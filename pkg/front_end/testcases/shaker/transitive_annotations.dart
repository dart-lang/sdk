// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'transitive_annotations_lib.dart';

class X1 extends C1 {
  @forMethod2
  void publicMethodX1() {}

  @B2(forSubexpression2)
  void publicMethodX2() {}

  @excludedOutline
  void _privateMethodX2() {}
}

C2<int> y1;

F1 y2;

int y3 = publicFunction1(0);
