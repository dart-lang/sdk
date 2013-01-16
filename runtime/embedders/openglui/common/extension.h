// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_EXTENSION_H_
#define EMBEDDERS_OPENGLUI_COMMON_EXTENSION_H_

#include "include/dart_api.h"

Dart_NativeFunction ResolveName(Dart_Handle name, int argc);

extern int32_t PlayBackgroundSound(const char* path);
extern void StopBackgroundSound();
extern int32_t LoadSoundSample(const char* path);
extern int32_t PlaySoundSample(const char* path);

#endif  // EMBEDDERS_OPENGLUI_COMMON_EXTENSION_H_

