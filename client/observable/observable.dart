// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('observable');

#import('dart:coreimpl');

#source('ChangeEvent.dart');
#source('EventBatch.dart');

/**
 * An object whose changes are tracked and who can issue events notifying how it
 * has been changed.
 */
interface Observable {
  /** Returns a globally unique identifier for the object. */
  // TODO(sigmund): remove once dart supports maps with arbitrary keys.
  final int uid;

  /** Listeners on this model. */
  final List<ChangeListener> listeners;

  /** The parent observable to notify when this child is changed. */
  final Observable parent;

  /**
   * Adds a listener for changes on this observable instance. Returns whether
   * the listener was added successfully.
   */
  bool addChangeListener(ChangeListener listener);

  /**
   * Removes a listener for changes on this observable instance. Returns whether
   * the listener was removed successfully.
   */
  bool removeChangeListener(ChangeListener listener);
}


/** Common functionality for observable objects. */
class AbstractObservable implements Observable {

  /** Unique id to identify this model in an event batch. */
  final int uid;

  /** The parent observable to notify when this child is changed. */
  final Observable parent;

  /** Listeners on this model. */
  List<ChangeListener> listeners;

  /** Whether this object is currently observed by listeners or propagators. */
  bool get isObserved() {
    for (Observable obj = this; obj != null; obj = obj.parent) {
      if (listeners.length > 0) {
        return true;
      }
    }
    return false;
  }

  AbstractObservable([Observable this.parent = null])
    : uid = EventBatch.genUid(),
      listeners = new List<ChangeListener>();

  bool addChangeListener(ChangeListener listener) {
    if (listeners.indexOf(listener, 0) == -1) {
      listeners.add(listener);
      return true;
    }

    return false;
  }

  bool removeChangeListener(ChangeListener listener) {
    // TODO(rnystrom): This is awkward without List.remove(e).
    if (listeners.indexOf(listener, 0) != -1) {
      bool found = false;
      listeners = listeners.filter((e) => found || !(found = (e == listener)));
      return true;
    } else {
      return false;
    }
  }

  void recordPropertyUpdate(String propertyName, newValue, oldValue) {
    recordEvent(new ChangeEvent.property(
        this, propertyName, newValue, oldValue));
  }

  void recordListUpdate(int index, newValue, oldValue) {
    recordEvent(new ChangeEvent.list(
        this, ChangeEvent.UPDATE, index, newValue, oldValue));
  }

  void recordListInsert(int index, newValue) {
    recordEvent(new ChangeEvent.list(
        this, ChangeEvent.INSERT, index, newValue, null));
  }

  void recordListRemove(int index, oldValue) {
    recordEvent(new ChangeEvent.list(
        this, ChangeEvent.REMOVE, index, null, oldValue));
  }

  void recordGlobalChange() {
    recordEvent(new ChangeEvent.global(this));
  }

  void recordEvent(ChangeEvent event) {
    // Bail if no one cares about the event.
    if (!isObserved) {
      return;
    }

    if (EventBatch.current != null) {
      // Already in a batch, so just add it.
      assert (!EventBatch.current.sealed);
      // TODO(sigmund): measure the performance implications of this indirection
      // and consider whether caching the summary object in this instance helps.
      var summary = EventBatch.current.getEvents(this);
      summary.addEvent(event);
    } else {
      // Not in a batch, so create a one-off one.
      // TODO(rnystrom): Needing to do ignore and (null) here is awkward.
      EventBatch.wrap((ignore) { recordEvent(event); })(null);
    }
  }
}

/** A growable list that fires events when it's modified. */
class ObservableList<T>
    extends AbstractObservable
    implements List<T>, Observable {

  /** Underlying list. */
  // TODO(rnystrom): Make this final if we get list.remove().
  List<T> _internal;

  ObservableList([Observable parent = null])
    : super(parent), _internal = new List<T>();

  T operator [](int index) => _internal[index];

  void operator []=(int index, T value) {
    recordListUpdate(index, value, _internal[index]);
    _internal[index] = value;
  }

  int get length() => _internal.length;

  void set length(int value) {
    _internal.length = value;
    recordGlobalChange();
  }

  void clear() {
    _internal.clear();
    recordGlobalChange();
  }

  void sort(int compare(Object a, Object b)) {
    _internal.sort(compare);
    recordGlobalChange();
  }

  void add(T element) {
    recordListInsert(length, element);
    _internal.add(element);
  }

  void addLast(T element) {
    add(element);
  }

  void addAll(Collection<T> elements) {
    for (T element in elements) {
      add(element);
    }
  }

  int push(T element) {
    recordListInsert(length, element);
    _internal.add(element);
    return _internal.length;
  }

  T last() => _internal.last();

  T removeLast() {
    final result = _internal.removeLast();
    recordListRemove(length, result);
    return result;
  }

  T removeAt(int index) {
    int i = 0;
    T found = null;
    _internal = _internal.filter(bool _(element) {
      if (i++ == index) {
        found = element;
        return false;
      }
      return true;
    });
    if (found != null) {
      recordListRemove(index, found);
    }
    return found;
  }

  int indexOf(T element, [int start = 0]) {
    return _internal.indexOf(element, start);
  }

  int lastIndexOf(T element, [int start = null]) {
    if (start === null) start = length - 1;
    return _internal.lastIndexOf(element, start);
  }

  bool removeFirstElement(T element) {
    // the removeAt above will record the event.
    return (removeAt(indexOf(element, 0)) != null);
  }

  int removeAllElements(T element) {
    int count = 0;
    for (int i = 0; i < length; i++) {
      if (_internal[i] == element) {
        // the removeAt above will record the event.
        removeAt(i);
        // adjust index since remove shifted elements.
        i--;
        count++;
      }
    }
    return count;
  }

  void copyFrom(List<T> src, int srcStart, int dstStart, int count) {
    Arrays.copy(src, srcStart, this, dstStart, count);
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const NotImplementedException();
  }

  void removeRange(int start, int length) {
    throw const NotImplementedException();
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  List getRange(int start, int length) {
    throw const NotImplementedException();
  }

  // Iterable<T>:
  Iterator<T> iterator() => _internal.iterator();

  // Collection<T>:
  Collection<T> filter(bool f(T element)) => _internal.filter(f);
  bool every(bool f(T element)) => _internal.every(f);
  bool some(bool f(T element)) => _internal.some(f);
  void forEach(void f(T element)) { _internal.forEach(f); }
  bool isEmpty() => length == 0;
}

// TODO(jmesserly): is this too granular? Other similar systems make whole
// classes observable instead of individual fields. The memory cost of having
// every field effectively boxed, plus having a listeners list is likely too
// much. Also, making a value observable necessitates adding ".value" to lots
// of places, and constructing all fields with the verbose
// "new ObservableValue<DataType>(myValue)".
/** A wrapper around a single value whose change can be observed. */
class ObservableValue<T> extends AbstractObservable {
  ObservableValue(T value, [Observable parent = null])
    : super(parent), _value = value;

  T get value() => _value;

  void set value(T newValue) {
    // Only fire on an actual change.
    // TODO(terry): An object identity test === is needed.  Each DataSource has
    //              its own operator == which does a value compare.  Which
    //              equality check should be done?
    if (newValue !== _value) {
      final oldValue = _value;
      _value = newValue;
      recordPropertyUpdate("value", newValue, oldValue);
    }
  }

  T _value;
}
