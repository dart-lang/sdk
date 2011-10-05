// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_EXCEPTIONS_H_
#define VM_EXCEPTIONS_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"

namespace dart {

// Forward declarations.
class Instance;
class Object;
class RawInstance;

class Exceptions : AllStatic {
 public:
  static void Throw(const Instance& exception);
  static void ReThrow(const Instance& exception, const Instance& stacktrace);

  enum ExceptionType {
    kIndexOutOfRange,
    kIllegalArgument,
    kNoSuchMethod,
    kClosureArgumentMismatch,
    kObjectNotClosure,
    kBadNumberFormat,
    kStackOverflow,
    kWrongArgumentCount,
    kInternalError,
    kNullPointer,
    kIllegalJSRegExp,
  };

  static void ThrowByType(ExceptionType type,
                          const GrowableArray<const Object*>& arguments);
  static RawInstance* Create(ExceptionType type,
                             const GrowableArray<const Object*>& arguments);

 private:
  DISALLOW_COPY_AND_ASSIGN(Exceptions);
};

}  // namespace dart

#endif  // VM_EXCEPTIONS_H_
