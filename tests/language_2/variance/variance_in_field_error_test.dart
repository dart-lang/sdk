// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous field usage for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

class A<in T> {
  final T a = null;
  //      ^
  // [analyzer] unspecified
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  final T Function() b = () => null;
  //                 ^
  // [analyzer] unspecified
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  T get c => null;
  //      ^
  // [analyzer] unspecified
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  T d;
  //^
  // [analyzer] unspecified
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  covariant T e;
  //          ^
  // [analyzer] unspecified
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.
}

mixin BMixin<in T> {
  final T a = null;
  //      ^
  // [analyzer] unspecified
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  final T Function() b = () => null;
  //                 ^
  // [analyzer] unspecified
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  T get c => null;
  //      ^
  // [analyzer] unspecified
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  T d;
  //^
  // [analyzer] unspecified
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  covariant T e;
  //          ^
  // [analyzer] unspecified
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.
}
