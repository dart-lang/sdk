// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observe;

/**
 * Represents an observable list of model values. If any items are added,
 * removed, or replaced, then observers that are listening to [changes]
 * will be notified.
 */
class ObservableList<E> extends ListBase<E> with ChangeNotifier {
  List<ListChangeRecord> _listRecords;

  /** The inner [List<E>] with the actual storage. */
  final List<E> _list;

  /**
   * Creates an observable list of the given [length].
   *
   * If no [length] argument is supplied an extendable list of
   * length 0 is created.
   *
   * If a [length] argument is supplied, a fixed size list of that
   * length is created.
   */
  ObservableList([int length])
      : _list = length != null ? new List<E>(length) : <E>[];

  /**
   * Creates an observable list with the elements of [other]. The order in
   * the list will be the order provided by the iterator of [other].
   */
  factory ObservableList.from(Iterable<E> other) =>
      new ObservableList<E>()..addAll(other);

  @reflectable int get length => _list.length;

  @reflectable set length(int value) {
    int len = _list.length;
    if (len == value) return;

    // Produce notifications if needed
    if (hasObservers) {
      if (value < len) {
        // Remove items, then adjust length. Note the reverse order.
        _recordChange(new ListChangeRecord(value, removedCount: len - value));
      } else {
        // Adjust length then add items
        _recordChange(new ListChangeRecord(len, addedCount: value - len));
      }
    }

    _list.length = value;
  }

  @reflectable E operator [](int index) => _list[index];

  @reflectable void operator []=(int index, E value) {
    var oldValue = _list[index];
    if (hasObservers) {
      _recordChange(new ListChangeRecord(index, addedCount: 1,
                                                removedCount: 1));
    }
    _list[index] = value;
  }

  // The following methods are here so that we can provide nice change events.

  void setAll(int index, Iterable<E> iterable) {
    if (iterable is! List && iterable is! Set) {
      iterable = iterable.toList();
    }
    var len = iterable.length;
    _list.setAll(index, iterable);
    if (hasObservers && len > 0) {
      _recordChange(
          new ListChangeRecord(index, addedCount: len, removedCount: len));
    }
  }

  void add(E value) {
    int len = _list.length;
    if (hasObservers) {
      _recordChange(new ListChangeRecord(len, addedCount: 1));
    }

    _list.add(value);
  }

  void addAll(Iterable<E> iterable) {
    int len = _list.length;
    _list.addAll(iterable);
    int added = _list.length - len;
    if (hasObservers && added > 0) {
      _recordChange(new ListChangeRecord(len, addedCount: added));
    }
  }

  bool remove(Object element) {
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        removeRange(i, i + 1);
        return true;
      }
    }
    return false;
  }

  void removeRange(int start, int end) {
    _rangeCheck(start, end);
    int length = end - start;
    _list.setRange(start, this.length - length, this, end);

    int len = _list.length;
    _list.length -= length;
    if (hasObservers && length > 0) {
      _recordChange(new ListChangeRecord(start, removedCount: length));
    }
  }

  void insertAll(int index, Iterable<E> iterable) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    // TODO(floitsch): we can probably detect more cases.
    if (iterable is! List && iterable is! Set) {
      iterable = iterable.toList();
    }
    int insertionLength = iterable.length;
    // There might be errors after the length change, in which case the list
    // will end up being modified but the operation not complete. Unless we
    // always go through a "toList" we can't really avoid that.
    int len = _list.length;
    _list.length += insertionLength;

    _list.setRange(index + insertionLength, this.length, this, index);
    _list.setAll(index, iterable);

    if (hasObservers && insertionLength > 0) {
      _recordChange(new ListChangeRecord(index, addedCount: insertionLength));
    }
  }

  void insert(int index, E element) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    if (index == length) {
      add(element);
      return;
    }
    // We are modifying the length just below the is-check. Without the check
    // Array.copy could throw an exception, leaving the list in a bad state
    // (with a length that has been increased, but without a new element).
    if (index is! int) throw new ArgumentError(index);
    _list.length++;
    _list.setRange(index + 1, length, this, index);
    if (hasObservers) {
      _recordChange(new ListChangeRecord(index, addedCount: 1));
    }
    _list[index] = element;
  }


  E removeAt(int index) {
    E result = this[index];
    removeRange(index, index + 1);
    return result;
  }

  void _rangeCheck(int start, int end) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (end < start || end > this.length) {
      throw new RangeError.range(end, start, this.length);
    }
  }

  void _recordChange(ListChangeRecord record) {
    if (_listRecords == null) {
      _listRecords = [];
      scheduleMicrotask(deliverChanges);
    }
    _listRecords.add(record);
  }

  bool deliverChanges() {
    if (_listRecords == null) return false;
    _summarizeRecords();
    return super.deliverChanges();
  }

  /**
   * We need to summarize change records. Consumers of these records want to
   * apply the batch sequentially, and ensure that they can find inserted
   * items by looking at that position in the list. This property does not
   * hold in our record-as-you-go records. Consider:
   *
   *     var model = toObservable(['a', 'b']);
   *     model.removeAt(1);
   *     model.insertAll(0, ['c', 'd', 'e']);
   *     model.removeRange(1, 3);
   *     model.insert(1, 'f');
   *
   * Here, we inserted some records and then removed some of them.
   * If someone processed these records naively, they would "play back" the
   * insert incorrectly, because those items will be shifted.
   *
   * We summarize changes using a straightforward technique:
   * Simulate the moves and use the final item positions to synthesize a
   * new list of changes records. This has the advantage of not depending
   * on the actual *values*, so we don't need to perform N^2 edit
   */
  // TODO(jmesserly): there's probably something smarter here, but this
  // algorithm is pretty simple. It has complexity equivalent to the original
  // list modifications.
  // One simple idea: we can simply update the index map as we do the operations
  // to the list, then produce the records at the end.
  void _summarizeRecords() {
    int oldLength = length;
    for (var r in _listRecords) {
      oldLength += r.removedCount - r.addedCount;
    }

    if (length != oldLength) {
      notifyPropertyChange(#length, oldLength, length);
    }

    if (_listRecords.length == 1) {
      notifyChange(_listRecords[0]);
      _listRecords = null;
      return;
    }

    var items = [];
    for (int i = 0; i < oldLength; i++) items.add(i);
    for (var r in _listRecords) {
      items.removeRange(r.index, r.index + r.removedCount);

      // Represent inserts with -1.
      items.insertAll(r.index, new List.filled(r.addedCount, -1));
    }
    assert(items.length == length);

    _listRecords = null;

    int index = 0;
    int offset = 0;
    while (index < items.length) {
      // Skip unchanged items.
      while (index < items.length && items[index] == index + offset) {
        index++;
      }

      // Find inserts
      int startIndex = index;
      while (index < items.length && items[index] == -1) {
        index++;
      }

      int added = index - startIndex;

      // Use the delta between our actual and expected position to determine
      // how much was removed.
      int actualItem = index < items.length ? items[index] : oldLength;
      int expectedItem = startIndex + offset;

      int removed = actualItem - expectedItem;

      if (added > 0 || removed > 0) {
        notifyChange(new ListChangeRecord(startIndex, addedCount: added,
            removedCount: removed));
      }

      offset += removed - added;
    }
  }
}
