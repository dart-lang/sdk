// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void testOneByteSting() {
  // Compare one-byte-string toLowerCase with a two-byte-string toLowerCase.
  var oneByteString =
      new String.fromCharCodes(new List.generate(256, (i) => i)).toLowerCase();
  var twoByteString =
      new String.fromCharCodes(new List.generate(512, (i) => i)).toLowerCase();
  Expect.isTrue(twoByteString.codeUnits.any((u) => u >= 256));
  Expect.equals(oneByteString, twoByteString.substring(0, 256));
}

void main() {
  testOneByteSting();
}
