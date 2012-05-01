// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/raw_object.h"

#include "vm/class_table.h"
#include "vm/freelist.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/visitor.h"


namespace dart {

void RawObject::Validate(Isolate* isolate) const {
  // Validation only happens in DEBUG builds.
#if defined(DEBUG)
  if (Object::null_class_ == reinterpret_cast<RawClass*>(kHeapObjectTag)) {
    // Validation relies on properly initialized class classes. Skip if the
    // VM is still being initialized.
    return;
  }
  // All Smi values are valid.
  if (!IsHeapObject()) {
    return;
  }
  // Validate that the class_ field is sensible.
  RawClass* raw_class = ptr()->class_;
  ASSERT(raw_class->IsHeapObject());
  RawClass* raw_class_class = raw_class->ptr()->class_;
  ASSERT(raw_class_class->IsHeapObject());
  ASSERT(raw_class_class->ptr()->instance_kind_ == kClass);

  // Validate that the tags_ field is sensible.
  uword tags = ptr()->tags_;
  ASSERT((tags & 0x000000f0) == 0);
  intptr_t cid = ClassTag::decode(tags);
  RawClass* tag_class = isolate->class_table()->At(cid);
  ASSERT(tag_class == raw_class);
#endif
}


intptr_t RawObject::SizeFromClass() const {
  NoHandleScope no_handles(Isolate::Current());

  // Only reasonable to be called on heap objects.
  ASSERT(IsHeapObject());

  RawClass* raw_class = ptr()->class_;
  intptr_t instance_size = raw_class->ptr()->instance_size_;
  ObjectKind instance_kind = raw_class->ptr()->instance_kind_;

  if (instance_size == 0) {
    switch (instance_kind) {
      case kTokenStream: {
        const RawTokenStream* raw_tokens =
            reinterpret_cast<const RawTokenStream*>(this);
        intptr_t tokens_length = Smi::Value(raw_tokens->ptr()->length_);
        instance_size = TokenStream::InstanceSize(tokens_length);
        break;
      }
      case kCode: {
        const RawCode* raw_code = reinterpret_cast<const RawCode*>(this);
        intptr_t pointer_offsets_length =
            raw_code->ptr()->pointer_offsets_length_;
        instance_size = Code::InstanceSize(pointer_offsets_length);
        break;
      }
      case kInstructions: {
        const RawInstructions* raw_instructions =
            reinterpret_cast<const RawInstructions*>(this);
        intptr_t instructions_size = raw_instructions->ptr()->size_;
        instance_size = Instructions::InstanceSize(instructions_size);
        break;
      }
      case kContext: {
        const RawContext* raw_context =
            reinterpret_cast<const RawContext*>(this);
        intptr_t num_variables = raw_context->ptr()->num_variables_;
        instance_size = Context::InstanceSize(num_variables);
        break;
      }
      case kContextScope: {
        const RawContextScope* raw_context_scope =
            reinterpret_cast<const RawContextScope*>(this);
        intptr_t num_variables = raw_context_scope->ptr()->num_variables_;
        instance_size = ContextScope::InstanceSize(num_variables);
        break;
      }
      case kBigint: {
        const RawBigint* raw_bgi = reinterpret_cast<const RawBigint*>(this);
        intptr_t length = raw_bgi->ptr()->allocated_length_;
        instance_size = Bigint::InstanceSize(length);
        break;
      }
      case kOneByteString: {
        const RawOneByteString* raw_string =
            reinterpret_cast<const RawOneByteString*>(this);
        intptr_t string_length = Smi::Value(raw_string->ptr()->length_);
        instance_size = OneByteString::InstanceSize(string_length);
        break;
      }
      case kTwoByteString: {
        const RawTwoByteString* raw_string =
            reinterpret_cast<const RawTwoByteString*>(this);
        intptr_t string_length = Smi::Value(raw_string->ptr()->length_);
        instance_size = TwoByteString::InstanceSize(string_length);
        break;
      }
      case kFourByteString: {
        const RawFourByteString* raw_string =
            reinterpret_cast<const RawFourByteString*>(this);
        intptr_t string_length = Smi::Value(raw_string->ptr()->length_);
        instance_size = FourByteString::InstanceSize(string_length);
        break;
      }
      case kArray:
      case kImmutableArray: {
        const RawArray* raw_array = reinterpret_cast<const RawArray*>(this);
        intptr_t array_length = Smi::Value(raw_array->ptr()->length_);
        instance_size = Array::InstanceSize(array_length);
        break;
      }
      case kInternalByteArray: {
        const RawInternalByteArray* raw_byte_array =
            reinterpret_cast<const RawInternalByteArray*>(this);
        intptr_t byte_array_length = Smi::Value(raw_byte_array->ptr()->length_);
        instance_size = InternalByteArray::InstanceSize(byte_array_length);
        break;
      }
      case kTypeArguments: {
        const RawTypeArguments* raw_array =
            reinterpret_cast<const RawTypeArguments*>(this);
        intptr_t array_length = Smi::Value(raw_array->ptr()->length_);
        instance_size = TypeArguments::InstanceSize(array_length);
        break;
      }
      case kPcDescriptors: {
        const RawPcDescriptors* raw_descriptors =
            reinterpret_cast<const RawPcDescriptors*>(this);
        intptr_t num_descriptors = Smi::Value(raw_descriptors->ptr()->length_);
        instance_size = PcDescriptors::InstanceSize(num_descriptors);
        break;
      }
      case kStackmap: {
        const RawStackmap* map = reinterpret_cast<const RawStackmap*>(this);
        intptr_t size_in_bytes = Smi::Value(map->ptr()->bitmap_size_in_bytes_);
        instance_size = Stackmap::InstanceSize(size_in_bytes);
        break;
      }
      case kLocalVarDescriptors: {
        const RawLocalVarDescriptors* raw_descriptors =
            reinterpret_cast<const RawLocalVarDescriptors*>(this);
        intptr_t num_descriptors = raw_descriptors->ptr()->length_;
        instance_size = LocalVarDescriptors::InstanceSize(num_descriptors);
        break;
      }
      case kExceptionHandlers: {
        const RawExceptionHandlers* raw_handlers =
            reinterpret_cast<const RawExceptionHandlers*>(this);
        intptr_t num_handlers = Smi::Value(raw_handlers->ptr()->length_);
        instance_size = ExceptionHandlers::InstanceSize(num_handlers);
        break;
      }
      case kJSRegExp: {
        const RawJSRegExp* raw_jsregexp =
            reinterpret_cast<const RawJSRegExp*>(this);
        intptr_t data_length = Smi::Value(raw_jsregexp->ptr()->data_length_);
        instance_size = JSRegExp::InstanceSize(data_length);
        break;
      }
      case kFreeListElement: {
        ASSERT(FreeBit::decode(ptr()->tags_));
        uword addr = RawObject::ToAddr(const_cast<RawObject*>(this));
        FreeListElement* element = reinterpret_cast<FreeListElement*>(addr);
        instance_size = element->Size();
        break;
      }
      default:
        UNREACHABLE();
        break;
    }
  }
  ASSERT(instance_size != 0);
  uword tags = ptr()->tags_;
  ASSERT((instance_size == SizeTag::decode(tags)) ||
         (SizeTag::decode(tags) == 0) ||
         FreeBit::decode(tags));
  return instance_size;
}


intptr_t RawObject::VisitPointers(ObjectPointerVisitor* visitor) {
  intptr_t size = 0;
  NoHandleScope no_handles(Isolate::Current());

  // Only reasonable to be called on heap objects.
  ASSERT(IsHeapObject());

  // Read the necessary data out of the class before visting the class itself.
  RawClass* raw_class = ptr()->class_;
  ObjectKind kind = raw_class->ptr()->instance_kind_;

  // Visit the class before visting the fields.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&ptr()->class_));

  switch (kind) {
#define RAW_VISITPOINTERS(clazz) \
    case clazz::kInstanceKind: { \
      Raw##clazz* raw_obj = reinterpret_cast<Raw##clazz*>(this); \
      size = Raw##clazz::Visit##clazz##Pointers(raw_obj, visitor); \
      break; \
    }
    CLASS_LIST_NO_OBJECT(RAW_VISITPOINTERS)
#undef RAW_VISITPOINTERS
    case kFreeListElement: {
      ASSERT(FreeBit::decode(ptr()->tags_));
      // Nothing to visit for free list elements.
      uword addr = RawObject::ToAddr(this);
      FreeListElement* element = reinterpret_cast<FreeListElement*>(addr);
      size = element->Size();
      break;
    }
    default:
      OS::Print("Kind: %d\n", kind);
      UNREACHABLE();
      break;
  }

  ASSERT(size != 0);
  ASSERT(size == Size());
  return size;
}


bool RawObject::FindObject(FindObjectVisitor* visitor) {
  ASSERT(visitor != NULL);
  return visitor->FindObject(const_cast<RawObject*>(this));
}


intptr_t RawClass::VisitClassPointers(RawClass* raw_obj,
                                      ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Class::InstanceSize();
}


intptr_t RawUnresolvedClass::VisitUnresolvedClassPointers(
    RawUnresolvedClass* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return UnresolvedClass::InstanceSize();
}


intptr_t RawAbstractType::VisitAbstractTypePointers(
    RawAbstractType* raw_obj, ObjectPointerVisitor* visitor) {
  // RawAbstractType is an abstract class.
  UNREACHABLE();
  return 0;
}


intptr_t RawType::VisitTypePointers(
    RawType* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Type::InstanceSize();
}


intptr_t RawTypeParameter::VisitTypeParameterPointers(
    RawTypeParameter* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&raw_obj->ptr()->name_));
  return TypeParameter::InstanceSize();
}


intptr_t RawInstantiatedType::VisitInstantiatedTypePointers(
    RawInstantiatedType* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return InstantiatedType::InstanceSize();
}


intptr_t RawAbstractTypeArguments::VisitAbstractTypeArgumentsPointers(
    RawAbstractTypeArguments* raw_obj, ObjectPointerVisitor* visitor) {
  // RawAbstractTypeArguments is an abstract class.
  UNREACHABLE();
  return 0;
}


intptr_t RawTypeArguments::VisitTypeArgumentsPointers(
    RawTypeArguments* raw_obj, ObjectPointerVisitor* visitor) {
  intptr_t length = Smi::Value(raw_obj->ptr()->length_);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to(length));
  return TypeArguments::InstanceSize(length);
}


intptr_t RawInstantiatedTypeArguments::VisitInstantiatedTypeArgumentsPointers(
    RawInstantiatedTypeArguments* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return InstantiatedTypeArguments::InstanceSize();
}


intptr_t RawFunction::VisitFunctionPointers(RawFunction* raw_obj,
                                            ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Function::InstanceSize();
}


intptr_t RawField::VisitFieldPointers(RawField* raw_obj,
                                      ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Field::InstanceSize();
}


intptr_t RawLiteralToken::VisitLiteralTokenPointers(
    RawLiteralToken* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return LiteralToken::InstanceSize();
}


intptr_t RawTokenStream::VisitTokenStreamPointers(
    RawTokenStream* raw_obj, ObjectPointerVisitor* visitor) {
  intptr_t length = Smi::Value(raw_obj->ptr()->length_);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to(length));
  return TokenStream::InstanceSize(length);
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
    RawLibraryPrefix* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return LibraryPrefix::InstanceSize();
}


intptr_t RawCode::VisitCodePointers(RawCode* raw_obj,
                                    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());

  // Also visit all the embedded pointers in the corresponding instructions.
  RawCode* obj = raw_obj->ptr();
  intptr_t length = obj->pointer_offsets_length_;
  uword entry_point = reinterpret_cast<uword>(obj->instructions_->ptr()) +
      Instructions::HeaderSize();
  for (intptr_t i = 0; i < length; i++) {
    int32_t offset = obj->data_[i];
    visitor->VisitPointer(reinterpret_cast<RawObject**>(entry_point + offset));
  }
  return Code::InstanceSize(length);
}


intptr_t RawInstructions::VisitInstructionsPointers(
    RawInstructions* raw_obj, ObjectPointerVisitor* visitor) {
  RawInstructions* obj = raw_obj->ptr();
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&obj->code_));
  return Instructions::InstanceSize(obj->size_);
}


bool RawInstructions::ContainsPC(RawObject* raw_obj, uword pc) {
  RawClass* raw_class = raw_obj->ptr()->class_;
  ObjectKind instance_kind = raw_class->ptr()->instance_kind_;
  if (instance_kind == kInstructions) {
    RawInstructions* raw_instr = reinterpret_cast<RawInstructions*>(raw_obj);
    uword start_pc =
        reinterpret_cast<uword>(raw_instr->ptr()) + Instructions::HeaderSize();
    uword end_pc = start_pc + raw_instr->ptr()->size_;
    ASSERT(end_pc > start_pc);
    if ((pc >= start_pc) && (pc < end_pc)) {
      return true;
    }
  }
  return false;
}


intptr_t RawPcDescriptors::VisitPcDescriptorsPointers(
    RawPcDescriptors* raw_obj, ObjectPointerVisitor* visitor) {
  RawPcDescriptors* obj = raw_obj->ptr();
  intptr_t length = Smi::Value(obj->length_);
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&obj->length_));
  return PcDescriptors::InstanceSize(length);
}


intptr_t RawStackmap::VisitStackmapPointers(RawStackmap* raw_obj,
                                            ObjectPointerVisitor* visitor) {
  RawStackmap* obj = raw_obj->ptr();
  intptr_t size_in_bytes = Smi::Value(obj->bitmap_size_in_bytes_);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Stackmap::InstanceSize(size_in_bytes);
}


intptr_t RawLocalVarDescriptors::VisitLocalVarDescriptorsPointers(
    RawLocalVarDescriptors* raw_obj, ObjectPointerVisitor* visitor) {
  RawLocalVarDescriptors* obj = raw_obj->ptr();
  intptr_t len = obj->length_;
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&obj->names_));
  return LocalVarDescriptors::InstanceSize(len);
}


intptr_t RawExceptionHandlers::VisitExceptionHandlersPointers(
    RawExceptionHandlers* raw_obj, ObjectPointerVisitor* visitor) {
  RawExceptionHandlers* obj = raw_obj->ptr();
  intptr_t length = Smi::Value(obj->length_);
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&obj->length_));
  return ExceptionHandlers::InstanceSize(length);
}


intptr_t RawContext::VisitContextPointers(RawContext* raw_obj,
                                          ObjectPointerVisitor* visitor) {
  intptr_t num_variables = raw_obj->ptr()->num_variables_;
  visitor->VisitPointers(raw_obj->from(), raw_obj->to(num_variables));
  return Context::InstanceSize(num_variables);
}


intptr_t RawContextScope::VisitContextScopePointers(
    RawContextScope* raw_obj, ObjectPointerVisitor* visitor) {
  intptr_t num_variables = raw_obj->ptr()->num_variables_;
  visitor->VisitPointers(raw_obj->from(), raw_obj->to(num_variables));
  return ContextScope::InstanceSize(num_variables);
}


intptr_t RawICData::VisitICDataPointers(RawICData* raw_obj,
                                        ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ICData::InstanceSize();
}


intptr_t RawError::VisitErrorPointers(RawError* raw_obj,
                                      ObjectPointerVisitor* visitor) {
  // Error is an abstract class.
  UNREACHABLE();
  return 0;
}


intptr_t RawApiError::VisitApiErrorPointers(
    RawApiError* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ApiError::InstanceSize();
}


intptr_t RawLanguageError::VisitLanguageErrorPointers(
    RawLanguageError* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return LanguageError::InstanceSize();
}


intptr_t RawUnhandledException::VisitUnhandledExceptionPointers(
    RawUnhandledException* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return UnhandledException::InstanceSize();
}


intptr_t RawUnwindError::VisitUnwindErrorPointers(
    RawUnwindError* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return UnwindError::InstanceSize();
}


intptr_t RawInstance::VisitInstancePointers(RawInstance* raw_obj,
                                            ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  RawInstance* obj = raw_obj->ptr();
  intptr_t instance_size = obj->class_->ptr()->instance_size_;
  intptr_t num_native_fields = obj->class_->ptr()->num_native_fields_;

  // Calculate the first and last raw object pointer fields.
  uword obj_addr = RawObject::ToAddr(raw_obj);
  uword from = obj_addr + sizeof(RawObject) + num_native_fields * kWordSize;
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
  RawBigint* obj = raw_obj->ptr();
  intptr_t length = obj->allocated_length_;
  return Bigint::InstanceSize(length);
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
    RawOneByteString* raw_obj, ObjectPointerVisitor* visitor) {
  intptr_t length = Smi::Value(raw_obj->ptr()->length_);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return OneByteString::InstanceSize(length);
}


intptr_t RawTwoByteString::VisitTwoByteStringPointers(
    RawTwoByteString* raw_obj, ObjectPointerVisitor* visitor) {
  intptr_t length = Smi::Value(raw_obj->ptr()->length_);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return TwoByteString::InstanceSize(length);
}


intptr_t RawFourByteString::VisitFourByteStringPointers(
    RawFourByteString* raw_obj, ObjectPointerVisitor* visitor) {
  intptr_t length = Smi::Value(raw_obj->ptr()->length_);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return FourByteString::InstanceSize(length);
}


intptr_t RawExternalOneByteString::VisitExternalOneByteStringPointers(
    RawExternalOneByteString* raw_obj, ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ExternalOneByteString::InstanceSize();
}


intptr_t RawExternalTwoByteString::VisitExternalTwoByteStringPointers(
    RawExternalTwoByteString* raw_obj, ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ExternalTwoByteString::InstanceSize();
}


intptr_t RawExternalFourByteString::VisitExternalFourByteStringPointers(
    RawExternalFourByteString* raw_obj, ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ExternalFourByteString::InstanceSize();
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
    RawImmutableArray* raw_obj, ObjectPointerVisitor* visitor) {
  return RawArray::VisitArrayPointers(raw_obj, visitor);
}


intptr_t RawGrowableObjectArray::VisitGrowableObjectArrayPointers(
    RawGrowableObjectArray* raw_obj, ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return GrowableObjectArray::InstanceSize();
}


intptr_t RawByteArray::VisitByteArrayPointers(RawByteArray* raw_obj,
                                              ObjectPointerVisitor* visitor) {
  // ByteArray is an abstract class.
  UNREACHABLE();
  return 0;
}


intptr_t RawInternalByteArray::VisitInternalByteArrayPointers(
    RawInternalByteArray* raw_obj, ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  intptr_t length = Smi::Value(raw_obj->ptr()->length_);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return InternalByteArray::InstanceSize(length);
}


intptr_t RawExternalByteArray::VisitExternalByteArrayPointers(
    RawExternalByteArray* raw_obj, ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return ExternalByteArray::InstanceSize();
}


intptr_t RawClosure::VisitClosurePointers(RawClosure* raw_obj,
                                          ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Closure::InstanceSize();
}


intptr_t RawStacktrace::VisitStacktracePointers(RawStacktrace* raw_obj,
                                                ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return Stacktrace::InstanceSize();
}


intptr_t RawJSRegExp::VisitJSRegExpPointers(RawJSRegExp* raw_obj,
                                            ObjectPointerVisitor* visitor) {
  // Make sure that we got here with the tagged pointer as this.
  ASSERT(raw_obj->IsHeapObject());
  intptr_t length = Smi::Value(raw_obj->ptr()->data_length_);
  visitor->VisitPointers(raw_obj->from(), raw_obj->to());
  return JSRegExp::InstanceSize(length);
}

}  // namespace dart
