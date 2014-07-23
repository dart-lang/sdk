// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'dart:async';

import 'package:expect/expect.dart';

class A {
  noSuchMethod(Invocation invocation) {
    return MirrorSystem.getName(invocation.memberName);
  }
}

var lines = [];
capturePrint(Zone self, ZoneDelegate parent, Zone origin, line) {
  lines.add(line);
}

runTests() {
  // No MirrorsUsed annotation anywhere.
  // Dart2js should retain all symbols.
  Expect.equals("foo", new A().foo);
  Expect.isTrue(lines.isEmpty);
  var barResult = new A().bar;
  Expect.equals("bar", barResult);
  Expect.isTrue(lines.isEmpty);
}

main() {
  runZoned(runTests,
           zoneSpecification: new ZoneSpecification(print: capturePrint));
}
