// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_RESOLVER_H_
#define RUNTIME_VM_RESOLVER_H_

#include "vm/allocation.h"
#include "vm/tagged_pointer.h"

namespace dart {

// Forward declarations.
class Array;
class Class;
class Instance;
class Library;
class String;
class ArgumentsDescriptor;

// Resolver abstracts functionality needed to resolve dart functions at
// invocations.
class Resolver : public AllStatic {
 public:
  // Resolve specified dart instance function.
  static FunctionPtr ResolveDynamic(const Instance& receiver,
                                    const String& function_name,
                                    const ArgumentsDescriptor& args_desc);

  // If 'allow_add' is true we may add a function to the class during lookup.
  static FunctionPtr ResolveDynamicForReceiverClass(
      const Class& receiver_class,
      const String& function_name,
      const ArgumentsDescriptor& args_desc,
      bool allow_add = true);
  static FunctionPtr ResolveDynamicForReceiverClassAllowPrivate(
      const Class& receiver_class,
      const String& function_name,
      const ArgumentsDescriptor& args_desc,
      bool allow_add);

  // If 'allow_add' is true we may add a function to the class during lookup.
  static FunctionPtr ResolveDynamicAnyArgs(Zone* zone,
                                           const Class& receiver_class,
                                           const String& function_name,
                                           bool allow_add = true);
  static FunctionPtr ResolveDynamicAnyArgsAllowPrivate(
      Zone* zone,
      const Class& receiver_class,
      const String& function_name,
      bool allow_add);

  // Resolve instance function [function_name] with any args, it doesn't
  // allow adding methods during resolution: [allow_add] is [false].
  static FunctionPtr ResolveDynamicFunction(Zone* zone,
                                            const Class& receiver_class,
                                            const String& function_name);
  // Resolve static or instance function [function_name] with any args, it
  // doesn't allow adding methods during resolution: [allow_add] is [false].
  static FunctionPtr ResolveFunction(Zone* zone,
                                     const Class& receiver_class,
                                     const String& function_name);
};

}  // namespace dart

#endif  // RUNTIME_VM_RESOLVER_H_
