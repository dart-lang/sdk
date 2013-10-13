// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

/// The observatory application. Instances of this are created and owned
/// by the observatory_application custom element.
class ObservatoryApplication {
  final LocationManager locationManager = new LocationManager();
  final RequestManager requestManager = new HttpRequestManager();
  final IsolateManager isolateManager = new IsolateManager();

  ObservatoryApplication() {
    locationManager._application = this;
    requestManager._application = this;
    isolateManager._application = this;
    requestManager.interceptor = isolateManager._responseInterceptor;
    locationManager.init();
  }

  /// Return the [Isolate] with [id].
  Isolate getIsolate(int id) {
    return isolateManager.isolates[id];
  }

  /// Return the name of the isolate with [id].
  String getIsolateName(int id) {
    var isolate = getIsolate(id);
    if (isolate == null) {
      return 'Null Isolate';
    }
    return isolate.name;
  }
}
