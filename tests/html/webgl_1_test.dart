// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_gl_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';
import 'dart:web_gl';
import 'dart:web_gl' as gl;

// Test that WebGL is present in dart:web_gl API

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(RenderingContext.supported, isTrue);
    });
  });

  group('functional', () {
    test('unsupported fails', () {
      var canvas = new CanvasElement();
      var context = canvas.getContext3d();
      if (RenderingContext.supported) {
        expect(context, isNotNull);
        expect(context, new isInstanceOf<RenderingContext>());
      } else {
        expect(context, isNull);
      }
    });

    if (RenderingContext.supported) {
      test('simple', () {
        var canvas = new CanvasElement();
        var context = canvas.getContext('experimental-webgl');
        var shader = context.createShader(gl.VERTEX_SHADER);
        context.shaderSource(shader, 'void main() { }');
        context.compileShader(shader);
        var success = context.getShaderParameter(shader, gl.COMPILE_STATUS);
        expect(success, isTrue);
      });

      test('getContext3d', () {
        var canvas = new CanvasElement();
        var context = canvas.getContext3d();
        expect(context, isNotNull);
        expect(context, new isInstanceOf<RenderingContext>());

        context = canvas.getContext3d(depth: false);
        expect(context, isNotNull);
        expect(context, new isInstanceOf<RenderingContext>());
      });
    }
  });
}

