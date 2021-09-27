// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async' show Completer, runZonedGuarded, unawaited;
import 'dart:async' as prefix;
import '../../language/static_type_helper.dart';

void main() {
  testUnawaited();
}

void testUnawaited() {
  // Exists where expected.
  prefix.unawaited.expectStaticType<Exactly<void Function(Future<Object?>?)>>();

  var future = Future<int>.value(42);
  captureStaticType(unawaited(future), <T>(value) {
    Expect.equals(typeOf<void>(), T);
  });

  Future<Never>? noFuture = null;
  unawaited(noFuture); // Doesn't throw on null.

  asyncStart();
  // Unawaited futures still throw.
  {
    var c = Completer<int>();
    var f = c.future;
    unawaited(f);
    asyncStart();
    f.catchError((e) {
      Expect.equals("ERROR1", e);
      asyncEnd();
      return 0;
    });
    c.completeError("ERROR1");
  }
  // Unawaited futures are still uncaught errors.
  {
    asyncStart();
    runZonedGuarded(() {
      var c = Completer<int>();
      var f = c.future;
      unawaited(f);
      c.completeError("ERROR2");
    }, (e, s) {
      Expect.equals("ERROR2", e);
      asyncEnd();
    });
  }
  asyncEnd();
}
