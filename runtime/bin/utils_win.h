// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_UTILS_WIN_H_
#define BIN_UTILS_WIN_H_

#include "platform/globals.h"

namespace dart {
namespace bin {

void FormatMessageIntoBuffer(DWORD code, wchar_t* buffer, int buffer_length);

}  // namespace bin
}  // namespace dart

#endif  // BIN_UTILS_WIN_H_
