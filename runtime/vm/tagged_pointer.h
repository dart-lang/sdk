// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TAGGED_POINTER_H_
#define RUNTIME_VM_TAGGED_POINTER_H_

#include <type_traits>
#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/class_id.h"
#include "vm/globals.h"
#include "vm/pointer_tagging.h"

namespace dart {

class IsolateGroup;
class UntaggedObject;

#define OBJECT_POINTER_CORE_FUNCTIONS(type, ptr)                               \
  type* operator->() {                                                         \
    return this;                                                               \
  }                                                                            \
  const type* operator->() const {                                             \
    return this;                                                               \
  }                                                                            \
  bool IsWellFormed() const {                                                  \
    const uword value = ptr;                                                   \
    return (value & kSmiTagMask) == 0 ||                                       \
           Utils::IsAligned(value - kHeapObjectTag, kWordSize);                \
  }                                                                            \
  bool IsHeapObject() const {                                                  \
    ASSERT(IsWellFormed());                                                    \
    const uword value = ptr;                                                   \
    return (value & kSmiTagMask) == kHeapObjectTag;                            \
  }                                                                            \
  /* Assumes this is a heap object. */                                         \
  bool IsNewObject() const {                                                   \
    ASSERT(IsHeapObject());                                                    \
    const uword addr = ptr;                                                    \
    return (addr & kNewObjectAlignmentOffset) == kNewObjectAlignmentOffset;    \
  }                                                                            \
  bool IsNewObjectMayBeSmi() const {                                           \
    const uword kNewObjectBits = (kNewObjectAlignmentOffset | kHeapObjectTag); \
    const uword addr = ptr;                                                    \
    return (addr & kObjectAlignmentMask) == kNewObjectBits;                    \
  }                                                                            \
  /* Assumes this is a heap object. */                                         \
  bool IsOldObject() const {                                                   \
    ASSERT(IsHeapObject());                                                    \
    const uword addr = ptr;                                                    \
    return (addr & kNewObjectAlignmentOffset) == kOldObjectAlignmentOffset;    \
  }                                                                            \
                                                                               \
  /* Like !IsHeapObject() || IsOldObject() but compiles to a single branch. */ \
  bool IsSmiOrOldObject() const {                                              \
    ASSERT(IsWellFormed());                                                    \
    const uword kNewObjectBits = (kNewObjectAlignmentOffset | kHeapObjectTag); \
    const uword addr = ptr;                                                    \
    return (addr & kObjectAlignmentMask) != kNewObjectBits;                    \
  }                                                                            \
                                                                               \
  /* Like !IsHeapObject() || IsNewObject() but compiles to a single branch. */ \
  bool IsSmiOrNewObject() const {                                              \
    ASSERT(IsWellFormed());                                                    \
    const uword kOldObjectBits = (kOldObjectAlignmentOffset | kHeapObjectTag); \
    const uword addr = ptr;                                                    \
    return (addr & kObjectAlignmentMask) != kOldObjectBits;                    \
  }                                                                            \
                                                                               \
  bool operator==(const type& other) {                                         \
    return (ptr & kSmiTagMask) == kHeapObjectTag                               \
               ? ptr == other.ptr                                              \
               : static_cast<compressed_uword>(ptr) ==                         \
                     static_cast<compressed_uword>(other.ptr);                 \
  }                                                                            \
  bool operator!=(const type& other) {                                         \
    return (ptr & kSmiTagMask) == kHeapObjectTag                               \
               ? ptr != other.ptr                                              \
               : static_cast<compressed_uword>(ptr) !=                         \
                     static_cast<compressed_uword>(other.ptr);                 \
  }                                                                            \
  constexpr bool operator==(const type& other) const {                         \
    return (ptr & kSmiTagMask) == kHeapObjectTag                               \
               ? ptr == other.ptr                                              \
               : static_cast<compressed_uword>(ptr) ==                         \
                     static_cast<compressed_uword>(other.ptr);                 \
  }                                                                            \
  constexpr bool operator!=(const type& other) const {                         \
    return (ptr & kSmiTagMask) == kHeapObjectTag                               \
               ? ptr != other.ptr                                              \
               : static_cast<compressed_uword>(ptr) !=                         \
                     static_cast<compressed_uword>(other.ptr);                 \
  }

class ObjectPtr {
 public:
  OBJECT_POINTER_CORE_FUNCTIONS(ObjectPtr, tagged_pointer_)

  UntaggedObject* untag() const {
    return reinterpret_cast<UntaggedObject*>(untagged_pointer());
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
  bool IsUnmodifiableTypedDataView##clazz() const {                            \
    return ((GetClassId() == kUnmodifiableTypedData##clazz##ViewCid));         \
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
    return (!IsHeapObject() || !IsInternalOnlyClassId(GetClassId()));
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
  explicit ObjectPtr(UntaggedObject* heap_object)
      : tagged_pointer_(reinterpret_cast<uword>(heap_object) + kHeapObjectTag) {
  }

  ObjectPtr Decompress(uword heap_base) const { return *this; }
  ObjectPtr DecompressSmi() const { return *this; }
  uword heap_base() const {
    // TODO(rmacnak): Why does Windows have trouble linking GetClassId used
    // here?
#if !defined(DART_HOST_OS_WINDOWS)
    ASSERT(IsHeapObject());
    ASSERT(!IsInstructions());
    ASSERT(!IsInstructionsSection());
#endif
    return tagged_pointer_ & kHeapBaseMask;
  }

 protected:
  uword untagged_pointer() const {
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

template <typename T, typename Enable = void>
struct is_uncompressed_ptr : std::false_type {};
template <typename T>
struct is_uncompressed_ptr<
    T,
    typename std::enable_if<std::is_base_of<ObjectPtr, T>::value, void>::type>
    : std::true_type {};
template <typename T, typename Enable = void>
struct is_compressed_ptr : std::false_type {};

template <typename T, typename Enable = void>
struct base_ptr_type {
  using type =
      typename std::enable_if<is_uncompressed_ptr<T>::value, ObjectPtr>::type;
};

#if !defined(DART_COMPRESSED_POINTERS)
typedef ObjectPtr CompressedObjectPtr;
#define DEFINE_COMPRESSED_POINTER(klass, base)                                 \
  typedef klass##Ptr Compressed##klass##Ptr;
#else
class CompressedObjectPtr {
 public:
  OBJECT_POINTER_CORE_FUNCTIONS(CompressedObjectPtr, compressed_pointer_)

  explicit CompressedObjectPtr(ObjectPtr uncompressed)
      : compressed_pointer_(
            static_cast<uint32_t>(static_cast<uword>(uncompressed))) {}
  explicit constexpr CompressedObjectPtr(uword tagged)
      : compressed_pointer_(static_cast<uint32_t>(tagged)) {}

  ObjectPtr Decompress(uword heap_base) const {
    return static_cast<ObjectPtr>(static_cast<uword>(compressed_pointer_) +
                                  heap_base);
  }

  ObjectPtr DecompressSmi() const {
    ASSERT((compressed_pointer_ & kSmiTagMask) != kHeapObjectTag);
    return static_cast<ObjectPtr>(static_cast<uword>(compressed_pointer_));
  }

  const ObjectPtr& operator=(const ObjectPtr& other) {
    compressed_pointer_ = static_cast<uint32_t>(static_cast<uword>(other));
    return other;
  }

 protected:
  uint32_t compressed_pointer_;
};

template <typename T>
struct is_compressed_ptr<
    T,
    typename std::enable_if<std::is_base_of<CompressedObjectPtr, T>::value,
                            void>::type> : std::true_type {};
template <typename T>
struct base_ptr_type<
    T,
    typename std::enable_if<std::is_base_of<CompressedObjectPtr, T>::value,
                            void>::type> {
  using type = CompressedObjectPtr;
};

#define DEFINE_COMPRESSED_POINTER(klass, base)                                 \
  class Compressed##klass##Ptr : public Compressed##base##Ptr {                \
   public:                                                                     \
    explicit Compressed##klass##Ptr(klass##Ptr uncompressed)                   \
        : Compressed##base##Ptr(uncompressed) {}                               \
    const klass##Ptr& operator=(const klass##Ptr& other) {                     \
      compressed_pointer_ = static_cast<uint32_t>(static_cast<uword>(other));  \
      return other;                                                            \
    }                                                                          \
    klass##Ptr Decompress(uword heap_base) const {                             \
      return klass##Ptr(CompressedObjectPtr::Decompress(heap_base));           \
    }                                                                          \
  };
#endif

#define DEFINE_TAGGED_POINTER(klass, base)                                     \
  class Untagged##klass;                                                       \
  class klass##Ptr : public base##Ptr {                                        \
   public:                                                                     \
    klass##Ptr* operator->() {                                                 \
      return this;                                                             \
    }                                                                          \
    const klass##Ptr* operator->() const {                                     \
      return this;                                                             \
    }                                                                          \
    Untagged##klass* untag() {                                                 \
      return reinterpret_cast<Untagged##klass*>(untagged_pointer());           \
    }                                                                          \
    /* TODO: Return const pointer */                                           \
    Untagged##klass* untag() const {                                           \
      return reinterpret_cast<Untagged##klass*>(untagged_pointer());           \
    }                                                                          \
    klass##Ptr& operator=(const klass##Ptr& other) = default;                  \
    constexpr klass##Ptr(const klass##Ptr& other) = default;                   \
    explicit constexpr klass##Ptr(const ObjectPtr& other)                      \
        : base##Ptr(other) {}                                                  \
    klass##Ptr() : base##Ptr() {}                                              \
    explicit constexpr klass##Ptr(uword tagged) : base##Ptr(tagged) {}         \
    explicit constexpr klass##Ptr(intptr_t tagged) : base##Ptr(tagged) {}      \
    constexpr klass##Ptr(std::nullptr_t) : base##Ptr(nullptr) {} /* NOLINT */  \
    explicit klass##Ptr(const UntaggedObject* untagged)                        \
        : base##Ptr(reinterpret_cast<uword>(untagged) + kHeapObjectTag) {}     \
    klass##Ptr Decompress(uword heap_base) const {                             \
      return *this;                                                            \
    }                                                                          \
  };                                                                           \
  DEFINE_COMPRESSED_POINTER(klass, base)

DEFINE_TAGGED_POINTER(Class, Object)
DEFINE_TAGGED_POINTER(PatchClass, Object)
DEFINE_TAGGED_POINTER(Function, Object)
DEFINE_TAGGED_POINTER(ClosureData, Object)
DEFINE_TAGGED_POINTER(FfiTrampolineData, Object)
DEFINE_TAGGED_POINTER(Field, Object)
DEFINE_TAGGED_POINTER(Script, Object)
DEFINE_TAGGED_POINTER(Library, Object)
DEFINE_TAGGED_POINTER(Namespace, Object)
DEFINE_TAGGED_POINTER(KernelProgramInfo, Object)
DEFINE_TAGGED_POINTER(WeakSerializationReference, Object)
DEFINE_TAGGED_POINTER(WeakArray, Object)
DEFINE_TAGGED_POINTER(Code, Object)
DEFINE_TAGGED_POINTER(ObjectPool, Object)
DEFINE_TAGGED_POINTER(Instructions, Object)
DEFINE_TAGGED_POINTER(InstructionsSection, Object)
DEFINE_TAGGED_POINTER(InstructionsTable, Object)
DEFINE_TAGGED_POINTER(PcDescriptors, Object)
DEFINE_TAGGED_POINTER(CodeSourceMap, Object)
DEFINE_TAGGED_POINTER(CompressedStackMaps, Object)
DEFINE_TAGGED_POINTER(LocalVarDescriptors, Object)
DEFINE_TAGGED_POINTER(ExceptionHandlers, Object)
DEFINE_TAGGED_POINTER(Context, Object)
DEFINE_TAGGED_POINTER(ContextScope, Object)
DEFINE_TAGGED_POINTER(Sentinel, Object)
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
DEFINE_TAGGED_POINTER(TypeParameters, Object)
DEFINE_TAGGED_POINTER(AbstractType, Instance)
DEFINE_TAGGED_POINTER(Type, AbstractType)
DEFINE_TAGGED_POINTER(FunctionType, AbstractType)
DEFINE_TAGGED_POINTER(RecordType, AbstractType)
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
DEFINE_TAGGED_POINTER(Record, Instance)
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
DEFINE_TAGGED_POINTER(LinkedHashBase, Instance)
DEFINE_TAGGED_POINTER(Map, LinkedHashBase)
DEFINE_TAGGED_POINTER(Set, LinkedHashBase)
DEFINE_TAGGED_POINTER(ConstMap, Map)
DEFINE_TAGGED_POINTER(ConstSet, Set)
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
DEFINE_TAGGED_POINTER(SuspendState, Instance)
DEFINE_TAGGED_POINTER(RegExp, Instance)
DEFINE_TAGGED_POINTER(WeakProperty, Instance)
DEFINE_TAGGED_POINTER(WeakReference, Instance)
DEFINE_TAGGED_POINTER(FinalizerBase, Instance)
DEFINE_TAGGED_POINTER(Finalizer, Instance)
DEFINE_TAGGED_POINTER(FinalizerEntry, Instance)
DEFINE_TAGGED_POINTER(NativeFinalizer, Instance)
DEFINE_TAGGED_POINTER(MirrorReference, Instance)
DEFINE_TAGGED_POINTER(UserTag, Instance)
DEFINE_TAGGED_POINTER(FutureOr, Instance)
#undef DEFINE_TAGGED_POINTER

inline intptr_t RawSmiValue(const SmiPtr raw_value) {
#if !defined(DART_COMPRESSED_POINTERS)
  const intptr_t value = static_cast<intptr_t>(raw_value);
#else
  const intptr_t value = static_cast<intptr_t>(static_cast<int32_t>(
      static_cast<uint32_t>(static_cast<uintptr_t>(raw_value))));
#endif
  ASSERT((value & kSmiTagMask) == kSmiTag);
  return (value >> kSmiTagShift);
}

}  // namespace dart

#endif  // RUNTIME_VM_TAGGED_POINTER_H_
