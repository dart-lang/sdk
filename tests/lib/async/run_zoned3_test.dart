// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

main() {
  asyncStart();
  // Ensure that `runZoned` is done when a synchronous call throws.
  bool sawException = false;
  try {
    runZonedExperimental(() { throw 0; },
                         onDone: () {
                           // onDone is executed synchronously.
                           Expect.isFalse(sawException);
                           asyncEnd();
                         });
  } catch (e) {
    sawException = true;
  }
  Expect.isTrue(sawException);
}
