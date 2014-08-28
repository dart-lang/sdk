// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration("doesn't create a snapshot for transitive dependencies' "
      "executables", () {
    servePackages((builder) {
      builder.serve("foo", "1.2.3", deps: {'bar': '1.2.3'});
      builder.serve("bar", "1.2.3", contents: [
        d.dir("bin", [d.file("hello.dart", "void main() => print('hello!');")])
      ]);
    });

    d.appDir({"foo": "1.2.3"}).create();

    pubGet();

    d.nothing(p.join(appPath, '.pub', 'bin', 'bar')).validate();
  });
}
