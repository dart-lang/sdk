// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_VERSION_H_
#define RUNTIME_VM_VERSION_H_

#include "vm/allocation.h"

namespace dart {

class Version : public AllStatic {
 public:
  static const char* String();
  static const char* SnapshotString();

 private:
  static const char* str_;
  static const char* snapshot_hash_;
};

}  // namespace dart

#endif  // RUNTIME_VM_VERSION_H_
