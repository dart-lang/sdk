// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

// TODO(vsm): Unify with Dartium version.
class _DOMWindowCrossFrame implements Window {
  // Private window.  Note, this is a window in another frame, so it
  // cannot be typed as "Window" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _window;

  // Fields.
  History get history =>
    _HistoryCrossFrame._createSafe(JS('History', '#.history', _window));
  Location get location =>
    _LocationCrossFrame._createSafe(JS('Location', '#.location', _window));

  // TODO(vsm): Add frames to navigate subframes.  See 2312.

  bool get closed => JS('bool', '#.closed', _window);

  Window get opener => _createSafe(JS('Window', '#.opener', _window));

  Window get parent => _createSafe(JS('Window', '#.parent', _window));

  Window get top => _createSafe(JS('Window', '#.top', _window));

  // Methods.
  void focus() => JS('void', '#.focus()', _window);

  void blur() => JS('void', '#.blur()', _window);

  void close() => JS('void', '#.close()', _window);

  void postMessage(var message, String targetOrigin, [List messagePorts = null]) {
    if (messagePorts == null) {
      JS('void', '#.postMessage(#,#)', _window, message, targetOrigin);
    } else {
      JS('void', '#.postMessage(#,#,#)', _window, message, targetOrigin, messagePorts);
    }
  }

  // Implementation support.
  _DOMWindowCrossFrame(this._window);

  static Window _createSafe(w) {
    if (identical(w, window)) {
      return w;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _DOMWindowCrossFrame(w);
    }
  }
}

class _LocationCrossFrame implements Location {
  // Private location.  Note, this is a location object in another frame, so it
  // cannot be typed as "Location" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _location;

  void set href(String val) => _setHref(_location, val);
  static void _setHref(location, val) {
    JS('void', '#.href = #', location, val);
  }

  // Implementation support.
  _LocationCrossFrame(this._location);

  static Location _createSafe(location) {
    if (identical(location, window.location)) {
      return location;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _LocationCrossFrame(location);
    }
  }
}

class _HistoryCrossFrame implements History {
  // Private history.  Note, this is a history object in another frame, so it
  // cannot be typed as "History" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _history;

  void back() => JS('void', '#.back()', _history);

  void forward() => JS('void', '#.forward()', _history);

  void go(int distance) => JS('void', '#.go(#)', _history, distance);

  // Implementation support.
  _HistoryCrossFrame(this._history);

  static History _createSafe(h) {
    if (identical(h, window.history)) {
      return h;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _HistoryCrossFrame(h);
    }
  }
}
