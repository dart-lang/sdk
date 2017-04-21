// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/sync_socket.h"

#include "bin/builtin.h"
#include "bin/log.h"
#include "bin/utils.h"
#include "bin/utils_win.h"

// #define SOCKET_LOG_ERROR 1

// define SOCKET_LOG_ERROR to get log messages only for errors.
#if defined(SOCKET_LOG_ERROR)
#define LOG_ERR(msg, ...)                                                      \
  {                                                                            \
    int err = errno;                                                           \
    Log::PrintErr("Dart Socket ERROR: %s:%d: " msg, __FILE__, __LINE__,        \
                  ##__VA_ARGS__);                                              \
    errno = err;                                                               \
  }
#else
#define LOG_ERR(msg, ...)
#endif  // defined(SOCKET_LOG_ERROR)

namespace dart {
namespace bin {

SynchronousSocket::SynchronousSocket(intptr_t fd) {
  LOG_ERR("SynchronousSocket is unimplemented\n");
  UNIMPLEMENTED();
}


bool SynchronousSocket::Initialize() {
  LOG_ERR("SynchronousSocket::Initialize is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}


void SynchronousSocket::SetClosedFd() {
  LOG_ERR("SynchronousSocket::SetClosedFd is unimplemented\n");
  UNIMPLEMENTED();
}


intptr_t SynchronousSocket::CreateConnect(const RawAddr& addr) {
  LOG_ERR("SynchronousSocket::CreateConnect is unimplemented\n");
  UNIMPLEMENTED();
  return -1;
}


void SynchronousSocket::ShutdownRead(intptr_t fd) {
  LOG_ERR("SynchronousSocket::ShutdownRead is unimplemented\n");
  UNIMPLEMENTED();
}


void SynchronousSocket::ShutdownWrite(intptr_t fd) {
  LOG_ERR("SynchronousSocket::ShutdownWrite is unimplemented\n");
  UNIMPLEMENTED();
}


}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)

#endif  // !defined(DART_IO_DISABLED)
