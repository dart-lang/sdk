// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebGLDebugShadersWrappingImplementation extends DOMWrapperBase implements WebGLDebugShaders {
  _WebGLDebugShadersWrappingImplementation() : super() {}

  static create__WebGLDebugShadersWrappingImplementation() native {
    return new _WebGLDebugShadersWrappingImplementation();
  }

  String getTranslatedShaderSource(WebGLShader shader) {
    return _getTranslatedShaderSource(this, shader);
  }
  static String _getTranslatedShaderSource(receiver, shader) native;

  String get typeName() { return "WebGLDebugShaders"; }
}
