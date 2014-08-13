// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/vmservice_impl.h"

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/isolate_data.h"
#include "bin/platform.h"
#include "bin/thread.h"
#include "platform/json.h"

namespace dart {
namespace bin {

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

#define kLibrarySourceNamePrefix "/vmservice"
static const char* kVMServiceIOLibraryScriptResourceName = "vmservice_io.dart";
#define kClientResourceNamePrefix "/vmservice/observatory/deployed/web"

struct ResourcesEntry {
  const char* path_;
  const char* resource_;
  int length_;
};

extern ResourcesEntry __service_bin_resources_[];

class Resources {
 public:
  static const int kNoSuchInstance = -1;
  static int ResourceLookup(const char* path, const char** resource) {
    ResourcesEntry* table = ResourcesTable();
    for (int i = 0; table[i].path_ != NULL; i++) {
      const ResourcesEntry& entry = table[i];
      if (strcmp(path, entry.path_) == 0) {
        *resource = entry.resource_;
        ASSERT(entry.length_ > 0);
        return entry.length_;
      }
    }
    return kNoSuchInstance;
  }

  static const char* Path(int idx) {
    ASSERT(idx >= 0);
    ResourcesEntry* entry = At(idx);
    if (entry == NULL) {
      return NULL;
    }
    ASSERT(entry->path_ != NULL);
    return entry->path_;
  }

 private:
  static ResourcesEntry* At(int idx) {
    ASSERT(idx >= 0);
    ResourcesEntry* table = ResourcesTable();
    for (int i = 0; table[i].path_ != NULL; i++) {
      if (idx == i) {
        return &table[i];
      }
    }
    return NULL;
  }
  static ResourcesEntry* ResourcesTable() {
    return &__service_bin_resources_[0];
  }

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Resources);
};

const char* VmService::error_msg_ = NULL;

bool VmService::Start(const char *server_ip, intptr_t server_port) {
  bool r = _Start(server_ip, server_port);
  if (!r) {
    return r;
  }
  // Start processing messages in a new thread.
  dart::Thread::Start(ThreadMain, static_cast<uword>(NULL));
  return true;
}


bool VmService::_Start(const char *server_ip, intptr_t server_port) {
  ASSERT(Dart_CurrentIsolate() == NULL);
  Dart_Isolate isolate = Dart_GetServiceIsolate(NULL);
  if (isolate == NULL) {
    error_msg_ = "Internal error.";
    return false;
  }
  Dart_EnterIsolate(isolate);
  Dart_EnterScope();
  // Install our own library tag handler.
  Dart_SetLibraryTagHandler(LibraryTagHandler);
  Dart_Handle result;
  Dart_Handle library = LoadScript(kVMServiceIOLibraryScriptResourceName);
  // Expect a library.
  ASSERT(library != Dart_Null());
  SHUTDOWN_ON_ERROR(library);
  result = Dart_FinalizeLoading(false);
  ASSERT(!Dart_IsError(result));
  Dart_ExitScope();
  Dart_ExitIsolate();
  bool retval = Dart_IsolateMakeRunnable(isolate);
  if (!retval) {
    Dart_EnterIsolate(isolate);
    Dart_ShutdownIsolate();
    error_msg_ = "Invalid isolate state - Unable to make it runnable.";
    return false;
  }

  Dart_EnterIsolate(isolate);
  Dart_EnterScope();
  library = Dart_RootLibrary();
  // Set requested TCP port.
  DartUtils::SetStringField(library, "_ip", server_ip);
  // If we have a port specified, start the server immediately.
  bool auto_start = server_port >= 0;
  if (server_port < 0) {
    // Adjust server_port to port 0 which will result in the first available
    // port when the HTTP server is started.
    server_port = 0;
  }
  // Set initial state.
  DartUtils::SetIntegerField(library, "_port", server_port);
  Dart_SetField(library,
                DartUtils::NewString("_autoStart"),
                Dart_NewBoolean(auto_start));
  // We cannot register for signals on windows.
#if defined(TARGET_OS_WINDOWS)
  const bool is_windows = true;
#else
  const bool is_windows = false;
#endif
  Dart_SetField(library,
                DartUtils::NewString("_isWindows"),
                Dart_NewBoolean(is_windows));

  // Invoke main.
  result = Dart_Invoke(library, DartUtils::NewString("main"), 0, NULL);
  SHUTDOWN_ON_ERROR(result);
  // Load resources.
  result = LoadResources(library);
  SHUTDOWN_ON_ERROR(result);

  Dart_ExitScope();
  Dart_ExitIsolate();

  return true;
}


const char* VmService::GetErrorMessage() {
  return error_msg_ == NULL ? "No error." : error_msg_;
}


Dart_Handle VmService::GetSource(const char* name) {
  const intptr_t kBufferSize = 512;
  char buffer[kBufferSize];
  snprintf(&buffer[0], kBufferSize-1, "%s/%s", kLibrarySourceNamePrefix, name);
  const char* vmservice_source = NULL;
  int r = Resources::ResourceLookup(buffer, &vmservice_source);
  ASSERT(r != Resources::kNoSuchInstance);
  return Dart_NewStringFromCString(vmservice_source);
}


Dart_Handle VmService::LoadScript(const char* name) {
  Dart_Handle url = Dart_NewStringFromCString("dart:vmservice_io");
  Dart_Handle source = GetSource(name);
  return Dart_LoadScript(url, source, 0, 0);
}


Dart_Handle VmService::LoadSource(Dart_Handle library, const char* name) {
  Dart_Handle url = Dart_NewStringFromCString(name);
  Dart_Handle source = GetSource(name);
  return Dart_LoadSource(library, url, source, 0, 0);
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
  for (intptr_t i = 0; Resources::Path(i) != NULL; i++) {
    const char* path = Resources::Path(i);
    if (!strncmp(path, kClientResourceNamePrefix, prefixLen)) {
      result = LoadResource(library, path, kClientResourceNamePrefix);
      if (Dart_IsError(result)) {
        break;
      }
    }
  }
  return result;
}


Dart_Handle VmService::LibraryTagHandler(Dart_LibraryTag tag,
                                         Dart_Handle library,
                                         Dart_Handle url) {
  if (!Dart_IsLibrary(library)) {
    return Dart_NewApiError("not a library");
  }
  if (!Dart_IsString(url)) {
    return Dart_NewApiError("url is not a string");
  }
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  Dart_Handle library_url = Dart_LibraryUrl(library);
  const char* library_url_string = NULL;
  result = Dart_StringToCString(library_url, &library_url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  if (tag == Dart_kImportTag) {
    // Embedder handles all requests for external libraries.
    return DartUtils::LibraryTagHandler(tag, library, url);
  }
  ASSERT((tag == Dart_kSourceTag) || (tag == Dart_kCanonicalizeUrl));
  if (tag == Dart_kCanonicalizeUrl) {
    // url is already canonicalized.
    return url;
  }
  Dart_Handle source = GetSource(url_string);
  if (Dart_IsError(source)) {
    return source;
  }
  return Dart_LoadSource(library, url, source, 0, 0);
}


void VmService::ThreadMain(uword parameters) {
  ASSERT(Dart_CurrentIsolate() == NULL);
  Dart_Isolate service_isolate = Dart_GetServiceIsolate(NULL);
  Dart_EnterIsolate(service_isolate);
  Dart_EnterScope();
  Dart_Handle result = Dart_RunLoop();
  if (Dart_IsError(result)) {
    printf("Service exited with an error:\n%s\n", Dart_GetError(result));
  }
  Dart_ExitScope();
  Dart_ExitIsolate();
}



}  // namespace bin
}  // namespace dart
