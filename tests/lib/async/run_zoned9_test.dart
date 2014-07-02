// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'package:async_helper/async_helper.dart';

main() {
  asyncStart();
  // Ensure that `runZoned`'s onError handles synchronous errors but delegates
  // to the next runZoned when the handler returns false.
  bool sawInnerHandler = false;
  try {
    runZoned(() {
      runZoned(() { throw 0; },
               onError: (e) {
                 Expect.equals(0, e);
                 sawInnerHandler = true;
                 throw e;
               });
    }, onError: (e) {
      Expect.equals(0, e);
      Expect.isTrue(sawInnerHandler);
      // If we are waiting for an error, don't asyncEnd, but let it time out.
      if (false) /// 01: runtime error
        asyncEnd();
      throw e;   /// 01: continued
    });
  } catch (e) {
    // We should never see an error here.
    if (false)   /// 01: continued
      rethrow;
  }
}
