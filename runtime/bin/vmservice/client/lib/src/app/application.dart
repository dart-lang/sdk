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

  /// The current [ServiceObject] being viewed by the application.
  @observable ServiceObject response;

  /// Any client-level arguments for viewing the current response.
  @observable String args;
  // TODO(turnidge): Make args a Map.

  void _initOnce() {
    // Only called once.
    assert(locationManager._app == null);
    locationManager._app = this;
    locationManager.init();
    vm.errors.stream.listen(_onError);
    vm.exceptions.stream.listen(_onException);
  }

  void _onError(ServiceError error) {
    response = error;
    // No id, clear the hash.
    locationManager.clearCurrentHash();
  }

  void _onException(ServiceException exception) {
    response = exception;
    // No id, clear the hash.
    locationManager.clearCurrentHash();
  }

  ObservatoryApplication.devtools() :
      locationManager = new LocationManager(),
      vm = new DartiumVM() {
    _initOnce();
  }

  ObservatoryApplication() :
      locationManager = new LocationManager(),
      vm = new HttpVM() {
    _initOnce();
  }
}
