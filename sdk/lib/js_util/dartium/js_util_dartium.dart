// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods to efficiently manipulate typed JSInterop objects in cases
/// where the name to call is not known at runtime. You should only use these
/// methods when the same effect cannot be achieved with @JS annotations.
/// These methods would be extension methods on JSObject if Dart supported
/// extension methods.
library dart.js_util;

import 'dart:js';

/// WARNING: performance of this method is much worse than other util
/// methods in this library. Only use this method as a last resort.
///
/// Recursively converts a JSON-like collection of Dart objects to a
/// collection of JavaScript objects and returns a [JsObject] proxy to it.
///
/// [object] must be a [Map] or [Iterable], the contents of which are also
/// converted. Maps and Iterables are copied to a new JavaScript object.
/// Primitives and other transferable values are directly converted to their
/// JavaScript type, and all other objects are proxied.
jsify(object) {
  if ((object is! Map) && (object is! Iterable)) {
    throw new ArgumentError("object must be a Map or Iterable");
  }
  return JsNative.jsify(object);
}

JSObject newObject() => JsNative.newObject();

hasProperty(JSObject o, name) => JsNative.hasProperty(o, name);
getProperty(JSObject o, name) => JsNative.getProperty(o, name);
setProperty(JSObject o, name, value) => JsNative.setProperty(o, name, value);
callMethod(JSObject o, String method, List args) =>
    JsNative.callMethod(o, method, args);
instanceof(JSObject o, Function type) => JsNative.instanceof(o, type);
callConstructor(JSObject constructor, List args) =>
    JsNative.callConstructor(constructor, args);
