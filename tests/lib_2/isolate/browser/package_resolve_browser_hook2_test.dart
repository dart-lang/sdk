// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js';
import 'dart:isolate';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

main() async {
  useHtmlConfiguration();

  setUp(() {
    context['defaultPackagesBase'] = 'path1/';
  });

  test('hook overrides package-uri resolution', () async {
    var uri = await Isolate.resolvePackageUri(Uri.parse('package:foo/bar.txt'));
    expect(uri, Uri.base.resolve('path1/foo/bar.txt'));
  });

  test('hook is read once, on the first use of resolvePackageUri', () async {
    await Isolate.resolvePackageUri(Uri.parse('package:foo/bar.txt'));
    context['defaultPackagesBase'] = 'path2/';
    var uri = await Isolate.resolvePackageUri(Uri.parse('package:foo/bar.txt'));
    expect(uri, Uri.base.resolve('path1/foo/bar.txt'));
  });
}
