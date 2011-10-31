// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef INCLUDE_DART_API_H_
#define INCLUDE_DART_API_H_

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

typedef void* Dart_Isolate;
typedef void* Dart_Handle;
typedef void* Dart_NativeArguments;

typedef enum {
  kLibraryTag = 0,
  kImportTag,
  kSourceTag,
  kCanonicalizeUrl,
} Dart_LibraryTag;

typedef void Dart_Snapshot;

typedef int64_t Dart_Port;
typedef void* Dart_Message;

// Allow the embedder to intercept isolate creation. Both at startup
// and when spawning new isolates from Dart code. The result returned
// from this callback is handed to all isolates spawned from the
// isolate currently being initialized.
//
// Return NULL if an error is encountered. The isolate being
// initialized will be shutdown. No Dart code will execute before it
// is shutdown.
//
// TODO(iposva): Pass a specification of the app file being spawned.
typedef void* (*Dart_IsolateInitCallback)(void* data);

typedef void (*Dart_NativeFunction)(Dart_NativeArguments arguments);
typedef Dart_NativeFunction (*Dart_NativeEntryResolver)(Dart_Handle name,
                                                        int num_of_arguments);
typedef Dart_Handle (*Dart_LibraryTagHandler)(Dart_LibraryTag tag,
                                              Dart_Handle library,
                                              Dart_Handle url);

// TODO(iposva): This is a placeholder for the eventual external Dart API.

// Returns true if 'handle' is valid and false if invalid.
DART_EXPORT bool Dart_IsValid(const Dart_Handle& handle);

// Internal routine used for reporting invalid handles.
DART_EXPORT void _Dart_ReportInvalidHandle(const char* file,
                                           int line,
                                           const char* handle_string,
                                           const char* error);

// Aborts the process if 'handle' is invalid.
#define DART_CHECK_VALID(handle)                                        \
  if (!Dart_IsValid((handle))) {                                        \
    _Dart_ReportInvalidHandle(__FILE__, __LINE__,                       \
                              #handle, Dart_GetError(handle));          \
  }

// Gets the error message associated with an invalid handle.
DART_EXPORT const char* Dart_GetError(const Dart_Handle& handle);

// Produces an invalid handle with an associated error message
DART_EXPORT Dart_Handle Dart_Error(const char* error);

// Initialize the VM with commmand line flags.
DART_EXPORT bool Dart_Initialize(int argc, char** argv,
                                 Dart_IsolateInitCallback callback);


// Isolate handling.
DART_EXPORT Dart_Isolate Dart_CreateIsolate(const Dart_Snapshot* snapshot,
                                            void* data);
DART_EXPORT void Dart_ShutdownIsolate();

DART_EXPORT Dart_Isolate Dart_CurrentIsolate();
DART_EXPORT void Dart_EnterIsolate(Dart_Isolate isolate);
DART_EXPORT void Dart_ExitIsolate();

// A convenience routine which processes any incoming messages for the
// current isolate. The routine exits when all ports to the current
// isolate are closed.
//
// This routine may only be used when the embedder has not provided an
// alternate message delivery mechanism with Dart_SetPostMessageCallback.
DART_EXPORT Dart_Handle Dart_RunLoop();

// Messages/ports

// A post message callback allows the embedder to provide an alternate
// delivery mechanism for inter-isolate messages. It is the
// responsibility of the embedder to call Dart_HandleMessage to
// process the message.
//
// If there is no reply port, then the constant 'kNoReplyPort' is
// passed as the 'reply_port' parameter.
//
// The memory pointed to by 'message' has been allocated by malloc.  It
// is the responsibility of the callback to ensure that free(message)
// is called once the message has been processed.
//
// The callback should return false if it runs into a problem
// processing this message.
//
// Todo(turnidge): Add a Dart_ReleaseMessage to hide allocation details?
typedef bool (*Dart_PostMessageCallback)(Dart_Isolate dest_isolate,
                                         Dart_Port dest_port,
                                         Dart_Port reply_port,
                                         Dart_Message message);
const Dart_Port kNoReplyPort = 0;

// A close port callback allows the embedder to receive notification
// when a port is closed. The constant 'kCloseAllPorts' is passed as
// the 'port' parameter when all active ports are being closed at
// once.
typedef void (*Dart_ClosePortCallback)(Dart_Isolate isolate,
                                       Dart_Port port);
const Dart_Port kCloseAllPorts = 0;

// Allows embedders to provide an alternative mechanism for sending
// inter-isolate messages. This setting only applies to the current
// isolate.
//
// Most embedders will only call this function once, before isolate
// execution begins.  If this function is called after isolate
// execution begins, the embedder is responsible for threading issues.
//
// TODO(turnidge): Consider moving this to isolate creation so that it
// is impossible to mess up.
DART_EXPORT void Dart_SetMessageCallbacks(
    Dart_PostMessageCallback post_message_callback,
    Dart_ClosePortCallback close_port_callback);

// Handle a message on the current isolate.
DART_EXPORT void Dart_HandleMessage(Dart_Port dest_port,
                                    Dart_Port reply_port,
                                    Dart_Message dart_message);


// Object.
DART_EXPORT Dart_Handle Dart_ObjectToString(Dart_Handle object);
DART_EXPORT bool Dart_IsNull(Dart_Handle object);


// Returns true if the two objects are equal.
DART_EXPORT Dart_Handle Dart_Objects_Equal(Dart_Handle obj1,
                                           Dart_Handle obj2,
                                           bool* value);


// Classes.
DART_EXPORT Dart_Handle Dart_GetClass(Dart_Handle library, Dart_Handle name);
DART_EXPORT Dart_Handle Dart_IsInstanceOf(Dart_Handle object,
                                          Dart_Handle cls,
                                          bool* value);


// Number.
DART_EXPORT bool Dart_IsNumber(Dart_Handle object);


// Integer.
DART_EXPORT bool Dart_IsInteger(Dart_Handle object);
DART_EXPORT Dart_Handle Dart_NewInteger(int64_t value);
DART_EXPORT Dart_Handle Dart_NewIntegerFromHexCString(const char* value);
DART_EXPORT Dart_Handle Dart_IntegerValue(Dart_Handle integer, int64_t* value);
DART_EXPORT Dart_Handle Dart_IntegerValueHexCString(Dart_Handle integer,
                                                    const char** value);
DART_EXPORT Dart_Handle Dart_IntegerFitsIntoInt64(Dart_Handle integer,
                                                  bool* value);


// Boolean.
DART_EXPORT bool Dart_IsBoolean(Dart_Handle object);
DART_EXPORT Dart_Handle Dart_NewBoolean(bool value);
DART_EXPORT Dart_Handle Dart_BooleanValue(Dart_Handle bool_object, bool* value);


// Double.
DART_EXPORT bool Dart_IsDouble(Dart_Handle object);
DART_EXPORT Dart_Handle Dart_NewDouble(double value);
DART_EXPORT Dart_Handle Dart_DoubleValue(Dart_Handle integer, double* result);


// String.
DART_EXPORT bool Dart_IsString(Dart_Handle object);

DART_EXPORT Dart_Handle Dart_StringLength(Dart_Handle str, intptr_t* len);

DART_EXPORT Dart_Handle Dart_NewString(const char* str);
DART_EXPORT Dart_Handle Dart_NewString8(const uint8_t* codepoints,
                                        intptr_t length);
DART_EXPORT Dart_Handle Dart_NewString16(const uint16_t* codepoints,
                                         intptr_t length);
DART_EXPORT Dart_Handle Dart_NewString32(const uint32_t* codepoints,
                                         intptr_t length);

// The functions below test whether the object is a String and its codepoints
// all fit into 8 or 16 bits respectively.
DART_EXPORT bool Dart_IsString8(Dart_Handle object);
DART_EXPORT bool Dart_IsString16(Dart_Handle object);

DART_EXPORT Dart_Handle Dart_StringGet8(Dart_Handle str,
                                        uint8_t* codepoints,
                                        intptr_t* length);
DART_EXPORT Dart_Handle Dart_StringGet16(Dart_Handle str,
                                         uint16_t* codepoints,
                                         intptr_t* length);
DART_EXPORT Dart_Handle Dart_StringGet32(Dart_Handle str,
                                         uint32_t* codepoints,
                                         intptr_t* length);

DART_EXPORT Dart_Handle Dart_StringToCString(Dart_Handle str,
                                             const char** result);


// Array.
DART_EXPORT bool Dart_IsArray(Dart_Handle object);
DART_EXPORT Dart_Handle Dart_NewArray(intptr_t length);
DART_EXPORT Dart_Handle Dart_GetLength(Dart_Handle array, intptr_t* len);
DART_EXPORT Dart_Handle Dart_ArrayGetAt(Dart_Handle array,
                                        intptr_t index);
DART_EXPORT Dart_Handle Dart_ArrayGet(Dart_Handle array,
                                      intptr_t offset,
                                      uint8_t* native_array,
                                      intptr_t length);
DART_EXPORT Dart_Handle Dart_ArraySetAt(Dart_Handle array,
                                        intptr_t index,
                                        Dart_Handle value);
DART_EXPORT Dart_Handle Dart_ArraySet(Dart_Handle array,
                                      intptr_t offset,
                                      uint8_t* native_array,
                                      intptr_t length);

// Closure.
DART_EXPORT bool Dart_IsClosure(Dart_Handle object);
// DEPRECATED: The API below is a temporary hack.
DART_EXPORT int64_t Dart_ClosureSmrck(Dart_Handle object);
DART_EXPORT void Dart_ClosureSetSmrck(Dart_Handle object, int64_t value);


// Invocation of methods.
DART_EXPORT Dart_Handle Dart_InvokeStatic(Dart_Handle library,
                                          Dart_Handle class_name,
                                          Dart_Handle function_name,
                                          int number_of_arguments,
                                          Dart_Handle* arguments);
DART_EXPORT Dart_Handle Dart_InvokeDynamic(Dart_Handle receiver,
                                           Dart_Handle function_name,
                                           int number_of_arguments,
                                           Dart_Handle* arguments);
DART_EXPORT Dart_Handle Dart_InvokeClosure(Dart_Handle closure,
                                           int number_of_arguments,
                                           Dart_Handle* arguments);


// Interaction with native methods.
DART_EXPORT Dart_Handle Dart_GetNativeArgument(Dart_NativeArguments args,
                                               int index);
DART_EXPORT int Dart_GetNativeArgumentCount(Dart_NativeArguments args);
DART_EXPORT void Dart_SetReturnValue(Dart_NativeArguments args,
                                     Dart_Handle retval);

// Library.
DART_EXPORT bool Dart_IsLibrary(Dart_Handle object);
DART_EXPORT Dart_Handle Dart_LibraryUrl(Dart_Handle library);
DART_EXPORT Dart_Handle Dart_LibraryImportLibrary(Dart_Handle library,
                                                  Dart_Handle import);

DART_EXPORT Dart_Handle Dart_LookupLibrary(Dart_Handle url);

DART_EXPORT Dart_Handle Dart_LoadLibrary(Dart_Handle url,
                                         Dart_Handle source);
DART_EXPORT Dart_Handle Dart_LoadSource(Dart_Handle library,
                                        Dart_Handle url,
                                        Dart_Handle source);
DART_EXPORT Dart_Handle Dart_SetNativeResolver(
    Dart_Handle library,
    Dart_NativeEntryResolver resolver);


// Script handling.
DART_EXPORT Dart_Handle Dart_LoadScript(Dart_Handle url,
                                        Dart_Handle source,
                                        Dart_LibraryTagHandler handler);

// Compile all loaded classes and functions eagerly.
DART_EXPORT Dart_Handle Dart_CompileAll();

// Exception related.
DART_EXPORT bool Dart_ExceptionOccurred(Dart_Handle result);
DART_EXPORT Dart_Handle Dart_GetException(Dart_Handle result);
DART_EXPORT Dart_Handle Dart_GetStacktrace(Dart_Handle unhandled_exception);
DART_EXPORT Dart_Handle Dart_ThrowException(Dart_Handle exception);
DART_EXPORT Dart_Handle Dart_ReThrowException(Dart_Handle exception,
                                              Dart_Handle stacktrace);

// Global Handles and Scope for local handles and zone based memory allocation.
DART_EXPORT void Dart_EnterScope();
DART_EXPORT void Dart_ExitScope();

DART_EXPORT Dart_Handle Dart_NewPersistentHandle(Dart_Handle object);
DART_EXPORT Dart_Handle Dart_MakeWeakPersistentHandle(Dart_Handle object);
DART_EXPORT Dart_Handle Dart_MakePersistentHandle(Dart_Handle object);
DART_EXPORT void Dart_DeletePersistentHandle(Dart_Handle object);

// Fields.
DART_EXPORT Dart_Handle Dart_GetStaticField(Dart_Handle cls, Dart_Handle name);
DART_EXPORT Dart_Handle Dart_SetStaticField(Dart_Handle cls,
                                            Dart_Handle name,
                                            Dart_Handle value);
DART_EXPORT Dart_Handle Dart_GetInstanceField(Dart_Handle obj,
                                              Dart_Handle name);
DART_EXPORT Dart_Handle Dart_SetInstanceField(Dart_Handle obj,
                                              Dart_Handle name,
                                              Dart_Handle value);

// Native fields.
DART_EXPORT Dart_Handle Dart_CreateNativeWrapperClass(Dart_Handle library,
                                                      Dart_Handle class_name,
                                                      int field_count);
DART_EXPORT Dart_Handle Dart_GetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t* value);
DART_EXPORT Dart_Handle Dart_SetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t value);

// Snapshot creation.
DART_EXPORT Dart_Handle Dart_CreateSnapshot(uint8_t** snaphot_buffer,
                                            intptr_t* snapshot_size);

// Message communication.
DART_EXPORT bool Dart_PostIntArray(Dart_Port port,
                                   int field_count,
                                   intptr_t* data);

DART_EXPORT bool Dart_Post(Dart_Port port, Dart_Handle value);

// External pprof support for gathering and dumping symbolic information
// that can be used for better profile reports for dynamically generated
// code.
DART_EXPORT void Dart_InitPprofSupport();
DART_EXPORT void Dart_GetPprofSymbolInfo(void** buffer, int* buffer_size);

// Check set vm flags.
DART_EXPORT bool Dart_IsVMFlagSet(const char* flag_name);

#endif  // INCLUDE_DART_API_H_
