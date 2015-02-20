// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;


/**
 * A specialized double-linked list of elements that extends [LinkedListEntry].
 *
 * This is not a generic data structure. It only accepts elements that extend
 * the [LinkedListEntry] class. See the [Queue] implementations for
 * generic collections that allow constant time adding and removing at the ends.
 *
 * This is not a [List] implementation. Despite its name, this class does not
 * implement the [List] interface. It does not allow constant time lookup by
 * index.
 *
 * Because the elements themselves contain the links of this linked list,
 * each element can be in only one list at a time. To add an element to another
 * list, it must first be removed from its current list (if any).
 *
 * In return, each element knows its own place in the linked list, as well as
 * which list it is in. This allows constant time [LinkedListEntry.addAfter],
 * [LinkedListEntry.addBefore] and [LinkedListEntry.unlink] operations
 * when all you have is the element.
 *
 * A `LinkedList` also allows constant time adding and removing at either end,
 * and a constant time length getter.
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
   * Add [entry] to the beginning of the linked list.
   */
  void addFirst(E entry) {
    _insertAfter(this, entry);
  }

  /**
   * Add [entry] to the end of the linked list.
   */
  void add(E entry) {
    _insertAfter(_previous, entry);
  }

  /**
   * Add [entries] to the end of the linked list.
   */
  void addAll(Iterable<E> entries) {
    entries.forEach((entry) => _insertAfter(_previous, entry));
  }

  /**
   * Remove [entry] from the linked list.
   *
   * Returns false and does nothing if [entry] is not in this linked list.
   *
   * This is equivalent to calling `entry.unlink()` if the entry is in this
   * list.
   */
  bool remove(E entry) {
    if (entry._list != this) return false;
    _unlink(entry);  // Unlink will decrement length.
    return true;
  }

  Iterator<E> get iterator => new _LinkedListIterator<E>(this);

  int get length => _length;

  /**
   * Remove all elements from this linked list.
   */
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
   * Call [action] with each entry in this linked list.
   *
   * It's an error if [action] modify the linked list.
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
 * An object that can be an element in a [LinkedList].
 *
 * All elements of a `LinkedList` must extend this class.
 * The class provides the internal links that link elements together
 * in the `LinkedList`, and a reference to the linked list itself
 * that an element is currently part of.
 *
 * An entry can be in at most one linked list at a time.
 * While an entry is in a linked list, the [list] property points to that
 * linked list, and otherwise the `list` property is `null`.
 *
 * When created, an entry is not in any linked list.
 */
abstract class LinkedListEntry<E extends LinkedListEntry<E>>
    implements _LinkedListLink {
  LinkedList<E> _list;
  _LinkedListLink _next;
  _LinkedListLink _previous;

  /**
   * Get the linked list containing this element.
   *
   * Returns `null` if this entry is not currently in any list.
   */
  LinkedList<E> get list => _list;

  /**
   * Unlink the element from its linked list.
   *
   * The entry must currently be in a linked list when this method is called.
   */
  void unlink() {
    _list._unlink(this);
  }

  /**
   * Return the succeessor of this element in its linked list.
   *
   * Returns `null` if there is no successor in the linked list, or if this
   * entry is not currently in any list.
   */
  E get next {
    if (identical(_next, _list)) return null;
    E result = _next;
    return result;
  }

  /**
   * Return the predecessor of this element in its linked list.
   *
   * Returns `null` if there is no predecessor in the linked list, or if this
   * entry is not currently in any list.
   */
  E get previous {
    if (identical(_previous, _list)) return null;
    return _previous as E;
  }

  /**
   * Insert an element after this element in this element's linked list.
   *
   * This entry must be in a linked list when this method is called.
   * The [entry] must not be in a linked list.
   */
  void insertAfter(E entry) {
    _list._insertAfter(this, entry);
  }

  /**
   * Insert an element before this element in this element's linked list.
   *
   * This entry must be in a linked list when this method is called.
   * The [entry] must not be in a linked list.
   */
  void insertBefore(E entry) {
    _list._insertAfter(_previous, entry);
  }
}
