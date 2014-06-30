/*
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#ifndef INCLUDE_DART_API_H_
#define INCLUDE_DART_API_H_

/** \mainpage Dart Embedding API Reference
 *
 * Dart is a class-based programming language for creating structured
 * web applications. This reference describes the Dart embedding api,
 * which is used to embed the Dart Virtual Machine within an
 * application.
 *
 * This reference is generated from the header include/dart_api.h.
 */

#ifdef __cplusplus
#define DART_EXTERN_C extern "C"
#else
#define DART_EXTERN_C
#endif

#if defined(__CYGWIN__)
#error Tool chain and platform not supported.
#elif defined(_WIN32)
// Define bool if necessary.
#ifndef __cplusplus
typedef unsigned __int8 bool;
#endif
// Define integer types.
typedef signed __int8 int8_t;
typedef signed __int16 int16_t;
typedef signed __int32 int32_t;
typedef signed __int64 int64_t;
typedef unsigned __int8 uint8_t;
typedef unsigned __int16 uint16_t;
typedef unsigned __int32 uint32_t;
typedef unsigned __int64 uint64_t;
#if defined(DART_SHARED_LIB)
#define DART_EXPORT DART_EXTERN_C __declspec(dllexport)
#else
#define DART_EXPORT DART_EXTERN_C
#endif
#else
/* __STDC_FORMAT_MACROS has to be defined before including <inttypes.h> to
 * enable platform independent printf format specifiers. */
#ifndef __STDC_FORMAT_MACROS
#define __STDC_FORMAT_MACROS
#endif
#include <inttypes.h>
#include <stdbool.h>
#if __GNUC__ >= 4
#if defined(DART_SHARED_LIB)
#define DART_EXPORT DART_EXTERN_C __attribute__ ((visibility("default")))
#else
#define DART_EXPORT DART_EXTERN_C
#endif
#else
#error Tool chain not supported.
#endif
#endif

#include <assert.h>

/*
 * =======
 * Handles
 * =======
 */

/**
 * An isolate is the unit of concurrency in Dart. Each isolate has
 * its own memory and thread of control. No state is shared between
 * isolates. Instead, isolates communicate by message passing.
 *
 * Each thread keeps track of its current isolate, which is the
 * isolate which is ready to execute on the current thread. The
 * current isolate may be NULL, in which case no isolate is ready to
 * execute. Most of the Dart apis require there to be a current
 * isolate in order to function without error. The current isolate is
 * set by any call to Dart_CreateIsolate or Dart_EnterIsolate.
 */
typedef struct _Dart_Isolate* Dart_Isolate;

/**
 * An object reference managed by the Dart VM garbage collector.
 *
 * Because the garbage collector may move objects, it is unsafe to
 * refer to objects directly. Instead, we refer to objects through
 * handles, which are known to the garbage collector and updated
 * automatically when the object is moved. Handles should be passed
 * by value (except in cases like out-parameters) and should never be
 * allocated on the heap.
 *
 * Most functions in the Dart Embedding API return a handle. When a
 * function completes normally, this will be a valid handle to an
 * object in the Dart VM heap. This handle may represent the result of
 * the operation or it may be a special valid handle used merely to
 * indicate successful completion. Note that a valid handle may in
 * some cases refer to the null object.
 *
 * --- Error handles ---
 *
 * When a function encounters a problem that prevents it from
 * completing normally, it returns an error handle (See Dart_IsError).
 * An error handle has an associated error message that gives more
 * details about the problem (See Dart_GetError).
 *
 * There are four kinds of error handles that can be produced,
 * depending on what goes wrong:
 *
 * - Api error handles are produced when an api function is misused.
 *   This happens when a Dart embedding api function is called with
 *   invalid arguments or in an invalid context.
 *
 * - Unhandled exception error handles are produced when, during the
 *   execution of Dart code, an exception is thrown but not caught.
 *   Prototypically this would occur during a call to Dart_Invoke, but
 *   it can occur in any function which triggers the execution of Dart
 *   code (for example, Dart_ToString).
 *
 *   An unhandled exception error provides access to an exception and
 *   stacktrace via the functions Dart_ErrorGetException and
 *   Dart_ErrorGetStacktrace.
 *
 * - Compilation error handles are produced when, during the execution
 *   of Dart code, a compile-time error occurs.  As above, this can
 *   occur in any function which triggers the execution of Dart code.
 *
 * - Fatal error handles are produced when the system wants to shut
 *   down the current isolate.
 *
 * --- Propagating errors ---
 *
 * When an error handle is returned from the top level invocation of
 * Dart code in a program, the embedder must handle the error as they
 * see fit.  Often, the embedder will print the error message produced
 * by Dart_Error and exit the program.
 *
 * When an error is returned while in the body of a native function,
 * it can be propagated by calling Dart_PropagateError.  Errors should
 * be propagated unless there is a specific reason not to.  If an
 * error is not propagated then it is ignored.  For example, if an
 * unhandled exception error is ignored, that effectively "catches"
 * the unhandled exception.  Fatal errors must always be propagated.
 *
 * Note that a call to Dart_PropagateError never returns.  Instead it
 * transfers control non-locally using a setjmp-like mechanism.  This
 * can be inconvenient if you have resources that you need to clean up
 * before propagating the error.  When an error is propagated, any
 * current scopes created by Dart_EnterScope will be exited.
 *
 * To deal with this inconvenience, we often return error handles
 * rather than propagating them from helper functions.  Consider the
 * following contrived example:
 *
 * 1    Dart_Handle isLongStringHelper(Dart_Handle arg) {
 * 2      intptr_t* length = 0;
 * 3      result = Dart_StringLength(arg, &length);
 * 4      if (Dart_IsError(result)) {
 * 5        return result
 * 6      }
 * 7      return Dart_NewBoolean(length > 100);
 * 8    }
 * 9
 * 10   void NativeFunction_isLongString(Dart_NativeArguments args) {
 * 11     Dart_EnterScope();
 * 12     AllocateMyResource();
 * 13     Dart_Handle arg = Dart_GetNativeArgument(args, 0);
 * 14     Dart_Handle result = isLongStringHelper(arg);
 * 15     if (Dart_IsError(result)) {
 * 16       FreeMyResource();
 * 17       Dart_PropagateError(result);
 * 18       abort();  // will not reach here
 * 19     }
 * 20     Dart_SetReturnValue(result);
 * 21     FreeMyResource();
 * 22     Dart_ExitScope();
 * 23   }
 *
 * In this example, we have a native function which calls a helper
 * function to do its work.  On line 5, the helper function could call
 * Dart_PropagateError, but that would not give the native function a
 * chance to call FreeMyResource(), causing a leak.  Instead, the
 * helper function returns the error handle to the caller, giving the
 * caller a chance to clean up before propagating the error handle.
 *
 * --- Local and persistent handles ---
 *
 * Local handles are allocated within the current scope (see
 * Dart_EnterScope) and go away when the current scope exits. Unless
 * otherwise indicated, callers should assume that all functions in
 * the Dart embedding api return local handles.
 *
 * Persistent handles are allocated within the current isolate. They
 * can be used to store objects across scopes. Persistent handles have
 * the lifetime of the current isolate unless they are explicitly
 * deallocated (see Dart_DeletePersistentHandle).
 * The type Dart_Handle represents a handle (both local and persistent).
 * The type Dart_PersistentHandle is a Dart_Handle and it is used to
 * document that a persistent handle is expected as a parameter to a call
 * or the return value from a call is a persistent handle.
 */
typedef struct _Dart_Handle* Dart_Handle;
typedef Dart_Handle Dart_PersistentHandle;
typedef struct _Dart_WeakPersistentHandle* Dart_WeakPersistentHandle;

typedef void (*Dart_WeakPersistentHandleFinalizer)(
    void* isolate_callback_data,
    Dart_WeakPersistentHandle handle,
    void* peer);
typedef void (*Dart_PeerFinalizer)(void* peer);

/**
 * Is this an error handle?
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsError(Dart_Handle handle);

/**
 * Is this an api error handle?
 *
 * Api error handles are produced when an api function is misused.
 * This happens when a Dart embedding api function is called with
 * invalid arguments or in an invalid context.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsApiError(Dart_Handle handle);

/**
 * Is this an unhandled exception error handle?
 *
 * Unhandled exception error handles are produced when, during the
 * execution of Dart code, an exception is thrown but not caught.
 * This can occur in any function which triggers the execution of Dart
 * code.
 *
 * See Dart_ErrorGetException and Dart_ErrorGetStacktrace.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsUnhandledExceptionError(Dart_Handle handle);

/**
 * Is this a compilation error handle?
 *
 * Compilation error handles are produced when, during the execution
 * of Dart code, a compile-time error occurs.  This can occur in any
 * function which triggers the execution of Dart code.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsCompilationError(Dart_Handle handle);

/**
 * Is this a fatal error handle?
 *
 * Fatal error handles are produced when the system wants to shut down
 * the current isolate.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsFatalError(Dart_Handle handle);

/**
 * Gets the error message from an error handle.
 *
 * Requires there to be a current isolate.
 *
 * \return A C string containing an error message if the handle is
 *   error. An empty C string ("") if the handle is valid. This C
 *   String is scope allocated and is only valid until the next call
 *   to Dart_ExitScope.
*/
DART_EXPORT const char* Dart_GetError(Dart_Handle handle);

/**
 * Is this an error handle for an unhandled exception?
 */
DART_EXPORT bool Dart_ErrorHasException(Dart_Handle handle);

/**
 * Gets the exception Object from an unhandled exception error handle.
 */
DART_EXPORT Dart_Handle Dart_ErrorGetException(Dart_Handle handle);

/**
 * Gets the stack trace Object from an unhandled exception error handle.
 */
DART_EXPORT Dart_Handle Dart_ErrorGetStacktrace(Dart_Handle handle);

/**
 * Produces an api error handle with the provided error message.
 *
 * Requires there to be a current isolate.
 *
 * \param error the error message.
 */
DART_EXPORT Dart_Handle Dart_NewApiError(const char* error);

/**
 * Produces a new unhandled exception error handle.
 *
 * Requires there to be a current isolate.
 *
 * \param exception An instance of a Dart object to be thrown.
 */
DART_EXPORT Dart_Handle Dart_NewUnhandledExceptionError(Dart_Handle exception);

/**
 * Propagates an error.
 *
 * If the provided handle is an unhandled exception error, this
 * function will cause the unhandled exception to be rethrown.  This
 * will proceed in the standard way, walking up Dart frames until an
 * appropriate 'catch' block is found, executing 'finally' blocks,
 * etc.
 *
 * If the error is not an unhandled exception error, we will unwind
 * the stack to the next C frame.  Intervening Dart frames will be
 * discarded; specifically, 'finally' blocks will not execute.  This
 * is the standard way that compilation errors (and the like) are
 * handled by the Dart runtime.
 *
 * In either case, when an error is propagated any current scopes
 * created by Dart_EnterScope will be exited.
 *
 * See the additional discussion under "Propagating Errors" at the
 * beginning of this file.
 *
 * \param An error handle (See Dart_IsError)
 *
 * \return On success, this function does not return.  On failure, an
 *   error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_PropagateError(Dart_Handle handle);
/* TODO(turnidge): Should this really return an error handle? */
/* Consider just terminating. */

/* Internal routine used for reporting error handles. */
DART_EXPORT void _Dart_ReportErrorHandle(const char* file,
                                         int line,
                                         const char* handle_string,
                                         const char* error);

/* TODO(turnidge): Move DART_CHECK_VALID to some sort of dart_utils
 * header instead of this header. */
/**
 * Aborts the process if 'handle' is an error handle.
 *
 * Provided for convenience.
 */
#define DART_CHECK_VALID(handle)                                               \
  {                                                                            \
    Dart_Handle __handle = handle;                                             \
    if (Dart_IsError((__handle))) {                                            \
      _Dart_ReportErrorHandle(__FILE__, __LINE__,                              \
                              #handle, Dart_GetError(__handle));               \
    }                                                                          \
  }                                                                            \


/**
 * Converts an object to a string.
 *
 * May generate an unhandled exception error.
 *
 * \return The converted string if no error occurs during
 *   the conversion. If an error does occur, an error handle is
 *   returned.
 */
DART_EXPORT Dart_Handle Dart_ToString(Dart_Handle object);

/**
 * Checks to see if two handles refer to identically equal objects.
 *
 * If both handles refer to instances, this is equivalent to using the top-level
 * function identical() from dart:core. Otherwise, returns whether the two
 * argument handles refer to the same object.
 *
 * \param obj1 An object to be compared.
 * \param obj2 An object to be compared.
 *
 * \return True if the objects are identically equal.  False otherwise.
 */
DART_EXPORT bool Dart_IdentityEquals(Dart_Handle obj1, Dart_Handle obj2);

/**
 * Returns a hash code for the argument. The hash code of objects that are equal
 * according to Dart_IdentityEquals will return the same hash code, but the hash
 * codes of non-equal objects are not necessarily distinct.
 *
 * \param obj An object for which to derive a hash code.
 *
 * \return A hash code for the parameter.
 */
DART_EXPORT uint64_t Dart_IdentityHash(Dart_Handle obj);

/**
 * Allocates a handle in the current scope from a persistent handle.
 */
DART_EXPORT Dart_Handle Dart_HandleFromPersistent(Dart_PersistentHandle object);

/**
 * Allocates a handle in the current scope from a weak persistent handle.
 */
DART_EXPORT Dart_Handle Dart_HandleFromWeakPersistent(
    Dart_WeakPersistentHandle object);

/**
 * Allocates a persistent handle for an object.
 *
 * This handle has the lifetime of the current isolate unless it is
 * explicitly deallocated by calling Dart_DeletePersistentHandle.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_PersistentHandle Dart_NewPersistentHandle(Dart_Handle object);

/**
 * Assign value of local handle to a persistent handle.
 *
 * Requires there to be a current isolate.
 *
 * \param obj1 A persistent handle whose value needs to be set.
 * \param obj2 An object whose value needs to be set to the persistent handle.
 *
 * \return Success if the persistent handle was set
 *   Otherwise, returns an error.
 */
DART_EXPORT void Dart_SetPersistentHandle(Dart_PersistentHandle obj1,
                                          Dart_Handle obj2);

/**
 * Deallocates a persistent handle.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_DeletePersistentHandle(Dart_PersistentHandle object);

/**
 * Allocates a weak persistent handle for an object.
 *
 * This handle has the lifetime of the current isolate unless the object
 * pointed to by the handle is garbage collected, in this case the VM
 * automatically deletes the handle after invoking the callback associated
 * with the handle. The handle can also be explicitly deallocated by
 * calling Dart_DeleteWeakPersistentHandle.
 *
 * If the object becomes unreachable the callback is invoked with the weak
 * persistent handle and the peer as arguments. This gives the native code the
 * ability to cleanup data associated with the object and clear out any cached
 * references to the handle. All references to this handle after the callback
 * will be invalid. It is illegal to call into the VM from the callback.
 * If the handle is deleted before the object becomes unreachable,
 * the callback is never invoked.
 *
 * Requires there to be a current isolate.
 *
 * \param object An object.
 * \param peer A pointer to a native object or NULL.  This value is
 *   provided to callback when it is invoked.
 * \param external_allocation_size The number of externally allocated
 *   bytes for peer. Used to inform the garbage collector.
 * \param callback A function pointer that will be invoked sometime
 *   after the object is garbage collected, unless the handle has been deleted.
 *   A valid callback needs to be specified it cannot be NULL.
 *
 * \return Success if the weak persistent handle was
 *   created. Otherwise, returns an error.
 */
DART_EXPORT Dart_WeakPersistentHandle Dart_NewWeakPersistentHandle(
    Dart_Handle object,
    void* peer,
    intptr_t external_allocation_size,
    Dart_WeakPersistentHandleFinalizer callback);

DART_EXPORT void Dart_DeleteWeakPersistentHandle(
    Dart_Isolate isolate,
    Dart_WeakPersistentHandle object);

/**
 * Allocates a prologue weak persistent handle for an object.
 *
 * Prologue weak persistent handles are similar to weak persistent
 * handles but exhibit different behavior during garbage collections
 * that invoke the prologue and epilogue callbacks.  While weak
 * persistent handles always weakly reference their referents,
 * prologue weak persistent handles weakly reference their referents
 * only during a garbage collection that invokes the prologue and
 * epilogue callbacks.  During all other garbage collections, prologue
 * weak persistent handles strongly reference their referents.
 *
 * This handle has the lifetime of the current isolate unless the object
 * pointed to by the handle is garbage collected, in this case the VM
 * automatically deletes the handle after invoking the callback associated
 * with the handle. The handle can also be explicitly deallocated by
 * calling Dart_DeleteWeakPersistentHandle.
 *
 * If the object becomes unreachable the callback is invoked with the weak
 * persistent handle and the peer as arguments. This gives the native code the
 * ability to cleanup data associated with the object and clear out any cached
 * references to the handle. All references to this handle after the callback
 * will be invalid. It is illegal to call into the VM from the callback.
 * If the handle is deleted before the object becomes unreachable,
 * the callback is never invoked.
 *
 * Requires there to be a current isolate.
 *
 * \param object An object.
 * \param peer A pointer to a native object or NULL.  This value is
 *   provided to callback when it is invoked.
 * \param external_allocation_size The number of externally allocated
 *   bytes for peer. Used to inform the garbage collector.
 * \param callback A function pointer that will be invoked sometime
 *   after the object is garbage collected, unless the handle has been deleted.
 *   A valid callback needs to be specified it cannot be NULL.
 *
 * \return Success if the prologue weak persistent handle was created.
 *   Otherwise, returns an error.
 */
DART_EXPORT Dart_WeakPersistentHandle Dart_NewPrologueWeakPersistentHandle(
    Dart_Handle object,
    void* peer,
    intptr_t external_allocation_size,
    Dart_WeakPersistentHandleFinalizer callback);

/**
 * Is this object a prologue weak persistent handle?
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsPrologueWeakPersistentHandle(
    Dart_WeakPersistentHandle object);

typedef struct _Dart_WeakReferenceSetBuilder* Dart_WeakReferenceSetBuilder;
typedef struct _Dart_WeakReferenceSet* Dart_WeakReferenceSet;

/**
 * Constructs a weak references set builder.
 *
 * \returns a pointer to the weak reference set builder if successful.
 *   Otherwise, returns NULL.
 */
DART_EXPORT Dart_WeakReferenceSetBuilder Dart_NewWeakReferenceSetBuilder();

/**
 * Constructs a set of weak references from the Cartesian product of
 * the objects in the key set and the objects in values set.
 *
 * \param set_builder The weak references set builder which was created
 *   using Dart_NewWeakReferenceSetBuilder().
 * \param key An object reference.  This references will be
 *   considered weak by the garbage collector.
 * \param value An object reference.  This reference will be
 *   considered weak by garbage collector unless any object reference
 *   in 'keys' is found to be strong.
 *
 * \return a pointer to the weak reference set if successful.
 *   Otherwise, returns NULL.
 */
DART_EXPORT Dart_WeakReferenceSet Dart_NewWeakReferenceSet(
    Dart_WeakReferenceSetBuilder set_builder,
    Dart_WeakPersistentHandle key,
    Dart_WeakPersistentHandle value);

/**
 * Append the pair of key/value object references to the weak references set.
 *
 * \param reference_set A weak references set into which the pair of key/value
 *   needs to be added.
 * \param key An object reference.  This references will be
 *   considered weak by the garbage collector.
 * \param value An object reference.  This reference will be
 *   considered weak by garbage collector unless any object reference
 *   in 'keys' is found to be strong.
 *
 * \return Success if the prologue weak persistent handle was created.
 *   Otherwise, returns an error.
 */
DART_EXPORT Dart_Handle Dart_AppendToWeakReferenceSet(
    Dart_WeakReferenceSet reference_set,
    Dart_WeakPersistentHandle key,
    Dart_WeakPersistentHandle value);

/**
 * Append the key object reference to the weak references set.
 *
 * \param reference_set A weak references set into which the key
 *   needs to be added.
 * \param key An object reference.  This references will be
 *   considered weak by the garbage collector.
 *
 * \return Success if the prologue weak persistent handle was created.
 *   Otherwise, returns an error.
 */
DART_EXPORT Dart_Handle Dart_AppendKeyToWeakReferenceSet(
    Dart_WeakReferenceSet reference_set,
    Dart_WeakPersistentHandle key);

/**
 * Append the value object reference to the weak references set.
 *
 * \param reference_set A weak references set into which the key
 *   needs to be added.
 * \param value An object reference.  This references will be
 *   considered weak by the garbage collector.
 *
 * \return Success if the prologue weak persistent handle was created.
 *   Otherwise, returns an error.
 */
DART_EXPORT Dart_Handle Dart_AppendValueToWeakReferenceSet(
    Dart_WeakReferenceSet reference_set,
    Dart_WeakPersistentHandle value);


/*
 * ============================
 * Garbage Collection Callbacks
 * ============================
 */

/**
 * Callbacks signal the beginning and end of a garbage collection.
 *
 * These signals are intended to be used by the embedder to manage the
 * lifetime of native objects with a managed object peer.
 */

/**
 * A callback invoked at the beginning of a garbage collection.
 */
typedef void (*Dart_GcPrologueCallback)();

/**
 * A callback invoked at the end of a garbage collection.
 */
typedef void (*Dart_GcEpilogueCallback)();

/**
 * Adds garbage collection callbacks (prologue and epilogue).
 *
 * \param prologue_callback A function pointer to a prologue callback function.
 *   A prologue callback function should not be already set when this function
 *   is called. A NULL value removes the existing prologue callback function
 *   if any.
 *
 * \param epilogue_callback A function pointer to an epilogue callback function.
 *   An epilogue callback function should not be already set when this function
 *   is called. A NULL value removes the existing epilogue callback function
 *   if any.
 *
 * \return Success if the callbacks were added.  Otherwise, returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_SetGcCallbacks(
    Dart_GcPrologueCallback prologue_callback,
    Dart_GcEpilogueCallback epilogue_callback);

typedef void (*Dart_GcPrologueWeakHandleCallback)(void* isolate_callback_data,
                                                  Dart_WeakPersistentHandle obj,
                                                  intptr_t num_native_fields,
                                                  intptr_t* native_fields);

DART_EXPORT Dart_Handle Dart_VisitPrologueWeakHandles(
    Dart_GcPrologueWeakHandleCallback callback);

/*
 * ==========================
 * Initialization and Globals
 * ==========================
 */

/**
 * Gets the version string for the Dart VM.
 *
 * The version of the Dart VM can be accessed without initializing the VM.
 *
 * \return The version string for the embedded Dart VM.
 */
DART_EXPORT const char* Dart_VersionString();

/**
 * An isolate creation and initialization callback function.
 *
 * This callback, provided by the embedder, is called when the vm
 * needs to create an isolate. The callback should create an isolate
 * by calling Dart_CreateIsolate and load any scripts required for
 * execution.
 *
 * When the function returns false, it is the responsibility of this
 * function to ensure that Dart_ShutdownIsolate has been called if
 * required (for example, if the isolate was created successfully by
 * Dart_CreateIsolate() but the root library fails to load
 * successfully, then the function should call Dart_ShutdownIsolate
 * before returning).
 *
 * When the function returns false, the function should set *error to
 * a malloc-allocated buffer containing a useful error message.  The
 * caller of this function (the vm) will make sure that the buffer is
 * freed.
 *
 * \param script_uri The uri of the script to load.
 *   This uri is non NULL if the isolate is being created using the
 *   spawnUri isolate API. This uri has been canonicalized by the
 *   library tag handler from the parent isolate.
 *   The callback is responsible for loading this script by a call to
 *   Dart_LoadScript or Dart_LoadScriptFromSnapshot.
 *   This uri will be NULL if the isolate is being created using the
 *   spawnFunction isolate API.
 *   The callback is responsible for loading the script used in the
 *   parent isolate by a call to Dart_LoadScript or
 *   Dart_LoadScriptFromSnapshot.
 * \param main The name of the main entry point this isolate will
 *   eventually run.  This is provided for advisory purposes only to
 *   improve debugging messages.  The main function is not invoked by
 *   this function.
 * \param callback_data The callback data which was passed to the
 *   parent isolate when it was created by calling Dart_CreateIsolate().
 * \param error A structure into which the embedder can place a
 *   C string containing an error message in the case of failures.
 *
 * \return The embedder returns NULL if the creation and
 *   initialization was not successful and the isolate if successful.
 */
typedef Dart_Isolate (*Dart_IsolateCreateCallback)(const char* script_uri,
                                                   const char* main,
                                                   void* callback_data,
                                                   char** error);


/**
 * The service isolate creation and initialization callback function.
 *
 * This callback, provided by the embedder, is called when the vm
 * needs to create the service isolate. The callback should create an isolate
 * by calling Dart_CreateIsolate and prepare the isolate to be used as
 * the service isolate.
 *
 * When the function returns NULL, it is the responsibility of this
 * function to ensure that Dart_ShutdownIsolate has been called if
 * required.
 *
 * When the function returns NULL, the function should set *error to
 * a malloc-allocated buffer containing a useful error message.  The
 * caller of this function (the vm) will make sure that the buffer is
 * freed.
 *
 *
 * \param error A structure into which the embedder can place a
 *   C string containing an error message in the case of failures.
 *
 * \return The embedder returns NULL if the creation and
 *   initialization was not successful and the isolate if successful.
 */
typedef Dart_Isolate (*Dart_ServiceIsolateCreateCalback)(void* callback_data,
                                                         char** error);

/**
 * An isolate interrupt callback function.
 *
 * This callback, provided by the embedder, is called when an isolate
 * is interrupted as a result of a call to Dart_InterruptIsolate().
 * When the callback is called, Dart_CurrentIsolate can be used to
 * figure out which isolate is being interrupted.
 *
 * \return The embedder returns true if the isolate should continue
 *   execution. If the embedder returns false, the isolate will be
 *   unwound (currently unimplemented).
 */
typedef bool (*Dart_IsolateInterruptCallback)();
/* TODO(turnidge): Define and implement unwinding. */

/**
 * An isolate unhandled exception callback function.
 *
 * This callback, provided by the embedder, is called when an unhandled
 * exception or internal error is thrown during isolate execution. When the
 * callback is invoked, Dart_CurrentIsolate can be used to figure out which
 * isolate was running when the exception was thrown.
 *
 * \param error The unhandled exception or error.  This handle's scope is
 *   only valid until the embedder returns from this callback.
 */
typedef void (*Dart_IsolateUnhandledExceptionCallback)(Dart_Handle error);

/**
 * An isolate shutdown callback function.
 *
 * This callback, provided by the embedder, is called before the vm
 * shuts down an isolate.  The isolate being shutdown will be the current
 * isolate. It is safe to run Dart code.
 *
 * This function should be used to dispose of native resources that
 * are allocated to an isolate in order to avoid leaks.
 *
 * \param callback_data The same callback data which was passed to the
 *   isolate when it was created.
 *
 */
typedef void (*Dart_IsolateShutdownCallback)(void* callback_data);

/**
 * Callbacks provided by the embedder for file operations. If the
 * embedder does not allow file operations these callbacks can be
 * NULL.
 *
 * Dart_FileOpenCallback - opens a file for reading or writing.
 * \param name The name of the file to open.
 * \param write A boolean variable which indicates if the file is to
 *   opened for writing. If there is an existing file it needs to truncated.
 *
 * Dart_FileReadCallback - Read contents of file.
 * \param data Buffer allocated in the callback into which the contents
 *   of the file are read into. It is the responsibility of the caller to
 *   free this buffer.
 * \param file_length A variable into which the length of the file is returned.
 *   In the case of an error this value would be -1.
 * \param stream Handle to the opened file.
 *
 * Dart_FileWriteCallback - Write data into file.
 * \param data Buffer which needs to be written into the file.
 * \param length Length of the buffer.
 * \param stream Handle to the opened file.
 *
 * Dart_FileCloseCallback - Closes the opened file.
 * \param stream Handle to the opened file.
 *
 */
typedef void* (*Dart_FileOpenCallback)(const char* name, bool write);

typedef void (*Dart_FileReadCallback)(const uint8_t** data,
                                      intptr_t* file_length,
                                      void* stream);

typedef void (*Dart_FileWriteCallback)(const void* data,
                                       intptr_t length,
                                       void* stream);

typedef void (*Dart_FileCloseCallback)(void* stream);

typedef bool (*Dart_EntropySource)(uint8_t* buffer, intptr_t length);

/**
 * Initializes the VM.
 *
 * \param create A function to be called during isolate creation.
 *   See Dart_IsolateCreateCallback.
 * \param interrupt A function to be called when an isolate is interrupted.
 *   See Dart_IsolateInterruptCallback.
 * \param unhandled_exception A function to be called if an isolate has an
 *   unhandled exception.  Set Dart_IsolateUnhandledExceptionCallback.
 * \param shutdown A function to be called when an isolate is shutdown.
 *   See Dart_IsolateShutdownCallback.
 *
 * \return True if initialization is successful.
 */
DART_EXPORT bool Dart_Initialize(
    Dart_IsolateCreateCallback create,
    Dart_IsolateInterruptCallback interrupt,
    Dart_IsolateUnhandledExceptionCallback unhandled_exception,
    Dart_IsolateShutdownCallback shutdown,
    Dart_FileOpenCallback file_open,
    Dart_FileReadCallback file_read,
    Dart_FileWriteCallback file_write,
    Dart_FileCloseCallback file_close,
    Dart_EntropySource entropy_source,
    Dart_ServiceIsolateCreateCalback service_create);

/**
 * Cleanup state in the VM before process termination.
 *
 * \return True if cleanup is successful.
 */
DART_EXPORT bool Dart_Cleanup();

/**
 * Sets command line flags. Should be called before Dart_Initialize.
 *
 * \param argc The length of the arguments array.
 * \param argv An array of arguments.
 *
 * \return True if VM flags set successfully.
 */
DART_EXPORT bool Dart_SetVMFlags(int argc, const char** argv);

/**
 * Returns true if the named VM flag is set.
 */
DART_EXPORT bool Dart_IsVMFlagSet(const char* flag_name);


/*
 * ========
 * Isolates
 * ========
 */

/**
 * Creates a new isolate. The new isolate becomes the current isolate.
 *
 * A snapshot can be used to restore the VM quickly to a saved state
 * and is useful for fast startup. If snapshot data is provided, the
 * isolate will be started using that snapshot data.
 *
 * Requires there to be no current isolate.
 *
 * \param script_uri The name of the script this isolate will load.
 *   Provided only for advisory purposes to improve debugging messages.
 * \param main The name of the main entry point this isolate will run.
 *   Provided only for advisory purposes to improve debugging messages.
 * \param snapshot A buffer containing a VM snapshot or NULL if no
 *   snapshot is provided.
 * \param callback_data Embedder data.  This data will be passed to
 *   the Dart_IsolateCreateCallback when new isolates are spawned from
 *   this parent isolate.
 * \param error DOCUMENT
 *
 * \return The new isolate is returned. May be NULL if an error
 *   occurs duing isolate initialization.
 */
DART_EXPORT Dart_Isolate Dart_CreateIsolate(const char* script_uri,
                                            const char* main,
                                            const uint8_t* snapshot,
                                            void* callback_data,
                                            char** error);
/* TODO(turnidge): Document behavior when there is already a current
 * isolate. */

/**
 * Shuts down the current isolate. After this call, the current isolate
 * is NULL. Invokes the shutdown callback and any callbacks of remaining
 * weak persistent handles.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_ShutdownIsolate();
/* TODO(turnidge): Document behavior when there is no current isolate. */

/**
 * Returns the current isolate. Will return NULL if there is no
 * current isolate.
 */
DART_EXPORT Dart_Isolate Dart_CurrentIsolate();

/**
 * Returns the callback data associated with the current Isolate. This data was
 * passed to the isolate when it was created.
 */
DART_EXPORT void* Dart_CurrentIsolateData();

/**
 * Returns the callback data associated with the specified Isolate. This data
 * was passed to the isolate when it was created.
 * The embedder is responsible for ensuring the consistency of this data
 * with respect to the lifecycle of an Isolate.
 */
DART_EXPORT void* Dart_IsolateData(Dart_Isolate isolate);

/**
 * Returns the debugging name for the current isolate.
 *
 * This name is unique to each isolate and should only be used to make
 * debugging messages more comprehensible.
 */
DART_EXPORT Dart_Handle Dart_DebugName();

/**
 * Enters an isolate. After calling this function,
 * the current isolate will be set to the provided isolate.
 *
 * Requires there to be no current isolate.
 */
DART_EXPORT void Dart_EnterIsolate(Dart_Isolate isolate);
/* TODO(turnidge): Describe what happens if two threads attempt to
 * enter the same isolate simultaneously. Check for this in the code.
 * Describe whether isolates are allowed to migrate. */

/**
 * Notifies the VM that the current isolate is about to make a blocking call.
 */
DART_EXPORT void Dart_IsolateBlocked();

/**
 * Notifies the VM that the current isolate is no longer blocked.
 */
DART_EXPORT void Dart_IsolateUnblocked();

/**
 * Exits an isolate. After this call, Dart_CurrentIsolate will
 * return NULL.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_ExitIsolate();
/* TODO(turnidge): We don't want users of the api to be able to exit a
 * "pure" dart isolate. Implement and document. */

/**
 * Creates a full snapshot of the current isolate heap.
 *
 * A full snapshot is a compact representation of the dart heap state and
 * can be used for fast initialization of an isolate. A Snapshot of the heap
 * can only be created before any dart code has executed.
 *
 * Requires there to be a current isolate.
 *
 * \param buffer Returns a pointer to a buffer containing the
 *   snapshot. This buffer is scope allocated and is only valid
 *   until the next call to Dart_ExitScope.
 * \param size Returns the size of the buffer.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_CreateSnapshot(uint8_t** buffer,
                                            intptr_t* size);

/**
 * Creates a snapshot of the application script loaded in the isolate.
 *
 * A script snapshot can be used for implementing fast startup of applications
 * (skips the script tokenizing and parsing process). A Snapshot of the script
 * can only be created before any dart code has executed.
 *
 * Requires there to be a current isolate which already has loaded script.
 *
 * \param buffer Returns a pointer to a buffer containing
 *   the snapshot. This buffer is scope allocated and is only valid
 *   until the next call to Dart_ExitScope.
 * \param size Returns the size of the buffer.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_CreateScriptSnapshot(uint8_t** buffer,
                                                  intptr_t* size);

/**
 * Schedules an interrupt for the specified isolate.
 *
 * Note that the interrupt does not occur immediately. In fact, if
 * 'isolate' does not execute any further Dart code, then the
 * interrupt will not occur at all.  If and when the isolate is
 * interrupted, the isolate interrupt callback will be invoked with
 * 'isolate' as the current isolate (see
 * Dart_IsolateInterruptCallback).
 *
 * \param isolate The isolate to be interrupted.
 */
DART_EXPORT void Dart_InterruptIsolate(Dart_Isolate isolate);

/**
 * Make isolate runnable.
 *
 * When isolates are spawned this function is used to indicate that
 * the creation and initialization (including script loading) of the
 * isolate is complete and the isolate can start.
 * This function does not expect there to be a current isolate.
 *
 * \param isolate The isolate to be made runnable.
 */
DART_EXPORT bool Dart_IsolateMakeRunnable(Dart_Isolate isolate);


/*
 * ==================
 * Messages and Ports
 * ==================
 */

/**
 * A port is used to send or receive inter-isolate messages
 */
typedef int64_t Dart_Port;

/**
 * ILLEGAL_PORT is a port number guaranteed never to be associated with a valid
 * port.
 */
#define ILLEGAL_PORT ((Dart_Port) 0)

/**
 * A message notification callback.
 *
 * This callback allows the embedder to provide an alternate wakeup
 * mechanism for the delivery of inter-isolate messages.  It is the
 * responsibility of the embedder to call Dart_HandleMessage to
 * process the message.
 */
typedef void (*Dart_MessageNotifyCallback)(Dart_Isolate dest_isolate);

/**
 * Allows embedders to provide an alternative wakeup mechanism for the
 * delivery of inter-isolate messages. This setting only applies to
 * the current isolate.
 *
 * Most embedders will only call this function once, before isolate
 * execution begins. If this function is called after isolate
 * execution begins, the embedder is responsible for threading issues.
 */
DART_EXPORT void Dart_SetMessageNotifyCallback(
    Dart_MessageNotifyCallback message_notify_callback);
/* TODO(turnidge): Consider moving this to isolate creation so that it
 * is impossible to mess up. */

/**
 * Handles the next pending message for the current isolate.
 *
 * May generate an unhandled exception error.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_HandleMessage();

/**
 * Handles any pending messages for the vm service for the current
 * isolate.
 *
 * This function may be used by an embedder at a breakpoint to avoid
 * pausing the vm service.
 *
 * \return true if the vm service requests the program resume
 * execution, false otherwise
 */
DART_EXPORT bool Dart_HandleServiceMessages();

/**
 * Processes any incoming messages for the current isolate.
 *
 * This function may only be used when the embedder has not provided
 * an alternate message delivery mechanism with
 * Dart_SetMessageCallbacks. It is provided for convenience.
 *
 * This function waits for incoming messages for the current
 * isolate. As new messages arrive, they are handled using
 * Dart_HandleMessage. The routine exits when all ports to the
 * current isolate are closed.
 *
 * \return A valid handle if the run loop exited successfully.  If an
 *   exception or other error occurs while processing messages, an
 *   error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_RunLoop();
/* TODO(turnidge): Should this be removed from the public api? */

/**
 * Gets the main port id for the current isolate.
 */
DART_EXPORT Dart_Port Dart_GetMainPortId();

/**
 * Does the current isolate have live ReceivePorts?
 *
 * A ReceivePort is live when it has not been closed.
 */
DART_EXPORT bool Dart_HasLivePorts();

/**
 * Posts a message for some isolate. The message is a serialized
 * object.
 *
 * Requires there to be a current isolate.
 *
 * \param port The destination port.
 * \param object An object from the current isolate.
 *
 * \return True if the message was posted.
 */
DART_EXPORT bool Dart_Post(Dart_Port port_id, Dart_Handle object);

/**
 * Returns a new SendPort with the provided port id.
 */
DART_EXPORT Dart_Handle Dart_NewSendPort(Dart_Port port_id);

/**
 * Gets the SendPort id for the provided SendPort.
 * \param port A SendPort object whose id is desired.
 * \param port_id Returns the id of the SendPort.
 * \return Success if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_SendPortGetId(Dart_Handle port,
                                           Dart_Port* port_id);


/*
 * ======
 * Scopes
 * ======
 */

/**
 * Enters a new scope.
 *
 * All new local handles will be created in this scope. Additionally,
 * some functions may return "scope allocated" memory which is only
 * valid within this scope.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_EnterScope();

/**
 * Exits a scope.
 *
 * The previous scope (if any) becomes the current scope.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_ExitScope();

/**
 * The Dart VM uses "zone allocation" for temporary structures. Zones
 * support very fast allocation of small chunks of memory. The chunks
 * cannot be deallocated individually, but instead zones support
 * deallocating all chunks in one fast operation.
 *
 * This function makes it possible for the embedder to allocate
 * temporary data in the VMs zone allocator.
 *
 * Zone allocation is possible:
 *   1. when inside a scope where local handles can be allocated
 *   2. when processing a message from a native port in a native port
 *      handler
 *
 * All the memory allocated this way will be reclaimed either on the
 * next call to Dart_ExitScope or when the native port handler exits.
 *
 * \param size Size of the memory to allocate.
 *
 * \return A pointer to the allocated memory. NULL if allocation
 *   failed. Failure might due to is no current VM zone.
 */
DART_EXPORT uint8_t* Dart_ScopeAllocate(intptr_t size);


/*
 * =======
 * Objects
 * =======
 */

/**
 * Returns the null object.
 *
 * \return A handle to the null object.
 */
DART_EXPORT Dart_Handle Dart_Null();

/**
 * Returns the empty string object.
 *
 * \return A handle to the empty string object.
 */
DART_EXPORT Dart_Handle Dart_EmptyString();

/**
 * Is this object null?
 */
DART_EXPORT bool Dart_IsNull(Dart_Handle object);

/**
 * Checks if the two objects are equal.
 *
 * The result of the comparison is returned through the 'equal'
 * parameter. The return value itself is used to indicate success or
 * failure, not equality.
 *
 * May generate an unhandled exception error.
 *
 * \param obj1 An object to be compared.
 * \param obj2 An object to be compared.
 * \param equal Returns the result of the equality comparison.
 *
 * \return A valid handle if no error occurs during the comparison.
 */
DART_EXPORT Dart_Handle Dart_ObjectEquals(Dart_Handle obj1,
                                          Dart_Handle obj2,
                                          bool* equal);

/**
 * Is this object an instance of some type?
 *
 * The result of the test is returned through the 'instanceof' parameter.
 * The return value itself is used to indicate success or failure.
 *
 * \param object An object.
 * \param type A type.
 * \param instanceof Return true if 'object' is an instance of type 'type'.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ObjectIsType(Dart_Handle object,
                                          Dart_Handle type,
                                          bool* instanceof);


/**
 * Query object type.
 *
 * \param object Some Object.
 *
 * \return true if Object is of the specified type.
 */
DART_EXPORT bool Dart_IsInstance(Dart_Handle object);
DART_EXPORT bool Dart_IsNumber(Dart_Handle object);
DART_EXPORT bool Dart_IsInteger(Dart_Handle object);
DART_EXPORT bool Dart_IsDouble(Dart_Handle object);
DART_EXPORT bool Dart_IsBoolean(Dart_Handle object);
DART_EXPORT bool Dart_IsString(Dart_Handle object);
DART_EXPORT bool Dart_IsStringLatin1(Dart_Handle object);  /* (ISO-8859-1) */
DART_EXPORT bool Dart_IsExternalString(Dart_Handle object);
DART_EXPORT bool Dart_IsList(Dart_Handle object);
DART_EXPORT bool Dart_IsMap(Dart_Handle object);
DART_EXPORT bool Dart_IsLibrary(Dart_Handle object);
DART_EXPORT bool Dart_IsType(Dart_Handle handle);
DART_EXPORT bool Dart_IsFunction(Dart_Handle handle);
DART_EXPORT bool Dart_IsVariable(Dart_Handle handle);
DART_EXPORT bool Dart_IsTypeVariable(Dart_Handle handle);
DART_EXPORT bool Dart_IsClosure(Dart_Handle object);


/*
 * =========
 * Instances
 * =========
 */

/*
 * For the purposes of the embedding api, not all objects returned are
 * Dart language objects.  Within the api, we use the term 'Instance'
 * to indicate handles which refer to true Dart language objects.
 *
 * TODO(turnidge): Reorganize the "Object" section above, pulling down
 * any functions that more properly belong here. */

/**
 * Gets the type of a Dart language object.
 *
 * \param instance Some Dart object.
 *
 * \return If no error occurs, the type is returned. Otherwise an
 *   error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_InstanceGetType(Dart_Handle instance);


/*
 * =============================
 * Numbers, Integers and Doubles
 * =============================
 */

/**
 * Does this Integer fit into a 64-bit signed integer?
 *
 * \param integer An integer.
 * \param fits Returns true if the integer fits into a 64-bit signed integer.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_IntegerFitsIntoInt64(Dart_Handle integer,
                                                  bool* fits);

/**
 * Does this Integer fit into a 64-bit unsigned integer?
 *
 * \param integer An integer.
 * \param fits Returns true if the integer fits into a 64-bit unsigned integer.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_IntegerFitsIntoUint64(Dart_Handle integer,
                                                   bool* fits);

/**
 * Returns an Integer with the provided value.
 *
 * \param value The value of the integer.
 *
 * \return The Integer object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewInteger(int64_t value);

/**
 * Returns an Integer with the provided value.
 *
 * \param value The value of the integer represented as a C string
 *   containing a hexadecimal number.
 *
 * \return The Integer object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewIntegerFromHexCString(const char* value);

/**
 * Gets the value of an Integer.
 *
 * The integer must fit into a 64-bit signed integer, otherwise an error occurs.
 *
 * \param integer An Integer.
 * \param value Returns the value of the Integer.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_IntegerToInt64(Dart_Handle integer,
                                            int64_t* value);

/**
 * Gets the value of an Integer.
 *
 * The integer must fit into a 64-bit unsigned integer, otherwise an
 * error occurs.
 *
 * \param integer An Integer.
 * \param value Returns the value of the Integer.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_IntegerToUint64(Dart_Handle integer,
                                             uint64_t* value);

/**
 * Gets the value of an integer as a hexadecimal C string.
 *
 * \param integer An Integer.
 * \param value Returns the value of the Integer as a hexadecimal C
 *   string. This C string is scope allocated and is only valid until
 *   the next call to Dart_ExitScope.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_IntegerToHexCString(Dart_Handle integer,
                                                 const char** value);

/**
 * Returns a Double with the provided value.
 *
 * \param value A double.
 *
 * \return The Double object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewDouble(double value);

/**
 * Gets the value of a Double
 *
 * \param double_obj A Double
 * \param value Returns the value of the Double.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_DoubleValue(Dart_Handle double_obj, double* value);


/*
 * ========
 * Booleans
 * ========
 */

/**
 * Returns the True object.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object.
 */
DART_EXPORT Dart_Handle Dart_True();

/**
 * Returns the False object.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the False object.
 */
DART_EXPORT Dart_Handle Dart_False();

/**
 * Returns a Boolean with the provided value.
 *
 * \param value true or false.
 *
 * \return The Boolean object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewBoolean(bool value);

/**
 * Gets the value of a Boolean
 *
 * \param boolean_obj A Boolean
 * \param value Returns the value of the Boolean.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_BooleanValue(Dart_Handle boolean_obj, bool* value);


/*
 * =======
 * Strings
 * =======
 */

/**
 * Gets the length of a String.
 *
 * \param str A String.
 * \param length Returns the length of the String.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringLength(Dart_Handle str, intptr_t* length);

/**
 * Returns a String built from the provided C string
 * (There is an implicit assumption that the C string passed in contains
 *  UTF-8 encoded characters and '\0' is considered as a termination
 *  character).
 *
 * \param value A C String
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewStringFromCString(const char* str);
/* TODO(turnidge): Document what happens when we run out of memory
 * during this call. */

/**
 * Returns a String built from an array of UTF-8 encoded characters.
 *
 * \param utf8_array An array of UTF-8 encoded characters.
 * \param length The length of the codepoints array.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewStringFromUTF8(const uint8_t* utf8_array,
                                               intptr_t length);

/**
 * Returns a String built from an array of UTF-16 encoded characters.
 *
 * \param utf16_array An array of UTF-16 encoded characters.
 * \param length The length of the codepoints array.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewStringFromUTF16(const uint16_t* utf16_array,
                                                intptr_t length);

/**
 * Returns a String built from an array of UTF-32 encoded characters.
 *
 * \param utf32_array An array of UTF-32 encoded characters.
 * \param length The length of the codepoints array.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewStringFromUTF32(const int32_t* utf32_array,
                                                intptr_t length);

/**
 * Returns a String which references an external array of
 * Latin-1 (ISO-8859-1) encoded characters.
 *
 * \param latin1_array Array of Latin-1 encoded characters. This must not move.
 * \param length The length of the characters array.
 * \param peer An external pointer to associate with this string.
 * \param cback A callback to be called when this string is finalized.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewExternalLatin1String(
    const uint8_t* latin1_array,
    intptr_t length,
    void* peer,
    Dart_PeerFinalizer cback);

/**
 * Returns a String which references an external array of UTF-16 encoded
 * characters.
 *
 * \param utf16_array An array of UTF-16 encoded characters. This must not move.
 * \param length The length of the characters array.
 * \param peer An external pointer to associate with this string.
 * \param cback A callback to be called when this string is finalized.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewExternalUTF16String(const uint16_t* utf16_array,
                                                    intptr_t length,
                                                    void* peer,
                                                    Dart_PeerFinalizer cback);

/**
 * Gets the C string representation of a String.
 * (It is a sequence of UTF-8 encoded values with a '\0' termination.)
 *
 * \param str A string.
 * \param cstr Returns the String represented as a C string.
 *   This C string is scope allocated and is only valid until
 *   the next call to Dart_ExitScope.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringToCString(Dart_Handle str,
                                             const char** cstr);

/**
 * Gets a UTF-8 encoded representation of a String.
 *
 * \param str A string.
 * \param utf8_array Returns the String represented as UTF-8 code
 *   units.  This UTF-8 array is scope allocated and is only valid
 *   until the next call to Dart_ExitScope.
 * \param length Used to return the length of the array which was
 *   actually used.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringToUTF8(Dart_Handle str,
                                          uint8_t** utf8_array,
                                          intptr_t* length);

/**
 * Gets the data corresponding to the string object. This function returns
 * the data only for Latin-1 (ISO-8859-1) string objects. For all other
 * string objects it returns an error.
 *
 * \param str A string.
 * \param latin1_array An array allocated by the caller, used to return
 *   the string data.
 * \param length Used to pass in the length of the provided array.
 *   Used to return the length of the array which was actually used.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringToLatin1(Dart_Handle str,
                                            uint8_t* latin1_array,
                                            intptr_t* length);

/**
 * Gets the UTF-16 encoded representation of a string.
 *
 * \param str A string.
 * \param utf16_array An array allocated by the caller, used to return
 *   the array of UTF-16 encoded characters.
 * \param length Used to pass in the length of the provided array.
 *   Used to return the length of the array which was actually used.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringToUTF16(Dart_Handle str,
                                           uint16_t* utf16_array,
                                           intptr_t* length);

/**
 * Gets the storage size in bytes of a String.
 *
 * \param str A String.
 * \param length Returns the storage size in bytes of the String.
 *  This is the size in bytes needed to store the String.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringStorageSize(Dart_Handle str, intptr_t* size);

/**
 * Converts a String into an ExternalString.
 * The original object is morphed into an external string object.
 *
 * \param array External space into which the string data will be
 *   copied into. This must not move.
 * \param length The size in bytes of the provided external space (array).
 * \param peer An external pointer to associate with this string.
 * \param cback A callback to be called when this string is finalized.
 *
 * \return the converted ExternalString object if no error occurs.
 *   Otherwise returns an error handle.
 *   If the object is a valid string but if it cannot be externalized
 *   the string data is copied into the external space specified
 *   and the passed in peer is setup as a peer for this string object.
 *   In this case the function returns the original String object as is.
 *
 * For example:
 *  intptr_t size;
 *  Dart_Handle result;
 *  result = DartStringStorageSize(str, &size);
 *  void* data = malloc(size);
 *  result = Dart_MakeExternalString(str, data, size, NULL, NULL);
 *
 */
DART_EXPORT Dart_Handle Dart_MakeExternalString(Dart_Handle str,
                                                void* array,
                                                intptr_t length,
                                                void* peer,
                                                Dart_PeerFinalizer cback);

/**
 * Retrieves some properties associated with a String.
 * Properties retrieved are:
 * - character size of the string (one or two byte)
 * - length of the string
 * - peer pointer of string if it is an external string.
 * \param str A String.
 * \param char_size Returns the character size of the String.
 * \param str_len Returns the length of the String.
 * \param peer Returns the peer pointer associated with the String or 0 if
 *   there is no peer pointer for it.
 * \return Success if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_StringGetProperties(Dart_Handle str,
                                                 intptr_t* char_size,
                                                 intptr_t* str_len,
                                                 void** peer);

/*
 * =====
 * Lists
 * =====
 */

/**
 * Returns a List of the desired length.
 *
 * \param length The length of the list.
 *
 * \return The List object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewList(intptr_t length);

/**
 * Gets the length of a List.
 *
 * May generate an unhandled exception error.
 *
 * \param list A List.
 * \param length Returns the length of the List.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ListLength(Dart_Handle list, intptr_t* length);

/**
 * Gets the Object at some index of a List.
 *
 * If the index is out of bounds, an error occurs.
 *
 * May generate an unhandled exception error.
 *
 * \param list A List.
 * \param index A valid index into the List.
 *
 * \return The Object in the List at the specified index if no error
 *   occurs. Otherwise returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_ListGetAt(Dart_Handle list,
                                       intptr_t index);

/**
 * Sets the Object at some index of a List.
 *
 * If the index is out of bounds, an error occurs.
 *
 * May generate an unhandled exception error.
 *
 * \param array A List.
 * \param index A valid index into the List.
 * \param value The Object to put in the List.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ListSetAt(Dart_Handle list,
                                       intptr_t index,
                                       Dart_Handle value);

/**
 * May generate an unhandled exception error.
 */
DART_EXPORT Dart_Handle Dart_ListGetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            uint8_t* native_array,
                                            intptr_t length);

/**
 * May generate an unhandled exception error.
 */
DART_EXPORT Dart_Handle Dart_ListSetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            uint8_t* native_array,
                                            intptr_t length);


/*
 * ====
 * Maps
 * ====
 */

/**
 * Gets the Object at some key of a Map.
 *
 * May generate an unhandled exception error.
 *
 * \param map A Map.
 * \param key An Object.
 *
 * \return The value in the map at the specified key, null if the map does not
 *   contain the key, or an error handle.
 */
DART_EXPORT Dart_Handle Dart_MapGetAt(Dart_Handle map, Dart_Handle key);

/**
 * Returns whether the Map contains a given key.
 *
 * May generate an unhandled exception error.
 *
 * \param map A Map.
 *
 * \return A handle on a boolean indicating whether map contains the key.
 *   Otherwise returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_MapContainsKey(Dart_Handle map, Dart_Handle key);

/**
 * Gets the list of keys of a Map.
 *
 * May generate an unhandled exception error.
 *
 * \param map A Map.
 *
 * \return The list of key Objects if no error occurs. Otherwise returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_MapKeys(Dart_Handle map);


/*
 * ==========
 * Typed Data
 * ==========
 */

typedef enum {
  Dart_TypedData_kByteData = 0,
  Dart_TypedData_kInt8,
  Dart_TypedData_kUint8,
  Dart_TypedData_kUint8Clamped,
  Dart_TypedData_kInt16,
  Dart_TypedData_kUint16,
  Dart_TypedData_kInt32,
  Dart_TypedData_kUint32,
  Dart_TypedData_kInt64,
  Dart_TypedData_kUint64,
  Dart_TypedData_kFloat32,
  Dart_TypedData_kFloat64,
  Dart_TypedData_kFloat32x4,
  Dart_TypedData_kInvalid
} Dart_TypedData_Type;

/**
 * Return type if this object is a TypedData object.
 *
 * \return kInvalid if the object is not a TypedData object or the appropriate
 *   Dart_TypedData_Type.
 */
DART_EXPORT Dart_TypedData_Type Dart_GetTypeOfTypedData(Dart_Handle object);

/**
 * Return type if this object is an external TypedData object.
 *
 * \return kInvalid if the object is not an external TypedData object or
 *   the appropriate Dart_TypedData_Type.
 */
DART_EXPORT Dart_TypedData_Type Dart_GetTypeOfExternalTypedData(
    Dart_Handle object);

/**
 * Returns a TypedData object of the desired length and type.
 *
 * \param type The type of the TypedData object.
 * \param length The length of the TypedData object (length in type units).
 *
 * \return The TypedData object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewTypedData(Dart_TypedData_Type type,
                                          intptr_t length);

/**
 * Returns a TypedData object which references an external data array.
 *
 * \param type The type of the data array.
 * \param value A data array. This array must not move.
 * \param length The length of the data array (length in type units).
 * \param peer An external pointer to associate with this array.
 *
 * \return The TypedData object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewExternalTypedData(Dart_TypedData_Type type,
                                                  void* data,
                                                  intptr_t length);

/**
 * Acquires access to the internal data address of a TypedData object.
 *
 * \param object The typed data object whose internal data address is to
 *    be accessed.
 * \param type The type of the object is returned here.
 * \param data The internal data address is returned here.
 * \param len Size of the typed array is returned here.
 *
 * Note: When the internal address of the object is acquired any calls to a
 *       Dart API function that could potentially allocate an object or run
 *       any Dart code will return an error.
 *
 * \return Success if the internal data address is acquired successfully.
 *   Otherwise, returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_TypedDataAcquireData(Dart_Handle object,
                                                  Dart_TypedData_Type* type,
                                                  void** data,
                                                  intptr_t* len);

/**
 * Releases access to the internal data address that was acquired earlier using
 * Dart_TypedDataAcquireData.
 *
 * \param object The typed data object whose internal data address is to be
 *   released.
 *
 * \return Success if the internal data address is released successfully.
 *   Otherwise, returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_TypedDataReleaseData(Dart_Handle object);


/*
 * ============================================================
 * Invoking Constructors, Methods, Closures and Field accessors
 * ============================================================
 */

/**
 * Invokes a constructor, creating a new object.
 *
 * This function allows hidden constructors (constructors with leading
 * underscores) to be called.
 *
 * \param type Type of object to be constructed.
 * \param constructor_name The name of the constructor to invoke.  Use
 *   Dart_Null() to invoke the unnamed constructor.  This name should
 *   not include the name of the class.
 * \param number_of_arguments Size of the arguments array.
 * \param arguments An array of arguments to the constructor.
 *
 * \return If the constructor is called and completes successfully,
 *   then the new object. If an error occurs during execution, then an
 *   error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_New(Dart_Handle type,
                                 Dart_Handle constructor_name,
                                 int number_of_arguments,
                                 Dart_Handle* arguments);

/**
 * Allocate a new object without invoking a constructor.
 *
 * \param type The type of an object to be allocated.
 *
 * \return The new object. If an error occurs during execution, then an
 *   error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_Allocate(Dart_Handle type);

/**
 * Allocate a new object without invoking a constructor, and sets specified
 *  native fields.
 *
 * \param type The type of an object to be allocated.
 * \param num_native_fields The number of native fields to set.
 * \param native_fields An array containing the value of native fields.
 *
 * \return The new object. If an error occurs during execution, then an
 *   error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_AllocateWithNativeFields(
    Dart_Handle type,
    intptr_t num_native_fields,
    const intptr_t* native_fields);

/**
 * Invokes a method or function.
 *
 * The 'target' parameter may be an object, type, or library.  If
 * 'target' is an object, then this function will invoke an instance
 * method.  If 'target' is a type, then this function will invoke a
 * static method.  If 'target' is a library, then this function will
 * invoke a top-level function from that library.
 * NOTE: This API call cannot be used to invoke methods of a type object.
 *
 * This function ignores visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param target An object, type, or library.
 * \param name The name of the function or method to invoke.
 * \param number_of_arguments Size of the arguments array.
 * \param arguments An array of arguments to the function.
 *
 * \return If the function or method is called and completes
 *   successfully, then the return value is returned. If an error
 *   occurs during execution, then an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_Invoke(Dart_Handle target,
                                    Dart_Handle name,
                                    int number_of_arguments,
                                    Dart_Handle* arguments);
/* TODO(turnidge): Document how to invoke operators. */

/**
 * Invokes a Closure with the given arguments.
 *
 * May generate an unhandled exception error.
 *
 * \return If no error occurs during execution, then the result of
 *   invoking the closure is returned. If an error occurs during
 *   execution, then an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_InvokeClosure(Dart_Handle closure,
                                           int number_of_arguments,
                                           Dart_Handle* arguments);

/**
 * Invokes a Generative Constructor on an object that was previously
 * allocated using Dart_Allocate/Dart_AllocateWithNativeFields.
 *
 * The 'target' parameter must be an object.
 *
 * This function ignores visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param target An object.
 * \param name The name of the constructor to invoke.
 * \param number_of_arguments Size of the arguments array.
 * \param arguments An array of arguments to the function.
 *
 * \return If the constructor is called and completes
 *   successfully, then the object is returned. If an error
 *   occurs during execution, then an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_InvokeConstructor(Dart_Handle object,
                                               Dart_Handle name,
                                               int number_of_arguments,
                                               Dart_Handle* arguments);

/**
 * Gets the value of a field.
 *
 * The 'container' parameter may be an object, type, or library.  If
 * 'container' is an object, then this function will access an
 * instance field.  If 'container' is a type, then this function will
 * access a static field.  If 'container' is a library, then this
 * function will access a top-level variable.
 * NOTE: This API call cannot be used to access fields of a type object.
 *
 * This function ignores field visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param container An object, type, or library.
 * \param name A field name.
 *
 * \return If no error occurs, then the value of the field is
 *   returned. Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetField(Dart_Handle container,
                                      Dart_Handle name);

/**
 * Sets the value of a field.
 *
 * The 'container' parameter may actually be an object, type, or
 * library.  If 'container' is an object, then this function will
 * access an instance field.  If 'container' is a type, then this
 * function will access a static field.  If 'container' is a library,
 * then this function will access a top-level variable.
 * NOTE: This API call cannot be used to access fields of a type object.
 *
 * This function ignores field visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param container An object, type, or library.
 * \param name A field name.
 * \param value The new field value.
 *
 * \return A valid handle if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_SetField(Dart_Handle container,
                                      Dart_Handle name,
                                      Dart_Handle value);


/*
 * ==========
 * Exceptions
 * ==========
 */

/*
 * TODO(turnidge): Remove these functions from the api and replace all
 * uses with Dart_NewUnhandledExceptionError. */

/**
 * Throws an exception.
 *
 * This function causes a Dart language exception to be thrown. This
 * will proceed in the standard way, walking up Dart frames until an
 * appropriate 'catch' block is found, executing 'finally' blocks,
 * etc.
 *
 * If successful, this function does not return. Note that this means
 * that the destructors of any stack-allocated C++ objects will not be
 * called. If there are no Dart frames on the stack, an error occurs.
 *
 * \return An error handle if the exception was not thrown.
 *   Otherwise the function does not return.
 */
DART_EXPORT Dart_Handle Dart_ThrowException(Dart_Handle exception);

/**
 * Rethrows an exception.
 *
 * Rethrows an exception, unwinding all dart frames on the stack. If
 * successful, this function does not return. Note that this means
 * that the destructors of any stack-allocated C++ objects will not be
 * called. If there are no Dart frames on the stack, an error occurs.
 *
 * \return An error handle if the exception was not thrown.
 *   Otherwise the function does not return.
 */
DART_EXPORT Dart_Handle Dart_RethrowException(Dart_Handle exception,
                                              Dart_Handle stacktrace);


/*
 * ===========================
 * Native fields and functions
 * ===========================
 */

/**
 * Creates a native wrapper class.
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle Dart_CreateNativeWrapperClass(Dart_Handle library,
                                                      Dart_Handle class_name,
                                                      int field_count);

/**
 * Gets the number of native instance fields in an object.
 */
DART_EXPORT Dart_Handle Dart_GetNativeInstanceFieldCount(Dart_Handle obj,
                                                         int* count);

/**
 * Gets the value of a native field.
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle Dart_GetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t* value);

/**
 * Sets the value of a native field.
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle Dart_SetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t value);

/**
 * The arguments to a native function.
 *
 * This object is passed to a native function to represent its
 * arguments and return value. It allows access to the arguments to a
 * native function by index. It also allows the return value of a
 * native function to be set.
 */
typedef struct _Dart_NativeArguments* Dart_NativeArguments;

/**
 * Extracts current isolate data from the native arguments structure.
 */
DART_EXPORT void* Dart_GetNativeIsolateData(Dart_NativeArguments args);

typedef enum {
  Dart_NativeArgument_kBool = 0,
  Dart_NativeArgument_kInt32,
  Dart_NativeArgument_kUint32,
  Dart_NativeArgument_kInt64,
  Dart_NativeArgument_kUint64,
  Dart_NativeArgument_kDouble,
  Dart_NativeArgument_kString,
  Dart_NativeArgument_kInstance,
  Dart_NativeArgument_kNativeFields,
} Dart_NativeArgument_Type;

typedef struct _Dart_NativeArgument_Descriptor {
  uint8_t type;
  uint8_t index;
} Dart_NativeArgument_Descriptor;

typedef union _Dart_NativeArgument_Value {
  bool as_bool;
  int32_t as_int32;
  uint32_t as_uint32;
  int64_t as_int64;
  uint64_t as_uint64;
  double as_double;
  struct {
    Dart_Handle dart_str;
    void* peer;
  } as_string;
  struct {
    intptr_t num_fields;
    intptr_t* values;
  } as_native_fields;
  Dart_Handle as_instance;
} Dart_NativeArgument_Value;

enum {
  kNativeArgNumberPos = 0,
  kNativeArgNumberSize = 8,
  kNativeArgTypePos = kNativeArgNumberPos + kNativeArgNumberSize,
  kNativeArgTypeSize = 8,
};

#define BITMASK(size) ((1 << size) - 1)
#define DART_NATIVE_ARG_DESCRIPTOR(type, position)                             \
  (((type & BITMASK(kNativeArgTypeSize)) << kNativeArgTypePos) |               \
    (position & BITMASK(kNativeArgNumberSize)))

/**
 * Gets the native arguments based on the types passed in and populates
 * the passed arguments buffer with appropriate native values.
 *
 * \param args the Native arguments block passed into the native call.
 * \param num_arguments length of argument descriptor array and argument
 *   values array passed in.
 * \param arg_descriptors an array that describes the arguments that
 *   need to be retrieved. For each argument to be retrieved the descriptor
 *   contains the argument number (0, 1 etc.) and the argument type
 *   described using Dart_NativeArgument_Type, e.g:
 *   DART_NATIVE_ARG_DESCRIPTOR(Dart_NativeArgument_kBool, 1) indicates
 *   that the first argument is to be retrieved and it should be a boolean.
 * \param arg_values array into which the native arguments need to be
 *   extracted into, the array is allocated by the caller (it could be
 *   stack allocated to avoid the malloc/free performance overhead).
 *
 * \return Success if all the arguments could be extracted correctly,
 *   returns an error handle if there were any errors while extracting the
 *   arguments (mismatched number of arguments, incorrect types, etc.).
 */
DART_EXPORT Dart_Handle Dart_GetNativeArguments(
    Dart_NativeArguments args,
    int num_arguments,
    const Dart_NativeArgument_Descriptor* arg_descriptors,
    Dart_NativeArgument_Value* arg_values);


/**
 * Gets the native argument at some index.
 */
DART_EXPORT Dart_Handle Dart_GetNativeArgument(Dart_NativeArguments args,
                                               int index);
/* TODO(turnidge): Specify the behavior of an out-of-bounds access. */

/**
 * Gets the number of native arguments.
 */
DART_EXPORT int Dart_GetNativeArgumentCount(Dart_NativeArguments args);

/**
 * Gets all the native fields of the native argument at some index.
 * \param args Native arguments structure.
 * \param arg_index Index of the desired argument in the structure above.
 * \param num_fields size of the intptr_t array 'field_values' passed in.
 * \param field_values intptr_t array in which native field values are returned.
 * \return Success if the native fields where copied in successfully. Otherwise
 *   returns an error handle. On success the native field values are copied
 *   into the 'field_values' array, if the argument at 'arg_index' is a
 *   null object then 0 is copied as the native field values into the
 *   'field_values' array.
 */
DART_EXPORT Dart_Handle Dart_GetNativeFieldsOfArgument(
    Dart_NativeArguments args,
    int arg_index,
    int num_fields,
    intptr_t* field_values);

/**
 * Gets the native field of the receiver.
 */
DART_EXPORT Dart_Handle Dart_GetNativeReceiver(Dart_NativeArguments args,
                                               intptr_t* value);

/**
 * Gets a string native argument at some index.
 * \param args Native arguments structure.
 * \param arg_index Index of the desired argument in the structure above.
 * \param peer Returns the peer pointer if the string argument has one.
 * \return Success if the string argument has a peer, if it does not
 *   have a peer then the String object is returned. Otherwise returns
 *   an error handle (argument is not a String object).
 */
DART_EXPORT Dart_Handle Dart_GetNativeStringArgument(Dart_NativeArguments args,
                                                     int arg_index,
                                                     void** peer);

/**
 * Gets an integer native argument at some index.
 * \param args Native arguments structure.
 * \param arg_index Index of the desired argument in the structure above.
 * \param value Returns the integer value if the argument is an Integer.
 * \return Success if no error occurs. Otherwise returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_GetNativeIntegerArgument(Dart_NativeArguments args,
                                                      int index,
                                                      int64_t* value);

/**
 * Gets a boolean native argument at some index.
 * \param args Native arguments structure.
 * \param arg_index Index of the desired argument in the structure above.
 * \param value Returns the boolean value if the argument is a Boolean.
 * \return Success if no error occurs. Otherwise returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_GetNativeBooleanArgument(Dart_NativeArguments args,
                                                      int index,
                                                      bool* value);

/**
 * Gets a double native argument at some index.
 * \param args Native arguments structure.
 * \param arg_index Index of the desired argument in the structure above.
 * \param value Returns the double value if the argument is a double.
 * \return Success if no error occurs. Otherwise returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_GetNativeDoubleArgument(Dart_NativeArguments args,
                                                     int index,
                                                     double* value);

/**
 * Sets the return value for a native function.
 */
DART_EXPORT void Dart_SetReturnValue(Dart_NativeArguments args,
                                     Dart_Handle retval);

DART_EXPORT void Dart_SetWeakHandleReturnValue(Dart_NativeArguments args,
                                               Dart_WeakPersistentHandle rval);

DART_EXPORT void Dart_SetBooleanReturnValue(Dart_NativeArguments args,
                                            bool retval);

DART_EXPORT void Dart_SetIntegerReturnValue(Dart_NativeArguments args,
                                            int64_t retval);

DART_EXPORT void Dart_SetDoubleReturnValue(Dart_NativeArguments args,
                                           double retval);

/**
 * A native function.
 */
typedef void (*Dart_NativeFunction)(Dart_NativeArguments arguments);

/**
 * Native entry resolution callback.
 *
 * For libraries and scripts which have native functions, the embedder
 * can provide a native entry resolver. This callback is used to map a
 * name/arity to a Dart_NativeFunction. If no function is found, the
 * callback should return NULL.
 *
 * The parameters to the native resolver function are:
 * \param name a Dart string which is the name of the native function.
 * \param num_of_arguments is the number of arguments expected by the
 *   native function.
 * \param auto_setup_scope is a boolean flag that can be set by the resolver
 *   to indicate if this function needs a Dart API scope (see Dart_EnterScope/
 *   Dart_ExitScope) to be setup automatically by the VM before calling into
 *   the native function. By default most native functions would require this
 *   to be true but some light weight native functions which do not call back
 *   into the VM through the Dart API may not require a Dart scope to be
 *   setup automatically.
 *
 * \return A valid Dart_NativeFunction which resolves to a native entry point
 *   for the native function.
 *
 * See Dart_SetNativeResolver.
 */
typedef Dart_NativeFunction (*Dart_NativeEntryResolver)(Dart_Handle name,
                                                        int num_of_arguments,
                                                        bool* auto_setup_scope);
/* TODO(turnidge): Consider renaming to NativeFunctionResolver or
 * NativeResolver. */

/**
 * Native entry symbol lookup callback.
 *
 * For libraries and scripts which have native functions, the embedder
 * can provide a callback for mapping a native entry to a symbol. This callback
 * maps a native function entry PC to the native function name. If no native
 * entry symbol can be found, the callback should return NULL.
 *
 * The parameters to the native reverse resolver function are:
 * \param nf A Dart_NativeFunction.
 *
 * \return A const UTF-8 string containing the symbol name or NULL.
 *
 * See Dart_SetNativeResolver.
 */
typedef const uint8_t* (*Dart_NativeEntrySymbol)(Dart_NativeFunction nf);


/*
 * ===========
 * Environment
 * ===========
 */

/**
 * An environment lookup callback function.
 *
 * \param name The name of the value to lookup in the environment.
 *
 * \return A valid handle to a string if the name exists in the
 * current environment or Dart_Null() if not.
 */
typedef Dart_Handle (*Dart_EnvironmentCallback)(Dart_Handle name);

/**
 * Sets the environment callback for the current isolate. This
 * callback is used to lookup environment values by name in the
 * current environment. This enables the embedder to supply values for
 * the const constructors bool.fromEnvironment, int.fromEnvironment
 * and String.fromEnvironment.
 */
DART_EXPORT Dart_Handle Dart_SetEnvironmentCallback(
    Dart_EnvironmentCallback callback);

/**
 * Sets the callback used to resolve native functions for a library.
 *
 * \param library A library.
 * \param resolver A native entry resolver.
 *
 * \return A valid handle if the native resolver was set successfully.
 */
DART_EXPORT Dart_Handle Dart_SetNativeResolver(
    Dart_Handle library,
    Dart_NativeEntryResolver resolver,
    Dart_NativeEntrySymbol symbol);
/* TODO(turnidge): Rename to Dart_LibrarySetNativeResolver? */


/*
 * =====================
 * Scripts and Libraries
 * =====================
 */
/* TODO(turnidge): Finish documenting this section. */

typedef enum {
  Dart_kImportTag = 0,
  Dart_kSourceTag,
  Dart_kCanonicalizeUrl
} Dart_LibraryTag;

/* TODO(turnidge): Document. */
typedef Dart_Handle (*Dart_LibraryTagHandler)(Dart_LibraryTag tag,
                                              Dart_Handle library,
                                              Dart_Handle url);

/**
 * Sets library tag handler for the current isolate. This handler is
 * used to handle the various tags encountered while loading libraries
 * or scripts in the isolate.
 *
 * \param handler Handler code to be used for handling the various tags
 *   encountered while loading libraries or scripts in the isolate.
 *
 * \return If no error occurs, the handler is set for the isolate.
 *   Otherwise an error handle is returned.
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle Dart_SetLibraryTagHandler(
    Dart_LibraryTagHandler handler);

/**
 * Loads the root script for the current isolate. The script can be
 * embedded in another file, for example in an html file.
 *
 * TODO(turnidge): Document.
 *
 * \line_offset is the number of text lines before the
 *   first line of the Dart script in the containing file.
 *
 * \col_offset is the number of characters before the first character
 *   in the first line of the Dart script.
 */
DART_EXPORT Dart_Handle Dart_LoadScript(Dart_Handle url,
                                        Dart_Handle source,
                                        intptr_t line_offset,
                                        intptr_t col_offset);

/**
 * Loads the root script for current isolate from a snapshot.
 *
 * \param buffer A buffer which contains a snapshot of the script.
 * \param length Length of the passed in buffer.
 *
 * \return If no error occurs, the Library object corresponding to the root
 *   script is returned. Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_LoadScriptFromSnapshot(const uint8_t* buffer,
                                                    intptr_t buffer_len);

/**
 * Gets the library for the root script for the current isolate.
 *
 * If the root script has not yet been set for the current isolate,
 * this function returns Dart_Null().  This function never returns an
 * error handle.
 *
 * \return Returns the root Library for the current isolate or Dart_Null().
 */
DART_EXPORT Dart_Handle Dart_RootLibrary();

/**
 * Lookup or instantiate a type by name and type arguments from a Library.
 *
 * \param library The library containing the class or interface.
 * \param class_name The class name for the type.
 * \param number_of_type_arguments Number of type arguments.
 *   For non parametric types the number of type arguments would be 0.
 * \param type_arguments Pointer to an array of type arguments.
 *   For non parameteric types a NULL would be passed in for this argument.
 *
 * \return If no error occurs, the type is returned.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetType(Dart_Handle library,
                                     Dart_Handle class_name,
                                     intptr_t number_of_type_arguments,
                                     Dart_Handle* type_arguments);

/**
 * Lookup a class or interface by name from a Library.
 *
 * \param library The library containing the class or interface.
 * \param class_name The name of the class or interface.
 *
 * \return If no error occurs, the class or interface is
 *   returned. Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetClass(Dart_Handle library,
                                      Dart_Handle class_name);
/* TODO(asiva): The above method needs to be removed once all uses
 * of it are removed from the embedder code. */

/**
 * Returns the url from which a library was loaded.
 */
DART_EXPORT Dart_Handle Dart_LibraryUrl(Dart_Handle library);

DART_EXPORT Dart_Handle Dart_LookupLibrary(Dart_Handle url);
/* TODO(turnidge): Consider returning Dart_Null() when the library is
 * not found to distinguish that from a true error case. */

DART_EXPORT Dart_Handle Dart_LoadLibrary(Dart_Handle url,
                                         Dart_Handle source);

/**
 * Imports a library into another library, optionally with a prefix.
 * If no prefix is required, an empty string or Dart_Null() can be
 * supplied.
 *
 * \param library The library into which to import another library.
 * \param import The library to import.
 * \param prefix The prefix under which to import.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_LibraryImportLibrary(Dart_Handle library,
                                                  Dart_Handle import,
                                                  Dart_Handle prefix);

/**
 * Loads a source string into a library.
 *
 * \param library A library
 * \param url A url identifying the origin of the source
 * \param source A string of Dart source
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_LoadSource(Dart_Handle library,
                                        Dart_Handle url,
                                        Dart_Handle source);
/* TODO(turnidge): Rename to Dart_LibraryLoadSource? */


/**
 * Loads a patch source string into a library.
 *
 * \param library A library
 * \param url A url identifying the origin of the patch source
 * \param source A string of Dart patch source
 */
DART_EXPORT Dart_Handle Dart_LibraryLoadPatch(Dart_Handle library,
                                              Dart_Handle url,
                                              Dart_Handle patch_source);


/**
 * Indicates that all outstanding load requests have been satisfied,
 * finalizing classes and completing deferred library futures.
 *
 * Requires there to be a current isolate.
 *
 * \return Success if all deferred library futures are completed.
 *   Otherwise, returns an error.
 */
DART_EXPORT Dart_Handle Dart_FinalizeLoading();


/*
 * =====
 * Peers
 * =====
 */

/**
 * The peer field is a lazily allocated field intendend for storage of
 * an uncommonly used values.  Most instances types can have a peer
 * field allocated.  The exceptions are subtypes of Null, num, and
 * bool.
 */

/**
 * Returns the value of peer field of 'object' in 'peer'.
 *
 * \param object An object.
 * \param peer An out parameter that returns the value of the peer
 *   field.
 *
 * \return Returns an error if 'object' is a subtype of Null, num, or
 *   bool.
 */
DART_EXPORT Dart_Handle Dart_GetPeer(Dart_Handle object, void** peer);

/**
 * Sets the value of the peer field of 'object' to the value of
 * 'peer'.
 *
 * \param object An object.
 * \param peer A value to store in the peer field.
 *
 * \return Returns an error if 'object' is a subtype of Null, num, or
 *   bool.
 */
DART_EXPORT Dart_Handle Dart_SetPeer(Dart_Handle object, void* peer);


/*
 * =======
 * Service
 * =======
 */

/**
 * Returns the Service isolate initialized and with the dart:vmservice library
 * loaded and booted.
 *
 * This will call the embedder provided Dart_ServiceIsolateCreateCalback to
 * create the isolate.
 *
 * After obtaining the service isolate the embedder specific glue code can
 * be loaded in and the isolate can be run by the embedder.
 *
 * NOTE: It is not safe to call this from multiple threads concurrently.
 *
 * \return Returns NULL if an error occurred.
 */
DART_EXPORT Dart_Isolate Dart_GetServiceIsolate(void* callback_data);


/**
 * Returns true if the service is enabled. False otherwise.
 *
 *  \return Returns true if service is running.
 */
DART_EXPORT bool Dart_IsServiceRunning();


/**
 * A service request callback function.
 *
 * These callbacks, registered by the embedder, are called when the VM receives
 * a service request it can't handle and the service request command name
 * matches one of the embedder registered handlers.
 *
 * \param name The service request command name. Always the first entry
 *   in the arguments array. Will match the name the callback was
 *   registered with.
 * \param arguments The service request command arguments. Incoming service
 *   request paths are split like file system paths and flattened into an array
 *   (e.g. /foo/bar becomes the array ["foo", "bar"].
 * \param num_arguments The length of the arguments array.
 * \param option_keys Service requests can have options key-value pairs. The
 *   keys and values are flattened and stored in arrays.
 * \param option_values The values associated with the keys.
 * \param num_options The length of the option_keys and option_values array.
 * \param user_data The user_data pointer registered with this handler.
 *
 * \return Returns a C string containing a valid JSON object. The returned
 * pointer will be freed by the VM by calling free.
 */
typedef const char* (*Dart_ServiceRequestCallback)(
    const char* name,
    const char** arguments,
    intptr_t num_arguments,
    const char** option_keys,
    const char** option_values,
    intptr_t num_options,
    void* user_data);

/**
 * Register a Dart_ServiceRequestCallback to be called to handle requests
 * with name on a specific isolate. The callback will be invoked with the
 * current isolate set to the request target.
 *
 * \param name The name of the command that this callback is responsible for.
 * \param callback The callback to invoke.
 * \param user_data The user data passed to the callback.
 *
 * NOTE: If multiple callbacks with the same name are registered, only the
 * last callback registered will be remembered.
 */
DART_EXPORT void Dart_RegisterIsolateServiceRequestCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data);

/**
 * Register a Dart_ServiceRequestCallback to be called to handle requests
 * with name. The callback will be invoked without a current isolate.
 *
 * \param name The name of the command that this callback is responsible for.
 * \param callback The callback to invoke.
 * \param user_data The user data passed to the callback.
 *
 * NOTE: If multiple callbacks with the same name are registered, only the
 * last callback registered will be remembered.
 */
DART_EXPORT void Dart_RegisterRootServiceRequestCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data);


#endif  /* INCLUDE_DART_API_H_ */  /* NOLINT */
