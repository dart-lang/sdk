// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_stream.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration(
      "creates a snapshot for an immediate dependency's executables",
      () {
    servePackages((builder) {
      builder.serve(
          "foo",
          "5.6.7",
          contents: [
              d.dir("bin", [d.file("hello.dart", "void main() => print('hello!');")])]);
    });

    d.appDir({
      "foo": "5.6.7"
    }).create();

    pubGet(output: contains("Precompiled foo:hello."));

    d.dir(
        p.join(appPath, '.pub', 'bin'),
        [d.dir('foo', [d.outOfDateSnapshot('hello.dart.snapshot')])]).create();

    var process = pubRun(args: ['foo:hello']);

    // In the real world this would just print "hello!", but since we collect
    // all output we see the precompilation messages as well.
    process.stdout.expect("Precompiling executables...");
    process.stdout.expect(consumeThrough("hello!"));
    process.shouldExit();

    d.dir(
        p.join(appPath, '.pub', 'bin'),
        [
            d.file('sdk-version', '0.1.2+3'),
            d.dir(
                'foo',
                [d.matcherFile('hello.dart.snapshot', contains('hello!'))])]).create();
  });
}
