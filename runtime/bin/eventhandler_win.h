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
#include <memory>
#include <utility>

#include "bin/builtin.h"
#include "bin/lockers.h"
#include "bin/reference_counting.h"
#include "bin/socket_base.h"
#include "bin/thread.h"

namespace dart {
namespace bin {

// Forward declarations.
class ClientSocket;
class EventHandlerImplementation;
class FileHandle;
class Handle;
class ListenSocket;
class SocketHandle;

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

  static std::unique_ptr<OverlappedBuffer> AllocateAcceptBuffer(Handle* handle);
  static std::unique_ptr<OverlappedBuffer> AllocateReadBuffer(Handle* handle,
                                                              int buffer_size);
  static std::unique_ptr<OverlappedBuffer> AllocateRecvFromBuffer(
      Handle* handle,
      int buffer_size);
  static std::unique_ptr<OverlappedBuffer> AllocateWriteBuffer(Handle* handle,
                                                               int buffer_size);
  static std::unique_ptr<OverlappedBuffer> AllocateSendToBuffer(
      Handle* handle,
      int buffer_size);
  static std::unique_ptr<OverlappedBuffer> AllocateDisconnectBuffer(
      Handle* handle);
  static std::unique_ptr<OverlappedBuffer> AllocateConnectBuffer(
      Handle* handle);

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
  struct sockaddr* from() const { return from_; }
  socklen_t* from_len_addr() const { return from_len_addr_; }
  socklen_t from_len() const { return from_ == nullptr ? 0 : *from_len_addr_; }

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

  void operator delete(void* buffer) { free(buffer); }

  Handle* StealHandle() {
    auto handle = handle_;
    handle_ = nullptr;
    return handle;
  }
  void DetachClient() { client_ = INVALID_SOCKET; }

  ~OverlappedBuffer();

 private:
  OverlappedBuffer(Handle* handle, int buffer_size, Operation operation);

  void* operator new(size_t size, int buffer_size) {
    return malloc(size + buffer_size);
  }

  // Allocate an overlapped buffer for thse specified amount of data and
  // operation. Some operations need additional buffer space, which is
  // handled by this method.
  static std::unique_ptr<OverlappedBuffer> AllocateBuffer(Handle* handle,
                                                          int buffer_size,
                                                          Operation operation);

  OVERLAPPED overlapped_;           // OVERLAPPED structure for overlapped IO.
  SOCKET client_ = INVALID_SOCKET;  // Used for AcceptEx client socket.
  int buflen_;                      // Length of the buffer.
  Operation operation_;             // Type of operation issued.
  Handle* handle_ = nullptr;

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

  enum class SupportsOverlappedIO { kYes, kNo };

  // Socket interface exposing normal socket operations.
  intptr_t Available();
  bool DataReady();
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
  virtual bool IssueReadLocked(MonitorLocker* ml);
  virtual bool IssueRecvFromLocked(MonitorLocker* ml);
  bool HasPendingRead();
  bool HasPendingWrite();
  void ReadComplete(std::unique_ptr<OverlappedBuffer> buffer);
  void WriteComplete(std::unique_ptr<OverlappedBuffer> buffer);

  bool IsClosing() { return (flags_ & (1 << kClosing)) != 0; }
  bool IsClosedRead() { return (flags_ & (1 << kCloseRead)) != 0; }
  bool IsClosedWrite() { return (flags_ & (1 << kCloseWrite)) != 0; }
  bool IsError() { return (flags_ & (1 << kError)) != 0; }
  void MarkClosing() { flags_ |= (1 << kClosing); }
  void MarkClosedRead() { flags_ |= (1 << kCloseRead); }
  void MarkClosedWrite() { flags_ |= (1 << kCloseWrite); }
  void MarkError() { flags_ |= (1 << kError); }

  HANDLE handle() { return handle_; }

  void Close();
  void CloseLocked(MonitorLocker* ml);

  virtual void DoCloseLocked(MonitorLocker* ml);
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

  bool supports_overlapped_io() {
    return (flags_ & (1 << kDoesNotSupportOverlappedIO)) == 0;
  }

  void ReadSyncCompleteAsync();

  DWORD last_error() { return last_error_; }
  void set_last_error(DWORD last_error) { last_error_ = last_error; }

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

  Handle(intptr_t handle,
         Type type_,
         SupportsOverlappedIO supports_overlapped_io);
  virtual ~Handle();

  virtual void HandleIssueError();

  Monitor monitor_;
  const Type type_;
  HANDLE handle_;

  std::unique_ptr<OverlappedBuffer>
      data_ready_;  // Buffer for data ready to be read.
  OverlappedBuffer* pending_read_ = nullptr;   // Buffer for pending read.
  OverlappedBuffer* pending_write_ = nullptr;  // Buffer for pending write

  DWORD last_error_ = NOERROR;

  HANDLE read_thread_ = INVALID_HANDLE_VALUE;
  bool read_thread_starting_ = false;
  bool read_thread_finished_ = false;

 private:
  void WaitForReadThreadStarted();
  void NotifyReadThreadStarted();
  void WaitForReadThreadFinished();
  void NotifyReadThreadFinished();

  virtual bool IssueWriteLocked(MonitorLocker* ml,
                                std::unique_ptr<OverlappedBuffer> buffer);
  virtual bool IssueSendToLocked(MonitorLocker* ml,
                                 std::unique_ptr<OverlappedBuffer> buffer,
                                 struct sockaddr* sa,
                                 socklen_t sa_len);

  int flags_ = 0;

  friend class ReferenceCounted<Handle>;
  DISALLOW_COPY_AND_ASSIGN(Handle);
};

class FileHandle : public DescriptorInfoSingleMixin<Handle> {
 public:
  explicit FileHandle(HANDLE handle)
      : DescriptorInfoSingleMixin(reinterpret_cast<intptr_t>(handle),
                                  kFile,
                                  SupportsOverlappedIO::kYes) {}

  virtual bool IsClosed();

 protected:
  FileHandle(HANDLE handle,
             Type type,
             SupportsOverlappedIO supports_overlapped_io)
      : DescriptorInfoSingleMixin(reinterpret_cast<intptr_t>(handle),
                                  type,
                                  supports_overlapped_io) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(FileHandle);
};

class StdHandle : public FileHandle {
 public:
  static StdHandle* Stdin(HANDLE handle);

  virtual void DoCloseLocked(MonitorLocker* ml);
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
      : FileHandle(handle, kStd, SupportsOverlappedIO::kNo) {}

  HANDLE thread_handle_ = INVALID_HANDLE_VALUE;
  intptr_t thread_wrote_ = 0;
  bool write_thread_exists_ = false;
  bool write_thread_running_ = false;

  DISALLOW_COPY_AND_ASSIGN(StdHandle);
};

class DirectoryWatchHandle : public DescriptorInfoSingleMixin<Handle> {
 public:
  DirectoryWatchHandle(HANDLE handle, int events, bool recursive)
      : DescriptorInfoSingleMixin(reinterpret_cast<intptr_t>(handle),
                                  kDirectoryWatch,
                                  SupportsOverlappedIO::kYes),
        events_(events),
        recursive_(recursive) {}

  virtual bool IsClosed();

  virtual bool IssueReadLocked(MonitorLocker* ml);

  void Start();
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
  explicit SocketHandle(intptr_t s, Type type)
      : Handle(s, type, SupportsOverlappedIO::kYes), socket_(s) {}

  virtual void HandleIssueError();

 private:
  const SOCKET socket_;

  DISALLOW_COPY_AND_ASSIGN(SocketHandle);
};

// Information on listen sockets.
class ListenSocket : public DescriptorInfoMultipleMixin<SocketHandle> {
 public:
  explicit ListenSocket(intptr_t s)
      : DescriptorInfoMultipleMixin(s, kListenSocket),
        pending_accept_count_(0),
        accepted_head_(nullptr),
        accepted_tail_(nullptr),
        accepted_count_(0) {}
  virtual ~ListenSocket() {
    ASSERT(!HasPendingAccept());
    ASSERT(accepted_head_ == nullptr);
    ASSERT(accepted_tail_ == nullptr);
  }

  // Socket interface exposing normal socket operations.
  ClientSocket* Accept();
  bool StartAccept();

  // Internal interface used by the event handler.
  bool HasPendingAccept() { return pending_accept_count_ > 0; }
  void AcceptComplete(std::unique_ptr<OverlappedBuffer> buffer);

  virtual void DoCloseLocked(MonitorLocker* ml);
  virtual bool IsClosed();

  int pending_accept_count() { return pending_accept_count_; }

  int accepted_count() { return accepted_count_; }

  void DispatchCompletedAcceptsLocked(MonitorLocker* ml);

 private:
  static constexpr intptr_t kMinIssuedAccepts = 5;

  bool IssueAcceptLocked(MonitorLocker* ml);

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
  explicit ClientSocket(intptr_t s,
                        std::unique_ptr<RawAddr> remote_addr = nullptr)
      : DescriptorInfoSingleMixin(s, kClientSocket),
        next_(nullptr),
        connected_(false),
        closed_(false),
        remote_addr_(std::move(remote_addr)) {}

  virtual ~ClientSocket() {
    // Don't delete this object until all pending requests have been handled.
    ASSERT(!HasPendingRead());
    ASSERT(!HasPendingWrite());
    ASSERT(next_ == nullptr);
    ASSERT(closed_ == true);
  }

  void Shutdown(int how);

  // Internal interface used by the event handler.
  virtual bool IssueReadLocked(MonitorLocker* ml);
  void IssueDisconnectLocked(MonitorLocker* ml);
  void DisconnectComplete();
  void ConnectComplete();

  virtual void DoCloseLocked(MonitorLocker* ml);
  virtual bool IsClosed();

  // If `ClientSocket` was constructed with a `remote_addr`, populate `addr`
  // with that value and return `true`. Otherwise leave `addr` untouched and
  // return `false`.
  bool PopulateRemoteAddr(RawAddr& addr);

  ClientSocket* next() { return next_; }
  void set_next(ClientSocket* next) { next_ = next; }

  void mark_connected() { connected_ = true; }
  bool is_connected() const { return connected_; }

  void mark_closed() { closed_ = true; }

#if defined(DEBUG)
  static intptr_t disconnecting() { return disconnecting_; }
#endif

 private:
  virtual bool IssueWriteLocked(MonitorLocker* ml,
                                std::unique_ptr<OverlappedBuffer> buffer);

  ClientSocket* next_;
  bool connected_;
  bool closed_;
  std::unique_ptr<RawAddr> remote_addr_;

#if defined(DEBUG)
  static intptr_t disconnecting_;
#endif

  DISALLOW_COPY_AND_ASSIGN(ClientSocket);
};

class DatagramSocket : public DescriptorInfoSingleMixin<SocketHandle> {
 public:
  explicit DatagramSocket(intptr_t s)
      : DescriptorInfoSingleMixin(s, kDatagramSocket) {}

  virtual ~DatagramSocket() {
    // Don't delete this object until all pending requests have been handled.
    ASSERT(!HasPendingRead());
    ASSERT(!HasPendingWrite());
  }

  // Internal interface used by the event handler.
  virtual bool IssueRecvFromLocked(MonitorLocker* ml);

  virtual void DoCloseLocked(MonitorLocker* ml);
  virtual bool IsClosed();

 private:
  virtual bool IssueSendToLocked(MonitorLocker* ml,
                                 std::unique_ptr<OverlappedBuffer> buffer,
                                 sockaddr* sa,
                                 socklen_t sa_len);

  DISALLOW_COPY_AND_ASSIGN(DatagramSocket);
};

// Event handler.
class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  virtual ~EventHandlerImplementation();

  void AssociateWithCompletionPort(Handle* handle);

  void SendData(intptr_t id, Dart_Port dart_port, int64_t data);
  void Start(EventHandler* handler);
  void Shutdown();

  static void EventHandlerEntry(uword args);

  int64_t GetTimeout();
  void HandleInterrupt(InterruptMessage* msg);
  void HandleTimeout();

  void HandleIOCompletion(int32_t bytes, ULONG_PTR key, OVERLAPPED* overlapped);

  void HandleCompletionOrInterrupt(BOOL ok,
                                   DWORD bytes,
                                   ULONG_PTR key,
                                   OVERLAPPED* overlapped);

  HANDLE completion_port() { return completion_port_; }

  LPFN_ACCEPTEX accept_ex() {
    InitializeSocketExtensions();
    return accept_ex_;
  }

  LPFN_CONNECTEX connect_ex() {
    InitializeSocketExtensions();
    return connect_ex_;
  }

  LPFN_DISCONNECTEX disconnect_ex() {
    InitializeSocketExtensions();
    return disconnect_ex_;
  }

  LPFN_GETACCEPTEXSOCKADDRS get_accept_ex_sockaddrs() {
    InitializeSocketExtensions();
    return get_accept_ex_sockaddrs_;
  }

 private:
  void InitializeSocketExtensions();

  void HandleAccept(ListenSocket* listen_socket,
                    std::unique_ptr<OverlappedBuffer> buffer);
  void HandleRead(Handle* handle,
                  int bytes,
                  std::unique_ptr<OverlappedBuffer> buffer);
  void HandleRecvFrom(Handle* handle,
                      int bytes,
                      std::unique_ptr<OverlappedBuffer> buffer);
  void HandleWrite(Handle* handle,
                   int bytes,
                   std::unique_ptr<OverlappedBuffer> buffer);
  void HandleDisconnect(ClientSocket* client_socket,
                        int bytes,
                        std::unique_ptr<OverlappedBuffer> buffer);
  void HandleConnect(ClientSocket* client_socket,
                     int bytes,
                     std::unique_ptr<OverlappedBuffer> buffer);

  Monitor monitor_;
  HANDLE handler_thread_ = INVALID_HANDLE_VALUE;

  TimeoutQueue timeout_queue_;  // Time for next timeout.
  bool shutdown_ = false;
  HANDLE completion_port_ = INVALID_HANDLE_VALUE;

  std::atomic<bool> socket_extensions_initialized_{false};
  LPFN_ACCEPTEX accept_ex_ = nullptr;
  LPFN_CONNECTEX connect_ex_ = nullptr;
  LPFN_DISCONNECTEX disconnect_ex_ = nullptr;
  LPFN_GETACCEPTEXSOCKADDRS get_accept_ex_sockaddrs_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(EventHandlerImplementation);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_EVENTHANDLER_WIN_H_
