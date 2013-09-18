classdef ColumnType
  
  enumeration
    INT, TEXT, RAWDATA, MDATA, FILE, MD5DATA, MD5FILE, IMAGEFILE
  end
  
  methods
    function res = isValidKey(obj)
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
      % TODO maybe check the data types here?
        switch (obj)
          case {ColumnType.INT}
            res = java.lang.Integer(int32(round(data)));
          case {ColumnType.MDATA, ColumnType.MD5DATA}
            res = helpers.serialize.hlp_serialize(data);
          otherwise
            res = data;
        end
    end
    
    function res = afterLoadHook(obj, data)
        switch (obj)
          case ColumnType.MDATA
            % Cassandra returns bytes as ByteBuffer where the data itself
            % starts from some offset. Data are by no means copied to
            % Matlab so just do the conversion in Matlab.
            byteArr = data.array;
            % Take only the data without cassandra header
            byteArr = byteArr((data.position+1):end);
            res = helpers.serialize.hlp_deserialize(byteArr);
          case ColumnType.IMAGEFILE
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

