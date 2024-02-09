// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type ET1(num id) {
  void method(covariant int i) {}
  //          ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER_IN_EXTENSION_TYPE
  // [cfe] Can't have modifier 'covariant' in an extension type.
}

extension type ET2<T extends num>(T id) {
  void setter(covariant int x) {}
  //          ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER_IN_EXTENSION_TYPE
  // [cfe] Can't have modifier 'covariant' in an extension type.
}

extension type ET3(num id) {
  int operator +(covariant int other) => other + id.floor();
  //             ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER_IN_EXTENSION_TYPE
  // [cfe] Can't have modifier 'covariant' in an extension type.
}

extension type ET4(covariant num id) {}
//                 ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] Can't have modifier 'covariant' in a primary constructor.
