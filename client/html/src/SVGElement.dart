// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface SVGElement extends Element default SVGElementWrappingImplementation {

  SVGElement.tag(String tag);
  SVGElement.svg(String svg);

  String get id();

  void set id(String value);

  SVGSVGElement get ownerSVGElement();

  SVGElement get viewportElement();

  String get xmlbase();

  void set xmlbase(String value);

  SVGElement clone(bool deep);
}
