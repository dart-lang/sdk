// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library element_types_constructors6_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  check(String name, bool fn(), [bool supported = true]) {
    test(name, () {
      var expectation = supported ? returnsNormally : throws;
      expect(() {
        expect(fn(), isTrue);
      }, expectation);
    });
  }

  group('ul', () {
    check('ul', () => new UListElement() is UListElement);

    test('accepts li', () {
      var ul = new UListElement();
      var li = new LIElement();
      ul.append(li);
    });
  });
  group('constructors', () {
    check('video', () => new VideoElement() is VideoElement);
    check('unknown', () => new Element.tag('someunknown') is UnknownElement);
  });
}
