// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.utils;

import 'package:collection/collection.dart';

/// Returns a hash code for [obj] such that structurally equivalent objects
/// will have the same hash code.
///
/// This supports deep equality for maps and lists, including those with
/// self-referential structures.
int hashCodeFor(obj) {
  var parents = [];

  _hashCodeFor(value) {
    if (parents.any((parent) => identical(parent, value))) return -1;

    parents.add(value);
    try {
      if (value is Map) {
        var equality = const UnorderedIterableEquality();
        return equality.hash(value.keys.map(_hashCodeFor)) ^
            equality.hash(value.values.map(_hashCodeFor));
      } else if (value is Iterable) {
        return const IterableEquality().hash(value.map(hashCodeFor));
      }
      return value.hashCode;
    } finally {
      parents.removeLast();
    }
  }

  return _hashCodeFor(obj);
}
