#!/bin/bash
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

echo "Drop elex_$1 if it exists"
dropdb elex_$RACEDATE --if-exists

echo "Create elex_$RACEDATE"
psql elex_$RACEDATE -l | grep -q elex_$RACEDATE || createdb elex_$RACEDATE

echo "Initialize races"
cat /home/ubuntu/elex-loader/fields/races.txt | psql elex_$RACEDATE
python init.py --races | psql elex_$RACEDATE -c "COPY races FROM stdin DELIMITER ',' CSV HEADER;"

echo "Initialize reporting units"
cat /home/ubuntu/elex-loader/fields/reporting_units.txt | psql elex_$RACEDATE
python init.py --reportingunits | psql elex_$RACEDATE -c "COPY reporting_units FROM stdin DELIMITER ',' CSV HEADER;"

echo "Initialize candidates"
cat /home/ubuntu/elex-loader/fields/candidates.txt | psql elex_$RACEDATE
python init.py --candidates | psql elex_$RACEDATE -c "COPY candidates FROM stdin DELIMITER ',' CSV HEADER;"

echo "------------------------------"
date "+ENDED: %H:%M:%S"