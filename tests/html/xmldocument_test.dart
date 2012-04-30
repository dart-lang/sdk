// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('XMLDocumentTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  XMLDocument makeDocument() => new XMLDocument.xml("<xml><foo/><bar/></xml>");

  group('constructor', () {
    test('with a well-formed document', () {
      final doc = makeDocument();
      Expect.isTrue(doc is XMLDocument);
      Expect.equals('foo', doc.elements[0].tagName);
      Expect.equals('bar', doc.elements[1].tagName);
    });

    // TODO(nweiz): re-enable this when Document#query matches the root-level
    // element. Otherwise it fails on Firefox.
    //
    // test('with a parse error', () {
    //   Expect.throws(() => new XMLDocument.xml("<xml></xml>foo"),
    //       (e) => e is IllegalArgumentException);
    // });

    test('with a PARSERERROR tag', () {
      final doc = new XMLDocument.xml("<xml><parsererror /></xml>");
      Expect.equals('parsererror', doc.elements[0].tagName);
    });
  });

  // FilteredElementList is tested more thoroughly in DocumentFragmentTests.
  group('elements', () {
    test('filters out non-element nodes', () {
      final doc = new XMLDocument.xml("<xml>1<a/><b/>2<c/>3<d/></xml>");
      Expect.listEquals(["a", "b", "c", "d"], doc.elements.map((e) => e.tagName));
    });

    test('overwrites nodes when set', () {
      final doc = new XMLDocument.xml("<xml>1<a/><b/>2<c/>3<d/></xml>");
      doc.elements = [new XMLElement.tag('x'), new XMLElement.tag('y')];
      Expect.equals("<xml><x></x><y></y></xml>", doc.outerHTML);
    });
  });

  group('classes', () {
    XMLDocument makeDocumentWithClasses() =>
      new XMLDocument.xml("<xml class='foo bar baz'></xml>");

    Set<String> makeClassSet() => makeDocumentWithClasses().classes;

    Set<String> extractClasses(Document doc) {
      final match = new RegExp('class="([^"]+)"').firstMatch(doc.outerHTML);
      return new Set.from(match[1].split(' '));
    }

    test('affects the "class" attribute', () {
      final doc = makeDocumentWithClasses();
      doc.classes.add('qux');
      Expect.setEquals(['foo', 'bar', 'baz', 'qux'], extractClasses(doc));
    });

    test('is affected by the "class" attribute', () {
      final doc = makeDocumentWithClasses();
      doc.attributes['class'] = 'foo qux';
      Expect.setEquals(['foo', 'qux'], doc.classes);
    });

    test('classes=', () {
      final doc = makeDocumentWithClasses();
      doc.classes = ['foo', 'qux'];
      Expect.setEquals(['foo', 'qux'], doc.classes);
      Expect.setEquals(['foo', 'qux'], extractClasses(doc));
    });

    test('toString', () {
      Expect.setEquals(['foo', 'bar', 'baz'],
          makeClassSet().toString().split(' '));
      Expect.equals('', makeDocument().classes.toString());
    });

    test('forEach', () {
      final classes = <String>[];
      makeClassSet().forEach(classes.add);
      Expect.setEquals(['foo', 'bar', 'baz'], classes);
    });

    test('iterator', () {
      final classes = <String>[];
      for (var doc in makeClassSet()) {
        classes.add(doc);
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
      Expect.isTrue(makeDocument().classes.isEmpty());
    });

    test('length', () {
      Expect.equals(3, makeClassSet().length);
      Expect.equals(0, makeDocument().classes.length);
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

  // XMLClassSet is tested more thoroughly in XMLElementTests.
  group('classes', () {
    XMLDocument makeDocumentWithClasses() =>
      new XMLDocument.xml("<xml class='foo bar baz'></xml>");

    test('affects the "class" attribute', () {
      final doc = makeDocumentWithClasses();
      doc.classes.add('qux');
      Expect.setEquals(['foo', 'bar', 'baz', 'qux'],
          doc.attributes['class'].split(' '));
    });

    test('is affected by the "class" attribute', () {
      final doc = makeDocumentWithClasses();
      doc.attributes['class'] = 'foo qux';
      Expect.setEquals(['foo', 'qux'], doc.classes);
    });
  });

  test("no-op methods don't throw errors", () {
    final doc = makeDocument();
    doc.on.click.add((e) => null);
    doc.blur();
    doc.focus();
    doc.scrollByLines(2);
    doc.scrollByPages(2);
    doc.scrollIntoView();
    Expect.isFalse(doc.execCommand("foo", false, "bar"));
  });

  group('properties that map to attributes', () {
    group('contentEditable', () {
      test('get', () {
        final doc = makeDocument();
        Expect.equals('inherit', doc.contentEditable);
        doc.attributes['contentEditable'] = 'foo';
        Expect.equals('foo', doc.contentEditable);
      });

      test('set', () {
        final doc = makeDocument();
        doc.contentEditable = 'foo';
        Expect.equals('foo', doc.attributes['contentEditable']);
      });

      test('isContentEditable', () {
        final doc = makeDocument();
        Expect.isFalse(doc.isContentEditable);
        doc.contentEditable = 'true';
        Expect.isFalse(doc.isContentEditable);
      });
    });

    group('draggable', () {
      test('get', () {
        final doc = makeDocument();
        Expect.isFalse(doc.draggable);
        doc.attributes['draggable'] = 'true';
        Expect.isTrue(doc.draggable);
        doc.attributes['draggable'] = 'foo';
        Expect.isFalse(doc.draggable);
      });

      test('set', () {
        final doc = makeDocument();
        doc.draggable = true;
        Expect.equals('true', doc.attributes['draggable']);
        doc.draggable = false;
        Expect.equals('false', doc.attributes['draggable']);
      });
    });

    group('spellcheck', () {
      test('get', () {
        final doc = makeDocument();
        Expect.isFalse(doc.spellcheck);
        doc.attributes['spellcheck'] = 'true';
        Expect.isTrue(doc.spellcheck);
        doc.attributes['spellcheck'] = 'foo';
        Expect.isFalse(doc.spellcheck);
      });

      test('set', () {
        final doc = makeDocument();
        doc.spellcheck = true;
        Expect.equals('true', doc.attributes['spellcheck']);
        doc.spellcheck = false;
        Expect.equals('false', doc.attributes['spellcheck']);
      });
    });

    group('hidden', () {
      test('get', () {
        final doc = makeDocument();
        Expect.isFalse(doc.hidden);
        doc.attributes['hidden'] = '';
        Expect.isTrue(doc.hidden);
      });

      test('set', () {
        final doc = makeDocument();
        doc.hidden = true;
        Expect.equals('', doc.attributes['hidden']);
        doc.hidden = false;
        Expect.isFalse(doc.attributes.containsKey('hidden'));
      });
    });

    group('tabIndex', () {
      test('get', () {
        final doc = makeDocument();
        Expect.equals(0, doc.tabIndex);
        doc.attributes['tabIndex'] = '2';
        Expect.equals(2, doc.tabIndex);
        doc.attributes['tabIndex'] = 'foo';
        Expect.equals(0, doc.tabIndex);
      });

      test('set', () {
        final doc = makeDocument();
        doc.tabIndex = 15;
        Expect.equals('15', doc.attributes['tabIndex']);
      });
    });

    group('id', () {
      test('get', () {
        final doc = makeDocument();
        Expect.equals('', doc.id);
        doc.attributes['id'] = 'foo';
        Expect.equals('foo', doc.id);
      });

      test('set', () {
        final doc = makeDocument();
        doc.id = 'foo';
        Expect.equals('foo', doc.attributes['id']);
      });
    });

    group('title', () {
      test('get', () {
        final doc = makeDocument();
        Expect.equals('', doc.title);
        doc.attributes['title'] = 'foo';
        Expect.equals('foo', doc.title);
      });

      test('set', () {
        final doc = makeDocument();
        doc.title = 'foo';
        Expect.equals('foo', doc.attributes['title']);
      });
    });

    // TODO(nweiz): re-enable this when the WebKit-specificness won't break
    // non-WebKit browsers.
    //
    // group('webkitdropzone', () {
    //   test('get', () {
    //     final doc = makeDocument();
    //     Expect.equals('', doc.webkitdropzone);
    //     doc.attributes['webkitdropzone'] = 'foo';
    //     Expect.equals('foo', doc.webkitdropzone);
    //   });
    //
    //   test('set', () {
    //     final doc = makeDocument();
    //     doc.webkitdropzone = 'foo';
    //     Expect.equals('foo', doc.attributes['webkitdropzone']);
    //   });
    // });

    group('lang', () {
      test('get', () {
        final doc = makeDocument();
        Expect.equals('', doc.lang);
        doc.attributes['lang'] = 'foo';
        Expect.equals('foo', doc.lang);
      });

      test('set', () {
        final doc = makeDocument();
        doc.lang = 'foo';
        Expect.equals('foo', doc.attributes['lang']);
      });
    });

    group('dir', () {
      test('get', () {
        final doc = makeDocument();
        Expect.equals('', doc.dir);
        doc.attributes['dir'] = 'foo';
        Expect.equals('foo', doc.dir);
      });

      test('set', () {
        final doc = makeDocument();
        doc.dir = 'foo';
        Expect.equals('foo', doc.attributes['dir']);
      });
    });
  });

  test('set innerHTML', () {
    final doc = makeDocument();
    doc.innerHTML = "<foo>Bar<baz/></foo>";
    Expect.equals(1, doc.nodes.length);
    final node = doc.nodes[0];
    Expect.isTrue(node is XMLElement);
    Expect.equals('foo', node.tagName);
    Expect.equals('Bar', node.nodes[0].text);
    Expect.equals('baz', node.nodes[1].tagName);
  });

  test('get innerHTML/outerHTML', () {
    final doc = makeDocument();
    Expect.equals("<foo></foo><bar></bar>", doc.innerHTML);
    doc.nodes.clear();
    doc.nodes.addAll([new Text("foo"), new XMLElement.xml("<a>bar</a>")]);
    Expect.equals("foo<a>bar</a>", doc.innerHTML);
    Expect.equals("<xml>foo<a>bar</a></xml>", doc.outerHTML);
  });

  test('query', () {
    final doc = makeDocument();
    Expect.equals("foo", doc.query('foo').tagName);
    Expect.isNull(doc.query('baz'));
  });

  test('queryAll', () {
    final doc = new XMLDocument.xml(
        "<xml><foo id='f1' /><bar><foo id='f2' /></bar></xml>");
    Expect.listEquals(["f1", "f2"], doc.queryAll('foo').map((e) => e.id));
    Expect.listEquals([], doc.queryAll('baz'));
  });

  // TODO(nweiz): re-enable this when matchesSelector works cross-browser.
  //
  // test('matchesSelector', () {
  //   final doc = makeDocument();
  //   Expect.isTrue(doc.matchesSelector('*'));
  //   Expect.isTrue(doc.matchesSelector('xml'));
  //   Expect.isFalse(doc.matchesSelector('html'));
  // });

  group('insertAdjacentElement', () {
    getDoc() => new XMLDocument.xml("<xml><a>foo</a></xml>");

    test('beforeBegin does nothing', () {
      final doc = getDoc();
      Expect.isNull(
        doc.insertAdjacentElement("beforeBegin", new XMLElement.tag("b")));
      Expect.equals("<a>foo</a>", doc.innerHTML);
    });

    test('afterEnd does nothing', () {
      final doc = getDoc();
      Expect.isNull(
        doc.insertAdjacentElement("afterEnd", new XMLElement.tag("b")));
      Expect.equals("<a>foo</a>", doc.innerHTML);
    });

    test('afterBegin inserts the element', () {
      final doc = getDoc();
      final el = new XMLElement.tag("b");
      Expect.equals(el, doc.insertAdjacentElement("afterBegin", el));
      Expect.equals("<b></b><a>foo</a>", doc.innerHTML);
    });

    test('beforeEnd inserts the element', () {
      final doc = getDoc();
      final el = new XMLElement.tag("b");
      Expect.equals(el, doc.insertAdjacentElement("beforeEnd", el));
      Expect.equals("<a>foo</a><b></b>", doc.innerHTML);
    });
  });

  group('insertAdjacentText', () {
    getDoc() => new XMLDocument.xml("<xml><a>foo</a></xml>");

    test('beforeBegin does nothing', () {
      final doc = getDoc();
      doc.insertAdjacentText("beforeBegin", "foo");
      Expect.equals("<a>foo</a>", doc.innerHTML);
    });

    test('afterEnd does nothing', () {
      final doc = getDoc();
      doc.insertAdjacentText("afterEnd", "foo");
      Expect.equals("<a>foo</a>", doc.innerHTML);
    });

    test('afterBegin inserts the text', () {
      final doc = getDoc();
      doc.insertAdjacentText("afterBegin", "foo");
      Expect.equals("foo<a>foo</a>", doc.innerHTML);
    });

    test('beforeEnd inserts the text', () {
      final doc = getDoc();
      doc.insertAdjacentText("beforeEnd", "foo");
      Expect.equals("<a>foo</a>foo", doc.innerHTML);
    });
  });

  group('insertAdjacentHTML', () {
    getDoc() => new XMLDocument.xml("<xml><a>foo</a></xml>");

    test('beforeBegin does nothing', () {
      final doc = getDoc();
      doc.insertAdjacentHTML("beforeBegin", "foo<b/>");
      Expect.equals("<a>foo</a>", doc.innerHTML);
    });

    test('afterEnd does nothing', () {
      final doc = getDoc();
      doc.insertAdjacentHTML("afterEnd", "<b/>foo");
      Expect.equals("<a>foo</a>", doc.innerHTML);
    });

    test('afterBegin inserts the HTML', () {
      final doc = getDoc();
      doc.insertAdjacentHTML("afterBegin", "foo<b/>");
      Expect.equals("foo<b></b><a>foo</a>", doc.innerHTML);
    });

    test('beforeEnd inserts the HTML', () {
      final doc = getDoc();
      doc.insertAdjacentHTML("beforeEnd", "<b/>foo");
      Expect.equals("<a>foo</a><b></b>foo", doc.innerHTML);
    });
  });

  group('default values', () {
    asyncTest('default rect values', 1, () {
      makeDocument().rect.then((ElementRect rect) {
        expectEmptyRect(rect.client);
        expectEmptyRect(rect.offset);
        expectEmptyRect(rect.scroll);
        expectEmptyRect(rect.bounding);
        Expect.isTrue(rect.clientRects.isEmpty());
        callbackDone();
      });
    });

    test('nextElementSibling', () =>
        Expect.isNull(makeDocument().nextElementSibling));
    test('previousElementSibling', () =>
        Expect.isNull(makeDocument().previousElementSibling));
    test('parent', () => Expect.isNull(makeDocument().parent));
    test('offsetParent', () => Expect.isNull(makeDocument().offsetParent));
    test('activeElement', () => Expect.isNull(makeDocument().activeElement));
    test('body', () => Expect.isNull(makeDocument().body));
    test('window', () => Expect.isNull(makeDocument().window));
    test('domain', () => Expect.equals('', makeDocument().domain));
    test('head', () => Expect.isNull(makeDocument().head));
    test('referrer', () => Expect.equals('', makeDocument().referrer));
    test('styleSheets', () =>
        Expect.listEquals([], makeDocument().styleSheets));
    test('title', () => Expect.equals('', makeDocument().title));

    // TODO(nweiz): IE sets the charset to "windows-1252". How do we want to
    // handle that?
    //
    // test('charset', () => Expect.isNull(makeDocument().charset));

    // TODO(nweiz): re-enable these when the WebKit-specificness won't break
    // non-WebKit browsers.
    //
    // test('webkitHidden', () => Expect.isFalse(makeDocument().webkitHidden));
    // test('webkitVisibilityState', () =>
    //     Expect.equals('visible', makeDocument().webkitVisibilityState));

    asyncTest('caretRangeFromPoint', 1, () {
      final doc = makeDocument();
      Futures.wait([
        doc.caretRangeFromPoint(),
        doc.caretRangeFromPoint(0, 0),
        doc.caretRangeFromPoint(5, 5)
      ]).then((ranges) {
        Expect.listEquals([null, null, null], ranges);
        callbackDone();
      });
    });

    asyncTest('elementFromPoint', 1, () {
      final doc = makeDocument();
      Futures.wait([
        doc.elementFromPoint(),
        doc.elementFromPoint(0, 0),
        doc.elementFromPoint(5, 5)
      ]).then((ranges) {
        Expect.listEquals([null, null, null], ranges);
        callbackDone();
      });
    });

    test('queryCommandEnabled', () {
      Expect.isFalse(makeDocument().queryCommandEnabled('foo'));
      Expect.isFalse(makeDocument().queryCommandEnabled('bold'));
    });

    test('queryCommandIndeterm', () {
      Expect.isFalse(makeDocument().queryCommandIndeterm('foo'));
      Expect.isFalse(makeDocument().queryCommandIndeterm('bold'));
    });

    test('queryCommandState', () {
      Expect.isFalse(makeDocument().queryCommandState('foo'));
      Expect.isFalse(makeDocument().queryCommandState('bold'));
    });

    test('queryCommandSupported', () {
      Expect.isFalse(makeDocument().queryCommandSupported('foo'));
      Expect.isFalse(makeDocument().queryCommandSupported('bold'));
    });

    test('manifest', () => Expect.equals('', makeDocument().manifest));
  });

  test('unsupported operations', () {
    expectUnsupported(() { makeDocument().body = new XMLElement.tag('xml'); });
    expectUnsupported(() => makeDocument().cookie);
    expectUnsupported(() { makeDocument().cookie = 'foo'; });
    expectUnsupported(() { makeDocument().manifest = 'foo'; });
  });
}
