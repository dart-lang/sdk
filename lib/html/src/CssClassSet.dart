// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO - figure out whether classList exists, and if so use that
// rather than the className property that is being used here.

class _CssClassSet implements Set<String> {

  final _element;

  _CssClassSet(this._element);

  String toString() {
    return _formatSet(_read());
  }

  // interface Iterable - BEGIN
  Iterator<String> iterator() {
    return _read().iterator();
  }
  // interface Iterable - END

  // interface Collection - BEGIN
  void forEach(void f(String element)) {
    _read().forEach(f);
  }

  Collection map(f(String element)) {
    return _read().map(f);
  }

  Collection<String> filter(bool f(String element)) {
    return _read().filter(f);
  }

  bool every(bool f(String element)) {
    return _read().every(f);
  }

  bool some(bool f(String element)) {
    return _read().some(f);
  }

  bool isEmpty() {
    return _read().isEmpty();
  }

  int get length {
    return _read().length;
  }
  // interface Collection - END

  // interface Set - BEGIN
  bool contains(String value) {
    return _read().contains(value);
  }

  void add(String value) {
    // TODO - figure out if we need to do any validation here
    // or if the browser natively does enough
    _modify((s) => s.add(value));
  }

  bool remove(String value) {
    Set<String> s = _read();
    bool result = s.remove(value);
    _write(s);
    return result;
  }

  void addAll(Collection<String> collection) {
    // TODO - see comment above about validation
    _modify((s) => s.addAll(collection));
  }

  void removeAll(Collection<String> collection) {
    _modify((s) => s.removeAll(collection));
  }

  bool isSubsetOf(Collection<String> collection) {
    return _read().isSubsetOf(collection);
  }

  bool containsAll(Collection<String> collection) {
    return _read().containsAll(collection);
  }

  Set<String> intersection(Collection<String> other) {
    return _read().intersection(other);
  }

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
    Set<String> s = _read();
    f(s);
    _write(s);
  }

  /**
   * Read the class names from the HTMLElement class property,
   * and put them into a set (duplicates are discarded).
   */
  Set<String> _read() {
    // TODO(mattsh) simplify this once split can take regex.
    Set<String> s = new Set<String>();
    for (String name in _className().split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty()) {
        s.add(trimmed);
      }
    }
    return s;
  }

  /**
   * Read the class names as a space-separated string. This is meant to be
   * overridden by subclasses.
   */
  String _className() => _element.className;

  /**
   * Join all the elements of a set into one string and write
   * back to the element.
   */
  void _write(Set s) {
    _element.className = _formatSet(s);
  }

  String _formatSet(Set<String> s) {
    // TODO(mattsh) should be able to pass Set to String.joins http:/b/5398605
    List list = new List.from(s);
    return Strings.join(list, ' ');
  }

}

