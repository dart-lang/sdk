// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/utils.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

getWarningRegExp(String assetsPath) {
  // Escape backslashes since they are metacharacters in a regex.
  assetsPath = quoteRegExp(assetsPath);
  return new RegExp(
      r'^Warning: Pub reserves paths containing "assets" for using assets from '
      'packages\\. Please rename the path "$assetsPath"\\.\$');
}

main() {
  initConfig();

  integration('warns user about assets dir in the root of "web"', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('index.html'),
        d.dir('assets')
      ])
    ]).create();

    var pub = pubServe();
    waitForBuildSuccess();

    var assetsPath = path.join('web', 'assets');
    pub.stderr.expect(consumeThrough(matches(getWarningRegExp(assetsPath))));
    endPubServe();
  });

  integration('warns user about assets dir nested anywhere in "web"', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('index.html'),
        d.dir('foo', [
          d.dir('assets')
        ])
      ])
    ]).create();

    var pub = pubServe();
    waitForBuildSuccess();

    var assetsPath = path.join('web', 'foo', 'assets');
    pub.stderr.expect(consumeThrough(matches(getWarningRegExp(assetsPath))));
    endPubServe();
  });

  integration('warns user about assets file in the root of "web"', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('index.html'),
        d.file('assets')
      ])
    ]).create();

    var pub = pubServe();
    waitForBuildSuccess();

    var assetsPath = path.join('web', 'assets');
    pub.stderr.expect(consumeThrough(matches(getWarningRegExp(assetsPath))));
    endPubServe();
  });

  integration('warns user about assets file nested anywhere in "web"', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('index.html'),
        d.dir('foo', [
          d.file('assets')
        ])
      ])
    ]).create();

    var pub = pubServe();
    waitForBuildSuccess();

    var assetsPath = path.join('web', 'foo', 'assets');
    pub.stderr.expect(consumeThrough(matches(getWarningRegExp(assetsPath))));
    endPubServe();
  });

  integration('does not warn if no assets dir or file anywhere in "web"', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('index.html'),
        d.dir('foo')
      ])
    ]).create();

    var pub = pubServe();
    waitForBuildSuccess();
    endPubServe();

    pub.stderr.expect(never(startsWith('Warning: Pub reserves paths containing '
        '"assets"')));
  });
}
