// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/name_filter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NameFilterTest);
  });
}

@reflectiveTest
class NameFilterTest {
  test_accepts_accessors_hide() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
        new UnlinkedCombinatorBuilder(hides: ['bar']));
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('foo='), isTrue);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('bar='), isFalse);
  }

  test_accepts_accessors_show() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
        new UnlinkedCombinatorBuilder(shows: ['foo']));
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('foo='), isTrue);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('bar='), isFalse);
  }

  test_forNamespaceCombinator_hide() {
    NameFilter filter = new NameFilter.forNamespaceCombinator(
        new HideElementCombinatorImpl()..hiddenNames = ['foo', 'bar']);
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isTrue);
    expect(filter.shownNames, isNull);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, ['foo', 'bar'].toSet());
  }

  test_forNamespaceCombinator_show() {
    NameFilter filter = new NameFilter.forNamespaceCombinator(
        new ShowElementCombinatorImpl()..shownNames = ['foo', 'bar']);
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isTrue);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo', 'bar'].toSet());
  }

  test_forNamespaceCombinators() {
    NameFilter filter = new NameFilter.forNamespaceCombinators([
      new HideElementCombinatorImpl()..hiddenNames = ['foo'],
      new HideElementCombinatorImpl()..hiddenNames = ['bar']
    ]);
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isTrue);
    expect(filter.shownNames, isNull);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, ['foo', 'bar'].toSet());
  }

  test_forUnlinkedCombinator_hide() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
        new UnlinkedCombinatorBuilder(hides: ['foo', 'bar']));
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isTrue);
    expect(filter.shownNames, isNull);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, ['foo', 'bar'].toSet());
  }

  test_forUnlinkedCombinator_show() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
        new UnlinkedCombinatorBuilder(shows: ['foo', 'bar']));
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isTrue);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo', 'bar'].toSet());
  }

  test_forUnlinkedCombinators() {
    NameFilter filter = new NameFilter.forUnlinkedCombinators([
      new UnlinkedCombinatorBuilder(hides: ['foo']),
      new UnlinkedCombinatorBuilder(hides: ['bar'])
    ]);
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isTrue);
    expect(filter.shownNames, isNull);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, ['foo', 'bar'].toSet());
  }

  test_identity() {
    expect(NameFilter.identity.accepts('foo'), isTrue);
    expect(NameFilter.identity.hiddenNames, isNotNull);
    expect(NameFilter.identity.hiddenNames, isEmpty);
    expect(NameFilter.identity.shownNames, isNull);
  }

  test_merge_hides_hides() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(hides: ['foo']))
        .merge(new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(hides: ['bar'])));
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isTrue);
    expect(filter.shownNames, isNull);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, ['foo', 'bar'].toSet());
  }

  test_merge_hides_identity() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(hides: ['foo', 'bar']))
        .merge(NameFilter.identity);
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isTrue);
    expect(filter.shownNames, isNull);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, ['foo', 'bar'].toSet());
  }

  test_merge_hides_shows() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(hides: ['bar', 'baz']))
        .merge(new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(shows: ['foo', 'bar'])));
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo'].toSet());
  }

  test_merge_identity_hides() {
    NameFilter filter = NameFilter.identity.merge(
        new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(hides: ['foo', 'bar'])));
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isTrue);
    expect(filter.shownNames, isNull);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, ['foo', 'bar'].toSet());
  }

  test_merge_identity_identity() {
    NameFilter filter = NameFilter.identity.merge(NameFilter.identity);
    expect(filter.accepts('foo'), isTrue);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, isEmpty);
    expect(filter.shownNames, isNull);
  }

  test_merge_identity_shows() {
    NameFilter filter = NameFilter.identity.merge(
        new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(shows: ['foo', 'bar'])));
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isTrue);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo', 'bar'].toSet());
  }

  test_merge_shows_hides() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(shows: ['foo', 'bar']))
        .merge(new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(hides: ['bar', 'baz'])));
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo'].toSet());
  }

  test_merge_shows_identity() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(shows: ['foo', 'bar']))
        .merge(NameFilter.identity);
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isTrue);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo', 'bar'].toSet());
  }

  test_merge_shows_shows() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(shows: ['foo', 'bar']))
        .merge(new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(shows: ['bar', 'baz'])));
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isTrue);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['bar'].toSet());
  }

  test_merge_shows_shows_emptyResult() {
    NameFilter filter = new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(shows: ['foo']))
        .merge(new NameFilter.forUnlinkedCombinator(
            new UnlinkedCombinatorBuilder(shows: ['bar'])));
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, isEmpty);
  }
}
