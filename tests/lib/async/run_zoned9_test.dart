// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import "package:expect/expect.dart";

void main() {
  // Ensure that `runZonedGuarded`'s onError handles synchronous errors but
  // delegates to the next runZoned when the handler throws.

  bool innerHandlerReached = false;
  bool outerHandlerReached = false;
  runZonedGuarded(
    () {
      runZonedGuarded(
        () {
          throw 0;
        },
        (e, s) {
          Expect.equals(0, e);
          innerHandlerReached = true;
          throw e;
        },
      );
    },
    (e, s) {
      Expect.equals(0, e);
      Expect.isTrue(innerHandlerReached);
      outerHandlerReached = true;
      // Do not rethrow.
    },
  );
  Expect.isTrue(outerHandlerReached);
  Expect.isTrue(innerHandlerReached);

  innerHandlerReached = false;
  outerHandlerReached = false;
  bool catchReached = false;
  try {
    runZonedGuarded(
      () {
        runZonedGuarded(
          () {
            throw 0;
          },
          (e, s) {
            Expect.equals(0, e);
            innerHandlerReached = true;
            throw e;
          },
        );
      },
      (e, s) {
        Expect.equals(0, e);
        Expect.isTrue(innerHandlerReached);
        outerHandlerReached = true;
        throw e; // Throw in outer.
      },
    );
  } catch (e) {
    Expect.equals(0, e);
    Expect.isTrue(innerHandlerReached);
    Expect.isTrue(outerHandlerReached);
    catchReached = true;
  }
  Expect.isTrue(innerHandlerReached);
  Expect.isTrue(outerHandlerReached);
  Expect.isTrue(catchReached);
}
