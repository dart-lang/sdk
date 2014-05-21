/// Additional feature tests that aren't based on test data.
library dom_test;

import 'package:unittest/unittest.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';

main() {

  group('Element', () {
    test('classes', () {
      final barBaz = new Element.html('<div class=" bar baz"></div>');
      final quxBaz = new Element.html('<div class="qux  baz "></div>');
      expect(barBaz.className, ' bar baz');
      expect(quxBaz.className, 'qux  baz ');
      expect(barBaz.classes, ['bar', 'baz']);
      expect(quxBaz.classes, ['qux', 'baz']);
    });
  });

  group('Document', () {
    final doc = parse('<div id=foo>'
          '<div class=" bar baz"></div>'
          '<div class="qux  baz "></div>'
          '<div id=Foo>');

    test('getElementById', () {
      var foo = doc.body.nodes[0];
      var Foo = foo.nodes[2];
      expect(foo.id, 'foo');
      expect(Foo.id, 'Foo');
      expect(doc.getElementById('foo'), foo);
      expect(doc.getElementById('Foo'), Foo);
    });

    test('getElementsByClassName', () {
      var foo = doc.body.nodes[0];
      var barBaz = foo.nodes[0];
      var quxBaz = foo.nodes[1];
      expect(barBaz.className, ' bar baz');
      expect(quxBaz.className, 'qux  baz ');
      expect(doc.getElementsByClassName('baz'), [barBaz, quxBaz]);
      expect(doc.getElementsByClassName('bar '), [barBaz]);
      expect(doc.getElementsByClassName('  qux'), [quxBaz]);
      expect(doc.getElementsByClassName(' baz qux'), [quxBaz]);
    });

    test('getElementsByTagName', () {
      var foo = doc.body.nodes[0];
      var barBaz = foo.nodes[0];
      var quxBaz = foo.nodes[1];
      var Foo = foo.nodes[2];
      expect(doc.getElementsByTagName('div'), [foo, barBaz, quxBaz, Foo]);
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
