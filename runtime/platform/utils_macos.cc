// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_MACOS)

#include "platform/utils.h"
#include "platform/utils_macos.h"

#include <sys/utsname.h>  // NOLINT

namespace dart {

char* Utils::StrNDup(const char* s, intptr_t n) {
// strndup has only been added to Mac OS X in 10.7. We are supplying
// our own copy here if needed.
#if !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) ||                 \
    __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ <= 1060
  intptr_t len = strlen(s);
  if ((n < 0) || (len < 0)) {
    return nullptr;
  }
  if (n < len) {
    len = n;
  }
  char* result = reinterpret_cast<char*>(malloc(len + 1));
  result[len] = '\0';
  return reinterpret_cast<char*>(memmove(result, s, len));
#else   // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
  return strndup(s, n);
#endif  // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
}

char* Utils::StrDup(const char* s) {
  return strdup(s);
}

intptr_t Utils::StrNLen(const char* s, intptr_t n) {
// strnlen has only been added to Mac OS X in 10.7. We are supplying
// our own copy here if needed.
#if !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) ||                 \
    __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ <= 1060
  intptr_t len = 0;
  while ((len <= n) && (*s != '\0')) {
    s++;
    len++;
  }
  return len;
#else   // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
  return strnlen(s, n);
#endif  // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
}

int Utils::SNPrint(char* str, size_t size, const char* format, ...) {
  va_list args;
  va_start(args, format);
  int retval = VSNPrint(str, size, format, args);
  va_end(args);
  return retval;
}

int Utils::VSNPrint(char* str, size_t size, const char* format, va_list args) {
  int retval = vsnprintf(str, size, format, args);
  if (retval < 0) {
    FATAL("Fatal error in Utils::VSNPrint with format '%s'", format);
  }
  return retval;
}

int Utils::Close(int fildes) {
  return close(fildes);
}
size_t Utils::Read(int filedes, void* buf, size_t nbyte) {
  return read(filedes, buf, nbyte);
}
int Utils::Unlink(const char* path) {
  return unlink(path);
}

namespace internal {

namespace {
// Extracts the version of the running kernel from utsname.release.
bool GetDarwinKernelVersionFromUname(int32_t* kernel_major_version,
                                     int32_t* kernel_minor_version) {
  // uname is implemented as a simple series of sysctl system calls to
  // obtain the relevant data from the kernel. The data is
  // compiled right into the kernel, so no threads or blocking or other
  // funny business is necessary.

  struct utsname uname_info;
  if (uname(&uname_info) != 0) {
    FATAL("GetDarwinKernelVersionFromUname: uname failed");
    return false;
  }

  if (strcmp(uname_info.sysname, "Darwin") != 0) {
    FATAL(
        "GetDarwinKernelVersionFromUname: unexpected uname"
        " sysname '%s'",
        uname_info.sysname);
    return false;
  }

  *kernel_major_version = 0;
  *kernel_minor_version = 0;
  char* dot = strchr(uname_info.release, '.');
  if (dot != nullptr && dot != uname_info.release) {
    char* end_ptr = nullptr;
    *kernel_major_version = strtol(uname_info.release, &end_ptr, 10);
    if (end_ptr == dot) {  // Expected to parse until `.`
      char* minor_start = dot + 1;
      *kernel_minor_version = strtol(minor_start, &end_ptr, 10);
      if (end_ptr != minor_start) {
        return true;
      }
    }
  }

  FATAL(
      "GetDarwinKernelVersionFromUname: "
      " could not parse uname release '%s'",
      uname_info.release);
  return false;
}

}  // namespace

// Returns the running system's Mac OS X or iOS version which matches the
// encoding of *_X_VERSION_* defines in AvailabilityVersions.h
int32_t DarwinVersionInternal() {
  int32_t kernel_major_version;
  int32_t kernel_minor_version;
  if (!GetDarwinKernelVersionFromUname(&kernel_major_version,
                                       &kernel_minor_version)) {
    return 0;
  }

  int32_t major_version = 0;
  int32_t minor_version = 0;

#if defined(DART_HOST_OS_IOS)
  if (kernel_major_version >= 25) {
    // Starting from iOS 26 kernel versions are 1 behind OS version.
    major_version = kernel_major_version + 1;
  } else {
    // We do not expect to run on version of iOS <12.0 so we can assume that
    // kernel version is off by 6 from iOS version (e.g. kernel 18.0 is
    // iOS 12.0). This only holds starting from iOS 4.0.
    major_version = kernel_major_version - 6;
  }
  if (major_version >= 15) {
    // After iOS 15 minor version of kernel is the same as minor version of
    // the iOS release. Before iOS 15 these numbers were not in sync. However
    // We do not expect to check minor version numbers for older iOS
    // releases so we just keep it at 0 for them.
    minor_version = kernel_minor_version;
  }
  const int32_t field_multiplier = 100;
#else
  if (kernel_major_version < 20) {
    // For Mac OS X 10.* minor version is off by 4 from Darwin's major
    // version, e.g. 5.* is v10.1.*, 6.* is v10.2.* and so on.
    // Pretend that anything below Darwin v5 is just Mac OS X Cheetah (v10.0).
    major_version = 10;
    minor_version = Utils::Maximum(0, kernel_major_version - 4);
  } else {
    // Starting from Darwin v20 major version increment in lock-step:
    // Darwin v20 - Mac OS X v11, Darwin v21 - Mac OS X v12, etc
    major_version = (kernel_major_version - 9);
    minor_version = 0;
  }

  // Caveat: MAC_OS_X_VERSION_* is encoded using decimal encoding.
  // Starting at MAC_OS_X_VERSION_10_10 versions use 2 decimal digits for
  // minor version and patch number.
  const int32_t field_multiplier = (kernel_major_version < 14) ? 10 : 100;
#endif
  const int32_t major_multiplier = field_multiplier * field_multiplier;
  const int32_t minor_multiplier = field_multiplier;

  return major_version * major_multiplier + minor_version * minor_multiplier;
}

int32_t DarwinVersion() {
  static int version = DarwinVersionInternal();
  return version;
}

}  // namespace internal

#if !defined(DART_HOST_OS_IOS)
namespace {
int32_t MacOSXMinorVersion(int32_t version) {
  // Caveat: MAC_OS_X_VERSION_* is encoded using decimal encoding.
  // Starting at MAC_OS_X_VERSION_10_10 versions use 2 decimal digits for
  // minor version and patch number.
  const int32_t field_multiplier =
      (version < MAC_OS_X_VERSION_10_10) ? 10 : 100;
  return (version / field_multiplier) % field_multiplier;
}

int32_t MacOSXMajorVersion(int32_t version) {
  // Caveat: MAC_OS_X_VERSION_* is encoded using decimal encoding.
  // Starting at MAC_OS_X_VERSION_10_10 versions use 2 decimal digits for
  // minor version and patch number.
  const int32_t field_multiplier =
      (version < MAC_OS_X_VERSION_10_10) ? 10 : 100;
  return version / (field_multiplier * field_multiplier);
}
}  // namespace

char* CheckIsAtLeastMinRequiredMacOSXVersion() {
  const int32_t current_version = internal::DarwinVersion();

  if (current_version >= MAC_OS_X_VERSION_MIN_REQUIRED) {
    return nullptr;
  }

  return Utils::SCreate(
      "Current Mac OS X version %d.%d is lower than minimum supported version "
      "%d.%d",
      MacOSXMajorVersion(current_version), MacOSXMinorVersion(current_version),
      MacOSXMajorVersion(MAC_OS_X_VERSION_MIN_REQUIRED),
      MacOSXMinorVersion(MAC_OS_X_VERSION_MIN_REQUIRED));
}
#endif

}  // namespace dart

#endif  // defined(DART_HOST_OS_MACOS)
