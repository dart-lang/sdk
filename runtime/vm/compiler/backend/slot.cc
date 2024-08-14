// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/slot.h"

#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/compiler_state.h"
#include "vm/hash_map.h"
#include "vm/parser.h"
#include "vm/scopes.h"

namespace dart {

enum NativeSlotsEnumeration {
#define DECLARE_KIND(CN, __, FN, ___, ____) k##CN##_##FN,
  NATIVE_SLOTS_LIST(DECLARE_KIND)
#undef DECLARE_KIND
      kNativeSlotsCount
};

// Canonicalization cache for Slot objects.
//
// This cache is attached to the CompilerState to ensure that we preserve
// identity of Slot objects during each individual compilation.
class SlotCache : public ZoneAllocated {
 public:
  // Returns an instance of SlotCache for the current compilation.
  static SlotCache& Instance(Thread* thread) {
    auto result = thread->compiler_state().slot_cache();
    if (result == nullptr) {
      result = new (thread->zone()) SlotCache(thread);
      thread->compiler_state().set_slot_cache(result);
    }
    return *result;
  }

  const Slot& Canonicalize(const Slot& value) {
    auto result = fields_.LookupValue(&value);
    if (result == nullptr) {
      result = new (zone_) Slot(value);
      fields_.Insert(result);
    }
    return *result;
  }

  const Slot& GetNativeSlot(Slot::Kind kind) {
    const intptr_t index = static_cast<intptr_t>(kind);
    ASSERT((index >= 0) && (index < kNativeSlotsCount));
    const Slot* slot = native_fields_[index];
    if (slot == nullptr) {
      native_fields_[index] = slot = CreateNativeSlot(kind);
    }
    return *slot;
  }

 private:
  explicit SlotCache(Thread* thread)
      : zone_(thread->zone()), fields_(thread->zone()) {}

  Slot* CreateNativeSlot(Slot::Kind kind);

  Zone* const zone_;
  PointerSet<const Slot> fields_;
  const Slot* native_fields_[kNativeSlotsCount] = {nullptr};
};

Slot* SlotCache::CreateNativeSlot(Slot::Kind kind) {
  switch (kind) {
#define FIELD_FLAGS_FINAL                                                      \
  (Slot::IsImmutableBit::encode(true) | Slot::IsWeakBit::encode(false))
#define FIELD_FLAGS_VAR                                                        \
  (Slot::IsImmutableBit::encode(false) | Slot::IsWeakBit::encode(false))
#define FIELD_FLAGS_WEAK                                                       \
  (Slot::IsImmutableBit::encode(false) | Slot::IsWeakBit::encode(true))
#define DEFINE_NULLABLE_TAGGED_NATIVE_DART_FIELD(ClassName, UnderlyingType,    \
                                                 FieldName, cid, mutability)   \
  case Slot::Kind::k##ClassName##_##FieldName:                                 \
    return new (zone_) Slot(                                                   \
        Slot::Kind::k##ClassName##_##FieldName,                                \
        (FIELD_FLAGS_##mutability |                                            \
         Slot::IsCompressedBit::encode(                                        \
             ClassName::ContainsCompressedPointers())),                        \
        compiler::target::ClassName::FieldName##_offset(),                     \
        #ClassName "." #FieldName,                                             \
        CompileType(CompileType::kCanBeNull, CompileType::kCannotBeSentinel,   \
                    k##cid##Cid, nullptr),                                     \
        kTagged);

    NULLABLE_TAGGED_NATIVE_DART_SLOTS_LIST(
        DEFINE_NULLABLE_TAGGED_NATIVE_DART_FIELD)

#undef DEFINE_NULLABLE_TAGGED_NATIVE_DART_FIELD

#define DEFINE_NONNULLABLE_TAGGED_NATIVE_DART_FIELD(                           \
    ClassName, UnderlyingType, FieldName, cid, mutability)                     \
  case Slot::Kind::k##ClassName##_##FieldName:                                 \
    return new (zone_) Slot(                                                   \
        Slot::Kind::k##ClassName##_##FieldName,                                \
        (FIELD_FLAGS_##mutability |                                            \
         Slot::IsCompressedBit::encode(                                        \
             ClassName::ContainsCompressedPointers())),                        \
        compiler::target::ClassName::FieldName##_offset(),                     \
        #ClassName "." #FieldName,                                             \
        CompileType(CompileType::kCannotBeNull,                                \
                    CompileType::kCannotBeSentinel, k##cid##Cid, nullptr),     \
        kTagged);

    NONNULLABLE_INT_TAGGED_NATIVE_DART_SLOTS_LIST(
        DEFINE_NONNULLABLE_TAGGED_NATIVE_DART_FIELD)
    NONNULLABLE_NONINT_TAGGED_NATIVE_DART_SLOTS_LIST(
        DEFINE_NONNULLABLE_TAGGED_NATIVE_DART_FIELD)

#undef DEFINE_NONNULLABLE_TAGGED_NATIVE_DART_FIELD

#define DEFINE_UNBOXED_NATIVE_DART_FIELD(ClassName, UnderlyingType, FieldName, \
                                         representation, mutability)           \
  case Slot::Kind::k##ClassName##_##FieldName:                                 \
    return new (zone_)                                                         \
        Slot(Slot::Kind::k##ClassName##_##FieldName,                           \
             FIELD_FLAGS_##mutability | Slot::IsNonTaggedBit::encode(true),    \
             compiler::target::ClassName::FieldName##_offset(),                \
             #ClassName "." #FieldName,                                        \
             CompileType::FromUnboxedRepresentation(kUnboxed##representation), \
             kUnboxed##representation);

    UNBOXED_NATIVE_DART_SLOTS_LIST(DEFINE_UNBOXED_NATIVE_DART_FIELD)

#undef DEFINE_UNBOXED_NATIVE_DART_FIELD

#define DEFINE_UNTAGGED_NATIVE_DART_FIELD(ClassName, UnderlyingType,           \
                                          FieldName, GcMayMove, mutability)    \
  case Slot::Kind::k##ClassName##_##FieldName:                                 \
    return new (zone_)                                                         \
        Slot(Slot::Kind::k##ClassName##_##FieldName,                           \
             FIELD_FLAGS_##mutability |                                        \
                 Slot::MayContainInnerPointerBit::encode(GcMayMove) |          \
                 Slot::IsNonTaggedBit::encode(true),                           \
             compiler::target::ClassName::FieldName##_offset(),                \
             #ClassName "." #FieldName, CompileType::Object(), kUntagged);

    UNTAGGED_NATIVE_DART_SLOTS_LIST(DEFINE_UNTAGGED_NATIVE_DART_FIELD)

#undef DEFINE_UNTAGGED_NATIVE_DART_FIELD

#define DEFINE_NULLABLE_TAGGED_NATIVE_NONDART_FIELD(ClassName, __, FieldName,  \
                                                    cid, mutability)           \
  case Slot::Kind::k##ClassName##_##FieldName:                                 \
    return new (zone_) Slot(                                                   \
        Slot::Kind::k##ClassName##_##FieldName,                                \
        FIELD_FLAGS_##mutability | Slot::HasUntaggedInstanceBit::encode(true), \
        compiler::target::ClassName::FieldName##_offset(),                     \
        #ClassName "." #FieldName,                                             \
        CompileType(CompileType::kCanBeNull, CompileType::kCannotBeSentinel,   \
                    k##cid##Cid, nullptr),                                     \
        kTagged);

    NULLABLE_TAGGED_NATIVE_NONDART_SLOTS_LIST(
        DEFINE_NULLABLE_TAGGED_NATIVE_NONDART_FIELD)

#undef DEFINE_NULLABLE_TAGGED_NONDART_FIELD

#define DEFINE_UNBOXED_NATIVE_NONDART_FIELD(ClassName, __, FieldName,          \
                                            representation, mutability)        \
  case Slot::Kind::k##ClassName##_##FieldName:                                 \
    return new (zone_)                                                         \
        Slot(Slot::Kind::k##ClassName##_##FieldName,                           \
             FIELD_FLAGS_##mutability | Slot::IsNonTaggedBit::encode(true) |   \
                 Slot::HasUntaggedInstanceBit::encode(true),                   \
             compiler::target::ClassName::FieldName##_offset(),                \
             #ClassName "." #FieldName,                                        \
             CompileType::FromUnboxedRepresentation(kUnboxed##representation), \
             kUnboxed##representation);

    UNBOXED_NATIVE_NONDART_SLOTS_LIST(DEFINE_UNBOXED_NATIVE_NONDART_FIELD)

#undef DEFINE_UNBOXED_NATIVE_NONDART_FIELD

#define DEFINE_UNTAGGED_NATIVE_NONDART_FIELD(ClassName, __, FieldName,         \
                                             gc_may_move, mutability)          \
  case Slot::Kind::k##ClassName##_##FieldName:                                 \
    return new (zone_)                                                         \
        Slot(Slot::Kind::k##ClassName##_##FieldName,                           \
             FIELD_FLAGS_##mutability |                                        \
                 Slot::MayContainInnerPointerBit::encode(gc_may_move) |        \
                 Slot::IsNonTaggedBit::encode(true) |                          \
                 Slot::HasUntaggedInstanceBit::encode(true),                   \
             compiler::target::ClassName::FieldName##_offset(),                \
             #ClassName "." #FieldName, CompileType::Object(), kUntagged);

    UNTAGGED_NATIVE_NONDART_SLOTS_LIST(DEFINE_UNTAGGED_NATIVE_NONDART_FIELD)

#undef DEFINE_UNTAGGED_NATIVE_NONDART_FIELD

#undef FIELD_FLAGS_FINAL
#undef FIELD_FLAGS_VAR
#undef FIELD_FLAGS_WEAK
    default:
      UNREACHABLE();
  }
}

const Slot& Slot::GetNativeSlot(Kind kind) {
  return SlotCache::Instance(Thread::Current()).GetNativeSlot(kind);
}

bool Slot::IsLengthSlot() const {
  switch (kind()) {
    case Slot::Kind::kArray_length:
    case Slot::Kind::kTypedDataBase_length:
    case Slot::Kind::kString_length:
    case Slot::Kind::kTypeArguments_length:
    case Slot::Kind::kGrowableObjectArray_length:
      return true;
    default:
      return false;
  }
}

bool Slot::IsImmutableLengthSlot() const {
  switch (kind()) {
    case Slot::Kind::kArray_length:
    case Slot::Kind::kTypedDataBase_length:
    case Slot::Kind::kString_length:
    case Slot::Kind::kTypeArguments_length:
      return true;
    default:
      return false;
  }
}

// Note: should only be called with cids of array-like classes.
const Slot& Slot::GetLengthFieldForArrayCid(intptr_t array_cid) {
  if (IsExternalTypedDataClassId(array_cid) || IsTypedDataClassId(array_cid) ||
      IsTypedDataViewClassId(array_cid) ||
      IsUnmodifiableTypedDataViewClassId(array_cid)) {
    return GetNativeSlot(Kind::kTypedDataBase_length);
  }
  switch (array_cid) {
    case kGrowableObjectArrayCid:
      return GetNativeSlot(Kind::kGrowableObjectArray_length);

    case kOneByteStringCid:
    case kTwoByteStringCid:
      return GetNativeSlot(Kind::kString_length);

    case kArrayCid:
    case kImmutableArrayCid:
      return GetNativeSlot(Kind::kArray_length);

    case kTypeArgumentsCid:
      return GetNativeSlot(Kind::kTypeArguments_length);

    default:
      UNREACHABLE();
      return GetNativeSlot(Kind::kArray_length);
  }
}

const Slot& Slot::GetTypeArgumentsSlotFor(Thread* thread, const Class& cls) {
  if (cls.id() == kArrayCid || cls.id() == kImmutableArrayCid) {
    return Slot::Array_type_arguments();
  }
  const intptr_t offset =
      compiler::target::Class::TypeArgumentsFieldOffset(cls);
  ASSERT(offset != Class::kNoTypeArguments);
  return GetCanonicalSlot(
      thread, Kind::kTypeArguments,
      IsImmutableBit::encode(true) |
          IsCompressedBit::encode(
              compiler::target::Class::HasCompressedPointers(cls)),
      offset, ":type_arguments", CompileType::FromCid(kTypeArgumentsCid),
      kTagged);
}

const Slot& Slot::GetContextVariableSlotFor(Thread* thread,
                                            const LocalVariable& variable) {
  ASSERT(variable.is_captured());
  return GetCanonicalSlot(
      thread, Kind::kCapturedVariable,
      IsImmutableBit::encode(variable.is_final() && !variable.is_late()) |
          IsCompressedBit::encode(Context::ContainsCompressedPointers()),
      compiler::target::Context::variable_offset(variable.index().value()),
      &variable.name(), *(variable.inferred_type()), kTagged);
}

const Slot& Slot::GetTypeArgumentsIndexSlot(Thread* thread, intptr_t index) {
  const intptr_t offset =
      compiler::target::TypeArguments::type_at_offset(index);
  return GetCanonicalSlot(
      thread, Kind::kTypeArgumentsIndex,
      IsImmutableBit::encode(true) |
          IsCompressedBit::encode(TypeArguments::ContainsCompressedPointers()),
      offset, ":argument",
      CompileType(CompileType::kCannotBeNull, CompileType::kCannotBeSentinel,
                  kDynamicCid, nullptr),
      kTagged);
}

const Slot& Slot::GetArrayElementSlot(Thread* thread,
                                      intptr_t offset_in_bytes) {
  return GetCanonicalSlot(
      thread, Kind::kArrayElement,
      IsCompressedBit::encode(Array::ContainsCompressedPointers()),
      offset_in_bytes, ":array_element", CompileType::Dynamic(), kTagged);
}

const Slot& Slot::GetRecordFieldSlot(Thread* thread, intptr_t offset_in_bytes) {
  return GetCanonicalSlot(
      thread, Kind::kRecordField,
      IsCompressedBit::encode(Record::ContainsCompressedPointers()),
      offset_in_bytes, ":record_field", CompileType::Dynamic(), kTagged);
}

const Slot& Slot::GetCanonicalSlot(Thread* thread,
                                   Slot::Kind kind,
                                   int8_t flags,
                                   intptr_t offset_in_bytes,
                                   const void* data,
                                   CompileType type,
                                   Representation representation,
                                   const FieldGuardState& field_guard_state) {
  const Slot& slot = Slot(kind, flags, offset_in_bytes, data, type,
                          representation, field_guard_state);
  return SlotCache::Instance(thread).Canonicalize(slot);
}

FieldGuardState::FieldGuardState(const Field& field)
    : state_(GuardedCidBits::encode(field.guarded_cid()) |
             IsNullableBit::encode(field.is_nullable())) {
  ASSERT(compiler::target::UntaggedObject::kClassIdTagSize <=
         GuardedCidBits::bitsize());
}

const Slot& Slot::Get(const Field& field,
                      const ParsedFunction* parsed_function) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Representation rep = kTagged;
  intptr_t nullable_cid = kDynamicCid;
  bool is_nullable = true;

  if (field.has_pragma()) {
    const intptr_t cid = MethodRecognizer::ResultCidFromPragma(field);
    if (cid != kDynamicCid) {
      nullable_cid = cid;
      is_nullable = false;
    }
  }

  AbstractType& field_type = AbstractType::ZoneHandle(zone, field.type());
  if (field_type.IsStrictlyNonNullable()) {
    is_nullable = false;
  }

  FieldGuardState field_guard_state(field);

  bool used_guarded_state = false;
  if (field_guard_state.guarded_cid() != kIllegalCid &&
      field_guard_state.guarded_cid() != kDynamicCid) {
    // Use guarded state if it is more precise then what we already have.
    if (nullable_cid == kDynamicCid) {
      nullable_cid = field_guard_state.guarded_cid();
      used_guarded_state = true;
    }

    if (is_nullable && !field_guard_state.is_nullable()) {
      is_nullable = false;
      used_guarded_state = true;
    }
  }

  const bool needs_load_guard = field.needs_load_guard();
  const bool is_unboxed = field.is_unboxed();
  ASSERT(!(needs_load_guard && is_unboxed));

  if (needs_load_guard) {
    // Should be kept in sync with LoadStaticFieldInstr::ComputeType.
    field_type = Type::DynamicType();
    nullable_cid = kDynamicCid;
    is_nullable = true;
    used_guarded_state = false;
  }

  if (is_unboxed) {
    // The decision to unbox is made based on static types (or TFA annotations).
    // It is therefore not part of the dynamically initialized & updated guarded
    // state.
    used_guarded_state = false;
    is_nullable = false;
    nullable_cid = field_guard_state.guarded_cid();
    switch (nullable_cid) {
      case kDoubleCid:
        rep = kUnboxedDouble;
        break;
      case kFloat32x4Cid:
        rep = kUnboxedFloat32x4;
        break;
      case kFloat64x2Cid:
        rep = kUnboxedFloat64x2;
        break;
      default:
        rep = kUnboxedInt64;
        break;
    }
  }

  const bool is_sentinel_visible =
      field.is_late() && field.is_final() && !field.has_initializer();

  CompileType type = (rep != kTagged)
                         ? CompileType::FromUnboxedRepresentation(rep)
                         : CompileType(is_nullable, is_sentinel_visible,
                                       nullable_cid, &field_type);

  Class& owner = Class::Handle(zone, field.Owner());
  const Slot& slot = GetCanonicalSlot(
      thread, Kind::kDartField,
      IsImmutableBit::encode((field.is_final() && !field.is_late()) ||
                             field.is_const()) |
          IsGuardedBit::encode(used_guarded_state) |
          IsCompressedBit::encode(
              compiler::target::Class::HasCompressedPointers(owner)) |
          IsNonTaggedBit::encode(is_unboxed),
      compiler::target::Field::OffsetOf(field), &field, type, rep,
      field_guard_state);

  // If properties of this slot were based on the guarded state make sure
  // to add the field to the list of guarded fields. Note that during background
  // compilation we might have two field clones that have incompatible guarded
  // state - however both of these clones would correspond to the same slot.
  // That is why we check the is_guarded_field() property of the slot rather
  // than look at the current guarded state of the field, because current
  // guarded state of the field might be set to kDynamicCid, while it was
  // set to something more concrete when the slot was created.
  // Note that we could have created this slot during an unsuccessful inlining
  // attempt where we built and discarded the graph, in this case guarded
  // fields associated with that graph are also discarded. However the slot
  // itself stays behind in the compilation global cache. Thus we must always
  // try to add it to the list of guarded fields of the current function.
  if (slot.is_guarded_field()) {
    if (thread->isolate_group()->use_field_guards()) {
      ASSERT(parsed_function != nullptr);
      parsed_function->AddToGuardedFields(&slot.field());
    } else {
      // In precompiled mode we use guarded_cid field for type information
      // inferred by TFA.
      ASSERT(CompilerState::Current().is_aot());
    }
  }

  return slot;
}

const char* Slot::Name() const {
  if (IsLocalVariable()) {
    return DataAs<const String>()->ToCString();
  } else if (IsDartField()) {
    return String::Handle(field().name()).ToCString();
  } else {
    return DataAs<const char>();
  }
}

bool Slot::Equals(const Slot& other) const {
  if (kind_ != other.kind_ || offset_in_bytes_ != other.offset_in_bytes_) {
    return false;
  }

  switch (kind_) {
    case Kind::kTypeArguments:
    case Kind::kTypeArgumentsIndex:
    case Kind::kArrayElement:
    case Kind::kRecordField:
      return true;

    case Kind::kCapturedVariable: {
      auto other_type = other.type();
      return (flags_ == other.flags_) &&
             (DataAs<const String>()->ptr() ==
              other.DataAs<const String>()->ptr()) &&
             type().IsEqualTo(&other_type);
    }

    case Kind::kDartField:
      return other.DataAs<const Field>()->Original() ==
             DataAs<const Field>()->Original();

    default:
      UNREACHABLE();
      return false;
  }
}

uword Slot::Hash() const {
  uword result = (static_cast<int8_t>(kind_) * 63 + offset_in_bytes_) * 31;
  if (IsDartField()) {
    result += String::Handle(DataAs<const Field>()->name()).Hash();
  } else if (IsLocalVariable()) {
    result += DataAs<const String>()->Hash();
  }
  return result;
}

}  // namespace dart
