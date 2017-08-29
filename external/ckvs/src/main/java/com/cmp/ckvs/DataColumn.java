package com.cmp.ckvs;

import java.nio.ByteBuffer;

import com.datastax.driver.core.Row;

public class DataColumn extends Column {

	public DataColumn(String name) {
		super(name);
	}

	@Override
	public String getDataTypeString() {
		return "blob";
	}
	
	@Override
	public Object prepareData(Object data) {
		ByteBuffer bb;
		if (data instanceof ByteBuffer) {
			bb = (ByteBuffer)data;
		} else {
			if (data instanceof byte[])
				bb = ByteBuffer.wrap((byte[])data);
			else
				throw new IllegalArgumentException("The value is not convertible to ByteBuffer. The type of the object is: " + data.getClass().getName());
		}
		return bb;
	}

	@Override
	public Object extractData(Row row) {
		ByteBuffer res = row.getBytes(name);
		return res;
	}
}