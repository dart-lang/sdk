// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_CRYPTO_H_
#define RUNTIME_BIN_CRYPTO_H_

#include "bin/builtin.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

class Crypto {
 public:
  static bool GetRandomBytes(intptr_t count, uint8_t* buffer);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Crypto);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_CRYPTO_H_
