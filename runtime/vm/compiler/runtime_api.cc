// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"
#include "platform/utils.h"

namespace dart {
namespace compiler {
namespace target {

#include "vm/compiler/runtime_offsets_extracted.h"

bool IsSmi(int64_t v) {
  return Utils::IsInt(kSmiBits + 1, v);
}

}  // namespace target
}  // namespace compiler
}  // namespace dart

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/runtime_offsets_list.h"
#include "vm/dart_entry.h"
#include "vm/longjump.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"
#include "vm/symbols.h"
#include "vm/timeline.h"

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

word LookupFieldOffsetInBytes(const Field& field) {
  return field.Offset();
}

#if defined(TARGET_ARCH_IA32)
uword SymbolsPredefinedAddress() {
  return reinterpret_cast<uword>(dart::Symbols::PredefinedAddress());
}
#endif

#if !defined(TARGET_ARCH_DBC)
const Code& StubCodeAllocateArray() {
  return dart::StubCode::AllocateArray();
}

const Code& StubCodeSubtype2TestCache() {
  return dart::StubCode::Subtype2TestCache();
}

const Code& StubCodeSubtype6TestCache() {
  return dart::StubCode::Subtype6TestCache();
}
#endif  // !defined(TARGET_ARCH_DBC)

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

namespace target {

const word kPageSize = dart::kPageSize;
const word kPageSizeInWords = dart::kPageSize / kWordSize;
const word kPageMask = dart::kPageMask;

static word TranslateOffsetInWordsToHost(word offset) {
  RELEASE_ASSERT((offset % kWordSize) == 0);
  return (offset / kWordSize) * dart::kWordSize;
}

uint32_t MakeTagWordForNewSpaceObject(classid_t cid, uword instance_size) {
  return dart::RawObject::SizeTag::encode(
             TranslateOffsetInWordsToHost(instance_size)) |
         dart::RawObject::ClassIdTag::encode(cid) |
         dart::RawObject::NewBit::encode(true);
}

word Object::tags_offset() {
  return 0;
}

const word RawObject::kCardRememberedBit = dart::RawObject::kCardRememberedBit;

const word RawObject::kOldAndNotRememberedBit =
    dart::RawObject::kOldAndNotRememberedBit;

const word RawObject::kOldAndNotMarkedBit =
    dart::RawObject::kOldAndNotMarkedBit;

const word RawObject::kClassIdTagPos = dart::RawObject::kClassIdTagPos;

const word RawObject::kClassIdTagSize = dart::RawObject::kClassIdTagSize;

const word RawObject::kSizeTagMaxSizeTag =
    dart::RawObject::SizeTag::kMaxSizeTagInUnitsOfAlignment *
    ObjectAlignment::kObjectAlignment;

const word RawObject::kTagBitsSizeTagPos =
    dart::RawObject::TagBits::kSizeTagPos;

const word RawAbstractType::kTypeStateFinalizedInstantiated =
    dart::RawAbstractType::kFinalizedInstantiated;

const word RawObject::kBarrierOverlapShift =
    dart::RawObject::kBarrierOverlapShift;

bool RawObject::IsTypedDataClassId(intptr_t cid) {
  return dart::RawObject::IsTypedDataClassId(cid);
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
      return TranslateOffsetInWords(handle.instance_size());
    default:
      if (handle.id() >= kNumPredefinedCids) {
        return TranslateOffsetInWords(handle.instance_size());
      }
  }
  FATAL3("Unsupported class for size translation: %s (id=%" Pd
         ", kNumPredefinedCids=%d)\n",
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
  return klass.type_arguments_field_offset() != dart::Class::kNoTypeArguments;
}

intptr_t Class::TypeArgumentsFieldOffset(const dart::Class& klass) {
  return TranslateOffsetInWords(klass.type_arguments_field_offset());
}

bool Class::TraceAllocation(const dart::Class& klass) {
  return klass.TraceAllocation(dart::Isolate::Current());
}

word Instance::first_field_offset() {
  return TranslateOffsetInWords(dart::Instance::NextFieldOffset());
}

word Instance::DataOffsetFor(intptr_t cid) {
  if (dart::RawObject::IsExternalTypedDataClassId(cid) ||
      dart::RawObject::IsExternalStringClassId(cid)) {
    // Elements start at offset 0 of the external data.
    return 0;
  }
  if (dart::RawObject::IsTypedDataClassId(cid)) {
    return TypedData::data_offset();
  }
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
      return Array::data_offset();
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
  if (dart::RawObject::IsExternalTypedDataClassId(cid) ||
      dart::RawObject::IsTypedDataClassId(cid) ||
      dart::RawObject::IsTypedDataViewClassId(cid)) {
    return dart::TypedDataBase::ElementSizeInBytes(cid);
  }
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
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

#define DEFINE_FIELD(clazz, name)                                              \
  word clazz::name() { return clazz##_##name; }

#define DEFINE_ARRAY(clazz, name)                                              \
  word clazz::name(intptr_t index) {                                           \
    return clazz##_elements_start_offset + index * clazz##_element_size;       \
  }

#define DEFINE_ARRAY_STRUCTFIELD(clazz, name, element_offset, field_offset)    \
  word clazz::name(intptr_t index) {                                           \
    return element_offset(index) + field_offset;                               \
  }

#define DEFINE_SIZEOF(clazz, name, what)                                       \
  word clazz::name() { return clazz##_##name; }

#define DEFINE_RANGE(Class, Getter, Type, First, Last, Filter)                 \
  word Class::Getter(Type index) {                                             \
    return Class##_##Getter[static_cast<intptr_t>(index) -                     \
                            static_cast<intptr_t>(First)];                     \
  }

#define DEFINE_CONSTANT(Class, Name) const word Class::Name = Class##_##Name;

#define PRECOMP_NO_CHECK(Code) Code

OFFSETS_LIST(DEFINE_FIELD,
             DEFINE_ARRAY,
             DEFINE_ARRAY_STRUCTFIELD,
             DEFINE_SIZEOF,
             DEFINE_RANGE,
             DEFINE_CONSTANT,
             PRECOMP_NO_CHECK)

#undef DEFINE_FIELD
#undef DEFINE_ARRAY
#undef DEFINE_ARRAY_STRUCTFIELD
#undef DEFINE_SIZEOF
#undef DEFINE_RANGE
#undef DEFINE_CONSTANT
#undef PRECOMP_NO_CHECK

const word StoreBufferBlock::kSize = dart::StoreBufferBlock::kSize;

const word MarkingStackBlock::kSize = dart::MarkingStackBlock::kSize;

word Instructions::HeaderSize() {
  intptr_t alignment = OS::PreferredCodeAlignment();
  intptr_t aligned_size =
      Utils::RoundUp(Instructions::UnalignedHeaderSize(), alignment);
  ASSERT(aligned_size == alignment);
  return aligned_size;
}

#if !defined(TARGET_ARCH_DBC)
word Thread::stack_overflow_shared_stub_entry_point_offset(bool fpu_regs) {
  return fpu_regs ? stack_overflow_shared_with_fpu_regs_entry_point_offset()
                  : stack_overflow_shared_without_fpu_regs_entry_point_offset();
}
#endif  // !defined(TARGET_ARCH_DBC)

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

uword Thread::vm_tag_compiled_id() {
  return dart::VMTag::kDartCompiledTagId;
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
  return static_cast<word>(reinterpret_cast<intptr_t>(a.raw()));
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
  return reinterpret_cast<word>(a.raw());
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

bool Heap::IsAllocatableInNewSpace(intptr_t instance_size) {
  return dart::Heap::IsAllocatableInNewSpace(instance_size);
}

word Field::OffsetOf(const dart::Field& field) {
  return TranslateOffsetInWords(field.Offset());
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
