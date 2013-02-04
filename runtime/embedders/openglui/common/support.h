// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_SUPPORT_H_
#define EMBEDDERS_OPENGLUI_COMMON_SUPPORT_H_

#include "embedders/openglui/common/opengl.h"

#ifndef MAX
#define MAX(a, b) (((a) > (b)) ? (a) : (b))
#endif
#ifndef MIN
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#endif

// Colors as used by canvas.
typedef struct ColorRGBA {
  // We store Skia-compatible values. Skia uses
  // the form AARRGGBB.
  uint32_t v;

  inline ColorRGBA(char rp, char gp, char bp, char ap = 255) {
    v = ((static_cast<uint32_t>(rp) & 0xFF) << 16) |
        ((static_cast<uint32_t>(gp) & 0xFF) << 8) |
        ((static_cast<uint32_t>(bp) & 0xFF) << 0) |
        ((static_cast<uint32_t>(ap) & 0xFF) << 24);
  }
  inline ColorRGBA(uint32_t vp)
    : v(vp) {
  }
  inline uint8_t alpha() {
    return (v >> 24) & 0xFF;
  }
} ColorRGBA;

#endif  // EMBEDDERS_OPENGLUI_COMMON_SUPPORT_H_
