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
  V(Bytecode)                                                                  \
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
  V(MonomorphicSmiableCall)                                                    \
  V(CallSiteData)                                                              \
  V(UnlinkedCall)                                                              \
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
  V(TwoByteString)

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

#define LEAF_HANDLE_LIST(V)                                                    \
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
  V(Bytecode)                                                                  \
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
  V(ICData)                                                                    \
  V(MegamorphicCache)                                                          \
  V(SubtypeTestCache)                                                          \
  V(LoadingUnit)                                                               \
  V(ApiError)                                                                  \
  V(LanguageError)                                                             \
  V(UnhandledException)                                                        \
  V(UnwindError)                                                               \
  V(LibraryPrefix)                                                             \
  V(TypeArguments)                                                             \
  V(Type)                                                                      \
  V(FunctionType)                                                              \
  V(RecordType)                                                                \
  V(TypeParameter)                                                             \
  V(Finalizer)                                                                 \
  V(NativeFinalizer)                                                           \
  V(FinalizerEntry)                                                            \
  V(Closure)                                                                   \
  V(Smi)                                                                       \
  V(Mint)                                                                      \
  V(Double)                                                                    \
  V(Bool)                                                                      \
  V(Float32x4)                                                                 \
  V(Int32x4)                                                                   \
  V(Float64x2)                                                                 \
  V(Record)                                                                    \
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
  V(TransferableTypedData)                                                     \
  V(Map)                                                                       \
  V(Set)                                                                       \
  V(Array)                                                                     \
  V(GrowableObjectArray)                                                       \
  V(String)

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
const int kNumTypedDataCidRemainders = kTypedDataCidRemainderUnmodifiable + 1;

// Class Id predicates.

bool IsInternalOnlyClassId(intptr_t index);
bool IsErrorClassId(intptr_t index);
bool IsNumberClassId(intptr_t index);
bool IsIntegerClassId(intptr_t index);
bool IsStringClassId(intptr_t index);
bool IsOneByteStringClassId(intptr_t index);
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

inline bool IsCallSiteDataClassId(intptr_t index) {
  COMPILE_ASSERT(kCallSiteDataCid + 1 == kUnlinkedCallCid &&
                 kCallSiteDataCid + 2 == kICDataCid &&
                 kCallSiteDataCid + 3 == kMegamorphicCacheCid);
  return (index >= kCallSiteDataCid && index <= kMegamorphicCacheCid);
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

inline bool IsAbstractTypeClassId(intptr_t index) {
  COMPILE_ASSERT(kAbstractTypeCid + 1 == kTypeCid &&
                 kAbstractTypeCid + 2 == kFunctionTypeCid &&
                 kAbstractTypeCid + 3 == kRecordTypeCid &&
                 kAbstractTypeCid + 4 == kTypeParameterCid);
  return (index >= kAbstractTypeCid && index <= kTypeParameterCid);
}

inline bool IsConcreteTypeClassId(intptr_t index) {
  // Make sure to update when new AbstractType subclasses are added.
  COMPILE_ASSERT(kFunctionTypeCid == kTypeCid + 1 &&
                 kRecordTypeCid == kTypeCid + 2 &&
                 kTypeParameterCid == kTypeCid + 3);
  return (index >= kTypeCid && index <= kTypeParameterCid);
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
               kTwoByteStringCid == kStringCid + 2);

inline bool IsStringClassId(intptr_t index) {
  return (index >= kStringCid && index <= kTwoByteStringCid);
}

inline bool IsOneByteStringClassId(intptr_t index) {
  return (index == kOneByteStringCid);
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

static const ClassId kFirstTypedDataCid = kTypedDataInt8ArrayCid;
static const ClassId kLastTypedDataCid =
    kUnmodifiableTypedDataFloat64x2ArrayViewCid;

// Make sure the following checks are updated when adding new TypedData types.

// The following asserts assume this.
COMPILE_ASSERT(kTypedDataCidRemainderInternal == 0);
// Ensure that each typed data type comes in internal/view/external variants
// next to each other.
COMPILE_ASSERT(kTypedDataInt8ArrayCid + kTypedDataCidRemainderView ==
               kTypedDataInt8ArrayViewCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + kTypedDataCidRemainderExternal ==
               kExternalTypedDataInt8ArrayCid);
COMPILE_ASSERT(kTypedDataInt8ArrayCid + kTypedDataCidRemainderUnmodifiable ==
               kUnmodifiableTypedDataInt8ArrayViewCid);
// Ensure the order of the typed data members in 3-step.
COMPILE_ASSERT(kFirstTypedDataCid == kTypedDataInt8ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 1 * kNumTypedDataCidRemainders ==
               kTypedDataUint8ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 2 * kNumTypedDataCidRemainders ==
               kTypedDataUint8ClampedArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 3 * kNumTypedDataCidRemainders ==
               kTypedDataInt16ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 4 * kNumTypedDataCidRemainders ==
               kTypedDataUint16ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 5 * kNumTypedDataCidRemainders ==
               kTypedDataInt32ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 6 * kNumTypedDataCidRemainders ==
               kTypedDataUint32ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 7 * kNumTypedDataCidRemainders ==
               kTypedDataInt64ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 8 * kNumTypedDataCidRemainders ==
               kTypedDataUint64ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 9 * kNumTypedDataCidRemainders ==
               kTypedDataFloat32ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 10 * kNumTypedDataCidRemainders ==
               kTypedDataFloat64ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 11 * kNumTypedDataCidRemainders ==
               kTypedDataFloat32x4ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 12 * kNumTypedDataCidRemainders ==
               kTypedDataInt32x4ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 13 * kNumTypedDataCidRemainders ==
               kTypedDataFloat64x2ArrayCid);
COMPILE_ASSERT(kFirstTypedDataCid + 13 * kNumTypedDataCidRemainders +
                   kTypedDataCidRemainderUnmodifiable ==
               kLastTypedDataCid);
// Checks for possible new typed data entries added before or after the current
// entries.
COMPILE_ASSERT(kFfiStructCid + 1 == kFirstTypedDataCid);
COMPILE_ASSERT(kLastTypedDataCid + 1 == kByteDataViewCid);

inline bool IsTypedDataBaseClassId(intptr_t index) {
  return index >= kFirstTypedDataCid && index <= kLastTypedDataCid;
}

inline bool IsTypedDataClassId(intptr_t index) {
  return IsTypedDataBaseClassId(index) &&
         ((index - kFirstTypedDataCid) % kNumTypedDataCidRemainders) ==
             kTypedDataCidRemainderInternal;
}

inline bool IsTypedDataViewClassId(intptr_t index) {
  const bool is_byte_data_view = index == kByteDataViewCid;
  return is_byte_data_view ||
         (IsTypedDataBaseClassId(index) &&
          ((index - kFirstTypedDataCid) % kNumTypedDataCidRemainders) ==
              kTypedDataCidRemainderView);
}

inline bool IsExternalTypedDataClassId(intptr_t index) {
  return IsTypedDataBaseClassId(index) &&
         ((index - kFirstTypedDataCid) % kNumTypedDataCidRemainders) ==
             kTypedDataCidRemainderExternal;
}

inline bool IsUnmodifiableTypedDataViewClassId(intptr_t index) {
  const bool is_byte_data_view = index == kUnmodifiableByteDataViewCid;
  return is_byte_data_view ||
         (IsTypedDataBaseClassId(index) &&
          ((index - kFirstTypedDataCid) % kNumTypedDataCidRemainders) ==
              kTypedDataCidRemainderUnmodifiable);
}

inline bool IsClampedTypedDataBaseClassId(intptr_t index) {
  if (!IsTypedDataBaseClassId(index)) return false;
  const intptr_t internal_cid =
      index - ((index - kFirstTypedDataCid) % kNumTypedDataCidRemainders) +
      kTypedDataCidRemainderInternal;
  // Currently, the only clamped typed data arrays are Uint8.
  return internal_cid == kTypedDataUint8ClampedArrayCid;
}

// Whether the given cid is an external array cid, that is, an array where
// the payload is not in GC-managed memory.
inline bool IsExternalPayloadClassId(classid_t cid) {
  return cid == kPointerCid || IsExternalTypedDataClassId(cid);
}

// For predefined cids only. Refer to Class::is_deeply_immutable for
// instances of non-predefined classes.
//
// Having the `@pragma('vm:deeply-immutable')`, which means statically proven
// deeply immutable, implies true for this function. The other way around is not
// guaranteed, predefined classes can be marked deeply immutable in the VM while
// not having their subtypes or super type being deeply immutable.
//
// Keep consistent with runtime/docs/deeply_immutable.md.
inline bool IsDeeplyImmutableCid(intptr_t predefined_cid) {
  ASSERT(predefined_cid < kNumPredefinedCids);
  return IsStringClassId(predefined_cid) || predefined_cid == kNumberCid ||
         predefined_cid == kIntegerCid || predefined_cid == kSmiCid ||
         predefined_cid == kMintCid || predefined_cid == kNeverCid ||
         predefined_cid == kSentinelCid || predefined_cid == kStackTraceCid ||
         predefined_cid == kDoubleCid || predefined_cid == kFloat32x4Cid ||
         predefined_cid == kFloat64x2Cid || predefined_cid == kInt32x4Cid ||
         predefined_cid == kSendPortCid || predefined_cid == kCapabilityCid ||
         predefined_cid == kRegExpCid || predefined_cid == kBoolCid ||
         predefined_cid == kNullCid || predefined_cid == kPointerCid ||
         predefined_cid == kTypeCid || predefined_cid == kRecordTypeCid ||
         predefined_cid == kFunctionTypeCid;
}

inline bool IsShallowlyImmutableCid(intptr_t predefined_cid) {
  ASSERT(predefined_cid < kNumPredefinedCids);
  return predefined_cid == kClosureCid ||
         IsUnmodifiableTypedDataViewClassId(predefined_cid);
}

// See documentation on ImmutableBit in raw_object.h
inline bool ShouldHaveImmutabilityBitSetCid(intptr_t predefined_cid) {
  ASSERT(predefined_cid < kNumPredefinedCids);
  return IsDeeplyImmutableCid(predefined_cid) ||
         IsShallowlyImmutableCid(predefined_cid);
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

COMPILE_ASSERT(kByteBufferCid + 1 == kNullCid);

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_ID_H_
