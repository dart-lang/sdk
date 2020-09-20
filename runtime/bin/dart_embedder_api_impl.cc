// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_embedder_api.h"

#include "bin/dartutils.h"
#include "bin/eventhandler.h"
#include "bin/isolate_data.h"
#include "bin/process.h"
#include "bin/secure_socket_filter.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/vmservice_impl.h"

namespace dart {
namespace embedder {

static char* MallocFormatedString(const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t len = vsnprintf(NULL, 0, format, args);
  va_end(args);

  char* buffer = reinterpret_cast<char*>(malloc(len + 1));
  MSAN_UNPOISON(buffer, (len + 1));
  va_list args2;
  va_start(args2, format);
  vsnprintf(buffer, (len + 1), format, args2);
  va_end(args2);
  return buffer;
}

bool InitOnce(char** error) {
  if (!bin::DartUtils::SetOriginalWorkingDirectory()) {
    bin::OSError err;
    *error = MallocFormatedString("Error determining current directory: %s\n",
                                  err.message());
    return false;
  }
  bin::TimerUtils::InitOnce();
  bin::Process::Init();
#if !defined(DART_IO_SECURE_SOCKET_DISABLED)
  bin::SSLFilter::Init();
#endif
  bin::EventHandler::Start();
  return true;
}

void Cleanup() {
  bin::Process::ClearAllSignalHandlers();

  bin::EventHandler::Stop();
#if !defined(DART_IO_SECURE_SOCKET_DISABLED)
  bin::SSLFilter::Cleanup();
#endif
  bin::Process::Cleanup();
}

Dart_Isolate CreateKernelServiceIsolate(const IsolateCreationData& data,
                                        const uint8_t* buffer,
                                        intptr_t buffer_size,
                                        char** error) {
  Dart_Isolate kernel_isolate = Dart_CreateIsolateGroupFromKernel(
      data.script_uri, data.main, buffer, buffer_size, data.flags,
      data.isolate_group_data, data.isolate_data, error);
  if (kernel_isolate == nullptr) {
    return nullptr;
  }

  Dart_EnterScope();
  Dart_Handle result = Dart_LoadScriptFromKernel(buffer, buffer_size);
  if (Dart_IsError(result)) {
    *error = Utils::StrDup(Dart_GetError(result));
    Dart_ExitScope();
    Dart_ShutdownIsolate();
    return nullptr;
  }
  result = bin::DartUtils::PrepareForScriptLoading(/*is_service_isolate=*/false,
                                                   /*trace_loading=*/false);
  Dart_ExitScope();
  Dart_ExitIsolate();
  return kernel_isolate;
}

Dart_Isolate CreateVmServiceIsolate(const IsolateCreationData& data,
                                    const VmServiceConfiguration& config,
                                    const uint8_t* isolate_data,
                                    const uint8_t* isolate_instr,
                                    char** error) {
  if (data.flags == nullptr) {
    *error = Utils::StrDup("Expected non-null flags");
    return nullptr;
  }
  data.flags->load_vmservice_library = true;

  Dart_Isolate service_isolate = Dart_CreateIsolateGroup(
      data.script_uri, data.main, isolate_data, isolate_instr, data.flags,
      data.isolate_group_data, data.isolate_data, error);
  if (service_isolate == nullptr) {
    return nullptr;
  }

  Dart_EnterScope();
  // Load embedder specific bits and return.
  if (!bin::VmService::Setup(config.ip, config.port, config.dev_mode,
                             config.disable_auth_codes,
                             config.write_service_info_filename,
                             /*trace_loading=*/false, config.deterministic,
                             /*enable_service_port_fallback=*/false,
                             /*wait_for_dds_to_advertise_service=*/false)) {
    *error = Utils::StrDup(bin::VmService::GetErrorMessage());
    return nullptr;
  }

  Dart_ExitScope();
  Dart_ExitIsolate();
  return service_isolate;
}

Dart_Isolate CreateVmServiceIsolateFromKernel(
    const IsolateCreationData& data,
    const VmServiceConfiguration& config,
    const uint8_t* kernel_buffer,
    intptr_t kernel_buffer_size,
    char** error) {
  if (data.flags == nullptr) {
    *error = Utils::StrDup("Expected non-null flags");
    return nullptr;
  }
  data.flags->load_vmservice_library = true;

  Dart_Isolate service_isolate = Dart_CreateIsolateGroupFromKernel(
      data.script_uri, data.main, kernel_buffer, kernel_buffer_size, data.flags,
      data.isolate_group_data, data.isolate_data, error);
  if (service_isolate == nullptr) {
    return nullptr;
  }

  Dart_EnterScope();
  // Load embedder specific bits and return.
  if (!bin::VmService::Setup(config.ip, config.port, config.dev_mode,
                             config.disable_auth_codes,
                             config.write_service_info_filename,
                             /*trace_loading=*/false, config.deterministic,
                             /*enable_service_port_fallback=*/false,
                             /*wait_for_dds_to_advertise_service=*/false)) {
    *error = Utils::StrDup(bin::VmService::GetErrorMessage());
    return nullptr;
  }

  Dart_ExitScope();
  Dart_ExitIsolate();
  return service_isolate;
}

}  // namespace embedder
}  // namespace dart
