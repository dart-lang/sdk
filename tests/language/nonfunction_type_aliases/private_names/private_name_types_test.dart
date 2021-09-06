// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that private names exported via public typedefs work correctly as
// types.

import "package:expect/expect.dart";

import "private_name_library.dart";
import "private_name_library.dart" as prefixed;

/// Test that each public typedef is usable as a type, and that the types
/// behave as expected.
void test1() {
  {
    PublicClass p0 = mkPublicClass();
    AlsoPublicClass p1 = mkAlsoPublicClass();
    // Test that equivalent private types are still equivalent
    p0 = p1;
    p1 = p0;
  }

  {
    PublicGenericClass<int> p0 = mkPublicGenericClass();
    PublicGenericClassOfInt p1 = mkPublicGenericClass();
    // Test that equivalent private types are still equivalent
    p0 = p1;
    p1 = p0;

    // Test that inference works on private generic names.
    Type capture<T>(PublicGenericClass<T> a) => T;
    Expect.equals(int, capture(p1));
  }
}

/// Test that each public typedef is usable as a type when the types are
/// imported with a prefix, and that the types behave as expected.
void test2() {
  {
    prefixed.PublicClass p0 = prefixed.mkPublicClass();
    prefixed.AlsoPublicClass p1 = prefixed.mkAlsoPublicClass();
    // Test that equivalent private types are still equivalent
    p0 = p1;
    p1 = p0;
  }

  {
    prefixed.PublicGenericClass<int> p0 = prefixed.mkPublicGenericClass();
    prefixed.PublicGenericClassOfInt p1 = prefixed.mkPublicGenericClass();
    // Test that equivalent private types are still equivalent
    p0 = p1;
    p1 = p0;

    // Test that inference works on private generic names.
    Type capture<T>(prefixed.PublicGenericClass<T> a) => T;
    Expect.equals(capture(p1), int);
  }
}

void main() {
  test1();
  test2();
}
