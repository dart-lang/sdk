// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_ABI_VERSION_H_
#define RUNTIME_BIN_ABI_VERSION_H_

namespace dart {

class AbiVersion {
 public:
  static int GetCurrent();
  static int GetOldestSupported();
};

}  // namespace dart

#endif  // RUNTIME_BIN_ABI_VERSION_H_
