// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests how canonicalization works when using the deployed app.
library canonicalization.dev3_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

import 'package:canonicalization3/a.dart';
import 'packages/canonicalization3/b.dart';
import 'package:canonicalization3/c.dart';
import 'package:canonicalization3/d.dart' as d1;
import 'packages/canonicalization3/d.dart' as d2;

@initMethod
main() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('canonicalization', () {
    // "package:" urls work the same during development and deployment
    expect(a, 1, reason:
      'deploy picks the "package:" url as the canonical url for script tags.');

    // relative urls do not. true, we shouldn't be using 'packages/' above, so
    // that's ok.
    expect(b, 0, reason:
      'deploy picks the "package:" url as the canonical url for script tags.');
    expect(c, 2, reason: 'c was always imported with "package:" urls.');
    expect(d1.d, 2, reason: 'both a and b are loaded using package: urls');

    // same here
    expect(d2.d, 0, reason: 'both a and b are loaded using package: urls');
  });
}
