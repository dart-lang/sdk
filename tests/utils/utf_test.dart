// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf_test;
import 'dart:utf';

main() {
  String str = codepointsToString([0x1d537]);
  // String.charCodes gives 16-bit code units, but stringToCodepoints gives
  // back the original code points.
  Expect.listEquals([0xd835, 0xdd37], str.charCodes);
  Expect.listEquals([0x1d537], stringToCodepoints(str));
}
