package com.cmp.ckvs;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.apache.log4j.Logger;

public class MD5FileColumn extends TextColumn {
	
	Logger logger = Logger.getLogger("com.cmp.wbs.casscon.md5filecolumn");
	MessageDigest md;

	public MD5FileColumn(String name) {
		super(name);
		try {
			md = MessageDigest.getInstance("MD5");
		} catch (NoSuchAlgorithmException e) {
			throw new IllegalArgumentException("This should not happen. MD5 algorithm not found.");
		}
	}

	@Override
	public Object prepareData(Object data)  throws IllegalArgumentException {
		if (!(String.class.isAssignableFrom(data.getClass()))) {
			throw new IllegalArgumentException("The value is not a string. The type of the object is: " + data.getClass().getName());
		}
		String fileName = (String)data;
		fileName = FileColumn.expandPath(fileName);

		byte[] byteData = FileColumn.readFile(fileName);
		byte[] digest = md.digest(byteData);
		logger.info(String.format("Computed MD5 digest of file %s of length %d bytes..",
				fileName, byteData.length));
		String md5 = new String(digest);
		return md5;
	}
}
