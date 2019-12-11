// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ??= operator, including order of operations, by
// keeping track of the operations performed.

import "package:expect/expect.dart";
import "assignment_helper.dart" as h;

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
    vGetValue = 1; check(1, () => super.v ??= bad(), ['$s.v']);

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











  // C.v ??= e is equivalent to ((x) => x == null ? C.v = e : x)(C.v)





  // e1.v ??= e2 is equivalent to
  // ((x) => ((y) => y == null ? x.v = e2 : y)(x.v))(e1)









  // e1[e2] ??= e3 is equivalent to
  // ((a, i) => ((x) => x == null ? a[i] = e3 : x)(a[i]))(e1, e2)





  // e1?.v ??= e2 is equivalent to ((x) => x == null ? null : x.v ??= e2)(e1).






  // C?.v ??= e2 is equivalent to C.v ??= e2.








}
