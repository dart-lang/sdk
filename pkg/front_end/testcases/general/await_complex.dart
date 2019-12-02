// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test was adapted from language_2/await_test

import 'dart:async';

int globalVariable = 1;
int topLevelFoo(int param) => 1;
int get topLevelGetter => globalVariable;
void set topLevelSetter(val) {
  globalVariable = val;
}

class C {
  static int staticField = 1;
  static int get staticGetter => staticField;
  static void set staticSetter(val) {
    staticField = val;
  }

  static int staticFoo(int param) => param;

  int field = 1;
  int get getter => field;
  void set setter(val) {
    field = val;
  }

  int foo(int param) => param;
}

dummy() => 1;

staticMembers() async {
  var a = C.staticField + await dummy();
  expect(2, a);
  var f = (C.staticField = 1) + await dummy();
  expect(2, f);
  var b = C.staticGetter + await dummy();
  expect(2, b);
  var c = (C.staticSetter = 1) + await dummy();
  expect(2, c);
  var d = C.staticFoo(2) + await dummy();
  expect(3, d);
  var e = C.staticField +
      C.staticGetter +
      (C.staticSetter = 1) +
      C.staticFoo(1) +
      await dummy();
  expect(5, e);
}

topLevelMembers() async {
  var a = globalVariable + await dummy();
  expect(2, a);
  var b = topLevelGetter + await dummy();
  expect(2, b);
  var c = (topLevelSetter = 1) + await dummy();
  expect(2, c);
  var d = topLevelFoo(1) + await dummy();
  expect(2, d);
  var e = globalVariable +
      topLevelGetter +
      (topLevelSetter = 1) +
      topLevelFoo(1) +
      await dummy();
  expect(5, e);
}

instanceMembers() async {
  var inst = new C();
  var a = inst.field + await dummy();
  expect(2, a);
  var b = inst.getter + await dummy();
  expect(2, b);
  var c = (inst.setter = 1) + await dummy();
  expect(2, c);
  var d = inst.foo(1) + await dummy();
  expect(2, d);
  var e = inst.field +
      inst.getter +
      (inst.setter = 1) +
      inst.foo(1) +
      await dummy();
  expect(5, e);
}

others() async {
  var a = "${globalVariable} ${await dummy()} " + await "someString";
  expect("1 1 someString", a);
  var c = new C();
  var d = c.field + await dummy();
  var cnt = 2;
  var b = [1, 2, 3];
  b[cnt] = await dummy();
  expect(1, b[cnt]);
  var e = b[0] + await dummy();
  expect(2, e);
}

conditionals() async {
  var a = false;
  var b = true;
  var c = (a || b) || await dummy();
  expect(true, c);
  var d = (a || b) ? a : await dummy();
  expect(false, d);
  var e = (a is int) ? await dummy() : 2;
  expect(2, e);
  try {
    var f = (a is int) ? await dummy() : 2;
  } catch (e) {}
}

asserts() async {
  for (final FutureOr<T> Function<T>(T) func in <Function>[id, future]) {
    assert(await func(true));
    assert(id(true), await func("message"));
    assert(await func(true), await (func("message")));
    try {
      assert(await func(false), await (func("message")));
      if (assertStatementsEnabled) throw "Didn't throw";
    } on AssertionError catch (e) {
      expect("message", e.message);
    }
  }
}

controlFlow() async {
  for (final FutureOr<T> Function<T>(T) func in <Function>[id, future]) {
    // For.
    var c = 0;
    for (var i = await (func(0)); await func(i < 5); await func(i++)) {
      c++;
    }
    expect(5, c);
    // While.
    c = 0;
    while (await func(c < 5)) c++;
    expect(5, c);
    // Do-while.
    c = 0;
    do {
      c++;
    } while (await func(c < 5));
    expect(5, c);
    // If.
    if (await func(c == 5)) {
      expect(5, c);
    } else {
      throw "unreachable";
    }
    // Throw.
    try {
      throw await func("string");
    } on String {
      // OK.
    }

    try {
      await (throw "string");
    } on String {
      // OK.
    }
    // Try/catch/finally
    try {
      try {
        throw "string";
      } catch (e) {
        expect("string", e);
        expect(0, await func(0));
        rethrow;
      } finally {
        expect(0, await func(0));
      }
    } catch (e) {
      expect(0, await func(0));
      expect("string", e);
    } finally {
      expect(0, await func(0));
    }
    // Switch
    switch (await func(2)) {
      case 2:
        break;
      default:
        throw "unreachable";
    }
    // Return.
    expect(
        42,
        await () async {
          return await func(42);
        }());
    expect(
        42,
        await () async {
          return func(42);
        }());
    // Yield.
    Stream<int> testStream1() async* {
      yield await func(42);
    }

    expectList([42], await testStream1().toList());
    // Yield*
    Stream<int> testStream2() async* {
      yield* await func(intStream());
    }

    expectList([42], await testStream2().toList());
  }
}

FutureOr<T> future<T>(T value) async => value;
FutureOr<T> id<T>(T value) => value;

Stream<int> intStream() async* {
  yield 42;
}

final bool assertStatementsEnabled = () {
  try {
    assert(false);
    return false;
  } catch (_) {
    return true;
  }
}();

main() async {
  for (int i = 0; i < 11; i++) {
    await staticMembers();
    await topLevelMembers();
    await instanceMembers();
    await conditionals();
    await others();
    await asserts();
    await controlFlow();
  }
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

expectList(List expected, List actual) {
  if (expected.length != actual.length) {
    throw 'Expected $expected, actual $actual';
  }
  for (int i = 0; i < expected.length; i++) {
    expect(expected[i], actual[i]);
  }
}
