// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "class_no_shadow.dart";

const double otherExtensionValue = 1.234;

void checkOtherExtensionValue(double other) {
  Expect.equals(other, otherExtensionValue);
}

// An extension which defines only its own symbols
extension ExtraExt on A {
  double get fieldInOtherExtensionScope => otherExtensionValue;
  double get getterInOtherExtensionScope => otherExtensionValue;
  set setterInOtherExtensionScope(double x) {
    checkOtherExtensionValue(x);
  }

  double methodInOtherExtensionScope() => otherExtensionValue;
}
