// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _GeopositionWrappingImplementation extends DOMWrapperBase implements Geoposition {
  _GeopositionWrappingImplementation() : super() {}

  static create__GeopositionWrappingImplementation() native {
    return new _GeopositionWrappingImplementation();
  }

  Coordinates get coords() { return _get_coords(this); }
  static Coordinates _get_coords(var _this) native;

  int get timestamp() { return _get_timestamp(this); }
  static int _get_timestamp(var _this) native;

  String get typeName() { return "Geoposition"; }
}
