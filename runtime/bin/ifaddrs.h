// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_IFADDRS_H_
#define RUNTIME_BIN_IFADDRS_H_

// On Android getifaddrs API which is only supported directly by
// Bionic starting at API level 24 so we provide our own implementation
// which is API compatible. Otherwise we just include system ifaddrs.h

#if defined(ANDROID) && __ANDROID_API__ < 24
#include <sys/socket.h>

namespace dart {
namespace bin {

struct ifaddrs {
  struct ifaddrs* ifa_next;
  char* ifa_name;
  unsigned int ifa_flags;
  struct sockaddr* ifa_addr;
  struct sockaddr* ifa_netmask;
  union {
    struct sockaddr* ifu_broadaddr;
    struct sockaddr* ifu_dstaddr;
  } ifa_ifu;
  void* ifa_data;
};

void freeifaddrs(struct ifaddrs* __ptr);
int getifaddrs(struct ifaddrs** __list_ptr);

}  // namespace bin
}  // namespace dart

#else

#include <ifaddrs.h>

#endif  // defined(ANDROID) && __ANDROID_API__ < 24

#endif  // RUNTIME_BIN_IFADDRS_H_
