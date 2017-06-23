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
#include "bin/utils.h"
#include "platform/text_buffer.h"

namespace dart {
namespace bin {

#define RETURN_ERROR_HANDLE(handle)                                            \
  if (Dart_IsError(handle)) {                                                  \
    return handle;                                                             \
  }

#define SHUTDOWN_ON_ERROR(handle)                                              \
  if (Dart_IsError(handle)) {                                                  \
    error_msg_ = strdup(Dart_GetError(handle));                                \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return false;                                                              \
  }

#define kLibrarySourceNamePrefix "/vmservice"
static const char* const kVMServiceIOLibraryUri = "dart:vmservice_io";
static const char* const kVMServiceIOLibraryScriptResourceName =
    "vmservice_io.dart";

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


void NotifyServerState(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* uri_chars;
  Dart_Handle uri_arg = Dart_GetNativeArgument(args, 0);
  if (Dart_IsError(uri_arg)) {
    VmService::SetServerAddress("");
    Dart_ExitScope();
    return;
  }
  Dart_Handle result = Dart_StringToCString(uri_arg, &uri_chars);
  if (Dart_IsError(result)) {
    VmService::SetServerAddress("");
    Dart_ExitScope();
    return;
  }
  VmService::SetServerAddress(uri_chars);
  Dart_ExitScope();
}


static void Shutdown(Dart_NativeArguments args) {
  // NO-OP.
}


struct VmServiceIONativeEntry {
  const char* name;
  int num_arguments;
  Dart_NativeFunction function;
};


static VmServiceIONativeEntry _VmServiceIONativeEntries[] = {
    {"VMServiceIO_NotifyServerState", 1, NotifyServerState},
    {"VMServiceIO_Shutdown", 0, Shutdown},
};


static Dart_NativeFunction VmServiceIONativeResolver(Dart_Handle name,
                                                     int num_arguments,
                                                     bool* auto_setup_scope) {
  const char* function_name = NULL;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  ASSERT(!Dart_IsError(result));
  ASSERT(function_name != NULL);
  *auto_setup_scope = true;
  intptr_t n =
      sizeof(_VmServiceIONativeEntries) / sizeof(_VmServiceIONativeEntries[0]);
  for (intptr_t i = 0; i < n; i++) {
    VmServiceIONativeEntry entry = _VmServiceIONativeEntries[i];
    if ((strcmp(function_name, entry.name) == 0) &&
        (num_arguments == entry.num_arguments)) {
      return entry.function;
    }
  }
  return NULL;
}


const char* VmService::error_msg_ = NULL;
char VmService::server_uri_[kServerUriStringBufferSize];


bool VmService::LoadForGenPrecompiled(void* vmservice_kernel) {
  Dart_Handle result;
  Dart_SetLibraryTagHandler(LibraryTagHandler);
  Dart_Handle library;
  if (vmservice_kernel != NULL) {
    library = Dart_LoadLibrary(
        Dart_NewStringFromCString(kVMServiceIOLibraryUri), Dart_Null(),
        reinterpret_cast<Dart_Handle>(vmservice_kernel), 0, 0);
  } else {
    library = LookupOrLoadLibrary(kVMServiceIOLibraryScriptResourceName);
  }
  ASSERT(library != Dart_Null());
  SHUTDOWN_ON_ERROR(library);
  result = Dart_SetNativeResolver(library, VmServiceIONativeResolver, NULL);
  SHUTDOWN_ON_ERROR(result);
  result = Dart_FinalizeLoading(false);
  SHUTDOWN_ON_ERROR(result);
  return true;
}


bool VmService::Setup(const char* server_ip,
                      intptr_t server_port,
                      bool running_precompiled,
                      bool dev_mode_server,
                      bool trace_loading) {
  Dart_Isolate isolate = Dart_CurrentIsolate();
  ASSERT(isolate != NULL);
  SetServerAddress("");

  Dart_Handle result;

  // Prepare builtin and its dependent libraries for use to resolve URIs.
  // Set up various closures, e.g: printing, timers etc.
  // Set up 'package root' for URI resolution.
  result = DartUtils::PrepareForScriptLoading(true, false);
  SHUTDOWN_ON_ERROR(result);

  if (running_precompiled) {
    Dart_Handle url = DartUtils::NewString(kVMServiceIOLibraryUri);
    Dart_Handle library = Dart_LookupLibrary(url);
    SHUTDOWN_ON_ERROR(library);
    result = Dart_SetRootLibrary(library);
    SHUTDOWN_ON_ERROR(library);
    result = Dart_SetNativeResolver(library, VmServiceIONativeResolver, NULL);
    SHUTDOWN_ON_ERROR(result);
  } else {
    // Load main script.
    Dart_SetLibraryTagHandler(LibraryTagHandler);
    Dart_Handle library = LoadScript(kVMServiceIOLibraryScriptResourceName);
    ASSERT(library != Dart_Null());
    SHUTDOWN_ON_ERROR(library);
    result = Dart_SetNativeResolver(library, VmServiceIONativeResolver, NULL);
    SHUTDOWN_ON_ERROR(result);
    result = Dart_FinalizeLoading(false);
    SHUTDOWN_ON_ERROR(result);
  }

  // Make runnable.
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

  Dart_Handle library = Dart_RootLibrary();
  SHUTDOWN_ON_ERROR(library);

  // Set HTTP server state.
  result = DartUtils::SetStringField(library, "_ip", server_ip);
  SHUTDOWN_ON_ERROR(result);
  // If we have a port specified, start the server immediately.
  bool auto_start = server_port >= 0;
  if (server_port < 0) {
    // Adjust server_port to port 0 which will result in the first available
    // port when the HTTP server is started.
    server_port = 0;
  }
  result = DartUtils::SetIntegerField(library, "_port", server_port);
  SHUTDOWN_ON_ERROR(result);
  result = Dart_SetField(library, DartUtils::NewString("_autoStart"),
                         Dart_NewBoolean(auto_start));
  SHUTDOWN_ON_ERROR(result);
  result = Dart_SetField(library, DartUtils::NewString("_originCheckDisabled"),
                         Dart_NewBoolean(dev_mode_server));

// Are we running on Windows?
#if defined(HOST_OS_WINDOWS)
  Dart_Handle is_windows = Dart_True();
#else
  Dart_Handle is_windows = Dart_False();
#endif
  result =
      Dart_SetField(library, DartUtils::NewString("_isWindows"), is_windows);
  SHUTDOWN_ON_ERROR(result);

// Are we running on Fuchsia?
#if defined(HOST_OS_FUCHSIA)
  Dart_Handle is_fuchsia = Dart_True();
#else
  Dart_Handle is_fuchsia = Dart_False();
#endif
  result =
      Dart_SetField(library, DartUtils::NewString("_isFuchsia"), is_fuchsia);
  SHUTDOWN_ON_ERROR(result);

  if (trace_loading) {
    result = Dart_SetField(library, DartUtils::NewString("_traceLoading"),
                           Dart_True());
    SHUTDOWN_ON_ERROR(result);
  }

  // Get _getWatchSignalInternal from dart:io.
  Dart_Handle dart_io_str = Dart_NewStringFromCString(DartUtils::kIOLibURL);
  SHUTDOWN_ON_ERROR(dart_io_str);
  Dart_Handle io_lib = Dart_LookupLibrary(dart_io_str);
  SHUTDOWN_ON_ERROR(io_lib);
  Dart_Handle function_name =
      Dart_NewStringFromCString("_getWatchSignalInternal");
  SHUTDOWN_ON_ERROR(function_name);
  Dart_Handle signal_watch = Dart_Invoke(io_lib, function_name, 0, NULL);
  SHUTDOWN_ON_ERROR(signal_watch);
  Dart_Handle field_name = Dart_NewStringFromCString("_signalWatch");
  SHUTDOWN_ON_ERROR(field_name);
  result = Dart_SetField(library, field_name, signal_watch);
  SHUTDOWN_ON_ERROR(field_name);
  return true;
}


const char* VmService::GetErrorMessage() {
  return (error_msg_ == NULL) ? "No error." : error_msg_;
}


void VmService::SetServerAddress(const char* server_uri) {
  if (server_uri == NULL) {
    server_uri = "";
  }
  const intptr_t server_uri_len = strlen(server_uri);
  if (server_uri_len >= (kServerUriStringBufferSize - 1)) {
    FATAL1("vm-service: Server URI exceeded length: %s\n", server_uri);
  }
  strncpy(server_uri_, server_uri, kServerUriStringBufferSize);
  server_uri_[kServerUriStringBufferSize - 1] = '\0';
}


Dart_Handle VmService::GetSource(const char* name) {
  const intptr_t kBufferSize = 512;
  char buffer[kBufferSize];
  snprintf(&buffer[0], kBufferSize - 1, "%s/%s", kLibrarySourceNamePrefix,
           name);
  const char* vmservice_source = NULL;
  int r = Resources::ResourceLookup(buffer, &vmservice_source);
  if (r == Resources::kNoSuchInstance) {
    FATAL1("vm-service: Could not find embedded source file: %s ", buffer);
  }
  ASSERT(r != Resources::kNoSuchInstance);
  return Dart_NewStringFromCString(vmservice_source);
}


Dart_Handle VmService::LoadScript(const char* name) {
  Dart_Handle uri = Dart_NewStringFromCString(kVMServiceIOLibraryUri);
  Dart_Handle source = GetSource(name);
  return Dart_LoadScript(uri, Dart_Null(), source, 0, 0);
}


Dart_Handle VmService::LookupOrLoadLibrary(const char* name) {
  Dart_Handle uri = Dart_NewStringFromCString(kVMServiceIOLibraryUri);
  Dart_Handle library = Dart_LookupLibrary(uri);
  if (!Dart_IsLibrary(library)) {
    Dart_Handle source = GetSource(name);
    library = Dart_LoadLibrary(uri, Dart_Null(), source, 0, 0);
  }
  return library;
}


Dart_Handle VmService::LoadSource(Dart_Handle library, const char* name) {
  Dart_Handle uri = Dart_NewStringFromCString(name);
  Dart_Handle source = GetSource(name);
  return Dart_LoadSource(library, uri, Dart_Null(), source, 0, 0);
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
    UNREACHABLE();
    return Dart_Null();
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
  return Dart_LoadSource(library, url, Dart_Null(), source, 0, 0);
}


}  // namespace bin
}  // namespace dart
