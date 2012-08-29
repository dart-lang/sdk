var fs = require('fs');
var util = require('util');
var exec = require('child_process').exec;
var path = require('path');

// We have numProcesses extraction tasks running simultaneously to improve
// performance.  If your machine is slow, you may need to dial back the
// parallelism.
var numProcesses = 8;

var db = {};
var metadata = {};
var USE_VM = false;

// Warning: START_DART_MESSAGE must match the value hardcoded in extract.dart
// TODO(jacobr): figure out a cleaner way to parse this data.
var START_DART_MESSAGE = "START_DART_MESSAGE_UNIQUE_IDENTIFIER";
var END_DART_MESSAGE = "END_DART_MESSAGE_UNIQUE_IDENTIFIER";

var domTypes = JSON.parse(fs.readFileSync('data/domTypes.json',
    'utf8').toString());
var cacheData = JSON.parse(fs.readFileSync('output/crawl/cache.json',
    'utf8').toString());
var dartIdl = JSON.parse(fs.readFileSync('data/dartIdl.json',
    'utf8').toString());

try {
  fs.mkdirSync('output/extract');
} catch (e) {
  // It doesn't matter if the directories already exist.
}

var errorFiles = [];
// TODO(jacobr): blacklist these types as we can't get good docs for them.
// ["Performance"]

function parseFile(type, onDone, entry, file, searchResultIndex) {
  var inputFile;
  try {
    inputFile = fs.readFileSync("output/crawl/" + file, 'utf8').toString();
  } catch (e) {
    console.warn("Couldn't read: " + file);
    onDone();
    return;
  }

  var inputFileRaw = inputFile;
  // Cached pages have multiple DOCTYPE tags.  Strip off the first one so that
  // we have valid HTML.
  // TODO(jacobr): use a regular expression instead of indexOf.
  if (inputFile.toLowerCase().indexOf("<!doctype") == 0) {
    var matchIndex = inputFile.toLowerCase().indexOf("<!doctype", 1);
    if (matchIndex == -1) {
      // not a cached page.
      inputFile = inputFileRaw;
    } else {
      inputFile = inputFile.substr(matchIndex);
    }
  }

  // Disable all existing javascript in the input file to speed up parsing and
  // avoid conflicts between our JS and the JS in the file.
  inputFile = inputFile.replace(/<script type="text\/javascript"/g,
      '<script type="text/ignored"');

  var endBodyIndex = inputFile.lastIndexOf("</body>");
  if (endBodyIndex == -1) {
    // Some files are missing a closing body tag.
    endBodyIndex = inputFile.lastIndexOf("</html>");
  }
  if (endBodyIndex == -1) {
    if (inputFile.indexOf("Error 404 (Not Found)") != -1) {
      console.warn("Skipping 404 file: " + file);
      onDone();
      return;
    }
    throw "Unexpected file format for " + file;
  }

  inputFile = inputFile.substring(0, endBodyIndex) +
    '<script type="text/javascript">\n' +
    '  if (window.layoutTestController) {\n' +
    '    var controller = window.layoutTestController;\n' +
    '    controller.dumpAsText();\n' +
    '    controller.waitUntilDone();\n' +
    '  }\n' +
    'window.addEventListener("message", receiveMessage, false);\n' +
    'function receiveMessage(event) {\n' +
     '  if (event.data.indexOf("' + START_DART_MESSAGE + '") != 0) return;\n' +
     '  console.log(event.data + "' + END_DART_MESSAGE + '");\n' +
     // We feature detect whether the browser supports layoutTestController
     // so we only clear the document content when running in the test shell
     // and not when debugging using a normal browser.
     '  if (window.layoutTestController) {\n' +
     '    document.documentElement.textContent = "";\n' +
     '    window.layoutTestController.notifyDone();\n' +
     '  }\n' +
     '}\n' +
    '</script>\n' +
    (USE_VM ?
      '<script type="application/dart" src="../../extract.dart"></script>' :
      '<script type="text/javascript" src="../../output/extract.dart.js">' +
      '</script>') +
      '\n' + inputFile.substring(endBodyIndex);

  console.log("Processing: " + file);
  var absoluteDumpFileName = path.resolve("output/extract/" + file);
  fs.writeFileSync(absoluteDumpFileName, inputFile, 'utf8');
  var parseArgs = {
    type: type,
    searchResult: entry,
    dartIdl: dartIdl[type]
  };
  fs.writeFileSync(absoluteDumpFileName + ".json", JSON.stringify(parseArgs),
      'utf8');

  /*
  // TODO(jacobr): Make this run on platforms other than OS X.
  var cmd = '../../../client/tests/drt/DumpRenderTree.app/Contents/MacOS/' +
      'DumpRenderTree ' + absoluteDumpFileName;
  */
  // TODO(eub): Make this run on platforms other than Linux.
  var cmd = '../../../client/tests/drt/DumpRenderTree ' + absoluteDumpFileName;
  console.log(cmd);
  exec(cmd,
    function (error, stdout, stderr) {
      var msgIndex = stdout.indexOf(START_DART_MESSAGE);
      console.log('all: ' + stdout);
      console.log('stderr: ' + stderr);
      if (error !== null) {
        console.log('exec error: ' + error);
      }

      // TODO(jacobr): use a regexp.
      var msg = stdout.substring(msgIndex + START_DART_MESSAGE.length);
      msg = msg.substring(0, msg.indexOf(END_DART_MESSAGE));
      if (!(type in db)) {
        db[type] = [];
      }
      try {
        db[type][searchResultIndex] = JSON.parse(msg);
      } catch(e) {
        // Write the errors file every time there is an error so that if the
        // user aborts the script, the error file is valid.
        console.warn("error parsing result for " + type + " file= "+ file);
        errorFiles.push(file);
        fs.writeFileSync("output/errors.json",
            JSON.stringify(errorFiles, null, ' '), 'utf8');
      }
      onDone();
  });
}

var tasks = [];

var numPending = numProcesses;

function processNextTask() {
  numPending--;
  if (tasks.length > 0) {
    numPending++;
    var task = tasks.pop();
    task();
  } else {
    if (numPending <= 0) {
      console.log("Successfully completed all tasks");
      fs.writeFileSync("output/database.json",
          JSON.stringify(db, null, ' '), 'utf8');
    }
  }
}

function createTask(type, entry, index) {
  return function () {
    var file = type + index + '.html';
    parseFile(type, processNextTask, entry, file, index);
  };
}

for (var i = 0; i < domTypes.length; i++) {
  var type = domTypes[i];
  var entries = cacheData[type];
  if (entries != null) {
    for (var j = 0; j < entries.length; j++) {
      tasks.push(createTask(type, entries[j], j));
    }
  } else {
    console.warn("No crawled files for " + type);
  }
}

for (var p = 0; p < numProcesses; p++) {
  processNextTask();
}
