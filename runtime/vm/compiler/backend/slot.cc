// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/slot.h"

#ifndef DART_PRECOMPILED_RUNTIME

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

const Slot& Slot::GetNativeSlot(Kind kind) {
  // There is a fixed statically known number of native slots so we cache
  // them statically.
  static const Slot fields[] = {
#define FIELD_FINAL (IsImmutableBit::encode(true))
#define FIELD_VAR (0)
#define DEFINE_NATIVE_FIELD(ClassName, FieldName, cid, mutability)             \
  Slot(Kind::k##ClassName##_##FieldName, FIELD_##mutability, k##cid##Cid,      \
       ClassName::FieldName##_offset(), #ClassName "." #FieldName, nullptr),

      NATIVE_SLOTS_LIST(DEFINE_NATIVE_FIELD)

#undef DEFINE_FIELD
#undef FIELD_VAR
#undef FIELD_FINAL
  };

  ASSERT(static_cast<uint8_t>(kind) < ARRAY_SIZE(fields));
  return fields[static_cast<uint8_t>(kind)];
}

// Note: should only be called with cids of array-like classes.
const Slot& Slot::GetLengthFieldForArrayCid(intptr_t array_cid) {
  if (RawObject::IsExternalTypedDataClassId(array_cid) ||
      RawObject::IsTypedDataClassId(array_cid)) {
    return GetNativeSlot(Kind::kTypedData_length);
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

    default:
      UNREACHABLE();
      return GetNativeSlot(Kind::kArray_length);
  }
}

const Slot& Slot::GetTypeArgumentsSlotAt(Thread* thread, intptr_t offset) {
  ASSERT(offset != Class::kNoTypeArguments);
  return SlotCache::Instance(thread).Canonicalize(Slot(
      Kind::kTypeArguments, IsImmutableBit::encode(true), kTypeArgumentsCid,
      offset, ":type_arguments", /*static_type=*/nullptr));
}

const Slot& Slot::GetTypeArgumentsSlotFor(Thread* thread, const Class& cls) {
  return GetTypeArgumentsSlotAt(thread, cls.type_arguments_field_offset());
}

const Slot& Slot::GetContextVariableSlotFor(Thread* thread,
                                            const LocalVariable& variable) {
  ASSERT(variable.is_captured());
  // TODO(vegorov) Can't assign static type to local variables because
  // for captured parameters we generate the code that first stores a
  // variable into the context and then loads it from the context to perform
  // the type check.
  return SlotCache::Instance(thread).Canonicalize(Slot(
      Kind::kCapturedVariable,
      IsImmutableBit::encode(variable.is_final()) | IsNullableBit::encode(true),
      kDynamicCid, Context::variable_offset(variable.index().value()),
      &variable.name(), /*static_type=*/nullptr));
}

const Slot& Slot::Get(const Field& field,
                      const ParsedFunction* parsed_function) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
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

  const Slot& slot = SlotCache::Instance(thread).Canonicalize(
      Slot(Kind::kDartField,
           IsImmutableBit::encode(field.is_final() || field.is_const()) |
               IsNullableBit::encode(is_nullable) |
               IsGuardedBit::encode(used_guarded_state),
           nullable_cid, field.Offset(), &field,
           &AbstractType::ZoneHandle(zone, field.type())));

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
      ASSERT(FLAG_precompiled_mode);
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

#endif  // DART_PRECOMPILED_RUNTIME
