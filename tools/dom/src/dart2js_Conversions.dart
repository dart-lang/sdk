// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Conversions for Window.  These check if the window is the local
// window, and if it's not, wraps or unwraps it with a secure wrapper.
// We need to test for EventTarget here as well as it's a base type.
// We omit an unwrapper for Window as no methods take a non-local
// window as a parameter.

part of html;

WindowBase _convertNativeToDart_Window(win) {
  if (win == null) return null;
  return _DOMWindowCrossFrame._createSafe(win);
}

EventTarget _convertNativeToDart_EventTarget(e) {
  if (e == null) {
    return null;
  }
  // Assume it's a Window if it contains the postMessage property.  It may be
  // from a different frame - without a patched prototype - so we cannot
  // rely on Dart type checking.
  if (JS('bool', r'"postMessage" in #', e)) {
    var window = _DOMWindowCrossFrame._createSafe(e);
    // If it's a native window.
    if (window is EventTarget) {
      return window;
    }
    return null;
  }
  else
    return e;
}

EventTarget _convertDartToNative_EventTarget(e) {
  if (e is _DOMWindowCrossFrame) {
    return e._window;
  } else {
    return e;
  }
}

_convertNativeToDart_XHR_Response(o) {
  if (o is Document) {
    return o;
  }
  return convertNativeToDart_SerializedScriptValue(o);
}
