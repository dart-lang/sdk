// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(vsm): Unify with Dartium version.
class _DOMWindowCrossFrameImpl implements DOMType, DOMWindow {
  // Private window.
  _DOMWindowJs _window;

  // DOMType
  var dartObjectLocalStorage;
  String get typeName() => "DOMWindow";

  // Fields.
  // TODO(vsm): Implement history and location getters.

  bool get closed() => _window.closed;
  int get length() => _window.length;
  DOMWindow get opener() => _createSafe(_window.opener);
  DOMWindow get parent() => _createSafe(_window.parent);
  DOMWindow get top() => _createSafe(_window.top);

  // Methods.
  void focus() => _window.focus();

  void blur() => _window.blur();

  void close() => _window.close();

  void postMessage(Dynamic message,
                   String targetOrigin,
                   [List messagePorts = null]) {
    if (messagePorts == null) {
      _window.postMessage(message, targetOrigin);
    } else {
      _window.postMessage(message, targetOrigin, messagePorts);
    }
  }

  // Implementation support.
  _DOMWindowCrossFrameImpl(this._window);

  static DOMWindow _createSafe(w) {
    if (w === window) {
      return w;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _DOMWindowCrossFrameImpl(w);
    }
  }
}
