// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGElementWrappingImplementation extends ElementWrappingImplementation implements SVGElement {
  SVGElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get id() { return _ptr.id; }

  void set id(String value) { _ptr.id = value; }

  SVGSVGElement get ownerSVGElement() { return LevelDom.wrapSVGSVGElement(_ptr.ownerSVGElement); }

  SVGElement get viewportElement() { return LevelDom.wrapSVGElement(_ptr.viewportElement); }

  String get xmlbase() { return _ptr.xmlbase; }

  void set xmlbase(String value) { _ptr.xmlbase = value; }
}
