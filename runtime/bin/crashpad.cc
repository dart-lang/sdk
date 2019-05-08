// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/crashpad.h"

#if defined(DART_USE_CRASHPAD)
#include <map>
#include <string>
#include <vector>

#include "crashpad/client/crashpad_client.h"
#include "crashpad/client/crashpad_info.h"
#endif

#include "bin/error_exit.h"
#include "bin/platform.h"
#include "platform/syslog.h"

namespace dart {
namespace bin {

#if defined(DART_USE_CRASHPAD)
#if !defined(HOST_OS_WINDOWS)
#error "Currently we only support Crashpad on Windows"
#endif

void InitializeCrashpadClient() {
  // DART_CRASHPAD_HANDLER and DART_CRASHPAD_CRASHES_DIR are set by the
  // testing framework.
  wchar_t* handler = _wgetenv(L"DART_CRASHPAD_HANDLER");
  wchar_t* crashes_dir = _wgetenv(L"DART_CRASHPAD_CRASHES_DIR");
  if (handler == nullptr || crashes_dir == nullptr || wcslen(handler) == 0 ||
      wcslen(crashes_dir) == 0) {
    return;
  }

  // Crashpad uses STL so we use it here too even though in general we
  // avoid it.
  const base::FilePath handler_path{std::wstring(handler)};
  const base::FilePath crashes_dir_path{std::wstring(crashes_dir)};
  const std::string url("");
  std::map<std::string, std::string> annotations;
  char* test_name = getenv("DART_TEST_NAME");
  if (test_name != nullptr) {
    annotations["dart_test_name"] = test_name;
  }

  std::vector<std::string> arguments;

  crashpad::CrashpadClient client;

  // Prevent crashpad_handler from inheriting our standard output and error
  // handles. Otherwise we would not be able to close them ourselves making
  // tests that rely on that fail.
  HANDLE original_stdout = GetStdHandle(STD_OUTPUT_HANDLE);
  HANDLE original_stderr = GetStdHandle(STD_ERROR_HANDLE);
  SetStdHandle(STD_OUTPUT_HANDLE, INVALID_HANDLE_VALUE);
  SetStdHandle(STD_ERROR_HANDLE, INVALID_HANDLE_VALUE);
  const bool success =
      client.StartHandler(handler_path, crashes_dir_path, crashes_dir_path, url,
                          annotations, arguments,
                          /*restartable=*/true,
                          /*asynchronous_start=*/false);
  SetStdHandle(STD_OUTPUT_HANDLE, original_stdout);
  SetStdHandle(STD_ERROR_HANDLE, original_stderr);

  if (!success) {
    Syslog::PrintErr("Failed to start the crash handler!\n");
    Platform::Exit(kErrorExitCode);
  }
  crashpad::CrashpadInfo::GetCrashpadInfo()
      ->set_gather_indirectly_referenced_memory(crashpad::TriState::kEnabled,
                                                /*limit=*/500 * MB);
}
#else
void InitializeCrashpadClient() {}
#endif  // DART_USE_CRASHPAD

}  // namespace bin
}  // namespace dart
