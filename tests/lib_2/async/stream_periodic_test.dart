// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test merging streams.
library dart.test.stream_from_iterable;

import 'dart:async';

import 'package:async_helper/async_minitest.dart';

main() {
  test("stream-periodic1", () {
    Stream stream = new Stream.periodic(const Duration(milliseconds: 1));
    int receivedCount = 0;
    var subscription;
    subscription = stream.listen(expectAsync((data) {
      expect(data, isNull);
      receivedCount++;
      if (receivedCount == 5) {
        var future = subscription.cancel();
        expect(future, completes);
      }
    }, count: 5));
  });
}
