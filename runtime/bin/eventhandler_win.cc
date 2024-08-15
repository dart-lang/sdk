// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include "bin/eventhandler.h"
#include "bin/eventhandler_win.h"

#include <fcntl.h>     // NOLINT
#include <io.h>        // NOLINT
#include <mswsock.h>   // NOLINT
#include <winsock2.h>  // NOLINT
#include <ws2tcpip.h>  // NOLINT
#include <utility>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/lockers.h"
#include "bin/process.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/syslog.h"

#include "platform/utils.h"

namespace dart {
namespace bin {

// kBufferSize must be >= kMaxUDPPackageLength so that a complete UDP packet
// can fit in the buffer.
static constexpr int kBufferSize = 64 * 1024;
static constexpr int kStdOverlappedBufferSize = 16 * 1024;
static constexpr int kMaxUDPPackageLength = 64 * 1024;
// For AcceptEx there needs to be buffer storage for address
// information for two addresses (local and remote address). The
// AcceptEx documentation says: "This value must be at least 16
// bytes more than the maximum address length for the transport
// protocol in use."
static constexpr int kAcceptExAddressAdditionalBytes = 16;
static constexpr int kAcceptExAddressStorageSize =
    sizeof(SOCKADDR_STORAGE) + kAcceptExAddressAdditionalBytes;

static constexpr intptr_t kOutEventMask = 1 << kOutEvent;
static constexpr intptr_t kInEventMask = 1 << kInEvent;

static bool DispatchEventIfEnabled(Handle* handle, intptr_t event_mask) {
  if ((handle->Mask() & event_mask) != 0) {
    DartUtils::PostInt32(handle->NextNotifyDartPort(event_mask), event_mask);
    return true;
  }
  return false;
}

static bool DispatchOutEventIfEnabled(Handle* handle) {
  return DispatchEventIfEnabled(handle, kOutEventMask);
}

static bool DispatchInEventIfEnabled(Handle* handle) {
  return DispatchEventIfEnabled(handle, kInEventMask);
}

OverlappedBuffer::OverlappedBuffer(Handle* handle,
                                   int buffer_size,
                                   Operation operation)
    : buflen_(buffer_size), operation_(operation), handle_(handle) {
  memset(GetBufferStart(), 0, GetBufferSize());
  if (operation == kRecvFrom) {
    // Reserve part of the buffer for the length of source sockaddr
    // and source sockaddr.
    const int kAdditionalSize =
        sizeof(struct sockaddr_storage) + sizeof(socklen_t);
    ASSERT(buflen_ > kAdditionalSize);
    buflen_ -= kAdditionalSize;
    from_len_addr_ =
        reinterpret_cast<socklen_t*>(GetBufferStart() + GetBufferSize());
    *from_len_addr_ = sizeof(struct sockaddr_storage);
    from_ = reinterpret_cast<struct sockaddr*>(from_len_addr_ + 1);
  } else {
    from_len_addr_ = nullptr;
    from_ = nullptr;
  }
  index_ = 0;
  data_length_ = 0;
  if (operation_ == kAccept) {
    client_ = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  }

  // Retain handle for the duration of the operation.
  handle->Retain();
}

OverlappedBuffer::~OverlappedBuffer() {
  // If handle was not detached from the buffer release the reference
  // we were holding to it.
  if (handle_ != nullptr) {
    handle_->Release();
  }

  if (client_ != INVALID_SOCKET) {
    closesocket(client_);
  }
}

std::unique_ptr<OverlappedBuffer> OverlappedBuffer::AllocateBuffer(
    Handle* handle,
    int buffer_size,
    Operation operation) {
  OverlappedBuffer* buffer =
      new (buffer_size) OverlappedBuffer(handle, buffer_size, operation);
  return std::unique_ptr<OverlappedBuffer>{buffer};
}

std::unique_ptr<OverlappedBuffer> OverlappedBuffer::AllocateAcceptBuffer(
    Handle* handle) {
  return AllocateBuffer(handle, 2 * kAcceptExAddressStorageSize, kAccept);
}

std::unique_ptr<OverlappedBuffer> OverlappedBuffer::AllocateReadBuffer(
    Handle* handle,
    int buffer_size) {
  return AllocateBuffer(handle, buffer_size, kRead);
}

std::unique_ptr<OverlappedBuffer> OverlappedBuffer::AllocateRecvFromBuffer(
    Handle* handle,
    int buffer_size) {
  // For calling recvfrom additional buffer space is needed for the source
  // address information.
  buffer_size += sizeof(socklen_t) + sizeof(struct sockaddr_storage);
  return AllocateBuffer(handle, buffer_size, kRecvFrom);
}

std::unique_ptr<OverlappedBuffer> OverlappedBuffer::AllocateWriteBuffer(
    Handle* handle,
    int buffer_size) {
  return AllocateBuffer(handle, buffer_size, kWrite);
}

std::unique_ptr<OverlappedBuffer> OverlappedBuffer::AllocateSendToBuffer(
    Handle* handle,
    int buffer_size) {
  return AllocateBuffer(handle, buffer_size, kSendTo);
}

std::unique_ptr<OverlappedBuffer> OverlappedBuffer::AllocateDisconnectBuffer(
    Handle* handle) {
  return AllocateBuffer(handle, 0, kDisconnect);
}

std::unique_ptr<OverlappedBuffer> OverlappedBuffer::AllocateConnectBuffer(
    Handle* handle) {
  return AllocateBuffer(handle, 0, kConnect);
}

OverlappedBuffer* OverlappedBuffer::GetFromOverlapped(OVERLAPPED* overlapped) {
  OverlappedBuffer* buffer =
      CONTAINING_RECORD(overlapped, OverlappedBuffer, overlapped_);
  return buffer;
}

int OverlappedBuffer::Read(void* buffer, int num_bytes) {
  if (num_bytes > GetRemainingLength()) {
    num_bytes = GetRemainingLength();
  }
  memmove(buffer, GetBufferStart() + index_, num_bytes);
  index_ += num_bytes;
  return num_bytes;
}

int OverlappedBuffer::Write(const void* buffer, int num_bytes) {
  ASSERT(num_bytes == buflen_);
  memmove(GetBufferStart(), buffer, num_bytes);
  data_length_ = num_bytes;
  return num_bytes;
}

int OverlappedBuffer::GetRemainingLength() {
  ASSERT(operation_ == kRead || operation_ == kRecvFrom);
  return data_length_ - index_;
}

Handle::Handle(intptr_t handle,
               Type type,
               Handle::SupportsOverlappedIO supports_overlapped_io /* = kYes */)
    : ReferenceCounted(),
      DescriptorInfoBase(handle),
      monitor_(),
      type_(type),
      handle_(reinterpret_cast<HANDLE>(handle)),
      data_ready_() {
  if (supports_overlapped_io == SupportsOverlappedIO::kYes) {
    EventHandler::delegate()->AssociateWithCompletionPort(this);
  } else {
    flags_ |= 1 << kDoesNotSupportOverlappedIO;
  }
}

Handle::~Handle() {}

void Handle::Close() {
  MonitorLocker ml(&monitor_);
  CloseLocked(&ml);
}

void Handle::CloseLocked(MonitorLocker* ml) {
  if (!supports_overlapped_io()) {
    // If the handle uses synchronous I/O (e.g. stdin), cancel any pending
    // operation before closing the handle, so the read thread is not blocked.
    BOOL result = CancelIoEx(handle_, nullptr);
    ASSERT(result || (GetLastError() == ERROR_NOT_FOUND));
  }
  if (!IsClosing()) {
    // Close the socket and set the closing state. This close method can be
    // called again if this socket has pending IO operations in flight.
    MarkClosing();
    // Perform handle type specific closing.
    DoCloseLocked(ml);
  }
  ASSERT(IsHandleClosed());
}

void Handle::DoCloseLocked(MonitorLocker* ml) {
  if (!IsHandleClosed()) {
    CloseHandle(handle_);
    handle_ = INVALID_HANDLE_VALUE;
  }
}

bool Handle::HasPendingRead() {
  return pending_read_ != nullptr;
}

bool Handle::HasPendingWrite() {
  return pending_write_ != nullptr;
}

void Handle::WaitForReadThreadStarted() {
  MonitorLocker ml(&monitor_);
  while (read_thread_starting_) {
    ml.Wait();
  }
}

void Handle::WaitForReadThreadFinished() {
  HANDLE to_join = nullptr;
  {
    MonitorLocker ml(&monitor_);
    if (read_thread_ != INVALID_HANDLE_VALUE) {
      while (!read_thread_finished_) {
        ml.Wait();
      }
      read_thread_finished_ = false;
      to_join = read_thread_;
      read_thread_ = INVALID_HANDLE_VALUE;
    }
  }
  if (to_join != nullptr) {
    // Join the read thread.
    DWORD res = WaitForSingleObject(to_join, INFINITE);
    CloseHandle(to_join);
    ASSERT(res == WAIT_OBJECT_0);
  }
}

void Handle::ReadComplete(std::unique_ptr<OverlappedBuffer> buffer) {
  WaitForReadThreadStarted();
  {
    MonitorLocker ml(&monitor_);
    // Currently only one outstanding read at the time.
    ASSERT(pending_read_ == buffer.get());
    ASSERT(data_ready_ == nullptr);
    if (!IsClosing()) {
      data_ready_ = std::move(buffer);
    }
    pending_read_ = nullptr;
  }
  WaitForReadThreadFinished();
}

void Handle::WriteComplete(std::unique_ptr<OverlappedBuffer> buffer) {
  MonitorLocker ml(&monitor_);
  // Currently only one outstanding write at the time.
  ASSERT(pending_write_ == buffer.get());
  pending_write_ = nullptr;
}

// Helper method which returns a real HANDLE for the current thread.
static HANDLE GetCurrentThreadHandle() {
  HANDLE thread_handle = INVALID_HANDLE_VALUE;
  if (!DuplicateHandle(GetCurrentProcess(), GetCurrentThread(),
                       GetCurrentProcess(), &thread_handle,
                       /*dwDesiredAccess=*/0, FALSE, DUPLICATE_SAME_ACCESS)) {
    FATAL("Failed to obtain thread handle");
  }
  return thread_handle;
}

void Handle::NotifyReadThreadStarted() {
  MonitorLocker ml(&monitor_);
  ASSERT(read_thread_starting_);
  ASSERT(read_thread_ == INVALID_HANDLE_VALUE);
  read_thread_ = GetCurrentThreadHandle();
  read_thread_starting_ = false;
  ml.Notify();
}

void Handle::NotifyReadThreadFinished() {
  MonitorLocker ml(&monitor_);
  ASSERT(!read_thread_finished_);
  ASSERT(read_thread_ != INVALID_HANDLE_VALUE);
  read_thread_finished_ = true;
  ml.Notify();
}

void Handle::ReadSyncCompleteAsync() {
  NotifyReadThreadStarted();
  ASSERT(HasPendingRead());
  ASSERT(pending_read_->GetBufferSize() >= kStdOverlappedBufferSize);

  DWORD buffer_size = pending_read_->GetBufferSize();
  if (GetFileType(handle_) == FILE_TYPE_CHAR) {
    buffer_size = kStdOverlappedBufferSize;
  }
  char* buffer_start = pending_read_->GetBufferStart();
  DWORD bytes_read = 0;
  BOOL ok = ReadFile(handle_, buffer_start, buffer_size, &bytes_read, nullptr);
  if (!ok) {
    bytes_read = 0;
  }
  OVERLAPPED* overlapped = pending_read_->GetCleanOverlapped();
  ok = PostQueuedCompletionStatus(EventHandler::delegate()->completion_port(),
                                  bytes_read, reinterpret_cast<ULONG_PTR>(this),
                                  overlapped);
  if (!ok) {
    FATAL("PostQueuedCompletionStatus failed");
  }
  NotifyReadThreadFinished();
}

bool Handle::IssueReadLocked(MonitorLocker* ml) {
  ASSERT(type_ != kListenSocket);
  ASSERT(!HasPendingRead());
  auto buffer = OverlappedBuffer::AllocateReadBuffer(this, kBufferSize);
  // Must initialize pending_read_ before issuing async operation, because
  // completion will race with this code.
  pending_read_ = buffer.get();
  if (supports_overlapped_io()) {
    BOOL ok =
        ReadFile(handle_, buffer->GetBufferStart(), buffer->GetBufferSize(),
                 nullptr, buffer->GetCleanOverlapped());
    if (ok || (GetLastError() == ERROR_IO_PENDING)) {
      // Completing asynchronously.
      buffer.release();  // HandleIOCompletion will take ownership.
      return true;
    }
    pending_read_ = nullptr;
    HandleIssueError();
    return false;
  } else {
    // Completing asynchronously through thread.
    Retain();
    buffer.release();  // HandleIOCompletion will take ownership.
    read_thread_starting_ = true;
    int result = Thread::Start(
        "dart:io ReadFile",
        [](uword args) {
          auto handle = reinterpret_cast<Handle*>(args);
          handle->ReadSyncCompleteAsync();
          handle->Release();
        },
        reinterpret_cast<uword>(this));
    if (result != 0) {
      FATAL("Failed to start read file thread %d", result);
    }
    return true;
  }
}

bool Handle::IssueRecvFromLocked(MonitorLocker* ml) {
  return false;
}

bool Handle::IssueWriteLocked(MonitorLocker* ml,
                              std::unique_ptr<OverlappedBuffer> buffer) {
  ASSERT(type_ != kListenSocket);
  ASSERT(!HasPendingWrite());
  ASSERT(buffer->operation() == OverlappedBuffer::kWrite);

  // Must initialize pending_write_ before issuing asynchronous operation,
  // because completion will race with this code.
  pending_write_ = buffer.get();
  BOOL ok =
      WriteFile(handle_, buffer->GetBufferStart(), buffer->GetBufferSize(),
                nullptr, buffer->GetCleanOverlapped());
  if (ok || (GetLastError() == ERROR_IO_PENDING)) {
    // Completing asynchronously.
    buffer.release();  // HandleIOCompletion will take ownership.
    return true;
  }
  pending_write_ = nullptr;
  HandleIssueError();
  return false;
}

bool Handle::IssueSendToLocked(MonitorLocker* ml,
                               std::unique_ptr<OverlappedBuffer> buffer,
                               struct sockaddr* sa,
                               socklen_t sa_len) {
  return false;
}

static void HandleClosed(Handle* handle) {
  if (!handle->IsClosing()) {
    handle->NotifyAllDartPorts(1 << kCloseEvent);
  }
}

static void HandleError(Handle* handle) {
  handle->set_last_error(WSAGetLastError());
  handle->MarkError();
  if (!handle->IsClosing()) {
    handle->NotifyAllDartPorts(1 << kErrorEvent);
  }
}

void Handle::HandleIssueError() {
  DWORD error = GetLastError();
  if (error == ERROR_BROKEN_PIPE) {
    HandleClosed(this);
  } else {
    HandleError(this);
  }
  SetLastError(error);
}

bool FileHandle::IsClosed() {
  return IsClosing() && !HasPendingRead() && !HasPendingWrite();
}

void DirectoryWatchHandle::Start() {
  MonitorLocker ml(&monitor_);
  IssueReadLocked(&ml);
}

bool DirectoryWatchHandle::IsClosed() {
  return IsClosing() && !HasPendingRead();
}

bool DirectoryWatchHandle::IssueReadLocked(MonitorLocker* ml) {
  // It may have been started before, as we start the directory-handler when
  // we create it.
  if (HasPendingRead() || (data_ready_ != nullptr)) {
    return true;
  }
  auto buffer = OverlappedBuffer::AllocateReadBuffer(this, kBufferSize);
  // Set up pending_read_ before ReadDirectoryChangesW because it might be
  // needed in ReadComplete invoked on event loop thread right away if data is
  // also ready right away.
  pending_read_ = buffer.get();
  BOOL ok = ReadDirectoryChangesW(
      handle_, buffer->GetBufferStart(), buffer->GetBufferSize(), recursive_,
      events_, nullptr, buffer->GetCleanOverlapped(), nullptr);
  if (ok || (GetLastError() == ERROR_IO_PENDING)) {
    // Completing asynchronously.
    buffer.release();  // HandleIOCompletion will take ownership.
    return true;
  }
  pending_read_ = nullptr;
  return false;
}

void DirectoryWatchHandle::Stop() {
  MonitorLocker ml(&monitor_);

  // Stop the outstanding read, so we can close the handle.
  if (HasPendingRead()) {
    CancelIoEx(handle(), pending_read_->GetCleanOverlapped());
    // Don't dispose of the buffer, as it will still complete (with length 0).
  }

  DoCloseLocked(&ml);
}

void SocketHandle::HandleIssueError() {
  int error = WSAGetLastError();
  if (error == WSAECONNRESET) {
    HandleClosed(this);
  } else {
    HandleError(this);
  }
  WSASetLastError(error);
}

bool ListenSocket::IssueAcceptLocked(MonitorLocker* ml) {
  auto buffer = OverlappedBuffer::AllocateAcceptBuffer(this);
  DWORD received;
  BOOL ok;
  ok = EventHandler::delegate()->accept_ex()(
      socket(), buffer->client(), buffer->GetBufferStart(),
      0,  // For now don't receive data with accept.
      kAcceptExAddressStorageSize, kAcceptExAddressStorageSize, &received,
      buffer->GetCleanOverlapped());
  if (ok || WSAGetLastError() == WSA_IO_PENDING) {
    pending_accept_count_++;
    buffer.release();  // HandleIOCompletion will take ownership.
    return true;
  }
  HandleError(this);
  return false;
}

bool ListenSocket::StartAccept() {
  MonitorLocker ml(&monitor_);

  // Always keep 5 outstanding accepts going, to enhance performance.
  for (intptr_t i = 0; i < kMinIssuedAccepts; i++) {
    if (!IssueAcceptLocked(&ml)) {
      return false;
    }
  }

  return true;
}

void ListenSocket::AcceptComplete(std::unique_ptr<OverlappedBuffer> buffer) {
  MonitorLocker ml(&monitor_);
  if (!IsClosing()) {
    // Update the accepted socket to support the full range of API calls.
    SOCKET s = socket();
    int rc = setsockopt(buffer->client(), SOL_SOCKET, SO_UPDATE_ACCEPT_CONTEXT,
                        reinterpret_cast<char*>(&s), sizeof(s));
    if (rc == NO_ERROR) {
      SOCKET client = buffer->client();
      buffer->DetachClient();

      // getpeername() returns incorrect results when used with a socket that
      // was accepted using overlapped I/O. AcceptEx includes the remote
      // address in its result so retrieve it using GetAcceptExSockaddrs and
      // save it.
      LPSOCKADDR local_addr;
      int local_addr_length;
      LPSOCKADDR remote_addr;
      int remote_addr_length;
      EventHandler::delegate()->get_accept_ex_sockaddrs()(
          buffer->GetBufferStart(), 0, kAcceptExAddressStorageSize,
          kAcceptExAddressStorageSize, &local_addr, &local_addr_length,
          &remote_addr, &remote_addr_length);
      RawAddr* raw_remote_addr = new RawAddr;
      memmove(raw_remote_addr, remote_addr, remote_addr_length);

      // Insert the accepted socket into the list.
      ClientSocket* client_socket =
          new ClientSocket(client, std::unique_ptr<RawAddr>(raw_remote_addr));
      client_socket->mark_connected();
      if (accepted_head_ == nullptr) {
        accepted_head_ = client_socket;
        accepted_tail_ = client_socket;
      } else {
        ASSERT(accepted_tail_ != nullptr);
        accepted_tail_->set_next(client_socket);
        accepted_tail_ = client_socket;
      }
      accepted_count_++;
    }
  }

  pending_accept_count_--;
  DispatchCompletedAcceptsLocked(&ml);
}

void ListenSocket::DispatchCompletedAcceptsLocked(MonitorLocker* ml) {
  if (IsClosing()) {
    return;
  }

  for (int i = 0; i < accepted_count(); i++) {
    if (!DispatchInEventIfEnabled(this)) {
      break;
    }
  }
}

static void NotifyDestroyedIfClosed(Handle* handle) {
  if (handle->IsClosed()) {
    handle->NotifyAllDartPorts(1 << kDestroyedEvent);
    handle->RemoveAllPorts();
  }
}

void ListenSocket::DoCloseLocked(MonitorLocker* ml) {
  closesocket(socket());
  handle_ = INVALID_HANDLE_VALUE;

  // Get rid of connections already accepted.
  ClientSocket* next_client = accepted_head_;
  while (next_client != nullptr) {
    ClientSocket* client = next_client;
    next_client = client->next();
    client->set_next(nullptr);

    client->Close();
    NotifyDestroyedIfClosed(client);
    client->Release();
  }
  accepted_head_ = accepted_tail_ = nullptr;
  accepted_count_ = 0;
}

ClientSocket* ListenSocket::Accept() {
  MonitorLocker ml(&monitor_);

  ClientSocket* result = nullptr;
  if (accepted_head_ != nullptr) {
    result = accepted_head_;
    accepted_head_ = accepted_head_->next();
    if (accepted_head_ == nullptr) {
      accepted_tail_ = nullptr;
    }
    result->set_next(nullptr);
    accepted_count_--;
  }

  // We have less than 5 pending accepts and are not closing try to queue
  // another accept.
  if (!IsClosing() && (pending_accept_count_ < kMinIssuedAccepts)) {
    IssueAcceptLocked(&ml);
  }

  return result;
}

bool ListenSocket::IsClosed() {
  return IsClosing() && !HasPendingAccept();
}

intptr_t Handle::Available() {
  MonitorLocker ml(&monitor_);
  if (data_ready_ == nullptr) {
    return 0;
  }
  return data_ready_->GetRemainingLength();
}

bool Handle::DataReady() {
  return data_ready_ != nullptr;
}

intptr_t Handle::Read(void* buffer, intptr_t num_bytes) {
  MonitorLocker ml(&monitor_);
  if (data_ready_ == nullptr) {
    return 0;
  }
  num_bytes =
      data_ready_->Read(buffer, Utils::Minimum<intptr_t>(num_bytes, INT_MAX));
  if (data_ready_->IsEmpty()) {
    data_ready_ = nullptr;
    if (!IsClosing() && !IsClosedRead()) {
      IssueReadLocked(&ml);
    }
  }
  return num_bytes;
}

intptr_t Handle::RecvFrom(void* buffer,
                          intptr_t num_bytes,
                          struct sockaddr* sa,
                          socklen_t sa_len) {
  MonitorLocker ml(&monitor_);
  if (data_ready_ == nullptr) {
    return 0;
  }
  num_bytes =
      data_ready_->Read(buffer, Utils::Minimum<intptr_t>(num_bytes, INT_MAX));
  if (data_ready_->from()->sa_family == AF_INET) {
    ASSERT(sa_len >= sizeof(struct sockaddr_in));
    memmove(sa, data_ready_->from(), sizeof(struct sockaddr_in));
  } else {
    ASSERT(data_ready_->from()->sa_family == AF_INET6);
    ASSERT(sa_len >= sizeof(struct sockaddr_in6));
    memmove(sa, data_ready_->from(), sizeof(struct sockaddr_in6));
  }
  // Always dispose of the buffer, as UDP messages must be read in their
  // entirety to match how recvfrom works in a socket.
  data_ready_ = nullptr;
  if (!IsClosing() && !IsClosedRead()) {
    IssueRecvFromLocked(&ml);
  }
  return num_bytes;
}

intptr_t Handle::Write(const void* data, intptr_t num_bytes) {
  MonitorLocker ml(&monitor_);
  if (HasPendingWrite() || IsClosed()) {
    return 0;
  }
  if (num_bytes > kBufferSize) {
    num_bytes = kBufferSize;
  }
  ASSERT(supports_overlapped_io());
  int truncated_bytes = Utils::Minimum<intptr_t>(num_bytes, INT_MAX);
  auto buffer = OverlappedBuffer::AllocateWriteBuffer(this, truncated_bytes);
  buffer->Write(data, truncated_bytes);
  if (!IssueWriteLocked(&ml, std::move(buffer))) {
    return -1;
  }
  return truncated_bytes;
}

intptr_t Handle::SendTo(const void* data,
                        intptr_t num_bytes,
                        struct sockaddr* sa,
                        socklen_t sa_len) {
  MonitorLocker ml(&monitor_);
  if (HasPendingWrite() || IsClosed()) {
    return 0;
  }
  if (num_bytes > kBufferSize) {
    ASSERT(kBufferSize >= kMaxUDPPackageLength);
    // The provided buffer is larger than the maximum UDP datagram size so
    // return an error immediately. If the buffer were larger and the data were
    // actually passed to `WSASendTo()` then the operation would fail with
    // ERROR_INVALID_USER_BUFFER anyway.
    SetLastError(ERROR_INVALID_USER_BUFFER);
    return -1;
  }
  auto buffer = OverlappedBuffer::AllocateSendToBuffer(this, num_bytes);
  buffer->Write(data, num_bytes);
  if (!IssueSendToLocked(&ml, std::move(buffer), sa, sa_len)) {
    return -1;
  }
  return num_bytes;
}

Mutex* StdHandle::stdin_mutex_ = new Mutex();
StdHandle* StdHandle::stdin_ = nullptr;

StdHandle* StdHandle::Stdin(HANDLE handle) {
  MutexLocker ml(stdin_mutex_);
  if (stdin_ == nullptr) {
    stdin_ = new StdHandle(handle);
  }
  return stdin_;
}

void StdHandle::RunWriteLoop() {
  MonitorLocker ml(&monitor_);
  write_thread_running_ = true;
  thread_handle_ = GetCurrentThreadHandle();
  // Notify we have started.
  ml.Notify();

  while (write_thread_running_) {
    ml.Wait(Monitor::kNoTimeout);
    if (HasPendingWrite()) {
      // We woke up and had a pending write. Execute it.
      WriteSyncCompleteAsync();
    }
  }

  write_thread_exists_ = false;
  ml.Notify();
}

void StdHandle::WriteSyncCompleteAsync() {
  ASSERT(HasPendingWrite());

  DWORD bytes_written = -1;
  BOOL ok = WriteFile(handle_, pending_write_->GetBufferStart(),
                      pending_write_->GetBufferSize(), &bytes_written, nullptr);
  if (!ok) {
    bytes_written = 0;
  }
  thread_wrote_ += bytes_written;
  OVERLAPPED* overlapped = pending_write_->GetCleanOverlapped();
  ok = PostQueuedCompletionStatus(
      EventHandler::delegate()->completion_port(), bytes_written,
      reinterpret_cast<ULONG_PTR>(this), overlapped);
  if (!ok) {
    FATAL("PostQueuedCompletionStatus failed");
  }
}

intptr_t StdHandle::Write(const void* buffer, intptr_t num_bytes) {
  MonitorLocker ml(&monitor_);
  if (HasPendingWrite()) {
    return 0;
  }
  if (num_bytes > kBufferSize) {
    num_bytes = kBufferSize;
  }
  // In the case of stdout and stderr, OverlappedIO is not supported.
  // Here we'll instead use a thread, to make it async.
  // This code is actually never exposed to the user, as stdout and stderr is
  // not available as a RawSocket, but only wrapped in a Socket.
  // Note that we return '0', unless a thread have already completed a write.
  if (thread_wrote_ > 0) {
    if (num_bytes > thread_wrote_) {
      num_bytes = thread_wrote_;
    }
    thread_wrote_ -= num_bytes;
    return num_bytes;
  }
  if (!write_thread_exists_) {
    write_thread_exists_ = true;
    // The write thread gets a reference to the Handle, which it places in
    // the events it puts on the IO completion port.
    Retain();
    int result = Thread::Start(
        "dart:io WriteFile",
        [](uword args) {
          auto handle = reinterpret_cast<StdHandle*>(args);
          handle->RunWriteLoop();
          handle->Release();
        },
        reinterpret_cast<uword>(this));
    if (result != 0) {
      FATAL("Failed to start write file thread %d", result);
    }
    while (!write_thread_running_) {
      // Wait until we the thread is running.
      ml.Wait(Monitor::kNoTimeout);
    }
  }
  // Only queue up to INT_MAX bytes.
  int truncated_bytes = Utils::Minimum<intptr_t>(num_bytes, INT_MAX);
  // Create buffer and notify thread about the new handle.
  pending_write_ =
      OverlappedBuffer::AllocateWriteBuffer(this, truncated_bytes).release();
  pending_write_->Write(buffer, truncated_bytes);
  ml.Notify();
  return 0;
}

void StdHandle::DoCloseLocked(MonitorLocker* ml) {
  if (write_thread_exists_) {
    write_thread_running_ = false;
    ml->Notify();
    while (write_thread_exists_) {
      ml->Wait(Monitor::kNoTimeout);
    }
    // Join the thread.
    DWORD res = WaitForSingleObject(thread_handle_, INFINITE);
    CloseHandle(thread_handle_);
    ASSERT(res == WAIT_OBJECT_0);
  }
  Handle::DoCloseLocked(ml);

  MutexLocker stdin_mutex_locker(stdin_mutex_);
  stdin_->Release();
  StdHandle::stdin_ = nullptr;
}

#if defined(DEBUG)
intptr_t ClientSocket::disconnecting_ = 0;
#endif

void ClientSocket::Shutdown(int how) {
  int rc = shutdown(socket(), how);
  if (how == SD_RECEIVE) {
    MarkClosedRead();
  }
  if (how == SD_SEND) {
    MarkClosedWrite();
  }
  if (how == SD_BOTH) {
    MarkClosedRead();
    MarkClosedWrite();
  }
}

void ClientSocket::DoCloseLocked(MonitorLocker* ml) {
  // Always do a shutdown before initiating a disconnect.
  shutdown(socket(), SD_BOTH);
  IssueDisconnectLocked(ml);
  handle_ = INVALID_HANDLE_VALUE;
}

bool ClientSocket::IssueReadLocked(MonitorLocker* ml) {
  ASSERT(!HasPendingRead());

  // TODO(sgjesse): Use a MTU value here. Only the loopback adapter can
  // handle 64k datagrams.
  auto buffer = OverlappedBuffer::AllocateReadBuffer(this, 65536);

  DWORD flags;
  flags = 0;
  pending_read_ = buffer.get();
  int rc = WSARecv(socket(), buffer->GetWASBUF(), 1, nullptr, &flags,
                   buffer->GetCleanOverlapped(), nullptr);
  if ((rc == NO_ERROR) || (WSAGetLastError() == WSA_IO_PENDING)) {
    buffer.release();  // HandleIOCompletion will take ownership.
    return true;
  }
  pending_read_ = nullptr;
  HandleIssueError();
  return false;
}

bool ClientSocket::IssueWriteLocked(MonitorLocker* ml,
                                    std::unique_ptr<OverlappedBuffer> buffer) {
  ASSERT(!HasPendingWrite());
  ASSERT(buffer->operation() == OverlappedBuffer::kWrite);

  pending_write_ = buffer.get();
  int rc = WSASend(socket(), pending_write_->GetWASBUF(), 1, nullptr, 0,
                   pending_write_->GetCleanOverlapped(), nullptr);
  if ((rc == NO_ERROR) || (WSAGetLastError() == WSA_IO_PENDING)) {
    buffer.release();  // HandleIOCompletion will take ownership.
    return true;
  }
  pending_write_ = nullptr;
  HandleIssueError();
  return false;
}

void ClientSocket::IssueDisconnectLocked(MonitorLocker* ml) {
  auto buffer = OverlappedBuffer::AllocateDisconnectBuffer(this);
  BOOL ok = EventHandler::delegate()->disconnect_ex()(
      socket(), buffer->GetCleanOverlapped(), TF_REUSE_SOCKET, 0);
  // DisconnectEx works like other OverlappedIO APIs, where we can get either an
  // immediate success or delayed operation by WSA_IO_PENDING being set.
  if (ok || (WSAGetLastError() != WSA_IO_PENDING)) {
    DisconnectComplete();
  } else {
    // Completing asynchronously.
    buffer.release();  // HandleIOCompletion will take ownership.
  }
  // When the Dart side receives this event, it may decide to close its Dart
  // ports. When all ports are closed, the VM will shut down. The EventHandler
  // will then shut down. If the EventHandler shuts down before this
  // asynchronous disconnect finishes, this ClientSocket will be leaked.
  // TODO(dart:io): Retain a list of client sockets that are in the process of
  // disconnecting. Disconnect them forcefully, and clean up their resources
  // when the EventHandler shuts down.
  NotifyAllDartPorts(1 << kDestroyedEvent);
  RemoveAllPorts();
#if defined(DEBUG)
  disconnecting_++;
#endif
}

void ClientSocket::DisconnectComplete() {
  closesocket(socket());
  data_ready_ = nullptr;
  mark_closed();
#if defined(DEBUG)
  disconnecting_--;
#endif
}

void ClientSocket::ConnectComplete() {
  // Update socket to support full socket API, after ConnectEx completed.
  setsockopt(socket(), SOL_SOCKET, SO_UPDATE_CONNECT_CONTEXT, nullptr, 0);
  // If the port is set, we already listen for this socket in Dart.
  // Handle the cases here.
  if (!IsClosedRead() && ((Mask() & kInEventMask) != 0)) {
    MonitorLocker ml(&monitor_);
    IssueReadLocked(&ml);
  }
  if (!IsClosedWrite()) {
    DispatchOutEventIfEnabled(this);
  }
}

bool ClientSocket::IsClosed() {
  return connected_ && closed_ && !HasPendingRead() && !HasPendingWrite();
}

bool ClientSocket::PopulateRemoteAddr(RawAddr& addr) {
  if (!remote_addr_) {
    return false;
  }
  addr = *remote_addr_;
  return true;
}

bool DatagramSocket::IssueSendToLocked(MonitorLocker* ml,
                                       std::unique_ptr<OverlappedBuffer> buffer,
                                       struct sockaddr* sa,
                                       socklen_t sa_len) {
  ASSERT(!HasPendingWrite());
  ASSERT(buffer->operation() == OverlappedBuffer::kSendTo);

  pending_write_ = buffer.get();
  int rc = WSASendTo(socket(), pending_write_->GetWASBUF(), 1, nullptr, 0, sa,
                     sa_len, pending_write_->GetCleanOverlapped(), nullptr);
  if ((rc == NO_ERROR) || (WSAGetLastError() == WSA_IO_PENDING)) {
    buffer.release();  // HandleIOCompletion will take ownership.
    return true;
  }
  pending_write_ = nullptr;
  HandleIssueError();
  return false;
}

bool DatagramSocket::IssueRecvFromLocked(MonitorLocker* ml) {
  ASSERT(!HasPendingRead());

  auto buffer =
      OverlappedBuffer::AllocateRecvFromBuffer(this, kMaxUDPPackageLength);

  pending_read_ = buffer.get();
  DWORD flags = 0;
  int rc = WSARecvFrom(socket(), buffer->GetWASBUF(), 1, nullptr, &flags,
                       buffer->from(), buffer->from_len_addr(),
                       buffer->GetCleanOverlapped(), nullptr);
  if ((rc == NO_ERROR) || (WSAGetLastError() == WSA_IO_PENDING)) {
    buffer.release();  // HandleIOCompletion will take ownership.
    return true;
  }
  pending_read_ = nullptr;
  HandleIssueError();
  return false;
}

bool DatagramSocket::IsClosed() {
  return IsClosing() && !HasPendingRead() && !HasPendingWrite();
}

void DatagramSocket::DoCloseLocked(MonitorLocker* ml) {
  // Just close the socket. This will cause any queued requests to be aborted.
  closesocket(socket());
  MarkClosedRead();
  MarkClosedWrite();
  handle_ = INVALID_HANDLE_VALUE;
}

void EventHandlerImplementation::HandleInterrupt(InterruptMessage* msg) {
  if (msg->id == kTimerId) {
    // Change of timeout request. Just set the new timeout and port as the
    // completion thread will use the new timeout value for its next wait.
    timeout_queue_.UpdateTimeout(msg->dart_port, msg->data);
  } else if (msg->id == kShutdownId) {
    shutdown_ = true;
  } else {
    Socket* socket = reinterpret_cast<Socket*>(msg->id);
    RefCntReleaseScope<Socket> rs(socket);
    if (socket->fd() == -1) {
      return;
    }
    Handle* handle = reinterpret_cast<Handle*>(socket->fd());
    ASSERT(handle != nullptr);

    handle->Retain();
    RefCntReleaseScope<Handle> rh(handle);

    MonitorLocker hl(&handle->monitor_);
    switch (msg->data & COMMAND_MASK) {
      case 1 << kReturnTokenCommand:
        handle->ReturnTokens(msg->dart_port, TOKEN_COUNT(msg->data));
        break;

      case 1 << kSetEventMaskCommand: {
        // `events` can only have kInEvent/kOutEvent flags set.
        intptr_t events = msg->data & EVENT_MASK;
        ASSERT(0 == (events & ~(kInEventMask | kOutEventMask)));

        handle->SetPortAndMask(msg->dart_port, events);
        if (handle->is_listen_socket()) {
          static_cast<ListenSocket*>(handle)->DispatchCompletedAcceptsLocked(
              &hl);
        } else {
          // Issue a read.
          if ((handle->Mask() & kInEventMask) != 0) {
            if (handle->is_datagram_socket()) {
              handle->IssueRecvFromLocked(&hl);
            } else if (!handle->is_client_socket() ||
                       reinterpret_cast<ClientSocket*>(handle)
                           ->is_connected()) {
              handle->IssueReadLocked(&hl);
            }
          }

          // If out events (can write events) have been requested, and there
          // are no pending writes, meaning any writes are already complete,
          // post an out event immediately.
          //
          // Client sockets are only notified if they are connected.
          if ((events & kOutEventMask) != 0 && !handle->HasPendingWrite()) {
            if (!handle->is_client_socket() ||
                reinterpret_cast<ClientSocket*>(handle)->is_connected()) {
              DispatchOutEventIfEnabled(handle);
            }
          }

          // Similarly, if in events (can read events) have been requested, and
          // there is pending data available, post an in event immediately.
          if ((events & kInEventMask) != 0) {
            if (handle->data_ready_ != nullptr &&
                !handle->data_ready_->IsEmpty()) {
              DispatchInEventIfEnabled(handle);
            }
          }
        }
        break;
      }

      case 1 << kShutdownReadCommand: {
        ASSERT(handle->is_client_socket());
        ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(handle);
        client_socket->Shutdown(SD_RECEIVE);
        break;
      }

      case 1 << kShutdownWriteCommand: {
        ASSERT(handle->is_client_socket());
        ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(handle);
        client_socket->Shutdown(SD_SEND);
        break;
      }

      case 1 << kCloseCommand: {
        if (IS_SIGNAL_SOCKET(msg->data)) {
          Process::ClearSignalHandlerByFd(socket->fd(), socket->isolate_port());
        }
        bool can_close_handle = true;
        if (handle->is_listen_socket()) {
          // We only close the socket file descriptor if there are no other
          // dart socket objects which are listening on the same
          // (address, port) combination.
          ListeningSocketRegistry* registry =
              ListeningSocketRegistry::Instance();
          MutexLocker locker(registry->mutex());
          if (!registry->CloseSafe(socket)) {
            // Other sockets are listening to the same OS socket. Do not close
            // OS socket, but deassociate it from the message port and tell
            // Dart side that this socket was destroyed.
            can_close_handle = false;
            handle->RemovePort(msg->dart_port);
            DartUtils::PostInt32(msg->dart_port, 1 << kDestroyedEvent);
            socket->SetClosedFd();
          }
        }

        if (can_close_handle) {
          // Set response port so that kDestroyedEvent notification is
          // delivered to the listener.
          handle->SetPortAndMask(msg->dart_port, 0);
          handle->CloseLocked(&hl);
          socket->CloseFd();
        }
        break;
      }

      default:
        UNREACHABLE();
        break;
    }

    NotifyDestroyedIfClosed(handle);
  }
}

void EventHandlerImplementation::HandleAccept(
    ListenSocket* listen_socket,
    std::unique_ptr<OverlappedBuffer> buffer) {
  listen_socket->AcceptComplete(std::move(buffer));
}

void EventHandlerImplementation::HandleRead(
    Handle* handle,
    int bytes,
    std::unique_ptr<OverlappedBuffer> buffer) {
  buffer->set_data_length(bytes);
  handle->ReadComplete(std::move(buffer));
  if (bytes > 0) {
    if (!handle->IsClosing()) {
      DispatchInEventIfEnabled(handle);
    }
  } else {
    handle->MarkClosedRead();
    if (bytes == 0) {
      HandleClosed(handle);
    } else {
      HandleError(handle);
    }
  }
}

void EventHandlerImplementation::HandleRecvFrom(
    Handle* handle,
    int bytes,
    std::unique_ptr<OverlappedBuffer> buffer) {
  ASSERT(handle->is_datagram_socket());
  if (bytes >= 0) {
    buffer->set_data_length(bytes);
    handle->ReadComplete(std::move(buffer));
    if (!handle->IsClosing()) {
      DispatchInEventIfEnabled(handle);
    }
  } else {
    HandleError(handle);
  }
}

void EventHandlerImplementation::HandleWrite(
    Handle* handle,
    int bytes,
    std::unique_ptr<OverlappedBuffer> buffer) {
  handle->WriteComplete(std::move(buffer));

  if (bytes >= 0) {
    if (!handle->IsError() && !handle->IsClosing()) {
      ASSERT(!handle->is_client_socket() ||
             reinterpret_cast<ClientSocket*>(handle)->is_connected());
      DispatchOutEventIfEnabled(handle);
    }
  } else {
    HandleError(handle);
  }
}

void EventHandlerImplementation::HandleDisconnect(
    ClientSocket* client_socket,
    int bytes,
    std::unique_ptr<OverlappedBuffer> buffer) {
  client_socket->DisconnectComplete();
}

void EventHandlerImplementation::HandleConnect(
    ClientSocket* client_socket,
    int bytes,
    std::unique_ptr<OverlappedBuffer> buffer) {
  if (bytes < 0) {
    HandleError(client_socket);
  } else {
    client_socket->ConnectComplete();
  }
  client_socket->mark_connected();
}

void EventHandlerImplementation::HandleTimeout() {
  if (!timeout_queue_.HasTimeout()) {
    return;
  }
  DartUtils::PostNull(timeout_queue_.CurrentPort());
  timeout_queue_.RemoveCurrent();
}

static const char* OperationName(OverlappedBuffer::Operation op) {
  switch (op) {
    case OverlappedBuffer::kAccept:
      return "Accept";
    case OverlappedBuffer::kRead:
      return "Read";
    case OverlappedBuffer::kRecvFrom:
      return "RecvFrom";
    case OverlappedBuffer::kWrite:
      return "Write";
    case OverlappedBuffer::kSendTo:
      return "SendTo";
    case OverlappedBuffer::kDisconnect:
      return "Disconnect";
    case OverlappedBuffer::kConnect:
      return "Connect";
  }
  return "?";
}

void EventHandlerImplementation::HandleIOCompletion(int32_t bytes,
                                                    ULONG_PTR key,
                                                    OVERLAPPED* overlapped) {
  std::unique_ptr<OverlappedBuffer> buffer(
      OverlappedBuffer::GetFromOverlapped(overlapped));
  Handle* handle = reinterpret_cast<Handle*>(key);
  RefCntReleaseScope<Handle> release(buffer->StealHandle());
  switch (buffer->operation()) {
    case OverlappedBuffer::kAccept: {
      HandleAccept(static_cast<ListenSocket*>(handle), std::move(buffer));
      break;
    }
    case OverlappedBuffer::kRead: {
      HandleRead(handle, bytes, std::move(buffer));
      break;
    }
    case OverlappedBuffer::kRecvFrom: {
      HandleRecvFrom(handle, bytes, std::move(buffer));
      break;
    }
    case OverlappedBuffer::kWrite:
    case OverlappedBuffer::kSendTo: {
      HandleWrite(handle, bytes, std::move(buffer));
      break;
    }
    case OverlappedBuffer::kDisconnect: {
      HandleDisconnect(static_cast<ClientSocket*>(handle), bytes,
                       std::move(buffer));
      break;
    }
    case OverlappedBuffer::kConnect: {
      HandleConnect(static_cast<ClientSocket*>(handle), bytes,
                    std::move(buffer));
      break;
    }
    default:
      UNREACHABLE();
  }
  NotifyDestroyedIfClosed(handle);
}

void EventHandlerImplementation::HandleCompletionOrInterrupt(
    BOOL ok,
    DWORD bytes,
    ULONG_PTR key,
    OVERLAPPED* overlapped) {
  if (!ok) {
    // Treat ERROR_CONNECTION_ABORTED as connection closed.
    // The error ERROR_OPERATION_ABORTED is set for pending
    // accept requests for a listen socket which is closed.
    // ERROR_NETNAME_DELETED occurs when the client closes
    // the socket it is reading from.
    DWORD last_error = GetLastError();
    if ((last_error == ERROR_CONNECTION_ABORTED) ||
        (last_error == ERROR_OPERATION_ABORTED) ||
        (last_error == ERROR_NETNAME_DELETED) ||
        (last_error == ERROR_BROKEN_PIPE)) {
      ASSERT(bytes == 0);
      HandleIOCompletion(bytes, key, overlapped);
    } else if (last_error == ERROR_MORE_DATA) {
      // Don't ASSERT no bytes in this case. This can happen if the receive
      // buffer for datagram sockets is too small to contain a full datagram,
      // and in this case bytes hold the bytes that was read.
      HandleIOCompletion(-1, key, overlapped);
    } else {
      ASSERT(bytes == 0);
      HandleIOCompletion(-1, key, overlapped);
    }
  } else if (key == NULL) {
    // A key of nullptr signals an interrupt message.
    InterruptMessage* msg = reinterpret_cast<InterruptMessage*>(overlapped);
    HandleInterrupt(msg);
    delete msg;
  } else {
    HandleIOCompletion(bytes, key, overlapped);
  }
}

EventHandlerImplementation::EventHandlerImplementation() {
  completion_port_ =
      CreateIoCompletionPort(INVALID_HANDLE_VALUE, nullptr, NULL, 1);
  if (completion_port_ == nullptr) {
    FATAL("Completion port creation failed");
  }
}

namespace {
template <typename F>
void GetSocketExtensionFunction(SOCKET socket, GUID guid, F* result) {
  DWORD bytes;
  int status =
      WSAIoctl(socket, SIO_GET_EXTENSION_FUNCTION_POINTER, &guid, sizeof(guid),
               result, sizeof(F), &bytes, nullptr, nullptr);
  if (status == SOCKET_ERROR) {
    FATAL("Failed to get a pointer to the extension function.");
  }
}
}  // namespace

void EventHandlerImplementation::InitializeSocketExtensions() {
  if (socket_extensions_initialized_.load()) {
    return;
  }

  MonitorLocker ml(&monitor_);
  SOCKET dummy = socket(AF_INET, SOCK_STREAM, 0);
  GetSocketExtensionFunction(dummy, WSAID_ACCEPTEX, &accept_ex_);
  GetSocketExtensionFunction(dummy, WSAID_CONNECTEX, &connect_ex_);
  GetSocketExtensionFunction(dummy, WSAID_DISCONNECTEX, &disconnect_ex_);
  GetSocketExtensionFunction(dummy, WSAID_GETACCEPTEXSOCKADDRS,
                             &get_accept_ex_sockaddrs_);
  socket_extensions_initialized_.store(true);
  closesocket(dummy);
}

EventHandlerImplementation::~EventHandlerImplementation() {
  // Join the handler thread.
  DWORD res = WaitForSingleObject(handler_thread_, INFINITE);
  CloseHandle(handler_thread_);
  ASSERT(res == WAIT_OBJECT_0);
  CloseHandle(completion_port_);
}

void EventHandlerImplementation::AssociateWithCompletionPort(Handle* handle) {
  HANDLE result =
      CreateIoCompletionPort(handle->handle(), completion_port_,
                             reinterpret_cast<ULONG_PTR>(handle), 0);
  if (result == nullptr) {
    FATAL("Failed to associate handle with completion port");
  }
}

int64_t EventHandlerImplementation::GetTimeout() {
  if (!timeout_queue_.HasTimeout()) {
    return kInfinityTimeout;
  }
  int64_t millis =
      timeout_queue_.CurrentTimeout() - TimerUtils::GetCurrentMonotonicMillis();
  return (millis < 0) ? 0 : millis;
}

void EventHandlerImplementation::SendData(intptr_t id,
                                          Dart_Port dart_port,
                                          int64_t data) {
  InterruptMessage* msg = new InterruptMessage;
  msg->id = id;
  msg->dart_port = dart_port;
  msg->data = data;
  BOOL ok = PostQueuedCompletionStatus(completion_port_, 0, NULL,
                                       reinterpret_cast<OVERLAPPED*>(msg));
  if (!ok) {
    FATAL("PostQueuedCompletionStatus failed");
  }
}

void EventHandlerImplementation::EventHandlerEntry(uword args) {
  EventHandler* handler = reinterpret_cast<EventHandler*>(args);
  EventHandlerImplementation* handler_impl = &handler->delegate_;
  ASSERT(handler_impl != nullptr);

  {
    MonitorLocker ml(&handler_impl->monitor_);
    handler_impl->handler_thread_ = GetCurrentThreadHandle();
    ml.Notify();
  }

  DWORD bytes;
  ULONG_PTR key;
  OVERLAPPED* overlapped;
  BOOL ok;
  while (!handler_impl->shutdown_) {
    int64_t millis = handler_impl->GetTimeout();
    ASSERT(millis == kInfinityTimeout || millis >= 0);
    if (millis > kMaxInt32) {
      millis = kMaxInt32;
    }
    ASSERT(sizeof(int32_t) == sizeof(DWORD));
    DWORD timeout = static_cast<DWORD>(millis);
    ok = GetQueuedCompletionStatus(handler_impl->completion_port(), &bytes,
                                   &key, &overlapped, timeout);

    if (!ok && (overlapped == nullptr)) {
      if (GetLastError() == ERROR_ABANDONED_WAIT_0) {
        // The completion port should never be closed.
        Syslog::Print("Completion port closed\n");
        UNREACHABLE();
      } else {
        // Timeout is signalled by false result and nullptr in overlapped.
        handler_impl->HandleTimeout();
      }
    } else {
      handler_impl->HandleCompletionOrInterrupt(ok, bytes, key, overlapped);
    }
  }

// In a Debug build, drain the IO completion port to make sure we aren't
// leaking any (non-disconnecting) Handles. In a Release build, we don't care
// because the VM is going down, and the asserts below are Debug-only.
#if defined(DEBUG)
  while (true) {
    ok = GetQueuedCompletionStatus(handler_impl->completion_port(), &bytes,
                                   &key, &overlapped, 0);
    if (!ok && (overlapped == nullptr)) {
      // There was an error or nothing is ready. Assume the port is drained.
      break;
    }
    handler_impl->HandleCompletionOrInterrupt(ok, bytes, key, overlapped);
  }

  // The eventhandler thread is going down so there should be no more live
  // Handles or Sockets.
  // TODO(dart:io): It would be nice to be able to assert here that:
  //     ReferenceCounted<Handle>::instances() == 0;
  // However, we cannot at the moment. See the TODO on:
  //     ClientSocket::IssueDisconnect()
  // Furthermore, if the Dart program references stdin, but does not
  // explicitly close it, then the StdHandle for it will be leaked to here.
  const intptr_t stdin_leaked = (StdHandle::StdinPtr() == nullptr) ? 0 : 1;
  DEBUG_ASSERT(ReferenceCounted<Handle>::instances() ==
               ClientSocket::disconnecting() + stdin_leaked);
  DEBUG_ASSERT(ReferenceCounted<Socket>::instances() == 0);
#endif  // defined(DEBUG)
  handler->NotifyShutdownDone();
}

void EventHandlerImplementation::Start(EventHandler* handler) {
  int result = Thread::Start("dart:io EventHandler", EventHandlerEntry,
                             reinterpret_cast<uword>(handler));
  if (result != 0) {
    FATAL("Failed to start event handler thread %d", result);
  }

  {
    MonitorLocker ml(&monitor_);
    while (handler_thread_ == INVALID_HANDLE_VALUE) {
      ml.Wait();
    }
  }
}

void EventHandlerImplementation::Shutdown() {
  SendData(kShutdownId, 0, 0);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
