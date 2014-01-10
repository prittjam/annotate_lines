classdef ColumnType
  %ColumnType Enumeration of supported CassandraDataStore column types.
  % Valid ColumnTypes:
  %   INT       - Int32 value
  %   TEXT      - Array of chars
  %   RAWDATA   - Array of signed bytes (Java style buffers)
  %   MDATA     - Any matlab object, serialised and deseriased, store in
  %               Cassandra as RAWDATA
  %   FILE      - Java-processed file (store(FILENAME), RAW_DATA = load())
  %   MD5DATA   - MD5 of data (store(RAW_DATA), DATA_MD5 = load()), stored
  %               as text
  %   MD5FILE   - MD5 of a file (store(FILENAME), FILE_DATA_MD5 = load()),
  %               stored as text
  %   IMAGEFILE - Java processed image file (store(FILENAME), 
  %               MATLAB_IMAGE = load()) Stored in cassandra as RAW_DATA 
  %               of the image file (e.g. compressed). The image type must 
  %               be supported and readable by Java Image I/O
  %
  % Several column types also have various matlab hooks (e.g. serialistion 
  % of Matlab data types etc.).
  %
  % See also: CassandraDataStore
  
  % AUTHOR: Karel Lenc
  enumeration
    INT, TEXT, RAWDATA, MDATA, FILE, MD5DATA, MD5FILE, IMAGEFILE
  end
  
  methods (Hidden)
    function res = isValidKey(obj)
      %isValidKey Determine if the ColumnType can be used as a key column
        switch (obj)
          case ColumnType.INT
            res = true;
          case ColumnType.TEXT
            res = true;
          case ColumnType.RAWDATA
            res = false;
          case ColumnType.MDATA
            res = false;
          case ColumnType.FILE
            res = false;
          case ColumnType.MD5DATA
            res = false;
          case ColumnType.MD5FILE
            res = false;
          case ColumnType.IMAGEFILE
            res = false;
          otherwise
            error('Invalid column type %s', char(obj));
        end
    end
    
    function jvColumn = buildJvColumn(obj, columnName)
      % buildJvColumn Create a Java countrepart object of a column
        switch (obj)
          case ColumnType.INT
            jvColumn = com.cmp.ckvs.IntColumn(columnName);
          case ColumnType.TEXT
            jvColumn = com.cmp.ckvs.TextColumn(columnName);
          case ColumnType.RAWDATA
            jvColumn = com.cmp.ckvs.DataColumn(columnName);
          case ColumnType.MDATA
            jvColumn = com.cmp.ckvs.DataColumn(columnName);
          case ColumnType.FILE
            jvColumn = com.cmp.ckvs.FileColumn(columnName);
          case ColumnType.MD5DATA
            jvColumn = com.cmp.ckvs.MD5DataColumn(columnName);
          case ColumnType.MD5FILE
            jvColumn = com.cmp.ckvs.MD5FileColumn(columnName);
          case ColumnType.IMAGEFILE
            jvColumn = com.cmp.ckvs.ImageFileColumn(columnName);
          otherwise
            error('Invalid column type %s', char(obj));
        end
    end
    
    function res = preStoreHook(obj, data)
      % preStoreHook Preprocess data before passing them to java
        switch (obj)
          case {ColumnType.INT}
            % INT -> convert to int32 value
            if ~isscalar(data), error('Data must be a scalar value'); end;
            res = java.lang.Integer(int32(round(data)));
          case {ColumnType.MDATA, ColumnType.MD5DATA}
            % MDATA, MD5DATA -> Serialise the matlab object to array of
            % bytes
            res = helpers.serialize.hlp_serialize(data);
          otherwise
            res = data;
        end
    end
    
    function res = postLoadHook(obj, data)
      % postLoadHook Process data from Java
        switch (obj)
          case ColumnType.MDATA
            % Get they array of bytes from Java and deserialise it back to
            % Matlab object
            
            % Cassandra returns bytes as ByteBuffer where the data itself
            % starts from some offset. Data are by no means copied to
            % Matlab so just do the conversion in Matlab.
            byteArr = data.array;
            % Take only the data without cassandra header
            byteArr = byteArr((data.position+1):end);
            res = helpers.serialize.hlp_deserialize(byteArr);
          case ColumnType.IMAGEFILE
            % Data are returned from Java as JavaImage, convert it to
            % Matlab style image.
            
            % Source: 
            % http://www.mathworks.com/support/solutions/en/data/1-2WPAYR/?solution=1-2WPAYR
            h=data.getHeight;
            w=data.getWidth;

            pixelsData = reshape(typecast(data.getData.getDataStorage, 'uint8'), 3, w, h);
            res = cat(3, ...
                    transpose(reshape(pixelsData(3, :, :), w, h)), ...
                    transpose(reshape(pixelsData(2, :, :), w, h)), ...
                    transpose(reshape(pixelsData(1, :, :), w, h)));
          otherwise
            res = data;
        end
    end
  end
end

