// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library geolocation_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  // Actual tests require browser interaction. This just makes sure the API
  // is present.
  test('is not null', () {
    expect(window.navigator.geolocation, isNotNull);
  });
}
