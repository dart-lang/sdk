// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library DocumentFragmentTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
part 'util.dart';

main() {
  useHtmlConfiguration();

  var isAnchorElement =
      predicate((x) => x is AnchorElement, 'is an AnchorElement');

  Collection<String> _nodeStrings(Collection<Node> input) {
    var out = new List<String>();
    for (Node n in input) {
      if (n is Element) {
        Element e = n;
        out.add(e.tagName);
      } else {
        out.add(n.text);
      }
    }
    return out;
  };

  assertConstError(void fn()) {
    try {
      fn();
    } catch (e) {
      if (e is UnsupportedError) {
        return;
      }
    }
    expect(true, isFalse, reason: 'Expected immutability error');
  };

  void expectEmptyStyleDeclaration(CSSStyleDeclaration style) {
    expect(style.cssText, equals(''));
    expect(style.getPropertyPriority('color'), equals(''));
    expect(style.item(0), equals(''));
    expect(style.length, isZero);
    // TODO(jacobr): these checks throw UnimplementedErrors in dartium.
    // expect(style.parentRule, isNull);
    // expect(style.getPropertyCssValue('color'), isNull);
    // expect(style.getPropertyShorthand('color'), isNull);
    // expect(style.isPropertyImplicit('color'), isFalse);

    // Ideally these would throw errors, but it's not possible to create a class
    // that'll intercept these calls without implementing the entire
    // CSSStyleDeclaration interface, so we'll settle for them being no-ops.
    style.cssText = '* {color: blue}';
    style.removeProperty('color');
    style.setProperty('color', 'blue');
  }

  group('constructors', () {
    test('0-argument makes an empty fragment', () {
      final fragment = new DocumentFragment();
      expect(fragment.children, equals([]));
    });

    test('.html parses input as HTML', () {
      final fragment = new DocumentFragment.html('<a>foo</a>');
      expect(fragment.children[0], isAnchorElement);
    });

    // test('.svg parses input as SVG', () {
    //   final fragment = new DocumentFragment.svg('<a>foo</a>');
    //   expect(fragment.children[0] is SVGAElement, isTrue);
    // });

    // TODO(nweiz): enable this once XML is ported.
    // test('.xml parses input as XML', () {
    //   final fragment = new DocumentFragment.xml('<a>foo</a>');
    //   expect(fragment.children[0] is XMLElement, isTrue);
    // });
  });

  test('Unsupported operations throw errors', () {
    var emptyFragment = new DocumentFragment();
    expectUnsupported(() => emptyFragment.attributes = {});
    expectUnsupported(() => emptyFragment.classes = []);
    expectUnsupported(() => emptyFragment.classes.add('foo'));
    expectUnsupported(() => emptyFragment.dataAttributes = {});
    expectUnsupported(() => emptyFragment.contentEditable = "true");
    expectUnsupported(() => emptyFragment.dir);
    expectUnsupported(() => emptyFragment.dir = "ltr");
    expectUnsupported(() => emptyFragment.draggable = true);
    expectUnsupported(() => emptyFragment.hidden = true);
    expectUnsupported(() => emptyFragment.id = "foo");
    expectUnsupported(() => emptyFragment.lang);
    expectUnsupported(() => emptyFragment.lang = "en");
    expectUnsupported(() => emptyFragment.scrollLeft = 10);
    expectUnsupported(() => emptyFragment.scrollTop = 10);
    expectUnsupported(() => emptyFragment.spellcheck = true);
    expectUnsupported(() => emptyFragment.translate = true);
    expectUnsupported(() => emptyFragment.tabIndex = 5);
    expectUnsupported(() => emptyFragment.title = "foo");
    expectUnsupported(() => emptyFragment.webkitdropzone = "foo");
    expectUnsupported(() => emptyFragment.webkitRegionOverflow = "foo");
  });

  group('children', () {
    var fragment;
    var children;

    init() {
      fragment = new DocumentFragment();
      children = fragment.children;
      fragment.nodes.addAll(
        [new Text("1"), new Element.tag("A"), new Element.tag("B"),
         new Text("2"), new Element.tag("I"), new Text("3"),
         new Element.tag("U")]);
    };

    test('is initially empty', () {
      children = new DocumentFragment().children;
      expect(children, equals([]));
      expect(children.isEmpty, isTrue);
    });

    test('filters out non-element nodes', () {
      init();
      expect(_nodeStrings(fragment.nodes),
          orderedEquals(["1", "A", "B", "2", "I", "3", "U"]));
      expect(_nodeStrings(children),
          orderedEquals(["A", "B", "I", "U"]));
    });

    test('only indexes children, not other nodes', () {
      init();
      children[1] = new Element.tag("BR");
      expect(_nodeStrings(fragment.nodes),
          orderedEquals(["1", "A", "BR", "2", "I", "3", "U"]));
      expect(_nodeStrings(children),
          orderedEquals(["A", "BR", "I", "U"]));
    });

    test('adds to both children and nodes', () {
      init();
      children.add(new Element.tag("UL"));
      expect(_nodeStrings(fragment.nodes),
          orderedEquals(["1", "A", "B", "2", "I", "3", "U", "UL"]));
      expect(_nodeStrings(children),
          orderedEquals(["A", "B", "I", "U", "UL"]));
    });

    test('removes only children, from both children and nodes', () {
      init();
      expect(children.removeLast().tagName, equals('U'));
      expect(_nodeStrings(fragment.nodes),
          orderedEquals(["1", "A", "B", "2", "I", "3"]));
      expect(_nodeStrings(children),
          orderedEquals(["A", "B", "I"]));

      expect(children.removeLast().tagName, "I");
      expect(_nodeStrings(fragment.nodes),
          equals(["1", "A", "B", "2", "3"]));
      expect(_nodeStrings(children), equals(["A", "B"]));
    });

    test('accessors are wrapped', () {
      init();
      expect(children[0].tagName, "A");
      expect(_nodeStrings(children.filter((e) => e.tagName == "I")), ["I"]);
      expect(children.every((e) => e is Element), isTrue);
      expect(children.some((e) => e.tagName == "U"), isTrue);
      expect(children.isEmpty, isFalse);
      expect(children.length, 4);
      expect(children[2].tagName, "I");
      expect(children.last.tagName, "U");
    });

    test('setting children overwrites nodes as well', () {
      init();
      fragment.children = [new Element.tag("DIV"), new Element.tag("HEAD")];
      expect(_nodeStrings(fragment.nodes), equals(["DIV", "HEAD"]));
    });
  });

  test('setting innerHtml works', () {
    var fragment = new DocumentFragment();
    fragment.nodes.add(new Text("foo"));
    fragment.innerHtml = "<a>bar</a>baz";
    expect(_nodeStrings(fragment.nodes), equals(["A", "baz"]));
  });

  test('getting innerHtml works', () {
    var fragment = new DocumentFragment();
    fragment.nodes.addAll([new Text("foo"), new Element.html("<A>bar</A>")]);
    expect(fragment.innerHtml, "foo<a>bar</a>");
    expect(fragment.outerHtml, "foo<a>bar</a>");
  });

  group('insertAdjacentElement', () {
    getFragment() => new DocumentFragment.html("<a>foo</a>");

    test('beforeBegin does nothing', () {
      var fragment = getFragment();
      expect(fragment.insertAdjacentElement("beforeBegin",
          new Element.tag("b")), isNull);
      expect(fragment.innerHtml, "<a>foo</a>");
    });

    test('afterEnd does nothing', () {
      var fragment = getFragment();
      expect(fragment.insertAdjacentElement("afterEnd",
          new Element.tag("b")), isNull);
      expect(fragment.innerHtml, "<a>foo</a>");
    });

    test('afterBegin inserts the element', () {
      var fragment = getFragment();
      var el = new Element.tag("b");
      expect(fragment.insertAdjacentElement("afterBegin", el), equals(el));
      expect(fragment.innerHtml, "<b></b><a>foo</a>");
    });

    test('beforeEnd inserts the element', () {
      var fragment = getFragment();
      var el = new Element.tag("b");
      expect(fragment.insertAdjacentElement("beforeEnd", el), equals(el));
      expect(fragment.innerHtml, "<a>foo</a><b></b>");
    });
  });

  group('insertAdjacentText', () {
    getFragment() => new DocumentFragment.html("<a>foo</a>");

    test('beforeBegin does nothing', () {
      var fragment = getFragment();
      fragment.insertAdjacentText("beforeBegin", "foo");
      expect(fragment.innerHtml, "<a>foo</a>");
    });

    test('afterEnd does nothing', () {
      var fragment = getFragment();
      fragment.insertAdjacentText("afterEnd", "foo");
      expect(fragment.innerHtml, "<a>foo</a>");
    });

    test('afterBegin inserts the text', () {
      var fragment = getFragment();
      fragment.insertAdjacentText("afterBegin", "foo");
      expect(fragment.innerHtml, "foo<a>foo</a>");
    });

    test('beforeEnd inserts the text', () {
      var fragment = getFragment();
      fragment.insertAdjacentText("beforeEnd", "foo");
      expect(fragment.innerHtml, "<a>foo</a>foo");
    });
  });

  group('insertAdjacentHtml', () {
    getFragment() => new DocumentFragment.html("<a>foo</a>");

    test('beforeBegin does nothing', () {
      var fragment = getFragment();
      fragment.insertAdjacentHtml("beforeBegin", "foo<br>");
      expect(fragment.innerHtml, "<a>foo</a>");
    });

    test('afterEnd does nothing', () {
      var fragment = getFragment();
      fragment.insertAdjacentHtml("afterEnd", "<br>foo");
      expect(fragment.innerHtml, "<a>foo</a>");
    });

    test('afterBegin inserts the HTML', () {
      var fragment = getFragment();
      fragment.insertAdjacentHtml("afterBegin", "foo<br>");
      expect(fragment.innerHtml, "foo<br><a>foo</a>");
    });

    test('beforeEnd inserts the HTML', () {
      var fragment = getFragment();
      fragment.insertAdjacentHtml("beforeEnd", "<br>foo");
      expect(fragment.innerHtml, "<a>foo</a><br>foo");
    });
  });

  // Just test that these methods don't throw errors
  test("no-op methods don't throw errors", () {
    var fragment = new DocumentFragment();
    fragment.on.click.add((e) => null);
    fragment.blur();
    fragment.focus();
    fragment.click();
    fragment.scrollByLines(2);
    fragment.scrollByPages(2);
    fragment.scrollIntoView();
    fragment.webkitRequestFullScreen(2);
  });

  test('default values', () {
    var fragment = new DocumentFragment();
    expect(fragment.contentEditable, "false");
    expect(fragment.tabIndex, -1);
    expect(fragment.id, "");
    expect(fragment.title, "");
    expect(fragment.tagName, "");
    expect(fragment.webkitdropzone, "");
    expect(fragment.webkitRegionOverflow, "");
    expect(fragment.isContentEditable, isFalse);
    expect(fragment.draggable, isFalse);
    expect(fragment.hidden, isFalse);
    expect(fragment.spellcheck, isFalse);
    expect(fragment.translate, isFalse);
    expect(fragment.nextElementSibling, isNull);
    expect(fragment.previousElementSibling, isNull);
    expect(fragment.offsetParent, isNull);
    expect(fragment.parent, isNull);
    expect(fragment.attributes.isEmpty, isTrue);
    expect(fragment.classes.isEmpty, isTrue);
    expect(fragment.dataAttributes.isEmpty, isTrue);
    expect(fragment.matchesSelector("foo"), isFalse);
    expect(fragment.matchesSelector("*"), isFalse);
  });

  test('style', () {
    var fragment = new DocumentFragment();
    var style = fragment.style;
    expectEmptyStyleDeclaration(style);
    fragment.computedStyle.then(expectAsync1((computedStyle) {
      expectEmptyStyleDeclaration(computedStyle);
    }));
  });

  // TODO(nweiz): re-enable when const is better supported in dartc and/or frog
  // test('const fields are immutable', () {
  //   var fragment = new DocumentFragment();
  //   assertConstError(() => fragment.attributes['title'] = 'foo');
  //   assertConstError(() => fragment.dataAttributes['title'] = 'foo');
  //   fragment.rect.then((ElementRect rect) {
  //     assertConstError(() => rect.clientRects.add(null));
  //     callbackDone();
  //   });
  //   // Issue 174: #classes is currently not const
  //   // assertConstError(() => fragment.classes.add('foo'));
  // });

  test('query searches the fragment', () {
    var fragment = new DocumentFragment.html(
      "<div class='foo'><a>foo</a><b>bar</b></div>");
    expect(fragment.query(".foo a").tagName, "A");
    expect(_nodeStrings(fragment.queryAll(".foo *")), equals(["A", "B"]));
  });
}
