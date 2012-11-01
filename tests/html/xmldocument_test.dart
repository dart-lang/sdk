// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('XMLDocumentTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  var isXMLDocument = predicate((x) => x is XMLDocument, 'is an XMLDocument');
  var isXMLElement = predicate((x) => x is XMLElement, 'is an XMLElement');

  XMLDocument makeDocument() => new XMLDocument.xml("<xml><foo/><bar/></xml>");

  group('constructor', () {
    test('with a well-formed document', () {
      final doc = makeDocument();
      expect(doc, isXMLDocument);
      expect(doc.elements[0].tagName, 'foo');
      expect(doc.elements[1].tagName, 'bar');
    });

    // TODO(nweiz): re-enable this when Document#query matches the root-level
    // element. Otherwise it fails on Firefox.
    //
    // test('with a parse error', () {
    //   expect(() => new XMLDocument.xml("<xml></xml>foo"),
    //       throwsArgumentError);
    // });

    test('with a PARSERERROR tag', () {
      final doc = new XMLDocument.xml("<xml><parsererror /></xml>");
      expect(doc.elements[0].tagName, 'parsererror');
    });
  });

  // FilteredElementList is tested more thoroughly in DocumentFragmentTests.
  group('elements', () {
    test('filters out non-element nodes', () {
      final doc = new XMLDocument.xml("<xml>1<a/><b/>2<c/>3<d/></xml>");
      expect(doc.elements.map((e) => e.tagName), ["a", "b", "c", "d"]);
    });

    test('overwrites nodes when set', () {
      final doc = new XMLDocument.xml("<xml>1<a/><b/>2<c/>3<d/></xml>");
      doc.elements = [new XMLElement.tag('x'), new XMLElement.tag('y')];
      expect(doc.outerHTML, "<xml><x></x><y></y></xml>");
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
      expect(extractClasses(doc), ["foo", "bar", "baz", "qux"]);
    });

    test('is affected by the "class" attribute', () {
      final doc = makeDocumentWithClasses();
      doc.attributes['class'] = 'foo qux';
      expect(doc.classes, ["foo", "qux"]);
    });

    test('classes=', () {
      final doc = makeDocumentWithClasses();
      doc.classes = ['foo', 'qux'];
      expect(doc.classes, ["foo", "qux"]);
      expect(extractClasses(doc), ["foo", "qux"]);
    });

    test('toString', () {
      expect(makeClassSet().toString().split(' '),
          unorderedEquals(['foo', 'bar', 'baz']));
      expect(makeDocument().classes.toString(), '');
    });

    test('forEach', () {
      final classes = <String>[];
      makeClassSet().forEach(classes.add);
      expect(classes, unorderedEquals(['foo', 'bar', 'baz']));
    });

    test('iterator', () {
      final classes = <String>[];
      for (var doc in makeClassSet()) {
        classes.add(doc);
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
      expect(makeDocument().classes.isEmpty, isTrue);
    });

    test('length', () {
      expect(makeClassSet().length, 3);
      expect(makeDocument().classes.length, 0);
    });

    test('contains', () {
      expect(makeClassSet().contains('foo'), isTrue);
      expect(makeClassSet().contains('qux'), isFalse);
    });

    test('add', () {
      final classes = makeClassSet();
      classes.add('qux');
      expect(classes, unorderedEquals(['foo', 'bar', 'baz', 'qux']);

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
          unorderedEquals(['foo', 'baz']))
    });

    test('clear', () {
      final classes = makeClassSet();
      classes.clear();
      expect(classes, []);
    });
  });

  // XMLClassSet is tested more thoroughly in XMLElementTests.
  group('classes', () {
    XMLDocument makeDocumentWithClasses() =>
      new XMLDocument.xml("<xml class='foo bar baz'></xml>");

    test('affects the "class" attribute', () {
      final doc = makeDocumentWithClasses();
      doc.classes.add('qux');
      expect(doc.attributes['class'].split(' '),
          unorderedEquals(['foo', 'bar', 'baz', 'qux']));
    });

    test('is affected by the "class" attribute', () {
      final doc = makeDocumentWithClasses();
      doc.attributes['class'] = 'foo qux';
      expect(doc.classes, unorderedEquals(['foo', 'qux']));
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
    expect(doc.execCommand("foo", false, "bar"), isFalse);
  });

  group('properties that map to attributes', () {
    group('contentEditable', () {
      test('get', () {
        final doc = makeDocument();
        expect(doc.contentEditable, 'inherit');
        doc.attributes['contentEditable'] = 'foo';
        expect(doc.contentEditable, 'foo');
      });

      test('set', () {
        final doc = makeDocument();
        doc.contentEditable = 'foo';
        expect(doc.attributes['contentEditable'], 'foo');
      });

      test('isContentEditable', () {
        final doc = makeDocument();
        expect(doc.isContentEditable, isFalse);
        doc.contentEditable = 'true';
        expect(doc.isContentEditable, isFalse);
      });
    });

    group('draggable', () {
      test('get', () {
        final doc = makeDocument();
        expect(doc.draggable, isFalse);
        doc.attributes['draggable'] = 'true';
        expect(doc.draggable, isTrue);
        doc.attributes['draggable'] = 'foo';
        expect(doc.draggable, isFalse);
      });

      test('set', () {
        final doc = makeDocument();
        doc.draggable = true;
        expect(doc.attributes['draggable'], 'true');
        doc.draggable = false;
        expect(doc.attributes['draggable'], 'false');
      });
    });

    group('spellcheck', () {
      test('get', () {
        final doc = makeDocument();
        expect(doc.spellcheck, isFalse);
        doc.attributes['spellcheck'] = 'true';
        expect(doc.spellcheck, isTrue);
        doc.attributes['spellcheck'] = 'foo';
        expect(doc.spellcheck, isFalse);
      });

      test('set', () {
        final doc = makeDocument();
        doc.spellcheck = true;
        expect(doc.attributes['spellcheck'], 'true');
        doc.spellcheck = false;
        expect(doc.attributes['spellcheck'], 'false');
      });
    });

    group('hidden', () {
      test('get', () {
        final doc = makeDocument();
        expect(doc.hidden, isFalse);
        doc.attributes['hidden'] = '';
        expect(doc.hidden, isTrue);
      });

      test('set', () {
        final doc = makeDocument();
        doc.hidden = true;
        expect(doc.attributes['hidden'], '');
        doc.hidden = false;
        expect(doc.attributes.containsKey('hidden'), isFalse);
      });
    });

    group('tabIndex', () {
      test('get', () {
        final doc = makeDocument();
        expect(doc.tabIndex, 0);
        doc.attributes['tabIndex'] = '2';
        expect(doc.tabIndex, 2);
        doc.attributes['tabIndex'] = 'foo';
        expect(doc.tabIndex, 0);
      });

      test('set', () {
        final doc = makeDocument();
        doc.tabIndex = 15;
        expect(doc.attributes['tabIndex'], '15');
      });
    });

    group('id', () {
      test('get', () {
        final doc = makeDocument();
        expect(doc.id, '');
        doc.attributes['id'] = 'foo';
        expect(doc.id, 'foo');
      });

      test('set', () {
        final doc = makeDocument();
        doc.id = 'foo';
        expect(doc.attributes['id'], 'foo');
      });
    });

    group('title', () {
      test('get', () {
        final doc = makeDocument();
        expect(doc.title, '');
        doc.attributes['title'] = 'foo';
        expect(doc.title, 'foo');
      });

      test('set', () {
        final doc = makeDocument();
        doc.title = 'foo';
        expect(doc.attributes['title'], 'foo');
      });
    });

    // TODO(nweiz): re-enable this when the WebKit-specificness won't break
    // non-WebKit browsers.
    //
    // group('webkitdropzone', () {
    //   test('get', () {
    //     final doc = makeDocument();
    //     expect(doc.webkitdropzone, '');
    //     doc.attributes['webkitdropzone'] = 'foo';
    //     expect(doc.webkitdropzone, 'foo');
    //   });
    //
    //   test('set', () {
    //     final doc = makeDocument();
    //     doc.webkitdropzone = 'foo';
    //     expect(doc.attributes['webkitdropzone'], 'foo');
    //   });
    // });

    group('lang', () {
      test('get', () {
        final doc = makeDocument();
        expect(doc.lang, '');
        doc.attributes['lang'] = 'foo';
        expect(doc.lang, 'foo');
      });

      test('set', () {
        final doc = makeDocument();
        doc.lang = 'foo';
        expect(doc.attributes['lang'], 'foo');
      });
    });

    group('dir', () {
      test('get', () {
        final doc = makeDocument();
        expect(doc.dir, '');
        doc.attributes['dir'] = 'foo';
        expect(doc.dir, 'foo');
      });

      test('set', () {
        final doc = makeDocument();
        doc.dir = 'foo';
        expect(doc.attributes['dir'], 'foo');
      });
    });
  });

  test('set innerHTML', () {
    final doc = makeDocument();
    doc.innerHTML = "<foo>Bar<baz/></foo>";
    expect(doc.nodes.length, 1);
    final node = doc.nodes[0];
    expect(node, isXMLElement);
    expect(node.tagName, 'foo');
    expect(node.nodes[0].text, 'Bar');
    expect(node.nodes[1].tagName, 'baz');
  });

  test('get innerHTML/outerHTML', () {
    final doc = makeDocument();
    expect(doc.innerHTML, "<foo></foo><bar></bar>");
    doc.nodes.clear();
    doc.nodes.addAll([new Text("foo"), new XMLElement.xml("<a>bar</a>")]);
    expect(doc.innertHTML, "foo<a>bar</a>");
    expect(doc.outerHTML, "<xml>foo<a>bar</a></xml>");
  });

  test('query', () {
    final doc = makeDocument();
    expect(doc.query('foo').tagName, 'foo');
    expect(doc.query('baz'), isNull);
  });

  test('queryAll', () {
    final doc = new XMLDocument.xml(
        "<xml><foo id='f1' /><bar><foo id='f2' /></bar></xml>");
    expect(doc.queryAll('foo').map((e) => e.id), ['f1', 'f2']);
    expect(doc.queryAll('baz'), []);
  });

  // TODO(nweiz): re-enable this when matchesSelector works cross-browser.
  //
  // test('matchesSelector', () {
  //   final doc = makeDocument();
  //   expect(doc.matchesSelector('*'), isTrue);
  //   expect(doc.matchesSelector('xml'), isTrue);
  //   expect(doc.matchesSelector('html'), isFalse);
  // });

  group('insertAdjacentElement', () {
    getDoc() => new XMLDocument.xml("<xml><a>foo</a></xml>");

    test('beforeBegin does nothing', () {
      final doc = getDoc();
      expect(doc.insertAdjacentElement("beforeBegin", new XMLElement.tag("b")),
          isNull);
      expect(doc.innerHTML, "<a>foo</a>");
    });

    test('afterEnd does nothing', () {
      final doc = getDoc();
      expect(doc.insertAdjacentElement("afterEnd", new XMLElement.tag("b")),
          isNull);
      expect(doc.innerHTML, "<a>foo</a>");
    });

    test('afterBegin inserts the element', () {
      final doc = getDoc();
      final el = new XMLElement.tag("b");
      expect(doc.insertAdjacentElement("afterBegin", el), el);
      expect(doc.innerHTML, "<b></b><a>foo</a>");
    });

    test('beforeEnd inserts the element', () {
      final doc = getDoc();
      final el = new XMLElement.tag("b");
      expect(doc.insertAdjacentElement("beforeEnd", el), el);
      expect(doc.innerHTML, "<a>foo</a><b></b>");
    });
  });

  group('insertAdjacentText', () {
    getDoc() => new XMLDocument.xml("<xml><a>foo</a></xml>");

    test('beforeBegin does nothing', () {
      final doc = getDoc();
      doc.insertAdjacentText("beforeBegin", "foo");
      expect(doc.innerHTML, "<a>foo</a>");
    });

    test('afterEnd does nothing', () {
      final doc = getDoc();
      doc.insertAdjacentText("afterEnd", "foo");
      expect(doc.innerHTML, "<a>foo</a>");
    });

    test('afterBegin inserts the text', () {
      final doc = getDoc();
      doc.insertAdjacentText("afterBegin", "foo");
      expect(doc.innerHTML, "foo<a>foo</a>");
    });

    test('beforeEnd inserts the text', () {
      final doc = getDoc();
      doc.insertAdjacentText("beforeEnd", "foo");
      expect(doc.innerHTML, "<a>foo</a>foo");
    });
  });

  group('insertAdjacentHTML', () {
    getDoc() => new XMLDocument.xml("<xml><a>foo</a></xml>");

    test('beforeBegin does nothing', () {
      final doc = getDoc();
      doc.insertAdjacentHTML("beforeBegin", "foo<b/>");
      expect(doc.innerHTML, "<a>foo</a>");
    });

    test('afterEnd does nothing', () {
      final doc = getDoc();
      doc.insertAdjacentHTML("afterEnd", "<b/>foo");
      expect(doc.innerHTML, "<a>foo</a>");
    });

    test('afterBegin inserts the HTML', () {
      final doc = getDoc();
      doc.insertAdjacentHTML("afterBegin", "foo<b/>");
      expect(doc.innerHTML, "foo<b></b><a>foo</a>");
    });

    test('beforeEnd inserts the HTML', () {
      final doc = getDoc();
      doc.insertAdjacentHTML("beforeEnd", "<b/>foo");
      expect(doc.innerHTML, "<a>foo</a><b></b>foo");
    });
  });

  group('default values', () {
    test('default rect values', () {
      makeDocument().rect.then(expectAsync1((ElementRect rect) {
        expectEmptyRect(rect.client);
        expectEmptyRect(rect.offset);
        expectEmptyRect(rect.scroll);
        expectEmptyRect(rect.bounding);
        expect(rect.clientRects.isEmpty, isTrue);
      }));
    });

    test('nextElementSibling', () =>
        expect(makeDocument().nextElementSibling), isNull);
    test('previousElementSibling', () =>
        expect(makeDocument().previousElementSibling), isNull);
    test('parent', () => expect(makeDocument().parent), isNull);
    test('offsetParent', () => expect(makeDocument().offsetParent), isNull);
    test('activeElement', () => expect(makeDocument().activeElement), isNull);
    test('body', () => expect(makeDocument().body), isNull);
    test('window', () => expect(makeDocument().window), isNull);
    test('domain', () => expect(makeDocument().domain), '');
    test('head', () => expect(makeDocument().head), isNull);
    test('referrer', () => expect(makeDocument().referrer), '');
    test('styleSheets', () => expect(makeDocument().styleSheets), []);
    test('title', () => expect(makeDocument().title), '');

    // TODO(nweiz): IE sets the charset to "windows-1252". How do we want to
    // handle that?
    //
    // test('charset', () => expect(makeDocument().charset), isNull);

    // TODO(nweiz): re-enable these when the WebKit-specificness won't break
    // non-WebKit browsers.
    //
    // test('webkitHidden', () => expect(makeDocument().webkitHidden), isFalse);
    // test('webkitVisibilityState', () =>
    //     expect(makeDocument().webkitVisibilityState), 'visible');

    test('caretRangeFromPoint', () {
      final doc = makeDocument();
      Futures.wait([
        doc.caretRangeFromPoint(),
        doc.caretRangeFromPoint(0, 0),
        doc.caretRangeFromPoint(5, 5)
      ]).then(expectAsync1((ranges) {
        expect(ranges, [null, null, null]);
      }));
    });

    test('elementFromPoint', () {
      final doc = makeDocument();
      Futures.wait([
        doc.elementFromPoint(),
        doc.elementFromPoint(0, 0),
        doc.elementFromPoint(5, 5)
      ]).then(expectAsync1((ranges) {
        expect(ranges, [null, null, null]);
      }));
    });

    test('queryCommandEnabled', () {
      expect(makeDocument().queryCommandEnabled('foo'), isFalse);
      expect(makeDocument().queryCommandEnabled('bold'), isFalse);
    });

    test('queryCommandIndeterm', () {
      expect(makeDocument().queryCommandIndeterm('foo'), isFalse);
      expect(makeDocument().queryCommandIndeterm('bold'), isFalse);
    });

    test('queryCommandState', () {
      expect(makeDocument().queryCommandState('foo'), isFalse);
      expect(makeDocument().queryCommandState('bold'), isFalse);
    });

    test('queryCommandSupported', () {
      expect(makeDocument().queryCommandSupported('foo'), isFalse);
      expect(makeDocument().queryCommandSupported('bold'), isFalse);
    });

    test('manifest', () => expect(makeDocument().manifest), '');
  });

  test('unsupported operations', () {
    expectUnsupported(() { makeDocument().body = new XMLElement.tag('xml'); });
    expectUnsupported(() => makeDocument().cookie);
    expectUnsupported(() { makeDocument().cookie = 'foo'; });
    expectUnsupported(() { makeDocument().manifest = 'foo'; });
  });
}
