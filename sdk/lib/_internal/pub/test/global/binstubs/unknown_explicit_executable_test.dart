// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_stream.dart';

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("errors on an unknown explicit executable", () {
    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "executables": {
          "one": "one"
        }
      }),
      d.dir("bin", [
        d.file("one.dart", "main() => print('ok');")
      ])
    ]).create();

    var pub = startPub(args: [
      "global", "activate", "--source", "path", "../foo",
      "-x", "who", "-x", "one", "--executable", "wat"
    ]);

    pub.stdout.expect(consumeThrough("Installed executable one."));
    pub.stderr.expect("Unknown executables wat and who.");
    pub.shouldExit(exit_codes.DATA);
  });
}
