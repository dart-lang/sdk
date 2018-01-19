// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:mirrors';
import 'dart:cli';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

main() {
  asyncStart();
  Completer<bool> c = new Completer<bool>();
  Timer.run(() {
    c.complete(true);
    asyncEnd();
  });
  bool result = waitFor<bool>(c.future);
  Expect.isTrue(result);
}
