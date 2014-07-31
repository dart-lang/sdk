// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_stream.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('gets dependencies before running if needed', () {
    d.dir("foo", [
      d.libPubspec("foo", "1.0.0", deps: {
        "bar": {"path": "../bar"}
      }),
      d.dir("bin", [
        d.file("foo.dart", "main() => print('ok');")
      ])
    ]).create();

    d.dir("bar", [
      d.libPubspec("bar", "1.0.0")
    ]).create();

    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);

    var pub = pubRun(global: true, args: ["foo"]);
    pub.stdout.expect(
        "Your pubspec has changed, so we need to update your lockfile:");
    pub.stdout.expect(consumeThrough("ok"));
    pub.shouldExit();
  });
}

