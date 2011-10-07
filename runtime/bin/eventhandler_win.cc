// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <process.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <mswsock.h>

#include "bin/builtin.h"
#include "bin/eventhandler.h"
#include "bin/socket.h"


static const int kInfinityTimeout = -1;


int64_t GetCurrentTimeMilliseconds() {
  static const int64_t kTimeEpoc = 116444736000000000LL;

  // Although win32 uses 64-bit integers for representing timestamps,
  // these are packed into a FILETIME structure. The FILETIME structure
  // is just a struct representing a 64-bit integer. The TimeStamp union
  // allows access to both a FILETIME and an integer representation of
  // the timestamp.
  union TimeStamp {
    FILETIME ft_;
    int64_t t_;
  };
  TimeStamp time;
  GetSystemTimeAsFileTime(&time.ft_);
  return (time.t_ - kTimeEpoc) / 10000;
}

IOBuffer* IOBuffer::AllocateBuffer(int buffer_size, Operation operation) {
  IOBuffer* buffer = new(buffer_size) IOBuffer(buffer_size, operation);
  return buffer;
}


IOBuffer* IOBuffer::AllocateAcceptBuffer(int buffer_size) {
  IOBuffer* buffer = AllocateBuffer(buffer_size, kAccept);
  return buffer;
}


IOBuffer* IOBuffer::AllocateReadBuffer(int buffer_size) {
  return AllocateBuffer(buffer_size, kRead);
}


IOBuffer* IOBuffer::AllocateWriteBuffer(int buffer_size) {
  return AllocateBuffer(buffer_size, kWrite);
}


void IOBuffer::DisposeBuffer(IOBuffer* buffer) {
  delete buffer;
}


IOBuffer* IOBuffer::GetFromOverlapped(OVERLAPPED* overlapped) {
  IOBuffer* buffer = CONTAINING_RECORD(overlapped, IOBuffer, overlapped_);
  return buffer;
}


int IOBuffer::Read(void* buffer, int num_bytes) {
  if (num_bytes > GetRemainingLength()) {
    num_bytes = GetRemainingLength();
  }
  memcpy(buffer, GetBufferStart() + index_, num_bytes);
  index_ += num_bytes;
  return num_bytes;
}


int IOBuffer::Write(const void* buffer, int num_bytes) {
  ASSERT(num_bytes == buflen_);
  memcpy(GetBufferStart(), buffer, num_bytes);
  data_length_ = num_bytes;
  return num_bytes;
}


int IOBuffer::GetRemainingLength() {
  ASSERT(operation_ == kRead);
  return data_length_ - index_;
}


Handle::Handle(HANDLE handle)
    : handle_(reinterpret_cast<HANDLE>(handle)),
      closing_(false),
      port_(0),
      completion_port_(INVALID_HANDLE_VALUE),
      event_handler_(NULL),
      data_ready_(NULL),
      pending_read_(NULL),
      pending_write_(NULL) {
  InitializeCriticalSection(&cs_);
}


Handle::Handle(HANDLE handle, Dart_Port port)
    : handle_(reinterpret_cast<HANDLE>(handle)),
      closing_(false),
      port_(port),
      completion_port_(INVALID_HANDLE_VALUE),
      event_handler_(NULL),
      data_ready_(NULL),
      pending_read_(NULL),
      pending_write_(NULL) {
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
  completion_port_ = CreateIoCompletionPort(handle_,
                                            completion_port,
                                            reinterpret_cast<ULONG_PTR>(this),
                                            0);
  if (completion_port_ == NULL) {
    fprintf(stderr, "Error CreateIoCompletionPort: %d\n", GetLastError());
    return false;
  }
  return true;
}


void Handle::close() {
  ScopedLock lock(this);
  if (!closing_) {
    // Close the socket and set the closing state. This close method can be
    // called again if this socket has pending IO operations in flight.
    ASSERT(handle_ != INVALID_HANDLE_VALUE);
    closing_ = true;
    // According to the documentation from Microsoft socket handles should
    // not be closed using CloseHandle but using closesocket.
    if (is_socket()) {
      closesocket(reinterpret_cast<SOCKET>(handle_));
    } else {
      CloseHandle(handle_);
    }
    handle_ = INVALID_HANDLE_VALUE;
  }

  // Perform socket type specific close handling.
  AfterClose();
}


bool Handle::HasPendingRead() {
  ScopedLock lock(this);
  return pending_read_ != NULL;
}


bool Handle::HasPendingWrite() {
  ScopedLock lock(this);
  return pending_write_ != NULL;
}


void Handle::ReadComplete(IOBuffer* buffer) {
  ScopedLock lock(this);
  // Currently only one outstanding read at the time.
  ASSERT(pending_read_ == buffer);
  ASSERT(data_ready_ == NULL);
  if (!closing_ && !buffer->IsEmpty()) {
    data_ready_ = pending_read_;
  } else {
    IOBuffer::DisposeBuffer(buffer);
  }
  pending_read_ = NULL;
}


void Handle::WriteComplete(IOBuffer* buffer) {
  ScopedLock lock(this);
  // Currently only one outstanding write at the time.
  ASSERT(pending_write_ == buffer);
  IOBuffer::DisposeBuffer(buffer);
  pending_write_ = NULL;
}


bool Handle::IssueRead() {
  ScopedLock lock(this);
  ASSERT(type_ != kListenSocket);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_read_ == NULL);

  IOBuffer* buffer = IOBuffer::AllocateReadBuffer(1024);
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

  fprintf(stderr, "ReadFile failed: %d\n", GetLastError());
  event_handler_->HandleClosed(this);
  IOBuffer::DisposeBuffer(buffer);
  return false;
}


bool Handle::IssueWrite() {
  ScopedLock lock(this);
  ASSERT(type_ != kListenSocket);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_write_ != NULL);
  ASSERT(pending_write_->operation() == IOBuffer::kWrite);

  IOBuffer* buffer = pending_write_;
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

  fprintf(stderr, "WriteFile failed: %d\n", GetLastError());
  event_handler_->HandleClosed(this);
  IOBuffer::DisposeBuffer(buffer);
  return false;
}


bool ListenSocket::LoadAcceptEx() {
  // Load the AcceptEx function into memory using WSAIoctl.
  // The WSAIoctl function is an extension of the ioctlsocket()
  // function that can use overlapped I/O. The function's 3rd
  // through 6th parameters are input and output buffers where
  // we pass the pointer to our AcceptEx function. This is used
  // so that we can call the AcceptEx function directly, rather
  // than refer to the Mswsock.lib library.
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
    fprintf(stderr, "Error WSAIoctl failed: %d\n", WSAGetLastError());
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
  IOBuffer* buffer =
      IOBuffer::AllocateAcceptBuffer(2 * kAcceptExAddressStorageSize);
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
      fprintf(stderr, "AcceptEx failed: %d\n", WSAGetLastError());
      closesocket(buffer->client());
      IOBuffer::DisposeBuffer(buffer);
      return false;
    }
  }

  pending_accept_count_++;

  return true;
}


void ListenSocket::AcceptComplete(IOBuffer* buffer, HANDLE completion_port) {
  ScopedLock lock(this);
  if (!closing_) {
    ClientSocket* client_socket = new ClientSocket(buffer->client(), 0);
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
  pending_accept_count_--;
  IOBuffer::DisposeBuffer(buffer);
}


ClientSocket* ListenSocket::Accept() {
  ScopedLock lock(this);
  if (accepted_head_ == NULL) return NULL;
  ClientSocket* result = accepted_head_;
  accepted_head_ = accepted_head_->next();
  if (accepted_head_ == NULL) accepted_tail_ = NULL;
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


void ListenSocket::AfterClose() {
  ScopedLock lock(this);
  while (true) {
    // Get rid of connections already accepted.
    ClientSocket *client = Accept();
    if (client != NULL) {
      client->close();
    } else {
      break;
    }
  }
}


bool ListenSocket::IsClosed() {
  return closing_ && !HasPendingAccept();
}


int ClientSocket::Available() {
  ScopedLock lock(this);
  if (data_ready_ == NULL) return 0;
  ASSERT(!data_ready_->IsEmpty());
  return data_ready_->GetRemainingLength();
}


int ClientSocket::Read(void* buffer, int num_bytes) {
  ScopedLock lock(this);
  if (data_ready_ == NULL) return 0;
  num_bytes = data_ready_->Read(buffer, num_bytes);
  if (data_ready_->IsEmpty()) {
    IOBuffer::DisposeBuffer(data_ready_);
    data_ready_ = NULL;
  }
  return num_bytes;
}


int ClientSocket::Write(const void* buffer, int num_bytes) {
  ScopedLock lock(this);
  if (pending_write_ != NULL) return 0;
  if (completion_port_ == INVALID_HANDLE_VALUE) return 0;
  if (num_bytes > 4096) num_bytes = 4096;
  pending_write_ = IOBuffer::AllocateWriteBuffer(num_bytes);
  pending_write_->Write(buffer, num_bytes);
  IssueWrite();
  return num_bytes;
}


bool ClientSocket::IssueRead() {
  ScopedLock lock(this);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_read_ == NULL);

  IOBuffer* buffer = IOBuffer::AllocateReadBuffer(1024);

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

  if (WSAGetLastError() != WSAECONNRESET) {
    fprintf(stderr, "WSARecv failed: %d\n", WSAGetLastError());
  }
  event_handler_->HandleClosed(this);
  IOBuffer::DisposeBuffer(buffer);
  return false;
}


bool ClientSocket::IssueWrite() {
  ScopedLock lock(this);
  ASSERT(completion_port_ != INVALID_HANDLE_VALUE);
  ASSERT(pending_write_ != NULL);
  ASSERT(pending_write_->operation() == IOBuffer::kWrite);

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

  fprintf(stderr, "WSASend failed: %d\n", WSAGetLastError());
  IOBuffer::DisposeBuffer(pending_write_);
  pending_write_ = NULL;
  return false;
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


void ClientSocket::AfterClose() {
  ScopedLock lock(this);
  if (data_ready_ != NULL) {
    IOBuffer::DisposeBuffer(data_ready_);
    data_ready_ = NULL;
  }
}


bool ClientSocket::IsClosed() {
  return closing_ && !HasPendingRead() && !HasPendingWrite();
}


void EventHandlerImplementation::HandleInterrupt(InterruptMessage* msg) {
  if (msg->id == -1) {
    // Change of timeout request. Just set the new timeout and port as the
    // completion thread will use the new timeout value for its next wait.
    timeout_ = msg->data;
    timeout_port_ = msg->dart_port;
  } else {
    bool delete_socket = false;
    Handle* socket_desc =
        reinterpret_cast<Handle*>(msg->id);
    ASSERT(socket_desc != NULL);
    if (socket_desc->is_listen_socket()) {
      ListenSocket* listen_socket =
          reinterpret_cast<ListenSocket*>(socket_desc);
      listen_socket->EnsureInitialized(this);
      listen_socket->SetPortAndMask(msg->dart_port, msg->data);

      Handle::ScopedLock lock(listen_socket);

      // If incomming connections are requested make sure that pending accepts
      // are issued.
      if ((msg->data & (1 << kInEvent)) != 0) {
        while (listen_socket->pending_accept_count() < 5) {
          listen_socket->IssueAccept();
        }
      }

      if ((msg->data & (1 << kCloseCommand)) != 0) {
        listen_socket->close();
        if (listen_socket->IsClosed()) {
          delete_socket = true;
        }
      }
    } else {
      ClientSocket* client_socket =
          reinterpret_cast<ClientSocket*>(socket_desc);
      client_socket->SetPortAndMask(msg->dart_port, msg->data);
      client_socket->EnsureInitialized(this);

      Handle::ScopedLock lock(client_socket);

      // If data available callback has been requested and data are
      // available post it immediately. Otherwise make sure that a pending
      // read is issued.
      if ((msg->data & (1 << kInEvent)) != 0) {
        if (client_socket->Available() > 0) {
          int event_mask = (1 << kInEvent);
          Dart_PostIntArray(client_socket->port(), 1, &event_mask);
        } else if (!client_socket->HasPendingRead()) {
          client_socket->IssueRead();
        }
      }

      // If can send callback had been requested and there is no pending
      // send post it immediately.
      if ((msg->data & (1 << kOutEvent)) != 0) {
        if (!client_socket->HasPendingWrite()) {
          int event_mask = (1 << kOutEvent);
          Dart_PostIntArray(client_socket->port(), 1, &event_mask);
        }
      }

      if ((msg->data & (1 << kCloseCommand)) != 0) {
        client_socket->close();
        if (client_socket->IsClosed()) {
          delete_socket = true;
        }
      }
    }
    if (delete_socket) {
      delete socket_desc;
    }
  }
}


void EventHandlerImplementation::HandleAccept(ListenSocket* listen_socket,
                                              IOBuffer* buffer) {
  listen_socket->AcceptComplete(buffer, completion_port_);

  if (!listen_socket->is_closing()) {
    int event_mask = 1 << kInEvent;
    if ((listen_socket->mask() & event_mask) != 0) {
      Dart_PostIntArray(listen_socket->port(), 1, &event_mask);
    }
  }

  if (listen_socket->IsClosed()) {
    delete listen_socket;
  }
}


void EventHandlerImplementation::HandleClosed(Handle* handle) {
  if (!handle->is_closing()) {
    int event_mask = 1 << kCloseEvent;
    if ((handle->mask() & event_mask) != 0) {
      Dart_PostIntArray(handle->port(), 1, &event_mask);
    }
  }
}


void EventHandlerImplementation::HandleRead(ClientSocket* client_socket,
                                            int bytes,
                                            IOBuffer* buffer) {
  buffer->set_data_length(bytes);
  client_socket->ReadComplete(buffer);

  if (bytes > 0) {
    if (!client_socket->is_closing()) {
      int event_mask = 1 << kInEvent;
      if ((client_socket->mask() & event_mask) != 0) {
        Dart_PostIntArray(client_socket->port(), 1, &event_mask);
      }
    }
  } else {
    ASSERT(bytes == 0);
    HandleClosed(client_socket);
  }

  if (client_socket->IsClosed()) {
    delete client_socket;
  }
}


void EventHandlerImplementation::HandleWrite(ClientSocket* client_socket,
                                             int bytes,
                                             IOBuffer* buffer) {
  client_socket->WriteComplete(buffer);

  if (bytes > 0) {
    if (!client_socket->is_closing()) {
      int event_mask = 1 << kOutEvent;
      if ((client_socket->mask() & event_mask) != 0) {
        Dart_PostIntArray(client_socket->port(), 1, &event_mask);
      }
    }
  } else {
    ASSERT(bytes == 0);
    HandleClosed(client_socket);
  }

  if (client_socket->IsClosed()) {
    delete client_socket;
  }
}


void EventHandlerImplementation::HandleTimeout() {
  // TODO(sgjesse) check if there actually is a timeout.
  Dart_PostIntArray(timeout_port_, 0, NULL);
  timeout_ = kInfinityTimeout;
  timeout_port_ = 0;
}


void EventHandlerImplementation::HandleIOCompletion(DWORD bytes,
                                                    ULONG_PTR key,
                                                    OVERLAPPED* overlapped) {
  IOBuffer* buffer = IOBuffer::GetFromOverlapped(overlapped);
  switch (buffer->operation()) {
    case IOBuffer::kAccept: {
      ListenSocket* listen_socket = reinterpret_cast<ListenSocket*>(key);
      HandleAccept(listen_socket, buffer);
      break;
    }
    case IOBuffer::kRead: {
      ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(key);
      HandleRead(client_socket, bytes, buffer);
      break;
    }
    case IOBuffer::kWrite: {
      ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(key);
      HandleWrite(client_socket, bytes, buffer);
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
  timeout_ = kInfinityTimeout;
  timeout_port_ = 0;
}


DWORD EventHandlerImplementation::GetTimeout() {
  if (timeout_ == kInfinityTimeout) {
    return kInfinityTimeout;
  }
  intptr_t millis = timeout_ - GetCurrentTimeMilliseconds();
  return (millis < 0) ? 0 : millis;
}


void EventHandlerImplementation::SendData(intptr_t id,
                                          Dart_Port dart_port,
                                          intptr_t data) {
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


static unsigned int __stdcall EventHandlerThread(void* args) {
  EventHandlerImplementation* handler =
      reinterpret_cast<EventHandlerImplementation*>(args);
  while (true) {
    DWORD bytes;
    ULONG_PTR key;
    OVERLAPPED* overlapped;
    intptr_t millis = handler->GetTimeout();
    BOOL ok = GetQueuedCompletionStatus(handler->completion_port(),
                                        &bytes,
                                        &key,
                                        &overlapped,
                                        millis);
    if (!ok && overlapped == NULL) {
      if (GetLastError() == ERROR_ABANDONED_WAIT_0) {
        // The completion port should never be closed.
        printf("Completion port closed\n");
        UNREACHABLE();
      } else {
        // Timeout is signalled by false result and NULL in overlapped.
        handler->HandleTimeout();
      }
    } else if (!ok) {
      // If GetQueuedCompletionStatus return false and overlapped is
      // not NULL then it did dequeue a request which failed.

      // Treat ERROR_CONNECTION_ABORTED as connection closed.
      // The error ERROR_OPERATION_ABORTED is set for pending
      // accept requests for a listen socket which is closed.
      // ERROR_NETNAME_DELETED occurs when the client closes
      // the socket it is reading from.
      DWORD last_error = GetLastError();
      if (last_error == ERROR_CONNECTION_ABORTED ||
          last_error == ERROR_OPERATION_ABORTED ||
          last_error == ERROR_NETNAME_DELETED) {
        ASSERT(bytes == 0);
        handler->HandleIOCompletion(bytes, key, overlapped);
      } else {
        printf("After GetQueuedCompletionStatus %d\n", GetLastError());
        UNREACHABLE();
     }
    } else if (key == NULL) {
      // A key of NULL signals an interrupt message.
      InterruptMessage* msg = reinterpret_cast<InterruptMessage*>(overlapped);
      handler->HandleInterrupt(msg);
      delete msg;
    } else {
      handler->HandleIOCompletion(bytes, key, overlapped);
    }
  }
}


void EventHandlerImplementation::StartEventHandler() {
  uint32_t tid;
  uintptr_t thread_handle =
      _beginthreadex(NULL, 32 * 1024, EventHandlerThread, this, 0, &tid);
  if (thread_handle == -1) {
    FATAL("Failed to start event handler thread");
  }

  // Initialize Winsock32
  if (!Socket::Initialize()) {
    FATAL("Failed to initialized Windows sockets");
  }
}
