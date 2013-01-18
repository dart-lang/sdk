// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_INPUT_HANDLER_H_
#define EMBEDDERS_OPENGLUI_COMMON_INPUT_HANDLER_H_

#include "embedders/openglui/common/events.h"
#include "embedders/openglui/common/vm_glue.h"

class InputHandler {
  public:
    explicit InputHandler(VMGlue* vm_glue);
    virtual int32_t Start() { return 0; }
    virtual void Stop() { }
    virtual int OnMotionEvent(MotionEvent event, int64_t when,
                    float move_x, float move_y);
    virtual int OnKeyEvent(KeyEvent event, int64_t when, int32_t flags,
             int32_t key_code, int32_t meta_state, int32_t repeat);
    virtual ~InputHandler() {}

  protected:
    VMGlue* vm_glue_;
};

#endif  // EMBEDDERS_OPENGLUI_COMMON_INPUT_HANDLER_H_

