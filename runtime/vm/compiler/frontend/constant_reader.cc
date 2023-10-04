// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/constant_reader.h"

#include "vm/object_store.h"

namespace dart {
namespace kernel {

#define Z (zone_)
#define H (translation_helper_)

// Note: If changing how the constants are saved in the binary (and thus how
// they are read here) be aware that there's also some reading going on in
// KernelLoader::ReadVMAnnotations which then also has to be updated!

ConstantReader::ConstantReader(KernelReaderHelper* helper,
                               ActiveClass* active_class)
    : helper_(helper),
      zone_(helper->zone_),
      translation_helper_(helper->translation_helper_),
      active_class_(active_class),
      result_(Object::Handle(zone_)) {}

bool ConstantReader::IsPragmaInstanceConstant(
    intptr_t constant_index,
    intptr_t* pragma_name_constant_index,
    intptr_t* pragma_options_constant_index) {
  KernelReaderHelper reader(Z, &H, H.constants_table(), 0);
  NavigateToIndex(&reader, constant_index);

  if (reader.ReadByte() == kInstanceConstant) {
    NameIndex index = reader.ReadCanonicalNameReference();
    if (H.IsRoot(index) ||
        !H.StringEquals(H.CanonicalNameString(index), "pragma")) {
      return false;
    }
    index = H.CanonicalNameParent(index);
    if (H.IsRoot(index) ||
        !H.StringEquals(H.CanonicalNameString(index), "dart:core")) {
      return false;
    }
    const intptr_t num_type_args = reader.ReadUInt();
    if (num_type_args != 0) return false;

    const intptr_t num_fields = reader.ReadUInt();
    if (num_fields != 2) return false;

    const NameIndex field0_name = reader.ReadCanonicalNameReference();
    if (H.IsRoot(field0_name) ||
        !H.StringEquals(H.CanonicalNameString(field0_name), "name")) {
      return false;
    }
    const intptr_t name_index = reader.ReadUInt();
    if (pragma_name_constant_index != nullptr) {
      *pragma_name_constant_index = name_index;
    }

    const NameIndex field1_name = reader.ReadCanonicalNameReference();
    if (H.IsRoot(field1_name) ||
        !H.StringEquals(H.CanonicalNameString(field1_name), "options")) {
      return false;
    }
    const intptr_t options_index = reader.ReadUInt();
    if (pragma_options_constant_index != nullptr) {
      *pragma_options_constant_index = options_index;
    }
    return true;
  }
  return false;
}

bool ConstantReader::IsStringConstant(intptr_t constant_index,
                                      const char* name) {
  KernelReaderHelper reader(Z, &H, H.constants_table(), 0);
  NavigateToIndex(&reader, constant_index);

  if (reader.ReadByte() == kStringConstant) {
    const StringIndex index = reader.ReadStringReference();
    return H.StringEquals(index, name);
  }
  return false;
}

bool ConstantReader::GetStringConstant(intptr_t constant_index,
                                       String* out_value) {
  KernelReaderHelper reader(Z, &H, H.constants_table(), 0);
  NavigateToIndex(&reader, constant_index);

  if (reader.ReadByte() == kStringConstant) {
    const StringIndex index = reader.ReadStringReference();
    *out_value = H.DartSymbolPlain(index).ptr();
    return true;
  }
  return false;
}

InstancePtr ConstantReader::ReadConstantInitializer() {
  Tag tag = helper_->ReadTag();  // read tag.
  switch (tag) {
    case kSomething:
      return ReadConstantExpression();
    default:
      const auto& script = Script::Handle(Z, Script());
      H.ReportError(script, TokenPosition::kNoSource,
                    "Not a constant expression: unexpected kernel tag %s (%d)",
                    Reader::TagName(tag), tag);
  }
  return Instance::RawCast(result_.ptr());
}

InstancePtr ConstantReader::ReadConstantExpression() {
  Tag tag = helper_->ReadTag();  // read tag.
  switch (tag) {
    case kConstantExpression:
      helper_->ReadPosition();
      helper_->SkipDartType();
      result_ = ReadConstant(helper_->ReadUInt());
      break;
    case kFileUriConstantExpression:
      helper_->ReadPosition();
      helper_->ReadUInt();
      helper_->SkipDartType();
      result_ = ReadConstant(helper_->ReadUInt());
      break;
    case kInvalidExpression: {
      helper_->ReadPosition();  // Skip position.
      const String& message = H.DartString(helper_->ReadStringReference());
      const auto& script = Script::Handle(Z, Script());
      // Invalid expression message has pointer to the source code, no need to
      // report it twice.
      H.ReportError(script, TokenPosition::kNoSource, "%s",
                    message.ToCString());
      break;
    }
    default:
      const auto& script = Script::Handle(Z, Script());
      H.ReportError(script, TokenPosition::kNoSource,
                    "Not a constant expression: unexpected kernel tag %s (%d)",
                    Reader::TagName(tag), tag);
  }
  return Instance::RawCast(result_.ptr());
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

InstancePtr ConstantReader::ReadConstant(intptr_t constant_index) {
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
    const auto& constants_array =
        Array::Handle(Z, H.GetKernelProgramInfo().constants());
    ASSERT(constant_index < constants_array.Length());
    result_ = constants_array.At(constant_index);
  }

  // On miss, evaluate, and insert value.
  if (result_.ptr() == Object::sentinel().ptr()) {
    LeaveCompilerScope cs(H.thread());
    result_ = ReadConstantInternal(constant_index);
    SafepointMutexLocker ml(
        H.thread()->isolate_group()->kernel_constants_mutex());
    const auto& constants_array =
        Array::Handle(Z, H.GetKernelProgramInfo().constants());
    ASSERT(constant_index < constants_array.Length());
    constants_array.SetAt(constant_index, result_);
  }
  return Instance::RawCast(result_.ptr());
}

bool ConstantReader::IsInstanceConstant(intptr_t constant_index,
                                        const Class& clazz) {
  // Get reader directly into raw bytes of constant table/constant mapping.
  KernelReaderHelper reader(Z, &H, H.constants_table(), 0);
  NavigateToIndex(&reader, constant_index);

  // Peek for an instance of the given clazz.
  if (reader.ReadByte() == kInstanceConstant) {
    const NameIndex index = reader.ReadCanonicalNameReference();
    return H.LookupClassByKernelClass(index) == clazz.ptr();
  }
  return false;
}

intptr_t ConstantReader::NumConstants() {
  ASSERT(!H.constants_table().IsNull());
  KernelReaderHelper reader(Z, &H, H.constants_table(), 0);
  return NumConstants(&reader);
}

intptr_t ConstantReader::NumConstants(KernelReaderHelper* reader) {
  // Get reader directly into raw bytes of constant table/constant mapping.
  // Get the length of the constants (at the end of the mapping).
  reader->SetOffset(reader->ReaderSize() - 4);
  return reader->ReadUInt32();
}

intptr_t ConstantReader::NavigateToIndex(KernelReaderHelper* reader,
                                         intptr_t constant_index) {
  const intptr_t num_constants = NumConstants(reader);

  // Get the binary offset of the constant at the wanted index.
  reader->SetOffset(reader->ReaderSize() - 4 - (num_constants * 4) +
                    (constant_index * 4));
  const intptr_t constant_offset = reader->ReadUInt32();

  reader->SetOffset(constant_offset);

  return constant_offset;
}

InstancePtr ConstantReader::ReadConstantInternal(intptr_t constant_index) {
  // Get reader directly into raw bytes of constant table/constant mapping.
  bool null_safety = H.thread()->isolate_group()->null_safety();
  KernelReaderHelper reader(Z, &H, H.constants_table(), 0);
  const intptr_t constant_offset = NavigateToIndex(&reader, constant_index);

  // No function types returned as part of any types built should reference
  // free parent type args, ensured by clearing the enclosing function type.
  ActiveEnclosingFunctionScope scope(active_class_, nullptr);
  // Construct constant from raw bytes.
  Instance& instance = Instance::Handle(Z);
  const intptr_t constant_tag = reader.ReadByte();
  switch (constant_tag) {
    case kNullConstant:
      instance = Instance::null();
      break;
    case kBoolConstant:
      instance = reader.ReadByte() == 1 ? Object::bool_true().ptr()
                                        : Object::bool_false().ptr();
      break;
    case kIntConstant: {
      uint8_t payload = 0;
      Tag integer_tag = reader.ReadTag(&payload);  // read tag.
      switch (integer_tag) {
        case kBigIntLiteral: {
          reader.ReadPosition();
          const String& value = H.DartString(reader.ReadStringReference());
          instance = Integer::New(value, Heap::kOld);
          break;
        }
        case kSpecializedIntLiteral: {
          reader.ReadPosition();
          const int64_t value =
              static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
          instance = Integer::New(value, Heap::kOld);
          break;
        }
        case kNegativeIntLiteral: {
          reader.ReadPosition();
          const int64_t value = -static_cast<int64_t>(reader.ReadUInt());
          instance = Integer::New(value, Heap::kOld);
          break;
        }
        case kPositiveIntLiteral: {
          reader.ReadPosition();
          const int64_t value = reader.ReadUInt();
          instance = Integer::New(value, Heap::kOld);
          break;
        }
        default:
          const auto& script = Script::Handle(Z, Script());
          H.ReportError(
              script, TokenPosition::kNoSource,
              "Cannot lazily read integer: unexpected kernel tag %s (%d)",
              Reader::TagName(integer_tag), integer_tag);
      }
      break;
    }
    case kDoubleConstant:
      instance = Double::New(reader.ReadDouble(), Heap::kOld);
      break;
    case kStringConstant:
      instance = H.DartSymbolPlain(reader.ReadStringReference()).ptr();
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
      const auto& list_class = Class::Handle(
          Z, H.isolate_group()->object_store()->immutable_array_class());
      ASSERT(!list_class.IsNull());
      ASSERT(list_class.is_finalized());
      // Build type from the raw bytes (needs temporary translator).
      TypeTranslator type_translator(
          &reader, this, active_class_, /* finalize = */ true,
          active_class_->RequireConstCanonicalTypeErasure(null_safety),
          /* in_constant_context = */ true);
      auto& type_arguments =
          TypeArguments::Handle(Z, TypeArguments::New(1, Heap::kOld));
      AbstractType& type = type_translator.BuildType();
      type_arguments.SetTypeAt(0, type);
      // Instantiate class.
      type_arguments =
          list_class.GetInstanceTypeArguments(H.thread(), type_arguments);
      // Fill array with constant elements.
      const intptr_t length = reader.ReadUInt();
      const Array& array =
          Array::Handle(Z, ImmutableArray::New(length, Heap::kOld));
      array.SetTypeArguments(type_arguments);
      Instance& constant = Instance::Handle(Z);
      for (intptr_t j = 0; j < length; ++j) {
        // Recurse into lazily evaluating all "sub" constants
        // needed to evaluate the current constant.
        const intptr_t entry_index = reader.ReadUInt();
        ASSERT(entry_index < constant_offset);  // DAG!
        constant = ReadConstant(entry_index);
        array.SetAt(j, constant);
      }
      instance = array.ptr();
      break;
    }
    case kMapConstant: {
      const auto& map_class = Class::Handle(
          Z, H.isolate_group()->object_store()->const_map_impl_class());
      ASSERT(!map_class.IsNull());
      ASSERT(map_class.is_finalized());

      // Build types from the raw bytes (needs temporary translator).
      TypeTranslator type_translator(
          &reader, this, active_class_, /* finalize = */ true,
          active_class_->RequireConstCanonicalTypeErasure(null_safety),
          /* in_constant_context = */ true);
      auto& type_arguments =
          TypeArguments::Handle(Z, TypeArguments::New(2, Heap::kOld));
      AbstractType& type = type_translator.BuildType();
      type_arguments.SetTypeAt(0, type);
      type = type_translator.BuildType().ptr();
      type_arguments.SetTypeAt(1, type);

      // Instantiate class.
      type_arguments =
          map_class.GetInstanceTypeArguments(H.thread(), type_arguments);

      // Fill map with constant elements.
      const auto& map = Map::Handle(Z, ConstMap::NewUninitialized(Heap::kOld));
      ASSERT_EQUAL(map.GetClassId(), kConstMapCid);
      map.SetTypeArguments(type_arguments);
      const intptr_t length = reader.ReadUInt();
      const intptr_t used_data = (length << 1);
      map.set_used_data(used_data);

      const auto& data = Array::Handle(Z, Array::New(used_data));
      map.set_data(data);

      map.set_deleted_keys(0);
      map.ComputeAndSetHashMask();

      Instance& constant = Instance::Handle(Z);
      for (intptr_t j = 0; j < used_data; ++j) {
        // Recurse into lazily evaluating all "sub" constants
        // needed to evaluate the current constant.
        const intptr_t entry_index = reader.ReadUInt();
        ASSERT(entry_index < constant_offset);  // DAG!
        constant = ReadConstant(entry_index);
        data.SetAt(j, constant);
      }

      instance = map.ptr();
      break;
    }
    case kRecordConstant: {
      const intptr_t num_positional = reader.ReadListLength();
      intptr_t num_named = 0;
      const Array* field_names = &Array::empty_array();
      {
        AlternativeReadingScope alt(&reader.reader_);
        for (intptr_t j = 0; j < num_positional; ++j) {
          reader.ReadUInt();
        }
        num_named = reader.ReadListLength();
        if (num_named > 0) {
          auto& names = Array::Handle(Z, Array::New(num_named));
          for (intptr_t j = 0; j < num_named; ++j) {
            String& name = H.DartSymbolObfuscate(reader.ReadStringReference());
            names.SetAt(j, name);
            reader.ReadUInt();
          }
          names.MakeImmutable();
          field_names = &names;
        }
      }
      const intptr_t num_fields = num_positional + num_named;
      const RecordShape shape =
          RecordShape::Register(H.thread(), num_fields, *field_names);
      const auto& record = Record::Handle(Z, Record::New(shape));
      intptr_t pos = 0;
      for (intptr_t j = 0; j < num_positional; ++j) {
        const intptr_t entry_index = reader.ReadUInt();
        ASSERT(entry_index < constant_offset);  // DAG!
        instance = ReadConstant(entry_index);
        record.SetFieldAt(pos++, instance);
      }
      reader.ReadListLength();
      for (intptr_t j = 0; j < num_named; ++j) {
        reader.ReadStringReference();
        const intptr_t entry_index = reader.ReadUInt();
        ASSERT(entry_index < constant_offset);  // DAG!
        instance = ReadConstant(entry_index);
        record.SetFieldAt(pos++, instance);
      }
      instance = record.ptr();
      break;
    }
    case kSetConstant: {
      const auto& set_class = Class::Handle(
          Z, H.isolate_group()->object_store()->const_set_impl_class());
      ASSERT(!set_class.IsNull());
      ASSERT(set_class.is_finalized());

      // Build types from the raw bytes (needs temporary translator).
      TypeTranslator type_translator(
          &reader, this, active_class_, /* finalize = */ true,
          active_class_->RequireConstCanonicalTypeErasure(null_safety),
          /* in_constant_context = */ true);
      auto& type_arguments =
          TypeArguments::Handle(Z, TypeArguments::New(1, Heap::kOld));
      AbstractType& type = type_translator.BuildType();
      type_arguments.SetTypeAt(0, type);

      // Instantiate class.
      type_arguments =
          set_class.GetInstanceTypeArguments(H.thread(), type_arguments);

      // Fill set with constant elements.
      const auto& set = Set::Handle(Z, ConstSet::NewUninitialized(Heap::kOld));
      ASSERT_EQUAL(set.GetClassId(), kConstSetCid);
      set.SetTypeArguments(type_arguments);
      const intptr_t length = reader.ReadUInt();
      const intptr_t used_data = length;
      set.set_used_data(used_data);

      const auto& data = Array::Handle(Z, Array::New(used_data));
      set.set_data(data);

      set.set_deleted_keys(0);
      set.ComputeAndSetHashMask();

      Instance& constant = Instance::Handle(Z);
      for (intptr_t j = 0; j < used_data; ++j) {
        // Recurse into lazily evaluating all "sub" constants
        // needed to evaluate the current constant.
        const intptr_t entry_index = reader.ReadUInt();
        ASSERT(entry_index < constant_offset);  // DAG!
        constant = ReadConstant(entry_index);
        data.SetAt(j, constant);
      }

      instance = set.ptr();
      break;
    }
    case kInstanceConstant: {
      const NameIndex index = reader.ReadCanonicalNameReference();
      const auto& klass = Class::Handle(Z, H.LookupClassByKernelClass(index));
      if (!klass.is_declaration_loaded()) {
        FATAL(
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
          &reader, this, active_class_, /* finalize = */ true,
          active_class_->RequireConstCanonicalTypeErasure(null_safety),
          /* in_constant_context = */ true);
      const intptr_t number_of_type_arguments = reader.ReadUInt();
      if (klass.NumTypeArguments() > 0) {
        auto& type_arguments = TypeArguments::Handle(
            Z, TypeArguments::New(number_of_type_arguments, Heap::kOld));
        for (intptr_t j = 0; j < number_of_type_arguments; ++j) {
          type_arguments.SetTypeAt(j, type_translator.BuildType());
        }
        // Instantiate class.
        type_arguments =
            klass.GetInstanceTypeArguments(H.thread(), type_arguments);
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
        const intptr_t entry_index = reader.ReadUInt();
        ASSERT(entry_index < constant_offset);  // DAG!
        constant = ReadConstant(entry_index);
        instance.SetField(field, constant);
      }
      break;
    }
    case kInstantiationConstant: {
      // Recurse into lazily evaluating the "sub" constant
      // needed to evaluate the current constant.
      const intptr_t entry_index = reader.ReadUInt();
      ASSERT(entry_index < constant_offset);  // DAG!
      const auto& constant = Instance::Handle(Z, ReadConstant(entry_index));
      ASSERT(!constant.IsNull());

      // Build type from the raw bytes (needs temporary translator).
      TypeTranslator type_translator(
          &reader, this, active_class_, /* finalize = */ true,
          active_class_->RequireConstCanonicalTypeErasure(null_safety),
          /* in_constant_context = */ true);
      const intptr_t number_of_type_arguments = reader.ReadUInt();
      ASSERT(number_of_type_arguments > 0);
      auto& type_arguments = TypeArguments::Handle(
          Z, TypeArguments::New(number_of_type_arguments, Heap::kOld));
      for (intptr_t j = 0; j < number_of_type_arguments; ++j) {
        type_arguments.SetTypeAt(j, type_translator.BuildType());
      }
      type_arguments = type_arguments.Canonicalize(Thread::Current());
      // Make a copy of the old closure, and set delayed type arguments.
      Closure& closure = Closure::Handle(Z, Closure::RawCast(constant.ptr()));
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
    case kStaticTearOffConstant:
    case kConstructorTearOffConstant:
    case kRedirectingFactoryTearOffConstant: {
      const NameIndex index = reader.ReadCanonicalNameReference();
      Function& function = Function::Handle(Z);
      if (H.IsConstructor(index)) {
        function = H.LookupConstructorByKernelConstructor(index);
      } else {
        function = H.LookupStaticMethodByKernelProcedure(index);
      }
      function = function.ImplicitClosureFunction();
      instance = function.ImplicitStaticClosure();
      break;
    }
    case kTypeLiteralConstant: {
      // Build type from the raw bytes (needs temporary translator).
      // Const canonical type erasure is not applied to constant type literals.
      // However, CFE must ensure that constant type literals can be
      // canonicalized to an identical representant independently of the null
      // safety mode currently in use (sound or unsound) or migration state of
      // the declaring library (legacy or opted-in).
      TypeTranslator type_translator(&reader, this, active_class_,
                                     /* finalize = */ true,
                                     /* apply_canonical_type_erasure = */ false,
                                     /* in_constant_context = */ true);
      instance = type_translator.BuildType().ptr();
      break;
    }
    default:
      // We should never see unevaluated constants (kUnevaluatedConstant) in
      // the constant table, they should have been fully evaluated before we
      // get them.
      const auto& script = Script::Handle(Z, Script());
      H.ReportError(script, TokenPosition::kNoSource,
                    "Cannot lazily read constant: unexpected kernel tag (%" Pd
                    ")",
                    constant_tag);
  }
  return H.Canonicalize(instance);
}

}  // namespace kernel
}  // namespace dart
