# This script goes from the input data in data/ all the way to the output data
# in database.filtered.json
# See output/database.html for a human readable view of the extracted data.

rm -rf output
node search.js
node crawl.js
./extract.sh
