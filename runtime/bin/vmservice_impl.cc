// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/vmservice_impl.h"

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/isolate_data.h"
#include "bin/resources.h"
#include "bin/thread.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/isolate.h"
#include "vm/message.h"
#include "vm/native_entry.h"
#include "vm/native_arguments.h"
#include "vm/object.h"
#include "vm/port.h"
#include "vm/snapshot.h"

namespace dart {
namespace bin {

// snapshot_buffer points to a snapshot if we link in a snapshot otherwise
// it is initialized to NULL.
extern const uint8_t* snapshot_buffer;
#define RETURN_ERROR_HANDLE(handle)                             \
  if (Dart_IsError(handle)) {                                   \
    return handle;                                              \
  }

#define SHUTDOWN_ON_ERROR(handle)                               \
  if (Dart_IsError(handle)) {                                   \
    error_msg_ = strdup(Dart_GetError(handle));                 \
    Dart_ExitScope();                                           \
    Dart_ShutdownIsolate();                                     \
    return false;                                               \
  }

#define kLibraryResourceNamePrefix "/vmservice"
static const char* kLibraryScriptResourceName =
    kLibraryResourceNamePrefix "/vmservice.dart";
static const char* kLibrarySourceResourceNames[] = {
    kLibraryResourceNamePrefix "/constants.dart",
    kLibraryResourceNamePrefix "/resources.dart",
    kLibraryResourceNamePrefix "/running_isolate.dart",
    kLibraryResourceNamePrefix "/running_isolates.dart",
    kLibraryResourceNamePrefix "/server.dart",
    kLibraryResourceNamePrefix "/service_request.dart",
    kLibraryResourceNamePrefix "/service_request_router.dart",
    kLibraryResourceNamePrefix "/vmservice_io.dart",
    NULL
};

#define kClientResourceNamePrefix "/client/web/out"

Dart_Isolate VmService::isolate_ = NULL;
Dart_Port VmService::port_ = ILLEGAL_PORT;
dart::Monitor* VmService::monitor_ = NULL;
const char* VmService::error_msg_ = NULL;

// These must be kept in sync with vmservice/constants.dart
#define VM_SERVICE_ISOLATE_STARTUP_MESSAGE_ID 1
#define VM_SERVICE_ISOLATE_SHUTDOWN_MESSAGE_ID 2


static Dart_NativeFunction VmServiceNativeResolver(Dart_Handle name,
                                                   int num_arguments);


bool VmService::Start(intptr_t server_port) {
  monitor_ = new dart::Monitor();
  ASSERT(monitor_ != NULL);
  error_msg_ = NULL;


  {
    // Take lock before spawning new thread.
    MonitorLocker ml(monitor_);
    // Spawn new thread.
    dart::Thread::Start(ThreadMain, server_port);
    // Wait until service is running on spawned thread.
    ml.Wait();
  }
  return port_ != ILLEGAL_PORT;
}


bool VmService::_Start(intptr_t server_port) {
  ASSERT(isolate_ == NULL);
  char* error = NULL;
  isolate_ = Dart_CreateIsolate("vmservice:", "main", snapshot_buffer,
                                new IsolateData(),
                                &error);
  if (isolate_ == NULL) {
    error_msg_ = error;
    return false;
  }

  Dart_EnterScope();

  if (snapshot_buffer != NULL) {
    // Setup the native resolver as the snapshot does not carry it.
    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kIOLibrary);
  }

  // Set up the library tag handler for this isolate.
  Dart_Handle result = Dart_SetLibraryTagHandler(DartUtils::LibraryTagHandler);
  SHUTDOWN_ON_ERROR(result);

  // Load the specified application script into the newly created isolate.

  // Prepare builtin and its dependent libraries for use to resolve URIs.
  // The builtin library is part of the core snapshot and would already be
  // available here in the case of script snapshot loading.
  Dart_Handle builtin_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  SHUTDOWN_ON_ERROR(builtin_lib);

  // Prepare for script loading by setting up the 'print' and 'timer'
  // closures and setting up 'package root' for URI resolution.
  result = DartUtils::PrepareForScriptLoading("", builtin_lib);
  SHUTDOWN_ON_ERROR(result);

  {
    // Load source into service isolate.
    Dart_Handle library = LoadScript(kLibraryScriptResourceName);
    SHUTDOWN_ON_ERROR(library);
    result = LoadSources(library, kLibrarySourceResourceNames);
    SHUTDOWN_ON_ERROR(result);
  }

  // Make the isolate runnable so that it is ready to handle messages.
  Dart_ExitScope();
  Dart_ExitIsolate();

  bool retval = Dart_IsolateMakeRunnable(isolate_);
  if (!retval) {
    Dart_EnterIsolate(isolate_);
    Dart_ShutdownIsolate();
    error_msg_ = "Invalid isolate state - Unable to make it runnable.";
    return false;
  }

  Dart_EnterIsolate(isolate_);
  Dart_EnterScope();


  Dart_Handle library = Dart_RootLibrary();
  // Set requested port.
  DartUtils::SetIntegerField(library, "_port", server_port);
  // Install native resolver.
  result = Dart_SetNativeResolver(library, VmServiceNativeResolver);
  SHUTDOWN_ON_ERROR(result);
  result = Dart_Invoke(library, DartUtils::NewString("main"), 0, NULL);
  SHUTDOWN_ON_ERROR(result);

  result = LoadResources(library);
  SHUTDOWN_ON_ERROR(result);
  result = Dart_CompileAll();
  SHUTDOWN_ON_ERROR(result);

  port_ = Dart_GetMainPortId();

  Dart_ExitScope();
  Dart_ExitIsolate();

  return true;
}


void VmService::_Stop() {
  port_ = ILLEGAL_PORT;
}


const char* VmService::GetErrorMessage() {
  return error_msg_ == NULL ? "No error." : error_msg_;
}


Dart_Port VmService::port() {
  return port_;
}


bool VmService::IsRunning() {
  return port_ != ILLEGAL_PORT;
}


Dart_Handle VmService::LoadScript(const char* name) {
  Dart_Handle url = Dart_NewStringFromCString(name);
  const char* vmservice_source = NULL;
  int r = Resources::ResourceLookup(name, &vmservice_source);
  ASSERT(r != Resources::kNoSuchInstance);
  Dart_Handle source = Dart_NewStringFromCString(vmservice_source);
  return Dart_LoadScript(url, source, 0, 0);
}


Dart_Handle VmService::LoadSource(Dart_Handle library, const char* name) {
  Dart_Handle url = Dart_NewStringFromCString(name);
  const char* vmservice_source = NULL;
  int r = Resources::ResourceLookup(name, &vmservice_source);
  if (r == Resources::kNoSuchInstance) {
    printf("Can't find %s\n", name);
  }
  ASSERT(r != Resources::kNoSuchInstance);
  Dart_Handle source = Dart_NewStringFromCString(vmservice_source);
  return Dart_LoadSource(library, url, source);
}


Dart_Handle VmService::LoadSources(Dart_Handle library, const char* names[]) {
  Dart_Handle result = Dart_Null();
  for (int i = 0; names[i] != NULL; i++) {
    result = LoadSource(library, names[i]);
    if (Dart_IsError(result)) {
      break;
    }
  }
  return result;
}


Dart_Handle VmService::LoadResource(Dart_Handle library,
                                    const char* resource_name,
                                    const char* prefix) {
  intptr_t prefix_len = strlen(prefix);
  // Prepare for invoke call.
  Dart_Handle name = Dart_NewStringFromCString(resource_name+prefix_len);
  RETURN_ERROR_HANDLE(name);
  const char* data_buffer = NULL;
  int data_buffer_length = Resources::ResourceLookup(resource_name,
                                                     &data_buffer);
  if (data_buffer_length == Resources::kNoSuchInstance) {
    printf("Could not find %s %s\n", resource_name, resource_name+prefix_len);
  }
  ASSERT(data_buffer_length != Resources::kNoSuchInstance);
  Dart_Handle data_list = Dart_NewTypedData(Dart_TypedData_kUint8,
                                            data_buffer_length);
  RETURN_ERROR_HANDLE(data_list);
  Dart_TypedData_Type type = Dart_TypedData_kInvalid;
  void* data_list_buffer = NULL;
  intptr_t data_list_buffer_length = 0;
  Dart_Handle result = Dart_TypedDataAcquireData(data_list, &type,
                                                 &data_list_buffer,
                                                 &data_list_buffer_length);
  RETURN_ERROR_HANDLE(result);
  ASSERT(data_buffer_length == data_list_buffer_length);
  ASSERT(data_list_buffer != NULL);
  ASSERT(type = Dart_TypedData_kUint8);
  memmove(data_list_buffer, &data_buffer[0], data_buffer_length);
  result = Dart_TypedDataReleaseData(data_list);
  RETURN_ERROR_HANDLE(result);

  // Make invoke call.
  const intptr_t kNumArgs = 2;
  Dart_Handle args[kNumArgs] = { name, data_list };
  result = Dart_Invoke(library, Dart_NewStringFromCString("_addResource"),
                       kNumArgs, args);
  return result;
}


Dart_Handle VmService::LoadResources(Dart_Handle library) {
  Dart_Handle result = Dart_Null();
  intptr_t prefixLen = strlen(kClientResourceNamePrefix);
  for (intptr_t i = 0; i < Resources::get_resource_count(); i++) {
    const char* path = Resources::get_resource_path(i);
    if (!strncmp(path, kClientResourceNamePrefix, prefixLen)) {
      result = LoadResource(library, path, kClientResourceNamePrefix);
      if (Dart_IsError(result)) {
        break;
      }
    }
  }
  return result;
}


void VmService::ThreadMain(uword parameters) {
  ASSERT(Dart_CurrentIsolate() == NULL);
  ASSERT(isolate_ == NULL);

  intptr_t server_port = static_cast<intptr_t>(parameters);
  ASSERT(server_port >= 0);

  // Lock scope.
  {
    MonitorLocker ml(monitor_);
    bool r = _Start(server_port);
    if (!r) {
      port_ = ILLEGAL_PORT;
      monitor_->Notify();
      return;
    }

    Dart_EnterIsolate(isolate_);
    Dart_EnterScope();

    Dart_Handle receievePort = Dart_GetReceivePort(port_);
    ASSERT(!Dart_IsError(receievePort));
    monitor_->Notify();
  }

  // Keep handling messages until the last active receive port is closed.
  Dart_Handle result = Dart_RunLoop();
  if (Dart_IsError(result)) {
    printf("VmService has exited with an error:\n%s\n", Dart_GetError(result));
  }

  _Stop();

  Dart_ExitScope();
  Dart_ExitIsolate();
}


static Dart_Handle MakeServiceControlMessage(Dart_Port port) {
  Dart_Handle list = Dart_NewList(2);
  ASSERT(!Dart_IsError(list));
  Dart_Handle sendPort = Dart_NewSendPort(port);
  ASSERT(!Dart_IsError(sendPort));
  Dart_ListSetAt(list, 1, sendPort);
  return list;
}


bool VmService::SendIsolateStartupMessage(Dart_Port port) {
  if (!IsRunning()) {
    return false;
  }
  Dart_Isolate isolate = Dart_CurrentIsolate();
  ASSERT(isolate != NULL);
  ASSERT(Dart_GetMainPortId() == port);
  Dart_Handle list = MakeServiceControlMessage(port);
  Dart_ListSetAt(list, 0,
                 Dart_NewInteger(VM_SERVICE_ISOLATE_STARTUP_MESSAGE_ID));
  return Dart_Post(port_, list);
}


bool VmService::SendIsolateShutdownMessage(Dart_Port port) {
  if (!IsRunning()) {
    return false;
  }
  Dart_Isolate isolate = Dart_CurrentIsolate();
  ASSERT(isolate != NULL);
  ASSERT(Dart_GetMainPortId() == port);
  Dart_Handle list = MakeServiceControlMessage(port);
  Dart_ListSetAt(list, 0,
                 Dart_NewInteger(VM_SERVICE_ISOLATE_SHUTDOWN_MESSAGE_ID));
  return Dart_Post(port_, list);
}


void VmService::VmServiceShutdownCallback(void* callback_data) {
  ASSERT(Dart_CurrentIsolate() != NULL);
  Dart_EnterScope();
  VmService::SendIsolateShutdownMessage(Dart_GetMainPortId());
  Dart_ExitScope();
}


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


static void SendServiceMessage(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Isolate* isolate = arguments->isolate();
  StackZone zone(isolate);
  HANDLESCOPE(isolate);
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, sp, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, rp, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(2));

  // Extract SendPort port id.
  const Object& sp_id_obj = Object::Handle(DartLibraryCalls::PortGetId(sp));
  if (sp_id_obj.IsError()) {
    Exceptions::PropagateError(Error::Cast(sp_id_obj));
  }
  Integer& id = Integer::Handle();
  id ^= sp_id_obj.raw();
  Dart_Port sp_id = static_cast<Dart_Port>(id.AsInt64Value());

  // Extract ReceivePort port id.
  const Object& rp_id_obj = Object::Handle(DartLibraryCalls::PortGetId(rp));
  if (rp_id_obj.IsError()) {
    Exceptions::PropagateError(Error::Cast(rp_id_obj));
  }
  ASSERT(rp_id_obj.IsSmi() || rp_id_obj.IsMint());
  id ^= rp_id_obj.raw();
  Dart_Port rp_id = static_cast<Dart_Port>(id.AsInt64Value());

  // Both are valid ports.
  ASSERT(sp_id != ILLEGAL_PORT);
  ASSERT(rp_id != ILLEGAL_PORT);

  // Serialize message.
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(message);

  // TODO(turnidge): Throw an exception when the return value is false?
  PortMap::PostMessage(new Message(sp_id, rp_id, data, writer.BytesWritten(),
                                   Message::kOOBPriority));
}


struct VmServiceNativeEntry {
  const char* name;
  int num_arguments;
  Dart_NativeFunction function;
};


static VmServiceNativeEntry _VmServiceNativeEntries[] = {
  {"SendServiceMessage", 3, SendServiceMessage}
};


static Dart_NativeFunction VmServiceNativeResolver(Dart_Handle name,
                                                   int num_arguments) {
  const Object& obj = Object::Handle(Api::UnwrapHandle(name));
  if (!obj.IsString()) {
    return NULL;
  }
  const char* function_name = obj.ToCString();
  ASSERT(function_name != NULL);
  intptr_t n =
      sizeof(_VmServiceNativeEntries) / sizeof(_VmServiceNativeEntries[0]);
  for (intptr_t i = 0; i < n; i++) {
    VmServiceNativeEntry entry = _VmServiceNativeEntries[i];
    if (!strcmp(function_name, entry.name) &&
        (num_arguments == entry.num_arguments)) {
      return entry.function;
    }
  }
  return NULL;
}

}  // namespace bin
}  // namespace dart
