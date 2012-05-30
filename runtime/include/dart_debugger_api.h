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

typedef void Dart_BreakpointResolvedHandler(
                 intptr_t bp_id,
                 Dart_Handle url,
                 intptr_t line_number);


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
 * DEPRECATED -- use Gart_GetLibraryIds instead.
 *
 * Returns a list of urls (strings) of all the libraries loaded in the
 * current isolate.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to a list of string handles.
 */
DART_EXPORT Dart_Handle Dart_GetLibraryURLs();
// TODO(turnidge): The embedding and debugger apis are not consistent
// in how they capitalize url.  One uses 'Url' and the other 'URL'.
// They should be the same.


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
DART_EXPORT Dart_Handle Dart_GetScriptSource(
                            Dart_Handle library_url_in,
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
 * DEPRECATED -- use Dart_SetBreakpoint instead.
 *
 * Sets a breakpoint at line \line_number in \script_url, or the closest
 * following line (within the same function) where a breakpoint can be set.
 *
 * Requires there to be a current isolate.
 *
 * \breakpoint If non-null, will point to the breakpoint object
 *   if a breakpoint was successfully created.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_SetBreakpointAtLine(
                            Dart_Handle script_url,
                            Dart_Handle line_number,
                            Dart_Breakpoint* breakpoint);


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
 * DEPRECATED -- use Dart_RemoveBreakpoint instead.
 *
 * Deletes the given \breakpoint.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_DeleteBreakpoint(
                            Dart_Breakpoint breakpoint);


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
 * when a breakpoint has been reached.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_SetBreakpointHandler(
                            Dart_BreakpointHandler bp_handler);

/**
 * Installs a callback function that gets called by the VM when
 * a breakpoint has been resolved to an actual url and line number.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_SetBreakpointResolvedHandler(
                            Dart_BreakpointResolvedHandler handler);


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
 * Returns the superclass of the given class \cls.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the class object.
 */
DART_EXPORT Dart_Handle Dart_GetSuperclass(Dart_Handle cls);


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
 * the given class \cls.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to an array containing field names and
 * corresponding field values. The array is empty if the class has
 * no static fields. If non-empty, field names are at array offsets 2*n,
 * values at offset 2*n+1. Field values may also be a handle to an
 * error object if an error was encountered evaluating the field.
 */
DART_EXPORT Dart_Handle Dart_GetStaticFields(Dart_Handle cls);


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


#endif  // INCLUDE_DART_DEBUGGER_API_H_
