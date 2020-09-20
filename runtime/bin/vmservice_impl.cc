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
#include "platform/utils.h"

namespace dart {
namespace bin {

#define RETURN_ERROR_HANDLE(handle)                                            \
  if (Dart_IsError(handle)) {                                                  \
    return handle;                                                             \
  }

#define SHUTDOWN_ON_ERROR(handle)                                              \
  if (Dart_IsError(handle)) {                                                  \
    error_msg_ = Utils::StrDup(Dart_GetError(handle));                         \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return false;                                                              \
  }

static const char* const kVMServiceIOLibraryUri = "dart:vmservice_io";

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

const uint8_t* VmServiceIONativeSymbol(Dart_NativeFunction nf) {
  intptr_t n =
      sizeof(_VmServiceIONativeEntries) / sizeof(_VmServiceIONativeEntries[0]);
  for (intptr_t i = 0; i < n; i++) {
    VmServiceIONativeEntry entry = _VmServiceIONativeEntries[i];
    if (reinterpret_cast<Dart_NativeFunction>(entry.function) == nf) {
      return reinterpret_cast<const uint8_t*>(entry.name);
    }
  }
  return NULL;
}

const char* VmService::error_msg_ = NULL;
char VmService::server_uri_[kServerUriStringBufferSize];

void VmService::SetNativeResolver() {
  Dart_Handle url = DartUtils::NewString(kVMServiceIOLibraryUri);
  Dart_Handle library = Dart_LookupLibrary(url);
  if (!Dart_IsError(library)) {
    Dart_SetNativeResolver(library, VmServiceIONativeResolver,
                           VmServiceIONativeSymbol);
  }
}

bool VmService::Setup(const char* server_ip,
                      intptr_t server_port,
                      bool dev_mode_server,
                      bool auth_codes_disabled,
                      const char* write_service_info_filename,
                      bool trace_loading,
                      bool deterministic,
                      bool enable_service_port_fallback,
                      bool wait_for_dds_to_advertise_service) {
  Dart_Isolate isolate = Dart_CurrentIsolate();
  ASSERT(isolate != NULL);
  SetServerAddress("");

  Dart_Handle result;

  // Prepare builtin and its dependent libraries for use to resolve URIs.
  // Set up various closures, e.g: printing, timers etc.
  // Set up 'package root' for URI resolution.
  result = DartUtils::PrepareForScriptLoading(/*is_service_isolate=*/true,
                                              trace_loading);
  SHUTDOWN_ON_ERROR(result);

  Dart_Handle url = DartUtils::NewString(kVMServiceIOLibraryUri);
  Dart_Handle library = Dart_LookupLibrary(url);
  SHUTDOWN_ON_ERROR(library);
  result = Dart_SetRootLibrary(library);
  SHUTDOWN_ON_ERROR(library);
  result = Dart_SetNativeResolver(library, VmServiceIONativeResolver,
                                  VmServiceIONativeSymbol);
  SHUTDOWN_ON_ERROR(result);

  // Make runnable.
  Dart_ExitScope();
  Dart_ExitIsolate();
  error_msg_ = Dart_IsolateMakeRunnable(isolate);
  if (error_msg_ != NULL) {
    Dart_EnterIsolate(isolate);
    Dart_ShutdownIsolate();
    return false;
  }
  Dart_EnterIsolate(isolate);
  Dart_EnterScope();

  library = Dart_RootLibrary();
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
  SHUTDOWN_ON_ERROR(result);

  result = Dart_SetField(library, DartUtils::NewString("_authCodesDisabled"),
                         Dart_NewBoolean(auth_codes_disabled));
  SHUTDOWN_ON_ERROR(result);

  result =
      Dart_SetField(library, DartUtils::NewString("_enableServicePortFallback"),
                    Dart_NewBoolean(enable_service_port_fallback));
  SHUTDOWN_ON_ERROR(result);

  if (write_service_info_filename != nullptr) {
    result = DartUtils::SetStringField(library, "_serviceInfoFilename",
                                       write_service_info_filename);
    SHUTDOWN_ON_ERROR(result);
  }

  result = Dart_SetField(library,
                         DartUtils::NewString("_waitForDdsToAdvertiseService"),
                         Dart_NewBoolean(wait_for_dds_to_advertise_service));
  SHUTDOWN_ON_ERROR(result);

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

}  // namespace bin
}  // namespace dart
