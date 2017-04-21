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
    check('a', () => new AnchorElement() is AnchorElement);
    check('area', () => new AreaElement() is AreaElement);
    check('audio', () => new AudioElement() is AudioElement);
    check('body', () => new BodyElement() is BodyElement);
    check('br', () => new BRElement() is BRElement);
    check('base', () => new BaseElement() is BaseElement);
    check('button', () => new ButtonElement() is ButtonElement);
    check('canvas', () => new CanvasElement() is CanvasElement);
    check('caption', () => new TableCaptionElement() is TableCaptionElement);
    check('content', () => new ContentElement() is ContentElement,
        ContentElement.supported);
    check('details', () => new DetailsElement() is DetailsElement,
        DetailsElement.supported);
    check('datalist', () => new DataListElement() is DataListElement,
        DataListElement.supported);
    check('dl', () => new DListElement() is DListElement);
    check('div', () => new DivElement() is DivElement);
    check('embed', () => new EmbedElement() is EmbedElement,
        EmbedElement.supported);
  });
}
