// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DoubleLinkedQueueEntry<E> {
  DoubleLinkedQueueEntry<E>? _previousLink;
  DoubleLinkedQueueEntry<E>? _nextLink;

  E element;

  DoubleLinkedQueueEntry(this.element);

  void _link(
      DoubleLinkedQueueEntry<E>? previous, DoubleLinkedQueueEntry<E>? next) {
    _nextLink = next;
    _previousLink = previous;
    previous?._nextLink = this;
    next?._previousLink = this;
  }

  void prepend(E e) {
    DoubleLinkedQueueEntry<E>(e)._link(_previousLink, this);
  }
}
