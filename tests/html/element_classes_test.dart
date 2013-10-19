// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ElementTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:collection';
import 'dart:html';

main() {
  useHtmlConfiguration();

  Element makeElement() => new Element.tag('div');

  Element makeElementWithChildren() =>
    new Element.html("<div><br/><img/><input/></div>");

  Element makeElementWithClasses() =>
    new Element.html('<div class="foo bar baz"></div>');

  Element makeListElement() =>
    new Element.html('<ul class="foo bar baz">'
        '<li class="quux qux"><li class="meta">'
        '<li class="classy lassy"><li class="qux lassy"></ul>');

  Set<String> makeClassSet() => makeElementWithClasses().classes;

  Set<String> extractClasses(Element el) {
    final match = new RegExp('class="([^"]+)"').firstMatch(el.outerHtml);
    return new LinkedHashSet.from(match[1].split(' '));
  }

  test('affects the "class" attribute', () {
    final el = makeElementWithClasses();
    el.classes.add('qux');
    expect(extractClasses(el), orderedEquals(['foo', 'bar', 'baz', 'qux']));
  });

  test('is affected by the "class" attribute', () {
    final el = makeElementWithClasses();
    el.attributes['class'] = 'foo qux';
    expect(el.classes, orderedEquals(['foo', 'qux']));
  });

  test('classes=', () {
    final el = makeElementWithClasses();
    el.classes = ['foo', 'qux'];
    expect(el.classes, orderedEquals(['foo', 'qux']));
    expect(extractClasses(el), orderedEquals(['foo', 'qux']));
  });

  test('toString', () {
    expect(makeClassSet().toString().split(' '),
        orderedEquals(['foo', 'bar', 'baz']));
    expect(makeElement().classes.toString(), '');
  });

  test('forEach', () {
    final classes = <String>[];
    makeClassSet().forEach(classes.add);
    expect(classes, orderedEquals(['foo', 'bar', 'baz']));
  });

  test('iterator', () {
    final classes = <String>[];
    for (var el in makeClassSet()) {
      classes.add(el);
    }
    expect(classes, orderedEquals(['foo', 'bar', 'baz']));
  });

  test('map', () {
    expect(makeClassSet().map((c) => c.toUpperCase()).toList(),
        orderedEquals(['FOO', 'BAR', 'BAZ']));
  });

  test('where', () {
    expect(makeClassSet().where((c) => c.contains('a')).toList(),
        orderedEquals(['bar', 'baz']));
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

  test('add', () {
    final classes = makeClassSet();
    var added = classes.add('qux');
    expect(added, isTrue);
    expect(classes, orderedEquals(['foo', 'bar', 'baz', 'qux']));

    added = classes.add('qux');
    expect(added, isFalse);
    final list = new List.from(classes);
    list.sort((a, b) => a.compareTo(b));
    expect(list, orderedEquals(['bar', 'baz', 'foo', 'qux']),
        reason: "The class set shouldn't have duplicate elements.");
  });

  test('remove', () {
    final classes = makeClassSet();
    classes.remove('bar');
    expect(classes, orderedEquals(['foo', 'baz']));
    classes.remove('qux');
    expect(classes, orderedEquals(['foo', 'baz']));
  });

  test('toggle', () {
    final classes = makeClassSet();
    classes.toggle('bar');
    expect(classes, orderedEquals(['foo', 'baz']));
    classes.toggle('qux');
    expect(classes, orderedEquals(['foo', 'baz', 'qux']));

    classes.toggle('qux', true);
    expect(classes, orderedEquals(['foo', 'baz', 'qux']));
    classes.toggle('qux', false);
    expect(classes, orderedEquals(['foo', 'baz']));
    classes.toggle('qux', false);
    expect(classes, orderedEquals(['foo', 'baz']));
    classes.toggle('qux', true);
    expect(classes, orderedEquals(['foo', 'baz', 'qux']));
  });

  test('addAll', () {
    final classes = makeClassSet();
    classes.addAll(['bar', 'qux', 'bip']);
    expect(classes, orderedEquals(['foo', 'bar', 'baz', 'qux', 'bip']));
  });

  test('removeAll', () {
    final classes = makeClassSet();
    classes.removeAll(['bar', 'baz', 'qux']);
    expect(classes, orderedEquals(['foo']));
  });

  test('toggleAll', () {
    final classes = makeClassSet();
    classes.toggleAll(['bar', 'foo']);
    expect(classes, orderedEquals(['baz']));
    classes.toggleAll(['qux', 'quux']);
    expect(classes, orderedEquals(['baz', 'qux', 'quux']));
    classes.toggleAll(['bar', 'foo'], true);
    expect(classes, orderedEquals(['baz', 'qux', 'quux', 'bar', 'foo']));
    classes.toggleAll(['baz', 'quux'], false);
    expect(classes, orderedEquals(['qux','bar', 'foo']));
  });

  test('containsAll', () {
    final classes = makeClassSet();
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
    expect(classes, orderedEquals(['foo', 'bar', 'baz', 'aardvark']));
    classes.toggle('baz');
    expect(classes, orderedEquals(['foo', 'bar', 'aardvark']));
    classes.toggle('baz');
    expect(classes, orderedEquals(['foo', 'bar', 'aardvark', 'baz']));
  });

  Element listElement;

  ElementList listElementSetup() {
    listElement = makeListElement();
    document.documentElement.children.add(listElement);
    return document.queryAll('li');
  }

  test('listClasses=', () {
    var elements =  listElementSetup();
    elements.classes = ['foo', 'qux'];
    elements = document.queryAll('li');
    for (Element e in elements) {
      expect(e.classes, orderedEquals(['foo', 'qux']));
      expect(extractClasses(e), orderedEquals(['foo', 'qux']));
    }

    elements.classes = [];
    for (Element e in elements) {
      expect(e.classes, []);
    }
    document.documentElement.children.remove(listElement);
  });

  test('listMap', () {
    var elements = listElementSetup();
    expect(elements.classes.map((c) => c.toUpperCase()).toList(),
        unorderedEquals(['QUX', 'QUUX', 'META', 'CLASSY', 'LASSY']));
    document.documentElement.children.remove(listElement);
  });

  test('listContains', () {
    var elements = listElementSetup();
    expect(elements.classes.contains('lassy'), isTrue);
    expect(elements.classes.contains('foo'), isFalse);
    document.documentElement.children.remove(listElement);
  });


  test('listAdd', () {
    var elements =  listElementSetup();
    var added = elements.classes.add('lassie');
    expect(added, isNull);

    expect(elements.classes,
        unorderedEquals(['lassie', 'qux', 'quux', 'meta', 'classy', 'lassy']));
    for (Element e in elements) {
      expect(e.classes, anyOf(unorderedEquals(['quux', 'qux', 'lassie']),
          unorderedEquals(['meta', 'lassie']),
          unorderedEquals(['classy', 'lassy', 'lassie']),
          unorderedEquals(['qux', 'lassy', 'lassie'])));
    }
    document.documentElement.children.remove(listElement);
  });

  test('listRemove', () {
    var elements = listElementSetup();
    expect(elements.classes.remove('lassi'), isFalse);
    expect(elements.classes,
        unorderedEquals(['qux', 'quux', 'meta', 'classy', 'lassy']));
    for (Element e in elements) {
      expect(e.classes, anyOf(unorderedEquals(['quux', 'qux']),
          unorderedEquals(['meta']), unorderedEquals(['classy', 'lassy']),
          unorderedEquals(['qux', 'lassy'])));
    }

    expect(elements.classes.remove('qux'), isTrue);
    expect(elements.classes,
        unorderedEquals(['quux', 'meta', 'classy', 'lassy']));
    for (Element e in elements) {
      expect(e.classes, anyOf(unorderedEquals(['quux']),
          unorderedEquals(['meta']), unorderedEquals(['classy', 'lassy']),
          unorderedEquals(['lassy'])));
    }
    document.documentElement.children.remove(listElement);
  });

  test('listToggle', () {
    var elements = listElementSetup();
    elements.classes.toggle('qux');
    expect(elements.classes,
        unorderedEquals(['qux', 'quux', 'meta', 'classy', 'lassy']));
    for (Element e in elements) {
      expect(e.classes, anyOf(unorderedEquals(['quux']),
          unorderedEquals(['meta', 'qux']), unorderedEquals(['classy', 'lassy',
          'qux']), unorderedEquals(['lassy'])));
    }
    document.documentElement.children.remove(listElement);
  });

  test('listAddAll', () {
    var elements = listElementSetup();
    elements.classes.addAll(['qux', 'lassi', 'sassy']);
    expect(elements.classes,
        unorderedEquals(['qux', 'quux', 'meta', 'classy', 'lassy', 'sassy',
        'lassi']));
    for (Element e in elements) {
      expect(e.classes, anyOf(
          unorderedEquals(['quux', 'qux', 'lassi', 'sassy']),
          unorderedEquals(['meta', 'qux', 'lassi', 'sassy']),
          unorderedEquals(['classy', 'lassy', 'qux', 'lassi','sassy']),
          unorderedEquals(['lassy', 'qux', 'lassi', 'sassy'])));
    }
    document.documentElement.children.remove(listElement);
  });

  test('listRemoveAll', () {
    var elements = listElementSetup();
    elements.classes.removeAll(['qux', 'lassy', 'meta']);
    expect(elements.classes,
        unorderedEquals(['quux','classy']));
    for (Element e in elements) {
      expect(e.classes, anyOf(unorderedEquals(['quux']),
          unorderedEquals([]), unorderedEquals(['classy'])));
    }
    document.documentElement.children.remove(listElement);
  });

  test('listToggleAll', () {
    var elements = listElementSetup();
    elements.classes.toggleAll(['qux', 'meta', 'mornin']);
    expect(elements.classes,
        unorderedEquals(['qux', 'quux', 'meta', 'classy', 'lassy', 'mornin']));
    for (Element e in elements) {
      expect(e.classes, anyOf(unorderedEquals(['quux', 'meta', 'mornin']),
          unorderedEquals(['qux', 'mornin']),
          unorderedEquals(['classy', 'lassy', 'qux', 'mornin', 'meta']),
          unorderedEquals(['lassy', 'mornin', 'meta'])));
    }
    document.documentElement.children.remove(listElement);
  });

  test('listContainsAll', () {
    var elements = listElementSetup();
    expect(elements.classes.containsAll(['qux', 'meta', 'mornin']), isFalse);
    expect(elements.classes.containsAll(['qux', 'lassy', 'classy']), isTrue);
    document.documentElement.children.remove(listElement);
  });
}
