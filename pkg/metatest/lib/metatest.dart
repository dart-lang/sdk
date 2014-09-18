// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A test library for testing test libraries? We must go deeper.
///
/// Since unit testing code tends to use a lot of global state, it can be tough
/// to test. This library manages it by running each test case in a child
/// isolate, then reporting the results back to the parent isolate.
library metatest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

import 'src/utils.dart';

/// Whether or not we're running in a child isolate that's supposed to run a
/// test.
bool _inChildIsolate;

/// The port with which the child isolate should communicate with the parent
/// isolate.
///
/// `null` in the parent isolate.
SendPort _replyTo;

/// The only value of the configuration used in metatest.
final _metaConfiguration = new _MetaConfiguration();

/// The function holding the tests to be run.
Function _testBody;

/// The description of the test to run in the child isolate.
///
/// `null` in the parent isolate.
String _testToRun;

/// Stores the optional timeout used to override the default unittest timeout.
Duration _timeoutOverride;

/// Runs [setUpFn] before every metatest.
///
/// Note that [setUpFn] will be overwritten if the test itself calls [setUp].
void metaSetUp(void setUpFn()) {
  if (_inChildIsolate) setUp(setUpFn);
}

/// Runs a set of tests defined in `body` and checks the result by comparing
/// with values in `expectedResults`.
///
/// [expectedResults] is a list which should have a [Map] value for each test
/// that is run. Each [Map] key corresponds to values from a completed test
/// case: "description", "message", "result", and "stackTrace".
///
/// The value of "result" can be one of: 'pass', 'fail', or 'error'.
///
/// The value for "stackTrace" is the [String] 'null' if the property is `null`
/// on the source test case. Otherwise, it is the output of `toString`. The
/// format is not guaranteed.
///
/// Here's an example of a `expectedResults` value for two tests, where the
/// where the first fails and the second passes.
///
/// ```dart
/// [{
///   'description': 'test',
///   'message': 'Caught error!',
///   'result': 'fail',
/// }, {
///   'description': 'follow up',
///   'result': 'pass',
/// }]
/// ```
void expectTestResults(String description, void body(),
    List<Map> expectedResults) {
  _setUpTest(description, body, (resultsMap) {
    var list = resultsMap['results'];
    expect(list, hasLength(expectedResults.length),
        reason: 'The number of tests run does not match the number of expected'
          ' results.');

    for (var i = 0; i < list.length; i++) {
      var expectedMap = expectedResults[i];
      var map = list[i];

      expectedMap.forEach((key, value) {
        expect(map, containsPair(key, value), reason: 'A test did not match the'
          ' expected value for "$key" at index $i.');
      });
    }
  });
}

/// Declares a test with the given [description] and [body]. [body] corresponds
/// to the `main` method of a test file, and will be run in an isolate. By
/// default, this expects that all tests defined in [body] pass, but if
/// [passing] is passed, only tests listed there are expected to pass.
void expectTestsPass(String description, void body(), {List<String> passing}) {
  _setUpTest(description, body, (results) {
    if (_hasError(results)) {
      fail('Expected all tests to pass, but got error(s):\n'
          '${_summarizeTests(results)}');
    } else if (passing == null) {
      if (results['failed'] != 0) {
        fail('Expected all tests to pass, but some failed:\n'
            '${_summarizeTests(results)}');
      }
    } else {
      var shouldPass = new Set.from(passing);
      var didPass = new Set.from(results['results']
          .where((t) => t['result'] == 'pass')
          .map((t) => t['description']));

      if (!shouldPass.containsAll(didPass) ||
          !didPass.containsAll(shouldPass)) {
        String stringify(Set<String> tests) =>
            '{${tests.map((t) => '"$t"').join(', ')}}';

        fail('Expected exactly ${stringify(shouldPass)} to pass, but '
            '${stringify(didPass)} passed.\n'
            '${_summarizeTests(results)}');
      }
    }
  });
}

/// Declares a test with the given [description] and [body]. [body] corresponds
/// to the `main` method of a test file, and will be run in an isolate. Expects
/// all tests defined by [body] to fail.
void expectTestsFail(String description, void body()) {
  _setUpTest(description, body, (results) {
    if (_hasError(results)) {
      throw 'Expected all tests to fail, but got error(s):\n'
          '${_summarizeTests(results)}';
    } else if (results['passed'] != 0) {
      throw 'Expected all tests to fail, but some passed:\n'
          '${_summarizeTests(results)}';
    }
  });
}

/// Sets up a test with the given [description] and [body]. After the test runs,
/// calls [validate] with the result map.
void _setUpTest(String description, void body(), void validate(Map map)) {
  if (_inChildIsolate) {
    _ensureInitialized();
    if (_testToRun == description) body();
  } else {
    test(description, () {
      return _runInIsolate(description).then(validate);
    });
  }
}

/// Initialize metatest.
///
/// [message] should be the second argument to [main]. It's used to determine
/// whether this test is in the parent isolate or a child isolate.
///
/// [timeout], when specified, overrides the default timeout for unittest.
void initMetatest(message, {Duration timeout}) {
  _timeoutOverride = timeout;
  if (message == null) {
    _inChildIsolate = false;
  } else {
    _testToRun = message['testToRun'];
    _replyTo = message['replyTo'];
    _inChildIsolate = true;
  }
}

// TODO(kevmoo) We need to capture the main method to allow running in an
// isolate. There is no mechanism to capture the current executing URI between
// browser and vm. Issue 1145 and/or Issue 8440
void initTests(void testBody(message)) {
  _testBody = testBody;
  _testBody(null);
}

/// Runs the test described by [description] in its own isolate.
///
/// Returns a map describing the results of that test run.
Future<Map> _runInIsolate(String description) {
  if (_testBody == null) {
    throw new StateError('initTests was not called.');
  }

  var replyPort = new ReceivePort();
  return Isolate.spawn(_testBody, {
    'testToRun': description,
    'replyTo': replyPort.sendPort
  }).then((_) => replyPort.first);
}

/// Returns whether [results] (a test result map) describes a test run in which
/// an error occurred.
bool _hasError(Map results) {
  return results['errors'] > 0 || results['uncaughtError'] != null ||
      (results['passed'] == 0 && results['failed'] == 0);
}

/// Returns a string description of the test run descibed by [results].
String _summarizeTests(Map results) {
  var buffer = new StringBuffer();
  for (var t in results["results"]) {
    buffer.writeln("${t['result'].toUpperCase()}: ${t['description']}");
    if (t['message'] != '') buffer.writeln("${_indent(t['message'])}");
    if (t['stackTrace'] != null && t['stackTrace'] != '') {
      buffer.writeln("${_indent(t['stackTrace'])}");
    }
  }

  buffer.writeln();

  var success = false;
  if (results['passed'] == 0 && results['failed'] == 0 &&
      results['errors'] == 0 && results['uncaughtError'] == null) {
    buffer.write('No tests found.');
    // This is considered a failure too.
  } else if (results['failed'] == 0 && results['errors'] == 0 &&
      results['uncaughtError'] == null) {
    buffer.write('All ${results['passed']} tests passed.');
    success = true;
  } else {
    if (results['uncaughtError'] != null) {
      buffer.write('Top-level uncaught error: ${results['uncaughtError']}');
    }
    buffer.write('${results['passed']} PASSED, ${results['failed']} FAILED, '
        '${results['errors']} ERRORS');
  }
  return prefixLines(buffer.toString());
}

/// Indents each line of [str] by two spaces.
String _indent(String str) {
  return str.replaceAll(new RegExp("^", multiLine: true), "  ");
}

/// Ensure that the metatest configuration is loaded.
void _ensureInitialized() {
  unittestConfiguration = _metaConfiguration;
  if (_timeoutOverride != null) {
    unittestConfiguration.timeout = _timeoutOverride;
  }
}

/// Special test configuration for use within the child isolates. This hides all
/// output and reports data back to the parent isolate.
class _MetaConfiguration extends Configuration {

  _MetaConfiguration() : super.blank();

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    _replyTo.send({
      "passed": passed,
      "failed": failed,
      "errors": errors,
      "uncaughtError": uncaughtError,
      "results": results.map((testCase) => {
        "description": testCase.description,
        "message": testCase.message,
        "result": testCase.result,
        "stackTrace": testCase.stackTrace.toString()
      }).toList()
    });
  }
}
