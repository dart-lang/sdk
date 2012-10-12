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
#define CLASS_LIST_NO_OBJECT(V)                                                \
  V(Class)                                                                     \
  V(UnresolvedClass)                                                           \
  V(AbstractTypeArguments)                                                     \
    V(TypeArguments)                                                           \
    V(InstantiatedTypeArguments)                                               \
  V(PatchClass)                                                                \
  V(Function)                                                                  \
  V(ClosureData)                                                               \
  V(RedirectionData)                                                           \
  V(Field)                                                                     \
  V(LiteralToken)                                                              \
  V(TokenStream)                                                               \
  V(Script)                                                                    \
  V(Library)                                                                   \
  V(LibraryPrefix)                                                             \
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
  V(SubtypeTestCache)                                                          \
  V(Error)                                                                     \
    V(ApiError)                                                                \
    V(LanguageError)                                                           \
    V(UnhandledException)                                                      \
    V(UnwindError)                                                             \
  V(Instance)                                                                  \
    V(AbstractType)                                                            \
      V(Type)                                                                  \
      V(TypeParameter)                                                         \
    V(Number)                                                                  \
      V(Integer)                                                               \
        V(Smi)                                                                 \
        V(Mint)                                                                \
        V(Bigint)                                                              \
      V(Double)                                                                \
    V(String)                                                                  \
      V(OneByteString)                                                         \
      V(TwoByteString)                                                         \
      V(FourByteString)                                                        \
      V(ExternalOneByteString)                                                 \
      V(ExternalTwoByteString)                                                 \
      V(ExternalFourByteString)                                                \
    V(Bool)                                                                    \
    V(Array)                                                                   \
      V(ImmutableArray)                                                        \
    V(GrowableObjectArray)                                                     \
    V(ByteArray)                                                               \
      V(Int8Array)                                                             \
      V(Uint8Array)                                                            \
      V(Int16Array)                                                            \
      V(Uint16Array)                                                           \
      V(Int32Array)                                                            \
      V(Uint32Array)                                                           \
      V(Int64Array)                                                            \
      V(Uint64Array)                                                           \
      V(Float32Array)                                                          \
      V(Float64Array)                                                          \
      V(ExternalInt8Array)                                                     \
      V(ExternalUint8Array)                                                    \
      V(ExternalInt16Array)                                                    \
      V(ExternalUint16Array)                                                   \
      V(ExternalInt32Array)                                                    \
      V(ExternalUint32Array)                                                   \
      V(ExternalInt64Array)                                                    \
      V(ExternalUint64Array)                                                   \
      V(ExternalFloat32Array)                                                  \
      V(ExternalFloat64Array)                                                  \
    V(Stacktrace)                                                              \
    V(JSRegExp)                                                                \
    V(WeakProperty)                                                            \
    V(DartFunction)                                                            \

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


// RawObject is the base class of all raw objects, even though it carries the
// class_ field not all raw objects are allocated in the heap and thus cannot
// be dereferenced (e.g. RawSmi).
class RawObject {
 public:
  // The tags field which is a part of the object header uses the following
  // bit fields for storing tags.
  enum TagBits {
    kFreeBit = 0,
    kMarkBit = 1,
    kCanonicalBit = 2,
    kFromSnapshotBit = 3,
    kWatchedBit = 4,
    kReservedTagBit = 5,  // kReservedBit{10K,100K,1M,10M}
    kReservedTagSize = 3,
    kSizeTagBit = 8,
    kSizeTagSize = 8,
    kClassIdTagBit = kSizeTagBit + kSizeTagSize,
    kClassIdTagSize = 16
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
    class SizeBits : public BitField<intptr_t, kSizeTagBit, kSizeTagSize> {};

    static intptr_t SizeToTagValue(intptr_t size) {
      ASSERT(Utils::IsAligned(size, kObjectAlignment));
      return  (size > kMaxSizeTag) ? 0 : (size >> kObjectAlignmentLog2);
    }
    static intptr_t TagValueToSize(intptr_t value) {
      return value << kObjectAlignmentLog2;
    }
  };

  class ClassIdTag : public BitField<intptr_t,
                                     kClassIdTagBit,
                                     kClassIdTagSize> {};  // NOLINT

  bool IsHeapObject() const {
    uword value = reinterpret_cast<uword>(this);
    return (value & kSmiTagMask) == kHeapObjectTag;
  }

  bool IsNewObject() const {
    uword addr = reinterpret_cast<uword>(this);
    return (addr & kNewObjectAlignmentOffset) == kNewObjectAlignmentOffset;
  }
  bool IsOldObject() const {
    uword addr = reinterpret_cast<uword>(this);
    return (addr & kNewObjectAlignmentOffset) == kOldObjectAlignmentOffset;
  }

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

  static uword ToAddr(RawObject* raw_obj) {
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
  static bool IsByteArrayClassId(intptr_t index);

 protected:
  uword tags_;  // Various object tags (bits).

 private:
  class FreeBit : public BitField<bool, kFreeBit, 1> {};

  class MarkBit : public BitField<bool, kMarkBit, 1> {};

  class WatchedBit : public BitField<bool, kWatchedBit, 1> {};

  class CanonicalObjectTag : public BitField<bool, kCanonicalBit, 1> {};

  class CreatedFromSnapshotTag : public BitField<bool, kFromSnapshotBit, 1> {};

  class ReservedBits : public BitField<intptr_t,
                                       kReservedTagBit,
                                       kReservedTagSize> {};  // NOLINT

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
  friend class FreeListElement;
  friend class GCMarker;
  friend class Heap;
  friend class HeapProfiler;
  friend class HeapProfilerRootVisitor;
  friend class MarkingVisitor;
  friend class Object;
  friend class RawInstructions;
  friend class RawInstance;
  friend class Scavenger;
  friend class SnapshotReader;
  friend class SnapshotWriter;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(RawObject);
};


class RawClass : public RawObject {
 public:
  enum ClassState {
    kAllocated,     // Initial state.
    kPreFinalized,  // VM classes: size precomputed, but no checks done.
    kFinalized,     // All checks completed, class ready for use.
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Class);

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->name_); }
  RawString* name_;
  RawArray* functions_;
  RawArray* fields_;
  RawGrowableObjectArray* closure_functions_;  // Local functions and literals.
  RawArray* interfaces_;  // Array of AbstractType.
  RawGrowableObjectArray* direct_subclasses_;  // Array of Class.
  RawScript* script_;
  RawLibrary* library_;
  RawTypeArguments* type_parameters_;  // Array of TypeParameter.
  RawType* super_type_;
  RawObject* factory_class_;  // UnresolvedClass (until finalization) or Class.
  RawFunction* signature_function_;  // Associated function for signature class.
  RawArray* constants_;  // Canonicalized values of this class.
  RawArray* canonical_types_;  // Canonicalized types of this class.
  RawCode* allocation_stub_;  // Stub code for allocation of instances.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->allocation_stub_);
  }

  cpp_vtable handle_vtable_;
  intptr_t instance_size_;  // Size if fixed length or 0 if variable length.
  intptr_t id_;  // Class Id, also index in the class table.
  intptr_t type_arguments_instance_field_offset_;  // May be kNoTypeArguments.
  intptr_t next_field_offset_;  // Offset of the next instance field.
  intptr_t num_native_fields_;  // Number of native fields in class.
  intptr_t token_pos_;
  uint8_t state_bits_;  // state, is_const, is_interface.

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
  RawClass* factory_signature_class_;  // Expected type parameters for factory.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->factory_signature_class_);
  }
  intptr_t token_pos_;
};


class RawAbstractTypeArguments : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(AbstractTypeArguments);
};


class RawTypeArguments : public RawAbstractTypeArguments {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeArguments);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->length_);
  }
  RawSmi* length_;

  // Variable length data follows here.
  RawAbstractType* types_[0];
  RawObject** to(intptr_t length) {
    return reinterpret_cast<RawObject**>(&ptr()->types_[length - 1]);
  }

  friend class SnapshotReader;
};


class RawInstantiatedTypeArguments : public RawAbstractTypeArguments {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(InstantiatedTypeArguments);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(
        &ptr()->uninstantiated_type_arguments_);
  }
  RawAbstractTypeArguments* uninstantiated_type_arguments_;
  RawAbstractTypeArguments* instantiator_type_arguments_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->instantiator_type_arguments_);
  }
};


class RawPatchClass : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(PatchClass);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->patched_class_);
  }
  RawClass* patched_class_;
  RawScript* script_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->script_);
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
    kConstImplicitGetter,  // represents an implicit const getter for fields.
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Function);

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->name_); }
  RawString* name_;
  RawObject* owner_;  // Class or  patch class where this function was defined.
  RawAbstractType* result_type_;
  RawArray* parameter_types_;
  RawArray* parameter_names_;
  RawCode* code_;  // Compiled code for the function.
  RawCode* unoptimized_code_;  // Unoptimized code, keep it after optimization.
  RawObject* data_;  // Additional data specific to the function kind.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->data_);
  }

  intptr_t token_pos_;
  intptr_t end_token_pos_;
  intptr_t usage_counter_;  // Incremented while function is running.
  int16_t num_fixed_parameters_;
  int16_t num_optional_parameters_;  // > 0: positional; < 0: named.
  uint16_t deoptimization_counter_;
  uint16_t kind_tag_;
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
  RawCode* closure_allocation_stub_;  // Stub code for allocation of closures.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->closure_allocation_stub_);
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
  RawClass* owner_;
  RawAbstractType* type_;
  RawInstance* value_;  // Offset for instance and value for static fields.
  RawObject** to() { return reinterpret_cast<RawObject**>(&ptr()->value_); }

  intptr_t token_pos_;
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
  RawExternalUint8Array* stream_;
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

  Kind kind_;
};


class RawLibrary : public RawObject {
  enum LibraryState {
    kAllocated,       // Initial state.
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
  RawArray* anonymous_classes_;  // Classes containing top-level elements.
  RawArray* imports_;            // List of Namespaces imported without prefix.
  RawArray* exports_;            // List of re-exported Namespaces.
  RawArray* loaded_scripts_;     // Array of scripts loaded in this library.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->loaded_scripts_);
  }

  intptr_t index_;               // Library id number.
  intptr_t num_imports_;         // Number of entries in imports_.
  intptr_t num_anonymous_;       // Number of entries in anonymous_classes_.
  Dart_NativeEntryResolver native_entry_resolver_;  // Resolves natives.
  bool corelib_imported_;
  bool debuggable_;              // True if debugger can stop in library.
  int8_t load_state_;            // Of type LibraryState.

  friend class Isolate;
};


class RawLibraryPrefix : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LibraryPrefix);

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->name_); }
  RawString* name_;               // library prefix name.
  RawArray* imports_;             // libraries imported with this prefix.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->imports_);
  }
  intptr_t num_imports_;          // Number of library entries in libraries_.
};


class RawNamespace : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Namespace);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->library_);
  }
  RawLibrary* library_;          // library with name dictionary.
  RawArray* show_names_;         // list of names that are exported.
  RawArray* hide_names_;         // blacklist of names that are not exported.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->hide_names_);
  }
};


class RawCode : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Code);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->instructions_);
  }
  RawInstructions* instructions_;
  RawFunction* function_;
  RawExceptionHandlers* exception_handlers_;
  RawPcDescriptors* pc_descriptors_;
  RawArray* deopt_info_array_;
  RawArray* object_table_;
  RawArray* stackmaps_;
  RawLocalVarDescriptors* var_descriptors_;
  RawArray* comments_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->comments_);
  }

  intptr_t pointer_offsets_length_;
  // These fields cannot be boolean because of alignment issues on x64
  // architectures.
  intptr_t is_optimized_;
  // If true, the embedded object pointers will be visited during GC.
  intptr_t is_alive_;

  // Variable length data follows here.
  int32_t data_[0];

  friend class StackFrame;
};


class RawInstructions : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Instructions);

  RawCode* code_;
  intptr_t size_;

  // Variable length data follows here.
  uint8_t data_[0];

  // Private helper function used while visiting stack frames. The
  // code which iterates over dart frames is also called during GC and
  // is not allowed to create handles.
  static bool ContainsPC(RawObject* raw_obj, uword pc);

  friend class RawCode;
  friend class Code;
  friend class StackFrame;
};


class RawPcDescriptors : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(PcDescriptors);

  RawSmi* length_;  // Number of descriptors.

  // Variable length data follows here.
  intptr_t data_[0];
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

  RawCode* code_;  // Code object corresponding to the frame described.

  // TODO(kmillikin): We need a small number of bits to encode the register
  // count.  Consider packing them in with the length.
  intptr_t length_;  // Length of payload, in bits.
  intptr_t register_bit_count_;  // Live register bits, included in length_.

  uword pc_;  // PC corresponding to this stack map representation.

  // Variable length data follows here (bitmap of the stack layout).
  uint8_t data_[0];
};


class RawLocalVarDescriptors : public RawObject {
 public:
  enum VarInfoKind {
    kStackVar = 1,
    kContextVar,
    kContextLevel,
    kContextChain
  };

  struct VarInfo {
    intptr_t index;      // Slot index on stack or in context.
    int8_t   kind;       // Entry kind of type VarInfoKind.
    int16_t  scope_id;   // Scope to which the variable belongs.
    intptr_t begin_pos;  // Token position of scope start.
    intptr_t end_pos;    // Token position of scope end.
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(LocalVarDescriptors);
  intptr_t length_;  // Number of descriptors.
  RawArray* names_;  // Array of [length_] variable names.

  VarInfo data_[0];   // Variable info with [length_] entries.
};


class RawExceptionHandlers : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExceptionHandlers);

  RawSmi* length_;  // Number of exception handler entries.

  // Variable length data follows here.
  intptr_t data_[0];
};


// Contains an array of deoptimization commands, e.g., move a specific register
// into a specific slot of unoptimized frame.
class RawDeoptInfo : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(DeoptInfo);

  RawSmi* length_;  // Number of deoptimization commands

  // Variable length data follows here.
  intptr_t data_[0];
};


class RawContext : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Context);

  intptr_t num_variables_;
  Isolate* isolate_;

  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->parent_); }
  RawContext* parent_;

  // Variable length data follows here.
  RawInstance* data_[0];
  RawObject** to(intptr_t num_vars) {
    return reinterpret_cast<RawObject**>(&ptr()->data_[num_vars - 1]);
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
    RawAbstractType* type;
    RawSmi* context_index;
    RawSmi* context_level;
  };

  intptr_t num_variables_;

  // Variable length data follows here.
  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->data_[0]); }
  RawObject* data_[0];
  RawObject** to(intptr_t num_vars) {
    intptr_t data_length = num_vars * (sizeof(VariableDesc)/kWordSize);
    return reinterpret_cast<RawObject**>(&ptr()->data_[data_length - 1]);
  }
};


class RawICData : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ICData);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->function_);
  }
  RawFunction* function_;     // Parent/calling function of this IC.
  RawString* target_name_;    // Name of target function.
  RawArray* ic_data_;         // Contains test class-ids and target functions.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->ic_data_);
  }
  intptr_t deopt_id_;         // Deoptimization id corresponding to this IC.
  intptr_t num_args_tested_;  // Number of arguments tested in IC.
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
    return reinterpret_cast<RawObject**>(&ptr()->message_);
  }
  RawString* message_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->message_);
  }
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


class RawAbstractType : public RawInstance {
 protected:
  enum TypeState {
    kAllocated,  // Initial state.
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
  RawAbstractTypeArguments* arguments_;
  RawError* malformed_error_;  // Error object if type is malformed.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->malformed_error_);
  }
  intptr_t token_pos_;
  int8_t type_state_;
};


class RawTypeParameter : public RawAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeParameter);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->parameterized_class_);
  }
  RawClass* parameterized_class_;
  RawString* name_;
  RawAbstractType* bound_;  // DynamicType if no explicit bound specified.
  RawObject** to() { return reinterpret_cast<RawObject**>(&ptr()->bound_); }
  intptr_t index_;
  intptr_t token_pos_;
  int8_t type_state_;
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
  uint8_t data_[0];

  friend class SnapshotReader;
};


class RawDouble : public RawNumber {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Double);

  double value_;

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
  uint8_t data_[0];

  friend class SnapshotReader;
  friend class ApiMessageReader;
};


class RawTwoByteString : public RawString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TwoByteString);

  // Variable length data follows here.
  uint16_t data_[0];

  friend class SnapshotReader;
};


class RawFourByteString : public RawString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(FourByteString);

  // Variable length data follows here.
  uint32_t data_[0];

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


class RawExternalFourByteString : public RawString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalFourByteString);

  ExternalStringData<uint32_t>* external_data_;
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
  RawAbstractTypeArguments* type_arguments_;
  RawSmi* length_;
  // Variable length data follows here.
  RawObject** data() {
    uword address_of_length = reinterpret_cast<uword>(&length_);
    return reinterpret_cast<RawObject**>(address_of_length + kWordSize);
  }
  RawObject** to(intptr_t length) {
    return reinterpret_cast<RawObject**>(&ptr()->data()[length - 1]);
  }

  friend class RawCode;
  friend class RawImmutableArray;
  friend class SnapshotReader;
  friend class GrowableObjectArray;
  friend class Object;
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
  RawAbstractTypeArguments* type_arguments_;
  RawSmi* length_;
  RawArray* data_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->data_);
  }

  friend class SnapshotReader;
};


class RawByteArray : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ByteArray);

 protected:
  RawObject** from() { return reinterpret_cast<RawObject**>(&ptr()->length_); }
  RawSmi* length_;
  RawObject** to() { return reinterpret_cast<RawObject**>(&ptr()->length_); }
};


class RawInt8Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Int8Array);

  // Variable length data follows here.
  int8_t data_[0];
};


class RawUint8Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Uint8Array);

  // Variable length data follows here.
  uint8_t data_[0];
};


class RawInt16Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Int16Array);

  // Variable length data follows here.
  int16_t data_[0];
};


class RawUint16Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Uint16Array);

  // Variable length data follows here.
  uint16_t data_[0];
};


class RawInt32Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Int32Array);

  // Variable length data follows here.
  int32_t data_[0];
};


class RawUint32Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Uint32Array);

  // Variable length data follows here.
  uint32_t data_[0];
};


class RawInt64Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Int64Array);

  // Variable length data follows here.
  int64_t data_[0];
};


class RawUint64Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Uint64Array);

  // Variable length data follows here.
  uint64_t data_[0];
};


class RawFloat32Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Float32Array);

  // Variable length data follows here.
  float data_[0];
};


class RawFloat64Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Float64Array);

  // Variable length data follows here.
  double data_[0];
};


template<typename T>
class ExternalByteArrayData {
 public:
  ExternalByteArrayData(T* data,
                        void* peer,
                        Dart_PeerFinalizer callback) :
      data_(data), peer_(peer), callback_(callback) {
  }
  ~ExternalByteArrayData() {
    if (callback_ != NULL) (*callback_)(peer_);
  }

  T* data() {
    return data_;
  }
  void* peer() {
    return peer_;
  }

 private:
  T* data_;
  void* peer_;
  Dart_PeerFinalizer callback_;
};


class RawExternalInt8Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalInt8Array);

  ExternalByteArrayData<int8_t>* external_data_;
};


class RawExternalUint8Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalUint8Array);

  ExternalByteArrayData<uint8_t>* external_data_;

  friend class TokenStream;
  friend class RawTokenStream;
};


class RawExternalInt16Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalInt16Array);

  ExternalByteArrayData<int16_t>* external_data_;
};


class RawExternalUint16Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalUint16Array);

  ExternalByteArrayData<uint16_t>* external_data_;
};


class RawExternalInt32Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalInt32Array);

  ExternalByteArrayData<int32_t>* external_data_;
};


class RawExternalUint32Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalUint32Array);

  ExternalByteArrayData<uint32_t>* external_data_;
};


class RawExternalInt64Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalInt64Array);

  ExternalByteArrayData<int64_t>* external_data_;
};


class RawExternalUint64Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalUint64Array);

  ExternalByteArrayData<uint64_t>* external_data_;
};


class RawExternalFloat32Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalFloat32Array);

  ExternalByteArrayData<float>* external_data_;
};


class RawExternalFloat64Array : public RawByteArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalFloat64Array);

  ExternalByteArrayData<double>* external_data_;
};


class RawDartFunction : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(DartFunction);
};


// VM type for capturing stacktraces when exceptions are thrown,
// Currently we don't have any interface that this object is supposed
// to implement so we just support the 'toString' method which
// converts the stack trace into a string.
class RawStacktrace : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Stacktrace);

  RawObject** from() {
    return reinterpret_cast<RawObject**>(&ptr()->function_array_);
  }
  RawArray* function_array_;  // Function for each frame in the stack trace.
  RawArray* code_array_;  // Code object for each frame in the stack trace.
  RawArray* pc_offset_array_;  // Offset of PC for each frame.
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&ptr()->pc_offset_array_);
  }
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
  uint8_t data_[0];
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

// Class Id predicates.

inline bool RawObject::IsErrorClassId(intptr_t index) {
  // Make sure this function is updated when new Error types are added.
  ASSERT(kApiErrorCid == kErrorCid + 1 &&
         kLanguageErrorCid == kErrorCid + 2 &&
         kUnhandledExceptionCid == kErrorCid + 3 &&
         kUnwindErrorCid == kErrorCid + 4 &&
         kInstanceCid == kErrorCid + 5);
  return (index >= kErrorCid && index < kInstanceCid);
}

inline bool RawObject::IsNumberClassId(intptr_t index) {
  // Make sure this function is updated when new Number types are added.
  ASSERT(kIntegerCid == kNumberCid + 1 &&
         kSmiCid == kNumberCid + 2 &&
         kMintCid == kNumberCid + 3 &&
         kBigintCid == kNumberCid + 4 &&
         kDoubleCid == kNumberCid + 5 &&
         kStringCid == kNumberCid + 6);
  return (index >= kNumberCid && index < kStringCid);
}

inline bool RawObject::IsIntegerClassId(intptr_t index) {
  // Make sure this function is updated when new Integer types are added.
  ASSERT(kSmiCid == kIntegerCid + 1 &&
         kMintCid == kIntegerCid + 2 &&
         kBigintCid == kIntegerCid + 3 &&
         kDoubleCid == kIntegerCid + 4);
  return (index >= kIntegerCid && index < kDoubleCid);
}

inline bool RawObject::IsStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  ASSERT(kOneByteStringCid == kStringCid + 1 &&
         kTwoByteStringCid == kStringCid + 2 &&
         kFourByteStringCid == kStringCid + 3 &&
         kExternalOneByteStringCid == kStringCid + 4 &&
         kExternalTwoByteStringCid == kStringCid + 5 &&
         kExternalFourByteStringCid == kStringCid + 6 &&
         kBoolCid == kStringCid + 7);
  return (index >= kStringCid && index < kBoolCid);
}

inline bool RawObject::IsOneByteStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  ASSERT(kOneByteStringCid == kStringCid + 1 &&
         kTwoByteStringCid == kStringCid + 2 &&
         kFourByteStringCid == kStringCid + 3 &&
         kExternalOneByteStringCid == kStringCid + 4 &&
         kExternalTwoByteStringCid == kStringCid + 5 &&
         kExternalFourByteStringCid == kStringCid + 6 &&
         kBoolCid == kStringCid + 7);
  return (index == kOneByteStringCid || index == kExternalOneByteStringCid);
}

inline bool RawObject::IsTwoByteStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  ASSERT(kOneByteStringCid == kStringCid + 1 &&
         kTwoByteStringCid == kStringCid + 2 &&
         kFourByteStringCid == kStringCid + 3 &&
         kExternalOneByteStringCid == kStringCid + 4 &&
         kExternalTwoByteStringCid == kStringCid + 5 &&
         kExternalFourByteStringCid == kStringCid + 6 &&
         kBoolCid == kStringCid + 7);
  return (index == kOneByteStringCid ||
          index == kTwoByteStringCid ||
          index == kExternalOneByteStringCid ||
          index == kExternalTwoByteStringCid);
}

inline bool RawObject::IsExternalStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  ASSERT(kOneByteStringCid == kStringCid + 1 &&
         kTwoByteStringCid == kStringCid + 2 &&
         kFourByteStringCid == kStringCid + 3 &&
         kExternalOneByteStringCid == kStringCid + 4 &&
         kExternalTwoByteStringCid == kStringCid + 5 &&
         kExternalFourByteStringCid == kStringCid + 6 &&
         kBoolCid == kStringCid + 7);
  return (index == kExternalOneByteStringCid ||
          index == kExternalTwoByteStringCid ||
          index == kExternalFourByteStringCid);
}

inline bool RawObject::IsBuiltinListClassId(intptr_t index) {
  // Make sure this function is updated when new builtin List types are added.
  ASSERT(kImmutableArrayCid == kArrayCid + 1 &&
         kGrowableObjectArrayCid == kArrayCid + 2 &&
         kByteArrayCid == kArrayCid + 3);
  return (index >= kArrayCid && index < kByteArrayCid) ||
      IsByteArrayClassId(index);
}

inline bool RawObject::IsByteArrayClassId(intptr_t index) {
  // Make sure this function is updated when new ByteArray types are added.
  ASSERT(kInt8ArrayCid == kByteArrayCid + 1 &&
         kUint8ArrayCid == kByteArrayCid + 2 &&
         kInt16ArrayCid == kByteArrayCid + 3 &&
         kUint16ArrayCid == kByteArrayCid + 4 &&
         kInt32ArrayCid == kByteArrayCid + 5 &&
         kUint32ArrayCid == kByteArrayCid + 6 &&
         kInt64ArrayCid == kByteArrayCid + 7 &&
         kUint64ArrayCid == kByteArrayCid + 8 &&
         kFloat32ArrayCid == kByteArrayCid + 9 &&
         kFloat64ArrayCid == kByteArrayCid + 10 &&
         kExternalInt8ArrayCid == kByteArrayCid + 11 &&
         kExternalUint8ArrayCid == kByteArrayCid + 12 &&
         kExternalInt16ArrayCid == kByteArrayCid + 13 &&
         kExternalUint16ArrayCid == kByteArrayCid + 14 &&
         kExternalInt32ArrayCid == kByteArrayCid + 15 &&
         kExternalUint32ArrayCid == kByteArrayCid + 16 &&
         kExternalInt64ArrayCid == kByteArrayCid + 17 &&
         kExternalUint64ArrayCid == kByteArrayCid + 18 &&
         kExternalFloat32ArrayCid == kByteArrayCid + 19 &&
         kExternalFloat64ArrayCid == kByteArrayCid + 20 &&
         kStacktraceCid == kByteArrayCid + 21);
  return (index >= kByteArrayCid && index <= kExternalFloat64ArrayCid);
}

}  // namespace dart

#endif  // VM_RAW_OBJECT_H_
