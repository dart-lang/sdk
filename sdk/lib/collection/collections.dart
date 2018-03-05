// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * An unmodifiable [List] view of another List.
 *
 * The source of the elements may be a [List] or any [Iterable] with
 * efficient [Iterable.length] and [Iterable.elementAt].
 */
class UnmodifiableListView<E> extends UnmodifiableListBase<E> {
  final Iterable<E> _source;

  /**
   * Creates an unmodifiable list backed by [source].
   *
   * The [source] of the elements may be a [List] or any [Iterable] with
   * efficient [Iterable.length] and [Iterable.elementAt].
   */
  UnmodifiableListView(Iterable<E> source) : _source = source;

  List<R> cast<R>() {
    List<Object> self = this;
    if (self is List<R>) return self;
    return new UnmodifiableListView<R>(_source.cast<R>());
  }

  List<R> retype<R>() => new UnmodifiableListView(_source.retype<R>());

  int get length => _source.length;

  E operator [](int index) => _source.elementAt(index);
}
