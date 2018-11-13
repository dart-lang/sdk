// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel.h"

#include "vm/compiler/frontend/constant_evaluator.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"  // For Parser::kParameter* constants.

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

bool FieldHasFunctionLiteralInitializer(const Field& field,
                                        TokenPosition* start,
                                        TokenPosition* end) {
  Zone* zone = Thread::Current()->zone();
  const Script& script = Script::Handle(zone, field.Script());

  TranslationHelper translation_helper(Thread::Current());
  translation_helper.InitFromScript(script);

  KernelReaderHelper kernel_reader_helper(
      zone, &translation_helper, Script::Handle(zone, field.Script()),
      ExternalTypedData::Handle(zone, field.KernelData()),
      field.KernelDataProgramOffset());
  kernel_reader_helper.SetOffset(field.kernel_offset());
  kernel::FieldHelper field_helper(&kernel_reader_helper);
  field_helper.ReadUntilExcluding(kernel::FieldHelper::kEnd, true);
  return field_helper.FieldHasFunctionLiteralInitializer(start, end);
}

KernelLineStartsReader::KernelLineStartsReader(
    const dart::TypedData& line_starts_data,
    dart::Zone* zone)
    : line_starts_data_(line_starts_data) {
  TypedDataElementType type = line_starts_data_.ElementType();
  if (type == kInt8ArrayElement) {
    helper_ = new KernelInt8LineStartsHelper();
  } else if (type == kInt16ArrayElement) {
    helper_ = new KernelInt16LineStartsHelper();
  } else if (type == kInt32ArrayElement) {
    helper_ = new KernelInt32LineStartsHelper();
  } else {
    UNREACHABLE();
  }
}

intptr_t KernelLineStartsReader::LineNumberForPosition(
    intptr_t position) const {
  intptr_t line_count = line_starts_data_.Length();
  intptr_t current_start = 0;
  for (intptr_t i = 0; i < line_count; ++i) {
    current_start += helper_->At(line_starts_data_, i);
    if (current_start > position) {
      // If current_start is greater than the desired position, it means that
      // it is for the line after |position|. However, since line numbers
      // start at 1, we just return |i|.
      return i;
    }

    if (current_start == position) {
      return i + 1;
    }
  }
  return line_count;
}

void KernelLineStartsReader::LocationForPosition(intptr_t position,
                                                 intptr_t* line,
                                                 intptr_t* col) const {
  intptr_t line_count = line_starts_data_.Length();
  intptr_t current_start = 0;
  intptr_t previous_start = 0;
  for (intptr_t i = 0; i < line_count; ++i) {
    current_start += helper_->At(line_starts_data_, i);
    if (current_start > position) {
      *line = i;
      if (col != NULL) {
        *col = position - previous_start + 1;
      }
      return;
    }
    if (current_start == position) {
      *line = i + 1;
      if (col != NULL) {
        *col = 1;
      }
      return;
    }
    previous_start = current_start;
  }

  // If the start of any of the lines did not cross |position|,
  // then it means the position falls on the last line.
  *line = line_count;
  if (col != NULL) {
    *col = position - current_start + 1;
  }
}

void KernelLineStartsReader::TokenRangeAtLine(
    intptr_t source_length,
    intptr_t line_number,
    TokenPosition* first_token_index,
    TokenPosition* last_token_index) const {
  ASSERT(line_number <= line_starts_data_.Length());
  intptr_t cumulative = 0;
  for (intptr_t i = 0; i < line_number; ++i) {
    cumulative += helper_->At(line_starts_data_, i);
  }
  *first_token_index = dart::TokenPosition(cumulative);
  if (line_number == line_starts_data_.Length()) {
    *last_token_index = dart::TokenPosition(source_length);
  } else {
    *last_token_index = dart::TokenPosition(
        cumulative + helper_->At(line_starts_data_, line_number) - 1);
  }
}

int32_t KernelLineStartsReader::KernelInt8LineStartsHelper::At(
    const dart::TypedData& data,
    intptr_t index) const {
  return data.GetInt8(index);
}

int32_t KernelLineStartsReader::KernelInt16LineStartsHelper::At(
    const dart::TypedData& data,
    intptr_t index) const {
  return data.GetInt16(index << 1);
}

int32_t KernelLineStartsReader::KernelInt32LineStartsHelper::At(
    const dart::TypedData& data,
    intptr_t index) const {
  return data.GetInt32(index << 2);
}

class KernelTokenPositionCollector : public KernelReaderHelper {
 public:
  KernelTokenPositionCollector(
      Zone* zone,
      TranslationHelper* translation_helper,
      const Script& script,
      const ExternalTypedData& data,
      intptr_t data_program_offset,
      intptr_t initial_script_index,
      intptr_t record_for_script_id,
      GrowableArray<intptr_t>* record_token_positions_into,
      GrowableArray<intptr_t>* record_yield_positions_into)
      : KernelReaderHelper(zone,
                           translation_helper,
                           script,
                           data,
                           data_program_offset),
        current_script_id_(initial_script_index),
        record_for_script_id_(record_for_script_id),
        record_token_positions_into_(record_token_positions_into),
        record_yield_positions_into_(record_yield_positions_into) {}

  void CollectTokenPositions(intptr_t kernel_offset);

  void RecordTokenPosition(TokenPosition position) override;
  void RecordYieldPosition(TokenPosition position) override;

  void set_current_script_id(intptr_t id) override { current_script_id_ = id; }

 private:
  intptr_t current_script_id_;
  intptr_t record_for_script_id_;
  GrowableArray<intptr_t>* record_token_positions_into_;
  GrowableArray<intptr_t>* record_yield_positions_into_;

  DISALLOW_COPY_AND_ASSIGN(KernelTokenPositionCollector);
};

void KernelTokenPositionCollector::CollectTokenPositions(
    intptr_t kernel_offset) {
  SetOffset(kernel_offset);

  const Tag tag = PeekTag();
  if (tag == kProcedure) {
    ProcedureHelper procedure_helper(this);
    procedure_helper.ReadUntilExcluding(ProcedureHelper::kEnd);
  } else if (tag == kConstructor) {
    ConstructorHelper constructor_helper(this);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kEnd);
  } else if (tag == kFunctionNode) {
    FunctionNodeHelper function_node_helper(this);
    function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);
  } else if (tag == kField) {
    FieldHelper field_helper(this);
    field_helper.ReadUntilExcluding(FieldHelper::kEnd);
  } else if (tag == kClass) {
    ClassHelper class_helper(this);
    class_helper.ReadUntilExcluding(ClassHelper::kEnd);
  } else {
    ReportUnexpectedTag("a class or a member", tag);
    UNREACHABLE();
  }
}

void KernelTokenPositionCollector::RecordTokenPosition(TokenPosition position) {
  if (record_for_script_id_ == current_script_id_ &&
      record_token_positions_into_ != NULL && position.IsReal()) {
    record_token_positions_into_->Add(position.value());
  }
}

void KernelTokenPositionCollector::RecordYieldPosition(TokenPosition position) {
  if (record_for_script_id_ == current_script_id_ &&
      record_yield_positions_into_ != NULL && position.IsReal()) {
    record_yield_positions_into_->Add(position.value());
  }
}

static int LowestFirst(const intptr_t* a, const intptr_t* b) {
  return *a - *b;
}

/**
 * If index exists as sublist in list, sort the sublist from lowest to highest,
 * then copy it, as Smis and without duplicates,
 * to a new Array in Heap::kOld which is returned.
 * Note that the source list is both sorted and de-duplicated as well, but will
 * possibly contain duplicate and unsorted data at the end.
 * Otherwise (when sublist doesn't exist in list) return new empty array.
 */
static RawArray* AsSortedDuplicateFreeArray(GrowableArray<intptr_t>* source) {
  intptr_t size = source->length();
  if (size == 0) {
    return Object::empty_array().raw();
  }

  source->Sort(LowestFirst);

  intptr_t last = 0;
  for (intptr_t current = 1; current < size; ++current) {
    if (source->At(last) != source->At(current)) {
      (*source)[++last] = source->At(current);
    }
  }
  Array& array_object = Array::Handle();
  array_object = Array::New(last + 1, Heap::kOld);
  Smi& smi_value = Smi::Handle();
  for (intptr_t i = 0; i <= last; ++i) {
    smi_value = Smi::New(source->At(i));
    array_object.SetAt(i, smi_value);
  }
  return array_object.raw();
}

static void ProcessTokenPositionsEntry(
    const ExternalTypedData& kernel_data,
    const Script& script,
    const Script& entry_script,
    intptr_t kernel_offset,
    intptr_t data_kernel_offset,
    Zone* zone,
    TranslationHelper* helper,
    GrowableArray<intptr_t>* token_positions,
    GrowableArray<intptr_t>* yield_positions) {
  if (kernel_data.IsNull()) {
    return;
  }

  KernelTokenPositionCollector token_position_collector(
      zone, helper, script, kernel_data, data_kernel_offset,
      entry_script.kernel_script_index(), script.kernel_script_index(),
      token_positions, yield_positions);

  token_position_collector.CollectTokenPositions(kernel_offset);
}

void CollectTokenPositionsFor(const Script& interesting_script) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  TranslationHelper helper(thread);
  helper.InitFromScript(interesting_script);

  GrowableArray<intptr_t> token_positions(10);
  GrowableArray<intptr_t> yield_positions(1);

  Isolate* isolate = thread->isolate();
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(zone, isolate->object_store()->libraries());
  Library& lib = Library::Handle(zone);
  Object& entry = Object::Handle(zone);
  Script& entry_script = Script::Handle(zone);
  ExternalTypedData& data = ExternalTypedData::Handle(zone);

  auto& temp_array = Array::Handle(zone);
  auto& temp_field = Field::Handle(zone);
  auto& temp_function = Function::Handle(zone);
  for (intptr_t i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    DictionaryIterator it(lib);
    while (it.HasNext()) {
      entry = it.GetNext();
      data = ExternalTypedData::null();
      if (entry.IsClass()) {
        const Class& klass = Class::Cast(entry);
        if (klass.script() == interesting_script.raw()) {
          token_positions.Add(klass.token_pos().value());
        }
        if (klass.is_finalized()) {
          temp_array = klass.fields();
          for (intptr_t i = 0; i < temp_array.Length(); ++i) {
            temp_field ^= temp_array.At(i);
            if (temp_field.kernel_offset() <= 0) {
              // Skip artificially injected fields.
              continue;
            }
            entry_script = temp_field.Script();
            if (entry_script.raw() != interesting_script.raw()) {
              continue;
            }
            data = temp_field.KernelData();
            ProcessTokenPositionsEntry(data, interesting_script, entry_script,
                                       temp_field.kernel_offset(),
                                       temp_field.KernelDataProgramOffset(),
                                       zone, &helper, &token_positions,
                                       &yield_positions);
          }
          temp_array = klass.functions();
          for (intptr_t i = 0; i < temp_array.Length(); ++i) {
            temp_function ^= temp_array.At(i);
            entry_script = temp_function.script();
            if (entry_script.raw() != interesting_script.raw()) {
              continue;
            }
            data = temp_function.KernelData();
            ProcessTokenPositionsEntry(data, interesting_script, entry_script,
                                       temp_function.kernel_offset(),
                                       temp_function.KernelDataProgramOffset(),
                                       zone, &helper, &token_positions,
                                       &yield_positions);
          }
        } else {
          // Class isn't finalized yet: read the data attached to it.
          ASSERT(klass.kernel_offset() > 0);
          data = lib.kernel_data();
          ASSERT(!data.IsNull());
          const intptr_t library_kernel_offset = lib.kernel_offset();
          ASSERT(library_kernel_offset > 0);
          const intptr_t class_offset = klass.kernel_offset();

          entry_script = klass.script();
          if (entry_script.raw() != interesting_script.raw()) {
            continue;
          }
          ProcessTokenPositionsEntry(data, interesting_script, entry_script,
                                     class_offset, library_kernel_offset, zone,
                                     &helper, &token_positions,
                                     &yield_positions);
        }
      } else if (entry.IsFunction()) {
        temp_function ^= entry.raw();
        entry_script = temp_function.script();
        if (entry_script.raw() != interesting_script.raw()) {
          continue;
        }
        data = temp_function.KernelData();
        ProcessTokenPositionsEntry(data, interesting_script, entry_script,
                                   temp_function.kernel_offset(),
                                   temp_function.KernelDataProgramOffset(),
                                   zone, &helper, &token_positions,
                                   &yield_positions);
      } else if (entry.IsField()) {
        const Field& field = Field::Cast(entry);
        if (field.kernel_offset() <= 0) {
          // Skip artificially injected fields.
          continue;
        }
        entry_script = field.Script();
        if (entry_script.raw() != interesting_script.raw()) {
          continue;
        }
        data = field.KernelData();
        ProcessTokenPositionsEntry(data, interesting_script, entry_script,
                                   field.kernel_offset(),
                                   field.KernelDataProgramOffset(), zone,
                                   &helper, &token_positions, &yield_positions);
      }
    }
  }

  Script& script = Script::Handle(zone, interesting_script.raw());
  Array& array_object = Array::Handle(zone);
  array_object = AsSortedDuplicateFreeArray(&token_positions);
  script.set_debug_positions(array_object);
  array_object = AsSortedDuplicateFreeArray(&yield_positions);
  script.set_yield_positions(array_object);
}

class MetadataEvaluator : public KernelReaderHelper {
 public:
  MetadataEvaluator(Zone* zone,
                    TranslationHelper* translation_helper,
                    const Script& script,
                    const ExternalTypedData& data,
                    intptr_t data_program_offset,
                    ActiveClass* active_class)
      : KernelReaderHelper(zone,
                           translation_helper,
                           script,
                           data,
                           data_program_offset),
        type_translator_(this, active_class, /* finalize= */ true),
        constant_evaluator_(this, &type_translator_, active_class, nullptr) {}

  RawObject* EvaluateMetadata(intptr_t kernel_offset,
                              bool is_annotations_offset) {
    SetOffset(kernel_offset);

    // Library and LibraryDependency objects do not have a tag in kernel binary.
    // Synthetic metadata fields corresponding to these objects keep kernel
    // offset of annotations list instead of annotated object.
    if (!is_annotations_offset) {
      const Tag tag = PeekTag();

      if (tag == kClass) {
        ClassHelper class_helper(this);
        class_helper.ReadUntilExcluding(ClassHelper::kAnnotations);
      } else if (tag == kProcedure) {
        ProcedureHelper procedure_helper(this);
        procedure_helper.ReadUntilExcluding(ProcedureHelper::kAnnotations);
      } else if (tag == kField) {
        FieldHelper field_helper(this);
        field_helper.ReadUntilExcluding(FieldHelper::kAnnotations);
      } else if (tag == kConstructor) {
        ConstructorHelper constructor_helper(this);
        constructor_helper.ReadUntilExcluding(ConstructorHelper::kAnnotations);
      } else {
        FATAL("No support for metadata on this type of kernel node\n");
      }
    }

    return constant_evaluator_.EvaluateAnnotations();
  }

 private:
  TypeTranslator type_translator_;
  ConstantEvaluator constant_evaluator_;

  DISALLOW_COPY_AND_ASSIGN(MetadataEvaluator);
};

RawObject* EvaluateMetadata(const Field& metadata_field,
                            bool is_annotations_offset) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();
    TranslationHelper helper(thread);
    Script& script = Script::Handle(zone, metadata_field.Script());
    helper.InitFromScript(script);

    const Class& owner_class = Class::Handle(zone, metadata_field.Owner());
    ActiveClass active_class;
    ActiveClassScope active_class_scope(&active_class, &owner_class);

    MetadataEvaluator metadata_evaluator(
        zone, &helper, script,
        ExternalTypedData::Handle(zone, metadata_field.KernelData()),
        metadata_field.KernelDataProgramOffset(), &active_class);

    return metadata_evaluator.EvaluateMetadata(metadata_field.kernel_offset(),
                                               is_annotations_offset);

  } else {
    Thread* thread = Thread::Current();
    Error& error = Error::Handle();
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error.raw();
  }
}

class ParameterDescriptorBuilder : public KernelReaderHelper {
 public:
  ParameterDescriptorBuilder(TranslationHelper* translation_helper,
                             const Script& script,
                             Zone* zone,
                             const ExternalTypedData& data,
                             intptr_t data_program_offset,
                             ActiveClass* active_class)
      : KernelReaderHelper(zone,
                           translation_helper,
                           script,
                           data,
                           data_program_offset),
        type_translator_(this, active_class, /* finalize= */ true),
        constant_evaluator_(this, &type_translator_, active_class, nullptr) {}

  RawObject* BuildParameterDescriptor(intptr_t kernel_offset);

 private:
  TypeTranslator type_translator_;
  ConstantEvaluator constant_evaluator_;

  DISALLOW_COPY_AND_ASSIGN(ParameterDescriptorBuilder);
};

RawObject* ParameterDescriptorBuilder::BuildParameterDescriptor(
    intptr_t kernel_offset) {
  SetOffset(kernel_offset);
  ReadUntilFunctionNode();
  FunctionNodeHelper function_node_helper(this);
  function_node_helper.ReadUntilExcluding(
      FunctionNodeHelper::kPositionalParameters);
  intptr_t param_count = function_node_helper.total_parameter_count_;
  intptr_t positional_count = ReadListLength();  // read list length.
  intptr_t named_parameter_count = param_count - positional_count;

  const Array& param_descriptor = Array::Handle(
      Array::New(param_count * Parser::kParameterEntrySize, Heap::kOld));
  for (intptr_t i = 0; i < param_count; ++i) {
    const intptr_t entry_start = i * Parser::kParameterEntrySize;

    if (i == positional_count) {
      intptr_t named_parameter_count_check =
          ReadListLength();  // read list length.
      ASSERT(named_parameter_count_check == named_parameter_count);
    }

    // Read ith variable declaration.
    intptr_t param_kernel_offset = reader_.offset();
    VariableDeclarationHelper helper(this);
    helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);
    param_descriptor.SetAt(entry_start + Parser::kParameterIsFinalOffset,
                           helper.IsFinal() ? Bool::True() : Bool::False());

    Tag tag = ReadTag();  // read (first part of) initializer.
    if (tag == kSomething) {
      // this will (potentially) read the initializer, but reset the position.
      Instance& constant = Instance::ZoneHandle(
          zone_, constant_evaluator_.EvaluateExpression(ReaderOffset()));
      SkipExpression();  // read (actual) initializer.
      param_descriptor.SetAt(entry_start + Parser::kParameterDefaultValueOffset,
                             constant);
    } else {
      param_descriptor.SetAt(entry_start + Parser::kParameterDefaultValueOffset,
                             Object::null_instance());
    }

    if (FLAG_enable_mirrors && (helper.annotation_count_ > 0)) {
      AlternativeReadingScope alt(&reader_, param_kernel_offset);
      VariableDeclarationHelper helper(this);
      helper.ReadUntilExcluding(VariableDeclarationHelper::kAnnotations);
      Object& metadata =
          Object::ZoneHandle(zone_, constant_evaluator_.EvaluateAnnotations());
      param_descriptor.SetAt(entry_start + Parser::kParameterMetadataOffset,
                             metadata);
    } else {
      param_descriptor.SetAt(entry_start + Parser::kParameterMetadataOffset,
                             Object::null_instance());
    }
  }
  return param_descriptor.raw();
}

RawObject* BuildParameterDescriptor(const Function& function) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();
    TranslationHelper helper(thread);
    Script& script = Script::Handle(zone, function.script());
    helper.InitFromScript(script);

    const Class& owner_class = Class::Handle(zone, function.Owner());
    ActiveClass active_class;
    ActiveClassScope active_class_scope(&active_class, &owner_class);

    ParameterDescriptorBuilder builder(
        &helper, Script::Handle(zone, function.script()), zone,
        ExternalTypedData::Handle(zone, function.KernelData()),
        function.KernelDataProgramOffset(), &active_class);

    return builder.BuildParameterDescriptor(function.kernel_offset());
  } else {
    Thread* thread = Thread::Current();
    Error& error = Error::Handle();
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error.raw();
  }
}

bool NeedsDynamicInvocationForwarder(const Function& function) {
  ASSERT(FLAG_strong);

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  TranslationHelper helper(thread);
  Script& script = Script::Handle(zone, function.script());
  helper.InitFromScript(script);

  // Setup a [ActiveClassScope] and a [ActiveMemberScope] which will be used
  // e.g. for type translation.

  const Class& owner_class = Class::Handle(zone, function.Owner());
  Function& outermost_function =
      Function::Handle(zone, function.GetOutermostFunction());

  ActiveClass active_class;
  ActiveClassScope active_class_scope(&active_class, &owner_class);
  ActiveMemberScope active_member(&active_class, &outermost_function);
  ActiveTypeParametersScope active_type_params(&active_class, function, zone);

  KernelReaderHelper reader_helper(
      zone, &helper, script,
      ExternalTypedData::Handle(zone, function.KernelData()),
      function.KernelDataProgramOffset());

  TypeTranslator type_translator(&reader_helper, &active_class,
                                 /* finalize= */ true);

  reader_helper.SetOffset(function.kernel_offset());

  // Handle setters.
  if (reader_helper.PeekTag() == kField) {
    ASSERT(function.IsImplicitSetterFunction());
    FieldHelper field_helper(&reader_helper);
    field_helper.ReadUntilIncluding(FieldHelper::kFlags);
    return !(field_helper.IsCovariant() ||
             field_helper.IsGenericCovariantImpl());
  }

  reader_helper.ReadUntilFunctionNode();

  FunctionNodeHelper function_node_helper(&reader_helper);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);
  intptr_t num_type_params = reader_helper.ReadListLength();

  for (intptr_t i = 0; i < num_type_params; ++i) {
    TypeParameterHelper helper(&reader_helper);
    helper.ReadUntilExcludingAndSetJustRead(TypeParameterHelper::kBound);
    AbstractType& bound = type_translator.BuildType();  // read bound
    helper.Finish();

    if (!bound.IsTopType() && !helper.IsGenericCovariantImpl()) {
      return true;
    }
  }
  function_node_helper.SetJustRead(FunctionNodeHelper::kTypeParameters);
  function_node_helper.ReadUntilExcluding(
      FunctionNodeHelper::kPositionalParameters);

  // Positional.
  const intptr_t num_positional_params = reader_helper.ReadListLength();
  for (intptr_t i = 0; i < num_positional_params; ++i) {
    VariableDeclarationHelper helper(&reader_helper);
    helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
    AbstractType& type = type_translator.BuildType();  // read type.
    helper.SetJustRead(VariableDeclarationHelper::kType);
    helper.ReadUntilExcluding(VariableDeclarationHelper::kEnd);

    if (!type.IsTopType() && !helper.IsGenericCovariantImpl() &&
        !helper.IsCovariant()) {
      return true;
    }
  }

  // Named.
  const intptr_t num_named_params = reader_helper.ReadListLength();
  for (intptr_t i = 0; i < num_named_params; ++i) {
    VariableDeclarationHelper helper(&reader_helper);
    helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
    AbstractType& type = type_translator.BuildType();  // read type.
    helper.SetJustRead(VariableDeclarationHelper::kType);
    helper.ReadUntilExcluding(VariableDeclarationHelper::kEnd);

    if (!type.IsTopType() && !helper.IsGenericCovariantImpl() &&
        !helper.IsCovariant()) {
      return true;
    }
  }

  return false;
}

bool IsFieldInitializer(const Function& function, Zone* zone) {
  return (function.kind() == RawFunction::kImplicitStaticFinalGetter) &&
         String::Handle(zone, function.name())
             .StartsWith(Symbols::InitPrefix());
}

static ProcedureAttributesMetadata ProcedureAttributesOf(
    Zone* zone,
    const Script& script,
    const ExternalTypedData& kernel_data,
    intptr_t kernel_data_program_offset,
    intptr_t kernel_offset) {
  TranslationHelper translation_helper(Thread::Current());
  translation_helper.InitFromScript(script);
  KernelReaderHelper reader_helper(zone, &translation_helper, script,
                                   kernel_data, kernel_data_program_offset);
  ProcedureAttributesMetadataHelper procedure_attributes_metadata_helper(
      &reader_helper);
  ProcedureAttributesMetadata attrs =
      procedure_attributes_metadata_helper.GetProcedureAttributes(
          kernel_offset);
  return attrs;
}

ProcedureAttributesMetadata ProcedureAttributesOf(const Function& function,
                                                  Zone* zone) {
  const Script& script = Script::Handle(zone, function.script());
  return ProcedureAttributesOf(
      zone, script, ExternalTypedData::Handle(zone, function.KernelData()),
      function.KernelDataProgramOffset(), function.kernel_offset());
}

ProcedureAttributesMetadata ProcedureAttributesOf(const Field& field,
                                                  Zone* zone) {
  const Class& parent = Class::Handle(zone, field.Owner());
  const Script& script = Script::Handle(zone, parent.script());
  return ProcedureAttributesOf(
      zone, script, ExternalTypedData::Handle(zone, field.KernelData()),
      field.KernelDataProgramOffset(), field.kernel_offset());
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
