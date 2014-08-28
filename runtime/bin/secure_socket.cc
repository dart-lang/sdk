// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/secure_socket.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>

#include <key.h>
#include <keyt.h>
#include <nss.h>
#include <pk11pub.h>
#include <prerror.h>
#include <prinit.h>
#include <prnetdb.h>
#include <secmod.h>
#include <ssl.h>
#include <sslproto.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/lockers.h"
#include "bin/net/nss_memio.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/utils.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

bool SSLFilter::library_initialized_ = false;
// To protect library initialization.
Mutex* SSLFilter::mutex_ = new Mutex();
// The password is needed when creating secure server sockets.  It can
// be null if only secure client sockets are used.
const char* SSLFilter::password_ = NULL;

static const int kSSLFilterNativeFieldIndex = 0;


/* Handle an error reported from the NSS library. */
static void ThrowPRException(const char* exception_type,
                             const char* message,
                             bool free_message = false) {
  PRErrorCode error_code = PR_GetError();
  const char* error_message = PR_ErrorToString(error_code, PR_LANGUAGE_EN);
  OSError os_error_struct(error_code, error_message, OSError::kNSS);
  Dart_Handle os_error = DartUtils::NewDartOSError(&os_error_struct);
  Dart_Handle exception =
      DartUtils::NewDartIOException(exception_type, message, os_error);
  if (free_message) {
    free(const_cast<char*>(message));
  }
  Dart_ThrowException(exception);
}


static void ThrowCertificateException(const char* format,
                                      const char* certificate_name) {
  int length = strlen(certificate_name);
  length += strlen(format);
  char* message = reinterpret_cast<char*>(malloc(length + 1));
  if (message == NULL) {
    FATAL("Out of memory formatting CertificateException for throwing");
  }
  snprintf(message, length + 1, format, certificate_name);
  message[length] = '\0';
  ThrowPRException("CertificateException", message, true);
}


static SSLFilter* GetFilter(Dart_NativeArguments args) {
  SSLFilter* filter;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(Dart_GetNativeInstanceField(
      dart_this,
      kSSLFilterNativeFieldIndex,
      reinterpret_cast<intptr_t*>(&filter)));
  return filter;
}


static void SetFilter(Dart_NativeArguments args, SSLFilter* filter) {
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(Dart_SetNativeInstanceField(
      dart_this,
      kSSLFilterNativeFieldIndex,
      reinterpret_cast<intptr_t>(filter)));
}


void FUNCTION_NAME(SecureSocket_Init)(Dart_NativeArguments args) {
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  SSLFilter* filter = new SSLFilter;
  SetFilter(args, filter);
  filter->Init(dart_this);
}


void FUNCTION_NAME(SecureSocket_Connect)(Dart_NativeArguments args) {
  Dart_Handle host_name_object = ThrowIfError(Dart_GetNativeArgument(args, 1));
  Dart_Handle host_sockaddr_storage_object =
      ThrowIfError(Dart_GetNativeArgument(args, 2));
  Dart_Handle port_object = ThrowIfError(Dart_GetNativeArgument(args, 3));
  bool is_server = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 4));
  Dart_Handle certificate_name_object =
      ThrowIfError(Dart_GetNativeArgument(args, 5));
  bool request_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 6));
  bool require_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 7));
  bool send_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 8));

  const char* host_name = NULL;
  // TODO(whesse): Is truncating a Dart string containing \0 what we want?
  ThrowIfError(Dart_StringToCString(host_name_object, &host_name));

  RawAddr raw_addr;
  SocketAddress::GetSockAddr(host_sockaddr_storage_object, &raw_addr);

  int64_t port;
  if (!DartUtils::GetInt64Value(port_object, &port)) {
    FATAL("The range of port_object was checked in Dart - it cannot fail here");
  }

  const char* certificate_name = NULL;
  if (Dart_IsString(certificate_name_object)) {
    ThrowIfError(Dart_StringToCString(certificate_name_object,
                                      &certificate_name));
  }
  // If this is a server connection, it must have a certificate to connect with.
  ASSERT(!is_server || certificate_name != NULL);

  GetFilter(args)->Connect(host_name,
                           &raw_addr,
                           static_cast<int>(port),
                           is_server,
                           certificate_name,
                           request_client_certificate,
                           require_client_certificate,
                           send_client_certificate);
}


void FUNCTION_NAME(SecureSocket_Destroy)(Dart_NativeArguments args) {
  SSLFilter* filter = GetFilter(args);
  SetFilter(args, NULL);
  filter->Destroy();
  delete filter;
}


void FUNCTION_NAME(SecureSocket_Handshake)(Dart_NativeArguments args) {
  GetFilter(args)->Handshake();
}


void FUNCTION_NAME(SecureSocket_Renegotiate)(Dart_NativeArguments args) {
  bool use_session_cache =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 1));
  bool request_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 2));
  bool require_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3));
  GetFilter(args)->Renegotiate(use_session_cache,
                               request_client_certificate,
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
  Dart_Handle callback =
      ThrowIfError(Dart_GetNativeArgument(args, 1));
  if (!Dart_IsClosure(callback) && !Dart_IsNull(callback)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Illegal argument to RegisterBadCertificateCallback"));
  }
  GetFilter(args)->RegisterBadCertificateCallback(callback);
}


void FUNCTION_NAME(SecureSocket_InitializeLibrary)
    (Dart_NativeArguments args) {
  Dart_Handle certificate_database_object =
      ThrowIfError(Dart_GetNativeArgument(args, 0));
  // Check that the type is string, and get the UTF-8 C string value from it.
  const char* certificate_database = NULL;
  if (Dart_IsString(certificate_database_object)) {
    ThrowIfError(Dart_StringToCString(certificate_database_object,
                                      &certificate_database));
  } else if (!Dart_IsNull(certificate_database_object)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Non-String certificate directory argument to SetCertificateDatabase"));
  }
  // Leave certificate_database as NULL if no value was provided.

  Dart_Handle password_object = ThrowIfError(Dart_GetNativeArgument(args, 1));
  // Check that the type is string or null,
  // and get the UTF-8 C string value from it.
  const char* password = NULL;
  if (Dart_IsString(password_object)) {
    ThrowIfError(Dart_StringToCString(password_object, &password));
  } else if (Dart_IsNull(password_object)) {
    // Pass the empty string as the password.
    password = "";
  } else {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Password argument to SetCertificateDatabase is not a String or null"));
  }

  Dart_Handle builtin_roots_object =
      ThrowIfError(Dart_GetNativeArgument(args, 2));
  // Check that the type is boolean, and get the boolean value from it.
  bool builtin_roots = true;
  if (Dart_IsBoolean(builtin_roots_object)) {
    ThrowIfError(Dart_BooleanValue(builtin_roots_object, &builtin_roots));
  } else {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "UseBuiltinRoots argument to SetCertificateDatabase is not a bool"));
  }

  SSLFilter::InitializeLibrary(certificate_database, password, builtin_roots);
}


void FUNCTION_NAME(SecureSocket_PeerCertificate)
    (Dart_NativeArguments args) {
  Dart_SetReturnValue(args, GetFilter(args)->PeerCertificate());
}


void FUNCTION_NAME(SecureSocket_FilterPointer)(Dart_NativeArguments args) {
  intptr_t filter_pointer = reinterpret_cast<intptr_t>(GetFilter(args));
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
  bool in_handshake = CObjectBool(request[1]).Value();
  int starts[SSLFilter::kNumBuffers];
  int ends[SSLFilter::kNumBuffers];
  for (int i = 0; i < SSLFilter::kNumBuffers; ++i) {
    starts[i] = CObjectInt32(request[2 * i + 2]).Value();
    ends[i] = CObjectInt32(request[2 * i + 3]).Value();
  }

  if (filter->ProcessAllBuffers(starts, ends, in_handshake)) {
    CObjectArray* result = new CObjectArray(
        CObject::NewArray(SSLFilter::kNumBuffers * 2));
    for (int i = 0; i < SSLFilter::kNumBuffers; ++i) {
      result->SetAt(2 * i, new CObjectInt32(CObject::NewInt32(starts[i])));
      result->SetAt(2 * i + 1, new CObjectInt32(CObject::NewInt32(ends[i])));
    }
    return result;
  } else {
    PRErrorCode error_code = PR_GetError();
    const char* error_message = PR_ErrorToString(error_code, PR_LANGUAGE_EN);
    CObjectArray* result = new CObjectArray(CObject::NewArray(2));
    result->SetAt(0, new CObjectInt32(CObject::NewInt32(error_code)));
    result->SetAt(1, new CObjectString(CObject::NewString(error_message)));
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
    int size = isBufferEncrypted(i) ? encrypted_buffer_size_ : buffer_size_;
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
          int bytes = (i == kReadPlaintext) ?
              ProcessReadPlaintextBuffer(end, buffer_end) :
              ProcessWriteEncryptedBuffer(end, buffer_end);
          if (bytes < 0) return false;
          end += bytes;
          ASSERT(end <= size);
          if (end == size) end = 0;
        }
        if (start > end + 1) {
          int bytes =  (i == kReadPlaintext) ?
              ProcessReadPlaintextBuffer(end, start - 1) :
              ProcessWriteEncryptedBuffer(end, start - 1);
          if (bytes < 0) return false;
          end += bytes;
          ASSERT(end < start);
        }
        ends[i] = end;
        break;
      case kReadEncrypted:
        // Read data from circular buffer.
        if (end < start) {
          // Data may be split into two segments.  In this case,
          // the first is [start, size).
          int bytes = ProcessReadEncryptedBuffer(start, size);
          if (bytes < 0) return false;
          start += bytes;
          ASSERT(start <= size);
          if (start == size) start = 0;
        }
        if (start < end) {
          int bytes = ProcessReadEncryptedBuffer(start, end);
          if (bytes < 0) return false;
          start += bytes;
          ASSERT(start <= end);
        }
        starts[i] = start;
        break;
      case kWritePlaintext:
        if (end < start) {
          // Data is split into two segments, [start, size) and [0, end).
          int bytes = ProcessWritePlaintextBuffer(start, size, 0, end);
          if (bytes < 0) return false;
          start += bytes;
          if (start >= size) start -= size;
        } else {
          int bytes = ProcessWritePlaintextBuffer(start, end, 0, 0);
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


static Dart_Handle X509FromCertificate(CERTCertificate* certificate) {
  PRTime start_validity;
  PRTime end_validity;
  SECStatus status =
      CERT_GetCertTimes(certificate, &start_validity, &end_validity);
  if (status != SECSuccess) {
    ThrowPRException("CertificateException",
                     "Cannot get validity times from certificate");
  }
  int64_t start_epoch_ms = start_validity / PR_USEC_PER_MSEC;
  int64_t end_epoch_ms = end_validity / PR_USEC_PER_MSEC;
  Dart_Handle subject_name_object =
      DartUtils::NewString(certificate->subjectName);
  Dart_Handle issuer_name_object =
      DartUtils::NewString(certificate->issuerName);
  Dart_Handle start_epoch_ms_int = Dart_NewInteger(start_epoch_ms);
  Dart_Handle end_epoch_ms_int = Dart_NewInteger(end_epoch_ms);

  Dart_Handle date_type =
      DartUtils::GetDartType(DartUtils::kCoreLibURL, "DateTime");
  Dart_Handle from_milliseconds =
      DartUtils::NewString("fromMillisecondsSinceEpoch");

  Dart_Handle start_validity_date =
      Dart_New(date_type, from_milliseconds, 1, &start_epoch_ms_int);
  Dart_Handle end_validity_date =
      Dart_New(date_type, from_milliseconds, 1, &end_epoch_ms_int);

  Dart_Handle x509_type =
      DartUtils::GetDartType(DartUtils::kIOLibURL, "X509Certificate");
  Dart_Handle arguments[] = { subject_name_object,
                              issuer_name_object,
                              start_validity_date,
                              end_validity_date };
  return Dart_New(x509_type, Dart_Null(), 4, arguments);
}


void SSLFilter::Init(Dart_Handle dart_this) {
  if (!library_initialized_) {
    InitializeLibrary(NULL, "", true, false);
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

  InitializeBuffers(dart_this);
  filter_ = memio_CreateIOLayer(kMemioBufferSize, kMemioBufferSize);
}


void SSLFilter::InitializeBuffers(Dart_Handle dart_this) {
  // Create SSLFilter buffers as ExternalUint8Array objects.
  Dart_Handle dart_buffers_object = ThrowIfError(
      Dart_GetField(dart_this, DartUtils::NewString("buffers")));
  Dart_Handle secure_filter_impl_type =
      Dart_InstanceGetType(dart_this);
  Dart_Handle dart_buffer_size = ThrowIfError(
      Dart_GetField(secure_filter_impl_type, DartUtils::NewString("SIZE")));
  int64_t buffer_size = DartUtils::GetIntegerValue(dart_buffer_size);
  Dart_Handle dart_encrypted_buffer_size = ThrowIfError(
      Dart_GetField(secure_filter_impl_type,
                    DartUtils::NewString("ENCRYPTED_SIZE")));
  int64_t encrypted_buffer_size =
      DartUtils::GetIntegerValue(dart_encrypted_buffer_size);
  if (buffer_size <= 0 || buffer_size > 1 * MB) {
    FATAL("Invalid buffer size in _ExternalBuffer");
  }
  if (encrypted_buffer_size <= 0 || encrypted_buffer_size > 1 * MB) {
    FATAL("Invalid encrypted buffer size in _ExternalBuffer");
  }
  buffer_size_ = static_cast<int>(buffer_size);
  encrypted_buffer_size_ = static_cast<int>(encrypted_buffer_size);


  Dart_Handle data_identifier = DartUtils::NewString("data");
  for (int i = 0; i < kNumBuffers; ++i) {
    int size = isBufferEncrypted(i) ? encrypted_buffer_size_ : buffer_size_;
    dart_buffer_objects_[i] =
        Dart_NewPersistentHandle(Dart_ListGetAt(dart_buffers_object, i));
    ASSERT(dart_buffer_objects_[i] != NULL);
    buffers_[i] = new uint8_t[size];
    Dart_Handle data = ThrowIfError(
        Dart_NewExternalTypedData(Dart_TypedData_kUint8, buffers_[i], size));
    ThrowIfError(
        Dart_SetField(Dart_HandleFromPersistent(dart_buffer_objects_[i]),
                      data_identifier,
                      data));
  }
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


char* PasswordCallback(PK11SlotInfo* slot, PRBool retry, void* arg) {
  if (!retry) {
    return PL_strdup(static_cast<char*>(arg));  // Freed by NSS internals.
  }
  return NULL;
}


static const char* builtin_roots_module =
#if defined(TARGET_OS_LINUX) || defined(TARGET_OS_ANDROID)
    "name=\"Root Certs\" library=\"libnssckbi.so\"";
#elif defined(TARGET_OS_MACOS)
    "name=\"Root Certs\" library=\"libnssckbi.dylib\"";
#elif defined(TARGET_OS_WINDOWS)
    "name=\"Root Certs\" library=\"nssckbi.dll\"";
#else
#error Automatic target os detection failed.
#endif



void SSLFilter::InitializeLibrary(const char* certificate_database,
                                  const char* password,
                                  bool use_builtin_root_certificates,
                                  bool report_duplicate_initialization) {
  MutexLocker locker(mutex_);
  SECStatus status;
  if (!library_initialized_) {
    PR_Init(PR_USER_THREAD, PR_PRIORITY_NORMAL, 0);
    // TODO(whesse): Verify there are no UTF-8 issues here.
    if (certificate_database == NULL || certificate_database[0] == '\0') {
      status = NSS_NoDB_Init(NULL);
      if (status != SECSuccess) {
        mutex_->Unlock();  // MutexLocker destructor not called when throwing.
        ThrowPRException("TlsException",
                         "Failed NSS_NoDB_Init call.");
      }
      if (use_builtin_root_certificates) {
        SECMODModule* module = SECMOD_LoadUserModule(
            const_cast<char*>(builtin_roots_module), NULL, PR_FALSE);
        if (!module) {
          mutex_->Unlock();  // MutexLocker destructor not called when throwing.
          ThrowPRException("TlsException",
                           "Failed to load builtin root certificates.");
        }
      }
    } else {
      PRUint32 init_flags = NSS_INIT_READONLY;
      if (!use_builtin_root_certificates) {
        init_flags |= NSS_INIT_NOMODDB;
      }
      status = NSS_Initialize(certificate_database,
                              "",
                              "",
                              SECMOD_DB,
                              init_flags);
      if (status != SECSuccess) {
        mutex_->Unlock();  // MutexLocker destructor not called when throwing.
        ThrowPRException("TlsException",
                         "Failed NSS_Init call.");
      }
      password_ = strdup(password);  // This one copy persists until Dart exits.
      PK11_SetPasswordFunc(PasswordCallback);
    }
    library_initialized_ = true;

    status = NSS_SetDomesticPolicy();
    if (status != SECSuccess) {
      mutex_->Unlock();  // MutexLocker destructor not called when throwing.
      ThrowPRException("TlsException",
                       "Failed NSS_SetDomesticPolicy call.");
    }

    // Enable the same additional ciphers that Chromium does.
    // See NSSSSLInitSingleton() in Chromium's net/socket/nss_ssl_util.cc.
    // Explicitly enable exactly those ciphers with keys of at least 80 bits.
    const PRUint16* const ssl_ciphers = SSL_GetImplementedCiphers();
    const PRUint16 num_ciphers = SSL_GetNumImplementedCiphers();
    for (int i = 0; i < num_ciphers; i++) {
      SSLCipherSuiteInfo info;
      if (SSL_GetCipherSuiteInfo(ssl_ciphers[i], &info, sizeof(info)) ==
          SECSuccess) {
        bool enabled = (info.effectiveKeyBits >= 80);
        // Trim the list of cipher suites in order to keep the size of the
        // ClientHello down. DSS, ECDH, CAMELLIA, SEED, ECC+3DES, and
        // HMAC-SHA256 cipher suites are disabled.
        if (info.symCipher == ssl_calg_camellia ||
            info.symCipher == ssl_calg_seed ||
            (info.symCipher == ssl_calg_3des && info.keaType != ssl_kea_rsa) ||
            info.authAlgorithm == ssl_auth_dsa ||
            info.macAlgorithm == ssl_hmac_sha256 ||
            info.nonStandard ||
            strcmp(info.keaTypeName, "ECDH") == 0) {
          enabled = false;
        }

        if (ssl_ciphers[i] == TLS_DHE_DSS_WITH_AES_128_CBC_SHA) {
          // Enabled to allow servers with only a DSA certificate to function.
          enabled = true;
        }
        SSL_CipherPrefSetDefault(ssl_ciphers[i], enabled);
      }
    }

    status = SSL_ConfigServerSessionIDCache(0, 0, 0, NULL);
    if (status != SECSuccess) {
      mutex_->Unlock();  // MutexLocker destructor not called when throwing.
      ThrowPRException("TlsException",
                       "Failed SSL_ConfigServerSessionIDCache call.");
    }

  } else if (report_duplicate_initialization) {
    mutex_->Unlock();  // MutexLocker destructor not called when throwing.
    // Like ThrowPRException, without adding an OSError.
    Dart_ThrowException(DartUtils::NewDartIOException("TlsException",
        "Called SecureSocket.initialize more than once",
        Dart_Null()));
  }
}


SECStatus BadCertificateCallback(void* filter, PRFileDesc* fd) {
  SSLFilter* ssl_filter = static_cast<SSLFilter*>(filter);
  Dart_Handle callback = ssl_filter->bad_certificate_callback();
  if (Dart_IsNull(callback)) return SECFailure;
  Dart_Handle x509_object = ssl_filter->PeerCertificate();
  Dart_Handle result = Dart_InvokeClosure(callback, 1, &x509_object);
  if (Dart_IsError(result)) {
    ssl_filter->callback_error = result;
    return SECFailure;
  }
  // Our wrapper is guaranteed to return a boolean.
  bool c_result = DartUtils::GetBooleanValue(result);
  return c_result ? SECSuccess : SECFailure;
}


Dart_Handle SSLFilter::PeerCertificate() {
  CERTCertificate* certificate = SSL_PeerCertificate(filter_);
  if (certificate == NULL) return Dart_Null();
  Dart_Handle x509_object = X509FromCertificate(certificate);
  CERT_DestroyCertificate(certificate);
  return x509_object;
}


void SSLFilter::Connect(const char* host_name,
                        RawAddr* raw_addr,
                        int port,
                        bool is_server,
                        const char* certificate_name,
                        bool request_client_certificate,
                        bool require_client_certificate,
                        bool send_client_certificate) {
  is_server_ = is_server;
  if (in_handshake_) {
    FATAL("Connect called twice on the same _SecureFilter.");
  }

  if (!is_server && certificate_name != NULL) {
    client_certificate_name_ = strdup(certificate_name);
  }

  filter_ = SSL_ImportFD(NULL, filter_);
  if (filter_ == NULL) {
    ThrowPRException("TlsException", "Failed SSL_ImportFD call");
  }

  SSLVersionRange vrange;
  vrange.min = SSL_LIBRARY_VERSION_3_0;
  vrange.max = SSL_LIBRARY_VERSION_TLS_1_2;
  SSL_VersionRangeSet(filter_, &vrange);

  SECStatus status;
  if (is_server) {
    CERTCertificate* certificate = NULL;
    if (strstr(certificate_name, "CN=") != NULL) {
      // Look up certificate using the distinguished name (DN) certificate_name.
      CERTCertDBHandle* certificate_database = CERT_GetDefaultCertDB();
      if (certificate_database == NULL) {
        ThrowPRException("CertificateException",
                         "Certificate database cannot be loaded");
      }
      certificate = CERT_FindCertByNameString(certificate_database,
          const_cast<char*>(certificate_name));
      if (certificate == NULL) {
        ThrowCertificateException(
            "Cannot find server certificate by distinguished name: %s",
            certificate_name);
      }
    } else {
      // Look up certificate using the nickname certificate_name.
      certificate = PK11_FindCertFromNickname(
          const_cast<char*>(certificate_name),
          static_cast<void*>(const_cast<char*>(password_)));
      if (certificate == NULL) {
        ThrowCertificateException(
            "Cannot find server certificate by nickname: %s",
            certificate_name);
      }
    }
    SECKEYPrivateKey* key = PK11_FindKeyByAnyCert(
        certificate,
        static_cast<void*>(const_cast<char*>(password_)));
    if (key == NULL) {
      CERT_DestroyCertificate(certificate);
      if (PR_GetError() == -8177) {
        ThrowPRException("CertificateException",
                         "Certificate database password incorrect");
      } else {
        ThrowCertificateException(
            "Cannot find private key for certificate %s",
            certificate_name);
      }
    }
    // kt_rsa (key type RSA) is an enum constant from the NSS libraries.
    // TODO(whesse): Allow different key types.
    status = SSL_ConfigSecureServer(filter_, certificate, key, kt_rsa);
    CERT_DestroyCertificate(certificate);
    SECKEY_DestroyPrivateKey(key);
    if (status != SECSuccess) {
      ThrowCertificateException(
          "Failed SSL_ConfigSecureServer call with certificate %s",
          certificate_name);
    }

    if (request_client_certificate) {
      status = SSL_OptionSet(filter_, SSL_REQUEST_CERTIFICATE, PR_TRUE);
      if (status != SECSuccess) {
        ThrowPRException("TlsException",
                         "Failed SSL_OptionSet(REQUEST_CERTIFICATE) call");
      }
      status = SSL_OptionSet(filter_,
                             SSL_REQUIRE_CERTIFICATE,
                             require_client_certificate);
      if (status != SECSuccess) {
        ThrowPRException("TlsException",
                         "Failed SSL_OptionSet(REQUIRE_CERTIFICATE) call");
      }
    }
  } else {  // Client.
    if (SSL_SetURL(filter_, host_name) == -1) {
      ThrowPRException("TlsException", "Failed SetURL call");
    }
    if (send_client_certificate) {
      SSL_SetPKCS11PinArg(filter_, const_cast<char*>(password_));
      status = SSL_GetClientAuthDataHook(
          filter_,
          NSS_GetClientAuthData,
          static_cast<void*>(client_certificate_name_));
      if (status != SECSuccess) {
        ThrowPRException("TlsException",
                         "Failed SSL_GetClientAuthDataHook call");
      }
    }
  }

  // Install bad certificate callback, and pass 'this' to it if it is called.
  status = SSL_BadCertHook(filter_,
                           BadCertificateCallback,
                           static_cast<void*>(this));

  status = SSL_ResetHandshake(filter_, is_server);
  if (status != SECSuccess) {
    ThrowPRException("TlsException",
                     "Failed SSL_ResetHandshake call");
  }

  // Set the peer address from the address passed. The DNS has already
  // been done in Dart code, so just use that address. This relies on
  // following about PRNetAddr: "The raw member of the union is
  // equivalent to struct sockaddr", which is stated in the NSS
  // documentation.
  PRNetAddr peername;
  memset(&peername, 0, sizeof(peername));
  intptr_t len = SocketAddress::GetAddrLength(raw_addr);
  ASSERT(static_cast<size_t>(len) <= sizeof(peername));
  memmove(&peername, &raw_addr->addr, len);

  // Adjust the address family field for BSD, whose sockaddr
  // structure has a one-byte length and one-byte address family
  // field at the beginning.  PRNetAddr has a two-byte address
  // family field at the beginning.
  peername.raw.family = raw_addr->addr.sa_family;

  memio_SetPeerName(filter_, &peername);
}


void SSLFilter::Handshake() {
  SECStatus status = SSL_ForceHandshake(filter_);
  if (status == SECSuccess) {
    if (in_handshake_) {
      ThrowIfError(Dart_InvokeClosure(
          Dart_HandleFromPersistent(handshake_complete_), 0, NULL));
      in_handshake_ = false;
    }
  } else {
    if (callback_error != NULL) {
      Dart_PropagateError(callback_error);
    }
    PRErrorCode error = PR_GetError();
    if (error == PR_WOULD_BLOCK_ERROR) {
      if (!in_handshake_) {
        in_handshake_ = true;
      }
    } else {
      if (is_server_) {
        ThrowPRException("HandshakeException",
                         "Handshake error in server");
      } else {
        ThrowPRException("HandshakeException",
                         "Handshake error in client");
      }
    }
  }
}


void SSLFilter::Renegotiate(bool use_session_cache,
                            bool request_client_certificate,
                            bool require_client_certificate) {
  SECStatus status;
  // The SSL_REQUIRE_CERTIFICATE option only takes effect if the
  // SSL_REQUEST_CERTIFICATE option is also set, so set it.
  request_client_certificate =
      request_client_certificate || require_client_certificate;

  status = SSL_OptionSet(filter_,
                         SSL_REQUEST_CERTIFICATE,
                         request_client_certificate);
  if (status != SECSuccess) {
    ThrowPRException("TlsException",
       "Failure in (Raw)SecureSocket.renegotiate request_client_certificate");
  }
  status = SSL_OptionSet(filter_,
                         SSL_REQUIRE_CERTIFICATE,
                         require_client_certificate);
  if (status != SECSuccess) {
    ThrowPRException("TlsException",
       "Failure in (Raw)SecureSocket.renegotiate require_client_certificate");
  }
  bool flush_cache = !use_session_cache;
  status = SSL_ReHandshake(filter_, flush_cache);
  if (status != SECSuccess) {
    if (is_server_) {
      ThrowPRException("HandshakeException",
                       "Failure in (Raw)SecureSocket.renegotiate in server");
    } else {
      ThrowPRException("HandshakeException",
                       "Failure in (Raw)SecureSocket.renegotiate in client");
    }
  }
}


void SSLFilter::Destroy() {
  for (int i = 0; i < kNumBuffers; ++i) {
    Dart_DeletePersistentHandle(dart_buffer_objects_[i]);
    delete[] buffers_[i];
  }
  Dart_DeletePersistentHandle(string_start_);
  Dart_DeletePersistentHandle(string_length_);
  Dart_DeletePersistentHandle(handshake_complete_);
  Dart_DeletePersistentHandle(bad_certificate_callback_);
  free(client_certificate_name_);

  PR_Close(filter_);
}


intptr_t SSLFilter::ProcessReadPlaintextBuffer(int start, int end) {
  int length = end - start;
  int bytes_processed = 0;
  if (length > 0) {
    bytes_processed = PR_Read(filter_,
                              buffers_[kReadPlaintext] + start,
                              length);
    if (bytes_processed < 0) {
      ASSERT(bytes_processed == -1);
      PRErrorCode pr_error = PR_GetError();
      if (PR_WOULD_BLOCK_ERROR != pr_error) {
        return -1;
      }
      bytes_processed = 0;
    }
  }
  return bytes_processed;
}


intptr_t SSLFilter::ProcessWritePlaintextBuffer(int start1, int end1,
                                                int start2, int end2) {
  PRIOVec ranges[2];
  uint8_t* buffer = buffers_[kWritePlaintext];
  ranges[0].iov_base = reinterpret_cast<char*>(buffer + start1);
  ranges[0].iov_len = end1 - start1;
  ranges[1].iov_base = reinterpret_cast<char*>(buffer + start2);
  ranges[1].iov_len = end2 - start2;
  int bytes_processed = PR_Writev(filter_, ranges, 2, PR_INTERVAL_NO_TIMEOUT);
  if (bytes_processed < 0) {
    ASSERT(bytes_processed == -1);
    PRErrorCode pr_error = PR_GetError();
    if (PR_WOULD_BLOCK_ERROR != pr_error) {
      return -1;
    }
    bytes_processed = 0;
  }
  return bytes_processed;
}


intptr_t SSLFilter::ProcessReadEncryptedBuffer(int start, int end) {
  int length = end - start;
  int bytes_processed = 0;
  if (length > 0) {
    memio_Private* secret = memio_GetSecret(filter_);
    uint8_t* filter_buf;
    int free_bytes = memio_GetReadParams(secret, &filter_buf);
    bytes_processed = dart::Utils::Minimum(length, free_bytes);
    memmove(filter_buf, buffers_[kReadEncrypted] + start, bytes_processed);
    memio_PutReadResult(secret, bytes_processed);
  }
  return bytes_processed;
}


intptr_t SSLFilter::ProcessWriteEncryptedBuffer(int start, int end) {
  int length = end - start;
  int bytes_processed = 0;
  if (length > 0) {
    uint8_t* buffer = buffers_[kWriteEncrypted];
    const uint8_t* buf1;
    const uint8_t* buf2;
    unsigned int len1;
    unsigned int len2;
    memio_Private* secret = memio_GetSecret(filter_);
    memio_GetWriteParams(secret, &buf1, &len1, &buf2, &len2);
    int bytes_to_send =
        dart::Utils::Minimum(len1, static_cast<unsigned>(length));
    if (bytes_to_send > 0) {
      memmove(buffer + start, buf1, bytes_to_send);
      bytes_processed = bytes_to_send;
    }
    bytes_to_send = dart::Utils::Minimum(len2,
        static_cast<unsigned>(length - bytes_processed));
    if (bytes_to_send > 0) {
      memmove(buffer + start + bytes_processed, buf2, bytes_to_send);
      bytes_processed += bytes_to_send;
    }
    if (bytes_processed > 0) {
      memio_PutWriteResult(secret, bytes_processed);
    }
  }
  return bytes_processed;
}

}  // namespace bin
}  // namespace dart
