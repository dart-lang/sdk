/// Additional feature tests that aren't based on test data.
library dom_test;

import 'package:unittest/unittest.dart';
import 'package:html5lib/parser.dart';

main() {
  group('Node.querySelector type selectors', () {
    test('x-foo', () {
      expect(parse('<x-foo>').body.querySelector('x-foo'), isNotNull);
    });

    test('-x-foo', () {
      var doc = parse('<body><-x-foo>');
      expect(doc.body.outerHtml, equals('<body>&lt;-x-foo&gt;</body>'));
      expect(doc.body.querySelector('-x-foo'), isNull);
    });

    test('foo123', () {
      expect(parse('<foo123>').body.querySelector('foo123'), isNotNull);
    });

    test('123 - invalid', () {
      var doc = parse('<123>');
      expect(() => doc.body.querySelector('123'), throwsUnimplementedError);
    });

    test('x\\ny - not implemented', () {
      var doc = parse('<x\\ny>');
      expect(() => doc.body.querySelector('x\\ny'), throwsUnimplementedError);
    });
  });
}
