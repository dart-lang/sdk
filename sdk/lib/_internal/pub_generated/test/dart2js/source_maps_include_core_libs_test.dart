// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  // This test is a bit shaky. Since dart2js is free to inline things, it's
  // not precise as to which source libraries will actually be referenced in
  // the source map. But this tries to use a type in the core library
  // (StringBuffer) and validate that its source ends up in the source map.
  integration("Dart core libraries are available to source maps", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.file("main.dart", "main() => new StringBuffer().writeAll(['s']);"),
                    d.dir(
                        "sub",
                        [
                            d.file(
                                "main.dart",
                                "main() => new StringBuffer().writeAll(['s']);")])])]).create();

    schedulePub(
        args: ["build", "--mode", "debug"],
        output: new RegExp(r'Built \d+ files to "build".'),
        exitCode: 0);

    d.dir(
        appPath,
        [
            d.dir(
                "build",
                [
                    d.dir(
                        "web",
                        [
                            d.matcherFile(
                                "main.dart.js.map",
                                contains(r"packages/$sdk/lib/core/string_buffer.dart")),
                            d.dir(
                                "sub",
                                [
                                    d.matcherFile(
                                        "main.dart.js.map",
                                        contains(r"../packages/$sdk/lib/core/string_buffer.dart"))]),
                            d.dir(
                                "packages",
                                [
                                    d.dir(
                                        r"$sdk",
                                        [
                                            d.dir(
                                                "lib",
                                                [
                                                    d.dir(
                                                        r"core",
                                                        [
                                                            d.matcherFile(
                                                                "string_buffer.dart",
                                                                contains("class StringBuffer"))])])])])])])]).validate();
  });
}
