// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration('warns user about top-level "assets" directories', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('bin', [
        d.dir('assets')
      ]),
      d.dir('test', [
        d.dir('assets')
      ]),
      d.dir('web', [
        d.file('index.html'),
        d.dir('assets')
      ])
    ]).create();

    var pub = pubServe();
    waitForBuildSuccess();

    pub.stderr.expect(emitsLines('''
Warning: Pub reserves paths containing "assets" for using assets from packages.
Please rename the directory "${path.join('bin', 'assets')}".
Please rename the directory "${path.join('test', 'assets')}".
Please rename the directory "${path.join('web', 'assets')}".'''));
    endPubServe();
  });

  integration('warns user about top-level "assets" files', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('bin', [
        d.file('assets', '...')
      ]),
      d.dir('test', [
        d.file('assets', '...')
      ]),
      d.dir('web', [
        d.file('index.html'),
        d.file('assets', '...')
      ])
    ]).create();

    var pub = pubServe();
    waitForBuildSuccess();
    pub.stderr.expect(emitsLines('''
Warning: Pub reserves paths containing "assets" for using assets from packages.
Please rename the file "${path.join('bin', 'assets')}".
Please rename the file "${path.join('test', 'assets')}".
Please rename the file "${path.join('web', 'assets')}".'''));
    endPubServe();
  });

  integration('does not warn on "assets" in subdirectories', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('index.html'),
        d.dir('foo', [
          d.dir('assets')
        ]),
        d.dir('bar', [
          d.file('assets', '...')
        ])
      ])
    ]).create();

    var pub = pubServe();
    waitForBuildSuccess();
    endPubServe();
    pub.stderr.expect(never(contains("Warning")));
  });
}
