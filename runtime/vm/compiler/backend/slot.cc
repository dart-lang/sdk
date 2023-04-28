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
  PointerSet<const Slot> fields_;
};

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
#define NULLABLE_FIELD_FINAL(ClassName)                                        \
  (IsNullableBit::encode(true) | IsImmutableBit::encode(true) |                \
   IsCompressedBit::encode(ClassName::ContainsCompressedPointers()))
#define NULLABLE_FIELD_VAR(ClassName)                                          \
  (IsNullableBit::encode(true) |                                               \
   IsCompressedBit::encode(ClassName::ContainsCompressedPointers()))
#define DEFINE_NULLABLE_BOXED_NATIVE_FIELD(ClassName, UnderlyingType,          \
                                           FieldName, cid, mutability)         \
  Slot(Kind::k##ClassName##_##FieldName,                                       \
       NULLABLE_FIELD_##mutability(ClassName), k##cid##Cid,                    \
       compiler::target::ClassName::FieldName##_offset(),                      \
       #ClassName "." #FieldName, nullptr, kTagged),

        NULLABLE_BOXED_NATIVE_SLOTS_LIST(DEFINE_NULLABLE_BOXED_NATIVE_FIELD)

#undef DEFINE_NULLABLE_BOXED_NATIVE_FIELD
#undef NULLABLE_FIELD_FINAL
#undef NULLABLE_FIELD_VAR

#define NONNULLABLE_FIELD_FINAL(ClassName)                                     \
  (Slot::IsImmutableBit::encode(true) |                                        \
   IsCompressedBit::encode(ClassName::ContainsCompressedPointers()))
#define NONNULLABLE_FIELD_VAR(ClassName)                                       \
  (IsCompressedBit::encode(ClassName::ContainsCompressedPointers()))
#define DEFINE_NONNULLABLE_BOXED_NATIVE_FIELD(ClassName, UnderlyingType,       \
                                              FieldName, cid, mutability)      \
  Slot(Kind::k##ClassName##_##FieldName,                                       \
       NONNULLABLE_FIELD_##mutability(ClassName), k##cid##Cid,                 \
       compiler::target::ClassName::FieldName##_offset(),                      \
       #ClassName "." #FieldName, nullptr, kTagged),

            NONNULLABLE_BOXED_NATIVE_SLOTS_LIST(
                DEFINE_NONNULLABLE_BOXED_NATIVE_FIELD)

#undef DEFINE_NONNULLABLE_BOXED_NATIVE_FIELD
#undef NONNULLABLE_FIELD_VAR
#undef NONNULLABLE_FIELD_FINAL

#define UNBOXED_FIELD_FINAL (Slot::IsImmutableBit::encode(true))
#define UNBOXED_FIELD_VAR (0)
#define DEFINE_UNBOXED_NATIVE_FIELD(ClassName, UnderlyingType, FieldName,      \
                                    representation, mutability)                \
  Slot(Kind::k##ClassName##_##FieldName, UNBOXED_FIELD_##mutability,           \
       GetUnboxedNativeSlotCid(kUnboxed##representation),                      \
       compiler::target::ClassName::FieldName##_offset(),                      \
       #ClassName "." #FieldName, nullptr, kUnboxed##representation),

                UNBOXED_NATIVE_SLOTS_LIST(DEFINE_UNBOXED_NATIVE_FIELD)

#undef DEFINE_UNBOXED_NATIVE_FIELD
#undef UNBOXED_FIELD_VAR
#undef UNBOXED_FIELD_FINAL
    };
    Slot* old_value = nullptr;
    if (!native_fields_.compare_exchange_strong(old_value, new_value)) {
      delete[] new_value;
    }
  }

  ASSERT(static_cast<uint8_t>(kind) < kNativeSlotsCount);
  return native_fields_.load()[static_cast<uint8_t>(kind)];
}

bool Slot::IsImmutableLengthSlot() const {
  switch (kind()) {
    case Slot::Kind::kArray_length:
    case Slot::Kind::kTypedDataBase_length:
    case Slot::Kind::kString_length:
    case Slot::Kind::kTypeArguments_length:
      return true;
    case Slot::Kind::kGrowableObjectArray_length:
      return false;

      // Not length loads.
#define UNBOXED_NATIVE_SLOT_CASE(Class, Untagged, Field, Rep, IsFinal)         \
  case Slot::Kind::k##Class##_##Field:
      UNBOXED_NATIVE_SLOTS_LIST(UNBOXED_NATIVE_SLOT_CASE)
#undef UNBOXED_NATIVE_SLOT_CASE
    case Slot::Kind::kReceivePort_send_port:
    case Slot::Kind::kReceivePort_handler:
    case Slot::Kind::kLinkedHashBase_index:
    case Slot::Kind::kImmutableLinkedHashBase_index:
    case Slot::Kind::kLinkedHashBase_data:
    case Slot::Kind::kImmutableLinkedHashBase_data:
    case Slot::Kind::kLinkedHashBase_hash_mask:
    case Slot::Kind::kLinkedHashBase_used_data:
    case Slot::Kind::kLinkedHashBase_deleted_keys:
    case Slot::Kind::kArgumentsDescriptor_type_args_len:
    case Slot::Kind::kArgumentsDescriptor_positional_count:
    case Slot::Kind::kArgumentsDescriptor_count:
    case Slot::Kind::kArgumentsDescriptor_size:
    case Slot::Kind::kArrayElement:
    case Slot::Kind::kInstance_native_fields_array:
    case Slot::Kind::kTypeArguments:
    case Slot::Kind::kTypeArguments_hash:
    case Slot::Kind::kTypedDataView_offset_in_bytes:
    case Slot::Kind::kTypedDataView_typed_data:
    case Slot::Kind::kGrowableObjectArray_data:
    case Slot::Kind::kArray_type_arguments:
    case Slot::Kind::kContext_parent:
    case Slot::Kind::kClosure_context:
    case Slot::Kind::kClosure_delayed_type_arguments:
    case Slot::Kind::kClosure_function:
    case Slot::Kind::kClosure_function_type_arguments:
    case Slot::Kind::kClosure_instantiator_type_arguments:
    case Slot::Kind::kClosure_hash:
    case Slot::Kind::kCapturedVariable:
    case Slot::Kind::kDartField:
    case Slot::Kind::kFinalizer_callback:
    case Slot::Kind::kFinalizer_type_arguments:
    case Slot::Kind::kFinalizerBase_all_entries:
    case Slot::Kind::kFinalizerBase_detachments:
    case Slot::Kind::kFinalizerBase_entries_collected:
    case Slot::Kind::kFinalizerEntry_detach:
    case Slot::Kind::kFinalizerEntry_finalizer:
    case Slot::Kind::kFinalizerEntry_next:
    case Slot::Kind::kFinalizerEntry_token:
    case Slot::Kind::kFinalizerEntry_value:
    case Slot::Kind::kNativeFinalizer_callback:
    case Slot::Kind::kFunction_data:
    case Slot::Kind::kFunction_signature:
    case Slot::Kind::kFunctionType_named_parameter_names:
    case Slot::Kind::kFunctionType_parameter_types:
    case Slot::Kind::kFunctionType_type_parameters:
    case Slot::Kind::kRecordField:
    case Slot::Kind::kRecord_shape:
    case Slot::Kind::kSuspendState_function_data:
    case Slot::Kind::kSuspendState_then_callback:
    case Slot::Kind::kSuspendState_error_callback:
    case Slot::Kind::kTypeArgumentsIndex:
    case Slot::Kind::kTypeParameters_names:
    case Slot::Kind::kTypeParameters_flags:
    case Slot::Kind::kTypeParameters_bounds:
    case Slot::Kind::kTypeParameters_defaults:
    case Slot::Kind::kUnhandledException_exception:
    case Slot::Kind::kUnhandledException_stacktrace:
    case Slot::Kind::kWeakProperty_key:
    case Slot::Kind::kWeakProperty_value:
    case Slot::Kind::kWeakReference_target:
    case Slot::Kind::kWeakReference_type_arguments:
      return false;
  }
  UNREACHABLE();
  return false;
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
      kTypeArgumentsCid, offset, ":type_arguments",
      /*static_type=*/nullptr, kTagged);
}

const Slot& Slot::GetContextVariableSlotFor(Thread* thread,
                                            const LocalVariable& variable) {
  ASSERT(variable.is_captured());
  return GetCanonicalSlot(
      thread, Kind::kCapturedVariable,
      IsImmutableBit::encode(variable.is_final() && !variable.is_late()) |
          IsNullableBit::encode(true) |
          IsCompressedBit::encode(Context::ContainsCompressedPointers()) |
          IsSentinelVisibleBit::encode(variable.is_late()),
      kDynamicCid,
      compiler::target::Context::variable_offset(variable.index().value()),
      &variable.name(), &variable.type(), kTagged);
}

const Slot& Slot::GetTypeArgumentsIndexSlot(Thread* thread, intptr_t index) {
  const intptr_t offset =
      compiler::target::TypeArguments::type_at_offset(index);
  return GetCanonicalSlot(
      thread, Kind::kTypeArgumentsIndex,
      IsImmutableBit::encode(true) |
          IsCompressedBit::encode(TypeArguments::ContainsCompressedPointers()),
      kDynamicCid, offset, ":argument", /*static_type=*/nullptr, kTagged);
}

const Slot& Slot::GetArrayElementSlot(Thread* thread,
                                      intptr_t offset_in_bytes) {
  return GetCanonicalSlot(
      thread, Kind::kArrayElement,
      IsNullableBit::encode(true) |
          IsCompressedBit::encode(Array::ContainsCompressedPointers()),
      kDynamicCid, offset_in_bytes, ":array_element",
      /*static_type=*/nullptr, kTagged);
}

const Slot& Slot::GetRecordFieldSlot(Thread* thread, intptr_t offset_in_bytes) {
  return GetCanonicalSlot(
      thread, Kind::kRecordField,
      IsNullableBit::encode(true) |
          IsCompressedBit::encode(Record::ContainsCompressedPointers()),
      kDynamicCid, offset_in_bytes, ":record_field",
      /*static_type=*/nullptr, kTagged);
}

const Slot& Slot::GetCanonicalSlot(Thread* thread,
                                   Slot::Kind kind,
                                   int8_t flags,
                                   ClassIdTagType cid,
                                   intptr_t offset_in_bytes,
                                   const void* data,
                                   const AbstractType* static_type,
                                   Representation representation,
                                   const FieldGuardState& field_guard_state) {
  const Slot& slot = Slot(kind, flags, cid, offset_in_bytes, data, static_type,
                          representation, field_guard_state);
  return SlotCache::Instance(thread).Canonicalize(slot);
}

FieldGuardState::FieldGuardState(const Field& field)
    : state_(GuardedCidBits::encode(field.guarded_cid()) |
             IsNullableBit::encode(field.is_nullable())) {}

Representation Slot::UnboxedRepresentation() const {
  switch (field_guard_state().guarded_cid()) {
    case kDoubleCid:
      return kUnboxedDouble;
    case kFloat32x4Cid:
      return kUnboxedFloat32x4;
    case kFloat64x2Cid:
      return kUnboxedFloat64x2;
    default:
      return kUnboxedInt64;
  }
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
    type = Type::DynamicType();
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

  Class& owner = Class::Handle(zone, field.Owner());
  const Slot& slot = GetCanonicalSlot(
      thread, Kind::kDartField,
      IsImmutableBit::encode((field.is_final() && !field.is_late()) ||
                             field.is_const()) |
          IsNullableBit::encode(is_nullable) |
          IsGuardedBit::encode(used_guarded_state) |
          IsCompressedBit::encode(
              compiler::target::Class::HasCompressedPointers(owner)) |
          IsSentinelVisibleBit::encode(field.is_late() && field.is_final() &&
                                       !field.has_initializer()) |
          IsUnboxedBit::encode(is_unboxed),
      nullable_cid, compiler::target::Field::OffsetOf(field), &field, &type,
      rep, field_guard_state);

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

CompileType Slot::ComputeCompileType() const {
  // If we unboxed the slot, we may know a more precise type.
  switch (representation()) {
#if defined(TARGET_ARCH_IS_32_BIT)
    // Int32/Uint32 values are not guaranteed to fit in a Smi.
    case kUnboxedInt32:
    case kUnboxedUint32:
#endif
    case kUnboxedInt64:
      if (nullable_cid() == kDynamicCid) {
        return CompileType::Int();
      }
      break;
#if defined(TARGET_ARCH_IS_64_BIT)
    // Int32/Uint32 values are guaranteed to fit in a Smi.
    case kUnboxedInt32:
    case kUnboxedUint32:
#endif
    case kUnboxedUint8:
      return CompileType::Smi();
    case kUnboxedDouble:
      return CompileType::FromCid(kDoubleCid);
    case kUnboxedInt32x4:
      return CompileType::FromCid(kInt32x4Cid);
    case kUnboxedFloat32x4:
      return CompileType::FromCid(kFloat32x4Cid);
    case kUnboxedFloat64x2:
      return CompileType::FromCid(kFloat64x2Cid);
    default:
      break;
  }

  return CompileType(is_nullable(), is_sentinel_visible(), nullable_cid(),
                     static_type_);
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

    case Kind::kCapturedVariable:
      return (flags_ == other.flags_) &&
             (DataAs<const String>()->ptr() ==
              other.DataAs<const String>()->ptr()) &&
             static_type_->Equals(*(other.static_type_));

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
