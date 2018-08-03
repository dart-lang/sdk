// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A pair of values.
 */
class Pair<E, F> {
  final E first;
  final F last;

  Pair(this.first, this.last);

  @override
  int get hashCode => first.hashCode ^ last.hashCode;

  @override
  bool operator ==(other) {
    if (other is! Pair) {
      return false;
    }
    return other.first == first && other.last == last;
  }

  @override
  String toString() => '($first, $last)';
}
