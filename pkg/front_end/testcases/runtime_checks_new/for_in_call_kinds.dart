// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

var topLevel;
void set topLevelSetter(x) {}

class C {
  static var staticField;
  static void set staticSetter(x) {}
  var instanceField;
  void set instanceSetter(x) {}
  void test() {
    var localVar;
    for (topLevel in []) {}
    for (topLevelSetter in []) {}
    for (staticField in []) {}
    for (staticSetter in []) {}
    for (instanceField in []) {}
    for (instanceSetter in []) {}
    for (localVar in []) {}
  }
}

main() {}
