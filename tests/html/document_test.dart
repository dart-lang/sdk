library DocumentTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  var isElement = predicate((x) => x is Element, 'is an Element');
  var isDivElement = predicate((x) => x is DivElement, 'is a DivElement');
  var isAnchorElement =
      predicate((x) => x is AnchorElement, 'is an AnchorElement');
  var isUnknownElement =
      predicate((x) => x is UnknownElement, 'is UnknownElement');

  test('CreateElement', () {
    // FIXME: nifty way crashes, do it boring way.
    expect(new Element.tag('span'), isElement);
    expect(new Element.tag('div'), isDivElement);
    expect(new Element.tag('a'), isAnchorElement);
    expect(new Element.tag('bad_name'), isUnknownElement);
  });

  group('supports_cssCanvasContext', () {
    test('supports_cssCanvasContext', () {
      expect(HtmlDocument.supportsCssCanvasContext, true);
    });
  });

  group('getCssCanvasContext', () {
    test('getCssCanvasContext 2d', () {
      var expectation = HtmlDocument.supportsCssCanvasContext ?
        returnsNormally : throws;

      expect(() {
        var context = document.getCssCanvasContext('2d', 'testContext', 10, 20);
        expect(context is CanvasRenderingContext2D, true);
        expect(context.canvas.width, 10);
        expect(context.canvas.height, 20);
      }, expectation);
    });
  });

  group('document', () {
    test('Document.query', () {
      Document doc = new DomParser().parseFromString(
      '''<ResultSet>
           <Row>A</Row>
           <Row>B</Row>
           <Row>C</Row>
         </ResultSet>''','text/xml');

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
      expect(div.document, doc);
      doc.body.nodes.add(div);
      expect(doc.query('#foo').text, 'bar');
    });

    test('importNode', () {
      var div = new Element.html('<div><div id="foo">bar</div></div>');
      var doc = document.implementation.createHtmlDocument('');
      var div2 = doc.importNode(div, true);
      expect(div2, isNot(equals(div)));
      expect(div2.document, doc);
      doc.body.nodes.add(div2);
      expect(doc.query('#foo').text, 'bar');
    });
  });
}
