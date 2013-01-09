// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_DART_HOST_H_
#define EMBEDDERS_ANDROID_DART_HOST_H_

#include <android_native_app_glue.h>
#include "include/dart_api.h"
#include "embedders/android/activity_handler.h"
#include "embedders/android/context.h"
#include "embedders/android/graphics.h"
#include "embedders/android/input_service.h"
#include "embedders/android/sound_service.h"
#include "embedders/android/timer.h"
#include "embedders/android/vm_glue.h"

// Currently the life cycle management is very crude. We conservatively
// shutdown the main isolate when we lose focus and create a new one when
// we resume. This needs to be improved later when we understand this better,
// and we need some hooks to tell the Dart script to save/restore state
// (and an API that will support that).

class DartHost : public ActivityHandler {
 public:
  explicit DartHost(Context* context);
  virtual ~DartHost();

 protected:
  int32_t OnActivate();
  void OnDeactivate();
  int32_t OnStep();

  void OnStart();
  void OnResume();
  void OnPause();
  void OnStop();
  void OnDestroy();

  void OnSaveState(void** data, size_t size);
  void OnConfigurationChanged();
  void OnLowMemory();
  void OnCreateWindow();
  void OnDestroyWindow();
  void OnGainedFocus();
  void OnLostFocus();

 private:
  void Clear();
  int32_t Activate();
  void Deactivate();

  ANativeWindow_Buffer window_buffer_;
  Graphics* graphics_;
  InputHandler* input_handler_;
  SoundService* sound_service_;
  Timer* timer_;
  VMGlue* vm_glue_;
  bool active_;
};

#endif  // EMBEDDERS_ANDROID_DART_HOST_H_
