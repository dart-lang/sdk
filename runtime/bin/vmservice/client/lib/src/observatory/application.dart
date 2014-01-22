// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

/// The observatory application. Instances of this are created and owned
/// by the observatory_application custom element.
class ObservatoryApplication extends Observable {
  @observable final LocationManager locationManager;
  @observable final RequestManager requestManager;
  @observable final IsolateManager isolateManager;

  void _setup() {
    locationManager._application = this;
    requestManager._application = this;
    isolateManager._application = this;
    requestManager.interceptor = isolateManager._responseInterceptor;
    locationManager.init();
  }

  ObservatoryApplication.devtools() :
      locationManager = new LocationManager(),
      requestManager = new PostMessageRequestManager(),
      isolateManager = new IsolateManager() {
    _setup();
  }

  ObservatoryApplication() :
      locationManager = new LocationManager(),
      requestManager = new HttpRequestManager(),
      isolateManager = new IsolateManager() {
    _setup();
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
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
    return x.toStringAsFixed(4);
  }
}
