// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGElementInstanceWrappingImplementation extends DOMWrapperBase implements SVGElementInstance {
  _SVGElementInstanceWrappingImplementation() : super() {}

  static create__SVGElementInstanceWrappingImplementation() native {
    return new _SVGElementInstanceWrappingImplementation();
  }

  SVGElementInstanceList get childNodes() { return _get_childNodes(this); }
  static SVGElementInstanceList _get_childNodes(var _this) native;

  SVGElement get correspondingElement() { return _get_correspondingElement(this); }
  static SVGElement _get_correspondingElement(var _this) native;

  SVGUseElement get correspondingUseElement() { return _get_correspondingUseElement(this); }
  static SVGUseElement _get_correspondingUseElement(var _this) native;

  SVGElementInstance get firstChild() { return _get_firstChild(this); }
  static SVGElementInstance _get_firstChild(var _this) native;

  SVGElementInstance get lastChild() { return _get_lastChild(this); }
  static SVGElementInstance _get_lastChild(var _this) native;

  SVGElementInstance get nextSibling() { return _get_nextSibling(this); }
  static SVGElementInstance _get_nextSibling(var _this) native;

  SVGElementInstance get parentNode() { return _get_parentNode(this); }
  static SVGElementInstance _get_parentNode(var _this) native;

  SVGElementInstance get previousSibling() { return _get_previousSibling(this); }
  static SVGElementInstance _get_previousSibling(var _this) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener_SVGElementInstance(this, type, listener);
      return;
    } else {
      _addEventListener_SVGElementInstance_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener_SVGElementInstance(receiver, type, listener) native;
  static void _addEventListener_SVGElementInstance_2(receiver, type, listener, useCapture) native;

  bool dispatchEvent(Event event) {
    return _dispatchEvent_SVGElementInstance(this, event);
  }
  static bool _dispatchEvent_SVGElementInstance(receiver, event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener_SVGElementInstance(this, type, listener);
      return;
    } else {
      _removeEventListener_SVGElementInstance_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener_SVGElementInstance(receiver, type, listener) native;
  static void _removeEventListener_SVGElementInstance_2(receiver, type, listener, useCapture) native;

  String get typeName() { return "SVGElementInstance"; }
}
