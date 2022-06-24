// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'dart:async';

main() {
  asyncStart(2);
  () async {
    var it = new StreamIterator(new Stream.fromIterable([]));
    Expect.isFalse(await it.moveNext());

    late Future nullFuture;

    bool nullFutureZoneUsed = false;
    runZoned(() {
      // Known code that exposes the special "nullFuture".
      nullFuture = (new StreamController()..stream.listen(null).cancel()).done;
    }, zoneSpecification: new ZoneSpecification(scheduleMicrotask:
        (Zone self, ZoneDelegate parent, Zone zone, void f()) {
      Expect.identical(zone, self);
      nullFutureZoneUsed = true;
      parent.scheduleMicrotask(zone, f);
    }));

    nullFuture.then((value) {
      Expect.isNull(value);
      Expect.isTrue(nullFutureZoneUsed);
      asyncEnd();
    });

    late Future falseFuture;

    runZoned(() {
      falseFuture = it.moveNext();
    }, zoneSpecification: new ZoneSpecification(scheduleMicrotask:
        (Zone self, ZoneDelegate parent, Zone zone, void f()) {
      Expect.fail("Should not be called");
    }));

    falseFuture.then((value) {
      Expect.isFalse(value);
      asyncEnd();
    });
  }();
}
