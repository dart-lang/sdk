// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLASS_ID_H_
#define RUNTIME_VM_CLASS_ID_H_

// This header defines the list of VM implementation classes and their ids.
//
// Note: we assume that all builds of Dart VM use exactly the same class ids
// for these classes.

#include "platform/assert.h"
#include "vm/globals.h"

namespace dart {

// Large enough to contain the class-id part of the object header. See
// UntaggedObject. Signed to be comparable to intptr_t.
typedef int32_t ClassIdTagType;

static constexpr intptr_t kClassIdTagMax = (1 << 20) - 1;

// Classes that are not subclasses of Instance and only handled by the VM,
// but do not require any special handling other than being a predefined class.
#define CLASS_LIST_INTERNAL_ONLY(V)                                            \
  V(Class)                                                                     \
  V(PatchClass)                                                                \
  V(Function)                                                                  \
  V(TypeParameters)                                                            \
  V(ClosureData)                                                               \
  V(FfiTrampolineData)                                                         \
  V(Field)                                                                     \
  V(Script)                                                                    \
  V(Library)                                                                   \
  V(Namespace)                                                                 \
  V(KernelProgramInfo)                                                         \
  V(WeakSerializationReference)                                                \
  V(WeakArray)                                                                 \
  V(Code)                                                                      \
  V(Instructions)                                                              \
  V(InstructionsSection)                                                       \
  V(InstructionsTable)                                                         \
  V(ObjectPool)                                                                \
  V(PcDescriptors)                                                             \
  V(CodeSourceMap)                                                             \
  V(CompressedStackMaps)                                                       \
  V(LocalVarDescriptors)                                                       \
  V(ExceptionHandlers)                                                         \
  V(Context)                                                                   \
  V(ContextScope)                                                              \
  V(Sentinel)                                                                  \
  V(SingleTargetCache)                                                         \
  V(UnlinkedCall)                                                              \
  V(MonomorphicSmiableCall)                                                    \
  V(CallSiteData)                                                              \
  V(ICData)                                                                    \
  V(MegamorphicCache)                                                          \
  V(SubtypeTestCache)                                                          \
  V(LoadingUnit)                                                               \
  V(Error)                                                                     \
  V(ApiError)                                                                  \
  V(LanguageError)                                                             \
  V(UnhandledException)                                                        \
  V(UnwindError)

// Classes that are subclasses of Instance and neither part of a specific cid
// grouping like strings, arrays, etc. nor require special handling outside of
// being a predefined class.
#define CLASS_LIST_INSTANCE_SINGLETONS(V)                                      \
  V(Instance)                                                                  \
  V(LibraryPrefix)                                                             \
  V(TypeArguments)                                                             \
  V(AbstractType)                                                              \
  V(Type)                                                                      \
  V(FunctionType)                                                              \
  V(RecordType)                                                                \
  V(TypeParameter)                                                             \
  V(FinalizerBase)                                                             \
  V(Finalizer)                                                                 \
  V(NativeFinalizer)                                                           \
  V(FinalizerEntry)                                                            \
  V(Closure)                                                                   \
  V(Number)                                                                    \
  V(Integer)                                                                   \
  V(Smi)                                                                       \
  V(Mint)                                                                      \
  V(Double)                                                                    \
  V(Bool)                                                                      \
  V(Float32x4)                                                                 \
  V(Int32x4)                                                                   \
  V(Float64x2)                                                                 \
  V(Record)                                                                    \
  V(TypedDataBase)                                                             \
  V(TypedData)                                                                 \
  V(ExternalTypedData)                                                         \
  V(TypedDataView)                                                             \
  V(Pointer)                                                                   \
  V(DynamicLibrary)                                                            \
  V(Capability)                                                                \
  V(ReceivePort)                                                               \
  V(SendPort)                                                                  \
  V(StackTrace)                                                                \
  V(SuspendState)                                                              \
  V(RegExp)                                                                    \
  V(WeakProperty)                                                              \
  V(WeakReference)                                                             \
  V(MirrorReference)                                                           \
  V(FutureOr)                                                                  \
  V(UserTag)                                                                   \
  V(TransferableTypedData)

#define CLASS_LIST_NO_OBJECT_NOR_STRING_NOR_ARRAY_NOR_MAP(V)                   \
  CLASS_LIST_INTERNAL_ONLY(V) CLASS_LIST_INSTANCE_SINGLETONS(V)

#define CLASS_LIST_MAPS(V)                                                     \
  V(Map)                                                                       \
  V(ConstMap)

#define CLASS_LIST_SETS(V)                                                     \
  V(Set)                                                                       \
  V(ConstSet)

#define CLASS_LIST_FIXED_LENGTH_ARRAYS(V)                                      \
  V(Array)                                                                     \
  V(ImmutableArray)

#define CLASS_LIST_ARRAYS(V)                                                   \
  CLASS_LIST_FIXED_LENGTH_ARRAYS(V)                                            \
  V(GrowableObjectArray)

#define CLASS_LIST_STRINGS(V)                                                  \
  V(String)                                                                    \
  V(OneByteString)                                                             \
  V(TwoByteString)                                                             \
  V(ExternalOneByteString)                                                     \
  V(ExternalTwoByteString)

#define CLASS_LIST_TYPED_DATA(V)                                               \
  V(Int8Array)                                                                 \
  V(Uint8Array)                                                                \
  V(Uint8ClampedArray)                                                         \
  V(Int16Array)                                                                \
  V(Uint16Array)                                                               \
  V(Int32Array)                                                                \
  V(Uint32Array)                                                               \
  V(Int64Array)                                                                \
  V(Uint64Array)                                                               \
  V(Float32Array)                                                              \
  V(Float64Array)                                                              \
  V(Float32x4Array)                                                            \
  V(Int32x4Array)                                                              \
  V(Float64x2Array)

#define CLASS_LIST_FFI_NUMERIC_FIXED_SIZE(V)                                   \
  V(Int8)                                                                      \
  V(Int16)                                                                     \
  V(Int32)                                                                     \
  V(Int64)                                                                     \
  V(Uint8)                                                                     \
  V(Uint16)                                                                    \
  V(Uint32)                                                                    \
  V(Uint64)                                                                    \
  V(Float)                                                                     \
  V(Double)

#define CLASS_LIST_FFI_TYPE_MARKER(V)                                          \
  CLASS_LIST_FFI_NUMERIC_FIXED_SIZE(V)                                         \
  V(Void)                                                                      \
  V(Handle)                                                                    \
  V(Bool)

#define CLASS_LIST_FFI(V)                                                      \
  V(NativeFunction)                                                            \
  CLASS_LIST_FFI_TYPE_MARKER(V)                                                \
  V(NativeType)                                                                \
  V(Struct)

#define DART_CLASS_LIST_TYPED_DATA(V)                                          \
  V(Int8)                                                                      \
  V(Uint8)                                                                     \
  V(Uint8Clamped)                                                              \
  V(Int16)                                                                     \
  V(Uint16)                                                                    \
  V(Int32)                                                                     \
  V(Uint32)                                                                    \
  V(Int64)                                                                     \
  V(Uint64)                                                                    \
  V(Float32)                                                                   \
  V(Float64)                                                                   \
  V(Float32x4)                                                                 \
  V(Int32x4)                                                                   \
  V(Float64x2)

#define CLASS_LIST_FOR_HANDLES(V)                                              \
  CLASS_LIST_NO_OBJECT_NOR_STRING_NOR_ARRAY_NOR_MAP(V)                         \
  V(Map)                                                                       \
  V(Set)                                                                       \
  V(Array)                                                                     \
  V(GrowableObjectArray)                                                       \
  V(String)

#define CLASS_LIST_NO_OBJECT(V)                                                \
  CLASS_LIST_NO_OBJECT_NOR_STRING_NOR_ARRAY_NOR_MAP(V)                         \
  CLASS_LIST_MAPS(V)                                                           \
  CLASS_LIST_SETS(V)                                                           \
  CLASS_LIST_ARRAYS(V)                                                         \
  CLASS_LIST_STRINGS(V)

#define CLASS_LIST(V)                                                          \
  V(Object)                                                                    \
  CLASS_LIST_NO_OBJECT(V)

enum ClassId : intptr_t {
  // Illegal class id.
  kIllegalCid = 0,

  // Pseudo class id for native pointers, the heap should never see an
  // object with this class id.
  kNativePointer,

  // The following entries describes classes for pseudo-objects in the heap
  // that should never be reachable from live objects. Free list elements
  // maintain the free list for old space, and forwarding corpses are used to
  // implement one-way become.
  kFreeListElement,
  kForwardingCorpse,

// List of Ids for predefined classes.
#define DEFINE_OBJECT_KIND(clazz) k##clazz##Cid,
  CLASS_LIST(DEFINE_OBJECT_KIND)
#undef DEFINE_OBJECT_KIND

// clang-format off
#define DEFINE_OBJECT_KIND(clazz) kFfi##clazz##Cid,
  CLASS_LIST_FFI(DEFINE_OBJECT_KIND)
#undef DEFINE_OBJECT_KIND

#define DEFINE_OBJECT_KIND(clazz)                                              \
  kTypedData##clazz##Cid,                                                      \
  kTypedData##clazz##ViewCid,                                                  \
  kExternalTypedData##clazz##Cid,                                              \
  kUnmodifiableTypedData##clazz##ViewCid,
  CLASS_LIST_TYPED_DATA(DEFINE_OBJECT_KIND)
#undef DEFINE_OBJECT_KIND
  kByteDataViewCid,
  kUnmodifiableByteDataViewCid,

  kByteBufferCid,
  // clang-format on

  // The following entries do not describe a predefined class, but instead
  // are class indexes for pre-allocated instances (Null, dynamic, void, Never).
  kNullCid,
  kDynamicCid,
  kVoidCid,
  kNeverCid,

  kNumPredefinedCids,
};

// Keep these in sync with the cid numbering above.
const int kTypedDataCidRemainderInternal = 0;
const int kTypedDataCidRemainderView = 1;
const int kTypedDataCidRemainderExternal = 2;
const int kTypedDataCidRemainderUnmodifiable = 3;

// Class Id predicates.

bool IsInternalOnlyClassId(intptr_t index);
bool IsErrorClassId(intptr_t index);
bool IsNumberClassId(intptr_t index);
bool IsIntegerClassId(intptr_t index);
bool IsStringClassId(intptr_t index);
bool IsOneByteStringClassId(intptr_t index);
bool IsExternalStringClassId(intptr_t index);
bool IsBuiltinListClassId(intptr_t index);
bool IsTypeClassId(intptr_t index);
bool IsTypedDataBaseClassId(intptr_t index);
bool IsTypedDataClassId(intptr_t index);
bool IsTypedDataViewClassId(intptr_t index);
bool IsExternalTypedDataClassId(intptr_t index);
bool IsFfiPointerClassId(intptr_t index);
bool IsFfiTypeClassId(intptr_t index);
bool IsFfiDynamicLibraryClassId(intptr_t index);
bool IsInternalVMdefinedClassId(intptr_t index);
bool IsImplicitFieldClassId(intptr_t index);

// Should be used for looping over non-Object internal-only cids.
constexpr intptr_t kFirstInternalOnlyCid = kClassCid;
constexpr intptr_t kLastInternalOnlyCid = kUnwindErrorCid;
// Use the currently surrounding cids to check that no new classes have been
// added to the beginning or end of CLASS_LIST_INTERNAL_ONLY without adjusting
// the above definitions.
COMPILE_ASSERT(kFirstInternalOnlyCid == kObjectCid + 1);
COMPILE_ASSERT(kInstanceCid == kLastInternalOnlyCid + 1);

// Returns true for any class id that either does not correspond to a real
// class, like kIllegalCid or kForwardingCorpse, or that is internal to the VM
// and should not be exposed directly to user code.
inline bool IsInternalOnlyClassId(intptr_t index) {
  // Fix the condition below if these become non-contiguous.
  COMPILE_ASSERT(kIllegalCid + 1 == kNativePointer &&
                 kIllegalCid + 2 == kFreeListElement &&
                 kIllegalCid + 3 == kForwardingCorpse &&
                 kIllegalCid + 4 == kObjectCid &&
                 kIllegalCid + 5 == kFirstInternalOnlyCid);
  return index <= kLastInternalOnlyCid;
}

  // Make sure this function is updated when new Error types are added.
static const ClassId kFirstErrorCid = kErrorCid;
static const ClassId kLastErrorCid = kUnwindErrorCid;
COMPILE_ASSERT(kFirstErrorCid == kErrorCid &&
               kApiErrorCid == kFirstErrorCid + 1 &&
               kLanguageErrorCid == kFirstErrorCid + 2 &&
               kUnhandledExceptionCid == kFirstErrorCid + 3 &&
               kUnwindErrorCid == kFirstErrorCid + 4 &&
               kLastErrorCid == kUnwindErrorCid &&
               // Change if needed for detecting a new error added at the end.
               kLastInternalOnlyCid == kLastErrorCid);

inline bool IsErrorClassId(intptr_t index) {
  return (index >= kFirstErrorCid && index <= kLastErrorCid);
}

inline bool IsNumberClassId(intptr_t index) {
  // Make sure this function is updated when new Number types are added.
  COMPILE_ASSERT(kIntegerCid == kNumberCid + 1 && kSmiCid == kNumberCid + 2 &&
                 kMintCid == kNumberCid + 3 && kDoubleCid == kNumberCid + 4);
  return (index >= kNumberCid && index <= kDoubleCid);
}

inline bool IsIntegerClassId(intptr_t index) {
  // Make sure this function is updated when new Integer types are added.
  COMPILE_ASSERT(kSmiCid == kIntegerCid + 1 && kMintCid == kIntegerCid + 2);
  return (index >= kIntegerCid && index <= kMintCid);
}

// Make sure this check is updated when new StringCid types are added.
COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
               kTwoByteStringCid == kStringCid + 2 &&
               kExternalOneByteStringCid == kStringCid + 3 &&
               kExternalTwoByteStringCid == kStringCid + 4);

inline bool IsStringClassId(intptr_t index) {
  return (index >= kStringCid && index <= kExternalTwoByteStringCid);
}

inline bool IsOneByteStringClassId(intptr_t index) {
  return (index == kOneByteStringCid || index == kExternalOneByteStringCid);
}

inline bool IsExternalStringClassId(intptr_t index) {
  return (index == kExternalOneByteStringCid ||
          index == kExternalTwoByteStringCid);
}

inline bool IsArrayClassId(intptr_t index) {
  COMPILE_ASSERT(kImmutableArrayCid == kArrayCid + 1);
  COMPILE_ASSERT(kGrowableObjectArrayCid == kArrayCid + 2);
  return (index >= kArrayCid && index <= kGrowableObjectArrayCid);
}

inline bool IsBuiltinListClassId(intptr_t index) {
  // Make sure this function is updated when new builtin List types are added.
  return (IsArrayClassId(index) || IsTypedDataBaseClassId(index) ||
          (index == kByteBufferCid));
}

inline bool IsTypeClassId(intptr_t index) {
  // Only Type, FunctionType and RecordType can be encountered as instance
  // types at runtime.
  return index == kTypeCid || index == kFunctionTypeCid ||
         index == kRecordTypeCid;
}

inline bool IsTypedDataBaseClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 4 == kTypedDataUint8ArrayCid);
  return index >= kTypedDataInt8ArrayCid && index < kByteDataViewCid;
}

inline bool IsTypedDataClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 4 == kTypedDataUint8ArrayCid);
  return IsTypedDataBaseClassId(index) && ((index - kTypedDataInt8ArrayCid) %
                                           4) == kTypedDataCidRemainderInternal;
}

inline bool IsTypedDataViewClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kTypedDataInt8ArrayViewCid + 4 == kTypedDataUint8ArrayViewCid);

  const bool is_byte_data_view = index == kByteDataViewCid;
  return is_byte_data_view ||
         (IsTypedDataBaseClassId(index) &&
          ((index - kTypedDataInt8ArrayCid) % 4) == kTypedDataCidRemainderView);
}

inline bool IsExternalTypedDataClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kExternalTypedDataInt8ArrayCid + 4 ==
                 kExternalTypedDataUint8ArrayCid);

  return IsTypedDataBaseClassId(index) && ((index - kTypedDataInt8ArrayCid) %
                                           4) == kTypedDataCidRemainderExternal;
}

inline bool IsUnmodifiableTypedDataViewClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kExternalTypedDataInt8ArrayCid + 4 ==
                 kExternalTypedDataUint8ArrayCid);

  const bool is_byte_data_view = index == kUnmodifiableByteDataViewCid;
  return is_byte_data_view || (IsTypedDataBaseClassId(index) &&
                               ((index - kTypedDataInt8ArrayCid) % 4) ==
                                   kTypedDataCidRemainderUnmodifiable);
}

inline bool ShouldHaveImmutabilityBitSet(intptr_t index) {
  return IsUnmodifiableTypedDataViewClassId(index) || IsStringClassId(index) ||
         index == kMintCid || index == kNeverCid || index == kSentinelCid ||
         index == kStackTraceCid || index == kDoubleCid ||
         index == kFloat32x4Cid || index == kFloat64x2Cid ||
         index == kInt32x4Cid || index == kSendPortCid ||
         index == kCapabilityCid || index == kRegExpCid || index == kBoolCid ||
         index == kNullCid;
}

inline bool IsFfiTypeClassId(intptr_t index) {
  switch (index) {
    case kPointerCid:
    case kFfiNativeFunctionCid:
#define CASE_FFI_CID(name) case kFfi##name##Cid:
      CLASS_LIST_FFI_TYPE_MARKER(CASE_FFI_CID)
#undef CASE_FFI_CID
      return true;
    default:
      return false;
  }
  UNREACHABLE();
}

inline bool IsFfiPredefinedClassId(classid_t class_id) {
  switch (class_id) {
    case kPointerCid:
    case kDynamicLibraryCid:
#define CASE_FFI_CID(name) case kFfi##name##Cid:
      CLASS_LIST_FFI(CASE_FFI_CID)
#undef CASE_FFI_CID
      return true;
    default:
      return false;
  }
  UNREACHABLE();
}

inline bool IsFfiPointerClassId(intptr_t index) {
  return index == kPointerCid;
}

inline bool IsFfiDynamicLibraryClassId(intptr_t index) {
  return index == kDynamicLibraryCid;
}

inline bool IsInternalVMdefinedClassId(intptr_t index) {
  return ((index < kNumPredefinedCids) && !IsImplicitFieldClassId(index));
}

// This is a set of classes that are not Dart classes whose representation
// is defined by the VM but are used in the VM code by computing the
// implicit field offsets of the various fields in the dart object.
inline bool IsImplicitFieldClassId(intptr_t index) {
  return index == kByteBufferCid;
}

// Make sure the following checks are updated when adding new TypedData types.

// Ensure that each typed data type comes in internal/view/external variants
// next to each other.
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 1 == kTypedDataInt8ArrayViewCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 2 == kExternalTypedDataInt8ArrayCid);

// Ensure the order of the typed data members in 3-step.
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 1 * 4 == kTypedDataUint8ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 2 * 4 ==
               kTypedDataUint8ClampedArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 3 * 4 == kTypedDataInt16ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 4 * 4 == kTypedDataUint16ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 5 * 4 == kTypedDataInt32ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 6 * 4 == kTypedDataUint32ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 7 * 4 == kTypedDataInt64ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 8 * 4 == kTypedDataUint64ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 9 * 4 == kTypedDataFloat32ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 10 * 4 == kTypedDataFloat64ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 11 * 4 == kTypedDataFloat32x4ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 12 * 4 == kTypedDataInt32x4ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 13 * 4 == kTypedDataFloat64x2ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + 14 * 4 == kByteDataViewCid);
COMPILE_ASSERT(kByteBufferCid + 1 == kNullCid);

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_ID_H_
