// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Super {
  var field = 0;

  get property => 0;
  set property(_) {}

  void method() {}
}

class Sub extends Super {
  var field = 1;

  get property => 1;
  set property(_) {}

  void method() {
    super.method();
    field = super.field = super.field + field;
    property = super.property = super.property + property;
  }
}

main() {
  var c = new Sub();
  c.method();
}
