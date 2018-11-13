// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  check(String name, bool fn(), [bool supported = true]) {
    test(name, () {
      if (supported) {
        expect(fn(), isTrue);
      } else {
        // Can either throw or return false.
        expect(() => (fn() || (throw "false")), throws);
      }
    });
  }

  group('constructors', () {
    check('p', () => new ParagraphElement() is ParagraphElement);
    check('param', () => new ParamElement() is ParamElement);
    check('pre', () => new PreElement() is PreElement);
    check('progress', () => new ProgressElement() is ProgressElement,
        ProgressElement.supported);
    check('q', () => new QuoteElement() is QuoteElement);
    check('script', () => new ScriptElement() is ScriptElement);
    check('select', () => new SelectElement() is SelectElement);
    check('shadow', () => new ShadowElement() is ShadowElement,
        ShadowElement.supported);
    check('source', () => new SourceElement() is SourceElement);
    check('span', () => new SpanElement() is SpanElement);
    check('style', () => new StyleElement() is StyleElement);
  });
}
