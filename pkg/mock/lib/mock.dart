// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple mocking/spy library.
 *
 * To create a mock objects for some class T, create a new class using:
 *
 *     class MockT extends Mock implements T {};
 *
 * Then specify the [Behavior] of the Mock for different methods using
 * [when] (to select the method and parameters) and then the [Action]s
 * for the [Behavior] by calling [thenReturn], [alwaysReturn], [thenThrow],
 * [alwaysThrow], [thenCall] or [alwaysCall].
 *
 * [thenReturn], [thenThrow] and [thenCall] are one-shot so you would
 * typically call these more than once to specify a sequence of actions;
 * this can be done with chained calls, e.g.:
 *
 *      m.when(callsTo('foo')).
 *          thenReturn(0).thenReturn(1).thenReturn(2);
 *
 * [thenCall] and [alwaysCall] allow you to proxy mocked methods, chaining
 * to some other implementation. This provides a way to implement 'spies'.
 *
 * For getters and setters, use "get foo" and "set foo"-style arguments
 * to [callsTo].
 *
 * You can disable logging for a particular [Behavior] easily:
 *
 *     m.when(callsTo('bar')).logging = false;
 *
 * You can then use the mock object. Once you are done, to verify the
 * behavior, use [getLogs] to extract a relevant subset of method call
 * logs and apply [Matchers] to these through calling [verify].
 *
 * A Mock can be given a name when constructed. In this case instead of
 * keeping its own log, it uses a shared log. This can be useful to get an
 * audit trail of interleaved behavior. It is the responsibility of the user
 * to ensure that mock names, if used, are unique.
 *
 * Limitations:
 *
 * * only positional parameters are supported (up to 10);
 * * to mock getters you will need to include parentheses in the call
 *       (e.g. m.length() will work but not m.length).
 *
 * Here is a simple example:
 *
 *     class MockList extends Mock implements List {};
 *
 *     List m = new MockList();
 *     m.when(callsTo('add', anything)).alwaysReturn(0);
 *
 *     m.add('foo');
 *     m.add('bar');
 *
 *     getLogs(m, callsTo('add', anything)).verify(happenedExactly(2));
 *     getLogs(m, callsTo('add', 'foo')).verify(happenedOnce);
 *     getLogs(m, callsTo('add', 'isNull)).verify(neverHappened);
 *
 * Note that we don't need to provide argument matchers for all arguments,
 * but we do need to provide arguments for all matchers. So this is allowed:
 *
 *     m.when(callsTo('add')).alwaysReturn(0);
 *     m.add(1, 2);
 *
 * But this is not allowed and will throw an exception:
 *
 *     m.when(callsTo('add', anything, anything)).alwaysReturn(0);
 *     m.add(1);
 *
 * Here is a way to implement a 'spy', which is where we log the call
 * but then hand it off to some other function, which is the same
 * method in a real instance of the class being mocked:
 *
 *     class Foo {
 *       bar(a, b, c) => a + b + c;
 *     }
 *
 *     class MockFoo extends Mock implements Foo {
 *       Foo real;
 *       MockFoo() {
 *         real = new Foo();
 *         this.when(callsTo('bar')).alwaysCall(real.bar);
 *       }
 *     }
 *
 * However, there is an even easier way, by calling [Mock.spy], e.g.:
 *
 *      var foo = new Foo();
 *      var spy = new Mock.spy(foo);
 *      print(spy.bar(1, 2, 3));
 *
 * Spys created with Mock.spy do not have user-defined behavior;
 * they are simply proxies,  and thus will throw an exception if
 * you call [when]. They capture all calls in the log, so you can
 * do assertions on their history, such as:
 *
 *       spy.getLogs(callsTo('bar')).verify(happenedOnce);
 *
 * [pub]: http://pub.dartlang.org
 */

library mock;

export 'src/action.dart';
export 'src/behavior.dart';
export 'src/call_matcher.dart';
export 'src/log_entry.dart';
export 'src/log_entry_list.dart';
export 'src/mock.dart';
export 'src/responder.dart';
export 'src/result_matcher.dart';
export 'src/result_set_matcher.dart';
export 'src/times_matcher.dart';
