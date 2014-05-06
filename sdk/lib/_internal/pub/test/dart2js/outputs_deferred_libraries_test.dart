// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

const MAIN = """
import 'dart:async';

@lazyA import 'a.dart' as a;
@lazyB import 'b.dart' as b;

const lazyA = const DeferredLibrary('a', uri: 'a.js');
const lazyB = const DeferredLibrary('b', uri: 'b.js');

void main() {
  Future.wait([lazyA.load(), lazyB.load()]).then((_) {
    a.fn();
    b.fn();
  });
}
""";

const A = """
library a;

fn() => print("a");
""";

const B = """
library b;

fn() => print("b");
""";

main() {
  initConfig();
  integration("compiles deferred libraries to separate outputs", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('main.dart', MAIN),
        d.file('a.dart', A),
        d.file('b.dart', B)
      ])
    ]).create();

    schedulePub(args: ["build"],
        output: new RegExp(r'Built 4 files to "build".'));

    d.dir(appPath, [
      d.dir('build', [
        d.dir('web', [
          d.matcherFile('main.dart.js', isNot(isEmpty)),
          d.matcherFile('main.dart.precompiled.js', isNot(isEmpty)),
          d.matcherFile('main.dart.js_a.part.js', isNot(isEmpty)),
          d.matcherFile('main.dart.js_b.part.js', isNot(isEmpty)),
        ])
      ])
    ]).validate();
  });
}
