// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import "package:expect/expect.dart";

void main() {
  // Make sure `runZonedGuarded` returns the result of a synchronous call.
  Expect.equals(
    499,
    runZonedGuarded(() => 499, (e, s) {
      Expect.fail("Unreachable");
    }),
  );
}
