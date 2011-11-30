// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGDocumentWrappingImplementation extends _DocumentWrappingImplementation implements SVGDocument {
  _SVGDocumentWrappingImplementation() : super() {}

  static create__SVGDocumentWrappingImplementation() native {
    return new _SVGDocumentWrappingImplementation();
  }

  SVGSVGElement get rootElement() { return _get_rootElement(this); }
  static SVGSVGElement _get_rootElement(var _this) native;

  Event createEvent(String eventType) {
    return _createEvent_SVGDocument(this, eventType);
  }
  static Event _createEvent_SVGDocument(receiver, eventType) native;

  String get typeName() { return "SVGDocument"; }
}
