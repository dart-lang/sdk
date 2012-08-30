// TODO(jacobr): convert this file to Dart once Dart supports all of the
// nodejs functionality used here.  For example, search for all occurences of
// "http." and "fs."
var http = require('http');
var fs = require('fs');

try {
  fs.mkdirSync('output/crawl');
} catch (e) {
  // It doesn't matter if the directories already exist.
}

var domTypes = JSON.parse(fs.readFileSync('data/domTypes.json', 'utf8'));

var cacheData = {};

function scrape(filename, link) {
  console.log(link);
  var httpsPrefix = "https://";
  var prefix = 'https://developer.mozilla.org/';
  var notFoundPrefix = 'https://developer.mozilla.org/Article_not_found?uri=';
  if (link.indexOf(prefix) != 0 ) {
    throw "Unexpected url: " + link;
  }
  var scrapePath = "/search?q=cache:" + link;
  // We crawl content from googleusercontent.com so we don't have to worry about
  // crawler politeness like we would have to if scraping developer.mozilla.org
  // directly.
  var options = {
    host: 'webcache.googleusercontent.com',
    path: scrapePath,
    port: 80,
    method: 'GET'
  };

  var req = http.request(options, function(res) {
    res.setEncoding('utf8');
    var data='';

    res.on('data', function(d) {
      data += d;
    });
    var onClose = function(e) {
      console.log("Writing crawl result for " + link);
      fs.writeFileSync("output/crawl/" + filename + ".html", data, 'utf8');
    }
    res.on('close', onClose);
    res.on('end', onClose);
  });
  req.end();

  req.on('error', function(e) {
    throw "Error " + e + " scraping " + link;
  });
}

for (var i = 0; i < domTypes.length; i++) {
  var type = domTypes[i];

  // Json containing the search results for the current type.
  var data = fs.readFileSync("output/search/" + type + ".json");
  json = JSON.parse(data);
  if (!('items' in json)) {
    console.warn("No search results for " + type);
    continue;
  }
  var items = json['items'];

  var entry = [];
  cacheData[type] = entry;

  // Hardcode the correct matching url for a few types where the search engine
  // gets the wrong answer.
  var link = null;
  if (type == 'Screen') {
    link = 'https://developer.mozilla.org/en/DOM/window.screen';
  } else if (type == 'Text') {
    link = 'https://developer.mozilla.org/en/DOM/Text';
  } else if (type == 'Touch') {
    link = 'https://developer.mozilla.org/en/DOM/Touch';
  } else if (type == 'TouchEvent' || type == 'webkitTouchEvent' || type == 'WebkitTouchEvent' || type == 'WebKitTouchEvent') {
    link = 'https://developer.mozilla.org/en/DOM/TouchEvent';
  } else if (type == 'HTMLSpanElement') {
    link = 'https://developer.mozilla.org/en/HTML/Element/span';
  } else if (type == 'HTMLPreElement') {
    link = 'https://developer.mozilla.org/en/HTML/Element/pre';
  } else if (type == 'HTMLFrameElement') {
    link = 'https://developer.mozilla.org/en/HTML/Element/frame';
  } else if (type == 'HTMLFrameSetElement') {
    link = 'https://developer.mozilla.org/en/HTML/Element/frameset';
  } else if (type == 'Geolocation') {
    link = 'https://developer.mozilla.org/en/nsIDOMGeolocation;'
  } else if (type == 'Notification') {
    link = 'https://developer.mozilla.org/en/DOM/notification';
  } else if (type == 'IDBDatabase') {
    link = 'https://developer.mozilla.org/en/IndexedDB/IDBDatabase'
  }
  if (link != null) {
    entry.push({index: 0, link: link, title: type});
    scrape(type + 0, link);
    continue;
  }

  for (j = 0; j < items.length; j++) {
    var item = items[j];
    var prefix = 'https://developer.mozilla.org/';
    var notFoundPrefix = 'https://developer.mozilla.org/Article_not_found?uri=';
    // Be optimistic and replace article not found links with links to where the
    // article should be.
    link = item['link'];
    if (link.indexOf(notFoundPrefix) == 0) {
      link = prefix + link.substr(notFoundPrefix.length);
    }

    entry.push({index: j, link: link, title: item['title']});
    scrape(type + j, link);
  }
}

fs.writeFileSync('output/crawl/cache.json', JSON.stringify(cacheData, null, ' '), 'utf8');
