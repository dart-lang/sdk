// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/input_handler.h"
#include "embedders/openglui/common/log.h"

InputHandler::InputHandler(VMGlue* vm_glue)
  : vm_glue_(vm_glue) {
}

int InputHandler::OnMotionEvent(MotionEvent event,
                                int64_t when,
                                float x,
                                float y) {
  const char *function = NULL;
  // For now we just keep this simple. There are
  // no click events or mouseover events.
  switch (event) {
    case kMotionDown:
      function = "onMouseDown_";
      break;
    case kMotionUp:
      function = "onMouseUp_";
      break;
    case kMotionMove:
      function = "onMouseMove_";
      break;
    case kMotionCancel:
      break;
    case kMotionOutside:
      break;
    case kMotionPointerDown:
      break;
    case kMotionPointerUp:
      break;
    default:
      return -1;
  }
  if (function == NULL) {
    return 0;
  } else {
    return vm_glue_->OnMotionEvent(function, when, x, y);
  }
}

int InputHandler::OnKeyEvent(KeyEvent event,
                             int64_t when,
                             int32_t key_code,
                             bool isAltKeyDown,
                             bool isCtrlKeyDown,
                             bool isShiftKeyDown,
                             int32_t repeat) {
  const char *function = NULL;
  switch (event) {
    case kKeyDown:
      function = "onKeyDown_";
      break;
    case kKeyUp:
      function = "onKeyUp_";
      break;
    case kKeyMultiple:
      return -1;  // TODO(gram): handle this.
      break;
    default:
      return -1;
  }
  return vm_glue_->OnKeyEvent(function, when, key_code,
                              isAltKeyDown, isCtrlKeyDown, isShiftKeyDown,
                              repeat);
}

void InputHandler::OnAccelerometerEvent(float x, float y, float z) {
  vm_glue_->OnAccelerometerEvent(x, y, z);
}

