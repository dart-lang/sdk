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
