// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "bin/secure_socket_filter.h"

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/secure_socket_utils.h"
#include "bin/security_context.h"
#include "platform/text_buffer.h"

// Return the error from the containing function if handle is an error handle.
#define RETURN_IF_ERROR(handle)                                                \
  {                                                                            \
    Dart_Handle __handle = handle;                                             \
    if (Dart_IsError((__handle))) {                                            \
      return __handle;                                                         \
    }                                                                          \
  }

namespace dart {
namespace bin {

bool SSLFilter::library_initialized_ = false;
// To protect library initialization.
Mutex* SSLFilter::mutex_ = new Mutex();
int SSLFilter::filter_ssl_index;

const intptr_t SSLFilter::kInternalBIOSize = 10 * KB;
const intptr_t SSLFilter::kApproximateSize =
    sizeof(SSLFilter) + (2 * SSLFilter::kInternalBIOSize);

static SSLFilter* GetFilter(Dart_NativeArguments args) {
  SSLFilter* filter;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(Dart_GetNativeInstanceField(
      dart_this, SSLFilter::kSSLFilterNativeFieldIndex,
      reinterpret_cast<intptr_t*>(&filter)));
  return filter;
}

static void DeleteFilter(void* isolate_data,
                         Dart_WeakPersistentHandle handle,
                         void* context_pointer) {
  SSLFilter* filter = reinterpret_cast<SSLFilter*>(context_pointer);
  filter->Release();
}

static Dart_Handle SetFilter(Dart_NativeArguments args, SSLFilter* filter) {
  ASSERT(filter != NULL);
  Dart_Handle dart_this = Dart_GetNativeArgument(args, 0);
  RETURN_IF_ERROR(dart_this);
  ASSERT(Dart_IsInstance(dart_this));
  Dart_Handle err = Dart_SetNativeInstanceField(
      dart_this, SSLFilter::kSSLFilterNativeFieldIndex,
      reinterpret_cast<intptr_t>(filter));
  RETURN_IF_ERROR(err);
  Dart_NewWeakPersistentHandle(dart_this, reinterpret_cast<void*>(filter),
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

  const char* host_name = NULL;
  // TODO(whesse): Is truncating a Dart string containing \0 what we want?
  ThrowIfError(Dart_StringToCString(host_name_object, &host_name));

  SSLCertContext* context = NULL;
  if (!Dart_IsNull(context_object)) {
    ThrowIfError(Dart_GetNativeInstanceField(
        context_object, SSLCertContext::kSecurityContextNativeFieldIndex,
        reinterpret_cast<intptr_t*>(&context)));
  }

  // The protocols_handle is guaranteed to be a valid Uint8List.
  // It will have the correct length encoding of the protocols array.
  ASSERT(!Dart_IsNull(protocols_handle));
  GetFilter(args)->Connect(host_name, context, is_server,
                           request_client_certificate,
                           require_client_certificate, protocols_handle);
}

void FUNCTION_NAME(SecureSocket_Destroy)(Dart_NativeArguments args) {
  SSLFilter* filter = GetFilter(args);
  // There are two paths that can clean up an SSLFilter object. First,
  // there is this explicit call to Destroy(), called from
  // _SecureFilter.destroy() in Dart code. After a call to destroy(), the Dart
  // code maintains the invariant that there will be no futher SSLFilter
  // requests sent to the IO Service. Therefore, the internals of the SSLFilter
  // are safe to deallocate, but not the SSLFilter itself, which is already
  // set up to be cleaned up by the finalizer.
  //
  // The second path is through the finalizer, which we have to do in case
  // some mishap prevents a call to _SecureFilter.destroy().
  filter->Destroy();
}

void FUNCTION_NAME(SecureSocket_Handshake)(Dart_NativeArguments args) {
  GetFilter(args)->Handshake();
}

void FUNCTION_NAME(SecureSocket_GetSelectedProtocol)(
    Dart_NativeArguments args) {
  GetFilter(args)->GetSelectedProtocol(args);
}

void FUNCTION_NAME(SecureSocket_Renegotiate)(Dart_NativeArguments args) {
  bool use_session_cache =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 1));
  bool request_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 2));
  bool require_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3));
  GetFilter(args)->Renegotiate(use_session_cache, request_client_certificate,
                               require_client_certificate);
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

void FUNCTION_NAME(SecureSocket_PeerCertificate)(Dart_NativeArguments args) {
  Dart_Handle cert = ThrowIfError(GetFilter(args)->PeerCertificate());
  Dart_SetReturnValue(args, cert);
}

void FUNCTION_NAME(SecureSocket_FilterPointer)(Dart_NativeArguments args) {
  SSLFilter* filter = GetFilter(args);
  // This filter pointer is passed to the IO Service thread. The IO Service
  // thread must Release() the pointer when it is done with it.
  filter->Retain();
  intptr_t filter_pointer = reinterpret_cast<intptr_t>(filter);
  Dart_SetReturnValue(args, Dart_NewInteger(filter_pointer));
}

/**
 * Pushes data through the SSL filter, reading and writing from circular
 * buffers shared with Dart.
 *
 * The Dart _SecureFilterImpl class contains 4 ExternalByteArrays used to
 * pass encrypted and plaintext data to and from the C++ SSLFilter object.
 *
 * ProcessFilter is called with a CObject array containing the pointer to
 * the SSLFilter, encoded as an int, and the start and end positions of the
 * valid data in the four circular buffers.  The function only reads from
 * the valid data area of the input buffers, and only writes to the free
 * area of the output buffers.  The function returns the new start and end
 * positions in the buffers, but it only updates start for input buffers, and
 * end for output buffers.  Therefore, the Dart thread can simultaneously
 * write to the free space and end pointer of input buffers, and read from
 * the data space of output buffers, and modify the start pointer.
 *
 * When ProcessFilter returns, the Dart thread is responsible for combining
 * the updated pointers from Dart and C++, to make the new valid state of
 * the circular buffer.
 */
CObject* SSLFilter::ProcessFilterRequest(const CObjectArray& request) {
  CObjectIntptr filter_object(request[0]);
  SSLFilter* filter = reinterpret_cast<SSLFilter*>(filter_object.Value());
  RefCntReleaseScope<SSLFilter> rs(filter);

  bool in_handshake = CObjectBool(request[1]).Value();
  int starts[SSLFilter::kNumBuffers];
  int ends[SSLFilter::kNumBuffers];
  for (int i = 0; i < SSLFilter::kNumBuffers; ++i) {
    starts[i] = CObjectInt32(request[2 * i + 2]).Value();
    ends[i] = CObjectInt32(request[2 * i + 3]).Value();
  }

  if (filter->ProcessAllBuffers(starts, ends, in_handshake)) {
    CObjectArray* result =
        new CObjectArray(CObject::NewArray(SSLFilter::kNumBuffers * 2));
    for (int i = 0; i < SSLFilter::kNumBuffers; ++i) {
      result->SetAt(2 * i, new CObjectInt32(CObject::NewInt32(starts[i])));
      result->SetAt(2 * i + 1, new CObjectInt32(CObject::NewInt32(ends[i])));
    }
    return result;
  } else {
    int32_t error_code = static_cast<int32_t>(ERR_peek_error());
    TextBuffer error_string(SecureSocketUtils::SSL_ERROR_MESSAGE_BUFFER_SIZE);
    SecureSocketUtils::FetchErrorString(filter->ssl_, &error_string);
    CObjectArray* result = new CObjectArray(CObject::NewArray(2));
    result->SetAt(0, new CObjectInt32(CObject::NewInt32(error_code)));
    result->SetAt(1, new CObjectString(CObject::NewString(error_string.buf())));
    return result;
  }
}

bool SSLFilter::ProcessAllBuffers(int starts[kNumBuffers],
                                  int ends[kNumBuffers],
                                  bool in_handshake) {
  for (int i = 0; i < kNumBuffers; ++i) {
    if (in_handshake && (i == kReadPlaintext || i == kWritePlaintext)) continue;
    int start = starts[i];
    int end = ends[i];
    int size = IsBufferEncrypted(i) ? encrypted_buffer_size_ : buffer_size_;
    if (start < 0 || end < 0 || start >= size || end >= size) {
      FATAL("Out-of-bounds internal buffer access in dart:io SecureSocket");
    }
    switch (i) {
      case kReadPlaintext:
      case kWriteEncrypted:
        // Write data to the circular buffer's free space.  If the buffer
        // is full, neither if statement is executed and nothing happens.
        if (start <= end) {
          // If the free space may be split into two segments,
          // then the first is [end, size), unless start == 0.
          // Then, since the last free byte is at position start - 2,
          // the interval is [end, size - 1).
          int buffer_end = (start == 0) ? size - 1 : size;
          int bytes = (i == kReadPlaintext)
                          ? ProcessReadPlaintextBuffer(end, buffer_end)
                          : ProcessWriteEncryptedBuffer(end, buffer_end);
          if (bytes < 0) return false;
          end += bytes;
          ASSERT(end <= size);
          if (end == size) end = 0;
        }
        if (start > end + 1) {
          int bytes = (i == kReadPlaintext)
                          ? ProcessReadPlaintextBuffer(end, start - 1)
                          : ProcessWriteEncryptedBuffer(end, start - 1);
          if (bytes < 0) return false;
          end += bytes;
          ASSERT(end < start);
        }
        ends[i] = end;
        break;
      case kReadEncrypted:
      case kWritePlaintext:
        // Read/Write data from circular buffer.  If the buffer is empty,
        // neither if statement's condition is true.
        if (end < start) {
          // Data may be split into two segments.  In this case,
          // the first is [start, size).
          int bytes = (i == kReadEncrypted)
                          ? ProcessReadEncryptedBuffer(start, size)
                          : ProcessWritePlaintextBuffer(start, size);
          if (bytes < 0) return false;
          start += bytes;
          ASSERT(start <= size);
          if (start == size) start = 0;
        }
        if (start < end) {
          int bytes = (i == kReadEncrypted)
                          ? ProcessReadEncryptedBuffer(start, end)
                          : ProcessWritePlaintextBuffer(start, end);
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

Dart_Handle SSLFilter::Init(Dart_Handle dart_this) {
  if (!library_initialized_) {
    InitializeLibrary();
  }
  ASSERT(string_start_ == NULL);
  string_start_ = Dart_NewPersistentHandle(DartUtils::NewString("start"));
  ASSERT(string_start_ != NULL);
  ASSERT(string_length_ == NULL);
  string_length_ = Dart_NewPersistentHandle(DartUtils::NewString("length"));
  ASSERT(string_length_ != NULL);
  ASSERT(bad_certificate_callback_ == NULL);
  bad_certificate_callback_ = Dart_NewPersistentHandle(Dart_Null());
  ASSERT(bad_certificate_callback_ != NULL);
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

  Dart_Handle encrypted_size_string = DartUtils::NewString("ENCRYPTED_SIZE");
  RETURN_IF_ERROR(encrypted_size_string);

  Dart_Handle dart_encrypted_buffer_size =
      Dart_GetField(secure_filter_impl_type, encrypted_size_string);
  RETURN_IF_ERROR(dart_encrypted_buffer_size);

  int64_t encrypted_buffer_size = 0;
  err = Dart_IntegerToInt64(dart_encrypted_buffer_size, &encrypted_buffer_size);
  RETURN_IF_ERROR(err);

  if (buffer_size <= 0 || buffer_size > 1 * MB) {
    FATAL("Invalid buffer size in _ExternalBuffer");
  }
  if (encrypted_buffer_size <= 0 || encrypted_buffer_size > 1 * MB) {
    FATAL("Invalid encrypted buffer size in _ExternalBuffer");
  }
  buffer_size_ = static_cast<int>(buffer_size);
  encrypted_buffer_size_ = static_cast<int>(encrypted_buffer_size);

  Dart_Handle data_identifier = DartUtils::NewString("data");
  RETURN_IF_ERROR(data_identifier);

  for (int i = 0; i < kNumBuffers; i++) {
    int size = IsBufferEncrypted(i) ? encrypted_buffer_size_ : buffer_size_;
    buffers_[i] = new uint8_t[size];
    ASSERT(buffers_[i] != NULL);
    dart_buffer_objects_[i] = NULL;
  }

  Dart_Handle result = Dart_Null();
  for (int i = 0; i < kNumBuffers; ++i) {
    int size = IsBufferEncrypted(i) ? encrypted_buffer_size_ : buffer_size_;
    result = Dart_ListGetAt(dart_buffers_object, i);
    if (Dart_IsError(result)) {
      break;
    }

    dart_buffer_objects_[i] = Dart_NewPersistentHandle(result);
    ASSERT(dart_buffer_objects_[i] != NULL);
    Dart_Handle data =
        Dart_NewExternalTypedData(Dart_TypedData_kUint8, buffers_[i], size);
    if (Dart_IsError(data)) {
      result = data;
      break;
    }
    result = Dart_HandleFromPersistent(dart_buffer_objects_[i]);
    if (Dart_IsError(result)) {
      break;
    }
    result = Dart_SetField(result, data_identifier, data);
    if (Dart_IsError(result)) {
      break;
    }
  }

  // Caller handles cleanup on an error.
  return result;
}

void SSLFilter::RegisterHandshakeCompleteCallback(Dart_Handle complete) {
  ASSERT(NULL == handshake_complete_);
  handshake_complete_ = Dart_NewPersistentHandle(complete);

  ASSERT(handshake_complete_ != NULL);
}

void SSLFilter::RegisterBadCertificateCallback(Dart_Handle callback) {
  ASSERT(bad_certificate_callback_ != NULL);
  Dart_DeletePersistentHandle(bad_certificate_callback_);
  bad_certificate_callback_ = Dart_NewPersistentHandle(callback);
  ASSERT(bad_certificate_callback_ != NULL);
}

Dart_Handle SSLFilter::PeerCertificate() {
  X509* ca = SSL_get_peer_certificate(ssl_);
  if (ca == NULL) {
    return Dart_Null();
  }
  return X509Helper::WrappedX509Certificate(ca);
}

void SSLFilter::InitializeLibrary() {
  MutexLocker locker(mutex_);
  if (!library_initialized_) {
    SSL_library_init();
    filter_ssl_index = SSL_get_ex_new_index(0, NULL, NULL, NULL, NULL);
    ASSERT(filter_ssl_index >= 0);
    library_initialized_ = true;
  }
}

void SSLFilter::Connect(const char* hostname,
                        SSLCertContext* context,
                        bool is_server,
                        bool request_client_certificate,
                        bool require_client_certificate,
                        Dart_Handle protocols_handle) {
  is_server_ = is_server;
  if (in_handshake_) {
    FATAL("Connect called twice on the same _SecureFilter.");
  }

  int status;
  int error;
  BIO* ssl_side;
  status = BIO_new_bio_pair(&ssl_side, kInternalBIOSize, &socket_side_,
                            kInternalBIOSize);
  SecureSocketUtils::CheckStatusSSL(status, "TlsException", "BIO_new_bio_pair",
                                    ssl_);

  ASSERT(context != NULL);
  ASSERT(context->context() != NULL);
  ssl_ = SSL_new(context->context());
  SSL_set_bio(ssl_, ssl_side, ssl_side);
  SSL_set_mode(ssl_, SSL_MODE_AUTO_RETRY);  // TODO(whesse): Is this right?
  SSL_set_ex_data(ssl_, filter_ssl_index, this);
  context->RegisterCallbacks(ssl_);

  if (is_server_) {
    int certificate_mode =
        request_client_certificate ? SSL_VERIFY_PEER : SSL_VERIFY_NONE;
    if (require_client_certificate) {
      certificate_mode |= SSL_VERIFY_FAIL_IF_NO_PEER_CERT;
    }
    SSL_set_verify(ssl_, certificate_mode, NULL);
  } else {
    SSLCertContext::SetAlpnProtocolList(protocols_handle, ssl_, NULL, false);
    status = SSL_set_tlsext_host_name(ssl_, hostname);
    SecureSocketUtils::CheckStatusSSL(status, "TlsException",
                                      "Set SNI host name", ssl_);
    // Sets the hostname in the certificate-checking object, so it is checked
    // against the certificate presented by the server.
    X509_VERIFY_PARAM* certificate_checking_parameters = SSL_get0_param(ssl_);
    hostname_ = strdup(hostname);
    X509_VERIFY_PARAM_set_flags(
        certificate_checking_parameters,
        X509_V_FLAG_PARTIAL_CHAIN | X509_V_FLAG_TRUSTED_FIRST);
    X509_VERIFY_PARAM_set_hostflags(certificate_checking_parameters, 0);
    status = X509_VERIFY_PARAM_set1_host(certificate_checking_parameters,
                                         hostname_, strlen(hostname_));
    SecureSocketUtils::CheckStatusSSL(
        status, "TlsException", "Set hostname for certificate checking", ssl_);
  }
  // Make the connection:
  if (is_server_) {
    status = SSL_accept(ssl_);
    if (SSL_LOG_STATUS) {
      Log::Print("SSL_accept status: %d\n", status);
    }
    if (status != 1) {
      // TODO(whesse): expect a needs-data error here.  Handle other errors.
      error = SSL_get_error(ssl_, status);
      if (SSL_LOG_STATUS) {
        Log::Print("SSL_accept error: %d\n", error);
      }
    }
  } else {
    status = SSL_connect(ssl_);
    if (SSL_LOG_STATUS) {
      Log::Print("SSL_connect status: %d\n", status);
    }
    if (status != 1) {
      // TODO(whesse): expect a needs-data error here.  Handle other errors.
      error = SSL_get_error(ssl_, status);
      if (SSL_LOG_STATUS) {
        Log::Print("SSL_connect error: %d\n", error);
      }
    }
  }
  Handshake();
}

void SSLFilter::Handshake() {
  // Try and push handshake along.
  int status;
  status = SSL_do_handshake(ssl_);
  if (callback_error != NULL) {
    // The SSL_do_handshake will try performing a handshake and might call
    // a CertificateCallback. If the certificate validation
    // failed the 'callback_error" will be set by the certificateCallback
    // logic and we propagate the error"
    Dart_PropagateError(callback_error);
  }
  if (SSL_want_write(ssl_) || SSL_want_read(ssl_)) {
    in_handshake_ = true;
    return;
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
      Log::Print("Handshake verification status: %d\n", result);
      X509* peer_certificate = SSL_get_peer_certificate(ssl_);
      if (peer_certificate == NULL) {
        Log::Print("No peer certificate received\n");
      } else {
        X509_NAME* s_name = X509_get_subject_name(peer_certificate);
        printf("Peer certificate SN: ");
        X509_NAME_print_ex_fp(stdout, s_name, 4, 0);
        printf("\n");
      }
    }
    ThrowIfError(Dart_InvokeClosure(
        Dart_HandleFromPersistent(handshake_complete_), 0, NULL));
    in_handshake_ = false;
  }
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

void SSLFilter::Renegotiate(bool use_session_cache,
                            bool request_client_certificate,
                            bool require_client_certificate) {
  // The SSL_REQUIRE_CERTIFICATE option only takes effect if the
  // SSL_REQUEST_CERTIFICATE option is also set, so set it.
  request_client_certificate =
      request_client_certificate || require_client_certificate;
  // TODO(24070, 24069): Implement setting the client certificate parameters,
  //   and triggering rehandshake.
}

void SSLFilter::FreeResources() {
  if (ssl_ != NULL) {
    SSL_free(ssl_);
    ssl_ = NULL;
  }
  if (socket_side_ != NULL) {
    BIO_free(socket_side_);
    socket_side_ = NULL;
  }
  if (hostname_ != NULL) {
    free(hostname_);
    hostname_ = NULL;
  }
  for (int i = 0; i < kNumBuffers; ++i) {
    if (buffers_[i] != NULL) {
      delete[] buffers_[i];
      buffers_[i] = NULL;
    }
  }
}

SSLFilter::~SSLFilter() {
  FreeResources();
}

void SSLFilter::Destroy() {
  for (int i = 0; i < kNumBuffers; ++i) {
    if (dart_buffer_objects_[i] != NULL) {
      Dart_DeletePersistentHandle(dart_buffer_objects_[i]);
      dart_buffer_objects_[i] = NULL;
    }
  }
  if (string_start_ != NULL) {
    Dart_DeletePersistentHandle(string_start_);
    string_start_ = NULL;
  }
  if (string_length_ != NULL) {
    Dart_DeletePersistentHandle(string_length_);
    string_length_ = NULL;
  }
  if (handshake_complete_ != NULL) {
    Dart_DeletePersistentHandle(handshake_complete_);
    handshake_complete_ = NULL;
  }
  if (bad_certificate_callback_ != NULL) {
    Dart_DeletePersistentHandle(bad_certificate_callback_);
    bad_certificate_callback_ = NULL;
  }
  FreeResources();
}

/* Read decrypted data from the filter to the circular buffer */
int SSLFilter::ProcessReadPlaintextBuffer(int start, int end) {
  int length = end - start;
  int bytes_processed = 0;
  if (length > 0) {
    bytes_processed = SSL_read(
        ssl_, reinterpret_cast<char*>((buffers_[kReadPlaintext] + start)),
        length);
    if (bytes_processed < 0) {
      int error = SSL_get_error(ssl_, bytes_processed);
      USE(error);
      bytes_processed = 0;
    }
  }
  return bytes_processed;
}

int SSLFilter::ProcessWritePlaintextBuffer(int start, int end) {
  int length = end - start;
  int bytes_processed =
      SSL_write(ssl_, buffers_[kWritePlaintext] + start, length);
  if (bytes_processed < 0) {
    if (SSL_LOG_DATA) {
      Log::Print("SSL_write returned error %d\n", bytes_processed);
    }
    return 0;
  }
  return bytes_processed;
}

/* Read encrypted data from the circular buffer to the filter */
int SSLFilter::ProcessReadEncryptedBuffer(int start, int end) {
  int length = end - start;
  if (SSL_LOG_DATA)
    Log::Print("Entering ProcessReadEncryptedBuffer with %d bytes\n", length);
  int bytes_processed = 0;
  if (length > 0) {
    bytes_processed =
        BIO_write(socket_side_, buffers_[kReadEncrypted] + start, length);
    if (bytes_processed <= 0) {
      bool retry = BIO_should_retry(socket_side_);
      if (!retry) {
        if (SSL_LOG_DATA)
          Log::Print("BIO_write failed in ReadEncryptedBuffer\n");
      }
      bytes_processed = 0;
    }
  }
  if (SSL_LOG_DATA)
    Log::Print("Leaving ProcessReadEncryptedBuffer wrote %d bytes\n",
               bytes_processed);
  return bytes_processed;
}

int SSLFilter::ProcessWriteEncryptedBuffer(int start, int end) {
  int length = end - start;
  int bytes_processed = 0;
  if (length > 0) {
    bytes_processed =
        BIO_read(socket_side_, buffers_[kWriteEncrypted] + start, length);
    if (bytes_processed < 0) {
      if (SSL_LOG_DATA)
        Log::Print("WriteEncrypted BIO_read returned error %d\n",
                   bytes_processed);
      return 0;
    } else {
      if (SSL_LOG_DATA)
        Log::Print("WriteEncrypted  BIO_read wrote %d bytes\n",
                   bytes_processed);
    }
  }
  return bytes_processed;
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
