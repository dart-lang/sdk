// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_BUILTIN_H_
#define BIN_BUILTIN_H_

#include <stdio.h>
#include <stdlib.h>

#include "bin/globals.h"
#include "include/dart_api.h"

#ifdef DEBUG
#define ASSERT(expr) assert(expr)
#else
#define ASSERT(expr) USE(expr)
#endif

#define FATAL(error)                                                           \
  fprintf(stderr, "%s\n", error);                                              \
  fflush(stderr);                                                              \
  abort();

#define UNREACHABLE()                                                          \
  FATAL("unreachable code")

#define UNIMPLEMENTED()                                                        \
  FATAL("unimplemented code")

#define FUNCTION_NAME(name) Builtin_##name
#define REGISTER_FUNCTION(name, count)                                         \
  { ""#name, FUNCTION_NAME(name), count },
#define DECLARE_FUNCTION(name, count)                                          \
  extern void FUNCTION_NAME(name)(Dart_NativeArguments args);

extern Dart_Handle Builtin_Source();
extern void Builtin_SetupLibrary(Dart_Handle builtin_lib);
extern void Builtin_ImportLibrary(Dart_Handle library);
extern void Builtin_SetNativeResolver();
extern void PrintString(FILE* out, Dart_Handle object);

#endif  // BIN_BUILTIN_H_
