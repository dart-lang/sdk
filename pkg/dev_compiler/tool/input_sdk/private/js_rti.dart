// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_helper;

// TODO(leafp): Maybe get rid of this?  Currently used by the interceptors
// library, but that should probably be culled as well.
Type getRuntimeType(var object) =>
    JS('Type|null', 'dart.getReifiedType(#)', object);

/// Returns the property [index] of the JavaScript array [array].
getIndex(var array, int index) {
  assert_(isJsArray(array));
  return JS('var', r'#[#]', array, index);
}

/// Returns the length of the JavaScript array [array].
int getLength(var array) {
  assert_(isJsArray(array));
  return JS('int', r'#.length', array);
}

/// Returns whether [value] is a JavaScript array.
bool isJsArray(var value) {
  return value is JSArray;
}
