// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_EVENTHANDLER_ANDROID_H_
#define RUNTIME_BIN_EVENTHANDLER_ANDROID_H_

#if !defined(RUNTIME_BIN_EVENTHANDLER_H_)
#error Do not include eventhandler_android.h directly;
#error use eventhandler.h instead.
#endif

#include <errno.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <unistd.h>

#include "platform/hashmap.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

class DescriptorInfo : public DescriptorInfoBase {
 public:
  explicit DescriptorInfo(intptr_t fd) : DescriptorInfoBase(fd) {}

  virtual ~DescriptorInfo() {}

  intptr_t GetPollEvents();

  virtual void Close() {
    VOID_TEMP_FAILURE_RETRY(close(fd_));
    fd_ = -1;
  }

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

  void UpdateEpollInstance(intptr_t old_mask, DescriptorInfo* di);

  // Gets the socket data structure for a given file
  // descriptor. Creates a new one if one is not found.
  DescriptorInfo* GetDescriptorInfo(intptr_t fd, bool is_listening);
  void SendData(intptr_t id, Dart_Port dart_port, int64_t data);
  void Start(EventHandler* handler);
  void Shutdown();

 private:
  int64_t GetTimeout();
  void HandleEvents(struct epoll_event* events, int size);
  void HandleTimeout();
  static void Poll(uword args);
  void WakeupHandler(intptr_t id, Dart_Port dart_port, int64_t data);
  void HandleInterruptFd();
  void SetPort(intptr_t fd, Dart_Port dart_port, intptr_t mask);
  intptr_t GetPollEvents(intptr_t events, DescriptorInfo* di);
  static void* GetHashmapKeyFromFd(intptr_t fd);
  static uint32_t GetHashmapHashFromFd(intptr_t fd);

  HashMap socket_map_;
  TimeoutQueue timeout_queue_;
  bool shutdown_;
  int interrupt_fds_[2];
  int epoll_fd_;

  DISALLOW_COPY_AND_ASSIGN(EventHandlerImplementation);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_EVENTHANDLER_ANDROID_H_
