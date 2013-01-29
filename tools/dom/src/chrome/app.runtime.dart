// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// from app_runtime.idl
part of chrome;

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

