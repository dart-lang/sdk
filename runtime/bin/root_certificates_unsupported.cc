// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_MACOS) || defined(HOST_OS_ANDROID) ||                      \
    defined(DART_IO_ROOT_CERTS_DISABLED)

namespace dart {
namespace bin {

const unsigned char* root_certificates_pem = NULL;
unsigned int root_certificates_pem_length = 0;

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_MACOS) || defined(HOST_OS_ANDROID) || ...

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
