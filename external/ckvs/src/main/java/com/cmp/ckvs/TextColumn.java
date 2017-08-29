package com.cmp.ckvs;

import com.datastax.driver.core.Row;

public class TextColumn extends Column {
	public TextColumn(String name) {
		super(name);
	}
	@Override
	public String getDataTypeString() {
		return "text";
	}
	
	@Override
	public Object prepareData(Object data) {
		if (!(String.class.isAssignableFrom(data.getClass()))) {
			throw new IllegalArgumentException("The value is not a String.");
		}
		return data;
	}

	@Override
	public Object extractData(Row row) {
		String res = row.getString(name);
		return res;
	}
}