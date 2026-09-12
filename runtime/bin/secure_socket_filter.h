// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SECURE_SOCKET_FILTER_H_
#define RUNTIME_BIN_SECURE_SOCKET_FILTER_H_

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>

#include <memory>

#include "bin/builtin.h"
#include "bin/reference_counting.h"
#include "bin/security_context.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

/* These are defined in root_certificates.cc. */
extern const unsigned char* root_certificates_pem;
extern unsigned int root_certificates_pem_length;

class X509TrustState {
 public:
  X509TrustState(const X509* x509, bool is_trusted)
      : x509_(x509), is_trusted_(is_trusted) {}

  const X509* x509() const { return x509_; }
  bool is_trusted() const { return is_trusted_; }

 private:
  const X509* x509_;
  bool is_trusted_;

  DISALLOW_COPY_AND_ASSIGN(X509TrustState);
};

// Owns one immutable generation of a plaintext ring's backing storage. The
// SSLFilter and the Dart ExternalUint8List each retain a reference, so a
// replaced generation remains valid until neither side can access it.
class SSLFilterBuffer : public ReferenceCounted<SSLFilterBuffer> {
 public:
  explicit SSLFilterBuffer(int size);
  ~SSLFilterBuffer() override;

  uint8_t* data() const { return data_; }
  int size() const { return size_; }

 private:
  uint8_t* const data_;
  const int size_;

  DISALLOW_COPY_AND_ASSIGN(SSLFilterBuffer);
};

// Owns the BoringSSL connection and two shared plaintext rings. Its custom BIO
// uses a retained native socket when available and falls back to Dart RawSocket
// callbacks for other implementations. It never owns a ciphertext queue. All
// TLS operations are serialized by the Dart isolate.
class SSLFilter : public ReferenceCounted<SSLFilter> {
 public:
  static void Init();
  static void Cleanup();

  // These enums must agree with those in sdk/lib/io/secure_socket.dart.
  enum BufferIndex { kReadPlaintext, kWritePlaintext, kNumBuffers };

  // TLS upgrades may provide bytes which were read before the socket was
  // handed to SecureSocket. Keep only a small, bounded chunk in native memory
  // while those bytes are drained. Normal socket traffic bypasses this queue.
  static constexpr intptr_t kMaxPrefetchedData = 16 * KB;

  static const intptr_t kApproximateSize;
  static constexpr int kSSLFilterNativeFieldIndex = 0;

  SSLFilter()
      : callback_error(nullptr),
        ssl_(nullptr),
        socket_(nullptr),
        socket_fd_(Socket::kClosedFd),
        transport_read_(nullptr),
        transport_write_(nullptr),
        prefetched_data_(nullptr),
        prefetched_data_offset_(0),
        prefetched_data_length_(0),
        prefetched_data_has_tail_(false),
        socket_read_bytes_(0),
        socket_write_bytes_(0),
        max_buffer_size_(0),
        last_ssl_status_(0),
        last_ssl_error_(SSL_ERROR_NONE),
        last_os_error_(0),
        handshake_complete_(nullptr),
        bad_certificate_callback_(nullptr),
        in_handshake_(false),
        hostname_(nullptr) {
    for (int i = 0; i < kNumBuffers; ++i) {
      buffers_[i] = nullptr;
    }
  }

  ~SSLFilter();

  char* hostname() const { return hostname_; }
  bool is_server() const { return is_server_; }
  bool is_client() const { return !is_server_; }
  Dart_Handle Init(Dart_Handle dart_this);
  void Connect(const char* hostname,
               SSLCertContext* context,
               bool is_server,
               bool request_client_certificate,
               bool require_client_certificate,
               Dart_Handle protocols_handle,
               class Socket* socket,
               Dart_Handle transport_read,
               Dart_Handle transport_write);
  void Destroy();
  void FreeResources();
  void MarkAsTrusted(Dart_NativeArguments args);
  int Handshake(Dart_Port reply_port);
  void GetSelectedProtocol(Dart_NativeArguments args);
  void RegisterHandshakeCompleteCallback(Dart_Handle handshake_complete);
  void RegisterBadCertificateCallback(Dart_Handle callback);
  void RegisterKeyLogPort(Dart_Port key_log_port);
  Dart_Port key_log_port() { return key_log_port_; }
  Dart_Handle bad_certificate_callback() {
    return Dart_HandleFromPersistent(bad_certificate_callback_);
  }
  int ProcessReadPlaintextBuffer(int start, int end);
  int ProcessWritePlaintextBuffer(int start, int end);
  bool ProcessAllBuffers(int starts[kNumBuffers],
                         int ends[kNumBuffers],
                         int sizes[kNumBuffers]);
  Dart_Handle GrowBuffer(int buffer_index,
                         int start,
                         int end,
                         int old_size,
                         int new_size);
  intptr_t QueuePrefetchedData(Dart_Handle data, intptr_t offset);
  bool HasPrefetchedData() const {
    return prefetched_data_offset_ < prefetched_data_length_;
  }
  bool HasPendingPlaintext() const {
    return ssl_ != nullptr && SSL_pending(ssl_) > 0;
  }
  bool WantsWrite() const { return ssl_ != nullptr && SSL_want_write(ssl_); }
  bool HasPendingSocketWrite() const;
  intptr_t TakeSocketReadBytes() {
    const intptr_t result = socket_read_bytes_;
    socket_read_bytes_ = 0;
    return result;
  }
  intptr_t TakeSocketWriteBytes() {
    const intptr_t result = socket_write_bytes_;
    socket_write_bytes_ = 0;
    return result;
  }
  void ThrowFilterError();
  static bool IsValidBufferRange(int start, int end, int size) {
    return start >= 0 && end >= 0 && start < size && end < size;
  }
  static intptr_t BoundedPrefetchedDataLength(intptr_t data_length,
                                              intptr_t offset) {
    if (data_length < 0 || offset < 0 || offset > data_length) return -1;
    const intptr_t remaining = data_length - offset;
    return remaining > kMaxPrefetchedData ? kMaxPrefetchedData : remaining;
  }
  static bool PrefetchedDataHasTail(intptr_t data_length,
                                    intptr_t offset,
                                    intptr_t chunk_length) {
    if (data_length < 0 || offset < 0 || offset > data_length ||
        chunk_length < 0 || chunk_length > data_length - offset) {
      return false;
    }
    return chunk_length < data_length - offset;
  }
  Dart_Handle PeerCertificate();
  static void InitializeLibrary();
  Dart_Handle callback_error;
  void SetCallbackError(Dart_Handle error) {
    if (callback_error == nullptr) callback_error = error;
  }

  // The index of the external data field in _ssl that points to the SSLFilter.
  static int filter_ssl_index;
  // The index of the external data field in _ssl that points to the
  // SSLCertContext.
  static int ssl_cert_context_index;

  const X509TrustState* certificate_trust_state() {
    return certificate_trust_state_.get();
  }
  Dart_Port reply_port() const { return reply_port_; }
  static Dart_Port TrustEvaluateReplyPort();

 private:
  static bool library_initialized_;
  static Mutex* mutex_;  // To protect library initialization.
  static Dart_Port trust_evaluate_reply_port_;
  static BIO_METHOD* socket_bio_method_;

  static int SocketBIORead(BIO* bio, char* output, int length);
  static int SocketBIOWrite(BIO* bio,
                            const char* input,
                            size_t length,
                            size_t* written);
  static long SocketBIOControl(BIO* bio,
                               int command,
                               long argument,
                               void* pointer);

  SSL* ssl_;
  // The native socket and its underlying fd/handle are retained until SSL
  // (and therefore its BIO) has been freed. socket_fd_ is cached at Connect
  // time and protected via Socket::RetainFd / Socket::ReleaseFd to avoid
  // Use-After-Free on platforms where fd is a heap Handle* (Windows/Fuchsia).
  // For non-native RawSocket implementations the two persistent closures
  // provide the transport instead.
  class Socket* socket_;
  intptr_t socket_fd_;
  Dart_PersistentHandle transport_read_;
  Dart_PersistentHandle transport_write_;
  uint8_t* prefetched_data_;
  intptr_t prefetched_data_offset_;
  intptr_t prefetched_data_length_;
  // Prevents the BIO from reading the socket between bounded chunks from the
  // same Dart bufferedData value.
  bool prefetched_data_has_tail_;
  intptr_t socket_read_bytes_;
  intptr_t socket_write_bytes_;
  // Currently only one(root) certificate is evaluated via
  // TrustEvaluate mechanism.
  std::unique_ptr<X509TrustState> certificate_trust_state_;

  SSLFilterBuffer* buffers_[kNumBuffers];
  int max_buffer_size_;
  int last_ssl_status_;
  int last_ssl_error_;
  int last_os_error_;
  Dart_PersistentHandle handshake_complete_;
  Dart_PersistentHandle bad_certificate_callback_;
  bool in_handshake_;
  bool is_server_;
  char* hostname_;

  Dart_Port reply_port_ = ILLEGAL_PORT;
  Dart_Port key_log_port_ = ILLEGAL_PORT;

  Dart_Handle InitializeBuffers(Dart_Handle dart_this);
  void InitializePlatformData();

  DISALLOW_COPY_AND_ASSIGN(SSLFilter);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SECURE_SOCKET_FILTER_H_
