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
class Library;
class Object;
class RawInstance;
class RawObject;
class String;

// DartEntry abstracts functionality needed to resolve dart functions
// and invoke them from C++.
class DartEntry : public AllStatic {
 public:
  // On success, returns a RawInstance.  On failure, a RawError.
  typedef RawObject* (*invokestub)(uword entry_point,
                                   const Array& arguments_descriptor,
                                   const Object** arguments,
                                   const Context& context);

  // Invokes the specified instance function on the receiver.
  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* InvokeDynamic(
      const Instance& receiver,
      const Function& function,
      const GrowableArray<const Object*>& arguments,
      const Array& optional_arguments_names);

  // Invoke the specified static function.
  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* InvokeStatic(
      const Function& function,
      const GrowableArray<const Object*>& arguments,
      const Array& optional_arguments_names);

  // Invoke the specified closure object.
  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* InvokeClosure(
      const Closure& closure,
      const GrowableArray<const Object*>& arguments,
      const Array& optional_arguments_names);
};


// Utility functions to call from VM into Dart bootstrap libraries.
// Each may return an exception object.
class DartLibraryCalls : public AllStatic {
 public:
  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* ExceptionCreate(
      const Library& library,
      const String& exception_name,
      const GrowableArray<const Object*>& arguments);

  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* ToString(const Instance& receiver);

  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* Equals(const Instance& left, const Instance& right);

  // Returns null on success, a RawError on failure.
  static RawObject* HandleMessage(Dart_Port dest_port_id,
                                  Dart_Port reply_port_id,
                                  const Instance& dart_message);

  // On success returns new SendPort, on failure returns a RawError.
  static RawObject* NewSendPort(intptr_t port_id);

  // map[key] = value;
  //
  // Returns null on success, a RawError on failure.
  static RawObject* MapSetAt(const Instance& map,
                             const Instance& key,
                             const Instance& value);

  // Gets the _id field of a SendPort/ReceivePort.
  //
  // Returns the value of _id on success, a RawError on failure.
  static RawObject* PortGetId(const Instance& port);
};

}  // namespace dart

#endif  // VM_DART_ENTRY_H_
