// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;


/**
 * A linked list implementation, providing O(1) removal(unlink) of elements and
 * manual traversal through [next] and [previous].
 *
 * The list elements must extend [LinkedListEntry].
 */
class LinkedList<E extends LinkedListEntry<E>>
    extends IterableBase<E>
    implements _LinkedListLink {

  int _modificationCount = 0;
  int _length = 0;
  _LinkedListLink _next;
  _LinkedListLink _previous;

  /**
   * Construct a new empty linked list.
   */
  LinkedList() {
    _next = _previous = this;
  }

  /**
   * Add [entry] to the beginning of the list.
   */
  void addFirst(E entry) {
    _insertAfter(this, entry);
  }

  /**
   * Add [entry] to the end of the list.
   */
  void add(E entry) {
    _insertAfter(_previous, entry);
  }

  /**
   * Add [entries] to the end of the list.
   */
  void addAll(Iterable<E> entries) {
    entries.forEach((entry) => _insertAfter(_previous, entry));
  }

  /**
   * Remove [entry] from the list. This is the same as calling `entry.unlink()`.
   *
   * If [entry] is not in the list, `false` is returned.
   */
  bool remove(E entry) {
    if (entry._list != this) return false;
    _unlink(entry);  // Unlink will decrement length.
    return true;
  }

  Iterator<E> get iterator => new _LinkedListIterator<E>(this);

  // TODO(zarah) Remove this, and let it be inherited by IterableMixin
  String toString() => IterableMixinWorkaround.toStringIterable(this, '{', '}');

  int get length => _length;

  void clear() {
    _modificationCount++;
    _LinkedListLink next = _next;
    while (!identical(next, this)) {
      E entry = next;
      next = entry._next;
      entry._next = entry._previous = entry._list = null;
    }
    _next = _previous = this;
    _length = 0;
  }

  E get first {
    if (identical(_next, this)) {
      throw new StateError('No such element');
    }
    return _next;
  }

  E get last {
    if (identical(_previous, this)) {
      throw new StateError('No such element');
    }
    return _previous;
  }

  E get single {
    if (identical(_previous, this)) {
      throw new StateError('No such element');
    }
    if (!identical(_previous, _next)) {
      throw new StateError('Too many elements');
    }
    return _next;
  }

  /**
   * Call [action] with each entry in the list.
   *
   * It's an error if [action] modify the list.
   */
  void forEach(void action(E entry)) {
    int modificationCount = _modificationCount;
    _LinkedListLink current = _next;
    while (!identical(current, this)) {
      action(current);
      if (modificationCount != _modificationCount) {
        throw new ConcurrentModificationError(this);
      }
      current = current._next;
    }
  }

  bool get isEmpty => _length == 0;

  void _insertAfter(_LinkedListLink entry, E newEntry) {
    if (newEntry.list != null) {
      throw new StateError(
          'LinkedListEntry is already in a LinkedList');
    }
    _modificationCount++;
    newEntry._list = this;
    var predecessor = entry;
    var successor = entry._next;
    successor._previous = newEntry;
    newEntry._previous = predecessor;
    newEntry._next = successor;
    predecessor._next = newEntry;
    _length++;
  }

  void _unlink(LinkedListEntry<E> entry) {
    _modificationCount++;
    entry._next._previous = entry._previous;
    entry._previous._next = entry._next;
    _length--;
    entry._list = entry._next = entry._previous = null;
  }
}


class _LinkedListIterator<E extends LinkedListEntry<E>>
    implements Iterator<E> {
  final LinkedList<E> _list;
  final int _modificationCount;
  E _current;
  _LinkedListLink _next;

  _LinkedListIterator(LinkedList<E> list)
    : _list = list,
      _modificationCount = list._modificationCount,
      _next = list._next;

  E get current => _current;

  bool moveNext() {
    if (identical(_next, _list)) {
      _current = null;
      return false;
    }
    if (_modificationCount != _list._modificationCount) {
      throw new ConcurrentModificationError(this);
    }
    _current = _next;
    _next = _next._next;
    return true;
  }
}


class _LinkedListLink {
  _LinkedListLink _next;
  _LinkedListLink _previous;
}


/**
 * Entry element for a [LinkedList]. Any entry must extend this class.
 */
abstract class LinkedListEntry<E extends LinkedListEntry<E>>
    implements _LinkedListLink {
  LinkedList<E> _list;
  _LinkedListLink _next;
  _LinkedListLink _previous;

  /**
   * Get the list containing this element.
   */
  LinkedList<E> get list => _list;

  /**
   * Unlink the element from the list.
   */
  void unlink() {
    _list._unlink(this);
  }

  /**
   * Return the succeeding element in the list.
   */
  E get next {
    if (identical(_next, _list)) return null;
    return _next as E;
  }

  /**
   * Return the preceeding element in the list.
   */
  E get previous {
    if (identical(_previous, _list)) return null;
    return _previous as E;
  }

  /**
   * insert an element after this.
   */
  void insertAfter(E entry) {
    _list._insertAfter(this, entry);
  }

  /**
   * Insert an element before this.
   */
  void insertBefore(E entry) {
    _list._insertAfter(_previous, entry);
  }
}
