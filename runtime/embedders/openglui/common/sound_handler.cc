// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/sound_handler.h"

#include <string.h>

#include "embedders/openglui/common/log.h"

// TODO(gram): Clean up this instance pointer; either make the class
// a proper singleton or provide a cleaner way for the static functions
// at the end to access it (those functions are the hooks into the Dart
// native extension).
SoundHandler* instance_ = NULL;

SoundHandler::SoundHandler()
    : samples_() {
  instance_ = this;
}

Sample* SoundHandler::GetSample(const char* path) {
  for (samples_t::iterator sp = samples_.begin();
       sp != samples_.end();
       ++sp) {
    Sample* sample = (*sp);
    if (strcmp(sample->path(), path) == 0) {
      LOGI("Returning cached sample %s", path);
      return sample;
    }
  }
  Sample* sample = new Sample(path);
  if (sample->Load() != 0) {
    LOGI("Failed to load sample %s", path);
    delete sample;
    return NULL;
  }
  samples_.push_back(sample);
  LOGI("Adding sample %s to cache", path);
  return sample;
}

int32_t PlayBackgroundSound(const char* path) {
  return instance_->PlayBackground(path);
}

void StopBackgroundSound() {
  instance_->StopBackground();
}

int32_t LoadSoundSample(const char* path) {
  return instance_->LoadSample(path);
}

int32_t PlaySoundSample(const char* path) {
  return instance_->PlaySample(path);
}

