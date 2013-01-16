// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_GL_GRAPHICS_HANDLER_H_
#define EMBEDDERS_OPENGLUI_COMMON_GL_GRAPHICS_HANDLER_H_

#include "embedders/openglui/common/graphics_handler.h"
#include "embedders/openglui/common/opengl.h"
#include "embedders/openglui/common/timer.h"

class GLGraphicsHandler : public GraphicsHandler {
  public:
    GLGraphicsHandler()
      : GraphicsHandler() {
    }

    virtual int32_t Start() = 0;
    virtual void Stop() = 0;

    void SwapBuffers() {
      GLSwapBuffers();
    }

    virtual int32_t Update() {
      SwapBuffers();
      return 0;
    }

    void SetViewport(int left, int top, int width, int height);
    int BuildProgram(const char* vertexShaderSource,
                     const char* fragmentShaderSource) const;
    int BuildShader(const char* source, GLenum shaderType) const;

    virtual ~GLGraphicsHandler() {
    }
};

#endif  // EMBEDDERS_OPENGLUI_COMMON_GL_GRAPHICS_HANDLER_H_

