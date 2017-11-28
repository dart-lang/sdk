// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

import 'dart:html';

import 'package:expect/minitest.dart';

import 'utils.dart';

main() {
  var isSpanElement = predicate((x) => x is SpanElement, 'is a SpanElemt');
  var isDivElement = predicate((x) => x is DivElement, 'is a DivElement');
  var isText = predicate((x) => x is Text, 'is a Text');

  void expectNoSuchMethod(void fn()) => expect(fn, throwsNoSuchMethodError);

  group('append', () {
    test('htmlelement', () {
      var el = new DivElement();
      el.append(new SpanElement());
      expect(el.children.length, equals(1));
      var span = el.children[0];
      expect(span, isSpanElement);

      el.append(new DivElement());
      expect(el.children.length, equals(2));
      // Validate that the first item is still first.
      expect(el.children[0], equals(span));
      expect(el.children[1], isDivElement);
    });

    test('documentFragment', () {
      var fragment = new DocumentFragment();
      fragment.append(new SpanElement());
      expect(fragment.children.length, equals(1));
      expect(fragment.children[0], isSpanElement);
    });
  });

  group('appendHtml', () {
    test('htmlelement', () {
      var el = new DivElement();
      el.appendHtml('<span></span>');
      expect(el.children.length, equals(1));
      var span = el.children[0];
      expect(span, isSpanElement);

      el.appendHtml('<div></div>');
      expect(el.children.length, equals(2));
      // Validate that the first item is still first.
      expect(el.children[0], equals(span));
      expect(el.children[1], isDivElement);
    });

    test('documentFragment', () {
      var fragment = new DocumentFragment();
      fragment.appendHtml('<span>something</span>');
      expect(fragment.children.length, equals(1));
      expect(fragment.children[0], isSpanElement);
    });

    test('html interpreted in correct context', () {
      // appendHtml, in order to sanitize, needs to create a document fragment,
      // but it needs to be created in the right context. If we try to append
      // table components then the document fragment needs the table context
      // or it will fail to create them.
      var el = new TableElement();
      el.appendHtml('<tr><td>foo</td></tr>');
      expect(el.children.length, 1);
      var section = el.children.first;
      expect(section is TableSectionElement, isTrue);
      var row = section.children.first;
      expect(row is TableRowElement, isTrue);
      var item = row.children.first;
      expect(item is TableCellElement, isTrue);
      expect(item.innerHtml, 'foo');
    });

    test("use body context for elements that are don't support it", () {
      // Some elements can't be used as context for createContextualFragment,
      // often because it doesn't make any sense. So adding children to a
      // <br> has no real effect on the page, but we can do it. But the
      // document fragment will have to be created in the body context. Verify
      // that this doesn't throw and that the children show up.
      var el = new BRElement();
      el.appendHtml("<p>Stuff</p>");
      expect(el.children.length, 1);
      expect(el.children[0].outerHtml, "<p>Stuff</p>");
    });
  });

  group('appendText', () {
    test('htmlelement', () {
      var el = new DivElement();
      el.appendText('foo');
      // No children were created.
      expect(el.children.length, equals(0));
      // One text node was added.
      expect(el.nodes.length, equals(1));
    });

    test('htmlelement', () {
      var el = new DivElement();
      var twoNewLines = "\n\n";
      el.appendText(twoNewLines);
      // No children were created.
      expect(el.children.length, equals(0));
      // One text node was added.
      expect(el.nodes.length, equals(1));
      expect(el.nodes[0], isText);
      expect(el.nodes[0].text, equals(twoNewLines));
      expect(el.text, equals(twoNewLines));
    });

    test('documentFragment', () {
      var fragment = new DocumentFragment();
      fragment.appendText('foo');
      // No children were created.
      expect(fragment.children.length, equals(0));
      // One text node was added.
      expect(fragment.nodes.length, equals(1));
    });
  });

  group('insertAdjacentElement', () {
    test('beforebegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      var newChild = new SpanElement();
      parent.children.add(child);

      child.insertAdjacentElement('beforebegin', newChild);

      expect(parent.children.length, 2);
      expect(parent.children[0], isSpanElement);
    });

    test('afterend', () {
      var parent = new DivElement();
      var child = new DivElement();
      var newChild = new SpanElement();
      parent.children.add(child);

      child.insertAdjacentElement('afterend', newChild);

      expect(parent.children.length, 2);
      expect(parent.children[1], isSpanElement);
    });

    test('afterbegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      var newChild = new SpanElement();
      parent.children.add(child);

      parent.insertAdjacentElement('afterbegin', newChild);

      expect(parent.children.length, 2);
      expect(parent.children[0], isSpanElement);
    });

    test('beforeend', () {
      var parent = new DivElement();
      var child = new DivElement();
      var newChild = new SpanElement();
      parent.children.add(child);

      parent.insertAdjacentElement('beforeend', newChild);

      expect(parent.children.length, 2);
      expect(parent.children[1], isSpanElement);
    });
  });

  group('insertAdjacentHtml', () {
    test('beforebegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.children.add(child);

      child.insertAdjacentHtml('beforebegin', '<span></span>');

      expect(parent.children.length, 2);
      expect(parent.children[0], isSpanElement);
    });

    test('afterend', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.children.add(child);

      child.insertAdjacentHtml('afterend', '<span></span>');

      expect(parent.children.length, 2);
      expect(parent.children[1], isSpanElement);
    });

    test('afterbegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.children.add(child);

      parent.insertAdjacentHtml('afterbegin', '<span></span>');

      expect(parent.children.length, 2);
      expect(parent.children[0], isSpanElement);
    });

    test('beforeend', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.children.add(child);

      parent.insertAdjacentHtml('beforeend', '<span></span>');

      expect(parent.children.length, 2);
      expect(parent.children[1], isSpanElement);
    });
  });

  group('insertAdjacentText', () {
    test('beforebegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.children.add(child);

      child.insertAdjacentText('beforebegin', 'test');

      expect(parent.nodes.length, 2);
      expect(parent.nodes[0], isText);
    });

    test('afterend', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.children.add(child);

      child.insertAdjacentText('afterend', 'test');

      expect(parent.nodes.length, 2);
      expect(parent.nodes[1], isText);
    });

    test('afterbegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.children.add(child);

      parent.insertAdjacentText('afterbegin', 'test');

      expect(parent.nodes.length, 2);
      expect(parent.nodes[0], isText);
    });

    test('beforeend', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.children.add(child);

      parent.insertAdjacentText('beforeend', 'test');

      expect(parent.nodes.length, 2);
      expect(parent.nodes[1], isText);
    });
  });
}
