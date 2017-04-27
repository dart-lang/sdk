// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/platform.h"

#include <string.h>  // NOLINT
#include <unistd.h>  // NOLINT

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


const char* Platform::ResolveExecutablePath() {
  // The string used on the command line to spawn the executable is in argv_[0].
  // If that string is a relative or absolute path, i.e. it contains a '/', then
  // we make the path absolute if it is not already and return it. If argv_[0]
  // does not contain a '/', we assume it is a program whose location is
  // resolved via the PATH environment variable, and search for it using the
  // paths found there.
  const char* path = getenv("PATH");
  if ((strchr(argv_[0], '/') != NULL) || (path == NULL)) {
    if (argv_[0][0] == '/') {
      return File::GetCanonicalPath(argv_[0]);
    } else {
      char* result = DartUtils::ScopedCString(PATH_MAX + 1);
      char* cwd = DartUtils::ScopedCString(PATH_MAX + 1);
      getcwd(cwd, PATH_MAX);
      snprintf(result, PATH_MAX, "%s/%s", cwd, argv_[0]);
      result[PATH_MAX] = '\0';
      ASSERT(File::Exists(result));
      return File::GetCanonicalPath(result);
    }
  } else {
    char* pathcopy = DartUtils::ScopedCopyCString(path);
    char* result = DartUtils::ScopedCString(PATH_MAX + 1);
    char* save = NULL;
    while ((pathcopy = strtok_r(pathcopy, ":", &save)) != NULL) {
      snprintf(result, PATH_MAX, "%s/%s", pathcopy, argv_[0]);
      result[PATH_MAX] = '\0';
      if (File::Exists(result)) {
        return File::GetCanonicalPath(result);
      }
      pathcopy = NULL;
    }
    // Couldn't find it. This causes null to be returned for
    // Platform.resovledExecutable.
    return NULL;
  }
}


void Platform::Exit(int exit_code) {
  exit(exit_code);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
