// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_GRAPHICS_HANDLER_H_
#define EMBEDDERS_OPENGLUI_COMMON_GRAPHICS_HANDLER_H_

#include <stdint.h>

#include "embedders/openglui/common/isized.h"
#include "embedders/openglui/common/timer.h"

class GraphicsHandler : public ISized {
  public:
    GraphicsHandler()
      : width_(0),
        height_(0) {
    }

    const int32_t& height() {
      return height_;
    }

    const int32_t& width() {
      return width_;
    }

    virtual int32_t Start() = 0;
    virtual void Stop() = 0;

    virtual void SwapBuffers() = 0;

    virtual int32_t Update() {
      return 0;
    }

    virtual void SetViewport(int left, int top, int width, int height) = 0;

    virtual ~GraphicsHandler() {
    }

  protected:
    int32_t width_, height_;
};

#endif  // EMBEDDERS_OPENGLUI_COMMON_GRAPHICS_HANDLER_H_

