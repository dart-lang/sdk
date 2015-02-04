// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  setUp(() {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                'web',
                [
                    d.file('file1.dart', 'var main = () => print("hello");'),
                    d.file('file2.dart', 'void main(arg1, arg2, arg3) => print("hello");'),
                    d.file('file3.dart', 'class Foo { void main() => print("hello"); }'),
                    d.file('file4.dart', 'var foo;')])]).create();
  });

  integration("build ignores non-entrypoint Dart files", () {
    schedulePub(
        args: ["build"],
        output: new RegExp(r'Built 0 files to "build".'));

    d.dir(appPath, [d.dir('build', [d.nothing('web')])]).validate();
  });

  integration("serve ignores non-entrypoint Dart files", () {
    pubServe();
    requestShould404("file1.dart.js");
    requestShould404("file2.dart.js");
    requestShould404("file3.dart.js");
    requestShould404("file4.dart.js");
    endPubServe();
  });

}
