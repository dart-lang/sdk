// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--gc_at_throw --force_evacuation

import 'package:expect/expect.dart';
import 'dart:async';

controlFlow() {
  for (final FutureOr<T> Function<T>(T) func in <dynamic>[id, future]) {
    try {
      try {
        throw "string";
      } catch (e) {
        Expect.equals("string", e);
        rethrow;
      } finally {
        Expect.equals(0, func(0));
      }
    } catch (e) {
      Expect.equals("string", e);
    } finally {
      Expect.equals(0, func(0));
    }
  }
}

FutureOr<T> future<T>(T value) => value;
FutureOr<T> id<T>(T value) => value;

main() {
  for (int i = 0; i < 100; i++) {
    controlFlow();
  }
}
