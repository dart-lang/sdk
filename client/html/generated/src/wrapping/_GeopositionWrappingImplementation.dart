// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class GeopositionWrappingImplementation extends DOMWrapperBase implements Geoposition {
  GeopositionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Coordinates get coords() { return LevelDom.wrapCoordinates(_ptr.coords); }

  int get timestamp() { return _ptr.timestamp; }
}
