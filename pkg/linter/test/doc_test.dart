// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../tool/machine.dart';
import 'util/test_utils.dart';

void main() {
  group('doc generation', () {
    setUp(setUpSharedTestEnvironment);
    test('fixStatus (sanity)', () {
      var fixStatusMap = readFixStatusMap();
      // Doc generation reads the fix status map to associate fix status
      // badges with rule documentation.  Here we check one for sanity.
      // If the file moves or format changes, we'd expect this to fail.
      expect(fixStatusMap['always_declare_return_types'], 'hasFix');
    });
  });
}
