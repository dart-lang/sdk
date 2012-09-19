// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A [List] is an indexable collection with a length. It can be of
 * fixed size or extendable.
 */
class ListImplementation<E> {
  /**
   * Factory implementation of List().
   *
   * Creates a list of the given [length].
   */
  external factory List([int length]);

  /**
   * Factory implementation of List.from().
   *
   * Creates a list with the elements of [other]. The order in
   * the list will be the order provided by the iterator of [other].
   */
  factory List.from(Iterable<E> other) {
    // TODO(ajohnsen): Make external once the vm can handle it, so we don't
    // lose generic type information.
    // Issue: #4727
    return _from(other);
  }

  external static List _from(Iterable other);
}
