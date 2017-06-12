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
