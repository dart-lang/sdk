// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef INCLUDE_DART_DEBUGGER_API_H_
#define INCLUDE_DART_DEBUGGER_API_H_

#include "include/dart_api.h"

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

// DEPRECATED -- use Dart_PausedEventHandler
typedef void Dart_BreakpointHandler(Dart_IsolateId isolate_id,
                                    Dart_Breakpoint breakpoint,
                                    Dart_StackTrace stack_trace);

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
                                     const Dart_CodeLocation& location);

typedef void Dart_BreakpointResolvedHandler(Dart_IsolateId isolate_id,
                                            intptr_t bp_id,
                                            const Dart_CodeLocation& location);


/**
 * Caches a given \object and returns an object id. The object id is only
 * valid while the VM is paused. The cache is invalidated when the VM
 * resumes.
 *
 * Requires there to be a current isolate.
 *
 * Returns an id >= 0 on success, or -1 if there is an error.
 */
DART_EXPORT intptr_t Dart_CacheObject(Dart_Handle object_in);


/**
 * Returns a cached object given the \obj_id.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_Handle Dart_GetCachedObject(intptr_t obj_id);


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
 * Returns a list of urls (strings) of all the scripts loaded in the
 * given library.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to a list of string handles.
 */
DART_EXPORT Dart_Handle Dart_GetScriptURLs(Dart_Handle library_url);


/**
 * Returns a string containing the source code of the given script
 * in the given library.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to string containing the source text if no error
 * occurs.
 */
DART_EXPORT Dart_Handle Dart_ScriptGetSource(
                            intptr_t library_id,
                            Dart_Handle script_url_in);


/**
 * Returns an array containing line number and token offset info
 * for the given script.
 *
 * Returns an array of numbers. Null values indicate the beginning of
 * a new line. The first number after null is the line number.
 * The line number is followed by pairs of numbers, with the first value
 * being the "token offset" and the second value being the column number
 * of the token.
 * The "token offset" is a value that is used to indicate a location
 * in code, similarly to a "PC" address.
 * Source lines with no tokens are omitted.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to an array or an error object.
 */
DART_EXPORT Dart_Handle Dart_ScriptGetTokenInfo(
                            intptr_t library_id,
                            Dart_Handle script_url_in);


/**
 * Returns a string containing a generated source code of the given script
 * in the given library. This is essentially used to pretty print dart code
 * generated from any tool (e.g: dart2dart).
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to string containing the source text if no error
 * occurs.
 */
DART_EXPORT Dart_Handle Dart_GenerateScriptSource(Dart_Handle library_url_in,
                                                  Dart_Handle script_url_in);


/**
 * Sets a breakpoint at line \line_number in \script_url, or the closest
 * following line (within the same function) where a breakpoint can be set.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle containing the breakpoint id, which is an integer
 * value, or an error object if a breakpoint could not be set.
 */
DART_EXPORT Dart_Handle Dart_SetBreakpoint(
                            Dart_Handle script_url,
                            intptr_t line_number);

/**
 * Deletes the breakpoint with the given id \pb_id.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_RemoveBreakpoint(intptr_t bp_id);


/**
 * Get the script URL of the breakpoint with the given id \pb_id.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the URL (string) of the script, or an error
 * object.
 */
DART_EXPORT Dart_Handle Dart_GetBreakpointURL(intptr_t bp_id);


/**
 * Get the line number of the breakpoint with the given id \pb_id.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the line number (integer) of the script,
 * or an error object.
 */
DART_EXPORT Dart_Handle Dart_GetBreakpointLine(intptr_t bp_id);


/**
 * Sets a one-time breakpoint at the entry of the given function.
 * If class_name is the empty string, looks for a library function
 * with the given name.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle containing the breakpoint id, which is an integer
 * value, or an error object if a breakpoint could not be set.
 */
DART_EXPORT Dart_Handle Dart_SetBreakpointAtEntry(
                            Dart_Handle library,
                            Dart_Handle class_name,
                            Dart_Handle function_name);


/**
 * Sets a breakpoint at the entry of the given function. If class_name
 * is the empty string, looks for a library function with the given
 * name.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_OneTimeBreakAtEntry(
                            Dart_Handle library,
                            Dart_Handle class_name,
                            Dart_Handle function_name);


/**
 * Can be called from the breakpoint handler. Sets the debugger to
 * single step mode.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_Handle Dart_SetStepOver();


/**
 * Can be called from the breakpoint handler. Causes the debugger to
 * break after at the beginning of the next function call.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_Handle Dart_SetStepInto();


/**
 * Can be called from the breakpoint handler. Causes the debugger to
 * break after returning from the current Dart function.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_Handle Dart_SetStepOut();


/**
 * DEPRECATED -- use Dart_SetPausedEventHandler
 *
 * Installs a handler callback function that gets called by the VM
 * when a breakpoint has been reached.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_SetBreakpointHandler(
                            Dart_BreakpointHandler bp_handler);


/**
 * Installs a handler callback function that gets called by the VM
 * when a breakpoint location has been reached or when stepping.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_SetPausedEventHandler(
                            Dart_PausedEventHandler handler);


/**
 * Installs a callback function that gets called by the VM when
 * a breakpoint has been resolved to an actual url and line number.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_SetBreakpointResolvedHandler(
                            Dart_BreakpointResolvedHandler handler);

/**
 * Installs a callback function that gets called by the VM when
 * an exception has been thrown.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_SetExceptionThrownHandler(
                            Dart_ExceptionThrownHandler handler);

/**
 * Installs a callback function that gets called by the VM when
 * an isolate event happens, e.g:
 *   - creation of a new isolate
 *   - shutdown of an isolate
 *   - interruption of an isolate
 */
DART_EXPORT void Dart_SetIsolateEventHandler(Dart_IsolateEventHandler handler);

// On which exceptions to pause.
typedef enum {
  kNoPauseOnExceptions = 1,
  kPauseOnUnhandledExceptions,
  kPauseOnAllExceptions,
} Dart_ExceptionPauseInfo;

/**
 * Define on which exceptions the debugger pauses.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_Handle Dart_SetExceptionPauseInfo(
                            Dart_ExceptionPauseInfo pause_info);


/**
 * Returns on which exceptions the debugger pauses.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_ExceptionPauseInfo Dart_GetExceptionPauseInfo();

/**
 * Returns in \trace the the current stack trace, or NULL if the
 * VM is not paused.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_GetStackTrace(Dart_StackTrace* trace);


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
 * DEPRECATED -- Use Dart_ActivationFrameGetLocation instead.
 *
 * Returns information about the given activation frame.
 * \function_name receives a string handle with the qualified
 *    function name.
 * \script_url receives a string handle with the url of the
 *    source script that contains the frame's function.
 * \line_number receives the line number in the script.
 * \library_id receives the id of the library in which the
 *    function in this frame is defined.
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
                            intptr_t* line_number,
                            intptr_t* library_id);


/**
 * Returns code location of the given activation frame.
 *
 * \function_name receives a string handle with the qualified
 *    function name.
 * \function receives a handle to the function.
 * \location.script_url receives a string handle with the url of
 *    the source script that contains the frame's function.
 *    Receives a null handle if there is no textual location
 *    that corresponds to the frame, e.g. for implicitly
 *    generated constructors.
 * \location.library_id receives the id of the library in which the
 *    function in this frame is defined.
 * \location.token_pos receives the token position in the script.
 *
 * Any of the out parameters above may be NULL.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 *         A handle to the False object if there is no text
 *         position for the frame.
 */
DART_EXPORT Dart_Handle Dart_ActivationFrameGetLocation(
                            Dart_ActivationFrame activation_frame,
                            Dart_Handle* function_name,
                            Dart_Handle* function,
                            Dart_CodeLocation* location);


/**
 * Returns an array containing all the local variable names and values of
 * the given \activation_frame.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to an array containing variable names and
 * corresponding values. The array is empty if the activation frame has
 * no variables. If non-empty, variable names are at array offsets 2*n,
 * values at offset 2*n+1.
 */
DART_EXPORT Dart_Handle Dart_GetLocalVariables(
                            Dart_ActivationFrame activation_frame);


/**
 * Returns an array containing all the global variable names and values of
 * the library with given \library_id.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to an array containing variable names and
 * corresponding values. Variable names are at array offsets 2*n,
 * values at offset 2*n+1.
 */
DART_EXPORT Dart_Handle Dart_GetGlobalVariables(intptr_t library_id);


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
 * TODO(hausner): add 'library' execution context.
 * 
 * \return A handle to the computed value, or an error object if
 * the compilation of the expression fails, or if the evaluation throws
 * an error.
 */
DART_EXPORT Dart_Handle Dart_EvaluateExpr(Dart_Handle target,
                                          Dart_Handle expr);


/**
 * Returns the class of the given \object.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the class object.
 */
DART_EXPORT Dart_Handle Dart_GetObjClass(Dart_Handle object);


/**
 * Returns in \class_id the class id of the given \object. The id is valid
 * for the lifetime of the isolate.
 *
 * Requires there to be a current isolate.
 *
 * \return True if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_GetObjClassId(Dart_Handle object,
                                           intptr_t* class_id);


/**
 * Returns the supertype of the given instantiated type \cls.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the type object.
 */
DART_EXPORT Dart_Handle Dart_GetSupertype(Dart_Handle type);


/**
 * Returns handle to class with class id \class_id.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the class if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_GetClassFromId(intptr_t class_id);


/**
 * Returns info about the given class \cls_id.
 *
 * \param class_name receives handle to class name (string) if non-null.
 * \param library receives handle to library in which the class
 *        is defined, if non-null.
 * \param super_class_id receives the class id to the super class of
 *        \cls_id if non-null.
 * \param static_fields If non-null, receives an array containing field
 *        names and values of static fields of the class. Names are
 *        at array offsets 2*n, values at offset 2*n+1.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the value true if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_GetClassInfo(intptr_t class_id,
                                          Dart_Handle* class_name,
                                          intptr_t* library_id,
                                          intptr_t* super_class_id,
                                          Dart_Handle* static_fields);


/**
 * Returns an array containing all instance field names and values of
 * the given \object.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to an array containing field names and
 * corresponding field values. The array is empty if the object has
 * no fields. If non-empty, field names are at array offsets 2*n,
 * values at offset 2*n+1. Field values may also be a handle to an
 * error object if an error was encountered evaluating the field.
 */
DART_EXPORT Dart_Handle Dart_GetInstanceFields(Dart_Handle object);


/**
 * Returns an array containing all static field names and values of
 * the given type \target.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to an array containing field names and
 * corresponding field values. The array is empty if the class has
 * no static fields. If non-empty, field names are at array offsets 2*n,
 * values at offset 2*n+1. Field values may also be a handle to an
 * error object if an error was encountered evaluating the field.
 */
DART_EXPORT Dart_Handle Dart_GetStaticFields(Dart_Handle target);


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


/**
 * Returns an array containing all variable names and values of
 * the given library \library_id.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to an array containing variable names and
 * corresponding values. The array is empty if the library has
 * no variables. If non-empty, variable names are at array offsets 2*n,
 * values at offset 2*n+1. Variable values may also be a handle to an
 * error object if an error was encountered evaluating the value.
 */
DART_EXPORT Dart_Handle Dart_GetLibraryFields(intptr_t library_id);


/**
 * Returns an array containing all imported libraries of
 * the given library \library_id.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to an array containing prefix names and
 * library ids. The array is empty if the library has
 * no imports. If non-empty, import prefixes are at array offsets 2*n,
 * corresponding library ids at offset 2*n+1. Prefixes may be null
 * which indicates the respective library has been imported without
 * a prefix.
 */
DART_EXPORT Dart_Handle Dart_GetLibraryImports(intptr_t library_id);


/**
* Returns the url of the library \library_id.
*
* Requires there to be a current isolate.
*
* \return A string handle containing the URL of the library.
*/
DART_EXPORT Dart_Handle Dart_GetLibraryURL(intptr_t library_id);


/**
* Returns the isolate object corresponding to the isolate id.
*
* \return The Dart_Isolate object corresponding to the isolate id.
* If the specified id is invalid NULL is returned.
*/
DART_EXPORT Dart_Isolate Dart_GetIsolate(Dart_IsolateId isolate_id);


/**
 * Returns VM status information. VM status is implemented using a
 * different status plug-in for each type of status; for example, there
 * might be an "isolate" plug-in that returns information about the
 * current isolates.
 *
 * To get a list of status types, this function is called with a
 * status_type parameter of "statustypes". This list is useful when
 * building a status dashboard.
 *
 * TODO(tball): we need to figure out which isolate this command needs
 * to be sent to after parsing the string and then send an OOB message
 * to that isolate.
 *
 * \param request A REST-like string, which uses '/' to separate
 *     parameters. The first parameter is always the status type.
 *
 * \return The requested status as a JSON formatted string, with the
 *     contents defined by the status plug-in. The caller is responsible
 *     for freeing this string.
 */
DART_EXPORT char* Dart_GetVmStatus(const char* request);

#endif  // INCLUDE_DART_DEBUGGER_API_H_
