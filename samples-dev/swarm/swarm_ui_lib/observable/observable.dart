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
  Observable? get parent;

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
  final Observable? parent;

  /** Listeners on this model. */
  List<ChangeListener> listeners;

  /** Whether this object is currently observed by listeners or propagators. */
  bool get isObserved {
    for (Observable? obj = this; obj != null; obj = obj.parent) {
      if (listeners.length > 0) {
        return true;
      }
    }
    return false;
  }

  AbstractObservable([this.parent = null])
      : uid = EventBatch.genUid(),
        listeners = List<ChangeListener>.empty();

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
    recordEvent(ChangeEvent.property(this, propertyName, newValue, oldValue));
  }

  void recordListUpdate(int index, newValue, oldValue) {
    recordEvent(
        ChangeEvent.list(this, ChangeEvent.UPDATE, index, newValue, oldValue));
  }

  void recordListInsert(int index, newValue) {
    recordEvent(
        ChangeEvent.list(this, ChangeEvent.INSERT, index, newValue, null));
  }

  void recordListRemove(int index, oldValue) {
    recordEvent(
        ChangeEvent.list(this, ChangeEvent.REMOVE, index, null, oldValue));
  }

  void recordGlobalChange() {
    recordEvent(ChangeEvent.global(this));
  }

  void recordEvent(ChangeEvent event) {
    // Bail if no one cares about the event.
    if (!isObserved) {
      return;
    }

    var current = EventBatch.current;
    if (current != null) {
      // Already in a batch, so just add it.
      assert(!current.sealed);
      // TODO(sigmund): measure the performance implications of this indirection
      // and consider whether caching the summary object in this instance helps.
      var summary = current.getEvents(this);
      summary.addEvent(event);
    } else {
      // Not in a batch, so create a one-off one.
      // TODO(rnystrom): Needing to do ignore and (null) here is awkward.
      EventBatch.wrap((ignore) {
        recordEvent(event);
      })(null);
    }
  }
}

/** A growable list that fires events when it's modified. */
class ObservableList<T> extends AbstractObservable
    implements List<T>, Observable {
  /** Underlying list. */
  // TODO(rnystrom): Make this final if we get list.remove().
  List<T> _internal;

  ObservableList([Observable? parent = null])
      : _internal = List<T>.empty(),
        super(parent);

  T operator [](int index) => _internal[index];

  void operator []=(int index, T value) {
    recordListUpdate(index, value, _internal[index]);
    _internal[index] = value;
  }

  int get length => _internal.length;

  List<R> cast<R>() => _internal.cast<R>();
  Iterable<R> whereType<R>() => _internal.whereType<R>();

  List<T> operator +(List<T> other) => _internal + other;

  Iterable<T> followedBy(Iterable<T> other) => _internal.followedBy(other);

  int indexWhere(bool test(T element), [int start = 0]) =>
      _internal.indexWhere(test, start);

  int lastIndexWhere(bool test(T element), [int? start]) =>
      _internal.lastIndexWhere(test, start);

  void set length(int value) {
    _internal.length = value;
    recordGlobalChange();
  }

  void clear() {
    _internal.clear();
    recordGlobalChange();
  }

  Iterable<T> get reversed => _internal.reversed;

  void sort([int compare(T a, T b)?]) {
    //if (compare == null) compare = (u, v) => Comparable.compare(u, v);
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
  void set first(T value) {
    _internal.first = value;
  }

  T get last => _internal.last;
  void set last(T value) {
    _internal.last = value;
  }

  T get single => _internal.single;

  void insert(int index, T element) {
    _internal.insert(index, element);
    recordListInsert(index, element);
  }

  void insertAll(int index, Iterable<T> iterable) {
    throw UnimplementedError();
  }

  void setAll(int index, Iterable<T> iterable) {
    throw UnimplementedError();
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

  int indexOf(T element, [int start = 0]) {
    return _internal.indexOf(element, start);
  }

  int lastIndexOf(T element, [int? start]) {
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

  void copyFrom(List<T> src, int? srcStart, int? dstStart, int count) {
    List dst = this;
    if (srcStart == null) srcStart = 0;
    if (dstStart == null) dstStart = 0;

    if (srcStart < dstStart) {
      for (int i = srcStart + count - 1, j = dstStart + count - 1;
          i >= srcStart;
          i--, j--) {
        dst[j] = src[i];
      }
    } else {
      for (int i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
        dst[j] = src[i];
      }
    }
  }

  void setRange(int start, int end, Iterable iterable, [int skipCount = 0]) {
    throw UnimplementedError();
  }

  void removeRange(int start, int end) {
    throw UnimplementedError();
  }

  void replaceRange(int start, int end, Iterable<T> iterable) {
    throw UnimplementedError();
  }

  void fillRange(int start, int end, [T? fillValue]) {
    throw UnimplementedError();
  }

  List<T> sublist(int start, [int? end]) {
    throw UnimplementedError();
  }

  Iterable<T> getRange(int start, int end) {
    throw UnimplementedError();
  }

  bool contains(Object? element) {
    throw UnimplementedError();
  }

  T reduce(T combine(T previousValue, T element)) {
    throw UnimplementedError();
  }

  R fold<R>(R initialValue, R combine(R previousValue, T element)) {
    throw UnimplementedError();
  }

  // Iterable<T>:
  Iterator<T> get iterator => _internal.iterator;

  Iterable<T> where(bool f(T element)) => _internal.where(f);
  Iterable<R> map<R>(R f(T element)) => _internal.map(f);
  Iterable<R> expand<R>(Iterable<R> f(T element)) => _internal.expand(f);
  List<T> skip(int count) => _internal.skip(count) as List<T>;
  List<T> take(int count) => _internal.take(count) as List<T>;
  bool every(bool f(T element)) => _internal.every(f);
  bool any(bool f(T element)) => _internal.any(f);
  void forEach(void f(T element)) {
    _internal.forEach(f);
  }

  String join([String separator = ""]) => _internal.join(separator);
  T firstWhere(bool test(T value), {T orElse()?}) {
    return _internal.firstWhere(test, orElse: orElse);
  }

  T lastWhere(bool test(T value), {T orElse()?}) {
    return _internal.lastWhere(test, orElse: orElse);
  }

  void shuffle([random]) => throw UnimplementedError();
  bool remove(Object? element) => throw UnimplementedError();
  void removeWhere(bool test(T element)) => throw UnimplementedError();
  void retainWhere(bool test(T element)) => throw UnimplementedError();
  List<T> toList({bool growable: true}) => throw UnimplementedError();
  Set<T> toSet() => throw UnimplementedError();
  Iterable<T> takeWhile(bool test(T value)) => throw UnimplementedError();
  Iterable<T> skipWhile(bool test(T value)) => throw UnimplementedError();

  T singleWhere(bool test(T value), {T orElse()?}) {
    return _internal.singleWhere(test, orElse: orElse);
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
// "ObservableValue<DataType>(myValue)".
/** A wrapper around a single value whose change can be observed. */
class ObservableValue<T> extends AbstractObservable {
  ObservableValue(T value, [Observable? parent = null])
      : _value = value,
        super(parent);

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
