// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.change_notifier;

import 'dart:async';
import 'dart:collection' show UnmodifiableListView;
import 'package:observe/observe.dart';
import 'package:observe/src/observable.dart' show notifyPropertyChangeHelper;

/// Mixin and base class for implementing an [Observable] object that performs
/// its own change notifications, and does not need to be considered by
/// [Observable.dirtyCheck].
///
/// When a field, property, or indexable item is changed, a derived class should
/// call [notifyPropertyChange]. See that method for an example.
abstract class ChangeNotifier implements Observable {
  StreamController _changes;
  List<ChangeRecord> _records;

  Stream<List<ChangeRecord>> get changes {
    if (_changes == null) {
      _changes = new StreamController.broadcast(sync: true,
          onListen: observed, onCancel: unobserved);
    }
    return _changes.stream;
  }

  // TODO(jmesserly): should these be public? They're useful lifecycle methods
  // for subclasses. Ideally they'd be protected.
  /// Override this method to be called when the [changes] are first observed.
  void observed() {}

  /// Override this method to be called when the [changes] are no longer being
  /// observed.
  void unobserved() {
    // Free some memory
    _changes = null;
  }

  bool deliverChanges() {
    var records = _records;
    _records = null;
    if (hasObservers && records != null) {
      _changes.add(new UnmodifiableListView<ChangeRecord>(records));
      return true;
    }
    return false;
  }

  /// True if this object has any observers, and should call
  /// [notifyPropertyChange] for changes.
  bool get hasObservers => _changes != null && _changes.hasListener;

  /// Notify that the field [name] of this object has been changed.
  ///
  /// The [oldValue] and [newValue] are also recorded. If the two values are
  /// equal, no change will be recorded.
  ///
  /// For convenience this returns [newValue]. This makes it easy to use in a
  /// setter:
  ///
  ///     var _myField;
  ///     @reflectable get myField => _myField;
  ///     @reflectable set myField(value) {
  ///       _myField = notifyPropertyChange(#myField, _myField, value);
  ///     }
  notifyPropertyChange(Symbol field, Object oldValue, Object newValue)
      => notifyPropertyChangeHelper(this, field, oldValue, newValue);

  void notifyChange(ChangeRecord record) {
    if (!hasObservers) return;

    if (_records == null) {
      _records = [];
      scheduleMicrotask(deliverChanges);
    }
    _records.add(record);
  }
}
