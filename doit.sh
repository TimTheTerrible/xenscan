#!/bin/bash

BASE="${HOME}/Projects"
DATACENTERS="fal arc bal"

for DC in ${DATACENTERS}; do
	echo "Deploying to ${DC}..."
	scp ${BASE}/TimUtil/TimUtil.pm ${DC}:.
	scp ${BASE}/TimDB/TimDB.pm ${DC}:.
	scp ${BASE}/xenscan/xenscan.pl ${DC}:.

	echo "Scanning ${DC}..."
	ssh ${DC} -R 5432:localhost:5432 "./xenscan.pl --debug=error,warn,info --no-test --no-limit"
done
