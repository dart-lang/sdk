// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library element_types_constructors3_test;

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

  group('constructors', () {
    check('li', () => new LIElement() is LIElement);
    check('label', () => new LabelElement() is LabelElement);
    check('legen', () => new LegendElement() is LegendElement);
    check('link', () => new LinkElement() is LinkElement);
    check('map', () => new MapElement() is MapElement);
    check('menu', () => new MenuElement() is MenuElement);
    check('meta', () => new MetaElement() is MetaElement);
    check('meter', () => new MeterElement() is MeterElement,
        MeterElement.supported);
    check('del', () => new Element.tag('del') is ModElement);
    check('ins', () => new Element.tag('ins') is ModElement);
    check('object', () => new ObjectElement() is ObjectElement,
        ObjectElement.supported);
    check('ol', () => new OListElement() is OListElement);
    check('optgroup', () => new OptGroupElement() is OptGroupElement);
    check('option', () => new OptionElement() is OptionElement);
    check('output', () => new OutputElement() is OutputElement,
        OutputElement.supported);
  });
}
