// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

main() {
  useHtmlConfiguration();

  test('by default package-uri resolve under base/packages/', () async {
    var uri = await Isolate.resolvePackageUri(Uri.parse('package:foo/bar.txt'));
    expect(uri, Uri.base.resolve('packages/foo/bar.txt'));
  });
}
