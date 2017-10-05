// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

import 'utils.dart';

main() {
  var isAnchorElement =
      predicate((x) => x is AnchorElement, 'is an AnchorElement');

  List<String> _nodeStrings(Iterable<Node> input) {
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

  ;

  assertConstError(void fn()) {
    try {
      fn();
    } catch (e) {
      if (e is UnsupportedError) {
        return;
      }
    }
    expect(true, isFalse, reason: 'Expected immutability error');
  }

  ;

  void expectEmptyStyleDeclaration(CssStyleDeclaration style) {
    expect(style.cssText, equals(''));
    expect(style.getPropertyPriority('color'), equals(''));
    expect(style.item(0), equals(''));
    expect(style.length, equals(0));
    // TODO(jacobr): these checks throw UnimplementedErrors in dartium.
    // expect(style.parentRule, isNull);
    // expect(style.getPropertyCssValue('color'), isNull);
    // expect(style.getPropertyShorthand('color'), isNull);
    // expect(style.isPropertyImplicit('color'), isFalse);

    // Ideally these would throw errors, but it's not possible to create a class
    // that'll intercept these calls without implementing the entire
    // CssStyleDeclaration interface, so we'll settle for them being no-ops.
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

  group('children', () {
    DocumentFragment fragment;
    List<Element> children;

    init() {
      fragment = new DocumentFragment();
      children = fragment.children;
      fragment.nodes.addAll([
        new Text("1"),
        new Element.tag("A"),
        new Element.tag("B"),
        new Text("2"),
        new Element.tag("I"),
        new Text("3"),
        new Element.tag("U")
      ]);
    }

    ;

    test('is initially empty', () {
      children = new DocumentFragment().children;
      expect(children, equals([]));
      expect(children.isEmpty, isTrue);
    });

    test('filters out non-element nodes', () {
      init();
      expect(_nodeStrings(fragment.nodes),
          equals(["1", "A", "B", "2", "I", "3", "U"]));
      expect(_nodeStrings(children), equals(["A", "B", "I", "U"]));
    });

    test('only indexes children, not other nodes', () {
      init();
      children[1] = new Element.tag("BR");
      expect(_nodeStrings(fragment.nodes),
          equals(["1", "A", "BR", "2", "I", "3", "U"]));
      expect(_nodeStrings(children), equals(["A", "BR", "I", "U"]));
    });

    test('adds to both children and nodes', () {
      init();
      children.add(new Element.tag("UL"));
      expect(_nodeStrings(fragment.nodes),
          equals(["1", "A", "B", "2", "I", "3", "U", "UL"]));
      expect(_nodeStrings(children), equals(["A", "B", "I", "U", "UL"]));
    });

    test('removes only children, from both children and nodes', () {
      init();
      expect(children.removeLast().tagName, equals('U'));
      expect(
          _nodeStrings(fragment.nodes), equals(["1", "A", "B", "2", "I", "3"]));
      expect(_nodeStrings(children), equals(["A", "B", "I"]));

      expect(children.removeLast().tagName, "I");
      expect(_nodeStrings(fragment.nodes), equals(["1", "A", "B", "2", "3"]));
      expect(_nodeStrings(children), equals(["A", "B"]));
    });

    test('accessors are wrapped', () {
      init();
      expect(children[0].tagName, "A");
      expect(_nodeStrings(children.where((e) => e.tagName == "I")), ["I"]);
      expect(children.every((e) => e is Element), isTrue);
      expect(children.any((e) => e.tagName == "U"), isTrue);
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
    fragment.append(new Text("foo"));
    fragment.innerHtml = "<a>bar</a>baz";
    expect(_nodeStrings(fragment.nodes), equals(["A", "baz"]));
  });

  test('getting innerHtml works', () {
    var fragment = new DocumentFragment();
    fragment.nodes.addAll([new Text("foo"), new Element.html("<A>bar</A>")]);
    expect(fragment.innerHtml, "foo<a>bar</a>");
  });

  test('query searches the fragment', () {
    var fragment = new DocumentFragment.html(
        "<div class='foo'><a>foo</a><b>bar</b></div>");
    expect(fragment.query(".foo a").tagName, "A");
    expect(
        _nodeStrings(fragment.queryAll<Element>(".foo *")), equals(["A", "B"]));
  });
}
