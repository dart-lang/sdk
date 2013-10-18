// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

/** A Set that stores the CSS class names for an element. */
abstract class CssClassSet implements Set<String> {

  /**
   * Adds the class [value] to the element if it is not on it, removes it if it
   * is.
   *
   * If [shouldAdd] is true, then we always add that [value] to the element. If
   * [shouldAdd] is false then we always remove [value] from the element.
   */
  bool toggle(String value, [bool shouldAdd]);

  /**
   * Returns [:true:] if classes cannot be added or removed from this
   * [:CssClassSet:].
   */
  bool get frozen;

  /**
   * Determine if this element contains the class [value].
   *
   * This is the Dart equivalent of jQuery's
   * [hasClass](http://api.jquery.com/hasClass/).
   */
  bool contains(String value);

  /**
   * Add the class [value] to element.
   *
   * This is the Dart equivalent of jQuery's
   * [addClass](http://api.jquery.com/addClass/).
   *
   * If this corresponds to one element. Returns `true` if [value] was added to
   * the set, otherwise `false`.
   *
   * If this corresponds to many elements, `null` is always returned.
   */
  bool add(String value);

  /**
   * Remove the class [value] from element, and return true on successful
   * removal.
   *
   * This is the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   */
  bool remove(Object value);

  /**
   * Add all classes specified in [iterable] to element.
   *
   * This is the Dart equivalent of jQuery's
   * [addClass](http://api.jquery.com/addClass/).
   */
  void addAll(Iterable<String> iterable);

  /**
   * Remove all classes specified in [iterable] from element.
   *
   * This is the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   */
  void removeAll(Iterable<String> iterable);

  /**
   * Toggles all classes specified in [iterable] on element.
   *
   * Iterate through [iterable]'s items, and add it if it is not on it, or
   * remove it if it is. This is the Dart equivalent of jQuery's
   * [toggleClass](http://api.jquery.com/toggleClass/).
   * If [shouldAdd] is true, then we always add all the classes in [iterable]
   * element. If [shouldAdd] is false then we always remove all the classes in
   * [iterable] from the element.
   */
  void toggleAll(Iterable<String> iterable, [bool shouldAdd]);
}

/**
 * A set (union) of the CSS classes that are present in a set of elements.
 * Implemented separately from _ElementCssClassSet for performance.
 */
class _MultiElementCssClassSet extends CssClassSetImpl {
  final Iterable<Element> _elementIterable;
  Iterable<_ElementCssClassSet> _elementCssClassSetIterable;

  _MultiElementCssClassSet(this._elementIterable) {
    _elementCssClassSetIterable = new List.from(_elementIterable).map(
        (e) => new _ElementCssClassSet(e));
  }

  Set<String> readClasses() {
    var s = new LinkedHashSet<String>();
    _elementCssClassSetIterable.forEach((e) => s.addAll(e.readClasses()));
    return s;
  }

  void writeClasses(Set<String> s) {
    var classes = new List.from(s).join(' ');
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
  modify( f(Set<String> s)) {
    _elementCssClassSetIterable.forEach((e) => e.modify(f));
  }

  /**
   * Adds the class [value] to the element if it is not on it, removes it if it
   * is.
   */
  bool toggle(String value, [bool shouldAdd]) =>
      _modifyWithReturnValue((e) => e.toggle(value, shouldAdd));

  /**
   * Remove the class [value] from element, and return true on successful
   * removal.
   *
   * This is the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   */
  bool remove(Object value) => _modifyWithReturnValue((e) => e.remove(value));

  bool _modifyWithReturnValue(f) => _elementCssClassSetIterable.fold(
      false, (prevValue, element) => f(element) || prevValue);
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
    List list = new List.from(s);
    _element.className = s.join(' ');
  }
}
