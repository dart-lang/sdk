// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generated from namespace: app.runtime

part of chrome;

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
