// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import "package:expect/expect.dart";

void main() {
  // Ensure that `runZoned`'s onError handles synchronous errors, and throwing
  // in the error handler at that point (when it is a synchronous error) yields
  // a synchronous error.
  bool handleReached = false;
  runZonedGuarded(
    () {
      throw 0;
    },
    (e, s) {
      handleReached = true;
      Expect.equals(0, e);
    },
  );
  Expect.isTrue(handleReached);

  handleReached = false;
  try {
    runZonedGuarded(
      () {
        throw 0;
      },
      (e, s) {
        Expect.equals(0, e);
        throw e; // Rethrow in error handler.
      },
    );
  } catch (e) {
    Expect.equals(0, e);
    handleReached = true;
  }
  Expect.isTrue(handleReached);
}
