%% Cassandra connector test
% In order to run this test, the connector must be installed, run the script:
%   install;

clear all;
clear java;

% For cassandra data modeling see:
% http://www.datastax.com/documentation/cql/3.0/webhelp/index.html#cql/ddl/ddl_anatomy_table_c.html
keyspace = 'matlab';
table = 'test4'; % Name of the table

% Define the data structure. The resulting table will look like:
%
%    id(int, key) | name(string, key)    | data (blob)
%   --------------+----------------------+-----------
%
%  With two keys - an integer and a string. The supported column types are:
%
%    Column type       Accepted Matlab types
%    INT               Numerical integer values, indexes
%    TEXT              Matlab string
%    DATA              Any Matlab data types, serialised into BLOB columns.
%                      See helpers.serialize for details.
%    FILE              Store - String with path to the file,
%                      Load  - File data in byte array.
%    MD5DATA           Store - Any matlab data type (is being serialised)
%                      Load  - MD5 hash of the data.
%    MD5FILE           Store - String with path to the file
%                      Load  - MD5 hash of the file data.
%    IMAGEFILE         Store - String with path to the image file,
%                              see Java ImageIO API for supp. types.
%                      Load  - Matlab array with image raster. Same as 
%                              imread(<stored image path>);

keysStruct = struct('id', ColumnType.INT,'name',ColumnType.TEXT);
dataStruct = struct('data',ColumnType.DATA);

% Construct the datastore object
cds = CassandraDataStore(keyspace, table, keysStruct, dataStruct);

% Store some data... Data are passed in the same structures as the
% structures used for definition of table layout.
cds.store(struct('id', 1,'name','tralala'),struct('data','stringy..'));
cds.store(struct('id', 2,'name','tralala'),struct('data',magic(3)));


% Load back the data. To load the data, define only the key of the rows 
% to load. Data returned in the same structures as stored.
a1 = cds.load(struct('id', 1,'name','tralala'));
a2 = cds.load(struct('id', 2,'name','tralala'));

% Get number of rows
fprintf('Num rows: %d\n', double(cds.getNumRows()));

% Delete row defined by key.
cds.deleteRow(struct('id', 2,'name','tralala'));

% Close the connection to cassandra.
cds.close();
delete(cds);