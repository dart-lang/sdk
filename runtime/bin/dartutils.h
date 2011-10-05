// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DARTUTILS_H_
#define BIN_DARTUTILS_H_

#include "bin/builtin.h"
#include "bin/globals.h"

#include "include/dart_api.h"

class DartUtils {
 public:
  static int64_t GetIntegerValue(Dart_Handle value_obj);
  static const char* GetStringValue(Dart_Handle str_obj);
  static bool GetBooleanValue(Dart_Handle bool_obj);
  static void SetIntegerInstanceField(Dart_Handle handle,
                                      const char* name,
                                      intptr_t val);
  static intptr_t GetIntegerInstanceField(Dart_Handle handle,
                                          const char* name);
  static void SetStringInstanceField(Dart_Handle handle,
                                     const char* name,
                                     const char* val);

  static const char* kBuiltinLibURL;
  static const char* kBuiltinLibSpec;

  static const char* kIdFieldName;
 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(DartUtils);
};

#endif  // BIN_DARTUTILS_H_
