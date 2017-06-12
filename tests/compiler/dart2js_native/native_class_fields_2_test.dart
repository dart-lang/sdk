// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Verify that methods are not renamed to clash with native field names
// that are known from the DOM (like x, y, z).
@Native("A")
class A {
  int x;
  int y;
  int z;
  int gettersCalled;
}

void setup() native r"""
function getter() {
  this.gettersCalled++;
  return 42;
}

function A(){
  var a = Object.create(
      { constructor: A },
      { x: { get: getter, configurable: false, writeable: false },
        y: { get: getter, configurable: false, writeable: false },
        z: { get: getter, configurable: false, writeable: false }
      });
  a.gettersCalled = 0;
  return a;
}

makeA = function() { return new A; };
self.nativeConstructor(A);
""";

A makeA() native;

class B {
  void a() {}
  void a0() {}
  void a1() {}
  void a2() {}
  void a3() {}
  void a4() {}
  void a5() {}
  void a6() {}
  void a7() {}
  void a8() {}
  void a9() {}
  void a10() {}
  void a11() {}
  void a12() {}
  void a13() {}
  void a14() {}
  void a15() {}
  void a16() {}
  void a17() {}
  void a18() {}
  void a19() {}
  void a20() {}
  void a21() {}
  void a22() {}
  void a23() {}
  void a24() {}
  void a25() {}
  void a26() {}
  int z = 0;
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  nativeTesting();
  setup();
  confuse(new B()).a();
  var x = confuse(makeA());
  // Each of these will throw, because an instance of A doesn't have any of
  // these functions.  The important thing is that none of them have been
  // renamed to be called 'z' by the minifier, because then the getter will be
  // hit.
  try {
    x.a();
  } catch (e) {}
  try {
    x.a0();
  } catch (e) {}
  try {
    x.a1();
  } catch (e) {}
  try {
    x.a2();
  } catch (e) {}
  try {
    x.a3();
  } catch (e) {}
  try {
    x.a4();
  } catch (e) {}
  try {
    x.a5();
  } catch (e) {}
  try {
    x.a6();
  } catch (e) {}
  try {
    x.a7();
  } catch (e) {}
  try {
    x.a8();
  } catch (e) {}
  try {
    x.a9();
  } catch (e) {}
  try {
    x.a10();
  } catch (e) {}
  try {
    x.a11();
  } catch (e) {}
  try {
    x.a12();
  } catch (e) {}
  try {
    x.a13();
  } catch (e) {}
  try {
    x.a14();
  } catch (e) {}
  try {
    x.a15();
  } catch (e) {}
  try {
    x.a16();
  } catch (e) {}
  try {
    x.a17();
  } catch (e) {}
  try {
    x.a18();
  } catch (e) {}
  try {
    x.a19();
  } catch (e) {}
  try {
    x.a20();
  } catch (e) {}
  try {
    x.a21();
  } catch (e) {}
  try {
    x.a12();
  } catch (e) {}
  try {
    x.a23();
  } catch (e) {}
  try {
    x.a24();
  } catch (e) {}
  try {
    x.a25();
  } catch (e) {}
  try {
    x.a26();
  } catch (e) {}
  Expect.equals(0, x.gettersCalled);
  Expect.equals(42, x.z);
  Expect.equals(1, x.gettersCalled);
}
