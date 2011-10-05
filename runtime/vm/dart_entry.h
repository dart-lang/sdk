// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DART_ENTRY_H_
#define VM_DART_ENTRY_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"

namespace dart {

// Forward declarations.
class Array;
class Closure;
class Context;
class Function;
class Instance;
class Integer;
class Object;
class RawInstance;
class String;

// DartEntry abstracts functionality needed to resolve dart functions
// and invoke them from C++.
class DartEntry : public AllStatic {
 public:
  typedef RawInstance* (*invokestub)(uword entry_point,
                                     const Array& arguments_descriptor,
                                     const Object** arguments,
                                     const Context& context);

  // Invoke the specified instance function on the receiver.
  // Returns object returned by the dart instance function.
  static RawInstance* InvokeDynamic(
      const Instance& receiver,
      const Function& function,
      const GrowableArray<const Object*>& arguments);

  // Invoke the specified static function.
  // Returns object returned by the dart static function.
  static RawInstance* InvokeStatic(
      const Function& function, const GrowableArray<const Object*>& arguments);

  // Invoke the specified closure object.
  // Returns object returned by the closure.
  static RawInstance* InvokeClosure(
      const Closure& closure, const GrowableArray<const Object*>& arguments);
};


// Utility functions to call from VM into Dart bootstrap libraries.
// Each may return an exception object.
class DartLibraryCalls : public AllStatic {
 public:
  static RawInstance* ExceptionCreate(
      const String& exception_name,
      const GrowableArray<const Object*>& arguments);
  static RawInstance* ToString(const Instance& receiver);
  static RawInstance* Equals(const Instance& left, const Instance& right);
};

}  // namespace dart

#endif  // VM_DART_ENTRY_H_
