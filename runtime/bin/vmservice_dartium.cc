// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/vmservice_dartium.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/eventhandler.h"
#include "bin/platform.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/vmservice_impl.h"
#include "zlib/zlib.h"

namespace dart {
namespace bin {

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    fprintf(stderr, "CHECK_RESULT failed: %s", Dart_GetError(result));         \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return 0;                                                                  \
  }

static const char* DART_IPV6_ONLY_FLAG = "DART_IPV6_ONLY";
static const char* DEFAULT_VM_SERVICE_SERVER_IP_V6 = "::1";
static const char* DEFAULT_VM_SERVICE_SERVER_IP_V4 = "127.0.0.1";
static const int DEFAULT_VM_SERVICE_SERVER_PORT = 0;

static bool IsIpv6Only() {
  char* v = getenv(DART_IPV6_ONLY_FLAG);
  if (!v) return 0;
  return v[0] == '1';
}

void VmServiceServer::Bootstrap() {
  if (!Platform::Initialize()) {
    fprintf(stderr, "Platform::Initialize() failed\n");
  }
  DartUtils::SetOriginalWorkingDirectory();
  Thread::InitOnce();
  TimerUtils::InitOnce();
  EventHandler::Start();
}


Dart_Isolate VmServiceServer::CreateIsolate(const uint8_t* snapshot_buffer) {
  ASSERT(snapshot_buffer != NULL);
  // Create the isolate.
  IsolateData* isolate_data =
      new IsolateData(DART_VM_SERVICE_ISOLATE_NAME, NULL, NULL, NULL);
  char* error = 0;
  Dart_Isolate isolate =
      Dart_CreateIsolate(DART_VM_SERVICE_ISOLATE_NAME, "main", snapshot_buffer,
                         NULL, NULL, isolate_data, &error);
  if (!isolate) {
    fprintf(stderr, "Dart_CreateIsolate failed: %s\n", error);
    return 0;
  }

  Dart_EnterScope();
  Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
  Builtin::SetNativeResolver(Builtin::kIOLibrary);

  ASSERT(Dart_IsServiceIsolate(isolate));
  if (!VmService::Setup(
          IsIpv6Only() ? DEFAULT_VM_SERVICE_SERVER_IP_V6 :
                 DEFAULT_VM_SERVICE_SERVER_IP_V4,
          DEFAULT_VM_SERVICE_SERVER_PORT,
          false /* running_precompiled */, false /* disable origin checks */,
          false /* trace_loading */)) {
    fprintf(stderr, "Vmservice::Setup failed: %s\n",
            VmService::GetErrorMessage());
    isolate = NULL;
  }
  Dart_ExitScope();
  Dart_ExitIsolate();
  return isolate;
}


const char* VmServiceServer::GetServerAddress() {
  return VmService::GetServerAddress();
}


void VmServiceServer::DecompressAssets(const uint8_t* input,
                                       unsigned int input_len,
                                       uint8_t** output,
                                       unsigned int* output_length) {
  ASSERT(input != NULL);
  ASSERT(input_len > 0);
  ASSERT(output != NULL);
  ASSERT(output_length != NULL);

  // Initialize output.
  *output = NULL;
  *output_length = 0;

  const unsigned int kChunkSize = 256 * 1024;
  uint8_t chunk_out[kChunkSize];
  z_stream strm;
  strm.zalloc = Z_NULL;
  strm.zfree = Z_NULL;
  strm.opaque = Z_NULL;
  strm.avail_in = 0;
  strm.next_in = 0;
  int ret = inflateInit2(&strm, 32 + MAX_WBITS);
  ASSERT(ret == Z_OK);

  unsigned int input_cursor = 0;
  unsigned int output_cursor = 0;
  do {
    // Setup input.
    unsigned int size_in = input_len - input_cursor;
    if (size_in > kChunkSize) {
      size_in = kChunkSize;
    }
    strm.avail_in = size_in;
    strm.next_in = const_cast<uint8_t*>(&input[input_cursor]);

    // Inflate until we've exhausted the current input chunk.
    do {
      // Setup output.
      strm.avail_out = kChunkSize;
      strm.next_out = &chunk_out[0];
      // Inflate.
      ret = inflate(&strm, Z_SYNC_FLUSH);
      // We either hit the end of the stream or made forward progress.
      ASSERT((ret == Z_STREAM_END) || (ret == Z_OK));
      // Grow output buffer size.
      unsigned int size_out = kChunkSize - strm.avail_out;
      *output_length += size_out;
      *output = reinterpret_cast<uint8_t*>(realloc(*output, *output_length));
      // Copy output.
      memmove(&((*output)[output_cursor]), &chunk_out[0], size_out);
      output_cursor += size_out;
    } while (strm.avail_out == 0);

    // We've processed size_in bytes.
    input_cursor += size_in;

    // We're finished decompressing when zlib tells us.
  } while (ret != Z_STREAM_END);

  inflateEnd(&strm);
}


/* DISALLOW_ALLOCATION */
void VmServiceServer::operator delete(void* pointer) {
  fprintf(stderr, "unreachable code\n");
  abort();
}

}  // namespace bin
}  // namespace dart
