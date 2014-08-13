// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/eventhandler.h"

#include <winsock2.h>  // NOLINT
#include <ws2tcpip.h>  // NOLINT
#include <mswsock.h>  // NOLINT
#include <io.h>  // NOLINT
#include <fcntl.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "platform/utils.h"

namespace dart {
namespace bin {

static const int kBufferSize = 64 * 1024;
static const int kStdOverlappedBufferSize = 16 * 1024;

static const int kInfinityTimeout = -1;
static const int kTimeoutId = -1;
static const int kShutdownId = -2;

OverlappedBuffer* OverlappedBuffer::AllocateBuffer(int buffer_size,
                                                   Operation operation) {
  OverlappedBuffer* buffer =
      new(buffer_size) OverlappedBuffer(buffer_size, operation);
  return buffer;
}


OverlappedBuffer* OverlappedBuffer::AllocateAcceptBuffer(int buffer_size) {
  OverlappedBuffer* buffer = AllocateBuffer(buffer_size, kAccept);
  return buffer;
}


OverlappedBuffer* OverlappedBuffer::AllocateReadBuffer(int buffer_size) {
  return AllocateBuffer(buffer_size, kRead);
}


OverlappedBuffer* OverlappedBuffer::AllocateRecvFromBuffer(int buffer_size) {
  // For calling recvfrom additional buffer space is needed for the source
  // address information.
  buffer_size += sizeof(socklen_t) + sizeof(struct sockaddr_storage);
  return AllocateBuffer(buffer_size, kRecvFrom);
}


OverlappedBuffer* OverlappedBuffer::AllocateWriteBuffer(int buffer_size) {
  return AllocateBuffer(buffer_size, kWrite);
}


OverlappedBuffer* OverlappedBuffer::AllocateSendToBuffer(int buffer_size) {
  return AllocateBuffer(buffer_size, kSendTo);
}


OverlappedBuffer* OverlappedBuffer::AllocateDisconnectBuffer() {
  return AllocateBuffer(0, kDisconnect);
}


OverlappedBuffer* OverlappedBuffer::AllocateConnectBuffer() {
  return AllocateBuffer(0, kConnect);
}


void OverlappedBuffer::DisposeBuffer(OverlappedBuffer* buffer) {
  delete buffer;
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


Handle::Handle(HANDLE handle)
    : handle_(reinterpret_cast<HANDLE>(handle)),
      port_(0),
      mask_(0),
      completion_port_(INVALID_HANDLE_VALUE),
      event_handler_(NULL),
      data_ready_(NULL),
      pending_read_(NULL),
      pending_write_(NULL),
      last_error_(NOERROR),
      flags_(0) {
  InitializeCriticalSection(&cs_);
}


Handle::Handle(HANDLE handle, Dart_Port port)
    : handle_(reinterpret_cast<HANDLE>(handle)),
      port_(port),
      mask_(0),
      completion_port_(INVALID_HANDLE_VALUE),
      event_handler_(NULL),
      data_ready_(NULL),
      pending_read_(NULL),
      pending_write_(NULL),
      last_error_(NOERROR),
      flags_(0) {
  InitializeCriticalSection(&cs_);
}


Handle::~Handle() {
  DeleteCriticalSection(&cs_);
}


void Handle::Lock() {
  EnterCriticalSection(&cs_);
}


void Handle::Unlock() {
  LeaveCriticalSection(&cs_);
}


bool Handle::CreateCompletionPort(HANDLE completion_port) {
  completion_port_ = CreateIoCompletionPort(handle(),
                                            completion_port,
                                            reinterpret_cast<ULONG_PTR>(this),
                                            0);
  if (completion_port_ == NULL) {
    return false;
  }
  return true;
}


void Handle::Close() {
  ScopedLock lock(this);
  if (!IsClosing()) {
    // Close the socket and set the closing state. This close method can be
    // called again if this socket has pending IO operations in flight.
    MarkClosing();
    // Perform handle type specific closing.
    DoClose();
  }
  ASSERT(IsHandleClosed());
}


void Handle::DoClose() {
  if (!IsHandleClosed()) {
    CloseHandle(handle_);
    handle_ = INVALID_HANDLE_VALUE;
  }
}


bool Handle::HasPendingRead() {
  ScopedLock lock(this);
  return pending_read_ != NULL;
}


bool Handle::HasPendingWrite() {
  ScopedLock lock(this);
  return pending_write_ != NULL;
}


void Handle::ReadComplete(OverlappedBuffer* buffer) {
  ScopedLock lock(this);
  // Currently only one outstanding read at the time.
  ASSERT(pending_read_ == buffer);
  ASSERT(data_ready_ == NULL);
  if (!IsClosing() && !buffer->IsEmpty()) {
    data_ready_ = pending_read_;
  } else {
    OverlappedBuffer::DisposeBuffer(buffer);
  }
  pending_read_ = NULL;
}


void Handle::RecvFromComplete(OverlappedBuffer* buffer) {
  ReadComplete(buffer);
}


void Handle::WriteComplete(OverlappedBuffer* buffer) {
  ScopedLock lock(this);
  // Currently only one outstanding write at the time.
  ASSERT(pending_write_ == buffer);
  OverlappedBuffer::DisposeBuffer(buffer);
  pending_write_ = NULL;
}


static void ReadFileThread(uword args) {
  Handle* handle = reinterpret_cast<Handle*>(args);
  handle->ReadSyncCompleteAsync();
}


void Handle::ReadSyncCompleteAsync() {
  ASSERT(pending_read_ != NULL);
  ASSERT(pending_read_->GetBufferSize() >= kStdOverlappedBufferSize);

  DWORD buffer_size = pending_read_->GetBufferSize();
  if (GetFileType(handle_) == FILE_TYPE_CHAR) {
    buffer_size = kStdOverlappedBufferSize;
  }
  DWORD bytes_read = 0;
  BOOL ok = ReadFile(handle_,
                     pending_read_->GetBufferStart(),
                     buffer_size,
                     &bytes_read,
                     NULL);
  if (!ok) {
    bytes_read = 0;
  }
  OVERLAPPED* overlapped = pending_read_->GetCleanOverlapped();
  ok = PostQueuedCompletionStatus(event_handler_->completion_port(),
                                  bytes_read,
                                  reinterpret_cast<ULONG_PTR>(this),
                                  overlapped);
  if (!ok) {
    FATAL("PostQueuedCompletionStatus failed");
  }
}


bool Handle::IssueRead() {
  ScopedLock lock(this);
  ASSERT(type_ != kListenSocket);
  ASSERT(pending_read_ == NULL);
  OverlappedBuffer* buffer = OverlappedBuffer::AllocateReadBuffer(kBufferSize);
  if (SupportsOverlappedIO()) {
    ASSERT(completion_port_ != INVALID_HANDLE_VALUE);

    BOOL ok = ReadFile(handle_,
                       buffer->GetBufferStart(),
                       buffer->GetBufferSize(),
                       NULL,
                       buffer->GetCleanOverlapped());
    if (ok || GetLastError() == ERROR_IO_PENDING) {
      // Completing asynchronously.
      pending_read_ = buffer;
      return true;
    }
    OverlappedBuffer::DisposeBuffer(buffer);
    HandleIssueError();
    return false;
  } else {
    // Completing asynchronously through thread.
    pending_read_ = buffer;
    int result = dart::Thread::Start(ReadFileThread,
                                     reinterpret_cast<uword>(this));
    if (result != 0) {
      FATAL1("Failed to start read file thread %d", result);
    }
    return true;
  }
}


bool Handle::IssueRecvFrom() {
  return false;
}


bool Handle::IssueWrite() {
  ScopedLock lock(this);
  ASSERT(type_ != kListenSocket);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_write_ != NULL);
  ASSERT(pending_write_->operation() == OverlappedBuffer::kWrite);

  OverlappedBuffer* buffer = pending_write_;
  BOOL ok = WriteFile(handle_,
                      buffer->GetBufferStart(),
                      buffer->GetBufferSize(),
                      NULL,
                      buffer->GetCleanOverlapped());
  if (ok || GetLastError() == ERROR_IO_PENDING) {
    // Completing asynchronously.
    pending_write_ = buffer;
    return true;
  }
  OverlappedBuffer::DisposeBuffer(buffer);
  HandleIssueError();
  return false;
}


bool Handle::IssueSendTo(struct sockaddr* sa, socklen_t sa_len) {
  return false;
}


static void HandleClosed(Handle* handle) {
  if (!handle->IsClosing()) {
    int event_mask = 1 << kCloseEvent;
    DartUtils::PostInt32(handle->port(), event_mask);
  }
}


static void HandleError(Handle* handle) {
  handle->set_last_error(WSAGetLastError());
  handle->MarkError();
  if (!handle->IsClosing()) {
    Dart_Port port = handle->port();
    if (port != ILLEGAL_PORT) {
      DartUtils::PostInt32(port, 1 << kErrorEvent);
    }
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


void FileHandle::EnsureInitialized(EventHandlerImplementation* event_handler) {
  ScopedLock lock(this);
  event_handler_ = event_handler;
  if (SupportsOverlappedIO() && completion_port_ == INVALID_HANDLE_VALUE) {
    CreateCompletionPort(event_handler_->completion_port());
  }
}


bool FileHandle::IsClosed() {
  return IsClosing() && !HasPendingRead() && !HasPendingWrite();
}


void DirectoryWatchHandle::EnsureInitialized(
    EventHandlerImplementation* event_handler) {
  ScopedLock lock(this);
  event_handler_ = event_handler;
  if (completion_port_ == INVALID_HANDLE_VALUE) {
    CreateCompletionPort(event_handler_->completion_port());
  }
}


bool DirectoryWatchHandle::IsClosed() {
  return IsClosing() && pending_read_ == NULL;
}


bool DirectoryWatchHandle::IssueRead() {
  ScopedLock lock(this);
  // It may have been started before, as we start the directory-handler when
  // we create it.
  if (pending_read_ != NULL || data_ready_ != NULL) return true;
  OverlappedBuffer* buffer = OverlappedBuffer::AllocateReadBuffer(kBufferSize);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  BOOL ok = ReadDirectoryChangesW(handle_,
                                  buffer->GetBufferStart(),
                                  buffer->GetBufferSize(),
                                  recursive_,
                                  events_,
                                  NULL,
                                  buffer->GetCleanOverlapped(),
                                  NULL);
  if (ok || GetLastError() == ERROR_IO_PENDING) {
    // Completing asynchronously.
    pending_read_ = buffer;
    return true;
  }
  OverlappedBuffer::DisposeBuffer(buffer);
  return false;
}


void DirectoryWatchHandle::Stop() {
  ScopedLock lock(this);
  // Stop the outstanding read, so we can close the handle.

  if (pending_read_ != NULL) {
    CancelIoEx(handle(), pending_read_->GetCleanOverlapped());
    // Don't dispose of the buffer, as it will still complete (with length 0).
  }

  DoClose();
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


bool ListenSocket::LoadAcceptEx() {
  // Load the AcceptEx function into memory using WSAIoctl.
  GUID guid_accept_ex = WSAID_ACCEPTEX;
  DWORD bytes;
  int status = WSAIoctl(socket(),
                        SIO_GET_EXTENSION_FUNCTION_POINTER,
                        &guid_accept_ex,
                        sizeof(guid_accept_ex),
                        &AcceptEx_,
                        sizeof(AcceptEx_),
                        &bytes,
                        NULL,
                        NULL);
  if (status == SOCKET_ERROR) {
    return false;
  }
  return true;
}


bool ListenSocket::IssueAccept() {
  ScopedLock lock(this);
  // For AcceptEx there needs to be buffer storage for address
  // information for two addresses (local and remote address). The
  // AcceptEx documentation says: "This value must be at least 16
  // bytes more than the maximum address length for the transport
  // protocol in use."
  static const int kAcceptExAddressAdditionalBytes = 16;
  static const int kAcceptExAddressStorageSize =
      sizeof(SOCKADDR_STORAGE) + kAcceptExAddressAdditionalBytes;
  OverlappedBuffer* buffer =
      OverlappedBuffer::AllocateAcceptBuffer(2 * kAcceptExAddressStorageSize);
  DWORD received;
  BOOL ok;
  ok = AcceptEx_(socket(),
                 buffer->client(),
                 buffer->GetBufferStart(),
                 0,  // For now don't receive data with accept.
                 kAcceptExAddressStorageSize,
                 kAcceptExAddressStorageSize,
                 &received,
                 buffer->GetCleanOverlapped());
  if (!ok) {
    if (WSAGetLastError() != WSA_IO_PENDING) {
      int error = WSAGetLastError();
      closesocket(buffer->client());
      OverlappedBuffer::DisposeBuffer(buffer);
      WSASetLastError(error);
      return false;
    }
  }

  pending_accept_count_++;

  return true;
}


void ListenSocket::AcceptComplete(OverlappedBuffer* buffer,
                                  HANDLE completion_port) {
  ScopedLock lock(this);
  if (!IsClosing()) {
    // Update the accepted socket to support the full range of API calls.
    SOCKET s = socket();
    int rc = setsockopt(buffer->client(),
                        SOL_SOCKET,
                        SO_UPDATE_ACCEPT_CONTEXT,
                        reinterpret_cast<char*>(&s), sizeof(s));
    if (rc == NO_ERROR) {
      // Insert the accepted socket into the list.
      ClientSocket* client_socket = new ClientSocket(buffer->client(), 0);
      client_socket->mark_connected();
      client_socket->CreateCompletionPort(completion_port);
      if (accepted_head_ == NULL) {
        accepted_head_ = client_socket;
        accepted_tail_ = client_socket;
      } else {
        ASSERT(accepted_tail_ != NULL);
        accepted_tail_->set_next(client_socket);
        accepted_tail_ = client_socket;
      }
    } else {
      closesocket(buffer->client());
    }
  } else {
    // Close the socket, as it's already accepted.
    closesocket(buffer->client());
  }

  pending_accept_count_--;
  OverlappedBuffer::DisposeBuffer(buffer);
}


static void DeleteIfClosed(Handle* handle) {
  if (handle->IsClosed()) {
    Dart_Port port = handle->port();
    delete handle;
    if (port != ILLEGAL_PORT) {
      DartUtils::PostInt32(port, 1 << kDestroyedEvent);
    }
  }
}


void ListenSocket::DoClose() {
  closesocket(socket());
  handle_ = INVALID_HANDLE_VALUE;
  while (CanAccept()) {
    // Get rid of connections already accepted.
    ClientSocket *client = Accept();
    if (client != NULL) {
      client->Close();
      DeleteIfClosed(client);
    } else {
      break;
    }
  }
}


bool ListenSocket::CanAccept() {
  ScopedLock lock(this);
  return accepted_head_ != NULL;
}


ClientSocket* ListenSocket::Accept() {
  ScopedLock lock(this);
  if (accepted_head_ == NULL) return NULL;
  ClientSocket* result = accepted_head_;
  accepted_head_ = accepted_head_->next();
  if (accepted_head_ == NULL) accepted_tail_ = NULL;
  result->set_next(NULL);
  if (!IsClosing()) {
    if (!IssueAccept()) {
      HandleError(this);
    }
  }
  return result;
}


void ListenSocket::EnsureInitialized(
    EventHandlerImplementation* event_handler) {
  ScopedLock lock(this);
  if (AcceptEx_ == NULL) {
    ASSERT(completion_port_ == INVALID_HANDLE_VALUE);
    ASSERT(event_handler_ == NULL);
    event_handler_ = event_handler;
    CreateCompletionPort(event_handler_->completion_port());
    LoadAcceptEx();
  }
}


bool ListenSocket::IsClosed() {
  return IsClosing() && !HasPendingAccept();
}


intptr_t Handle::Available() {
  ScopedLock lock(this);
  if (data_ready_ == NULL) return 0;
  ASSERT(!data_ready_->IsEmpty());
  return data_ready_->GetRemainingLength();
}


intptr_t Handle::Read(void* buffer, intptr_t num_bytes) {
  ScopedLock lock(this);
  if (data_ready_ == NULL) return 0;
  num_bytes = data_ready_->Read(
      buffer, Utils::Minimum<intptr_t>(num_bytes, INT_MAX));
  if (data_ready_->IsEmpty()) {
    OverlappedBuffer::DisposeBuffer(data_ready_);
    data_ready_ = NULL;
    if (!IsClosing() && !IsClosedRead()) IssueRead();
  }
  return num_bytes;
}


intptr_t Handle::RecvFrom(
    void* buffer, intptr_t num_bytes, struct sockaddr* sa, socklen_t sa_len) {
  ScopedLock lock(this);
  if (data_ready_ == NULL) return 0;
  num_bytes = data_ready_->Read(
      buffer, Utils::Minimum<intptr_t>(num_bytes, INT_MAX));
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
  OverlappedBuffer::DisposeBuffer(data_ready_);
  data_ready_ = NULL;
  if (!IsClosing() && !IsClosedRead()) IssueRecvFrom();
  return num_bytes;
}


intptr_t Handle::Write(const void* buffer, intptr_t num_bytes) {
  ScopedLock lock(this);
  if (pending_write_ != NULL) return 0;
  if (num_bytes > kBufferSize) num_bytes = kBufferSize;
  ASSERT(SupportsOverlappedIO());
  if (completion_port_ == INVALID_HANDLE_VALUE) return 0;
  int truncated_bytes = Utils::Minimum<intptr_t>(num_bytes, INT_MAX);
  pending_write_ = OverlappedBuffer::AllocateWriteBuffer(truncated_bytes);
  pending_write_->Write(buffer, truncated_bytes);
  if (!IssueWrite()) return -1;
  return truncated_bytes;
}


intptr_t Handle::SendTo(const void* buffer,
                        intptr_t num_bytes,
                        struct sockaddr* sa,
                        socklen_t sa_len) {
  ScopedLock lock(this);
  if (pending_write_ != NULL) return 0;
  if (num_bytes > kBufferSize) num_bytes = kBufferSize;
  ASSERT(SupportsOverlappedIO());
  if (completion_port_ == INVALID_HANDLE_VALUE) return 0;
  pending_write_ = OverlappedBuffer::AllocateSendToBuffer(num_bytes);
  pending_write_->Write(buffer, num_bytes);
  if (!IssueSendTo(sa, sa_len)) return -1;
  return num_bytes;
}


static void WriteFileThread(uword args) {
  StdHandle* handle = reinterpret_cast<StdHandle*>(args);
  handle->RunWriteLoop();
}


void StdHandle::RunWriteLoop() {
  write_monitor_->Enter();
  write_thread_running_ = true;
  // Notify we have started.
  write_monitor_->Notify();

  while (write_thread_running_) {
    write_monitor_->Wait(Monitor::kNoTimeout);
    if (pending_write_ != NULL) {
      // We woke up and had a pending write. Execute it.
      WriteSyncCompleteAsync();
    }
  }

  write_thread_exists_ = false;
  write_monitor_->Notify();
  write_monitor_->Exit();
}


void StdHandle::WriteSyncCompleteAsync() {
  ASSERT(pending_write_ != NULL);

  DWORD bytes_written = -1;
  BOOL ok = WriteFile(handle_,
                      pending_write_->GetBufferStart(),
                      pending_write_->GetBufferSize(),
                      &bytes_written,
                      NULL);
  if (!ok) {
    bytes_written = 0;
  }
  thread_wrote_ += bytes_written;
  OVERLAPPED* overlapped = pending_write_->GetCleanOverlapped();
  ok = PostQueuedCompletionStatus(event_handler_->completion_port(),
                                  bytes_written,
                                  reinterpret_cast<ULONG_PTR>(this),
                                  overlapped);
  if (!ok) {
    FATAL("PostQueuedCompletionStatus failed");
  }
}

intptr_t StdHandle::Write(const void* buffer, intptr_t num_bytes) {
  ScopedLock lock(this);
  if (pending_write_ != NULL) return 0;
  if (num_bytes > kBufferSize) num_bytes = kBufferSize;
  // In the case of stdout and stderr, OverlappedIO is not supported.
  // Here we'll instead use a thread, to make it async.
  // This code is actually never exposed to the user, as stdout and stderr is
  // not available as a RawSocket, but only wrapped in a Socket.
  // Note that we return '0', unless a thread have already completed a write.
  MonitorLocker locker(write_monitor_);
  if (thread_wrote_ > 0) {
    if (num_bytes > thread_wrote_) num_bytes = thread_wrote_;
    thread_wrote_ -= num_bytes;
    return num_bytes;
  }
  if (!write_thread_exists_) {
    write_thread_exists_ = true;
    int result = dart::Thread::Start(WriteFileThread,
                                     reinterpret_cast<uword>(this));
    if (result != 0) {
      FATAL1("Failed to start write file thread %d", result);
    }
    while (!write_thread_running_) {
      // Wait until we the thread is running.
      locker.Wait(Monitor::kNoTimeout);
    }
  }
  // Only queue up to INT_MAX bytes.
  int truncated_bytes = Utils::Minimum<intptr_t>(num_bytes, INT_MAX);
  // Create buffer and notify thread about the new handle.
  pending_write_ = OverlappedBuffer::AllocateWriteBuffer(truncated_bytes);
  pending_write_->Write(buffer, truncated_bytes);
  locker.Notify();
  return 0;
}


void StdHandle::DoClose() {
  MonitorLocker locker(write_monitor_);
  if (write_thread_exists_) {
    write_thread_running_ = false;
    locker.Notify();
    while (write_thread_exists_) {
      locker.Wait(Monitor::kNoTimeout);
    }
  }
  Handle::DoClose();
}


bool ClientSocket::LoadDisconnectEx() {
  // Load the DisconnectEx function into memory using WSAIoctl.
  GUID guid_disconnect_ex = WSAID_DISCONNECTEX;
  DWORD bytes;
  int status = WSAIoctl(socket(),
                        SIO_GET_EXTENSION_FUNCTION_POINTER,
                        &guid_disconnect_ex,
                        sizeof(guid_disconnect_ex),
                        &DisconnectEx_,
                        sizeof(DisconnectEx_),
                        &bytes,
                        NULL,
                        NULL);
  if (status == SOCKET_ERROR) {
    return false;
  }
  return true;
}


void ClientSocket::Shutdown(int how) {
  int rc = shutdown(socket(), how);
  if (how == SD_RECEIVE) MarkClosedRead();
  if (how == SD_SEND) MarkClosedWrite();
  if (how == SD_BOTH) {
    MarkClosedRead();
    MarkClosedWrite();
  }
}


void ClientSocket::DoClose() {
  // Always do a shutdown before initiating a disconnect.
  shutdown(socket(), SD_BOTH);
  IssueDisconnect();
  handle_ = INVALID_HANDLE_VALUE;
}


bool ClientSocket::IssueRead() {
  ScopedLock lock(this);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_read_ == NULL);

  // TODO(sgjesse): Use a MTU value here. Only the loopback adapter can
  // handle 64k datagrams.
  OverlappedBuffer* buffer = OverlappedBuffer::AllocateReadBuffer(65536);

  DWORD flags;
  flags = 0;
  int rc = WSARecv(socket(),
                   buffer->GetWASBUF(),
                   1,
                   NULL,
                   &flags,
                   buffer->GetCleanOverlapped(),
                   NULL);
  if (rc == NO_ERROR || WSAGetLastError() == WSA_IO_PENDING) {
    pending_read_ = buffer;
    return true;
  }
  OverlappedBuffer::DisposeBuffer(buffer);
  pending_read_ = NULL;
  HandleIssueError();
  return false;
}


bool ClientSocket::IssueWrite() {
  ScopedLock lock(this);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_write_ != NULL);
  ASSERT(pending_write_->operation() == OverlappedBuffer::kWrite);

  int rc = WSASend(socket(),
                   pending_write_->GetWASBUF(),
                   1,
                   NULL,
                   0,
                   pending_write_->GetCleanOverlapped(),
                   NULL);
  if (rc == NO_ERROR || WSAGetLastError() == WSA_IO_PENDING) {
    return true;
  }
  OverlappedBuffer::DisposeBuffer(pending_write_);
  pending_write_ = NULL;
  HandleIssueError();
  return false;
}


void ClientSocket::IssueDisconnect() {
  OverlappedBuffer* buffer = OverlappedBuffer::AllocateDisconnectBuffer();
  BOOL ok = DisconnectEx_(
    socket(), buffer->GetCleanOverlapped(), TF_REUSE_SOCKET, 0);
  // DisconnectEx works like other OverlappedIO APIs, where we can get either an
  // immediate success or delayed operation by WSA_IO_PENDING being set.
  if (ok || WSAGetLastError() != WSA_IO_PENDING) {
    DisconnectComplete(buffer);
  }
  Dart_Port p = port();
  if (p != ILLEGAL_PORT) DartUtils::PostInt32(p, 1 << kDestroyedEvent);
  port_ = ILLEGAL_PORT;
}


void ClientSocket::DisconnectComplete(OverlappedBuffer* buffer) {
  OverlappedBuffer::DisposeBuffer(buffer);
  closesocket(socket());
  if (data_ready_ != NULL) {
    OverlappedBuffer::DisposeBuffer(data_ready_);
  }
  closed_ = true;
}


void ClientSocket::ConnectComplete(OverlappedBuffer* buffer) {
  OverlappedBuffer::DisposeBuffer(buffer);
  // Update socket to support full socket API, after ConnectEx completed.
  setsockopt(socket(), SOL_SOCKET, SO_UPDATE_CONNECT_CONTEXT, NULL, 0);
  Dart_Port p = port();
  if (p != ILLEGAL_PORT) {
    // If the port is set, we already listen for this socket in Dart.
    // Handle the cases here.
    if (!IsClosedRead()) {
      IssueRead();
    }
    if (!IsClosedWrite()) {
      DartUtils::PostInt32(p, 1 << kOutEvent);
    }
  }
}


void ClientSocket::EnsureInitialized(
    EventHandlerImplementation* event_handler) {
  ScopedLock lock(this);
  if (completion_port_ == INVALID_HANDLE_VALUE) {
    ASSERT(event_handler_ == NULL);
    event_handler_ = event_handler;
    CreateCompletionPort(event_handler_->completion_port());
  }
}


bool ClientSocket::IsClosed() {
  return connected_ && closed_;
}


bool DatagramSocket::IssueSendTo(struct sockaddr* sa, socklen_t sa_len) {
  ScopedLock lock(this);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_write_ != NULL);
  ASSERT(pending_write_->operation() == OverlappedBuffer::kSendTo);

  int rc = WSASendTo(socket(),
                     pending_write_->GetWASBUF(),
                     1,
                     NULL,
                     0,
                     sa,
                     sa_len,
                     pending_write_->GetCleanOverlapped(),
                     NULL);
  if (rc == NO_ERROR || WSAGetLastError() == WSA_IO_PENDING) {
    return true;
  }
  OverlappedBuffer::DisposeBuffer(pending_write_);
  pending_write_ = NULL;
  HandleIssueError();
  return false;
}


bool DatagramSocket::IssueRecvFrom() {
  ScopedLock lock(this);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_read_ == NULL);

  OverlappedBuffer* buffer = OverlappedBuffer::AllocateRecvFromBuffer(1024);

  DWORD flags;
  flags = 0;
  int len;
  int rc = WSARecvFrom(socket(),
                       buffer->GetWASBUF(),
                       1,
                       NULL,
                       &flags,
                       buffer->from(),
                       buffer->from_len_addr(),
                       buffer->GetCleanOverlapped(),
                       NULL);
  if (rc == NO_ERROR || WSAGetLastError() == WSA_IO_PENDING) {
    pending_read_ = buffer;
    return true;
  }
  OverlappedBuffer::DisposeBuffer(buffer);
  pending_read_ = NULL;
  HandleIssueError();
  return false;
}


void DatagramSocket::EnsureInitialized(
    EventHandlerImplementation* event_handler) {
  ScopedLock lock(this);
  if (completion_port_ == INVALID_HANDLE_VALUE) {
    ASSERT(event_handler_ == NULL);
    event_handler_ = event_handler;
    CreateCompletionPort(event_handler_->completion_port());
  }
}


bool DatagramSocket::IsClosed() {
  return IsClosing() && !HasPendingRead() && !HasPendingWrite();
}


void DatagramSocket::DoClose() {
  // Just close the socket. This will cause any queued requests to be aborted.
  closesocket(socket());
  MarkClosedRead();
  MarkClosedWrite();
  handle_ = INVALID_HANDLE_VALUE;
}


void EventHandlerImplementation::HandleInterrupt(InterruptMessage* msg) {
  ASSERT(this != NULL);
  if (msg->id == kTimeoutId) {
    // Change of timeout request. Just set the new timeout and port as the
    // completion thread will use the new timeout value for its next wait.
    timeout_queue_.UpdateTimeout(msg->dart_port, msg->data);
  } else if (msg->id == kShutdownId) {
    shutdown_ = true;
  } else {
    // No tokens to return on Windows.
    if ((msg->data & (1 << kReturnTokenCommand)) != 0) return;
    Handle* handle = reinterpret_cast<Handle*>(msg->id);
    ASSERT(handle != NULL);
    if (handle->is_listen_socket()) {
      ListenSocket* listen_socket =
          reinterpret_cast<ListenSocket*>(handle);
      listen_socket->EnsureInitialized(this);
      listen_socket->SetPortAndMask(msg->dart_port, msg->data);

      Handle::ScopedLock lock(listen_socket);

      // If incoming connections are requested make sure to post already
      // accepted connections.
      if ((msg->data & (1 << kInEvent)) != 0) {
        if (listen_socket->CanAccept()) {
          int event_mask = (1 << kInEvent);
          handle->set_mask(handle->mask() & ~event_mask);
          DartUtils::PostInt32(handle->port(), event_mask);
        }
      }
    } else {
      handle->EnsureInitialized(this);

      Handle::ScopedLock lock(handle);

      // Only set mask if we turned on kInEvent or kOutEvent.
      if ((msg->data & ((1 << kInEvent) | (1 << kOutEvent))) != 0) {
        handle->SetPortAndMask(msg->dart_port, msg->data);
      }

      // Issue a read.
      if ((msg->data & (1 << kInEvent)) != 0) {
        if (handle->is_datagram_socket()) {
          handle->IssueRecvFrom();
        } else if (handle->is_client_socket()) {
          if (reinterpret_cast<ClientSocket*>(handle)->is_connected()) {
            handle->IssueRead();
          }
        } else {
          handle->IssueRead();
        }
      }

      // If out events (can write events) have been requested, and there
      // are no pending writes, meaning any writes are already complete,
      // post an out event immediately.
      if ((msg->data & (1 << kOutEvent)) != 0) {
        if (!handle->HasPendingWrite()) {
          if (handle->is_client_socket()) {
            if (reinterpret_cast<ClientSocket*>(handle)->is_connected()) {
              DartUtils::PostInt32(handle->port(), 1 << kOutEvent);
            }
          } else {
            DartUtils::PostInt32(handle->port(), 1 << kOutEvent);
          }
        }
      }

      if (handle->is_client_socket()) {
        ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(handle);
        if ((msg->data & (1 << kShutdownReadCommand)) != 0) {
          client_socket->Shutdown(SD_RECEIVE);
        }

        if ((msg->data & (1 << kShutdownWriteCommand)) != 0) {
          client_socket->Shutdown(SD_SEND);
        }
      }
    }

    if ((msg->data & (1 << kCloseCommand)) != 0) {
      handle->SetPortAndMask(msg->dart_port, msg->data);
      handle->Close();
    }

    DeleteIfClosed(handle);
  }
}


void EventHandlerImplementation::HandleAccept(ListenSocket* listen_socket,
                                              OverlappedBuffer* buffer) {
  listen_socket->AcceptComplete(buffer, completion_port_);

  if (!listen_socket->IsClosing()) {
    int event_mask = 1 << kInEvent;
    if ((listen_socket->mask() & event_mask) != 0) {
      DartUtils::PostInt32(listen_socket->port(), event_mask);
    }
  }

  DeleteIfClosed(listen_socket);
}


void EventHandlerImplementation::HandleRead(Handle* handle,
                                            int bytes,
                                            OverlappedBuffer* buffer) {
  buffer->set_data_length(bytes);
  handle->ReadComplete(buffer);
  if (bytes > 0) {
    if (!handle->IsClosing()) {
      int event_mask = 1 << kInEvent;
      if ((handle->mask() & event_mask) != 0) {
        DartUtils::PostInt32(handle->port(), event_mask);
      }
    }
  } else {
    handle->MarkClosedRead();
    if (bytes == 0) {
      HandleClosed(handle);
    } else {
      HandleError(handle);
    }
  }

  DeleteIfClosed(handle);
}


void EventHandlerImplementation::HandleRecvFrom(Handle* handle,
                                                int bytes,
                                                OverlappedBuffer* buffer) {
  ASSERT(handle->is_datagram_socket());
  buffer->set_data_length(bytes);
  handle->ReadComplete(buffer);
  if (!handle->IsClosing()) {
    int event_mask = 1 << kInEvent;
    if ((handle->mask() & event_mask) != 0) {
      DartUtils::PostInt32(handle->port(), event_mask);
    }
  }

  DeleteIfClosed(handle);
}


void EventHandlerImplementation::HandleWrite(Handle* handle,
                                             int bytes,
                                             OverlappedBuffer* buffer) {
  handle->WriteComplete(buffer);

  if (bytes >= 0) {
    if (!handle->IsError() && !handle->IsClosing()) {
      int event_mask = 1 << kOutEvent;
      ASSERT(!handle->is_client_socket() ||
             reinterpret_cast<ClientSocket*>(handle)->is_connected());
      if ((handle->mask() & event_mask) != 0) {
        DartUtils::PostInt32(handle->port(), event_mask);
      }
    }
  } else {
    HandleError(handle);
  }

  DeleteIfClosed(handle);
}


void EventHandlerImplementation::HandleDisconnect(
    ClientSocket* client_socket,
    int bytes,
    OverlappedBuffer* buffer) {
  client_socket->DisconnectComplete(buffer);
  DeleteIfClosed(client_socket);
}


void EventHandlerImplementation::HandleConnect(
    ClientSocket* client_socket,
    int bytes,
    OverlappedBuffer* buffer) {
  if (bytes < 0) {
    HandleError(client_socket);
    OverlappedBuffer::DisposeBuffer(buffer);
  } else {
    client_socket->ConnectComplete(buffer);
  }
  client_socket->mark_connected();
  DeleteIfClosed(client_socket);
}


void EventHandlerImplementation::HandleTimeout() {
  if (!timeout_queue_.HasTimeout()) return;
  DartUtils::PostNull(timeout_queue_.CurrentPort());
  timeout_queue_.RemoveCurrent();
}


void EventHandlerImplementation::HandleIOCompletion(DWORD bytes,
                                                    ULONG_PTR key,
                                                    OVERLAPPED* overlapped) {
  OverlappedBuffer* buffer = OverlappedBuffer::GetFromOverlapped(overlapped);
  switch (buffer->operation()) {
    case OverlappedBuffer::kAccept: {
      ListenSocket* listen_socket = reinterpret_cast<ListenSocket*>(key);
      HandleAccept(listen_socket, buffer);
      break;
    }
    case OverlappedBuffer::kRead: {
      Handle* handle = reinterpret_cast<Handle*>(key);
      HandleRead(handle, bytes, buffer);
      break;
    }
    case OverlappedBuffer::kRecvFrom: {
      Handle* handle = reinterpret_cast<Handle*>(key);
      HandleRecvFrom(handle, bytes, buffer);
      break;
    }
    case OverlappedBuffer::kWrite:
    case OverlappedBuffer::kSendTo: {
      Handle* handle = reinterpret_cast<Handle*>(key);
      HandleWrite(handle, bytes, buffer);
      break;
    }
    case OverlappedBuffer::kDisconnect: {
      ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(key);
      HandleDisconnect(client_socket, bytes, buffer);
      break;
    }
    case OverlappedBuffer::kConnect: {
      ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(key);
      HandleConnect(client_socket, bytes, buffer);
      break;
    }
    default:
      UNREACHABLE();
  }
}


EventHandlerImplementation::EventHandlerImplementation() {
  intptr_t result;
  completion_port_ =
      CreateIoCompletionPort(INVALID_HANDLE_VALUE, NULL, NULL, 1);
  if (completion_port_ == NULL) {
    FATAL("Completion port creation failed");
  }
  shutdown_ = false;
}


EventHandlerImplementation::~EventHandlerImplementation() {
  CloseHandle(completion_port_);
}


int64_t EventHandlerImplementation::GetTimeout() {
  if (!timeout_queue_.HasTimeout()) {
    return kInfinityTimeout;
  }
  int64_t millis = timeout_queue_.CurrentTimeout() -
      TimerUtils::GetCurrentTimeMilliseconds();
  return (millis < 0) ? 0 : millis;
}


void EventHandlerImplementation::SendData(intptr_t id,
                                          Dart_Port dart_port,
                                          int64_t data) {
  InterruptMessage* msg = new InterruptMessage;
  msg->id = id;
  msg->dart_port = dart_port;
  msg->data = data;
  BOOL ok = PostQueuedCompletionStatus(
      completion_port_, 0, NULL, reinterpret_cast<OVERLAPPED*>(msg));
  if (!ok) {
    FATAL("PostQueuedCompletionStatus failed");
  }
}


void EventHandlerImplementation::EventHandlerEntry(uword args) {
  EventHandler* handler = reinterpret_cast<EventHandler*>(args);
  EventHandlerImplementation* handler_impl = &handler->delegate_;
  ASSERT(handler_impl != NULL);
  while (!handler_impl->shutdown_) {
    DWORD bytes;
    ULONG_PTR key;
    OVERLAPPED* overlapped;
    int64_t millis = handler_impl->GetTimeout();
    ASSERT(millis == kInfinityTimeout || millis >= 0);
    if (millis > kMaxInt32) millis = kMaxInt32;
    ASSERT(sizeof(int32_t) == sizeof(DWORD));
    BOOL ok = GetQueuedCompletionStatus(handler_impl->completion_port(),
                                        &bytes,
                                        &key,
                                        &overlapped,
                                        static_cast<DWORD>(millis));

    if (!ok && overlapped == NULL) {
      if (GetLastError() == ERROR_ABANDONED_WAIT_0) {
        // The completion port should never be closed.
        Log::Print("Completion port closed\n");
        UNREACHABLE();
      } else {
        // Timeout is signalled by false result and NULL in overlapped.
        handler_impl->HandleTimeout();
      }
    } else if (!ok) {
      // Treat ERROR_CONNECTION_ABORTED as connection closed.
      // The error ERROR_OPERATION_ABORTED is set for pending
      // accept requests for a listen socket which is closed.
      // ERROR_NETNAME_DELETED occurs when the client closes
      // the socket it is reading from.
      DWORD last_error = GetLastError();
      if (last_error == ERROR_CONNECTION_ABORTED ||
          last_error == ERROR_OPERATION_ABORTED ||
          last_error == ERROR_NETNAME_DELETED ||
          last_error == ERROR_BROKEN_PIPE) {
        ASSERT(bytes == 0);
        handler_impl->HandleIOCompletion(bytes, key, overlapped);
      } else {
        ASSERT(bytes == 0);
        handler_impl->HandleIOCompletion(-1, key, overlapped);
      }
    } else if (key == NULL) {
      // A key of NULL signals an interrupt message.
      InterruptMessage* msg = reinterpret_cast<InterruptMessage*>(overlapped);
      handler_impl->HandleInterrupt(msg);
      delete msg;
    } else {
      handler_impl->HandleIOCompletion(bytes, key, overlapped);
    }
  }
  delete handler;
}


void EventHandlerImplementation::Start(EventHandler* handler) {
  int result = dart::Thread::Start(EventHandlerEntry,
                                   reinterpret_cast<uword>(handler));
  if (result != 0) {
    FATAL1("Failed to start event handler thread %d", result);
  }

  // Initialize Winsock32
  if (!Socket::Initialize()) {
    FATAL("Failed to initialized Windows sockets");
  }
}


void EventHandlerImplementation::Shutdown() {
  SendData(kShutdownId, 0, 0);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
