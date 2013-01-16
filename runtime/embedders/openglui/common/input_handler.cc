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
  switch (event) {
    case kMotionDown:
      function = "onMotionDown";
      break;
    case kMotionUp:
      function = "onMotionUp";
      break;
    case kMotionMove:
      function = "onMotionMove";
      break;
    case kMotionCancel:
      function = "onMotionCancel";
      break;
    case kMotionOutside:
      function = "onMotionOutside";
      break;
    case kMotionPointerDown:
      function = "onMotionPointerDown";
      break;
    case kMotionPointerUp:
      function = "onMotionPointerUp";
      break;
    default:
      return -1;
  }
  return vm_glue_->OnMotionEvent(function, when, x, y);
}

int InputHandler::OnKeyEvent(KeyEvent event,
                             int64_t when,
                             int32_t flags,
                             int32_t key_code,
                             int32_t meta_state,
                             int32_t repeat) {
  const char *function = NULL;
  switch (event) {
    case kKeyDown:
      function = "onKeyDown";
      break;
    case kKeyUp:
      function = "onKeyUp";
      break;
    case kKeyMultiple:
      function = "onKeyMultiple";
      break;
    default:
      return -1;
  }
  return vm_glue_->OnKeyEvent(function, when, flags, key_code,
                              meta_state, repeat);
}

