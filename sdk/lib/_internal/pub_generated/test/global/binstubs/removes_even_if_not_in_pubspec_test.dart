// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("removes all binstubs for package", () {
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "foo": null
        }
      }),
          d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();

    // Create the binstub for foo.
    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);

    // Remove it from the pubspec.
    d.dir("foo", [d.pubspec({
        "name": "foo"
      })]).create();

    // Deactivate.
    schedulePub(args: ["global", "deactivate", "foo"]);

    // It should still be deleted.
    d.dir(
        cachePath,
        [d.dir("bin", [d.nothing(binStubName("foo"))])]).validate();
  });
}
