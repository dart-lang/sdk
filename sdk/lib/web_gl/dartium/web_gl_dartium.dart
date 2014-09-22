library dart.dom.web_gl;

import 'dart:async';
import 'dart:collection';
import 'dart:_internal' hide deprecated;
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:typed_data';
import 'dart:_blink' as _blink;
// DO NOT EDIT
// Auto-generated dart:web_gl library.





// FIXME: Can we make this private?
final web_glBlinkMap = {
  'ANGLEInstancedArrays': () => AngleInstancedArrays,
  'EXTBlendMinMax': () => ExtBlendMinMax,
  'EXTFragDepth': () => ExtFragDepth,
  'EXTShaderTextureLOD': () => ExtShaderTextureLod,
  'EXTTextureFilterAnisotropic': () => ExtTextureFilterAnisotropic,
  'OESElementIndexUint': () => OesElementIndexUint,
  'OESStandardDerivatives': () => OesStandardDerivatives,
  'OESTextureFloat': () => OesTextureFloat,
  'OESTextureFloatLinear': () => OesTextureFloatLinear,
  'OESTextureHalfFloat': () => OesTextureHalfFloat,
  'OESTextureHalfFloatLinear': () => OesTextureHalfFloatLinear,
  'OESVertexArrayObject': () => OesVertexArrayObject,
  'WebGLActiveInfo': () => ActiveInfo,
  'WebGLBuffer': () => Buffer,
  'WebGLCompressedTextureATC': () => CompressedTextureAtc,
  'WebGLCompressedTextureETC1': () => CompressedTextureETC1,
  'WebGLCompressedTexturePVRTC': () => CompressedTexturePvrtc,
  'WebGLCompressedTextureS3TC': () => CompressedTextureS3TC,
  'WebGLContextAttributes': () => ContextAttributes,
  'WebGLContextEvent': () => ContextEvent,
  'WebGLDebugRendererInfo': () => DebugRendererInfo,
  'WebGLDebugShaders': () => DebugShaders,
  'WebGLDepthTexture': () => DepthTexture,
  'WebGLDrawBuffers': () => DrawBuffers,
  'WebGLFramebuffer': () => Framebuffer,
  'WebGLLoseContext': () => LoseContext,
  'WebGLProgram': () => Program,
  'WebGLRenderbuffer': () => Renderbuffer,
  'WebGLRenderingContext': () => RenderingContext,
  'WebGLRenderingContextBase': () => RenderingContextBase,
  'WebGLShader': () => Shader,
  'WebGLShaderPrecisionFormat': () => ShaderPrecisionFormat,
  'WebGLTexture': () => Texture,
  'WebGLUniformLocation': () => UniformLocation,
  'WebGLVertexArrayObjectOES': () => VertexArrayObject,

};
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


const int ACTIVE_ATTRIBUTES = RenderingContextBase.ACTIVE_ATTRIBUTES;
const int ACTIVE_TEXTURE = RenderingContextBase.ACTIVE_TEXTURE;
const int ACTIVE_UNIFORMS = RenderingContextBase.ACTIVE_UNIFORMS;
const int ALIASED_LINE_WIDTH_RANGE = RenderingContextBase.ALIASED_LINE_WIDTH_RANGE;
const int ALIASED_POINT_SIZE_RANGE = RenderingContextBase.ALIASED_POINT_SIZE_RANGE;
const int ALPHA = RenderingContextBase.ALPHA;
const int ALPHA_BITS = RenderingContextBase.ALPHA_BITS;
const int ALWAYS = RenderingContextBase.ALWAYS;
const int ARRAY_BUFFER = RenderingContextBase.ARRAY_BUFFER;
const int ARRAY_BUFFER_BINDING = RenderingContextBase.ARRAY_BUFFER_BINDING;
const int ATTACHED_SHADERS = RenderingContextBase.ATTACHED_SHADERS;
const int BACK = RenderingContextBase.BACK;
const int BLEND = RenderingContextBase.BLEND;
const int BLEND_COLOR = RenderingContextBase.BLEND_COLOR;
const int BLEND_DST_ALPHA = RenderingContextBase.BLEND_DST_ALPHA;
const int BLEND_DST_RGB = RenderingContextBase.BLEND_DST_RGB;
const int BLEND_EQUATION = RenderingContextBase.BLEND_EQUATION;
const int BLEND_EQUATION_ALPHA = RenderingContextBase.BLEND_EQUATION_ALPHA;
const int BLEND_EQUATION_RGB = RenderingContextBase.BLEND_EQUATION_RGB;
const int BLEND_SRC_ALPHA = RenderingContextBase.BLEND_SRC_ALPHA;
const int BLEND_SRC_RGB = RenderingContextBase.BLEND_SRC_RGB;
const int BLUE_BITS = RenderingContextBase.BLUE_BITS;
const int BOOL = RenderingContextBase.BOOL;
const int BOOL_VEC2 = RenderingContextBase.BOOL_VEC2;
const int BOOL_VEC3 = RenderingContextBase.BOOL_VEC3;
const int BOOL_VEC4 = RenderingContextBase.BOOL_VEC4;
const int BROWSER_DEFAULT_WEBGL = RenderingContextBase.BROWSER_DEFAULT_WEBGL;
const int BUFFER_SIZE = RenderingContextBase.BUFFER_SIZE;
const int BUFFER_USAGE = RenderingContextBase.BUFFER_USAGE;
const int BYTE = RenderingContextBase.BYTE;
const int CCW = RenderingContextBase.CCW;
const int CLAMP_TO_EDGE = RenderingContextBase.CLAMP_TO_EDGE;
const int COLOR_ATTACHMENT0 = RenderingContextBase.COLOR_ATTACHMENT0;
const int COLOR_BUFFER_BIT = RenderingContextBase.COLOR_BUFFER_BIT;
const int COLOR_CLEAR_VALUE = RenderingContextBase.COLOR_CLEAR_VALUE;
const int COLOR_WRITEMASK = RenderingContextBase.COLOR_WRITEMASK;
const int COMPILE_STATUS = RenderingContextBase.COMPILE_STATUS;
const int COMPRESSED_TEXTURE_FORMATS = RenderingContextBase.COMPRESSED_TEXTURE_FORMATS;
const int CONSTANT_ALPHA = RenderingContextBase.CONSTANT_ALPHA;
const int CONSTANT_COLOR = RenderingContextBase.CONSTANT_COLOR;
const int CONTEXT_LOST_WEBGL = RenderingContextBase.CONTEXT_LOST_WEBGL;
const int CULL_FACE = RenderingContextBase.CULL_FACE;
const int CULL_FACE_MODE = RenderingContextBase.CULL_FACE_MODE;
const int CURRENT_PROGRAM = RenderingContextBase.CURRENT_PROGRAM;
const int CURRENT_VERTEX_ATTRIB = RenderingContextBase.CURRENT_VERTEX_ATTRIB;
const int CW = RenderingContextBase.CW;
const int DECR = RenderingContextBase.DECR;
const int DECR_WRAP = RenderingContextBase.DECR_WRAP;
const int DELETE_STATUS = RenderingContextBase.DELETE_STATUS;
const int DEPTH_ATTACHMENT = RenderingContextBase.DEPTH_ATTACHMENT;
const int DEPTH_BITS = RenderingContextBase.DEPTH_BITS;
const int DEPTH_BUFFER_BIT = RenderingContextBase.DEPTH_BUFFER_BIT;
const int DEPTH_CLEAR_VALUE = RenderingContextBase.DEPTH_CLEAR_VALUE;
const int DEPTH_COMPONENT = RenderingContextBase.DEPTH_COMPONENT;
const int DEPTH_COMPONENT16 = RenderingContextBase.DEPTH_COMPONENT16;
const int DEPTH_FUNC = RenderingContextBase.DEPTH_FUNC;
const int DEPTH_RANGE = RenderingContextBase.DEPTH_RANGE;
const int DEPTH_STENCIL = RenderingContextBase.DEPTH_STENCIL;
const int DEPTH_STENCIL_ATTACHMENT = RenderingContextBase.DEPTH_STENCIL_ATTACHMENT;
const int DEPTH_TEST = RenderingContextBase.DEPTH_TEST;
const int DEPTH_WRITEMASK = RenderingContextBase.DEPTH_WRITEMASK;
const int DITHER = RenderingContextBase.DITHER;
const int DONT_CARE = RenderingContextBase.DONT_CARE;
const int DST_ALPHA = RenderingContextBase.DST_ALPHA;
const int DST_COLOR = RenderingContextBase.DST_COLOR;
const int DYNAMIC_DRAW = RenderingContextBase.DYNAMIC_DRAW;
const int ELEMENT_ARRAY_BUFFER = RenderingContextBase.ELEMENT_ARRAY_BUFFER;
const int ELEMENT_ARRAY_BUFFER_BINDING = RenderingContextBase.ELEMENT_ARRAY_BUFFER_BINDING;
const int EQUAL = RenderingContextBase.EQUAL;
const int FASTEST = RenderingContextBase.FASTEST;
const int FLOAT = RenderingContextBase.FLOAT;
const int FLOAT_MAT2 = RenderingContextBase.FLOAT_MAT2;
const int FLOAT_MAT3 = RenderingContextBase.FLOAT_MAT3;
const int FLOAT_MAT4 = RenderingContextBase.FLOAT_MAT4;
const int FLOAT_VEC2 = RenderingContextBase.FLOAT_VEC2;
const int FLOAT_VEC3 = RenderingContextBase.FLOAT_VEC3;
const int FLOAT_VEC4 = RenderingContextBase.FLOAT_VEC4;
const int FRAGMENT_SHADER = RenderingContextBase.FRAGMENT_SHADER;
const int FRAMEBUFFER = RenderingContextBase.FRAMEBUFFER;
const int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = RenderingContextBase.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME;
const int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = RenderingContextBase.FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE;
const int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = RenderingContextBase.FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE;
const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = RenderingContextBase.FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL;
const int FRAMEBUFFER_BINDING = RenderingContextBase.FRAMEBUFFER_BINDING;
const int FRAMEBUFFER_COMPLETE = RenderingContextBase.FRAMEBUFFER_COMPLETE;
const int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = RenderingContextBase.FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
const int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = RenderingContextBase.FRAMEBUFFER_INCOMPLETE_DIMENSIONS;
const int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = RenderingContextBase.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT;
const int FRAMEBUFFER_UNSUPPORTED = RenderingContextBase.FRAMEBUFFER_UNSUPPORTED;
const int FRONT = RenderingContextBase.FRONT;
const int FRONT_AND_BACK = RenderingContextBase.FRONT_AND_BACK;
const int FRONT_FACE = RenderingContextBase.FRONT_FACE;
const int FUNC_ADD = RenderingContextBase.FUNC_ADD;
const int FUNC_REVERSE_SUBTRACT = RenderingContextBase.FUNC_REVERSE_SUBTRACT;
const int FUNC_SUBTRACT = RenderingContextBase.FUNC_SUBTRACT;
const int GENERATE_MIPMAP_HINT = RenderingContextBase.GENERATE_MIPMAP_HINT;
const int GEQUAL = RenderingContextBase.GEQUAL;
const int GREATER = RenderingContextBase.GREATER;
const int GREEN_BITS = RenderingContextBase.GREEN_BITS;
const int HALF_FLOAT_OES = OesTextureHalfFloat.HALF_FLOAT_OES;
const int HIGH_FLOAT = RenderingContextBase.HIGH_FLOAT;
const int HIGH_INT = RenderingContextBase.HIGH_INT;
const int INCR = RenderingContextBase.INCR;
const int INCR_WRAP = RenderingContextBase.INCR_WRAP;
const int INT = RenderingContextBase.INT;
const int INT_VEC2 = RenderingContextBase.INT_VEC2;
const int INT_VEC3 = RenderingContextBase.INT_VEC3;
const int INT_VEC4 = RenderingContextBase.INT_VEC4;
const int INVALID_ENUM = RenderingContextBase.INVALID_ENUM;
const int INVALID_FRAMEBUFFER_OPERATION = RenderingContextBase.INVALID_FRAMEBUFFER_OPERATION;
const int INVALID_OPERATION = RenderingContextBase.INVALID_OPERATION;
const int INVALID_VALUE = RenderingContextBase.INVALID_VALUE;
const int INVERT = RenderingContextBase.INVERT;
const int KEEP = RenderingContextBase.KEEP;
const int LEQUAL = RenderingContextBase.LEQUAL;
const int LESS = RenderingContextBase.LESS;
const int LINEAR = RenderingContextBase.LINEAR;
const int LINEAR_MIPMAP_LINEAR = RenderingContextBase.LINEAR_MIPMAP_LINEAR;
const int LINEAR_MIPMAP_NEAREST = RenderingContextBase.LINEAR_MIPMAP_NEAREST;
const int LINES = RenderingContextBase.LINES;
const int LINE_LOOP = RenderingContextBase.LINE_LOOP;
const int LINE_STRIP = RenderingContextBase.LINE_STRIP;
const int LINE_WIDTH = RenderingContextBase.LINE_WIDTH;
const int LINK_STATUS = RenderingContextBase.LINK_STATUS;
const int LOW_FLOAT = RenderingContextBase.LOW_FLOAT;
const int LOW_INT = RenderingContextBase.LOW_INT;
const int LUMINANCE = RenderingContextBase.LUMINANCE;
const int LUMINANCE_ALPHA = RenderingContextBase.LUMINANCE_ALPHA;
const int MAX_COMBINED_TEXTURE_IMAGE_UNITS = RenderingContextBase.MAX_COMBINED_TEXTURE_IMAGE_UNITS;
const int MAX_CUBE_MAP_TEXTURE_SIZE = RenderingContextBase.MAX_CUBE_MAP_TEXTURE_SIZE;
const int MAX_FRAGMENT_UNIFORM_VECTORS = RenderingContextBase.MAX_FRAGMENT_UNIFORM_VECTORS;
const int MAX_RENDERBUFFER_SIZE = RenderingContextBase.MAX_RENDERBUFFER_SIZE;
const int MAX_TEXTURE_IMAGE_UNITS = RenderingContextBase.MAX_TEXTURE_IMAGE_UNITS;
const int MAX_TEXTURE_SIZE = RenderingContextBase.MAX_TEXTURE_SIZE;
const int MAX_VARYING_VECTORS = RenderingContextBase.MAX_VARYING_VECTORS;
const int MAX_VERTEX_ATTRIBS = RenderingContextBase.MAX_VERTEX_ATTRIBS;
const int MAX_VERTEX_TEXTURE_IMAGE_UNITS = RenderingContextBase.MAX_VERTEX_TEXTURE_IMAGE_UNITS;
const int MAX_VERTEX_UNIFORM_VECTORS = RenderingContextBase.MAX_VERTEX_UNIFORM_VECTORS;
const int MAX_VIEWPORT_DIMS = RenderingContextBase.MAX_VIEWPORT_DIMS;
const int MEDIUM_FLOAT = RenderingContextBase.MEDIUM_FLOAT;
const int MEDIUM_INT = RenderingContextBase.MEDIUM_INT;
const int MIRRORED_REPEAT = RenderingContextBase.MIRRORED_REPEAT;
const int NEAREST = RenderingContextBase.NEAREST;
const int NEAREST_MIPMAP_LINEAR = RenderingContextBase.NEAREST_MIPMAP_LINEAR;
const int NEAREST_MIPMAP_NEAREST = RenderingContextBase.NEAREST_MIPMAP_NEAREST;
const int NEVER = RenderingContextBase.NEVER;
const int NICEST = RenderingContextBase.NICEST;
const int NONE = RenderingContextBase.NONE;
const int NOTEQUAL = RenderingContextBase.NOTEQUAL;
const int NO_ERROR = RenderingContextBase.NO_ERROR;
const int ONE = RenderingContextBase.ONE;
const int ONE_MINUS_CONSTANT_ALPHA = RenderingContextBase.ONE_MINUS_CONSTANT_ALPHA;
const int ONE_MINUS_CONSTANT_COLOR = RenderingContextBase.ONE_MINUS_CONSTANT_COLOR;
const int ONE_MINUS_DST_ALPHA = RenderingContextBase.ONE_MINUS_DST_ALPHA;
const int ONE_MINUS_DST_COLOR = RenderingContextBase.ONE_MINUS_DST_COLOR;
const int ONE_MINUS_SRC_ALPHA = RenderingContextBase.ONE_MINUS_SRC_ALPHA;
const int ONE_MINUS_SRC_COLOR = RenderingContextBase.ONE_MINUS_SRC_COLOR;
const int OUT_OF_MEMORY = RenderingContextBase.OUT_OF_MEMORY;
const int PACK_ALIGNMENT = RenderingContextBase.PACK_ALIGNMENT;
const int POINTS = RenderingContextBase.POINTS;
const int POLYGON_OFFSET_FACTOR = RenderingContextBase.POLYGON_OFFSET_FACTOR;
const int POLYGON_OFFSET_FILL = RenderingContextBase.POLYGON_OFFSET_FILL;
const int POLYGON_OFFSET_UNITS = RenderingContextBase.POLYGON_OFFSET_UNITS;
const int RED_BITS = RenderingContextBase.RED_BITS;
const int RENDERBUFFER = RenderingContextBase.RENDERBUFFER;
const int RENDERBUFFER_ALPHA_SIZE = RenderingContextBase.RENDERBUFFER_ALPHA_SIZE;
const int RENDERBUFFER_BINDING = RenderingContextBase.RENDERBUFFER_BINDING;
const int RENDERBUFFER_BLUE_SIZE = RenderingContextBase.RENDERBUFFER_BLUE_SIZE;
const int RENDERBUFFER_DEPTH_SIZE = RenderingContextBase.RENDERBUFFER_DEPTH_SIZE;
const int RENDERBUFFER_GREEN_SIZE = RenderingContextBase.RENDERBUFFER_GREEN_SIZE;
const int RENDERBUFFER_HEIGHT = RenderingContextBase.RENDERBUFFER_HEIGHT;
const int RENDERBUFFER_INTERNAL_FORMAT = RenderingContextBase.RENDERBUFFER_INTERNAL_FORMAT;
const int RENDERBUFFER_RED_SIZE = RenderingContextBase.RENDERBUFFER_RED_SIZE;
const int RENDERBUFFER_STENCIL_SIZE = RenderingContextBase.RENDERBUFFER_STENCIL_SIZE;
const int RENDERBUFFER_WIDTH = RenderingContextBase.RENDERBUFFER_WIDTH;
const int RENDERER = RenderingContextBase.RENDERER;
const int REPEAT = RenderingContextBase.REPEAT;
const int REPLACE = RenderingContextBase.REPLACE;
const int RGB = RenderingContextBase.RGB;
const int RGB565 = RenderingContextBase.RGB565;
const int RGB5_A1 = RenderingContextBase.RGB5_A1;
const int RGBA = RenderingContextBase.RGBA;
const int RGBA4 = RenderingContextBase.RGBA4;
const int SAMPLER_2D = RenderingContextBase.SAMPLER_2D;
const int SAMPLER_CUBE = RenderingContextBase.SAMPLER_CUBE;
const int SAMPLES = RenderingContextBase.SAMPLES;
const int SAMPLE_ALPHA_TO_COVERAGE = RenderingContextBase.SAMPLE_ALPHA_TO_COVERAGE;
const int SAMPLE_BUFFERS = RenderingContextBase.SAMPLE_BUFFERS;
const int SAMPLE_COVERAGE = RenderingContextBase.SAMPLE_COVERAGE;
const int SAMPLE_COVERAGE_INVERT = RenderingContextBase.SAMPLE_COVERAGE_INVERT;
const int SAMPLE_COVERAGE_VALUE = RenderingContextBase.SAMPLE_COVERAGE_VALUE;
const int SCISSOR_BOX = RenderingContextBase.SCISSOR_BOX;
const int SCISSOR_TEST = RenderingContextBase.SCISSOR_TEST;
const int SHADER_TYPE = RenderingContextBase.SHADER_TYPE;
const int SHADING_LANGUAGE_VERSION = RenderingContextBase.SHADING_LANGUAGE_VERSION;
const int SHORT = RenderingContextBase.SHORT;
const int SRC_ALPHA = RenderingContextBase.SRC_ALPHA;
const int SRC_ALPHA_SATURATE = RenderingContextBase.SRC_ALPHA_SATURATE;
const int SRC_COLOR = RenderingContextBase.SRC_COLOR;
const int STATIC_DRAW = RenderingContextBase.STATIC_DRAW;
const int STENCIL_ATTACHMENT = RenderingContextBase.STENCIL_ATTACHMENT;
const int STENCIL_BACK_FAIL = RenderingContextBase.STENCIL_BACK_FAIL;
const int STENCIL_BACK_FUNC = RenderingContextBase.STENCIL_BACK_FUNC;
const int STENCIL_BACK_PASS_DEPTH_FAIL = RenderingContextBase.STENCIL_BACK_PASS_DEPTH_FAIL;
const int STENCIL_BACK_PASS_DEPTH_PASS = RenderingContextBase.STENCIL_BACK_PASS_DEPTH_PASS;
const int STENCIL_BACK_REF = RenderingContextBase.STENCIL_BACK_REF;
const int STENCIL_BACK_VALUE_MASK = RenderingContextBase.STENCIL_BACK_VALUE_MASK;
const int STENCIL_BACK_WRITEMASK = RenderingContextBase.STENCIL_BACK_WRITEMASK;
const int STENCIL_BITS = RenderingContextBase.STENCIL_BITS;
const int STENCIL_BUFFER_BIT = RenderingContextBase.STENCIL_BUFFER_BIT;
const int STENCIL_CLEAR_VALUE = RenderingContextBase.STENCIL_CLEAR_VALUE;
const int STENCIL_FAIL = RenderingContextBase.STENCIL_FAIL;
const int STENCIL_FUNC = RenderingContextBase.STENCIL_FUNC;
const int STENCIL_INDEX = RenderingContextBase.STENCIL_INDEX;
const int STENCIL_INDEX8 = RenderingContextBase.STENCIL_INDEX8;
const int STENCIL_PASS_DEPTH_FAIL = RenderingContextBase.STENCIL_PASS_DEPTH_FAIL;
const int STENCIL_PASS_DEPTH_PASS = RenderingContextBase.STENCIL_PASS_DEPTH_PASS;
const int STENCIL_REF = RenderingContextBase.STENCIL_REF;
const int STENCIL_TEST = RenderingContextBase.STENCIL_TEST;
const int STENCIL_VALUE_MASK = RenderingContextBase.STENCIL_VALUE_MASK;
const int STENCIL_WRITEMASK = RenderingContextBase.STENCIL_WRITEMASK;
const int STREAM_DRAW = RenderingContextBase.STREAM_DRAW;
const int SUBPIXEL_BITS = RenderingContextBase.SUBPIXEL_BITS;
const int TEXTURE = RenderingContextBase.TEXTURE;
const int TEXTURE0 = RenderingContextBase.TEXTURE0;
const int TEXTURE1 = RenderingContextBase.TEXTURE1;
const int TEXTURE10 = RenderingContextBase.TEXTURE10;
const int TEXTURE11 = RenderingContextBase.TEXTURE11;
const int TEXTURE12 = RenderingContextBase.TEXTURE12;
const int TEXTURE13 = RenderingContextBase.TEXTURE13;
const int TEXTURE14 = RenderingContextBase.TEXTURE14;
const int TEXTURE15 = RenderingContextBase.TEXTURE15;
const int TEXTURE16 = RenderingContextBase.TEXTURE16;
const int TEXTURE17 = RenderingContextBase.TEXTURE17;
const int TEXTURE18 = RenderingContextBase.TEXTURE18;
const int TEXTURE19 = RenderingContextBase.TEXTURE19;
const int TEXTURE2 = RenderingContextBase.TEXTURE2;
const int TEXTURE20 = RenderingContextBase.TEXTURE20;
const int TEXTURE21 = RenderingContextBase.TEXTURE21;
const int TEXTURE22 = RenderingContextBase.TEXTURE22;
const int TEXTURE23 = RenderingContextBase.TEXTURE23;
const int TEXTURE24 = RenderingContextBase.TEXTURE24;
const int TEXTURE25 = RenderingContextBase.TEXTURE25;
const int TEXTURE26 = RenderingContextBase.TEXTURE26;
const int TEXTURE27 = RenderingContextBase.TEXTURE27;
const int TEXTURE28 = RenderingContextBase.TEXTURE28;
const int TEXTURE29 = RenderingContextBase.TEXTURE29;
const int TEXTURE3 = RenderingContextBase.TEXTURE3;
const int TEXTURE30 = RenderingContextBase.TEXTURE30;
const int TEXTURE31 = RenderingContextBase.TEXTURE31;
const int TEXTURE4 = RenderingContextBase.TEXTURE4;
const int TEXTURE5 = RenderingContextBase.TEXTURE5;
const int TEXTURE6 = RenderingContextBase.TEXTURE6;
const int TEXTURE7 = RenderingContextBase.TEXTURE7;
const int TEXTURE8 = RenderingContextBase.TEXTURE8;
const int TEXTURE9 = RenderingContextBase.TEXTURE9;
const int TEXTURE_2D = RenderingContextBase.TEXTURE_2D;
const int TEXTURE_BINDING_2D = RenderingContextBase.TEXTURE_BINDING_2D;
const int TEXTURE_BINDING_CUBE_MAP = RenderingContextBase.TEXTURE_BINDING_CUBE_MAP;
const int TEXTURE_CUBE_MAP = RenderingContextBase.TEXTURE_CUBE_MAP;
const int TEXTURE_CUBE_MAP_NEGATIVE_X = RenderingContextBase.TEXTURE_CUBE_MAP_NEGATIVE_X;
const int TEXTURE_CUBE_MAP_NEGATIVE_Y = RenderingContextBase.TEXTURE_CUBE_MAP_NEGATIVE_Y;
const int TEXTURE_CUBE_MAP_NEGATIVE_Z = RenderingContextBase.TEXTURE_CUBE_MAP_NEGATIVE_Z;
const int TEXTURE_CUBE_MAP_POSITIVE_X = RenderingContextBase.TEXTURE_CUBE_MAP_POSITIVE_X;
const int TEXTURE_CUBE_MAP_POSITIVE_Y = RenderingContextBase.TEXTURE_CUBE_MAP_POSITIVE_Y;
const int TEXTURE_CUBE_MAP_POSITIVE_Z = RenderingContextBase.TEXTURE_CUBE_MAP_POSITIVE_Z;
const int TEXTURE_MAG_FILTER = RenderingContextBase.TEXTURE_MAG_FILTER;
const int TEXTURE_MIN_FILTER = RenderingContextBase.TEXTURE_MIN_FILTER;
const int TEXTURE_WRAP_S = RenderingContextBase.TEXTURE_WRAP_S;
const int TEXTURE_WRAP_T = RenderingContextBase.TEXTURE_WRAP_T;
const int TRIANGLES = RenderingContextBase.TRIANGLES;
const int TRIANGLE_FAN = RenderingContextBase.TRIANGLE_FAN;
const int TRIANGLE_STRIP = RenderingContextBase.TRIANGLE_STRIP;
const int UNPACK_ALIGNMENT = RenderingContextBase.UNPACK_ALIGNMENT;
const int UNPACK_COLORSPACE_CONVERSION_WEBGL = RenderingContextBase.UNPACK_COLORSPACE_CONVERSION_WEBGL;
const int UNPACK_FLIP_Y_WEBGL = RenderingContextBase.UNPACK_FLIP_Y_WEBGL;
const int UNPACK_PREMULTIPLY_ALPHA_WEBGL = RenderingContextBase.UNPACK_PREMULTIPLY_ALPHA_WEBGL;
const int UNSIGNED_BYTE = RenderingContextBase.UNSIGNED_BYTE;
const int UNSIGNED_INT = RenderingContextBase.UNSIGNED_INT;
const int UNSIGNED_SHORT = RenderingContextBase.UNSIGNED_SHORT;
const int UNSIGNED_SHORT_4_4_4_4 = RenderingContextBase.UNSIGNED_SHORT_4_4_4_4;
const int UNSIGNED_SHORT_5_5_5_1 = RenderingContextBase.UNSIGNED_SHORT_5_5_5_1;
const int UNSIGNED_SHORT_5_6_5 = RenderingContextBase.UNSIGNED_SHORT_5_6_5;
const int VALIDATE_STATUS = RenderingContextBase.VALIDATE_STATUS;
const int VENDOR = RenderingContextBase.VENDOR;
const int VERSION = RenderingContextBase.VERSION;
const int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = RenderingContextBase.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING;
const int VERTEX_ATTRIB_ARRAY_ENABLED = RenderingContextBase.VERTEX_ATTRIB_ARRAY_ENABLED;
const int VERTEX_ATTRIB_ARRAY_NORMALIZED = RenderingContextBase.VERTEX_ATTRIB_ARRAY_NORMALIZED;
const int VERTEX_ATTRIB_ARRAY_POINTER = RenderingContextBase.VERTEX_ATTRIB_ARRAY_POINTER;
const int VERTEX_ATTRIB_ARRAY_SIZE = RenderingContextBase.VERTEX_ATTRIB_ARRAY_SIZE;
const int VERTEX_ATTRIB_ARRAY_STRIDE = RenderingContextBase.VERTEX_ATTRIB_ARRAY_STRIDE;
const int VERTEX_ATTRIB_ARRAY_TYPE = RenderingContextBase.VERTEX_ATTRIB_ARRAY_TYPE;
const int VERTEX_SHADER = RenderingContextBase.VERTEX_SHADER;
const int VIEWPORT = RenderingContextBase.VIEWPORT;
const int ZERO = RenderingContextBase.ZERO;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLActiveInfo')
@Unstable()
class ActiveInfo extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory ActiveInfo._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLActiveInfo.name')
  @DocsEditable()
  String get name => _blink.BlinkWebGLActiveInfo.name_Getter(this);

  @DomName('WebGLActiveInfo.size')
  @DocsEditable()
  int get size => _blink.BlinkWebGLActiveInfo.size_Getter(this);

  @DomName('WebGLActiveInfo.type')
  @DocsEditable()
  int get type => _blink.BlinkWebGLActiveInfo.type_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('ANGLEInstancedArrays')
@Experimental() // untriaged
class AngleInstancedArrays extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AngleInstancedArrays._() { throw new UnsupportedError("Not supported"); }

  @DomName('ANGLEInstancedArrays.VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE = 0x88FE;

  @DomName('ANGLEInstancedArrays.drawArraysInstancedANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  void drawArraysInstancedAngle(int mode, int first, int count, int primcount) => _blink.BlinkANGLEInstancedArrays.drawArraysInstancedANGLE_Callback_ul_long_long_long(this, mode, first, count, primcount);

  @DomName('ANGLEInstancedArrays.drawElementsInstancedANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  void drawElementsInstancedAngle(int mode, int count, int type, int offset, int primcount) => _blink.BlinkANGLEInstancedArrays.drawElementsInstancedANGLE_Callback_ul_long_ul_ll_long(this, mode, count, type, offset, primcount);

  @DomName('ANGLEInstancedArrays.vertexAttribDivisorANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttribDivisorAngle(int index, int divisor) => _blink.BlinkANGLEInstancedArrays.vertexAttribDivisorANGLE_Callback_ul_long(this, index, divisor);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLBuffer')
@Unstable()
class Buffer extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Buffer._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLCompressedTextureATC')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_atc/
@Experimental()
class CompressedTextureAtc extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureAtc._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLCompressedTextureATC.COMPRESSED_RGBA_ATC_EXPLICIT_ALPHA_WEBGL')
  @DocsEditable()
  static const int COMPRESSED_RGBA_ATC_EXPLICIT_ALPHA_WEBGL = 0x8C93;

  @DomName('WebGLCompressedTextureATC.COMPRESSED_RGBA_ATC_INTERPOLATED_ALPHA_WEBGL')
  @DocsEditable()
  static const int COMPRESSED_RGBA_ATC_INTERPOLATED_ALPHA_WEBGL = 0x87EE;

  @DomName('WebGLCompressedTextureATC.COMPRESSED_RGB_ATC_WEBGL')
  @DocsEditable()
  static const int COMPRESSED_RGB_ATC_WEBGL = 0x8C92;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLCompressedTextureETC1')
@Experimental() // untriaged
class CompressedTextureETC1 extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureETC1._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLCompressedTextureETC1.COMPRESSED_RGB_ETC1_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGB_ETC1_WEBGL = 0x8D64;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLCompressedTexturePVRTC')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_pvrtc/
@Experimental() // experimental
class CompressedTexturePvrtc extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory CompressedTexturePvrtc._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLCompressedTexturePVRTC.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG')
  @DocsEditable()
  static const int COMPRESSED_RGBA_PVRTC_2BPPV1_IMG = 0x8C03;

  @DomName('WebGLCompressedTexturePVRTC.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG')
  @DocsEditable()
  static const int COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;

  @DomName('WebGLCompressedTexturePVRTC.COMPRESSED_RGB_PVRTC_2BPPV1_IMG')
  @DocsEditable()
  static const int COMPRESSED_RGB_PVRTC_2BPPV1_IMG = 0x8C01;

  @DomName('WebGLCompressedTexturePVRTC.COMPRESSED_RGB_PVRTC_4BPPV1_IMG')
  @DocsEditable()
  static const int COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLCompressedTextureS3TC')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_s3tc/
@Experimental() // experimental
class CompressedTextureS3TC extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureS3TC._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLCompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT1_EXT')
  @DocsEditable()
  static const int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  @DomName('WebGLCompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT3_EXT')
  @DocsEditable()
  static const int COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;

  @DomName('WebGLCompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT5_EXT')
  @DocsEditable()
  static const int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  @DomName('WebGLCompressedTextureS3TC.COMPRESSED_RGB_S3TC_DXT1_EXT')
  @DocsEditable()
  static const int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
/**
 * The properties of a WebGL rendering context.
 *
 * If [alpha] is `true`, then the context has an alpha channel.
 *
 * If [antialias] is `true`, then antialiasing is performed by the browser, but
 * only if the browser's implementation of WebGL supports antialiasing.
 *
 * If [depth] is `true`, then the context has a depth buffer of at least 16
 * bits.
 *
 * If [premultipliedAlpha] is `true`, then the context's colors are assumed to
 * be premultiplied. This means that color values are assumed to have  been
 * multiplied by their alpha values. If [alpha] is `false`, then this flag is
 * ignored.
 *
 * If [preserveDrawingBuffer] is `false`, then all contents of the context are
 * cleared. If `true`, then all values will remain until changed or cleared.
 *
 * If [stencil] is `true`, then the context has a stencil buffer of at least 8
 * bits.
 */
@DomName('WebGLContextAttributes')
@Unstable()
class ContextAttributes extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory ContextAttributes._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLContextAttributes.alpha')
  @DocsEditable()
  bool get alpha => _blink.BlinkWebGLContextAttributes.alpha_Getter(this);

  @DomName('WebGLContextAttributes.alpha')
  @DocsEditable()
  void set alpha(bool value) => _blink.BlinkWebGLContextAttributes.alpha_Setter_boolean(this, value);

  @DomName('WebGLContextAttributes.antialias')
  @DocsEditable()
  bool get antialias => _blink.BlinkWebGLContextAttributes.antialias_Getter(this);

  @DomName('WebGLContextAttributes.antialias')
  @DocsEditable()
  void set antialias(bool value) => _blink.BlinkWebGLContextAttributes.antialias_Setter_boolean(this, value);

  @DomName('WebGLContextAttributes.depth')
  @DocsEditable()
  bool get depth => _blink.BlinkWebGLContextAttributes.depth_Getter(this);

  @DomName('WebGLContextAttributes.depth')
  @DocsEditable()
  void set depth(bool value) => _blink.BlinkWebGLContextAttributes.depth_Setter_boolean(this, value);

  @DomName('WebGLContextAttributes.failIfMajorPerformanceCaveat')
  @DocsEditable()
  @Experimental() // untriaged
  bool get failIfMajorPerformanceCaveat => _blink.BlinkWebGLContextAttributes.failIfMajorPerformanceCaveat_Getter(this);

  @DomName('WebGLContextAttributes.failIfMajorPerformanceCaveat')
  @DocsEditable()
  @Experimental() // untriaged
  void set failIfMajorPerformanceCaveat(bool value) => _blink.BlinkWebGLContextAttributes.failIfMajorPerformanceCaveat_Setter_boolean(this, value);

  @DomName('WebGLContextAttributes.premultipliedAlpha')
  @DocsEditable()
  bool get premultipliedAlpha => _blink.BlinkWebGLContextAttributes.premultipliedAlpha_Getter(this);

  @DomName('WebGLContextAttributes.premultipliedAlpha')
  @DocsEditable()
  void set premultipliedAlpha(bool value) => _blink.BlinkWebGLContextAttributes.premultipliedAlpha_Setter_boolean(this, value);

  @DomName('WebGLContextAttributes.preserveDrawingBuffer')
  @DocsEditable()
  bool get preserveDrawingBuffer => _blink.BlinkWebGLContextAttributes.preserveDrawingBuffer_Getter(this);

  @DomName('WebGLContextAttributes.preserveDrawingBuffer')
  @DocsEditable()
  void set preserveDrawingBuffer(bool value) => _blink.BlinkWebGLContextAttributes.preserveDrawingBuffer_Setter_boolean(this, value);

  @DomName('WebGLContextAttributes.stencil')
  @DocsEditable()
  bool get stencil => _blink.BlinkWebGLContextAttributes.stencil_Getter(this);

  @DomName('WebGLContextAttributes.stencil')
  @DocsEditable()
  void set stencil(bool value) => _blink.BlinkWebGLContextAttributes.stencil_Setter_boolean(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLContextEvent')
@Unstable()
class ContextEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory ContextEvent._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLContextEvent.statusMessage')
  @DocsEditable()
  String get statusMessage => _blink.BlinkWebGLContextEvent.statusMessage_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLDebugRendererInfo')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_debug_renderer_info/
@Experimental() // experimental
class DebugRendererInfo extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory DebugRendererInfo._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLDebugRendererInfo.UNMASKED_RENDERER_WEBGL')
  @DocsEditable()
  static const int UNMASKED_RENDERER_WEBGL = 0x9246;

  @DomName('WebGLDebugRendererInfo.UNMASKED_VENDOR_WEBGL')
  @DocsEditable()
  static const int UNMASKED_VENDOR_WEBGL = 0x9245;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLDebugShaders')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_debug_shaders/
@Experimental() // experimental
class DebugShaders extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory DebugShaders._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLDebugShaders.getTranslatedShaderSource')
  @DocsEditable()
  String getTranslatedShaderSource(Shader shader) => _blink.BlinkWebGLDebugShaders.getTranslatedShaderSource_Callback_WebGLShader(this, shader);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLDepthTexture')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_depth_texture/
@Experimental() // experimental
class DepthTexture extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory DepthTexture._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLDepthTexture.UNSIGNED_INT_24_8_WEBGL')
  @DocsEditable()
  static const int UNSIGNED_INT_24_8_WEBGL = 0x84FA;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLDrawBuffers')
// http://www.khronos.org/registry/webgl/specs/latest/
@Experimental() // stable
class DrawBuffers extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory DrawBuffers._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT0_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT0_WEBGL = 0x8CE0;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT10_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT10_WEBGL = 0x8CEA;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT11_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT11_WEBGL = 0x8CEB;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT12_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT12_WEBGL = 0x8CEC;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT13_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT13_WEBGL = 0x8CED;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT14_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT14_WEBGL = 0x8CEE;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT15_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT15_WEBGL = 0x8CEF;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT1_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT1_WEBGL = 0x8CE1;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT2_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT2_WEBGL = 0x8CE2;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT3_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT3_WEBGL = 0x8CE3;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT4_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT4_WEBGL = 0x8CE4;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT5_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT5_WEBGL = 0x8CE5;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT6_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT6_WEBGL = 0x8CE6;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT7_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT7_WEBGL = 0x8CE7;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT8_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT8_WEBGL = 0x8CE8;

  @DomName('WebGLDrawBuffers.COLOR_ATTACHMENT9_WEBGL')
  @DocsEditable()
  static const int COLOR_ATTACHMENT9_WEBGL = 0x8CE9;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER0_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER0_WEBGL = 0x8825;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER10_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER10_WEBGL = 0x882F;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER11_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER11_WEBGL = 0x8830;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER12_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER12_WEBGL = 0x8831;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER13_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER13_WEBGL = 0x8832;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER14_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER14_WEBGL = 0x8833;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER15_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER15_WEBGL = 0x8834;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER1_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER1_WEBGL = 0x8826;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER2_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER2_WEBGL = 0x8827;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER3_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER3_WEBGL = 0x8828;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER4_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER4_WEBGL = 0x8829;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER5_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER5_WEBGL = 0x882A;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER6_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER6_WEBGL = 0x882B;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER7_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER7_WEBGL = 0x882C;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER8_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER8_WEBGL = 0x882D;

  @DomName('WebGLDrawBuffers.DRAW_BUFFER9_WEBGL')
  @DocsEditable()
  static const int DRAW_BUFFER9_WEBGL = 0x882E;

  @DomName('WebGLDrawBuffers.MAX_COLOR_ATTACHMENTS_WEBGL')
  @DocsEditable()
  static const int MAX_COLOR_ATTACHMENTS_WEBGL = 0x8CDF;

  @DomName('WebGLDrawBuffers.MAX_DRAW_BUFFERS_WEBGL')
  @DocsEditable()
  static const int MAX_DRAW_BUFFERS_WEBGL = 0x8824;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('EXTBlendMinMax')
@Experimental() // untriaged
class ExtBlendMinMax extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory ExtBlendMinMax._() { throw new UnsupportedError("Not supported"); }

  @DomName('EXTBlendMinMax.MAX_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_EXT = 0x8008;

  @DomName('EXTBlendMinMax.MIN_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MIN_EXT = 0x8007;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('EXTFragDepth')
// http://www.khronos.org/registry/webgl/extensions/EXT_frag_depth/
@Experimental()
class ExtFragDepth extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory ExtFragDepth._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('EXTShaderTextureLOD')
@Experimental() // untriaged
class ExtShaderTextureLod extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory ExtShaderTextureLod._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('EXTTextureFilterAnisotropic')
// http://www.khronos.org/registry/webgl/extensions/EXT_texture_filter_anisotropic/
@Experimental()
class ExtTextureFilterAnisotropic extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory ExtTextureFilterAnisotropic._() { throw new UnsupportedError("Not supported"); }

  @DomName('EXTTextureFilterAnisotropic.MAX_TEXTURE_MAX_ANISOTROPY_EXT')
  @DocsEditable()
  static const int MAX_TEXTURE_MAX_ANISOTROPY_EXT = 0x84FF;

  @DomName('EXTTextureFilterAnisotropic.TEXTURE_MAX_ANISOTROPY_EXT')
  @DocsEditable()
  static const int TEXTURE_MAX_ANISOTROPY_EXT = 0x84FE;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLFramebuffer')
@Unstable()
class Framebuffer extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Framebuffer._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLLoseContext')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_lose_context/
@Experimental()
class LoseContext extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory LoseContext._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLLoseContext.loseContext')
  @DocsEditable()
  void loseContext() => _blink.BlinkWebGLLoseContext.loseContext_Callback(this);

  @DomName('WebGLLoseContext.restoreContext')
  @DocsEditable()
  void restoreContext() => _blink.BlinkWebGLLoseContext.restoreContext_Callback(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('OESElementIndexUint')
// http://www.khronos.org/registry/webgl/extensions/OES_element_index_uint/
@Experimental() // experimental
class OesElementIndexUint extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory OesElementIndexUint._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('OESStandardDerivatives')
// http://www.khronos.org/registry/webgl/extensions/OES_standard_derivatives/
@Experimental() // experimental
class OesStandardDerivatives extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory OesStandardDerivatives._() { throw new UnsupportedError("Not supported"); }

  @DomName('OESStandardDerivatives.FRAGMENT_SHADER_DERIVATIVE_HINT_OES')
  @DocsEditable()
  static const int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('OESTextureFloat')
// http://www.khronos.org/registry/webgl/extensions/OES_texture_float/
@Experimental() // experimental
class OesTextureFloat extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory OesTextureFloat._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('OESTextureFloatLinear')
// http://www.khronos.org/registry/webgl/extensions/OES_texture_float_linear/
@Experimental()
class OesTextureFloatLinear extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory OesTextureFloatLinear._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('OESTextureHalfFloat')
// http://www.khronos.org/registry/webgl/extensions/OES_texture_half_float/
@Experimental() // experimental
class OesTextureHalfFloat extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory OesTextureHalfFloat._() { throw new UnsupportedError("Not supported"); }

  @DomName('OESTextureHalfFloat.HALF_FLOAT_OES')
  @DocsEditable()
  static const int HALF_FLOAT_OES = 0x8D61;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('OESTextureHalfFloatLinear')
// http://www.khronos.org/registry/webgl/extensions/OES_texture_half_float_linear/
@Experimental()
class OesTextureHalfFloatLinear extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory OesTextureHalfFloatLinear._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('OESVertexArrayObject')
// http://www.khronos.org/registry/webgl/extensions/OES_vertex_array_object/
@Experimental() // experimental
class OesVertexArrayObject extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory OesVertexArrayObject._() { throw new UnsupportedError("Not supported"); }

  @DomName('OESVertexArrayObject.VERTEX_ARRAY_BINDING_OES')
  @DocsEditable()
  static const int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  @DomName('OESVertexArrayObject.bindVertexArrayOES')
  @DocsEditable()
  void bindVertexArray(VertexArrayObject arrayObject) => _blink.BlinkOESVertexArrayObject.bindVertexArrayOES_Callback_WebGLVertexArrayObjectOES(this, arrayObject);

  @DomName('OESVertexArrayObject.createVertexArrayOES')
  @DocsEditable()
  VertexArrayObject createVertexArray() => _blink.BlinkOESVertexArrayObject.createVertexArrayOES_Callback(this);

  @DomName('OESVertexArrayObject.deleteVertexArrayOES')
  @DocsEditable()
  void deleteVertexArray(VertexArrayObject arrayObject) => _blink.BlinkOESVertexArrayObject.deleteVertexArrayOES_Callback_WebGLVertexArrayObjectOES(this, arrayObject);

  @DomName('OESVertexArrayObject.isVertexArrayOES')
  @DocsEditable()
  bool isVertexArray(VertexArrayObject arrayObject) => _blink.BlinkOESVertexArrayObject.isVertexArrayOES_Callback_WebGLVertexArrayObjectOES(this, arrayObject);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLProgram')
@Unstable()
class Program extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Program._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLRenderbuffer')
@Unstable()
class Renderbuffer extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Renderbuffer._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('WebGLRenderingContext')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Experimental()
@Unstable()
class RenderingContext extends NativeFieldWrapperClass2 implements CanvasRenderingContext {
  // To suppress missing implicit constructor warnings.
  factory RenderingContext._() { throw new UnsupportedError("Not supported"); }

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('WebGLRenderingContext.canvas')
  @DocsEditable()
  @Experimental() // untriaged
  CanvasElement get canvas => _blink.BlinkWebGLRenderingContext.canvas_Getter(this);

  @DomName('WebGLRenderingContext.drawingBufferHeight')
  @DocsEditable()
  int get drawingBufferHeight => _blink.BlinkWebGLRenderingContext.drawingBufferHeight_Getter(this);

  @DomName('WebGLRenderingContext.drawingBufferWidth')
  @DocsEditable()
  int get drawingBufferWidth => _blink.BlinkWebGLRenderingContext.drawingBufferWidth_Getter(this);

  @DomName('WebGLRenderingContext.activeTexture')
  @DocsEditable()
  void activeTexture(int texture) => _blink.BlinkWebGLRenderingContext.activeTexture_Callback_ul(this, texture);

  @DomName('WebGLRenderingContext.attachShader')
  @DocsEditable()
  void attachShader(Program program, Shader shader) => _blink.BlinkWebGLRenderingContext.attachShader_Callback_WebGLProgram_WebGLShader(this, program, shader);

  @DomName('WebGLRenderingContext.bindAttribLocation')
  @DocsEditable()
  void bindAttribLocation(Program program, int index, String name) => _blink.BlinkWebGLRenderingContext.bindAttribLocation_Callback_WebGLProgram_ul_DOMString(this, program, index, name);

  @DomName('WebGLRenderingContext.bindBuffer')
  @DocsEditable()
  void bindBuffer(int target, Buffer buffer) => _blink.BlinkWebGLRenderingContext.bindBuffer_Callback_ul_WebGLBuffer(this, target, buffer);

  @DomName('WebGLRenderingContext.bindFramebuffer')
  @DocsEditable()
  void bindFramebuffer(int target, Framebuffer framebuffer) => _blink.BlinkWebGLRenderingContext.bindFramebuffer_Callback_ul_WebGLFramebuffer(this, target, framebuffer);

  @DomName('WebGLRenderingContext.bindRenderbuffer')
  @DocsEditable()
  void bindRenderbuffer(int target, Renderbuffer renderbuffer) => _blink.BlinkWebGLRenderingContext.bindRenderbuffer_Callback_ul_WebGLRenderbuffer(this, target, renderbuffer);

  @DomName('WebGLRenderingContext.bindTexture')
  @DocsEditable()
  void bindTexture(int target, Texture texture) => _blink.BlinkWebGLRenderingContext.bindTexture_Callback_ul_WebGLTexture(this, target, texture);

  @DomName('WebGLRenderingContext.blendColor')
  @DocsEditable()
  void blendColor(num red, num green, num blue, num alpha) => _blink.BlinkWebGLRenderingContext.blendColor_Callback_float_float_float_float(this, red, green, blue, alpha);

  @DomName('WebGLRenderingContext.blendEquation')
  @DocsEditable()
  void blendEquation(int mode) => _blink.BlinkWebGLRenderingContext.blendEquation_Callback_ul(this, mode);

  @DomName('WebGLRenderingContext.blendEquationSeparate')
  @DocsEditable()
  void blendEquationSeparate(int modeRGB, int modeAlpha) => _blink.BlinkWebGLRenderingContext.blendEquationSeparate_Callback_ul_ul(this, modeRGB, modeAlpha);

  @DomName('WebGLRenderingContext.blendFunc')
  @DocsEditable()
  void blendFunc(int sfactor, int dfactor) => _blink.BlinkWebGLRenderingContext.blendFunc_Callback_ul_ul(this, sfactor, dfactor);

  @DomName('WebGLRenderingContext.blendFuncSeparate')
  @DocsEditable()
  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) => _blink.BlinkWebGLRenderingContext.blendFuncSeparate_Callback_ul_ul_ul_ul(this, srcRGB, dstRGB, srcAlpha, dstAlpha);

  @DomName('WebGLRenderingContext.bufferByteData')
  @DocsEditable()
  void bufferByteData(int target, ByteBuffer data, int usage) => _blink.BlinkWebGLRenderingContext.bufferData_Callback_ul_ArrayBuffer_ul(this, target, data, usage);

  void bufferData(int target, data_OR_size, int usage) {
    if ((usage is int) && (data_OR_size is int) && (target is int)) {
      _blink.BlinkWebGLRenderingContext.bufferData_Callback_ul_ll_ul(this, target, data_OR_size, usage);
      return;
    }
    if ((usage is int) && (data_OR_size is TypedData) && (target is int)) {
      _blink.BlinkWebGLRenderingContext.bufferData_Callback_ul_ArrayBufferView_ul(this, target, data_OR_size, usage);
      return;
    }
    if ((usage is int) && (data_OR_size is ByteBuffer || data_OR_size == null) && (target is int)) {
      _blink.BlinkWebGLRenderingContext.bufferData_Callback_ul_ArrayBuffer_ul(this, target, data_OR_size, usage);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContext.bufferDataTyped')
  @DocsEditable()
  void bufferDataTyped(int target, TypedData data, int usage) => _blink.BlinkWebGLRenderingContext.bufferData_Callback_ul_ArrayBufferView_ul(this, target, data, usage);

  @DomName('WebGLRenderingContext.bufferSubByteData')
  @DocsEditable()
  void bufferSubByteData(int target, int offset, ByteBuffer data) => _blink.BlinkWebGLRenderingContext.bufferSubData_Callback_ul_ll_ArrayBuffer(this, target, offset, data);

  void bufferSubData(int target, int offset, data) {
    if ((data is TypedData) && (offset is int) && (target is int)) {
      _blink.BlinkWebGLRenderingContext.bufferSubData_Callback_ul_ll_ArrayBufferView(this, target, offset, data);
      return;
    }
    if ((data is ByteBuffer || data == null) && (offset is int) && (target is int)) {
      _blink.BlinkWebGLRenderingContext.bufferSubData_Callback_ul_ll_ArrayBuffer(this, target, offset, data);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContext.bufferSubDataTyped')
  @DocsEditable()
  void bufferSubDataTyped(int target, int offset, TypedData data) => _blink.BlinkWebGLRenderingContext.bufferSubData_Callback_ul_ll_ArrayBufferView(this, target, offset, data);

  @DomName('WebGLRenderingContext.checkFramebufferStatus')
  @DocsEditable()
  int checkFramebufferStatus(int target) => _blink.BlinkWebGLRenderingContext.checkFramebufferStatus_Callback_ul(this, target);

  @DomName('WebGLRenderingContext.clear')
  @DocsEditable()
  void clear(int mask) => _blink.BlinkWebGLRenderingContext.clear_Callback_ul(this, mask);

  @DomName('WebGLRenderingContext.clearColor')
  @DocsEditable()
  void clearColor(num red, num green, num blue, num alpha) => _blink.BlinkWebGLRenderingContext.clearColor_Callback_float_float_float_float(this, red, green, blue, alpha);

  @DomName('WebGLRenderingContext.clearDepth')
  @DocsEditable()
  void clearDepth(num depth) => _blink.BlinkWebGLRenderingContext.clearDepth_Callback_float(this, depth);

  @DomName('WebGLRenderingContext.clearStencil')
  @DocsEditable()
  void clearStencil(int s) => _blink.BlinkWebGLRenderingContext.clearStencil_Callback_long(this, s);

  @DomName('WebGLRenderingContext.colorMask')
  @DocsEditable()
  void colorMask(bool red, bool green, bool blue, bool alpha) => _blink.BlinkWebGLRenderingContext.colorMask_Callback_boolean_boolean_boolean_boolean(this, red, green, blue, alpha);

  @DomName('WebGLRenderingContext.compileShader')
  @DocsEditable()
  void compileShader(Shader shader) => _blink.BlinkWebGLRenderingContext.compileShader_Callback_WebGLShader(this, shader);

  @DomName('WebGLRenderingContext.compressedTexImage2D')
  @DocsEditable()
  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, TypedData data) => _blink.BlinkWebGLRenderingContext.compressedTexImage2D_Callback_ul_long_ul_long_long_long_ArrayBufferView(this, target, level, internalformat, width, height, border, data);

  @DomName('WebGLRenderingContext.compressedTexSubImage2D')
  @DocsEditable()
  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, TypedData data) => _blink.BlinkWebGLRenderingContext.compressedTexSubImage2D_Callback_ul_long_long_long_long_long_ul_ArrayBufferView(this, target, level, xoffset, yoffset, width, height, format, data);

  @DomName('WebGLRenderingContext.copyTexImage2D')
  @DocsEditable()
  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) => _blink.BlinkWebGLRenderingContext.copyTexImage2D_Callback_ul_long_ul_long_long_long_long_long(this, target, level, internalformat, x, y, width, height, border);

  @DomName('WebGLRenderingContext.copyTexSubImage2D')
  @DocsEditable()
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) => _blink.BlinkWebGLRenderingContext.copyTexSubImage2D_Callback_ul_long_long_long_long_long_long_long(this, target, level, xoffset, yoffset, x, y, width, height);

  @DomName('WebGLRenderingContext.createBuffer')
  @DocsEditable()
  Buffer createBuffer() => _blink.BlinkWebGLRenderingContext.createBuffer_Callback(this);

  @DomName('WebGLRenderingContext.createFramebuffer')
  @DocsEditable()
  Framebuffer createFramebuffer() => _blink.BlinkWebGLRenderingContext.createFramebuffer_Callback(this);

  @DomName('WebGLRenderingContext.createProgram')
  @DocsEditable()
  Program createProgram() => _blink.BlinkWebGLRenderingContext.createProgram_Callback(this);

  @DomName('WebGLRenderingContext.createRenderbuffer')
  @DocsEditable()
  Renderbuffer createRenderbuffer() => _blink.BlinkWebGLRenderingContext.createRenderbuffer_Callback(this);

  @DomName('WebGLRenderingContext.createShader')
  @DocsEditable()
  Shader createShader(int type) => _blink.BlinkWebGLRenderingContext.createShader_Callback_ul(this, type);

  @DomName('WebGLRenderingContext.createTexture')
  @DocsEditable()
  Texture createTexture() => _blink.BlinkWebGLRenderingContext.createTexture_Callback(this);

  @DomName('WebGLRenderingContext.cullFace')
  @DocsEditable()
  void cullFace(int mode) => _blink.BlinkWebGLRenderingContext.cullFace_Callback_ul(this, mode);

  @DomName('WebGLRenderingContext.deleteBuffer')
  @DocsEditable()
  void deleteBuffer(Buffer buffer) => _blink.BlinkWebGLRenderingContext.deleteBuffer_Callback_WebGLBuffer(this, buffer);

  @DomName('WebGLRenderingContext.deleteFramebuffer')
  @DocsEditable()
  void deleteFramebuffer(Framebuffer framebuffer) => _blink.BlinkWebGLRenderingContext.deleteFramebuffer_Callback_WebGLFramebuffer(this, framebuffer);

  @DomName('WebGLRenderingContext.deleteProgram')
  @DocsEditable()
  void deleteProgram(Program program) => _blink.BlinkWebGLRenderingContext.deleteProgram_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContext.deleteRenderbuffer')
  @DocsEditable()
  void deleteRenderbuffer(Renderbuffer renderbuffer) => _blink.BlinkWebGLRenderingContext.deleteRenderbuffer_Callback_WebGLRenderbuffer(this, renderbuffer);

  @DomName('WebGLRenderingContext.deleteShader')
  @DocsEditable()
  void deleteShader(Shader shader) => _blink.BlinkWebGLRenderingContext.deleteShader_Callback_WebGLShader(this, shader);

  @DomName('WebGLRenderingContext.deleteTexture')
  @DocsEditable()
  void deleteTexture(Texture texture) => _blink.BlinkWebGLRenderingContext.deleteTexture_Callback_WebGLTexture(this, texture);

  @DomName('WebGLRenderingContext.depthFunc')
  @DocsEditable()
  void depthFunc(int func) => _blink.BlinkWebGLRenderingContext.depthFunc_Callback_ul(this, func);

  @DomName('WebGLRenderingContext.depthMask')
  @DocsEditable()
  void depthMask(bool flag) => _blink.BlinkWebGLRenderingContext.depthMask_Callback_boolean(this, flag);

  @DomName('WebGLRenderingContext.depthRange')
  @DocsEditable()
  void depthRange(num zNear, num zFar) => _blink.BlinkWebGLRenderingContext.depthRange_Callback_float_float(this, zNear, zFar);

  @DomName('WebGLRenderingContext.detachShader')
  @DocsEditable()
  void detachShader(Program program, Shader shader) => _blink.BlinkWebGLRenderingContext.detachShader_Callback_WebGLProgram_WebGLShader(this, program, shader);

  @DomName('WebGLRenderingContext.disable')
  @DocsEditable()
  void disable(int cap) => _blink.BlinkWebGLRenderingContext.disable_Callback_ul(this, cap);

  @DomName('WebGLRenderingContext.disableVertexAttribArray')
  @DocsEditable()
  void disableVertexAttribArray(int index) => _blink.BlinkWebGLRenderingContext.disableVertexAttribArray_Callback_ul(this, index);

  @DomName('WebGLRenderingContext.drawArrays')
  @DocsEditable()
  void drawArrays(int mode, int first, int count) => _blink.BlinkWebGLRenderingContext.drawArrays_Callback_ul_long_long(this, mode, first, count);

  @DomName('WebGLRenderingContext.drawElements')
  @DocsEditable()
  void drawElements(int mode, int count, int type, int offset) => _blink.BlinkWebGLRenderingContext.drawElements_Callback_ul_long_ul_ll(this, mode, count, type, offset);

  @DomName('WebGLRenderingContext.enable')
  @DocsEditable()
  void enable(int cap) => _blink.BlinkWebGLRenderingContext.enable_Callback_ul(this, cap);

  @DomName('WebGLRenderingContext.enableVertexAttribArray')
  @DocsEditable()
  void enableVertexAttribArray(int index) => _blink.BlinkWebGLRenderingContext.enableVertexAttribArray_Callback_ul(this, index);

  @DomName('WebGLRenderingContext.finish')
  @DocsEditable()
  void finish() => _blink.BlinkWebGLRenderingContext.finish_Callback(this);

  @DomName('WebGLRenderingContext.flush')
  @DocsEditable()
  void flush() => _blink.BlinkWebGLRenderingContext.flush_Callback(this);

  @DomName('WebGLRenderingContext.framebufferRenderbuffer')
  @DocsEditable()
  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, Renderbuffer renderbuffer) => _blink.BlinkWebGLRenderingContext.framebufferRenderbuffer_Callback_ul_ul_ul_WebGLRenderbuffer(this, target, attachment, renderbuffertarget, renderbuffer);

  @DomName('WebGLRenderingContext.framebufferTexture2D')
  @DocsEditable()
  void framebufferTexture2D(int target, int attachment, int textarget, Texture texture, int level) => _blink.BlinkWebGLRenderingContext.framebufferTexture2D_Callback_ul_ul_ul_WebGLTexture_long(this, target, attachment, textarget, texture, level);

  @DomName('WebGLRenderingContext.frontFace')
  @DocsEditable()
  void frontFace(int mode) => _blink.BlinkWebGLRenderingContext.frontFace_Callback_ul(this, mode);

  @DomName('WebGLRenderingContext.generateMipmap')
  @DocsEditable()
  void generateMipmap(int target) => _blink.BlinkWebGLRenderingContext.generateMipmap_Callback_ul(this, target);

  @DomName('WebGLRenderingContext.getActiveAttrib')
  @DocsEditable()
  ActiveInfo getActiveAttrib(Program program, int index) => _blink.BlinkWebGLRenderingContext.getActiveAttrib_Callback_WebGLProgram_ul(this, program, index);

  @DomName('WebGLRenderingContext.getActiveUniform')
  @DocsEditable()
  ActiveInfo getActiveUniform(Program program, int index) => _blink.BlinkWebGLRenderingContext.getActiveUniform_Callback_WebGLProgram_ul(this, program, index);

  @DomName('WebGLRenderingContext.getAttachedShaders')
  @DocsEditable()
  List<Shader> getAttachedShaders(Program program) => _blink.BlinkWebGLRenderingContext.getAttachedShaders_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContext.getAttribLocation')
  @DocsEditable()
  int getAttribLocation(Program program, String name) => _blink.BlinkWebGLRenderingContext.getAttribLocation_Callback_WebGLProgram_DOMString(this, program, name);

  @DomName('WebGLRenderingContext.getBufferParameter')
  @DocsEditable()
  Object getBufferParameter(int target, int pname) => _blink.BlinkWebGLRenderingContext.getBufferParameter_Callback_ul_ul(this, target, pname);

  @DomName('WebGLRenderingContext.getContextAttributes')
  @DocsEditable()
  ContextAttributes getContextAttributes() => _blink.BlinkWebGLRenderingContext.getContextAttributes_Callback(this);

  @DomName('WebGLRenderingContext.getError')
  @DocsEditable()
  int getError() => _blink.BlinkWebGLRenderingContext.getError_Callback(this);

  @DomName('WebGLRenderingContext.getExtension')
  @DocsEditable()
  Object getExtension(String name) => _blink.BlinkWebGLRenderingContext.getExtension_Callback_DOMString(this, name);

  @DomName('WebGLRenderingContext.getFramebufferAttachmentParameter')
  @DocsEditable()
  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) => _blink.BlinkWebGLRenderingContext.getFramebufferAttachmentParameter_Callback_ul_ul_ul(this, target, attachment, pname);

  @DomName('WebGLRenderingContext.getParameter')
  @DocsEditable()
  Object getParameter(int pname) => _blink.BlinkWebGLRenderingContext.getParameter_Callback_ul(this, pname);

  @DomName('WebGLRenderingContext.getProgramInfoLog')
  @DocsEditable()
  String getProgramInfoLog(Program program) => _blink.BlinkWebGLRenderingContext.getProgramInfoLog_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContext.getProgramParameter')
  @DocsEditable()
  Object getProgramParameter(Program program, int pname) => _blink.BlinkWebGLRenderingContext.getProgramParameter_Callback_WebGLProgram_ul(this, program, pname);

  @DomName('WebGLRenderingContext.getRenderbufferParameter')
  @DocsEditable()
  Object getRenderbufferParameter(int target, int pname) => _blink.BlinkWebGLRenderingContext.getRenderbufferParameter_Callback_ul_ul(this, target, pname);

  @DomName('WebGLRenderingContext.getShaderInfoLog')
  @DocsEditable()
  String getShaderInfoLog(Shader shader) => _blink.BlinkWebGLRenderingContext.getShaderInfoLog_Callback_WebGLShader(this, shader);

  @DomName('WebGLRenderingContext.getShaderParameter')
  @DocsEditable()
  Object getShaderParameter(Shader shader, int pname) => _blink.BlinkWebGLRenderingContext.getShaderParameter_Callback_WebGLShader_ul(this, shader, pname);

  @DomName('WebGLRenderingContext.getShaderPrecisionFormat')
  @DocsEditable()
  ShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype) => _blink.BlinkWebGLRenderingContext.getShaderPrecisionFormat_Callback_ul_ul(this, shadertype, precisiontype);

  @DomName('WebGLRenderingContext.getShaderSource')
  @DocsEditable()
  String getShaderSource(Shader shader) => _blink.BlinkWebGLRenderingContext.getShaderSource_Callback_WebGLShader(this, shader);

  @DomName('WebGLRenderingContext.getSupportedExtensions')
  @DocsEditable()
  List<String> getSupportedExtensions() => _blink.BlinkWebGLRenderingContext.getSupportedExtensions_Callback(this);

  @DomName('WebGLRenderingContext.getTexParameter')
  @DocsEditable()
  Object getTexParameter(int target, int pname) => _blink.BlinkWebGLRenderingContext.getTexParameter_Callback_ul_ul(this, target, pname);

  @DomName('WebGLRenderingContext.getUniform')
  @DocsEditable()
  Object getUniform(Program program, UniformLocation location) => _blink.BlinkWebGLRenderingContext.getUniform_Callback_WebGLProgram_WebGLUniformLocation(this, program, location);

  @DomName('WebGLRenderingContext.getUniformLocation')
  @DocsEditable()
  UniformLocation getUniformLocation(Program program, String name) => _blink.BlinkWebGLRenderingContext.getUniformLocation_Callback_WebGLProgram_DOMString(this, program, name);

  @DomName('WebGLRenderingContext.getVertexAttrib')
  @DocsEditable()
  Object getVertexAttrib(int index, int pname) => _blink.BlinkWebGLRenderingContext.getVertexAttrib_Callback_ul_ul(this, index, pname);

  @DomName('WebGLRenderingContext.getVertexAttribOffset')
  @DocsEditable()
  int getVertexAttribOffset(int index, int pname) => _blink.BlinkWebGLRenderingContext.getVertexAttribOffset_Callback_ul_ul(this, index, pname);

  @DomName('WebGLRenderingContext.hint')
  @DocsEditable()
  void hint(int target, int mode) => _blink.BlinkWebGLRenderingContext.hint_Callback_ul_ul(this, target, mode);

  @DomName('WebGLRenderingContext.isBuffer')
  @DocsEditable()
  bool isBuffer(Buffer buffer) => _blink.BlinkWebGLRenderingContext.isBuffer_Callback_WebGLBuffer(this, buffer);

  @DomName('WebGLRenderingContext.isContextLost')
  @DocsEditable()
  bool isContextLost() => _blink.BlinkWebGLRenderingContext.isContextLost_Callback(this);

  @DomName('WebGLRenderingContext.isEnabled')
  @DocsEditable()
  bool isEnabled(int cap) => _blink.BlinkWebGLRenderingContext.isEnabled_Callback_ul(this, cap);

  @DomName('WebGLRenderingContext.isFramebuffer')
  @DocsEditable()
  bool isFramebuffer(Framebuffer framebuffer) => _blink.BlinkWebGLRenderingContext.isFramebuffer_Callback_WebGLFramebuffer(this, framebuffer);

  @DomName('WebGLRenderingContext.isProgram')
  @DocsEditable()
  bool isProgram(Program program) => _blink.BlinkWebGLRenderingContext.isProgram_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContext.isRenderbuffer')
  @DocsEditable()
  bool isRenderbuffer(Renderbuffer renderbuffer) => _blink.BlinkWebGLRenderingContext.isRenderbuffer_Callback_WebGLRenderbuffer(this, renderbuffer);

  @DomName('WebGLRenderingContext.isShader')
  @DocsEditable()
  bool isShader(Shader shader) => _blink.BlinkWebGLRenderingContext.isShader_Callback_WebGLShader(this, shader);

  @DomName('WebGLRenderingContext.isTexture')
  @DocsEditable()
  bool isTexture(Texture texture) => _blink.BlinkWebGLRenderingContext.isTexture_Callback_WebGLTexture(this, texture);

  @DomName('WebGLRenderingContext.lineWidth')
  @DocsEditable()
  void lineWidth(num width) => _blink.BlinkWebGLRenderingContext.lineWidth_Callback_float(this, width);

  @DomName('WebGLRenderingContext.linkProgram')
  @DocsEditable()
  void linkProgram(Program program) => _blink.BlinkWebGLRenderingContext.linkProgram_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContext.pixelStorei')
  @DocsEditable()
  void pixelStorei(int pname, int param) => _blink.BlinkWebGLRenderingContext.pixelStorei_Callback_ul_long(this, pname, param);

  @DomName('WebGLRenderingContext.polygonOffset')
  @DocsEditable()
  void polygonOffset(num factor, num units) => _blink.BlinkWebGLRenderingContext.polygonOffset_Callback_float_float(this, factor, units);

  @DomName('WebGLRenderingContext.readPixels')
  @DocsEditable()
  void readPixels(int x, int y, int width, int height, int format, int type, TypedData pixels) => _blink.BlinkWebGLRenderingContext.readPixels_Callback_long_long_long_long_ul_ul_ArrayBufferView(this, x, y, width, height, format, type, pixels);

  @DomName('WebGLRenderingContext.renderbufferStorage')
  @DocsEditable()
  void renderbufferStorage(int target, int internalformat, int width, int height) => _blink.BlinkWebGLRenderingContext.renderbufferStorage_Callback_ul_ul_long_long(this, target, internalformat, width, height);

  @DomName('WebGLRenderingContext.sampleCoverage')
  @DocsEditable()
  void sampleCoverage(num value, bool invert) => _blink.BlinkWebGLRenderingContext.sampleCoverage_Callback_float_boolean(this, value, invert);

  @DomName('WebGLRenderingContext.scissor')
  @DocsEditable()
  void scissor(int x, int y, int width, int height) => _blink.BlinkWebGLRenderingContext.scissor_Callback_long_long_long_long(this, x, y, width, height);

  @DomName('WebGLRenderingContext.shaderSource')
  @DocsEditable()
  void shaderSource(Shader shader, String string) => _blink.BlinkWebGLRenderingContext.shaderSource_Callback_WebGLShader_DOMString(this, shader, string);

  @DomName('WebGLRenderingContext.stencilFunc')
  @DocsEditable()
  void stencilFunc(int func, int ref, int mask) => _blink.BlinkWebGLRenderingContext.stencilFunc_Callback_ul_long_ul(this, func, ref, mask);

  @DomName('WebGLRenderingContext.stencilFuncSeparate')
  @DocsEditable()
  void stencilFuncSeparate(int face, int func, int ref, int mask) => _blink.BlinkWebGLRenderingContext.stencilFuncSeparate_Callback_ul_ul_long_ul(this, face, func, ref, mask);

  @DomName('WebGLRenderingContext.stencilMask')
  @DocsEditable()
  void stencilMask(int mask) => _blink.BlinkWebGLRenderingContext.stencilMask_Callback_ul(this, mask);

  @DomName('WebGLRenderingContext.stencilMaskSeparate')
  @DocsEditable()
  void stencilMaskSeparate(int face, int mask) => _blink.BlinkWebGLRenderingContext.stencilMaskSeparate_Callback_ul_ul(this, face, mask);

  @DomName('WebGLRenderingContext.stencilOp')
  @DocsEditable()
  void stencilOp(int fail, int zfail, int zpass) => _blink.BlinkWebGLRenderingContext.stencilOp_Callback_ul_ul_ul(this, fail, zfail, zpass);

  @DomName('WebGLRenderingContext.stencilOpSeparate')
  @DocsEditable()
  void stencilOpSeparate(int face, int fail, int zfail, int zpass) => _blink.BlinkWebGLRenderingContext.stencilOpSeparate_Callback_ul_ul_ul_ul(this, face, fail, zfail, zpass);

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, [int format, int type, TypedData pixels]) {
    if ((pixels is TypedData || pixels == null) && (type is int) && (format is int) && (border_OR_canvas_OR_image_OR_pixels_OR_video is int) && (height_OR_type is int) && (format_OR_width is int) && (internalformat is int) && (level is int) && (target is int)) {
      _blink.BlinkWebGLRenderingContext.texImage2D_Callback_ul_long_ul_long_long_long_ul_ul_ArrayBufferView(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int) && (format_OR_width is int) && (internalformat is int) && (level is int) && (target is int) && format == null && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContext.texImage2D_Callback_ul_long_ul_ul_ul_ImageData(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement) && (height_OR_type is int) && (format_OR_width is int) && (internalformat is int) && (level is int) && (target is int) && format == null && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContext.texImage2D_Callback_ul_long_ul_ul_ul_HTMLImageElement(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement) && (height_OR_type is int) && (format_OR_width is int) && (internalformat is int) && (level is int) && (target is int) && format == null && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContext.texImage2D_Callback_ul_long_ul_ul_ul_HTMLCanvasElement(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement) && (height_OR_type is int) && (format_OR_width is int) && (internalformat is int) && (level is int) && (target is int) && format == null && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContext.texImage2D_Callback_ul_long_ul_ul_ul_HTMLVideoElement(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContext.texImage2DCanvas')
  @DocsEditable()
  void texImage2DCanvas(int target, int level, int internalformat, int format, int type, CanvasElement canvas) => _blink.BlinkWebGLRenderingContext.texImage2D_Callback_ul_long_ul_ul_ul_HTMLCanvasElement(this, target, level, internalformat, format, type, canvas);

  @DomName('WebGLRenderingContext.texImage2DImage')
  @DocsEditable()
  void texImage2DImage(int target, int level, int internalformat, int format, int type, ImageElement image) => _blink.BlinkWebGLRenderingContext.texImage2D_Callback_ul_long_ul_ul_ul_HTMLImageElement(this, target, level, internalformat, format, type, image);

  @DomName('WebGLRenderingContext.texImage2DImageData')
  @DocsEditable()
  void texImage2DImageData(int target, int level, int internalformat, int format, int type, ImageData pixels) => _blink.BlinkWebGLRenderingContext.texImage2D_Callback_ul_long_ul_ul_ul_ImageData(this, target, level, internalformat, format, type, pixels);

  @DomName('WebGLRenderingContext.texImage2DVideo')
  @DocsEditable()
  void texImage2DVideo(int target, int level, int internalformat, int format, int type, VideoElement video) => _blink.BlinkWebGLRenderingContext.texImage2D_Callback_ul_long_ul_ul_ul_HTMLVideoElement(this, target, level, internalformat, format, type, video);

  @DomName('WebGLRenderingContext.texParameterf')
  @DocsEditable()
  void texParameterf(int target, int pname, num param) => _blink.BlinkWebGLRenderingContext.texParameterf_Callback_ul_ul_float(this, target, pname, param);

  @DomName('WebGLRenderingContext.texParameteri')
  @DocsEditable()
  void texParameteri(int target, int pname, int param) => _blink.BlinkWebGLRenderingContext.texParameteri_Callback_ul_ul_long(this, target, pname, param);

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, [int type, TypedData pixels]) {
    if ((pixels is TypedData || pixels == null) && (type is int) && (canvas_OR_format_OR_image_OR_pixels_OR_video is int) && (height_OR_type is int) && (format_OR_width is int) && (yoffset is int) && (xoffset is int) && (level is int) && (target is int)) {
      _blink.BlinkWebGLRenderingContext.texSubImage2D_Callback_ul_long_long_long_long_long_ul_ul_ArrayBufferView(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int) && (format_OR_width is int) && (yoffset is int) && (xoffset is int) && (level is int) && (target is int) && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContext.texSubImage2D_Callback_ul_long_long_long_ul_ul_ImageData(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement) && (height_OR_type is int) && (format_OR_width is int) && (yoffset is int) && (xoffset is int) && (level is int) && (target is int) && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContext.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLImageElement(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement) && (height_OR_type is int) && (format_OR_width is int) && (yoffset is int) && (xoffset is int) && (level is int) && (target is int) && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContext.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLCanvasElement(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement) && (height_OR_type is int) && (format_OR_width is int) && (yoffset is int) && (xoffset is int) && (level is int) && (target is int) && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContext.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLVideoElement(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContext.texSubImage2DCanvas')
  @DocsEditable()
  void texSubImage2DCanvas(int target, int level, int xoffset, int yoffset, int format, int type, CanvasElement canvas) => _blink.BlinkWebGLRenderingContext.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLCanvasElement(this, target, level, xoffset, yoffset, format, type, canvas);

  @DomName('WebGLRenderingContext.texSubImage2DImage')
  @DocsEditable()
  void texSubImage2DImage(int target, int level, int xoffset, int yoffset, int format, int type, ImageElement image) => _blink.BlinkWebGLRenderingContext.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLImageElement(this, target, level, xoffset, yoffset, format, type, image);

  @DomName('WebGLRenderingContext.texSubImage2DImageData')
  @DocsEditable()
  void texSubImage2DImageData(int target, int level, int xoffset, int yoffset, int format, int type, ImageData pixels) => _blink.BlinkWebGLRenderingContext.texSubImage2D_Callback_ul_long_long_long_ul_ul_ImageData(this, target, level, xoffset, yoffset, format, type, pixels);

  @DomName('WebGLRenderingContext.texSubImage2DVideo')
  @DocsEditable()
  void texSubImage2DVideo(int target, int level, int xoffset, int yoffset, int format, int type, VideoElement video) => _blink.BlinkWebGLRenderingContext.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLVideoElement(this, target, level, xoffset, yoffset, format, type, video);

  @DomName('WebGLRenderingContext.uniform1f')
  @DocsEditable()
  void uniform1f(UniformLocation location, num x) => _blink.BlinkWebGLRenderingContext.uniform1f_Callback_WebGLUniformLocation_float(this, location, x);

  @DomName('WebGLRenderingContext.uniform1fv')
  @DocsEditable()
  void uniform1fv(UniformLocation location, Float32List v) => _blink.BlinkWebGLRenderingContext.uniform1fv_Callback_WebGLUniformLocation_Float32Array(this, location, v);

  @DomName('WebGLRenderingContext.uniform1i')
  @DocsEditable()
  void uniform1i(UniformLocation location, int x) => _blink.BlinkWebGLRenderingContext.uniform1i_Callback_WebGLUniformLocation_long(this, location, x);

  @DomName('WebGLRenderingContext.uniform1iv')
  @DocsEditable()
  void uniform1iv(UniformLocation location, Int32List v) => _blink.BlinkWebGLRenderingContext.uniform1iv_Callback_WebGLUniformLocation_Int32Array(this, location, v);

  @DomName('WebGLRenderingContext.uniform2f')
  @DocsEditable()
  void uniform2f(UniformLocation location, num x, num y) => _blink.BlinkWebGLRenderingContext.uniform2f_Callback_WebGLUniformLocation_float_float(this, location, x, y);

  @DomName('WebGLRenderingContext.uniform2fv')
  @DocsEditable()
  void uniform2fv(UniformLocation location, Float32List v) => _blink.BlinkWebGLRenderingContext.uniform2fv_Callback_WebGLUniformLocation_Float32Array(this, location, v);

  @DomName('WebGLRenderingContext.uniform2i')
  @DocsEditable()
  void uniform2i(UniformLocation location, int x, int y) => _blink.BlinkWebGLRenderingContext.uniform2i_Callback_WebGLUniformLocation_long_long(this, location, x, y);

  @DomName('WebGLRenderingContext.uniform2iv')
  @DocsEditable()
  void uniform2iv(UniformLocation location, Int32List v) => _blink.BlinkWebGLRenderingContext.uniform2iv_Callback_WebGLUniformLocation_Int32Array(this, location, v);

  @DomName('WebGLRenderingContext.uniform3f')
  @DocsEditable()
  void uniform3f(UniformLocation location, num x, num y, num z) => _blink.BlinkWebGLRenderingContext.uniform3f_Callback_WebGLUniformLocation_float_float_float(this, location, x, y, z);

  @DomName('WebGLRenderingContext.uniform3fv')
  @DocsEditable()
  void uniform3fv(UniformLocation location, Float32List v) => _blink.BlinkWebGLRenderingContext.uniform3fv_Callback_WebGLUniformLocation_Float32Array(this, location, v);

  @DomName('WebGLRenderingContext.uniform3i')
  @DocsEditable()
  void uniform3i(UniformLocation location, int x, int y, int z) => _blink.BlinkWebGLRenderingContext.uniform3i_Callback_WebGLUniformLocation_long_long_long(this, location, x, y, z);

  @DomName('WebGLRenderingContext.uniform3iv')
  @DocsEditable()
  void uniform3iv(UniformLocation location, Int32List v) => _blink.BlinkWebGLRenderingContext.uniform3iv_Callback_WebGLUniformLocation_Int32Array(this, location, v);

  @DomName('WebGLRenderingContext.uniform4f')
  @DocsEditable()
  void uniform4f(UniformLocation location, num x, num y, num z, num w) => _blink.BlinkWebGLRenderingContext.uniform4f_Callback_WebGLUniformLocation_float_float_float_float(this, location, x, y, z, w);

  @DomName('WebGLRenderingContext.uniform4fv')
  @DocsEditable()
  void uniform4fv(UniformLocation location, Float32List v) => _blink.BlinkWebGLRenderingContext.uniform4fv_Callback_WebGLUniformLocation_Float32Array(this, location, v);

  @DomName('WebGLRenderingContext.uniform4i')
  @DocsEditable()
  void uniform4i(UniformLocation location, int x, int y, int z, int w) => _blink.BlinkWebGLRenderingContext.uniform4i_Callback_WebGLUniformLocation_long_long_long_long(this, location, x, y, z, w);

  @DomName('WebGLRenderingContext.uniform4iv')
  @DocsEditable()
  void uniform4iv(UniformLocation location, Int32List v) => _blink.BlinkWebGLRenderingContext.uniform4iv_Callback_WebGLUniformLocation_Int32Array(this, location, v);

  @DomName('WebGLRenderingContext.uniformMatrix2fv')
  @DocsEditable()
  void uniformMatrix2fv(UniformLocation location, bool transpose, Float32List array) => _blink.BlinkWebGLRenderingContext.uniformMatrix2fv_Callback_WebGLUniformLocation_boolean_Float32Array(this, location, transpose, array);

  @DomName('WebGLRenderingContext.uniformMatrix3fv')
  @DocsEditable()
  void uniformMatrix3fv(UniformLocation location, bool transpose, Float32List array) => _blink.BlinkWebGLRenderingContext.uniformMatrix3fv_Callback_WebGLUniformLocation_boolean_Float32Array(this, location, transpose, array);

  @DomName('WebGLRenderingContext.uniformMatrix4fv')
  @DocsEditable()
  void uniformMatrix4fv(UniformLocation location, bool transpose, Float32List array) => _blink.BlinkWebGLRenderingContext.uniformMatrix4fv_Callback_WebGLUniformLocation_boolean_Float32Array(this, location, transpose, array);

  @DomName('WebGLRenderingContext.useProgram')
  @DocsEditable()
  void useProgram(Program program) => _blink.BlinkWebGLRenderingContext.useProgram_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContext.validateProgram')
  @DocsEditable()
  void validateProgram(Program program) => _blink.BlinkWebGLRenderingContext.validateProgram_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContext.vertexAttrib1f')
  @DocsEditable()
  void vertexAttrib1f(int indx, num x) => _blink.BlinkWebGLRenderingContext.vertexAttrib1f_Callback_ul_float(this, indx, x);

  @DomName('WebGLRenderingContext.vertexAttrib1fv')
  @DocsEditable()
  void vertexAttrib1fv(int indx, Float32List values) => _blink.BlinkWebGLRenderingContext.vertexAttrib1fv_Callback_ul_Float32Array(this, indx, values);

  @DomName('WebGLRenderingContext.vertexAttrib2f')
  @DocsEditable()
  void vertexAttrib2f(int indx, num x, num y) => _blink.BlinkWebGLRenderingContext.vertexAttrib2f_Callback_ul_float_float(this, indx, x, y);

  @DomName('WebGLRenderingContext.vertexAttrib2fv')
  @DocsEditable()
  void vertexAttrib2fv(int indx, Float32List values) => _blink.BlinkWebGLRenderingContext.vertexAttrib2fv_Callback_ul_Float32Array(this, indx, values);

  @DomName('WebGLRenderingContext.vertexAttrib3f')
  @DocsEditable()
  void vertexAttrib3f(int indx, num x, num y, num z) => _blink.BlinkWebGLRenderingContext.vertexAttrib3f_Callback_ul_float_float_float(this, indx, x, y, z);

  @DomName('WebGLRenderingContext.vertexAttrib3fv')
  @DocsEditable()
  void vertexAttrib3fv(int indx, Float32List values) => _blink.BlinkWebGLRenderingContext.vertexAttrib3fv_Callback_ul_Float32Array(this, indx, values);

  @DomName('WebGLRenderingContext.vertexAttrib4f')
  @DocsEditable()
  void vertexAttrib4f(int indx, num x, num y, num z, num w) => _blink.BlinkWebGLRenderingContext.vertexAttrib4f_Callback_ul_float_float_float_float(this, indx, x, y, z, w);

  @DomName('WebGLRenderingContext.vertexAttrib4fv')
  @DocsEditable()
  void vertexAttrib4fv(int indx, Float32List values) => _blink.BlinkWebGLRenderingContext.vertexAttrib4fv_Callback_ul_Float32Array(this, indx, values);

  @DomName('WebGLRenderingContext.vertexAttribPointer')
  @DocsEditable()
  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) => _blink.BlinkWebGLRenderingContext.vertexAttribPointer_Callback_ul_long_ul_boolean_long_ll(this, indx, size, type, normalized, stride, offset);

  @DomName('WebGLRenderingContext.viewport')
  @DocsEditable()
  void viewport(int x, int y, int width, int height) => _blink.BlinkWebGLRenderingContext.viewport_Callback_long_long_long_long(this, x, y, width, height);


  /**
   * Sets the currently bound texture to [data].
   *
   * [data] can be either an [ImageElement], a
   * [CanvasElement], a [VideoElement], or an [ImageData] object.
   *
   * To use [texImage2d] with a TypedData object, use [texImage2dTyped].
   *
   */
  void texImage2DUntyped(int targetTexture, int levelOfDetail, 
      int internalFormat, int format, int type, data) {
    if (data is ImageElement) {
      texImage2DImage(targetTexture, levelOfDetail, internalFormat, format,
          type, data);
    } else if (data is ImageData) {
      texImage2DImageData(targetTexture, levelOfDetail, internalFormat, format,
          type, data);
    } else if (data is CanvasElement) {
      texImage2DCanvas(targetTexture, levelOfDetail, internalFormat, format,
          type, data);
    } else {
      texImage2DVideo(targetTexture, levelOfDetail, internalFormat, format,
          type, data);
    }
  }

  /**
   * Sets the currently bound texture to [data].
   */
  void texImage2DTyped(int targetTexture, int levelOfDetail, int internalFormat,
      int width, int height, int border, int format, int type, TypedData data) {
    texImage2D(targetTexture, levelOfDetail, internalFormat,
        width, height, border, format, type, data);
  }

  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * [data] can be either an [ImageElement], a
   * [CanvasElement], a [VideoElement], or an [ImageData] object.
   *
   * To use [texSubImage2d] with a TypedData object, use [texSubImage2dTyped].
   *
   */
  void texSubImage2DUntyped(int targetTexture, int levelOfDetail, 
      int xOffset, int yOffset, int format, int type, data) {
    texSubImage2D(targetTexture, levelOfDetail, xOffset, yOffset,
        format, type, data);
  }

  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   */
  void texSubImage2DTyped(int targetTexture, int levelOfDetail,
      int xOffset, int yOffset, int width, int height, int format,
      int type, TypedData data) {
    texSubImage2D(targetTexture, levelOfDetail, xOffset, yOffset,
        width, height, format, type, data);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLRenderingContextBase')
@Experimental() // untriaged
abstract class RenderingContextBase extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory RenderingContextBase._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLRenderingContextBase.ACTIVE_ATTRIBUTES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ACTIVE_ATTRIBUTES = 0x8B89;

  @DomName('WebGLRenderingContextBase.ACTIVE_TEXTURE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ACTIVE_TEXTURE = 0x84E0;

  @DomName('WebGLRenderingContextBase.ACTIVE_UNIFORMS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ACTIVE_UNIFORMS = 0x8B86;

  @DomName('WebGLRenderingContextBase.ALIASED_LINE_WIDTH_RANGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALIASED_LINE_WIDTH_RANGE = 0x846E;

  @DomName('WebGLRenderingContextBase.ALIASED_POINT_SIZE_RANGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALIASED_POINT_SIZE_RANGE = 0x846D;

  @DomName('WebGLRenderingContextBase.ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALPHA = 0x1906;

  @DomName('WebGLRenderingContextBase.ALPHA_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALPHA_BITS = 0x0D55;

  @DomName('WebGLRenderingContextBase.ALWAYS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALWAYS = 0x0207;

  @DomName('WebGLRenderingContextBase.ARRAY_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ARRAY_BUFFER = 0x8892;

  @DomName('WebGLRenderingContextBase.ARRAY_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ARRAY_BUFFER_BINDING = 0x8894;

  @DomName('WebGLRenderingContextBase.ATTACHED_SHADERS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ATTACHED_SHADERS = 0x8B85;

  @DomName('WebGLRenderingContextBase.BACK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BACK = 0x0405;

  @DomName('WebGLRenderingContextBase.BLEND')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND = 0x0BE2;

  @DomName('WebGLRenderingContextBase.BLEND_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_COLOR = 0x8005;

  @DomName('WebGLRenderingContextBase.BLEND_DST_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_DST_ALPHA = 0x80CA;

  @DomName('WebGLRenderingContextBase.BLEND_DST_RGB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_DST_RGB = 0x80C8;

  @DomName('WebGLRenderingContextBase.BLEND_EQUATION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_EQUATION = 0x8009;

  @DomName('WebGLRenderingContextBase.BLEND_EQUATION_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_EQUATION_ALPHA = 0x883D;

  @DomName('WebGLRenderingContextBase.BLEND_EQUATION_RGB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_EQUATION_RGB = 0x8009;

  @DomName('WebGLRenderingContextBase.BLEND_SRC_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_SRC_ALPHA = 0x80CB;

  @DomName('WebGLRenderingContextBase.BLEND_SRC_RGB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_SRC_RGB = 0x80C9;

  @DomName('WebGLRenderingContextBase.BLUE_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLUE_BITS = 0x0D54;

  @DomName('WebGLRenderingContextBase.BOOL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BOOL = 0x8B56;

  @DomName('WebGLRenderingContextBase.BOOL_VEC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BOOL_VEC2 = 0x8B57;

  @DomName('WebGLRenderingContextBase.BOOL_VEC3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BOOL_VEC3 = 0x8B58;

  @DomName('WebGLRenderingContextBase.BOOL_VEC4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BOOL_VEC4 = 0x8B59;

  @DomName('WebGLRenderingContextBase.BROWSER_DEFAULT_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BROWSER_DEFAULT_WEBGL = 0x9244;

  @DomName('WebGLRenderingContextBase.BUFFER_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BUFFER_SIZE = 0x8764;

  @DomName('WebGLRenderingContextBase.BUFFER_USAGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BUFFER_USAGE = 0x8765;

  @DomName('WebGLRenderingContextBase.BYTE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BYTE = 0x1400;

  @DomName('WebGLRenderingContextBase.CCW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CCW = 0x0901;

  @DomName('WebGLRenderingContextBase.CLAMP_TO_EDGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CLAMP_TO_EDGE = 0x812F;

  @DomName('WebGLRenderingContextBase.COLOR_ATTACHMENT0')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT0 = 0x8CE0;

  @DomName('WebGLRenderingContextBase.COLOR_BUFFER_BIT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_BUFFER_BIT = 0x00004000;

  @DomName('WebGLRenderingContextBase.COLOR_CLEAR_VALUE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_CLEAR_VALUE = 0x0C22;

  @DomName('WebGLRenderingContextBase.COLOR_WRITEMASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_WRITEMASK = 0x0C23;

  @DomName('WebGLRenderingContextBase.COMPILE_STATUS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPILE_STATUS = 0x8B81;

  @DomName('WebGLRenderingContextBase.COMPRESSED_TEXTURE_FORMATS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_TEXTURE_FORMATS = 0x86A3;

  @DomName('WebGLRenderingContextBase.CONSTANT_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CONSTANT_ALPHA = 0x8003;

  @DomName('WebGLRenderingContextBase.CONSTANT_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CONSTANT_COLOR = 0x8001;

  @DomName('WebGLRenderingContextBase.CONTEXT_LOST_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CONTEXT_LOST_WEBGL = 0x9242;

  @DomName('WebGLRenderingContextBase.CULL_FACE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CULL_FACE = 0x0B44;

  @DomName('WebGLRenderingContextBase.CULL_FACE_MODE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CULL_FACE_MODE = 0x0B45;

  @DomName('WebGLRenderingContextBase.CURRENT_PROGRAM')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CURRENT_PROGRAM = 0x8B8D;

  @DomName('WebGLRenderingContextBase.CURRENT_VERTEX_ATTRIB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CURRENT_VERTEX_ATTRIB = 0x8626;

  @DomName('WebGLRenderingContextBase.CW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CW = 0x0900;

  @DomName('WebGLRenderingContextBase.DECR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DECR = 0x1E03;

  @DomName('WebGLRenderingContextBase.DECR_WRAP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DECR_WRAP = 0x8508;

  @DomName('WebGLRenderingContextBase.DELETE_STATUS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DELETE_STATUS = 0x8B80;

  @DomName('WebGLRenderingContextBase.DEPTH_ATTACHMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_ATTACHMENT = 0x8D00;

  @DomName('WebGLRenderingContextBase.DEPTH_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_BITS = 0x0D56;

  @DomName('WebGLRenderingContextBase.DEPTH_BUFFER_BIT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_BUFFER_BIT = 0x00000100;

  @DomName('WebGLRenderingContextBase.DEPTH_CLEAR_VALUE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_CLEAR_VALUE = 0x0B73;

  @DomName('WebGLRenderingContextBase.DEPTH_COMPONENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_COMPONENT = 0x1902;

  @DomName('WebGLRenderingContextBase.DEPTH_COMPONENT16')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_COMPONENT16 = 0x81A5;

  @DomName('WebGLRenderingContextBase.DEPTH_FUNC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_FUNC = 0x0B74;

  @DomName('WebGLRenderingContextBase.DEPTH_RANGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_RANGE = 0x0B70;

  @DomName('WebGLRenderingContextBase.DEPTH_STENCIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_STENCIL = 0x84F9;

  @DomName('WebGLRenderingContextBase.DEPTH_STENCIL_ATTACHMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_STENCIL_ATTACHMENT = 0x821A;

  @DomName('WebGLRenderingContextBase.DEPTH_TEST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_TEST = 0x0B71;

  @DomName('WebGLRenderingContextBase.DEPTH_WRITEMASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_WRITEMASK = 0x0B72;

  @DomName('WebGLRenderingContextBase.DITHER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DITHER = 0x0BD0;

  @DomName('WebGLRenderingContextBase.DONT_CARE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DONT_CARE = 0x1100;

  @DomName('WebGLRenderingContextBase.DST_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DST_ALPHA = 0x0304;

  @DomName('WebGLRenderingContextBase.DST_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DST_COLOR = 0x0306;

  @DomName('WebGLRenderingContextBase.DYNAMIC_DRAW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DYNAMIC_DRAW = 0x88E8;

  @DomName('WebGLRenderingContextBase.ELEMENT_ARRAY_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ELEMENT_ARRAY_BUFFER = 0x8893;

  @DomName('WebGLRenderingContextBase.ELEMENT_ARRAY_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;

  @DomName('WebGLRenderingContextBase.EQUAL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int EQUAL = 0x0202;

  @DomName('WebGLRenderingContextBase.FASTEST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FASTEST = 0x1101;

  @DomName('WebGLRenderingContextBase.FLOAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT = 0x1406;

  @DomName('WebGLRenderingContextBase.FLOAT_MAT2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT2 = 0x8B5A;

  @DomName('WebGLRenderingContextBase.FLOAT_MAT3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT3 = 0x8B5B;

  @DomName('WebGLRenderingContextBase.FLOAT_MAT4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT4 = 0x8B5C;

  @DomName('WebGLRenderingContextBase.FLOAT_VEC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_VEC2 = 0x8B50;

  @DomName('WebGLRenderingContextBase.FLOAT_VEC3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_VEC3 = 0x8B51;

  @DomName('WebGLRenderingContextBase.FLOAT_VEC4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_VEC4 = 0x8B52;

  @DomName('WebGLRenderingContextBase.FRAGMENT_SHADER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAGMENT_SHADER = 0x8B30;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER = 0x8D40;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_BINDING = 0x8CA6;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER_COMPLETE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_COMPLETE = 0x8CD5;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER_INCOMPLETE_ATTACHMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER_INCOMPLETE_DIMENSIONS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;

  @DomName('WebGLRenderingContextBase.FRAMEBUFFER_UNSUPPORTED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

  @DomName('WebGLRenderingContextBase.FRONT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRONT = 0x0404;

  @DomName('WebGLRenderingContextBase.FRONT_AND_BACK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRONT_AND_BACK = 0x0408;

  @DomName('WebGLRenderingContextBase.FRONT_FACE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRONT_FACE = 0x0B46;

  @DomName('WebGLRenderingContextBase.FUNC_ADD')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FUNC_ADD = 0x8006;

  @DomName('WebGLRenderingContextBase.FUNC_REVERSE_SUBTRACT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FUNC_REVERSE_SUBTRACT = 0x800B;

  @DomName('WebGLRenderingContextBase.FUNC_SUBTRACT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FUNC_SUBTRACT = 0x800A;

  @DomName('WebGLRenderingContextBase.GENERATE_MIPMAP_HINT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int GENERATE_MIPMAP_HINT = 0x8192;

  @DomName('WebGLRenderingContextBase.GEQUAL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int GEQUAL = 0x0206;

  @DomName('WebGLRenderingContextBase.GREATER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int GREATER = 0x0204;

  @DomName('WebGLRenderingContextBase.GREEN_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int GREEN_BITS = 0x0D53;

  @DomName('WebGLRenderingContextBase.HIGH_FLOAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int HIGH_FLOAT = 0x8DF2;

  @DomName('WebGLRenderingContextBase.HIGH_INT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int HIGH_INT = 0x8DF5;

  @DomName('WebGLRenderingContextBase.IMPLEMENTATION_COLOR_READ_FORMAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int IMPLEMENTATION_COLOR_READ_FORMAT = 0x8B9B;

  @DomName('WebGLRenderingContextBase.IMPLEMENTATION_COLOR_READ_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int IMPLEMENTATION_COLOR_READ_TYPE = 0x8B9A;

  @DomName('WebGLRenderingContextBase.INCR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INCR = 0x1E02;

  @DomName('WebGLRenderingContextBase.INCR_WRAP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INCR_WRAP = 0x8507;

  @DomName('WebGLRenderingContextBase.INT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT = 0x1404;

  @DomName('WebGLRenderingContextBase.INT_VEC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_VEC2 = 0x8B53;

  @DomName('WebGLRenderingContextBase.INT_VEC3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_VEC3 = 0x8B54;

  @DomName('WebGLRenderingContextBase.INT_VEC4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_VEC4 = 0x8B55;

  @DomName('WebGLRenderingContextBase.INVALID_ENUM')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVALID_ENUM = 0x0500;

  @DomName('WebGLRenderingContextBase.INVALID_FRAMEBUFFER_OPERATION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVALID_FRAMEBUFFER_OPERATION = 0x0506;

  @DomName('WebGLRenderingContextBase.INVALID_OPERATION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVALID_OPERATION = 0x0502;

  @DomName('WebGLRenderingContextBase.INVALID_VALUE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVALID_VALUE = 0x0501;

  @DomName('WebGLRenderingContextBase.INVERT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVERT = 0x150A;

  @DomName('WebGLRenderingContextBase.KEEP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int KEEP = 0x1E00;

  @DomName('WebGLRenderingContextBase.LEQUAL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LEQUAL = 0x0203;

  @DomName('WebGLRenderingContextBase.LESS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LESS = 0x0201;

  @DomName('WebGLRenderingContextBase.LINEAR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINEAR = 0x2601;

  @DomName('WebGLRenderingContextBase.LINEAR_MIPMAP_LINEAR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINEAR_MIPMAP_LINEAR = 0x2703;

  @DomName('WebGLRenderingContextBase.LINEAR_MIPMAP_NEAREST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINEAR_MIPMAP_NEAREST = 0x2701;

  @DomName('WebGLRenderingContextBase.LINES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINES = 0x0001;

  @DomName('WebGLRenderingContextBase.LINE_LOOP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINE_LOOP = 0x0002;

  @DomName('WebGLRenderingContextBase.LINE_STRIP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINE_STRIP = 0x0003;

  @DomName('WebGLRenderingContextBase.LINE_WIDTH')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINE_WIDTH = 0x0B21;

  @DomName('WebGLRenderingContextBase.LINK_STATUS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINK_STATUS = 0x8B82;

  @DomName('WebGLRenderingContextBase.LOW_FLOAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LOW_FLOAT = 0x8DF0;

  @DomName('WebGLRenderingContextBase.LOW_INT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LOW_INT = 0x8DF3;

  @DomName('WebGLRenderingContextBase.LUMINANCE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LUMINANCE = 0x1909;

  @DomName('WebGLRenderingContextBase.LUMINANCE_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LUMINANCE_ALPHA = 0x190A;

  @DomName('WebGLRenderingContextBase.MAX_COMBINED_TEXTURE_IMAGE_UNITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;

  @DomName('WebGLRenderingContextBase.MAX_CUBE_MAP_TEXTURE_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

  @DomName('WebGLRenderingContextBase.MAX_FRAGMENT_UNIFORM_VECTORS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;

  @DomName('WebGLRenderingContextBase.MAX_RENDERBUFFER_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_RENDERBUFFER_SIZE = 0x84E8;

  @DomName('WebGLRenderingContextBase.MAX_TEXTURE_IMAGE_UNITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_TEXTURE_IMAGE_UNITS = 0x8872;

  @DomName('WebGLRenderingContextBase.MAX_TEXTURE_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_TEXTURE_SIZE = 0x0D33;

  @DomName('WebGLRenderingContextBase.MAX_VARYING_VECTORS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VARYING_VECTORS = 0x8DFC;

  @DomName('WebGLRenderingContextBase.MAX_VERTEX_ATTRIBS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VERTEX_ATTRIBS = 0x8869;

  @DomName('WebGLRenderingContextBase.MAX_VERTEX_TEXTURE_IMAGE_UNITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;

  @DomName('WebGLRenderingContextBase.MAX_VERTEX_UNIFORM_VECTORS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;

  @DomName('WebGLRenderingContextBase.MAX_VIEWPORT_DIMS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VIEWPORT_DIMS = 0x0D3A;

  @DomName('WebGLRenderingContextBase.MEDIUM_FLOAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MEDIUM_FLOAT = 0x8DF1;

  @DomName('WebGLRenderingContextBase.MEDIUM_INT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MEDIUM_INT = 0x8DF4;

  @DomName('WebGLRenderingContextBase.MIRRORED_REPEAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MIRRORED_REPEAT = 0x8370;

  @DomName('WebGLRenderingContextBase.NEAREST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NEAREST = 0x2600;

  @DomName('WebGLRenderingContextBase.NEAREST_MIPMAP_LINEAR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NEAREST_MIPMAP_LINEAR = 0x2702;

  @DomName('WebGLRenderingContextBase.NEAREST_MIPMAP_NEAREST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NEAREST_MIPMAP_NEAREST = 0x2700;

  @DomName('WebGLRenderingContextBase.NEVER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NEVER = 0x0200;

  @DomName('WebGLRenderingContextBase.NICEST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NICEST = 0x1102;

  @DomName('WebGLRenderingContextBase.NONE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NONE = 0;

  @DomName('WebGLRenderingContextBase.NOTEQUAL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NOTEQUAL = 0x0205;

  @DomName('WebGLRenderingContextBase.NO_ERROR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NO_ERROR = 0;

  @DomName('WebGLRenderingContextBase.ONE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE = 1;

  @DomName('WebGLRenderingContextBase.ONE_MINUS_CONSTANT_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_CONSTANT_ALPHA = 0x8004;

  @DomName('WebGLRenderingContextBase.ONE_MINUS_CONSTANT_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_CONSTANT_COLOR = 0x8002;

  @DomName('WebGLRenderingContextBase.ONE_MINUS_DST_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_DST_ALPHA = 0x0305;

  @DomName('WebGLRenderingContextBase.ONE_MINUS_DST_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_DST_COLOR = 0x0307;

  @DomName('WebGLRenderingContextBase.ONE_MINUS_SRC_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_SRC_ALPHA = 0x0303;

  @DomName('WebGLRenderingContextBase.ONE_MINUS_SRC_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_SRC_COLOR = 0x0301;

  @DomName('WebGLRenderingContextBase.OUT_OF_MEMORY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int OUT_OF_MEMORY = 0x0505;

  @DomName('WebGLRenderingContextBase.PACK_ALIGNMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int PACK_ALIGNMENT = 0x0D05;

  @DomName('WebGLRenderingContextBase.POINTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int POINTS = 0x0000;

  @DomName('WebGLRenderingContextBase.POLYGON_OFFSET_FACTOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int POLYGON_OFFSET_FACTOR = 0x8038;

  @DomName('WebGLRenderingContextBase.POLYGON_OFFSET_FILL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int POLYGON_OFFSET_FILL = 0x8037;

  @DomName('WebGLRenderingContextBase.POLYGON_OFFSET_UNITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int POLYGON_OFFSET_UNITS = 0x2A00;

  @DomName('WebGLRenderingContextBase.RED_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RED_BITS = 0x0D52;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER = 0x8D41;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER_ALPHA_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_ALPHA_SIZE = 0x8D53;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_BINDING = 0x8CA7;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER_BLUE_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_BLUE_SIZE = 0x8D52;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER_DEPTH_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_DEPTH_SIZE = 0x8D54;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER_GREEN_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_GREEN_SIZE = 0x8D51;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER_HEIGHT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_HEIGHT = 0x8D43;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER_INTERNAL_FORMAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER_RED_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_RED_SIZE = 0x8D50;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER_STENCIL_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_STENCIL_SIZE = 0x8D55;

  @DomName('WebGLRenderingContextBase.RENDERBUFFER_WIDTH')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_WIDTH = 0x8D42;

  @DomName('WebGLRenderingContextBase.RENDERER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERER = 0x1F01;

  @DomName('WebGLRenderingContextBase.REPEAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int REPEAT = 0x2901;

  @DomName('WebGLRenderingContextBase.REPLACE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int REPLACE = 0x1E01;

  @DomName('WebGLRenderingContextBase.RGB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB = 0x1907;

  @DomName('WebGLRenderingContextBase.RGB565')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB565 = 0x8D62;

  @DomName('WebGLRenderingContextBase.RGB5_A1')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB5_A1 = 0x8057;

  @DomName('WebGLRenderingContextBase.RGBA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA = 0x1908;

  @DomName('WebGLRenderingContextBase.RGBA4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA4 = 0x8056;

  @DomName('WebGLRenderingContextBase.SAMPLER_2D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLER_2D = 0x8B5E;

  @DomName('WebGLRenderingContextBase.SAMPLER_CUBE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLER_CUBE = 0x8B60;

  @DomName('WebGLRenderingContextBase.SAMPLES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLES = 0x80A9;

  @DomName('WebGLRenderingContextBase.SAMPLE_ALPHA_TO_COVERAGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLE_ALPHA_TO_COVERAGE = 0x809E;

  @DomName('WebGLRenderingContextBase.SAMPLE_BUFFERS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLE_BUFFERS = 0x80A8;

  @DomName('WebGLRenderingContextBase.SAMPLE_COVERAGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLE_COVERAGE = 0x80A0;

  @DomName('WebGLRenderingContextBase.SAMPLE_COVERAGE_INVERT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLE_COVERAGE_INVERT = 0x80AB;

  @DomName('WebGLRenderingContextBase.SAMPLE_COVERAGE_VALUE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLE_COVERAGE_VALUE = 0x80AA;

  @DomName('WebGLRenderingContextBase.SCISSOR_BOX')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SCISSOR_BOX = 0x0C10;

  @DomName('WebGLRenderingContextBase.SCISSOR_TEST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SCISSOR_TEST = 0x0C11;

  @DomName('WebGLRenderingContextBase.SHADER_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SHADER_TYPE = 0x8B4F;

  @DomName('WebGLRenderingContextBase.SHADING_LANGUAGE_VERSION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SHADING_LANGUAGE_VERSION = 0x8B8C;

  @DomName('WebGLRenderingContextBase.SHORT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SHORT = 0x1402;

  @DomName('WebGLRenderingContextBase.SRC_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRC_ALPHA = 0x0302;

  @DomName('WebGLRenderingContextBase.SRC_ALPHA_SATURATE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRC_ALPHA_SATURATE = 0x0308;

  @DomName('WebGLRenderingContextBase.SRC_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRC_COLOR = 0x0300;

  @DomName('WebGLRenderingContextBase.STATIC_DRAW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STATIC_DRAW = 0x88E4;

  @DomName('WebGLRenderingContextBase.STENCIL_ATTACHMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_ATTACHMENT = 0x8D20;

  @DomName('WebGLRenderingContextBase.STENCIL_BACK_FAIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_FAIL = 0x8801;

  @DomName('WebGLRenderingContextBase.STENCIL_BACK_FUNC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_FUNC = 0x8800;

  @DomName('WebGLRenderingContextBase.STENCIL_BACK_PASS_DEPTH_FAIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;

  @DomName('WebGLRenderingContextBase.STENCIL_BACK_PASS_DEPTH_PASS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;

  @DomName('WebGLRenderingContextBase.STENCIL_BACK_REF')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_REF = 0x8CA3;

  @DomName('WebGLRenderingContextBase.STENCIL_BACK_VALUE_MASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_VALUE_MASK = 0x8CA4;

  @DomName('WebGLRenderingContextBase.STENCIL_BACK_WRITEMASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_WRITEMASK = 0x8CA5;

  @DomName('WebGLRenderingContextBase.STENCIL_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BITS = 0x0D57;

  @DomName('WebGLRenderingContextBase.STENCIL_BUFFER_BIT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BUFFER_BIT = 0x00000400;

  @DomName('WebGLRenderingContextBase.STENCIL_CLEAR_VALUE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_CLEAR_VALUE = 0x0B91;

  @DomName('WebGLRenderingContextBase.STENCIL_FAIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_FAIL = 0x0B94;

  @DomName('WebGLRenderingContextBase.STENCIL_FUNC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_FUNC = 0x0B92;

  @DomName('WebGLRenderingContextBase.STENCIL_INDEX')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_INDEX = 0x1901;

  @DomName('WebGLRenderingContextBase.STENCIL_INDEX8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_INDEX8 = 0x8D48;

  @DomName('WebGLRenderingContextBase.STENCIL_PASS_DEPTH_FAIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_PASS_DEPTH_FAIL = 0x0B95;

  @DomName('WebGLRenderingContextBase.STENCIL_PASS_DEPTH_PASS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_PASS_DEPTH_PASS = 0x0B96;

  @DomName('WebGLRenderingContextBase.STENCIL_REF')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_REF = 0x0B97;

  @DomName('WebGLRenderingContextBase.STENCIL_TEST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_TEST = 0x0B90;

  @DomName('WebGLRenderingContextBase.STENCIL_VALUE_MASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_VALUE_MASK = 0x0B93;

  @DomName('WebGLRenderingContextBase.STENCIL_WRITEMASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_WRITEMASK = 0x0B98;

  @DomName('WebGLRenderingContextBase.STREAM_DRAW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STREAM_DRAW = 0x88E0;

  @DomName('WebGLRenderingContextBase.SUBPIXEL_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SUBPIXEL_BITS = 0x0D50;

  @DomName('WebGLRenderingContextBase.TEXTURE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE = 0x1702;

  @DomName('WebGLRenderingContextBase.TEXTURE0')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE0 = 0x84C0;

  @DomName('WebGLRenderingContextBase.TEXTURE1')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE1 = 0x84C1;

  @DomName('WebGLRenderingContextBase.TEXTURE10')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE10 = 0x84CA;

  @DomName('WebGLRenderingContextBase.TEXTURE11')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE11 = 0x84CB;

  @DomName('WebGLRenderingContextBase.TEXTURE12')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE12 = 0x84CC;

  @DomName('WebGLRenderingContextBase.TEXTURE13')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE13 = 0x84CD;

  @DomName('WebGLRenderingContextBase.TEXTURE14')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE14 = 0x84CE;

  @DomName('WebGLRenderingContextBase.TEXTURE15')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE15 = 0x84CF;

  @DomName('WebGLRenderingContextBase.TEXTURE16')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE16 = 0x84D0;

  @DomName('WebGLRenderingContextBase.TEXTURE17')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE17 = 0x84D1;

  @DomName('WebGLRenderingContextBase.TEXTURE18')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE18 = 0x84D2;

  @DomName('WebGLRenderingContextBase.TEXTURE19')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE19 = 0x84D3;

  @DomName('WebGLRenderingContextBase.TEXTURE2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE2 = 0x84C2;

  @DomName('WebGLRenderingContextBase.TEXTURE20')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE20 = 0x84D4;

  @DomName('WebGLRenderingContextBase.TEXTURE21')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE21 = 0x84D5;

  @DomName('WebGLRenderingContextBase.TEXTURE22')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE22 = 0x84D6;

  @DomName('WebGLRenderingContextBase.TEXTURE23')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE23 = 0x84D7;

  @DomName('WebGLRenderingContextBase.TEXTURE24')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE24 = 0x84D8;

  @DomName('WebGLRenderingContextBase.TEXTURE25')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE25 = 0x84D9;

  @DomName('WebGLRenderingContextBase.TEXTURE26')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE26 = 0x84DA;

  @DomName('WebGLRenderingContextBase.TEXTURE27')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE27 = 0x84DB;

  @DomName('WebGLRenderingContextBase.TEXTURE28')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE28 = 0x84DC;

  @DomName('WebGLRenderingContextBase.TEXTURE29')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE29 = 0x84DD;

  @DomName('WebGLRenderingContextBase.TEXTURE3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE3 = 0x84C3;

  @DomName('WebGLRenderingContextBase.TEXTURE30')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE30 = 0x84DE;

  @DomName('WebGLRenderingContextBase.TEXTURE31')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE31 = 0x84DF;

  @DomName('WebGLRenderingContextBase.TEXTURE4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE4 = 0x84C4;

  @DomName('WebGLRenderingContextBase.TEXTURE5')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE5 = 0x84C5;

  @DomName('WebGLRenderingContextBase.TEXTURE6')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE6 = 0x84C6;

  @DomName('WebGLRenderingContextBase.TEXTURE7')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE7 = 0x84C7;

  @DomName('WebGLRenderingContextBase.TEXTURE8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE8 = 0x84C8;

  @DomName('WebGLRenderingContextBase.TEXTURE9')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE9 = 0x84C9;

  @DomName('WebGLRenderingContextBase.TEXTURE_2D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_2D = 0x0DE1;

  @DomName('WebGLRenderingContextBase.TEXTURE_BINDING_2D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_BINDING_2D = 0x8069;

  @DomName('WebGLRenderingContextBase.TEXTURE_BINDING_CUBE_MAP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_BINDING_CUBE_MAP = 0x8514;

  @DomName('WebGLRenderingContextBase.TEXTURE_CUBE_MAP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP = 0x8513;

  @DomName('WebGLRenderingContextBase.TEXTURE_CUBE_MAP_NEGATIVE_X')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;

  @DomName('WebGLRenderingContextBase.TEXTURE_CUBE_MAP_NEGATIVE_Y')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;

  @DomName('WebGLRenderingContextBase.TEXTURE_CUBE_MAP_NEGATIVE_Z')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;

  @DomName('WebGLRenderingContextBase.TEXTURE_CUBE_MAP_POSITIVE_X')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;

  @DomName('WebGLRenderingContextBase.TEXTURE_CUBE_MAP_POSITIVE_Y')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;

  @DomName('WebGLRenderingContextBase.TEXTURE_CUBE_MAP_POSITIVE_Z')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;

  @DomName('WebGLRenderingContextBase.TEXTURE_MAG_FILTER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_MAG_FILTER = 0x2800;

  @DomName('WebGLRenderingContextBase.TEXTURE_MIN_FILTER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_MIN_FILTER = 0x2801;

  @DomName('WebGLRenderingContextBase.TEXTURE_WRAP_S')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_WRAP_S = 0x2802;

  @DomName('WebGLRenderingContextBase.TEXTURE_WRAP_T')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_WRAP_T = 0x2803;

  @DomName('WebGLRenderingContextBase.TRIANGLES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRIANGLES = 0x0004;

  @DomName('WebGLRenderingContextBase.TRIANGLE_FAN')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRIANGLE_FAN = 0x0006;

  @DomName('WebGLRenderingContextBase.TRIANGLE_STRIP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRIANGLE_STRIP = 0x0005;

  @DomName('WebGLRenderingContextBase.UNPACK_ALIGNMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_ALIGNMENT = 0x0CF5;

  @DomName('WebGLRenderingContextBase.UNPACK_COLORSPACE_CONVERSION_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;

  @DomName('WebGLRenderingContextBase.UNPACK_FLIP_Y_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_FLIP_Y_WEBGL = 0x9240;

  @DomName('WebGLRenderingContextBase.UNPACK_PREMULTIPLY_ALPHA_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;

  @DomName('WebGLRenderingContextBase.UNSIGNED_BYTE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_BYTE = 0x1401;

  @DomName('WebGLRenderingContextBase.UNSIGNED_INT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT = 0x1405;

  @DomName('WebGLRenderingContextBase.UNSIGNED_SHORT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_SHORT = 0x1403;

  @DomName('WebGLRenderingContextBase.UNSIGNED_SHORT_4_4_4_4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_SHORT_4_4_4_4 = 0x8033;

  @DomName('WebGLRenderingContextBase.UNSIGNED_SHORT_5_5_5_1')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_SHORT_5_5_5_1 = 0x8034;

  @DomName('WebGLRenderingContextBase.UNSIGNED_SHORT_5_6_5')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_SHORT_5_6_5 = 0x8363;

  @DomName('WebGLRenderingContextBase.VALIDATE_STATUS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VALIDATE_STATUS = 0x8B83;

  @DomName('WebGLRenderingContextBase.VENDOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VENDOR = 0x1F00;

  @DomName('WebGLRenderingContextBase.VERSION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERSION = 0x1F02;

  @DomName('WebGLRenderingContextBase.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

  @DomName('WebGLRenderingContextBase.VERTEX_ATTRIB_ARRAY_ENABLED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;

  @DomName('WebGLRenderingContextBase.VERTEX_ATTRIB_ARRAY_NORMALIZED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;

  @DomName('WebGLRenderingContextBase.VERTEX_ATTRIB_ARRAY_POINTER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;

  @DomName('WebGLRenderingContextBase.VERTEX_ATTRIB_ARRAY_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;

  @DomName('WebGLRenderingContextBase.VERTEX_ATTRIB_ARRAY_STRIDE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;

  @DomName('WebGLRenderingContextBase.VERTEX_ATTRIB_ARRAY_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;

  @DomName('WebGLRenderingContextBase.VERTEX_SHADER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_SHADER = 0x8B31;

  @DomName('WebGLRenderingContextBase.VIEWPORT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VIEWPORT = 0x0BA2;

  @DomName('WebGLRenderingContextBase.ZERO')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ZERO = 0;

  @DomName('WebGLRenderingContextBase.canvas')
  @DocsEditable()
  @Experimental() // untriaged
  CanvasElement get canvas => _blink.BlinkWebGLRenderingContextBase.canvas_Getter(this);

  @DomName('WebGLRenderingContextBase.drawingBufferHeight')
  @DocsEditable()
  @Experimental() // untriaged
  int get drawingBufferHeight => _blink.BlinkWebGLRenderingContextBase.drawingBufferHeight_Getter(this);

  @DomName('WebGLRenderingContextBase.drawingBufferWidth')
  @DocsEditable()
  @Experimental() // untriaged
  int get drawingBufferWidth => _blink.BlinkWebGLRenderingContextBase.drawingBufferWidth_Getter(this);

  @DomName('WebGLRenderingContextBase.activeTexture')
  @DocsEditable()
  @Experimental() // untriaged
  void activeTexture(int texture) => _blink.BlinkWebGLRenderingContextBase.activeTexture_Callback_ul(this, texture);

  @DomName('WebGLRenderingContextBase.attachShader')
  @DocsEditable()
  @Experimental() // untriaged
  void attachShader(Program program, Shader shader) => _blink.BlinkWebGLRenderingContextBase.attachShader_Callback_WebGLProgram_WebGLShader(this, program, shader);

  @DomName('WebGLRenderingContextBase.bindAttribLocation')
  @DocsEditable()
  @Experimental() // untriaged
  void bindAttribLocation(Program program, int index, String name) => _blink.BlinkWebGLRenderingContextBase.bindAttribLocation_Callback_WebGLProgram_ul_DOMString(this, program, index, name);

  @DomName('WebGLRenderingContextBase.bindBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void bindBuffer(int target, Buffer buffer) => _blink.BlinkWebGLRenderingContextBase.bindBuffer_Callback_ul_WebGLBuffer(this, target, buffer);

  @DomName('WebGLRenderingContextBase.bindFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void bindFramebuffer(int target, Framebuffer framebuffer) => _blink.BlinkWebGLRenderingContextBase.bindFramebuffer_Callback_ul_WebGLFramebuffer(this, target, framebuffer);

  @DomName('WebGLRenderingContextBase.bindRenderbuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void bindRenderbuffer(int target, Renderbuffer renderbuffer) => _blink.BlinkWebGLRenderingContextBase.bindRenderbuffer_Callback_ul_WebGLRenderbuffer(this, target, renderbuffer);

  @DomName('WebGLRenderingContextBase.bindTexture')
  @DocsEditable()
  @Experimental() // untriaged
  void bindTexture(int target, Texture texture) => _blink.BlinkWebGLRenderingContextBase.bindTexture_Callback_ul_WebGLTexture(this, target, texture);

  @DomName('WebGLRenderingContextBase.blendColor')
  @DocsEditable()
  @Experimental() // untriaged
  void blendColor(num red, num green, num blue, num alpha) => _blink.BlinkWebGLRenderingContextBase.blendColor_Callback_float_float_float_float(this, red, green, blue, alpha);

  @DomName('WebGLRenderingContextBase.blendEquation')
  @DocsEditable()
  @Experimental() // untriaged
  void blendEquation(int mode) => _blink.BlinkWebGLRenderingContextBase.blendEquation_Callback_ul(this, mode);

  @DomName('WebGLRenderingContextBase.blendEquationSeparate')
  @DocsEditable()
  @Experimental() // untriaged
  void blendEquationSeparate(int modeRGB, int modeAlpha) => _blink.BlinkWebGLRenderingContextBase.blendEquationSeparate_Callback_ul_ul(this, modeRGB, modeAlpha);

  @DomName('WebGLRenderingContextBase.blendFunc')
  @DocsEditable()
  @Experimental() // untriaged
  void blendFunc(int sfactor, int dfactor) => _blink.BlinkWebGLRenderingContextBase.blendFunc_Callback_ul_ul(this, sfactor, dfactor);

  @DomName('WebGLRenderingContextBase.blendFuncSeparate')
  @DocsEditable()
  @Experimental() // untriaged
  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) => _blink.BlinkWebGLRenderingContextBase.blendFuncSeparate_Callback_ul_ul_ul_ul(this, srcRGB, dstRGB, srcAlpha, dstAlpha);

  @DomName('WebGLRenderingContextBase.bufferByteData')
  @DocsEditable()
  @Experimental() // untriaged
  void bufferByteData(int target, ByteBuffer data, int usage) => _blink.BlinkWebGLRenderingContextBase.bufferData_Callback_ul_ArrayBuffer_ul(this, target, data, usage);

  void bufferData(int target, data_OR_size, int usage) {
    if ((usage is int || usage == null) && (data_OR_size is int || data_OR_size == null) && (target is int || target == null)) {
      _blink.BlinkWebGLRenderingContextBase.bufferData_Callback_ul_ll_ul(this, target, data_OR_size, usage);
      return;
    }
    if ((usage is int || usage == null) && (data_OR_size is TypedData || data_OR_size == null) && (target is int || target == null)) {
      _blink.BlinkWebGLRenderingContextBase.bufferData_Callback_ul_ArrayBufferView_ul(this, target, data_OR_size, usage);
      return;
    }
    if ((usage is int || usage == null) && (data_OR_size is ByteBuffer || data_OR_size == null) && (target is int || target == null)) {
      _blink.BlinkWebGLRenderingContextBase.bufferData_Callback_ul_ArrayBuffer_ul(this, target, data_OR_size, usage);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContextBase.bufferDataTyped')
  @DocsEditable()
  @Experimental() // untriaged
  void bufferDataTyped(int target, TypedData data, int usage) => _blink.BlinkWebGLRenderingContextBase.bufferData_Callback_ul_ArrayBufferView_ul(this, target, data, usage);

  @DomName('WebGLRenderingContextBase.bufferSubByteData')
  @DocsEditable()
  @Experimental() // untriaged
  void bufferSubByteData(int target, int offset, ByteBuffer data) => _blink.BlinkWebGLRenderingContextBase.bufferSubData_Callback_ul_ll_ArrayBuffer(this, target, offset, data);

  void bufferSubData(int target, int offset, data) {
    if ((data is TypedData || data == null) && (offset is int || offset == null) && (target is int || target == null)) {
      _blink.BlinkWebGLRenderingContextBase.bufferSubData_Callback_ul_ll_ArrayBufferView(this, target, offset, data);
      return;
    }
    if ((data is ByteBuffer || data == null) && (offset is int || offset == null) && (target is int || target == null)) {
      _blink.BlinkWebGLRenderingContextBase.bufferSubData_Callback_ul_ll_ArrayBuffer(this, target, offset, data);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContextBase.bufferSubDataTyped')
  @DocsEditable()
  @Experimental() // untriaged
  void bufferSubDataTyped(int target, int offset, TypedData data) => _blink.BlinkWebGLRenderingContextBase.bufferSubData_Callback_ul_ll_ArrayBufferView(this, target, offset, data);

  @DomName('WebGLRenderingContextBase.checkFramebufferStatus')
  @DocsEditable()
  @Experimental() // untriaged
  int checkFramebufferStatus(int target) => _blink.BlinkWebGLRenderingContextBase.checkFramebufferStatus_Callback_ul(this, target);

  @DomName('WebGLRenderingContextBase.clear')
  @DocsEditable()
  @Experimental() // untriaged
  void clear(int mask) => _blink.BlinkWebGLRenderingContextBase.clear_Callback_ul(this, mask);

  @DomName('WebGLRenderingContextBase.clearColor')
  @DocsEditable()
  @Experimental() // untriaged
  void clearColor(num red, num green, num blue, num alpha) => _blink.BlinkWebGLRenderingContextBase.clearColor_Callback_float_float_float_float(this, red, green, blue, alpha);

  @DomName('WebGLRenderingContextBase.clearDepth')
  @DocsEditable()
  @Experimental() // untriaged
  void clearDepth(num depth) => _blink.BlinkWebGLRenderingContextBase.clearDepth_Callback_float(this, depth);

  @DomName('WebGLRenderingContextBase.clearStencil')
  @DocsEditable()
  @Experimental() // untriaged
  void clearStencil(int s) => _blink.BlinkWebGLRenderingContextBase.clearStencil_Callback_long(this, s);

  @DomName('WebGLRenderingContextBase.colorMask')
  @DocsEditable()
  @Experimental() // untriaged
  void colorMask(bool red, bool green, bool blue, bool alpha) => _blink.BlinkWebGLRenderingContextBase.colorMask_Callback_boolean_boolean_boolean_boolean(this, red, green, blue, alpha);

  @DomName('WebGLRenderingContextBase.compileShader')
  @DocsEditable()
  @Experimental() // untriaged
  void compileShader(Shader shader) => _blink.BlinkWebGLRenderingContextBase.compileShader_Callback_WebGLShader(this, shader);

  @DomName('WebGLRenderingContextBase.compressedTexImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, TypedData data) => _blink.BlinkWebGLRenderingContextBase.compressedTexImage2D_Callback_ul_long_ul_long_long_long_ArrayBufferView(this, target, level, internalformat, width, height, border, data);

  @DomName('WebGLRenderingContextBase.compressedTexSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, TypedData data) => _blink.BlinkWebGLRenderingContextBase.compressedTexSubImage2D_Callback_ul_long_long_long_long_long_ul_ArrayBufferView(this, target, level, xoffset, yoffset, width, height, format, data);

  @DomName('WebGLRenderingContextBase.copyTexImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) => _blink.BlinkWebGLRenderingContextBase.copyTexImage2D_Callback_ul_long_ul_long_long_long_long_long(this, target, level, internalformat, x, y, width, height, border);

  @DomName('WebGLRenderingContextBase.copyTexSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) => _blink.BlinkWebGLRenderingContextBase.copyTexSubImage2D_Callback_ul_long_long_long_long_long_long_long(this, target, level, xoffset, yoffset, x, y, width, height);

  @DomName('WebGLRenderingContextBase.createBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  Buffer createBuffer() => _blink.BlinkWebGLRenderingContextBase.createBuffer_Callback(this);

  @DomName('WebGLRenderingContextBase.createFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  Framebuffer createFramebuffer() => _blink.BlinkWebGLRenderingContextBase.createFramebuffer_Callback(this);

  @DomName('WebGLRenderingContextBase.createProgram')
  @DocsEditable()
  @Experimental() // untriaged
  Program createProgram() => _blink.BlinkWebGLRenderingContextBase.createProgram_Callback(this);

  @DomName('WebGLRenderingContextBase.createRenderbuffer')
  @DocsEditable()
  @Experimental() // untriaged
  Renderbuffer createRenderbuffer() => _blink.BlinkWebGLRenderingContextBase.createRenderbuffer_Callback(this);

  @DomName('WebGLRenderingContextBase.createShader')
  @DocsEditable()
  @Experimental() // untriaged
  Shader createShader(int type) => _blink.BlinkWebGLRenderingContextBase.createShader_Callback_ul(this, type);

  @DomName('WebGLRenderingContextBase.createTexture')
  @DocsEditable()
  @Experimental() // untriaged
  Texture createTexture() => _blink.BlinkWebGLRenderingContextBase.createTexture_Callback(this);

  @DomName('WebGLRenderingContextBase.cullFace')
  @DocsEditable()
  @Experimental() // untriaged
  void cullFace(int mode) => _blink.BlinkWebGLRenderingContextBase.cullFace_Callback_ul(this, mode);

  @DomName('WebGLRenderingContextBase.deleteBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteBuffer(Buffer buffer) => _blink.BlinkWebGLRenderingContextBase.deleteBuffer_Callback_WebGLBuffer(this, buffer);

  @DomName('WebGLRenderingContextBase.deleteFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteFramebuffer(Framebuffer framebuffer) => _blink.BlinkWebGLRenderingContextBase.deleteFramebuffer_Callback_WebGLFramebuffer(this, framebuffer);

  @DomName('WebGLRenderingContextBase.deleteProgram')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteProgram(Program program) => _blink.BlinkWebGLRenderingContextBase.deleteProgram_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContextBase.deleteRenderbuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteRenderbuffer(Renderbuffer renderbuffer) => _blink.BlinkWebGLRenderingContextBase.deleteRenderbuffer_Callback_WebGLRenderbuffer(this, renderbuffer);

  @DomName('WebGLRenderingContextBase.deleteShader')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteShader(Shader shader) => _blink.BlinkWebGLRenderingContextBase.deleteShader_Callback_WebGLShader(this, shader);

  @DomName('WebGLRenderingContextBase.deleteTexture')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteTexture(Texture texture) => _blink.BlinkWebGLRenderingContextBase.deleteTexture_Callback_WebGLTexture(this, texture);

  @DomName('WebGLRenderingContextBase.depthFunc')
  @DocsEditable()
  @Experimental() // untriaged
  void depthFunc(int func) => _blink.BlinkWebGLRenderingContextBase.depthFunc_Callback_ul(this, func);

  @DomName('WebGLRenderingContextBase.depthMask')
  @DocsEditable()
  @Experimental() // untriaged
  void depthMask(bool flag) => _blink.BlinkWebGLRenderingContextBase.depthMask_Callback_boolean(this, flag);

  @DomName('WebGLRenderingContextBase.depthRange')
  @DocsEditable()
  @Experimental() // untriaged
  void depthRange(num zNear, num zFar) => _blink.BlinkWebGLRenderingContextBase.depthRange_Callback_float_float(this, zNear, zFar);

  @DomName('WebGLRenderingContextBase.detachShader')
  @DocsEditable()
  @Experimental() // untriaged
  void detachShader(Program program, Shader shader) => _blink.BlinkWebGLRenderingContextBase.detachShader_Callback_WebGLProgram_WebGLShader(this, program, shader);

  @DomName('WebGLRenderingContextBase.disable')
  @DocsEditable()
  @Experimental() // untriaged
  void disable(int cap) => _blink.BlinkWebGLRenderingContextBase.disable_Callback_ul(this, cap);

  @DomName('WebGLRenderingContextBase.disableVertexAttribArray')
  @DocsEditable()
  @Experimental() // untriaged
  void disableVertexAttribArray(int index) => _blink.BlinkWebGLRenderingContextBase.disableVertexAttribArray_Callback_ul(this, index);

  @DomName('WebGLRenderingContextBase.drawArrays')
  @DocsEditable()
  @Experimental() // untriaged
  void drawArrays(int mode, int first, int count) => _blink.BlinkWebGLRenderingContextBase.drawArrays_Callback_ul_long_long(this, mode, first, count);

  @DomName('WebGLRenderingContextBase.drawElements')
  @DocsEditable()
  @Experimental() // untriaged
  void drawElements(int mode, int count, int type, int offset) => _blink.BlinkWebGLRenderingContextBase.drawElements_Callback_ul_long_ul_ll(this, mode, count, type, offset);

  @DomName('WebGLRenderingContextBase.enable')
  @DocsEditable()
  @Experimental() // untriaged
  void enable(int cap) => _blink.BlinkWebGLRenderingContextBase.enable_Callback_ul(this, cap);

  @DomName('WebGLRenderingContextBase.enableVertexAttribArray')
  @DocsEditable()
  @Experimental() // untriaged
  void enableVertexAttribArray(int index) => _blink.BlinkWebGLRenderingContextBase.enableVertexAttribArray_Callback_ul(this, index);

  @DomName('WebGLRenderingContextBase.finish')
  @DocsEditable()
  @Experimental() // untriaged
  void finish() => _blink.BlinkWebGLRenderingContextBase.finish_Callback(this);

  @DomName('WebGLRenderingContextBase.flush')
  @DocsEditable()
  @Experimental() // untriaged
  void flush() => _blink.BlinkWebGLRenderingContextBase.flush_Callback(this);

  @DomName('WebGLRenderingContextBase.framebufferRenderbuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, Renderbuffer renderbuffer) => _blink.BlinkWebGLRenderingContextBase.framebufferRenderbuffer_Callback_ul_ul_ul_WebGLRenderbuffer(this, target, attachment, renderbuffertarget, renderbuffer);

  @DomName('WebGLRenderingContextBase.framebufferTexture2D')
  @DocsEditable()
  @Experimental() // untriaged
  void framebufferTexture2D(int target, int attachment, int textarget, Texture texture, int level) => _blink.BlinkWebGLRenderingContextBase.framebufferTexture2D_Callback_ul_ul_ul_WebGLTexture_long(this, target, attachment, textarget, texture, level);

  @DomName('WebGLRenderingContextBase.frontFace')
  @DocsEditable()
  @Experimental() // untriaged
  void frontFace(int mode) => _blink.BlinkWebGLRenderingContextBase.frontFace_Callback_ul(this, mode);

  @DomName('WebGLRenderingContextBase.generateMipmap')
  @DocsEditable()
  @Experimental() // untriaged
  void generateMipmap(int target) => _blink.BlinkWebGLRenderingContextBase.generateMipmap_Callback_ul(this, target);

  @DomName('WebGLRenderingContextBase.getActiveAttrib')
  @DocsEditable()
  @Experimental() // untriaged
  ActiveInfo getActiveAttrib(Program program, int index) => _blink.BlinkWebGLRenderingContextBase.getActiveAttrib_Callback_WebGLProgram_ul(this, program, index);

  @DomName('WebGLRenderingContextBase.getActiveUniform')
  @DocsEditable()
  @Experimental() // untriaged
  ActiveInfo getActiveUniform(Program program, int index) => _blink.BlinkWebGLRenderingContextBase.getActiveUniform_Callback_WebGLProgram_ul(this, program, index);

  @DomName('WebGLRenderingContextBase.getAttachedShaders')
  @DocsEditable()
  @Experimental() // untriaged
  List<Shader> getAttachedShaders(Program program) => _blink.BlinkWebGLRenderingContextBase.getAttachedShaders_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContextBase.getAttribLocation')
  @DocsEditable()
  @Experimental() // untriaged
  int getAttribLocation(Program program, String name) => _blink.BlinkWebGLRenderingContextBase.getAttribLocation_Callback_WebGLProgram_DOMString(this, program, name);

  @DomName('WebGLRenderingContextBase.getBufferParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getBufferParameter(int target, int pname) => _blink.BlinkWebGLRenderingContextBase.getBufferParameter_Callback_ul_ul(this, target, pname);

  @DomName('WebGLRenderingContextBase.getContextAttributes')
  @DocsEditable()
  @Experimental() // untriaged
  ContextAttributes getContextAttributes() => _blink.BlinkWebGLRenderingContextBase.getContextAttributes_Callback(this);

  @DomName('WebGLRenderingContextBase.getError')
  @DocsEditable()
  @Experimental() // untriaged
  int getError() => _blink.BlinkWebGLRenderingContextBase.getError_Callback(this);

  @DomName('WebGLRenderingContextBase.getExtension')
  @DocsEditable()
  @Experimental() // untriaged
  Object getExtension(String name) => _blink.BlinkWebGLRenderingContextBase.getExtension_Callback_DOMString(this, name);

  @DomName('WebGLRenderingContextBase.getFramebufferAttachmentParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) => _blink.BlinkWebGLRenderingContextBase.getFramebufferAttachmentParameter_Callback_ul_ul_ul(this, target, attachment, pname);

  @DomName('WebGLRenderingContextBase.getParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getParameter(int pname) => _blink.BlinkWebGLRenderingContextBase.getParameter_Callback_ul(this, pname);

  @DomName('WebGLRenderingContextBase.getProgramInfoLog')
  @DocsEditable()
  @Experimental() // untriaged
  String getProgramInfoLog(Program program) => _blink.BlinkWebGLRenderingContextBase.getProgramInfoLog_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContextBase.getProgramParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getProgramParameter(Program program, int pname) => _blink.BlinkWebGLRenderingContextBase.getProgramParameter_Callback_WebGLProgram_ul(this, program, pname);

  @DomName('WebGLRenderingContextBase.getRenderbufferParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getRenderbufferParameter(int target, int pname) => _blink.BlinkWebGLRenderingContextBase.getRenderbufferParameter_Callback_ul_ul(this, target, pname);

  @DomName('WebGLRenderingContextBase.getShaderInfoLog')
  @DocsEditable()
  @Experimental() // untriaged
  String getShaderInfoLog(Shader shader) => _blink.BlinkWebGLRenderingContextBase.getShaderInfoLog_Callback_WebGLShader(this, shader);

  @DomName('WebGLRenderingContextBase.getShaderParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getShaderParameter(Shader shader, int pname) => _blink.BlinkWebGLRenderingContextBase.getShaderParameter_Callback_WebGLShader_ul(this, shader, pname);

  @DomName('WebGLRenderingContextBase.getShaderPrecisionFormat')
  @DocsEditable()
  @Experimental() // untriaged
  ShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype) => _blink.BlinkWebGLRenderingContextBase.getShaderPrecisionFormat_Callback_ul_ul(this, shadertype, precisiontype);

  @DomName('WebGLRenderingContextBase.getShaderSource')
  @DocsEditable()
  @Experimental() // untriaged
  String getShaderSource(Shader shader) => _blink.BlinkWebGLRenderingContextBase.getShaderSource_Callback_WebGLShader(this, shader);

  @DomName('WebGLRenderingContextBase.getSupportedExtensions')
  @DocsEditable()
  @Experimental() // untriaged
  List<String> getSupportedExtensions() => _blink.BlinkWebGLRenderingContextBase.getSupportedExtensions_Callback(this);

  @DomName('WebGLRenderingContextBase.getTexParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getTexParameter(int target, int pname) => _blink.BlinkWebGLRenderingContextBase.getTexParameter_Callback_ul_ul(this, target, pname);

  @DomName('WebGLRenderingContextBase.getUniform')
  @DocsEditable()
  @Experimental() // untriaged
  Object getUniform(Program program, UniformLocation location) => _blink.BlinkWebGLRenderingContextBase.getUniform_Callback_WebGLProgram_WebGLUniformLocation(this, program, location);

  @DomName('WebGLRenderingContextBase.getUniformLocation')
  @DocsEditable()
  @Experimental() // untriaged
  UniformLocation getUniformLocation(Program program, String name) => _blink.BlinkWebGLRenderingContextBase.getUniformLocation_Callback_WebGLProgram_DOMString(this, program, name);

  @DomName('WebGLRenderingContextBase.getVertexAttrib')
  @DocsEditable()
  @Experimental() // untriaged
  Object getVertexAttrib(int index, int pname) => _blink.BlinkWebGLRenderingContextBase.getVertexAttrib_Callback_ul_ul(this, index, pname);

  @DomName('WebGLRenderingContextBase.getVertexAttribOffset')
  @DocsEditable()
  @Experimental() // untriaged
  int getVertexAttribOffset(int index, int pname) => _blink.BlinkWebGLRenderingContextBase.getVertexAttribOffset_Callback_ul_ul(this, index, pname);

  @DomName('WebGLRenderingContextBase.hint')
  @DocsEditable()
  @Experimental() // untriaged
  void hint(int target, int mode) => _blink.BlinkWebGLRenderingContextBase.hint_Callback_ul_ul(this, target, mode);

  @DomName('WebGLRenderingContextBase.isBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  bool isBuffer(Buffer buffer) => _blink.BlinkWebGLRenderingContextBase.isBuffer_Callback_WebGLBuffer(this, buffer);

  @DomName('WebGLRenderingContextBase.isContextLost')
  @DocsEditable()
  @Experimental() // untriaged
  bool isContextLost() => _blink.BlinkWebGLRenderingContextBase.isContextLost_Callback(this);

  @DomName('WebGLRenderingContextBase.isEnabled')
  @DocsEditable()
  @Experimental() // untriaged
  bool isEnabled(int cap) => _blink.BlinkWebGLRenderingContextBase.isEnabled_Callback_ul(this, cap);

  @DomName('WebGLRenderingContextBase.isFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  bool isFramebuffer(Framebuffer framebuffer) => _blink.BlinkWebGLRenderingContextBase.isFramebuffer_Callback_WebGLFramebuffer(this, framebuffer);

  @DomName('WebGLRenderingContextBase.isProgram')
  @DocsEditable()
  @Experimental() // untriaged
  bool isProgram(Program program) => _blink.BlinkWebGLRenderingContextBase.isProgram_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContextBase.isRenderbuffer')
  @DocsEditable()
  @Experimental() // untriaged
  bool isRenderbuffer(Renderbuffer renderbuffer) => _blink.BlinkWebGLRenderingContextBase.isRenderbuffer_Callback_WebGLRenderbuffer(this, renderbuffer);

  @DomName('WebGLRenderingContextBase.isShader')
  @DocsEditable()
  @Experimental() // untriaged
  bool isShader(Shader shader) => _blink.BlinkWebGLRenderingContextBase.isShader_Callback_WebGLShader(this, shader);

  @DomName('WebGLRenderingContextBase.isTexture')
  @DocsEditable()
  @Experimental() // untriaged
  bool isTexture(Texture texture) => _blink.BlinkWebGLRenderingContextBase.isTexture_Callback_WebGLTexture(this, texture);

  @DomName('WebGLRenderingContextBase.lineWidth')
  @DocsEditable()
  @Experimental() // untriaged
  void lineWidth(num width) => _blink.BlinkWebGLRenderingContextBase.lineWidth_Callback_float(this, width);

  @DomName('WebGLRenderingContextBase.linkProgram')
  @DocsEditable()
  @Experimental() // untriaged
  void linkProgram(Program program) => _blink.BlinkWebGLRenderingContextBase.linkProgram_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContextBase.pixelStorei')
  @DocsEditable()
  @Experimental() // untriaged
  void pixelStorei(int pname, int param) => _blink.BlinkWebGLRenderingContextBase.pixelStorei_Callback_ul_long(this, pname, param);

  @DomName('WebGLRenderingContextBase.polygonOffset')
  @DocsEditable()
  @Experimental() // untriaged
  void polygonOffset(num factor, num units) => _blink.BlinkWebGLRenderingContextBase.polygonOffset_Callback_float_float(this, factor, units);

  @DomName('WebGLRenderingContextBase.readPixels')
  @DocsEditable()
  @Experimental() // untriaged
  void readPixels(int x, int y, int width, int height, int format, int type, TypedData pixels) => _blink.BlinkWebGLRenderingContextBase.readPixels_Callback_long_long_long_long_ul_ul_ArrayBufferView(this, x, y, width, height, format, type, pixels);

  @DomName('WebGLRenderingContextBase.renderbufferStorage')
  @DocsEditable()
  @Experimental() // untriaged
  void renderbufferStorage(int target, int internalformat, int width, int height) => _blink.BlinkWebGLRenderingContextBase.renderbufferStorage_Callback_ul_ul_long_long(this, target, internalformat, width, height);

  @DomName('WebGLRenderingContextBase.sampleCoverage')
  @DocsEditable()
  @Experimental() // untriaged
  void sampleCoverage(num value, bool invert) => _blink.BlinkWebGLRenderingContextBase.sampleCoverage_Callback_float_boolean(this, value, invert);

  @DomName('WebGLRenderingContextBase.scissor')
  @DocsEditable()
  @Experimental() // untriaged
  void scissor(int x, int y, int width, int height) => _blink.BlinkWebGLRenderingContextBase.scissor_Callback_long_long_long_long(this, x, y, width, height);

  @DomName('WebGLRenderingContextBase.shaderSource')
  @DocsEditable()
  @Experimental() // untriaged
  void shaderSource(Shader shader, String string) => _blink.BlinkWebGLRenderingContextBase.shaderSource_Callback_WebGLShader_DOMString(this, shader, string);

  @DomName('WebGLRenderingContextBase.stencilFunc')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilFunc(int func, int ref, int mask) => _blink.BlinkWebGLRenderingContextBase.stencilFunc_Callback_ul_long_ul(this, func, ref, mask);

  @DomName('WebGLRenderingContextBase.stencilFuncSeparate')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilFuncSeparate(int face, int func, int ref, int mask) => _blink.BlinkWebGLRenderingContextBase.stencilFuncSeparate_Callback_ul_ul_long_ul(this, face, func, ref, mask);

  @DomName('WebGLRenderingContextBase.stencilMask')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilMask(int mask) => _blink.BlinkWebGLRenderingContextBase.stencilMask_Callback_ul(this, mask);

  @DomName('WebGLRenderingContextBase.stencilMaskSeparate')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilMaskSeparate(int face, int mask) => _blink.BlinkWebGLRenderingContextBase.stencilMaskSeparate_Callback_ul_ul(this, face, mask);

  @DomName('WebGLRenderingContextBase.stencilOp')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilOp(int fail, int zfail, int zpass) => _blink.BlinkWebGLRenderingContextBase.stencilOp_Callback_ul_ul_ul(this, fail, zfail, zpass);

  @DomName('WebGLRenderingContextBase.stencilOpSeparate')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilOpSeparate(int face, int fail, int zfail, int zpass) => _blink.BlinkWebGLRenderingContextBase.stencilOpSeparate_Callback_ul_ul_ul_ul(this, face, fail, zfail, zpass);

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, [int format, int type, TypedData pixels]) {
    if ((pixels is TypedData || pixels == null) && (type is int || type == null) && (format is int || format == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is int || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null)) {
      _blink.BlinkWebGLRenderingContextBase.texImage2D_Callback_ul_long_ul_long_long_long_ul_ul_ArrayBufferView(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContextBase.texImage2D_Callback_ul_long_ul_ul_ul_ImageData(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContextBase.texImage2D_Callback_ul_long_ul_ul_ul_HTMLImageElement(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContextBase.texImage2D_Callback_ul_long_ul_ul_ul_HTMLCanvasElement(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContextBase.texImage2D_Callback_ul_long_ul_ul_ul_HTMLVideoElement(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContextBase.texImage2DCanvas')
  @DocsEditable()
  @Experimental() // untriaged
  void texImage2DCanvas(int target, int level, int internalformat, int format, int type, CanvasElement canvas) => _blink.BlinkWebGLRenderingContextBase.texImage2D_Callback_ul_long_ul_ul_ul_HTMLCanvasElement(this, target, level, internalformat, format, type, canvas);

  @DomName('WebGLRenderingContextBase.texImage2DImage')
  @DocsEditable()
  @Experimental() // untriaged
  void texImage2DImage(int target, int level, int internalformat, int format, int type, ImageElement image) => _blink.BlinkWebGLRenderingContextBase.texImage2D_Callback_ul_long_ul_ul_ul_HTMLImageElement(this, target, level, internalformat, format, type, image);

  @DomName('WebGLRenderingContextBase.texImage2DImageData')
  @DocsEditable()
  @Experimental() // untriaged
  void texImage2DImageData(int target, int level, int internalformat, int format, int type, ImageData pixels) => _blink.BlinkWebGLRenderingContextBase.texImage2D_Callback_ul_long_ul_ul_ul_ImageData(this, target, level, internalformat, format, type, pixels);

  @DomName('WebGLRenderingContextBase.texImage2DVideo')
  @DocsEditable()
  @Experimental() // untriaged
  void texImage2DVideo(int target, int level, int internalformat, int format, int type, VideoElement video) => _blink.BlinkWebGLRenderingContextBase.texImage2D_Callback_ul_long_ul_ul_ul_HTMLVideoElement(this, target, level, internalformat, format, type, video);

  @DomName('WebGLRenderingContextBase.texParameterf')
  @DocsEditable()
  @Experimental() // untriaged
  void texParameterf(int target, int pname, num param) => _blink.BlinkWebGLRenderingContextBase.texParameterf_Callback_ul_ul_float(this, target, pname, param);

  @DomName('WebGLRenderingContextBase.texParameteri')
  @DocsEditable()
  @Experimental() // untriaged
  void texParameteri(int target, int pname, int param) => _blink.BlinkWebGLRenderingContextBase.texParameteri_Callback_ul_ul_long(this, target, pname, param);

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, [int type, TypedData pixels]) {
    if ((pixels is TypedData || pixels == null) && (type is int || type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is int || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null)) {
      _blink.BlinkWebGLRenderingContextBase.texSubImage2D_Callback_ul_long_long_long_long_long_ul_ul_ArrayBufferView(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContextBase.texSubImage2D_Callback_ul_long_long_long_ul_ul_ImageData(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContextBase.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLImageElement(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContextBase.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLCanvasElement(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      _blink.BlinkWebGLRenderingContextBase.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLVideoElement(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContextBase.texSubImage2DCanvas')
  @DocsEditable()
  @Experimental() // untriaged
  void texSubImage2DCanvas(int target, int level, int xoffset, int yoffset, int format, int type, CanvasElement canvas) => _blink.BlinkWebGLRenderingContextBase.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLCanvasElement(this, target, level, xoffset, yoffset, format, type, canvas);

  @DomName('WebGLRenderingContextBase.texSubImage2DImage')
  @DocsEditable()
  @Experimental() // untriaged
  void texSubImage2DImage(int target, int level, int xoffset, int yoffset, int format, int type, ImageElement image) => _blink.BlinkWebGLRenderingContextBase.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLImageElement(this, target, level, xoffset, yoffset, format, type, image);

  @DomName('WebGLRenderingContextBase.texSubImage2DImageData')
  @DocsEditable()
  @Experimental() // untriaged
  void texSubImage2DImageData(int target, int level, int xoffset, int yoffset, int format, int type, ImageData pixels) => _blink.BlinkWebGLRenderingContextBase.texSubImage2D_Callback_ul_long_long_long_ul_ul_ImageData(this, target, level, xoffset, yoffset, format, type, pixels);

  @DomName('WebGLRenderingContextBase.texSubImage2DVideo')
  @DocsEditable()
  @Experimental() // untriaged
  void texSubImage2DVideo(int target, int level, int xoffset, int yoffset, int format, int type, VideoElement video) => _blink.BlinkWebGLRenderingContextBase.texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLVideoElement(this, target, level, xoffset, yoffset, format, type, video);

  @DomName('WebGLRenderingContextBase.uniform1f')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1f(UniformLocation location, num x) => _blink.BlinkWebGLRenderingContextBase.uniform1f_Callback_WebGLUniformLocation_float(this, location, x);

  @DomName('WebGLRenderingContextBase.uniform1fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1fv(UniformLocation location, Float32List v) => _blink.BlinkWebGLRenderingContextBase.uniform1fv_Callback_WebGLUniformLocation_Float32Array(this, location, v);

  @DomName('WebGLRenderingContextBase.uniform1i')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1i(UniformLocation location, int x) => _blink.BlinkWebGLRenderingContextBase.uniform1i_Callback_WebGLUniformLocation_long(this, location, x);

  @DomName('WebGLRenderingContextBase.uniform1iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1iv(UniformLocation location, Int32List v) => _blink.BlinkWebGLRenderingContextBase.uniform1iv_Callback_WebGLUniformLocation_Int32Array(this, location, v);

  @DomName('WebGLRenderingContextBase.uniform2f')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2f(UniformLocation location, num x, num y) => _blink.BlinkWebGLRenderingContextBase.uniform2f_Callback_WebGLUniformLocation_float_float(this, location, x, y);

  @DomName('WebGLRenderingContextBase.uniform2fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2fv(UniformLocation location, Float32List v) => _blink.BlinkWebGLRenderingContextBase.uniform2fv_Callback_WebGLUniformLocation_Float32Array(this, location, v);

  @DomName('WebGLRenderingContextBase.uniform2i')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2i(UniformLocation location, int x, int y) => _blink.BlinkWebGLRenderingContextBase.uniform2i_Callback_WebGLUniformLocation_long_long(this, location, x, y);

  @DomName('WebGLRenderingContextBase.uniform2iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2iv(UniformLocation location, Int32List v) => _blink.BlinkWebGLRenderingContextBase.uniform2iv_Callback_WebGLUniformLocation_Int32Array(this, location, v);

  @DomName('WebGLRenderingContextBase.uniform3f')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3f(UniformLocation location, num x, num y, num z) => _blink.BlinkWebGLRenderingContextBase.uniform3f_Callback_WebGLUniformLocation_float_float_float(this, location, x, y, z);

  @DomName('WebGLRenderingContextBase.uniform3fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3fv(UniformLocation location, Float32List v) => _blink.BlinkWebGLRenderingContextBase.uniform3fv_Callback_WebGLUniformLocation_Float32Array(this, location, v);

  @DomName('WebGLRenderingContextBase.uniform3i')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3i(UniformLocation location, int x, int y, int z) => _blink.BlinkWebGLRenderingContextBase.uniform3i_Callback_WebGLUniformLocation_long_long_long(this, location, x, y, z);

  @DomName('WebGLRenderingContextBase.uniform3iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3iv(UniformLocation location, Int32List v) => _blink.BlinkWebGLRenderingContextBase.uniform3iv_Callback_WebGLUniformLocation_Int32Array(this, location, v);

  @DomName('WebGLRenderingContextBase.uniform4f')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4f(UniformLocation location, num x, num y, num z, num w) => _blink.BlinkWebGLRenderingContextBase.uniform4f_Callback_WebGLUniformLocation_float_float_float_float(this, location, x, y, z, w);

  @DomName('WebGLRenderingContextBase.uniform4fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4fv(UniformLocation location, Float32List v) => _blink.BlinkWebGLRenderingContextBase.uniform4fv_Callback_WebGLUniformLocation_Float32Array(this, location, v);

  @DomName('WebGLRenderingContextBase.uniform4i')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4i(UniformLocation location, int x, int y, int z, int w) => _blink.BlinkWebGLRenderingContextBase.uniform4i_Callback_WebGLUniformLocation_long_long_long_long(this, location, x, y, z, w);

  @DomName('WebGLRenderingContextBase.uniform4iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4iv(UniformLocation location, Int32List v) => _blink.BlinkWebGLRenderingContextBase.uniform4iv_Callback_WebGLUniformLocation_Int32Array(this, location, v);

  @DomName('WebGLRenderingContextBase.uniformMatrix2fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix2fv(UniformLocation location, bool transpose, Float32List array) => _blink.BlinkWebGLRenderingContextBase.uniformMatrix2fv_Callback_WebGLUniformLocation_boolean_Float32Array(this, location, transpose, array);

  @DomName('WebGLRenderingContextBase.uniformMatrix3fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix3fv(UniformLocation location, bool transpose, Float32List array) => _blink.BlinkWebGLRenderingContextBase.uniformMatrix3fv_Callback_WebGLUniformLocation_boolean_Float32Array(this, location, transpose, array);

  @DomName('WebGLRenderingContextBase.uniformMatrix4fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix4fv(UniformLocation location, bool transpose, Float32List array) => _blink.BlinkWebGLRenderingContextBase.uniformMatrix4fv_Callback_WebGLUniformLocation_boolean_Float32Array(this, location, transpose, array);

  @DomName('WebGLRenderingContextBase.useProgram')
  @DocsEditable()
  @Experimental() // untriaged
  void useProgram(Program program) => _blink.BlinkWebGLRenderingContextBase.useProgram_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContextBase.validateProgram')
  @DocsEditable()
  @Experimental() // untriaged
  void validateProgram(Program program) => _blink.BlinkWebGLRenderingContextBase.validateProgram_Callback_WebGLProgram(this, program);

  @DomName('WebGLRenderingContextBase.vertexAttrib1f')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib1f(int indx, num x) => _blink.BlinkWebGLRenderingContextBase.vertexAttrib1f_Callback_ul_float(this, indx, x);

  @DomName('WebGLRenderingContextBase.vertexAttrib1fv')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib1fv(int indx, Float32List values) => _blink.BlinkWebGLRenderingContextBase.vertexAttrib1fv_Callback_ul_Float32Array(this, indx, values);

  @DomName('WebGLRenderingContextBase.vertexAttrib2f')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib2f(int indx, num x, num y) => _blink.BlinkWebGLRenderingContextBase.vertexAttrib2f_Callback_ul_float_float(this, indx, x, y);

  @DomName('WebGLRenderingContextBase.vertexAttrib2fv')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib2fv(int indx, Float32List values) => _blink.BlinkWebGLRenderingContextBase.vertexAttrib2fv_Callback_ul_Float32Array(this, indx, values);

  @DomName('WebGLRenderingContextBase.vertexAttrib3f')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib3f(int indx, num x, num y, num z) => _blink.BlinkWebGLRenderingContextBase.vertexAttrib3f_Callback_ul_float_float_float(this, indx, x, y, z);

  @DomName('WebGLRenderingContextBase.vertexAttrib3fv')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib3fv(int indx, Float32List values) => _blink.BlinkWebGLRenderingContextBase.vertexAttrib3fv_Callback_ul_Float32Array(this, indx, values);

  @DomName('WebGLRenderingContextBase.vertexAttrib4f')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib4f(int indx, num x, num y, num z, num w) => _blink.BlinkWebGLRenderingContextBase.vertexAttrib4f_Callback_ul_float_float_float_float(this, indx, x, y, z, w);

  @DomName('WebGLRenderingContextBase.vertexAttrib4fv')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib4fv(int indx, Float32List values) => _blink.BlinkWebGLRenderingContextBase.vertexAttrib4fv_Callback_ul_Float32Array(this, indx, values);

  @DomName('WebGLRenderingContextBase.vertexAttribPointer')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) => _blink.BlinkWebGLRenderingContextBase.vertexAttribPointer_Callback_ul_long_ul_boolean_long_ll(this, indx, size, type, normalized, stride, offset);

  @DomName('WebGLRenderingContextBase.viewport')
  @DocsEditable()
  @Experimental() // untriaged
  void viewport(int x, int y, int width, int height) => _blink.BlinkWebGLRenderingContextBase.viewport_Callback_long_long_long_long(this, x, y, width, height);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLShader')
class Shader extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Shader._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLShaderPrecisionFormat')
class ShaderPrecisionFormat extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory ShaderPrecisionFormat._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLShaderPrecisionFormat.precision')
  @DocsEditable()
  int get precision => _blink.BlinkWebGLShaderPrecisionFormat.precision_Getter(this);

  @DomName('WebGLShaderPrecisionFormat.rangeMax')
  @DocsEditable()
  int get rangeMax => _blink.BlinkWebGLShaderPrecisionFormat.rangeMax_Getter(this);

  @DomName('WebGLShaderPrecisionFormat.rangeMin')
  @DocsEditable()
  int get rangeMin => _blink.BlinkWebGLShaderPrecisionFormat.rangeMin_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLTexture')
class Texture extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Texture._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLUniformLocation')
class UniformLocation extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory UniformLocation._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WebGLVertexArrayObjectOES')
// http://www.khronos.org/registry/webgl/extensions/OES_vertex_array_object/
@Experimental() // experimental
class VertexArrayObject extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory VertexArrayObject._() { throw new UnsupportedError("Not supported"); }

}
