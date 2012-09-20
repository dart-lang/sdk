// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The DartWrapTask generates a Dart wrapper for a test file, that has a
 * test Configuration customized for the options specified by the user.
 */
class DartWrapTask extends PipelineTask {
  final String _sourceFileTemplate;
  final String _tempDartFileTemplate;

  DartWrapTask(this._sourceFileTemplate, this._tempDartFileTemplate);

  void execute(Path testfile, List stdout, List stderr, bool logging,
              Function exitHandler) {
    // Get the source test file and canonicalize the path.
    var sourceName = makePathAbsolute(
        expandMacros(_sourceFileTemplate, testfile));
    // Get the destination file.
    var destFile = expandMacros(_tempDartFileTemplate, testfile);

    if (config.layoutText || config.layoutPixel) {
      makeLayoutTestWrappers(sourceName, destFile, runnerDirectory);
    } else {
      makeNonLayoutTestWrapper(sourceName, destFile, runnerDirectory);
    }
    exitHandler(0);
  }

  void makeLayoutTestWrappers(String sourceName,
                              String destFile,
                              String libDirectory) {

    // Get the name of the directory that has the expectation files
    // (by stripping .dart suffix from test file path).
    // Create it if it does not exist.
    var expectedDirectory = sourceName.substring(0, sourceName.length - 5);
    if (config.regenerate) {
      var d = new Directory(expectedDirectory);
      if (!d.existsSync()) {
        d.createSync();
      }
    }

    // Create the child file that runs single tests in DRT.
    var childFile =
        '${destFile.substring(0, destFile.length - 5)}-child.dart';
        createFile(childFile, layoutTestWrapper(sourceName, libDirectory));

        // Create the controller file that invokes DRT for each test.
        createFile(destFile,
            layoutTestControllerWrapper(sourceName, childFile,
                                        expectedDirectory, libDirectory));
  }

  void makeNonLayoutTestWrapper(String sourceName,
                                String destFile,
                                String libDirectory) {
    var extraImports;
    var onDone;
    var tprint;
    var action;
    if (config.runInBrowser) {
      extraImports = "#import('dart:html');";
      onDone = "window.postMessage('done', '*')";
      tprint = "query('#console').addText('###\$msg\\n')";
    } else {
      extraImports = "#import('dart:io');";
      onDone = "exit(e)";
      tprint = "print('###\$msg')";
    }
    if (config.listTests) {
      action = 'listTests';
    } else if (config.listGroups) {
      action = 'listGroups';
    } else if (config.runIsolated) {
      action = 'runIsolateTests';
    } else {
      action = 'null';
    }
    var wrapper = """
#library('layout_test');
$extraImports
#import('${config.unittestPath}', prefix:'unittest');
#import('$sourceName', prefix: 'test');
#source('$libDirectory/standard_test_runner.dart');

main() {
  action = null;
  immediate = ${config.immediateOutput};
  includeTime = ${config.includeTime};
  passFormat = '${config.passFormat}';
  failFormat = '${config.failFormat}';
  errorFormat = '${config.errorFormat}';
  listFormat = '${config.listFormat}';
  includeFilters = ${config.includeFilter};
  excludeFilters = ${config.excludeFilter};
  regenerate = ${config.regenerate};
  testfile = '$sourceName';
  summarize = ${config.produceSummary};
  notifyDone = (e) => $onDone;
  tprint = (msg) => $tprint;
  action = $action;
  runTests(test.main);
}
""";
    // Save the Dart file.
    createFile(destFile, wrapper);
  }

  void cleanup(Path testfile, List stdout, List stderr,
               bool logging, bool keepFiles) {
    deleteFiles([_tempDartFileTemplate], testfile, logging, keepFiles, stdout);
  }

  String layoutTestWrapper(String sourceName, String libDirectory) => """
#library('layout_test');
#import('dart:math');
#import('dart:isolate');
#import('dart:html');
#import('dart:uri');
#import('${config.unittestPath}', prefix:'unittest');
#import('$sourceName', prefix: 'test');
#source('$libDirectory/layout_test_runner.dart');

main() {
  includeFilters = ${config.includeFilter};
  excludeFilters = ${config.excludeFilter};
  runTests(test.main);
}
""";


  String layoutTestControllerWrapper(String sourceName, String childName,
                                     String expectedDirectory,
                                     String libDirectory) {
    StringBuffer sbuf = new StringBuffer();
    var htmlFile = childName.replaceFirst('-child.dart', '.html');
    // Add common prefix.
    return """
#library('layout_controller');
#import('dart:uri');
#import('dart:io');
#import('dart:math');
#source('$libDirectory/layout_test_controller.dart');

main() {
  includeTime = ${config.includeTime};
  passFormat = '${config.passFormat}';
  failFormat = '${config.failFormat}';
  errorFormat = '${config.errorFormat}';
  listFormat = '${config.listFormat}';
  drt = '${makePathAbsolute(config.drtPath)}';
  regenerate = ${config.regenerate};
  sourceDir = '$expectedDirectory';
  testfile = '$sourceName';
  summarize = ${config.produceSummary};
  baseUrl = 'file://$htmlFile';
  run${config.layoutText?'Text':'Pixel'}LayoutTest(0);
}
""";
  }
}
