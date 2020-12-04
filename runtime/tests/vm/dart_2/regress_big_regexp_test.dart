// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that RegExp compilation doesn't crash on a huge source string.

import 'package:expect/expect.dart';

void testBigRegExp(String source) {
  try {
    var re = new RegExp(source);
    Expect.isTrue(re.hasMatch(source));
  } catch (e) {
    // May throw an error containing
    Expect.isTrue(e.toString().contains('RegExp too big'));
  }
}

main() {
  testBigRegExp("a" * (0x10000 - 128));
  testBigRegExp(
      String.fromCharCodes(List.generate(0x10000 - 128, (x) => x + 128)));
}
