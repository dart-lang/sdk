// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebGLCompressedTexturesWrappingImplementation extends DOMWrapperBase implements WebGLCompressedTextures {
  _WebGLCompressedTexturesWrappingImplementation() : super() {}

  static create__WebGLCompressedTexturesWrappingImplementation() native {
    return new _WebGLCompressedTexturesWrappingImplementation();
  }

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, ArrayBufferView data) {
    _compressedTexImage2D(this, target, level, internalformat, width, height, border, data);
    return;
  }
  static void _compressedTexImage2D(receiver, target, level, internalformat, width, height, border, data) native;

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, ArrayBufferView data) {
    _compressedTexSubImage2D(this, target, level, xoffset, yoffset, width, height, format, data);
    return;
  }
  static void _compressedTexSubImage2D(receiver, target, level, xoffset, yoffset, width, height, format, data) native;

  String get typeName() { return "WebGLCompressedTextures"; }
}
