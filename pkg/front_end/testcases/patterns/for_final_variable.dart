// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

testFor() {
  // Error
  for (final int i = 0; i < 3; i = i + 1) {
    print(i);
  }
  // Error
  for (final (int i) = 0; i < 3; i = i + 1) {
    print(i);
  }
  for (var (final int i, String s) = (0, ''); i < 3; i = i + 1) {
    print(i); // Error
  }
  for (var (int i, final String s) = (0, ''); i < 3; i = i + 1) {
    print(i); // Ok
  }
  var l1 = [
    for (final int i = 0; i < 3; i = i + 1) i, // Error
  ];
  var l2 = [
    for (final (int i) = 0; i < 3; i = i + 1) i, // Error
  ];
  var l3 = [
    for (var (final int i, String s) = (0, ''); i < 3; i = i + 1) i, // Error
  ];
  var l4 = [
    for (var (int i, final String s) = (0, ''); i < 3; i = i + 1) i, // Ok
  ];
}

testForIn() {
  for (final int i in [1, 2, 3]) {
    i = i + 1; // Error
  }
  for (final (int i) in [1, 2, 3]) {
    i = i + 1; // Error
  }
  for (var (final int i, String s) in [(1, 'a'), (2, 'b'), (3, 'c')]) {
    i = i + 1; // Error
  }
  for (var (int i, final String s) in [(1, 'a'), (2, 'b'), (3, 'c')]) {
    i = i + 1; // Ok
  }
  var l1 = [
    for (final int i in [1, 2, 3]) i = i + 1 // Error
  ];
  var l2 = [
    for (final (int i) in [1, 2, 3]) i = i + 1 // Error
  ];
  var l3 = [
    for (var (final int i, String s) in [(1, 'a'), (2, 'b'), (3, 'c')])
      i = i + 1 // Error
  ];
  var l4 = [
    for (var (int i, final String s) in [(1, 'a'), (2, 'b'), (3, 'c')])
      i = i + 1 // Ok
  ];
}
