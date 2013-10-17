// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

_wrapZone(callback) {
  // For performance reasons avoid wrapping if we are in the root zone.
  if (Zone.current == Zone.ROOT) return callback;
  return Zone.current.bindUnaryCallback(callback, runGuarded: true);
}

_wrapBinaryZone(callback) {
  if (Zone.current == Zone.ROOT) return callback;
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

Element querySelector(String selector) => document.querySelector(selector);
ElementList querySelectorAll(String selector) => document.querySelectorAll(selector);
