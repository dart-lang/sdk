// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Erroneous ways to use shorthands for simple identifiers and const simple
// identifiers.

// SharedOptions=--enable-experiment=dot-shorthands

import '../enum_shorthand_helper.dart';

void main() {
  var color = .blue;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const constColor = .blue;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  var integer = .one;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const constInteger = .one;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
