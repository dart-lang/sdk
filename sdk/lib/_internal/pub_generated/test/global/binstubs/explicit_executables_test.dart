// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("only creates binstubs for the listed executables", () {
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "one": "script",
          "two": "script",
          "three": "script"
        }
      }),
          d.dir("bin", [d.file("script.dart", "main() => print('ok');")])]).create();

    schedulePub(
        args: [
            "global",
            "activate",
            "--source",
            "path",
            "../foo",
            "-x",
            "one",
            "--executable",
            "three"],
        output: contains("Installed executables one and three."));

    d.dir(
        cachePath,
        [
            d.dir(
                "bin",
                [
                    d.matcherFile(binStubName("one"), contains("pub global run foo:script")),
                    d.nothing(binStubName("two")),
                    d.matcherFile(
                        binStubName("three"),
                        contains("pub global run foo:script"))])]).validate();
  });
}
