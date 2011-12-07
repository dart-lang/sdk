// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimationElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGAnimationElement {
  SVGAnimationElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGElement get targetElement() { return LevelDom.wrapSVGElement(_ptr.targetElement); }

  num getCurrentTime() {
    return _ptr.getCurrentTime();
  }

  num getSimpleDuration() {
    return _ptr.getSimpleDuration();
  }

  num getStartTime() {
    return _ptr.getStartTime();
  }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From ElementTimeControl

  void beginElement() {
    _ptr.beginElement();
    return;
  }

  void beginElementAt(num offset) {
    _ptr.beginElementAt(offset);
    return;
  }

  void endElement() {
    _ptr.endElement();
    return;
  }

  void endElementAt(num offset) {
    _ptr.endElementAt(offset);
    return;
  }
}
