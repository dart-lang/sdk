// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  group('supported', () {
    test('supported', () {
      expect(XsltProcessor.supported, true);
    });
  });

  group('functional', () {
    var isXsltProcessor =
        predicate((x) => x is XsltProcessor, 'is an XsltProcessor');

    var expectation = XsltProcessor.supported ? returnsNormally : throws;

    test('constructorTest', () {
      expect(() {
        var processor = new XsltProcessor();
        expect(processor, isNotNull);
        expect(processor, isXsltProcessor);
      }, expectation);
    });
  });
}
