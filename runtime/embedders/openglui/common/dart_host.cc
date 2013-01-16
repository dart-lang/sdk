// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/dart_host.h"

#include <math.h>
#include <unistd.h>

#include "embedders/openglui/common/log.h"

DartHost::DartHost(Context *context)
    : graphics_handler_(context->graphics_handler),
      input_handler_(context->input_handler),
      sound_handler_(context->sound_handler),
      timer_(context->timer),
      vm_glue_(context->vm_glue),
      active_(false) {
  LOGI("Creating DartHost");
}

DartHost::~DartHost() {
  LOGI("Freeing DartHost");
}

int32_t DartHost::OnActivate() {
  return Activate();
}

int32_t DartHost::Activate() {
  if (!active_) {
    LOGI("Activating DartHost");
    if (graphics_handler_->Start() != 0) {
      return -1;
    }
    if (sound_handler_->Start() != 0) {
      return -1;
    }
    if (input_handler_->Start() != 0) {
      return -1;
    }
    timer_->reset();
    LOGI("Starting main isolate");
    int result = vm_glue_->StartMainIsolate();
    if (result != 0) {
      LOGE("startMainIsolate returned %d", result);
      return -1;
    }
    active_ = true;
    vm_glue_->CallSetup();
  }
  return 0;
}

void DartHost::OnDeactivate() {
  Deactivate();
}

void DartHost::Deactivate() {
  if (active_) {
    active_ = false;
    vm_glue_->FinishMainIsolate();
    LOGI("Deactivating DartHost");
    input_handler_->Stop();
    sound_handler_->Stop();
    graphics_handler_->Stop();
  }
}

int32_t DartHost::OnStep() {
  timer_->update();
  vm_glue_->CallUpdate();
  if (graphics_handler_->Update() != 0) {
    return -1;
  }
  return 0;
}

void DartHost::OnStart() {
  LOGI("Starting DartHost");
}

void DartHost::OnResume() {
  LOGI("Resuming DartHost");
}

void DartHost::OnPause() {
  LOGI("Pausing DartHost");
}

void DartHost::OnStop() {
  LOGI("Stopping DartHost");
}

void DartHost::OnDestroy() {
  LOGI("Destroying DartHost");
}

void DartHost::OnSaveState(void** data, size_t* size) {
  LOGI("Saving DartHost state");
}

void DartHost::OnConfigurationChanged() {
  LOGI("DartHost config changed");
}

void DartHost::OnLowMemory() {
  LOGI("DartHost low on memory");
}

void DartHost::OnCreateWindow() {
  LOGI("DartHost creating window");
}

void DartHost::OnDestroyWindow() {
  LOGI("DartHost destroying window");
}

void DartHost::OnGainedFocus() {
  LOGI("DartHost gained focus");
}

void DartHost::OnLostFocus() {
  LOGI("DartHost lost focus");
}

