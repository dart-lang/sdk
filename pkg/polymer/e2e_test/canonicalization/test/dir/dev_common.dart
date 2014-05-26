// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests how canonicalization works when developing in Dartium. This is
/// identical to the code in ../dir/deploy_common.dart but we need to copy it
/// here because the 'packages/...' URLs below should be relative from the
/// entrypoint directory.
library canonicalization.test.dir.dev_common;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

import 'package:canonicalization/a.dart' show a;
import 'packages/canonicalization/b.dart' show b;
import 'package:canonicalization/c.dart' show c;
import 'package:canonicalization/d.dart' as d1 show d;
import 'packages/canonicalization/d.dart' as d2 show d;

main() {
  initPolymer();
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('canonicalization', () {
    expect(a, 1, reason: 'Dartium loads "a" via a "package:" url.');

    // We shouldn't be using 'packages/', but we do just to check that Dartium
    // can't infer a "package:" url for it.
    expect(b, 1, reason: 'Dartium picks the relative url for "b".');
    expect(c, 2, reason: '"c" was always imported with "package:" urls.');
    expect(d1.d, 1, reason: '"a" loads via "package:", but "b" does not.');
    expect(d2.d, 1, reason: '"b" loads via a relative url, but "a" does not.');
  });
}
