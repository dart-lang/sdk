// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  new();

  new named();

  factory fact();

  factory redirect();
}

augment class Class1 {
  augment new() {}

  augment new named() {}

  augment factory fact() => Class1();

  augment factory redirect() = Class1;
}

class Class2();

augment class Class2 {
  augment new() {}
}

class Class3();

augment class Class3() {
  augment this;
}

class Class4();

augment class Class4();
