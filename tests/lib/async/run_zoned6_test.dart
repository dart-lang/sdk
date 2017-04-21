// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'package:async_helper/async_helper.dart';

main() {
  asyncStart();
  // Ensure that `runZoned`'s onError handles synchronous errors but delegates
  // to the top-level when the handler returns false.
  try {
    runZoned(() {
      throw 0;
    }, onError: (e) {
      Expect.equals(0, e);
               if (false) //# 01: runtime error
      asyncEnd();
               throw e; //# 01: runtime error
    });
  } catch (e) {
    // We should never see an error here.
    if (false) //# 01: continued
    rethrow;
  }
}
