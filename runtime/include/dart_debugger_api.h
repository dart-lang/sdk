// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef INCLUDE_DART_DEBUGGER_API_H_
#define INCLUDE_DART_DEBUGGER_API_H_

#include "include/dart_api.h"

typedef struct _Dart_Breakpoint* Dart_Breakpoint;


/**
 * Sets a breakpoint at the entry of the given function. If class_name
 * is the empty string, looks for a library function with the given
 * name.
 *
 * Requires there to be a current isolate.
 *
 * \breakpoint If non-null, will point to the breakpoint object
 *   if a breakpoint was successfully created.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_SetBreakpointAtEntry(
                            Dart_Handle library,
                            Dart_Handle class_name,
                            Dart_Handle function_name,
                            Dart_Breakpoint* breakpoint);

#endif  // INCLUDE_DART_DEBUGGER_API_H_
