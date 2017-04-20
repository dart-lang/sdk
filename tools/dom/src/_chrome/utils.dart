// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A set of utilities for use with the Chrome Extension APIs.
 *
 * Allows for easy access to required JS objects.
 */
part of chrome;

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
  for (Object key in argument.keys) m[key] = convertArgument(argument[key]);
  return convertDartToNative_Dictionary(m);
}

/**
 * Converts the given list-type argument to js-friendly format, recursively.
 * Returns the new List object.
 */
List _convertListArgument(List argument) {
  List l = new List();
  for (var i = 0; i < argument.length; i++) l.add(convertArgument(argument[i]));
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
  if (argument == null) return argument;

  if (argument is num || argument is String || argument is bool)
    return argument;

  if (argument is ChromeObject) return argument._jsObject;

  if (argument is List) return _convertListArgument(argument);

  if (argument is Map) return _convertMapArgument(argument);

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

  set id(String id) {
    JS('void', '#.id = #', this._jsObject, id);
  }

  // TODO(sashab): Wrap these generic Lists somehow.
  List get conditions => JS('List', '#.conditions', this._jsObject);

  set conditions(List conditions) {
    JS('void', '#.conditions = #', this._jsObject, convertArgument(conditions));
  }

  // TODO(sashab): Wrap these generic Lists somehow.
  List get actions => JS('List', '#.actions', this._jsObject);

  set actions(List actions) {
    JS('void', '#.actions = #', this._jsObject, convertArgument(actions));
  }

  int get priority => JS('int', '#.priority', this._jsObject);

  set priority(int priority) {
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
  void addListener(Function callback) => JS('void', '#.addListener(#)',
      this._jsObject, convertDartClosureToJS(callback, this._callbackArity));

  /// Deregisters an event listener <em>callback</em> from an event.
  void removeListener(Function callback) => JS('void', '#.removeListener(#)',
      this._jsObject, convertDartClosureToJS(callback, this._callbackArity));

  /// Returns True if <em>callback</em> is registered to the event.
  bool hasListener(Function callback) => JS('bool', '#.hasListener(#)',
      this._jsObject, convertDartClosureToJS(callback, this._callbackArity));

  /// Returns true if any event listeners are registered to the event.
  bool hasListeners() => JS('bool', '#.hasListeners()', this._jsObject);

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

        for (Object o in rules) __proxy_rules.add(new Rule._proxy(o));

        callback(__proxy_rules);
      }
    }

    JS(
        'void',
        '#.addRules(#, #, #)',
        this._jsObject,
        convertArgument(eventName),
        convertArgument(rules),
        convertDartClosureToJS(__proxy_callback, 1));
  }

  /// Returns currently registered rules.
  ///
  /// [eventName] is the name of the event this function affects and, if an array
  /// is passed as [ruleIdentifiers], only rules with identifiers contained in
  /// this array are returned. [callback] is called with registered rules.
  ///
  void getRules(String eventName,
      [List<String> ruleIdentifiers, void callback(List<Rule> rules)]) {
    // proxy the callback
    void __proxy_callback(List rules) {
      if (callback != null) {
        List<Rule> __proxy_rules = new List<Rule>();

        for (Object o in rules) __proxy_rules.add(new Rule._proxy(o));

        callback(__proxy_rules);
      }
    }

    JS(
        'void',
        '#.getRules(#, #, #)',
        this._jsObject,
        convertArgument(eventName),
        convertArgument(ruleIdentifiers),
        convertDartClosureToJS(__proxy_callback, 1));
  }

  /// Unregisters currently registered rules.
  ///
  /// [eventName] is the name of the event this function affects and, if an array
  /// is passed as [ruleIdentifiers], only rules with identifiers contained in
  /// this array are unregistered. [callback] is called when the rules are
  /// unregistered.
  ///
  void removeRules(String eventName,
          [List<String> ruleIdentifiers, void callback()]) =>
      JS(
          'void',
          '#.removeRules(#, #, #)',
          this._jsObject,
          convertArgument(eventName),
          convertArgument(ruleIdentifiers),
          convertDartClosureToJS(callback, 0));
}
