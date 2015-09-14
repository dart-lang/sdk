// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_EXCEPTIONS_H_
#define VM_EXCEPTIONS_H_

#include "vm/allocation.h"

namespace dart {

// Forward declarations.
class Array;
class Class;
class DartFrameIterator;
class Error;
class Instance;
class Integer;
class Object;
class RawInstance;
class RawObject;
class RawScript;
class RawStacktrace;
class RawString;
class Script;
class StackFrame;
class Stacktrace;
class String;
class Thread;

class Exceptions : AllStatic {
 public:
  static const char* kCastErrorDstName;

  static void Throw(Thread* thread, const Instance& exception);
  static void ReThrow(Thread* thread,
                      const Instance& exception,
                      const Instance& stacktrace);
  static void PropagateError(const Error& error);

  // Helpers to create and throw errors.
  static RawStacktrace* CurrentStacktrace();
  static RawScript* GetCallerScript(DartFrameIterator* iterator);
  static RawInstance* NewInstance(const char* class_name);
  static void CreateAndThrowTypeError(intptr_t location,
                                      const String& src_type_name,
                                      const String& dst_type_name,
                                      const String& dst_name,
                                      const String& error_msg);

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
    kIsolateUnhandledException,
    kJavascriptIntegerOverflowError,
    kJavascriptCompatibilityError,
    kAssertion,
    kCast,
    kType,
    kFallThrough,
    kAbstractClassInstantiation,
    kCyclicInitializationError,
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
  static void ThrowJavascriptCompatibilityError(const char* msg);

  // Returns a RawInstance if the exception is successfully created,
  // otherwise returns a RawError.
  static RawObject* Create(ExceptionType type, const Array& arguments);

 private:
  DISALLOW_COPY_AND_ASSIGN(Exceptions);
};

}  // namespace dart

#endif  // VM_EXCEPTIONS_H_
