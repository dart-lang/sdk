// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SECURE_SOCKET_UTILS_H_
#define RUNTIME_BIN_SECURE_SOCKET_UTILS_H_

#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/pkcs12.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "platform/globals.h"

#include "bin/dartutils.h"
#include "platform/text_buffer.h"

namespace dart {
namespace bin {

const bool SSL_LOG_STATUS = false;
const bool SSL_LOG_DATA = false;
const bool SSL_LOG_CERTS = false;

class SecureSocketUtils : public AllStatic {
 public:
  static const int SSL_ERROR_MESSAGE_BUFFER_SIZE = 1000;

  static void ThrowIOException(int status,
                               const char* exception_type,
                               const char* message,
                               const SSL* ssl);

  static void CheckStatusSSL(int status,
                             const char* type,
                             const char* message,
                             const SSL* ssl);

  static void CheckStatus(int status, const char* type, const char* message);

  static bool NoPEMStartLine() {
    uint32_t last_error = ERR_peek_last_error();
    return (ERR_GET_LIB(last_error) == ERR_LIB_PEM) &&
           (ERR_GET_REASON(last_error) == PEM_R_NO_START_LINE);
  }

  static void FetchErrorString(const SSL* ssl, TextBuffer* text_buffer);
};

// Where the argument to the constructor is the handle for an object
// implementing List<int>, this class creates a scope in which a memory-backed
// BIO is allocated. Leaving the scope cleans up the BIO and the buffer that
// was used to create it.
//
// Do not make Dart_ API calls while in a ScopedMemBIO.
// Do not call Dart_PropagateError while in a ScopedMemBIO.
class ScopedMemBIO {
 public:
  explicit ScopedMemBIO(Dart_Handle object) {
    if (!Dart_IsTypedData(object) && !Dart_IsList(object)) {
      Dart_ThrowException(
          DartUtils::NewDartArgumentError("Argument is not a List<int>"));
    }

    uint8_t* bytes = NULL;
    intptr_t bytes_len = 0;
    bool is_typed_data = false;
    if (Dart_IsTypedData(object)) {
      is_typed_data = true;
      Dart_TypedData_Type typ;
      ThrowIfError(Dart_TypedDataAcquireData(
          object, &typ, reinterpret_cast<void**>(&bytes), &bytes_len));
    } else {
      ASSERT(Dart_IsList(object));
      ThrowIfError(Dart_ListLength(object, &bytes_len));
      bytes = Dart_ScopeAllocate(bytes_len);
      ASSERT(bytes != NULL);
      ThrowIfError(Dart_ListGetAsBytes(object, 0, bytes, bytes_len));
    }

    object_ = object;
    bytes_ = bytes;
    bytes_len_ = bytes_len;
    bio_ = BIO_new_mem_buf(bytes, bytes_len);
    ASSERT(bio_ != NULL);
    is_typed_data_ = is_typed_data;
  }

  ~ScopedMemBIO() {
    ASSERT(bio_ != NULL);
    if (is_typed_data_) {
      BIO_free(bio_);
      ThrowIfError(Dart_TypedDataReleaseData(object_));
    } else {
      BIO_free(bio_);
    }
  }

  BIO* bio() {
    ASSERT(bio_ != NULL);
    return bio_;
  }

 private:
  Dart_Handle object_;
  uint8_t* bytes_;
  intptr_t bytes_len_;
  BIO* bio_;
  bool is_typed_data_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ScopedMemBIO);
};

template <typename T, void (*free_func)(T*)>
class ScopedSSLType {
 public:
  explicit ScopedSSLType(T* obj) : obj_(obj) {}

  ~ScopedSSLType() {
    if (obj_ != NULL) {
      free_func(obj_);
    }
  }

  T* get() { return obj_; }
  const T* get() const { return obj_; }

  T* release() {
    T* result = obj_;
    obj_ = NULL;
    return result;
  }

 private:
  T* obj_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ScopedSSLType);
};

template <typename T, typename E, void (*func)(E*)>
class ScopedSSLStackType {
 public:
  explicit ScopedSSLStackType(T* obj) : obj_(obj) {}

  ~ScopedSSLStackType() {
    if (obj_ != NULL) {
      sk_pop_free(reinterpret_cast<_STACK*>(obj_),
                  reinterpret_cast<void (*)(void*)>(func));
    }
  }

  T* get() { return obj_; }
  const T* get() const { return obj_; }

  T* release() {
    T* result = obj_;
    obj_ = NULL;
    return result;
  }

 private:
  T* obj_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ScopedSSLStackType);
};

typedef ScopedSSLType<PKCS12, PKCS12_free> ScopedPKCS12;
typedef ScopedSSLType<X509, X509_free> ScopedX509;
typedef ScopedSSLStackType<STACK_OF(X509), X509, X509_free> ScopedX509Stack;

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SECURE_SOCKET_UTILS_H_
