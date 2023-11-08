// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_FUCHSIA)

#include "bin/platform.h"

#include <fuchsia/kernel/cpp/fidl.h>
#include <lib/fdio/directory.h>
#include <lib/zx/resource.h>
#include <string.h>
#include <sys/utsname.h>
#include <unistd.h>
#include <zircon/process.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>

#include "bin/console.h"
#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/file.h"

namespace dart {
namespace bin {

const char* Platform::executable_name_ = nullptr;
int Platform::script_index_ = 1;
char** Platform::argv_ = nullptr;

bool Platform::Initialize() {
  return true;
}

int Platform::NumberOfProcessors() {
  return sysconf(_SC_NPROCESSORS_CONF);
}

const char* Platform::OperatingSystemVersion() {
  struct utsname info;
  int ret = uname(&info);
  if (ret != 0) {
    return nullptr;
  }
  const char* kFormat = "%s %s %s";
  int len =
      snprintf(nullptr, 0, kFormat, info.sysname, info.release, info.version);
  if (len <= 0) {
    return nullptr;
  }
  char* result = DartUtils::ScopedCString(len + 1);
  ASSERT(result != nullptr);
  len = snprintf(result, len + 1, kFormat, info.sysname, info.release,
                 info.version);
  if (len <= 0) {
    return nullptr;
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
  if (lang == nullptr) {
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
  while (*(tmp++) != nullptr) {
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
  if (executable_name_ != nullptr) {
    return executable_name_;
  }
  char* name = DartUtils::ScopedCString(ZX_MAX_NAME_LEN);
  zx_status_t status = zx_object_get_property(zx_process_self(), ZX_PROP_NAME,
                                              name, ZX_MAX_NAME_LEN);
  if (status != ZX_OK) {
    return nullptr;
  }
  return name;
}

const char* Platform::ResolveExecutablePath() {
  const char* executable_name = Platform::GetExecutableName();
  if (executable_name == nullptr) {
    return nullptr;
  }
  if ((executable_name[0] == '/') && File::Exists(nullptr, executable_name)) {
    return File::GetCanonicalPath(nullptr, executable_name);
  }
  if (strchr(executable_name, '/') != nullptr) {
    const char* result = File::GetCanonicalPath(nullptr, executable_name);
    if (File::Exists(nullptr, result)) {
      return result;
    }
  } else {
    const char* path = getenv("PATH");
    if (path == nullptr) {
      // If PATH isn't set, make some guesses about where we should look.
      path = "/system/bin:/system/apps:/boot/bin";
    }
    char* pathcopy = DartUtils::ScopedCopyCString(path);
    char* result = DartUtils::ScopedCString(PATH_MAX + 1);
    char* save = nullptr;
    while ((pathcopy = strtok_r(pathcopy, ":", &save)) != nullptr) {
      snprintf(result, PATH_MAX, "%s/%s", pathcopy, executable_name);
      result[PATH_MAX] = '\0';
      if (File::Exists(nullptr, result)) {
        return File::GetCanonicalPath(nullptr, result);
      }
      pathcopy = nullptr;
    }
  }
  // Couldn't find it. This causes null to be returned for
  // Platform.resolvedExecutable.
  return nullptr;
}

intptr_t Platform::ResolveExecutablePathInto(char* result, size_t result_size) {
  return -1;
}

void Platform::SetProcessName(const char* name) {
  zx_object_set_property(zx_process_self(), ZX_PROP_NAME, name,
                         Utils::Minimum(strlen(name), ZX_MAX_NAME_LEN));
}

void Platform::Exit(int exit_code) {
  Console::RestoreConfig();
  Dart_PrepareToAbort();
  exit(exit_code);
}

void Platform::_Exit(int exit_code) {
  Console::RestoreConfig();
  Dart_PrepareToAbort();
  _exit(exit_code);
}

void Platform::SetCoreDumpResourceLimit(int value) {
  // Not supported.
}

zx_handle_t Platform::GetVMEXResource() {
  zx::resource vmex_resource;
  fuchsia::kernel::VmexResourceSyncPtr vmex_resource_svc;
  zx_status_t status = fdio_service_connect(
      "/svc/fuchsia.kernel.VmexResource",
      vmex_resource_svc.NewRequest().TakeChannel().release());
  ASSERT(status == ZX_OK);
  status = vmex_resource_svc->Get(&vmex_resource);
  ASSERT(status == ZX_OK);
  return vmex_resource.release();
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_FUCHSIA)
