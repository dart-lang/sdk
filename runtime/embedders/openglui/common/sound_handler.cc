// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/sound_handler.h"

#include <string.h>

#include "embedders/openglui/common/log.h"

SoundHandler* SoundHandler::instance_ = NULL;

SoundHandler::SoundHandler()
    : samples_() {
}

Sample* SoundHandler::GetSample(const char* path) {
  for (samples_t::iterator sp = samples_.begin();
       sp != samples_.end();
       ++sp) {
    Sample* sample = (*sp);
    if (strcmp(sample->path(), path) == 0) {
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
  return sample;
}


int32_t PlayBackgroundSound(const char* path) {
  return SoundHandler::instance()->PlayBackground(path);
}

void StopBackgroundSound() {
  SoundHandler::instance()->StopBackground();
}

int32_t LoadSoundSample(const char* path) {
  return SoundHandler::instance()->LoadSample(path);
}

int32_t PlaySoundSample(const char* path) {
  return SoundHandler::instance()->PlaySample(path);
}

