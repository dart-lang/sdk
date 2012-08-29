/**
 * Uses a Google Custom Search Engine to find pages on
 * developer.mozilla.org that appear to match types from the Webkit IDL
 */
var https = require('https');
var fs = require('fs');

var domTypes = JSON.parse(fs.readFileSync('data/domTypes.json', 'utf8'));

try {
  fs.mkdirSync('output');
  fs.mkdirSync('output/search');
} catch (e) {
  // It doesn't matter if the directories already exist.
}

function searchForType(type) {
  // Strip off WebKit specific prefixes from type names to increase the chances
  // of getting matches on developer.mozilla.org.
  var shortType = type.replace(/^WebKit/, "");

  // We use a Google Custom Search Engine provisioned for 10,000 API based
  // queries per day that limits search results to developer.mozilla.org.
  // You shouldn't need to, but if you want to create your own Google Custom
  // Search Engine, visit http://www.google.com/cse/
  var options = {
    host: 'www.googleapis.com',
    path: '/customsearch/v1?key=AIzaSyDN1RhE5FafLzLfErGpoYhHlLHeyEkxTkM&' +
          'cx=017193972565947830266:wpqsk6dy6ee&num=5&q=' + shortType,
    port: 443,
    method: 'GET'
  };

  var req = https.request(options, function(res) {
    res.setEncoding('utf8');
    var data = '';
    res.on('data', function(d) {
      data += d;
    });
    var onClose = function(e) {
      fs.writeFile("output/search/" + type + ".json", data, function(err) {
          if (err) throw err;
      console.log('Done searching for ' + type);
      });
    }
    res.on('close', onClose);
    res.on('end', onClose);
  });
  req.end();

  req.on('error', function(e) {
    console.error(e);
  });
}

for (var i = 0; i < domTypes.length; i++) {
  searchForType(domTypes[i]);
}
