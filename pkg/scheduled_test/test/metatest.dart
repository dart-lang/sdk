// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A test library for testing test libraries? We must go deeper.
///
/// Since unit testing code tends to use a lot of global state, it can be tough
/// to test. This library manages it by running each test case in a child
/// isolate, then reporting the results back to the parent isolate.
library metatest;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'package:scheduled_test/scheduled_test.dart' as scheduled_test;

import 'utils.dart';

/// Declares a test with the given [description] and [body]. [body] corresponds
/// to the `main` method of a test file, and will be run in an isolate. By
/// default, this expects that all tests defined in [body] pass, but if
/// [passing] is passed, only tests listed there are expected to pass.
void expectTestsPass(String description, void body(), {List<String> passing}) {
  _setUpTest(description, body, (results) {
    if (_hasError(results)) {
      throw 'Expected all tests to pass, but got error(s):\n'
          '${_summarizeTests(results)}';
    } else if (passing == null) {
      if (results['failed'] != 0) {
        throw 'Expected all tests to pass, but some failed:\n'
            '${_summarizeTests(results)}';
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

/// Runs [setUpFn] before every metatest. Note that [setUpFn] will be
/// overwritten if the test itself calls [setUp].
void metaSetUp(void setUpFn()) {
  if (_inChildIsolate) scheduled_test.setUp(setUpFn);
}

/// Sets up a test with the given [description] and [body]. After the test runs,
/// calls [validate] with the result map.
void _setUpTest(String description, void body(), void validate(Map)) {
  if (_inChildIsolate) {
    _ensureInitialized();
    if (_testToRun == description) body();
  } else {
    test(description, () {
      expect(_runInIsolate(description).then(validate), completes);
    });
  }
}

/// The description of the test to run in the child isolate.
///
/// `null` in the parent isolate.
String _testToRun;

/// The port with which the child isolate should communicate with the parent
/// isolate.
///
/// `null` in the parent isolate.
SendPort _replyTo;

/// Whether or not we're running in a child isolate that's supposed to run a
/// test.
bool _inChildIsolate;

/// Initialize metatest.
///
/// [message] should be the second argument to [main]. It's used to determine
/// whether this test is in the parent isolate or a child isolate.
void initMetatest(message) {
  if (message == null) {
    _inChildIsolate = false;
  } else {
    _testToRun = message['testToRun'];
    _replyTo = message['replyTo'];
    _inChildIsolate = true;
  }
}

/// Runs the test described by [description] in its own isolate. Returns a map
/// describing the results of that test run.
Future<Map> _runInIsolate(String description) {
  var replyPort = new ReceivePort();
  // TODO(nweiz): Don't use path here once issue 8440 is fixed.
  var uri = path.toUri(path.absolute(path.fromUri(Platform.script)));
  return Isolate.spawnUri(uri, [], {
    'testToRun': description,
    'replyTo': replyPort.sendPort
  }).then((_) {
    // TODO(nweiz): Remove this timeout once issue 8417 is fixed and we can
    // capture top-level exceptions.
    return timeout(replyPort.first, 30 * 1000, () {
      throw 'Timed out waiting for test to complete.';
    });
  });
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
  // TODO(nweiz): Use this simpler code once issue 2980 is fixed.
  // return str.replaceAll(new RegExp("^", multiLine: true), "  ");

  return str.split("\n").map((line) => "  $line").join("\n");
}

/// Ensure that the metatest configuration is loaded.
void _ensureInitialized() {
  unittestConfiguration = _singleton;
}

final _singleton = new _MetaConfiguration();

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
