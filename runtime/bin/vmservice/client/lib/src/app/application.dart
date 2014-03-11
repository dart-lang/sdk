// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// A request response interceptor is called for each response.
typedef void RequestResponseInterceptor();

/// The observatory application. Instances of this are created and owned
/// by the observatory_application custom element.
class ObservatoryApplication extends Observable {
  @observable final LocationManager locationManager;
  @observable final VM vm;
  @observable Isolate isolate;
  @observable ServiceObject response;

  void setResponse(ServiceObject response) {
    this.response = response;
  }

  void _initOnce() {
    // Only called once.
    assert(locationManager._app == null);
    locationManager._app = this;
    locationManager.init();
  }

  ObservatoryApplication.devtools() :
      locationManager = new LocationManager(),
      vm = new DartiumVM() {
    _initOnce();
  }

  ObservatoryApplication() :
      locationManager = new LocationManager(),
      vm = new HttpVM('http://127.0.0.1:8181/') {
    _initOnce();
  }
}
