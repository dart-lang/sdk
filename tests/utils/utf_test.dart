// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf_test;
import 'dart:utf';

main() {
  String str = new String.fromCharCodes([0x1d537]);
  // String.charCodes gives the original code points and String.codeUnits
  // gives back 16-bit code units
  Expect.listEquals([0xd835, 0xdd37], str.codeUnits);
  Expect.listEquals([0x1d537], str.charCodes);
}
