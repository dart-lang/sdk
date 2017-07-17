// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if !defined(HOST_OS_MACOS)
#include "vm/cpuid.h"

#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
// GetCpuId() on Windows, __get_cpuid() on Linux
#if defined(HOST_OS_WINDOWS)
#include <intrin.h>  // NOLINT
#else
#include <cpuid.h>  // NOLINT
#endif
#endif

namespace dart {

bool CpuId::sse2_ = false;
bool CpuId::sse41_ = false;
const char* CpuId::id_string_ = NULL;
const char* CpuId::brand_string_ = NULL;

#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)

void CpuId::GetCpuId(int32_t level, uint32_t info[4]) {
#if defined(HOST_OS_WINDOWS)
  // The documentation for __cpuid is at:
  // http://msdn.microsoft.com/en-us/library/hskdteyh(v=vs.90).aspx
  __cpuid(reinterpret_cast<int*>(info), level);
#else
  __get_cpuid(level, &info[0], &info[1], &info[2], &info[3]);
#endif
}

void CpuId::InitOnce() {
  uint32_t info[4] = {static_cast<uint32_t>(-1)};

  GetCpuId(0, info);
  char* id_string = reinterpret_cast<char*>(malloc(3 * sizeof(int32_t)));
  // Yes, these are supposed to be out of order.
  *reinterpret_cast<uint32_t*>(id_string) = info[1];
  *reinterpret_cast<uint32_t*>(id_string + 4) = info[3];
  *reinterpret_cast<uint32_t*>(id_string + 8) = info[2];
  CpuId::id_string_ = id_string;

  GetCpuId(1, info);
  CpuId::sse41_ = (info[2] & (1 << 19)) != 0;
  CpuId::sse2_ = (info[3] & (1 << 26)) != 0;

  char* brand_string =
      reinterpret_cast<char*>(malloc(3 * 4 * sizeof(uint32_t)));
  for (uint32_t i = 0x80000002; i <= 0x80000004; i++) {
    uint32_t off = (i - 0x80000002U) * 4 * sizeof(uint32_t);
    GetCpuId(i, info);
    *reinterpret_cast<int32_t*>(brand_string + off) = info[0];
    *reinterpret_cast<int32_t*>(brand_string + off + 4) = info[1];
    *reinterpret_cast<int32_t*>(brand_string + off + 8) = info[2];
    *reinterpret_cast<int32_t*>(brand_string + off + 12) = info[3];
  }
  CpuId::brand_string_ = brand_string;
}

void CpuId::Cleanup() {
  ASSERT(id_string_ != NULL);
  free(const_cast<char*>(id_string_));
  id_string_ = NULL;

  ASSERT(brand_string_ != NULL);
  free(const_cast<char*>(brand_string_));
  brand_string_ = NULL;
}

const char* CpuId::id_string() {
  return strdup(id_string_);
}

const char* CpuId::brand_string() {
  return strdup(brand_string_);
}

const char* CpuId::field(CpuInfoIndices idx) {
  switch (idx) {
    case kCpuInfoProcessor:
      return id_string();
    case kCpuInfoModel:
      return brand_string();
    case kCpuInfoHardware:
      return brand_string();
    case kCpuInfoFeatures: {
      if (sse2() && sse41()) {
        return strdup("sse2 sse4.1");
      } else if (sse2()) {
        return strdup("sse2");
      } else if (sse41()) {
        return strdup("sse4.1");
      } else {
        return strdup("");
      }
    }
    default: {
      UNREACHABLE();
      return NULL;
    }
  }
}

#endif  // defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
}  // namespace dart

#endif  // !defined(HOST_OS_MACOS)
