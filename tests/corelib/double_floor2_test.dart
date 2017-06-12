// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.throws(() => double.INFINITY.floor(), (e) => e is UnsupportedError);
  Expect.throws(
      () => double.NEGATIVE_INFINITY.floor(), (e) => e is UnsupportedError);
  Expect.throws(() => double.NAN.floor(), (e) => e is UnsupportedError);
}
