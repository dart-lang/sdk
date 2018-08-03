// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'package:async_helper/async_helper.dart';

main() {
  asyncStart();
  // Ensure that `runZoned`'s onError handles synchronous errors, and throwing
  // in the error handler at that point (when it is a synchronous error) yields
  // a synchronous error.
  try {
    runZoned(() {
      throw 0;
    }, onError: (e) {
      Expect.equals(0, e);
      throw e;  //#01 : ok
      asyncEnd();
    });
  } catch (e) {
    asyncEnd(); return;  //# 01: continued
    rethrow;
  }
}
