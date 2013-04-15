library dart.dom.web_gl;

import 'dart:async';
import 'dart:collection';
import 'dart:_collection-dev';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:typeddata' as _typeddata;
// DO NOT EDIT
// Auto-generated dart:web_gl library.





// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


const int ACTIVE_ATTRIBUTES = RenderingContext.ACTIVE_ATTRIBUTES;
const int ACTIVE_TEXTURE = RenderingContext.ACTIVE_TEXTURE;
const int ACTIVE_UNIFORMS = RenderingContext.ACTIVE_UNIFORMS;
const int ALIASED_LINE_WIDTH_RANGE = RenderingContext.ALIASED_LINE_WIDTH_RANGE;
const int ALIASED_POINT_SIZE_RANGE = RenderingContext.ALIASED_POINT_SIZE_RANGE;
const int ALPHA = RenderingContext.ALPHA;
const int ALPHA_BITS = RenderingContext.ALPHA_BITS;
const int ALWAYS = RenderingContext.ALWAYS;
const int ARRAY_BUFFER = RenderingContext.ARRAY_BUFFER;
const int ARRAY_BUFFER_BINDING = RenderingContext.ARRAY_BUFFER_BINDING;
const int ATTACHED_SHADERS = RenderingContext.ATTACHED_SHADERS;
const int BACK = RenderingContext.BACK;
const int BLEND = RenderingContext.BLEND;
const int BLEND_COLOR = RenderingContext.BLEND_COLOR;
const int BLEND_DST_ALPHA = RenderingContext.BLEND_DST_ALPHA;
const int BLEND_DST_RGB = RenderingContext.BLEND_DST_RGB;
const int BLEND_EQUATION = RenderingContext.BLEND_EQUATION;
const int BLEND_EQUATION_ALPHA = RenderingContext.BLEND_EQUATION_ALPHA;
const int BLEND_EQUATION_RGB = RenderingContext.BLEND_EQUATION_RGB;
const int BLEND_SRC_ALPHA = RenderingContext.BLEND_SRC_ALPHA;
const int BLEND_SRC_RGB = RenderingContext.BLEND_SRC_RGB;
const int BLUE_BITS = RenderingContext.BLUE_BITS;
const int BOOL = RenderingContext.BOOL;
const int BOOL_VEC2 = RenderingContext.BOOL_VEC2;
const int BOOL_VEC3 = RenderingContext.BOOL_VEC3;
const int BOOL_VEC4 = RenderingContext.BOOL_VEC4;
const int BROWSER_DEFAULT_WEBGL = RenderingContext.BROWSER_DEFAULT_WEBGL;
const int BUFFER_SIZE = RenderingContext.BUFFER_SIZE;
const int BUFFER_USAGE = RenderingContext.BUFFER_USAGE;
const int BYTE = RenderingContext.BYTE;
const int CCW = RenderingContext.CCW;
const int CLAMP_TO_EDGE = RenderingContext.CLAMP_TO_EDGE;
const int COLOR_ATTACHMENT0 = RenderingContext.COLOR_ATTACHMENT0;
const int COLOR_BUFFER_BIT = RenderingContext.COLOR_BUFFER_BIT;
const int COLOR_CLEAR_VALUE = RenderingContext.COLOR_CLEAR_VALUE;
const int COLOR_WRITEMASK = RenderingContext.COLOR_WRITEMASK;
const int COMPILE_STATUS = RenderingContext.COMPILE_STATUS;
const int COMPRESSED_TEXTURE_FORMATS = RenderingContext.COMPRESSED_TEXTURE_FORMATS;
const int CONSTANT_ALPHA = RenderingContext.CONSTANT_ALPHA;
const int CONSTANT_COLOR = RenderingContext.CONSTANT_COLOR;
const int CONTEXT_LOST_WEBGL = RenderingContext.CONTEXT_LOST_WEBGL;
const int CULL_FACE = RenderingContext.CULL_FACE;
const int CULL_FACE_MODE = RenderingContext.CULL_FACE_MODE;
const int CURRENT_PROGRAM = RenderingContext.CURRENT_PROGRAM;
const int CURRENT_VERTEX_ATTRIB = RenderingContext.CURRENT_VERTEX_ATTRIB;
const int CW = RenderingContext.CW;
const int DECR = RenderingContext.DECR;
const int DECR_WRAP = RenderingContext.DECR_WRAP;
const int DELETE_STATUS = RenderingContext.DELETE_STATUS;
const int DEPTH_ATTACHMENT = RenderingContext.DEPTH_ATTACHMENT;
const int DEPTH_BITS = RenderingContext.DEPTH_BITS;
const int DEPTH_BUFFER_BIT = RenderingContext.DEPTH_BUFFER_BIT;
const int DEPTH_CLEAR_VALUE = RenderingContext.DEPTH_CLEAR_VALUE;
const int DEPTH_COMPONENT = RenderingContext.DEPTH_COMPONENT;
const int DEPTH_COMPONENT16 = RenderingContext.DEPTH_COMPONENT16;
const int DEPTH_FUNC = RenderingContext.DEPTH_FUNC;
const int DEPTH_RANGE = RenderingContext.DEPTH_RANGE;
const int DEPTH_STENCIL = RenderingContext.DEPTH_STENCIL;
const int DEPTH_STENCIL_ATTACHMENT = RenderingContext.DEPTH_STENCIL_ATTACHMENT;
const int DEPTH_TEST = RenderingContext.DEPTH_TEST;
const int DEPTH_WRITEMASK = RenderingContext.DEPTH_WRITEMASK;
const int DITHER = RenderingContext.DITHER;
const int DONT_CARE = RenderingContext.DONT_CARE;
const int DST_ALPHA = RenderingContext.DST_ALPHA;
const int DST_COLOR = RenderingContext.DST_COLOR;
const int DYNAMIC_DRAW = RenderingContext.DYNAMIC_DRAW;
const int ELEMENT_ARRAY_BUFFER = RenderingContext.ELEMENT_ARRAY_BUFFER;
const int ELEMENT_ARRAY_BUFFER_BINDING = RenderingContext.ELEMENT_ARRAY_BUFFER_BINDING;
const int EQUAL = RenderingContext.EQUAL;
const int FASTEST = RenderingContext.FASTEST;
const int FLOAT = RenderingContext.FLOAT;
const int FLOAT_MAT2 = RenderingContext.FLOAT_MAT2;
const int FLOAT_MAT3 = RenderingContext.FLOAT_MAT3;
const int FLOAT_MAT4 = RenderingContext.FLOAT_MAT4;
const int FLOAT_VEC2 = RenderingContext.FLOAT_VEC2;
const int FLOAT_VEC3 = RenderingContext.FLOAT_VEC3;
const int FLOAT_VEC4 = RenderingContext.FLOAT_VEC4;
const int FRAGMENT_SHADER = RenderingContext.FRAGMENT_SHADER;
const int FRAMEBUFFER = RenderingContext.FRAMEBUFFER;
const int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = RenderingContext.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME;
const int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = RenderingContext.FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE;
const int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = RenderingContext.FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE;
const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = RenderingContext.FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL;
const int FRAMEBUFFER_BINDING = RenderingContext.FRAMEBUFFER_BINDING;
const int FRAMEBUFFER_COMPLETE = RenderingContext.FRAMEBUFFER_COMPLETE;
const int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = RenderingContext.FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
const int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = RenderingContext.FRAMEBUFFER_INCOMPLETE_DIMENSIONS;
const int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = RenderingContext.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT;
const int FRAMEBUFFER_UNSUPPORTED = RenderingContext.FRAMEBUFFER_UNSUPPORTED;
const int FRONT = RenderingContext.FRONT;
const int FRONT_AND_BACK = RenderingContext.FRONT_AND_BACK;
const int FRONT_FACE = RenderingContext.FRONT_FACE;
const int FUNC_ADD = RenderingContext.FUNC_ADD;
const int FUNC_REVERSE_SUBTRACT = RenderingContext.FUNC_REVERSE_SUBTRACT;
const int FUNC_SUBTRACT = RenderingContext.FUNC_SUBTRACT;
const int GENERATE_MIPMAP_HINT = RenderingContext.GENERATE_MIPMAP_HINT;
const int GEQUAL = RenderingContext.GEQUAL;
const int GREATER = RenderingContext.GREATER;
const int GREEN_BITS = RenderingContext.GREEN_BITS;
const int HALF_FLOAT_OES = RenderingContext.HALF_FLOAT_OES;
const int HIGH_FLOAT = RenderingContext.HIGH_FLOAT;
const int HIGH_INT = RenderingContext.HIGH_INT;
const int INCR = RenderingContext.INCR;
const int INCR_WRAP = RenderingContext.INCR_WRAP;
const int INT = RenderingContext.INT;
const int INT_VEC2 = RenderingContext.INT_VEC2;
const int INT_VEC3 = RenderingContext.INT_VEC3;
const int INT_VEC4 = RenderingContext.INT_VEC4;
const int INVALID_ENUM = RenderingContext.INVALID_ENUM;
const int INVALID_FRAMEBUFFER_OPERATION = RenderingContext.INVALID_FRAMEBUFFER_OPERATION;
const int INVALID_OPERATION = RenderingContext.INVALID_OPERATION;
const int INVALID_VALUE = RenderingContext.INVALID_VALUE;
const int INVERT = RenderingContext.INVERT;
const int KEEP = RenderingContext.KEEP;
const int LEQUAL = RenderingContext.LEQUAL;
const int LESS = RenderingContext.LESS;
const int LINEAR = RenderingContext.LINEAR;
const int LINEAR_MIPMAP_LINEAR = RenderingContext.LINEAR_MIPMAP_LINEAR;
const int LINEAR_MIPMAP_NEAREST = RenderingContext.LINEAR_MIPMAP_NEAREST;
const int LINES = RenderingContext.LINES;
const int LINE_LOOP = RenderingContext.LINE_LOOP;
const int LINE_STRIP = RenderingContext.LINE_STRIP;
const int LINE_WIDTH = RenderingContext.LINE_WIDTH;
const int LINK_STATUS = RenderingContext.LINK_STATUS;
const int LOW_FLOAT = RenderingContext.LOW_FLOAT;
const int LOW_INT = RenderingContext.LOW_INT;
const int LUMINANCE = RenderingContext.LUMINANCE;
const int LUMINANCE_ALPHA = RenderingContext.LUMINANCE_ALPHA;
const int MAX_COMBINED_TEXTURE_IMAGE_UNITS = RenderingContext.MAX_COMBINED_TEXTURE_IMAGE_UNITS;
const int MAX_CUBE_MAP_TEXTURE_SIZE = RenderingContext.MAX_CUBE_MAP_TEXTURE_SIZE;
const int MAX_FRAGMENT_UNIFORM_VECTORS = RenderingContext.MAX_FRAGMENT_UNIFORM_VECTORS;
const int MAX_RENDERBUFFER_SIZE = RenderingContext.MAX_RENDERBUFFER_SIZE;
const int MAX_TEXTURE_IMAGE_UNITS = RenderingContext.MAX_TEXTURE_IMAGE_UNITS;
const int MAX_TEXTURE_SIZE = RenderingContext.MAX_TEXTURE_SIZE;
const int MAX_VARYING_VECTORS = RenderingContext.MAX_VARYING_VECTORS;
const int MAX_VERTEX_ATTRIBS = RenderingContext.MAX_VERTEX_ATTRIBS;
const int MAX_VERTEX_TEXTURE_IMAGE_UNITS = RenderingContext.MAX_VERTEX_TEXTURE_IMAGE_UNITS;
const int MAX_VERTEX_UNIFORM_VECTORS = RenderingContext.MAX_VERTEX_UNIFORM_VECTORS;
const int MAX_VIEWPORT_DIMS = RenderingContext.MAX_VIEWPORT_DIMS;
const int MEDIUM_FLOAT = RenderingContext.MEDIUM_FLOAT;
const int MEDIUM_INT = RenderingContext.MEDIUM_INT;
const int MIRRORED_REPEAT = RenderingContext.MIRRORED_REPEAT;
const int NEAREST = RenderingContext.NEAREST;
const int NEAREST_MIPMAP_LINEAR = RenderingContext.NEAREST_MIPMAP_LINEAR;
const int NEAREST_MIPMAP_NEAREST = RenderingContext.NEAREST_MIPMAP_NEAREST;
const int NEVER = RenderingContext.NEVER;
const int NICEST = RenderingContext.NICEST;
const int NONE = RenderingContext.NONE;
const int NOTEQUAL = RenderingContext.NOTEQUAL;
const int NO_ERROR = RenderingContext.NO_ERROR;
const int ONE = RenderingContext.ONE;
const int ONE_MINUS_CONSTANT_ALPHA = RenderingContext.ONE_MINUS_CONSTANT_ALPHA;
const int ONE_MINUS_CONSTANT_COLOR = RenderingContext.ONE_MINUS_CONSTANT_COLOR;
const int ONE_MINUS_DST_ALPHA = RenderingContext.ONE_MINUS_DST_ALPHA;
const int ONE_MINUS_DST_COLOR = RenderingContext.ONE_MINUS_DST_COLOR;
const int ONE_MINUS_SRC_ALPHA = RenderingContext.ONE_MINUS_SRC_ALPHA;
const int ONE_MINUS_SRC_COLOR = RenderingContext.ONE_MINUS_SRC_COLOR;
const int OUT_OF_MEMORY = RenderingContext.OUT_OF_MEMORY;
const int PACK_ALIGNMENT = RenderingContext.PACK_ALIGNMENT;
const int POINTS = RenderingContext.POINTS;
const int POLYGON_OFFSET_FACTOR = RenderingContext.POLYGON_OFFSET_FACTOR;
const int POLYGON_OFFSET_FILL = RenderingContext.POLYGON_OFFSET_FILL;
const int POLYGON_OFFSET_UNITS = RenderingContext.POLYGON_OFFSET_UNITS;
const int RED_BITS = RenderingContext.RED_BITS;
const int RENDERBUFFER = RenderingContext.RENDERBUFFER;
const int RENDERBUFFER_ALPHA_SIZE = RenderingContext.RENDERBUFFER_ALPHA_SIZE;
const int RENDERBUFFER_BINDING = RenderingContext.RENDERBUFFER_BINDING;
const int RENDERBUFFER_BLUE_SIZE = RenderingContext.RENDERBUFFER_BLUE_SIZE;
const int RENDERBUFFER_DEPTH_SIZE = RenderingContext.RENDERBUFFER_DEPTH_SIZE;
const int RENDERBUFFER_GREEN_SIZE = RenderingContext.RENDERBUFFER_GREEN_SIZE;
const int RENDERBUFFER_HEIGHT = RenderingContext.RENDERBUFFER_HEIGHT;
const int RENDERBUFFER_INTERNAL_FORMAT = RenderingContext.RENDERBUFFER_INTERNAL_FORMAT;
const int RENDERBUFFER_RED_SIZE = RenderingContext.RENDERBUFFER_RED_SIZE;
const int RENDERBUFFER_STENCIL_SIZE = RenderingContext.RENDERBUFFER_STENCIL_SIZE;
const int RENDERBUFFER_WIDTH = RenderingContext.RENDERBUFFER_WIDTH;
const int RENDERER = RenderingContext.RENDERER;
const int REPEAT = RenderingContext.REPEAT;
const int REPLACE = RenderingContext.REPLACE;
const int RGB = RenderingContext.RGB;
const int RGB565 = RenderingContext.RGB565;
const int RGB5_A1 = RenderingContext.RGB5_A1;
const int RGBA = RenderingContext.RGBA;
const int RGBA4 = RenderingContext.RGBA4;
const int SAMPLER_2D = RenderingContext.SAMPLER_2D;
const int SAMPLER_CUBE = RenderingContext.SAMPLER_CUBE;
const int SAMPLES = RenderingContext.SAMPLES;
const int SAMPLE_ALPHA_TO_COVERAGE = RenderingContext.SAMPLE_ALPHA_TO_COVERAGE;
const int SAMPLE_BUFFERS = RenderingContext.SAMPLE_BUFFERS;
const int SAMPLE_COVERAGE = RenderingContext.SAMPLE_COVERAGE;
const int SAMPLE_COVERAGE_INVERT = RenderingContext.SAMPLE_COVERAGE_INVERT;
const int SAMPLE_COVERAGE_VALUE = RenderingContext.SAMPLE_COVERAGE_VALUE;
const int SCISSOR_BOX = RenderingContext.SCISSOR_BOX;
const int SCISSOR_TEST = RenderingContext.SCISSOR_TEST;
const int SHADER_TYPE = RenderingContext.SHADER_TYPE;
const int SHADING_LANGUAGE_VERSION = RenderingContext.SHADING_LANGUAGE_VERSION;
const int SHORT = RenderingContext.SHORT;
const int SRC_ALPHA = RenderingContext.SRC_ALPHA;
const int SRC_ALPHA_SATURATE = RenderingContext.SRC_ALPHA_SATURATE;
const int SRC_COLOR = RenderingContext.SRC_COLOR;
const int STATIC_DRAW = RenderingContext.STATIC_DRAW;
const int STENCIL_ATTACHMENT = RenderingContext.STENCIL_ATTACHMENT;
const int STENCIL_BACK_FAIL = RenderingContext.STENCIL_BACK_FAIL;
const int STENCIL_BACK_FUNC = RenderingContext.STENCIL_BACK_FUNC;
const int STENCIL_BACK_PASS_DEPTH_FAIL = RenderingContext.STENCIL_BACK_PASS_DEPTH_FAIL;
const int STENCIL_BACK_PASS_DEPTH_PASS = RenderingContext.STENCIL_BACK_PASS_DEPTH_PASS;
const int STENCIL_BACK_REF = RenderingContext.STENCIL_BACK_REF;
const int STENCIL_BACK_VALUE_MASK = RenderingContext.STENCIL_BACK_VALUE_MASK;
const int STENCIL_BACK_WRITEMASK = RenderingContext.STENCIL_BACK_WRITEMASK;
const int STENCIL_BITS = RenderingContext.STENCIL_BITS;
const int STENCIL_BUFFER_BIT = RenderingContext.STENCIL_BUFFER_BIT;
const int STENCIL_CLEAR_VALUE = RenderingContext.STENCIL_CLEAR_VALUE;
const int STENCIL_FAIL = RenderingContext.STENCIL_FAIL;
const int STENCIL_FUNC = RenderingContext.STENCIL_FUNC;
const int STENCIL_INDEX = RenderingContext.STENCIL_INDEX;
const int STENCIL_INDEX8 = RenderingContext.STENCIL_INDEX8;
const int STENCIL_PASS_DEPTH_FAIL = RenderingContext.STENCIL_PASS_DEPTH_FAIL;
const int STENCIL_PASS_DEPTH_PASS = RenderingContext.STENCIL_PASS_DEPTH_PASS;
const int STENCIL_REF = RenderingContext.STENCIL_REF;
const int STENCIL_TEST = RenderingContext.STENCIL_TEST;
const int STENCIL_VALUE_MASK = RenderingContext.STENCIL_VALUE_MASK;
const int STENCIL_WRITEMASK = RenderingContext.STENCIL_WRITEMASK;
const int STREAM_DRAW = RenderingContext.STREAM_DRAW;
const int SUBPIXEL_BITS = RenderingContext.SUBPIXEL_BITS;
const int TEXTURE = RenderingContext.TEXTURE;
const int TEXTURE0 = RenderingContext.TEXTURE0;
const int TEXTURE1 = RenderingContext.TEXTURE1;
const int TEXTURE10 = RenderingContext.TEXTURE10;
const int TEXTURE11 = RenderingContext.TEXTURE11;
const int TEXTURE12 = RenderingContext.TEXTURE12;
const int TEXTURE13 = RenderingContext.TEXTURE13;
const int TEXTURE14 = RenderingContext.TEXTURE14;
const int TEXTURE15 = RenderingContext.TEXTURE15;
const int TEXTURE16 = RenderingContext.TEXTURE16;
const int TEXTURE17 = RenderingContext.TEXTURE17;
const int TEXTURE18 = RenderingContext.TEXTURE18;
const int TEXTURE19 = RenderingContext.TEXTURE19;
const int TEXTURE2 = RenderingContext.TEXTURE2;
const int TEXTURE20 = RenderingContext.TEXTURE20;
const int TEXTURE21 = RenderingContext.TEXTURE21;
const int TEXTURE22 = RenderingContext.TEXTURE22;
const int TEXTURE23 = RenderingContext.TEXTURE23;
const int TEXTURE24 = RenderingContext.TEXTURE24;
const int TEXTURE25 = RenderingContext.TEXTURE25;
const int TEXTURE26 = RenderingContext.TEXTURE26;
const int TEXTURE27 = RenderingContext.TEXTURE27;
const int TEXTURE28 = RenderingContext.TEXTURE28;
const int TEXTURE29 = RenderingContext.TEXTURE29;
const int TEXTURE3 = RenderingContext.TEXTURE3;
const int TEXTURE30 = RenderingContext.TEXTURE30;
const int TEXTURE31 = RenderingContext.TEXTURE31;
const int TEXTURE4 = RenderingContext.TEXTURE4;
const int TEXTURE5 = RenderingContext.TEXTURE5;
const int TEXTURE6 = RenderingContext.TEXTURE6;
const int TEXTURE7 = RenderingContext.TEXTURE7;
const int TEXTURE8 = RenderingContext.TEXTURE8;
const int TEXTURE9 = RenderingContext.TEXTURE9;
const int TEXTURE_2D = RenderingContext.TEXTURE_2D;
const int TEXTURE_BINDING_2D = RenderingContext.TEXTURE_BINDING_2D;
const int TEXTURE_BINDING_CUBE_MAP = RenderingContext.TEXTURE_BINDING_CUBE_MAP;
const int TEXTURE_CUBE_MAP = RenderingContext.TEXTURE_CUBE_MAP;
const int TEXTURE_CUBE_MAP_NEGATIVE_X = RenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_X;
const int TEXTURE_CUBE_MAP_NEGATIVE_Y = RenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_Y;
const int TEXTURE_CUBE_MAP_NEGATIVE_Z = RenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_Z;
const int TEXTURE_CUBE_MAP_POSITIVE_X = RenderingContext.TEXTURE_CUBE_MAP_POSITIVE_X;
const int TEXTURE_CUBE_MAP_POSITIVE_Y = RenderingContext.TEXTURE_CUBE_MAP_POSITIVE_Y;
const int TEXTURE_CUBE_MAP_POSITIVE_Z = RenderingContext.TEXTURE_CUBE_MAP_POSITIVE_Z;
const int TEXTURE_MAG_FILTER = RenderingContext.TEXTURE_MAG_FILTER;
const int TEXTURE_MIN_FILTER = RenderingContext.TEXTURE_MIN_FILTER;
const int TEXTURE_WRAP_S = RenderingContext.TEXTURE_WRAP_S;
const int TEXTURE_WRAP_T = RenderingContext.TEXTURE_WRAP_T;
const int TRIANGLES = RenderingContext.TRIANGLES;
const int TRIANGLE_FAN = RenderingContext.TRIANGLE_FAN;
const int TRIANGLE_STRIP = RenderingContext.TRIANGLE_STRIP;
const int UNPACK_ALIGNMENT = RenderingContext.UNPACK_ALIGNMENT;
const int UNPACK_COLORSPACE_CONVERSION_WEBGL = RenderingContext.UNPACK_COLORSPACE_CONVERSION_WEBGL;
const int UNPACK_FLIP_Y_WEBGL = RenderingContext.UNPACK_FLIP_Y_WEBGL;
const int UNPACK_PREMULTIPLY_ALPHA_WEBGL = RenderingContext.UNPACK_PREMULTIPLY_ALPHA_WEBGL;
const int UNSIGNED_BYTE = RenderingContext.UNSIGNED_BYTE;
const int UNSIGNED_INT = RenderingContext.UNSIGNED_INT;
const int UNSIGNED_SHORT = RenderingContext.UNSIGNED_SHORT;
const int UNSIGNED_SHORT_4_4_4_4 = RenderingContext.UNSIGNED_SHORT_4_4_4_4;
const int UNSIGNED_SHORT_5_5_5_1 = RenderingContext.UNSIGNED_SHORT_5_5_5_1;
const int UNSIGNED_SHORT_5_6_5 = RenderingContext.UNSIGNED_SHORT_5_6_5;
const int VALIDATE_STATUS = RenderingContext.VALIDATE_STATUS;
const int VENDOR = RenderingContext.VENDOR;
const int VERSION = RenderingContext.VERSION;
const int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = RenderingContext.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING;
const int VERTEX_ATTRIB_ARRAY_ENABLED = RenderingContext.VERTEX_ATTRIB_ARRAY_ENABLED;
const int VERTEX_ATTRIB_ARRAY_NORMALIZED = RenderingContext.VERTEX_ATTRIB_ARRAY_NORMALIZED;
const int VERTEX_ATTRIB_ARRAY_POINTER = RenderingContext.VERTEX_ATTRIB_ARRAY_POINTER;
const int VERTEX_ATTRIB_ARRAY_SIZE = RenderingContext.VERTEX_ATTRIB_ARRAY_SIZE;
const int VERTEX_ATTRIB_ARRAY_STRIDE = RenderingContext.VERTEX_ATTRIB_ARRAY_STRIDE;
const int VERTEX_ATTRIB_ARRAY_TYPE = RenderingContext.VERTEX_ATTRIB_ARRAY_TYPE;
const int VERTEX_SHADER = RenderingContext.VERTEX_SHADER;
const int VIEWPORT = RenderingContext.VIEWPORT;
const int ZERO = RenderingContext.ZERO;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLActiveInfo')
class ActiveInfo extends NativeFieldWrapperClass1 {
  ActiveInfo.internal();

  @DomName('WebGLActiveInfo.name')
  @DocsEditable
  String get name native "WebGLActiveInfo_name_Getter";

  @DomName('WebGLActiveInfo.size')
  @DocsEditable
  int get size native "WebGLActiveInfo_size_Getter";

  @DomName('WebGLActiveInfo.type')
  @DocsEditable
  int get type native "WebGLActiveInfo_type_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLBuffer')
class Buffer extends NativeFieldWrapperClass1 {
  Buffer.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLCompressedTextureATC')
class CompressedTextureAtc extends NativeFieldWrapperClass1 {
  CompressedTextureAtc.internal();

  static const int COMPRESSED_RGBA_ATC_EXPLICIT_ALPHA_WEBGL = 0x8C93;

  static const int COMPRESSED_RGBA_ATC_INTERPOLATED_ALPHA_WEBGL = 0x87EE;

  static const int COMPRESSED_RGB_ATC_WEBGL = 0x8C92;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLCompressedTexturePVRTC')
class CompressedTexturePvrtc extends NativeFieldWrapperClass1 {
  CompressedTexturePvrtc.internal();

  static const int COMPRESSED_RGBA_PVRTC_2BPPV1_IMG = 0x8C03;

  static const int COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;

  static const int COMPRESSED_RGB_PVRTC_2BPPV1_IMG = 0x8C01;

  static const int COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLCompressedTextureS3TC')
class CompressedTextureS3TC extends NativeFieldWrapperClass1 {
  CompressedTextureS3TC.internal();

  static const int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  static const int COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;

  static const int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  static const int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLContextAttributes')
class ContextAttributes extends NativeFieldWrapperClass1 {
  ContextAttributes.internal();

  @DomName('WebGLContextAttributes.alpha')
  @DocsEditable
  bool get alpha native "WebGLContextAttributes_alpha_Getter";

  @DomName('WebGLContextAttributes.alpha')
  @DocsEditable
  void set alpha(bool value) native "WebGLContextAttributes_alpha_Setter";

  @DomName('WebGLContextAttributes.antialias')
  @DocsEditable
  bool get antialias native "WebGLContextAttributes_antialias_Getter";

  @DomName('WebGLContextAttributes.antialias')
  @DocsEditable
  void set antialias(bool value) native "WebGLContextAttributes_antialias_Setter";

  @DomName('WebGLContextAttributes.depth')
  @DocsEditable
  bool get depth native "WebGLContextAttributes_depth_Getter";

  @DomName('WebGLContextAttributes.depth')
  @DocsEditable
  void set depth(bool value) native "WebGLContextAttributes_depth_Setter";

  @DomName('WebGLContextAttributes.premultipliedAlpha')
  @DocsEditable
  bool get premultipliedAlpha native "WebGLContextAttributes_premultipliedAlpha_Getter";

  @DomName('WebGLContextAttributes.premultipliedAlpha')
  @DocsEditable
  void set premultipliedAlpha(bool value) native "WebGLContextAttributes_premultipliedAlpha_Setter";

  @DomName('WebGLContextAttributes.preserveDrawingBuffer')
  @DocsEditable
  bool get preserveDrawingBuffer native "WebGLContextAttributes_preserveDrawingBuffer_Getter";

  @DomName('WebGLContextAttributes.preserveDrawingBuffer')
  @DocsEditable
  void set preserveDrawingBuffer(bool value) native "WebGLContextAttributes_preserveDrawingBuffer_Setter";

  @DomName('WebGLContextAttributes.stencil')
  @DocsEditable
  bool get stencil native "WebGLContextAttributes_stencil_Getter";

  @DomName('WebGLContextAttributes.stencil')
  @DocsEditable
  void set stencil(bool value) native "WebGLContextAttributes_stencil_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLContextEvent')
class ContextEvent extends Event {
  ContextEvent.internal() : super.internal();

  @DomName('WebGLContextEvent.statusMessage')
  @DocsEditable
  String get statusMessage native "WebGLContextEvent_statusMessage_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLDebugRendererInfo')
class DebugRendererInfo extends NativeFieldWrapperClass1 {
  DebugRendererInfo.internal();

  static const int UNMASKED_RENDERER_WEBGL = 0x9246;

  static const int UNMASKED_VENDOR_WEBGL = 0x9245;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLDebugShaders')
class DebugShaders extends NativeFieldWrapperClass1 {
  DebugShaders.internal();

  @DomName('WebGLDebugShaders.getTranslatedShaderSource')
  @DocsEditable
  String getTranslatedShaderSource(Shader shader) native "WebGLDebugShaders_getTranslatedShaderSource_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLDepthTexture')
class DepthTexture extends NativeFieldWrapperClass1 {
  DepthTexture.internal();

  static const int UNSIGNED_INT_24_8_WEBGL = 0x84FA;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('EXTDrawBuffers')
class ExtDrawBuffers extends NativeFieldWrapperClass1 {
  ExtDrawBuffers.internal();

  static const int COLOR_ATTACHMENT0_EXT = 0x8CE0;

  static const int COLOR_ATTACHMENT10_EXT = 0x8CEA;

  static const int COLOR_ATTACHMENT11_EXT = 0x8CEB;

  static const int COLOR_ATTACHMENT12_EXT = 0x8CEC;

  static const int COLOR_ATTACHMENT13_EXT = 0x8CED;

  static const int COLOR_ATTACHMENT14_EXT = 0x8CEE;

  static const int COLOR_ATTACHMENT15_EXT = 0x8CEF;

  static const int COLOR_ATTACHMENT1_EXT = 0x8CE1;

  static const int COLOR_ATTACHMENT2_EXT = 0x8CE2;

  static const int COLOR_ATTACHMENT3_EXT = 0x8CE3;

  static const int COLOR_ATTACHMENT4_EXT = 0x8CE4;

  static const int COLOR_ATTACHMENT5_EXT = 0x8CE5;

  static const int COLOR_ATTACHMENT6_EXT = 0x8CE6;

  static const int COLOR_ATTACHMENT7_EXT = 0x8CE7;

  static const int COLOR_ATTACHMENT8_EXT = 0x8CE8;

  static const int COLOR_ATTACHMENT9_EXT = 0x8CE9;

  static const int DRAW_BUFFER0_EXT = 0x8825;

  static const int DRAW_BUFFER10_EXT = 0x882F;

  static const int DRAW_BUFFER11_EXT = 0x8830;

  static const int DRAW_BUFFER12_EXT = 0x8831;

  static const int DRAW_BUFFER13_EXT = 0x8832;

  static const int DRAW_BUFFER14_EXT = 0x8833;

  static const int DRAW_BUFFER15_EXT = 0x8834;

  static const int DRAW_BUFFER1_EXT = 0x8826;

  static const int DRAW_BUFFER2_EXT = 0x8827;

  static const int DRAW_BUFFER3_EXT = 0x8828;

  static const int DRAW_BUFFER4_EXT = 0x8829;

  static const int DRAW_BUFFER5_EXT = 0x882A;

  static const int DRAW_BUFFER6_EXT = 0x882B;

  static const int DRAW_BUFFER7_EXT = 0x882C;

  static const int DRAW_BUFFER8_EXT = 0x882D;

  static const int DRAW_BUFFER9_EXT = 0x882E;

  static const int MAX_COLOR_ATTACHMENTS_EXT = 0x8CDF;

  static const int MAX_DRAW_BUFFERS_EXT = 0x8824;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('EXTTextureFilterAnisotropic')
class ExtTextureFilterAnisotropic extends NativeFieldWrapperClass1 {
  ExtTextureFilterAnisotropic.internal();

  static const int MAX_TEXTURE_MAX_ANISOTROPY_EXT = 0x84FF;

  static const int TEXTURE_MAX_ANISOTROPY_EXT = 0x84FE;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLFramebuffer')
class Framebuffer extends NativeFieldWrapperClass1 {
  Framebuffer.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLLoseContext')
class LoseContext extends NativeFieldWrapperClass1 {
  LoseContext.internal();

  @DomName('WebGLLoseContext.loseContext')
  @DocsEditable
  void loseContext() native "WebGLLoseContext_loseContext_Callback";

  @DomName('WebGLLoseContext.restoreContext')
  @DocsEditable
  void restoreContext() native "WebGLLoseContext_restoreContext_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('OESElementIndexUint')
class OesElementIndexUint extends NativeFieldWrapperClass1 {
  OesElementIndexUint.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('OESStandardDerivatives')
class OesStandardDerivatives extends NativeFieldWrapperClass1 {
  OesStandardDerivatives.internal();

  static const int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('OESTextureFloat')
class OesTextureFloat extends NativeFieldWrapperClass1 {
  OesTextureFloat.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('OESTextureHalfFloat')
class OesTextureHalfFloat extends NativeFieldWrapperClass1 {
  OesTextureHalfFloat.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('OESVertexArrayObject')
class OesVertexArrayObject extends NativeFieldWrapperClass1 {
  OesVertexArrayObject.internal();

  static const int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  @DomName('OESVertexArrayObject.bindVertexArrayOES')
  @DocsEditable
  void bindVertexArray(VertexArrayObject arrayObject) native "OESVertexArrayObject_bindVertexArrayOES_Callback";

  @DomName('OESVertexArrayObject.createVertexArrayOES')
  @DocsEditable
  VertexArrayObject createVertexArray() native "OESVertexArrayObject_createVertexArrayOES_Callback";

  @DomName('OESVertexArrayObject.deleteVertexArrayOES')
  @DocsEditable
  void deleteVertexArray(VertexArrayObject arrayObject) native "OESVertexArrayObject_deleteVertexArrayOES_Callback";

  @DomName('OESVertexArrayObject.isVertexArrayOES')
  @DocsEditable
  bool isVertexArray(VertexArrayObject arrayObject) native "OESVertexArrayObject_isVertexArrayOES_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLProgram')
class Program extends NativeFieldWrapperClass1 {
  Program.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLRenderbuffer')
class Renderbuffer extends NativeFieldWrapperClass1 {
  Renderbuffer.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLRenderingContext')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Experimental
class RenderingContext extends CanvasRenderingContext {
  RenderingContext.internal() : super.internal();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  static const int ACTIVE_ATTRIBUTES = 0x8B89;

  static const int ACTIVE_TEXTURE = 0x84E0;

  static const int ACTIVE_UNIFORMS = 0x8B86;

  static const int ALIASED_LINE_WIDTH_RANGE = 0x846E;

  static const int ALIASED_POINT_SIZE_RANGE = 0x846D;

  static const int ALPHA = 0x1906;

  static const int ALPHA_BITS = 0x0D55;

  static const int ALWAYS = 0x0207;

  static const int ARRAY_BUFFER = 0x8892;

  static const int ARRAY_BUFFER_BINDING = 0x8894;

  static const int ATTACHED_SHADERS = 0x8B85;

  static const int BACK = 0x0405;

  static const int BLEND = 0x0BE2;

  static const int BLEND_COLOR = 0x8005;

  static const int BLEND_DST_ALPHA = 0x80CA;

  static const int BLEND_DST_RGB = 0x80C8;

  static const int BLEND_EQUATION = 0x8009;

  static const int BLEND_EQUATION_ALPHA = 0x883D;

  static const int BLEND_EQUATION_RGB = 0x8009;

  static const int BLEND_SRC_ALPHA = 0x80CB;

  static const int BLEND_SRC_RGB = 0x80C9;

  static const int BLUE_BITS = 0x0D54;

  static const int BOOL = 0x8B56;

  static const int BOOL_VEC2 = 0x8B57;

  static const int BOOL_VEC3 = 0x8B58;

  static const int BOOL_VEC4 = 0x8B59;

  static const int BROWSER_DEFAULT_WEBGL = 0x9244;

  static const int BUFFER_SIZE = 0x8764;

  static const int BUFFER_USAGE = 0x8765;

  static const int BYTE = 0x1400;

  static const int CCW = 0x0901;

  static const int CLAMP_TO_EDGE = 0x812F;

  static const int COLOR_ATTACHMENT0 = 0x8CE0;

  static const int COLOR_BUFFER_BIT = 0x00004000;

  static const int COLOR_CLEAR_VALUE = 0x0C22;

  static const int COLOR_WRITEMASK = 0x0C23;

  static const int COMPILE_STATUS = 0x8B81;

  static const int COMPRESSED_TEXTURE_FORMATS = 0x86A3;

  static const int CONSTANT_ALPHA = 0x8003;

  static const int CONSTANT_COLOR = 0x8001;

  static const int CONTEXT_LOST_WEBGL = 0x9242;

  static const int CULL_FACE = 0x0B44;

  static const int CULL_FACE_MODE = 0x0B45;

  static const int CURRENT_PROGRAM = 0x8B8D;

  static const int CURRENT_VERTEX_ATTRIB = 0x8626;

  static const int CW = 0x0900;

  static const int DECR = 0x1E03;

  static const int DECR_WRAP = 0x8508;

  static const int DELETE_STATUS = 0x8B80;

  static const int DEPTH_ATTACHMENT = 0x8D00;

  static const int DEPTH_BITS = 0x0D56;

  static const int DEPTH_BUFFER_BIT = 0x00000100;

  static const int DEPTH_CLEAR_VALUE = 0x0B73;

  static const int DEPTH_COMPONENT = 0x1902;

  static const int DEPTH_COMPONENT16 = 0x81A5;

  static const int DEPTH_FUNC = 0x0B74;

  static const int DEPTH_RANGE = 0x0B70;

  static const int DEPTH_STENCIL = 0x84F9;

  static const int DEPTH_STENCIL_ATTACHMENT = 0x821A;

  static const int DEPTH_TEST = 0x0B71;

  static const int DEPTH_WRITEMASK = 0x0B72;

  static const int DITHER = 0x0BD0;

  static const int DONT_CARE = 0x1100;

  static const int DST_ALPHA = 0x0304;

  static const int DST_COLOR = 0x0306;

  static const int DYNAMIC_DRAW = 0x88E8;

  static const int ELEMENT_ARRAY_BUFFER = 0x8893;

  static const int ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;

  static const int EQUAL = 0x0202;

  static const int FASTEST = 0x1101;

  static const int FLOAT = 0x1406;

  static const int FLOAT_MAT2 = 0x8B5A;

  static const int FLOAT_MAT3 = 0x8B5B;

  static const int FLOAT_MAT4 = 0x8B5C;

  static const int FLOAT_VEC2 = 0x8B50;

  static const int FLOAT_VEC3 = 0x8B51;

  static const int FLOAT_VEC4 = 0x8B52;

  static const int FRAGMENT_SHADER = 0x8B30;

  static const int FRAMEBUFFER = 0x8D40;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;

  static const int FRAMEBUFFER_BINDING = 0x8CA6;

  static const int FRAMEBUFFER_COMPLETE = 0x8CD5;

  static const int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;

  static const int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;

  static const int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;

  static const int FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

  static const int FRONT = 0x0404;

  static const int FRONT_AND_BACK = 0x0408;

  static const int FRONT_FACE = 0x0B46;

  static const int FUNC_ADD = 0x8006;

  static const int FUNC_REVERSE_SUBTRACT = 0x800B;

  static const int FUNC_SUBTRACT = 0x800A;

  static const int GENERATE_MIPMAP_HINT = 0x8192;

  static const int GEQUAL = 0x0206;

  static const int GREATER = 0x0204;

  static const int GREEN_BITS = 0x0D53;

  static const int HALF_FLOAT_OES = 0x8D61;

  static const int HIGH_FLOAT = 0x8DF2;

  static const int HIGH_INT = 0x8DF5;

  static const int INCR = 0x1E02;

  static const int INCR_WRAP = 0x8507;

  static const int INT = 0x1404;

  static const int INT_VEC2 = 0x8B53;

  static const int INT_VEC3 = 0x8B54;

  static const int INT_VEC4 = 0x8B55;

  static const int INVALID_ENUM = 0x0500;

  static const int INVALID_FRAMEBUFFER_OPERATION = 0x0506;

  static const int INVALID_OPERATION = 0x0502;

  static const int INVALID_VALUE = 0x0501;

  static const int INVERT = 0x150A;

  static const int KEEP = 0x1E00;

  static const int LEQUAL = 0x0203;

  static const int LESS = 0x0201;

  static const int LINEAR = 0x2601;

  static const int LINEAR_MIPMAP_LINEAR = 0x2703;

  static const int LINEAR_MIPMAP_NEAREST = 0x2701;

  static const int LINES = 0x0001;

  static const int LINE_LOOP = 0x0002;

  static const int LINE_STRIP = 0x0003;

  static const int LINE_WIDTH = 0x0B21;

  static const int LINK_STATUS = 0x8B82;

  static const int LOW_FLOAT = 0x8DF0;

  static const int LOW_INT = 0x8DF3;

  static const int LUMINANCE = 0x1909;

  static const int LUMINANCE_ALPHA = 0x190A;

  static const int MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;

  static const int MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

  static const int MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;

  static const int MAX_RENDERBUFFER_SIZE = 0x84E8;

  static const int MAX_TEXTURE_IMAGE_UNITS = 0x8872;

  static const int MAX_TEXTURE_SIZE = 0x0D33;

  static const int MAX_VARYING_VECTORS = 0x8DFC;

  static const int MAX_VERTEX_ATTRIBS = 0x8869;

  static const int MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;

  static const int MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;

  static const int MAX_VIEWPORT_DIMS = 0x0D3A;

  static const int MEDIUM_FLOAT = 0x8DF1;

  static const int MEDIUM_INT = 0x8DF4;

  static const int MIRRORED_REPEAT = 0x8370;

  static const int NEAREST = 0x2600;

  static const int NEAREST_MIPMAP_LINEAR = 0x2702;

  static const int NEAREST_MIPMAP_NEAREST = 0x2700;

  static const int NEVER = 0x0200;

  static const int NICEST = 0x1102;

  static const int NONE = 0;

  static const int NOTEQUAL = 0x0205;

  static const int NO_ERROR = 0;

  static const int ONE = 1;

  static const int ONE_MINUS_CONSTANT_ALPHA = 0x8004;

  static const int ONE_MINUS_CONSTANT_COLOR = 0x8002;

  static const int ONE_MINUS_DST_ALPHA = 0x0305;

  static const int ONE_MINUS_DST_COLOR = 0x0307;

  static const int ONE_MINUS_SRC_ALPHA = 0x0303;

  static const int ONE_MINUS_SRC_COLOR = 0x0301;

  static const int OUT_OF_MEMORY = 0x0505;

  static const int PACK_ALIGNMENT = 0x0D05;

  static const int POINTS = 0x0000;

  static const int POLYGON_OFFSET_FACTOR = 0x8038;

  static const int POLYGON_OFFSET_FILL = 0x8037;

  static const int POLYGON_OFFSET_UNITS = 0x2A00;

  static const int RED_BITS = 0x0D52;

  static const int RENDERBUFFER = 0x8D41;

  static const int RENDERBUFFER_ALPHA_SIZE = 0x8D53;

  static const int RENDERBUFFER_BINDING = 0x8CA7;

  static const int RENDERBUFFER_BLUE_SIZE = 0x8D52;

  static const int RENDERBUFFER_DEPTH_SIZE = 0x8D54;

  static const int RENDERBUFFER_GREEN_SIZE = 0x8D51;

  static const int RENDERBUFFER_HEIGHT = 0x8D43;

  static const int RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;

  static const int RENDERBUFFER_RED_SIZE = 0x8D50;

  static const int RENDERBUFFER_STENCIL_SIZE = 0x8D55;

  static const int RENDERBUFFER_WIDTH = 0x8D42;

  static const int RENDERER = 0x1F01;

  static const int REPEAT = 0x2901;

  static const int REPLACE = 0x1E01;

  static const int RGB = 0x1907;

  static const int RGB565 = 0x8D62;

  static const int RGB5_A1 = 0x8057;

  static const int RGBA = 0x1908;

  static const int RGBA4 = 0x8056;

  static const int SAMPLER_2D = 0x8B5E;

  static const int SAMPLER_CUBE = 0x8B60;

  static const int SAMPLES = 0x80A9;

  static const int SAMPLE_ALPHA_TO_COVERAGE = 0x809E;

  static const int SAMPLE_BUFFERS = 0x80A8;

  static const int SAMPLE_COVERAGE = 0x80A0;

  static const int SAMPLE_COVERAGE_INVERT = 0x80AB;

  static const int SAMPLE_COVERAGE_VALUE = 0x80AA;

  static const int SCISSOR_BOX = 0x0C10;

  static const int SCISSOR_TEST = 0x0C11;

  static const int SHADER_TYPE = 0x8B4F;

  static const int SHADING_LANGUAGE_VERSION = 0x8B8C;

  static const int SHORT = 0x1402;

  static const int SRC_ALPHA = 0x0302;

  static const int SRC_ALPHA_SATURATE = 0x0308;

  static const int SRC_COLOR = 0x0300;

  static const int STATIC_DRAW = 0x88E4;

  static const int STENCIL_ATTACHMENT = 0x8D20;

  static const int STENCIL_BACK_FAIL = 0x8801;

  static const int STENCIL_BACK_FUNC = 0x8800;

  static const int STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;

  static const int STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;

  static const int STENCIL_BACK_REF = 0x8CA3;

  static const int STENCIL_BACK_VALUE_MASK = 0x8CA4;

  static const int STENCIL_BACK_WRITEMASK = 0x8CA5;

  static const int STENCIL_BITS = 0x0D57;

  static const int STENCIL_BUFFER_BIT = 0x00000400;

  static const int STENCIL_CLEAR_VALUE = 0x0B91;

  static const int STENCIL_FAIL = 0x0B94;

  static const int STENCIL_FUNC = 0x0B92;

  static const int STENCIL_INDEX = 0x1901;

  static const int STENCIL_INDEX8 = 0x8D48;

  static const int STENCIL_PASS_DEPTH_FAIL = 0x0B95;

  static const int STENCIL_PASS_DEPTH_PASS = 0x0B96;

  static const int STENCIL_REF = 0x0B97;

  static const int STENCIL_TEST = 0x0B90;

  static const int STENCIL_VALUE_MASK = 0x0B93;

  static const int STENCIL_WRITEMASK = 0x0B98;

  static const int STREAM_DRAW = 0x88E0;

  static const int SUBPIXEL_BITS = 0x0D50;

  static const int TEXTURE = 0x1702;

  static const int TEXTURE0 = 0x84C0;

  static const int TEXTURE1 = 0x84C1;

  static const int TEXTURE10 = 0x84CA;

  static const int TEXTURE11 = 0x84CB;

  static const int TEXTURE12 = 0x84CC;

  static const int TEXTURE13 = 0x84CD;

  static const int TEXTURE14 = 0x84CE;

  static const int TEXTURE15 = 0x84CF;

  static const int TEXTURE16 = 0x84D0;

  static const int TEXTURE17 = 0x84D1;

  static const int TEXTURE18 = 0x84D2;

  static const int TEXTURE19 = 0x84D3;

  static const int TEXTURE2 = 0x84C2;

  static const int TEXTURE20 = 0x84D4;

  static const int TEXTURE21 = 0x84D5;

  static const int TEXTURE22 = 0x84D6;

  static const int TEXTURE23 = 0x84D7;

  static const int TEXTURE24 = 0x84D8;

  static const int TEXTURE25 = 0x84D9;

  static const int TEXTURE26 = 0x84DA;

  static const int TEXTURE27 = 0x84DB;

  static const int TEXTURE28 = 0x84DC;

  static const int TEXTURE29 = 0x84DD;

  static const int TEXTURE3 = 0x84C3;

  static const int TEXTURE30 = 0x84DE;

  static const int TEXTURE31 = 0x84DF;

  static const int TEXTURE4 = 0x84C4;

  static const int TEXTURE5 = 0x84C5;

  static const int TEXTURE6 = 0x84C6;

  static const int TEXTURE7 = 0x84C7;

  static const int TEXTURE8 = 0x84C8;

  static const int TEXTURE9 = 0x84C9;

  static const int TEXTURE_2D = 0x0DE1;

  static const int TEXTURE_BINDING_2D = 0x8069;

  static const int TEXTURE_BINDING_CUBE_MAP = 0x8514;

  static const int TEXTURE_CUBE_MAP = 0x8513;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;

  static const int TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;

  static const int TEXTURE_MAG_FILTER = 0x2800;

  static const int TEXTURE_MIN_FILTER = 0x2801;

  static const int TEXTURE_WRAP_S = 0x2802;

  static const int TEXTURE_WRAP_T = 0x2803;

  static const int TRIANGLES = 0x0004;

  static const int TRIANGLE_FAN = 0x0006;

  static const int TRIANGLE_STRIP = 0x0005;

  static const int UNPACK_ALIGNMENT = 0x0CF5;

  static const int UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;

  static const int UNPACK_FLIP_Y_WEBGL = 0x9240;

  static const int UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;

  static const int UNSIGNED_BYTE = 0x1401;

  static const int UNSIGNED_INT = 0x1405;

  static const int UNSIGNED_SHORT = 0x1403;

  static const int UNSIGNED_SHORT_4_4_4_4 = 0x8033;

  static const int UNSIGNED_SHORT_5_5_5_1 = 0x8034;

  static const int UNSIGNED_SHORT_5_6_5 = 0x8363;

  static const int VALIDATE_STATUS = 0x8B83;

  static const int VENDOR = 0x1F00;

  static const int VERSION = 0x1F02;

  static const int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

  static const int VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;

  static const int VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;

  static const int VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;

  static const int VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;

  static const int VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;

  static const int VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;

  static const int VERTEX_SHADER = 0x8B31;

  static const int VIEWPORT = 0x0BA2;

  static const int ZERO = 0;

  @DomName('WebGLRenderingContext.drawingBufferHeight')
  @DocsEditable
  int get drawingBufferHeight native "WebGLRenderingContext_drawingBufferHeight_Getter";

  @DomName('WebGLRenderingContext.drawingBufferWidth')
  @DocsEditable
  int get drawingBufferWidth native "WebGLRenderingContext_drawingBufferWidth_Getter";

  @DomName('WebGLRenderingContext.activeTexture')
  @DocsEditable
  void activeTexture(int texture) native "WebGLRenderingContext_activeTexture_Callback";

  @DomName('WebGLRenderingContext.attachShader')
  @DocsEditable
  void attachShader(Program program, Shader shader) native "WebGLRenderingContext_attachShader_Callback";

  @DomName('WebGLRenderingContext.bindAttribLocation')
  @DocsEditable
  void bindAttribLocation(Program program, int index, String name) native "WebGLRenderingContext_bindAttribLocation_Callback";

  @DomName('WebGLRenderingContext.bindBuffer')
  @DocsEditable
  void bindBuffer(int target, Buffer buffer) native "WebGLRenderingContext_bindBuffer_Callback";

  @DomName('WebGLRenderingContext.bindFramebuffer')
  @DocsEditable
  void bindFramebuffer(int target, Framebuffer framebuffer) native "WebGLRenderingContext_bindFramebuffer_Callback";

  @DomName('WebGLRenderingContext.bindRenderbuffer')
  @DocsEditable
  void bindRenderbuffer(int target, Renderbuffer renderbuffer) native "WebGLRenderingContext_bindRenderbuffer_Callback";

  @DomName('WebGLRenderingContext.bindTexture')
  @DocsEditable
  void bindTexture(int target, Texture texture) native "WebGLRenderingContext_bindTexture_Callback";

  @DomName('WebGLRenderingContext.blendColor')
  @DocsEditable
  void blendColor(num red, num green, num blue, num alpha) native "WebGLRenderingContext_blendColor_Callback";

  @DomName('WebGLRenderingContext.blendEquation')
  @DocsEditable
  void blendEquation(int mode) native "WebGLRenderingContext_blendEquation_Callback";

  @DomName('WebGLRenderingContext.blendEquationSeparate')
  @DocsEditable
  void blendEquationSeparate(int modeRGB, int modeAlpha) native "WebGLRenderingContext_blendEquationSeparate_Callback";

  @DomName('WebGLRenderingContext.blendFunc')
  @DocsEditable
  void blendFunc(int sfactor, int dfactor) native "WebGLRenderingContext_blendFunc_Callback";

  @DomName('WebGLRenderingContext.blendFuncSeparate')
  @DocsEditable
  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) native "WebGLRenderingContext_blendFuncSeparate_Callback";

  void bufferData(int target, data_OR_size, int usage) {
    if ((target is int || target == null) && (data_OR_size is ArrayBufferView || data_OR_size is _typeddata.TypedData || data_OR_size == null) && (usage is int || usage == null)) {
      _bufferData_1(target, data_OR_size, usage);
      return;
    }
    if ((target is int || target == null) && (data_OR_size is ArrayBuffer || data_OR_size is _typeddata.ByteBuffer || data_OR_size == null) && (usage is int || usage == null)) {
      _bufferData_2(target, data_OR_size, usage);
      return;
    }
    if ((target is int || target == null) && (data_OR_size is int || data_OR_size == null) && (usage is int || usage == null)) {
      _bufferData_3(target, data_OR_size, usage);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContext._bufferData_1')
  @DocsEditable
  void _bufferData_1(target, data_OR_size, usage) native "WebGLRenderingContext__bufferData_1_Callback";

  @DomName('WebGLRenderingContext._bufferData_2')
  @DocsEditable
  void _bufferData_2(target, data_OR_size, usage) native "WebGLRenderingContext__bufferData_2_Callback";

  @DomName('WebGLRenderingContext._bufferData_3')
  @DocsEditable
  void _bufferData_3(target, data_OR_size, usage) native "WebGLRenderingContext__bufferData_3_Callback";

  void bufferSubData(int target, int offset, /*ArrayBuffer*/ data) {
    if ((target is int || target == null) && (offset is int || offset == null) && (data is ArrayBufferView || data is _typeddata.TypedData || data == null)) {
      _bufferSubData_1(target, offset, data);
      return;
    }
    if ((target is int || target == null) && (offset is int || offset == null) && (data is ArrayBuffer || data is _typeddata.ByteBuffer || data == null)) {
      _bufferSubData_2(target, offset, data);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContext._bufferSubData_1')
  @DocsEditable
  void _bufferSubData_1(target, offset, data) native "WebGLRenderingContext__bufferSubData_1_Callback";

  @DomName('WebGLRenderingContext._bufferSubData_2')
  @DocsEditable
  void _bufferSubData_2(target, offset, data) native "WebGLRenderingContext__bufferSubData_2_Callback";

  @DomName('WebGLRenderingContext.checkFramebufferStatus')
  @DocsEditable
  int checkFramebufferStatus(int target) native "WebGLRenderingContext_checkFramebufferStatus_Callback";

  @DomName('WebGLRenderingContext.clear')
  @DocsEditable
  void clear(int mask) native "WebGLRenderingContext_clear_Callback";

  @DomName('WebGLRenderingContext.clearColor')
  @DocsEditable
  void clearColor(num red, num green, num blue, num alpha) native "WebGLRenderingContext_clearColor_Callback";

  @DomName('WebGLRenderingContext.clearDepth')
  @DocsEditable
  void clearDepth(num depth) native "WebGLRenderingContext_clearDepth_Callback";

  @DomName('WebGLRenderingContext.clearStencil')
  @DocsEditable
  void clearStencil(int s) native "WebGLRenderingContext_clearStencil_Callback";

  @DomName('WebGLRenderingContext.colorMask')
  @DocsEditable
  void colorMask(bool red, bool green, bool blue, bool alpha) native "WebGLRenderingContext_colorMask_Callback";

  @DomName('WebGLRenderingContext.compileShader')
  @DocsEditable
  void compileShader(Shader shader) native "WebGLRenderingContext_compileShader_Callback";

  @DomName('WebGLRenderingContext.compressedTexImage2D')
  @DocsEditable
  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, /*ArrayBufferView*/ data) native "WebGLRenderingContext_compressedTexImage2D_Callback";

  @DomName('WebGLRenderingContext.compressedTexSubImage2D')
  @DocsEditable
  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, /*ArrayBufferView*/ data) native "WebGLRenderingContext_compressedTexSubImage2D_Callback";

  @DomName('WebGLRenderingContext.copyTexImage2D')
  @DocsEditable
  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) native "WebGLRenderingContext_copyTexImage2D_Callback";

  @DomName('WebGLRenderingContext.copyTexSubImage2D')
  @DocsEditable
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) native "WebGLRenderingContext_copyTexSubImage2D_Callback";

  @DomName('WebGLRenderingContext.createBuffer')
  @DocsEditable
  Buffer createBuffer() native "WebGLRenderingContext_createBuffer_Callback";

  @DomName('WebGLRenderingContext.createFramebuffer')
  @DocsEditable
  Framebuffer createFramebuffer() native "WebGLRenderingContext_createFramebuffer_Callback";

  @DomName('WebGLRenderingContext.createProgram')
  @DocsEditable
  Program createProgram() native "WebGLRenderingContext_createProgram_Callback";

  @DomName('WebGLRenderingContext.createRenderbuffer')
  @DocsEditable
  Renderbuffer createRenderbuffer() native "WebGLRenderingContext_createRenderbuffer_Callback";

  @DomName('WebGLRenderingContext.createShader')
  @DocsEditable
  Shader createShader(int type) native "WebGLRenderingContext_createShader_Callback";

  @DomName('WebGLRenderingContext.createTexture')
  @DocsEditable
  Texture createTexture() native "WebGLRenderingContext_createTexture_Callback";

  @DomName('WebGLRenderingContext.cullFace')
  @DocsEditable
  void cullFace(int mode) native "WebGLRenderingContext_cullFace_Callback";

  @DomName('WebGLRenderingContext.deleteBuffer')
  @DocsEditable
  void deleteBuffer(Buffer buffer) native "WebGLRenderingContext_deleteBuffer_Callback";

  @DomName('WebGLRenderingContext.deleteFramebuffer')
  @DocsEditable
  void deleteFramebuffer(Framebuffer framebuffer) native "WebGLRenderingContext_deleteFramebuffer_Callback";

  @DomName('WebGLRenderingContext.deleteProgram')
  @DocsEditable
  void deleteProgram(Program program) native "WebGLRenderingContext_deleteProgram_Callback";

  @DomName('WebGLRenderingContext.deleteRenderbuffer')
  @DocsEditable
  void deleteRenderbuffer(Renderbuffer renderbuffer) native "WebGLRenderingContext_deleteRenderbuffer_Callback";

  @DomName('WebGLRenderingContext.deleteShader')
  @DocsEditable
  void deleteShader(Shader shader) native "WebGLRenderingContext_deleteShader_Callback";

  @DomName('WebGLRenderingContext.deleteTexture')
  @DocsEditable
  void deleteTexture(Texture texture) native "WebGLRenderingContext_deleteTexture_Callback";

  @DomName('WebGLRenderingContext.depthFunc')
  @DocsEditable
  void depthFunc(int func) native "WebGLRenderingContext_depthFunc_Callback";

  @DomName('WebGLRenderingContext.depthMask')
  @DocsEditable
  void depthMask(bool flag) native "WebGLRenderingContext_depthMask_Callback";

  @DomName('WebGLRenderingContext.depthRange')
  @DocsEditable
  void depthRange(num zNear, num zFar) native "WebGLRenderingContext_depthRange_Callback";

  @DomName('WebGLRenderingContext.detachShader')
  @DocsEditable
  void detachShader(Program program, Shader shader) native "WebGLRenderingContext_detachShader_Callback";

  @DomName('WebGLRenderingContext.disable')
  @DocsEditable
  void disable(int cap) native "WebGLRenderingContext_disable_Callback";

  @DomName('WebGLRenderingContext.disableVertexAttribArray')
  @DocsEditable
  void disableVertexAttribArray(int index) native "WebGLRenderingContext_disableVertexAttribArray_Callback";

  @DomName('WebGLRenderingContext.drawArrays')
  @DocsEditable
  void drawArrays(int mode, int first, int count) native "WebGLRenderingContext_drawArrays_Callback";

  @DomName('WebGLRenderingContext.drawElements')
  @DocsEditable
  void drawElements(int mode, int count, int type, int offset) native "WebGLRenderingContext_drawElements_Callback";

  @DomName('WebGLRenderingContext.enable')
  @DocsEditable
  void enable(int cap) native "WebGLRenderingContext_enable_Callback";

  @DomName('WebGLRenderingContext.enableVertexAttribArray')
  @DocsEditable
  void enableVertexAttribArray(int index) native "WebGLRenderingContext_enableVertexAttribArray_Callback";

  @DomName('WebGLRenderingContext.finish')
  @DocsEditable
  void finish() native "WebGLRenderingContext_finish_Callback";

  @DomName('WebGLRenderingContext.flush')
  @DocsEditable
  void flush() native "WebGLRenderingContext_flush_Callback";

  @DomName('WebGLRenderingContext.framebufferRenderbuffer')
  @DocsEditable
  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, Renderbuffer renderbuffer) native "WebGLRenderingContext_framebufferRenderbuffer_Callback";

  @DomName('WebGLRenderingContext.framebufferTexture2D')
  @DocsEditable
  void framebufferTexture2D(int target, int attachment, int textarget, Texture texture, int level) native "WebGLRenderingContext_framebufferTexture2D_Callback";

  @DomName('WebGLRenderingContext.frontFace')
  @DocsEditable
  void frontFace(int mode) native "WebGLRenderingContext_frontFace_Callback";

  @DomName('WebGLRenderingContext.generateMipmap')
  @DocsEditable
  void generateMipmap(int target) native "WebGLRenderingContext_generateMipmap_Callback";

  @DomName('WebGLRenderingContext.getActiveAttrib')
  @DocsEditable
  ActiveInfo getActiveAttrib(Program program, int index) native "WebGLRenderingContext_getActiveAttrib_Callback";

  @DomName('WebGLRenderingContext.getActiveUniform')
  @DocsEditable
  ActiveInfo getActiveUniform(Program program, int index) native "WebGLRenderingContext_getActiveUniform_Callback";

  @DomName('WebGLRenderingContext.getAttachedShaders')
  @DocsEditable
  void getAttachedShaders(Program program) native "WebGLRenderingContext_getAttachedShaders_Callback";

  @DomName('WebGLRenderingContext.getAttribLocation')
  @DocsEditable
  int getAttribLocation(Program program, String name) native "WebGLRenderingContext_getAttribLocation_Callback";

  @DomName('WebGLRenderingContext.getBufferParameter')
  @DocsEditable
  Object getBufferParameter(int target, int pname) native "WebGLRenderingContext_getBufferParameter_Callback";

  @DomName('WebGLRenderingContext.getContextAttributes')
  @DocsEditable
  ContextAttributes getContextAttributes() native "WebGLRenderingContext_getContextAttributes_Callback";

  @DomName('WebGLRenderingContext.getError')
  @DocsEditable
  int getError() native "WebGLRenderingContext_getError_Callback";

  @DomName('WebGLRenderingContext.getExtension')
  @DocsEditable
  Object getExtension(String name) native "WebGLRenderingContext_getExtension_Callback";

  @DomName('WebGLRenderingContext.getFramebufferAttachmentParameter')
  @DocsEditable
  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) native "WebGLRenderingContext_getFramebufferAttachmentParameter_Callback";

  @DomName('WebGLRenderingContext.getParameter')
  @DocsEditable
  Object getParameter(int pname) native "WebGLRenderingContext_getParameter_Callback";

  @DomName('WebGLRenderingContext.getProgramInfoLog')
  @DocsEditable
  String getProgramInfoLog(Program program) native "WebGLRenderingContext_getProgramInfoLog_Callback";

  @DomName('WebGLRenderingContext.getProgramParameter')
  @DocsEditable
  Object getProgramParameter(Program program, int pname) native "WebGLRenderingContext_getProgramParameter_Callback";

  @DomName('WebGLRenderingContext.getRenderbufferParameter')
  @DocsEditable
  Object getRenderbufferParameter(int target, int pname) native "WebGLRenderingContext_getRenderbufferParameter_Callback";

  @DomName('WebGLRenderingContext.getShaderInfoLog')
  @DocsEditable
  String getShaderInfoLog(Shader shader) native "WebGLRenderingContext_getShaderInfoLog_Callback";

  @DomName('WebGLRenderingContext.getShaderParameter')
  @DocsEditable
  Object getShaderParameter(Shader shader, int pname) native "WebGLRenderingContext_getShaderParameter_Callback";

  @DomName('WebGLRenderingContext.getShaderPrecisionFormat')
  @DocsEditable
  ShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype) native "WebGLRenderingContext_getShaderPrecisionFormat_Callback";

  @DomName('WebGLRenderingContext.getShaderSource')
  @DocsEditable
  String getShaderSource(Shader shader) native "WebGLRenderingContext_getShaderSource_Callback";

  @DomName('WebGLRenderingContext.getSupportedExtensions')
  @DocsEditable
  List<String> getSupportedExtensions() native "WebGLRenderingContext_getSupportedExtensions_Callback";

  @DomName('WebGLRenderingContext.getTexParameter')
  @DocsEditable
  Object getTexParameter(int target, int pname) native "WebGLRenderingContext_getTexParameter_Callback";

  @DomName('WebGLRenderingContext.getUniform')
  @DocsEditable
  Object getUniform(Program program, UniformLocation location) native "WebGLRenderingContext_getUniform_Callback";

  @DomName('WebGLRenderingContext.getUniformLocation')
  @DocsEditable
  UniformLocation getUniformLocation(Program program, String name) native "WebGLRenderingContext_getUniformLocation_Callback";

  @DomName('WebGLRenderingContext.getVertexAttrib')
  @DocsEditable
  Object getVertexAttrib(int index, int pname) native "WebGLRenderingContext_getVertexAttrib_Callback";

  @DomName('WebGLRenderingContext.getVertexAttribOffset')
  @DocsEditable
  int getVertexAttribOffset(int index, int pname) native "WebGLRenderingContext_getVertexAttribOffset_Callback";

  @DomName('WebGLRenderingContext.hint')
  @DocsEditable
  void hint(int target, int mode) native "WebGLRenderingContext_hint_Callback";

  @DomName('WebGLRenderingContext.isBuffer')
  @DocsEditable
  bool isBuffer(Buffer buffer) native "WebGLRenderingContext_isBuffer_Callback";

  @DomName('WebGLRenderingContext.isContextLost')
  @DocsEditable
  bool isContextLost() native "WebGLRenderingContext_isContextLost_Callback";

  @DomName('WebGLRenderingContext.isEnabled')
  @DocsEditable
  bool isEnabled(int cap) native "WebGLRenderingContext_isEnabled_Callback";

  @DomName('WebGLRenderingContext.isFramebuffer')
  @DocsEditable
  bool isFramebuffer(Framebuffer framebuffer) native "WebGLRenderingContext_isFramebuffer_Callback";

  @DomName('WebGLRenderingContext.isProgram')
  @DocsEditable
  bool isProgram(Program program) native "WebGLRenderingContext_isProgram_Callback";

  @DomName('WebGLRenderingContext.isRenderbuffer')
  @DocsEditable
  bool isRenderbuffer(Renderbuffer renderbuffer) native "WebGLRenderingContext_isRenderbuffer_Callback";

  @DomName('WebGLRenderingContext.isShader')
  @DocsEditable
  bool isShader(Shader shader) native "WebGLRenderingContext_isShader_Callback";

  @DomName('WebGLRenderingContext.isTexture')
  @DocsEditable
  bool isTexture(Texture texture) native "WebGLRenderingContext_isTexture_Callback";

  @DomName('WebGLRenderingContext.lineWidth')
  @DocsEditable
  void lineWidth(num width) native "WebGLRenderingContext_lineWidth_Callback";

  @DomName('WebGLRenderingContext.linkProgram')
  @DocsEditable
  void linkProgram(Program program) native "WebGLRenderingContext_linkProgram_Callback";

  @DomName('WebGLRenderingContext.pixelStorei')
  @DocsEditable
  void pixelStorei(int pname, int param) native "WebGLRenderingContext_pixelStorei_Callback";

  @DomName('WebGLRenderingContext.polygonOffset')
  @DocsEditable
  void polygonOffset(num factor, num units) native "WebGLRenderingContext_polygonOffset_Callback";

  @DomName('WebGLRenderingContext.readPixels')
  @DocsEditable
  void readPixels(int x, int y, int width, int height, int format, int type, /*ArrayBufferView*/ pixels) native "WebGLRenderingContext_readPixels_Callback";

  @DomName('WebGLRenderingContext.releaseShaderCompiler')
  @DocsEditable
  void releaseShaderCompiler() native "WebGLRenderingContext_releaseShaderCompiler_Callback";

  @DomName('WebGLRenderingContext.renderbufferStorage')
  @DocsEditable
  void renderbufferStorage(int target, int internalformat, int width, int height) native "WebGLRenderingContext_renderbufferStorage_Callback";

  @DomName('WebGLRenderingContext.sampleCoverage')
  @DocsEditable
  void sampleCoverage(num value, bool invert) native "WebGLRenderingContext_sampleCoverage_Callback";

  @DomName('WebGLRenderingContext.scissor')
  @DocsEditable
  void scissor(int x, int y, int width, int height) native "WebGLRenderingContext_scissor_Callback";

  @DomName('WebGLRenderingContext.shaderSource')
  @DocsEditable
  void shaderSource(Shader shader, String string) native "WebGLRenderingContext_shaderSource_Callback";

  @DomName('WebGLRenderingContext.stencilFunc')
  @DocsEditable
  void stencilFunc(int func, int ref, int mask) native "WebGLRenderingContext_stencilFunc_Callback";

  @DomName('WebGLRenderingContext.stencilFuncSeparate')
  @DocsEditable
  void stencilFuncSeparate(int face, int func, int ref, int mask) native "WebGLRenderingContext_stencilFuncSeparate_Callback";

  @DomName('WebGLRenderingContext.stencilMask')
  @DocsEditable
  void stencilMask(int mask) native "WebGLRenderingContext_stencilMask_Callback";

  @DomName('WebGLRenderingContext.stencilMaskSeparate')
  @DocsEditable
  void stencilMaskSeparate(int face, int mask) native "WebGLRenderingContext_stencilMaskSeparate_Callback";

  @DomName('WebGLRenderingContext.stencilOp')
  @DocsEditable
  void stencilOp(int fail, int zfail, int zpass) native "WebGLRenderingContext_stencilOp_Callback";

  @DomName('WebGLRenderingContext.stencilOpSeparate')
  @DocsEditable
  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native "WebGLRenderingContext_stencilOpSeparate_Callback";

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, [int format, int type, /*ArrayBufferView*/ pixels]) {
    if ((target is int || target == null) && (level is int || level == null) && (internalformat is int || internalformat == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is int || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (format is int || format == null) && (type is int || type == null) && (pixels is ArrayBufferView || pixels is _typeddata.TypedData || pixels == null)) {
      _texImage2D_1(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (internalformat is int || internalformat == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_2(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (internalformat is int || internalformat == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_3(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (internalformat is int || internalformat == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_4(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (internalformat is int || internalformat == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_5(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContext._texImage2D_1')
  @DocsEditable
  void _texImage2D_1(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels) native "WebGLRenderingContext__texImage2D_1_Callback";

  @DomName('WebGLRenderingContext._texImage2D_2')
  @DocsEditable
  void _texImage2D_2(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext__texImage2D_2_Callback";

  @DomName('WebGLRenderingContext._texImage2D_3')
  @DocsEditable
  void _texImage2D_3(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext__texImage2D_3_Callback";

  @DomName('WebGLRenderingContext._texImage2D_4')
  @DocsEditable
  void _texImage2D_4(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext__texImage2D_4_Callback";

  @DomName('WebGLRenderingContext._texImage2D_5')
  @DocsEditable
  void _texImage2D_5(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext__texImage2D_5_Callback";

  @DomName('WebGLRenderingContext.texParameterf')
  @DocsEditable
  void texParameterf(int target, int pname, num param) native "WebGLRenderingContext_texParameterf_Callback";

  @DomName('WebGLRenderingContext.texParameteri')
  @DocsEditable
  void texParameteri(int target, int pname, int param) native "WebGLRenderingContext_texParameteri_Callback";

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, [int type, /*ArrayBufferView*/ pixels]) {
    if ((target is int || target == null) && (level is int || level == null) && (xoffset is int || xoffset == null) && (yoffset is int || yoffset == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is int || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (type is int || type == null) && (pixels is ArrayBufferView || pixels is _typeddata.TypedData || pixels == null)) {
      _texSubImage2D_1(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (xoffset is int || xoffset == null) && (yoffset is int || yoffset == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (xoffset is int || xoffset == null) && (yoffset is int || yoffset == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_3(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (xoffset is int || xoffset == null) && (yoffset is int || yoffset == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_4(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (xoffset is int || xoffset == null) && (yoffset is int || yoffset == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_5(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('WebGLRenderingContext._texSubImage2D_1')
  @DocsEditable
  void _texSubImage2D_1(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels) native "WebGLRenderingContext__texSubImage2D_1_Callback";

  @DomName('WebGLRenderingContext._texSubImage2D_2')
  @DocsEditable
  void _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext__texSubImage2D_2_Callback";

  @DomName('WebGLRenderingContext._texSubImage2D_3')
  @DocsEditable
  void _texSubImage2D_3(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext__texSubImage2D_3_Callback";

  @DomName('WebGLRenderingContext._texSubImage2D_4')
  @DocsEditable
  void _texSubImage2D_4(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext__texSubImage2D_4_Callback";

  @DomName('WebGLRenderingContext._texSubImage2D_5')
  @DocsEditable
  void _texSubImage2D_5(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext__texSubImage2D_5_Callback";

  @DomName('WebGLRenderingContext.uniform1f')
  @DocsEditable
  void uniform1f(UniformLocation location, num x) native "WebGLRenderingContext_uniform1f_Callback";

  @DomName('WebGLRenderingContext.uniform1fv')
  @DocsEditable
  void uniform1fv(UniformLocation location, List<double> v) native "WebGLRenderingContext_uniform1fv_Callback";

  @DomName('WebGLRenderingContext.uniform1i')
  @DocsEditable
  void uniform1i(UniformLocation location, int x) native "WebGLRenderingContext_uniform1i_Callback";

  @DomName('WebGLRenderingContext.uniform1iv')
  @DocsEditable
  void uniform1iv(UniformLocation location, List<int> v) native "WebGLRenderingContext_uniform1iv_Callback";

  @DomName('WebGLRenderingContext.uniform2f')
  @DocsEditable
  void uniform2f(UniformLocation location, num x, num y) native "WebGLRenderingContext_uniform2f_Callback";

  @DomName('WebGLRenderingContext.uniform2fv')
  @DocsEditable
  void uniform2fv(UniformLocation location, List<double> v) native "WebGLRenderingContext_uniform2fv_Callback";

  @DomName('WebGLRenderingContext.uniform2i')
  @DocsEditable
  void uniform2i(UniformLocation location, int x, int y) native "WebGLRenderingContext_uniform2i_Callback";

  @DomName('WebGLRenderingContext.uniform2iv')
  @DocsEditable
  void uniform2iv(UniformLocation location, List<int> v) native "WebGLRenderingContext_uniform2iv_Callback";

  @DomName('WebGLRenderingContext.uniform3f')
  @DocsEditable
  void uniform3f(UniformLocation location, num x, num y, num z) native "WebGLRenderingContext_uniform3f_Callback";

  @DomName('WebGLRenderingContext.uniform3fv')
  @DocsEditable
  void uniform3fv(UniformLocation location, List<double> v) native "WebGLRenderingContext_uniform3fv_Callback";

  @DomName('WebGLRenderingContext.uniform3i')
  @DocsEditable
  void uniform3i(UniformLocation location, int x, int y, int z) native "WebGLRenderingContext_uniform3i_Callback";

  @DomName('WebGLRenderingContext.uniform3iv')
  @DocsEditable
  void uniform3iv(UniformLocation location, List<int> v) native "WebGLRenderingContext_uniform3iv_Callback";

  @DomName('WebGLRenderingContext.uniform4f')
  @DocsEditable
  void uniform4f(UniformLocation location, num x, num y, num z, num w) native "WebGLRenderingContext_uniform4f_Callback";

  @DomName('WebGLRenderingContext.uniform4fv')
  @DocsEditable
  void uniform4fv(UniformLocation location, List<double> v) native "WebGLRenderingContext_uniform4fv_Callback";

  @DomName('WebGLRenderingContext.uniform4i')
  @DocsEditable
  void uniform4i(UniformLocation location, int x, int y, int z, int w) native "WebGLRenderingContext_uniform4i_Callback";

  @DomName('WebGLRenderingContext.uniform4iv')
  @DocsEditable
  void uniform4iv(UniformLocation location, List<int> v) native "WebGLRenderingContext_uniform4iv_Callback";

  @DomName('WebGLRenderingContext.uniformMatrix2fv')
  @DocsEditable
  void uniformMatrix2fv(UniformLocation location, bool transpose, List<double> array) native "WebGLRenderingContext_uniformMatrix2fv_Callback";

  @DomName('WebGLRenderingContext.uniformMatrix3fv')
  @DocsEditable
  void uniformMatrix3fv(UniformLocation location, bool transpose, List<double> array) native "WebGLRenderingContext_uniformMatrix3fv_Callback";

  @DomName('WebGLRenderingContext.uniformMatrix4fv')
  @DocsEditable
  void uniformMatrix4fv(UniformLocation location, bool transpose, List<double> array) native "WebGLRenderingContext_uniformMatrix4fv_Callback";

  @DomName('WebGLRenderingContext.useProgram')
  @DocsEditable
  void useProgram(Program program) native "WebGLRenderingContext_useProgram_Callback";

  @DomName('WebGLRenderingContext.validateProgram')
  @DocsEditable
  void validateProgram(Program program) native "WebGLRenderingContext_validateProgram_Callback";

  @DomName('WebGLRenderingContext.vertexAttrib1f')
  @DocsEditable
  void vertexAttrib1f(int indx, num x) native "WebGLRenderingContext_vertexAttrib1f_Callback";

  @DomName('WebGLRenderingContext.vertexAttrib1fv')
  @DocsEditable
  void vertexAttrib1fv(int indx, List<double> values) native "WebGLRenderingContext_vertexAttrib1fv_Callback";

  @DomName('WebGLRenderingContext.vertexAttrib2f')
  @DocsEditable
  void vertexAttrib2f(int indx, num x, num y) native "WebGLRenderingContext_vertexAttrib2f_Callback";

  @DomName('WebGLRenderingContext.vertexAttrib2fv')
  @DocsEditable
  void vertexAttrib2fv(int indx, List<double> values) native "WebGLRenderingContext_vertexAttrib2fv_Callback";

  @DomName('WebGLRenderingContext.vertexAttrib3f')
  @DocsEditable
  void vertexAttrib3f(int indx, num x, num y, num z) native "WebGLRenderingContext_vertexAttrib3f_Callback";

  @DomName('WebGLRenderingContext.vertexAttrib3fv')
  @DocsEditable
  void vertexAttrib3fv(int indx, List<double> values) native "WebGLRenderingContext_vertexAttrib3fv_Callback";

  @DomName('WebGLRenderingContext.vertexAttrib4f')
  @DocsEditable
  void vertexAttrib4f(int indx, num x, num y, num z, num w) native "WebGLRenderingContext_vertexAttrib4f_Callback";

  @DomName('WebGLRenderingContext.vertexAttrib4fv')
  @DocsEditable
  void vertexAttrib4fv(int indx, List<double> values) native "WebGLRenderingContext_vertexAttrib4fv_Callback";

  @DomName('WebGLRenderingContext.vertexAttribPointer')
  @DocsEditable
  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) native "WebGLRenderingContext_vertexAttribPointer_Callback";

  @DomName('WebGLRenderingContext.viewport')
  @DocsEditable
  void viewport(int x, int y, int width, int height) native "WebGLRenderingContext_viewport_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLShader')
class Shader extends NativeFieldWrapperClass1 {
  Shader.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLShaderPrecisionFormat')
class ShaderPrecisionFormat extends NativeFieldWrapperClass1 {
  ShaderPrecisionFormat.internal();

  @DomName('WebGLShaderPrecisionFormat.precision')
  @DocsEditable
  int get precision native "WebGLShaderPrecisionFormat_precision_Getter";

  @DomName('WebGLShaderPrecisionFormat.rangeMax')
  @DocsEditable
  int get rangeMax native "WebGLShaderPrecisionFormat_rangeMax_Getter";

  @DomName('WebGLShaderPrecisionFormat.rangeMin')
  @DocsEditable
  int get rangeMin native "WebGLShaderPrecisionFormat_rangeMin_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLTexture')
class Texture extends NativeFieldWrapperClass1 {
  Texture.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLUniformLocation')
class UniformLocation extends NativeFieldWrapperClass1 {
  UniformLocation.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WebGLVertexArrayObjectOES')
class VertexArrayObject extends NativeFieldWrapperClass1 {
  VertexArrayObject.internal();

}
