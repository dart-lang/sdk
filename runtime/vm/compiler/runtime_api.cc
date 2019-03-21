// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

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
  return obj.IsOld();
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
  return dart::TypedData::MaxNewSpaceElements(cid);
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

namespace target {

const word kPageSize = dart::kPageSize;
const word kPageSizeInWords = dart::kPageSizeInWords;
const word kPageMask = dart::kPageMask;

uint32_t MakeTagWordForNewSpaceObject(classid_t cid, uword instance_size) {
  return dart::RawObject::SizeTag::encode(instance_size) |
         dart::RawObject::ClassIdTag::encode(cid) |
         dart::RawObject::NewBit::encode(true);
}

word Object::tags_offset() {
  return dart::Object::tags_offset();
}

const word RawObject::kCardRememberedBit = dart::RawObject::kCardRememberedBit;

const word RawObject::kOldAndNotRememberedBit =
    dart::RawObject::kOldAndNotRememberedBit;

const word RawObject::kOldAndNotMarkedBit =
    dart::RawObject::kOldAndNotMarkedBit;

const word RawObject::kClassIdTagPos = dart::RawObject::kClassIdTagPos;

const word RawObject::kClassIdTagSize = dart::RawObject::kClassIdTagSize;

const word RawObject::kSizeTagMaxSizeTag =
    dart::RawObject::SizeTag::kMaxSizeTag;

const word RawObject::kTagBitsSizeTagPos =
    dart::RawObject::TagBits::kSizeTagPos;

const word RawAbstractType::kTypeStateFinalizedInstantiated =
    dart::RawAbstractType::kFinalizedInstantiated;

const word RawObject::kBarrierOverlapShift =
    dart::RawObject::kBarrierOverlapShift;

intptr_t ObjectPool::element_offset(intptr_t index) {
  return dart::ObjectPool::element_offset(index);
}

word Class::type_arguments_field_offset_in_words_offset() {
  return dart::Class::type_arguments_field_offset_in_words_offset();
}

word Class::declaration_type_offset() {
  return dart::Class::declaration_type_offset();
}

word Class::num_type_arguments_offset_in_bytes() {
  return dart::Class::num_type_arguments_offset();
}

const word Class::kNoTypeArguments = dart::Class::kNoTypeArguments;

classid_t Class::GetId(const dart::Class& handle) {
  return handle.id();
}

uword Class::GetInstanceSize(const dart::Class& handle) {
  return handle.instance_size();
}

intptr_t Class::NumTypeArguments(const dart::Class& klass) {
  return klass.NumTypeArguments() > 0;
}

bool Class::HasTypeArgumentsField(const dart::Class& klass) {
  return klass.type_arguments_field_offset() != dart::Class::kNoTypeArguments;
}

intptr_t Class::TypeArgumentsFieldOffset(const dart::Class& klass) {
  return klass.type_arguments_field_offset();
}

intptr_t Class::InstanceSize(const dart::Class& klass) {
  return klass.instance_size();
}

bool Class::TraceAllocation(const dart::Class& klass) {
  return klass.TraceAllocation(dart::Isolate::Current());
}

word Instance::first_field_offset() {
  return dart::Instance::NextFieldOffset();
}

word Instance::DataOffsetFor(intptr_t cid) {
  return dart::Instance::DataOffsetFor(cid);
}

word Instance::ElementSizeFor(intptr_t cid) {
  return dart::Instance::ElementSizeFor(cid);
}

word Function::code_offset() {
  return dart::Function::code_offset();
}

word Function::entry_point_offset() {
  return dart::Function::entry_point_offset();
}

word Function::usage_counter_offset() {
  return dart::Function::usage_counter_offset();
}

word Function::unchecked_entry_point_offset() {
  return dart::Function::unchecked_entry_point_offset();
}

word ICData::CodeIndexFor(word num_args) {
  return dart::ICData::CodeIndexFor(num_args);
}

word ICData::owner_offset() {
  return dart::ICData::owner_offset();
}

word ICData::arguments_descriptor_offset() {
  return dart::ICData::arguments_descriptor_offset();
}

word ICData::entries_offset() {
  return dart::ICData::entries_offset();
}

word ICData::static_receiver_type_offset() {
  return dart::ICData::static_receiver_type_offset();
}

word ICData::state_bits_offset() {
  return dart::ICData::state_bits_offset();
}

word ICData::CountIndexFor(word num_args) {
  return dart::ICData::CountIndexFor(num_args);
}

word ICData::TargetIndexFor(word num_args) {
  return dart::ICData::TargetIndexFor(num_args);
}

word ICData::ExactnessOffsetFor(word num_args) {
  return dart::ICData::ExactnessOffsetFor(num_args);
}

word ICData::TestEntryLengthFor(word num_args, bool exactness_check) {
  return dart::ICData::TestEntryLengthFor(num_args, exactness_check);
}

word ICData::EntryPointIndexFor(word num_args) {
  return dart::ICData::EntryPointIndexFor(num_args);
}

word ICData::NumArgsTestedShift() {
  return dart::ICData::NumArgsTestedShift();
}

word ICData::NumArgsTestedMask() {
  return dart::ICData::NumArgsTestedMask();
}

const word MegamorphicCache::kSpreadFactor =
    dart::MegamorphicCache::kSpreadFactor;

word MegamorphicCache::mask_offset() {
  return dart::MegamorphicCache::mask_offset();
}
word MegamorphicCache::buckets_offset() {
  return dart::MegamorphicCache::buckets_offset();
}
word MegamorphicCache::arguments_descriptor_offset() {
  return dart::MegamorphicCache::arguments_descriptor_offset();
}

word SingleTargetCache::lower_limit_offset() {
  return dart::SingleTargetCache::lower_limit_offset();
}
word SingleTargetCache::upper_limit_offset() {
  return dart::SingleTargetCache::upper_limit_offset();
}
word SingleTargetCache::entry_point_offset() {
  return dart::SingleTargetCache::entry_point_offset();
}
word SingleTargetCache::target_offset() {
  return dart::SingleTargetCache::target_offset();
}

const word Array::kMaxNewSpaceElements = dart::Array::kMaxNewSpaceElements;

word Context::InstanceSize(word n) {
  return dart::Context::InstanceSize(n);
}

word Context::variable_offset(word n) {
  return dart::Context::variable_offset(n);
}

word TypedData::InstanceSize() {
  return sizeof(RawTypedData);
}

word Array::header_size() {
  return sizeof(dart::RawArray);
}

#define CLASS_NAME_LIST(V)                                                     \
  V(AbstractType, type_test_stub_entry_point_offset)                           \
  V(ArgumentsDescriptor, count_offset)                                         \
  V(ArgumentsDescriptor, type_args_len_offset)                                 \
  V(Array, data_offset)                                                        \
  V(Array, length_offset)                                                      \
  V(Array, tags_offset)                                                        \
  V(Array, type_arguments_offset)                                              \
  V(ClassTable, table_offset)                                                  \
  V(Closure, context_offset)                                                   \
  V(Closure, delayed_type_arguments_offset)                                    \
  V(Closure, function_offset)                                                  \
  V(Closure, function_type_arguments_offset)                                   \
  V(Closure, instantiator_type_arguments_offset)                               \
  V(Code, object_pool_offset)                                                  \
  V(Code, saved_instructions_offset)                                           \
  V(Context, num_variables_offset)                                             \
  V(Context, parent_offset)                                                    \
  V(Double, value_offset)                                                      \
  V(Float32x4, value_offset)                                                   \
  V(Float64x2, value_offset)                                                   \
  V(GrowableObjectArray, data_offset)                                          \
  V(GrowableObjectArray, length_offset)                                        \
  V(GrowableObjectArray, type_arguments_offset)                                \
  V(HeapPage, card_table_offset)                                               \
  V(Isolate, class_table_offset)                                               \
  V(Isolate, current_tag_offset)                                               \
  V(Isolate, default_tag_offset)                                               \
  V(Isolate, ic_miss_code_offset)                                              \
  V(Isolate, object_store_offset)                                              \
  V(Isolate, user_tag_offset)                                                  \
  V(MarkingStackBlock, pointers_offset)                                        \
  V(MarkingStackBlock, top_offset)                                             \
  V(Mint, value_offset)                                                        \
  V(NativeArguments, argc_tag_offset)                                          \
  V(NativeArguments, argv_offset)                                              \
  V(NativeArguments, retval_offset)                                            \
  V(NativeArguments, thread_offset)                                            \
  V(ObjectStore, double_type_offset)                                           \
  V(ObjectStore, int_type_offset)                                              \
  V(ObjectStore, string_type_offset)                                           \
  V(OneByteString, data_offset)                                                \
  V(StoreBufferBlock, pointers_offset)                                         \
  V(StoreBufferBlock, top_offset)                                              \
  V(String, hash_offset)                                                       \
  V(String, length_offset)                                                     \
  V(SubtypeTestCache, cache_offset)                                            \
  V(Thread, active_exception_offset)                                           \
  V(Thread, active_stacktrace_offset)                                          \
  V(Thread, async_stack_trace_offset)                                          \
  V(Thread, auto_scope_native_wrapper_entry_point_offset)                      \
  V(Thread, bool_false_offset)                                                 \
  V(Thread, bool_true_offset)                                                  \
  V(Thread, dart_stream_offset)                                                \
  V(Thread, end_offset)                                                        \
  V(Thread, global_object_pool_offset)                                         \
  V(Thread, isolate_offset)                                                    \
  V(Thread, marking_stack_block_offset)                                        \
  V(Thread, no_scope_native_wrapper_entry_point_offset)                        \
  V(Thread, object_null_offset)                                                \
  V(Thread, predefined_symbols_address_offset)                                 \
  V(Thread, resume_pc_offset)                                                  \
  V(Thread, store_buffer_block_offset)                                         \
  V(Thread, top_exit_frame_info_offset)                                        \
  V(Thread, top_offset)                                                        \
  V(Thread, top_resource_offset)                                               \
  V(Thread, vm_tag_offset)                                                     \
  V(TimelineStream, enabled_offset)                                            \
  V(TwoByteString, data_offset)                                                \
  V(Type, arguments_offset)                                                    \
  V(TypedData, data_offset)                                                    \
  V(TypedData, length_offset)                                                  \
  V(Type, hash_offset)                                                         \
  V(TypeRef, type_offset)                                                      \
  V(Type, signature_offset)                                                    \
  V(Type, type_state_offset)                                                   \
  V(UserTag, tag_offset)

#define DEFINE_FORWARDER(clazz, name)                                          \
  word clazz::name() { return dart::clazz::name(); }

CLASS_NAME_LIST(DEFINE_FORWARDER)
#undef DEFINE_FORWARDER

const word HeapPage::kBytesPerCardLog2 = dart::HeapPage::kBytesPerCardLog2;

const word String::kHashBits = dart::String::kHashBits;

word String::InstanceSize() {
  return sizeof(dart::RawString);
}

bool Heap::IsAllocatableInNewSpace(intptr_t instance_size) {
  return dart::Heap::IsAllocatableInNewSpace(instance_size);
}

#if !defined(TARGET_ARCH_DBC)
word Thread::write_barrier_code_offset() {
  return dart::Thread::write_barrier_code_offset();
}

word Thread::array_write_barrier_code_offset() {
  return dart::Thread::array_write_barrier_code_offset();
}

word Thread::fix_callers_target_code_offset() {
  return dart::Thread::fix_callers_target_code_offset();
}

word Thread::fix_allocation_stub_code_offset() {
  return dart::Thread::fix_allocation_stub_code_offset();
}

word Thread::call_to_runtime_entry_point_offset() {
  return dart::Thread::call_to_runtime_entry_point_offset();
}

word Thread::null_error_shared_with_fpu_regs_entry_point_offset() {
  return dart::Thread::null_error_shared_with_fpu_regs_entry_point_offset();
}

word Thread::null_error_shared_without_fpu_regs_entry_point_offset() {
  return dart::Thread::null_error_shared_without_fpu_regs_entry_point_offset();
}

word Thread::monomorphic_miss_entry_offset() {
  return dart::Thread::monomorphic_miss_entry_offset();
}

word Thread::write_barrier_mask_offset() {
  return dart::Thread::write_barrier_mask_offset();
}

word Thread::write_barrier_entry_point_offset() {
  return dart::Thread::write_barrier_entry_point_offset();
}

word Thread::array_write_barrier_entry_point_offset() {
  return dart::Thread::array_write_barrier_entry_point_offset();
}
#endif  // !defined(TARGET_ARCH_DBC)

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64) ||                  \
    defined(TARGET_ARCH_X64)
word Thread::write_barrier_wrappers_thread_offset(intptr_t regno) {
  return dart::Thread::write_barrier_wrappers_thread_offset(
      static_cast<Register>(regno));
}
#endif

#if !defined(TARGET_ARCH_DBC)

word Thread::monomorphic_miss_stub_offset() {
  return dart::Thread::monomorphic_miss_stub_offset();
}

word Thread::ic_lookup_through_code_stub_offset() {
  return dart::Thread::ic_lookup_through_code_stub_offset();
}

word Thread::lazy_specialize_type_test_stub_offset() {
  return dart::Thread::lazy_specialize_type_test_stub_offset();
}

word Thread::slow_type_test_stub_offset() {
  return dart::Thread::slow_type_test_stub_offset();
}

word Thread::call_to_runtime_stub_offset() {
  return dart::Thread::call_to_runtime_stub_offset();
}

word Thread::invoke_dart_code_stub_offset() {
  return dart::Thread::invoke_dart_code_stub_offset();
}

word Thread::interpret_call_entry_point_offset() {
  return dart::Thread::interpret_call_entry_point_offset();
}

word Thread::invoke_dart_code_from_bytecode_stub_offset() {
  return dart::Thread::invoke_dart_code_from_bytecode_stub_offset();
}

word Thread::null_error_shared_without_fpu_regs_stub_offset() {
  return dart::Thread::null_error_shared_without_fpu_regs_stub_offset();
}

word Thread::null_error_shared_with_fpu_regs_stub_offset() {
  return dart::Thread::null_error_shared_with_fpu_regs_stub_offset();
}

word Thread::stack_overflow_shared_without_fpu_regs_stub_offset() {
  return dart::Thread::stack_overflow_shared_without_fpu_regs_stub_offset();
}

word Thread::stack_overflow_shared_with_fpu_regs_stub_offset() {
  return dart::Thread::stack_overflow_shared_with_fpu_regs_stub_offset();
}

word Thread::lazy_deopt_from_return_stub_offset() {
  return dart::Thread::lazy_deopt_from_return_stub_offset();
}

word Thread::lazy_deopt_from_throw_stub_offset() {
  return dart::Thread::lazy_deopt_from_throw_stub_offset();
}

word Thread::deoptimize_stub_offset() {
  return dart::Thread::deoptimize_stub_offset();
}

#endif  // !defined(TARGET_ARCH_DBC)

#define DECLARE_CONSTANT_OFFSET_GETTER(name)                                   \
  word Thread::name##_address_offset() {                                       \
    return dart::Thread::name##_address_offset();                              \
  }
THREAD_XMM_CONSTANT_LIST(DECLARE_CONSTANT_OFFSET_GETTER)
#undef DECLARE_CONSTANT_OFFSET_GETTER

word Thread::OffsetFromThread(const dart::Object& object) {
  return dart::Thread::OffsetFromThread(object);
}

const word StoreBufferBlock::kSize = dart::StoreBufferBlock::kSize;

const word MarkingStackBlock::kSize = dart::MarkingStackBlock::kSize;

#if !defined(PRODUCT)
word Isolate::single_step_offset() {
  return dart::Isolate::single_step_offset();
}
#endif  // !defined(PRODUCT)

#if !defined(PRODUCT)
word ClassTable::ClassOffsetFor(intptr_t cid) {
  return dart::ClassTable::ClassOffsetFor(cid);
}

word ClassTable::StateOffsetFor(intptr_t cid) {
  return dart::ClassTable::StateOffsetFor(cid);
}

word ClassTable::TableOffsetFor(intptr_t cid) {
  return dart::ClassTable::TableOffsetFor(cid);
}

word ClassTable::CounterOffsetFor(intptr_t cid, bool is_new) {
  return dart::ClassTable::CounterOffsetFor(cid, is_new);
}

word ClassTable::SizeOffsetFor(intptr_t cid, bool is_new) {
  return dart::ClassTable::SizeOffsetFor(cid, is_new);
}
#endif  // !defined(PRODUCT)

const word ClassTable::kSizeOfClassPairLog2 = dart::kSizeOfClassPairLog2;

const intptr_t Instructions::kPolymorphicEntryOffset =
    dart::Instructions::kPolymorphicEntryOffset;

const intptr_t Instructions::kMonomorphicEntryOffset =
    dart::Instructions::kMonomorphicEntryOffset;

intptr_t Instructions::HeaderSize() {
  return dart::Instructions::HeaderSize();
}

intptr_t Code::entry_point_offset(CodeEntryKind kind) {
  return dart::Code::entry_point_offset(kind);
}

const word SubtypeTestCache::kTestEntryLength =
    dart::SubtypeTestCache::kTestEntryLength;
const word SubtypeTestCache::kInstanceClassIdOrFunction =
    dart::SubtypeTestCache::kInstanceClassIdOrFunction;
const word SubtypeTestCache::kInstanceTypeArguments =
    dart::SubtypeTestCache::kInstanceTypeArguments;
const word SubtypeTestCache::kInstantiatorTypeArguments =
    dart::SubtypeTestCache::kInstantiatorTypeArguments;
const word SubtypeTestCache::kFunctionTypeArguments =
    dart::SubtypeTestCache::kFunctionTypeArguments;
const word SubtypeTestCache::kInstanceParentFunctionTypeArguments =
    dart::SubtypeTestCache::kInstanceParentFunctionTypeArguments;
const word SubtypeTestCache::kInstanceDelayedFunctionTypeArguments =
    dart::SubtypeTestCache::kInstanceDelayedFunctionTypeArguments;
const word SubtypeTestCache::kTestResult = dart::SubtypeTestCache::kTestResult;

word Context::header_size() {
  return sizeof(dart::RawContext);
}

#if !defined(PRODUCT)
word ClassHeapStats::TraceAllocationMask() {
  return dart::ClassHeapStats::TraceAllocationMask();
}

word ClassHeapStats::state_offset() {
  return dart::ClassHeapStats::state_offset();
}

word ClassHeapStats::allocated_since_gc_new_space_offset() {
  return dart::ClassHeapStats::allocated_since_gc_new_space_offset();
}

word ClassHeapStats::allocated_size_since_gc_new_space_offset() {
  return dart::ClassHeapStats::allocated_size_since_gc_new_space_offset();
}
#endif  // !defined(PRODUCT)

const word Smi::kBits = dart::Smi::kBits;
bool IsSmi(const dart::Object& a) {
  return a.IsSmi();
}

word ToRawSmi(const dart::Object& a) {
  ASSERT(a.IsSmi());
  return reinterpret_cast<word>(a.raw());
}

word ToRawSmi(intptr_t value) {
  return dart::Smi::RawValue(value);
}

bool CanLoadFromThread(const dart::Object& object,
                       word* offset /* = nullptr */) {
  if (dart::Thread::CanLoadFromThread(object)) {
    if (offset != nullptr) {
      *offset = dart::Thread::OffsetFromThread(object);
    }
    return true;
  }
  return false;
}

#if defined(TARGET_ARCH_IA32)
uword Code::EntryPointOf(const dart::Code& code) {
  static_assert(kHostWordSize == kWordSize,
                "Can't embed raw pointers to runtime objects when host and "
                "target word sizes are different");
  return code.EntryPoint();
}

bool CanEmbedAsRawPointerInGeneratedCode(const dart::Object& obj) {
  return obj.IsSmi() || obj.IsReadOnly();
}

word ToRawPointer(const dart::Object& a) {
  static_assert(kHostWordSize == kWordSize,
                "Can't embed raw pointers to runtime objects when host and "
                "target word sizes are different");
  return reinterpret_cast<word>(a.raw());
}
#endif  // defined(TARGET_ARCH_IA32)

const word NativeEntry::kNumCallWrapperArguments =
    dart::NativeEntry::kNumCallWrapperArguments;

word NativeArguments::StructSize() {
  return sizeof(dart::NativeArguments);
}

word RegExp::function_offset(classid_t cid, bool sticky) {
  return dart::RegExp::function_offset(cid, sticky);
}

const word Symbols::kNumberOfOneCharCodeSymbols =
    dart::Symbols::kNumberOfOneCharCodeSymbols;
const word Symbols::kNullCharCodeSymbolOffset =
    dart::Symbols::kNullCharCodeSymbolOffset;

}  // namespace target
}  // namespace compiler
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
