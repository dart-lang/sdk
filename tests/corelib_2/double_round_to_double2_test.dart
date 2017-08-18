// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0.0, 0.49999999999999994.roundToDouble());
  Expect.equals(0.0, (-0.49999999999999994).roundToDouble());
  Expect.isTrue(0.49999999999999994.roundToDouble() is double);
  Expect.isTrue((-0.49999999999999994).roundToDouble().isNegative);
  Expect.isTrue((-0.49999999999999994).roundToDouble() is double);
}
