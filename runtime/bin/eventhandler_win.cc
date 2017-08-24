// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/eventhandler.h"
#include "bin/eventhandler_win.h"

#include <fcntl.h>     // NOLINT
#include <io.h>        // NOLINT
#include <mswsock.h>   // NOLINT
#include <winsock2.h>  // NOLINT
#include <ws2tcpip.h>  // NOLINT

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
static const int kMaxUDPPackageLength = 64 * 1024;

OverlappedBuffer* OverlappedBuffer::AllocateBuffer(int buffer_size,
                                                   Operation operation) {
  OverlappedBuffer* buffer =
      new (buffer_size) OverlappedBuffer(buffer_size, operation);
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

Handle::Handle(intptr_t handle)
    : ReferenceCounted(),
      DescriptorInfoBase(handle),
      handle_(reinterpret_cast<HANDLE>(handle)),
      completion_port_(INVALID_HANDLE_VALUE),
      event_handler_(NULL),
      data_ready_(NULL),
      pending_read_(NULL),
      pending_write_(NULL),
      last_error_(NOERROR),
      flags_(0),
      read_thread_id_(Thread::kInvalidThreadId),
      read_thread_handle_(NULL),
      read_thread_starting_(false),
      read_thread_finished_(false),
      monitor_(new Monitor()) {}

Handle::~Handle() {
  delete monitor_;
}

bool Handle::CreateCompletionPort(HANDLE completion_port) {
  ASSERT(completion_port_ == INVALID_HANDLE_VALUE);
  // A reference to the Handle is Retained by the IO completion port.
  // It is Released by DeleteIfClosed.
  Retain();
  completion_port_ = CreateIoCompletionPort(
      handle(), completion_port, reinterpret_cast<ULONG_PTR>(this), 0);
  return (completion_port_ != NULL);
}

void Handle::Close() {
  MonitorLocker ml(monitor_);
  if (!SupportsOverlappedIO()) {
    // If the handle uses synchronous I/O (e.g. stdin), cancel any pending
    // operation before closing the handle, so the read thread is not blocked.
    BOOL result = CancelIoEx(handle_, NULL);
// The Dart code 'stdin.listen(() {}).cancel()' causes this assert to be
// triggered on Windows 7, but not on Windows 10.
#if defined(DEBUG)
    if (IsWindows10OrGreater()) {
      ASSERT(result || (GetLastError() == ERROR_NOT_FOUND));
    }
#else
    USE(result);
#endif
  }
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
  MonitorLocker ml(monitor_);
  return pending_read_ != NULL;
}

bool Handle::HasPendingWrite() {
  MonitorLocker ml(monitor_);
  return pending_write_ != NULL;
}

void Handle::WaitForReadThreadStarted() {
  MonitorLocker ml(monitor_);
  while (read_thread_starting_) {
    ml.Wait();
  }
}

void Handle::WaitForReadThreadFinished() {
  HANDLE to_join = NULL;
  {
    MonitorLocker ml(monitor_);
    if (read_thread_id_ != Thread::kInvalidThreadId) {
      while (!read_thread_finished_) {
        ml.Wait();
      }
      read_thread_finished_ = false;
      read_thread_id_ = Thread::kInvalidThreadId;
      to_join = read_thread_handle_;
      read_thread_handle_ = NULL;
    }
  }
  if (to_join != NULL) {
    // Join the read thread.
    DWORD res = WaitForSingleObject(to_join, INFINITE);
    CloseHandle(to_join);
    ASSERT(res == WAIT_OBJECT_0);
  }
}

void Handle::ReadComplete(OverlappedBuffer* buffer) {
  WaitForReadThreadStarted();
  {
    MonitorLocker ml(monitor_);
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
  WaitForReadThreadFinished();
}

void Handle::RecvFromComplete(OverlappedBuffer* buffer) {
  ReadComplete(buffer);
}

void Handle::WriteComplete(OverlappedBuffer* buffer) {
  MonitorLocker ml(monitor_);
  // Currently only one outstanding write at the time.
  ASSERT(pending_write_ == buffer);
  OverlappedBuffer::DisposeBuffer(buffer);
  pending_write_ = NULL;
}

static void ReadFileThread(uword args) {
  Handle* handle = reinterpret_cast<Handle*>(args);
  handle->ReadSyncCompleteAsync();
}

void Handle::NotifyReadThreadStarted() {
  MonitorLocker ml(monitor_);
  ASSERT(read_thread_starting_);
  ASSERT(read_thread_id_ == Thread::kInvalidThreadId);
  read_thread_id_ = Thread::GetCurrentThreadId();
  read_thread_handle_ = OpenThread(SYNCHRONIZE, false, read_thread_id_);
  read_thread_starting_ = false;
  ml.Notify();
}

void Handle::NotifyReadThreadFinished() {
  MonitorLocker ml(monitor_);
  ASSERT(!read_thread_finished_);
  ASSERT(read_thread_id_ != Thread::kInvalidThreadId);
  read_thread_finished_ = true;
  ml.Notify();
}

void Handle::ReadSyncCompleteAsync() {
  NotifyReadThreadStarted();
  ASSERT(pending_read_ != NULL);
  ASSERT(pending_read_->GetBufferSize() >= kStdOverlappedBufferSize);

  DWORD buffer_size = pending_read_->GetBufferSize();
  if (GetFileType(handle_) == FILE_TYPE_CHAR) {
    buffer_size = kStdOverlappedBufferSize;
  }
  char* buffer_start = pending_read_->GetBufferStart();
  DWORD bytes_read = 0;
  BOOL ok = ReadFile(handle_, buffer_start, buffer_size, &bytes_read, NULL);
  if (!ok) {
    bytes_read = 0;
  }
  OVERLAPPED* overlapped = pending_read_->GetCleanOverlapped();
  ok =
      PostQueuedCompletionStatus(event_handler_->completion_port(), bytes_read,
                                 reinterpret_cast<ULONG_PTR>(this), overlapped);
  if (!ok) {
    FATAL("PostQueuedCompletionStatus failed");
  }
  NotifyReadThreadFinished();
}

bool Handle::IssueRead() {
  ASSERT(type_ != kListenSocket);
  ASSERT(pending_read_ == NULL);
  OverlappedBuffer* buffer = OverlappedBuffer::AllocateReadBuffer(kBufferSize);
  if (SupportsOverlappedIO()) {
    ASSERT(completion_port_ != INVALID_HANDLE_VALUE);

    BOOL ok =
        ReadFile(handle_, buffer->GetBufferStart(), buffer->GetBufferSize(),
                 NULL, buffer->GetCleanOverlapped());
    if (ok || (GetLastError() == ERROR_IO_PENDING)) {
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
    read_thread_starting_ = true;
    int result = Thread::Start(ReadFileThread, reinterpret_cast<uword>(this));
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
  MonitorLocker ml(monitor_);
  ASSERT(type_ != kListenSocket);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_write_ != NULL);
  ASSERT(pending_write_->operation() == OverlappedBuffer::kWrite);

  OverlappedBuffer* buffer = pending_write_;
  BOOL ok =
      WriteFile(handle_, buffer->GetBufferStart(), buffer->GetBufferSize(),
                NULL, buffer->GetCleanOverlapped());
  if (ok || (GetLastError() == ERROR_IO_PENDING)) {
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
    handle->NotifyAllDartPorts(event_mask);
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

void FileHandle::EnsureInitialized(EventHandlerImplementation* event_handler) {
  MonitorLocker ml(monitor_);
  event_handler_ = event_handler;
  if (completion_port_ == INVALID_HANDLE_VALUE) {
    if (SupportsOverlappedIO()) {
      CreateCompletionPort(event_handler_->completion_port());
    } else {
      // We need to retain the Handle even if overlapped IO is not supported.
      // It is Released by DeleteIfClosed after ReadSyncCompleteAsync
      // manually puts an event on the IO completion port.
      Retain();
      completion_port_ = event_handler_->completion_port();
    }
  }
}

bool FileHandle::IsClosed() {
  return IsClosing() && !HasPendingRead() && !HasPendingWrite();
}

void DirectoryWatchHandle::EnsureInitialized(
    EventHandlerImplementation* event_handler) {
  MonitorLocker ml(monitor_);
  event_handler_ = event_handler;
  if (completion_port_ == INVALID_HANDLE_VALUE) {
    CreateCompletionPort(event_handler_->completion_port());
  }
}

bool DirectoryWatchHandle::IsClosed() {
  return IsClosing() && (pending_read_ == NULL);
}

bool DirectoryWatchHandle::IssueRead() {
  // It may have been started before, as we start the directory-handler when
  // we create it.
  if ((pending_read_ != NULL) || (data_ready_ != NULL)) {
    return true;
  }
  OverlappedBuffer* buffer = OverlappedBuffer::AllocateReadBuffer(kBufferSize);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  BOOL ok = ReadDirectoryChangesW(handle_, buffer->GetBufferStart(),
                                  buffer->GetBufferSize(), recursive_, events_,
                                  NULL, buffer->GetCleanOverlapped(), NULL);
  if (ok || (GetLastError() == ERROR_IO_PENDING)) {
    // Completing asynchronously.
    pending_read_ = buffer;
    return true;
  }
  OverlappedBuffer::DisposeBuffer(buffer);
  return false;
}

void DirectoryWatchHandle::Stop() {
  MonitorLocker ml(monitor_);
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
  int status = WSAIoctl(socket(), SIO_GET_EXTENSION_FUNCTION_POINTER,
                        &guid_accept_ex, sizeof(guid_accept_ex), &AcceptEx_,
                        sizeof(AcceptEx_), &bytes, NULL, NULL);
  return (status != SOCKET_ERROR);
}

bool ListenSocket::IssueAccept() {
  MonitorLocker ml(monitor_);

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
  ok = AcceptEx_(socket(), buffer->client(), buffer->GetBufferStart(),
                 0,  // For now don't receive data with accept.
                 kAcceptExAddressStorageSize, kAcceptExAddressStorageSize,
                 &received, buffer->GetCleanOverlapped());
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
  MonitorLocker ml(monitor_);
  if (!IsClosing()) {
    // Update the accepted socket to support the full range of API calls.
    SOCKET s = socket();
    int rc = setsockopt(buffer->client(), SOL_SOCKET, SO_UPDATE_ACCEPT_CONTEXT,
                        reinterpret_cast<char*>(&s), sizeof(s));
    if (rc == NO_ERROR) {
      // Insert the accepted socket into the list.
      ClientSocket* client_socket = new ClientSocket(buffer->client());
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
      accepted_count_++;
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
    handle->set_completion_port(INVALID_HANDLE_VALUE);
    handle->set_event_handler(NULL);
    handle->NotifyAllDartPorts(1 << kDestroyedEvent);
    handle->RemoveAllPorts();
    // Once the Handle is closed, no further events on the IO completion port
    // will mention it. Thus, we can drop the reference here.
    handle->Release();
  }
}

void ListenSocket::DoClose() {
  closesocket(socket());
  handle_ = INVALID_HANDLE_VALUE;
  while (CanAccept()) {
    // Get rid of connections already accepted.
    ClientSocket* client = Accept();
    if (client != NULL) {
      client->Close();
      // Release the reference from the list.
      // When an accept completes, we make a new ClientSocket (1 reference),
      // and add it to the IO completion port (1 more reference). If an
      // accepted connection is never requested by the Dart code, then
      // this list owns a reference (first Release), and the IO completion
      // port owns a reference, (second Release in DeleteIfClosed).
      client->Release();
      DeleteIfClosed(client);
    } else {
      break;
    }
  }
  // To finish resetting the state of the ListenSocket back to what it was
  // before EnsureInitialized was called, we have to reset the AcceptEx_
  // function pointer.
  AcceptEx_ = NULL;
}

bool ListenSocket::CanAccept() {
  MonitorLocker ml(monitor_);
  return accepted_head_ != NULL;
}

ClientSocket* ListenSocket::Accept() {
  MonitorLocker ml(monitor_);

  ClientSocket* result = NULL;

  if (accepted_head_ != NULL) {
    result = accepted_head_;
    accepted_head_ = accepted_head_->next();
    if (accepted_head_ == NULL) {
      accepted_tail_ = NULL;
    }
    result->set_next(NULL);
    accepted_count_--;
  }

  if (pending_accept_count_ < 5) {
    // We have less than 5 pending accepts, queue another.
    if (!IsClosing()) {
      if (!IssueAccept()) {
        HandleError(this);
      }
    }
  }

  return result;
}

void ListenSocket::EnsureInitialized(
    EventHandlerImplementation* event_handler) {
  MonitorLocker ml(monitor_);
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
  MonitorLocker ml(monitor_);
  if (data_ready_ == NULL) {
    return 0;
  }
  ASSERT(!data_ready_->IsEmpty());
  return data_ready_->GetRemainingLength();
}

intptr_t Handle::Read(void* buffer, intptr_t num_bytes) {
  MonitorLocker ml(monitor_);
  if (data_ready_ == NULL) {
    return 0;
  }
  num_bytes =
      data_ready_->Read(buffer, Utils::Minimum<intptr_t>(num_bytes, INT_MAX));
  if (data_ready_->IsEmpty()) {
    OverlappedBuffer::DisposeBuffer(data_ready_);
    data_ready_ = NULL;
    if (!IsClosing() && !IsClosedRead()) {
      IssueRead();
    }
  }
  return num_bytes;
}

intptr_t Handle::RecvFrom(void* buffer,
                          intptr_t num_bytes,
                          struct sockaddr* sa,
                          socklen_t sa_len) {
  MonitorLocker ml(monitor_);
  if (data_ready_ == NULL) {
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
  OverlappedBuffer::DisposeBuffer(data_ready_);
  data_ready_ = NULL;
  if (!IsClosing() && !IsClosedRead()) {
    IssueRecvFrom();
  }
  return num_bytes;
}

intptr_t Handle::Write(const void* buffer, intptr_t num_bytes) {
  MonitorLocker ml(monitor_);
  if (pending_write_ != NULL) {
    return 0;
  }
  if (num_bytes > kBufferSize) {
    num_bytes = kBufferSize;
  }
  ASSERT(SupportsOverlappedIO());
  if (completion_port_ == INVALID_HANDLE_VALUE) {
    return 0;
  }
  int truncated_bytes = Utils::Minimum<intptr_t>(num_bytes, INT_MAX);
  pending_write_ = OverlappedBuffer::AllocateWriteBuffer(truncated_bytes);
  pending_write_->Write(buffer, truncated_bytes);
  if (!IssueWrite()) {
    return -1;
  }
  return truncated_bytes;
}

intptr_t Handle::SendTo(const void* buffer,
                        intptr_t num_bytes,
                        struct sockaddr* sa,
                        socklen_t sa_len) {
  MonitorLocker ml(monitor_);
  if (pending_write_ != NULL) {
    return 0;
  }
  if (num_bytes > kBufferSize) {
    num_bytes = kBufferSize;
  }
  ASSERT(SupportsOverlappedIO());
  if (completion_port_ == INVALID_HANDLE_VALUE) {
    return 0;
  }
  pending_write_ = OverlappedBuffer::AllocateSendToBuffer(num_bytes);
  pending_write_->Write(buffer, num_bytes);
  if (!IssueSendTo(sa, sa_len)) {
    return -1;
  }
  return num_bytes;
}

Mutex* StdHandle::stdin_mutex_ = new Mutex();
StdHandle* StdHandle::stdin_ = NULL;

StdHandle* StdHandle::Stdin(HANDLE handle) {
  MutexLocker ml(stdin_mutex_);
  if (stdin_ == NULL) {
    stdin_ = new StdHandle(handle);
  }
  return stdin_;
}

static void WriteFileThread(uword args) {
  StdHandle* handle = reinterpret_cast<StdHandle*>(args);
  handle->RunWriteLoop();
}

void StdHandle::RunWriteLoop() {
  MonitorLocker ml(monitor_);
  write_thread_running_ = true;
  thread_id_ = Thread::GetCurrentThreadId();
  thread_handle_ = OpenThread(SYNCHRONIZE, false, thread_id_);
  // Notify we have started.
  ml.Notify();

  while (write_thread_running_) {
    ml.Wait(Monitor::kNoTimeout);
    if (pending_write_ != NULL) {
      // We woke up and had a pending write. Execute it.
      WriteSyncCompleteAsync();
    }
  }

  write_thread_exists_ = false;
  ml.Notify();
}

void StdHandle::WriteSyncCompleteAsync() {
  ASSERT(pending_write_ != NULL);

  DWORD bytes_written = -1;
  BOOL ok = WriteFile(handle_, pending_write_->GetBufferStart(),
                      pending_write_->GetBufferSize(), &bytes_written, NULL);
  if (!ok) {
    bytes_written = 0;
  }
  thread_wrote_ += bytes_written;
  OVERLAPPED* overlapped = pending_write_->GetCleanOverlapped();
  ok = PostQueuedCompletionStatus(
      event_handler_->completion_port(), bytes_written,
      reinterpret_cast<ULONG_PTR>(this), overlapped);
  if (!ok) {
    FATAL("PostQueuedCompletionStatus failed");
  }
}

intptr_t StdHandle::Write(const void* buffer, intptr_t num_bytes) {
  MonitorLocker ml(monitor_);
  if (pending_write_ != NULL) {
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
    // the events it puts on the IO completion port. The reference is
    // Released by DeleteIfClosed.
    Retain();
    int result = Thread::Start(WriteFileThread, reinterpret_cast<uword>(this));
    if (result != 0) {
      FATAL1("Failed to start write file thread %d", result);
    }
    while (!write_thread_running_) {
      // Wait until we the thread is running.
      ml.Wait(Monitor::kNoTimeout);
    }
  }
  // Only queue up to INT_MAX bytes.
  int truncated_bytes = Utils::Minimum<intptr_t>(num_bytes, INT_MAX);
  // Create buffer and notify thread about the new handle.
  pending_write_ = OverlappedBuffer::AllocateWriteBuffer(truncated_bytes);
  pending_write_->Write(buffer, truncated_bytes);
  ml.Notify();
  return 0;
}

void StdHandle::DoClose() {
  {
    MonitorLocker ml(monitor_);
    if (write_thread_exists_) {
      write_thread_running_ = false;
      ml.Notify();
      while (write_thread_exists_) {
        ml.Wait(Monitor::kNoTimeout);
      }
      // Join the thread.
      DWORD res = WaitForSingleObject(thread_handle_, INFINITE);
      CloseHandle(thread_handle_);
      ASSERT(res == WAIT_OBJECT_0);
    }
    Handle::DoClose();
  }
  MutexLocker ml(stdin_mutex_);
  stdin_->Release();
  StdHandle::stdin_ = NULL;
}

#if defined(DEBUG)
intptr_t ClientSocket::disconnecting_ = 0;
#endif

bool ClientSocket::LoadDisconnectEx() {
  // Load the DisconnectEx function into memory using WSAIoctl.
  GUID guid_disconnect_ex = WSAID_DISCONNECTEX;
  DWORD bytes;
  int status =
      WSAIoctl(socket(), SIO_GET_EXTENSION_FUNCTION_POINTER,
               &guid_disconnect_ex, sizeof(guid_disconnect_ex), &DisconnectEx_,
               sizeof(DisconnectEx_), &bytes, NULL, NULL);
  return (status != SOCKET_ERROR);
}

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

void ClientSocket::DoClose() {
  // Always do a shutdown before initiating a disconnect.
  shutdown(socket(), SD_BOTH);
  IssueDisconnect();
  handle_ = INVALID_HANDLE_VALUE;
}

bool ClientSocket::IssueRead() {
  MonitorLocker ml(monitor_);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_read_ == NULL);

  // TODO(sgjesse): Use a MTU value here. Only the loopback adapter can
  // handle 64k datagrams.
  OverlappedBuffer* buffer = OverlappedBuffer::AllocateReadBuffer(65536);

  DWORD flags;
  flags = 0;
  int rc = WSARecv(socket(), buffer->GetWASBUF(), 1, NULL, &flags,
                   buffer->GetCleanOverlapped(), NULL);
  if ((rc == NO_ERROR) || (WSAGetLastError() == WSA_IO_PENDING)) {
    pending_read_ = buffer;
    return true;
  }
  OverlappedBuffer::DisposeBuffer(buffer);
  pending_read_ = NULL;
  HandleIssueError();
  return false;
}

bool ClientSocket::IssueWrite() {
  MonitorLocker ml(monitor_);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_write_ != NULL);
  ASSERT(pending_write_->operation() == OverlappedBuffer::kWrite);

  int rc = WSASend(socket(), pending_write_->GetWASBUF(), 1, NULL, 0,
                   pending_write_->GetCleanOverlapped(), NULL);
  if ((rc == NO_ERROR) || (WSAGetLastError() == WSA_IO_PENDING)) {
    return true;
  }
  OverlappedBuffer::DisposeBuffer(pending_write_);
  pending_write_ = NULL;
  HandleIssueError();
  return false;
}

void ClientSocket::IssueDisconnect() {
  OverlappedBuffer* buffer = OverlappedBuffer::AllocateDisconnectBuffer();
  BOOL ok =
      DisconnectEx_(socket(), buffer->GetCleanOverlapped(), TF_REUSE_SOCKET, 0);
  // DisconnectEx works like other OverlappedIO APIs, where we can get either an
  // immediate success or delayed operation by WSA_IO_PENDING being set.
  if (ok || (WSAGetLastError() != WSA_IO_PENDING)) {
    DisconnectComplete(buffer);
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

void ClientSocket::DisconnectComplete(OverlappedBuffer* buffer) {
  OverlappedBuffer::DisposeBuffer(buffer);
  closesocket(socket());
  if (data_ready_ != NULL) {
    OverlappedBuffer::DisposeBuffer(data_ready_);
  }
  mark_closed();
#if defined(DEBUG)
  disconnecting_--;
#endif
}

void ClientSocket::ConnectComplete(OverlappedBuffer* buffer) {
  OverlappedBuffer::DisposeBuffer(buffer);
  // Update socket to support full socket API, after ConnectEx completed.
  setsockopt(socket(), SOL_SOCKET, SO_UPDATE_CONNECT_CONTEXT, NULL, 0);
  // If the port is set, we already listen for this socket in Dart.
  // Handle the cases here.
  if (!IsClosedRead() && ((Mask() & (1 << kInEvent)) != 0)) {
    IssueRead();
  }
  if (!IsClosedWrite() && ((Mask() & (1 << kOutEvent)) != 0)) {
    Dart_Port port = NextNotifyDartPort(1 << kOutEvent);
    DartUtils::PostInt32(port, 1 << kOutEvent);
  }
}

void ClientSocket::EnsureInitialized(
    EventHandlerImplementation* event_handler) {
  MonitorLocker ml(monitor_);
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
  MonitorLocker ml(monitor_);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_write_ != NULL);
  ASSERT(pending_write_->operation() == OverlappedBuffer::kSendTo);

  int rc = WSASendTo(socket(), pending_write_->GetWASBUF(), 1, NULL, 0, sa,
                     sa_len, pending_write_->GetCleanOverlapped(), NULL);
  if ((rc == NO_ERROR) || (WSAGetLastError() == WSA_IO_PENDING)) {
    return true;
  }
  OverlappedBuffer::DisposeBuffer(pending_write_);
  pending_write_ = NULL;
  HandleIssueError();
  return false;
}

bool DatagramSocket::IssueRecvFrom() {
  MonitorLocker ml(monitor_);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_read_ == NULL);

  OverlappedBuffer* buffer =
      OverlappedBuffer::AllocateRecvFromBuffer(kMaxUDPPackageLength);

  DWORD flags;
  flags = 0;
  int rc = WSARecvFrom(socket(), buffer->GetWASBUF(), 1, NULL, &flags,
                       buffer->from(), buffer->from_len_addr(),
                       buffer->GetCleanOverlapped(), NULL);
  if ((rc == NO_ERROR) || (WSAGetLastError() == WSA_IO_PENDING)) {
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
  MonitorLocker ml(monitor_);
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
    ASSERT(handle != NULL);

    if (handle->is_listen_socket()) {
      ListenSocket* listen_socket = reinterpret_cast<ListenSocket*>(handle);
      listen_socket->EnsureInitialized(this);

      MonitorLocker ml(listen_socket->monitor_);

      if (IS_COMMAND(msg->data, kReturnTokenCommand)) {
        listen_socket->ReturnTokens(msg->dart_port, TOKEN_COUNT(msg->data));
      } else if (IS_COMMAND(msg->data, kSetEventMaskCommand)) {
        // `events` can only have kInEvent/kOutEvent flags set.
        intptr_t events = msg->data & EVENT_MASK;
        ASSERT(0 == (events & ~(1 << kInEvent | 1 << kOutEvent)));
        listen_socket->SetPortAndMask(msg->dart_port, events);
        TryDispatchingPendingAccepts(listen_socket);
      } else if (IS_COMMAND(msg->data, kCloseCommand)) {
        listen_socket->RemovePort(msg->dart_port);

        // We only close the socket file descriptor from the operating
        // system if there are no other dart socket objects which
        // are listening on the same (address, port) combination.
        ListeningSocketRegistry* registry = ListeningSocketRegistry::Instance();
        MutexLocker locker(registry->mutex());
        if (registry->CloseSafe(socket)) {
          ASSERT(listen_socket->Mask() == 0);
          listen_socket->Close();
          socket->SetClosedFd();
        }

        DartUtils::PostInt32(msg->dart_port, 1 << kDestroyedEvent);
      } else {
        UNREACHABLE();
      }
    } else {
      handle->EnsureInitialized(this);
      MonitorLocker ml(handle->monitor_);

      if (IS_COMMAND(msg->data, kReturnTokenCommand)) {
        handle->ReturnTokens(msg->dart_port, TOKEN_COUNT(msg->data));
      } else if (IS_COMMAND(msg->data, kSetEventMaskCommand)) {
        // `events` can only have kInEvent/kOutEvent flags set.
        intptr_t events = msg->data & EVENT_MASK;
        ASSERT(0 == (events & ~(1 << kInEvent | 1 << kOutEvent)));

        handle->SetPortAndMask(msg->dart_port, events);

        // Issue a read.
        if ((handle->Mask() & (1 << kInEvent)) != 0) {
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
        if ((events & (1 << kOutEvent)) != 0) {
          if (!handle->HasPendingWrite()) {
            if (handle->is_client_socket()) {
              if (reinterpret_cast<ClientSocket*>(handle)->is_connected()) {
                intptr_t event_mask = 1 << kOutEvent;
                if ((handle->Mask() & event_mask) != 0) {
                  Dart_Port port = handle->NextNotifyDartPort(event_mask);
                  DartUtils::PostInt32(port, event_mask);
                }
              }
            } else {
              intptr_t event_mask = 1 << kOutEvent;
              if ((handle->Mask() & event_mask) != 0) {
                Dart_Port port = handle->NextNotifyDartPort(event_mask);
                DartUtils::PostInt32(port, event_mask);
              }
            }
          }
        }
      } else if (IS_COMMAND(msg->data, kShutdownReadCommand)) {
        ASSERT(handle->is_client_socket());

        ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(handle);
        client_socket->Shutdown(SD_RECEIVE);
      } else if (IS_COMMAND(msg->data, kShutdownWriteCommand)) {
        ASSERT(handle->is_client_socket());

        ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(handle);
        client_socket->Shutdown(SD_SEND);
      } else if (IS_COMMAND(msg->data, kCloseCommand)) {
        handle->SetPortAndMask(msg->dart_port, 0);
        handle->Close();
        socket->SetClosedFd();
      } else {
        UNREACHABLE();
      }
    }

    DeleteIfClosed(handle);
  }
}

void EventHandlerImplementation::HandleAccept(ListenSocket* listen_socket,
                                              OverlappedBuffer* buffer) {
  listen_socket->AcceptComplete(buffer, completion_port_);

  {
    MonitorLocker ml(listen_socket->monitor_);
    TryDispatchingPendingAccepts(listen_socket);
  }

  DeleteIfClosed(listen_socket);
}

void EventHandlerImplementation::TryDispatchingPendingAccepts(
    ListenSocket* listen_socket) {
  if (!listen_socket->IsClosing() && listen_socket->CanAccept()) {
    intptr_t event_mask = 1 << kInEvent;
    for (int i = 0; (i < listen_socket->accepted_count()) &&
                    (listen_socket->Mask() == event_mask);
         i++) {
      Dart_Port port = listen_socket->NextNotifyDartPort(event_mask);
      DartUtils::PostInt32(port, event_mask);
    }
  }
}

void EventHandlerImplementation::HandleRead(Handle* handle,
                                            int bytes,
                                            OverlappedBuffer* buffer) {
  buffer->set_data_length(bytes);
  handle->ReadComplete(buffer);
  if (bytes > 0) {
    if (!handle->IsClosing()) {
      int event_mask = 1 << kInEvent;
      if ((handle->Mask() & event_mask) != 0) {
        Dart_Port port = handle->NextNotifyDartPort(event_mask);
        DartUtils::PostInt32(port, event_mask);
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
  if (bytes >= 0) {
    buffer->set_data_length(bytes);
    handle->ReadComplete(buffer);
    if (!handle->IsClosing()) {
      int event_mask = 1 << kInEvent;
      if ((handle->Mask() & event_mask) != 0) {
        Dart_Port port = handle->NextNotifyDartPort(event_mask);
        DartUtils::PostInt32(port, event_mask);
      }
    }
  } else {
    HandleError(handle);
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
      if ((handle->Mask() & event_mask) != 0) {
        Dart_Port port = handle->NextNotifyDartPort(event_mask);
        DartUtils::PostInt32(port, event_mask);
      }
    }
  } else {
    HandleError(handle);
  }

  DeleteIfClosed(handle);
}

void EventHandlerImplementation::HandleDisconnect(ClientSocket* client_socket,
                                                  int bytes,
                                                  OverlappedBuffer* buffer) {
  client_socket->DisconnectComplete(buffer);
  DeleteIfClosed(client_socket);
}

void EventHandlerImplementation::HandleConnect(ClientSocket* client_socket,
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
  if (!timeout_queue_.HasTimeout()) {
    return;
  }
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
    // A key of NULL signals an interrupt message.
    InterruptMessage* msg = reinterpret_cast<InterruptMessage*>(overlapped);
    HandleInterrupt(msg);
    delete msg;
  } else {
    HandleIOCompletion(bytes, key, overlapped);
  }
}

EventHandlerImplementation::EventHandlerImplementation() {
  startup_monitor_ = new Monitor();
  handler_thread_id_ = Thread::kInvalidThreadId;
  handler_thread_handle_ = NULL;
  completion_port_ =
      CreateIoCompletionPort(INVALID_HANDLE_VALUE, NULL, NULL, 1);
  if (completion_port_ == NULL) {
    FATAL("Completion port creation failed");
  }
  shutdown_ = false;
}

EventHandlerImplementation::~EventHandlerImplementation() {
  // Join the handler thread.
  DWORD res = WaitForSingleObject(handler_thread_handle_, INFINITE);
  CloseHandle(handler_thread_handle_);
  ASSERT(res == WAIT_OBJECT_0);
  delete startup_monitor_;
  CloseHandle(completion_port_);
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
  ASSERT(handler_impl != NULL);

  {
    MonitorLocker ml(handler_impl->startup_monitor_);
    handler_impl->handler_thread_id_ = Thread::GetCurrentThreadId();
    handler_impl->handler_thread_handle_ =
        OpenThread(SYNCHRONIZE, false, handler_impl->handler_thread_id_);
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

    if (!ok && (overlapped == NULL)) {
      if (GetLastError() == ERROR_ABANDONED_WAIT_0) {
        // The completion port should never be closed.
        Log::Print("Completion port closed\n");
        UNREACHABLE();
      } else {
        // Timeout is signalled by false result and NULL in overlapped.
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
    if (!ok && (overlapped == NULL)) {
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
  const intptr_t stdin_leaked = (StdHandle::StdinPtr() == NULL) ? 0 : 1;
  DEBUG_ASSERT(ReferenceCounted<Handle>::instances() ==
               ClientSocket::disconnecting() + stdin_leaked);
  DEBUG_ASSERT(ReferenceCounted<Socket>::instances() == 0);
#endif  // defined(DEBUG)
  handler->NotifyShutdownDone();
}

void EventHandlerImplementation::Start(EventHandler* handler) {
  int result =
      Thread::Start(EventHandlerEntry, reinterpret_cast<uword>(handler));
  if (result != 0) {
    FATAL1("Failed to start event handler thread %d", result);
  }

  {
    MonitorLocker ml(startup_monitor_);
    while (handler_thread_id_ == Thread::kInvalidThreadId) {
      ml.Wait();
    }
  }

  // Initialize Winsock32
  if (!SocketBase::Initialize()) {
    FATAL("Failed to initialized Windows sockets");
  }
}

void EventHandlerImplementation::Shutdown() {
  SendData(kShutdownId, 0, 0);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
