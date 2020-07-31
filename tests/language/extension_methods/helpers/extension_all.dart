// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "class_no_shadow.dart";

const double otherExtensionValue = 1.234;

void checkOtherExtensionValue(double other) {
  Expect.equals(other, otherExtensionValue);
}

// An extension which defines all symbols
extension ExtraExt on A {
  double get fieldInGlobalScope => otherExtensionValue;
  double get getterInGlobalScope => otherExtensionValue;
  set setterInGlobalScope(double x) {
    checkOtherExtensionValue(x);
  }

  double methodInGlobalScope() => otherExtensionValue;

  double get fieldInInstanceScope => otherExtensionValue;
  double get getterInInstanceScope => otherExtensionValue;
  set setterInInstanceScope(double x) {
    checkOtherExtensionValue(x);
  }

  double methodInInstanceScope() => otherExtensionValue;

  double get fieldInExtensionScope => otherExtensionValue;
  double get getterInExtensionScope => otherExtensionValue;
  set setterInExtensionScope(double x) {
    checkOtherExtensionValue(x);
  }

  double methodInExtensionScope() => otherExtensionValue;

  double get fieldInOtherExtensionScope => otherExtensionValue;
  double get getterInOtherExtensionScope => otherExtensionValue;
  set setterInOtherExtensionScope(double x) {
    checkOtherExtensionValue(x);
  }

  double methodInOtherExtensionScope() => otherExtensionValue;
}
