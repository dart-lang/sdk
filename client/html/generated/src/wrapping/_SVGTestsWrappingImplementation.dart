// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTestsWrappingImplementation extends DOMWrapperBase implements SVGTests {
  SVGTestsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }
}
