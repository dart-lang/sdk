// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_const_declarations`

const o1 = const []; // OK
final o2 = []; // OK
final o3 = const []; // LINT
final o4 = ''; // LINT
final o5 = 1; // LINT
final o6 = 1.3; // LINT
final o7 = null; // LINT
final o8 = const {}; // LINT

class A {
  static const o1 = const []; // OK
  static final o2 = []; // OK
  static final o3 = const []; // LINT
  static final o4 = ''; // LINT
  static final o5 = 1; // LINT
  static final o6 = 1.3; // LINT
  static final o7 = null; // LINT
  static final o8 = const {}; // LINT

  final i = const []; // OK
}
