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

public class CassandraConnector {
	private Cluster cluster;
	private Session session;
	private Logger logger;
	private int port = -1;
	boolean isConnected = false;
	
	private ArrayList<KeySpace> keySpaces = new ArrayList<KeySpace>();

	public int getPort() {
		return port;
	}
	public void setPort(int port) {
		this.port = port;
	}
	
	public CassandraConnector() {
	    LogManager.resetConfiguration();
	    BasicConfigurator.configure();
	    String level = System.getProperty("casscon.loglevel");
	    LogManager.getRootLogger().setLevel(Level.toLevel(level));
		logger = Logger.getLogger("com.cmp.wbs.casscon.cassandraconnector");
	}

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
	
	public void close() {
		session.shutdown();
		cluster.shutdown();
		isConnected = false;
	}
	
	
	public ResultSet executeQuer(String query) {
		if (!isConnected)
			throw new IllegalStateException("Unable to execute query when not connected");
		
		ResultSet res = session.execute(query);
		return res;
	}
	
	public ArrayList<KeySpace> loadKeyspaces() throws NoSuchFieldException {
		if (!isConnected)
			throw new IllegalStateException("Unable to load keyspaces when not connected");
		
		ResultSet results = session.execute("SELECT * from system.schema_keyspaces");
		for (Row row : results) {
		    KeySpace ksp = new KeySpace(row);
		    keySpaces.add(ksp);
		}
		
		return keySpaces;
	}
	
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
}
