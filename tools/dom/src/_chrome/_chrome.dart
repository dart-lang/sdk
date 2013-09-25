// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of chrome;

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
