/**
 * 3D programming in the browser.
 *
 * {@category Web}
 */
library dart.dom.web_gl;

import 'dart:async';
import 'dart:collection' hide LinkedList, LinkedListEntry;
import 'dart:_internal' show FixedLengthListMixin;
import 'dart:html';
import 'dart:html_common';
import 'dart:_native_typed_data';
import 'dart:typed_data';
import 'dart:_js_helper'
    show Creates, JSName, Native, Returns, convertDartClosureToJS;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show Interceptor, JSExtendableArray;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:web_gl library.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLActiveInfo')
@Unstable()
@Native("WebGLActiveInfo")
class ActiveInfo extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ActiveInfo._() {
    throw new UnsupportedError("Not supported");
  }

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
@Native("ANGLEInstancedArrays,ANGLE_instanced_arrays")
class AngleInstancedArrays extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AngleInstancedArrays._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('ANGLEInstancedArrays.VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE = 0x88FE;

  @JSName('drawArraysInstancedANGLE')
  @DomName('ANGLEInstancedArrays.drawArraysInstancedANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  void drawArraysInstancedAngle(int mode, int first, int count, int primcount)
      native;

  @JSName('drawElementsInstancedANGLE')
  @DomName('ANGLEInstancedArrays.drawElementsInstancedANGLE')
  @DocsEditable()
  @Experimental() // untriaged
  void drawElementsInstancedAngle(
      int mode, int count, int type, int offset, int primcount) native;

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
  factory Buffer._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLCanvas')
@Experimental() // untriaged
@Native("WebGLCanvas")
class Canvas extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Canvas._() {
    throw new UnsupportedError("Not supported");
  }

  @JSName('canvas')
  @DomName('WebGLCanvas.canvas')
  @DocsEditable()
  final CanvasElement canvas;

  @JSName('canvas')
  @DomName('WebGLCanvas.offscreenCanvas')
  @DocsEditable()
  final OffscreenCanvas offscreenCanvas;
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLColorBufferFloat')
@Experimental() // untriaged
@Native("WebGLColorBufferFloat")
class ColorBufferFloat extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ColorBufferFloat._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLCompressedTextureASTC')
@Experimental() // untriaged
@Native("WebGLCompressedTextureASTC")
class CompressedTextureAstc extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureAstc._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_10x10_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_10x10_KHR = 0x93BB;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_10x5_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_10x5_KHR = 0x93B8;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_10x6_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_10x6_KHR = 0x93B9;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_10x8_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_10x8_KHR = 0x93BA;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_12x10_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_12x10_KHR = 0x93BC;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_12x12_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_12x12_KHR = 0x93BD;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_4x4_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_4x4_KHR = 0x93B0;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_5x4_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_5x4_KHR = 0x93B1;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_5x5_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_5x5_KHR = 0x93B2;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_6x5_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_6x5_KHR = 0x93B3;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_6x6_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_6x6_KHR = 0x93B4;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_8x5_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_8x5_KHR = 0x93B5;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_8x6_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_8x6_KHR = 0x93B6;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_RGBA_ASTC_8x8_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA_ASTC_8x8_KHR = 0x93B7;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR = 0x93DB;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR = 0x93D8;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR = 0x93D9;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR = 0x93DA;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR = 0x93DC;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR = 0x93DD;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR = 0x93D0;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR = 0x93D1;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR = 0x93D2;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR = 0x93D3;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR = 0x93D4;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR = 0x93D5;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR = 0x93D6;

  @DomName('WebGLCompressedTextureASTC.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR = 0x93D7;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLCompressedTextureATC')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_atc/
@Experimental()
@Native("WebGLCompressedTextureATC,WEBGL_compressed_texture_atc")
class CompressedTextureAtc extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureAtc._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WebGLCompressedTextureATC.COMPRESSED_RGBA_ATC_EXPLICIT_ALPHA_WEBGL')
  @DocsEditable()
  static const int COMPRESSED_RGBA_ATC_EXPLICIT_ALPHA_WEBGL = 0x8C93;

  @DomName(
      'WebGLCompressedTextureATC.COMPRESSED_RGBA_ATC_INTERPOLATED_ALPHA_WEBGL')
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
@Native("WebGLCompressedTextureETC1,WEBGL_compressed_texture_etc1")
class CompressedTextureETC1 extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureETC1._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WebGLCompressedTextureETC1.COMPRESSED_RGB_ETC1_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGB_ETC1_WEBGL = 0x8D64;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLCompressedTextureETC')
@Experimental() // untriaged
@Native("WebGLCompressedTextureETC")
class CompressedTextureEtc extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureEtc._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WebGLCompressedTextureETC.COMPRESSED_R11_EAC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_R11_EAC = 0x9270;

  @DomName('WebGLCompressedTextureETC.COMPRESSED_RG11_EAC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RG11_EAC = 0x9272;

  @DomName('WebGLCompressedTextureETC.COMPRESSED_RGB8_ETC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGB8_ETC2 = 0x9274;

  @DomName('WebGLCompressedTextureETC.COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9276;

  @DomName('WebGLCompressedTextureETC.COMPRESSED_RGBA8_ETC2_EAC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_RGBA8_ETC2_EAC = 0x9278;

  @DomName('WebGLCompressedTextureETC.COMPRESSED_SIGNED_R11_EAC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SIGNED_R11_EAC = 0x9271;

  @DomName('WebGLCompressedTextureETC.COMPRESSED_SIGNED_RG11_EAC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SIGNED_RG11_EAC = 0x9273;

  @DomName('WebGLCompressedTextureETC.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ALPHA8_ETC2_EAC = 0x9279;

  @DomName('WebGLCompressedTextureETC.COMPRESSED_SRGB8_ETC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_ETC2 = 0x9275;

  @DomName(
      'WebGLCompressedTextureETC.COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9277;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLCompressedTexturePVRTC')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_pvrtc/
@Experimental() // experimental
@Native("WebGLCompressedTexturePVRTC,WEBGL_compressed_texture_pvrtc")
class CompressedTexturePvrtc extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory CompressedTexturePvrtc._() {
    throw new UnsupportedError("Not supported");
  }

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
@Native("WebGLCompressedTextureS3TC,WEBGL_compressed_texture_s3tc")
class CompressedTextureS3TC extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureS3TC._() {
    throw new UnsupportedError("Not supported");
  }

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
@DomName('WebGLCompressedTextureS3TCsRGB')
@Experimental() // untriaged
@Native("WebGLCompressedTextureS3TCsRGB")
class CompressedTextureS3TCsRgb extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureS3TCsRgb._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WebGLCompressedTextureS3TCsRGB.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT = 0x8C4D;

  @DomName('WebGLCompressedTextureS3TCsRGB.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT = 0x8C4E;

  @DomName('WebGLCompressedTextureS3TCsRGB.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT = 0x8C4F;

  @DomName('WebGLCompressedTextureS3TCsRGB.COMPRESSED_SRGB_S3TC_DXT1_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_SRGB_S3TC_DXT1_EXT = 0x8C4C;
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
  factory ContextEvent._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WebGLContextEvent.WebGLContextEvent')
  @DocsEditable()
  factory ContextEvent(String type, [Map eventInit]) {
    if (eventInit != null) {
      var eventInit_1 = convertDartToNative_Dictionary(eventInit);
      return ContextEvent._create_1(type, eventInit_1);
    }
    return ContextEvent._create_2(type);
  }
  static ContextEvent _create_1(type, eventInit) =>
      JS('ContextEvent', 'new WebGLContextEvent(#,#)', type, eventInit);
  static ContextEvent _create_2(type) =>
      JS('ContextEvent', 'new WebGLContextEvent(#)', type);

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
@Native("WebGLDebugRendererInfo,WEBGL_debug_renderer_info")
class DebugRendererInfo extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory DebugRendererInfo._() {
    throw new UnsupportedError("Not supported");
  }

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
@Native("WebGLDebugShaders,WEBGL_debug_shaders")
class DebugShaders extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory DebugShaders._() {
    throw new UnsupportedError("Not supported");
  }

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
@Native("WebGLDepthTexture,WEBGL_depth_texture")
class DepthTexture extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory DepthTexture._() {
    throw new UnsupportedError("Not supported");
  }

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
@Native("WebGLDrawBuffers,WEBGL_draw_buffers")
class DrawBuffers extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory DrawBuffers._() {
    throw new UnsupportedError("Not supported");
  }

  @JSName('drawBuffersWEBGL')
  @DomName('WebGLDrawBuffers.drawBuffersWEBGL')
  @DocsEditable()
  void drawBuffersWebgl(List<int> buffers) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('EXTsRGB')
@Experimental() // untriaged
@Native("EXTsRGB,EXT_sRGB")
class EXTsRgb extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory EXTsRgb._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('EXTsRGB.FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT = 0x8210;

  @DomName('EXTsRGB.SRGB8_ALPHA8_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRGB8_ALPHA8_EXT = 0x8C43;

  @DomName('EXTsRGB.SRGB_ALPHA_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRGB_ALPHA_EXT = 0x8C42;

  @DomName('EXTsRGB.SRGB_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRGB_EXT = 0x8C40;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('EXTBlendMinMax')
@Experimental() // untriaged
@Native("EXTBlendMinMax,EXT_blend_minmax")
class ExtBlendMinMax extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ExtBlendMinMax._() {
    throw new UnsupportedError("Not supported");
  }

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
@DomName('EXTColorBufferFloat')
@Experimental() // untriaged
@Native("EXTColorBufferFloat")
class ExtColorBufferFloat extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ExtColorBufferFloat._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('EXTColorBufferHalfFloat')
@Experimental() // untriaged
@Native("EXTColorBufferHalfFloat")
class ExtColorBufferHalfFloat extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ExtColorBufferHalfFloat._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('EXTDisjointTimerQuery')
@Experimental() // untriaged
@Native("EXTDisjointTimerQuery")
class ExtDisjointTimerQuery extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ExtDisjointTimerQuery._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('EXTDisjointTimerQuery.CURRENT_QUERY_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CURRENT_QUERY_EXT = 0x8865;

  @DomName('EXTDisjointTimerQuery.GPU_DISJOINT_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int GPU_DISJOINT_EXT = 0x8FBB;

  @DomName('EXTDisjointTimerQuery.QUERY_COUNTER_BITS_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int QUERY_COUNTER_BITS_EXT = 0x8864;

  @DomName('EXTDisjointTimerQuery.QUERY_RESULT_AVAILABLE_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int QUERY_RESULT_AVAILABLE_EXT = 0x8867;

  @DomName('EXTDisjointTimerQuery.QUERY_RESULT_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int QUERY_RESULT_EXT = 0x8866;

  @DomName('EXTDisjointTimerQuery.TIMESTAMP_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TIMESTAMP_EXT = 0x8E28;

  @DomName('EXTDisjointTimerQuery.TIME_ELAPSED_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TIME_ELAPSED_EXT = 0x88BF;

  @JSName('beginQueryEXT')
  @DomName('EXTDisjointTimerQuery.beginQueryEXT')
  @DocsEditable()
  @Experimental() // untriaged
  void beginQueryExt(int target, TimerQueryExt query) native;

  @JSName('createQueryEXT')
  @DomName('EXTDisjointTimerQuery.createQueryEXT')
  @DocsEditable()
  @Experimental() // untriaged
  TimerQueryExt createQueryExt() native;

  @JSName('deleteQueryEXT')
  @DomName('EXTDisjointTimerQuery.deleteQueryEXT')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteQueryExt(TimerQueryExt query) native;

  @JSName('endQueryEXT')
  @DomName('EXTDisjointTimerQuery.endQueryEXT')
  @DocsEditable()
  @Experimental() // untriaged
  void endQueryExt(int target) native;

  @JSName('getQueryEXT')
  @DomName('EXTDisjointTimerQuery.getQueryEXT')
  @DocsEditable()
  @Experimental() // untriaged
  Object getQueryExt(int target, int pname) native;

  @JSName('getQueryObjectEXT')
  @DomName('EXTDisjointTimerQuery.getQueryObjectEXT')
  @DocsEditable()
  @Experimental() // untriaged
  Object getQueryObjectExt(TimerQueryExt query, int pname) native;

  @JSName('isQueryEXT')
  @DomName('EXTDisjointTimerQuery.isQueryEXT')
  @DocsEditable()
  @Experimental() // untriaged
  bool isQueryExt(TimerQueryExt query) native;

  @JSName('queryCounterEXT')
  @DomName('EXTDisjointTimerQuery.queryCounterEXT')
  @DocsEditable()
  @Experimental() // untriaged
  void queryCounterExt(TimerQueryExt query, int target) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('EXTDisjointTimerQueryWebGL2')
@Experimental() // untriaged
@Native("EXTDisjointTimerQueryWebGL2")
class ExtDisjointTimerQueryWebGL2 extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ExtDisjointTimerQueryWebGL2._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('EXTDisjointTimerQueryWebGL2.GPU_DISJOINT_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int GPU_DISJOINT_EXT = 0x8FBB;

  @DomName('EXTDisjointTimerQueryWebGL2.QUERY_COUNTER_BITS_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int QUERY_COUNTER_BITS_EXT = 0x8864;

  @DomName('EXTDisjointTimerQueryWebGL2.TIMESTAMP_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TIMESTAMP_EXT = 0x8E28;

  @DomName('EXTDisjointTimerQueryWebGL2.TIME_ELAPSED_EXT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TIME_ELAPSED_EXT = 0x88BF;

  @JSName('queryCounterEXT')
  @DomName('EXTDisjointTimerQueryWebGL2.queryCounterEXT')
  @DocsEditable()
  @Experimental() // untriaged
  void queryCounterExt(Query query, int target) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('EXTFragDepth')
// http://www.khronos.org/registry/webgl/extensions/EXT_frag_depth/
@Experimental()
@Native("EXTFragDepth,EXT_frag_depth")
class ExtFragDepth extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ExtFragDepth._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('EXTShaderTextureLOD')
@Experimental() // untriaged
@Native("EXTShaderTextureLOD,EXT_shader_texture_lod")
class ExtShaderTextureLod extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ExtShaderTextureLod._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('EXTTextureFilterAnisotropic')
// http://www.khronos.org/registry/webgl/extensions/EXT_texture_filter_anisotropic/
@Experimental()
@Native("EXTTextureFilterAnisotropic,EXT_texture_filter_anisotropic")
class ExtTextureFilterAnisotropic extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ExtTextureFilterAnisotropic._() {
    throw new UnsupportedError("Not supported");
  }

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
  factory Framebuffer._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLGetBufferSubDataAsync')
@Experimental() // untriaged
@Native("WebGLGetBufferSubDataAsync")
class GetBufferSubDataAsync extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory GetBufferSubDataAsync._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WebGLGetBufferSubDataAsync.getBufferSubDataAsync')
  @DocsEditable()
  @Experimental() // untriaged
  Future getBufferSubDataAsync(int target, int srcByteOffset, TypedData dstData,
          [int dstOffset, int length]) =>
      promiseToFuture(JS("", "#.getBufferSubDataAsync(#, #, #, #, #)", this,
          target, srcByteOffset, dstData, dstOffset, length));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLLoseContext')
// http://www.khronos.org/registry/webgl/extensions/WEBGL_lose_context/
@Experimental()
@Native("WebGLLoseContext,WebGLExtensionLoseContext,WEBGL_lose_context")
class LoseContext extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory LoseContext._() {
    throw new UnsupportedError("Not supported");
  }

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
@Native("OESElementIndexUint,OES_element_index_uint")
class OesElementIndexUint extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesElementIndexUint._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('OESStandardDerivatives')
// http://www.khronos.org/registry/webgl/extensions/OES_standard_derivatives/
@Experimental() // experimental
@Native("OESStandardDerivatives,OES_standard_derivatives")
class OesStandardDerivatives extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesStandardDerivatives._() {
    throw new UnsupportedError("Not supported");
  }

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
@Native("OESTextureFloat,OES_texture_float")
class OesTextureFloat extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesTextureFloat._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('OESTextureFloatLinear')
// http://www.khronos.org/registry/webgl/extensions/OES_texture_float_linear/
@Experimental()
@Native("OESTextureFloatLinear,OES_texture_float_linear")
class OesTextureFloatLinear extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesTextureFloatLinear._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('OESTextureHalfFloat')
// http://www.khronos.org/registry/webgl/extensions/OES_texture_half_float/
@Experimental() // experimental
@Native("OESTextureHalfFloat,OES_texture_half_float")
class OesTextureHalfFloat extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesTextureHalfFloat._() {
    throw new UnsupportedError("Not supported");
  }

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
@Native("OESTextureHalfFloatLinear,OES_texture_half_float_linear")
class OesTextureHalfFloatLinear extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesTextureHalfFloatLinear._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('OESVertexArrayObject')
// http://www.khronos.org/registry/webgl/extensions/OES_vertex_array_object/
@Experimental() // experimental
@Native("OESVertexArrayObject,OES_vertex_array_object")
class OesVertexArrayObject extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory OesVertexArrayObject._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('OESVertexArrayObject.VERTEX_ARRAY_BINDING_OES')
  @DocsEditable()
  static const int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  @JSName('bindVertexArrayOES')
  @DomName('OESVertexArrayObject.bindVertexArrayOES')
  @DocsEditable()
  void bindVertexArray(VertexArrayObjectOes arrayObject) native;

  @JSName('createVertexArrayOES')
  @DomName('OESVertexArrayObject.createVertexArrayOES')
  @DocsEditable()
  VertexArrayObjectOes createVertexArray() native;

  @JSName('deleteVertexArrayOES')
  @DomName('OESVertexArrayObject.deleteVertexArrayOES')
  @DocsEditable()
  void deleteVertexArray(VertexArrayObjectOes arrayObject) native;

  @JSName('isVertexArrayOES')
  @DomName('OESVertexArrayObject.isVertexArrayOES')
  @DocsEditable()
  bool isVertexArray(VertexArrayObjectOes arrayObject) native;
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
  factory Program._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLQuery')
@Experimental() // untriaged
@Native("WebGLQuery")
class Query extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Query._() {
    throw new UnsupportedError("Not supported");
  }
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
  factory Renderbuffer._() {
    throw new UnsupportedError("Not supported");
  }
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
  factory RenderingContext._() {
    throw new UnsupportedError("Not supported");
  }

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.WebGLRenderingContext)');

  @DomName('WebGLRenderingContext.canvas')
  @DocsEditable()
  @Experimental() // untriaged
  final CanvasElement canvas;

  // From WebGLRenderingContextBase

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
  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha)
      native;

  @DomName('WebGLRenderingContext.bufferData')
  @DocsEditable()
  void bufferData(int target, data_OR_size, int usage) native;

  @DomName('WebGLRenderingContext.bufferSubData')
  @DocsEditable()
  void bufferSubData(int target, int offset, data) native;

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

  @DomName('WebGLRenderingContext.commit')
  @DocsEditable()
  @Experimental() // untriaged
  Future commit() => promiseToFuture(JS("", "#.commit()", this));

  @DomName('WebGLRenderingContext.compileShader')
  @DocsEditable()
  void compileShader(Shader shader) native;

  @DomName('WebGLRenderingContext.compressedTexImage2D')
  @DocsEditable()
  void compressedTexImage2D(int target, int level, int internalformat,
      int width, int height, int border, TypedData data) native;

  @DomName('WebGLRenderingContext.compressedTexSubImage2D')
  @DocsEditable()
  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset,
      int width, int height, int format, TypedData data) native;

  @DomName('WebGLRenderingContext.copyTexImage2D')
  @DocsEditable()
  void copyTexImage2D(int target, int level, int internalformat, int x, int y,
      int width, int height, int border) native;

  @DomName('WebGLRenderingContext.copyTexSubImage2D')
  @DocsEditable()
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x,
      int y, int width, int height) native;

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
  void framebufferRenderbuffer(int target, int attachment,
      int renderbuffertarget, Renderbuffer renderbuffer) native;

  @DomName('WebGLRenderingContext.framebufferTexture2D')
  @DocsEditable()
  void framebufferTexture2D(int target, int attachment, int textarget,
      Texture texture, int level) native;

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
  @Creates('ContextAttributes|Null')
  Map getContextAttributes() {
    return convertNativeToDart_Dictionary(_getContextAttributes_1());
  }

  @JSName('getContextAttributes')
  @DomName('WebGLRenderingContext.getContextAttributes')
  @DocsEditable()
  @Creates('ContextAttributes|Null')
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
  Object getFramebufferAttachmentParameter(
      int target, int attachment, int pname) native;

  @DomName('WebGLRenderingContext.getParameter')
  @DocsEditable()
  @Creates(
      'Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List|Framebuffer|Renderbuffer|Texture')
  @Returns(
      'Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List|Framebuffer|Renderbuffer|Texture')
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
  ShaderPrecisionFormat getShaderPrecisionFormat(
      int shadertype, int precisiontype) native;

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
  @Creates(
      'Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List')
  @Returns(
      'Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List')
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

  @JSName('readPixels')
  @DomName('WebGLRenderingContext.readPixels')
  @DocsEditable()
  void _readPixels(int x, int y, int width, int height, int format, int type,
      TypedData pixels) native;

  @DomName('WebGLRenderingContext.renderbufferStorage')
  @DocsEditable()
  void renderbufferStorage(
      int target, int internalformat, int width, int height) native;

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

  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void texImage2D(
      int target,
      int level,
      int internalformat,
      int format_OR_width,
      int height_OR_type,
      bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video,
      [int format,
      int type,
      TypedData pixels]) {
    if (type != null &&
        format != null &&
        (bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video is int)) {
      _texImage2D_1(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video,
          format,
          type,
          pixels);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData) &&
        format == null &&
        type == null &&
        pixels == null) {
      var pixels_1 = convertDartToNative_ImageData(
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      _texImage2D_2(target, level, internalformat, format_OR_width,
          height_OR_type, pixels_1);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is ImageElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_3(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is CanvasElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_4(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is VideoElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_5(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is ImageBitmap) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_6(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_1(target, level, internalformat, width, height, int border,
      format, type, TypedData pixels) native;
  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_2(target, level, internalformat, format, type, pixels)
      native;
  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_3(
      target, level, internalformat, format, type, ImageElement image) native;
  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_4(
      target, level, internalformat, format, type, CanvasElement canvas) native;
  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_5(
      target, level, internalformat, format, type, VideoElement video) native;
  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable()
  void _texImage2D_6(
      target, level, internalformat, format, type, ImageBitmap bitmap) native;

  @DomName('WebGLRenderingContext.texParameterf')
  @DocsEditable()
  void texParameterf(int target, int pname, num param) native;

  @DomName('WebGLRenderingContext.texParameteri')
  @DocsEditable()
  void texParameteri(int target, int pname, int param) native;

  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void texSubImage2D(
      int target,
      int level,
      int xoffset,
      int yoffset,
      int format_OR_width,
      int height_OR_type,
      bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video,
      [int type,
      TypedData pixels]) {
    if (type != null &&
        (bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is int)) {
      _texSubImage2D_1(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video,
          type,
          pixels);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData) &&
        type == null &&
        pixels == null) {
      var pixels_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width,
          height_OR_type, pixels_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is ImageElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_3(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is CanvasElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_4(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is VideoElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_5(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is ImageBitmap) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_6(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_1(target, level, xoffset, yoffset, width, height,
      int format, type, TypedData pixels) native;
  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_2(target, level, xoffset, yoffset, format, type, pixels)
      native;
  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_3(
      target, level, xoffset, yoffset, format, type, ImageElement image) native;
  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_4(target, level, xoffset, yoffset, format, type,
      CanvasElement canvas) native;
  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_5(
      target, level, xoffset, yoffset, format, type, VideoElement video) native;
  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable()
  void _texSubImage2D_6(
      target, level, xoffset, yoffset, format, type, ImageBitmap bitmap) native;

  @DomName('WebGLRenderingContext.uniform1f')
  @DocsEditable()
  void uniform1f(UniformLocation location, num x) native;

  @DomName('WebGLRenderingContext.uniform1fv')
  @DocsEditable()
  void uniform1fv(UniformLocation location, v) native;

  @DomName('WebGLRenderingContext.uniform1i')
  @DocsEditable()
  void uniform1i(UniformLocation location, int x) native;

  @DomName('WebGLRenderingContext.uniform1iv')
  @DocsEditable()
  void uniform1iv(UniformLocation location, v) native;

  @DomName('WebGLRenderingContext.uniform2f')
  @DocsEditable()
  void uniform2f(UniformLocation location, num x, num y) native;

  @DomName('WebGLRenderingContext.uniform2fv')
  @DocsEditable()
  void uniform2fv(UniformLocation location, v) native;

  @DomName('WebGLRenderingContext.uniform2i')
  @DocsEditable()
  void uniform2i(UniformLocation location, int x, int y) native;

  @DomName('WebGLRenderingContext.uniform2iv')
  @DocsEditable()
  void uniform2iv(UniformLocation location, v) native;

  @DomName('WebGLRenderingContext.uniform3f')
  @DocsEditable()
  void uniform3f(UniformLocation location, num x, num y, num z) native;

  @DomName('WebGLRenderingContext.uniform3fv')
  @DocsEditable()
  void uniform3fv(UniformLocation location, v) native;

  @DomName('WebGLRenderingContext.uniform3i')
  @DocsEditable()
  void uniform3i(UniformLocation location, int x, int y, int z) native;

  @DomName('WebGLRenderingContext.uniform3iv')
  @DocsEditable()
  void uniform3iv(UniformLocation location, v) native;

  @DomName('WebGLRenderingContext.uniform4f')
  @DocsEditable()
  void uniform4f(UniformLocation location, num x, num y, num z, num w) native;

  @DomName('WebGLRenderingContext.uniform4fv')
  @DocsEditable()
  void uniform4fv(UniformLocation location, v) native;

  @DomName('WebGLRenderingContext.uniform4i')
  @DocsEditable()
  void uniform4i(UniformLocation location, int x, int y, int z, int w) native;

  @DomName('WebGLRenderingContext.uniform4iv')
  @DocsEditable()
  void uniform4iv(UniformLocation location, v) native;

  @DomName('WebGLRenderingContext.uniformMatrix2fv')
  @DocsEditable()
  void uniformMatrix2fv(UniformLocation location, bool transpose, array) native;

  @DomName('WebGLRenderingContext.uniformMatrix3fv')
  @DocsEditable()
  void uniformMatrix3fv(UniformLocation location, bool transpose, array) native;

  @DomName('WebGLRenderingContext.uniformMatrix4fv')
  @DocsEditable()
  void uniformMatrix4fv(UniformLocation location, bool transpose, array) native;

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
  void vertexAttrib1fv(int indx, values) native;

  @DomName('WebGLRenderingContext.vertexAttrib2f')
  @DocsEditable()
  void vertexAttrib2f(int indx, num x, num y) native;

  @DomName('WebGLRenderingContext.vertexAttrib2fv')
  @DocsEditable()
  void vertexAttrib2fv(int indx, values) native;

  @DomName('WebGLRenderingContext.vertexAttrib3f')
  @DocsEditable()
  void vertexAttrib3f(int indx, num x, num y, num z) native;

  @DomName('WebGLRenderingContext.vertexAttrib3fv')
  @DocsEditable()
  void vertexAttrib3fv(int indx, values) native;

  @DomName('WebGLRenderingContext.vertexAttrib4f')
  @DocsEditable()
  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  @DomName('WebGLRenderingContext.vertexAttrib4fv')
  @DocsEditable()
  void vertexAttrib4fv(int indx, values) native;

  @DomName('WebGLRenderingContext.vertexAttribPointer')
  @DocsEditable()
  void vertexAttribPointer(int indx, int size, int type, bool normalized,
      int stride, int offset) native;

  @DomName('WebGLRenderingContext.viewport')
  @DocsEditable()
  void viewport(int x, int y, int width, int height) native;

  @DomName('WebGLRenderingContext.readPixels')
  @DocsEditable()
  void readPixels(int x, int y, int width, int height, int format, int type,
      TypedData pixels) {
    _readPixels(x, y, width, height, format, type, pixels);
  }

  /**
   * Sets the currently bound texture to [data].
   *
   * [data] can be either an [ImageElement], a
   * [CanvasElement], a [VideoElement], [TypedData] or an [ImageData] object.
   *
   * This is deprecated in favor of [texImage2D].
   */
  @Deprecated("Use texImage2D")
  void texImage2DUntyped(int targetTexture, int levelOfDetail,
      int internalFormat, int format, int type, data) {
    texImage2D(
        targetTexture, levelOfDetail, internalFormat, format, type, data);
  }

  /**
   * Sets the currently bound texture to [data].
   *
   * This is deprecated in favour of [texImage2D].
   */
  @Deprecated("Use texImage2D")
  void texImage2DTyped(int targetTexture, int levelOfDetail, int internalFormat,
      int width, int height, int border, int format, int type, TypedData data) {
    texImage2D(targetTexture, levelOfDetail, internalFormat, width, height,
        border, format, type, data);
  }

  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * [data] can be either an [ImageElement], a
   * [CanvasElement], a [VideoElement], [TypedData] or an [ImageData] object.
   *
   */
  @Deprecated("Use texSubImage2D")
  void texSubImage2DUntyped(int targetTexture, int levelOfDetail, int xOffset,
      int yOffset, int format, int type, data) {
    texSubImage2D(
        targetTexture, levelOfDetail, xOffset, yOffset, format, type, data);
  }

  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   */
  @Deprecated("Use texSubImage2D")
  void texSubImage2DTyped(
      int targetTexture,
      int levelOfDetail,
      int xOffset,
      int yOffset,
      int width,
      int height,
      int border,
      int format,
      int type,
      TypedData data) {
    texSubImage2D(targetTexture, levelOfDetail, xOffset, yOffset, width, height,
        format, type, data);
  }

  /**
   * Set the bufferData to [data].
   */
  @Deprecated("Use bufferData")
  void bufferDataTyped(int target, TypedData data, int usage) {
    bufferData(target, data, usage);
  }

  /**
   * Set the bufferSubData to [data].
   */
  @Deprecated("Use bufferSubData")
  void bufferSubDataTyped(int target, int offset, TypedData data) {
    bufferSubData(target, offset, data);
  }
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGL2RenderingContext')
@Experimental() // untriaged
@Native("WebGL2RenderingContext")
class RenderingContext2 extends Interceptor
    implements _WebGL2RenderingContextBase, _WebGLRenderingContextBase {
  // To suppress missing implicit constructor warnings.
  factory RenderingContext2._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WebGL2RenderingContext.canvas')
  @DocsEditable()
  @Experimental() // untriaged
  final Canvas canvas;

  // From WebGL2RenderingContextBase

  @DomName('WebGL2RenderingContext.beginQuery')
  @DocsEditable()
  @Experimental() // untriaged
  void beginQuery(int target, Query query) native;

  @DomName('WebGL2RenderingContext.beginTransformFeedback')
  @DocsEditable()
  @Experimental() // untriaged
  void beginTransformFeedback(int primitiveMode) native;

  @DomName('WebGL2RenderingContext.bindBufferBase')
  @DocsEditable()
  @Experimental() // untriaged
  void bindBufferBase(int target, int index, Buffer buffer) native;

  @DomName('WebGL2RenderingContext.bindBufferRange')
  @DocsEditable()
  @Experimental() // untriaged
  void bindBufferRange(
      int target, int index, Buffer buffer, int offset, int size) native;

  @DomName('WebGL2RenderingContext.bindSampler')
  @DocsEditable()
  @Experimental() // untriaged
  void bindSampler(int unit, Sampler sampler) native;

  @DomName('WebGL2RenderingContext.bindTransformFeedback')
  @DocsEditable()
  @Experimental() // untriaged
  void bindTransformFeedback(int target, TransformFeedback feedback) native;

  @DomName('WebGL2RenderingContext.bindVertexArray')
  @DocsEditable()
  @Experimental() // untriaged
  void bindVertexArray(VertexArrayObject vertexArray) native;

  @DomName('WebGL2RenderingContext.blitFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void blitFramebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0,
      int dstY0, int dstX1, int dstY1, int mask, int filter) native;

  @JSName('bufferData')
  @DomName('WebGL2RenderingContext.bufferData')
  @DocsEditable()
  @Experimental() // untriaged
  void bufferData2(int target, TypedData srcData, int usage, int srcOffset,
      [int length]) native;

  @JSName('bufferSubData')
  @DomName('WebGL2RenderingContext.bufferSubData')
  @DocsEditable()
  @Experimental() // untriaged
  void bufferSubData2(
      int target, int dstByteOffset, TypedData srcData, int srcOffset,
      [int length]) native;

  @DomName('WebGL2RenderingContext.clearBufferfi')
  @DocsEditable()
  @Experimental() // untriaged
  void clearBufferfi(int buffer, int drawbuffer, num depth, int stencil) native;

  @DomName('WebGL2RenderingContext.clearBufferfv')
  @DocsEditable()
  @Experimental() // untriaged
  void clearBufferfv(int buffer, int drawbuffer, value, [int srcOffset]) native;

  @DomName('WebGL2RenderingContext.clearBufferiv')
  @DocsEditable()
  @Experimental() // untriaged
  void clearBufferiv(int buffer, int drawbuffer, value, [int srcOffset]) native;

  @DomName('WebGL2RenderingContext.clearBufferuiv')
  @DocsEditable()
  @Experimental() // untriaged
  void clearBufferuiv(int buffer, int drawbuffer, value, [int srcOffset])
      native;

  @DomName('WebGL2RenderingContext.clientWaitSync')
  @DocsEditable()
  @Experimental() // untriaged
  int clientWaitSync(Sync sync, int flags, int timeout) native;

  @JSName('compressedTexImage2D')
  @DomName('WebGL2RenderingContext.compressedTexImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexImage2D2(int target, int level, int internalformat,
      int width, int height, int border, TypedData data, int srcOffset,
      [int srcLengthOverride]) native;

  @JSName('compressedTexImage2D')
  @DomName('WebGL2RenderingContext.compressedTexImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexImage2D3(int target, int level, int internalformat,
      int width, int height, int border, int imageSize, int offset) native;

  @DomName('WebGL2RenderingContext.compressedTexImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexImage3D(int target, int level, int internalformat,
      int width, int height, int depth, int border, TypedData data,
      [int srcOffset, int srcLengthOverride]) native;

  @JSName('compressedTexImage3D')
  @DomName('WebGL2RenderingContext.compressedTexImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexImage3D2(
      int target,
      int level,
      int internalformat,
      int width,
      int height,
      int depth,
      int border,
      int imageSize,
      int offset) native;

  @JSName('compressedTexSubImage2D')
  @DomName('WebGL2RenderingContext.compressedTexSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexSubImage2D2(int target, int level, int xoffset, int yoffset,
      int width, int height, int format, TypedData data, int srcOffset,
      [int srcLengthOverride]) native;

  @JSName('compressedTexSubImage2D')
  @DomName('WebGL2RenderingContext.compressedTexSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexSubImage2D3(int target, int level, int xoffset, int yoffset,
      int width, int height, int format, int imageSize, int offset) native;

  @DomName('WebGL2RenderingContext.compressedTexSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexSubImage3D(int target, int level, int xoffset, int yoffset,
      int zoffset, int width, int height, int depth, int format, TypedData data,
      [int srcOffset, int srcLengthOverride]) native;

  @JSName('compressedTexSubImage3D')
  @DomName('WebGL2RenderingContext.compressedTexSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexSubImage3D2(
      int target,
      int level,
      int xoffset,
      int yoffset,
      int zoffset,
      int width,
      int height,
      int depth,
      int format,
      int imageSize,
      int offset) native;

  @DomName('WebGL2RenderingContext.copyBufferSubData')
  @DocsEditable()
  @Experimental() // untriaged
  void copyBufferSubData(int readTarget, int writeTarget, int readOffset,
      int writeOffset, int size) native;

  @DomName('WebGL2RenderingContext.copyTexSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void copyTexSubImage3D(int target, int level, int xoffset, int yoffset,
      int zoffset, int x, int y, int width, int height) native;

  @DomName('WebGL2RenderingContext.createQuery')
  @DocsEditable()
  @Experimental() // untriaged
  Query createQuery() native;

  @DomName('WebGL2RenderingContext.createSampler')
  @DocsEditable()
  @Experimental() // untriaged
  Sampler createSampler() native;

  @DomName('WebGL2RenderingContext.createTransformFeedback')
  @DocsEditable()
  @Experimental() // untriaged
  TransformFeedback createTransformFeedback() native;

  @DomName('WebGL2RenderingContext.createVertexArray')
  @DocsEditable()
  @Experimental() // untriaged
  VertexArrayObject createVertexArray() native;

  @DomName('WebGL2RenderingContext.deleteQuery')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteQuery(Query query) native;

  @DomName('WebGL2RenderingContext.deleteSampler')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteSampler(Sampler sampler) native;

  @DomName('WebGL2RenderingContext.deleteSync')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteSync(Sync sync) native;

  @DomName('WebGL2RenderingContext.deleteTransformFeedback')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteTransformFeedback(TransformFeedback feedback) native;

  @DomName('WebGL2RenderingContext.deleteVertexArray')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteVertexArray(VertexArrayObject vertexArray) native;

  @DomName('WebGL2RenderingContext.drawArraysInstanced')
  @DocsEditable()
  @Experimental() // untriaged
  void drawArraysInstanced(int mode, int first, int count, int instanceCount)
      native;

  @DomName('WebGL2RenderingContext.drawBuffers')
  @DocsEditable()
  @Experimental() // untriaged
  void drawBuffers(List<int> buffers) native;

  @DomName('WebGL2RenderingContext.drawElementsInstanced')
  @DocsEditable()
  @Experimental() // untriaged
  void drawElementsInstanced(
      int mode, int count, int type, int offset, int instanceCount) native;

  @DomName('WebGL2RenderingContext.drawRangeElements')
  @DocsEditable()
  @Experimental() // untriaged
  void drawRangeElements(
      int mode, int start, int end, int count, int type, int offset) native;

  @DomName('WebGL2RenderingContext.endQuery')
  @DocsEditable()
  @Experimental() // untriaged
  void endQuery(int target) native;

  @DomName('WebGL2RenderingContext.endTransformFeedback')
  @DocsEditable()
  @Experimental() // untriaged
  void endTransformFeedback() native;

  @DomName('WebGL2RenderingContext.fenceSync')
  @DocsEditable()
  @Experimental() // untriaged
  Sync fenceSync(int condition, int flags) native;

  @DomName('WebGL2RenderingContext.framebufferTextureLayer')
  @DocsEditable()
  @Experimental() // untriaged
  void framebufferTextureLayer(
      int target, int attachment, Texture texture, int level, int layer) native;

  @DomName('WebGL2RenderingContext.getActiveUniformBlockName')
  @DocsEditable()
  @Experimental() // untriaged
  String getActiveUniformBlockName(Program program, int uniformBlockIndex)
      native;

  @DomName('WebGL2RenderingContext.getActiveUniformBlockParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getActiveUniformBlockParameter(
      Program program, int uniformBlockIndex, int pname) native;

  @DomName('WebGL2RenderingContext.getActiveUniforms')
  @DocsEditable()
  @Experimental() // untriaged
  Object getActiveUniforms(Program program, List<int> uniformIndices, int pname)
      native;

  @DomName('WebGL2RenderingContext.getBufferSubData')
  @DocsEditable()
  @Experimental() // untriaged
  void getBufferSubData(int target, int srcByteOffset, TypedData dstData,
      [int dstOffset, int length]) native;

  @DomName('WebGL2RenderingContext.getFragDataLocation')
  @DocsEditable()
  @Experimental() // untriaged
  int getFragDataLocation(Program program, String name) native;

  @DomName('WebGL2RenderingContext.getIndexedParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getIndexedParameter(int target, int index) native;

  @DomName('WebGL2RenderingContext.getInternalformatParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getInternalformatParameter(int target, int internalformat, int pname)
      native;

  @DomName('WebGL2RenderingContext.getQuery')
  @DocsEditable()
  @Experimental() // untriaged
  Object getQuery(int target, int pname) native;

  @DomName('WebGL2RenderingContext.getQueryParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getQueryParameter(Query query, int pname) native;

  @DomName('WebGL2RenderingContext.getSamplerParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getSamplerParameter(Sampler sampler, int pname) native;

  @DomName('WebGL2RenderingContext.getSyncParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getSyncParameter(Sync sync, int pname) native;

  @DomName('WebGL2RenderingContext.getTransformFeedbackVarying')
  @DocsEditable()
  @Experimental() // untriaged
  ActiveInfo getTransformFeedbackVarying(Program program, int index) native;

  @DomName('WebGL2RenderingContext.getUniformBlockIndex')
  @DocsEditable()
  @Experimental() // untriaged
  int getUniformBlockIndex(Program program, String uniformBlockName) native;

  @DomName('WebGL2RenderingContext.getUniformIndices')
  @DocsEditable()
  @Experimental() // untriaged
  List<int> getUniformIndices(Program program, List<String> uniformNames) {
    List uniformNames_1 = convertDartToNative_StringArray(uniformNames);
    return _getUniformIndices_1(program, uniformNames_1);
  }

  @JSName('getUniformIndices')
  @DomName('WebGL2RenderingContext.getUniformIndices')
  @DocsEditable()
  @Experimental() // untriaged
  List<int> _getUniformIndices_1(Program program, List uniformNames) native;

  @DomName('WebGL2RenderingContext.invalidateFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void invalidateFramebuffer(int target, List<int> attachments) native;

  @DomName('WebGL2RenderingContext.invalidateSubFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void invalidateSubFramebuffer(int target, List<int> attachments, int x, int y,
      int width, int height) native;

  @DomName('WebGL2RenderingContext.isQuery')
  @DocsEditable()
  @Experimental() // untriaged
  bool isQuery(Query query) native;

  @DomName('WebGL2RenderingContext.isSampler')
  @DocsEditable()
  @Experimental() // untriaged
  bool isSampler(Sampler sampler) native;

  @DomName('WebGL2RenderingContext.isSync')
  @DocsEditable()
  @Experimental() // untriaged
  bool isSync(Sync sync) native;

  @DomName('WebGL2RenderingContext.isTransformFeedback')
  @DocsEditable()
  @Experimental() // untriaged
  bool isTransformFeedback(TransformFeedback feedback) native;

  @DomName('WebGL2RenderingContext.isVertexArray')
  @DocsEditable()
  @Experimental() // untriaged
  bool isVertexArray(VertexArrayObject vertexArray) native;

  @DomName('WebGL2RenderingContext.pauseTransformFeedback')
  @DocsEditable()
  @Experimental() // untriaged
  void pauseTransformFeedback() native;

  @DomName('WebGL2RenderingContext.readBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void readBuffer(int mode) native;

  @JSName('readPixels')
  @DomName('WebGL2RenderingContext.readPixels')
  @DocsEditable()
  @Experimental() // untriaged
  void readPixels2(int x, int y, int width, int height, int format, int type,
      dstData_OR_offset,
      [int offset]) native;

  @DomName('WebGL2RenderingContext.renderbufferStorageMultisample')
  @DocsEditable()
  @Experimental() // untriaged
  void renderbufferStorageMultisample(int target, int samples,
      int internalformat, int width, int height) native;

  @DomName('WebGL2RenderingContext.resumeTransformFeedback')
  @DocsEditable()
  @Experimental() // untriaged
  void resumeTransformFeedback() native;

  @DomName('WebGL2RenderingContext.samplerParameterf')
  @DocsEditable()
  @Experimental() // untriaged
  void samplerParameterf(Sampler sampler, int pname, num param) native;

  @DomName('WebGL2RenderingContext.samplerParameteri')
  @DocsEditable()
  @Experimental() // untriaged
  void samplerParameteri(Sampler sampler, int pname, int param) native;

  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void texImage2D2(
      int target,
      int level,
      int internalformat,
      int width,
      int height,
      int border,
      int format,
      int type,
      bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video,
      [int srcOffset]) {
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is int) &&
        srcOffset == null) {
      _texImage2D2_1(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageData) &&
        srcOffset == null) {
      var data_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      _texImage2D2_2(target, level, internalformat, width, height, border,
          format, type, data_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageElement) &&
        srcOffset == null) {
      _texImage2D2_3(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is CanvasElement) &&
        srcOffset == null) {
      _texImage2D2_4(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is VideoElement) &&
        srcOffset == null) {
      _texImage2D2_5(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageBitmap) &&
        srcOffset == null) {
      _texImage2D2_6(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if (srcOffset != null &&
        (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is TypedData)) {
      _texImage2D2_7(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video,
          srcOffset);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D2_1(target, level, internalformat, width, height, border,
      format, type, int offset) native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D2_2(target, level, internalformat, width, height, border,
      format, type, data) native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D2_3(target, level, internalformat, width, height, border,
      format, type, ImageElement image) native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D2_4(target, level, internalformat, width, height, border,
      format, type, CanvasElement canvas) native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D2_5(target, level, internalformat, width, height, border,
      format, type, VideoElement video) native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D2_6(target, level, internalformat, width, height, border,
      format, type, ImageBitmap bitmap) native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D2_7(target, level, internalformat, width, height, border,
      format, type, TypedData srcData, srcOffset) native;

  @DomName('WebGL2RenderingContext.texImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void texImage3D(
      int target,
      int level,
      int internalformat,
      int width,
      int height,
      int depth,
      int border,
      int format,
      int type,
      bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video,
      [int srcOffset]) {
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is int) &&
        srcOffset == null) {
      _texImage3D_1(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageData) &&
        srcOffset == null) {
      var data_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      _texImage3D_2(target, level, internalformat, width, height, depth, border,
          format, type, data_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageElement) &&
        srcOffset == null) {
      _texImage3D_3(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is CanvasElement) &&
        srcOffset == null) {
      _texImage3D_4(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is VideoElement) &&
        srcOffset == null) {
      _texImage3D_5(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageBitmap) &&
        srcOffset == null) {
      _texImage3D_6(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
                is TypedData ||
            bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video ==
                null) &&
        srcOffset == null) {
      _texImage3D_7(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if (srcOffset != null &&
        (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is TypedData)) {
      _texImage3D_8(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video,
          srcOffset);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texImage3D')
  @DomName('WebGL2RenderingContext.texImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage3D_1(target, level, internalformat, width, height, depth,
      border, format, type, int offset) native;
  @JSName('texImage3D')
  @DomName('WebGL2RenderingContext.texImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage3D_2(target, level, internalformat, width, height, depth,
      border, format, type, data) native;
  @JSName('texImage3D')
  @DomName('WebGL2RenderingContext.texImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage3D_3(target, level, internalformat, width, height, depth,
      border, format, type, ImageElement image) native;
  @JSName('texImage3D')
  @DomName('WebGL2RenderingContext.texImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage3D_4(target, level, internalformat, width, height, depth,
      border, format, type, CanvasElement canvas) native;
  @JSName('texImage3D')
  @DomName('WebGL2RenderingContext.texImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage3D_5(target, level, internalformat, width, height, depth,
      border, format, type, VideoElement video) native;
  @JSName('texImage3D')
  @DomName('WebGL2RenderingContext.texImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage3D_6(target, level, internalformat, width, height, depth,
      border, format, type, ImageBitmap bitmap) native;
  @JSName('texImage3D')
  @DomName('WebGL2RenderingContext.texImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage3D_7(target, level, internalformat, width, height, depth,
      border, format, type, TypedData pixels) native;
  @JSName('texImage3D')
  @DomName('WebGL2RenderingContext.texImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage3D_8(target, level, internalformat, width, height, depth,
      border, format, type, TypedData pixels, srcOffset) native;

  @DomName('WebGL2RenderingContext.texStorage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void texStorage2D(
      int target, int levels, int internalformat, int width, int height) native;

  @DomName('WebGL2RenderingContext.texStorage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void texStorage3D(int target, int levels, int internalformat, int width,
      int height, int depth) native;

  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void texSubImage2D2(
      int target,
      int level,
      int xoffset,
      int yoffset,
      int width,
      int height,
      int format,
      int type,
      bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video,
      [int srcOffset]) {
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is int) &&
        srcOffset == null) {
      _texSubImage2D2_1(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageData) &&
        srcOffset == null) {
      var data_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      _texSubImage2D2_2(
          target, level, xoffset, yoffset, width, height, format, type, data_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageElement) &&
        srcOffset == null) {
      _texSubImage2D2_3(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is CanvasElement) &&
        srcOffset == null) {
      _texSubImage2D2_4(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is VideoElement) &&
        srcOffset == null) {
      _texSubImage2D2_5(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageBitmap) &&
        srcOffset == null) {
      _texSubImage2D2_6(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if (srcOffset != null &&
        (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is TypedData)) {
      _texSubImage2D2_7(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video,
          srcOffset);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D2_1(target, level, xoffset, yoffset, width, height, format,
      type, int offset) native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D2_2(target, level, xoffset, yoffset, width, height, format,
      type, data) native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D2_3(target, level, xoffset, yoffset, width, height, format,
      type, ImageElement image) native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D2_4(target, level, xoffset, yoffset, width, height, format,
      type, CanvasElement canvas) native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D2_5(target, level, xoffset, yoffset, width, height, format,
      type, VideoElement video) native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D2_6(target, level, xoffset, yoffset, width, height, format,
      type, ImageBitmap bitmap) native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D2_7(target, level, xoffset, yoffset, width, height, format,
      type, TypedData srcData, srcOffset) native;

  @DomName('WebGL2RenderingContext.texSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void texSubImage3D(
      int target,
      int level,
      int xoffset,
      int yoffset,
      int zoffset,
      int width,
      int height,
      int depth,
      int format,
      int type,
      bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video,
      [int srcOffset]) {
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is int) &&
        srcOffset == null) {
      _texSubImage3D_1(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageData) &&
        srcOffset == null) {
      var data_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      _texSubImage3D_2(target, level, xoffset, yoffset, zoffset, width, height,
          depth, format, type, data_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageElement) &&
        srcOffset == null) {
      _texSubImage3D_3(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is CanvasElement) &&
        srcOffset == null) {
      _texSubImage3D_4(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is VideoElement) &&
        srcOffset == null) {
      _texSubImage3D_5(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageBitmap) &&
        srcOffset == null) {
      _texSubImage3D_6(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is TypedData) &&
        srcOffset == null) {
      _texSubImage3D_7(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if (srcOffset != null &&
        (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is TypedData)) {
      _texSubImage3D_8(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video,
          srcOffset);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texSubImage3D')
  @DomName('WebGL2RenderingContext.texSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage3D_1(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, int offset) native;
  @JSName('texSubImage3D')
  @DomName('WebGL2RenderingContext.texSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage3D_2(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, data) native;
  @JSName('texSubImage3D')
  @DomName('WebGL2RenderingContext.texSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage3D_3(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, ImageElement image) native;
  @JSName('texSubImage3D')
  @DomName('WebGL2RenderingContext.texSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage3D_4(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, CanvasElement canvas) native;
  @JSName('texSubImage3D')
  @DomName('WebGL2RenderingContext.texSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage3D_5(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, VideoElement video) native;
  @JSName('texSubImage3D')
  @DomName('WebGL2RenderingContext.texSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage3D_6(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, ImageBitmap bitmap) native;
  @JSName('texSubImage3D')
  @DomName('WebGL2RenderingContext.texSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage3D_7(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, TypedData pixels) native;
  @JSName('texSubImage3D')
  @DomName('WebGL2RenderingContext.texSubImage3D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage3D_8(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, TypedData pixels, srcOffset) native;

  @DomName('WebGL2RenderingContext.transformFeedbackVaryings')
  @DocsEditable()
  @Experimental() // untriaged
  void transformFeedbackVaryings(
      Program program, List<String> varyings, int bufferMode) {
    List varyings_1 = convertDartToNative_StringArray(varyings);
    _transformFeedbackVaryings_1(program, varyings_1, bufferMode);
    return;
  }

  @JSName('transformFeedbackVaryings')
  @DomName('WebGL2RenderingContext.transformFeedbackVaryings')
  @DocsEditable()
  @Experimental() // untriaged
  void _transformFeedbackVaryings_1(Program program, List varyings, bufferMode)
      native;

  @JSName('uniform1fv')
  @DomName('WebGL2RenderingContext.uniform1fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1fv2(UniformLocation location, v, int srcOffset, [int srcLength])
      native;

  @JSName('uniform1iv')
  @DomName('WebGL2RenderingContext.uniform1iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1iv2(UniformLocation location, v, int srcOffset, [int srcLength])
      native;

  @DomName('WebGL2RenderingContext.uniform1ui')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1ui(UniformLocation location, int v0) native;

  @DomName('WebGL2RenderingContext.uniform1uiv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1uiv(UniformLocation location, v, [int srcOffset, int srcLength])
      native;

  @JSName('uniform2fv')
  @DomName('WebGL2RenderingContext.uniform2fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2fv2(UniformLocation location, v, int srcOffset, [int srcLength])
      native;

  @JSName('uniform2iv')
  @DomName('WebGL2RenderingContext.uniform2iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2iv2(UniformLocation location, v, int srcOffset, [int srcLength])
      native;

  @DomName('WebGL2RenderingContext.uniform2ui')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2ui(UniformLocation location, int v0, int v1) native;

  @DomName('WebGL2RenderingContext.uniform2uiv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2uiv(UniformLocation location, v, [int srcOffset, int srcLength])
      native;

  @JSName('uniform3fv')
  @DomName('WebGL2RenderingContext.uniform3fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3fv2(UniformLocation location, v, int srcOffset, [int srcLength])
      native;

  @JSName('uniform3iv')
  @DomName('WebGL2RenderingContext.uniform3iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3iv2(UniformLocation location, v, int srcOffset, [int srcLength])
      native;

  @DomName('WebGL2RenderingContext.uniform3ui')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3ui(UniformLocation location, int v0, int v1, int v2) native;

  @DomName('WebGL2RenderingContext.uniform3uiv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3uiv(UniformLocation location, v, [int srcOffset, int srcLength])
      native;

  @JSName('uniform4fv')
  @DomName('WebGL2RenderingContext.uniform4fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4fv2(UniformLocation location, v, int srcOffset, [int srcLength])
      native;

  @JSName('uniform4iv')
  @DomName('WebGL2RenderingContext.uniform4iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4iv2(UniformLocation location, v, int srcOffset, [int srcLength])
      native;

  @DomName('WebGL2RenderingContext.uniform4ui')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4ui(UniformLocation location, int v0, int v1, int v2, int v3)
      native;

  @DomName('WebGL2RenderingContext.uniform4uiv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4uiv(UniformLocation location, v, [int srcOffset, int srcLength])
      native;

  @DomName('WebGL2RenderingContext.uniformBlockBinding')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformBlockBinding(
      Program program, int uniformBlockIndex, int uniformBlockBinding) native;

  @JSName('uniformMatrix2fv')
  @DomName('WebGL2RenderingContext.uniformMatrix2fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix2fv2(
      UniformLocation location, bool transpose, array, int srcOffset,
      [int srcLength]) native;

  @DomName('WebGL2RenderingContext.uniformMatrix2x3fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix2x3fv(UniformLocation location, bool transpose, value,
      [int srcOffset, int srcLength]) native;

  @DomName('WebGL2RenderingContext.uniformMatrix2x4fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix2x4fv(UniformLocation location, bool transpose, value,
      [int srcOffset, int srcLength]) native;

  @JSName('uniformMatrix3fv')
  @DomName('WebGL2RenderingContext.uniformMatrix3fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix3fv2(
      UniformLocation location, bool transpose, array, int srcOffset,
      [int srcLength]) native;

  @DomName('WebGL2RenderingContext.uniformMatrix3x2fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix3x2fv(UniformLocation location, bool transpose, value,
      [int srcOffset, int srcLength]) native;

  @DomName('WebGL2RenderingContext.uniformMatrix3x4fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix3x4fv(UniformLocation location, bool transpose, value,
      [int srcOffset, int srcLength]) native;

  @JSName('uniformMatrix4fv')
  @DomName('WebGL2RenderingContext.uniformMatrix4fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix4fv2(
      UniformLocation location, bool transpose, array, int srcOffset,
      [int srcLength]) native;

  @DomName('WebGL2RenderingContext.uniformMatrix4x2fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix4x2fv(UniformLocation location, bool transpose, value,
      [int srcOffset, int srcLength]) native;

  @DomName('WebGL2RenderingContext.uniformMatrix4x3fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix4x3fv(UniformLocation location, bool transpose, value,
      [int srcOffset, int srcLength]) native;

  @DomName('WebGL2RenderingContext.vertexAttribDivisor')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttribDivisor(int index, int divisor) native;

  @DomName('WebGL2RenderingContext.vertexAttribI4i')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttribI4i(int index, int x, int y, int z, int w) native;

  @DomName('WebGL2RenderingContext.vertexAttribI4iv')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttribI4iv(int index, v) native;

  @DomName('WebGL2RenderingContext.vertexAttribI4ui')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttribI4ui(int index, int x, int y, int z, int w) native;

  @DomName('WebGL2RenderingContext.vertexAttribI4uiv')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttribI4uiv(int index, v) native;

  @DomName('WebGL2RenderingContext.vertexAttribIPointer')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttribIPointer(
      int index, int size, int type, int stride, int offset) native;

  @DomName('WebGL2RenderingContext.waitSync')
  @DocsEditable()
  @Experimental() // untriaged
  void waitSync(Sync sync, int flags, int timeout) native;

  // From WebGLRenderingContextBase

  @DomName('WebGL2RenderingContext.drawingBufferHeight')
  @DocsEditable()
  @Experimental() // untriaged
  final int drawingBufferHeight;

  @DomName('WebGL2RenderingContext.drawingBufferWidth')
  @DocsEditable()
  @Experimental() // untriaged
  final int drawingBufferWidth;

  @DomName('WebGL2RenderingContext.activeTexture')
  @DocsEditable()
  @Experimental() // untriaged
  void activeTexture(int texture) native;

  @DomName('WebGL2RenderingContext.attachShader')
  @DocsEditable()
  @Experimental() // untriaged
  void attachShader(Program program, Shader shader) native;

  @DomName('WebGL2RenderingContext.bindAttribLocation')
  @DocsEditable()
  @Experimental() // untriaged
  void bindAttribLocation(Program program, int index, String name) native;

  @DomName('WebGL2RenderingContext.bindBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void bindBuffer(int target, Buffer buffer) native;

  @DomName('WebGL2RenderingContext.bindFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void bindFramebuffer(int target, Framebuffer framebuffer) native;

  @DomName('WebGL2RenderingContext.bindRenderbuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void bindRenderbuffer(int target, Renderbuffer renderbuffer) native;

  @DomName('WebGL2RenderingContext.bindTexture')
  @DocsEditable()
  @Experimental() // untriaged
  void bindTexture(int target, Texture texture) native;

  @DomName('WebGL2RenderingContext.blendColor')
  @DocsEditable()
  @Experimental() // untriaged
  void blendColor(num red, num green, num blue, num alpha) native;

  @DomName('WebGL2RenderingContext.blendEquation')
  @DocsEditable()
  @Experimental() // untriaged
  void blendEquation(int mode) native;

  @DomName('WebGL2RenderingContext.blendEquationSeparate')
  @DocsEditable()
  @Experimental() // untriaged
  void blendEquationSeparate(int modeRGB, int modeAlpha) native;

  @DomName('WebGL2RenderingContext.blendFunc')
  @DocsEditable()
  @Experimental() // untriaged
  void blendFunc(int sfactor, int dfactor) native;

  @DomName('WebGL2RenderingContext.blendFuncSeparate')
  @DocsEditable()
  @Experimental() // untriaged
  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha)
      native;

  @DomName('WebGL2RenderingContext.bufferData')
  @DocsEditable()
  @Experimental() // untriaged
  void bufferData(int target, data_OR_size, int usage) native;

  @DomName('WebGL2RenderingContext.bufferSubData')
  @DocsEditable()
  @Experimental() // untriaged
  void bufferSubData(int target, int offset, data) native;

  @DomName('WebGL2RenderingContext.checkFramebufferStatus')
  @DocsEditable()
  @Experimental() // untriaged
  int checkFramebufferStatus(int target) native;

  @DomName('WebGL2RenderingContext.clear')
  @DocsEditable()
  @Experimental() // untriaged
  void clear(int mask) native;

  @DomName('WebGL2RenderingContext.clearColor')
  @DocsEditable()
  @Experimental() // untriaged
  void clearColor(num red, num green, num blue, num alpha) native;

  @DomName('WebGL2RenderingContext.clearDepth')
  @DocsEditable()
  @Experimental() // untriaged
  void clearDepth(num depth) native;

  @DomName('WebGL2RenderingContext.clearStencil')
  @DocsEditable()
  @Experimental() // untriaged
  void clearStencil(int s) native;

  @DomName('WebGL2RenderingContext.colorMask')
  @DocsEditable()
  @Experimental() // untriaged
  void colorMask(bool red, bool green, bool blue, bool alpha) native;

  @DomName('WebGL2RenderingContext.commit')
  @DocsEditable()
  @Experimental() // untriaged
  Future commit() => promiseToFuture(JS("", "#.commit()", this));

  @DomName('WebGL2RenderingContext.compileShader')
  @DocsEditable()
  @Experimental() // untriaged
  void compileShader(Shader shader) native;

  @DomName('WebGL2RenderingContext.compressedTexImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexImage2D(int target, int level, int internalformat,
      int width, int height, int border, TypedData data) native;

  @DomName('WebGL2RenderingContext.compressedTexSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset,
      int width, int height, int format, TypedData data) native;

  @DomName('WebGL2RenderingContext.copyTexImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void copyTexImage2D(int target, int level, int internalformat, int x, int y,
      int width, int height, int border) native;

  @DomName('WebGL2RenderingContext.copyTexSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x,
      int y, int width, int height) native;

  @DomName('WebGL2RenderingContext.createBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  Buffer createBuffer() native;

  @DomName('WebGL2RenderingContext.createFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  Framebuffer createFramebuffer() native;

  @DomName('WebGL2RenderingContext.createProgram')
  @DocsEditable()
  @Experimental() // untriaged
  Program createProgram() native;

  @DomName('WebGL2RenderingContext.createRenderbuffer')
  @DocsEditable()
  @Experimental() // untriaged
  Renderbuffer createRenderbuffer() native;

  @DomName('WebGL2RenderingContext.createShader')
  @DocsEditable()
  @Experimental() // untriaged
  Shader createShader(int type) native;

  @DomName('WebGL2RenderingContext.createTexture')
  @DocsEditable()
  @Experimental() // untriaged
  Texture createTexture() native;

  @DomName('WebGL2RenderingContext.cullFace')
  @DocsEditable()
  @Experimental() // untriaged
  void cullFace(int mode) native;

  @DomName('WebGL2RenderingContext.deleteBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteBuffer(Buffer buffer) native;

  @DomName('WebGL2RenderingContext.deleteFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteFramebuffer(Framebuffer framebuffer) native;

  @DomName('WebGL2RenderingContext.deleteProgram')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteProgram(Program program) native;

  @DomName('WebGL2RenderingContext.deleteRenderbuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteRenderbuffer(Renderbuffer renderbuffer) native;

  @DomName('WebGL2RenderingContext.deleteShader')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteShader(Shader shader) native;

  @DomName('WebGL2RenderingContext.deleteTexture')
  @DocsEditable()
  @Experimental() // untriaged
  void deleteTexture(Texture texture) native;

  @DomName('WebGL2RenderingContext.depthFunc')
  @DocsEditable()
  @Experimental() // untriaged
  void depthFunc(int func) native;

  @DomName('WebGL2RenderingContext.depthMask')
  @DocsEditable()
  @Experimental() // untriaged
  void depthMask(bool flag) native;

  @DomName('WebGL2RenderingContext.depthRange')
  @DocsEditable()
  @Experimental() // untriaged
  void depthRange(num zNear, num zFar) native;

  @DomName('WebGL2RenderingContext.detachShader')
  @DocsEditable()
  @Experimental() // untriaged
  void detachShader(Program program, Shader shader) native;

  @DomName('WebGL2RenderingContext.disable')
  @DocsEditable()
  @Experimental() // untriaged
  void disable(int cap) native;

  @DomName('WebGL2RenderingContext.disableVertexAttribArray')
  @DocsEditable()
  @Experimental() // untriaged
  void disableVertexAttribArray(int index) native;

  @DomName('WebGL2RenderingContext.drawArrays')
  @DocsEditable()
  @Experimental() // untriaged
  void drawArrays(int mode, int first, int count) native;

  @DomName('WebGL2RenderingContext.drawElements')
  @DocsEditable()
  @Experimental() // untriaged
  void drawElements(int mode, int count, int type, int offset) native;

  @DomName('WebGL2RenderingContext.enable')
  @DocsEditable()
  @Experimental() // untriaged
  void enable(int cap) native;

  @DomName('WebGL2RenderingContext.enableVertexAttribArray')
  @DocsEditable()
  @Experimental() // untriaged
  void enableVertexAttribArray(int index) native;

  @DomName('WebGL2RenderingContext.finish')
  @DocsEditable()
  @Experimental() // untriaged
  void finish() native;

  @DomName('WebGL2RenderingContext.flush')
  @DocsEditable()
  @Experimental() // untriaged
  void flush() native;

  @DomName('WebGL2RenderingContext.framebufferRenderbuffer')
  @DocsEditable()
  @Experimental() // untriaged
  void framebufferRenderbuffer(int target, int attachment,
      int renderbuffertarget, Renderbuffer renderbuffer) native;

  @DomName('WebGL2RenderingContext.framebufferTexture2D')
  @DocsEditable()
  @Experimental() // untriaged
  void framebufferTexture2D(int target, int attachment, int textarget,
      Texture texture, int level) native;

  @DomName('WebGL2RenderingContext.frontFace')
  @DocsEditable()
  @Experimental() // untriaged
  void frontFace(int mode) native;

  @DomName('WebGL2RenderingContext.generateMipmap')
  @DocsEditable()
  @Experimental() // untriaged
  void generateMipmap(int target) native;

  @DomName('WebGL2RenderingContext.getActiveAttrib')
  @DocsEditable()
  @Experimental() // untriaged
  ActiveInfo getActiveAttrib(Program program, int index) native;

  @DomName('WebGL2RenderingContext.getActiveUniform')
  @DocsEditable()
  @Experimental() // untriaged
  ActiveInfo getActiveUniform(Program program, int index) native;

  @DomName('WebGL2RenderingContext.getAttachedShaders')
  @DocsEditable()
  @Experimental() // untriaged
  List<Shader> getAttachedShaders(Program program) native;

  @DomName('WebGL2RenderingContext.getAttribLocation')
  @DocsEditable()
  @Experimental() // untriaged
  int getAttribLocation(Program program, String name) native;

  @DomName('WebGL2RenderingContext.getBufferParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getBufferParameter(int target, int pname) native;

  @DomName('WebGL2RenderingContext.getContextAttributes')
  @DocsEditable()
  @Experimental() // untriaged
  Map getContextAttributes() {
    return convertNativeToDart_Dictionary(_getContextAttributes_1());
  }

  @JSName('getContextAttributes')
  @DomName('WebGL2RenderingContext.getContextAttributes')
  @DocsEditable()
  @Experimental() // untriaged
  _getContextAttributes_1() native;

  @DomName('WebGL2RenderingContext.getError')
  @DocsEditable()
  @Experimental() // untriaged
  int getError() native;

  @DomName('WebGL2RenderingContext.getExtension')
  @DocsEditable()
  @Experimental() // untriaged
  Object getExtension(String name) native;

  @DomName('WebGL2RenderingContext.getFramebufferAttachmentParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getFramebufferAttachmentParameter(
      int target, int attachment, int pname) native;

  @DomName('WebGL2RenderingContext.getParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getParameter(int pname) native;

  @DomName('WebGL2RenderingContext.getProgramInfoLog')
  @DocsEditable()
  @Experimental() // untriaged
  String getProgramInfoLog(Program program) native;

  @DomName('WebGL2RenderingContext.getProgramParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getProgramParameter(Program program, int pname) native;

  @DomName('WebGL2RenderingContext.getRenderbufferParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getRenderbufferParameter(int target, int pname) native;

  @DomName('WebGL2RenderingContext.getShaderInfoLog')
  @DocsEditable()
  @Experimental() // untriaged
  String getShaderInfoLog(Shader shader) native;

  @DomName('WebGL2RenderingContext.getShaderParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getShaderParameter(Shader shader, int pname) native;

  @DomName('WebGL2RenderingContext.getShaderPrecisionFormat')
  @DocsEditable()
  @Experimental() // untriaged
  ShaderPrecisionFormat getShaderPrecisionFormat(
      int shadertype, int precisiontype) native;

  @DomName('WebGL2RenderingContext.getShaderSource')
  @DocsEditable()
  @Experimental() // untriaged
  String getShaderSource(Shader shader) native;

  @DomName('WebGL2RenderingContext.getSupportedExtensions')
  @DocsEditable()
  @Experimental() // untriaged
  List<String> getSupportedExtensions() native;

  @DomName('WebGL2RenderingContext.getTexParameter')
  @DocsEditable()
  @Experimental() // untriaged
  Object getTexParameter(int target, int pname) native;

  @DomName('WebGL2RenderingContext.getUniform')
  @DocsEditable()
  @Experimental() // untriaged
  Object getUniform(Program program, UniformLocation location) native;

  @DomName('WebGL2RenderingContext.getUniformLocation')
  @DocsEditable()
  @Experimental() // untriaged
  UniformLocation getUniformLocation(Program program, String name) native;

  @DomName('WebGL2RenderingContext.getVertexAttrib')
  @DocsEditable()
  @Experimental() // untriaged
  Object getVertexAttrib(int index, int pname) native;

  @DomName('WebGL2RenderingContext.getVertexAttribOffset')
  @DocsEditable()
  @Experimental() // untriaged
  int getVertexAttribOffset(int index, int pname) native;

  @DomName('WebGL2RenderingContext.hint')
  @DocsEditable()
  @Experimental() // untriaged
  void hint(int target, int mode) native;

  @DomName('WebGL2RenderingContext.isBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  bool isBuffer(Buffer buffer) native;

  @DomName('WebGL2RenderingContext.isContextLost')
  @DocsEditable()
  @Experimental() // untriaged
  bool isContextLost() native;

  @DomName('WebGL2RenderingContext.isEnabled')
  @DocsEditable()
  @Experimental() // untriaged
  bool isEnabled(int cap) native;

  @DomName('WebGL2RenderingContext.isFramebuffer')
  @DocsEditable()
  @Experimental() // untriaged
  bool isFramebuffer(Framebuffer framebuffer) native;

  @DomName('WebGL2RenderingContext.isProgram')
  @DocsEditable()
  @Experimental() // untriaged
  bool isProgram(Program program) native;

  @DomName('WebGL2RenderingContext.isRenderbuffer')
  @DocsEditable()
  @Experimental() // untriaged
  bool isRenderbuffer(Renderbuffer renderbuffer) native;

  @DomName('WebGL2RenderingContext.isShader')
  @DocsEditable()
  @Experimental() // untriaged
  bool isShader(Shader shader) native;

  @DomName('WebGL2RenderingContext.isTexture')
  @DocsEditable()
  @Experimental() // untriaged
  bool isTexture(Texture texture) native;

  @DomName('WebGL2RenderingContext.lineWidth')
  @DocsEditable()
  @Experimental() // untriaged
  void lineWidth(num width) native;

  @DomName('WebGL2RenderingContext.linkProgram')
  @DocsEditable()
  @Experimental() // untriaged
  void linkProgram(Program program) native;

  @DomName('WebGL2RenderingContext.pixelStorei')
  @DocsEditable()
  @Experimental() // untriaged
  void pixelStorei(int pname, int param) native;

  @DomName('WebGL2RenderingContext.polygonOffset')
  @DocsEditable()
  @Experimental() // untriaged
  void polygonOffset(num factor, num units) native;

  @JSName('readPixels')
  @DomName('WebGL2RenderingContext.readPixels')
  @DocsEditable()
  @Experimental() // untriaged
  void _readPixels(int x, int y, int width, int height, int format, int type,
      TypedData pixels) native;

  @DomName('WebGL2RenderingContext.renderbufferStorage')
  @DocsEditable()
  @Experimental() // untriaged
  void renderbufferStorage(
      int target, int internalformat, int width, int height) native;

  @DomName('WebGL2RenderingContext.sampleCoverage')
  @DocsEditable()
  @Experimental() // untriaged
  void sampleCoverage(num value, bool invert) native;

  @DomName('WebGL2RenderingContext.scissor')
  @DocsEditable()
  @Experimental() // untriaged
  void scissor(int x, int y, int width, int height) native;

  @DomName('WebGL2RenderingContext.shaderSource')
  @DocsEditable()
  @Experimental() // untriaged
  void shaderSource(Shader shader, String string) native;

  @DomName('WebGL2RenderingContext.stencilFunc')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilFunc(int func, int ref, int mask) native;

  @DomName('WebGL2RenderingContext.stencilFuncSeparate')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  @DomName('WebGL2RenderingContext.stencilMask')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilMask(int mask) native;

  @DomName('WebGL2RenderingContext.stencilMaskSeparate')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilMaskSeparate(int face, int mask) native;

  @DomName('WebGL2RenderingContext.stencilOp')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilOp(int fail, int zfail, int zpass) native;

  @DomName('WebGL2RenderingContext.stencilOpSeparate')
  @DocsEditable()
  @Experimental() // untriaged
  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void texImage2D(
      int target,
      int level,
      int internalformat,
      int format_OR_width,
      int height_OR_type,
      bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video,
      [int format,
      int type,
      TypedData pixels]) {
    if (type != null &&
        format != null &&
        (bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video is int)) {
      _texImage2D_1(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video,
          format,
          type,
          pixels);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData) &&
        format == null &&
        type == null &&
        pixels == null) {
      var pixels_1 = convertDartToNative_ImageData(
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      _texImage2D_2(target, level, internalformat, format_OR_width,
          height_OR_type, pixels_1);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is ImageElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_3(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is CanvasElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_4(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is VideoElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_5(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is ImageBitmap) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_6(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D_1(target, level, internalformat, width, height, int border,
      format, type, TypedData pixels) native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D_2(target, level, internalformat, format, type, pixels)
      native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D_3(
      target, level, internalformat, format, type, ImageElement image) native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D_4(
      target, level, internalformat, format, type, CanvasElement canvas) native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D_5(
      target, level, internalformat, format, type, VideoElement video) native;
  @JSName('texImage2D')
  @DomName('WebGL2RenderingContext.texImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texImage2D_6(
      target, level, internalformat, format, type, ImageBitmap bitmap) native;

  @DomName('WebGL2RenderingContext.texParameterf')
  @DocsEditable()
  @Experimental() // untriaged
  void texParameterf(int target, int pname, num param) native;

  @DomName('WebGL2RenderingContext.texParameteri')
  @DocsEditable()
  @Experimental() // untriaged
  void texParameteri(int target, int pname, int param) native;

  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void texSubImage2D(
      int target,
      int level,
      int xoffset,
      int yoffset,
      int format_OR_width,
      int height_OR_type,
      bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video,
      [int type,
      TypedData pixels]) {
    if (type != null &&
        (bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is int)) {
      _texSubImage2D_1(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video,
          type,
          pixels);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData) &&
        type == null &&
        pixels == null) {
      var pixels_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width,
          height_OR_type, pixels_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is ImageElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_3(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is CanvasElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_4(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is VideoElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_5(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is ImageBitmap) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_6(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D_1(target, level, xoffset, yoffset, width, height,
      int format, type, TypedData pixels) native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D_2(target, level, xoffset, yoffset, format, type, pixels)
      native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D_3(
      target, level, xoffset, yoffset, format, type, ImageElement image) native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D_4(target, level, xoffset, yoffset, format, type,
      CanvasElement canvas) native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D_5(
      target, level, xoffset, yoffset, format, type, VideoElement video) native;
  @JSName('texSubImage2D')
  @DomName('WebGL2RenderingContext.texSubImage2D')
  @DocsEditable()
  @Experimental() // untriaged
  void _texSubImage2D_6(
      target, level, xoffset, yoffset, format, type, ImageBitmap bitmap) native;

  @DomName('WebGL2RenderingContext.uniform1f')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1f(UniformLocation location, num x) native;

  @DomName('WebGL2RenderingContext.uniform1fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1fv(UniformLocation location, v) native;

  @DomName('WebGL2RenderingContext.uniform1i')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1i(UniformLocation location, int x) native;

  @DomName('WebGL2RenderingContext.uniform1iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform1iv(UniformLocation location, v) native;

  @DomName('WebGL2RenderingContext.uniform2f')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2f(UniformLocation location, num x, num y) native;

  @DomName('WebGL2RenderingContext.uniform2fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2fv(UniformLocation location, v) native;

  @DomName('WebGL2RenderingContext.uniform2i')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2i(UniformLocation location, int x, int y) native;

  @DomName('WebGL2RenderingContext.uniform2iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform2iv(UniformLocation location, v) native;

  @DomName('WebGL2RenderingContext.uniform3f')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3f(UniformLocation location, num x, num y, num z) native;

  @DomName('WebGL2RenderingContext.uniform3fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3fv(UniformLocation location, v) native;

  @DomName('WebGL2RenderingContext.uniform3i')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3i(UniformLocation location, int x, int y, int z) native;

  @DomName('WebGL2RenderingContext.uniform3iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform3iv(UniformLocation location, v) native;

  @DomName('WebGL2RenderingContext.uniform4f')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4f(UniformLocation location, num x, num y, num z, num w) native;

  @DomName('WebGL2RenderingContext.uniform4fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4fv(UniformLocation location, v) native;

  @DomName('WebGL2RenderingContext.uniform4i')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4i(UniformLocation location, int x, int y, int z, int w) native;

  @DomName('WebGL2RenderingContext.uniform4iv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniform4iv(UniformLocation location, v) native;

  @DomName('WebGL2RenderingContext.uniformMatrix2fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix2fv(UniformLocation location, bool transpose, array) native;

  @DomName('WebGL2RenderingContext.uniformMatrix3fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix3fv(UniformLocation location, bool transpose, array) native;

  @DomName('WebGL2RenderingContext.uniformMatrix4fv')
  @DocsEditable()
  @Experimental() // untriaged
  void uniformMatrix4fv(UniformLocation location, bool transpose, array) native;

  @DomName('WebGL2RenderingContext.useProgram')
  @DocsEditable()
  @Experimental() // untriaged
  void useProgram(Program program) native;

  @DomName('WebGL2RenderingContext.validateProgram')
  @DocsEditable()
  @Experimental() // untriaged
  void validateProgram(Program program) native;

  @DomName('WebGL2RenderingContext.vertexAttrib1f')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib1f(int indx, num x) native;

  @DomName('WebGL2RenderingContext.vertexAttrib1fv')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib1fv(int indx, values) native;

  @DomName('WebGL2RenderingContext.vertexAttrib2f')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib2f(int indx, num x, num y) native;

  @DomName('WebGL2RenderingContext.vertexAttrib2fv')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib2fv(int indx, values) native;

  @DomName('WebGL2RenderingContext.vertexAttrib3f')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib3f(int indx, num x, num y, num z) native;

  @DomName('WebGL2RenderingContext.vertexAttrib3fv')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib3fv(int indx, values) native;

  @DomName('WebGL2RenderingContext.vertexAttrib4f')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  @DomName('WebGL2RenderingContext.vertexAttrib4fv')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttrib4fv(int indx, values) native;

  @DomName('WebGL2RenderingContext.vertexAttribPointer')
  @DocsEditable()
  @Experimental() // untriaged
  void vertexAttribPointer(int indx, int size, int type, bool normalized,
      int stride, int offset) native;

  @DomName('WebGL2RenderingContext.viewport')
  @DocsEditable()
  @Experimental() // untriaged
  void viewport(int x, int y, int width, int height) native;

  @DomName('WebGLRenderingContext2.readPixels')
  @DocsEditable()
  void readPixels(int x, int y, int width, int height, int format, int type,
      TypedData pixels) {
    _readPixels(x, y, width, height, format, type, pixels);
  }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLSampler')
@Experimental() // untriaged
@Native("WebGLSampler")
class Sampler extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Sampler._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLShader')
@Native("WebGLShader")
class Shader extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Shader._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLShaderPrecisionFormat')
@Native("WebGLShaderPrecisionFormat")
class ShaderPrecisionFormat extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory ShaderPrecisionFormat._() {
    throw new UnsupportedError("Not supported");
  }

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
@DomName('WebGLSync')
@Experimental() // untriaged
@Native("WebGLSync")
class Sync extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Sync._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLTexture')
@Native("WebGLTexture")
class Texture extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Texture._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WebGLTexture.lastUploadedVideoFrameWasSkipped')
  @DocsEditable()
  @Experimental() // untriaged
  final bool lastUploadedVideoFrameWasSkipped;

  @DomName('WebGLTexture.lastUploadedVideoHeight')
  @DocsEditable()
  @Experimental() // untriaged
  final int lastUploadedVideoHeight;

  @DomName('WebGLTexture.lastUploadedVideoTimestamp')
  @DocsEditable()
  @Experimental() // untriaged
  final num lastUploadedVideoTimestamp;

  @DomName('WebGLTexture.lastUploadedVideoWidth')
  @DocsEditable()
  @Experimental() // untriaged
  final int lastUploadedVideoWidth;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLTimerQueryEXT')
@Experimental() // untriaged
@Native("WebGLTimerQueryEXT")
class TimerQueryExt extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory TimerQueryExt._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLTransformFeedback')
@Experimental() // untriaged
@Native("WebGLTransformFeedback")
class TransformFeedback extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory TransformFeedback._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLUniformLocation')
@Native("WebGLUniformLocation")
class UniformLocation extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory UniformLocation._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLVertexArrayObject')
@Experimental() // untriaged
@Native("WebGLVertexArrayObject")
class VertexArrayObject extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory VertexArrayObject._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLVertexArrayObjectOES')
// http://www.khronos.org/registry/webgl/extensions/OES_vertex_array_object/
@Experimental() // experimental
@Native("WebGLVertexArrayObjectOES")
class VertexArrayObjectOes extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory VertexArrayObjectOes._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Amalgamation of the WebGL constants from the IDL interfaces in
/// WebGLRenderingContextBase, WebGL2RenderingContextBase, & WebGLDrawBuffers.
/// Because the RenderingContextBase interfaces are hidden they would be
/// replicated in more than one class (e.g., RenderingContext and
/// RenderingContext2) to prevent that duplication these 600+ constants are
/// defined in one abstract class (WebGL).
@DomName('WebGL')
@Experimental() // untriaged
@Native("WebGL")
abstract class WebGL {
  // To suppress missing implicit constructor warnings.
  factory WebGL._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WebGL.ACTIVE_ATTRIBUTES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ACTIVE_ATTRIBUTES = 0x8B89;

  @DomName('WebGL.ACTIVE_TEXTURE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ACTIVE_TEXTURE = 0x84E0;

  @DomName('WebGL.ACTIVE_UNIFORMS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ACTIVE_UNIFORMS = 0x8B86;

  @DomName('WebGL.ACTIVE_UNIFORM_BLOCKS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ACTIVE_UNIFORM_BLOCKS = 0x8A36;

  @DomName('WebGL.ALIASED_LINE_WIDTH_RANGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALIASED_LINE_WIDTH_RANGE = 0x846E;

  @DomName('WebGL.ALIASED_POINT_SIZE_RANGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALIASED_POINT_SIZE_RANGE = 0x846D;

  @DomName('WebGL.ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALPHA = 0x1906;

  @DomName('WebGL.ALPHA_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALPHA_BITS = 0x0D55;

  @DomName('WebGL.ALREADY_SIGNALED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALREADY_SIGNALED = 0x911A;

  @DomName('WebGL.ALWAYS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ALWAYS = 0x0207;

  @DomName('WebGL.ANY_SAMPLES_PASSED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ANY_SAMPLES_PASSED = 0x8C2F;

  @DomName('WebGL.ANY_SAMPLES_PASSED_CONSERVATIVE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ANY_SAMPLES_PASSED_CONSERVATIVE = 0x8D6A;

  @DomName('WebGL.ARRAY_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ARRAY_BUFFER = 0x8892;

  @DomName('WebGL.ARRAY_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ARRAY_BUFFER_BINDING = 0x8894;

  @DomName('WebGL.ATTACHED_SHADERS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ATTACHED_SHADERS = 0x8B85;

  @DomName('WebGL.BACK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BACK = 0x0405;

  @DomName('WebGL.BLEND')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND = 0x0BE2;

  @DomName('WebGL.BLEND_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_COLOR = 0x8005;

  @DomName('WebGL.BLEND_DST_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_DST_ALPHA = 0x80CA;

  @DomName('WebGL.BLEND_DST_RGB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_DST_RGB = 0x80C8;

  @DomName('WebGL.BLEND_EQUATION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_EQUATION = 0x8009;

  @DomName('WebGL.BLEND_EQUATION_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_EQUATION_ALPHA = 0x883D;

  @DomName('WebGL.BLEND_EQUATION_RGB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_EQUATION_RGB = 0x8009;

  @DomName('WebGL.BLEND_SRC_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_SRC_ALPHA = 0x80CB;

  @DomName('WebGL.BLEND_SRC_RGB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLEND_SRC_RGB = 0x80C9;

  @DomName('WebGL.BLUE_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BLUE_BITS = 0x0D54;

  @DomName('WebGL.BOOL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BOOL = 0x8B56;

  @DomName('WebGL.BOOL_VEC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BOOL_VEC2 = 0x8B57;

  @DomName('WebGL.BOOL_VEC3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BOOL_VEC3 = 0x8B58;

  @DomName('WebGL.BOOL_VEC4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BOOL_VEC4 = 0x8B59;

  @DomName('WebGL.BROWSER_DEFAULT_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BROWSER_DEFAULT_WEBGL = 0x9244;

  @DomName('WebGL.BUFFER_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BUFFER_SIZE = 0x8764;

  @DomName('WebGL.BUFFER_USAGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BUFFER_USAGE = 0x8765;

  @DomName('WebGL.BYTE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int BYTE = 0x1400;

  @DomName('WebGL.CCW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CCW = 0x0901;

  @DomName('WebGL.CLAMP_TO_EDGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CLAMP_TO_EDGE = 0x812F;

  @DomName('WebGL.COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR = 0x1800;

  @DomName('WebGL.COLOR_ATTACHMENT0')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT0 = 0x8CE0;

  @DomName('WebGL.COLOR_ATTACHMENT0_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT0_WEBGL = 0x8CE0;

  @DomName('WebGL.COLOR_ATTACHMENT1')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT1 = 0x8CE1;

  @DomName('WebGL.COLOR_ATTACHMENT10')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT10 = 0x8CEA;

  @DomName('WebGL.COLOR_ATTACHMENT10_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT10_WEBGL = 0x8CEA;

  @DomName('WebGL.COLOR_ATTACHMENT11')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT11 = 0x8CEB;

  @DomName('WebGL.COLOR_ATTACHMENT11_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT11_WEBGL = 0x8CEB;

  @DomName('WebGL.COLOR_ATTACHMENT12')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT12 = 0x8CEC;

  @DomName('WebGL.COLOR_ATTACHMENT12_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT12_WEBGL = 0x8CEC;

  @DomName('WebGL.COLOR_ATTACHMENT13')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT13 = 0x8CED;

  @DomName('WebGL.COLOR_ATTACHMENT13_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT13_WEBGL = 0x8CED;

  @DomName('WebGL.COLOR_ATTACHMENT14')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT14 = 0x8CEE;

  @DomName('WebGL.COLOR_ATTACHMENT14_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT14_WEBGL = 0x8CEE;

  @DomName('WebGL.COLOR_ATTACHMENT15')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT15 = 0x8CEF;

  @DomName('WebGL.COLOR_ATTACHMENT15_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT15_WEBGL = 0x8CEF;

  @DomName('WebGL.COLOR_ATTACHMENT1_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT1_WEBGL = 0x8CE1;

  @DomName('WebGL.COLOR_ATTACHMENT2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT2 = 0x8CE2;

  @DomName('WebGL.COLOR_ATTACHMENT2_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT2_WEBGL = 0x8CE2;

  @DomName('WebGL.COLOR_ATTACHMENT3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT3 = 0x8CE3;

  @DomName('WebGL.COLOR_ATTACHMENT3_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT3_WEBGL = 0x8CE3;

  @DomName('WebGL.COLOR_ATTACHMENT4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT4 = 0x8CE4;

  @DomName('WebGL.COLOR_ATTACHMENT4_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT4_WEBGL = 0x8CE4;

  @DomName('WebGL.COLOR_ATTACHMENT5')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT5 = 0x8CE5;

  @DomName('WebGL.COLOR_ATTACHMENT5_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT5_WEBGL = 0x8CE5;

  @DomName('WebGL.COLOR_ATTACHMENT6')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT6 = 0x8CE6;

  @DomName('WebGL.COLOR_ATTACHMENT6_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT6_WEBGL = 0x8CE6;

  @DomName('WebGL.COLOR_ATTACHMENT7')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT7 = 0x8CE7;

  @DomName('WebGL.COLOR_ATTACHMENT7_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT7_WEBGL = 0x8CE7;

  @DomName('WebGL.COLOR_ATTACHMENT8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT8 = 0x8CE8;

  @DomName('WebGL.COLOR_ATTACHMENT8_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT8_WEBGL = 0x8CE8;

  @DomName('WebGL.COLOR_ATTACHMENT9')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT9 = 0x8CE9;

  @DomName('WebGL.COLOR_ATTACHMENT9_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_ATTACHMENT9_WEBGL = 0x8CE9;

  @DomName('WebGL.COLOR_BUFFER_BIT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_BUFFER_BIT = 0x00004000;

  @DomName('WebGL.COLOR_CLEAR_VALUE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_CLEAR_VALUE = 0x0C22;

  @DomName('WebGL.COLOR_WRITEMASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COLOR_WRITEMASK = 0x0C23;

  @DomName('WebGL.COMPARE_REF_TO_TEXTURE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPARE_REF_TO_TEXTURE = 0x884E;

  @DomName('WebGL.COMPILE_STATUS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPILE_STATUS = 0x8B81;

  @DomName('WebGL.COMPRESSED_TEXTURE_FORMATS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COMPRESSED_TEXTURE_FORMATS = 0x86A3;

  @DomName('WebGL.CONDITION_SATISFIED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CONDITION_SATISFIED = 0x911C;

  @DomName('WebGL.CONSTANT_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CONSTANT_ALPHA = 0x8003;

  @DomName('WebGL.CONSTANT_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CONSTANT_COLOR = 0x8001;

  @DomName('WebGL.CONTEXT_LOST_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CONTEXT_LOST_WEBGL = 0x9242;

  @DomName('WebGL.COPY_READ_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COPY_READ_BUFFER = 0x8F36;

  @DomName('WebGL.COPY_READ_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COPY_READ_BUFFER_BINDING = 0x8F36;

  @DomName('WebGL.COPY_WRITE_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COPY_WRITE_BUFFER = 0x8F37;

  @DomName('WebGL.COPY_WRITE_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int COPY_WRITE_BUFFER_BINDING = 0x8F37;

  @DomName('WebGL.CULL_FACE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CULL_FACE = 0x0B44;

  @DomName('WebGL.CULL_FACE_MODE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CULL_FACE_MODE = 0x0B45;

  @DomName('WebGL.CURRENT_PROGRAM')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CURRENT_PROGRAM = 0x8B8D;

  @DomName('WebGL.CURRENT_QUERY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CURRENT_QUERY = 0x8865;

  @DomName('WebGL.CURRENT_VERTEX_ATTRIB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CURRENT_VERTEX_ATTRIB = 0x8626;

  @DomName('WebGL.CW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int CW = 0x0900;

  @DomName('WebGL.DECR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DECR = 0x1E03;

  @DomName('WebGL.DECR_WRAP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DECR_WRAP = 0x8508;

  @DomName('WebGL.DELETE_STATUS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DELETE_STATUS = 0x8B80;

  @DomName('WebGL.DEPTH')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH = 0x1801;

  @DomName('WebGL.DEPTH24_STENCIL8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH24_STENCIL8 = 0x88F0;

  @DomName('WebGL.DEPTH32F_STENCIL8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH32F_STENCIL8 = 0x8CAD;

  @DomName('WebGL.DEPTH_ATTACHMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_ATTACHMENT = 0x8D00;

  @DomName('WebGL.DEPTH_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_BITS = 0x0D56;

  @DomName('WebGL.DEPTH_BUFFER_BIT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_BUFFER_BIT = 0x00000100;

  @DomName('WebGL.DEPTH_CLEAR_VALUE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_CLEAR_VALUE = 0x0B73;

  @DomName('WebGL.DEPTH_COMPONENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_COMPONENT = 0x1902;

  @DomName('WebGL.DEPTH_COMPONENT16')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_COMPONENT16 = 0x81A5;

  @DomName('WebGL.DEPTH_COMPONENT24')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_COMPONENT24 = 0x81A6;

  @DomName('WebGL.DEPTH_COMPONENT32F')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_COMPONENT32F = 0x8CAC;

  @DomName('WebGL.DEPTH_FUNC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_FUNC = 0x0B74;

  @DomName('WebGL.DEPTH_RANGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_RANGE = 0x0B70;

  @DomName('WebGL.DEPTH_STENCIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_STENCIL = 0x84F9;

  @DomName('WebGL.DEPTH_STENCIL_ATTACHMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_STENCIL_ATTACHMENT = 0x821A;

  @DomName('WebGL.DEPTH_TEST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_TEST = 0x0B71;

  @DomName('WebGL.DEPTH_WRITEMASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DEPTH_WRITEMASK = 0x0B72;

  @DomName('WebGL.DITHER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DITHER = 0x0BD0;

  @DomName('WebGL.DONT_CARE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DONT_CARE = 0x1100;

  @DomName('WebGL.DRAW_BUFFER0')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER0 = 0x8825;

  @DomName('WebGL.DRAW_BUFFER0_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER0_WEBGL = 0x8825;

  @DomName('WebGL.DRAW_BUFFER1')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER1 = 0x8826;

  @DomName('WebGL.DRAW_BUFFER10')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER10 = 0x882F;

  @DomName('WebGL.DRAW_BUFFER10_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER10_WEBGL = 0x882F;

  @DomName('WebGL.DRAW_BUFFER11')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER11 = 0x8830;

  @DomName('WebGL.DRAW_BUFFER11_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER11_WEBGL = 0x8830;

  @DomName('WebGL.DRAW_BUFFER12')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER12 = 0x8831;

  @DomName('WebGL.DRAW_BUFFER12_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER12_WEBGL = 0x8831;

  @DomName('WebGL.DRAW_BUFFER13')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER13 = 0x8832;

  @DomName('WebGL.DRAW_BUFFER13_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER13_WEBGL = 0x8832;

  @DomName('WebGL.DRAW_BUFFER14')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER14 = 0x8833;

  @DomName('WebGL.DRAW_BUFFER14_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER14_WEBGL = 0x8833;

  @DomName('WebGL.DRAW_BUFFER15')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER15 = 0x8834;

  @DomName('WebGL.DRAW_BUFFER15_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER15_WEBGL = 0x8834;

  @DomName('WebGL.DRAW_BUFFER1_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER1_WEBGL = 0x8826;

  @DomName('WebGL.DRAW_BUFFER2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER2 = 0x8827;

  @DomName('WebGL.DRAW_BUFFER2_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER2_WEBGL = 0x8827;

  @DomName('WebGL.DRAW_BUFFER3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER3 = 0x8828;

  @DomName('WebGL.DRAW_BUFFER3_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER3_WEBGL = 0x8828;

  @DomName('WebGL.DRAW_BUFFER4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER4 = 0x8829;

  @DomName('WebGL.DRAW_BUFFER4_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER4_WEBGL = 0x8829;

  @DomName('WebGL.DRAW_BUFFER5')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER5 = 0x882A;

  @DomName('WebGL.DRAW_BUFFER5_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER5_WEBGL = 0x882A;

  @DomName('WebGL.DRAW_BUFFER6')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER6 = 0x882B;

  @DomName('WebGL.DRAW_BUFFER6_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER6_WEBGL = 0x882B;

  @DomName('WebGL.DRAW_BUFFER7')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER7 = 0x882C;

  @DomName('WebGL.DRAW_BUFFER7_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER7_WEBGL = 0x882C;

  @DomName('WebGL.DRAW_BUFFER8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER8 = 0x882D;

  @DomName('WebGL.DRAW_BUFFER8_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER8_WEBGL = 0x882D;

  @DomName('WebGL.DRAW_BUFFER9')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER9 = 0x882E;

  @DomName('WebGL.DRAW_BUFFER9_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_BUFFER9_WEBGL = 0x882E;

  @DomName('WebGL.DRAW_FRAMEBUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_FRAMEBUFFER = 0x8CA9;

  @DomName('WebGL.DRAW_FRAMEBUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DRAW_FRAMEBUFFER_BINDING = 0x8CA6;

  @DomName('WebGL.DST_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DST_ALPHA = 0x0304;

  @DomName('WebGL.DST_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DST_COLOR = 0x0306;

  @DomName('WebGL.DYNAMIC_COPY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DYNAMIC_COPY = 0x88EA;

  @DomName('WebGL.DYNAMIC_DRAW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DYNAMIC_DRAW = 0x88E8;

  @DomName('WebGL.DYNAMIC_READ')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DYNAMIC_READ = 0x88E9;

  @DomName('WebGL.ELEMENT_ARRAY_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ELEMENT_ARRAY_BUFFER = 0x8893;

  @DomName('WebGL.ELEMENT_ARRAY_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;

  @DomName('WebGL.EQUAL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int EQUAL = 0x0202;

  @DomName('WebGL.FASTEST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FASTEST = 0x1101;

  @DomName('WebGL.FLOAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT = 0x1406;

  @DomName('WebGL.FLOAT_32_UNSIGNED_INT_24_8_REV')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_32_UNSIGNED_INT_24_8_REV = 0x8DAD;

  @DomName('WebGL.FLOAT_MAT2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT2 = 0x8B5A;

  @DomName('WebGL.FLOAT_MAT2x3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT2x3 = 0x8B65;

  @DomName('WebGL.FLOAT_MAT2x4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT2x4 = 0x8B66;

  @DomName('WebGL.FLOAT_MAT3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT3 = 0x8B5B;

  @DomName('WebGL.FLOAT_MAT3x2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT3x2 = 0x8B67;

  @DomName('WebGL.FLOAT_MAT3x4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT3x4 = 0x8B68;

  @DomName('WebGL.FLOAT_MAT4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT4 = 0x8B5C;

  @DomName('WebGL.FLOAT_MAT4x2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT4x2 = 0x8B69;

  @DomName('WebGL.FLOAT_MAT4x3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_MAT4x3 = 0x8B6A;

  @DomName('WebGL.FLOAT_VEC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_VEC2 = 0x8B50;

  @DomName('WebGL.FLOAT_VEC3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_VEC3 = 0x8B51;

  @DomName('WebGL.FLOAT_VEC4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FLOAT_VEC4 = 0x8B52;

  @DomName('WebGL.FRAGMENT_SHADER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAGMENT_SHADER = 0x8B30;

  @DomName('WebGL.FRAGMENT_SHADER_DERIVATIVE_HINT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B;

  @DomName('WebGL.FRAMEBUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER = 0x8D40;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_BLUE_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_GREEN_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_RED_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4;

  @DomName('WebGL.FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;

  @DomName('WebGL.FRAMEBUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_BINDING = 0x8CA6;

  @DomName('WebGL.FRAMEBUFFER_COMPLETE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_COMPLETE = 0x8CD5;

  @DomName('WebGL.FRAMEBUFFER_DEFAULT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_DEFAULT = 0x8218;

  @DomName('WebGL.FRAMEBUFFER_INCOMPLETE_ATTACHMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;

  @DomName('WebGL.FRAMEBUFFER_INCOMPLETE_DIMENSIONS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;

  @DomName('WebGL.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;

  @DomName('WebGL.FRAMEBUFFER_INCOMPLETE_MULTISAMPLE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56;

  @DomName('WebGL.FRAMEBUFFER_UNSUPPORTED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

  @DomName('WebGL.FRONT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRONT = 0x0404;

  @DomName('WebGL.FRONT_AND_BACK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRONT_AND_BACK = 0x0408;

  @DomName('WebGL.FRONT_FACE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FRONT_FACE = 0x0B46;

  @DomName('WebGL.FUNC_ADD')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FUNC_ADD = 0x8006;

  @DomName('WebGL.FUNC_REVERSE_SUBTRACT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FUNC_REVERSE_SUBTRACT = 0x800B;

  @DomName('WebGL.FUNC_SUBTRACT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int FUNC_SUBTRACT = 0x800A;

  @DomName('WebGL.GENERATE_MIPMAP_HINT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int GENERATE_MIPMAP_HINT = 0x8192;

  @DomName('WebGL.GEQUAL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int GEQUAL = 0x0206;

  @DomName('WebGL.GREATER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int GREATER = 0x0204;

  @DomName('WebGL.GREEN_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int GREEN_BITS = 0x0D53;

  @DomName('WebGL.HALF_FLOAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int HALF_FLOAT = 0x140B;

  @DomName('WebGL.HIGH_FLOAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int HIGH_FLOAT = 0x8DF2;

  @DomName('WebGL.HIGH_INT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int HIGH_INT = 0x8DF5;

  @DomName('WebGL.IMPLEMENTATION_COLOR_READ_FORMAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int IMPLEMENTATION_COLOR_READ_FORMAT = 0x8B9B;

  @DomName('WebGL.IMPLEMENTATION_COLOR_READ_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int IMPLEMENTATION_COLOR_READ_TYPE = 0x8B9A;

  @DomName('WebGL.INCR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INCR = 0x1E02;

  @DomName('WebGL.INCR_WRAP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INCR_WRAP = 0x8507;

  @DomName('WebGL.INT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT = 0x1404;

  @DomName('WebGL.INTERLEAVED_ATTRIBS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INTERLEAVED_ATTRIBS = 0x8C8C;

  @DomName('WebGL.INT_2_10_10_10_REV')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_2_10_10_10_REV = 0x8D9F;

  @DomName('WebGL.INT_SAMPLER_2D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_SAMPLER_2D = 0x8DCA;

  @DomName('WebGL.INT_SAMPLER_2D_ARRAY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_SAMPLER_2D_ARRAY = 0x8DCF;

  @DomName('WebGL.INT_SAMPLER_3D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_SAMPLER_3D = 0x8DCB;

  @DomName('WebGL.INT_SAMPLER_CUBE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_SAMPLER_CUBE = 0x8DCC;

  @DomName('WebGL.INT_VEC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_VEC2 = 0x8B53;

  @DomName('WebGL.INT_VEC3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_VEC3 = 0x8B54;

  @DomName('WebGL.INT_VEC4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INT_VEC4 = 0x8B55;

  @DomName('WebGL.INVALID_ENUM')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVALID_ENUM = 0x0500;

  @DomName('WebGL.INVALID_FRAMEBUFFER_OPERATION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVALID_FRAMEBUFFER_OPERATION = 0x0506;

  @DomName('WebGL.INVALID_INDEX')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVALID_INDEX = 0xFFFFFFFF;

  @DomName('WebGL.INVALID_OPERATION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVALID_OPERATION = 0x0502;

  @DomName('WebGL.INVALID_VALUE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVALID_VALUE = 0x0501;

  @DomName('WebGL.INVERT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int INVERT = 0x150A;

  @DomName('WebGL.KEEP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int KEEP = 0x1E00;

  @DomName('WebGL.LEQUAL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LEQUAL = 0x0203;

  @DomName('WebGL.LESS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LESS = 0x0201;

  @DomName('WebGL.LINEAR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINEAR = 0x2601;

  @DomName('WebGL.LINEAR_MIPMAP_LINEAR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINEAR_MIPMAP_LINEAR = 0x2703;

  @DomName('WebGL.LINEAR_MIPMAP_NEAREST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINEAR_MIPMAP_NEAREST = 0x2701;

  @DomName('WebGL.LINES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINES = 0x0001;

  @DomName('WebGL.LINE_LOOP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINE_LOOP = 0x0002;

  @DomName('WebGL.LINE_STRIP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINE_STRIP = 0x0003;

  @DomName('WebGL.LINE_WIDTH')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINE_WIDTH = 0x0B21;

  @DomName('WebGL.LINK_STATUS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LINK_STATUS = 0x8B82;

  @DomName('WebGL.LOW_FLOAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LOW_FLOAT = 0x8DF0;

  @DomName('WebGL.LOW_INT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LOW_INT = 0x8DF3;

  @DomName('WebGL.LUMINANCE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LUMINANCE = 0x1909;

  @DomName('WebGL.LUMINANCE_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int LUMINANCE_ALPHA = 0x190A;

  @DomName('WebGL.MAX')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX = 0x8008;

  @DomName('WebGL.MAX_3D_TEXTURE_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_3D_TEXTURE_SIZE = 0x8073;

  @DomName('WebGL.MAX_ARRAY_TEXTURE_LAYERS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_ARRAY_TEXTURE_LAYERS = 0x88FF;

  @DomName('WebGL.MAX_CLIENT_WAIT_TIMEOUT_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_CLIENT_WAIT_TIMEOUT_WEBGL = 0x9247;

  @DomName('WebGL.MAX_COLOR_ATTACHMENTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_COLOR_ATTACHMENTS = 0x8CDF;

  @DomName('WebGL.MAX_COLOR_ATTACHMENTS_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_COLOR_ATTACHMENTS_WEBGL = 0x8CDF;

  @DomName('WebGL.MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = 0x8A33;

  @DomName('WebGL.MAX_COMBINED_TEXTURE_IMAGE_UNITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;

  @DomName('WebGL.MAX_COMBINED_UNIFORM_BLOCKS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_COMBINED_UNIFORM_BLOCKS = 0x8A2E;

  @DomName('WebGL.MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = 0x8A31;

  @DomName('WebGL.MAX_CUBE_MAP_TEXTURE_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

  @DomName('WebGL.MAX_DRAW_BUFFERS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_DRAW_BUFFERS = 0x8824;

  @DomName('WebGL.MAX_DRAW_BUFFERS_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_DRAW_BUFFERS_WEBGL = 0x8824;

  @DomName('WebGL.MAX_ELEMENTS_INDICES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_ELEMENTS_INDICES = 0x80E9;

  @DomName('WebGL.MAX_ELEMENTS_VERTICES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_ELEMENTS_VERTICES = 0x80E8;

  @DomName('WebGL.MAX_ELEMENT_INDEX')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_ELEMENT_INDEX = 0x8D6B;

  @DomName('WebGL.MAX_FRAGMENT_INPUT_COMPONENTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_FRAGMENT_INPUT_COMPONENTS = 0x9125;

  @DomName('WebGL.MAX_FRAGMENT_UNIFORM_BLOCKS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_FRAGMENT_UNIFORM_BLOCKS = 0x8A2D;

  @DomName('WebGL.MAX_FRAGMENT_UNIFORM_COMPONENTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49;

  @DomName('WebGL.MAX_FRAGMENT_UNIFORM_VECTORS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;

  @DomName('WebGL.MAX_PROGRAM_TEXEL_OFFSET')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_PROGRAM_TEXEL_OFFSET = 0x8905;

  @DomName('WebGL.MAX_RENDERBUFFER_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_RENDERBUFFER_SIZE = 0x84E8;

  @DomName('WebGL.MAX_SAMPLES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_SAMPLES = 0x8D57;

  @DomName('WebGL.MAX_SERVER_WAIT_TIMEOUT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_SERVER_WAIT_TIMEOUT = 0x9111;

  @DomName('WebGL.MAX_TEXTURE_IMAGE_UNITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_TEXTURE_IMAGE_UNITS = 0x8872;

  @DomName('WebGL.MAX_TEXTURE_LOD_BIAS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_TEXTURE_LOD_BIAS = 0x84FD;

  @DomName('WebGL.MAX_TEXTURE_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_TEXTURE_SIZE = 0x0D33;

  @DomName('WebGL.MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS = 0x8C8A;

  @DomName('WebGL.MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS = 0x8C8B;

  @DomName('WebGL.MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS = 0x8C80;

  @DomName('WebGL.MAX_UNIFORM_BLOCK_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_UNIFORM_BLOCK_SIZE = 0x8A30;

  @DomName('WebGL.MAX_UNIFORM_BUFFER_BINDINGS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_UNIFORM_BUFFER_BINDINGS = 0x8A2F;

  @DomName('WebGL.MAX_VARYING_COMPONENTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VARYING_COMPONENTS = 0x8B4B;

  @DomName('WebGL.MAX_VARYING_VECTORS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VARYING_VECTORS = 0x8DFC;

  @DomName('WebGL.MAX_VERTEX_ATTRIBS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VERTEX_ATTRIBS = 0x8869;

  @DomName('WebGL.MAX_VERTEX_OUTPUT_COMPONENTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VERTEX_OUTPUT_COMPONENTS = 0x9122;

  @DomName('WebGL.MAX_VERTEX_TEXTURE_IMAGE_UNITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;

  @DomName('WebGL.MAX_VERTEX_UNIFORM_BLOCKS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VERTEX_UNIFORM_BLOCKS = 0x8A2B;

  @DomName('WebGL.MAX_VERTEX_UNIFORM_COMPONENTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VERTEX_UNIFORM_COMPONENTS = 0x8B4A;

  @DomName('WebGL.MAX_VERTEX_UNIFORM_VECTORS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;

  @DomName('WebGL.MAX_VIEWPORT_DIMS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MAX_VIEWPORT_DIMS = 0x0D3A;

  @DomName('WebGL.MEDIUM_FLOAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MEDIUM_FLOAT = 0x8DF1;

  @DomName('WebGL.MEDIUM_INT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MEDIUM_INT = 0x8DF4;

  @DomName('WebGL.MIN')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MIN = 0x8007;

  @DomName('WebGL.MIN_PROGRAM_TEXEL_OFFSET')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MIN_PROGRAM_TEXEL_OFFSET = 0x8904;

  @DomName('WebGL.MIRRORED_REPEAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int MIRRORED_REPEAT = 0x8370;

  @DomName('WebGL.NEAREST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NEAREST = 0x2600;

  @DomName('WebGL.NEAREST_MIPMAP_LINEAR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NEAREST_MIPMAP_LINEAR = 0x2702;

  @DomName('WebGL.NEAREST_MIPMAP_NEAREST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NEAREST_MIPMAP_NEAREST = 0x2700;

  @DomName('WebGL.NEVER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NEVER = 0x0200;

  @DomName('WebGL.NICEST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NICEST = 0x1102;

  @DomName('WebGL.NONE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NONE = 0;

  @DomName('WebGL.NOTEQUAL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NOTEQUAL = 0x0205;

  @DomName('WebGL.NO_ERROR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int NO_ERROR = 0;

  @DomName('WebGL.OBJECT_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int OBJECT_TYPE = 0x9112;

  @DomName('WebGL.ONE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE = 1;

  @DomName('WebGL.ONE_MINUS_CONSTANT_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_CONSTANT_ALPHA = 0x8004;

  @DomName('WebGL.ONE_MINUS_CONSTANT_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_CONSTANT_COLOR = 0x8002;

  @DomName('WebGL.ONE_MINUS_DST_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_DST_ALPHA = 0x0305;

  @DomName('WebGL.ONE_MINUS_DST_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_DST_COLOR = 0x0307;

  @DomName('WebGL.ONE_MINUS_SRC_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_SRC_ALPHA = 0x0303;

  @DomName('WebGL.ONE_MINUS_SRC_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ONE_MINUS_SRC_COLOR = 0x0301;

  @DomName('WebGL.OUT_OF_MEMORY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int OUT_OF_MEMORY = 0x0505;

  @DomName('WebGL.PACK_ALIGNMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int PACK_ALIGNMENT = 0x0D05;

  @DomName('WebGL.PACK_ROW_LENGTH')
  @DocsEditable()
  @Experimental() // untriaged
  static const int PACK_ROW_LENGTH = 0x0D02;

  @DomName('WebGL.PACK_SKIP_PIXELS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int PACK_SKIP_PIXELS = 0x0D04;

  @DomName('WebGL.PACK_SKIP_ROWS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int PACK_SKIP_ROWS = 0x0D03;

  @DomName('WebGL.PIXEL_PACK_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int PIXEL_PACK_BUFFER = 0x88EB;

  @DomName('WebGL.PIXEL_PACK_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int PIXEL_PACK_BUFFER_BINDING = 0x88ED;

  @DomName('WebGL.PIXEL_UNPACK_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int PIXEL_UNPACK_BUFFER = 0x88EC;

  @DomName('WebGL.PIXEL_UNPACK_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int PIXEL_UNPACK_BUFFER_BINDING = 0x88EF;

  @DomName('WebGL.POINTS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int POINTS = 0x0000;

  @DomName('WebGL.POLYGON_OFFSET_FACTOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int POLYGON_OFFSET_FACTOR = 0x8038;

  @DomName('WebGL.POLYGON_OFFSET_FILL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int POLYGON_OFFSET_FILL = 0x8037;

  @DomName('WebGL.POLYGON_OFFSET_UNITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int POLYGON_OFFSET_UNITS = 0x2A00;

  @DomName('WebGL.QUERY_RESULT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int QUERY_RESULT = 0x8866;

  @DomName('WebGL.QUERY_RESULT_AVAILABLE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int QUERY_RESULT_AVAILABLE = 0x8867;

  @DomName('WebGL.R11F_G11F_B10F')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R11F_G11F_B10F = 0x8C3A;

  @DomName('WebGL.R16F')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R16F = 0x822D;

  @DomName('WebGL.R16I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R16I = 0x8233;

  @DomName('WebGL.R16UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R16UI = 0x8234;

  @DomName('WebGL.R32F')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R32F = 0x822E;

  @DomName('WebGL.R32I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R32I = 0x8235;

  @DomName('WebGL.R32UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R32UI = 0x8236;

  @DomName('WebGL.R8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R8 = 0x8229;

  @DomName('WebGL.R8I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R8I = 0x8231;

  @DomName('WebGL.R8UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R8UI = 0x8232;

  @DomName('WebGL.R8_SNORM')
  @DocsEditable()
  @Experimental() // untriaged
  static const int R8_SNORM = 0x8F94;

  @DomName('WebGL.RASTERIZER_DISCARD')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RASTERIZER_DISCARD = 0x8C89;

  @DomName('WebGL.READ_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int READ_BUFFER = 0x0C02;

  @DomName('WebGL.READ_FRAMEBUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int READ_FRAMEBUFFER = 0x8CA8;

  @DomName('WebGL.READ_FRAMEBUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int READ_FRAMEBUFFER_BINDING = 0x8CAA;

  @DomName('WebGL.RED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RED = 0x1903;

  @DomName('WebGL.RED_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RED_BITS = 0x0D52;

  @DomName('WebGL.RED_INTEGER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RED_INTEGER = 0x8D94;

  @DomName('WebGL.RENDERBUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER = 0x8D41;

  @DomName('WebGL.RENDERBUFFER_ALPHA_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_ALPHA_SIZE = 0x8D53;

  @DomName('WebGL.RENDERBUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_BINDING = 0x8CA7;

  @DomName('WebGL.RENDERBUFFER_BLUE_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_BLUE_SIZE = 0x8D52;

  @DomName('WebGL.RENDERBUFFER_DEPTH_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_DEPTH_SIZE = 0x8D54;

  @DomName('WebGL.RENDERBUFFER_GREEN_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_GREEN_SIZE = 0x8D51;

  @DomName('WebGL.RENDERBUFFER_HEIGHT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_HEIGHT = 0x8D43;

  @DomName('WebGL.RENDERBUFFER_INTERNAL_FORMAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;

  @DomName('WebGL.RENDERBUFFER_RED_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_RED_SIZE = 0x8D50;

  @DomName('WebGL.RENDERBUFFER_SAMPLES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_SAMPLES = 0x8CAB;

  @DomName('WebGL.RENDERBUFFER_STENCIL_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_STENCIL_SIZE = 0x8D55;

  @DomName('WebGL.RENDERBUFFER_WIDTH')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERBUFFER_WIDTH = 0x8D42;

  @DomName('WebGL.RENDERER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RENDERER = 0x1F01;

  @DomName('WebGL.REPEAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int REPEAT = 0x2901;

  @DomName('WebGL.REPLACE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int REPLACE = 0x1E01;

  @DomName('WebGL.RG')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG = 0x8227;

  @DomName('WebGL.RG16F')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG16F = 0x822F;

  @DomName('WebGL.RG16I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG16I = 0x8239;

  @DomName('WebGL.RG16UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG16UI = 0x823A;

  @DomName('WebGL.RG32F')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG32F = 0x8230;

  @DomName('WebGL.RG32I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG32I = 0x823B;

  @DomName('WebGL.RG32UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG32UI = 0x823C;

  @DomName('WebGL.RG8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG8 = 0x822B;

  @DomName('WebGL.RG8I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG8I = 0x8237;

  @DomName('WebGL.RG8UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG8UI = 0x8238;

  @DomName('WebGL.RG8_SNORM')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG8_SNORM = 0x8F95;

  @DomName('WebGL.RGB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB = 0x1907;

  @DomName('WebGL.RGB10_A2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB10_A2 = 0x8059;

  @DomName('WebGL.RGB10_A2UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB10_A2UI = 0x906F;

  @DomName('WebGL.RGB16F')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB16F = 0x881B;

  @DomName('WebGL.RGB16I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB16I = 0x8D89;

  @DomName('WebGL.RGB16UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB16UI = 0x8D77;

  @DomName('WebGL.RGB32F')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB32F = 0x8815;

  @DomName('WebGL.RGB32I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB32I = 0x8D83;

  @DomName('WebGL.RGB32UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB32UI = 0x8D71;

  @DomName('WebGL.RGB565')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB565 = 0x8D62;

  @DomName('WebGL.RGB5_A1')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB5_A1 = 0x8057;

  @DomName('WebGL.RGB8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB8 = 0x8051;

  @DomName('WebGL.RGB8I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB8I = 0x8D8F;

  @DomName('WebGL.RGB8UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB8UI = 0x8D7D;

  @DomName('WebGL.RGB8_SNORM')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB8_SNORM = 0x8F96;

  @DomName('WebGL.RGB9_E5')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB9_E5 = 0x8C3D;

  @DomName('WebGL.RGBA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA = 0x1908;

  @DomName('WebGL.RGBA16F')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA16F = 0x881A;

  @DomName('WebGL.RGBA16I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA16I = 0x8D88;

  @DomName('WebGL.RGBA16UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA16UI = 0x8D76;

  @DomName('WebGL.RGBA32F')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA32F = 0x8814;

  @DomName('WebGL.RGBA32I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA32I = 0x8D82;

  @DomName('WebGL.RGBA32UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA32UI = 0x8D70;

  @DomName('WebGL.RGBA4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA4 = 0x8056;

  @DomName('WebGL.RGBA8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA8 = 0x8058;

  @DomName('WebGL.RGBA8I')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA8I = 0x8D8E;

  @DomName('WebGL.RGBA8UI')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA8UI = 0x8D7C;

  @DomName('WebGL.RGBA8_SNORM')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA8_SNORM = 0x8F97;

  @DomName('WebGL.RGBA_INTEGER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGBA_INTEGER = 0x8D99;

  @DomName('WebGL.RGB_INTEGER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RGB_INTEGER = 0x8D98;

  @DomName('WebGL.RG_INTEGER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int RG_INTEGER = 0x8228;

  @DomName('WebGL.SAMPLER_2D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLER_2D = 0x8B5E;

  @DomName('WebGL.SAMPLER_2D_ARRAY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLER_2D_ARRAY = 0x8DC1;

  @DomName('WebGL.SAMPLER_2D_ARRAY_SHADOW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLER_2D_ARRAY_SHADOW = 0x8DC4;

  @DomName('WebGL.SAMPLER_2D_SHADOW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLER_2D_SHADOW = 0x8B62;

  @DomName('WebGL.SAMPLER_3D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLER_3D = 0x8B5F;

  @DomName('WebGL.SAMPLER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLER_BINDING = 0x8919;

  @DomName('WebGL.SAMPLER_CUBE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLER_CUBE = 0x8B60;

  @DomName('WebGL.SAMPLER_CUBE_SHADOW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLER_CUBE_SHADOW = 0x8DC5;

  @DomName('WebGL.SAMPLES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLES = 0x80A9;

  @DomName('WebGL.SAMPLE_ALPHA_TO_COVERAGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLE_ALPHA_TO_COVERAGE = 0x809E;

  @DomName('WebGL.SAMPLE_BUFFERS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLE_BUFFERS = 0x80A8;

  @DomName('WebGL.SAMPLE_COVERAGE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLE_COVERAGE = 0x80A0;

  @DomName('WebGL.SAMPLE_COVERAGE_INVERT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLE_COVERAGE_INVERT = 0x80AB;

  @DomName('WebGL.SAMPLE_COVERAGE_VALUE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SAMPLE_COVERAGE_VALUE = 0x80AA;

  @DomName('WebGL.SCISSOR_BOX')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SCISSOR_BOX = 0x0C10;

  @DomName('WebGL.SCISSOR_TEST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SCISSOR_TEST = 0x0C11;

  @DomName('WebGL.SEPARATE_ATTRIBS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SEPARATE_ATTRIBS = 0x8C8D;

  @DomName('WebGL.SHADER_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SHADER_TYPE = 0x8B4F;

  @DomName('WebGL.SHADING_LANGUAGE_VERSION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SHADING_LANGUAGE_VERSION = 0x8B8C;

  @DomName('WebGL.SHORT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SHORT = 0x1402;

  @DomName('WebGL.SIGNALED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SIGNALED = 0x9119;

  @DomName('WebGL.SIGNED_NORMALIZED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SIGNED_NORMALIZED = 0x8F9C;

  @DomName('WebGL.SRC_ALPHA')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRC_ALPHA = 0x0302;

  @DomName('WebGL.SRC_ALPHA_SATURATE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRC_ALPHA_SATURATE = 0x0308;

  @DomName('WebGL.SRC_COLOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRC_COLOR = 0x0300;

  @DomName('WebGL.SRGB')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRGB = 0x8C40;

  @DomName('WebGL.SRGB8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRGB8 = 0x8C41;

  @DomName('WebGL.SRGB8_ALPHA8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SRGB8_ALPHA8 = 0x8C43;

  @DomName('WebGL.STATIC_COPY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STATIC_COPY = 0x88E6;

  @DomName('WebGL.STATIC_DRAW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STATIC_DRAW = 0x88E4;

  @DomName('WebGL.STATIC_READ')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STATIC_READ = 0x88E5;

  @DomName('WebGL.STENCIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL = 0x1802;

  @DomName('WebGL.STENCIL_ATTACHMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_ATTACHMENT = 0x8D20;

  @DomName('WebGL.STENCIL_BACK_FAIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_FAIL = 0x8801;

  @DomName('WebGL.STENCIL_BACK_FUNC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_FUNC = 0x8800;

  @DomName('WebGL.STENCIL_BACK_PASS_DEPTH_FAIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;

  @DomName('WebGL.STENCIL_BACK_PASS_DEPTH_PASS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;

  @DomName('WebGL.STENCIL_BACK_REF')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_REF = 0x8CA3;

  @DomName('WebGL.STENCIL_BACK_VALUE_MASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_VALUE_MASK = 0x8CA4;

  @DomName('WebGL.STENCIL_BACK_WRITEMASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BACK_WRITEMASK = 0x8CA5;

  @DomName('WebGL.STENCIL_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BITS = 0x0D57;

  @DomName('WebGL.STENCIL_BUFFER_BIT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_BUFFER_BIT = 0x00000400;

  @DomName('WebGL.STENCIL_CLEAR_VALUE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_CLEAR_VALUE = 0x0B91;

  @DomName('WebGL.STENCIL_FAIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_FAIL = 0x0B94;

  @DomName('WebGL.STENCIL_FUNC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_FUNC = 0x0B92;

  @DomName('WebGL.STENCIL_INDEX8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_INDEX8 = 0x8D48;

  @DomName('WebGL.STENCIL_PASS_DEPTH_FAIL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_PASS_DEPTH_FAIL = 0x0B95;

  @DomName('WebGL.STENCIL_PASS_DEPTH_PASS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_PASS_DEPTH_PASS = 0x0B96;

  @DomName('WebGL.STENCIL_REF')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_REF = 0x0B97;

  @DomName('WebGL.STENCIL_TEST')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_TEST = 0x0B90;

  @DomName('WebGL.STENCIL_VALUE_MASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_VALUE_MASK = 0x0B93;

  @DomName('WebGL.STENCIL_WRITEMASK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STENCIL_WRITEMASK = 0x0B98;

  @DomName('WebGL.STREAM_COPY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STREAM_COPY = 0x88E2;

  @DomName('WebGL.STREAM_DRAW')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STREAM_DRAW = 0x88E0;

  @DomName('WebGL.STREAM_READ')
  @DocsEditable()
  @Experimental() // untriaged
  static const int STREAM_READ = 0x88E1;

  @DomName('WebGL.SUBPIXEL_BITS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SUBPIXEL_BITS = 0x0D50;

  @DomName('WebGL.SYNC_CONDITION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SYNC_CONDITION = 0x9113;

  @DomName('WebGL.SYNC_FENCE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SYNC_FENCE = 0x9116;

  @DomName('WebGL.SYNC_FLAGS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SYNC_FLAGS = 0x9115;

  @DomName('WebGL.SYNC_FLUSH_COMMANDS_BIT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SYNC_FLUSH_COMMANDS_BIT = 0x00000001;

  @DomName('WebGL.SYNC_GPU_COMMANDS_COMPLETE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SYNC_GPU_COMMANDS_COMPLETE = 0x9117;

  @DomName('WebGL.SYNC_STATUS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int SYNC_STATUS = 0x9114;

  @DomName('WebGL.TEXTURE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE = 0x1702;

  @DomName('WebGL.TEXTURE0')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE0 = 0x84C0;

  @DomName('WebGL.TEXTURE1')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE1 = 0x84C1;

  @DomName('WebGL.TEXTURE10')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE10 = 0x84CA;

  @DomName('WebGL.TEXTURE11')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE11 = 0x84CB;

  @DomName('WebGL.TEXTURE12')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE12 = 0x84CC;

  @DomName('WebGL.TEXTURE13')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE13 = 0x84CD;

  @DomName('WebGL.TEXTURE14')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE14 = 0x84CE;

  @DomName('WebGL.TEXTURE15')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE15 = 0x84CF;

  @DomName('WebGL.TEXTURE16')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE16 = 0x84D0;

  @DomName('WebGL.TEXTURE17')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE17 = 0x84D1;

  @DomName('WebGL.TEXTURE18')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE18 = 0x84D2;

  @DomName('WebGL.TEXTURE19')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE19 = 0x84D3;

  @DomName('WebGL.TEXTURE2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE2 = 0x84C2;

  @DomName('WebGL.TEXTURE20')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE20 = 0x84D4;

  @DomName('WebGL.TEXTURE21')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE21 = 0x84D5;

  @DomName('WebGL.TEXTURE22')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE22 = 0x84D6;

  @DomName('WebGL.TEXTURE23')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE23 = 0x84D7;

  @DomName('WebGL.TEXTURE24')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE24 = 0x84D8;

  @DomName('WebGL.TEXTURE25')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE25 = 0x84D9;

  @DomName('WebGL.TEXTURE26')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE26 = 0x84DA;

  @DomName('WebGL.TEXTURE27')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE27 = 0x84DB;

  @DomName('WebGL.TEXTURE28')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE28 = 0x84DC;

  @DomName('WebGL.TEXTURE29')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE29 = 0x84DD;

  @DomName('WebGL.TEXTURE3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE3 = 0x84C3;

  @DomName('WebGL.TEXTURE30')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE30 = 0x84DE;

  @DomName('WebGL.TEXTURE31')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE31 = 0x84DF;

  @DomName('WebGL.TEXTURE4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE4 = 0x84C4;

  @DomName('WebGL.TEXTURE5')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE5 = 0x84C5;

  @DomName('WebGL.TEXTURE6')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE6 = 0x84C6;

  @DomName('WebGL.TEXTURE7')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE7 = 0x84C7;

  @DomName('WebGL.TEXTURE8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE8 = 0x84C8;

  @DomName('WebGL.TEXTURE9')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE9 = 0x84C9;

  @DomName('WebGL.TEXTURE_2D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_2D = 0x0DE1;

  @DomName('WebGL.TEXTURE_2D_ARRAY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_2D_ARRAY = 0x8C1A;

  @DomName('WebGL.TEXTURE_3D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_3D = 0x806F;

  @DomName('WebGL.TEXTURE_BASE_LEVEL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_BASE_LEVEL = 0x813C;

  @DomName('WebGL.TEXTURE_BINDING_2D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_BINDING_2D = 0x8069;

  @DomName('WebGL.TEXTURE_BINDING_2D_ARRAY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_BINDING_2D_ARRAY = 0x8C1D;

  @DomName('WebGL.TEXTURE_BINDING_3D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_BINDING_3D = 0x806A;

  @DomName('WebGL.TEXTURE_BINDING_CUBE_MAP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_BINDING_CUBE_MAP = 0x8514;

  @DomName('WebGL.TEXTURE_COMPARE_FUNC')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_COMPARE_FUNC = 0x884D;

  @DomName('WebGL.TEXTURE_COMPARE_MODE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_COMPARE_MODE = 0x884C;

  @DomName('WebGL.TEXTURE_CUBE_MAP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP = 0x8513;

  @DomName('WebGL.TEXTURE_CUBE_MAP_NEGATIVE_X')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;

  @DomName('WebGL.TEXTURE_CUBE_MAP_NEGATIVE_Y')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;

  @DomName('WebGL.TEXTURE_CUBE_MAP_NEGATIVE_Z')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;

  @DomName('WebGL.TEXTURE_CUBE_MAP_POSITIVE_X')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;

  @DomName('WebGL.TEXTURE_CUBE_MAP_POSITIVE_Y')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;

  @DomName('WebGL.TEXTURE_CUBE_MAP_POSITIVE_Z')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;

  @DomName('WebGL.TEXTURE_IMMUTABLE_FORMAT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_IMMUTABLE_FORMAT = 0x912F;

  @DomName('WebGL.TEXTURE_IMMUTABLE_LEVELS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_IMMUTABLE_LEVELS = 0x82DF;

  @DomName('WebGL.TEXTURE_MAG_FILTER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_MAG_FILTER = 0x2800;

  @DomName('WebGL.TEXTURE_MAX_LEVEL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_MAX_LEVEL = 0x813D;

  @DomName('WebGL.TEXTURE_MAX_LOD')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_MAX_LOD = 0x813B;

  @DomName('WebGL.TEXTURE_MIN_FILTER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_MIN_FILTER = 0x2801;

  @DomName('WebGL.TEXTURE_MIN_LOD')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_MIN_LOD = 0x813A;

  @DomName('WebGL.TEXTURE_WRAP_R')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_WRAP_R = 0x8072;

  @DomName('WebGL.TEXTURE_WRAP_S')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_WRAP_S = 0x2802;

  @DomName('WebGL.TEXTURE_WRAP_T')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TEXTURE_WRAP_T = 0x2803;

  @DomName('WebGL.TIMEOUT_EXPIRED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TIMEOUT_EXPIRED = 0x911B;

  @DomName('WebGL.TIMEOUT_IGNORED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TIMEOUT_IGNORED = -1;

  @DomName('WebGL.TRANSFORM_FEEDBACK')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK = 0x8E22;

  @DomName('WebGL.TRANSFORM_FEEDBACK_ACTIVE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK_ACTIVE = 0x8E24;

  @DomName('WebGL.TRANSFORM_FEEDBACK_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK_BINDING = 0x8E25;

  @DomName('WebGL.TRANSFORM_FEEDBACK_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK_BUFFER = 0x8C8E;

  @DomName('WebGL.TRANSFORM_FEEDBACK_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK_BUFFER_BINDING = 0x8C8F;

  @DomName('WebGL.TRANSFORM_FEEDBACK_BUFFER_MODE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK_BUFFER_MODE = 0x8C7F;

  @DomName('WebGL.TRANSFORM_FEEDBACK_BUFFER_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK_BUFFER_SIZE = 0x8C85;

  @DomName('WebGL.TRANSFORM_FEEDBACK_BUFFER_START')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK_BUFFER_START = 0x8C84;

  @DomName('WebGL.TRANSFORM_FEEDBACK_PAUSED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK_PAUSED = 0x8E23;

  @DomName('WebGL.TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN = 0x8C88;

  @DomName('WebGL.TRANSFORM_FEEDBACK_VARYINGS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRANSFORM_FEEDBACK_VARYINGS = 0x8C83;

  @DomName('WebGL.TRIANGLES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRIANGLES = 0x0004;

  @DomName('WebGL.TRIANGLE_FAN')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRIANGLE_FAN = 0x0006;

  @DomName('WebGL.TRIANGLE_STRIP')
  @DocsEditable()
  @Experimental() // untriaged
  static const int TRIANGLE_STRIP = 0x0005;

  @DomName('WebGL.UNIFORM_ARRAY_STRIDE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_ARRAY_STRIDE = 0x8A3C;

  @DomName('WebGL.UNIFORM_BLOCK_ACTIVE_UNIFORMS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BLOCK_ACTIVE_UNIFORMS = 0x8A42;

  @DomName('WebGL.UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES = 0x8A43;

  @DomName('WebGL.UNIFORM_BLOCK_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BLOCK_BINDING = 0x8A3F;

  @DomName('WebGL.UNIFORM_BLOCK_DATA_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BLOCK_DATA_SIZE = 0x8A40;

  @DomName('WebGL.UNIFORM_BLOCK_INDEX')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BLOCK_INDEX = 0x8A3A;

  @DomName('WebGL.UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER = 0x8A46;

  @DomName('WebGL.UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER = 0x8A44;

  @DomName('WebGL.UNIFORM_BUFFER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BUFFER = 0x8A11;

  @DomName('WebGL.UNIFORM_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BUFFER_BINDING = 0x8A28;

  @DomName('WebGL.UNIFORM_BUFFER_OFFSET_ALIGNMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BUFFER_OFFSET_ALIGNMENT = 0x8A34;

  @DomName('WebGL.UNIFORM_BUFFER_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BUFFER_SIZE = 0x8A2A;

  @DomName('WebGL.UNIFORM_BUFFER_START')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_BUFFER_START = 0x8A29;

  @DomName('WebGL.UNIFORM_IS_ROW_MAJOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_IS_ROW_MAJOR = 0x8A3E;

  @DomName('WebGL.UNIFORM_MATRIX_STRIDE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_MATRIX_STRIDE = 0x8A3D;

  @DomName('WebGL.UNIFORM_OFFSET')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_OFFSET = 0x8A3B;

  @DomName('WebGL.UNIFORM_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_SIZE = 0x8A38;

  @DomName('WebGL.UNIFORM_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNIFORM_TYPE = 0x8A37;

  @DomName('WebGL.UNPACK_ALIGNMENT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_ALIGNMENT = 0x0CF5;

  @DomName('WebGL.UNPACK_COLORSPACE_CONVERSION_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;

  @DomName('WebGL.UNPACK_FLIP_Y_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_FLIP_Y_WEBGL = 0x9240;

  @DomName('WebGL.UNPACK_IMAGE_HEIGHT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_IMAGE_HEIGHT = 0x806E;

  @DomName('WebGL.UNPACK_PREMULTIPLY_ALPHA_WEBGL')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;

  @DomName('WebGL.UNPACK_ROW_LENGTH')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_ROW_LENGTH = 0x0CF2;

  @DomName('WebGL.UNPACK_SKIP_IMAGES')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_SKIP_IMAGES = 0x806D;

  @DomName('WebGL.UNPACK_SKIP_PIXELS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_SKIP_PIXELS = 0x0CF4;

  @DomName('WebGL.UNPACK_SKIP_ROWS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNPACK_SKIP_ROWS = 0x0CF3;

  @DomName('WebGL.UNSIGNALED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNALED = 0x9118;

  @DomName('WebGL.UNSIGNED_BYTE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_BYTE = 0x1401;

  @DomName('WebGL.UNSIGNED_INT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT = 0x1405;

  @DomName('WebGL.UNSIGNED_INT_10F_11F_11F_REV')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_10F_11F_11F_REV = 0x8C3B;

  @DomName('WebGL.UNSIGNED_INT_24_8')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_24_8 = 0x84FA;

  @DomName('WebGL.UNSIGNED_INT_2_10_10_10_REV')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_2_10_10_10_REV = 0x8368;

  @DomName('WebGL.UNSIGNED_INT_5_9_9_9_REV')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_5_9_9_9_REV = 0x8C3E;

  @DomName('WebGL.UNSIGNED_INT_SAMPLER_2D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_SAMPLER_2D = 0x8DD2;

  @DomName('WebGL.UNSIGNED_INT_SAMPLER_2D_ARRAY')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_SAMPLER_2D_ARRAY = 0x8DD7;

  @DomName('WebGL.UNSIGNED_INT_SAMPLER_3D')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_SAMPLER_3D = 0x8DD3;

  @DomName('WebGL.UNSIGNED_INT_SAMPLER_CUBE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_SAMPLER_CUBE = 0x8DD4;

  @DomName('WebGL.UNSIGNED_INT_VEC2')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_VEC2 = 0x8DC6;

  @DomName('WebGL.UNSIGNED_INT_VEC3')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_VEC3 = 0x8DC7;

  @DomName('WebGL.UNSIGNED_INT_VEC4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_INT_VEC4 = 0x8DC8;

  @DomName('WebGL.UNSIGNED_NORMALIZED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_NORMALIZED = 0x8C17;

  @DomName('WebGL.UNSIGNED_SHORT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_SHORT = 0x1403;

  @DomName('WebGL.UNSIGNED_SHORT_4_4_4_4')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_SHORT_4_4_4_4 = 0x8033;

  @DomName('WebGL.UNSIGNED_SHORT_5_5_5_1')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_SHORT_5_5_5_1 = 0x8034;

  @DomName('WebGL.UNSIGNED_SHORT_5_6_5')
  @DocsEditable()
  @Experimental() // untriaged
  static const int UNSIGNED_SHORT_5_6_5 = 0x8363;

  @DomName('WebGL.VALIDATE_STATUS')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VALIDATE_STATUS = 0x8B83;

  @DomName('WebGL.VENDOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VENDOR = 0x1F00;

  @DomName('WebGL.VERSION')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERSION = 0x1F02;

  @DomName('WebGL.VERTEX_ARRAY_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ARRAY_BINDING = 0x85B5;

  @DomName('WebGL.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

  @DomName('WebGL.VERTEX_ATTRIB_ARRAY_DIVISOR')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_DIVISOR = 0x88FE;

  @DomName('WebGL.VERTEX_ATTRIB_ARRAY_ENABLED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;

  @DomName('WebGL.VERTEX_ATTRIB_ARRAY_INTEGER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_INTEGER = 0x88FD;

  @DomName('WebGL.VERTEX_ATTRIB_ARRAY_NORMALIZED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;

  @DomName('WebGL.VERTEX_ATTRIB_ARRAY_POINTER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;

  @DomName('WebGL.VERTEX_ATTRIB_ARRAY_SIZE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;

  @DomName('WebGL.VERTEX_ATTRIB_ARRAY_STRIDE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;

  @DomName('WebGL.VERTEX_ATTRIB_ARRAY_TYPE')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;

  @DomName('WebGL.VERTEX_SHADER')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VERTEX_SHADER = 0x8B31;

  @DomName('WebGL.VIEWPORT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int VIEWPORT = 0x0BA2;

  @DomName('WebGL.WAIT_FAILED')
  @DocsEditable()
  @Experimental() // untriaged
  static const int WAIT_FAILED = 0x911D;

  @DomName('WebGL.ZERO')
  @DocsEditable()
  @Experimental() // untriaged
  static const int ZERO = 0;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGL2RenderingContextBase')
@Experimental() // untriaged
@Native("WebGL2RenderingContextBase")
abstract class _WebGL2RenderingContextBase extends Interceptor
    implements _WebGLRenderingContextBase {
  // To suppress missing implicit constructor warnings.
  factory _WebGL2RenderingContextBase._() {
    throw new UnsupportedError("Not supported");
  }

  // From WebGLRenderingContextBase
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WebGLRenderingContextBase')
@Experimental() // untriaged
abstract class _WebGLRenderingContextBase extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory _WebGLRenderingContextBase._() {
    throw new UnsupportedError("Not supported");
  }
}
