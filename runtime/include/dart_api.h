// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

// --- Handles ---

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
 * When a function encounters a problem that prevents it from
 * completing normally, it returns an error handle (See Dart_IsError).
 * An error handle has an associated error message that gives more
 * details about the problem (See Dart_GetError).
 *
 * When an unhandled exception occurs, it is returned as an error
 * handle that has additional information about the exception (See
 * Dart_ErrorHasException). This error handle retains information
 * about the exception and the stack trace (See
 * Dart_ErrorGetException, Dart_ErrorGetStacktrace,
 * Dart_RethrowException).
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
 */
typedef struct _Dart_Handle* Dart_Handle;

typedef void (*Dart_WeakPersistentHandleFinalizer)(Dart_Handle handle,
                                                   void* peer);
typedef void (*Dart_PeerFinalizer)(void* peer);

/**
 * Is this an error handle?
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsError(Dart_Handle handle);

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
 * Produces an error handle with the provided error message.
 *
 * Requires there to be a current isolate.
 *
 * \param error A C string containing an error message.
 */
DART_EXPORT Dart_Handle Dart_Error(const char* format, ...);

/**
 * Propagates an error.
 *
 * It only makes sense to call this function when there are dart
 * frames on the stack.  That is, this function should only be called
 * in the C implementation of a native function which has been called
 * from Dart code.  If this function is called in the top-level
 * embedder code, it will return an error, as there is no way to
 * further propagate the error.
 *
 * The provided handle must be an error handle.  (See Dart_IsError.)
 *
 * If the provided handle is an unhandled exception, this function
 * will cause the unhandled exception to be rethrown.  Otherwise, the
 * error will be propagated to the caller, discarding any active dart
 * frames up to the next C frame.
 *
 * \param An error handle.
 *
 * \return On success, this function does not return.  On failure, an
 *   error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_PropagateError(Dart_Handle handle);

// Internal routine used for reporting error handles.
DART_EXPORT void _Dart_ReportErrorHandle(const char* file,
                                         int line,
                                         const char* handle_string,
                                         const char* error);

// TODO(turnidge): Move DART_CHECK_VALID to some sort of dart_utils
// header instead of this header.
/**
 * Aborts the process if 'handle' is an error handle.
 *
 * Provided for convenience.
 */
#define DART_CHECK_VALID(handle)                                        \
  if (Dart_IsError((handle))) {                                         \
    _Dart_ReportErrorHandle(__FILE__, __LINE__,                       \
                              #handle, Dart_GetError(handle));          \
  }


/**
 * Converts an object to a string.
 *
 * May generate an unhandled exception error.
 *
 * \return A handle to the converted string if no error occurs during
 *   the conversion. If an error does occur, an error handle is
 *   returned.
 */
DART_EXPORT Dart_Handle Dart_ToString(Dart_Handle object);

/**
 * Checks to see if two handles refer to identically equal objects.
 *
 * This is equivalent to using the triple-equals (===) operator.
 *
 * \param obj1 An object to be compared.
 * \param obj2 An object to be compared.
 *
 * \return True if the objects are identically equal.  False otherwise.
 */
DART_EXPORT bool Dart_IdentityEquals(Dart_Handle obj1, Dart_Handle obj2);

/**
 * Allocates a persistent handle for an object.
 *
 * This handle has the lifetime of the current isolate unless it is
 * explicitly deallocated by calling Dart_DeletePersistentHandle.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_Handle Dart_NewPersistentHandle(Dart_Handle object);

/**
 * Deallocates a persistent handle.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_DeletePersistentHandle(Dart_Handle object);

/**
 * Allocates a weak persistent handle for an object.
 *
 * This handle has the lifetime of the current isolate unless it is
 * explicitly deallocated by calling Dart_DeletePersistentHandle.
 *
 * Requires there to be a current isolate.
 *
 * \param object An object.
 * \param peer A pointer to a native object or NULL.  This value is
 *   provided to callback when it is invoked.
 * \param callback A function pointer that will be invoked sometime
 *   after the object is garbage collected.
 *
 * \return Success if the weak persistent handle was
 *   created. Otherwise, returns an error.
 */
DART_EXPORT Dart_Handle Dart_NewWeakPersistentHandle(
    Dart_Handle object,
    void* peer,
    Dart_WeakPersistentHandleFinalizer callback);

/**
 * Is this object a weak persistent handle?
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsWeakPersistentHandle(Dart_Handle object);

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
 * This handle has the lifetime of the current isolate unless it is
 * explicitly deallocated by calling Dart_DeletePersistentHandle.
 *
 * Requires there to be a current isolate.
 *
 * \param object An object.
 * \param peer A pointer to a native object or NULL.  This value is
 *   provided to callback when it is invoked.
 * \param callback A function pointer that will be invoked sometime
 *   after the object is garbage collected.
 *
 * \return Success if the prologue weak persistent handle was created.
 *   Otherwise, returns an error.
 */
DART_EXPORT Dart_Handle Dart_NewPrologueWeakPersistentHandle(
    Dart_Handle object,
    void* peer,
    Dart_WeakPersistentHandleFinalizer callback);

/**
 * Is this object a prologue weak persistent handle?
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsPrologueWeakPersistentHandle(Dart_Handle object);

/**
 * Constructs a set of weak references from the Cartesian product of
 * the objects in the key set and the objects in values set.
 *
 * \param keys A set of object references.  These references will be
 *   considered weak by the garbage collector.
 * \param num_keys the number of objects in the keys set.
 * \param values A set of object references.  These references will be
 *   considered weak by garbage collector unless any object reference
 *   in 'keys' is found to be strong.
 * \param num_values the size of the values set
 *
 * \return Success if the weak reference set could be created.
 *   Otherwise, returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewWeakReferenceSet(Dart_Handle* keys,
                                                 intptr_t num_keys,
                                                 Dart_Handle* values,
                                                 intptr_t num_values);

// --- Garbage Collection Callbacks --

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
 * Adds a garbage collection prologue callback.
 *
 * \param callback A function pointer to a prologue callback function.
 *   This function must not have been previously added as a prologue
 *   callback.
 *
 * \return Success if the callback was added.  Otherwise, returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_AddGcPrologueCallback(
    Dart_GcPrologueCallback callback);

/**
 * Removes a garbage collection prologue callback.
 *
 * \param callback A function pointer to a prologue callback function.
 *   This function must have been added as a prologue callback.
 *
 * \return Success if the callback was removed.  Otherwise, returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_RemoveGcPrologueCallback(
    Dart_GcPrologueCallback callback);

/**
 * Adds a garbage collection epilogue callback.
 *
 * \param callback A function pointer to an epilogue callback
 *   function.  This function must not have been previously added as
 *   an epilogue callback.
 *
 * \return Success if the callback was added.  Otherwise, returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_AddGcEpilogueCallback(
    Dart_GcEpilogueCallback callback);

/**
 * Removes a garbage collection epilogue callback.
 *
 * \param callback A function pointer to an epilogue callback
 *   function.  This function must have been added as an epilogue
 *   callback.
 *
 * \return Success if the callback was removed.  Otherwise, returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_RemoveGcEpilogueCallback(
    Dart_GcEpilogueCallback callback);

// --- Initialization and Globals ---

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
 * \param script_uri The uri of the script to load.  This uri has been
 *   canonicalized by the library tag handler from the parent isolate.
 *   The callback is responsible for loading this script by a call to
 *   Dart_LoadScript or Dart_LoadScriptFromSnapshot.
 * \param main The name of the main entry point this isolate will
 *   eventually run.  This is provided for advisory purposes only to
 *   improve debugging messages.  The main function is not invoked by
 *   this function.
 * \param callback_data The callback data which was passed to the
 *   parent isolate when it was created by calling Dart_CreateIsolate().
 * \param error A structure into which the embedder can place a
 *   C string containing an error message in the case of failures.
 *
 * \return The embedder returns false if the creation and
 *   initialization was not successful and true if successful.
 */
typedef bool (*Dart_IsolateCreateCallback)(const char* script_uri,
                                           const char* main,
                                           void* callback_data,
                                           char** error);

/**
 * An isolate interrupt callback function.
 *
 * This callback, provided by the embedder, is called when an isolate
 * is interrupted as a result of a call to Dart_InterruptIsolate().
 * When the callback is called, Dart_CurrentIsolate can be used to
 * figure out which isolate is being interrupted.
 *
 * \param current_isolate The isolate being interrupted.
 *
 * \return The embedder returns true if the isolate should continue
 *   execution. If the embedder returns false, the isolate will be
 *   unwound (currently unimplemented).
 */
typedef bool (*Dart_IsolateInterruptCallback)();
// TODO(turnidge): Define and implement unwinding.

/**
 * Initializes the VM.
 *
 * \param create A function to be called during isolate creation.
 *   See Dart_IsolateCreateCallback.
 * \param interrupt A function to be called when an isolate is interrupted.
 *   See Dart_IsolateInterruptCallback.
 *
 * \return True if initialization is successful.
 */
DART_EXPORT bool Dart_Initialize(Dart_IsolateCreateCallback create,
                                 Dart_IsolateInterruptCallback interrupt);

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

// --- Isolates ---

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
// TODO(turnidge): Document behavior when there is already a current
// isolate.

/**
 * Shuts down the current isolate. After this call, the current
 * isolate is NULL.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_ShutdownIsolate();
// TODO(turnidge): Document behavior when there is no current isolate.

/**
 * Returns the current isolate. Will return NULL if there is no
 * current isolate.
 */
DART_EXPORT Dart_Isolate Dart_CurrentIsolate();

/**
 * Enters an isolate. After calling this function,
 * the current isolate will be set to the provided isolate.
 *
 * Requires there to be no current isolate.
 */
DART_EXPORT void Dart_EnterIsolate(Dart_Isolate isolate);
// TODO(turnidge): Describe what happens if two threads attempt to
// enter the same isolate simultaneously. Check for this in the code.
// Describe whether isolates are allowed to migrate.

/**
 * Exits an isolate. After this call, Dart_CurrentIsolate will
 * return NULL.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_ExitIsolate();
// TODO(turnidge): We don't want users of the api to be able to exit a
// "pure" dart isolate. Implement and document.

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

// --- Messages and Ports ---

/**
 * A port is used to send or receive inter-isolate messages
 */
typedef int64_t Dart_Port;

/**
 * kIllegalPort is a port number guaranteed never to be associated
 * with a valid port.
 */
const Dart_Port kIllegalPort = 0;

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
// TODO(turnidge): Consider moving this to isolate creation so that it
// is impossible to mess up.

/**
 * Handles the next pending message for the current isolate.
 *
 * May generate an unhandled exception error.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_HandleMessage();

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
// TODO(turnidge): Should this be removed from the public api?

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

// --- Message sending/receiving from native code ----

/**
 * A Dart_CObject is used for representing Dart objects as native C
 * data outside the Dart heap. These objects are totally detached from
 * the Dart heap. Only a subset of the Dart objects have a
 * representation as a Dart_CObject.
 */
typedef struct _Dart_CObject {
  enum Type {
    kNull = 0,
    kBool,
    kInt32,
    kInt64,
    kBigint,
    kDouble,
    kString,
    kArray,
    kUint8Array,
    kUnsupported,
    kNumberOfTypes
  } type;
  union {
    bool as_bool;
    int32_t as_int32;
    int64_t as_int64;
    double as_double;
    char* as_string;
    char* as_bigint;
    struct {
      int length;
      struct _Dart_CObject** values;
    } as_array;
    struct {
      int length;
      uint8_t* values;
    } as_byte_array;
  } value;
} Dart_CObject;

/**
 * Posts a message on some port. The message will contain the
 * Dart_CObject object graph rooted in 'message'.
 *
 * While the message is being sent the state of the graph of
 * Dart_CObject structures rooted in 'message' should not be accessed,
 * as the message generation will make temporary modifications to the
 * data. When the message has been sent the graph will be fully
 * restored.
 *
 * \param port_id The destination port.
 * \param message The message to send.
 *
 * \return True if the message was posted.
 */
DART_EXPORT bool Dart_PostCObject(Dart_Port port_id, Dart_CObject* message);

/**
 * A native message handler.
 *
 * This handler is associated with a native port by calling
 * Dart_NewNativePort.
 *
 * The message received is decoded into the message structure. The
 * lifetime of the message data is controlled by the caller. All the
 * data references from the message are allocated by the caller and
 * will be reclaimed when returning to it.
 */

typedef void (*Dart_NativeMessageHandler)(Dart_Port dest_port_id,
                                          Dart_Port reply_port_id,
                                          Dart_CObject* message);

/**
 * Creates a new native port.  When messages are received on this
 * native port, then they will be dispatched to the provided native
 * message handler.
 *
 * \param name The name of this port in debugging messages.
 * \param handler The C handler to run when messages arrive on the port.
 * \param handle_concurrently Is it okay to process requests on this
 *                            native port concurrently?
 *
 * \return If successful, returns the port id for the native port.  In
 *   case of error, returns kIllegalPort.
 */
DART_EXPORT Dart_Port Dart_NewNativePort(const char* name,
                                         Dart_NativeMessageHandler handler,
                                         bool handle_concurrently);
// TODO(turnidge): Currently handle_concurrently is ignored.

/**
 * Closes the native port with the given id.
 *
 * The port must have been allocated by a call to Dart_NewNativePort.
 *
 * \param native_port_id The id of the native port to close.
 *
 * \return Returns true if the port was closed successfully.
 */
DART_EXPORT bool Dart_CloseNativePort(Dart_Port native_port_id);

/**
 * Returns a new SendPort with the provided port id.
 */
DART_EXPORT Dart_Handle Dart_NewSendPort(Dart_Port port_id);

/**
 * Gets the ReceivePort for the provided port id, creating it if necessary.
 *
 * Note that there is at most one ReceivePort for a given port id.
 */
DART_EXPORT Dart_Handle Dart_GetReceivePort(Dart_Port port_id);

// --- Scopes ----

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

// --- Objects ----

/**
 * Returns the null object.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the null object.
 */
DART_EXPORT Dart_Handle Dart_Null();

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
 * The result of the test is returned through the 'instanceif' parameter.
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

// --- Numbers ----

/**
 * Is this object a Number?
 */
DART_EXPORT bool Dart_IsNumber(Dart_Handle object);

// --- Integers ----

/**
 * Is this object an Integer?
 */
DART_EXPORT bool Dart_IsInteger(Dart_Handle object);

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

// --- Booleans ----

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
 * Is this object a Boolean?
 */
DART_EXPORT bool Dart_IsBoolean(Dart_Handle object);

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

// --- Doubles ---

/**
 * Is this object a Double?
 */
DART_EXPORT bool Dart_IsDouble(Dart_Handle object);

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

// --- Strings ---

/**
 * Is this object a String?
 */
DART_EXPORT bool Dart_IsString(Dart_Handle object);

/**
 * Is this object a String whose codepoints all fit into 8 bits?
 */
DART_EXPORT bool Dart_IsString8(Dart_Handle object);

/**
 * Is this object a String whose codepoints all fit into 16 bits?
 */
DART_EXPORT bool Dart_IsString16(Dart_Handle object);

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
 *
 * \param value A C String
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewString(const char* str);

/**
 * Returns a String built from an array of 8-bit codepoints.
 *
 * \param value An array of 8-bit codepoints.
 * \param length The length of the codepoints array.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewString8(const uint8_t* codepoints,
                                        intptr_t length);

/**
 * Returns a String built from an array of 16-bit codepoints.
 *
 * \param value An array of 16-bit codepoints.
 * \param length The length of the codepoints array.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewString16(const uint16_t* codepoints,
                                         intptr_t length);

/**
 * Returns a String built from an array of 32-bit codepoints.
 *
 * \param value An array of 32-bit codepoints.
 * \param length The length of the codepoints array.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewString32(const uint32_t* codepoints,
                                         intptr_t length);

/**
 * Is this object an external String?
 *
 * An external String is a String which references a fixed array of
 * codepoints which is external to the Dart heap.
 */
DART_EXPORT bool Dart_IsExternalString(Dart_Handle object);

/**
 * Retrieves the peer pointer associated with an external String.
 */
DART_EXPORT Dart_Handle Dart_ExternalStringGetPeer(Dart_Handle object,
                                                   void** peer);


/**
 * Returns a String which references an external array of 8-bit codepoints.
 *
 * \param value An array of 8-bit codepoints. This array must not move.
 * \param length The length of the codepoints array.
 * \param peer An external pointer to associate with this string.
 * \param callback A callback to be called when this string is finalized.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewExternalString8(const uint8_t* codepoints,
                                                intptr_t length,
                                                void* peer,
                                                Dart_PeerFinalizer callback);

/**
 * Returns a String which references an external array of 16-bit codepoints.
 *
 * \param value An array of 16-bit codepoints. This array must not move.
 * \param length The length of the codepoints array.
 * \param peer An external pointer to associate with this string.
 * \param callback A callback to be called when this string is finalized.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewExternalString16(const uint16_t* codepoints,
                                                 intptr_t length,
                                                 void* peer,
                                                 Dart_PeerFinalizer callback);

/**
 * Returns a String which references an external array of 32-bit codepoints.
 *
 * \param value An array of 32-bit codepoints. This array must not move.
 * \param length The length of the codepoints array.
 * \param peer An external pointer to associate with this string.
 * \param callback A callback to be called when this string is finalized.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewExternalString32(const uint32_t* codepoints,
                                                 intptr_t length,
                                                 void* peer,
                                                 Dart_PeerFinalizer callback);

/**
 * Gets the codepoints from a String.
 *
 * This function is only valid on strings for which Dart_IsString8 is
 * true. Otherwise an error occurs.
 *
 * \param str A string.
 * \param codepoints An array allocated by the caller, used to return
 *   the array of codepoints.
 * \param length Used to pass in the length of the provided array.
 *   Used to return the length of the array which was actually used.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringGet8(Dart_Handle str,
                                        uint8_t* codepoints,
                                        intptr_t* length);
// TODO(turnidge): Rename to GetString8 to be consistent with the Is*
// and New* functions above?

/**
 * Gets the codepoints from a String.
 *
 * This function is only valid on strings for which Dart_IsString8 or
 * Dart_IsString16 is true. Otherwise an error occurs.
 *
 * \param str A string.
 * \param codepoints An array allocated by the caller, used to return
 *   the array of codepoints.
 * \param length Used to pass in the length of the provided array.
 *   Used to return the length of the array which was actually used.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringGet16(Dart_Handle str,
                                         uint16_t* codepoints,
                                         intptr_t* length);

/**
 * Gets the codepoints from a String
 *
 * \param str A string.
 * \param codepoints An array allocated by the caller, used to return
 *   the array of codepoints.
 * \param length Used to pass in the length of the provided array.
 *   Used to return the length of the array which was actually used.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringGet32(Dart_Handle str,
                                         uint32_t* codepoints,
                                         intptr_t* length);

/**
 * Gets the utf8 encoded representation of a String.
 *
 * \param str A string.
 * \param utf8 Returns the String represented as a utf8 encoded C
 *   string. This C string is scope allocated and is only valid until
 *   the next call to Dart_ExitScope.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringToCString(Dart_Handle str,
                                             const char** utf8);

/**
 * Gets a UTF-8 encoded representation of a String.
 *
 * \param str A string.
 * \param bytes Returns the String represented as an array of UTF-8
 *   code units. This array is scope allocated and is only valid until
 *   the next call to Dart_ExitScope.
 * \param length Returns the length of the code units array, in bytes.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringToBytes(Dart_Handle str,
                                           const uint8_t** bytes,
                                           intptr_t* length);

// --- Lists ---

/**
 * Is this object a List?
 */
DART_EXPORT bool Dart_IsList(Dart_Handle object);

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
 * \return The Object in the List at the specified index if no errors
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

// --- Byte Arrays ---

/**
 * Is this object a ByteArray?
 */
DART_EXPORT bool Dart_IsByteArray(Dart_Handle object);

/**
 * Returns a ByteArray of the desired length.
 *
 * \param length The length of the array.
 *
 * \return The ByteArray object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewByteArray(intptr_t length);

/**
 * Returns a ByteArray which references an external array of 8-bit bytes.
 *
 * \param value An array of 8-bit bytes. This array must not move.
 * \param length The length of the array.
 * \param peer An external pointer to associate with this byte array.
 *
 * \return The ByteArray object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewExternalByteArray(uint8_t* data,
                                                  intptr_t length,
                                                  void* peer,
                                                  Dart_PeerFinalizer callback);

/**
 * Retrieves the peer pointer associated with an external ByteArray.
 */
DART_EXPORT Dart_Handle Dart_ExternalByteArrayGetPeer(Dart_Handle object,
                                                      void** peer);

/**
 * Gets an int8_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the List.
 * \param value Returns the value of the int8_t.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArrayGetInt8At(Dart_Handle array,
                                                intptr_t offset,
                                                int8_t* value);

/**
 * Sets an int8_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the ByteArray.
 * \param value The int8_t to put into the ByteArray.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArraySetInt8At(Dart_Handle array,
                                                intptr_t offset,
                                                int8_t value);

/**
 * Gets a uint8_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the List.
 * \param value Returns the value of the uint8_t.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArrayGetUint8At(Dart_Handle array,
                                                 intptr_t offset,
                                                 uint8_t* value);

/**
 * Sets a uint8_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the ByteArray.
 * \param value The uint8_t to put into the ByteArray.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArraySetUint8At(Dart_Handle array,
                                                 intptr_t offset,
                                                 uint8_t value);

/**
 * Gets an int16_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the List.
 * \param value Returns the value of the int16_t.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArrayGetInt16At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int16_t* value);

/**
 * Sets an int16_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the ByteArray.
 * \param value The int16_t to put into the ByteArray.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArraySetInt16At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int16_t value);

/**
 * Gets a uint16_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the List.
 * \param value Returns the value of the uint16_t.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArrayGetUint16At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint16_t* value);

/**
 * Sets a uint16_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the ByteArray.
 * \param value The uint16_t to put into the ByteArray.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArraySetUint16At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint16_t value);

/**
 * Gets an int32_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the List.
 * \param value Returns the value of the int32_t.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArrayGetInt32At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int32_t* value);

/**
 * Sets an int32_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the ByteArray.
 * \param value The int32_t to put into the ByteArray.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArraySetInt32At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int32_t value);

/**
 * Gets a uint32_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the List.
 * \param value Returns the value of the uint32_t.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArrayGetUint32At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint32_t* value);

/**
 * Sets a uint32_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the ByteArray.
 * \param value The uint32_t to put into the ByteArray.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArraySetUint32At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint32_t value);

/**
 * Gets an int64_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the List.
 * \param value Returns the value of the int64_t.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArrayGetInt64At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int64_t* value);

/**
 * Sets an int64_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the ByteArray.
 * \param value The int64_t to put into the ByteArray.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArraySetInt64At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int64_t value);

/**
 * Gets a uint64_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the List.
 * \param value Returns the value of the uint64_t.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArrayGetUint64At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint64_t* value);

/**
 * Sets a uint64_t at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the ByteArray.
 * \param value The uint64_t to put into the ByteArray.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArraySetUint64At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint64_t value);

/**
 * Gets a float at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the List.
 * \param value Returns the value of the float.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArrayGetFloat32At(Dart_Handle array,
                                                   intptr_t offset,
                                                   float* value);

/**
 * Sets a float at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the ByteArray.
 * \param value The float to put into the ByteArray.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArraySetFloat32At(Dart_Handle array,
                                                   intptr_t offset,
                                                   float value);

/**
 * Gets a double from some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the List.
 * \param value Returns the value of the double.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArrayGetFloat64At(Dart_Handle array,
                                                   intptr_t offset,
                                                   double* value);

/**
 * Sets a double at some byte offset in a ByteArray.
 *
 * If the byte offset is out of bounds, an error occurs.
 *
 * \param array A ByteArray.
 * \param offset A valid byte offset into the ByteArray.
 * \param value The double to put into the ByteArray.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ByteArraySetFloat64At(Dart_Handle array,
                                                   intptr_t offset,
                                                   double value);

// --- Closures ---

/**
 * Is this object a Closure?
 */
DART_EXPORT bool Dart_IsClosure(Dart_Handle object);

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

// DEPRECATED: The API below is a temporary hack.
DART_EXPORT int64_t Dart_ClosureSmrck(Dart_Handle object);

// DEPRECATED: The API below is a temporary hack.
DART_EXPORT void Dart_ClosureSetSmrck(Dart_Handle object, int64_t value);

// --- Constructors, Methods, and Fields ---

/**
 * Invokes a constructor, creating a new object.
 *
 * This function allows hidden constructors (constructors with leading
 * underscores) to be called.
 *
 * \param clazz A class or an interface.
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
DART_EXPORT Dart_Handle Dart_New(Dart_Handle clazz,
                                 Dart_Handle constructor_name,
                                 int number_of_arguments,
                                 Dart_Handle* arguments);

/**
 * Invokes a method or function.
 *
 * The 'target' parameter may be an object, class, or library.  If
 * 'target' is an object, then this function will invoke an instance
 * method.  If 'target' is a class, then this function will invoke a
 * static method.  If 'target' is a library, then this function will
 * invoke a top-level function from that library.
 *
 * This function ignores visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param target An object, class, or library.
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

/**
 * Gets the value of a field.
 *
 * The 'container' parameter may be an object, class, or library.  If
 * 'container' is an object, then this function will access an
 * instance field.  If 'container' is a class, then this function will
 * access a static field.  If 'container' is a library, then this
 * function will access a top-level variable.
 *
 * This function ignores field visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param container An object, class, or library.
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
 * The 'container' parameter may actually be an object, class, or
 * library.  If 'container' is an object, then this function will
 * access an instance field.  If 'container' is a class, then this
 * function will access a static field.  If 'container' is a library,
 * then this function will access a top-level variable.
 *
 * This function ignores field visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param container An object, class, or library.
 * \param name A field name.
 * \param value The new field value.
 *
 * \return A valid handle if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_SetField(Dart_Handle container,
                                      Dart_Handle name,
                                      Dart_Handle value);

/**
 * Creates a native wrapper class.
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle Dart_CreateNativeWrapperClass(Dart_Handle library,
                                                      Dart_Handle class_name,
                                                      int field_count);

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

// --- Exceptions ----

/**
 * Throws an exception.
 *
 * Throws an exception, unwinding all dart frames on the stack. If
 * successful, this function does not return. Note that this means
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

// --- Native functions ---

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
 * Gets the native argument at some index.
 */
DART_EXPORT Dart_Handle Dart_GetNativeArgument(Dart_NativeArguments args,
                                               int index);
// TODO(turnidge): Specify the behavior of an out-of-bounds access.

/**
 * Gets the number of native arguments.
 */
DART_EXPORT int Dart_GetNativeArgumentCount(Dart_NativeArguments args);

/**
 * Sets the return value for a native function.
 */
DART_EXPORT void Dart_SetReturnValue(Dart_NativeArguments args,
                                     Dart_Handle retval);

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
 * See Dart_SetNativeResolver.
 */
typedef Dart_NativeFunction (*Dart_NativeEntryResolver)(Dart_Handle name,
                                                        int num_of_arguments);
// TODO(turnidge): Consider renaming to NativeFunctionResolver or
// NativeResolver.

// --- Scripts and Libraries ---
// TODO(turnidge): Finish documenting this section.

typedef enum {
  kLibraryTag = 0,
  kImportTag,
  kSourceTag,
  kCanonicalizeUrl
} Dart_LibraryTag;

// TODO(turnidge): Document.
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
 * Sets the import map for the current isolate.
 *
 * The import map is a List of Strings, representing a set of (name,
 * value) pairs. The import map is used during the resolution of #
 * directives in source files to implement string interpolation.
 *
 * For example, if a source file imports:
 *
 *   #import('${foo}/dart.html');
 *
 * And the import map is:
 *
 *   [ "foo", "/home/user" ]
 *
 * Then the import would resolve to:
 *
 *   #import('/home/user/dart.html');
 *
 * \param import_map A List of Strings interpreted as a String to
 *   String mapping.
 * \return If no error occurs, the import map is set for the isolate.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_SetImportMap(Dart_Handle import_map);

/**
 * Loads the root script for the current isolate.
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle Dart_LoadScript(Dart_Handle url,
                                        Dart_Handle source);

/**
 * Loads the root script for current isolate from a snapshot.
 *
 * \param buffer A buffer which contains a snapshot of the script.
 *
 * \return If no error occurs, the Library object corresponding to the root
 *   script is returned. Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_LoadScriptFromSnapshot(const uint8_t* buffer);

/**
 * Gets the library for the root script for the current isolate.
 *
 * \return Returns the Library object corresponding to the root script
 *   if it has been set by a successful call to Dart_LoadScript or
 *   Dart_LoadScriptFromSnapshot.  Otherwise returns Dart_Null().
 */
DART_EXPORT Dart_Handle Dart_RootLibrary();

/**
 * Forces all loaded classes and functions to be compiled eagerly in
 * the current isolate..
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle Dart_CompileAll();

/**
 * Is this object a Library?
 */
DART_EXPORT bool Dart_IsLibrary(Dart_Handle object);

/**
 * Lookup a class by name from a Library.
 *
 * \return If no error occurs, the Library is returned. Otherwise an
 *   error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetClass(Dart_Handle library, Dart_Handle name);
// TODO(turnidge): Consider returning Dart_Null() when the class is
// not found to distinguish that from a true error case.

DART_EXPORT Dart_Handle Dart_LibraryUrl(Dart_Handle library);

DART_EXPORT Dart_Handle Dart_LookupLibrary(Dart_Handle url);
// TODO(turnidge): Consider returning Dart_Null() when the library is
// not found to distinguish that from a true error case.

DART_EXPORT Dart_Handle Dart_LoadLibrary(Dart_Handle url,
                                         Dart_Handle source);


DART_EXPORT Dart_Handle Dart_LibraryImportLibrary(Dart_Handle library,
                                                  Dart_Handle import);

DART_EXPORT Dart_Handle Dart_LoadSource(Dart_Handle library,
                                        Dart_Handle url,
                                        Dart_Handle source);
// TODO(turnidge): Rename to Dart_LibraryLoadSource?

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
    Dart_NativeEntryResolver resolver);
// TODO(turnidge): Rename to Dart_LibrarySetNativeResolver?

// --- Profiling support ----

// External pprof support for gathering and dumping symbolic
// information that can be used for better profile reports for
// dynamically generated code.
DART_EXPORT void Dart_InitPprofSupport();
DART_EXPORT void Dart_GetPprofSymbolInfo(void** buffer, int* buffer_size);

#endif  // INCLUDE_DART_API_H_
