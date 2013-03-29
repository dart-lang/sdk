// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_SOUND_HANDLER_H_
#define EMBEDDERS_OPENGLUI_COMMON_SOUND_HANDLER_H_

#include <stdint.h>
#include <vector>

#include "embedders/openglui/common/sample.h"

class SoundHandler {
  public:
    SoundHandler();

    virtual ~SoundHandler() {
    }

    virtual int32_t Start() {
      return 0;
    }

    virtual void Stop() {
    }

    virtual int32_t Suspend() {
      return 0;
    }

    virtual int32_t Resume() {
      return 0;
    }

    virtual int32_t PlayBackground(const char* path) {
      return 0;
    }

    virtual void StopBackground() {
    }

    // Optional, for preloading.
    int32_t LoadSample(const char* path) {
       return (GetSample(path) == NULL) ? -1 : 0;
    }

    virtual int32_t PlaySample(const char* path) {
      // Just do a load so we can get logging.
      return (GetSample(path) == NULL) ? -1 : 0;
    }

  protected:
    typedef std::vector<Sample*> samples_t;

    Sample* GetSample(const char* path);

    samples_t samples_;
};

int32_t PlayBackgroundSound(const char* path);
void StopBackgroundSound();
int32_t LoadSoundSample(const char* path);
int32_t PlaySoundSample(const char* path);

#endif  // EMBEDDERS_OPENGLUI_COMMON_SOUND_HANDLER_H_

