// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_gl_test;

import 'dart:html';
import 'dart:web_gl';

import 'package:expect/minitest.dart';

final isAngleInstancedArrays = predicate((v) => v is AngleInstancedArrays);
final isExtBlendMinMax = predicate((v) => v is ExtBlendMinMax);
final isExtFragDepth = predicate((v) => v is ExtFragDepth);
final isEXTsRgb = predicate((v) => v is EXTsRgb);
final isExtShaderTextureLod = predicate((v) => v is ExtShaderTextureLod);
final isExtTextureFilterAnisotropic =
    predicate((v) => v is ExtTextureFilterAnisotropic);
final isOesElementIndexUint = predicate((v) => v is OesElementIndexUint);
final isOesStandardDerivatives = predicate((v) => v is OesStandardDerivatives);
final isOesTextureFloat = predicate((v) => v is OesTextureFloat);
final isOesTextureFloatLinear = predicate((v) => v is OesTextureFloatLinear);
final isOesTextureHalfFloat = predicate((v) => v is OesTextureHalfFloat);
final isOesTextureHalfFloatLinear =
    predicate((v) => v is OesTextureHalfFloatLinear);
final isOesVertexArrayObject = predicate((v) => v is OesVertexArrayObject);
final isCompressedTextureAtc = predicate((v) => v is CompressedTextureAtc);
final isCompressedTextureETC1 = predicate((v) => v is CompressedTextureETC1);
final isCompressedTexturePvrtc = predicate((v) => v is CompressedTexturePvrtc);
final isCompressedTextureS3TC = predicate((v) => v is CompressedTextureS3TC);
final isDebugRendererInfo = predicate((v) => v is DebugRendererInfo);
final isDebugShaders = predicate((v) => v is DebugShaders);
final isDepthTexture = predicate((v) => v is DepthTexture);
final isDrawBuffers = predicate((v) => v is DrawBuffers);
final isLoseContext = predicate((v) => v is LoseContext);
final isFunction = predicate((v) => v is Function);

// Test that various webgl extensions are available. Only test advertised
// supported extensions. If the extension has methods, we just test the presence
// of some methods - we don't test if functionality works.

main() {
  if (!RenderingContext.supported) return;

  const allExtensions = const [
    'ANGLE_instanced_arrays',
    'EXT_blend_minmax',
    'EXT_color_buffer_float',
    'EXT_color_buffer_half_float',
    'EXT_disjoint_timer_query',
    'EXT_frag_depth',
    'EXT_sRGB',
    'EXT_shader_texture_lod',
    'EXT_texture_filter_anisotropic',
    'OES_element_index_uint',
    'OES_standard_derivatives',
    'OES_texture_float',
    'OES_texture_float_linear',
    'OES_texture_half_float',
    'OES_texture_half_float_linear',
    'OES_vertex_array_object',
    'WEBGL_color_buffer_float',
    'WEBGL_compressed_texture_atc',
    'WEBGL_compressed_texture_es3',
    'WEBGL_compressed_texture_etc1',
    'WEBGL_compressed_texture_pvrtc',
    'WEBGL_compressed_texture_s3tc',
    'WEBGL_debug_renderer_info',
    'WEBGL_debug_shaders',
    'WEBGL_depth_texture',
    'WEBGL_draw_buffers',
    'WEBGL_lose_context',
  ];

  getExtension(String name) {
    expect(name, anyOf(allExtensions), reason: 'unknown extension');
    var canvas = new CanvasElement();
    var context = canvas.getContext3d();
    var supportedExtensions = context.getSupportedExtensions();
    if (supportedExtensions.contains(name)) {
      var extension = context.getExtension(name);
      expect(extension, isNotNull);
      return extension;
    }
    return null;
  }

  testType(name, typeMatcher) {
    test('type', () {
      var extension = getExtension(name);
      if (extension == null) return;
      expect(extension, typeMatcher);
      // Ensure that isInstanceOf<X> is not instantiated for an erroneous type
      // X.  If X is erroneous, there is only a warning at compile time and X is
      // treated as dynamic, which would make the above line pass.
      expect(() => expect(1, typeMatcher), throws,
          reason: 'invalid typeMatcher');
    });
  }

  group('ANGLE_instanced_arrays', () {
    const name = 'ANGLE_instanced_arrays';
    testType(name, isAngleInstancedArrays);
    test('vertexAttribDivisorAngle', () {
      AngleInstancedArrays extension = getExtension(name);
      if (extension == null) return;
      expect(extension.vertexAttribDivisorAngle, isFunction);
    });
  });

  group('EXT_blend_minmax', () {
    testType('EXT_blend_minmax', isExtBlendMinMax);
  });

  group('EXT_frag_depth', () {
    testType('EXT_frag_depth', isExtFragDepth);
  });

  group('EXT_sRGB', () {
    testType('EXT_sRGB', isEXTsRgb);
  });

  group('EXT_shader_texture_lod', () {
    testType('EXT_shader_texture_lod', isExtShaderTextureLod);
  });

  group('EXT_texture_filter_anisotropic', () {
    testType('EXT_texture_filter_anisotropic', isExtTextureFilterAnisotropic);
  });

  group('OES_element_index_uint', () {
    testType('OES_element_index_uint', isOesElementIndexUint);
  });

  group('OES_standard_derivatives', () {
    testType('OES_standard_derivatives', isOesStandardDerivatives);
  });

  group('OES_texture_float', () {
    testType('OES_texture_float', isOesTextureFloat);
  });

  group('OES_texture_float_linear', () {
    testType('OES_texture_float_linear', isOesTextureFloatLinear);
  });

  group('OES_texture_half_float', () {
    testType('OES_texture_half_float', isOesTextureHalfFloat);
  });

  group('OES_texture_half_float_linear', () {
    testType('OES_texture_half_float_linear', isOesTextureHalfFloatLinear);
  });

  group('OES_vertex_array_object', () {
    testType('OES_vertex_array_object', isOesVertexArrayObject);
  });

  group('WEBGL_compressed_texture_atc', () {
    testType('WEBGL_compressed_texture_atc', isCompressedTextureAtc);
  });

  group('WEBGL_compressed_texture_etc1', () {
    testType('WEBGL_compressed_texture_etc1', isCompressedTextureETC1);
  });

  group('WEBGL_compressed_texture_pvrtc', () {
    testType('WEBGL_compressed_texture_pvrtc', isCompressedTexturePvrtc);
  });

  group('WEBGL_compressed_texture_s3tc', () {
    testType('WEBGL_compressed_texture_s3tc', isCompressedTextureS3TC);
  });

  group('WEBGL_debug_renderer_info', () {
    testType('WEBGL_debug_renderer_info', isDebugRendererInfo);
  });

  group('WEBGL_debug_shaders', () {
    testType('WEBGL_debug_shaders', isDebugShaders);
  });

  group('WEBGL_depth_texture', () {
    testType('WEBGL_depth_texture', isDepthTexture);
  });

  group('WEBGL_draw_buffers', () {
    const name = 'WEBGL_draw_buffers';
    testType(name, isDrawBuffers);
    test('drawBuffersWebgl', () {
      DrawBuffers extension = getExtension(name);
      if (extension == null) return;
      expect(extension.drawBuffersWebgl, isFunction);
    });
  });

  group('WEBGL_lose_context', () {
    const name = 'WEBGL_lose_context';
    testType(name, isLoseContext);
    test('loseContext', () {
      LoseContext extension = getExtension(name);
      if (extension == null) return;
      expect(extension.loseContext, isFunction);
    });
  });
}
