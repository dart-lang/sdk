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

Future _defer(void fn()) {
  return new Future.sync(fn);
}

String buildStatusString(int passed, int failed, int errors,
                         var results,
                         {int count: 0,
                         String setup: '', String teardown: '',
                         String uncaughtError: null,
                         String message: ''}) {
  var totalTests = 0;
  var testDetails = new StringBuffer();
  if(results == null) {
    // no op
    assert(message == '');
  } else if (results is String) {
    totalTests = passed + failed + errors;
    testDetails.write(':$results:$message');
  } else {
    totalTests = results.length;
    for (var i = 0; i < results.length; i++) {
      testDetails.write(':${results[i].description}:'
          '${collapseWhitespace(results[i].message)}');
    }
  }
  return '$passed:$failed:$errors:$totalTests:$count:'
      '$setup:$teardown:$uncaughtError$testDetails';
}

class TestConfiguration extends Configuration {

  // Some test state that is captured
  int count = 0; // a count of callbacks
  String setup = ''; // the name of the test group setup function, if any
  String teardown = ''; // the name of the test group teardown function, if any

  // The port to communicate with the parent isolate
  final SendPort _port;
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

makeDelayedSetup(index, s) => () {
  return new Future.delayed(new Duration(milliseconds:1), () {
    s.write('l$index U ');
  });
};

makeDelayedTeardown(index, s) => () {
  return new Future.delayed(new Duration(milliseconds:1), () {
    s.write('l$index D ');
  });
};

makeImmediateSetup(index, s) => () {
  s.write('l$index U ');
};

makeImmediateTeardown(index, s) => () {
  s.write('l$index D ');
};

runTest() {
  port.receive((String testName, sendport) {
    var testConfig = new TestConfiguration(sendport);
    unittestConfiguration = testConfig;

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
        setUp(() { testConfig.setup = 'setup'; });
        test(testName, () {});
      });
    } else if (testName == 'teardown test') {
      group('a', () {
        tearDown(() { testConfig.teardown = 'teardown'; });
        test(testName, () {});
      });
    } else if (testName == 'setup and teardown test') {
      group('a', () {
        setUp(() { testConfig.setup = 'setup'; });
        tearDown(() { testConfig.teardown = 'teardown'; });
        test(testName, () {});
      });
    } else if (testName == 'correct callback test') {
      test(testName,
        () =>_defer(expectAsync0((){ ++testConfig.count;})));
    } else if (testName == 'excess callback test') {
      test(testName, () {
        var _callback0 = expectAsync0(() => ++testConfig.count);
        var _callback1 = expectAsync0(() => ++testConfig.count);
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
               if (++testConfig.count < 10) {
                 _defer(_callback);
               }
             },
             () => (testConfig.count == 10));
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
          return new Future.value(0);
        });
        tearDown(() {
          return new Future.value(0);
        });
        test('foo1', (){});
      });
      group('good setup/bad teardown', () {
        setUp(() {
          return new Future.value(0);
        });
        tearDown(() {
          return new Future.error("Failed to complete tearDown");
        });
        test('foo2', (){});
      });
      group('bad setup/good teardown', () {
        setUp(() {
          return new Future.error("Failed to complete setUp");
        });
        tearDown(() {
          return new Future.value(0);
        });
        test('foo3', (){});
      });
      group('bad setup/bad teardown', () {
        setUp(() {
          return new Future.error("Failed to complete setUp");
        });
        tearDown(() {
          return new Future.error("Failed to complete tearDown");
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
    } else if (testName == 'test returning future using runAsync') {
      test("successful", () {
        return _defer(() {
          runAsync(() {
            guardAsync(() {
              expect(true, true);
            });
          });
        });
      });
      test("fail1", () {
        var callback = expectAsync0((){});
        return _defer(() {
          runAsync(() {
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
          runAsync(() {
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
          runAsync(() {
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
          runAsync(() {
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
    } else if (testName == 'testCases immutable') {
      test(testName, () {
        expect(() => testCases.clear(), throwsUnsupportedError);
        expect(() => testCases.removeLast(), throwsUnsupportedError);
      });
    } else if (testName == 'runTests without tests') {
      runTests();
    } else if (testName == 'nested groups setup/teardown') {
      StringBuffer s = new StringBuffer();
      group('level 1', () {
        setUp(makeDelayedSetup(1, s));
        group('level 2', () {
          setUp(makeImmediateSetup(2, s));
          tearDown(makeDelayedTeardown(2, s));
          group('level 3', () {
            group('level 4', () {
              setUp(makeDelayedSetup(4, s));
              tearDown(makeImmediateTeardown(4, s));
              group('level 5', () {
                setUp(makeImmediateSetup(5, s));
                group('level 6', () {
                  tearDown(makeDelayedTeardown(6, s));
                  test('inner', () {});
                });
              });
            });
          });
        });
      });
      test('after nest', () {
        expect(s.toString(), "l1 U l2 U l4 U l5 U l6 D l4 D l2 D ");
      });
    } else if (testName == 'skipped/soloed nested groups with setup/teardown') {
      StringBuffer s = null;
      setUp(() {
        if (s == null) 
          s = new StringBuffer();
      });
      test('top level', () {
        s.write('A');
      });
      skip_test('skipped top level', () {
        s.write('B');
      });
      skip_group('skipped top level group', () {
        setUp(() {
          s.write('C');
        });
        solo_test('skipped solo nested test', () {
          s.write('D');
        });
      });
      group('non-solo group', () {
        setUp(() {
          s.write('E');
        });
        test('in non-solo group', () {
          s.write('F');
        });
        solo_test('solo_test in non-solo group', () {
          s.write('G');
        });
      });
      solo_group('solo group', () {
        setUp(() {
          s.write('H');
        });
        test('solo group non-solo test', () {
          s.write('I');
        });
        solo_test('solo group solo test', () {
          s.write('J');
        });
        group('nested non-solo group in solo group', () {
          test('nested non-solo group non-solo test', () {
            s.write('K');
          });
          solo_test('nested non-solo group solo test', () {
            s.write('L');
          });
        });
      });
      solo_test('final', () {
        expect(s.toString(), "EGHIHJHKHL");
      });
    }
  });
}

main() {
  var tests = {
    'single correct test': buildStatusString(1, 0, 0, 'single correct test'),
    'single failing test': buildStatusString(0, 1, 0, 'single failing test',
        message: 'Expected: <5> Actual: <4>'),
    'exception test': buildStatusString(0, 0, 1, 'exception test',
        message: 'Test failed: Caught Exception: Fail.'),
    'group name test': buildStatusString(2, 0, 0, 'a a::a b b'),
    'setup test': buildStatusString(1, 0, 0, 'a setup test',
        count: 0, setup: 'setup'),
    'teardown test': buildStatusString(1, 0, 0, 'a teardown test',
        count: 0, setup: '', teardown: 'teardown'),
    'setup and teardown test': buildStatusString(1, 0, 0,
        'a setup and teardown test', count: 0, setup: 'setup',
        teardown: 'teardown'),
    'correct callback test': buildStatusString(1, 0, 0, 'correct callback test',
        count: 1),
    'excess callback test': buildStatusString(0, 1, 0, 'excess callback test',
        count: 1, message: 'Callback called more times than expected (1).'),
    'completion test': buildStatusString(1, 0, 0, 'completion test', count: 10),
    'async exception test': buildStatusString(0, 1, 0, 'async exception test',
        message: 'Caught error!'),
    'late exception test': buildStatusString(1, 0, 1, 'testOne',
        message: 'Callback called (2) after test case testOne has already '
                 'been marked as pass.:testTwo:'),
    'middle exception test': buildStatusString(2, 1, 0,
        'testOne::testTwo:Expected: false Actual: <true>:testThree'),
    'async setup/teardown test': buildStatusString(2, 0, 3,
        'good setup/good teardown foo1::'
        'good setup/bad teardown foo2:'
            'Teardown failed: Caught Failed to complete tearDown:'
        'bad setup/good teardown foo3:'
            'Setup failed: Caught Failed to complete setUp:'
        'bad setup/bad teardown foo4:'
            'Setup failed: Caught Failed to complete setUp:'
        'post groups'),
    'test returning future': buildStatusString(2, 4, 0,
        'successful::'
        'error1:Callback called more times than expected (1).:'
        'fail1:Expected: <false> Actual: <true>:'
        'error2:Callback called more times than expected (1).:'
        'fail2:failure:'
        'foo5'),
    'test returning future using runAsync': buildStatusString(2, 4, 0,
        'successful::'
        'fail1:Expected: <false> Actual: <true>:'
        'error1:Callback called more times than expected (1).:'
        'fail2:failure:'
        'error2:Callback called more times than expected (1).:'
        'foo6'),
    'testCases immutable':
        buildStatusString(1, 0, 0, 'testCases immutable'),
    'runTests without tests': buildStatusString(0, 0, 0, null),
    'nested groups setup/teardown':
        buildStatusString(2, 0, 0,
            'level 1 level 2 level 3 level 4 level 5 level 6 inner::'
            'after nest'),
    'skipped/soloed nested groups with setup/teardown':
        buildStatusString(6, 0, 0,
            'non-solo group solo_test in non-solo group::'
            'solo group solo group non-solo test::'
            'solo group solo group solo test::'
            'solo group nested non-solo group in solo group nested non-'
            'solo group non-solo test::'
            'solo group nested non-solo group in solo'
            ' group nested non-solo group solo test::'
            'final')
  };

  tests.forEach((String name, String expected) {
    test(name, () => spawnFunction(runTest)
        .call(name)
        .then((String msg) => expect(msg.trim(), equals(expected))));
    });
}

