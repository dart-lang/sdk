library range_test;

import 'dart:html';
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supports_createContextualFragment', () {
      expect(Range.supportsCreateContextualFragment, isTrue);
    });
  });

  group('functional', () {
    test('supported works', () {
      var range = new Range();
      range.selectNode(document.body);

      var expectation = Range.supportsCreateContextualFragment ?
          returnsNormally : throws;

      expect(() {
        range.createContextualFragment('<div></div>');
      }, expectation);
    });
  });
}
