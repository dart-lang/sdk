// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_INPUT_HANDLER_H_
#define EMBEDDERS_ANDROID_INPUT_HANDLER_H_

#include <android/input.h>

class InputHandler {
  public:
    virtual int32_t Start() { return 0; }
    virtual bool OnTouchEvent(AInputEvent* event) = 0;
    virtual bool OnKeyEvent(AInputEvent* event) = 0;
    virtual ~InputHandler() {}
};

#endif  // EMBEDDERS_ANDROID_INPUT_HANDLER_H_
