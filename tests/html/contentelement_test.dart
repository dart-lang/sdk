// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library contentelement_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  var isContentElement =
      predicate((x) => x is ContentElement, 'is a ContentElement');

  test('constructor', () {
      var e = new ContentElement();
      expect(e, isContentElement);
    });
}
