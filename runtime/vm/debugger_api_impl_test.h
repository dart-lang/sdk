// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DEBUGGER_API_IMPL_TEST_H_
#define RUNTIME_VM_DEBUGGER_API_IMPL_TEST_H_

#include "include/dart_api.h"
#include "vm/debugger.h"

typedef struct _Dart_Breakpoint* Dart_Breakpoint;

typedef struct _Dart_StackTrace* Dart_StackTrace;

typedef struct _Dart_ActivationFrame* Dart_ActivationFrame;

/**
 * An id used to uniquely represent an Isolate in the debugger wire protocol
 * messages.
 */
typedef Dart_Port Dart_IsolateId;

/**
 * ILLEGAL_ISOLATE_ID is a number guaranteed never to be associated with a
 * valid isolate.
 */
#define ILLEGAL_ISOLATE_ID ILLEGAL_PORT

/**
 * Null value for breakpoint id. Guaranteed never to be associated
 * with a valid breakpoint.
 */
#define ILLEGAL_BREAKPOINT_ID 0

typedef void Dart_ExceptionThrownHandler(Dart_IsolateId isolate_id,
                                         Dart_Handle exception_object,
                                         Dart_StackTrace stack_trace);

typedef enum {
  kCreated = 0,
  kInterrupted,
  kShutdown,
} Dart_IsolateEvent;

/**
 * Represents a location in Dart code.
 */
typedef struct {
  Dart_Handle script_url;  // Url (string) of the script.
  int32_t library_id;      // Library in which the script is loaded.
  int32_t token_pos;       // Code address.
} Dart_CodeLocation;

typedef void Dart_IsolateEventHandler(Dart_IsolateId isolate_id,
                                      Dart_IsolateEvent kind);

typedef void Dart_PausedEventHandler(Dart_IsolateId isolate_id,
                                     intptr_t bp_id,
                                     const Dart_CodeLocation& location);

typedef void Dart_BreakpointResolvedHandler(Dart_IsolateId isolate_id,
                                            intptr_t bp_id,
                                            const Dart_CodeLocation& location);

/**
 * Returns a list of ids (integers) of all the libraries loaded in the
 * current isolate.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to a list of library ids.
 */
DART_EXPORT Dart_Handle Dart_GetLibraryIds();

/**
 * Returns true if the debugger can step into code of the given library.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_GetLibraryDebuggable(intptr_t library_id,
                                                  bool* is_debuggable);

/**
 * Requets that debugging be enabled for the given library.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_SetLibraryDebuggable(intptr_t library_id,
                                                  bool is_debuggable);

/**
 * Sets a breakpoint at line \line_number in \script_url, or the closest
 * following line (within the same function) where a breakpoint can be set.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle containing the breakpoint id, which is an integer
 * value, or an error object if a breakpoint could not be set.
 */
DART_EXPORT Dart_Handle Dart_SetBreakpoint(Dart_Handle script_url,
                                           intptr_t line_number);

/**
 * Installs a handler callback function that gets called by the VM
 * when a breakpoint location has been reached or when stepping.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_SetPausedEventHandler(Dart_PausedEventHandler handler);

/**
 * Returns in \trace the current stack trace, or NULL if the
 * VM is not paused.
 *
 * Requires there to be a current isolate.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_GetStackTrace(Dart_StackTrace* trace);

/**
 * Returns in \trace the stack trace associated with the error given in \handle.
 *
 * Requires there to be a current isolate.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_GetStackTraceFromError(Dart_Handle error,
                                                    Dart_StackTrace* trace);

/**
 * Returns in \length the number of activation frames in the given
 * stack trace.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_StackTraceLength(Dart_StackTrace trace,
                                              intptr_t* length);

/**
 * Returns in \frame the activation frame with index \frame_index.
 * The activation frame at the top of stack has index 0.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_GetActivationFrame(Dart_StackTrace trace,
                                                int frame_index,
                                                Dart_ActivationFrame* frame);

/**
 * Returns information about the given activation frame.
 * \function_name receives a string handle with the qualified
 *    function name.
 * \script_url receives a string handle with the url of the
 *    source script that contains the frame's function.
 * \line_number receives the line number in the script.
 * \col_number receives the column number in the script, or -1 if column
 *    information is not available
 *
 * Any or all of the out parameters above may be NULL.
 *
 * Requires there to be a current isolate.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle
Dart_ActivationFrameInfo(Dart_ActivationFrame activation_frame,
                         Dart_Handle* function_name,
                         Dart_Handle* script_url,
                         intptr_t* line_number,
                         intptr_t* column_number);

/**
 * Execute the expression given in string \expr in the context
 * of \target.
 *
 * Requires there to be a current isolate.
 *
 * The expression is evaluated in the context of \target.
 * If \target is a Dart object, the expression is evaluated as if
 * it were an instance method of the class of the object.
 * If \target is a Class, the expression is evaluated as if it
 * were a static method of that class.
 * If \target is a Library, the expression is evaluated as if it
 * were a top-level function in that library.
 *
 * \return A handle to the computed value, or an error object if
 * the compilation of the expression fails, or if the evaluation throws
 * an error.
 */
DART_EXPORT Dart_Handle Dart_EvaluateExpr(Dart_Handle target, Dart_Handle expr);

/**
 * Returns a handle to the library \library_id.
 *
 * Requires there to be a current isolate.
 *
 * \return A library handle if the id is valid.
 */
DART_EXPORT Dart_Handle Dart_GetLibraryFromId(intptr_t library_id);

/**
 * Returns in \library_id the library id of the given \library.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_LibraryId(Dart_Handle library,
                                       intptr_t* library_id);

#endif  // RUNTIME_VM_DEBUGGER_API_IMPL_TEST_H_
