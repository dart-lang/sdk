// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void DebugCallback(String methodName, var arg1, var arg2);

class DebugMap<K, V> implements Map<K, V> {
  final Map<K, V> sourceMap;
  DebugCallback indexSetCallback;
  DebugCallback putIfAbsentCallback;
  DebugCallback removeCallback;

  DebugMap(this.sourceMap, {DebugCallback addCallback, this.removeCallback}) {
    if (addCallback != null) {
      this.addCallback = addCallback;
    }
  }

  void set addCallback(DebugCallback value) {
    indexSetCallback = value;
    putIfAbsentCallback = value;
  }

  @override
  Map<RK, RV> cast<RK, RV>() => Map.castFrom<K, V, RK, RV>(this);
  @override
  bool containsValue(Object value) {
    return sourceMap.containsValue(value);
  }

  @override
  bool containsKey(Object key) => sourceMap.containsKey(key);

  @override
  V operator [](Object key) => sourceMap[key];

  @override
  void operator []=(K key, V value) {
    if (indexSetCallback != null) {
      indexSetCallback('[]=', key, value);
    }
    sourceMap[key] = value;
  }

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    return sourceMap.putIfAbsent(key, () {
      V v = ifAbsent();
      if (putIfAbsentCallback != null) {
        putIfAbsentCallback('putIfAbsent', key, v);
      }
      return v;
    });
  }

  @override
  void addAll(Map<K, V> other) => sourceMap.addAll(other);

  @override
  V remove(Object key) {
    if (removeCallback != null) {
      removeCallback('remove', key, sourceMap[key]);
    }
    return sourceMap.remove(key);
  }

  @override
  void clear() {
    if (removeCallback != null) {
      removeCallback('clear', sourceMap, null);
    }
    sourceMap.clear();
  }

  @override
  void forEach(void f(K key, V value)) => sourceMap.forEach(f);

  @override
  Iterable<K> get keys => sourceMap.keys;

  @override
  Iterable<V> get values => sourceMap.values;

  @override
  Iterable<MapEntry<K, V>> get entries => sourceMap.entries;

  @override
  void addEntries(Iterable<MapEntry<K, V>> entries) {
    sourceMap.addEntries(entries);
  }

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> transform(K key, V value)) =>
      sourceMap.map(transform);

  @override
  int get length => sourceMap.length;

  @override
  bool get isEmpty => sourceMap.isEmpty;

  @override
  bool get isNotEmpty => sourceMap.isNotEmpty;

  @override
  V update(K key, V update(V value), {V ifAbsent()}) =>
      sourceMap.update(key, update, ifAbsent: ifAbsent);

  @override
  void updateAll(V update(K key, V value)) {
    sourceMap.updateAll(update);
  }

  @override
  void removeWhere(bool test(K key, V value)) {
    sourceMap.removeWhere(test);
  }
}

class DebugIterable<E> implements Iterable<E> {
  final Iterable<E> iterable;

  DebugIterable(this.iterable);

  @override
  Iterator<E> get iterator => iterable.iterator;

  @override
  Iterable<R> cast<R>() => Iterable.castFrom<E, R>(this);
  @override
  Iterable<T> map<T>(T f(E element)) => iterable.map(f);

  @override
  Iterable<E> where(bool test(E element)) => iterable.where(test);

  @override
  Iterable<T> expand<T>(Iterable<T> f(E element)) => iterable.expand(f);

  @override
  bool contains(Object element) => iterable.contains(element);

  @override
  void forEach(void f(E element)) => iterable.forEach(f);

  @override
  E reduce(E combine(E value, E element)) => iterable.reduce(combine);

  @override
  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    return iterable.fold(initialValue, combine);
  }

  @override
  bool every(bool test(E element)) => iterable.every(test);

  @override
  String join([String separator = ""]) => iterable.join(separator);

  @override
  bool any(bool test(E element)) => iterable.any(test);

  @override
  List<E> toList({bool growable: true}) {
    return iterable.toList(growable: growable);
  }

  @override
  Set<E> toSet() => iterable.toSet();

  @override
  int get length => iterable.length;

  @override
  bool get isEmpty => iterable.isEmpty;

  @override
  bool get isNotEmpty => iterable.isNotEmpty;

  @override
  Iterable<E> take(int n) => iterable.take(n);

  @override
  Iterable<E> takeWhile(bool test(E value)) => iterable.takeWhile(test);

  @override
  Iterable<E> skip(int n) => iterable.skip(n);

  @override
  Iterable<E> skipWhile(bool test(E value)) => iterable.skipWhile(test);

  @override
  E get first => iterable.first;

  @override
  E get last => iterable.last;

  @override
  E get single => iterable.single;

  @override
  E firstWhere(bool test(E element), {E orElse()}) {
    return iterable.firstWhere(test, orElse: orElse);
  }

  @override
  E lastWhere(bool test(E element), {E orElse()}) {
    return iterable.lastWhere(test, orElse: orElse);
  }

  @override
  E singleWhere(bool test(E element), {E orElse()}) =>
      iterable.singleWhere(test, orElse: orElse);

  @override
  E elementAt(int index) => iterable.elementAt(index);

  @override
  Iterable<E> followedBy(Iterable<E> other) => iterable.followedBy(other);

  @override
  Iterable<T> whereType<T>() => iterable.whereType<T>();

  @override
  String toString() => iterable.toString();
}

class DebugList<E> extends DebugIterable<E> implements List<E> {
  DebugCallback addCallback;
  DebugCallback addAllCallback;

  DebugList(List<E> list, {this.addCallback, this.addAllCallback})
      : super(list);

  List<E> get list => iterable;

  @override
  List<R> cast<R>() => List.castFrom<E, R>(this);
  @override
  List<E> operator +(List<E> other) => list + other;

  @override
  E operator [](int index) => list[index];

  @override
  void operator []=(int index, E value) {
    list[index] = value;
  }

  @override
  void set first(E element) {
    list.first = element;
  }

  @override
  void set last(E element) {
    list.last = element;
  }

  @override
  int get length => list.length;

  @override
  void set length(int newLength) {
    list.length = newLength;
  }

  @override
  void add(E value) {
    if (addCallback != null) {
      addCallback('add', value, null);
    }
    list.add(value);
  }

  @override
  void addAll(Iterable<E> iterable) {
    if (addAllCallback != null) {
      addAllCallback('addAll', iterable, null);
    }
    list.addAll(iterable);
  }

  @override
  Iterable<E> get reversed => list.reversed;

  @override
  void sort([int compare(E a, E b)]) => list.sort(compare);

  @override
  void shuffle([random]) => list.shuffle(random);

  @override
  int indexOf(E element, [int start = 0]) => list.indexOf(element, start);

  @override
  int indexWhere(bool test(E element), [int start = 0]) =>
      list.indexWhere(test, start);

  @override
  int lastIndexOf(E element, [int start]) => list.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool test(E element), [int start]) =>
      list.lastIndexWhere(test, start);

  @override
  void clear() => list.clear();

  @override
  void insert(int index, E element) => list.insert(index, element);

  @override
  void insertAll(int index, Iterable<E> iterable) {
    list.insertAll(index, iterable);
  }

  @override
  void setAll(int index, Iterable<E> iterable) => list.setAll(index, iterable);

  @override
  bool remove(Object value) => list.remove(value);

  @override
  E removeAt(int index) => list.removeAt(index);

  @override
  E removeLast() => list.removeLast();

  @override
  void removeWhere(bool test(E element)) => list.removeWhere(test);

  @override
  void retainWhere(bool test(E element)) => list.retainWhere(test);

  @override
  List<E> sublist(int start, [int end]) => list.sublist(start, end);

  @override
  Iterable<E> getRange(int start, int end) => list.getRange(start, end);

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    list.setRange(start, end, iterable, skipCount);
  }

  @override
  void removeRange(int start, int end) {
    list.removeRange(start, end);
  }

  @override
  void fillRange(int start, int end, [E fillValue]) {
    list.fillRange(start, end, fillValue);
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacement) {
    list.replaceRange(start, end, replacement);
  }

  @override
  Map<int, E> asMap() => list.asMap();
}

class DebugSet<E> extends DebugIterable<E> implements Set<E> {
  DebugCallback addCallback;

  DebugSet(Set<E> set, {this.addCallback}) : super(set);

  Set<E> get set => iterable;

  @override
  Set<R> cast<R>() => Set.castFrom<E, R>(this);
  @override
  bool contains(Object value) => set.contains(value);

  @override
  bool add(E value) {
    if (addCallback != null) {
      addCallback('add', value, null);
    }
    return set.add(value);
  }

  @override
  void addAll(Iterable<E> elements) {
    elements.forEach(add);
  }

  @override
  bool remove(Object value) => set.remove(value);

  @override
  E lookup(Object object) => set.lookup(object);

  @override
  void removeAll(Iterable<Object> elements) => set.removeAll(elements);

  @override
  void retainAll(Iterable<Object> elements) => set.retainAll(elements);

  @override
  void removeWhere(bool test(E element)) => set.removeWhere(test);

  @override
  void retainWhere(bool test(E element)) => set.retainWhere(test);

  @override
  bool containsAll(Iterable<Object> other) => set.containsAll(other);

  @override
  Set<E> intersection(Set<Object> other) => set.intersection(other);

  @override
  Set<E> union(Set<E> other) => set.union(other);

  @override
  Set<E> difference(Set<Object> other) => set.difference(other);

  @override
  void clear() => set.clear();

  @override
  Set<E> toSet() => set.toSet();
}

/// Throws an exception if the runtime type of [object] is not in
/// [runtimeTypes].
///
/// Use this to gradually build the set of actual runtime values of [object]
/// at the call site by running test programs and adding to [runtimeTypes] when
/// new type are found.
void assertType(String name, List<String> runtimeTypes, var object,
    {bool showObjects: false}) {
  String runtimeType = '${object.runtimeType}';
  if (runtimeTypes != null && runtimeTypes.contains(runtimeType)) return;
  throw '$name: $runtimeType'
      '${showObjects ? ' ($object)' : ''}';
}

/// Callback for the [addCallback] of [DebugMap] that throws an exception if
/// the runtime type of key/value pairs are not in [runtimeTypes].
///
/// Use this to gradually build the set of actual runtime values of key/value
/// pairs of a map by running test programs and adding to [runtimeTypes] when
/// new type are found.
class MapTypeAsserter {
  final String name;
  final Map<String, List<String>> runtimeTypes;
  final bool showObjects;

  const MapTypeAsserter(this.name, this.runtimeTypes,
      {bool this.showObjects: false});

  void call(String methodName, var key, var value) {
    check(key, value, '$methodName: ');
  }

  void check(var key, var value, [String text = '']) {
    String keyType = '${key.runtimeType}';
    String valueType = '${value.runtimeType}';
    List<String> valuesTypes = runtimeTypes[keyType];
    if (valuesTypes != null && valuesTypes.contains(valueType)) return;
    throw '$name: $text$keyType => $valueType'
        '${showObjects ? ' ($key => $value)' : ''}';
  }
}

/// Callback for the [addCallback] of [DebugSet] or [DebugList]  that throws an
/// exception if the runtime type of the elements are not in [runtimeTypes].
///
/// Use this to gradually build the set of actual runtime values of the elements
/// of a collection by running test programs and adding to [runtimeTypes] when
/// new type are found.
class CollectionTypeAsserter {
  final String name;
  final List<String> runtimeTypes;
  final bool showObjects;

  const CollectionTypeAsserter(this.name, this.runtimeTypes,
      {bool this.showObjects: false});

  void call(String methodName, var element, _) {
    check(element, '$methodName: ');
  }

  void check(var element, [String text = '']) {
    String elementType = '${element.runtimeType}';
    if (runtimeTypes.contains(elementType)) return;
    throw '$name: $text$elementType'
        '${showObjects ? ' ($element)' : ''}';
  }
}
