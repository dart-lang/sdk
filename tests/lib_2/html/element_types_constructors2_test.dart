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
    check('fieldset', () => new FieldSetElement() is FieldSetElement);
    check('form', () => new FormElement() is FormElement);
    check('head', () => new HeadElement() is HeadElement);
    check('hr', () => new HRElement() is HRElement);
    check('html', () => new HtmlHtmlElement() is HtmlHtmlElement);
    check('h1', () => new HeadingElement.h1() is HeadingElement);
    check('h2', () => new HeadingElement.h2() is HeadingElement);
    check('h3', () => new HeadingElement.h3() is HeadingElement);
    check('h4', () => new HeadingElement.h4() is HeadingElement);
    check('h5', () => new HeadingElement.h5() is HeadingElement);
    check('h6', () => new HeadingElement.h6() is HeadingElement);
    check('iframe', () => new IFrameElement() is IFrameElement);
    check('img', () => new ImageElement() is ImageElement);
    check('input', () => new InputElement() is InputElement);
    check('keygen', () => new KeygenElement() is KeygenElement,
        KeygenElement.supported);
  });
}
