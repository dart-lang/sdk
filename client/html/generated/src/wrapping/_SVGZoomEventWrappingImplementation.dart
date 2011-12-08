// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGZoomEventWrappingImplementation extends UIEventWrappingImplementation implements SVGZoomEvent {
  SVGZoomEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get newScale() { return _ptr.newScale; }

  SVGPoint get newTranslate() { return LevelDom.wrapSVGPoint(_ptr.newTranslate); }

  num get previousScale() { return _ptr.previousScale; }

  SVGPoint get previousTranslate() { return LevelDom.wrapSVGPoint(_ptr.previousTranslate); }

  SVGRect get zoomRectScreen() { return LevelDom.wrapSVGRect(_ptr.zoomRectScreen); }
}
