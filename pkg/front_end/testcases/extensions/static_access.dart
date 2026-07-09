// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

extension Extension on Class {
  static method() {}
  static genericMethod<T>(T t) {}
  static get property => 42;
  static set property(value) {}
  static var field;

  instanceMethod() {}
  get instanceProperty => 42;
  set instanceProperty(value) {}
}

main() {
  Extension.method();
  Extension.genericMethod(42);
  Extension.genericMethod<num>(42);
  Extension.method;
  Extension.genericMethod;
  Extension.property;
  Extension.property = 42;
  Extension.field;
  Extension.field = 42;
}
