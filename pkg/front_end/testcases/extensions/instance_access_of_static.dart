// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
}

extension Extension1 on Class1 {
  static staticMethod() {
    print('Extension1.staticMethod()');
  }

  static get staticProperty {
    print('Extension1.staticProperty()');
  }
  static set staticProperty(int value) {
    print('Extension1.staticProperty($value)');
    value++;
  }

  static var staticField = 42;
}

main() {
  Class1 c = new Class1();
  c.staticMethod();
  c.staticMethod;
  c.staticProperty;
  c.staticProperty = 42;
  c.staticField;
  c.staticField = 42;
}