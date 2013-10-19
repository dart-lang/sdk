// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js;

import 'dart:nativewrappers';

JsObject _cachedContext;

JsObject get _context native "Js_context_Callback";

JsObject get context {
  if (_cachedContext == null) {
    _cachedContext = _context;
  }
  return _cachedContext;
}

class JsObject extends NativeFieldWrapperClass2 {
  JsObject.internal();

  factory JsObject(JsFunction constructor, [List arguments]) => _create(constructor, arguments);

  static JsObject _create(JsFunction constructor, arguments) native "JsObject_constructorCallback";

   /**
    * Expert users only:
    * Use this constructor only if you want to gain access to JS expandos
    * attached to a browser native object such as a Node.
    * Not all native browser objects can be converted using fromBrowserObject.
    * Currently the following types are supported:
    * * Node
    * * ArrayBuffer
    * * Blob
    * * ImageData
    * * IDBKeyRange
    * TODO(jacobr): support Event, Window and NodeList as well.
    */
  factory JsObject.fromBrowserObject(var object) {
    if (object is num || object is String || object is bool || object == null) {
      throw new ArgumentError(
        "object cannot be a num, string, bool, or null");
    }
    return _fromBrowserObject(object);
  }

  /**
   * Converts a json-like [object] to a JavaScript map or array and return a
   * [JsObject] to it.
   */
  factory JsObject.jsify(object) {
    if ((object is! Map) && (object is! Iterable)) {
      throw new ArgumentError("object must be a Map or Iterable");
    }
    return _jsify(object);
  }

  static JSObject _jsify(object) native "JsObject_jsify";

  static JsObject _fromBrowserObject(object) native "JsObject_fromBrowserObject";

  operator[](key) native "JsObject_[]";
  operator[]=(key, value) native "JsObject_[]=";

  int get hashCode native "JsObject_hashCode";

  operator==(other) => other is JsObject && _identityEquality(this, other);

  static bool _identityEquality(JsObject a, JsObject b) native "JsObject_identityEquality";

  bool hasProperty(String property) native "JsObject_hasProperty";

  void deleteProperty(JsFunction name) native "JsObject_deleteProperty";

  bool instanceof(JsFunction type) native "JsObject_instanceof";

  String toString() {
    try {
      return _toString();
    } catch(e) {
      return super.toString();
    }
  }

  String _toString() native "JsObject_toString";

  callMethod(String name, [List args]) {
    try {
      return _callMethod(name, args);
    } catch(e) {
      if (hasProperty(name)) {
        rethrow;
      } else {
        throw new NoSuchMethodError(this, new Symbol(name), args, null);
      }
    }
  }

  _callMethod(String name, List args) native "JsObject_callMethod";
}

class JsFunction extends JsObject {
  JsFunction.internal();

  /**
   * Returns a [JsFunction] that captures its 'this' binding and calls [f]
   * with the value of this passed as the first argument.
   */
  factory JsFunction.withThis(Function f) => _withThis(f);

  apply(List args, {thisArg}) native "JsFunction_apply";

  static JsFunction _withThis(Function f) native "JsFunction_withThis";
}
