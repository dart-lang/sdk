// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('snapshots the executables for a hosted package', () {
    servePackages((builder) {
      builder.serve(
          "foo",
          "1.0.0",
          contents: [
              d.dir(
                  'bin',
                  [
                      d.file("hello.dart", "void main() => print('hello!');"),
                      d.file("goodbye.dart", "void main() => print('goodbye!');"),
                      d.file("shell.sh", "echo shell"),
                      d.dir("subdir", [d.file("sub.dart", "void main() => print('sub!');")])])]);
    });

    schedulePub(
        args: ["global", "activate", "foo"],
        output: allOf(
            [contains('Precompiled foo:hello.'), contains("Precompiled foo:goodbye.")]));

    d.dir(
        cachePath,
        [
            d.dir(
                'global_packages',
                [
                    d.dir(
                        'foo',
                        [
                            d.matcherFile('pubspec.lock', contains('1.0.0')),
                            d.dir(
                                'bin',
                                [
                                    d.matcherFile('hello.dart.snapshot', contains('hello!')),
                                    d.matcherFile('goodbye.dart.snapshot', contains('goodbye!')),
                                    d.nothing('shell.sh.snapshot'),
                                    d.nothing('subdir')])])])]).validate();
  });
}
