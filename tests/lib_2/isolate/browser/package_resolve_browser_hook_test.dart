// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

main() async {
  useHtmlConfiguration();

  test('defaultPackagesBase hook overrides package-uri resolution', () async {
    var uri = await Isolate.resolvePackageUri(Uri.parse('package:foo/bar.txt'));
    expect(uri, Uri.base.resolve('path/set/from/hook/foo/bar.txt'));
  });
}
