// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observe;

/**
 * Use `@observable` to make a field automatically observable.
 */
const Object observable = const _ObservableAnnotation();

/**
 * Interface representing an observable object. This is used by data in
 * model-view architectures to notify interested parties of [changes].
 *
 * This object does not require any specific technique to implement
 * observability. However if you implement change notification yourself, you
 * should also implement [ChangeNotifier], so [dirtyCheck] knows to skip the
 * object.
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
  bool deliverChanges();

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

  Stream<List<ChangeRecord>> get changes {
    if (_changes == null) {
      _changes = new StreamController.broadcast(sync: true,
          onListen: _observed, onCancel: _unobserved);
    }
    return _changes.stream;
  }

  /**
   * True if this object has any observers, and should call
   * [notifyPropertyChange] for changes.
   */
  bool get hasObservers => _changes != null && _changes.hasListener;

  void _observed() {
    // Register this object for dirty checking purposes.
    registerObservable(this);

    var mirror = reflect(this);
    var values = new Map<Symbol, Object>();

    // TODO(jmesserly): this should consider the superclass. Unfortunately
    // that is not possible right now because of:
    // http://code.google.com/p/dart/issues/detail?id=9434
    for (var field in mirror.type.variables.values) {
      if (field.isFinal || field.isStatic || field.isPrivate) continue;

      for (var meta in field.metadata) {
        if (identical(observable, meta.reflectee)) {
          var name = field.simpleName;
          // Note: since this is a field, getting the value shouldn't execute
          // user code, so we don't need to worry about errors.
          values[name] = mirror.getField(name).reflectee;
          break;
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

    List changes = null;
    _values.forEach((name, oldValue) {
      var newValue = _mirror.getField(name).reflectee;
      if (!identical(oldValue, newValue)) {
        if (changes == null) changes = <PropertyChangeRecord>[];
        changes.add(new PropertyChangeRecord(name));
        _values[name] = newValue;
      }
    });

    if (changes == null) return false;

    // TODO(jmesserly): make "changes" immutable
    _changes.add(changes);
    return true;
  }
}

/**
 * The type of the `@observable` annotation.
 *
 * Library private because you should be able to use the [observable] field
 * to get the one and only instance. We could make it public though, if anyone
 * needs it for some reason.
 */
class _ObservableAnnotation {
  const _ObservableAnnotation();
}
