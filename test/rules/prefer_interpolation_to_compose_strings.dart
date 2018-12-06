// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_interpolation_to_compose_strings`

void main() {
  String name = 'Juan'+'Pablo'; // OK // It is not the business of this rule
  int year = 2017;
  int birth = 1993;
  'Hello, $name! You are ${year - birth} years old.';
  'Hello, ' + // LINT
      name +
      '! You are ' +
      (year - birth).toString() +
      ' years old.';
  name += 'casanueva'; // OK (#813)

  int width = 10;
  String pad = '';
  for (int i = 0; i < width; i++) {
    pad = pad + ' '; // LINT
  }

  var str1 = 'Hello';
  var str2 = 'World';
  var str3 = str1 + str2; // OK (#735)
}
