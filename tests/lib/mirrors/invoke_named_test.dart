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
  a(a, {b:'B', c}) => "$a-$b-$c";
  b({a:'A', b, c}) => "$a-$b-$c";
  c(a, [b, c='C']) => "$a-$b-$c";
  d([a, b='B', c='C']) => "$a-$b-$c";
  e(a, b, c) => "$a-$b-$c";
}

class D {
  static a(a, {b:'B', c}) => "$a-$b-$c";
  static b({a:'A', b, c}) => "$a-$b-$c";
  static c(a, [b, c='C']) => "$a-$b-$c";
  static d([a, b='B', c='C']) => "$a-$b-$c";
  static e(a, b, c) => "$a-$b-$c";
}

class E {
  var field;
  E(a, {b:'B', c}) : this.field = "$a-$b-$c";
  E.b({a:'A', b, c}) : this.field = "$a-$b-$c";
  E.c(a, [b, c='C']) : this.field = "$a-$b-$c";
  E.d([a, b='B', c='C']) : this.field = "$a-$b-$c";
  E.e(a, b, c) : this.field = "$a-$b-$c";
}

a(a, {b:'B', c}) => "$a-$b-$c";
b({a:'A', b, c}) => "$a-$b-$c";
c(a, [b, c='C']) => "$a-$b-$c";
d([a, b='B', c='C']) => "$a-$b-$c";
e(a, b, c) => "$a-$b-$c";

testSyncInvoke(ObjectMirror om) {
  InstanceMirror result;

  result = om.invoke(const Symbol('a'), ['X']);
  Expect.equals('X-B-null', result.reflectee);
  result = om.invoke(const Symbol('a'), ['X'], {const Symbol('b') : 'Y'});
  Expect.equals('X-Y-null', result.reflectee);
  result = om.invoke(const Symbol('a'), ['X'], {const Symbol('c') : 'Z', const Symbol('b') : 'Y'});
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throws(() => om.invoke(const Symbol('a'), []),
                isNoSuchMethodError,
                'Insufficient positional arguments');
  Expect.throws(() => om.invoke(const Symbol('a'), ['X', 'Y']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => om.invoke(const Symbol('a'), ['X'], {const Symbol('undef') : 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');

  result = om.invoke(const Symbol('b'), []);
  Expect.equals('A-null-null', result.reflectee);
  result = om.invoke(const Symbol('b'), [], {const Symbol('a') : 'X'});
  Expect.equals('X-null-null', result.reflectee);
  result = om.invoke(const Symbol('b'), [], {const Symbol('b') :'Y', const Symbol('c') :'Z', const Symbol('a') :'X'});
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throws(() => om.invoke(const Symbol('b'), ['X']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => om.invoke(const Symbol('b'), ['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');

  if (!isDart2js) {
  result = om.invoke(const Symbol('c'), ['X']);
  Expect.equals('X-null-C', result.reflectee);
  result = om.invoke(const Symbol('c'), ['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee);
  result = om.invoke(const Symbol('c'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throws(() => om.invoke(const Symbol('c'), []),
                isNoSuchMethodError,
                'Insufficient positional arguments');
  Expect.throws(() => om.invoke(const Symbol('c'), ['X', 'Y', 'Z', 'W']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => om.invoke(const Symbol('c'), ['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');

  result = om.invoke(const Symbol('d'), []);
  Expect.equals('null-B-C', result.reflectee);
  result = om.invoke(const Symbol('d'), ['X']);
  Expect.equals('X-B-C', result.reflectee);
  result = om.invoke(const Symbol('d'), ['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee);
  result = om.invoke(const Symbol('d'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throws(() => om.invoke(const Symbol('d'), ['X', 'Y', 'Z', 'W']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => om.invoke(const Symbol('d'), ['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');
  }

  result = om.invoke(const Symbol('e'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throws(() => om.invoke(const Symbol('e'), ['X']),
                isNoSuchMethodError,
                'Insufficient positional arguments');
  Expect.throws(() => om.invoke(const Symbol('e'), ['X', 'Y', 'Z', 'W']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => om.invoke(const Symbol('e'), ['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');
}

testAsyncInvoke(ObjectMirror om) {
  Future<InstanceMirror> future;

  future = om.invokeAsync(const Symbol('a'), ['X']);
  expectValueThen(future, (result) {
    Expect.equals('X-B-null', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('a'), ['X'], {const Symbol('b') : 'Y'});
  expectValueThen(future, (result) {
    Expect.equals('X-Y-null', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('a'), ['X'], {const Symbol('c') : 'Z', const Symbol('b') : 'Y'});
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('a'), []);
  expectError(future, isNoSuchMethodError, 'Insufficient positional arguments');
  future = om.invokeAsync(const Symbol('a'), ['X', 'Y']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = om.invokeAsync(const Symbol('a'), ['X'], {const Symbol('undef') : 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');


  future = om.invokeAsync(const Symbol('b'), []);
  expectValueThen(future, (result) {
    Expect.equals('A-null-null', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('b'), [], {const Symbol('a') : 'X'});
  expectValueThen(future, (result) {
    Expect.equals('X-null-null', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('b'), [], {const Symbol('b') :'Y', const Symbol('c') :'Z', const Symbol('a') :'X'});
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('b'), ['X']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = om.invokeAsync(const Symbol('b'), ['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');

  if (!isDart2js) {
  future = om.invokeAsync(const Symbol('c'), ['X']);
  expectValueThen(future, (result) {
    Expect.equals('X-null-C', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('c'), ['X', 'Y']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-C', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('c'), ['X', 'Y', 'Z']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('c'), []);
  expectError(future, isNoSuchMethodError, 'Insufficient positional arguments');
  future = om.invokeAsync(const Symbol('c'), ['X', 'Y', 'Z', 'W']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = om.invokeAsync(const Symbol('c'), ['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');


  future = om.invokeAsync(const Symbol('d'), []);
  expectValueThen(future, (result) {
    Expect.equals('null-B-C', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('d'), ['X']);
  expectValueThen(future, (result) {
    Expect.equals('X-B-C', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('d'), ['X', 'Y']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-C', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('d'), ['X', 'Y', 'Z']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('d'), ['X', 'Y', 'Z', 'W']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = om.invokeAsync(const Symbol('d'), ['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');
  }

  future = om.invokeAsync(const Symbol('e'), ['X', 'Y', 'Z']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee);
  });
  future = om.invokeAsync(const Symbol('e'), ['X']);
  expectError(future, isNoSuchMethodError, 'Insufficient positional arguments');
  future = om.invokeAsync(const Symbol('e'), ['X', 'Y', 'Z', 'W']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = om.invokeAsync(const Symbol('e'), ['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');
}

testSyncNewInstance() {
  ClassMirror cm = reflectClass(E);
  InstanceMirror result;

  result = cm.newInstance(const Symbol(''), ['X']);
  Expect.equals('X-B-null', result.reflectee.field);
  result = cm.newInstance(const Symbol(''), ['X'], {const Symbol('b') : 'Y'});
  Expect.equals('X-Y-null', result.reflectee.field);
  result = cm.newInstance(const Symbol(''), ['X'], {const Symbol('c') : 'Z', const Symbol('b') : 'Y'});
  Expect.equals('X-Y-Z', result.reflectee.field);
  Expect.throws(() => cm.newInstance(const Symbol(''), []),
                isNoSuchMethodError,
                'Insufficient positional arguments');
  Expect.throws(() => cm.newInstance(const Symbol(''), ['X', 'Y']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => cm.newInstance(const Symbol(''), ['X'], {const Symbol('undef') : 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');

  result = cm.newInstance(const Symbol('b'), []);
  Expect.equals('A-null-null', result.reflectee.field);
  result = cm.newInstance(const Symbol('b'), [], {const Symbol('a') : 'X'});
  Expect.equals('X-null-null', result.reflectee.field);
  result = cm.newInstance(const Symbol('b'), [], {const Symbol('b') :'Y', const Symbol('c') :'Z', const Symbol('a') :'X'});
  Expect.equals('X-Y-Z', result.reflectee.field);
  Expect.throws(() => cm.newInstance(const Symbol('b'), ['X']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => cm.newInstance(const Symbol('b'), ['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');

  result = cm.newInstance(const Symbol('c'), ['X']);
  Expect.equals('X-null-C', result.reflectee.field);
  result = cm.newInstance(const Symbol('c'), ['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee.field);
  result = cm.newInstance(const Symbol('c'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee.field);
  Expect.throws(() => cm.newInstance(const Symbol('c'), []),
                isNoSuchMethodError,
                'Insufficient positional arguments');
  Expect.throws(() => cm.newInstance(const Symbol('c'), ['X', 'Y', 'Z', 'W']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => cm.newInstance(const Symbol('c'), ['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');

  result = cm.newInstance(const Symbol('d'), []);
  Expect.equals('null-B-C', result.reflectee.field);
  result = cm.newInstance(const Symbol('d'), ['X']);
  Expect.equals('X-B-C', result.reflectee.field);
  result = cm.newInstance(const Symbol('d'), ['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee.field);
  result = cm.newInstance(const Symbol('d'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee.field);
  Expect.throws(() => cm.newInstance(const Symbol('d'), ['X', 'Y', 'Z', 'W']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => cm.newInstance(const Symbol('d'), ['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');

  result = cm.newInstance(const Symbol('e'), ['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee.field);
  Expect.throws(() => cm.newInstance(const Symbol('e'), ['X']),
                isNoSuchMethodError,
                'Insufficient positional arguments');
  Expect.throws(() => cm.newInstance(const Symbol('e'), ['X', 'Y', 'Z', 'W']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => cm.newInstance(const Symbol('e'), ['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');
}

testAsyncNewInstance() {
  ClassMirror cm = reflectClass(E);
  Future<InstanceMirror> future;

  future = cm.newInstanceAsync(const Symbol(''), ['X']);
  expectValueThen(future, (result) {
    Expect.equals('X-B-null', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol(''), ['X'], {const Symbol('b') : 'Y'});
  expectValueThen(future, (result) {
    Expect.equals('X-Y-null', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol(''), ['X'], {const Symbol('c') : 'Z', const Symbol('b') : 'Y'});
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol(''), []);
  expectError(future, isNoSuchMethodError, 'Insufficient positional arguments');
  future = cm.newInstanceAsync(const Symbol(''), ['X', 'Y']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = cm.newInstanceAsync(const Symbol(''), ['X'], {const Symbol('undef') : 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');


  future = cm.newInstanceAsync(const Symbol('b'), []);
  expectValueThen(future, (result) {
    Expect.equals('A-null-null', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('b'), [], {const Symbol('a') : 'X'});
  expectValueThen(future, (result) {
    Expect.equals('X-null-null', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('b'), [], {const Symbol('b') :'Y', const Symbol('c') :'Z', const Symbol('a') :'X'});
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('b'), ['X']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = cm.newInstanceAsync(const Symbol('b'), ['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');


  future = cm.newInstanceAsync(const Symbol('c'), ['X']);
  expectValueThen(future, (result) {
    Expect.equals('X-null-C', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('c'), ['X', 'Y']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-C', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('c'), ['X', 'Y', 'Z']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('c'), []);
  expectError(future, isNoSuchMethodError, 'Insufficient positional arguments');
  future = cm.newInstanceAsync(const Symbol('c'), ['X', 'Y', 'Z', 'W']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = cm.newInstanceAsync(const Symbol('c'), ['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');


  future = cm.newInstanceAsync(const Symbol('d'), []);
  expectValueThen(future, (result) {
    Expect.equals('null-B-C', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('d'), ['X']);
  expectValueThen(future, (result) {
    Expect.equals('X-B-C', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('d'), ['X', 'Y']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-C', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('d'), ['X', 'Y', 'Z']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('d'), ['X', 'Y', 'Z', 'W']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = cm.newInstanceAsync(const Symbol('d'), ['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');


  future = cm.newInstanceAsync(const Symbol('e'), ['X', 'Y', 'Z']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('e'), ['X']);
  expectError(future, isNoSuchMethodError, 'Insufficient positional arguments');
  future = cm.newInstanceAsync(const Symbol('e'), ['X', 'Y', 'Z', 'W']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = cm.newInstanceAsync(const Symbol('e'), ['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');
}

testSyncApply() {
  ClosureMirror cm;
  InstanceMirror result;

  cm = reflect(a);
  result = cm.apply(['X']);
  Expect.equals('X-B-null', result.reflectee);
  result = cm.apply(['X'], {const Symbol('b') : 'Y'});
  Expect.equals('X-Y-null', result.reflectee);
  result = cm.apply(['X'], {const Symbol('c') : 'Z', const Symbol('b') : 'Y'});
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throws(() => cm.apply([]),
                isNoSuchMethodError,
                'Insufficient positional arguments');
  Expect.throws(() => cm.apply(['X', 'Y']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => cm.apply(['X'], {const Symbol('undef') : 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');

  cm = reflect(b);
  result = cm.apply([]);
  Expect.equals('A-null-null', result.reflectee);
  result = cm.apply([], {const Symbol('a') : 'X'});
  Expect.equals('X-null-null', result.reflectee);
  result = cm.apply([], {const Symbol('b') :'Y', const Symbol('c') :'Z', const Symbol('a') :'X'});
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throws(() => cm.apply(['X']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => cm.apply(['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');

  cm = reflect(c);
  result = cm.apply(['X']);
  Expect.equals('X-null-C', result.reflectee);
  result = cm.apply(['X', 'Y']);
  Expect.equals('X-Y-C', result.reflectee);
  result = cm.apply(['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throws(() => cm.apply([]),
                isNoSuchMethodError,
                'Insufficient positional arguments');
  Expect.throws(() => cm.apply(['X', 'Y', 'Z', 'W']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => cm.apply(['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
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
  Expect.throws(() => cm.apply(['X', 'Y', 'Z', 'W']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => cm.apply(['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');

  cm = reflect(e);
  result = cm.apply(['X', 'Y', 'Z']);
  Expect.equals('X-Y-Z', result.reflectee);
  Expect.throws(() => cm.apply(['X']),
                isNoSuchMethodError,
                'Insufficient positional arguments');
  Expect.throws(() => cm.apply(['X', 'Y', 'Z', 'W']),
                isNoSuchMethodError,
                'Extra positional arguments');
  Expect.throws(() => cm.apply(['X'], {const Symbol('undef'): 'Y'}),
                isNoSuchMethodError,
                'Unmatched named argument');
}

testAsyncApply() {
  ClosureMirror cm;
  Future<InstanceMirror> future;

  cm = reflect(a);
  future = cm.applyAsync(['X']);
  expectValueThen(future, (result) {
    Expect.equals('X-B-null', result.reflectee);
  });
  future = cm.applyAsync(['X'], {const Symbol('b') : 'Y'});
  expectValueThen(future, (result) {
    Expect.equals('X-Y-null', result.reflectee);
  });
  future = cm.applyAsync(['X'], {const Symbol('c') : 'Z', const Symbol('b') : 'Y'});
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee);
  });
  future = cm.applyAsync([]);
  expectError(future, isNoSuchMethodError, 'Insufficient positional arguments');
  future = cm.applyAsync(['X', 'Y']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = cm.applyAsync(['X'], {const Symbol('undef') : 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');


  cm = reflect(b);
  future = cm.applyAsync([]);
  expectValueThen(future, (result) {
    Expect.equals('A-null-null', result.reflectee);
  });
  future = cm.applyAsync([], {const Symbol('a') : 'X'});
  expectValueThen(future, (result) {
    Expect.equals('X-null-null', result.reflectee);
  });
  future = cm.applyAsync([], {const Symbol('b') :'Y', const Symbol('c') :'Z', const Symbol('a') :'X'});
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee);
  });
  future = cm.applyAsync(['X']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = cm.applyAsync(['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');


  cm = reflect(c);
  future = cm.applyAsync(['X']);
  expectValueThen(future, (result) {
    Expect.equals('X-null-C', result.reflectee);
  });
  future = cm.applyAsync(['X', 'Y']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-C', result.reflectee);
  });
  future = cm.applyAsync(['X', 'Y', 'Z']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee);
  });
  future = cm.applyAsync([]);
  expectError(future, isNoSuchMethodError, 'Insufficient positional arguments');
  future = cm.applyAsync(['X', 'Y', 'Z', 'W']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = cm.applyAsync(['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');


  cm = reflect(d);
  future = cm.applyAsync([]);
  expectValueThen(future, (result) {
    Expect.equals('null-B-C', result.reflectee);
  });
  future = cm.applyAsync(['X']);
  expectValueThen(future, (result) {
    Expect.equals('X-B-C', result.reflectee);
  });
  future = cm.applyAsync(['X', 'Y']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-C', result.reflectee);
  });
  future = cm.applyAsync(['X', 'Y', 'Z']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee);
  });
  future = cm.applyAsync(['X', 'Y', 'Z', 'W']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = cm.applyAsync(['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');


  cm = reflect(e);
  future = cm.applyAsync(['X', 'Y', 'Z']);
  expectValueThen(future, (result) {
    Expect.equals('X-Y-Z', result.reflectee);
  });
  future = cm.applyAsync(['X']);
  expectError(future, isNoSuchMethodError, 'Insufficient positional arguments');
  future = cm.applyAsync(['X', 'Y', 'Z', 'W']);
  expectError(future, isNoSuchMethodError, 'Extra positional arguments');
  future = cm.applyAsync(['X'], {const Symbol('undef'): 'Y'});
  expectError(future, isNoSuchMethodError, 'Unmatched named argument');
}

main() {
  isDart2js = true; /// 01: ok

  testSyncInvoke(reflect(new C())); // InstanceMirror
  if (!isDart2js) testSyncInvoke(reflectClass(D)); // ClassMirror
  LibraryMirror lib = reflectClass(D).owner;
  if (!isDart2js) testSyncInvoke(lib); // LibraryMirror

  testAsyncInvoke(reflect(new C())); // InstanceMirror

  if (isDart2js) return;

  testAsyncInvoke(reflectClass(D)); // ClassMirror
  testAsyncInvoke(lib); // LibraryMirror

  testSyncNewInstance();
  testAsyncNewInstance();

  testSyncApply();
  testAsyncApply();
}
