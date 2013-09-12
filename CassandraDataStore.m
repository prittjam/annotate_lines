classdef CassandraDataStore
  %UNTITLED Summary of this class goes here
  %   Detailed explanation goes here
    
  properties (Constant)
    ConnectorJarFile = fullfile(CassandraDataStore.getClassFilePath(),...
      '/target/ckvs-0.0.1-jar-with-dependencies.jar');
    LogLevel = 'DEBUG';
  end
  
  properties (SetAccess = protected, GetAccess = public)
    Keyspace;
    TableName;
    Keys;
    KeyFields;
    Values;
    ValueFields;
    Opts = struct(...
      'nodes',char({'woska','tarski'}),...
      'port',-1,...
      'replicationFactor',2,...
      'strategy','SimpleStrategy');
    % JAVA objects
    jvCassConn;
    jvDataStore;
    jvKeyspace;
    jvLogger;
  end
  
  methods
    function obj = CassandraDataStore(keyspace, tableName, keysStructure, valuesStructure, varargin)
      if ~usejava('jvm')
        error('Cassandra connector needs Java Virtual Machine. Run Matlab without -nojvm argument.');
      end
      
      % Check whether new version of google-collections is in path
      staticJavaFiles = javaclasspath('-static');
      guavaClassPath = find(~cellfun(@isempty,strfind(staticJavaFiles,'guava')), 1);
      if isempty(guavaClassPath)
        error([
          'Cassandra driver is not binary compatible with the old version '
          'of google-collections which is a part of Matlab distribution. '
          'The guava library must be loaded in the static java path insted.'
          'In order to fix this problem you must edit file: \n'
          fullfile(matlabroot,'toolbox','local','classpath.txt')
          'replacing google-collect.jar with guava-14.0.1.jar library '
          '(available at http://code.google.com/p/guava-libraries/).']);
      end
      java.lang.System.setProperty('casscon.loglevel',obj.LogLevel);
      javaaddpath(obj.ConnectorJarFile);
      
      obj.Keyspace = keyspace;
      obj.TableName = tableName;
      
      if ~isstruct(keysStructure) || ~isstruct(valuesStructure)
        error('Keys and data structure definition must be a struct.');
      end
      
      obj.checkDataStructure(keysStructure);
      obj.checkDataStructure(valuesStructure);
      
      obj.Keys = keysStructure;
      obj.KeyFields = fieldnames(keysStructure);
      obj.Values = valuesStructure;
      obj.ValueFields = fieldnames(valuesStructure);
      
      obj.Opts = helpers.vl_argparse(obj.Opts, varargin);
      
      jvNodes = CassandraDataStore.cellToJvStringArr(cellstr(obj.Opts.nodes));
      obj.jvCassConn = com.cmp.ckvs.CassandraConnector();
      obj.jvCassConn.connect(jvNodes);
      if obj.Opts.port > -1
        obj.jvCassConn.setPort(obj.Opts.port);
      end
      
      jvKeyColumns = CassandraDataStore.matlabDataStruct2Java(keysStructure);
      jvDataColumns = CassandraDataStore.matlabDataStruct2Java(valuesStructure);
      jvKeySpace = obj.buildJvKeyspace();
      
      obj.jvDataStore =  obj.jvCassConn.buildDataStore(jvKeySpace, ...
        tableName, jvKeyColumns, jvDataColumns);
    end
    
    function close(obj)
      obj.jvCassConn.close();
    end
    
    function store(obj, keys, values)
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      if ~CassandraDataStore.hasFields(values, obj.ValueFields)
        error('Values structure does not correspond to initialised data store.');
      end
     
      arrSize = numel(obj.KeyFields) + numel(obj.ValueFields);
      rr = cell(1,arrSize);
      ai = 1;
      for i = 1:numel(obj.KeyFields)
        clmnSpec = obj.Keys.(obj.KeyFields{i});
        rr{ai} = clmnSpec.preStoreHook(keys.(obj.KeyFields{i}));
        ai = ai + 1;
      end
      
      for i = 1:numel(obj.ValueFields)
        clmnSpec = obj.Values.(obj.ValueFields{i});
        rr{ai} = clmnSpec.preStoreHook(values.(obj.ValueFields{i}));
        ai = ai + 1;
      end
      
      jvArrList = CassandraDataStore.cellToJvArrList(rr);
      obj.jvDataStore.storeData(jvArrList);
    end
    
    function values = load(obj, keys)
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      
      arrSize = numel(obj.KeyFields);
      rr = cell(1,arrSize);
      ai = 1;
      for i = 1:numel(obj.KeyFields)
        clmnSpec = obj.Keys.(obj.KeyFields{i});
        rr{ai} = clmnSpec.preStoreHook(keys.(obj.KeyFields{i}));
        ai = ai + 1;
      end
      
      jvArrList = CassandraDataStore.cellToJvArrList(rr);
      data = obj.jvDataStore.loadData(jvArrList);
      
      values = struct();
      for i = 1:numel(obj.ValueFields)
        fld = obj.ValueFields{i};
        clmnSpec = obj.Values.(fld);
        values.(fld) = clmnSpec.afterLoadHook(data.get(i-1));
      end
    end
    
    function deleteRow(obj, keys)
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      
      arrSize = numel(obj.KeyFields);
      rr = cell(1,arrSize);
      ai = 1;
      for i = 1:numel(obj.KeyFields)
        clmnSpec = obj.Keys.(obj.KeyFields{i});
        rr{ai} = clmnSpec.preStoreHook(keys.(obj.KeyFields{i}));
        ai = ai + 1;
      end
      
      jvArrList = CassandraDataStore.cellToJvArrList(rr);
      obj.jvDataStore.deleteData(jvArrList);
    end
    
    
    function numRows = getNumRows(obj)
      numRows = obj.jvDataStore.getNumRows();
    end
  end
  
  methods (Access = protected, Hidden)
    
    function jvKeySpace = buildJvKeyspace(obj)
      builder = com.cmp.ckvs.KeySpace.builder(obj.Keyspace);
      jvKeySpace = builder.replicationFactor(obj.Opts.replicationFactor)...
        .strategy(obj.Opts.strategy).build();
    end
    
    function delete(obj)
      obj.close();
    end
  end
  
  methods (Static)
   function checkDataStructure(dataStructure)
      flds = fieldnames(dataStructure);
      for fldId = 1:numel(flds)
        val = dataStructure.(flds{fldId});
        if ~isa(val,'ColumnType')
          error('Value of field %s is not an instance of ColumnType.', flds{fldId});
        end
      end
   end
    
   function jvArrList = cellToJvArrList(cellArray)
      jvArrList = java.util.ArrayList;
      for i = 1:numel(cellArray)
        jvArrList.add(cellArray{i});
      end
   end
   
   function jvStringArr = cellToJvStringArr(cellArray)
      jvStringArr = javaArray('java.lang.String',numel(cellArray));
      for i = 1:numel(cellArray)
        jvStringArr(i) = 	java.lang.String(cellArray{i});
      end
   end
    
   function jvArrList = matlabDataStruct2Java(dataStructure)
      flds = fieldnames(dataStructure);
      jvColumns = cell(1,numel(flds));
      for fldId = 1:numel(flds)
        fldName = flds{fldId};
        jvColumns{fldId} = dataStructure.(fldName).buildJvColumn(fldName);
      end
      jvArrList = CassandraDataStore.cellToJvArrList(jvColumns);
   end
    
   function res = hasFields(str, fields)
     res = true;
     strFields = fieldnames(str);
     if numel(fields) ~= numel(fields) || ~all(ismember(strFields, fields))
       res = false;
     end
   end
   
   function path = getClassFilePath()
     classFname = mfilename('fullpath');
     [path, ~] = fileparts(classFname);
   end
  end
  
end

