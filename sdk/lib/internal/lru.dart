// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

class LRUAssociation<K,V> {
  K key;
  V value;
  LRUAssociation previous;
  LRUAssociation next;

  void insertBetween(before, after) {
    after.previous = this;
    before.next = this;
    this.next = after;
    this.previous = before;
  }

  void remove() {
    var after = next;
    var before = previous;
    after.previous = before;
    before.next = after;
  }
}

/**
 * A map with a fixed capacity that evicts associations when capacity is reached
 * on a least-recently-used basis. Implemented as an open addressing hash table
 * with doubly-linked entries forming the LRU queue.
 */
class LRUMap<K,V> {
  final LRUAssociation<K,V> _head;
  final List _table;
  final int _mask;
  final int _capacity;  // Max number of associations before we start evicting.
  int _size = 0;  // Current number of associations.

  /**
   * Create an LRUMap whose capacity is 75% of 2^shift.
   */
  LRUMap.withShift(int shift)
      : this._mask = (1 << shift) - 1
      , this._capacity = (1 << shift) * 3 ~/ 4
      , this._table = new List(1 << shift)
      , this._head = new LRUAssociation() {
    // The scheme used here for handling collisions relies on there always
    // being at least one empty slot.
    if (shift < 1) throw new Exception("LRUMap requires a shift >= 1");
    assert(_table.length > _capacity);
    _head.insertBetween(_head, _head);
  }

  int _scanFor(K key) {
    var start = key.hashCode & _mask;
    var index = start;
    do {
      var assoc = _table[index];
      if (null == assoc || assoc.key == key) {
        return index;
      }
      index = (index + 1) & _mask;
    } while (index != start);
    // Should never happen because we start evicting associations before the
    // table is full.
    throw new Exception("Internal error: LRUMap table full");
  }

  void _fixCollisionsAfter(start) {
    var assoc;
    var index = (start + 1) & _mask;
    while (null != (assoc = _table[index])) {
      var newIndex = _scanFor(assoc.key);
      if (newIndex != index) {
        assert(_table[newIndex] == null);
        _table[newIndex] = assoc;
        _table[index] = null;
      }
      index = (index + 1) & _mask;
    }
  }

  operator []=(K key, V value) {
    int index = _scanFor(key);
    var assoc = _table[index];
    if (null != assoc) {
      // Existing key, replace value.
      assert(assoc.key == key);
      assoc.value = value;
      assoc.remove();
      assoc.insertBetween(_head, _head.next);
    } else {
      // New key.
      var newAssoc;
      if (_size == _capacity) {
        // Knock out the oldest association.
        var lru = _head.previous;
        lru.remove();
        index = _scanFor(lru.key);
        _table[index] = null;
        _fixCollisionsAfter(index);
        index = _scanFor(key);
        newAssoc = lru;  // Recycle the association.
      } else {
        newAssoc = new LRUAssociation();
        _size++;
      }
      newAssoc.key = key;
      newAssoc.value = value;
      newAssoc.insertBetween(_head, _head.next);
      _table[index] = newAssoc;
    }
  }

  V operator [](K key) {
    var index = _scanFor(key);
    var assoc = _table[index];
    if (null == assoc) return null;
    // Move to front of LRU queue.
    assoc.remove();
    assoc.insertBetween(_head, _head.next);
    return assoc.value;
  }
}
