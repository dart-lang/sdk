// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XMLElementTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  var isXMLElement = predicate((x) => x is XMLElement, 'is an XMLElement');

  XMLElement makeElement() => new XMLElement.xml("<xml><foo/><bar/></xml>");

  makeElementWithParent() {
    final parent = new XMLElement.xml(
        "<parent><before/><xml><foo/><bar/></xml><after/></parent>");
    return parent.children[1];
  }

  group('constructors', () {
    group('.xml', () {
      test('with a well-formed document', () {
        final el = makeElement();
        expect(el, isXMLElement);
        expect(el.children[0].tagName, 'foo');
        expect(el.children[1].tagName, 'bar');
      });

      test('with too many nodes', () {
        expect(() => new XMLElement.xml("<xml></xml>foo"), throwsArgumentError);
      });

      test('with a parse error', () {
        expect(() => new XMLElement.xml("<xml></xml>>"), throwsArgumentError);
      });

      test('with a PARSERERROR tag', () {
        final el = new XMLElement.xml("<xml><parsererror /></xml>");
        expect('parsererror', el.children[0].tagName, 'parsererror');
      });

      test('has no parent', () =>
          expect(new XMLElement.xml('<foo/>').parent), isNull);
    });

    test('.tag', () {
      final el = new XMLElement.tag('foo');
      expect(el, isXMLElement);
      expect(el.tagName, 'foo');
    });
  });

  // FilteredElementList is tested more thoroughly in DocumentFragmentTests.
  group('children', () {
    test('filters out non-element nodes', () {
      final el = new XMLElement.xml("<xml>1<a/><b/>2<c/>3<d/></xml>");
      expect(el.children.map((e) => e.tagName), ["a", "b", "c", "d"]);
    });

    test('overwrites nodes when set', () {
      final el = new XMLElement.xml("<xml>1<a/><b/>2<c/>3<d/></xml>");
      el.children = [new XMLElement.tag('x'), new XMLElement.tag('y')];
      expect(el.outerHTML, "<xml><x></x><y></y></xml>");
    });
  });

  group('classes', () {
    XMLElement makeElementWithClasses() =>
      new XMLElement.xml("<xml class='foo bar baz'></xml>");

    Set<String> makeClassSet() => makeElementWithClasses().classes;

    test('affects the "class" attribute', () {
      final el = makeElementWithClasses();
      el.classes.add('qux');
      expect(el.attributes['class'].split(' '),
          unorderedEquals(['foo', 'bar', 'baz', 'qux']));
    });

    test('is affected by the "class" attribute', () {
      final el = makeElementWithClasses();
      el.attributes['class'] = 'foo qux';
      expect(el.classes, unorderedEquals(['foo', 'qux']));
    });

    test('classes=', () {
      final el = makeElementWithClasses();
      el.classes = ['foo', 'qux'];
      expect(el.classes, unorderedEquals(['foo', 'qux']));
      expect(el.attributes['class'].split(' '),
          unorderedEquals(['foo', 'qux']));
    });

    test('toString', () {
      expect(makeClassSet().toString().split(' '),
          unorderedEquals(['foo', 'bar', 'baz']));
      expect(makeElement().classes.toString(), '');
    });

    test('forEach', () {
      final classes = <String>[];
      makeClassSet().forEach(classes.add);
      expect(classes, unorderedEquals(['foo', 'bar', 'baz']));
    });

    test('iterator', () {
      final classes = <String>[];
      for (var el in makeClassSet()) {
        classes.add(el);
      }
      expect(classes, unorderedEquals(['foo', 'bar', 'baz']));
    });

    test('map', () {
      expect(makeClassSet().map((c) => c.toUpperCase()),
          unorderedEquals(['FOO', 'BAR', 'BAZ']));
    });

    test('filter', () {
      expect(makeClassSet().filter((c) => c.contains('a')),
          unorderedEquals(['bar', 'baz']));
    });

    test('every', () {
      expect(makeClassSet().every((c) => c is String), isTrue);
      expect(makeClassSet().every((c) => c.contains('a')), isFalse);
    });

    test('some', () {
      expect(makeClassSet().some((c) => c.contains('a')), isTrue);
      expect(makeClassSet().some((c) => c is num), isFalse);
    });

    test('isEmpty', () {
      expect(makeClassSet().isEmpty, isFalse);
      expect(makeElement().classes.isEmpty, isTrue);
    });

    test('length', () {
      expect(makeClassSet().length, 3);
      expect(makeElement().classes.length, 0);
    });

    test('contains', () {
      expect(makeClassSet().contains('foo'), isTrue);
      expect(makeClassSet().contains('qux'), isFalse);
    });

    test('add', () {
      final classes = makeClassSet();
      classes.add('qux');
      expect(classes, unorderedEquals(['foo', 'bar', 'baz', 'qux']));

      classes.add('qux');
      final list = new List.from(classes);
      list.sort((a, b) => a.compareTo(b));
      expect(list, ['bar', 'baz', 'foo', 'qux'],
          reason: "The class set shouldn't have duplicate elements.");
    });

    test('remove', () {
      final classes = makeClassSet();
      classes.remove('bar');
      expect(classes, unorderedEquals(['foo', 'baz']));
      classes.remove('qux');
      expect(classes, unorderedEquals(['foo', 'baz']));
    });

    test('addAll', () {
      final classes = makeClassSet();
      classes.addAll(['bar', 'qux', 'bip']);
      expect(classes, unorderedEquals(['foo', 'bar', 'baz', 'qux', 'bip']));
    });

    test('removeAll', () {
      final classes = makeClassSet();
      classes.removeAll(['bar', 'baz', 'qux']);
      expect(classes, ['foo']);
    });

    test('isSubsetOf', () {
      final classes = makeClassSet();
      expect(classes.isSubsetOf(['foo', 'bar', 'baz']), isTrue);
      expect(classes.isSubsetOf(['foo', 'bar', 'baz', 'qux']), isTrue);
      expect(classes.isSubsetOf(['foo', 'bar', 'qux']), isFalse);
    });

    test('containsAll', () {
      final classes = makeClassSet();
      expect(classes.containsAll(['foo', 'baz']), isTrue);
      expect(classes.containsAll(['foo', 'qux']), isFalse);
    });

    test('intersection', () {
      final classes = makeClassSet();
      expect(classes.intersection(['foo', 'qux', 'baz']),
          unorderedEquals(['foo', 'baz']));
    });

    test('clear', () {
      final classes = makeClassSet();
      classes.clear();
      expect(classes, []);
    });
  });

  test("no-op methods don't throw errors", () {
    final el = makeElement();
    el.on.click.add((e) => null);
    el.blur();
    el.focus();
    el.scrollByLines(2);
    el.scrollByPages(2);
    el.scrollIntoView();
  });

  group('properties that map to attributes', () {
    group('contentEditable', () {
      test('get', () {
        final el = makeElement();
        expect(el.contentEditable, 'inherit');
        el.attributes['contentEditable'] = 'foo';
        expect(el.contentEditable, 'foo');
      });

      test('set', () {
        final el = makeElement();
        el.contentEditable = 'foo';
        expect(el.attributes['contentEditable'], 'foo');
      });

      test('isContentEditable', () {
        final el = makeElement();
        expect(el.isContentEditable, isFalse);
        el.contentEditable = 'true';
        expect(el.isContentEditable, isFalse);
      });
    });

    group('draggable', () {
      test('get', () {
        final el = makeElement();
        expect(el.draggable, isFalse);
        el.attributes['draggable'] = 'true';
        expect(el.draggable, isTrue);
        el.attributes['draggable'] = 'foo';
        expect(el.draggable, isFalse);
      });

      test('set', () {
        final el = makeElement();
        el.draggable = true;
        expect(el.attributes['draggable'], 'true');
        el.draggable = false;
        expect(el.attributes['draggable'], 'false');
      });
    });

    group('spellcheck', () {
      test('get', () {
        final el = makeElement();
        expect(el.spellcheck, isFalse);
        el.attributes['spellcheck'] = 'true';
        expect(el.spellcheck, isTrue);
        el.attributes['spellcheck'] = 'foo';
        expect(el.spellcheck, isFalse);
      });

      test('set', () {
        final el = makeElement();
        el.spellcheck = true;
        expect(el.attributes['spellcheck'], 'true');
        el.spellcheck = false;
        expect(el.attributes['spellcheck'], 'false');
      });
    });

    group('hidden', () {
      test('get', () {
        final el = makeElement();
        expect(el.hidden, isFalse);
        el.attributes['hidden'] = '';
        expect(el.hidden, isTrue);
      });

      test('set', () {
        final el = makeElement();
        el.hidden = true;
        expect(el.attributes['hidden'], '');
        el.hidden = false;
        expect(el.attributes.containsKey('hidden'), isFalse);
      });
    });

    group('tabIndex', () {
      test('get', () {
        final el = makeElement();
        expect(el.tabIndex, 0);
        el.attributes['tabIndex'] = '2';
        expect(el.tabIndex, 2);
        el.attributes['tabIndex'] = 'foo';
        expect(el.tabIndex, 0);
      });

      test('set', () {
        final el = makeElement();
        el.tabIndex = 15;
        expect(el.attributes['tabIndex'], '15');
      });
    });

    group('id', () {
      test('get', () {
        final el = makeElement();
        expect(el.id, '');
        el.attributes['id'] = 'foo';
        expect(el.id, 'foo');
      });

      test('set', () {
        final el = makeElement();
        el.id = 'foo';
        expect(el.attributes['id'], 'foo');
      });
    });

    group('title', () {
      test('get', () {
        final el = makeElement();
        expect(el.title, '');
        el.attributes['title'] = 'foo';
        expect(el.title, 'foo');
      });

      test('set', () {
        final el = makeElement();
        el.title = 'foo';
        expect(el.attributes['title'], 'foo');
      });
    });

    group('webkitdropzone', () {
      test('get', () {
        final el = makeElement();
        expect(el.webkitdropzone, '');
        el.attributes['webkitdropzone'] = 'foo';
        expect(el.webkitdropzone, 'foo');
      });

      test('set', () {
        final el = makeElement();
        el.webkitdropzone = 'foo';
        expect(el.attributes['webkitdropzone'], 'foo');
      });
    });

    group('lang', () {
      test('get', () {
        final el = makeElement();
        expect(el.lang, '');
        el.attributes['lang'] = 'foo';
        expect(el.lang, 'foo');
      });

      test('set', () {
        final el = makeElement();
        el.lang = 'foo';
        expect(el.attributes['lang'], 'foo');
      });
    });

    group('dir', () {
      test('get', () {
        final el = makeElement();
        expect(el.dir, '');
        el.attributes['dir'] = 'foo';
        expect(el.dir, 'foo');
      });

      test('set', () {
        final el = makeElement();
        el.dir = 'foo';
        expect(el.attributes['dir'], 'foo');
      });
    });
  });

  test('set innerHTML', () {
    final el = makeElement();
    el.innerHTML = "<foo>Bar<baz/></foo>";
    expect(el.nodes.length, 1);
    final node = el.nodes[0];
    expect(node, isXMLElement);
    expect(node.tagName, 'foo');
    expect(node.nodes[0].text, 'Bar');
    expect(node.nodes[1].tagName, 'baz');
  });

  test('get innerHTML/outerHTML', () {
    final el = makeElement();
    expect(el.innerHTML, "<foo></foo><bar></bar>");
    el.nodes.clear();
    el.nodes.addAll([new Text("foo"), new XMLElement.xml("<a>bar</a>")]);
    expect(el.innerHTML, "foo<a>bar</a>");
    expect(el.outerHTML, "<xml>foo<a>bar</a></xml>");
  });

  test('query', () {
    final el = makeElement();
    expect(el.query('foo').tagName, 'foo');
    expect(el.query('baz'), isNull);
  });

  test('queryAll', () {
    final el = new XMLElement.xml(
        "<xml><foo id='f1' /><bar><foo id='f2' /></bar></xml>");
    expect(el.queryAll('foo').map((e) => e.id), ['f1', 'f2']);
    expect(el.queryAll('baz'), []);
  });

  // TODO(nweiz): re-enable this when matchesSelector works cross-browser.
  //
  // test('matchesSelector', () {
  //   final el = makeElement();
  //   expect(el.matchesSelector('*'), isTrue);
  //   expect(el.matchesSelector('xml'), isTrue);
  //   expect(el.matchesSelector('html'), isFalse);
  // });

  group('insertAdjacentElement', () {
    test('beforeBegin with no parent does nothing', () {
      final el = makeElement();
      expect(el.insertAdjacentElement("beforeBegin", new XMLElement.tag("b")),
          isNull);
      expect(el.innerHTML, "<foo></foo><bar></bar>");
    });

    test('afterEnd with no parent does nothing', () {
      final el = makeElement();
      expect(
        el.insertAdjacentElement("afterEnd", new XMLElement.tag("b")), isNull);
      expect(el.innerHTML, "<foo></foo><bar></bar>");
    });

    test('beforeBegin with parent inserts the element', () {
      final el = makeElementWithParent();
      final newEl = new XMLElement.tag("b");
      expect(el.insertAdjacentElement("beforeBegin", newEl), newEl);
      expect(el.innerHTML, "<foo></foo><bar></bar>");
      expect(el.parent.innerHTML,
          "<before></before><b></b><xml><foo></foo><bar></bar>"
          "</xml><after></after>");
    });

    test('afterEnd with parent inserts the element', () {
      final el = makeElementWithParent();
      final newEl = new XMLElement.tag("b");
      expect(el.insertAdjacentElement("afterEnd", newEl), newEl);
      expect(el.innerHTML, "<foo></foo><bar></bar>");
      expect(el.parent.innerHTML,
          "<before></before><xml><foo></foo><bar></bar></xml><b>"
          "</b><after></after>");
    });

    test('afterBegin inserts the element', () {
      final el = makeElement();
      final newEl = new XMLElement.tag("b");
      expect(el.insertAdjacentElement("afterBegin", newEl), newEl);
      expect(el.innerHTML, "<b></b><foo></foo><bar></bar>");
    });

    test('beforeEnd inserts the element', () {
      final el = makeElement();
      final newEl = new XMLElement.tag("b");
      expect(el.insertAdjacentElement("beforeEnd", newEl), newEl);
      expect(el.innerHTML, "<foo></foo><bar></bar><b></b>");
    });
  });

  group('insertAdjacentText', () {
    test('beforeBegin with no parent does nothing', () {
      final el = makeElement();
      el.insertAdjacentText("beforeBegin", "foo");
      expect(el.innerHTML, "<foo></foo><bar></bar>");
    });

    test('afterEnd with no parent does nothing', () {
      final el = makeElement();
      el.insertAdjacentText("afterEnd", "foo");
      expect(el.innerHTML, "<foo></foo><bar></bar>");
    });

    test('beforeBegin with parent inserts the text', () {
      final el = makeElementWithParent();
      el.insertAdjacentText("beforeBegin", "foo");
      expect(el.innerHTML, "<foo></foo><bar></bar>");
      expect(el.parent.innerHTML,
          "<before></before>foo<xml><foo></foo><bar></bar></xml>"
          "<after></after>");
    });

    test('afterEnd with parent inserts the text', () {
      final el = makeElementWithParent();
      el.insertAdjacentText("afterEnd", "foo");
      expect(el.innerHTML, "<foo></foo><bar></bar>");
      expect(el.parent.innerHTML,
          "<before></before><xml><foo></foo><bar></bar></xml>foo"
          "<after></after>");
    });

    test('afterBegin inserts the text', () {
      final el = makeElement();
      el.insertAdjacentText("afterBegin", "foo");
      expect(el.innerHTML, "foo<foo></foo><bar></bar>");
    });

    test('beforeEnd inserts the text', () {
      final el = makeElement();
      el.insertAdjacentText("beforeEnd", "foo");
      expect(el.innerHTML, "<foo></foo><bar></bar>foo");
    });
  });

  group('insertAdjacentHTML', () {
    test('beforeBegin with no parent does nothing', () {
      final el = makeElement();
      el.insertAdjacentHTML("beforeBegin", "foo<b/>");
      expect(el.innerHTML, "<foo></foo><bar></bar>");
    });

    test('afterEnd with no parent does nothing', () {
      final el = makeElement();
      el.insertAdjacentHTML("afterEnd", "<b/>foo");
      expect(el.innerHTML, "<foo></foo><bar></bar>");
    });

    test('beforeBegin with parent inserts the HTML', () {
      final el = makeElementWithParent();
      el.insertAdjacentHTML("beforeBegin", "foo<b/>");
      expect(el.innerHTML, "<foo></foo><bar></bar>");
      expect(el.parent.innerHTML,
          "<before></before>foo<b></b><xml><foo></foo><bar></bar>"
          "</xml><after></after>");
    });

    test('afterEnd with parent inserts the HTML', () {
      final el = makeElementWithParent();
      el.insertAdjacentHTML("afterEnd", "foo<b/>");
      expect(el.innerHTML, "<foo></foo><bar></bar>");
      expect(el.parent.innerHTML,
          "<before></before><xml><foo></foo><bar></bar></xml>foo"
          "<b></b><after></after>");
    });

    test('afterBegin inserts the HTML', () {
      final el = makeElement();
      el.insertAdjacentHTML("afterBegin", "foo<b/>");
      expect(el.innerHTML, "foo<b></b><foo></foo><bar></bar>");
    });

    test('beforeEnd inserts the HTML', () {
      final el = makeElement();
      el.insertAdjacentHTML("beforeEnd", "<b/>foo");
      expect(el.innerHTML, "<foo></foo><bar></bar><b></b>foo");
    });
  });

  test('default rect values', () {
    makeElement().rect.then(
      expectAsync1(ElementRect rect) {
        expectEmptyRect(rect.client);
        expectEmptyRect(rect.offset);
        expectEmptyRect(rect.scroll);
        expectEmptyRect(rect.bounding);
        expect(rect.clientRects.isEmpty, isTrue);
      }));
  });
}
