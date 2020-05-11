// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REPORT_H_
#define RUNTIME_VM_REPORT_H_

#include "vm/allocation.h"
#include "vm/tagged_pointer.h"
#include "vm/token_position.h"

namespace dart {

// Forward declarations.
class Error;
class ICData;
class Script;
class StackFrame;
class String;

class Report : AllStatic {
 public:
  enum Kind {
    kWarning,
    kError,
    kBailout,
  };

  static const bool AtLocation = false;
  static const bool AfterLocation = true;

  // Report an already formatted error via a long jump.
  DART_NORETURN static void LongJump(const Error& error);

  // Concatenate and report an already formatted error and a new error message.
  DART_NORETURN static void LongJumpF(const Error& prev_error,
                                      const Script& script,
                                      TokenPosition token_pos,
                                      const char* format,
                                      ...) PRINTF_ATTRIBUTE(4, 5);
  DART_NORETURN static void LongJumpV(const Error& prev_error,
                                      const Script& script,
                                      TokenPosition token_pos,
                                      const char* format,
                                      va_list args);

  // Report a warning/jswarning/error/bailout message.
  static void MessageF(Kind kind,
                       const Script& script,
                       TokenPosition token_pos,
                       bool report_after_token,
                       const char* format,
                       ...) PRINTF_ATTRIBUTE(5, 6);
  static void MessageV(Kind kind,
                       const Script& script,
                       TokenPosition token_pos,
                       bool report_after_token,
                       const char* format,
                       va_list args);

  // Prepend a source snippet to the message.
  // A null script means no source and a negative token_pos means no position.
  static StringPtr PrependSnippet(Kind kind,
                                  const Script& script,
                                  TokenPosition token_pos,
                                  bool report_after_token,
                                  const String& message);

 private:
  DISALLOW_COPY_AND_ASSIGN(Report);
};

}  // namespace dart

#endif  // RUNTIME_VM_REPORT_H_
