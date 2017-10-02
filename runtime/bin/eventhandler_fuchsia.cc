// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/eventhandler.h"
#include "bin/eventhandler_fuchsia.h"

#include <errno.h>
#include <fcntl.h>
#include <fdio/private.h>
#include <poll.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>
#include <zircon/syscalls/object.h>
#include <zircon/syscalls/port.h>

#include "bin/fdutils.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/hashmap.h"
#include "platform/utils.h"

// The EventHandler for Fuchsia uses its "ports v2" API:
// https://fuchsia.googlesource.com/zircon/+/HEAD/docs/syscalls/port_create.md
// This API does not have epoll()-like edge triggering (EPOLLET). Since clients
// of the EventHandler expect edge-triggered notifications, we must simulate it.
// When a packet from zx_port_wait() indicates that a signal is asserted for a
// handle, we unsubscribe from that signal until the event that asserted the
// signal can be processed. For example:
//
// 1. We get ZX_SOCKET_WRITABLE from zx_port_wait() for a handle.
// 2. We send kOutEvent to the Dart thread.
// 3. We unsubscribe from further ZX_SOCKET_WRITABLE signals for the handle.
// 4. Some time later the Dart thread actually does a write().
// 5. After writing, the Dart thread resubscribes to write events.
//
// We use he same procedure for ZX_SOCKET_READABLE, and read()/accept().

// define EVENTHANDLER_LOG_ERROR to get log messages only for errors.
// define EVENTHANDLER_LOG_INFO to get log messages for both information and
//   errors.
// #define EVENTHANDLER_LOG_INFO 1
#define EVENTHANDLER_LOG_ERROR 1
#if defined(EVENTHANDLER_LOG_INFO) || defined(EVENTHANDLER_LOG_ERROR)
#define LOG_ERR(msg, ...)                                                      \
  {                                                                            \
    int err = errno;                                                           \
    Log::PrintErr("Dart EventHandler ERROR: %s:%d: " msg, __FILE__, __LINE__,  \
                  ##__VA_ARGS__);                                              \
    errno = err;                                                               \
  }
#if defined(EVENTHANDLER_LOG_INFO)
#define LOG_INFO(msg, ...)                                                     \
  Log::Print("Dart EventHandler INFO: %s:%d: " msg, __FILE__, __LINE__,        \
             ##__VA_ARGS__)
#else
#define LOG_INFO(msg, ...)
#endif  // defined(EVENTHANDLER_LOG_INFO)
#else
#define LOG_ERR(msg, ...)
#define LOG_INFO(msg, ...)
#endif  // defined(EVENTHANDLER_LOG_INFO) || defined(EVENTHANDLER_LOG_ERROR)

namespace dart {
namespace bin {

intptr_t IOHandle::Read(void* buffer, intptr_t num_bytes) {
  MutexLocker ml(mutex_);
  const ssize_t read_bytes = NO_RETRY_EXPECTED(read(fd_, buffer, num_bytes));
  const int err = errno;
  LOG_INFO("IOHandle::Read: fd = %ld. read %ld bytes\n", fd_, read_bytes);

  // Resubscribe to read events. We resubscribe to events even if read() returns
  // an error. The error might be, e.g. EWOULDBLOCK, in which case
  // re-subscription is necessary. Logic in the caller decides which errors are
  // real, and which are ignore-and-continue.
  read_events_enabled_ = true;
  if (!AsyncWaitLocked(ZX_HANDLE_INVALID, POLLIN, wait_key_)) {
    LOG_ERR("IOHandle::AsyncWait failed for fd = %ld\n", fd_);
  }

  errno = err;
  return read_bytes;
}

intptr_t IOHandle::Write(const void* buffer, intptr_t num_bytes) {
  MutexLocker ml(mutex_);
  const ssize_t written_bytes =
      NO_RETRY_EXPECTED(write(fd_, buffer, num_bytes));
  const int err = errno;
  LOG_INFO("IOHandle::Write: fd = %ld. wrote %ld bytes\n", fd_, written_bytes);

  // Resubscribe to write events.
  write_events_enabled_ = true;
  if (!AsyncWaitLocked(ZX_HANDLE_INVALID, POLLOUT, wait_key_)) {
    LOG_ERR("IOHandle::AsyncWait failed for fd = %ld\n", fd_);
  }

  errno = err;
  return written_bytes;
}

intptr_t IOHandle::Accept(struct sockaddr* addr, socklen_t* addrlen) {
  MutexLocker ml(mutex_);
  const intptr_t socket = NO_RETRY_EXPECTED(accept(fd_, addr, addrlen));
  const int err = errno;
  LOG_INFO("IOHandle::Accept: fd = %ld. socket = %ld\n", fd_, socket);

  // Re-subscribe to read events.
  read_events_enabled_ = true;
  if (!AsyncWaitLocked(ZX_HANDLE_INVALID, POLLIN, wait_key_)) {
    LOG_ERR("IOHandle::AsyncWait failed for fd = %ld\n", fd_);
  }

  errno = err;
  return socket;
}

void IOHandle::Close() {
  MutexLocker ml(mutex_);
  VOID_NO_RETRY_EXPECTED(close(fd_));
}

uint32_t IOHandle::MaskToEpollEvents(intptr_t mask) {
  MutexLocker ml(mutex_);
  // Do not ask for POLLERR and POLLHUP explicitly as they are
  // triggered anyway.
  uint32_t events = POLLRDHUP;
  if (read_events_enabled_ && ((mask & (1 << kInEvent)) != 0)) {
    events |= POLLIN;
  }
  if (write_events_enabled_ && ((mask & (1 << kOutEvent)) != 0)) {
    events |= POLLOUT;
  }
  return events;
}

intptr_t IOHandle::EpollEventsToMask(intptr_t events) {
  if ((events & POLLERR) != 0) {
    // Return error only if POLLIN is present.
    return ((events & POLLIN) != 0) ? (1 << kErrorEvent) : 0;
  }
  intptr_t event_mask = 0;
  if ((events & POLLIN) != 0) {
    event_mask |= (1 << kInEvent);
  }
  if ((events & POLLOUT) != 0) {
    event_mask |= (1 << kOutEvent);
  }
  if ((events & (POLLHUP | POLLRDHUP)) != 0) {
    event_mask |= (1 << kCloseEvent);
  }
  return event_mask;
}

bool IOHandle::AsyncWaitLocked(zx_handle_t port,
                               uint32_t events,
                               uint64_t key) {
  LOG_INFO("IOHandle::AsyncWait: fd = %ld\n", fd_);
  // The call to __fdio_fd_to_io() in the DescriptorInfo constructor may have
  // returned NULL. If it did, propagate the problem up to Dart.
  if (fdio_ == NULL) {
    LOG_ERR("__fdio_fd_to_io(%d) returned NULL\n", fd_);
    return false;
  }

  zx_handle_t handle;
  zx_signals_t signals;
  __fdio_wait_begin(fdio_, events, &handle, &signals);
  if (handle == ZX_HANDLE_INVALID) {
    LOG_ERR("fd = %ld __fdio_wait_begin returned an invalid handle\n", fd_);
    return false;
  }

  // Remember the port. Use the remembered port if the argument "port" is
  // ZX_HANDLE_INVALID.
  ASSERT((port != ZX_HANDLE_INVALID) || (port_ != ZX_HANDLE_INVALID));
  if ((port_ == ZX_HANDLE_INVALID) || (port != ZX_HANDLE_INVALID)) {
    port_ = port;
  }

  handle_ = handle;
  wait_key_ = key;
  LOG_INFO("zx_object_wait_async(fd = %ld, signals = %x)\n", fd_, signals);
  zx_status_t status =
      zx_object_wait_async(handle_, port_, key, signals, ZX_WAIT_ASYNC_ONCE);
  if (status != ZX_OK) {
    LOG_ERR("zx_object_wait_async failed: %s\n", zx_status_get_string(status));
    return false;
  }

  return true;
}

bool IOHandle::AsyncWait(zx_handle_t port, uint32_t events, uint64_t key) {
  MutexLocker ml(mutex_);
  return AsyncWaitLocked(port, events, key);
}

void IOHandle::CancelWait(zx_handle_t port, uint64_t key) {
  MutexLocker ml(mutex_);
  LOG_INFO("IOHandle::CancelWait: fd = %ld\n", fd_);
  ASSERT(port != ZX_HANDLE_INVALID);
  ASSERT(handle_ != ZX_HANDLE_INVALID);
  zx_status_t status = zx_port_cancel(port, handle_, key);
  if ((status != ZX_OK) && (status != ZX_ERR_NOT_FOUND)) {
    LOG_ERR("zx_port_cancel failed: %s\n", zx_status_get_string(status));
  }
}

uint32_t IOHandle::WaitEnd(zx_signals_t observed) {
  MutexLocker ml(mutex_);
  uint32_t events = 0;
  __fdio_wait_end(fdio_, observed, &events);
  return events;
}

intptr_t IOHandle::ToggleEvents(intptr_t event_mask) {
  MutexLocker ml(mutex_);
  if (!write_events_enabled_) {
    LOG_INFO("IOHandle::ToggleEvents: fd = %ld de-asserting write\n", fd_);
    event_mask = event_mask & ~(1 << kOutEvent);
  }
  if ((event_mask & (1 << kOutEvent)) != 0) {
    LOG_INFO("IOHandle::ToggleEvents: fd = %ld asserting write and disabling\n",
             fd_);
    write_events_enabled_ = false;
  }
  if (!read_events_enabled_) {
    LOG_INFO("IOHandle::ToggleEvents: fd=%ld de-asserting read\n", fd_);
    event_mask = event_mask & ~(1 << kInEvent);
  }
  if ((event_mask & (1 << kInEvent)) != 0) {
    LOG_INFO("IOHandle::ToggleEvents: fd = %ld asserting read and disabling\n",
             fd_);
    read_events_enabled_ = false;
  }
  return event_mask;
}

void EventHandlerImplementation::AddToPort(zx_handle_t port_handle,
                                           DescriptorInfo* di) {
  const uint32_t events = di->io_handle()->MaskToEpollEvents(di->Mask());
  const uint64_t key = reinterpret_cast<uint64_t>(di);
  if (!di->io_handle()->AsyncWait(port_handle, events, key)) {
    di->NotifyAllDartPorts(1 << kCloseEvent);
  }
}

void EventHandlerImplementation::RemoveFromPort(zx_handle_t port_handle,
                                                DescriptorInfo* di) {
  const uint64_t key = reinterpret_cast<uint64_t>(di);
  di->io_handle()->CancelWait(port_handle, key);
}

EventHandlerImplementation::EventHandlerImplementation()
    : socket_map_(&HashMap::SamePointerValue, 16) {
  shutdown_ = false;
  // Create the port.
  port_handle_ = ZX_HANDLE_INVALID;
  zx_status_t status = zx_port_create(0, &port_handle_);
  if (status != ZX_OK) {
    // This is a FATAL because the VM won't work at all if we can't create this
    // port.
    FATAL1("zx_port_create failed: %s\n", zx_status_get_string(status));
  }
  ASSERT(port_handle_ != ZX_HANDLE_INVALID);
}

static void DeleteDescriptorInfo(void* info) {
  DescriptorInfo* di = reinterpret_cast<DescriptorInfo*>(info);
  LOG_INFO("Closed %ld\n", di->io_handle()->fd());
  di->Close();
  delete di;
}

EventHandlerImplementation::~EventHandlerImplementation() {
  socket_map_.Clear(DeleteDescriptorInfo);
  zx_handle_close(port_handle_);
  port_handle_ = ZX_HANDLE_INVALID;
}

void EventHandlerImplementation::UpdatePort(intptr_t old_mask,
                                            DescriptorInfo* di) {
  const intptr_t new_mask = di->Mask();
  if ((old_mask != 0) && (new_mask == 0)) {
    RemoveFromPort(port_handle_, di);
  } else if ((old_mask == 0) && (new_mask != 0)) {
    AddToPort(port_handle_, di);
  } else if ((old_mask != 0) && (new_mask != 0)) {
    ASSERT(!di->IsListeningSocket());
    RemoveFromPort(port_handle_, di);
    AddToPort(port_handle_, di);
  }
}

DescriptorInfo* EventHandlerImplementation::GetDescriptorInfo(
    intptr_t fd,
    bool is_listening) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  ASSERT(handle->fd() >= 0);
  HashMap::Entry* entry =
      socket_map_.Lookup(GetHashmapKeyFromFd(handle->fd()),
                         GetHashmapHashFromFd(handle->fd()), true);
  ASSERT(entry != NULL);
  DescriptorInfo* di = reinterpret_cast<DescriptorInfo*>(entry->value);
  if (di == NULL) {
    // If there is no data in the hash map for this file descriptor a
    // new DescriptorInfo for the file descriptor is inserted.
    if (is_listening) {
      di = new DescriptorInfoMultiple(fd);
    } else {
      di = new DescriptorInfoSingle(fd);
    }
    entry->value = di;
  }
  ASSERT(fd == di->fd());
  return di;
}

void EventHandlerImplementation::WakeupHandler(intptr_t id,
                                               Dart_Port dart_port,
                                               int64_t data) {
  COMPILE_ASSERT(sizeof(InterruptMessage) <= sizeof(zx_packet_user_t));
  zx_port_packet_t pkt;
  InterruptMessage* msg = reinterpret_cast<InterruptMessage*>(&pkt.user);
  pkt.key = kInterruptPacketKey;
  msg->id = id;
  msg->dart_port = dart_port;
  msg->data = data;
  zx_status_t status = zx_port_queue(port_handle_, &pkt, 0);
  if (status != ZX_OK) {
    // This is a FATAL because the VM won't work at all if we can't send any
    // messages to the EventHandler thread.
    FATAL1("zx_port_queue failed: %s\n", zx_status_get_string(status));
  }
}

void EventHandlerImplementation::HandleInterrupt(InterruptMessage* msg) {
  if (msg->id == kTimerId) {
    LOG_INFO("HandleInterrupt read timer update\n");
    timeout_queue_.UpdateTimeout(msg->dart_port, msg->data);
    return;
  } else if (msg->id == kShutdownId) {
    LOG_INFO("HandleInterrupt read shutdown\n");
    shutdown_ = true;
    return;
  }
  ASSERT((msg->data & COMMAND_MASK) != 0);
  LOG_INFO("HandleInterrupt command:\n");
  Socket* socket = reinterpret_cast<Socket*>(msg->id);
  RefCntReleaseScope<Socket> rs(socket);
  if (socket->fd() == -1) {
    return;
  }
  IOHandle* io_handle = reinterpret_cast<IOHandle*>(socket->fd());
  const intptr_t fd = io_handle->fd();
  DescriptorInfo* di =
      GetDescriptorInfo(socket->fd(), IS_LISTENING_SOCKET(msg->data));
  ASSERT(io_handle == di->io_handle());
  if (IS_COMMAND(msg->data, kShutdownReadCommand)) {
    ASSERT(!di->IsListeningSocket());
    // Close the socket for reading.
    LOG_INFO("\tSHUT_RD: %ld\n", fd);
    VOID_NO_RETRY_EXPECTED(shutdown(fd, SHUT_RD));
  } else if (IS_COMMAND(msg->data, kShutdownWriteCommand)) {
    ASSERT(!di->IsListeningSocket());
    // Close the socket for writing.
    LOG_INFO("\tSHUT_WR: %ld\n", fd);
    VOID_NO_RETRY_EXPECTED(shutdown(fd, SHUT_WR));
  } else if (IS_COMMAND(msg->data, kCloseCommand)) {
    // Close the socket and free system resources and move on to next
    // message.
    const intptr_t old_mask = di->Mask();
    Dart_Port port = msg->dart_port;
    di->RemovePort(port);
    const intptr_t new_mask = di->Mask();
    UpdatePort(old_mask, di);

    LOG_INFO("\tCLOSE: %ld: %lx -> %lx\n", fd, old_mask, new_mask);
    if (di->IsListeningSocket()) {
      // We only close the socket file descriptor from the operating
      // system if there are no other dart socket objects which
      // are listening on the same (address, port) combination.
      ListeningSocketRegistry* registry = ListeningSocketRegistry::Instance();

      MutexLocker locker(registry->mutex());

      if (registry->CloseSafe(socket)) {
        ASSERT(new_mask == 0);
        socket_map_.Remove(GetHashmapKeyFromFd(fd), GetHashmapHashFromFd(fd));
        di->Close();
        delete di;
        socket->SetClosedFd();
      }
    } else {
      ASSERT(new_mask == 0);
      socket_map_.Remove(GetHashmapKeyFromFd(fd), GetHashmapHashFromFd(fd));
      di->Close();
      delete di;
      socket->SetClosedFd();
    }
    if (port != 0) {
      const bool success = DartUtils::PostInt32(port, 1 << kDestroyedEvent);
      if (!success) {
        LOG_INFO("Failed to post destroy event to port %ld\n", port);
      }
    }
  } else if (IS_COMMAND(msg->data, kReturnTokenCommand)) {
    const int count = TOKEN_COUNT(msg->data);
    const intptr_t old_mask = di->Mask();
    LOG_INFO("\t Return Token: %ld: %lx\n", fd, old_mask);
    di->ReturnTokens(msg->dart_port, count);
    UpdatePort(old_mask, di);
  } else if (IS_COMMAND(msg->data, kSetEventMaskCommand)) {
    // `events` can only have kInEvent/kOutEvent flags set.
    const intptr_t events = msg->data & EVENT_MASK;
    ASSERT(0 == (events & ~(1 << kInEvent | 1 << kOutEvent)));

    const intptr_t old_mask = di->Mask();
    LOG_INFO("\t Set Event Mask: %ld: %lx %lx\n", fd, old_mask,
             msg->data & EVENT_MASK);
    di->SetPortAndMask(msg->dart_port, msg->data & EVENT_MASK);
    UpdatePort(old_mask, di);
  } else {
    UNREACHABLE();
  }
}

void EventHandlerImplementation::HandlePacket(zx_port_packet_t* pkt) {
  LOG_INFO("HandlePacket: Got event packet: key=%lx\n", pkt->key);
  LOG_INFO("HandlePacket: Got event packet: type=%lx\n", pkt->type);
  LOG_INFO("HandlePacket: Got event packet: status=%ld\n", pkt->status);
  if (pkt->type == ZX_PKT_TYPE_USER) {
    ASSERT(pkt->key == kInterruptPacketKey);
    InterruptMessage* msg = reinterpret_cast<InterruptMessage*>(&pkt->user);
    HandleInterrupt(msg);
    return;
  }
  LOG_INFO("HandlePacket: Got event packet: observed = %lx\n",
           pkt->signal.observed);
  LOG_INFO("HandlePacket: Got event packet: count = %ld\n", pkt->signal.count);

  DescriptorInfo* di = reinterpret_cast<DescriptorInfo*>(pkt->key);
  zx_signals_t observed = pkt->signal.observed;
  const intptr_t old_mask = di->Mask();
  const uint32_t epoll_event = di->io_handle()->WaitEnd(observed);
  intptr_t event_mask = IOHandle::EpollEventsToMask(epoll_event);
  if ((event_mask & (1 << kErrorEvent)) != 0) {
    di->NotifyAllDartPorts(event_mask);
  } else if (event_mask != 0) {
    event_mask = di->io_handle()->ToggleEvents(event_mask);
    if (event_mask != 0) {
      Dart_Port port = di->NextNotifyDartPort(event_mask);
      ASSERT(port != 0);
      bool success = DartUtils::PostInt32(port, event_mask);
      if (!success) {
        // This can happen if e.g. the isolate that owns the port has died
        // for some reason.
        LOG_INFO("Failed to post event to port %ld\n", port);
      }
    }
  }
  UpdatePort(old_mask, di);
}

int64_t EventHandlerImplementation::GetTimeout() const {
  if (!timeout_queue_.HasTimeout()) {
    return kInfinityTimeout;
  }
  int64_t millis =
      timeout_queue_.CurrentTimeout() - TimerUtils::GetCurrentMonotonicMillis();
  return (millis < 0) ? 0 : millis;
}

void EventHandlerImplementation::HandleTimeout() {
  if (timeout_queue_.HasTimeout()) {
    int64_t millis = timeout_queue_.CurrentTimeout() -
                     TimerUtils::GetCurrentMonotonicMillis();
    if (millis <= 0) {
      DartUtils::PostNull(timeout_queue_.CurrentPort());
      timeout_queue_.RemoveCurrent();
    }
  }
}

void EventHandlerImplementation::Poll(uword args) {
  EventHandler* handler = reinterpret_cast<EventHandler*>(args);
  EventHandlerImplementation* handler_impl = &handler->delegate_;
  ASSERT(handler_impl != NULL);

  zx_port_packet_t pkt;
  while (!handler_impl->shutdown_) {
    int64_t millis = handler_impl->GetTimeout();
    ASSERT((millis == kInfinityTimeout) || (millis >= 0));

    LOG_INFO("zx_port_wait(millis = %ld)\n", millis);
    zx_status_t status = zx_port_wait(handler_impl->port_handle_,
                                      millis == kInfinityTimeout
                                          ? ZX_TIME_INFINITE
                                          : zx_deadline_after(ZX_MSEC(millis)),
                                      &pkt, 0);
    if (status == ZX_ERR_TIMED_OUT) {
      handler_impl->HandleTimeout();
    } else if (status != ZX_OK) {
      FATAL1("zx_port_wait failed: %s\n", zx_status_get_string(status));
    } else {
      handler_impl->HandleTimeout();
      handler_impl->HandlePacket(&pkt);
    }
  }
  DEBUG_ASSERT(ReferenceCounted<Socket>::instances() == 0);
  handler->NotifyShutdownDone();
}

void EventHandlerImplementation::Start(EventHandler* handler) {
  int result = Thread::Start(&EventHandlerImplementation::Poll,
                             reinterpret_cast<uword>(handler));
  if (result != 0) {
    FATAL1("Failed to start event handler thread %d", result);
  }
}

void EventHandlerImplementation::Shutdown() {
  SendData(kShutdownId, 0, 0);
}

void EventHandlerImplementation::SendData(intptr_t id,
                                          Dart_Port dart_port,
                                          int64_t data) {
  WakeupHandler(id, dart_port, data);
}

void* EventHandlerImplementation::GetHashmapKeyFromFd(intptr_t fd) {
  // The hashmap does not support keys with value 0.
  return reinterpret_cast<void*>(fd + 1);
}

uint32_t EventHandlerImplementation::GetHashmapHashFromFd(intptr_t fd) {
  // The hashmap does not support keys with value 0.
  return dart::Utils::WordHash(fd + 1);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
