// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../serve/utils.dart';
import '../test_pub.dart';

main() {
  initConfig();

  // This test is a bit shaky. Since dart2js is free to inline things, it's
  // not precise as to which source libraries will actually be referenced in
  // the source map. But this tries to use a type in the core library
  // (StringBuffer) and validate that its source ends up in the source map.
  integration(
      "Dart core libraries are available to source maps when the "
          "build directory is a subdirectory",
      () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.dir(
                        "sub",
                        [
                            d.file(
                                "main.dart",
                                "main() => new StringBuffer().writeAll(['s']);")])])]).create();

    var webSub = path.join("web", "sub");
    pubServe(args: [webSub]);

    requestShouldSucceed(
        "main.dart.js.map",
        contains(r"packages/$sdk/lib/core/string_buffer.dart"),
        root: webSub);
    requestShouldSucceed(
        r"packages/$sdk/lib/core/string_buffer.dart",
        contains("class StringBuffer"),
        root: webSub);

    endPubServe();
  });
}
