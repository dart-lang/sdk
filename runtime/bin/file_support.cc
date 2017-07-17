// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/embedded_dart_io.h"
#include "bin/io_buffer.h"
#include "bin/utils.h"

#include "include/dart_api.h"
#include "include/dart_tools_api.h"

namespace dart {
namespace bin {

// Are we capturing output from stdout for the VM service?
static bool capture_stdout = false;

// Are we capturing output from stderr for the VM service?
static bool capture_stderr = false;

void SetCaptureStdout(bool value) {
  capture_stdout = value;
}

void SetCaptureStderr(bool value) {
  capture_stderr = value;
}

bool ShouldCaptureStdout() {
  return capture_stdout;
}

bool ShouldCaptureStderr() {
  return capture_stderr;
}

bool File::ReadFully(void* buffer, int64_t num_bytes) {
  int64_t remaining = num_bytes;
  char* current_buffer = reinterpret_cast<char*>(buffer);
  while (remaining > 0) {
    int64_t bytes_read = Read(current_buffer, remaining);
    if (bytes_read <= 0) {
      return false;
    }
    remaining -= bytes_read;       // Reduce the number of remaining bytes.
    current_buffer += bytes_read;  // Move the buffer forward.
  }
  return true;
}

bool File::WriteFully(const void* buffer, int64_t num_bytes) {
  int64_t remaining = num_bytes;
  const char* current_buffer = reinterpret_cast<const char*>(buffer);
  while (remaining > 0) {
    int64_t bytes_written = Write(current_buffer, remaining);
    if (bytes_written < 0) {
      return false;
    }
    remaining -= bytes_written;       // Reduce the number of remaining bytes.
    current_buffer += bytes_written;  // Move the buffer forward.
  }
  if (capture_stdout || capture_stderr) {
    intptr_t fd = GetFD();
    if ((fd == STDOUT_FILENO) && capture_stdout) {
      Dart_ServiceSendDataEvent("Stdout", "WriteEvent",
                                reinterpret_cast<const uint8_t*>(buffer),
                                num_bytes);
    } else if ((fd == STDERR_FILENO) && capture_stderr) {
      Dart_ServiceSendDataEvent("Stderr", "WriteEvent",
                                reinterpret_cast<const uint8_t*>(buffer),
                                num_bytes);
    }
  }
  return true;
}

File::FileOpenMode File::DartModeToFileMode(DartFileOpenMode mode) {
  ASSERT((mode == File::kDartRead) || (mode == File::kDartWrite) ||
         (mode == File::kDartAppend) || (mode == File::kDartWriteOnly) ||
         (mode == File::kDartWriteOnlyAppend));
  if (mode == File::kDartWrite) {
    return File::kWriteTruncate;
  }
  if (mode == File::kDartAppend) {
    return File::kWrite;
  }
  if (mode == File::kDartWriteOnly) {
    return File::kWriteOnlyTruncate;
  }
  if (mode == File::kDartWriteOnlyAppend) {
    return File::kWriteOnly;
  }
  return File::kRead;
}

}  // namespace bin
}  // namespace dart
