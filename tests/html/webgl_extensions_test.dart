// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_gl_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import 'dart:typed_data';
import 'dart:web_gl';
import 'dart:web_gl' as gl;

// Test that various webgl extensions are available. Only test advertised
// supported extensions. If the extension has methods, we just test the presence
// of some methods - we don't test if functionality works.

main() {
  useHtmlIndividualConfiguration();

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
    expect(name, isIn(allExtensions), reason: 'unknown extension');
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
      expect(1, isNot(typeMatcher), reason: 'invalid typeMatcher');
    });
  }

  group('ANGLE_instanced_arrays', () {
    const name = 'ANGLE_instanced_arrays';
    testType(name, const isInstanceOf<AngleInstancedArrays>());
    test('vertexAttribDivisorAngle', () {
      var extension = getExtension(name);
      if (extension == null) return;
      expect(extension.vertexAttribDivisorAngle, isFunction);
    });
  });

  group('EXT_blend_minmax', () {
    testType('EXT_blend_minmax', const isInstanceOf<ExtBlendMinMax>());
  });

  group('EXT_frag_depth', () {
    testType('EXT_frag_depth', const isInstanceOf<ExtFragDepth>());
  });

  group('EXT_sRGB', () {
    testType('EXT_sRGB', const isInstanceOf<EXTsRgb>());
  });

  group('EXT_shader_texture_lod', () {
    testType(
        'EXT_shader_texture_lod', const isInstanceOf<ExtShaderTextureLod>());
  });

  group('EXT_texture_filter_anisotropic', () {
    testType('EXT_texture_filter_anisotropic',
        const isInstanceOf<ExtTextureFilterAnisotropic>());
  });

  group('OES_element_index_uint', () {
    testType(
        'OES_element_index_uint', const isInstanceOf<OesElementIndexUint>());
  });

  group('OES_standard_derivatives', () {
    testType('OES_standard_derivatives',
        const isInstanceOf<OesStandardDerivatives>());
  });

  group('OES_texture_float', () {
    testType('OES_texture_float', const isInstanceOf<OesTextureFloat>());
  });

  group('OES_texture_float_linear', () {
    testType('OES_texture_float_linear',
        const isInstanceOf<OesTextureFloatLinear>());
  });

  group('OES_texture_half_float', () {
    testType(
        'OES_texture_half_float', const isInstanceOf<OesTextureHalfFloat>());
  });

  group('OES_texture_half_float_linear', () {
    testType('OES_texture_half_float_linear',
        const isInstanceOf<OesTextureHalfFloatLinear>());
  });

  group('OES_vertex_array_object', () {
    testType(
        'OES_vertex_array_object', const isInstanceOf<OesVertexArrayObject>());
  });

  group('WEBGL_compressed_texture_atc', () {
    testType('WEBGL_compressed_texture_atc',
        const isInstanceOf<CompressedTextureAtc>());
  });

  group('WEBGL_compressed_texture_etc1', () {
    testType('WEBGL_compressed_texture_etc1',
        const isInstanceOf<CompressedTextureETC1>());
  });

  group('WEBGL_compressed_texture_pvrtc', () {
    testType('WEBGL_compressed_texture_pvrtc',
        const isInstanceOf<CompressedTexturePvrtc>());
  });

  group('WEBGL_compressed_texture_s3tc', () {
    testType('WEBGL_compressed_texture_s3tc',
        const isInstanceOf<CompressedTextureS3TC>());
  });

  group('WEBGL_debug_renderer_info', () {
    testType(
        'WEBGL_debug_renderer_info', const isInstanceOf<DebugRendererInfo>());
  });

  group('WEBGL_debug_shaders', () {
    testType('WEBGL_debug_shaders', const isInstanceOf<DebugShaders>());
  });

  group('WEBGL_depth_texture', () {
    testType('WEBGL_depth_texture', const isInstanceOf<DepthTexture>());
  });

  group('WEBGL_draw_buffers', () {
    const name = 'WEBGL_draw_buffers';
    testType(name, const isInstanceOf<DrawBuffers>());
    test('drawBuffersWebgl', () {
      var extension = getExtension(name);
      if (extension == null) return;
      expect(extension.drawBuffersWebgl, isFunction);
    });
  });

  group('WEBGL_lose_context', () {
    const name = 'WEBGL_lose_context';
    testType(name, const isInstanceOf<LoseContext>());
    test('loseContext', () {
      var extension = getExtension(name);
      if (extension == null) return;
      expect(extension.loseContext, isFunction);
    });
  });
}

Matcher isFunction = const isInstanceOf<Function>();
