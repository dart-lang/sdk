// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('DocumentFragmentTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');
#source('util.dart');

main() {
  useHtmlConfiguration();

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
      if (e is IllegalAccessException || e is UnsupportedOperationException) {
        return;
      }
    }
    Expect.fail('Expected immutability error');
  };

  void expectEmptyStyleDeclaration(CSSStyleDeclaration style) {
    Expect.equals("", style.cssText);
    Expect.equals("", style.getPropertyPriority('color'));
    Expect.equals("", style.item(0));
    Expect.equals(0, style.length);
    // TODO(jacobr): these checks throw NotImplementedExceptions in dartium.
    // Expect.isNull(style.parentRule);
    // Expect.isNull(style.getPropertyCSSValue('color'));
    // Expect.isNull(style.getPropertyShorthand('color'));
    // Expect.isFalse(style.isPropertyImplicit('color'));

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
      Expect.listEquals([], fragment.elements);
    });

    test('.html parses input as HTML', () {
      final fragment = new DocumentFragment.html('<a>foo</a>');
      Expect.isTrue(fragment.elements.first is AnchorElement);
    });

    // test('.svg parses input as SVG', () {
    //   final fragment = new DocumentFragment.svg('<a>foo</a>');
    //   Expect.isTrue(fragment.elements.first is SVGAElement);
    // });

    // TODO(nweiz): enable this once XML is ported.
    // test('.xml parses input as XML', () {
    //   final fragment = new DocumentFragment.xml('<a>foo</a>');
    //   Expect.isTrue(fragment.elements.first is XMLElement);
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

  group('elements', () {
    var fragment;
    var elements;

    init() {
      fragment = new DocumentFragment();
      elements = fragment.elements;
      fragment.nodes.addAll(
        [new Text("1"), new Element.tag("A"), new Element.tag("B"),
         new Text("2"), new Element.tag("I"), new Text("3"),
         new Element.tag("U")]);
    };

    test('is initially empty', () {
      elements = new DocumentFragment().elements;
      Expect.listEquals([], elements);
      Expect.isTrue(elements.isEmpty());
    });

    test('filters out non-element nodes', () {
      init();
      Expect.listEquals(["1", "A", "B", "2", "I", "3", "U"],
                        _nodeStrings(fragment.nodes));
      Expect.listEquals(["A", "B", "I", "U"], _nodeStrings(elements));
    });

    test('only indexes elements, not other nodes', () {
      init();
      elements[1] = new Element.tag("BR");
      Expect.listEquals(["1", "A", "BR", "2", "I", "3", "U"],
                        _nodeStrings(fragment.nodes));
      Expect.listEquals(["A", "BR", "I", "U"], _nodeStrings(elements));
    });

    test('adds to both elements and nodes', () {
      init();
      elements.add(new Element.tag("UL"));
      Expect.listEquals(["1", "A", "B", "2", "I", "3", "U", "UL"],
                        _nodeStrings(fragment.nodes));
      Expect.listEquals(["A", "B", "I", "U", "UL"], _nodeStrings(elements));
    });

    test('removes only elements, from both elements and nodes', () {
      init();
      Expect.equals("U", elements.removeLast().tagName);
      Expect.listEquals(["1", "A", "B", "2", "I", "3"],
                        _nodeStrings(fragment.nodes));
      Expect.listEquals(["A", "B", "I"], _nodeStrings(elements));

      Expect.equals("I", elements.removeLast().tagName);
      Expect.listEquals(["1", "A", "B", "2", "3"],
                        _nodeStrings(fragment.nodes));
      Expect.listEquals(["A", "B"], _nodeStrings(elements));
    });

    test('accessors are wrapped', () {
      init();
      Expect.equals("A", elements.first.tagName);
      Expect.listEquals(
          ["I"], _nodeStrings(elements.filter((e) => e.tagName == "I")));
      Expect.isTrue(elements.every((e) => e is Element));
      Expect.isTrue(elements.some((e) => e.tagName == "U"));
      Expect.isFalse(elements.isEmpty());
      Expect.equals(4, elements.length);
      Expect.equals("I", elements[2].tagName);
      Expect.equals("U", elements.last().tagName);
    });

    test('setting elements overwrites nodes as well', () {
      init();
      fragment.elements = [new Element.tag("DIV"), new Element.tag("HEAD")];
      Expect.listEquals(["DIV", "HEAD"], _nodeStrings(fragment.nodes));
    });
  });

  test('setting innerHTML works', () {
    var fragment = new DocumentFragment();
    fragment.nodes.add(new Text("foo"));
    fragment.innerHTML = "<a>bar</a>baz";
    Expect.listEquals(["A", "baz"], _nodeStrings(fragment.nodes));
  });

  test('getting innerHTML works', () {
    var fragment = new DocumentFragment();
    fragment.nodes.addAll([new Text("foo"), new Element.html("<A>bar</A>")]);
    Expect.equals("foo<a>bar</a>", fragment.innerHTML);
    Expect.equals("foo<a>bar</a>", fragment.outerHTML);
  });

  group('insertAdjacentElement', () {
    getFragment() => new DocumentFragment.html("<a>foo</a>");

    test('beforeBegin does nothing', () {
      var fragment = getFragment();
      Expect.isNull(
        fragment.insertAdjacentElement("beforeBegin", new Element.tag("b")));
      Expect.equals("<a>foo</a>", fragment.innerHTML);
    });

    test('afterEnd does nothing', () {
      var fragment = getFragment();
      Expect.isNull(
        fragment.insertAdjacentElement("afterEnd", new Element.tag("b")));
      Expect.equals("<a>foo</a>", fragment.innerHTML);
    });

    test('afterBegin inserts the element', () {
      var fragment = getFragment();
      var el = new Element.tag("b");
      Expect.equals(el, fragment.insertAdjacentElement("afterBegin", el));
      Expect.equals("<b></b><a>foo</a>", fragment.innerHTML);
    });

    test('beforeEnd inserts the element', () {
      var fragment = getFragment();
      var el = new Element.tag("b");
      Expect.equals(el, fragment.insertAdjacentElement("beforeEnd", el));
      Expect.equals("<a>foo</a><b></b>", fragment.innerHTML);
    });
  });

  group('insertAdjacentText', () {
    getFragment() => new DocumentFragment.html("<a>foo</a>");

    test('beforeBegin does nothing', () {
      var fragment = getFragment();
      fragment.insertAdjacentText("beforeBegin", "foo");
      Expect.equals("<a>foo</a>", fragment.innerHTML);
    });

    test('afterEnd does nothing', () {
      var fragment = getFragment();
      fragment.insertAdjacentText("afterEnd", "foo");
      Expect.equals("<a>foo</a>", fragment.innerHTML);
    });

    test('afterBegin inserts the text', () {
      var fragment = getFragment();
      fragment.insertAdjacentText("afterBegin", "foo");
      Expect.equals("foo<a>foo</a>", fragment.innerHTML);
    });

    test('beforeEnd inserts the text', () {
      var fragment = getFragment();
      fragment.insertAdjacentText("beforeEnd", "foo");
      Expect.equals("<a>foo</a>foo", fragment.innerHTML);
    });
  });

  group('insertAdjacentHTML', () {
    getFragment() => new DocumentFragment.html("<a>foo</a>");

    test('beforeBegin does nothing', () {
      var fragment = getFragment();
      fragment.insertAdjacentHTML("beforeBegin", "foo<br>");
      Expect.equals("<a>foo</a>", fragment.innerHTML);
    });

    test('afterEnd does nothing', () {
      var fragment = getFragment();
      fragment.insertAdjacentHTML("afterEnd", "<br>foo");
      Expect.equals("<a>foo</a>", fragment.innerHTML);
    });

    test('afterBegin inserts the HTML', () {
      var fragment = getFragment();
      fragment.insertAdjacentHTML("afterBegin", "foo<br>");
      Expect.equals("foo<br><a>foo</a>", fragment.innerHTML);
    });

    test('beforeEnd inserts the HTML', () {
      var fragment = getFragment();
      fragment.insertAdjacentHTML("beforeEnd", "<br>foo");
      Expect.equals("<a>foo</a><br>foo", fragment.innerHTML);
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
    fragment.rect.then(expectAsync1((ElementRect rect) {
       expectEmptyRect(rect.client);
       expectEmptyRect(rect.offset);
       expectEmptyRect(rect.scroll);
       expectEmptyRect(rect.bounding);
       Expect.isTrue(rect.clientRects.isEmpty());
    }));
    Expect.equals("false", fragment.contentEditable);
    Expect.equals(-1, fragment.tabIndex);
    Expect.equals("", fragment.id);
    Expect.equals("", fragment.title);
    Expect.equals("", fragment.tagName);
    Expect.equals("", fragment.webkitdropzone);
    Expect.equals("", fragment.webkitRegionOverflow);
    Expect.isFalse(fragment.isContentEditable);
    Expect.isFalse(fragment.draggable);
    Expect.isFalse(fragment.hidden);
    Expect.isFalse(fragment.spellcheck);
    Expect.isFalse(fragment.translate);
    Expect.isNull(fragment.nextElementSibling);
    Expect.isNull(fragment.previousElementSibling);
    Expect.isNull(fragment.offsetParent);
    Expect.isNull(fragment.parent);
    Expect.isTrue(fragment.attributes.isEmpty());
    Expect.isTrue(fragment.classes.isEmpty());
    Expect.isTrue(fragment.dataAttributes.isEmpty());
    Expect.isFalse(fragment.matchesSelector("foo"));
    Expect.isFalse(fragment.matchesSelector("*"));
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
    Expect.equals("A", fragment.query(".foo a").tagName);
    Expect.listEquals(["A", "B"], _nodeStrings(fragment.queryAll(".foo *")));
  });
}
