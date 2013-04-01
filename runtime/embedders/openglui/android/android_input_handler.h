// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_ANDROID_ANDROID_INPUT_HANDLER_H_
#define EMBEDDERS_OPENGLUI_ANDROID_ANDROID_INPUT_HANDLER_H_

#include "embedders/openglui/common/graphics_handler.h"
#include "embedders/openglui/common/input_handler.h"

class AndroidInputHandler : public InputHandler {
  public:
    AndroidInputHandler(VMGlue* vm_glue,
                        GraphicsHandler* graphics_handler)
      : InputHandler(vm_glue),
        graphics_handler_(graphics_handler) {
    }

  public:
    int32_t Start() {
      if (graphics_handler_->width() == 0 ||
          graphics_handler_->height() == 0) {
        return -1;
      }
      return 0;
    }

    void Stop() {
    }

  private:
    GraphicsHandler* graphics_handler_;
};

#endif  // EMBEDDERS_OPENGLUI_ANDROID_ANDROID_INPUT_HANDLER_H_

