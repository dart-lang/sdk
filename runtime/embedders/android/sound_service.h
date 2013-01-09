// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_SOUND_SERVICE_H_
#define EMBEDDERS_ANDROID_SOUND_SERVICE_H_

#include <android_native_app_glue.h>
#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>
#include <SLES/OpenSLES_AndroidConfiguration.h>
#include "embedders/android/types.h"

class SoundService {
  public:
    explicit SoundService(android_app* application);
    int32_t Start();
    void Stop();

    int32_t PlayBackground(const char* path);
    void StopBackground();

  private:
    android_app* application_;
    SLObjectItf engine_;
    SLEngineItf engine_if_;
    SLObjectItf output_mix_;
    SLObjectItf background_player_;
    SLPlayItf background_player_if_;
    SLSeekItf background_player_seek_if_;
};

void PlayBackground(const char* path);
void StopBackground();
#endif  // EMBEDDERS_ANDROID_SOUND_SERVICE_H_
