// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_EVENTHANDLER_FUCHSIA_H_
#define RUNTIME_BIN_EVENTHANDLER_FUCHSIA_H_

#if !defined(RUNTIME_BIN_EVENTHANDLER_H_)
#error Do not include eventhandler_fuchsia.h directly; use eventhandler.h.
#endif

#include <errno.h>
#include <magenta/status.h>
#include <magenta/syscalls.h>
#include <magenta/syscalls/object.h>
#include <magenta/syscalls/port.h>
#include <mxio/private.h>
#include <sys/socket.h>
#include <unistd.h>

#include "bin/reference_counting.h"
#include "bin/thread.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

class DescriptorInfo;

class IOHandle : public ReferenceCounted<IOHandle> {
 public:
  explicit IOHandle(intptr_t fd)
      : ReferenceCounted(),
        mutex_(new Mutex()),
        write_events_enabled_(true),
        read_events_enabled_(true),
        fd_(fd),
        handle_(MX_HANDLE_INVALID),
        wait_key_(0),
        mxio_(__mxio_fd_to_io(fd)) {}

  intptr_t fd() const { return fd_; }

  // Called from SocketBase::{Read(), Write()} and ServerSocket::Accept() on
  // the Dart thread.
  intptr_t Read(void* buffer, intptr_t num_bytes);
  intptr_t Write(const void* buffer, intptr_t num_bytes);
  intptr_t Accept(struct sockaddr* addr, socklen_t* addrlen);

  // Called from the EventHandler thread.
  void Close();
  uint32_t MaskToEpollEvents(intptr_t mask);
  // If port is MX_HANDLE_INVALID, AsyncWait uses the port from the previous
  // call with a valid port handle.
  bool AsyncWait(mx_handle_t port, uint32_t events, uint64_t key);
  void CancelWait(mx_handle_t port, uint64_t key);
  uint32_t WaitEnd(mx_signals_t observed);
  intptr_t ToggleEvents(intptr_t event_mask);

  static intptr_t EpollEventsToMask(intptr_t events);

 private:
  ~IOHandle() {
    if (mxio_ != NULL) {
      __mxio_release(mxio_);
    }
    delete mutex_;
  }

  bool AsyncWaitLocked(mx_handle_t port, uint32_t events, uint64_t key);

  // Mutex that protects the state here.
  Mutex* mutex_;
  bool write_events_enabled_;
  bool read_events_enabled_;
  // TODO(zra): Add flag to enable/disable peer closed signal?
  intptr_t fd_;
  mx_handle_t handle_;
  mx_handle_t port_;
  uint64_t wait_key_;
  mxio_t* mxio_;

  friend class ReferenceCounted<IOHandle>;
  DISALLOW_COPY_AND_ASSIGN(IOHandle);
};

class DescriptorInfo : public DescriptorInfoBase {
 public:
  explicit DescriptorInfo(intptr_t fd) : DescriptorInfoBase(fd) {
    IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
    handle->Retain();
  }

  virtual ~DescriptorInfo() {
    IOHandle* handle = reinterpret_cast<IOHandle*>(fd_);
    handle->Release();
  }

  virtual void Close() {
    IOHandle* handle = reinterpret_cast<IOHandle*>(fd_);
    handle->Close();
  }

  IOHandle* io_handle() const { return reinterpret_cast<IOHandle*>(fd_); }

 private:
  DISALLOW_COPY_AND_ASSIGN(DescriptorInfo);
};

class DescriptorInfoSingle : public DescriptorInfoSingleMixin<DescriptorInfo> {
 public:
  explicit DescriptorInfoSingle(intptr_t fd)
      : DescriptorInfoSingleMixin(fd, false) {}
  virtual ~DescriptorInfoSingle() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(DescriptorInfoSingle);
};

class DescriptorInfoMultiple
    : public DescriptorInfoMultipleMixin<DescriptorInfo> {
 public:
  explicit DescriptorInfoMultiple(intptr_t fd)
      : DescriptorInfoMultipleMixin(fd, false) {}
  virtual ~DescriptorInfoMultiple() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(DescriptorInfoMultiple);
};

class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  ~EventHandlerImplementation();

  void UpdatePort(intptr_t old_mask, DescriptorInfo* di);

  // Gets the socket data structure for a given file
  // descriptor. Creates a new one if one is not found.
  DescriptorInfo* GetDescriptorInfo(intptr_t fd, bool is_listening);
  void SendData(intptr_t id, Dart_Port dart_port, int64_t data);
  void Start(EventHandler* handler);
  void Shutdown();

 private:
  static const uint64_t kInterruptPacketKey = 1;

  static void Poll(uword args);
  static void* GetHashmapKeyFromFd(intptr_t fd);
  static uint32_t GetHashmapHashFromFd(intptr_t fd);
  static void AddToPort(mx_handle_t port_handle, DescriptorInfo* di);
  static void RemoveFromPort(mx_handle_t port_handle, DescriptorInfo* di);

  int64_t GetTimeout() const;
  void HandlePacket(mx_port_packet_t* pkt);
  void HandleTimeout();
  void WakeupHandler(intptr_t id, Dart_Port dart_port, int64_t data);
  intptr_t GetPollEvents(intptr_t events);
  void HandleInterrupt(InterruptMessage* msg);

  HashMap socket_map_;
  TimeoutQueue timeout_queue_;
  bool shutdown_;
  mx_handle_t port_handle_;

  DISALLOW_COPY_AND_ASSIGN(EventHandlerImplementation);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_EVENTHANDLER_FUCHSIA_H_
