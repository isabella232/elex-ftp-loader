#!/bin/bash

# set RACEDATE from the first argument, if it exists
if [[ ! -z $1 ]] ; then
    RACEDATE=$1
fi

if [[ -z $RACEDATE ]] ; then
    echo 'Provide a race date, such as 2016-02-01'
    exit 1
fi

if [[ -z "$AP_API_KEY" ]] ; then
    echo "Missing environmental variable AP_API_KEY. Try 'export AP_API_KEY=MY_API_KEY_GOES_HERE'."
    exit 1
fi

date "+STARTED: %H:%M:%S"
echo "------------------------------"

echo "Delete temp files from last run"

rm -f races.csv
rm -f reporting_units.csv
rm -f candidates.csv

echo "Drop elex_$1 if it exists"
dropdb elex_$RACEDATE --if-exists

echo "Create elex_$RACEDATE"
psql -l | grep -q elex_$RACEDATE || createdb elex_$RACEDATE

echo "Initialize races"
psql elex_$RACEDATE -c "DROP TABLE IF EXISTS races CASCADE; CREATE TABLE races (
    id varchar,
    raceid varchar,
    racetype varchar,
    racetypeid varchar,
    description varchar,
    electiondate varchar,
    initialization_data boolean,
    lastupdated date,
    national boolean,
    officeid varchar,
    officename varchar,
    party varchar,
    seatname varchar,
    seatnum varchar,
    statename varchar,
    statepostal char(2),
    test boolean,
    uncontested boolean
);"

python init.py --races | psql elex_$RACEDATE -c "COPY races FROM stdin DELIMITER ',' CSV HEADER;"

echo "Initialize reporting units"
psql elex_$RACEDATE -c "DROP TABLE IF EXISTS reporting_units CASCADE; CREATE TABLE reporting_units(
    id varchar,
    reportingunitid varchar,
    reportingunitname varchar,
    description varchar,
    electiondate varchar,
    fipscode char(5),
    initialization_data bool,
    lastupdated date,
    level varchar,
    national varchar,
    officeid varchar,
    officename varchar,
    precinctsreporting integer,
    precinctsreportingpct numeric,
    precinctstotal integer,
    raceid varchar,
    racetype varchar,
    racetypeid varchar,
    seatname varchar,
    seatnum varchar,
    statename varchar,
    statepostal varchar,
    test bool,
    uncontested bool,
    votecount integer
);"

python init.py --reporting_units | psql elex_$RACEDATE -c "COPY reporting_units FROM stdin DELIMITER ',' CSV HEADER;"

echo "Initialize candidates"
psql elex_$RACEDATE -c "DROP TABLE IF EXISTS candidates CASCADE; CREATE TABLE candidates(
    id varchar,
    unique_id varchar,
    candidateid varchar,
    ballotorder integer,
    first varchar,
    last varchar,
    party varchar,
    polid varchar,
    polnum varchar
);"

python init.py --candidates | psql elex_$RACEDATE -c "COPY candidates FROM stdin DELIMITER ',' CSV HEADER;"

echo "Create candidate overrides table"
psql elex_$RACEDATE -c "DROP TABLE IF EXISTS override_candidates CASCADE; CREATE TABLE override_candidates(
    candidate_candidateid varchar,
    nyt_candidate_name varchar,
    nyt_candidate_important bool,
    nyt_candidate_description text,
    nyt_races integer[],
    nyt_winner bool
);"

echo "Create race overrides table"
psql elex_$RACEDATE -c "DROP TABLE IF EXISTS override_races CASCADE; CREATE TABLE override_races(
    nyt_race_preview text,
    nyt_race_result_description text,
    nyt_delegate_allocation text,
    report bool,
    report_description text,
    race_raceid varchar,
    nyt_race_name varchar,
    nyt_race_description text,
    accept_ap_calls bool,
    nyt_called bool,
    nyt_race_important bool
);"

echo "Delete temp files from this run"
rm -f races.csv
rm -f reporting_units.csv
rm -f candidates.csv

echo "------------------------------"
date "+ENDED: %H:%M:%S"