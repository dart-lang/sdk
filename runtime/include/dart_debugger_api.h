// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef INCLUDE_DART_DEBUGGER_API_H_
#define INCLUDE_DART_DEBUGGER_API_H_

#include "include/dart_api.h"

typedef struct _Dart_Breakpoint* Dart_Breakpoint;

typedef struct _Dart_StackTrace* Dart_StackTrace;

typedef struct _Dart_ActivationFrame* Dart_ActivationFrame;

typedef void Dart_BreakpointHandler(
                 Dart_Breakpoint breakpoint,
                 Dart_StackTrace stack_trace);

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

/**
 * Installs a handler callback function that gets called by the VM
 * when a breakpoint has been reached.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_SetBreakpointHandler(
                            Dart_BreakpointHandler bp_handler);


/**
 * Returns in \length the number of activation frames in the given
 * stack trace.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_StackTraceLength(
                            Dart_StackTrace trace,
                            intptr_t* length);


/**
 * Returns in \frame the activation frame with index \frame_index.
 * The activation frame at the top of stack has index 0.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_GetActivationFrame(
                            Dart_StackTrace trace,
                            int frame_index,
                            Dart_ActivationFrame* frame);


/**
 * Returns information about the given activation frame.
 * \function_name receives a string handle with the qualified
 *    function name.
 * \script_url receives a string handle with the url of the
 *    source script that contains the frame's function.
 * \line_number receives the line number in the script.
 *
 * Any or all of the out parameters above may be NULL.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_ActivationFrameInfo(
                            Dart_ActivationFrame activation_frame,
                            Dart_Handle* function_name,
                            Dart_Handle* script_url,
                            intptr_t* line_number);


#endif  // INCLUDE_DART_DEBUGGER_API_H_
