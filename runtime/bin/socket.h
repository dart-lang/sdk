// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SOCKET_H_
#define RUNTIME_BIN_SOCKET_H_

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/reference_counting.h"
#include "bin/socket_base.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/hashmap.h"

namespace dart {
namespace bin {

// TODO(bkonyi): Socket should also inherit from SocketBase once it is
// refactored to use instance methods when possible.

// We write Sockets into the native field of the _NativeSocket object
// on the Dart side. They are allocated in SetSocketIdNativeField(), and are
// deallocated either from the finalizer attached to _NativeSockets there, or
// from the eventhandler, whichever drops the last reference.
class Socket : public ReferenceCounted<Socket> {
 public:
  enum SocketRequest {
    kLookupRequest = 0,
    kListInterfacesRequest = 1,
    kReverseLookupRequest = 2,
  };

  enum SocketFinalizer {
    kFinalizerNormal,
    kFinalizerListening,
    kFinalizerStdio,
    kFinalizerSignal,
  };

  // Keep in sync with constants in _NativeSocket in socket_patch.dart.
  enum SocketType {
    kTcpSocket = 18,
    kUdpSocket = 19,
    kInternalSocket = 20,
    kInternalSignalSocket = 21,
  };

  explicit Socket(intptr_t fd);

  intptr_t fd() const { return fd_; }

  // Close fd and may need to decrement the count of handle by calling
  // release().
  void CloseFd();
  // Set fd_ to closed. On fuchsia and win, shared socket should not
  // release handle but only SetClosedFd().
  void SetClosedFd();

  Dart_Port isolate_port() const { return isolate_port_; }

  Dart_Port port() const { return port_; }
  void set_port(Dart_Port port) { port_ = port; }

  uint8_t* udp_receive_buffer() const { return udp_receive_buffer_; }
  void set_udp_receive_buffer(uint8_t* buffer) { udp_receive_buffer_ = buffer; }

  static bool Initialize();

  // Creates a socket which is bound and connected. The port to connect to is
  // specified as the port component of the passed RawAddr structure.
  static intptr_t CreateConnect(const RawAddr& addr);
  static intptr_t CreateUnixDomainConnect(const RawAddr& addr);
  // Creates a socket which is bound and connected. The port to connect to is
  // specified as the port component of the passed RawAddr structure.
  static intptr_t CreateBindConnect(const RawAddr& addr,
                                    const RawAddr& source_addr);
  static intptr_t CreateUnixDomainBindConnect(const RawAddr& addr,
                                              const RawAddr& source_addr);
  // Creates a datagram socket which is bound. The port to bind
  // to is specified as the port component of the RawAddr structure.
  static intptr_t CreateBindDatagram(const RawAddr& addr,
                                     bool reuseAddress,
                                     bool reusePort,
                                     int ttl = 1);

  static CObject* LookupRequest(const CObjectArray& request);
  static CObject* ListInterfacesRequest(const CObjectArray& request);
  static CObject* ReverseLookupRequest(const CObjectArray& request);

  static Dart_Port GetServicePort();

  static void SetSocketIdNativeField(Dart_Handle handle,
                                     intptr_t id,
                                     SocketFinalizer finalizer);
  static void ReuseSocketIdNativeField(Dart_Handle handle,
                                       Socket* socket,
                                       SocketFinalizer finalizer);
  static Socket* GetSocketIdNativeField(Dart_Handle socket);

  static bool short_socket_read() { return short_socket_read_; }
  static void set_short_socket_read(bool short_socket_read) {
    short_socket_read_ = short_socket_read;
  }
  static bool short_socket_write() { return short_socket_write_; }
  static void set_short_socket_write(bool short_socket_write) {
    short_socket_write_ = short_socket_write;
  }

  static bool IsSignalSocketFlag(intptr_t flag) {
    return ((flag & (0x1 << kInternalSignalSocket)) != 0);
  }

 private:
  ~Socket() {
    ASSERT(fd_ == kClosedFd);
    free(udp_receive_buffer_);
    udp_receive_buffer_ = NULL;
  }

  static const int kClosedFd = -1;

  static bool short_socket_read_;
  static bool short_socket_write_;

  intptr_t fd_;
  Dart_Port isolate_port_;
  Dart_Port port_;
  uint8_t* udp_receive_buffer_;

  friend class ReferenceCounted<Socket>;
  DISALLOW_COPY_AND_ASSIGN(Socket);
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
  static intptr_t CreateUnixDomainBindListen(const RawAddr& addr,
                                             intptr_t backlog);

  // Start accepting on a newly created listening socket. If it was unable to
  // start accepting incoming sockets, the fd is invalidated.
  static bool StartAccept(intptr_t fd);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ServerSocket);
};

class ListeningSocketRegistry {
 public:
  ListeningSocketRegistry()
      : sockets_by_port_(SameIntptrValue, kInitialSocketsCount),
        sockets_by_fd_(SameIntptrValue, kInitialSocketsCount),
        unix_domain_sockets_(nullptr),
        mutex_() {}

  ~ListeningSocketRegistry() {
    CloseAllSafe();
  }

  static void Initialize();

  static ListeningSocketRegistry* Instance();

  static void Cleanup();

  // Bind `socket_object` to `addr`.
  // Return Dart_True() if succeed.
  // This function should be called from a dart runtime call in order to create
  // a new (potentially shared) socket.
  Dart_Handle CreateBindListen(Dart_Handle socket_object,
                               RawAddr addr,
                               intptr_t backlog,
                               bool v6_only,
                               bool shared);
  // Bind unix domain socket`socket_object` to `path`.
  // Return Dart_True() if succeed.
  // This function should be called from a dart runtime call in order to create
  // a new socket.
  Dart_Handle CreateUnixDomainBindListen(Dart_Handle socket_object,
                                         Namespace* namespc,
                                         const char* path,
                                         intptr_t backlog,
                                         bool shared);

  // This should be called from the event handler for every kCloseEvent it gets
  // on listening sockets.
  //
  // Returns `true` if the last reference has been dropped and the underlying
  // socket can be closed.
  //
  // The caller is responsible for obtaining the mutex first, before calling
  // this function.
  bool CloseSafe(Socket* socketfd);

  Mutex* mutex() { return &mutex_; }

 private:
  struct OSSocket {
    RawAddr address;
    int port;
    bool v6_only;
    bool shared;
    int ref_count;
    intptr_t fd;

    // Only applicable to Unix domain socket, where address.addr.sa_family
    // == AF_UNIX.
    Namespace* namespc;

    // Singly linked lists of OSSocket instances which listen on the same port
    // but on different addresses.
    OSSocket* next;

    OSSocket(RawAddr address,
             int port,
             bool v6_only,
             bool shared,
             Socket* socketfd,
             Namespace* namespc)
        : address(address),
          port(port),
          v6_only(v6_only),
          shared(shared),
          ref_count(0),
          namespc(namespc),
          next(NULL) {
      fd = socketfd->fd();
    }
  };

  static const intptr_t kInitialSocketsCount = 8;

  OSSocket* FindOSSocketWithAddress(OSSocket* current, const RawAddr& addr) {
    while (current != NULL) {
      if (SocketAddress::AreAddressesEqual(current->address, addr)) {
        return current;
      }
      current = current->next;
    }
    return NULL;
  }

  OSSocket* FindOSSocketWithPath(OSSocket* current,
                                 Namespace* namespc,
                                 const char* path) {
    while (current != NULL) {
      ASSERT(current->address.addr.sa_family == AF_UNIX);
#if defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
      bool condition;
      if (path[0] == '\0') {
        condition = current->address.un.sun_path[0] == '\0' &&
                    strcmp(&(current->address.un.sun_path[1]), path + 1) == 0;
      } else {
        condition =
            File::AreIdentical(current->namespc, current->address.un.sun_path,
                               namespc, path) == File::kIdentical;
      }
      if (condition) {
        return current;
      }
#else
      if (File::AreIdentical(current->namespc, current->address.un.sun_path,
                             namespc, path) == File::kIdentical) {
        return current;
      }
#endif  // defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
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

  OSSocket* LookupByFd(Socket* fd);
  void InsertByFd(Socket* fd, OSSocket* socket);
  void RemoveByFd(Socket* fd);

  bool CloseOneSafe(OSSocket* os_socket, Socket* socket);
  void CloseAllSafe();

  SimpleHashMap sockets_by_port_;
  SimpleHashMap sockets_by_fd_;

  OSSocket* unix_domain_sockets_;

  Mutex mutex_;

  DISALLOW_COPY_AND_ASSIGN(ListeningSocketRegistry);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SOCKET_H_
