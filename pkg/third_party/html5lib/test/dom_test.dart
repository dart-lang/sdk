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

    test('built from fragments', () {
      var doc = parse('<body>');
      doc.body.nodes.add(parseFragment('<x-foo>'));
      expect(doc.body.querySelector('x-foo'), isNotNull);
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

  group('Node.querySelectorAll type selectors', () {
    test('x-foo', () {
      expect(parse('<x-foo>').body.querySelectorAll('x-foo').length, 1);
    });

    test('-x-foo', () {
      var doc = parse('<body><-x-foo>');
      expect(doc.body.outerHtml, equals('<body>&lt;-x-foo&gt;</body>'));
      expect(doc.body.querySelectorAll('-x-foo').length, 0);
    });

    test('foo123', () {
      expect(parse('<foo123>').body.querySelectorAll('foo123').length, 1);
    });

    test('built from fragments', () {
      var doc = parse('<body>');
      doc.body.nodes.add(parseFragment('<x-foo></x-foo><x-foo>'));
      expect(doc.body.querySelectorAll('x-foo').length, 2);
    });

    test('123 - invalid', () {
      var doc = parse('<123>');
      expect(() => doc.body.querySelectorAll('123'), throwsUnimplementedError);
    });

    test('x\\ny - not implemented', () {
      var doc = parse('<x\\ny>');
      expect(() => doc.body.querySelectorAll('x\\ny'),
        throwsUnimplementedError);
    });
  });

  group('fragments are flattened', () {
    test('add', () {
      var doc = parse('<body>');
      doc.body.nodes.add(parseFragment('<x-foo>'));
      expect(doc.body.nodes[0].localName, 'x-foo');
      doc.body.nodes.add(parseFragment('<x-bar>'));
      expect(doc.body.nodes[1].localName, 'x-bar');
    });

    test('addLast', () {
      var doc = parse('<body>');
      doc.body.nodes.addLast(parseFragment('<x-foo>'));
      expect(doc.body.nodes[0].localName, 'x-foo');
      doc.body.nodes.addLast(parseFragment('<x-bar>'));
      expect(doc.body.nodes[1].localName, 'x-bar');
    });

    test('addAll', () {
      var doc = parse('<body><x-a></x-a>');
      doc.body.nodes.addAll([parseFragment('<x-b></x-b><x-c></x-c>')]);
      expect(doc.body.nodes[0].localName, 'x-a');
      expect(doc.body.nodes[1].localName, 'x-b');
      expect(doc.body.nodes[2].localName, 'x-c');
    });

    test('insert', () {
      var doc = parse('<body><x-a></x-a>');
      doc.body.nodes.insert(0, parseFragment('<x-b></x-b><x-c></x-c>'));
      expect(doc.body.nodes[0].localName, 'x-b');
      expect(doc.body.nodes[1].localName, 'x-c');
      expect(doc.body.nodes[2].localName, 'x-a');

      doc = parse('<body><x-a></x-a>');
      doc.body.nodes.insert(1, parseFragment('<x-b></x-b><x-c></x-c>'));
      expect(doc.body.nodes[0].localName, 'x-a');
      expect(doc.body.nodes[1].localName, 'x-b');
      expect(doc.body.nodes[2].localName, 'x-c');

      doc = parse('<body><x-a></x-a>');
      doc.body.nodes.insert(0, parseFragment('<x-b></x-b>'));
      doc.body.nodes.insert(1, parseFragment('<x-c></x-c>'));
      expect(doc.body.nodes[0].localName, 'x-b');
      expect(doc.body.nodes[1].localName, 'x-c');
      expect(doc.body.nodes[2].localName, 'x-a');
    });

    test('insertAll', () {
      var doc = parse('<body><x-a></x-a>');
      doc.body.nodes.insertAll(0, [parseFragment('<x-b></x-b><x-c></x-c>')]);
      expect(doc.body.nodes[0].localName, 'x-b');
      expect(doc.body.nodes[1].localName, 'x-c');
      expect(doc.body.nodes[2].localName, 'x-a');
      expect(doc.body.nodes.length, 3);

      doc = parse('<body><x-a></x-a>');
      doc.body.nodes.insertAll(1, [parseFragment('<x-b></x-b><x-c></x-c>')]);
      expect(doc.body.nodes[0].localName, 'x-a');
      expect(doc.body.nodes[1].localName, 'x-b');
      expect(doc.body.nodes[2].localName, 'x-c');

      doc = parse('<body><x-a></x-a>');
      doc.body.nodes.insertAll(0, [parseFragment('<x-b></x-b>')]);
      doc.body.nodes.insertAll(1, [parseFragment('<x-c></x-c>')]);
      expect(doc.body.nodes[0].localName, 'x-b');
      expect(doc.body.nodes[1].localName, 'x-c');
      expect(doc.body.nodes[2].localName, 'x-a');
    });

    test('operator []=', () {
      var doc = parse('<body><x-a></x-a>');
      doc.body.nodes[0] = parseFragment('<x-b></x-b><x-c></x-c>');
      expect(doc.body.nodes[0].localName, 'x-b');
      expect(doc.body.nodes[1].localName, 'x-c');
      expect(doc.body.nodes.length, 2);

      doc = parse('<body><x-a></x-a><x-b></x-b><x-c></x-c>');
      doc.body.nodes[1] = parseFragment('<y-b></y-b><y-c></y-c>');
      expect(doc.body.nodes[0].localName, 'x-a');
      expect(doc.body.nodes[1].localName, 'y-b');
      expect(doc.body.nodes[2].localName, 'y-c');
      expect(doc.body.nodes[3].localName, 'x-c');
      expect(doc.body.nodes.length, 4);
    });

    test('setRange', () {
      var fragment = parseFragment('<y-b></y-b><y-c></y-c>');
      var doc = parse('<body><x-a></x-a><x-b></x-b><x-c></x-c>');
      doc.body.nodes.setRange(1, 2, fragment.nodes, 0);
      expect(doc.body.nodes[0].localName, 'x-a');
      expect(doc.body.nodes[1].localName, 'y-b');
      expect(doc.body.nodes[2].localName, 'y-c');
      expect(doc.body.nodes.length, 3);

      fragment = parseFragment('<y-b></y-b><y-c></y-c>');
      doc = parse('<body><x-a></x-a><x-b></x-b><x-c></x-c>');
      doc.body.nodes.setRange(1, 1, [fragment], 0);
      expect(doc.body.nodes[0].localName, 'x-a');
      expect(doc.body.nodes[1].localName, 'y-b');
      expect(doc.body.nodes[2].localName, 'y-c');
      expect(doc.body.nodes[3].localName, 'x-c');
      expect(doc.body.nodes.length, 4);
    });

    test('replaceRange', () {
      var fragment = parseFragment('<y-b></y-b><y-c></y-c>');
      var doc = parse('<body><x-a></x-a><x-b></x-b><x-c></x-c>');
      doc.body.nodes.replaceRange(1, 2, fragment.nodes);
      expect(doc.body.nodes[0].localName, 'x-a');
      expect(doc.body.nodes[1].localName, 'y-b');
      expect(doc.body.nodes[2].localName, 'y-c');
      expect(doc.body.nodes[3].localName, 'x-c');
      expect(doc.body.nodes.length, 4);

      fragment = parseFragment('<y-b></y-b><y-c></y-c>');
      doc = parse('<body><x-a></x-a><x-b></x-b><x-c></x-c>');
      doc.body.nodes.replaceRange(1, 2, [fragment]);
      expect(doc.body.nodes[0].localName, 'x-a');
      expect(doc.body.nodes[1].localName, 'y-b');
      expect(doc.body.nodes[2].localName, 'y-c');
      expect(doc.body.nodes[3].localName, 'x-c');
      expect(doc.body.nodes.length, 4);
    });

    test('replaceWith', () {
      var fragment = parseFragment('<y-b></y-b><y-c></y-c>');
      var doc = parse('<body><x-a></x-a><x-b></x-b><x-c></x-c>');
      doc.body.nodes[1].replaceWith(fragment);
      expect(doc.body.nodes[0].localName, 'x-a');
      expect(doc.body.nodes[1].localName, 'y-b');
      expect(doc.body.nodes[2].localName, 'y-c');
      expect(doc.body.nodes[3].localName, 'x-c');
      expect(doc.body.nodes.length, 4);
    });
  });
}
