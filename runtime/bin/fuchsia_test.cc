// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>

#include <dart_api.h>

int main(void) {
  fprintf(stderr, "Calling Dart_SetVMFlags\n");
  fflush(stderr);
  if (!Dart_SetVMFlags(0, NULL)) {
    fprintf(stderr, "Failed to set flags\n");
    fflush(stderr);
    return -1;
  }
  fprintf(stderr, "Calling Dart_Initialize\n");
  fflush(stderr);
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
    fprintf(stderr, "VM initialization failed: %s\n", error);
    fflush(stderr);
    free(error);
    return -1;
  }
  fprintf(stderr, "Success!\n");
  fflush(stderr);
  return 0;
}
