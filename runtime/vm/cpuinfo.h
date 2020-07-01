// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CPUINFO_H_
#define RUNTIME_VM_CPUINFO_H_

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/allocation.h"

namespace dart {

// Indices into cpuinfo field name arrays.
enum CpuInfoIndices {
  kCpuInfoProcessor = 0,
  kCpuInfoModel = 1,
  kCpuInfoHardware = 2,
  kCpuInfoFeatures = 3,
  kCpuInfoArchitecture = 4,
  kCpuInfoMax = 5,
};

// For Intel architectures, the method to use to get CPU information.
enum CpuInfoMethod {
  // Use the cpuid instruction.
  kCpuInfoCpuId,

  // Use system calls.
  kCpuInfoSystem,

  // Use whatever the default is for a particular OS:
  // Linux, Windows -> CpuId,
  // Android, MacOS -> System.
  kCpuInfoDefault,
};

class CpuInfo : public AllStatic {
 public:
  static void Init();
  static void Cleanup();

  static const char* FieldName(CpuInfoIndices idx) {
    ASSERT((idx >= 0) && (idx < kCpuInfoMax));
    return fields_[idx];
  }

  // Returns true if the cpuinfo field contains the string.
  static bool FieldContains(CpuInfoIndices idx, const char* search_string);

  // Returns true if the cpuinfo field [field] exists and is non-empty.
  static bool HasField(const char* field);

  // Returns the field describing the CPU model. Caller is responsible for
  // freeing the result.
  static const char* GetCpuModel() {
    if (HasField(FieldName(kCpuInfoHardware))) {
      return ExtractField(kCpuInfoHardware);
    } else {
      return Utils::StrDup("Unknown");
    }
  }

 private:
  // Returns the field. Caller is responsible for freeing the result.
  static const char* ExtractField(CpuInfoIndices idx);

  // The method to use to acquire info about the CPU.
  static CpuInfoMethod method_;

  // Cpuinfo field names.
  static const char* fields_[kCpuInfoMax];
};

}  // namespace dart

#endif  // RUNTIME_VM_CPUINFO_H_
