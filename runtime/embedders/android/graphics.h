// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_GRAPHICS_H_
#define EMBEDDERS_ANDROID_GRAPHICS_H_

#include <android_native_app_glue.h>
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include "embedders/android/timer.h"

class Graphics {
  public:
    Graphics(android_app* application, Timer* timer);

    const int32_t& height();
    const int32_t& width();
    int32_t Start();
    void Stop();
    void SwapBuffers();
    int32_t Update();
    void SetViewport(int left, int top, int width, int height);
    int BuildProgram(const char* vertexShaderSource,
                        const char* fragmentShaderSource) const;
    int BuildShader(const char* source, GLenum shaderType) const;

  private:
    android_app* application_;
    Timer* timer_;
    int32_t width_, height_;
    EGLDisplay display_;
    EGLSurface surface_;
    EGLContext context_;
};

#endif  // EMBEDDERS_ANDROID_GRAPHICS_H_
