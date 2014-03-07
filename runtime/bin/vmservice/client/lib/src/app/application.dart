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
  @observable Map response;
  @observable Isolate isolate;

  void setResponse(Map response) {
    this.response = toObservable(response);
  }

  void setResponseError(String message, [String errorType = 'ResponseError']) {
    this.response = toObservable({
      'type': 'Error',
      'errorType': errorType,
      'text': message
    });
    Logger.root.severe(message);
  }

  void _setup() {
    vm._app = this;
    locationManager._app = this;
    locationManager.init();
  }

  ObservatoryApplication.devtools() :
      locationManager = new LocationManager(),
      vm = new DartiumVM() {
    _setup();
  }

  ObservatoryApplication() :
      locationManager = new LocationManager(),
      vm = new HttpVM('http://127.0.0.1:8181/') {
    _setup();
  }

  static const int KB = 1024;
  static const int MB = KB * 1024;
  static String scaledSizeUnits(int x) {
    if (x > 2 * MB) {
      var y = x / MB;
      return '${y.toStringAsFixed(1)} MB';
    } else if (x > 2 * KB) {
      var y = x / KB;
      return '${y.toStringAsFixed(1)} KB';
    }
    var y = x.toDouble();
    return '${y.toStringAsFixed(1)} B';
  }

  static String timeUnits(double x) {
    return x.toStringAsFixed(2);
  }
}
