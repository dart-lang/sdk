// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.observable_list;

import 'dart:async';
import 'dart:collection' show ListBase, UnmodifiableListView;
import 'package:observe/observe.dart';
import 'list_diff.dart' show projectListSplices, calcSplices;

/// Represents an observable list of model values. If any items are added,
/// removed, or replaced, then observers that are listening to [changes]
/// will be notified.
class ObservableList<E> extends ListBase<E> with ChangeNotifier {
  List<ListChangeRecord> _listRecords;

  StreamController _listChanges;

  /// The inner [List<E>] with the actual storage.
  final List<E> _list;

  /// Creates an observable list of the given [length].
  ///
  /// If no [length] argument is supplied an extendable list of
  /// length 0 is created.
  ///
  /// If a [length] argument is supplied, a fixed size list of that
  /// length is created.
  ObservableList([int length])
      : _list = length != null ? new List<E>(length) : <E>[];

  /// Creates an observable list with the elements of [other]. The order in
  /// the list will be the order provided by the iterator of [other].
  factory ObservableList.from(Iterable<E> other) =>
      new ObservableList<E>()..addAll(other);

  /// The stream of summarized list changes, delivered asynchronously.
  ///
  /// Each list change record contains information about an individual mutation.
  /// The records are projected so they can be applied sequentially. For
  /// example, this set of mutations:
  ///
  ///     var model = new ObservableList.from(['a', 'b']);
  ///     model.listChanges.listen((records) => records.forEach(print));
  ///     model.removeAt(1);
  ///     model.insertAll(0, ['c', 'd', 'e']);
  ///     model.removeRange(1, 3);
  ///     model.insert(1, 'f');
  ///
  /// The change records will be summarized so they can be "played back", using
  /// the final list positions to figure out which item was added:
  ///
  ///     #<ListChangeRecord index: 0, removed: [], addedCount: 2>
  ///     #<ListChangeRecord index: 3, removed: [b], addedCount: 0>
  ///
  /// [deliverChanges] can be called to force synchronous delivery.
  Stream<List<ListChangeRecord>> get listChanges {
    if (_listChanges == null) {
      // TODO(jmesserly): split observed/unobserved notions?
      _listChanges = new StreamController.broadcast(sync: true,
          onCancel: () { _listChanges = null; });
    }
    return _listChanges.stream;
  }

  bool get _hasListObservers =>
      _listChanges != null && _listChanges.hasListener;

  @reflectable int get length => _list.length;

  @reflectable set length(int value) {
    int len = _list.length;
    if (len == value) return;

    // Produce notifications if needed
    _notifyChangeLength(len, value);
    if (_hasListObservers) {
      if (value < len) {
        _recordChange(new ListChangeRecord(this, value,
            removed: _list.getRange(value, len).toList()));
      } else {
        _recordChange(new ListChangeRecord(this, len, addedCount: value - len));
      }
    }

    _list.length = value;
  }

  @reflectable E operator [](int index) => _list[index];

  @reflectable void operator []=(int index, E value) {
    var oldValue = _list[index];
    if (_hasListObservers) {
      _recordChange(new ListChangeRecord(this, index, addedCount: 1,
          removed: [oldValue]));
    }
    _list[index] = value;
  }

  // Forwarders so we can reflect on the properties.
  @reflectable bool get isEmpty => super.isEmpty;
  @reflectable bool get isNotEmpty => super.isNotEmpty;

  // TODO(jmesserly): should we support first/last/single? They're kind of
  // dangerous to use in a path because they throw exceptions. Also we'd need
  // to produce property change notifications which seems to conflict with our
  // existing list notifications.

  // The following methods are here so that we can provide nice change events.

  void setAll(int index, Iterable<E> iterable) {
    if (iterable is! List && iterable is! Set) {
      iterable = iterable.toList();
    }
    var len = iterable.length;
    if (_hasListObservers && len > 0) {
      _recordChange(new ListChangeRecord(this, index, addedCount: len,
          removed: _list.getRange(index, len).toList()));
    }
    _list.setAll(index, iterable);
  }

  void add(E value) {
    int len = _list.length;
    _notifyChangeLength(len, len + 1);
    if (_hasListObservers) {
      _recordChange(new ListChangeRecord(this, len, addedCount: 1));
    }

    _list.add(value);
  }

  void addAll(Iterable<E> iterable) {
    int len = _list.length;
    _list.addAll(iterable);

    _notifyChangeLength(len, _list.length);

    int added = _list.length - len;
    if (_hasListObservers && added > 0) {
      _recordChange(new ListChangeRecord(this, len, addedCount: added));
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
    int rangeLength = end - start;
    int len = _list.length;

    _notifyChangeLength(len, len - rangeLength);
    if (_hasListObservers && rangeLength > 0) {
      _recordChange(new ListChangeRecord(this, start,
          removed: _list.getRange(start, end).toList()));
    }

    _list.removeRange(start, end);
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

    _notifyChangeLength(len, _list.length);

    if (_hasListObservers && insertionLength > 0) {
      _recordChange(new ListChangeRecord(this, index,
          addedCount: insertionLength));
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

    _notifyChangeLength(_list.length - 1, _list.length);
    if (_hasListObservers) {
      _recordChange(new ListChangeRecord(this, index, addedCount: 1));
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
    if (!_hasListObservers) return;

    if (_listRecords == null) {
      _listRecords = [];
      scheduleMicrotask(deliverListChanges);
    }
    _listRecords.add(record);
  }

  void _notifyChangeLength(int oldValue, int newValue) {
    notifyPropertyChange(#length, oldValue, newValue);
    notifyPropertyChange(#isEmpty, oldValue == 0, newValue == 0);
    notifyPropertyChange(#isNotEmpty, oldValue != 0, newValue != 0);
  }

  /// Deprecated. Name had a typo, use [discardListChanges] instead.
  @deprecated
  void discardListChages() => discardListChanges();

  void discardListChanges() {
    // Leave _listRecords set so we don't schedule another delivery.
    if (_listRecords != null) _listRecords = [];
  }

  bool deliverListChanges() {
    if (_listRecords == null) return false;
    var records = projectListSplices(this, _listRecords);
    _listRecords = null;

    if (_hasListObservers && !records.isEmpty) {
      _listChanges.add(new UnmodifiableListView<ListChangeRecord>(records));
      return true;
    }
    return false;
  }

  /// Calculates the changes to the list, if lacking individual splice mutation
  /// information.
  ///
  /// This is not needed for change records produced by [ObservableList] itself,
  /// but it can be used if the list instance was replaced by another list.
  ///
  /// The minimal set of splices can be synthesized given the previous state and
  /// final state of a list. The basic approach is to calculate the edit
  /// distance matrix and choose the shortest path through it.
  ///
  /// Complexity is `O(l * p)` where `l` is the length of the current list and
  /// `p` is the length of the old list.
  static List<ListChangeRecord> calculateChangeRecords(
      List<Object> oldValue, List<Object> newValue) =>
      calcSplices(newValue, 0, newValue.length, oldValue, 0, oldValue.length);

  /// Updates the [previous] list using the change [records]. For added items,
  /// the [current] list is used to find the current value.
  static void applyChangeRecords(List<Object> previous, List<Object> current,
      List<ListChangeRecord> changeRecords) {

    if (identical(previous, current)) {
      throw new ArgumentError("can't use same list for previous and current");
    }

    for (var change in changeRecords) {
      int addEnd = change.index + change.addedCount;
      int removeEnd = change.index + change.removed.length;

      var addedItems = current.getRange(change.index, addEnd);
      previous.replaceRange(change.index, removeEnd, addedItems);
    }
  }
}
