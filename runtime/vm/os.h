// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_OS_H_
#define VM_OS_H_

#include "vm/globals.h"

// Forward declarations.
class tm;

namespace dart {

// Forward declarations.
class Isolate;

// Interface to the underlying OS platform.
class OS {
 public:
  // Takes the seconds since epoch (midnight, January 1, 1970 UTC) and breaks it
  // down into date and time in the UTC timezone.
  // The returned year is offset by 1900. The returned month is 0-based.
  // Returns true if the conversion succeeds, false otherwise.
  static bool GmTime(int64_t seconds_since_epoch, tm* tm_result);

  // Takes the seconds since epoch (midnight, January 1, 1970 UTC) and breaks it
  // down into date and time in the local time.
  // The returned year is offset by 1900. The returned month is 0-based.
  // Returns true if the conversion succeeds, false otherwise.
  static bool LocalTime(int64_t seconds_since_epoch, tm* tm_result);

  // Takes the broken down date and time in UTC timezone and computes the
  // seconds since epoch (midnight, January 1, 1970 UTC).
  // The given year is offset by 1900. The given month is 0-based.
  // Returns true if the conversion succeeds, false otherwise.
  static bool MkGmTime(tm* tm, int64_t* seconds_result);

  // Takes the broken down date and time in local timezone and computes the
  // seconds since epoch (midnight, January 1, 1970 UTC).
  // The given year is offset by 1900. The given month is 0-based.
  // Returns true if the conversion succeeds, false otherwise.
  static bool MkTime(tm* tm, int64_t* seconds_result);

  // Returns the abbreviated time-zone name for the given instant.
  // For example "CET" or "CEST".
  static bool GetTimeZoneName(int64_t seconds_since_epoch,
                              const char** name_result);

  // Returns the difference in seconds between local time and UTC for the given
  // instant.
  // For example 3600 for CET, and 7200 for CEST.
  static bool GetTimeZoneOffsetInSeconds(int64_t seconds_since_epoch,
                                         int* offset_result);

  // Returns the current time in milliseconds measured
  // from midnight January 1, 1970 UTC.
  static int64_t GetCurrentTimeMillis();

  // Returns the current time in microseconds measured
  // from midnight January 1, 1970 UTC.
  static int64_t GetCurrentTimeMicros();

  // Returns the activation frame alignment constraint or zero if
  // the platform doesn't care. Guaranteed to be a power of two.
  static word ActivationFrameAlignment();

  // Returns the preferred code alignment or zero if
  // the platform doesn't care. Guaranteed to be a power of two.
  static word PreferredCodeAlignment();

  // Returns the stack size limit.
  static uword GetStackSizeLimit();

  // Returns number of available processor cores.
  static int NumberOfAvailableProcessors();

  // Sleep the currently executing thread for millis ms.
  static void Sleep(int64_t millis);

  // Debug break.
  static void DebugBreak();

  // Print formatted output to stdout/stderr for debugging.
  static void Print(const char* format, ...);
  static void PrintErr(const char* format, ...);
  static void VFPrint(FILE* stream, const char* format, va_list args);
  // Print formatted output info a buffer.
  // Does not write more than size characters (including the trailing '\0').
  // Returns the number of characters (excluding the trailing '\0') that would
  // been written if the buffer had been big enough.
  // If the return value is greater or equal than the given size then the output
  // has been truncated.
  // The buffer will always be terminated by a '\0', unless the buffer is of
  // size 0.
  // The buffer might be NULL if the size is 0.
  // This specification conforms to C99 standard which is implemented by
  // glibc 2.1+.
  static int SNPrint(char* str, size_t size, const char* format, ...);
  static int VSNPrint(char* str, size_t size,
                      const char* format,
                      va_list args);

  // Initialize the OS class.
  static void InitOnce();

  // Shut down the OS class.
  static void Shutdown();

  static void Abort();

  static void Exit(int code);
};

}  // namespace dart

#endif  // VM_OS_H_
