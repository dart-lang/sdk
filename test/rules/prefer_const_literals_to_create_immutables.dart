// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_const_literals_to_create_immutables`

import 'package:meta/meta.dart';

@immutable
class A {
  const A(a);
  const A.named({a});
}

// basic tests
var l1 = new A([]); // LINT
var l2 = new A(const[]); // OK

// tests for nested lists
var l3 = new A([ // LINT
  []]); // LINT
var l4 = new A([ // LINT
  const[]]); // OK
var l5 = new A(const[ //OK
  const[]]); // OK

// tests with maps and parenthesis
var l6 = new A({1: // LINT
  []});// LINT
var l7 = new A(const {1: const []});// OK
var l8 = new A((([])));// LINT
var l9 = new A(((const[])));// OK

// test with const inside
var l10 = new A([const A(null)]); // LINT

// test named parameter
var l11 = new A.named(a: []); // LINT

// test with literals
var l12 = new A([1]); // LINT
var l13 = new A([1.0]); // LINT
var l14 = new A(['']); // LINT
var l15 = new A([null]); // LINT

// basic tests
var m1 = new A({}); // LINT
var m2 = new A(const{}); // OK

// tests for nested maps
var m3 = new A({ // LINT
  1: {}}); // LINT
var m4 = new A({ // LINT
  1: const{}}); // OK
var m5 = new A(const{1: //OK
  const{}}); // OK

// tests with lists and parenthesis
var m6 = new A([ // LINT
  {}]);// LINT
var m7 = new A(const [const {}]);// OK
var m8 = new A((({})));// LINT
var m9 = new A(((const{})));// OK

// test with const inside
var m10 = new A({1: const A(null)}); // LINT

// test named parameter
var m11 = new A.named(a: {}); // LINT

// test with literals
var m12 = new A({1: 1}); // LINT
var m13 = new A({1: 1.0}); // LINT
var m14 = new A({1: ''}); // LINT
var m15 = new A({1: null}); // LINT

// ignore: undefined_class
var e1 = new B([]); // OK

// optional new
class C {}
var m16 = A([C()]); // OK

@immutable
class K {
  final List<K> children;
  const K({this.children});
}

final k = K(
  children: <K>[for (var i = 0; i < 5; ++i) K()], // OK
);
