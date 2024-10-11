// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that if an assignment is made to a local variable that's been promoted
/// to a record type, and the newly assigned value doesn't match the previously
/// promoted type, no error occurs (the variable is simply demoted).

import 'package:expect/static_type_helper.dart';

void testPositionalFieldTypeMismatch(Object o) {
  if (o is (int,)) {
    o.expectStaticType<Exactly<(int,)>>();
    // Note: prior to https://github.com/dart-lang/language/pull/3613 this would
    // have been a compile-time error, since there is no coercion from `String`
    // to `int`.
    o = ('',)..expectStaticType<Exactly<(String,)>>();
    o.expectStaticType<Exactly<Object>>();
  }
}

void testNamedFieldTypeMismatch(Object o) {
  if (o is ({int f1})) {
    o.expectStaticType<Exactly<({int f1})>>();
    // Note: prior to https://github.com/dart-lang/language/pull/3613 this would
    // have been a compile-time error, since there is no coercion from `String`
    // to `int`.
    o = (f1: '')..expectStaticType<Exactly<({String f1})>>();
    o.expectStaticType<Exactly<Object>>();
  }
}

void testAdditionalPositionalField(Object o) {
  if (o is (int,)) {
    o.expectStaticType<Exactly<(int,)>>();
    o = (1, 2)..expectStaticType<Exactly<(int, int)>>();
    o.expectStaticType<Exactly<Object>>();
  }
}

void testAdditionalNamedField(Object o) {
  if (o is ({int f1})) {
    o.expectStaticType<Exactly<({int f1})>>();
    o = (f1: 1, f2: 2)..expectStaticType<Exactly<({int f1, int f2})>>();
    o.expectStaticType<Exactly<Object>>();
  }
}

void testMissingPositionalField(Object o) {
  if (o is (int, int)) {
    o.expectStaticType<Exactly<(int, int)>>();
    o = (1,);
    o.expectStaticType<Exactly<Object>>();
  }
}

void testMissingNamedField(Object o) {
  if (o is ({int f1, int f2})) {
    o.expectStaticType<Exactly<({int f1, int f2})>>();
    o = (f1: 1);
    o.expectStaticType<Exactly<Object>>();
  }
}

main() {
  testPositionalFieldTypeMismatch((1,));
  testNamedFieldTypeMismatch((f1: 1));
  testAdditionalPositionalField((1,));
  testAdditionalNamedField((f1: 1));
  testMissingPositionalField((1, 2));
  testMissingNamedField((f1: 1, f2: 2));
}
