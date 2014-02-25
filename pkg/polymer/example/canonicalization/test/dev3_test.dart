// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests how canonicalization works during development.
library canonicalization.dev3_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

import 'package:canonicalization/a.dart';
import 'packages/canonicalization/b.dart';
import 'package:canonicalization/c.dart';
import 'package:canonicalization/d.dart' as d1;
import 'packages/canonicalization/d.dart' as d2;

main() {
  initPolymer();
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('canonicalization', () {
    expect(a, 1, reason:
      'initPolymer picks the "package:" url as the canonical url for script '
      'tags whose library is also loaded with a "package:" url.');
    expect(b, 1, reason:
      'initPolymer does nothing with script tags where the program doesn\'t '
      'use a "package:" urls matching the same library.');
    expect(c, 2, reason: 'c was always imported with "package:" urls.');
    expect(d1.d, 1, reason: 'this matches the import from a');
    expect(d2.d, 1, reason: 'this matches the import from b');
  });
}
