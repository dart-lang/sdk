// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observable;

part 'ChangeEvent.dart';
part 'EventBatch.dart';

/// An object whose changes are tracked and who can issue events notifying how it
/// has been changed.
abstract class Observable {
  /// Returns a globally unique identifier for the object. */
  // TODO(sigmund): remove once dart supports maps with arbitrary keys.
  int get uid;

  /// Listeners on this model. */
  List<ChangeListener> get listeners;

  /// The parent observable to notify when this child is changed. */
  Observable? get parent;

  /// Adds a listener for changes on this observable instance. Returns whether
  /// the listener was added successfully.
  bool addChangeListener(ChangeListener listener);

  /// Removes a listener for changes on this observable instance. Returns whether
  /// the listener was removed successfully.
  bool removeChangeListener(ChangeListener listener);
}

/// Common functionality for observable objects. */
class AbstractObservable implements Observable {
  /// Unique id to identify this model in an event batch. */
  @override
  final int uid;

  /// The parent observable to notify when this child is changed. */
  @override
  final Observable? parent;

  /// Listeners on this model. */
  @override
  List<ChangeListener> listeners;

  /// Whether this object is currently observed by listeners or propagators. */
  bool get isObserved {
    for (Observable? obj = this; obj != null; obj = obj.parent) {
      if (listeners.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  AbstractObservable([this.parent])
      : uid = EventBatch.genUid(),
        listeners = List<ChangeListener>.empty();

  @override
  bool addChangeListener(ChangeListener listener) {
    if (!listeners.contains(listener)) {
      listeners.add(listener);
      return true;
    }

    return false;
  }

  @override
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

/// A growable list that fires events when it's modified. */
class ObservableList<T> extends AbstractObservable
    implements List<T>, Observable {
  /// Underlying list. */
  // TODO(rnystrom): Make this final if we get list.remove().
  final List<T> _internal;

  ObservableList([Observable? parent])
      : _internal = List<T>.empty(),
        super(parent);

  @override
  T operator [](int index) => _internal[index];

  @override
  void operator []=(int index, T value) {
    recordListUpdate(index, value, _internal[index]);
    _internal[index] = value;
  }

  @override
  int get length => _internal.length;

  @override
  List<R> cast<R>() => _internal.cast<R>();
  @override
  Iterable<R> whereType<R>() => _internal.whereType<R>();

  @override
  List<T> operator +(List<T> other) => _internal + other;

  @override
  Iterable<T> followedBy(Iterable<T> other) => _internal.followedBy(other);

  @override
  int indexWhere(bool Function(T element) test, [int start = 0]) =>
      _internal.indexWhere(test, start);

  @override
  int lastIndexWhere(bool Function(T element) test, [int? start]) =>
      _internal.lastIndexWhere(test, start);

  @override
  set length(int value) {
    _internal.length = value;
    recordGlobalChange();
  }

  @override
  void clear() {
    _internal.clear();
    recordGlobalChange();
  }

  @override
  Iterable<T> get reversed => _internal.reversed;

  @override
  void sort([int Function(T a, T b)? compare]) {
    //if (compare == null) compare = (u, v) => Comparable.compare(u, v);
    _internal.sort(compare);
    recordGlobalChange();
  }

  @override
  void add(T element) {
    recordListInsert(length, element);
    _internal.add(element);
  }

  @override
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

  @override
  T get first => _internal.first;
  @override
  set first(T value) {
    _internal.first = value;
  }

  @override
  T get last => _internal.last;
  @override
  set last(T value) {
    _internal.last = value;
  }

  @override
  T get single => _internal.single;

  @override
  void insert(int index, T element) {
    _internal.insert(index, element);
    recordListInsert(index, element);
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    throw UnimplementedError();
  }

  @override
  void setAll(int index, Iterable<T> iterable) {
    throw UnimplementedError();
  }

  @override
  T removeLast() {
    final result = _internal.removeLast();
    recordListRemove(length, result);
    return result;
  }

  @override
  T removeAt(int index) {
    T result = _internal.removeAt(index);
    recordListRemove(index, result);
    return result;
  }

  @override
  int indexOf(T element, [int start = 0]) {
    return _internal.indexOf(element, start);
  }

  @override
  int lastIndexOf(T element, [int? start]) {
    start ??= length - 1;
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
    srcStart ??= 0;
    dstStart ??= 0;

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

  @override
  void setRange(int start, int end, Iterable iterable, [int skipCount = 0]) {
    throw UnimplementedError();
  }

  @override
  void removeRange(int start, int end) {
    throw UnimplementedError();
  }

  @override
  void replaceRange(int start, int end, Iterable<T> iterable) {
    throw UnimplementedError();
  }

  @override
  void fillRange(int start, int end, [T? fillValue]) {
    throw UnimplementedError();
  }

  @override
  List<T> sublist(int start, [int? end]) {
    throw UnimplementedError();
  }

  @override
  Iterable<T> getRange(int start, int end) {
    throw UnimplementedError();
  }

  @override
  bool contains(Object? element) {
    throw UnimplementedError();
  }

  @override
  T reduce(T Function(T previousValue, T element) combine) {
    throw UnimplementedError();
  }

  @override
  R fold<R>(R initialValue, R Function(R previousValue, T element) combine) {
    throw UnimplementedError();
  }

  // Iterable<T>:
  @override
  Iterator<T> get iterator => _internal.iterator;

  @override
  Iterable<T> where(bool Function(T element) f) => _internal.where(f);
  @override
  Iterable<R> map<R>(R Function(T element) f) => _internal.map(f);
  @override
  Iterable<R> expand<R>(Iterable<R> Function(T element) f) =>
      _internal.expand(f);
  @override
  List<T> skip(int count) => _internal.skip(count) as List<T>;
  @override
  List<T> take(int count) => _internal.take(count) as List<T>;
  @override
  bool every(bool Function(T element) f) => _internal.every(f);
  @override
  bool any(bool Function(T element) f) => _internal.any(f);
  @override
  void forEach(void Function(T element) f) {
    _internal.forEach(f);
  }

  @override
  String join([String separator = ""]) => _internal.join(separator);
  @override
  T firstWhere(bool Function(T value) test, {T Function()? orElse}) {
    return _internal.firstWhere(test, orElse: orElse);
  }

  @override
  T lastWhere(bool Function(T value) test, {T Function()? orElse}) {
    return _internal.lastWhere(test, orElse: orElse);
  }

  @override
  void shuffle([random]) => throw UnimplementedError();
  @override
  bool remove(Object? element) => throw UnimplementedError();
  @override
  void removeWhere(bool Function(T element) test) => throw UnimplementedError();
  @override
  void retainWhere(bool Function(T element) test) => throw UnimplementedError();
  @override
  List<T> toList({bool growable = true}) => throw UnimplementedError();
  @override
  Set<T> toSet() => throw UnimplementedError();
  @override
  Iterable<T> takeWhile(bool Function(T value) test) =>
      throw UnimplementedError();
  @override
  Iterable<T> skipWhile(bool Function(T value) test) =>
      throw UnimplementedError();

  @override
  T singleWhere(bool Function(T value) test, {T Function()? orElse}) {
    return _internal.singleWhere(test, orElse: orElse);
  }

  @override
  T elementAt(int index) {
    return _internal.elementAt(index);
  }

  @override
  Map<int, T> asMap() {
    return _internal.asMap();
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;
}

// TODO(jmesserly): is this too granular? Other similar systems make whole
// classes observable instead of individual fields. The memory cost of having
// every field effectively boxed, plus having a listeners list is likely too
// much. Also, making a value observable necessitates adding ".value" to lots
// of places, and constructing all fields with the verbose
// "ObservableValue<DataType>(myValue)".
/// A wrapper around a single value whose change can be observed. */
class ObservableValue<T> extends AbstractObservable {
  ObservableValue(T value, [Observable? parent])
      : _value = value,
        super(parent);

  T get value => _value;

  set value(T newValue) {
    // Only fire on an actual change.
    if (!identical(newValue, _value)) {
      final oldValue = _value;
      _value = newValue;
      recordPropertyUpdate("value", newValue, oldValue);
    }
  }

  T _value;
}
