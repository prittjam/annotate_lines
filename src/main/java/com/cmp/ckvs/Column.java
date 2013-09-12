package com.cmp.ckvs;

import com.datastax.driver.core.Row;

public abstract class Column {
	
	protected String name;
	
	public Column(String name) {
		this.name = name;
	}
	
	public String getName() {
		return name;
	}
	
	public String getQuerySpecification() {
		return String.format("%s %s", name, getDataTypeString());
	}
	
	public abstract String getDataTypeString();
	
	public abstract Object prepareData(Object data) throws IllegalArgumentException;
	public abstract Object extractData(Row row) throws IllegalArgumentException;
}