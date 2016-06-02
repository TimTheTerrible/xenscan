#!/bin/bash

psql postgres postgres -c "DROP DATABASE xenscan"
psql postgres postgres -c "CREATE DATABASE xenscan"
psql xenscan xenscan < xenscan.sql
