// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that a boolean condition can be stored in a variable using a pattern
// assignment, or pattern variable declaration, and later used for type
// promotion.

import 'package:expect/static_type_helper.dart';

void patternAssignment(int? x) {
  bool b;
  (b) = x != null;
  if (b) {
    x.expectStaticType<Exactly<int>>();
  }
}

void patternVariableDeclaration(int? x) {
  var (b) = x != null;
  if (b) {
    x.expectStaticType<Exactly<int>>();
  }
}

main() {
  patternAssignment(0);
  patternVariableDeclaration(0);
}
