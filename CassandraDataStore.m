classdef CassandraDataStore
  %UNTITLED Summary of this class goes here
  %   Detailed explanation goes here
  
  % TODO make it work on default with cell arrays, not structs.
  %   reason - it is simpler to work with cell arrays than structs and it
  %   may be faster as well as it would need less structs and no dynamic
  %   field allocation...
  
  % TODO change the cool stuff with the conversions in java etc. to hooks,
  % rather than to column types. It would be much clearer then.
    
  properties (Constant)
    ConnectorJarFile = fullfile(CassandraDataStore.getClassFilePath(),...
      '/target/ckvs-0.0.1-jar-with-dependencies.jar');
    % Change this to any log4j level to limit the verbosity. Before the
    % changes take effect, 'clear all' must be called.
    LogLevel = 'WARN';
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
          'Cassandra driver is not binary compatible with the old version ',...
          'of google-collections which is a part of Matlab distribution. ',...
          'The guava library must be loaded in the static java path insted.',...
          'In order to fix this problem you must edit file: \n',...
          fullfile(matlabroot,'toolbox','local','classpath.txt') ,...
          'replacing google-collect.jar with guava-14.0.1.jar library ' ,...
          '(available at http://code.google.com/p/guava-libraries/).']);
      end
      
      if ~obj.checkGCClass()
         error(['Guava library has not been properly loaded. Is it a valid jar file?']);
      end
      
      java.lang.System.setProperty('casscon.loglevel',obj.LogLevel);

      if ~ismember(obj.ConnectorJarFile,javaclasspath('-dynamic')) 
        warning('Knock-Knock - Matlab is going to delete all your global variables!');
        obj.decentjavaaddpath(obj.ConnectorJarFile);
      end
      
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
      
      obj.jvCassConn = obj.getConnection();
      
      jvKeyColumns = CassandraDataStore.matlabDataStruct2Java(keysStructure, true);
      jvDataColumns = CassandraDataStore.matlabDataStruct2Java(valuesStructure, false);
      jvKeySpace = obj.buildJvKeyspace();
      
      obj.jvDataStore =  obj.jvCassConn.buildDataStore(jvKeySpace, ...
        tableName, jvKeyColumns, jvDataColumns);
    end
    
    function close(obj)
      obj.jvCassConn.close();
    end
    
    function store(obj, keys, values, runHooks)
      if nargin < 4
        runHooks = true;
      end
      
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      if ~CassandraDataStore.hasFields(values, obj.ValueFields)
        error('Values structure does not correspond to initialised data store.');
      end
     
      rr = struct2cell(keys)';
      rr = [rr cell(1, numel(obj.ValueFields))];
      
      ai = numel(obj.KeyFields) + 1;
      for i = 1:numel(obj.ValueFields)
        clmnSpec = obj.Values.(obj.ValueFields{i});
        if runHooks
          rr{ai} = clmnSpec.preStoreHook(values.(obj.ValueFields{i}));
        else
          rr{ai} = values.(obj.ValueFields{i});
        end
        ai = ai + 1;
      end
      
      jvArrList = CassandraDataStore.cellToJvArrList(rr);
      obj.jvDataStore.storeData(jvArrList);
    end
    
    function values = load(obj, keys, runHooks)
      if nargin < 3
        runHooks = true;
      end
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      
      rr = struct2cell(keys)';
      
      jvArrList = CassandraDataStore.cellToJvArrList(rr);
      data = obj.jvDataStore.loadData(jvArrList);
      
      if data.size() == 0
        values = [];
        return;
      end
      
      values = struct();
      for i = 1:numel(obj.ValueFields)
        fld = obj.ValueFields{i};
        clmnSpec = obj.Values.(fld);
        if runHooks
          values.(fld) = clmnSpec.afterLoadHook(data.get(i-1));
        else
          values.(fld) = data.get(i-1);
        end
      end
    end
    
        
    function ex = exist(obj, keys)
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      
      rr = struct2cell(keys)';
      
      jvArrList = CassandraDataStore.cellToJvArrList(rr);
      ex = obj.jvDataStore.existData(jvArrList);
    end
    
    function deleteRow(obj, keys)
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      
      rr = struct2cell(keys)';
      
      jvArrList = CassandraDataStore.cellToJvArrList(rr);
      obj.jvDataStore.deleteData(jvArrList);
    end
    
    
    function resultsSet = execute(obj, query)
      resultsSet = obj.jvDataStore.executeQuery(query);
    end
    
    function numRows = getNumRows(obj)
      numRows = obj.jvDataStore.getNumRows();
    end
    
    function keys = buildKeys(obj, varargin)
      keys = obj.buildStruct(obj.KeyFields, varargin);
    end
    
    function values = buildValues(obj, varargin)
      values = obj.buildStruct(obj.ValueFields, varargin);
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
    
    function conn = getConnection(obj)
      persistent connPool; % Imitation of a static variable
      if isempty(connPool)
        connPool = containers.Map();
      end
      
      nodes = cellstr(obj.Opts.nodes);
      connSpec = [[nodes{:}] num2str(obj.Opts.port)];
      if ~connPool.isKey(connSpec)
        conn = com.cmp.ckvs.CassandraConnector();
        if obj.Opts.port > -1
          conn.setPort(obj.Opts.port);
        end
        connPool(connSpec) = conn;
      else
        conn = connPool(connSpec);
      end
      
      if ~conn.isConnected()
        jvNodes = CassandraDataStore.cellToJvStringArr(cellstr(obj.Opts.nodes));
        conn.connect(jvNodes);
      end
    end
  end
  
  methods (Static)
    function str = buildStruct(fields, values)
      if numel(fields) ~= numel(values)
        error('Invalid number of values.');
      end
      args = [fields(:)'; values(:)'];
      str = struct(args{:});
    end
    
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
    
   function jvArrList = matlabDataStruct2Java(dataStructure, isKey)
      flds = fieldnames(dataStructure);
      jvColumns = cell(1,numel(flds));
      for fldId = 1:numel(flds)
        fldName = flds{fldId};
        ds = dataStructure.(fldName);
        if isKey && ~ds.isValidKey()
          error('Data type %s of column %s cannot be used as a key.', ...
            char(ds), fldName);
        end
        jvColumns{fldId} = ds.buildJvColumn(fldName);
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
   
   function decentjavaaddpath(newpath)
     % USeful function for nasty boys from Mathworks
     globalVars = who('global');
     % Save the whales
     for iVar = 1:numel(globalVars)
       eval(sprintf('global %s', globalVars{iVar}));
       values.(globalVars{iVar}) = eval(globalVars{iVar});
     end
     
     % Release the Kraken
     javaaddpath(newpath);
     
     % Make your moms happy
     for iVar = 1:numel(globalVars)
       eval(sprintf('global %s', globalVars{iVar}));
       eval(sprintf('%s = values.%s;',globalVars{iVar},globalVars{iVar}));
     end
   end
   
   function isGuava = checkGCClass()
     b = com.google.common.collect.ImmutableSet.builder();
     classPath = b.getClass().getProtectionDomain().getCodeSource().getLocation().getPath();
     isGuava = isempty(strfind(classPath,'google-collect.jar'));
   end
  end
  
end

