// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/tls_socket.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>

#include <nss.h>
#include <prerror.h>
#include <prinit.h>
#include <prnetdb.h>
#include <ssl.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/net/nss_memio.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/utils.h"

#include "include/dart_api.h"

bool TlsFilter::library_initialized_ = false;
dart::Mutex TlsFilter::mutex_;  // To protect library initialization.
static const int kTlsFilterNativeFieldIndex = 0;

static TlsFilter* GetTlsFilter(Dart_NativeArguments args) {
  TlsFilter* filter;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(Dart_GetNativeInstanceField(
      dart_this,
      kTlsFilterNativeFieldIndex,
      reinterpret_cast<intptr_t*>(&filter)));
  return filter;
}


static void SetTlsFilter(Dart_NativeArguments args, TlsFilter* filter) {
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(Dart_SetNativeInstanceField(
      dart_this,
      kTlsFilterNativeFieldIndex,
      reinterpret_cast<intptr_t>(filter)));
}


void FUNCTION_NAME(TlsSocket_Init)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  TlsFilter* filter = new TlsFilter;
  SetTlsFilter(args, filter);
  filter->Init(dart_this);
  Dart_ExitScope();
}


void FUNCTION_NAME(TlsSocket_Connect)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle host_name = ThrowIfError(Dart_GetNativeArgument(args, 1));
  Dart_Handle port_object = ThrowIfError(Dart_GetNativeArgument(args, 2));

  const char* host_name_string = NULL;
  // TODO(whesse): Is truncating a Dart string containing \0 what we want?
  ThrowIfError(Dart_StringToCString(host_name, &host_name_string));

  int64_t port;
  if (!DartUtils::GetInt64Value(port_object, &port) ||
      port < 0 || port > 65535) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
      "Illegal port parameter in TlsSocket"));
  }

  GetTlsFilter(args)->Connect(host_name_string, static_cast<int>(port));
  Dart_ExitScope();
}


void FUNCTION_NAME(TlsSocket_Destroy)(Dart_NativeArguments args) {
  Dart_EnterScope();
  TlsFilter* filter = GetTlsFilter(args);
  SetTlsFilter(args, NULL);
  filter->Destroy();
  delete filter;
  Dart_ExitScope();
}


void FUNCTION_NAME(TlsSocket_Handshake)(Dart_NativeArguments args) {
  Dart_EnterScope();
  GetTlsFilter(args)->Handshake();
  Dart_ExitScope();
}


void FUNCTION_NAME(TlsSocket_RegisterHandshakeCompleteCallback)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle handshake_complete =
      ThrowIfError(Dart_GetNativeArgument(args, 1));
  if (!Dart_IsClosure(handshake_complete)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Illegal argument to RegisterHandshakeCompleteCallback"));
  }
  GetTlsFilter(args)->RegisterHandshakeCompleteCallback(handshake_complete);
  Dart_ExitScope();
}


void FUNCTION_NAME(TlsSocket_ProcessBuffer)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle buffer_id_object = ThrowIfError(Dart_GetNativeArgument(args, 1));
  int64_t buffer_id = DartUtils::GetIntegerValue(buffer_id_object);
  if (buffer_id < 0 || buffer_id >= TlsFilter::kNumBuffers) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Illegal argument to ProcessBuffer"));
  }

  intptr_t bytes_read =
      GetTlsFilter(args)->ProcessBuffer(static_cast<int>(buffer_id));
  Dart_SetReturnValue(args, Dart_NewInteger(bytes_read));
  Dart_ExitScope();
}


void FUNCTION_NAME(TlsSocket_SetCertificateDatabase)
    (Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle dart_pkcert_dir = ThrowIfError(Dart_GetNativeArgument(args, 0));
  // Check that the type is string, and get the UTF-8 C string value from it.
  if (Dart_IsString(dart_pkcert_dir)) {
    const char* pkcert_dir = NULL;
    ThrowIfError(Dart_StringToCString(dart_pkcert_dir, &pkcert_dir));
    TlsFilter::InitializeLibrary(pkcert_dir);
  } else {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Non-String argument to SetCertificateDatabase"));
  }
  Dart_ExitScope();
}


void TlsFilter::Init(Dart_Handle dart_this) {
  string_start_ = ThrowIfError(
      Dart_NewPersistentHandle(DartUtils::NewString("start")));
  string_length_ = ThrowIfError(
      Dart_NewPersistentHandle(DartUtils::NewString("length")));

  InitializeBuffers(dart_this);
  memio_ = memio_CreateIOLayer(kMemioBufferSize);
}


void TlsFilter::InitializeBuffers(Dart_Handle dart_this) {
  // Create TlsFilter buffers as ExternalUint8Array objects.
  Dart_Handle dart_buffers_object = ThrowIfError(
      Dart_GetField(dart_this, DartUtils::NewString("buffers")));
  Dart_Handle dart_buffer_object =
      Dart_ListGetAt(dart_buffers_object, kReadPlaintext);
  Dart_Handle tls_external_buffer_class =
      Dart_InstanceGetClass(dart_buffer_object);
  Dart_Handle dart_buffer_size = ThrowIfError(
      Dart_GetField(tls_external_buffer_class, DartUtils::NewString("SIZE")));
  buffer_size_ = DartUtils::GetIntegerValue(dart_buffer_size);
  if (buffer_size_ <= 0 || buffer_size_ > 1024 * 1024) {
    Dart_ThrowException(
        DartUtils::NewString("Invalid buffer size in _TlsExternalBuffer"));
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


void TlsFilter::RegisterHandshakeCompleteCallback(Dart_Handle complete) {
  ASSERT(NULL == handshake_complete_);
  handshake_complete_ = ThrowIfError(Dart_NewPersistentHandle(complete));
}


void TlsFilter::InitializeLibrary(const char* pkcert_database) {
  MutexLocker locker(&mutex_);
  if (!library_initialized_) {
    PR_Init(PR_USER_THREAD, PR_PRIORITY_NORMAL, 0);
    // TODO(whesse): Verify there are no UTF-8 issues here.
    SECStatus status = NSS_Init(pkcert_database);
    if (status != SECSuccess) {
      ThrowPRException("Unsuccessful NSS_Init call.");
    }

    status = NSS_SetDomesticPolicy();
    if (status != SECSuccess) {
      ThrowPRException("Unsuccessful NSS_SetDomesticPolicy call.");
    }
  } else {
    ThrowException("Called TlsFilter::InitializeLibrary more than once");
  }
}


void TlsFilter::Connect(const char* host, int port) {
  if (in_handshake_) {
    ThrowException("Connect called while already in handshake state.");
  }
  PRFileDesc* my_socket = memio_;

  my_socket = SSL_ImportFD(NULL, my_socket);
  if (my_socket == NULL) {
    ThrowPRException("Unsuccessful SSL_ImportFD call");
  }

  if (SSL_SetURL(my_socket, host) == -1) {
    ThrowPRException("Unsuccessful SetURL call");
  }

  SECStatus status = SSL_ResetHandshake(my_socket, PR_FALSE);
  if (status != SECSuccess) {
    ThrowPRException("Unsuccessful SSL_ResetHandshake call");
  }

  // SetPeerAddress
  PRNetAddr host_address;
  char host_entry_buffer[PR_NETDB_BUF_SIZE];
  PRHostEnt host_entry;
  PRStatus rv = PR_GetHostByName(host, host_entry_buffer,
                                 PR_NETDB_BUF_SIZE, &host_entry);
  if (rv != PR_SUCCESS) {
    ThrowPRException("Unsuccessful PR_GetHostByName call");
  }

  int index = PR_EnumerateHostEnt(0, &host_entry, port, &host_address);
  if (index == -1 || index == 0) {
    ThrowPRException("Unsuccessful PR_EnumerateHostEnt call");
  }

  memio_SetPeerName(my_socket, &host_address);
  memio_ = my_socket;
}


void TlsFilter::Handshake() {
  SECStatus status = SSL_ForceHandshake(memio_);
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
      ThrowPRException("Unexpected handshake error");
    }
  }
}


void TlsFilter::Destroy() {
  for (int i = 0; i < kNumBuffers; ++i) {
    Dart_DeletePersistentHandle(dart_buffer_objects_[i]);
    delete[] buffers_[i];
  }
  Dart_DeletePersistentHandle(string_start_);
  Dart_DeletePersistentHandle(string_length_);
  Dart_DeletePersistentHandle(handshake_complete_);
  // TODO(whesse): Free NSS objects here.
}


intptr_t TlsFilter::ProcessBuffer(int buffer_index) {
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
      bytes_processed = PR_Read(memio_,
                                buffer + start + length,
                                bytes_free);
      if (bytes_processed < 0) {
        ASSERT(bytes_processed == -1);
        // TODO(whesse): Handle unexpected errors here.
        PRErrorCode pr_error = PR_GetError();
        if (PR_WOULD_BLOCK_ERROR != pr_error) {
          ThrowPRException("Error reading plaintext from TlsFilter");
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
      memio_Private* secret = memio_GetSecret(memio_);
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
        memio_Private* secret = memio_GetSecret(memio_);
        uint8_t* memio_buf;
        int free_bytes = memio_GetReadParams(secret, &memio_buf);
        if (free_bytes < bytes_processed) bytes_processed = free_bytes;
        memmove(memio_buf,
                buffer + start,
                bytes_processed);
        memio_PutReadResult(secret, bytes_processed);
      }
      break;
    }

    case kWritePlaintext: {
      if (length > 0) {
        bytes_processed = PR_Write(memio_,
                                   buffer + start,
                                   length);
      }

      if (bytes_processed < 0) {
        ASSERT(bytes_processed == -1);
        // TODO(whesse): Handle unexpected errors here.
        PRErrorCode pr_error = PR_GetError();
        if (PR_WOULD_BLOCK_ERROR != pr_error) {
          ThrowPRException("Error reading plaintext from TlsFilter");
        }
        bytes_processed = 0;
      }
      break;
    }
  }
  return bytes_processed;
}
