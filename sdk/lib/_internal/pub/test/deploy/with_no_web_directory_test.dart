// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("with no web directory", () {
    d.appDir().create();

    schedulePub(args: ["deploy"],
        error: new RegExp(r"^There is no '[^']+[/\\]web' directory.$",
            multiLine: true),
        exitCode: 1);
  });
}
