package com.cmp.ckvs;

import java.nio.ByteBuffer;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.apache.log4j.Logger;

public class MD5DataColumn extends TextColumn {
	
	Logger logger = Logger.getLogger("com.cmp.wbs.casscon.md5filecolumn");
	MessageDigest md;

	public MD5DataColumn(String name) {
		super(name);
		try {
			md = MessageDigest.getInstance("MD5");
		} catch (NoSuchAlgorithmException e) {
			throw new IllegalArgumentException("This should not happen. MD5 algorithm not found.");
		}
	}

	@Override
	public Object prepareData(Object data)  throws IllegalArgumentException {
		ByteBuffer bb;
		if (data instanceof ByteBuffer) {
			bb = (ByteBuffer)data;
		} else {
			if (data instanceof byte[])
				bb = ByteBuffer.wrap((byte[])data);
			else
				throw new IllegalArgumentException("The value is not convertible to ByteBuffer.. The type of the object is: " + data.getClass().getName());
		}
		byte[] byteData = bb.array();
		byte[] digest = md.digest(byteData);
		logger.info(String.format("Computed MD5 digest of %d bytes of data",
				byteData.length));

		String md5 = new String(digest);
		return md5;
	}
}
