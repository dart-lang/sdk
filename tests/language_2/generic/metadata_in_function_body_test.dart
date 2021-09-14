// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Check that annotations inside function bodies cannot use type arguments, but
// can be raw.

// @dart=2.11

class C<T> {
  const C();
}

void ignore(dynamic value) {}

main() {
  @C()
  @C<dynamic>()
  //^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] An annotation can't use type arguments.
  @C<int>()
  //^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] An annotation can't use type arguments.
  int i = 0;
  ignore(i);
}
