// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  integration("detects a transformer cycle", () {
    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": ["myapp/transformer"],
        "dependencies": {'myapp': {'path': '../myapp'}}
      }),
      d.dir("lib", [
        d.file("transformer.dart", dartTransformer('foo')),
      ])
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": ["foo/transformer"],
        "dependencies": {'foo': {'path': '../foo'}}
      }),
      d.dir("lib", [
        d.file("transformer.dart", dartTransformer('myapp')),
      ])
    ]).create();

    createLockFile('myapp', sandbox: ['foo'], pkg: ['barback']);

    var process = startPubServe();
    process.shouldExit(1);
    process.stderr.expect(emitsLines(
        "Transformer cycle detected:\n"
        "  foo is transformed by myapp/transformer\n"
        "  myapp is transformed by foo/transformer"));
  });
}
