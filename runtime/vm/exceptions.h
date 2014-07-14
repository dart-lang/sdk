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
class Object;
class RawInstance;
class RawObject;
class RawScript;
class RawStacktrace;
class RawString;
class Script;
class StackFrame;
class String;

class Exceptions : AllStatic {
 public:
  static const char* kCastErrorDstName;

  static void Throw(Isolate* isolate, const Instance& exception);
  static void ReThrow(Isolate* isolate,
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
    kNoSuchMethod,
    kFormat,
    kUnsupported,
    kStackOverflow,
    kOutOfMemory,
    kInternalError,
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
  };

  static void ThrowByType(ExceptionType type, const Array& arguments);
  static void ThrowOOM();
  static void ThrowStackOverflow();
  static void ThrowArgumentError(const Instance& arg);
  static void ThrowJavascriptCompatibilityError(const char* msg);

  // Returns a RawInstance if the exception is successfully created,
  // otherwise returns a RawError.
  static RawObject* Create(ExceptionType type, const Array& arguments);

 private:
  DISALLOW_COPY_AND_ASSIGN(Exceptions);
};

}  // namespace dart

#endif  // VM_EXCEPTIONS_H_
