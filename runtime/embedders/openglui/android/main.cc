// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/android/android_graphics_handler.h"
#include "embedders/openglui/android/android_input_handler.h"
#include "embedders/openglui/android/android_sound_handler.h"
#include "embedders/openglui/android/eventloop.h"
#include "embedders/openglui/common/context.h"
#include "embedders/openglui/common/dart_host.h"
#include "embedders/openglui/common/vm_glue.h"

void android_main(android_app* application) {
  app_dummy();  // Link in native_app_glue.
  AndroidGraphicsHandler graphics_handler(application);
  VMGlue vm_glue(&graphics_handler, "/data/data/com.google.dartndk/app_dart");
  AndroidInputHandler input_handler(&vm_glue, &graphics_handler);
  AndroidSoundHandler sound_handler(application);
  Timer timer;
  Context app_context;
  app_context.graphics_handler = &graphics_handler;
  app_context.input_handler = &input_handler;
  app_context.sound_handler = &sound_handler;
  app_context.timer = &timer;
  app_context.vm_glue = &vm_glue;
  EventLoop eventLoop(application);
  DartHost host(&app_context);
  eventLoop.Run(&host, &input_handler);
}

