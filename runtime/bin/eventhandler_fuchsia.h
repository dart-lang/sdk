// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_EVENTHANDLER_FUCHSIA_H_
#define RUNTIME_BIN_EVENTHANDLER_FUCHSIA_H_

#if !defined(RUNTIME_BIN_EVENTHANDLER_H_)
#error Do not include eventhandler_fuchsia.h directly; use eventhandler.h instead.
#endif

#include <errno.h>
#include <magenta/syscalls.h>

#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

class DescriptorInfo : public DescriptorInfoBase {
 public:
  explicit DescriptorInfo(intptr_t fd) : DescriptorInfoBase(fd) { }

  virtual ~DescriptorInfo() { }

  virtual void Close() {
    VOID_TEMP_FAILURE_RETRY(close(fd_));
    fd_ = -1;
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(DescriptorInfo);
};

class DescriptorInfoSingle
    : public DescriptorInfoSingleMixin<DescriptorInfo> {
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

// Information needed to call mx_handle_wait_many(), and to handle events.
class MagentaWaitManyInfo {
 public:
  MagentaWaitManyInfo();
  ~MagentaWaitManyInfo();

  intptr_t capacity() const { return capacity_; }
  intptr_t size() const { return size_; }
  DescriptorInfo** descriptor_infos() const { return descriptor_infos_; }
  mx_handle_t* handles() const { return handles_; }
  mx_signals_t* signals() const { return signals_; }
  mx_signals_state_t* signals_states() const { return signals_states_; }

  void AddHandle(mx_handle_t handle, mx_signals_t signals, DescriptorInfo* di);
  void RemoveHandle(mx_handle_t handle);

 private:
  static const intptr_t kInitialCapacity = 32;

  void GrowArraysIfNeeded(intptr_t desired_size);

  intptr_t capacity_;
  intptr_t size_;
  DescriptorInfo** descriptor_infos_;
  mx_handle_t* handles_;
  mx_signals_t* signals_;
  mx_signals_state_t* signals_states_;

  DISALLOW_COPY_AND_ASSIGN(MagentaWaitManyInfo);
};

class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  ~EventHandlerImplementation();

  void SendData(intptr_t id, Dart_Port dart_port, int64_t data);
  void Start(EventHandler* handler);
  void Shutdown();

  const MagentaWaitManyInfo& info() const { return info_; }

 private:
  int64_t GetTimeout() const;
  void HandleEvents();
  void HandleTimeout();
  void WakeupHandler(intptr_t id, Dart_Port dart_port, int64_t data);
  void HandleInterruptFd();
  static void Poll(uword args);

  TimeoutQueue timeout_queue_;
  bool shutdown_;
  mx_handle_t interrupt_handles_[2];

  MagentaWaitManyInfo info_;

  DISALLOW_COPY_AND_ASSIGN(EventHandlerImplementation);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_EVENTHANDLER_FUCHSIA_H_
