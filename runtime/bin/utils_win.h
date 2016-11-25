// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_UTILS_WIN_H_
#define RUNTIME_BIN_UTILS_WIN_H_

#include "platform/globals.h"

namespace dart {
namespace bin {

void FormatMessageIntoBuffer(DWORD code, wchar_t* buffer, int buffer_length);

// These string utility functions return strings that have been allocated with
// Dart_ScopeAllocate(). They should be used only when we are inside an API
// scope. If a string returned by one of these functions must persist beyond
// the scope, then copy the results into a suitable buffer that you have
// allocated.
class StringUtilsWin {
 public:
  static char* WideToUtf8(wchar_t* wide,
                          intptr_t len = -1,
                          intptr_t* result_len = NULL);
  static const char* WideToUtf8(const wchar_t* wide,
                                intptr_t len = -1,
                                intptr_t* result_len = NULL);
  static wchar_t* Utf8ToWide(char* utf8,
                             intptr_t len = -1,
                             intptr_t* result_len = NULL);
  static const wchar_t* Utf8ToWide(const char* utf8,
                                   intptr_t len = -1,
                                   intptr_t* result_len = NULL);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(StringUtilsWin);
};

// These scopes provide strings converted as indicated by the scope names.
// The provided strings are allocated with 'new' and have the same lifetime as
// the scope.
class WideToUtf8Scope {
 public:
  explicit WideToUtf8Scope(const wchar_t* wide) {
    intptr_t utf8_len =
        WideCharToMultiByte(CP_UTF8, 0, wide, -1, NULL, 0, NULL, NULL);
    char* utf8 = new char[utf8_len];
    WideCharToMultiByte(CP_UTF8, 0, wide, -1, utf8, utf8_len, NULL, NULL);
    length_ = utf8_len;
    utf8_ = utf8;
  }

  ~WideToUtf8Scope() {
    delete[] utf8_;
    utf8_ = NULL;
  }

  char* utf8() const { return utf8_; }
  intptr_t length() const { return length_; }

 private:
  intptr_t length_;
  char* utf8_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(WideToUtf8Scope);
};

class Utf8ToWideScope {
 public:
  explicit Utf8ToWideScope(const char* utf8) {
    int wide_len = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
    wchar_t* wide = new wchar_t[wide_len];
    MultiByteToWideChar(CP_UTF8, 0, utf8, -1, wide, wide_len);
    length_ = wide_len;
    wide_ = wide;
  }

  ~Utf8ToWideScope() { delete[] wide_; }

  wchar_t* wide() const { return wide_; }
  intptr_t length() const { return length_; }

 private:
  intptr_t length_;
  wchar_t* wide_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Utf8ToWideScope);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_UTILS_WIN_H_
