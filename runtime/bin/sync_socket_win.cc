// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/builtin.h"
#include "bin/log.h"
#include "bin/utils.h"
#include "bin/utils_win.h"

namespace dart {
namespace bin {

SynchronousSocket::SynchronousSocket(intptr_t fd)
    : ReferenceCounted(), fd_(fd), port_(ILLEGAL_PORT) {
  LOG_ERR("SynchronousSocket is unimplemented\n");
  UNIMPLEMENTED();
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


intptr_t SynchronousSocket::CreateBindConnect(const RawAddr& addr,
                                              const RawAddr& source_addr) {
  LOG_ERR("SynchronousSocket::CreateBindConnect is unimplemented\n");
  UNIMPLEMENTED();
  return -1;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)

#endif  // !defined(DART_IO_DISABLED)
