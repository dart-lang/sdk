// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"

#include "vm/object.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/runtime_offsets_list.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/longjump.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace compiler {
namespace target {

#include "vm/compiler/runtime_offsets_extracted.h"

bool IsSmi(int64_t v) {
  return Utils::IsInt(kSmiBits + 1, v);
}

bool WillAllocateNewOrRememberedContext(intptr_t num_context_variables) {
  if (!dart::Context::IsValidLength(num_context_variables)) return false;
  return dart::Heap::IsAllocatableInNewSpace(
      dart::Context::InstanceSize(num_context_variables));
}

bool WillAllocateNewOrRememberedArray(intptr_t length) {
  if (!dart::Array::IsValidLength(length)) return false;
  return !dart::Array::UseCardMarkingForAllocation(length);
}

}  // namespace target
}  // namespace compiler
}  // namespace dart

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace compiler {

bool IsSameObject(const Object& a, const Object& b) {
  if (a.IsMint() && b.IsMint()) {
    return Mint::Cast(a).value() == Mint::Cast(b).value();
  } else if (a.IsDouble() && b.IsDouble()) {
    return Double::Cast(a).value() == Double::Cast(b).value();
  }
  return a.raw() == b.raw();
}

bool IsEqualType(const AbstractType& a, const AbstractType& b) {
  return a.Equals(b);
}

bool IsDoubleType(const AbstractType& type) {
  return type.IsDoubleType();
}

bool IsBoolType(const AbstractType& type) {
  return type.IsBoolType();
}

bool IsIntType(const AbstractType& type) {
  return type.IsIntType();
}

bool IsSmiType(const AbstractType& type) {
  return type.IsSmiType();
}

bool IsNotTemporaryScopedHandle(const Object& obj) {
  return obj.IsNotTemporaryScopedHandle();
}

#define DO(clazz)                                                              \
  bool Is##clazz##Handle(const Object& obj) { return obj.Is##clazz(); }
CLASS_LIST_FOR_HANDLES(DO)
#undef DO

bool IsInOldSpace(const Object& obj) {
  return obj.IsSmi() || obj.IsOld();
}

intptr_t ObjectHash(const Object& obj) {
  if (obj.IsNull()) {
    return 2011;
  }
  if (obj.IsString() || obj.IsNumber()) {
    return Instance::Cast(obj).CanonicalizeHash();
  }
  if (obj.IsCode()) {
    // Instructions don't move during compaction.
    return Code::Cast(obj).PayloadStart();
  }
  if (obj.IsFunction()) {
    return Function::Cast(obj).Hash();
  }
  if (obj.IsField()) {
    return dart::String::HashRawSymbol(Field::Cast(obj).name());
  }
  // Unlikely.
  return obj.GetClassId();
}

void SetToNull(Object* obj) {
  *obj = Object::null();
}

Object& NewZoneHandle(Zone* zone) {
  return Object::ZoneHandle(zone, Object::null());
}

Object& NewZoneHandle(Zone* zone, const Object& obj) {
  return Object::ZoneHandle(zone, obj.raw());
}

const Object& NullObject() {
  return Object::null_object();
}

const Object& SentinelObject() {
  return Object::sentinel();
}

const Bool& TrueObject() {
  return dart::Bool::True();
}

const Bool& FalseObject() {
  return dart::Bool::False();
}

const Object& EmptyTypeArguments() {
  return Object::empty_type_arguments();
}

const Type& DynamicType() {
  return dart::Type::dynamic_type();
}

const Type& ObjectType() {
  return Type::Handle(dart::Type::ObjectType());
}

const Type& VoidType() {
  return dart::Type::void_type();
}

const Type& IntType() {
  return Type::Handle(dart::Type::IntType());
}

const Class& GrowableObjectArrayClass() {
  auto object_store = Isolate::Current()->object_store();
  return Class::Handle(object_store->growable_object_array_class());
}

const Class& MintClass() {
  auto object_store = Isolate::Current()->object_store();
  return Class::Handle(object_store->mint_class());
}

const Class& DoubleClass() {
  auto object_store = Isolate::Current()->object_store();
  return Class::Handle(object_store->double_class());
}

const Array& OneArgArgumentsDescriptor() {
  return Array::ZoneHandle(
      ArgumentsDescriptor::NewBoxed(/*type_args_len=*/0, /*num_arguments=*/1));
}

bool IsOriginalObject(const Object& object) {
  if (object.IsICData()) {
    return ICData::Cast(object).IsOriginal();
  } else if (object.IsField()) {
    return Field::Cast(object).IsOriginal();
  }
  return true;
}

const String& AllocateString(const char* buffer) {
  return String::ZoneHandle(String::New(buffer, dart::Heap::kOld));
}

bool HasIntegerValue(const dart::Object& object, int64_t* value) {
  if (object.IsInteger()) {
    *value = Integer::Cast(object).AsInt64Value();
    return true;
  }
  return false;
}

int32_t CreateJitCookie() {
  return static_cast<int32_t>(Isolate::Current()->random()->NextUInt32());
}

word TypedDataElementSizeInBytes(classid_t cid) {
  return dart::TypedData::ElementSizeInBytes(cid);
}

word TypedDataMaxNewSpaceElements(classid_t cid) {
  return (dart::Heap::kNewAllocatableSize - target::TypedData::InstanceSize()) /
         TypedDataElementSizeInBytes(cid);
}

const Field& LookupMathRandomStateFieldOffset() {
  const auto& math_lib = dart::Library::Handle(dart::Library::MathLibrary());
  ASSERT(!math_lib.IsNull());
  const auto& random_class = dart::Class::Handle(
      math_lib.LookupClassAllowPrivate(dart::Symbols::_Random()));
  ASSERT(!random_class.IsNull());
  const auto& state_field = dart::Field::ZoneHandle(
      random_class.LookupInstanceFieldAllowPrivate(dart::Symbols::_state()));
  return state_field;
}

const Field& LookupConvertUtf8DecoderScanFlagsField() {
  const auto& convert_lib =
      dart::Library::Handle(dart::Library::ConvertLibrary());
  ASSERT(!convert_lib.IsNull());
  const auto& _utf8decoder_class = dart::Class::Handle(
      convert_lib.LookupClassAllowPrivate(dart::Symbols::_Utf8Decoder()));
  ASSERT(!_utf8decoder_class.IsNull());
  const auto& scan_flags_field = dart::Field::ZoneHandle(
      _utf8decoder_class.LookupInstanceFieldAllowPrivate(
          dart::Symbols::_scanFlags()));
  return scan_flags_field;
}

word LookupFieldOffsetInBytes(const Field& field) {
  return field.TargetOffset();
}

#if defined(TARGET_ARCH_IA32)
uword SymbolsPredefinedAddress() {
  return reinterpret_cast<uword>(dart::Symbols::PredefinedAddress());
}
#endif

const Code& StubCodeAllocateArray() {
  return dart::StubCode::AllocateArray();
}

const Code& StubCodeSubtype3TestCache() {
  return dart::StubCode::Subtype3TestCache();
}

const Code& StubCodeSubtype7TestCache() {
  return dart::StubCode::Subtype7TestCache();
}

#define DEFINE_ALIAS(name)                                                     \
  const RuntimeEntry& k##name##RuntimeEntry(dart::k##name##RuntimeEntry);
RUNTIME_ENTRY_LIST(DEFINE_ALIAS)
#undef DEFINE_ALIAS

#define DEFINE_ALIAS(type, name, ...)                                          \
  const RuntimeEntry& k##name##RuntimeEntry(dart::k##name##RuntimeEntry);
LEAF_RUNTIME_ENTRY_LIST(DEFINE_ALIAS)
#undef DEFINE_ALIAS

void BailoutWithBranchOffsetError() {
  Thread::Current()->long_jump_base()->Jump(1, Object::branch_offset_error());
}

word RuntimeEntry::OffsetFromThread() const {
  return target::Thread::OffsetFromThread(runtime_entry_);
}

bool RuntimeEntry::is_leaf() const {
  return runtime_entry_->is_leaf();
}

namespace target {

const word kOldPageSize = dart::kOldPageSize;
const word kOldPageSizeInWords = dart::kOldPageSize / kWordSize;
const word kOldPageMask = dart::kOldPageMask;

static word TranslateOffsetInWordsToHost(word offset) {
  RELEASE_ASSERT((offset % kWordSize) == 0);
  return (offset / kWordSize) * dart::kWordSize;
}

bool SizeFitsInSizeTag(uword instance_size) {
  return dart::ObjectLayout::SizeTag::SizeFits(
      TranslateOffsetInWordsToHost(instance_size));
}

uword MakeTagWordForNewSpaceObject(classid_t cid, uword instance_size) {
  return dart::ObjectLayout::SizeTag::encode(
             TranslateOffsetInWordsToHost(instance_size)) |
         dart::ObjectLayout::ClassIdTag::encode(cid) |
         dart::ObjectLayout::NewBit::encode(true);
}

word Object::tags_offset() {
  return 0;
}

const word ObjectLayout::kCardRememberedBit =
    dart::ObjectLayout::kCardRememberedBit;

const word ObjectLayout::kOldAndNotRememberedBit =
    dart::ObjectLayout::kOldAndNotRememberedBit;

const word ObjectLayout::kOldAndNotMarkedBit =
    dart::ObjectLayout::kOldAndNotMarkedBit;

const word ObjectLayout::kSizeTagPos = dart::ObjectLayout::kSizeTagPos;

const word ObjectLayout::kSizeTagSize = dart::ObjectLayout::kSizeTagSize;

const word ObjectLayout::kClassIdTagPos = dart::ObjectLayout::kClassIdTagPos;

const word ObjectLayout::kClassIdTagSize = dart::ObjectLayout::kClassIdTagSize;

const word ObjectLayout::kHashTagPos = dart::ObjectLayout::kHashTagPos;

const word ObjectLayout::kHashTagSize = dart::ObjectLayout::kHashTagSize;

const word ObjectLayout::kSizeTagMaxSizeTag =
    dart::ObjectLayout::SizeTag::kMaxSizeTagInUnitsOfAlignment *
    ObjectAlignment::kObjectAlignment;

const word ObjectLayout::kTagBitsSizeTagPos =
    dart::ObjectLayout::TagBits::kSizeTagPos;

const word AbstractTypeLayout::kTypeStateFinalizedInstantiated =
    dart::AbstractTypeLayout::kFinalizedInstantiated;

const word ObjectLayout::kBarrierOverlapShift =
    dart::ObjectLayout::kBarrierOverlapShift;

bool IsTypedDataClassId(intptr_t cid) {
  return dart::IsTypedDataClassId(cid);
}

const word Class::kNoTypeArguments = dart::Class::kNoTypeArguments;

classid_t Class::GetId(const dart::Class& handle) {
  return handle.id();
}

static word TranslateOffsetInWords(word offset) {
  RELEASE_ASSERT((offset % dart::kWordSize) == 0);
  return (offset / dart::kWordSize) * kWordSize;
}

static uword GetInstanceSizeImpl(const dart::Class& handle) {
  switch (handle.id()) {
    case kMintCid:
      return Mint::InstanceSize();
    case kDoubleCid:
      return Double::InstanceSize();
    case kInt32x4Cid:
      return Int32x4::InstanceSize();
    case kFloat32x4Cid:
      return Float32x4::InstanceSize();
    case kFloat64x2Cid:
      return Float64x2::InstanceSize();
    case kObjectCid:
      return Object::InstanceSize();
    case kInstanceCid:
      return Instance::InstanceSize();
    case kGrowableObjectArrayCid:
      return GrowableObjectArray::InstanceSize();
    case kClosureCid:
      return Closure::InstanceSize();
    case kTypedDataBaseCid:
      return TypedDataBase::InstanceSize();
    case kLinkedHashMapCid:
      return LinkedHashMap::InstanceSize();
    case kUnhandledExceptionCid:
      return UnhandledException::InstanceSize();
    case kWeakPropertyCid:
      return WeakProperty::InstanceSize();
    case kByteBufferCid:
    case kByteDataViewCid:
    case kFfiPointerCid:
    case kFfiDynamicLibraryCid:
#define HANDLE_CASE(clazz) case kFfi##clazz##Cid:
      CLASS_LIST_FFI_TYPE_MARKER(HANDLE_CASE)
#undef HANDLE_CASE
#define HANDLE_CASE(clazz)                                                     \
  case kTypedData##clazz##Cid:                                                 \
  case kTypedData##clazz##ViewCid:                                             \
  case kExternalTypedData##clazz##Cid:
      CLASS_LIST_TYPED_DATA(HANDLE_CASE)
#undef HANDLE_CASE
      return handle.target_instance_size();
    default:
      if (handle.id() >= kNumPredefinedCids) {
        return handle.target_instance_size();
      }
  }
  FATAL3("Unsupported class for size translation: %s (id=%" Pd
         ", kNumPredefinedCids=%" Pd ")\n",
         handle.ToCString(), handle.id(), kNumPredefinedCids);
  return -1;
}

uword Class::GetInstanceSize(const dart::Class& handle) {
  return Utils::RoundUp(GetInstanceSizeImpl(handle),
                        ObjectAlignment::kObjectAlignment);
}

intptr_t Class::NumTypeArguments(const dart::Class& klass) {
  return klass.NumTypeArguments();
}

bool Class::HasTypeArgumentsField(const dart::Class& klass) {
  return klass.host_type_arguments_field_offset() !=
         dart::Class::kNoTypeArguments;
}

intptr_t Class::TypeArgumentsFieldOffset(const dart::Class& klass) {
  return klass.target_type_arguments_field_offset();
}

bool Class::TraceAllocation(const dart::Class& klass) {
  return klass.TraceAllocation(dart::Isolate::Current());
}

word Instance::first_field_offset() {
  return TranslateOffsetInWords(dart::Instance::NextFieldOffset());
}

word Instance::DataOffsetFor(intptr_t cid) {
  if (dart::IsExternalTypedDataClassId(cid) ||
      dart::IsExternalStringClassId(cid)) {
    // Elements start at offset 0 of the external data.
    return 0;
  }
  if (dart::IsTypedDataClassId(cid)) {
    return TypedData::data_offset();
  }
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
      return Array::data_offset();
    case kTypeArgumentsCid:
      return TypeArguments::types_offset();
    case kOneByteStringCid:
      return OneByteString::data_offset();
    case kTwoByteStringCid:
      return TwoByteString::data_offset();
    default:
      UNIMPLEMENTED();
      return Array::data_offset();
  }
}

word Instance::ElementSizeFor(intptr_t cid) {
  if (dart::IsExternalTypedDataClassId(cid) || dart::IsTypedDataClassId(cid) ||
      dart::IsTypedDataViewClassId(cid)) {
    return dart::TypedDataBase::ElementSizeInBytes(cid);
  }
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
    case kTypeArgumentsCid:
      return kWordSize;
    case kOneByteStringCid:
      return dart::OneByteString::kBytesPerElement;
    case kTwoByteStringCid:
      return dart::TwoByteString::kBytesPerElement;
    case kExternalOneByteStringCid:
      return dart::ExternalOneByteString::kBytesPerElement;
    case kExternalTwoByteStringCid:
      return dart::ExternalTwoByteString::kBytesPerElement;
    default:
      UNIMPLEMENTED();
      return 0;
  }
}

word ICData::CodeIndexFor(word num_args) {
  return dart::ICData::CodeIndexFor(num_args);
}

word ICData::CountIndexFor(word num_args) {
  return dart::ICData::CountIndexFor(num_args);
}

word ICData::TargetIndexFor(word num_args) {
  return dart::ICData::TargetIndexFor(num_args);
}

word ICData::ExactnessIndexFor(word num_args) {
  return dart::ICData::ExactnessIndexFor(num_args);
}

word ICData::TestEntryLengthFor(word num_args, bool exactness_check) {
  return dart::ICData::TestEntryLengthFor(num_args, exactness_check);
}

word ICData::EntryPointIndexFor(word num_args) {
  return dart::ICData::EntryPointIndexFor(num_args);
}

const word MegamorphicCache::kSpreadFactor =
    dart::MegamorphicCache::kSpreadFactor;

word Context::InstanceSize(word n) {
  return TranslateOffsetInWords(dart::Context::InstanceSize(n));
}

word Context::variable_offset(word n) {
  return TranslateOffsetInWords(dart::Context::variable_offset(n));
}

// Currently we have two different axes for offset generation:
//
//  * Target architecture
//  * DART_PRECOMPILED_RUNTIME (i.e, AOT vs. JIT)
//
// TODO(dartbug.com/43646): Add DART_PRECOMPILER as another axis.

#define DEFINE_CONSTANT(Class, Name) const word Class::Name = Class##_##Name;

#define DEFINE_PAYLOAD_SIZEOF(clazz, name, header)                             \
  word clazz::name() { return 0; }                                             \
  word clazz::name(word payload_size) {                                        \
    return RoundedAllocationSize(clazz::header() + payload_size);              \
  }

#if defined(TARGET_ARCH_IA32)

#define DEFINE_FIELD(clazz, name)                                              \
  word clazz::name() { return clazz##_##name; }

#define DEFINE_ARRAY(clazz, name)                                              \
  word clazz::name(intptr_t index) {                                           \
    return clazz##_elements_start_offset + index * clazz##_element_size;       \
  }

#define DEFINE_SIZEOF(clazz, name, what)                                       \
  word clazz::name() { return clazz##_##name; }

#define DEFINE_RANGE(Class, Getter, Type, First, Last, Filter)                 \
  word Class::Getter(Type index) {                                             \
    return Class##_##Getter[static_cast<intptr_t>(index) -                     \
                            static_cast<intptr_t>(First)];                     \
  }

JIT_OFFSETS_LIST(DEFINE_FIELD,
                 DEFINE_ARRAY,
                 DEFINE_SIZEOF,
                 DEFINE_PAYLOAD_SIZEOF,
                 DEFINE_RANGE,
                 DEFINE_CONSTANT)

COMMON_OFFSETS_LIST(DEFINE_FIELD,
                    DEFINE_ARRAY,
                    DEFINE_SIZEOF,
                    DEFINE_PAYLOAD_SIZEOF,
                    DEFINE_RANGE,
                    DEFINE_CONSTANT)

#else

#define DEFINE_JIT_FIELD(clazz, name)                                          \
  word clazz::name() {                                                         \
    if (FLAG_precompiled_mode) {                                               \
      FATAL1("Use JIT-only field %s in precompiled mode", #clazz "::" #name);  \
    }                                                                          \
    return clazz##_##name;                                                     \
  }

#define DEFINE_JIT_ARRAY(clazz, name)                                          \
  word clazz::name(intptr_t index) {                                           \
    if (FLAG_precompiled_mode) {                                               \
      FATAL1("Use of JIT-only array %s in precompiled mode",                   \
             #clazz "::" #name);                                               \
    }                                                                          \
    return clazz##_elements_start_offset + index * clazz##_element_size;       \
  }

#define DEFINE_JIT_SIZEOF(clazz, name, what)                                   \
  word clazz::name() {                                                         \
    if (FLAG_precompiled_mode) {                                               \
      FATAL1("Use of JIT-only sizeof %s in precompiled mode",                  \
             #clazz "::" #name);                                               \
    }                                                                          \
    return clazz##_##name;                                                     \
  }

#define DEFINE_JIT_RANGE(Class, Getter, Type, First, Last, Filter)             \
  word Class::Getter(Type index) {                                             \
    if (FLAG_precompiled_mode) {                                               \
      FATAL1("Use of JIT-only range %s in precompiled mode",                   \
             #Class "::" #Getter);                                             \
    }                                                                          \
    return Class##_##Getter[static_cast<intptr_t>(index) -                     \
                            static_cast<intptr_t>(First)];                     \
  }

JIT_OFFSETS_LIST(DEFINE_JIT_FIELD,
                 DEFINE_JIT_ARRAY,
                 DEFINE_JIT_SIZEOF,
                 DEFINE_PAYLOAD_SIZEOF,
                 DEFINE_JIT_RANGE,
                 DEFINE_CONSTANT)

#undef DEFINE_JIT_FIELD
#undef DEFINE_JIT_ARRAY
#undef DEFINE_JIT_SIZEOF
#undef DEFINE_JIT_RANGE

#define DEFINE_FIELD(clazz, name)                                              \
  word clazz::name() {                                                         \
    return FLAG_precompiled_mode ? AOT_##clazz##_##name : clazz##_##name;      \
  }

#define DEFINE_ARRAY(clazz, name)                                              \
  word clazz::name(intptr_t index) {                                           \
    if (FLAG_precompiled_mode) {                                               \
      return AOT_##clazz##_elements_start_offset +                             \
             index * AOT_##clazz##_element_size;                               \
    } else {                                                                   \
      return clazz##_elements_start_offset + index * clazz##_element_size;     \
    }                                                                          \
  }

#define DEFINE_SIZEOF(clazz, name, what)                                       \
  word clazz::name() {                                                         \
    return FLAG_precompiled_mode ? AOT_##clazz##_##name : clazz##_##name;      \
  }

#define DEFINE_RANGE(Class, Getter, Type, First, Last, Filter)                 \
  word Class::Getter(Type index) {                                             \
    if (FLAG_precompiled_mode) {                                               \
      return AOT_##Class##_##Getter[static_cast<intptr_t>(index) -             \
                                    static_cast<intptr_t>(First)];             \
    } else {                                                                   \
      return Class##_##Getter[static_cast<intptr_t>(index) -                   \
                              static_cast<intptr_t>(First)];                   \
    }                                                                          \
  }

COMMON_OFFSETS_LIST(DEFINE_FIELD,
                    DEFINE_ARRAY,
                    DEFINE_SIZEOF,
                    DEFINE_PAYLOAD_SIZEOF,
                    DEFINE_RANGE,
                    DEFINE_CONSTANT)

#endif

#undef DEFINE_FIELD
#undef DEFINE_ARRAY
#undef DEFINE_SIZEOF
#undef DEFINE_RANGE
#undef DEFINE_PAYLOAD_SIZEOF
#undef DEFINE_CONSTANT

const word StoreBufferBlock::kSize = dart::StoreBufferBlock::kSize;

const word MarkingStackBlock::kSize = dart::MarkingStackBlock::kSize;

// For InstructionsSections and Instructions, we define these by hand, because
// they depend on flags or #defines.

// Used for InstructionsSection and Instructions methods, since we don't
// serialize Instructions objects in bare instructions mode, just payloads.
DART_FORCE_INLINE static bool BareInstructionsPayloads() {
  return FLAG_precompiled_mode && FLAG_use_bare_instructions;
}

word InstructionsSection::HeaderSize() {
  // We only create InstructionsSections in precompiled mode.
  ASSERT(FLAG_precompiled_mode);
  return Utils::RoundUp(InstructionsSection::UnalignedHeaderSize(),
                        Instructions::kBarePayloadAlignment);
}

word Instructions::HeaderSize() {
  return BareInstructionsPayloads()
             ? 0
             : Utils::RoundUp(UnalignedHeaderSize(), kNonBarePayloadAlignment);
}

word Instructions::InstanceSize() {
  return 0;
}

word Instructions::InstanceSize(word payload_size) {
  const intptr_t alignment = BareInstructionsPayloads()
                                 ? kBarePayloadAlignment
                                 : ObjectAlignment::kObjectAlignment;
  return Utils::RoundUp(Instructions::HeaderSize() + payload_size, alignment);
}

word Thread::stack_overflow_shared_stub_entry_point_offset(bool fpu_regs) {
  return fpu_regs ? stack_overflow_shared_with_fpu_regs_entry_point_offset()
                  : stack_overflow_shared_without_fpu_regs_entry_point_offset();
}

uword Thread::safepoint_state_unacquired() {
  return dart::Thread::safepoint_state_unacquired();
}

uword Thread::safepoint_state_acquired() {
  return dart::Thread::safepoint_state_acquired();
}

intptr_t Thread::safepoint_state_inside_bit() {
  COMPILE_ASSERT(dart::Thread::AtSafepointField::bitsize() == 1);
  return dart::Thread::AtSafepointField::shift();
}

uword Thread::generated_execution_state() {
  return dart::Thread::ExecutionState::kThreadInGenerated;
}

uword Thread::native_execution_state() {
  return dart::Thread::ExecutionState::kThreadInNative;
}

uword Thread::vm_execution_state() {
  return dart::Thread::ExecutionState::kThreadInVM;
}

uword Thread::vm_tag_dart_id() {
  return dart::VMTag::kDartTagId;
}

uword Thread::exit_through_runtime_call() {
  return dart::Thread::kExitThroughRuntimeCall;
}

uword Thread::exit_through_ffi() {
  return dart::Thread::kExitThroughFfi;
}

word Thread::OffsetFromThread(const dart::Object& object) {
  auto host_offset = dart::Thread::OffsetFromThread(object);
  return object_null_offset() +
         TranslateOffsetInWords(host_offset -
                                dart::Thread::object_null_offset());
}

intptr_t Thread::OffsetFromThread(const dart::RuntimeEntry* runtime_entry) {
  auto host_offset = dart::Thread::OffsetFromThread(runtime_entry);
  return AllocateArray_entry_point_offset() +
         TranslateOffsetInWords(
             host_offset - dart::Thread::AllocateArray_entry_point_offset());
}

bool CanLoadFromThread(const dart::Object& object,
                       intptr_t* offset /* = nullptr */) {
  if (dart::Thread::CanLoadFromThread(object)) {
    if (offset != nullptr) {
      *offset = Thread::OffsetFromThread(object);
    }
    return true;
  }
  return false;
}

static_assert(
    kSmiBits <= dart::kSmiBits,
    "Expected that size of Smi on HOST is at least as large as on target.");

bool IsSmi(const dart::Object& a) {
  return a.IsSmi() && IsSmi(dart::Smi::Cast(a).Value());
}

word ToRawSmi(const dart::Object& a) {
  RELEASE_ASSERT(IsSmi(a));
  return static_cast<word>(static_cast<intptr_t>(a.raw()));
}

word ToRawSmi(intptr_t value) {
  return dart::Smi::RawValue(value);
}

word SmiValue(const dart::Object& a) {
  RELEASE_ASSERT(IsSmi(a));
  return static_cast<word>(dart::Smi::Cast(a).Value());
}

#if defined(TARGET_ARCH_IA32)
uword Code::EntryPointOf(const dart::Code& code) {
  static_assert(kHostWordSize == kWordSize,
                "Can't embed raw pointers to runtime objects when host and "
                "target word sizes are different");
  return code.EntryPoint();
}

bool CanEmbedAsRawPointerInGeneratedCode(const dart::Object& obj) {
  return obj.IsSmi() || obj.InVMIsolateHeap();
}

word ToRawPointer(const dart::Object& a) {
  static_assert(kHostWordSize == kWordSize,
                "Can't embed raw pointers to runtime objects when host and "
                "target word sizes are different");
  return static_cast<word>(a.raw());
}
#endif  // defined(TARGET_ARCH_IA32)

word RegExp::function_offset(classid_t cid, bool sticky) {
  return TranslateOffsetInWords(dart::RegExp::function_offset(cid, sticky));
}

const word Symbols::kNumberOfOneCharCodeSymbols =
    dart::Symbols::kNumberOfOneCharCodeSymbols;
const word Symbols::kNullCharCodeSymbolOffset =
    dart::Symbols::kNullCharCodeSymbolOffset;

const word String::kHashBits = dart::String::kHashBits;

const int8_t Nullability::kNullable =
    static_cast<int8_t>(dart::Nullability::kNullable);
const int8_t Nullability::kNonNullable =
    static_cast<int8_t>(dart::Nullability::kNonNullable);
const int8_t Nullability::kLegacy =
    static_cast<int8_t>(dart::Nullability::kLegacy);

bool Heap::IsAllocatableInNewSpace(intptr_t instance_size) {
  return dart::Heap::IsAllocatableInNewSpace(instance_size);
}

word Field::OffsetOf(const dart::Field& field) {
  return field.TargetOffset();
}

word FieldTable::OffsetOf(const dart::Field& field) {
  return TranslateOffsetInWords(
      dart::FieldTable::FieldOffsetFor(field.field_id()));
}

word FreeListElement::FakeInstance::InstanceSize() {
  return 0;
}

word ForwardingCorpse::FakeInstance::InstanceSize() {
  return 0;
}

word Instance::NextFieldOffset() {
  return TranslateOffsetInWords(dart::Instance::NextFieldOffset());
}

word Pointer::NextFieldOffset() {
  return TranslateOffsetInWords(dart::Pointer::NextFieldOffset());
}

word WeakSerializationReference::NextFieldOffset() {
  return -kWordSize;
}

word ObjectPool::NextFieldOffset() {
  return -kWordSize;
}

word Class::NextFieldOffset() {
  return -kWordSize;
}

word Function::NextFieldOffset() {
  return -kWordSize;
}

word ICData::NextFieldOffset() {
  return -kWordSize;
}

word MegamorphicCache::NextFieldOffset() {
  return -kWordSize;
}

word SingleTargetCache::NextFieldOffset() {
  return -kWordSize;
}

word Array::NextFieldOffset() {
  return -kWordSize;
}

intptr_t Array::index_at_offset(intptr_t offset_in_bytes) {
  return dart::Array::index_at_offset(
      TranslateOffsetInWordsToHost(offset_in_bytes));
}

word GrowableObjectArray::NextFieldOffset() {
  return -kWordSize;
}

word TypedDataBase::NextFieldOffset() {
  return -kWordSize;
}

word TypedData::NextFieldOffset() {
  return -kWordSize;
}

word ExternalTypedData::NextFieldOffset() {
  return -kWordSize;
}

word TypedDataView::NextFieldOffset() {
  return -kWordSize;
}

word LinkedHashMap::NextFieldOffset() {
  return -kWordSize;
}

word Type::NextFieldOffset() {
  return -kWordSize;
}

word TypeRef::NextFieldOffset() {
  return -kWordSize;
}

word Double::NextFieldOffset() {
  return -kWordSize;
}

word Mint::NextFieldOffset() {
  return -kWordSize;
}

word String::NextFieldOffset() {
  return -kWordSize;
}

word String::InstanceSize(word payload_size) {
  return RoundedAllocationSize(String::InstanceSize() + payload_size);
}

word OneByteString::NextFieldOffset() {
  return -kWordSize;
}

word TwoByteString::NextFieldOffset() {
  return -kWordSize;
}

word ExternalOneByteString::NextFieldOffset() {
  return -kWordSize;
}

word ExternalTwoByteString::NextFieldOffset() {
  return -kWordSize;
}

word Int32x4::NextFieldOffset() {
  return -kWordSize;
}

word Float32x4::NextFieldOffset() {
  return -kWordSize;
}

word Float64x2::NextFieldOffset() {
  return -kWordSize;
}

word DynamicLibrary::NextFieldOffset() {
  return -kWordSize;
}

word PatchClass::NextFieldOffset() {
  return -kWordSize;
}

word SignatureData::NextFieldOffset() {
  return -kWordSize;
}

word FfiTrampolineData::NextFieldOffset() {
  return -kWordSize;
}

word Script::NextFieldOffset() {
  return -kWordSize;
}

word Library::NextFieldOffset() {
  return -kWordSize;
}

word Namespace::NextFieldOffset() {
  return -kWordSize;
}

word KernelProgramInfo::NextFieldOffset() {
  return -kWordSize;
}

word PcDescriptors::NextFieldOffset() {
  return -kWordSize;
}

word CodeSourceMap::NextFieldOffset() {
  return -kWordSize;
}

word CompressedStackMaps::NextFieldOffset() {
  return -kWordSize;
}

word LocalVarDescriptors::NextFieldOffset() {
  return -kWordSize;
}

word ExceptionHandlers::NextFieldOffset() {
  return -kWordSize;
}

word ContextScope::NextFieldOffset() {
  return -kWordSize;
}

word UnlinkedCall::NextFieldOffset() {
  return -kWordSize;
}

word ApiError::NextFieldOffset() {
  return -kWordSize;
}

word LanguageError::NextFieldOffset() {
  return -kWordSize;
}

word UnhandledException::NextFieldOffset() {
  return -kWordSize;
}

word UnwindError::NextFieldOffset() {
  return -kWordSize;
}

word Bool::NextFieldOffset() {
  return -kWordSize;
}

word TypeParameter::NextFieldOffset() {
  return -kWordSize;
}

word LibraryPrefix::NextFieldOffset() {
  return -kWordSize;
}

word Capability::NextFieldOffset() {
  return -kWordSize;
}

word ReceivePort::NextFieldOffset() {
  return -kWordSize;
}

word SendPort::NextFieldOffset() {
  return -kWordSize;
}

word TransferableTypedData::NextFieldOffset() {
  return -kWordSize;
}

word StackTrace::NextFieldOffset() {
  return -kWordSize;
}

word Integer::NextFieldOffset() {
  return -kWordSize;
}

word Smi::NextFieldOffset() {
  return -kWordSize;
}

word WeakProperty::NextFieldOffset() {
  return -kWordSize;
}

word MirrorReference::NextFieldOffset() {
  return -kWordSize;
}

word Number::NextFieldOffset() {
  return -kWordSize;
}

word MonomorphicSmiableCall::NextFieldOffset() {
  return -kWordSize;
}

word InstructionsSection::NextFieldOffset() {
  return -kWordSize;
}

word Instructions::NextFieldOffset() {
  return -kWordSize;
}

word Code::NextFieldOffset() {
  return -kWordSize;
}

word SubtypeTestCache::NextFieldOffset() {
  return -kWordSize;
}

word LoadingUnit::NextFieldOffset() {
  return -kWordSize;
}

word Context::NextFieldOffset() {
  return -kWordSize;
}

word Closure::NextFieldOffset() {
  return -kWordSize;
}

word ClosureData::NextFieldOffset() {
  return -kWordSize;
}

word RegExp::NextFieldOffset() {
  return -kWordSize;
}

word UserTag::NextFieldOffset() {
  return -kWordSize;
}

word FutureOr::NextFieldOffset() {
  return -kWordSize;
}

word Field::NextFieldOffset() {
  return -kWordSize;
}

word TypeArguments::NextFieldOffset() {
  return -kWordSize;
}

word FreeListElement::FakeInstance::NextFieldOffset() {
  return -kWordSize;
}

word ForwardingCorpse::FakeInstance::NextFieldOffset() {
  return -kWordSize;
}

}  // namespace target
}  // namespace compiler
}  // namespace dart

#else

namespace dart {
namespace compiler {
namespace target {

const word Array::kMaxElements = Array_kMaxElements;

}  // namespace target
}  // namespace compiler
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
