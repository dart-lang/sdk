// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OS_H_
#define RUNTIME_VM_OS_H_

#include "vm/globals.h"

// Forward declarations.
struct tm;

namespace dart {

// Forward declarations.
class Isolate;
class Zone;

// Interface to the underlying OS platform.
class OS {
 public:
  // Returns the name of the given OS. For example "linux".
  static const char* Name();

  // Returns the current process id.
  static intptr_t ProcessId();

  // Returns a time-zone name for the given instant.
  // The name is provided by the underlying platform.
  // The returned string may be Zone allocated.
  static const char* GetTimeZoneName(int64_t seconds_since_epoch);

  // Returns the difference in seconds between local time and UTC for the given
  // instant.
  // For example 3600 for CET, and 7200 for CEST.
  static int GetTimeZoneOffsetInSeconds(int64_t seconds_since_epoch);

  // Returns the difference in seconds between local time and UTC when no
  // daylight saving is active.
  // For example 3600 in CET and CEST.
  static int GetLocalTimeZoneAdjustmentInSeconds();

  // Returns the current time in milliseconds measured
  // from midnight January 1, 1970 UTC.
  static int64_t GetCurrentTimeMillis();

  // Returns the current time in microseconds measured
  // from midnight January 1, 1970 UTC.
  static int64_t GetCurrentTimeMicros();

  // Returns the current time used by the tracing infrastructure.
  static int64_t GetCurrentMonotonicMicros();

  // Returns the raw clock value from the monotonic clock.
  static int64_t GetCurrentMonotonicTicks();

  // Returns the frequency of the monotonic clock.
  static int64_t GetCurrentMonotonicFrequency();

  // Returns the value of current thread's CPU usage clock in microseconds.
  // NOTE: This clock will return different values depending on the calling
  // thread. It is only expected to increase in value as the thread uses
  // CPU time.
  // NOTE: This function will return -1 on OSs that are not supported.
  static int64_t GetCurrentThreadCPUMicros();

  // Returns the activation frame alignment constraint or one if
  // the platform doesn't care. Guaranteed to be a power of two.
  static intptr_t ActivationFrameAlignment();

  // This constant is guaranteed to be greater or equal to the
  // preferred code alignment on all platforms.
  static const int kMaxPreferredCodeAlignment = 32;

  // Returns the preferred code alignment or zero if
  // the platform doesn't care. Guaranteed to be a power of two.
  static intptr_t PreferredCodeAlignment();

  // Returns number of available processor cores.
  static int NumberOfAvailableProcessors();

  // Sleep the currently executing thread for millis ms.
  static void Sleep(int64_t millis);

  // Sleep the currently executing thread for micros microseconds.
  static void SleepMicros(int64_t micros);

  // Debug break.
  static void DebugBreak();

  // Returns the current program counter.
  static uintptr_t GetProgramCounter();

  // Not all platform support strndup.
  static char* StrNDup(const char* s, intptr_t n);
  static intptr_t StrNLen(const char* s, intptr_t n);

  // Print formatted output to stdout/stderr for debugging.
  static void Print(const char* format, ...) PRINTF_ATTRIBUTE(1, 2);
  static void PrintErr(const char* format, ...) PRINTF_ATTRIBUTE(1, 2);
  static void VFPrint(FILE* stream, const char* format, va_list args);
  // Print formatted output info a buffer.
  //
  // Does not write more than size characters (including the trailing '\0').
  //
  // Returns the number of characters (excluding the trailing '\0')
  // that would been written if the buffer had been big enough.  If
  // the return value is greater or equal than the given size then the
  // output has been truncated.  The return value is never negative.
  //
  // The buffer will always be terminated by a '\0', unless the buffer
  // is of size 0.  The buffer might be NULL if the size is 0.
  //
  // This specification conforms to C99 standard which is implemented
  // by glibc 2.1+ with one exception: the C99 standard allows a
  // negative return value.  We will terminate the vm rather than let
  // that occur.
  static int SNPrint(char* str, size_t size, const char* format, ...)
      PRINTF_ATTRIBUTE(3, 4);
  static int VSNPrint(char* str, size_t size, const char* format, va_list args);

  // Allocate a string and print formatted output into the buffer.
  // Uses the zone for allocation if one if provided, and otherwise uses
  // malloc.
  static char* SCreate(Zone* zone, const char* format, ...)
      PRINTF_ATTRIBUTE(2, 3);
  static char* VSCreate(Zone* zone, const char* format, va_list args);

  // Converts a C string which represents a valid dart integer into a 64 bit
  // value.
  // Returns false if it is unable to convert the string to a 64 bit value,
  // the failure could be because of underflow/overflow or invalid characters.
  // On success the function returns true and 'value' contains the converted
  // value.
  static bool StringToInt64(const char* str, int64_t* value);

  // Register code observers relevant to this OS.
  static void RegisterCodeObservers();

  // Initialize the OS class.
  static void InitOnce();

  // Shut down the OS class.
  static void Shutdown();

  static void Abort();

  static void Exit(int code);
};

}  // namespace dart

#endif  // RUNTIME_VM_OS_H_
