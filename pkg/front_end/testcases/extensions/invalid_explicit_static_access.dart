// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on String {
  static method() {}
  static get getter => null;
  static set setter(_) {}
  static get property => null;
  static set property(_) {}
  static var field;
}

main() {}

errors() {
  String s = "";
  Extension(s).method();
  Extension(s).method;
  Extension(s).method = 42;
  Extension(s).getter;
  Extension(s).getter = 42;
  Extension(s).setter;
  Extension(s).setter = 42;
  Extension(s).property;
  Extension(s).property = 42;
  Extension(s).field;
  Extension(s).field = 42;
}
