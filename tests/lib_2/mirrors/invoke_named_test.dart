// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_named_test;

import 'dart:mirrors';

import 'dart:async' show Future;

import 'package:expect/expect.dart';
import 'invoke_test.dart';

// TODO(ahe): Remove this variable (http://dartbug.com/12863).
bool isDart2js = false;

class C {
  a(a, {b: 'B', c}) => "$a-$b-$c";
  b({a: 'A', b, c}) => "$a-$b-$c";
  c(a, [b, c = 'C']) => "$a-$b-$c";
  d([a, b = 'B', c = 'C']) => "$a-$b-$c";
  e(a, b, c) => "$a-$b-$c";
}

class D {
  static a(a, {b: 'B', c}) => "$a-$b-$c";
  static b({a: 'A', b, c}) => "$a-$b-$c";
  static c(a, [b, c = 'C']) => "$a-$b-$c";
  static d([a, b = 'B', c = 'C']) => "$a-$b-$c";
  static e(a, b, c) => "$a-$b-$c";
}

class E {
  var field;
  E(a, {b: 'B', c}) : this.field = "$a-$b-$c";
  E.b({a: 'A', b, c}) : this.field = "$a-$b-$c";
  E.c(a, [b, c = 'C']) : this.field = "$a-$b-$c";
  E.d([a, b = 'B', c = 'C']) : this.field = "$a-$b-$c";
  E.e(a, b, c) : this.field = "$a-$b-$c";
}

a(a, {b: 'B', c}) => "$a-$b-$c";
b({a: 'A', b, c}) => "$a-$b-$c";
c(a, [b, c = 'C']) => "$a-$b-$c";
d([a, b = 'B', c = 'C']) => "$a-$b-$c";
e(a, b, c) => "$a-$b-$c";

testSyncInvoke(ObjectMirror om) {
  InstanceMirror result;

  result = om.invoke(const Symbol('a'), ['X']);
  Expect.equals('X-B-null', result.reflectee);
  result = om.invoke(const Symbol('a'), ['X'], {const Symbol('b'): 'Y'});
  Expect.equals('X-Y-null', result.reflectee);
  result = om.invoke(const Symbol('a'), ['X'],
      {const Symbol('c'): 'Z', const Symbol('b'): 'Y'});
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throwsNoSuchMethodError(() => om.invoke(const Symbol('a'), []),
      'Insufficient positional arguments');
  Expect.throwsNoSuchMethodError(() => om.invoke(const Symbol('a'), ['X', 'Y']),
      'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => om.invoke(const Symbol('a'), ['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  result = om.invoke(const Symbol('b'), []);
  Expect.equals('A-null-null', result.reflectee);
  result = om.invoke(const Symbol('b'), [], {const Symbol('a'): 'X'});
  Expect.equals('X-null-null', result.reflectee);
  result = om.invoke(const Symbol('b'), [],
      {const Symbol('b'): 'Y', const Symbol('c'): 'Z', const Symbol('a'): 'X'});
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throwsNoSuchMethodError(
      () => om.invoke(const Symbol('b'), ['X']), 'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => om.invoke(const Symbol('b'), ['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  result = om.invoke(const Symbol('c'), ['X']);
  Expect.equals('X-null-C', result.reflectee);
  result = om.invoke(const Symbol('c'), ['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee);
  result = om.invoke(const Symbol('c'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throwsNoSuchMethodError(() => om.invoke(const Symbol('c'), []),
      'Insufficient positional arguments');
  Expect.throwsNoSuchMethodError(
      () => om.invoke(const Symbol('c'), ['X', 'Y', 'Z', 'W']),
      'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => om.invoke(const Symbol('c'), ['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  result = om.invoke(const Symbol('d'), []);
  Expect.equals('null-B-C', result.reflectee);
  result = om.invoke(const Symbol('d'), ['X']);
  Expect.equals('X-B-C', result.reflectee);
  result = om.invoke(const Symbol('d'), ['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee);
  result = om.invoke(const Symbol('d'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throwsNoSuchMethodError(
      () => om.invoke(const Symbol('d'), ['X', 'Y', 'Z', 'W']),
      'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => om.invoke(const Symbol('d'), ['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  result = om.invoke(const Symbol('e'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throwsNoSuchMethodError(() => om.invoke(const Symbol('e'), ['X']),
      'Insufficient positional arguments');
  Expect.throwsNoSuchMethodError(
      () => om.invoke(const Symbol('e'), ['X', 'Y', 'Z', 'W']),
      'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => om.invoke(const Symbol('e'), ['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');
}

testSyncNewInstance() {
  ClassMirror cm = reflectClass(E);
  InstanceMirror result;

  result = cm.newInstance(const Symbol(''), ['X']);
  Expect.equals('X-B-null', result.reflectee.field);
  result = cm.newInstance(const Symbol(''), ['X'], {const Symbol('b'): 'Y'});
  Expect.equals('X-Y-null', result.reflectee.field);
  result = cm.newInstance(const Symbol(''), ['X'],
      {const Symbol('c'): 'Z', const Symbol('b'): 'Y'});
  Expect.equals('X-Y-Z', result.reflectee.field);
  Expect.throwsNoSuchMethodError(() => cm.newInstance(const Symbol(''), []),
      'Insufficient positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.newInstance(const Symbol(''), ['X', 'Y']),
      'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () =>
          cm.newInstance(const Symbol(''), ['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  result = cm.newInstance(const Symbol('b'), []);
  Expect.equals('A-null-null', result.reflectee.field);
  result = cm.newInstance(const Symbol('b'), [], {const Symbol('a'): 'X'});
  Expect.equals('X-null-null', result.reflectee.field);
  result = cm.newInstance(const Symbol('b'), [],
      {const Symbol('b'): 'Y', const Symbol('c'): 'Z', const Symbol('a'): 'X'});
  Expect.equals('X-Y-Z', result.reflectee.field);
  Expect.throwsNoSuchMethodError(() => cm.newInstance(const Symbol('b'), ['X']),
      'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm
          .newInstance(const Symbol('b'), ['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  result = cm.newInstance(const Symbol('c'), ['X']);
  Expect.equals('X-null-C', result.reflectee.field);
  result = cm.newInstance(const Symbol('c'), ['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee.field);
  result = cm.newInstance(const Symbol('c'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee.field);
  Expect.throwsNoSuchMethodError(() => cm.newInstance(const Symbol('c'), []),
      'Insufficient positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.newInstance(const Symbol('c'), ['X', 'Y', 'Z', 'W']),
      'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm
          .newInstance(const Symbol('c'), ['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  result = cm.newInstance(const Symbol('d'), []);
  Expect.equals('null-B-C', result.reflectee.field);
  result = cm.newInstance(const Symbol('d'), ['X']);
  Expect.equals('X-B-C', result.reflectee.field);
  result = cm.newInstance(const Symbol('d'), ['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee.field);
  result = cm.newInstance(const Symbol('d'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee.field);
  Expect.throwsNoSuchMethodError(
      () => cm.newInstance(const Symbol('d'), ['X', 'Y', 'Z', 'W']),
      'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm
          .newInstance(const Symbol('d'), ['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  result = cm.newInstance(const Symbol('e'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee.field);
  Expect.throwsNoSuchMethodError(() => cm.newInstance(const Symbol('e'), ['X']),
      'Insufficient positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.newInstance(const Symbol('e'), ['X', 'Y', 'Z', 'W']),
      'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm
          .newInstance(const Symbol('e'), ['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');
}

testSyncApply() {
  ClosureMirror cm;
  InstanceMirror result;

  cm = reflect(a);
  result = cm.apply(['X']);
  Expect.equals('X-B-null', result.reflectee);
  result = cm.apply(['X'], {const Symbol('b'): 'Y'});
  Expect.equals('X-Y-null', result.reflectee);
  result = cm.apply(['X'], {const Symbol('c'): 'Z', const Symbol('b'): 'Y'});
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throwsNoSuchMethodError(
      () => cm.apply([]), 'Insufficient positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X', 'Y']), 'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  cm = reflect(b);
  result = cm.apply([]);
  Expect.equals('A-null-null', result.reflectee);
  result = cm.apply([], {const Symbol('a'): 'X'});
  Expect.equals('X-null-null', result.reflectee);
  result = cm.apply([],
      {const Symbol('b'): 'Y', const Symbol('c'): 'Z', const Symbol('a'): 'X'});
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X']), 'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  cm = reflect(c);
  result = cm.apply(['X']);
  Expect.equals('X-null-C', result.reflectee);
  result = cm.apply(['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee);
  result = cm.apply(['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throwsNoSuchMethodError(
      () => cm.apply([]), 'Insufficient positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X', 'Y', 'Z', 'W']), 'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  cm = reflect(d);
  result = cm.apply([]);
  Expect.equals('null-B-C', result.reflectee);
  result = cm.apply(['X']);
  Expect.equals('X-B-C', result.reflectee);
  result = cm.apply(['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee);
  result = cm.apply(['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X', 'Y', 'Z', 'W']), 'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');

  cm = reflect(e);
  result = cm.apply(['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X']), 'Insufficient positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X', 'Y', 'Z', 'W']), 'Extra positional arguments');
  Expect.throwsNoSuchMethodError(
      () => cm.apply(['X'], {const Symbol('undef'): 'Y'}),
      'Unmatched named argument');
}

main() {
  isDart2js = true; //# 01: ok

  testSyncInvoke(reflect(new C())); // InstanceMirror

  if (isDart2js) return;

  testSyncInvoke(reflectClass(D)); // ClassMirror
  LibraryMirror lib = reflectClass(D).owner;
  testSyncInvoke(lib); // LibraryMirror

  testSyncNewInstance();

  testSyncApply();
}
