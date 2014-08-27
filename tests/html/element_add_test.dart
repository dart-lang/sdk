// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library ElementAddTest;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'util.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  var isSpanElement = predicate((x) => x is SpanElement, 'is a SpanElemt');
  var isDivElement = predicate((x) => x is DivElement, 'is a DivElement');
  var isText = predicate((x) => x is Text, 'is a Text');

  void expectNoSuchMethod(void fn()) =>
    expect(fn, throwsNoSuchMethodError);

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
