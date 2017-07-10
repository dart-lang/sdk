// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

/// A rudimentary linked list.
class LinkedList<T extends LinkedListEntry<T>> extends IterableBase<T> {
  T first;
  T last;
  int length = 0;

  bool get isEmpty => length == 0;

  /**
   * Adds [newLast] to the end of this linked list.
   */
  void add(T newLast) {
    assert(newLast._next == null && newLast._previous == null);
    if (last != null) {
      assert(last._next == null);
      last._next = newLast;
    } else {
      first = newLast;
    }
    newLast._previous = last;
    last = newLast;
    last._list = this;
    length++;
  }

  /**
   * Adds [newFirst] to the beginning of this linked list.
   */
  void addFirst(T newFirst) {
    if (first != null) {
      assert(first._previous == null);
      first._previous = newFirst;
    } else {
      last = newFirst;
    }
    newFirst._next = first;
    first = newFirst;
    first._list = this;
    length++;
  }

  /**
   * Removes the given [node] from this list.
   *
   * The entry must be in this linked list when this method is called. Also see
   * [LinkedListEntry.unlink].
   */
  void remove(T node) {
    assert(node._previous != null || node._next != null || length == 1);
    length--;
    if (node._previous == null) {
      assert(identical(node, first));
      first = node._next;
    } else {
      node._previous._next = node._next;
    }
    if (node._next == null) {
      assert(identical(node, last));
      last = node._previous;
    } else {
      node._next._previous = node._previous;
    }
    node._next = node._previous = null;
  }

  Iterator<T> get iterator => new _LinkedListIterator<T>(this);
}

class LinkedListEntry<T extends LinkedListEntry<T>> {
  T _next;
  T _previous;
  LinkedList<T> _list;

  /**
   * Unlinks the element from its linked list.
   *
   * The entry must be in a linked list when this method is called.
   * This is equivalent to calling [LinkedList.remove] on the list this entry
   * is currently in.
   */
  void unlink() {
    _list.remove(this);
  }
}

class _LinkedListIterator<T extends LinkedListEntry<T>> implements Iterator<T> {
  /// The current element of the iterator.
  // This field is writeable, but should only read by users of this class.
  T current;

  /// The list the iterator iterates over.
  ///
  /// Set to [null] if the provided list was empty (indicating that there were
  /// no entries to iterate over).
  ///
  /// Set to [null] as soon as [moveNext] was invoked (indicating that the
  /// iterator has to work with [current] from now on.
  LinkedList<T> _list;

  _LinkedListIterator(this._list) {
    if (_list.length == 0) _list = null;
  }

  bool moveNext() {
    // current is null if the iterator hasn't started iterating, or if the
    // iteration is finished. In the first case, the [_list] field is not null.
    if (current == null) {
      if (_list == null) return false;
      assert(_list.length > 0);
      current = _list.first;
      _list = null;
      return true;
    }
    current = current._next;
    return current != null;
  }
}
