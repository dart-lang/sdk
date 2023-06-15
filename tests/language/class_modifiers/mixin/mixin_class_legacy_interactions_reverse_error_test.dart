// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the behavior of mixing in classes defined in a pre 3.0 library
// when the mixin happens in a 3.0 library.

import 'mixin_class_legacy_lib.dart' as legacy;

/// Test mixing in things from the core libraries.

/// Test that it is an error to mix in a class (which is not marked as a
/// mixin class) from the core libraries in 3.0.
class A with Comparable<int> {
//           ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Comparable' can't be used as a mixin because it isn't a mixin class nor a mixin.
  int compareTo(int x) => 0;
}

/// Test mixing in things from a 3.0 library exported through a pre 3.0 library.

/// Test that it is an error to mix in a class (which is not marked as a mixin
/// class) from a 3.0 non core library exported through a pre 3.0 library
class B with legacy.NotAMixinClass {}
//           ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'NotAMixinClass' can't be used as a mixin because it isn't a mixin class nor a mixin.

/// Test that it is not an error to mix in a mixin class from a 3.0 non core
/// library exported through a pre 3.0 library.
class C with legacy.Class {}

/// Test mixing in things from a pre 3.0 library.

/// Test that it is not an error to mix in a class from a 3.0 non core library,
/// when it would have been valid to do so in a pre 3.0 library.
class D with legacy.LegacyNotAMixinClass {}

/// Test that it is an error to mix in a class from a 3.0 non core library,
/// when it would not have been valid to do so in a pre 3.0 library.
class E with legacy.LegacyNotAMixinClassWithConstructor {}
//    ^
// [cfe] Can't use 'LegacyNotAMixinClassWithConstructor' as a mixin because it has constructors.
//           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR

main() {}
