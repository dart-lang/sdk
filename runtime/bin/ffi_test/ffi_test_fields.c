// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#include "ffi_test_fields.h"

DART_EXPORT_FIELD int32_t globalInt;
DART_EXPORT_FIELD struct Coord globalStruct;
DART_EXPORT_FIELD const char* globalString = "Hello Dart!";
DART_EXPORT_FIELD int globalArray[] = {1, 2, 3};
DART_EXPORT_FIELD double identity3x3[3][3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
