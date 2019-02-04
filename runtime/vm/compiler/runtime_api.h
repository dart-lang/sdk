// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_RUNTIME_API_H_
#define RUNTIME_VM_COMPILER_RUNTIME_API_H_

// This header defines the API that compiler can use to interact with the
// underlying Dart runtime that it is embedded into.
//
// Compiler is not allowed to directly interact with any objects - it can only
// use classes like dart::Object, dart::Code, dart::Function and similar as
// opaque handles. All interactions should be done through helper methods
// provided by this header.
//
// This header also provides ways to get word sizes, frame layout, field
// offsets for the target runtime. Note that these can be different from
// those on the host. Helpers providing access to these values live
// in compiler::target namespace.

#include "platform/globals.h"
#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/code_entry_kind.h"
#include "vm/frame_layout.h"
#include "vm/pointer_tagging.h"

namespace dart {

// Forward declarations.
class Class;
class Code;
class Function;
class LocalVariable;
class Object;
class String;
class Zone;
namespace compiler {
class Assembler;
}

namespace compiler {

// Host word sizes.
//
// Code in the compiler namespace should not use kWordSize and derived
// constants directly because the word size on host and target might
// be different.
//
// To prevent this we introduce variables that would shadow these
// constants and introduce compilation errors when used.
//
// target::kWordSize and target::ObjectAlignment give access to
// word size and object aligment offsets for the target.
//
// Similarly kHostWordSize gives access to the host word size.
class InvalidClass {};
extern InvalidClass kWordSize;
extern InvalidClass kWordSizeLog2;
extern InvalidClass kNewObjectAlignmentOffset;
extern InvalidClass kOldObjectAlignmentOffset;
extern InvalidClass kNewObjectBitPosition;
extern InvalidClass kObjectAlignment;
extern InvalidClass kObjectAlignmentLog2;
extern InvalidClass kObjectAlignmentMask;

static constexpr intptr_t kHostWordSize = dart::kWordSize;
static constexpr intptr_t kHostWordSizeLog2 = dart::kWordSizeLog2;

//
// Object handles.
//

// Create an empty handle.
Object& NewZoneHandle(Zone* zone);

// Clone the given handle.
Object& NewZoneHandle(Zone* zone, const Object&);

// Returns true if [a] and [b] are the same object.
bool IsSameObject(const Object& a, const Object& b);

// Returns true if the given handle is a zone handle or one of the global
// cached handles.
bool IsNotTemporaryScopedHandle(const Object& obj);

// Returns true if [obj] resides in old space.
bool IsInOldSpace(const Object& obj);

// Returns true if [obj] is not a Field/ICData clone.
//
// Used to assert that we are not embedding pointers to cloned objects that are
// used by background compiler into object pools / code.
bool IsOriginalObject(const Object& object);

// Clear the given handle.
void SetToNull(Object* obj);

// Helper functions to upcast handles.
//
// Note: compiler code cannot include object.h so it cannot see that Object is
// a superclass of Code or Function - thus we have to cast these pointers using
// reinterpret_cast.
inline const Object& ToObject(const Code& handle) {
  return *reinterpret_cast<const Object*>(&handle);
}

inline const Object& ToObject(const Function& handle) {
  return *reinterpret_cast<const Object*>(&handle);
}

// Returns some hash value for the given object.
//
// Note: the given hash value does not necessarily match Object.get:hashCode,
// or canonical hash.
intptr_t ObjectHash(const Object& obj);

// If the given object represents a Dart integer returns true and sets [value]
// to the value of the integer.
bool HasIntegerValue(const dart::Object& obj, int64_t* value);

// Creates a random cookie to be used for masking constants embedded in the
// generated code.
int32_t CreateJitCookie();

class RuntimeEntry : public ValueObject {
 public:
  virtual ~RuntimeEntry() {}
  virtual void Call(compiler::Assembler* assembler,
                    intptr_t argument_count) const = 0;
};

// Allocate a string object with the given content in the runtime heap.
const String& AllocateString(const char* buffer);

DART_NORETURN void BailoutWithBranchOffsetError();

// compiler::target namespace contains information about the target platform:
//
//    - word sizes and derived constants
//    - offsets of fields
//    - sizes of structures
namespace target {

// Currently we define target::word to match dart::word which represents
// host word.
//
// Once refactoring of the compiler is complete we will switch target::word
// to be independent from host word.
typedef dart::word word;
typedef dart::uword uword;

static constexpr word kWordSize = dart::kWordSize;
static constexpr word kWordSizeLog2 = dart::kWordSizeLog2;
static_assert((1 << kWordSizeLog2) == kWordSize,
              "kWordSizeLog2 should match kWordSize");

using ObjectAlignment = dart::ObjectAlignment<kWordSize, kWordSizeLog2>;

// Information about frame_layout that compiler should be targeting.
extern FrameLayout frame_layout;

// Returns the FP-relative index where [variable] can be found (assumes
// [variable] is not captured), in bytes.
inline int FrameOffsetInBytesForVariable(const LocalVariable* variable) {
  return frame_layout.FrameSlotForVariable(variable) * kWordSize;
}

// Encode tag word for a heap allocated object with the given class id and
// size.
//
// Note: even on 64-bit platforms we only use lower 32-bits of the tag word.
uint32_t MakeTagWordForNewSpaceObject(classid_t cid, uword instance_size);

//
// Target specific information about objects.
//

// Returns true if the given object can be represented as a Smi on the
// target platform.
bool IsSmi(const dart::Object& a);

// Return raw Smi representation of the given object for the target platform.
word ToRawSmi(const dart::Object& a);

// Return raw Smi representation of the given integer value for the target
// platform.
//
// Note: method assumes that caller has validated that value is representable
// as a Smi.
word ToRawSmi(intptr_t value);

// If the given object can be loaded from the thread on the target then
// return true and set offset (if provided) to the offset from the
// thread pointer to a field that contains the object.
bool CanLoadFromThread(const dart::Object& object, word* offset = nullptr);

// On IA32 we can embed raw pointers into generated code.
#if defined(TARGET_ARCH_IA32)
// Returns true if the pointer to the given object can be directly embedded
// into the generated code (because the object is immortal and immovable).
bool CanEmbedAsRawPointerInGeneratedCode(const dart::Object& obj);

// Returns raw pointer value for the given object. Should only be invoked
// if CanEmbedAsRawPointerInGeneratedCode returns true.
word ToRawPointer(const dart::Object& a);
#endif  // defined(TARGET_ARCH_IA32)

//
// Target specific offsets and constants.
//
// Currently we use the same names for classes, constants and getters to make
// migration easier.

class RawObject : public AllStatic {
 public:
  static const word kClassIdTagPos;
  static const word kClassIdTagSize;
  static const word kBarrierOverlapShift;
};

class Object : public AllStatic {
 public:
  // Offset of the tags word.
  static word tags_offset();
};

class ObjectPool : public AllStatic {
 public:
  // Return offset to the element with the given [index] in the object pool.
  static intptr_t element_offset(intptr_t index);
};

class Class : public AllStatic {
 public:
  // Return class id of the given class on the target.
  static classid_t GetId(const dart::Class& handle);

  // Return instance size for the given class on the target.
  static uword GetInstanceSize(const dart::Class& handle);
};

class Instance : public AllStatic {
 public:
  static word DataOffsetFor(intptr_t cid);
};

class Double : public AllStatic {
 public:
  static word value_offset();
};

class Float32x4 : public AllStatic {
 public:
  static word value_offset();
};

class Float64x2 : public AllStatic {
 public:
  static word value_offset();
};

class Thread : public AllStatic {
 public:
  static word top_offset();
  static word end_offset();
  static word isolate_offset();
  static word call_to_runtime_entry_point_offset();
  static word null_error_shared_with_fpu_regs_entry_point_offset();
  static word null_error_shared_without_fpu_regs_entry_point_offset();
  static word write_barrier_mask_offset();
  static word monomorphic_miss_entry_offset();
  static word write_barrier_wrappers_thread_offset(intptr_t regno);
  static word array_write_barrier_entry_point_offset();
  static word write_barrier_entry_point_offset();
  static word vm_tag_offset();

#define THREAD_XMM_CONSTANT_LIST(V)                                            \
  V(float_not)                                                                 \
  V(float_negate)                                                              \
  V(float_absolute)                                                            \
  V(float_zerow)                                                               \
  V(double_negate)                                                             \
  V(double_abs)

#define DECLARE_CONSTANT_OFFSET_GETTER(name)                                   \
  static word name##_address_offset();
  THREAD_XMM_CONSTANT_LIST(DECLARE_CONSTANT_OFFSET_GETTER)
#undef DECLARE_CONSTANT_OFFSET_GETTER
};

class Isolate : public AllStatic {
 public:
  static word class_table_offset();
};

class ClassTable : public AllStatic {
 public:
  static word table_offset();
#if !defined(PRODUCT)
  static word ClassOffsetFor(intptr_t cid);
  static word StateOffsetFor(intptr_t cid);
  static word TableOffsetFor(intptr_t cid);
  static word CounterOffsetFor(intptr_t cid, bool is_new);
  static word SizeOffsetFor(intptr_t cid, bool is_new);
#endif  // !defined(PRODUCT)
  static const word kSizeOfClassPairLog2;
};

#if !defined(PRODUCT)
class ClassHeapStats : public AllStatic {
 public:
  static word TraceAllocationMask();
  static word state_offset();
  static word allocated_since_gc_new_space_offset();
  static word allocated_size_since_gc_new_space_offset();
};
#endif  // !defined(PRODUCT)

class Instructions : public AllStatic {
 public:
  static const intptr_t kPolymorphicEntryOffset;
  static const intptr_t kMonomorphicEntryOffset;
  static intptr_t HeaderSize();
};

class Code : public AllStatic {
 public:
#if defined(TARGET_ARCH_IA32)
  static uword EntryPointOf(const dart::Code& code);
#endif  // defined(TARGET_ARCH_IA32)

  static intptr_t object_pool_offset();
  static intptr_t entry_point_offset(
      CodeEntryKind kind = CodeEntryKind::kNormal);
  static intptr_t saved_instructions_offset();
};

class Heap : public AllStatic {
 public:
  // Return true if an object with the given instance size is allocatable
  // in new space on the target.
  static bool IsAllocatableInNewSpace(intptr_t instance_size);
};

}  // namespace target
}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_RUNTIME_API_H_
