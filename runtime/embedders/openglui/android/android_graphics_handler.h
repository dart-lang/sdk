// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_ANDROID_ANDROID_GRAPHICS_HANDLER_H_
#define EMBEDDERS_OPENGLUI_ANDROID_ANDROID_GRAPHICS_HANDLER_H_

#include <android_native_app_glue.h>
#include "embedders/openglui/common/gl_graphics_handler.h"

class AndroidGraphicsHandler : public GLGraphicsHandler {
  public:
    explicit AndroidGraphicsHandler(android_app* application);

    int32_t Start();
    void Stop();

  private:
    android_app* application_;
    EGLDisplay display_;
    EGLSurface surface_;
    EGLContext context_;
};

#endif  // EMBEDDERS_OPENGLUI_ANDROID_ANDROID_GRAPHICS_HANDLER_H_

