// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/android/eventloop.h"

#include "embedders/openglui/common/log.h"

EventLoop::EventLoop(android_app* application)
    : enabled_(false),
      quit_(false),
      application_(application),
      lifecycle_handler_(NULL),
      input_handler_(NULL) {
  application_->onAppCmd = ActivityCallback;
  application_->onInputEvent = InputCallback;
  application_->userData = this;
}

void EventLoop::Run(LifeCycleHandler* lifecycle_handler,
                    InputHandler* input_handler) {
  int32_t result;
  int32_t events;
  android_poll_source* source;

  lifecycle_handler_ = lifecycle_handler;
  input_handler_ = input_handler;
  LOGI("Starting event loop");
  while (true) {
    // If not enabled, block on events. If enabled, don't block
    // so we can do useful work in onStep.
    while ((result = ALooper_pollAll(enabled_ ? 0 : -1,
                                     NULL,
                                     &events,
                                     reinterpret_cast<void**>(&source))) >= 0) {
      if (source != NULL) {
        source->process(application_, source);
      }
      if (application_->destroyRequested) {
        return;
      }
    }
    if (enabled_ && !quit_) {
      LOGI("step");
      if (lifecycle_handler_->OnStep() != 0) {
        quit_ = true;
        ANativeActivity_finish(application_->activity);
      }
    }
  }
}

// Called when we gain focus.
void EventLoop::Activate() {
  LOGI("activate");
  if (!enabled_ && application_->window != NULL) {
    quit_ = false;
    enabled_ = true;
    if (lifecycle_handler_->OnActivate() != 0) {
      quit_ = true;
      ANativeActivity_finish(application_->activity);
    }
  }
}

// Called when we lose focus.
void EventLoop::Deactivate() {
  LOGI("deactivate");
  if (enabled_) {
    lifecycle_handler_->OnDeactivate();
    enabled_ = false;
  }
}

void EventLoop::ProcessActivityEvent(int32_t command) {
  switch (command) {
    case APP_CMD_CONFIG_CHANGED:
      lifecycle_handler_->OnConfigurationChanged();
      break;
    case APP_CMD_INIT_WINDOW:
      lifecycle_handler_->OnCreateWindow();
      break;
    case APP_CMD_DESTROY:
      lifecycle_handler_->OnDestroy();
      break;
    case APP_CMD_GAINED_FOCUS:
      Activate();
      lifecycle_handler_->OnGainedFocus();
      break;
    case APP_CMD_LOST_FOCUS:
      lifecycle_handler_->OnLostFocus();
      Deactivate();
      break;
    case APP_CMD_LOW_MEMORY:
      lifecycle_handler_->OnLowMemory();
      break;
    case APP_CMD_PAUSE:
      lifecycle_handler_->OnPause();
      Deactivate();
      break;
    case APP_CMD_RESUME:
      lifecycle_handler_->OnResume();
      break;
    case APP_CMD_SAVE_STATE:
      lifecycle_handler_->OnSaveState(&application_->savedState,
                                    &application_->savedStateSize);
      break;
    case APP_CMD_START:
      lifecycle_handler_->OnStart();
      break;
    case APP_CMD_STOP:
      lifecycle_handler_->OnStop();
      break;
    case APP_CMD_TERM_WINDOW:
      lifecycle_handler_->OnDestroyWindow();
      Deactivate();
      break;
    default:
      break;
  }
}

bool EventLoop::OnTouchEvent(AInputEvent* event) {
  int32_t type = AMotionEvent_getAction(event);
  MotionEvent motion_event;
  switch (type) {
    case AMOTION_EVENT_ACTION_DOWN:
      motion_event = kMotionDown;
      break;
    case AMOTION_EVENT_ACTION_UP:
      motion_event = kMotionUp;
      break;
    case AMOTION_EVENT_ACTION_MOVE:
      motion_event = kMotionMove;
      break;
    case AMOTION_EVENT_ACTION_CANCEL:
      motion_event = kMotionCancel;
      break;
    case AMOTION_EVENT_ACTION_OUTSIDE:
      motion_event = kMotionOutside;
      break;
    case AMOTION_EVENT_ACTION_POINTER_DOWN:
      motion_event = kMotionPointerDown;
      break;
    case AMOTION_EVENT_ACTION_POINTER_UP:
      motion_event = kMotionPointerUp;
      break;
    default:
      return false;
  }
  // For now we just get the last coords.
  float move_x = AMotionEvent_getX(event, 0);
  float move_y = AMotionEvent_getY(event, 0);
  int64_t when = AMotionEvent_getEventTime(event);
  LOGI("Got motion event %d at %f, %f", type, move_x, move_y);

  if (input_handler_->OnMotionEvent(motion_event, when, move_x, move_y) != 0) {
    return false;
  }
  return true;
}

bool EventLoop::OnKeyEvent(AInputEvent* event) {
  int32_t type = AKeyEvent_getAction(event);
  KeyEvent key_event;
  switch (type) {
    case AKEY_EVENT_ACTION_DOWN:
      key_event = kKeyDown;
      break;
    case AKEY_EVENT_ACTION_UP:
      key_event = kKeyUp;
      break;
    case AKEY_EVENT_ACTION_MULTIPLE:
      key_event = kKeyMultiple;
      break;
    default:
      return false;
  }
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
  if (input_handler_->OnKeyEvent(key_event, when, flags, key_code,
                             meta_state, repeat) != 0) {
    return false;
  }
  return true;
}

int32_t EventLoop::ProcessInputEvent(AInputEvent* event) {
  int32_t event_type = AInputEvent_getType(event);
  LOGI("Got input event type %d", event_type);
  switch (event_type) {
    case AINPUT_EVENT_TYPE_MOTION:
      if (AInputEvent_getSource(event) == AINPUT_SOURCE_TOUCHSCREEN) {
          return OnTouchEvent(event);
      }
      break;
    case AINPUT_EVENT_TYPE_KEY:
      return OnKeyEvent(event);
  }
  return 0;
}

void EventLoop::ActivityCallback(android_app* application, int32_t command) {
  EventLoop* event_loop = reinterpret_cast<EventLoop*>(application->userData);
  event_loop->ProcessActivityEvent(command);
}

int32_t EventLoop::InputCallback(android_app* application,
                                 AInputEvent* event) {
  EventLoop* event_loop = reinterpret_cast<EventLoop*>(application->userData);
  return event_loop->ProcessInputEvent(event);
}

