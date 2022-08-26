// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

/// Matches a [MapEntry] with matching [MapEntry.key] and [MapEntry.value].
MapEntryMatcher isMapEntry(key, value) => MapEntryMatcher(key, value);

class MapEntryMatcher extends Matcher {
  final Matcher keyMatcher;
  final Matcher valueMatcher;

  MapEntryMatcher(key, value)
      : keyMatcher = wrapMatcher(key),
        valueMatcher = wrapMatcher(value);

  @override
  Description describe(Description description) => description
      .add('MapEntry(key: ')
      .addDescriptionOf(keyMatcher)
      .add(', value: ')
      .addDescriptionOf(valueMatcher)
      .add(')');

  @override
  bool matches(item, Map matchState) =>
      item is MapEntry &&
      keyMatcher.matches(item.key, {}) &&
      valueMatcher.matches(item.value, {});
}
