// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_UTILS_WIN_H_
#define RUNTIME_BIN_UTILS_WIN_H_

#include <memory>
#include <utility>

#include "platform/utils.h"

#include "platform/allocation.h"

#define MAX_LONG_PATH 32767

namespace dart {
namespace bin {

void FormatMessageIntoBuffer(DWORD code, wchar_t* buffer, int buffer_length);

// Convert from milliseconds since the Unix epoch to a FILETIME.
FILETIME GetFiletimeFromMillis(int64_t millis);

// These string utility functions return strings that have been allocated with
// Dart_ScopeAllocate(). They should be used only when we are inside an API
// scope. If a string returned by one of these functions must persist beyond
// the scope, then copy the results into a suitable buffer that you have
// allocated.
class StringUtilsWin {
 public:
  static char* WideToUtf8(wchar_t* wide,
                          intptr_t len = -1,
                          intptr_t* result_len = nullptr);
  static const char* WideToUtf8(const wchar_t* wide,
                                intptr_t len = -1,
                                intptr_t* result_len = nullptr);
  static wchar_t* Utf8ToWide(char* utf8,
                             intptr_t len = -1,
                             intptr_t* result_len = nullptr);
  static const wchar_t* Utf8ToWide(const char* utf8,
                                   intptr_t len = -1,
                                   intptr_t* result_len = nullptr);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(StringUtilsWin);
};

// These scopes provide strings converted as indicated by the scope names.
// The provided strings are allocated with 'malloc' and have the same lifetime
// as the scope.
class WideToUtf8Scope {
 public:
  explicit WideToUtf8Scope(const wchar_t* wide)
      : utf8_(CStringUniquePtr(nullptr)) {
    intptr_t utf8_len =
        WideCharToMultiByte(CP_UTF8, 0, wide, -1, nullptr, 0, nullptr, nullptr);
    char* utf8 = reinterpret_cast<char*>(malloc(utf8_len));
    WideCharToMultiByte(CP_UTF8, 0, wide, -1, utf8, utf8_len, nullptr, nullptr);
    length_ = utf8_len;
    utf8_.reset(utf8);
  }

  char* utf8() const { return utf8_.get(); }
  intptr_t length() const { return length_; }

  // Release the ownership of the converted string and return it.
  CStringUniquePtr release() { return std::move(utf8_); }

 private:
  intptr_t length_;
  CStringUniquePtr utf8_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(WideToUtf8Scope);
};

std::unique_ptr<wchar_t[]> Utf8ToWideChar(const char* path);

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_UTILS_WIN_H_
