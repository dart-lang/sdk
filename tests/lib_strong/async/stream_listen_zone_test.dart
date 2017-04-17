// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_listen_zeno_test;

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

main() {
  asyncStart();
  var controller;
  for (bool overrideDone in [false, true]) {
    for (bool sync in [false, true]) {
      var mode = "${sync ? "-sync" : ""}${overrideDone ? "-od": ""}";
      controller = new StreamController(sync: sync);
      testStream("SC$mode", controller, controller.stream, overrideDone);
      controller = new StreamController.broadcast(sync: sync);
      testStream("BSC$mode", controller, controller.stream, overrideDone);
      controller = new StreamController(sync: sync);
      testStream("SCAB$mode", controller, controller.stream.asBroadcastStream(),
          overrideDone, 3);
      controller = new StreamController(sync: sync);
      testStream("SCMap$mode", controller, controller.stream.map((x) => x),
          overrideDone, 3);
    }
  }
  asyncEnd();
}

void testStream(
    String name, StreamController controller, Stream stream, bool overrideDone,
    [int registerExpect = 0]) {
  asyncStart();
  StreamSubscription sub;
  Zone zone;
  int registerCount = 0;
  int callbackBits = 0;
  int stepCount = 0;
  Function step;
  void nextStep() {
    Zone.ROOT.scheduleMicrotask(step);
  }

  runZoned(() {
    zone = Zone.current;
    sub = stream.listen((v) {
      Expect.identical(zone, Zone.current, name);
      Expect.equals(42, v, name);
      callbackBits |= 1;
      nextStep();
    }, onError: (e, s) {
      Expect.identical(zone, Zone.current, name);
      Expect.equals("ERROR", e, name);
      callbackBits |= 2;
      nextStep();
    }, onDone: () {
      Expect.identical(zone, Zone.current, name);
      if (overrideDone) throw "RUNNING WRONG ONDONE";
      callbackBits |= 4;
      nextStep();
    });
    registerExpect += 3;
    Expect.equals(registerExpect, registerCount, name);
  },
      zoneSpecification:
          new ZoneSpecification(registerCallback: (self, p, z, callback()) {
        Expect.identical(zone, self, name);
        registerCount++;
        return () {
          Expect.identical(zone, Zone.current, name);
          callback();
        };
      }, registerUnaryCallback: (self, p, z, callback(a)) {
        Expect.identical(zone, self, name);
        registerCount++;
        return (a) {
          Expect.identical(zone, Zone.current, name);
          callback(a);
        };
      }, registerBinaryCallback: (self, package, z, callback(a, b)) {
        Expect.identical(zone, self, name);
        registerCount++;
        return (a, b) {
          Expect.identical(zone, Zone.current, name);
          callback(a, b);
        };
      }));

  int expectedBits = 0;
  step = () {
    var stepName = "$name-$stepCount";
    Expect.identical(Zone.ROOT, Zone.current, stepName);
    Expect.equals(expectedBits, callbackBits, stepName);
    switch (stepCount++) {
      case 0:
        expectedBits |= 1;
        controller.add(42);
        break;
      case 1:
        expectedBits |= 2;
        controller.addError("ERROR", null);
        break;
      case 2:
        Expect.equals(registerExpect, registerCount, stepName);
        sub.onData((v) {
          Expect.identical(zone, Zone.current, stepName);
          Expect.equals(37, v);
          callbackBits |= 8;
          nextStep();
        });
        Expect.equals(++registerExpect, registerCount, stepName);
        expectedBits |= 8;
        controller.add(37);
        break;
      case 3:
        Expect.equals(registerExpect, registerCount, stepName);
        sub.onError((e, s) {
          Expect.identical(zone, Zone.current);
          Expect.equals("BAD", e);
          callbackBits |= 16;
          nextStep();
        });
        Expect.equals(++registerExpect, registerCount, stepName);
        expectedBits |= 16;
        controller.addError("BAD", null);
        break;
      case 4:
        Expect.equals(registerExpect, registerCount, stepName);
        if (overrideDone) {
          sub.onDone(() {
            Expect.identical(zone, Zone.current);
            callbackBits |= 32;
            nextStep();
          });
          registerExpect++;
          expectedBits |= 32;
        } else {
          expectedBits |= 4;
        }
        Expect.equals(registerExpect, registerCount, stepName);
        controller.close();
        break;
      case 5:
        asyncEnd();
    }
  };
  step();
}
