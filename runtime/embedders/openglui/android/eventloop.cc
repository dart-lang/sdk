// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/android/eventloop.h"

#include <time.h>
#include "embedders/openglui/common/log.h"

/*
 * The Android lifecycle events are:
 *
 * OnCreate: In NDK this is the call to android_main
 *
 * OnStart: technically, called to initiate the “visible” lifespan of the
 *     app; at any time between OnStart and OnStop, the app may be visible.
 *     We can either be OnResume’d or OnStop’ped from this state. Note that
 *     there is also an event for OnRestart, which is called before OnStart
 *     if the application is transitioning from OnStop to OnStart instead of
 *     being started from scratch.
 *
 * OnResume: technically, the start of the “foreground” lifespan of the app, 
 *     but this does not mean that the app is fully visible and should be 
 *     rendering – more on that later
 *
 * OnPause: the app is losing its foregrounded state; this is normally an 
 *     indication that something is fully covering the app. On versions of 
 *     Android before Honeycomb, once we returned from this callback, we 
 *     could be killed at any time with no further app code called. We can
 *     either be OnResume’d or OnStop’ped from this state. OnPause halts the 
 *     visible UI thread and so should be handled as quickly as possible.
 *
 * OnStop: the end of the current visible lifespan of the app – we may
 *     transition to On(Re)Start to become visible again, or to OnDestroy if
 *      we are shutting down entirely. Once we return from this callback, we
 *      can be killed at any time with no further app code called on any
 *      version of Android.
 *
 * OnDestroy: this can only be followed by the application being killed or
 *     restarted with OnCreate.
 *
 * The above events occur in fixed orders. The events below can occur at 
 * various times:
 *
 * OnGainedFocus: happens between OnResume and OnPause.
 * OnLostFocus:  may occur at arbitrary times, and may in fact not happen
 *     at all if the app is being destroyed. So OnPause and OnGainedFocus/
 *     OnLostFocus must be used together to determine the visible and
 *     interactable state of the app.
 *
 * OnCreateWindow: usually happens in the resumed state
 * OnDestroyWindow: can happen after OnPause or OnDestroy, so apps may
 *     need to handle shutting down EGL before their surfaces are
 *     destroyed.
 * OnConfigurationChanged: typically means the size has changed
 *
 * An application's EGL surface may only exist between the OnCreateWindow
 * and OnDestroyWindow callbacks.
 *
 * An application is "killable" after OnStop or OnDestroy (in earlier 
 * Android versions, after OnPause too). That means any critical state
 * or resources must be handled by any of these callbacks.
 *
 * These callbacks run on the main thread. If they block any event
 * processing for more than 5 seconds this will result in an ANR
 * (Application Not Responding message).
 *
 * On application launch, this sequence will occur:
 *
 * - OnCreate
 * - OnStart
 * - OnResume
 * - OnCreateWindow
 * - OnConfigurationChanged
 * - OnGainedFocus
 *
 * If the back button is pressed, and the app does not handle it,
 * Android will pop the app of the UI stack and destroy the application's
 * activity:
 *
 * - OnPause
 * - OnLostFocus
 * - OnDestroyWindow
 * - OnStop
 * - OnDestroy
 *
 * If the home button is pressed, the app is sent down in the UI stack.
 * The app's Activity still exists but may be killed at any time, and
 * it loses its rendering surface:
 *
 * - OnPause
 * - OnLostFocus
 * - OnDestroyWindow
 * - OnStop
 *
 * If the app is then restarted (without having been killed in between):
 *
 * - OnRestart
 * - OnStart
 * - OnResume
 * - OnCreateWindow
 * - OnConfigurationChanged
 * - OnGainedFocus
 *
 * If a status icon pop up is opened, the app is still visible and can render
 * but is not focused and cannot receive input:
 *
 * - OnLostFocus
 *
 * When the popup is dismissed, the app regains focus:
 *
 * - OnGainedFocus
 *
 * When the device is suspended (power button or screen saver), the application
 * will typically be paused and lose focus:
 *
 * - OnPause
 * - OnLostFocus (sometimes this will only come when the device is resumed
 *       to the lock screen)
 *
 * The application should have stopped all rendering and sound and any
 * non-critical background processing.
 *
 * When the device is resumed but not yet unlocked, the app will be resumed:
 * 
 * - OnResume
 *
 * The application should not perform sound or graphics yet. If the lock 
 * screen times out, the app will be paused again. If the screen is
 * unlocked, the app will regain focus.
 *
 * Turning all of this into a general framework, we can use the following:
 *
 * 1. In OnCreate/android_main, set up the main classes and possibly
 *    load some lightweight resources.
 * 2. In OnCreateWindow, create the EGLSurface, bind the context, load 
 *    OpenGL resources. No rendering.
 * 3. When we are between OnResume and OnPause, and between OnCreateWindow
 *    and OnDestroyWindow, and between OnGainedFocus and OnLostFocus,
 *    we can render and process input.
 * 4. In OnLostFocus, stop sounds from playing, and stop rendering.
 * 5. In OnPause, stop all rendering
 * 6. In OnResume, prepare to start rendering again, but don't render.
 * 7. In OnGainedFocus after OnResume, start rendering and sound again.
 * 8. In OnStop, free all graphic resources, either through GLES calls
 *    if the EGLContext is still bound, or via eglDestroyContext if the
 *    context has been unbound because the rendering surface was destroyed.
 * 9. In OnDestroy, release all other resources.
 */
EventLoop::EventLoop(android_app* application)
    : enabled_(false),
      quit_(false),
      isResumed_(false),
      hasSurface_(false),
      hasFocus_(false),
      application_(application),
      lifecycle_handler_(NULL),
      input_handler_(NULL),
      sensor_manager_(NULL),
      sensor_event_queue_(NULL),
      sensor_poll_source_() {
  application_->onAppCmd = ActivityCallback;
  application_->onInputEvent = InputCallback;
  application_->userData = this;
}

static int64_t getTimeInMillis() {
  struct timespec res;
  clock_gettime(CLOCK_REALTIME, &res);
  return 1000 * res.tv_sec + res.tv_nsec / 1000000;
}

void EventLoop::Run(LifeCycleHandler* lifecycle_handler,
                    InputHandler* input_handler) {
  int32_t result;
  int32_t events;
  android_poll_source* source;

  lifecycle_handler_ = lifecycle_handler;
  input_handler_ = input_handler;
  int64_t last_frame_time = getTimeInMillis();
  if (lifecycle_handler_->OnStart() == 0) {
    LOGI("Starting event loop");
    while (!quit_) {
      // If not enabled, block indefinitely on events. If enabled, block
      // briefly so we can do useful work in onStep, but only long
      // enough that we can still do work at 60fps if possible.
      int64_t next_frame_time = last_frame_time + (1000/60);
      int64_t next_frame_delay = next_frame_time - getTimeInMillis();
      if (next_frame_delay < 0) next_frame_delay = 0;
      while ((result = ALooper_pollAll(enabled_ ? next_frame_delay : -1, NULL,
          &events, reinterpret_cast<void**>(&source))) >= 0) {
        if (source != NULL) {
          source->process(application_, source);
        }
        if (application_->destroyRequested) {
          return;
        }
      }
      if (enabled_ && !quit_) {
        int64_t now = getTimeInMillis();
        if (now >= next_frame_time) {
          LOGI("step");
          last_frame_time = now;
          if (lifecycle_handler_->OnStep() != 0) {
            quit_ = true;
          }
        }
      }
    }
  }
  ANativeActivity_finish(application_->activity);
}

void EventLoop::EnableSensorEvents() {
  sensor_poll_source_.id = LOOPER_ID_USER;
  sensor_poll_source_.app = application_;
  sensor_poll_source_.process = SensorCallback;
  sensor_manager_ = ASensorManager_getInstance();
  if (sensor_manager_ != NULL) {
    sensor_event_queue_ = ASensorManager_createEventQueue(
        sensor_manager_, application_->looper,
        LOOPER_ID_USER, NULL, &sensor_poll_source_);

    sensor_ = ASensorManager_getDefaultSensor(sensor_manager_,
        ASENSOR_TYPE_ACCELEROMETER);
    if (sensor_ != NULL) {
      int32_t min_delay = ASensor_getMinDelay(sensor_);
      if (ASensorEventQueue_enableSensor(sensor_event_queue_, sensor_) < 0 ||
          ASensorEventQueue_setEventRate(sensor_event_queue_, sensor_,
              min_delay) < 0) {
        LOGE("Error while activating sensor.");
        DisableSensorEvents();
        return;
      }
      LOGI("Activating sensor:");
      LOGI("Name       : %s", ASensor_getName(sensor_));
      LOGI("Vendor     : %s", ASensor_getVendor(sensor_));
      LOGI("Resolution : %f", ASensor_getResolution(sensor_));
      LOGI("Min Delay  : %d", min_delay);
    } else {
      LOGI("No sensor");
    }
  }
}

void EventLoop::DisableSensorEvents() {
  if (sensor_ != NULL) {
    if (ASensorEventQueue_disableSensor(sensor_event_queue_, sensor_) < 0) {
      LOGE("Error while deactivating sensor.");
    }
    sensor_ = NULL;
  }
  if (sensor_event_queue_ != NULL) {
    ASensorManager_destroyEventQueue(sensor_manager_,
                    sensor_event_queue_);
    sensor_event_queue_ = NULL;
  }
  sensor_manager_ = NULL;
}

void EventLoop::ProcessActivityEvent(int32_t command) {
  switch (command) {
    case APP_CMD_INIT_WINDOW:
      if (lifecycle_handler_->Activate() != 0) {
        quit_ = true;
      } else {
        hasSurface_ = true;
      }
      break;
    case APP_CMD_CONFIG_CHANGED:
      lifecycle_handler_->OnConfigurationChanged();
      break;
    case APP_CMD_DESTROY:
      hasFocus_ = false;
      lifecycle_handler_->FreeAllResources();
      break;
    case APP_CMD_GAINED_FOCUS:
      hasFocus_ = true;
      if (hasSurface_ && isResumed_ && hasFocus_) {
        enabled_ = (lifecycle_handler_->Resume() == 0);
        if (enabled_) {
          EnableSensorEvents();
        }
      }
      break;
    case APP_CMD_LOST_FOCUS:
      hasFocus_ = false;
      enabled_ = false;
      DisableSensorEvents();
      lifecycle_handler_->Pause();
      break;
    case APP_CMD_LOW_MEMORY:
      lifecycle_handler_->OnLowMemory();
      break;
    case APP_CMD_PAUSE:
      isResumed_ = false;
      enabled_ = false;
      DisableSensorEvents();
      lifecycle_handler_->Pause();
      break;
    case APP_CMD_RESUME:
      isResumed_ = true;
      break;
    case APP_CMD_SAVE_STATE:
      lifecycle_handler_->OnSaveState(&application_->savedState,
                                    &application_->savedStateSize);
      break;
    case APP_CMD_START:
      break;
    case APP_CMD_STOP:
      hasFocus_ = false;
      lifecycle_handler_->Deactivate();
      break;
    case APP_CMD_TERM_WINDOW:
      hasFocus_ = false;
      hasSurface_ = false;
      enabled_ = false;
      DisableSensorEvents();
      lifecycle_handler_->Pause();
      break;
    default:
      break;
  }
}

void EventLoop::ProcessSensorEvent() {
  ASensorEvent event;
  while (ASensorEventQueue_getEvents(sensor_event_queue_, &event, 1) > 0) {
    switch (event.type) {
      case ASENSOR_TYPE_ACCELEROMETER:
        input_handler_->OnAccelerometerEvent(event.vector.x,
            event.vector.y, event.vector.z);
        break;
    }
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
  bool isAltKeyDown = (meta_state & AMETA_ALT_ON) != 0;
  bool isShiftKeyDown = (meta_state & AMETA_SHIFT_ON) != 0;
  bool isCtrlKeyDown = key_code < 32;

  LOGI("Got key event %d %d", type, key_code);

  if (input_handler_->OnKeyEvent(key_event, when, key_code,
                                 isAltKeyDown, isCtrlKeyDown, isShiftKeyDown,
                                 repeat) != 0) {
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

void EventLoop::SensorCallback(android_app* application,
    android_poll_source* source) {
  EventLoop* event_loop = reinterpret_cast<EventLoop*>(application->userData);
  event_loop->ProcessSensorEvent();
}

