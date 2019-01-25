// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/longjump.h"
#include "vm/object.h"

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

bool IsOriginalObject(const Object& object) {
  if (object.IsICData()) {
    return ICData::Cast(object).IsOriginal();
  } else if (object.IsField()) {
    return Field::Cast(object).IsOriginal();
  }
  return true;
}

const String& AllocateString(const char* buffer) {
  return String::ZoneHandle(String::New(buffer));
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

void BailoutWithBranchOffsetError() {
  Thread::Current()->long_jump_base()->Jump(1, Object::branch_offset_error());
}

namespace target {

uint32_t MakeTagWordForNewSpaceObject(classid_t cid, uword instance_size) {
  return dart::RawObject::SizeTag::encode(instance_size) |
         dart::RawObject::ClassIdTag::encode(cid) |
         dart::RawObject::NewBit::encode(true);
}

word Object::tags_offset() {
  return dart::Object::tags_offset();
}

const word RawObject::kClassIdTagPos = dart::RawObject::kClassIdTagPos;

const word RawObject::kClassIdTagSize = dart::RawObject::kClassIdTagSize;

const word RawObject::kBarrierOverlapShift =
    dart::RawObject::kBarrierOverlapShift;

intptr_t ObjectPool::element_offset(intptr_t index) {
  return dart::ObjectPool::element_offset(index);
}

classid_t Class::GetId(const dart::Class& handle) {
  return handle.id();
}

uword Class::GetInstanceSize(const dart::Class& handle) {
  return handle.instance_size();
}

word Instance::DataOffsetFor(intptr_t cid) {
  return dart::Instance::DataOffsetFor(cid);
}

bool Heap::IsAllocatableInNewSpace(intptr_t instance_size) {
  return dart::Heap::IsAllocatableInNewSpace(instance_size);
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

#if !defined(TARGET_ARCH_DBC)
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

#define DECLARE_CONSTANT_OFFSET_GETTER(name)                                   \
  word Thread::name##_address_offset() {                                       \
    return dart::Thread::name##_address_offset();                              \
  }
THREAD_XMM_CONSTANT_LIST(DECLARE_CONSTANT_OFFSET_GETTER)
#undef DECLARE_CONSTANT_OFFSET_GETTER

word Isolate::class_table_offset() {
  return dart::Isolate::class_table_offset();
}

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

}  // namespace target
}  // namespace compiler
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
