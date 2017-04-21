// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:html';

import 'package:expect/minitest.dart';

Element makeElement() => new Element.tag('div');

Element makeElementWithClasses() =>
    new Element.html('<div class="foo bar baz"></div>');

CssClassSet makeClassSet() => makeElementWithClasses().classes;

Element makeListElement() => new Element.html('<ul class="foo bar baz">'
    '<li class="quux qux">'
    '<li class="meta">'
    '<li class="classy lassy">'
    '<li class="qux lassy">'
    '</ul>');

Element listElement;

ElementList<Element> listElementSetup() {
  listElement = makeListElement();
  document.documentElement.children.add(listElement);
  return document.querySelectorAll('li');
}

void listElementTearDown() {
  if (listElement != null) {
    document.documentElement.children.remove(listElement);
    listElement = null;
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

  test('affects the "class" attribute', () {
    final el = makeElementWithClasses();
    el.classes.add('qux');
    expect(extractClasses(el), equals(['foo', 'bar', 'baz', 'qux']));
  });

  test('is affected by the "class" attribute', () {
    final el = makeElementWithClasses();
    el.attributes['class'] = 'foo qux';
    expect(el.classes, equals(['foo', 'qux']));
  });

  test('classes=', () {
    final el = makeElementWithClasses();
    el.classes = ['foo', 'qux'];
    expect(el.classes, equals(['foo', 'qux']));
    expect(extractClasses(el), equals(['foo', 'qux']));
  });

  test('toString', () {
    expect(makeClassSet().toString().split(' '), equals(['foo', 'bar', 'baz']));
    expect(makeElement().classes.toString(), '');
  });

  test('forEach', () {
    final classes = <String>[];
    makeClassSet().forEach(classes.add);
    expect(classes, equals(['foo', 'bar', 'baz']));
  });

  test('iterator', () {
    final classes = <String>[];
    for (var el in makeClassSet()) {
      classes.add(el);
    }
    expect(classes, equals(['foo', 'bar', 'baz']));
  });

  test('map', () {
    expect(makeClassSet().map((c) => c.toUpperCase()).toList(),
        equals(['FOO', 'BAR', 'BAZ']));
  });

  test('where', () {
    expect(makeClassSet().where((c) => c.contains('a')).toList(),
        equals(['bar', 'baz']));
  });

  test('every', () {
    expect(makeClassSet().every((c) => c is String), isTrue);
    expect(makeClassSet().every((c) => c.contains('a')), isFalse);
  });

  test('any', () {
    expect(makeClassSet().any((c) => c.contains('a')), isTrue);
    expect(makeClassSet().any((c) => c is num), isFalse);
  });

  test('isEmpty', () {
    expect(makeClassSet().isEmpty, isFalse);
    expect(makeElement().classes.isEmpty, isTrue);
  });

  test('length', () {
    expect(makeClassSet().length, 3);
    expect(makeElement().classes.length, 0);
  });

  test('contains', () {
    expect(makeClassSet().contains('foo'), isTrue);
    expect(makeClassSet().contains('qux'), isFalse);
  });

  test('contains-bad', () {
    // Non-strings return `false`.
    // Strings need to be valid tokens.
    final classes = makeClassSet();
    expect(classes.contains(1), isFalse);
    expect(() => classes.contains(''), throws);
    expect(() => classes.contains('foo bar'), throws);
  });

  test('add', () {
    final classes = makeClassSet();
    var added = classes.add('qux');
    expect(added, isTrue);
    expect(classes, equals(['foo', 'bar', 'baz', 'qux']));

    added = classes.add('qux');
    expect(added, isFalse);
    final list = new List.from(classes);
    list.sort((a, b) => a.compareTo(b));
    expect(list, equals(['bar', 'baz', 'foo', 'qux']),
        reason: "The class set shouldn't have duplicate elements.");
  });

  test('add-bad', () {
    final classes = makeClassSet();
    expect(() => classes.add(''), throws);
    expect(() => classes.add('foo bar'), throws);
  });

  test('remove', () {
    final classes = makeClassSet();
    classes.remove('bar');
    expect(classes, equals(['foo', 'baz']));
    classes.remove('qux');
    expect(classes, equals(['foo', 'baz']));
  });

  test('remove-bad', () {
    final classes = makeClassSet();
    expect(() => classes.remove(''), throws);
    expect(() => classes.remove('foo bar'), throws);
  });

  test('toggle', () {
    final classes = makeClassSet();
    classes.toggle('bar');
    expect(classes, equals(['foo', 'baz']));
    classes.toggle('qux');
    expect(classes, equals(['foo', 'baz', 'qux']));

    classes.toggle('qux', true);
    expect(classes, equals(['foo', 'baz', 'qux']));
    classes.toggle('qux', false);
    expect(classes, equals(['foo', 'baz']));
    classes.toggle('qux', false);
    expect(classes, equals(['foo', 'baz']));
    classes.toggle('qux', true);
    expect(classes, equals(['foo', 'baz', 'qux']));
  });

  test('toggle-bad', () {
    final classes = makeClassSet();
    expect(() => classes.toggle(''), throws);
    expect(() => classes.toggle('', true), throws);
    expect(() => classes.toggle('', false), throws);
    expect(() => classes.toggle('foo bar'), throws);
    expect(() => classes.toggle('foo bar', true), throws);
    expect(() => classes.toggle('foo bar', false), throws);
  });

  test('addAll', () {
    final classes = makeClassSet();
    classes.addAll(['bar', 'qux', 'bip']);
    expect(classes, equals(['foo', 'bar', 'baz', 'qux', 'bip']));
  });

  test('removeAll', () {
    final classes = makeClassSet();
    classes.removeAll(['bar', 'baz', 'qux']);
    expect(classes, equals(['foo']));
  });

  test('toggleAll', () {
    final classes = makeClassSet();
    classes.toggleAll(['bar', 'foo']);
    expect(classes, equals(['baz']));
    classes.toggleAll(['qux', 'quux']);
    expect(classes, equals(['baz', 'qux', 'quux']));
    classes.toggleAll(['bar', 'foo'], true);
    expect(classes, equals(['baz', 'qux', 'quux', 'bar', 'foo']));
    classes.toggleAll(['baz', 'quux'], false);
    expect(classes, equals(['qux', 'bar', 'foo']));
  });

  test('retainAll', () {
    final classes = makeClassSet();
    classes.retainAll(['bar', 'baz', 'qux']);
    expect(classes, equals(['bar', 'baz']));
  });

  test('removeWhere', () {
    final classes = makeClassSet();
    classes.removeWhere((s) => s.startsWith('b'));
    expect(classes, equals(['foo']));
  });

  test('retainWhere', () {
    final classes = makeClassSet();
    classes.retainWhere((s) => s.startsWith('b'));
    expect(classes, equals(['bar', 'baz']));
  });

  test('containsAll', () {
    final classes = makeClassSet();
    expect(classes.containsAll(['foo', 'baz']), isTrue);
    expect(classes.containsAll(['foo', 'qux']), isFalse);
    expect(classes.containsAll(['foo', 'baz'].toSet()), isTrue);
    expect(classes.containsAll(['foo', 'qux'].toSet()), isFalse);
  });

  test('intersection', () {
    final classes = makeClassSet();
    expect(classes.intersection(['foo', 'qux', 'baz'].toSet()),
        unorderedEquals(['foo', 'baz']));
  });

  test('clear', () {
    final classes = makeClassSet();
    classes.clear();
    expect(classes, equals([]));
  });

  test('order', () {
    var classes = makeClassSet();
    classes.add('aardvark');
    expect(classes, equals(['foo', 'bar', 'baz', 'aardvark']));
    classes.toggle('baz');
    expect(classes, equals(['foo', 'bar', 'aardvark']));
    classes.toggle('baz');
    expect(classes, equals(['foo', 'bar', 'aardvark', 'baz']));
  });

  tearDown(listElementTearDown);

  test('list_view', () {
    // Test that the 'view' helper function is behaving.
    var elements = listElementSetup();
    expect(view(elements.classes), '[classy, lassy, meta, quux, qux]');
    expect(
        view(elements), '[[quux, qux], [meta], [classy, lassy], [lassy, qux]]');
  });

  test('listClasses=', () {
    var elements = listElementSetup();
    elements.classes = ['foo', 'qux'];
    elements = document.queryAll('li');
    for (Element e in elements) {
      expect(e.classes, equals(['foo', 'qux']));
      expect(extractClasses(e), equals(['foo', 'qux']));
    }

    elements.classes = [];
    expect(view(elements.classes), '[]');
    expect(view(elements), '[[], [], [], []]');
  });

  test('listMap', () {
    var elements = listElementSetup();
    expect(elements.classes.map((c) => c.toUpperCase()).toList(),
        unorderedEquals(['QUX', 'QUUX', 'META', 'CLASSY', 'LASSY']));
  });

  test('listContains', () {
    var elements = listElementSetup();
    expect(elements.classes.contains('lassy'), isTrue);
    expect(elements.classes.contains('foo'), isFalse);
  });

  test('listAdd', () {
    var elements = listElementSetup();
    var added = elements.classes.add('lassie');
    expect(added, isNull);

    expect(view(elements.classes), '[classy, lassie, lassy, meta, quux, qux]');
    expect(
        view(elements),
        '[[lassie, quux, qux], [lassie, meta], [classy, lassie, lassy], '
        '[lassie, lassy, qux]]');
  });

  test('listRemove', () {
    var elements = listElementSetup();
    expect(elements.classes.remove('lassi'), isFalse);
    expect(view(elements.classes), '[classy, lassy, meta, quux, qux]');
    expect(
        view(elements), '[[quux, qux], [meta], [classy, lassy], [lassy, qux]]');

    expect(elements.classes.remove('qux'), isTrue);
    expect(view(elements.classes), '[classy, lassy, meta, quux]');
    expect(view(elements), '[[quux], [meta], [classy, lassy], [lassy]]');
  });

  test('listToggle', () {
    var elements = listElementSetup();
    elements.classes.toggle('qux');
    expect(view(elements.classes), '[classy, lassy, meta, quux, qux]');
    expect(
        view(elements), '[[quux], [meta, qux], [classy, lassy, qux], [lassy]]');
  });

  test('listAddAll', () {
    var elements = listElementSetup();
    elements.classes.addAll(['qux', 'lassi', 'sassy']);
    expect(view(elements.classes),
        '[classy, lassi, lassy, meta, quux, qux, sassy]');
    expect(
        view(elements),
        '[[lassi, quux, qux, sassy], [lassi, meta, qux, sassy], '
        '[classy, lassi, lassy, qux, sassy], [lassi, lassy, qux, sassy]]');
  });

  test('listRemoveAll', () {
    var elements = listElementSetup();
    elements.classes.removeAll(['qux', 'lassy', 'meta']);
    expect(view(elements.classes), '[classy, quux]');
    expect(view(elements), '[[quux], [], [classy], []]');
  });

  test('listToggleAll', () {
    var elements = listElementSetup();
    elements.classes.toggleAll(['qux', 'meta', 'mornin']);
    expect(view(elements.classes), '[classy, lassy, meta, mornin, quux, qux]');
    expect(
        view(elements),
        '[[meta, mornin, quux], [mornin, qux], '
        '[classy, lassy, meta, mornin, qux], [lassy, meta, mornin]]');
  });

  test('listRetainAll', () {
    var elements = listElementSetup();
    elements.classes.retainAll(['bar', 'baz', 'qux']);
    expect(view(elements.classes), '[qux]');
    expect(view(elements), '[[qux], [], [], [qux]]');
  });

  test('listRemoveWhere', () {
    var elements = listElementSetup();
    elements.classes.removeWhere((s) => s.startsWith('q'));
    expect(view(elements.classes), '[classy, lassy, meta]');
    expect(view(elements), '[[], [meta], [classy, lassy], [lassy]]');
  });

  test('listRetainWhere', () {
    var elements = listElementSetup();
    elements.classes.retainWhere((s) => s.startsWith('q'));
    expect(view(elements.classes), '[quux, qux]');
    expect(view(elements), '[[quux, qux], [], [], [qux]]');
  });

  test('listContainsAll', () {
    var elements = listElementSetup();
    expect(elements.classes.containsAll(['qux', 'meta', 'mornin']), isFalse);
    expect(elements.classes.containsAll(['qux', 'lassy', 'classy']), isTrue);
  });
}
