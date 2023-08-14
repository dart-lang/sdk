// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

// Test the behavior of mixing in classes defined in a 3.0 library (both SDK
// and non SDK) when the mixin happens in a pre 3.0 library.

import 'dart:collection';
import 'mixin_class_lib.dart';

/// Test mixing in things from the SDK core libraries.

/// Test that it is not an error to mix in a class (which is not marked as a
/// mixin class) from the core libraries if it was valid to do so pre 3.0.
class A with Comparable<int> {
  int compareTo(int x) => 0;
}

/// Test that it is not an error to mix in a mixin from the core libraries even
/// if it has a generative constructor.
abstract class B with Iterable<int> {}

/// Test that it continues to be an error to mix in a class (which is not marked
/// as a mixin class) from the core libraries if it was not valid to do so pre
/// 3.0.
class C with Error {}
//    ^
// [cfe] Can't use 'Error' as a mixin because it has constructors.
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR

/// Test mixing in things from the non-SDK libraries.

/// Test that it is an error to mix in a class (which is not marked as a mixin
/// class) from a 3.0 non core library.
class D with NotAMixinClass {}
//           ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'NotAMixinClass' can't be used as a mixin because it isn't a mixin class nor a mixin.

/// Test that it is not an error to mix in a mixin class from a 3.0 non core
/// library.
class E with Class {}

void main() {}
