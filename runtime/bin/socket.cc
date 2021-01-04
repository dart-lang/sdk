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
#include "bin/utils.h"

#include "include/dart_api.h"

#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

static const int kSocketIdNativeField = 0;

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
        Socket* socketfd = new Socket(os_socket->fd);
        os_socket->ref_count++;
        // We set as a side-effect the file descriptor on the dart
        // socket_object.
        Socket::ReuseSocketIdNativeField(socket_object, socketfd,
                                         Socket::kFinalizerListening);
        InsertByFd(socketfd, os_socket);
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

#if defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
  // Abstract unix domain socket doesn't exist in file system.
  if (File::Exists(namespc, addr.un.sun_path) && path[0] != '@') {
#else
  if (File::Exists(namespc, addr.un.sun_path)) {
#endif  // defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
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
        Socket* socketfd = new Socket(os_socket->fd);
        os_socket->ref_count++;
        // We set as a side-effect the file descriptor on the dart
        // socket_object.
        Socket::ReuseSocketIdNativeField(socket_object, socketfd,
                                         Socket::kFinalizerListening);
        InsertByFd(socketfd, os_socket);
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
#if defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
    // If the socket is abstract, which has a path starting with a null byte,
    // unlink() is not necessary because the file doesn't exist.
    if (os_socket->address.un.sun_path[0] != '\0') {
      Utils::Unlink(os_socket->address.un.sun_path);
    }
#else
    Utils::Unlink(os_socket->address.un.sun_path);
#endif  // defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
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

void FUNCTION_NAME(Socket_CreateBindConnect)(Dart_NativeArguments args) {
  RawAddr addr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 1), &addr);
  Dart_Handle port_arg = Dart_GetNativeArgument(args, 2);
  int64_t port = DartUtils::GetInt64ValueCheckRange(port_arg, 0, 65535);
  SocketAddress::SetAddrPort(&addr, static_cast<intptr_t>(port));
  RawAddr sourceAddr;
  SocketAddress::GetSockAddr(Dart_GetNativeArgument(args, 3), &sourceAddr);
  if (addr.addr.sa_family == AF_INET6) {
    Dart_Handle scope_id_arg = Dart_GetNativeArgument(args, 4);
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
#if defined(HOST_OS_WINDOWS) || defined(HOST_OS_FUCHSIA)
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
#endif  // defined(HOST_OS_WINDOWS) || defined(HOST_OS_FUCHSIA)
}

void FUNCTION_NAME(Socket_CreateUnixDomainConnect)(Dart_NativeArguments args) {
#if defined(HOST_OS_WINDOWS) || defined(HOST_OS_FUCHSIA)
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
#endif  // defined(HOST_OS_WINDOWS) || defined(HOST_OS_FUCHSIA)
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
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_ThrowException(DartUtils::NewDartOSError(&os_error));
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

  // Memory Sanitizer complains addr not being initialized, which is done
  // through RecvFrom().
  // Issue: https://github.com/google/sanitizers/issues/1201
  MSAN_UNPOISON(&addr, sizeof(RawAddr));

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
  Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
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
#if defined(HOST_OS_WINDOWS)
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
#endif  // defined(HOST_OS_WINDOWS)
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
  int64_t protocol = DartUtils::GetInt64ValueCheckRange(
      Dart_GetNativeArgument(args, 2), SocketAddress::TYPE_IPV4,
      SocketAddress::TYPE_IPV6);
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
  if (socket->fd() >= 0) {
    const int64_t flags = 1 << kCloseCommand;
    socket->Retain();
    EventHandler::SendFromNative(reinterpret_cast<intptr_t>(socket),
                                 socket->port(), flags);
  }
  socket->Release();
}

static void ListeningSocketFinalizer(void* isolate_data, void* data) {
  Socket* socket = reinterpret_cast<Socket*>(data);
  if (socket->fd() >= 0) {
    const int64_t flags = (1 << kListeningSocket) | (1 << kCloseCommand);
    socket->Retain();
    EventHandler::SendFromNative(reinterpret_cast<intptr_t>(socket),
                                 socket->port(), flags);
  }
  socket->Release();
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
  if (socket->fd() >= 0) {
    Process::ClearSignalHandlerByFd(socket->fd(), socket->isolate_port());
    const int64_t flags = 1 << kCloseCommand;
    socket->Retain();
    EventHandler::SendFromNative(reinterpret_cast<intptr_t>(socket),
                                 socket->port(), flags);
  }

  socket->Release();
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
      callback = NULL;
      UNREACHABLE();
      break;
  }
  if (callback != NULL) {
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

}  // namespace bin
}  // namespace dart
