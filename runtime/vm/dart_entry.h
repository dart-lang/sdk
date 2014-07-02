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
class RawArray;
class RawInstance;
class RawObject;
class RawString;
class String;

// An arguments descriptor array consists of the total argument count; the
// positional argument count; a sequence of (name, position) pairs, sorted
// by name, for each named optional argument; and a terminating null to
// simplify iterating in generated code.
class ArgumentsDescriptor : public ValueObject {
 public:
  explicit ArgumentsDescriptor(const Array& array);

  // Accessors.
  intptr_t Count() const;
  intptr_t PositionalCount() const;
  intptr_t NamedCount() const { return Count() - PositionalCount(); }
  RawString* NameAt(intptr_t i) const;
  bool MatchesNameAt(intptr_t i, const String& other) const;

  // Generated code support.
  static intptr_t count_offset();
  static intptr_t positional_count_offset();
  static intptr_t first_named_entry_offset();
  static intptr_t name_offset() { return kNameOffset * kWordSize; }
  static intptr_t position_offset() { return kPositionOffset * kWordSize; }
  static intptr_t named_entry_size() { return kNamedEntrySize * kWordSize; }

  // Allocate and return an arguments descriptor.  The first
  // (count - optional_arguments_names.Length()) arguments are
  // positional and the remaining ones are named optional arguments.
  static RawArray* New(intptr_t count,
                       const Array& optional_arguments_names);

  // Allocate and return an arguments descriptor that has no optional
  // arguments. All arguments are positional.
  static RawArray* New(intptr_t count);

  // Initialize the preallocated fixed length arguments descriptors cache.
  static void InitOnce();

 private:
  // Absolute indexes into the array.
  enum {
    kCountIndex,
    kPositionalCountIndex,
    kFirstNamedEntryIndex,
  };

  // Relative indexes into each named argument entry.
  enum {
    kNameOffset,
    kPositionOffset,
    kNamedEntrySize,
  };

  enum {
    kCachedDescriptorCount = 32
  };

  static intptr_t LengthFor(intptr_t count) {
    // Add 1 for the terminating null.
    return kFirstNamedEntryIndex + (kNamedEntrySize * count) + 1;
  }

  static RawArray* NewNonCached(intptr_t count, bool canonicalize = true);

  const Array& array_;

  // A cache of VM heap allocated arguments descriptors.
  static RawArray* cached_args_descriptors_[kCachedDescriptorCount];

  DISALLOW_COPY_AND_ASSIGN(ArgumentsDescriptor);
};


// DartEntry abstracts functionality needed to resolve dart functions
// and invoke them from C++.
class DartEntry : public AllStatic {
 public:
  // On success, returns a RawInstance.  On failure, a RawError.
  typedef RawObject* (*invokestub)(uword entry_point,
                                   const Array& arguments_descriptor,
                                   const Array& arguments,
                                   const Context& context);

  // Invokes the specified instance function or static function.
  // The first argument of an instance function is the receiver.
  // On success, returns a RawInstance.  On failure, a RawError.
  // This is used when there are no named arguments in the call.
  static RawObject* InvokeFunction(const Function& function,
                                   const Array& arguments);

  // Invokes the specified instance or static function.
  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* InvokeFunction(const Function& function,
                                   const Array& arguments,
                                   const Array& arguments_descriptor);

  // Invokes the specified instance, static, or closure function.
  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* InvokeFunction(const Function& function,
                                   const Array& arguments,
                                   const Array& arguments_descriptor,
                                   const Context& context);

  // Invokes the closure object given as the first argument.
  // On success, returns a RawInstance.  On failure, a RawError.
  // This is used when there are no named arguments in the call.
  static RawObject* InvokeClosure(const Array& arguments);

  // Invokes the closure object given as the first argument.
  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* InvokeClosure(const Array& arguments,
                                  const Array& arguments_descriptor);

  // Invokes the noSuchMethod instance function on the receiver.
  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* InvokeNoSuchMethod(const Instance& receiver,
                                       const String& target_name,
                                       const Array& arguments,
                                       const Array& arguments_descriptor);
};


// Utility functions to call from VM into Dart bootstrap libraries.
// Each may return an exception object.
class DartLibraryCalls : public AllStatic {
 public:
  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* InstanceCreate(const Library& library,
                                   const String& exception_name,
                                   const String& constructor_name,
                                   const Array& arguments);

  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* ToString(const Instance& receiver);

  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* HashCode(const Instance& receiver);

  // On success, returns a RawInstance.  On failure, a RawError.
  static RawObject* Equals(const Instance& left, const Instance& right);

  // Returns the handler if one has been registered for this port id.
  static RawObject* LookupHandler(Dart_Port port_id);

  // Returns null on success, a RawError on failure.
  static RawObject* HandleMessage(const Object& handler,
                                  const Instance& dart_message);

  // map[key] = value;
  //
  // Returns null on success, a RawError on failure.
  static RawObject* MapSetAt(const Instance& map,
                             const Instance& key,
                             const Instance& value);
};

}  // namespace dart

#endif  // VM_DART_ENTRY_H_
