// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_DART_HOST_H_
#define EMBEDDERS_OPENGLUI_COMMON_DART_HOST_H_

#include "embedders/openglui/common/context.h"
#include "embedders/openglui/common/graphics_handler.h"
#include "embedders/openglui/common/input_handler.h"
#include "embedders/openglui/common/lifecycle_handler.h"
#include "embedders/openglui/common/sound_handler.h"
#include "embedders/openglui/common/timer.h"
#include "embedders/openglui/common/vm_glue.h"
#include "include/dart_api.h"

// Currently the life cycle management is very crude. We conservatively
// shutdown the main isolate when we lose focus and create a new one when
// we resume. This needs to be improved later when we understand this better,
// and we need some hooks to tell the Dart script to save/restore state
// (and an API that will support that).

class DartHost : public LifeCycleHandler {
 public:
  explicit DartHost(Context* context);
  virtual ~DartHost();

  void OnStart();
  void OnResume();
  void OnPause();
  void OnStop();
  void OnDestroy();
  void OnSaveState(void** data, size_t* size);
  void OnConfigurationChanged();
  void OnLowMemory();
  void OnCreateWindow();
  void OnDestroyWindow();
  void OnGainedFocus();
  void OnLostFocus();
  int32_t OnActivate();
  void OnDeactivate();
  int32_t OnStep();

 private:
  void Clear();
  int32_t Activate();
  void Deactivate();

  GraphicsHandler* graphics_handler_;
  InputHandler* input_handler_;
  SoundHandler* sound_handler_;
  Timer* timer_;
  VMGlue* vm_glue_;
  bool active_;
};

#endif  // EMBEDDERS_OPENGLUI_COMMON_DART_HOST_H_

