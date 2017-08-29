classdef CassandraDataStore
  %CassandraDataStore Connector to Cassandra as Key-Value store
  %   Matlab frontend to Appache Cassandra distributed database accessing
  %   the data in Multiple-key/Multiple-values data storage where the keys
  %   and values are defined in the object constructor. Data are then
  %   managed by load/store methods of the constructed object which
  %   represents a single ColumnFamily in the Cassandra database.
  %
  %   Connector supports several ColumnTypes with various side-effects
  %   (e.g. loading a file in Java, computation of MD5 of data,
  %   serialisation of Matlab data types etc.). See the documentation of
  %   the ColumnType enumeration.
  %
  %   INSTALLATION
  %     see help for install.m
  %
  %   See also: ColumnType, install, http://www.datastax.com/docs
  
  % AUTHOR: Karel Lenc
  
  % TODO make it work on default with cell arrays, not structs.
  %   reason - it is simpler to work with cell arrays than structs and it
  %   may be faster as well as it would need less structs and no dynamic
  %   field allocation...
  % TODO change the cool stuff with the conversions in java etc. to hooks,
  % rather than to column types. It would be much clearer then.
    
  properties (Constant)
    % Path to the jar of the connector
    ConnectorJarFile = fullfile(CassandraDataStore.getClassFilePath(),...
      '/target/ckvs-0.0.1-jar-with-dependencies.jar');
  end
  
  properties (Constant, Hidden)
    % Change this to any log4j level to limit the verbosity. Before the
    % changes take effect, 'clear all' must be called. This value is set
    % globally.
    LogLevel = 'WARN';
  end
  
  properties (SetAccess = protected, GetAccess = public)
    Keyspace;     % Name of the keyspace
    ColumnFamily; % Name of the ColumnFamily
    Keys;         % Structure defining the key columns
    Values;       % Structure defining the value columns
    KeyFields;    % Cell array of the key comlumns names
    ValueFields;  % Cell array of the value columns names
    % Cassandra settings
    Opts = struct(...
      'nodes',char({'localhost'}),... % Seeds
      'port',-1,...                   % Used port
      'replicationFactor',2 ...       % Replication factor for new KeySpace
      );
  end
  
  properties (SetAccess = protected, GetAccess = public, Hidden)  
    % JAVA objects
    jvCassConn;   % Object for a connection
    jvDataStore;  % Object for a data store
    jvKeyspace;   % KeySpace java object
    jvLogger;     % Reference to the log4j logger
  end
  
  methods
    function obj = CassandraDataStore(keyspace, columnFamily, ...
        keysDef, valuesDef, varargin)
      %CassandraDataStore Create a cassandra key-value store object
      %  obj = CassandraDataStore(KEYSPACE, COL_FAMILY, KEYS_DEF, VALS_DEF)
      %  constructs a CassandraDataStore object which handles data in
      %  Cassandra table defined by KEYSPACE name and COL_FAMILY name. The
      %  columns of the table is defined by the KEYS_DEF structure (columns
      %  used as keys) and VALS_DEF structure (columns used as data). Both 
      %  KEYS_DEF and VALS_DEF are of the following format:
      %     COLUMNS_DEF = struct('col_name',ColumnType.COLTYPE,...)
      %  Valid KEYS can have columnt type only in COLTYPE = {INT, TEXT}.
      %  The load/store methods handle the data in the same structures, 
      %  replacing the ColumnType objects with the data values. For the
      %  supported ColumnTypes and their side effects see documentation for
      %  ColumnType enumeration.
      %
      %  obj = CassandraDataStore(,'OPT_NAME','OPT_VALUE',...) Define
      %  further options:
      %  
      %   'nodes', NODES :: {'localhost'}
      %     Specify the cassandra seed nodes NODES, cell array of strings.
      %
      %   'port', PORT :: -1
      %      Specify the port on which the cassandra service is runnign.
      %      Keep -1 for default.
      %
      %   'replicationFactor' :: 2
      %       Replication factor of a newly created KeySpace.
      %
      %  When the column family of the given name and keyspace does not
      %  exist, it is created. When it does exist, the structure of the
      %  table is not anyhow checked and the errors are thrown when data
      %  are loded/stored (as wrong CQL queries are generated).
      
      if ~usejava('jvm')
        error(['Cassandra connector needs Java Virtual Machine.'...
          'Run Matlab without -nojvm argument.']);
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
         error(['Guava library has not been properly loaded.'...
           'Is it a valid jar file?']);
      end
      
      % Set the global loggin level
      java.lang.System.setProperty('casscon.loglevel',obj.LogLevel);

      if ~ismember(obj.ConnectorJarFile,javaclasspath('-dynamic')) 
        warning('Knock-Knock - Matlab is going to delete all your global variables!');
        obj.decentJavaaddpath(obj.ConnectorJarFile);
      end
      
      obj.Keyspace = keyspace;
      obj.ColumnFamily = columnFamily;
      
      if ~isstruct(keysDef) || ~isstruct(valuesDef)
        error('Keys and data structure definition must be a struct.');
      end
      
      obj.checkDataDef(keysDef);
      obj.checkDataDef(valuesDef);
      
      obj.Keys = keysDef;
      obj.KeyFields = fieldnames(keysDef);
      obj.Values = valuesDef;
      obj.ValueFields = fieldnames(valuesDef);
      
      obj.Opts = helpers.vl_argparse(obj.Opts, varargin);
      
      obj.jvCassConn = obj.getConnection();
      
      jvKeyColumns = CassandraDataStore.matlabDataDef2Java(keysDef, true);
      jvDataColumns = CassandraDataStore.matlabDataDef2Java(valuesDef, false);
      jvKeySpace = obj.buildJvKeyspace();
      
      obj.jvDataStore =  obj.jvCassConn.buildDataStore(jvKeySpace, ...
        columnFamily, jvKeyColumns, jvDataColumns);
    end
    
    function close(obj)
      % close Close the connection to cassandra servers. Destructor.
      obj.jvCassConn.close();
    end
    
    function store(obj, keys, values, doRunHooks)
      % store Store values defined by keys into CassandraDataStore
      %   obj.store(KEYS,VALUES) Store a row [KEYS VALUES] into the
      %   cassandra data store. If a row with same KEYS exist, values are
      %   replaced with the new VALUES. KEYS and VALUES are structs:
      %      COLDATA = struct('COL_NAME', COL_VALUE, ...)
      if nargin < 4
        doRunHooks = true;
      end
      
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      if ~CassandraDataStore.hasFields(values, obj.ValueFields)
        error('Values structure does not correspond to initialised data store.');
      end
     
      dataCell = struct2cell(keys)';
      dataCell = [dataCell cell(1, numel(obj.ValueFields))];
      
      % Run the pre-store hooks
      ai = numel(obj.KeyFields) + 1;
      for i = 1:numel(obj.ValueFields)
        clmnSpec = obj.Values.(obj.ValueFields{i});
        if doRunHooks
          dataCell{ai} = clmnSpec.preStoreHook(values.(obj.ValueFields{i}));
        else
          dataCell{ai} = values.(obj.ValueFields{i});
        end
        ai = ai + 1;
      end
      
      dataJvArrList = CassandraDataStore.cellToJvArrList(dataCell);
      obj.jvDataStore.storeData(dataJvArrList);
    end
    
    function values = load(obj, keys, doRunHooks)
      %load Load data from the CassandraDataStore
      %  VALUES = obj.load(KEYS) Load VALUES from a row in
      %  CassandraDataSTore with the specified KEYS. When the row does not
      %  exist, exception is thrown. Use the exist method instead.
      %  KEYS and VALUES are structs:
      %      COLDATA = struct('COL_NAME', COL_VALUE, ...)
      if nargin < 3
        doRunHooks = true;
      end
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      
      keysCell = struct2cell(keys)';
      
      keysJvArrList = CassandraDataStore.cellToJvArrList(keysCell);
      dataResultsSet = obj.jvDataStore.loadData(keysJvArrList);
      
      if dataResultsSet.size() == 0
        values = [];
        return;
      end
      
      % Load the values from the cassandra's ResultSet
      values = struct();
      for i = 1:numel(obj.ValueFields)
        fld = obj.ValueFields{i};
        clmnSpec = obj.Values.(fld);
        if doRunHooks
          values.(fld) = clmnSpec.postLoadHook(dataResultsSet.get(i-1));
        else
          values.(fld) = dataResultsSet.get(i-1);
        end
      end
    end
    
        
    function res = exist(obj, keys)
      % exist Check whether a row exist
      %   RES = obj.exist(KEY) Checks whether a row defined by the KEYS
      %   does exist (i.e. RES=true).
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      
      keysCell = struct2cell(keys)';
      
      jvArrList = CassandraDataStore.cellToJvArrList(keysCell);
      res = obj.jvDataStore.existData(jvArrList);
    end
    
    function deleteRow(obj, keys)
      % deleteRow Delete a row
      %   obj.deleteRow(KEYS) Delete row defined by keys.
      %
      %   NOTE: Thanks to cassandra design, the fact that the row has been
      %   deleted may be in some cases not distributed to all nodes 
      %   (see http://goo.gl/xaOCJm (Cassandra 1.2 Documentation)
      if ~CassandraDataStore.hasFields(keys, obj.KeyFields)
        error('Keys structure does not correspond to initialised data store.');
      end
      
      kyesCell = struct2cell(keys)';
      
      keysJvArrList = CassandraDataStore.cellToJvArrList(kyesCell);
      obj.jvDataStore.deleteData(keysJvArrList);
    end
    
    function resultsSet = execute(obj, query)
      % execute Execute a CQL query
      %   RESULTSET = obj.execute(QUERY) Execute a CQL query defined in
      %   QUERY as a string. Returns RESULTSET, java object of class 
      %   com.datastax.driver.core.ResultSet.
      resultsSet = obj.jvDataStore.executeQuery(query);
    end
    
    function numRows = getNumRows(obj)
      % getNumRows Get number of rows in a column family.
      %   NUM_ROWS = obj.getNumRows() Returns NUM_ROWS in a current column
      %   family corresponding to the data store configuration.
      %   NOTE: Thanks to the distributed nature of the cassandra database,
      %   in case of tables with many rows, this command ends up with
      %   timeout.
      numRows = obj.jvDataStore.getNumRows();
    end
    
    function keys = buildKeys(obj, varargin)
      % buildKeys Create a keys structure from the arguments
      % KEYS_STRUCTURE = obj.buildKeys(VAL1,VAL2,...) Builds a
      % a structure defined as:
      %  KEYS_STRUCTURE = struct(obj.KeyFields{1},VAL1, ...
      %                          obj.KeyFields{2},VAL2, ... );
      keys = obj.buildStruct(obj.KeyFields, varargin);
    end
    
    function values = buildValues(obj, varargin)
      % buildValues Create a values structure from the arguments
      % VALUES_STRUCTURE = obj.buildValues(VAL1,VAL2,...) Builds a
      % a structure defined as:
      %  VALUES_STRUCTURE = struct(obj.ValueFields{1},VAL1, ...
      %                            obj.ValueFields{2},VAL2, ... );
      values = obj.buildStruct(obj.ValueFields, varargin);
    end
  end
  
  methods (Hidden)
    function delete(obj)
      % Destructor
      obj.close();
    end
  end
  
  methods (Access = protected, Hidden)
        
    function jvKeySpace = buildJvKeyspace(obj)
      % buildJvKeyspace Get an object of com.cmp.ckvs.KeySpace
      % In java, this is implemented with the builder pattern
      builder = com.cmp.ckvs.KeySpace.builder(obj.Keyspace);
      jvKeySpace = builder.replicationFactor(obj.Opts.replicationFactor)...
        .build();
    end
    
    function conn = getConnection(obj)
      % getConnection Get a com.cmp.ckvs.CassandraConnector object
      % Stores the connection in persistent map so that several objects of
      % the CassandraDataStore use a single connection when they have equal
      % connection configurations.
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
  
  methods (Static, Hidden)
    function str = buildStruct(fields, values)
      % buildStruct Build a structure from cell arrays of fields and values
      if numel(fields) ~= numel(values)
        error('Invalid number of values.');
      end
      args = [fields(:)'; values(:)'];
      str = struct(args{:});
    end
    
    function res = hasFields(struct, fields)
     % hasFields Check whether a structure has got certain fields
     res = true;
     strFields = fieldnames(struct);
     if numel(fields) ~= numel(fields) || ~all(ismember(strFields, fields))
       res = false;
     end
   end
    
   function checkDataDef(dataStructure)
     % checkDataDef Check whether struct. is valid data def.
     % In data definition structure, each value must be an object of
     % ColumnType.
      flds = fieldnames(dataStructure);
      for fldId = 1:numel(flds)
        val = dataStructure.(flds{fldId});
        if ~isa(val,'ColumnType')
          error('Value of field %s is not an instance of ColumnType.', flds{fldId});
        end
      end
   end
    
   function jvArrList = cellToJvArrList(cellArray)
     % cellToJvArrList Convert cell array to Java Array list
      jvArrList = java.util.ArrayList;
      for i = 1:numel(cellArray)
        jvArrList.add(cellArray{i});
      end
   end
   
   function jvStringArr = cellToJvStringArr(cellArray)
     % cellToJvStringArr Convert cell array of strings to javaArray
      jvStringArr = javaArray('java.lang.String',numel(cellArray));
      for i = 1:numel(cellArray)
        jvStringArr(i) = 	java.lang.String(cellArray{i});
      end
   end
    
   function jvArrList = matlabDataDef2Java(dataDefStructure, isKey)
     % matlabDataDef2Java Convert data def. structure to java object
      flds = fieldnames(dataDefStructure);
      jvColumns = cell(1,numel(flds));
      for fldId = 1:numel(flds)
        fldName = flds{fldId};
        ds = dataDefStructure.(fldName);
        if isKey && ~ds.isValidKey()
          error('Data type %s of column %s cannot be used as a key.', ...
            char(ds), fldName);
        end
        jvColumns{fldId} = ds.buildJvColumn(fldName);
      end
      jvArrList = CassandraDataStore.cellToJvArrList(jvColumns);
   end
   
   function path = getClassFilePath()
     % Get the path of the class source file
     classFname = mfilename('fullpath');
     [path, ~] = fileparts(classFname);
   end
   
   function decentJavaaddpath(newpath)
     % decentJavaaddpath Calls javaaddpath trying to preserve global
     % variables. Though it clears links to existing variables (global
     % varname has to be called again, but the data are preserved).
     
     % Useful function against the fact that javaaddpath calls clear java
     % which clears all global variables.
     globalVars = who('global');
     % Save the whales
     for iVar = 1:numel(globalVars)
       eval(sprintf('global %s', globalVars{iVar}));
       values.(globalVars{iVar}) = eval(globalVars{iVar});
     end
     
     % Release the Kraken
     javaaddpath(newpath);
     
     % Make your mom happy by reintroducing the global variables
     for iVar = 1:numel(globalVars)
       eval(sprintf('global %s', globalVars{iVar}));
       eval(sprintf('%s = values.%s;',globalVars{iVar},globalVars{iVar}));
     end
   end
   
   function isGuava = checkGCClass()
     % Check whether the google collections are properly linked not to the
     % older version distributed with Matlab, but with the newer version
     % distributed in guava library as those two drivers are not binary
     % compatible and cassandra driver is using functions available in
     % Guava but not in google collections.
     
     % Check it using reflection
     b = com.google.common.collect.ImmutableSet.builder();
     classPath = b.getClass().getProtectionDomain().getCodeSource().getLocation().getPath();
     isGuava = isempty(strfind(classPath,'google-collect.jar'));
   end
  end
  
end

