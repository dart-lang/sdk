// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_CONTEXT_H_
#define EMBEDDERS_ANDROID_CONTEXT_H_

class Graphics;
class InputHandler;
class SoundService;
class Timer;
class VMGlue;

struct Context {
  Graphics* graphics;
  InputHandler* input_handler;
  SoundService* sound_service;
  Timer* timer;
  VMGlue* vm_glue;
};

#endif  // EMBEDDERS_ANDROID_CONTEXT_H_
