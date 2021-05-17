// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that private names exported via public typedefs work correctly for
// accessing static methods.

import "package:expect/expect.dart";

import "../../static_type_helper.dart";
import "private_name_library.dart";

/// Test that each public typedef can be used to access static methods.
void test1() {
  {
    Expect.equals(privateLibrarySentinel, PublicClass.staticMethod());
    PublicClass.staticMethod().expectStaticType<Exactly<int>>();

    Expect.equals(privateLibrarySentinel, AlsoPublicClass.staticMethod());
    AlsoPublicClass.staticMethod().expectStaticType<Exactly<int>>();

    Expect.equals(
        privateLibrarySentinel, PublicGenericClassOfInt.staticMethod());
    PublicGenericClassOfInt.staticMethod().expectStaticType<Exactly<int>>();
  }
}

void main() {
  test1();
}
