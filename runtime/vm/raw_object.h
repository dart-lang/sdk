// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_RAW_OBJECT_H_
#define VM_RAW_OBJECT_H_

#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/token.h"
#include "vm/snapshot.h"

namespace dart {

// Macrobatics to define the Object hierarchy of VM implementation classes.
#define CLASS_LIST_NO_OBJECT_NOR_STRING_NOR_ARRAY(V)                           \
  V(Class)                                                                     \
  V(UnresolvedClass)                                                           \
  V(TypeArguments)                                                             \
  V(PatchClass)                                                                \
  V(Function)                                                                  \
  V(ClosureData)                                                               \
  V(RedirectionData)                                                           \
  V(Field)                                                                     \
  V(LiteralToken)                                                              \
  V(TokenStream)                                                               \
  V(Script)                                                                    \
  V(Library)                                                                   \
  V(Namespace)                                                                 \
  V(Code)                                                                      \
  V(Instructions)                                                              \
  V(PcDescriptors)                                                             \
  V(Stackmap)                                                                  \
  V(LocalVarDescriptors)                                                       \
  V(ExceptionHandlers)                                                         \
  V(DeoptInfo)                                                                 \
  V(Context)                                                                   \
  V(ContextScope)                                                              \
  V(ICData)                                                                    \
  V(MegamorphicCache)                                                          \
  V(SubtypeTestCache)                                                          \
  V(Error)                                                                     \
    V(ApiError)                                                                \
    V(LanguageError)                                                           \
    V(UnhandledException)                                                      \
    V(UnwindError)                                                             \
  V(Instance)                                                                  \
    V(LibraryPrefix)                                                           \
    V(AbstractType)                                                            \
      V(Type)                                                                  \
      V(TypeRef)                                                               \
      V(TypeParameter)                                                         \
      V(BoundedType)                                                           \
      V(MixinAppType)                                                          \
    V(Number)                                                                  \
      V(Integer)                                                               \
        V(Smi)                                                                 \
        V(Mint)                                                                \
        V(Bigint)                                                              \
      V(Double)                                                                \
    V(Bool)                                                                    \
    V(GrowableObjectArray)                                                     \
    V(Float32x4)                                                               \
    V(Int32x4)                                                                 \
    V(Float64x2)                                                               \
    V(TypedData)                                                               \
    V(ExternalTypedData)                                                       \
    V(Capability)                                                              \
    V(ReceivePort)                                                             \
    V(SendPort)                                                                \
    V(Stacktrace)                                                              \
    V(JSRegExp)                                                                \
    V(WeakProperty)                                                            \
    V(MirrorReference)                                                         \
    V(LinkedHashMap)                                                           \
    V(UserTag)                                                                 \

#define CLASS_LIST_ARRAYS(V)                                                   \
  V(Array)                                                                     \
    V(ImmutableArray)                                                          \

#define CLASS_LIST_STRINGS(V)                                                  \
  V(String)                                                                    \
    V(OneByteString)                                                           \
    V(TwoByteString)                                                           \
    V(ExternalOneByteString)                                                   \
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
  V(Float64x2Array)                                                            \

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


// Forward declarations.
class Isolate;
#define DEFINE_FORWARD_DECLARATION(clazz)                                      \
  class Raw##clazz;
CLASS_LIST(DEFINE_FORWARD_DECLARATION)
#undef DEFINE_FORWARD_DECLARATION


enum ClassId {
  // Illegal class id.
  kIllegalCid = 0,

  // List of Ids for predefined classes.
#define DEFINE_OBJECT_KIND(clazz)                                              \
  k##clazz##Cid,
CLASS_LIST(DEFINE_OBJECT_KIND)
#undef DEFINE_OBJECT_KIND

#define DEFINE_OBJECT_KIND(clazz)                                              \
  kTypedData##clazz##Cid,
CLASS_LIST_TYPED_DATA(DEFINE_OBJECT_KIND)
#undef DEFINE_OBJECT_KIND

#define DEFINE_OBJECT_KIND(clazz)                                              \
  kTypedData##clazz##ViewCid,
CLASS_LIST_TYPED_DATA(DEFINE_OBJECT_KIND)
  kByteDataViewCid,
#undef DEFINE_OBJECT_KIND

#define DEFINE_OBJECT_KIND(clazz)                                              \
  kExternalTypedData##clazz##Cid,
CLASS_LIST_TYPED_DATA(DEFINE_OBJECT_KIND)
#undef DEFINE_OBJECT_KIND

  kByteBufferCid,

  // The following entries do not describe a predefined class, but instead
  // are class indexes for pre-allocated instance (Null, dynamic and Void).
  kNullCid,
  kDynamicCid,
  kVoidCid,

  // The following entry does not describe a real class, but instead it is an
  // id which is used to identify free list elements in the heap.
  kFreeListElement,

  kNumPredefinedCids,
};

enum ObjectAlignment {
  // Alignment offsets are used to determine object age.
  kNewObjectAlignmentOffset = kWordSize,
  kOldObjectAlignmentOffset = 0,
  // Object sizes are aligned to kObjectAlignment.
  kObjectAlignment = 2 * kWordSize,
  kObjectAlignmentLog2 = kWordSizeLog2 + 1,
  kObjectAlignmentMask = kObjectAlignment - 1,
};

enum {
  kSmiTag = 0,
  kHeapObjectTag = 1,
  kSmiTagSize = 1,
  kSmiTagMask = 1,
  kSmiTagShift = 1,
};

enum {
  kInvalidObjectPointer = kHeapObjectTag,
};

enum TypedDataElementType {
#define V(name) k##name##Element,
CLASS_LIST_TYPED_DATA(V)
#undef V
};

#define SNAPSHOT_WRITER_SUPPORT()                                              \
  void WriteTo(                                                                \
      SnapshotWriter* writer, intptr_t object_id, Snapshot::Kind kind);        \
  friend class SnapshotWriter;                                                 \

#define VISITOR_SUPPORT(object)                                                \
  static intptr_t Visit##object##Pointers(Raw##object* raw_obj,                \
                                          ObjectPointerVisitor* visitor);

#define HEAP_PROFILER_SUPPORT()                                                \
  friend class HeapProfiler;                                                   \

#define RAW_OBJECT_IMPLEMENTATION(object)                                      \
 private:  /* NOLINT */                                                        \
  VISITOR_SUPPORT(object)                                                      \
  friend class object;                                                         \
  friend class RawObject;                                                      \
  friend class Heap;                                                           \
  DISALLOW_ALLOCATION();                                                       \
  DISALLOW_IMPLICIT_CONSTRUCTORS(Raw##object)

#define RAW_HEAP_OBJECT_IMPLEMENTATION(object)                                 \
  private:                                                                     \
    RAW_OBJECT_IMPLEMENTATION(object);                                         \
    Raw##object* ptr() const {                                                 \
      ASSERT(IsHeapObject());                                                  \
      return reinterpret_cast<Raw##object*>(                                   \
          reinterpret_cast<uword>(this) - kHeapObjectTag);                     \
    }                                                                          \
    SNAPSHOT_WRITER_SUPPORT()                                                  \
    HEAP_PROFILER_SUPPORT()                                                    \

#define OPEN_ARRAY_START(type, align)                                          \
  do {                                                                         \
    const uword result = reinterpret_cast<uword>(this) + sizeof(*this);        \
    ASSERT(Utils::IsAligned(result, sizeof(align)));                           \
    return reinterpret_cast<type*>(result);                                    \
  } while (0)

// RawObject is the base class of all raw objects, even though it carries the
// class_ field not all raw objects are allocated in the heap and thus cannot
// be dereferenced (e.g. RawSmi).
class RawObject {
 public:
  // The tags field which is a part of the object header uses the following
  // bit fields for storing tags.
  enum TagBits {
    kWatchedBit = 0,
    kMarkBit = 1,
    kCanonicalBit = 2,
    kFromSnapshotBit = 3,
    kRememberedBit = 4,
    kReservedTagPos = 5,  // kReservedBit{10K,100K,1M,10M}
    kReservedTagSize = 3,
    kSizeTagPos = kReservedTagPos + kReservedTagSize,  // = 8
    kSizeTagSize = 8,
    kClassIdTagPos = kSizeTagPos + kSizeTagSize,  // = 16
    kClassIdTagSize = 16,
  };

  // Encodes the object size in the tag in units of object alignment.
  class SizeTag {
   public:
    static const intptr_t kMaxSizeTag =
        ((1 << RawObject::kSizeTagSize) - 1) << kObjectAlignmentLog2;

    static uword encode(intptr_t size) {
      return SizeBits::encode(SizeToTagValue(size));
    }

    static intptr_t decode(uword tag) {
      return TagValueToSize(SizeBits::decode(tag));
    }

    static uword update(intptr_t size, uword tag) {
      return SizeBits::update(SizeToTagValue(size), tag);
    }

   private:
    // The actual unscaled bit field used within the tag field.
    class SizeBits : public BitField<intptr_t, kSizeTagPos, kSizeTagSize> {};

    static intptr_t SizeToTagValue(intptr_t size) {
      ASSERT(Utils::IsAligned(size, kObjectAlignment));
      return  (size > kMaxSizeTag) ? 0 : (size >> kObjectAlignmentLog2);
    }
    static intptr_t TagValueToSize(intptr_t value) {
      return value << kObjectAlignmentLog2;
    }
  };

  class ClassIdTag :
      public BitField<intptr_t, kClassIdTagPos, kClassIdTagSize> {};  // NOLINT

  bool IsHeapObject() const {
    uword value = reinterpret_cast<uword>(this);
    return (value & kSmiTagMask) == kHeapObjectTag;
  }

  bool IsNewObject() const {
    ASSERT(IsHeapObject());
    uword addr = reinterpret_cast<uword>(this);
    return (addr & kNewObjectAlignmentOffset) == kNewObjectAlignmentOffset;
  }
  bool IsOldObject() const {
    ASSERT(IsHeapObject());
    uword addr = reinterpret_cast<uword>(this);
    return (addr & kNewObjectAlignmentOffset) == kOldObjectAlignmentOffset;
  }
  bool IsVMHeapObject() const;

  // Support for GC marking bit.
  bool IsMarked() const {
    return MarkBit::decode(ptr()->tags_);
  }
  void SetMarkBit() {
    ASSERT(!IsMarked());
    uword tags = ptr()->tags_;
    ptr()->tags_ = MarkBit::update(true, tags);
  }
  void ClearMarkBit() {
    ASSERT(IsMarked());
    uword tags = ptr()->tags_;
    ptr()->tags_ = MarkBit::update(false, tags);
  }

  // Support for GC watched bit.
  bool IsWatched() const {
    return WatchedBit::decode(ptr()->tags_);
  }
  void SetWatchedBit() {
    ASSERT(!IsWatched());
    uword tags = ptr()->tags_;
    ptr()->tags_ = WatchedBit::update(true, tags);
  }
  void ClearWatchedBit() {
    ASSERT(IsWatched());
    uword tags = ptr()->tags_;
    ptr()->tags_ = WatchedBit::update(false, tags);
  }

  // Support for object tags.
  bool IsCanonical() const {
    return CanonicalObjectTag::decode(ptr()->tags_);
  }
  void SetCanonical() {
    uword tags = ptr()->tags_;
    ptr()->tags_ = CanonicalObjectTag::update(true, tags);
  }
  bool IsCreatedFromSnapshot() const {
    return CreatedFromSnapshotTag::decode(ptr()->tags_);
  }
  void SetCreatedFromSnapshot() {
    uword tags = ptr()->tags_;
    ptr()->tags_ = CreatedFromSnapshotTag::update(true, tags);
  }

  // Support for GC remembered bit.
  bool IsRemembered() const {
    return RememberedBit::decode(ptr()->tags_);
  }
  void SetRememberedBit() {
    ASSERT(!IsRemembered());
    uword tags = ptr()->tags_;
    ptr()->tags_ = RememberedBit::update(true, tags);
  }
  void ClearRememberedBit() {
    uword tags = ptr()->tags_;
    ptr()->tags_ = RememberedBit::update(false, tags);
  }

  bool IsDartInstance() {
    return (!IsHeapObject() || (GetClassId() >= kInstanceCid));
  }
  bool IsFreeListElement() {
    return ((GetClassId() == kFreeListElement));
  }

  intptr_t Size() const {
    uword tags = ptr()->tags_;
    intptr_t result = SizeTag::decode(tags);
    if (result != 0) {
      ASSERT(result == SizeFromClass());
      return result;
    }
    result = SizeFromClass();
    ASSERT(result > SizeTag::kMaxSizeTag);
    return result;
  }

  void Validate(Isolate* isolate) const;
  intptr_t VisitPointers(ObjectPointerVisitor* visitor);
  bool FindObject(FindObjectVisitor* visitor);

  static RawObject* FromAddr(uword addr) {
    // We expect the untagged address here.
    ASSERT((addr & kSmiTagMask) != kHeapObjectTag);
    return reinterpret_cast<RawObject*>(addr + kHeapObjectTag);
  }

  static uword ToAddr(const RawObject* raw_obj) {
    return reinterpret_cast<uword>(raw_obj->ptr());
  }

  static bool IsCreatedFromSnapshot(intptr_t value) {
    return CreatedFromSnapshotTag::decode(value);
  }

  static bool IsCanonical(intptr_t value) {
    return CanonicalObjectTag::decode(value);
  }

  // Class Id predicates.
  static bool IsErrorClassId(intptr_t index);
  static bool IsNumberClassId(intptr_t index);
  static bool IsIntegerClassId(intptr_t index);
  static bool IsStringClassId(intptr_t index);
  static bool IsOneByteStringClassId(intptr_t index);
  static bool IsTwoByteStringClassId(intptr_t index);
  static bool IsExternalStringClassId(intptr_t index);
  static bool IsBuiltinListClassId(intptr_t index);
  static bool IsTypedDataClassId(intptr_t index);
  static bool IsTypedDataViewClassId(intptr_t index);
  static bool IsExternalTypedDataClassId(intptr_t index);
  static bool IsInternalVMdefinedClassId(intptr_t index);
  static bool IsVariableSizeClassId(intptr_t index);
  static bool IsImplicitFieldClassId(intptr_t index);

  static intptr_t NumberOfTypedDataClasses();

 private:
  uword tags_;  // Various object tags (bits).

  class WatchedBit : public BitField<bool, kWatchedBit, 1> {};

  class MarkBit : public BitField<bool, kMarkBit, 1> {};

  class RememberedBit : public BitField<bool, kRememberedBit, 1> {};

  class CanonicalObjectTag : public BitField<bool, kCanonicalBit, 1> {};

  class CreatedFromSnapshotTag : public BitField<bool, kFromSnapshotBit, 1> {};

  class ReservedBits : public
      BitField<intptr_t, kReservedTagPos, kReservedTagSize> {};  // NOLINT

  RawObject* ptr() const {
    ASSERT(IsHeapObject());
    return reinterpret_cast<RawObject*>(
        reinterpret_cast<uword>(this) - kHeapObjectTag);
  }

  intptr_t SizeFromClass() const;

  intptr_t GetClassId() const {
    uword tags = ptr()->tags_;
    return ClassIdTag::decode(tags);
  }

  friend class Api;
  friend class Array;
  friend class ByteBuffer;
  friend class Code;
  friend class FreeListElement;
  friend class GCMarker;
  friend class ExternalTypedData;
  friend class ForwardList;
  friend class Heap;
  friend class HeapMapAsJSONVisitor;
  friend class ClassStatsVisitor;
  friend class MarkingVisitor;
  friend class Object;
  friend class RawExternalTypedData;
  friend class RawInstructions;
  friend class RawInstance;
  friend class RawTypedData;
  friend class Scavenger;
  friend class ScavengerVisitor;
  friend class SizeExcludingClassVisitor;  // GetClassId
  friend class SnapshotReader;
  friend class SnapshotWriter;
  friend class String;
  friend class TypedData;
  friend class TypedDataView;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(RawObject);
};


class RawClass : public RawObject {
 public:
  enum ClassFinalizedState {
    kAllocated = 0,  // Initial state.
    kPreFinalized,  // VM classes: size precomputed, but no checks done.
    kFinalized,  // Class parsed, finalized and ready for use.
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Class);

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->name_); }
  RawString* name_;
  RawString* user_name_;
  RawArray* functions_;
  RawArray* fields_;
  RawArray* offset_in_words_to_field_;
  RawGrowableObjectArray* closure_functions_;  // Local functions and literals.
  RawArray* interfaces_;  // Array of AbstractType.
  RawGrowableObjectArray* direct_subclasses_;  // Array of Class.
  RawScript* script_;
  RawLibrary* library_;
  RawTypeArguments* type_parameters_;  // Array of TypeParameter.
  RawAbstractType* super_type_;
  RawType* mixin_;  // Generic mixin type, e.g. M<T>, not M<int>.
  RawClass* patch_class_;
  RawFunction* signature_function_;  // Associated function for signature class.
  RawArray* constants_;  // Canonicalized values of this class.
  RawObject* canonical_types_;  // An array of canonicalized types of this class
                                // or the canonical type.
  RawArray* invocation_dispatcher_cache_;  // Cache for dispatcher functions.
  RawArray* cha_codes_;  // CHA optimized codes.
  RawCode* allocation_stub_;  // Stub code for allocation of instances.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->allocation_stub_);
  }

  cpp_vtable handle_vtable_;
  int32_t id_;  // Class Id, also index in the class table.
  int32_t token_pos_;
  int32_t instance_size_in_words_;  // Size if fixed len or 0 if variable len.
  int32_t type_arguments_field_offset_in_words_;  // Offset of type args fld.
  int32_t next_field_offset_in_words_;  // Offset of the next instance field.
  int16_t num_type_arguments_;  // Number of type arguments in flatten vector.
  int16_t num_own_type_arguments_;  // Number of non-overlapping type arguments.
  uint16_t num_native_fields_;  // Number of native fields in class.
  uint16_t state_bits_;

  friend class Instance;
  friend class Object;
  friend class RawInstance;
  friend class RawInstructions;
  friend class SnapshotReader;
};


class RawUnresolvedClass : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnresolvedClass);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->library_prefix_);
  }
  RawLibraryPrefix* library_prefix_;  // Library prefix qualifier for the ident.
  RawString* ident_;  // Name of the unresolved identifier.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->ident_);
  }
  int32_t token_pos_;
};


class RawTypeArguments : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeArguments);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->instantiations_);
  }
  // The instantiations_ array remains empty for instantiated type arguments.
  RawArray* instantiations_;  // Array of paired canonical vectors:
                              // Even index: instantiator.
                              // Odd index: instantiated (without bound error).
  // Instantiations leading to bound errors do not get cached.
  RawSmi* length_;

  // Variable length data follows here.
  RawAbstractType** types() {
    OPEN_ARRAY_START(RawAbstractType*, RawAbstractType*);
  }
  RawObject** to(intptr_t length) {
    return reinterpret_cast<RawObject**>(&ptr()->types()[length - 1]);
  }

  friend class SnapshotReader;
};


class RawPatchClass : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(PatchClass);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->patched_class_);
  }
  RawClass* patched_class_;
  RawClass* source_class_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->source_class_);
  }
};


class RawFunction : public RawObject {
 public:
  enum Kind {
    kRegularFunction,
    kClosureFunction,
    kSignatureFunction,  // represents a signature only without actual code.
    kGetterFunction,     // represents getter functions e.g: get foo() { .. }.
    kSetterFunction,     // represents setter functions e.g: set foo(..) { .. }.
    kConstructor,
    kImplicitGetter,     // represents an implicit getter for fields.
    kImplicitSetter,     // represents an implicit setter for fields.
    kImplicitStaticFinalGetter,  // represents an implicit getter for static
                                 // final fields (incl. static const fields).
    kStaticInitializer,  // used in implicit static getters.
    kMethodExtractor,  // converts method into implicit closure on the receiver.
    kNoSuchMethodDispatcher,  // invokes noSuchMethod.
    kInvokeFieldDispatcher,  // invokes a field as a closure.
  };

  enum AsyncModifier {
    kNoModifier,
    kAsync,
  };

 private:
  // So that the MarkingVisitor::DetachCode can null out the code fields.
  friend class MarkingVisitor;
  friend class Class;
  RAW_HEAP_OBJECT_IMPLEMENTATION(Function);
  static bool SkipCode(RawFunction* raw_fun);

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->name_); }
  RawString* name_;
  RawObject* owner_;  // Class or patch class or mixin class
                      // where this function is defined.
  RawAbstractType* result_type_;
  RawArray* parameter_types_;
  RawArray* parameter_names_;
  RawObject* data_;  // Additional data specific to the function kind.
  RawObject** to_snapshot() {
    return reinterpret_cast<RawObject**>(&ptr()->data_);
  }
  // Fields below are not part of the snapshot.
  RawArray* ic_data_array_;  // ICData of unoptimized code.
  RawObject** to_no_code() {
    return reinterpret_cast<RawObject**>(&ptr()->ic_data_array_);
  }
  RawInstructions* instructions_;  // Instructions of currently active code.
  RawCode* unoptimized_code_;  // Unoptimized code, keep it after optimization.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->unoptimized_code_);
  }

  int32_t token_pos_;
  int32_t end_token_pos_;
  int32_t usage_counter_;  // Incremented while function is running.
  int16_t num_fixed_parameters_;
  int16_t num_optional_parameters_;  // > 0: positional; < 0: named.
  int16_t deoptimization_counter_;
  uint32_t kind_tag_;  // See Function::KindTagBits.
  uint16_t optimized_instruction_count_;
  uint16_t optimized_call_site_count_;
};


class RawClosureData : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(ClosureData);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->context_scope_);
  }
  RawContextScope* context_scope_;
  RawFunction* parent_function_;  // Enclosing function of this local function.
  RawClass* signature_class_;
  RawInstance* closure_;  // Closure object for static implicit closures.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->closure_);
  }
};


class RawRedirectionData : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(RedirectionData);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->type_);
  }
  RawType* type_;
  RawString* identifier_;
  RawFunction* target_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->target_);
  }
};


class RawField : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Field);

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->name_); }
  RawString* name_;
  RawObject* owner_;  // Class or patch class or mixin class
                      // where this field is defined.
  RawAbstractType* type_;
  RawInstance* value_;  // Offset in words for instance and value for static.
  RawArray* dependent_code_;
  RawSmi* guarded_list_length_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->guarded_list_length_);
  }

  int32_t token_pos_;
  int32_t guarded_cid_;
  int32_t is_nullable_;  // kNullCid if field can contain null value and
                         // any other value otherwise.
  // Offset to the guarded length field inside an instance of class matching
  // guarded_cid_. Stored corrected by -kHeapObjectTag to simplify code
  // generated on platforms with weak addressing modes (ARM, MIPS).
  int8_t guarded_list_length_in_object_offset_;

  uint8_t kind_bits_;  // static, final, const, has initializer.
};


class RawLiteralToken : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LiteralToken);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->literal_);
  }
  RawString* literal_;  // Literal characters as they appear in source text.
  RawObject* value_;  // The actual object corresponding to the token.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->value_);
  }
  Token::Kind kind_;  // The literal kind (string, integer, double).

  friend class SnapshotReader;
};


class RawTokenStream : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TokenStream);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->private_key_);
  }
  RawString* private_key_;  // Key used for private identifiers.
  RawArray* token_objects_;
  RawExternalTypedData* stream_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->stream_);
  }

  friend class SnapshotReader;
};


class RawScript : public RawObject {
 public:
  enum Kind {
    kScriptTag = 0,
    kLibraryTag,
    kSourceTag,
    kPatchTag,
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Script);

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->url_); }
  RawString* url_;
  RawString* source_;
  RawTokenStream* tokens_;
  RawObject** to() { return reinterpret_cast<RawObject**>(&ptr()->tokens_); }

  int32_t line_offset_;
  int32_t col_offset_;
  int8_t kind_;  // Of type Kind.
};


class RawLibrary : public RawObject {
  enum LibraryState {
    kAllocated,       // Initial state.
    kLoadRequested,   // Compiler or script requested load of library.
    kLoadInProgress,  // Library is in the process of being loaded.
    kLoaded,          // Library is loaded.
    kLoadError,       // Error occurred during load of the Library.
  };

  RAW_HEAP_OBJECT_IMPLEMENTATION(Library);

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->name_); }
  RawString* name_;
  RawString* url_;
  RawScript* script_;
  RawString* private_key_;
  RawArray* dictionary_;         // Top-level names in this library.
  RawArray* resolved_names_;     // Cache of resolved names in library scope.
  RawGrowableObjectArray* metadata_;  // Metadata on classes, methods etc.
  RawArray* anonymous_classes_;  // Classes containing top-level elements.
  RawArray* imports_;            // List of Namespaces imported without prefix.
  RawArray* exports_;            // List of re-exported Namespaces.
  RawArray* loaded_scripts_;     // Array of scripts loaded in this library.
  RawInstance* load_error_;      // Error iff load_state_ == kLoadError.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->load_error_);
  }

  int32_t index_;               // Library id number.
  int32_t num_imports_;         // Number of entries in imports_.
  int32_t num_anonymous_;       // Number of entries in anonymous_classes_.
  Dart_NativeEntryResolver native_entry_resolver_;  // Resolves natives.
  Dart_NativeEntrySymbol native_entry_symbol_resolver_;
  bool corelib_imported_;
  bool is_dart_scheme_;
  bool debuggable_;              // True if debugger can stop in library.
  int8_t load_state_;            // Of type LibraryState.

  friend class Isolate;
};


class RawNamespace : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Namespace);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->library_);
  }
  RawLibrary* library_;          // library with name dictionary.
  RawArray* show_names_;         // list of names that are exported.
  RawArray* hide_names_;         // blacklist of names that are not exported.
  RawField* metadata_field_;     // remembers the token pos of metadata if any,
                                 // and the metadata values if computed.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->metadata_field_);
  }
};


class RawCode : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Code);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->instructions_);
  }
  RawInstructions* instructions_;
  // If owner_ is Function::null() the owner is a regular stub.
  // If owner_ is a Class the owner is the allocation stub for that class.
  // Else, owner_ is a regular Dart Function.
  RawObject* owner_;  // Function, Null, or a Class.
  RawExceptionHandlers* exception_handlers_;
  RawPcDescriptors* pc_descriptors_;
  RawArray* deopt_info_array_;
  RawArray* object_table_;
  RawArray* static_calls_target_table_;  // (code-offset, function, code).
  RawArray* stackmaps_;
  RawLocalVarDescriptors* var_descriptors_;
  RawArray* comments_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->comments_);
  }

  // Compilation timestamp.
  int64_t compile_timestamp_;
  intptr_t pointer_offsets_length_;
  // Alive: If true, the embedded object pointers will be visited during GC.
  // This field cannot be shorter because of alignment issues on x64
  // architectures.
  intptr_t state_bits_;  // state, is_optimized, is_alive.

  // PC offsets for code patching.
  intptr_t entry_patch_pc_offset_;
  intptr_t patch_code_pc_offset_;
  intptr_t lazy_deopt_pc_offset_;

  // Variable length data follows here.
  int32_t* data() { OPEN_ARRAY_START(int32_t, int32_t); }

  friend class StackFrame;
  friend class MarkingVisitor;
  friend class Function;
};


class RawInstructions : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Instructions);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->code_);
  }
  RawCode* code_;
  RawArray* object_pool_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->object_pool_);
  }
  intptr_t size_;

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }

  // Private helper function used while visiting stack frames. The
  // code which iterates over dart frames is also called during GC and
  // is not allowed to create handles.
  static bool ContainsPC(RawObject* raw_obj, uword pc);

  friend class RawCode;
  friend class Code;
  friend class StackFrame;
  friend class MarkingVisitor;
  friend class Function;
};


class RawPcDescriptors : public RawObject {
 public:
  enum Kind {
    kDeopt           = 1,  // Deoptimization continuation point.
    kIcCall          = kDeopt << 1,  // IC call.
    kOptStaticCall   = kIcCall << 1,  // Call directly to known target.
    kUnoptStaticCall = kOptStaticCall << 1,  // Call to a known target via stub.
    kClosureCall     = kUnoptStaticCall << 1,  // Closure call.
    kRuntimeCall     = kClosureCall << 1,  // Runtime call.
    kOsrEntry        = kRuntimeCall << 1,  // OSR entry point in unopt. code.
    kOther           = kOsrEntry << 1,
    kAnyKind         = 0xFF
  };

  // Compressed version assumes try_index is always -1 and does not store it.
  struct PcDescriptorRec {
    uword pc() const { return pc_; }
    void set_pc(uword value) { pc_ = value; }

    Kind kind() const {
      return static_cast<Kind>(deopt_id_and_kind_ & kAnyKind);
    }
    void set_kind(Kind kind) {
      deopt_id_and_kind_ = (deopt_id_and_kind_ & 0xFFFFFF00) | kind;
    }

    int16_t try_index() const { return is_compressed() ? -1 : try_index_; }
    void set_try_index(int16_t value) {
      if (is_compressed()) {
        ASSERT(value == -1);
        return;
      }
      try_index_ = value;
    }

    intptr_t token_pos() const { return token_pos_ >> 1; }
    void set_token_pos(int32_t value, bool compressed) {
      int32_t bit = compressed ? 0x1 : 0x0;
      token_pos_ = (value << 1) | bit;
    }

    intptr_t deopt_id() const { return deopt_id_and_kind_ >> 8; }
    void set_deopt_id(int32_t value) {
      ASSERT(Utils::IsInt(24, value));
      deopt_id_and_kind_ = (deopt_id_and_kind_ & 0xFF) | (value << 8);
    }

   private:
    bool is_compressed() const {
      return (token_pos_ & 0x1) == 1;
    }

    uword pc_;
    int32_t deopt_id_and_kind_;  // Bits 31..8 -> deopt_id, bits 7..0 kind.
    int32_t token_pos_;  // Bits 31..1 -> token_pos, bit 1 -> compressed flag;
    int16_t try_index_;
  };

  // This structure is only used to compute what the size of PcDescriptorRec
  // should be when the try_index_ field is omitted.
  struct CompressedPcDescriptorRec {
    uword pc_;
    int32_t deopt_id_and_kind_;
    int32_t token_pos_;
  };

  static intptr_t RecordSize(bool has_try_index);

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(PcDescriptors);

  static const intptr_t kFullRecSize;
  static const intptr_t kCompressedRecSize;

  intptr_t record_size_in_bytes_;
  intptr_t length_;  // Number of descriptors.

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, intptr_t); }

  friend class Object;
};


// Stackmap is an immutable representation of the layout of the stack at a
// PC. The stack map representation consists of a bit map which marks each
// live object index starting from the base of the frame.
//
// The Stackmap also consists of a link to the code object corresponding to
// the frame which the stack map is describing.  The bit map representation
// is optimized for dense and small bit maps, without any upper bound.
class RawStackmap : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Stackmap);

  // TODO(kmillikin): We need a small number of bits to encode the register
  // count.  Consider packing them in with the length.
  intptr_t length_;  // Length of payload, in bits.
  intptr_t register_bit_count_;  // Live register bits, included in length_.

  uword pc_;  // PC corresponding to this stack map representation.

  // Variable length data follows here (bitmap of the stack layout).
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }
};


class RawLocalVarDescriptors : public RawObject {
 public:
  enum VarInfoKind {
    kStackVar = 1,
    kContextVar,
    kContextLevel,
    kSavedEntryContext,
    kSavedCurrentContext
  };

  struct VarInfo {
    intptr_t index;      // Slot index on stack or in context.
    intptr_t begin_pos;  // Token position of scope start.
    intptr_t end_pos;    // Token position of scope end.
    int16_t  scope_id;   // Scope to which the variable belongs.
    int8_t   kind;       // Entry kind of type VarInfoKind.
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(LocalVarDescriptors);
  intptr_t length_;  // Number of descriptors.
  RawArray* names_;  // Array of [length_] variable names.

  // Variable info with [length_] entries.
  VarInfo* data() { OPEN_ARRAY_START(VarInfo, intptr_t); }
};


class RawExceptionHandlers : public RawObject {
 public:
  // The index into the ExceptionHandlers table corresponds to
  // the try_index of the handler.
  struct HandlerInfo {
    intptr_t handler_pc;       // PC value of handler.
    int16_t outer_try_index;   // Try block index of enclosing try block.
    int8_t needs_stacktrace;   // True if a stacktrace is needed.
    int8_t has_catch_all;      // Catches all exceptions.
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExceptionHandlers);

  // Number of exception handler entries.
  intptr_t length_;

  // Array with [length_] entries. Each entry is an array of all handled
  // exception types.
  RawArray* handled_types_data_;

  // Exception handler info of length [length_].
  HandlerInfo* data() { OPEN_ARRAY_START(HandlerInfo, intptr_t); }
};


// Contains an array of deoptimization commands, e.g., move a specific register
// into a specific slot of unoptimized frame.
class RawDeoptInfo : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(DeoptInfo);

  RawSmi* length_;  // Number of deoptimization commands

  // Variable length data follows here.
  intptr_t* data() { OPEN_ARRAY_START(intptr_t, intptr_t); }
};


class RawContext : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Context);

  intptr_t num_variables_;
  Isolate* isolate_;

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->parent_); }
  RawContext* parent_;

  // Variable length data follows here.
  RawInstance** data() { OPEN_ARRAY_START(RawInstance*, RawInstance*); }
  RawObject** to(intptr_t num_vars) {
    return reinterpret_cast<RawObject**>(&ptr()->data()[num_vars - 1]);
  }

  friend class SnapshotReader;
};


class RawContextScope : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ContextScope);

  // TODO(iposva): Switch to convential enum offset based structure to avoid
  // alignment mishaps.
  struct VariableDesc {
    RawSmi* token_pos;
    RawString* name;
    RawBool* is_final;
    RawBool* is_const;
    union {
      RawAbstractType* type;
      RawInstance* value;  // iff is_const is true
    };
    RawSmi* context_index;
    RawSmi* context_level;
  };

  intptr_t num_variables_;

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->data()[0]);
  }
  // Variable length data follows here.
  RawObject** data() { OPEN_ARRAY_START(RawObject*, RawObject*); }
  RawObject** to(intptr_t num_vars) {
    const intptr_t data_length = num_vars * (sizeof(VariableDesc)/kWordSize);
    return reinterpret_cast<RawObject**>(&ptr()->data()[data_length - 1]);
  }
};


class RawICData : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ICData);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->owner_);
  }
  RawFunction* owner_;         // Parent/calling function of this IC.
  RawString* target_name_;     // Name of target function.
  RawArray* args_descriptor_;  // Arguments descriptor.
  RawArray* ic_data_;          // Contains class-ids, target and count.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->ic_data_);
  }
  int32_t deopt_id_;     // Deoptimization id corresponding to this IC.
  uint32_t state_bits_;  // Number of arguments tested in IC, deopt reasons,
                         // is closure call, JS warning issued.
};


class RawMegamorphicCache : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(MegamorphicCache);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->buckets_);
  }
  RawArray* buckets_;
  RawSmi* mask_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->mask_);
  }

  int32_t filled_entry_count_;
};


class RawSubtypeTestCache : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SubtypeTestCache);
  RawArray* cache_;
};


class RawError : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Error);
};


class RawApiError : public RawError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ApiError);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->message_);
  }
  RawString* message_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->message_);
  }
};


class RawLanguageError : public RawError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LanguageError);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->previous_error_);
  }
  RawError* previous_error_;  // May be null.
  RawScript* script_;
  RawString* message_;
  RawString* formatted_message_;  // Incl. previous error's formatted message.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->formatted_message_);
  }
  int32_t token_pos_;  // Source position in script_.
  int8_t kind_;  // Of type LanguageError::Kind.
};


class RawUnhandledException : public RawError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnhandledException);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->exception_);
  }
  RawInstance* exception_;
  RawInstance* stacktrace_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->stacktrace_);
  }
};


class RawUnwindError : public RawError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnwindError);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->message_);
  }
  RawString* message_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->message_);
  }
};


class RawInstance : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Instance);
};


class RawLibraryPrefix : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LibraryPrefix);

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->name_); }
  RawString* name_;               // Library prefix name.
  RawArray* imports_;             // Libraries imported with this prefix.
  RawLibrary* importer_;          // Library which declares this prefix.
  RawArray* dependent_code_;      // Code that refers to deferred, unloaded
                                  // library prefix.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->dependent_code_);
  }
  int32_t num_imports_;          // Number of library entries in libraries_.
  bool is_deferred_load_;
  bool is_loaded_;
};


class RawAbstractType : public RawInstance {
 protected:
  enum TypeState {
    kAllocated,  // Initial state.
    kResolved,  // Type class and type arguments resolved.
    kBeingFinalized,  // In the process of being finalized.
    kFinalizedInstantiated,  // Instantiated type ready for use.
    kFinalizedUninstantiated,  // Uninstantiated type ready for use.
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(AbstractType);

  friend class ObjectStore;
};


class RawType : public RawAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Type);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->type_class_);
  }
  RawObject* type_class_;  // Either resolved class or unresolved class.
  RawTypeArguments* arguments_;
  RawLanguageError* error_;  // Error object if type is malformed or malbounded.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->error_);
  }
  int32_t token_pos_;
  int8_t type_state_;
};


class RawTypeRef : public RawAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeRef);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->type_);
  }
  RawAbstractType* type_;  // The referenced type.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->type_);
  }
};


class RawTypeParameter : public RawAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeParameter);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->parameterized_class_);
  }
  RawClass* parameterized_class_;
  RawString* name_;
  RawAbstractType* bound_;  // ObjectType if no explicit bound specified.
  RawObject** to() { return reinterpret_cast<RawObject**>(&ptr()->bound_); }
  int32_t index_;
  int32_t token_pos_;
  int8_t type_state_;
};


class RawBoundedType : public RawAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(BoundedType);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->type_);
  }
  RawAbstractType* type_;
  RawAbstractType* bound_;
  RawTypeParameter* type_parameter_;  // For more detailed error reporting.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->type_parameter_);
  }
};


class RawMixinAppType : public RawAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(MixinAppType);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->super_type_);
  }
  RawAbstractType* super_type_;
  RawArray* mixin_types_;  // Array of AbstractType.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->mixin_types_);
  }
};


class RawNumber : public RawInstance {
  RAW_OBJECT_IMPLEMENTATION(Number);
};


class RawInteger : public RawNumber {
  RAW_OBJECT_IMPLEMENTATION(Integer);
};


class RawSmi : public RawInteger {
  RAW_OBJECT_IMPLEMENTATION(Smi);
};


class RawMint : public RawInteger {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Mint);

  int64_t value_;

  friend class Api;
  friend class SnapshotReader;
};


class RawBigint : public RawInteger {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Bigint);

  // Actual length in chunks at the time of allocation (later we may
  // clamp the operational length but we need to maintain a consistent
  // object length so that the object can be traversed during GC).
  intptr_t allocated_length_;

  // Operational length in chunks of the bigint object, clamping can
  // cause this length to be reduced. If the signed_length_ is
  // negative then the number is negative.
  intptr_t signed_length_;

  // A sequence of Chunks (typedef in Bignum) representing bignum digits.
  // Bignum::Chunk chunks_[Utils::Abs(signed_length_)];
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }

  friend class SnapshotReader;
};


class RawDouble : public RawNumber {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Double);

  double value_;

  friend class Api;
  friend class SnapshotReader;
};


class RawString : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(String);

 protected:
  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->length_); }
  RawSmi* length_;
  RawSmi* hash_;
  RawObject** to() { return reinterpret_cast<RawObject**>(&ptr()->hash_); }
};


class RawOneByteString : public RawString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(OneByteString);

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }

  friend class ApiMessageReader;
  friend class SnapshotReader;
};


class RawTwoByteString : public RawString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TwoByteString);

  // Variable length data follows here.
  uint16_t* data() { OPEN_ARRAY_START(uint16_t, uint16_t); }

  friend class SnapshotReader;
};


template<typename T>
class ExternalStringData {
 public:
  ExternalStringData(const T* data, void* peer, Dart_PeerFinalizer callback) :
      data_(data), peer_(peer), callback_(callback) {
  }
  ~ExternalStringData() {
    if (callback_ != NULL) (*callback_)(peer_);
  }

  const T* data() {
    return data_;
  }
  void* peer() {
    return peer_;
  }

 private:
  const T* data_;
  void* peer_;
  Dart_PeerFinalizer callback_;
};


class RawExternalOneByteString : public RawString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalOneByteString);

  ExternalStringData<uint8_t>* external_data_;
  friend class Api;
};


class RawExternalTwoByteString : public RawString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalTwoByteString);

  ExternalStringData<uint16_t>* external_data_;
  friend class Api;
};


class RawBool : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Bool);

  bool value_;
};


class RawArray : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Array);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->type_arguments_);
  }
  RawTypeArguments* type_arguments_;
  RawSmi* length_;
  // Variable length data follows here.
  RawObject** data() { OPEN_ARRAY_START(RawObject*, RawObject*); }
  RawObject** to(intptr_t length) {
    return reinterpret_cast<RawObject**>(&ptr()->data()[length - 1]);
  }

  friend class RawCode;
  friend class RawImmutableArray;
  friend class SnapshotReader;
  friend class GrowableObjectArray;
  friend class LinkedHashMap;
  friend class Object;
  friend class ICData;  // For high performance access.
  friend class SubtypeTestCache;  // For high performance access.
};


class RawImmutableArray : public RawArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ImmutableArray);

  friend class SnapshotReader;
};


class RawGrowableObjectArray : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(GrowableObjectArray);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->type_arguments_);
  }
  RawTypeArguments* type_arguments_;
  RawSmi* length_;
  RawArray* data_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->data_);
  }

  friend class SnapshotReader;
};


class RawLinkedHashMap : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LinkedHashMap);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->type_arguments_);
  }
  RawTypeArguments* type_arguments_;
  RawInstance* cme_mark_;
  RawArray* data_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->data_);
  }

  friend class SnapshotReader;
};


class RawFloat32x4 : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Float32x4);

  float value_[4];

  friend class SnapshotReader;
 public:
  float x() const { return value_[0]; }
  float y() const { return value_[1]; }
  float z() const { return value_[2]; }
  float w() const { return value_[3]; }
};


class RawInt32x4 : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Int32x4);

  int32_t value_[4];

  friend class SnapshotReader;
 public:
  int32_t x() const { return value_[0]; }
  int32_t y() const { return value_[1]; }
  int32_t z() const { return value_[2]; }
  int32_t w() const { return value_[3]; }
};


class RawFloat64x2 : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Float64x2);

  double value_[2];

  friend class SnapshotReader;
 public:
  double x() const { return value_[0]; }
  double y() const { return value_[1]; }
};


// Define an aliases for intptr_t.
#if defined(ARCH_IS_32_BIT)
#define kIntPtrCid kTypedDataInt32ArrayCid
#define SetIntPtr SetInt32
#elif defined(ARCH_IS_64_BIT)
#define kIntPtrCid kTypedDataInt64ArrayCid
#define SetIntPtr SetInt64
#else
#error Architecture is not 32-bit or 64-bit.
#endif  // ARCH_IS_32_BIT


class RawTypedData : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypedData);

 protected:
  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->length_); }
  RawSmi* length_;
  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }
  RawObject** to() { return reinterpret_cast<RawObject**>(&ptr()->length_); }

  friend class Api;
  friend class Object;
  friend class Instance;
  friend class SnapshotReader;
};


class RawExternalTypedData : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalTypedData);

 protected:
  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->length_); }
  RawSmi* length_;
  RawObject** to() { return reinterpret_cast<RawObject**>(&ptr()->length_); }

  uint8_t* data_;

  friend class TokenStream;
  friend class RawTokenStream;
};

// VM implementations of the basic types in the isolate.
class RawCapability : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Capability);
  uint64_t id_;
};


class RawSendPort : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SendPort);
  Dart_Port id_;

  friend class ReceivePort;
};


class RawReceivePort : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ReceivePort);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->send_port_);
  }
  RawSendPort* send_port_;
  RawInstance* handler_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->handler_);
  }
};


// VM type for capturing stacktraces when exceptions are thrown,
// Currently we don't have any interface that this object is supposed
// to implement so we just support the 'toString' method which
// converts the stack trace into a string.
class RawStacktrace : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Stacktrace);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->code_array_);
  }
  RawArray* code_array_;  // Code object for each frame in the stack trace.
  RawArray* pc_offset_array_;  // Offset of PC for each frame.
  RawArray* catch_code_array_;  // Code for each frame in catch stack trace.
  RawArray* catch_pc_offset_array_;  // Offset of PC for each catch stack frame.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->catch_pc_offset_array_);
  }
  // False for pre-allocated stack trace (used in OOM and Stack overflow).
  bool expand_inlined_;
};


// VM type for capturing JS regular expressions.
class RawJSRegExp : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(JSRegExp);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->data_length_);
  }
  RawSmi* data_length_;
  RawSmi* num_bracket_expressions_;
  RawString* pattern_;  // Pattern to be used for matching.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->pattern_);
  }

  intptr_t type_;  // Uninitialized, simple or complex.
  intptr_t flags_;  // Represents global/local, case insensitive, multiline.

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }
};


class RawWeakProperty : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(WeakProperty);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->key_);
  }
  RawObject* key_;
  RawObject* value_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->value_);
  }

  friend class GCMarker;
  friend class MarkingVisitor;
  friend class Scavenger;
  friend class ScavengerVisitor;
};

// MirrorReferences are used by mirrors to hold reflectees that are VM
// internal objects, such as libraries, classes, functions or types.
class RawMirrorReference : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(MirrorReference);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->referent_);
  }
  RawObject* referent_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->referent_);
  }
};


// UserTag are used by the profiler to track Dart script state.
class RawUserTag : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UserTag);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->label_);
  }

  RawString* label_;

  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->label_);
  }

  // Isolate unique tag.
  uword tag_;

  friend class SnapshotReader;
  friend class Object;

 public:
  uword tag() const { return tag_; }
};

// Class Id predicates.

inline bool RawObject::IsErrorClassId(intptr_t index) {
  // Make sure this function is updated when new Error types are added.
  COMPILE_ASSERT(kApiErrorCid == kErrorCid + 1 &&
                 kLanguageErrorCid == kErrorCid + 2 &&
                 kUnhandledExceptionCid == kErrorCid + 3 &&
                 kUnwindErrorCid == kErrorCid + 4 &&
                 kInstanceCid == kErrorCid + 5);
  return (index >= kErrorCid && index < kInstanceCid);
}


inline bool RawObject::IsNumberClassId(intptr_t index) {
  // Make sure this function is updated when new Number types are added.
  COMPILE_ASSERT(kIntegerCid == kNumberCid + 1 &&
                 kSmiCid == kNumberCid + 2 &&
                 kMintCid == kNumberCid + 3 &&
                 kBigintCid == kNumberCid + 4 &&
                 kDoubleCid == kNumberCid + 5);
  return (index >= kNumberCid && index < kBoolCid);
}


inline bool RawObject::IsIntegerClassId(intptr_t index) {
  // Make sure this function is updated when new Integer types are added.
  COMPILE_ASSERT(kSmiCid == kIntegerCid + 1 &&
                 kMintCid == kIntegerCid + 2 &&
                 kBigintCid == kIntegerCid + 3 &&
                 kDoubleCid == kIntegerCid + 4);
  return (index >= kIntegerCid && index < kDoubleCid);
}


inline bool RawObject::IsStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index >= kStringCid && index <= kExternalTwoByteStringCid);
}


inline bool RawObject::IsOneByteStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index == kOneByteStringCid || index == kExternalOneByteStringCid);
}


inline bool RawObject::IsTwoByteStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index == kOneByteStringCid ||
          index == kTwoByteStringCid ||
          index == kExternalOneByteStringCid ||
          index == kExternalTwoByteStringCid);
}


inline bool RawObject::IsExternalStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index == kExternalOneByteStringCid ||
          index == kExternalTwoByteStringCid);
}


inline bool RawObject::IsBuiltinListClassId(intptr_t index) {
  // Make sure this function is updated when new builtin List types are added.
  COMPILE_ASSERT(kImmutableArrayCid == kArrayCid + 1);
  return ((index >= kArrayCid && index <= kImmutableArrayCid) ||
          (index == kGrowableObjectArrayCid) ||
          IsTypedDataClassId(index) ||
          IsTypedDataViewClassId(index) ||
          IsExternalTypedDataClassId(index) ||
          (index == kByteBufferCid));
}


inline bool RawObject::IsTypedDataClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kTypedDataUint8ArrayCid == kTypedDataInt8ArrayCid + 1 &&
                 kTypedDataUint8ClampedArrayCid == kTypedDataInt8ArrayCid + 2 &&
                 kTypedDataInt16ArrayCid == kTypedDataInt8ArrayCid + 3 &&
                 kTypedDataUint16ArrayCid == kTypedDataInt8ArrayCid + 4 &&
                 kTypedDataInt32ArrayCid == kTypedDataInt8ArrayCid + 5 &&
                 kTypedDataUint32ArrayCid == kTypedDataInt8ArrayCid + 6 &&
                 kTypedDataInt64ArrayCid == kTypedDataInt8ArrayCid + 7 &&
                 kTypedDataUint64ArrayCid == kTypedDataInt8ArrayCid + 8 &&
                 kTypedDataFloat32ArrayCid == kTypedDataInt8ArrayCid + 9 &&
                 kTypedDataFloat64ArrayCid == kTypedDataInt8ArrayCid + 10 &&
                 kTypedDataFloat32x4ArrayCid == kTypedDataInt8ArrayCid + 11 &&
                 kTypedDataInt32x4ArrayCid == kTypedDataInt8ArrayCid + 12 &&
                 kTypedDataFloat64x2ArrayCid == kTypedDataInt8ArrayCid + 13 &&
                 kTypedDataInt8ArrayViewCid == kTypedDataInt8ArrayCid + 14);
  return (index >= kTypedDataInt8ArrayCid &&
          index <= kTypedDataFloat64x2ArrayCid);
}


inline bool RawObject::IsTypedDataViewClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(
      kTypedDataUint8ArrayViewCid == kTypedDataInt8ArrayViewCid + 1 &&
      kTypedDataUint8ClampedArrayViewCid == kTypedDataInt8ArrayViewCid + 2 &&
      kTypedDataInt16ArrayViewCid == kTypedDataInt8ArrayViewCid + 3 &&
      kTypedDataUint16ArrayViewCid == kTypedDataInt8ArrayViewCid + 4 &&
      kTypedDataInt32ArrayViewCid == kTypedDataInt8ArrayViewCid + 5 &&
      kTypedDataUint32ArrayViewCid == kTypedDataInt8ArrayViewCid + 6 &&
      kTypedDataInt64ArrayViewCid == kTypedDataInt8ArrayViewCid + 7 &&
      kTypedDataUint64ArrayViewCid == kTypedDataInt8ArrayViewCid + 8 &&
      kTypedDataFloat32ArrayViewCid == kTypedDataInt8ArrayViewCid + 9 &&
      kTypedDataFloat64ArrayViewCid == kTypedDataInt8ArrayViewCid + 10 &&
      kTypedDataFloat32x4ArrayViewCid == kTypedDataInt8ArrayViewCid + 11 &&
      kTypedDataInt32x4ArrayViewCid == kTypedDataInt8ArrayViewCid + 12 &&
      kTypedDataFloat64x2ArrayViewCid == kTypedDataInt8ArrayViewCid + 13 &&
      kByteDataViewCid == kTypedDataInt8ArrayViewCid + 14 &&
      kExternalTypedDataInt8ArrayCid == kTypedDataInt8ArrayViewCid + 15);
  return (index >= kTypedDataInt8ArrayViewCid &&
          index <= kByteDataViewCid);
}


inline bool RawObject::IsExternalTypedDataClassId(intptr_t index) {
  // Make sure this is updated when new ExternalTypedData types are added.
  COMPILE_ASSERT(
      (kExternalTypedDataUint8ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 1) &&
      (kExternalTypedDataUint8ClampedArrayCid ==
       kExternalTypedDataInt8ArrayCid + 2) &&
      (kExternalTypedDataInt16ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 3) &&
      (kExternalTypedDataUint16ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 4) &&
      (kExternalTypedDataInt32ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 5) &&
      (kExternalTypedDataUint32ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 6) &&
      (kExternalTypedDataInt64ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 7) &&
      (kExternalTypedDataUint64ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 8) &&
      (kExternalTypedDataFloat32ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 9) &&
      (kExternalTypedDataFloat64ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 10) &&
      (kExternalTypedDataFloat32x4ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 11) &&
      (kExternalTypedDataInt32x4ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 12) &&
      (kExternalTypedDataFloat64x2ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 13) &&
      (kByteBufferCid == kExternalTypedDataInt8ArrayCid + 14));
  return (index >= kExternalTypedDataInt8ArrayCid &&
          index <= kExternalTypedDataFloat64x2ArrayCid);
}


inline bool RawObject::IsInternalVMdefinedClassId(intptr_t index) {
  return ((index < kNumPredefinedCids) &&
          !RawObject::IsImplicitFieldClassId(index));
}


inline bool RawObject::IsVariableSizeClassId(intptr_t index) {
  return (index == kArrayCid) ||
         (index == kImmutableArrayCid) ||
         RawObject::IsOneByteStringClassId(index) ||
         RawObject::IsTwoByteStringClassId(index) ||
         RawObject::IsTypedDataClassId(index) ||
         (index == kContextCid) ||
         (index == kTypeArgumentsCid) ||
         (index == kInstructionsCid) ||
         (index == kPcDescriptorsCid) ||
         (index == kStackmapCid) ||
         (index == kLocalVarDescriptorsCid) ||
         (index == kExceptionHandlersCid) ||
         (index == kDeoptInfoCid) ||
         (index == kCodeCid) ||
         (index == kContextScopeCid) ||
         (index == kInstanceCid) ||
         (index == kBigintCid) ||
         (index == kJSRegExpCid);
}


// This is a set of classes that are not Dart classes whose representation
// is defined by the VM but are used in the VM code by computing the
// implicit field offsets of the various fields in the dart object.
inline bool RawObject::IsImplicitFieldClassId(intptr_t index) {
  return (IsTypedDataViewClassId(index) || index == kByteBufferCid);
}


inline intptr_t RawObject::NumberOfTypedDataClasses() {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kTypedDataInt8ArrayViewCid == kTypedDataInt8ArrayCid + 14);
  COMPILE_ASSERT(kExternalTypedDataInt8ArrayCid ==
                 kTypedDataInt8ArrayViewCid + 15);
  COMPILE_ASSERT(kByteBufferCid == kExternalTypedDataInt8ArrayCid + 14);
  COMPILE_ASSERT(kNullCid == kByteBufferCid + 1);
  return (kNullCid - kTypedDataInt8ArrayCid);
}

}  // namespace dart

#endif  // VM_RAW_OBJECT_H_
