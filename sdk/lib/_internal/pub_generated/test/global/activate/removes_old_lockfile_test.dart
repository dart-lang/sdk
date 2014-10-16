// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('removes the 1.6-style lockfile', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
    });

    d.dir(
        cachePath,
        [
            d.dir(
                'global_packages',
                [
                    d.file(
                        'foo.lock',
                        'packages: {foo: {description: foo, source: hosted, '
                            'version: "1.0.0"}}}')])]).create();

    schedulePub(args: ["global", "activate", "foo"]);

    d.dir(
        cachePath,
        [
            d.dir(
                'global_packages',
                [
                    d.nothing('foo.lock'),
                    d.dir('foo', [d.matcherFile('pubspec.lock', contains('1.0.0'))])])]).validate();
  });
}
