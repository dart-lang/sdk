// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/socket_base.h"

#include "bin/dartutils.h"
#include "bin/io_buffer.h"
#include "bin/isolate_data.h"
#include "bin/lockers.h"
#include "bin/thread.h"
#include "bin/typed_data_utils.h"
#include "bin/utils.h"

#include "include/dart_api.h"

#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

int SocketAddress::GetType() {
  switch (addr_.ss.ss_family) {
    case AF_INET6:
      return TYPE_IPV6;
    case AF_INET:
      return TYPE_IPV4;
    case AF_UNIX:
      return TYPE_UNIX;
    default:
      UNREACHABLE();
      return TYPE_ANY;
  }
}

intptr_t SocketAddress::GetAddrLength(const RawAddr& addr) {
  ASSERT((addr.ss.ss_family == AF_INET) || (addr.ss.ss_family == AF_INET6) ||
         (addr.ss.ss_family == AF_UNIX));
  switch (addr.ss.ss_family) {
    case AF_INET6:
      return sizeof(struct sockaddr_in6);
    case AF_INET:
      return sizeof(struct sockaddr_in);
    case AF_UNIX:
      return sizeof(struct sockaddr_un);
    default:
      UNREACHABLE();
      return 0;
  }
}

intptr_t SocketAddress::GetInAddrLength(const RawAddr& addr) {
  ASSERT((addr.ss.ss_family == AF_INET) || (addr.ss.ss_family == AF_INET6));
  return (addr.ss.ss_family == AF_INET6) ? sizeof(struct in6_addr)
                                         : sizeof(struct in_addr);
}

bool SocketAddress::AreAddressesEqual(const RawAddr& a, const RawAddr& b) {
  if (a.ss.ss_family != b.ss.ss_family) {
    return false;
  }
  if (a.ss.ss_family == AF_INET) {
    return memcmp(&a.in.sin_addr, &b.in.sin_addr, sizeof(a.in.sin_addr)) == 0;
  } else if (a.ss.ss_family == AF_INET6) {
    return memcmp(&a.in6.sin6_addr, &b.in6.sin6_addr,
                  sizeof(a.in6.sin6_addr)) == 0 &&
           a.in6.sin6_scope_id == b.in6.sin6_scope_id;
  } else if (a.ss.ss_family == AF_UNIX) {
    // This is not used anywhere. The comparison of file path is done via
    // File::AreIdentical().
    int len = sizeof(a.un.sun_path);
    for (int i = 0; i < len; i++) {
      if (a.un.sun_path[i] != b.un.sun_path[i]) return false;
      if (a.un.sun_path[i] == '\0') return true;
    }
    return true;
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

Dart_Handle SocketAddress::GetUnixDomainSockAddr(const char* path,
                                                 Namespace* namespc,
                                                 RawAddr* addr) {
#if defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
  NamespaceScope ns(namespc, path);
  path = ns.path();
  bool is_abstract = (path[0] == '@');
  if (is_abstract) {
    // The following 107 bytes after the leading null byte represents the name
    // of unix domain socket. Without reseting, even users provide the same path
    // for bind and connect, they actually represent two different address and
    // connection will be rejected.
    bzero(addr->un.sun_path, sizeof(addr->un.sun_path));
  }
#endif  // defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
  if (sizeof(path) > sizeof(addr->un.sun_path)) {
    OSError os_error(-1,
                     "The length of path exceeds the limit. "
                     "Check out man 7 unix page",
                     OSError::kUnknown);
    return DartUtils::NewDartOSError(&os_error);
  }
  addr->un.sun_family = AF_UNIX;
  Utils::SNPrint(addr->un.sun_path, sizeof(addr->un.sun_path), "%s", path);
#if defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
  // In case of abstract namespace, transfer the leading '@' into a null byte.
  if (is_abstract) {
    addr->un.sun_path[0] = '\0';
  }
#endif  // defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
  return Dart_Null();
}

int16_t SocketAddress::FromType(int type) {
  if (type == TYPE_ANY) {
    return AF_UNSPEC;
  }
  if (type == TYPE_IPV4) {
    return AF_INET;
  }
  if (type == TYPE_UNIX) {
    return AF_UNIX;
  }
  ASSERT((type == TYPE_IPV6) && "Invalid type");
  return AF_INET6;
}

void SocketAddress::SetAddrPort(RawAddr* addr, intptr_t port) {
  if (addr->ss.ss_family == AF_INET) {
    addr->in.sin_port = htons(port);
  } else if (addr->ss.ss_family == AF_INET6) {
    addr->in6.sin6_port = htons(port);
  } else {
    UNREACHABLE();
  }
}

intptr_t SocketAddress::GetAddrPort(const RawAddr& addr) {
  if (addr.ss.ss_family == AF_INET) {
    return ntohs(addr.in.sin_port);
  } else if (addr.ss.ss_family == AF_INET6) {
    return ntohs(addr.in6.sin6_port);
  } else if (addr.ss.ss_family == AF_UNIX) {
    return 0;
  } else {
    UNREACHABLE();
    return -1;
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
void SocketAddress::SetAddrScope(RawAddr* addr, intptr_t scope_id) {
  if (addr->addr.sa_family != AF_INET6) return;
  addr->in6.sin6_scope_id = scope_id;
}

intptr_t SocketAddress::GetAddrScope(const RawAddr& addr) {
  if (addr.addr.sa_family == AF_INET6) {
    return addr.in6.sin6_scope_id;
  } else {
    return 0;
  }
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

void FUNCTION_NAME(InternetAddress_ParseScopedLinkLocalAddress)(
    Dart_NativeArguments args) {
  const char* address =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 0));
  // This must be an IPv6 address.
  intptr_t type = 1;
  ASSERT(address != NULL);
  OSError* os_error = NULL;
  AddressList<SocketAddress>* addresses =
      SocketBase::LookupAddress(address, type, &os_error);
  if (addresses != NULL) {
    SocketAddress* addr = addresses->GetAt(0);
    Dart_SetReturnValue(
        args, Dart_NewInteger(SocketAddress::GetAddrScope(addr->addr())));
    delete addresses;
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(os_error));
    delete os_error;
  }
}

void FUNCTION_NAME(InternetAddress_RawAddrToString)(Dart_NativeArguments args) {
  RawAddr addr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 0), &addr);
  // INET6_ADDRSTRLEN is larger than INET_ADDRSTRLEN
  char str[INET6_ADDRSTRLEN];
  bool ok = SocketBase::RawAddrToString(&addr, str);
  if (!ok) {
    str[0] = '\0';
  }
  Dart_SetReturnValue(args, ThrowIfError(DartUtils::NewString(str)));
}

void FUNCTION_NAME(NetworkInterface_ListSupported)(Dart_NativeArguments args) {
  Dart_SetBooleanReturnValue(args, SocketBase::ListInterfacesSupported());
}

void FUNCTION_NAME(SocketBase_IsBindError)(Dart_NativeArguments args) {
  intptr_t error_number =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  bool is_bind_error = SocketBase::IsBindError(error_number);
  Dart_SetBooleanReturnValue(args, is_bind_error ? true : false);
}

}  // namespace bin
}  // namespace dart
