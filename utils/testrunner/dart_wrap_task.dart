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

    // Working buffer for the Dart wrapper.
    StringBuffer sbuf = new StringBuffer();

    // Add the common header stuff.
    var p = new Path(sourceName);
    sbuf.add(directives(p.filenameWithoutExtension,
                        config.unittestPath,
                        sourceName));

    // Add the test configuration and determine the action function.
    var action;
    if (config.listTests) {
      action = 'listTests';
      sbuf.add(barebonesConfig());
      sbuf.add(listTestsFunction);
      sbuf.add(formatListMessageFunction(config.listFormat));
    } else if (config.listGroups) {
      sbuf.add(barebonesConfig());
      sbuf.add(listGroupsFunction);
      sbuf.add(formatListMessageFunction(config.listFormat));
      action = 'listGroups';
    } else {

      if (config.runInBrowser) {
        sbuf.add(browserTestPrintFunction);
        sbuf.add(unblockDRTFunction);
      } else {
        sbuf.add(nonBrowserTestPrintFunction);
        sbuf.add(stubUnblockDRTFunction);
      }

      if (config.runIsolated) {
        sbuf.add(runIsolateTestsFunction);
        action = 'runIsolateTests';
      } else {
        sbuf.add(runTestsFunction);
        action = 'runTests';
      }

      sbuf.add(config.includeTime ? elapsedFunction : stubElapsedFunction);
      sbuf.add(config.produceSummary ?
          printSummaryFunction : stubPrintSummaryFunction);

      if (config.immediateOutput) {
        sbuf.add(printTestResultFunction);
        sbuf.add(stubPrintAllTestResultsFunction);
      } else {
        sbuf.add(stubPrintTestResultFunction);
        sbuf.add(printAllTestResultsFunction);
      }

      sbuf.add(dumpTestResultFunction);
      sbuf.add(formatMessageFunction(config.passFormat,
                                     config.failFormat,
                                     config.errorFormat));
      sbuf.add(testConfig());
    }

    // Add the filter, if applicable.
    if (config.filtering) {
      if (config.includeFilter.length > 0) {
        sbuf.add(filterTestFunction(config.includeFilter, 'true'));
      } else {
        sbuf.add(filterTestFunction(config.excludeFilter, 'false'));
      }
    }

    // Add the common trailer stuff.
    sbuf.add(dartMain(sourceName, action, config.filtering));

    // Save the Dart file.
    createFile(destFile, sbuf.toString());
    exitHandler(0);
  }

  void cleanup(Path testfile, List stdout, List stderr,
               bool logging, bool keepFiles) {
    deleteFiles([_tempDartFileTemplate], testfile, logging, keepFiles, stdout);
  }

  String directives(String library, String unittest, String sourceName) {
    return """
#library('$library');
#import('dart:math');
#import('dart:isolate');
#import('$unittest', prefix:'unittest');
#import('$sourceName', prefix: 'test');
""";
  }

  // The core skeleton for a config. Most of the guts is in the
  // parameter [body].
  String configuration([String body = '']) {
    return """
class TestRunnerConfiguration extends unittest.Configuration {
  get name => 'Test runner configuration';
  get autoStart => false;
  $body
}
""";
  }

  // A barebones config, used for listing tests, not running them.
  String barebonesConfig() {
    return configuration();
  }

  // A more complex config, used for running tests.
  String testConfig() {
    return configuration(""" 
  void onTestResult(unittest.TestCase testCase) {
    printResult('\$testFile ', testCase);
  }

  void onDone(int passed, int failed, int errors, 
              List<unittest.TestCase> results,
      String uncaughtError) {
    var success = (passed > 0 && failed == 0 && errors == 0 && 
        uncaughtError == null);
    printResults(testFile, results);
    printSummary(testFile, passed, failed, errors, uncaughtError);
    unblockDRT();
  }
""");
  }

  // The main function, that creates the config, filters the tests if
  // necessary, then performs the action (list/run/run-isolated).
  String dartMain(String sourceName, String action, bool filter) {
    return """
var testFile = '$sourceName';
main() {
  unittest.groupSep = '###';
  unittest.configure(new TestRunnerConfiguration());
  unittest.group('', test.main);
  ${filter ? 'unittest.filterTests(filterTest);' : ''}
  $action();
}
""";
  }

  // For 'printing' when we are in the browser, we add text elements
  // to a DOM element with id 'console'.
  final String browserTestPrintFunction = """
#import('dart:html');
void tprint(msg) {
var pre = query('#console');
pre.addText('###\$msg\\n');
}
""";

  // For printing when not in the browser we can just use Dart's print().
  final String nonBrowserTestPrintFunction = """
void tprint(msg) {
print('###\$msg');
}
""";

  // A function to give us the elapsed time for a test.
  final String elapsedFunction = """
String elapsed(unittest.TestCase t) {
  double duration = t.runningTime.inMilliseconds.toDouble();
  duration /= 1000;
  return '\${duration.toStringAsFixed(3)}s ';
}
""";

  // A dummy version of the elapsed function for when the user
  // doesn't want test times included.
  final String stubElapsedFunction = """
String elapsed(unittest.TestCase t) {
  return '';
}
""";

  // A function to print the results of a test.
  final String dumpTestResultFunction = """
void dumpTestResult(source, unittest.TestCase t) {
  var groupName = '', testName = '';
  var idx = t.description.lastIndexOf('###');
  if (idx >= 0) {
      groupName = t.description.substring(0, idx).replaceAll('###', ' ');
      testName = t.description.substring(idx+3);
  } else {
      testName = t.description;
  }
  var stack = (t.stackTrace == null) ? '' : '\${t.stackTrace} ';
  var message = (t.message.length > 0) ? '\$t.message ' : '';
  var duration = elapsed(t);
  tprint(formatMessage(source, '\$groupName ', '\$testName ', 
      duration, t.result, message, stack));
}
""";

  // A function to print the test summary.
  final String printSummaryFunction = """
void printSummary(String testFile, int passed, int failed, int errors,
    String uncaughtError) { 
  tprint('');
  if (passed == 0 && failed == 0 && errors == 0) {
    tprint('\$testFile: No tests found.');
  } else if (failed == 0 && errors == 0 && uncaughtError == null) {
    tprint('\$testFile: All \$passed tests passed.');
  } else {
    if (uncaughtError != null) {
      tprint('\$testFile: Top-level uncaught error: \$uncaughtError');
    }
    tprint('\$testFile: \$passed PASSED, \$failed FAILED, \$errors ERRORS');
  }
}
""";

  final String stubPrintSummaryFunction = """
void printSummary(String testFile, int passed, int failed, int errors,
    String uncaughtError) {   
}
""";

  // A function to print all test results.
  final String printAllTestResultsFunction = """
void printResults(testfile, List<unittest.TestCase> results) {
  for (final testCase in results) {
    dumpTestResult('\$testfile ', testCase);
  }
}
""";

  final String stubPrintAllTestResultsFunction = """
void printResults(testfile, List<unittest.TestCase> results) {
}
""";

  // A function to print a single test result.
  final String printTestResultFunction = """
void printResult(testfile, unittest.TestCase testCase) {
  dumpTestResult('\$testfile ', testCase);
}
""";

  final String stubPrintTestResultFunction = """
void printResult(testfile, unittest.TestCase testCase) {
}
""";

  final String unblockDRTFunction = """
void unblockDRT() {
  window.postMessage('done', '*');
}
 """;

  final String stubUnblockDRTFunction = """
void unblockDRT() {
}
""";

  // A simple format function for listing tests.
  String formatListMessageFunction(String format) {
    return """
String formatMessage(filename, groupname, [ testname = '']) {
  return '${format}'.
      replaceAll('${Macros.testfile}', filename).
      replaceAll('${Macros.testGroup}', groupname).
      replaceAll('${Macros.testDescription}', testname);
}
""";
  }

  // A richer format function for test results.
  String formatMessageFunction(
      String passFormat, String failFormat, String errorFormat) {
    return """
String formatMessage(filename, groupname,
    [ testname = '', testTime = '', result = '',
      message = '', stack = '' ]) {
  var format = '$errorFormat';
  if (result == 'pass') format = '$passFormat';
  else if (result == 'fail') format = '$failFormat';
  return format.
      replaceAll('${Macros.testTime}', testTime).
      replaceAll('${Macros.testfile}', filename).
      replaceAll('${Macros.testGroup}', groupname).
      replaceAll('${Macros.testDescription}', testname).
      replaceAll('${Macros.testMessage}', message).
      replaceAll('${Macros.testStacktrace}', stack);
}
""";
  }

  // A function to list the test groups.
  final String listGroupsFunction = """
listGroups() {
  List tests = unittest.testCases;
  Map groups = {};
  for (var t in tests) {
    var groupName, testName = '';
    var idx = t.description.lastIndexOf('###');
    if (idx >= 0) {
      groupName = t.description.substring(0, idx).replaceAll('###', ' ');
      if (!groups.containsKey(groupName)) {
        groups[groupName] = '';
      }
    }
  }
  for (var g in groups.getKeys()) {
    var msg = formatMessage('\$testfile ', '\$g ');
    print('###\$msg');
  }
}
""";

  // A function to list the tests.
  final String listTestsFunction = """
listTests() {
  List tests = unittest.testCases;
  for (var t in tests) {
    var groupName, testName = '';
    var idx = t.description.lastIndexOf('###');
    if (idx >= 0) {
      groupName = t.description.substring(0, idx).replaceAll('###', ' ');
      testName = t.description.substring(idx+3);
    } else {
      groupName = '';
      testName = t.description;
    }
    var msg = formatMessage('\$testfile ', '\$groupName ', '\$testName ');
    print('###\$msg');
  }
}
""";

  // A function to filter the tests.
  String filterTestFunction(List filters, String filterReturnValue) {
    StringBuffer sbuf = new StringBuffer();
    sbuf.add('filterTest(t) {\n');
    if (filters != null) {
      sbuf.add('  var name = t.description.replaceAll("###", " ");\n');
      for (var f in filters) {
        sbuf.add('  if (name.indexOf("$f")>=0) return $filterReturnValue;\n');
      }
      sbuf.add('  return !$filterReturnValue;\n');
    } else {
      sbuf.add('  return true;\n');
    }
    sbuf.add('}\n');
    return sbuf.toString();
  }

  // Code to support running single tests in isolates.
  final String runIsolateTestsFunction = """
class TestRunnerChildConfiguration extends unittest.Configuration {
  get name => 'Test runner child configuration';
  get autoStart => false;

  void onDone(int passed, int failed, int errors,
              List<unittest.TestCase> results, String uncaughtError) {
    unittest.TestCase test = results[0];
    parentPort.send([test.result, test.runningTime.inMilliseconds,
                     test.message, test.stackTrace]);
  }
}

var parentPort;
runChildTest() {
  port.receive((testName, sendport) {
    parentPort = sendport;
    unittest.configure(new TestRunnerChildConfiguration());
    unittest.groupSep = '###';
    unittest.group('', test.main);
    unittest.filterTests(testName);
    unittest.runTests();    
  });
}

var testNum;
var failed;
var errors;
var passed;

runParentTest() {
  var tests = unittest.testCases;
  tests[testNum].startTime = new Date.now();
  SendPort childPort = spawnFunction(runChildTest);
  childPort.call(tests[testNum].description).then((results) {
    var result = results[0];
    var duration = new Duration(milliseconds: results[1]);
    var message = results[2];
    var stack = results[3];  
    if (result == 'pass') {
      tests[testNum].pass();
      ++passed;
    } else if (result == 'fail') {
      tests[testNum].fail(message, stack);
      ++failed;
    } else {
      tests[testNum].error(message, stack);
      ++errors;
    }   
    tests[testNum].runningTime = duration;
    ++testNum;
    if (testNum < tests.length) {
      runParentTest();
    } else {
      unittest.config.onDone(passed, failed, errors, 
          unittest.testCases, null);
    }
  });
}

runIsolateTests() {
  testNum = 0;
  passed = failed = errors = 0;
  runParentTest();
}
""";

  // Code for running all tests in the normal (non-isolate) way.
  final String runTestsFunction = """
runTests() {
  unittest.runTests();
}
""";
}
