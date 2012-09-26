// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('XMLElementTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  XMLElement makeElement() => new XMLElement.xml("<xml><foo/><bar/></xml>");

  makeElementWithParent() {
    final parent = new XMLElement.xml(
        "<parent><before/><xml><foo/><bar/></xml><after/></parent>");
    return parent.elements[1];
  }

  group('constructors', () {
    group('.xml', () {
      test('with a well-formed document', () {
        final el = makeElement();
        Expect.isTrue(el is XMLElement);
        Expect.equals('foo', el.elements[0].tagName);
        Expect.equals('bar', el.elements[1].tagName);
      });

      test('with too many nodes', () {
        Expect.throws(() => new XMLElement.xml("<xml></xml>foo"),
            (e) => e is ArgumentError);
      });

      test('with a parse error', () {
        Expect.throws(() => new XMLElement.xml("<xml></xml>>"),
            (e) => e is ArgumentError);
      });

      test('with a PARSERERROR tag', () {
        final el = new XMLElement.xml("<xml><parsererror /></xml>");
        Expect.equals('parsererror', el.elements[0].tagName);
      });

      test('has no parent', () =>
          Expect.isNull(new XMLElement.xml('<foo/>').parent));
    });

    test('.tag', () {
      final el = new XMLElement.tag('foo');
      Expect.isTrue(el is XMLElement);
      Expect.equals('foo', el.tagName);
    });
  });

  // FilteredElementList is tested more thoroughly in DocumentFragmentTests.
  group('elements', () {
    test('filters out non-element nodes', () {
      final el = new XMLElement.xml("<xml>1<a/><b/>2<c/>3<d/></xml>");
      Expect.listEquals(["a", "b", "c", "d"], el.elements.map((e) => e.tagName));
    });

    test('overwrites nodes when set', () {
      final el = new XMLElement.xml("<xml>1<a/><b/>2<c/>3<d/></xml>");
      el.elements = [new XMLElement.tag('x'), new XMLElement.tag('y')];
      Expect.equals("<xml><x></x><y></y></xml>", el.outerHTML);
    });
  });

  group('classes', () {
    XMLElement makeElementWithClasses() =>
      new XMLElement.xml("<xml class='foo bar baz'></xml>");

    Set<String> makeClassSet() => makeElementWithClasses().classes;

    test('affects the "class" attribute', () {
      final el = makeElementWithClasses();
      el.classes.add('qux');
      Expect.setEquals(['foo', 'bar', 'baz', 'qux'],
          el.attributes['class'].split(' '));
    });

    test('is affected by the "class" attribute', () {
      final el = makeElementWithClasses();
      el.attributes['class'] = 'foo qux';
      Expect.setEquals(['foo', 'qux'], el.classes);
    });

    test('classes=', () {
      final el = makeElementWithClasses();
      el.classes = ['foo', 'qux'];
      Expect.setEquals(['foo', 'qux'], el.classes);
      Expect.setEquals(['foo', 'qux'], el.attributes['class'].split(' '));
    });

    test('toString', () {
      Expect.setEquals(['foo', 'bar', 'baz'],
          makeClassSet().toString().split(' '));
      Expect.equals('', makeElement().classes.toString());
    });

    test('forEach', () {
      final classes = <String>[];
      makeClassSet().forEach(classes.add);
      Expect.setEquals(['foo', 'bar', 'baz'], classes);
    });

    test('iterator', () {
      final classes = <String>[];
      for (var el in makeClassSet()) {
        classes.add(el);
      }
      Expect.setEquals(['foo', 'bar', 'baz'], classes);
    });

    test('map', () {
      Expect.setEquals(['FOO', 'BAR', 'BAZ'],
          makeClassSet().map((c) => c.toUpperCase()));
    });

    test('filter', () {
      Expect.setEquals(['bar', 'baz'],
          makeClassSet().filter((c) => c.contains('a')));
    });

    test('every', () {
      Expect.isTrue(makeClassSet().every((c) => c is String));
      Expect.isFalse(
          makeClassSet().every((c) => c.contains('a')));
    });

    test('some', () {
      Expect.isTrue(
          makeClassSet().some((c) => c.contains('a')));
      Expect.isFalse(makeClassSet().some((c) => c is num));
    });

    test('isEmpty', () {
      Expect.isFalse(makeClassSet().isEmpty());
      Expect.isTrue(makeElement().classes.isEmpty());
    });

    test('length', () {
      Expect.equals(3, makeClassSet().length);
      Expect.equals(0, makeElement().classes.length);
    });

    test('contains', () {
      Expect.isTrue(makeClassSet().contains('foo'));
      Expect.isFalse(makeClassSet().contains('qux'));
    });

    test('add', () {
      final classes = makeClassSet();
      classes.add('qux');
      Expect.setEquals(['foo', 'bar', 'baz', 'qux'], classes);

      classes.add('qux');
      final list = new List.from(classes);
      list.sort((a, b) => a.compareTo(b));
      Expect.listEquals(['bar', 'baz', 'foo', 'qux'], list,
          "The class set shouldn't have duplicate elements.");
    });

    test('remove', () {
      final classes = makeClassSet();
      classes.remove('bar');
      Expect.setEquals(['foo', 'baz'], classes);
      classes.remove('qux');
      Expect.setEquals(['foo', 'baz'], classes);
    });

    test('addAll', () {
      final classes = makeClassSet();
      classes.addAll(['bar', 'qux', 'bip']);
      Expect.setEquals(['foo', 'bar', 'baz', 'qux', 'bip'], classes);
    });

    test('removeAll', () {
      final classes = makeClassSet();
      classes.removeAll(['bar', 'baz', 'qux']);
      Expect.setEquals(['foo'], classes);
    });

    test('isSubsetOf', () {
      final classes = makeClassSet();
      Expect.isTrue(classes.isSubsetOf(['foo', 'bar', 'baz']));
      Expect.isTrue(classes.isSubsetOf(['foo', 'bar', 'baz', 'qux']));
      Expect.isFalse(classes.isSubsetOf(['foo', 'bar', 'qux']));
    });

    test('containsAll', () {
      final classes = makeClassSet();
      Expect.isTrue(classes.containsAll(['foo', 'baz']));
      Expect.isFalse(classes.containsAll(['foo', 'qux']));
    });

    test('intersection', () {
      final classes = makeClassSet();
      Expect.setEquals(['foo', 'baz'],
          classes.intersection(['foo', 'qux', 'baz']));
    });

    test('clear', () {
      final classes = makeClassSet();
      classes.clear();
      Expect.setEquals([], classes);
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
        Expect.equals('inherit', el.contentEditable);
        el.attributes['contentEditable'] = 'foo';
        Expect.equals('foo', el.contentEditable);
      });

      test('set', () {
        final el = makeElement();
        el.contentEditable = 'foo';
        Expect.equals('foo', el.attributes['contentEditable']);
      });

      test('isContentEditable', () {
        final el = makeElement();
        Expect.isFalse(el.isContentEditable);
        el.contentEditable = 'true';
        Expect.isFalse(el.isContentEditable);
      });
    });

    group('draggable', () {
      test('get', () {
        final el = makeElement();
        Expect.isFalse(el.draggable);
        el.attributes['draggable'] = 'true';
        Expect.isTrue(el.draggable);
        el.attributes['draggable'] = 'foo';
        Expect.isFalse(el.draggable);
      });

      test('set', () {
        final el = makeElement();
        el.draggable = true;
        Expect.equals('true', el.attributes['draggable']);
        el.draggable = false;
        Expect.equals('false', el.attributes['draggable']);
      });
    });

    group('spellcheck', () {
      test('get', () {
        final el = makeElement();
        Expect.isFalse(el.spellcheck);
        el.attributes['spellcheck'] = 'true';
        Expect.isTrue(el.spellcheck);
        el.attributes['spellcheck'] = 'foo';
        Expect.isFalse(el.spellcheck);
      });

      test('set', () {
        final el = makeElement();
        el.spellcheck = true;
        Expect.equals('true', el.attributes['spellcheck']);
        el.spellcheck = false;
        Expect.equals('false', el.attributes['spellcheck']);
      });
    });

    group('hidden', () {
      test('get', () {
        final el = makeElement();
        Expect.isFalse(el.hidden);
        el.attributes['hidden'] = '';
        Expect.isTrue(el.hidden);
      });

      test('set', () {
        final el = makeElement();
        el.hidden = true;
        Expect.equals('', el.attributes['hidden']);
        el.hidden = false;
        Expect.isFalse(el.attributes.containsKey('hidden'));
      });
    });

    group('tabIndex', () {
      test('get', () {
        final el = makeElement();
        Expect.equals(0, el.tabIndex);
        el.attributes['tabIndex'] = '2';
        Expect.equals(2, el.tabIndex);
        el.attributes['tabIndex'] = 'foo';
        Expect.equals(0, el.tabIndex);
      });

      test('set', () {
        final el = makeElement();
        el.tabIndex = 15;
        Expect.equals('15', el.attributes['tabIndex']);
      });
    });

    group('id', () {
      test('get', () {
        final el = makeElement();
        Expect.equals('', el.id);
        el.attributes['id'] = 'foo';
        Expect.equals('foo', el.id);
      });

      test('set', () {
        final el = makeElement();
        el.id = 'foo';
        Expect.equals('foo', el.attributes['id']);
      });
    });

    group('title', () {
      test('get', () {
        final el = makeElement();
        Expect.equals('', el.title);
        el.attributes['title'] = 'foo';
        Expect.equals('foo', el.title);
      });

      test('set', () {
        final el = makeElement();
        el.title = 'foo';
        Expect.equals('foo', el.attributes['title']);
      });
    });

    group('webkitdropzone', () {
      test('get', () {
        final el = makeElement();
        Expect.equals('', el.webkitdropzone);
        el.attributes['webkitdropzone'] = 'foo';
        Expect.equals('foo', el.webkitdropzone);
      });

      test('set', () {
        final el = makeElement();
        el.webkitdropzone = 'foo';
        Expect.equals('foo', el.attributes['webkitdropzone']);
      });
    });

    group('lang', () {
      test('get', () {
        final el = makeElement();
        Expect.equals('', el.lang);
        el.attributes['lang'] = 'foo';
        Expect.equals('foo', el.lang);
      });

      test('set', () {
        final el = makeElement();
        el.lang = 'foo';
        Expect.equals('foo', el.attributes['lang']);
      });
    });

    group('dir', () {
      test('get', () {
        final el = makeElement();
        Expect.equals('', el.dir);
        el.attributes['dir'] = 'foo';
        Expect.equals('foo', el.dir);
      });

      test('set', () {
        final el = makeElement();
        el.dir = 'foo';
        Expect.equals('foo', el.attributes['dir']);
      });
    });
  });

  test('set innerHTML', () {
    final el = makeElement();
    el.innerHTML = "<foo>Bar<baz/></foo>";
    Expect.equals(1, el.nodes.length);
    final node = el.nodes[0];
    Expect.isTrue(node is XMLElement);
    Expect.equals('foo', node.tagName);
    Expect.equals('Bar', node.nodes[0].text);
    Expect.equals('baz', node.nodes[1].tagName);
  });

  test('get innerHTML/outerHTML', () {
    final el = makeElement();
    Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
    el.nodes.clear();
    el.nodes.addAll([new Text("foo"), new XMLElement.xml("<a>bar</a>")]);
    Expect.equals("foo<a>bar</a>", el.innerHTML);
    Expect.equals("<xml>foo<a>bar</a></xml>", el.outerHTML);
  });

  test('query', () {
    final el = makeElement();
    Expect.equals("foo", el.query('foo').tagName);
    Expect.isNull(el.query('baz'));
  });

  test('queryAll', () {
    final el = new XMLElement.xml(
        "<xml><foo id='f1' /><bar><foo id='f2' /></bar></xml>");
    Expect.listEquals(["f1", "f2"], el.queryAll('foo').map((e) => e.id));
    Expect.listEquals([], el.queryAll('baz'));
  });

  // TODO(nweiz): re-enable this when matchesSelector works cross-browser.
  //
  // test('matchesSelector', () {
  //   final el = makeElement();
  //   Expect.isTrue(el.matchesSelector('*'));
  //   Expect.isTrue(el.matchesSelector('xml'));
  //   Expect.isFalse(el.matchesSelector('html'));
  // });

  group('insertAdjacentElement', () {
    test('beforeBegin with no parent does nothing', () {
      final el = makeElement();
      Expect.isNull(
        el.insertAdjacentElement("beforeBegin", new XMLElement.tag("b")));
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
    });

    test('afterEnd with no parent does nothing', () {
      final el = makeElement();
      Expect.isNull(
        el.insertAdjacentElement("afterEnd", new XMLElement.tag("b")));
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
    });

    test('beforeBegin with parent inserts the element', () {
      final el = makeElementWithParent();
      final newEl = new XMLElement.tag("b");
      Expect.equals(newEl, el.insertAdjacentElement("beforeBegin", newEl));
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
      Expect.equals("<before></before><b></b><xml><foo></foo><bar></bar>" +
          "</xml><after></after>", el.parent.innerHTML);
    });

    test('afterEnd with parent inserts the element', () {
      final el = makeElementWithParent();
      final newEl = new XMLElement.tag("b");
      Expect.equals(newEl, el.insertAdjacentElement("afterEnd", newEl));
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
      Expect.equals("<before></before><xml><foo></foo><bar></bar></xml><b>" +
          "</b><after></after>", el.parent.innerHTML);
    });

    test('afterBegin inserts the element', () {
      final el = makeElement();
      final newEl = new XMLElement.tag("b");
      Expect.equals(newEl, el.insertAdjacentElement("afterBegin", newEl));
      Expect.equals("<b></b><foo></foo><bar></bar>", el.innerHTML);
    });

    test('beforeEnd inserts the element', () {
      final el = makeElement();
      final newEl = new XMLElement.tag("b");
      Expect.equals(newEl, el.insertAdjacentElement("beforeEnd", newEl));
      Expect.equals("<foo></foo><bar></bar><b></b>", el.innerHTML);
    });
  });

  group('insertAdjacentText', () {
    test('beforeBegin with no parent does nothing', () {
      final el = makeElement();
      el.insertAdjacentText("beforeBegin", "foo");
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
    });

    test('afterEnd with no parent does nothing', () {
      final el = makeElement();
      el.insertAdjacentText("afterEnd", "foo");
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
    });

    test('beforeBegin with parent inserts the text', () {
      final el = makeElementWithParent();
      el.insertAdjacentText("beforeBegin", "foo");
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
      Expect.equals("<before></before>foo<xml><foo></foo><bar></bar></xml>" +
          "<after></after>", el.parent.innerHTML);
    });

    test('afterEnd with parent inserts the text', () {
      final el = makeElementWithParent();
      el.insertAdjacentText("afterEnd", "foo");
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
      Expect.equals("<before></before><xml><foo></foo><bar></bar></xml>foo" +
          "<after></after>", el.parent.innerHTML);
    });

    test('afterBegin inserts the text', () {
      final el = makeElement();
      el.insertAdjacentText("afterBegin", "foo");
      Expect.equals("foo<foo></foo><bar></bar>", el.innerHTML);
    });

    test('beforeEnd inserts the text', () {
      final el = makeElement();
      el.insertAdjacentText("beforeEnd", "foo");
      Expect.equals("<foo></foo><bar></bar>foo", el.innerHTML);
    });
  });

  group('insertAdjacentHTML', () {
    test('beforeBegin with no parent does nothing', () {
      final el = makeElement();
      el.insertAdjacentHTML("beforeBegin", "foo<b/>");
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
    });

    test('afterEnd with no parent does nothing', () {
      final el = makeElement();
      el.insertAdjacentHTML("afterEnd", "<b/>foo");
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
    });

    test('beforeBegin with parent inserts the HTML', () {
      final el = makeElementWithParent();
      el.insertAdjacentHTML("beforeBegin", "foo<b/>");
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
      Expect.equals("<before></before>foo<b></b><xml><foo></foo><bar></bar>" +
          "</xml><after></after>", el.parent.innerHTML);
    });

    test('afterEnd with parent inserts the HTML', () {
      final el = makeElementWithParent();
      el.insertAdjacentHTML("afterEnd", "foo<b/>");
      Expect.equals("<foo></foo><bar></bar>", el.innerHTML);
      Expect.equals("<before></before><xml><foo></foo><bar></bar></xml>foo" +
          "<b></b><after></after>", el.parent.innerHTML);
    });

    test('afterBegin inserts the HTML', () {
      final el = makeElement();
      el.insertAdjacentHTML("afterBegin", "foo<b/>");
      Expect.equals("foo<b></b><foo></foo><bar></bar>", el.innerHTML);
    });

    test('beforeEnd inserts the HTML', () {
      final el = makeElement();
      el.insertAdjacentHTML("beforeEnd", "<b/>foo");
      Expect.equals("<foo></foo><bar></bar><b></b>foo", el.innerHTML);
    });
  });

  test('default rect values', () {
    makeElement().rect.then(
      expectAsync1(ElementRect rect) {
        expectEmptyRect(rect.client);
        expectEmptyRect(rect.offset);
        expectEmptyRect(rect.scroll);
        expectEmptyRect(rect.bounding);
        Expect.isTrue(rect.clientRects.isEmpty());
      }));
  });
}
