// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_ANDROID_EXTENSION_H_
#define EMBEDDERS_ANDROID_ANDROID_EXTENSION_H_

#include "include/dart_api.h"

Dart_NativeFunction ResolveName(Dart_Handle name, int argc);

void PlayBackground(const char* path);
void StopBackground();

#endif  // EMBEDDERS_ANDROID_ANDROID_EXTENSION_H_
