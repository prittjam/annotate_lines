package com.cmp.ckvs;

import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.BasicConfigurator;
import org.apache.log4j.Level;
import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;

import com.datastax.driver.core.Cluster;
import com.datastax.driver.core.Metadata;
import com.datastax.driver.core.Host;
import com.datastax.driver.core.ResultSet;
import com.datastax.driver.core.Row;
import com.datastax.driver.core.Session;
import com.datastax.driver.core.exceptions.AlreadyExistsException;

// TODO remake to builder template, now it is kind of mixed 
// TODO numRows - allow incomplete definition of the keys, count the number of rows with a particular key
// TODO HAVE CONNECTION AS SINGLETON!

/**
 * Connector to the Cassandra implmeneting the key/value store
 * paradigm.
 * 
 * Handles the connection and allows building new DataStores which
 * represent a single table in Cassandra.
 * 
 * Before a DataStore can be built, the connection has to be established
 * (connection port set by setPort method, seed nodes parameters of connect).
 * 
 * @author Karel Lenc
 *
 */
public class CassandraConnector {
	private Cluster cluster;
	private Session session;
	private Logger logger;
	private int port = -1;
	protected boolean isConnected = false;

	/**
	 * Construct a CassandraConnector instance.
	 */
	public CassandraConnector() {
	    LogManager.resetConfiguration();
	    BasicConfigurator.configure();
	    String level = System.getProperty("casscon.loglevel");
	    LogManager.getRootLogger().setLevel(Level.toLevel(level));
		logger = Logger.getLogger("com.cmp.wbs.casscon.cassandraconnector");
	}
	
	/**
	 * Connect to cassandra cluster. If unsuccessful (? TBD)
	 * @param nodes VARARG seed nodes
	 */
	public void connect(String... nodes) {
		Cluster.Builder builder = Cluster.builder();
		
		if (port > 0) {
			builder.withPort(port);
		}
		
		cluster = builder.addContactPoints(nodes).build();
		
		Metadata metadata = cluster.getMetadata();
		logger.info("Connected to cluster: " +metadata.getClusterName());
		for ( Host host : metadata.getAllHosts() ) {
			logger.info(String.format("Datacenter: %s; Host: %s; Rack: %s",
					host.getDatacenter(), host.getAddress(), host.getRack()));
		}
		session = cluster.connect();
		
		isConnected = true;
	}
	
	/**
	 * Close a connection to Cassandra cluster.
	 */
	public void close() {
		session.shutdown();
		cluster.shutdown();
		isConnected = false;
	}
	
	/**
	 * Build a new instance of a DataStore.
	 * @param keyspace The definition of the KeySpace
	 * @param columnFamily Name of the CF (Table name)
	 * @param keyColumns Definition of the key columns 
	 * @param dataColumns Definition of the value columns
	 * @return A new instance of the DataStore handling the defined storage
	 */
	public DataStore buildDataStore(KeySpace keyspace, String columnFamily,
			List<Column> keyColumns,
			List<Column> dataColumns) {
		if (!isConnected)
			throw new IllegalStateException("Unable to create a datastore when not connected");
		if (!createKeyspace(keyspace)) {
			logger.info(String.format("Keyspace %s already exists.",keyspace.getName()));
		}
		return new DataStore(session, keyspace, columnFamily, keyColumns, dataColumns);
	}	
	
	/**
	 * Execute a single CQL query on the connected cluster.
	 * @param query The query
	 * @return Results
	 */
	public ResultSet executeQuery(String query) {
		if (!isConnected)
			throw new IllegalStateException("Unable to execute query when not connected");
		
		ResultSet res = session.execute(query);
		return res;
	}
	
	/**
	 * Get the list of all KeySpaces in the cassandra cluster.
	 * @return List of alll KeySpaces in the cluster.
	 * @throws NoSuchFieldException
	 */
	public ArrayList<KeySpace> loadKeyspaces() throws NoSuchFieldException {
		if (!isConnected)
			throw new IllegalStateException("Unable to load keyspaces when not connected");
		
		ArrayList<KeySpace> keySpaces = new ArrayList<KeySpace>();
		
		ResultSet results = session.execute("SELECT * from system.schema_keyspaces");
		for (Row row : results) {
		    KeySpace ksp = new KeySpace(row);
		    keySpaces.add(ksp);
		}
		
		return keySpaces;
	}
	
	/**
	 * Create a new KeySpace.
	 * @param ksp The KeySpace definition.
	 * @return True if success.
	 */
	public boolean createKeyspace(KeySpace ksp) {
		boolean success = true;
		String query = ksp.getCreateQuery();
		try {
			session.execute(query);
		} catch (AlreadyExistsException e) {
			success = false;
		}
		return success;
	}
	
	/**
	 * Check whether the instance is connected to cassandra.
	 * @return True if connected.
	 */
	public boolean isConnected() {
		return isConnected;
	}
	
	public int getPort() {
		return port;
	}
	
	/**
	 * Set the connection port to the Cassandra cluster.
	 * @param port Port number.
	 */
	public void setPort(int port) {
		this.port = port;
	}
	
}
