// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This iterator should be [close]d after use.
///
/// [ClosableIterator]s often use resources which should be freed after use.
/// The consumer of the iterator can either manually [close] the iterator, or
/// consume all elements on which the iterator will automatically be closed.
abstract class ClosableIterator<T> extends Iterator<T> {
  /// Close this iterator.
  void close();

  /// Moves to the next element and [close]s the iterator if it was the last
  /// element.
  bool moveNext();
}

/// This iterable's iterator should be [close]d after use.
///
/// Companion class of [ClosableIterator].
abstract class ClosableIterable<T> extends Iterable<T> {
  /// Close this iterables iterator.
  void close();

  /// Returns a [ClosableIterator] that allows iterating the elements of this
  /// [ClosableIterable].
  ClosableIterator<T> get iterator;
}
