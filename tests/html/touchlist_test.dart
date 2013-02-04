// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library touch_list_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(TouchList.supported, true);
    });
  });

  group('functional', () {
    test('touchlist constructor', () {
      if (TouchList.supported) {
        var list = new TouchList();
        expect(list, isNotNull);
        expect(list is TouchList, true);
      }
    });
  });
}
