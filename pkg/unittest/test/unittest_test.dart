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
import 'dart:async';
import 'package:unittest/unittest.dart';

var tests; // array of test names
var expected; // array of test expected results (from buildStatusString)
var actual; // actual test results (from buildStatusString in config.onDone)
var _testconfig; // test configuration to capture onDone

Future _defer(void fn()) {
  return new Future.of(fn);
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
  String _result;

  TestConfiguration(this._port);

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    _result = buildStatusString(passed, failed, errors, results,
        count: count, setup: setup, teardown: teardown,
        uncaughtError: uncaughtError);
  }

  void onDone(bool success) {
    _port.send(_result);
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
        var _callback0 = expectAsync0(() => ++_testconfig.count);
        var _callback1 = expectAsync0(() => ++_testconfig.count);
        var _callback2 = expectAsync0(() {
          _callback1();
          _callback1();
          _callback0();
        });
        _defer(_callback2);
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
      var f;
      test('testOne', () {
        f = expectAsync0(() {});
        _defer(f);
      });
      test('testTwo', () {
        _defer(expectAsync0(() { f(); }));
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
    } else if (testName == 'async setup/teardown test') {
      group('good setup/good teardown', () {
        setUp(() {
          return new Future.immediate(0);
        });
        tearDown(() {
          return new Future.immediate(0);
        });
        test('foo1', (){});
      });
      group('good setup/bad teardown', () {
        setUp(() {
          return new Future.immediate(0);
        });
        tearDown(() {
          return new Future.immediateError("Failed to complete tearDown");
        });
        test('foo2', (){});
      });
      group('bad setup/good teardown', () {
        setUp(() {
          return new Future.immediateError("Failed to complete setUp");
        });
        tearDown(() {
          return new Future.immediate(0);
        });
        test('foo3', (){});
      });
      group('bad setup/bad teardown', () {
        setUp(() {
          return new Future.immediateError("Failed to complete setUp");
        });
        tearDown(() {
          return new Future.immediateError("Failed to complete tearDown");
        });
        test('foo4', (){});
      });
      // The next test is just to make sure we make steady progress
      // through the tests.
      test('post groups', () {});
    } else if (testName == 'test returning future') {
      test("successful", () {
        return _defer(() {
          expect(true, true);
        });
      });
      // We repeat the fail and error tests, because during development
      // I had a situation where either worked fine on their own, and
      // error/fail worked, but fail/error would time out.
      test("error1", () {
        var callback = expectAsync0((){});
        var excesscallback = expectAsync0((){});
        return _defer(() {
          excesscallback();
          excesscallback();
          excesscallback();
          callback();
        });
      });
      test("fail1", () {
        return _defer(() {
          expect(true, false);
        });
      });
      test("error2", () {
        var callback = expectAsync0((){});
        var excesscallback = expectAsync0((){});
        return _defer(() {
          excesscallback();
          excesscallback();
          callback();
        });
      });
      test("fail2", () {
        return _defer(() {
          fail('failure');
        });
      });
      test('foo5', () {
      });
    } else if (testName == 'test returning future using Timer') {
      test("successful", () {
        return _defer(() {
          Timer.run(() {
            guardAsync(() {
              expect(true, true);
            });
          });
        });
      });
      test("fail1", () {
        var callback = expectAsync0((){});
        return _defer(() {
          Timer.run(() {
            guardAsync(() {
              expect(true, false);
              callback();
            });
          });
        });
      });
      test('error1', () {
        var callback = expectAsync0((){});
        var excesscallback = expectAsync0((){});
        return _defer(() {
          Timer.run(() {
            guardAsync(() {
              excesscallback();
              excesscallback();
              callback();
            });
          });
        });
      });
      test("fail2", () {
        var callback = expectAsync0((){});
        return _defer(() {
          Timer.run(() {
            guardAsync(() {
              fail('failure');
              callback();
            });
          });
        });
      });
      test('error2', () {
        var callback = expectAsync0((){});
        var excesscallback = expectAsync0((){});
        return _defer(() {
          Timer.run(() {
            guardAsync(() {
              excesscallback();
              excesscallback();
              excesscallback();
              callback();
            });
          });
        });
      });
      test('foo6', () {
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
    'middle exception test',
    'async setup/teardown test',
    'test returning future',
    'test returning future using Timer'
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
    buildStatusString(0, 1, 0, tests[8], count: 1,
        message: 'Callback called more times than expected (1).'),
    buildStatusString(1, 0, 0, tests[9], count: 10),
    buildStatusString(0, 1, 0, tests[10], message: 'Caught error!'),
    buildStatusString(1, 0, 1, 'testOne',
        message: 'Callback called (2) after test case testOne has already '
                 'been marked as pass.:testTwo:'),
    buildStatusString(2, 1, 0,
        'testOne::testTwo:Expected: false but: was <true>.:testThree'),
    buildStatusString(2, 0, 3,
        'good setup/good teardown foo1::'
        'good setup/bad teardown foo2:good setup/bad teardown '
        'foo2: Test teardown failed: Failed to complete tearDown:'
        'bad setup/good teardown foo3:bad setup/good teardown '
        'foo3: Test setup failed: Failed to complete setUp:'
        'bad setup/bad teardown foo4:bad setup/bad teardown '
        'foo4: Test teardown failed: Failed to complete tearDown:'
        'post groups'),
    buildStatusString(2, 4, 0,
        'successful::'
        'error1:Callback called more times than expected (1).:'
        'fail1:Expected: <false> but: was <true>.:'
        'error2:Callback called more times than expected (1).:'
        'fail2:failure:'
        'foo5'),
    buildStatusString(2, 4, 0,
        'successful::'
        'fail1:Expected: <false> but: was <true>.:'
        'error1:Callback called more times than expected (1).:'
        'fail2:failure:'
        'error2:Callback called more times than expected (1).:'
        'foo6'),
  ];

  actual = [];

  nextTest(0);
}

