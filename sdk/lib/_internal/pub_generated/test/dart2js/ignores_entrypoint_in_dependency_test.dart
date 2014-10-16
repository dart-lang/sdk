// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  integration("ignores a Dart entrypoint in a dependency", () {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "0.0.1"),
            d.dir("lib", [d.file("lib.dart", "main() => print('foo');")])]).create();

    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      })]).create();

    pubServe(shouldGetFirst: true);
    requestShould404("web/packages/foo/lib.dart.js");
    endPubServe();
  });
}
