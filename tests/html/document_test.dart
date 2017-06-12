library DocumentTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  var isElement = predicate((x) => x is Element, 'is an Element');
  var isDivElement = predicate((x) => x is DivElement, 'is a DivElement');
  var isAnchorElement =
      predicate((x) => x is AnchorElement, 'is an AnchorElement');
  var isUnknownElement =
      predicate((x) => x is UnknownElement, 'is UnknownElement');

  var inscrutable;

  test('CreateElement', () {
    // FIXME: nifty way crashes, do it boring way.
    expect(new Element.tag('span'), isElement);
    expect(new Element.tag('div'), isDivElement);
    expect(new Element.tag('a'), isAnchorElement);
    expect(new Element.tag('bad_name'), isUnknownElement);
  });

  group('document', () {
    inscrutable = (x) => x;

    test('Document.query', () {
      Document doc = new DomParser().parseFromString(
          '''<ResultSet>
           <Row>A</Row>
           <Row>B</Row>
           <Row>C</Row>
         </ResultSet>''',
          'text/xml');

      var rs = doc.query('ResultSet');
      expect(rs, isNotNull);
    });

    test('CreateElement', () {
      // FIXME: nifty way crashes, do it boring way.
      expect(new Element.tag('span'), isElement);
      expect(new Element.tag('div'), isDivElement);
      expect(new Element.tag('a'), isAnchorElement);
      expect(new Element.tag('bad_name'), isUnknownElement);
    });

    test('adoptNode', () {
      var div = new Element.html('<div><div id="foo">bar</div></div>');
      var doc = document.implementation.createHtmlDocument('');
      expect(doc.adoptNode(div), div);
      expect(div.ownerDocument, doc);
      doc.body.nodes.add(div);
      expect(doc.query('#foo').text, 'bar');
    });

    test('importNode', () {
      var div = new Element.html('<div><div id="foo">bar</div></div>');
      var doc = document.implementation.createHtmlDocument('');
      var div2 = doc.importNode(div, true);
      expect(div2, isNot(equals(div)));
      expect(div2.ownerDocument, doc);
      doc.body.nodes.add(div2);
      expect(doc.query('#foo').text, 'bar');
    });

    test('typeTest1', () {
      inscrutable = inscrutable(inscrutable);
      var doc1 = document;
      expect(doc1 is HtmlDocument, true);
      expect(inscrutable(doc1) is HtmlDocument, true);
      var doc2 = document.implementation.createHtmlDocument('');
      expect(doc2 is HtmlDocument, true);
      expect(inscrutable(doc2) is HtmlDocument, true);
    });

    test('typeTest2', () {
      inscrutable = inscrutable(inscrutable);
      // XML document.
      var doc3 = document.implementation.createDocument(null, 'report', null);
      expect(doc3 is HtmlDocument, false);
      expect(inscrutable(doc3) is HtmlDocument, false);
    });
  });
}
