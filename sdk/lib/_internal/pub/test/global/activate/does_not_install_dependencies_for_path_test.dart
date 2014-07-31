// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('activating a path package does not install dependencies', () {
    d.dir("foo", [
      d.libPubspec("foo", "1.0.0", deps: {
        "bar": "any"
      }),
      d.dir("bin", [
        d.file("foo.dart", "main() => print('ok');")
      ])
    ]).create();

    schedulePub(args: ["global", "activate", "--source", "path", "../foo"],
        output: "Activated foo 1.0.0.");
  });
}
