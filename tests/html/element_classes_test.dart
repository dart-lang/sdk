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
    // TODO: Change to this when Issue 3484 is fixed.
    //    makeClassSet().forEach(classes.add);
    makeClassSet().forEach((c) => classes.add(c));
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
    classes.add('qux');
    expect(classes, orderedEquals(['foo', 'bar', 'baz', 'qux']));

    classes.add('qux');
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
}
