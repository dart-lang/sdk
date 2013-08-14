/** Additional feature tests that aren't based on test data. */
library parser_feature_test;

import 'package:unittest/unittest.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';
import 'package:html5lib/parser.dart';
import 'package:html5lib/src/constants.dart';
import 'package:html5lib/src/tokenizer.dart';
import 'package:html5lib/src/treebuilder.dart';

main() {
  test('doctype is cloneable', () {
    var doc = parse('<!DOCTYPE HTML>');
    DocumentType doctype = doc.nodes[0];
    expect(doctype.clone().outerHtml, '<!DOCTYPE html>');
  });

  test('line counter', () {
    // http://groups.google.com/group/html5lib-discuss/browse_frm/thread/f4f00e4a2f26d5c0
    var doc = parse("<pre>\nx\n&gt;\n</pre>");
    expect(doc.body.innerHtml, "<pre>x\n&gt;\n</pre>");
  });

  test('namespace html elements on', () {
    var doc = new HtmlParser('', tree: new TreeBuilder(true)).parse();
    expect(doc.nodes[0].namespace, Namespaces.html);
  });

  test('namespace html elements off', () {
    var doc = new HtmlParser('', tree: new TreeBuilder(false)).parse();
    expect(doc.nodes[0].namespace, null);
  });

  test('parse error spans - full', () {
    var parser = new HtmlParser('''
<!DOCTYPE html>
<html>
  <body>
  <!DOCTYPE html>
  </body>
</html>
''', generateSpans: true, sourceUrl: 'ParseError');
    var doc = parser.parse();
    expect(doc.body.outerHtml, '<body>\n  \n  \n\n</body>');
    expect(parser.errors.length, 1);
    ParseError error = parser.errors[0];
    expect(error.errorCode, 'unexpected-doctype');

    // Note: these values are 0-based, but the printed format is 1-based.
    expect(error.span.start.line, 3);
    expect(error.span.end.line, 3);
    expect(error.span.start.column, 2);
    expect(error.span.end.column, 17);
    expect(error.span.text, '<!DOCTYPE html>');

    expect(error.toString(), '''
ParseError:4:3: Unexpected DOCTYPE. Ignored.
  <!DOCTYPE html>
  ^^^^^^^^^^^^^^^''');
  });

  test('parse error spans - minimal', () {
    var parser = new HtmlParser('''
<!DOCTYPE html>
<html>
  <body>
  <!DOCTYPE html>
  </body>
</html>
''');
    var doc = parser.parse();
    expect(doc.body.outerHtml, '<body>\n  \n  \n\n</body>');
    expect(parser.errors.length, 1);
    ParseError error = parser.errors[0];
    expect(error.errorCode, 'unexpected-doctype');
    expect(error.span.start.line, 3);
    // Note: error position is at the end, not the beginning
    expect(error.span.start.column, 17);
  });

  test('text spans should have the correct length', () {
    var textContent = '\n  hello {{name}}';
    var html = '<body><div>$textContent</div>';
    var doc = parse(html, generateSpans: true);
    var text = doc.body.nodes[0].nodes[0];
    expect(text, new isInstanceOf<Text>());
    expect(text.value, textContent);
    expect(text.sourceSpan.start.offset, html.indexOf(textContent));
    expect(text.sourceSpan.length, textContent.length);
  });

  test('attribute spans', () {
    var text = '<element name="x-foo" extends="x-bar" constructor="Foo">';
    var doc = parse(text, generateSpans: true);
    var elem = doc.query('element');
    expect(elem.sourceSpan.start.offset, 0);
    expect(elem.sourceSpan.end.offset, text.length);
    expect(elem.sourceSpan.text, text);

    expect(elem.attributeSpans['quux'], null);

    var span = elem.attributeSpans['extends'];
    expect(span.start.offset, text.indexOf('extends'));
    expect(span.text, 'extends="x-bar"');
  });

  test('attribute value spans', () {
    var text = '<element name="x-foo" extends="x-bar" constructor="Foo">';
    var doc = parse(text, generateSpans: true);
    var elem = doc.query('element');

    expect(elem.attributeValueSpans['quux'], null);

    var span = elem.attributeValueSpans['extends'];
    expect(span.start.offset, text.indexOf('x-bar'));
    expect(span.text, 'x-bar');
  });

  test('attribute spans if no attributes', () {
    var text = '<element>';
    var doc = parse(text, generateSpans: true);
    var elem = doc.query('element');

    expect(elem.attributeSpans['quux'], null);
    expect(elem.attributeValueSpans['quux'], null);
  });

  test('attribute spans if no attribute value', () {
    var text = '<foo template>';
    var doc = parse(text, generateSpans: true);
    var elem = doc.query('foo');

    expect(elem.attributeSpans['template'].start.offset,
        text.indexOf('template'));
    expect(elem.attributeValueSpans.containsKey('template'), false);
  });

  test('attribute spans null if code parsed without spans', () {
    var text = '<element name="x-foo" extends="x-bar" constructor="Foo">';
    var doc = parse(text);
    var elem = doc.query('element');
    expect(elem.sourceSpan, null);
    expect(elem.attributeSpans['quux'], null);
    expect(elem.attributeSpans['extends'], null);
  });

  test('void element innerHTML', () {
    var doc = parse('<div></div>');
    expect(doc.body.innerHtml, '<div></div>');
    doc = parse('<body><script></script></body>');
    expect(doc.body.innerHtml, '<script></script>');
    doc = parse('<br>');
    expect(doc.body.innerHtml, '<br>');
    doc = parse('<br><foo><bar>');
    expect(doc.body.innerHtml, '<br><foo><bar></bar></foo>');
  });

  test('empty document has html, body, and head', () {
    var doc = parse('');
    expect(doc.outerHtml, '<html><head></head><body></body></html>');
    expect(doc.head.outerHtml, '<head></head>');
    expect(doc.body.outerHtml, '<body></body>');
  });

  test('strange table case', () {
    var doc = parseFragment('<table><tbody><foo>');
    expect(doc.outerHtml, '<foo></foo><table><tbody></tbody></table>');
  });

  group('html serialization', () {
    test('attribute order', () {
      // Note: the spec only requires a stable order.
      // However, we preserve the input order via LinkedHashMap
      var doc = parseFragment('<foo d=1 a=2 c=3 b=4>');
      expect(doc.outerHtml, '<foo d="1" a="2" c="3" b="4"></foo>');
      expect(doc.query('foo').attributes.remove('a'), '2');
      expect(doc.outerHtml, '<foo d="1" c="3" b="4"></foo>');
      doc.query('foo').attributes['a'] = '0';
      expect(doc.outerHtml, '<foo d="1" c="3" b="4" a="0"></foo>');
    });

    test('escaping Text node in <script>', () {
      var doc = parseFragment('<script>a && b</script>');
      expect(doc.outerHtml, '<script>a && b</script>');
    });

    test('escaping Text node in <span>', () {
      var doc = parseFragment('<span>a && b</span>');
      expect(doc.outerHtml, '<span>a &amp;&amp; b</span>');
    });

    test('Escaping attributes', () {
      var doc = parseFragment('<div class="a<b>">');
      expect(doc.outerHtml, '<div class="a<b>"></div>');
      doc = parseFragment('<div class=\'a"b\'>');
      expect(doc.outerHtml, '<div class="a&quot;b"></div>');
    });

    test('Escaping non-breaking space', () {
      var text = '<span>foO\u00A0bar</span>';
      expect(text.codeUnitAt(text.indexOf('O') + 1), 0xA0);
      var doc = parseFragment(text);
      expect(doc.outerHtml, '<span>foO&nbsp;bar</span>');
    });

    test('Newline after <pre>', () {
      var doc = parseFragment('<pre>\n\nsome text</span>');
      expect(doc.query('pre').nodes[0].value, '\nsome text');
      expect(doc.outerHtml, '<pre>\n\nsome text</pre>');

      doc = parseFragment('<pre>\nsome text</span>');
      expect(doc.query('pre').nodes[0].value, 'some text');
      expect(doc.outerHtml, '<pre>some text</pre>');
    });

    test('xml namespaces', () {
      // Note: this is a nonsensical example, but it triggers the behavior
      // we're looking for with attribute names in foreign content.
      var doc = parse('''
        <body>
        <svg>
        <desc xlink:type="simple"
              xlink:href="http://example.com/logo.png"
              xlink:show="new"></desc>
      ''');
      var n = doc.query('desc');
      var keys = n.attributes.keys.toList();
      expect(keys[0], new isInstanceOf<AttributeName>());
      expect(keys[0].prefix, 'xlink');
      expect(keys[0].namespace, 'http://www.w3.org/1999/xlink');
      expect(keys[0].name, 'type');

      expect(n.outerHtml, '<desc xlink:type="simple" '
          'xlink:href="http://example.com/logo.png" xlink:show="new"></desc>');
    });
  });

  test('error printing without spans', () {
    var parser = new HtmlParser('foo');
    var doc = parser.parse();
    expect(doc.body.innerHtml, 'foo');
    expect(parser.errors.length, 1);
    expect(parser.errors[0].errorCode, 'expected-doctype-but-got-chars');
    expect(parser.errors[0].message,
        'Unexpected non-space characters. Expected DOCTYPE.');
    expect(parser.errors[0].toString(),
        'ParserError:1:4: Unexpected non-space characters. '
        'Expected DOCTYPE.');
  });
}
