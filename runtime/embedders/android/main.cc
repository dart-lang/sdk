// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/android/context.h"
#include "embedders/android/dart_host.h"
#include "embedders/android/eventloop.h"
#include "embedders/android/graphics.h"
#include "embedders/android/input_service.h"
#include "embedders/android/vm_glue.h"

SoundService* psound_service;

void android_main(android_app* application) {
  Timer timer;
  Graphics graphics(application, &timer);
  VMGlue vm_glue(&graphics);
  InputService input_handler(application, &vm_glue,
      graphics.width(), graphics.height());
  SoundService sound_service(application);
  Context app_context;
  app_context.graphics = &graphics;
  app_context.input_handler = &input_handler;
  app_context.sound_service = &sound_service;
  app_context.timer = &timer;
  app_context.vm_glue = &vm_glue;
  EventLoop eventLoop(application);
  DartHost host(&app_context);
  eventLoop.Run(&host, &app_context);
}

int32_t PlayBackgroundSound(const char* path) {
  return psound_service->PlayBackground(path);
}

void StopBackgroundSound() {
  psound_service->StopBackground();
}

int32_t LoadSoundSample(const char* path) {
  return psound_service->LoadSample(path);
}

int32_t PlaySoundSample(const char* path) {
  return psound_service->PlaySample(path);
}
