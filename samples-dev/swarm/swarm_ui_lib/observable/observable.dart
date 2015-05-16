// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observable;

part 'ChangeEvent.dart';
part 'EventBatch.dart';

/**
 * An object whose changes are tracked and who can issue events notifying how it
 * has been changed.
 */
abstract class Observable {
  /** Returns a globally unique identifier for the object. */
  // TODO(sigmund): remove once dart supports maps with arbitrary keys.
  int get uid;

  /** Listeners on this model. */
  List<ChangeListener> get listeners;

  /** The parent observable to notify when this child is changed. */
  Observable get parent;

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
  bool get isObserved {
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
    var index = listeners.indexOf(listener, 0);
    if (index != -1) {
      listeners.removeAt(index);
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

  int get length => _internal.length;

  void set length(int value) {
    _internal.length = value;
    recordGlobalChange();
  }

  void clear() {
    _internal.clear();
    recordGlobalChange();
  }

  Iterable<T> get reversed => _internal.reversed;

  void sort([int compare(var a, var b)]) {
    if (compare == null) compare = Comparable.compare;
    _internal.sort(compare);
    recordGlobalChange();
  }

  void add(T element) {
    recordListInsert(length, element);
    _internal.add(element);
  }

  void addAll(Iterable<T> elements) {
    for (T element in elements) {
      add(element);
    }
  }

  int push(T element) {
    recordListInsert(length, element);
    _internal.add(element);
    return _internal.length;
  }

  T get first => _internal.first;
  T get last => _internal.last;
  T get single => _internal.single;

  void insert(int index, T element) {
    _internal.insert(index, element);
    recordListInsert(index, element);
  }

  void insertAll(int index, Iterable<T> iterable) {
    throw new UnimplementedError();
  }

  void setAll(int index, Iterable<T> iterable) {
    throw new UnimplementedError();
  }

  T removeLast() {
    final result = _internal.removeLast();
    recordListRemove(length, result);
    return result;
  }

  T removeAt(int index) {
    T result = _internal.removeAt(index);
    recordListRemove(index, result);
    return result;
  }

  int indexOf(Object element, [int start = 0]) {
    return _internal.indexOf(element, start);
  }

  int lastIndexOf(Object element, [int start = null]) {
    if (start == null) start = length - 1;
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
    List dst = this;
    if (srcStart == null) srcStart = 0;
    if (dstStart == null) dstStart = 0;

    if (srcStart < dstStart) {
      for (int i = srcStart + count - 1, j = dstStart + count - 1;
           i >= srcStart; i--, j--) {
        dst[j] = src[i];
      }
    } else {
      for (int i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
        dst[j] = src[i];
      }
    }
  }

  void setRange(int start, int end, Iterable iterable, [int skipCount = 0]) {
    throw new UnimplementedError();
  }

  void removeRange(int start, int end) {
    throw new UnimplementedError();
  }

  void replaceRange(int start, int end, Iterable<T> iterable) {
    throw new UnimplementedError();
  }

  void fillRange(int start, int end, [T fillValue]) {
    throw new UnimplementedError();
  }

  List sublist(int start, [int end]) {
    throw new UnimplementedError();
  }

  Iterable getRange(int start, int end) {
    throw new UnimplementedError();
  }

  bool contains(Object element) {
    throw new UnimplementedError();
  }

  T reduce(T combine(T previousValue, T element)) {
    throw new UnimplementedError();
  }

  dynamic fold(var initialValue,
               dynamic combine(var previousValue, T element)) {
    throw new UnimplementedError();
  }

  // Iterable<T>:
  Iterator<T> get iterator => _internal.iterator;

  Iterable<T> where(bool f(T element)) => _internal.where(f);
  Iterable map(f(T element)) => _internal.map(f);
  Iterable expand(Iterable f(T element)) => _internal.expand(f);
  List<T> skip(int count) => _internal.skip(count);
  List<T> take(int count) => _internal.take(count);
  bool every(bool f(T element)) => _internal.every(f);
  bool any(bool f(T element)) => _internal.any(f);
  void forEach(void f(T element)) { _internal.forEach(f); }
  String join([String separator = ""]) => _internal.join(separator);
  dynamic firstWhere(bool test(T value), {Object orElse()}) {
    return _internal.firstWhere(test, orElse: orElse);
  }
  dynamic lastWhere(bool test(T value), {Object orElse()}) {
    return _internal.lastWhere(test, orElse: orElse);
  }

  void shuffle([random]) => throw new UnimplementedError();
  bool remove(T element) => throw new UnimplementedError();
  void removeWhere(bool test(T element)) => throw new UnimplementedError();
  void retainWhere(bool test(T element)) => throw new UnimplementedError();
  List<T> toList({bool growable:true}) => throw new UnimplementedError();
  Set<T> toSet() => throw new UnimplementedError();
  Iterable<T> takeWhile(bool test(T value)) => throw new UnimplementedError();
  Iterable<T> skipWhile(bool test(T value)) => throw new UnimplementedError();

  T singleWhere(bool test(T value)) {
    return _internal.singleWhere(test);
  }
  T elementAt(int index) {
    return _internal.elementAt(index);
  }
  Map<int, T> asMap() {
    return _internal.asMap();
  }


  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;
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

  T get value => _value;

  void set value(T newValue) {
    // Only fire on an actual change.
    if (!identical(newValue, _value)) {
      final oldValue = _value;
      _value = newValue;
      recordPropertyUpdate("value", newValue, oldValue);
    }
  }

  T _value;
}
