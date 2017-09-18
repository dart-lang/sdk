// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'causal_async_exception_stack_helper.dart' as h;

foo3() async => throw "foo";
bar3() async => throw "bar";

foo2() async => foo3();
bar2() async => bar3();

foo() async => foo2();
bar() async => bar2();

test1() async {
  // test1 -> foo -> foo2 -> foo3
  // test1 -> bar -> bar2 -> bar3
  // These run interleaved, check their stack traces don't become mixed.
  var a = foo();
  var b = bar();

  try {
    await a;
  } catch (e, st) {
    // st has foo,2,3 and not bar,2,3.
    expect(
        h.stringContainsInOrder(st.toString(), [
          'foo3',
          '<asynchronous suspension>',
          'foo2',
          '<asynchronous suspension>',
          'foo',
          '<asynchronous suspension>',
          'test1',
        ]),
        isTrue);
    expect(st.toString().contains('bar'), isFalse);
  }

  try {
    await b;
  } catch (e, st) {
    // st has bar,2,3 but not foo,2,3
    expect(
        h.stringContainsInOrder(st.toString(), [
          'bar3',
          '<asynchronous suspension>',
          'bar2',
          '<asynchronous suspension>',
          'bar',
          '<asynchronous suspension>',
          'test1',
        ]),
        isTrue);
    expect(st.toString().contains('foo'), isFalse);
  }
}

test2() async {
  // test2 -> foo -> foo2 -> foo3
  // test2 -> bar -> bar2 -> bar3
  // These run sequentially, check the former stack trace didn't get linked to
  // from the latter stack trace.

  try {
    await foo();
  } catch (e, st) {
    // st has foo,2,3 but not bar,2,3
    expect(
        h.stringContainsInOrder(st.toString(), [
          'foo3',
          '<asynchronous suspension>',
          'foo2',
          '<asynchronous suspension>',
          'foo',
          '<asynchronous suspension>',
          'test2',
        ]),
        isTrue);
    expect(st.toString().contains('bar'), isFalse);
  }

  try {
    await bar();
  } catch (e, st) {
    // st has bar,2,3 but not foo,2,3
    expect(
        h.stringContainsInOrder(st.toString(), [
          'bar3',
          '<asynchronous suspension>',
          'bar2',
          '<asynchronous suspension>',
          'bar',
          '<asynchronous suspension>',
          'test2',
        ]),
        isTrue);
    expect(st.toString().contains('foo'), isFalse);
  }
}

main() async {
  test('causal async exception stack', () async {
    await test1();
    await test2();
  });
}
