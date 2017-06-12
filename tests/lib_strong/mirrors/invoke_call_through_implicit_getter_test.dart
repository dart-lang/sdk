// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_call_through_implicit_getter;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class FakeFunctionCall {
  call(x, y) => '1 $x $y';
}

class FakeFunctionNSM {
  noSuchMethod(msg) => msg.positionalArguments.join(', ');
}

class C {
  var fakeFunctionCall = new FakeFunctionCall();
  var fakeFunctionNSM = new FakeFunctionNSM();
  var closure; // = (x, y) => '2 $this $x $y';
  var closureOpt; // = (x, y, [z, w]) => '3 $this $x $y $z $w';
  var closureNamed; // = (x, y, {z, w}) => '4 $this $x $y $z $w';
  var notAClosure = 'Not a closure';
  noSuchMethod(msg) => 'DNU';

  C() {
    closure = (x, y) => '2 $this $x $y';
    closureOpt = (x, y, [z, w]) => '3 $this $x $y $z $w';
    closureNamed = (x, y, {z, w}) => '4 $this $x $y $z $w';
  }

  toString() => 'C';
}

testInstanceBase() {
  var c = new C();

  Expect.equals('1 5 6', c.fakeFunctionCall(5, 6));
  Expect.equals('7, 8', c.fakeFunctionNSM(7, 8));
  Expect.equals('2 C 9 10', c.closure(9, 10));
  Expect.equals('3 C 11 12 13 null', c.closureOpt(11, 12, 13));
  Expect.equals('4 C 14 15 null 16', c.closureNamed(14, 15, w: 16));
  Expect.equals('DNU', c.doesNotExist(17, 18));
  Expect.throws(() => c.closure('wrong arity'), (e) => e is NoSuchMethodError);
  Expect.throws(() => c.notAClosure(), (e) => e is NoSuchMethodError);
}

testInstanceReflective() {
  InstanceMirror im = reflect(new C());

  Expect.equals('1 5 6', im.invoke(#fakeFunctionCall, [5, 6]).reflectee);
  Expect.equals('7, 8', im.invoke(#fakeFunctionNSM, [7, 8]).reflectee);
  Expect.equals('2 C 9 10', im.invoke(#closure, [9, 10]).reflectee);
  Expect.equals(
      '3 C 11 12 13 null', im.invoke(#closureOpt, [11, 12, 13]).reflectee);
  Expect.equals('4 C 14 15 null 16',
      im.invoke(#closureNamed, [14, 15], {#w: 16}).reflectee);
  Expect.equals('DNU', im.invoke(#doesNotExist, [17, 18]).reflectee);
  Expect.throws(() => im.invoke(#closure, ['wrong arity']),
      (e) => e is NoSuchMethodError);
  Expect.throws(
      () => im.invoke(#notAClosure, []), (e) => e is NoSuchMethodError);
}

class D {
  static var fakeFunctionCall = new FakeFunctionCall();
  static var fakeFunctionNSM = new FakeFunctionNSM();
  static var closure = (x, y) => '2 $x $y';
  static var closureOpt = (x, y, [z, w]) => '3 $x $y $z $w';
  static var closureNamed = (x, y, {z, w}) => '4 $x $y $z $w';
  static var notAClosure = 'Not a closure';
}

testClassBase() {
  Expect.equals('1 5 6', D.fakeFunctionCall(5, 6));
  Expect.equals('7, 8', D.fakeFunctionNSM(7, 8));
  Expect.equals('2 9 10', D.closure(9, 10));
  Expect.equals('3 11 12 13 null', D.closureOpt(11, 12, 13));
  Expect.equals('4 14 15 null 16', D.closureNamed(14, 15, w: 16));
  Expect.throws(() => D.closure('wrong arity'), (e) => e is NoSuchMethodError);
}

testClassReflective() {
  ClassMirror cm = reflectClass(D);

  Expect.equals('1 5 6', cm.invoke(#fakeFunctionCall, [5, 6]).reflectee);
  Expect.equals('7, 8', cm.invoke(#fakeFunctionNSM, [7, 8]).reflectee);
  Expect.equals('2 9 10', cm.invoke(#closure, [9, 10]).reflectee);
  Expect.equals(
      '3 11 12 13 null', cm.invoke(#closureOpt, [11, 12, 13]).reflectee);
  Expect.equals('4 14 15 null 16',
      cm.invoke(#closureNamed, [14, 15], {#w: 16}).reflectee);
  Expect.throws(() => cm.invoke(#closure, ['wrong arity']),
      (e) => e is NoSuchMethodError);
}

var fakeFunctionCall = new FakeFunctionCall();
var fakeFunctionNSM = new FakeFunctionNSM();
var closure = (x, y) => '2 $x $y';
var closureOpt = (x, y, [z, w]) => '3 $x $y $z $w';
var closureNamed = (x, y, {z, w}) => '4 $x $y $z $w';
var notAClosure = 'Not a closure';

testLibraryBase() {
  Expect.equals('1 5 6', fakeFunctionCall(5, 6));
  Expect.equals('7, 8', fakeFunctionNSM(7, 8));
  Expect.equals('2 9 10', closure(9, 10));
  Expect.equals('3 11 12 13 null', closureOpt(11, 12, 13));
  Expect.equals('4 14 15 null 16', closureNamed(14, 15, w: 16));
  Expect.throws(() => closure('wrong arity'), (e) => e is NoSuchMethodError);
}

testLibraryReflective() {
  LibraryMirror lm = reflectClass(D).owner;

  Expect.equals('1 5 6', lm.invoke(#fakeFunctionCall, [5, 6]).reflectee);
  Expect.equals('7, 8', lm.invoke(#fakeFunctionNSM, [7, 8]).reflectee);
  Expect.equals('2 9 10', lm.invoke(#closure, [9, 10]).reflectee);
  Expect.equals(
      '3 11 12 13 null', lm.invoke(#closureOpt, [11, 12, 13]).reflectee);
  Expect.equals('4 14 15 null 16',
      lm.invoke(#closureNamed, [14, 15], {#w: 16}).reflectee);
  Expect.throws(() => lm.invoke(#closure, ['wrong arity']),
      (e) => e is NoSuchMethodError);
}

main() {
  // Do not access the getters/closures at the base level in this variant.
  //testInstanceBase();
  testInstanceReflective();
  //testClassBase();
  testClassReflective();
  //testLibraryBase();
  testLibraryReflective();
}
