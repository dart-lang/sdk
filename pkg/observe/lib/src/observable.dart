// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observe;

/**
 * Interface representing an observable object. This is used by data in
 * model-view architectures to notify interested parties of [changes].
 *
 * This object does not require any specific technique to implement
 * observability. If you mixin [ObservableMixin], [dirtyCheck] will know to
 * check for changes on the object. You may also implement change notification
 * yourself, by calling [notifyChange].
 *
 * You can use [ObservableBase] or [ObservableMixin] to implement this.
 */
abstract class Observable {
  /**
   * The stream of change records to this object. Records will be delivered
   * asynchronously.
   *
   * [deliverChanges] can be called to force synchronous delivery.
   */
  Stream<List<ChangeRecord>> get changes;

  /**
   * Synchronously deliver pending [changes]. Returns true if any records were
   * delivered, otherwise false.
   */
  // TODO(jmesserly): this is a bit different from the ES Harmony version, which
  // allows delivery of changes to a particular observer:
  // http://wiki.ecmascript.org/doku.php?id=harmony:observe#object.deliverchangerecords
  //
  // The rationale for that, and for async delivery in general, is the principal
  // that you shouldn't run code (observers) when it doesn't expect to be run.
  // If you do that, you risk violating invariants that the code assumes.
  //
  // For this reason, we need to match the ES Harmony version. The way we can do
  // this in Dart is to add a method on StreamSubscription (possibly by
  // subclassing Stream* types) that immediately delivers records for only
  // that subscription. Alternatively, we could consider using something other
  // than Stream to deliver the multicast change records, and provide an
  // Observable->Stream adapter.
  //
  // Also: we should be delivering changes to the observer (subscription) based
  // on the birth order of the observer. This is for compatibility with ES
  // Harmony as well as predictability for app developers.
  bool deliverChanges();

  /**
   * Notify observers of a change.
   *
   * For most objects [ObservableMixin.notifyPropertyChange] is more
   * convenient, but collections sometimes deliver other types of changes such
   * as a [ListChangeRecord].
   */
  void notifyChange(ChangeRecord record);

  /**
   * True if this object has any observers, and should call
   * [notifyChange] for changes.
   */
  bool get hasObservers;

  /**
   * Performs dirty checking of objects that inherit from [ObservableMixin].
   * This scans all observed objects using mirrors and determines if any fields
   * have changed. If they have, it delivers the changes for the object.
   */
  static void dirtyCheck() => dirtyCheckObservables();
}

/**
 * Base class implementing [Observable].
 *
 * When a field, property, or indexable item is changed, the change record
 * will be sent to [changes].
 */
typedef ObservableBase = Object with ObservableMixin;

/**
 * Mixin for implementing [Observable] objects.
 *
 * When a field, property, or indexable item is changed, the change record
 * will be sent to [changes].
 */
abstract class ObservableMixin implements Observable {
  StreamController _changes;
  InstanceMirror _mirror;

  Map<Symbol, Object> _values;
  List<ChangeRecord> _records;

  static final _objectType = reflectClass(Object);

  Stream<List<ChangeRecord>> get changes {
    if (_changes == null) {
      _changes = new StreamController.broadcast(sync: true,
          onListen: _observed, onCancel: _unobserved);
    }
    return _changes.stream;
  }

  bool get hasObservers => _changes != null && _changes.hasListener;

  void _observed() {
    // Register this object for dirty checking purposes.
    registerObservable(this);

    var mirror = reflect(this);
    var values = new Map<Symbol, Object>();

    // Note: we scan for @observable regardless of whether the base type
    // actually includes this mixin. While perhaps too inclusive, it lets us
    // avoid complex logic that walks "with" and "implements" clauses.
    for (var type = mirror.type; type != _objectType; type = type.superclass) {
      for (var field in type.variables.values) {
        if (field.isFinal || field.isStatic || field.isPrivate) continue;

        for (var meta in field.metadata) {
          if (meta.reflectee is ObservableProperty) {
            var name = field.simpleName;
            // Note: since this is a field, getting the value shouldn't execute
            // user code, so we don't need to worry about errors.
            values[name] = mirror.getField(name).reflectee;
            break;
          }
        }
      }
    }

    _mirror = mirror;
    _values = values;
  }

  /** Release data associated with observation. */
  void _unobserved() {
    // Note: we don't need to explicitly unregister from the dirty check list.
    // This will happen automatically at the next call to dirtyCheck.
    if (_values != null) {
      _mirror = null;
      _values = null;
    }
  }

  bool deliverChanges() {
    if (_values == null || !hasObservers) return false;

    // Start with manually notified records (computed properties, etc),
    // then scan all fields for additional changes.
    List records = _records;
    _records = null;

    _values.forEach((name, oldValue) {
      var newValue = _mirror.getField(name).reflectee;
      if (!identical(oldValue, newValue)) {
        if (records == null) records = [];
        records.add(new PropertyChangeRecord(name));
        _values[name] = newValue;
      }
    });

    if (records == null) return false;

    _changes.add(new UnmodifiableListView<ChangeRecord>(records));
    return true;
  }

  /**
   * Notify that the field [name] of this object has been changed.
   *
   * The [oldValue] and [newValue] are also recorded. If the two values are
   * identical, no change will be recorded.
   *
   * For convenience this returns [newValue].
   */
  notifyPropertyChange(Symbol field, Object oldValue, Object newValue)
      => _notifyPropertyChange(this, field, oldValue, newValue);

  /**
   * Notify a change manually. This is *not* required for fields, but can be
   * used for computed properties. *Note*: unlike [ChangeNotifierMixin] this
   * will not schedule [deliverChanges]; use [Observable.dirtyCheck] instead.
   */
  void notifyChange(ChangeRecord record) {
    if (!hasObservers) return;

    if (_records == null) _records = [];
    _records.add(record);
  }
}

/**
 * Notify the property change. Shorthand for:
 *
 *     target.notifyChange(new PropertyChangeRecord(targetName));
 */
void notifyProperty(Observable target, Symbol targetName) {
  target.notifyChange(new PropertyChangeRecord(targetName));
}

// TODO(jmesserly): remove the instance method and make this top-level method
// public instead?
_notifyPropertyChange(Observable obj, Symbol field, Object oldValue,
    Object newValue) {

  // TODO(jmesserly): should this be == instead of identical, to prevent
  // spurious loops?
  if (obj.hasObservers && !identical(oldValue, newValue)) {
    obj.notifyChange(new PropertyChangeRecord(field));
  }
  return newValue;
}
