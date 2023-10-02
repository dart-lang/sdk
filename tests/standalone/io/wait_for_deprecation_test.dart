// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that attempting to use `waitFor` without enabling it
// causes an exception.

import 'dart:async';
import 'dart:cli';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

main() {
  asyncStart();
  Expect.throws<String>(() {
    waitFor(Future.delayed(Duration(milliseconds: 10)).whenComplete(asyncEnd));
  }, (v) {
    return v.contains('deprecated and disabled') &&
        v.contains('dartbug.com/52121') &&
        v.contains('enable_deprecated_wait_for');
  });
}
