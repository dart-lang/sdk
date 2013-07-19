// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of test_controller;

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

/**
 * A special marker string used to separate group names and
 * identify non-debug output.
 */ 
final marker = '###';

class Macros {
  static const String testTime = '<TIME>';
  static const String testfile = '<FILENAME>';
  static const String testGroup = '<GROUPNAME>';
  static const String testDescription = '<TESTNAME>';
  static const String testMessage = '<MESSAGE>';
  static const String testStacktrace = '<STACK>';
}

class TestRunnerConfiguration extends Configuration {
  get name => 'Minimal test runner configuration';
  get autoStart => false;

  void onInit() {}

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

  String elapsed(TestCase t) {
    if (includeTime) {
      double duration = t.runningTime.inMilliseconds.toDouble();
      duration /= 1000;
      return '${duration.toStringAsFixed(3)}s ';
    } else {
      return '';
    }
  }

  void dumpTestResult(source, TestCase t) {
    var groupName = '', testName = '';
    var idx = t.description.lastIndexOf(marker);
    if (idx >= 0) {
        groupName = t.description.substring(0, idx).replaceAll(marker, ' ');
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

  void onTestResult(TestCase testCase) {
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

  void onSummary(int passed, int failed, int errors,
      List<TestCase> results, String uncaughtError) {
    if (!immediate) {
      for (final testCase in results) {
        dumpTestResult('$testfile ', testCase);
      }
    }
    if (summarize) {
      printSummary(passed, failed, errors, uncaughtError);
    }
  }

  void onDone(bool success) {
    if (notifyDone != null) {
      notifyDone(success ? 0 : -1);
    }
  }
}

String formatListMessage(filename, groupname, [ testname = '']) {
  return listFormat.
      replaceAll(Macros.testfile, filename).
      replaceAll(Macros.testGroup, groupname).
      replaceAll(Macros.testDescription, testname);
}

listGroups() {
  List tests = testCases;
  Map groups = {};
  for (var t in tests) {
    var groupName, testName = '';
    var idx = t.description.lastIndexOf(marker);
    if (idx >= 0) {
      groupName = t.description.substring(0, idx).replaceAll(marker, ' ');
      if (!groups.containsKey(groupName)) {
        groups[groupName] = '';
      }
    }
  }
  for (var g in groups.keys) {
    var msg = formatListMessage('$testfile ', '$g ');
    print('$marker$msg');
  }
  if (notifyDone != null) {
    notifyDone(0);
  }
}

listTests() {
  List tests = testCases;
  for (var t in tests) {
    var groupName, testName = '';
    var idx = t.description.lastIndexOf(marker);
    if (idx >= 0) {
      groupName = t.description.substring(0, idx).replaceAll(marker, ' ');
      testName = t.description.substring(idx+3);
    } else {
      groupName = '';
      testName = t.description;
    }
    var msg = formatListMessage('$testfile ', '$groupName ', '$testName ');
    print('$marker$msg');
  }
  if (notifyDone != null) {
    notifyDone(0);
  }
}

// Support for running in isolates.

class TestRunnerChildConfiguration extends Configuration {
  get name => 'Test runner child configuration';
  get autoStart => false;

  void onSummary(int passed, int failed, int errors,
      List<TestCase> results, String uncaughtError) {
    TestCase test = results[0];
    parentPort.send([test.result, test.runningTime.inMilliseconds,
                     test.message, test.stackTrace.toString()]);
  }
}

var parentPort;
runChildTest() {
  port.receive((testName, sendport) {
    parentPort = sendport;
    unittestConfiguration = new TestRunnerChildConfiguration();
    groupSep = marker;
    group('', test.main);
    filterTests(testName);
    runTests();
  });
}

isolatedTestParentWrapper(testCase) => () {
  SendPort childPort = spawnFunction(runChildTest);
  var f = childPort.call(testCase.description);
  f.then((results) {
    var result = results[0];
    var duration = new Duration(milliseconds: results[1]);
    var message = results[2];
    var stack = results[3];
    if (result == 'fail') {
      testCase.fail(message, stack);
    } else if (result == 'error') {
      testCase.error(message, stack);
    }
  });
  return f;
};

runIsolateTests() {
  // Replace each test with a wrapped version first.
  for (var i = 0; i < testCases.length; i++) {
    testCases[i].testFunction = isolatedTestParentWrapper(testCases[i]);
  }
  runTests();
}

// Main

filterTest(t) {
  var name = t.description.replaceAll(marker, " ");
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
  groupSep = marker;
  unittestConfiguration = new TestRunnerConfiguration();
  group('', testMain);
  // Do any user-specified test filtering.
  filterTests(filterTest);
  action();
}
