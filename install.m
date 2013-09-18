% Install cassandra connector

%% Compile cassandra connector

if ~exist(CassandraDataStore.ConnectorJarFile,'file')
  if ~isunix()
    error(['Windows platforms not supported.\n' ...
    'Compile cassandra-connector with maven by hand.']);
  end

  if system('which mvn') ~= 0
    error('Maven not found.');
  end
  
  if system('mvn install') ~= 0
    error('Error compiling cassandra-connector.');
  end
  fprintf('\nCassandra-connector succesfully compiled.\n');
else
  fprintf('\nCassandra-connector already compiled.\n');
end


%% Download guava library

fprintf(['\nIn order to run cassandra-driver, google-collection \n' ...
  'from the Matlab distribution must be replaced with its newer version\n' ...
  'which is a part of guava library.\n']);

libDir = 'lib';
guavaDir = fullfile(CassandraDataStore.getClassFilePath(), libDir);

guavaJarPattern = fullfile(guavaDir,'guava*.jar');
guavaFiles = dir(guavaJarPattern);
guavaIsInstalled = ~isempty(guavaFiles);

if ~guavaIsInstalled
  fprintf('\nDownloading guava...\n');
  if system(sprintf('mvn -DoutputDirectory=%s -DincludeArtifactIds=guava dependency:copy-dependencies',...
      guavaDir)) ~= 0
    error('\nError downloading guava.\n');
  end
  guavaFiles = dir(guavaJarPattern);
else
  fprintf('\nGuava library already downloaded.\n');
end

guavaJar = fullfile(guavaDir, guavaFiles(1).name);

prompt = sprintf('Install guava library in %s? Y/N [Y]: ',fullfile(prefdir, libDir));
installInPrefDir = input(prompt,'s');
if isempty(installInPrefDir)
    installInPrefDir = 'Y';
end

if strcmp(installInPrefDir,'Y')
  guavaDir = fullfile(prefdir, libDir);
  copyfile(guavaJar, guavaDir);
  guavaJar = fullfile(guavaDir, guavaFiles(1).name);
end  



%% Prepare to replace google-collect.jar with guava in static javaclasspath

switch version('-release')
  case {'2010a','2011b'}
    % In older Matlabs, classpath.txt in current directory is used. It must
    % be a copy of Matlab's classpath file.
    matlabClassPathDir = toolboxdir('local');
    matlabClassPathFile = fullfile(matlabClassPathDir,'classpath.txt');
    newClassPathFile = fullfile(CassandraDataStore.getClassFilePath(),'classpath.txt');

    % Pattern to build a path to google-collect jar
    matlabGCJarLine = fullfile('$matlabroot','java','jarext','google-collect.jar');
    helpers.replaceInFile(matlabGCJarLine, guavaJar, matlabClassPathFile, newClassPathFile);
    
    fprintf(['\nIn Matlab R2011b the only way how to affect the static class path\n' ...
      'is to start matlab with different classpath.txt file. ' ...
      'This file is \nloaded either from the $PWD or from: \n\n\t%s\n\n' ...
      'A new classpath.txt file generated and saved in: \n\n\t%s\n' ...
      ], matlabClassPathFile, newClassPathFile);
  case {'2012a','2012b','2013a','2013b'}
    % In newer Matlab's there is possibility to affect the static
    % javaclasspath with the file javaclasspath.txt

    fprintf(['\nIn Matlab >R2012b, the static java class path can be\n' ...
      'changed with generated javaclasspath.txt in $PWD or %s.\n'], prefdir);
    
    prompt = sprintf('\nDo you want to copy generated javaclasspath.txt to %s?\nThe file be overwritten Y/N [Y]: ', prefdir);
    installInPrefDir = input(prompt,'s');
    if isempty(installInPrefDir)
        installInPrefDir = 'Y';
    end
    if installInPrefDir
      classPathFileDir = prefdir;
    else
      classPathFileDir = CassandraDataStore.getClassFilePath();
      fprintf('\nIn order to run cassandra-connector, file:\n%s\n must be in Matlab''s start-up folder. \n',...
        fullfile(classPathFileDir,'javaclasspath.txt'));
    end
    
    newClassPathFile = fullfile(classPathFileDir,'javaclasspath.txt');
    fd = fopen(newClassPathFile,'w');
    fprintf(fd, '<before>\n%s\n', guavaJar);
    fclose(fd);
    
    fprintf('\nIn order to run cassandra connector you must restart Matlab.\n');
  otherwise
    error('Unsupported version %s of Matlab.', version('-release'));
end

