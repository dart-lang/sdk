// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/android/eventloop.h"
#include "embedders/android/log.h"

EventLoop::EventLoop(android_app* application)
    : enabled_(false),
      quit_(false),
      application_(application),
      activity_handler_(NULL),
      input_handler_(NULL) {
  application_->onAppCmd = ActivityCallback;
  application_->onInputEvent = InputCallback;
  application_->userData = this;
}

void EventLoop::Run(ActivityHandler* activity_handler,
                    Context* context) {
  int32_t result;
  int32_t events;
  android_poll_source* source;

  // TODO(vsm): We need to link in native_app_glue.
  // app_dummy();
  activity_handler_ = activity_handler;
  input_handler_ = context->input_handler;
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
      if (activity_handler_->OnStep() != 0) {
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
    if (activity_handler_->OnActivate() != 0) {
      quit_ = true;
      ANativeActivity_finish(application_->activity);
    }
  }
}

// Called when we lose focus.
void EventLoop::Deactivate() {
  LOGI("deactivate");
  if (enabled_) {
    activity_handler_->OnDeactivate();
    enabled_ = false;
  }
}

void EventLoop::ProcessActivityEvent(int32_t command) {
  switch (command) {
    case APP_CMD_CONFIG_CHANGED:
      activity_handler_->OnConfigurationChanged();
      break;
    case APP_CMD_INIT_WINDOW:
      activity_handler_->OnCreateWindow();
      break;
    case APP_CMD_DESTROY:
      activity_handler_->OnDestroy();
      break;
    case APP_CMD_GAINED_FOCUS:
      Activate();
      activity_handler_->OnGainedFocus();
      break;
    case APP_CMD_LOST_FOCUS:
      activity_handler_->OnLostFocus();
      Deactivate();
      break;
    case APP_CMD_LOW_MEMORY:
      activity_handler_->OnLowMemory();
      break;
    case APP_CMD_PAUSE:
      activity_handler_->OnPause();
      Deactivate();
      break;
    case APP_CMD_RESUME:
      activity_handler_->OnResume();
      break;
    case APP_CMD_SAVE_STATE:
      activity_handler_->OnSaveState(&application_->savedState,
                                    &application_->savedStateSize);
      break;
    case APP_CMD_START:
      activity_handler_->OnStart();
      break;
    case APP_CMD_STOP:
      activity_handler_->OnStop();
      break;
    case APP_CMD_TERM_WINDOW:
      activity_handler_->OnDestroyWindow();
      Deactivate();
      break;
    default:
      break;
  }
}

int32_t EventLoop::ProcessInputEvent(AInputEvent* event) {
  int32_t event_type = AInputEvent_getType(event);
  LOGI("Got input event type %d", event_type);
  switch (event_type) {
    case AINPUT_EVENT_TYPE_MOTION:
      if (AInputEvent_getSource(event) == AINPUT_SOURCE_TOUCHSCREEN) {
          return input_handler_->OnTouchEvent(event);
      }
      break;
    case AINPUT_EVENT_TYPE_KEY:
      return input_handler_->OnKeyEvent(event);
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
