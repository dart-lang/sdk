// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a null stream expression produces a runtime error.
import 'package:async_helper/async_helper.dart';

void main() {
  asyncTest(() async {
    // Null stream.
    Stream<int> nullStream = null;
    asyncExpectThrows<Error>(
        () async => <int>[await for (var i in nullStream) 1]);
    asyncExpectThrows<Error>(
        () async => <int, int>{await for (var i in nullStream) 1: 1});
    asyncExpectThrows<Error>(
        () async => <int>{await for (var i in nullStream) 1});
  });
}
