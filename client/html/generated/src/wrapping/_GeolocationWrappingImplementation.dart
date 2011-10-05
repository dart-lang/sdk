// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class GeolocationWrappingImplementation extends DOMWrapperBase implements Geolocation {
  GeolocationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void clearWatch(int watchId) {
    _ptr.clearWatch(watchId);
    return;
  }

  void getCurrentPosition(PositionCallback successCallback, PositionErrorCallback errorCallback) {
    _ptr.getCurrentPosition(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  int watchPosition(PositionCallback successCallback, PositionErrorCallback errorCallback) {
    return _ptr.watchPosition(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
  }

  String get typeName() { return "Geolocation"; }
}
