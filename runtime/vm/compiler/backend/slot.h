// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Slot is an abstraction that describes an readable (and possibly writeable)
// location within an object.
//
// In general slots follow the memory model for normal Dart fields - but can
// also be used to describe locations that don't have corresponding Field
// object, i.e. fields within native objects like arrays or contexts.
//
// Slot objects created by the compiler have an identity. If two slots F and G
// are different then compiler assumes that store into F can't alias a load
// from G and vice versa.
//
// All slots can be split into 4 categories:
//
//   - slots for fields of native classes (Array, Closure, etc);
//   - slots for type arguments;
//   - slots for captured variable;
//   - slots for normal Dart fields (e.g. those that Field object).
//

#ifndef RUNTIME_VM_COMPILER_BACKEND_SLOT_H_
#define RUNTIME_VM_COMPILER_BACKEND_SLOT_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/compile_type.h"
#include "vm/compiler/backend/locations.h"
#include "vm/thread.h"

namespace dart {

class LocalScope;
class LocalVariable;
class ParsedFunction;

// The list of slots that correspond to nullable boxed fields of native
// Dart objects in the following format:
//
//     V(class_name, underlying_type, field_name, exact_type, FINAL|VAR|WEAK)
//
// - class_name and field_name specify the name of the host class and the name
//   of the field respectively;
// - underlying_type: the Raw class which holds the field;
// - exact_type specifies exact type of the field (any load from this field
//   would only yield instances of this type);
// - the last component specifies whether field behaves like a final field
//   (i.e. initialized once at construction time and does not change after
//   that), ordinary mutable field or a weak field (can be modified by GC).
#define NULLABLE_TAGGED_NATIVE_DART_SLOTS_LIST(V)                              \
  V(Array, UntaggedArray, type_arguments, TypeArguments, FINAL)                \
  V(Finalizer, UntaggedFinalizer, type_arguments, TypeArguments, FINAL)        \
  V(FinalizerBase, UntaggedFinalizerBase, all_entries, Set, VAR)               \
  V(FinalizerBase, UntaggedFinalizerBase, detachments, Dynamic, VAR)           \
  V(FinalizerBase, UntaggedFinalizer, entries_collected, FinalizerEntry, VAR)  \
  V(FinalizerEntry, UntaggedFinalizerEntry, value, Dynamic, WEAK)              \
  V(FinalizerEntry, UntaggedFinalizerEntry, detach, Dynamic, WEAK)             \
  V(FinalizerEntry, UntaggedFinalizerEntry, token, Dynamic, VAR)               \
  V(FinalizerEntry, UntaggedFinalizerEntry, finalizer, FinalizerBase, WEAK)    \
  V(FinalizerEntry, UntaggedFinalizerEntry, next, FinalizerEntry, VAR)         \
  V(Function, UntaggedFunction, signature, FunctionType, FINAL)                \
  V(Context, UntaggedContext, parent, Context, FINAL)                          \
  V(Closure, UntaggedClosure, instantiator_type_arguments, TypeArguments,      \
    FINAL)                                                                     \
  V(Closure, UntaggedClosure, delayed_type_arguments, TypeArguments, FINAL)    \
  V(Closure, UntaggedClosure, function_type_arguments, TypeArguments, FINAL)   \
  V(FunctionType, UntaggedFunctionType, type_parameters, TypeParameters,       \
    FINAL)                                                                     \
  V(ReceivePort, UntaggedReceivePort, send_port, SendPort, FINAL)              \
  V(ReceivePort, UntaggedReceivePort, handler, Closure, VAR)                   \
  V(ImmutableLinkedHashBase, UntaggedLinkedHashBase, index,                    \
    TypedDataUint32Array, VAR)                                                 \
  V(Instance, UntaggedInstance, native_fields_array, Dynamic, VAR)             \
  V(SuspendState, UntaggedSuspendState, function_data, Dynamic, VAR)           \
  V(SuspendState, UntaggedSuspendState, then_callback, Closure, VAR)           \
  V(SuspendState, UntaggedSuspendState, error_callback, Closure, VAR)          \
  V(TypeParameters, UntaggedTypeParameters, flags, Array, FINAL)               \
  V(TypeParameters, UntaggedTypeParameters, bounds, TypeArguments, FINAL)      \
  V(TypeParameters, UntaggedTypeParameters, defaults, TypeArguments, FINAL)    \
  V(WeakProperty, UntaggedWeakProperty, key, Dynamic, WEAK)                    \
  V(WeakProperty, UntaggedWeakProperty, value, Dynamic, WEAK)                  \
  V(WeakReference, UntaggedWeakReference, target, Dynamic, WEAK)               \
  V(WeakReference, UntaggedWeakReference, type_arguments, TypeArguments, FINAL)

// The list of slots that correspond to non-nullable boxed fields of native
// Dart objects that contain integers in the following format:
//
//     V(class_name, underlying_type, field_name, exact_type, FINAL|VAR)
//
// - class_name and field_name specify the name of the host class and the name
//   of the field respectively;
// - underlying_type: the Raw class which holds the field;
// - exact_type specifies exact type of the field (any load from this field
//   would only yield instances of this type);
// - the last component specifies whether field behaves like a final field
//   (i.e. initialized once at construction time and does not change after
//   that) or like a non-final field.
#define NONNULLABLE_INT_TAGGED_NATIVE_DART_SLOTS_LIST(V)                       \
  V(Array, UntaggedArray, length, Smi, FINAL)                                  \
  V(Closure, UntaggedClosure, hash, Smi, VAR)                                  \
  V(GrowableObjectArray, UntaggedGrowableObjectArray, length, Smi, VAR)        \
  V(TypedDataBase, UntaggedTypedDataBase, length, Smi, FINAL)                  \
  V(TypedDataView, UntaggedTypedDataView, offset_in_bytes, Smi, FINAL)         \
  V(String, UntaggedString, length, Smi, FINAL)                                \
  V(LinkedHashBase, UntaggedLinkedHashBase, hash_mask, Smi, VAR)               \
  V(LinkedHashBase, UntaggedLinkedHashBase, used_data, Smi, VAR)               \
  V(LinkedHashBase, UntaggedLinkedHashBase, deleted_keys, Smi, VAR)            \
  V(ArgumentsDescriptor, UntaggedArray, type_args_len, Smi, FINAL)             \
  V(ArgumentsDescriptor, UntaggedArray, positional_count, Smi, FINAL)          \
  V(ArgumentsDescriptor, UntaggedArray, count, Smi, FINAL)                     \
  V(ArgumentsDescriptor, UntaggedArray, size, Smi, FINAL)                      \
  V(Record, UntaggedRecord, shape, Smi, FINAL)                                 \
  V(TypeArguments, UntaggedTypeArguments, hash, Smi, VAR)                      \
  V(TypeArguments, UntaggedTypeArguments, length, Smi, FINAL)                  \
  V(AbstractType, UntaggedTypeArguments, hash, Smi, VAR)

// The list of slots that correspond to non-nullable boxed fields of native
// Dart objects that do not contain integers in the following format:
//
//     V(class_name, underlying_type, field_name, exact_type, FINAL|VAR)
//
// - class_name and field_name specify the name of the host class and the name
//   of the field respectively;
// - underlying_type: the Raw class which holds the field;
// - exact_type specifies exact type of the field (any load from this field
//   would only yield instances of this type);
// - the last component specifies whether field behaves like a final field
//   (i.e. initialized once at construction time and does not change after
//   that) or like a non-final field.
#define NONNULLABLE_NONINT_TAGGED_NATIVE_DART_SLOTS_LIST(V)                    \
  V(Closure, UntaggedClosure, function, Function, FINAL)                       \
  V(Closure, UntaggedClosure, context, Dynamic, FINAL)                         \
  V(Finalizer, UntaggedFinalizer, callback, Closure, FINAL)                    \
  V(NativeFinalizer, UntaggedFinalizer, callback, Pointer, FINAL)              \
  V(Function, UntaggedFunction, data, Dynamic, FINAL)                          \
  V(FunctionType, UntaggedFunctionType, named_parameter_names, Array, FINAL)   \
  V(FunctionType, UntaggedFunctionType, parameter_types, Array, FINAL)         \
  V(GrowableObjectArray, UntaggedGrowableObjectArray, data, Array, VAR)        \
  V(TypedDataView, UntaggedTypedDataView, typed_data, Dynamic, FINAL)          \
  V(LinkedHashBase, UntaggedLinkedHashBase, index, TypedDataUint32Array, VAR)  \
  V(LinkedHashBase, UntaggedLinkedHashBase, data, Array, VAR)                  \
  V(ImmutableLinkedHashBase, UntaggedLinkedHashBase, data, ImmutableArray,     \
    FINAL)                                                                     \
  V(TypeParameters, UntaggedTypeParameters, names, Array, FINAL)               \
  V(UnhandledException, UntaggedUnhandledException, exception, Dynamic, FINAL) \
  V(UnhandledException, UntaggedUnhandledException, stacktrace, Dynamic, FINAL)

// List of slots that correspond to fields of native objects that contain
// unboxed values in the following format:
//
//     V(class_name, underlying_type, field_name, representation, FINAL|VAR)
//
// - class_name and field_name specify the name of the host class and the name
//   of the field respectively;
// - underlying_type: the Raw class which holds the field;
// - representation specifies the representation of the bits stored within
//   the unboxed field (minus the kUnboxed prefix);
// - the last component specifies whether field behaves like a final field
//   (i.e. initialized once at construction time and does not change after
//   that) or like a non-final field.
//
// Note: As the underlying field is unboxed, these slots cannot be nullable.
//
// Note: Currently LoadFieldInstr::IsImmutableLengthLoad() assumes that no
// unboxed slots represent length loads.
#define UNBOXED_NATIVE_DART_SLOTS_LIST(V)                                      \
  V(AbstractType, UntaggedAbstractType, flags, Uint32, FINAL)                  \
  V(ClosureData, UntaggedClosureData, packed_fields, Uint32, FINAL)            \
  V(FinalizerEntry, UntaggedFinalizerEntry, external_size, IntPtr, VAR)        \
  V(Function, UntaggedFunction, kind_tag, Uint32, FINAL)                       \
  V(FunctionType, UntaggedFunctionType, packed_parameter_counts, Uint32,       \
    FINAL)                                                                     \
  V(FunctionType, UntaggedFunctionType, packed_type_parameter_counts, Uint16,  \
    FINAL)                                                                     \
  V(SubtypeTestCache, UntaggedSubtypeTestCache, num_inputs, Uint32, FINAL)

// Native slots containing untagged addresses that do not exist in JIT mode.
// See UNTAGGED_NATIVE_DART_SLOTS_LIST for the format.
#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
#define AOT_ONLY_UNTAGGED_NATIVE_DART_SLOTS_LIST(V)                            \
  V(Closure, UntaggedClosure, entry_point, false, FINAL)
#else
#define AOT_ONLY_UNTAGGED_NATIVE_DART_SLOTS_LIST(V)
#endif

// List of slots that correspond to fields of native Dart objects containing
// untagged addresses in the following format:
//
//     V(class_name, underlying_type, field_name, gc_may_move, FINAL|VAR)
//
// - class_name and field_name specify the name of the host class and the name
//   of the field respectively;
// - underlying_type: the Raw class which holds the field;
// - gc_may_move: whether the untagged address contained in this field is a
//   pointer to memory that may be moved by the GC, which means a value loaded
//   from this field is invalidated by any instruction that can cause GC;
// - the last component specifies whether field behaves like a final field
//   (i.e. initialized once at construction time and does not change after
//   that) or like a non-final field.
//
// Note: As the underlying field is untagged, these slots cannot be nullable.
//
// Note: All slots for fields that contain untagged addresses are given
// the kUntagged representation.
#define UNTAGGED_NATIVE_DART_SLOTS_LIST(V)                                     \
  AOT_ONLY_UNTAGGED_NATIVE_DART_SLOTS_LIST(V)                                  \
  V(Function, UntaggedFunction, entry_point, false, FINAL)                     \
  V(FinalizerBase, UntaggedFinalizerBase, isolate, false, VAR)                 \
  V(PointerBase, UntaggedPointerBase, data, true, VAR)

// List of slots that correspond to fields of non-Dart objects containing
// tagged addresses of Dart objects in the following format:
//
//     V(class_name, _, field_name, exact_type, FINAL|VAR)
//
// - class_name and field_name specify the name of the host class and the name
//   of the field respectively;
// - exact_type specifies exact type of the field (any load from this field
//   would only yield instances of this type);
// - the last component specifies whether field behaves like a final field
//   (i.e. initialized once at construction time and does not change after
//   that) or like a non-final field.
//
// Note: Currently LoadFieldInstr::IsImmutableLengthLoad() assumes that no
// slots of non-Dart values represent length loads.
#define NULLABLE_TAGGED_NATIVE_NONDART_SLOTS_LIST(V)                           \
  V(Isolate, _, finalizers, GrowableObjectArray, VAR)                          \
  V(LocalHandle, _, ptr, Dynamic, VAR)                                         \
  V(ObjectStore, _, record_field_names, Array, VAR)                            \
  V(PersistentHandle, _, ptr, Dynamic, VAR)

// List of slots that correspond to fields of non-Dart objects containing
// unboxed values in the following format:
//
//     V(class_name, _, field_name, representation, FINAL|VAR)
//
// - class_name and field_name specify the name of the host class and the name
//   of the field respectively;
// - representation specifies the representation of the bits stored within
//   the unboxed field (minus the kUnboxed prefix);
// - the last component specifies whether field behaves like a final field
//   (i.e. initialized once at construction time and does not change after
//   that) or like a non-final field.
//
// Note: As the underlying field is unboxed, these slots cannot be nullable.
//
// Note: Currently LoadFieldInstr::IsImmutableLengthLoad() assumes that no
// slots of non-Dart values represent length loads.
#define UNBOXED_NATIVE_NONDART_SLOTS_LIST(V)                                   \
  V(StreamInfo, _, enabled, IntPtr, VAR)

// List of slots that correspond to fields of non-Dart objects containing
// untagged addresses in the following format:
//
//     V(class_name, _, field_name, gc_may_move, FINAL|VAR)
//
// - class_name and field_name specify the name of the host class and the name
//   of the field respectively;
// - gc_may_move: whether the untagged address contained in this field is a
//   pointer to memory that may be moved by the GC, which means a value loaded
//   from this field is invalidated by any instruction that can cause GC;
// - the last component specifies whether field behaves like a final field
//   (i.e. initialized once at construction time and does not change after
//   that) or like a non-final field.
//
// Note: As the underlying field is untagged, these slots cannot be nullable.
//
// Note: All slots for fields that contain untagged addresses are given
// the kUntagged representation.
//
// Note: while Thread::isolate_ and IsolateGroup::object_store_ aren't const
// fields, they should never change during a given execution of the code
// generated for a function and the compiler only does intra-procedural
// load optimizations.
#define UNTAGGED_NATIVE_NONDART_SLOTS_LIST(V)                                  \
  V(IsolateGroup, _, object_store, false, FINAL)                               \
  V(Thread, _, api_top_scope, false, VAR)                                      \
  V(Thread, _, isolate, false, FINAL)                                          \
  V(Thread, _, isolate_group, false, FINAL)                                    \
  V(Thread, _, service_extension_stream, false, FINAL)

// No untagged slot on a non-Dart object should contain a GC-movable address.
// The gc_may_move field is only there so that any code that operates on
// UNTAGGED_NATIVE_SLOTS_LIST can use that field as desired.
#define CHECK_NATIVE_NONDART_SLOT(__, ___, ____, gc_may_move, _____)           \
  static_assert(!gc_may_move);
UNTAGGED_NATIVE_NONDART_SLOTS_LIST(CHECK_NATIVE_NONDART_SLOT)
#undef CHECK_NATIVE_NONDART_SLOT

// For uses that need any native slot that contain an unboxed integer. Such uses
// can only use the following arguments for each entry:
//     V(class_name, _, field_name, rep, FINAL|VAR)
#define UNBOXED_NATIVE_SLOTS_LIST(V)                                           \
  UNBOXED_NATIVE_DART_SLOTS_LIST(V)                                            \
  UNBOXED_NATIVE_NONDART_SLOTS_LIST(V)

// For uses that need any native slot that contain an untagged address. Such
// uses can only use the following arguments for each entry:
//     V(class_name, _, field_name, gc_may_move, FINAL|VAR)
#define UNTAGGED_NATIVE_SLOTS_LIST(V)                                          \
  UNTAGGED_NATIVE_DART_SLOTS_LIST(V)                                           \
  UNTAGGED_NATIVE_NONDART_SLOTS_LIST(V)

// For uses that need any native slot that does not contain a Dart object. Such
// uses can only use the following arguments for each entry:
//     V(class_name, _, field_name, _, FINAL|VAR)
#define NOT_TAGGED_NATIVE_SLOTS_LIST(V)                                        \
  UNBOXED_NATIVE_SLOTS_LIST(V)                                                 \
  UNTAGGED_NATIVE_SLOTS_LIST(V)

// For uses that need any native slot that is guaranteed to contain a tagged
// integer. Such uses can only use the following arguments for each entry:
//     V(class_name, _, field_name, exact_type, FINAL|VAR)
#define TAGGED_INT_NATIVE_SLOTS_LIST(V)                                        \
  NONNULLABLE_INT_TAGGED_NATIVE_DART_SLOTS_LIST(V)

// For uses that need any native slot that contains a tagged object which is not
// guaranteed to be a integer. This includes nullable integer slots, since
// those slots may return a non-integer value (null). Such uses can
// only use the following arguments for each entry:
//     V(class_name, _, field_name, exact_type, FINAL|VAR|WEAK)
#define TAGGED_NONINT_NATIVE_SLOTS_LIST(V)                                     \
  NULLABLE_TAGGED_NATIVE_DART_SLOTS_LIST(V)                                    \
  NONNULLABLE_NONINT_TAGGED_NATIVE_DART_SLOTS_LIST(V)                          \
  NULLABLE_TAGGED_NATIVE_NONDART_SLOTS_LIST(V)

// For uses that need any native slot that is not guaranteed to contain an
// integer, whether a Dart object or unboxed. Such uses can only use the
// following arguments for each entry:
//     V(class_name, _, field_name, _, FINAL|VAR|WEAK)
#define NOT_INT_NATIVE_SLOTS_LIST(V)                                           \
  TAGGED_NONINT_NATIVE_SLOTS_LIST(V)                                           \
  UNTAGGED_NATIVE_SLOTS_LIST(V)

// For uses that need any native slot on Dart objects that contains a Dart
// object (e.g., for write barrier purposes). Such uses can use the following
// arguments for each entry:
//     V(class_name, underlying_class, field_name, exact_type, FINAL|VAR|WEAK)
#define TAGGED_NATIVE_DART_SLOTS_LIST(V)                                       \
  NULLABLE_TAGGED_NATIVE_DART_SLOTS_LIST(V)                                    \
  NONNULLABLE_INT_TAGGED_NATIVE_DART_SLOTS_LIST(V)                             \
  NONNULLABLE_NONINT_TAGGED_NATIVE_DART_SLOTS_LIST(V)

// For uses that need any native slot that is not on a Dart object or does
// not contain a Dart object (e.g., for write barrier purposes). Such uses
// can only use the following arguments for each entry:
//     V(class_name, _, field_name, _, FINAL|VAR)
#define NOT_TAGGED_NATIVE_DART_SLOTS_LIST(V)                                   \
  NULLABLE_TAGGED_NATIVE_NONDART_SLOTS_LIST(V)                                 \
  NOT_TAGGED_NATIVE_SLOTS_LIST(V)

// For uses that need any native slot that contains a Dart object. Such uses can
// only use the following arguments for each entry:
//     V(class_name, _, field_name, exact_type, FINAL|VAR|WEAK)
#define TAGGED_NATIVE_SLOTS_LIST(V)                                            \
  TAGGED_INT_NATIVE_SLOTS_LIST(V)                                              \
  TAGGED_NONINT_NATIVE_SLOTS_LIST(V)

// For uses that need all native slots. Such uses can only use the following
// arguments for each entry:
//     V(class_name, _, field_name, _, FINAL|VAR|WEAK)
#define NATIVE_SLOTS_LIST(V)                                                   \
  TAGGED_NATIVE_SLOTS_LIST(V)                                                  \
  NOT_TAGGED_NATIVE_SLOTS_LIST(V)

// For tagged slots, the cid should either be Dynamic or the precise cid
// of the values stored in the corresponding field. That means the cid should
// not be the cid of an abstract superclass, because then the code will assume
// the cid of retrieved values is always the given cid.
//
// Note: If we ever need native slots with CompileTypes created from an
// AbstractType instead, then a new base category should be created for those,
// possibly replacing the cid field with the name of the abstract type.
#define CHECK_TAGGED_NATIVE_SLOT(__, ___, ____, field_type, _____)             \
  static_assert(k##field_type##Cid != kObjectCid);                             \
  static_assert(k##field_type##Cid != kInstanceCid);                           \
  static_assert(k##field_type##Cid != kIntegerCid);                            \
  static_assert(k##field_type##Cid != kStringCid);                             \
  static_assert(k##field_type##Cid != kAbstractTypeCid);
TAGGED_NATIVE_SLOTS_LIST(CHECK_TAGGED_NATIVE_SLOT)
#undef CHECK_NULLABLE_TAGGED_NATIVE_SLOT

// Currently we only create slots with CompileTypes created from a precise cid,
// so integer slots listed here must only contain Smis (or Mints, but no slot
// currently does has only Mints, adjust this check if one is added).
//
// Note: If we ever add a category of native slots with AbstractType-based
// CompileTypes that always contain integers, then add additional checks that
// the AbstractTypes of those slots are subtypes of Integer.
#define CHECK_INT_NATIVE_SLOT(__, ___, ____, field_type, _____)                \
  static_assert(k##field_type##Cid == kSmiCid);
TAGGED_INT_NATIVE_SLOTS_LIST(CHECK_INT_NATIVE_SLOT)
#undef CHECK_INT_NATIVE_SLOT

// Any slot with an integer type should go into the correct category.
//
// Note: If we ever add native slots with AbstractType-based CompileTypes, then
// add appropriate checks that the AbstractType is not a subtype of Integer.
#define CHECK_NONINT_NATIVE_SLOT(__, ___, ____, field_type, _____)             \
  static_assert(k##field_type##Cid != kSmiCid);                                \
  static_assert(k##field_type##Cid != kMintCid);
TAGGED_NONINT_NATIVE_SLOTS_LIST(CHECK_NONINT_NATIVE_SLOT)
#undef CHECK_NONINT_NATIVE_SLOT

class FieldGuardState {
 public:
  FieldGuardState() : state_(0) {}
  explicit FieldGuardState(const Field& field);

  intptr_t guarded_cid() const { return GuardedCidBits::decode(state_); }
  bool is_nullable() const { return IsNullableBit::decode(state_); }

 private:
  using GuardedCidBits = BitField<int32_t, ClassIdTagType, 0, 20>;
  using IsNullableBit = BitField<int32_t, bool, GuardedCidBits::kNextBit, 1>;

  const int32_t state_;
};

// Slot is an abstraction that describes an readable (and possibly writeable)
// location within an object.
//
// Slot objects returned by Slot::Get* methods have identity and can be
// compared by pointer. If two slots are different they must not alias.
// If two slots can alias - they must be represented by identical
// slot object.
class Slot : public ZoneAllocated {
 public:
  // clang-format off
  enum class Kind : uint8_t {
    // Native slots are identified by their kind - each native slot has its own.
#define DECLARE_KIND(ClassName, __, FieldName, ___, ____)                      \
  k##ClassName##_##FieldName,
    NATIVE_SLOTS_LIST(DECLARE_KIND)
#undef DECLARE_KIND

    // A slot used to store type arguments.
    kTypeArguments,

    // A slot at a specific [index] in a [UntaggedTypeArgument] vector.
    kTypeArgumentsIndex,

    // A slot corresponding to an array element at given offset.
    // Only used during allocation sinking and in MaterializeObjectInstr.
    kArrayElement,

    // A slot corresponding to a record field at the given offset.
    kRecordField,

    // A slot within a Context object that contains a value of a captured
    // local variable.
    kCapturedVariable,

    // A slot that corresponds to a Dart field (has corresponding Field object).
    kDartField,
  };
  // clang-format on

  // Returns a slot that represents length field for the given [array_cid].
  static const Slot& GetLengthFieldForArrayCid(intptr_t array_cid);

  // Return a slot that represents type arguments field for the given class.
  //
  // We do not distinguish type argument fields within disjoint
  // class hierarchies: type argument fields at the same offset would be
  // represented by the same Slot object. Type argument slots are final
  // so disambiguating type arguments fields does not improve alias analysis.
  static const Slot& GetTypeArgumentsSlotFor(Thread* thread, const Class& cls);

  // Returns a slot at a specific [index] in a [UntaggedTypeArgument] vector.
  static const Slot& GetTypeArgumentsIndexSlot(Thread* thread, intptr_t index);

  // Returns a slot corresponding to an array element at [offset_in_bytes].
  static const Slot& GetArrayElementSlot(Thread* thread,
                                         intptr_t offset_in_bytes);

  // Returns a slot corresponding to a record field at [offset_in_bytes].
  static const Slot& GetRecordFieldSlot(Thread* thread,
                                        intptr_t offset_in_bytes);

  // Returns a slot that represents the given captured local variable.
  static const Slot& GetContextVariableSlotFor(Thread* thread,
                                               const LocalVariable& var);

  // Returns a slot that represents the given Dart field.
  static const Slot& Get(const Field& field,
                         const ParsedFunction* parsed_function);

  // Convenience getters for native slots.
#define DEFINE_GETTER(ClassName, __, FieldName, ___, ____)                     \
  static const Slot& ClassName##_##FieldName() {                               \
    return GetNativeSlot(Kind::k##ClassName##_##FieldName);                    \
  }

  NATIVE_SLOTS_LIST(DEFINE_GETTER)
#undef DEFINE_GETTER

  Kind kind() const { return kind_; }
  bool IsDartField() const { return kind() == Kind::kDartField; }
  bool IsLocalVariable() const { return kind() == Kind::kCapturedVariable; }
  bool IsTypeArguments() const { return kind() == Kind::kTypeArguments; }
  bool IsArgumentOfType() const { return kind() == Kind::kTypeArgumentsIndex; }
  bool IsArrayElement() const { return kind() == Kind::kArrayElement; }
  bool IsRecordField() const { return kind() == Kind::kRecordField; }
  bool IsLengthSlot() const;
  bool IsImmutableLengthSlot() const;

  const char* Name() const;

  intptr_t offset_in_bytes() const { return offset_in_bytes_; }

  // Currently returns the representation of unboxed native fields and kTagged
  // for most other types of fields. One special case: fields marked as
  // containing non-nullable ints in AOT kernel, which have the kUnboxedInt64
  // representation.
  Representation representation() const { return representation_; }

  bool is_immutable() const { return IsImmutableBit::decode(flags_); }

  bool is_weak() const { return IsWeakBit::decode(flags_); }

  // Returns true if properties of this slot were based on the guarded state
  // of the corresponding Dart field.
  bool is_guarded_field() const { return IsGuardedBit::decode(flags_); }

  bool is_compressed() const { return IsCompressedBit::decode(flags_); }

  // Returns true if the field is an unboxed native field that may contain an
  // inner pointer to a GC-movable object.
  bool may_contain_inner_pointer() const {
    return MayContainInnerPointerBit::decode(flags_);
  }

  // Type information about values that can be read from this slot.
  CompileType type() const { return type_; }

  const Field& field() const {
    ASSERT(IsDartField());
    ASSERT(data_ != nullptr);
    return *DataAs<const Field>();
  }

  bool Equals(const Slot& other) const;
  uword Hash() const;

  bool IsIdentical(const Slot& other) const { return this == &other; }

  bool IsContextSlot() const {
    return kind() == Kind::kCapturedVariable || kind() == Kind::kContext_parent;
  }

  bool is_tagged() const { return !IsNonTaggedBit::decode(flags_); }
  bool has_untagged_instance() const {
    return HasUntaggedInstanceBit::decode(flags_);
  }

  void Write(FlowGraphSerializer* s) const;
  static const Slot& Read(FlowGraphDeserializer* d);

 private:
  Slot(Kind kind,
       int8_t flags,
       intptr_t offset_in_bytes,
       const void* data,
       CompileType type,
       Representation representation,
       const FieldGuardState& field_guard_state = FieldGuardState())
      : kind_(kind),
        flags_(flags),
        offset_in_bytes_(offset_in_bytes),
        representation_(representation),
        field_guard_state_(field_guard_state),
        data_(data),
        type_(type) {}

  Slot(const Slot& other)
      : Slot(other.kind_,
             other.flags_,
             other.offset_in_bytes_,
             other.data_,
             other.type_,
             other.representation_,
             other.field_guard_state_) {}

  template <typename T>
  const T* DataAs() const {
    return static_cast<const T*>(data_);
  }

  static const Slot& GetCanonicalSlot(
      Thread* thread,
      Kind kind,
      int8_t flags,
      intptr_t offset_in_bytes,
      const void* data,
      CompileType type,
      Representation representation,
      const FieldGuardState& field_guard_state = FieldGuardState());

  static const Slot& GetNativeSlot(Kind kind);

  const FieldGuardState& field_guard_state() const {
    return field_guard_state_;
  }

  const Kind kind_;
  const int8_t flags_;
  const intptr_t offset_in_bytes_;
  const Representation representation_;

  const FieldGuardState field_guard_state_;

  // Kind dependent data:
  //   - name as a Dart String object for local variables;
  //   - name as a C string for native slots;
  //   - Field object for Dart fields;
  const void* data_;

  CompileType type_;

  using IsImmutableBit = BitField<decltype(flags_), bool, 0, 1>;
  using IsWeakBit =
      BitField<decltype(flags_), bool, IsImmutableBit::kNextBit, 1>;
  using IsGuardedBit = BitField<decltype(flags_), bool, IsWeakBit::kNextBit, 1>;
  using IsCompressedBit =
      BitField<decltype(flags_), bool, IsGuardedBit::kNextBit, 1>;
  // Stores whether a field isn't tagged so that tagged is the default value
  using IsNonTaggedBit =
      BitField<decltype(flags_), bool, IsCompressedBit::kNextBit, 1>;
  using MayContainInnerPointerBit =
      BitField<decltype(flags_), bool, IsNonTaggedBit::kNextBit, 1>;
  using HasUntaggedInstanceBit =
      BitField<decltype(flags_), bool, MayContainInnerPointerBit::kNextBit, 1>;

  friend class SlotCache;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_SLOT_H_
