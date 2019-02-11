// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/dart_entry.h"
#include "vm/longjump.h"
#include "vm/native_arguments.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"

namespace dart {
namespace compiler {

bool IsSameObject(const Object& a, const Object& b) {
  return a.raw() == b.raw();
}

bool IsNotTemporaryScopedHandle(const Object& obj) {
  return obj.IsNotTemporaryScopedHandle();
}

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

word ICData::ic_data_offset() {
  return dart::ICData::ic_data_offset();
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

word Array::header_size() {
  return sizeof(dart::RawArray);
}

word Array::tags_offset() {
  return dart::Array::tags_offset();
}

word Array::data_offset() {
  return dart::Array::data_offset();
}

word Array::type_arguments_offset() {
  return dart::Array::type_arguments_offset();
}

word Array::length_offset() {
  return dart::Array::length_offset();
}

const word Array::kMaxNewSpaceElements = dart::Array::kMaxNewSpaceElements;

word ArgumentsDescriptor::count_offset() {
  return dart::ArgumentsDescriptor::count_offset();
}

word ArgumentsDescriptor::type_args_len_offset() {
  return dart::ArgumentsDescriptor::type_args_len_offset();
}

word AbstractType::type_test_stub_entry_point_offset() {
  return dart::AbstractType::type_test_stub_entry_point_offset();
}

word Type::type_state_offset() {
  return dart::Type::type_state_offset();
}

word Type::arguments_offset() {
  return dart::Type::arguments_offset();
}

word Type::signature_offset() {
  return dart::Type::signature_offset();
}

word TypeRef::type_offset() {
  return dart::TypeRef::type_offset();
}

const word HeapPage::kBytesPerCardLog2 = dart::HeapPage::kBytesPerCardLog2;

word HeapPage::card_table_offset() {
  return dart::HeapPage::card_table_offset();
}

bool Heap::IsAllocatableInNewSpace(intptr_t instance_size) {
  return dart::Heap::IsAllocatableInNewSpace(instance_size);
}

word Thread::active_exception_offset() {
  return dart::Thread::active_exception_offset();
}

word Thread::active_stacktrace_offset() {
  return dart::Thread::active_stacktrace_offset();
}

word Thread::resume_pc_offset() {
  return dart::Thread::resume_pc_offset();
}

word Thread::marking_stack_block_offset() {
  return dart::Thread::marking_stack_block_offset();
}

word Thread::top_exit_frame_info_offset() {
  return dart::Thread::top_exit_frame_info_offset();
}

word Thread::top_resource_offset() {
  return dart::Thread::top_resource_offset();
}

word Thread::global_object_pool_offset() {
  return dart::Thread::global_object_pool_offset();
}

word Thread::object_null_offset() {
  return dart::Thread::object_null_offset();
}

word Thread::bool_true_offset() {
  return dart::Thread::bool_true_offset();
}

word Thread::bool_false_offset() {
  return dart::Thread::bool_false_offset();
}

word Thread::top_offset() {
  return dart::Thread::top_offset();
}

word Thread::end_offset() {
  return dart::Thread::end_offset();
}

word Thread::isolate_offset() {
  return dart::Thread::isolate_offset();
}

word Thread::store_buffer_block_offset() {
  return dart::Thread::store_buffer_block_offset();
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

word Thread::vm_tag_offset() {
  return dart::Thread::vm_tag_offset();
}

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

word Thread::no_scope_native_wrapper_entry_point_offset() {
  return dart::Thread::no_scope_native_wrapper_entry_point_offset();
}

word Thread::auto_scope_native_wrapper_entry_point_offset() {
  return dart::Thread::auto_scope_native_wrapper_entry_point_offset();
}

#define DECLARE_CONSTANT_OFFSET_GETTER(name)                                   \
  word Thread::name##_address_offset() {                                       \
    return dart::Thread::name##_address_offset();                              \
  }
THREAD_XMM_CONSTANT_LIST(DECLARE_CONSTANT_OFFSET_GETTER)
#undef DECLARE_CONSTANT_OFFSET_GETTER

word Thread::OffsetFromThread(const dart::Object& object) {
  return dart::Thread::OffsetFromThread(object);
}

uword StoreBufferBlock::top_offset() {
  return dart::StoreBufferBlock::top_offset();
}
uword StoreBufferBlock::pointers_offset() {
  return dart::StoreBufferBlock::pointers_offset();
}
const word StoreBufferBlock::kSize = dart::StoreBufferBlock::kSize;

uword MarkingStackBlock::top_offset() {
  return dart::MarkingStackBlock::top_offset();
}
uword MarkingStackBlock::pointers_offset() {
  return dart::MarkingStackBlock::pointers_offset();
}
const word MarkingStackBlock::kSize = dart::MarkingStackBlock::kSize;

word Isolate::class_table_offset() {
  return dart::Isolate::class_table_offset();
}

word Isolate::ic_miss_code_offset() {
  return dart::Isolate::ic_miss_code_offset();
}

#if !defined(PRODUCT)
word Isolate::single_step_offset() {
  return dart::Isolate::single_step_offset();
}
#endif  // !defined(PRODUCT)

word ClassTable::table_offset() {
  return dart::ClassTable::table_offset();
}

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

intptr_t Code::object_pool_offset() {
  return dart::Code::object_pool_offset();
}

intptr_t Code::saved_instructions_offset() {
  return dart::Code::saved_instructions_offset();
}

intptr_t Code::entry_point_offset(CodeEntryKind kind) {
  return dart::Code::entry_point_offset(kind);
}

word SubtypeTestCache::cache_offset() {
  return dart::SubtypeTestCache::cache_offset();
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

word Context::parent_offset() {
  return dart::Context::parent_offset();
}

word Context::num_variables_offset() {
  return dart::Context::num_variables_offset();
}

word Context::variable_offset(word i) {
  return dart::Context::variable_offset(i);
}

word Context::InstanceSize(word n) {
  return dart::Context::InstanceSize(n);
}

word Closure::context_offset() {
  return dart::Closure::context_offset();
}

word Closure::delayed_type_arguments_offset() {
  return dart::Closure::delayed_type_arguments_offset();
}

word Closure::function_offset() {
  return dart::Closure::function_offset();
}

word Closure::function_type_arguments_offset() {
  return dart::Closure::function_type_arguments_offset();
}

word Closure::instantiator_type_arguments_offset() {
  return dart::Closure::instantiator_type_arguments_offset();
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

word Double::value_offset() {
  return dart::Double::value_offset();
}

word Mint::value_offset() {
  return dart::Mint::value_offset();
}

word Float32x4::value_offset() {
  return dart::Float32x4::value_offset();
}

word Float64x2::value_offset() {
  return dart::Float64x2::value_offset();
}

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
  return obj.IsSmi() || obj.InVMHeap();
}

word ToRawPointer(const dart::Object& a) {
  static_assert(kHostWordSize == kWordSize,
                "Can't embed raw pointers to runtime objects when host and "
                "target word sizes are different");
  return reinterpret_cast<word>(a.raw());
}
#endif  // defined(TARGET_ARCH_IA32)

word NativeArguments::thread_offset() {
  return dart::NativeArguments::thread_offset();
}

word NativeArguments::argc_tag_offset() {
  return dart::NativeArguments::argc_tag_offset();
}

word NativeArguments::argv_offset() {
  return dart::NativeArguments::argv_offset();
}

word NativeArguments::retval_offset() {
  return dart::NativeArguments::retval_offset();
}

word NativeArguments::StructSize() {
  return sizeof(dart::NativeArguments);
}

}  // namespace target
}  // namespace compiler
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
