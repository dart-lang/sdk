// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/secure_socket.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>

#include <nss.h>
#include <pk11pub.h>
#include <prerror.h>
#include <prinit.h>
#include <prnetdb.h>
#include <ssl.h>
#include <sslproto.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/net/nss_memio.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/utils.h"

#include "include/dart_api.h"

bool SSLFilter::library_initialized_ = false;
dart::Mutex SSLFilter::mutex_;  // To protect library initialization.
// The password is needed when creating secure server sockets.  It can
// be null if only secure client sockets are used.
const char* SSLFilter::password_ = NULL;

static const int kSSLFilterNativeFieldIndex = 0;

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
  Dart_EnterScope();
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  SSLFilter* filter = new SSLFilter;
  SetFilter(args, filter);
  filter->Init(dart_this);
  Dart_ExitScope();
}


void FUNCTION_NAME(SecureSocket_Connect)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle host_name_object = ThrowIfError(Dart_GetNativeArgument(args, 1));
  Dart_Handle port_object = ThrowIfError(Dart_GetNativeArgument(args, 2));
  Dart_Handle is_server_object = ThrowIfError(Dart_GetNativeArgument(args, 3));
  Dart_Handle certificate_name_object =
      ThrowIfError(Dart_GetNativeArgument(args, 4));

  const char* host_name = NULL;
  // TODO(whesse): Is truncating a Dart string containing \0 what we want?
  ThrowIfError(Dart_StringToCString(host_name_object, &host_name));

  int64_t port;
  if (!DartUtils::GetInt64Value(port_object, &port) ||
      port < 0 || port > 65535) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Illegal port parameter in _SSLFilter.connect"));
  }

  if (!Dart_IsBoolean(is_server_object)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Illegal is_server parameter in _SSLFilter.connect"));
  }
  bool is_server = DartUtils::GetBooleanValue(is_server_object);

  const char* certificate_name = NULL;
  // If this is a server connection, get the certificate to connect with.
  // TODO(whesse): Use this parameter for a client certificate as well.
  if (is_server) {
    if (!Dart_IsString(certificate_name_object)) {
      Dart_ThrowException(DartUtils::NewDartArgumentError(
          "Non-String certificate parameter in _SSLFilter.connect"));
    }
    ThrowIfError(Dart_StringToCString(certificate_name_object,
                                      &certificate_name));
  }

  GetFilter(args)->Connect(host_name,
                              static_cast<int>(port),
                              is_server,
                              certificate_name);
  Dart_ExitScope();
}


void FUNCTION_NAME(SecureSocket_Destroy)(Dart_NativeArguments args) {
  Dart_EnterScope();
  SSLFilter* filter = GetFilter(args);
  SetFilter(args, NULL);
  filter->Destroy();
  delete filter;
  Dart_ExitScope();
}


void FUNCTION_NAME(SecureSocket_Handshake)(Dart_NativeArguments args) {
  Dart_EnterScope();
  GetFilter(args)->Handshake();
  Dart_ExitScope();
}


void FUNCTION_NAME(SecureSocket_RegisterHandshakeCompleteCallback)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle handshake_complete =
      ThrowIfError(Dart_GetNativeArgument(args, 1));
  if (!Dart_IsClosure(handshake_complete)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Illegal argument to RegisterHandshakeCompleteCallback"));
  }
  GetFilter(args)->RegisterHandshakeCompleteCallback(handshake_complete);
  Dart_ExitScope();
}


void FUNCTION_NAME(SecureSocket_ProcessBuffer)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle buffer_id_object = ThrowIfError(Dart_GetNativeArgument(args, 1));
  int64_t buffer_id = DartUtils::GetIntegerValue(buffer_id_object);
  if (buffer_id < 0 || buffer_id >= SSLFilter::kNumBuffers) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Illegal argument to ProcessBuffer"));
  }

  intptr_t bytes_read =
      GetFilter(args)->ProcessBuffer(static_cast<int>(buffer_id));
  Dart_SetReturnValue(args, Dart_NewInteger(bytes_read));
  Dart_ExitScope();
}


void FUNCTION_NAME(SecureSocket_SetCertificateDatabase)
    (Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle certificate_database_object =
      ThrowIfError(Dart_GetNativeArgument(args, 0));
  // Check that the type is string, and get the UTF-8 C string value from it.
  const char* certificate_database = NULL;
  if (Dart_IsString(certificate_database_object)) {
    ThrowIfError(Dart_StringToCString(certificate_database_object,
                                      &certificate_database));
  } else {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Non-String certificate directory argument to SetCertificateDatabase"));
  }

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

  SSLFilter::InitializeLibrary(certificate_database, password);
  Dart_ExitScope();
}


void SSLFilter::Init(Dart_Handle dart_this) {
  string_start_ = ThrowIfError(
      Dart_NewPersistentHandle(DartUtils::NewString("start")));
  string_length_ = ThrowIfError(
      Dart_NewPersistentHandle(DartUtils::NewString("length")));

  InitializeBuffers(dart_this);
  filter_ = memio_CreateIOLayer(kMemioBufferSize);
}


void SSLFilter::InitializeBuffers(Dart_Handle dart_this) {
  // Create SSLFilter buffers as ExternalUint8Array objects.
  Dart_Handle dart_buffers_object = ThrowIfError(
      Dart_GetField(dart_this, DartUtils::NewString("buffers")));
  Dart_Handle dart_buffer_object =
      Dart_ListGetAt(dart_buffers_object, kReadPlaintext);
  Dart_Handle external_buffer_class =
      Dart_InstanceGetClass(dart_buffer_object);
  Dart_Handle dart_buffer_size = ThrowIfError(
      Dart_GetField(external_buffer_class, DartUtils::NewString("SIZE")));
  buffer_size_ = DartUtils::GetIntegerValue(dart_buffer_size);
  if (buffer_size_ <= 0 || buffer_size_ > 1024 * 1024) {
    Dart_ThrowException(
        DartUtils::NewString("Invalid buffer size in _ExternalBuffer"));
  }

  Dart_Handle data_identifier = DartUtils::NewString("data");
  for (int i = 0; i < kNumBuffers; ++i) {
    dart_buffer_objects_[i] = ThrowIfError(
        Dart_NewPersistentHandle(Dart_ListGetAt(dart_buffers_object, i)));
    buffers_[i] = new uint8_t[buffer_size_];
    Dart_Handle data = ThrowIfError(
      Dart_NewExternalByteArray(buffers_[i], buffer_size_, NULL, NULL));
    ThrowIfError(Dart_SetField(dart_buffer_objects_[i],
                               data_identifier,
                               data));
  }
}


void SSLFilter::RegisterHandshakeCompleteCallback(Dart_Handle complete) {
  ASSERT(NULL == handshake_complete_);
  handshake_complete_ = ThrowIfError(Dart_NewPersistentHandle(complete));
}


void SSLFilter::InitializeLibrary(const char* certificate_database,
                                  const char* password) {
  MutexLocker locker(&mutex_);
  if (!library_initialized_) {
    library_initialized_ = true;
    password_ = strdup(password);  // This one copy persists until Dart exits.
    PR_Init(PR_USER_THREAD, PR_PRIORITY_NORMAL, 0);
    // TODO(whesse): Verify there are no UTF-8 issues here.
    SECStatus status = NSS_Init(certificate_database);
    if (status != SECSuccess) {
      ThrowPRException("Unsuccessful NSS_Init call.");
    }

    status = NSS_SetDomesticPolicy();
    if (status != SECSuccess) {
      ThrowPRException("Unsuccessful NSS_SetDomesticPolicy call.");
    }
    // Enable TLS, as well as SSL3 and SSL2.
    status = SSL_OptionSetDefault(SSL_ENABLE_TLS, PR_TRUE);
    if (status != SECSuccess) {
      ThrowPRException("Unsuccessful SSL_OptionSetDefault enable TLS call.");
    }
    status = SSL_ConfigServerSessionIDCache(0, 0, 0, NULL);
    if (status != SECSuccess) {
      ThrowPRException("Unsuccessful SSL_ConfigServerSessionIDCache call.");
    }

  } else {
    ThrowException("Called SSLFilter::InitializeLibrary more than once");
  }
}

char* PasswordCallback(PK11SlotInfo* slot, PRBool retry, void* arg) {
  if (!retry) {
    return PL_strdup(static_cast<char*>(arg));  // Freed by NSS internals.
  }
  return NULL;
}

void SSLFilter::Connect(const char* host_name,
                        int port,
                        bool is_server,
                        const char* certificate_name) {
  is_server_ = is_server;
  if (in_handshake_) {
    ThrowException("Connect called while already in handshake state.");
  }

  filter_ = SSL_ImportFD(NULL, filter_);
  if (filter_ == NULL) {
    ThrowPRException("Unsuccessful SSL_ImportFD call");
  }

  SECStatus status;
  if (is_server) {
    PK11_SetPasswordFunc(PasswordCallback);
    CERTCertDBHandle* certificate_database = CERT_GetDefaultCertDB();
    if (certificate_database == NULL) {
      ThrowPRException("Certificate database cannot be loaded");
    }
    CERTCertificate* certificate = CERT_FindCertByNameString(
        certificate_database,
        const_cast<char*>(certificate_name));
    if (certificate == NULL) {
      ThrowPRException("Cannot find server certificate by name");
    }
    SECKEYPrivateKey* key = PK11_FindKeyByAnyCert(
        certificate,
        static_cast<void*>(const_cast<char*>(password_)));
    if (key == NULL) {
      if (PR_GetError() == -8177) {
        ThrowPRException("Certificate database password incorrect");
      } else {
        ThrowPRException("Unsuccessful PK11_FindKeyByAnyCert call."
                         " Cannot find private key for certificate");
      }
    }
    // kt_rsa (key type RSA) is an enum constant from the NSS libraries.
    // TODO(whesse): Allow different key types.
    status = SSL_ConfigSecureServer(filter_, certificate, key, kt_rsa);
    if (status != SECSuccess) {
      ThrowPRException("Unsuccessful SSL_ConfigSecureServer call");
    }
  } else {  // Client.
    if (SSL_SetURL(filter_, host_name) == -1) {
      ThrowPRException("Unsuccessful SetURL call");
    }
  }

  PRBool as_server = is_server ? PR_TRUE : PR_FALSE;  // Convert bool to PRBool.
  status = SSL_ResetHandshake(filter_, as_server);
  if (status != SECSuccess) {
    ThrowPRException("Unsuccessful SSL_ResetHandshake call");
  }

  // SetPeerAddress
  PRNetAddr host_address;
  char host_entry_buffer[PR_NETDB_BUF_SIZE];
  PRHostEnt host_entry;
  PRStatus rv = PR_GetHostByName(host_name, host_entry_buffer,
                                 PR_NETDB_BUF_SIZE, &host_entry);
  if (rv != PR_SUCCESS) {
    ThrowPRException("Unsuccessful PR_GetHostByName call");
  }

  int index = PR_EnumerateHostEnt(0, &host_entry, port, &host_address);
  if (index == -1 || index == 0) {
    ThrowPRException("Unsuccessful PR_EnumerateHostEnt call");
  }
  memio_SetPeerName(filter_, &host_address);
}


void SSLFilter::Handshake() {
  SECStatus status = SSL_ForceHandshake(filter_);
  if (status == SECSuccess) {
    if (in_handshake_) {
      ThrowIfError(Dart_InvokeClosure(handshake_complete_, 0, NULL));
      in_handshake_ = false;
    }
  } else {
    PRErrorCode error = PR_GetError();
    if (error == PR_WOULD_BLOCK_ERROR) {
      if (!in_handshake_) {
        in_handshake_ = true;
      }
    } else {
      if (is_server_) {
        ThrowPRException("Unexpected handshake error in server");
      } else {
        ThrowPRException("Unexpected handshake error in client");
      }
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
  // TODO(whesse): Free NSS objects here.
}


intptr_t SSLFilter::ProcessBuffer(int buffer_index) {
  Dart_Handle buffer_object = dart_buffer_objects_[buffer_index];
  Dart_Handle start_object = ThrowIfError(
      Dart_GetField(buffer_object, string_start_));
  Dart_Handle length_object = ThrowIfError(
      Dart_GetField(buffer_object, string_length_));
  int64_t unsafe_start = DartUtils::GetIntegerValue(start_object);
  int64_t unsafe_length = DartUtils::GetIntegerValue(length_object);
  ASSERT(unsafe_start >= 0);
  ASSERT(unsafe_start < buffer_size_);
  ASSERT(unsafe_length >= 0);
  ASSERT(unsafe_length <= buffer_size_);
  intptr_t start = static_cast<intptr_t>(unsafe_start);
  intptr_t length = static_cast<intptr_t>(unsafe_length);
  uint8_t* buffer = buffers_[buffer_index];

  int bytes_processed = 0;
  switch (buffer_index) {
    case kReadPlaintext: {
      int bytes_free = buffer_size_ - start - length;
      bytes_processed = PR_Read(filter_,
                                buffer + start + length,
                                bytes_free);
      if (bytes_processed < 0) {
        ASSERT(bytes_processed == -1);
        // TODO(whesse): Handle unexpected errors here.
        PRErrorCode pr_error = PR_GetError();
        if (PR_WOULD_BLOCK_ERROR != pr_error) {
          ThrowPRException("Error reading plaintext from SSLFilter");
        }
        bytes_processed = 0;
      }
      break;
    }

    case kWriteEncrypted: {
      const uint8_t* buf1;
      const uint8_t* buf2;
      unsigned int len1;
      unsigned int len2;
      int bytes_free = buffer_size_ - start - length;
      memio_Private* secret = memio_GetSecret(filter_);
      memio_GetWriteParams(secret, &buf1, &len1, &buf2, &len2);
      int bytes_to_send =
          dart::Utils::Minimum(len1, static_cast<unsigned>(bytes_free));
      if (bytes_to_send > 0) {
        memmove(buffer + start + length, buf1, bytes_to_send);
        bytes_processed = bytes_to_send;
      }
      bytes_to_send = dart::Utils::Minimum(len2,
          static_cast<unsigned>(bytes_free - bytes_processed));
      if (bytes_to_send > 0) {
        memmove(buffer + start + length + bytes_processed, buf2,
                bytes_to_send);
        bytes_processed += bytes_to_send;
      }
      if (bytes_processed > 0) {
        memio_PutWriteResult(secret, bytes_processed);
      }
      break;
    }

    case kReadEncrypted: {
      if (length > 0) {
        bytes_processed = length;
        memio_Private* secret = memio_GetSecret(filter_);
        uint8_t* filter_buf;
        int free_bytes = memio_GetReadParams(secret, &filter_buf);
        if (free_bytes < bytes_processed) bytes_processed = free_bytes;
        memmove(filter_buf,
                buffer + start,
                bytes_processed);
        memio_PutReadResult(secret, bytes_processed);
      }
      break;
    }

    case kWritePlaintext: {
      if (length > 0) {
        bytes_processed = PR_Write(filter_,
                                   buffer + start,
                                   length);
      }

      if (bytes_processed < 0) {
        ASSERT(bytes_processed == -1);
        // TODO(whesse): Handle unexpected errors here.
        PRErrorCode pr_error = PR_GetError();
        if (PR_WOULD_BLOCK_ERROR != pr_error) {
          ThrowPRException("Error reading plaintext from SSLFilter");
        }
        bytes_processed = 0;
      }
      break;
    }
  }
  return bytes_processed;
}
