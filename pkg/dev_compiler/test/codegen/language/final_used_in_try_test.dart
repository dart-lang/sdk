// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  while (true) {
    final a = 'fff'.substring(1, 2);
    try {
      Expect.equals('f', a);
    } catch (e) {
      rethrow;
    }
    break;
  }
}
