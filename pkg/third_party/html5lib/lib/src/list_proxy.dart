// TODO(jmesserly): remove this once we have a subclassable growable list
// in our libraries.

/// A [List] proxy that you can subclass.
library list_proxy;

import 'dart:collection';
import 'dart:math' show Random;

// TOOD(jmesserly): this needs to be removed, but fixing NodeList is tricky.
class ListProxy<E> extends IterableBase<E> implements List<E> {

  /// The inner [List<T>] with the actual storage.
  final List<E> _list;

  /// Creates a list proxy.
  /// You can optionally specify the list to use for [storage] of the items,
  /// otherwise this will create a [List<E>].
  ListProxy([List<E> storage])
     : _list = storage != null ? storage : <E>[];

  // TODO(jmesserly): This should be on List.
  // See http://code.google.com/p/dart/issues/detail?id=947
  bool remove(E item) {
    int i = indexOf(item);
    if (i == -1) return false;
    removeAt(i);
    return true;
  }

  void insert(int index, E item) => _list.insert(index, item);

  // Override from Iterable to fix performance
  // Length and last become O(1) instead of O(N)
  // The others are just different constant factor.
  int get length => _list.length;
  E get last => _list.last;
  E get first => _list.first;
  E get single => _list.single;

  // From Iterable
  Iterator<E> get iterator => _list.iterator;

  // From List
  E operator [](int index) => _list[index];
  operator []=(int index, E value) { _list[index] = value; }
  set length(int value) { _list.length = value; }
  void add(E value) { _list.add(value); }

  void addLast(E value) { add(value); }
  void addAll(Iterable<E> collection) { _list.addAll(collection); }
  void sort([int compare(E a, E b)]) { _list.sort(compare); }
  void shuffle([Random random]) { _list.shuffle(random); }

  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);
  int lastIndexOf(E element, [int start]) => _list.lastIndexOf(element, start);
  void clear() { _list.clear(); }

  E removeAt(int index) => _list.removeAt(index);
  E removeLast() => _list.removeLast();

  void removeWhere(bool test(E element)) => _list.removeWhere(test);
  void retainWhere(bool test(E element)) => _list.retainWhere(test);

  List<E> sublist(int start, [int end]) => _list.sublist(start, end);

  List<E> getRange(int start, int end) => _list.getRange(start, end);

  void setRange(int start, int length, List<E> from, [int startFrom = 0]) {
    _list.setRange(start, length, from, startFrom);
  }
  void removeRange(int start, int length) { _list.removeRange(start, length); }
  void insertAll(int index, Iterable<E> iterable) {
    _list.insertAll(index, iterable);
  }

  Iterable<E> get reversed => _list.reversed;

  Map<int, E> asMap() => _list.asMap();

  void replaceRange(int start, int end, Iterable<E> newContents) =>
      _list.replaceRange(start, end, newContents);

  void setAll(int index, Iterable<E> iterable) => _list.setAll(index, iterable);

  void fillRange(int start, int end, [E fillValue])
      => _list.fillRange(start, end, fillValue);
}
