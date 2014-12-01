// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("removes previous binstubs when reactivating a package", () {
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "one": null,
          "two": null
        }
      }),
          d.dir(
              "bin",
              [
                  d.file("one.dart", "main() => print('ok');"),
                  d.file("two.dart", "main() => print('ok');")])]).create();

    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);

    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          // Remove "one".
          "two": null
        }
      }),]).create();

    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);

    d.dir(
        cachePath,
        [
            d.dir(
                "bin",
                [
                    d.nothing(binStubName("one")),
                    d.matcherFile(binStubName("two"), contains("two"))])]).validate();
  });
}
