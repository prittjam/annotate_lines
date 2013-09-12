function replaceInFile(str, replace, inFile, outFile)

s = fileread(inFile);

rs = strrep(s, str, replace);

ofid = fopen(outFile, 'w');
fprintf(ofid, '%s', rs);
fclose(ofid);

end