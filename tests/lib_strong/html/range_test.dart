import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  group('supported', () {
    test('supports_createContextualFragment', () {
      expect(Range.supportsCreateContextualFragment, isTrue);
    });
  });

  group('functional', () {
    test('supported works', () {
      var range = new Range();
      range.selectNode(document.body);

      var expectation =
          Range.supportsCreateContextualFragment ? returnsNormally : throws;

      expect(() {
        range.createContextualFragment('<div></div>');
      }, expectation);
    });
  });
}
