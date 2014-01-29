// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as path;

import '../../lib/src/utils.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';

getWarningRegExp(String assetsPath) {
  // Escape backslashes since they are metacharacters in a regex.
  assetsPath = quoteRegExp(assetsPath);
  return new RegExp(
      '^Warning: Pub reserves paths containing "assets" for using assets from '
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

    var assetsPath = path.join('web', 'assets');
    schedulePub(args: ['build'],
        error: getWarningRegExp(assetsPath));
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

    var assetsPath = path.join('web', 'foo', 'assets');
    schedulePub(args: ['build'],
        error: getWarningRegExp(assetsPath));
  });

  integration('warns user about assets file in the root of "web"', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('index.html'),
        d.file('assets')
      ])
    ]).create();

    var assetsPath = path.join('web', 'assets');
    schedulePub(args: ['build'],
        error: getWarningRegExp(assetsPath));
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

    var assetsPath = path.join('web', 'foo', 'assets');
    schedulePub(args: ['build'],
        error: getWarningRegExp(assetsPath));
  });

  integration('does not warn if no assets dir or file anywhere in "web"', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('index.html'),
        d.dir('foo')
      ])
    ]).create();

    schedulePub(args: ['build'],
        error: new RegExp(
            r'^(?!Warning: Pub reserves paths containing "assets").*$'));
  });
}
