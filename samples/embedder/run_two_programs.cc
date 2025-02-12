// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <iostream>
#include "helpers.h"
#include "include/dart_api.h"
#include "include/dart_engine.h"

int main(int argc, char** argv) {
  if (argc < 3) {
    std::cerr << "Must specify two snapshot paths" << std::endl;
    std::exit(1);
  }
  char* error = nullptr;

  DartEngine_SnapshotData snapshot1 = AutoSnapshotFromFile(argv[1], &error);
  CheckError(error, "reading snapshot");

  DartEngine_SnapshotData snapshot2 = AutoSnapshotFromFile(argv[2], &error);
  CheckError(error, "reading snapshot");

  Dart_Isolate isolate1 = DartEngine_CreateIsolate(snapshot1, &error);
  CheckError(error, "starting 1st isolate");

  Dart_Isolate isolate2 = DartEngine_CreateIsolate(snapshot2, &error);
  CheckError(error, "starting 2nd isolate");

  DartEngine_AcquireIsolate(isolate1);
  Dart_EnterScope();

  Dart_Handle invoke_result = Dart_Invoke(
      Dart_RootLibrary(), Dart_NewStringFromCString("getValue"), 0, nullptr);
  std::string return_value = StringFromHandle(invoke_result);

  std::cout << "program1 returned: " << return_value << std::endl;
  Dart_ExitScope();
  DartEngine_ReleaseIsolate();

  DartEngine_AcquireIsolate(isolate2);
  Dart_EnterScope();

  std::initializer_list<Dart_Handle> args{
      Dart_NewStringFromCString(return_value.c_str())};
  Dart_Handle invoke_result2 =
      Dart_Invoke(Dart_RootLibrary(), Dart_NewStringFromCString("printValue"),
                  1, const_cast<Dart_Handle*>(args.begin()));
  CheckError(invoke_result2);

  Dart_ExitScope();
  DartEngine_ReleaseIsolate();

  DartEngine_Shutdown();
}
