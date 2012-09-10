// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(vsm): Unify with Dartium version.
class _DOMWindowCrossFrameImpl implements Window {
  // Private window.
  _WindowImpl _window;

  // Fields.
  // TODO(vsm): Implement history and location getters.

  // TODO(vsm): Add frames to navigate subframes.  See 2312.

  bool get closed => _closed(_window);
  static bool _closed(win) native "return win.closed;";

  Window get opener => _createSafe(_opener(_window));
  static Window _opener(win) native "return win.opener;";

  Window get parent => _createSafe(_parent(_window));
  static Window _parent(win) native "return win.parent;";

  Window get top => _createSafe(_top(_window));
  static Window _top(win) native "return win.top;";

  // Methods.
  void focus() => _focus(_window);
  static void _focus(win) native "win.focus()";

  void blur() => _blur(_window);
  static void _blur(win) native "win.blur()";

  void close() => _close(_window);
  static void _close(win) native "win.close()";

  void postMessage(Dynamic message,
                   String targetOrigin,
                   [List messagePorts = null]) {
    if (messagePorts == null) {
      _postMessage2(_window, message, targetOrigin);
    } else {
      _postMessage3(_window, message, targetOrigin, messagePorts);
    }
  }

  // TODO(vsm): This is a hack to workaround dartbug.com/3175.  We
  // need a more robust convention to invoke JS methods on the
  // underlying window.
  static void _postMessage2(win, message, targetOrigin) native """
    win.postMessage(message, targetOrigin);
""";

  static void _postMessage3(win, message, targetOrigin, messagePorts) native """
    win.postMessage(message, targetOrigin, messagePorts);
""";

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
