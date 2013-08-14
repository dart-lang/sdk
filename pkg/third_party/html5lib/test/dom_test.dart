/** Additional feature tests that aren't based on test data. */
library dom_test;

import 'package:unittest/unittest.dart';
import 'package:html5lib/parser.dart';
import 'package:html5lib/dom.dart';

main() {
  group('Node.query type selectors', () {
    test('x-foo', () {
      expect(parse('<x-foo>').body.query('x-foo'), isNotNull);
    });

    test('-x-foo', () {
      var doc = parse('<body><-x-foo>');
      expect(doc.body.outerHtml, equals('<body>&lt;-x-foo&gt;</body>'));
      expect(doc.body.query('-x-foo'), isNull);
    });

    test('foo123', () {
      expect(parse('<foo123>').body.query('foo123'), isNotNull);
    });

    test('123 - invalid', () {
      var doc = parse('<123>');
      expect(() => doc.body.query('123'), throwsUnimplementedError);
    });

    test('x\\ny - not implemented', () {
      var doc = parse('<x\\ny>');
      expect(() => doc.body.query('x\\ny'), throwsUnimplementedError);
    });
  });
}
