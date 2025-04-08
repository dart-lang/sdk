// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Erroneous ways to use shorthands for simple identifiers and const simple
// identifiers.

// SharedOptions=--enable-experiment=dot-shorthands

import '../dot_shorthand_helper.dart';

void main() {
  var color = .blue;
  //           ^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'blue'.

  const constColor = .blue;
  //                  ^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'blue'.

  var integer = .one;
  //             ^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'one'.

  const constInteger = .one;
  //                    ^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'one'.

  Integer i = .one();
  //          ^
  // [analyzer] unspecified
  // [cfe] The method 'call' isn't defined for the class 'Integer'.
}
