// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_GDBJIT_LINUX_H_
#define VM_GDBJIT_LINUX_H_

#include <stdint.h>

extern "C" {
  void addDynamicSection(const char* symfile_addr, uint64_t symfile_size);
  void deleteDynamicSections();
};

#endif  // VM_GDBJIT_LINUX_H_
