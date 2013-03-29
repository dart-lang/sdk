// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/canvas_context.h"

#include <ctype.h>
#include <string.h>
#include "core/SkStream.h"
#include "embedders/openglui/common/image_cache.h"
#include "embedders/openglui/common/support.h"

// TODO(gram): this should be dynamic.
#define MAX_CONTEXTS 256
CanvasContext* contexts[MAX_CONTEXTS] = { 0 };

CanvasContext* Context2D(int handle) {
  if (handle < 0 || handle >= MAX_CONTEXTS) {
    LOGE("Request for out-of-range handle %d", handle);
    return NULL;
  }
  if (contexts[handle] == NULL) {
    LOGE("Warning: request for context with handle %d returns NULL", handle);
  }
  return contexts[handle];
}

void FreeContexts() {
  extern CanvasContext* display_context;
  for (int i = 0; i < MAX_CONTEXTS; i++) {
    delete contexts[i];
    contexts[i] = NULL;
  }
  display_context = NULL;
}


CanvasContext::CanvasContext(int handle, int16_t widthp, int16_t heightp)
  : canvas_(NULL),
    width_(widthp),
    height_(heightp),
    imageSmoothingEnabled_(true),
    state_(NULL) {
  if (handle >= MAX_CONTEXTS) {
    LOGE("Max contexts exceeded");
    exit(-1);
  }
  if (handle == 0) {
    canvas_ = graphics->CreateDisplayCanvas();
  } else {
    canvas_ = graphics->CreateBitmapCanvas(widthp, heightp);
  }
  state_ = new CanvasState(canvas_);
  contexts[handle] = this;
  LOGI("Created context with handle %d", handle);
}

CanvasContext::~CanvasContext() {
  delete state_;
  delete canvas_;
}

void CanvasContext::Save() {
  state_ = state_->Save();
}

void CanvasContext::Restore() {
  CanvasState* popped_state = state_;
  state_ = state_->Restore();
  if (state_ == NULL) {
    LOGE("Popping last state!");
    state_ = popped_state;
  }
  if (state_ != popped_state) {
    // Only delete if the pop was successful.
    delete popped_state;
  }
}

void CanvasContext::DrawImage(const char* src_url,
                              int sx, int sy,
                              bool has_src_dimensions, int sw, int sh,
                              int dx, int dy,
                              bool has_dst_dimensions, int dw, int dh) {
  const SkBitmap* bm = ImageCache::GetImage(src_url);
  if (bm == NULL) return;
  if (!has_src_dimensions) {
    sw = bm->width();
    sh = bm->height();
  }
  if (!has_dst_dimensions) {
    dw = bm->width();
    dh = bm->height();
  }
  state_->DrawImage(*bm, sx, sy, sw, sh, dx, dy, dw, dh);
  isDirty_ = true;
}

void CanvasContext::ClearRect(float left, float top,
                              float width, float height) {
  SkPaint paint;
  paint.setStyle(SkPaint::kFill_Style);
  paint.setColor(0xFFFFFFFF);
  canvas_->drawRectCoords(left, top, left + width, top + height, paint);
  isDirty_ = true;
}

