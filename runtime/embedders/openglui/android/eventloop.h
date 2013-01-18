// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_ANDROID_EVENTLOOP_H_
#define EMBEDDERS_OPENGLUI_ANDROID_EVENTLOOP_H_

#include <android_native_app_glue.h>
#include "embedders/openglui/common/events.h"
#include "embedders/openglui/common/input_handler.h"
#include "embedders/openglui/common/lifecycle_handler.h"

class EventLoop {
  public:
    explicit EventLoop(android_app* application);
    void Run(LifeCycleHandler* activity_handler,
             InputHandler* input_handler);

  protected:
    void Activate();
    void Deactivate();
    void ProcessActivityEvent(int32_t command);
    int32_t ProcessInputEvent(AInputEvent* event);
    bool OnTouchEvent(AInputEvent* event);
    bool OnKeyEvent(AInputEvent* event);

    static void ActivityCallback(android_app* application, int32_t command);
    static int32_t InputCallback(android_app* application, AInputEvent* event);

  private:
    bool enabled_;
    bool quit_;
    android_app* application_;
    LifeCycleHandler* lifecycle_handler_;
    InputHandler* input_handler_;
};

#endif  // EMBEDDERS_OPENGLUI_ANDROID_EVENTLOOP_H_

