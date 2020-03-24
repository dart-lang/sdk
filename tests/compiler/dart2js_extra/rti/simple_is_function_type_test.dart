// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
//
// dart2jsOptions=--experiment-new-rti

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

int fnInt2Int(int x) => x;
int fnIntOptInt2Int(int x, [int y = 0]) => x + y;

main() {
  Expect.isTrue(fnInt2Int is int Function(int));

  Expect.isTrue(fnInt2Int is void Function(int));
  Expect.isFalse(fnInt2Int is int Function());

  Expect.isTrue(fnIntOptInt2Int is int Function(int, [int]));

  Expect.isTrue(fnIntOptInt2Int is int Function(int, int));
  Expect.isTrue(fnIntOptInt2Int is int Function(int));
}
