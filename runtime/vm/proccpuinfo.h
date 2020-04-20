// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PROCCPUINFO_H_
#define RUNTIME_VM_PROCCPUINFO_H_

#include "vm/globals.h"
#if defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)

#include "vm/allocation.h"

namespace dart {

class ProcCpuInfo : public AllStatic {
 public:
  static void Init();
  static void Cleanup();
  static bool FieldContains(const char* field, const char* search_string);
  static const char* ExtractField(const char* field);
  static bool HasField(const char* field);

 private:
  static char* data_;
  static intptr_t datalen_;

  static char* FieldStart(const char* field);
};

}  // namespace dart

#endif  // defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)

#endif  // RUNTIME_VM_PROCCPUINFO_H_
