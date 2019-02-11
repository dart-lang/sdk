// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_const_declarations`

//ignore_for_file: unused_local_variable

const o1 = const []; // OK
final o2 = []; // OK
final o3 = const []; // LINT
final o4 = ''; // LINT
final o5 = 1; // LINT
final o6 = 1.3; // LINT
final o7 = null; // LINT
final o8 = const {}; // LINT
final o9 = {}; // OK
final o10 = o1; // LINT

// lint on final keyword
final a = null; // LINT

class A {
  const A();

  static const o1 = const []; // OK
  static final o2 = []; // OK
  static final o3 = const []; // LINT
  static final o4 = ''; // LINT
  static final o5 = 1; // LINT
  static final o6 = 1.3; // LINT
  static final o7 = null; // LINT
  static final o8 = const {}; // LINT
  static final o9 = {}; // OK

  // lint on final keyword
  static //
      final a = null; // LINT

  final i = const []; // OK

  int m() => 0;
}

m() {
  const o1 = const []; // OK
  final o2 = []; // OK
  final o3 = const []; // LINT
  final o4 = ''; // LINT
  final o5 = 1; // LINT
  final o6 = 1.3; // LINT
  final o7 = null; // LINT
  final o8 = const {}; // LINT
  final o9 = {}; // OK
  final o10 = new A(); // OK
  final o11 = const A(); // LINT
  final o12 = A.o1; // LINT
  final o13 = A.o2; // OK
  final o14 = o11.m(); // OK

  // lint on final keyword
  final a = null; // LINT

  // https://github.com/dart-lang/sdk/issues/32745
  final b, c = 1; // OK

  final s = {}; // OK
  final Set<int> ids = {}; // OK
  final Set<int> ids2 = <int>{}; // OK

  final m = <int,int>{}; // OK
  final Map<int,int> m2 = {}; // OK
  final Map<int,int> m3 = <int,int>{}; // OK

  final l = <int>[]; // OK
  final List<int> l2 = []; // OK
  final List<int> l3 = <int>[]; // OK
}
