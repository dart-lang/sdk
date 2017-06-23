// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/raw_object.h"

#include "vm/become.h"
#include "vm/class_table.h"
#include "vm/dart.h"
#include "vm/freelist.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/visitor.h"


namespace dart {

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
  intptr_t reserved = ReservedBits::decode(tags);
  if (reserved != 0) {
    FATAL1("Invalid tags field encountered %x\n", tags);
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
  intptr_t size = SizeTag::decode(tags);
  if (size != 0 && size != SizeFromClass()) {
    FATAL1("Inconsistent class size encountered %" Pd "\n", size);
  }
}


intptr_t RawObject::SizeFromClass() const {
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
      instance_size = element->Size();
      break;
    }
    case kForwardingCorpse: {
      uword addr = RawObject::ToAddr(this);
      ForwardingCorpse* element = reinterpret_cast<ForwardingCorpse*>(addr);
      instance_size = element->Size();
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
      RawClass* raw_class = isolate->GetClassForHeapWalkAt(class_id);
      instance_size = raw_class->ptr()->instance_size_in_words_
                      << kWordSizeLog2;
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
      RawExternalTypedData* raw_obj =
          reinterpret_cast<RawExternalTypedData*>(this);
      size = RawExternalTypedData::VisitExternalTypedDataPointers(raw_obj,
                                                                  visitor);
      break;
    }
#undef RAW_VISITPOINTERS
#define RAW_VISITPOINTERS(clazz) case kTypedData##clazz##ViewCid:
    CLASS_LIST_TYPED_DATA(RAW_VISITPOINTERS)
    case kByteDataViewCid:
    case kByteBufferCid: {
      RawInstance* raw_obj = reinterpret_cast<RawInstance*>(this);
      size = RawInstance::VisitInstancePointers(raw_obj, visitor);
      break;
    }
#undef RAW_VISITPOINTERS
    case kFreeListElement: {
      uword addr = RawObject::ToAddr(this);
      FreeListElement* element = reinterpret_cast<FreeListElement*>(addr);
      size = element->Size();
      break;
    }
    case kForwardingCorpse: {
      uword addr = RawObject::ToAddr(this);
      ForwardingCorpse* forwarder = reinterpret_cast<ForwardingCorpse*>(addr);
      size = forwarder->Size();
      break;
    }
    case kNullCid:
      size = Size();
      break;
    default:
      OS::Print("Class Id: %" Pd "\n", class_id);
      UNREACHABLE();
      break;
  }

  ASSERT(size != 0);
  ASSERT(size == Size());
  return size;
}


bool RawObject::FindObject(FindObjectVisitor* visitor) {
  ASSERT(visitor != NULL);
  return visitor->FindObject(this);
}


intptr_t RawClass::VisitClassPointers(RawClass* raw_obj,
                                      ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Class::InstanceSize();
}


intptr_t RawUnresolvedClass::VisitUnresolvedClassPointers(
    RawUnresolvedClass* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return UnresolvedClass::InstanceSize();
}


intptr_t RawAbstractType::VisitAbstractTypePointers(
    RawAbstractType* raw_obj,
    ObjectPointerVisitor* visitor) {
  // RawAbstractType is an abstract class.
  UNREACHABLE();
  return 0;
}


intptr_t RawType::VisitTypePointers(RawType* raw_obj,
                                    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Type::InstanceSize();
}


intptr_t RawTypeRef::VisitTypeRefPointers(RawTypeRef* raw_obj,
                                          ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return TypeRef::InstanceSize();
}


intptr_t RawTypeParameter::VisitTypeParameterPointers(
    RawTypeParameter* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return TypeParameter::InstanceSize();
}


intptr_t RawBoundedType::VisitBoundedTypePointers(
    RawBoundedType* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return BoundedType::InstanceSize();
}


intptr_t RawMixinAppType::VisitMixinAppTypePointers(
    RawMixinAppType* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return MixinAppType::InstanceSize();
}


intptr_t RawTypeArguments::VisitTypeArgumentsPointers(
    RawTypeArguments* raw_obj,
    ObjectPointerVisitor* visitor) {
  intptr_t length = Smi::Value(raw_obj->ptr()->length_);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to(length));
  return TypeArguments::InstanceSize(length);
}


intptr_t RawPatchClass::VisitPatchClassPointers(RawPatchClass* raw_obj,
                                                ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return PatchClass::InstanceSize();
}


intptr_t RawClosure::VisitClosurePointers(RawClosure* raw_obj,
                                          ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Closure::InstanceSize();
}


intptr_t RawClosureData::VisitClosureDataPointers(
    RawClosureData* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ClosureData::InstanceSize();
}


intptr_t RawSignatureData::VisitSignatureDataPointers(
    RawSignatureData* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return SignatureData::InstanceSize();
}


intptr_t RawRedirectionData::VisitRedirectionDataPointers(
    RawRedirectionData* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return RedirectionData::InstanceSize();
}


bool RawFunction::CheckUsageCounter(RawFunction* raw_fun) {
  // NOTE: This code runs while GC is in progress and runs within
  // a NoHandleScope block. Hence it is not okay to use regular Zone or
  // Scope handles. We use direct stack handles, and so the raw pointers in
  // these handles are not traversed. The use of handles is mainly to
  // be able to reuse the handle based code and avoid having to add
  // helper functions to the raw object interface.
  Function fn;
  fn = raw_fun;

  // The function may not have code.
  if (!fn.HasCode()) return false;
  // These may not increment the usage counter.
  if (fn.is_intrinsic()) return false;

  if (fn.usage_counter() >= 0) {
    fn.set_usage_counter(fn.usage_counter() / 2);
  }
  return FLAG_always_drop_code || (fn.usage_counter() == 0);
}


bool RawFunction::ShouldVisitCode(RawCode* raw_code) {
  // NOTE: This code runs while GC is in progress and runs within
  // a NoHandleScope block. Hence it is not okay to use regular Zone or
  // Scope handles. We use direct stack handles, and so the raw pointers in
  // these handles are not traversed. The use of handles is mainly to
  // be able to reuse the handle based code and avoid having to add
  // helper functions to the raw object interface.
  Code code;
  code = raw_code;
  if (code.IsNull()) return true;
  if (code.is_optimized()) return true;
  if (code.HasBreakpoint()) return true;
  return false;
}


intptr_t RawFunction::VisitFunctionPointers(RawFunction* raw_obj,
                                            ObjectPointerVisitor* visitor) {
  if (visitor->visit_function_code() || !CheckUsageCounter(raw_obj)) {
    visitor->VisitPointers(raw_obj->from(), raw_obj->to());
    return Function::InstanceSize();
  }
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  visitor->VisitPointers(raw_obj->from(), raw_obj->to_no_code());

  if (ShouldVisitCode(raw_obj->ptr()->code_)) {
    visitor->VisitPointer(
        reinterpret_cast<RawObject**>(&raw_obj->ptr()->code_));
  } else {
    visitor->add_skipped_code_function(raw_obj);
  }

  if (ShouldVisitCode(raw_obj->ptr()->unoptimized_code_)) {
    visitor->VisitPointer(
        reinterpret_cast<RawObject**>(&raw_obj->ptr()->unoptimized_code_));
  } else {
    visitor->add_skipped_code_function(raw_obj);
  }
#endif
  return Function::InstanceSize();
}


intptr_t RawField::VisitFieldPointers(RawField* raw_obj,
                                      ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Field::InstanceSize();
}


intptr_t RawLiteralToken::VisitLiteralTokenPointers(
    RawLiteralToken* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return LiteralToken::InstanceSize();
}


intptr_t RawTokenStream::VisitTokenStreamPointers(
    RawTokenStream* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return TokenStream::InstanceSize();
}


intptr_t RawScript::VisitScriptPointers(RawScript* raw_obj,
                                        ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Script::InstanceSize();
}


intptr_t RawLibrary::VisitLibraryPointers(RawLibrary* raw_obj,
                                          ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Library::InstanceSize();
}


intptr_t RawLibraryPrefix::VisitLibraryPrefixPointers(
    RawLibraryPrefix* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return LibraryPrefix::InstanceSize();
}


intptr_t RawNamespace::VisitNamespacePointers(RawNamespace* raw_obj,
                                              ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Namespace::InstanceSize();
}


bool RawCode::ContainsPC(RawObject* raw_obj, uword pc) {
  uint32_t tags = raw_obj->ptr()->tags_;
  if (RawObject::ClassIdTag::decode(tags) == kCodeCid) {
    RawCode* raw_code = reinterpret_cast<RawCode*>(raw_obj);
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


intptr_t RawObjectPool::VisitObjectPoolPointers(RawObjectPool* raw_obj,
                                                ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(
      reinterpret_cast<RawObject**>(&raw_obj->ptr()->info_array_));
  const intptr_t len = raw_obj->ptr()->length_;
  RawTypedData* info_array = raw_obj->ptr()->info_array_->ptr();
  Entry* first = raw_obj->first_entry();
  for (intptr_t i = 0; i < len; ++i) {
    ObjectPool::EntryType entry_type =
        static_cast<ObjectPool::EntryType>(info_array->data()[i]);
    if (entry_type == ObjectPool::kTaggedObject) {
      visitor->VisitPointer(&(first + i)->raw_obj_);
    }
  }
  return ObjectPool::InstanceSize(raw_obj->ptr()->length_);
}


intptr_t RawInstructions::VisitInstructionsPointers(
    RawInstructions* raw_obj,
    ObjectPointerVisitor* visitor) {
  return Instructions::InstanceSize(Instructions::Size(raw_obj));
}


bool RawInstructions::ContainsPC(RawInstructions* raw_instr, uword pc) {
  uword start_pc =
      reinterpret_cast<uword>(raw_instr->ptr()) + Instructions::HeaderSize();
  uword end_pc = start_pc + Instructions::Size(raw_instr);
  ASSERT(end_pc > start_pc);
  return (pc >= start_pc) && (pc < end_pc);
}


intptr_t RawPcDescriptors::VisitPcDescriptorsPointers(
    RawPcDescriptors* raw_obj,
    ObjectPointerVisitor* visitor) {
  return PcDescriptors::InstanceSize(raw_obj->ptr()->length_);
}


intptr_t RawCodeSourceMap::VisitCodeSourceMapPointers(
    RawCodeSourceMap* raw_obj,
    ObjectPointerVisitor* visitor) {
  return CodeSourceMap::InstanceSize(raw_obj->ptr()->length_);
}


intptr_t RawStackMap::VisitStackMapPointers(RawStackMap* raw_obj,
                                            ObjectPointerVisitor* visitor) {
  return StackMap::InstanceSize(raw_obj->ptr()->length_);
}


intptr_t RawLocalVarDescriptors::VisitLocalVarDescriptorsPointers(
    RawLocalVarDescriptors* raw_obj,
    ObjectPointerVisitor* visitor) {
  intptr_t num_entries = raw_obj->ptr()->num_entries_;
  visitor->VisitPointers(raw_obj->from(), raw_obj->to(num_entries));
  return LocalVarDescriptors::InstanceSize(num_entries);
}


intptr_t RawExceptionHandlers::VisitExceptionHandlersPointers(
    RawExceptionHandlers* raw_obj,
    ObjectPointerVisitor* visitor) {
  RawExceptionHandlers* obj = raw_obj->ptr();
  intptr_t len = obj->num_entries_;
  visitor->VisitPointer(
      reinterpret_cast<RawObject**>(&obj->handled_types_data_));
  return ExceptionHandlers::InstanceSize(len);
}


intptr_t RawContext::VisitContextPointers(RawContext* raw_obj,
                                          ObjectPointerVisitor* visitor) {
  intptr_t num_variables = raw_obj->ptr()->num_variables_;
  visitor->VisitPointers(raw_obj->from(), raw_obj->to(num_variables));
  return Context::InstanceSize(num_variables);
}


intptr_t RawContextScope::VisitContextScopePointers(
    RawContextScope* raw_obj,
    ObjectPointerVisitor* visitor) {
  intptr_t num_variables = raw_obj->ptr()->num_variables_;
  visitor->VisitPointers(raw_obj->from(), raw_obj->to(num_variables));
  return ContextScope::InstanceSize(num_variables);
}


intptr_t RawSingleTargetCache::VisitSingleTargetCachePointers(
    RawSingleTargetCache* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return SingleTargetCache::InstanceSize();
}


intptr_t RawUnlinkedCall::VisitUnlinkedCallPointers(
    RawUnlinkedCall* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return UnlinkedCall::InstanceSize();
}


intptr_t RawICData::VisitICDataPointers(RawICData* raw_obj,
                                        ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ICData::InstanceSize();
}


intptr_t RawMegamorphicCache::VisitMegamorphicCachePointers(
    RawMegamorphicCache* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return MegamorphicCache::InstanceSize();
}


intptr_t RawSubtypeTestCache::VisitSubtypeTestCachePointers(
    RawSubtypeTestCache* raw_obj,
    ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  RawSubtypeTestCache* obj = raw_obj->ptr();
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&obj->cache_));
  return SubtypeTestCache::InstanceSize();
}


intptr_t RawError::VisitErrorPointers(RawError* raw_obj,
                                      ObjectPointerVisitor* visitor) {
  // Error is an abstract class.
  UNREACHABLE();
  return 0;
}


intptr_t RawApiError::VisitApiErrorPointers(RawApiError* raw_obj,
                                            ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ApiError::InstanceSize();
}


intptr_t RawLanguageError::VisitLanguageErrorPointers(
    RawLanguageError* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return LanguageError::InstanceSize();
}


intptr_t RawUnhandledException::VisitUnhandledExceptionPointers(
    RawUnhandledException* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return UnhandledException::InstanceSize();
}


intptr_t RawUnwindError::VisitUnwindErrorPointers(
    RawUnwindError* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return UnwindError::InstanceSize();
}


intptr_t RawInstance::VisitInstancePointers(RawInstance* raw_obj,
                                            ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  uint32_t tags = raw_obj->ptr()->tags_;
  intptr_t instance_size = SizeTag::decode(tags);
  if (instance_size == 0) {
    RawClass* cls =
        visitor->isolate()->GetClassForHeapWalkAt(raw_obj->GetClassId());
    instance_size = cls->ptr()->instance_size_in_words_ << kWordSizeLog2;
  }

  // Calculate the first and last raw object pointer fields.
  uword obj_addr = RawObject::ToAddr(raw_obj);
  uword from = obj_addr + sizeof(RawObject);
  uword to = obj_addr + instance_size - kWordSize;
  visitor->VisitPointers(reinterpret_cast<RawObject**>(from),
                         reinterpret_cast<RawObject**>(to));
  return instance_size;
}


intptr_t RawNumber::VisitNumberPointers(RawNumber* raw_obj,
                                        ObjectPointerVisitor* visitor) {
  // Number is an abstract class.
  UNREACHABLE();
  return 0;
}


intptr_t RawInteger::VisitIntegerPointers(RawInteger* raw_obj,
                                          ObjectPointerVisitor* visitor) {
  // Integer is an abstract class.
  UNREACHABLE();
  return 0;
}


intptr_t RawSmi::VisitSmiPointers(RawSmi* raw_obj,
                                  ObjectPointerVisitor* visitor) {
  // Smi does not have a heap representation.
  UNREACHABLE();
  return 0;
}


intptr_t RawMint::VisitMintPointers(RawMint* raw_obj,
                                    ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  return Mint::InstanceSize();
}


intptr_t RawBigint::VisitBigintPointers(RawBigint* raw_obj,
                                        ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Bigint::InstanceSize();
}


intptr_t RawDouble::VisitDoublePointers(RawDouble* raw_obj,
                                        ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  return Double::InstanceSize();
}


intptr_t RawString::VisitStringPointers(RawString* raw_obj,
                                        ObjectPointerVisitor* visitor) {
  // String is an abstract class.
  UNREACHABLE();
  return 0;
}


intptr_t RawOneByteString::VisitOneByteStringPointers(
    RawOneByteString* raw_obj,
    ObjectPointerVisitor* visitor) {
  ASSERT(!raw_obj->ptr()->length_->IsHeapObject());
#if !defined(HASH_IN_OBJECT_HEADER)
  ASSERT(!raw_obj->ptr()->hash_->IsHeapObject());
#endif
  intptr_t length = Smi::Value(raw_obj->ptr()->length_);
  return OneByteString::InstanceSize(length);
}


intptr_t RawTwoByteString::VisitTwoByteStringPointers(
    RawTwoByteString* raw_obj,
    ObjectPointerVisitor* visitor) {
  ASSERT(!raw_obj->ptr()->length_->IsHeapObject());
#if !defined(HASH_IN_OBJECT_HEADER)
  ASSERT(!raw_obj->ptr()->hash_->IsHeapObject());
#endif
  intptr_t length = Smi::Value(raw_obj->ptr()->length_);
  return TwoByteString::InstanceSize(length);
}


intptr_t RawExternalOneByteString::VisitExternalOneByteStringPointers(
    RawExternalOneByteString* raw_obj,
    ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ExternalOneByteString::InstanceSize();
}


intptr_t RawExternalTwoByteString::VisitExternalTwoByteStringPointers(
    RawExternalTwoByteString* raw_obj,
    ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ExternalTwoByteString::InstanceSize();
}


intptr_t RawBool::VisitBoolPointers(RawBool* raw_obj,
                                    ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  return Bool::InstanceSize();
}


intptr_t RawArray::VisitArrayPointers(RawArray* raw_obj,
                                      ObjectPointerVisitor* visitor) {
  intptr_t length = Smi::Value(raw_obj->ptr()->length_);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to(length));
  return Array::InstanceSize(length);
}


intptr_t RawImmutableArray::VisitImmutableArrayPointers(
    RawImmutableArray* raw_obj,
    ObjectPointerVisitor* visitor) {
  return RawArray::VisitArrayPointers(raw_obj, visitor);
}


intptr_t RawGrowableObjectArray::VisitGrowableObjectArrayPointers(
    RawGrowableObjectArray* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return GrowableObjectArray::InstanceSize();
}


intptr_t RawLinkedHashMap::VisitLinkedHashMapPointers(
    RawLinkedHashMap* raw_obj,
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return LinkedHashMap::InstanceSize();
}


intptr_t RawFloat32x4::VisitFloat32x4Pointers(RawFloat32x4* raw_obj,
                                              ObjectPointerVisitor* visitor) {
  ASSERT(raw_obj->IsHeapObject());
  return Float32x4::InstanceSize();
}


intptr_t RawInt32x4::VisitInt32x4Pointers(RawInt32x4* raw_obj,
                                          ObjectPointerVisitor* visitor) {
  ASSERT(raw_obj->IsHeapObject());
  return Int32x4::InstanceSize();
}


intptr_t RawFloat64x2::VisitFloat64x2Pointers(RawFloat64x2* raw_obj,
                                              ObjectPointerVisitor* visitor) {
  ASSERT(raw_obj->IsHeapObject());
  return Float64x2::InstanceSize();
}

intptr_t RawTypedData::VisitTypedDataPointers(RawTypedData* raw_obj,
                                              ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  intptr_t cid = raw_obj->GetClassId();
  intptr_t array_len = Smi::Value(raw_obj->ptr()->length_);
  intptr_t lengthInBytes = array_len * TypedData::ElementSizeInBytes(cid);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return TypedData::InstanceSize(lengthInBytes);
}


intptr_t RawExternalTypedData::VisitExternalTypedDataPointers(
    RawExternalTypedData* raw_obj,
    ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ExternalTypedData::InstanceSize();
}

intptr_t RawCapability::VisitCapabilityPointers(RawCapability* raw_obj,
                                                ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  return Capability::InstanceSize();
}


intptr_t RawReceivePort::VisitReceivePortPointers(
    RawReceivePort* raw_obj,
    ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ReceivePort::InstanceSize();
}


intptr_t RawSendPort::VisitSendPortPointers(RawSendPort* raw_obj,
                                            ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  return SendPort::InstanceSize();
}


intptr_t RawStackTrace::VisitStackTracePointers(RawStackTrace* raw_obj,
                                                ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return StackTrace::InstanceSize();
}


intptr_t RawRegExp::VisitRegExpPointers(RawRegExp* raw_obj,
                                        ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return RegExp::InstanceSize();
}


intptr_t RawWeakProperty::VisitWeakPropertyPointers(
    RawWeakProperty* raw_obj,
    ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return WeakProperty::InstanceSize();
}


intptr_t RawMirrorReference::VisitMirrorReferencePointers(
    RawMirrorReference* raw_obj,
    ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return MirrorReference::InstanceSize();
}


intptr_t RawUserTag::VisitUserTagPointers(RawUserTag* raw_obj,
                                          ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return UserTag::InstanceSize();
}


}  // namespace dart
