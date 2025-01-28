// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <iostream>
#include "helpers.h"
#include "include/dart_api.h"
#include "include/dart_engine.h"

Dart_Handle ToDartStringList(const std::vector<std::string>& values) {
  Dart_Handle core_library =
      CheckError(Dart_LookupLibrary(Dart_NewStringFromCString("dart:core")));
  Dart_Handle string_type = CheckError(Dart_GetNonNullableType(
      core_library, Dart_NewStringFromCString("String"), 0, nullptr));
  Dart_Handle filler = Dart_NewStringFromCString("");

  Dart_Handle result =
      CheckError(Dart_NewListOfTypeFilled(string_type, filler, values.size()));
  for (size_t i = 0; i < values.size(); i++) {
    Dart_Handle element = Dart_NewStringFromCString(values[i].c_str());
    CheckError(Dart_ListSetAt(result, i, element));
  }

  return result;
}

int main(int argc, char** argv) {
  if (argc == 1) {
    std::cerr << "Must specify snapshot path" << std::endl;
    std::exit(1);
  }
  char* error = nullptr;

  DartEngine_SnapshotData snapshot_data = AutoSnapshotFromFile(argv[1], &error);
  CheckError(error, "reading snapshot");

  Dart_Isolate isolate = DartEngine_CreateIsolate(snapshot_data, &error);
  CheckError(error, "starting isolate");

  DartEngine_AcquireIsolate(isolate);
  Dart_EnterScope();

  std::initializer_list<Dart_Handle> main_args{ToDartStringList({"world"})};

  CheckError(Dart_Invoke(Dart_RootLibrary(), Dart_NewStringFromCString("main"),
                         1, const_cast<Dart_Handle*>(main_args.begin())),
             "calling main");

  Dart_ExitScope();
  DartEngine_ReleaseIsolate();

  DartEngine_Shutdown();
}
