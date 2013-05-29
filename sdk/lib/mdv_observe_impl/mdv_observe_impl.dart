// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library itself is undocumented and not supported for end use.
// Because dart:html must use some of this functionality, it has to be available
// via a dart:* library. The public APIs are reexported via package:mdv_observe.
// Generally we try to keep this library minimal, with utility types and
// functions in the package.
library dart.mdv_observe_impl;

import 'dart:async';
import 'dart:collection';

/**
 * Interface representing an observable object. This is used by data in
 * model-view architectures to notify interested parties of [changes].
 *
 * This object does not require any specific technique to implement
 * observability.
 *
 * You can use [ObservableMixin] as a base class or mixin to implement this.
 */
abstract class Observable {
  /**
   * The stream of change records to this object.
   *
   * Changes should be delivered in asynchronous batches by calling
   * [queueChangeRecords].
   *
   * [deliverChangeRecords] can be called to force delivery.
   */
  Stream<List<ChangeRecord>> get changes;

  // TODO(jmesserly): remove these ASAP.
  /**
   * *Warning*: this method is temporary until dart2js supports mirrors.
   * Gets the value of a field or index. This should return null if it was
   * not found.
   */
  getValueWorkaround(key);

  /**
   * *Warning*: this method is temporary until dart2js supports mirrors.
   * Sets the value of a field or index. This should have no effect if the field
   * was not found.
   */
  void setValueWorkaround(key, Object value);
}

/**
 * Base class implementing [Observable].
 *
 * When a field, property, or indexable item is changed, a derived class should
 * call [notifyPropertyChange]. See that method for an example.
 */
typedef ObservableBase = Object with ObservableMixin;

/**
 * Mixin for implementing [Observable] objects.
 *
 * When a field, property, or indexable item is changed, a derived class should
 * call [notifyPropertyChange]. See that method for an example.
 */
abstract class ObservableMixin implements Observable {
  StreamController _multiplexController;
  List<ChangeRecord> _changes;

  Stream<List<ChangeRecord>> get changes {
    if (_multiplexController == null) {
      _multiplexController =
          new StreamController<List<ChangeRecord>>.broadcast();
    }
    return _multiplexController.stream;
  }

  void _deliverChanges() {
    var changes = _changes;
    _changes = null;
    if (hasObservers && changes != null) {
      // TODO(jmesserly): make "changes" immutable
      _multiplexController.add(changes);
    }
  }

  /**
   * True if this object has any observers, and should call
   * [notifyPropertyChange] for changes.
   */
  bool get hasObservers => _multiplexController != null &&
                           _multiplexController.hasListener;

  /**
   * Notify that the field [name] of this object has been changed.
   *
   * The [oldValue] and [newValue] are also recorded. If the two values are
   * identical, no change will be recorded.
   *
   * For convenience this returns [newValue]. This makes it easy to use in a
   * setter:
   *
   *     var _myField;
   *     get myField => _myField;
   *     set myField(value) {
   *       _myField = notifyPropertyChange(
   *           const Symbol('myField'), _myField, value);
   *     }
   */
  // TODO(jmesserly): should this be == instead of identical, to prevent
  // spurious loops?
  notifyPropertyChange(Symbol field, Object oldValue, Object newValue) {
    if (hasObservers && !identical(oldValue, newValue)) {
      notifyChange(new PropertyChangeRecord(field));
    }
    return newValue;
  }

  /**
   * Notify observers of a change. For most objects [notifyPropertyChange] is
   * more convenient, but collections sometimes deliver other types of changes
   * such as a [ListChangeRecord].
   */
  void notifyChange(ChangeRecord record) {
    if (!hasObservers) return;

    if (_changes == null) {
      _changes = [];
      queueChangeRecords(_deliverChanges);
    }
    _changes.add(record);
  }
}


/** Records a change to an [Observable]. */
abstract class ChangeRecord {
  /** True if the change affected the given item, otherwise false. */
  bool change(key);
}

/** A change record to a field of an observable object. */
class PropertyChangeRecord extends ChangeRecord {
  /** The field that was changed. */
  final Symbol field;

  PropertyChangeRecord(this.field);

  bool changes(key) => key is Symbol && field == key;

  String toString() => '#<PropertyChangeRecord $field>';
}

/** A change record for an observable list. */
class ListChangeRecord extends ChangeRecord {
  /** The starting index of the change. */
  final int index;

  /** The number of items removed. */
  final int removedCount;

  /** The number of items added. */
  final int addedCount;

  ListChangeRecord(this.index, {this.removedCount: 0, this.addedCount: 0}) {
    if (addedCount == 0 && removedCount == 0) {
      throw new ArgumentError('added and removed counts should not both be '
          'zero. Use 1 if this was a single item update.');
    }
  }

  /** Returns true if the provided index was changed by this operation. */
  bool changes(key) {
    // If key isn't an int, or before the index, then it wasn't changed.
    if (key is! int || key < index) return false;

    // If this was a shift operation, anything after index is changed.
    if (addedCount != removedCount) return true;

    // Otherwise, anything in the update range was changed.
    return key < index + addedCount;
  }

  String toString() => '#<ListChangeRecord index: $index, '
      'removed: $removedCount, addedCount: $addedCount>';
}

/**
 * Synchronously deliver [Observable.changes] for all observables.
 * If new changes are added as a result of delivery, this will keep running
 * until all pending change records are delivered.
 */
// TODO(jmesserly): this is a bit different from the ES Harmony version, which
// allows delivery of changes to a particular observer:
// http://wiki.ecmascript.org/doku.php?id=harmony:observe#object.deliverchangerecords
// However the binding system needs delivery of everything, along the lines of:
// https://github.com/toolkitchen/mdv/blob/stable/src/model.js#L19
// https://github.com/rafaelw/ChangeSummary/blob/master/change_summary.js#L590
// TODO(jmesserly): in the future, we can use this to trigger dirty checking.
void deliverChangeRecords() {
  if (_deliverCallbacks == null) return;

  while (!_deliverCallbacks.isEmpty) {
    var deliver = _deliverCallbacks.removeFirst();

    try {
      deliver();
    } catch (e, s) {
      // Schedule the error to be top-leveled later.
      new Completer().completeError(e, s);
    }
  }

  // Null it out, so [queueChangeRecords] will reschedule this method.
  _deliverCallbacks = null;
}

/** Queues an action to happen during the [deliverChangeRecords] timeslice. */
void queueChangeRecords(void deliverChanges()) {
  if (_deliverCallbacks == null) {
    _deliverCallbacks = new Queue<Function>();
    runAsync(deliverChangeRecords);
  }
  _deliverCallbacks.add(deliverChanges);
}

Queue _deliverCallbacks;
