// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  check(String name, bool fn(), [bool supported = true]) {
    test(name, () {
      var expectation = supported ? returnsNormally : throws;
      expect(() {
        expect(fn(), isTrue);
      }, expectation);
    });
  }

  group('constructors', () {
    check('table', () => new TableElement() is TableElement);
    check('template', () => new TemplateElement() is TemplateElement,
        TemplateElement.supported);
    check('textarea', () => new TextAreaElement() is TextAreaElement);
    check('title', () => new TitleElement() is TitleElement);
    check('td', () => new TableCellElement() is TableCellElement);
    check('col', () => new TableColElement() is TableColElement);
    check('colgroup', () => new Element.tag('colgroup') is TableColElement);
    check('tr', () => new TableRowElement() is TableRowElement);
    check('tbody', () => new Element.tag('tbody') is TableSectionElement);
    check('tfoot', () => new Element.tag('tfoot') is TableSectionElement);
    check('thead', () => new Element.tag('thead') is TableSectionElement);
    check('track', () => new TrackElement() is TrackElement,
        TrackElement.supported);
  });
}
