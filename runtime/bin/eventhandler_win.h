// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_EVENTHANDLER_WIN_H_
#define RUNTIME_BIN_EVENTHANDLER_WIN_H_

#if !defined(RUNTIME_BIN_EVENTHANDLER_H_)
#error Do not include eventhandler_win.h directly; use eventhandler.h instead.
#endif

#include <mswsock.h>
#include <winsock2.h>
#include <ws2tcpip.h>

#include "bin/builtin.h"
#include "bin/reference_counting.h"
#include "bin/thread.h"

namespace dart {
namespace bin {

// Forward declarations.
class EventHandlerImplementation;
class Handle;
class FileHandle;
class SocketHandle;
class ClientSocket;
class ListenSocket;

// An OverlappedBuffer encapsulates the OVERLAPPED structure and the
// associated data buffer. For accept it also contains the pre-created
// socket for the client.
class OverlappedBuffer {
 public:
  enum Operation {
    kAccept,
    kRead,
    kRecvFrom,
    kWrite,
    kSendTo,
    kDisconnect,
    kConnect
  };

  static OverlappedBuffer* AllocateAcceptBuffer(int buffer_size);
  static OverlappedBuffer* AllocateReadBuffer(int buffer_size);
  static OverlappedBuffer* AllocateRecvFromBuffer(int buffer_size);
  static OverlappedBuffer* AllocateWriteBuffer(int buffer_size);
  static OverlappedBuffer* AllocateSendToBuffer(int buffer_size);
  static OverlappedBuffer* AllocateDisconnectBuffer();
  static OverlappedBuffer* AllocateConnectBuffer();
  static void DisposeBuffer(OverlappedBuffer* buffer);

  // Find the IO buffer from the OVERLAPPED address.
  static OverlappedBuffer* GetFromOverlapped(OVERLAPPED* overlapped);

  // Read data from a buffer which has been received. It will read up
  // to num_bytes bytes of data returning the actual number of bytes
  // read. This will update the index of the next byte in the buffer
  // so calling Read several times will keep returning new data from
  // the buffer until all data have been read.
  int Read(void* buffer, int num_bytes);

  // Write data to a buffer before sending it. Returns the number of bytes
  // actually written to the buffer. Calls to Write will always write to
  // the buffer from the beginning.
  int Write(const void* buffer, int num_bytes);

  // Check the amount of data in a read buffer which has not been read yet.
  int GetRemainingLength();
  bool IsEmpty() { return GetRemainingLength() == 0; }

  Operation operation() const { return operation_; }
  SOCKET client() const { return client_; }
  char* GetBufferStart() { return reinterpret_cast<char*>(&buffer_data_); }
  int GetBufferSize() const { return buflen_; }
  struct sockaddr* from() const {
    return from_;
  }
  socklen_t* from_len_addr() const { return from_len_addr_; }
  socklen_t from_len() const { return from_ == NULL ? 0 : *from_len_addr_; }

  // Returns the address of the OVERLAPPED structure with all fields
  // initialized to zero.
  OVERLAPPED* GetCleanOverlapped() {
    memset(&overlapped_, 0, sizeof(overlapped_));
    return &overlapped_;
  }

  // Returns a WASBUF structure initialized with the data in this IO buffer.
  WSABUF* GetWASBUF() {
    wbuf_.buf = GetBufferStart();
    wbuf_.len = GetBufferSize();
    return &wbuf_;
  }

  void set_data_length(int data_length) { data_length_ = data_length; }

 private:
  OverlappedBuffer(int buffer_size, Operation operation)
      : operation_(operation), buflen_(buffer_size) {
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
      from_len_addr_ = NULL;
      from_ = NULL;
    }
    index_ = 0;
    data_length_ = 0;
    if (operation_ == kAccept) {
      client_ = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    }
  }

  void* operator new(size_t size, int buffer_size) {
    return malloc(size + buffer_size);
  }

  void operator delete(void* buffer) { free(buffer); }

  // Allocate an overlapped buffer for thse specified amount of data and
  // operation. Some operations need additional buffer space, which is
  // handled by this method.
  static OverlappedBuffer* AllocateBuffer(int buffer_size, Operation operation);

  OVERLAPPED overlapped_;  // OVERLAPPED structure for overlapped IO.
  SOCKET client_;          // Used for AcceptEx client socket.
  int buflen_;             // Length of the buffer.
  Operation operation_;    // Type of operation issued.

  int index_;        // Index for next read from read buffer.
  int data_length_;  // Length of the actual data in the buffer.

  WSABUF wbuf_;  // Structure for passing buffer to WSA functions.

  // For the recvfrom operation additional storace is allocated for the
  // source sockaddr.
  socklen_t* from_len_addr_;  // Pointer to source sockaddr size storage.
  struct sockaddr* from_;     // Pointer to source sockaddr storage.

  // Buffer for recv/send/AcceptEx. This must be at the end of the
  // object as the object is allocated larger than it's definition
  // indicate to extend this array.
  uint8_t buffer_data_[1];

  DISALLOW_COPY_AND_ASSIGN(OverlappedBuffer);
};

// Abstract super class for holding information on listen and connected
// sockets.
class Handle : public ReferenceCounted<Handle>, public DescriptorInfoBase {
 public:
  enum Type {
    kFile,
    kStd,
    kDirectoryWatch,
    kClientSocket,
    kListenSocket,
    kDatagramSocket
  };

  // Socket interface exposing normal socket operations.
  intptr_t Available();
  intptr_t Read(void* buffer, intptr_t num_bytes);
  intptr_t RecvFrom(void* buffer,
                    intptr_t num_bytes,
                    struct sockaddr* sa,
                    socklen_t addr_len);
  virtual intptr_t Write(const void* buffer, intptr_t num_bytes);
  virtual intptr_t SendTo(const void* buffer,
                          intptr_t num_bytes,
                          struct sockaddr* sa,
                          socklen_t sa_len);

  // Internal interface used by the event handler.
  virtual bool IssueRead();
  virtual bool IssueRecvFrom();
  virtual bool IssueWrite();
  virtual bool IssueSendTo(struct sockaddr* sa, socklen_t sa_len);
  bool HasPendingRead();
  bool HasPendingWrite();
  void ReadComplete(OverlappedBuffer* buffer);
  void RecvFromComplete(OverlappedBuffer* buffer);
  void WriteComplete(OverlappedBuffer* buffer);

  bool IsClosing() { return (flags_ & (1 << kClosing)) != 0; }
  bool IsClosedRead() { return (flags_ & (1 << kCloseRead)) != 0; }
  bool IsClosedWrite() { return (flags_ & (1 << kCloseWrite)) != 0; }
  bool IsError() { return (flags_ & (1 << kError)) != 0; }
  void MarkClosing() { flags_ |= (1 << kClosing); }
  void MarkClosedRead() { flags_ |= (1 << kCloseRead); }
  void MarkClosedWrite() { flags_ |= (1 << kCloseWrite); }
  void MarkError() { flags_ |= (1 << kError); }

  virtual void EnsureInitialized(EventHandlerImplementation* event_handler) = 0;

  HANDLE handle() { return handle_; }

  bool CreateCompletionPort(HANDLE completion_port);

  void Close();
  virtual void DoClose();
  virtual bool IsClosed() = 0;

  bool IsHandleClosed() const { return handle_ == INVALID_HANDLE_VALUE; }

  Type type() { return type_; }
  bool is_file() { return type_ == kFile; }
  bool is_socket() {
    return type_ == kListenSocket || type_ == kClientSocket ||
           type_ == kDatagramSocket;
  }
  bool is_listen_socket() { return type_ == kListenSocket; }
  bool is_client_socket() { return type_ == kClientSocket; }
  bool is_datagram_socket() { return type_ == kDatagramSocket; }

  void MarkDoesNotSupportOverlappedIO() {
    flags_ |= (1 << kDoesNotSupportOverlappedIO);
  }
  bool SupportsOverlappedIO() {
    return (flags_ & (1 << kDoesNotSupportOverlappedIO)) == 0;
  }

  void ReadSyncCompleteAsync();

  DWORD last_error() { return last_error_; }
  void set_last_error(DWORD last_error) { last_error_ = last_error; }

  void set_completion_port(HANDLE completion_port) {
    completion_port_ = completion_port;
  }

  void set_event_handler(EventHandlerImplementation* event_handler) {
    event_handler_ = event_handler;
  }

 protected:
  // For access to monitor_;
  friend class EventHandlerImplementation;

  enum Flags {
    kClosing = 0,
    kCloseRead = 1,
    kCloseWrite = 2,
    kDoesNotSupportOverlappedIO = 3,
    kError = 4
  };

  explicit Handle(intptr_t handle);
  virtual ~Handle();

  virtual void HandleIssueError();

  Monitor* monitor_;
  Type type_;
  HANDLE handle_;
  HANDLE completion_port_;
  EventHandlerImplementation* event_handler_;

  OverlappedBuffer* data_ready_;     // Buffer for data ready to be read.
  OverlappedBuffer* pending_read_;   // Buffer for pending read.
  OverlappedBuffer* pending_write_;  // Buffer for pending write

  DWORD last_error_;

  ThreadId read_thread_id_;
  HANDLE read_thread_handle_;
  bool read_thread_starting_;
  bool read_thread_finished_;

 private:
  void WaitForReadThreadStarted();
  void NotifyReadThreadStarted();
  void WaitForReadThreadFinished();
  void NotifyReadThreadFinished();

  int flags_;

  friend class ReferenceCounted<Handle>;
  DISALLOW_COPY_AND_ASSIGN(Handle);
};


class FileHandle : public DescriptorInfoSingleMixin<Handle> {
 public:
  explicit FileHandle(HANDLE handle)
      : DescriptorInfoSingleMixin(reinterpret_cast<intptr_t>(handle), true) {
    type_ = kFile;
  }

  virtual void EnsureInitialized(EventHandlerImplementation* event_handler);
  virtual bool IsClosed();

 private:
  DISALLOW_COPY_AND_ASSIGN(FileHandle);
};


class StdHandle : public FileHandle {
 public:
  static StdHandle* Stdin(HANDLE handle);

  virtual void DoClose();
  virtual intptr_t Write(const void* buffer, intptr_t num_bytes);

  void WriteSyncCompleteAsync();
  void RunWriteLoop();

#if defined(DEBUG)
  static StdHandle* StdinPtr() { return stdin_; }
#endif

 private:
  static Mutex* stdin_mutex_;
  static StdHandle* stdin_;

  explicit StdHandle(HANDLE handle)
      : FileHandle(handle),
        thread_id_(Thread::kInvalidThreadId),
        thread_handle_(NULL),
        thread_wrote_(0),
        write_thread_exists_(false),
        write_thread_running_(false) {
    type_ = kStd;
  }

  ThreadId thread_id_;
  HANDLE thread_handle_;
  intptr_t thread_wrote_;
  bool write_thread_exists_;
  bool write_thread_running_;

  DISALLOW_COPY_AND_ASSIGN(StdHandle);
};


class DirectoryWatchHandle : public DescriptorInfoSingleMixin<Handle> {
 public:
  DirectoryWatchHandle(HANDLE handle, int events, bool recursive)
      : DescriptorInfoSingleMixin(reinterpret_cast<intptr_t>(handle), true),
        events_(events),
        recursive_(recursive) {
    type_ = kDirectoryWatch;
  }

  virtual void EnsureInitialized(EventHandlerImplementation* event_handler);
  virtual bool IsClosed();

  virtual bool IssueRead();

  void Stop();

 private:
  int events_;
  bool recursive_;

  DISALLOW_COPY_AND_ASSIGN(DirectoryWatchHandle);
};


class SocketHandle : public Handle {
 public:
  SOCKET socket() const { return socket_; }

 protected:
  explicit SocketHandle(intptr_t s) : Handle(s), socket_(s) {}

  virtual void HandleIssueError();

 private:
  const SOCKET socket_;

  DISALLOW_COPY_AND_ASSIGN(SocketHandle);
};


// Information on listen sockets.
class ListenSocket : public DescriptorInfoMultipleMixin<SocketHandle> {
 public:
  explicit ListenSocket(intptr_t s)
      : DescriptorInfoMultipleMixin(s, true),
        AcceptEx_(NULL),
        pending_accept_count_(0),
        accepted_head_(NULL),
        accepted_tail_(NULL),
        accepted_count_(0) {
    type_ = kListenSocket;
  }
  virtual ~ListenSocket() {
    ASSERT(!HasPendingAccept());
    ASSERT(accepted_head_ == NULL);
    ASSERT(accepted_tail_ == NULL);
  }

  // Socket interface exposing normal socket operations.
  ClientSocket* Accept();
  bool CanAccept();

  // Internal interface used by the event handler.
  bool HasPendingAccept() { return pending_accept_count_ > 0; }
  bool IssueAccept();
  void AcceptComplete(OverlappedBuffer* buffer, HANDLE completion_port);

  virtual void EnsureInitialized(EventHandlerImplementation* event_handler);
  virtual void DoClose();
  virtual bool IsClosed();

  int pending_accept_count() { return pending_accept_count_; }

  int accepted_count() { return accepted_count_; }

 private:
  bool LoadAcceptEx();

  LPFN_ACCEPTEX AcceptEx_;

  // The number of asynchronous `IssueAccept` operations which haven't completed
  // yet.
  int pending_accept_count_;

  // Linked list of accepted connections provided by completion code. Ready to
  // be handed over through accept.
  ClientSocket* accepted_head_;
  ClientSocket* accepted_tail_;

  // The number of accepted connections which are waiting to be removed from
  // this queue and processed by dart isolates.
  int accepted_count_;

  DISALLOW_COPY_AND_ASSIGN(ListenSocket);
};


// Information on connected sockets.
class ClientSocket : public DescriptorInfoSingleMixin<SocketHandle> {
 public:
  explicit ClientSocket(intptr_t s)
      : DescriptorInfoSingleMixin(s, true),
        DisconnectEx_(NULL),
        next_(NULL),
        connected_(false),
        closed_(false) {
    LoadDisconnectEx();
    type_ = kClientSocket;
  }

  virtual ~ClientSocket() {
    // Don't delete this object until all pending requests have been handled.
    ASSERT(!HasPendingRead());
    ASSERT(!HasPendingWrite());
    ASSERT(next_ == NULL);
    ASSERT(closed_ == true);
  }

  void Shutdown(int how);

  // Internal interface used by the event handler.
  virtual bool IssueRead();
  virtual bool IssueWrite();
  void IssueDisconnect();
  void DisconnectComplete(OverlappedBuffer* buffer);

  void ConnectComplete(OverlappedBuffer* buffer);

  virtual void EnsureInitialized(EventHandlerImplementation* event_handler);
  virtual void DoClose();
  virtual bool IsClosed();

  ClientSocket* next() { return next_; }
  void set_next(ClientSocket* next) { next_ = next; }

  void mark_connected() { connected_ = true; }
  bool is_connected() const { return connected_; }

  void mark_closed() { closed_ = true; }

#if defined(DEBUG)
  static intptr_t disconnecting() { return disconnecting_; }
#endif

 private:
  bool LoadDisconnectEx();

  LPFN_DISCONNECTEX DisconnectEx_;
  ClientSocket* next_;
  bool connected_;
  bool closed_;

#if defined(DEBUG)
  static intptr_t disconnecting_;
#endif

  DISALLOW_COPY_AND_ASSIGN(ClientSocket);
};


class DatagramSocket : public DescriptorInfoSingleMixin<SocketHandle> {
 public:
  explicit DatagramSocket(intptr_t s) : DescriptorInfoSingleMixin(s, true) {
    type_ = kDatagramSocket;
  }

  virtual ~DatagramSocket() {
    // Don't delete this object until all pending requests have been handled.
    ASSERT(!HasPendingRead());
    ASSERT(!HasPendingWrite());
  }

  // Internal interface used by the event handler.
  virtual bool IssueRecvFrom();
  virtual bool IssueSendTo(sockaddr* sa, socklen_t sa_len);

  virtual void EnsureInitialized(EventHandlerImplementation* event_handler);
  virtual void DoClose();
  virtual bool IsClosed();

 private:
  DISALLOW_COPY_AND_ASSIGN(DatagramSocket);
};


// Event handler.
class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  virtual ~EventHandlerImplementation();

  void SendData(intptr_t id, Dart_Port dart_port, int64_t data);
  void Start(EventHandler* handler);
  void Shutdown();

  static void EventHandlerEntry(uword args);

  int64_t GetTimeout();
  void HandleInterrupt(InterruptMessage* msg);
  void HandleTimeout();
  void HandleAccept(ListenSocket* listen_socket, OverlappedBuffer* buffer);
  void TryDispatchingPendingAccepts(ListenSocket* listen_socket);
  void HandleRead(Handle* handle, int bytes, OverlappedBuffer* buffer);
  void HandleRecvFrom(Handle* handle, int bytes, OverlappedBuffer* buffer);
  void HandleWrite(Handle* handle, int bytes, OverlappedBuffer* buffer);
  void HandleDisconnect(ClientSocket* client_socket,
                        int bytes,
                        OverlappedBuffer* buffer);
  void HandleConnect(ClientSocket* client_socket,
                     int bytes,
                     OverlappedBuffer* buffer);
  void HandleIOCompletion(DWORD bytes, ULONG_PTR key, OVERLAPPED* overlapped);

  void HandleCompletionOrInterrupt(BOOL ok,
                                   DWORD bytes,
                                   ULONG_PTR key,
                                   OVERLAPPED* overlapped);

  HANDLE completion_port() { return completion_port_; }

 private:
  Monitor* startup_monitor_;
  ThreadId handler_thread_id_;
  HANDLE handler_thread_handle_;

  TimeoutQueue timeout_queue_;  // Time for next timeout.
  bool shutdown_;
  HANDLE completion_port_;

  DISALLOW_COPY_AND_ASSIGN(EventHandlerImplementation);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_EVENTHANDLER_WIN_H_
