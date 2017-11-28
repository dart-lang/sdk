// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void DebugCallback(String methodName, var arg1, var arg2);

class DebugMap<K, V> implements Map<K, V> {
  final Map<K, V> map;
  DebugCallback indexSetCallback;
  DebugCallback putIfAbsentCallback;
  DebugCallback removeCallback;

  DebugMap(this.map, {DebugCallback addCallback, this.removeCallback}) {
    if (addCallback != null) {
      this.addCallback = addCallback;
    }
  }

  void set addCallback(DebugCallback value) {
    indexSetCallback = value;
    putIfAbsentCallback = value;
  }

  bool containsValue(Object value) {
    return map.containsValue(value);
  }

  bool containsKey(Object key) => map.containsKey(key);

  V operator [](Object key) => map[key];

  void operator []=(K key, V value) {
    if (indexSetCallback != null) {
      indexSetCallback('[]=', key, value);
    }
    map[key] = value;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    return map.putIfAbsent(key, () {
      V v = ifAbsent();
      if (putIfAbsentCallback != null) {
        putIfAbsentCallback('putIfAbsent', key, v);
      }
      return v;
    });
  }

  void addAll(Map<K, V> other) => map.addAll(other);

  V remove(Object key) {
    if (removeCallback != null) {
      removeCallback('remove', key, map[key]);
    }
    return map.remove(key);
  }

  void clear() {
    if (removeCallback != null) {
      removeCallback('clear', map, null);
    }
    map.clear();
  }

  void forEach(void f(K key, V value)) => map.forEach(f);

  Iterable<K> get keys => map.keys;

  Iterable<V> get values => map.values;

  int get length => map.length;

  bool get isEmpty => map.isEmpty;

  bool get isNotEmpty => map.isNotEmpty;
}

class DebugIterable<E> implements Iterable<E> {
  final Iterable<E> iterable;

  DebugIterable(this.iterable);

  Iterator<E> get iterator => iterable.iterator;

  Iterable<T> map<T>(T f(E element)) => iterable.map(f);

  Iterable<E> where(bool test(E element)) => iterable.where(test);

  Iterable<T> expand<T>(Iterable<T> f(E element)) => iterable.expand(f);

  bool contains(Object element) => iterable.contains(element);

  void forEach(void f(E element)) => iterable.forEach(f);

  E reduce(E combine(E value, E element)) => iterable.reduce(combine);

  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    return iterable.fold(initialValue, combine);
  }

  bool every(bool test(E element)) => iterable.every(test);

  String join([String separator = ""]) => iterable.join(separator);

  bool any(bool test(E element)) => iterable.any(test);

  List<E> toList({bool growable: true}) {
    return iterable.toList(growable: growable);
  }

  Set<E> toSet() => iterable.toSet();

  int get length => iterable.length;

  bool get isEmpty => iterable.isEmpty;

  bool get isNotEmpty => iterable.isNotEmpty;

  Iterable<E> take(int n) => iterable.take(n);

  Iterable<E> takeWhile(bool test(E value)) => iterable.takeWhile(test);

  Iterable<E> skip(int n) => iterable.skip(n);

  Iterable<E> skipWhile(bool test(E value)) => iterable.skipWhile(test);

  E get first => iterable.first;

  E get last => iterable.last;

  E get single => iterable.single;

  E firstWhere(bool test(E element), {E orElse()}) {
    return iterable.firstWhere(test, orElse: orElse);
  }

  E lastWhere(bool test(E element), {E orElse()}) {
    return iterable.lastWhere(test, orElse: orElse);
  }

  E singleWhere(bool test(E element)) => iterable.singleWhere(test);

  E elementAt(int index) => iterable.elementAt(index);

  String toString() => iterable.toString();
}

class DebugList<E> extends DebugIterable<E> implements List<E> {
  DebugCallback addCallback;
  DebugCallback addAllCallback;

  DebugList(List<E> list, {this.addCallback, this.addAllCallback})
      : super(list);

  List<E> get list => iterable;

  E operator [](int index) => list[index];

  void operator []=(int index, E value) {
    list[index] = value;
  }

  int get length => list.length;

  void set length(int newLength) {
    list.length = newLength;
  }

  void add(E value) {
    if (addCallback != null) {
      addCallback('add', value, null);
    }
    list.add(value);
  }

  void addAll(Iterable<E> iterable) {
    if (addAllCallback != null) {
      addAllCallback('addAll', iterable, null);
    }
    list.addAll(iterable);
  }

  Iterable<E> get reversed => list.reversed;

  void sort([int compare(E a, E b)]) => list.sort(compare);

  void shuffle([random]) => list.shuffle(random);

  int indexOf(E element, [int start = 0]) => list.indexOf(element, start);

  int lastIndexOf(E element, [int start]) => list.lastIndexOf(element, start);

  void clear() => list.clear();

  void insert(int index, E element) => list.insert(index, element);

  void insertAll(int index, Iterable<E> iterable) {
    list.insertAll(index, iterable);
  }

  void setAll(int index, Iterable<E> iterable) => list.setAll(index, iterable);

  bool remove(Object value) => list.remove(value);

  E removeAt(int index) => list.removeAt(index);

  E removeLast() => list.removeLast();

  void removeWhere(bool test(E element)) => list.removeWhere(test);

  void retainWhere(bool test(E element)) => list.retainWhere(test);

  List<E> sublist(int start, [int end]) => list.sublist(start, end);

  Iterable<E> getRange(int start, int end) => list.getRange(start, end);

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    list.setRange(start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    list.removeRange(start, end);
  }

  void fillRange(int start, int end, [E fillValue]) {
    list.fillRange(start, end, fillValue);
  }

  void replaceRange(int start, int end, Iterable<E> replacement) {
    list.replaceRange(start, end, replacement);
  }

  Map<int, E> asMap() => list.asMap();
}

class DebugSet<E> extends DebugIterable<E> implements Set<E> {
  DebugCallback addCallback;

  DebugSet(Set<E> set, {this.addCallback}) : super(set);

  Set<E> get set => iterable;

  bool contains(Object value) => set.contains(value);

  bool add(E value) {
    if (addCallback != null) {
      addCallback('add', value, null);
    }
    return set.add(value);
  }

  void addAll(Iterable<E> elements) {
    elements.forEach(add);
  }

  bool remove(Object value) => set.remove(value);

  E lookup(Object object) => set.lookup(object);

  void removeAll(Iterable<Object> elements) => set.removeAll(elements);

  void retainAll(Iterable<Object> elements) => set.retainAll(elements);

  void removeWhere(bool test(E element)) => set.removeWhere(test);

  void retainWhere(bool test(E element)) => set.retainWhere(test);

  bool containsAll(Iterable<Object> other) => set.containsAll(other);

  Set<E> intersection(Set<Object> other) => set.intersection(other);

  Set<E> union(Set<E> other) => set.union(other);

  Set<E> difference(Set<Object> other) => set.difference(other);

  void clear() => set.clear();

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
