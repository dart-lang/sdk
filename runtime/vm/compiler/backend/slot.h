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
  V(Context, ContextLayout, parent, Context, FINAL)                            \
  V(Closure, ClosureLayout, instantiator_type_arguments, TypeArguments, FINAL) \
  V(Closure, ClosureLayout, delayed_type_arguments, TypeArguments, FINAL)      \
  V(Closure, ClosureLayout, function_type_arguments, TypeArguments, FINAL)     \
  V(ClosureData, ClosureDataLayout, default_type_arguments, TypeArguments,     \
    FINAL)                                                                     \
  V(Function, FunctionLayout, type_parameters, TypeArguments, FINAL)           \
  V(Type, TypeLayout, arguments, TypeArguments, FINAL)                         \
  V(WeakProperty, WeakPropertyLayout, key, Dynamic, VAR)                       \
  V(WeakProperty, WeakPropertyLayout, value, Dynamic, VAR)

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
  V(Array, ArrayLayout, length, Smi, FINAL)                                    \
  V(Closure, ClosureLayout, function, Function, FINAL)                         \
  V(Closure, ClosureLayout, context, Context, FINAL)                           \
  V(Closure, ClosureLayout, hash, Context, VAR)                                \
  V(ClosureData, ClosureDataLayout, default_type_arguments_info, Smi, FINAL)   \
  V(Function, FunctionLayout, data, Dynamic, FINAL)                            \
  V(Function, FunctionLayout, parameter_names, Array, FINAL)                   \
  V(Function, FunctionLayout, parameter_types, Array, FINAL)                   \
  V(GrowableObjectArray, GrowableObjectArrayLayout, length, Smi, VAR)          \
  V(GrowableObjectArray, GrowableObjectArrayLayout, data, Array, VAR)          \
  V(TypedDataBase, TypedDataBaseLayout, length, Smi, FINAL)                    \
  V(TypedDataView, TypedDataViewLayout, offset_in_bytes, Smi, FINAL)           \
  V(TypedDataView, TypedDataViewLayout, data, Dynamic, FINAL)                  \
  V(String, StringLayout, length, Smi, FINAL)                                  \
  V(LinkedHashMap, LinkedHashMapLayout, index, TypedDataUint32Array, VAR)      \
  V(LinkedHashMap, LinkedHashMapLayout, data, Array, VAR)                      \
  V(LinkedHashMap, LinkedHashMapLayout, hash_mask, Smi, VAR)                   \
  V(LinkedHashMap, LinkedHashMapLayout, used_data, Smi, VAR)                   \
  V(LinkedHashMap, LinkedHashMapLayout, deleted_keys, Smi, VAR)                \
  V(ArgumentsDescriptor, ArrayLayout, type_args_len, Smi, FINAL)               \
  V(ArgumentsDescriptor, ArrayLayout, positional_count, Smi, FINAL)            \
  V(ArgumentsDescriptor, ArrayLayout, count, Smi, FINAL)                       \
  V(ArgumentsDescriptor, ArrayLayout, size, Smi, FINAL)                        \
  V(PointerBase, PointerBaseLayout, data_field, Dynamic, FINAL)                \
  V(TypeArguments, TypeArgumentsLayout, length, Smi, FINAL)                    \
  V(TypeParameter, TypeParameterLayout, bound, Dynamic, FINAL)                 \
  V(TypeParameter, TypeParameterLayout, name, Dynamic, FINAL)                  \
  V(UnhandledException, UnhandledExceptionLayout, exception, Dynamic, FINAL)   \
  V(UnhandledException, UnhandledExceptionLayout, stacktrace, Dynamic, FINAL)

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
#define UNBOXED_NATIVE_SLOTS_LIST(V)                                           \
  V(Function, FunctionLayout, kind_tag, Uint32, FINAL)                         \
  V(Function, FunctionLayout, packed_fields, Uint32, FINAL)                    \
  V(TypeParameter, TypeParameterLayout, flags, Uint8, FINAL)

// For uses that do not need the exact_type (boxed) or representation (unboxed)
// or whether a boxed native slot is nullable. (Generally, such users only need
// the class name, the underlying type, and/or the field name.)
#define NATIVE_SLOTS_LIST(V)                                                   \
  NULLABLE_BOXED_NATIVE_SLOTS_LIST(V)                                          \
  NONNULLABLE_BOXED_NATIVE_SLOTS_LIST(V)                                       \
  UNBOXED_NATIVE_SLOTS_LIST(V)

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

    // A slot at a specific [index] in a [RawTypeArgument] vector.
    kTypeArgumentsIndex,

    // A slot corresponding to an array element at given offset.
    // Only used during allocation sinking and in MaterializeObjectInstr.
    kArrayElement,

    // A slot within a Context object that contains a value of a captured
    // local variable.
    kCapturedVariable,

    // A slot that corresponds to a Dart field (has corresponding Field object).
    kDartField,
  };
  // clang-format on

  static const char* KindToCString(Kind k);
  static bool ParseKind(const char* str, Kind* k);

  // Returns a slot that represents length field for the given [array_cid].
  static const Slot& GetLengthFieldForArrayCid(intptr_t array_cid);

  // Return a slot that represents type arguments field at the given offset
  // or for the given class.
  //
  // We do not distinguish type argument fields within disjoint
  // class hierarchies: type argument fields at the same offset would be
  // represented by the same Slot object. Type argument slots are final
  // so disambiguating type arguments fields does not improve alias analysis.
  static const Slot& GetTypeArgumentsSlotAt(Thread* thread, intptr_t offset);
  static const Slot& GetTypeArgumentsSlotFor(Thread* thread, const Class& cls);

  // Returns a slot at a specific [index] in a [RawTypeArgument] vector.
  static const Slot& GetTypeArgumentsIndexSlot(Thread* thread, intptr_t index);

  // Returns a slot corresponding to an array element at [offset_in_bytes].
  static const Slot& GetArrayElementSlot(Thread* thread,
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

  const char* Name() const;

  intptr_t offset_in_bytes() const { return offset_in_bytes_; }

  // Currently returns the representation of unboxed native fields and kTagged
  // for most other types of fields. One special case: fields marked as
  // containing non-nullable ints in AOT kernel, which have the kUnboxedInt64
  // representation.
  Representation representation() const { return representation_; }

  bool is_immutable() const { return IsImmutableBit::decode(flags_); }

  intptr_t nullable_cid() const { return cid_; }
  bool is_nullable() const { return IsNullableBit::decode(flags_); }

  // Returns true if properties of this slot were based on the guarded state
  // of the corresponding Dart field.
  bool is_guarded_field() const { return IsGuardedBit::decode(flags_); }

  // Static type of the slots if any.
  //
  // A value that is read from the slot is guaranteed to be assignable to its
  // static type.
  const AbstractType& static_type() const;

  // More precise type information about values that can be read from this slot.
  CompileType ComputeCompileType() const;

  const Field& field() const {
    ASSERT(IsDartField());
    ASSERT(data_ != nullptr);
    return *DataAs<const Field>();
  }

  bool Equals(const Slot* other) const;
  intptr_t Hashcode() const;

  bool IsIdentical(const Slot& other) const { return this == &other; }

  bool IsContextSlot() const {
    return kind() == Kind::kCapturedVariable || kind() == Kind::kContext_parent;
  }

 private:
  friend class FlowGraphDeserializer;  // For GetNativeSlot.

  Slot(Kind kind,
       int8_t bits,
       ClassIdTagType cid,
       intptr_t offset_in_bytes,
       const void* data,
       const AbstractType* static_type,
       Representation representation)
      : kind_(kind),
        flags_(bits),
        cid_(cid),
        offset_in_bytes_(offset_in_bytes),
        representation_(representation),
        data_(data),
        static_type_(static_type) {}

  Slot(const Slot& other)
      : Slot(other.kind_,
             other.flags_,
             other.cid_,
             other.offset_in_bytes_,
             other.data_,
             other.static_type_,
             other.representation_) {}

  using IsImmutableBit = BitField<int8_t, bool, 0, 1>;
  using IsNullableBit = BitField<int8_t, bool, IsImmutableBit::kNextBit, 1>;
  using IsGuardedBit = BitField<int8_t, bool, IsNullableBit::kNextBit, 1>;

  template <typename T>
  const T* DataAs() const {
    return static_cast<const T*>(data_);
  }

  // There is a fixed statically known number of native slots so we cache
  // them statically.
  static AcqRelAtomic<Slot*> native_fields_;
  static const Slot& GetNativeSlot(Kind kind);

  const Kind kind_;
  const int8_t flags_;  // is_immutable, is_nullable
  const ClassIdTagType cid_;  // Concrete cid of a value or kDynamicCid.

  const intptr_t offset_in_bytes_;
  const Representation representation_;

  // Kind dependent data:
  //   - name as a Dart String object for local variables;
  //   - name as a C string for native slots;
  //   - Field object for Dart fields;
  const void* data_;

  const AbstractType* static_type_;

  friend class SlotCache;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_SLOT_H_
