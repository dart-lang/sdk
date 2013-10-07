// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';

main() {
  initConfig();
  integration("ignores a Dart entrypoint in a dependency", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir("foo", [
      d.libPubspec("foo", "0.0.1"),
      d.dir("lib", [
        d.file("lib.dart", "main() => print('foo');")
      ])
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": "../foo"}
      })
    ]).create();

    startPubServe(shouldInstallFirst: true);
    requestShould404("web/packages/foo/lib.dart.js");
    endPubServe();
  });
}
