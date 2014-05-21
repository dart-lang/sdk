// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_wrappers_test;

import 'dart:html';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

main() {
  useHtmlConfiguration();

  test('OK to access location with platform.js', () {
    expect(window.location.toString(), window.location.href);
  });
}
