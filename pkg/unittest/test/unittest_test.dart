// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(gram):
// Unfortunately I can't seem to test anything that involves timeouts, e.g.
// insufficient callbacks, because the timeout is controlled externally
// (test.dart?), and we would need to use a shorter timeout for the inner tests
// so the outer timeout doesn't fire. So I removed all such tests.
// I'd like to revisit this at some point.

library unittestTest;
import 'dart:isolate';
import '../../../pkg/unittest/lib/unittest.dart';

var tests; // array of test names
var expected; // array of test expected results (from buildStatusString)
var actual; // actual test results (from buildStatusString in config.onDone)
var _testconfig; // test configuration to capture onDone

_defer(void fn()) {
  // Exploit isolate ports as a platform-independent mechanism to queue a
  // message at the end of the event loop. Stolen from unittest.dart.
  final port = new ReceivePort();
  port.receive((msg, reply) {
    fn();
    port.close();
  });
  port.toSendPort().send(null, null);
}

String buildStatusString(int passed, int failed, int errors,
                         var results,
                         {int count: 0,
                         String setup: '', String teardown: '',
                         String uncaughtError: null,
                         String message: ''}) {
  var totalTests = 0;
  String testDetails = '';
  if (results is String) {
    totalTests = passed + failed + errors;
    testDetails = ':$results:$message';
  } else {
    totalTests = results.length;
    for (var i = 0; i < results.length; i++) {
      testDetails = '$testDetails:${results[i].description}:'
          '${collapseWhitespace(results[i].message)}';
    }
  }
  var result = '$passed:$failed:$errors:$totalTests:$count:'
      '$setup:$teardown:$uncaughtError$testDetails';
  return result;
}

class TestConfiguration extends Configuration {

  // Some test state that is captured
  int count = 0; // a count of callbacks
  String setup = ''; // the name of the test group setup function, if any
  String teardown = ''; // the name of the test group teardown function, if any

  // The port to communicate with the parent isolate
  SendPort _port;

  TestConfiguration(this._port);

  void onDone(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    var result = buildStatusString(passed, failed, errors, results,
        count: count, setup: setup, teardown: teardown,
        uncaughtError: uncaughtError);
    _port.send(result);
  }
}
runTest() {
  port.receive((testName, sendport) {
    configure(_testconfig = new TestConfiguration(sendport));
    if (testName == 'single correct test') {
      test(testName, () => expect(2 + 3, equals(5)));
    } else if (testName == 'single failing test') {
      test(testName, () => expect(2 + 2, equals(5)));
    } else if (testName == 'exception test') {
      test(testName, () { throw new Exception('Fail.'); });
    } else if (testName == 'group name test') {
      group('a', () {
        test('a', () {});
        group('b', () {
          test('b', () {});
        });
      });
    } else if (testName == 'setup test') {
      group('a', () {
        setUp(() { _testconfig.setup = 'setup'; });
        test(testName, () {});
      });
    } else if (testName == 'teardown test') {
      group('a', () {
        tearDown(() { _testconfig.teardown = 'teardown'; });
        test(testName, () {});
      });
    } else if (testName == 'setup and teardown test') {
      group('a', () {
        setUp(() { _testconfig.setup = 'setup'; });
        tearDown(() { _testconfig.teardown = 'teardown'; });
        test(testName, () {});
      });
    } else if (testName == 'correct callback test') {
      test(testName,
        () =>_defer(expectAsync0((){ ++_testconfig.count;})));
    } else if (testName == 'excess callback test') {
      test(testName, () {
        var _callback = expectAsync0((){ ++_testconfig.count;});
        _defer(_callback);
        _defer(_callback);
      });
    } else if (testName == 'completion test') {
      test(testName, () {
             var _callback;
             _callback = expectAsyncUntil0(() {
               if (++_testconfig.count < 10) {
                 _defer(_callback);
               }
             },
             () => (_testconfig.count == 10));
             _defer(_callback);
      });
    } else if (testName == 'async exception test') {
      test(testName, () {
        expectAsync0(() {});
        _defer(() => guardAsync(() { throw "error!"; }));
      });
    } else if (testName == 'late exception test') {
      test('testOne', () {
        var f = expectAsync0(() {});
        _defer(protectAsync0(() {
          _defer(protectAsync0(() => expect(false, isTrue)));
          expect(false, isTrue);
        }));
      });
      test('testTwo', () {
        _defer(expectAsync0(() {}));
      });
    } else if (testName == 'middle exception test') {
      test('testOne', () { expect(true, isTrue); });
      test('testTwo', () { expect(true, isFalse); });
      test('testThree', () {
        var done = expectAsync0((){});
        _defer(() {
          expect(true, isTrue);
          done();
        });
      });
    }
  });
}

void nextTest(int testNum) {
  SendPort sport = spawnFunction(runTest);
  sport.call(tests[testNum]).then((msg) {
    actual.add(msg);
    if (actual.length == expected.length) {
      for (var i = 0; i < tests.length; i++) {
        test(tests[i], () => expect(actual[i].trim(), equals(expected[i])));
      }
    } else {
      nextTest(testNum+1);
    }
  });
}

main() {
  tests = [
    'single correct test',
    'single failing test',
    'exception test',
    'group name test',
    'setup test',
    'teardown test',
    'setup and teardown test',
    'correct callback test',
    'excess callback test',
    'completion test',
    'async exception test',
    'late exception test',
    'middle exception test'
  ];

  expected = [
    buildStatusString(1, 0, 0, tests[0]),
    buildStatusString(0, 1, 0, tests[1],
        message: 'Expected: <5> but: was <4>.'),
    buildStatusString(0, 1, 0, tests[2], message: 'Caught Exception: Fail.'),
    buildStatusString(2, 0, 0, 'a a::a b b'),
    buildStatusString(1, 0, 0, 'a ${tests[4]}', count: 0, setup: 'setup'),
    buildStatusString(1, 0, 0, 'a ${tests[5]}', count: 0, setup: '',
        teardown: 'teardown'),
    buildStatusString(1, 0, 0, 'a ${tests[6]}', count: 0,
        setup: 'setup', teardown: 'teardown'),
    buildStatusString(1, 0, 0, tests[7], count: 1),
    buildStatusString(0, 0, 1, tests[8], count: 1,
        message: 'Callback called more times than expected (2 > 1).'),
    buildStatusString(1, 0, 0, tests[9], count: 10),
    buildStatusString(0, 1, 0, tests[10], message: 'Caught error!'),
    buildStatusString(1, 0, 1, 'testOne', message: 'Callback called after already being marked as done (1).:testTwo:'),
    buildStatusString(2, 1, 0, 'testOne::testTwo:Expected: false but: was <true>.:testThree')
  ];

  actual = [];

  nextTest(0);
}

