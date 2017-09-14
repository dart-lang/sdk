// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'causal_async_exception_stack_helper.dart' as h;

thrower() async {
  throw 'oops';
}

number() async {
  return 4;
}

generator() async* {
  yield await number();
  yield await thrower();
}

foo() async {
  await for (var i in generator()) {
    print(i);
  }
}

main() async {
  // Test async and async*.
  test('causal async exception stack', () async {
    try {
      await foo();
      fail("Did not throw");
    } catch (e, st) {
      expect(
          h.stringContainsInOrder(st.toString(), [
            'thrower', '.dart:9', //
            '<asynchronous suspension>', //
            'generator', '.dart:18', //
            '<asynchronous suspension>', //
            'foo', '.dart:22', //
            '<asynchronous suspension>', //
            'main', //
          ]),
          isTrue);
    }

    inner() async {
      deep() async {
        await thrower();
      }

      await deep();
    }

    // Test inner functions.
    try {
      await inner();
    } catch (e, st) {
      expect(
          h.stringContainsInOrder(st.toString(), [
            'thrower',
            '<asynchronous suspension>',
            'main.<anonymous closure>.inner.deep',
            '<asynchronous suspension>',
            'main.<anonymous closure>.inner',
            '<asynchronous suspension>',
            'main',
            '<asynchronous suspension>',
          ]),
          isTrue);
    }

    // Test for correct linkage.
    try {
      await thrower();
    } catch (e, st) {
      expect(
          h.stringContainsInOrder(st.toString(), [
            'thrower', '.dart:9', //
            '<asynchronous suspension>', //
            'main.<anonymous closure>', '.dart:75', //
          ]),
          isTrue);
    }
  });
}
