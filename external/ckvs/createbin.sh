#!/bin/sh

PUB_PATH=cassandra@tarski:~/ckvs-latest-bin.tar.gz;

tar cvzf target/ckvs-0.0.1-bin.tar.gz target/ckvs-0.0.1-jar-with-dependencies.jar lib/guava-14.0.1.jar && scp ./target/ckvs-*-bin.tar.gz ${PUB_PATH}

