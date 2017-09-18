// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=---optimization-counter-threshold=10

import 'package:expect/expect.dart';

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

await() => 4;
nonAsyncFunction() => await();

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
  Expect.equals(nonAsyncFunction(), 4);
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

main() {
  for (int i = 0; i < 10; i++) {
    staticMembers();
    topLevelMembers();
    instanceMembers();
    conditionals();
    others();
  }
}
