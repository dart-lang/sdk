// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is a compile-time error if an extension type does not contain a declaring
// constructor that has exactly one declaring parameter which is final. This is
// the test for in-header constructors

// SharedOptions=--enable-experiment=primary-constructors

extension type ET1(var int i);
//                 ^
// [analyzer] unspecified
// [cfe] unspecified

extension type ET2(var i);
//                 ^
// [analyzer] unspecified
// [cfe] unspecified

extension type ET3(final i, final x);
//                 ^
// [analyzer] unspecified
// [cfe] unspecified

// Two `final` declaring parameters are inferred.
extension type ET4(int i, int x);
//                 ^
// [analyzer] unspecified
// [cfe] unspecified

// A final modifier on the first parameter is inferred.
extension type ET5(int i, final x);
//                 ^
// [analyzer] unspecified
// [cfe] unspecified
