// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_UTILS_WIN_H_
#define BIN_UTILS_WIN_H_

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

}  // namespace bin
}  // namespace dart

#endif  // BIN_UTILS_WIN_H_
