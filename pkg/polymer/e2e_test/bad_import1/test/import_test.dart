// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests how canonicalization works when using the deployed app.
library bad_import1.import_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

import 'package:bad_import1/a.dart';
main() {
  initPolymer();
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('html import', () {
    expect(a, 0, reason: 'html import was not resolved correctly.');
  });
}
