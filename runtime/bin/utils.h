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
  enum SubSystem {
    kSystem,
    kGetAddressInfo,
    kUnknown = -1
  };

  OSError();
  OSError(int code, const char* message, SubSystem sub_system) {
    sub_system_ = sub_system;
    code_ = code;
    message_ = NULL;  // SetMessage will free existing message.
    SetMessage(message);
  }
  virtual ~OSError() { free(message_); }

  SubSystem sub_system() { return sub_system_; }
  void set_sub_system(SubSystem sub_system) { sub_system_ = sub_system; }
  int code() { return code_; }
  void set_code(int code) { code_ = code; }
  char* message() { return message_; }
  void SetMessage(const char* message) {
    free(message_);
    if (message == NULL) {
      message_ = NULL;
    } else {
      message_ = strdup(message);
    }
  }

 private:
  SubSystem sub_system_;
  int code_;
  char* message_;

  DISALLOW_COPY_AND_ASSIGN(OSError);
};

#endif  // BIN_UTILS_H_
