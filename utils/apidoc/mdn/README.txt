Here's a rough walkthrough of how this works. The ultimate output file is
database.filtered.json.

full_run.sh executes all of the scripts in the correct order.

search.js
- read data/domTypes.json
- for each dom type:
  - search for page on www.googleapis.com
  - write search results to output/search/<type>.json
    . this is a list of search results and urls to pages

crawl.js
- read data/domTypes.json
- for each dom type:
  - for each output/search/<type>.json:
    - for each result in the file:
      - try to scrape that cached MDN page from webcache.googleusercontent.com
      - write mdn page to output/crawl/<type><index of result>.html
- write output/crawl/cache.json
  . it maps types -> search result page urls and titles

extract.sh
- compile extract.dart to js
- run extractRunner.js
  - read data/domTypes.json
  - read output/crawl/cache.json
  - read data/dartIdl.json
  - for each scraped search result page:
    - create a cleaned up html page in output/extract/<type><index>.html that
      contains the scraped content + a script tag that includes extract.dart.js.
    - create an args file in output/extract/<type><index>.html.json with some
      data on how that file should be processed
    - invoke dump render tree on that file
    - when that returns, parse the console output and add it to database.json
    - add any errors to output/errors.json
  - save output/database.json

extract.dart
- xhr output/extract/<type><index>.html.json
- all sorts of shenanigans to actually pull the content out of the html
- build a JSON object with the results
- do a postmessage with that object so extractRunner.js can pull it out

- run postProcess.dart
  - go through the results for each type looking for the best match
  - write output/database.html
  - write output/examples.html
  - write output/obsolete.html
  - write output/database.filtered.json which is the best matches