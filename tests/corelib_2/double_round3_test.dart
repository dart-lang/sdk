// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:expect/expect.dart';

main() {
  Expect.equals(0, 0.49999999999999994.round());
  Expect.equals(0, (-0.49999999999999994).round());
  Expect.isTrue(0.49999999999999994.round() is int);
  Expect.isTrue((-0.49999999999999994).round() is int);
}
