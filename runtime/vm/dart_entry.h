// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DART_ENTRY_H_
#define RUNTIME_VM_DART_ENTRY_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

// Forward declarations.
class Array;
class Closure;
class Function;
class Instance;
class Integer;
class Library;
class Object;
class String;

// An arguments descriptor array consists of the type argument vector length (0
// if none); total argument count (not counting type argument vector); total
// arguments size (not counting type argument vector); the positional argument
// count; a sequence of (name, position) pairs, sorted by name, for each named
// optional argument; and a terminating null to simplify iterating in generated
// code.
class ArgumentsDescriptor : public ValueObject {
 public:
  explicit ArgumentsDescriptor(const Array& array);

  // Accessors.
  intptr_t TypeArgsLen() const;  // 0 if no type argument vector is passed.
  intptr_t FirstArgIndex() const { return TypeArgsLen() > 0 ? 1 : 0; }
  intptr_t CountWithTypeArgs() const { return FirstArgIndex() + Count(); }
  intptr_t Count() const;  // Excluding type arguments vector.
  intptr_t Size() const;   // Excluding type arguments vector.
  intptr_t SizeWithTypeArgs() const { return FirstArgIndex() + Size(); }
  intptr_t PositionalCount() const;  // Excluding type arguments vector.
  intptr_t NamedCount() const { return Count() - PositionalCount(); }
  StringPtr NameAt(intptr_t i) const;
  intptr_t PositionAt(intptr_t i) const;
  bool MatchesNameAt(intptr_t i, const String& other) const;
  // Returns array of argument names in the arguments order.
  ArrayPtr GetArgumentNames() const;
  void PrintTo(BaseTextBuffer* buffer, bool show_named_positions = false) const;
  const char* ToCString() const;

  // Generated code support.
  static intptr_t type_args_len_offset() {
    return Array::element_offset(kTypeArgsLenIndex);
  }

  static intptr_t count_offset() { return Array::element_offset(kCountIndex); }

  static intptr_t size_offset() { return Array::element_offset(kSizeIndex); }

  static intptr_t positional_count_offset() {
    return Array::element_offset(kPositionalCountIndex);
  }

  static intptr_t first_named_entry_offset() {
    return Array::element_offset(kFirstNamedEntryIndex);
  }

  static intptr_t name_offset() { return kNameOffset * kCompressedWordSize; }
  static intptr_t position_offset() {
    return kPositionOffset * kCompressedWordSize;
  }
  static intptr_t named_entry_size() {
    return kNamedEntrySize * kCompressedWordSize;
  }

  // Constructs an argument descriptor where all arguments are boxed and
  // therefore number of parameters equals parameter size.
  //
  // Right now this is for example the case for all closure functions.
  // Functions marked as entry-points may also be created by NewUnboxed because
  // we rely that TFA will mark the arguments as nullable for such cases.
  static ArrayPtr NewBoxed(intptr_t type_args_len,
                           intptr_t num_arguments,
                           const Array& optional_arguments_names,
                           Heap::Space space = Heap::kOld) {
    return New(type_args_len, num_arguments, num_arguments,
               optional_arguments_names, space);
  }

  // Allocate and return an arguments descriptor.  The first
  // (num_arguments - optional_arguments_names.Length()) arguments are
  // positional and the remaining ones are named optional arguments.
  // The presence of a type argument vector as first argument (not counted in
  // num_arguments) is indicated by a non-zero type_args_len.
  static ArrayPtr New(intptr_t type_args_len,
                      intptr_t num_arguments,
                      intptr_t size_arguments,
                      const Array& optional_arguments_names,
                      Heap::Space space = Heap::kOld);

  // Constructs an argument descriptor where all arguments are boxed and
  // therefore number of parameters equals parameter size.
  //
  // Right now this is for example the case for all closure functions.
  static ArrayPtr NewBoxed(intptr_t type_args_len,
                           intptr_t num_arguments,
                           Heap::Space space = Heap::kOld) {
    return New(type_args_len, num_arguments, num_arguments, space);
  }

  // Allocate and return an arguments descriptor that has no optional
  // arguments. All arguments are positional. The presence of a type argument
  // vector as first argument (not counted in num_arguments) is indicated
  // by a non-zero type_args_len.
  static ArrayPtr New(intptr_t type_args_len,
                      intptr_t num_arguments,
                      intptr_t size_arguments,
                      Heap::Space space = Heap::kOld);

  // Initialize the preallocated fixed length arguments descriptors cache.
  static void Init();

  // Clear the preallocated fixed length arguments descriptors cache.
  static void Cleanup();

  enum { kCachedDescriptorCount = 32 };

  // For creating ArgumentDescriptor Slots.
  static constexpr bool ContainsCompressedPointers() {
    // Use the same state as the backing store.
    return Array::ContainsCompressedPointers();
  }

 private:
  // Absolute indices into the array.
  // Keep these in sync with the constants in invocation_mirror_patch.dart.
  enum {
    kTypeArgsLenIndex,
    kCountIndex,
    kSizeIndex,
    kPositionalCountIndex,
    kFirstNamedEntryIndex,
  };

 private:
  // Relative indexes into each named argument entry.
  enum {
    kNameOffset,
    // The least significant bit of the entry in 'kPositionOffset' (second
    // least-significant after Smi-encoding) holds the strong-mode checking bit
    // for the named argument.
    kPositionOffset,
    kNamedEntrySize,
  };

  static intptr_t LengthFor(intptr_t num_named_arguments) {
    // Add 1 for the terminating null.
    return kFirstNamedEntryIndex + (kNamedEntrySize * num_named_arguments) + 1;
  }

  static ArrayPtr NewNonCached(intptr_t type_args_len,
                               intptr_t num_arguments,
                               intptr_t size_arguments,
                               bool canonicalize,
                               Heap::Space space);

  // Used by Simulator to parse argument descriptors.
  static intptr_t name_index(intptr_t index) {
    return kFirstNamedEntryIndex + (index * kNamedEntrySize) + kNameOffset;
  }

  static intptr_t position_index(intptr_t index) {
    return kFirstNamedEntryIndex + (index * kNamedEntrySize) + kPositionOffset;
  }

  const Array& array_;

  // A cache of VM heap allocated arguments descriptors.
  static ArrayPtr cached_args_descriptors_[kCachedDescriptorCount];

  friend class VMSerializationRoots;
  friend class VMDeserializationRoots;
  DISALLOW_COPY_AND_ASSIGN(ArgumentsDescriptor);
};

// DartEntry abstracts functionality needed to resolve dart functions
// and invoke them from C++.
class DartEntry : public AllStatic {
 public:
  // Invokes the specified instance function or static function.
  // The first argument of an instance function is the receiver.
  // On success, returns an InstancePtr.  On failure, an ErrorPtr.
  // This is used when there is no type argument vector and
  // no named arguments in the call.
  static ObjectPtr InvokeFunction(const Function& function,
                                  const Array& arguments);

#if defined(TESTING)
  // Invokes the specified code as if it was a Dart function.
  // On success, returns an InstancePtr.  On failure, an ErrorPtr.
  static ObjectPtr InvokeCode(const Code& code,
                              const Array& arguments_descriptor,
                              const Array& arguments,
                              Thread* thread);
#endif

  // Invokes the specified instance, static, or closure function.
  // On success, returns an InstancePtr.  On failure, an ErrorPtr.
  static ObjectPtr InvokeFunction(const Function& function,
                                  const Array& arguments,
                                  const Array& arguments_descriptor);

  // Invokes the first argument in the provided arguments array as a callable
  // object, performing any needed dynamic checks if the callable cannot receive
  // dynamic invocation.
  //
  // On success, returns an InstancePtr.  On failure, an ErrorPtr.
  //
  // Used when an ArgumentsDescriptor is not required, that is, when there
  // are no type arguments or named arguments.
  static ObjectPtr InvokeClosure(Thread* thread, const Array& arguments);

  // Invokes the first argument in the provided arguments array as a callable
  // object, performing any needed dynamic checks if the callable cannot receive
  // dynamic invocation.
  //
  // On success, returns an InstancePtr.  On failure, an ErrorPtr.
  static ObjectPtr InvokeClosure(Thread* thread,
                                 const Array& arguments,
                                 const Array& arguments_descriptor);

  // Invokes the noSuchMethod instance function on the receiver.
  // On success, returns an InstancePtr.  On failure, an ErrorPtr.
  static ObjectPtr InvokeNoSuchMethod(Thread* thread,
                                      const Instance& receiver,
                                      const String& target_name,
                                      const Array& arguments,
                                      const Array& arguments_descriptor);

 private:
  // Resolves the first argument in the provided arguments array to a callable
  // compatible with the arguments. Helper method used within InvokeClosure.
  //
  // If no errors occur, the first argument is changed to be either the resolved
  // callable or, if Function::null() is returned, an appropriate target for
  // invoking noSuchMethod.
  //
  // On success, returns a FunctionPtr. On failure, an ErrorPtr.
  static ObjectPtr ResolveCallable(Thread* thread,
                                   const Array& arguments,
                                   const Array& arguments_descriptor);

  // Invokes a function returned by ResolveCallable, performing any dynamic
  // checks needed if the function cannot receive dynamic invocation. Helper
  // method used within InvokeClosure.
  //
  // On success, returns an InstancePtr. On failure, an ErrorPtr.
  static ObjectPtr InvokeCallable(Thread* thread,
                                  const Function& callable_function,
                                  const Array& arguments,
                                  const Array& arguments_descriptor);
};

// Utility functions to call from VM into Dart bootstrap libraries.
// Each may return an exception object.
class DartLibraryCalls : public AllStatic {
 public:
  // On success, returns an InstancePtr. On failure, an ErrorPtr.
  static ObjectPtr InstanceCreate(const Library& library,
                                  const String& exception_name,
                                  const String& constructor_name,
                                  const Array& arguments);

  // On success, returns an InstancePtr. On failure, an ErrorPtr.
  static ObjectPtr ToString(const Instance& receiver);

  // On success, returns an InstancePtr. On failure, an ErrorPtr.
  static ObjectPtr HashCode(const Instance& receiver);

  // On success, returns an InstancePtr. On failure, an ErrorPtr.
  static ObjectPtr Equals(const Instance& left, const Instance& right);

  // Returns the handler if one has been registered for this port id.
  static ObjectPtr LookupHandler(Dart_Port port_id);

  // Returns handler on success, an ErrorPtr on failure, null if can't find
  // handler for this port id.
  static ObjectPtr HandleMessage(Dart_Port port_id, const Instance& message);

  // Invokes the finalizer to run its callbacks.
  static ObjectPtr HandleFinalizerMessage(const FinalizerBase& finalizer);

  // Returns a list of open ReceivePorts.
  static ObjectPtr LookupOpenPorts();

  // Returns null on success, an ErrorPtr on failure.
  static ObjectPtr DrainMicrotaskQueue();

  // Ensures that the isolate's _pendingImmediateCallback is set to
  // _startMicrotaskLoop from dart:async.
  // Returns null on success, an ErrorPtr on failure.
  static ObjectPtr EnsureScheduleImmediate();

  // Runs the `_rehashObjects()` function in `dart:collection`.
  static ObjectPtr RehashObjectsInDartCollection(
      Thread* thread,
      const Object& array_or_growable_array);

  // Runs the `_rehashObjects()` function in `dart:core`.
  static ObjectPtr RehashObjectsInDartCore(
      Thread* thread,
      const Object& array_or_growable_array);
};

}  // namespace dart

#endif  // RUNTIME_VM_DART_ENTRY_H_
