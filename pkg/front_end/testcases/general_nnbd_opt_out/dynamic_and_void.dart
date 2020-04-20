// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// dynamic is treated as a name exported by dart:core.  void is not treated as a
// name exported by dart:core.

import 'dart:core' show int;

dynamic testDynamic() => 0;
void testVoid() {}

main() {}
