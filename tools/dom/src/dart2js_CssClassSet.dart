// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

/**
 * A set (union) of the CSS classes that are present in a set of elements.
 * Implemented separately from _ElementCssClassSet for performance.
 */
class _MultiElementCssClassSet extends CssClassSetImpl {
  final Iterable<Element> _elementIterable;

  // TODO(sra): Perhaps we should store the DomTokenList instead.
  final List<CssClassSetImpl> _sets;

  factory _MultiElementCssClassSet(Iterable<Element> elements) {
    return new _MultiElementCssClassSet._(
        elements, elements.map((Element e) => e.classes).toList());
  }

  _MultiElementCssClassSet._(this._elementIterable, this._sets);

  Set<String> readClasses() {
    var s = new LinkedHashSet<String>();
    _sets.forEach((CssClassSetImpl e) => s.addAll(e.readClasses()));
    return s;
  }

  void writeClasses(Set<String> s) {
    var classes = s.join(' ');
    for (Element e in _elementIterable) {
      e.className = classes;
    }
  }

  /**
   * Helper method used to modify the set of css classes on this element.
   *
   *   f - callback with:
   *   s - a Set of all the css class name currently on this element.
   *
   *   After f returns, the modified set is written to the
   *       className property of this element.
   */
  modify(f(Set<String> s)) {
    _sets.forEach((CssClassSetImpl e) => e.modify(f));
  }

  /**
   * Adds the class [value] to the element if it is not on it, removes it if it
   * is.
   *
   * TODO(sra): It seems wrong to collect a 'changed' flag like this when the
   * underlying toggle returns an 'is set' flag.
   */
  bool toggle(String value, [bool shouldAdd]) => _sets.fold(
      false,
      (bool changed, CssClassSetImpl e) =>
          e.toggle(value, shouldAdd) || changed);

  /**
   * Remove the class [value] from element, and return true on successful
   * removal.
   *
   * This is the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   */
  bool remove(Object value) => _sets.fold(
      false, (bool changed, CssClassSetImpl e) => e.remove(value) || changed);
}

class _ElementCssClassSet extends CssClassSetImpl {
  final Element _element;

  _ElementCssClassSet(this._element);

  Set<String> readClasses() {
    var s = new LinkedHashSet<String>();
    var classname = _element.className;

    for (String name in classname.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty) {
        s.add(trimmed);
      }
    }
    return s;
  }

  void writeClasses(Set<String> s) {
    _element.className = s.join(' ');
  }

  int get length => _classListLength(_classListOf(_element));
  bool get isEmpty => length == 0;
  bool get isNotEmpty => length != 0;

  void clear() {
    _element.className = '';
  }

  bool contains(Object value) {
    return _contains(_element, value);
  }

  bool add(String value) {
    return _add(_element, value);
  }

  bool remove(Object value) {
    return value is String && _remove(_element, value);
  }

  bool toggle(String value, [bool shouldAdd]) {
    return _toggle(_element, value, shouldAdd);
  }

  void addAll(Iterable<String> iterable) {
    _addAll(_element, iterable);
  }

  void removeAll(Iterable<Object> iterable) {
    _removeAll(_element, iterable);
  }

  void retainAll(Iterable<Object> iterable) {
    _removeWhere(_element, iterable.toSet().contains, false);
  }

  void removeWhere(bool test(String name)) {
    _removeWhere(_element, test, true);
  }

  void retainWhere(bool test(String name)) {
    _removeWhere(_element, test, false);
  }

  static bool _contains(Element _element, Object value) {
    return value is String && _classListContains(_classListOf(_element), value);
  }

  @ForceInline()
  static bool _add(Element _element, String value) {
    DomTokenList list = _classListOf(_element);
    // Compute returned result independently of action upon the set.
    bool added = !_classListContainsBeforeAddOrRemove(list, value);
    _classListAdd(list, value);
    return added;
  }

  @ForceInline()
  static bool _remove(Element _element, String value) {
    DomTokenList list = _classListOf(_element);
    bool removed = _classListContainsBeforeAddOrRemove(list, value);
    _classListRemove(list, value);
    return removed;
  }

  static bool _toggle(Element _element, String value, bool shouldAdd) {
    // There is no value that can be passed as the second argument of
    // DomTokenList.toggle that behaves the same as passing one argument.
    // `null` is seen as false, meaning 'remove'.
    return shouldAdd == null
        ? _toggleDefault(_element, value)
        : _toggleOnOff(_element, value, shouldAdd);
  }

  static bool _toggleDefault(Element _element, String value) {
    DomTokenList list = _classListOf(_element);
    return _classListToggle1(list, value);
  }

  static bool _toggleOnOff(Element _element, String value, bool shouldAdd) {
    DomTokenList list = _classListOf(_element);
    // IE's toggle does not take a second parameter. We would prefer:
    //
    //    return _classListToggle2(list, value, shouldAdd);
    //
    if (shouldAdd) {
      _classListAdd(list, value);
      return true;
    } else {
      _classListRemove(list, value);
      return false;
    }
  }

  static void _addAll(Element _element, Iterable<String> iterable) {
    DomTokenList list = _classListOf(_element);
    for (String value in iterable) {
      _classListAdd(list, value);
    }
  }

  static void _removeAll(Element _element, Iterable<String> iterable) {
    DomTokenList list = _classListOf(_element);
    for (var value in iterable) {
      _classListRemove(list, value);
    }
  }

  static void _removeWhere(
      Element _element, bool test(String name), bool doRemove) {
    DomTokenList list = _classListOf(_element);
    int i = 0;
    while (i < _classListLength(list)) {
      String item = list.item(i);
      if (doRemove == test(item)) {
        _classListRemove(list, item);
      } else {
        ++i;
      }
    }
  }

  // A collection of static methods for DomTokenList. These methods are a
  // work-around for the lack of annotations to express the full behaviour of
  // the DomTokenList methods.

  static DomTokenList _classListOf(Element e) => JS(
      'returns:DomTokenList;creates:DomTokenList;effects:none;depends:all;',
      '#.classList',
      e);

  static int _classListLength(DomTokenList list) =>
      JS('returns:JSUInt31;effects:none;depends:all;', '#.length', list);

  static bool _classListContains(DomTokenList list, String value) =>
      JS('returns:bool;effects:none;depends:all', '#.contains(#)', list, value);

  static bool _classListContainsBeforeAddOrRemove(
          DomTokenList list, String value) =>
      // 'throws:never' is a lie, since 'contains' will throw on an illegal
      // token.  However, we always call this function immediately prior to
      // add/remove/toggle with the same token.  Often the result of 'contains'
      // is unused and the lie makes it possible for the 'contains' instruction
      // to be removed.
      JS('returns:bool;effects:none;depends:all;throws:null(1)',
          '#.contains(#)', list, value);

  static void _classListAdd(DomTokenList list, String value) {
    // list.add(value);
    JS('', '#.add(#)', list, value);
  }

  static void _classListRemove(DomTokenList list, String value) {
    // list.remove(value);
    JS('', '#.remove(#)', list, value);
  }

  static bool _classListToggle1(DomTokenList list, String value) {
    return JS('bool', '#.toggle(#)', list, value);
  }

  static bool _classListToggle2(
      DomTokenList list, String value, bool shouldAdd) {
    return JS('bool', '#.toggle(#, #)', list, value, shouldAdd);
  }
}
