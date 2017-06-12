// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_gl_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import 'dart:typed_data';
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

      test('texImage2D', () {
        var canvas = new CanvasElement();
        var context = canvas.getContext3d();
        var pixels = new Uint8List.fromList([0, 0, 3, 255, 0, 0, 0, 0, 0, 0]);
        context.texImage2DUntyped(1, 1, 1, 1, 10, 10, 1, 1, pixels);

        canvas = new CanvasElement();
        document.body.children.add(canvas);
        var context2 = canvas.getContext('2d');
        context.texImage2DData(
            1, 1, 1, 1, 10, context2.getImageData(10, 10, 10, 10));

        context.texImage2DImage(1, 1, 1, 1, 10, new ImageElement());
        context.texImage2DCanvas(1, 1, 1, 1, 10, new CanvasElement());
        context.texImage2DVideo(1, 1, 1, 1, 10, new VideoElement());
      });

      test('texSubImage2D', () {
        var canvas = new CanvasElement();
        var context = canvas.getContext3d();
        var pixels = new Uint8List.fromList([0, 0, 3, 255, 0, 0, 0, 0, 0, 0]);
        context.texSubImage2DUntyped(1, 1, 1, 1, 10, 10, 1, 1, pixels);

        canvas = new CanvasElement();
        document.body.children.add(canvas);
        var context2 = canvas.getContext('2d');
        context.texSubImage2DData(
            1, 1, 1, 1, 1, 10, context2.getImageData(10, 10, 10, 10));

        context.texSubImage2DImage(1, 1, 1, 1, 1, 10, new ImageElement());
        context.texSubImage2DCanvas(1, 1, 1, 1, 1, 10, new CanvasElement());
        context.texSubImage2DVideo(1, 1, 1, 1, 1, 10, new VideoElement());
      });

      test('getContextAttributes', () {
        var canvas = new CanvasElement();
        var context = canvas.getContext3d();
        var attributes = context.getContextAttributes();

        expect(attributes, isNotNull);
        expect(attributes, new isInstanceOf<gl.ContextAttributes>());

        expect(attributes.alpha, isBoolean);
        expect(attributes.antialias, isBoolean);
        expect(attributes.depth, isBoolean);
        expect(attributes.premultipliedAlpha, isBoolean);
        expect(attributes.preserveDrawingBuffer, isBoolean);
        expect(attributes.stencil, isBoolean);
      });
    }
  });
}

Matcher isBoolean = anyOf(isTrue, isFalse);
