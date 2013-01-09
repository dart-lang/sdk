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
  VMGlue vmGlue(&graphics);
  InputService inputService(application, &vmGlue,
      graphics.width(), graphics.height());
  SoundService sound_service(application);
  psound_service = &sound_service;
  Context context;
  context.graphics = &graphics;
  context.input_handler = &inputService;
  context.sound_service = psound_service;
  context.timer = &timer;
  context.vm_glue = &vmGlue;
  EventLoop eventLoop(application);
  DartHost host(&context);
  eventLoop.Run(&host, &context);
}

void PlayBackground(const char* path) {
  psound_service->PlayBackground(path);
}

void StopBackground() {
  psound_service->StopBackground();
}
