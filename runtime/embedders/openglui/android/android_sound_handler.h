// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_ANDROID_ANDROID_SOUND_HANDLER_H_
#define EMBEDDERS_OPENGLUI_ANDROID_ANDROID_SOUND_HANDLER_H_

#include <android_native_app_glue.h>
#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>
#include <SLES/OpenSLES_AndroidConfiguration.h>
#include <vector>

#include "embedders/openglui/common/sample.h"
#include "embedders/openglui/common/sound_handler.h"
#include "embedders/openglui/common/types.h"

class AndroidSoundHandler : public SoundHandler {
  public:
    explicit AndroidSoundHandler(android_app* application);
    int32_t Start();
    void Stop();
    int32_t Pause();
    int32_t Resume();

    int32_t PlayBackground(const char* path);
    void StopBackground();

    int32_t PlaySample(const char* path);

  private:
    int32_t CreateAudioPlayer(SLEngineItf engine_if,
                              const SLInterfaceID extra_if,
                              SLDataSource data_source,
                              SLDataSink data_sink,
                              SLObjectItf& player_out,
                              SLPlayItf& player_if_out);

    int32_t SetBackgroundPlayerState(int state);
    int32_t StartSamplePlayer();

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
};

#endif  // EMBEDDERS_OPENGLUI_ANDROID_ANDROID_SOUND_HANDLER_H_

