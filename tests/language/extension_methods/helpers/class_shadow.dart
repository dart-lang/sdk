// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "class_no_shadow.dart";

// A class which has its own instance methods, which also
// shadows the global scope
class AGlobal extends A {
  String fieldInGlobalScope = instanceValue;
  String get getterInGlobalScope => instanceValue;
  set setterInGlobalScope(String x) {
    checkInstanceValue(x);
  }

  String methodInGlobalScope() => instanceValue;
}
