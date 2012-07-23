// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(gram):
// Unfortunately I can't seem to test anything that involves timeouts, e.g.
// insufficient callbacks, because the timeout is controlled externally
// (test.dart?), and we would need to use a shorter timeout for the inner tests
// so the outer timeout doesn't fire. So I removed all such tests.
// I'd like to revisit this at some point.

#library('unittestTest');
#import('dart:isolate');
#import('../../../lib/unittest/unittest.dart');

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
                         [int count = 0,
                         String setup = '', String teardown = '',
                         String uncaughtError = null,
                         String message = '']) {
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
    var result = buildStatusString(passed, failed, errors, results, count,
        setup, teardown, uncaughtError);
    _port.send(result);
  }
}

class MockList extends Mock implements List {
}

class Foo {
  sum(a, b, c) => a + b + c;
}

class FooSpy extends Mock implements Foo {
  Foo real;
  FooSpy() {
    real = new Foo();
    this.when(callsTo('sum')).alwaysCall(real.sum);
  }
}

makeTestLogEntry(String methodName, List args, int time,
                 [String mockName]) {
  LogEntry e = new LogEntry(mockName, methodName, args, Action.IGNORE);
  e.time = new Date.fromMillisecondsSinceEpoch(time, true);
  return e;
}

makeTestLog() {
  LogEntryList log = new LogEntryList('test');
  List args = new List();
  log.add(makeTestLogEntry('a', args, 1000));
  log.add(makeTestLogEntry('b', args, 2000));
  log.add(makeTestLogEntry('c', args, 3000));
  return log;
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
    } else if (testName.startsWith('mock test 1 ')) {
      test(testName, () {
        var m = new Mock();
        print(m.length);
        m.getLogs(callsTo('get length')).verify(happenedOnce);

        m.when(callsTo('foo', 1, 2)).thenReturn('A').thenReturn('B');
        m.when(callsTo('foo', 1, 1)).thenReturn('C');
        m.when(callsTo('foo', 9, anything)).thenReturn('D');
        m.when(callsTo('bar', anything, anything)).thenReturn('E');
        m.when(callsTo('foobar')).thenReturn('F');

        var s = '${m.foo(1,2)}${m.foo(1,1)}${m.foo(9,10)}'
            '${m.bar(1,1)}${m.foo(1,2)}';
        m.getLogs(callsTo('foo', anything, anything)).
            verify(happenedExactly(4));
        m.getLogs(callsTo('foo', 1, anything)).verify(happenedExactly(3));
        m.getLogs(callsTo('foo', 9, anything)).verify(happenedOnce);
        m.getLogs(callsTo('foo', anything, 2)).verify(happenedExactly(2));
        m.getLogs(callsTo('foobar')).verify(neverHappened);
        m.getLogs(callsTo('foo', 10, anything)).verify(neverHappened);
        m.getLogs(callsTo('foo'), returning(anyOf('A', 'C'))).
              verify(happenedExactly(2));
        expect(s, 'ACDEB');
      });
    } else if (testName.startsWith('mock test 2 ')) {
      test(testName, () {
        var l = new MockList();
        l.when(callsTo('get length')).thenReturn(1);
        l.when(callsTo('add', anything)).alwaysReturn(0);
        l.add('foo');
        expect(l.length, 1);

        var m = new MockList();
        m.when(callsTo('add', anything)).alwaysReturn(0);

        m.add('foo');
        m.add('bar');

        m.getLogs(callsTo('add')).verify(happenedExactly(2));
        m.getLogs(callsTo('add', 'foo')).verify(happenedOnce);
      });
    } else if (testName.startsWith('mock test 3 ')) {
      test(testName, () {
        var p = new FooSpy();
        p.sum(1, 2, 3);
        p.getLogs(callsTo('sum')).verify(happenedOnce);
        p.sum(2, 2, 2);
        p.getLogs(callsTo('sum')).verify(happenedExactly(2));
        p.getLogs(callsTo('sum')).verify(sometimeReturned(6));
        p.getLogs(callsTo('sum')).verify(alwaysReturned(6));
        p.getLogs(callsTo('sum')).verify(neverReturned(5));
        p.sum(2, 2, 1);
        p.getLogs(callsTo('sum')).verify(sometimeReturned(5));
      });
    } else if (testName.startsWith('mock test 4 ')) {
      test(testName, () {
        var m = new Mock();
        m.when(callsTo('foo')).alwaysReturn(null);
        m.foo();
        m.foo();
        m.getLogs(callsTo('foo')).verify(happenedOnce);
      });
    } else if (testName.startsWith('mock test 5 ')) {
      test(testName, () {
        var m = new Mock();
        m.when(callsTo('foo')).thenReturn(null);
        m.foo();
        m.foo();
      });
    } else if (testName.startsWith('mock test 6 ')) {
      test(testName, () {
        var p = new FooSpy();
        p.sum(1, 2, 3);
        p.getLogs(callsTo('sum')).verify(sometimeReturned(0));
      });
    } else if (testName.startsWith('mock test 7 ')) {
      test(testName, () {
        var m = new Mock.custom(throwIfNoBehavior:true);
        m.when(callsTo('foo')).thenReturn(null);
        m.foo();
        m.bar();
      });
    } else if (testName.startsWith('mock test 8 ')) {
      test(testName, () {
        var log = new LogEntryList();
        var m1 = new Mock.custom(name:'m1', log:log);
        var m2 = new Mock.custom(name:'m2', log:log);
        m1.foo();
        m2.foo();
        m1.bar();
        m2.bar();
        expect(log.logs.length, 4);
        log.getMatches(anything, callsTo('foo')).verify(happenedExactly(2));
        log.getMatches('m1', callsTo('foo')).verify(happenedOnce);
        log.getMatches('m1', callsTo('bar')).verify(happenedOnce);
        m2.getLogs(callsTo('foo')).verify(happenedOnce);
        m2.getLogs(callsTo('bar')).verify(happenedOnce);
      });
    } else if (testName.startsWith('mock test 9 ')) {
      test(testName, () {
        var m = new Mock();
        m.when(callsTo(null, 1)).alwaysReturn(2);
        m.when(callsTo(null, 2)).alwaysReturn(4);
        expect(m.foo(1), 2);
        expect(m.foo(2), 4);
        expect(m.bar(1), 2);
        expect(m.bar(2), 4);
        m.getLogs(callsTo()).verify(happenedExactly(4));
        m.getLogs(callsTo(null, 1)).verify(happenedExactly(2));
        m.getLogs(callsTo(null, 2)).verify(happenedExactly(2));
        m.getLogs(null, returning(1)).verify(neverHappened);
        m.getLogs(null, returning(2)).verify(happenedExactly(2));
        m.getLogs(null, returning(4)).verify(happenedExactly(2));
      });
    } else if (testName.startsWith('mock test 10 ')) {
      test(testName, () {
        var m = new Mock();
        m.when(callsTo(matches('^[A-Z]'))).
            alwaysThrow('Method names must start with lower case.');
        m.test();
      });
    } else if (testName.startsWith('mock test 11 ')) {
      test(testName, () {
        var m = new Mock();
        m.when(callsTo(matches('^[A-Z]'))).
            alwaysThrow('Method names must start with lower case.');
        m.Test();
      });
    } else if (testName.startsWith('mock test 12 ')) {
      test(testName, () {
        var m = new Mock.custom(enableLogging:false);
        m.Test();
        print(m.getLogs(callsTo('Test')).toString());
      });
    } else if (testName.startsWith('mock test 13 ')) {
      test(testName, () {
        LogEntryList log = makeTestLog();
        // Basic behavior, with call matcher.
        expect(log.findLogEntry(callsTo('a')), 0);
        expect(log.findLogEntry(callsTo('b')), 1);
        expect(log.findLogEntry(callsTo('c')), 2);
        expect(log.findLogEntry(callsTo('d')), -1);
        // Find using predicate.
        expect(log.findLogEntry((le) => le.methodName == 'a'), 0);
        expect(log.findLogEntry((le) => le.methodName == 'b'), 1);
        expect(log.findLogEntry((le) => le.methodName == 'c'), 2);
        // Test explicit return value.
        expect(log.findLogEntry((le) => le.methodName == 'd', 0, 3), 3);
        // Find from start of log.
        expect(log.findLogEntry(callsTo('a'), 0), 0);
        expect(log.findLogEntry(callsTo('b'), 0), 1);
        expect(log.findLogEntry(callsTo('c'), 0), 2);
        // Find from second entry in log.
        expect(log.findLogEntry(callsTo('a'), 1), -1);
        expect(log.findLogEntry(callsTo('b'), 1), 1);
        expect(log.findLogEntry(callsTo('c'), 1), 2);
        // Find from last entry in log.
        expect(log.findLogEntry(callsTo('a'), 2), -1);
        expect(log.findLogEntry(callsTo('b'), 2), -1);
        expect(log.findLogEntry(callsTo('c'), 2), 2);
        // Find from start position passed end of log.
        expect(log.findLogEntry(callsTo('a'), 3), -1);
        expect(log.findLogEntry(callsTo('b'), 3), -1);
        expect(log.findLogEntry(callsTo('c'), 3), -1);
        // No restriction on entry.
        expect(log.findLogEntry(null, 0), 0);
        expect(log.findLogEntry(null, 1), 1);
        expect(log.findLogEntry(null, 2), 2);
        expect(log.findLogEntry(null, 3), -1);
      });
    } else if (testName.startsWith('mock test 14 ')) {
      test(testName, () {
        LogEntryList log = makeTestLog();
        LogEntryList log2;
        Date t0 = new Date.fromMillisecondsSinceEpoch(0, true);
        Date t1000 = new Date.fromMillisecondsSinceEpoch(1000, true);
        Date t2000 = new Date.fromMillisecondsSinceEpoch(2000, true);
        Date t3000 = new Date.fromMillisecondsSinceEpoch(3000, true);
        Date t4000 = new Date.fromMillisecondsSinceEpoch(4000, true);

        log2 = log.before(t0);
        expect(log2.logs, hasLength(0));
        expect(log2.filter, 'test before 1970-01-01 00:00:00.000Z');
        log2 = log.until(t0);
        expect(log2.logs, hasLength(0));
        expect(log2.filter, 'test until 1970-01-01 00:00:00.000Z');
        log2 = log.from(t0);
        expect(log2.logs, hasLength(3));
        expect(log2.first.methodName, 'a');
        expect(log2.last.methodName, 'c');
        expect(log2.filter, 'test from 1970-01-01 00:00:00.000Z');
        log2 = log.after(t0);
        expect(log2.logs, hasLength(3));
        expect(log2.first.methodName, 'a');
        expect(log2.last.methodName, 'c');
        expect(log2.filter, 'test after 1970-01-01 00:00:00.000Z');

        log2 = log.before(t1000);
        expect(log2.logs, hasLength(0));
        log2 = log.until(t1000);
        expect(log2.logs, hasLength(1));
        expect(log2.first.methodName, 'a');
        expect(log2.last.methodName, 'a');
        log2 = log.from(t1000);
        expect(log2.logs, hasLength(3));
        expect(log2.first.methodName, 'a');
        expect(log2.last.methodName, 'c');
        log2 = log.after(t1000);
        expect(log2.logs, hasLength(2));
        expect(log2.first.methodName, 'b');
        expect(log2.last.methodName, 'c');

        log2 = log.before(t2000);
        expect(log2.logs, hasLength(1));
        expect(log2.first.methodName, 'a');
        expect(log2.last.methodName, 'a');
        log2 = log.until(t2000);
        expect(log2.logs, hasLength(2));
        expect(log2.first.methodName, 'a');
        expect(log2.last.methodName, 'b');
        log2 = log.from(t2000);
        expect(log2.logs, hasLength(2));
        expect(log2.first.methodName, 'b');
        expect(log2.last.methodName, 'c');
        log2 = log.after(t2000);
        expect(log2.logs, hasLength(1));
        expect(log2.first.methodName, 'c');
        expect(log2.last.methodName, 'c');

        log2 = log.before(t3000);
        expect(log2.logs, hasLength(2));
        expect(log2.first.methodName, 'a');
        expect(log2.last.methodName, 'b');
        log2 = log.until(t3000);
        expect(log2.logs, hasLength(3));
        expect(log2.first.methodName, 'a');
        expect(log2.last.methodName, 'c');

        log2 = log.from(t3000);
        expect(log2.logs, hasLength(1));
        expect(log2.first.methodName, 'c');
        expect(log2.last.methodName, 'c');
        log2 = log.after(t3000);
        expect(log2.logs, hasLength(0));

        log2 = log.before(t4000);
        expect(log2.logs, hasLength(3));
        expect(log2.first.methodName, 'a');
        expect(log2.last.methodName, 'c');
        log2 = log.until(t4000);
        expect(log2.logs, hasLength(3));
        expect(log2.first.methodName, 'a');
        expect(log2.last.methodName, 'c');
        log2 = log.from(t4000);
        expect(log2.logs, hasLength(0));
        log2 = log.after(t4000);
        expect(log2.logs, hasLength(0));
      });
    } else if (testName.startsWith('mock test 15 ')) {
      test(testName, () {
        Date t0 = new Date.fromMillisecondsSinceEpoch(0, true);
        Date t1000 = new Date.fromMillisecondsSinceEpoch(1000, true);
        Date t2000 = new Date.fromMillisecondsSinceEpoch(2000, true);
        Date t3000 = new Date.fromMillisecondsSinceEpoch(3000, true);
        Date t4000 = new Date.fromMillisecondsSinceEpoch(4000, true);

        LogEntryList log = makeTestLog().before(t0, true);
        expect(log.logs, hasLength(0));
        expect(log.filter, 'test before 1970-01-01 00:00:00.000Z');
        log = makeTestLog().until(t0, true);
        expect(log.logs, hasLength(0));
        expect(log.filter, 'test until 1970-01-01 00:00:00.000Z');
        log = makeTestLog().from(t0, true);
        expect(log.logs, hasLength(3));
        expect(log.first.methodName, 'a');
        expect(log.last.methodName, 'c');
        expect(log.filter, 'test from 1970-01-01 00:00:00.000Z');
        log = makeTestLog().after(t0, true);
        expect(log.logs, hasLength(3));
        expect(log.first.methodName, 'a');
        expect(log.last.methodName, 'c');
        expect(log.filter, 'test after 1970-01-01 00:00:00.000Z');

        log = makeTestLog().before(t1000, true);
        expect(log.logs, hasLength(0));
        log = makeTestLog().until(t1000, true);
        expect(log.logs, hasLength(1));
        expect(log.first.methodName, 'a');
        expect(log.last.methodName, 'a');
        log = makeTestLog().from(t1000, true);
        expect(log.logs, hasLength(3));
        expect(log.first.methodName, 'a');
        expect(log.last.methodName, 'c');
        log = makeTestLog().after(t1000, true);
        expect(log.logs, hasLength(2));
        expect(log.first.methodName, 'b');
        expect(log.last.methodName, 'c');

        log = makeTestLog().before(t2000, true);
        expect(log.logs, hasLength(1));
        expect(log.first.methodName, 'a');
        expect(log.last.methodName, 'a');
        log = makeTestLog().until(t2000, true);
        expect(log.logs, hasLength(2));
        expect(log.first.methodName, 'a');
        expect(log.last.methodName, 'b');
        log = makeTestLog().from(t2000, true);
        expect(log.logs, hasLength(2));
        expect(log.first.methodName, 'b');
        expect(log.last.methodName, 'c');
        log = makeTestLog().after(t2000, true);
        expect(log.logs, hasLength(1));
        expect(log.first.methodName, 'c');
        expect(log.last.methodName, 'c');

        log = makeTestLog().before(t3000, true);
        expect(log.logs, hasLength(2));
        expect(log.first.methodName, 'a');
        expect(log.last.methodName, 'b');
        log = makeTestLog().until(t3000, true);
        expect(log.logs, hasLength(3));
        expect(log.first.methodName, 'a');
        expect(log.last.methodName, 'c');
        log = makeTestLog().from(t3000, true);
        expect(log.logs, hasLength(1));
        expect(log.first.methodName, 'c');
        expect(log.last.methodName, 'c');
        log = makeTestLog().after(t3000);
        expect(log.logs, hasLength(0));

        log = makeTestLog().before(t4000, true);
        expect(log.logs, hasLength(3));
        expect(log.first.methodName, 'a');
        expect(log.last.methodName, 'c');
        log = makeTestLog().until(t4000, true);
        expect(log.logs, hasLength(3));
        expect(log.first.methodName, 'a');
        expect(log.last.methodName, 'c');
        log = makeTestLog().from(t4000, true);
        expect(log.logs, hasLength(0));
        log = makeTestLog().after(t4000, true);
        expect(log.logs, hasLength(0));
      });
    } else if (testName.startsWith('mock test 16 ')) {
      test(testName, () {
        LogEntryList log = new LogEntryList('test');
        List args0 = new List();
        List args1 = new List();
        args1.add('test');
        LogEntry e0 = makeTestLogEntry('foo', args0, 1000);
        log.add(e0);
        LogEntry e1 = makeTestLogEntry('bar1', args0, 2000, 'a');
        log.add(e1);
        LogEntry e2 = makeTestLogEntry('bar1', args1, 3000, 'b');
        log.add(e2);
        LogEntry e3 = makeTestLogEntry('foo', args0, 4000);
        log.add(e3);
        LogEntry e4 = makeTestLogEntry('hello', args0, 4500);
        log.add(e4);
        LogEntry e5 = makeTestLogEntry('bar2', args0, 5000, 'a');
        log.add(e5);
        LogEntry e6 = makeTestLogEntry('bar2', args1, 6000, 'b');
        log.add(e6);
        LogEntry e7 = makeTestLogEntry('foo', args0, 7000);
        log.add(e7);
        LogEntry e8 = makeTestLogEntry('bar3', args0, 8000, 'a');
        log.add(e8);
        LogEntry e9 = makeTestLogEntry('bar3', args1, 9000, 'b');
        log.add(e9);
        LogEntry e10 = makeTestLogEntry('foo', args0, 10000);
        log.add(e10);

        LogEntryList keyList = new LogEntryList('keys');

        // Test with empty key list.

        LogEntryList result;
        result = log.preceding(keyList);
        expect(result.logs, hasLength(0));

        result = log.preceding(keyList, includeKeys:true);
        expect(result.logs, hasLength(0));

        // Single key, distance 1, no restrictions.

        keyList.add(e3);
        result = log.preceding(keyList);
        expect(result.logs, orderedEquals([e2]));

        result = log.following(keyList);
        expect(result.logs, orderedEquals([e4]));

        // Single key, distance 2, no restrictions.

        result = log.preceding(keyList, distance:2);
        expect(result.logs, orderedEquals([e1, e2]));

        result = log.following(keyList, distance:2);
        expect(result.logs, orderedEquals([e4, e5]));

        // Single key, distance 3, no restrictions.

        result = log.preceding(keyList, distance:3);
        expect(result.logs, orderedEquals([e0, e1, e2]));

        result = log.following(keyList, distance:3);
        expect(result.logs, orderedEquals([e4, e5, e6]));

        // Include keys in result

        result = log.preceding(keyList, distance:3, includeKeys:true);
        expect(result.logs, orderedEquals([e0, e1, e2, e3]));

        result = log.following(keyList, distance:3, includeKeys:true);
        expect(result.logs, orderedEquals([e3, e4, e5, e6]));

        // Restrict the matches

        result = log.preceding(keyList, logFilter:callsTo(startsWith('bar')),
          distance:3);
        expect(result.logs, orderedEquals([e1, e2]));

        result = log.preceding(keyList, logFilter:callsTo(startsWith('bar')),
            distance:3, includeKeys:true);
        expect(result.logs, orderedEquals([e1, e2, e3]));

        result = log.preceding(keyList, equals('a'), callsTo(startsWith('bar')),
          distance:3);
        expect(result.logs, orderedEquals([e1]));

        result = log.preceding(keyList, equals('a'), callsTo(startsWith('bar')),
            distance:3, includeKeys:true);
        expect(result.logs, orderedEquals([e1, e3]));

        keyList.logs.clear();
        keyList.add(e0);
        keyList.add(e3);
        keyList.add(e7);

        result = log.preceding(keyList);
        expect(result.logs, orderedEquals([e2, e6]));

        result = log.following(keyList);
        expect(result.logs, orderedEquals([e1, e4, e8]));

        result = log.preceding(keyList, includeKeys:true);
        expect(result.logs, orderedEquals([e0, e2, e3, e6, e7]));

        result = log.following(keyList, includeKeys:true);
        expect(result.logs, orderedEquals([e0, e1, e3, e4, e7, e8]));

        keyList.logs.clear();
        keyList.add(e3);
        keyList.add(e7);
        keyList.add(e10);

        result = log.preceding(keyList);
        expect(result.logs, orderedEquals([e2, e6, e9]));

        result = log.following(keyList);
        expect(result.logs, orderedEquals([e4, e8]));

        result = log.preceding(keyList, includeKeys:true);
        expect(result.logs, orderedEquals([e2, e3, e6, e7, e9, e10]));

        result = log.following(keyList, includeKeys:true);
        expect(result.logs, orderedEquals([e3, e4, e7, e8, e10]));

        keyList.logs.clear();
        keyList.add(e0);
        keyList.add(e3);
        keyList.add(e7);
        keyList.add(e10);

        result = log.preceding(keyList);
        expect(result.logs, orderedEquals([e2, e6, e9]));

        result = log.following(keyList);
        expect(result.logs, orderedEquals([e1, e4, e8]));

        result = log.preceding(keyList, includeKeys:true);
        expect(result.logs, orderedEquals([e0, e2, e3, e6, e7, e9, e10]));

        result = log.following(keyList, includeKeys:true);
        expect(result.logs, orderedEquals([e0, e1, e3, e4, e7, e8, e10]));

        keyList.logs.clear();
        keyList.add(e0);
        keyList.add(e3);
        keyList.add(e7);

        result = log.preceding(keyList, distance:3);
        expect(result.logs, orderedEquals([e1, e2, e4, e5, e6]));

        result = log.following(keyList, distance:3);
        expect(result.logs, orderedEquals([e1, e2, e4, e5, e6, e8, e9, e10]));

        result = log.preceding(keyList, distance:3, includeKeys:true);
        expect(result.logs, orderedEquals([e0, e1, e2, e3, e4, e5, e6, e7]));

        result = log.following(keyList, distance:3, includeKeys:true);
        expect(result.logs, orderedEquals([e0, e1, e2, e3, e4, e5, e6,
                                           e7, e8, e9, e10]));

        keyList.logs.clear();
        keyList.add(e3);
        keyList.add(e7);
        keyList.add(e10);

        result = log.preceding(keyList, distance:3);
        expect(result.logs, orderedEquals([e0, e1, e2, e4, e5, e6, e8, e9]));

        result = log.following(keyList, distance:3);
        expect(result.logs, orderedEquals([e4, e5, e6, e8, e9]));

        result = log.preceding(keyList, distance:3, includeKeys:true);
        expect(result.logs, orderedEquals([e0, e1, e2, e3, e4, e5, e6,
                                           e7, e8, e9, e10]));

        result = log.following(keyList, distance:3, includeKeys:true);
        expect(result.logs, orderedEquals([e3, e4, e5, e6, e7, e8, e9, e10]));

        keyList.logs.clear();
        keyList.add(e0);
        keyList.add(e3);
        keyList.add(e7);
        keyList.add(e10);

        result = log.preceding(keyList, distance:3);
        expect(result.logs, orderedEquals([e1, e2, e4, e5, e6, e8, e9]));

        result = log.following(keyList, distance:3);
        expect(result.logs, orderedEquals([e1, e2, e4, e5, e6, e8, e9]));

        result = log.preceding(keyList, distance:3, includeKeys:true);
        expect(result.logs, orderedEquals([e0, e1, e2, e3, e4, e5, e6,
                                           e7, e8, e9, e10]));

        result = log.following(keyList, distance:3, includeKeys:true);
        expect(result.logs, orderedEquals([e0, e1, e2, e3, e4, e5, e6,
                                           e7, e8, e9, e10]));
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
    'mock test 1 (Mock)',
    'mock test 2 (MockList)',
    'mock test 3 (Spy)',
    'mock test 4 (Excess calls)',
    'mock test 5 (No action)',
    'mock test 6 (No matching return)',
    'mock test 7 (No behavior)',
    'mock test 8 (Shared log)',
    'mock test 9 (Null CallMatcher)',
    'mock test 10 (RegExp CallMatcher Good)',
    'mock test 11 (RegExp CallMatcher Bad)',
    'mock test 12 (No logging)',
    'mock test 13 (find log entry)',
    'mock test 14 (from,after,before,until)',
    'mock test 15 (inplace from,after,before,until)',
    'mock test 16 (neighbors)'
  ];

  expected = [
    buildStatusString(1, 0, 0, tests[0]),
    buildStatusString(0, 1, 0, tests[1],
        message: 'Expected: <5> but: was <4>.'),
    buildStatusString(0, 1, 0, tests[2], message: 'Caught Exception: Fail.'),
    buildStatusString(2, 0, 0, 'a a::a b b'),
    buildStatusString(1, 0, 0, 'a ${tests[4]}', 0, 'setup'),
    buildStatusString(1, 0, 0, 'a ${tests[5]}', 0, '', 'teardown'),
    buildStatusString(1, 0, 0, 'a ${tests[6]}', 0,
        'setup', 'teardown'),
    buildStatusString(1, 0, 0, tests[7], 1),
    buildStatusString(0, 0, 1, tests[8], 1,
        message: 'Callback called more times than expected (2 > 1).'),
    buildStatusString(1, 0, 0, tests[9], 10),
    buildStatusString(1, 0, 0, tests[10]),
    buildStatusString(1, 0, 0, tests[11]),
    buildStatusString(1, 0, 0, tests[12]),
    buildStatusString(0, 1, 0, tests[13],
        message: "Expected foo() to be called 1 times but:"
            " was called 2 times."),
    buildStatusString(0, 1, 0, tests[14],
        message: 'Caught Exception: No more actions for method foo.'),
    buildStatusString(0, 1, 0, tests[15], message:
        "Expected sum() to sometimes return <0> but: never did."),
    buildStatusString(0, 1, 0, tests[16],
        message: 'Caught Exception: No behavior specified for method bar.'),
    buildStatusString(1, 0, 0, tests[17]),
    buildStatusString(1, 0, 0, tests[18]),
    buildStatusString(1, 0, 0, tests[19]),
    buildStatusString(0, 1, 0, tests[20],
        message:'Caught Method names must start with lower case.'),
    buildStatusString(0, 1, 0, tests[21], message:
      "Caught Exception: Can't retrieve logs when logging was never enabled."),
    buildStatusString(1, 0, 0, tests[22]),
    buildStatusString(1, 0, 0, tests[23]),
    buildStatusString(1, 0, 0, tests[24]),
    buildStatusString(1, 0, 0, tests[25])
  ];

  actual = [];

  nextTest(0);
}

