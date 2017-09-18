// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test merging streams.
library dart.test.stream_from_iterable;

import "dart:async";
import 'package:test/test.dart';

main() {
  test("stream-periodic1", () {
    Stream stream = new Stream.periodic(const Duration(milliseconds: 1), (i) {
      if (i == 3) throw 42;
      return i;
    });
    int expected = 0;
    var subscription;
    subscription = stream.listen(
        expectAsync((data) {
          expect(data, expected++);
          if (expected == 5) subscription.cancel();
        }, count: 4), onError: expectAsync((e, s) {
      expect(e, 42);
      expected++;
    }));
  });
}
