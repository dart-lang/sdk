// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests how canonicalization works when using the deployed app. This is
/// identical to the code in ../dir/deploy_common.dart but we need to copy it
/// here because the 'packages/...' URLs below should be relative from the
/// entrypoint directory.
library canonicalization.test.dir.deploy_common;

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
