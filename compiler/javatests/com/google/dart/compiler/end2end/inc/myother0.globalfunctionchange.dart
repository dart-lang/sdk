// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of myApp;

class Other0 {
  static int value() { return 42; }

  int field_;

  Other0() : this.field_ = 42 { }
  int get field { return field_; }
}

int globalVar = 42;

// changed return type from int to num
num globalFunction() {
  return 42;
}
