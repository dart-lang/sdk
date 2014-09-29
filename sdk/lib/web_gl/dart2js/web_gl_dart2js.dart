/**
 * 3D programming in the browser.
 */
library dart.dom.web_gl;

import 'dart:collection';
import 'dart:_internal' hide deprecated;
import 'dart:html';
import 'dart:html_common';
import 'dart:_native_typed_data';
import 'dart:typed_data';
import 'dart:_js_helper' show Creates, JSName, Native, Null, Returns, convertDartClosureToJS;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show Interceptor, JSExtendableArray;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:web_gl library.





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


@DocsEditable()
@DomName('WebGLActiveInfo')
@Unstable()
@Native("WebGLActiveInfo")
class ActiveInfo extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ActiveInfo._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLActiveInfo.name')
  @DocsEditable()
  final String name;

  @DomName('WebGLActiveInfo.size')
  @DocsEditable()
  final int size;

  @DomName('WebGLActiveInfo.type')
  @DocsEditable()
  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('ANGLEInstancedArrays')
@Experimental() // untriaged
@Native("ANGLEInstancedArrays")
class AngleInstancedArrays extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AngleInstancedArrays._() { throw new UnsupportedError("Not supported"); }

  @DomName('ANGLEInstancedArrays.VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE = 0x88FE;

  @JSName('drawArraysInstancedANGLE')
  @DomName('ANGLEInstancedArrays.drawArraysInstancedANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  void drawArraysInstancedAngle(int mode, int first, int count, int primcount) native;

  @JSName('drawElementsInstancedANGLE')
  @DomName('ANGLEInstancedArrays.drawElementsInstancedANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  void drawElementsInstancedAngle(int mode, int count, int type, int offset, int primcount) native;

  @JSName('vertexAttribDivisorANGLE')
  @DomName('ANGLEInstancedArrays.vertexAttribDivisorANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttribDivisorAngle(int index, int divisor) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLBuffer')
@Unstable()
@Native("WebGLBuffer")
class Buffer extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Buffer._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLCompressedTextureATC')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_atc/
@Experimental()
@Native("WebGLCompressedTextureATC")
class CompressedTextureAtc extends Interceptor {
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


@DocsEditable()
@DomName('WebGLCompressedTextureETC1')
@Experimental() // untriaged
@Native("WebGLCompressedTextureETC1")
class CompressedTextureETC1 extends Interceptor {
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


@DocsEditable()
@DomName('WebGLCompressedTexturePVRTC')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_pvrtc/
@Experimental() // experimental
@Native("WebGLCompressedTexturePVRTC")
class CompressedTexturePvrtc extends Interceptor {
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


@DocsEditable()
@DomName('WebGLCompressedTextureS3TC')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_s3tc/
@Experimental() // experimental
@Native("WebGLCompressedTextureS3TC")
class CompressedTextureS3TC extends Interceptor {
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
@Native("WebGLContextAttributes")
class ContextAttributes extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ContextAttributes._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLContextAttributes.alpha')
  @DocsEditable()
  bool alpha;

  @DomName('WebGLContextAttributes.antialias')
  @DocsEditable()
  bool antialias;

  @DomName('WebGLContextAttributes.depth')
  @DocsEditable()
  bool depth;

  @DomName('WebGLContextAttributes.failIfMajorPerformanceCaveat')
  @DocsEditable()
  @Experimental() // untriaged
  bool failIfMajorPerformanceCaveat;

  @DomName('WebGLContextAttributes.premultipliedAlpha')
  @DocsEditable()
  bool premultipliedAlpha;

  @DomName('WebGLContextAttributes.preserveDrawingBuffer')
  @DocsEditable()
  bool preserveDrawingBuffer;

  @DomName('WebGLContextAttributes.stencil')
  @DocsEditable()
  bool stencil;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLContextEvent')
@Unstable()
@Native("WebGLContextEvent")
class ContextEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory ContextEvent._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLContextEvent.statusMessage')
  @DocsEditable()
  final String statusMessage;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLDebugRendererInfo')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_debug_renderer_info/
@Experimental() // experimental
@Native("WebGLDebugRendererInfo")
class DebugRendererInfo extends Interceptor {
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


@DocsEditable()
@DomName('WebGLDebugShaders')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_debug_shaders/
@Experimental() // experimental
@Native("WebGLDebugShaders")
class DebugShaders extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory DebugShaders._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLDebugShaders.getTranslatedShaderSource')
  @DocsEditable()
  String getTranslatedShaderSource(Shader shader) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLDepthTexture')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_depth_texture/
@Experimental() // experimental
@Native("WebGLDepthTexture")
class DepthTexture extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory DepthTexture._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLDepthTexture.UNSIGNED_INT_24_8_WEBGL')
  @DocsEditable()
  static const int UNSIGNED_INT_24_8_WEBGL = 0x84FA;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLDrawBuffers')
// http://www.khronos.org/registry/webgl/specs/latest/
@Experimental() // stable
@Native("WebGLDrawBuffers")
class DrawBuffers extends Interceptor {
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

  @JSName('drawBuffersWEBGL')
  @DomName('WebGLDrawBuffers.drawBuffersWEBGL')
  @DocsEditable()
  void drawBuffersWebgl(List<int> buffers) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('EXTBlendMinMax')
@Experimental() // untriaged
@Native("EXTBlendMinMax")
class ExtBlendMinMax extends Interceptor {
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


@DocsEditable()
@DomName('EXTFragDepth')
// http://www.khronos.org/registry/webgl/extensions/EXT_frag_depth/
@Experimental()
@Native("EXTFragDepth")
class ExtFragDepth extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ExtFragDepth._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('EXTShaderTextureLOD')
@Experimental() // untriaged
@Native("EXTShaderTextureLOD")
class ExtShaderTextureLod extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ExtShaderTextureLod._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('EXTTextureFilterAnisotropic')
// http://www.khronos.org/registry/webgl/extensions/EXT_texture_filter_anisotropic/
@Experimental()
@Native("EXTTextureFilterAnisotropic")
class ExtTextureFilterAnisotropic extends Interceptor {
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


@DocsEditable()
@DomName('WebGLFramebuffer')
@Unstable()
@Native("WebGLFramebuffer")
class Framebuffer extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Framebuffer._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLLoseContext')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_lose_context/
@Experimental()
@Native("WebGLLoseContext,WebGLExtensionLoseContext")
class LoseContext extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory LoseContext._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLLoseContext.loseContext')
  @DocsEditable()
  void loseContext() native;

  @DomName('WebGLLoseContext.restoreContext')
  @DocsEditable()
  void restoreContext() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('OESElementIndexUint')
// http://www.khronos.org/registry/webgl/extensions/OES_element_index_uint/
@Experimental() // experimental
@Native("OESElementIndexUint")
class OesElementIndexUint extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesElementIndexUint._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('OESStandardDerivatives')
// http://www.khronos.org/registry/webgl/extensions/OES_standard_derivatives/
@Experimental() // experimental
@Native("OESStandardDerivatives")
class OesStandardDerivatives extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesStandardDerivatives._() { throw new UnsupportedError("Not supported"); }

  @DomName('OESStandardDerivatives.FRAGMENT_SHADER_DERIVATIVE_HINT_OES')
  @DocsEditable()
  static const int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('OESTextureFloat')
// http://www.khronos.org/registry/webgl/extensions/OES_texture_float/
@Experimental() // experimental
@Native("OESTextureFloat")
class OesTextureFloat extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesTextureFloat._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('OESTextureFloatLinear')
// http://www.khronos.org/registry/webgl/extensions/OES_texture_float_linear/
@Experimental()
@Native("OESTextureFloatLinear")
class OesTextureFloatLinear extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesTextureFloatLinear._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('OESTextureHalfFloat')
// http://www.khronos.org/registry/webgl/extensions/OES_texture_half_float/
@Experimental() // experimental
@Native("OESTextureHalfFloat")
class OesTextureHalfFloat extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesTextureHalfFloat._() { throw new UnsupportedError("Not supported"); }

  @DomName('OESTextureHalfFloat.HALF_FLOAT_OES')
  @DocsEditable()
  static const int HALF_FLOAT_OES = 0x8D61;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('OESTextureHalfFloatLinear')
// http://www.khronos.org/registry/webgl/extensions/OES_texture_half_float_linear/
@Experimental()
@Native("OESTextureHalfFloatLinear")
class OesTextureHalfFloatLinear extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesTextureHalfFloatLinear._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('OESVertexArrayObject')
// http://www.khronos.org/registry/webgl/extensions/OES_vertex_array_object/
@Experimental() // experimental
@Native("OESVertexArrayObject")
class OesVertexArrayObject extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesVertexArrayObject._() { throw new UnsupportedError("Not supported"); }

  @DomName('OESVertexArrayObject.VERTEX_ARRAY_BINDING_OES')
  @DocsEditable()
  static const int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  @JSName('bindVertexArrayOES')
  @DomName('OESVertexArrayObject.bindVertexArrayOES')
  @DocsEditable()
  void bindVertexArray(VertexArrayObject arrayObject) native;

  @JSName('createVertexArrayOES')
  @DomName('OESVertexArrayObject.createVertexArrayOES')
  @DocsEditable()
  VertexArrayObject createVertexArray() native;

  @JSName('deleteVertexArrayOES')
  @DomName('OESVertexArrayObject.deleteVertexArrayOES')
  @DocsEditable()
  void deleteVertexArray(VertexArrayObject arrayObject) native;

  @JSName('isVertexArrayOES')
  @DomName('OESVertexArrayObject.isVertexArrayOES')
  @DocsEditable()
  bool isVertexArray(VertexArrayObject arrayObject) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLProgram')
@Unstable()
@Native("WebGLProgram")
class Program extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Program._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLRenderbuffer')
@Unstable()
@Native("WebGLRenderbuffer")
class Renderbuffer extends Interceptor {
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
@Native("WebGLRenderingContext")
class RenderingContext extends Interceptor implements CanvasRenderingContext {
  // To suppress missing implicit constructor warnings.
  factory RenderingContext._() { throw new UnsupportedError("Not supported"); }

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.WebGLRenderingContext)');

  // From WebGLRenderingContextBase

  @DomName('WebGLRenderingContext.canvas')
  @DocsEditable()
  @Experimental() // untriaged
  final CanvasElement canvas;

  @DomName('WebGLRenderingContext.drawingBufferHeight')
  @DocsEditable()
  final int drawingBufferHeight;

  @DomName('WebGLRenderingContext.drawingBufferWidth')
  @DocsEditable()
  final int drawingBufferWidth;

  @DomName('WebGLRenderingContext.activeTexture')
  @DocsEditable()
  void activeTexture(int texture) native;

  @DomName('WebGLRenderingContext.attachShader')
  @DocsEditable()
  void attachShader(Program program, Shader shader) native;

  @DomName('WebGLRenderingContext.bindAttribLocation')
  @DocsEditable()
  void bindAttribLocation(Program program, int index, String name) native;

  @DomName('WebGLRenderingContext.bindBuffer')
  @DocsEditable()
  void bindBuffer(int target, Buffer buffer) native;

  @DomName('WebGLRenderingContext.bindFramebuffer')
  @DocsEditable()
  void bindFramebuffer(int target, Framebuffer framebuffer) native;

  @DomName('WebGLRenderingContext.bindRenderbuffer')
  @DocsEditable()
  void bindRenderbuffer(int target, Renderbuffer renderbuffer) native;

  @DomName('WebGLRenderingContext.bindTexture')
  @DocsEditable()
  void bindTexture(int target, Texture texture) native;

  @DomName('WebGLRenderingContext.blendColor')
  @DocsEditable()
  void blendColor(num red, num green, num blue, num alpha) native;

  @DomName('WebGLRenderingContext.blendEquation')
  @DocsEditable()
  void blendEquation(int mode) native;

  @DomName('WebGLRenderingContext.blendEquationSeparate')
  @DocsEditable()
  void blendEquationSeparate(int modeRGB, int modeAlpha) native;

  @DomName('WebGLRenderingContext.blendFunc')
  @DocsEditable()
  void blendFunc(int sfactor, int dfactor) native;

  @DomName('WebGLRenderingContext.blendFuncSeparate')
  @DocsEditable()
  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) native;

  @JSName('bufferData')
  /**
   * Buffers the specified data.
   *
   * The [bufferData] method is provided for WebGL API compatibility reasons, but
   * it is highly recommended that you use [bufferDataTyped] or [bufferByteData]
   * depending on your purposes.
   */
  @DomName('WebGLRenderingContext.bufferData')
  @DocsEditable()
  void bufferByteData(int target, ByteBuffer data, int usage) native;

  /**
   * Buffers the specified data.
   *
   * The [bufferData] method is provided for WebGL API compatibility reasons, but
   * it is highly recommended that you use [bufferDataTyped] or [bufferByteData]
   * depending on your purposes.
   */
  @DomName('WebGLRenderingContext.bufferData')
  @DocsEditable()
  void bufferData(int target, data_OR_size, int usage) native;

  @JSName('bufferData')
  /**
   * Buffers the specified data.
   *
   * The [bufferData] method is provided for WebGL API compatibility reasons, but
   * it is highly recommended that you use [bufferDataTyped] or [bufferByteData]
   * depending on your purposes.
   */
  @DomName('WebGLRenderingContext.bufferData')
  @DocsEditable()
  void bufferDataTyped(int target, TypedData data, int usage) native;

  @JSName('bufferSubData')
  /**
   * Buffers the specified subset of data.
   *
   * The [bufferSubData] method is provided for WebGL API compatibility reasons, but
   * it is highly recommended that you use [bufferSubDataTyped] or [bufferSubByteData]
   * depending on your purposes.
   */
  @DomName('WebGLRenderingContext.bufferSubData')
  @DocsEditable()
  void bufferSubByteData(int target, int offset, ByteBuffer data) native;

  /**
   * Buffers the specified subset of data.
   *
   * The [bufferSubData] method is provided for WebGL API compatibility reasons, but
   * it is highly recommended that you use [bufferSubDataTyped] or [bufferSubByteData]
   * depending on your purposes.
   */
  @DomName('WebGLRenderingContext.bufferSubData')
  @DocsEditable()
  void bufferSubData(int target, int offset, data) native;

  @JSName('bufferSubData')
  /**
   * Buffers the specified subset of data.
   *
   * The [bufferSubData] method is provided for WebGL API compatibility reasons, but
   * it is highly recommended that you use [bufferSubDataTyped] or [bufferSubByteData]
   * depending on your purposes.
   */
  @DomName('WebGLRenderingContext.bufferSubData')
  @DocsEditable()
  void bufferSubDataTyped(int target, int offset, TypedData data) native;

  @DomName('WebGLRenderingContext.checkFramebufferStatus')
  @DocsEditable()
  int checkFramebufferStatus(int target) native;

  @DomName('WebGLRenderingContext.clear')
  @DocsEditable()
  void clear(int mask) native;

  @DomName('WebGLRenderingContext.clearColor')
  @DocsEditable()
  void clearColor(num red, num green, num blue, num alpha) native;

  @DomName('WebGLRenderingContext.clearDepth')
  @DocsEditable()
  void clearDepth(num depth) native;

  @DomName('WebGLRenderingContext.clearStencil')
  @DocsEditable()
  void clearStencil(int s) native;

  @DomName('WebGLRenderingContext.colorMask')
  @DocsEditable()
  void colorMask(bool red, bool green, bool blue, bool alpha) native;

  @DomName('WebGLRenderingContext.compileShader')
  @DocsEditable()
  void compileShader(Shader shader) native;

  @DomName('WebGLRenderingContext.compressedTexImage2D')
  @DocsEditable()
  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, TypedData data) native;

  @DomName('WebGLRenderingContext.compressedTexSubImage2D')
  @DocsEditable()
  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, TypedData data) native;

  @DomName('WebGLRenderingContext.copyTexImage2D')
  @DocsEditable()
  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) native;

  @DomName('WebGLRenderingContext.copyTexSubImage2D')
  @DocsEditable()
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) native;

  @DomName('WebGLRenderingContext.createBuffer')
  @DocsEditable()
  Buffer createBuffer() native;

  @DomName('WebGLRenderingContext.createFramebuffer')
  @DocsEditable()
  Framebuffer createFramebuffer() native;

  @DomName('WebGLRenderingContext.createProgram')
  @DocsEditable()
  Program createProgram() native;

  @DomName('WebGLRenderingContext.createRenderbuffer')
  @DocsEditable()
  Renderbuffer createRenderbuffer() native;

  @DomName('WebGLRenderingContext.createShader')
  @DocsEditable()
  Shader createShader(int type) native;

  @DomName('WebGLRenderingContext.createTexture')
  @DocsEditable()
  Texture createTexture() native;

  @DomName('WebGLRenderingContext.cullFace')
  @DocsEditable()
  void cullFace(int mode) native;

  @DomName('WebGLRenderingContext.deleteBuffer')
  @DocsEditable()
  void deleteBuffer(Buffer buffer) native;

  @DomName('WebGLRenderingContext.deleteFramebuffer')
  @DocsEditable()
  void deleteFramebuffer(Framebuffer framebuffer) native;

  @DomName('WebGLRenderingContext.deleteProgram')
  @DocsEditable()
  void deleteProgram(Program program) native;

  @DomName('WebGLRenderingContext.deleteRenderbuffer')
  @DocsEditable()
  void deleteRenderbuffer(Renderbuffer renderbuffer) native;

  @DomName('WebGLRenderingContext.deleteShader')
  @DocsEditable()
  void deleteShader(Shader shader) native;

  @DomName('WebGLRenderingContext.deleteTexture')
  @DocsEditable()
  void deleteTexture(Texture texture) native;

  @DomName('WebGLRenderingContext.depthFunc')
  @DocsEditable()
  void depthFunc(int func) native;

  @DomName('WebGLRenderingContext.depthMask')
  @DocsEditable()
  void depthMask(bool flag) native;

  @DomName('WebGLRenderingContext.depthRange')
  @DocsEditable()
  void depthRange(num zNear, num zFar) native;

  @DomName('WebGLRenderingContext.detachShader')
  @DocsEditable()
  void detachShader(Program program, Shader shader) native;

  @DomName('WebGLRenderingContext.disable')
  @DocsEditable()
  void disable(int cap) native;

  @DomName('WebGLRenderingContext.disableVertexAttribArray')
  @DocsEditable()
  void disableVertexAttribArray(int index) native;

  @DomName('WebGLRenderingContext.drawArrays')
  @DocsEditable()
  void drawArrays(int mode, int first, int count) native;

  @DomName('WebGLRenderingContext.drawElements')
  @DocsEditable()
  void drawElements(int mode, int count, int type, int offset) native;

  @DomName('WebGLRenderingContext.enable')
  @DocsEditable()
  void enable(int cap) native;

  @DomName('WebGLRenderingContext.enableVertexAttribArray')
  @DocsEditable()
  void enableVertexAttribArray(int index) native;

  @DomName('WebGLRenderingContext.finish')
  @DocsEditable()
  void finish() native;

  @DomName('WebGLRenderingContext.flush')
  @DocsEditable()
  void flush() native;

  @DomName('WebGLRenderingContext.framebufferRenderbuffer')
  @DocsEditable()
  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, Renderbuffer renderbuffer) native;

  @DomName('WebGLRenderingContext.framebufferTexture2D')
  @DocsEditable()
  void framebufferTexture2D(int target, int attachment, int textarget, Texture texture, int level) native;

  @DomName('WebGLRenderingContext.frontFace')
  @DocsEditable()
  void frontFace(int mode) native;

  @DomName('WebGLRenderingContext.generateMipmap')
  @DocsEditable()
  void generateMipmap(int target) native;

  @DomName('WebGLRenderingContext.getActiveAttrib')
  @DocsEditable()
  ActiveInfo getActiveAttrib(Program program, int index) native;

  @DomName('WebGLRenderingContext.getActiveUniform')
  @DocsEditable()
  ActiveInfo getActiveUniform(Program program, int index) native;

  @DomName('WebGLRenderingContext.getAttachedShaders')
  @DocsEditable()
  List<Shader> getAttachedShaders(Program program) native;

  @DomName('WebGLRenderingContext.getAttribLocation')
  @DocsEditable()
  int getAttribLocation(Program program, String name) native;

  @DomName('WebGLRenderingContext.getBufferParameter')
  @DocsEditable()
  @Creates('int|Null')
  @Returns('int|Null')
  Object getBufferParameter(int target, int pname) native;

  @DomName('WebGLRenderingContext.getContextAttributes')
  @DocsEditable()
  @Creates('ContextAttributes|=Object')
  ContextAttributes getContextAttributes() {
    return convertNativeToDart_ContextAttributes(_getContextAttributes_1());
  }
  @JSName('getContextAttributes')
  @DomName('WebGLRenderingContext.getContextAttributes')
  @DocsEditable()
  @Creates('ContextAttributes|=Object')
  _getContextAttributes_1() native;

  @DomName('WebGLRenderingContext.getError')
  @DocsEditable()
  int getError() native;

  @DomName('WebGLRenderingContext.getExtension')
  @DocsEditable()
  Object getExtension(String name) native;

  @DomName('WebGLRenderingContext.getFramebufferAttachmentParameter')
  @DocsEditable()
  @Creates('int|Renderbuffer|Texture|Null')
  @Returns('int|Renderbuffer|Texture|Null')
  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) native;

  @DomName('WebGLRenderingContext.getParameter')
  @DocsEditable()
  @Creates('Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List|Framebuffer|Renderbuffer|Texture')
  @Returns('Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List|Framebuffer|Renderbuffer|Texture')
  Object getParameter(int pname) native;

  @DomName('WebGLRenderingContext.getProgramInfoLog')
  @DocsEditable()
  String getProgramInfoLog(Program program) native;

  @DomName('WebGLRenderingContext.getProgramParameter')
  @DocsEditable()
  @Creates('int|bool|Null')
  @Returns('int|bool|Null')
  Object getProgramParameter(Program program, int pname) native;

  @DomName('WebGLRenderingContext.getRenderbufferParameter')
  @DocsEditable()
  @Creates('int|Null')
  @Returns('int|Null')
  Object getRenderbufferParameter(int target, int pname) native;

  @DomName('WebGLRenderingContext.getShaderInfoLog')
  @DocsEditable()
  String getShaderInfoLog(Shader shader) native;

  @DomName('WebGLRenderingContext.getShaderParameter')
  @DocsEditable()
  @Creates('int|bool|Null')
  @Returns('int|bool|Null')
  Object getShaderParameter(Shader shader, int pname) native;

  @DomName('WebGLRenderingContext.getShaderPrecisionFormat')
  @DocsEditable()
  ShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype) native;

  @DomName('WebGLRenderingContext.getShaderSource')
  @DocsEditable()
  String getShaderSource(Shader shader) native;

  @DomName('WebGLRenderingContext.getSupportedExtensions')
  @DocsEditable()
  List<String> getSupportedExtensions() native;

  @DomName('WebGLRenderingContext.getTexParameter')
  @DocsEditable()
  @Creates('int|Null')
  @Returns('int|Null')
  Object getTexParameter(int target, int pname) native;

  @DomName('WebGLRenderingContext.getUniform')
  @DocsEditable()
  @Creates('Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List')
  @Returns('Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List')
  Object getUniform(Program program, UniformLocation location) native;

  @DomName('WebGLRenderingContext.getUniformLocation')
  @DocsEditable()
  UniformLocation getUniformLocation(Program program, String name) native;

  @DomName('WebGLRenderingContext.getVertexAttrib')
  @DocsEditable()
  @Creates('Null|num|bool|NativeFloat32List|Buffer')
  @Returns('Null|num|bool|NativeFloat32List|Buffer')
  Object getVertexAttrib(int index, int pname) native;

  @DomName('WebGLRenderingContext.getVertexAttribOffset')
  @DocsEditable()
  int getVertexAttribOffset(int index, int pname) native;

  @DomName('WebGLRenderingContext.hint')
  @DocsEditable()
  void hint(int target, int mode) native;

  @DomName('WebGLRenderingContext.isBuffer')
  @DocsEditable()
  bool isBuffer(Buffer buffer) native;

  @DomName('WebGLRenderingContext.isContextLost')
  @DocsEditable()
  bool isContextLost() native;

  @DomName('WebGLRenderingContext.isEnabled')
  @DocsEditable()
  bool isEnabled(int cap) native;

  @DomName('WebGLRenderingContext.isFramebuffer')
  @DocsEditable()
  bool isFramebuffer(Framebuffer framebuffer) native;

  @DomName('WebGLRenderingContext.isProgram')
  @DocsEditable()
  bool isProgram(Program program) native;

  @DomName('WebGLRenderingContext.isRenderbuffer')
  @DocsEditable()
  bool isRenderbuffer(Renderbuffer renderbuffer) native;

  @DomName('WebGLRenderingContext.isShader')
  @DocsEditable()
  bool isShader(Shader shader) native;

  @DomName('WebGLRenderingContext.isTexture')
  @DocsEditable()
  bool isTexture(Texture texture) native;

  @DomName('WebGLRenderingContext.lineWidth')
  @DocsEditable()
  void lineWidth(num width) native;

  @DomName('WebGLRenderingContext.linkProgram')
  @DocsEditable()
  void linkProgram(Program program) native;

  @DomName('WebGLRenderingContext.pixelStorei')
  @DocsEditable()
  void pixelStorei(int pname, int param) native;

  @DomName('WebGLRenderingContext.polygonOffset')
  @DocsEditable()
  void polygonOffset(num factor, num units) native;

  @DomName('WebGLRenderingContext.readPixels')
  @DocsEditable()
  void readPixels(int x, int y, int width, int height, int format, int type, TypedData pixels) native;

  @DomName('WebGLRenderingContext.renderbufferStorage')
  @DocsEditable()
  void renderbufferStorage(int target, int internalformat, int width, int height) native;

  @DomName('WebGLRenderingContext.sampleCoverage')
  @DocsEditable()
  void sampleCoverage(num value, bool invert) native;

  @DomName('WebGLRenderingContext.scissor')
  @DocsEditable()
  void scissor(int x, int y, int width, int height) native;

  @DomName('WebGLRenderingContext.shaderSource')
  @DocsEditable()
  void shaderSource(Shader shader, String string) native;

  @DomName('WebGLRenderingContext.stencilFunc')
  @DocsEditable()
  void stencilFunc(int func, int ref, int mask) native;

  @DomName('WebGLRenderingContext.stencilFuncSeparate')
  @DocsEditable()
  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  @DomName('WebGLRenderingContext.stencilMask')
  @DocsEditable()
  void stencilMask(int mask) native;

  @DomName('WebGLRenderingContext.stencilMaskSeparate')
  @DocsEditable()
  void stencilMaskSeparate(int face, int mask) native;

  @DomName('WebGLRenderingContext.stencilOp')
  @DocsEditable()
  void stencilOp(int fail, int zfail, int zpass) native;

  @DomName('WebGLRenderingContext.stencilOpSeparate')
  @DocsEditable()
  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, [int format, int type, TypedData pixels]) {
    if (pixels != null && type != null && format != null && (border_OR_canvas_OR_image_OR_pixels_OR_video is int)) {
      _texImage2D_1(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && format == null && type == null && pixels == null) {
      var pixels_1 = convertDartToNative_ImageData(border_OR_canvas_OR_image_OR_pixels_OR_video);
      _texImage2D_2(target, level, internalformat, format_OR_width, height_OR_type, pixels_1);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement) && format == null && type == null && pixels == null) {
      _texImage2D_3(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement) && format == null && type == null && pixels == null) {
      _texImage2D_4(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement) && format == null && type == null && pixels == null) {
      _texImage2D_5(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('texImage2D')
  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_1(target, level, internalformat, width, height, int border, format, type, TypedData pixels) native;
  @JSName('texImage2D')
  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_2(target, level, internalformat, format, type, pixels) native;
  @JSName('texImage2D')
  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_3(target, level, internalformat, format, type, ImageElement image) native;
  @JSName('texImage2D')
  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_4(target, level, internalformat, format, type, CanvasElement canvas) native;
  @JSName('texImage2D')
  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_5(target, level, internalformat, format, type, VideoElement video) native;

  @JSName('texImage2D')
  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void texImage2DCanvas(int target, int level, int internalformat, int format, int type, CanvasElement canvas) native;

  @JSName('texImage2D')
  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void texImage2DImage(int target, int level, int internalformat, int format, int type, ImageElement image) native;

  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void texImage2DImageData(int target, int level, int internalformat, int format, int type, ImageData pixels) {
    var pixels_1 = convertDartToNative_ImageData(pixels);
    _texImage2DImageData_1(target, level, internalformat, format, type, pixels_1);
    return;
  }
  @JSName('texImage2D')
  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2DImageData_1(target, level, internalformat, format, type, pixels) native;

  @JSName('texImage2D')
  /**
   * Updates the currently bound texture to [data].
   *
   * The [texImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texImage2DUntyped] or [texImage2DTyped]
   * (or for more specificity, the more specialized [texImage2DImageData],
   * [texImage2DCanvas], [texImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void texImage2DVideo(int target, int level, int internalformat, int format, int type, VideoElement video) native;

  @DomName('WebGLRenderingContext.texParameterf')
  @DocsEditable()
  void texParameterf(int target, int pname, num param) native;

  @DomName('WebGLRenderingContext.texParameteri')
  @DocsEditable()
  void texParameteri(int target, int pname, int param) native;

  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, [int type, TypedData pixels]) {
    if (pixels != null && type != null && (canvas_OR_format_OR_image_OR_pixels_OR_video is int)) {
      _texSubImage2D_1(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && type == null && pixels == null) {
      var pixels_1 = convertDartToNative_ImageData(canvas_OR_format_OR_image_OR_pixels_OR_video);
      _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width, height_OR_type, pixels_1);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement) && type == null && pixels == null) {
      _texSubImage2D_3(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement) && type == null && pixels == null) {
      _texSubImage2D_4(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement) && type == null && pixels == null) {
      _texSubImage2D_5(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('texSubImage2D')
  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_1(target, level, xoffset, yoffset, width, height, int format, type, TypedData pixels) native;
  @JSName('texSubImage2D')
  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_2(target, level, xoffset, yoffset, format, type, pixels) native;
  @JSName('texSubImage2D')
  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_3(target, level, xoffset, yoffset, format, type, ImageElement image) native;
  @JSName('texSubImage2D')
  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_4(target, level, xoffset, yoffset, format, type, CanvasElement canvas) native;
  @JSName('texSubImage2D')
  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_5(target, level, xoffset, yoffset, format, type, VideoElement video) native;

  @JSName('texSubImage2D')
  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void texSubImage2DCanvas(int target, int level, int xoffset, int yoffset, int format, int type, CanvasElement canvas) native;

  @JSName('texSubImage2D')
  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void texSubImage2DImage(int target, int level, int xoffset, int yoffset, int format, int type, ImageElement image) native;

  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void texSubImage2DImageData(int target, int level, int xoffset, int yoffset, int format, int type, ImageData pixels) {
    var pixels_1 = convertDartToNative_ImageData(pixels);
    _texSubImage2DImageData_1(target, level, xoffset, yoffset, format, type, pixels_1);
    return;
  }
  @JSName('texSubImage2D')
  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2DImageData_1(target, level, xoffset, yoffset, format, type, pixels) native;

  @JSName('texSubImage2D')
  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * The [texSubImage2D] method is provided for WebGL API compatibility reasons, but it
   * is highly recommended that you use [texSubImage2DUntyped] or [texSubImage2DTyped]
   * (or for more specificity, the more specialized [texSubImage2DImageData],
   * [texSubImage2DCanvas], [texSubImage2DVideo]).
   */
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void texSubImage2DVideo(int target, int level, int xoffset, int yoffset, int format, int type, VideoElement video) native;

  @DomName('WebGLRenderingContext.uniform1f')
  @DocsEditable()
  void uniform1f(UniformLocation location, num x) native;

  @DomName('WebGLRenderingContext.uniform1fv')
  @DocsEditable()
  void uniform1fv(UniformLocation location, Float32List v) native;

  @DomName('WebGLRenderingContext.uniform1i')
  @DocsEditable()
  void uniform1i(UniformLocation location, int x) native;

  @DomName('WebGLRenderingContext.uniform1iv')
  @DocsEditable()
  void uniform1iv(UniformLocation location, Int32List v) native;

  @DomName('WebGLRenderingContext.uniform2f')
  @DocsEditable()
  void uniform2f(UniformLocation location, num x, num y) native;

  @DomName('WebGLRenderingContext.uniform2fv')
  @DocsEditable()
  void uniform2fv(UniformLocation location, Float32List v) native;

  @DomName('WebGLRenderingContext.uniform2i')
  @DocsEditable()
  void uniform2i(UniformLocation location, int x, int y) native;

  @DomName('WebGLRenderingContext.uniform2iv')
  @DocsEditable()
  void uniform2iv(UniformLocation location, Int32List v) native;

  @DomName('WebGLRenderingContext.uniform3f')
  @DocsEditable()
  void uniform3f(UniformLocation location, num x, num y, num z) native;

  @DomName('WebGLRenderingContext.uniform3fv')
  @DocsEditable()
  void uniform3fv(UniformLocation location, Float32List v) native;

  @DomName('WebGLRenderingContext.uniform3i')
  @DocsEditable()
  void uniform3i(UniformLocation location, int x, int y, int z) native;

  @DomName('WebGLRenderingContext.uniform3iv')
  @DocsEditable()
  void uniform3iv(UniformLocation location, Int32List v) native;

  @DomName('WebGLRenderingContext.uniform4f')
  @DocsEditable()
  void uniform4f(UniformLocation location, num x, num y, num z, num w) native;

  @DomName('WebGLRenderingContext.uniform4fv')
  @DocsEditable()
  void uniform4fv(UniformLocation location, Float32List v) native;

  @DomName('WebGLRenderingContext.uniform4i')
  @DocsEditable()
  void uniform4i(UniformLocation location, int x, int y, int z, int w) native;

  @DomName('WebGLRenderingContext.uniform4iv')
  @DocsEditable()
  void uniform4iv(UniformLocation location, Int32List v) native;

  @DomName('WebGLRenderingContext.uniformMatrix2fv')
  @DocsEditable()
  void uniformMatrix2fv(UniformLocation location, bool transpose, Float32List array) native;

  @DomName('WebGLRenderingContext.uniformMatrix3fv')
  @DocsEditable()
  void uniformMatrix3fv(UniformLocation location, bool transpose, Float32List array) native;

  @DomName('WebGLRenderingContext.uniformMatrix4fv')
  @DocsEditable()
  void uniformMatrix4fv(UniformLocation location, bool transpose, Float32List array) native;

  @DomName('WebGLRenderingContext.useProgram')
  @DocsEditable()
  void useProgram(Program program) native;

  @DomName('WebGLRenderingContext.validateProgram')
  @DocsEditable()
  void validateProgram(Program program) native;

  @DomName('WebGLRenderingContext.vertexAttrib1f')
  @DocsEditable()
  void vertexAttrib1f(int indx, num x) native;

  @DomName('WebGLRenderingContext.vertexAttrib1fv')
  @DocsEditable()
  void vertexAttrib1fv(int indx, Float32List values) native;

  @DomName('WebGLRenderingContext.vertexAttrib2f')
  @DocsEditable()
  void vertexAttrib2f(int indx, num x, num y) native;

  @DomName('WebGLRenderingContext.vertexAttrib2fv')
  @DocsEditable()
  void vertexAttrib2fv(int indx, Float32List values) native;

  @DomName('WebGLRenderingContext.vertexAttrib3f')
  @DocsEditable()
  void vertexAttrib3f(int indx, num x, num y, num z) native;

  @DomName('WebGLRenderingContext.vertexAttrib3fv')
  @DocsEditable()
  void vertexAttrib3fv(int indx, Float32List values) native;

  @DomName('WebGLRenderingContext.vertexAttrib4f')
  @DocsEditable()
  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  @DomName('WebGLRenderingContext.vertexAttrib4fv')
  @DocsEditable()
  void vertexAttrib4fv(int indx, Float32List values) native;

  @DomName('WebGLRenderingContext.vertexAttribPointer')
  @DocsEditable()
  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) native;

  @DomName('WebGLRenderingContext.viewport')
  @DocsEditable()
  void viewport(int x, int y, int width, int height) native;


  /**
   * Sets the currently bound texture to [data].
   *
   * [data] can be either an [ImageElement], a
   * [CanvasElement], a [VideoElement], or an [ImageData] object.
   *
   * To use [texImage2d] with a TypedData object, use [texImage2dTyped].
   *
   */
  @JSName('texImage2D')
  void texImage2DUntyped(int targetTexture, int levelOfDetail, 
      int internalFormat, int format, int type, data) native;

  /**
   * Sets the currently bound texture to [data].
   */
  @JSName('texImage2D')
  void texImage2DTyped(int targetTexture, int levelOfDetail,
      int internalFormat, int width, int height, int border, int format,
      int type, TypedData data) native;

  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * [data] can be either an [ImageElement], a
   * [CanvasElement], a [VideoElement], or an [ImageData] object.
   *
   * To use [texSubImage2d] with a TypedData object, use [texSubImage2dTyped].
   *
   */
  @JSName('texSubImage2D')
  void texSubImage2DUntyped(int targetTexture, int levelOfDetail,
      int xOffset, int yOffset, int format, int type, data) native;

  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   */
  @JSName('texSubImage2D')
  void texSubImage2DTyped(int targetTexture, int levelOfDetail,
      int xOffset, int yOffset, int width, int height, int border, int format,
      int type, TypedData data) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLRenderingContextBase')
@Experimental() // untriaged
abstract class RenderingContextBase extends Interceptor {
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

  final CanvasElement canvas;

  final int drawingBufferHeight;

  final int drawingBufferWidth;

  void activeTexture(int texture);

  void attachShader(Program program, Shader shader);

  void bindAttribLocation(Program program, int index, String name);

  void bindBuffer(int target, Buffer buffer);

  void bindFramebuffer(int target, Framebuffer framebuffer);

  void bindRenderbuffer(int target, Renderbuffer renderbuffer);

  void bindTexture(int target, Texture texture);

  void blendColor(num red, num green, num blue, num alpha);

  void blendEquation(int mode);

  void blendEquationSeparate(int modeRGB, int modeAlpha);

  void blendFunc(int sfactor, int dfactor);

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha);

  void bufferByteData(int target, ByteBuffer data, int usage);

  void bufferData(int target, data_OR_size, int usage);

  void bufferDataTyped(int target, TypedData data, int usage);

  void bufferSubByteData(int target, int offset, ByteBuffer data);

  void bufferSubData(int target, int offset, data);

  void bufferSubDataTyped(int target, int offset, TypedData data);

  int checkFramebufferStatus(int target);

  void clear(int mask);

  void clearColor(num red, num green, num blue, num alpha);

  void clearDepth(num depth);

  void clearStencil(int s);

  void colorMask(bool red, bool green, bool blue, bool alpha);

  void compileShader(Shader shader);

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, TypedData data);

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, TypedData data);

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border);

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height);

  Buffer createBuffer();

  Framebuffer createFramebuffer();

  Program createProgram();

  Renderbuffer createRenderbuffer();

  Shader createShader(int type);

  Texture createTexture();

  void cullFace(int mode);

  void deleteBuffer(Buffer buffer);

  void deleteFramebuffer(Framebuffer framebuffer);

  void deleteProgram(Program program);

  void deleteRenderbuffer(Renderbuffer renderbuffer);

  void deleteShader(Shader shader);

  void deleteTexture(Texture texture);

  void depthFunc(int func);

  void depthMask(bool flag);

  void depthRange(num zNear, num zFar);

  void detachShader(Program program, Shader shader);

  void disable(int cap);

  void disableVertexAttribArray(int index);

  void drawArrays(int mode, int first, int count);

  void drawElements(int mode, int count, int type, int offset);

  void enable(int cap);

  void enableVertexAttribArray(int index);

  void finish();

  void flush();

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, Renderbuffer renderbuffer);

  void framebufferTexture2D(int target, int attachment, int textarget, Texture texture, int level);

  void frontFace(int mode);

  void generateMipmap(int target);

  ActiveInfo getActiveAttrib(Program program, int index);

  ActiveInfo getActiveUniform(Program program, int index);

  List<Shader> getAttachedShaders(Program program);

  int getAttribLocation(Program program, String name);

  Object getBufferParameter(int target, int pname);

  ContextAttributes getContextAttributes();

  int getError();

  Object getExtension(String name);

  Object getFramebufferAttachmentParameter(int target, int attachment, int pname);

  Object getParameter(int pname);

  String getProgramInfoLog(Program program);

  Object getProgramParameter(Program program, int pname);

  Object getRenderbufferParameter(int target, int pname);

  String getShaderInfoLog(Shader shader);

  Object getShaderParameter(Shader shader, int pname);

  ShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype);

  String getShaderSource(Shader shader);

  List<String> getSupportedExtensions();

  Object getTexParameter(int target, int pname);

  Object getUniform(Program program, UniformLocation location);

  UniformLocation getUniformLocation(Program program, String name);

  Object getVertexAttrib(int index, int pname);

  int getVertexAttribOffset(int index, int pname);

  void hint(int target, int mode);

  bool isBuffer(Buffer buffer);

  bool isContextLost();

  bool isEnabled(int cap);

  bool isFramebuffer(Framebuffer framebuffer);

  bool isProgram(Program program);

  bool isRenderbuffer(Renderbuffer renderbuffer);

  bool isShader(Shader shader);

  bool isTexture(Texture texture);

  void lineWidth(num width);

  void linkProgram(Program program);

  void pixelStorei(int pname, int param);

  void polygonOffset(num factor, num units);

  void readPixels(int x, int y, int width, int height, int format, int type, TypedData pixels);

  void renderbufferStorage(int target, int internalformat, int width, int height);

  void sampleCoverage(num value, bool invert);

  void scissor(int x, int y, int width, int height);

  void shaderSource(Shader shader, String string);

  void stencilFunc(int func, int ref, int mask);

  void stencilFuncSeparate(int face, int func, int ref, int mask);

  void stencilMask(int mask);

  void stencilMaskSeparate(int face, int mask);

  void stencilOp(int fail, int zfail, int zpass);

  void stencilOpSeparate(int face, int fail, int zfail, int zpass);

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, [int format, int type, TypedData pixels]);

  void texImage2DCanvas(int target, int level, int internalformat, int format, int type, CanvasElement canvas);

  void texImage2DImage(int target, int level, int internalformat, int format, int type, ImageElement image);

  void texImage2DImageData(int target, int level, int internalformat, int format, int type, ImageData pixels);

  void texImage2DVideo(int target, int level, int internalformat, int format, int type, VideoElement video);

  void texParameterf(int target, int pname, num param);

  void texParameteri(int target, int pname, int param);

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, [int type, TypedData pixels]);

  void texSubImage2DCanvas(int target, int level, int xoffset, int yoffset, int format, int type, CanvasElement canvas);

  void texSubImage2DImage(int target, int level, int xoffset, int yoffset, int format, int type, ImageElement image);

  void texSubImage2DImageData(int target, int level, int xoffset, int yoffset, int format, int type, ImageData pixels);

  void texSubImage2DVideo(int target, int level, int xoffset, int yoffset, int format, int type, VideoElement video);

  void uniform1f(UniformLocation location, num x);

  void uniform1fv(UniformLocation location, Float32List v);

  void uniform1i(UniformLocation location, int x);

  void uniform1iv(UniformLocation location, Int32List v);

  void uniform2f(UniformLocation location, num x, num y);

  void uniform2fv(UniformLocation location, Float32List v);

  void uniform2i(UniformLocation location, int x, int y);

  void uniform2iv(UniformLocation location, Int32List v);

  void uniform3f(UniformLocation location, num x, num y, num z);

  void uniform3fv(UniformLocation location, Float32List v);

  void uniform3i(UniformLocation location, int x, int y, int z);

  void uniform3iv(UniformLocation location, Int32List v);

  void uniform4f(UniformLocation location, num x, num y, num z, num w);

  void uniform4fv(UniformLocation location, Float32List v);

  void uniform4i(UniformLocation location, int x, int y, int z, int w);

  void uniform4iv(UniformLocation location, Int32List v);

  void uniformMatrix2fv(UniformLocation location, bool transpose, Float32List array);

  void uniformMatrix3fv(UniformLocation location, bool transpose, Float32List array);

  void uniformMatrix4fv(UniformLocation location, bool transpose, Float32List array);

  void useProgram(Program program);

  void validateProgram(Program program);

  void vertexAttrib1f(int indx, num x);

  void vertexAttrib1fv(int indx, Float32List values);

  void vertexAttrib2f(int indx, num x, num y);

  void vertexAttrib2fv(int indx, Float32List values);

  void vertexAttrib3f(int indx, num x, num y, num z);

  void vertexAttrib3fv(int indx, Float32List values);

  void vertexAttrib4f(int indx, num x, num y, num z, num w);

  void vertexAttrib4fv(int indx, Float32List values);

  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset);

  void viewport(int x, int y, int width, int height);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLShader')
@Native("WebGLShader")
class Shader extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Shader._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLShaderPrecisionFormat')
@Native("WebGLShaderPrecisionFormat")
class ShaderPrecisionFormat extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ShaderPrecisionFormat._() { throw new UnsupportedError("Not supported"); }

  @DomName('WebGLShaderPrecisionFormat.precision')
  @DocsEditable()
  final int precision;

  @DomName('WebGLShaderPrecisionFormat.rangeMax')
  @DocsEditable()
  final int rangeMax;

  @DomName('WebGLShaderPrecisionFormat.rangeMin')
  @DocsEditable()
  final int rangeMin;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLTexture')
@Native("WebGLTexture")
class Texture extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Texture._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLUniformLocation')
@Native("WebGLUniformLocation")
class UniformLocation extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory UniformLocation._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WebGLVertexArrayObjectOES')
// http://www.khronos.org/registry/webgl/extensions/OES_vertex_array_object/
@Experimental() // experimental
@Native("WebGLVertexArrayObjectOES")
class VertexArrayObject extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory VertexArrayObject._() { throw new UnsupportedError("Not supported"); }
}
