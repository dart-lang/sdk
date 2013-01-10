// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_VM_GLUE_H_
#define EMBEDDERS_ANDROID_VM_GLUE_H_

#include <android_native_app_glue.h>

#include "include/dart_api.h"
#include "embedders/android/graphics.h"

class VMGlue {
 public:
  explicit VMGlue(Graphics* graphics);

  int InitializeVM();
  int StartMainIsolate();
  int CallSetup();
  int CallUpdate();
  int OnMotionEvent(const char* function, int64_t when,
                    float move_x, float move_y);
  int OnKeyEvent(const char* function, int64_t when, int32_t flags,
             int32_t key_code, int32_t meta_state, int32_t repeat);
  void FinishMainIsolate();

 private:
  int Invoke(const char *function, int argc, Dart_Handle* args,
             bool failIfNotDefined = true);

  static int ErrorExit(const char* format, ...);
  static Dart_Handle CheckError(Dart_Handle);

  static bool CreateIsolateAndSetupHelper(const char* script_uri,
                                          const char* main,
                                          void* data,
                                          char** error);
  static bool CreateIsolateAndSetup(const char* script_uri,
                                    const char* main,
                                    void* data, char** error);
  static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                       Dart_Handle library,
                                       Dart_Handle urlHandle);
  static Dart_Handle LoadSourceFromFile(const char* url);
  static void ShutdownIsolate(void* callback_data);

  Graphics* graphics_;
  Dart_Isolate isolate_;
  bool initialized_vm_;
  bool initialized_script_;
};

#endif  // EMBEDDERS_ANDROID_VM_GLUE_H_
