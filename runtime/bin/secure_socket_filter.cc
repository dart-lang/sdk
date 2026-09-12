// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "bin/secure_socket_filter.h"

#include <errno.h>

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "bin/io_service.h"
#include "bin/lockers.h"
#include "bin/secure_socket_utils.h"
#include "bin/security_context.h"
#include "bin/socket.h"
#include "bin/socket_base.h"
#include "bin/utils.h"
#include "platform/syslog.h"

namespace dart {
namespace bin {

static int GetLastSocketError(intptr_t fd) {
#if defined(DART_HOST_OS_WINDOWS)
  OSError os_error;
  SocketBase::GetError(fd, &os_error);
  return os_error.code();
#else
  static_cast<void>(fd);
  return errno;
#endif
}

// Determines whether an OS socket error (or return status) indicates a
// non-fatal, retriable condition for BoringSSL custom socket BIO.
//
// BoringSSL custom BIO contract:
// - Returning -1 (read) or 0 (write) WITHOUT setting BIO_set_retry_read/write
//   causes BoringSSL to treat the condition as a fatal SSL_ERROR_SYSCALL (5),
//   which invalidates the TLS session and corrupts the state machine.
// - On Windows, non-blocking asynchronous I/O (Handle::Read / Handle::Write)
//   returns -1 with last_error == NOERROR (0) when an overlapped operation
//   is pending or no packet has completed yet.
// - Furthermore, socket resets/closures (WSAECONNRESET, ERROR_OPERATION_ABORTED,
//   etc.) must be flagged as retriable so that Dart EventHandler's stream
//   events (RawSocketEvent.readClosed / closed) can deliver the termination
//   gracefully instead of triggering an unhandled native SYSCALL exception.
static bool IsRetrySocketError(int error) {
  if (error == 0) {
    // Windows non-blocking pending I/O: Handle::Read returns -1 with last_error
    // == 0 when no data is ready, and Handle::Write returns -1 with last_error
    // == 0 when a write is in progress.
    return true;
  }
#if defined(DART_HOST_OS_WINDOWS)
  return error == WSAEWOULDBLOCK || error == WSAEBADF ||
         error == WSAENOTSOCK || error == ERROR_INVALID_HANDLE ||
         error == WSAECONNRESET || error == WSAECONNABORTED ||
         error == WSAESHUTDOWN || error == WSAENOTCONN ||
         error == ERROR_NETNAME_DELETED || error == ERROR_OPERATION_ABORTED ||
         error == ERROR_CONNECTION_ABORTED;
#else
  return error == EAGAIN || error == EWOULDBLOCK || error == EBADF ||
         error == ECONNRESET || error == EPIPE || error == ENOTCONN ||
         error == ECONNABORTED;
#endif
}

bool SSLFilter::library_initialized_ = false;
// To protect library initialization.
Mutex* SSLFilter::mutex_ = nullptr;
int SSLFilter::filter_ssl_index;
int SSLFilter::ssl_cert_context_index;
Dart_Port SSLFilter::trust_evaluate_reply_port_ = ILLEGAL_PORT;
BIO_METHOD* SSLFilter::socket_bio_method_ = nullptr;

void SSLFilter::Init() {
  ASSERT(SSLFilter::mutex_ == nullptr);
  SSLFilter::mutex_ = new Mutex();
}

void SSLFilter::Cleanup() {
  ASSERT(SSLFilter::mutex_ != nullptr);
  if (socket_bio_method_ != nullptr) {
    BIO_meth_free(socket_bio_method_);
    socket_bio_method_ = nullptr;
  }
  delete SSLFilter::mutex_;
  SSLFilter::mutex_ = nullptr;
  trust_evaluate_reply_port_ = ILLEGAL_PORT;
}

const intptr_t SSLFilter::kApproximateSize =
    sizeof(SSLFilter) + SSLFilter::kMaxPrefetchedData;

SSLFilterBuffer::SSLFilterBuffer(int size)
    : data_(new uint8_t[size]), size_(size) {
  ASSERT(size >= 2);
  ASSERT(data_ != nullptr);
  memset(data_, 0, size_);
}

SSLFilterBuffer::~SSLFilterBuffer() {
  delete[] data_;
}

static void ReleaseFilterBuffer(void* isolate_data, void* peer) {
  static_cast<SSLFilterBuffer*>(peer)->Release();
}

static Dart_Handle NewUnhandledInternalError(const char* message) {
  return Dart_NewUnhandledExceptionError(DartUtils::NewInternalError(message));
}

static Dart_Handle NewUnhandledArgumentError(const char* message) {
  return Dart_NewUnhandledExceptionError(
      DartUtils::NewDartArgumentError(message));
}

static Dart_Handle WrapFilterBuffer(SSLFilterBuffer* buffer) {
  // The allocation's initial reference belongs to SSLFilter. Reserve a second
  // reference for the ExternalUint8List before installing its finalizer.
  buffer->Retain();
  Dart_Handle data = Dart_NewExternalTypedDataWithFinalizer(
      Dart_TypedData_kUint8, buffer->data(), buffer->size(), buffer,
      buffer->size() + sizeof(SSLFilterBuffer), ReleaseFilterBuffer);
  if (Dart_IsError(data)) {
    buffer->Release();
  }
  return data;
}

static SSLFilter* GetFilter(Dart_NativeArguments args) {
  SSLFilter* filter = nullptr;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(Dart_GetNativeInstanceField(
      dart_this, SSLFilter::kSSLFilterNativeFieldIndex,
      reinterpret_cast<intptr_t*>(&filter)));
  if (filter == nullptr) {
    Dart_PropagateError(Dart_NewUnhandledExceptionError(
        DartUtils::NewInternalError("No native peer")));
  }
  return filter;
}

static void DeleteFilter(void* isolate_data, void* context_pointer) {
  SSLFilter* filter = reinterpret_cast<SSLFilter*>(context_pointer);
  filter->Release();
}

static Dart_Handle SetFilter(Dart_NativeArguments args, SSLFilter* filter) {
  ASSERT(filter != nullptr);
  Dart_Handle dart_this = Dart_GetNativeArgument(args, 0);
  RETURN_IF_ERROR(dart_this);
  ASSERT(Dart_IsInstance(dart_this));
  Dart_Handle err = Dart_SetNativeInstanceField(
      dart_this, SSLFilter::kSSLFilterNativeFieldIndex,
      reinterpret_cast<intptr_t>(filter));
  RETURN_IF_ERROR(err);
  Dart_NewFinalizableHandle(dart_this, reinterpret_cast<void*>(filter),
                            SSLFilter::kApproximateSize, DeleteFilter);
  return Dart_Null();
}

void FUNCTION_NAME(SecureSocket_Init)(Dart_NativeArguments args) {
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  SSLFilter* filter = new SSLFilter();
  Dart_Handle err = SetFilter(args, filter);
  if (Dart_IsError(err)) {
    filter->Release();
    Dart_PropagateError(err);
  }
  err = filter->Init(dart_this);
  if (Dart_IsError(err)) {
    // The finalizer was set up by SetFilter. It will delete `filter` if there
    // is an error.
    filter->Destroy();
    Dart_PropagateError(err);
  }
}

void FUNCTION_NAME(SecureSocket_Connect)(Dart_NativeArguments args) {
  Dart_Handle host_name_object = ThrowIfError(Dart_GetNativeArgument(args, 1));
  Dart_Handle context_object = ThrowIfError(Dart_GetNativeArgument(args, 2));
  bool is_server = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3));
  bool request_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 4));
  bool require_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 5));
  Dart_Handle protocols_handle = ThrowIfError(Dart_GetNativeArgument(args, 6));

  const char* host_name = nullptr;
  // TODO(whesse): Is truncating a Dart string containing \0 what we want?
  ThrowIfError(Dart_StringToCString(host_name_object, &host_name));

  SSLCertContext* context = nullptr;
  if (!Dart_IsNull(context_object)) {
    ThrowIfError(Dart_GetNativeInstanceField(
        context_object, SSLCertContext::kSecurityContextNativeFieldIndex,
        reinterpret_cast<intptr_t*>(&context)));
  }

  // The protocols_handle is guaranteed to be a valid Uint8List.
  // It will have the correct length encoding of the protocols array.
  ASSERT(!Dart_IsNull(protocols_handle));
  Dart_Handle native_socket = ThrowIfError(Dart_GetNativeArgument(args, 7));
  Dart_Handle transport_read = ThrowIfError(Dart_GetNativeArgument(args, 8));
  Dart_Handle transport_write = ThrowIfError(Dart_GetNativeArgument(args, 9));
  Socket* socket = nullptr;
  if (!Dart_IsNull(native_socket)) {
    socket = Socket::GetSocketIdNativeField(native_socket);
  }
  GetFilter(args)->Connect(host_name, context, is_server,
                           request_client_certificate,
                           require_client_certificate, protocols_handle, socket,
                           transport_read, transport_write);
}

void FUNCTION_NAME(SecureSocket_Destroy)(Dart_NativeArguments args) {
  SSLFilter* filter = GetFilter(args);
  // There are two paths that can clean up an SSLFilter object. First,
  // there is this explicit call to Destroy(), called from
  // _SecureFilter.destroy() in Dart code. After a call to destroy(), the Dart
  // code maintains the invariant that there will be no further SSLFilter
  // requests sent to the IO Service. Therefore, the internals of the SSLFilter
  // are safe to deallocate, but not the SSLFilter itself, which is already
  // set up to be cleaned up by the finalizer.
  //
  // The second path is through the finalizer, which we have to do in case
  // some mishap prevents a call to _SecureFilter.destroy().
  filter->Destroy();
}

void FUNCTION_NAME(SecureSocket_Handshake)(Dart_NativeArguments args) {
  Dart_Handle port = ThrowIfError(Dart_GetNativeArgument(args, 1));
  ASSERT(!Dart_IsNull(port));

  Dart_Port port_id;
  ThrowIfError(Dart_SendPortGetId(port, &port_id));
  SSLFilter* filter = GetFilter(args);
  int status = filter->Handshake(port_id);
  Dart_Handle result = Dart_NewList(5);
  ThrowIfError(result);
  ThrowIfError(Dart_ListSetAt(result, 0, Dart_NewInteger(status)));
  ThrowIfError(
      Dart_ListSetAt(result, 1, Dart_NewBoolean(filter->HasPrefetchedData())));
  ThrowIfError(Dart_ListSetAt(
      result, 2, Dart_NewBoolean(filter->HasPendingSocketWrite())));
  ThrowIfError(Dart_ListSetAt(result, 3,
                              Dart_NewInteger(filter->TakeSocketReadBytes())));
  ThrowIfError(Dart_ListSetAt(result, 4,
                              Dart_NewInteger(filter->TakeSocketWriteBytes())));
  Dart_SetReturnValue(args, result);
}

void FUNCTION_NAME(SecureSocket_MarkAsTrusted)(Dart_NativeArguments args) {
  GetFilter(args)->MarkAsTrusted(args);
}

void FUNCTION_NAME(SecureSocket_NewX509CertificateWrapper)(
    Dart_NativeArguments args) {
// This is to be used only in conjunction with certificate trust evaluator
// running asynchronously, which is only used on mac/ios at the moment.
#if defined(DART_HOST_OS_MACOS)
  intptr_t x509_pointer = DartUtils::GetNativeIntptrArgument(args, 0);
  X509* x509 = reinterpret_cast<X509*>(x509_pointer);
  Dart_SetReturnValue(args, X509Helper::WrappedX509Certificate(x509));
#else
  FATAL("This is to be used only on mac/ios platforms");
#endif
}

void FUNCTION_NAME(SecureSocket_GetSelectedProtocol)(
    Dart_NativeArguments args) {
  GetFilter(args)->GetSelectedProtocol(args);
}

void FUNCTION_NAME(SecureSocket_RegisterHandshakeCompleteCallback)(
    Dart_NativeArguments args) {
  Dart_Handle handshake_complete =
      ThrowIfError(Dart_GetNativeArgument(args, 1));
  if (!Dart_IsClosure(handshake_complete)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Illegal argument to RegisterHandshakeCompleteCallback"));
  }
  GetFilter(args)->RegisterHandshakeCompleteCallback(handshake_complete);
}

void FUNCTION_NAME(SecureSocket_RegisterBadCertificateCallback)(
    Dart_NativeArguments args) {
  Dart_Handle callback = ThrowIfError(Dart_GetNativeArgument(args, 1));
  if (!Dart_IsClosure(callback) && !Dart_IsNull(callback)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Illegal argument to RegisterBadCertificateCallback"));
  }
  GetFilter(args)->RegisterBadCertificateCallback(callback);
}

void FUNCTION_NAME(SecureSocket_RegisterKeyLogPort)(Dart_NativeArguments args) {
  Dart_Handle port = ThrowIfError(Dart_GetNativeArgument(args, 1));
  ASSERT(!Dart_IsNull(port));

  Dart_Port port_id;
  ThrowIfError(Dart_SendPortGetId(port, &port_id));
  GetFilter(args)->RegisterKeyLogPort(port_id);
}

void FUNCTION_NAME(SecureSocket_PeerCertificate)(Dart_NativeArguments args) {
  Dart_Handle cert = ThrowIfError(GetFilter(args)->PeerCertificate());
  Dart_SetReturnValue(args, cert);
}

void FUNCTION_NAME(SecureSocket_QueuePrefetchedData)(
    Dart_NativeArguments args) {
  SSLFilter* filter = GetFilter(args);
  Dart_Handle data = ThrowIfError(Dart_GetNativeArgument(args, 1));
  intptr_t offset = DartUtils::GetNativeIntptrArgument(args, 2);
  Dart_SetIntegerReturnValue(args, filter->QueuePrefetchedData(data, offset));
}

void FUNCTION_NAME(SecureSocket_Process)(Dart_NativeArguments args) {
  SSLFilter* filter = GetFilter(args);
  Dart_Handle positions = ThrowIfError(Dart_GetNativeArgument(args, 1));
  intptr_t length = 0;
  ThrowIfError(Dart_ListLength(positions, &length));
  if (length != SSLFilter::kNumBuffers * 3) {
    Dart_ThrowException(DartUtils::NewInternalError(
        "Invalid SecureSocket buffer position list"));
  }

  int starts[SSLFilter::kNumBuffers];
  int ends[SSLFilter::kNumBuffers];
  int sizes[SSLFilter::kNumBuffers];
  for (int i = 0; i < SSLFilter::kNumBuffers; ++i) {
    starts[i] = DartUtils::GetIntegerValue(
        ThrowIfError(Dart_ListGetAt(positions, 3 * i)));
    ends[i] = DartUtils::GetIntegerValue(
        ThrowIfError(Dart_ListGetAt(positions, 3 * i + 1)));
    sizes[i] = DartUtils::GetIntegerValue(
        ThrowIfError(Dart_ListGetAt(positions, 3 * i + 2)));
  }

  if (!filter->ProcessAllBuffers(starts, ends, sizes)) {
    filter->ThrowFilterError();
  }

  Dart_Handle result = Dart_NewList(SSLFilter::kNumBuffers * 2 + 6);
  ThrowIfError(result);
  for (int i = 0; i < SSLFilter::kNumBuffers; ++i) {
    ThrowIfError(Dart_ListSetAt(result, 2 * i, Dart_NewInteger(starts[i])));
    ThrowIfError(Dart_ListSetAt(result, 2 * i + 1, Dart_NewInteger(ends[i])));
  }
  ThrowIfError(Dart_ListSetAt(result, SSLFilter::kNumBuffers * 2,
                              Dart_NewBoolean(filter->WantsWrite())));
  ThrowIfError(Dart_ListSetAt(result, SSLFilter::kNumBuffers * 2 + 1,
                              Dart_NewBoolean(filter->HasPrefetchedData())));
  ThrowIfError(
      Dart_ListSetAt(result, SSLFilter::kNumBuffers * 2 + 2,
                     Dart_NewBoolean(filter->HasPendingSocketWrite())));
  ThrowIfError(Dart_ListSetAt(result, SSLFilter::kNumBuffers * 2 + 3,
                              Dart_NewInteger(filter->TakeSocketReadBytes())));
  ThrowIfError(Dart_ListSetAt(result, SSLFilter::kNumBuffers * 2 + 4,
                              Dart_NewInteger(filter->TakeSocketWriteBytes())));
  ThrowIfError(
      Dart_ListSetAt(result, SSLFilter::kNumBuffers * 2 + 5,
                     Dart_NewBoolean(filter->HasPendingPlaintext())));
  Dart_SetReturnValue(args, result);
}

void FUNCTION_NAME(SecureSocket_GrowBuffer)(Dart_NativeArguments args) {
  SSLFilter* filter = GetFilter(args);
  int buffer_index =
      static_cast<int>(DartUtils::GetNativeIntptrArgument(args, 1));
  int start = static_cast<int>(DartUtils::GetNativeIntptrArgument(args, 2));
  int end = static_cast<int>(DartUtils::GetNativeIntptrArgument(args, 3));
  int old_size = static_cast<int>(DartUtils::GetNativeIntptrArgument(args, 4));
  int new_size = static_cast<int>(DartUtils::GetNativeIntptrArgument(args, 5));
  Dart_SetReturnValue(args, ThrowIfError(filter->GrowBuffer(
                                buffer_index, start, end, old_size, new_size)));
}

void SSLFilter::ThrowFilterError() {
  if (last_ssl_error_ == SSL_ERROR_SYSCALL && last_os_error_ != 0) {
    OSError os_error;
    os_error.SetCodeAndMessage(OSError::kSystem, last_os_error_);
    Dart_Handle dart_os_error = DartUtils::NewDartOSError(&os_error);
    Dart_Handle exception = DartUtils::NewDartIOException(
        "TlsException", "SecureSocket filter error", dart_os_error);
    Dart_ThrowException(exception);
    UNREACHABLE();
  }
  SecureSocketUtils::ThrowIOException(
      last_ssl_error_ == SSL_ERROR_SSL ? 0 : last_ssl_status_, "TlsException",
      "SecureSocket filter error", ssl_);
}

bool SSLFilter::HasPendingSocketWrite() const {
#if defined(DART_HOST_OS_WINDOWS)
  return socket_fd_ != Socket::kClosedFd &&
         SocketBase::HasPendingWrite(socket_fd_);
#else
  return false;
#endif
}

intptr_t SSLFilter::QueuePrefetchedData(Dart_Handle data, intptr_t offset) {
  if (HasPrefetchedData()) {
    return 0;
  }
  if (prefetched_data_ != nullptr) {
    delete[] prefetched_data_;
    prefetched_data_ = nullptr;
  }
  prefetched_data_offset_ = 0;
  prefetched_data_length_ = 0;

  intptr_t data_length = 0;
  ThrowIfError(Dart_ListLength(data, &data_length));
  intptr_t length = BoundedPrefetchedDataLength(data_length, offset);
  if (length < 0) {
    Dart_ThrowException(
        DartUtils::NewDartArgumentError("Invalid prefetched data offset"));
  }
  if (length == 0) {
    prefetched_data_has_tail_ = false;
    return 0;
  }

  prefetched_data_ = new uint8_t[length];
  ASSERT(prefetched_data_ != nullptr);
  Dart_Handle result =
      Dart_ListGetAsBytes(data, offset, prefetched_data_, length);
  if (Dart_IsError(result)) {
    delete[] prefetched_data_;
    prefetched_data_ = nullptr;
    prefetched_data_has_tail_ = false;
    Dart_PropagateError(result);
  }
  prefetched_data_length_ = length;
  prefetched_data_has_tail_ =
      PrefetchedDataHasTail(data_length, offset, length);
  return length;
}

int SSLFilter::SocketBIORead(BIO* bio, char* output, int length) {
  BIO_clear_retry_flags(bio);
  SSLFilter* filter = static_cast<SSLFilter*>(BIO_get_data(bio));
  if (filter == nullptr || length <= 0) {
    return -1;
  }

  if (filter->HasPrefetchedData()) {
    intptr_t available =
        filter->prefetched_data_length_ - filter->prefetched_data_offset_;
    intptr_t to_read = available < length ? available : length;
    memmove(output, filter->prefetched_data_ + filter->prefetched_data_offset_,
            to_read);
    filter->prefetched_data_offset_ += to_read;
    if (!filter->HasPrefetchedData()) {
      delete[] filter->prefetched_data_;
      filter->prefetched_data_ = nullptr;
      filter->prefetched_data_offset_ = 0;
      filter->prefetched_data_length_ = 0;
    }
    return static_cast<int>(to_read);
  }

  // The current bounded chunk is empty, but Dart still owns earlier transport
  // bytes which have not been queued yet. Do not allow newer socket bytes to
  // overtake that tail. Returning WANT_READ gives Dart a chance to queue the
  // next chunk before BoringSSL reads again.
  if (filter->prefetched_data_has_tail_) {
    BIO_set_retry_read(bio);
    return -1;
  }

  if (filter->socket_fd_ != Socket::kClosedFd) {
    const intptr_t fd = filter->socket_fd_;
    intptr_t requested = length;
    if (Socket::short_socket_read()) {
      requested = (requested + 1) / 2;
    }
    intptr_t read = SocketBase::Read(fd, output, requested, SocketBase::kAsync);
    if (read > 0) {
      filter->socket_read_bytes_ += read;
      return static_cast<int>(read);
    }
    if (read == 0) {
      BIO_set_retry_read(bio);
      return -1;
    }
    const int socket_error = GetLastSocketError(fd);
    if (IsRetrySocketError(socket_error)) {
      BIO_set_retry_read(bio);
      return -1;
    }
    filter->last_os_error_ = socket_error;
    return -1;
  }

  if (filter->transport_read_ == nullptr) {
    return -1;
  }
  Dart_Handle read_length = Dart_NewInteger(length);
  if (Dart_IsError(read_length)) {
    filter->SetCallbackError(read_length);
    return -1;
  }
  Dart_Handle result = Dart_InvokeClosure(
      Dart_HandleFromPersistent(filter->transport_read_), 1, &read_length);
  if (Dart_IsError(result)) {
    filter->SetCallbackError(result);
    return -1;
  }
  if (Dart_IsNull(result)) {
    BIO_set_retry_read(bio);
    return -1;
  }
  intptr_t result_length = 0;
  Dart_Handle status = Dart_ListLength(result, &result_length);
  if (Dart_IsError(status)) {
    filter->SetCallbackError(status);
    return -1;
  }
  if (result_length < 0 || result_length > length) {
    filter->SetCallbackError(NewUnhandledArgumentError(
        "RawSocket.read returned an invalid byte count"));
    return -1;
  }
  if (result_length == 0) {
    BIO_set_retry_read(bio);
    return -1;
  }
  status = Dart_ListGetAsBytes(result, 0, reinterpret_cast<uint8_t*>(output),
                               result_length);
  if (Dart_IsError(status)) {
    filter->SetCallbackError(status);
    return -1;
  }
  return static_cast<int>(result_length);
}

int SSLFilter::SocketBIOWrite(BIO* bio,
                              const char* input,
                              size_t length,
                              size_t* written) {
  BIO_clear_retry_flags(bio);
  SSLFilter* filter = static_cast<SSLFilter*>(BIO_get_data(bio));
  if (filter == nullptr) {
    return 0;
  }

  intptr_t requested = length > static_cast<size_t>(INTPTR_MAX)
                           ? INTPTR_MAX
                           : static_cast<intptr_t>(length);
  intptr_t result = 0;
  if (filter->socket_fd_ != Socket::kClosedFd) {
    const intptr_t fd = filter->socket_fd_;
    if (Socket::short_socket_write()) {
      requested = (requested + 1) / 2;
    }
    result = SocketBase::Write(fd, input, requested, SocketBase::kAsync);
    if (result > 0) {
      filter->socket_write_bytes_ += result;
    } else if (result == 0) {
      BIO_set_retry_write(bio);
    } else {
      const int socket_error = GetLastSocketError(fd);
      if (IsRetrySocketError(socket_error)) {
        BIO_set_retry_write(bio);
      } else {
        filter->last_os_error_ = socket_error;
      }
    }
  } else {
    if (filter->transport_write_ == nullptr) {
      return 0;
    }
    Dart_Handle data = DartUtils::MakeUint8Array(input, requested);
    if (Dart_IsError(data)) {
      filter->SetCallbackError(data);
      return 0;
    }
    Dart_Handle write_result = Dart_InvokeClosure(
        Dart_HandleFromPersistent(filter->transport_write_), 1, &data);
    if (Dart_IsError(write_result)) {
      filter->SetCallbackError(write_result);
      return 0;
    }
    int64_t dart_result = 0;
    Dart_Handle status = Dart_IntegerToInt64(write_result, &dart_result);
    if (Dart_IsError(status)) {
      filter->SetCallbackError(status);
      return 0;
    }
    if (dart_result < 0 || dart_result > requested) {
      filter->SetCallbackError(NewUnhandledArgumentError(
          "RawSocket.write returned an invalid byte count"));
      return 0;
    }
    result = static_cast<intptr_t>(dart_result);
  }
  if (result > 0) {
    *written = static_cast<size_t>(result);
    return 1;
  }
  if (result == 0) {
    BIO_set_retry_write(bio);
  }
  return 0;
}

long SSLFilter::SocketBIOControl(BIO* bio,
                                 int command,
                                 long argument,
                                 void* pointer) {
  SSLFilter* filter = static_cast<SSLFilter*>(BIO_get_data(bio));
  switch (command) {
    case BIO_CTRL_EOF:
      return 0;
    case BIO_CTRL_PENDING:
      return filter != nullptr && filter->HasPrefetchedData()
                 ? filter->prefetched_data_length_ -
                       filter->prefetched_data_offset_
                 : 0;
    case BIO_CTRL_WPENDING:
      return 0;
    case BIO_CTRL_FLUSH:
      return 1;
    default:
      return 0;
  }
}

bool SSLFilter::ProcessAllBuffers(int starts[kNumBuffers],
                                  int ends[kNumBuffers],
                                  int sizes[kNumBuffers]) {
  for (int i = 0; i < kNumBuffers; ++i) {
    int start = starts[i];
    int end = ends[i];
    int size = sizes[i];
    if (buffers_[i] == nullptr || size != buffers_[i]->size() ||
        !IsValidBufferRange(start, end, size)) {
      Dart_ThrowException(DartUtils::NewInternalError(
          "Out-of-bounds internal buffer access in dart:io SecureSocket"));
    }
    switch (i) {
      case kReadPlaintext:
        // Write data to the circular buffer's free space.  If the buffer
        // is full, neither if statement is executed and nothing happens.
        if (start <= end) {
          // If the free space may be split into two segments,
          // then the first is [end, size), unless start == 0.
          // Then, since the last free byte is at position start - 2,
          // the interval is [end, size - 1).
          int buffer_end = (start == 0) ? size - 1 : size;
          int bytes = ProcessReadPlaintextBuffer(end, buffer_end);
          if (bytes < 0) return false;
          end += bytes;
          ASSERT(end <= size);
          if (end == size) end = 0;
        }
        if (start > end + 1) {
          int bytes = ProcessReadPlaintextBuffer(end, start - 1);
          if (bytes < 0) return false;
          end += bytes;
          ASSERT(end < start);
        }
        ends[i] = end;
        break;
      case kWritePlaintext:
        // Read/Write data from circular buffer.  If the buffer is empty,
        // neither if statement's condition is true.
        if (end < start) {
          // Data may be split into two segments.  In this case,
          // the first is [start, size).
          int bytes = ProcessWritePlaintextBuffer(start, size);
          if (bytes < 0) return false;
          start += bytes;
          ASSERT(start <= size);
          if (start == size) start = 0;
        }
        if (start < end) {
          int bytes = ProcessWritePlaintextBuffer(start, end);
          if (bytes < 0) return false;
          start += bytes;
          ASSERT(start <= end);
        }
        starts[i] = start;
        break;
      default:
        UNREACHABLE();
    }
  }
  return true;
}

Dart_Handle SSLFilter::GrowBuffer(int buffer_index,
                                  int start,
                                  int end,
                                  int old_size,
                                  int new_size) {
  if (buffer_index < 0 || buffer_index >= kNumBuffers) {
    return NewUnhandledInternalError("Invalid SecureSocket buffer index");
  }

  SSLFilterBuffer* old_buffer = buffers_[buffer_index];
  if (old_buffer == nullptr || old_size != old_buffer->size() ||
      new_size <= old_size || new_size > max_buffer_size_ ||
      !IsValidBufferRange(start, end, old_size)) {
    return NewUnhandledInternalError(
        "Invalid SecureSocket buffer growth request");
  }

  int used = start > end ? old_size + end - start : end - start;
  if (used < 0 || used >= new_size) {
    return NewUnhandledInternalError(
        "Invalid SecureSocket buffer contents during growth");
  }

  SSLFilterBuffer* new_buffer = new SSLFilterBuffer(new_size);
  int first_length = old_size - start;
  if (first_length > used) first_length = used;
  if (first_length > 0) {
    memmove(new_buffer->data(), old_buffer->data() + start, first_length);
  }
  int second_length = used - first_length;
  if (second_length > 0) {
    memmove(new_buffer->data() + first_length, old_buffer->data(),
            second_length);
  }

  Dart_Handle data = WrapFilterBuffer(new_buffer);
  if (Dart_IsError(data)) {
    new_buffer->Release();
    return data;
  }

  // Commit only after both the native allocation and its Dart wrapper exist.
  // The old ExternalUint8List owns the remaining reference to old_buffer.
  buffers_[buffer_index] = new_buffer;
  old_buffer->Release();
  return data;
}

Dart_Handle SSLFilter::Init(Dart_Handle dart_this) {
  if (!library_initialized_) {
    InitializeLibrary();
  }
  ASSERT(bad_certificate_callback_ == nullptr);
  bad_certificate_callback_ = Dart_NewPersistentHandle(Dart_Null());
  ASSERT(bad_certificate_callback_ != nullptr);
  // Caller handles cleanup on an error.
  return InitializeBuffers(dart_this);
}

Dart_Handle SSLFilter::InitializeBuffers(Dart_Handle dart_this) {
  // Create SSLFilter buffers as ExternalUint8Array objects.
  Dart_Handle buffers_string = DartUtils::NewString("buffers");
  RETURN_IF_ERROR(buffers_string);
  Dart_Handle dart_buffers_object = Dart_GetField(dart_this, buffers_string);
  RETURN_IF_ERROR(dart_buffers_object);
  Dart_Handle secure_filter_impl_type = Dart_InstanceGetType(dart_this);
  RETURN_IF_ERROR(secure_filter_impl_type);
  Dart_Handle size_string = DartUtils::NewString("SIZE");
  RETURN_IF_ERROR(size_string);
  Dart_Handle dart_buffer_size =
      Dart_GetField(secure_filter_impl_type, size_string);
  RETURN_IF_ERROR(dart_buffer_size);

  int64_t buffer_size = 0;
  Dart_Handle err = Dart_IntegerToInt64(dart_buffer_size, &buffer_size);
  RETURN_IF_ERROR(err);

  if (buffer_size <= 0 || buffer_size > 1 * MB) {
    FATAL("Invalid buffer size in _ExternalBuffer");
  }
  max_buffer_size_ = static_cast<int>(buffer_size);

  Dart_Handle data_identifier = DartUtils::NewString("data");
  RETURN_IF_ERROR(data_identifier);

  Dart_Handle current_size_identifier = DartUtils::NewString("size");
  RETURN_IF_ERROR(current_size_identifier);

  Dart_Handle result = Dart_Null();
  for (int i = 0; i < kNumBuffers; ++i) {
    Dart_Handle dart_buffer = Dart_ListGetAt(dart_buffers_object, i);
    if (Dart_IsError(dart_buffer)) {
      result = dart_buffer;
      break;
    }

    Dart_Handle dart_current_size =
        Dart_GetField(dart_buffer, current_size_identifier);
    if (Dart_IsError(dart_current_size)) {
      result = dart_current_size;
      break;
    }
    int64_t current_size = 0;
    result = Dart_IntegerToInt64(dart_current_size, &current_size);
    if (Dart_IsError(result)) {
      break;
    }
    if (current_size < 2 || current_size > max_buffer_size_) {
      result =
          NewUnhandledInternalError("Invalid initial SecureSocket buffer size");
      break;
    }

    SSLFilterBuffer* buffer =
        new SSLFilterBuffer(static_cast<int>(current_size));
    Dart_Handle data = WrapFilterBuffer(buffer);
    if (Dart_IsError(data)) {
      buffer->Release();
      result = data;
      break;
    }
    buffers_[i] = buffer;
    result = Dart_SetField(dart_buffer, data_identifier, data);
    if (Dart_IsError(result)) {
      break;
    }
  }

  // Caller handles cleanup on an error.
  return result;
}

void SSLFilter::RegisterHandshakeCompleteCallback(Dart_Handle complete) {
  ASSERT(nullptr == handshake_complete_);
  handshake_complete_ = Dart_NewPersistentHandle(complete);

  ASSERT(handshake_complete_ != nullptr);
}

void SSLFilter::RegisterBadCertificateCallback(Dart_Handle callback) {
  ASSERT(bad_certificate_callback_ != nullptr);
  Dart_DeletePersistentHandle(bad_certificate_callback_);
  bad_certificate_callback_ = Dart_NewPersistentHandle(callback);
  ASSERT(bad_certificate_callback_ != nullptr);
}

Dart_Handle SSLFilter::PeerCertificate() {
  X509* ca = SSL_get_peer_certificate(ssl_);
  if (ca == nullptr) {
    return Dart_Null();
  }
  return X509Helper::WrappedX509Certificate(ca);
}

void SSLFilter::RegisterKeyLogPort(Dart_Port key_log_port) {
  key_log_port_ = key_log_port;
}

void SSLFilter::InitializeLibrary() {
  MutexLocker locker(mutex_);
  if (!library_initialized_) {
    SSL_library_init();
    const int socket_bio_type = BIO_get_new_index();
    RELEASE_ASSERT(socket_bio_type >= 0);
    socket_bio_method_ = BIO_meth_new(socket_bio_type, nullptr);
    RELEASE_ASSERT(socket_bio_method_ != nullptr);
    RELEASE_ASSERT(
        BIO_meth_set_read(socket_bio_method_, SSLFilter::SocketBIORead));
    RELEASE_ASSERT(
        BIO_meth_set_write_ex(socket_bio_method_, SSLFilter::SocketBIOWrite));
    RELEASE_ASSERT(
        BIO_meth_set_ctrl(socket_bio_method_, SSLFilter::SocketBIOControl));
    filter_ssl_index =
        SSL_get_ex_new_index(0, nullptr, nullptr, nullptr, nullptr);
    ASSERT(filter_ssl_index >= 0);
    ssl_cert_context_index =
        SSL_get_ex_new_index(0, nullptr, nullptr, nullptr, nullptr);
    ASSERT(ssl_cert_context_index >= 0);
    library_initialized_ = true;
  }
}

Dart_Port SSLFilter::TrustEvaluateReplyPort() {
  MutexLocker locker(mutex_);
  if (trust_evaluate_reply_port_ == ILLEGAL_PORT) {
    trust_evaluate_reply_port_ =
        Dart_NewConcurrentNativePort("SSLCertContextTrustEvaluate",
                                     SSLCertContext::GetTrustEvaluateHandler(),
                                     IOService::max_concurrency());
  }
  return trust_evaluate_reply_port_;
}

void SSLFilter::Connect(const char* hostname,
                        SSLCertContext* context,
                        bool is_server,
                        bool request_client_certificate,
                        bool require_client_certificate,
                        Dart_Handle protocols_handle,
                        Socket* socket,
                        Dart_Handle transport_read,
                        Dart_Handle transport_write) {
  is_server_ = is_server;
  if (ssl_ != nullptr) {
    FATAL("Connect called twice on the same _SecureFilter.");
  }

  int status;
  ASSERT(socket_ == nullptr);
  ASSERT(socket_fd_ == Socket::kClosedFd);
  ASSERT(transport_read_ == nullptr);
  ASSERT(transport_write_ == nullptr);
  if (socket != nullptr) {
    socket_ = socket;
    socket_->Retain();
    socket_fd_ = socket->fd();
    Socket::RetainFd(socket_fd_);
  } else {
    if (!Dart_IsClosure(transport_read) || !Dart_IsClosure(transport_write)) {
      Dart_ThrowException(DartUtils::NewDartArgumentError(
          "SecureSocket transport callbacks must be closures"));
    }
    transport_read_ = Dart_NewPersistentHandle(transport_read);
    transport_write_ = Dart_NewPersistentHandle(transport_write);
    ASSERT(transport_read_ != nullptr);
    ASSERT(transport_write_ != nullptr);
  }

  BIO* socket_bio = BIO_new(socket_bio_method_);
  if (socket_bio == nullptr) {
    SecureSocketUtils::ThrowIOException(0, "TlsException",
                                        "Failed to create socket BIO", ssl_);
  }
  BIO_set_data(socket_bio, this);
  BIO_set_init(socket_bio, 1);

  ASSERT(context != nullptr);
  ASSERT(context->context() != nullptr);
  ssl_ = SSL_new(context->context());
  if (ssl_ == nullptr) {
    BIO_free(socket_bio);
    SecureSocketUtils::ThrowIOException(
        0, "TlsException", "Failed to create TLS connection", nullptr);
  }
  SSL_set_bio(ssl_, socket_bio, socket_bio);
  SSL_set_mode(ssl_, SSL_MODE_AUTO_RETRY | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);
  SSL_set_ex_data(ssl_, filter_ssl_index, this);

  if (context->allow_tls_renegotiation()) {
    SSL_set_renegotiate_mode(ssl_, ssl_renegotiate_freely);
  }
  context->RegisterCallbacks(ssl_);
  SSL_set_ex_data(ssl_, ssl_cert_context_index, context);

  if (is_server_) {
    int certificate_mode =
        request_client_certificate ? SSL_VERIFY_PEER : SSL_VERIFY_NONE;
    if (require_client_certificate) {
      certificate_mode |= SSL_VERIFY_FAIL_IF_NO_PEER_CERT;
    }
    SSL_set_verify(ssl_, certificate_mode, nullptr);
  } else {
    SSLCertContext::SetAlpnProtocolList(protocols_handle, ssl_, nullptr, false);
    status = SSL_set_tlsext_host_name(ssl_, hostname);
    SecureSocketUtils::CheckStatusSSL(status, "TlsException",
                                      "Set SNI host name", ssl_);
    // Sets the hostname in the certificate-checking object, so it is checked
    // against the certificate presented by the server.
    X509_VERIFY_PARAM* certificate_checking_parameters = SSL_get0_param(ssl_);
    hostname_ = Utils::StrDup(hostname);
    X509_VERIFY_PARAM_set_flags(
        certificate_checking_parameters,
        X509_V_FLAG_PARTIAL_CHAIN | X509_V_FLAG_TRUSTED_FIRST);
    X509_VERIFY_PARAM_set_hostflags(certificate_checking_parameters, 0);

    // Use different check depending on whether the hostname is an IP address
    // or a DNS name.
    if (SocketBase::IsValidAddress(hostname_)) {
      status = X509_VERIFY_PARAM_set1_ip_asc(certificate_checking_parameters,
                                             hostname_);
    } else {
      status = X509_VERIFY_PARAM_set1_host(certificate_checking_parameters,
                                           hostname_, strlen(hostname_));
    }
    SecureSocketUtils::CheckStatusSSL(
        status, "TlsException", "Set hostname for certificate checking", ssl_);
  }
  if (is_server_) {
    SSL_set_accept_state(ssl_);
  } else {
    SSL_set_connect_state(ssl_);
  }
  in_handshake_ = true;
}

void SSLFilter::MarkAsTrusted(Dart_NativeArguments args) {
  intptr_t certificate_pointer = DartUtils::GetNativeIntptrArgument(args, 1);
  ASSERT(certificate_pointer != 0);
  certificate_trust_state_.reset(
      new X509TrustState(reinterpret_cast<X509*>(certificate_pointer),
                         DartUtils::GetNativeBooleanArgument(args, 2)));
  if (SSL_LOG_STATUS) {
    Syslog::Print("Mark %p as %strusted certificate\n",
                  certificate_trust_state_->x509(),
                  certificate_trust_state_->is_trusted() ? "" : "not ");
  }
}

int SSLFilter::Handshake(Dart_Port reply_port) {
  if (ssl_ == nullptr) {
    SecureSocketUtils::ThrowIOException(
        0, "HandshakeException",
        "TLS handshake started before the connection was initialized",
        nullptr);
    return SSL_ERROR_SSL;
  }

  // Set reply port to be used by CertificateVerificationCallback
  // invoked by SSL_do_handshake: this is where results of
  // certificate evaluation will be communicated to.
  reply_port_ = reply_port;

  // Try and push handshake along.
  int status = SSL_do_handshake(ssl_);
  int error = SSL_get_error(ssl_, status);
  if (callback_error != nullptr) {
    // The SSL_do_handshake will try performing a handshake and might call:
    //   SSLCertContext::KeyLogCallback
    //   SSLCertContext::CertificateCallback
    //   the Dart RawSocket transport callbacks
    //
    // If either of those functions fail, and this.callback_error has not
    // already been set, then they will set this.callback_error to an error
    // handle i.e. only the first error will be captured and propagated.
    Dart_PropagateError(callback_error);
  }
  if (error == SSL_ERROR_WANT_CERTIFICATE_VERIFY) {
    return SSL_ERROR_WANT_CERTIFICATE_VERIFY;
  }
  if (SSL_want_write(ssl_) || SSL_want_read(ssl_)) {
    in_handshake_ = true;
    return error;
  }
  SecureSocketUtils::CheckStatusSSL(
      status, "HandshakeException",
      is_server_ ? "Handshake error in server" : "Handshake error in client",
      ssl_);
  // Handshake succeeded.
  if (in_handshake_) {
    // TODO(24071): Check return value of SSL_get_verify_result, this
    //    should give us the hostname check.
    int result = SSL_get_verify_result(ssl_);
    if (SSL_LOG_STATUS) {
      Syslog::Print("Handshake verification status: %d\n", result);
      X509* peer_certificate = SSL_get_peer_certificate(ssl_);
      if (peer_certificate == nullptr) {
        Syslog::Print("No peer certificate received\n");
      } else {
        X509_NAME* s_name = X509_get_subject_name(peer_certificate);
        printf("Peer certificate SN: ");
        X509_NAME_print_ex_fp(stdout, s_name, 4, 0);
        printf("\n");
      }
    }
    ThrowIfError(Dart_InvokeClosure(
        Dart_HandleFromPersistent(handshake_complete_), 0, nullptr));
    in_handshake_ = false;
  }

  return error;
}

void SSLFilter::GetSelectedProtocol(Dart_NativeArguments args) {
  const uint8_t* protocol;
  unsigned length;
  SSL_get0_alpn_selected(ssl_, &protocol, &length);
  if (length == 0) {
    Dart_SetReturnValue(args, Dart_Null());
  } else {
    Dart_SetReturnValue(args, Dart_NewStringFromUTF8(protocol, length));
  }
}

void SSLFilter::FreeResources() {
  if (ssl_ != nullptr) {
    SSL_free(ssl_);
    ssl_ = nullptr;
  }
  if (socket_fd_ != Socket::kClosedFd) {
    Socket::ReleaseFd(socket_fd_);
    socket_fd_ = Socket::kClosedFd;
  }
  if (socket_ != nullptr) {
    socket_->Release();
    socket_ = nullptr;
  }
  if (prefetched_data_ != nullptr) {
    delete[] prefetched_data_;
    prefetched_data_ = nullptr;
  }
  prefetched_data_offset_ = 0;
  prefetched_data_length_ = 0;
  prefetched_data_has_tail_ = false;
  if (hostname_ != nullptr) {
    free(hostname_);
    hostname_ = nullptr;
  }
  for (int i = 0; i < kNumBuffers; ++i) {
    if (buffers_[i] != nullptr) {
      buffers_[i]->Release();
      buffers_[i] = nullptr;
    }
  }
}

SSLFilter::~SSLFilter() {
  FreeResources();
}

void SSLFilter::Destroy() {
  if (handshake_complete_ != nullptr) {
    Dart_DeletePersistentHandle(handshake_complete_);
    handshake_complete_ = nullptr;
  }
  if (bad_certificate_callback_ != nullptr) {
    Dart_DeletePersistentHandle(bad_certificate_callback_);
    bad_certificate_callback_ = nullptr;
  }
  if (transport_read_ != nullptr) {
    Dart_DeletePersistentHandle(transport_read_);
    transport_read_ = nullptr;
  }
  if (transport_write_ != nullptr) {
    Dart_DeletePersistentHandle(transport_write_);
    transport_write_ = nullptr;
  }
  FreeResources();
}

/* Read decrypted data from the filter to the circular buffer */
int SSLFilter::ProcessReadPlaintextBuffer(int start, int end) {
  int length = end - start;
  int bytes_processed = 0;
  if (SSL_LOG_DATA) {
    Syslog::Print("Entering ProcessReadPlaintextBuffer with %d bytes\n",
                  length);
  }
  if (length > 0) {
    last_os_error_ = 0;
    bytes_processed = SSL_read(
        ssl_, reinterpret_cast<char*>(buffers_[kReadPlaintext]->data() + start),
        length);
    if (callback_error != nullptr) {
      Dart_PropagateError(callback_error);
    }
    if (bytes_processed <= 0) {
      int error = SSL_get_error(ssl_, bytes_processed);
      if (SSL_LOG_DATA) {
        Syslog::Print("SSL_read returned error %d\n", error);
      }
      switch (error) {
        case SSL_ERROR_SYSCALL:
        case SSL_ERROR_SSL:
          last_ssl_status_ = bytes_processed;
          last_ssl_error_ = error;
          return -1;
        default:
          break;
      }
      bytes_processed = 0;
    }
  }
  if (SSL_LOG_DATA) {
    Syslog::Print("Leaving ProcessReadPlaintextBuffer read %d bytes\n",
                  bytes_processed);
  }
  return bytes_processed;
}

int SSLFilter::ProcessWritePlaintextBuffer(int start, int end) {
  int length = end - start;
  if (SSL_LOG_DATA) {
    Syslog::Print("Entering ProcessWritePlaintextBuffer with %d bytes\n",
                  length);
  }
  last_os_error_ = 0;
  int bytes_processed =
      SSL_write(ssl_, buffers_[kWritePlaintext]->data() + start, length);
  if (callback_error != nullptr) {
    Dart_PropagateError(callback_error);
  }
  if (bytes_processed <= 0) {
    int error = SSL_get_error(ssl_, bytes_processed);
    if (SSL_LOG_DATA) {
      Syslog::Print("SSL_write returned error %d\n", error);
    }
    switch (error) {
      case SSL_ERROR_SYSCALL:
      case SSL_ERROR_SSL:
        last_ssl_status_ = bytes_processed;
        last_ssl_error_ = error;
        return -1;
      default:
        return 0;
    }
  }
  if (SSL_LOG_DATA) {
    Syslog::Print("Leaving ProcessWritePlaintextBuffer wrote %d bytes\n",
                  bytes_processed);
  }
  return bytes_processed;
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
