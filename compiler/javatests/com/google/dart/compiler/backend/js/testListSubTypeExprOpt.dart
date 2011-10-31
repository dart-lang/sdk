// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MyList<T> implements List<T> {
  MyList() { }
  T operator[](int index) { return null; }
  void operator[]=(int index, T value) {}
  int length;
  void add(T value) {}
  void addLast(T value) {}
  void addAll(Collection<T> collection) {}
  void sort(int f(T, T)) {}
  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {}
  int indexOf(T element, [int start = 0]) { return null; }
  int lastIndexOf(T element, [int start = null]) { return null; }
  void setRange(int start, int length, List from, [int startFrom = 0]) {}
  void removeRange(int start, int length) {}
  void insertRange(int start, int length, [initialValue = null]) {}
  List getRange(int start, int length) { return null; }
  void clear() {}
  T removeLast() { return null; }
  T last() { return null; }
  void forEach(void f(T)) {}
  Collection<T> filter(bool f(T)) { return null; }
  bool every(bool (T)) { return null; }
  bool some(bool f(T)) { return null; }
  bool isEmpty() { return null; }
  Iterator<T> iterator() { return null; }
}

class Main {
  static void main() {
    // List<T> subtype (we will do better in the future, for now, take the conservative path).
    MyList<String> _list0_ = new MyList<String>();
    _list0_[0] = "foo";
    String lhs0 = _list0_[0];
  }
}

main() {
  Main.main();
}
