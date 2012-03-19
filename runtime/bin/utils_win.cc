// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>

#include "bin/utils.h"

OSError::OSError() : sub_system_(kSystem), code_(0), message_(NULL) {
  set_code(GetLastError());

  static const int kMaxMessageLength = 256;
  char message[kMaxMessageLength];
  DWORD message_size =
      FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                    NULL,
                    code_,
                    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                    message,
                    kMaxMessageLength,
                    NULL);
  if (message_size == 0) {
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      fprintf(stderr, "FormatMessage failed %d\n", GetLastError());
    }
    snprintf(message, kMaxMessageLength, "OS Error %d", code_);
  }
  message[kMaxMessageLength - 1] = '\0';

  SetMessage(message);
}
