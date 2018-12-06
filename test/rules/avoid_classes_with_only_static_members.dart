// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_classes_with_only_static_members`

class Bad { // LINT
  static int a;

  static foo() {}
}

class Bad2 extends Good1 { // LINT
  static int staticInt;

  static foo() {}
}

class Bad3 {} // OK

class Good1 { // OK
  int a = 0;
}

class Good2 { // OK
  void foo() {}
}

class Good3 { // OK
  Good3();
}

class Color { // OK
  static const red = '#f00';
  static const green = '#0f0';
  static const blue = '#00f';
  static const black = '#000';
  static const white = '#fff';
}
