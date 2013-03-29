// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/dart_host.h"

#include <math.h>
#include <unistd.h>

#include "embedders/openglui/common/image_cache.h"
#include "embedders/openglui/common/log.h"

DartHost::DartHost(Context *context)
    : graphics_handler_(context->graphics_handler),
      input_handler_(context->input_handler),
      sound_handler_(context->sound_handler),
      timer_(context->timer),
      vm_glue_(context->vm_glue),
      has_context_(false),
      started_(false),
      active_(false) {
  ImageCache::Init(graphics_handler_->resource_path());
}

DartHost::~DartHost() {
}

int32_t DartHost::OnStart() {
  int result = vm_glue_->StartMainIsolate();
  if (result != 0) {
    LOGE("startMainIsolate returned %d", result);
    return -1;
  }
  started_ = true;
  return 0;
}

int32_t DartHost::Activate() {
  if (!has_context_) {
    if (graphics_handler_->Start() != 0) {
      return -1;
    }
    if (sound_handler_->Start() != 0) {
      graphics_handler_->Stop();
      return -1;
    }
    if (input_handler_->Start() != 0) {
      sound_handler_->Stop();
      graphics_handler_->Stop();
      return -1;
    }
    int32_t rtn = vm_glue_->CallSetup(true);
    timer_->Reset();
    has_context_ = true;
    return rtn;
  }
  return 0;
}

void DartHost::Deactivate() {
  Pause();
  if (has_context_) {
    vm_glue_->CallShutdown();
    input_handler_->Stop();
    sound_handler_->Stop();
    graphics_handler_->Stop();
    has_context_ = false;
  }
}

int32_t DartHost::OnStep() {
  if (active_) {
    timer_->Update();
    if (vm_glue_->CallUpdate() != 0 ||
        graphics_handler_->Update() != 0) {
      return -1;
    }
  }
  return 0;
}

int32_t DartHost::Resume() {
  if (!active_) {
    if (Activate() == 0) {
      sound_handler_->Resume();
      active_ = true;
    }
  }
  return 0;
}

void DartHost::Pause() {
  if (active_) {
    active_ = false;  // This stops update() calls.
    sound_handler_->Suspend();
  }
}

void DartHost::FreeAllResources() {
  if (started_) {
    vm_glue_->FinishMainIsolate();
    started_ = false;
  }
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

