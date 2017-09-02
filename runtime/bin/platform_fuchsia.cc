// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/platform.h"

#include <magenta/process.h>
#include <magenta/status.h>
#include <magenta/syscalls.h>
#include <string.h>
#include <sys/utsname.h>
#include <unistd.h>

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/file.h"

namespace dart {
namespace bin {

const char* Platform::executable_name_ = NULL;
char* Platform::resolved_executable_name_ = NULL;
int Platform::script_index_ = 1;
char** Platform::argv_ = NULL;

bool Platform::Initialize() {
  return true;
}

int Platform::NumberOfProcessors() {
  return sysconf(_SC_NPROCESSORS_CONF);
}

const char* Platform::OperatingSystem() {
  return "fuchsia";
}

const char* Platform::OperatingSystemVersion() {
  struct utsname info;
  int ret = uname(&info);
  if (ret != 0) {
    return NULL;
  }
  const char* kFormat = "%s %s %s";
  int len =
      snprintf(NULL, 0, kFormat, info.sysname, info.release, info.version);
  if (len <= 0) {
    return NULL;
  }
  char* result = DartUtils::ScopedCString(len + 1);
  ASSERT(result != NULL);
  len = snprintf(result, len + 1, kFormat, info.sysname, info.release,
                 info.version);
  if (len <= 0) {
    return NULL;
  }
  return result;
}

const char* Platform::LibraryPrefix() {
  return "lib";
}

const char* Platform::LibraryExtension() {
  return "so";
}

const char* Platform::LocaleName() {
  char* lang = getenv("LANG");
  if (lang == NULL) {
    return "en_US";
  }
  return lang;
}

bool Platform::LocalHostname(char* buffer, intptr_t buffer_length) {
  return gethostname(buffer, buffer_length) == 0;
}

char** Platform::Environment(intptr_t* count) {
  // Using environ directly is only safe as long as we do not
  // provide access to modifying environment variables.
  intptr_t i = 0;
  char** tmp = environ;
  while (*(tmp++) != NULL) {
    i++;
  }
  *count = i;
  char** result;
  result = reinterpret_cast<char**>(Dart_ScopeAllocate(i * sizeof(*result)));
  for (intptr_t current = 0; current < i; current++) {
    result[current] = environ[current];
  }
  return result;
}

const char* Platform::GetExecutableName() {
  if (executable_name_ != NULL) {
    return executable_name_;
  }
  char* name = DartUtils::ScopedCString(MX_MAX_NAME_LEN);
  mx_status_t status = mx_object_get_property(mx_process_self(), MX_PROP_NAME,
                                              name, MX_MAX_NAME_LEN);
  if (status != MX_OK) {
    return NULL;
  }
  return name;
}

const char* Platform::ResolveExecutablePath() {
  const char* executable_name = Platform::GetExecutableName();
  if (executable_name == NULL) {
    return NULL;
  }
  if ((executable_name[0] == '/') && File::Exists(NULL, executable_name)) {
    return File::GetCanonicalPath(NULL, executable_name);
  }
  if (strchr(executable_name, '/') != NULL) {
    const char* result = File::GetCanonicalPath(NULL, executable_name);
    if (File::Exists(NULL, result)) {
      return result;
    }
  } else {
    const char* path = getenv("PATH");
    if (path == NULL) {
      // If PATH isn't set, make some guesses about where we should look.
      path = "/system/bin:/system/apps:/boot/bin";
    }
    char* pathcopy = DartUtils::ScopedCopyCString(path);
    char* result = DartUtils::ScopedCString(PATH_MAX + 1);
    char* save = NULL;
    while ((pathcopy = strtok_r(pathcopy, ":", &save)) != NULL) {
      snprintf(result, PATH_MAX, "%s/%s", pathcopy, executable_name);
      result[PATH_MAX] = '\0';
      if (File::Exists(NULL, result)) {
        return File::GetCanonicalPath(NULL, result);
      }
      pathcopy = NULL;
    }
  }
  // Couldn't find it. This causes null to be returned for
  // Platform.resovledExecutable.
  return NULL;
}

void Platform::Exit(int exit_code) {
  exit(exit_code);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
