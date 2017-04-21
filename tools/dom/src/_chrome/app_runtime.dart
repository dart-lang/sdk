// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generated from namespace: app.runtime

part of chrome;

/**
 * Types
 */

class AppRuntimeLaunchItem extends ChromeObject {
  /*
   * Public constructor
   */
  AppRuntimeLaunchItem({FileEntry entry, String type}) {
    if (entry != null) this.entry = entry;
    if (type != null) this.type = type;
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

  set entry(FileEntry entry) {
    JS('void', '#.entry = #', this._jsObject, convertArgument(entry));
  }

  /// The MIME type of the file.
  String get type => JS('String', '#.type', this._jsObject);

  set type(String type) {
    JS('void', '#.type = #', this._jsObject, type);
  }
}

class AppRuntimeLaunchData extends ChromeObject {
  /*
   * Public constructor
   */
  AppRuntimeLaunchData({String id, List<AppRuntimeLaunchItem> items}) {
    if (id != null) this.id = id;
    if (items != null) this.items = items;
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

  set id(String id) {
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

  set items(List<AppRuntimeLaunchItem> items) {
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
    onLaunched = new Event_app_runtime_onLaunched(
        JS('', '#.onLaunched', this._jsObject));
    onRestarted = new Event_app_runtime_onRestarted(
        JS('', '#.onRestarted', this._jsObject));
  }
}
