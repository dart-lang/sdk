// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/bin/dart_io_api.h"

#include "bin/crypto.h"
#include "bin/directory.h"
#include "bin/eventhandler.h"
#include "bin/io_natives.h"
#include "bin/platform.h"
#include "bin/process.h"
#if !defined(DART_IO_SECURE_SOCKET_DISABLED)
  #include "bin/secure_socket_filter.h"
#endif
#include "bin/thread.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

void BootstrapDartIo() {
  // Bootstrap 'dart:io' event handler.
  TimerUtils::InitOnce();
  Process::Init();
#if !defined(DART_IO_SECURE_SOCKET_DISABLED)
  SSLFilter::Init();
#endif
  EventHandler::Start();
}

void CleanupDartIo() {
  EventHandler::Stop();
#if !defined(DART_IO_SECURE_SOCKET_DISABLED)
  SSLFilter::Cleanup();
#endif
  Process::Cleanup();
}

void SetSystemTempDirectory(const char* system_temp) {
  Directory::SetSystemTemp(system_temp);
}

void SetExecutableName(const char* executable_name) {
  Platform::SetExecutableName(executable_name);
}

void SetExecutableArguments(int script_index, char** argv) {
  Platform::SetExecutableArguments(script_index, argv);
}

void GetIOEmbedderInformation(Dart_EmbedderInformation* info) {
  ASSERT(info != NULL);
  ASSERT(info->version == DART_EMBEDDER_INFORMATION_CURRENT_VERSION);

  Process::GetRSSInformation(&(info->max_rss), &(info->current_rss));
}

bool GetEntropy(uint8_t* buffer, intptr_t length) {
  return Crypto::GetRandomBytes(length, buffer);
}

Dart_NativeFunction LookupIONative(Dart_Handle name,
                                   int argument_count,
                                   bool* auto_setup_scope) {
  return IONativeLookup(name, argument_count, auto_setup_scope);
}

const uint8_t* LookupIONativeSymbol(Dart_NativeFunction nf) {
  return IONativeSymbol(nf);
}

}  // namespace bin
}  // namespace dart
