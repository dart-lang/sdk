// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

extension Extension on Class {
  instanceMethod() {}
  get instanceProperty => 42;
  set instanceProperty(value) {}
}

main() {
  Extension.instanceMethod();
  Extension.instanceMethod;
  Extension.instanceProperty;
  Extension.instanceProperty = 42;
}