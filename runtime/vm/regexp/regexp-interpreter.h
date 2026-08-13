// Copyright 2011 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef V8_REGEXP_REGEXP_INTERPRETER_H_
#define V8_REGEXP_REGEXP_INTERPRETER_H_

// A simple interpreter for the Irregexp byte code.

#include "vm/regexp/regexp.h"

namespace dart {

class TrustedByteArray;

class IrregexpInterpreter : public AllStatic {
 public:
  enum Result {
    FAILURE = RegExpStatics::kInternalRegExpFailure,
    SUCCESS = RegExpStatics::kInternalRegExpSuccess,
    EXCEPTION = RegExpStatics::kInternalRegExpException,
    RETRY = RegExpStatics::kInternalRegExpRetry,
    FALLBACK_TO_EXPERIMENTAL =
        RegExpStatics::kInternalRegExpFallbackToExperimental,
  };

  // In case a StackOverflow occurs, a StackOverflowException is created and
  // EXCEPTION is returned.
  static int MatchForCallFromRuntime(Thread* thread,
                                     const RegExp& regexp_data,
                                     const String& subject_string,
                                     int* output_registers,
                                     int output_register_count,
                                     int start_position,
                                     bool is_sticky);

  // In case a StackOverflow occurs, EXCEPTION is returned. The caller is
  // responsible for creating the exception.
  //
  // RETRY is returned if a retry through the runtime is needed (e.g. when
  // interrupts have been scheduled or the regexp is marked for tier-up).
  //
  // Arguments input_start and input_end are unused. They are only passed to
  // match the signature of the native irregex code.
  //
  // Arguments output_registers and output_register_count describe the results
  // array, which will contain register values of all captures if one or more
  // matches were found. In this case, the return value is the number of
  // matches. For all other return codes, the results array remains unmodified.
  static int MatchForCallFromJs(void* subject,
                                int32_t start_position,
                                void* input_start,
                                void* input_end,
                                int* output_registers,
                                int32_t output_register_count,
                                RegExpStatics::CallOrigin call_origin,
                                Thread* thread,
                                void* regexp_data);

  static Result MatchInternal(Thread* thread,
                              const TypedData& code_array,
                              const String& subject_string,
                              int* output_registers,
                              int output_register_count,
                              int total_register_count,
                              int start_position,
                              RegExpStatics::CallOrigin call_origin,
                              uint32_t backtrack_limit);

 private:
  static int Match(Thread* thread,
                   const RegExp& regexp_data,
                   const String& subject_string,
                   int* output_registers,
                   int output_register_count,
                   int start_position,
                   RegExpStatics::CallOrigin call_origin,
                   bool is_sticky);
};

}  // namespace dart

#endif  // V8_REGEXP_REGEXP_INTERPRETER_H_
