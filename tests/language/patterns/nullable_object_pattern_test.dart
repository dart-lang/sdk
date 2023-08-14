// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the appropriate errors are generated if a nullable type is used in
/// an object pattern.

import 'package:expect/expect.dart';

typedef A = int?;

bool nullableWithoutField(x) {
  // This is fine because all the implementation needs to do is a type test.
  switch (x) {
    case A():
      return true;
    default:
      return false;
  }
}

bool potentiallyNullableWithoutField<T extends int?>(x) {
  // This is fine because all the implementation needs to do is a type test.
  switch (x) {
    case T():
      return true;
    default:
      return false;
  }
}

bool nonNullableTypeArgument<T extends int>(x) {
  // This is fine error because `isEven` *can* be called on `int`.
  switch (x) {
    case T(isEven: true):
      return true;
    default:
      return false;
  }
}

bool nullableWithObjectFields(x) {
  // This is fine because the fields `hashCode` and `runtimeType` are defined on
  // `null`.
  switch (x) {
    case A(:var runtimeType, :var hashCode):
      Expect.equals(x.runtimeType, runtimeType);
      Expect.equals(x.hashCode, hashCode);
      return true;
    default:
      return false;
  }
}

main() {
  Expect.equals(true, nullableWithoutField(null));
  Expect.equals(true, nullableWithoutField(0));
  Expect.equals(false, nullableWithoutField(''));
  Expect.equals(true, potentiallyNullableWithoutField<int?>(null));
  Expect.equals(true, potentiallyNullableWithoutField<int?>(0));
  Expect.equals(false, potentiallyNullableWithoutField<int?>(''));
  Expect.equals(false, potentiallyNullableWithoutField<int>(null));
  Expect.equals(true, potentiallyNullableWithoutField<int>(0));
  Expect.equals(false, potentiallyNullableWithoutField<int>(''));
  Expect.equals(false, potentiallyNullableWithoutField<Never>(null));
  Expect.equals(false, potentiallyNullableWithoutField<Never>(0));
  Expect.equals(false, potentiallyNullableWithoutField<Never>(''));
  Expect.equals(false, nonNullableTypeArgument<int>(null));
  Expect.equals(true, nonNullableTypeArgument<int>(0));
  Expect.equals(false, nonNullableTypeArgument<int>(1));
  Expect.equals(false, nonNullableTypeArgument<int>(''));
  Expect.equals(false, nonNullableTypeArgument<Never>(null));
  Expect.equals(false, nonNullableTypeArgument<Never>(0));
  Expect.equals(false, nonNullableTypeArgument<Never>(1));
  Expect.equals(false, nonNullableTypeArgument<Never>(''));
  Expect.equals(true, nullableWithObjectFields(null));
  Expect.equals(true, nullableWithObjectFields(0));
  Expect.equals(false, nullableWithObjectFields(''));
}
