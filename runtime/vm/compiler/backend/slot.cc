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

 private:
  explicit SlotCache(Thread* thread)
      : zone_(thread->zone()), fields_(thread->zone()) {}

  Zone* const zone_;
  DirectChainedHashMap<PointerKeyValueTrait<const Slot> > fields_;
};

#define NATIVE_SLOT_NAME(C, F) Kind::k##C##_##F
#define NATIVE_TO_STR(C, F) #C "_" #F

const char* Slot::KindToCString(Kind k) {
  switch (k) {
#define NATIVE_CASE(C, __, F, ___, ____)                                       \
  case NATIVE_SLOT_NAME(C, F):                                                 \
    return NATIVE_TO_STR(C, F);
    NATIVE_SLOTS_LIST(NATIVE_CASE)
#undef NATIVE_CASE
    case Kind::kTypeArguments:
      return "TypeArguments";
    case Kind::kArrayElement:
      return "ArrayElement";
    case Kind::kCapturedVariable:
      return "CapturedVariable";
    case Kind::kDartField:
      return "DartField";
    default:
      UNREACHABLE();
      return nullptr;
  }
}

bool Slot::ParseKind(const char* str, Kind* out) {
  ASSERT(str != nullptr && out != nullptr);
#define NATIVE_CASE(C, __, F, ___, ____)                                       \
  if (strcmp(str, NATIVE_TO_STR(C, F)) == 0) {                                 \
    *out = NATIVE_SLOT_NAME(C, F);                                             \
    return true;                                                               \
  }
  NATIVE_SLOTS_LIST(NATIVE_CASE)
#undef NATIVE_CASE
  if (strcmp(str, "TypeArguments") == 0) {
    *out = Kind::kTypeArguments;
    return true;
  }
  if (strcmp(str, "ArrayElement") == 0) {
    *out = Kind::kArrayElement;
    return true;
  }
  if (strcmp(str, "CapturedVariable") == 0) {
    *out = Kind::kCapturedVariable;
    return true;
  }
  if (strcmp(str, "DartField") == 0) {
    *out = Kind::kDartField;
    return true;
  }
  return false;
}

#undef NATIVE_TO_STR
#undef NATIVE_SLOT_NAME

static classid_t GetUnboxedNativeSlotCid(Representation rep) {
  // Currently we only support integer unboxed fields.
  if (RepresentationUtils::IsUnboxedInteger(rep)) {
    return Boxing::BoxCid(rep);
  }
  UNREACHABLE();
  return kIllegalCid;
}

AcqRelAtomic<Slot*> Slot::native_fields_(nullptr);

enum NativeSlotsEnumeration {
#define DECLARE_KIND(CN, __, FN, ___, ____) k##CN##_##FN,
  NATIVE_SLOTS_LIST(DECLARE_KIND)
#undef DECLARE_KIND
      kNativeSlotsCount
};

const Slot& Slot::GetNativeSlot(Kind kind) {
  if (native_fields_.load() == nullptr) {
    Slot* new_value = new Slot[kNativeSlotsCount]{
#define NULLABLE_FIELD_FINAL                                                   \
  (IsNullableBit::encode(true) | IsImmutableBit::encode(true))
#define NULLABLE_FIELD_VAR (IsNullableBit::encode(true))
#define DEFINE_NULLABLE_BOXED_NATIVE_FIELD(ClassName, UnderlyingType,          \
                                           FieldName, cid, mutability)         \
  Slot(Kind::k##ClassName##_##FieldName, NULLABLE_FIELD_##mutability,          \
       k##cid##Cid, compiler::target::ClassName::FieldName##_offset(),         \
       #ClassName "." #FieldName, nullptr, kTagged),

        NULLABLE_BOXED_NATIVE_SLOTS_LIST(DEFINE_NULLABLE_BOXED_NATIVE_FIELD)

#undef DEFINE_NULLABLE_BOXED_NATIVE_FIELD
#undef NULLABLE_FIELD_FINAL
#undef NULLABLE_FIELD_VAR

#define NONNULLABLE_FIELD_FINAL (Slot::IsImmutableBit::encode(true))
#define NONNULLABLE_FIELD_VAR (0)
#define DEFINE_NONNULLABLE_BOXED_NATIVE_FIELD(ClassName, UnderlyingType,       \
                                              FieldName, cid, mutability)      \
  Slot(Kind::k##ClassName##_##FieldName, NONNULLABLE_FIELD_##mutability,       \
       k##cid##Cid, compiler::target::ClassName::FieldName##_offset(),         \
       #ClassName "." #FieldName, nullptr, kTagged),

            NONNULLABLE_BOXED_NATIVE_SLOTS_LIST(
                DEFINE_NONNULLABLE_BOXED_NATIVE_FIELD)

#undef DEFINE_NONNULLABLE_BOXED_NATIVE_FIELD
#define DEFINE_UNBOXED_NATIVE_FIELD(ClassName, UnderlyingType, FieldName,      \
                                    representation, mutability)                \
  Slot(Kind::k##ClassName##_##FieldName, NONNULLABLE_FIELD_##mutability,       \
       GetUnboxedNativeSlotCid(kUnboxed##representation),                      \
       compiler::target::ClassName::FieldName##_offset(),                      \
       #ClassName "." #FieldName, nullptr, kUnboxed##representation),

                UNBOXED_NATIVE_SLOTS_LIST(DEFINE_UNBOXED_NATIVE_FIELD)

#undef DEFINE_UNBOXED_NATIVE_FIELD
#undef NONNULLABLE_FIELD_VAR
#undef NONNULLABLE_FIELD_FINAL
    };
    Slot* old_value = nullptr;
    if (!native_fields_.compare_exchange_strong(old_value, new_value)) {
      delete[] new_value;
    }
  }

  ASSERT(static_cast<uint8_t>(kind) < kNativeSlotsCount);
  return native_fields_.load()[static_cast<uint8_t>(kind)];
}

// Note: should only be called with cids of array-like classes.
const Slot& Slot::GetLengthFieldForArrayCid(intptr_t array_cid) {
  if (IsExternalTypedDataClassId(array_cid) || IsTypedDataClassId(array_cid) ||
      IsTypedDataViewClassId(array_cid)) {
    return GetNativeSlot(Kind::kTypedDataBase_length);
  }
  switch (array_cid) {
    case kGrowableObjectArrayCid:
      return GetNativeSlot(Kind::kGrowableObjectArray_length);

    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
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

const Slot& Slot::GetTypeArgumentsSlotAt(Thread* thread, intptr_t offset) {
  ASSERT(offset != Class::kNoTypeArguments);
  return SlotCache::Instance(thread).Canonicalize(Slot(
      Kind::kTypeArguments, IsImmutableBit::encode(true), kTypeArgumentsCid,
      offset, ":type_arguments", /*static_type=*/nullptr, kTagged));
}

const Slot& Slot::GetTypeArgumentsSlotFor(Thread* thread, const Class& cls) {
  return GetTypeArgumentsSlotAt(
      thread, compiler::target::Class::TypeArgumentsFieldOffset(cls));
}

const Slot& Slot::GetContextVariableSlotFor(Thread* thread,
                                            const LocalVariable& variable) {
  ASSERT(variable.is_captured());
  return SlotCache::Instance(thread).Canonicalize(
      Slot(Kind::kCapturedVariable,
           IsImmutableBit::encode(variable.is_final() && !variable.is_late()) |
               IsNullableBit::encode(true),
           kDynamicCid,
           compiler::target::Context::variable_offset(variable.index().value()),
           &variable.name(), &variable.type(), kTagged));
}

const Slot& Slot::GetTypeArgumentsIndexSlot(Thread* thread, intptr_t index) {
  const intptr_t offset =
      compiler::target::TypeArguments::type_at_offset(index);
  const Slot& slot =
      Slot(Kind::kTypeArgumentsIndex, IsImmutableBit::encode(true), kDynamicCid,
           offset, ":argument", /*static_type=*/nullptr, kTagged);
  return SlotCache::Instance(thread).Canonicalize(slot);
}

const Slot& Slot::GetArrayElementSlot(Thread* thread,
                                      intptr_t offset_in_bytes) {
  const Slot& slot =
      Slot(Kind::kArrayElement, IsNullableBit::encode(true), kDynamicCid,
           offset_in_bytes, ":array_element", /*static_type=*/nullptr, kTagged);
  return SlotCache::Instance(thread).Canonicalize(slot);
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
    } else if (MethodRecognizer::HasNonNullableResultTypeFromPragma(field)) {
      is_nullable = false;
    }
  }

  AbstractType& type = AbstractType::ZoneHandle(zone, field.type());
  if (type.IsStrictlyNonNullable()) {
    is_nullable = false;
  }

  bool used_guarded_state = false;
  if (field.guarded_cid() != kIllegalCid &&
      field.guarded_cid() != kDynamicCid) {
    // Use guarded state if it is more precise then what we already have.
    if (nullable_cid == kDynamicCid) {
      nullable_cid = field.guarded_cid();
      used_guarded_state = true;
    }

    if (is_nullable && !field.is_nullable()) {
      is_nullable = false;
      used_guarded_state = true;
    }
  }

  if (field.needs_load_guard()) {
    // Should be kept in sync with LoadStaticFieldInstr::ComputeType.
    type = Type::DynamicType();
    nullable_cid = kDynamicCid;
    is_nullable = true;
    used_guarded_state = false;
  }

  if (field.is_non_nullable_integer()) {
    ASSERT(FLAG_precompiled_mode);
    is_nullable = false;
    if (FlowGraphCompiler::IsUnboxedField(field)) {
      rep = kUnboxedInt64;
    }
  }

  const Slot& slot = SlotCache::Instance(thread).Canonicalize(
      Slot(Kind::kDartField,
           IsImmutableBit::encode((field.is_final() && !field.is_late()) ||
                                  field.is_const()) |
               IsNullableBit::encode(is_nullable) |
               IsGuardedBit::encode(used_guarded_state),
           nullable_cid, compiler::target::Field::OffsetOf(field), &field,
           &type, rep));

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
    if (thread->isolate()->use_field_guards()) {
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

CompileType Slot::ComputeCompileType() const {
  return CompileType::CreateNullable(is_nullable(), nullable_cid());
}

const AbstractType& Slot::static_type() const {
  return static_type_ != nullptr ? *static_type_ : Object::null_abstract_type();
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

bool Slot::Equals(const Slot* other) const {
  if (kind_ != other->kind_) {
    return false;
  }

  switch (kind_) {
    case Kind::kTypeArguments:
    case Kind::kTypeArgumentsIndex:
    case Kind::kArrayElement:
      return (offset_in_bytes_ == other->offset_in_bytes_);

    case Kind::kCapturedVariable:
      return (offset_in_bytes_ == other->offset_in_bytes_) &&
             (flags_ == other->flags_) &&
             (DataAs<const String>()->raw() ==
              other->DataAs<const String>()->raw());

    case Kind::kDartField:
      return (offset_in_bytes_ == other->offset_in_bytes_) &&
             other->DataAs<const Field>()->Original() ==
                 DataAs<const Field>()->Original();

    default:
      UNREACHABLE();
      return false;
  }
}

intptr_t Slot::Hashcode() const {
  intptr_t result = (static_cast<int8_t>(kind_) * 63 + offset_in_bytes_) * 31;
  if (IsDartField()) {
    result += String::Handle(DataAs<const Field>()->name()).Hash();
  } else if (IsLocalVariable()) {
    result += DataAs<const String>()->Hash();
  }
  return result;
}

}  // namespace dart
