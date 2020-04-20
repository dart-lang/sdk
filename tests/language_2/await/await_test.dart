// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=---optimization-counter-threshold=10

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

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
  Expect.equals(a, 2);
  var f = (C.staticField = 1) + await dummy();
  Expect.equals(f, 2);
  var b = C.staticGetter + await dummy();
  Expect.equals(b, 2);
  var c = (C.staticSetter = 1) + await dummy();
  Expect.equals(c, 2);
  var d = C.staticFoo(2) + await dummy();
  Expect.equals(d, 3);
  var e = C.staticField +
      C.staticGetter +
      (C.staticSetter = 1) +
      C.staticFoo(1) +
      await dummy();
  Expect.equals(e, 5);
}

topLevelMembers() async {
  var a = globalVariable + await dummy();
  Expect.equals(a, 2);
  var b = topLevelGetter + await dummy();
  Expect.equals(b, 2);
  var c = (topLevelSetter = 1) + await dummy();
  Expect.equals(c, 2);
  var d = topLevelFoo(1) + await dummy();
  Expect.equals(d, 2);
  var e = globalVariable +
      topLevelGetter +
      (topLevelSetter = 1) +
      topLevelFoo(1) +
      await dummy();
  Expect.equals(e, 5);
}

instanceMembers() async {
  var inst = new C();
  var a = inst.field + await dummy();
  Expect.equals(a, 2);
  var b = inst.getter + await dummy();
  Expect.equals(b, 2);
  var c = (inst.setter = 1) + await dummy();
  Expect.equals(c, 2);
  var d = inst.foo(1) + await dummy();
  Expect.equals(d, 2);
  var e = inst.field +
      inst.getter +
      (inst.setter = 1) +
      inst.foo(1) +
      await dummy();
  Expect.equals(e, 5);
}

others() async {
  var a = "${globalVariable} ${await dummy()} " + await "someString";
  Expect.equals(a, "1 1 someString");
  var c = new C();
  var d = c.field + await dummy();
  var cnt = 2;
  var b = [1, 2, 3];
  b[cnt] = await dummy();
  Expect.equals(b[cnt], 1);
  var e = b[0] + await dummy();
  Expect.equals(e, 2);
}

conditionals() async {
  var a = false;
  var b = true;
  var c = (a || b) || await dummy();
  Expect.isTrue(c);
  var d = (a || b) ? a : await dummy();
  Expect.isFalse(d);
  var e = (a is int) ? await dummy() : 2;
  Expect.equals(e, 2);
  try {
    var f = (a is int) ? await dummy() : 2;
  } catch (e) {}
}

asserts() async {
  for (final FutureOr<T> Function<T>(T) func in <Function>[id, future]) {
    assert(await func(true));
    assert(id(true), await func("message"));
    assert(await func(true), await (func("message")));
    bool success = true;
    try {
      assert(await func(false), await (func("message")));
      if (assertStatementsEnabled) Expect.fail("Didn't throw");
    } on AssertionError catch (e) {
      Expect.equals("message", e.message);
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
    Expect.equals(5, c);
    // While.
    c = 0;
    while (await func(c < 5)) c++;
    Expect.equals(5, c);
    // Do-while.
    c = 0;
    do {
      c++;
    } while (await func(c < 5));
    Expect.equals(5, c);
    // If.
    if (await func(c == 5)) {
      Expect.equals(5, c);
    } else {
      Expect.fail("unreachable");
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
        Expect.equals("string", e);
        Expect.equals(0, await func(0));
        rethrow;
      } finally {
        Expect.equals(0, await func(0));
      }
    } catch (e) {
      Expect.equals(0, await func(0));
      Expect.equals("string", e);
    } finally {
      Expect.equals(0, await func(0));
    }
    // Switch
    switch (await func(2)) {
      case 2:
        break;
      default:
        Expect.fail("unreachable");
    }
    // Return.
    Expect.equals(
        42,
        await () async {
          return await func(42);
        }());
    Expect.equals(
        42,
        await () async {
          return func(42);
        }());
    // Yield.
    Stream<int> testStream1() async* {
      yield await func(42);
    }

    Expect.listEquals([42], await testStream1().toList());
    // Yield*
    Stream<int> testStream2() async* {
      yield* await func(intStream());
    }

    Expect.listEquals([42], await testStream2().toList());
  }
}

FutureOr<T> future<T>(T value) async => value;
FutureOr<T> id<T>(T value) => value;

Stream<int> intStream() async* {
  yield 42;
}

main() {
  asyncStart();
  for (int i = 0; i < 11; i++) {
    asyncTest(staticMembers);
    asyncTest(topLevelMembers);
    asyncTest(instanceMembers);
    asyncTest(conditionals);
    asyncTest(others);
    asyncTest(asserts);
    asyncTest(controlFlow);
  }
  asyncEnd();
}
