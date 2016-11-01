// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SOCKET_H_
#define RUNTIME_BIN_SOCKET_H_

#if defined(DART_IO_DISABLED)
#error "socket.h can only be included on builds with IO enabled"
#endif

#include "platform/globals.h"
// Declare the OS-specific types ahead of defining the generic class.
#if defined(TARGET_OS_ANDROID)
#include "bin/socket_android.h"
#elif defined(TARGET_OS_FUCHSIA)
#include "bin/socket_fuchsia.h"
#elif defined(TARGET_OS_LINUX)
#include "bin/socket_linux.h"
#elif defined(TARGET_OS_MACOS)
#include "bin/socket_macos.h"
#elif defined(TARGET_OS_WINDOWS)
#include "bin/socket_win.h"
#else
#error Unknown target os.
#endif

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/thread.h"
#include "bin/utils.h"
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

  int GetType() {
    if (addr_.ss.ss_family == AF_INET6) {
      return TYPE_IPV6;
    }
    return TYPE_IPV4;
  }

  const char* as_string() const { return as_string_; }
  const RawAddr& addr() const { return addr_; }

  static intptr_t GetAddrLength(const RawAddr& addr) {
    ASSERT((addr.ss.ss_family == AF_INET) || (addr.ss.ss_family == AF_INET6));
    return (addr.ss.ss_family == AF_INET6) ?
        sizeof(struct sockaddr_in6) : sizeof(struct sockaddr_in);
  }

  static intptr_t GetInAddrLength(const RawAddr& addr) {
    ASSERT((addr.ss.ss_family == AF_INET) || (addr.ss.ss_family == AF_INET6));
    return (addr.ss.ss_family == AF_INET6) ?
        sizeof(struct in6_addr) : sizeof(struct in_addr);
  }

  static bool AreAddressesEqual(const RawAddr& a, const RawAddr& b) {
    if (a.ss.ss_family == AF_INET) {
      if (b.ss.ss_family != AF_INET) {
        return false;
      }
      return memcmp(&a.in.sin_addr, &b.in.sin_addr, sizeof(a.in.sin_addr)) == 0;
    } else if (a.ss.ss_family == AF_INET6) {
      if (b.ss.ss_family != AF_INET6) {
        return false;
      }
      return memcmp(&a.in6.sin6_addr,
                    &b.in6.sin6_addr,
                    sizeof(a.in6.sin6_addr)) == 0;
    } else {
      UNREACHABLE();
      return false;
    }
  }

  static void GetSockAddr(Dart_Handle obj, RawAddr* addr) {
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
      Dart_PropagateError(
          Dart_NewApiError("Unexpected type for socket address"));
    }
    memset(reinterpret_cast<void*>(addr), 0, sizeof(RawAddr));
    if (len == sizeof(in_addr)) {
      addr->in.sin_family = AF_INET;
      memmove(reinterpret_cast<void *>(&addr->in.sin_addr), data, len);
    } else {
      ASSERT(len == sizeof(in6_addr));
      addr->in6.sin6_family = AF_INET6;
      memmove(reinterpret_cast<void*>(&addr->in6.sin6_addr), data, len);
    }
    Dart_TypedDataReleaseData(obj);
  }

  static int16_t FromType(int type) {
    if (type == TYPE_ANY) {
      return AF_UNSPEC;
    }
    if (type == TYPE_IPV4) {
      return AF_INET;
    }
    ASSERT((type == TYPE_IPV6) && "Invalid type");
    return AF_INET6;
  }

  static void SetAddrPort(RawAddr* addr, intptr_t port) {
    if (addr->ss.ss_family == AF_INET) {
      addr->in.sin_port = htons(port);
    } else {
      addr->in6.sin6_port = htons(port);
    }
  }

  static intptr_t GetAddrPort(const RawAddr& addr) {
    if (addr.ss.ss_family == AF_INET) {
      return ntohs(addr.in.sin_port);
    } else {
      return ntohs(addr.in6.sin6_port);
    }
  }

  static Dart_Handle ToTypedData(const RawAddr& addr) {
    int len = GetInAddrLength(addr);
    Dart_Handle result = Dart_NewTypedData(Dart_TypedData_kUint8, len);
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    Dart_Handle err;
    if (addr.addr.sa_family == AF_INET6) {
      err = Dart_ListSetAsBytes(
          result, 0,
          reinterpret_cast<const uint8_t*>(&addr.in6.sin6_addr), len);
    } else {
      err = Dart_ListSetAsBytes(
          result, 0, reinterpret_cast<const uint8_t*>(&addr.in.sin_addr), len);
    }
    if (Dart_IsError(err)) {
      Dart_PropagateError(err);
    }
    return result;
  }

  static CObjectUint8Array* ToCObject(const RawAddr& addr) {
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

  ~InterfaceSocketAddress() {
    delete socket_address_;
  }

  SocketAddress* socket_address() const { return socket_address_; }
  const char* interface_name() const { return interface_name_; }
  int interface_index() const { return interface_index_; }

 private:
  SocketAddress* socket_address_;
  const char* interface_name_;
  intptr_t interface_index_;

  DISALLOW_COPY_AND_ASSIGN(InterfaceSocketAddress);
};


template<typename T>
class AddressList {
 public:
  explicit AddressList(intptr_t count)
      : count_(count),
        addresses_(new T*[count_]) {}

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


class Socket {
 public:
  enum SocketRequest {
    kLookupRequest = 0,
    kListInterfacesRequest = 1,
    kReverseLookupRequest = 2,
  };

  static bool Initialize();
  static intptr_t Available(intptr_t fd);
  static intptr_t Read(intptr_t fd, void* buffer, intptr_t num_bytes);
  static intptr_t Write(intptr_t fd, const void* buffer, intptr_t num_bytes);
  // Send data on a socket. The port to send to is specified in the port
  // component of the passed RawAddr structure. The RawAddr structure is only
  // used for datagram sockets.
  static intptr_t SendTo(
      intptr_t fd, const void* buffer, intptr_t num_bytes, const RawAddr& addr);
  static intptr_t RecvFrom(
      intptr_t fd, void* buffer, intptr_t num_bytes, RawAddr* addr);
  // Creates a socket which is bound and connected. The port to connect to is
  // specified as the port component of the passed RawAddr structure.
  static intptr_t CreateConnect(const RawAddr& addr);
  // Creates a socket which is bound and connected. The port to connect to is
  // specified as the port component of the passed RawAddr structure.
  static intptr_t CreateBindConnect(const RawAddr& addr,
                                    const RawAddr& source_addr);
  // Returns true if the given error-number is because the system was not able
  // to bind the socket to a specific IP.
  static bool IsBindError(intptr_t error_number);
  // Creates a datagram socket which is bound. The port to bind
  // to is specified as the port component of the RawAddr structure.
  static intptr_t CreateBindDatagram(const RawAddr& addr, bool reuseAddress);
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

  static CObject* LookupRequest(const CObjectArray& request);
  static CObject* ListInterfacesRequest(const CObjectArray& request);
  static CObject* ReverseLookupRequest(const CObjectArray& request);

  static Dart_Port GetServicePort();

  static void SetSocketIdNativeField(Dart_Handle socket, intptr_t id);
  static intptr_t GetSocketIdNativeField(Dart_Handle socket);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Socket);
};


class ServerSocket {
 public:
  static const intptr_t kTemporaryFailure = -2;

  static intptr_t Accept(intptr_t fd);

  // Creates a socket which is bound and listens. The port to listen on is
  // specified in the port component of the passed RawAddr structure.
  //
  // Returns a positive integer if the call is successful. In case of failure
  // it returns:
  //
  //   -1: system error (errno set)
  //   -5: invalid bindAddress
  static intptr_t CreateBindListen(const RawAddr& addr,
                                   intptr_t backlog,
                                   bool v6_only = false);

  // Start accepting on a newly created listening socket. If it was unable to
  // start accepting incoming sockets, the fd is invalidated.
  static bool StartAccept(intptr_t fd);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ServerSocket);
};


class ListeningSocketRegistry {
 public:
  ListeningSocketRegistry() :
      sockets_by_port_(SameIntptrValue, kInitialSocketsCount),
      sockets_by_fd_(SameIntptrValue, kInitialSocketsCount),
      mutex_(new Mutex()) {}

  ~ListeningSocketRegistry() {
    CloseAllSafe();
    delete mutex_;
    mutex_ = NULL;
  }

  static void Initialize();

  static ListeningSocketRegistry *Instance();

  static void Cleanup();

  // This function should be called from a dart runtime call in order to create
  // a new (potentially shared) socket.
  Dart_Handle CreateBindListen(Dart_Handle socket_object,
                               RawAddr addr,
                               intptr_t backlog,
                               bool v6_only,
                               bool shared);

  // This should be called from the event handler for every kCloseEvent it gets
  // on listening sockets.
  //
  // Returns `true` if the last reference has been dropped and the underlying
  // socket can be closed.
  //
  // The caller is responsible for obtaining the mutex first, before calling
  // this function.
  bool CloseSafe(intptr_t socketfd);

  Mutex *mutex() { return mutex_; }

 private:
  struct OSSocket {
    RawAddr address;
    int port;
    bool v6_only;
    bool shared;
    int ref_count;
    intptr_t socketfd;

    // Singly linked lists of OSSocket instances which listen on the same port
    // but on different addresses.
    OSSocket *next;

    OSSocket(RawAddr address, int port, bool v6_only, bool shared,
             intptr_t socketfd)
        : address(address), port(port), v6_only(v6_only), shared(shared),
          ref_count(0), socketfd(socketfd), next(NULL) {}
  };

  static const intptr_t kInitialSocketsCount = 8;

  OSSocket *findOSSocketWithAddress(OSSocket *current, const RawAddr& addr) {
    while (current != NULL) {
      if (SocketAddress::AreAddressesEqual(current->address, addr)) {
        return current;
      }
      current = current->next;
    }
    return NULL;
  }

  static bool SameIntptrValue(void* key1, void* key2) {
    return reinterpret_cast<intptr_t>(key1) == reinterpret_cast<intptr_t>(key2);
  }

  static uint32_t GetHashmapHashFromIntptr(intptr_t i) {
    return static_cast<uint32_t>((i + 1) & 0xFFFFFFFF);
  }


  static void* GetHashmapKeyFromIntptr(intptr_t i) {
    return reinterpret_cast<void*>(i + 1);
  }

  OSSocket* LookupByPort(intptr_t port);
  void InsertByPort(intptr_t port, OSSocket* socket);
  void RemoveByPort(intptr_t port);

  OSSocket* LookupByFd(intptr_t fd);
  void InsertByFd(intptr_t fd, OSSocket* socket);
  void RemoveByFd(intptr_t fd);

  bool CloseOneSafe(OSSocket* os_socket);
  void CloseAllSafe();

  HashMap sockets_by_port_;
  HashMap sockets_by_fd_;

  Mutex *mutex_;

  DISALLOW_COPY_AND_ASSIGN(ListeningSocketRegistry);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SOCKET_H_
