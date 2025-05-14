// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that horizontal inference works properly when record types are
// involved. This is an important corner case because record types were added to
// the language after horizontal inference, and the logic to determine whether a
// given type variable appears free in a given type was not properly updated to
// understand record types (see https://github.com/dart-lang/sdk/issues/59933).

import 'package:expect/static_type_helper.dart';

testUnnamedField(void Function<T>((T,) v, void Function(T) fn) f) {
  // There should be a round of horizontal inference between type inference of
  // `('',)` and type inference of `(s) { ... }`, because the type `T` appears
  // free in the type of the former `(T,)` and in the parameter type of the type
  // of latter (`void Function(T)`).
  f(('',), (s) {
    (s..expectStaticType<Exactly<String>>()).length;
  });
}

testNamedField(void Function<T>(({T x}) v, void Function(T) fn) f) {
  // There should be a round of horizontal inference between type inference of
  // `('',)` and type inference of `(s) { ... }`, because the type `T` appears
  // free in the type of the former `({T x})` and in the parameter type of the
  // type of latter (`void Function(T)`).
  f((x: ''), (s) {
    (s..expectStaticType<Exactly<String>>()).length;
  });
}

main() {
  testUnnamedField(<T>((T,) v, void Function(T) fn) {
    fn(v.$1);
  });
  testNamedField(<T>(({T x}) v, void Function(T) fn) {
    fn(v.x);
  });
}
