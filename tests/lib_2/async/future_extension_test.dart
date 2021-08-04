// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async' show Completer, runZonedGuarded;
import '../../language/static_type_helper.dart';

void main() {
  testIgnore();
}

void testIgnore() {
  var future = Future<int>.value(42);
  captureStaticType(future.ignore(), <T>(T value) {
    Expect.equals(typeOf<void>(), T);
  });

  asyncStart();
  // Ignored futures can still be listend to.
  {
    var c = Completer<int>.sync();
    var f = c.future;
    f.ignore();
    asyncStart();
    f.catchError((e) {
      Expect.equals("ERROR1", e);
      asyncEnd();
      return 0;
    });
    c.completeError("ERROR1");
  }

  // Ignored futures are not uncaught errors.
  {
    asyncStart();
    bool threw = false;
    runZonedGuarded(() {
      var c = Completer<int>.sync();
      var f = c.future;
      f.ignore();
      c.completeError("ERROR2");
    }, (e, s) {
      threw = true;
      Expect.fail("Should not happen: $e");
    });
    Future.delayed(Duration.zero, () {
      if (threw) Expect.fail("Future not ignored.");
      asyncEnd();
    });
  }
  asyncEnd();
}
