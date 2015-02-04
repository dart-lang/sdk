// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../descriptor.dart' as d;
import '../test_pub.dart';

/// Runs the hosted test server and serves a valid "browser" package that
/// contains the same files (but not their contents) as the real browser
/// package.
void serveBrowserPackage() {
  serve([d.dir('api', [d.dir('packages', [d.file('browser', JSON.encode({
          'versions': [packageVersionApiMap(packageMap('browser', '1.0.0'))]
        })),
            d.dir(
                'browser',
                [
                    d.dir(
                        'versions',
                        [
                            d.file(
                                '1.0.0',
                                JSON.encode(
                                    packageVersionApiMap(packageMap('browser', '1.0.0'), full: true)))])])])]),
            d.dir(
                'packages',
                [
                    d.dir(
                        'browser',
                        [
                            d.dir(
                                'versions',
                                [
                                    d.tar(
                                        '1.0.0.tar.gz',
                                        [
                                            d.file('pubspec.yaml', yaml(packageMap("browser", "1.0.0"))),
                                            d.dir(
                                                'lib',
                                                [
                                                    d.file('dart.js', 'contents of dart.js'),
                                                    d.file('interop.js', 'contents of interop.js')])])])])])]);
}
