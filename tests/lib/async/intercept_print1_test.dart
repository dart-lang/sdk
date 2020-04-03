// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'catch_errors.dart';

var events = [];

void printHandler1(Zone self, ZoneDelegate parent, Zone origin, String line) {
  events.add("print: $line");
}

bool shouldIntercept = true;

void printHandler2(Zone self, ZoneDelegate parent, Zone origin, String line) {
  if (shouldIntercept) {
    events.add("print **: $line");
  } else {
    parent.print(origin, line);
  }
}

const TEST_SPEC1 = const ZoneSpecification(print: printHandler1);
const TEST_SPEC2 = const ZoneSpecification(print: printHandler2);

main() {
  Zone zone1 = Zone.current.fork(specification: TEST_SPEC1);
  Zone zone2 = zone1.fork(specification: TEST_SPEC2);
  zone1.run(() {
    print("1");
    print(2);
    print({
      3: [4]
    });
  });
  zone2.run(() {
    print("5");
    shouldIntercept = false;
    print(6);
  });
  Expect.listEquals(
      ["print: 1", "print: 2", "print: {3: [4]}", "print **: 5", "print: 6"],
      events);
}
