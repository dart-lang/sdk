// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _interceptors;

/**
 * The interceptor class for [List]. The compiler recognizes this
 * class as an interceptor, and changes references to [:this:] to
 * actually use the receiver of the method, which is generated as an extra
 * argument added to each member.
 */
class JSArray<E> implements List<E> {
  const JSArray();

  void add(E value) {
    checkGrowable(this, 'add');
    JS('void', r'#.push(#)', this, value);
  }

  E removeAt(int index) {
    if (index is !int) throw new ArgumentError(index);
    if (index < 0 || index >= length) {
      throw new RangeError.value(index);
    }
    checkGrowable(this, 'removeAt');
    return JS('var', r'#.splice(#, 1)[0]', this, index);
  }

  E removeLast() {
    checkGrowable(this, 'removeLast');
    if (length == 0) throw new RangeError.value(-1);
    return JS('var', r'#.pop()', this);
  }

  List<E> filter(bool f(E element)) {
    return Collections.filter(this, <E>[], f);
  }

  void addAll(Collection<E> collection) {
    for (E e in collection) {
      this.add(e);
    }
  }

  void addLast(E value) {
    checkGrowable(this, 'addLast');
    JS('void', r'#.push(#)', this, value);
  }

  void clear() {
    length = 0;
  }

  void forEach(void f(E element)) {
    return Collections.forEach(this, f);
  }

  Collection map(f(E element)) {
    return Collections.map(this, [], f);
  }

  reduce(initialValue, combine(previousValue, E element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  List<E> getRange(int start, int length) {
    // TODO(ngeoffray): Parameterize the return value.
    if (0 == length) return [];
    checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
    checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
    if (start is !int) throw new ArgumentError(start);
    if (length is !int) throw new ArgumentError(length);
    if (length < 0) throw new ArgumentError(length);
    if (start < 0) throw new RangeError.value(start);
    int end = start + length;
    if (end > this.length) {
      throw new RangeError.value(length);
    }
    if (length < 0) throw new ArgumentError(length);
    return JS('List', r'#.slice(#, #)', this, start, end);
  }
}
