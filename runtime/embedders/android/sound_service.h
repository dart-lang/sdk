// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_SOUND_SERVICE_H_
#define EMBEDDERS_ANDROID_SOUND_SERVICE_H_

#include <android_native_app_glue.h>
#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>
#include <SLES/OpenSLES_AndroidConfiguration.h>
#include <vector>
#include "embedders/android/sample.h"
#include "embedders/android/types.h"

class SoundService {
  public:
    explicit SoundService(android_app* application);
    int32_t Start();
    void Stop();

    int32_t PlayBackground(const char* path);
    void StopBackground();

    // Optional, for preloading.
    int32_t LoadSample(const char* path) {
       return (GetSample(path) == NULL) ? -1 : 0;
    }

    int32_t PlaySample(const char* path);

  private:
    typedef std::vector<Sample*> samples_t;

    int32_t CreateAudioPlayer(SLEngineItf engine_if,
                              const SLInterfaceID extra_if,
                              SLDataSource data_source,
                              SLDataSink data_sink,
                              SLObjectItf& player_out,
                              SLPlayItf& player_if_out);

    int32_t StartSamplePlayer();
    Sample* GetSample(const char* path);

    android_app* application_;
    SLObjectItf engine_;
    SLEngineItf engine_if_;
    SLObjectItf output_mix_;
    SLObjectItf background_player_;
    SLPlayItf background_player_if_;
    SLSeekItf background_player_seek_if_;
    SLObjectItf sample_player_;
    SLPlayItf sample_player_if_;
    SLBufferQueueItf sample_player_queue_;
    samples_t samples_;
};

int32_t PlayBackgroundSound(const char* path);
void StopBackgroundSound();
#endif  // EMBEDDERS_ANDROID_SOUND_SERVICE_H_
