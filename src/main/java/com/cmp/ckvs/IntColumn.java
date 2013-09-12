package com.cmp.ckvs;

import com.datastax.driver.core.Row;

public class IntColumn extends Column {

	public IntColumn(String name) {
		super(name);
	}

	@Override
	public String getDataTypeString() {
		return "int";
	}

	@Override
	public Object prepareData(Object data) {
		// Matlab, when the 
		if (!(Integer.class.isAssignableFrom(data.getClass()))) {
			throw new IllegalArgumentException("The value is not an Integer. The type of the object is: " + data.getClass().getName());				
		}
		return data;
	}

	@Override
	public Object extractData(Row row) {
		Integer res = row.getInt(name);
		return res;
	}
}
