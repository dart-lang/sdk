/// Native wrappers for the Chrome Packaged App APIs.
///
/// These functions allow direct access to the Packaged App APIs, allowing
/// Chrome Packaged Apps to be written using Dart.
///
/// For more information on these APIs, see the
/// [Chrome APIs Documentation](http://developer.chrome.com/extensions/api_index.html)
library chrome;

import 'dart:_foreign_helper' show JS;
import 'dart:_js_helper';
import 'dart:html_common';
import 'dart:html';

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:chrome library.


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
      if (?callback) {
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
      if (?callback) {
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

class AppWindowCreateWindowOptions extends ChromeObject {
  /*
   * Public constructor
   */
  AppWindowCreateWindowOptions({String id, int defaultWidth, int defaultHeight, int defaultLeft, int defaultTop, int width, int height, int left, int top, int minWidth, int minHeight, int maxWidth, int maxHeight, String type, String frame, AppWindowBounds bounds, bool transparentBackground, bool hidden, bool singleton}) {
    if (?id)
      this.id = id;
    if (?defaultWidth)
      this.defaultWidth = defaultWidth;
    if (?defaultHeight)
      this.defaultHeight = defaultHeight;
    if (?defaultLeft)
      this.defaultLeft = defaultLeft;
    if (?defaultTop)
      this.defaultTop = defaultTop;
    if (?width)
      this.width = width;
    if (?height)
      this.height = height;
    if (?left)
      this.left = left;
    if (?top)
      this.top = top;
    if (?minWidth)
      this.minWidth = minWidth;
    if (?minHeight)
      this.minHeight = minHeight;
    if (?maxWidth)
      this.maxWidth = maxWidth;
    if (?maxHeight)
      this.maxHeight = maxHeight;
    if (?type)
      this.type = type;
    if (?frame)
      this.frame = frame;
    if (?bounds)
      this.bounds = bounds;
    if (?transparentBackground)
      this.transparentBackground = transparentBackground;
    if (?hidden)
      this.hidden = hidden;
    if (?singleton)
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
  /// same id (and no explicit size or position) is later opened.
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

  /// Minimum width of the window.
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

  /// Window type:  'shell' - the default window type  'panel' - a panel, managed
  /// by the OS (Currently experimental, Ash only)
  String get type => JS('String', '#.type', this._jsObject);

  void set type(String type) {
    JS('void', '#.type = #', this._jsObject, type);
  }

  /// Frame type: 'none' or 'chrome' (defaults to 'chrome').
  String get frame => JS('String', '#.frame', this._jsObject);

  void set frame(String frame) {
    JS('void', '#.frame = #', this._jsObject, frame);
  }

  /// Size of the content in the window (excluding the titlebar). If specified in
  /// addition to any of the left/top/width/height parameters, this field takes
  /// precedence. If a frameBounds is specified, the frameBounds take precedence.
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

  /// If true, the window will be created in a hidden state. Call show() on the
  /// window to show it once it has been created. Defaults to false.
  bool get hidden => JS('bool', '#.hidden', this._jsObject);

  void set hidden(bool hidden) {
    JS('void', '#.hidden = #', this._jsObject, hidden);
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

class AppWindowBounds extends ChromeObject {
  /*
   * Public constructor
   */
  AppWindowBounds({int left, int top, int width, int height}) {
    if (?left)
      this.left = left;
    if (?top)
      this.top = top;
    if (?width)
      this.width = width;
    if (?height)
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

  /// Minimize the window.
  void minimize() => JS('void', '#.minimize()', this._jsObject);

  /// Is the window minimized?
  void isMinimized() => JS('void', '#.isMinimized()', this._jsObject);

  /// Maximize the window.
  void maximize() => JS('void', '#.maximize()', this._jsObject);

  /// Is the window maximized?
  void isMaximized() => JS('void', '#.isMaximized()', this._jsObject);

  /// Restore the window.
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
  Event_app_window_onMaximized onMaximized;
  Event_app_window_onMinimized onMinimized;
  Event_app_window_onRestored onRestored;

  /*
   * Functions
   */
  /// The size and position of a window can be specified in a number of different
  /// ways. The most simple option is not specifying anything at all, in which
  /// case a default size and platform dependent position will be used.<br/><br/>
  /// Another option is to use the top/left and width/height properties, which
  /// will always put the window at the specified coordinates with the specified
  /// size.<br/><br/> Yet another option is to give the window a (unique) id.
  /// This id is then used to remember the size and position of the window
  /// whenever it is moved or resized. This size and position is then used
  /// instead of the specified bounds on subsequent opening of a window with the
  /// same id. If you need to open a window with an id at a location other than
  /// the remembered default, you can create it hidden, move it to the desired
  /// location, then show it.<br/><br/> You can also combine these various
  /// options, explicitly specifying for example the size while having the
  /// position be remembered or other combinations like that. Size and position
  /// are dealt with seperately, but individual coordinates are not. So if you
  /// specify a top (or left) coordinate, you should also specify a left (or top)
  /// coordinate, and similar for size.<br/><br/> If you specify both a regular
  /// and a default value for the same option the regular value is the only one
  /// that takes effect.
  // Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
  // for details. All rights reserved. Use of this source code is governed by a
  // BSD-style license that can be found in the LICENSE file.

  // TODO(sashab): This override is no longer needed once prefixes are removed.
  void create(String url,
              [AppWindowCreateWindowOptions options,
              void callback(AppWindowAppWindow created_window)]) {
    void __proxy_callback(created_window) {
      if (?callback)
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

class AppRuntimeIntent extends ChromeObject {
  /*
   * Private constructor
   */
  AppRuntimeIntent._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// The WebIntent being invoked.
  String get action => JS('String', '#.action', this._jsObject);

  void set action(String action) {
    JS('void', '#.action = #', this._jsObject, action);
  }

  /// The MIME type of the data.
  String get type => JS('String', '#.type', this._jsObject);

  void set type(String type) {
    JS('void', '#.type = #', this._jsObject, type);
  }

  /// Data associated with the intent.
  Object get data => JS('Object', '#.data', this._jsObject);

  void set data(Object data) {
    JS('void', '#.data = #', this._jsObject, convertArgument(data));
  }


  /*
   * Methods
   */
  /// Callback to be compatible with WebIntents.
  void postResult() => JS('void', '#.postResult()', this._jsObject);

  /// Callback to be compatible with WebIntents.
  void postFailure() => JS('void', '#.postFailure()', this._jsObject);

}

class AppRuntimeLaunchItem extends ChromeObject {
  /*
   * Public constructor
   */
  AppRuntimeLaunchItem({FileEntry entry, String type}) {
    if (?entry)
      this.entry = entry;
    if (?type)
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
  AppRuntimeLaunchData({AppRuntimeIntent intent, String id, List<AppRuntimeLaunchItem> items}) {
    if (?intent)
      this.intent = intent;
    if (?id)
      this.id = id;
    if (?items)
      this.items = items;
  }

  /*
   * Private constructor
   */
  AppRuntimeLaunchData._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  AppRuntimeIntent get intent => new AppRuntimeIntent._proxy(JS('', '#.intent', this._jsObject));

  void set intent(AppRuntimeIntent intent) {
    JS('void', '#.intent = #', this._jsObject, convertArgument(intent));
  }

  /// The id of the file handler that the app is being invoked with.
  String get id => JS('String', '#.id', this._jsObject);

  void set id(String id) {
    JS('void', '#.id = #', this._jsObject, id);
  }

  List<AppRuntimeLaunchItem> get items {
    List<AppRuntimeLaunchItem> __proxy_items = new List<AppRuntimeLaunchItem>();
    for (var o in JS('List', '#.items', this._jsObject)) {
      __proxy_items.add(new AppRuntimeLaunchItem._proxy(o));
    }
    return __proxy_items;
  }

  void set items(List<AppRuntimeLaunchItem> items) {
    JS('void', '#.items = #', this._jsObject, convertArgument(items));
  }

}

class AppRuntimeIntentResponse extends ChromeObject {
  /*
   * Public constructor
   */
  AppRuntimeIntentResponse({int intentId, bool success, Object data}) {
    if (?intentId)
      this.intentId = intentId;
    if (?success)
      this.success = success;
    if (?data)
      this.data = data;
  }

  /*
   * Private constructor
   */
  AppRuntimeIntentResponse._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// Identifies the intent.
  int get intentId => JS('int', '#.intentId', this._jsObject);

  void set intentId(int intentId) {
    JS('void', '#.intentId = #', this._jsObject, intentId);
  }

  /// Was this intent successful? (i.e., postSuccess vs postFailure).
  bool get success => JS('bool', '#.success', this._jsObject);

  void set success(bool success) {
    JS('void', '#.success = #', this._jsObject, success);
  }

  /// Data associated with the intent response.
  Object get data => JS('Object', '#.data', this._jsObject);

  void set data(Object data) {
    JS('void', '#.data = #', this._jsObject, convertArgument(data));
  }

}

/**
 * Events
 */

/// Fired when an app is launched from the launcher or in response to a web
/// intent.
class Event_app_runtime_onLaunched extends Event {
  void addListener(void callback(AppRuntimeLaunchData launchData)) {
    void __proxy_callback(launchData) {
      if (?callback) {
        callback(new AppRuntimeLaunchData._proxy(launchData));
      }
    }
    super.addListener(callback);
  }

  void removeListener(void callback(AppRuntimeLaunchData launchData)) {
    void __proxy_callback(launchData) {
      if (?callback) {
        callback(new AppRuntimeLaunchData._proxy(launchData));
      }
    }
    super.removeListener(callback);
  }

  bool hasListener(void callback(AppRuntimeLaunchData launchData)) {
    void __proxy_callback(launchData) {
      if (?callback) {
        callback(new AppRuntimeLaunchData._proxy(launchData));
      }
    }
    super.hasListener(callback);
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

  /*
   * Functions
   */
  /// postIntentResponse is an internal method to responds to an intent
  /// previously sent to a packaged app. This is identified by intentId, and
  /// should only be invoked at most once per intentId.
  void postIntentResponse(AppRuntimeIntentResponse intentResponse) => JS('void', '#.postIntentResponse(#)', this._jsObject, convertArgument(intentResponse));

  API_app_runtime(this._jsObject) {
    onLaunched = new Event_app_runtime_onLaunched(JS('', '#.onLaunched', this._jsObject));
    onRestarted = new Event_app_runtime_onRestarted(JS('', '#.onRestarted', this._jsObject));
  }
}
