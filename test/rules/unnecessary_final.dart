// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_final`

void badMethod(final int x) { // LINT
  final label = 'Final or var?'; // LINT
  print(label);
  for (final char in ['v', 'a', 'r']) { // LINT
    print(((final String char) => char.length)(char)); // LINT
  }
}

void goodMethod(int x) {
  var label = 'Final or var?'; // OK
  print(label);
  for (var char in ['v', 'a', 'r']) { // OK
    print(((String char) => char.length)(char)); // OK
  }
}

class GoodClass {
  final int x = 3; // OK
}
