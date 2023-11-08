// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/socket.h"

#include "bin/dartutils.h"
#include "bin/eventhandler.h"
#include "bin/file.h"
#include "bin/io_buffer.h"
#include "bin/isolate_data.h"
#include "bin/lockers.h"
#include "bin/process.h"
#include "bin/thread.h"
#include "bin/typed_data_utils.h"
#include "bin/utils.h"

#include "include/dart_api.h"

#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

static constexpr int kSocketIdNativeField = 0;

ListeningSocketRegistry* globalTcpListeningSocketRegistry = nullptr;

bool Socket::short_socket_read_ = false;
bool Socket::short_socket_write_ = false;

void ListeningSocketRegistry::Initialize() {
  ASSERT(globalTcpListeningSocketRegistry == nullptr);
  globalTcpListeningSocketRegistry = new ListeningSocketRegistry();
}

ListeningSocketRegistry* ListeningSocketRegistry::Instance() {
  return globalTcpListeningSocketRegistry;
}

void ListeningSocketRegistry::Cleanup() {
  delete globalTcpListeningSocketRegistry;
  globalTcpListeningSocketRegistry = nullptr;
}

ListeningSocketRegistry::OSSocket* ListeningSocketRegistry::LookupByPort(
    intptr_t port) {
  SimpleHashMap::Entry* entry = sockets_by_port_.Lookup(
      GetHashmapKeyFromIntptr(port), GetHashmapHashFromIntptr(port), false);
  if (entry == nullptr) {
    return nullptr;
  }
  return reinterpret_cast<OSSocket*>(entry->value);
}

void ListeningSocketRegistry::InsertByPort(intptr_t port, OSSocket* socket) {
  SimpleHashMap::Entry* entry = sockets_by_port_.Lookup(
      GetHashmapKeyFromIntptr(port), GetHashmapHashFromIntptr(port), true);
  ASSERT(entry != nullptr);
  entry->value = reinterpret_cast<void*>(socket);
}

void ListeningSocketRegistry::RemoveByPort(intptr_t port) {
  sockets_by_port_.Remove(GetHashmapKeyFromIntptr(port),
                          GetHashmapHashFromIntptr(port));
}

ListeningSocketRegistry::OSSocket* ListeningSocketRegistry::LookupByFd(
    Socket* fd) {
  SimpleHashMap::Entry* entry = sockets_by_fd_.Lookup(
      GetHashmapKeyFromIntptr(reinterpret_cast<intptr_t>(fd)),
      GetHashmapHashFromIntptr(reinterpret_cast<intptr_t>(fd)), false);
  if (entry == nullptr) {
    return nullptr;
  }
  return reinterpret_cast<OSSocket*>(entry->value);
}

void ListeningSocketRegistry::InsertByFd(Socket* fd, OSSocket* socket) {
  SimpleHashMap::Entry* entry = sockets_by_fd_.Lookup(
      GetHashmapKeyFromIntptr(reinterpret_cast<intptr_t>(fd)),
      GetHashmapHashFromIntptr(reinterpret_cast<intptr_t>(fd)), true);
  ASSERT(entry != nullptr);
  entry->value = reinterpret_cast<void*>(socket);
}

void ListeningSocketRegistry::RemoveByFd(Socket* fd) {
  sockets_by_fd_.Remove(
      GetHashmapKeyFromIntptr(reinterpret_cast<intptr_t>(fd)),
      GetHashmapHashFromIntptr(reinterpret_cast<intptr_t>(fd)));
}

Dart_Handle ListeningSocketRegistry::CreateBindListen(Dart_Handle socket_object,
                                                      RawAddr addr,
                                                      intptr_t backlog,
                                                      bool v6_only,
                                                      bool shared) {
  MutexLocker ml(&mutex_);

  OSSocket* first_os_socket = nullptr;
  intptr_t port = SocketAddress::GetAddrPort(addr);
  if (port > 0) {
    first_os_socket = LookupByPort(port);
    if (first_os_socket != nullptr) {
      // There is already a socket listening on this port. We need to ensure
      // that if there is one also listening on the same address, it was created
      // with `shared = true`, ...
      OSSocket* os_socket = first_os_socket;
      OSSocket* os_socket_same_addr = FindOSSocketWithAddress(os_socket, addr);

      if (os_socket_same_addr != nullptr) {
        if (!os_socket_same_addr->shared || !shared) {
          OSError os_error(-1,
                           "The shared flag to bind() needs to be `true` if "
                           "binding multiple times on the same (address, port) "
                           "combination.",
                           OSError::kUnknown);
          return DartUtils::NewDartOSError(&os_error);
        }
        if (os_socket_same_addr->v6_only != v6_only) {
          OSError os_error(-1,
                           "The v6Only flag to bind() needs to be the same if "
                           "binding multiple times on the same (address, port) "
                           "combination.",
                           OSError::kUnknown);
          return DartUtils::NewDartOSError(&os_error);
        }

        // This socket creation is the exact same as the one which originally
        // created the socket. Feed same fd and store it into native field
        // of dart socket_object. Sockets here will share same fd but contain a
        // different port() through EventHandler_SendData.
        Socket* socketfd = new Socket(os_socket_same_addr->fd);
        os_socket_same_addr->ref_count++;
        // We set as a side-effect the file descriptor on the dart
        // socket_object.
        Socket::ReuseSocketIdNativeField(socket_object, socketfd,
                                         Socket::kFinalizerListening);
        InsertByFd(socketfd, os_socket_same_addr);
        return Dart_True();
      }
    }
  }

  // There is no socket listening on that (address, port), so we create new one.
  intptr_t fd = ServerSocket::CreateBindListen(addr, backlog, v6_only);
  if (fd == -5) {
    OSError os_error(-1, "Invalid host", OSError::kUnknown);
    return DartUtils::NewDartOSError(&os_error);
  }
  if (fd < 0) {
    OSError error;
    return DartUtils::NewDartOSError(&error);
  }
  if (!ServerSocket::StartAccept(fd)) {
    OSError os_error(-1, "Failed to start accept", OSError::kUnknown);
    return DartUtils::NewDartOSError(&os_error);
  }
  intptr_t allocated_port = SocketBase::GetPort(fd);
  ASSERT(allocated_port > 0);

  if (allocated_port != port) {
    // There are two cases to consider:
    //
    //   a) The user requested (address, port) where port != 0 which means
    //      we re-use an existing socket if available (and it is shared) or we
    //      create a new one. The new socket is guaranteed to have that
    //      selected port.
    //
    //   b) The user requested (address, 0). This will make us *always* create a
    //      new socket. The OS will assign it a new `allocated_port` and we will
    //      insert into our data structures. *BUT* There might already be an
    //      existing (address2, `allocated_port`) where address != address2. So
    //      we need to do another `LookupByPort(allocated_port)` and link them
    //      via `OSSocket->next`.
    ASSERT(port == 0);
    first_os_socket = LookupByPort(allocated_port);
  }

  Socket* socketfd = new Socket(fd);
  OSSocket* os_socket =
      new OSSocket(addr, allocated_port, v6_only, shared, socketfd, nullptr);
  os_socket->ref_count = 1;
  os_socket->next = first_os_socket;

  InsertByPort(allocated_port, os_socket);
  InsertByFd(socketfd, os_socket);

  // We set as a side-effect the port on the dart socket_object.
  Socket::ReuseSocketIdNativeField(socket_object, socketfd,
                                   Socket::kFinalizerListening);

  return Dart_True();
}

Dart_Handle ListeningSocketRegistry::CreateUnixDomainBindListen(
    Dart_Handle socket_object,
    Namespace* namespc,
    const char* path,
    intptr_t backlog,
    bool shared) {
  MutexLocker ml(&mutex_);

  RawAddr addr;
  Dart_Handle result =
      SocketAddress::GetUnixDomainSockAddr(path, namespc, &addr);
  if (!Dart_IsNull(result)) {
    return result;
  }

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
  // Abstract unix domain socket doesn't exist in file system.
  if (File::Exists(namespc, addr.un.sun_path) && path[0] != '@') {
#else
  if (File::Exists(namespc, addr.un.sun_path)) {
#endif  // defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
    if (unix_domain_sockets_ != nullptr) {
      // If there is a socket listening on this file. Ensure
      // that it was created with `shared` mode and current `shared`
      // is also true.
      OSSocket* os_socket = unix_domain_sockets_;
      OSSocket* os_socket_same_addr =
          FindOSSocketWithPath(os_socket, namespc, addr.un.sun_path);
      if (os_socket_same_addr != nullptr) {
        if (!os_socket_same_addr->shared || !shared) {
          OSError os_error(-1,
                           "The shared flag to bind() needs to be `true` if "
                           "binding multiple times on the same path.",
                           OSError::kUnknown);
          return DartUtils::NewDartOSError(&os_error);
        }

        // This socket creation is the exact same as the one which originally
        // created the socket. Feed the same fd and store it into the native
        // field of dart socket_object. Sockets here will share same fd but
        // contain a different port() through EventHandler_SendData.
        Socket* socketfd = new Socket(os_socket_same_addr->fd);
        os_socket_same_addr->ref_count++;
        // We set as a side-effect the file descriptor on the dart
        // socket_object.
        Socket::ReuseSocketIdNativeField(socket_object, socketfd,
                                         Socket::kFinalizerListening);
        InsertByFd(socketfd, os_socket_same_addr);
        return Dart_True();
      }
    }
    // Unix domain socket by default doesn't allow binding to an existing file.
    // An error (EADDRINUSE) will be returned back. However, hanging is noticed
    // on Android so we throw an exception for all platforms.
    OSError os_error(-1, "File exists with given unix domain address",
                     OSError::kUnknown);
    return DartUtils::NewDartOSError(&os_error);
  }

  // There is no socket listening on that path, so we create new one.
  intptr_t fd = ServerSocket::CreateUnixDomainBindListen(addr, backlog);

  if (fd < 0) {
    return DartUtils::NewDartOSError();
  }

  Socket* socketfd = new Socket(fd);
  OSSocket* os_socket =
      new OSSocket(addr, -1, false, shared, socketfd, namespc);
  os_socket->ref_count = 1;
  os_socket->next = unix_domain_sockets_;
  unix_domain_sockets_ = os_socket;
  InsertByFd(socketfd, os_socket);

  Socket::ReuseSocketIdNativeField(socket_object, socketfd,
                                   Socket::kFinalizerListening);

  return Dart_True();
}

bool ListeningSocketRegistry::CloseOneSafe(OSSocket* os_socket,
                                           Socket* socket) {
  ASSERT(!mutex_.TryLock());
  ASSERT(os_socket != nullptr);
  ASSERT(os_socket->ref_count > 0);
  os_socket->ref_count--;
  RemoveByFd(socket);
  if (os_socket->ref_count > 0) {
    return false;
  }
  // Unlink the socket file, if os_socket contains unix domain sockets.
  if (os_socket->address.addr.sa_family == AF_UNIX) {
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
    // If the socket is abstract, which has a path starting with a null byte,
    // unlink() is not necessary because the file doesn't exist.
    if (os_socket->address.un.sun_path[0] != '\0') {
      Utils::Unlink(os_socket->address.un.sun_path);
    }
#else
    Utils::Unlink(os_socket->address.un.sun_path);
#endif  // defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
    // Remove os_socket from unix_domain_sockets_ list.
    OSSocket* prev = nullptr;
    OSSocket* current = unix_domain_sockets_;
    while (current != nullptr) {
      if (current == os_socket) {
        if (prev == nullptr) {
          unix_domain_sockets_ = unix_domain_sockets_->next;
        } else {
          prev->next = current->next;
        }
        break;
      }
      prev = current;
      current = current->next;
    }
    delete os_socket;
    return true;
  }
  OSSocket* prev = nullptr;
  OSSocket* current = LookupByPort(os_socket->port);
  while (current != os_socket) {
    ASSERT(current != nullptr);
    prev = current;
    current = current->next;
  }

  if ((prev == nullptr) && (current->next == nullptr)) {
    // Remove last element from the list.
    RemoveByPort(os_socket->port);
  } else if (prev == nullptr) {
    // Remove first element of the list.
    InsertByPort(os_socket->port, current->next);
  } else {
    // Remove element from the list which is not the first one.
    prev->next = os_socket->next;
  }

  ASSERT(os_socket->ref_count == 0);
  delete os_socket;
  return true;
}

void ListeningSocketRegistry::CloseAllSafe() {
  MutexLocker ml(&mutex_);
  for (SimpleHashMap::Entry* cursor = sockets_by_fd_.Start(); cursor != nullptr;
       cursor = sockets_by_fd_.Next(cursor)) {
    OSSocket* os_socket = reinterpret_cast<OSSocket*>(cursor->value);
    ASSERT(os_socket != nullptr);
    delete os_socket;
  }
}

bool ListeningSocketRegistry::CloseSafe(Socket* socketfd) {
  ASSERT(!mutex_.TryLock());
  OSSocket* os_socket = LookupByFd(socketfd);
  if (os_socket != nullptr) {
    return CloseOneSafe(os_socket, socketfd);
  } else {
    // A finalizer may direct the event handler to close a listening socket
    // that it has never seen before. In this case, we return true to direct
    // the eventhandler to clean up the socket.
    return true;
  }
}

void FUNCTION_NAME(Socket_CreateConnect)(Dart_NativeArguments args) {
  RawAddr addr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 1), &addr);
  Dart_Handle port_arg = Dart_GetNativeArgument(args, 2);
  int64_t port = DartUtils::GetInt64ValueCheckRange(port_arg, 0, 65535);
  SocketAddress::SetAddrPort(&addr, static_cast<intptr_t>(port));
  if (addr.addr.sa_family == AF_INET6) {
    Dart_Handle scope_id_arg = Dart_GetNativeArgument(args, 3);
    int64_t scope_id =
        DartUtils::GetInt64ValueCheckRange(scope_id_arg, 0, 65535);
    SocketAddress::SetAddrScope(&addr, scope_id);
  }
  intptr_t socket = Socket::CreateConnect(addr);
  OSError error;
  if (socket >= 0) {
    Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), socket,
                                   Socket::kFinalizerNormal);
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&error));
  }
}

// This function will abort if sourceAddr is a Unix domain socket.
// The family ("sa_family") of the socket address is inferred from the length
// of the address. Unix domain sockets addresses are the bytes of their file
// system path so they have variable length. They cannot, therefore, be
// differentiated from other address types in this function.
void FUNCTION_NAME(Socket_CreateBindConnect)(Dart_NativeArguments args) {
  RawAddr addr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 1), &addr);
  Dart_Handle port_arg = Dart_GetNativeArgument(args, 2);
  int64_t port = DartUtils::GetInt64ValueCheckRange(port_arg, 0, 65535);
  SocketAddress::SetAddrPort(&addr, static_cast<intptr_t>(port));
  RawAddr sourceAddr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 3), &sourceAddr);
  Dart_Handle source_port_arg = Dart_GetNativeArgument(args, 4);
  int64_t source_port =
      DartUtils::GetInt64ValueCheckRange(source_port_arg, 0, 65535);
  SocketAddress::SetAddrPort(&sourceAddr, static_cast<intptr_t>(source_port));

  if (addr.addr.sa_family == AF_INET6) {
    Dart_Handle scope_id_arg = Dart_GetNativeArgument(args, 5);
    int64_t scope_id =
        DartUtils::GetInt64ValueCheckRange(scope_id_arg, 0, 65535);
    SocketAddress::SetAddrScope(&addr, scope_id);
  }
  intptr_t socket = Socket::CreateBindConnect(addr, sourceAddr);
  OSError error;
  if (socket >= 0) {
    Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), socket,
                                   Socket::kFinalizerNormal);
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&error));
  }
}

void FUNCTION_NAME(Socket_CreateUnixDomainBindConnect)(
    Dart_NativeArguments args) {
#if defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
  OSError os_error(
      -1, "Unix domain sockets are not available on this operating system.",
      OSError::kUnknown);
  Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
#else
  RawAddr addr;
  Dart_Handle address = Dart_GetNativeArgument(args, 1);
  if (Dart_IsNull(address)) {
    Dart_SetReturnValue(args,
        DartUtils::NewDartArgumentError("expect address to be of type String"));
  }
  Dart_Handle result = SocketAddress::GetUnixDomainSockAddr(
      DartUtils::GetStringValue(address), Namespace::GetNamespace(args, 3),
      &addr);
  if (!Dart_IsNull(result)) {
    return Dart_SetReturnValue(args, result);
  }

  RawAddr sourceAddr;
  address = Dart_GetNativeArgument(args, 2);
  if (Dart_IsNull(address)) {
    return Dart_SetReturnValue(
        args,
        DartUtils::NewDartArgumentError("expect address to be of type String"));
  }
  result = SocketAddress::GetUnixDomainSockAddr(
      DartUtils::GetStringValue(address), Namespace::GetNamespace(args, 3),
      &sourceAddr);
  if (!Dart_IsNull(result)) {
    return Dart_SetReturnValue(args, result);
  }

  intptr_t socket = Socket::CreateUnixDomainBindConnect(addr, sourceAddr);
  if (socket >= 0) {
    Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), socket,
                                   Socket::kFinalizerNormal);
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
#endif  // defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
}

void FUNCTION_NAME(Socket_CreateUnixDomainConnect)(Dart_NativeArguments args) {
#if defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
  OSError os_error(
      -1, "Unix domain sockets are not available on this operating system.",
      OSError::kUnknown);
  Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
#else
  RawAddr addr;
  Dart_Handle address = Dart_GetNativeArgument(args, 1);
  if (Dart_IsNull(address)) {
    return Dart_SetReturnValue(
        args,
        DartUtils::NewDartArgumentError("expect address to be of type String"));
  }
  Dart_Handle result = SocketAddress::GetUnixDomainSockAddr(
      DartUtils::GetStringValue(address), Namespace::GetNamespace(args, 2),
      &addr);
  if (!Dart_IsNull(result)) {
    return Dart_SetReturnValue(args, result);
  }
  intptr_t socket = Socket::CreateUnixDomainConnect(addr);
  if (socket >= 0) {
    Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), socket,
                                   Socket::kFinalizerNormal);
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
#endif  // defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
}

void FUNCTION_NAME(Socket_CreateBindDatagram)(Dart_NativeArguments args) {
  RawAddr addr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 1), &addr);
  Dart_Handle port_arg = Dart_GetNativeArgument(args, 2);
  int64_t port = DartUtils::GetInt64ValueCheckRange(port_arg, 0, 65535);
  SocketAddress::SetAddrPort(&addr, port);
  bool reuse_addr = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3));
  bool reuse_port = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 4));
  int ttl = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 5));
  intptr_t socket =
      Socket::CreateBindDatagram(addr, reuse_addr, reuse_port, ttl);
  if (socket >= 0) {
    Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), socket,
                                   Socket::kFinalizerNormal);
    Dart_SetReturnValue(args, Dart_True());
  } else {
    OSError error;
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&error));
  }
}

void FUNCTION_NAME(Socket_Available)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  intptr_t available = SocketBase::Available(socket->fd());
  if (available >= 0) {
    Dart_SetIntegerReturnValue(args, available);
  } else {
    // Available failed. Mark socket as having data, to trigger a future read
    // event where the actual error can be reported.
    Dart_SetIntegerReturnValue(args, 1);
  }
}

void FUNCTION_NAME(Socket_Read)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  int64_t length = 0;
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &length) &&
      (length >= 0)) {
    if (Socket::short_socket_read()) {
      length = (length + 1) / 2;
    }
    uint8_t* buffer = nullptr;
    Dart_Handle result = IOBuffer::Allocate(length, &buffer);
    if (Dart_IsNull(result)) {
      Dart_ThrowException(DartUtils::NewDartOSError());
    }
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    ASSERT(buffer != nullptr);
    intptr_t bytes_read =
        SocketBase::Read(socket->fd(), buffer, length, SocketBase::kAsync);
    if (bytes_read == length) {
      Dart_SetReturnValue(args, result);
    } else if (bytes_read > 0) {
      uint8_t* new_buffer = nullptr;
      Dart_Handle new_result = IOBuffer::Allocate(bytes_read, &new_buffer);
      if (Dart_IsNull(new_result)) {
        Dart_ThrowException(DartUtils::NewDartOSError());
      }
      if (Dart_IsError(new_result)) {
        Dart_PropagateError(new_result);
      }
      ASSERT(new_buffer != nullptr);
      memmove(new_buffer, buffer, bytes_read);
      Dart_SetReturnValue(args, new_result);
    } else if (bytes_read == 0) {
      // On MacOS when reading from a tty Ctrl-D will result in reading one
      // less byte then reported as available.
      Dart_SetReturnValue(args, Dart_Null());
    } else {
      ASSERT(bytes_read == -1);
      Dart_ThrowException(DartUtils::NewDartOSError());
    }
  } else {
    Dart_Handle exception;
    {
      // Make sure OSError destructor is called.
      OSError os_error(-1, "Invalid argument", OSError::kUnknown);
      exception = DartUtils::NewDartOSError(&os_error);
    }
    Dart_ThrowException(exception);
  }
}

void FUNCTION_NAME(Socket_RecvFrom)(Dart_NativeArguments args) {
  // TODO(sgjesse): Use a MTU value here. Only the loopback adapter can
  // handle 64k datagrams.
  const int kReceiveBufferLen = 65536;
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));

  // Ensure that a receive buffer for the UDP socket exists.
  ASSERT(socket != nullptr);
  uint8_t* recv_buffer = socket->udp_receive_buffer();
  if (recv_buffer == nullptr) {
    recv_buffer = reinterpret_cast<uint8_t*>(malloc(kReceiveBufferLen));
    socket->set_udp_receive_buffer(recv_buffer);
  }

  // Read data into the buffer.
  RawAddr addr;
  const intptr_t bytes_read = SocketBase::RecvFrom(
      socket->fd(), recv_buffer, kReceiveBufferLen, &addr, SocketBase::kAsync);
  if (bytes_read == 0) {
    Dart_SetReturnValue(args, Dart_Null());
    return;
  }
  if (bytes_read < 0) {
    ASSERT(bytes_read == -1);
    Dart_ThrowException(DartUtils::NewDartOSError());
  }

  // Datagram data read. Copy into buffer of the exact size,
  ASSERT(bytes_read >= 0);
  uint8_t* data_buffer = nullptr;
  Dart_Handle data = IOBuffer::Allocate(bytes_read, &data_buffer);
  if (Dart_IsNull(data)) {
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
  if (Dart_IsError(data)) {
    Dart_PropagateError(data);
  }
  ASSERT(data_buffer != nullptr);
  memmove(data_buffer, recv_buffer, bytes_read);

  // Get the port and clear it in the sockaddr structure.
  int port = SocketAddress::GetAddrPort(addr);
  // TODO(21403): Add checks for AF_UNIX, if unix domain sockets
  // are used in SOCK_DGRAM.
  enum internet_type { IPv4, IPv6 };
  internet_type type;
  if (addr.addr.sa_family == AF_INET) {
    addr.in.sin_port = 0;
    type = IPv4;
  } else {
    ASSERT(addr.addr.sa_family == AF_INET6);
    addr.in6.sin6_port = 0;
    type = IPv6;
  }
  // Format the address to a string using the numeric format.
  char numeric_address[INET6_ADDRSTRLEN];
  SocketBase::FormatNumericAddress(addr, numeric_address, INET6_ADDRSTRLEN);

  // Create a Datagram object with the data and sender address and port.
  const int kNumArgs = 5;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = data;
  dart_args[1] = Dart_NewStringFromCString(numeric_address);
  if (Dart_IsError(dart_args[1])) {
    Dart_PropagateError(dart_args[1]);
  }
  dart_args[2] = SocketAddress::ToTypedData(addr);
  dart_args[3] = Dart_NewInteger(port);
  dart_args[4] = Dart_NewInteger(type);
  if (Dart_IsError(dart_args[3])) {
    Dart_PropagateError(dart_args[3]);
  }
  // TODO(sgjesse): Cache the _makeDatagram function somewhere.
  Dart_Handle io_lib = Dart_LookupLibrary(DartUtils::NewString("dart:io"));
  if (Dart_IsError(io_lib)) {
    Dart_PropagateError(io_lib);
  }
  Dart_Handle result = Dart_Invoke(
      io_lib, DartUtils::NewString("_makeDatagram"), kNumArgs, dart_args);
  Dart_SetReturnValue(args, result);
}

void FUNCTION_NAME(Socket_ReceiveMessage)(Dart_NativeArguments args) {
  Socket* socket = Socket::GetSocketIdNativeField(
      ThrowIfError(Dart_GetNativeArgument(args, 0)));
  ASSERT(socket != nullptr);

  int64_t buffer_num_bytes = 0;
  DartUtils::GetInt64Value(ThrowIfError(Dart_GetNativeArgument(args, 1)),
                           &buffer_num_bytes);
  int64_t buffer_num_bytes_allocated = buffer_num_bytes;
  uint8_t* buffer = nullptr;
  Dart_Handle data = IOBuffer::Allocate(buffer_num_bytes, &buffer);
  if (Dart_IsNull(data)) {
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
  ASSERT(buffer != nullptr);

  // Can't rely on RAII since Dart_ThrowException won't call destructors.
  OSError* os_error = new OSError();
  SocketControlMessage* control_messages;
  const intptr_t messages_read = SocketBase::ReceiveMessage(
      socket->fd(), buffer, &buffer_num_bytes, &control_messages,
      SocketBase::kAsync, os_error);
  if (messages_read < 0) {
    ASSERT(messages_read == -1);
    Dart_Handle error = DartUtils::NewDartOSError(os_error);
    delete os_error;
    Dart_ThrowException(error);
  }
  delete os_error;
  if (buffer_num_bytes > 0 && buffer_num_bytes != buffer_num_bytes_allocated) {
    // If received fewer than allocated buffer size, truncate buffer.
    uint8_t* new_buffer = nullptr;
    Dart_Handle new_data = IOBuffer::Allocate(buffer_num_bytes, &new_buffer);
    if (Dart_IsNull(new_data)) {
      Dart_ThrowException(DartUtils::NewDartOSError());
    }
    ASSERT(new_buffer != nullptr);
    memmove(new_buffer, buffer, buffer_num_bytes);
    data = new_data;
  }

  // returned list has a (level, type, message bytes) triple for every message,
  // plus last element is raw data uint8list.
  Dart_Handle list = ThrowIfError(Dart_NewList(messages_read * 3 + 1));
  int j = 0;
  for (intptr_t i = 0; i < messages_read; i++) {
    SocketControlMessage* message = control_messages + i;
    Dart_Handle uint8list_message_data = ThrowIfError(
        DartUtils::MakeUint8Array(message->data(), message->data_length()));
    ThrowIfError(Dart_ListSetAt(
        list, j++, ThrowIfError(Dart_NewInteger(message->level()))));
    ThrowIfError(Dart_ListSetAt(
        list, j++, ThrowIfError(Dart_NewInteger(message->type()))));
    ThrowIfError(Dart_ListSetAt(list, j++, uint8list_message_data));
  }
  ThrowIfError(Dart_ListSetAt(list, j, data));
  Dart_SetReturnValue(args, list);
}

void FUNCTION_NAME(Socket_HasPendingWrite)(Dart_NativeArguments args) {
#if defined(DART_HOST_OS_WINDOWS)
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  const bool result = SocketBase::HasPendingWrite(socket->fd());
#else
  const bool result = false;
#endif  // defined(DART_HOST_OS_WINDOWS)
  Dart_SetReturnValue(args, Dart_NewBoolean(result));
}

void FUNCTION_NAME(Socket_WriteList)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  intptr_t offset = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  intptr_t length = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 3));
  bool short_write = false;
  if (Socket::short_socket_write()) {
    if (length > 1) {
      short_write = true;
    }
    length = (length + 1) / 2;
  }
  Dart_TypedData_Type type;
  uint8_t* buffer = nullptr;
  intptr_t len;
  Dart_Handle result = Dart_TypedDataAcquireData(
      buffer_obj, &type, reinterpret_cast<void**>(&buffer), &len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  ASSERT((offset + length) <= len);
  buffer += offset;
  intptr_t bytes_written =
      SocketBase::Write(socket->fd(), buffer, length, SocketBase::kAsync);
  if (bytes_written >= 0) {
    Dart_TypedDataReleaseData(buffer_obj);
    if (short_write) {
      // If the write was forced 'short', indicate by returning the negative
      // number of bytes. A forced short write may not trigger a write event.
      Dart_SetIntegerReturnValue(args, -bytes_written);
    } else {
      Dart_SetIntegerReturnValue(args, bytes_written);
    }
  } else {
    // Extract OSError before we release data, as it may override the error.
    Dart_Handle error;
    {
      OSError os_error;
      Dart_TypedDataReleaseData(buffer_obj);
      error = DartUtils::NewDartOSError(&os_error);
    }
    Dart_ThrowException(error);
  }
}

void FUNCTION_NAME(Socket_SendMessage)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  intptr_t offset = DartUtils::GetNativeIntptrArgument(args, 2);
  intptr_t length = DartUtils::GetNativeIntptrArgument(args, 3);

  // List of triples <level, type, data> arranged to minimize dart api use in
  // native methods.
  Dart_Handle control_message_list_dart =
      ThrowIfError(Dart_GetNativeArgument(args, 4));
  ASSERT(Dart_IsList(control_message_list_dart));
  intptr_t num_control_messages_pieces;
  ThrowIfError(
      Dart_ListLength(control_message_list_dart, &num_control_messages_pieces));
  intptr_t num_control_messages = num_control_messages_pieces / 3;
  ASSERT((num_control_messages * 3) == num_control_messages_pieces);
  SocketControlMessage* control_messages =
      reinterpret_cast<SocketControlMessage*>(Dart_ScopeAllocate(
          sizeof(SocketControlMessage) * num_control_messages));
  ASSERT(control_messages != nullptr);

  SocketControlMessage* control_message = control_messages;
  intptr_t j = 0;
  for (intptr_t i = 0; i < num_control_messages; i++, control_message++) {
    int level = DartUtils::GetIntegerValue(
        ThrowIfError(Dart_ListGetAt(control_message_list_dart, j++)));
    int type = DartUtils::GetIntegerValue(
        ThrowIfError(Dart_ListGetAt(control_message_list_dart, j++)));
    Dart_Handle uint8list_dart =
        ThrowIfError(Dart_ListGetAt(control_message_list_dart, j++));

    TypedDataScope data(uint8list_dart);
    void* copied_data = Dart_ScopeAllocate(data.size_in_bytes());
    ASSERT(copied_data != nullptr);
    memmove(copied_data, data.data(), data.size_in_bytes());
    new (control_message)
        SocketControlMessage(level, type, copied_data, data.size_in_bytes());
  }

  // Can't rely on RAII since Dart_ThrowException won't call destructors.
  OSError* os_error = new OSError();
  intptr_t bytes_written;
  {
    Dart_Handle buffer_dart = Dart_GetNativeArgument(args, 1);
    TypedDataScope data(buffer_dart);

    ASSERT((offset + length) <= data.size_in_bytes());
    uint8_t* buffer_at_offset =
        reinterpret_cast<uint8_t*>(data.data()) + offset;
    bytes_written = SocketBase::SendMessage(
        socket->fd(), buffer_at_offset, length, control_messages,
        num_control_messages, SocketBase::kAsync, os_error);
  }

  if (bytes_written < 0) {
    Dart_Handle error = DartUtils::NewDartOSError(os_error);
    delete os_error;
    Dart_ThrowException(error);
  }
  delete os_error;

  Dart_SetIntegerReturnValue(args, bytes_written);
}

void FUNCTION_NAME(Socket_SendTo)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  intptr_t offset = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  intptr_t length = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 3));
  Dart_Handle address_obj = Dart_GetNativeArgument(args, 4);
  ASSERT(Dart_IsList(address_obj));
  RawAddr addr;
  SocketAddress::GetSockAddr(address_obj, &addr);
  int64_t port = DartUtils::GetInt64ValueCheckRange(
      Dart_GetNativeArgument(args, 5), 0, 65535);
  SocketAddress::SetAddrPort(&addr, port);
  Dart_TypedData_Type type;
  uint8_t* buffer = nullptr;
  intptr_t len;
  Dart_Handle result = Dart_TypedDataAcquireData(
      buffer_obj, &type, reinterpret_cast<void**>(&buffer), &len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  ASSERT((offset + length) <= len);
  buffer += offset;
  intptr_t bytes_written = SocketBase::SendTo(socket->fd(), buffer, length,
                                              addr, SocketBase::kAsync);
  if (bytes_written >= 0) {
    Dart_TypedDataReleaseData(buffer_obj);
    Dart_SetIntegerReturnValue(args, bytes_written);
  } else {
    // Extract OSError before we release data, as it may override the error.
    Dart_Handle error;
    {
      OSError os_error;
      Dart_TypedDataReleaseData(buffer_obj);
      error = DartUtils::NewDartOSError(&os_error);
    }
    Dart_ThrowException(error);
  }
}

void FUNCTION_NAME(Socket_GetPort)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  intptr_t port = SocketBase::GetPort(socket->fd());
  if (port > 0) {
    Dart_SetIntegerReturnValue(args, port);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Socket_GetRemotePeer)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  intptr_t port = 0;
  SocketAddress* addr = SocketBase::GetRemotePeer(socket->fd(), &port);
  if (addr != nullptr) {
    Dart_Handle list = Dart_NewList(2);
    int type = addr->GetType();
    Dart_Handle entry;
    if (type == SocketAddress::TYPE_UNIX) {
      entry = Dart_NewList(2);
    } else {
      entry = Dart_NewList(3);
      RawAddr raw = addr->addr();
      Dart_ListSetAt(entry, 2, SocketAddress::ToTypedData(raw));
    }
    Dart_ListSetAt(entry, 0, Dart_NewInteger(type));
    Dart_ListSetAt(entry, 1, Dart_NewStringFromCString(addr->as_string()));

    Dart_ListSetAt(list, 0, entry);
    Dart_ListSetAt(list, 1, Dart_NewInteger(port));
    Dart_SetReturnValue(args, list);
    delete addr;
  } else {
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Socket_GetError)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  OSError os_error;
  SocketBase::GetError(socket->fd(), &os_error);
  if (os_error.code() != 0) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
  } else {
    Dart_SetReturnValue(args, Dart_Null());
  }
}

void FUNCTION_NAME(Socket_Fatal)(Dart_NativeArguments args) {
  Dart_Handle msg = Dart_GetNativeArgument(args, 0);
  const char* msgStr =
      (!Dart_IsNull(msg)) ? DartUtils::GetStringValue(msg) : nullptr;
  FATAL("Fatal error in dart:io (socket): %s", msgStr);
}

void FUNCTION_NAME(Socket_GetFD)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  Dart_SetIntegerReturnValue(args, socket->fd());
}

void FUNCTION_NAME(Socket_GetType)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  OSError os_error;
  intptr_t type = SocketBase::GetType(socket->fd());
  if (type >= 0) {
    Dart_SetIntegerReturnValue(args, type);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Socket_GetStdioHandle)(Dart_NativeArguments args) {
  int64_t num =
      DartUtils::GetInt64ValueCheckRange(Dart_GetNativeArgument(args, 1), 0, 2);
  intptr_t socket = SocketBase::GetStdioHandle(num);
  Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), socket,
                                 Socket::kFinalizerStdio);
  Dart_SetReturnValue(args, Dart_NewBoolean(socket >= 0));
}

void FUNCTION_NAME(Socket_GetSocketId)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  intptr_t id = reinterpret_cast<intptr_t>(socket);
  Dart_SetIntegerReturnValue(args, id);
}

void FUNCTION_NAME(Socket_SetSocketId)(Dart_NativeArguments args) {
  intptr_t id = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  intptr_t type_flag =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  Socket::SocketFinalizer finalizer;
  if (Socket::IsSignalSocketFlag(type_flag)) {
    finalizer = Socket::kFinalizerSignal;
  } else {
    finalizer = Socket::kFinalizerNormal;
  }
  Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), id,
                                 finalizer);
}

void FUNCTION_NAME(ServerSocket_CreateBindListen)(Dart_NativeArguments args) {
  RawAddr addr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 1), &addr);
  int64_t port = DartUtils::GetInt64ValueCheckRange(
      Dart_GetNativeArgument(args, 2), 0, 65535);
  SocketAddress::SetAddrPort(&addr, port);
  int64_t backlog = DartUtils::GetInt64ValueCheckRange(
      Dart_GetNativeArgument(args, 3), 0, 65535);
  bool v6_only = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 4));
  bool shared = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 5));
  if (addr.addr.sa_family == AF_INET6) {
    Dart_Handle scope_id_arg = Dart_GetNativeArgument(args, 6);
    int64_t scope_id =
        DartUtils::GetInt64ValueCheckRange(scope_id_arg, 0, 65535);
    SocketAddress::SetAddrScope(&addr, scope_id);
  }

  Dart_Handle socket_object = Dart_GetNativeArgument(args, 0);
  Dart_Handle result = ListeningSocketRegistry::Instance()->CreateBindListen(
      socket_object, addr, backlog, v6_only, shared);
  Dart_SetReturnValue(args, result);
}

void FUNCTION_NAME(ServerSocket_CreateUnixDomainBindListen)(
    Dart_NativeArguments args) {
#if defined(DART_HOST_OS_WINDOWS)
  OSError os_error(
      -1, "Unix domain sockets are not available on this operating system.",
      OSError::kUnknown);
  Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
#else
  Dart_Handle address = Dart_GetNativeArgument(args, 1);
  if (Dart_IsNull(address)) {
    Dart_SetReturnValue(args,
        DartUtils::NewDartArgumentError("expect address to be of type String"));
  }
  const char* path = DartUtils::GetStringValue(address);
  int64_t backlog = DartUtils::GetInt64ValueCheckRange(
      Dart_GetNativeArgument(args, 2), 0, 65535);
  bool shared = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3));
  Namespace* namespc = Namespace::GetNamespace(args, 4);
  Dart_Handle socket_object = Dart_GetNativeArgument(args, 0);
  Dart_Handle result =
      ListeningSocketRegistry::Instance()->CreateUnixDomainBindListen(
          socket_object, namespc, path, backlog, shared);
  Dart_SetReturnValue(args, result);
#endif  // defined(DART_HOST_OS_WINDOWS)
}

void FUNCTION_NAME(ServerSocket_Accept)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  intptr_t new_socket = ServerSocket::Accept(socket->fd());
  if (new_socket >= 0) {
    Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 1), new_socket,
                                   Socket::kFinalizerNormal);
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, Dart_False());
  }
}

CObject* Socket::LookupRequest(const CObjectArray& request) {
  if ((request.Length() == 2) && request[0]->IsString() &&
      request[1]->IsInt32()) {
    CObjectString host(request[0]);
    CObjectInt32 type(request[1]);
    CObject* result = nullptr;
    OSError* os_error = nullptr;
    AddressList<SocketAddress>* addresses =
        SocketBase::LookupAddress(host.CString(), type.Value(), &os_error);
    if (addresses != nullptr) {
      CObjectArray* array =
          new CObjectArray(CObject::NewArray(addresses->count() + 1));
      array->SetAt(0, new CObjectInt32(CObject::NewInt32(0)));
      for (intptr_t i = 0; i < addresses->count(); i++) {
        SocketAddress* addr = addresses->GetAt(i);
        CObjectArray* entry = new CObjectArray(CObject::NewArray(4));

        CObjectInt32* type =
            new CObjectInt32(CObject::NewInt32(addr->GetType()));
        entry->SetAt(0, type);

        CObjectString* as_string =
            new CObjectString(CObject::NewString(addr->as_string()));
        entry->SetAt(1, as_string);

        RawAddr raw = addr->addr();
        CObjectUint8Array* data = SocketAddress::ToCObject(raw);
        entry->SetAt(2, data);

        CObjectInt64* scope_id = new CObjectInt64(
            CObject::NewInt64(SocketAddress::GetAddrScope(raw)));
        entry->SetAt(3, scope_id);

        array->SetAt(i + 1, entry);
      }
      result = array;
      delete addresses;
    } else {
      result = CObject::NewOSError(os_error);
      delete os_error;
    }
    return result;
  }
  return CObject::IllegalArgumentError();
}

CObject* Socket::ReverseLookupRequest(const CObjectArray& request) {
  if ((request.Length() == 1) && request[0]->IsTypedData()) {
    CObjectUint8Array addr_object(request[0]);
    RawAddr addr;
    int len = addr_object.Length();
    memset(reinterpret_cast<void*>(&addr), 0, sizeof(RawAddr));
    if (len == sizeof(in_addr)) {
      addr.in.sin_family = AF_INET;
      memmove(reinterpret_cast<void*>(&addr.in.sin_addr), addr_object.Buffer(),
              len);
    } else {
      ASSERT(len == sizeof(in6_addr));
      addr.in6.sin6_family = AF_INET6;
      memmove(reinterpret_cast<void*>(&addr.in6.sin6_addr),
              addr_object.Buffer(), len);
    }

    OSError* os_error = nullptr;
    const intptr_t kMaxHostLength = 1025;
    char host[kMaxHostLength];
    if (SocketBase::ReverseLookup(addr, host, kMaxHostLength, &os_error)) {
      return new CObjectString(CObject::NewString(host));
    } else {
      CObject* result = CObject::NewOSError(os_error);
      delete os_error;
      return result;
    }
  }
  return CObject::IllegalArgumentError();
}

CObject* Socket::ListInterfacesRequest(const CObjectArray& request) {
  if ((request.Length() == 1) && request[0]->IsInt32()) {
    CObjectInt32 type(request[0]);
    CObject* result = nullptr;
    OSError* os_error = nullptr;
    AddressList<InterfaceSocketAddress>* addresses =
        SocketBase::ListInterfaces(type.Value(), &os_error);
    if (addresses != nullptr) {
      CObjectArray* array =
          new CObjectArray(CObject::NewArray(addresses->count() + 1));
      array->SetAt(0, new CObjectInt32(CObject::NewInt32(0)));
      for (intptr_t i = 0; i < addresses->count(); i++) {
        InterfaceSocketAddress* interface = addresses->GetAt(i);
        SocketAddress* addr = interface->socket_address();
        CObjectArray* entry = new CObjectArray(CObject::NewArray(5));

        CObjectInt32* type =
            new CObjectInt32(CObject::NewInt32(addr->GetType()));
        entry->SetAt(0, type);

        CObjectString* as_string =
            new CObjectString(CObject::NewString(addr->as_string()));
        entry->SetAt(1, as_string);

        RawAddr raw = addr->addr();
        CObjectUint8Array* data = SocketAddress::ToCObject(raw);
        entry->SetAt(2, data);

        CObjectString* interface_name =
            new CObjectString(CObject::NewString(interface->interface_name()));
        entry->SetAt(3, interface_name);

        CObjectInt64* interface_index =
            new CObjectInt64(CObject::NewInt64(interface->interface_index()));
        entry->SetAt(4, interface_index);

        array->SetAt(i + 1, entry);
      }
      result = array;
      delete addresses;
    } else {
      result = CObject::NewOSError(os_error);
      delete os_error;
    }
    return result;
  }
  return CObject::IllegalArgumentError();
}

void FUNCTION_NAME(Socket_GetOption)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  int64_t option = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  intptr_t protocol = static_cast<intptr_t>(
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2)));
  bool ok = false;
  switch (option) {
    case 0: {  // TCP_NODELAY.
      bool enabled;
      ok = SocketBase::GetNoDelay(socket->fd(), &enabled);
      if (ok) {
        Dart_SetBooleanReturnValue(args, enabled);
      }
      break;
    }
    case 1: {  // IP_MULTICAST_LOOP.
      bool enabled;
      ok = SocketBase::GetMulticastLoop(socket->fd(), protocol, &enabled);
      if (ok) {
        Dart_SetBooleanReturnValue(args, enabled);
      }
      break;
    }
    case 2: {  // IP_MULTICAST_TTL.
      int value;
      ok = SocketBase::GetMulticastHops(socket->fd(), protocol, &value);
      if (ok) {
        Dart_SetIntegerReturnValue(args, value);
      }
      break;
    }
    case 3: {  // IP_MULTICAST_IF.
      UNIMPLEMENTED();
      break;
    }
    case 4: {  // IP_BROADCAST.
      bool enabled;
      ok = SocketBase::GetBroadcast(socket->fd(), &enabled);
      if (ok) {
        Dart_SetBooleanReturnValue(args, enabled);
      }
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
  // In case of failure the return value is not set above.
  if (!ok) {
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Socket_SetOption)(Dart_NativeArguments args) {
  bool result = false;
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  int64_t option = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  intptr_t protocol = static_cast<intptr_t>(
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2)));
  switch (option) {
    case 0:  // TCP_NODELAY.
      result = SocketBase::SetNoDelay(
          socket->fd(),
          DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3)));
      break;
    case 1:  // IP_MULTICAST_LOOP.
      result = SocketBase::SetMulticastLoop(
          socket->fd(), protocol,
          DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3)));
      break;
    case 2:  // IP_MULTICAST_TTL.
      result = SocketBase::SetMulticastHops(
          socket->fd(), protocol,
          DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3)));
      break;
    case 3: {  // IP_MULTICAST_IF.
      UNIMPLEMENTED();
      break;
    }
    case 4:  // IP_BROADCAST.
      result = SocketBase::SetBroadcast(
          socket->fd(),
          DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3)));
      break;
    default:
      Dart_PropagateError(
          Dart_NewApiError("option to setOption() is outside expected range"));
      break;
  }
  if (!result) {
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Socket_SetRawOption)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  int64_t level = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  int64_t option = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  Dart_Handle data_obj = Dart_GetNativeArgument(args, 3);
  ASSERT(Dart_IsList(data_obj));
  char* data = nullptr;
  intptr_t length;
  Dart_TypedData_Type type;
  Dart_Handle data_result = Dart_TypedDataAcquireData(
      data_obj, &type, reinterpret_cast<void**>(&data), &length);
  if (Dart_IsError(data_result)) {
    Dart_PropagateError(data_result);
  }

  bool result = SocketBase::SetOption(socket->fd(), static_cast<int>(level),
                                      static_cast<int>(option), data,
                                      static_cast<int>(length));

  Dart_TypedDataReleaseData(data_obj);

  if (!result) {
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Socket_GetRawOption)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  int64_t level = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  int64_t option = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  Dart_Handle data_obj = Dart_GetNativeArgument(args, 3);
  ASSERT(Dart_IsList(data_obj));
  char* data = nullptr;
  intptr_t length;
  Dart_TypedData_Type type;
  Dart_Handle data_result = Dart_TypedDataAcquireData(
      data_obj, &type, reinterpret_cast<void**>(&data), &length);
  if (Dart_IsError(data_result)) {
    Dart_PropagateError(data_result);
  }
  unsigned int int_length = static_cast<unsigned int>(length);
  bool result =
      SocketBase::GetOption(socket->fd(), static_cast<int>(level),
                            static_cast<int>(option), data, &int_length);

  Dart_TypedDataReleaseData(data_obj);
  if (!result) {
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
}

// Keep in sync with _RawSocketOptions in socket.dart
enum _RawSocketOptions : int64_t {
  DART_SOL_SOCKET = 0,
  DART_IPPROTO_IP = 1,
  DART_IP_MULTICAST_IF = 2,
  DART_IPPROTO_IPV6 = 3,
  DART_IPV6_MULTICAST_IF = 4,
  DART_IPPROTO_TCP = 5,
  DART_IPPROTO_UDP = 6
};

void FUNCTION_NAME(RawSocketOption_GetOptionValue)(Dart_NativeArguments args) {
  _RawSocketOptions key = static_cast<_RawSocketOptions>(
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 0)));
  switch (key) {
    case DART_SOL_SOCKET:
      Dart_SetIntegerReturnValue(args, SOL_SOCKET);
      break;
    case DART_IPPROTO_IP:
      Dart_SetIntegerReturnValue(args, IPPROTO_IP);
      break;
    case DART_IP_MULTICAST_IF:
      Dart_SetIntegerReturnValue(args, IP_MULTICAST_IF);
      break;
    case DART_IPPROTO_IPV6:
      Dart_SetIntegerReturnValue(args, IPPROTO_IPV6);
      break;
    case DART_IPV6_MULTICAST_IF:
      Dart_SetIntegerReturnValue(args, IPV6_MULTICAST_IF);
      break;
    case DART_IPPROTO_TCP:
      Dart_SetIntegerReturnValue(args, IPPROTO_TCP);
      break;
    case DART_IPPROTO_UDP:
      Dart_SetIntegerReturnValue(args, IPPROTO_UDP);
      break;
    default:
      Dart_PropagateError(Dart_NewApiError(
          "option to getOptionValue() is outside expected range"));
      break;
  }
}

void FUNCTION_NAME(Socket_JoinMulticast)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  RawAddr addr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 1), &addr);
  RawAddr interface;
  if (Dart_GetNativeArgument(args, 2) != Dart_Null()) {
    SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 2), &interface);
  }
  int interfaceIndex =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  if (!SocketBase::JoinMulticast(socket->fd(), addr, interface,
                                 interfaceIndex)) {
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Socket_LeaveMulticast)(Dart_NativeArguments args) {
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  RawAddr addr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 1), &addr);
  RawAddr interface;
  if (Dart_GetNativeArgument(args, 2) != Dart_Null()) {
    SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 2), &interface);
  }
  int interfaceIndex =
      DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  if (!SocketBase::LeaveMulticast(socket->fd(), addr, interface,
                                  interfaceIndex)) {
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Socket_AvailableDatagram)(Dart_NativeArguments args) {
  const int kReceiveBufferLen = 1;
  Socket* socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  ASSERT(socket != nullptr);
  // Ensure that a receive buffer for peeking the UDP socket exists.
  uint8_t recv_buffer[kReceiveBufferLen];
  bool available = SocketBase::AvailableDatagram(socket->fd(), recv_buffer,
                                                 kReceiveBufferLen);
  Dart_SetBooleanReturnValue(args, available);
}

static void NormalSocketFinalizer(void* isolate_data, void* data) {
  Socket* socket = reinterpret_cast<Socket*>(data);
  const int64_t flags = 1 << kCloseCommand;
  socket->Retain();  // Bump reference till we send the message.
  EventHandler::SendFromNative(reinterpret_cast<intptr_t>(socket),
                               socket->port(), flags);
  socket->Release();  // Release the reference we just added above.
}

static void ListeningSocketFinalizer(void* isolate_data, void* data) {
  Socket* socket = reinterpret_cast<Socket*>(data);
  const int64_t flags = (1 << kListeningSocket) | (1 << kCloseCommand);
  socket->Retain();  // Bump reference till we send the message.
  EventHandler::SendFromNative(reinterpret_cast<intptr_t>(socket),
                               socket->port(), flags);
  socket->Release();  // Release the reference we just added above.
}

static void StdioSocketFinalizer(void* isolate_data, void* data) {
  Socket* socket = reinterpret_cast<Socket*>(data);
  if (socket->fd() >= 0) {
    socket->CloseFd();
  }
  socket->Release();
}

static void SignalSocketFinalizer(void* isolate_data, void* data) {
  Socket* socket = reinterpret_cast<Socket*>(data);
  const int64_t flags = (1 << kSignalSocket) | (1 << kCloseCommand);
  socket->Retain();  // Bump reference till we send the message.
  EventHandler::SendFromNative(reinterpret_cast<intptr_t>(socket),
                               socket->port(), flags);
  socket->Release();  // Release the reference we just added above.
}

void Socket::ReuseSocketIdNativeField(Dart_Handle handle,
                                      Socket* socket,
                                      SocketFinalizer finalizer) {
  Dart_Handle err = Dart_SetNativeInstanceField(
      handle, kSocketIdNativeField, reinterpret_cast<intptr_t>(socket));
  if (Dart_IsError(err)) {
    Dart_PropagateError(err);
  }
  Dart_HandleFinalizer callback;
  switch (finalizer) {
    case kFinalizerNormal:
      callback = NormalSocketFinalizer;
      break;
    case kFinalizerListening:
      callback = ListeningSocketFinalizer;
      break;
    case kFinalizerStdio:
      callback = StdioSocketFinalizer;
      break;
    case kFinalizerSignal:
      callback = SignalSocketFinalizer;
      break;
    default:
      callback = nullptr;
      UNREACHABLE();
      break;
  }
  if (callback != nullptr) {
    Dart_NewFinalizableHandle(handle, reinterpret_cast<void*>(socket),
                              sizeof(Socket), callback);
  }
}

void Socket::SetSocketIdNativeField(Dart_Handle handle,
                                    intptr_t id,
                                    SocketFinalizer finalizer) {
  Socket* socket = new Socket(id);
  ReuseSocketIdNativeField(handle, socket, finalizer);
}

Socket* Socket::GetSocketIdNativeField(Dart_Handle socket_obj) {
  intptr_t id;
  Dart_Handle err =
      Dart_GetNativeInstanceField(socket_obj, kSocketIdNativeField, &id);
  if (Dart_IsError(err)) {
    Dart_PropagateError(err);
  }
  Socket* socket = reinterpret_cast<Socket*>(id);
  if (socket == nullptr) {
    Dart_PropagateError(Dart_NewUnhandledExceptionError(
        DartUtils::NewInternalError("No native peer")));
  }
  return socket;
}

void FUNCTION_NAME(SocketControlMessage_fromHandles)(
    Dart_NativeArguments args) {
#if defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
  Dart_SetReturnValue(args,
                      DartUtils::NewDartUnsupportedError(
                          "This is not supported on this operating system"));
#else
  ASSERT(Dart_IsNull(Dart_GetNativeArgument(args, 0)));
  Dart_Handle handles_dart = Dart_GetNativeArgument(args, 1);
  if (Dart_IsNull(handles_dart)) {
    Dart_ThrowException(
        DartUtils::NewDartArgumentError("handles list can't be null"));
  }
  ASSERT(Dart_IsList(handles_dart));
  intptr_t num_handles;
  ThrowIfError(Dart_ListLength(handles_dart, &num_handles));
  intptr_t num_bytes = num_handles * sizeof(int);
  int* handles = reinterpret_cast<int*>(Dart_ScopeAllocate(num_bytes));
  Dart_Handle handle_dart_string =
      ThrowIfError(DartUtils::NewString("_handle"));
  for (intptr_t i = 0; i < num_handles; i++) {
    Dart_Handle handle_dart = ThrowIfError(Dart_ListGetAt(handles_dart, i));
    Dart_Handle handle_int_dart =
        ThrowIfError(Dart_GetField(handle_dart, handle_dart_string));
    handles[i] = DartUtils::GetIntegerValue(handle_int_dart);
  }

  Dart_Handle uint8list_dart =
      ThrowIfError(Dart_NewTypedData(Dart_TypedData_kUint8, num_bytes));
  ThrowIfError(Dart_ListSetAsBytes(uint8list_dart, /*offset=*/0,
                                   reinterpret_cast<const uint8_t*>(handles),
                                   num_bytes));
  Dart_Handle dart_new_args[] = {Dart_NewInteger(SOL_SOCKET),
                                 Dart_NewInteger(SCM_RIGHTS), uint8list_dart};

  Dart_Handle socket_control_message_impl = ThrowIfError(DartUtils::GetDartType(
      DartUtils::kIOLibURL, "_SocketControlMessageImpl"));
  Dart_SetReturnValue(
      args,
      Dart_New(socket_control_message_impl,
               /*constructor_name=*/Dart_Null(),
               sizeof(dart_new_args) / sizeof(Dart_Handle), dart_new_args));
#endif  // defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
}

void FUNCTION_NAME(SocketControlMessageImpl_extractHandles)(
    Dart_NativeArguments args) {
#if defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
  Dart_SetReturnValue(args,
                      DartUtils::NewDartUnsupportedError(
                          "This is not supported on this operating system"));
#else
  Dart_Handle handle_type = ThrowIfError(
      DartUtils::GetDartType(DartUtils::kIOLibURL, "ResourceHandle"));

  Dart_Handle message_dart = Dart_GetNativeArgument(args, 0);
  intptr_t level = DartUtils::GetIntegerValue(
      ThrowIfError(Dart_GetField(message_dart, DartUtils::NewString("level"))));
  intptr_t type = DartUtils::GetIntegerValue(
      ThrowIfError(Dart_GetField(message_dart, DartUtils::NewString("type"))));
  if (level != SOL_SOCKET || type != SCM_RIGHTS) {
    Dart_SetReturnValue(args, ThrowIfError(Dart_NewListOfTypeFilled(
                                  handle_type, Dart_Null(), 0)));
    return;
  }

  Dart_Handle data_dart =
      ThrowIfError(Dart_GetField(message_dart, DartUtils::NewString("data")));
  ASSERT(Dart_IsTypedData(data_dart));

  void* data;
  intptr_t bytes_count;
  Dart_TypedData_Type data_type;
  ThrowIfError(
      Dart_TypedDataAcquireData(data_dart, &data_type, &data, &bytes_count));
  ASSERT(data_type == Dart_TypedData_kUint8);
  int* ints_data = reinterpret_cast<int*>(Dart_ScopeAllocate(bytes_count));
  ASSERT(ints_data != nullptr);
  memmove(ints_data, data, bytes_count);
  ThrowIfError(Dart_TypedDataReleaseData(data_dart));
  intptr_t ints_count = bytes_count / sizeof(int);

  Dart_Handle handle_impl_type =
      DartUtils::GetDartType(DartUtils::kIOLibURL, "_ResourceHandleImpl");
  Dart_Handle sentinel = ThrowIfError(
      Dart_GetField(handle_impl_type, DartUtils::NewString("_sentinel")));
  Dart_Handle handle_list =
      ThrowIfError(Dart_NewListOfTypeFilled(handle_type, sentinel, ints_count));
  for (intptr_t i = 0; i < ints_count; i++) {
    Dart_Handle constructor_args[] = {
        ThrowIfError(Dart_NewInteger(*(ints_data + i)))};
    Dart_Handle handle_impl = ThrowIfError(Dart_New(
        handle_impl_type,
        /*constructor_name=*/Dart_Null(),
        sizeof(constructor_args) / sizeof(Dart_Handle), constructor_args));
    ThrowIfError(Dart_ListSetAt(handle_list, i, handle_impl));
  }

  Dart_SetReturnValue(args, handle_list);
#endif  // defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
}

void FUNCTION_NAME(ResourceHandleImpl_toFile)(Dart_NativeArguments args) {
#if defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
  Dart_SetReturnValue(args,
                      DartUtils::NewDartUnsupportedError(
                          "This is not supported on this operating system"));
#else
  Dart_Handle handle_object = ThrowIfError(Dart_GetNativeArgument(args, 0));
  Dart_Handle handle_field = ThrowIfError(
      Dart_GetField(handle_object, DartUtils::NewString("_handle")));
  intptr_t fd = DartUtils::GetIntegerValue(handle_field);

  Dart_Handle random_access_file_type = ThrowIfError(
      DartUtils::GetDartType(DartUtils::kIOLibURL, "_RandomAccessFile"));

  Dart_Handle dart_new_args[2];
  dart_new_args[1] = ThrowIfError(Dart_NewStringFromCString("<handle>"));

  File* file = File::OpenFD(fd);

  Dart_Handle result = Dart_NewInteger(reinterpret_cast<intptr_t>(file));
  if (Dart_IsError(result)) {
    file->Release();
    Dart_PropagateError(result);
  }
  dart_new_args[0] = result;

  Dart_Handle new_random_access_file =
      Dart_New(random_access_file_type,
               /*constructor_name=*/Dart_Null(),
               /*number_of_arguments=*/2, dart_new_args);
  if (Dart_IsError(new_random_access_file)) {
    file->Release();
    Dart_PropagateError(new_random_access_file);
  }

  Dart_SetReturnValue(args, new_random_access_file);
#endif  // defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
}

void FUNCTION_NAME(ResourceHandleImpl_toSocket)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args,
                      DartUtils::NewDartUnsupportedError(
                          "This is not supported on this operating system"));
}

void FUNCTION_NAME(ResourceHandleImpl_toRawSocket)(Dart_NativeArguments args) {
#if defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
  Dart_SetReturnValue(args,
                      DartUtils::NewDartUnsupportedError(
                          "This is not supported on this operating system"));
#else
  Dart_Handle handle_object = ThrowIfError(Dart_GetNativeArgument(args, 0));
  Dart_Handle handle_field = ThrowIfError(
      Dart_GetField(handle_object, DartUtils::NewString("_handle")));
  intptr_t fd = DartUtils::GetIntegerValue(handle_field);

  SocketAddress* socket_address = reinterpret_cast<SocketAddress*>(
      Dart_ScopeAllocate(sizeof(SocketAddress)));
  ASSERT(socket_address != nullptr);
  SocketBase::GetSocketName(fd, socket_address);

  // return a list describing socket_address: (type, hostname, typed_data_addr,
  // fd)
  Dart_Handle list = ThrowIfError(Dart_NewList(4));
  ThrowIfError(Dart_ListSetAt(
      list, 0, ThrowIfError(Dart_NewInteger(socket_address->GetType()))));
  ThrowIfError(Dart_ListSetAt(
      list, 1,
      ThrowIfError(Dart_NewStringFromCString(socket_address->as_string()))));
  ThrowIfError(Dart_ListSetAt(
      list, 2, SocketAddress::ToTypedData(socket_address->addr())));
  ThrowIfError(Dart_ListSetAt(list, 3, ThrowIfError(Dart_NewInteger(fd))));

  Dart_SetReturnValue(args, list);
#endif  // defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_FUCHSIA)
}

void FUNCTION_NAME(ResourceHandleImpl_toRawDatagramSocket)(
    Dart_NativeArguments args) {
  Dart_SetReturnValue(args,
                      DartUtils::NewDartUnsupportedError(
                          "This is not supported on this operating system"));
}

}  // namespace bin
}  // namespace dart
