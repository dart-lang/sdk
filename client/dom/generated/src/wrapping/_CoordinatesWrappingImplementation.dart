// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CoordinatesWrappingImplementation extends DOMWrapperBase implements Coordinates {
  _CoordinatesWrappingImplementation() : super() {}

  static create__CoordinatesWrappingImplementation() native {
    return new _CoordinatesWrappingImplementation();
  }

  num get accuracy() { return _get__Coordinates_accuracy(this); }
  static num _get__Coordinates_accuracy(var _this) native;

  num get altitude() { return _get__Coordinates_altitude(this); }
  static num _get__Coordinates_altitude(var _this) native;

  num get altitudeAccuracy() { return _get__Coordinates_altitudeAccuracy(this); }
  static num _get__Coordinates_altitudeAccuracy(var _this) native;

  num get heading() { return _get__Coordinates_heading(this); }
  static num _get__Coordinates_heading(var _this) native;

  num get latitude() { return _get__Coordinates_latitude(this); }
  static num _get__Coordinates_latitude(var _this) native;

  num get longitude() { return _get__Coordinates_longitude(this); }
  static num _get__Coordinates_longitude(var _this) native;

  num get speed() { return _get__Coordinates_speed(this); }
  static num _get__Coordinates_speed(var _this) native;

  String get typeName() { return "Coordinates"; }
}
