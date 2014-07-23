// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@MirrorsUsed(symbols: 'foo')
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
  // "foo" is in MirrorsUsed and should therefore always work.
  Expect.equals("foo", new A().foo);
  Expect.isTrue(lines.isEmpty);
  var barResult = new A().bar;
  Expect.equals("bar", barResult);           /// minif: ok
  Expect.isTrue(lines.length == 1);
  var line = lines.first;
  Expect.isTrue(line.contains("Warning") &&
                line.contains("bar") &&      /// minif: continued
                line.contains("minif"));
}

main() {
  runZoned(runTests,
           zoneSpecification: new ZoneSpecification(print: capturePrint));
}
