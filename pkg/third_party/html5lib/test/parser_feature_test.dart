/// Additional feature tests that aren't based on test data.
library parser_feature_test;

import 'package:unittest/unittest.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:html5lib/src/constants.dart';
import 'package:html5lib/src/treebuilder.dart';

main() {
  test('doctype is cloneable', () {
    var doc = parse('<!doctype HTML>');
    DocumentType doctype = doc.nodes[0];
    expect(doctype.clone(false).toString(), '<!DOCTYPE html>');
  });

  test('line counter', () {
    // http://groups.google.com/group/html5lib-discuss/browse_frm/thread/f4f00e4a2f26d5c0
    var doc = parse("<pre>\nx\n&gt;\n</pre>");
    expect(doc.body.innerHtml, "<pre>x\n&gt;\n</pre>");
  });

  test('namespace html elements on', () {
    var doc = new HtmlParser('', tree: new TreeBuilder(true)).parse();
    expect(doc.nodes[0].namespaceUri, Namespaces.html);
  });

  test('namespace html elements off', () {
    var doc = new HtmlParser('', tree: new TreeBuilder(false)).parse();
    expect(doc.nodes[0].namespaceUri, null);
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
On line 4, column 3 of ParseError: Unexpected DOCTYPE. Ignored.
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
    Text text = doc.body.nodes[0].nodes[0];
    expect(text, new isInstanceOf<Text>());
    expect(text.data, textContent);
    expect(text.sourceSpan.start.offset, html.indexOf(textContent));
    expect(text.sourceSpan.length, textContent.length);
  });

  test('attribute spans', () {
    var text = '<element name="x-foo" extends="x-bar" constructor="Foo">';
    var doc = parse(text, generateSpans: true);
    var elem = doc.querySelector('element');
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
    var elem = doc.querySelector('element');

    expect(elem.attributeValueSpans['quux'], null);

    var span = elem.attributeValueSpans['extends'];
    expect(span.start.offset, text.indexOf('x-bar'));
    expect(span.text, 'x-bar');
  });

  test('attribute spans if no attributes', () {
    var text = '<element>';
    var doc = parse(text, generateSpans: true);
    var elem = doc.querySelector('element');

    expect(elem.attributeSpans['quux'], null);
    expect(elem.attributeValueSpans['quux'], null);
  });

  test('attribute spans if no attribute value', () {
    var text = '<foo template>';
    var doc = parse(text, generateSpans: true);
    var elem = doc.querySelector('foo');

    expect(elem.attributeSpans['template'].start.offset,
        text.indexOf('template'));
    expect(elem.attributeValueSpans.containsKey('template'), false);
  });

  test('attribute spans null if code parsed without spans', () {
    var text = '<element name="x-foo" extends="x-bar" constructor="Foo">';
    var doc = parse(text);
    var elem = doc.querySelector('element');
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
    var html = '<html><head></head><body></body></html>';
    expect(doc.outerHtml, html);
    expect(doc.documentElement.outerHtml, html);
    expect(doc.head.outerHtml, '<head></head>');
    expect(doc.body.outerHtml, '<body></body>');
  });

  test('strange table case', () {
    var doc = parse('<table><tbody><foo>').body;
    expect(doc.innerHtml, '<foo></foo><table><tbody></tbody></table>');
  });

  group('html serialization', () {
    test('attribute order', () {
      // Note: the spec only requires a stable order.
      // However, we preserve the input order via LinkedHashMap
      var body = parse('<foo d=1 a=2 c=3 b=4>').body;
      expect(body.innerHtml, '<foo d="1" a="2" c="3" b="4"></foo>');
      expect(body.querySelector('foo').attributes.remove('a'), '2');
      expect(body.innerHtml, '<foo d="1" c="3" b="4"></foo>');
      body.querySelector('foo').attributes['a'] = '0';
      expect(body.innerHtml, '<foo d="1" c="3" b="4" a="0"></foo>');
    });

    test('escaping Text node in <script>', () {
      Element e = parseFragment('<script>a && b</script>').firstChild;
      expect(e.outerHtml, '<script>a && b</script>');
    });

    test('escaping Text node in <span>', () {
      Element e = parseFragment('<span>a && b</span>').firstChild;
      expect(e.outerHtml, '<span>a &amp;&amp; b</span>');
    });

    test('Escaping attributes', () {
      Element e = parseFragment('<div class="a<b>">').firstChild;
      expect(e.outerHtml, '<div class="a<b>"></div>');
      e = parseFragment('<div class=\'a"b\'>').firstChild;
      expect(e.outerHtml, '<div class="a&quot;b"></div>');
    });

    test('Escaping non-breaking space', () {
      var text = '<span>foO\u00A0bar</span>';
      expect(text.codeUnitAt(text.indexOf('O') + 1), 0xA0);
      Element e = parseFragment(text).firstChild;
      expect(e.outerHtml, '<span>foO&nbsp;bar</span>');
    });

    test('Newline after <pre>', () {
      Element e = parseFragment('<pre>\n\nsome text</span>').firstChild;
      expect((e.firstChild as Text).data, '\nsome text');
      expect(e.outerHtml, '<pre>\n\nsome text</pre>');

      e = parseFragment('<pre>\nsome text</span>').firstChild;
      expect((e.firstChild as Text).data, 'some text');
      expect(e.outerHtml, '<pre>some text</pre>');
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
      var n = doc.querySelector('desc');
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
        'ParserError on line 1, column 4: Unexpected non-space characters. '
        'Expected DOCTYPE.');
  });

  test('Element.text', () {
    var doc = parseFragment('<div>foo<div>bar</div>baz</div>');
    var e = doc.firstChild;
    var text = e.firstChild;
    expect((text as Text).data, 'foo');
    expect(e.text, 'foobarbaz');

    e.text = 'FOO';
    expect(e.nodes.length, 1);
    expect(e.firstChild, isNot(text), reason: 'should create a new tree');
    expect((e.firstChild as Text).data, 'FOO');
    expect(e.text, 'FOO');
  });

  test('Text.text', () {
    var doc = parseFragment('<div>foo<div>bar</div>baz</div>');
    var e = doc.firstChild;
    Text text = e.firstChild;
    expect(text.data, 'foo');
    expect(text.text, 'foo');

    text.text = 'FOO';
    expect(text.data, 'FOO');
    expect(e.text, 'FOObarbaz');
    expect(text.text, 'FOO');
  });

  test('Comment.text', () {
    var doc = parseFragment('<div><!--foo-->bar</div>');
    var e = doc.firstChild;
    var c = e.firstChild;
    expect((c as Comment).data, 'foo');
    expect(c.text, 'foo');
    expect(e.text, 'bar');

    c.text = 'qux';
    expect(c.data, 'qux');
    expect(c.text, 'qux');
    expect(e.text, 'bar');
  });
}
