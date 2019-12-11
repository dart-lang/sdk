// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:async_helper/async_minitest.dart";

/// Tests for exceptions raised in async*
main() {
  test('async* with Stream.first should complete with an error', () async {
    var expectedStack;
    Stream<int> foo() async* {
      try {
        throw 'oops';
      } catch (e, s) {
        expectedStack = s;
        try {
          throw 'oops again!';
        } catch (e2, _) {}
        await new Future.error(e, s);
      }
      yield 42;
    }

    try {
      await foo().first;
      fail('should not get here, an error should be thrown');
    } catch (e, s) {
      expect(e, 'oops');
      expect(s, expectedStack);
    }
  });
}
