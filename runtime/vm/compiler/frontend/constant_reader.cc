// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/constant_reader.h"

namespace dart {
namespace kernel {

#define Z (zone_)
#define H (translation_helper_)

ConstantReader::ConstantReader(KernelReaderHelper* helper,
                               ActiveClass* active_class)
    : helper_(helper),
      zone_(helper->zone_),
      translation_helper_(helper->translation_helper_),
      active_class_(active_class),
      script_(helper->script()),
      result_(Instance::Handle(zone_)) {}

InstancePtr ConstantReader::ReadConstantInitializer() {
  Tag tag = helper_->ReadTag();  // read tag.
  switch (tag) {
    case kSomething:
      return ReadConstantExpression();
    default:
      H.ReportError(script_, TokenPosition::kNoSource,
                    "Not a constant expression: unexpected kernel tag %s (%d)",
                    Reader::TagName(tag), tag);
  }
  return result_.raw();
}

InstancePtr ConstantReader::ReadConstantExpression() {
  Tag tag = helper_->ReadTag();  // read tag.
  switch (tag) {
    case kConstantExpression:
      helper_->ReadPosition();
      helper_->SkipDartType();
      result_ = ReadConstant(helper_->ReadUInt());
      break;
    case kInvalidExpression: {
      helper_->ReadPosition();  // Skip position.
      const String& message = H.DartString(helper_->ReadStringReference());
      // Invalid expression message has pointer to the source code, no need to
      // report it twice.
      H.ReportError(helper_->script(), TokenPosition::kNoSource, "%s",
                    message.ToCString());
      break;
    }
    default:
      H.ReportError(script_, TokenPosition::kNoSource,
                    "Not a constant expression: unexpected kernel tag %s (%d)",
                    Reader::TagName(tag), tag);
  }
  return result_.raw();
}

ObjectPtr ConstantReader::ReadAnnotations() {
  intptr_t list_length = helper_->ReadListLength();  // read list length.
  const auto& metadata_values =
      Array::Handle(Z, ImmutableArray::New(list_length, H.allocation_space()));
  Instance& value = Instance::Handle(Z);
  for (intptr_t i = 0; i < list_length; ++i) {
    // This will read the expression.
    value = ReadConstantExpression();
    metadata_values.SetAt(i, value);
  }
  return H.Canonicalize(metadata_values);
}

InstancePtr ConstantReader::ReadConstant(intptr_t constant_offset) {
  ASSERT(!H.constants().IsNull());
  ASSERT(!H.constants_table().IsNull());  // raw bytes

  // For kernel-level cache (in contrast with script-level caching),
  // we need to access the raw constants array inside the shared
  // KernelProgramInfo directly, so that all scripts will see the
  // results after new insertions. These accesses at kernel-level
  // must be locked since mutator and background compiler can
  // access the array at the same time.
  {
    SafepointMutexLocker ml(
        H.thread()->isolate_group()->kernel_constants_mutex());
    KernelConstantsMap constant_map(H.info().constants());
    result_ ^= constant_map.GetOrNull(constant_offset);
    ASSERT(constant_map.Release().raw() == H.info().constants());
  }

  // On miss, evaluate, and insert value.
  if (result_.IsNull()) {
    LeaveCompilerScope cs(H.thread());
    result_ = ReadConstantInternal(constant_offset);
    SafepointMutexLocker ml(
        H.thread()->isolate_group()->kernel_constants_mutex());
    KernelConstantsMap constant_map(H.info().constants());
    auto insert = constant_map.InsertNewOrGetValue(constant_offset, result_);
    ASSERT(insert == result_.raw());
    H.info().set_constants(constant_map.Release());  // update!
  }
  return result_.raw();
}

bool ConstantReader::IsInstanceConstant(intptr_t constant_offset,
                                        const Class& clazz) {
  // Get reader directly into raw bytes of constant table.
  KernelReaderHelper reader(Z, &H, script_, H.constants_table(), 0);
  reader.ReadUInt();  // skip variable-sized int for adjusted constant offset
  reader.SetOffset(reader.ReaderOffset() + constant_offset);
  // Peek for an instance of the given clazz.
  if (reader.ReadByte() == kInstanceConstant) {
    const NameIndex index = reader.ReadCanonicalNameReference();
    return H.LookupClassByKernelClass(index) == clazz.raw();
  }
  return false;
}

InstancePtr ConstantReader::ReadConstantInternal(intptr_t constant_offset) {
  // Get reader directly into raw bytes of constant table.
  bool null_safety = H.thread()->isolate()->null_safety();
  KernelReaderHelper reader(Z, &H, script_, H.constants_table(), 0);
  reader.ReadUInt();  // skip variable-sized int for adjusted constant offset
  reader.SetOffset(reader.ReaderOffset() + constant_offset);
  // Construct constant from raw bytes.
  Instance& instance = Instance::Handle(Z);
  const intptr_t constant_tag = reader.ReadByte();
  switch (constant_tag) {
    case kNullConstant:
      instance = Instance::null();
      break;
    case kBoolConstant:
      instance = reader.ReadByte() == 1 ? Object::bool_true().raw()
                                        : Object::bool_false().raw();
      break;
    case kIntConstant: {
      uint8_t payload = 0;
      Tag integer_tag = reader.ReadTag(&payload);  // read tag.
      switch (integer_tag) {
        case kBigIntLiteral: {
          const String& value = H.DartString(reader.ReadStringReference());
          instance = Integer::New(value, Heap::kOld);
          break;
        }
        case kSpecializedIntLiteral: {
          const int64_t value =
              static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
          instance = Integer::New(value, Heap::kOld);
          break;
        }
        case kNegativeIntLiteral: {
          const int64_t value = -static_cast<int64_t>(reader.ReadUInt());
          instance = Integer::New(value, Heap::kOld);
          break;
        }
        case kPositiveIntLiteral: {
          const int64_t value = reader.ReadUInt();
          instance = Integer::New(value, Heap::kOld);
          break;
        }
        default:
          H.ReportError(
              script_, TokenPosition::kNoSource,
              "Cannot lazily read integer: unexpected kernel tag %s (%d)",
              Reader::TagName(integer_tag), integer_tag);
      }
      break;
    }
    case kDoubleConstant:
      instance = Double::New(reader.ReadDouble(), Heap::kOld);
      break;
    case kStringConstant:
      instance = H.DartSymbolPlain(reader.ReadStringReference()).raw();
      break;
    case kSymbolConstant: {
      Library& library = Library::Handle(Z);
      library = Library::InternalLibrary();
      const auto& symbol_class =
          Class::Handle(Z, library.LookupClass(Symbols::Symbol()));
      const auto& symbol_name_field = Field::Handle(
          Z, symbol_class.LookupInstanceFieldAllowPrivate(Symbols::_name()));
      ASSERT(!symbol_name_field.IsNull());
      const NameIndex index = reader.ReadCanonicalNameReference();
      if (index == -1) {
        library = Library::null();
      } else {
        library = H.LookupLibraryByKernelLibrary(index);
      }
      const String& symbol =
          H.DartIdentifier(library, reader.ReadStringReference());
      instance = Instance::New(symbol_class, Heap::kOld);
      instance.SetField(symbol_name_field, symbol);
      break;
    }
    case kListConstant: {
      const auto& corelib = Library::Handle(Z, Library::CoreLibrary());
      const auto& list_class =
          Class::Handle(Z, corelib.LookupClassAllowPrivate(Symbols::_List()));
      // Build type from the raw bytes (needs temporary translator).
      TypeTranslator type_translator(
          &reader, this, active_class_, true,
          active_class_->RequireLegacyErasure(null_safety));
      auto& type_arguments =
          TypeArguments::Handle(Z, TypeArguments::New(1, Heap::kOld));
      AbstractType& type = type_translator.BuildType();
      type_arguments.SetTypeAt(0, type);
      // Instantiate class.
      type = Type::New(list_class, type_arguments, TokenPosition::kNoSource);
      type = ClassFinalizer::FinalizeType(type);
      type_arguments = type.arguments();
      // Fill array with constant elements.
      const intptr_t length = reader.ReadUInt();
      const Array& array =
          Array::Handle(Z, ImmutableArray::New(length, Heap::kOld));
      array.SetTypeArguments(type_arguments);
      Instance& constant = Instance::Handle(Z);
      for (intptr_t j = 0; j < length; ++j) {
        // Recurse into lazily evaluating all "sub" constants
        // needed to evaluate the current constant.
        const intptr_t entry_offset = reader.ReadUInt();
        ASSERT(entry_offset < constant_offset);  // DAG!
        constant = ReadConstant(entry_offset);
        array.SetAt(j, constant);
      }
      instance = array.raw();
      break;
    }
    case kInstanceConstant: {
      const NameIndex index = reader.ReadCanonicalNameReference();
      const auto& klass = Class::Handle(Z, H.LookupClassByKernelClass(index));
      if (!klass.is_declaration_loaded()) {
        FATAL1(
            "Trying to evaluate an instance constant whose references class "
            "%s is not loaded yet.",
            klass.ToCString());
      }
      const auto& obj =
          Object::Handle(Z, klass.EnsureIsAllocateFinalized(H.thread()));
      ASSERT(obj.IsNull());
      ASSERT(klass.is_enum_class() || klass.is_const());
      instance = Instance::New(klass, Heap::kOld);
      // Build type from the raw bytes (needs temporary translator).
      TypeTranslator type_translator(
          &reader, this, active_class_, true,
          active_class_->RequireLegacyErasure(null_safety));
      const intptr_t number_of_type_arguments = reader.ReadUInt();
      if (klass.NumTypeArguments() > 0) {
        auto& type_arguments = TypeArguments::Handle(
            Z, TypeArguments::New(number_of_type_arguments, Heap::kOld));
        for (intptr_t j = 0; j < number_of_type_arguments; ++j) {
          type_arguments.SetTypeAt(j, type_translator.BuildType());
        }
        // Instantiate class.
        auto& type = AbstractType::Handle(
            Z, Type::New(klass, type_arguments, TokenPosition::kNoSource));
        type = ClassFinalizer::FinalizeType(type);
        type_arguments = type.arguments();
        instance.SetTypeArguments(type_arguments);
      } else {
        ASSERT(number_of_type_arguments == 0);
      }
      // Set the fields.
      const intptr_t number_of_fields = reader.ReadUInt();
      Field& field = Field::Handle(Z);
      Instance& constant = Instance::Handle(Z);
      for (intptr_t j = 0; j < number_of_fields; ++j) {
        field = H.LookupFieldByKernelField(reader.ReadCanonicalNameReference());
        // Recurse into lazily evaluating all "sub" constants
        // needed to evaluate the current constant.
        const intptr_t entry_offset = reader.ReadUInt();
        ASSERT(entry_offset < constant_offset);  // DAG!
        constant = ReadConstant(entry_offset);
        instance.SetField(field, constant);
      }
      break;
    }
    case kPartialInstantiationConstant: {
      // Recurse into lazily evaluating the "sub" constant
      // needed to evaluate the current constant.
      const intptr_t entry_offset = reader.ReadUInt();
      ASSERT(entry_offset < constant_offset);  // DAG!
      const auto& constant = Instance::Handle(Z, ReadConstant(entry_offset));
      ASSERT(!constant.IsNull());

      // Build type from the raw bytes (needs temporary translator).
      TypeTranslator type_translator(
          &reader, this, active_class_, true,
          active_class_->RequireLegacyErasure(null_safety));
      const intptr_t number_of_type_arguments = reader.ReadUInt();
      ASSERT(number_of_type_arguments > 0);
      auto& type_arguments = TypeArguments::Handle(
          Z, TypeArguments::New(number_of_type_arguments, Heap::kOld));
      for (intptr_t j = 0; j < number_of_type_arguments; ++j) {
        type_arguments.SetTypeAt(j, type_translator.BuildType());
      }
      type_arguments = type_arguments.Canonicalize(Thread::Current(), nullptr);
      // Make a copy of the old closure, and set delayed type arguments.
      Closure& closure = Closure::Handle(Z, Closure::RawCast(constant.raw()));
      Function& function = Function::Handle(Z, closure.function());
      const auto& type_arguments2 =
          TypeArguments::Handle(Z, closure.instantiator_type_arguments());
      // The function type arguments are used for type parameters from enclosing
      // closures. Though inner closures cannot be constants. We should
      // therefore see `null here.
      ASSERT(closure.function_type_arguments() == TypeArguments::null());
      Context& context = Context::Handle(Z, closure.context());
      instance = Closure::New(type_arguments2, Object::null_type_arguments(),
                              type_arguments, function, context, Heap::kOld);
      break;
    }
    case kTearOffConstant: {
      const NameIndex index = reader.ReadCanonicalNameReference();
      Function& function =
          Function::Handle(Z, H.LookupStaticMethodByKernelProcedure(index));
      function = function.ImplicitClosureFunction();
      instance = function.ImplicitStaticClosure();
      break;
    }
    case kTypeLiteralConstant: {
      // Build type from the raw bytes (needs temporary translator).
      // Legacy erasure is not applied to type literals. See issue #42262.
      TypeTranslator type_translator(&reader, this, active_class_, true);
      instance = type_translator.BuildType().raw();
      break;
    }
    default:
      // Set literals (kSetConstant) are currently desugared in the frontend
      // and will not reach the VM. See http://dartbug.com/35124 for some
      // discussion. Map constants (kMapConstant ) are already lowered to
      // InstanceConstant or ListConstant. We should never see unevaluated
      // constants (kUnevaluatedConstant) in the constant table, they should
      // have been fully evaluated before we get them.
      H.ReportError(script_, TokenPosition::kNoSource,
                    "Cannot lazily read constant: unexpected kernel tag (%" Pd
                    ")",
                    constant_tag);
  }
  return H.Canonicalize(instance);
}

}  // namespace kernel
}  // namespace dart
