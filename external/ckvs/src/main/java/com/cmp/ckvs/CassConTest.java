package com.cmp.ckvs;

import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URL;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.util.ArrayList;

import org.apache.log4j.BasicConfigurator;
/**
 * Simple Java-Based testing script for the Cassandra connector.
 * 
 * Tests simple creation of a new column family, computation 
 * of MD5 of a file and storing/deleting a row from the table.
 * 
 * @author Karel Lenc
 *
 */

/* TODO do proper unit tests*/
public class CassConTest {

	public static void main(String[] args) {
		BasicConfigurator.configure();
		
		CassandraConnector casscon = new CassandraConnector();
		casscon.connect("147.32.84.147");
		
		ArrayList<KeySpace> kspcs = null;
		try {
			kspcs = casscon.loadKeyspaces();
		} catch (NoSuchFieldException e) {
			System.out.println("Error");
		}
		
		for (KeySpace k : kspcs) {
			System.out.println(String.format("Keyspace: %s",k.getName()));
		}
		
		KeySpace kspc = KeySpace.builder("test").build();
		
		
		ArrayList<Column> keys = new ArrayList<Column>();
		keys.add(new IntColumn("id"));
		keys.add(new TextColumn("name"));
		ArrayList<Column> values = new ArrayList<Column>();
		values.add(new MD5FileColumn("data"));

		
		DataStore ds = casscon.buildDataStore(kspc, "testTable2", keys, values);
		
		// Download some file
		try {
			URL website = new URL("http://www.datastax.com/documentation/cassandra/1.2/pdf/cassandra12.pdf");
			ReadableByteChannel rbc = Channels.newChannel(website.openStream());
			FileOutputStream fos = new FileOutputStream("test_file.pdf");
			fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE); // The file is smaller than 16MB
			fos.close();
			
		} catch (IOException e) {
			// Let's ignore the resource leaks when this happens, it's just a test
			e.printStackTrace();
		}

		ds.storeData(2,"first", "test_file.pdf");
		ds.loadData(2,"first");
		
		
		
		System.out.println(String.format("In the table there is: %d rows.", (int)ds.getNumRows()));
		
		ds.deleteData(2,"first");
		
		String ex = "No";
		if (ds.existData(2,"first"))
			ex = "Yop";
		System.out.println(String.format("The row existence: %s.", ex));
		
		casscon.close();
	}

}
