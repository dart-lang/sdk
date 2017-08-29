// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ??= operator, including order of operations, by
// keeping track of the operations performed.

import "package:expect/expect.dart";
import "if_null_assignment_helper.dart" as h;

bad() {
  Expect.fail('Should not be executed');
}

var xGetValue = null;

get x {
  h.operations.add('x');
  var tmp = xGetValue;
  xGetValue = null;
  return tmp;
}

void set x(value) {
  h.operations.add('x=$value');
}

var yGetValue = null;

get y {
  h.operations.add('y');
  var tmp = yGetValue;
  yGetValue = null;
  return tmp;
}

void set y(value) {
  h.operations.add('y=$value');
}

var zGetValue = null;

get z {
  h.operations.add('z');
  var tmp = zGetValue;
  zGetValue = null;
  return tmp;
}

void set z(value) {
  h.operations.add('z=$value');
}

var fValue = null;

f() {
  h.operations.add('f()');
  var tmp = fValue;
  fValue = null;
  return tmp;
}

void check(expectedValue, f(), expectedOperations) {
  Expect.equals(expectedValue, f());
  Expect.listEquals(expectedOperations, h.operations);
  h.operations = [];
}

void checkThrows(expectedException, f(), expectedOperations) {
  Expect.throws(f, expectedException);
  Expect.listEquals(expectedOperations, h.operations);
  h.operations = [];
}

noMethod(e) => e is NoSuchMethodError;

class C {
  final String s;

  C(this.s);

  @override
  String toString() => s;

  static var xGetValue = null;

  static get x {
    h.operations.add('C.x');
    var tmp = xGetValue;
    xGetValue = null;
    return tmp;
  }

  static void set x(value) {
    h.operations.add('C.x=$value');
  }

  var vGetValue = null;

  get v {
    h.operations.add('$s.v');
    var tmp = vGetValue;
    vGetValue = null;
    return tmp;
  }

  void set v(value) {
    h.operations.add('$s.v=$value');
  }

  var indexGetValue = null;

  operator [](index) {
    h.operations.add('$s[$index]');
    var tmp = indexGetValue;
    indexGetValue = null;
    return tmp;
  }

  void operator []=(index, value) {
    h.operations.add('$s[$index]=$value');
  }

  final finalOne = 1;
  final finalNull = null;

  void instanceTest() {
    // v ??= e is equivalent to ((x) => x == null ? v = e : x)(v)
    vGetValue = 1; check(1, () => v ??= bad(), ['$s.v']); //# 01: ok
    yGetValue = 1; check(1, () => v ??= y, ['$s.v', 'y', '$s.v=1']); //# 02: ok
    finalOne ??= null; //# 03: compile-time error
    yGetValue = 1;
  }
}

class D extends C {
  D(String s) : super(s);

  get v => bad();

  void set v(value) {
    bad();
  }

  void derivedInstanceTest() {
    // super.v ??= e is equivalent to
    // ((x) => x == null ? super.v = e : x)(super.v)
    vGetValue = 1; check(1, () => super.v ??= bad(), ['$s.v']); //# 05: ok
    yGetValue = 1; check(1, () => super.v ??= y, ['$s.v', 'y', '$s.v=1']); //# 06: ok
  }
}

main() {
  // Make sure the "none" test fails if "??=" is not implemented.  This makes
  // status files easier to maintain.
  var _;
  _ ??= null;

  new C('c').instanceTest();
  new D('d').derivedInstanceTest();

  // v ??= e is equivalent to ((x) => x == null ? v = e : x)(v)
  xGetValue = 1; check(1, () => x ??= bad(), ['x']); //# 07: ok
  yGetValue = 1; check(1, () => x ??= y, ['x', 'y', 'x=1']); //# 08: ok
  h.xGetValue = 1; check(1, () => h.x ??= bad(), ['h.x']); //# 09: ok
  yGetValue = 1; check(1, () => h.x ??= y, ['h.x', 'y', 'h.x=1']); //# 10: ok
  { var l = 1; check(1, () => l ??= bad(), []); } //# 11: ok
  { var l; yGetValue = 1; check(1, () => l ??= y, ['y']); Expect.equals(1, l); } //# 12: ok
  { final l = 1; l ??= null; } //# 13: compile-time error
  C ??= null; //# 15: compile-time error
  h ??= null; //# 29: compile-time error
  h[0] ??= null; //# 30: compile-time error

  // C.v ??= e is equivalent to ((x) => x == null ? C.v = e : x)(C.v)
  C.xGetValue = 1; check(1, () => C.x ??= bad(), ['C.x']); //# 16: ok
  yGetValue = 1; check(1, () => C.x ??= y, ['C.x', 'y', 'C.x=1']); //# 17: ok
  h.C.xGetValue = 1; check(1, () => h.C.x ??= bad(), ['h.C.x']); //# 18: ok
  yGetValue = 1; check(1, () => h.C.x ??= y, ['h.C.x', 'y', 'h.C.x=1']); //# 19: ok

  // e1.v ??= e2 is equivalent to
  // ((x) => ((y) => y == null ? x.v = e2 : y)(x.v))(e1)
  xGetValue = new C('x'); xGetValue.vGetValue = 1; //# 20: ok
  check(1, () => x.v ??= bad(), ['x', 'x.v']); //    //# 20: continued
  xGetValue = new C('x'); yGetValue = 1; //               //# 21: ok
  check(1, () => x.v ??= y, ['x', 'x.v', 'y', 'x.v=1']); //# 21: continued
  fValue = new C('f()'); fValue.vGetValue = 1; //      //# 22: ok
  check(1, () => f().v ??= bad(), ['f()', 'f().v']); //# 22: continued
  fValue = new C('f()'); yGetValue = 1; //                         //# 23: ok
  check(1, () => f().v ??= y, ['f()', 'f().v', 'y', 'f().v=1']); //# 23: continued

  // e1[e2] ??= e3 is equivalent to
  // ((a, i) => ((x) => x == null ? a[i] = e3 : x)(a[i]))(e1, e2)
  xGetValue = new C('x'); yGetValue = 1; xGetValue.indexGetValue = 2; //# 24: ok
  check(2, () => x[y] ??= bad(), ['x', 'y', 'x[1]']); //                //# 24: continued
  xGetValue = new C('x'); yGetValue = 1; zGetValue = 2; //         //# 25: ok
  check(2, () => x[y] ??= z, ['x', 'y', 'x[1]', 'z', 'x[1]=2']); //# 25: continued

  // e1?.v ??= e2 is equivalent to ((x) => x == null ? null : x.v ??= e2)(e1).
  check(null, () => x?.v ??= bad(), ['x']); //# 26: ok
  xGetValue = new C('x'); xGetValue.vGetValue = 1; //# 27: ok
  check(1, () => x?.v ??= bad(), ['x', 'x.v']); //    //# 27: continued
  xGetValue = new C('x'); yGetValue = 1; //                //# 28: ok
  check(1, () => x?.v ??= y, ['x', 'x.v', 'y', 'x.v=1']); //# 28: continued

  // C?.v ??= e2 is equivalent to C.v ??= e2.
  C.xGetValue = 1; //                        //# 29: ok
  check(1, () => C?.x ??= bad(), ['C.x']); //# 29: continued
  h.C.xgetValue = 1; //                          //# 30: ok
  check(1, () => h.c?.x ??= bad(), ['h.C.x']); //# 30: continued
  yGetValue = 1; //                                    //# 31: ok
  check(1, () => C?.x ??= y, ['C.x', 'y', 'C.x=1']); //# 31: continued
  yGetValue = 1; //                                          //# 32: ok
  check(1, () => h.C?.x ??= y, ['h.C.x', 'y', 'h.C.x=1']); //# 32: continued
}
