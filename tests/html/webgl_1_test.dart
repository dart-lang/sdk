// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_gl_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

// Test that WebGL is present in dart:html API

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(WebGLRenderingContext.supported, isTrue);
    });
  });

  group('functional', () {
    test('unsupported fails', () {
      var canvas = new CanvasElement();
      var gl = canvas.getContext3d();
      if (WebGLRenderingContext.supported) {
        expect(gl, isNotNull);
        expect(gl, new isInstanceOf<WebGLRenderingContext>());
      } else {
        expect(gl, isNull);
      }
    });

    if (WebGLRenderingContext.supported) {
      test('simple', () {
        var canvas = new CanvasElement();
        var gl = canvas.getContext('experimental-webgl');
        var shader = gl.createShader(WebGLRenderingContext.VERTEX_SHADER);
        gl.shaderSource(shader, 'void main() { }');
        gl.compileShader(shader);
        var success =
            gl.getShaderParameter(shader, WebGLRenderingContext.COMPILE_STATUS);
        expect(success, isTrue);
      });

      test('getContext3d', () {
        var canvas = new CanvasElement();
        var gl = canvas.getContext3d();
        expect(gl, isNotNull);
        expect(gl, new isInstanceOf<WebGLRenderingContext>());

        gl = canvas.getContext3d(depth: false);
        expect(gl, isNotNull);
        expect(gl, new isInstanceOf<WebGLRenderingContext>());
      });
    }
  });
}
