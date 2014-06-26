// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_REPORT_H_
#define VM_REPORT_H_

#include "vm/allocation.h"

namespace dart {

// Forward declarations.
class Error;
class ICData;
class RawString;
class Script;
class StackFrame;
class String;

class Report : AllStatic {
 public:
  enum Kind {
    kWarning,
    kJSWarning,
    kError,
    kMalformedType,
    kMalboundedType,
    kBailout,
  };

  // Report an already formatted error via a long jump.
  static void LongJump(const Error& error);

  // Concatenate and report an already formatted error and a new error message.
  static void LongJumpF(const Error& prev_error,
                        const Script& script, intptr_t token_pos,
                        const char* format, ...) PRINTF_ATTRIBUTE(4, 5);
  static void LongJumpV(const Error& prev_error,
                        const Script& script, intptr_t token_pos,
                        const char* format, va_list args);

  // Report a warning/jswarning/error/bailout message.
  static void MessageF(Kind kind, const Script& script, intptr_t token_pos,
                       const char* format, ...) PRINTF_ATTRIBUTE(4, 5);
  static void MessageV(Kind kind, const Script& script, intptr_t token_pos,
                       const char* format, va_list args);

  // Support to report Javascript compatibility warnings. Note that a
  // JavascriptCompatibilityError is thrown if --warning_as_error is specified.
  // If a warning is issued by the various JSWarning calls, the warning is also
  // emitted in the trace buffer of the current isolate.

  // Report a Javascript compatibility warning at the call site given by
  // ic_data, unless one has already been emitted at that location.
  static void JSWarningFromIC(const ICData& ic_data, const char* msg);

  // Report a Javascript compatibility warning at the current native call,
  // unless one has already been emitted at that location.
  static void JSWarningFromNative(bool is_static_native, const char* msg);

  // Report a Javascript compatibility warning at the call site given by
  // caller_frame.
  static void JSWarningFromFrame(StackFrame* caller_frame, const char* msg);

  // Prepend a source snippet to the message.
  // A null script means no source and a negative token_pos means no position.
  static RawString* PrependSnippet(Kind kind,
                                   const Script& script,
                                   intptr_t token_pos,
                                   const String& message);

 private:
  // Emit a Javascript compatibility warning to the current trace buffer.
  static void TraceJSWarning(const Script& script,
                             intptr_t token_pos,
                             const String& message);

  DISALLOW_COPY_AND_ASSIGN(Report);
};

}  // namespace dart

#endif  // VM_REPORT_H_

