// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/android/android_sound_handler.h"

#include "embedders/openglui/android/android_resource.h"
#include "embedders/openglui/common/log.h"

AndroidSoundHandler::AndroidSoundHandler(android_app* application)
    : SoundHandler(),
      application_(application),
      engine_(NULL),
      engine_if_(NULL),
      output_mix_(NULL),
      background_player_(NULL),
      background_player_if_(NULL),
      background_player_seek_if_(NULL),
      sample_player_(NULL),
      sample_player_if_(NULL),
      sample_player_queue_(NULL) {
  SoundHandler::instance_ = this;
}

int32_t AndroidSoundHandler::Start() {
  LOGI("Starting SoundService");

  const SLInterfaceID k_engine_mix_IIDs[] = { SL_IID_ENGINE };
  const SLboolean k_engine_mix_reqs[] = { SL_BOOLEAN_TRUE };
  const SLInterfaceID k_output_mix_IIDs[] = {};
  const SLboolean k_output_mix_reqs[] = {};
  int32_t res = slCreateEngine(&engine_, 0, NULL, 1,
                               k_engine_mix_IIDs, k_engine_mix_reqs);
  if (res == SL_RESULT_SUCCESS) {
    res = (*engine_)->Realize(engine_, SL_BOOLEAN_FALSE);
    if (res == SL_RESULT_SUCCESS) {
      res = (*engine_)->GetInterface(engine_, SL_IID_ENGINE, &engine_if_);
      if (res == SL_RESULT_SUCCESS) {
        res = (*engine_if_)->CreateOutputMix(engine_if_, &output_mix_, 0,
                                  k_output_mix_IIDs, k_output_mix_reqs);
        if (res == SL_RESULT_SUCCESS) {
          res = (*output_mix_)->Realize(output_mix_, SL_BOOLEAN_FALSE);
          if (res == SL_RESULT_SUCCESS) {
            if (StartSamplePlayer() == 0) {
              return 0;
            }
          }
        }
      }
    }
  }
  LOGI("Failed to start SoundService");
  Stop();
  return -1;
}

void AndroidSoundHandler::Stop() {
  StopBackground();
  if (output_mix_ != NULL) {
    (*output_mix_)->Destroy(output_mix_);
    output_mix_ = NULL;
  }
  if (engine_ != NULL) {
    (*engine_)->Destroy(engine_);
    engine_ = NULL;
    engine_if_ = NULL;
  }
  if (sample_player_ != NULL) {
    (*sample_player_)->Destroy(sample_player_);
    sample_player_ = NULL;
    sample_player_if_ = NULL;
    sample_player_queue_ = NULL;
  }
  samples_.clear();
}

int32_t AndroidSoundHandler::CreateAudioPlayer(SLEngineItf engine_if,
                                        const SLInterfaceID extra_if,
                                        SLDataSource data_source,
                                        SLDataSink data_sink,
                                        SLObjectItf& player_out,
                                        SLPlayItf& player_if_out) {
  const SLuint32 SoundPlayerIIDCount = 2;
  const SLInterfaceID SoundPlayerIIDs[] = { SL_IID_PLAY, extra_if };
  const SLboolean SoundPlayerReqs[] = { SL_BOOLEAN_TRUE, SL_BOOLEAN_TRUE };
  int32_t res = (*engine_if)->CreateAudioPlayer(engine_if,
                                                &player_out,
                                                &data_source,
                                                &data_sink,
                                                SoundPlayerIIDCount,
                                                SoundPlayerIIDs,
                                                SoundPlayerReqs);

  if (res == SL_RESULT_SUCCESS) {
    res = (*player_out)->Realize(player_out, SL_BOOLEAN_FALSE);
    if (res == SL_RESULT_SUCCESS) {
      res = (*player_out)->GetInterface(sample_player_,
                                            SL_IID_PLAY,
                                            &player_if_out);
      if (res == SL_RESULT_SUCCESS) {
        return 0;
      }
    }
  }
  return -1;
}

int32_t AndroidSoundHandler::PlayBackground(const char* path) {
  LOGI("Creating audio player");

  Resource resource(path);
  int fd = resource.descriptor();
  if (fd < 0) {
    LOGI("Could not open file %s", path);
    return -1;
  }

  SLDataLocator_AndroidFD data_locator_in = {
      SL_DATALOCATOR_ANDROIDFD,
      fd,
      resource.start(),
      resource.length()
  };
  SLDataFormat_MIME data_format = {
      SL_DATAFORMAT_MIME,
      NULL,
      SL_CONTAINERTYPE_UNSPECIFIED
  };
  SLDataSource data_source = { &data_locator_in, &data_format };

  resource.Close();

  SLDataLocator_OutputMix data_locator_out =
      { SL_DATALOCATOR_OUTPUTMIX, output_mix_ };
  SLDataSink data_sink = { &data_locator_out, NULL };

  int32_t res = CreateAudioPlayer(engine_if_,
                                  SL_IID_SEEK,
                                  data_source,
                                  data_sink,
                                  background_player_,
                                  background_player_if_);

  if (res != SL_RESULT_SUCCESS) {
    LOGE("Couldn't create audio player");
    return -1;
  }

  if ((*background_player_)->
          GetInterface(background_player_, SL_IID_SEEK,
                       &background_player_seek_if_) != SL_RESULT_SUCCESS) {
    LOGE("Couldn't get seek interface");
    return -1;
  }
  LOGI("Got seek interface");
  if ((*background_player_seek_if_)->
          SetLoop(background_player_seek_if_, SL_BOOLEAN_TRUE, 0,
                  SL_TIME_UNKNOWN) != SL_RESULT_SUCCESS) {
    LOGE("Couldn't set loop");
    return -1;
  }
  LOGI("Set loop");
  if ((*background_player_if_)->
          SetPlayState(background_player_if_, SL_PLAYSTATE_PLAYING) !=
          SL_RESULT_SUCCESS) {
    LOGE("Couldn't start playing");
    return -1;
  }
  LOGI("Started playing");
  return 0;
}

void AndroidSoundHandler::StopBackground() {
  if (background_player_if_ != NULL) {
    SLuint32 state;
    (*background_player_)->GetState(background_player_, &state);
    if (state == SL_OBJECT_STATE_REALIZED) {
      (*background_player_if_)->SetPlayState(background_player_if_,
                                           SL_PLAYSTATE_PAUSED);

      (*background_player_)->Destroy(background_player_);
      background_player_ = NULL;
      background_player_if_ = NULL;
      background_player_seek_if_ = NULL;
    }
  }
}

int32_t AndroidSoundHandler::StartSamplePlayer() {
  SLDataLocator_AndroidSimpleBufferQueue data_locator_in = {
    SL_DATALOCATOR_ANDROIDSIMPLEBUFFERQUEUE,
    1
  };

  SLDataFormat_PCM data_format= {
    SL_DATAFORMAT_PCM,
    1,
    SL_SAMPLINGRATE_44_1,
    SL_PCMSAMPLEFORMAT_FIXED_16,
    SL_PCMSAMPLEFORMAT_FIXED_16,
    SL_SPEAKER_FRONT_CENTER,
    SL_BYTEORDER_LITTLEENDIAN
  };

  SLDataSource data_source = { &data_locator_in, &data_format };

  SLDataLocator_OutputMix data_locator_out =
      { SL_DATALOCATOR_OUTPUTMIX, output_mix_ };
  SLDataSink data_sink = { &data_locator_out, NULL };

  int32_t res = CreateAudioPlayer(engine_if_, SL_IID_BUFFERQUEUE,
                                  data_source,
                                  data_sink,
                                  sample_player_, sample_player_if_);

  if (res == SL_RESULT_SUCCESS) {
    res = (*sample_player_)->GetInterface(sample_player_,
                                          SL_IID_BUFFERQUEUE,
                                          &sample_player_queue_);
    if (res == SL_RESULT_SUCCESS) {
      res = (*sample_player_if_)->SetPlayState(sample_player_if_,
                                               SL_PLAYSTATE_PLAYING);
      if (res == SL_RESULT_SUCCESS) {
        return 0;
      }
    }
  }
  LOGE("Error while starting sample player");
  return -1;
}

int32_t AndroidSoundHandler::PlaySample(const char* path) {
  SLuint32 state;
  (*sample_player_)->GetState(sample_player_, &state);
  if (state != SL_OBJECT_STATE_REALIZED) {
    LOGE("Sample player has not been realized");
  } else {
    Sample* sample = GetSample(path);
    if (sample != NULL) {
      int16_t* buffer = reinterpret_cast<int16_t*>(sample->buffer());
      off_t len = sample->length();

      // Remove any current sample.
      int32_t res = (*sample_player_queue_)->Clear(sample_player_queue_);
      if (res == SL_RESULT_SUCCESS) {
        res = (*sample_player_queue_)->Enqueue(sample_player_queue_,
                                               buffer, len);
        if (res == SL_RESULT_SUCCESS) {
          return 0;
        }
        LOGE("Enqueueing sample failed");
      }
    }
  }
  return -1;
}


