function replaceInFile(str, replace, inFile, outFile)

s = fileread(inFile);

rs = strrep(s, str, replace);

[ofid, message] = fopen(outFile, 'w');
if ofid < 0, error(message); end

fprintf(ofid, '%s', rs);
fclose(ofid);

end