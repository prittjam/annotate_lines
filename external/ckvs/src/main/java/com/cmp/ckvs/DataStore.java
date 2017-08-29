package com.cmp.ckvs;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.apache.log4j.Logger;

import com.datastax.driver.core.BoundStatement;
import com.datastax.driver.core.PreparedStatement;
import com.datastax.driver.core.ResultSet;
import com.datastax.driver.core.Row;
import com.datastax.driver.core.Session;
import com.datastax.driver.core.exceptions.AlreadyExistsException;

/**
 * Representation a single Column Family in Cassandra
 * used in the key/value store paradigm.
 * 
 * Implements generation of the CQL queries based on the
 * storage structure. Uses prepared statements.
 * 
 * @author Karel Lenc
 *
 */
public class DataStore {
	
	// TODO check the consistency of table structures.
	protected Session session;
	protected KeySpace keyspace;
	protected String columnFamily;
	protected List<Column> keyColumns;
	protected List<Column> dataColumns;
	protected ArrayList<Column> allColumns;
	protected int numColumns;
	
	Logger logger = Logger.getLogger("com.cmp.wbs.casscon.datastore");
	
	protected final PreparedStatement storeStatement;
	protected final PreparedStatement loadStatement;
	protected final PreparedStatement existStatement;
	protected final PreparedStatement deleteStatement;
	
	/**
	 * Construct a wrapper around a column family. If the CF does not exist,
	 * create one.
	 * @param session Reference to an open Session to Cassandra
	 * @param keyspace Reference to a keyspace where the CF is located
	 * @param columnFamily Name of the Column family
	 * @param keyColumns Definition of the columns used as keys
	 * @param dataColumns Definition of the columns used as values
	 */
	public DataStore(Session session, KeySpace keyspace, String columnFamily, 
			List<Column> keyColumns, List<Column> dataColumns) {
		
		this.session = session;
		this.keyspace = keyspace;
		this.columnFamily = columnFamily;
		this.keyColumns = keyColumns;
		this.dataColumns = dataColumns;
		numColumns = keyColumns.size() + dataColumns.size();
		allColumns = new ArrayList<Column>(numColumns);
		allColumns.addAll(keyColumns);
		allColumns.addAll(dataColumns);
		
		if (!this.createTable()) {
			logger.info(String.format("Table %s already exist.",columnFamily));
		} else {
			logger.info(String.format("Table %s created.",columnFamily));
		}
		
		String sq = storeQuery();
		String lq = loadQuery();
		String eq = existQuery();
		String dq = deleteQuery();
		
		// Prepare the statements
		storeStatement = session.prepare(sq);
		loadStatement = session.prepare(lq);
		deleteStatement = session.prepare(dq);
		existStatement = session.prepare(eq);
	}
	
	/**
	 * Execute a CQL query
	 * @param query The query (String)
	 * @return The result in ResultSet
	 */
	public ResultSet executeQuery(String query) {
		return session.execute(query);
	}
	
	/**
	 * Load data from the table defined by the keys.
	 * @param keys VARARG the keys.
	 * @return Array list of the value columns contents
	 */
	public ArrayList<Object> loadData(Object... keys) {
		BoundStatement boundStatement = bindData(loadStatement, keyColumns, keys);
		ResultSet rss = session.execute(boundStatement);
		
		ArrayList<Object> results = new ArrayList<Object>(dataColumns.size());
		Iterator<Column> clmnIter = dataColumns.iterator();

		for (Row row : rss) {
			Column col = clmnIter.next();
			Object extrData = col.extractData(row);
			results.add(extrData);
		}
		
		logger.trace("Data loaded.");
		return results;
	}
	
	public ArrayList<Object> loadData(ArrayList<Object> keys) {
		Object[] arr = keys.toArray();
		return loadData(arr);
	}
	
	/**
	 * Check whether a row defined by the keys does exist
	 * @param keys The keys
	 * @return True if does.
	 */
	public boolean existData(Object... keys) {
		BoundStatement boundStatement = bindData(existStatement, keyColumns, keys);
		ResultSet rss = session.execute(boundStatement);
		
		Row row = rss.one();
		long res = row.getLong(0);
		
		logger.trace("Query for data presence executed");
		return res > 0;
	}
	
	public boolean existData(ArrayList<Object> keys) {
		Object[] arr = keys.toArray();
		return existData(arr);
	}
	
	/**
	 * Store data into the table
	 * @param keysAndData Keys followed by the values to be stored.
	 */
	public void storeData(Object... keysAndData) {
		
		BoundStatement boundStatement = bindData(storeStatement, allColumns, 
				keysAndData);
		session.execute(boundStatement);
		logger.trace("Data stored.");
	}
	
	public void storeData(ArrayList<Object> keysAndData) {
		Object[] arr = keysAndData.toArray();
		storeData(arr);
	}
	
	/**
	 * Delete a row defined by the keys.
	 * @param keys Row definition to be deleted.
	 */
	public void deleteData(Object... keys) {
		BoundStatement boundStatement = bindData(deleteStatement, keyColumns, keys);
		session.execute(boundStatement);
		
		logger.trace("Data deleted.");
	}
	
	public void deleteData(ArrayList<Object> keys) {
		Object[] arr = keys.toArray();
		deleteData(arr);
	}
	
	/**
	 * Get number of rows in the table.
	 * Note: For big tables ends in timeout.
	 * @return Number of rows.
	 */
	public long getNumRows() {
		String query = String.format("SELECT COUNT(*) FROM \"%s\".\"%s\"",
				keyspace.getName(), columnFamily);
		ResultSet res = session.execute(query);
		Row rr = res.one();
		long numRows = rr.getLong(0);
		return numRows;
	}
	
	protected BoundStatement bindData(PreparedStatement statement, 
			List<Column> columns, Object[] objects) {
		
		if (objects.length != columns.size()) {
			throw new IllegalArgumentException(
					String.format("Invalid number of input arguments." 
							+ "Expected %d arguments",
					columns.size()));
		}
		
		BoundStatement boundStatement = new BoundStatement(statement);

		Iterator<Column> clmnIter = columns.iterator();
		Object[] procObjs = new Object[objects.length];
		
		int i = 0;
		for (Object obj : objects) {
			Column col = clmnIter.next();
			procObjs[i++] = col.prepareData(obj);
		}
		
		boundStatement = boundStatement.bind(procObjs);
		
		return boundStatement;
	}
	
	protected String storeQuery() {
		String keyNames = getColumnNamesString(keyColumns);
		String dataNames = getColumnNamesString(dataColumns);
		
		int qmnum = keyColumns.size() + dataColumns.size();
		
		String query = String.format("INSERT INTO \"%s\".\"%s\" (%s, %s) VALUES (%s);", 
						keyspace.getName(), columnFamily, keyNames, dataNames,
						genRepeatedString("?", ", ", qmnum));
		return query;
	}
	
	protected String loadQuery() {
		String dataNames = getColumnNamesString(dataColumns);
				
		StringBuilder qbldr = new StringBuilder();
		qbldr.append(String.format("SELECT %s FROM \"%s\".\"%s\" WHERE ", 
						dataNames, keyspace.getName(), columnFamily));
		
		int numel = keyColumns.size();
		int i = 0;
		for (Column col : keyColumns) {
			qbldr.append(String.format("\"%s\" = ?", col.getName()));
			if (++i < numel)
				qbldr.append(" AND ");
		}
		
		return qbldr.toString();
	}
	
	protected String existQuery() {				
		StringBuilder qbldr = new StringBuilder();
		qbldr.append(String.format("SELECT COUNT(*) FROM \"%s\".\"%s\" WHERE ", 
						keyspace.getName(), columnFamily));
		
		int numel = keyColumns.size();
		int i = 0;
		for (Column col : keyColumns) {
			qbldr.append(String.format("\"%s\" = ?", col.getName()));
			if (++i < numel)
				qbldr.append(" AND ");
		}
		
		return qbldr.toString();
	}
	
	protected String deleteQuery() {				
		StringBuilder qbldr = new StringBuilder();
		qbldr.append(String.format("DELETE FROM \"%s\".\"%s\" WHERE ", 
				keyspace.getName(), columnFamily));
		
		int numel = keyColumns.size();
		int i = 0;
		for (Column col : keyColumns) {
			qbldr.append(String.format("\"%s\" = ?", col.getName()));
			if (++i < numel)
				qbldr.append(" AND ");
		}
		
		return qbldr.toString();
	}
	
	protected boolean createTable() {
		boolean success = true;
		
		String columnTypes = getColumnTypesString(keyColumns) + ", "
				+ getColumnTypesString(dataColumns);
		String keyNames = getColumnNamesString(keyColumns);

		String query = String.format("CREATE TABLE \"%s\".\"%s\" ( %s, PRIMARY KEY (%s));", 
						keyspace.getName(), columnFamily, columnTypes, keyNames);
		try {
			session.execute(query);
		} catch (AlreadyExistsException e) {
			success = false;
		}
		return success;
	}
	
	protected static String getColumnTypesString(List<Column> columns) {
		StringBuilder bldr = new StringBuilder();
		int numel = columns.size();
		int i = 0;
		for (Column column : columns) {
			bldr.append(column.getQuerySpecification());
			if (++i < numel)
				bldr.append(", ");
		}
		return bldr.toString();
	}
	
	protected static String getColumnNamesString(List<Column> columns) {
		StringBuilder bldr = new StringBuilder();
		int numel = columns.size();
		int i = 0;
		for (Column column : columns) {
			bldr.append("\"");
			bldr.append(column.getName());
			bldr.append("\"");
			if (++i < numel)
				bldr.append(", ");	
		}
		return bldr.toString();
	}
	
	protected static String genRepeatedString(String what, String sep, int num) {
		StringBuilder qmbuilder = new StringBuilder();

		for (int i = 0; i < num; i++) {
			qmbuilder.append(what);
			if (i+1 < num)
				qmbuilder.append(sep);
		}
		
		return qmbuilder.toString();
	}
}
