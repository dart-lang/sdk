// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// from app.window.idl
part of chrome;

/**
 * Types
 */
class CreateWindowOptions extends ChromeObject {
  /*
   * Public constructor
   */
  CreateWindowOptions({String id, int defaultWidth, int defaultHeight,
      int defaultLeft, int defaultTop, int width, int height, int left, int top,
      int minWidth, int minHeight, int maxWidth, int maxHeight, String type,
      String frame, Bounds bounds, bool hidden}) {
    this.id = id;
    this.defaultWidth = defaultWidth;
    this.defaultHeight = defaultHeight;
    this.defaultLeft = defaultLeft;
    this.defaultTop = defaultTop;
    this.width = width;
    this.height = height;
    this.left = left;
    this.top = top;
    this.minWidth = minWidth;
    this.minHeight = minHeight;
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    this.type = type;
    this.frame = frame;
    this.bounds = bounds;
    this.hidden = hidden;
  }

  /*
   * Private constructor
   */
  CreateWindowOptions._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// Id to identify the window. This will be used to remember the size
  /// and position of the window and restore that geometry when a window
  /// with the same id (and no explicit size or position) is later opened.
  String get id => JS('String', '#.id', this._jsObject);

  void set id(String id) {
    JS('void', '#.id = #', this._jsObject, id);
  }

  /// Default width of the window. (Deprecated; regular bounds act like this
  /// now.)
  int get defaultWidth => JS('int', '#.defaultWidth', this._jsObject);

  void set defaultWidth(int defaultWidth) {
    JS('void', '#.defaultWidth = #', this._jsObject, defaultWidth);
  }

  /// Default height of the window. (Deprecated; regular bounds act like this
  /// now.)
  int get defaultHeight => JS('int', '#.defaultHeight', this._jsObject);

  void set defaultHeight(int defaultHeight) {
    JS('void', '#.defaultHeight = #', this._jsObject, defaultHeight);
  }

  /// Default X coordinate of the window. (Deprecated; regular bounds act like
  /// this now.)
  int get defaultLeft => JS('int', '#.defaultLeft', this._jsObject);

  void set defaultLeft(int defaultLeft) {
    JS('void', '#.defaultLeft = #', this._jsObject, defaultLeft);
  }

  /// Default Y coordinate of the window. (Deprecated; regular bounds act like
  /// this now.)
  int get defaultTop => JS('int', '#.defaultTop', this._jsObject);

  void set defaultTop(int defaultTop) {
    JS('void', '#.defaultTop = #', this._jsObject, defaultTop);
  }

  /// Width of the window. (Deprecated; use 'bounds'.)
  int get width => JS('int', '#.width', this._jsObject);

  void set width(int width) {
    JS('void', '#.width = #', this._jsObject, width);
  }

  /// Height of the window. (Deprecated; use 'bounds'.)
  int get height => JS('int', '#.height', this._jsObject);

  void set height(int height) {
    JS('void', '#.height = #', this._jsObject, height);
  }

  /// X coordinate of the window. (Deprecated; use 'bounds'.)
  int get left => JS('int', '#.left', this._jsObject);

  void set left(int left) {
    JS('void', '#.left = #', this._jsObject, left);
  }

  /// Y coordinate of the window. (Deprecated; use 'bounds'.)
  int get top => JS('int', '#.top', this._jsObject);

  void set top(int top) {
    JS('void', '#.top = #', this._jsObject, top);
  }

  /// Minimium width of the window.
  int get minWidth => JS('int', '#.minWidth', this._jsObject);

  void set minWidth(int minWidth) {
    JS('void', '#.minWidth = #', this._jsObject, minWidth);
  }

  /// Minimum height of the window.
  int get minHeight => JS('int', '#.minHeight', this._jsObject);

  void set minHeight(int minHeight) {
    JS('void', '#.minHeight = #', this._jsObject, minHeight);
  }

  /// Maximum width of the window.
  int get maxWidth => JS('int', '#.maxWidth', this._jsObject);

  void set maxWidth(int maxWidth) {
    JS('void', '#.maxWidth = #', this._jsObject, maxWidth);
  }

  /// Maximum height of the window.
  int get maxHeight => JS('int', '#.maxHeight', this._jsObject);

  void set maxHeight(int maxHeight) {
    JS('void', '#.maxHeight = #', this._jsObject, maxHeight);
  }

  /// Window type: 'shell' (the default) is the only currently supported value.
  String get type => JS('String', '#.type', this._jsObject);

  void set type(String type) {
    JS('void', '#.type = #', this._jsObject, type);
  }

  /// Frame type: 'none' or 'chrome' (defaults to 'chrome').
  String get frame => JS('String', '#.frame', this._jsObject);

  void set frame(String frame) {
    JS('void', '#.frame = #', this._jsObject, frame);
  }

  /// Size of the content in the window (excluding the titlebar). If specified
  /// in addition to any of the left/top/width/height parameters, this field
  /// takes precedence. If a frameBounds is specified, the frameBounds take
  /// precedence.
  Bounds get bounds =>
      new Bounds._proxy(JS('Bounds', '#.bounds', this._jsObject));

  void set bounds(Bounds bounds) {
    JS('void', '#.bounds = #', this._jsObject, convertArgument(bounds));
  }

  /// If true, the window will be created in a hidden state. Call show() on
  /// the window to show it once it has been created. Defaults to false.
  bool get hidden => JS('bool', '#.hidden', this._jsObject);

  void set hidden(bool hidden) {
    JS('void', '#.hidden = #', this._jsObject, hidden);
  }
}

class Bounds extends ChromeObject {
  /*
   * Public constructor
   */
  Bounds({int left, int top, int width, int height}) {
    this.left = left;
    this.top = top;
    this.width = width;
    this.height = height;
  }

  /*
   * Private constructor
   */
  Bounds._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  int get left => JS('int', '#.left', this._jsObject);

  void set left(int left) {
    JS('void', '#.left = #', this._jsObject, left);
  }

  int get top => JS('int', '#.top', this._jsObject);

  void set top(int top) {
    JS('void', '#.top = #', this._jsObject, top);
  }

  int get width => JS('int', '#.width', this._jsObject);

  void set width(int width) {
    JS('void', '#.width = #', this._jsObject, width);
  }

  int get height => JS('int', '#.height', this._jsObject);

  void set height(int height) {
    JS('void', '#.height = #', this._jsObject, height);
  }
}

class AppWindow extends ChromeObject {
  /*
   * Public constructor
   * TODO(sashab): Does it make sense to be able to create a new AppWindow this
   * way?
   */
  //AppWindow();

  /*
   * Private constructor
   */
  AppWindow._proxy(jsObject) : super._proxy(jsObject);

  /*
   * Public accessors
   */
  /// The JavaScript 'window' object for the created child.
  // TODO(sashab, sra): Detect whether this is the current window, or an
  // external one, and return an appropriately-typed object
  WindowBase get contentWindow =>
      JS("Window", "#.contentWindow", this._jsObject);

  /*
   * Functions
   */

  /// Focus the window.
  void focus() => JS("void", "#.focus()", this._jsObject);

  /// Minimize the window.
  void minimize() => JS("void", "#.minimize()", this._jsObject);

  /// Is the window minimized?
  bool isMinimized() => JS("bool", "#.isMinimized()", this._jsObject);

  /// Maximize the window.
  void maximize() => JS("void", "#.maximize()", this._jsObject);

  /// Is the window maximized?
  bool isMaximized() => JS("bool", "c#.isMaximized()", this._jsObject);

  /// Restore the window.
  void restore() => JS("void", "#.restore()", this._jsObject);

  /// Move the window to the position (|left|, |top|).
  void moveTo(int left, int top) =>
      JS("void", "#.moveTo(#, #)", this._jsObject, left, top);

  /// Resize the window to |width|x|height| pixels in size.
  void resizeTo(int width, int height) =>
      JS("void", "#.resizeTo(#, #)", this._jsObject, width, height);

  /// Draw attention to the window.
  void drawAttention() => JS("void", "#.drawAttention()", this._jsObject);

  /// Clear attention to the window.
  void clearAttention() => JS("void", "#.clearAttention()", this._jsObject);

  /// Close the window.
  void close() => JS("void", "#.close()", this._jsObject);

  /// Show the window. Does nothing if the window is already visible.
  void show() => JS("void", "#.show()", this._jsObject);

  /// Hide the window. Does nothing if the window is already hidden.
  void hide() => JS("void", "#.hide()", this._jsObject);

  /// Set the window's bounds.
  void setBounds(Bounds bounds) =>
      JS("void", "#.setBounds(#)", this._jsObject, convertArgument(bounds));

}

/**
 * Functions
 */
class API_ChromeAppWindow {
  /**
   * JS object
   */
  Object _jsObject;

  /**
   * Constructor
   */
  API_ChromeAppWindow(this._jsObject);

  /**
   * Functions
   */

  /// Returns an <a href="#type-AppWindow">AppWindow</a> object for the
  /// current script context (ie JavaScript 'window' object). This can also be
  /// called on a handle to a script context for another page, for example:
  /// otherWindow.chrome.app.window.current().
  AppWindow current() =>
      new AppWindow._proxy(JS("Object", "#.current()", this._jsObject));

  /// The size and position of a window can be specified in a number of
  /// different ways. The most simple option is not specifying anything at
  /// all, in which case a default size and platform dependent position will
  /// be used.
  ///
  /// Another option is to use the top/left and width/height properties,
  /// which will always put the window at the specified coordinates with the
  /// specified size.
  ///
  /// Yet another option is to give the window a (unique) id. This id is then
  /// used to remember the size and position of the window whenever it is
  /// moved or resized. This size and position is then used instead of the
  /// specified bounds on subsequent opening of a window with the same id. If
  /// you need to open a window with an id at a location other than the
  /// remembered default, you can create it hidden, move it to the desired
  /// location, then show it.
  ///
  /// You can also combine these various options, explicitly specifying for
  /// example the size while having the position be remembered or other
  /// combinations like that. Size and position are dealt with seperately,
  /// but individual coordinates are not. So if you specify a top (or left)
  /// coordinate, you should also specify a left (or top) coordinate, and
  /// similar for size.
  ///
  /// If you specify both a regular and a default value for the same option
  /// the regular value is the only one that takes effect.
  void create(String url, [CreateWindowOptions options,
                           void callback(AppWindow created_window)]) {
    void __proxy_callback(Object created_window) {
      if (?callback)
        callback(new AppWindow._proxy(created_window));
    }

    JS("void", "#.create(#, #, #)",
       this._jsObject,
       url,
       convertArgument(options),
       convertDartClosureToJS(__proxy_callback, 1)
    );
  }
}