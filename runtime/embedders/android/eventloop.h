// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_EVENTLOOP_H_
#define EMBEDDERS_ANDROID_EVENTLOOP_H_

#include <android_native_app_glue.h>
#include "embedders/android/activity_handler.h"
#include "embedders/android/context.h"
#include "embedders/android/input_handler.h"

class EventLoop {
  public:
    explicit EventLoop(android_app* application);
    void Run(ActivityHandler* activityHandler, Context* context);

  protected:
    void Activate();
    void Deactivate();
    void ProcessActivityEvent(int32_t command);
    int32_t ProcessInputEvent(AInputEvent* event);

    static void ActivityCallback(android_app* application, int32_t command);
    static int32_t InputCallback(android_app* application, AInputEvent* event);

  private:
    bool enabled_;
    bool quit_;
    android_app* application_;
    ActivityHandler* activity_handler_;
    InputHandler* input_handler_;
};

#endif  // EMBEDDERS_ANDROID_EVENTLOOP_H_
