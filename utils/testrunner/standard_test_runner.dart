// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Path to DRT executable. */
String drt;

/** Whether to include elapsed time. */
bool includeTime;

/** Whether to regenerate layout test files. */
bool regenerate;

/** Whether to output test summary. */
bool summarize;

/** Whether  to print results immediately as they come in. */
bool immediate;

/** Format strings to use for test result messages. */
String listFormat, passFormat, failFormat, errorFormat;

/** Path of the running test file. */
String testfile;

/** The filters must be set by the caller. */
List includeFilters;
List excludeFilters;

/** The print function to use. */
Function tprint;

/** A callback function to notify the caller we are done. */
Function notifyDone;

/** The action function to use. */
Function action;

class Macros {
  static const String testTime = '<TIME>';
  static const String testfile = '<FILENAME>';
  static const String testGroup = '<GROUPNAME>';
  static const String testDescription = '<TESTNAME>';
  static const String testMessage = '<MESSAGE>';
  static const String testStacktrace = '<STACK>';
}

class TestRunnerConfiguration extends unittest.Configuration {
  get name => 'Minimal test runner configuration';
  get autoStart => false;

  String formatMessage(filename, groupname,
      [ testname = '', testTime = '', result = '',
        message = '', stack = '' ]) {
    var format = errorFormat;
    if (result == 'pass') format = passFormat;
    else if (result == 'fail') format = failFormat;
    return format.
        replaceAll(Macros.testTime, testTime).
        replaceAll(Macros.testfile, filename).
        replaceAll(Macros.testGroup, groupname).
        replaceAll(Macros.testDescription, testname).
        replaceAll(Macros.testMessage, message).
        replaceAll(Macros.testStacktrace, stack);
  }

  String elapsed(unittest.TestCase t) {
    if (includeTime) {
      double duration = t.runningTime.inMilliseconds.toDouble();
      duration /= 1000;
      return '${duration.toStringAsFixed(3)}s ';
    } else {
      return '';
    }
  }

  void dumpTestResult(source, unittest.TestCase t) {
    var groupName = '', testName = '';
    var idx = t.description.lastIndexOf('###');
    if (idx >= 0) {
        groupName = t.description.substring(0, idx).replaceAll('###', ' ');
        testName = t.description.substring(idx+3);
    } else {
        testName = t.description;
    }
    var stack = (t.stackTrace == null) ? '' : '${t.stackTrace} ';
    var message = (t.message.length > 0) ? '${t.message} ' : '';
    var duration = elapsed(t);
    tprint(formatMessage(source, '$groupName ', '$testName ',
        duration, t.result, message, stack));
  }

  void onTestResult(unittest.TestCase testCase) {
    if (immediate) {
      dumpTestResult('$testfile ', testCase);
    }
  }

  void printSummary(int passed, int failed, int errors,
                    [String uncaughtError = '']) {
    tprint('');
    if (passed == 0 && failed == 0 && errors == 0) {
      tprint('$testfile: No tests found.');
    } else if (failed == 0 && errors == 0 && uncaughtError == null) {
      tprint('$testfile: All $passed tests passed.');
    } else {
      if (uncaughtError != null) {
        tprint('$testfile: Top-level uncaught error: $uncaughtError');
      }
      tprint('$testfile: $passed PASSED, $failed FAILED, $errors ERRORS');
    }
  }

  void onDone(int passed, int failed, int errors,
              List<unittest.TestCase> results,
              String uncaughtError) {
    var success = (passed > 0 && failed == 0 && errors == 0 &&
        uncaughtError == null);
    if (!immediate) {
      for (final testCase in results) {
        dumpTestResult('$testfile ', testCase);
      }
    }
    if (summarize) {
      printSummary(passed, failed, errors, uncaughtError);
    }
    if (notifyDone != null) {
      notifyDone(success ? 0 : -1);
    }
  }
}

// Support for listing tests and groups. We use a minimal config.
class MinimalTestRunnerConfiguration extends unittest.Configuration {
  get name => 'Minimal test runner configuration';
  get autoStart => false;
}

String formatListMessage(filename, groupname, [ testname = '']) {
  return listFormat.
      replaceAll(Macros.testfile, filename).
      replaceAll(Macros.testGroup, groupname).
      replaceAll(Macros.testDescription, testname);
}

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
    var msg = formatListMessage('$testfile ', '$g ');
    print('###$msg');
  }
}

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
    var msg = formatListMessage('$testfile ', '$groupName ', '$testName ');
    print('###$msg');
  }
}

// Support for running in isolates.

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

// Main

filterTest(t) {
  var name = t.description.replaceAll("###", " ");
  if (includeFilters.length > 0) {
    for (var f in includeFilters) {
      if (name.indexOf(f) >= 0) return true;
    }
    return false;
  } else if (excludeFilters.length > 0) {
    for (var f in excludeFilters) {
      if (name.indexOf(f) >= 0) return false;
    }
    return true;
  } else {
    return true;
  }
}

process(testMain, action) {
  unittest.groupSep = '###';
  unittest.configure(new TestRunnerConfiguration());
  unittest.group('', testMain);
  // Do any user-specified test filtering.
  unittest.filterTests(filterTest);
  action();
}
