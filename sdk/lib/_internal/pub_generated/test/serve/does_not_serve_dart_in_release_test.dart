// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("does not serve .dart files in release mode", () {

    d.dir(
        "foo",
        [d.libPubspec("foo", "0.0.1"), d.dir("lib", [d.file("foo.dart", """
            library foo;
            foo() => 'foo';
            """)])]).create();

    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }),
          d.dir("lib", [d.file("lib.dart", "lib() => print('hello');"),]),
          d.dir("web", [d.file("file.dart", """
            import 'package:foo/foo.dart';
            main() => print('hello');
            """),
            d.dir("sub", [d.file("sub.dart", "main() => 'foo';"),])])]).create();

    pubServe(shouldGetFirst: true, args: ["--mode", "release"]);
    requestShould404("file.dart");
    requestShould404("packages/myapp/lib.dart");
    requestShould404("packages/foo/foo.dart");
    requestShould404("sub/sub.dart");
    endPubServe();
  });
}
