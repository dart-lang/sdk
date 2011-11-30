// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGAnimationElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGAnimationElement {
  _SVGAnimationElementWrappingImplementation() : super() {}

  static create__SVGAnimationElementWrappingImplementation() native {
    return new _SVGAnimationElementWrappingImplementation();
  }

  SVGElement get targetElement() { return _get_targetElement(this); }
  static SVGElement _get_targetElement(var _this) native;

  num getCurrentTime() {
    return _getCurrentTime(this);
  }
  static num _getCurrentTime(receiver) native;

  num getSimpleDuration() {
    return _getSimpleDuration(this);
  }
  static num _getSimpleDuration(receiver) native;

  num getStartTime() {
    return _getStartTime(this);
  }
  static num _getStartTime(receiver) native;

  // From SVGTests

  SVGStringList get requiredExtensions() { return _get_requiredExtensions(this); }
  static SVGStringList _get_requiredExtensions(var _this) native;

  SVGStringList get requiredFeatures() { return _get_requiredFeatures(this); }
  static SVGStringList _get_requiredFeatures(var _this) native;

  SVGStringList get systemLanguage() { return _get_systemLanguage(this); }
  static SVGStringList _get_systemLanguage(var _this) native;

  bool hasExtension(String extension) {
    return _hasExtension(this, extension);
  }
  static bool _hasExtension(receiver, extension) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return _get_externalResourcesRequired(this); }
  static SVGAnimatedBoolean _get_externalResourcesRequired(var _this) native;

  // From ElementTimeControl

  void beginElement() {
    _beginElement(this);
    return;
  }
  static void _beginElement(receiver) native;

  void beginElementAt(num offset) {
    _beginElementAt(this, offset);
    return;
  }
  static void _beginElementAt(receiver, offset) native;

  void endElement() {
    _endElement(this);
    return;
  }
  static void _endElement(receiver) native;

  void endElementAt(num offset) {
    _endElementAt(this, offset);
    return;
  }
  static void _endElementAt(receiver, offset) native;

  String get typeName() { return "SVGAnimationElement"; }
}
