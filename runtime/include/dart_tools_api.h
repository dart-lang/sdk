// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_INCLUDE_DART_TOOLS_API_H_
#define RUNTIME_INCLUDE_DART_TOOLS_API_H_

#include "dart_api.h"

/** \mainpage Dart Tools Embedding API Reference
 *
 * This reference describes the Dart embedding API for tools. Tools include
 * a debugger, service protocol, and timeline.
 *
 * NOTE: The APIs described in this file are unstable and subject to change.
 *
 * This reference is generated from the header include/dart_tools_api.h.
 */

/*
  * ========
  * Debugger
  * ========
  */
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
DART_EXPORT Dart_Handle Dart_ScriptGetSource(intptr_t library_id,
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
DART_EXPORT Dart_Handle Dart_ScriptGetTokenInfo(intptr_t library_id,
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
DART_EXPORT Dart_Handle Dart_SetBreakpoint(Dart_Handle script_url,
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
DART_EXPORT Dart_Handle Dart_SetBreakpointAtEntry(Dart_Handle library,
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
DART_EXPORT Dart_Handle Dart_OneTimeBreakAtEntry(Dart_Handle library,
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
 * Installs a handler callback function that gets called by the VM
 * when a breakpoint location has been reached or when stepping.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_SetPausedEventHandler(Dart_PausedEventHandler handler);

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
  kInvalidExceptionPauseInfo
} Dart_ExceptionPauseInfo;

/**
 * Define on which exceptions the debugger pauses.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_Handle
Dart_SetExceptionPauseInfo(Dart_ExceptionPauseInfo pause_info);

/**
 * Returns on which exceptions the debugger pauses.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_ExceptionPauseInfo Dart_GetExceptionPauseInfo();

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
DART_EXPORT Dart_Handle
Dart_ActivationFrameGetLocation(Dart_ActivationFrame activation_frame,
                                Dart_Handle* function_name,
                                Dart_Handle* function,
                                Dart_CodeLocation* location);

/**
 * Returns frame pointer of the given activation frame.
 *
 * \frame_pointer receives the frame pointer for the frame.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle
Dart_ActivationFrameGetFramePointer(Dart_ActivationFrame activation_frame,
                                    uintptr_t* frame_pointer);

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
DART_EXPORT Dart_Handle
Dart_GetLocalVariables(Dart_ActivationFrame activation_frame);

/**
 * Returns origin class of a function.
 *
 * Requires there to be a current isolate.
 *
 * \return Returns the class id (a handle to an integer) of the class in
 * which \function is defined. Returns a null handle if \function is defined
 * at the top level. Returns an error object otherwise.
 */
DART_EXPORT Dart_Handle Dart_GetFunctionOrigin(Dart_Handle function);

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
 * of stack frame \activation_frame.
 */
DART_EXPORT Dart_Handle
Dart_ActivationFrameEvaluate(Dart_ActivationFrame activation_frame,
                             Dart_Handle expr_in);

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

/** Returns info about the given closure \closure.
 *
 * \param name receives handle to closure name (string).
 *        Receives a null handle if the closure is anonymous.
 * \param signature receives handle to closure signature (string).
 * \param location.script_url receives a string handle with the url of
 *        the source script that contains the closure.
 *        Receives a null handle if there is no textual location
 *        that corresponds to the fucntion.
 * \param location.library_id receives the id of the library in which the
 *        function in this frame is defined.
 * \param location.token_pos receives the token position in the script.
 *
 * \return A handle to the value true if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_GetClosureInfo(Dart_Handle closure,
                                            Dart_Handle* name,
                                            Dart_Handle* signature,
                                            Dart_CodeLocation* location);

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
 * Returns the isolate id for an isolate.
 *
 * \return The Dart_IsolateId value corresponding to the isolate.
 */
DART_EXPORT Dart_IsolateId Dart_GetIsolateId(Dart_Isolate isolate);

/*
 * =======
 * Service
 * =======
 */

/**
 * A service request callback function.
 *
 * These callbacks, registered by the embedder, are called when the VM receives
 * a service request it can't handle and the service request command name
 * matches one of the embedder registered handlers.
 *
 * The return value of the callback indicates whether the response
 * should be used as a regular result or an error result.
 * Specifically, if the callback returns true, a regular JSON-RPC
 * response is built in the following way:
 *
 * {
 *   "jsonrpc": "2.0",
 *   "result": <json_object>,
 *   "id": <some sequence id>,
 * }
 *
 * If the callback returns false, a JSON-RPC error is built like this:
 *
 * {
 *   "jsonrpc": "2.0",
 *   "error": <json_object>,
 *   "id": <some sequence id>,
 * }
 *
 * \param method The rpc method name.
 * \param param_keys Service requests can have key-value pair parameters. The
 *   keys and values are flattened and stored in arrays.
 * \param param_values The values associated with the keys.
 * \param num_params The length of the param_keys and param_values arrays.
 * \param user_data The user_data pointer registered with this handler.
 * \param result A C string containing a valid JSON object. The returned
 *   pointer will be freed by the VM by calling free.
 *
 * \return True if the result is a regular JSON-RPC response, false if the
 *   result is a JSON-RPC error.
 */
typedef bool (*Dart_ServiceRequestCallback)(const char* method,
                                            const char** param_keys,
                                            const char** param_values,
                                            intptr_t num_params,
                                            void* user_data,
                                            const char** json_object);

/**
 * Register a Dart_ServiceRequestCallback to be called to handle
 * requests for the named rpc on a specific isolate. The callback will
 * be invoked with the current isolate set to the request target.
 *
 * \param method The name of the method that this callback is responsible for.
 * \param callback The callback to invoke.
 * \param user_data The user data passed to the callback.
 *
 * NOTE: If multiple callbacks with the same name are registered, only
 * the last callback registered will be remembered.
 */
DART_EXPORT void Dart_RegisterIsolateServiceRequestCallback(
    const char* method,
    Dart_ServiceRequestCallback callback,
    void* user_data);

/**
 * Register a Dart_ServiceRequestCallback to be called to handle
 * requests for the named rpc. The callback will be invoked without a
 * current isolate.
 *
 * \param method The name of the command that this callback is responsible for.
 * \param callback The callback to invoke.
 * \param user_data The user data passed to the callback.
 *
 * NOTE: If multiple callbacks with the same name are registered, only
 * the last callback registered will be remembered.
 */
DART_EXPORT void Dart_RegisterRootServiceRequestCallback(
    const char* method,
    Dart_ServiceRequestCallback callback,
    void* user_data);

/*
 * ========
 * Event Streams
 * ========
 */

/**
 * A callback invoked when the VM service gets a request to listen to
 * some stream.
 *
 * \return Returns true iff the embedder supports the named stream id.
 */
typedef bool (*Dart_ServiceStreamListenCallback)(const char* stream_id);

/**
 * A callback invoked when the VM service gets a request to cancel
 * some stream.
 */
typedef void (*Dart_ServiceStreamCancelCallback)(const char* stream_id);

/**
 * Adds VM service stream callbacks.
 *
 * \param listen_callback A function pointer to a listen callback function.
 *   A listen callback function should not be already set when this function
 *   is called. A NULL value removes the existing listen callback function
 *   if any.
 *
 * \param cancel_callback A function pointer to a cancel callback function.
 *   A cancel callback function should not be already set when this function
 *   is called. A NULL value removes the existing cancel callback function
 *   if any.
 *
 * \return Success if the callbacks were added.  Otherwise, returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_SetServiceStreamCallbacks(
    Dart_ServiceStreamListenCallback listen_callback,
    Dart_ServiceStreamCancelCallback cancel_callback);

/**
 * Sends a data event to clients of the VM Service.
 *
 * A data event is used to pass an array of bytes to subscribed VM
 * Service clients.  For example, in the standalone embedder, this is
 * function used to provide WriteEvents on the Stdout and Stderr
 * streams.
 *
 * If the embedder passes in a stream id for which no client is
 * subscribed, then the event is ignored.
 *
 * \param stream_id The id of the stream on which to post the event.
 *
 * \param event_kind A string identifying what kind of event this is.
 *   For example, 'WriteEvent'.
 *
 * \param bytes A pointer to an array of bytes.
 *
 * \param bytes_length The length of the byte array.
 *
 * \return Success if the arguments are well formed.  Otherwise, returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_ServiceSendDataEvent(const char* stream_id,
                                                  const char* event_kind,
                                                  const uint8_t* bytes,
                                                  intptr_t bytes_length);

/*
 * ========
 * Reload support
 * ========
 *
 * These functions are used to implement reloading in the Dart VM.
 * This is an experimental feature, so embedders should be prepared
 * for these functions to change.
 */

/**
 * A callback which determines whether the file at some url has been
 * modified since some time.  If the file cannot be found, true should
 * be returned.
 */
typedef bool (*Dart_FileModifiedCallback)(const char* url, int64_t since);

DART_EXPORT Dart_Handle
Dart_SetFileModifiedCallback(Dart_FileModifiedCallback file_modified_callback);

/**
 * Returns true if isolate is currently reloading.
 */
DART_EXPORT bool Dart_IsReloading();

/*
 * ========
 * Timeline
 * ========
 */

/**
 * Returns a timestamp in microseconds. This timestamp is suitable for
 * passing into the timeline system.
 *
 * \return A timestamp that can be passed to the timeline system.
 */
DART_EXPORT int64_t Dart_TimelineGetMicros();

/** Timeline stream for Dart API calls */
#define DART_TIMELINE_STREAM_API (1 << 0)
/** Timeline stream for compiler events */
#define DART_TIMELINE_STREAM_COMPILER (1 << 1)
/** Timeline stream for Dart provided events */
#define DART_TIMELINE_STREAM_DART (1 << 2)
/** Timeline stream for debugger provided events */
#define DART_TIMELINE_STREAM_DEBUGGER (1 << 3)
/** Timeline stream for embedder provided events */
#define DART_TIMELINE_STREAM_EMBEDDER (1 << 4)
/** Timeline stream for GC events */
#define DART_TIMELINE_STREAM_GC (1 << 5)
/** Timeline stream for isolate events */
#define DART_TIMELINE_STREAM_ISOLATE (1 << 6)
/** Timeline stream for VM events */
#define DART_TIMELINE_STREAM_VM (1 << 7)

/** All timeline streams */
#define DART_TIMELINE_STREAM_ALL                                               \
  (DART_TIMELINE_STREAM_API | DART_TIMELINE_STREAM_COMPILER |                  \
   DART_TIMELINE_STREAM_DART | DART_TIMELINE_STREAM_DEBUGGER |                 \
   DART_TIMELINE_STREAM_EMBEDDER | DART_TIMELINE_STREAM_GC |                   \
   DART_TIMELINE_STREAM_ISOLATE | DART_TIMELINE_STREAM_VM)

/** Disable all timeline stream recording */
#define DART_TIMELINE_STREAM_DISABLE 0

/**
 * Start recording timeline events for the entire VM (including all isolates).
 *
 * \param stream_mask A bitmask of streams that should be recorded.
 *
 * NOTE: Calling with 0 disables recording of all streams.
 */
DART_EXPORT void Dart_GlobalTimelineSetRecordedStreams(int64_t stream_mask);

typedef enum {
  /** Indicates a new stream is being output */
  Dart_StreamConsumer_kStart = 0,
  /** Data for the current stream */
  Dart_StreamConsumer_kData = 1,
  /** Indicates stream is finished */
  Dart_StreamConsumer_kFinish = 2,
} Dart_StreamConsumer_State;

/**
 * A stream consumer callback function.
 *
 * This function will be called repeatedly until there is no more data in a
 * stream and there are no more streams.
 *
 * \param state Indicates a new stream, data, or a finished stream.
 * \param stream_name A name for this stream. Not guaranteed to be meaningful.
 * \param buffer A pointer to the stream data.
 * \param buffer_length The number of bytes at buffer that should be consumed.
 * \param stream_callback_data The pointer passed in when requesting the stream.
 *
 * At the start of each stream state will be DART_STREAM_CONSUMER_STATE_START
 * and buffer will be NULL.
 *
 * For each chunk of data the state will be DART_STREAM_CONSUMER_STATE_DATA
 * and buffer will not be NULL.
 *
 * At the end of each stream state will be DART_STREAM_CONSUMER_STATE_FINISH
 * and buffer will be NULL.
 */
typedef void (*Dart_StreamConsumer)(Dart_StreamConsumer_State state,
                                    const char* stream_name,
                                    const uint8_t* buffer,
                                    intptr_t buffer_length,
                                    void* stream_callback_data);

/**
 * Get the timeline for entire VM (including all isolates).
 *
 * NOTE: The timeline retrieved from this API call may not include the most
 * recent events.
 *
 * \param consumer A Dart_StreamConsumer.
 * \param user_data User data passed into consumer.
 *
 * NOTE: The trace-event format is documented here: https://goo.gl/hDZw5M
 *
 * \return True if a stream was output.
 */
DART_EXPORT bool Dart_GlobalTimelineGetTrace(Dart_StreamConsumer consumer,
                                             void* user_data);

typedef enum {
  Dart_Timeline_Event_Begin,          // Phase = 'B'.
  Dart_Timeline_Event_End,            // Phase = 'E'.
  Dart_Timeline_Event_Instant,        // Phase = 'i'.
  Dart_Timeline_Event_Duration,       // Phase = 'X'.
  Dart_Timeline_Event_Async_Begin,    // Phase = 'b'.
  Dart_Timeline_Event_Async_End,      // Phase = 'e'.
  Dart_Timeline_Event_Async_Instant,  // Phase = 'n'.
  Dart_Timeline_Event_Counter,        // Phase = 'C'.
  Dart_Timeline_Event_Flow_Begin,     // Phase = 's'.
  Dart_Timeline_Event_Flow_Step,      // Phase = 't'.
  Dart_Timeline_Event_Flow_End,       // Phase = 'f'.
} Dart_Timeline_Event_Type;

/**
 * Add a timeline event to the embedder stream.
 *
 * \param label The name of the evnet.
 * \param timestamp0 The first timestamp of the event.
 * \param timestamp1_or_async_id The second timestamp of the event or
 *     the async id.
 * \param argument_count The number of argument names and values.
 * \param argument_names An array of names of the arguments.
 * \param argument_values An array of values of the arguments.
 */
DART_EXPORT void Dart_TimelineEvent(const char* label,
                                    int64_t timestamp0,
                                    int64_t timestamp1_or_async_id,
                                    Dart_Timeline_Event_Type type,
                                    intptr_t argument_count,
                                    const char** argument_names,
                                    const char** argument_values);

/**
 * Associates a name with the current thread. This name will be used to name
 * threads in the timeline. Can only be called after a call to Dart_Initialize.
 *
 * \param name The name of the thread.
 */
DART_EXPORT void Dart_SetThreadName(const char* name);

/**
 * Called by the VM to let the embedder know when to start recording into the
 * timeline. Can be called from any thread.
 */
typedef void (*Dart_EmbedderTimelineStartRecording)();

/**
 * Called by the VM to let the embedder know when to stop recording into the
 * timeline. Can be called from any thread.
 */
typedef void (*Dart_EmbedderTimelineStopRecording)();

/**
 * Sets the embedder timeline callbacks. These callbacks are used by the VM
 * to notify the embedder of timeline recording state changes.
 *
 * \param start_recording See Dart_EmbedderTimelineStartRecording.
 * \param stop_recording See Dart_EmbedderTimelineStopRecording.
 *
 * NOTE: To avoid races, this should be called before Dart_Initialize.
 */
DART_EXPORT void Dart_SetEmbedderTimelineCallbacks(
    Dart_EmbedderTimelineStartRecording start_recording,
    Dart_EmbedderTimelineStopRecording stop_recording);

#endif  // RUNTIME_INCLUDE_DART_TOOLS_API_H_
