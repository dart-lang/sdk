// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int field1;
  num field2;

  A(this.field1, this.field2);
}

exhaustiveDirect(A a) => switch (a) {
      A() => 0,
    };

exhaustiveWithWildcards(A a) => switch (a) {
      A(field1: _, field2: _) => 0,
    };

exhaustiveWithFields(A a) => switch (a) {
      A(:var field1, :var field2) => 0,
    };

exhaustiveWithTypedFields(A a) => switch (a) {
      A(:int field1, :num field2) => 0,
    };

nonExhaustiveFixedField(A a) => switch (a) {
      A(field1: 5) => 0,
    };

nonExhaustiveTypedField(A a) => switch (a) {
      A(:int field2) => 0,
    };
