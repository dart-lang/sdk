// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

class FakeFunctionCall {
  call(x, y) => '1 $x $y';
}

class FakeFunctionNSM {
  noSuchMethod(msg) => msg.positionalArguments.join(', ');
}

class C {
  get fakeFunctionCall => FakeFunctionCall();
  get fakeFunctionNSM => FakeFunctionNSM();
  get closure =>
      (x, y) => '2 $this $x $y';
  get closureOpt =>
      (x, y, [z, w]) => '3 $this $x $y $z $w';
  get closureNamed =>
      (x, y, {z, w}) => '4 $this $x $y $z $w';
  get notAClosure => 'Not a closure';
  noSuchMethod(msg) => 'DNU';

  toString() => 'C';
}

void testInstanceReflective() {
  InstanceMirror im = reflect(C());

  Expect.equals('1 5 6', im.invoke(#fakeFunctionCall, [5, 6]).reflectee);
  Expect.equals('7, 8', im.invoke(#fakeFunctionNSM, [7, 8]).reflectee);
  Expect.equals('2 C 9 10', im.invoke(#closure, [9, 10]).reflectee);
  Expect.equals(
    '3 C 11 12 13 null',
    im.invoke(#closureOpt, [11, 12, 13]).reflectee,
  );
  Expect.equals(
    '4 C 14 15 null 16',
    im.invoke(#closureNamed, [14, 15], {#w: 16}).reflectee,
  );
  Expect.equals('DNU', im.invoke(#doesNotExist, [17, 18]).reflectee);
  Expect.throwsNoSuchMethodError(() => im.invoke(#closure, ['wrong arity']));
  Expect.throwsNoSuchMethodError(() => im.invoke(#notAClosure, []));
}

class D {
  static get fakeFunctionCall => FakeFunctionCall();
  static get fakeFunctionNSM => FakeFunctionNSM();
  static get closure =>
      (x, y) => '2 $x $y';
  static get closureOpt =>
      (x, y, [z, w]) => '3 $x $y $z $w';
  static get closureNamed =>
      (x, y, {z, w}) => '4 $x $y $z $w';
  static get notAClosure => 'Not a closure';
}

void testClassReflective() {
  ClassMirror cm = reflectClass(D);

  Expect.equals('1 5 6', cm.invoke(#fakeFunctionCall, [5, 6]).reflectee);
  Expect.equals('7, 8', cm.invoke(#fakeFunctionNSM, [7, 8]).reflectee);
  Expect.equals('2 9 10', cm.invoke(#closure, [9, 10]).reflectee);
  Expect.equals(
    '3 11 12 13 null',
    cm.invoke(#closureOpt, [11, 12, 13]).reflectee,
  );
  Expect.equals(
    '4 14 15 null 16',
    cm.invoke(#closureNamed, [14, 15], {#w: 16}).reflectee,
  );
  Expect.throwsNoSuchMethodError(() => cm.invoke(#closure, ['wrong arity']));
}

get fakeFunctionCall => FakeFunctionCall();
get fakeFunctionNSM => FakeFunctionNSM();
get closure =>
    (x, y) => '2 $x $y';
get closureOpt =>
    (x, y, [z, w]) => '3 $x $y $z $w';
get closureNamed =>
    (x, y, {z, w}) => '4 $x $y $z $w';
get notAClosure => 'Not a closure';

void testLibraryReflective() {
  LibraryMirror lm = reflectClass(D).owner as LibraryMirror;

  Expect.equals('1 5 6', lm.invoke(#fakeFunctionCall, [5, 6]).reflectee);
  Expect.equals('7, 8', lm.invoke(#fakeFunctionNSM, [7, 8]).reflectee);
  Expect.equals('2 9 10', lm.invoke(#closure, [9, 10]).reflectee);
  Expect.equals(
    '3 11 12 13 null',
    lm.invoke(#closureOpt, [11, 12, 13]).reflectee,
  );
  Expect.equals(
    '4 14 15 null 16',
    lm.invoke(#closureNamed, [14, 15], {#w: 16}).reflectee,
  );
  Expect.throwsNoSuchMethodError(() => lm.invoke(#closure, ['wrong arity']));
}

void main() {
  testInstanceReflective();
  testClassReflective();
  testLibraryReflective();
}
