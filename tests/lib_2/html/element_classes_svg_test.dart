// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:html';
import 'dart:svg' as svg;

import 'package:expect/minitest.dart';

// Test for `querySelectorAll(xxx).classes.op()` where the query returns mixed
// Html and Svg elements.

Element makeElementsContainer() {
  var e = new Element.html('<ul class="yes foo">'
      '<li class="yes quux qux">'
      '</ul>');
  final svgContent = r"""
<svg version="1.1">
  <circle class="yes qux"></circle>
  <path class="yes classy"></path>
</svg>""";
  final svgElement = new svg.SvgElement.svg(svgContent);
  e.append(svgElement);
  return e;
}

Element elementsContainer;

ElementList<Element> elementsSetup() {
  elementsContainer = makeElementsContainer();
  document.documentElement.children.add(elementsContainer);
  var elements = document.querySelectorAll('.yes');
  expect(elements.length, 4);
  return elements;
}

void elementsTearDown() {
  if (elementsContainer != null) {
    document.documentElement.children.remove(elementsContainer);
    elementsContainer = null;
  }
}

/// Returns a canonical string for Set<String> and lists of Element's classes.
String view(var e) {
  if (e is Set) return '${e.toList()..sort()}';
  if (e is Element) return view(e.classes);
  if (e is Iterable) return '${e.map(view).toList()}';
  throw new ArgumentError('Cannot make canonical view string for: $e}');
}

main() {
  Set<String> extractClasses(Element el) {
    final match = new RegExp('class="([^"]+)"').firstMatch(el.outerHtml);
    return new LinkedHashSet.from(match[1].split(' '));
  }

  tearDown(elementsTearDown);

  test('list_view', () {
    // Test that the 'view' helper function is behaving.
    var elements = elementsSetup();
    expect(view(elements.classes), '[classy, foo, quux, qux, yes]');
    expect(view(elements),
        '[[foo, yes], [quux, qux, yes], [qux, yes], [classy, yes]]');
  });

  test('listClasses=', () {
    var elements = elementsSetup();

    elements.classes = ['foo', 'qux'];
    expect(view(elements.classes), '[foo, qux]');
    expect(view(elements), '[[foo, qux], [foo, qux], [foo, qux], [foo, qux]]');

    var elements2 = document.querySelectorAll('.qux');
    expect(view(elements2.classes), '[foo, qux]');
    expect(view(elements2), '[[foo, qux], [foo, qux], [foo, qux], [foo, qux]]');

    for (Element e in elements2) {
      expect(e.classes, equals(['foo', 'qux']));
      expect(extractClasses(e), equals(['foo', 'qux']));
    }

    elements.classes = [];
    expect(view(elements2.classes), '[]');
    expect(view(elements2), '[[], [], [], []]');
  });

  test('listMap', () {
    var elements = elementsSetup();
    expect(elements.classes.map((c) => c.toUpperCase()).toList(),
        unorderedEquals(['YES', 'FOO', 'QUX', 'QUUX', 'CLASSY']));
  });

  test('listContains', () {
    var elements = elementsSetup();
    expect(elements.classes.contains('classy'), isTrue);
    expect(elements.classes.contains('troll'), isFalse);
  });

  test('listAdd', () {
    var elements = elementsSetup();
    var added = elements.classes.add('lassie');
    expect(added, isNull);

    expect(view(elements.classes), '[classy, foo, lassie, quux, qux, yes]');
    expect(
        view(elements),
        '[[foo, lassie, yes], [lassie, quux, qux, yes], '
        '[lassie, qux, yes], [classy, lassie, yes]]');
  });

  test('listRemove', () {
    var elements = elementsSetup();
    expect(elements.classes.remove('lassi'), isFalse);
    expect(view(elements.classes), '[classy, foo, quux, qux, yes]');
    expect(view(elements),
        '[[foo, yes], [quux, qux, yes], [qux, yes], [classy, yes]]');

    expect(elements.classes.remove('qux'), isTrue);
    expect(view(elements.classes), '[classy, foo, quux, yes]');
    expect(view(elements), '[[foo, yes], [quux, yes], [yes], [classy, yes]]');
  });

  test('listToggle', () {
    var elements = elementsSetup();
    elements.classes.toggle('qux');
    expect(view(elements.classes), '[classy, foo, quux, qux, yes]');
    expect(view(elements),
        '[[foo, qux, yes], [quux, yes], [yes], [classy, qux, yes]]');
  });

  test('listAddAll', () {
    var elements = elementsSetup();
    elements.classes.addAll(['qux', 'lassi', 'sassy']);
    expect(
        view(elements.classes), '[classy, foo, lassi, quux, qux, sassy, yes]');
    expect(
        view(elements),
        '[[foo, lassi, qux, sassy, yes], [lassi, quux, qux, sassy, yes], '
        '[lassi, qux, sassy, yes], [classy, lassi, qux, sassy, yes]]');
  });

  test('listRemoveAll', () {
    var elements = elementsSetup();
    elements.classes.removeAll(['qux', 'classy', 'mumble']);
    expect(view(elements.classes), '[foo, quux, yes]');
    expect(view(elements), '[[foo, yes], [quux, yes], [yes], [yes]]');

    elements.classes.removeAll(['foo', 'yes']);
    expect(view(elements.classes), '[quux]');
    expect(view(elements), '[[], [quux], [], []]');
  });

  test('listToggleAll', () {
    var elements = elementsSetup();
    elements.classes.toggleAll(['qux', 'mornin']);
    expect(view(elements.classes), '[classy, foo, mornin, quux, qux, yes]');
    expect(
        view(elements),
        '[[foo, mornin, qux, yes], [mornin, quux, yes], '
        '[mornin, yes], [classy, mornin, qux, yes]]');
  });

  test('listRetainAll', () {
    var elements = elementsSetup();
    elements.classes.retainAll(['bar', 'baz', 'classy', 'qux']);
    expect(view(elements.classes), '[classy, qux]');
    expect(view(elements), '[[], [qux], [qux], [classy]]');
  });

  test('listRemoveWhere', () {
    var elements = elementsSetup();
    elements.classes.removeWhere((s) => s.startsWith('q'));
    expect(view(elements.classes), '[classy, foo, yes]');
    expect(view(elements), '[[foo, yes], [yes], [yes], [classy, yes]]');
  });

  test('listRetainWhere', () {
    var elements = elementsSetup();
    elements.classes.retainWhere((s) => s.startsWith('q'));
    expect(view(elements.classes), '[quux, qux]');
    expect(view(elements), '[[], [quux, qux], [qux], []]');
  });

  test('listContainsAll', () {
    var elements = elementsSetup();
    expect(elements.classes.containsAll(['qux', 'mornin']), isFalse);
    expect(elements.classes.containsAll(['qux', 'classy']), isTrue);
  });
}
