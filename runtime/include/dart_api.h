// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
typedef void* Dart_Handle;

/**
 * Is this an error handle?
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsError(const Dart_Handle& handle);

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
DART_EXPORT const char* Dart_GetError(const Dart_Handle& handle);

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
 * Checks if the two objects are the same object
 *
 * The result of the comparison is returned through the 'same'
 * parameter. The return value itself is used to indicate success or
 * failure, not identity.
 *
 * \param obj1 An object to be compared.
 * \param obj2 An object to be compared.
 * \param equal Returns whether the two objects are the same.
 *
 * \return A valid handle if no error occurs during the comparison.
 */
DART_EXPORT Dart_Handle Dart_IsSame(Dart_Handle obj1,
                                    Dart_Handle obj2,
                                    bool* same);

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
 * Takes a persistent handle and makes it weak.
 *
 * UNIMPLEMENTED.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_Handle Dart_MakeWeakPersistentHandle(Dart_Handle object);
// TODO(turnidge): Needs a "near death" callback here.
// TODO(turnidge): Add IsWeak, Clear, etc.

/**
 * Takes a weak persistent handle and makes it non-weak.
 *
 * UNIMPLEMENTED.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_Handle Dart_MakePersistentHandle(Dart_Handle object);

// --- Initialization and Globals ---

/**
 * An isolate initialization callback function.
 *
 * This callback, provided by the embedder, is called during isolate
 * creation. It is called for all isolates, regardless of whether they
 * are created via Dart_CreateIsolate or directly from Dart code.
 *
 * \param data Embedder-specific data used during isolate initialization.
 *
 * \return If the embedder returns NULL, then the isolate being
 *   initialized will be shut down without executing any Dart code.
 *   Otherwise, the embedder should return a pointer to
 *   embedder-specific data created during the initialization of this
 *   isolate. This data will, in turn, be passed by the VM to all
 *   isolates spawned from the isolate currently being initialized.
 */
typedef void* (*Dart_IsolateInitCallback)(void* embedder_data);
// TODO(iposva): Pass a specification of the app file being spawned.
// TODO(turnidge): We don't actually shut down the isolate on NULL yet.
// TODO(turnidge): Should we separate the two return values?

/**
 * Initializes the VM with the given commmand line flags.
 *
 * \param argc The length of the arguments array.
 * \param argv An array of arguments.
 * \param callback A function to be called during isolate creation.
 *   See Dart_IsolateInitCallback.
 *
 * \return True if initialization is successful.
 */
DART_EXPORT bool Dart_Initialize(int argc, const char** argv,
                                 Dart_IsolateInitCallback callback);

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
typedef void* Dart_Isolate;

/**
 * A buffer containing a snapshot of the Dart VM. A snapshot can be
 * used to restore the VM quickly to a saved state and is useful for
 * fast startup.
 */
typedef void Dart_Snapshot;

/**
 * Creates a new isolate. If snapshot data is provided, the isolate
 * will be started using that snapshot data. The new isolate becomes
 * the current isolate.
 *
 * Requires there to be no current isolate.
 *
 * \param snapshot A buffer containing a VM snapshot or NULL if no
 *   snapshot is provided.
 * \param data Embedder-specific data. See Dart_IsolateInitCallback.
 *
 * \return The new isolate is returned. May be NULL if an error
 *   occurs duing isolate initialization.
 */
DART_EXPORT Dart_Isolate Dart_CreateIsolate(const Dart_Snapshot* snapshot,
                                            void* data);
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
 * Creates a snapshot of the state of the current isolate.
 */
DART_EXPORT Dart_Handle Dart_CreateSnapshot(uint8_t** snaphot_buffer,
                                            intptr_t* snapshot_size);
// TODO(turnidge): Does this include the current script or only libs?
// is it possible to take a snapshot and load more scripts into it?

// --- Messages and Ports ---

/**
 * Messages are used to communicate between isolates.
 */
typedef void* Dart_Message;

/**
 * A port is used to send or receive inter-isolate messages
 */
typedef int64_t Dart_Port;

const Dart_Port kNoReplyPort = 0;

/**
 * A message posting callback.
 *
 * This callback allows the embedder to provide an alternate delivery
 * mechanism for inter-isolate messages. It is the responsibility of
 * the embedder to call Dart_HandleMessage to process the message.
 *
 * If there is no reply port, then the constant 'kNoReplyPort' is
 * passed as the 'reply_port' parameter.
 *
 * The memory pointed to by 'message' has been allocated by malloc. It
 * is the responsibility of the callback to ensure that free(message)
 * is called once the message has been processed.
 *
 * The callback should return false if it runs into a problem
 * processing this message.
 */
typedef bool (*Dart_PostMessageCallback)(Dart_Isolate dest_isolate,
                                         Dart_Port dest_port,
                                         Dart_Port reply_port,
                                         Dart_Message message);
// TODO(turnidge): Add a Dart_ReleaseMessage to hide allocation details.

const Dart_Port kCloseAllPorts = 0;

/**
 * A close port callback.
 *
 * This callback allows the embedder to receive notification when a
 * port is closed. The constant 'kCloseAllPorts' is passed as the
 * 'port' parameter when all active ports are being closed at once.
 */
typedef void (*Dart_ClosePortCallback)(Dart_Isolate isolate,
                                       Dart_Port port);

/**
 * Allows embedders to provide an alternative mechanism for sending
 * inter-isolate messages. This setting only applies to the current
 * isolate.
 *
 * Most embedders will only call this function once, before isolate
 * execution begins. If this function is called after isolate
 * execution begins, the embedder is responsible for threading issues.
 */
DART_EXPORT void Dart_SetMessageCallbacks(
    Dart_PostMessageCallback post_message_callback,
    Dart_ClosePortCallback close_port_callback);
// TODO(turnidge): Consider moving this to isolate creation so that it
// is impossible to mess up.

/**
 * Handles a message on the current isolate.
 *
 * May generate an unhandled exception error.
 *
 * Note that this function does not free the memory associated with
 * 'dart_message'.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_HandleMessage(Dart_Port dest_port,
                                           Dart_Port reply_port,
                                           Dart_Message dart_message);
// TODO(turnidge): Revisit memory management of 'dart_message'.

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
 */
DART_EXPORT Dart_Handle Dart_RunLoop();
// TODO(turnidge): Should this be removed from the public api?

/**
 * Posts a message for some isolate. The message is built from a raw
 * array.
 *
 * \param port The destination port.
 * \param length The length of the data array.
 * \param data A data array to be sent in the message.
 *
 * \return True if the message was posted.
 */
DART_EXPORT bool Dart_PostIntArray(Dart_Port port,
                                   intptr_t length,
                                   intptr_t* data);
// TODO(turnidge): Should this be intptr_t or some fixed length type?
// TODO(turnidge): Reverse length/data for consistency.

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
DART_EXPORT bool Dart_Post(Dart_Port port, Dart_Handle object);

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
DART_EXPORT Dart_Handle Dart_IntegerValue(Dart_Handle integer, int64_t* value);

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
DART_EXPORT Dart_Handle Dart_IntegerValueHexCString(Dart_Handle integer,
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
 * \param bool_object A Boolean
 * \param value Returns the value of the Boolean.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_BooleanValue(Dart_Handle bool_object, bool* value);

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
 * \param bool_object A Double
 * \param value Returns the value of the Double.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_DoubleValue(Dart_Handle integer, double* result);

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


typedef void (*Dart_PeerFinalizer)(void* peer);

DART_EXPORT Dart_Handle Dart_NewExternalString8(const uint8_t* codepoints,
                                                intptr_t length,
                                                void* peer,
                                                Dart_PeerFinalizer callback);

DART_EXPORT Dart_Handle Dart_NewExternalString16(const uint16_t* codepoints,
                                                 intptr_t length,
                                                 void* peer,
                                                 Dart_PeerFinalizer callback);

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

// --- Methods and Fields ---

/**
 * Invokes a static method with the given arguments.
 *
 * May generate an unhandled exception error.
 *
 * \return If no error occurs during execution, then the result of
 *   invoking the method is returned. If an error occurs during
 *   execution, then an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_InvokeStatic(Dart_Handle library,
                                          Dart_Handle class_name,
                                          Dart_Handle function_name,
                                          int number_of_arguments,
                                          Dart_Handle* arguments);

/**
 * Invokes an instance method with the given arguments.
 *
 * May generate an unhandled exception error.
 *
 * \return If no error occurs during execution, then the result of
 *   invoking the method is returned. If an error occurs during
 *   execution, then an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_InvokeDynamic(Dart_Handle receiver,
                                           Dart_Handle function_name,
                                           int number_of_arguments,
                                           Dart_Handle* arguments);

/**
 * Gets the value of a static field.
 *
 * May generate an unhandled exception error.
 *
 * \return If no error occurs, then the value of the field is
 *   returned. Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetStaticField(Dart_Handle cls, Dart_Handle name);

/**
 * Sets the value of a static field.
 *
 * May generate an unhandled exception error.
 *
 * \return A valid handle if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_SetStaticField(Dart_Handle cls,
                                            Dart_Handle name,
                                            Dart_Handle value);

/**
 * Gets the value of an instance field.
 *
 * May generate an unhandled exception error.
 *
 * \return If no error occurs, then the value of the field is
 *   returned. Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetInstanceField(Dart_Handle obj,
                                              Dart_Handle name);
/**
 * Sets the value of an instance field.
 *
 * May generate an unhandled exception error.
 *
 * \return A valid handle if no error occurs.
 */
DART_EXPORT Dart_Handle Dart_SetInstanceField(Dart_Handle obj,
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
typedef void* Dart_NativeArguments;

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
  kCanonicalizeUrl,
} Dart_LibraryTag;

// TODO(turnidge): Document.
typedef Dart_Handle (*Dart_LibraryTagHandler)(Dart_LibraryTag tag,
                                              Dart_Handle library,
                                              Dart_Handle url);

/**
 * Loads the root script for the current isolate.
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle Dart_LoadScript(Dart_Handle url,
                                        Dart_Handle source,
                                        Dart_LibraryTagHandler handler);

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

DART_EXPORT Dart_Handle Dart_LibraryUrl(Dart_Handle library);

DART_EXPORT Dart_Handle Dart_LookupLibrary(Dart_Handle url);

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
