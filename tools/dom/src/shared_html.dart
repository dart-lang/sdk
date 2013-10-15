// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

_wrapZone(callback) {
  // For performance reasons avoid wrapping if we are in the root zone.
  if (Zone.current == Zone.ROOT) return callback;
  return Zone.current.bindUnaryCallback(callback, runGuarded: true);
}

Element query(String selector) => document.query(selector);
ElementList queryAll(String selector) => document.queryAll(selector);
