// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generated from namespace: app.window

part of chrome;

/**
 * Types
 */

class AppWindowBounds extends ChromeObject {
  /*
   * Public constructor
   */
  AppWindowBounds({int left, int top, int width, int height}) {
    if (left != null) this.left = left;
    if (top != null) this.top = top;
    if (width != null) this.width = width;
    if (height != null) this.height = height;
  }

  /*
   * Private constructor
   */
  AppWindowBounds._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  int get left => JS('int', '#.left', this._jsObject);

  set left(int left) {
    JS('void', '#.left = #', this._jsObject, left);
  }

  int get top => JS('int', '#.top', this._jsObject);

  set top(int top) {
    JS('void', '#.top = #', this._jsObject, top);
  }

  int get width => JS('int', '#.width', this._jsObject);

  set width(int width) {
    JS('void', '#.width = #', this._jsObject, width);
  }

  int get height => JS('int', '#.height', this._jsObject);

  set height(int height) {
    JS('void', '#.height = #', this._jsObject, height);
  }
}

class AppWindowCreateWindowOptions extends ChromeObject {
  /*
   * Public constructor
   */
  AppWindowCreateWindowOptions(
      {String id,
      int defaultWidth,
      int defaultHeight,
      int defaultLeft,
      int defaultTop,
      int width,
      int height,
      int left,
      int top,
      int minWidth,
      int minHeight,
      int maxWidth,
      int maxHeight,
      String type,
      String frame,
      AppWindowBounds bounds,
      bool transparentBackground,
      String state,
      bool hidden,
      bool resizable,
      bool singleton}) {
    if (id != null) this.id = id;
    if (defaultWidth != null) this.defaultWidth = defaultWidth;
    if (defaultHeight != null) this.defaultHeight = defaultHeight;
    if (defaultLeft != null) this.defaultLeft = defaultLeft;
    if (defaultTop != null) this.defaultTop = defaultTop;
    if (width != null) this.width = width;
    if (height != null) this.height = height;
    if (left != null) this.left = left;
    if (top != null) this.top = top;
    if (minWidth != null) this.minWidth = minWidth;
    if (minHeight != null) this.minHeight = minHeight;
    if (maxWidth != null) this.maxWidth = maxWidth;
    if (maxHeight != null) this.maxHeight = maxHeight;
    if (type != null) this.type = type;
    if (frame != null) this.frame = frame;
    if (bounds != null) this.bounds = bounds;
    if (transparentBackground != null)
      this.transparentBackground = transparentBackground;
    if (state != null) this.state = state;
    if (hidden != null) this.hidden = hidden;
    if (resizable != null) this.resizable = resizable;
    if (singleton != null) this.singleton = singleton;
  }

  /*
   * Private constructor
   */
  AppWindowCreateWindowOptions._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// Id to identify the window. This will be used to remember the size and
  /// position of the window and restore that geometry when a window with the
  /// same id is later opened.
  String get id => JS('String', '#.id', this._jsObject);

  set id(String id) {
    JS('void', '#.id = #', this._jsObject, id);
  }

  /// Default width of the window. (Deprecated; regular bounds act like this
  /// now.)
  int get defaultWidth => JS('int', '#.defaultWidth', this._jsObject);

  set defaultWidth(int defaultWidth) {
    JS('void', '#.defaultWidth = #', this._jsObject, defaultWidth);
  }

  /// Default height of the window. (Deprecated; regular bounds act like this
  /// now.)
  int get defaultHeight => JS('int', '#.defaultHeight', this._jsObject);

  set defaultHeight(int defaultHeight) {
    JS('void', '#.defaultHeight = #', this._jsObject, defaultHeight);
  }

  /// Default X coordinate of the window. (Deprecated; regular bounds act like
  /// this now.)
  int get defaultLeft => JS('int', '#.defaultLeft', this._jsObject);

  set defaultLeft(int defaultLeft) {
    JS('void', '#.defaultLeft = #', this._jsObject, defaultLeft);
  }

  /// Default Y coordinate of the window. (Deprecated; regular bounds act like
  /// this now.)
  int get defaultTop => JS('int', '#.defaultTop', this._jsObject);

  set defaultTop(int defaultTop) {
    JS('void', '#.defaultTop = #', this._jsObject, defaultTop);
  }

  /// Width of the window. (Deprecated; use 'bounds'.)
  int get width => JS('int', '#.width', this._jsObject);

  set width(int width) {
    JS('void', '#.width = #', this._jsObject, width);
  }

  /// Height of the window. (Deprecated; use 'bounds'.)
  int get height => JS('int', '#.height', this._jsObject);

  set height(int height) {
    JS('void', '#.height = #', this._jsObject, height);
  }

  /// X coordinate of the window. (Deprecated; use 'bounds'.)
  int get left => JS('int', '#.left', this._jsObject);

  set left(int left) {
    JS('void', '#.left = #', this._jsObject, left);
  }

  /// Y coordinate of the window. (Deprecated; use 'bounds'.)
  int get top => JS('int', '#.top', this._jsObject);

  set top(int top) {
    JS('void', '#.top = #', this._jsObject, top);
  }

  /// Minimum width for the lifetime of the window.
  int get minWidth => JS('int', '#.minWidth', this._jsObject);

  set minWidth(int minWidth) {
    JS('void', '#.minWidth = #', this._jsObject, minWidth);
  }

  /// Minimum height for the lifetime of the window.
  int get minHeight => JS('int', '#.minHeight', this._jsObject);

  set minHeight(int minHeight) {
    JS('void', '#.minHeight = #', this._jsObject, minHeight);
  }

  /// Maximum width for the lifetime of the window.
  int get maxWidth => JS('int', '#.maxWidth', this._jsObject);

  set maxWidth(int maxWidth) {
    JS('void', '#.maxWidth = #', this._jsObject, maxWidth);
  }

  /// Maximum height for the lifetime of the window.
  int get maxHeight => JS('int', '#.maxHeight', this._jsObject);

  set maxHeight(int maxHeight) {
    JS('void', '#.maxHeight = #', this._jsObject, maxHeight);
  }

  /// Type of window to create.
  String get type => JS('String', '#.type', this._jsObject);

  set type(String type) {
    JS('void', '#.type = #', this._jsObject, type);
  }

  /// Frame type: 'none' or 'chrome' (defaults to 'chrome').
  String get frame => JS('String', '#.frame', this._jsObject);

  set frame(String frame) {
    JS('void', '#.frame = #', this._jsObject, frame);
  }

  /// Size and position of the content in the window (excluding the titlebar). If
  /// an id is also specified and a window with a matching id has been shown
  /// before, the remembered bounds of the window will be used instead.
  AppWindowBounds get bounds =>
      new AppWindowBounds._proxy(JS('', '#.bounds', this._jsObject));

  set bounds(AppWindowBounds bounds) {
    JS('void', '#.bounds = #', this._jsObject, convertArgument(bounds));
  }

  /// Enable window background transparency. Only supported in ash. Requires
  /// experimental API permission.
  bool get transparentBackground =>
      JS('bool', '#.transparentBackground', this._jsObject);

  set transparentBackground(bool transparentBackground) {
    JS('void', '#.transparentBackground = #', this._jsObject,
        transparentBackground);
  }

  /// The initial state of the window, allowing it to be created already
  /// fullscreen, maximized, or minimized. Defaults to 'normal'.
  String get state => JS('String', '#.state', this._jsObject);

  set state(String state) {
    JS('void', '#.state = #', this._jsObject, state);
  }

  /// If true, the window will be created in a hidden state. Call show() on the
  /// window to show it once it has been created. Defaults to false.
  bool get hidden => JS('bool', '#.hidden', this._jsObject);

  set hidden(bool hidden) {
    JS('void', '#.hidden = #', this._jsObject, hidden);
  }

  /// If true, the window will be resizable by the user. Defaults to true.
  bool get resizable => JS('bool', '#.resizable', this._jsObject);

  set resizable(bool resizable) {
    JS('void', '#.resizable = #', this._jsObject, resizable);
  }

  /// By default if you specify an id for the window, the window will only be
  /// created if another window with the same id doesn't already exist. If a
  /// window with the same id already exists that window is activated instead. If
  /// you do want to create multiple windows with the same id, you can set this
  /// property to false.
  bool get singleton => JS('bool', '#.singleton', this._jsObject);

  set singleton(bool singleton) {
    JS('void', '#.singleton = #', this._jsObject, singleton);
  }
}

class AppWindowAppWindow extends ChromeObject {
  /*
   * Private constructor
   */
  AppWindowAppWindow._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// The JavaScript 'window' object for the created child.
  // Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
  // for details. All rights reserved. Use of this source code is governed by a
  // BSD-style license that can be found in the LICENSE file.

  // TODO(sashab, sra): Detect whether this is the current window, or an
  // external one, and return an appropriately-typed object
  WindowBase get contentWindow =>
      JS("Window", "#.contentWindow", this._jsObject);

  /*
   * Methods
   */
  /// Focus the window.
  void focus() => JS('void', '#.focus()', this._jsObject);

  /// Fullscreens the window.
  void fullscreen() => JS('void', '#.fullscreen()', this._jsObject);

  /// Is the window fullscreen?
  bool isFullscreen() => JS('bool', '#.isFullscreen()', this._jsObject);

  /// Minimize the window.
  void minimize() => JS('void', '#.minimize()', this._jsObject);

  /// Is the window minimized?
  bool isMinimized() => JS('bool', '#.isMinimized()', this._jsObject);

  /// Maximize the window.
  void maximize() => JS('void', '#.maximize()', this._jsObject);

  /// Is the window maximized?
  bool isMaximized() => JS('bool', '#.isMaximized()', this._jsObject);

  /// Restore the window, exiting a maximized, minimized, or fullscreen state.
  void restore() => JS('void', '#.restore()', this._jsObject);

  /// Move the window to the position (|left|, |top|).
  void moveTo(int left, int top) =>
      JS('void', '#.moveTo(#, #)', this._jsObject, left, top);

  /// Resize the window to |width|x|height| pixels in size.
  void resizeTo(int width, int height) =>
      JS('void', '#.resizeTo(#, #)', this._jsObject, width, height);

  /// Draw attention to the window.
  void drawAttention() => JS('void', '#.drawAttention()', this._jsObject);

  /// Clear attention to the window.
  void clearAttention() => JS('void', '#.clearAttention()', this._jsObject);

  /// Close the window.
  void close() => JS('void', '#.close()', this._jsObject);

  /// Show the window. Does nothing if the window is already visible.
  void show() => JS('void', '#.show()', this._jsObject);

  /// Hide the window. Does nothing if the window is already hidden.
  void hide() => JS('void', '#.hide()', this._jsObject);

  /// Get the window's bounds as a $ref:Bounds object.
  // Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
  // for details. All rights reserved. Use of this source code is governed by a
  // BSD-style license that can be found in the LICENSE file.

  // TODO(sashab, kalman): Fix IDL parser to read function return values
  // correctly. Currently, it just reads void for all functions.
  AppWindowBounds getBounds() =>
      new AppWindowBounds._proxy(JS('void', '#.getBounds()', this._jsObject));

  /// Set the window's bounds.
  void setBounds(AppWindowBounds bounds) =>
      JS('void', '#.setBounds(#)', this._jsObject, convertArgument(bounds));

  /// Set the app icon for the window (experimental). Currently this is only
  /// being implemented on Ash. TODO(stevenjb): Investigate implementing this on
  /// Windows and OSX.
  void setIcon(String icon_url) =>
      JS('void', '#.setIcon(#)', this._jsObject, icon_url);
}

/**
 * Events
 */

/// Fired when the window is resized.
class Event_app_window_onBoundsChanged extends Event {
  void addListener(void callback()) => super.addListener(callback);

  void removeListener(void callback()) => super.removeListener(callback);

  bool hasListener(void callback()) => super.hasListener(callback);

  Event_app_window_onBoundsChanged(jsObject) : super._(jsObject, 0);
}

/// Fired when the window is closed.
class Event_app_window_onClosed extends Event {
  void addListener(void callback()) => super.addListener(callback);

  void removeListener(void callback()) => super.removeListener(callback);

  bool hasListener(void callback()) => super.hasListener(callback);

  Event_app_window_onClosed(jsObject) : super._(jsObject, 0);
}

/// Fired when the window is fullscreened.
class Event_app_window_onFullscreened extends Event {
  void addListener(void callback()) => super.addListener(callback);

  void removeListener(void callback()) => super.removeListener(callback);

  bool hasListener(void callback()) => super.hasListener(callback);

  Event_app_window_onFullscreened(jsObject) : super._(jsObject, 0);
}

/// Fired when the window is maximized.
class Event_app_window_onMaximized extends Event {
  void addListener(void callback()) => super.addListener(callback);

  void removeListener(void callback()) => super.removeListener(callback);

  bool hasListener(void callback()) => super.hasListener(callback);

  Event_app_window_onMaximized(jsObject) : super._(jsObject, 0);
}

/// Fired when the window is minimized.
class Event_app_window_onMinimized extends Event {
  void addListener(void callback()) => super.addListener(callback);

  void removeListener(void callback()) => super.removeListener(callback);

  bool hasListener(void callback()) => super.hasListener(callback);

  Event_app_window_onMinimized(jsObject) : super._(jsObject, 0);
}

/// Fired when the window is restored from being minimized or maximized.
class Event_app_window_onRestored extends Event {
  void addListener(void callback()) => super.addListener(callback);

  void removeListener(void callback()) => super.removeListener(callback);

  bool hasListener(void callback()) => super.hasListener(callback);

  Event_app_window_onRestored(jsObject) : super._(jsObject, 0);
}

/**
 * Functions
 */

class API_app_window {
  /*
   * API connection
   */
  Object _jsObject;

  /*
   * Events
   */
  Event_app_window_onBoundsChanged onBoundsChanged;
  Event_app_window_onClosed onClosed;
  Event_app_window_onFullscreened onFullscreened;
  Event_app_window_onMaximized onMaximized;
  Event_app_window_onMinimized onMinimized;
  Event_app_window_onRestored onRestored;

  /*
   * Functions
   */
  /// The size and position of a window can be specified in a number of different
  /// ways. The most simple option is not specifying anything at all, in which
  /// case a default size and platform dependent position will be used.<br/><br/>
  /// Another option is to use the bounds property, which will put the window at
  /// the specified coordinates with the specified size. If the window has a
  /// frame, it's total size will be the size given plus the size of the frame;
  /// that is, the size in bounds is the content size, not the window
  /// size.<br/><br/> To automatically remember the positions of windows you can
  /// give them ids. If a window has an id, This id is used to remember the size
  /// and position of the window whenever it is moved or resized. This size and
  /// position is then used instead of the specified bounds on subsequent opening
  /// of a window with the same id. If you need to open a window with an id at a
  /// location other than the remembered default, you can create it hidden, move
  /// it to the desired location, then show it.
  // Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
  // for details. All rights reserved. Use of this source code is governed by a
  // BSD-style license that can be found in the LICENSE file.

  // TODO(sashab): This override is no longer needed once prefixes are removed.
  void create(String url,
      [AppWindowCreateWindowOptions options,
      void callback(AppWindowAppWindow created_window)]) {
    void __proxy_callback(created_window) {
      if (callback != null)
        callback(new AppWindowAppWindow._proxy(created_window));
    }

    JS('void', '#.create(#, #, #)', this._jsObject, url,
        convertArgument(options), convertDartClosureToJS(__proxy_callback, 1));
  }

  /// Returns an $ref:AppWindow object for the current script context (ie
  /// JavaScript 'window' object). This can also be called on a handle to a
  /// script context for another page, for example:
  /// otherWindow.chrome.app.window.current().
  // Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
  // for details. All rights reserved. Use of this source code is governed by a
  // BSD-style license that can be found in the LICENSE file.

  // TODO(sashab, kalman): Fix IDL parser to read function return values
  // correctly. Currently, it just reads void for all functions.
  AppWindowAppWindow current() =>
      new AppWindowAppWindow._proxy(JS('void', '#.current()', this._jsObject));

  void initializeAppWindow(Object state) => JS('void',
      '#.initializeAppWindow(#)', this._jsObject, convertArgument(state));

  API_app_window(this._jsObject) {
    onBoundsChanged = new Event_app_window_onBoundsChanged(
        JS('', '#.onBoundsChanged', this._jsObject));
    onClosed =
        new Event_app_window_onClosed(JS('', '#.onClosed', this._jsObject));
    onFullscreened = new Event_app_window_onFullscreened(
        JS('', '#.onFullscreened', this._jsObject));
    onMaximized = new Event_app_window_onMaximized(
        JS('', '#.onMaximized', this._jsObject));
    onMinimized = new Event_app_window_onMinimized(
        JS('', '#.onMinimized', this._jsObject));
    onRestored =
        new Event_app_window_onRestored(JS('', '#.onRestored', this._jsObject));
  }
}
