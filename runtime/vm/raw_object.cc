// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/raw_object.h"

#include "vm/class_table.h"
#include "vm/dart.h"
#include "vm/heap/become.h"
#include "vm/heap/freelist.h"
#include "vm/isolate.h"
#include "vm/isolate_reload.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/visitor.h"

namespace dart {

bool UntaggedObject::InVMIsolateHeap() const {
  // All "vm-isolate" objects are pre-marked and in old space
  // (see [Object::FinalizeVMIsolate]).
  if (!IsOldObject() || !IsMarked()) return false;

  auto heap = Dart::vm_isolate_group()->heap();
  ASSERT(heap->UsedInWords(Heap::kNew) == 0);
  return heap->old_space()->ContainsUnsafe(ToAddr(this));
}

void ObjectPtr::Validate(IsolateGroup* isolate_group) const {
  // All Smi values are valid.
  if (!IsHeapObject()) {
    return;
  }
  // Slightly more readable than a segfault.
  if (tagged_pointer_ == kHeapObjectTag) {
    FATAL("RAW_NULL encountered");
  }
  untag()->Validate(isolate_group);
}

void UntaggedObject::Validate(IsolateGroup* isolate_group) const {
  if (static_cast<uword>(Object::void_class_) == kHeapObjectTag) {
    // Validation relies on properly initialized class classes. Skip if the
    // VM is still being initialized.
    return;
  }
  // Validate that the tags_ field is sensible.
  uword tags = tags_;
  if (IsNewObject()) {
    if (!NewBit::decode(tags)) {
      FATAL("New object missing kNewBit: %" Px "\n", tags);
    }
    if (OldBit::decode(tags)) {
      FATAL("New object has kOldBit: %" Px "\n", tags);
    }
    if (OldAndNotMarkedBit::decode(tags)) {
      FATAL("New object has kOldAndNotMarkedBit: %" Px "\n", tags);
    }
    if (OldAndNotRememberedBit::decode(tags)) {
      FATAL("New object has kOldAndNotRememberedBit: %" Px "\n", tags);
    }
  } else {
    if (NewBit::decode(tags)) {
      FATAL("Old object has kNewBit: %" Px "\n", tags);
    }
    if (!OldBit::decode(tags)) {
      FATAL("Old object missing kOldBit: %" Px "\n", tags);
    }
  }
  const intptr_t class_id = ClassIdTag::decode(tags);
  if (!isolate_group->class_table()->IsValidIndex(class_id)) {
    FATAL("Invalid class id encountered %" Pd "\n", class_id);
  }
  if (class_id == kNullCid &&
      isolate_group->class_table()->HasValidClassAt(class_id)) {
    // Null class not yet initialized; skip.
    return;
  }
  intptr_t size_from_tags = SizeTag::decode(tags);
  intptr_t size_from_class = HeapSizeFromClass(tags);
  if ((size_from_tags != 0) && (size_from_tags != size_from_class)) {
    FATAL(
        "Inconsistent size encountered "
        "cid: %" Pd ", size_from_tags: %" Pd ", size_from_class: %" Pd "\n",
        class_id, size_from_tags, size_from_class);
  }
}

// Can't look at the class object because it can be called during
// compaction when the class objects are moving. Can use the class
// id in the header and the sizes in the Class Table.
// Cannot deference ptr()->tags_. May dereference other parts of the object.
intptr_t UntaggedObject::HeapSizeFromClass(uword tags) const {
  intptr_t class_id = ClassIdTag::decode(tags);
  intptr_t instance_size = 0;
  switch (class_id) {
    case kCodeCid: {
      const CodePtr raw_code = static_cast<const CodePtr>(this);
      intptr_t pointer_offsets_length =
          Code::PtrOffBits::decode(raw_code->untag()->state_bits_);
      instance_size = Code::InstanceSize(pointer_offsets_length);
      break;
    }
    case kInstructionsCid: {
      const InstructionsPtr raw_instructions =
          static_cast<const InstructionsPtr>(this);
      intptr_t instructions_size = Instructions::Size(raw_instructions);
      instance_size = Instructions::InstanceSize(instructions_size);
      break;
    }
    case kInstructionsSectionCid: {
      const InstructionsSectionPtr raw_section =
          static_cast<const InstructionsSectionPtr>(this);
      intptr_t section_size = InstructionsSection::Size(raw_section);
      instance_size = InstructionsSection::InstanceSize(section_size);
      break;
    }
    case kContextCid: {
      const ContextPtr raw_context = static_cast<const ContextPtr>(this);
      intptr_t num_variables = raw_context->untag()->num_variables_;
      instance_size = Context::InstanceSize(num_variables);
      break;
    }
    case kContextScopeCid: {
      const ContextScopePtr raw_context_scope =
          static_cast<const ContextScopePtr>(this);
      intptr_t num_variables = raw_context_scope->untag()->num_variables_;
      instance_size = ContextScope::InstanceSize(num_variables);
      break;
    }
    case kOneByteStringCid: {
      const OneByteStringPtr raw_string =
          static_cast<const OneByteStringPtr>(this);
      intptr_t string_length = Smi::Value(raw_string->untag()->length());
      instance_size = OneByteString::InstanceSize(string_length);
      break;
    }
    case kTwoByteStringCid: {
      const TwoByteStringPtr raw_string =
          static_cast<const TwoByteStringPtr>(this);
      intptr_t string_length = Smi::Value(raw_string->untag()->length());
      instance_size = TwoByteString::InstanceSize(string_length);
      break;
    }
    case kArrayCid:
    case kImmutableArrayCid: {
      const ArrayPtr raw_array = static_cast<const ArrayPtr>(this);
      intptr_t array_length =
          Smi::Value(raw_array->untag()->length<std::memory_order_acquire>());
      instance_size = Array::InstanceSize(array_length);
      break;
    }
    case kWeakArrayCid: {
      const WeakArrayPtr raw_array = static_cast<const WeakArrayPtr>(this);
      intptr_t array_length = Smi::Value(raw_array->untag()->length());
      instance_size = WeakArray::InstanceSize(array_length);
      break;
    }
    case kObjectPoolCid: {
      const ObjectPoolPtr raw_object_pool =
          static_cast<const ObjectPoolPtr>(this);
      intptr_t len = raw_object_pool->untag()->length_;
      instance_size = ObjectPool::InstanceSize(len);
      break;
    }
    case kRecordCid: {
      const RecordPtr raw_record = static_cast<const RecordPtr>(this);
      intptr_t num_fields =
          RecordShape(raw_record->untag()->shape()).num_fields();
      instance_size = Record::InstanceSize(num_fields);
      break;
    }
#define SIZE_FROM_CLASS(clazz) case kTypedData##clazz##Cid:
      CLASS_LIST_TYPED_DATA(SIZE_FROM_CLASS) {
        const TypedDataPtr raw_obj = static_cast<const TypedDataPtr>(this);
        intptr_t array_len = Smi::Value(raw_obj->untag()->length());
        intptr_t lengthInBytes =
            array_len * TypedData::ElementSizeInBytes(class_id);
        instance_size = TypedData::InstanceSize(lengthInBytes);
        break;
      }
#undef SIZE_FROM_CLASS
    case kPointerCid:
      instance_size = Pointer::InstanceSize();
      break;
    case kSuspendStateCid: {
      const SuspendStatePtr raw_suspend_state =
          static_cast<const SuspendStatePtr>(this);
      intptr_t frame_capacity = raw_suspend_state->untag()->frame_capacity();
      instance_size = SuspendState::InstanceSize(frame_capacity);
      break;
    }
    case kTypeArgumentsCid: {
      const TypeArgumentsPtr raw_array =
          static_cast<const TypeArgumentsPtr>(this);
      intptr_t array_length = Smi::Value(raw_array->untag()->length());
      instance_size = TypeArguments::InstanceSize(array_length);
      break;
    }
    case kPcDescriptorsCid: {
      const PcDescriptorsPtr raw_descriptors =
          static_cast<const PcDescriptorsPtr>(this);
      intptr_t length = raw_descriptors->untag()->length_;
      instance_size = PcDescriptors::InstanceSize(length);
      break;
    }
    case kCodeSourceMapCid: {
      const CodeSourceMapPtr raw_code_source_map =
          static_cast<const CodeSourceMapPtr>(this);
      intptr_t length = raw_code_source_map->untag()->length_;
      instance_size = CodeSourceMap::InstanceSize(length);
      break;
    }
    case kCompressedStackMapsCid: {
      const CompressedStackMapsPtr maps =
          static_cast<const CompressedStackMapsPtr>(this);
      intptr_t length = CompressedStackMaps::PayloadSizeOf(maps);
      instance_size = CompressedStackMaps::InstanceSize(length);
      break;
    }
    case kLocalVarDescriptorsCid: {
      const LocalVarDescriptorsPtr raw_descriptors =
          static_cast<const LocalVarDescriptorsPtr>(this);
      intptr_t num_descriptors = raw_descriptors->untag()->num_entries_;
      instance_size = LocalVarDescriptors::InstanceSize(num_descriptors);
      break;
    }
    case kExceptionHandlersCid: {
      const ExceptionHandlersPtr raw_handlers =
          static_cast<const ExceptionHandlersPtr>(this);
      intptr_t num_handlers = raw_handlers->untag()->num_entries();
      instance_size = ExceptionHandlers::InstanceSize(num_handlers);
      break;
    }
    case kFreeListElement: {
      uword addr = UntaggedObject::ToAddr(this);
      FreeListElement* element = reinterpret_cast<FreeListElement*>(addr);
      instance_size = element->HeapSize(tags);
      break;
    }
    case kForwardingCorpse: {
      uword addr = UntaggedObject::ToAddr(this);
      ForwardingCorpse* element = reinterpret_cast<ForwardingCorpse*>(addr);
      instance_size = element->HeapSize(tags);
      break;
    }
    case kWeakSerializationReferenceCid: {
      instance_size = WeakSerializationReference::InstanceSize();
      break;
    }
    default: {
      // Get the (constant) instance size out of the class object.
      // TODO(koda): Add Size(ClassTable*) interface to allow caching in loops.
      auto isolate_group = IsolateGroup::Current();
#if defined(DEBUG)
      auto class_table = isolate_group->heap_walk_class_table();
      if (!class_table->IsValidIndex(class_id) ||
          !class_table->HasValidClassAt(class_id)) {
        FATAL("Invalid cid: %" Pd ", obj: %p, tags: %x. Corrupt heap?",
              class_id, this, static_cast<uint32_t>(tags));
      }
      ASSERT(class_table->SizeAt(class_id) > 0);
#endif  // DEBUG
      instance_size = isolate_group->heap_walk_class_table()->SizeAt(class_id);
    }
  }
  ASSERT(instance_size != 0);
#if defined(DEBUG)
  intptr_t tags_size = SizeTag::decode(tags);
  if ((class_id == kArrayCid) && (instance_size > tags_size && tags_size > 0)) {
    // TODO(22501): Array::MakeFixedLength could be in the process of shrinking
    // the array (see comment therein), having already updated the tags but not
    // yet set the new length. Wait a millisecond and try again.
    int retries_remaining = 1000;  // ... but not forever.
    do {
      OS::Sleep(1);
      const ArrayPtr raw_array = static_cast<const ArrayPtr>(this);
      intptr_t array_length = Smi::Value(raw_array->untag()->length());
      instance_size = Array::InstanceSize(array_length);
    } while ((instance_size > tags_size) && (--retries_remaining > 0));
  }
  if ((instance_size != tags_size) && (tags_size != 0)) {
    FATAL("Size mismatch: %" Pd " from class vs %" Pd " from tags %" Px "\n",
          instance_size, tags_size, tags);
  }
#endif  // DEBUG
  return instance_size;
}

intptr_t UntaggedObject::VisitPointersPredefined(ObjectPointerVisitor* visitor,
                                                 intptr_t class_id) {
  ASSERT(class_id < kNumPredefinedCids);

  intptr_t size = 0;

  switch (class_id) {
#define RAW_VISITPOINTERS(clazz)                                               \
  case k##clazz##Cid: {                                                        \
    clazz##Ptr raw_obj = static_cast<clazz##Ptr>(this);                        \
    size = Untagged##clazz::Visit##clazz##Pointers(raw_obj, visitor);          \
    break;                                                                     \
  }
    CLASS_LIST_NO_OBJECT(RAW_VISITPOINTERS)
#undef RAW_VISITPOINTERS
#define RAW_VISITPOINTERS(clazz) case kTypedData##clazz##Cid:
    CLASS_LIST_TYPED_DATA(RAW_VISITPOINTERS) {
      TypedDataPtr raw_obj = static_cast<TypedDataPtr>(this);
      size = UntaggedTypedData::VisitTypedDataPointers(raw_obj, visitor);
      break;
    }
#undef RAW_VISITPOINTERS
#define RAW_VISITPOINTERS(clazz) case kExternalTypedData##clazz##Cid:
    CLASS_LIST_TYPED_DATA(RAW_VISITPOINTERS) {
      auto raw_obj = static_cast<ExternalTypedDataPtr>(this);
      size = UntaggedExternalTypedData::VisitExternalTypedDataPointers(raw_obj,
                                                                       visitor);
      break;
    }
#undef RAW_VISITPOINTERS
    case kByteDataViewCid:
    case kUnmodifiableByteDataViewCid:
#define RAW_VISITPOINTERS(clazz)                                               \
  case kTypedData##clazz##ViewCid:                                             \
  case kUnmodifiableTypedData##clazz##ViewCid:
      CLASS_LIST_TYPED_DATA(RAW_VISITPOINTERS) {
        auto raw_obj = static_cast<TypedDataViewPtr>(this);
        size =
            UntaggedTypedDataView::VisitTypedDataViewPointers(raw_obj, visitor);
        break;
      }
#undef RAW_VISITPOINTERS
    case kByteBufferCid: {
      InstancePtr raw_obj = static_cast<InstancePtr>(this);
      size = UntaggedInstance::VisitInstancePointers(raw_obj, visitor);
      break;
    }
#define RAW_VISITPOINTERS(clazz) case kFfi##clazz##Cid:
      CLASS_LIST_FFI_TYPE_MARKER(RAW_VISITPOINTERS) {
        // NativeType do not have any fields or type arguments.
        size = HeapSize();
        break;
      }
#undef RAW_VISITPOINTERS
    case kFreeListElement: {
      uword addr = UntaggedObject::ToAddr(this);
      FreeListElement* element = reinterpret_cast<FreeListElement*>(addr);
      size = element->HeapSize();
      break;
    }
    case kForwardingCorpse: {
      uword addr = UntaggedObject::ToAddr(this);
      ForwardingCorpse* forwarder = reinterpret_cast<ForwardingCorpse*>(addr);
      size = forwarder->HeapSize();
      break;
    }
    case kNullCid:
    case kNeverCid:
      size = HeapSize();
      break;
    default:
      FATAL("Invalid cid: %" Pd ", obj: %p, tags: %x. Corrupt heap?", class_id,
            this, static_cast<uint32_t>(tags_));
      break;
  }

#if defined(DEBUG)
  ASSERT(size != 0);
  const intptr_t expected_size = HeapSize();

  // In general we expect that visitors return exactly the same size that
  // HeapSize would compute. However in case of Arrays we might have a
  // discrepancy when concurrently visiting an array that is being shrunk with
  // Array::MakeFixedLength: the visitor might have visited the full array while
  // here we are observing a smaller HeapSize().
  ASSERT(size == expected_size ||
         (class_id == kArrayCid && size > expected_size));
  return size;  // Prefer larger size.
#else
  return size;
#endif
}

void UntaggedObject::VisitPointersPrecise(ObjectPointerVisitor* visitor) {
  intptr_t class_id = GetClassId();
  if ((class_id != kInstanceCid) && (class_id < kNumPredefinedCids)) {
    VisitPointersPredefined(visitor, class_id);
    return;
  }

  // N.B.: Not using the heap size!
  uword next_field_offset = visitor->class_table()
                                ->At(class_id)
                                ->untag()
                                ->host_next_field_offset_in_words_
                            << kCompressedWordSizeLog2;
  ASSERT(next_field_offset > 0);
  uword obj_addr = UntaggedObject::ToAddr(this);
  uword from = obj_addr + sizeof(UntaggedObject);
  uword to = obj_addr + next_field_offset - kCompressedWordSize;
  const auto first = reinterpret_cast<CompressedObjectPtr*>(from);
  const auto last = reinterpret_cast<CompressedObjectPtr*>(to);

  const auto unboxed_fields_bitmap =
      visitor->class_table()->GetUnboxedFieldsMapAt(class_id);

  if (!unboxed_fields_bitmap.IsEmpty()) {
    intptr_t bit = sizeof(UntaggedObject) / kCompressedWordSize;
    for (CompressedObjectPtr* current = first; current <= last; current++) {
      if (!unboxed_fields_bitmap.Get(bit++)) {
        visitor->VisitCompressedPointers(heap_base(), current, current);
      }
    }
  } else {
    visitor->VisitCompressedPointers(heap_base(), first, last);
  }
}

// Most objects are visited with this function. It calls the from() and to()
// methods on the raw object to get the first and last cells that need
// visiting.
#define REGULAR_VISITOR(Type)                                                  \
  intptr_t Untagged##Type::Visit##Type##Pointers(                              \
      Type##Ptr raw_obj, ObjectPointerVisitor* visitor) {                      \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    ASSERT_UNCOMPRESSED(Type);                                                 \
    visitor->VisitPointers(raw_obj->untag()->from(), raw_obj->untag()->to());  \
    return Type::InstanceSize();                                               \
  }

#if !defined(DART_COMPRESSED_POINTERS)
#define COMPRESSED_VISITOR(Type) REGULAR_VISITOR(Type)
#else
#define COMPRESSED_VISITOR(Type)                                               \
  intptr_t Untagged##Type::Visit##Type##Pointers(                              \
      Type##Ptr raw_obj, ObjectPointerVisitor* visitor) {                      \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    ASSERT_COMPRESSED(Type);                                                   \
    visitor->VisitCompressedPointers(raw_obj->heap_base(),                     \
                                     raw_obj->untag()->from(),                 \
                                     raw_obj->untag()->to());                  \
    return Type::InstanceSize();                                               \
  }
#endif

// It calls the from() and to() methods on the raw object to get the first and
// last cells that need visiting.
//
// Though as opposed to Similar to [REGULAR_VISITOR] this visitor will call the
// specialized VisitTypedDataViewPointers
#define TYPED_DATA_VIEW_VISITOR(Type)                                          \
  intptr_t Untagged##Type::Visit##Type##Pointers(                              \
      Type##Ptr raw_obj, ObjectPointerVisitor* visitor) {                      \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    ASSERT_COMPRESSED(Type);                                                   \
    visitor->VisitTypedDataViewPointers(raw_obj, raw_obj->untag()->from(),     \
                                        raw_obj->untag()->to());               \
    return Type::InstanceSize();                                               \
  }

// For variable length objects. get_length is a code snippet that gets the
// length of the object, which is passed to InstanceSize and the to() method.
#define VARIABLE_VISITOR(Type, get_length)                                     \
  intptr_t Untagged##Type::Visit##Type##Pointers(                              \
      Type##Ptr raw_obj, ObjectPointerVisitor* visitor) {                      \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    intptr_t length = get_length;                                              \
    visitor->VisitPointers(raw_obj->untag()->from(),                           \
                           raw_obj->untag()->to(length));                      \
    return Type::InstanceSize(length);                                         \
  }

#if !defined(DART_COMPRESSED_POINTERS)
#define VARIABLE_COMPRESSED_VISITOR(Type, get_length)                          \
  VARIABLE_VISITOR(Type, get_length)
#else
#define VARIABLE_COMPRESSED_VISITOR(Type, get_length)                          \
  intptr_t Untagged##Type::Visit##Type##Pointers(                              \
      Type##Ptr raw_obj, ObjectPointerVisitor* visitor) {                      \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    intptr_t length = get_length;                                              \
    visitor->VisitCompressedPointers(raw_obj->heap_base(),                     \
                                     raw_obj->untag()->from(),                 \
                                     raw_obj->untag()->to(length));            \
    return Type::InstanceSize(length);                                         \
  }
#endif

// For fixed-length objects that don't have any pointers that need visiting.
#define NULL_VISITOR(Type)                                                     \
  intptr_t Untagged##Type::Visit##Type##Pointers(                              \
      Type##Ptr raw_obj, ObjectPointerVisitor* visitor) {                      \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    ASSERT_NOTHING_TO_VISIT(Type);                                             \
    return Type::InstanceSize();                                               \
  }

// For objects that don't have any pointers that need visiting, but have a
// variable length.
#define VARIABLE_NULL_VISITOR(Type, get_length)                                \
  intptr_t Untagged##Type::Visit##Type##Pointers(                              \
      Type##Ptr raw_obj, ObjectPointerVisitor* visitor) {                      \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    ASSERT_NOTHING_TO_VISIT(Type);                                             \
    intptr_t length = get_length;                                              \
    return Type::InstanceSize(length);                                         \
  }

// For objects that are never instantiated on the heap.
#define UNREACHABLE_VISITOR(Type)                                              \
  intptr_t Untagged##Type::Visit##Type##Pointers(                              \
      Type##Ptr raw_obj, ObjectPointerVisitor* visitor) {                      \
    UNREACHABLE();                                                             \
    return 0;                                                                  \
  }

COMPRESSED_VISITOR(Class)
COMPRESSED_VISITOR(PatchClass)
COMPRESSED_VISITOR(ClosureData)
COMPRESSED_VISITOR(FfiTrampolineData)
COMPRESSED_VISITOR(Script)
COMPRESSED_VISITOR(Library)
COMPRESSED_VISITOR(Namespace)
COMPRESSED_VISITOR(KernelProgramInfo)
COMPRESSED_VISITOR(WeakSerializationReference)
VARIABLE_COMPRESSED_VISITOR(WeakArray, Smi::Value(raw_obj->untag()->length()))
COMPRESSED_VISITOR(Type)
COMPRESSED_VISITOR(FunctionType)
COMPRESSED_VISITOR(RecordType)
COMPRESSED_VISITOR(TypeParameter)
COMPRESSED_VISITOR(Function)
COMPRESSED_VISITOR(Closure)
COMPRESSED_VISITOR(LibraryPrefix)
REGULAR_VISITOR(SingleTargetCache)
REGULAR_VISITOR(UnlinkedCall)
NULL_VISITOR(MonomorphicSmiableCall)
REGULAR_VISITOR(ICData)
REGULAR_VISITOR(MegamorphicCache)
COMPRESSED_VISITOR(ApiError)
COMPRESSED_VISITOR(LanguageError)
COMPRESSED_VISITOR(UnhandledException)
COMPRESSED_VISITOR(UnwindError)
COMPRESSED_VISITOR(ExternalOneByteString)
COMPRESSED_VISITOR(ExternalTwoByteString)
COMPRESSED_VISITOR(GrowableObjectArray)
COMPRESSED_VISITOR(Map)
COMPRESSED_VISITOR(Set)
COMPRESSED_VISITOR(ExternalTypedData)
TYPED_DATA_VIEW_VISITOR(TypedDataView)
COMPRESSED_VISITOR(ReceivePort)
COMPRESSED_VISITOR(StackTrace)
COMPRESSED_VISITOR(RegExp)
COMPRESSED_VISITOR(WeakProperty)
COMPRESSED_VISITOR(WeakReference)
COMPRESSED_VISITOR(Finalizer)
COMPRESSED_VISITOR(FinalizerEntry)
COMPRESSED_VISITOR(NativeFinalizer)
COMPRESSED_VISITOR(MirrorReference)
COMPRESSED_VISITOR(UserTag)
REGULAR_VISITOR(SubtypeTestCache)
COMPRESSED_VISITOR(LoadingUnit)
COMPRESSED_VISITOR(TypeParameters)
VARIABLE_COMPRESSED_VISITOR(TypeArguments,
                            Smi::Value(raw_obj->untag()->length()))
VARIABLE_COMPRESSED_VISITOR(LocalVarDescriptors, raw_obj->untag()->num_entries_)
VARIABLE_COMPRESSED_VISITOR(ExceptionHandlers, raw_obj->untag()->num_entries())
VARIABLE_COMPRESSED_VISITOR(Context, raw_obj->untag()->num_variables_)
VARIABLE_COMPRESSED_VISITOR(Array, Smi::Value(raw_obj->untag()->length()))
VARIABLE_COMPRESSED_VISITOR(
    TypedData,
    TypedData::ElementSizeInBytes(raw_obj->GetClassId()) *
        Smi::Value(raw_obj->untag()->length()))
VARIABLE_COMPRESSED_VISITOR(ContextScope, raw_obj->untag()->num_variables_)
VARIABLE_COMPRESSED_VISITOR(Record,
                            RecordShape(raw_obj->untag()->shape()).num_fields())
NULL_VISITOR(Sentinel)
REGULAR_VISITOR(InstructionsTable)
NULL_VISITOR(Mint)
NULL_VISITOR(Double)
NULL_VISITOR(Float32x4)
NULL_VISITOR(Int32x4)
NULL_VISITOR(Float64x2)
NULL_VISITOR(Bool)
NULL_VISITOR(Capability)
NULL_VISITOR(SendPort)
NULL_VISITOR(TransferableTypedData)
COMPRESSED_VISITOR(Pointer)
NULL_VISITOR(DynamicLibrary)
VARIABLE_NULL_VISITOR(Instructions, Instructions::Size(raw_obj))
VARIABLE_NULL_VISITOR(InstructionsSection, InstructionsSection::Size(raw_obj))
VARIABLE_NULL_VISITOR(PcDescriptors, raw_obj->untag()->length_)
VARIABLE_NULL_VISITOR(CodeSourceMap, raw_obj->untag()->length_)
VARIABLE_NULL_VISITOR(CompressedStackMaps,
                      CompressedStackMaps::PayloadSizeOf(raw_obj))
VARIABLE_NULL_VISITOR(OneByteString, Smi::Value(raw_obj->untag()->length()))
VARIABLE_NULL_VISITOR(TwoByteString, Smi::Value(raw_obj->untag()->length()))
// Abstract types don't have their visitor called.
UNREACHABLE_VISITOR(AbstractType)
UNREACHABLE_VISITOR(CallSiteData)
UNREACHABLE_VISITOR(TypedDataBase)
UNREACHABLE_VISITOR(Error)
UNREACHABLE_VISITOR(FinalizerBase)
UNREACHABLE_VISITOR(Number)
UNREACHABLE_VISITOR(Integer)
UNREACHABLE_VISITOR(String)
UNREACHABLE_VISITOR(FutureOr)
// Smi has no heap representation.
UNREACHABLE_VISITOR(Smi)

intptr_t UntaggedField::VisitFieldPointers(FieldPtr raw_obj,
                                           ObjectPointerVisitor* visitor) {
  ASSERT(raw_obj->IsHeapObject());
  ASSERT_COMPRESSED(Field);
  visitor->VisitCompressedPointers(
      raw_obj->heap_base(), raw_obj->untag()->from(), raw_obj->untag()->to());

  if (visitor->trace_values_through_fields()) {
    if (Field::StaticBit::decode(raw_obj->untag()->kind_bits_)) {
      visitor->isolate_group()->ForEachIsolate(
          [&](Isolate* isolate) {
            intptr_t index =
                Smi::Value(raw_obj->untag()->host_offset_or_field_id());
            visitor->VisitPointer(&isolate->field_table()->table()[index]);
          },
          /*at_safepoint=*/true);
    }
  }
  return Field::InstanceSize();
}

intptr_t UntaggedSuspendState::VisitSuspendStatePointers(
    SuspendStatePtr raw_obj,
    ObjectPointerVisitor* visitor) {
  ASSERT(raw_obj->IsHeapObject());
  ASSERT_COMPRESSED(SuspendState);

  if (visitor->CanVisitSuspendStatePointers(raw_obj)) {
    visitor->VisitCompressedPointers(
        raw_obj->heap_base(), raw_obj->untag()->from(), raw_obj->untag()->to());

    const uword pc = raw_obj->untag()->pc_;
    if (pc != 0) {
      Thread* thread = Thread::Current();
      ASSERT(thread != nullptr);
      ASSERT(thread->isolate_group() == visitor->isolate_group());
      const uword sp = reinterpret_cast<uword>(raw_obj->untag()->payload());
      StackFrame frame(thread);
      frame.pc_ = pc;
      frame.sp_ = sp;
      frame.fp_ = sp + raw_obj->untag()->frame_size_;
      frame.VisitObjectPointers(visitor);
    }
  }

  return SuspendState::InstanceSize(raw_obj->untag()->frame_capacity());
}

bool UntaggedCode::ContainsPC(const ObjectPtr raw_obj, uword pc) {
  if (!raw_obj->IsCode()) return false;
  auto const raw_code = static_cast<const CodePtr>(raw_obj);
  const uword start = Code::PayloadStartOf(raw_code);
  const uword size = Code::PayloadSizeOf(raw_code);
  return (pc - start) <= size;  // pc may point just past last instruction.
}

intptr_t UntaggedCode::VisitCodePointers(CodePtr raw_obj,
                                         ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->untag()->from(), raw_obj->untag()->to());

  UntaggedCode* obj = raw_obj->untag();
  intptr_t length = Code::PtrOffBits::decode(obj->state_bits_);
#if defined(TARGET_ARCH_IA32)
  // On IA32 only we embed pointers to objects directly in the generated
  // instructions. The variable portion of a Code object describes where to
  // find those pointers for tracing.
  if (Code::AliveBit::decode(obj->state_bits_)) {
    uword entry_point = Code::PayloadStartOf(raw_obj);
    for (intptr_t i = 0; i < length; i++) {
      int32_t offset = obj->data()[i];
      visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(entry_point + offset));
    }
  }
  return Code::InstanceSize(length);
#else
  // On all other architectures, objects are referenced indirectly through
  // either an ObjectPool or Thread.
  ASSERT(length == 0);
  return Code::InstanceSize(0);
#endif
}

intptr_t UntaggedObjectPool::VisitObjectPoolPointers(
    ObjectPoolPtr raw_obj,
    ObjectPointerVisitor* visitor) {
  const intptr_t length = raw_obj->untag()->length_;
  UntaggedObjectPool::Entry* entries = raw_obj->untag()->data();
  uint8_t* entry_bits = raw_obj->untag()->entry_bits();
  for (intptr_t i = 0; i < length; ++i) {
    ObjectPool::EntryType entry_type =
        ObjectPool::TypeBits::decode(entry_bits[i]);
    if (entry_type == ObjectPool::EntryType::kTaggedObject) {
      visitor->VisitPointer(&entries[i].raw_obj_);
    }
  }
  return ObjectPool::InstanceSize(length);
}

bool UntaggedInstructions::ContainsPC(const InstructionsPtr raw_instr,
                                      uword pc) {
  const uword start = Instructions::PayloadStart(raw_instr);
  const uword size = Instructions::Size(raw_instr);
  // We use <= instead of < here because the saved-pc can be outside the
  // instruction stream if the last instruction is a call we don't expect to
  // return (e.g. because it throws an exception).
  return (pc - start) <= size;
}

intptr_t UntaggedInstance::VisitInstancePointers(
    InstancePtr raw_obj,
    ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  uword tags = raw_obj->untag()->tags_;
  intptr_t instance_size = SizeTag::decode(tags);
  if (instance_size == 0) {
    instance_size = visitor->class_table()->SizeAt(raw_obj->GetClassId());
  }

  // Calculate the first and last raw object pointer fields.
  uword obj_addr = UntaggedObject::ToAddr(raw_obj);
  uword from = obj_addr + sizeof(UntaggedObject);
  uword to = obj_addr + instance_size - kCompressedWordSize;
  visitor->VisitCompressedPointers(raw_obj->heap_base(),
                                   reinterpret_cast<CompressedObjectPtr*>(from),
                                   reinterpret_cast<CompressedObjectPtr*>(to));
  return instance_size;
}

intptr_t UntaggedImmutableArray::VisitImmutableArrayPointers(
    ImmutableArrayPtr raw_obj,
    ObjectPointerVisitor* visitor) {
  return UntaggedArray::VisitArrayPointers(raw_obj, visitor);
}

intptr_t UntaggedConstMap::VisitConstMapPointers(
    ConstMapPtr raw_obj,
    ObjectPointerVisitor* visitor) {
  return UntaggedMap::VisitMapPointers(raw_obj, visitor);
}

intptr_t UntaggedConstSet::VisitConstSetPointers(
    ConstSetPtr raw_obj,
    ObjectPointerVisitor* visitor) {
  return UntaggedSet::VisitSetPointers(raw_obj, visitor);
}

void UntaggedObject::RememberCard(ObjectPtr const* slot) {
  Page::Of(static_cast<ObjectPtr>(this))->RememberCard(slot);
}

#if defined(DART_COMPRESSED_POINTERS)
void UntaggedObject::RememberCard(CompressedObjectPtr const* slot) {
  Page::Of(static_cast<ObjectPtr>(this))->RememberCard(slot);
}
#endif

DEFINE_LEAF_RUNTIME_ENTRY(void,
                          RememberCard,
                          2,
                          uword /*ObjectPtr*/ object_in,
                          ObjectPtr* slot) {
  ObjectPtr object = static_cast<ObjectPtr>(object_in);
  ASSERT(object->IsOldObject());
  ASSERT(object->untag()->IsCardRemembered());
  Page::Of(object)->RememberCard(slot);
}
END_LEAF_RUNTIME_ENTRY

const char* UntaggedPcDescriptors::KindToCString(Kind k) {
  switch (k) {
#define ENUM_CASE(name, init)                                                  \
  case Kind::k##name:                                                          \
    return #name;
    FOR_EACH_RAW_PC_DESCRIPTOR(ENUM_CASE)
#undef ENUM_CASE
    default:
      return nullptr;
  }
}

bool UntaggedPcDescriptors::ParseKind(const char* cstr, Kind* out) {
  ASSERT(cstr != nullptr && out != nullptr);
#define ENUM_CASE(name, init)                                                  \
  if (strcmp(#name, cstr) == 0) {                                              \
    *out = Kind::k##name;                                                      \
    return true;                                                               \
  }
  FOR_EACH_RAW_PC_DESCRIPTOR(ENUM_CASE)
#undef ENUM_CASE
  return false;
}
#undef PREFIXED_NAME

}  // namespace dart
