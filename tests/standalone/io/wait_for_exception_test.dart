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
  runZonedGuarded(() {
    Timer.run(() {
      asyncEnd();
      throw "Error";
    });
  }, (e, s) {
    Expect.isTrue(e is String);
    c.complete(true);
  });
  Expect.isTrue(waitFor<bool>(c.future));
}
