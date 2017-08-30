// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'lib/sources.dart';

class C {
  A1 f1;
  var f2 = A2;

  A3 m1(A4 a, [A5 b]) => null;
  A3 m2(A4 a, {A6 b}) => null;

  A7 get getter => null;
  void set setter(A8 v) {}
}
