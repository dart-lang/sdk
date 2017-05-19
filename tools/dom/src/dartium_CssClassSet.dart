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
  Iterable<_ElementCssClassSet> _elementCssClassSetIterable;

  _MultiElementCssClassSet(this._elementIterable) {
    _elementCssClassSetIterable =
        new List.from(_elementIterable).map((e) => new _ElementCssClassSet(e));
  }

  Set<String> readClasses() {
    var s = new LinkedHashSet<String>();
    _elementCssClassSetIterable
        .forEach((_ElementCssClassSet e) => s.addAll(e.readClasses()));
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
    _elementCssClassSetIterable.forEach((_ElementCssClassSet e) => e.modify(f));
  }

  /**
   * Adds the class [value] to the element if it is not on it, removes it if it
   * is.
   */
  bool toggle(String value, [bool shouldAdd]) =>
      _elementCssClassSetIterable.fold(
          false,
          (bool changed, _ElementCssClassSet e) =>
              e.toggle(value, shouldAdd) || changed);

  /**
   * Remove the class [value] from element, and return true on successful
   * removal.
   *
   * This is the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   */
  bool remove(Object value) => _elementCssClassSetIterable.fold(false,
      (bool changed, _ElementCssClassSet e) => e.remove(value) || changed);
}

class _ElementCssClassSet extends CssClassSetImpl {
  final Element _element;

  _ElementCssClassSet(this._element);

  Set<String> readClasses() {
    var s = new LinkedHashSet<String>();
    var classname = _element.className;
    if (classname is svg.AnimatedString) {
      classname = classname.baseVal;
    }

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
}
