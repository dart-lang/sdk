// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library experimental_boot.test.import_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

import 'package:experimental_boot/a.dart' show a;
import 'packages/experimental_boot/b.dart' show b;
import 'package:experimental_boot/c.dart' show c;
import 'package:experimental_boot/d.dart' as d1 show d;
import 'packages/experimental_boot/d.dart' as d2 show d;

@initMethod
main() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('canonicalization with experimental bootstrap', () {
    expect(a, 1, reason:
      'deploy picks the "package:" url as the canonical url for script tags.');

    // We shouldn't be using 'packages/' above, so that's ok.
    expect(b, 0, reason:
        'we pick the "package:" url as the canonical url for script tags.');
    expect(c, 2, reason: 'c was always imported with "package:" urls.');
    expect(d1.d, 2, reason: 'both a and b are loaded using package: urls');
    expect(d2.d, 0, reason: 'both a and b are loaded using package: urls');
  });
}
