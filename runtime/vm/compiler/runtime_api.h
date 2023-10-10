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
#include "platform/thread_sanitizer.h"
#include "platform/utils.h"

#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/bss_relocs.h"
#include "vm/class_id.h"
#include "vm/code_entry_kind.h"
#include "vm/constants.h"
#include "vm/frame_layout.h"
#include "vm/pointer_tagging.h"
#include "vm/runtime_entry_list.h"
#include "vm/token.h"

namespace dart {

// Forward declarations.
class LocalVariable;
class Object;
class RuntimeEntry;
class Zone;

#define DO(clazz)                                                              \
  class Untagged##clazz;                                                       \
  class clazz;
CLASS_LIST_FOR_HANDLES(DO)
#undef DO

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
// word size and object alignment offsets for the target.
//
// Similarly kHostWordSize gives access to the host word size.
class InvalidClass {};
extern InvalidClass kWordSize;
extern InvalidClass kWordSizeLog2;
extern InvalidClass kBitsPerWord;
extern InvalidClass kBitsPerWordLog2;
extern InvalidClass kWordMin;
extern InvalidClass kWordMax;
extern InvalidClass kUWordMax;
extern InvalidClass kNewObjectAlignmentOffset;
extern InvalidClass kOldObjectAlignmentOffset;
extern InvalidClass kNewObjectBitPosition;
extern InvalidClass kPageSize;
extern InvalidClass kPageSizeInWords;
extern InvalidClass kPageMask;
extern InvalidClass kObjectAlignment;
extern InvalidClass kObjectAlignmentLog2;
extern InvalidClass kObjectAlignmentMask;
extern InvalidClass kSmiBits;
extern InvalidClass kSmiMin;
extern InvalidClass kSmiMax;

static constexpr intptr_t kHostWordSize = dart::kWordSize;
static constexpr intptr_t kHostWordSizeLog2 = dart::kWordSizeLog2;

//
// Object handles.
//

// Create an empty handle.
Object& NewZoneHandle(Zone* zone);

// Clone the given handle.
Object& NewZoneHandle(Zone* zone, const Object&);

//
// Constant objects.
//

const Object& NullObject();
const Object& SentinelObject();
const Bool& TrueObject();
const Bool& FalseObject();
const Object& EmptyTypeArguments();
const Type& DynamicType();
const Type& ObjectType();
const Type& VoidType();
const Type& IntType();
const Class& GrowableObjectArrayClass();
const Class& MintClass();
const Class& DoubleClass();
const Class& Float32x4Class();
const Class& Float64x2Class();
const Class& Int32x4Class();
const Class& ClosureClass();
const Array& ArgumentsDescriptorBoxed(intptr_t type_args_len,
                                      intptr_t num_arguments);

template <typename To, typename From>
const To& CastHandle(const From& from) {
  return reinterpret_cast<const To&>(from);
}

// Returns true if [a] and [b] are the same object.
bool IsSameObject(const Object& a, const Object& b);

// Returns true if [a] and [b] represent the same type (are equal).
bool IsEqualType(const AbstractType& a, const AbstractType& b);

// Returns true if [type] is a subtype of the "int" type (_Smi, _Mint, int or
// _IntegerImplementation).
bool IsSubtypeOfInt(const AbstractType& type);

// Returns true if [type] is the "double" type.
bool IsDoubleType(const AbstractType& type);

// Returns true if [type] is the "double" type.
bool IsBoolType(const AbstractType& type);

// Returns true if [type] is the "_Smi" type.
bool IsSmiType(const AbstractType& type);

#if defined(DEBUG)
// Returns true if the given handle is a zone handle or one of the global
// cached handles.
bool IsNotTemporaryScopedHandle(const Object& obj);
#endif

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

// Prints the given object into a C string.
const char* ObjectToCString(const Object& obj);

// If the given object represents a Dart integer returns true and sets [value]
// to the value of the integer.
bool HasIntegerValue(const dart::Object& obj, int64_t* value);

// Creates a random cookie to be used for masking constants embedded in the
// generated code.
int32_t CreateJitCookie();

// Returns the size in bytes for the given class id.
word TypedDataElementSizeInBytes(classid_t cid);

// Returns the size in bytes for the given class id.
word TypedDataMaxNewSpaceElements(classid_t cid);

// Looks up the dart:math's _Random._A field.
const Field& LookupMathRandomStateFieldOffset();

// Looks up the dart:convert's _Utf8Decoder._scanFlags field.
const Field& LookupConvertUtf8DecoderScanFlagsField();

// Returns the offset in bytes of [field].
word LookupFieldOffsetInBytes(const Field& field);

#if defined(TARGET_ARCH_IA32)
uword SymbolsPredefinedAddress();
#endif

const Code& StubCodeAllocateArray();
const Code& StubCodeSubtype2TestCache();
const Code& StubCodeSubtype3TestCache();
const Code& StubCodeSubtype4TestCache();
const Code& StubCodeSubtype6TestCache();
const Code& StubCodeSubtype7TestCache();

class RuntimeEntry : public ValueObject {
 public:
  virtual ~RuntimeEntry() {}

  word OffsetFromThread() const;

  bool is_leaf() const;
  intptr_t argument_count() const;

 protected:
  explicit RuntimeEntry(const dart::RuntimeEntry* runtime_entry)
      : runtime_entry_(runtime_entry) {}

 private:
  const dart::RuntimeEntry* runtime_entry_;
};

#define DECLARE_RUNTIME_ENTRY(name)                                            \
  extern const RuntimeEntry& k##name##RuntimeEntry;
RUNTIME_ENTRY_LIST(DECLARE_RUNTIME_ENTRY)
#undef DECLARE_RUNTIME_ENTRY

#define DECLARE_RUNTIME_ENTRY(type, name, ...)                                 \
  extern const RuntimeEntry& k##name##RuntimeEntry;
LEAF_RUNTIME_ENTRY_LIST(DECLARE_RUNTIME_ENTRY)
#undef DECLARE_RUNTIME_ENTRY

// Allocate a string object with the given content in the runtime heap.
const String& AllocateString(const char* buffer);

DART_NORETURN void BailoutWithBranchOffsetError();

// compiler::target namespace contains information about the target platform:
//
//    - word sizes and derived constants
//    - offsets of fields
//    - sizes of structures
namespace target {

#if defined(TARGET_ARCH_IS_32_BIT)
typedef int32_t word;
typedef uint32_t uword;
static constexpr int kWordSizeLog2 = 2;
#elif defined(TARGET_ARCH_IS_64_BIT)
typedef int64_t word;
typedef uint64_t uword;
static constexpr int kWordSizeLog2 = 3;
#else
#error "Unsupported architecture"
#endif
static constexpr int kWordSize = 1 << kWordSizeLog2;
static_assert(kWordSize == sizeof(word), "kWordSize should match sizeof(word)");
// Our compiler code currently assumes this, so formally check it.
#if !defined(FFI_UNIT_TESTS)
static_assert(dart::kWordSize >= kWordSize,
              "Host word size smaller than target word size");
#endif

#if defined(DART_COMPRESSED_POINTERS)
static constexpr int kCompressedWordSize = kInt32Size;
static constexpr int kCompressedWordSizeLog2 = kInt32SizeLog2;
#else
static constexpr int kCompressedWordSize = kWordSize;
static constexpr int kCompressedWordSizeLog2 = kWordSizeLog2;
#endif

static constexpr word kBitsPerWordLog2 = kWordSizeLog2 + kBitsPerByteLog2;
static constexpr word kBitsPerWord = 1 << kBitsPerWordLog2;

using ObjectAlignment = dart::ObjectAlignment<kWordSize, kWordSizeLog2>;

constexpr word kWordMax = (static_cast<uword>(1) << (kBitsPerWord - 1)) - 1;
constexpr word kWordMin = -(static_cast<uword>(1) << (kBitsPerWord - 1));
constexpr uword kUwordMax = static_cast<word>(-1);

// The number of bits in the _magnitude_ of a Smi, not counting the sign bit.
#if !defined(DART_COMPRESSED_POINTERS)
constexpr int kSmiBits = kBitsPerWord - 2;
#else
constexpr int kSmiBits = 30;
#endif
constexpr word kSmiMax = (static_cast<uword>(1) << kSmiBits) - 1;
constexpr word kSmiMin = -(static_cast<uword>(1) << kSmiBits);

// Information about heap pages.
extern const word kPageSize;
extern const word kPageSizeInWords;
extern const word kPageMask;

static constexpr intptr_t kObjectAlignment = ObjectAlignment::kObjectAlignment;

// Note: if other flags are added, then change the check for required parameters
// when no named arguments are provided in
// FlowGraphBuilder::BuildClosureCallHasRequiredNamedArgumentsCheck, since it
// assumes there are no flag slots when no named parameters are required.
enum ParameterFlags {
  kRequiredNamedParameterFlag,
  kNumParameterFlags,
};
// Parameter flags are stored in Smis. To ensure shifts and masks can be used to
// calculate both the parameter flag index in the parameter names array and
// which bit to check, kNumParameterFlagsPerElement should be a power of two.
static constexpr intptr_t kNumParameterFlagsPerElementLog2 =
    kBitsPerWordLog2 - 1 - kNumParameterFlags;
static constexpr intptr_t kNumParameterFlagsPerElement =
    1 << kNumParameterFlagsPerElementLog2;
static_assert(kNumParameterFlagsPerElement <= kSmiBits,
              "kNumParameterFlagsPerElement should fit in a Smi");

inline intptr_t RoundedAllocationSize(intptr_t size) {
  return Utils::RoundUp(size, kObjectAlignment);
}
// Information about frame_layout that compiler should be targeting.
extern FrameLayout frame_layout;

constexpr intptr_t kIntSpillFactor = sizeof(int64_t) / kWordSize;
constexpr intptr_t kDoubleSpillFactor = sizeof(double) / kWordSize;

// Returns the FP-relative index where [variable] can be found (assumes
// [variable] is not captured), in bytes.
inline int FrameOffsetInBytesForVariable(const LocalVariable* variable) {
  return frame_layout.FrameSlotForVariable(variable) * kWordSize;
}

// Check whether instance_size is small enough to be encoded in the size tag.
bool SizeFitsInSizeTag(uword instance_size);

// Encode tag word for a heap allocated object with the given class id and
// size.
//
// Note: even on 64-bit platforms we only use lower 32-bits of the tag word.
uword MakeTagWordForNewSpaceObject(classid_t cid, uword instance_size);

//
// Target specific information about objects.
//

// Returns true if the given object can be represented as a Smi on the target
// platform.
bool IsSmi(const dart::Object& a);

// Returns true if the given value can be represented as a Smi on the target
// platform.
bool IsSmi(int64_t value);

// Return raw Smi representation of the given object for the target platform.
word ToRawSmi(const dart::Object& a);

// Return raw Smi representation of the given integer value for the target
// platform.
//
// Note: method assumes that caller has validated that value is representable
// as a Smi.
word ToRawSmi(intptr_t value);

word SmiValue(const dart::Object& a);

bool IsDouble(const dart::Object& a);
double DoubleValue(const dart::Object& a);

// If the given object can be loaded from the thread on the target then
// return true and set offset (if provided) to the offset from the
// thread pointer to a field that contains the object.
bool CanLoadFromThread(const dart::Object& object, intptr_t* offset = nullptr);

// On IA32 we can embed raw pointers into generated code.
#if defined(TARGET_ARCH_IA32)
// Returns true if the pointer to the given object can be directly embedded
// into the generated code (because the object is immortal and immovable).
bool CanEmbedAsRawPointerInGeneratedCode(const dart::Object& obj);

// Returns raw pointer value for the given object. Should only be invoked
// if CanEmbedAsRawPointerInGeneratedCode returns true.
word ToRawPointer(const dart::Object& a);
#endif  // defined(TARGET_ARCH_IA32)

bool WillAllocateNewOrRememberedObject(intptr_t instance_size);

bool WillAllocateNewOrRememberedContext(intptr_t num_context_variables);

bool WillAllocateNewOrRememberedArray(intptr_t length);

#define FINAL_CLASS()                                                          \
  static word NextFieldOffset() { return -kWordSize; }

//
// Target specific offsets and constants.
//
// Currently we use the same names for classes, constants and getters to make
// migration easier.

class UntaggedObject : public AllStatic {
 public:
  static const word kCardRememberedBit;
  static const word kCanonicalBit;
  static const word kNewBit;
  static const word kOldAndNotRememberedBit;
  static const word kNotMarkedBit;
  static const word kImmutableBit;
  static const word kSizeTagPos;
  static const word kSizeTagSize;
  static const word kClassIdTagPos;
  static const word kClassIdTagSize;
  static const word kHashTagPos;
  static const word kHashTagSize;
  static const word kSizeTagMaxSizeTag;
  static const word kTagBitsSizeTagPos;
  static const word kBarrierOverlapShift;
  static const word kGenerationalBarrierMask;
  static const word kIncrementalBarrierMask;

  static bool IsTypedDataClassId(intptr_t cid);
};

class UntaggedAbstractType : public AllStatic {
 public:
  static const word kTypeStateFinalizedInstantiated;
  static const word kTypeStateShift;
  static const word kTypeStateBits;
  static const word kNullabilityMask;
};

class UntaggedType : public AllStatic {
 public:
  static const word kTypeClassIdShift;
};

class UntaggedTypeParameter : public AllStatic {
 public:
  static const word kIsFunctionTypeParameterBit;
};

class Object : public AllStatic {
 public:
  // Offset of the tags word.
  static word tags_offset();
  static word InstanceSize();
};

class ObjectPool : public AllStatic {
 public:
  // Return offset to the element with the given [index] in the object pool.
  static word element_offset(intptr_t index);
  static word InstanceSize(intptr_t length);
  static word InstanceSize();
  FINAL_CLASS();
};

class Class : public AllStatic {
 public:
  static word host_type_arguments_field_offset_in_words_offset();

  static word declaration_type_offset();

  static word super_type_offset();

  // The offset of the UntaggedObject::num_type_arguments_ field in bytes.
  static word num_type_arguments_offset();

  // The value used if no type arguments vector is present.
  static const word kNoTypeArguments;

  static word InstanceSize();

  FINAL_CLASS();

  // Return class id of the given class on the target.
  static classid_t GetId(const dart::Class& handle);

  // Return instance size for the given class on the target.
  static uword GetInstanceSize(const dart::Class& handle);

  // Return whether objects of the class on the target contain compressed
  // pointers.
  static bool HasCompressedPointers(const dart::Class& handle);

  // Returns the number of type arguments.
  static intptr_t NumTypeArguments(const dart::Class& klass);

  // Whether [klass] has a type arguments vector field.
  static bool HasTypeArgumentsField(const dart::Class& klass);

  // Returns the offset (in bytes) of the type arguments vector.
  static intptr_t TypeArgumentsFieldOffset(const dart::Class& klass);

  // Whether to trace allocation for this klass.
  static bool TraceAllocation(const dart::Class& klass);
};

class Instance : public AllStatic {
 public:
  // Returns the offset to the first field of [UntaggedInstance].
  static word first_field_offset();
  static word native_fields_array_offset();
  static word DataOffsetFor(intptr_t cid);
  static word ElementSizeFor(intptr_t cid);
  static word InstanceSize();
  static word NextFieldOffset();
};

class Function : public AllStatic {
 public:
  static word code_offset();
  static word data_offset();
  static word entry_point_offset(CodeEntryKind kind = CodeEntryKind::kNormal);
  static word kind_tag_offset();
  static word signature_offset();
  static word usage_counter_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class CallSiteData : public AllStatic {
 public:
  static word arguments_descriptor_offset();
};

class ICData : public AllStatic {
 public:
  static word owner_offset();
  static word entries_offset();
  static word receivers_static_type_offset();
  static word state_bits_offset();

  static word CodeIndexFor(word num_args);
  static word CountIndexFor(word num_args);
  static word TargetIndexFor(word num_args);
  static word ExactnessIndexFor(word num_args);
  static word TestEntryLengthFor(word num_args, bool exactness_check);
  static word EntryPointIndexFor(word num_args);
  static word NumArgsTestedShift();
  static word NumArgsTestedMask();
  static word InstanceSize();
  FINAL_CLASS();
};

class MegamorphicCache : public AllStatic {
 public:
  static const word kSpreadFactor;
  static word mask_offset();
  static word buckets_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class SingleTargetCache : public AllStatic {
 public:
  static word lower_limit_offset();
  static word upper_limit_offset();
  static word entry_point_offset();
  static word target_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class Array : public AllStatic {
 public:
  static word header_size();
  static word tags_offset();
  static word data_offset();
  static word type_arguments_offset();
  static word length_offset();
  static word element_offset(intptr_t index);
  static intptr_t index_at_offset(intptr_t offset_in_bytes);
  static word InstanceSize(intptr_t length);
  static word InstanceSize();
  FINAL_CLASS();

  static const word kMaxElements;
  static const word kMaxNewSpaceElements;
};

class GrowableObjectArray : public AllStatic {
 public:
  static word data_offset();
  static word type_arguments_offset();
  static word length_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class RecordShape : public AllStatic {
 public:
  static const word kNumFieldsMask;
  static const word kMaxNumFields;
  static const word kFieldNamesIndexShift;
  static const word kFieldNamesIndexMask;
  static const word kMaxFieldNamesIndex;
};

class Record : public AllStatic {
 public:
  static word shape_offset();
  static word field_offset(intptr_t index);
  static intptr_t field_index_at_offset(intptr_t offset_in_bytes);
  static word InstanceSize(intptr_t length);
  static word InstanceSize();
  FINAL_CLASS();

  static const word kMaxElements;
};

class PointerBase : public AllStatic {
 public:
  static word data_offset();
};

class TypedDataBase : public AllStatic {
 public:
  static word length_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class TypedData : public AllStatic {
 public:
  static word payload_offset();
  static word HeaderSize();
  static word InstanceSize();
  static word InstanceSize(word lengthInBytes);
  FINAL_CLASS();
};

class ExternalTypedData : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class TypedDataView : public AllStatic {
 public:
  static word offset_in_bytes_offset();
  static word typed_data_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class LinkedHashBase : public AllStatic {
 public:
  static word index_offset();
  static word data_offset();
  static word hash_mask_offset();
  static word used_data_offset();
  static word deleted_keys_offset();
  static word type_arguments_offset();
  static word InstanceSize();
};

class ImmutableLinkedHashBase : public LinkedHashBase {
 public:
  // The data slot is an immutable list and final in immutable maps and sets.
  static word data_offset();
};

class Map : public LinkedHashBase {
 public:
  FINAL_CLASS();
};

class Set : public LinkedHashBase {
 public:
  FINAL_CLASS();
};

class FutureOr : public AllStatic {
 public:
  static word type_arguments_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class ArgumentsDescriptor : public AllStatic {
 public:
  static word first_named_entry_offset();
  static word named_entry_size();
  static word position_offset();
  static word name_offset();
  static word count_offset();
  static word size_offset();
  static word type_args_len_offset();
  static word positional_count_offset();
};

class LocalHandle : public AllStatic {
 public:
  static word ptr_offset();
  static word InstanceSize();
};

class PersistentHandle : public AllStatic {
 public:
  static word ptr_offset();
};

class Pointer : public AllStatic {
 public:
  static word type_arguments_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class AbstractType : public AllStatic {
 public:
  static word flags_offset();
  static word hash_offset();
  static word type_test_stub_entry_point_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class Type : public AllStatic {
 public:
  static word arguments_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class FunctionType : public AllStatic {
 public:
  static word packed_parameter_counts_offset();
  static word packed_type_parameter_counts_offset();
  static word named_parameter_names_offset();
  static word parameter_types_offset();
  static word type_parameters_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class RecordType : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class Nullability : public AllStatic {
 public:
  static const uint8_t kNullable;
  static const uint8_t kNonNullable;
  static const uint8_t kLegacy;
};

class Double : public AllStatic {
 public:
  static word value_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class Mint : public AllStatic {
 public:
  static word value_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class String : public AllStatic {
 public:
  static const word kHashBits;
  static const word kMaxElements;
  static word hash_offset();
  static word length_offset();
  static word InstanceSize();
  static word InstanceSize(word payload_size);
  FINAL_CLASS();
};

class OneByteString : public AllStatic {
 public:
  static word data_offset();
  static word InstanceSize(intptr_t length);
  static word InstanceSize();
  FINAL_CLASS();

  static const word kMaxNewSpaceElements;

 private:
  static word element_offset(intptr_t index);
};

class TwoByteString : public AllStatic {
 public:
  static word data_offset();
  static word InstanceSize(intptr_t length);
  static word InstanceSize();
  FINAL_CLASS();

  static const word kMaxNewSpaceElements;

 private:
  static word element_offset(intptr_t index);
};

class ExternalOneByteString : public AllStatic {
 public:
  static word external_data_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class ExternalTwoByteString : public AllStatic {
 public:
  static word external_data_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class Int32x4 : public AllStatic {
 public:
  static word value_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class Float32x4 : public AllStatic {
 public:
  static word value_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class Float64x2 : public AllStatic {
 public:
  static word value_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class DynamicLibrary : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class PatchClass : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class FfiTrampolineData : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class Script : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class Library : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class Namespace : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class KernelProgramInfo : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class PcDescriptors : public AllStatic {
 public:
  static word HeaderSize();
  static word InstanceSize();
  static word InstanceSize(word payload_size);
  FINAL_CLASS();
};

class CodeSourceMap : public AllStatic {
 public:
  static word HeaderSize();
  static word InstanceSize();
  static word InstanceSize(word payload_size);
  FINAL_CLASS();
};

class CompressedStackMaps : public AllStatic {
 public:
  static word HeaderSize() { return ObjectHeaderSize() + PayloadHeaderSize(); }
  static word InstanceSize();
  static word InstanceSize(word payload_size);
  FINAL_CLASS();

 private:
  static word ObjectHeaderSize();
  static word PayloadHeaderSize();
};

class LocalVarDescriptors : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class ExceptionHandlers : public AllStatic {
 public:
  static word element_offset(intptr_t index);
  static word InstanceSize(intptr_t length);
  static word InstanceSize();
  FINAL_CLASS();
};

class ContextScope : public AllStatic {
 public:
  static word element_offset(intptr_t index);
  static word InstanceSize(intptr_t length);
  static word InstanceSize();
  FINAL_CLASS();
};

class Sentinel : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class UnlinkedCall : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class ApiError : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class LanguageError : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class UnhandledException : public AllStatic {
 public:
  static word exception_offset();
  static word stacktrace_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class UnwindError : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class Bool : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class TypeParameter : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
  static word index_offset();
};

class LibraryPrefix : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class Capability : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class ReceivePort : public AllStatic {
 public:
  static word send_port_offset();
  static word handler_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class SendPort : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class TransferableTypedData : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class StackTrace : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class SuspendState : public AllStatic {
 public:
  static word frame_capacity_offset();
  static word frame_size_offset();
  static word pc_offset();
  static word function_data_offset();
  static word then_callback_offset();
  static word error_callback_offset();
  static word payload_offset();

  static word HeaderSize();
  static word InstanceSize();
  static word InstanceSize(word payload_size);
  static word FrameSizeGrowthGap();

  FINAL_CLASS();
};

class Integer : public AllStatic {
 public:
  static word InstanceSize();
  static word NextFieldOffset();
};

class Smi : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class WeakProperty : public AllStatic {
 public:
  static word key_offset();
  static word value_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class WeakReference : public AllStatic {
 public:
  static word target_offset();
  static word type_arguments_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class FinalizerBase : public AllStatic {
 public:
  static word all_entries_offset();
  static word detachments_offset();
  static word entries_collected_offset();
  static word isolate_offset();
  FINAL_CLASS();
};

class Finalizer : public AllStatic {
 public:
  static word callback_offset();
  static word type_arguments_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class NativeFinalizer : public AllStatic {
 public:
  static word callback_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class FinalizerEntry : public AllStatic {
 public:
  static word detach_offset();
  static word external_size_offset();
  static word finalizer_offset();
  static word next_offset();
  static word token_offset();
  static word value_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class MirrorReference : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class Number : public AllStatic {
 public:
  static word InstanceSize();
  static word NextFieldOffset();
};

class TimelineStream : public AllStatic {
 public:
  static word enabled_offset();
};

class StreamInfo : public AllStatic {
 public:
  static word enabled_offset();
};

class MonomorphicSmiableCall : public AllStatic {
 public:
  static word expected_cid_offset();
  static word entrypoint_offset();
  static word target_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class TsanUtils : public AllStatic {
 public:
  static word setjmp_function_offset();
  static word setjmp_buffer_offset();
  static word exception_pc_offset();
  static word exception_sp_offset();
  static word exception_fp_offset();
};

class Thread : public AllStatic {
 public:
  static word api_top_scope_offset();
  static word double_truncate_round_supported_offset();
  static word exit_through_ffi_offset();
  static uword exit_through_runtime_call();
  static uword exit_through_ffi();
  static word dart_stream_offset();
  static word service_extension_stream_offset();
  static word predefined_symbols_address_offset();
  static word optimize_entry_offset();
  static word deoptimize_entry_offset();
  static word megamorphic_call_checked_entry_offset();
  static word active_exception_offset();
  static word active_stacktrace_offset();
  static word resume_pc_offset();
  static word saved_shadow_call_stack_offset();
  static word marking_stack_block_offset();
  static word top_exit_frame_info_offset();
  static word top_resource_offset();
  static word global_object_pool_offset();
  static word object_null_offset();
  static word bool_true_offset();
  static word bool_false_offset();
  static word dispatch_table_array_offset();
  static word top_offset();
  static word end_offset();
  static word isolate_offset();
  static word isolate_group_offset();
  static word field_table_values_offset();
  static word store_buffer_block_offset();
  static word call_to_runtime_entry_point_offset();
  static word write_barrier_mask_offset();
  static word heap_base_offset();
  static word switchable_call_miss_entry_offset();
  static word write_barrier_wrappers_thread_offset(Register regno);
  static word array_write_barrier_entry_point_offset();
  static word allocate_mint_with_fpu_regs_entry_point_offset();
  static word allocate_mint_without_fpu_regs_entry_point_offset();
  static word allocate_object_entry_point_offset();
  static word allocate_object_parameterized_entry_point_offset();
  static word allocate_object_slow_entry_point_offset();
  static word slow_type_test_entry_point_offset();
  static word write_barrier_entry_point_offset();
  static word vm_tag_offset();
  static uword vm_tag_dart_id();

  static word safepoint_state_offset();
  static uword full_safepoint_state_unacquired();
  static uword full_safepoint_state_acquired();

  static word execution_state_offset();
  static uword vm_execution_state();
  static uword native_execution_state();
  static uword generated_execution_state();
  static word stack_overflow_flags_offset();
  static word stack_overflow_shared_stub_entry_point_offset(bool fpu_regs);
  static word stack_limit_offset();
  static word saved_stack_limit_offset();
  static word unboxed_runtime_arg_offset();

  static word tsan_utils_offset();
  static word jump_to_frame_entry_point_offset();

  static word AllocateArray_entry_point_offset();
  static word write_barrier_code_offset();
  static word array_write_barrier_code_offset();
  static word fix_callers_target_code_offset();
  static word fix_allocation_stub_code_offset();

  static word switchable_call_miss_stub_offset();
  static word lazy_specialize_type_test_stub_offset();
  static word slow_type_test_stub_offset();
  static word call_to_runtime_stub_offset();
  static word invoke_dart_code_stub_offset();
  static word late_initialization_error_shared_without_fpu_regs_stub_offset();
  static word late_initialization_error_shared_with_fpu_regs_stub_offset();
  static word null_error_shared_without_fpu_regs_stub_offset();
  static word null_error_shared_with_fpu_regs_stub_offset();
  static word null_arg_error_shared_without_fpu_regs_stub_offset();
  static word null_arg_error_shared_with_fpu_regs_stub_offset();
  static word null_cast_error_shared_without_fpu_regs_stub_offset();
  static word null_cast_error_shared_with_fpu_regs_stub_offset();
  static word range_error_shared_without_fpu_regs_stub_offset();
  static word range_error_shared_with_fpu_regs_stub_offset();
  static word write_error_shared_without_fpu_regs_stub_offset();
  static word write_error_shared_with_fpu_regs_stub_offset();
  static word resume_stub_offset();
  static word return_async_not_future_stub_offset();
  static word return_async_star_stub_offset();
  static word return_async_stub_offset();
  static word stack_overflow_shared_without_fpu_regs_entry_point_offset();
  static word stack_overflow_shared_without_fpu_regs_stub_offset();
  static word stack_overflow_shared_with_fpu_regs_entry_point_offset();
  static word stack_overflow_shared_with_fpu_regs_stub_offset();
  static word lazy_deopt_from_return_stub_offset();
  static word lazy_deopt_from_throw_stub_offset();
  static word allocate_mint_with_fpu_regs_stub_offset();
  static word allocate_mint_without_fpu_regs_stub_offset();
  static word allocate_object_stub_offset();
  static word allocate_object_parameterized_stub_offset();
  static word allocate_object_slow_stub_offset();
  static word async_exception_handler_stub_offset();
  static word optimize_stub_offset();
  static word deoptimize_stub_offset();
  static word enter_safepoint_stub_offset();
  static word exit_safepoint_stub_offset();
  static word exit_safepoint_ignore_unwind_in_progress_stub_offset();
  static word call_native_through_safepoint_stub_offset();
  static word call_native_through_safepoint_entry_point_offset();

  static word bootstrap_native_wrapper_entry_point_offset();
  static word no_scope_native_wrapper_entry_point_offset();
  static word auto_scope_native_wrapper_entry_point_offset();

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

  static word next_task_id_offset();
  static word random_offset();

  static word suspend_state_init_async_entry_point_offset();
  static word suspend_state_await_entry_point_offset();
  static word suspend_state_await_with_type_check_entry_point_offset();
  static word suspend_state_return_async_entry_point_offset();
  static word suspend_state_return_async_not_future_entry_point_offset();

  static word suspend_state_init_async_star_entry_point_offset();
  static word suspend_state_yield_async_star_entry_point_offset();
  static word suspend_state_return_async_star_entry_point_offset();

  static word suspend_state_init_sync_star_entry_point_offset();
  static word suspend_state_suspend_sync_star_at_start_entry_point_offset();

  static word suspend_state_handle_exception_entry_point_offset();

  static word OffsetFromThread(const dart::Object& object);
  static intptr_t OffsetFromThread(const dart::RuntimeEntry* runtime_entry);
};

class StoreBufferBlock : public AllStatic {
 public:
  static word top_offset();
  static word pointers_offset();
  static const word kSize;
};

class MarkingStackBlock : public AllStatic {
 public:
  static word top_offset();
  static word pointers_offset();
  static const word kSize;
};

class ObjectStore : public AllStatic {
 public:
  static word double_type_offset();
  static word int_type_offset();
  static word record_field_names_offset();
  static word string_type_offset();
  static word type_type_offset();

  static word ffi_callback_code_offset();

  static word suspend_state_await_offset();
  static word suspend_state_await_with_type_check_offset();
  static word suspend_state_handle_exception_offset();
  static word suspend_state_init_async_offset();
  static word suspend_state_init_async_star_offset();
  static word suspend_state_init_sync_star_offset();
  static word suspend_state_return_async_offset();
  static word suspend_state_return_async_not_future_offset();
  static word suspend_state_return_async_star_offset();
  static word suspend_state_suspend_sync_star_at_start_offset();
  static word suspend_state_yield_async_star_offset();
};

class Isolate : public AllStatic {
 public:
  static word default_tag_offset();
  static word current_tag_offset();
  static word user_tag_offset();
  static word finalizers_offset();
#if !defined(PRODUCT)
  static word single_step_offset();
  static word has_resumption_breakpoints_offset();
#endif  // !defined(PRODUCT)
};

class IsolateGroup : public AllStatic {
 public:
  static word object_store_offset();
  static word class_table_offset();
  static word cached_class_table_table_offset();
};

class ClassTable : public AllStatic {
 public:
#if !defined(PRODUCT)
  static word allocation_tracing_state_table_offset();
  static word AllocationTracingStateSlotOffsetFor(intptr_t cid);
#endif  // !defined(PRODUCT)
};

class InstructionsSection : public AllStatic {
 public:
  static word UnalignedHeaderSize();
  static word HeaderSize();
  static word InstanceSize();
  static word InstanceSize(word payload_size);
  FINAL_CLASS();
};

class InstructionsTable : public AllStatic {
 public:
  static word HeaderSize();
  static word InstanceSize();
  static word InstanceSize(intptr_t length);
  FINAL_CLASS();

 private:
  static word element_offset(intptr_t index);
};

class Instructions : public AllStatic {
 public:
  static const word kMonomorphicEntryOffsetJIT;
  static const word kPolymorphicEntryOffsetJIT;
  static const word kMonomorphicEntryOffsetAOT;
  static const word kPolymorphicEntryOffsetAOT;
  static const word kBarePayloadAlignment;
  static const word kNonBarePayloadAlignment;
  static word UnalignedHeaderSize();
  static word HeaderSize();
  static word InstanceSize();
  static word InstanceSize(word payload_size);
  FINAL_CLASS();
};

class Code : public AllStatic {
 public:
#if defined(TARGET_ARCH_IA32)
  static uword EntryPointOf(const dart::Code& code);
#endif  // defined(TARGET_ARCH_IA32)

  static word object_pool_offset();
  static word entry_point_offset(CodeEntryKind kind = CodeEntryKind::kNormal);
  static word active_instructions_offset();
  static word instructions_offset();
  static word owner_offset();
  static word HeaderSize();
  static word InstanceSize();
  static word InstanceSize(intptr_t length);
  FINAL_CLASS();

 private:
  static word element_offset(intptr_t index);
};

class WeakSerializationReference : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class WeakArray : public AllStatic {
 public:
  static word length_offset();
  static word element_offset(intptr_t index);
  static word InstanceSize(intptr_t length);
  static word InstanceSize();
  FINAL_CLASS();
};

class SubtypeTestCache : public AllStatic {
 public:
  static word cache_offset();
  static word num_inputs_offset();

  static const word kMaxInputs;
  static const word kTestEntryLength;
  static const word kInstanceCidOrSignature;
  static const word kDestinationType;
  static const word kInstanceTypeArguments;
  static const word kInstantiatorTypeArguments;
  static const word kFunctionTypeArguments;
  static const word kInstanceParentFunctionTypeArguments;
  static const word kInstanceDelayedFunctionTypeArguments;
  static const word kTestResult;
  static word InstanceSize();
  FINAL_CLASS();
};

class LoadingUnit : public AllStatic {
 public:
  static word InstanceSize();
  FINAL_CLASS();
};

class Context : public AllStatic {
 public:
  static word header_size();
  static word parent_offset();
  static word num_variables_offset();
  static word variable_offset(intptr_t index);
  static word InstanceSize(intptr_t length);
  static word InstanceSize();
  FINAL_CLASS();

  static const word kMaxElements;
};

class Closure : public AllStatic {
 public:
  static word context_offset();
  static word delayed_type_arguments_offset();
  static word entry_point_offset();
  static word function_offset();
  static word function_type_arguments_offset();
  static word instantiator_type_arguments_offset();
  static word hash_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class ClosureData : public AllStatic {
 public:
  static word packed_fields_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class Page : public AllStatic {
 public:
  static const word kBytesPerCardLog2;

  static word card_table_offset();
  static word original_top_offset();
  static word original_end_offset();
};

class Heap : public AllStatic {
 public:
  // Return true if an object with the given instance size is allocatable
  // in new space on the target.
  static bool IsAllocatableInNewSpace(intptr_t instance_size);
};

class NativeArguments {
 public:
  static word thread_offset();
  static word argc_tag_offset();
  static word argv_offset();
  static word retval_offset();

  static word StructSize();
};

class NativeEntry {
 public:
  static const word kNumCallWrapperArguments;
};

class RegExp : public AllStatic {
 public:
  static word function_offset(classid_t cid, bool sticky);
  static word InstanceSize();
  FINAL_CLASS();
};

class UserTag : public AllStatic {
 public:
  static word tag_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class Symbols : public AllStatic {
 public:
  static const word kNumberOfOneCharCodeSymbols;
  static const word kNullCharCodeSymbolOffset;
};

class Field : public AllStatic {
 public:
  static word OffsetOf(const dart::Field& field);

  static word guarded_cid_offset();
  static word guarded_list_length_in_object_offset_offset();
  static word guarded_list_length_offset();
  static word is_nullable_offset();
  static word kind_bits_offset();
  static word initializer_function_offset();
  static word host_offset_or_field_id_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class TypeParameters : public AllStatic {
 public:
  static word names_offset();
  static word flags_offset();
  static word bounds_offset();
  static word defaults_offset();
  static word InstanceSize();
  FINAL_CLASS();
};

class TypeArguments : public AllStatic {
 public:
  static word hash_offset();
  static word instantiations_offset();
  static word length_offset();
  static word nullability_offset();
  static word type_at_offset(intptr_t i);
  static word types_offset();
  static word InstanceSize(intptr_t length);
  static word InstanceSize();
  FINAL_CLASS();

  static const word kMaxElements;
};

class FreeListElement : public AllStatic {
 public:
  class FakeInstance : public AllStatic {
   public:
    static word InstanceSize();
    FINAL_CLASS();
  };
};

class ForwardingCorpse : public AllStatic {
 public:
  class FakeInstance : public AllStatic {
   public:
    static word InstanceSize();
    FINAL_CLASS();
  };
};

class FieldTable : public AllStatic {
 public:
  static word OffsetOf(const dart::Field& field);
};

void UnboxFieldIfSupported(const dart::Field& field,
                           const dart::AbstractType& type);

}  // namespace target
}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_RUNTIME_API_H_
