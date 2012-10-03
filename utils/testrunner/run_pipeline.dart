// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The default pipeline code for running a test file. */
#library('pipeline');
#import('dart:isolate');
#import('dart:io');
#source('pipeline_utils.dart');

/**
 * The configuration passed in to the pipeline runner; this essentially
 * contains all the command line arguments passded to testrunner plus some
 * synthesized ones.
 */
Map config;

/** Paths to the various generated temporary files. */
String tempDartFile = null;
String tempHtmlFile = null;
String tempChildDartFile = null;
String tempJsFile = null;
String tempChildJsFile = null;

/**
 * Path to the Dart script file referenced from the HTML wrapper (or
 * that is compiled to a Javascript file referenced from the HTML wrapper).
 */
String sourceFile = null;

/** Path to the script file referenced from the HTML wrapper (Dart or JS). */
String scriptFile = null;

/** MIME type of the script. */
String scriptType;

/** Process id for the HTTP server. */
int serverId;

void main() {
  port.receive((cfg, replyPort) {
    config = cfg;
    initPipeline(replyPort);
    wrapStage();
  });
}

/** Initial pipeline stage - generates Dart and HTML wrapper files. */
wrapStage() {
  var tmpDir = config["tempdir"];
  var testFile = config["testfile"];

  // Make sure the temp dir exists.
  var d = new Directory(tmpDir);
  if (!d.existsSync()) {
    d.createSync();
  }

  // Generate names for the generated wrapper files.
  tempDartFile = createTempName(tmpDir, testFile, '.dart');
  if (config["runtime"] != 'vm') {
    tempHtmlFile = createTempName(tmpDir, testFile, '.html');
    if (config["layout"]) {
      tempChildDartFile =
          createTempName(tmpDir, testFile, '-child.dart');
    }
    if (config["runtime"] == 'drt-js') {
      tempJsFile = createTempName(tmpDir, testFile, '.js');
      if (config["layout"]) {
        tempChildJsFile =
            createTempName(tmpDir, testFile, '-child.js');
      }
    }
  }

  // Create the test controller Dart wrapper.
  var directives, extras;

  if (config["layout"]) {
    directives = '''
      #import('dart:uri');
      #import('dart:io');
      #import('dart:math');
      #source('${config["runnerDir"]}/layout_test_controller.dart');
    ''';
    extras = '''
      sourceDir = '${config["expectedDirectory"]}';
      baseUrl = 'file://$tempHtmlFile';
      tprint = (msg) => print('###\$msg');
      notifyDone = (e) => exit(e);
    ''';
  } else if (config["runtime"] == "vm") {
    directives = '''
      #import('dart:io');
      #import('dart:isolate');
      #import('${config["unittest"]}', prefix:'unittest');
      #import('${config["testfile"]}', prefix: 'test');
      #source('${config["runnerDir"]}/standard_test_runner.dart');
    ''';
    extras = '''
      includeFilters = ${config["include"]};
      excludeFilters = ${config["exclude"]};
      tprint = (msg) => print('###\$msg');
      notifyDone = (e) {};
    ''';
  } else {
    directives = '''
      #import('dart:html');
      #import('dart:isolate');
      #import('${config["unittest"]}', prefix:'unittest');
      #import('${config["testfile"]}', prefix: 'test');
      #source('${config["runnerDir"]}/standard_test_runner.dart');
    ''';
    extras = '''
      includeFilters = ${config["include"]};
      excludeFilters = ${config["exclude"]};
      tprint = (msg) => query('#console').addText('###\$msg\\n');
      notifyDone = (e) => window.postMessage('done', '*');
    ''';
  }

  var action = 'process(test.main, unittest.runTests)';
  if (config["layout-text"]) {
    action = 'runTextLayoutTests()';
  } else if (config["layout-pixel"]) {
    action = 'runPixelLayoutTests()';
  } else if (config["list-tests"]) {
    action = 'process(test.main, listTests)';
  } else if (config["list-groups"]) {
    action = 'process(test.main, listGroups)';
  } else if (config["isolate"]) {
    action = 'process(test.main, runIsolateTests)';
  }

  logMessage('Creating $tempDartFile');
  writeFile(tempDartFile, '''
    #library('test_controller');
    $directives

    main() {
      immediate = ${config["immediate"]};
      includeTime = ${config["time"]};
      passFormat = '${config["pass-format"]}';
      failFormat = '${config["fail-format"]}';
      errorFormat = '${config["error-format"]}';
      listFormat = '${config["list-format"]}';
      regenerate = ${config["regenerate"]};
      summarize = ${config["summary"]};
      testfile = '$testFile';
      drt = '${config["drt"]}';
      $extras
      $action;
    }
  ''');

  // Create the child wrapper for layout tests.
  if (config["layout"]) {
    logMessage('Creating $tempChildDartFile');
    writeFile(tempChildDartFile, '''
        #library('layout_test');
        #import('dart:math');
        #import('dart:isolate');
        #import('dart:html');
        #import('dart:uri');
        #import('${config["unittest"]}', prefix:'unittest');
        #import('$testFile', prefix: 'test');
        #source('${config["runnerDir"]}/layout_test_runner.dart');

        main() {
          includeFilters = ${config["include"]};
          excludeFilters = ${config["exclude"]};
          runTests(test.main);
        }
    ''');
  }


  // Create the HTML wrapper and compile to Javascript if necessary.
  var isJavascript = config["runtime"] == 'drt-js';
  if (config["runtime"] == 'drt-dart' || isJavascript) {
    var bodyElements, runAsText;

    if (config["layout"]) {
      sourceFile = tempChildDartFile;
      scriptFile = isJavascript ? tempChildJsFile : tempChildDartFile;
      bodyElements = '';
    } else {
      sourceFile = tempDartFile;
      scriptFile = isJavascript ? tempJsFile : tempDartFile;
      bodyElements = '<div id="container"></div><pre id="console"></pre>';
      runAsText = "window.testRunner.dumpAsText();";
    }
    scriptType = isJavascript ? 'text/javascript' : 'application/dart';

    if (config["runtime"] == 'drt-dart' || isJavascript) {
        logMessage('Creating $tempHtmlFile');
      writeFile(tempHtmlFile, '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>$testFile</title>
    <link rel="stylesheet" href="${config["runnerDir"]}/testrunner.css">
    <script type='text/javascript'>
      if (window.testRunner) {
        function handleMessage(m) {
          if (m.data == 'done') {
            window.testRunner.notifyDone();
          }
        }
        window.testRunner.waitUntilDone();
        $runAsText
        window.addEventListener("message", handleMessage, false);
      }
      if (!$isJavascript && navigator.webkitStartDart) {
        navigator.webkitStartDart();
      }
    </script>
  </head>
<body>
  $bodyElements
  <script type='$scriptType' src='$scriptFile'></script>
  </script>
  <script
src="http://dart.googlecode.com/svn/branches/bleeding_edge/dart/client/dart.js">
  </script>
</body>
</html>
''');
    }
  }
  compileStage(isJavascript);
}

/** Second stage of pipeline - compiles Dart to Javascript if needed. */
compileStage(isJavascript) {
  if (isJavascript) { // Compile the Dart file.
    if (config["checked"]) {
      runCommand(config["dart2js"],
          [ '--enable_checked_mode', '--out=$scriptFile', '$sourceFile' ]).
          then(runTestStage);
    } else {
      runCommand(config["dart2js"],
          [ '--out=$scriptFile', '$sourceFile' ]).
          then(runTestStage);
    }
  } else {
    runTestStage(0);
  }
}

/** Third stage of pipeline - runs the tests. */
runTestStage(_) {
  if (config["server"]) { // Start the HTTP server.
    serverId = startProcess(config["dart"],
        [ '${config["runnerDir"]}/http_server_test_runner.dart',
          '--port=${config["port"]}',
          '--root=${config["root"]}']);
  }

  var cmd, args;
  if (config["runtime"] == 'vm' || config["layout"]) { // Run the tests.
    if (config["checked"]) {
      cmd = config["dart"];
      args = [ '--enable_asserts', '--enable_type_checks', tempDartFile ];
    } else {
      cmd = config["dart"];
      args = [ tempDartFile ];
    }
  } else {
    cmd = config["drt"];
    args = [ '--no-timeout', tempHtmlFile ];
  }
  runCommand(cmd, args, config["timeout"]).then(cleanupStage);
}

/**
 * Final stage of the pipeline - clean up generated files and notify
 * the originator that started the isolate.
 */
cleanupStage(exitcode) {
  if (config["server"]) { // Stop the HTTP server.
    stopProcess(serverId);
  }

  if (!config["keep_files"]) { // Remove the temporary files.
    cleanup(tempDartFile);
    cleanup(tempHtmlFile);
    cleanup(tempJsFile);
    cleanup(tempChildDartFile);
    cleanup(tempChildJsFile);
  }
  completePipeline(exitcode);
}
