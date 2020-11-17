// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TAGGED_POINTER_H_
#define RUNTIME_VM_TAGGED_POINTER_H_

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/class_id.h"
#include "vm/pointer_tagging.h"

namespace dart {

class IsolateGroup;
class ObjectLayout;

class ObjectPtr {
 public:
  ObjectPtr* operator->() { return this; }
  const ObjectPtr* operator->() const { return this; }
  ObjectLayout* ptr() const {
    return reinterpret_cast<ObjectLayout*>(UntaggedPointer());
  }

  bool IsWellFormed() const {
    uword value = tagged_pointer_;
    return (value & kSmiTagMask) == 0 ||
           Utils::IsAligned(value - kHeapObjectTag, kWordSize);
  }
  bool IsHeapObject() const {
    ASSERT(IsWellFormed());
    uword value = tagged_pointer_;
    return (value & kSmiTagMask) == kHeapObjectTag;
  }
  // Assumes this is a heap object.
  bool IsNewObject() const {
    ASSERT(IsHeapObject());
    uword addr = tagged_pointer_;
    return (addr & kNewObjectAlignmentOffset) == kNewObjectAlignmentOffset;
  }
  bool IsNewObjectMayBeSmi() const {
    static const uword kNewObjectBits =
        (kNewObjectAlignmentOffset | kHeapObjectTag);
    const uword addr = tagged_pointer_;
    return (addr & kObjectAlignmentMask) == kNewObjectBits;
  }
  // Assumes this is a heap object.
  bool IsOldObject() const {
    ASSERT(IsHeapObject());
    uword addr = tagged_pointer_;
    return (addr & kNewObjectAlignmentOffset) == kOldObjectAlignmentOffset;
  }

  // Like !IsHeapObject() || IsOldObject(), but compiles to a single branch.
  bool IsSmiOrOldObject() const {
    ASSERT(IsWellFormed());
    static const uword kNewObjectBits =
        (kNewObjectAlignmentOffset | kHeapObjectTag);
    const uword addr = tagged_pointer_;
    return (addr & kObjectAlignmentMask) != kNewObjectBits;
  }

  // Like !IsHeapObject() || IsNewObject(), but compiles to a single branch.
  bool IsSmiOrNewObject() const {
    ASSERT(IsWellFormed());
    static const uword kOldObjectBits =
        (kOldObjectAlignmentOffset | kHeapObjectTag);
    const uword addr = tagged_pointer_;
    return (addr & kObjectAlignmentMask) != kOldObjectBits;
  }

#define DEFINE_IS_CID(clazz)                                                   \
  bool Is##clazz() const { return ((GetClassId() == k##clazz##Cid)); }
  CLASS_LIST(DEFINE_IS_CID)
#undef DEFINE_IS_CID

#define DEFINE_IS_CID(clazz)                                                   \
  bool IsTypedData##clazz() const {                                            \
    return ((GetClassId() == kTypedData##clazz##Cid));                         \
  }                                                                            \
  bool IsTypedDataView##clazz() const {                                        \
    return ((GetClassId() == kTypedData##clazz##ViewCid));                     \
  }                                                                            \
  bool IsExternalTypedData##clazz() const {                                    \
    return ((GetClassId() == kExternalTypedData##clazz##Cid));                 \
  }
  CLASS_LIST_TYPED_DATA(DEFINE_IS_CID)
#undef DEFINE_IS_CID

#define DEFINE_IS_CID(clazz)                                                   \
  bool IsFfi##clazz() const { return ((GetClassId() == kFfi##clazz##Cid)); }
  CLASS_LIST_FFI(DEFINE_IS_CID)
#undef DEFINE_IS_CID

  bool IsStringInstance() const { return IsStringClassId(GetClassId()); }
  bool IsRawNull() const { return GetClassId() == kNullCid; }
  bool IsDartInstance() const {
    return (!IsHeapObject() || (GetClassId() >= kInstanceCid));
  }
  bool IsFreeListElement() const {
    return ((GetClassId() == kFreeListElement));
  }
  bool IsForwardingCorpse() const {
    return ((GetClassId() == kForwardingCorpse));
  }
  bool IsPseudoObject() const {
    return IsFreeListElement() || IsForwardingCorpse();
  }

  intptr_t GetClassId() const;
  intptr_t GetClassIdMayBeSmi() const {
    return IsHeapObject() ? GetClassId() : static_cast<intptr_t>(kSmiCid);
  }

  void Validate(IsolateGroup* isolate_group) const;

  bool operator==(const ObjectPtr& other) {
    return tagged_pointer_ == other.tagged_pointer_;
  }
  bool operator!=(const ObjectPtr& other) {
    return tagged_pointer_ != other.tagged_pointer_;
  }
  constexpr bool operator==(const ObjectPtr& other) const {
    return tagged_pointer_ == other.tagged_pointer_;
  }
  constexpr bool operator!=(const ObjectPtr& other) const {
    return tagged_pointer_ != other.tagged_pointer_;
  }
  bool operator==(const std::nullptr_t& other) { return tagged_pointer_ == 0; }
  bool operator!=(const std::nullptr_t& other) { return tagged_pointer_ != 0; }
  constexpr bool operator==(const std::nullptr_t& other) const {
    return tagged_pointer_ == 0;
  }
  constexpr bool operator!=(const std::nullptr_t& other) const {
    return tagged_pointer_ != 0;
  }

  // Use explicit null comparisons instead.
  operator bool() const = delete;

  // The underlying types of int32_t/int64_t and intptr_t are sometimes
  // different and sometimes the same, depending on the platform. With
  // only a conversion operator for intptr_t, on 64-bit Mac a static_cast
  // to int64_t fails because it tries conversion to bool (!) rather than
  // intptr_t. So we exhaustive define all the valid conversions based on
  // the underlying types.
#if INT_MAX == INTPTR_MAX
  explicit operator int() const {              // NOLINT
    return static_cast<int>(tagged_pointer_);  // NOLINT
  }
#endif
#if LONG_MAX == INTPTR_MAX
  explicit operator long() const {              // NOLINT
    return static_cast<long>(tagged_pointer_);  // NOLINT
  }
#endif
#if LLONG_MAX == INTPTR_MAX
  explicit operator long long() const {              // NOLINT
    return static_cast<long long>(tagged_pointer_);  // NOLINT
  }
#endif
#if UINT_MAX == UINTPTR_MAX
  explicit operator unsigned int() const {              // NOLINT
    return static_cast<unsigned int>(tagged_pointer_);  // NOLINT
  }
#endif
#if ULONG_MAX == UINTPTR_MAX
  explicit operator unsigned long() const {              // NOLINT
    return static_cast<unsigned long>(tagged_pointer_);  // NOLINT
  }
#endif
#if ULLONG_MAX == UINTPTR_MAX
  explicit operator unsigned long long() const {              // NOLINT
    return static_cast<unsigned long long>(tagged_pointer_);  // NOLINT
  }
#endif

  // Must be trivially copyable for std::atomic.
  ObjectPtr& operator=(const ObjectPtr& other) = default;
  constexpr ObjectPtr(const ObjectPtr& other) = default;

  ObjectPtr() : tagged_pointer_(0) {}
  explicit constexpr ObjectPtr(uword tagged) : tagged_pointer_(tagged) {}
  explicit constexpr ObjectPtr(intptr_t tagged) : tagged_pointer_(tagged) {}
  constexpr ObjectPtr(std::nullptr_t) : tagged_pointer_(0) {}  // NOLINT
  explicit ObjectPtr(ObjectLayout* heap_object)
      : tagged_pointer_(reinterpret_cast<uword>(heap_object) + kHeapObjectTag) {
  }

 protected:
  uword UntaggedPointer() const {
    ASSERT(IsHeapObject());
    return tagged_pointer_ - kHeapObjectTag;
  }

  uword tagged_pointer_;
};

// Needed by the printing in the EXPECT macros.
#if defined(DEBUG) || defined(TESTING)
inline std::ostream& operator<<(std::ostream& os, const ObjectPtr& obj) {
  os << reinterpret_cast<void*>(static_cast<uword>(obj));
  return os;
}
#endif

#define DEFINE_TAGGED_POINTER(klass, base)                                     \
  class klass##Layout;                                                         \
  class klass##Ptr : public base##Ptr {                                        \
   public:                                                                     \
    klass##Ptr* operator->() { return this; }                                  \
    const klass##Ptr* operator->() const { return this; }                      \
    klass##Layout* ptr() {                                                     \
      return reinterpret_cast<klass##Layout*>(UntaggedPointer());              \
    }                                                                          \
    /* TODO: Return const pointer */                                           \
    klass##Layout* ptr() const {                                               \
      return reinterpret_cast<klass##Layout*>(UntaggedPointer());              \
    }                                                                          \
    klass##Ptr& operator=(const klass##Ptr& other) = default;                  \
    constexpr klass##Ptr(const klass##Ptr& other) = default;                   \
    explicit constexpr klass##Ptr(const ObjectPtr& other)                      \
        : base##Ptr(other) {}                                                  \
    klass##Ptr() : base##Ptr() {}                                              \
    explicit constexpr klass##Ptr(uword tagged) : base##Ptr(tagged) {}         \
    constexpr klass##Ptr(std::nullptr_t) : base##Ptr(nullptr) {} /* NOLINT */  \
    explicit klass##Ptr(const ObjectLayout* untagged)                          \
        : base##Ptr(reinterpret_cast<uword>(untagged) + kHeapObjectTag) {}     \
  };

DEFINE_TAGGED_POINTER(Class, Object)
DEFINE_TAGGED_POINTER(PatchClass, Object)
DEFINE_TAGGED_POINTER(Function, Object)
DEFINE_TAGGED_POINTER(ClosureData, Object)
DEFINE_TAGGED_POINTER(SignatureData, Object)
DEFINE_TAGGED_POINTER(FfiTrampolineData, Object)
DEFINE_TAGGED_POINTER(Field, Object)
DEFINE_TAGGED_POINTER(Script, Object)
DEFINE_TAGGED_POINTER(Library, Object)
DEFINE_TAGGED_POINTER(Namespace, Object)
DEFINE_TAGGED_POINTER(KernelProgramInfo, Object)
DEFINE_TAGGED_POINTER(WeakSerializationReference, Object)
DEFINE_TAGGED_POINTER(Code, Object)
DEFINE_TAGGED_POINTER(ObjectPool, Object)
DEFINE_TAGGED_POINTER(Instructions, Object)
DEFINE_TAGGED_POINTER(InstructionsSection, Object)
DEFINE_TAGGED_POINTER(PcDescriptors, Object)
DEFINE_TAGGED_POINTER(CodeSourceMap, Object)
DEFINE_TAGGED_POINTER(CompressedStackMaps, Object)
DEFINE_TAGGED_POINTER(LocalVarDescriptors, Object)
DEFINE_TAGGED_POINTER(ExceptionHandlers, Object)
DEFINE_TAGGED_POINTER(Context, Object)
DEFINE_TAGGED_POINTER(ContextScope, Object)
DEFINE_TAGGED_POINTER(SingleTargetCache, Object)
DEFINE_TAGGED_POINTER(UnlinkedCall, Object)
DEFINE_TAGGED_POINTER(MonomorphicSmiableCall, Object)
DEFINE_TAGGED_POINTER(CallSiteData, Object)
DEFINE_TAGGED_POINTER(ICData, CallSiteData)
DEFINE_TAGGED_POINTER(MegamorphicCache, CallSiteData)
DEFINE_TAGGED_POINTER(SubtypeTestCache, Object)
DEFINE_TAGGED_POINTER(LoadingUnit, Object)
DEFINE_TAGGED_POINTER(Error, Object)
DEFINE_TAGGED_POINTER(ApiError, Error)
DEFINE_TAGGED_POINTER(LanguageError, Error)
DEFINE_TAGGED_POINTER(UnhandledException, Error)
DEFINE_TAGGED_POINTER(UnwindError, Error)
DEFINE_TAGGED_POINTER(Instance, Object)
DEFINE_TAGGED_POINTER(LibraryPrefix, Instance)
DEFINE_TAGGED_POINTER(TypeArguments, Instance)
DEFINE_TAGGED_POINTER(AbstractType, Instance)
DEFINE_TAGGED_POINTER(Type, AbstractType)
DEFINE_TAGGED_POINTER(TypeRef, AbstractType)
DEFINE_TAGGED_POINTER(TypeParameter, AbstractType)
DEFINE_TAGGED_POINTER(Closure, Instance)
DEFINE_TAGGED_POINTER(Number, Instance)
DEFINE_TAGGED_POINTER(Integer, Number)
DEFINE_TAGGED_POINTER(Smi, Integer)
DEFINE_TAGGED_POINTER(Mint, Integer)
DEFINE_TAGGED_POINTER(Double, Number)
DEFINE_TAGGED_POINTER(String, Instance)
DEFINE_TAGGED_POINTER(OneByteString, String)
DEFINE_TAGGED_POINTER(TwoByteString, String)
DEFINE_TAGGED_POINTER(PointerBase, Instance)
DEFINE_TAGGED_POINTER(TypedDataBase, PointerBase)
DEFINE_TAGGED_POINTER(TypedData, TypedDataBase)
DEFINE_TAGGED_POINTER(TypedDataView, TypedDataBase)
DEFINE_TAGGED_POINTER(ExternalOneByteString, String)
DEFINE_TAGGED_POINTER(ExternalTwoByteString, String)
DEFINE_TAGGED_POINTER(Bool, Instance)
DEFINE_TAGGED_POINTER(Array, Instance)
DEFINE_TAGGED_POINTER(ImmutableArray, Array)
DEFINE_TAGGED_POINTER(GrowableObjectArray, Instance)
DEFINE_TAGGED_POINTER(LinkedHashMap, Instance)
DEFINE_TAGGED_POINTER(Float32x4, Instance)
DEFINE_TAGGED_POINTER(Int32x4, Instance)
DEFINE_TAGGED_POINTER(Float64x2, Instance)
DEFINE_TAGGED_POINTER(ExternalTypedData, TypedDataBase)
DEFINE_TAGGED_POINTER(Pointer, PointerBase)
DEFINE_TAGGED_POINTER(DynamicLibrary, Instance)
DEFINE_TAGGED_POINTER(Capability, Instance)
DEFINE_TAGGED_POINTER(SendPort, Instance)
DEFINE_TAGGED_POINTER(ReceivePort, Instance)
DEFINE_TAGGED_POINTER(TransferableTypedData, Instance)
DEFINE_TAGGED_POINTER(StackTrace, Instance)
DEFINE_TAGGED_POINTER(RegExp, Instance)
DEFINE_TAGGED_POINTER(WeakProperty, Instance)
DEFINE_TAGGED_POINTER(MirrorReference, Instance)
DEFINE_TAGGED_POINTER(UserTag, Instance)
DEFINE_TAGGED_POINTER(FutureOr, Instance)
#undef DEFINE_TAGGED_POINTER

inline intptr_t RawSmiValue(const SmiPtr raw_value) {
  const intptr_t value = static_cast<intptr_t>(raw_value);
  ASSERT((value & kSmiTagMask) == kSmiTag);
  return (value >> kSmiTagShift);
}

}  // namespace dart

#endif  // RUNTIME_VM_TAGGED_POINTER_H_
