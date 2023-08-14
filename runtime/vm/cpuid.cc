// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if !defined(DART_HOST_OS_MACOS)
#include "vm/cpuid.h"

#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
// GetCpuId() on Windows, __get_cpuid() on Linux
#if defined(DART_HOST_OS_WINDOWS)
#include <intrin.h>  // NOLINT
#else
#include <cpuid.h>  // NOLINT
#endif
#endif

namespace dart {

bool CpuId::sse2_ = false;
bool CpuId::sse41_ = false;
bool CpuId::popcnt_ = false;
bool CpuId::abm_ = false;

const char* CpuId::id_string_ = nullptr;
const char* CpuId::brand_string_ = nullptr;

#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)

static void GetCpuId(int32_t level, uint32_t info[4]) {
#if defined(DART_HOST_OS_WINDOWS)
  // The documentation for __cpuid is at:
  // http://msdn.microsoft.com/en-us/library/hskdteyh(v=vs.90).aspx
  __cpuid(reinterpret_cast<int*>(info), level);
#else
  __get_cpuid(level, &info[0], &info[1], &info[2], &info[3]);
#endif
}

void CpuId::Init() {
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
  CpuId::popcnt_ = (info[2] & (1 << 23)) != 0;

  GetCpuId(0x80000001, info);
  CpuId::abm_ = (info[2] & (1 << 5)) != 0;

  // Brand string returned by CPUID is expected to be nullptr-terminated,
  // however we have seen cases in the wild which violate this assumption.
  // To avoid going out of bounds when trying to print this string
  // we add null-terminator ourselves, just in case.
  //
  // See https://github.com/flutter/flutter/issues/114346
  char* brand_string = reinterpret_cast<char*>(calloc(3 * sizeof(info) + 1, 1));
  for (uint32_t i = 0; i < 2; i++) {
    GetCpuId(0x80000002U + i, info);
    memmove(&brand_string[i * sizeof(info)], &info, sizeof(info));
  }
  CpuId::brand_string_ = brand_string;
}

void CpuId::Cleanup() {
  ASSERT(id_string_ != nullptr);
  free(const_cast<char*>(id_string_));
  id_string_ = nullptr;

  ASSERT(brand_string_ != nullptr);
  free(const_cast<char*>(brand_string_));
  brand_string_ = nullptr;
}

const char* CpuId::id_string() {
  return Utils::StrDup(id_string_);
}

const char* CpuId::brand_string() {
  return Utils::StrDup(brand_string_);
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
      char buffer[100];
      char* p = buffer;
      const char* q = p + 100;
      *p = '\0';
      if (sse2()) {
        p += snprintf(p, q - p, "sse2 ");
      }
      if (sse41()) {
        p += snprintf(p, q - p, "sse4.1 ");
      }
      if (popcnt()) {
        p += snprintf(p, q - p, "popcnt ");
      }
      if (abm()) {
        p += snprintf(p, q - p, "abm ");
      }
      // Remove last space before returning string.
      if (p != buffer) *(p - 1) = '\0';
      return Utils::StrDup(buffer);
    }
    default: {
      UNREACHABLE();
      return nullptr;
    }
  }
}

#endif  // defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
}  // namespace dart

#endif  // !defined(DART_HOST_OS_MACOS)
