// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_GRAPHICS_H_
#define EMBEDDERS_ANDROID_GRAPHICS_H_

#include <android_native_app_glue.h>
#include <EGL/egl.h>

#include "embedders/android/timer.h"

class Graphics {
  public:
    Graphics(android_app* application, Timer* timer);

    const int32_t& height();
    const int32_t& width();
    int32_t Start();
    void Stop();
    int32_t Update();

  private:
    android_app* application_;
    Timer* timer_;
    int32_t width_, height_;
    EGLDisplay display_;
    EGLSurface surface_;
    EGLContext context_;
};

#endif  // EMBEDDERS_ANDROID_GRAPHICS_H_
