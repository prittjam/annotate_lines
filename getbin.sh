#/bin/sh

scp cassandra@tarski:~/ckvs-latest-bin.tar.gz . && tar xvzf ckvs-latest-bin.tar.gz --strip 1 && rm ckvs-latest-bin.tar.gz
