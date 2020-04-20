// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

main() {
  asyncStart();
  // Ensure that `runZoned`'s onError handles synchronous errors.
  runZonedGuarded(() {
    throw 0;
  }, (e, s) {
    Expect.equals(0, e);
    asyncEnd();
  });
}
