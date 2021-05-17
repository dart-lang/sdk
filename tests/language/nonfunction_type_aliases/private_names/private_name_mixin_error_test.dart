// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that a private mixin exported via a typedef cannot be used as a class.

import "private_name_library.dart";

/// Class that attempts to use a private mixin as a class via a public typedef
/// name.
class A0 extends PublicMixin {}
//    ^
// [cfe] The superclass, '_PrivateMixin', has no unnamed constructor that takes no arguments.
//               ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENDS_NON_CLASS

void main() {}
