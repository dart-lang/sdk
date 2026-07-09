// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when we are trying to use a static method from the wrapped type of an
// extension type.

import '../dot_shorthand_helper.dart';

extension type ExtensionType(int integer) {}

void main() {
  ExtensionType x = .parse('1'); // int.parse('1');
  //                 ^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'parse' isn't defined for the type 'ExtensionType'.
}
