// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_EXCEPTIONS_H_
#define RUNTIME_VM_EXCEPTIONS_H_

#include "vm/allocation.h"
#include "vm/token_position.h"

namespace dart {

// Forward declarations.
class AbstractType;
class Array;
class DartFrameIterator;
class Error;
class LanguageError;
class Instance;
class Integer;
class RawInstance;
class RawObject;
class RawScript;
class RawStackTrace;
class String;
class Thread;

class Exceptions : AllStatic {
 public:
  static void Throw(Thread* thread, const Instance& exception);
  static void ReThrow(Thread* thread,
                      const Instance& exception,
                      const Instance& stacktrace);
  static void PropagateError(const Error& error);

  // Helpers to create and throw errors.
  static RawStackTrace* CurrentStackTrace();
  static RawScript* GetCallerScript(DartFrameIterator* iterator);
  static RawInstance* NewInstance(const char* class_name);
  static void CreateAndThrowTypeError(TokenPosition location,
                                      const AbstractType& src_type,
                                      const AbstractType& dst_type,
                                      const String& dst_name,
                                      const String& bound_error_msg);

  enum ExceptionType {
    kNone,
    kRange,
    kRangeMsg,
    kArgument,
    kArgumentValue,
    kNoSuchMethod,
    kFormat,
    kUnsupported,
    kStackOverflow,
    kOutOfMemory,
    kNullThrown,
    kIsolateSpawn,
    kAssertion,
    kCast,
    kType,
    kFallThrough,
    kAbstractClassInstantiation,
    kCyclicInitializationError,
    kCompileTimeError,
  };

  static void ThrowByType(ExceptionType type, const Array& arguments);
  // Uses the preallocated out of memory exception to avoid calling
  // into Dart code or allocating any code.
  static void ThrowOOM();
  static void ThrowStackOverflow();
  static void ThrowArgumentError(const Instance& arg);
  static void ThrowRangeError(const char* argument_name,
                              const Integer& argument_value,
                              intptr_t expected_from,
                              intptr_t expected_to);
  static void ThrowRangeErrorMsg(const char* msg);
  static void ThrowCompileTimeError(const LanguageError& error);

  // Returns a RawInstance if the exception is successfully created,
  // otherwise returns a RawError.
  static RawObject* Create(ExceptionType type, const Array& arguments);

  static void JumpToFrame(Thread* thread,
                          uword program_counter,
                          uword stack_pointer,
                          uword frame_pointer,
                          bool clear_deopt_at_target);

 private:
  DISALLOW_COPY_AND_ASSIGN(Exceptions);
};

// The index into the ExceptionHandlers table corresponds to
// the try_index of the handler.
struct ExceptionHandlerInfo {
  uint32_t handler_pc_offset;  // PC offset value of handler.
  int16_t outer_try_index;     // Try block index of enclosing try block.
  int8_t needs_stacktrace;     // True if a stacktrace is needed.
  int8_t has_catch_all;        // Catches all exceptions.
  int8_t is_generated;         // True if this is a generated handler.
};


class CatchEntryState {
 public:
  enum { kCatchEntryStateIsMove = 1, kCatchEntryStateDestShift = 1 };

  CatchEntryState() : data(NULL) {}
  explicit CatchEntryState(intptr_t* data_) : data(data_) {}
  // Data has the following format:
  // 0 - number of pairs in this state
  // 1-2 - 1st encoded src,dest pair
  // 3-4 - 2nd pair
  // ....
  intptr_t* data;

  intptr_t Pairs() { return data[0]; }

  intptr_t Src(intptr_t i) { return data[1 + 2 * i]; }

  intptr_t Dest(intptr_t i) {
    return data[2 + 2 * i] >> kCatchEntryStateDestShift;
  }

  bool isMove(intptr_t i) { return data[2 + 2 * i] & kCatchEntryStateIsMove; }
};

}  // namespace dart

#endif  // RUNTIME_VM_EXCEPTIONS_H_
