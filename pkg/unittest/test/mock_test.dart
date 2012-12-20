// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock_test;
import '../../../pkg/unittest/lib/unittest.dart';
import '../../../pkg/unittest/lib/mock.dart';

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
  e.time = new Date.fromMillisecondsSinceEpoch(time, isUtc: true);
  return e;
}

makeTestLog() {
  LogEntryList logList = new LogEntryList('test');
  List args = new List();
  logList.add(makeTestLogEntry('a', args, 1000));
  logList.add(makeTestLogEntry('b', args, 2000));
  logList.add(makeTestLogEntry('c', args, 3000));
  return logList;
}

main() {
  test('Mocking: Basics', () {
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

  test('Mocking: Mock List', () {
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

  test('Mocking: Spy', () {
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

  test('Mocking: Excess Calls', () {
    var m = new Mock();
    m.when(callsTo('foo')).alwaysReturn(null);
    expect(() { m.foo(); }, returnsNormally);
    expect(() { m.foo(); }, returnsNormally);
    expect(
        () {
          m.getLogs(callsTo('foo')).verify(happenedOnce);
        },
      throwsA(
        (e) =>
          collapseWhitespace(e.toString()) ==
            "Expected foo() to be called 1 times but:"
                   " was called 2 times.")
    );
  });

  test('Mocking: No action', () {
    var m = new Mock();
    m.when(callsTo('foo')).thenReturn(null);
    expect(() => m.foo(), returnsNormally);
    expect(() => m.foo(), throwsA((e) =>
        e.toString() == 'Exception: No more actions for method foo.'));
  });

  test('Mocking: No matching return', () {
    var p = new FooSpy();
    p.sum(1, 2, 3);
    expect(() => p.getLogs(callsTo('sum')).verify(sometimeReturned(0)),
      throwsA((e) => collapseWhitespace(e.toString()) ==
          "Expected sum() to sometimes return <0> but: never did.")
    );
  });

  test('Mocking: No behavior', () {
    var m = new Mock.custom(throwIfNoBehavior:true);
    m.when(callsTo('foo')).thenReturn(null);
    expect(() => m.foo(), returnsNormally);
    expect(() => m.bar(), throwsA((e) => e.toString() ==
        'Exception: No behavior specified for method bar.'));
  });

  test('Mocking: Shared logList', () {
    var logList = new LogEntryList();
    var m1 = new Mock.custom(name:'m1', log:logList);
    var m2 = new Mock.custom(name:'m2', log:logList);
    m1.foo();
    m2.foo();
    m1.bar();
    m2.bar();
    expect(logList.logs.length, 4);
    logList.getMatches(anything, callsTo('foo')).verify(happenedExactly(2));
    logList.getMatches('m1', callsTo('foo')).verify(happenedOnce);
    logList.getMatches('m1', callsTo('bar')).verify(happenedOnce);
    m2.getLogs(callsTo('foo')).verify(happenedOnce);
    m2.getLogs(callsTo('bar')).verify(happenedOnce);
  });

  test('Mocking: Null CallMatcher', () {
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

  test('Mocking: RegExp CallMatcher good', () {	
    var m = new Mock();	
    m.when(callsTo(matches('^[A-Z]'))).	
           alwaysThrow('Method names must start with lower case.');	
    m.test();	
  });

  test('Mocking: No logging', () {
    var m = new Mock.custom(enableLogging:false);
    m.Test();
    expect(() => m.getLogs(callsTo('Test')), throwsA((e) => e.toString() ==
        "Exception: Can't retrieve logs when logging was never enabled."));
  });

  test('Mocking: Find logList entry', () {
    LogEntryList logList = makeTestLog();
    // Basic behavior, with call matcher.
    expect(logList.findLogEntry(callsTo('a')), 0);
    expect(logList.findLogEntry(callsTo('b')), 1);
    expect(logList.findLogEntry(callsTo('c')), 2);
    expect(logList.findLogEntry(callsTo('d')), -1);
    // Find using predicate.
    expect(logList.findLogEntry((le) => le.methodName == 'a'), 0);
    expect(logList.findLogEntry((le) => le.methodName == 'b'), 1);
    expect(logList.findLogEntry((le) => le.methodName == 'c'), 2);
    // Test explicit return value.
    expect(logList.findLogEntry((le) => le.methodName == 'd', 0, 3), 3);
    // Find from start of logList.
    expect(logList.findLogEntry(callsTo('a'), 0), 0);
    expect(logList.findLogEntry(callsTo('b'), 0), 1);
    expect(logList.findLogEntry(callsTo('c'), 0), 2);
    // Find from second entry in logList.
    expect(logList.findLogEntry(callsTo('a'), 1), -1);
    expect(logList.findLogEntry(callsTo('b'), 1), 1);
    expect(logList.findLogEntry(callsTo('c'), 1), 2);
    // Find from last entry in logList.
    expect(logList.findLogEntry(callsTo('a'), 2), -1);
    expect(logList.findLogEntry(callsTo('b'), 2), -1);
    expect(logList.findLogEntry(callsTo('c'), 2), 2);
    // Find from start position passed end of logList.
    expect(logList.findLogEntry(callsTo('a'), 3), -1);
    expect(logList.findLogEntry(callsTo('b'), 3), -1);
    expect(logList.findLogEntry(callsTo('c'), 3), -1);
    // No restriction on entry.
    expect(logList.findLogEntry(null, 0), 0);
    expect(logList.findLogEntry(null, 1), 1);
    expect(logList.findLogEntry(null, 2), 2);
    expect(logList.findLogEntry(null, 3), -1);
  });

  test('Mocking: from,after,before,until', () {
    LogEntryList logList = makeTestLog();
    LogEntryList log2;
    Date t0 = new Date.fromMillisecondsSinceEpoch(0, isUtc: true);
    Date t1000 = new Date.fromMillisecondsSinceEpoch(1000, isUtc: true);
    Date t2000 = new Date.fromMillisecondsSinceEpoch(2000, isUtc: true);
    Date t3000 = new Date.fromMillisecondsSinceEpoch(3000, isUtc: true);
    Date t4000 = new Date.fromMillisecondsSinceEpoch(4000, isUtc: true);

    log2 = logList.before(t0);
    expect(log2.logs, hasLength(0));
    expect(log2.filter, 'test before 1970-01-01 00:00:00.000Z');
    log2 = logList.until(t0);
    expect(log2.logs, hasLength(0));
    expect(log2.filter, 'test until 1970-01-01 00:00:00.000Z');
    log2 = logList.from(t0);
    expect(log2.logs, hasLength(3));
    expect(log2.first.methodName, 'a');
    expect(log2.last.methodName, 'c');
    expect(log2.filter, 'test from 1970-01-01 00:00:00.000Z');
    log2 = logList.after(t0);
    expect(log2.logs, hasLength(3));
    expect(log2.first.methodName, 'a');
    expect(log2.last.methodName, 'c');
    expect(log2.filter, 'test after 1970-01-01 00:00:00.000Z');

    log2 = logList.before(t1000);
    expect(log2.logs, hasLength(0));
    log2 = logList.until(t1000);
    expect(log2.logs, hasLength(1));
    expect(log2.first.methodName, 'a');
    expect(log2.last.methodName, 'a');
    log2 = logList.from(t1000);
    expect(log2.logs, hasLength(3));
    expect(log2.first.methodName, 'a');
    expect(log2.last.methodName, 'c');
    log2 = logList.after(t1000);
    expect(log2.logs, hasLength(2));
    expect(log2.first.methodName, 'b');
    expect(log2.last.methodName, 'c');

    log2 = logList.before(t2000);
    expect(log2.logs, hasLength(1));
    expect(log2.first.methodName, 'a');
    expect(log2.last.methodName, 'a');
    log2 = logList.until(t2000);
    expect(log2.logs, hasLength(2));
    expect(log2.first.methodName, 'a');
    expect(log2.last.methodName, 'b');
    log2 = logList.from(t2000);
    expect(log2.logs, hasLength(2));
    expect(log2.first.methodName, 'b');
    expect(log2.last.methodName, 'c');
    log2 = logList.after(t2000);
    expect(log2.logs, hasLength(1));
    expect(log2.first.methodName, 'c');
    expect(log2.last.methodName, 'c');

    log2 = logList.before(t3000);
    expect(log2.logs, hasLength(2));
    expect(log2.first.methodName, 'a');
    expect(log2.last.methodName, 'b');
    log2 = logList.until(t3000);
    expect(log2.logs, hasLength(3));
    expect(log2.first.methodName, 'a');
    expect(log2.last.methodName, 'c');

    log2 = logList.from(t3000);
    expect(log2.logs, hasLength(1));
    expect(log2.first.methodName, 'c');
    expect(log2.last.methodName, 'c');
    log2 = logList.after(t3000);
    expect(log2.logs, hasLength(0));

    log2 = logList.before(t4000);
    expect(log2.logs, hasLength(3));
    expect(log2.first.methodName, 'a');
    expect(log2.last.methodName, 'c');
    log2 = logList.until(t4000);
    expect(log2.logs, hasLength(3));
    expect(log2.first.methodName, 'a');
    expect(log2.last.methodName, 'c');
    log2 = logList.from(t4000);
    expect(log2.logs, hasLength(0));
    log2 = logList.after(t4000);
    expect(log2.logs, hasLength(0));
  });

  test('Mocking: inplace from,after,before,until', () {
    Date t0 = new Date.fromMillisecondsSinceEpoch(0, isUtc: true);
    Date t1000 = new Date.fromMillisecondsSinceEpoch(1000, isUtc: true);
    Date t2000 = new Date.fromMillisecondsSinceEpoch(2000, isUtc: true);
    Date t3000 = new Date.fromMillisecondsSinceEpoch(3000, isUtc: true);
    Date t4000 = new Date.fromMillisecondsSinceEpoch(4000, isUtc: true);

    LogEntryList logList = makeTestLog().before(t0, true);
    expect(logList.logs, hasLength(0));
    expect(logList.filter, 'test before 1970-01-01 00:00:00.000Z');
    logList = makeTestLog().until(t0, true);
    expect(logList.logs, hasLength(0));
    expect(logList.filter, 'test until 1970-01-01 00:00:00.000Z');
    logList = makeTestLog().from(t0, true);
    expect(logList.logs, hasLength(3));
    expect(logList.first.methodName, 'a');
    expect(logList.last.methodName, 'c');
    expect(logList.filter, 'test from 1970-01-01 00:00:00.000Z');
    logList = makeTestLog().after(t0, true);
    expect(logList.logs, hasLength(3));
    expect(logList.first.methodName, 'a');
    expect(logList.last.methodName, 'c');
    expect(logList.filter, 'test after 1970-01-01 00:00:00.000Z');

    logList = makeTestLog().before(t1000, true);
    expect(logList.logs, hasLength(0));
    logList = makeTestLog().until(t1000, true);
    expect(logList.logs, hasLength(1));
    expect(logList.first.methodName, 'a');
    expect(logList.last.methodName, 'a');
    logList = makeTestLog().from(t1000, true);
    expect(logList.logs, hasLength(3));
    expect(logList.first.methodName, 'a');
    expect(logList.last.methodName, 'c');
    logList = makeTestLog().after(t1000, true);
    expect(logList.logs, hasLength(2));
    expect(logList.first.methodName, 'b');
    expect(logList.last.methodName, 'c');

    logList = makeTestLog().before(t2000, true);
    expect(logList.logs, hasLength(1));
    expect(logList.first.methodName, 'a');
    expect(logList.last.methodName, 'a');
    logList = makeTestLog().until(t2000, true);
    expect(logList.logs, hasLength(2));
    expect(logList.first.methodName, 'a');
    expect(logList.last.methodName, 'b');
    logList = makeTestLog().from(t2000, true);
    expect(logList.logs, hasLength(2));
    expect(logList.first.methodName, 'b');
    expect(logList.last.methodName, 'c');
    logList = makeTestLog().after(t2000, true);
    expect(logList.logs, hasLength(1));
    expect(logList.first.methodName, 'c');
    expect(logList.last.methodName, 'c');

    logList = makeTestLog().before(t3000, true);
    expect(logList.logs, hasLength(2));
    expect(logList.first.methodName, 'a');
    expect(logList.last.methodName, 'b');
    logList = makeTestLog().until(t3000, true);
    expect(logList.logs, hasLength(3));
    expect(logList.first.methodName, 'a');
    expect(logList.last.methodName, 'c');
    logList = makeTestLog().from(t3000, true);
    expect(logList.logs, hasLength(1));
    expect(logList.first.methodName, 'c');
    expect(logList.last.methodName, 'c');
    logList = makeTestLog().after(t3000);
    expect(logList.logs, hasLength(0));

    logList = makeTestLog().before(t4000, true);
    expect(logList.logs, hasLength(3));
    expect(logList.first.methodName, 'a');
    expect(logList.last.methodName, 'c');
    logList = makeTestLog().until(t4000, true);
    expect(logList.logs, hasLength(3));
    expect(logList.first.methodName, 'a');
    expect(logList.last.methodName, 'c');
    logList = makeTestLog().from(t4000, true);
    expect(logList.logs, hasLength(0));
    logList = makeTestLog().after(t4000, true);
    expect(logList.logs, hasLength(0));
  });

  test('Mocking: Neighbors', () {
    LogEntryList logList = new LogEntryList('test');
    List args0 = new List();
    List args1 = new List();
    args1.add('test');
    LogEntry e0 = makeTestLogEntry('foo', args0, 1000);
    logList.add(e0);
    LogEntry e1 = makeTestLogEntry('bar1', args0, 2000, 'a');
    logList.add(e1);
    LogEntry e2 = makeTestLogEntry('bar1', args1, 3000, 'b');
    logList.add(e2);
    LogEntry e3 = makeTestLogEntry('foo', args0, 4000);
    logList.add(e3);
    LogEntry e4 = makeTestLogEntry('hello', args0, 4500);
    logList.add(e4);
    LogEntry e5 = makeTestLogEntry('bar2', args0, 5000, 'a');
    logList.add(e5);
    LogEntry e6 = makeTestLogEntry('bar2', args1, 6000, 'b');
    logList.add(e6);
    LogEntry e7 = makeTestLogEntry('foo', args0, 7000);
    logList.add(e7);
    LogEntry e8 = makeTestLogEntry('bar3', args0, 8000, 'a');
    logList.add(e8);
    LogEntry e9 = makeTestLogEntry('bar3', args1, 9000, 'b');
    logList.add(e9);
    LogEntry e10 = makeTestLogEntry('foo', args0, 10000);
    logList.add(e10);

    LogEntryList keyList = new LogEntryList('keys');

    // Test with empty key list.

    LogEntryList result;
    result = logList.preceding(keyList);
    expect(result.logs, hasLength(0));

    result = logList.preceding(keyList, includeKeys:true);
    expect(result.logs, hasLength(0));

    // Single key, distance 1, no restrictions.

    keyList.add(e3);
    result = logList.preceding(keyList);
    expect(result.logs, orderedEquals([e2]));

    result = logList.following(keyList);
    expect(result.logs, orderedEquals([e4]));

    // Single key, distance 2, no restrictions.

    result = logList.preceding(keyList, distance:2);
    expect(result.logs, orderedEquals([e1, e2]));

    result = logList.following(keyList, distance:2);
    expect(result.logs, orderedEquals([e4, e5]));

    // Single key, distance 3, no restrictions.

    result = logList.preceding(keyList, distance:3);
    expect(result.logs, orderedEquals([e0, e1, e2]));

    result = logList.following(keyList, distance:3);
    expect(result.logs, orderedEquals([e4, e5, e6]));

    // Include keys in result

    result = logList.preceding(keyList, distance:3, includeKeys:true);
    expect(result.logs, orderedEquals([e0, e1, e2, e3]));

    result = logList.following(keyList, distance:3, includeKeys:true);
    expect(result.logs, orderedEquals([e3, e4, e5, e6]));

    // Restrict the matches

    result = logList.preceding(keyList, logFilter:callsTo(startsWith('bar')),
      distance:3);
    expect(result.logs, orderedEquals([e1, e2]));

    result = logList.preceding(keyList, logFilter:callsTo(startsWith('bar')),
        distance:3, includeKeys:true);
    expect(result.logs, orderedEquals([e1, e2, e3]));

    result = logList.preceding(keyList, mockNameFilter: equals('a'),
        logFilter: callsTo(startsWith('bar')), distance:3);
    expect(result.logs, orderedEquals([e1]));

    result = logList.preceding(keyList, mockNameFilter: equals('a'),
        logFilter: callsTo(startsWith('bar')), distance:3, includeKeys:true);
    expect(result.logs, orderedEquals([e1, e3]));

    keyList.logs.clear();
    keyList.add(e0);
    keyList.add(e3);
    keyList.add(e7);

    result = logList.preceding(keyList);
    expect(result.logs, orderedEquals([e2, e6]));

    result = logList.following(keyList);
    expect(result.logs, orderedEquals([e1, e4, e8]));

    result = logList.preceding(keyList, includeKeys:true);
    expect(result.logs, orderedEquals([e0, e2, e3, e6, e7]));

    result = logList.following(keyList, includeKeys:true);
    expect(result.logs, orderedEquals([e0, e1, e3, e4, e7, e8]));

    keyList.logs.clear();
    keyList.add(e3);
    keyList.add(e7);
    keyList.add(e10);

    result = logList.preceding(keyList);
    expect(result.logs, orderedEquals([e2, e6, e9]));

    result = logList.following(keyList);
    expect(result.logs, orderedEquals([e4, e8]));

    result = logList.preceding(keyList, includeKeys:true);
    expect(result.logs, orderedEquals([e2, e3, e6, e7, e9, e10]));

    result = logList.following(keyList, includeKeys:true);
    expect(result.logs, orderedEquals([e3, e4, e7, e8, e10]));

    keyList.logs.clear();
    keyList.add(e0);
    keyList.add(e3);
    keyList.add(e7);
    keyList.add(e10);

    result = logList.preceding(keyList);
    expect(result.logs, orderedEquals([e2, e6, e9]));

    result = logList.following(keyList);
    expect(result.logs, orderedEquals([e1, e4, e8]));

    result = logList.preceding(keyList, includeKeys:true);
    expect(result.logs, orderedEquals([e0, e2, e3, e6, e7, e9, e10]));

    result = logList.following(keyList, includeKeys:true);
    expect(result.logs, orderedEquals([e0, e1, e3, e4, e7, e8, e10]));

    keyList.logs.clear();
    keyList.add(e0);
    keyList.add(e3);
    keyList.add(e7);

    result = logList.preceding(keyList, distance:3);
    expect(result.logs, orderedEquals([e1, e2, e4, e5, e6]));

    result = logList.following(keyList, distance:3);
    expect(result.logs, orderedEquals([e1, e2, e4, e5, e6, e8, e9, e10]));

    result = logList.preceding(keyList, distance:3, includeKeys:true);
    expect(result.logs, orderedEquals([e0, e1, e2, e3, e4, e5, e6, e7]));

    result = logList.following(keyList, distance:3, includeKeys:true);
    expect(result.logs, orderedEquals([e0, e1, e2, e3, e4, e5, e6,
                                       e7, e8, e9, e10]));

    keyList.logs.clear();
    keyList.add(e3);
    keyList.add(e7);
    keyList.add(e10);

    result = logList.preceding(keyList, distance:3);
    expect(result.logs, orderedEquals([e0, e1, e2, e4, e5, e6, e8, e9]));

    result = logList.following(keyList, distance:3);
    expect(result.logs, orderedEquals([e4, e5, e6, e8, e9]));

    result = logList.preceding(keyList, distance:3, includeKeys:true);
    expect(result.logs, orderedEquals([e0, e1, e2, e3, e4, e5, e6,
                                       e7, e8, e9, e10]));

    result = logList.following(keyList, distance:3, includeKeys:true);
    expect(result.logs, orderedEquals([e3, e4, e5, e6, e7, e8, e9, e10]));

    keyList.logs.clear();
    keyList.add(e0);
    keyList.add(e3);
    keyList.add(e7);
    keyList.add(e10);

    result = logList.preceding(keyList, distance:3);
    expect(result.logs, orderedEquals([e1, e2, e4, e5, e6, e8, e9]));

    result = logList.following(keyList, distance:3);
    expect(result.logs, orderedEquals([e1, e2, e4, e5, e6, e8, e9]));

    result = logList.preceding(keyList, distance:3, includeKeys:true);
    expect(result.logs, orderedEquals([e0, e1, e2, e3, e4, e5, e6,
                                       e7, e8, e9, e10]));

    result = logList.following(keyList, distance:3, includeKeys:true);
    expect(result.logs, orderedEquals([e0, e1, e2, e3, e4, e5, e6,
                                       e7, e8, e9, e10]));
  });

  test('Mocking: stepwiseValidate', () {
    LogEntryList logList = new LogEntryList('test');
    for (var i = 0; i < 10; i++) {
      LogEntry e = new LogEntry(null, 'foo', [i], Action.IGNORE);
      logList.add(e);
    }
    int total = 0;
    logList.stepwiseValidate((log, pos) {
        total += log[pos].args[0] * log[pos + 1].args[0];
        expect(log[pos + 1].args[0] - log[pos].args[0], equals(1));
        return 2;
    });
    expect(total, equals((0 * 1) + (2 * 3) + (4 * 5) + (6 * 7) + (8 * 9))); 
  });

  test('Mocking: clearLogs', () {
    var m = new Mock();
    m.foo();
    m.foo();
    m.foo();
    expect(m.log.logs, hasLength(3));
    m.clearLogs();
    expect(m.log.logs, hasLength(0));
    LogEntryList log = new LogEntryList();
    var m1 = new Mock.custom(name: 'm1', log: log);
    var m2 = new Mock.custom(name: 'm2', log: log);
    var m3 = new Mock.custom(name: 'm3', log: log);
    for (var i = 0; i < 3; i++) {
      m1.foo();
      m2.bar();
      m3.pow();
    }
    expect(log.logs, hasLength(9));
    m1.clearLogs();
    expect(log.logs, hasLength(6));
    m1.clearLogs();
    expect(log.logs, hasLength(6));
    expect(log.logs.every((e) => e.mockName == 'm2' || e.mockName == 'm3'),
        isTrue);
    m2.clearLogs();
    expect(log.logs, hasLength(3));
    expect(log.logs.every((e) => e.mockName =='m3'), isTrue);
    m3.clearLogs();
    expect(log.logs, hasLength(0));
  });
}
