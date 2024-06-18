// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() async {
  // Multiple for-loop wildcard declarations.
  for (int _ = 0, _ = 2;;) {
    print(_);
  }

  var list = [];
  for (var _ in list) {
    print(_);
  }

  var stream = Stream.empty();
  await for (var _ in stream) {
    print(_);
  }
}
