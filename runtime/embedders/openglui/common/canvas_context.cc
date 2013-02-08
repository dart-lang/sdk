// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/canvas_context.h"

#include <ctype.h>
#include <string.h>

#include "embedders/openglui/common/support.h"

// TODO(gram): this should be dynamic.
#define MAX_CONTEXTS 16
CanvasContext* contexts[MAX_CONTEXTS] = { 0 };

CanvasContext* Context2D(int handle) {
  if (handle < 0 || handle >= MAX_CONTEXTS) {
    return NULL;
  }
  return contexts[handle];
}

CanvasContext::CanvasContext(int handle, int16_t widthp, int16_t heightp)
  : canvas_(NULL),
    width_(widthp),
    height_(heightp),
    imageSmoothingEnabled_(true),
    state_(NULL) {
  if (handle == 0) {
    canvas_ = graphics->CreateDisplayCanvas();
  } else {
    canvas_ = graphics->CreateBitmapCanvas(widthp, heightp);
  }
  state_ = new CanvasState(canvas_);
  contexts[handle] = this;
}

CanvasContext::~CanvasContext() {
  delete state_;
  delete canvas_;
}

void CanvasContext::DrawImage(const char* src_url,
                              int sx, int sy,
                              bool has_src_dimensions, int sw, int sh,
                              int dx, int dy,
                              bool has_dst_dimensions, int dw, int dh) {
  SkBitmap bm;
  if (strncmp(src_url, "context2d://", 12) == 0) {
    int handle = atoi(src_url + 12);
    CanvasContext* otherContext = Context2D(handle);
    SkDevice* device = otherContext->canvas_->getDevice();
    bm = device->accessBitmap(false);
  } else {
    // TODO(gram): We need a way to remap URLs to local file names.
    // For now I am just using the characters after the last '/'.
    // Note also that if we want to support URLs and network fetches,
    // then we introduce more complexity; this can't just be an URL.
    int pos = strlen(src_url);
    while (--pos >= 0 && src_url[pos] != '/');
    const char *path = src_url + pos + 1;
    if (!SkImageDecoder::DecodeFile(path, &bm)) {
      LOGI("Image decode of %s failed", path);
      return;
    } else {
      LOGI("Decode image: width=%d,height=%d", bm.width(), bm.height());
    }
  }
  if (!has_src_dimensions) {
    sw = bm.width();
    sh = bm.height();
  }
  if (!has_dst_dimensions) {
    dw = bm.width();
    dh = bm.height();
  }
  state_->DrawImage(bm, sx, sy, sw, sh, dx, dy, dw, dh);
}

void CanvasContext::ClearRect(float left, float top,
                              float width, float height) {
  SkPaint paint;
  paint.setStyle(SkPaint::kFill_Style);
  paint.setColor(0xFFFFFFFF);
  canvas_->drawRectCoords(left, top, left + width, top + height, paint);
}

