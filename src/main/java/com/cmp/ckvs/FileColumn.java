package com.cmp.ckvs;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;

import org.apache.log4j.Logger;

import com.datastax.driver.core.Row;

public class FileColumn extends DataColumn {
	
	Logger logger = Logger.getLogger("com.cmp.wbs.casscon.filecolumn");
	String outputFile = "";

	public FileColumn(String name) {
		super(name);
	}
	
	FileColumn(String name, String outputFile) {
		super(name);
		this.outputFile = expandPath(outputFile);
	}
	
	static byte[] readFile(String fileName) {
		int length;
		byte[] byteData;
		
		try {
			RandomAccessFile f = new RandomAccessFile(fileName, "r");

			length = (int)f.length();
			byteData = new byte[length];
			f.read(byteData);
			f.close();
		} catch (FileNotFoundException e) {
			throw new IllegalArgumentException(String.format("Unable to open file %s", fileName));
		} catch (IOException e) {
			throw new IllegalArgumentException(String.format("Error reading file %s", fileName));
		}
		return byteData;
	}
	
	static int storeFile(String fileName, ByteBuffer res) {
		int numBytes = 0;
		
		try {
			RandomAccessFile out = new RandomAccessFile(fileName, "rw");
			// Data in the buffer array are from a certain byte...
			numBytes = res.limit() - res.position();
		    out.write(res.array(), res.position(), numBytes);
		    out.close();

		} catch (IOException e) {
			throw new IllegalArgumentException(String.format("Error writing to file %s", fileName));
		}
		return numBytes;
	}

	@Override
	public Object prepareData(Object data)  throws IllegalArgumentException {
		if (!(String.class.isAssignableFrom(data.getClass()))) {
			throw new IllegalArgumentException("The value is not a string. The type of the object is: " + data.getClass().getName());
		}
		String fileName = (String)data;
		fileName = expandPath(fileName);

		byte[] byteData = readFile(fileName);
		logger.info(String.format("File %s - loaded %d bytes.",
				fileName, byteData.length));
		
		ByteBuffer bb = ByteBuffer.wrap(byteData);
		return bb;
	}
	
	@Override
	public Object extractData(Row row) throws IllegalArgumentException {
		ByteBuffer res = row.getBytes(name);
		
		if (!outputFile.isEmpty()) {
			int numBytes = storeFile(outputFile, res);
		    logger.info(String.format("File %s - written %d bytes.",
					outputFile, numBytes));
		}
		
		return res;
	}
	
	public static String expandPath(String path) {
		if (path.startsWith("~" + File.separator)) {
		    path = System.getProperty("user.home") + path.substring(1);
		}
		return path;
	}
}
