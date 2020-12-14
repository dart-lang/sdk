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

namespace dart {

// Size of the class-id part of the object header. See ObjectLayout.
typedef uint16_t ClassIdTagType;

#define CLASS_LIST_NO_OBJECT_NOR_STRING_NOR_ARRAY(V)                           \
  V(Class)                                                                     \
  V(PatchClass)                                                                \
  V(Function)                                                                  \
  V(ClosureData)                                                               \
  V(SignatureData)                                                             \
  V(FfiTrampolineData)                                                         \
  V(Field)                                                                     \
  V(Script)                                                                    \
  V(Library)                                                                   \
  V(Namespace)                                                                 \
  V(KernelProgramInfo)                                                         \
  V(Code)                                                                      \
  V(Instructions)                                                              \
  V(InstructionsSection)                                                       \
  V(ObjectPool)                                                                \
  V(PcDescriptors)                                                             \
  V(CodeSourceMap)                                                             \
  V(CompressedStackMaps)                                                       \
  V(LocalVarDescriptors)                                                       \
  V(ExceptionHandlers)                                                         \
  V(Context)                                                                   \
  V(ContextScope)                                                              \
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
  V(UnwindError)                                                               \
  V(Instance)                                                                  \
  V(LibraryPrefix)                                                             \
  V(TypeArguments)                                                             \
  V(AbstractType)                                                              \
  V(Type)                                                                      \
  V(TypeRef)                                                                   \
  V(TypeParameter)                                                             \
  V(Closure)                                                                   \
  V(Number)                                                                    \
  V(Integer)                                                                   \
  V(Smi)                                                                       \
  V(Mint)                                                                      \
  V(Double)                                                                    \
  V(Bool)                                                                      \
  V(GrowableObjectArray)                                                       \
  V(Float32x4)                                                                 \
  V(Int32x4)                                                                   \
  V(Float64x2)                                                                 \
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
  V(RegExp)                                                                    \
  V(WeakProperty)                                                              \
  V(MirrorReference)                                                           \
  V(LinkedHashMap)                                                             \
  V(FutureOr)                                                                  \
  V(UserTag)                                                                   \
  V(TransferableTypedData)                                                     \
  V(WeakSerializationReference)

#define CLASS_LIST_ARRAYS(V)                                                   \
  V(Array)                                                                     \
  V(ImmutableArray)

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

#define CLASS_LIST_FFI_NUMERIC(V)                                              \
  V(Int8)                                                                      \
  V(Int16)                                                                     \
  V(Int32)                                                                     \
  V(Int64)                                                                     \
  V(Uint8)                                                                     \
  V(Uint16)                                                                    \
  V(Uint32)                                                                    \
  V(Uint64)                                                                    \
  V(IntPtr)                                                                    \
  V(Float)                                                                     \
  V(Double)

#define CLASS_LIST_FFI_TYPE_MARKER(V)                                          \
  CLASS_LIST_FFI_NUMERIC(V)                                                    \
  V(Void)                                                                      \
  V(Handle)

#define CLASS_LIST_FFI(V)                                                      \
  V(Pointer)                                                                   \
  V(NativeFunction)                                                            \
  CLASS_LIST_FFI_TYPE_MARKER(V)                                                \
  V(NativeType)                                                                \
  V(DynamicLibrary)                                                            \
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
  CLASS_LIST_NO_OBJECT_NOR_STRING_NOR_ARRAY(V)                                 \
  V(Array)                                                                     \
  V(String)

#define CLASS_LIST_NO_OBJECT(V)                                                \
  CLASS_LIST_NO_OBJECT_NOR_STRING_NOR_ARRAY(V)                                 \
  CLASS_LIST_ARRAYS(V)                                                         \
  CLASS_LIST_STRINGS(V)

#define CLASS_LIST(V)                                                          \
  V(Object)                                                                    \
  CLASS_LIST_NO_OBJECT(V)

enum ClassId : intptr_t {
  // Illegal class id.
  kIllegalCid = 0,

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
  kExternalTypedData##clazz##Cid,
  CLASS_LIST_TYPED_DATA(DEFINE_OBJECT_KIND)
#undef DEFINE_OBJECT_KIND
  kByteDataViewCid,

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

// Class Id predicates.

bool IsErrorClassId(intptr_t index);
bool IsNumberClassId(intptr_t index);
bool IsIntegerClassId(intptr_t index);
bool IsStringClassId(intptr_t index);
bool IsOneByteStringClassId(intptr_t index);
bool IsTwoByteStringClassId(intptr_t index);
bool IsExternalStringClassId(intptr_t index);
bool IsBuiltinListClassId(intptr_t index);
bool IsTypedDataBaseClassId(intptr_t index);
bool IsTypedDataClassId(intptr_t index);
bool IsTypedDataViewClassId(intptr_t index);
bool IsExternalTypedDataClassId(intptr_t index);
bool IsFfiNativeTypeTypeClassId(intptr_t index);
bool IsFfiPointerClassId(intptr_t index);
bool IsFfiTypeClassId(intptr_t index);
bool IsFfiTypeIntClassId(intptr_t index);
bool IsFfiTypeDoubleClassId(intptr_t index);
bool IsFfiTypeVoidClassId(intptr_t index);
bool IsFfiTypeNativeFunctionClassId(intptr_t index);
bool IsFfiDynamicLibraryClassId(intptr_t index);
bool IsFfiClassId(intptr_t index);
bool IsInternalVMdefinedClassId(intptr_t index);
bool IsVariableSizeClassId(intptr_t index);
bool IsImplicitFieldClassId(intptr_t index);
intptr_t NumberOfTypedDataClasses();

inline bool IsErrorClassId(intptr_t index) {
  // Make sure this function is updated when new Error types are added.
  COMPILE_ASSERT(
      kApiErrorCid == kErrorCid + 1 && kLanguageErrorCid == kErrorCid + 2 &&
      kUnhandledExceptionCid == kErrorCid + 3 &&
      kUnwindErrorCid == kErrorCid + 4 && kInstanceCid == kErrorCid + 5);
  return (index >= kErrorCid && index < kInstanceCid);
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

inline bool IsStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index >= kStringCid && index <= kExternalTwoByteStringCid);
}

inline bool IsOneByteStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index == kOneByteStringCid || index == kExternalOneByteStringCid);
}

inline bool IsTwoByteStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index == kTwoByteStringCid || index == kExternalTwoByteStringCid);
}

inline bool IsExternalStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index == kExternalOneByteStringCid ||
          index == kExternalTwoByteStringCid);
}

inline bool IsBuiltinListClassId(intptr_t index) {
  // Make sure this function is updated when new builtin List types are added.
  COMPILE_ASSERT(kImmutableArrayCid == kArrayCid + 1);
  return ((index >= kArrayCid && index <= kImmutableArrayCid) ||
          (index == kGrowableObjectArrayCid) || IsTypedDataBaseClassId(index) ||
          (index == kByteBufferCid));
}

inline bool IsTypedDataBaseClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 3 == kTypedDataUint8ArrayCid);
  return index >= kTypedDataInt8ArrayCid && index < kByteDataViewCid;
}

inline bool IsTypedDataClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 3 == kTypedDataUint8ArrayCid);
  return IsTypedDataBaseClassId(index) && ((index - kTypedDataInt8ArrayCid) %
                                           3) == kTypedDataCidRemainderInternal;
}

inline bool IsTypedDataViewClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kTypedDataInt8ArrayViewCid + 3 == kTypedDataUint8ArrayViewCid);

  const bool is_byte_data_view = index == kByteDataViewCid;
  return is_byte_data_view ||
         (IsTypedDataBaseClassId(index) &&
          ((index - kTypedDataInt8ArrayCid) % 3) == kTypedDataCidRemainderView);
}

inline bool IsExternalTypedDataClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kExternalTypedDataInt8ArrayCid + 3 ==
                 kExternalTypedDataUint8ArrayCid);

  return IsTypedDataBaseClassId(index) && ((index - kTypedDataInt8ArrayCid) %
                                           3) == kTypedDataCidRemainderExternal;
}

inline bool IsFfiNativeTypeTypeClassId(intptr_t index) {
  return index == kFfiNativeTypeCid;
}

inline bool IsFfiTypeClassId(intptr_t index) {
  switch (index) {
    case kFfiPointerCid:
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
#define CASE_FFI_CID(name) case kFfi##name##Cid:
    CLASS_LIST_FFI(CASE_FFI_CID)
#undef CASE_FFI_CID
    return true;
    default:
      return false;
  }
  UNREACHABLE();
}

inline bool IsFfiTypeIntClassId(intptr_t index) {
  return (index >= kFfiInt8Cid && index <= kFfiIntPtrCid);
}

inline bool IsFfiTypeDoubleClassId(intptr_t index) {
  return (index >= kFfiFloatCid && index <= kFfiDoubleCid);
}

inline bool IsFfiPointerClassId(intptr_t index) {
  return index == kFfiPointerCid;
}

inline bool IsFfiTypeVoidClassId(intptr_t index) {
  return index == kFfiVoidCid;
}

inline bool IsFfiTypeNativeFunctionClassId(intptr_t index) {
  return index == kFfiNativeFunctionCid;
}

inline bool IsFfiClassId(intptr_t index) {
  return (index >= kFfiPointerCid && index <= kFfiVoidCid);
}

inline bool IsFfiDynamicLibraryClassId(intptr_t index) {
  return index == kFfiDynamicLibraryCid;
}

inline bool IsInternalVMdefinedClassId(intptr_t index) {
  return ((index < kNumPredefinedCids) && !IsImplicitFieldClassId(index));
}

inline bool IsVariableSizeClassId(intptr_t index) {
  return (index == kArrayCid) || (index == kImmutableArrayCid) ||
         IsOneByteStringClassId(index) || IsTwoByteStringClassId(index) ||
         IsTypedDataClassId(index) || (index == kContextCid) ||
         (index == kTypeArgumentsCid) || (index == kInstructionsCid) ||
         (index == kInstructionsSectionCid) || (index == kObjectPoolCid) ||
         (index == kPcDescriptorsCid) || (index == kCodeSourceMapCid) ||
         (index == kCompressedStackMapsCid) ||
         (index == kLocalVarDescriptorsCid) ||
         (index == kExceptionHandlersCid) || (index == kCodeCid) ||
         (index == kContextScopeCid) || (index == kInstanceCid) ||
         (index == kRegExpCid);
}

// This is a set of classes that are not Dart classes whose representation
// is defined by the VM but are used in the VM code by computing the
// implicit field offsets of the various fields in the dart object.
inline bool IsImplicitFieldClassId(intptr_t index) {
  return index == kByteBufferCid;
}

inline intptr_t NumberOfTypedDataClasses() {
  // Make sure this is updated when new TypedData types are added.

  // Ensure that each typed data type comes in internal/view/external variants
  // next to each other.
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 1 == kTypedDataInt8ArrayViewCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 2 == kExternalTypedDataInt8ArrayCid);

  // Ensure the order of the typed data members in 3-step.
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 1 * 3 == kTypedDataUint8ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 2 * 3 ==
                 kTypedDataUint8ClampedArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 3 * 3 == kTypedDataInt16ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 4 * 3 == kTypedDataUint16ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 5 * 3 == kTypedDataInt32ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 6 * 3 == kTypedDataUint32ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 7 * 3 == kTypedDataInt64ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 8 * 3 == kTypedDataUint64ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 9 * 3 == kTypedDataFloat32ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 10 * 3 == kTypedDataFloat64ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 11 * 3 ==
                 kTypedDataFloat32x4ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 12 * 3 == kTypedDataInt32x4ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 13 * 3 ==
                 kTypedDataFloat64x2ArrayCid);
  COMPILE_ASSERT(kTypedDataInt8ArrayCid + 14 * 3 == kByteDataViewCid);
  COMPILE_ASSERT(kByteBufferCid + 1 == kNullCid);
  return (kNullCid - kTypedDataInt8ArrayCid);
}

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_ID_H_
