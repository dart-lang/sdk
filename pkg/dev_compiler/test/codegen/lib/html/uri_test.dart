// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('Uri.base', () {
    expect(Uri.base.scheme, "http");
    expect(Uri.base.toString(), window.location.href);
  });
}
