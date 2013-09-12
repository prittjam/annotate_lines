package com.cmp.ckvs;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

import javax.imageio.ImageIO;

import com.datastax.driver.core.Row;

public class ImageFileColumn extends FileColumn {
	
	public ImageFileColumn(String name) {
		super(name);
	}

	
	@Override
	public Object extractData(Row row) throws IllegalArgumentException {
		ByteBuffer res = row.getBytes(name);
		ByteArrayInputStream dataStream = new ByteArrayInputStream(res.array(), res.position(), res.remaining());
		BufferedImage bufferedImage = null;
		try {
			bufferedImage = ImageIO.read(dataStream);
		} catch (IOException e) {
			throw new IllegalArgumentException("Error reading the image stream.");
		}
		return bufferedImage;
	}
}
