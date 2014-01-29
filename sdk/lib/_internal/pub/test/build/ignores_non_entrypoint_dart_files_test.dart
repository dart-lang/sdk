// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("ignores non-entrypoint Dart files", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('file1.dart', 'var main = () => print("hello");'),
        d.file('file2.dart', 'void main(arg1, arg2, arg3) => print("hello");'),
        d.file('file3.dart', 'class Foo { void main() => print("hello"); }'),
        d.file('file4.dart', 'var foo;')
      ])
    ]).create();

    schedulePub(args: ["build"],
        output: new RegExp(r"Built 0 files!"));

    d.dir(appPath, [
      d.dir('build', [
        d.nothing('web')
      ])
    ]).validate();
  });
}
