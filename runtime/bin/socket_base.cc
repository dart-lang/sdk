// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

int SocketAddress::GetType() {
  if (addr_.ss.ss_family == AF_INET6) {
    return TYPE_IPV6;
  }
  return TYPE_IPV4;
}

intptr_t SocketAddress::GetAddrLength(const RawAddr& addr) {
  ASSERT((addr.ss.ss_family == AF_INET) || (addr.ss.ss_family == AF_INET6));
  return (addr.ss.ss_family == AF_INET6) ? sizeof(struct sockaddr_in6)
                                         : sizeof(struct sockaddr_in);
}

intptr_t SocketAddress::GetInAddrLength(const RawAddr& addr) {
  ASSERT((addr.ss.ss_family == AF_INET) || (addr.ss.ss_family == AF_INET6));
  return (addr.ss.ss_family == AF_INET6) ? sizeof(struct in6_addr)
                                         : sizeof(struct in_addr);
}

bool SocketAddress::AreAddressesEqual(const RawAddr& a, const RawAddr& b) {
  if (a.ss.ss_family == AF_INET) {
    if (b.ss.ss_family != AF_INET) {
      return false;
    }
    return memcmp(&a.in.sin_addr, &b.in.sin_addr, sizeof(a.in.sin_addr)) == 0;
  } else if (a.ss.ss_family == AF_INET6) {
    if (b.ss.ss_family != AF_INET6) {
      return false;
    }
    return memcmp(&a.in6.sin6_addr, &b.in6.sin6_addr,
                  sizeof(a.in6.sin6_addr)) == 0;
  } else {
    UNREACHABLE();
    return false;
  }
}

void SocketAddress::GetSockAddr(Dart_Handle obj, RawAddr* addr) {
  Dart_TypedData_Type data_type;
  uint8_t* data = NULL;
  intptr_t len;
  Dart_Handle result = Dart_TypedDataAcquireData(
      obj, &data_type, reinterpret_cast<void**>(&data), &len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  if ((data_type != Dart_TypedData_kUint8) ||
      ((len != sizeof(in_addr)) && (len != sizeof(in6_addr)))) {
    Dart_PropagateError(Dart_NewApiError("Unexpected type for socket address"));
  }
  memset(reinterpret_cast<void*>(addr), 0, sizeof(RawAddr));
  if (len == sizeof(in_addr)) {
    addr->in.sin_family = AF_INET;
    memmove(reinterpret_cast<void*>(&addr->in.sin_addr), data, len);
  } else {
    ASSERT(len == sizeof(in6_addr));
    addr->in6.sin6_family = AF_INET6;
    memmove(reinterpret_cast<void*>(&addr->in6.sin6_addr), data, len);
  }
  Dart_TypedDataReleaseData(obj);
}

int16_t SocketAddress::FromType(int type) {
  if (type == TYPE_ANY) {
    return AF_UNSPEC;
  }
  if (type == TYPE_IPV4) {
    return AF_INET;
  }
  ASSERT((type == TYPE_IPV6) && "Invalid type");
  return AF_INET6;
}

void SocketAddress::SetAddrPort(RawAddr* addr, intptr_t port) {
  if (addr->ss.ss_family == AF_INET) {
    addr->in.sin_port = htons(port);
  } else {
    addr->in6.sin6_port = htons(port);
  }
}

intptr_t SocketAddress::GetAddrPort(const RawAddr& addr) {
  if (addr.ss.ss_family == AF_INET) {
    return ntohs(addr.in.sin_port);
  } else {
    return ntohs(addr.in6.sin6_port);
  }
}

Dart_Handle SocketAddress::ToTypedData(const RawAddr& addr) {
  int len = GetInAddrLength(addr);
  Dart_Handle result = Dart_NewTypedData(Dart_TypedData_kUint8, len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  Dart_Handle err;
  if (addr.addr.sa_family == AF_INET6) {
    err = Dart_ListSetAsBytes(
        result, 0, reinterpret_cast<const uint8_t*>(&addr.in6.sin6_addr), len);
  } else {
    err = Dart_ListSetAsBytes(
        result, 0, reinterpret_cast<const uint8_t*>(&addr.in.sin_addr), len);
  }
  if (Dart_IsError(err)) {
    Dart_PropagateError(err);
  }
  return result;
}

CObjectUint8Array* SocketAddress::ToCObject(const RawAddr& addr) {
  int in_addr_len = SocketAddress::GetInAddrLength(addr);
  const void* in_addr;
  CObjectUint8Array* data =
      new CObjectUint8Array(CObject::NewUint8Array(in_addr_len));
  if (addr.addr.sa_family == AF_INET6) {
    in_addr = reinterpret_cast<const void*>(&addr.in6.sin6_addr);
  } else {
    in_addr = reinterpret_cast<const void*>(&addr.in.sin_addr);
  }
  memmove(data->Buffer(), in_addr, in_addr_len);
  return data;
}

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
