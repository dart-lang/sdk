// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_EVENTS_H_
#define EMBEDDERS_OPENGLUI_COMMON_EVENTS_H_

typedef enum {
  kStart,
  kStop,
  kGainedFocus,
  kLostFocus,
  kPause,
  kResume,
  kSaveState,
  kConfigChanged,
  kInitWindow,
  kTermWindow,
  kDestroy
} LifecycleEvent;

typedef enum {
  kKeyDown,
  kKeyUp,
  kKeyMultiple
} KeyEvent;

typedef enum {
  kMotionDown,
  kMotionUp,
  kMotionMove,
  kMotionCancel,
  kMotionOutside,
  kMotionPointerDown,
  kMotionPointerUp
} MotionEvent;

#endif  // EMBEDDERS_OPENGLUI_COMMON_EVENTS_H_

