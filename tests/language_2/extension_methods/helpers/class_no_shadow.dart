// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

const String instanceValue = "1";

void checkInstanceValue(String other) {
  Expect.equals(other, instanceValue);
}

// A class which has only its own instance methods
class A {
  String fieldInInstanceScope = instanceValue;
  String get getterInInstanceScope => instanceValue;
  set setterInInstanceScope(String x) {
    checkInstanceValue(x);
  }

  String methodInInstanceScope() => instanceValue;
}
