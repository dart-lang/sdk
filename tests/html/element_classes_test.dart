// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('ElementTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  Element makeElement() => new Element.tag('div');

  Element makeElementWithChildren() =>
    new Element.html("<div><br/><img/><input/></div>");

  Element makeElementWithClasses() =>
    new Element.html('<div class="foo bar baz"></div>');

  Set<String> makeClassSet() => makeElementWithClasses().classes;

  Set<String> extractClasses(Element el) {
    final match = new RegExp('class="([^"]+)"').firstMatch(el.outerHTML);
    return new Set.from(match[1].split(' '));
  }

  test('affects the "class" attribute', () {
    final el = makeElementWithClasses();
    el.classes.add('qux');
    Expect.setEquals(['foo', 'bar', 'baz', 'qux'], extractClasses(el));
  });

  test('is affected by the "class" attribute', () {
    final el = makeElementWithClasses();
    el.attributes['class'] = 'foo qux';
    Expect.setEquals(['foo', 'qux'], el.classes);
  });

  test('classes=', () {
    final el = makeElementWithClasses();
    el.classes = ['foo', 'qux'];
    Expect.setEquals(['foo', 'qux'], el.classes);
    Expect.setEquals(['foo', 'qux'], extractClasses(el));
  });

  test('toString', () {
    Expect.setEquals(['foo', 'bar', 'baz'],
        makeClassSet().toString().split(' '));
    Expect.equals('', makeElement().classes.toString());
  });

  test('forEach', () {
    final classes = <String>[];
    // TODO: Change to this when Issue 3484 is fixed.
    //    makeClassSet().forEach(classes.add);
    makeClassSet().forEach((c) => classes.add(c));
    Expect.setEquals(['foo', 'bar', 'baz'], classes);
  });

  test('iterator', () {
    final classes = <String>[];
    for (var el in makeClassSet()) {
      classes.add(el);
    }
    Expect.setEquals(['foo', 'bar', 'baz'], classes);
  });

  test('map', () {
    Expect.setEquals(['FOO', 'BAR', 'BAZ'],
        makeClassSet().map((c) => c.toUpperCase()));
  });

  test('filter', () {
    Expect.setEquals(['bar', 'baz'],
        makeClassSet().filter((c) => c.contains('a')));
  });

  test('every', () {
    Expect.isTrue(makeClassSet().every((c) => c is String));
    Expect.isFalse(
        makeClassSet().every((c) => c.contains('a')));
  });

  test('some', () {
    Expect.isTrue(
        makeClassSet().some((c) => c.contains('a')));
    Expect.isFalse(makeClassSet().some((c) => c is num));
  });

  test('isEmpty', () {
    Expect.isFalse(makeClassSet().isEmpty());
    Expect.isTrue(makeElement().classes.isEmpty());
  });

  test('length', () {
    Expect.equals(3, makeClassSet().length);
    Expect.equals(0, makeElement().classes.length);
  });

  test('contains', () {
    Expect.isTrue(makeClassSet().contains('foo'));
    Expect.isFalse(makeClassSet().contains('qux'));
  });

  test('add', () {
    final classes = makeClassSet();
    classes.add('qux');
    Expect.setEquals(['foo', 'bar', 'baz', 'qux'], classes);

    classes.add('qux');
    final list = new List.from(classes);
    list.sort((a, b) => a.compareTo(b));
    Expect.listEquals(['bar', 'baz', 'foo', 'qux'], list,
        "The class set shouldn't have duplicate elements.");
  });

  test('remove', () {
    final classes = makeClassSet();
    classes.remove('bar');
    Expect.setEquals(['foo', 'baz'], classes);
    classes.remove('qux');
    Expect.setEquals(['foo', 'baz'], classes);
  });

  test('toggle', () {
    final classes = makeClassSet();
    classes.toggle('bar');
    Expect.setEquals(['foo', 'baz'], classes);
    classes.toggle('qux');
    Expect.setEquals(['foo', 'baz', 'qux'], classes);
  });

  test('addAll', () {
    final classes = makeClassSet();
    classes.addAll(['bar', 'qux', 'bip']);
    Expect.setEquals(['foo', 'bar', 'baz', 'qux', 'bip'], classes);
  });

  test('removeAll', () {
    final classes = makeClassSet();
    classes.removeAll(['bar', 'baz', 'qux']);
    Expect.setEquals(['foo'], classes);
  });

  test('isSubsetOf', () {
    final classes = makeClassSet();
    Expect.isTrue(classes.isSubsetOf(['foo', 'bar', 'baz']));
    Expect.isTrue(classes.isSubsetOf(['foo', 'bar', 'baz', 'qux']));
    Expect.isFalse(classes.isSubsetOf(['foo', 'bar', 'qux']));
  });

  test('containsAll', () {
    final classes = makeClassSet();
    Expect.isTrue(classes.containsAll(['foo', 'baz']));
    Expect.isFalse(classes.containsAll(['foo', 'qux']));
  });

  test('intersection', () {
    final classes = makeClassSet();
    Expect.setEquals(['foo', 'baz'],
        classes.intersection(['foo', 'qux', 'baz']));
  });

  test('clear', () {
    final classes = makeClassSet();
    classes.clear();
    Expect.setEquals([], classes);
  });
}
