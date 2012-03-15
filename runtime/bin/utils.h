// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_UTILS_H_
#define BIN_UTILS_H_

#include <stdlib.h>
#include <string.h>

#include "include/dart_api.h"
#include "platform/globals.h"

class OSError {
 public:
  OSError();
  OSError(int code, char* message) {
    code_ = code;
    SetMessage(message);
  }
  virtual ~OSError() { free(message_); }

  int code() { return code_; }
  void set_code(int code) { code_ = code; }
  char* message() { return message_; }
  void SetMessage(char* message) {
    free(message_);
    if (message == NULL) {
      message_ = NULL;
    } else {
      message_ = strdup(message);
    }
  }

 private:
  int code_;
  char* message_;

  DISALLOW_COPY_AND_ASSIGN(OSError);
};

#endif  // BIN_UTILS_H_
