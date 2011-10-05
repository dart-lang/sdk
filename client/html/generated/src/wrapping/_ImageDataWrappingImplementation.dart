// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ImageDataWrappingImplementation extends DOMWrapperBase implements ImageData {
  ImageDataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CanvasPixelArray get data() { return LevelDom.wrapCanvasPixelArray(_ptr.data); }

  int get height() { return _ptr.height; }

  int get width() { return _ptr.width; }

  String get typeName() { return "ImageData"; }
}
