// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/raw_object.h"

#include "vm/class_table.h"
#include "vm/dart.h"
#include "vm/heap/become.h"
#include "vm/heap/freelist.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"
#include "vm/visitor.h"

namespace dart {

bool RawObject::InVMIsolateHeap() const {
  return Dart::vm_isolate()->heap()->Contains(ToAddr(this));
}

void RawObject::Validate(Isolate* isolate) const {
  if (Object::void_class_ == reinterpret_cast<RawClass*>(kHeapObjectTag)) {
    // Validation relies on properly initialized class classes. Skip if the
    // VM is still being initialized.
    return;
  }
  // All Smi values are valid.
  if (!IsHeapObject()) {
    return;
  }
  // Slightly more readable than a segfault.
  if (this == reinterpret_cast<RawObject*>(kHeapObjectTag)) {
    FATAL("RAW_NULL encountered");
  }
  // Validate that the tags_ field is sensible.
  uint32_t tags = ptr()->tags_;
  if (IsNewObject()) {
    if (!NewBit::decode(tags)) {
      FATAL1("New object missing kNewBit: %x\n", tags);
    }
    if (OldBit::decode(tags)) {
      FATAL1("New object has kOldBit: %x\n", tags);
    }
    if (OldAndNotMarkedBit::decode(tags)) {
      FATAL1("New object has kOldAndNotMarkedBit: %x\n", tags);
    }
    if (OldAndNotRememberedBit::decode(tags)) {
      FATAL1("New object has kOldAndNotRememberedBit: %x\n", tags);
    }
  } else {
    if (NewBit::decode(tags)) {
      FATAL1("Old object has kNewBit: %x\n", tags);
    }
    if (!OldBit::decode(tags)) {
      FATAL1("Old object missing kOldBit: %x\n", tags);
    }
  }
  intptr_t class_id = ClassIdTag::decode(tags);
  if (!isolate->class_table()->IsValidIndex(class_id)) {
    FATAL1("Invalid class id encountered %" Pd "\n", class_id);
  }
  if ((class_id == kNullCid) &&
      (isolate->class_table()->At(class_id) == NULL)) {
    // Null class not yet initialized; skip.
    return;
  }
  intptr_t size_from_tags = SizeTag::decode(tags);
  intptr_t size_from_class = HeapSizeFromClass();
  if ((size_from_tags != 0) && (size_from_tags != size_from_class)) {
    FATAL3(
        "Inconsistent size encountered "
        "cid: %" Pd ", size_from_tags: %" Pd ", size_from_class: %" Pd "\n",
        class_id, size_from_tags, size_from_class);
  }
}

// Can't look at the class object because it can be called during
// compaction when the class objects are moving. Can use the class
// id in the header and the sizes in the Class Table.
intptr_t RawObject::HeapSizeFromClass() const {
  // Only reasonable to be called on heap objects.
  ASSERT(IsHeapObject());

  intptr_t class_id = GetClassId();
  intptr_t instance_size = 0;
  switch (class_id) {
    case kCodeCid: {
      const RawCode* raw_code = reinterpret_cast<const RawCode*>(this);
      intptr_t pointer_offsets_length =
          Code::PtrOffBits::decode(raw_code->ptr()->state_bits_);
      instance_size = Code::InstanceSize(pointer_offsets_length);
      break;
    }
    case kInstructionsCid: {
      const RawInstructions* raw_instructions =
          reinterpret_cast<const RawInstructions*>(this);
      intptr_t instructions_size = Instructions::Size(raw_instructions);
      instance_size = Instructions::InstanceSize(instructions_size);
      break;
    }
    case kContextCid: {
      const RawContext* raw_context = reinterpret_cast<const RawContext*>(this);
      intptr_t num_variables = raw_context->ptr()->num_variables_;
      instance_size = Context::InstanceSize(num_variables);
      break;
    }
    case kContextScopeCid: {
      const RawContextScope* raw_context_scope =
          reinterpret_cast<const RawContextScope*>(this);
      intptr_t num_variables = raw_context_scope->ptr()->num_variables_;
      instance_size = ContextScope::InstanceSize(num_variables);
      break;
    }
    case kOneByteStringCid: {
      const RawOneByteString* raw_string =
          reinterpret_cast<const RawOneByteString*>(this);
      intptr_t string_length = Smi::Value(raw_string->ptr()->length_);
      instance_size = OneByteString::InstanceSize(string_length);
      break;
    }
    case kTwoByteStringCid: {
      const RawTwoByteString* raw_string =
          reinterpret_cast<const RawTwoByteString*>(this);
      intptr_t string_length = Smi::Value(raw_string->ptr()->length_);
      instance_size = TwoByteString::InstanceSize(string_length);
      break;
    }
    case kArrayCid:
    case kImmutableArrayCid: {
      const RawArray* raw_array = reinterpret_cast<const RawArray*>(this);
      intptr_t array_length = Smi::Value(raw_array->ptr()->length_);
      instance_size = Array::InstanceSize(array_length);
      break;
    }
    case kObjectPoolCid: {
      const RawObjectPool* raw_object_pool =
          reinterpret_cast<const RawObjectPool*>(this);
      intptr_t len = raw_object_pool->ptr()->length_;
      instance_size = ObjectPool::InstanceSize(len);
      break;
    }
#define SIZE_FROM_CLASS(clazz) case kTypedData##clazz##Cid:
      CLASS_LIST_TYPED_DATA(SIZE_FROM_CLASS) {
        const RawTypedData* raw_obj =
            reinterpret_cast<const RawTypedData*>(this);
        intptr_t cid = raw_obj->GetClassId();
        intptr_t array_len = Smi::Value(raw_obj->ptr()->length_);
        intptr_t lengthInBytes = array_len * TypedData::ElementSizeInBytes(cid);
        instance_size = TypedData::InstanceSize(lengthInBytes);
        break;
      }
#undef SIZE_FROM_CLASS
    case kFfiPointerCid:
      instance_size = Pointer::InstanceSize();
      break;
    case kTypeArgumentsCid: {
      const RawTypeArguments* raw_array =
          reinterpret_cast<const RawTypeArguments*>(this);
      intptr_t array_length = Smi::Value(raw_array->ptr()->length_);
      instance_size = TypeArguments::InstanceSize(array_length);
      break;
    }
    case kPcDescriptorsCid: {
      const RawPcDescriptors* raw_descriptors =
          reinterpret_cast<const RawPcDescriptors*>(this);
      intptr_t length = raw_descriptors->ptr()->length_;
      instance_size = PcDescriptors::InstanceSize(length);
      break;
    }
    case kCodeSourceMapCid: {
      const RawCodeSourceMap* raw_code_source_map =
          reinterpret_cast<const RawCodeSourceMap*>(this);
      intptr_t length = raw_code_source_map->ptr()->length_;
      instance_size = CodeSourceMap::InstanceSize(length);
      break;
    }
    case kStackMapCid: {
      const RawStackMap* map = reinterpret_cast<const RawStackMap*>(this);
      intptr_t length = map->ptr()->length_;
      instance_size = StackMap::InstanceSize(length);
      break;
    }
    case kLocalVarDescriptorsCid: {
      const RawLocalVarDescriptors* raw_descriptors =
          reinterpret_cast<const RawLocalVarDescriptors*>(this);
      intptr_t num_descriptors = raw_descriptors->ptr()->num_entries_;
      instance_size = LocalVarDescriptors::InstanceSize(num_descriptors);
      break;
    }
    case kExceptionHandlersCid: {
      const RawExceptionHandlers* raw_handlers =
          reinterpret_cast<const RawExceptionHandlers*>(this);
      intptr_t num_handlers = raw_handlers->ptr()->num_entries_;
      instance_size = ExceptionHandlers::InstanceSize(num_handlers);
      break;
    }
    case kFreeListElement: {
      uword addr = RawObject::ToAddr(this);
      FreeListElement* element = reinterpret_cast<FreeListElement*>(addr);
      instance_size = element->HeapSize();
      break;
    }
    case kForwardingCorpse: {
      uword addr = RawObject::ToAddr(this);
      ForwardingCorpse* element = reinterpret_cast<ForwardingCorpse*>(addr);
      instance_size = element->HeapSize();
      break;
    }
    default: {
      // Get the (constant) instance size out of the class object.
      // TODO(koda): Add Size(ClassTable*) interface to allow caching in loops.
      Isolate* isolate = Isolate::Current();
#if defined(DEBUG)
      ClassTable* class_table = isolate->class_table();
      if (!class_table->IsValidIndex(class_id) ||
          !class_table->HasValidClassAt(class_id)) {
        FATAL2("Invalid class id: %" Pd " from tags %x\n", class_id,
               ptr()->tags_);
      }
#endif  // DEBUG
      instance_size = isolate->GetClassSizeForHeapWalkAt(class_id);
    }
  }
  ASSERT(instance_size != 0);
#if defined(DEBUG)
  uint32_t tags = ptr()->tags_;
  intptr_t tags_size = SizeTag::decode(tags);
  if ((class_id == kArrayCid) && (instance_size > tags_size && tags_size > 0)) {
    // TODO(22501): Array::MakeFixedLength could be in the process of shrinking
    // the array (see comment therein), having already updated the tags but not
    // yet set the new length. Wait a millisecond and try again.
    int retries_remaining = 1000;  // ... but not forever.
    do {
      OS::Sleep(1);
      const RawArray* raw_array = reinterpret_cast<const RawArray*>(this);
      intptr_t array_length = Smi::Value(raw_array->ptr()->length_);
      instance_size = Array::InstanceSize(array_length);
    } while ((instance_size > tags_size) && (--retries_remaining > 0));
  }
  if ((instance_size != tags_size) && (tags_size != 0)) {
    FATAL3("Size mismatch: %" Pd " from class vs %" Pd " from tags %x\n",
           instance_size, tags_size, tags);
  }
#endif  // DEBUG
  return instance_size;
}

intptr_t RawObject::VisitPointersPredefined(ObjectPointerVisitor* visitor,
                                            intptr_t class_id) {
  ASSERT(class_id < kNumPredefinedCids);

  intptr_t size = 0;

  // Only reasonable to be called on heap objects.
  ASSERT(IsHeapObject());

  switch (class_id) {
#define RAW_VISITPOINTERS(clazz)                                               \
  case k##clazz##Cid: {                                                        \
    Raw##clazz* raw_obj = reinterpret_cast<Raw##clazz*>(this);                 \
    size = Raw##clazz::Visit##clazz##Pointers(raw_obj, visitor);               \
    break;                                                                     \
  }
    CLASS_LIST_NO_OBJECT(RAW_VISITPOINTERS)
#undef RAW_VISITPOINTERS
#define RAW_VISITPOINTERS(clazz) case kTypedData##clazz##Cid:
    CLASS_LIST_TYPED_DATA(RAW_VISITPOINTERS) {
      RawTypedData* raw_obj = reinterpret_cast<RawTypedData*>(this);
      size = RawTypedData::VisitTypedDataPointers(raw_obj, visitor);
      break;
    }
#undef RAW_VISITPOINTERS
#define RAW_VISITPOINTERS(clazz) case kExternalTypedData##clazz##Cid:
    CLASS_LIST_TYPED_DATA(RAW_VISITPOINTERS) {
      auto raw_obj = reinterpret_cast<RawExternalTypedData*>(this);
      size = RawExternalTypedData::VisitExternalTypedDataPointers(raw_obj,
                                                                  visitor);
      break;
    }
#undef RAW_VISITPOINTERS
    case kByteDataViewCid:
#define RAW_VISITPOINTERS(clazz) case kTypedData##clazz##ViewCid:
      CLASS_LIST_TYPED_DATA(RAW_VISITPOINTERS) {
        auto raw_obj = reinterpret_cast<RawTypedDataView*>(this);
        size = RawTypedDataView::VisitTypedDataViewPointers(raw_obj, visitor);
        break;
      }
#undef RAW_VISITPOINTERS
    case kByteBufferCid: {
      RawInstance* raw_obj = reinterpret_cast<RawInstance*>(this);
      size = RawInstance::VisitInstancePointers(raw_obj, visitor);
      break;
    }
    case kFfiPointerCid: {
      RawPointer* raw_obj = reinterpret_cast<RawPointer*>(this);
      size = RawPointer::VisitPointerPointers(raw_obj, visitor);
      break;
    }
    case kFfiDynamicLibraryCid: {
      RawDynamicLibrary* raw_obj = reinterpret_cast<RawDynamicLibrary*>(this);
      size = RawDynamicLibrary::VisitDynamicLibraryPointers(raw_obj, visitor);
      break;
    }
    case kFreeListElement: {
      uword addr = RawObject::ToAddr(this);
      FreeListElement* element = reinterpret_cast<FreeListElement*>(addr);
      size = element->HeapSize();
      break;
    }
    case kForwardingCorpse: {
      uword addr = RawObject::ToAddr(this);
      ForwardingCorpse* forwarder = reinterpret_cast<ForwardingCorpse*>(addr);
      size = forwarder->HeapSize();
      break;
    }
    case kNullCid:
      size = HeapSize();
      break;
    default:
      OS::PrintErr("Class Id: %" Pd "\n", class_id);
      UNREACHABLE();
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

bool RawObject::FindObject(FindObjectVisitor* visitor) {
  ASSERT(visitor != NULL);
  return visitor->FindObject(this);
}

// Most objects are visited with this function. It calls the from() and to()
// methods on the raw object to get the first and last cells that need
// visiting.
#define REGULAR_VISITOR(Type)                                                  \
  intptr_t Raw##Type::Visit##Type##Pointers(Raw##Type* raw_obj,                \
                                            ObjectPointerVisitor* visitor) {   \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    ASSERT_UNCOMPRESSED(Type);                                                 \
    visitor->VisitPointers(raw_obj->from(), raw_obj->to());                    \
    return Type::InstanceSize();                                               \
  }

// It calls the from() and to() methods on the raw object to get the first and
// last cells that need visiting.
//
// Though as opposed to Similar to [REGULAR_VISITOR] this visitor will call the
// specializd VisitTypedDataViewPointers
#define TYPED_DATA_VIEW_VISITOR(Type)                                          \
  intptr_t Raw##Type::Visit##Type##Pointers(Raw##Type* raw_obj,                \
                                            ObjectPointerVisitor* visitor) {   \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    ASSERT_UNCOMPRESSED(Type);                                                 \
    visitor->VisitTypedDataViewPointers(raw_obj, raw_obj->from(),              \
                                        raw_obj->to());                        \
    return Type::InstanceSize();                                               \
  }

// For variable length objects. get_length is a code snippet that gets the
// length of the object, which is passed to InstanceSize and the to() method.
#define VARIABLE_VISITOR(Type, get_length)                                     \
  intptr_t Raw##Type::Visit##Type##Pointers(Raw##Type* raw_obj,                \
                                            ObjectPointerVisitor* visitor) {   \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    intptr_t length = get_length;                                              \
    visitor->VisitPointers(raw_obj->from(), raw_obj->to(length));              \
    return Type::InstanceSize(length);                                         \
  }

// For now there are no compressed pointers:
#define COMPRESSED_VISITOR(Type) REGULAR_VISITOR(Type)
#define VARIABLE_COMPRESSED_VISITOR(Type, get_length)                          \
  VARIABLE_VISITOR(Type, get_length)

// For fixed-length objects that don't have any pointers that need visiting.
#define NULL_VISITOR(Type)                                                     \
  intptr_t Raw##Type::Visit##Type##Pointers(Raw##Type* raw_obj,                \
                                            ObjectPointerVisitor* visitor) {   \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    ASSERT_NOTHING_TO_VISIT(Type);                                             \
    return Type::InstanceSize();                                               \
  }

// For objects that don't have any pointers that need visiting, but have a
// variable length.
#define VARIABLE_NULL_VISITOR(Type, get_length)                                \
  intptr_t Raw##Type::Visit##Type##Pointers(Raw##Type* raw_obj,                \
                                            ObjectPointerVisitor* visitor) {   \
    /* Make sure that we got here with the tagged pointer as this. */          \
    ASSERT(raw_obj->IsHeapObject());                                           \
    ASSERT_NOTHING_TO_VISIT(Type);                                             \
    intptr_t length = get_length;                                              \
    return Type::InstanceSize(length);                                         \
  }

// For objects that are never instantiated on the heap.
#define UNREACHABLE_VISITOR(Type)                                              \
  intptr_t Raw##Type::Visit##Type##Pointers(Raw##Type* raw_obj,                \
                                            ObjectPointerVisitor* visitor) {   \
    UNREACHABLE();                                                             \
    return 0;                                                                  \
  }

REGULAR_VISITOR(Class)
REGULAR_VISITOR(Bytecode)
REGULAR_VISITOR(Type)
REGULAR_VISITOR(TypeRef)
REGULAR_VISITOR(TypeParameter)
REGULAR_VISITOR(PatchClass)
REGULAR_VISITOR(Function)
COMPRESSED_VISITOR(Closure)
REGULAR_VISITOR(ClosureData)
REGULAR_VISITOR(SignatureData)
REGULAR_VISITOR(RedirectionData)
REGULAR_VISITOR(FfiTrampolineData)
REGULAR_VISITOR(Field)
REGULAR_VISITOR(Script)
REGULAR_VISITOR(Library)
REGULAR_VISITOR(LibraryPrefix)
REGULAR_VISITOR(Namespace)
REGULAR_VISITOR(ParameterTypeCheck)
REGULAR_VISITOR(SingleTargetCache)
REGULAR_VISITOR(UnlinkedCall)
REGULAR_VISITOR(ICData)
REGULAR_VISITOR(MegamorphicCache)
REGULAR_VISITOR(ApiError)
REGULAR_VISITOR(LanguageError)
REGULAR_VISITOR(UnhandledException)
REGULAR_VISITOR(UnwindError)
REGULAR_VISITOR(ExternalOneByteString)
REGULAR_VISITOR(ExternalTwoByteString)
COMPRESSED_VISITOR(GrowableObjectArray)
COMPRESSED_VISITOR(LinkedHashMap)
COMPRESSED_VISITOR(ExternalTypedData)
TYPED_DATA_VIEW_VISITOR(TypedDataView)
REGULAR_VISITOR(ReceivePort)
REGULAR_VISITOR(StackTrace)
REGULAR_VISITOR(RegExp)
REGULAR_VISITOR(WeakProperty)
REGULAR_VISITOR(MirrorReference)
REGULAR_VISITOR(UserTag)
REGULAR_VISITOR(SubtypeTestCache)
REGULAR_VISITOR(KernelProgramInfo)
VARIABLE_VISITOR(TypeArguments, Smi::Value(raw_obj->ptr()->length_))
VARIABLE_VISITOR(LocalVarDescriptors, raw_obj->ptr()->num_entries_)
VARIABLE_VISITOR(ExceptionHandlers, raw_obj->ptr()->num_entries_)
VARIABLE_VISITOR(Context, raw_obj->ptr()->num_variables_)
VARIABLE_COMPRESSED_VISITOR(Array, Smi::Value(raw_obj->ptr()->length_))
VARIABLE_COMPRESSED_VISITOR(
    TypedData,
    TypedData::ElementSizeInBytes(raw_obj->GetClassId()) *
        Smi::Value(raw_obj->ptr()->length_))
VARIABLE_VISITOR(ContextScope, raw_obj->ptr()->num_variables_)
NULL_VISITOR(Mint)
NULL_VISITOR(Double)
NULL_VISITOR(Float32x4)
NULL_VISITOR(Int32x4)
NULL_VISITOR(Float64x2)
NULL_VISITOR(Bool)
NULL_VISITOR(Capability)
NULL_VISITOR(SendPort)
NULL_VISITOR(TransferableTypedData)
REGULAR_VISITOR(Pointer)
NULL_VISITOR(DynamicLibrary)
VARIABLE_NULL_VISITOR(Instructions, Instructions::Size(raw_obj))
VARIABLE_NULL_VISITOR(PcDescriptors, raw_obj->ptr()->length_)
VARIABLE_NULL_VISITOR(CodeSourceMap, raw_obj->ptr()->length_)
VARIABLE_NULL_VISITOR(StackMap, raw_obj->ptr()->length_)
VARIABLE_NULL_VISITOR(OneByteString, Smi::Value(raw_obj->ptr()->length_))
VARIABLE_NULL_VISITOR(TwoByteString, Smi::Value(raw_obj->ptr()->length_))
// Abstract types don't have their visitor called.
UNREACHABLE_VISITOR(AbstractType)
UNREACHABLE_VISITOR(TypedDataBase)
UNREACHABLE_VISITOR(Error)
UNREACHABLE_VISITOR(Number)
UNREACHABLE_VISITOR(Integer)
UNREACHABLE_VISITOR(String)
// Smi has no heap representation.
UNREACHABLE_VISITOR(Smi)

bool RawCode::ContainsPC(RawObject* raw_obj, uword pc) {
  if (raw_obj->IsCode()) {
    RawCode* raw_code = static_cast<RawCode*>(raw_obj);
    return RawInstructions::ContainsPC(raw_code->ptr()->instructions_, pc);
  }
  return false;
}

intptr_t RawCode::VisitCodePointers(RawCode* raw_obj,
                                    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());

  RawCode* obj = raw_obj->ptr();
  intptr_t length = Code::PtrOffBits::decode(obj->state_bits_);
#if defined(TARGET_ARCH_IA32)
  // On IA32 only we embed pointers to objects directly in the generated
  // instructions. The variable portion of a Code object describes where to
  // find those pointers for tracing.
  if (Code::AliveBit::decode(obj->state_bits_)) {
    uword entry_point = reinterpret_cast<uword>(obj->instructions_->ptr()) +
                        Instructions::HeaderSize();
    for (intptr_t i = 0; i < length; i++) {
      int32_t offset = obj->data()[i];
      visitor->VisitPointer(
          reinterpret_cast<RawObject**>(entry_point + offset));
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

bool RawBytecode::ContainsPC(RawObject* raw_obj, uword pc) {
  if (raw_obj->IsBytecode()) {
    RawBytecode* raw_bytecode = static_cast<RawBytecode*>(raw_obj);
    uword start = raw_bytecode->ptr()->instructions_;
    uword size = raw_bytecode->ptr()->instructions_size_;
    return (pc - start) <= size;  // pc may point past last instruction.
  }
  return false;
}

intptr_t RawObjectPool::VisitObjectPoolPointers(RawObjectPool* raw_obj,
                                                ObjectPointerVisitor* visitor) {
  const intptr_t length = raw_obj->ptr()->length_;
  RawObjectPool::Entry* entries = raw_obj->ptr()->data();
  uint8_t* entry_bits = raw_obj->ptr()->entry_bits();
  for (intptr_t i = 0; i < length; ++i) {
    ObjectPool::EntryType entry_type =
        ObjectPool::TypeBits::decode(entry_bits[i]);
    if ((entry_type == ObjectPool::EntryType::kTaggedObject) ||
        (entry_type == ObjectPool::EntryType::kNativeEntryData)) {
      visitor->VisitPointer(&entries[i].raw_obj_);
    }
  }
  return ObjectPool::InstanceSize(length);
}

bool RawInstructions::ContainsPC(RawInstructions* raw_instr, uword pc) {
  uword start_pc =
      reinterpret_cast<uword>(raw_instr->ptr()) + Instructions::HeaderSize();
  uword end_pc = start_pc + Instructions::Size(raw_instr);
  ASSERT(end_pc > start_pc);
  return (pc >= start_pc) && (pc < end_pc);
}

intptr_t RawInstance::VisitInstancePointers(RawInstance* raw_obj,
                                            ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  uint32_t tags = raw_obj->ptr()->tags_;
  intptr_t instance_size = SizeTag::decode(tags);
  if (instance_size == 0) {
    instance_size =
        visitor->isolate()->GetClassSizeForHeapWalkAt(raw_obj->GetClassId());
  }

  // Calculate the first and last raw object pointer fields.
  uword obj_addr = RawObject::ToAddr(raw_obj);
  uword from = obj_addr + sizeof(RawObject);
  uword to = obj_addr + instance_size - kWordSize;
  visitor->VisitPointers(reinterpret_cast<RawObject**>(from),
                         reinterpret_cast<RawObject**>(to));
  return instance_size;
}

intptr_t RawImmutableArray::VisitImmutableArrayPointers(
    RawImmutableArray* raw_obj,
    ObjectPointerVisitor* visitor) {
  return RawArray::VisitArrayPointers(raw_obj, visitor);
}

void RawObject::RememberCard(RawObject* const* slot) {
  HeapPage::Of(this)->RememberCard(slot);
}

DEFINE_LEAF_RUNTIME_ENTRY(void,
                          RememberCard,
                          2,
                          RawObject* object,
                          RawObject** slot) {
  ASSERT(object->IsOldObject());
  ASSERT(object->IsCardRemembered());
  HeapPage::Of(object)->RememberCard(slot);
}
END_LEAF_RUNTIME_ENTRY

}  // namespace dart
