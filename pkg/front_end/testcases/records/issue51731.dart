// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
void main() {
  var o = (null, null, null, 42);
  (int?, String?, bool?, int?) nullable = o;
  FutureOr<(int?, String?, bool?, int?)> futornullable1 = nullable;
  FutureOr<(int?, String?, bool?, int?)> futornullable2 = o;
}
