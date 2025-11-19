// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

String test1(int? value) {
  switch (value) {
    case 55:
      return '55';
    case 352:
      return '352';
    case null:
      return 'null';
  }

  return 'no match';
}

String test2(int? value) {
  switch (value) {
    case null:
      return 'null';
  }
  return 'no match';
}

String test3(int? value) {
  switch (value) {
    case 10:
    case null:
      return 'null or 10';
    case 20:
      return '20';
  }

  return 'no match';
}

const nullConstant = null;

test4(int? value) {
  switch (value) {
    case nullConstant:
      return 'null';
  }

  return 'no match';
}

void main() {
  Expect.equals(test1(55), '55');
  Expect.equals(test1(352), '352');
  Expect.equals(test1(null), 'null');
  Expect.equals(test1(38792), 'no match');

  Expect.equals(test2(0), 'no match');
  Expect.equals(test2(null), 'null');

  Expect.equals(test3(10), 'null or 10');
  Expect.equals(test3(null), 'null or 10');
  Expect.equals(test3(20), '20');
  Expect.equals(test3(28132), 'no match');

  Expect.equals(test4(nullConstant), 'null');
  Expect.equals(test4(2189), 'no match');
}
