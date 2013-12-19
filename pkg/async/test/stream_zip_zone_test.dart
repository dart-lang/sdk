// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:async/stream_zip.dart";
import "package:unittest/unittest.dart";

// Test that stream listener callbacks all happen in the zone where the
// listen occurred.

main() {
 StreamController controller;
 controller = new StreamController();
 testStream("singlesub-async", controller, controller.stream);
 controller = new StreamController.broadcast();
 testStream("broadcast-async", controller, controller.stream);
 controller = new StreamController();
 testStream("asbroadcast-async", controller,
                                 controller.stream.asBroadcastStream());

 controller = new StreamController(sync: true);
 testStream("singlesub-sync", controller, controller.stream);
 controller = new StreamController.broadcast(sync: true);
 testStream("broadcast-sync", controller, controller.stream);
 controller = new StreamController(sync: true);
 testStream("asbroadcast-sync", controller,
                                controller.stream.asBroadcastStream());
}

void testStream(String name, StreamController controller, Stream stream) {
  test(name, () {
    Zone outer = Zone.current;
    runZoned(() {
      Zone newZone1 = Zone.current;
      StreamSubscription sub;
      sub = stream.listen(expectAsync1((v) {
        expect(v, 42);
        expect(Zone.current, newZone1);
        outer.run(() {
          sub.onData(expectAsync1((v) {
            expect(v, 37);
            expect(Zone.current, newZone1);
            runZoned(() {
              Zone newZone2 = Zone.current;
              sub.onData(expectAsync1((v) {
                expect(v, 87);
                expect(Zone.current, newZone1);
              }));
            });
            controller.add(87);
          }));
        });
        controller.add(37);
      }));
    });
    controller.add(42);
  });
}
