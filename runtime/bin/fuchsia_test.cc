// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>

#include <dart_api.h>

#include "bin/log.h"

namespace dart {
namespace bin {

int Main() {
  Log::Print("Calling Dart_SetVMFlags\n");
  if (!Dart_SetVMFlags(0, NULL)) {
    Log::PrintErr("Failed to set flags\n");
    return -1;
  }
  Log::Print("Calling Dart_Initialize\n");
  char* error = Dart_Initialize(
      NULL, NULL, NULL,
      NULL, NULL, NULL, NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL);
  if (error != NULL) {
    Log::PrintErr("VM initialization failed: %s\n", error);
    free(error);
    return -1;
  }

  Log::Print("Calling Dart_Cleanup\n");
  error = Dart_Cleanup();
  if (error != NULL) {
    Log::PrintErr("VM Cleanup failed: %s\n", error);
    free(error);
    return -1;
  }

  Log::Print("Success!\n");
  return 0;
}

}  // namespace bin
}  // namespace dart

int main(void) {
  return dart::bin::Main();
}
