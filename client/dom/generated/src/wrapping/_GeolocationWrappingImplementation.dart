// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _GeolocationWrappingImplementation extends DOMWrapperBase implements Geolocation {
  _GeolocationWrappingImplementation() : super() {}

  static create__GeolocationWrappingImplementation() native {
    return new _GeolocationWrappingImplementation();
  }

  void clearWatch(int watchId) {
    _clearWatch(this, watchId);
    return;
  }
  static void _clearWatch(receiver, watchId) native;

  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _getCurrentPosition(this, successCallback);
      return;
    } else {
      _getCurrentPosition_2(this, successCallback, errorCallback);
      return;
    }
  }
  static void _getCurrentPosition(receiver, successCallback) native;
  static void _getCurrentPosition_2(receiver, successCallback, errorCallback) native;

  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      return _watchPosition(this, successCallback);
    } else {
      return _watchPosition_2(this, successCallback, errorCallback);
    }
  }
  static int _watchPosition(receiver, successCallback) native;
  static int _watchPosition_2(receiver, successCallback, errorCallback) native;

  String get typeName() { return "Geolocation"; }
}
