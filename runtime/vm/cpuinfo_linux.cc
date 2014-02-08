// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_LINUX)

#include "vm/cpuinfo.h"

#include <ctype.h>  // NOLINT
#include <string.h>  // NOLINT

#include "platform/assert.h"

namespace dart {

char* CpuInfo::data_ = NULL;
intptr_t CpuInfo::datalen_ = 0;

void CpuInfo::InitOnce() {
  InitializeFields();

  // Get the size of the cpuinfo file by reading it until the end. This is
  // required because files under /proc do not always return a valid size
  // when using fseek(0, SEEK_END) + ftell(). Nor can they be mmap()-ed.
  static const char PATHNAME[] = "/proc/cpuinfo";
  FILE* fp = fopen(PATHNAME, "r");
  if (fp != NULL) {
    for (;;) {
      char buffer[256];
      size_t n = fread(buffer, 1, sizeof(buffer), fp);
      if (n == 0) {
        break;
      }
      datalen_ += n;
    }
    fclose(fp);
  }

  // Read the contents of the cpuinfo file.
  data_ = new char[datalen_ + 1];
  fp = fopen(PATHNAME, "r");
  if (fp != NULL) {
    for (intptr_t offset = 0; offset < datalen_; ) {
      size_t n = fread(data_ + offset, 1, datalen_ - offset, fp);
      if (n == 0) {
        break;
      }
      offset += n;
    }
    fclose(fp);
  }

  // Zero-terminate the data.
  data_[datalen_] = '\0';
}


static char* FieldStart(char* data, const char* field) {
  // Look for first field occurrence, and ensure it starts the line.
  size_t fieldlen = strlen(field);
  char* p = data;
  for (;;) {
    p = strstr(p, field);
    if (p == NULL) {
      return NULL;
    }
    if (p == data || p[-1] == '\n') {
      break;
    }
    p += fieldlen;
  }

  // Skip to the first colon followed by a space.
  p = strchr(p + fieldlen, ':');
  if (p == NULL || !isspace(p[1])) {
    return NULL;
  }
  p += 2;

  return p;
}


bool CpuInfo::FieldContains(const char* field, const char* search_string) {
  ASSERT(data_ != NULL);
  ASSERT(search_string != NULL);

  char *p = FieldStart(data_, field);
  if (p == NULL) {
    return false;
  }

  // Find the end of the line.
  char* q = strchr(p, '\n');
  if (q == NULL) {
    q = data_ + datalen_;
  }

  char saved_end = *q;
  *q = '\0';
  bool ret = (strcasestr(p, search_string) != NULL);
  *q = saved_end;

  return ret;
}


// Extract the content of a the first occurrence of a given field in
// the content of the cpuinfo file and return it as a heap-allocated
// string that must be freed by the caller using delete[].
// Return NULL if not found.
char* CpuInfo::ExtractField(const char* field) {
  ASSERT(field != NULL);
  ASSERT(data_ != NULL);

  char* p = FieldStart(data_, field);
  if (p == NULL) {
    return NULL;
  }

  // Find the end of the line.
  char* q = strchr(p, '\n');
  if (q == NULL) {
    q = data_ + datalen_;
  }

  intptr_t len = q - p;
  char *result = new char[len + 1];  // plus one for null-terminator.
  // Copy the line into result, leaving enough room for a null-terminator.
  char saved_end = *q;
  *q = '\0';
  strncpy(result, p, len);
  result[len] = '\0';
  *q = saved_end;

  return result;
}


bool CpuInfo::HasField(const char* field) {
  ASSERT(field != NULL);
  ASSERT(data_ != NULL);
  return (FieldStart(data_, field) != NULL);
}


const char* CpuInfo::fields_[kCpuInfoMax] = {0};
void CpuInfo::InitializeFields() {
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
  fields_[kCpuInfoProcessor] = "vendor_id";
  fields_[kCpuInfoModel] = "model name";
  fields_[kCpuInfoFeatures] = "flags";
#elif defined(HOST_ARCH_ARM)
  fields_[kCpuInfoProcessor] = "Processor";
  fields_[kCpuInfoModel] = "Hardware";
  fields_[kCpuInfoFeatures] = "Features";
#elif defined(HOST_ARCH_MIPS)
  fields_[kCpuInfoProcessor] = "system type";
  fields_[kCpuInfoModel] = "cpu model";
  fields_[kCpuInfoFeatures] = "ASEs implemented";
#else
#error Unrecognized target architecture
#endif
}

}  // namespace dart

#endif  // defined(TARGET_OS_LINUX)
