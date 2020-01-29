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
   *
   * If this corresponds to one element, returns `true` if [value] is present
   * after the operation, and returns `false` if [value] is absent after the
   * operation.
   *
   * If this corresponds to many elements, `null` is always returned.
   *
   * [value] must be a valid 'token' representing a single class, i.e. a
   * non-empty string containing no whitespace.  To toggle multiple classes, use
   * [toggleAll].
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
   *
   * [value] must be a valid 'token' representing a single class, i.e. a
   * non-empty string containing no whitespace.
   */
  bool contains(Object value);

  /**
   * Add the class [value] to element.
   *
   * [add] and [addAll] are the Dart equivalent of jQuery's
   * [addClass](http://api.jquery.com/addClass/).
   *
   * If this CssClassSet corresponds to one element. Returns true if [value] was
   * added to the set, otherwise false.
   *
   * If this corresponds to many elements, `null` is always returned.
   *
   * [value] must be a valid 'token' representing a single class, i.e. a
   * non-empty string containing no whitespace.  To add multiple classes use
   * [addAll].
   */
  bool add(String value);

  /**
   * Remove the class [value] from element, and return true on successful
   * removal.
   *
   * [remove] and [removeAll] are the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   *
   * [value] must be a valid 'token' representing a single class, i.e. a
   * non-empty string containing no whitespace.  To remove multiple classes, use
   * [removeAll].
   */
  bool remove(Object value);

  /**
   * Add all classes specified in [iterable] to element.
   *
   * [add] and [addAll] are the Dart equivalent of jQuery's
   * [addClass](http://api.jquery.com/addClass/).
   *
   * Each element of [iterable] must be a valid 'token' representing a single
   * class, i.e. a non-empty string containing no whitespace.
   */
  void addAll(Iterable<String> iterable);

  /**
   * Remove all classes specified in [iterable] from element.
   *
   * [remove] and [removeAll] are the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   *
   * Each element of [iterable] must be a valid 'token' representing a single
   * class, i.e. a non-empty string containing no whitespace.
   */
  void removeAll(Iterable<Object> iterable);

  /**
   * Toggles all classes specified in [iterable] on element.
   *
   * Iterate through [iterable]'s items, and add it if it is not on it, or
   * remove it if it is. This is the Dart equivalent of jQuery's
   * [toggleClass](http://api.jquery.com/toggleClass/).
   * If [shouldAdd] is true, then we always add all the classes in [iterable]
   * element. If [shouldAdd] is false then we always remove all the classes in
   * [iterable] from the element.
   *
   * Each element of [iterable] must be a valid 'token' representing a single
   * class, i.e. a non-empty string containing no whitespace.
   */
  void toggleAll(Iterable<String> iterable, [bool shouldAdd]);
}
