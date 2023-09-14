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

// The list of slots that correspond to nullable boxed fields of native objects
// in the following format:
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
#define NULLABLE_BOXED_NATIVE_SLOTS_LIST(V)                                    \
  V(Array, UntaggedArray, type_arguments, TypeArguments, FINAL)                \
  V(Finalizer, UntaggedFinalizer, type_arguments, TypeArguments, FINAL)        \
  V(FinalizerBase, UntaggedFinalizerBase, all_entries, Set, VAR)               \
  V(FinalizerBase, UntaggedFinalizerBase, detachments, Dynamic, VAR)           \
  V(FinalizerBase, UntaggedFinalizer, entries_collected, FinalizerEntry, VAR)  \
  V(FinalizerEntry, UntaggedFinalizerEntry, value, Dynamic, VAR)               \
  V(FinalizerEntry, UntaggedFinalizerEntry, detach, Dynamic, VAR)              \
  V(FinalizerEntry, UntaggedFinalizerEntry, token, Dynamic, VAR)               \
  V(FinalizerEntry, UntaggedFinalizerEntry, finalizer, FinalizerBase, VAR)     \
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
  V(WeakProperty, UntaggedWeakProperty, key, Dynamic, VAR)                     \
  V(WeakProperty, UntaggedWeakProperty, value, Dynamic, VAR)                   \
  V(WeakReference, UntaggedWeakReference, target, Dynamic, VAR)                \
  V(WeakReference, UntaggedWeakReference, type_arguments, TypeArguments, FINAL)

// The list of slots that correspond to non-nullable boxed fields of native
// objects in the following format:
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
#define NONNULLABLE_BOXED_NATIVE_SLOTS_LIST(V)                                 \
  V(Array, UntaggedArray, length, Smi, FINAL)                                  \
  V(Closure, UntaggedClosure, function, Function, FINAL)                       \
  V(Closure, UntaggedClosure, context, Context, FINAL)                         \
  V(Closure, UntaggedClosure, hash, Context, VAR)                              \
  V(Finalizer, UntaggedFinalizer, callback, Closure, FINAL)                    \
  V(NativeFinalizer, UntaggedFinalizer, callback, Pointer, FINAL)              \
  V(Function, UntaggedFunction, data, Dynamic, FINAL)                          \
  V(FunctionType, UntaggedFunctionType, named_parameter_names, Array, FINAL)   \
  V(FunctionType, UntaggedFunctionType, parameter_types, Array, FINAL)         \
  V(GrowableObjectArray, UntaggedGrowableObjectArray, length, Smi, VAR)        \
  V(GrowableObjectArray, UntaggedGrowableObjectArray, data, Array, VAR)        \
  V(TypedDataBase, UntaggedTypedDataBase, length, Smi, FINAL)                  \
  V(TypedDataView, UntaggedTypedDataView, offset_in_bytes, Smi, FINAL)         \
  V(TypedDataView, UntaggedTypedDataView, typed_data, Dynamic, FINAL)          \
  V(String, UntaggedString, length, Smi, FINAL)                                \
  V(LinkedHashBase, UntaggedLinkedHashBase, index, TypedDataUint32Array, VAR)  \
  V(LinkedHashBase, UntaggedLinkedHashBase, data, Array, VAR)                  \
  V(ImmutableLinkedHashBase, UntaggedLinkedHashBase, data, ImmutableArray,     \
    FINAL)                                                                     \
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
  V(AbstractType, UntaggedTypeArguments, hash, Smi, VAR)                       \
  V(TypeParameters, UntaggedTypeParameters, names, Array, FINAL)               \
  V(UnhandledException, UntaggedUnhandledException, exception, Dynamic, FINAL) \
  V(UnhandledException, UntaggedUnhandledException, stacktrace, Dynamic, FINAL)

// Don't use Object or Instance, use Dynamic instead. The cid here should
// correspond to an exact type or Dynamic, not a static type.
// If we ever get a field of which the exact type is Instance (not a subtype),
// update the check below.
#define FOR_EACH_NATIVE_SLOT(_, __, ___, field_type, ____)                     \
  static_assert(k##field_type##Cid != kObjectCid);                             \
  static_assert(k##field_type##Cid != kInstanceCid);
NULLABLE_BOXED_NATIVE_SLOTS_LIST(FOR_EACH_NATIVE_SLOT)
NONNULLABLE_BOXED_NATIVE_SLOTS_LIST(FOR_EACH_NATIVE_SLOT)
#undef FOR_EACH_NATIVE_SLOT

// Only define AOT-only unboxed native slots when in the precompiler. See
// UNBOXED_NATIVE_SLOTS_LIST for the format.
#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
#define AOT_ONLY_UNBOXED_NATIVE_SLOTS_LIST(V)                                  \
  V(Closure, UntaggedClosure, entry_point, Uword, FINAL)
#else
#define AOT_ONLY_UNBOXED_NATIVE_SLOTS_LIST(V)
#endif

// List of slots that correspond to unboxed fields of native objects in the
// following format:
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
#define UNBOXED_NATIVE_SLOTS_LIST(V)                                           \
  AOT_ONLY_UNBOXED_NATIVE_SLOTS_LIST(V)                                        \
  V(AbstractType, UntaggedAbstractType, flags, Uint32, FINAL)                  \
  V(ClosureData, UntaggedClosureData, packed_fields, Uint32, FINAL)            \
  V(FinalizerBase, UntaggedFinalizerBase, isolate, IntPtr, VAR)                \
  V(FinalizerEntry, UntaggedFinalizerEntry, external_size, IntPtr, VAR)        \
  V(Function, UntaggedFunction, entry_point, Uword, FINAL)                     \
  V(Function, UntaggedFunction, kind_tag, Uint32, FINAL)                       \
  V(FunctionType, UntaggedFunctionType, packed_parameter_counts, Uint32,       \
    FINAL)                                                                     \
  V(FunctionType, UntaggedFunctionType, packed_type_parameter_counts, Uint16,  \
    FINAL)                                                                     \
  V(PointerBase, UntaggedPointerBase, data, IntPtr, VAR)                       \
  V(SubtypeTestCache, UntaggedSubtypeTestCache, num_inputs, Uint32, FINAL)

// For uses that do not need the exact_type (boxed) or representation (unboxed)
// or whether a boxed native slot is nullable. (Generally, such users only need
// the class name, the underlying type, and/or the field name.)
#define NATIVE_SLOTS_LIST(V)                                                   \
  NULLABLE_BOXED_NATIVE_SLOTS_LIST(V)                                          \
  NONNULLABLE_BOXED_NATIVE_SLOTS_LIST(V)                                       \
  UNBOXED_NATIVE_SLOTS_LIST(V)

class FieldGuardState {
 public:
  FieldGuardState() : state_(0) {}
  explicit FieldGuardState(const Field& field);

  intptr_t guarded_cid() const { return GuardedCidBits::decode(state_); }
  bool is_nullable() const { return IsNullableBit::decode(state_); }

 private:
  using GuardedCidBits = BitField<int32_t, ClassIdTagType, 0, 16>;
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
#define DEFINE_GETTER(ClassName, UnderlyingType, FieldName, __, ___)           \
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
  bool IsRecordField() const {
    return kind() == Kind::kRecordField;
  }
  bool IsImmutableLengthSlot() const;

  const char* Name() const;

  intptr_t offset_in_bytes() const { return offset_in_bytes_; }

  // Currently returns the representation of unboxed native fields and kTagged
  // for most other types of fields. One special case: fields marked as
  // containing non-nullable ints in AOT kernel, which have the kUnboxedInt64
  // representation.
  Representation representation() const { return representation_; }

  bool is_immutable() const { return IsImmutableBit::decode(flags_); }

  // Returns true if properties of this slot were based on the guarded state
  // of the corresponding Dart field.
  bool is_guarded_field() const { return IsGuardedBit::decode(flags_); }

  bool is_compressed() const { return IsCompressedBit::decode(flags_); }

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

  bool is_unboxed() const {
    return IsUnboxedBit::decode(flags_);
  }
  Representation UnboxedRepresentation() const;

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

  using IsImmutableBit = BitField<int8_t, bool, 0, 1>;
  using IsGuardedBit = BitField<int8_t, bool, IsImmutableBit::kNextBit, 1>;
  using IsCompressedBit = BitField<int8_t, bool, IsGuardedBit::kNextBit, 1>;
  using IsUnboxedBit = BitField<int8_t, bool, IsCompressedBit::kNextBit, 1>;

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

  friend class SlotCache;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_SLOT_H_
