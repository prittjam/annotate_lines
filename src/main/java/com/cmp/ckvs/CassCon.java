package com.cmp.ckvs;

import java.util.ArrayList;

import org.apache.log4j.BasicConfigurator;

public class CassCon {

	public static void main(String[] args) {
		BasicConfigurator.configure();
		
		CassandraConnector casscon = new CassandraConnector();
		casscon.connect("tarski");
		
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
		//values.add(new FileColumn("data","/tmp/tmp.pdf"));
		values.add(new MD5DataColumn("data"));

		
		DataStore ds = casscon.buildDataStore(kspc, "testTable2", keys, values);
		
		//ds.storeData(2,"first", "/home/kaja/mozilla.pdf");
		ds.storeData(2,"first", "/home/kaja/mozilla.pdf".getBytes());

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
