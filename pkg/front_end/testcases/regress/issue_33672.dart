// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  int count = 0;
  yield: for (int a = 0; a < 10; ++a) {
    for (int b = 0; b < 10; ++b) {
      ++count;
      if (count == 27) break yield;
    }
    ++count;
  }
  if (count != 27) throw 'failed: $count';
}
