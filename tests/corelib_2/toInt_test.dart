// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Expect.equals(-0x80000001, (-0x80000001).toInt());
  Expect.equals(-0x80000000, (-0x80000000 - 0.7).toInt());
  Expect.equals(-0x80000000, (-0x80000000 - 0.3).toInt());
  Expect.equals(-0x7FFFFFFF, (-0x80000000 + 0.3).toInt());
  Expect.equals(-0x7FFFFFFF, (-0x80000000 + 0.7).toInt());
  Expect.equals(-0x7FFFFFFF, (-0x7FFFFFFF).toInt());
  Expect.equals(0x7FFFFFFE, (0x7FFFFFFE).toInt());
  Expect.equals(0x7FFFFFFE, (0x7FFFFFFF - 0.7).toInt());
  Expect.equals(0x7FFFFFFE, (0x7FFFFFFF - 0.3).toInt());
  Expect.equals(0x7FFFFFFF, (0x7FFFFFFF + 0.3).toInt());
  Expect.equals(0x7FFFFFFF, (0x7FFFFFFF + 0.7).toInt());
  Expect.equals(0x80000000, 0x80000000.toInt());
}
