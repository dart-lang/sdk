// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

_wrapZone(callback(arg)) {
  // For performance reasons avoid wrapping if we are in the root zone.
  if (Zone.current == Zone.ROOT) return callback;
  if (callback == null) return null;
  return Zone.current.bindUnaryCallback(callback, runGuarded: true);
}

_wrapBinaryZone(callback(arg1, arg2)) {
  if (Zone.current == Zone.ROOT) return callback;
  if (callback == null) return null;
  return Zone.current.bindBinaryCallback(callback, runGuarded: true);
}

/**
 * Alias for [querySelector]. Note this function is deprecated because its
 * semantics will be changing in the future.
 */
@deprecated
@Experimental()
Element query(String relativeSelectors) => document.query(relativeSelectors);
/**
 * Alias for [querySelectorAll]. Note this function is deprecated because its
 * semantics will be changing in the future.
 */
@deprecated
@Experimental()
ElementList queryAll(String relativeSelectors) => document.queryAll(relativeSelectors);

/**
 * Finds the first descendant element of this document that matches the
 * specified group of selectors.
 *
 * Unless your webpage contains multiple documents, the top-level
 * [querySelector]
 * method behaves the same as this method, so you should use it instead to
 * save typing a few characters.
 *
 * [selectors] should be a string using CSS selector syntax.
 *
 *     var element1 = document.querySelector('.className');
 *     var element2 = document.querySelector('#id');
 *
 * For details about CSS selector syntax, see the
 * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
 */
Element querySelector(String selectors) => document.querySelector(selectors);

/**
 * Finds all descendant elements of this document that match the specified
 * group of selectors.
 *
 * Unless your webpage contains multiple documents, the top-level
 * [querySelectorAll]
 * method behaves the same as this method, so you should use it instead to
 * save typing a few characters.
 *
 * [selectors] should be a string using CSS selector syntax.
 *
 *     var items = document.querySelectorAll('.itemClassName');
 *
 * For details about CSS selector syntax, see the
 * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
 */
ElementList querySelectorAll(String selectors) => document.querySelectorAll(selectors);
