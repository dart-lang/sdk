// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CPUINFO_H_
#define VM_CPUINFO_H_

#include "platform/assert.h"
#include "vm/allocation.h"

namespace dart {

class CpuInfo : public AllStatic {
 public:
  // Indices into cpuinfo field name arrays.
  enum CpuInfoIndices {
    kCpuInfoProcessor = 0,
    kCpuInfoModel = 1,
    kCpuInfoFeatures = 2,
    kCpuInfoMax = 3,
  };

  // If necessary, allocates a buffer [data_] and reads cpuinfo into
  // that buffer.
  static void InitOnce();

  static const char* FieldName(CpuInfoIndices idx) {
    ASSERT((idx >= 0) && (idx < kCpuInfoMax));
    return fields_[idx];
  }

  // Returns true if the cpuinfo field [field] contains the
  // string [search_string].
  static bool FieldContains(const char* field, const char* search_string);
  static bool FieldContainsById(CpuInfoIndices idx, const char* search_string) {
    return FieldContains(FieldName(idx), search_string);
  }

  // Returns true if the cpuinfo field [field] exists and is non-empty.
  static bool HasField(const char* field);

  // Reads the cpuinfo field [field] into the buffer [dest] and returns the
  // length of the field.
  // If [dest] is NULL, ExtractField just returns the length.
  static char* ExtractField(const char* field);

  // Reads the cpuinfo field describing the CPU model into the buffer [dest].
  static char* GetCpuModel() {
    ASSERT(HasField(FieldName(kCpuInfoModel)));
    return ExtractField(FieldName(kCpuInfoModel));
  }

 private:
  // On Linux and Android data_ holds /proc/cpuinfo after Read().
  static char* data_;

  // On Linux and Android, the length of /proc/cpuinfo.
  static intptr_t datalen_;

  // Fills in the fields_ array.
  static void InitializeFields();

  // Cpuinfo field names.
  static const char* fields_[kCpuInfoMax];
};

}  // namespace dart

#endif  // VM_CPUINFO_H_
