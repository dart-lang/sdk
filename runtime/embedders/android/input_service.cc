// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <android_native_app_glue.h>
#include <cmath>

#include "embedders/android/input_service.h"
#include "embedders/android/log.h"

InputService::InputService(android_app* application,
                           VMGlue* vm_glue,
                           const int32_t& width,
                           const int32_t& height) :
  application_(application),
  vm_glue_(vm_glue),
  width_(width),
  height_(height) {
}

int32_t InputService::Start() {
  if ((width_ == 0) || (height_ == 0)) {
    return -1;
  }
  return 0;
}

bool InputService::OnTouchEvent(AInputEvent* event) {
  int32_t type = AMotionEvent_getAction(event);
  const char *function = NULL;
  switch (type) {
    case AMOTION_EVENT_ACTION_DOWN:
      function = "onMotionDown";
      break;
    case AMOTION_EVENT_ACTION_UP:
      function = "onMotionUp";
      break;
    case AMOTION_EVENT_ACTION_MOVE:
      function = "onMotionMove";
      break;
    case AMOTION_EVENT_ACTION_CANCEL:
      function = "onMotionCancel";
      break;
    case AMOTION_EVENT_ACTION_OUTSIDE:
      function = "onMotionOutside";
      break;
    case AMOTION_EVENT_ACTION_POINTER_DOWN:
      function = "onMotionPointerDown";
      break;
    case AMOTION_EVENT_ACTION_POINTER_UP:
      function = "onMotionPointerUp";
      break;
    default:
      break;
  }
  if (function != NULL) {
    // For now we just get the last coords.
    float move_x = AMotionEvent_getX(event, 0);
    float move_y = AMotionEvent_getY(event, 0);
    int64_t when = AMotionEvent_getEventTime(event);
    LOGI("Got motion event %d at %f, %f", type, move_x, move_y);

    if (vm_glue_->OnMotionEvent(function, when, move_x, move_y) != 0) {
      return false;
    }
  } else {
    return false;
  }
  return true;
}

bool InputService::OnKeyEvent(AInputEvent* event) {
  int32_t type = AKeyEvent_getAction(event);
  const char *function = NULL;
  switch (type) {
    case AKEY_EVENT_ACTION_DOWN:
      function = "onKeyDown";
      break;
    case AKEY_EVENT_ACTION_UP:
      function = "onKeyUp";
      break;
    case AKEY_EVENT_ACTION_MULTIPLE:
      function = "onKeyMultiple";
      break;
  }
  if (function != NULL) {
    int32_t flags = AKeyEvent_getFlags(event);
    /* Get the key code of the key event.
     * This is the physical key that was pressed, not the Unicode character. */
    int32_t key_code = AKeyEvent_getKeyCode(event);
    /* Get the meta key state. */
    int32_t meta_state = AKeyEvent_getMetaState(event);
    /* Get the repeat count of the event.
     * For both key up an key down events, this is the number of times the key
     * has repeated with the first down starting at 0 and counting up from
     * there.  For multiple key events, this is the number of down/up pairs
     * that have occurred. */
    int32_t repeat = AKeyEvent_getRepeatCount(event);

    /* Get the time of the most recent key down event, in the	
     * java.lang.System.nanoTime() time base.  If this is a down event,	
     * this will be the same as eventTime.	
     * Note that when chording keys, this value is the down time of the most	
     * recently pressed key, which may not be the same physical key of this	
     * event. */	
    // TODO(gram): Use or remove this.
    // int64_t key_down_time = AKeyEvent_getDownTime(event);

    /* Get the time this event occurred, in the
     * java.lang.System.nanoTime() time base. */
    int64_t when = AKeyEvent_getEventTime(event);

    LOGI("Got key event %d %d", type, key_code);
    if (vm_glue_->OnKeyEvent(function, when, flags, key_code,
                             meta_state, repeat) != 0) {
      return false;
    }
  } else {
    return false;
  }
  return true;
}
