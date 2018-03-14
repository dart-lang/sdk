// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)
#include "bin/console.h"

#include "bin/file.h"
#include "bin/lockers.h"
#include "bin/platform.h"
#include "bin/utils.h"
#include "bin/utils_win.h"

// These are not always defined in the header files. See:
// https://msdn.microsoft.com/en-us/library/windows/desktop/ms686033(v=vs.85).aspx
#ifndef ENABLE_VIRTUAL_TERMINAL_PROCESSING
#define ENABLE_VIRTUAL_TERMINAL_PROCESSING 0x0004
#endif

namespace dart {
namespace bin {

class ConsoleWin {
 public:
  static const int kInvalidFlag = -1;

  static void Initialize() {
    saved_output_cp_ = kInvalidFlag;
    saved_input_cp_ = kInvalidFlag;
    // Set up a signal handler that restores the console state on a
    // CTRL_C_EVENT signal. This will only run when there is no signal handler
    // registered for the CTRL_C_EVENT from Dart code.
    SetConsoleCtrlHandler(SignalHandler, TRUE);

    // Set both the input and output code pages to UTF8.
    const int output_cp = GetConsoleOutputCP();
    const int input_cp = GetConsoleCP();
    if (output_cp != CP_UTF8) {
      SetConsoleOutputCP(CP_UTF8);
      saved_output_cp_ = output_cp;
    }
    if (input_cp != CP_UTF8) {
      SetConsoleCP(CP_UTF8);
      saved_input_cp_ = input_cp;
    }

    // Try to set the bits for ANSI support, but swallow any failures.
    saved_stdout_mode_ =
        ModifyMode(STD_OUTPUT_HANDLE, ENABLE_VIRTUAL_TERMINAL_PROCESSING);
    saved_stderr_mode_ =
        ModifyMode(STD_ERROR_HANDLE, ENABLE_VIRTUAL_TERMINAL_PROCESSING);
    saved_stdin_mode_ = ModifyMode(STD_INPUT_HANDLE, 0);

    // TODO(28984): Due to issue #29104, we cannot set
    // ENABLE_VIRTUAL_TERMINAL_INPUT here, as it causes ENABLE_PROCESSED_INPUT
    // to be ignored.
  }

  static void Cleanup() {
    // STD_OUTPUT_HANDLE, may have been closed or redirected. Therefore, we
    // explicitly open the CONOUT$, CONERR$ and CONIN$ devices, so that we can
    // be sure that we are really restoring the console to its original state.
    if (saved_stdout_mode_ != kInvalidFlag) {
      CleanupDevices("CONOUT$", STD_OUTPUT_HANDLE, saved_stdout_mode_);
      saved_stdout_mode_ = kInvalidFlag;
    }
    if (saved_stderr_mode_ != kInvalidFlag) {
      CleanupDevices("CONERR$", STD_ERROR_HANDLE, saved_stderr_mode_);
    }
    if (saved_stdin_mode_ != kInvalidFlag) {
      CleanupDevices("CONIN$", STD_INPUT_HANDLE, saved_stdin_mode_);
    }
    if (saved_output_cp_ != kInvalidFlag) {
      SetConsoleOutputCP(saved_output_cp_);
      saved_output_cp_ = kInvalidFlag;
    }
    if (saved_input_cp_ != kInvalidFlag) {
      SetConsoleCP(saved_input_cp_);
      saved_input_cp_ = kInvalidFlag;
    }
  }

 private:
  static int saved_output_cp_;
  static int saved_input_cp_;
  static DWORD saved_stdout_mode_;
  static DWORD saved_stderr_mode_;
  static DWORD saved_stdin_mode_;

  static BOOL WINAPI SignalHandler(DWORD signal) {
    if (signal == CTRL_C_EVENT) {
      Cleanup();
    }
    return FALSE;
  }

  static DWORD ModifyMode(DWORD handle, DWORD flags) {
    HANDLE h = GetStdHandle(handle);
    DWORD mode;
    DWORD old_mode = kInvalidFlag;

    /// GetConsoleMode fails if this instance of the VM isn't attached to a
    /// console. In that case, we'll just return kInvalidFlag and won't try
    /// to reset the state when we cleanup.
    if ((h != INVALID_HANDLE_VALUE) && GetConsoleMode(h, &mode)) {
      old_mode = mode;
      if (flags != 0) {
        const DWORD request = mode | flags;
        SetConsoleMode(h, request);
      }
    }
    return old_mode;
  }

  static void CleanupDevices(const char* device,
                             DWORD handle,
                             DWORD orig_flags) {
    const intptr_t kWideBufLen = 64;
    wchar_t widebuf[kWideBufLen];
    int result =
        MultiByteToWideChar(CP_UTF8, 0, device, -1, widebuf, kWideBufLen);
    ASSERT(result != 0);
    HANDLE h = CreateFileW(widebuf, GENERIC_READ | GENERIC_WRITE,
                           FILE_SHARE_READ, 0, OPEN_EXISTING, 0, 0);
    if (h != INVALID_HANDLE_VALUE) {
      SetStdHandle(STD_OUTPUT_HANDLE, h);
      if (orig_flags != kInvalidFlag) {
        SetConsoleMode(h, orig_flags);
      }
    }
  }

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ConsoleWin);
};

int ConsoleWin::saved_output_cp_ = ConsoleWin::kInvalidFlag;
int ConsoleWin::saved_input_cp_ = ConsoleWin::kInvalidFlag;
DWORD ConsoleWin::saved_stdout_mode_ = ConsoleWin::kInvalidFlag;
DWORD ConsoleWin::saved_stderr_mode_ = ConsoleWin::kInvalidFlag;
DWORD ConsoleWin::saved_stdin_mode_ = ConsoleWin::kInvalidFlag;

void Console::SaveConfig() {
  ConsoleWin::Initialize();
}

void Console::RestoreConfig() {
  ConsoleWin::Cleanup();
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
