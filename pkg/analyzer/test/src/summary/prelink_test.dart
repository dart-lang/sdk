// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(NameFilterTest);
}

class MockUnlinkedCombinator implements UnlinkedCombinator {
  @override
  final List<String> hides;

  @override
  final List<String> shows;

  MockUnlinkedCombinator(
      {this.hides: const <String>[], this.shows: const <String>[]});

  @override
  Map<String, Object> toMap() {
    fail('toMap() called unexpectedly');
    return null;
  }
}

@reflectiveTest
class NameFilterTest {
  test_forCombinator_hide() {
    NameFilter filter = new NameFilter.forCombinator(
        new MockUnlinkedCombinator(hides: ['foo', 'bar']));
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isTrue);
    expect(filter.shownNames, isNull);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, ['foo', 'bar'].toSet());
  }

  test_forCombinator_show() {
    NameFilter filter = new NameFilter.forCombinator(
        new MockUnlinkedCombinator(shows: ['foo', 'bar']));
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isTrue);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo', 'bar'].toSet());
  }

  test_forCombinators() {
    NameFilter filter = new NameFilter.forCombinators([
      new MockUnlinkedCombinator(hides: ['foo']),
      new MockUnlinkedCombinator(hides: ['bar'])
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
    NameFilter filter =
        new NameFilter.forCombinator(new MockUnlinkedCombinator(hides: ['foo']))
            .merge(new NameFilter.forCombinator(
                new MockUnlinkedCombinator(hides: ['bar'])));
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isTrue);
    expect(filter.shownNames, isNull);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, ['foo', 'bar'].toSet());
  }

  test_merge_hides_identity() {
    NameFilter filter = new NameFilter.forCombinator(
            new MockUnlinkedCombinator(hides: ['foo', 'bar']))
        .merge(NameFilter.identity);
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isTrue);
    expect(filter.shownNames, isNull);
    expect(filter.hiddenNames, isNotNull);
    expect(filter.hiddenNames, ['foo', 'bar'].toSet());
  }

  test_merge_hides_shows() {
    NameFilter filter = new NameFilter.forCombinator(
        new MockUnlinkedCombinator(hides: ['bar', 'baz'])).merge(
        new NameFilter.forCombinator(
            new MockUnlinkedCombinator(shows: ['foo', 'bar'])));
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo'].toSet());
  }

  test_merge_identity_hides() {
    NameFilter filter = NameFilter.identity.merge(new NameFilter.forCombinator(
        new MockUnlinkedCombinator(hides: ['foo', 'bar'])));
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
    NameFilter filter = NameFilter.identity.merge(new NameFilter.forCombinator(
        new MockUnlinkedCombinator(shows: ['foo', 'bar'])));
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isTrue);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo', 'bar'].toSet());
  }

  test_merge_shows_hides() {
    NameFilter filter = new NameFilter.forCombinator(
        new MockUnlinkedCombinator(shows: ['foo', 'bar'])).merge(
        new NameFilter.forCombinator(
            new MockUnlinkedCombinator(hides: ['bar', 'baz'])));
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo'].toSet());
  }

  test_merge_shows_identity() {
    NameFilter filter = new NameFilter.forCombinator(
            new MockUnlinkedCombinator(shows: ['foo', 'bar']))
        .merge(NameFilter.identity);
    expect(filter.accepts('foo'), isTrue);
    expect(filter.accepts('bar'), isTrue);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['foo', 'bar'].toSet());
  }

  test_merge_shows_shows() {
    NameFilter filter = new NameFilter.forCombinator(
        new MockUnlinkedCombinator(shows: ['foo', 'bar'])).merge(
        new NameFilter.forCombinator(
            new MockUnlinkedCombinator(shows: ['bar', 'baz'])));
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isTrue);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, ['bar'].toSet());
  }

  test_merge_shows_shows_emptyResult() {
    NameFilter filter =
        new NameFilter.forCombinator(new MockUnlinkedCombinator(shows: ['foo']))
            .merge(new NameFilter.forCombinator(
                new MockUnlinkedCombinator(shows: ['bar'])));
    expect(filter.accepts('foo'), isFalse);
    expect(filter.accepts('bar'), isFalse);
    expect(filter.accepts('baz'), isFalse);
    expect(filter.hiddenNames, isNull);
    expect(filter.shownNames, isNotNull);
    expect(filter.shownNames, isEmpty);
  }
}
