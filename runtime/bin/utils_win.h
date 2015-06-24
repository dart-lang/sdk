// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_UTILS_WIN_H_
#define BIN_UTILS_WIN_H_

#include "platform/globals.h"

namespace dart {
namespace bin {

void FormatMessageIntoBuffer(DWORD code, wchar_t* buffer, int buffer_length);

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
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_UTILS_WIN_H_
