// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:cli';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

main() {
  asyncStart();
  Completer<bool> c = new Completer<bool>();
  Expect.throws(() {
    waitFor<bool>(c.future, timeout: const Duration(seconds: 1));
  }, (e) => e is TimeoutException);
  asyncEnd();
}
