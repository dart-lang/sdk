// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_MACOS)

#include "platform/utils.h"
#include "platform/utils_macos.h"

#include <errno.h>        // NOLINT
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

// Returns the running system's Darwin major version. Don't call this, it's
// an implementation detail and its result is meant to be cached by
// MacOSXMinorVersion.
int32_t DarwinMajorVersionInternal() {
  // uname is implemented as a simple series of sysctl system calls to
  // obtain the relevant data from the kernel. The data is
  // compiled right into the kernel, so no threads or blocking or other
  // funny business is necessary.

  struct utsname uname_info;
  if (uname(&uname_info) != 0) {
    FATAL("Fatal error in DarwinMajorVersionInternal : invalid return uname");
    return 0;
  }

  if (strcmp(uname_info.sysname, "Darwin") != 0) {
    FATAL(
        "Fatal error in DarwinMajorVersionInternal : unexpected uname"
        " sysname '%s'",
        uname_info.sysname);
    return 0;
  }

  int32_t darwin_major_version = 0;
  char* dot = strchr(uname_info.release, '.');
  if (dot) {
    errno = 0;
    char* end_ptr = nullptr;
    darwin_major_version = strtol(uname_info.release, &end_ptr, 10);
    if (errno != 0 || (end_ptr == uname_info.release)) {
      dot = nullptr;
    }
  }

  if (!dot) {
    FATAL(
        "Fatal error in DarwinMajorVersionInternal :"
        " could not parse uname release '%s'",
        uname_info.release);
    return 0;
  }

  return darwin_major_version;
}

// Returns the running system's Mac OS X version which matches the encoding
// of MAC_OS_X_VERSION_* defines in AvailabilityMacros.h
int32_t MacOSXVersionInternal() {
  const int32_t darwin_major_version = DarwinMajorVersionInternal();

  int32_t major_version;
  int32_t minor_version;

  if (darwin_major_version < 20) {
    // For Mac OS X 10.* minor version is off by 4 from Darwin's major
    // version, e.g. 5.* is v10.1.*, 6.* is v10.2.* and so on.
    // Pretend that anything below Darwin v5 is just Mac OS X Cheetah (v10.0).
    major_version = 10;
    minor_version = Utils::Maximum(0, darwin_major_version - 4);
  } else {
    // Starting from Darwin v20 major version increment in lock-step:
    // Darwin v20 - Mac OS X v11, Darwin v21 - Mac OS X v12, etc
    major_version = (darwin_major_version - 9);
    minor_version = 0;
  }

  // Caveat: MAC_OS_X_VERSION_* is encoded using decimal encoding.
  // Starting at MAC_OS_X_VERSION_10_10 versions use 2 decimal digits for
  // minor version and patch number.
  const int32_t field_multiplier = (darwin_major_version < 14) ? 10 : 100;
  const int32_t major_multiplier = field_multiplier * field_multiplier;
  const int32_t minor_multiplier = field_multiplier;

  return major_version * major_multiplier + minor_version * minor_multiplier;
}

int32_t MacOSXVersion() {
  static int mac_os_x_version = MacOSXVersionInternal();
  return mac_os_x_version;
}

}  // namespace internal

namespace {
int32_t MacOSMinorVersion(int32_t version) {
  // Caveat: MAC_OS_X_VERSION_* is encoded using decimal encoding.
  // Starting at MAC_OS_X_VERSION_10_10 versions use 2 decimal digits for
  // minor version and patch number.
  const int32_t field_multiplier =
      (version < MAC_OS_X_VERSION_10_10) ? 10 : 100;
  return (version / field_multiplier) % field_multiplier;
}

int32_t MacOSMajorVersion(int32_t version) {
  // Caveat: MAC_OS_X_VERSION_* is encoded using decimal encoding.
  // Starting at MAC_OS_X_VERSION_10_10 versions use 2 decimal digits for
  // minor version and patch number.
  const int32_t field_multiplier =
      (version < MAC_OS_X_VERSION_10_10) ? 10 : 100;
  return version / (field_multiplier * field_multiplier);
}
}  // namespace

char* CheckIsAtLeastMinRequiredMacOSVersion() {
  const int32_t current_version = internal::MacOSXVersion();

  if (current_version >= MAC_OS_X_VERSION_MIN_REQUIRED) {
    return nullptr;
  }

  return Utils::SCreate(
      "Current Mac OS X version %d.%d is lower than minimum supported version "
      "%d.%d",
      MacOSMajorVersion(current_version), MacOSMinorVersion(current_version),
      MacOSMajorVersion(MAC_OS_X_VERSION_MIN_REQUIRED),
      MacOSMinorVersion(MAC_OS_X_VERSION_MIN_REQUIRED));
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_MACOS)
