// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED) && !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "bin/secure_socket_utils.h"

#include <openssl/err.h>
#include <openssl/ssl.h>

#include "platform/globals.h"

#include "bin/file.h"
#include "bin/log.h"
#include "bin/secure_socket_filter.h"
#include "bin/security_context.h"

namespace dart {
namespace bin {

// Get the error messages from BoringSSL, and put them in buffer as a
// null-terminated string.
void SecureSocketUtils::FetchErrorString(const SSL* ssl,
                                         TextBuffer* text_buffer) {
  const char* sep = File::PathSeparator();
  while (true) {
    const char* path = NULL;
    int line = -1;
    uint32_t error = ERR_get_error_line(&path, &line);
    if (error == 0) {
      break;
    }
    text_buffer->Printf("\n\t%s", ERR_reason_error_string(error));
    if ((ssl != NULL) && (ERR_GET_LIB(error) == ERR_LIB_SSL) &&
        (ERR_GET_REASON(error) == SSL_R_CERTIFICATE_VERIFY_FAILED)) {
      intptr_t result = SSL_get_verify_result(ssl);
      text_buffer->Printf(": %s", X509_verify_cert_error_string(result));
    }
    if ((path != NULL) && (line >= 0)) {
      const char* file = strrchr(path, sep[0]);
      path = file ? file + 1 : path;
      text_buffer->Printf("(%s:%d)", path, line);
    }
  }
}

// Handle an error reported from the BoringSSL library.
void SecureSocketUtils::ThrowIOException(int status,
                                         const char* exception_type,
                                         const char* message,
                                         const SSL* ssl) {
  Dart_Handle exception;
  {
    TextBuffer error_string(SSL_ERROR_MESSAGE_BUFFER_SIZE);
    SecureSocketUtils::FetchErrorString(ssl, &error_string);
    OSError os_error_struct(status, error_string.buf(), OSError::kBoringSSL);
    Dart_Handle os_error = DartUtils::NewDartOSError(&os_error_struct);
    exception =
        DartUtils::NewDartIOException(exception_type, message, os_error);
    ASSERT(!Dart_IsError(exception));
  }
  Dart_ThrowException(exception);
  UNREACHABLE();
}

void SecureSocketUtils::CheckStatusSSL(int status,
                                       const char* type,
                                       const char* message,
                                       const SSL* ssl) {
  // TODO(24183): Take appropriate action on failed calls,
  // throw exception that includes all messages from the error stack.
  if (status == 1) {
    return;
  }
  if (SSL_LOG_STATUS) {
    int error = ERR_get_error();
    Log::PrintErr("Failed: %s status %d", message, status);
    char error_string[SSL_ERROR_MESSAGE_BUFFER_SIZE];
    ERR_error_string_n(error, error_string, SSL_ERROR_MESSAGE_BUFFER_SIZE);
    Log::PrintErr("ERROR: %d %s\n", error, error_string);
  }
  SecureSocketUtils::ThrowIOException(status, type, message, ssl);
}

void SecureSocketUtils::CheckStatus(int status,
                                    const char* type,
                                    const char* message) {
  SecureSocketUtils::CheckStatusSSL(status, type, message, NULL);
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_DISABLED) &&
        // !defined(DART_IO_SECURE_SOCKET_DISABLED)
