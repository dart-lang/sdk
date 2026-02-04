// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test1(bool c1, bool c2) {
  if (c1) {
    print(1);
  }
  print(2);
  if (c2) {
    print(3);
    return;
  }
  print(4);
}

void test2() {
  for (var i = 0; i < 10; ++i) {
    if (i > 3) {
      print('done');
      return;
    }
  }
}

void test3() {
  for (var i = 0; i < 10; ++i) {
    for (var j = 0; j < 10; ++j) {
      if (i + j > 10) {
        print('done');
        break;
      }
    }
  }
}

void test4(bool c1) {
  if (c1) {
    throw 'Error';
  }
  print('ok');
}

void main() {}
