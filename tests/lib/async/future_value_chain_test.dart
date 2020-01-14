// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

main() {
  asyncStart();
  var errorFuture = new Future.error(499);
  errorFuture.catchError((x) {
    Expect.equals(499, x);
    var valueChainFuture = new Future.value(errorFuture);
    // The errorFuture must not be propagated immediately as we would otherwise
    // not have time to catch the error.
    valueChainFuture.catchError((error) {
      Expect.equals(499, error);
      asyncEnd();
    });
  });
}
