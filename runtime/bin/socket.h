// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SOCKET_H_
#define RUNTIME_BIN_SOCKET_H_

#include "bin/builtin.h"
#include "bin/dartutils.h"
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
  };

  explicit Socket(intptr_t fd);

  intptr_t fd() const { return fd_; }
  void SetClosedFd();

  Dart_Port port() const { return port_; }
  void set_port(Dart_Port port) { port_ = port; }

  static bool Initialize();

  // Creates a socket which is bound and connected. The port to connect to is
  // specified as the port component of the passed RawAddr structure.
  static intptr_t CreateConnect(const RawAddr& addr);
  // Creates a socket which is bound and connected. The port to connect to is
  // specified as the port component of the passed RawAddr structure.
  static intptr_t CreateBindConnect(const RawAddr& addr,
                                    const RawAddr& source_addr);
  // Creates a datagram socket which is bound. The port to bind
  // to is specified as the port component of the RawAddr structure.
  static intptr_t CreateBindDatagram(const RawAddr& addr, bool reuseAddress);

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

 private:
  ~Socket() { ASSERT(fd_ == kClosedFd); }

  static const int kClosedFd = -1;

  intptr_t fd_;
  Dart_Port port_;

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
        mutex_(new Mutex()) {}

  ~ListeningSocketRegistry() {
    CloseAllSafe();
    delete mutex_;
    mutex_ = NULL;
  }

  static void Initialize();

  static ListeningSocketRegistry* Instance();

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
  bool CloseSafe(Socket* socketfd);

  Mutex* mutex() { return mutex_; }

 private:
  struct OSSocket {
    RawAddr address;
    int port;
    bool v6_only;
    bool shared;
    int ref_count;
    Socket* socketfd;

    // Singly linked lists of OSSocket instances which listen on the same port
    // but on different addresses.
    OSSocket* next;

    OSSocket(RawAddr address,
             int port,
             bool v6_only,
             bool shared,
             Socket* socketfd)
        : address(address),
          port(port),
          v6_only(v6_only),
          shared(shared),
          ref_count(0),
          socketfd(socketfd),
          next(NULL) {}
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

  bool CloseOneSafe(OSSocket* os_socket, bool update_hash_maps);
  void CloseAllSafe();

  HashMap sockets_by_port_;
  HashMap sockets_by_fd_;

  Mutex* mutex_;

  DISALLOW_COPY_AND_ASSIGN(ListeningSocketRegistry);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SOCKET_H_
