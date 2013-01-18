// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

abstract class CssClassSet implements Set<String> {

  String toString() {
    return Strings.join(new List.from(readClasses()), ' ');
  }

  /**
   * Adds the class [token] to the element if it is not on it, removes it if it
   * is.
   */
  bool toggle(String value) {
    Set<String> s = readClasses();
    bool result = false;
    if (s.contains(value)) {
      s.remove(value);
    } else {
      s.add(value);
      result = true;
    }
    writeClasses(s);
    return result;
  }

  /**
   * Returns [:true:] if classes cannot be added or removed from this
   * [:CssClassSet:].
   */
  bool get frozen => false;

  // interface Iterable - BEGIN
  Iterator<String> get iterator => readClasses().iterator;
  // interface Iterable - END

  // interface Collection - BEGIN
  void forEach(void f(String element)) {
    readClasses().forEach(f);
  }

  String join([String separator]) => readClasses().join(separator);

  Iterable mappedBy(f(String element)) => readClasses().mappedBy(f);

  Iterable<String> where(bool f(String element)) => readClasses().where(f);

  bool every(bool f(String element)) => readClasses().every(f);

  bool any(bool f(String element)) => readClasses().any(f);

  bool get isEmpty => readClasses().isEmpty;

  int get length =>readClasses().length;

  dynamic reduce(dynamic initialValue,
      dynamic combine(dynamic previousValue, String element)) {
    return readClasses().reduce(initialValue, combine);
  }
  // interface Collection - END

  // interface Set - BEGIN
  bool contains(String value) => readClasses().contains(value);

  void add(String value) {
    // TODO - figure out if we need to do any validation here
    // or if the browser natively does enough.
    _modify((s) => s.add(value));
  }

  bool remove(Object value) {
    if (value is! String) return false;
    Set<String> s = readClasses();
    bool result = s.remove(value);
    writeClasses(s);
    return result;
  }

  void addAll(Iterable<String> iterable) {
    // TODO - see comment above about validation.
    _modify((s) => s.addAll(iterable));
  }

  void removeAll(Iterable<String> iterable) {
    _modify((s) => s.removeAll(iterable));
  }

  void retainAll(Iterable<String> iterable) {
    _modify((s) => s.retainAll(iterable));
  }

  void removeMatching(bool test(String name)) {
    _modify((s) => s.removeMatching(test));
  }

  void retainMatching(bool test(String name)) {
    _modify((s) => s.retainMatching(test));
  }

  bool isSubsetOf(Collection<String> collection) =>
    readClasses().isSubsetOf(collection);

  bool containsAll(Collection<String> collection) =>
    readClasses().containsAll(collection);

  Set<String> intersection(Collection<String> other) =>
    readClasses().intersection(other);

  String get first => readClasses().first;
  String get last => readClasses().last;
  String get single => readClasses().single;
  List<String> toList() => readClasses().toList();
  Set<String> toSet() => readClasses().toSet();
  String min([int compare(String a, String b)]) =>
      readClasses().min(compare);
  String max([int compare(String a, String b)]) =>
      readClasses().max(compare);
  Iterable<String> take(int n) => readClasses().take(n);
  Iterable<String> takeWhile(bool test(String value)) =>
      readClasses().takeWhile(test);
  Iterable<String> skip(int n) => readClasses().skip(n);
  Iterable<String> skipWhile(bool test(String value)) =>
      readClasses().skipWhile(test);
  String firstMatching(bool test(String value), { String orElse() }) =>
      readClasses().firstMatching(test, orElse: orElse);
  String lastMatching(bool test(String value), {String orElse()}) =>
      readClasses().lastMatching(test, orElse: orElse);
  String singleMatching(bool test(String value)) =>
      readClasses().singleMatching(test);
  String elementAt(int index) => readClasses().elementAt(index);

  void clear() {
    _modify((s) => s.clear());
  }
  // interface Set - END

  /**
   * Helper method used to modify the set of css classes on this element.
   *
   *   f - callback with:
   *      s - a Set of all the css class name currently on this element.
   *
   *   After f returns, the modified set is written to the
   *       className property of this element.
   */
  void _modify( f(Set<String> s)) {
    Set<String> s = readClasses();
    f(s);
    writeClasses(s);
  }

  /**
   * Read the class names from the Element class property,
   * and put them into a set (duplicates are discarded).
   * This is intended to be overridden by specific implementations.
   */
  Set<String> readClasses();

  /**
   * Join all the elements of a set into one string and write
   * back to the element.
   * This is intended to be overridden by specific implementations.
   */
  void writeClasses(Set<String> s);
}
