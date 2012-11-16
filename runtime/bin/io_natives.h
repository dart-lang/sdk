// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_IO_NATIVES_H_
#define BIN_IO_NATIVES_H_

#include "include/dart_api.h"

Dart_NativeFunction IONativeLookup(Dart_Handle name,
                                   int argument_count);

#endif  // BIN_IO_NATIVES_H_
