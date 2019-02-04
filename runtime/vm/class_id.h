// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLASS_ID_H_
#define RUNTIME_VM_CLASS_ID_H_

// This header defines the list of VM implementation classes and their ids.
//
// Note: we assume that all builds of Dart VM use exactly the same class ids
// for these classes.

namespace dart {

#define CLASS_LIST_NO_OBJECT_NOR_STRING_NOR_ARRAY(V)                           \
  V(Class)                                                                     \
  V(PatchClass)                                                                \
  V(Function)                                                                  \
  V(ClosureData)                                                               \
  V(SignatureData)                                                             \
  V(RedirectionData)                                                           \
  V(Field)                                                                     \
  V(Script)                                                                    \
  V(Library)                                                                   \
  V(Namespace)                                                                 \
  V(KernelProgramInfo)                                                         \
  V(Code)                                                                      \
  V(Bytecode)                                                                  \
  V(Instructions)                                                              \
  V(ObjectPool)                                                                \
  V(PcDescriptors)                                                             \
  V(CodeSourceMap)                                                             \
  V(StackMap)                                                                  \
  V(LocalVarDescriptors)                                                       \
  V(ExceptionHandlers)                                                         \
  V(Context)                                                                   \
  V(ContextScope)                                                              \
  V(SingleTargetCache)                                                         \
  V(UnlinkedCall)                                                              \
  V(ICData)                                                                    \
  V(MegamorphicCache)                                                          \
  V(SubtypeTestCache)                                                          \
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
  V(TypedData)                                                                 \
  V(ExternalTypedData)                                                         \
  V(Capability)                                                                \
  V(ReceivePort)                                                               \
  V(SendPort)                                                                  \
  V(StackTrace)                                                                \
  V(RegExp)                                                                    \
  V(WeakProperty)                                                              \
  V(MirrorReference)                                                           \
  V(LinkedHashMap)                                                             \
  V(UserTag)

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

enum ClassId {
  // Illegal class id.
  kIllegalCid = 0,

  // A sentinel used by the vm service's heap snapshots to represent references
  // from the stack.
  kStackCid = 1,

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
#define DEFINE_OBJECT_KIND(clazz) kTypedData##clazz##Cid,
  CLASS_LIST_TYPED_DATA(DEFINE_OBJECT_KIND)
#undef DEFINE_OBJECT_KIND

#define DEFINE_OBJECT_KIND(clazz) kTypedData##clazz##ViewCid,
  CLASS_LIST_TYPED_DATA(DEFINE_OBJECT_KIND)
#undef DEFINE_OBJECT_KIND

  kByteDataViewCid,

#define DEFINE_OBJECT_KIND(clazz) kExternalTypedData##clazz##Cid,
  CLASS_LIST_TYPED_DATA(DEFINE_OBJECT_KIND)
#undef DEFINE_OBJECT_KIND

  kByteBufferCid,
  // clang-format on

  // The following entries do not describe a predefined class, but instead
  // are class indexes for pre-allocated instances (Null, dynamic and Void).
  kNullCid,
  kDynamicCid,
  kVoidCid,

  kNumPredefinedCids,
};

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_ID_H_
