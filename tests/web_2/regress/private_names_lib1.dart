// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'private_names_lib2.dart';

export 'private_names_lib2.dart' show DoubleLinkedQueueEntry;

abstract class _DoubleLinkedQueueEntry<E> {
  _DoubleLinkedQueueEntry<E>? _previousLink;
  _DoubleLinkedQueueEntry<E>? _nextLink;

  void _link(
      _DoubleLinkedQueueEntry<E>? previous, _DoubleLinkedQueueEntry<E>? next) {
    _nextLink = next;
    _previousLink = previous;
    previous?._nextLink = this;
    next?._previousLink = this;
  }

  _DoubleLinkedQueueElement<E>? _asNonSentinelEntry();

  void _prepend(E element, DoubleLinkedQueue<E>? queue) {
    _DoubleLinkedQueueElement<E>(element, queue)._link(_previousLink, this);
  }
}

class _DoubleLinkedQueueElement<E> extends _DoubleLinkedQueueEntry<E>
    implements DoubleLinkedQueueEntry<E> {
  DoubleLinkedQueue<E>? _queue;
  E element;

  _DoubleLinkedQueueElement(this.element, this._queue);

  void prepend(E e) {
    _prepend(e, _queue);
    _queue?._elementCount++;
  }

  _DoubleLinkedQueueElement<E> _asNonSentinelEntry() => this;
}

class _DoubleLinkedQueueSentinel<E> extends _DoubleLinkedQueueEntry<E> {
  _DoubleLinkedQueueSentinel() {
    _previousLink = this;
    _nextLink = this;
  }

  Null _asNonSentinelEntry() => null;
}

class DoubleLinkedQueue<E> /*extends Iterable<E> implements Queue<E>*/ {
  final _DoubleLinkedQueueSentinel<E> _sentinel =
      _DoubleLinkedQueueSentinel<E>();

  int _elementCount = 0;

  DoubleLinkedQueue();

  factory DoubleLinkedQueue.from(Iterable<dynamic> elements) {
    DoubleLinkedQueue<E> list = DoubleLinkedQueue<E>();
    for (final e in elements) {
      list.addLast(e as E);
    }
    return list;
  }

  void addLast(E value) {
    _sentinel._prepend(value, this);
    _elementCount++;
  }

  DoubleLinkedQueueEntry<E>? firstEntry() =>
      _sentinel._nextLink!._asNonSentinelEntry();
}
