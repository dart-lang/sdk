// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "bin/socket_base.h"

#include "bin/dartutils.h"
#include "bin/io_buffer.h"
#include "bin/isolate_data.h"
#include "bin/lockers.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "include/dart_api.h"

#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(InternetAddress_Parse)(Dart_NativeArguments args) {
  const char* address =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  ASSERT(address != NULL);
  RawAddr raw;
  memset(&raw, 0, sizeof(raw));
  int type = strchr(address, ':') == NULL ? SocketAddress::TYPE_IPV4
                                          : SocketAddress::TYPE_IPV6;
  if (type == SocketAddress::TYPE_IPV4) {
    raw.addr.sa_family = AF_INET;
  } else {
    raw.addr.sa_family = AF_INET6;
  }
  bool ok = SocketBase::ParseAddress(type, address, &raw);
  if (!ok) {
    Dart_SetReturnValue(args, Dart_Null());
  } else {
    Dart_SetReturnValue(args, SocketAddress::ToTypedData(raw));
  }
}


void FUNCTION_NAME(NetworkInterface_ListSupported)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args,
                      Dart_NewBoolean(SocketBase::ListInterfacesSupported()));
}


void FUNCTION_NAME(SocketBase_IsBindError)(Dart_NativeArguments args) {
  intptr_t error_number =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  bool is_bind_error = SocketBase::IsBindError(error_number);
  Dart_SetReturnValue(args, is_bind_error ? Dart_True() : Dart_False());
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_DISABLED)
