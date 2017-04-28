// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SOCKET_BASE_H_
#define RUNTIME_BIN_SOCKET_BASE_H_

#if defined(DART_IO_DISABLED)
#error "socket_base.h can only be included on builds with IO enabled"
#endif

#include "platform/globals.h"
// Declare the OS-specific types ahead of defining the generic class.
#if defined(HOST_OS_ANDROID)
#include "bin/socket_base_android.h"
#elif defined(HOST_OS_FUCHSIA)
#include "bin/socket_base_fuchsia.h"
#elif defined(HOST_OS_LINUX)
#include "bin/socket_base_linux.h"
#elif defined(HOST_OS_MACOS)
#include "bin/socket_base_macos.h"
#elif defined(HOST_OS_WINDOWS)
#include "bin/socket_base_win.h"
#else
#error Unknown target os.
#endif

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/allocation.h"
#include "platform/hashmap.h"

namespace dart {
namespace bin {

union RawAddr {
  struct sockaddr_in in;
  struct sockaddr_in6 in6;
  struct sockaddr_storage ss;
  struct sockaddr addr;
};

class SocketAddress {
 public:
  enum {
    TYPE_ANY = -1,
    TYPE_IPV4,
    TYPE_IPV6,
  };

  enum {
    ADDRESS_LOOPBACK_IP_V4,
    ADDRESS_LOOPBACK_IP_V6,
    ADDRESS_ANY_IP_V4,
    ADDRESS_ANY_IP_V6,
    ADDRESS_FIRST = ADDRESS_LOOPBACK_IP_V4,
    ADDRESS_LAST = ADDRESS_ANY_IP_V6,
  };

  explicit SocketAddress(struct sockaddr* sa);

  ~SocketAddress() {}

  int GetType();

  const char* as_string() const { return as_string_; }
  const RawAddr& addr() const { return addr_; }

  static intptr_t GetAddrLength(const RawAddr& addr);
  static intptr_t GetInAddrLength(const RawAddr& addr);
  static bool AreAddressesEqual(const RawAddr& a, const RawAddr& b);
  static void GetSockAddr(Dart_Handle obj, RawAddr* addr);
  static int16_t FromType(int type);
  static void SetAddrPort(RawAddr* addr, intptr_t port);
  static intptr_t GetAddrPort(const RawAddr& addr);
  static Dart_Handle ToTypedData(const RawAddr& addr);
  static CObjectUint8Array* ToCObject(const RawAddr& addr);

 private:
  char as_string_[INET6_ADDRSTRLEN];
  RawAddr addr_;

  DISALLOW_COPY_AND_ASSIGN(SocketAddress);
};

class InterfaceSocketAddress {
 public:
  InterfaceSocketAddress(struct sockaddr* sa,
                         const char* interface_name,
                         intptr_t interface_index)
      : socket_address_(new SocketAddress(sa)),
        interface_name_(interface_name),
        interface_index_(interface_index) {}

  ~InterfaceSocketAddress() { delete socket_address_; }

  SocketAddress* socket_address() const { return socket_address_; }
  const char* interface_name() const { return interface_name_; }
  int interface_index() const { return interface_index_; }

 private:
  SocketAddress* socket_address_;
  const char* interface_name_;
  intptr_t interface_index_;

  DISALLOW_COPY_AND_ASSIGN(InterfaceSocketAddress);
};

template <typename T>
class AddressList {
 public:
  explicit AddressList(intptr_t count)
      : count_(count), addresses_(new T*[count_]) {}

  ~AddressList() {
    for (intptr_t i = 0; i < count_; i++) {
      delete addresses_[i];
    }
    delete[] addresses_;
  }

  intptr_t count() const { return count_; }
  T* GetAt(intptr_t i) const { return addresses_[i]; }
  void SetAt(intptr_t i, T* addr) { addresses_[i] = addr; }

 private:
  const intptr_t count_;
  T** addresses_;

  DISALLOW_COPY_AND_ASSIGN(AddressList);
};

class SocketBase : public AllStatic {
 public:
  enum SocketRequest {
    kLookupRequest = 0,
    kListInterfacesRequest = 1,
    kReverseLookupRequest = 2,
  };

  enum SocketOpKind {
    kSync,
    kAsync,
  };

  // TODO(dart:io): Convert these to instance methods where possible.
  static bool Initialize();
  static intptr_t Available(intptr_t fd);
  static intptr_t Read(intptr_t fd,
                       void* buffer,
                       intptr_t num_bytes,
                       SocketOpKind sync);
  static intptr_t Write(intptr_t fd,
                        const void* buffer,
                        intptr_t num_bytes,
                        SocketOpKind sync);
  // Send data on a socket. The port to send to is specified in the port
  // component of the passed RawAddr structure. The RawAddr structure is only
  // used for datagram sockets.
  static intptr_t SendTo(intptr_t fd,
                         const void* buffer,
                         intptr_t num_bytes,
                         const RawAddr& addr,
                         SocketOpKind sync);
  static intptr_t RecvFrom(intptr_t fd,
                           void* buffer,
                           intptr_t num_bytes,
                           RawAddr* addr,
                           SocketOpKind sync);
  // Returns true if the given error-number is because the system was not able
  // to bind the socket to a specific IP.
  static bool IsBindError(intptr_t error_number);
  static intptr_t GetPort(intptr_t fd);
  static SocketAddress* GetRemotePeer(intptr_t fd, intptr_t* port);
  static void GetError(intptr_t fd, OSError* os_error);
  static int GetType(intptr_t fd);
  static intptr_t GetStdioHandle(intptr_t num);
  static void Close(intptr_t fd);
  static bool GetNoDelay(intptr_t fd, bool* enabled);
  static bool SetNoDelay(intptr_t fd, bool enabled);
  static bool GetMulticastLoop(intptr_t fd, intptr_t protocol, bool* enabled);
  static bool SetMulticastLoop(intptr_t fd, intptr_t protocol, bool enabled);
  static bool GetMulticastHops(intptr_t fd, intptr_t protocol, int* value);
  static bool SetMulticastHops(intptr_t fd, intptr_t protocol, int value);
  static bool GetBroadcast(intptr_t fd, bool* value);
  static bool SetBroadcast(intptr_t fd, bool value);
  static bool JoinMulticast(intptr_t fd,
                            const RawAddr& addr,
                            const RawAddr& interface,
                            int interfaceIndex);
  static bool LeaveMulticast(intptr_t fd,
                             const RawAddr& addr,
                             const RawAddr& interface,
                             int interfaceIndex);

  // Perform a hostname lookup. Returns a AddressList of SocketAddress's.
  static AddressList<SocketAddress>* LookupAddress(const char* host,
                                                   int type,
                                                   OSError** os_error);

  static bool ReverseLookup(const RawAddr& addr,
                            char* host,
                            intptr_t host_len,
                            OSError** os_error);

  static bool ParseAddress(int type, const char* address, RawAddr* addr);
  static bool FormatNumericAddress(const RawAddr& addr, char* address, int len);

  // Whether ListInterfaces is supported.
  static bool ListInterfacesSupported();

  // List interfaces. Returns a AddressList of InterfaceSocketAddress's.
  static AddressList<InterfaceSocketAddress>* ListInterfaces(
      int type,
      OSError** os_error);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(SocketBase);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SOCKET_BASE_H_
