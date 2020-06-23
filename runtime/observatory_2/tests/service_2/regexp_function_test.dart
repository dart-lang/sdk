// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=
// VMOptions=--interpret_irregexp

import 'package:expect/expect.dart';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

// Make sure these variables are not removed by the tree shaker.
@pragma("vm:entry-point")
var regex0;
@pragma("vm:entry-point")
var regex;

void script() {
  // Check the internal NUL doesn't trip up the name scrubbing in the vm.
  regex0 = new RegExp("with internal \u{0} NUL");
  regex = new RegExp(r"(\w+)");
  String str = "Parse my string";
  Iterable<Match> matches = regex.allMatches(str); // Run to generate bytecode.
  Expect.equals(matches.length, 3);
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library lib = isolate.rootLibrary;
    await lib.load();

    Field field0 = lib.variables.singleWhere((v) => v.name == 'regex0');
    await field0.load(); // No crash due to embedded NUL.

    Field field = lib.variables.singleWhere((v) => v.name == 'regex');
    await field.load();
    Instance regex = field.staticValue;
    expect(regex.isInstance, isTrue);
    expect(regex.isRegExp, isTrue);
    await regex.load();

    if (regex.oneByteFunction == null) {
      // Running with interpreted regexp.
      var b1 = await regex.oneByteBytecode.load();
      expect(b1.isTypedData, isTrue);
      var b2 = await regex.twoByteBytecode.load();
      expect(b2.isTypedData, isFalse); // No two-byte string subject was used.
    } else {
      // Running with compiled regexp.
      var f1 = await regex.oneByteFunction.load();
      expect(f1 is ServiceFunction, isTrue);
      var f2 = await regex.twoByteFunction.load();
      expect(f2 is ServiceFunction, isTrue);
      var f3 = await regex.externalOneByteFunction.load();
      expect(f3 is ServiceFunction, isTrue);
      var f4 = await regex.externalTwoByteFunction.load();
      expect(f4 is ServiceFunction, isTrue);
    }
  }
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
