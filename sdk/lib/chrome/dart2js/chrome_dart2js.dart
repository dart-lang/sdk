library chrome;

import 'dart:_foreign_helper' show JS;
import 'dart:html_common';
import 'dart:html';
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:chrome library.




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
  Object _jsObject;
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
  Object _jsObject;

  /*
   * Number of arguments the callback takes.
   */
  int _callbackArity;

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
  Object _jsObject;

  /*
   * Members
   */
  API_ChromeAppWindow window;
  API_ChromeAppRuntime runtime;

  /*
   * Constructor
   */
  API_ChromeApp(this._jsObject) {
    var window_object = JS('', '#.window', this._jsObject);
    if (window_object == null)
      throw new UnsupportedError('Not supported by current browser.');
    window = new API_ChromeAppWindow(window_object);

    var runtime_object = JS('', '#.runtime', this._jsObject);
    if (runtime_object == null)
      throw new UnsupportedError('Not supported by current browser.');
    runtime = new API_ChromeAppRuntime(runtime_object);
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

// from app_runtime.idl

/**
 * Types
 */

/// A WebIntents intent object. Deprecated.
class Intent extends ChromeObject {
  /*
   * Public (Dart) constructor
   */
  Intent({String action, String type, var data}) {
    this.action = action;
    this.type = type;
    this.data = data;
  }

  /*
   * Private (JS) constructor
   */
  Intent._proxy(_jsObject) : super._proxy(_jsObject);

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
  // TODO(sashab): What is the best way to serialize/return generic JS objects?
  Object get data => JS('Object', '#.data', this._jsObject);

  void set data(Object data) {
    JS('void', '#.data = #', this._jsObject, convertArgument(data));
  }

  /*
   * TODO(sashab): What is a NullCallback() type?
   * Add postResult and postFailure once understanding what this type is, and
   * once there is a way to pass functions back from JS.
   */
}

class LaunchItem extends ChromeObject {
  /*
   * Public constructor
   */
  LaunchItem({FileEntry entry, String type}) {
    this.entry = entry;
    this.type = type;
  }

  /*
   * Private constructor
   */
  LaunchItem._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */

  /// FileEntry for the file.
  FileEntry get entry => JS('FileEntry', '#.entry', this._jsObject);

  void set entry(FileEntry entry) {
    JS('void', '#.entry = #', this._jsObject, entry);
  }

  /// The MIME type of the file.
  String get type => JS('String', '#.type', this._jsObject);

  void set type(String type) {
    JS('void', '#.type = #', this._jsObject, type);
  }
}

/// Optional data for the launch.
class LaunchData extends ChromeObject {
  /*
   * Public constructor
   */
  LaunchData({Intent intent, String id, List<LaunchItem> items}) {
    this.intent = intent;
    this.id = id;
    this.items = items;
  }

  /*
   * Private constructor
   */
  LaunchData._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  Intent get intent => new Intent._proxy(JS('', '#.intent', this._jsObject));

  void set intent(Intent intent) {
    JS('void', '#.intent = #', this._jsObject, convertArgument(intent));
  }

  /// The id of the file handler that the app is being invoked with.
  String get id => JS('String', '#.id', this._jsObject);

  void set id(String id) {
    JS('void', '#.id = #', this._jsObject, id);
  }

  List<LaunchItem> get items() {
    List<LaunchItem> items_final = new List<LaunchItem>();
    for (var o in JS('List', '#.items', this._jsObject)) {
      items_final.add(new LaunchItem._proxy(o));
    }
    return items_final;
  }

  void set items(List<LaunchItem> items) {
    JS('void', '#.items = #', this._jsObject, convertArgument(items));
  }
}

class IntentResponse extends ChromeObject {
  /*
   * Public constructor
   */
  IntentResponse({int intentId, bool success, Object data}) {
    this.intentId = intentId;
    this.success = success;
    this.data = data;
  }

  /*
   * Private constructor
   */
  IntentResponse._proxy(_jsObject) : super._proxy(_jsObject);

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
  // TODO(sashab): What's the best way to serialize/return generic JS objects?
  Object get data => JS('Object', '#.data', this._jsObject);

  void set data(Object data) {
    JS('void', '#.data = #', this._jsObject, convertArgument(data));
  }
}

/**
 * Events
 */

/// Fired at Chrome startup to apps that were running when Chrome last shut
/// down.
class Event_ChromeAppRuntimeOnRestarted extends Event {
  /*
   * Override callback type definitions
   */
  void addListener(void callback())
      => super.addListener(callback);
  void removeListener(void callback())
      => super.removeListener(callback);
  bool hasListener(void callback())
      => super.hasListener(callback);

  /*
   * Constructor
   */
  Event_ChromeAppRuntimeOnRestarted(jsObject) : super._(jsObject, 0);
}

/// Fired when an app is launched from the launcher or in response to a web
/// intent.
class Event_ChromeAppRuntimeOnLaunched extends Event {
  /*
   * Override callback type definitions
   */
  void addListener(void callback(LaunchData launchData))
      => super.addListener(callback);
  void removeListener(void callback(LaunchData launchData))
      => super.removeListener(callback);
  bool hasListener(void callback(LaunchData launchData))
      => super.hasListener(callback);

  /*
   * Constructor
   */
  Event_ChromeAppRuntimeOnLaunched(jsObject) : super._(jsObject, 1);
}

/**
 * Functions
 */
class API_ChromeAppRuntime {
  /*
   * API connection
   */
  Object _jsObject;

  /*
   * Events
   */
  Event_ChromeAppRuntimeOnRestarted onRestarted;
  Event_ChromeAppRuntimeOnLaunched onLaunched;

  /*
   * Functions
   */
  void postIntentResponse(IntentResponse intentResponse) =>
    JS('void', '#.postIntentResponse(#)', this._jsObject,
        convertArgument(intentResponse));

  /*
   * Constructor
   */
  API_ChromeAppRuntime(this._jsObject) {
    onRestarted = new Event_ChromeAppRuntimeOnRestarted(JS('Object',
                                                           '#.onRestarted',
                                                           this._jsObject));
    onLaunched = new Event_ChromeAppRuntimeOnLaunched(JS('Object',
                                                         '#.onLaunched',
                                                         this._jsObject));
  }
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// from app.window.idl

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