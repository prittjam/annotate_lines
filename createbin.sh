#!/bin/sh

mvn package && scp scp ./target/ckvs-*-bin.tar.gz cassandra@tarski:~/ckvs-latest-bin.tar.gz

