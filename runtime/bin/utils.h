// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_UTILS_H_
#define RUNTIME_BIN_UTILS_H_

#include <stdlib.h>
#include <string.h>

#include "include/dart_api.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

class OSError {
 public:
  enum SubSystem { kSystem, kGetAddressInfo, kBoringSSL, kUnknown = -1 };

  OSError();
  OSError(int code, const char* message, SubSystem sub_system) {
    sub_system_ = sub_system;
    code_ = code;
    message_ = NULL;  // SetMessage will free existing message.
    SetMessage(message);
  }
  virtual ~OSError() { free(message_); }

  SubSystem sub_system() { return sub_system_; }
  int code() { return code_; }
  char* message() { return message_; }
  void SetCodeAndMessage(SubSystem sub_system, int code);

 private:
  void set_sub_system(SubSystem sub_system) { sub_system_ = sub_system; }
  void set_code(int code) { code_ = code; }
  void SetMessage(const char* message) {
    free(message_);
    if (message == NULL) {
      message_ = NULL;
    } else {
      message_ = strdup(message);
    }
  }

  SubSystem sub_system_;
  int code_;
  char* message_;

  DISALLOW_COPY_AND_ASSIGN(OSError);
};

class StringUtils {
 public:
  // The following methods convert the argument if needed.  The
  // conversions are only needed on Windows. If the methods returns a
  // pointer that is different from the input pointer, the returned
  // pointer is allocated with malloc and should be freed using free.
  //
  // If the len argument is passed then that number of characters are
  // converted. If len is -1, conversion will stop at the first NUL
  // character. If result_len is not NUL, it is used to set the number
  // of characters in the result.
  //
  // These conversion functions are only implemented on Windows as the
  // Dart code only hit this path on Windows.
  static const char* ConsoleStringToUtf8(const char* str,
                                         intptr_t len = -1,
                                         intptr_t* result_len = NULL);
  static char* ConsoleStringToUtf8(char* str,
                                   intptr_t len = -1,
                                   intptr_t* result_len = NULL);
  static const char* Utf8ToConsoleString(const char* utf8,
                                         intptr_t len = -1,
                                         intptr_t* result_len = NULL);
  static char* Utf8ToConsoleString(char* utf8,
                                   intptr_t len = -1,
                                   intptr_t* result_len = NULL);

  // Not all platforms support strndup.
  static char* StrNDup(const char* s, intptr_t n);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(StringUtils);
};

class ShellUtils {
 public:
  // Convert all the arguments to UTF8. On Windows, the arguments are
  // encoded in the current code page and not UTF8.
  //
  // Returns true if the arguments are converted. In that case
  // each of the arguments need to be deallocated using free.
  static bool GetUtf8Argv(int argc, char** argv);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ShellUtils);
};

class TimerUtils {
 public:
  static void InitOnce();
  static int64_t GetCurrentMonotonicMicros();
  static int64_t GetCurrentMonotonicMillis();
  static void Sleep(int64_t millis);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(TimerUtils);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_UTILS_H_
