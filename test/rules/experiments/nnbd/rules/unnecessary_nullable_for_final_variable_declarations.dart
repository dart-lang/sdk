// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_nullable_for_final_variable_declarations`

final int? _i = 1; // LINT
final int _j = 1; // OK
final int? i = 1; // LINT
final int j = 1; // OK
const int? ic = 1; // LINT
const int jc = 1; // OK
const dynamic jcd = 1; // OK

class A {
  final int? _i = 1; // LINT
  final int _j = 1; // OK
  final int? i = 1; // OK (may be overriden or may override)
  final int j = 1; // OK
  final dynamic jd = 1; // OK
  static final int? si = 1; // LINT
  static final int sj = 1; // OK
}

extension E on A {
  static final int? _e1i = 1; // LINT
  static final int _e1j = 1; // OK
  static final int? e1i = 1; // LINT
  static final int e1j = 1; // OK
  static final dynamic e1jd = 1; // OK
}

m() {
  final int? _i = 1; // LINT
  final int _j = 1; // OK
  final int? i = 1; // LINT
  final int j = 1; // OK
  final dynamic jd = 1; // OK
}
