// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "vm/cpuinfo.h"

// __cpuid()
#include <intrin.h>  // NOLINT
#include <string.h>  // NOLINT

#include "platform/assert.h"

namespace dart {

struct CpuIdData {
  static bool sse2;
  static bool sse41;
  static char* id_string;
  static char* brand_string;
};


char* CpuInfo::data_ = NULL;
intptr_t CpuInfo::datalen_ = 0;
bool CpuIdData::sse2 = false;
bool CpuIdData::sse41 = false;
char* CpuIdData::id_string = NULL;
char* CpuIdData::brand_string = NULL;


// The documentation for __cpuid is at:
// http://msdn.microsoft.com/en-us/library/hskdteyh(v=vs.90).aspx
// InitOnce reads and caches __cpuid results for use by CpuInfo.
void CpuInfo::InitOnce() {
  int32_t info[4] = {-1};

  InitializeFields();

  __cpuid(info, 0);
  char *id_string = new char[3 * sizeof(int32_t)];
  // Yes, these are supposed to be out of order.
  *reinterpret_cast<int32_t*>(id_string) = info[1];
  *reinterpret_cast<int32_t*>(id_string + 4) = info[3];
  *reinterpret_cast<int32_t*>(id_string + 8) = info[2];
  CpuIdData::id_string = id_string;

  __cpuid(info, 1);
  CpuIdData::sse41 = (info[2] & (1 << 19)) != 0;
  CpuIdData::sse2 = (info[3] & (1 << 26)) != 0;

  char* brand_string = new char[3 * 4 * sizeof(int32_t)];
  for (intptr_t i = 0x80000002; i <= 0x80000004; i++) {
    intptr_t off = (i - 0x80000002) * 4 * sizeof(int32_t);
    __cpuid(info, i);
    *reinterpret_cast<int32_t*>(brand_string + off) = info[0];
    *reinterpret_cast<int32_t*>(brand_string + off + 4) = info[1];
    *reinterpret_cast<int32_t*>(brand_string + off + 8) = info[2];
    *reinterpret_cast<int32_t*>(brand_string + off + 12) = info[3];
  }
  CpuIdData::brand_string = brand_string;
}


bool CpuInfo::FieldContains(const char* field, const char* search_string) {
  if (strcmp(field, fields_[kCpuInfoProcessor]) == 0) {
    return strstr(CpuIdData::id_string, search_string);
  } else if (strcmp(field, fields_[kCpuInfoModel]) == 0) {
    return strstr(CpuIdData::brand_string, search_string);
  } else if (strcmp(field, fields_[kCpuInfoFeatures]) == 0) {
    if (strcmp(search_string, "sse2") == 0) {
      return CpuIdData::sse2;
    } else if (strcmp(search_string, "sse4.1") == 0) {
      return CpuIdData::sse41;
    } else {
      return false;
    }
  } else {
    UNIMPLEMENTED();
  }
  return false;
}


char* CpuInfo::ExtractField(const char* field) {
  if (strcmp(field, fields_[kCpuInfoProcessor]) == 0) {
    return CpuIdData::id_string;
  } else if (strcmp(field, fields_[kCpuInfoModel]) == 0) {
    return CpuIdData::brand_string;
  } else {
    UNIMPLEMENTED();
  }
  return NULL;
}


bool CpuInfo::HasField(const char* field) {
  return (strcmp(field, fields_[kCpuInfoProcessor]) == 0) ||
         (strcmp(field, fields_[kCpuInfoModel]) == 0) ||
         (strcmp(field, fields_[kCpuInfoFeatures]) == 0);
}


const char* CpuInfo::fields_[kCpuInfoMax] = {0};
void CpuInfo::InitializeFields() {
  fields_[kCpuInfoProcessor] = "Processor";
  fields_[kCpuInfoModel] = "Hardware";
  fields_[kCpuInfoFeatures] = "Features";
}

}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
