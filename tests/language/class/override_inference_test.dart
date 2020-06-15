// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that inheriting types on overriding members work as specified.

// ignore_for_file: unused_local_variable

import "package:expect/expect.dart";

// Helper variables.
int intVar = 0;
List<int> listIntVar = <int>[];
int? intQVar;
List<int?> listIntQVar = <int?>[];
num numVar = 0;
List<num> listNumVar = <num>[];

/// Override can work with incompatible superinterfaces,
/// as long as override is more specific than all of them,
/// and it specifies all types.
class IIntOpts {
  int foo(int x, {int v = 0, required int z}) => x;
}

class IDoubleOpts {
  double foo(double x, {double w = 0.0, int z = 1}) => x;
}

class CNumOpts implements IIntOpts, IDoubleOpts {
  // Override is more specific than all supertype members.
  Never foo(num x, {int v = 0, double w = 0.0, int z = 1}) => throw "Never";
}

// When a type is omitted, the most specific immediate superinterface member
// signature is used. One such must exist.

class IIntInt {
  int foo(int x) => x;
}

class INumInt {
  int foo(num x) => x.toInt();
}

class IIntNum {
  num foo(int x) => x.toInt();
}

class IInt {
  void foo(int x) {}
}

class IIntQ {
  void foo(int? x) {}
}

class IOpt1 {
  void foo([int x = 0]) {}
}

class IOpt2 {
  void foo([int x = 0, int y = 0]) {}
}

class IOptX {
  void foo({int x = 0}) {}
}

class IOptXY {
  void foo({int x = 0, int y = 0}) {}
}

abstract class IOptA1 {
  void foo([int x]);
}

abstract class IOptAX {
  void foo({int x});
}

class IReq {
  void foo({required int x}) {}
}

// Type is inherited as long as no other type is written.
// Even if prefixed by `var`, `final`, `required` or `covariant`,
// or if made optional with or without a default value.
class CVar implements IIntInt {
  foo(var x) {
    // Checks that x is exactly int.
    // It is assignable in both directions, and it's not dynamic.
    intVar = x;
    x = intVar;
    var xList = [x];
    listIntVar = xList;
    return intVar;
  }
}

class CFinal implements IInt {
  foo(final x) {
    var sameTypeAsX = x;
    intVar = x;
    sameTypeAsX = intVar;
    var xList = [x];
    listIntVar = xList;
  }
}

class COptDefault implements IInt {
  foo([x = 0]) {
    intVar = x;
    x = intVar;
    var xList = [x];
    listIntVar = xList;
  }
}

// Must use the nullable type when not having a default.
class COptNoDefault implements IIntQ {
  foo([x]) {
    int? tmp = x;
    x = tmp;
    var xList = [x];
    listIntQVar = xList;
  }
}

class CReq implements IReq {
  foo({required x}) {
    intVar = x;
    x = intVar;
    var xList = [x];
    listIntQVar = xList;
  }
}

// Do inherit when specifying `covariant`.
class CCovar implements IInt {
  foo(covariant x) {
    intVar = x;
    x = intVar;
    var xList = [x];
    listIntVar = xList;
  }
}

class CCovar2 implements CCovar {
  // Method was covariant in CCovar.
  foo(Never x) => 0;
}

/// A more specific `foo` than [IInt.foo].
/// Subclass inherits types from most specific superclass member.
class CInherit1 implements INumInt, IIntNum {
  foo(x) {
    // x is num.
    numVar = x;
    x = numVar;
    var xList = [x];
    listNumVar = xList;

    // return type is int.
    var ret = foo(x);
    intVar = ret;
    ret = intVar;
    var retList = [ret];
    listIntVar = retList;
    return 0;
  }
}

class CInherit2 extends INumInt implements IIntNum {
  foo(x) {
    numVar = x;
    x = numVar;
    var xList = [x];
    listNumVar = xList;

    var ret = foo(x);
    intVar = ret;
    ret = intVar;
    var retList = [ret];
    listIntVar = retList;
    return 0;
  }
}

class CInherit3 extends IIntNum implements INumInt {
  foo(x) {
    numVar = x;
    x = numVar;
    var xList = [x];
    listNumVar = xList;

    var ret = foo(x);
    intVar = ret;
    ret = intVar;
    var retList = [ret];
    listIntVar = retList;
    return intVar;
  }
}

class CInherit4 with IIntNum implements INumInt {
  foo(x) {
    numVar = x;
    x = numVar;
    var xList = [x];
    listNumVar = xList;

    var ret = foo(x);
    intVar = ret;
    ret = intVar;
    var retList = [ret];
    listIntVar = retList;
    return intVar;
  }
}

void testInheritFull() {
  Expect.type<int Function(num)>(CInherit1().foo);
  Expect.type<int Function(num)>(CInherit2().foo);
  Expect.type<int Function(num)>(CInherit3().foo);
  Expect.type<int Function(num)>(CInherit4().foo);
}

/// Works for optional parameters too.

class COptInherit1 implements IOpt1, IOpt2 {
  foo([x = 0, y = 0]) {
    intVar = x;
    x = intVar;
    var listX = [x];
    listIntVar = listX;

    intVar = y;
    y = intVar;
    var listY = [y];
    listIntVar = listY;
  }
}

class COptInherit2 implements IOptX, IOptXY {
  foo({x = 0, y = 0}) {
    intVar = x;
    x = intVar;
    var listX = [x];
    listIntVar = listX;

    intVar = y;
    y = intVar;
    var listY = [y];
    listIntVar = listY;
  }
}

class COptInherit3 implements IIntInt, INumInt {
  foo(x, [y]) {
    // Ensure that type is: int Function(num, [dynamic]) .
    // For static checks only, do not call the method!

    // x is exactly num.
    numVar = x;
    x = numVar;
    var listX = [x];
    listNumVar = listX;

    // y is dynamic.
    Object? tmpObject;
    y = tmpObject; // A top type.
    Null tmpNull = y; // Implicit downcast.
    y.arglebargle(); // Unsound member invocations.

    // return type is exactly int.
    var ret = foo(x, y);
    intVar = ret;
    ret = intVar;
    var retList = [ret];
    listIntVar = retList;
    return intVar;
  }
}

class COptInherit4 implements IOptA1 {
  foo([x = 1]) {
    intVar = x;
    x = intVar;
    var listX = [x];
    listIntVar = listX;
  }
}

class COptInherit5 implements IOptAX {
  foo({x = 1}) {
    intVar = x;
    x = intVar;
    var listX = [x];
    listIntVar = listX;
  }
}

void testInheritOpt() {
  Expect.type<void Function([int, int])>(COptInherit1().foo);
  Expect.type<void Function({int x, int y})>(COptInherit2().foo);
  Expect.type<int Function(num, [dynamic])>(COptInherit3().foo);
  Expect.type<void Function([int])>(COptInherit4().foo);
  Expect.type<void Function({int x})>(COptInherit5().foo);
}

// Do not inherit `final` with the type.
class IFinal {
  void foo(final int x) {}
}

class CInheritFinal implements IFinal {
  void foo(x) {
    x = 42;
    x.toRadixString(16);
  }
}

// Also applies to getters and setters.
class IGetSetInt {
  int get foo => 0;
  set foo(int _) {}
}

class IFieldInt {
  int foo = 0;
}

class ILateFieldInt {
  late int foo;
}

class IFinalFieldInt {
  final int foo = 0;
}

class CInheritGetSet implements IGetSetInt {
  get foo => throw "whatever";
  set foo(set) {
    // For static checking only, do not call.
    // `set` is assignable both ways to int.
    intVar = set;
    set = intVar;
    var listSet = [set];
    listIntVar = listSet;

    var get = foo;
    // get is assignable both ways to int.
    intVar = get;
    get = intVar;
    var listGet = [get];
    listIntVar = listGet;
  }
}

class CInheritField implements IFieldInt {
  get foo => throw "whatever";
  set foo(set) {
    // For static checking only, do not call.
    // `set` is assignable both ways to int.
    intVar = set;
    set = intVar;
    var listSet = [set];
    listIntVar = listSet;

    var get = foo;
    // get is assignable both ways to int.
    intVar = get;
    get = intVar;
    var listGet = [get];
    listIntVar = listGet;
  }
}

class CInheritLateField implements ILateFieldInt {
  get foo => throw "whatever";
  set foo(set) {
    // For static checking only, do not call.
    // `set` is assignable both ways to int.
    intVar = set;
    set = intVar;
    var listSet = [set];
    listIntVar = listSet;

    var get = foo;
    // get is assignable both ways to int.
    intVar = get;
    get = intVar;
    var listGet = [get];
    listIntVar = listGet;
  }
}

class CInheritFinalField implements IFinalFieldInt {
  get foo => throw "whatever";
  set foo(set) {
    // For static checking only, do not call.

    // `set` is assignable both ways to int.
    intVar = set;
    set = intVar;
    var listSet = [set];
    listIntVar = listSet;

    var get = foo; // Is int.
    // get is assignable both ways to int.
    intVar = get;
    get = intVar;
    var listGet = [get];
    listIntVar = listGet;
  }
}

class ISetterOnly {
  set foo(int value) {}
}

class IInheritSetter implements ISetterOnly {
  // Infers `int` as return type.
  get foo => throw "whatever";

  set foo(value) {
    int tmp = value;
    value = tmp;
    var valueList = [value];
    List<int> list = valueList;

    var get = foo;
    intVar = get;
    get = intVar;
    var getList = [get];
    list = getList;
  }
}

void main() {
  testInheritFull();
  testInheritOpt();
}
