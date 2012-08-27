// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

#library('ElementAddTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');
#source('util.dart');

main() {
  useHtmlConfiguration();

  void expectNoSuchMethod(void fn()) =>
    Expect.throws(fn, (e) => e is NoSuchMethodException);

  group('addHTML', () {
    test('htmlelement', () {
      // Adding a <tr/> to a table should auto-wrap it into a tbody element.
      var el = new TableElement();
      el.addHTML('<tr>test</tr>');
      expect(el.elements.length, equals(1));
      var section = el.elements[0];
      expect(section is TableSectionElement);
      expect(section.elements.length, equals(1));
      expect(section.elements[0] is TableRowElement);

      el.addHTML('<tr>test</tr>');
      expect(el.elements.length, equals(2));
      // Validate that the first item is still first.
      expect(el.elements[0] == section);
      expect(el.elements[1] is TableSectionElement);
    });

    test('documentFragment', () {
      var fragment = new DocumentFragment();
      fragment.addHTML('<span>something</span>');
      expect(fragment.elements.length, equals(1));
      expect(fragment.elements[0] is SpanElement);
    });
  });

  group('addText', () {
    test('htmlelement', () {
      var el = new DivElement();
      el.addText('foo');
      // No elements were created.
      expect(el.elements.length, equals(0));
      // One text node was added.
      expect(el.nodes.length, equals(1));
    });

    test('documentFragment', () {
      var fragment = new DocumentFragment();
      fragment.addText('foo');
      // No elements were created.
      expect(fragment.elements.length, equals(0));
      // One text node was added.
      expect(fragment.nodes.length, equals(1));
    });
  });

  group('insertAdjacentElement', () {
    test('beforebegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      var newChild = new SpanElement();
      parent.elements.add(child);

      child.insertAdjacentElement('beforebegin', newChild);

      expect(parent.elements.length, 2);
      expect(parent.elements[0] is SpanElement);
    });

    test('afterend', () {
      var parent = new DivElement();
      var child = new DivElement();
      var newChild = new SpanElement();
      parent.elements.add(child);

      child.insertAdjacentElement('afterend', newChild);

      expect(parent.elements.length, 2);
      expect(parent.elements[1] is SpanElement);
    });

    test('afterbegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      var newChild = new SpanElement();
      parent.elements.add(child);

      parent.insertAdjacentElement('afterbegin', newChild);

      expect(parent.elements.length, 2);
      expect(parent.elements[0] is SpanElement);
    });

    test('beforeend', () {
      var parent = new DivElement();
      var child = new DivElement();
      var newChild = new SpanElement();
      parent.elements.add(child);

      parent.insertAdjacentElement('beforeend', newChild);

      expect(parent.elements.length, 2);
      expect(parent.elements[1] is SpanElement);
    });
  });

  group('insertAdjacentHTML', () {
    test('beforebegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.elements.add(child);

      child.insertAdjacentHTML('beforebegin', '<span></span>');

      expect(parent.elements.length, 2);
      expect(parent.elements[0] is SpanElement);
    });

    test('afterend', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.elements.add(child);

      child.insertAdjacentHTML('afterend', '<span></span>');

      expect(parent.elements.length, 2);
      expect(parent.elements[1] is SpanElement);
    });

    test('afterbegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.elements.add(child);

      parent.insertAdjacentHTML('afterbegin', '<span></span>');

      expect(parent.elements.length, 2);
      expect(parent.elements[0] is SpanElement);
    });

    test('beforeend', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.elements.add(child);

      parent.insertAdjacentHTML('beforeend', '<span></span>');

      expect(parent.elements.length, 2);
      expect(parent.elements[1] is SpanElement);
    });
  });

  group('insertAdjacentText', () {
    test('beforebegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.elements.add(child);

      child.insertAdjacentText('beforebegin', 'test');

      expect(parent.nodes.length, 2);
      expect(parent.nodes[0] is Text);
    });

    test('afterend', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.elements.add(child);

      child.insertAdjacentText('afterend', 'test');

      expect(parent.nodes.length, 2);
      expect(parent.nodes[1] is Text);
    });

    test('afterbegin', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.elements.add(child);

      parent.insertAdjacentText('afterbegin', 'test');

      expect(parent.nodes.length, 2);
      expect(parent.nodes[0] is Text);
    });

    test('beforeend', () {
      var parent = new DivElement();
      var child = new DivElement();
      parent.elements.add(child);

      parent.insertAdjacentText('beforeend', 'test');

      expect(parent.nodes.length, 2);
      expect(parent.nodes[1] is Text);
    });
  });
}
