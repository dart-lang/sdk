// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_BIGINT_STORE_H_
#define VM_BIGINT_STORE_H_

#include "vm/globals.h"

namespace dart {

// Use to store teporary BIGNUMs.
class BigintStore {
 public:
  BigintStore() : bn_(NULL), bn_ctx_(NULL) {}
  ~BigintStore() {
    BN_free(bn_);
    BN_CTX_free(bn_ctx_);
  }

  static BigintStore* Get() {
    BigintStore* store = Isolate::Current()->bigint_store();
    if (store == NULL) {
      store = new BigintStore();
      Isolate::Current()->set_bigint_store(store);
    }
    return store;
  }

  BIGNUM* bn_;
  BN_CTX* bn_ctx_;
};

}  // namespace dart

#endif  // VM_BIGINT_STORE_H_
