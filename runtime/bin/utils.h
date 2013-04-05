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
    kNSS,
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
  // pointer that is different from the input pointer the returned
  // pointer is allocated with malloc and should be freed using free.
  static const char* ConsoleStringToUtf8(const char* str);
  static char* ConsoleStringToUtf8(char* str);
  static const char* Utf8ToConsoleString(const char* utf8);
  static char* Utf8ToConsoleString(char* utf8);
  static char* WideToUtf8(wchar_t* wide);
  static const char* WideToUtf8(const wchar_t* wide);
  static wchar_t* Utf8ToWide(char* utf8);
  static const wchar_t* Utf8ToWide(const char* utf8);
};

class ShellUtils {
 public:
  // Get the arguments passed to the program as unicode strings.
  // If GetUnicodeArgv returns a pointer that pointer has to be
  // deallocated with a call to FreeUnicodeArgv.
  static wchar_t** GetUnicodeArgv(int* argc);
  static void FreeUnicodeArgv(wchar_t** argv);
};

class TimerUtils {
 public:
  static int64_t GetCurrentTimeMicros();
  static int64_t GetCurrentTimeMilliseconds();
  static void Sleep(int64_t millis);
};

#endif  // BIN_UTILS_H_
