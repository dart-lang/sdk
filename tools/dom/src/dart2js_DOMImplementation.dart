// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

// TODO(vsm): Unify with Dartium version.
class _DOMWindowCrossFrame implements WindowBase {
  // Private window.  Note, this is a window in another frame, so it
  // cannot be typed as "Window" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  final _window;

  // Fields.
  HistoryBase get history =>
      _HistoryCrossFrame._createSafe(JS('HistoryBase', '#.history', _window));
  LocationBase get location => _LocationCrossFrame
      ._createSafe(JS('LocationBase', '#.location', _window));

  // TODO(vsm): Add frames to navigate subframes.  See 2312.

  bool get closed => JS('bool', '#.closed', _window);

  WindowBase get opener => _createSafe(JS('WindowBase', '#.opener', _window));

  WindowBase get parent => _createSafe(JS('WindowBase', '#.parent', _window));

  WindowBase get top => _createSafe(JS('WindowBase', '#.top', _window));

  // Methods.
  void close() => JS('void', '#.close()', _window);

  void postMessage(var message, String targetOrigin,
      [List messagePorts = null]) {
    if (messagePorts == null) {
      JS('void', '#.postMessage(#,#)', _window,
          convertDartToNative_SerializedScriptValue(message), targetOrigin);
    } else {
      JS(
          'void',
          '#.postMessage(#,#,#)',
          _window,
          convertDartToNative_SerializedScriptValue(message),
          targetOrigin,
          messagePorts);
    }
  }

  // Implementation support.
  _DOMWindowCrossFrame(this._window);

  static WindowBase _createSafe(w) {
    if (identical(w, window)) {
      return w;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _DOMWindowCrossFrame(w);
    }
  }

  // TODO(efortuna): Remove this method. dartbug.com/16814
  Events get on => throw new UnsupportedError(
      'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void _addEventListener(String type, EventListener listener,
          [bool useCapture]) =>
      throw new UnsupportedError(
          'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void addEventListener(String type, EventListener listener,
          [bool useCapture]) =>
      throw new UnsupportedError(
          'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  bool dispatchEvent(Event event) => throw new UnsupportedError(
      'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void _removeEventListener(String type, EventListener listener,
          [bool useCapture]) =>
      throw new UnsupportedError(
          'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void removeEventListener(String type, EventListener listener,
          [bool useCapture]) =>
      throw new UnsupportedError(
          'You can only attach EventListeners to your own window.');
}

class _LocationCrossFrame implements LocationBase {
  // Private location.  Note, this is a location object in another frame, so it
  // cannot be typed as "Location" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _location;

  set href(String val) => _setHref(_location, val);
  static void _setHref(location, val) {
    JS('void', '#.href = #', location, val);
  }

  // Implementation support.
  _LocationCrossFrame(this._location);

  static LocationBase _createSafe(location) {
    if (identical(location, window.location)) {
      return location;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _LocationCrossFrame(location);
    }
  }
}

class _HistoryCrossFrame implements HistoryBase {
  // Private history.  Note, this is a history object in another frame, so it
  // cannot be typed as "History" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _history;

  void back() => JS('void', '#.back()', _history);

  void forward() => JS('void', '#.forward()', _history);

  void go(int distance) => JS('void', '#.go(#)', _history, distance);

  // Implementation support.
  _HistoryCrossFrame(this._history);

  static HistoryBase _createSafe(h) {
    if (identical(h, window.history)) {
      return h;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _HistoryCrossFrame(h);
    }
  }
}
