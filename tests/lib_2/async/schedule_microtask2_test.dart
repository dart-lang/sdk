// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library run_async_test;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'dart:async';

main() {
  int lastCallback = -1;
  for (int i = 0; i < 100; i++) {
    asyncStart();
    scheduleMicrotask(() {
      Expect.equals(lastCallback, i - 1);
      lastCallback = i;
      asyncEnd();
    });
  }
}
