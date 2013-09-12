package com.cmp.ckvs;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.datastax.driver.core.Row;

// TODO handle other than SimpleStrategy keyspaces

public class KeySpace {
	private int replicationFactor;
	private String strategy;
	private String name;
	
	public static class KeySpaceBuilder {
		private int replicationFactor = 2;
		private String strategy = "SimpleStrategy";
		private String name;
		
		public KeySpaceBuilder(String name) {
			this.name = name;
		}
		
		public KeySpaceBuilder replicationFactor(int rf) {
			replicationFactor = rf;
			return this;
		}
		
		public KeySpaceBuilder strategy(String str) {
			strategy = str;
			return this;
		}
		
		
		public KeySpace build() {
			return new KeySpace(this);
		}
	}
	
    public static KeySpace.KeySpaceBuilder builder(String name) {
        return new KeySpace.KeySpaceBuilder(name);
    }
	
	KeySpace(Row row) throws NoSuchFieldException
	{
		name = row.getString("keyspace_name");
		strategy = row.getString("strategy_class");
		if (strategy.equalsIgnoreCase("SimpleStrategy")) {
			String repFac = row.getString("strategy_options");
			Pattern p = Pattern.compile("(\\d+)");
			Matcher m = p.matcher(repFac);
			
			if (m.find())
				replicationFactor = Integer.parseInt(m.group());
		}
	}
	
	private KeySpace(KeySpaceBuilder b)
	{
		name = b.name;
		replicationFactor = b.replicationFactor;
		strategy = b.strategy;
	}
	
	public int getReplicationFactor() {
		return replicationFactor;
	}

	public String getName() {
		return name;
	}
	
	public String getStrategy() {
		return strategy;
	}
	
	public String getCreateQuery() {
		 String query = String.format("CREATE KEYSPACE %s " +
				 "WITH REPLICATION = {'class' : '%s', 'replication_factor': %d}",
				 name, strategy, replicationFactor);
		 return query;
	}

}
