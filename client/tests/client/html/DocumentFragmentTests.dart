// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DocumentFragmentTests extends UnitTestSuite {
  DocumentFragmentTests(): super();

  static void main() {
    new DocumentFragmentTests().run();
  }

  void setUpTestSuite() {
    addTest(testUnsupportedOperations);
    addTest(testElements);
    addTest(testSetInnerHtml);
    addTest(testGetInnerHtml);
    addTest(testInsertAdjacentElement);
    addTest(testInsertAdjacentText);
    addTest(testInsertAdjacentHtml);
    addTest(testNoOps);
    addTest(testDefaultValues);
    addTest(testStyle);
    addTest(testBoundingClientRect);
    addTest(testConstFields);
    addTest(testQuery);
  }

  void testUnsupportedOperations() {
    var emptyFragment = new DocumentFragment();
    assertUnsupported(() => emptyFragment.attributes = {});
    assertUnsupported(() => emptyFragment.classes = []);
    assertUnsupported(() => emptyFragment.dataAttributes = {});
    assertUnsupported(() => emptyFragment.contentEditable = "true");
    assertUnsupported(() => emptyFragment.dir);
    assertUnsupported(() => emptyFragment.dir = "ltr");
    assertUnsupported(() => emptyFragment.draggable = true);
    assertUnsupported(() => emptyFragment.hidden = true);
    assertUnsupported(() => emptyFragment.id = "foo");
    assertUnsupported(() => emptyFragment.lang);
    assertUnsupported(() => emptyFragment.lang = "en");
    assertUnsupported(() => emptyFragment.scrollLeft = 10);
    assertUnsupported(() => emptyFragment.scrollTop = 10);
    assertUnsupported(() => emptyFragment.spellcheck = true);
    assertUnsupported(() => emptyFragment.tabIndex = 5);
    assertUnsupported(() => emptyFragment.title = "foo");
    assertUnsupported(() => emptyFragment.webkitdropzone = "foo");
  }

  void testElements() {
    var fragment = new DocumentFragment();
    var elements = fragment.elements;
    Expect.listEquals([], elements);
    Expect.isTrue(elements.isEmpty());

    fragment.nodes.addAll(
      [new Text("1"), new Element.tag("A"), new Element.tag("B"),
       new Text("2"), new Element.tag("I"), new Text("3"),
       new Element.tag("U")]);
    Expect.listEquals(["1", "A", "B", "2", "I", "3", "U"],
                      _nodeStrings(fragment.nodes));
    Expect.listEquals(["A", "B", "I", "U"], _nodeStrings(elements));

    elements[1] = new Element.tag("BR");
    Expect.listEquals(["1", "A", "BR", "2", "I", "3", "U"],
                      _nodeStrings(fragment.nodes));
    Expect.listEquals(["A", "BR", "I", "U"], _nodeStrings(elements));

    elements.add(new Element.tag("UL"));
    Expect.listEquals(["1", "A", "BR", "2", "I", "3", "U", "UL"],
                      _nodeStrings(fragment.nodes));
    Expect.listEquals(["A", "BR", "I", "U", "UL"], _nodeStrings(elements));

    Expect.equals("UL", elements.removeLast().tagName);
    Expect.listEquals(["1", "A", "BR", "2", "I", "3", "U"],
                      _nodeStrings(fragment.nodes));
    Expect.listEquals(["A", "BR", "I", "U"], _nodeStrings(elements));

    Expect.equals("A", elements.first.tagName);
    Expect.listEquals(
        ["I"], _nodeStrings(elements.filter((e) => e.tagName == "I")));
    Expect.isTrue(elements.every((e) => e is Element));
    Expect.isTrue(elements.some((e) => e.tagName == "U"));
    Expect.isFalse(elements.isEmpty());
    Expect.equals(4, elements.length);
    Expect.equals("I", elements[2].tagName);
    Expect.equals("U", elements.last().tagName);

    fragment.elements = [new Element.tag("DIV"), new Element.tag("HEAD")];
    Expect.listEquals(["DIV", "HEAD"], _nodeStrings(fragment.nodes));
  }

  void testSetInnerHtml() {
    var fragment = new DocumentFragment();
    fragment.nodes.add(new Text("foo"));
    fragment.innerHTML = "<a>bar</a>baz";
    Expect.listEquals(["A", "baz"], _nodeStrings(fragment.nodes));
  }

  void testGetInnerHtml() {
    var fragment = new DocumentFragment();
    fragment.nodes.addAll([new Text("foo"), new Element.html("<A>bar</A>")]);
    Expect.equals("foo<a>bar</a>", fragment.innerHTML);
    Expect.equals("foo<a>bar</a>", fragment.outerHTML);
  }

  void testInsertAdjacentElement() {
    var fragment = new DocumentFragment.html("<a>foo</a>");

    Expect.isNull(
      fragment.insertAdjacentElement("beforeBegin", new Element.tag("b")));
    Expect.equals("<a>foo</a>", fragment.innerHTML);

    Expect.isNull(
      fragment.insertAdjacentElement("afterEnd", new Element.tag("b")));
    Expect.equals("<a>foo</a>", fragment.innerHTML);

    var el = new Element.tag("b");
    Expect.equals(el, fragment.insertAdjacentElement("afterBegin", el));
    Expect.equals("<b></b><a>foo</a>", fragment.innerHTML);

    el = new Element.tag("u");
    Expect.equals(el, fragment.insertAdjacentElement("beforeEnd", el));
    Expect.equals("<b></b><a>foo</a><u></u>", fragment.innerHTML);
  }

  void testInsertAdjacentText() {
    var fragment = new DocumentFragment.html("<a>foo</a>");

    fragment.insertAdjacentText("beforeBegin", "bar");
    Expect.equals("<a>foo</a>", fragment.innerHTML);

    fragment.insertAdjacentText("afterEnd", "bar");
    Expect.equals("<a>foo</a>", fragment.innerHTML);

    fragment.insertAdjacentText("afterBegin", "bar");
    Expect.equals("bar<a>foo</a>", fragment.innerHTML);

    fragment.insertAdjacentText("beforeEnd", "baz");
    Expect.equals("bar<a>foo</a>baz", fragment.innerHTML);
  }

  void testInsertAdjacentHtml() {
    var fragment = new DocumentFragment.html("<a>foo</a>");

    fragment.insertAdjacentHTML("beforeBegin", "bar<br>");
    Expect.equals("<a>foo</a>", fragment.innerHTML);

    fragment.insertAdjacentHTML("afterEnd", "bar<br>");
    Expect.equals("<a>foo</a>", fragment.innerHTML);

    fragment.insertAdjacentHTML("afterBegin", "bar<br>");
    Expect.equals("bar<br><a>foo</a>", fragment.innerHTML);

    fragment.insertAdjacentHTML("beforeEnd", "<hr>baz");
    Expect.equals("bar<br><a>foo</a><hr>baz", fragment.innerHTML);
  }

  // Just test that these methods don't throw errors
  void testNoOps() {
    var fragment = new DocumentFragment();
    fragment.on.click.add((e) => null);
    fragment.blur();
    fragment.focus();
    fragment.scrollByLines(2);
    fragment.scrollByPages(2);
    fragment.scrollIntoView();
  }

  void testDefaultValues() {
    var fragment = new DocumentFragment();
    Expect.equals(0, fragment.clientHeight);
    Expect.equals(0, fragment.clientWidth);
    Expect.equals(0, fragment.offsetHeight);
    Expect.equals(0, fragment.offsetWidth);
    Expect.equals(0, fragment.scrollHeight);
    Expect.equals(0, fragment.scrollWidth);
    Expect.equals(0, fragment.clientLeft);
    Expect.equals(0, fragment.clientTop);
    Expect.equals(0, fragment.offsetLeft);
    Expect.equals(0, fragment.offsetTop);
    Expect.equals(0, fragment.scrollLeft);
    Expect.equals(0, fragment.scrollTop);
    Expect.equals("false", fragment.contentEditable);
    Expect.equals(-1, fragment.tabIndex);
    Expect.equals("", fragment.id);
    Expect.equals("", fragment.title);
    Expect.equals("", fragment.tagName);
    Expect.equals("", fragment.webkitdropzone);
    Expect.isFalse(fragment.isContentEditable);
    Expect.isFalse(fragment.draggable);
    Expect.isFalse(fragment.hidden);
    Expect.isFalse(fragment.spellcheck);
    Expect.isNull(fragment.nextElementSibling);
    Expect.isNull(fragment.previousElementSibling);
    Expect.isNull(fragment.offsetParent);
    Expect.isNull(fragment.parent);
    Expect.isTrue(fragment.attributes.isEmpty());
    Expect.isTrue(fragment.classes.isEmpty());
    Expect.isTrue(fragment.dataAttributes.isEmpty());
    Expect.isTrue(fragment.getClientRects().isEmpty());
    Expect.isFalse(fragment.matchesSelector("foo"));
    Expect.isFalse(fragment.matchesSelector("*"));
  }

  void testStyle() {
    var fragment = new DocumentFragment();
    var style = fragment.style;
    Expect.equals("", style.cssText);
    Expect.equals("", style.getPropertyPriority('color'));
    Expect.equals("", style.item(0));
    Expect.equals(0, style.length);
    Expect.isNull(style.parentRule);
    Expect.isNull(style.getPropertyCSSValue('color'));
    Expect.isNull(style.getPropertyShorthand('color'));
    Expect.isFalse(style.isPropertyImplicit('color'));
    assertUnsupported(() => style.cssText = '* {color: blue}');
    assertUnsupported(() => style.removeProperty('color'));
    assertUnsupported(() => style.setProperty('color', 'blue'));
  }

  void testBoundingClientRect() {
    var fragment = new DocumentFragment();
    var rect = fragment.getBoundingClientRect();
    Expect.equals(0, rect.bottom);
    Expect.equals(0, rect.top);
    Expect.equals(0, rect.left);
    Expect.equals(0, rect.right);
    Expect.equals(0, rect.height);
    Expect.equals(0, rect.width);
  }

  void testConstFields() {
    var fragment = new DocumentFragment();
    assertConstError(() => fragment.attributes['title'] = 'foo');
    assertConstError(() => fragment.dataAttributes['title'] = 'foo');
    assertConstError(() => fragment.getClientRects().add(null));
    // Issue 174: #classes is currently not const
    // assertConstError(() => fragment.classes.add('foo'));
  }

  void testQuery() {
    var fragment = new DocumentFragment.html(
      "<div class='foo'><a>foo</a><b>bar</b></div>");
    Expect.equals("A", fragment.query(".foo a").tagName);
    Expect.listEquals(["A", "B"], _nodeStrings(fragment.queryAll(".foo *")));
  }

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
  }

  void assertUnsupported(void fn()) {
    try {
      fn();
    } catch (UnsupportedOperationException e) {
      return;
    }
    Expect.fail('Expected UnsupportedOperationException');
  }

  void assertConstError(void fn()) {
    try {
      fn();
    } catch (var e) {
      if (e is IllegalAccessException || e is UnsupportedOperationException) {
        return;
      }
    }
    Expect.fail('Expected immutability error');
  }
}
