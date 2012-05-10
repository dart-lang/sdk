// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(vsm): Unify with Dartium version.
class _DOMWindowCrossFrameImpl implements Window {
  // Private window.
  _WindowImpl _window;

  // Fields.
  // TODO(vsm): Implement history and location getters.

  bool get closed() => _window.closed;
  int get length() => _window.length;
  Window get opener() => _createSafe(_window.opener);
  Window get parent() => _createSafe(_window.parent);
  Window get top() => _createSafe(_window.top);

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

  static Window _createSafe(w) {
    if (w === window) {
      return w;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _DOMWindowCrossFrameImpl(w);
    }
  }
}
