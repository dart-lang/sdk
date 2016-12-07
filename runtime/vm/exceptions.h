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
class RawStacktrace;
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
  static RawStacktrace* CurrentStacktrace();
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

}  // namespace dart

#endif  // RUNTIME_VM_EXCEPTIONS_H_
