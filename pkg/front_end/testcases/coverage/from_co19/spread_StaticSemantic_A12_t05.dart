// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/co19/src/LanguageFeatures/Spread-collections/StaticSemantic_A12_t05.dart

// @dart=3.4

void foo() {
  Map m1 = {...m1}; // Error
  Map m2 = {...{...m2}};  // Error
  Map m3 = {...{m3}}; // Error
  Map m4 = {...?m4}; // Error
  Map m5 = {...{...?m5}}; // Error
  Map m6 = {...{?m6}}; // Error
}
