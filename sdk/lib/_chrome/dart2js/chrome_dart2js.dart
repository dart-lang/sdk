/// Native wrappers for the Chrome packaged app APIs.
///
/// These functions allow direct access to the chrome.* APIs, allowing
/// Chrome packaged apps to be written using Dart.
///
/// For more information on these APIs, see the
/// [chrome.* API documentation](http://developer.chrome.com/apps/api_index.html).
library _chrome;

import 'dart:_foreign_helper' show JS;
import 'dart:_js_helper';
import 'dart:html_common';
import 'dart:html';

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:_chrome library.


/* TODO(sashab): Add "show convertDartClosureToJS" once 'show' works. */


// Generated files below this line.
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A set of utilities for use with the Chrome Extension APIs.
 *
 * Allows for easy access to required JS objects.
 */

/**
 * A dart object, that is convertible to JS. Used for creating objects in dart,
 * then passing them to JS.
 *
 * Objects that are passable to JS need to implement this interface.
 */
abstract class ChromeObject {
  /*
   * Default Constructor
   *
   * Called by child objects during their regular construction.
   */
  ChromeObject() : _jsObject = JS('var', '{}');

  /*
   * Internal proxy constructor
   *
   * Creates a new Dart object using this existing proxy.
   */
  ChromeObject._proxy(this._jsObject);

  /*
   * JS Object Representation
   */
  final Object _jsObject;
}

/**
 * Useful functions for converting arguments.
 */

/**
 * Converts the given map-type argument to js-friendly format, recursively.
 * Returns the new Map object.
 */
Object _convertMapArgument(Map argument) {
  Map m = new Map();
  for (Object key in argument.keys)
    m[key] = convertArgument(argument[key]);
  return convertDartToNative_Dictionary(m);
}

/**
 * Converts the given list-type argument to js-friendly format, recursively.
 * Returns the new List object.
 */
List _convertListArgument(List argument) {
  List l = new List();
  for (var i = 0; i < argument.length; i ++)
    l.add(convertArgument(argument[i]));
  return l;
}

/**
 * Converts the given argument Object to js-friendly format, recursively.
 *
 * Flattens out all Chrome objects into their corresponding ._toMap()
 * definitions, then converts them to JS objects.
 *
 * Returns the new argument.
 *
 * Cannot be used for functions.
 */
Object convertArgument(var argument) {
  if (argument == null)
    return argument;

  if (argument is num || argument is String || argument is bool)
    return argument;

  if (argument is ChromeObject)
    return argument._jsObject;

  if (argument is List)
    return _convertListArgument(argument);

  if (argument is Map)
    return _convertMapArgument(argument);

  if (argument is Function)
    throw new Exception("Cannot serialize Function argument ${argument}.");

  // TODO(sashab): Try and detect whether the argument is already serialized.
  return argument;
}

/// Description of a declarative rule for handling events.
class Rule extends ChromeObject {
  /*
   * Public (Dart) constructor
   */
  Rule({String id, List conditions, List actions, int priority}) {
    this.id = id;
    this.conditions = conditions;
    this.actions = actions;
    this.priority = priority;
  }

  /*
   * Private (JS) constructor
   */
  Rule._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  String get id => JS('String', '#.id', this._jsObject);

  void set id(String id) {
    JS('void', '#.id = #', this._jsObject, id);
  }

  // TODO(sashab): Wrap these generic Lists somehow.
  List get conditions => JS('List', '#.conditions', this._jsObject);

  void set conditions(List conditions) {
    JS('void', '#.conditions = #', this._jsObject, convertArgument(conditions));
  }

  // TODO(sashab): Wrap these generic Lists somehow.
  List get actions => JS('List', '#.actions', this._jsObject);

  void set actions(List actions) {
    JS('void', '#.actions = #', this._jsObject, convertArgument(actions));
  }

  int get priority => JS('int', '#.priority', this._jsObject);

  void set priority(int priority) {
    JS('void', '#.priority = #', this._jsObject, priority);
  }

}

/**
 * The Event class.
 *
 * Chrome Event classes extend this interface.
 *
 * e.g.
 *
 *  // chrome.app.runtime.onLaunched
 *  class Event_ChromeAppRuntimeOnLaunched extends Event {
 *    // constructor, passing the arity of the callback
 *    Event_ChromeAppRuntimeOnLaunched(jsObject) :
 *     super._(jsObject, 1);
 *
 *    // methods, strengthening the Function parameter specificity
 *    void addListener(void callback(LaunchData launchData))
 *        => super.addListener(callback);
 *    void removeListener(void callback(LaunchData launchData))
 *        => super.removeListener(callback);
 *    bool hasListener(void callback(LaunchData launchData))
 *        => super.hasListener(callback);
 *  }
 *
 */
class Event {
  /*
   * JS Object Representation
   */
  final Object _jsObject;

  /*
   * Number of arguments the callback takes.
   */
  final int _callbackArity;

  /*
   * Private constructor
   */
  Event._(this._jsObject, this._callbackArity);

  /*
   * Methods
   */

  /// Registers an event listener <em>callback</em> to an event.
  void addListener(Function callback) =>
      JS('void',
         '#.addListener(#)',
         this._jsObject,
         convertDartClosureToJS(callback, this._callbackArity)
      );

  /// Deregisters an event listener <em>callback</em> from an event.
  void removeListener(Function callback) =>
      JS('void',
         '#.removeListener(#)',
         this._jsObject,
         convertDartClosureToJS(callback, this._callbackArity)
      );

  /// Returns True if <em>callback</em> is registered to the event.
  bool hasListener(Function callback) =>
      JS('bool',
         '#.hasListener(#)',
         this._jsObject,
         convertDartClosureToJS(callback, this._callbackArity)
      );

  /// Returns true if any event listeners are registered to the event.
  bool hasListeners() =>
      JS('bool',
         '#.hasListeners()',
         this._jsObject
      );

  /// Registers rules to handle events.
  ///
  /// [eventName] is the name of the event this function affects and [rules] are
  /// the rules to be registered. These do not replace previously registered
  /// rules. [callback] is called with registered rules.
  ///
  void addRules(String eventName, List<Rule> rules,
                [void callback(List<Rule> rules)]) {
    // proxy the callback
    void __proxy_callback(List rules) {
      if (callback != null) {
        List<Rule> __proxy_rules = new List<Rule>();

        for (Object o in rules)
          __proxy_rules.add(new Rule._proxy(o));

        callback(__proxy_rules);
      }
    }

    JS('void',
       '#.addRules(#, #, #)',
       this._jsObject,
       convertArgument(eventName),
       convertArgument(rules),
       convertDartClosureToJS(__proxy_callback, 1)
    );
  }

  /// Returns currently registered rules.
  ///
  /// [eventName] is the name of the event this function affects and, if an array
  /// is passed as [ruleIdentifiers], only rules with identifiers contained in
  /// this array are returned. [callback] is called with registered rules.
  ///
  void getRules(String eventName, [List<String> ruleIdentifiers,
                                   void callback(List<Rule> rules)]) {
    // proxy the callback
    void __proxy_callback(List rules) {
      if (callback != null) {
        List<Rule> __proxy_rules = new List<Rule>();

        for (Object o in rules)
          __proxy_rules.add(new Rule._proxy(o));

        callback(__proxy_rules);
      }
    }

    JS('void',
       '#.getRules(#, #, #)',
       this._jsObject,
       convertArgument(eventName),
       convertArgument(ruleIdentifiers),
       convertDartClosureToJS(__proxy_callback, 1)
    );
  }

  /// Unregisters currently registered rules.
  ///
  /// [eventName] is the name of the event this function affects and, if an array
  /// is passed as [ruleIdentifiers], only rules with identifiers contained in
  /// this array are unregistered. [callback] is called when the rules are
  /// unregistered.
  ///
  void removeRules(String eventName, [List<String> ruleIdentifiers,
                                      void callback()]) =>
      JS('void',
         '#.removeRules(#, #, #)',
         this._jsObject,
         convertArgument(eventName),
         convertArgument(ruleIdentifiers),
         convertDartClosureToJS(callback, 0)
      );
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// chrome.app
class API_ChromeApp {
  /*
   * JS Variable
   */
  final Object _jsObject;

  /*
   * Members
   */
  API_app_window window;
  API_app_runtime runtime;

  /*
   * Constructor
   */
  API_ChromeApp(this._jsObject) {
    var window_object = JS('', '#.window', this._jsObject);
    if (window_object == null)
      throw new UnsupportedError('Not supported by current browser.');
    window = new API_app_window(window_object);

    var runtime_object = JS('', '#.runtime', this._jsObject);
    if (runtime_object == null)
      throw new UnsupportedError('Not supported by current browser.');
    runtime = new API_app_runtime(runtime_object);
  }
}

// chrome
class API_Chrome {
  /*
   * JS Variable
   */
  Object _jsObject;

  /*
   * Members
   */
  API_ChromeApp app;
  API_file_system fileSystem;

  /*
   * Constructor
   */
  API_Chrome() {
    this._jsObject = JS("Object", "chrome");
    if (this._jsObject == null)
      throw new UnsupportedError('Not supported by current browser.');

    var app_object = JS('', '#.app', this._jsObject);
    if (app_object == null)
      throw new UnsupportedError('Not supported by current browser.');
    app = new API_ChromeApp(app_object);

    var file_system_object = JS('', '#.fileSystem', this._jsObject);
    if (file_system_object == null)
      throw new UnsupportedError('Not supported by current browser.');
    fileSystem = new API_file_system(file_system_object);
  }
}

// The final chrome objects
final API_Chrome chrome = new API_Chrome();
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generated from namespace: app.window


/**
 * Types
 */

class AppWindowBounds extends ChromeObject {
  /*
   * Public constructor
   */
  AppWindowBounds({int left, int top, int width, int height}) {
    if (left != null)
      this.left = left;
    if (top != null)
      this.top = top;
    if (width != null)
      this.width = width;
    if (height != null)
      this.height = height;
  }

  /*
   * Private constructor
   */
  AppWindowBounds._proxy(_jsObject) : super._proxy(_jsObject);

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

class AppWindowCreateWindowOptions extends ChromeObject {
  /*
   * Public constructor
   */
  AppWindowCreateWindowOptions({String id, int defaultWidth, int defaultHeight, int defaultLeft, int defaultTop, int width, int height, int left, int top, int minWidth, int minHeight, int maxWidth, int maxHeight, String type, String frame, AppWindowBounds bounds, bool transparentBackground, String state, bool hidden, bool resizable, bool singleton}) {
    if (id != null)
      this.id = id;
    if (defaultWidth != null)
      this.defaultWidth = defaultWidth;
    if (defaultHeight != null)
      this.defaultHeight = defaultHeight;
    if (defaultLeft != null)
      this.defaultLeft = defaultLeft;
    if (defaultTop != null)
      this.defaultTop = defaultTop;
    if (width != null)
      this.width = width;
    if (height != null)
      this.height = height;
    if (left != null)
      this.left = left;
    if (top != null)
      this.top = top;
    if (minWidth != null)
      this.minWidth = minWidth;
    if (minHeight != null)
      this.minHeight = minHeight;
    if (maxWidth != null)
      this.maxWidth = maxWidth;
    if (maxHeight != null)
      this.maxHeight = maxHeight;
    if (type != null)
      this.type = type;
    if (frame != null)
      this.frame = frame;
    if (bounds != null)
      this.bounds = bounds;
    if (transparentBackground != null)
      this.transparentBackground = transparentBackground;
    if (state != null)
      this.state = state;
    if (hidden != null)
      this.hidden = hidden;
    if (resizable != null)
      this.resizable = resizable;
    if (singleton != null)
      this.singleton = singleton;
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

  /// Minimum width for the lifetime of the window.
  int get minWidth => JS('int', '#.minWidth', this._jsObject);

  void set minWidth(int minWidth) {
    JS('void', '#.minWidth = #', this._jsObject, minWidth);
  }

  /// Minimum height for the lifetime of the window.
  int get minHeight => JS('int', '#.minHeight', this._jsObject);

  void set minHeight(int minHeight) {
    JS('void', '#.minHeight = #', this._jsObject, minHeight);
  }

  /// Maximum width for the lifetime of the window.
  int get maxWidth => JS('int', '#.maxWidth', this._jsObject);

  void set maxWidth(int maxWidth) {
    JS('void', '#.maxWidth = #', this._jsObject, maxWidth);
  }

  /// Maximum height for the lifetime of the window.
  int get maxHeight => JS('int', '#.maxHeight', this._jsObject);

  void set maxHeight(int maxHeight) {
    JS('void', '#.maxHeight = #', this._jsObject, maxHeight);
  }

  /// Type of window to create.
  String get type => JS('String', '#.type', this._jsObject);

  void set type(String type) {
    JS('void', '#.type = #', this._jsObject, type);
  }

  /// Frame type: 'none' or 'chrome' (defaults to 'chrome').
  String get frame => JS('String', '#.frame', this._jsObject);

  void set frame(String frame) {
    JS('void', '#.frame = #', this._jsObject, frame);
  }

  /// Size and position of the content in the window (excluding the titlebar). If
  /// an id is also specified and a window with a matching id has been shown
  /// before, the remembered bounds of the window will be used instead.
  AppWindowBounds get bounds => new AppWindowBounds._proxy(JS('', '#.bounds', this._jsObject));

  void set bounds(AppWindowBounds bounds) {
    JS('void', '#.bounds = #', this._jsObject, convertArgument(bounds));
  }

  /// Enable window background transparency. Only supported in ash. Requires
  /// experimental API permission.
  bool get transparentBackground => JS('bool', '#.transparentBackground', this._jsObject);

  void set transparentBackground(bool transparentBackground) {
    JS('void', '#.transparentBackground = #', this._jsObject, transparentBackground);
  }

  /// The initial state of the window, allowing it to be created already
  /// fullscreen, maximized, or minimized. Defaults to 'normal'.
  String get state => JS('String', '#.state', this._jsObject);

  void set state(String state) {
    JS('void', '#.state = #', this._jsObject, state);
  }

  /// If true, the window will be created in a hidden state. Call show() on the
  /// window to show it once it has been created. Defaults to false.
  bool get hidden => JS('bool', '#.hidden', this._jsObject);

  void set hidden(bool hidden) {
    JS('void', '#.hidden = #', this._jsObject, hidden);
  }

  /// If true, the window will be resizable by the user. Defaults to true.
  bool get resizable => JS('bool', '#.resizable', this._jsObject);

  void set resizable(bool resizable) {
    JS('void', '#.resizable = #', this._jsObject, resizable);
  }

  /// By default if you specify an id for the window, the window will only be
  /// created if another window with the same id doesn't already exist. If a
  /// window with the same id already exists that window is activated instead. If
  /// you do want to create multiple windows with the same id, you can set this
  /// property to false.
  bool get singleton => JS('bool', '#.singleton', this._jsObject);

  void set singleton(bool singleton) {
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
  void moveTo(int left, int top) => JS('void', '#.moveTo(#, #)', this._jsObject, left, top);

  /// Resize the window to |width|x|height| pixels in size.
  void resizeTo(int width, int height) => JS('void', '#.resizeTo(#, #)', this._jsObject, width, height);

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
  void setBounds(AppWindowBounds bounds) => JS('void', '#.setBounds(#)', this._jsObject, convertArgument(bounds));

  /// Set the app icon for the window (experimental). Currently this is only
  /// being implemented on Ash. TODO(stevenjb): Investigate implementing this on
  /// Windows and OSX.
  void setIcon(String icon_url) => JS('void', '#.setIcon(#)', this._jsObject, icon_url);

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
    JS('void', '#.create(#, #, #)', this._jsObject, url, convertArgument(options),
       convertDartClosureToJS(__proxy_callback, 1));
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

  void initializeAppWindow(Object state) => JS('void', '#.initializeAppWindow(#)', this._jsObject, convertArgument(state));

  API_app_window(this._jsObject) {
    onBoundsChanged = new Event_app_window_onBoundsChanged(JS('', '#.onBoundsChanged', this._jsObject));
    onClosed = new Event_app_window_onClosed(JS('', '#.onClosed', this._jsObject));
    onFullscreened = new Event_app_window_onFullscreened(JS('', '#.onFullscreened', this._jsObject));
    onMaximized = new Event_app_window_onMaximized(JS('', '#.onMaximized', this._jsObject));
    onMinimized = new Event_app_window_onMinimized(JS('', '#.onMinimized', this._jsObject));
    onRestored = new Event_app_window_onRestored(JS('', '#.onRestored', this._jsObject));
  }
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generated from namespace: app.runtime


/**
 * Types
 */

class AppRuntimeLaunchItem extends ChromeObject {
  /*
   * Public constructor
   */
  AppRuntimeLaunchItem({FileEntry entry, String type}) {
    if (entry != null)
      this.entry = entry;
    if (type != null)
      this.type = type;
  }

  /*
   * Private constructor
   */
  AppRuntimeLaunchItem._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// FileEntry for the file.
  FileEntry get entry => JS('FileEntry', '#.entry', this._jsObject);

  void set entry(FileEntry entry) {
    JS('void', '#.entry = #', this._jsObject, convertArgument(entry));
  }

  /// The MIME type of the file.
  String get type => JS('String', '#.type', this._jsObject);

  void set type(String type) {
    JS('void', '#.type = #', this._jsObject, type);
  }

}

class AppRuntimeLaunchData extends ChromeObject {
  /*
   * Public constructor
   */
  AppRuntimeLaunchData({String id, List<AppRuntimeLaunchItem> items}) {
    if (id != null)
      this.id = id;
    if (items != null)
      this.items = items;
  }

  /*
   * Private constructor
   */
  AppRuntimeLaunchData._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// The id of the file handler that the app is being invoked with.
  String get id => JS('String', '#.id', this._jsObject);

  void set id(String id) {
    JS('void', '#.id = #', this._jsObject, id);
  }

  List<AppRuntimeLaunchItem> get items {
    List<AppRuntimeLaunchItem> __proxy_items = new List<AppRuntimeLaunchItem>();
    int count = JS('int', '#.items.length', this._jsObject);
    for (int i = 0; i < count; i++) {
      var item = JS('', '#.items[#]', this._jsObject, i);
      __proxy_items.add(new AppRuntimeLaunchItem._proxy(item));
    }
    return __proxy_items;
  }

  void set items(List<AppRuntimeLaunchItem> items) {
    JS('void', '#.items = #', this._jsObject, convertArgument(items));
  }

}

/**
 * Events
 */

/// Fired when an app is launched from the launcher.
class Event_app_runtime_onLaunched extends Event {
  void addListener(void callback(AppRuntimeLaunchData launchData)) {
    void __proxy_callback(launchData) {
      if (callback != null) {
        callback(new AppRuntimeLaunchData._proxy(launchData));
      }
    }
    super.addListener(__proxy_callback);
  }

  void removeListener(void callback(AppRuntimeLaunchData launchData)) {
    void __proxy_callback(launchData) {
      if (callback != null) {
        callback(new AppRuntimeLaunchData._proxy(launchData));
      }
    }
    super.removeListener(__proxy_callback);
  }

  bool hasListener(void callback(AppRuntimeLaunchData launchData)) {
    void __proxy_callback(launchData) {
      if (callback != null) {
        callback(new AppRuntimeLaunchData._proxy(launchData));
      }
    }
    super.hasListener(__proxy_callback);
  }

  Event_app_runtime_onLaunched(jsObject) : super._(jsObject, 1);
}

/// Fired at Chrome startup to apps that were running when Chrome last shut
/// down.
class Event_app_runtime_onRestarted extends Event {
  void addListener(void callback()) => super.addListener(callback);

  void removeListener(void callback()) => super.removeListener(callback);

  bool hasListener(void callback()) => super.hasListener(callback);

  Event_app_runtime_onRestarted(jsObject) : super._(jsObject, 0);
}

/**
 * Functions
 */

class API_app_runtime {
  /*
   * API connection
   */
  Object _jsObject;

  /*
   * Events
   */
  Event_app_runtime_onLaunched onLaunched;
  Event_app_runtime_onRestarted onRestarted;
  API_app_runtime(this._jsObject) {
    onLaunched = new Event_app_runtime_onLaunched(JS('', '#.onLaunched', this._jsObject));
    onRestarted = new Event_app_runtime_onRestarted(JS('', '#.onRestarted', this._jsObject));
  }
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generated from namespace: fileSystem


/**
 * Types
 */

class FilesystemAcceptOption extends ChromeObject {
  /*
   * Public constructor
   */
  FilesystemAcceptOption({String description, List<String> mimeTypes, List<String> extensions}) {
    if (description != null)
      this.description = description;
    if (mimeTypes != null)
      this.mimeTypes = mimeTypes;
    if (extensions != null)
      this.extensions = extensions;
  }

  /*
   * Private constructor
   */
  FilesystemAcceptOption._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// This is the optional text description for this option. If not present, a
  /// description will be automatically generated; typically containing an
  /// expanded list of valid extensions (e.g. "text/html" may expand to "*.html,
  /// *.htm").
  String get description => JS('String', '#.description', this._jsObject);

  void set description(String description) {
    JS('void', '#.description = #', this._jsObject, description);
  }

  /// Mime-types to accept, e.g. "image/jpeg" or "audio/*". One of mimeTypes or
  /// extensions must contain at least one valid element.
  List<String> get mimeTypes => JS('List<String>', '#.mimeTypes', this._jsObject);

  void set mimeTypes(List<String> mimeTypes) {
    JS('void', '#.mimeTypes = #', this._jsObject, mimeTypes);
  }

  /// Extensions to accept, e.g. "jpg", "gif", "crx".
  List<String> get extensions => JS('List<String>', '#.extensions', this._jsObject);

  void set extensions(List<String> extensions) {
    JS('void', '#.extensions = #', this._jsObject, extensions);
  }

}

class FilesystemChooseEntryOptions extends ChromeObject {
  /*
   * Public constructor
   */
  FilesystemChooseEntryOptions({String type, String suggestedName, List<FilesystemAcceptOption> accepts, bool acceptsAllTypes}) {
    if (type != null)
      this.type = type;
    if (suggestedName != null)
      this.suggestedName = suggestedName;
    if (accepts != null)
      this.accepts = accepts;
    if (acceptsAllTypes != null)
      this.acceptsAllTypes = acceptsAllTypes;
  }

  /*
   * Private constructor
   */
  FilesystemChooseEntryOptions._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// Type of the prompt to show. The default is 'openFile'.
  String get type => JS('String', '#.type', this._jsObject);

  void set type(String type) {
    JS('void', '#.type = #', this._jsObject, type);
  }

  /// The suggested file name that will be presented to the user as the default
  /// name to read or write. This is optional.
  String get suggestedName => JS('String', '#.suggestedName', this._jsObject);

  void set suggestedName(String suggestedName) {
    JS('void', '#.suggestedName = #', this._jsObject, suggestedName);
  }

  /// The optional list of accept options for this file opener. Each option will
  /// be presented as a unique group to the end-user.
  List<FilesystemAcceptOption> get accepts {
    List<FilesystemAcceptOption> __proxy_accepts = new List<FilesystemAcceptOption>();
    int count = JS('int', '#.accepts.length', this._jsObject);
    for (int i = 0; i < count; i++) {
      var item = JS('', '#.accepts[#]', this._jsObject, i);
      __proxy_accepts.add(new FilesystemAcceptOption._proxy(item));
    }
    return __proxy_accepts;
  }

  void set accepts(List<FilesystemAcceptOption> accepts) {
    JS('void', '#.accepts = #', this._jsObject, convertArgument(accepts));
  }

  /// Whether to accept all file types, in addition to the options specified in
  /// the accepts argument. The default is true. If the accepts field is unset or
  /// contains no valid entries, this will always be reset to true.
  bool get acceptsAllTypes => JS('bool', '#.acceptsAllTypes', this._jsObject);

  void set acceptsAllTypes(bool acceptsAllTypes) {
    JS('void', '#.acceptsAllTypes = #', this._jsObject, acceptsAllTypes);
  }

}

/**
 * Functions
 */

class API_file_system {
  /*
   * API connection
   */
  Object _jsObject;

  /*
   * Functions
   */
  /// Get the display path of a FileEntry object. The display path is based on
  /// the full path of the file on the local file system, but may be made more
  /// readable for display purposes.
  void getDisplayPath(FileEntry fileEntry, void callback(String displayPath)) => JS('void', '#.getDisplayPath(#, #)', this._jsObject, convertArgument(fileEntry), convertDartClosureToJS(callback, 1));

  /// Get a writable FileEntry from another FileEntry. This call will fail if the
  /// application does not have the 'write' permission under 'fileSystem'.
  void getWritableEntry(FileEntry fileEntry, void callback(FileEntry fileEntry)) {
    void __proxy_callback(fileEntry) {
      if (callback != null) {
        callback(fileEntry);
      }
    }
    JS('void', '#.getWritableEntry(#, #)', this._jsObject, convertArgument(fileEntry), convertDartClosureToJS(__proxy_callback, 1));
  }

  /// Gets whether this FileEntry is writable or not.
  void isWritableEntry(FileEntry fileEntry, void callback(bool isWritable)) => JS('void', '#.isWritableEntry(#, #)', this._jsObject, convertArgument(fileEntry), convertDartClosureToJS(callback, 1));

  /// Ask the user to choose a file.
  void chooseEntry(void callback(FileEntry fileEntry), [FilesystemChooseEntryOptions options]) {
    void __proxy_callback(fileEntry) {
      if (callback != null) {
        callback(fileEntry);
      }
    }
    JS('void', '#.chooseEntry(#, #)', this._jsObject, convertArgument(options), convertDartClosureToJS(__proxy_callback, 1));
  }

  /// Returns the file entry with the given id if it can be restored. This call
  /// will fail otherwise.
  void restoreEntry(String id, void callback(FileEntry fileEntry)) {
    void __proxy_callback(fileEntry) {
      if (callback != null) {
        callback(fileEntry);
      }
    }
    JS('void', '#.restoreEntry(#, #)', this._jsObject, id, convertDartClosureToJS(__proxy_callback, 1));
  }

  /// Returns whether a file entry for the given id can be restored, i.e. whether
  /// restoreEntry would succeed with this id now.
  void isRestorable(String id, void callback(bool isRestorable)) => JS('void', '#.isRestorable(#, #)', this._jsObject, id, convertDartClosureToJS(callback, 1));

  /// Returns an id that can be passed to restoreEntry to regain access to a
  /// given file entry. Only the 500 most recently used entries are retained,
  /// where calls to retainEntry and restoreEntry count as use. If the app has
  /// the 'retainEntries' permission under 'fileSystem', entries are retained
  /// indefinitely. Otherwise, entries are retained only while the app is running
  /// and across restarts.
  String retainEntry(FileEntry fileEntry) => JS('String', '#.retainEntry(#)', this._jsObject, convertArgument(fileEntry));

  API_file_system(this._jsObject) {
  }
}
