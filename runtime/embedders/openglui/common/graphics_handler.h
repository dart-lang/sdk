// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_GRAPHICS_HANDLER_H_
#define EMBEDDERS_OPENGLUI_COMMON_GRAPHICS_HANDLER_H_

#include "embedders/openglui/common/isized.h"
#include "embedders/openglui/common/opengl.h"
#include "embedders/openglui/common/support.h"
#include "embedders/openglui/common/timer.h"

class GraphicsHandler : public ISized {
  private:
    void DecoderHack(int x, SkStream* s);

  public:
    explicit GraphicsHandler(const char* resource_path);

    const int32_t& height() {
      return height_;
    }

    const int32_t& width() {
      return width_;
    }

    void ApplyOrtho(float maxX, float maxY) const;
    void ApplyRotation(float degrees) const;

    virtual int32_t Start();
    virtual void Stop();

    void SwapBuffers() {
      GLSwapBuffers();
    }

    virtual int32_t Update();

    void SetViewport(int left, int top, int width, int height);

    SkCanvas* CreateDisplayCanvas();
    SkCanvas* CreateBitmapCanvas(int width, int height);

    inline const char* resource_path() {
      return resource_path_;
    }

    virtual ~GraphicsHandler() {
    }

  protected:
    const char* resource_path_;
    SkAutoGraphics ag;
    GrContext* grcontext;
    int32_t width_, height_;
};

extern GraphicsHandler* graphics;

#endif  // EMBEDDERS_OPENGLUI_COMMON_GRAPHICS_HANDLER_H_

