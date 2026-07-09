// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void doTest(Z a) {
    print(a.appName);
  }
}

class Z {
  final String? appName;
  Z({this.appName});
}

class X extends Base implements Z {}

class Base {
  String get appName => 'x';
}

void main() {
  Z();
  A().doTest(X());
}
