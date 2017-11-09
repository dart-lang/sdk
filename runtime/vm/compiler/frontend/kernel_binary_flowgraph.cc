// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/kernel_binary_flowgraph.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/longjump.h"
#include "vm/object_store.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()

static bool IsStaticInitializer(const Function& function, Zone* zone) {
  return (function.kind() == RawFunction::kImplicitStaticFinalGetter) &&
         String::Handle(zone, function.name())
             .StartsWith(Symbols::InitPrefix());
}

void FunctionNodeHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = builder_->ReadTag();  // read tag.
      ASSERT(tag == kFunctionNode);
      if (++next_read_ == field) return;
    }
    case kPosition:
      position_ = builder_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
    case kEndPosition:
      end_position_ = builder_->ReadPosition();  // read end position.
      if (++next_read_ == field) return;
    case kAsyncMarker:
      async_marker_ = static_cast<AsyncMarker>(builder_->ReadByte());
      if (++next_read_ == field) return;
    case kDartAsyncMarker:
      dart_async_marker_ = static_cast<AsyncMarker>(
          builder_->ReadByte());  // read dart async marker.
      if (++next_read_ == field) return;
    case kTypeParameters:
      builder_->SkipTypeParametersList();  // read type parameters.
      if (++next_read_ == field) return;
    case kTotalParameterCount:
      total_parameter_count_ =
          builder_->ReadUInt();  // read total parameter count.
      if (++next_read_ == field) return;
    case kRequiredParameterCount:
      required_parameter_count_ =
          builder_->ReadUInt();  // read required parameter count.
      if (++next_read_ == field) return;
    case kPositionalParameters:
      builder_->SkipListOfVariableDeclarations();  // read positionals.
      if (++next_read_ == field) return;
    case kNamedParameters:
      builder_->SkipListOfVariableDeclarations();  // read named.
      if (++next_read_ == field) return;
    case kReturnType:
      builder_->SkipDartType();  // read return type.
      if (++next_read_ == field) return;
    case kBody:
      if (builder_->ReadTag() == kSomething)
        builder_->SkipStatement();  // read body.
      if (++next_read_ == field) return;
    case kEnd:
      return;
  }
}

void VariableDeclarationHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kPosition:
      position_ = builder_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
    case kEqualPosition:
      equals_position_ = builder_->ReadPosition();  // read equals position.
      if (++next_read_ == field) return;
    case kAnnotations:
      builder_->SkipListOfExpressions();  // read annotations.
      if (++next_read_ == field) return;
    case kFlags:
      flags_ = builder_->ReadFlags();
      if (++next_read_ == field) return;
    case kNameIndex:
      name_index_ = builder_->ReadStringReference();  // read name index.
      if (++next_read_ == field) return;
    case kType:
      builder_->SkipDartType();  // read type.
      if (++next_read_ == field) return;
    case kInitializer:
      if (builder_->ReadTag() == kSomething)
        builder_->SkipExpression();  // read initializer.
      if (++next_read_ == field) return;
    case kEnd:
      return;
  }
}

FieldHelper::FieldHelper(StreamingFlowGraphBuilder* builder, intptr_t offset)
    : builder_(builder),
      next_read_(kStart),
      has_function_literal_initializer_(false) {
  builder_->SetOffset(offset);
}

void FieldHelper::ReadUntilExcluding(Field field,
                                     bool detect_function_literal_initializer) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = builder_->ReadTag();  // read tag.
      ASSERT(tag == kField);
      if (++next_read_ == field) return;
    }
    case kCanonicalName:
      canonical_name_ =
          builder_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
    case kPosition:
      position_ = builder_->ReadPosition(false);  // read position.
      if (++next_read_ == field) return;
    case kEndPosition:
      end_position_ = builder_->ReadPosition(false);  // read end position.
      if (++next_read_ == field) return;
    case kFlags:
      flags_ = builder_->ReadFlags();
      if (++next_read_ == field) return;
    case kFlags2:
      builder_->ReadFlags();
      if (++next_read_ == field) return;
    case kName:
      builder_->SkipName();  // read name.
      if (++next_read_ == field) return;
    case kSourceUriIndex:
      source_uri_index_ = builder_->ReadUInt();  // read source_uri_index.
      builder_->current_script_id_ = source_uri_index_;
      builder_->record_token_position(position_);
      builder_->record_token_position(end_position_);
      if (++next_read_ == field) return;
    case kAnnotations: {
      annotation_count_ = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        builder_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
    case kType:
      builder_->SkipDartType();  // read type.
      if (++next_read_ == field) return;
    case kInitializer:
      if (builder_->ReadTag() == kSomething) {
        if (detect_function_literal_initializer &&
            builder_->PeekTag() == kFunctionExpression) {
          AlternativeReadingScope alt(builder_->reader_);
          Tag tag = builder_->ReadTag();
          ASSERT(tag == kFunctionExpression);
          builder_->ReadPosition();  // read position.

          FunctionNodeHelper helper(builder_);
          helper.ReadUntilIncluding(FunctionNodeHelper::kEndPosition);

          has_function_literal_initializer_ = true;
          function_literal_start_ = helper.position_;
          function_literal_end_ = helper.end_position_;
        }
        builder_->SkipExpression();  // read initializer.
      }
      if (++next_read_ == field) return;
    case kEnd:
      return;
  }
}

void ProcedureHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = builder_->ReadTag();  // read tag.
      ASSERT(tag == kProcedure);
      if (++next_read_ == field) return;
    }
    case kCanonicalName:
      canonical_name_ =
          builder_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
    case kPosition:
      position_ = builder_->ReadPosition(false);  // read position.
      if (++next_read_ == field) return;
    case kEndPosition:
      end_position_ = builder_->ReadPosition(false);  // read end position.
      if (++next_read_ == field) return;
    case kKind:
      kind_ = static_cast<Kind>(builder_->ReadByte());
      if (++next_read_ == field) return;
    case kFlags:
      flags_ = builder_->ReadFlags();
      if (++next_read_ == field) return;
    case kName:
      builder_->SkipName();  // read name.
      if (++next_read_ == field) return;
    case kSourceUriIndex:
      source_uri_index_ = builder_->ReadUInt();  // read source_uri_index.
      builder_->current_script_id_ = source_uri_index_;
      builder_->record_token_position(position_);
      builder_->record_token_position(end_position_);
      if (++next_read_ == field) return;
    case kAnnotations: {
      annotation_count_ = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        builder_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
    case kFunction:
      if (builder_->ReadTag() == kSomething)
        builder_->SkipFunctionNode();  // read function node.
      if (++next_read_ == field) return;
    case kEnd:
      return;
  }
}

void ConstructorHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = builder_->ReadTag();  // read tag.
      ASSERT(tag == kConstructor);
      if (++next_read_ == field) return;
    }
    case kCanonicalName:
      canonical_name_ =
          builder_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
    case kPosition:
      position_ = builder_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
    case kEndPosition:
      end_position_ = builder_->ReadPosition();  // read end position.
      if (++next_read_ == field) return;
    case kFlags:
      flags_ = builder_->ReadFlags();
      if (++next_read_ == field) return;
    case kName:
      builder_->SkipName();  // read name.
      if (++next_read_ == field) return;
    case kAnnotations: {
      annotation_count_ = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        builder_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
    case kFunction:
      builder_->SkipFunctionNode();  // read function.
      if (++next_read_ == field) return;
    case kInitializers: {
      intptr_t list_length =
          builder_->ReadListLength();  // read initializers list length.
      for (intptr_t i = 0; i < list_length; i++) {
        builder_->SkipInitializer();
      }
      if (++next_read_ == field) return;
    }
    case kEnd:
      return;
  }
}

void ClassHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = builder_->ReadTag();  // read tag.
      ASSERT(tag == kClass);
      if (++next_read_ == field) return;
    }
    case kCanonicalName:
      canonical_name_ =
          builder_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
    case kPosition:
      position_ = builder_->ReadPosition(false);  // read position.
      if (++next_read_ == field) return;
    case kEndPosition:
      end_position_ = builder_->ReadPosition();  // read end position.
      if (++next_read_ == field) return;
    case kIsAbstract:
      is_abstract_ = builder_->ReadBool();  // read is_abstract.
      if (++next_read_ == field) return;
    case kNameIndex:
      name_index_ = builder_->ReadStringReference();  // read name index.
      if (++next_read_ == field) return;
    case kSourceUriIndex:
      source_uri_index_ = builder_->ReadUInt();  // read source_uri_index.
      builder_->current_script_id_ = source_uri_index_;
      builder_->record_token_position(position_);
      if (++next_read_ == field) return;
    case kAnnotations: {
      annotation_count_ = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        builder_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
    case kTypeParameters:
      builder_->SkipTypeParametersList();  // read type parameters.
      if (++next_read_ == field) return;
    case kSuperClass: {
      Tag type_tag = builder_->ReadTag();  // read super class type (part 1).
      if (type_tag == kSomething) {
        builder_->SkipDartType();  // read super class type (part 2).
      }
      if (++next_read_ == field) return;
    }
    case kMixinType: {
      Tag type_tag = builder_->ReadTag();  // read mixin type (part 1).
      if (type_tag == kSomething) {
        builder_->SkipDartType();  // read mixin type (part 2).
      }
      if (++next_read_ == field) return;
    }
    case kImplementedClasses:
      builder_->SkipListOfDartTypes();  // read implemented_classes.
      if (++next_read_ == field) return;
    case kFields: {
      intptr_t list_length =
          builder_->ReadListLength();  // read fields list length.
      for (intptr_t i = 0; i < list_length; i++) {
        FieldHelper field_helper(builder_);
        field_helper.ReadUntilExcluding(FieldHelper::kEnd);  // read field.
      }
      if (++next_read_ == field) return;
    }
    case kConstructors: {
      intptr_t list_length =
          builder_->ReadListLength();  // read constructors list length.
      for (intptr_t i = 0; i < list_length; i++) {
        ConstructorHelper constructor_helper(builder_);
        constructor_helper.ReadUntilExcluding(
            ConstructorHelper::kEnd);  // read constructor.
      }
      if (++next_read_ == field) return;
    }
    case kProcedures: {
      procedure_count_ = builder_->ReadListLength();  // read procedures #.
      for (intptr_t i = 0; i < procedure_count_; i++) {
        ProcedureHelper procedure_helper(builder_);
        procedure_helper.ReadUntilExcluding(
            ProcedureHelper::kEnd);  // read procedure.
      }
      if (++next_read_ == field) return;
    }
    case kClassIndex:
      // Read class index.
      for (intptr_t i = 0; i < procedure_count_; ++i) {
        builder_->reader_->ReadUInt32();
      }
      builder_->reader_->ReadUInt32();
      builder_->reader_->ReadUInt32();
      if (++next_read_ == field) return;
    case kEnd:
      return;
  }
}

void LibraryHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kFlags: {
      flags_ = builder_->ReadFlags();
      if (++next_read_ == field) return;
    }
    case kCanonicalName:
      canonical_name_ =
          builder_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
    case kName:
      name_index_ = builder_->ReadStringReference();  // read name index.
      if (++next_read_ == field) return;
    case kSourceUriIndex:
      source_uri_index_ = builder_->ReadUInt();  // read source_uri_index.
      builder_->current_script_id_ = source_uri_index_;
      if (++next_read_ == field) return;
    case kAnnotations:
      builder_->SkipListOfExpressions();  // read annotations.
      if (++next_read_ == field) return;
    case kDependencies: {
      intptr_t dependency_count = builder_->ReadUInt();  // read list length.
      for (intptr_t i = 0; i < dependency_count; ++i) {
        builder_->SkipLibraryDependency();
      }
      if (++next_read_ == field) return;
    }
    case kAdditionalExports: {
      intptr_t name_count = builder_->ReadUInt();
      for (intptr_t i = 0; i < name_count; ++i) {
        builder_->SkipCanonicalNameReference();
      }
      if (++next_read_ == field) return;
    }
    case kParts: {
      intptr_t part_count = builder_->ReadUInt();  // read list length.
      for (intptr_t i = 0; i < part_count; ++i) {
        builder_->SkipLibraryPart();
      }
      if (++next_read_ == field) return;
    }
    case kTypedefs: {
      intptr_t typedef_count = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < typedef_count; i++) {
        builder_->SkipLibraryTypedef();
      }
      if (++next_read_ == field) return;
    }
    case kClasses: {
      class_count_ = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < class_count_; ++i) {
        ClassHelper class_helper(builder_);
        class_helper.ReadUntilExcluding(ClassHelper::kEnd);
      }
      if (++next_read_ == field) return;
    }
    case kToplevelField: {
      intptr_t field_count = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < field_count; ++i) {
        FieldHelper field_helper(builder_);
        field_helper.ReadUntilExcluding(FieldHelper::kEnd);
      }
      if (++next_read_ == field) return;
    }
    case kToplevelProcedures: {
      procedure_count_ = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < procedure_count_; ++i) {
        ProcedureHelper procedure_helper(builder_);
        procedure_helper.ReadUntilExcluding(ProcedureHelper::kEnd);
      }
      if (++next_read_ == field) return;
    }
    case kLibraryIndex:
      // Read library index.
      for (intptr_t i = 0; i < class_count_; ++i) {
        builder_->reader_->ReadUInt32();
      }
      builder_->reader_->ReadUInt32();
      builder_->reader_->ReadUInt32();
      for (intptr_t i = 0; i < procedure_count_; ++i) {
        builder_->reader_->ReadUInt32();
      }
      builder_->reader_->ReadUInt32();
      builder_->reader_->ReadUInt32();
      if (++next_read_ == field) return;
    case kEnd:
      return;
  }
}

void LibraryDependencyHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kFileOffset: {
      builder_->ReadPosition();
      if (++next_read_ == field) return;
    }
    case kFlags: {
      flags_ = builder_->ReadFlags();
      if (++next_read_ == field) return;
    }
    case kAnnotations: {
      builder_->SkipListOfExpressions();
      if (++next_read_ == field) return;
    }
    case kTargetLibrary: {
      target_library_canonical_name_ = builder_->ReadCanonicalNameReference();
      if (++next_read_ == field) return;
    }
    case kName: {
      name_index_ = builder_->ReadStringReference();
      if (++next_read_ == field) return;
    }
    case kCombinators: {
      intptr_t count = builder_->ReadListLength();
      for (intptr_t i = 0; i < count; ++i) {
        // Skip flags
        builder_->SkipBytes(1);
        // Skip list of names.
        builder_->SkipListOfStrings();
      }
      if (++next_read_ == field) return;
    }
    case kEnd:
      return;
  }
}

MetadataHelper::MetadataHelper(StreamingFlowGraphBuilder* builder)
    : builder_(builder),
      translation_helper_(builder->translation_helper_),
      mappings_offset_(0),
      mappings_num_(0),
      last_node_offset_(0),
      last_mapping_index_(0) {}

void MetadataHelper::SetMetadataMappings(intptr_t mappings_offset,
                                         intptr_t mappings_num) {
  ASSERT((mappings_offset_ == 0) && (mappings_num_ == 0));
  ASSERT((mappings_offset != 0) && (mappings_num != 0));
  mappings_offset_ = mappings_offset;
  mappings_num_ = mappings_num;

#ifdef DEBUG
  // Verify that node offsets are sorted.
  {
    Reader reader(H.metadata_mappings());
    reader.set_offset(mappings_offset);

    intptr_t prev_node_offset = 0;
    for (intptr_t i = 0; i < mappings_num; ++i) {
      intptr_t node_offset = reader.ReadUInt32();
      intptr_t md_offset = reader.ReadUInt32();

      ASSERT((node_offset > 0) && (md_offset > 0));
      ASSERT(node_offset > prev_node_offset);
      prev_node_offset = node_offset;
    }
  }
#endif  // DEBUG

  last_node_offset_ = builder_->data_program_offset_ +
                      builder_->parsed_function()->function().kernel_offset();
  last_mapping_index_ = FindMetadataMapping(last_node_offset_);
}

intptr_t MetadataHelper::FindMetadataMapping(intptr_t node_offset) {
  const intptr_t kUInt32Size = 4;
  ASSERT(mappings_num_ > 0);

  Reader reader(H.metadata_mappings());

  intptr_t left = 0;
  intptr_t right = mappings_num_ - 1;
  while (left < right) {
    intptr_t mid = ((right - left) / 2) + left;
    intptr_t mid_node_offset =
        reader.ReadUInt32At(mappings_offset_ + mid * 2 * kUInt32Size);

    if (node_offset < mid_node_offset) {
      right = mid - 1;
    } else if (node_offset > mid_node_offset) {
      left = mid + 1;
    } else {
      return mid;  // Exact match found.
    }
  }
  ASSERT((0 <= left) && (left <= mappings_num_));

  // Approximate match is found. Make sure it has an offset greater or equal
  // to the given node offset.
  if (left < mappings_num_) {
    intptr_t found_node_offset =
        reader.ReadUInt32At(mappings_offset_ + left * 2 * kUInt32Size);

    if (found_node_offset < node_offset) {
      ++left;
    }
  }
  ASSERT((left == mappings_num_) ||
         static_cast<intptr_t>(reader.ReadUInt32At(
             mappings_offset_ + left * 2 * kUInt32Size)) >= node_offset);

  return left;
}

intptr_t MetadataHelper::GetNextMetadataPayloadOffset(intptr_t node_offset) {
  builder_->EnsureMetadataIsScanned();

  if (mappings_num_ == 0) {
    return -1;  // No metadata.
  }

  node_offset += builder_->data_program_offset_;

  // Nodes are parsed in linear order most of the time, so do the search
  // only if looking back.
  if (node_offset < last_node_offset_) {
    last_mapping_index_ = FindMetadataMapping(node_offset);
  }

  intptr_t index = last_mapping_index_;
  intptr_t mapping_node_offset = 0;
  intptr_t mapping_md_offset = 0;

  Reader reader(H.metadata_mappings());
  const intptr_t kUInt32Size = 4;
  reader.set_offset(mappings_offset_ + index * 2 * kUInt32Size);

  for (; index < mappings_num_; ++index) {
    mapping_node_offset = reader.ReadUInt32();
    mapping_md_offset = reader.ReadUInt32();

    if (mapping_node_offset >= node_offset) {
      break;
    }
  }

  last_mapping_index_ = index;
  last_node_offset_ = node_offset;

  if ((index < mappings_num_) && (mapping_node_offset == node_offset)) {
    ASSERT(mapping_md_offset > 0);
    return mapping_md_offset;
  } else {
    return -1;
  }
}

bool DirectCallMetadataHelper::ReadMetadata(intptr_t node_offset,
                                            NameIndex* target_name,
                                            bool* check_receiver_for_null) {
  intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return false;
  }

  AlternativeReadingScope alt(builder_->reader_, &H.metadata_payloads(),
                              md_offset - MetadataPayloadOffset);

  *target_name = builder_->ReadCanonicalNameReference();
  *check_receiver_for_null = builder_->ReadBool();
  return true;
}

DirectCallMetadata DirectCallMetadataHelper::GetDirectTargetForPropertyGet(
    intptr_t node_offset) {
  NameIndex kernel_name;
  bool check_receiver_for_null = false;
  if (!ReadMetadata(node_offset, &kernel_name, &check_receiver_for_null)) {
    return DirectCallMetadata(Function::null_function(), false);
  }

  if (H.IsProcedure(kernel_name) && !H.IsGetter(kernel_name)) {
    // Tear-off. Use method extractor as direct call target.
    const String& method_name = H.DartMethodName(kernel_name);
    const Function& target_method = Function::ZoneHandle(
        builder_->zone_,
        builder_->LookupMethodByMember(kernel_name, method_name));
    const String& getter_name = H.DartGetterName(kernel_name);
    return DirectCallMetadata(
        Function::ZoneHandle(builder_->zone_,
                             target_method.GetMethodExtractor(getter_name)),
        check_receiver_for_null);
  } else {
    const String& getter_name = H.DartGetterName(kernel_name);
    const Function& target = Function::ZoneHandle(
        builder_->zone_,
        builder_->LookupMethodByMember(kernel_name, getter_name));
    ASSERT(target.IsGetterFunction() || target.IsImplicitGetterFunction());
    return DirectCallMetadata(target, check_receiver_for_null);
  }
}

DirectCallMetadata DirectCallMetadataHelper::GetDirectTargetForPropertySet(
    intptr_t node_offset) {
  NameIndex kernel_name;
  bool check_receiver_for_null = false;
  if (!ReadMetadata(node_offset, &kernel_name, &check_receiver_for_null)) {
    return DirectCallMetadata(Function::null_function(), false);
  }

  const String& method_name = H.DartSetterName(kernel_name);
  const Function& target = Function::ZoneHandle(
      builder_->zone_,
      builder_->LookupMethodByMember(kernel_name, method_name));
  ASSERT(target.IsSetterFunction() || target.IsImplicitSetterFunction());

  return DirectCallMetadata(target, check_receiver_for_null);
}

DirectCallMetadata DirectCallMetadataHelper::GetDirectTargetForMethodInvocation(
    intptr_t node_offset) {
  NameIndex kernel_name;
  bool check_receiver_for_null = false;
  if (!ReadMetadata(node_offset, &kernel_name, &check_receiver_for_null)) {
    return DirectCallMetadata(Function::null_function(), false);
  }

  const String& method_name = H.DartProcedureName(kernel_name);
  const Function& target = Function::ZoneHandle(
      builder_->zone_,
      builder_->LookupMethodByMember(kernel_name, method_name));

  return DirectCallMetadata(target, check_receiver_for_null);
}

StreamingScopeBuilder::StreamingScopeBuilder(ParsedFunction* parsed_function)
    : result_(NULL),
      parsed_function_(parsed_function),
      translation_helper_(Thread::Current()),
      zone_(translation_helper_.zone()),
      current_function_scope_(NULL),
      scope_(NULL),
      depth_(0),
      name_index_(0),
      needs_expr_temp_(false),
      builder_(new StreamingFlowGraphBuilder(
          &translation_helper_,
          parsed_function->function().script(),
          zone_,
          TypedData::Handle(Z, parsed_function->function().KernelData()),
          parsed_function->function().KernelDataProgramOffset())),
      type_translator_(builder_, /*finalize=*/true) {
  Script& script = Script::Handle(Z, parsed_function->function().script());
  H.InitFromScript(script);
  type_translator_.active_class_ = &active_class_;
}

StreamingScopeBuilder::~StreamingScopeBuilder() {
  delete builder_;
}

ScopeBuildingResult* StreamingScopeBuilder::BuildScopes() {
  if (result_ != NULL) return result_;

  ASSERT(scope_ == NULL && depth_.loop_ == 0 && depth_.function_ == 0);
  result_ = new (Z) ScopeBuildingResult();

  const Function& function = parsed_function_->function();

  // Setup a [ActiveClassScope] and a [ActiveMemberScope] which will be used
  // e.g. for type translation.
  const Class& klass = Class::Handle(zone_, function.Owner());

  Function& outermost_function = Function::Handle(Z);
  builder_->DiscoverEnclosingElements(Z, function, &outermost_function);

  ActiveClassScope active_class_scope(&active_class_, &klass);
  ActiveMemberScope active_member(&active_class_, &outermost_function);
  ActiveTypeParametersScope active_type_params(&active_class_, function, Z);

  LocalScope* enclosing_scope = NULL;
  if (function.IsLocalFunction()) {
    enclosing_scope = LocalScope::RestoreOuterScope(
        ContextScope::Handle(Z, function.context_scope()));
  }
  current_function_scope_ = scope_ = new (Z) LocalScope(enclosing_scope, 0, 0);
  scope_->set_begin_token_pos(function.token_pos());
  scope_->set_end_token_pos(function.end_token_pos());

  // Add function type arguments variable before current context variable.
  if (I->reify_generic_functions() && function.IsGeneric()) {
    LocalVariable* type_args_var = MakeVariable(
        TokenPosition::kNoSource, TokenPosition::kNoSource,
        Symbols::FunctionTypeArgumentsVar(), AbstractType::dynamic_type());
    scope_->AddVariable(type_args_var);
    parsed_function_->set_function_type_arguments(type_args_var);
  }

  LocalVariable* context_var = parsed_function_->current_context_var();
  context_var->set_is_forced_stack();
  scope_->AddVariable(context_var);

  parsed_function_->SetNodeSequence(
      new SequenceNode(TokenPosition::kNoSource, scope_));

  builder_->SetOffset(function.kernel_offset());

  FunctionNodeHelper function_node_helper(builder_);

  switch (function.kind()) {
    case RawFunction::kClosureFunction:
    case RawFunction::kImplicitClosureFunction:
    case RawFunction::kConvertedClosureFunction:
    case RawFunction::kRegularFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
    case RawFunction::kConstructor: {
      const Tag tag = builder_->PeekTag();
      builder_->ReadUntilFunctionNode();
      function_node_helper.ReadUntilExcluding(
          FunctionNodeHelper::kPositionalParameters);
      current_function_async_marker_ = function_node_helper.async_marker_;
      // NOTE: FunctionNode is read further below the if.

      intptr_t pos = 0;
      if (function.IsClosureFunction()) {
        LocalVariable* closure_parameter = MakeVariable(
            TokenPosition::kNoSource, TokenPosition::kNoSource,
            Symbols::ClosureParameter(), AbstractType::dynamic_type());
        closure_parameter->set_is_forced_stack();
        scope_->InsertParameterAt(pos++, closure_parameter);
      } else if (!function.is_static()) {
        // We use [is_static] instead of [IsStaticFunction] because the latter
        // returns `false` for constructors.
        Class& klass = Class::Handle(Z, function.Owner());
        Type& klass_type = H.GetCanonicalType(klass);
        LocalVariable* variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         Symbols::This(), klass_type);
        scope_->InsertParameterAt(pos++, variable);
        result_->this_variable = variable;

        // We visit instance field initializers because they might contain
        // [Let] expressions and we need to have a mapping.
        if (tag == kConstructor) {
          Class& parent_class = Class::Handle(Z, function.Owner());
          Array& class_fields = Array::Handle(Z, parent_class.fields());
          Field& class_field = Field::Handle(Z);
          for (intptr_t i = 0; i < class_fields.Length(); ++i) {
            class_field ^= class_fields.At(i);
            if (!class_field.is_static()) {
              TypedData& kernel_data =
                  TypedData::Handle(Z, class_field.KernelData());
              ASSERT(!kernel_data.IsNull());
              intptr_t field_offset = class_field.kernel_offset();
              AlternativeReadingScope alt(builder_->reader_, &kernel_data,
                                          field_offset);
              FieldHelper field_helper(builder_);
              field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
              Tag initializer_tag =
                  builder_->ReadTag();  // read first part of initializer.
              if (initializer_tag == kSomething) {
                EnterScope(field_offset);
                VisitExpression();  // read initializer.
                ExitScope(field_helper.position_, field_helper.end_position_);
              }
            }
          }
        }
      } else if (function.IsFactory()) {
        LocalVariable* variable = MakeVariable(
            TokenPosition::kNoSource, TokenPosition::kNoSource,
            Symbols::TypeArgumentsParameter(), AbstractType::dynamic_type());
        scope_->InsertParameterAt(pos++, variable);
        result_->type_arguments_variable = variable;
      }

      // Continue reading FunctionNode:
      // read positional_parameters and named_parameters.
      AddPositionalAndNamedParameters(pos);

      // We generate a synthetic body for implicit closure functions - which
      // will forward the call to the real function.
      //     -> see BuildGraphOfImplicitClosureFunction
      if (!function.IsImplicitClosureFunction()) {
        builder_->SetOffset(function.kernel_offset());
        first_body_token_position_ = TokenPosition::kNoSource;
        VisitNode();

        // TODO(jensj): HACK: Push the begin token to after any parameters to
        // avoid crash when breaking on definition line of async method in
        // debugger. It seems that another scope needs to be added
        // in which captures are made, but I can't make that work.
        // This 'solution' doesn't crash, but I cannot see the parameters at
        // that particular breakpoint either.
        // Also push the end token to after the "}" to avoid crashing on
        // stepping past the last line (to the "}" character).
        if (first_body_token_position_.IsReal()) {
          scope_->set_begin_token_pos(first_body_token_position_);
        }
        if (scope_->end_token_pos().IsReal()) {
          scope_->set_end_token_pos(scope_->end_token_pos().Next());
        }
      }
      break;
    }
    case RawFunction::kImplicitGetter:
    case RawFunction::kImplicitStaticFinalGetter:
    case RawFunction::kImplicitSetter: {
      ASSERT(builder_->PeekTag() == kField);
      if (IsStaticInitializer(function, Z)) {
        VisitNode();
        break;
      }
      bool is_setter = function.IsImplicitSetterFunction();
      bool is_method = !function.IsStaticFunction();
      intptr_t pos = 0;
      if (is_method) {
        Class& klass = Class::Handle(Z, function.Owner());
        Type& klass_type = H.GetCanonicalType(klass);
        LocalVariable* variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         Symbols::This(), klass_type);
        scope_->InsertParameterAt(pos++, variable);
        result_->this_variable = variable;
      }
      if (is_setter) {
        result_->setter_value =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         Symbols::Value(), AbstractType::dynamic_type());
        scope_->InsertParameterAt(pos++, result_->setter_value);
      }
      break;
    }
    case RawFunction::kMethodExtractor: {
      // Add a receiver parameter.  Though it is captured, we emit code to
      // explicitly copy it to a fixed offset in a freshly-allocated context
      // instead of using the generic code for regular functions.
      // Therefore, it isn't necessary to mark it as captured here.
      Class& klass = Class::Handle(Z, function.Owner());
      Type& klass_type = H.GetCanonicalType(klass);
      LocalVariable* variable =
          MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                       Symbols::This(), klass_type);
      scope_->InsertParameterAt(0, variable);
      result_->this_variable = variable;
      break;
    }
    case RawFunction::kNoSuchMethodDispatcher:
    case RawFunction::kInvokeFieldDispatcher:
      for (intptr_t i = 0; i < function.NumParameters(); ++i) {
        LocalVariable* variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         String::ZoneHandle(Z, function.ParameterNameAt(i)),
                         AbstractType::dynamic_type());
        scope_->InsertParameterAt(i, variable);
      }
      break;
    case RawFunction::kSignatureFunction:
    case RawFunction::kIrregexpFunction:
      UNREACHABLE();
  }
  if (needs_expr_temp_) {
    scope_->AddVariable(parsed_function_->EnsureExpressionTemp());
  }
  parsed_function_->AllocateVariables();

  return result_;
}

void StreamingScopeBuilder::VisitNode() {
  Tag tag = builder_->PeekTag();
  switch (tag) {
    case kConstructor:
      VisitConstructor();
      return;
    case kProcedure:
      VisitProcedure();
      return;
    case kField:
      VisitField();
      return;
    case kFunctionNode:
      VisitFunctionNode();
      return;
    default:
      UNIMPLEMENTED();
      return;
  }
}

void StreamingScopeBuilder::VisitConstructor() {
  // Field initializers that come from non-static field declarations are
  // compiled as if they appear in the constructor initializer list.  This is
  // important for closure-valued field initializers because the VM expects the
  // corresponding closure functions to appear as if they were nested inside the
  // constructor.
  ConstructorHelper constructor_helper(builder_);
  constructor_helper.ReadUntilExcluding(ConstructorHelper::kFunction);
  {
    const Function& function = parsed_function_->function();
    Class& parent_class = Class::Handle(Z, function.Owner());
    Array& class_fields = Array::Handle(Z, parent_class.fields());
    Field& class_field = Field::Handle(Z);
    for (intptr_t i = 0; i < class_fields.Length(); ++i) {
      class_field ^= class_fields.At(i);
      if (!class_field.is_static()) {
        TypedData& kernel_data = TypedData::Handle(Z, class_field.KernelData());
        ASSERT(!kernel_data.IsNull());
        intptr_t field_offset = class_field.kernel_offset();
        AlternativeReadingScope alt(builder_->reader_, &kernel_data,
                                    field_offset);
        FieldHelper field_helper(builder_);
        field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
        Tag initializer_tag = builder_->ReadTag();
        if (initializer_tag == kSomething) {
          VisitExpression();  // read initializer.
        }
      }
    }
  }

  // Visit children (note that there's no reason to visit the name).
  VisitFunctionNode();
  intptr_t list_length =
      builder_->ReadListLength();  // read initializers list length.
  for (intptr_t i = 0; i < list_length; i++) {
    VisitInitializer();
  }
}

void StreamingScopeBuilder::VisitProcedure() {
  ProcedureHelper procedure_helper(builder_);
  procedure_helper.ReadUntilExcluding(ProcedureHelper::kFunction);
  if (builder_->ReadTag() == kSomething) {
    VisitFunctionNode();
  }
}

void StreamingScopeBuilder::VisitField() {
  FieldHelper field_helper(builder_);
  field_helper.ReadUntilExcluding(FieldHelper::kType);
  VisitDartType();                // read type.
  Tag tag = builder_->ReadTag();  // read initializer (part 1).
  if (tag == kSomething) {
    VisitExpression();  // read initializer (part 2).
  }
}

void StreamingScopeBuilder::VisitFunctionNode() {
  FunctionNodeHelper function_node_helper(builder_);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);

  intptr_t list_length =
      builder_->ReadListLength();  // read type_parameters list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    builder_->ReadFlags();              // read flags.
    builder_->SkipListOfExpressions();  // read annotations.
    builder_->SkipStringReference();    // read ith name index.
    VisitDartType();                    // read ith bound.
  }
  function_node_helper.SetJustRead(FunctionNodeHelper::kTypeParameters);

  if (FLAG_causal_async_stacks &&
      (function_node_helper.dart_async_marker_ == FunctionNodeHelper::kAsync ||
       function_node_helper.dart_async_marker_ ==
           FunctionNodeHelper::kAsyncStar)) {
    LocalVariable* asyncStackTraceVar = MakeVariable(
        TokenPosition::kNoSource, TokenPosition::kNoSource,
        Symbols::AsyncStackTraceVar(), AbstractType::dynamic_type());
    scope_->AddVariable(asyncStackTraceVar);
  }

  if (function_node_helper.async_marker_ == FunctionNodeHelper::kSyncYielding) {
    LocalScope* scope = parsed_function_->node_sequence()->scope();
    intptr_t offset = parsed_function_->function().num_fixed_parameters();
    for (intptr_t i = 0;
         i < parsed_function_->function().NumOptionalPositionalParameters();
         i++) {
      scope->VariableAt(offset + i)->set_is_forced_stack();
    }
  }

  // Read (but don't visit) the positional and named parameters, because they've
  // already been added to the scope.
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kBody);

  if (builder_->ReadTag() == kSomething) {
    PositionScope scope(builder_->reader_);
    VisitStatement();  // Read body
    first_body_token_position_ = builder_->reader_->min_position();
  }

  // Ensure that :await_jump_var, :await_ctx_var, :async_op and
  // :async_stack_trace are captured.
  if (function_node_helper.async_marker_ == FunctionNodeHelper::kSyncYielding) {
    {
      LocalVariable* temp = NULL;
      LookupCapturedVariableByName(
          (depth_.function_ == 0) ? &result_->yield_jump_variable : &temp,
          Symbols::AwaitJumpVar());
    }
    {
      LocalVariable* temp = NULL;
      LookupCapturedVariableByName(
          (depth_.function_ == 0) ? &result_->yield_context_variable : &temp,
          Symbols::AwaitContextVar());
    }
    {
      LocalVariable* temp =
          scope_->LookupVariable(Symbols::AsyncOperation(), true);
      if (temp != NULL) {
        scope_->CaptureVariable(temp);
      }
    }
    if (FLAG_causal_async_stacks) {
      LocalVariable* temp =
          scope_->LookupVariable(Symbols::AsyncStackTraceVar(), true);
      if (temp != NULL) {
        scope_->CaptureVariable(temp);
      }
    }
  }
}

void StreamingScopeBuilder::VisitInitializer() {
  Tag tag = builder_->ReadTag();
  builder_->ReadByte();  // read isSynthetic flag.
  switch (tag) {
    case kInvalidInitializer:
      return;
    case kFieldInitializer:
      builder_->SkipCanonicalNameReference();  // read field_reference.
      VisitExpression();                       // read value.
      return;
    case kSuperInitializer:
      builder_->SkipCanonicalNameReference();  // read target_reference.
      VisitArguments();                        // read arguments.
      return;
    case kRedirectingInitializer:
      builder_->SkipCanonicalNameReference();  // read target_reference.
      VisitArguments();                        // read arguments.
      return;
    case kLocalInitializer:
      VisitVariableDeclaration();  // read variable.
      return;
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }
}

void StreamingScopeBuilder::VisitExpression() {
  uint8_t payload = 0;
  Tag tag = builder_->ReadTag(&payload);
  switch (tag) {
    case kInvalidExpression:
      return;
    case kVariableGet: {
      builder_->ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          builder_->ReadUInt();          // read kernel position.
      builder_->ReadUInt();              // read relative variable index.
      builder_->SkipOptionalDartType();  // read promoted type.
      LookupVariable(variable_kernel_offset);
      return;
    }
    case kSpecializedVariableGet: {
      builder_->ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          builder_->ReadUInt();  // read kernel position.
      LookupVariable(variable_kernel_offset);
      return;
    }
    case kVariableSet: {
      builder_->ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          builder_->ReadUInt();  // read kernel position.
      builder_->ReadUInt();      // read relative variable index.
      LookupVariable(variable_kernel_offset);
      VisitExpression();  // read expression.
      return;
    }
    case kSpecializedVariableSet: {
      builder_->ReadPosition();  // read position.
      intptr_t variable_kernel_offset =
          builder_->ReadUInt();  // read kernel position.
      LookupVariable(variable_kernel_offset);
      VisitExpression();  // read expression.
      return;
    }
    case kPropertyGet:
      builder_->ReadPosition();  // read position.
      builder_->ReadFlags();     // read flags.
      VisitExpression();         // read receiver.
      builder_->SkipName();      // read name.
      // read interface_target_reference.
      builder_->SkipCanonicalNameReference();
      return;
    case kPropertySet:
      builder_->ReadPosition();  // read position.
      VisitExpression();         // read receiver.
      builder_->SkipName();      // read name.
      VisitExpression();         // read value.
      // read interface_target_reference.
      builder_->SkipCanonicalNameReference();
      return;
    case kDirectPropertyGet:
      builder_->ReadPosition();                // read position.
      builder_->ReadFlags();                   // read flags.
      VisitExpression();                       // read receiver.
      builder_->SkipCanonicalNameReference();  // read target_reference.
      return;
    case kDirectPropertySet:
      builder_->ReadPosition();                // read position.
      VisitExpression();                       // read receiver.
      builder_->SkipCanonicalNameReference();  // read target_reference.
      VisitExpression();                       // read value·
      return;
    case kSuperPropertyGet:
      HandleSpecialLoad(&result_->this_variable, Symbols::This());
      builder_->ReadPosition();                // read position.
      builder_->SkipName();                    // read name.
      builder_->SkipCanonicalNameReference();  // read target_reference.
      return;
    case kSuperPropertySet:
      HandleSpecialLoad(&result_->this_variable, Symbols::This());
      builder_->ReadPosition();                // read position.
      builder_->SkipName();                    // read name.
      VisitExpression();                       // read value.
      builder_->SkipCanonicalNameReference();  // read target_reference.
      return;
    case kStaticGet:
      builder_->ReadPosition();                // read position.
      builder_->SkipCanonicalNameReference();  // read target_reference.
      return;
    case kStaticSet:
      builder_->ReadPosition();                // read position.
      builder_->SkipCanonicalNameReference();  // read target_reference.
      VisitExpression();                       // read expression.
      return;
    case kMethodInvocation:
      builder_->ReadPosition();  // read position.
      builder_->ReadFlags();     // read flags.
      VisitExpression();         // read receiver.
      builder_->SkipName();      // read name.
      VisitArguments();          // read arguments.
      // read interface_target_reference.
      builder_->SkipCanonicalNameReference();
      return;
    case kDirectMethodInvocation:
      builder_->ReadPosition();                // read position.
      builder_->ReadFlags();                   // read flags.
      VisitExpression();                       // read receiver.
      builder_->SkipCanonicalNameReference();  // read target_reference.
      VisitArguments();                        // read arguments.
      return;
    case kSuperMethodInvocation:
      HandleSpecialLoad(&result_->this_variable, Symbols::This());
      builder_->ReadPosition();  // read position.
      builder_->SkipName();      // read name.
      VisitArguments();          // read arguments.
      // read interface_target_reference.
      builder_->SkipCanonicalNameReference();
      return;
    case kStaticInvocation:
    case kConstStaticInvocation:
      builder_->ReadPosition();                // read position.
      builder_->SkipCanonicalNameReference();  // read procedure_reference.
      VisitArguments();                        // read arguments.
      return;
    case kConstructorInvocation:
    case kConstConstructorInvocation:
      builder_->ReadPosition();                // read position.
      builder_->SkipCanonicalNameReference();  // read target_reference.
      VisitArguments();                        // read arguments.
      return;
    case kNot:
      VisitExpression();  // read expression.
      return;
    case kLogicalExpression:
      needs_expr_temp_ = true;
      VisitExpression();       // read left.
      builder_->SkipBytes(1);  // read operator.
      VisitExpression();       // read right.
      return;
    case kConditionalExpression: {
      needs_expr_temp_ = true;
      VisitExpression();                 // read condition.
      VisitExpression();                 // read then.
      VisitExpression();                 // read otherwise.
      builder_->SkipOptionalDartType();  // read unused static type.
      return;
    }
    case kStringConcatenation: {
      builder_->ReadPosition();                           // read position.
      intptr_t list_length = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitExpression();  // read ith expression.
      }
      return;
    }
    case kIsExpression:
      builder_->ReadPosition();  // read position.
      VisitExpression();         // read operand.
      VisitDartType();           // read type.
      return;
    case kAsExpression:
      builder_->ReadPosition();  // read position.
      builder_->ReadFlags();     // read flags.
      VisitExpression();         // read operand.
      VisitDartType();           // read type.
      return;
    case kSymbolLiteral:
      builder_->SkipStringReference();  // read index into string table.
      return;
    case kTypeLiteral:
      VisitDartType();  // read type.
      return;
    case kThisExpression:
      HandleSpecialLoad(&result_->this_variable, Symbols::This());
      return;
    case kRethrow:
      builder_->ReadPosition();  // read position.
      return;
    case kThrow:
      builder_->ReadPosition();  // read position.
      VisitExpression();         // read expression.
      return;
    case kListLiteral:
    case kConstListLiteral: {
      builder_->ReadPosition();                           // read position.
      VisitDartType();                                    // read type.
      intptr_t list_length = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitExpression();  // read ith expression.
      }
      return;
    }
    case kMapLiteral:
    case kConstMapLiteral: {
      builder_->ReadPosition();                           // read position.
      VisitDartType();                                    // read key type.
      VisitDartType();                                    // read value type.
      intptr_t list_length = builder_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitExpression();  // read ith key.
        VisitExpression();  // read ith value.
      }
      return;
    }
    case kFunctionExpression: {
      intptr_t offset =
          builder_->ReaderOffset() - 1;  // -1 to include tag byte.
      builder_->ReadPosition();          // read position.
      HandleLocalFunction(offset);       // read function node.
      return;
    }
    case kLet: {
      PositionScope scope(builder_->reader_);
      intptr_t offset =
          builder_->ReaderOffset() - 1;  // -1 to include tag byte.

      EnterScope(offset);

      VisitVariableDeclaration();  // read variable declaration.
      VisitExpression();           // read expression.

      ExitScope(builder_->reader_->min_position(),
                builder_->reader_->max_position());
      return;
    }
    case kBigIntLiteral:
      builder_->SkipStringReference();  // read string reference.
      return;
    case kStringLiteral:
      builder_->SkipStringReference();  // read string reference.
      return;
    case kSpecialIntLiteral:
      return;
    case kNegativeIntLiteral:
      builder_->ReadUInt();  // read value.
      return;
    case kPositiveIntLiteral:
      builder_->ReadUInt();  // read value.
      return;
    case kDoubleLiteral:
      builder_->SkipStringReference();  // read index into string table.
      return;
    case kTrueLiteral:
      return;
    case kFalseLiteral:
      return;
    case kNullLiteral:
      return;
    case kVectorCreation:
      builder_->ReadUInt();  // read size.
      return;
    case kVectorGet:
      VisitExpression();     // read expression.
      builder_->ReadUInt();  // read index.
      return;
    case kVectorSet:
      VisitExpression();     // read vector expression.
      builder_->ReadUInt();  // read index.
      VisitExpression();     // read value.
      return;
    case kVectorCopy:
      VisitExpression();  // read vector expression.
      return;
    case kClosureCreation:
      builder_->SkipCanonicalNameReference();  // read function reference.
      VisitExpression();                       // read context vector.
      VisitDartType();                  // read function type of the closure.
      builder_->SkipListOfDartTypes();  // read type arguments.
      return;
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }
}

void StreamingScopeBuilder::VisitStatement() {
  Tag tag = builder_->ReadTag();  // read tag.
  switch (tag) {
    case kInvalidStatement:
      return;
    case kExpressionStatement:
      VisitExpression();  // read expression.
      return;
    case kBlock: {
      PositionScope scope(builder_->reader_);
      intptr_t offset =
          builder_->ReaderOffset() - 1;  // -1 to include tag byte.

      EnterScope(offset);

      intptr_t list_length =
          builder_->ReadListLength();  // read number of statements.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitStatement();  // read ith statement.
      }

      ExitScope(builder_->reader_->min_position(),
                builder_->reader_->max_position());
      return;
    }
    case kEmptyStatement:
      return;
    case kAssertStatement: {
      if (I->asserts()) {
        VisitExpression();              // Read condition.
        builder_->ReadPosition();       // read condition start offset.
        builder_->ReadPosition();       // read condition end offset.
        Tag tag = builder_->ReadTag();  // read (first part of) message.
        if (tag == kSomething) {
          VisitExpression();  // read (rest of) message.
        }
      } else {
        builder_->SkipExpression();     // Read condition.
        builder_->ReadPosition();       // read condition start offset.
        builder_->ReadPosition();       // read condition end offset.
        Tag tag = builder_->ReadTag();  // read (first part of) message.
        if (tag == kSomething) {
          builder_->SkipExpression();  // read (rest of) message.
        }
      }
      return;
    }
    case kLabeledStatement:
      VisitStatement();  // read body.
      return;
    case kBreakStatement:
      builder_->ReadPosition();  // read position.
      builder_->ReadUInt();      // read target_index.
      return;
    case kWhileStatement:
      ++depth_.loop_;
      builder_->ReadPosition();  // read position.
      VisitExpression();         // read condition.
      VisitStatement();          // read body.
      --depth_.loop_;
      return;
    case kDoStatement:
      ++depth_.loop_;
      builder_->ReadPosition();  // read position.
      VisitStatement();          // read body.
      VisitExpression();         // read condition.
      --depth_.loop_;
      return;
    case kForStatement: {
      PositionScope scope(builder_->reader_);

      intptr_t offset =
          builder_->ReaderOffset() - 1;  // -1 to include tag byte.

      ++depth_.loop_;
      EnterScope(offset);

      TokenPosition position = builder_->ReadPosition();  // read position.
      intptr_t list_length =
          builder_->ReadListLength();  // read number of variables.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitVariableDeclaration();  // read ith variable.
      }

      Tag tag = builder_->ReadTag();  // Read first part of condition.
      if (tag == kSomething) {
        VisitExpression();  // read rest of condition.
      }
      list_length = builder_->ReadListLength();  // read number of updates.
      for (intptr_t i = 0; i < list_length; ++i) {
        VisitExpression();  // read ith update.
      }
      VisitStatement();  // read body.

      ExitScope(position, builder_->reader_->max_position());
      --depth_.loop_;
      return;
    }
    case kForInStatement:
    case kAsyncForInStatement: {
      PositionScope scope(builder_->reader_);

      intptr_t start_offset =
          builder_->ReaderOffset() - 1;  // -1 to include tag byte.

      builder_->ReadPosition();  // read position.
      TokenPosition body_position =
          builder_->ReadPosition();  // read body position.

      // Notice the ordering: We skip the variable, read the iterable, go back,
      // re-read the variable, go forward to after having read the iterable.
      intptr_t offset = builder_->ReaderOffset();
      builder_->SkipVariableDeclaration();  // read variable.
      VisitExpression();                    // read iterable.

      ++depth_.for_in_;
      AddIteratorVariable();
      ++depth_.loop_;
      EnterScope(start_offset);

      {
        AlternativeReadingScope alt(builder_->reader_, offset);
        VisitVariableDeclaration();  // read variable.
      }
      VisitStatement();  // read body.

      if (!body_position.IsReal()) {
        body_position = builder_->reader_->min_position();
      }
      // TODO(jensj): From kernel_binary.cc
      // forinstmt->variable_->set_end_position(forinstmt->position_);
      ExitScope(body_position, builder_->reader_->max_position());
      --depth_.loop_;
      --depth_.for_in_;
      return;
    }
    case kSwitchStatement: {
      AddSwitchVariable();
      builder_->ReadPosition();                     // read position.
      VisitExpression();                            // read condition.
      int case_count = builder_->ReadListLength();  // read number of cases.
      for (intptr_t i = 0; i < case_count; ++i) {
        int expression_count =
            builder_->ReadListLength();  // read number of expressions.
        for (intptr_t j = 0; j < expression_count; ++j) {
          builder_->ReadPosition();  // read jth position.
          VisitExpression();         // read jth expression.
        }
        builder_->ReadBool();  // read is_default.
        VisitStatement();      // read body.
      }
      return;
    }
    case kContinueSwitchStatement:
      builder_->ReadPosition();  // read position.
      builder_->ReadUInt();      // read target_index.
      return;
    case kIfStatement:
      builder_->ReadPosition();  // read position.
      VisitExpression();         // read condition.
      VisitStatement();          // read then.
      VisitStatement();          // read otherwise.
      return;
    case kReturnStatement: {
      if ((depth_.function_ == 0) && (depth_.finally_ > 0) &&
          (result_->finally_return_variable == NULL)) {
        const String& name = H.DartSymbol(":try_finally_return_value");
        LocalVariable* variable =
            MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                         name, AbstractType::dynamic_type());
        current_function_scope_->AddVariable(variable);
        result_->finally_return_variable = variable;
      }

      builder_->ReadPosition();       // read position
      Tag tag = builder_->ReadTag();  // read (first part of) expression.
      if (tag == kSomething) {
        VisitExpression();  // read (rest of) expression.
      }
      return;
    }
    case kTryCatch: {
      ++depth_.try_;
      AddTryVariables();
      VisitStatement();  // read body.
      --depth_.try_;

      ++depth_.catch_;
      AddCatchVariables();

      builder_->ReadBool();  // read any_catch_needs_stack_trace.
      intptr_t catch_count =
          builder_->ReadListLength();  // read number of catches.
      for (intptr_t i = 0; i < catch_count; ++i) {
        PositionScope scope(builder_->reader_);
        intptr_t offset = builder_->ReaderOffset();  // Catch has no tag.

        EnterScope(offset);

        VisitDartType();            // Read the guard.
        tag = builder_->ReadTag();  // read first part of exception.
        if (tag == kSomething) {
          VisitVariableDeclaration();  // read exception.
        }
        tag = builder_->ReadTag();  // read first part of stack trace.
        if (tag == kSomething) {
          VisitVariableDeclaration();  // read stack trace.
        }
        VisitStatement();  // read body.

        ExitScope(builder_->reader_->min_position(),
                  builder_->reader_->max_position());
      }
      --depth_.catch_;
      return;
    }
    case kTryFinally: {
      ++depth_.try_;
      ++depth_.finally_;
      AddTryVariables();

      VisitStatement();  // read body.

      --depth_.finally_;
      --depth_.try_;
      ++depth_.catch_;
      AddCatchVariables();

      VisitStatement();  // read finalizer.

      --depth_.catch_;
      return;
    }
    case kYieldStatement: {
      builder_->ReadPosition();           // read position.
      word flags = builder_->ReadByte();  // read flags.
      builder_->SkipExpression();         // read expression.

      ASSERT(flags == kNativeYieldFlags);
      if (depth_.function_ == 0) {
        AddSwitchVariable();
        // Promote all currently visible local variables into the context.
        // TODO(27590) CaptureLocalVariables promotes to many variables into
        // the scope. Mark those variables as stack_local.
        // TODO(27590) we don't need to promote those variables that are
        // not used across yields.
        scope_->CaptureLocalVariables(current_function_scope_);
      }
      return;
    }
    case kVariableDeclaration:
      VisitVariableDeclaration();  // read variable declaration.
      return;
    case kFunctionDeclaration: {
      intptr_t offset =
          builder_->ReaderOffset() - 1;  // -1 to include tag byte.
      builder_->ReadPosition();          // read position.
      VisitVariableDeclaration();        // read variable declaration.
      HandleLocalFunction(offset);       // read function node.
      return;
    }
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }
}

void StreamingScopeBuilder::VisitArguments() {
  builder_->ReadUInt();  // read argument_count.

  // Types
  intptr_t list_length = builder_->ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    VisitDartType();  // read ith type.
  }

  // Positional.
  list_length = builder_->ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    VisitExpression();  // read ith positional.
  }

  // Named.
  list_length = builder_->ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    builder_->SkipStringReference();  // read ith name index.
    VisitExpression();                // read ith expression.
  }
}

void StreamingScopeBuilder::VisitVariableDeclaration() {
  PositionScope scope(builder_->reader_);

  intptr_t kernel_offset_no_tag = builder_->ReaderOffset();
  VariableDeclarationHelper helper(builder_);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
  intptr_t offset_for_type = builder_->ReaderOffset();
  AbstractType& type = T.BuildVariableType();  // read type.

  // In case `declaration->IsConst()` the flow graph building will take care of
  // evaluating the constant and setting it via
  // `declaration->SetConstantValue()`.
  const String& name = (H.StringSize(helper.name_index_) == 0)
                           ? GenerateName(":var", name_index_++)
                           : H.DartSymbol(helper.name_index_);
  // We also need to visit the type.
  builder_->SetOffset(offset_for_type);
  VisitDartType();  // read type.

  Tag tag = builder_->ReadTag();  // read (first part of) initializer.
  if (tag == kSomething) {
    VisitExpression();  // read (actual) initializer.
  }

  // Go to next token position so it ends *after* the last potentially
  // debuggable position in the initializer.
  TokenPosition end_position = builder_->reader_->max_position();
  if (end_position.IsReal()) {
    end_position.Next();
  }
  LocalVariable* variable =
      MakeVariable(helper.position_, end_position, name, type);
  if (helper.IsFinal()) {
    variable->set_is_final();
  }
  scope_->AddVariable(variable);
  result_->locals.Insert(builder_->data_program_offset_ + kernel_offset_no_tag,
                         variable);
}

void StreamingScopeBuilder::VisitDartType() {
  Tag tag = builder_->ReadTag();
  switch (tag) {
    case kInvalidType:
    case kDynamicType:
    case kVoidType:
    case kBottomType:
    case kVectorType:
      // those contain nothing.
      return;
    case kInterfaceType:
      VisitInterfaceType(false);
      return;
    case kSimpleInterfaceType:
      VisitInterfaceType(true);
      return;
    case kFunctionType:
      VisitFunctionType(false);
      return;
    case kSimpleFunctionType:
      VisitFunctionType(true);
      return;
    case kTypeParameterType:
      VisitTypeParameterType();
      return;
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }
}

void StreamingScopeBuilder::VisitInterfaceType(bool simple) {
  builder_->ReadUInt();  // read klass_name.
  if (!simple) {
    intptr_t length = builder_->ReadListLength();  // read number of types.
    for (intptr_t i = 0; i < length; ++i) {
      VisitDartType();  // read the ith type.
    }
  }
}

void StreamingScopeBuilder::VisitFunctionType(bool simple) {
  if (!simple) {
    intptr_t list_length =
        builder_->ReadListLength();  // read type_parameters list length.
    for (int i = 0; i < list_length; ++i) {
      builder_->SkipFlags();              // read flags.
      builder_->SkipListOfExpressions();  // read annotations.
      builder_->SkipStringReference();    // read string index (name).
      VisitDartType();                    // read dart type.
    }
    builder_->ReadUInt();  // read required parameter count.
    builder_->ReadUInt();  // read total parameter count.
  }

  const intptr_t positional_count =
      builder_->ReadListLength();  // read positional_parameters list length.
  for (intptr_t i = 0; i < positional_count; ++i) {
    VisitDartType();  // read ith positional parameter.
  }

  if (!simple) {
    const intptr_t named_count =
        builder_->ReadListLength();  // read named_parameters list length.
    for (intptr_t i = 0; i < named_count; ++i) {
      // read string reference (i.e. named_parameters[i].name).
      builder_->SkipStringReference();
      VisitDartType();  // read named_parameters[i].type.
    }
  }

  builder_->SkipListOfStrings();  // read positional parameter names.

  if (!simple) {
    builder_->SkipCanonicalNameReference();  // read typedef reference.
  }

  VisitDartType();  // read return type.
}

void StreamingScopeBuilder::VisitTypeParameterType() {
  Function& function = Function::Handle(Z, parsed_function_->function().raw());
  while (function.IsClosureFunction()) {
    function = function.parent_function();
  }

  // The index here is the index identifying the type parameter binding site
  // inside the DILL file, which uses a different indexing system than the VM
  // uses for its 'TypeParameter's internally. This index includes both class
  // and function type parameters.

  intptr_t index = builder_->ReadUInt();  // read index for parameter.

  if (function.IsFactory()) {
    // The type argument vector is passed as the very first argument to the
    // factory constructor function.
    HandleSpecialLoad(&result_->type_arguments_variable,
                      Symbols::TypeArgumentsParameter());
  } else {
    // If the type parameter is a parameter to this or an enclosing function, we
    // can read it directly from the function type arguments vector later.
    // Otherwise, the type arguments vector we need is stored on the instance
    // object, so we need to capture 'this'.
    Class& parent_class = Class::Handle(Z, function.Owner());
    if (index < parent_class.NumTypeParameters()) {
      HandleSpecialLoad(&result_->this_variable, Symbols::This());
    }
  }

  builder_->SkipOptionalDartType();  // read bound bound.
}

void StreamingScopeBuilder::HandleLocalFunction(intptr_t parent_kernel_offset) {
  // "Peek" ahead into the function node
  intptr_t offset = builder_->ReaderOffset();

  FunctionNodeHelper function_node_helper(builder_);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);

  LocalScope* saved_function_scope = current_function_scope_;
  FunctionNodeHelper::AsyncMarker saved_function_async_marker =
      current_function_async_marker_;
  DepthState saved_depth_state = depth_;
  depth_ = DepthState(depth_.function_ + 1);
  EnterScope(parent_kernel_offset);
  current_function_scope_ = scope_;
  current_function_async_marker_ = function_node_helper.async_marker_;
  if (depth_.function_ == 1) {
    FunctionScope function_scope = {offset, scope_};
    result_->function_scopes.Add(function_scope);
  }

  int num_type_params = 0;
  {
    AlternativeReadingScope _(builder_->reader_);
    num_type_params = builder_->ReadListLength();
  }
  // Adding this scope here informs the type translator the type parameters of
  // this function are now in scope, although they are not defined and will be
  // filled in with dynamic. This is OK, since their definitions are not needed
  // for scope building of the enclosing function.
  StreamingDartTypeTranslator::TypeParameterScope scope(&type_translator_,
                                                        num_type_params);

  // read positional_parameters and named_parameters.
  function_node_helper.ReadUntilExcluding(
      FunctionNodeHelper::kPositionalParameters);
  AddPositionalAndNamedParameters();

  // "Peek" is now done.
  builder_->SetOffset(offset);

  VisitFunctionNode();  // read function node.

  ExitScope(function_node_helper.position_, function_node_helper.end_position_);
  depth_ = saved_depth_state;
  current_function_scope_ = saved_function_scope;
  current_function_async_marker_ = saved_function_async_marker;
}

void StreamingScopeBuilder::EnterScope(intptr_t kernel_offset) {
  scope_ = new (Z) LocalScope(scope_, depth_.function_, depth_.loop_);
  ASSERT(kernel_offset >= 0);
  result_->scopes.Insert(kernel_offset, scope_);
}

void StreamingScopeBuilder::ExitScope(TokenPosition start_position,
                                      TokenPosition end_position) {
  scope_->set_begin_token_pos(start_position);
  scope_->set_end_token_pos(end_position);
  scope_ = scope_->parent();
}

void StreamingScopeBuilder::AddPositionalAndNamedParameters(intptr_t pos) {
  // List of positional.
  intptr_t list_length = builder_->ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    AddVariableDeclarationParameter(pos++);  // read ith positional parameter.
  }

  // List of named.
  list_length = builder_->ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    AddVariableDeclarationParameter(pos++);  // read ith named parameter.
  }
}

void StreamingScopeBuilder::AddVariableDeclarationParameter(intptr_t pos) {
  intptr_t kernel_offset = builder_->ReaderOffset();  // no tag.
  VariableDeclarationHelper helper(builder_);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
  String& name = H.DartSymbol(helper.name_index_);
  AbstractType& type = T.BuildVariableType();  // read type.
  helper.SetJustRead(VariableDeclarationHelper::kType);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);

  LocalVariable* variable =
      MakeVariable(helper.position_, helper.position_, name, type);
  if (helper.IsFinal()) {
    variable->set_is_final();
  }
  if (variable->name().raw() == Symbols::IteratorParameter().raw()) {
    variable->set_is_forced_stack();
  }
  scope_->InsertParameterAt(pos, variable);
  result_->locals.Insert(builder_->data_program_offset_ + kernel_offset,
                         variable);

  // The default value may contain 'let' bindings for which the constant
  // evaluator needs scope bindings.
  Tag tag = builder_->ReadTag();
  if (tag == kSomething) {
    VisitExpression();  // read initializer.
  }
}

LocalVariable* StreamingScopeBuilder::MakeVariable(
    TokenPosition declaration_pos,
    TokenPosition token_pos,
    const String& name,
    const AbstractType& type) {
  return new (Z) LocalVariable(declaration_pos, token_pos, name, type);
}

void StreamingScopeBuilder::AddExceptionVariable(
    GrowableArray<LocalVariable*>* variables,
    const char* prefix,
    intptr_t nesting_depth) {
  LocalVariable* v = NULL;

  // If we are inside a function with yield points then Kernel transformer
  // could have lifted some of the auxiliary exception variables into the
  // context to preserve them across yield points because they might
  // be needed for rethrow.
  // Check if it did and capture such variables instead of introducing
  // new local ones.
  // Note: function that wrap kSyncYielding function does not contain
  // its own try/catches.
  if (current_function_async_marker_ == FunctionNodeHelper::kSyncYielding) {
    ASSERT(current_function_scope_->parent() != NULL);
    v = current_function_scope_->parent()->LocalLookupVariable(
        GenerateName(prefix, nesting_depth - 1));
    if (v != NULL) {
      scope_->CaptureVariable(v);
    }
  }

  // No need to create variables for try/catch-statements inside
  // nested functions.
  if (depth_.function_ > 0) return;
  if (variables->length() >= nesting_depth) return;

  // If variable was not lifted by the transformer introduce a new
  // one into the current function scope.
  if (v == NULL) {
    v = MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                     GenerateName(prefix, nesting_depth - 1),
                     AbstractType::dynamic_type());

    // If transformer did not lift the variable then there is no need
    // to lift it into the context when we encouter a YieldStatement.
    v->set_is_forced_stack();
    current_function_scope_->AddVariable(v);
  }

  variables->Add(v);
}

void StreamingScopeBuilder::AddTryVariables() {
  AddExceptionVariable(&result_->catch_context_variables,
                       ":saved_try_context_var", depth_.try_);
}

void StreamingScopeBuilder::AddCatchVariables() {
  AddExceptionVariable(&result_->exception_variables, ":exception",
                       depth_.catch_);
  AddExceptionVariable(&result_->stack_trace_variables, ":stack_trace",
                       depth_.catch_);
}

void StreamingScopeBuilder::AddIteratorVariable() {
  if (depth_.function_ > 0) return;
  if (result_->iterator_variables.length() >= depth_.for_in_) return;

  ASSERT(result_->iterator_variables.length() == depth_.for_in_ - 1);
  LocalVariable* iterator =
      MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                   GenerateName(":iterator", depth_.for_in_ - 1),
                   AbstractType::dynamic_type());
  current_function_scope_->AddVariable(iterator);
  result_->iterator_variables.Add(iterator);
}

void StreamingScopeBuilder::AddSwitchVariable() {
  if ((depth_.function_ == 0) && (result_->switch_variable == NULL)) {
    LocalVariable* variable =
        MakeVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                     Symbols::SwitchExpr(), AbstractType::dynamic_type());
    variable->set_is_forced_stack();
    current_function_scope_->AddVariable(variable);
    result_->switch_variable = variable;
  }
}

void StreamingScopeBuilder::LookupVariable(intptr_t declaration_binary_offset) {
  LocalVariable* variable = result_->locals.Lookup(declaration_binary_offset);
  if (variable == NULL) {
    // We have not seen a declaration of the variable, so it must be the
    // case that we are compiling a nested function and the variable is
    // declared in an outer scope.  In that case, look it up in the scope by
    // name and add it to the variable map to simplify later lookup.
    ASSERT(current_function_scope_->parent() != NULL);
    StringIndex var_name = builder_->GetNameFromVariableDeclaration(
        declaration_binary_offset - builder_->data_program_offset_,
        parsed_function_->function());

    const String& name = H.DartSymbol(var_name);
    variable = current_function_scope_->parent()->LookupVariable(name, true);
    ASSERT(variable != NULL);
    result_->locals.Insert(declaration_binary_offset, variable);
  }

  if (variable->owner()->function_level() < scope_->function_level()) {
    // We call `LocalScope->CaptureVariable(variable)` in two scenarios for two
    // different reasons:
    //   Scenario 1:
    //       We need to know which variables defined in this function
    //       are closed over by nested closures in order to ensure we will
    //       create a [Context] object of appropriate size and store captured
    //       variables there instead of the stack.
    //   Scenario 2:
    //       We need to find out which variables defined in enclosing functions
    //       are closed over by this function/closure or nested closures. This
    //       is necessary in order to build a fat flattened [ContextScope]
    //       object.
    scope_->CaptureVariable(variable);
  } else {
    ASSERT(variable->owner()->function_level() == scope_->function_level());
  }
}

const String& StreamingScopeBuilder::GenerateName(const char* prefix,
                                                  intptr_t suffix) {
  char name[64];
  OS::SNPrint(name, 64, "%s%" Pd "", prefix, suffix);
  return H.DartSymbol(name);
}

void StreamingScopeBuilder::HandleSpecialLoad(LocalVariable** variable,
                                              const String& symbol) {
  if (current_function_scope_->parent() != NULL) {
    // We are building the scope tree of a closure function and saw [node]. We
    // lazily populate the variable using the parent function scope.
    if (*variable == NULL) {
      *variable =
          current_function_scope_->parent()->LookupVariable(symbol, true);
      ASSERT(*variable != NULL);
    }
  }

  if ((current_function_scope_->parent() != NULL) ||
      (scope_->function_level() > 0)) {
    // Every scope we use the [variable] from needs to be notified of the usage
    // in order to ensure that preserving the context scope on that particular
    // use-site also includes the [variable].
    scope_->CaptureVariable(*variable);
  }
}

void StreamingScopeBuilder::LookupCapturedVariableByName(
    LocalVariable** variable,
    const String& name) {
  if (*variable == NULL) {
    *variable = scope_->LookupVariable(name, true);
    ASSERT(*variable != NULL);
    scope_->CaptureVariable(*variable);
  }
}

StreamingDartTypeTranslator::StreamingDartTypeTranslator(
    StreamingFlowGraphBuilder* builder,
    bool finalize)
    : builder_(builder),
      translation_helper_(builder->translation_helper_),
      active_class_(builder->active_class()),
      type_parameter_scope_(NULL),
      zone_(translation_helper_.zone()),
      result_(AbstractType::Handle(translation_helper_.zone())),
      finalize_(finalize) {}

AbstractType& StreamingDartTypeTranslator::BuildType() {
  BuildTypeInternal();

  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return AbstractType::ZoneHandle(Z, result_.raw());
}

AbstractType& StreamingDartTypeTranslator::BuildTypeWithoutFinalization() {
  bool saved_finalize = finalize_;
  finalize_ = false;
  BuildTypeInternal();
  finalize_ = saved_finalize;

  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return AbstractType::ZoneHandle(Z, result_.raw());
}

AbstractType& StreamingDartTypeTranslator::BuildVariableType() {
  AbstractType& abstract_type = BuildType();

  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  AbstractType& type = Type::ZoneHandle(Z);

  if (abstract_type.IsMalformed()) {
    type = AbstractType::dynamic_type().raw();
  } else {
    type = result_.raw();
  }

  return type;
}

void StreamingDartTypeTranslator::BuildTypeInternal(bool invalid_as_dynamic) {
  Tag tag = builder_->ReadTag();
  switch (tag) {
    case kInvalidType:
      if (invalid_as_dynamic) {
        result_ = Object::dynamic_type().raw();
      } else {
        result_ = ClassFinalizer::NewFinalizedMalformedType(
            Error::Handle(Z),  // No previous error.
            Script::Handle(Z, Script::null()), TokenPosition::kNoSource,
            "[InvalidType] in Kernel IR.");
      }
      break;
    case kDynamicType:
      result_ = Object::dynamic_type().raw();
      break;
    case kVoidType:
      result_ = Object::void_type().raw();
      break;
    case kVectorType:
      result_ = Object::vector_type().raw();
      break;
    case kBottomType:
      result_ =
          Class::Handle(Z, I->object_store()->null_class()).CanonicalType();
      break;
    case kInterfaceType:
      BuildInterfaceType(false);
      break;
    case kSimpleInterfaceType:
      BuildInterfaceType(true);
      break;
    case kFunctionType:
      BuildFunctionType(false);
      break;
    case kSimpleFunctionType:
      BuildFunctionType(true);
      break;
    case kTypeParameterType:
      BuildTypeParameterType();
      break;
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }
}

void StreamingDartTypeTranslator::BuildInterfaceType(bool simple) {
  // NOTE: That an interface type like `T<A, B>` is considered to be
  // malformed iff `T` is malformed.
  //   => We therefore ignore errors in `A` or `B`.

  NameIndex klass_name =
      builder_->ReadCanonicalNameReference();  // read klass_name.

  intptr_t length;
  if (simple) {
    length = 0;
  } else {
    length = builder_->ReadListLength();  // read type_arguments list length.
  }
  const TypeArguments& type_arguments =
      BuildTypeArguments(length);  // read type arguments.

  Object& klass = Object::Handle(Z, H.LookupClassByKernelClass(klass_name));
  result_ = Type::New(klass, type_arguments, TokenPosition::kNoSource);
  if (finalize_) {
    ASSERT(active_class_->klass != NULL);
    result_ = ClassFinalizer::FinalizeType(*active_class_->klass, result_);
  }
}

void StreamingDartTypeTranslator::BuildFunctionType(bool simple) {
  Function& signature_function = Function::ZoneHandle(
      Z, Function::NewSignatureFunction(*active_class_->klass,
                                        active_class_->enclosing != NULL
                                            ? *active_class_->enclosing
                                            : Function::Handle(Z),
                                        TokenPosition::kNoSource));

  // Suspend finalization of types inside this one. They will be finalized after
  // the whole function type is constructed.
  //
  // TODO(31213): Test further when nested generic function types
  // are supported by fasta.
  bool finalize = finalize_;
  finalize_ = false;

  if (!simple) {
    builder_->LoadAndSetupTypeParameters(active_class_, signature_function,
                                         builder_->ReadListLength(),
                                         signature_function);
  }

  ActiveTypeParametersScope scope(
      active_class_, &signature_function,
      TypeArguments::Handle(Z, signature_function.type_parameters()), Z);

  intptr_t required_count;
  intptr_t all_count;
  intptr_t positional_count;
  if (!simple) {
    required_count = builder_->ReadUInt();  // read required parameter count.
    all_count = builder_->ReadUInt();       // read total parameter count.
    positional_count =
        builder_->ReadListLength();  // read positional_parameters list length.
  } else {
    positional_count =
        builder_->ReadListLength();  // read positional_parameters list length.
    required_count = positional_count;
    all_count = positional_count;
  }

  const Array& parameter_types =
      Array::Handle(Z, Array::New(1 + all_count, Heap::kOld));
  signature_function.set_parameter_types(parameter_types);
  const Array& parameter_names =
      Array::Handle(Z, Array::New(1 + all_count, Heap::kOld));
  signature_function.set_parameter_names(parameter_names);

  intptr_t pos = 0;
  parameter_types.SetAt(pos, AbstractType::dynamic_type());
  parameter_names.SetAt(pos, H.DartSymbol("_receiver_"));
  ++pos;
  for (intptr_t i = 0; i < positional_count; ++i, ++pos) {
    BuildTypeInternal();  // read ith positional parameter.
    if (result_.IsMalformed()) {
      result_ = AbstractType::dynamic_type().raw();
    }
    parameter_types.SetAt(pos, result_);
    parameter_names.SetAt(pos, H.DartSymbol("noname"));
  }

  // The additional first parameter is the receiver type (set to dynamic).
  signature_function.set_num_fixed_parameters(1 + required_count);
  signature_function.SetNumOptionalParameters(
      all_count - required_count, positional_count > required_count);

  if (!simple) {
    const intptr_t named_count =
        builder_->ReadListLength();  // read named_parameters list length.
    for (intptr_t i = 0; i < named_count; ++i, ++pos) {
      // read string reference (i.e. named_parameters[i].name).
      String& name = H.DartSymbol(builder_->ReadStringReference());
      BuildTypeInternal();  // read named_parameters[i].type.
      if (result_.IsMalformed()) {
        result_ = AbstractType::dynamic_type().raw();
      }
      parameter_types.SetAt(pos, result_);
      parameter_names.SetAt(pos, name);
    }
  }

  builder_->SkipListOfStrings();  // read positional parameter names.

  if (!simple) {
    builder_->SkipCanonicalNameReference();  // read typedef reference.
  }

  BuildTypeInternal();  // read return type.
  if (result_.IsMalformed()) {
    result_ = AbstractType::dynamic_type().raw();
  }
  signature_function.set_result_type(result_);

  finalize_ = finalize;

  Type& signature_type =
      Type::ZoneHandle(Z, signature_function.SignatureType());

  if (finalize_) {
    signature_type ^=
        ClassFinalizer::FinalizeType(*active_class_->klass, signature_type);
    // Do not refer to signature_function anymore, since it may have been
    // replaced during canonicalization.
    signature_function = Function::null();
  }

  result_ = signature_type.raw();
}

void StreamingDartTypeTranslator::BuildTypeParameterType() {
  intptr_t parameter_index = builder_->ReadUInt();  // read parameter index.
  builder_->SkipOptionalDartType();                 // read bound.

  const TypeArguments& class_types =
      TypeArguments::Handle(Z, active_class_->klass->type_parameters());
  if (parameter_index < class_types.Length()) {
    // The index of the type parameter in [parameters] is
    // the same index into the `klass->type_parameters()` array.
    result_ ^= class_types.TypeAt(parameter_index);
    return;
  }
  parameter_index -= class_types.Length();

  if (active_class_->HasMember()) {
    if (active_class_->MemberIsFactoryProcedure()) {
      //
      // WARNING: This is a little hackish:
      //
      // We have a static factory constructor. The kernel IR gives the factory
      // constructor function its own type parameters (which are equal in name
      // and number to the ones of the enclosing class). I.e.,
      //
      //   class A<T> {
      //     factory A.x() { return new B<T>(); }
      //   }
      //
      //  is basically translated to this:
      //
      //   class A<T> {
      //     static A.x<T'>() { return new B<T'>(); }
      //   }
      //
      if (class_types.Length() > parameter_index) {
        result_ ^= class_types.TypeAt(parameter_index);
        return;
      }
      parameter_index -= class_types.Length();
    }

    intptr_t procedure_type_parameter_count =
        active_class_->MemberIsProcedure()
            ? active_class_->MemberTypeParameterCount(Z)
            : 0;
    if (procedure_type_parameter_count > 0) {
      if (procedure_type_parameter_count > parameter_index) {
        if (I->reify_generic_functions()) {
          result_ ^=
              TypeArguments::Handle(Z, active_class_->member->type_parameters())
                  .TypeAt(parameter_index);
        } else {
          result_ ^= Type::DynamicType();
        }
        return;
      }
      parameter_index -= procedure_type_parameter_count;
    }
  }

  if (active_class_->local_type_parameters != NULL) {
    if (parameter_index < active_class_->local_type_parameters->Length()) {
      if (I->reify_generic_functions()) {
        result_ ^=
            active_class_->local_type_parameters->TypeAt(parameter_index);
      } else {
        result_ ^= Type::DynamicType();
      }
      return;
    }
    parameter_index -= active_class_->local_type_parameters->Length();
  }

  if (type_parameter_scope_ != NULL &&
      parameter_index < type_parameter_scope_->outer_parameter_count() +
                            type_parameter_scope_->parameter_count()) {
    result_ ^= Type::DynamicType();
    return;
  }

  H.ReportError("Unexpected input. Please report this at dartbug.com.");
}

const TypeArguments& StreamingDartTypeTranslator::BuildTypeArguments(
    intptr_t length) {
  bool only_dynamic = true;
  intptr_t offset = builder_->ReaderOffset();
  for (intptr_t i = 0; i < length; ++i) {
    if (builder_->ReadTag() != kDynamicType) {  // Read the ith types tag.
      only_dynamic = false;
      builder_->SetOffset(offset);
      break;
    }
  }
  TypeArguments& type_arguments = TypeArguments::ZoneHandle(Z);
  if (!only_dynamic) {
    type_arguments = TypeArguments::New(length);
    for (intptr_t i = 0; i < length; ++i) {
      BuildTypeInternal(true);  // read ith type.
      type_arguments.SetTypeAt(i, result_);
    }

    if (finalize_) {
      type_arguments = type_arguments.Canonicalize();
    }
  }
  return type_arguments;
}

const TypeArguments&
StreamingDartTypeTranslator::BuildInstantiatedTypeArguments(
    const Class& receiver_class,
    intptr_t length) {
  const TypeArguments& type_arguments = BuildTypeArguments(length);

  // If type_arguments is null all arguments are dynamic.
  // If, however, this class doesn't specify all the type arguments directly we
  // still need to finalize the type below in order to get any non-dynamic types
  // from any super. See http://www.dartbug.com/29537.
  if (type_arguments.IsNull() && receiver_class.NumTypeArguments() == length) {
    return type_arguments;
  }

  // We make a temporary [Type] object and use `ClassFinalizer::FinalizeType` to
  // finalize the argument types.
  // (This can for example make the [type_arguments] vector larger)
  Type& type = Type::Handle(
      Z, Type::New(receiver_class, type_arguments, TokenPosition::kNoSource));
  if (finalize_) {
    type ^= ClassFinalizer::FinalizeType(*active_class_->klass, type);
  }

  const TypeArguments& instantiated_type_arguments =
      TypeArguments::ZoneHandle(Z, type.arguments());
  return instantiated_type_arguments;
}

const Type& StreamingDartTypeTranslator::ReceiverType(const Class& klass) {
  ASSERT(!klass.IsNull());
  ASSERT(!klass.IsTypedefClass());
  // Note that if klass is _Closure, the returned type will be _Closure,
  // and not the signature type.
  Type& type = Type::ZoneHandle(Z, klass.CanonicalType());
  if (!type.IsNull()) {
    return type;
  }
  type = Type::New(klass, TypeArguments::Handle(Z, klass.type_parameters()),
                   klass.token_pos());
  if (klass.is_type_finalized()) {
    type ^= ClassFinalizer::FinalizeType(klass, type);
    klass.SetCanonicalType(type);
  }
  return type;
}

StreamingConstantEvaluator::StreamingConstantEvaluator(
    StreamingFlowGraphBuilder* builder)
    : builder_(builder),
      isolate_(Isolate::Current()),
      zone_(builder_->zone_),
      translation_helper_(builder_->translation_helper_),
      type_translator_(builder_->type_translator_),
      script_(Script::Handle(zone_, builder_->Script())),
      result_(Instance::Handle(zone_)) {}

bool StreamingConstantEvaluator::IsCached(intptr_t offset) {
  return GetCachedConstant(offset, &result_);
}

Instance& StreamingConstantEvaluator::EvaluateExpression(intptr_t offset,
                                                         bool reset_position) {
  if (!GetCachedConstant(offset, &result_)) {
    ASSERT(IsAllowedToEvaluate());
    intptr_t original_offset = builder_->ReaderOffset();
    builder_->SetOffset(offset);
    uint8_t payload = 0;
    Tag tag = builder_->ReadTag(&payload);  // read tag.
    switch (tag) {
      case kVariableGet:
        EvaluateVariableGet();
        break;
      case kSpecializedVariableGet:
        EvaluateVariableGet(payload);
        break;
      case kPropertyGet:
        EvaluatePropertyGet();
        break;
      case kDirectPropertyGet:
        EvaluateDirectPropertyGet();
        break;
      case kStaticGet:
        EvaluateStaticGet();
        break;
      case kMethodInvocation:
        EvaluateMethodInvocation();
        break;
      case kDirectMethodInvocation:
        EvaluateDirectMethodInvocation();
        break;
      case kSuperMethodInvocation:
        EvaluateSuperMethodInvocation();
        break;
      case kStaticInvocation:
      case kConstStaticInvocation:
        EvaluateStaticInvocation();
        break;
      case kConstructorInvocation:
      case kConstConstructorInvocation:
        EvaluateConstructorInvocationInternal();
        break;
      case kNot:
        EvaluateNot();
        break;
      case kLogicalExpression:
        EvaluateLogicalExpression();
        break;
      case kConditionalExpression:
        EvaluateConditionalExpression();
        break;
      case kStringConcatenation:
        EvaluateStringConcatenation();
        break;
      case kSymbolLiteral:
        EvaluateSymbolLiteral();
        break;
      case kTypeLiteral:
        EvaluateTypeLiteral();
        break;
      case kListLiteral:
      case kConstListLiteral:
        EvaluateListLiteralInternal();
        break;
      case kMapLiteral:
      case kConstMapLiteral:
        EvaluateMapLiteralInternal();
        break;
      case kLet:
        EvaluateLet();
        break;
      case kBigIntLiteral:
        EvaluateBigIntLiteral();
        break;
      case kStringLiteral:
        EvaluateStringLiteral();
        break;
      case kSpecialIntLiteral:
        EvaluateIntLiteral(payload);
        break;
      case kNegativeIntLiteral:
        EvaluateIntLiteral(true);
        break;
      case kPositiveIntLiteral:
        EvaluateIntLiteral(false);
        break;
      case kDoubleLiteral:
        EvaluateDoubleLiteral();
        break;
      case kTrueLiteral:
        EvaluateBoolLiteral(true);
        break;
      case kFalseLiteral:
        EvaluateBoolLiteral(false);
        break;
      case kNullLiteral:
        EvaluateNullLiteral();
        break;
      default:
        H.ReportError(script_, TokenPosition::kNoSource,
                      "Not a constant expression.");
    }

    CacheConstantValue(offset, result_);
    if (reset_position) builder_->SetOffset(original_offset);
  } else {
    if (!reset_position) {
      builder_->SetOffset(offset);
      builder_->SkipExpression();
    }
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}

Instance& StreamingConstantEvaluator::EvaluateListLiteral(intptr_t offset,
                                                          bool reset_position) {
  if (!GetCachedConstant(offset, &result_)) {
    ASSERT(IsAllowedToEvaluate());
    intptr_t original_offset = builder_->ReaderOffset();
    builder_->SetOffset(offset);
    builder_->ReadTag();  // skip tag.
    EvaluateListLiteralInternal();

    CacheConstantValue(offset, result_);
    if (reset_position) builder_->SetOffset(original_offset);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}

Instance& StreamingConstantEvaluator::EvaluateMapLiteral(intptr_t offset,
                                                         bool reset_position) {
  if (!GetCachedConstant(offset, &result_)) {
    ASSERT(IsAllowedToEvaluate());
    intptr_t original_offset = builder_->ReaderOffset();
    builder_->SetOffset(offset);
    builder_->ReadTag();  // skip tag.
    EvaluateMapLiteralInternal();

    CacheConstantValue(offset, result_);
    if (reset_position) builder_->SetOffset(original_offset);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}

Instance& StreamingConstantEvaluator::EvaluateConstructorInvocation(
    intptr_t offset,
    bool reset_position) {
  if (!GetCachedConstant(offset, &result_)) {
    ASSERT(IsAllowedToEvaluate());
    intptr_t original_offset = builder_->ReaderOffset();
    builder_->SetOffset(offset);
    builder_->ReadTag();  // skip tag.
    EvaluateConstructorInvocationInternal();

    CacheConstantValue(offset, result_);
    if (reset_position) builder_->SetOffset(original_offset);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}

Object& StreamingConstantEvaluator::EvaluateExpressionSafe(intptr_t offset) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    return EvaluateExpression(offset);
  } else {
    Thread* thread = H.thread();
    Error& error = Error::Handle(Z);
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error;
  }
}

bool StreamingConstantEvaluator::IsAllowedToEvaluate() {
  return FLAG_precompiled_mode || builder_->flow_graph_builder_ == NULL ||
         !builder_->optimizing();
}

void StreamingConstantEvaluator::EvaluateVariableGet() {
  // When we see a [VariableGet] the corresponding [VariableDeclaration] must've
  // been executed already. It therefore must have a constant object associated
  // with it.
  builder_->ReadPosition();  // read position.
  intptr_t variable_kernel_position =
      builder_->ReadUInt();          // read kernel position.
  builder_->ReadUInt();              // read relative variable index.
  builder_->SkipOptionalDartType();  // read promoted type.
  LocalVariable* variable = builder_->LookupVariable(variable_kernel_position);
  ASSERT(variable->IsConst());
  result_ = variable->ConstValue()->raw();
}

void StreamingConstantEvaluator::EvaluateVariableGet(uint8_t payload) {
  // When we see a [VariableGet] the corresponding [VariableDeclaration] must've
  // been executed already. It therefore must have a constant object associated
  // with it.
  builder_->ReadPosition();  // read position.
  intptr_t variable_kernel_position =
      builder_->ReadUInt();  // read kernel position.
  LocalVariable* variable = builder_->LookupVariable(variable_kernel_position);
  ASSERT(variable->IsConst());
  result_ = variable->ConstValue()->raw();
}

void StreamingConstantEvaluator::EvaluateGetStringLength(
    intptr_t expression_offset,
    TokenPosition position) {
  EvaluateExpression(expression_offset);
  if (result_.IsString()) {
    const String& str = String::Handle(Z, String::RawCast(result_.raw()));
    result_ = Integer::New(str.Length());
  } else {
    H.ReportError(
        script_, position,
        "Constant expressions can only call 'length' on string constants.");
  }
}

void StreamingConstantEvaluator::EvaluatePropertyGet() {
  TokenPosition position = builder_->ReadPosition();  // read position.
  builder_->ReadFlags();     // read flags.
  intptr_t expression_offset = builder_->ReaderOffset();
  builder_->SkipExpression();                            // read receiver.
  StringIndex name = builder_->ReadNameAsStringIndex();  // read name.
  builder_->SkipCanonicalNameReference();  // read interface_target_reference.

  if (H.StringEquals(name, "length")) {
    EvaluateGetStringLength(expression_offset, position);
  } else {
    H.ReportError(
        script_, position,
        "Constant expressions can only call 'length' on string constants.");
  }
}

void StreamingConstantEvaluator::EvaluateDirectPropertyGet() {
  TokenPosition position = builder_->ReadPosition();  // read position.
  builder_->ReadFlags();     // read flags.
  intptr_t expression_offset = builder_->ReaderOffset();
  builder_->SkipExpression();  // read receiver.
  NameIndex kernel_name =
      builder_->ReadCanonicalNameReference();  // read target_reference.

  // TODO(vegorov): add check based on the complete canonical name.
  if (H.IsGetter(kernel_name) &&
      H.StringEquals(H.CanonicalNameString(kernel_name), "length")) {
    EvaluateGetStringLength(expression_offset, position);
  } else {
    H.ReportError(
        script_, position,
        "Constant expressions can only call 'length' on string constants.");
  }
}

void StreamingConstantEvaluator::EvaluateStaticGet() {
  TokenPosition position = builder_->ReadPosition();  // read position.
  NameIndex target =
      builder_->ReadCanonicalNameReference();  // read target_reference.

  if (H.IsField(target)) {
    const Field& field = Field::Handle(Z, H.LookupFieldByKernelField(target));
    if (!field.is_const()) {
      H.ReportError(script_, position, "Not a constant field.");
    }
    if (field.StaticValue() == Object::transition_sentinel().raw()) {
      H.ReportError(script_, position, "Not a constant expression.");
    } else if (field.StaticValue() == Object::sentinel().raw()) {
      field.SetStaticValue(Object::transition_sentinel());
      const Object& value =
          Object::Handle(Compiler::EvaluateStaticInitializer(field));
      if (value.IsError()) {
        field.SetStaticValue(Object::null_instance());
        H.ReportError(Error::Cast(value), script_, position,
                      "Not a constant expression.");
        UNREACHABLE();
      }
      Thread* thread = H.thread();
      const Error& error =
          Error::Handle(thread->zone(), thread->sticky_error());
      if (!error.IsNull()) {
        field.SetStaticValue(Object::null_instance());
        thread->clear_sticky_error();
        H.ReportError(error, script_, position, "Not a constant expression.");
        UNREACHABLE();
      }
      ASSERT(value.IsNull() || value.IsInstance());
      field.SetStaticValue(value.IsNull() ? Instance::null_instance()
                                          : Instance::Cast(value));

      result_ = field.StaticValue();
      result_ = H.Canonicalize(result_);
      field.SetStaticValue(result_, true);
    } else {
      result_ = field.StaticValue();
    }
  } else if (H.IsProcedure(target)) {
    const Function& function =
        Function::ZoneHandle(Z, H.LookupStaticMethodByKernelProcedure(target));

    if (H.IsMethod(target)) {
      Function& closure_function =
          Function::ZoneHandle(Z, function.ImplicitClosureFunction());
      result_ = closure_function.ImplicitStaticClosure();
      result_ = H.Canonicalize(result_);
    } else if (H.IsGetter(target)) {
      H.ReportError(script_, position, "Not a constant expression.");
    } else {
      H.ReportError(script_, position, "Not a constant expression.");
    }
  }
}

void StreamingConstantEvaluator::EvaluateMethodInvocation() {
  builder_->ReadPosition();  // read position.
  builder_->ReadFlags();     // read flags.
  // This method call wasn't cached, so receiver et al. isn't cached either.
  const Instance& receiver =
      EvaluateExpression(builder_->ReaderOffset(), false);  // read receiver.
  Class& klass =
      Class::Handle(Z, isolate_->class_table()->At(receiver.GetClassId()));
  ASSERT(!klass.IsNull());

  // Search the superclass chain for the selector.
  const String& method_name = builder_->ReadNameAsMethodName();  // read name.
  Function& function =
      builder_->FindMatchingFunctionAnyArgs(klass, method_name);

  // The frontend should guarantee that [MethodInvocation]s inside constant
  // expressions are always valid.
  ASSERT(!function.IsNull());

  // Read arguments, run the method and canonicalize the result.
  const Object& result = RunMethodCall(function, &receiver);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);

  builder_->SkipCanonicalNameReference();  // read interface_target_reference.
}

void StreamingConstantEvaluator::EvaluateDirectMethodInvocation() {
  builder_->ReadPosition();  // read position.
  builder_->ReadFlags();  // read flags.

  const Instance& receiver =
      EvaluateExpression(builder_->ReaderOffset(), false);  // read receiver.

  NameIndex kernel_name =
      builder_->ReadCanonicalNameReference();  // read target_reference.

  const Function& function = Function::ZoneHandle(
      Z, builder_->LookupMethodByMember(kernel_name,
                                        H.DartProcedureName(kernel_name)));

  // Read arguments, run the method and canonicalize the result.
  const Object& result = RunMethodCall(function, &receiver);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);
}

Class& StreamingFlowGraphBuilder::GetSuperOrDie() {
  Class& klass = Class::Handle(Z, parsed_function()->function().Owner());
  ASSERT(!klass.IsNull());
  klass = klass.SuperClass();
  ASSERT(!klass.IsNull());
  return klass;
}

void StreamingConstantEvaluator::EvaluateSuperMethodInvocation() {
  builder_->ReadPosition();  // read position.

  const LocalVariable* this_variable = builder_->scopes()->this_variable;
  ASSERT(this_variable->IsConst());
  const Instance& receiver =
      Instance::Handle(Z, this_variable->ConstValue()->raw());
  ASSERT(!receiver.IsNull());

  Class& klass = builder_->GetSuperOrDie();

  const String& method_name = builder_->ReadNameAsMethodName();  // read name.
  Function& function =
      builder_->FindMatchingFunctionAnyArgs(klass, method_name);

  // The frontend should guarantee that [MethodInvocation]s inside constant
  // expressions are always valid.
  ASSERT(!function.IsNull());

  // Read arguments, run the method and canonicalize the result.
  const Object& result = RunMethodCall(function, &receiver);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);

  builder_->SkipCanonicalNameReference();  // read interface_target_reference.
}

void StreamingConstantEvaluator::EvaluateStaticInvocation() {
  builder_->ReadPosition();  // read position.
  NameIndex procedure_reference =
      builder_->ReadCanonicalNameReference();  // read procedure reference.

  const Function& function = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(procedure_reference));
  Class& klass = Class::Handle(Z, function.Owner());

  intptr_t argument_count =
      builder_->ReadUInt();  // read arguments part #1: arguments count.

  // Build the type arguments vector (if necessary).
  const TypeArguments* type_arguments =
      TranslateTypeArguments(function, &klass);  // read argument types.

  // read positional and named parameters.
  const Object& result =
      RunFunction(function, argument_count, NULL, type_arguments);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);
}

void StreamingConstantEvaluator::EvaluateConstructorInvocationInternal() {
  builder_->ReadPosition();  // read position.

  NameIndex target = builder_->ReadCanonicalNameReference();  // read target.
  const Function& constructor =
      Function::Handle(Z, H.LookupConstructorByKernelConstructor(target));
  Class& klass = Class::Handle(Z, constructor.Owner());

  intptr_t argument_count =
      builder_->ReadUInt();  // read arguments part #1: arguments count.

  // Build the type arguments vector (if necessary).
  const TypeArguments* type_arguments =
      TranslateTypeArguments(constructor, &klass);  // read argument types.

  if (klass.NumTypeArguments() > 0 && !klass.IsGeneric()) {
    Type& type = Type::ZoneHandle(Z, T.ReceiverType(klass).raw());
    // TODO(27590): Can we move this code into [ReceiverType]?
    type ^= ClassFinalizer::FinalizeType(*builder_->active_class()->klass, type,
                                         ClassFinalizer::kFinalize);
    ASSERT(!type.IsMalformedOrMalbounded());

    TypeArguments& canonicalized_type_arguments =
        TypeArguments::ZoneHandle(Z, type.arguments());
    canonicalized_type_arguments = canonicalized_type_arguments.Canonicalize();
    type_arguments = &canonicalized_type_arguments;
  }

  // Prepare either the instance or the type argument vector for the constructor
  // call.
  Instance* receiver = NULL;
  const TypeArguments* type_arguments_argument = NULL;
  if (!constructor.IsFactory()) {
    receiver = &Instance::ZoneHandle(Z, Instance::New(klass, Heap::kOld));
    if (type_arguments != NULL) {
      receiver->SetTypeArguments(*type_arguments);
    }
  } else {
    type_arguments_argument = type_arguments;
  }

  // read positional and named parameters.
  const Object& result = RunFunction(constructor, argument_count, receiver,
                                     type_arguments_argument);

  if (constructor.IsFactory()) {
    // Factories return the new object.
    result_ ^= result.raw();
    result_ = H.Canonicalize(result_);
  } else {
    ASSERT(!receiver->IsNull());
    result_ = H.Canonicalize(*receiver);
  }
}

void StreamingConstantEvaluator::EvaluateNot() {
  result_ ^= Bool::Get(!EvaluateBooleanExpressionHere()).raw();
}

void StreamingConstantEvaluator::EvaluateLogicalExpression() {
  bool left = EvaluateBooleanExpressionHere();  // read left.
  LogicalOperator op = static_cast<LogicalOperator>(builder_->ReadByte());
  if (op == kAnd) {
    if (left) {
      EvaluateBooleanExpressionHere();  // read right.
    } else {
      builder_->SkipExpression();  // read right.
    }
  } else {
    ASSERT(op == kOr);
    if (!left) {
      EvaluateBooleanExpressionHere();  // read right.
    } else {
      builder_->SkipExpression();  // read right.
    }
  }
}

void StreamingConstantEvaluator::EvaluateConditionalExpression() {
  bool condition = EvaluateBooleanExpressionHere();
  if (condition) {
    EvaluateExpression(builder_->ReaderOffset(), false);  // read then.
    builder_->SkipExpression();                           // read otherwise.
  } else {
    builder_->SkipExpression();                           // read then.
    EvaluateExpression(builder_->ReaderOffset(), false);  // read otherwise.
  }
  builder_->SkipOptionalDartType();  // read unused static type.
}

void StreamingConstantEvaluator::EvaluateStringConcatenation() {
  builder_->ReadPosition();                      // read position.
  intptr_t length = builder_->ReadListLength();  // read list length.

  bool all_string = true;
  const Array& strings = Array::Handle(Z, Array::New(length));
  for (intptr_t i = 0; i < length; ++i) {
    EvaluateExpression(builder_->ReaderOffset(),
                       false);  // read ith expression.
    strings.SetAt(i, result_);
    all_string = all_string && result_.IsString();
  }
  if (all_string) {
    result_ = String::ConcatAll(strings, Heap::kOld);
    result_ = H.Canonicalize(result_);
  } else {
    // Get string interpolation function.
    const Class& cls =
        Class::Handle(Z, Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    const Function& func = Function::Handle(
        Z, cls.LookupStaticFunction(
               Library::PrivateCoreLibName(Symbols::Interpolate())));
    ASSERT(!func.IsNull());

    // Build argument array to pass to the interpolation function.
    const Array& interpolate_arg = Array::Handle(Z, Array::New(1, Heap::kOld));
    interpolate_arg.SetAt(0, strings);

    // Run and canonicalize.
    const Object& result =
        RunFunction(func, interpolate_arg, Array::null_array());
    result_ = H.Canonicalize(String::Cast(result));
  }
}

void StreamingConstantEvaluator::EvaluateSymbolLiteral() {
  const String& symbol_value = H.DartSymbol(
      builder_->ReadStringReference());  // read index into string table.

  const Class& symbol_class =
      Class::ZoneHandle(Z, I->object_store()->symbol_class());
  ASSERT(!symbol_class.IsNull());
  const Function& symbol_constructor = Function::ZoneHandle(
      Z, symbol_class.LookupConstructor(Symbols::SymbolCtor()));
  ASSERT(!symbol_constructor.IsNull());
  result_ ^= EvaluateConstConstructorCall(
      symbol_class, TypeArguments::Handle(Z), symbol_constructor, symbol_value);
}

void StreamingConstantEvaluator::EvaluateTypeLiteral() {
  const AbstractType& type = T.BuildType();
  if (type.IsMalformed()) {
    H.ReportError(script_, TokenPosition::kNoSource,
                  "Malformed type literal in constant expression.");
  }
  result_ = type.raw();
}

void StreamingConstantEvaluator::EvaluateListLiteralInternal() {
  builder_->ReadPosition();  // read position.
  const TypeArguments& type_arguments = T.BuildTypeArguments(1);  // read type.
  intptr_t length = builder_->ReadListLength();  // read list length.
  const Array& const_list =
      Array::ZoneHandle(Z, Array::New(length, Heap::kOld));
  const_list.SetTypeArguments(type_arguments);
  for (intptr_t i = 0; i < length; ++i) {
    const Instance& expression = EvaluateExpression(
        builder_->ReaderOffset(), false);  // read ith expression.
    const_list.SetAt(i, expression);
  }
  const_list.MakeImmutable();
  result_ = H.Canonicalize(const_list);
}

void StreamingConstantEvaluator::EvaluateMapLiteralInternal() {
  builder_->ReadPosition();  // read position.
  const TypeArguments& type_arguments =
      T.BuildTypeArguments(2);  // read key type and value type.

  intptr_t length = builder_->ReadListLength();  // read length of entries.

  // This MapLiteral wasn't cached, so content isn't cached either.
  Array& const_kv_array =
      Array::ZoneHandle(Z, Array::New(2 * length, Heap::kOld));
  for (intptr_t i = 0; i < length; ++i) {
    const_kv_array.SetAt(2 * i + 0, EvaluateExpression(builder_->ReaderOffset(),
                                                       false));  // read key.
    const_kv_array.SetAt(2 * i + 1, EvaluateExpression(builder_->ReaderOffset(),
                                                       false));  // read value.
  }

  const_kv_array.MakeImmutable();
  const_kv_array ^= H.Canonicalize(const_kv_array);

  const Class& map_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::ImmutableMap()));
  ASSERT(!map_class.IsNull());
  ASSERT(map_class.NumTypeArguments() == 2);

  const Field& field = Field::Handle(
      Z, map_class.LookupInstanceFieldAllowPrivate(H.DartSymbol("_kvPairs")));
  ASSERT(!field.IsNull());

  // NOTE: This needs to be kept in sync with `runtime/lib/immutable_map.dart`!
  result_ = Instance::New(map_class, Heap::kOld);
  ASSERT(!result_.IsNull());
  result_.SetTypeArguments(type_arguments);
  result_.SetField(field, const_kv_array);
  result_ = H.Canonicalize(result_);
}

void StreamingConstantEvaluator::EvaluateLet() {
  intptr_t kernel_position =
      builder_->ReaderOffset() + builder_->data_program_offset_;
  LocalVariable* local = builder_->LookupVariable(kernel_position);

  // read variable declaration.
  VariableDeclarationHelper helper(builder_);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);
  Tag tag = builder_->ReadTag();  // read (first part of) initializer.
  if (tag == kNothing) {
    local->SetConstValue(Instance::ZoneHandle(Z, Instance::null()));
  } else {
    local->SetConstValue(EvaluateExpression(
        builder_->ReaderOffset(), false));  // read rest of initializer.
  }

  EvaluateExpression(builder_->ReaderOffset(), false);  // read body
}

void StreamingConstantEvaluator::EvaluateBigIntLiteral() {
  const String& value =
      H.DartString(builder_->ReadStringReference());  // read string reference.
  result_ = Integer::New(value, Heap::kOld);
  if (result_.IsNull()) {
    H.ReportError(script_, TokenPosition::kNoSource,
                  "Integer literal %s is out of range", value.ToCString());
  }
  result_ = H.Canonicalize(result_);
}

void StreamingConstantEvaluator::EvaluateStringLiteral() {
  result_ = H.DartSymbol(builder_->ReadStringReference())
                .raw();  // read string reference.
}

void StreamingConstantEvaluator::EvaluateIntLiteral(uint8_t payload) {
  int64_t value = static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
  result_ = Integer::New(value, Heap::kOld);
  result_ = H.Canonicalize(result_);
}

void StreamingConstantEvaluator::EvaluateIntLiteral(bool is_negative) {
  int64_t value = is_negative ? -static_cast<int64_t>(builder_->ReadUInt())
                              : builder_->ReadUInt();  // read value.
  result_ = Integer::New(value, Heap::kOld);
  result_ = H.Canonicalize(result_);
}

void StreamingConstantEvaluator::EvaluateDoubleLiteral() {
  result_ = Double::New(H.DartString(builder_->ReadStringReference()),
                        Heap::kOld);  // read string reference.
  result_ = H.Canonicalize(result_);
}

void StreamingConstantEvaluator::EvaluateBoolLiteral(bool value) {
  result_ = Bool::Get(value).raw();
}

void StreamingConstantEvaluator::EvaluateNullLiteral() {
  result_ = Instance::null();
}

// This depends on being about to read the list of positionals on arguments.
const Object& StreamingConstantEvaluator::RunFunction(
    const Function& function,
    intptr_t argument_count,
    const Instance* receiver,
    const TypeArguments* type_args) {
  // We do not support generic methods yet.
  ASSERT((receiver == NULL) || (type_args == NULL));
  intptr_t extra_arguments =
      (receiver != NULL ? 1 : 0) + (type_args != NULL ? 1 : 0);

  // Build up arguments.
  const Array& arguments =
      Array::ZoneHandle(Z, Array::New(extra_arguments + argument_count));
  intptr_t pos = 0;
  if (receiver != NULL) {
    arguments.SetAt(pos++, *receiver);
  }
  if (type_args != NULL) {
    arguments.SetAt(pos++, *type_args);
  }

  // List of positional.
  intptr_t list_length = builder_->ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    EvaluateExpression(builder_->ReaderOffset(),
                       false);  // read ith expression.
    arguments.SetAt(pos++, result_);
  }

  // List of named.
  list_length = builder_->ReadListLength();  // read list length.
  const Array& names = Array::ZoneHandle(Z, Array::New(list_length));
  for (intptr_t i = 0; i < list_length; ++i) {
    String& name =
        H.DartSymbol(builder_->ReadStringReference());  // read ith name index.
    names.SetAt(i, name);
    EvaluateExpression(builder_->ReaderOffset(),
                       false);  // read ith expression.
    arguments.SetAt(pos++, result_);
  }

  return RunFunction(function, arguments, names);
}

const Object& StreamingConstantEvaluator::RunFunction(const Function& function,
                                                      const Array& arguments,
                                                      const Array& names) {
  // We do not support generic methods yet.
  const int kTypeArgsLen = 0;
  const Array& args_descriptor = Array::Handle(
      Z, ArgumentsDescriptor::New(kTypeArgsLen, arguments.Length(), names));
  const Object& result = Object::Handle(
      Z, DartEntry::InvokeFunction(function, arguments, args_descriptor));
  if (result.IsError()) {
    H.ReportError(Error::Cast(result), "error evaluating constant constructor");
  }
  return result;
}

const Object& StreamingConstantEvaluator::RunMethodCall(
    const Function& function,
    const Instance* receiver) {
  intptr_t argument_count = builder_->ReadUInt();  // read arguments count.

  // TODO(28109) Support generic methods in the VM or reify them away.
  ASSERT(builder_->PeekListLength() == 0);
  builder_->SkipListOfDartTypes();  // read list of types.

  // Run the method.
  return RunFunction(function, argument_count, receiver, NULL);
}

RawObject* StreamingConstantEvaluator::EvaluateConstConstructorCall(
    const Class& type_class,
    const TypeArguments& type_arguments,
    const Function& constructor,
    const Object& argument) {
  // Factories have one extra argument: the type arguments.
  // Constructors have 1 extra arguments: receiver.
  const int kTypeArgsLen = 0;
  const int kNumArgs = 1;
  const int kNumExtraArgs = 1;
  const int argument_count = kNumArgs + kNumExtraArgs;
  const Array& arg_values =
      Array::Handle(Z, Array::New(argument_count, Heap::kOld));
  Instance& instance = Instance::Handle(Z);
  if (!constructor.IsFactory()) {
    instance = Instance::New(type_class, Heap::kOld);
    if (!type_arguments.IsNull()) {
      ASSERT(type_arguments.IsInstantiated());
      instance.SetTypeArguments(
          TypeArguments::Handle(Z, type_arguments.Canonicalize()));
    }
    arg_values.SetAt(0, instance);
  } else {
    // Prepend type_arguments to list of arguments to factory.
    ASSERT(type_arguments.IsZoneHandle());
    arg_values.SetAt(0, type_arguments);
  }
  arg_values.SetAt((0 + kNumExtraArgs), argument);
  const Array& args_descriptor =
      Array::Handle(Z, ArgumentsDescriptor::New(kTypeArgsLen, argument_count,
                                                Object::empty_array()));
  const Object& result = Object::Handle(
      Z, DartEntry::InvokeFunction(constructor, arg_values, args_descriptor));
  ASSERT(!result.IsError());
  if (constructor.IsFactory()) {
    // The factory method returns the allocated object.
    instance ^= result.raw();
  }
  return H.Canonicalize(instance);
}

const TypeArguments* StreamingConstantEvaluator::TranslateTypeArguments(
    const Function& target,
    Class* target_klass) {
  intptr_t type_count = builder_->ReadListLength();  // read type count.

  const TypeArguments* type_arguments = NULL;
  if (type_count > 0) {
    type_arguments = &T.BuildInstantiatedTypeArguments(
        *target_klass, type_count);  // read types.

    if (!(type_arguments->IsNull() || type_arguments->IsInstantiated())) {
      H.ReportError(script_, TokenPosition::kNoSource,
                    "Type must be constant in const constructor.");
    }
  } else if (target.IsFactory() && type_arguments == NULL) {
    // All factories take a type arguments vector as first argument (independent
    // of whether the class is generic or not).
    type_arguments = &TypeArguments::ZoneHandle(Z, TypeArguments::null());
  }
  return type_arguments;
}

bool StreamingConstantEvaluator::EvaluateBooleanExpressionHere() {
  EvaluateExpression(builder_->ReaderOffset(), false);
  AssertBool();
  return result_.raw() == Bool::True().raw();
}

bool StreamingConstantEvaluator::GetCachedConstant(intptr_t kernel_offset,
                                                   Instance* value) {
  if (builder_ == NULL || builder_->flow_graph_builder_ == NULL) return false;

  const Function& function = builder_->parsed_function()->function();
  if (function.kind() == RawFunction::kImplicitStaticFinalGetter) {
    // Don't cache constants in initializer expressions. They get
    // evaluated only once.
    return false;
  }

  bool is_present = false;
  ASSERT(!script_.InVMHeap());
  if (script_.compile_time_constants() == Array::null()) {
    return false;
  }
  KernelConstantsMap constants(script_.compile_time_constants());
  *value ^= constants.GetOrNull(kernel_offset + builder_->data_program_offset_,
                                &is_present);
  // Mutator compiler thread may add constants while background compiler
  // is running, and thus change the value of 'compile_time_constants';
  // do not assert that 'compile_time_constants' has not changed.
  constants.Release();
  if (FLAG_compiler_stats && is_present) {
    ++H.thread()->compiler_stats()->num_const_cache_hits;
  }
  return is_present;
}

void StreamingConstantEvaluator::CacheConstantValue(intptr_t kernel_offset,
                                                    const Instance& value) {
  ASSERT(Thread::Current()->IsMutatorThread());

  if (builder_ == NULL || builder_->flow_graph_builder_ == NULL) return;

  const Function& function = builder_->parsed_function()->function();
  if (function.kind() == RawFunction::kImplicitStaticFinalGetter) {
    // Don't cache constants in initializer expressions. They get
    // evaluated only once.
    return;
  }
  const intptr_t kInitialConstMapSize = 16;
  ASSERT(!script_.InVMHeap());
  if (script_.compile_time_constants() == Array::null()) {
    const Array& array = Array::Handle(
        HashTables::New<KernelConstantsMap>(kInitialConstMapSize, Heap::kNew));
    script_.set_compile_time_constants(array);
  }
  KernelConstantsMap constants(script_.compile_time_constants());
  constants.InsertNewOrGetValue(kernel_offset + builder_->data_program_offset_,
                                value);
  script_.set_compile_time_constants(constants.Release());
}

void StreamingFlowGraphBuilder::DiscoverEnclosingElements(
    Zone* zone,
    const Function& function,
    Function* outermost_function) {
  // Find out if there is an enclosing kernel class (which will be used to
  // resolve type parameters).
  *outermost_function = function.raw();
  while (outermost_function->parent_function() != Object::null()) {
    *outermost_function = outermost_function->parent_function();
  }
}

void StreamingFlowGraphBuilder::ReadUntilFunctionNode() {
  const Tag tag = PeekTag();
  if (tag == kProcedure) {
    ProcedureHelper procedure_helper(this);
    procedure_helper.ReadUntilExcluding(ProcedureHelper::kFunction);
    if (ReadTag() == kNothing) {  // read function node tag.
      // Running a procedure without a function node doesn't make sense.
      UNREACHABLE();
    }
    return;
    // Now at start of FunctionNode.
  } else if (tag == kConstructor) {
    ConstructorHelper constructor_helper(this);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kFunction);
    return;
    // Now at start of FunctionNode.
    // Notice that we also have a list of initializers after that!
  } else if (tag == kFunctionNode) {
    // Already at start of FunctionNode.
  } else {
    H.ReportError("Unsupported tag at this point: %d.", tag);
    UNREACHABLE();
  }
  return;
}

StringIndex StreamingFlowGraphBuilder::GetNameFromVariableDeclaration(
    intptr_t kernel_offset,
    const Function& function) {
  TypedData& kernel_data = TypedData::Handle(Z, function.KernelData());
  ASSERT(!kernel_data.IsNull());

  // Temporarily go to the variable declaration, read the name.
  AlternativeReadingScope alt(reader_, &kernel_data, kernel_offset);
  VariableDeclarationHelper helper(this);
  helper.ReadUntilIncluding(VariableDeclarationHelper::kNameIndex);
  return helper.name_index_;
}

bool StreamingFlowGraphBuilder::optimizing() {
  return flow_graph_builder_->optimizing_;
}

FlowGraph* StreamingFlowGraphBuilder::BuildGraphOfStaticFieldInitializer() {
  FieldHelper field_helper(this);
  field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
  ASSERT(field_helper.IsStatic());

  Tag initializer_tag = ReadTag();  // read first part of initializer.
  if (initializer_tag != kSomething) {
    UNREACHABLE();
  }

  TargetEntryInstr* normal_entry = flow_graph_builder_->BuildTargetEntry();
  flow_graph_builder_->graph_entry_ = new (Z) GraphEntryInstr(
      *parsed_function(), normal_entry, Compiler::kNoOSRDeoptId);

  Fragment body(normal_entry);
  body += flow_graph_builder_->CheckStackOverflowInPrologue();
  if (field_helper.IsConst()) {
    // this will (potentially) read the initializer, but reset the position.
    body += Constant(constant_evaluator_.EvaluateExpression(ReaderOffset()));
    SkipExpression();  // read the initializer.
  } else {
    body += BuildExpression();  // read initializer.
  }
  body += Return(TokenPosition::kNoSource);

  return new (Z)
      FlowGraph(*parsed_function(), flow_graph_builder_->graph_entry_,
                flow_graph_builder_->next_block_id_ - 1);
}

FlowGraph* StreamingFlowGraphBuilder::BuildGraphOfFieldAccessor(
    LocalVariable* setter_value) {
  FieldHelper field_helper(this);
  field_helper.ReadUntilIncluding(FieldHelper::kCanonicalName);

  const Function& function = parsed_function()->function();

  bool is_setter = function.IsImplicitSetterFunction();
  bool is_method = !function.IsStaticFunction();
  Field& field = Field::ZoneHandle(
      Z, H.LookupFieldByKernelField(field_helper.canonical_name_));

  TargetEntryInstr* normal_entry = flow_graph_builder_->BuildTargetEntry();
  flow_graph_builder_->graph_entry_ = new (Z) GraphEntryInstr(
      *parsed_function(), normal_entry, Compiler::kNoOSRDeoptId);

  Fragment body(normal_entry);
  if (is_setter) {
    if (is_method) {
      body += LoadLocal(scopes()->this_variable);
      body += LoadLocal(setter_value);
      body += flow_graph_builder_->StoreInstanceFieldGuarded(field, false);
    } else {
      body += LoadLocal(setter_value);
      body += StoreStaticField(TokenPosition::kNoSource, field);
    }
    body += NullConstant();
  } else if (is_method) {
    body += LoadLocal(scopes()->this_variable);
    body += flow_graph_builder_->LoadField(field);
  } else if (field.is_const()) {
    field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
    Tag initializer_tag = ReadTag();  // read first part of initializer.

    // If the parser needs to know the value of an uninitialized constant field
    // it will set the value to the transition sentinel (used to detect circular
    // initialization) and then call the implicit getter.  Thus, the getter
    // cannot contain the InitStaticField instruction that normal static getters
    // contain because it would detect spurious circular initialization when it
    // checks for the transition sentinel.
    ASSERT(initializer_tag == kSomething);
    body += Constant(constant_evaluator_.EvaluateExpression(ReaderOffset()));
  } else {
    // The field always has an initializer because static fields without
    // initializers are initialized eagerly and do not have implicit getters.
    ASSERT(field.has_initializer());
    body += Constant(field);
    body += flow_graph_builder_->InitStaticField(field);
    body += Constant(field);
    body += LoadStaticField();
  }
  body += Return(TokenPosition::kNoSource);

  return new (Z)
      FlowGraph(*parsed_function(), flow_graph_builder_->graph_entry_,
                flow_graph_builder_->next_block_id_ - 1);
}

void StreamingFlowGraphBuilder::SetupDefaultParameterValues() {
  intptr_t optional_parameter_count =
      parsed_function()->function().NumOptionalParameters();
  if (optional_parameter_count > 0) {
    ZoneGrowableArray<const Instance*>* default_values =
        new ZoneGrowableArray<const Instance*>(Z, optional_parameter_count);

    AlternativeReadingScope alt(reader_);
    FunctionNodeHelper function_node_helper(this);
    function_node_helper.ReadUntilExcluding(
        FunctionNodeHelper::kPositionalParameters);

    if (parsed_function()->function().HasOptionalNamedParameters()) {
      // List of positional.
      intptr_t list_length = ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        SkipVariableDeclaration();  // read ith variable declaration.
      }

      // List of named.
      list_length = ReadListLength();  // read list length.
      ASSERT(optional_parameter_count == list_length);
      ASSERT(!parsed_function()->function().HasOptionalPositionalParameters());
      for (intptr_t i = 0; i < list_length; ++i) {
        Instance* default_value;

        // Read ith variable declaration
        VariableDeclarationHelper helper(this);
        helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);
        Tag tag = ReadTag();  // read (first part of) initializer.
        if (tag == kSomething) {
          // this will (potentially) read the initializer,
          // but reset the position.
          default_value =
              &constant_evaluator_.EvaluateExpression(ReaderOffset());
          SkipExpression();  // read (actual) initializer.
        } else {
          default_value = &Instance::ZoneHandle(Z, Instance::null());
        }
        default_values->Add(default_value);
      }
    } else {
      // List of positional.
      intptr_t list_length = ReadListLength();  // read list length.
      ASSERT(list_length == function_node_helper.required_parameter_count_ +
                                optional_parameter_count);
      ASSERT(parsed_function()->function().HasOptionalPositionalParameters());
      for (intptr_t i = 0; i < function_node_helper.required_parameter_count_;
           ++i) {
        SkipVariableDeclaration();  // read ith variable declaration.
      }
      for (intptr_t i = 0; i < optional_parameter_count; ++i) {
        Instance* default_value;

        // Read ith variable declaration
        VariableDeclarationHelper helper(this);
        helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);
        Tag tag = ReadTag();  // read (first part of) initializer.
        if (tag == kSomething) {
          // this will (potentially) read the initializer,
          // but reset the position.
          default_value =
              &constant_evaluator_.EvaluateExpression(ReaderOffset());
          SkipExpression();  // read (actual) initializer.
        } else {
          default_value = &Instance::ZoneHandle(Z, Instance::null());
        }
        default_values->Add(default_value);
      }

      // List of named.
      list_length = ReadListLength();  // read list length.
      ASSERT(list_length == 0);
    }
    parsed_function()->set_default_parameter_values(default_values);
  }
}

Fragment StreamingFlowGraphBuilder::BuildFieldInitializer(
    NameIndex canonical_name) {
  Field& field =
      Field::ZoneHandle(Z, H.LookupFieldByKernelField(canonical_name));
  if (PeekTag() == kNullLiteral) {
    SkipExpression();  // read past the null literal.
    field.RecordStore(Object::null_object());
    return Fragment();
  }

  Fragment instructions;
  instructions += LoadLocal(scopes()->this_variable);
  instructions += BuildExpression();
  instructions += flow_graph_builder_->StoreInstanceFieldGuarded(field, true);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildInitializers(
    const Class& parent_class) {
  Fragment instructions;

  // Start by getting the position of the constructors initializer.
  intptr_t initializers_offset = -1;
  {
    AlternativeReadingScope alt(reader_);
    SkipFunctionNode();  // read constructors function node.
    initializers_offset = ReaderOffset();
  }

  // These come from:
  //   class A {
  //     var x = (expr);
  //   }
  // We don't want to do that when this is a Redirecting Constructors though
  // (i.e. has a single initializer being of type kRedirectingInitializer).
  bool is_redirecting_constructor = false;
  {
    AlternativeReadingScope alt(reader_, initializers_offset);
    intptr_t list_length = ReadListLength();  // read initializers list length.
    bool no_field_initializers = true;
    for (intptr_t i = 0; i < list_length; ++i) {
      if (PeekTag() == kRedirectingInitializer) {
        is_redirecting_constructor = true;
      } else if (PeekTag() == kFieldInitializer) {
        no_field_initializers = false;
      }
      SkipInitializer();
    }
    ASSERT(is_redirecting_constructor ? no_field_initializers : true);
  }

  if (!is_redirecting_constructor) {
    Array& class_fields = Array::Handle(Z, parent_class.fields());
    Field& class_field = Field::Handle(Z);
    for (intptr_t i = 0; i < class_fields.Length(); ++i) {
      class_field ^= class_fields.At(i);
      if (!class_field.is_static()) {
        TypedData& kernel_data = TypedData::Handle(Z, class_field.KernelData());
        ASSERT(!kernel_data.IsNull());
        intptr_t field_offset = class_field.kernel_offset();
        AlternativeReadingScope alt(reader_, &kernel_data, field_offset);
        FieldHelper field_helper(this);
        field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
        Tag initializer_tag = ReadTag();  // read first part of initializer.
        if (initializer_tag == kSomething) {
          EnterScope(field_offset);
          instructions += BuildFieldInitializer(
              field_helper.canonical_name_);  // read initializer.
          ExitScope(field_offset);
        }
      }
    }
  }

  // These to come from:
  //   class A {
  //     var x;
  //     var y;
  //     A(this.x) : super(expr), y = (expr);
  //   }
  {
    AlternativeReadingScope alt(reader_, initializers_offset);
    intptr_t list_length = ReadListLength();  // read initializers list length.
    for (intptr_t i = 0; i < list_length; ++i) {
      Tag tag = ReadTag();
      ReadByte();  // read isSynthetic flag.
      switch (tag) {
        case kInvalidInitializer:
          UNIMPLEMENTED();
          return Fragment();
        case kFieldInitializer: {
          NameIndex canonical_name =
              ReadCanonicalNameReference();  // read field_reference.
          instructions += BuildFieldInitializer(canonical_name);  // read value.
          break;
        }
        case kSuperInitializer: {
          NameIndex canonical_target =
              ReadCanonicalNameReference();  // read target_reference.

          instructions += LoadLocal(scopes()->this_variable);
          instructions += PushArgument();

          // TODO(jensj): ASSERT(init->arguments()->types().length() == 0);
          Array& argument_names = Array::ZoneHandle(Z);
          intptr_t argument_count;
          instructions += BuildArguments(&argument_names,
                                         &argument_count);  // read arguments.
          argument_count += 1;

          Class& parent_klass = GetSuperOrDie();

          const Function& target = Function::ZoneHandle(
              Z, H.LookupConstructorByKernelConstructor(
                     parent_klass, H.CanonicalNameString(canonical_target)));
          instructions +=
              StaticCall(TokenPosition::kNoSource, target, argument_count,
                         argument_names, ICData::kStatic);
          instructions += Drop();
          break;
        }
        case kRedirectingInitializer: {
          NameIndex canonical_target =
              ReadCanonicalNameReference();  // read target_reference.

          instructions += LoadLocal(scopes()->this_variable);
          instructions += PushArgument();

          // TODO(jensj): ASSERT(init->arguments()->types().length() == 0);
          Array& argument_names = Array::ZoneHandle(Z);
          intptr_t argument_count;
          instructions += BuildArguments(&argument_names,
                                         &argument_count);  // read arguments.
          argument_count += 1;

          const Function& target = Function::ZoneHandle(
              Z, H.LookupConstructorByKernelConstructor(canonical_target));
          instructions +=
              StaticCall(TokenPosition::kNoSource, target, argument_count,
                         argument_names, ICData::kStatic);
          instructions += Drop();
          break;
        }
        case kLocalInitializer: {
          // The other initializers following this one might read the variable.
          // This is used e.g. for evaluating the arguments to a super call
          // first, run normal field initializers next and then make the actual
          // super call:
          //
          //   The frontend converts
          //
          //      class A {
          //        var x;
          //        A(a, b) : super(a + b), x = 2*b {}
          //      }
          //
          //   to
          //
          //      class A {
          //        var x;
          //        A(a, b) : tmp = a + b, x = 2*b, super(tmp) {}
          //      }
          //
          // (This is strictly speaking not what one should do in terms of the
          //  specification but that is how it is currently implemented.)
          LocalVariable* variable =
              LookupVariable(ReaderOffset() + data_program_offset_);

          // Variable declaration
          VariableDeclarationHelper helper(this);
          helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);
          ASSERT(!helper.IsConst());
          Tag tag = ReadTag();  // read (first part of) initializer.
          if (tag != kSomething) {
            UNREACHABLE();
          }

          instructions += BuildExpression();  // read initializer.
          instructions += StoreLocal(TokenPosition::kNoSource, variable);
          instructions += Drop();
          break;
        }
        default:
          H.ReportError("Unsupported tag at this point: %d.", tag);
          UNREACHABLE();
      }
    }
  }
  return instructions;
}

FlowGraph* StreamingFlowGraphBuilder::BuildGraphOfImplicitClosureFunction(
    const Function& function) {
  const Function& target = Function::ZoneHandle(Z, function.parent_function());

  TargetEntryInstr* normal_entry = flow_graph_builder_->BuildTargetEntry();
  flow_graph_builder_->graph_entry_ = new (Z) GraphEntryInstr(
      *parsed_function(), normal_entry, Compiler::kNoOSRDeoptId);
  SetupDefaultParameterValues();

  Fragment body(normal_entry);
  body += flow_graph_builder_->CheckStackOverflowInPrologue();

  // Load all the arguments.
  if (!target.is_static()) {
    // The context has a fixed shape: a single variable which is the
    // closed-over receiver.
    body += LoadLocal(parsed_function()->current_context_var());
    body += flow_graph_builder_->LoadField(Context::variable_offset(0));
    body += PushArgument();
  }

  FunctionNodeHelper function_node_helper(this);
  function_node_helper.ReadUntilExcluding(
      FunctionNodeHelper::kPositionalParameters);

  // Positional.
  intptr_t positional_argument_count = ReadListLength();
  for (intptr_t i = 0; i < positional_argument_count; ++i) {
    body += LoadLocal(LookupVariable(
        ReaderOffset() + data_program_offset_));  // ith variable offset.
    body += PushArgument();
    SkipVariableDeclaration();  // read ith variable.
  }

  // Named.
  intptr_t named_argument_count = ReadListLength();
  Array& argument_names = Array::ZoneHandle(Z);
  if (named_argument_count > 0) {
    argument_names = Array::New(named_argument_count);
    for (intptr_t i = 0; i < named_argument_count; ++i) {
      // ith variable offset.
      body += LoadLocal(LookupVariable(ReaderOffset() + data_program_offset_));
      body += PushArgument();

      // read ith variable.
      VariableDeclarationHelper helper(this);
      helper.ReadUntilExcluding(VariableDeclarationHelper::kEnd);

      argument_names.SetAt(i, H.DartSymbol(helper.name_index_));
    }
  }

  // Forward them to the target.
  intptr_t argument_count = positional_argument_count + named_argument_count;
  if (!target.is_static()) ++argument_count;
  body += StaticCall(TokenPosition::kNoSource, target, argument_count,
                     argument_names, ICData::kNoRebind);

  // Return the result.
  body += Return(function_node_helper.end_position_);

  return new (Z)
      FlowGraph(*parsed_function(), flow_graph_builder_->graph_entry_,
                flow_graph_builder_->next_block_id_ - 1);
}

LocalVariable* StreamingFlowGraphBuilder::LookupParameterDirect(
    intptr_t kernel_offset,
    intptr_t parameter_index) {
  LocalVariable* var = LookupVariable(kernel_offset);
  LocalVariable* parameter =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            Symbols::TempParam(), var->type());
  parameter->set_index(parameter_index);
  if (var->is_captured()) parameter->set_is_captured_parameter(true);
  return parameter;
}

FlowGraph* StreamingFlowGraphBuilder::BuildGraphOfFunction(bool constructor) {
  const Function& dart_function = parsed_function()->function();
  TargetEntryInstr* normal_entry = flow_graph_builder_->BuildTargetEntry();
  flow_graph_builder_->graph_entry_ = new (Z) GraphEntryInstr(
      *parsed_function(), normal_entry, flow_graph_builder_->osr_id_);

  SetupDefaultParameterValues();

  Fragment body;

  if (dart_function.IsConvertedClosureFunction()) {
    LocalVariable* closure = new (Z) LocalVariable(
        TokenPosition::kNoSource, TokenPosition::kNoSource,
        Symbols::TempParam(), AbstractType::ZoneHandle(Z, Type::DynamicType()));
    closure->set_index(parsed_function()->first_parameter_index());
    closure->set_is_captured_parameter(true);
    body += LoadLocal(closure);
    body += LoadField(Closure::context_offset());
    LocalVariable* context = closure;
    body += StoreLocal(TokenPosition::kNoSource, context);

    // TODO(30455): Kernel generic methods undone. When generic closures are
    // supported, the type arguments passed by the caller will actually need to
    // be used here.
    if (dart_function.IsGeneric() && I->reify_generic_functions()) {
      LocalVariable* type_args_slot =
          parsed_function()->function_type_arguments();
      ASSERT(type_args_slot != NULL);
      body += LoadField(Context::variable_offset(0));
      body += StoreLocal(TokenPosition::kNoSource, type_args_slot);
    }
    body += Drop();
  } else if (dart_function.IsClosureFunction() && dart_function.IsGeneric() &&
             dart_function.NumParentTypeParameters() > 0 &&
             I->reify_generic_functions()) {
    LocalVariable* closure =
        parsed_function()->node_sequence()->scope()->VariableAt(0);
    LocalVariable* fn_type_args = parsed_function()->function_type_arguments();
    ASSERT(fn_type_args != NULL && closure != NULL);

    body += LoadLocal(fn_type_args);
    body += PushArgument();
    body += LoadLocal(closure);
    body += LoadField(Closure::function_type_arguments_offset());
    body += PushArgument();
    body += IntConstant(dart_function.NumTypeParameters() +
                        dart_function.NumParentTypeParameters());
    body += PushArgument();

    const Library& dart_internal =
        Library::Handle(Z, Library::InternalLibrary());
    const Function& prepend_function =
        Function::ZoneHandle(Z, dart_internal.LookupFunctionAllowPrivate(
                                    Symbols::PrependTypeArguments()));
    ASSERT(!prepend_function.IsNull());

    body += StaticCall(TokenPosition::kNoSource, prepend_function, 3,
                       ICData::kStatic);
    body += StoreLocal(TokenPosition::kNoSource, fn_type_args);
    body += Drop();
  }

  if (!dart_function.is_native())
    body += flow_graph_builder_->CheckStackOverflowInPrologue();
  intptr_t context_size =
      parsed_function()->node_sequence()->scope()->num_context_variables();
  if (context_size > 0) {
    body += flow_graph_builder_->PushContext(context_size);
    LocalVariable* context = MakeTemporary();

    // Copy captured parameters from the stack into the context.
    LocalScope* scope = parsed_function()->node_sequence()->scope();
    intptr_t parameter_count = dart_function.NumParameters();
    intptr_t parameter_index = parsed_function()->first_parameter_index();

    for (intptr_t i = 0; i < parameter_count; ++i, --parameter_index) {
      LocalVariable* variable = scope->VariableAt(i);
      if (variable->is_captured()) {
        // There is no LocalVariable describing the on-stack parameter so
        // create one directly and use the same type.
        LocalVariable* parameter = new (Z)
            LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                          Symbols::TempParam(), variable->type());
        parameter->set_index(parameter_index);
        // Mark the stack variable so it will be ignored by the code for
        // try/catch.
        parameter->set_is_captured_parameter(true);

        // Copy the parameter from the stack to the context.  Overwrite it
        // with a null constant on the stack so the original value is
        // eligible for garbage collection.
        body += LoadLocal(context);
        body += LoadLocal(parameter);
        body += flow_graph_builder_->StoreInstanceField(
            TokenPosition::kNoSource,
            Context::variable_offset(variable->index()));
        body += NullConstant();
        body += StoreLocal(TokenPosition::kNoSource, parameter);
        body += Drop();
      }
    }
    body += Drop();  // The context.
  }
  if (constructor) {
    // TODO(27590): Currently the [VariableDeclaration]s from the
    // initializers will be visible inside the entire body of the constructor.
    // We should make a separate scope for them.
    body += BuildInitializers(Class::Handle(Z, dart_function.Owner()));
  }

  FunctionNodeHelper function_node_helper(this);
  function_node_helper.ReadUntilExcluding(
      FunctionNodeHelper::kPositionalParameters);
  intptr_t first_parameter_offset = -1;
  {
    AlternativeReadingScope alt(reader_);
    intptr_t list_length = ReadListLength();  // read number of positionals.
    if (list_length > 0) {
      first_parameter_offset = ReaderOffset() + data_program_offset_;
    }
  }
  // Current position: About to read list of positionals.

  // The specification defines the result of `a == b` to be:
  //
  //   a) if either side is `null` then the result is `identical(a, b)`.
  //   b) else the result is `a.operator==(b)`
  //
  // For user-defined implementations of `operator==` we need therefore
  // implement the handling of a).
  //
  // The default `operator==` implementation in `Object` is implemented in terms
  // of identical (which we assume here!) which means that case a) is actually
  // included in b).  So we just use the normal implementation in the body.
  if ((dart_function.NumParameters() == 2) &&
      (dart_function.name() == Symbols::EqualOperator().raw()) &&
      (dart_function.Owner() != I->object_store()->object_class())) {
    LocalVariable* parameter = LookupVariable(first_parameter_offset);

    TargetEntryInstr* null_entry;
    TargetEntryInstr* non_null_entry;

    body += LoadLocal(parameter);
    body += BranchIfNull(&null_entry, &non_null_entry);

    // The argument was `null` and the receiver is not the null class (we only
    // go into this branch for user-defined == operators) so we can return
    // false.
    Fragment null_fragment(null_entry);
    null_fragment += Constant(Bool::False());
    null_fragment += Return(dart_function.end_token_pos());

    body = Fragment(body.entry, non_null_entry);
  }

  // If we run in checked mode, we have to check the type of the passed
  // arguments.
  if (I->type_checks()) {
    // Positional.
    intptr_t list_length = ReadListLength();
    for (intptr_t i = 0; i < list_length; ++i) {
      // ith variable offset.
      body += LoadLocal(LookupVariable(ReaderOffset() + data_program_offset_));
      body +=
          CheckVariableTypeInCheckedMode(ReaderOffset() + data_program_offset_);
      body += Drop();
      SkipVariableDeclaration();  // read ith variable.
    }

    // Named.
    list_length = ReadListLength();
    for (intptr_t i = 0; i < list_length; ++i) {
      // ith variable offset.
      body += LoadLocal(LookupVariable(ReaderOffset() + data_program_offset_));
      body +=
          CheckVariableTypeInCheckedMode(ReaderOffset() + data_program_offset_);
      body += Drop();
      SkipVariableDeclaration();  // read ith variable.
    }

    function_node_helper.SetJustRead(FunctionNodeHelper::kNamedParameters);
  }

  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kBody);

  bool has_body = ReadTag() == kSomething;  // read first part of body.

  if (dart_function.is_native()) {
    body += flow_graph_builder_->NativeFunctionBody(first_parameter_offset,
                                                    dart_function);
  } else if (has_body) {
    body += BuildStatement();  // read body.
  }
  if (body.is_open()) {
    body += NullConstant();
    body += Return(dart_function.end_token_pos());
  }

  // If functions body contains any yield points build switch statement that
  // selects a continuation point based on the value of :await_jump_var.
  if (!yield_continuations().is_empty()) {
    // The code we are building will be executed right after we enter
    // the function and before any nested contexts are allocated.
    // Reset current context_depth_ to match this.
    const intptr_t current_context_depth = flow_graph_builder_->context_depth_;
    flow_graph_builder_->context_depth_ =
        scopes()->yield_jump_variable->owner()->context_level();

    // Prepend an entry corresponding to normal entry to the function.
    yield_continuations().InsertAt(
        0, YieldContinuation(new (Z) DropTempsInstr(0, NULL),
                             CatchClauseNode::kInvalidTryIndex));
    yield_continuations()[0].entry->LinkTo(body.entry);

    // Build a switch statement.
    Fragment dispatch;

    // Load :await_jump_var into a temporary.
    dispatch += LoadLocal(scopes()->yield_jump_variable);
    dispatch += StoreLocal(TokenPosition::kNoSource, scopes()->switch_variable);
    dispatch += Drop();

    BlockEntryInstr* block = NULL;
    for (intptr_t i = 0; i < yield_continuations().length(); i++) {
      if (i == 1) {
        // This is not a normal entry but a resumption.  Restore
        // :current_context_var from :await_ctx_var.
        // Note: after this point context_depth_ does not match current context
        // depth so we should not access any local variables anymore.
        dispatch += LoadLocal(scopes()->yield_context_variable);
        dispatch += StoreLocal(TokenPosition::kNoSource,
                               parsed_function()->current_context_var());
        dispatch += Drop();
      }
      if (i == (yield_continuations().length() - 1)) {
        // We reached the last possility, no need to build more ifs.
        // Continue to the last continuation.
        // Note: continuations start with nop DropTemps instruction
        // which acts like an anchor, so we need to skip it.
        block->set_try_index(yield_continuations()[i].try_index);
        dispatch <<= yield_continuations()[i].entry->next();
        break;
      }

      // Build comparison:
      //
      //   if (:await_ctx_var == i) {
      //     -> yield_continuations()[i]
      //   } else ...
      //
      TargetEntryInstr* then;
      TargetEntryInstr* otherwise;
      dispatch += LoadLocal(scopes()->switch_variable);
      dispatch += IntConstant(i);
      dispatch += flow_graph_builder_->BranchIfStrictEqual(&then, &otherwise);

      // True branch is linked to appropriate continuation point.
      // Note: continuations start with nop DropTemps instruction
      // which acts like an anchor, so we need to skip it.
      then->LinkTo(yield_continuations()[i].entry->next());
      then->set_try_index(yield_continuations()[i].try_index);
      // False branch will contain the next comparison.
      dispatch = Fragment(dispatch.entry, otherwise);
      block = otherwise;
    }
    body = dispatch;

    flow_graph_builder_->context_depth_ = current_context_depth;
  }

  if (FLAG_causal_async_stacks &&
      (dart_function.IsAsyncClosure() || dart_function.IsAsyncGenClosure())) {
    // The code we are building will be executed right after we enter
    // the function and before any nested contexts are allocated.
    // Reset current context_depth_ to match this.
    const intptr_t current_context_depth = flow_graph_builder_->context_depth_;
    flow_graph_builder_->context_depth_ =
        scopes()->yield_jump_variable->owner()->context_level();

    Fragment instructions;
    LocalScope* scope = parsed_function()->node_sequence()->scope();

    const Function& target = Function::ZoneHandle(
        Z, I->object_store()->async_set_thread_stack_trace());
    ASSERT(!target.IsNull());

    // Fetch and load :async_stack_trace
    LocalVariable* async_stack_trace_var =
        scope->LookupVariable(Symbols::AsyncStackTraceVar(), false);
    ASSERT((async_stack_trace_var != NULL) &&
           async_stack_trace_var->is_captured());
    instructions += LoadLocal(async_stack_trace_var);
    instructions += PushArgument();

    // Call _asyncSetThreadStackTrace
    instructions += StaticCall(TokenPosition::kNoSource, target,
                               /* argument_count = */ 1, ICData::kStatic);
    instructions += Drop();

    // TODO(29737): This sequence should be generated in order.
    body = instructions + body;
    flow_graph_builder_->context_depth_ = current_context_depth;
  }

  if (NeedsDebugStepCheck(dart_function, function_node_helper.position_)) {
    const intptr_t current_context_depth = flow_graph_builder_->context_depth_;
    flow_graph_builder_->context_depth_ = 0;
    // If a switch was added above: Start the switch by injecting a debuggable
    // safepoint so stepping over an await works.
    // If not, still start the body with a debuggable safepoint to ensure
    // breaking on a method always happens, even if there are no
    // assignments/calls/runtimecalls in the first basic block.
    // Place this check at the last parameter to ensure parameters
    // are in scope in the debugger at method entry.
    const int parameter_count = dart_function.NumParameters();
    TokenPosition check_pos = TokenPosition::kNoSource;
    if (parameter_count > 0) {
      LocalScope* scope = parsed_function()->node_sequence()->scope();
      const LocalVariable& parameter = *scope->VariableAt(parameter_count - 1);
      check_pos = parameter.token_pos();
    }
    if (!check_pos.IsDebugPause()) {
      // No parameters or synthetic parameters.
      check_pos = function_node_helper.position_;
      ASSERT(check_pos.IsDebugPause());
    }

    // TODO(29737): This sequence should be generated in order.
    body = DebugStepCheck(check_pos) + body;
    flow_graph_builder_->context_depth_ = current_context_depth;
  }

  normal_entry->LinkTo(body.entry);

  GraphEntryInstr* graph_entry = flow_graph_builder_->graph_entry_;
  // When compiling for OSR, use a depth first search to find the OSR
  // entry and make graph entry jump to it instead of normal entry.
  // Catch entries are always considered reachable, even if they
  // become unreachable after OSR.
  if (flow_graph_builder_->osr_id_ != Compiler::kNoOSRDeoptId) {
    graph_entry->RelinkToOsrEntry(Z, flow_graph_builder_->next_block_id_);
  }
  return new (Z) FlowGraph(*parsed_function(), graph_entry,
                           flow_graph_builder_->next_block_id_ - 1);
}

FlowGraph* StreamingFlowGraphBuilder::BuildGraph(intptr_t kernel_offset) {
  const Function& function = parsed_function()->function();

  // Setup a [ActiveClassScope] and a [ActiveMemberScope] which will be used
  // e.g. for type translation.
  const Class& klass =
      Class::Handle(zone_, parsed_function()->function().Owner());
  Function& outermost_function = Function::Handle(Z);
  DiscoverEnclosingElements(Z, function, &outermost_function);

  ActiveClassScope active_class_scope(active_class(), &klass);
  ActiveMemberScope active_member(active_class(), &outermost_function);
  ActiveTypeParametersScope active_type_params(active_class(), function, Z);

  // The IR builder will create its own local variables and scopes, and it
  // will not need an AST.  The code generator will assume that there is a
  // local variable stack slot allocated for the current context and (I
  // think) that the runtime will expect it to be at a fixed offset which
  // requires allocating an unused expression temporary variable.
  set_scopes(parsed_function()->EnsureKernelScopes());

  SetOffset(kernel_offset);

  switch (function.kind()) {
    case RawFunction::kClosureFunction:
    case RawFunction::kImplicitClosureFunction:
    case RawFunction::kConvertedClosureFunction:
    case RawFunction::kRegularFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction: {
      ReadUntilFunctionNode();  // read until function node.
      if (function.IsImplicitClosureFunction()) {
        return BuildGraphOfImplicitClosureFunction(function);
      }
      return BuildGraphOfFunction(false);
    }
    case RawFunction::kConstructor: {
      ReadUntilFunctionNode();  // read until function node.
      return BuildGraphOfFunction(!function.IsFactory());
    }
    case RawFunction::kImplicitGetter:
    case RawFunction::kImplicitStaticFinalGetter:
    case RawFunction::kImplicitSetter: {
      return IsStaticInitializer(function, Z)
                 ? BuildGraphOfStaticFieldInitializer()
                 : BuildGraphOfFieldAccessor(scopes()->setter_value);
    }
    case RawFunction::kMethodExtractor:
      return flow_graph_builder_->BuildGraphOfMethodExtractor(function);
    case RawFunction::kNoSuchMethodDispatcher:
      return flow_graph_builder_->BuildGraphOfNoSuchMethodDispatcher(function);
    case RawFunction::kInvokeFieldDispatcher:
      return flow_graph_builder_->BuildGraphOfInvokeFieldDispatcher(function);
    case RawFunction::kSignatureFunction:
    case RawFunction::kIrregexpFunction:
      break;
  }
  UNREACHABLE();
  return NULL;
}

Fragment StreamingFlowGraphBuilder::BuildStatementAt(intptr_t kernel_offset) {
  SetOffset(kernel_offset);
  return BuildStatement();  // read statement.
}

Fragment StreamingFlowGraphBuilder::BuildExpression(TokenPosition* position) {
  uint8_t payload = 0;
  Tag tag = ReadTag(&payload);  // read tag.
  switch (tag) {
    case kInvalidExpression:
      return BuildInvalidExpression(position);
    case kVariableGet:
      return BuildVariableGet(position);
    case kSpecializedVariableGet:
      return BuildVariableGet(payload, position);
    case kVariableSet:
      return BuildVariableSet(position);
    case kSpecializedVariableSet:
      return BuildVariableSet(payload, position);
    case kPropertyGet:
      return BuildPropertyGet(position);
    case kPropertySet:
      return BuildPropertySet(position);
    case kDirectPropertyGet:
      return BuildDirectPropertyGet(position);
    case kDirectPropertySet:
      return BuildDirectPropertySet(position);
    case kSuperPropertyGet:
      return BuildSuperPropertyGet(position);
    case kSuperPropertySet:
      return BuildSuperPropertySet(position);
    case kStaticGet:
      return BuildStaticGet(position);
    case kStaticSet:
      return BuildStaticSet(position);
    case kMethodInvocation:
      return BuildMethodInvocation(position);
    case kSuperMethodInvocation:
      return BuildSuperMethodInvocation(position);
    case kDirectMethodInvocation:
      return BuildDirectMethodInvocation(position);
    case kStaticInvocation:
      return BuildStaticInvocation(false, position);
    case kConstStaticInvocation:
      return BuildStaticInvocation(true, position);
    case kConstructorInvocation:
      return BuildConstructorInvocation(false, position);
    case kConstConstructorInvocation:
      return BuildConstructorInvocation(true, position);
    case kNot:
      return BuildNot(position);
    case kLogicalExpression:
      return BuildLogicalExpression(position);
    case kConditionalExpression:
      return BuildConditionalExpression(position);
    case kStringConcatenation:
      return BuildStringConcatenation(position);
    case kIsExpression:
      return BuildIsExpression(position);
    case kAsExpression:
      return BuildAsExpression(position);
    case kSymbolLiteral:
      return BuildSymbolLiteral(position);
    case kTypeLiteral:
      return BuildTypeLiteral(position);
    case kThisExpression:
      return BuildThisExpression(position);
    case kRethrow:
      return BuildRethrow(position);
    case kThrow:
      return BuildThrow(position);
    case kListLiteral:
      return BuildListLiteral(false, position);
    case kConstListLiteral:
      return BuildListLiteral(true, position);
    case kMapLiteral:
      return BuildMapLiteral(false, position);
    case kConstMapLiteral:
      return BuildMapLiteral(true, position);
    case kFunctionExpression:
      return BuildFunctionExpression();
    case kLet:
      return BuildLet(position);
    case kBigIntLiteral:
      return BuildBigIntLiteral(position);
    case kStringLiteral:
      return BuildStringLiteral(position);
    case kSpecialIntLiteral:
      return BuildIntLiteral(payload, position);
    case kNegativeIntLiteral:
      return BuildIntLiteral(true, position);
    case kPositiveIntLiteral:
      return BuildIntLiteral(false, position);
    case kDoubleLiteral:
      return BuildDoubleLiteral(position);
    case kTrueLiteral:
      return BuildBoolLiteral(true, position);
    case kFalseLiteral:
      return BuildBoolLiteral(false, position);
    case kNullLiteral:
      return BuildNullLiteral(position);
    case kVectorCreation:
      return BuildVectorCreation(position);
    case kVectorGet:
      return BuildVectorGet(position);
    case kVectorSet:
      return BuildVectorSet(position);
    case kVectorCopy:
      return BuildVectorCopy(position);
    case kClosureCreation:
      return BuildClosureCreation(position);
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }

  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildStatement() {
  Tag tag = ReadTag();  // read tag.
  switch (tag) {
    case kInvalidStatement:
      return BuildInvalidStatement();
    case kExpressionStatement:
      return BuildExpressionStatement();
    case kBlock:
      return BuildBlock();
    case kEmptyStatement:
      return BuildEmptyStatement();
    case kAssertStatement:
      return BuildAssertStatement();
    case kLabeledStatement:
      return BuildLabeledStatement();
    case kBreakStatement:
      return BuildBreakStatement();
    case kWhileStatement:
      return BuildWhileStatement();
    case kDoStatement:
      return BuildDoStatement();
    case kForStatement:
      return BuildForStatement();
    case kForInStatement:
      return BuildForInStatement(false);
    case kAsyncForInStatement:
      return BuildForInStatement(true);
    case kSwitchStatement:
      return BuildSwitchStatement();
    case kContinueSwitchStatement:
      return BuildContinueSwitchStatement();
    case kIfStatement:
      return BuildIfStatement();
    case kReturnStatement:
      return BuildReturnStatement();
    case kTryCatch:
      return BuildTryCatch();
    case kTryFinally:
      return BuildTryFinally();
    case kYieldStatement:
      return BuildYieldStatement();
    case kVariableDeclaration:
      return BuildVariableDeclaration();
    case kFunctionDeclaration:
      return BuildFunctionDeclaration();
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }
  return Fragment();
}

intptr_t StreamingFlowGraphBuilder::ReaderOffset() {
  return reader_->offset();
}

void StreamingFlowGraphBuilder::SetOffset(intptr_t offset) {
  reader_->set_offset(offset);
}

void StreamingFlowGraphBuilder::SkipBytes(intptr_t bytes) {
  reader_->set_offset(ReaderOffset() + bytes);
}

bool StreamingFlowGraphBuilder::ReadBool() {
  return reader_->ReadBool();
}

uint8_t StreamingFlowGraphBuilder::ReadByte() {
  return reader_->ReadByte();
}

uint32_t StreamingFlowGraphBuilder::ReadUInt() {
  return reader_->ReadUInt();
}

uint32_t StreamingFlowGraphBuilder::ReadUInt32() {
  return reader_->ReadUInt32();
}

uint32_t StreamingFlowGraphBuilder::PeekUInt() {
  AlternativeReadingScope alt(reader_);
  return reader_->ReadUInt();
}

uint32_t StreamingFlowGraphBuilder::PeekListLength() {
  AlternativeReadingScope alt(reader_);
  return reader_->ReadListLength();
}

intptr_t StreamingFlowGraphBuilder::ReadListLength() {
  return reader_->ReadListLength();
}

StringIndex StreamingFlowGraphBuilder::ReadStringReference() {
  return StringIndex(ReadUInt());
}

NameIndex StreamingFlowGraphBuilder::ReadCanonicalNameReference() {
  return reader_->ReadCanonicalNameReference();
}

StringIndex StreamingFlowGraphBuilder::ReadNameAsStringIndex() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    ReadUInt();  // read library index.
  }
  return name_index;
}

const String& StreamingFlowGraphBuilder::ReadNameAsMethodName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartMethodName(library_reference, name_index);
  } else {
    return H.DartMethodName(NameIndex(), name_index);
  }
}

const String& StreamingFlowGraphBuilder::ReadNameAsSetterName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartSetterName(library_reference, name_index);
  } else {
    return H.DartSetterName(NameIndex(), name_index);
  }
}

const String& StreamingFlowGraphBuilder::ReadNameAsGetterName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartGetterName(library_reference, name_index);
  } else {
    return H.DartGetterName(NameIndex(), name_index);
  }
}

const String& StreamingFlowGraphBuilder::ReadNameAsFieldName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartFieldName(library_reference, name_index);
  } else {
    return H.DartFieldName(NameIndex(), name_index);
  }
}

void StreamingFlowGraphBuilder::SkipFlags() {
  ReadFlags();
}

void StreamingFlowGraphBuilder::SkipStringReference() {
  ReadUInt();
}

void StreamingFlowGraphBuilder::SkipCanonicalNameReference() {
  ReadUInt();
}

void StreamingFlowGraphBuilder::SkipDartType() {
  Tag tag = ReadTag();
  switch (tag) {
    case kInvalidType:
    case kDynamicType:
    case kVoidType:
    case kBottomType:
    case kVectorType:
      // those contain nothing.
      return;
    case kInterfaceType:
      SkipInterfaceType(false);
      return;
    case kSimpleInterfaceType:
      SkipInterfaceType(true);
      return;
    case kFunctionType:
      SkipFunctionType(false);
      return;
    case kSimpleFunctionType:
      SkipFunctionType(true);
      return;
    case kTypeParameterType:
      ReadUInt();              // read index for parameter.
      SkipOptionalDartType();  // read bound bound.
      return;
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }
}

void StreamingFlowGraphBuilder::SkipOptionalDartType() {
  Tag tag = ReadTag();  // read tag.
  if (tag == kNothing) {
    return;
  }
  ASSERT(tag == kSomething);

  SkipDartType();  // read type.
}

void StreamingFlowGraphBuilder::SkipInterfaceType(bool simple) {
  ReadUInt();  // read klass_name.
  if (!simple) {
    SkipListOfDartTypes();  // read list of types.
  }
}

void StreamingFlowGraphBuilder::SkipFunctionType(bool simple) {
  if (!simple) {
    SkipTypeParametersList();  // read type_parameters.
    ReadUInt();                // read required parameter count.
    ReadUInt();                // read total parameter count.
  }

  SkipListOfDartTypes();  // read positional_parameters types.

  if (!simple) {
    const intptr_t named_count =
        ReadListLength();  // read named_parameters list length.
    for (intptr_t i = 0; i < named_count; ++i) {
      // read string reference (i.e. named_parameters[i].name).
      SkipStringReference();
      SkipDartType();  // read named_parameters[i].type.
    }
  }

  SkipListOfStrings();  // read positional parameter names.

  if (!simple) {
    SkipCanonicalNameReference();  // read typedef reference.
  }

  SkipDartType();  // read return type.
}

void StreamingFlowGraphBuilder::SkipListOfExpressions() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipExpression();  // read ith expression.
  }
}

void StreamingFlowGraphBuilder::SkipListOfDartTypes() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipDartType();  // read ith type.
  }
}

void StreamingFlowGraphBuilder::SkipListOfStrings() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipStringReference();  // read ith string index.
  }
}

void StreamingFlowGraphBuilder::SkipListOfVariableDeclarations() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipVariableDeclaration();  // read ith variable declaration.
  }
}

void StreamingFlowGraphBuilder::SkipTypeParametersList() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipFlags();              // read ith flags.
    SkipListOfExpressions();  // read annotations.
    SkipStringReference();    // read ith name index.
    SkipDartType();           // read ith bound.
  }
}

void StreamingFlowGraphBuilder::SkipInitializer() {
  Tag tag = ReadTag();
  ReadByte();  // read isSynthetic flag.
  switch (tag) {
    case kInvalidInitializer:
      return;
    case kFieldInitializer:
      SkipCanonicalNameReference();  // read field_reference.
      SkipExpression();              // read value.
      return;
    case kSuperInitializer:
      SkipCanonicalNameReference();  // read target_reference.
      SkipArguments();               // read arguments.
      return;
    case kRedirectingInitializer:
      SkipCanonicalNameReference();  // read target_reference.
      SkipArguments();               // read arguments.
      return;
    case kLocalInitializer:
      SkipVariableDeclaration();  // read variable.
      return;
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }
}

void StreamingFlowGraphBuilder::SkipExpression() {
  uint8_t payload = 0;
  Tag tag = ReadTag(&payload);
  switch (tag) {
    case kInvalidExpression:
      return;
    case kVariableGet:
      ReadPosition();          // read position.
      ReadUInt();              // read kernel position.
      ReadUInt();              // read relative variable index.
      SkipOptionalDartType();  // read promoted type.
      return;
    case kSpecializedVariableGet:
      ReadPosition();  // read position.
      ReadUInt();      // read kernel position.
      return;
    case kVariableSet:
      ReadPosition();    // read position.
      ReadUInt();        // read kernel position.
      ReadUInt();        // read relative variable index.
      SkipExpression();  // read expression.
      return;
    case kSpecializedVariableSet:
      ReadPosition();    // read position.
      ReadUInt();        // read kernel position.
      SkipExpression();  // read expression.
      return;
    case kPropertyGet:
      ReadPosition();                // read position.
      SkipFlags();                   // read flags.
      SkipExpression();              // read receiver.
      SkipName();                    // read name.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kPropertySet:
      ReadPosition();                // read position.
      SkipExpression();              // read receiver.
      SkipName();                    // read name.
      SkipExpression();              // read value.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kSuperPropertyGet:
      ReadPosition();                // read position.
      SkipName();                    // read name.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kSuperPropertySet:
      ReadPosition();                // read position.
      SkipName();                    // read name.
      SkipExpression();              // read value.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kDirectPropertyGet:
      ReadPosition();                // read position.
      SkipFlags();                   // read flags.
      SkipExpression();              // read receiver.
      SkipCanonicalNameReference();  // read target_reference.
      return;
    case kDirectPropertySet:
      ReadPosition();                // read position.
      SkipExpression();              // read receiver.
      SkipCanonicalNameReference();  // read target_reference.
      SkipExpression();              // read value·
      return;
    case kStaticGet:
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read target_reference.
      return;
    case kStaticSet:
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read target_reference.
      SkipExpression();              // read expression.
      return;
    case kMethodInvocation:
      ReadPosition();                // read position.
      SkipFlags();                   // read flags.
      SkipExpression();              // read receiver.
      SkipName();                    // read name.
      SkipArguments();               // read arguments.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kSuperMethodInvocation:
      ReadPosition();                // read position.
      SkipName();                    // read name.
      SkipArguments();               // read arguments.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kDirectMethodInvocation:
      ReadPosition();                // read position.
      SkipFlags();                   // read flags.
      SkipExpression();              // read receiver.
      SkipCanonicalNameReference();  // read target_reference.
      SkipArguments();               // read arguments.
      return;
    case kStaticInvocation:
    case kConstStaticInvocation:
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read procedure_reference.
      SkipArguments();               // read arguments.
      return;
    case kConstructorInvocation:
    case kConstConstructorInvocation:
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read target_reference.
      SkipArguments();               // read arguments.
      return;
    case kNot:
      SkipExpression();  // read expression.
      return;
    case kLogicalExpression:
      SkipExpression();  // read left.
      SkipBytes(1);      // read operator.
      SkipExpression();  // read right.
      return;
    case kConditionalExpression:
      SkipExpression();        // read condition.
      SkipExpression();        // read then.
      SkipExpression();        // read otherwise.
      SkipOptionalDartType();  // read unused static type.
      return;
    case kStringConcatenation:
      ReadPosition();           // read position.
      SkipListOfExpressions();  // read list of expressions.
      return;
    case kIsExpression:
      ReadPosition();    // read position.
      SkipExpression();  // read operand.
      SkipDartType();    // read type.
      return;
    case kAsExpression:
      ReadPosition();    // read position.
      SkipFlags();       // read flags.
      SkipExpression();  // read operand.
      SkipDartType();    // read type.
      return;
    case kSymbolLiteral:
      SkipStringReference();  // read index into string table.
      return;
    case kTypeLiteral:
      SkipDartType();  // read type.
      return;
    case kThisExpression:
      return;
    case kRethrow:
      ReadPosition();  // read position.
      return;
    case kThrow:
      ReadPosition();    // read position.
      SkipExpression();  // read expression.
      return;
    case kListLiteral:
    case kConstListLiteral:
      ReadPosition();           // read position.
      SkipDartType();           // read type.
      SkipListOfExpressions();  // read list of expressions.
      return;
    case kMapLiteral:
    case kConstMapLiteral: {
      ReadPosition();                           // read position.
      SkipDartType();                           // read key type.
      SkipDartType();                           // read value type.
      intptr_t list_length = ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        SkipExpression();  // read ith key.
        SkipExpression();  // read ith value.
      }
      return;
    }
    case kFunctionExpression:
      ReadPosition();      // read position.
      SkipFunctionNode();  // read function node.
      return;
    case kLet:
      SkipVariableDeclaration();  // read variable declaration.
      SkipExpression();           // read expression.
      return;
    case kVectorCreation:
      ReadUInt();  // read value.
      return;
    case kVectorGet:
      SkipExpression();  // read vector expression.
      ReadUInt();        // read index.
      return;
    case kVectorSet:
      SkipExpression();  // read vector expression.
      ReadUInt();        // read index.
      SkipExpression();  // read value.
      return;
    case kVectorCopy:
      SkipExpression();  // read vector expression.
      return;
    case kClosureCreation:
      SkipCanonicalNameReference();  // read top-level function reference.
      SkipExpression();              // read context vector.
      SkipDartType();                // read function type.
      SkipListOfDartTypes();         // read type arguments.
      return;
    case kBigIntLiteral:
      SkipStringReference();  // read string reference.
      return;
    case kStringLiteral:
      SkipStringReference();  // read string reference.
      return;
    case kSpecialIntLiteral:
      return;
    case kNegativeIntLiteral:
      ReadUInt();  // read value.
      return;
    case kPositiveIntLiteral:
      ReadUInt();  // read value.
      return;
    case kDoubleLiteral:
      SkipStringReference();  // read index into string table.
      return;
    case kTrueLiteral:
      return;
    case kFalseLiteral:
      return;
    case kNullLiteral:
      return;
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }
}

void StreamingFlowGraphBuilder::SkipStatement() {
  Tag tag = ReadTag();  // read tag.
  switch (tag) {
    case kInvalidStatement:
      return;
    case kExpressionStatement:
      SkipExpression();  // read expression.
      return;
    case kBlock: {
      intptr_t list_length = ReadListLength();  // read number of statements.
      for (intptr_t i = 0; i < list_length; ++i) {
        SkipStatement();  // read ith statement.
      }
      return;
    }
    case kEmptyStatement:
      return;
    case kAssertStatement: {
      SkipExpression();     // Read condition.
      ReadPosition();       // read condition start offset.
      ReadPosition();       // read condition end offset.
      Tag tag = ReadTag();  // read (first part of) message.
      if (tag == kSomething) {
        SkipExpression();  // read (rest of) message.
      }
      return;
    }
    case kLabeledStatement:
      SkipStatement();  // read body.
      return;
    case kBreakStatement:
      ReadPosition();  // read position.
      ReadUInt();      // read target_index.
      return;
    case kWhileStatement:
      ReadPosition();    // read position.
      SkipExpression();  // read condition.
      SkipStatement();   // read body.
      return;
    case kDoStatement:
      ReadPosition();    // read position.
      SkipStatement();   // read body.
      SkipExpression();  // read condition.
      return;
    case kForStatement: {
      ReadPosition();                    // read position.
      SkipListOfVariableDeclarations();  // read variables.
      Tag tag = ReadTag();               // Read first part of condition.
      if (tag == kSomething) {
        SkipExpression();  // read rest of condition.
      }
      SkipListOfExpressions();  // read updates.
      SkipStatement();          // read body.
      return;
    }
    case kForInStatement:
    case kAsyncForInStatement:
      ReadPosition();             // read position.
      ReadPosition();             // read body position.
      SkipVariableDeclaration();  // read variable.
      SkipExpression();           // read iterable.
      SkipStatement();            // read body.
      return;
    case kSwitchStatement: {
      ReadPosition();                     // read position.
      SkipExpression();                   // read condition.
      int case_count = ReadListLength();  // read number of cases.
      for (intptr_t i = 0; i < case_count; ++i) {
        int expression_count = ReadListLength();  // read number of expressions.
        for (intptr_t j = 0; j < expression_count; ++j) {
          ReadPosition();    // read jth position.
          SkipExpression();  // read jth expression.
        }
        ReadBool();       // read is_default.
        SkipStatement();  // read body.
      }
      return;
    }
    case kContinueSwitchStatement:
      ReadPosition();  // read position.
      ReadUInt();      // read target_index.
      return;
    case kIfStatement:
      ReadPosition();    // read position.
      SkipExpression();  // read condition.
      SkipStatement();   // read then.
      SkipStatement();   // read otherwise.
      return;
    case kReturnStatement: {
      ReadPosition();       // read position
      Tag tag = ReadTag();  // read (first part of) expression.
      if (tag == kSomething) {
        SkipExpression();  // read (rest of) expression.
      }
      return;
    }
    case kTryCatch: {
      SkipStatement();  // read body.
      ReadBool();       // read any_catch_needs_stack_trace.
      intptr_t catch_count = ReadListLength();  // read number of catches.
      for (intptr_t i = 0; i < catch_count; ++i) {
        SkipDartType();   // read guard.
        tag = ReadTag();  // read first part of exception.
        if (tag == kSomething) {
          SkipVariableDeclaration();  // read exception.
        }
        tag = ReadTag();  // read first part of stack trace.
        if (tag == kSomething) {
          SkipVariableDeclaration();  // read stack trace.
        }
        SkipStatement();  // read body.
      }
      return;
    }
    case kTryFinally:
      SkipStatement();  // read body.
      SkipStatement();  // read finalizer.
      return;
    case kYieldStatement: {
      TokenPosition position = ReadPosition();  // read position.
      record_yield_position(position);
      ReadByte();        // read flags.
      SkipExpression();  // read expression.
      return;
    }
    case kVariableDeclaration:
      SkipVariableDeclaration();  // read variable declaration.
      return;
    case kFunctionDeclaration:
      ReadPosition();             // read position.
      SkipVariableDeclaration();  // read variable.
      SkipFunctionNode();         // read function node.
      return;
    default:
      H.ReportError("Unsupported tag at this point: %d.", tag);
      UNREACHABLE();
  }
}

void StreamingFlowGraphBuilder::SkipFunctionNode() {
  FunctionNodeHelper function_node_helper(this);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);
}

void StreamingFlowGraphBuilder::SkipName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    SkipCanonicalNameReference();  // read library index.
  }
}

void StreamingFlowGraphBuilder::SkipArguments() {
  ReadUInt();  // read argument count.

  SkipListOfDartTypes();    // read list of types.
  SkipListOfExpressions();  // read positionals.

  // List of named.
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipStringReference();  // read ith name index.
    SkipExpression();       // read ith expression.
  }
}

void StreamingFlowGraphBuilder::SkipVariableDeclaration() {
  VariableDeclarationHelper helper(this);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kEnd);
}

void StreamingFlowGraphBuilder::SkipLibraryCombinator() {
  ReadBool();                        // read is_show.
  intptr_t name_count = ReadUInt();  // read list length.
  for (intptr_t j = 0; j < name_count; ++j) {
    ReadUInt();  // read ith entry of name_indices.
  }
}

void StreamingFlowGraphBuilder::SkipLibraryDependency() {
  ReadPosition();  // read file offset.
  ReadFlags();
  SkipListOfExpressions();  // Annotations.
  ReadCanonicalNameReference();
  ReadStringReference();  // Name.
  intptr_t combinator_count = ReadListLength();
  for (intptr_t i = 0; i < combinator_count; ++i) {
    SkipLibraryCombinator();
  }
}

void StreamingFlowGraphBuilder::SkipLibraryPart() {
  SkipListOfExpressions();  // Read annotations.
  ReadStringReference();    // read uri_index.
}

void StreamingFlowGraphBuilder::SkipLibraryTypedef() {
  SkipCanonicalNameReference();  // read canonical name.
  ReadPosition();                // read position.
  SkipStringReference();         // read name index.
  ReadUInt();                    // read source_uri_index.
  SkipListOfExpressions();       // read annotations.
  SkipTypeParametersList();      // read type parameters.
  SkipDartType();                // read type.
}

TokenPosition StreamingFlowGraphBuilder::ReadPosition(bool record) {
  TokenPosition position = reader_->ReadPosition();
  if (record) {
    record_token_position(position);
  }
  return position;
}

void StreamingFlowGraphBuilder::record_token_position(TokenPosition position) {
  if (record_for_script_id_ == current_script_id_ &&
      record_token_positions_into_ != NULL && position.IsReal()) {
    record_token_positions_into_->Add(position.value());
  }
}

void StreamingFlowGraphBuilder::record_yield_position(TokenPosition position) {
  if (record_for_script_id_ == current_script_id_ &&
      record_yield_positions_into_ != NULL && position.IsReal()) {
    record_yield_positions_into_->Add(position.value());
  }
}

Tag StreamingFlowGraphBuilder::ReadTag(uint8_t* payload) {
  return reader_->ReadTag(payload);
}

Tag StreamingFlowGraphBuilder::PeekTag(uint8_t* payload) {
  return reader_->PeekTag(payload);
}

void StreamingFlowGraphBuilder::loop_depth_inc() {
  ++flow_graph_builder_->loop_depth_;
}

void StreamingFlowGraphBuilder::loop_depth_dec() {
  --flow_graph_builder_->loop_depth_;
}

intptr_t StreamingFlowGraphBuilder::for_in_depth() {
  return flow_graph_builder_->for_in_depth_;
}

void StreamingFlowGraphBuilder::for_in_depth_inc() {
  ++flow_graph_builder_->for_in_depth_;
}

void StreamingFlowGraphBuilder::for_in_depth_dec() {
  --flow_graph_builder_->for_in_depth_;
}

void StreamingFlowGraphBuilder::catch_depth_inc() {
  ++flow_graph_builder_->catch_depth_;
}

void StreamingFlowGraphBuilder::catch_depth_dec() {
  --flow_graph_builder_->catch_depth_;
}

void StreamingFlowGraphBuilder::try_depth_inc() {
  ++flow_graph_builder_->try_depth_;
}

void StreamingFlowGraphBuilder::try_depth_dec() {
  --flow_graph_builder_->try_depth_;
}

intptr_t StreamingFlowGraphBuilder::CurrentTryIndex() {
  return flow_graph_builder_->CurrentTryIndex();
}

intptr_t StreamingFlowGraphBuilder::AllocateTryIndex() {
  return flow_graph_builder_->AllocateTryIndex();
}

LocalVariable* StreamingFlowGraphBuilder::CurrentException() {
  return flow_graph_builder_->CurrentException();
}

LocalVariable* StreamingFlowGraphBuilder::CurrentStackTrace() {
  return flow_graph_builder_->CurrentStackTrace();
}

CatchBlock* StreamingFlowGraphBuilder::catch_block() {
  return flow_graph_builder_->catch_block_;
}

ActiveClass* StreamingFlowGraphBuilder::active_class() {
  return &flow_graph_builder_->active_class_;
}

ScopeBuildingResult* StreamingFlowGraphBuilder::scopes() {
  return flow_graph_builder_->scopes_;
}

void StreamingFlowGraphBuilder::set_scopes(ScopeBuildingResult* scope) {
  flow_graph_builder_->scopes_ = scope;
}

ParsedFunction* StreamingFlowGraphBuilder::parsed_function() {
  return flow_graph_builder_->parsed_function_;
}

TryFinallyBlock* StreamingFlowGraphBuilder::try_finally_block() {
  return flow_graph_builder_->try_finally_block_;
}

SwitchBlock* StreamingFlowGraphBuilder::switch_block() {
  return flow_graph_builder_->switch_block_;
}

BreakableBlock* StreamingFlowGraphBuilder::breakable_block() {
  return flow_graph_builder_->breakable_block_;
}

GrowableArray<YieldContinuation>&
StreamingFlowGraphBuilder::yield_continuations() {
  return flow_graph_builder_->yield_continuations_;
}

Value* StreamingFlowGraphBuilder::stack() {
  return flow_graph_builder_->stack_;
}

void StreamingFlowGraphBuilder::Push(Definition* definition) {
  flow_graph_builder_->Push(definition);
}

Value* StreamingFlowGraphBuilder::Pop() {
  return flow_graph_builder_->Pop();
}

Tag StreamingFlowGraphBuilder::PeekArgumentsFirstPositionalTag() {
  // read parts of arguments, then go back to before doing so.
  AlternativeReadingScope alt(reader_);
  ReadUInt();  // read number of arguments.

  SkipListOfDartTypes();  // Read list of types.

  // List of positional.
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    return ReadTag();  // read first tag.
  }

  UNREACHABLE();
  return kNothing;
}

const TypeArguments& StreamingFlowGraphBuilder::PeekArgumentsInstantiatedType(
    const Class& klass) {
  // read parts of arguments, then go back to before doing so.
  AlternativeReadingScope alt(reader_);
  ReadUInt();                               // read argument count.
  intptr_t list_length = ReadListLength();  // read types list length.
  return T.BuildInstantiatedTypeArguments(klass, list_length);  // read types.
}

intptr_t StreamingFlowGraphBuilder::PeekArgumentsCount() {
  return PeekUInt();
}

LocalVariable* StreamingFlowGraphBuilder::LookupVariable(
    intptr_t kernel_offset) {
  return flow_graph_builder_->LookupVariable(kernel_offset);
}

LocalVariable* StreamingFlowGraphBuilder::MakeTemporary() {
  return flow_graph_builder_->MakeTemporary();
}

RawFunction* StreamingFlowGraphBuilder::LookupMethodByMember(
    NameIndex target,
    const String& method_name) {
  return flow_graph_builder_->LookupMethodByMember(target, method_name);
}

Function& StreamingFlowGraphBuilder::FindMatchingFunctionAnyArgs(
    const Class& klass,
    const String& name) {
  // Search the superclass chain for the selector.
  Function& function = Function::Handle(Z);
  Class& iterate_klass = Class::Handle(Z, klass.raw());
  while (!iterate_klass.IsNull()) {
    function = iterate_klass.LookupDynamicFunctionAllowPrivate(name);
    if (!function.IsNull()) break;
    iterate_klass = iterate_klass.SuperClass();
  }
  return function;
}

Function& StreamingFlowGraphBuilder::FindMatchingFunction(
    const Class& klass,
    const String& name,
    int type_args_len,
    int argument_count,
    const Array& argument_names) {
  // Search the superclass chain for the selector.
  Function& function = Function::Handle(Z);
  Class& iterate_klass = Class::Handle(Z, klass.raw());
  while (!iterate_klass.IsNull()) {
    function = iterate_klass.LookupDynamicFunctionAllowPrivate(name);
    if (!function.IsNull()) {
      if (function.AreValidArguments(type_args_len, argument_count,
                                     argument_names,
                                     /* error_message = */ NULL)) {
        return function;
      }
    }
    iterate_klass = iterate_klass.SuperClass();
  }
  return Function::Handle();
}

bool StreamingFlowGraphBuilder::NeedsDebugStepCheck(const Function& function,
                                                    TokenPosition position) {
  return flow_graph_builder_->NeedsDebugStepCheck(function, position);
}

bool StreamingFlowGraphBuilder::NeedsDebugStepCheck(Value* value,
                                                    TokenPosition position) {
  return flow_graph_builder_->NeedsDebugStepCheck(value, position);
}

void StreamingFlowGraphBuilder::InlineBailout(const char* reason) {
  flow_graph_builder_->InlineBailout(reason);
}

Fragment StreamingFlowGraphBuilder::DebugStepCheck(TokenPosition position) {
  return flow_graph_builder_->DebugStepCheck(position);
}

Fragment StreamingFlowGraphBuilder::LoadLocal(LocalVariable* variable) {
  return flow_graph_builder_->LoadLocal(variable);
}

Fragment StreamingFlowGraphBuilder::Return(TokenPosition position) {
  return flow_graph_builder_->Return(position);
}

Fragment StreamingFlowGraphBuilder::PushArgument() {
  return flow_graph_builder_->PushArgument();
}

Fragment StreamingFlowGraphBuilder::EvaluateAssertion() {
  return flow_graph_builder_->EvaluateAssertion();
}

Fragment StreamingFlowGraphBuilder::RethrowException(TokenPosition position,
                                                     int catch_try_index) {
  return flow_graph_builder_->RethrowException(position, catch_try_index);
}

Fragment StreamingFlowGraphBuilder::ThrowNoSuchMethodError() {
  return flow_graph_builder_->ThrowNoSuchMethodError();
}

Fragment StreamingFlowGraphBuilder::Constant(const Object& value) {
  return flow_graph_builder_->Constant(value);
}

Fragment StreamingFlowGraphBuilder::IntConstant(int64_t value) {
  return flow_graph_builder_->IntConstant(value);
}

Fragment StreamingFlowGraphBuilder::LoadStaticField() {
  return flow_graph_builder_->LoadStaticField();
}

Fragment StreamingFlowGraphBuilder::CheckNull(TokenPosition position,
                                              LocalVariable* receiver) {
  return flow_graph_builder_->CheckNull(position, receiver);
}

Fragment StreamingFlowGraphBuilder::StaticCall(TokenPosition position,
                                               const Function& target,
                                               intptr_t argument_count,
                                               ICData::RebindRule rebind_rule) {
  return flow_graph_builder_->StaticCall(position, target, argument_count,
                                         rebind_rule);
}

Fragment StreamingFlowGraphBuilder::StaticCall(TokenPosition position,
                                               const Function& target,
                                               intptr_t argument_count,
                                               const Array& argument_names,
                                               ICData::RebindRule rebind_rule,
                                               intptr_t type_args_count) {
  return flow_graph_builder_->StaticCall(position, target, argument_count,
                                         argument_names, rebind_rule,
                                         type_args_count);
}

Fragment StreamingFlowGraphBuilder::InstanceCall(
    TokenPosition position,
    const String& name,
    Token::Kind kind,
    intptr_t argument_count,
    intptr_t checked_argument_count) {
  const intptr_t kTypeArgsLen = 0;
  return flow_graph_builder_->InstanceCall(
      position, name, kind, kTypeArgsLen, argument_count, Array::null_array(),
      checked_argument_count, Function::null_function());
}

Fragment StreamingFlowGraphBuilder::InstanceCall(
    TokenPosition position,
    const String& name,
    Token::Kind kind,
    intptr_t type_args_len,
    intptr_t argument_count,
    const Array& argument_names,
    intptr_t checked_argument_count,
    const Function& interface_target) {
  return flow_graph_builder_->InstanceCall(
      position, name, kind, type_args_len, argument_count, argument_names,
      checked_argument_count, interface_target);
}

Fragment StreamingFlowGraphBuilder::ThrowException(TokenPosition position) {
  return flow_graph_builder_->ThrowException(position);
}

Fragment StreamingFlowGraphBuilder::BooleanNegate() {
  return flow_graph_builder_->BooleanNegate();
}

Fragment StreamingFlowGraphBuilder::TranslateInstantiatedTypeArguments(
    const TypeArguments& type_arguments) {
  return flow_graph_builder_->TranslateInstantiatedTypeArguments(
      type_arguments);
}

Fragment StreamingFlowGraphBuilder::StrictCompare(Token::Kind kind,
                                                  bool number_check) {
  return flow_graph_builder_->StrictCompare(kind, number_check);
}

Fragment StreamingFlowGraphBuilder::AllocateObject(TokenPosition position,
                                                   const Class& klass,
                                                   intptr_t argument_count) {
  return flow_graph_builder_->AllocateObject(position, klass, argument_count);
}

Fragment StreamingFlowGraphBuilder::AllocateObject(
    const Class& klass,
    const Function& closure_function) {
  return flow_graph_builder_->AllocateObject(klass, closure_function);
}

Fragment StreamingFlowGraphBuilder::AllocateContext(intptr_t size) {
  return flow_graph_builder_->AllocateContext(size);
}

Fragment StreamingFlowGraphBuilder::LoadField(intptr_t offset) {
  return flow_graph_builder_->LoadField(offset);
}

Fragment StreamingFlowGraphBuilder::StoreLocal(TokenPosition position,
                                               LocalVariable* variable) {
  return flow_graph_builder_->StoreLocal(position, variable);
}

Fragment StreamingFlowGraphBuilder::StoreStaticField(TokenPosition position,
                                                     const Field& field) {
  return flow_graph_builder_->StoreStaticField(position, field);
}

Fragment StreamingFlowGraphBuilder::StoreInstanceField(TokenPosition position,
                                                       intptr_t offset) {
  return flow_graph_builder_->StoreInstanceField(position, offset);
}

Fragment StreamingFlowGraphBuilder::StringInterpolate(TokenPosition position) {
  return flow_graph_builder_->StringInterpolate(position);
}

Fragment StreamingFlowGraphBuilder::StringInterpolateSingle(
    TokenPosition position) {
  return flow_graph_builder_->StringInterpolateSingle(position);
}

Fragment StreamingFlowGraphBuilder::ThrowTypeError() {
  return flow_graph_builder_->ThrowTypeError();
}

Fragment StreamingFlowGraphBuilder::LoadInstantiatorTypeArguments() {
  return flow_graph_builder_->LoadInstantiatorTypeArguments();
}

Fragment StreamingFlowGraphBuilder::LoadFunctionTypeArguments() {
  return flow_graph_builder_->LoadFunctionTypeArguments();
}

Fragment StreamingFlowGraphBuilder::InstantiateType(const AbstractType& type) {
  return flow_graph_builder_->InstantiateType(type);
}

Fragment StreamingFlowGraphBuilder::CreateArray() {
  return flow_graph_builder_->CreateArray();
}

Fragment StreamingFlowGraphBuilder::StoreIndexed(intptr_t class_id) {
  return flow_graph_builder_->StoreIndexed(class_id);
}

Fragment StreamingFlowGraphBuilder::CheckStackOverflow() {
  return flow_graph_builder_->CheckStackOverflow();
}

Fragment StreamingFlowGraphBuilder::CloneContext(
    intptr_t num_context_variables) {
  return flow_graph_builder_->CloneContext(num_context_variables);
}

Fragment StreamingFlowGraphBuilder::TranslateFinallyFinalizers(
    TryFinallyBlock* outer_finally,
    intptr_t target_context_depth) {
  // TranslateFinallyFinalizers can move the readers offset.
  // Save the current position and restore it afterwards.
  AlternativeReadingScope alt(reader_);
  return flow_graph_builder_->TranslateFinallyFinalizers(outer_finally,
                                                         target_context_depth);
}

Fragment StreamingFlowGraphBuilder::BranchIfTrue(
    TargetEntryInstr** then_entry,
    TargetEntryInstr** otherwise_entry,
    bool negate) {
  return flow_graph_builder_->BranchIfTrue(then_entry, otherwise_entry, negate);
}

Fragment StreamingFlowGraphBuilder::BranchIfEqual(
    TargetEntryInstr** then_entry,
    TargetEntryInstr** otherwise_entry,
    bool negate) {
  return flow_graph_builder_->BranchIfEqual(then_entry, otherwise_entry,
                                            negate);
}

Fragment StreamingFlowGraphBuilder::BranchIfNull(
    TargetEntryInstr** then_entry,
    TargetEntryInstr** otherwise_entry,
    bool negate) {
  return flow_graph_builder_->BranchIfNull(then_entry, otherwise_entry, negate);
}

Fragment StreamingFlowGraphBuilder::CatchBlockEntry(const Array& handler_types,
                                                    intptr_t handler_index,
                                                    bool needs_stacktrace) {
  return flow_graph_builder_->CatchBlockEntry(handler_types, handler_index,
                                              needs_stacktrace);
}

Fragment StreamingFlowGraphBuilder::TryCatch(int try_handler_index) {
  return flow_graph_builder_->TryCatch(try_handler_index);
}

Fragment StreamingFlowGraphBuilder::Drop() {
  return flow_graph_builder_->Drop();
}

Fragment StreamingFlowGraphBuilder::DropTempsPreserveTop(
    intptr_t num_temps_to_drop) {
  return flow_graph_builder_->DropTempsPreserveTop(num_temps_to_drop);
}

Fragment StreamingFlowGraphBuilder::NullConstant() {
  return flow_graph_builder_->NullConstant();
}

JoinEntryInstr* StreamingFlowGraphBuilder::BuildJoinEntry() {
  return flow_graph_builder_->BuildJoinEntry();
}

JoinEntryInstr* StreamingFlowGraphBuilder::BuildJoinEntry(intptr_t try_index) {
  return flow_graph_builder_->BuildJoinEntry(try_index);
}

Fragment StreamingFlowGraphBuilder::Goto(JoinEntryInstr* destination) {
  return flow_graph_builder_->Goto(destination);
}

Fragment StreamingFlowGraphBuilder::BuildImplicitClosureCreation(
    const Function& target) {
  return flow_graph_builder_->BuildImplicitClosureCreation(target);
}

Fragment StreamingFlowGraphBuilder::CheckBooleanInCheckedMode() {
  return flow_graph_builder_->CheckBooleanInCheckedMode();
}

Fragment StreamingFlowGraphBuilder::CheckAssignableInCheckedMode(
    const AbstractType& dst_type,
    const String& dst_name) {
  return flow_graph_builder_->CheckAssignableInCheckedMode(dst_type, dst_name);
}

Fragment StreamingFlowGraphBuilder::CheckVariableTypeInCheckedMode(
    intptr_t variable_kernel_position) {
  if (I->type_checks()) {
    LocalVariable* variable = LookupVariable(variable_kernel_position);
    return flow_graph_builder_->CheckVariableTypeInCheckedMode(
        variable->type(), variable->name());
  }
  return Fragment();
}

Fragment StreamingFlowGraphBuilder::CheckVariableTypeInCheckedMode(
    const AbstractType& dst_type,
    const String& name_symbol) {
  return flow_graph_builder_->CheckVariableTypeInCheckedMode(dst_type,
                                                             name_symbol);
}

Fragment StreamingFlowGraphBuilder::EnterScope(
    intptr_t kernel_offset,
    intptr_t* num_context_variables) {
  return flow_graph_builder_->EnterScope(kernel_offset, num_context_variables);
}

Fragment StreamingFlowGraphBuilder::ExitScope(intptr_t kernel_offset) {
  return flow_graph_builder_->ExitScope(kernel_offset);
}

Fragment StreamingFlowGraphBuilder::TranslateCondition(bool* negate) {
  *negate = PeekTag() == kNot;
  if (*negate) {
    SkipBytes(1);  // Skip Not tag, thus go directly to the inner expression.
  }
  Fragment instructions = BuildExpression();  // read expression.
  instructions += CheckBooleanInCheckedMode();
  return instructions;
}

const TypeArguments& StreamingFlowGraphBuilder::BuildTypeArguments() {
  ReadUInt();                               // read arguments count.
  intptr_t type_count = ReadListLength();   // read type count.
  return T.BuildTypeArguments(type_count);  // read types.
}

Fragment StreamingFlowGraphBuilder::BuildArguments(Array* argument_names,
                                                   intptr_t* argument_count,
                                                   bool skip_push_arguments,
                                                   bool do_drop) {
  intptr_t dummy;
  if (argument_count == NULL) argument_count = &dummy;
  *argument_count = ReadUInt();  // read arguments count.

  // List of types.
  SkipListOfDartTypes();  // read list of types.

  return BuildArgumentsFromActualArguments(argument_names, skip_push_arguments,
                                           do_drop);
}

Fragment StreamingFlowGraphBuilder::BuildArgumentsFromActualArguments(
    Array* argument_names,
    bool skip_push_arguments,
    bool do_drop) {
  Fragment instructions;

  // List of positional.
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    instructions += BuildExpression();  // read ith expression.
    if (!skip_push_arguments) instructions += PushArgument();
    if (do_drop) instructions += Drop();
  }

  // List of named.
  list_length = ReadListLength();  // read list length.
  if (argument_names != NULL && list_length > 0) {
    *argument_names ^= Array::New(list_length, Heap::kOld);
  }
  for (intptr_t i = 0; i < list_length; ++i) {
    String& name = H.DartSymbol(ReadStringReference());  // read ith name index.
    instructions += BuildExpression();                   // read ith expression.
    if (!skip_push_arguments) instructions += PushArgument();
    if (do_drop) instructions += Drop();
    if (argument_names != NULL) {
      argument_names->SetAt(i, name);
    }
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildInvalidExpression(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  // The frontend will take care of emitting normal errors (like
  // [NoSuchMethodError]s) and only emit [InvalidExpression]s in very special
  // situations (e.g. an invalid annotation).
  return ThrowNoSuchMethodError();
}

Fragment StreamingFlowGraphBuilder::BuildVariableGet(TokenPosition* position) {
  (position != NULL) ? * position = ReadPosition()
                     : ReadPosition();             // read position.
  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  ReadUInt();              // read relative variable index.
  SkipOptionalDartType();  // read promoted type.

  return LoadLocal(LookupVariable(variable_kernel_position));
}

Fragment StreamingFlowGraphBuilder::BuildVariableGet(uint8_t payload,
                                                     TokenPosition* position) {
  (position != NULL) ? * position = ReadPosition()
                     : ReadPosition();             // read position.
  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  return LoadLocal(LookupVariable(variable_kernel_position));
}

Fragment StreamingFlowGraphBuilder::BuildVariableSet(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  ReadUInt();                                 // read relative variable index.
  Fragment instructions = BuildExpression();  // read expression.

  if (NeedsDebugStepCheck(stack(), position)) {
    instructions = DebugStepCheck(position) + instructions;
  }
  instructions += CheckVariableTypeInCheckedMode(variable_kernel_position);
  instructions +=
      StoreLocal(position, LookupVariable(variable_kernel_position));
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildVariableSet(uint8_t payload,
                                                     TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  intptr_t variable_kernel_position = ReadUInt();  // read kernel position.
  Fragment instructions = BuildExpression();       // read expression.

  if (NeedsDebugStepCheck(stack(), position)) {
    instructions = DebugStepCheck(position) + instructions;
  }
  instructions += CheckVariableTypeInCheckedMode(variable_kernel_position);
  instructions +=
      StoreLocal(position, LookupVariable(variable_kernel_position));

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildPropertyGet(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForPropertyGet(offset);

  ReadFlags();  // read flags

  Fragment instructions = BuildExpression();  // read receiver.

  LocalVariable* receiver = NULL;
  if (direct_call.check_receiver_for_null_) {
    // Duplicate receiver for CheckNull before it is consumed by PushArgument.
    receiver = MakeTemporary();
    instructions += LoadLocal(receiver);
  }

  instructions += PushArgument();

  const String& getter_name = ReadNameAsGetterName();  // read name.

  const Function* interface_target = &Function::null_function();
  const NameIndex itarget_name =
      ReadCanonicalNameReference();  // read interface_target_reference.
  if (FLAG_experimental_strong_mode && !H.IsRoot(itarget_name) &&
      (H.IsGetter(itarget_name) || H.IsField(itarget_name))) {
    interface_target = &Function::ZoneHandle(
        Z, LookupMethodByMember(itarget_name, H.DartGetterName(itarget_name)));
    ASSERT(getter_name.raw() == interface_target->name());
  }

  if (direct_call.check_receiver_for_null_) {
    instructions += CheckNull(TokenPosition::kNoSource, receiver);
  }

  if (!direct_call.target_.IsNull()) {
    ASSERT(FLAG_precompiled_mode);
    instructions +=
        StaticCall(position, direct_call.target_, 1, ICData::kNoRebind);
  } else {
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 1;
    instructions +=
        InstanceCall(position, getter_name, Token::kGET, kTypeArgsLen, 1,
                     Array::null_array(), kNumArgsChecked, *interface_target);
  }

  if (direct_call.check_receiver_for_null_) {
    instructions += DropTempsPreserveTop(1);  // Drop receiver, preserve result.
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildPropertySet(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForPropertySet(offset);

  Fragment instructions(NullConstant());
  LocalVariable* variable = MakeTemporary();

  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  instructions += BuildExpression();  // read receiver.

  LocalVariable* receiver = NULL;
  if (direct_call.check_receiver_for_null_) {
    // Duplicate receiver for CheckNull before it is consumed by PushArgument.
    receiver = MakeTemporary();
    instructions += LoadLocal(receiver);
  }

  instructions += PushArgument();

  const String& setter_name = ReadNameAsSetterName();  // read name.

  instructions += BuildExpression();  // read value.
  instructions += StoreLocal(TokenPosition::kNoSource, variable);
  instructions += PushArgument();

  const Function* interface_target = &Function::null_function();
  const NameIndex itarget_name =
      ReadCanonicalNameReference();  // read interface_target_reference.
  if (FLAG_experimental_strong_mode && !H.IsRoot(itarget_name)) {
    interface_target = &Function::ZoneHandle(
        Z, LookupMethodByMember(itarget_name, H.DartSetterName(itarget_name)));
    ASSERT(setter_name.raw() == interface_target->name());
  }

  if (direct_call.check_receiver_for_null_) {
    instructions += CheckNull(position, receiver);
  }

  if (!direct_call.target_.IsNull()) {
    ASSERT(FLAG_precompiled_mode);
    instructions +=
        StaticCall(position, direct_call.target_, 2, ICData::kNoRebind);
  } else {
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 1;
    instructions +=
        InstanceCall(position, setter_name, Token::kSET, kTypeArgsLen, 2,
                     Array::null_array(), kNumArgsChecked, *interface_target);
  }

  instructions += Drop();  // Drop result of the setter invocation.

  if (direct_call.check_receiver_for_null_) {
    instructions += Drop();  // Drop receiver.
  }

  return instructions;
}

static Function& GetNoSuchMethodOrDie(Zone* zone, const Class& klass) {
  Function& nsm_function = Function::Handle(zone);
  Class& iterate_klass = Class::Handle(zone, klass.raw());
  while (!iterate_klass.IsNull()) {
    nsm_function = iterate_klass.LookupDynamicFunction(Symbols::NoSuchMethod());
    if (!nsm_function.IsNull() && nsm_function.NumParameters() == 2 &&
        nsm_function.NumTypeParameters() == 0) {
      break;
    }
    iterate_klass = iterate_klass.SuperClass();
  }
  // We are guaranteed to find noSuchMethod of class Object.
  ASSERT(!nsm_function.IsNull());

  return nsm_function;
}

// Note, that this will always mark `super` flag to true.
Fragment StreamingFlowGraphBuilder::BuildAllocateInvocationMirrorCall(
    TokenPosition position,
    const String& name,
    intptr_t num_type_arguments,
    intptr_t num_arguments,
    const Array& argument_names,
    LocalVariable* actuals_array,
    Fragment build_rest_of_actuals) {
  Fragment instructions;

  // Populate array containing the actual arguments. Just add [this] here.
  instructions += LoadLocal(actuals_array);                      // array
  instructions += IntConstant(num_type_arguments == 0 ? 0 : 1);  // index
  instructions += LoadLocal(scopes()->this_variable);            // receiver
  instructions += StoreIndexed(kArrayCid);
  instructions += Drop();  // dispose of stored value
  instructions += build_rest_of_actuals;

  // First argument is receiver.
  instructions += LoadLocal(scopes()->this_variable);
  instructions += PushArgument();

  // Push the arguments for allocating the invocation mirror:
  //   - the name.
  instructions += Constant(String::ZoneHandle(Z, name.raw()));
  instructions += PushArgument();

  //   - the arguments descriptor.
  const Array& args_descriptor =
      Array::Handle(Z, ArgumentsDescriptor::New(num_type_arguments,
                                                num_arguments, argument_names));
  instructions += Constant(Array::ZoneHandle(Z, args_descriptor.raw()));
  instructions += PushArgument();

  //   - an array containing the actual arguments.
  instructions += LoadLocal(actuals_array);
  instructions += PushArgument();

  //   - [true] indicating this is a `super` NoSuchMethod.
  instructions += Constant(Bool::True());
  instructions += PushArgument();

  const Class& mirror_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::InvocationMirror()));
  ASSERT(!mirror_class.IsNull());
  const Function& allocation_function = Function::ZoneHandle(
      Z, mirror_class.LookupStaticFunction(
             Library::PrivateCoreLibName(Symbols::AllocateInvocationMirror())));
  ASSERT(!allocation_function.IsNull());
  instructions += StaticCall(position, allocation_function,
                             /* argument_count = */ 4, ICData::kStatic);
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildSuperPropertyGet(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Class& klass = GetSuperOrDie();

  StringIndex name_index = ReadStringReference();  // read name index.
  NameIndex library_reference =
      ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_')
          ? ReadCanonicalNameReference()  // read library index.
          : NameIndex();
  const String& getter_name = H.DartGetterName(library_reference, name_index);
  const String& method_name = H.DartMethodName(library_reference, name_index);

  SkipCanonicalNameReference();  // skip target_reference.

  // Search the superclass chain for the selector looking for either getter or
  // method.
  Function& function = Function::Handle(Z);
  while (!klass.IsNull()) {
    function = klass.LookupDynamicFunction(method_name);
    if (!function.IsNull()) {
      Function& target =
          Function::ZoneHandle(Z, function.ImplicitClosureFunction());
      ASSERT(!target.IsNull());
      // Generate inline code for allocation closure object with context
      // which captures `this`.
      return BuildImplicitClosureCreation(target);
    }
    function = klass.LookupDynamicFunction(getter_name);
    if (!function.IsNull()) break;
    klass = klass.SuperClass();
  }

  Fragment instructions;
  if (klass.IsNull()) {
    instructions +=
        Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
    instructions += IntConstant(1);  // array size
    instructions += CreateArray();
    LocalVariable* actuals_array = MakeTemporary();

    Class& parent_klass = GetSuperOrDie();

    instructions += BuildAllocateInvocationMirrorCall(
        position, getter_name,
        /* num_type_arguments = */ 0,
        /* num_arguments = */ 1,
        /* argument_names = */ Object::empty_array(), actuals_array,
        /* build_rest_of_actuals = */ Fragment());
    instructions += PushArgument();  // second argument is invocation mirror

    Function& nsm_function = GetNoSuchMethodOrDie(Z, parent_klass);
    instructions +=
        StaticCall(position, Function::ZoneHandle(Z, nsm_function.raw()),
                   /* argument_count = */ 2, ICData::kNSMDispatch);
    instructions += DropTempsPreserveTop(1);  // Drop array
  } else {
    ASSERT(!klass.IsNull());
    ASSERT(!function.IsNull());

    instructions += LoadLocal(scopes()->this_variable);
    instructions += PushArgument();

    instructions +=
        StaticCall(position, Function::ZoneHandle(Z, function.raw()),
                   /* argument_count = */ 1, ICData::kSuper);
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildSuperPropertySet(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Class& klass = GetSuperOrDie();

  const String& setter_name = ReadNameAsSetterName();  // read name.

  Function& function = FindMatchingFunctionAnyArgs(klass, setter_name);

  Fragment instructions(NullConstant());
  LocalVariable* value = MakeTemporary();  // this holds RHS value

  if (function.IsNull()) {
    instructions +=
        Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
    instructions += IntConstant(2);  // array size
    instructions += CreateArray();
    LocalVariable* actuals_array = MakeTemporary();

    Fragment build_rest_of_actuals;
    build_rest_of_actuals += LoadLocal(actuals_array);  // array
    build_rest_of_actuals += IntConstant(1);            // index
    build_rest_of_actuals += BuildExpression();         // value.
    build_rest_of_actuals += StoreLocal(position, value);
    build_rest_of_actuals += StoreIndexed(kArrayCid);
    build_rest_of_actuals += Drop();  // dispose of stored value

    instructions += BuildAllocateInvocationMirrorCall(
        position, setter_name, /* num_type_arguments = */ 0,
        /* num_arguments = */ 2,
        /* argument_names = */ Object::empty_array(), actuals_array,
        build_rest_of_actuals);
    instructions += PushArgument();  // second argument - invocation mirror

    SkipCanonicalNameReference();  // skip target_reference.

    Function& nsm_function = GetNoSuchMethodOrDie(Z, klass);
    instructions +=
        StaticCall(position, Function::ZoneHandle(Z, nsm_function.raw()),
                   /* argument_count = */ 2, ICData::kNSMDispatch);
    instructions += Drop();  // Drop result of NoSuchMethod invocation
    instructions += Drop();  // Drop array
  } else {
    // receiver
    instructions += LoadLocal(scopes()->this_variable);
    instructions += PushArgument();

    instructions += BuildExpression();  // read value.
    instructions += StoreLocal(position, value);
    instructions += PushArgument();

    SkipCanonicalNameReference();  // skip target_reference.

    instructions +=
        StaticCall(position, Function::ZoneHandle(Z, function.raw()),
                   /* argument_count = */ 2, ICData::kSuper);
    instructions += Drop();  // Drop result of the setter invocation.
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildDirectPropertyGet(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  ReadFlags();  // read flags.

  const Tag receiver_tag = PeekTag();         // peek tag for receiver.
  Fragment instructions = BuildExpression();  // read receiver.
  const NameIndex kernel_name =
      ReadCanonicalNameReference();  // read target_reference.

  Function& target = Function::ZoneHandle(Z);
  if (H.IsProcedure(kernel_name)) {
    if (H.IsGetter(kernel_name)) {
      target = LookupMethodByMember(kernel_name, H.DartGetterName(kernel_name));
    } else if (receiver_tag == kThisExpression) {
      // Undo stack change for the BuildExpression.
      Pop();

      target = LookupMethodByMember(kernel_name, H.DartMethodName(kernel_name));
      target = target.ImplicitClosureFunction();
      ASSERT(!target.IsNull());

      // Generate inline code for allocating closure object with context which
      // captures `this`.
      return BuildImplicitClosureCreation(target);
    } else {
      // Need to create implicit closure (tear-off), receiver != this.
      // Ensure method extractor exists and call it directly.
      const Function& target_method = Function::ZoneHandle(
          Z, LookupMethodByMember(kernel_name, H.DartMethodName(kernel_name)));
      const String& getter_name = H.DartGetterName(kernel_name);
      target = target_method.GetMethodExtractor(getter_name);
    }
  } else {
    ASSERT(H.IsField(kernel_name));
    const String& getter_name = H.DartGetterName(kernel_name);
    target = LookupMethodByMember(kernel_name, getter_name);
    ASSERT(target.IsGetterFunction() || target.IsImplicitGetterFunction());
  }

  instructions += PushArgument();
  // Static calls are marked as "no-rebind", which is currently safe because
  // DirectPropertyGet are only used in enums (index in toString) and enums
  // can't change their structure during hot reload.
  // If there are other sources of DirectPropertyGet in the future, this code
  // have to be adjusted.
  return instructions + StaticCall(position, target, 1, ICData::kNoRebind);
}

Fragment StreamingFlowGraphBuilder::BuildDirectPropertySet(TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions(NullConstant());
  LocalVariable* value = MakeTemporary();

  instructions += BuildExpression();  // read receiver.
  instructions += PushArgument();

  const NameIndex target_reference =
      ReadCanonicalNameReference();  // read target_reference.
  const String& method_name = H.DartSetterName(target_reference);
  const Function& target = Function::ZoneHandle(
      Z, LookupMethodByMember(target_reference, method_name));
  ASSERT(target.IsSetterFunction() || target.IsImplicitSetterFunction());

  instructions += BuildExpression();  // read value.
  instructions += StoreLocal(TokenPosition::kNoSource, value);
  instructions += PushArgument();

  // Static calls are marked as "no-rebind", which is currently safe because
  // DirectPropertyGet are only used in enums (index in toString) and enums
  // can't change their structure during hot reload.
  // If there are other sources of DirectPropertyGet in the future, this code
  // have to be adjusted.
  instructions += StaticCall(position, target, 2, ICData::kNoRebind);

  return instructions + Drop();
}

Fragment StreamingFlowGraphBuilder::BuildStaticGet(TokenPosition* p) {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  NameIndex target = ReadCanonicalNameReference();  // read target_reference.

  if (H.IsField(target)) {
    const Field& field =
        Field::ZoneHandle(Z, H.LookupFieldByKernelField(target));
    if (field.is_const()) {
      return Constant(constant_evaluator_.EvaluateExpression(offset));
    } else {
      const Class& owner = Class::Handle(Z, field.Owner());
      const String& getter_name = H.DartGetterName(target);
      const Function& getter =
          Function::ZoneHandle(Z, owner.LookupStaticFunction(getter_name));
      if (getter.IsNull() || !field.has_initializer()) {
        Fragment instructions = Constant(field);
        return instructions + LoadStaticField();
      } else {
        return StaticCall(position, getter, 0, ICData::kStatic);
      }
    }
  } else {
    const Function& function =
        Function::ZoneHandle(Z, H.LookupStaticMethodByKernelProcedure(target));

    if (H.IsGetter(target)) {
      return StaticCall(position, function, 0, ICData::kStatic);
    } else if (H.IsMethod(target)) {
      return Constant(constant_evaluator_.EvaluateExpression(offset));
    } else {
      UNIMPLEMENTED();
    }
  }

  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildStaticSet(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  NameIndex target = ReadCanonicalNameReference();  // read target_reference.

  if (H.IsField(target)) {
    const Field& field =
        Field::ZoneHandle(Z, H.LookupFieldByKernelField(target));
    const AbstractType& dst_type = AbstractType::ZoneHandle(Z, field.type());
    Fragment instructions = BuildExpression();  // read expression.
    if (NeedsDebugStepCheck(stack(), position)) {
      instructions = DebugStepCheck(position) + instructions;
    }
    instructions += CheckAssignableInCheckedMode(
        dst_type, String::ZoneHandle(Z, field.name()));
    LocalVariable* variable = MakeTemporary();
    instructions += LoadLocal(variable);
    return instructions + StoreStaticField(position, field);
  } else {
    ASSERT(H.IsProcedure(target));

    // Evaluate the expression on the right hand side.
    Fragment instructions = BuildExpression();  // read expression.
    LocalVariable* variable = MakeTemporary();

    // Prepare argument.
    instructions += LoadLocal(variable);
    instructions += PushArgument();

    // Invoke the setter function.
    const Function& function =
        Function::ZoneHandle(Z, H.LookupStaticMethodByKernelProcedure(target));
    instructions += StaticCall(position, function, 1, ICData::kStatic);

    // Drop the unused result & leave the stored value on the stack.
    return instructions + Drop();
  }
}

static bool IsNumberLiteral(Tag tag) {
  return tag == kNegativeIntLiteral || tag == kPositiveIntLiteral ||
         tag == kSpecialIntLiteral || tag == kDoubleLiteral;
}

Fragment StreamingFlowGraphBuilder::BuildMethodInvocation(TokenPosition* p) {
  const intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const DirectCallMetadata direct_call =
      direct_call_metadata_helper_.GetDirectTargetForMethodInvocation(offset);

  ReadFlags();  // read flags.

  const Tag receiver_tag = PeekTag();  // peek tag for receiver.
  if (IsNumberLiteral(receiver_tag) &&
      (!optimizing() || constant_evaluator_.IsCached(offset))) {
    const intptr_t before_branch_offset = ReaderOffset();

    SkipExpression();  // read receiver (it's just a number literal).

    const String& name = ReadNameAsMethodName();  // read name.
    const Token::Kind token_kind =
        MethodTokenRecognizer::RecognizeTokenKind(name);
    intptr_t argument_count = PeekArgumentsCount() + 1;

    if ((argument_count == 1) && (token_kind == Token::kNEGATE)) {
      const Object& result = constant_evaluator_.EvaluateExpressionSafe(offset);
      if (!result.IsError()) {
        SkipArguments();               // read arguments.
        SkipCanonicalNameReference();  // read interface_target_reference.
        return Constant(result);
      }
    } else if ((argument_count == 2) &&
               Token::IsBinaryArithmeticOperator(token_kind) &&
               IsNumberLiteral(PeekArgumentsFirstPositionalTag())) {
      const Object& result = constant_evaluator_.EvaluateExpressionSafe(offset);
      if (!result.IsError()) {
        SkipArguments();               // read arguments.
        SkipCanonicalNameReference();  // read interface_target_reference.
        return Constant(result);
      }
    }

    SetOffset(before_branch_offset);
  }

  Fragment instructions;

  intptr_t type_args_len = 0;
  LocalVariable* type_arguments_temp = NULL;
  if (I->reify_generic_functions()) {
    AlternativeReadingScope alt(reader_);
    SkipExpression();                         // skip receiver
    SkipName();                               // skip method name
    ReadUInt();                               // read argument count.
    intptr_t list_length = ReadListLength();  // read types list length.
    if (list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(list_length);  // read types.
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      if (direct_call.check_receiver_for_null_) {
        // Don't yet push type arguments if we need to check receiver for null.
        // In this case receiver will be duplicated so instead of pushing
        // type arguments here we need to push it between receiver_temp
        // and actual receiver. See the code below.
        type_arguments_temp = MakeTemporary();
      } else {
        instructions += PushArgument();
      }
    }
    type_args_len = list_length;
  }

  instructions += BuildExpression();  // read receiver.

  const String& name = ReadNameAsMethodName();  // read name.
  const Token::Kind token_kind =
      MethodTokenRecognizer::RecognizeTokenKind(name);

  // Detect comparison with null.
  if ((token_kind == Token::kEQ || token_kind == Token::kNE) &&
      PeekArgumentsCount() == 1 &&
      (receiver_tag == kNullLiteral ||
       PeekArgumentsFirstPositionalTag() == kNullLiteral)) {
    ASSERT(type_args_len == 0);
    // "==" or "!=" with null on either side.
    instructions += BuildArguments(NULL, NULL, true);  // read arguments.
    SkipCanonicalNameReference();  // read interface_target_reference.
    Token::Kind strict_cmp_kind =
        token_kind == Token::kEQ ? Token::kEQ_STRICT : Token::kNE_STRICT;
    return instructions +
           StrictCompare(strict_cmp_kind, /*number_check = */ true);
  }

  LocalVariable* receiver_temp = NULL;
  if (direct_call.check_receiver_for_null_) {
    // Duplicate receiver for CheckNull before it is consumed by PushArgument.
    receiver_temp = MakeTemporary();
    if (type_arguments_temp != NULL) {
      // If call has type arguments then push them before pushing the receiver.
      // The stack will contain:
      //
      //   [type_arguments_temp][receiver_temp][type_arguments][receiver] ...
      //
      instructions += LoadLocal(type_arguments_temp);
      instructions += PushArgument();
    }
    instructions += LoadLocal(receiver_temp);
  }

  instructions += PushArgument();  // push receiver as argument.

  Array& argument_names = Array::ZoneHandle(Z);
  intptr_t argument_count;
  instructions +=
      BuildArguments(&argument_names, &argument_count);  // read arguments.
  ++argument_count;                                      // include receiver

  intptr_t checked_argument_count = 1;
  // If we have a special operation (e.g. +/-/==) we mark both arguments as
  // to be checked.
  if (token_kind != Token::kILLEGAL) {
    ASSERT(argument_count <= 2);
    checked_argument_count = argument_count;
  }

  const Function* interface_target = &Function::null_function();
  const NameIndex itarget_name =
      ReadCanonicalNameReference();  // read interface_target_reference.
  if (FLAG_experimental_strong_mode && !H.IsRoot(itarget_name) &&
      !H.IsField(itarget_name)) {
    interface_target = &Function::ZoneHandle(
        Z,
        LookupMethodByMember(itarget_name, H.DartProcedureName(itarget_name)));
    ASSERT((name.raw() == interface_target->name()) ||
           (interface_target->IsGetterFunction() &&
            Field::GetterSymbol(name) == interface_target->name()));
  }

  if (direct_call.check_receiver_for_null_) {
    instructions += CheckNull(position, receiver_temp);
  }

  if (!direct_call.target_.IsNull()) {
    ASSERT(FLAG_precompiled_mode);
    instructions +=
        StaticCall(position, direct_call.target_, argument_count,
                   argument_names, ICData::kNoRebind, type_args_len);
  } else {
    instructions +=
        InstanceCall(position, name, token_kind, type_args_len, argument_count,
                     argument_names, checked_argument_count, *interface_target);
  }

  // Drop temporaries preserving result on the top of the stack.
  ASSERT((receiver_temp != NULL) || (type_arguments_temp == NULL));
  if (receiver_temp != NULL) {
    const intptr_t num_temps =
        (receiver_temp != NULL ? 1 : 0) + (type_arguments_temp != NULL ? 1 : 0);
    instructions += DropTempsPreserveTop(num_temps);
  }

  // Later optimization passes assume that result of a x.[]=(...) call is not
  // used. We must guarantee this invariant because violation will lead to an
  // illegal IL once we replace x.[]=(...) with a sequence that does not
  // actually produce any value. See http://dartbug.com/29135 for more details.
  if (name.raw() == Symbols::AssignIndexToken().raw()) {
    instructions += Drop();
    instructions += NullConstant();
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildDirectMethodInvocation(
    TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read offset.
  if (p != NULL) *p = position;

  ReadFlags();  // read flags.

  Tag receiver_tag = PeekTag();  // peek tag for receiver.

  Fragment instructions;
  intptr_t type_args_len = 0;
  if (I->reify_generic_functions()) {
    AlternativeReadingScope alt(reader_);
    SkipExpression();                         // skip receiver
    ReadCanonicalNameReference();             // skip target reference
    ReadUInt();                               // read argument count.
    intptr_t list_length = ReadListLength();  // read types list length.
    if (list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(list_length);  // read types.
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      instructions += PushArgument();
    }
    type_args_len = list_length;
  }

  instructions += BuildExpression();  // read receiver.

  NameIndex kernel_name =
      ReadCanonicalNameReference();  // read target_reference.
  const String& method_name = H.DartProcedureName(kernel_name);
  const Token::Kind token_kind =
      MethodTokenRecognizer::RecognizeTokenKind(method_name);

  // Detect comparison with null.
  if ((token_kind == Token::kEQ || token_kind == Token::kNE) &&
      PeekArgumentsCount() == 1 &&
      (receiver_tag == kNullLiteral ||
       PeekArgumentsFirstPositionalTag() == kNullLiteral)) {
    ASSERT(type_args_len == 0);
    // "==" or "!=" with null on either side.
    instructions += BuildArguments(NULL, NULL, true);  // read arguments.
    Token::Kind strict_cmp_kind =
        token_kind == Token::kEQ ? Token::kEQ_STRICT : Token::kNE_STRICT;
    return instructions +
           StrictCompare(strict_cmp_kind, /*number_check = */ true);
  }

  instructions += PushArgument();  // push receiver as argument.

  const Function& target =
      Function::ZoneHandle(Z, LookupMethodByMember(kernel_name, method_name));

  Array& argument_names = Array::ZoneHandle(Z);
  intptr_t argument_count;
  instructions +=
      BuildArguments(&argument_names, &argument_count);  // read arguments.
  ++argument_count;
  return instructions + StaticCall(position, target, argument_count,
                                   argument_names, ICData::kNoRebind,
                                   type_args_len);
}

Fragment StreamingFlowGraphBuilder::BuildSuperMethodInvocation(
    TokenPosition* p) {
  const TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  intptr_t type_args_len = 0;
  if (I->reify_generic_functions()) {
    AlternativeReadingScope alt(reader_);
    SkipName();                        // skip method name
    ReadUInt();                        // read argument count.
    type_args_len = ReadListLength();  // read types list length.
  }

  Class& klass = GetSuperOrDie();

  // Search the superclass chain for the selector.
  const String& method_name = ReadNameAsMethodName();  // read name.

  // Figure out selector signature.
  intptr_t argument_count;
  Array& argument_names = Array::Handle(Z);
  {
    AlternativeReadingScope alt(reader_);
    argument_count = ReadUInt();
    SkipListOfDartTypes();

    SkipListOfExpressions();
    intptr_t named_list_length = ReadListLength();
    argument_names ^= Array::New(named_list_length);
    for (intptr_t i = 0; i < named_list_length; i++) {
      const String& arg_name = H.DartSymbol(ReadStringReference());
      argument_names.SetAt(i, arg_name);
      SkipExpression();
    }
  }

  Function& function = FindMatchingFunction(
      klass, method_name, type_args_len,
      argument_count + 1 /* account for 'this' */, argument_names);

  if (function.IsNull()) {
    ReadUInt();  // argument count
    intptr_t type_list_length = ReadListLength();

    Fragment instructions;
    instructions +=
        Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
    instructions += IntConstant(argument_count + 1 /* this */ +
                                (type_list_length == 0 ? 0 : 1));  // array size
    instructions += CreateArray();
    LocalVariable* actuals_array = MakeTemporary();

    // Call allocationInvocationMirror to get instance of Invocation.
    Fragment build_rest_of_actuals;
    intptr_t actuals_array_index = 0;
    if (type_list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(type_list_length);
      build_rest_of_actuals += LoadLocal(actuals_array);
      build_rest_of_actuals += IntConstant(actuals_array_index);
      build_rest_of_actuals +=
          TranslateInstantiatedTypeArguments(type_arguments);
      build_rest_of_actuals += StoreIndexed(kArrayCid);
      build_rest_of_actuals += Drop();  // dispose of stored value
      ++actuals_array_index;
    }

    ++actuals_array_index;  // account for 'this'.
    // Read arguments
    intptr_t list_length = ReadListLength();
    intptr_t i = 0;
    while (i < list_length) {
      build_rest_of_actuals += LoadLocal(actuals_array);              // array
      build_rest_of_actuals += IntConstant(actuals_array_index + i);  // index
      build_rest_of_actuals += BuildExpression();                     // value.
      build_rest_of_actuals += StoreIndexed(kArrayCid);
      build_rest_of_actuals += Drop();  // dispose of stored value
      ++i;
    }
    // Read named arguments
    intptr_t named_list_length = ReadListLength();
    if (named_list_length > 0) {
      ASSERT(argument_count == list_length + named_list_length);
      while ((i - list_length) < named_list_length) {
        SkipStringReference();
        build_rest_of_actuals += LoadLocal(actuals_array);              // array
        build_rest_of_actuals += IntConstant(i + actuals_array_index);  // index
        build_rest_of_actuals += BuildExpression();  // value.
        build_rest_of_actuals += StoreIndexed(kArrayCid);
        build_rest_of_actuals += Drop();  // dispose of stored value
        ++i;
      }
    }
    instructions += BuildAllocateInvocationMirrorCall(
        position, method_name, type_list_length,
        /* num_arguments = */ argument_count + 1, argument_names, actuals_array,
        build_rest_of_actuals);
    instructions += PushArgument();  // second argument - invocation mirror

    SkipCanonicalNameReference();  //  skip target_reference.

    Function& nsm_function = GetNoSuchMethodOrDie(Z, klass);
    instructions += StaticCall(TokenPosition::kNoSource,
                               Function::ZoneHandle(Z, nsm_function.raw()),
                               /* argument_count = */ 2, ICData::kNSMDispatch);
    instructions += DropTempsPreserveTop(1);  // Drop actuals_array temp.
    return instructions;
  } else {
    Fragment instructions;

    if (I->reify_generic_functions()) {
      AlternativeReadingScope alt(reader_);
      ReadUInt();                               // read argument count.
      intptr_t list_length = ReadListLength();  // read types list length.
      if (list_length > 0) {
        const TypeArguments& type_arguments =
            T.BuildTypeArguments(list_length);  // read types.
        instructions += TranslateInstantiatedTypeArguments(type_arguments);
        instructions += PushArgument();
      }
    }

    // receiver
    instructions += LoadLocal(scopes()->this_variable);
    instructions += PushArgument();

    Array& argument_names = Array::ZoneHandle(Z);
    intptr_t argument_count;
    instructions +=
        BuildArguments(&argument_names, &argument_count);  // read arguments.
    ++argument_count;                                      // include receiver
    SkipCanonicalNameReference();  // interfaceTargetReference
    return instructions + StaticCall(position,
                                     Function::ZoneHandle(Z, function.raw()),
                                     argument_count, argument_names,
                                     ICData::kSuper, type_args_len);
  }
}

Fragment StreamingFlowGraphBuilder::BuildStaticInvocation(bool is_const,
                                                          TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  NameIndex procedure_reference =
      ReadCanonicalNameReference();  // read procedure reference.
  intptr_t argument_count = PeekArgumentsCount();
  const Function& target = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(procedure_reference));
  const Class& klass = Class::ZoneHandle(Z, target.Owner());
  if (target.IsGenerativeConstructor() || target.IsFactory()) {
    // The VM requires a TypeArguments object as first parameter for
    // every factory constructor.
    ++argument_count;
  }

  Fragment instructions;
  LocalVariable* instance_variable = NULL;

  bool special_case_identical = klass.IsTopLevel() &&
                                (klass.library() == Library::CoreLibrary()) &&
                                (target.name() == Symbols::Identical().raw());

  // If we cross the Kernel -> VM core library boundary, a [StaticInvocation]
  // can appear, but the thing we're calling is not a static method, but a
  // factory constructor.
  // The `H.LookupStaticmethodByKernelProcedure` will potentially resolve to the
  // forwarded constructor.
  // In that case we'll make an instance and pass it as first argument.
  //
  // TODO(27590): Get rid of this after we're using core libraries compiled
  // into Kernel.
  intptr_t type_args_len = 0;
  if (target.IsGenerativeConstructor()) {
    if (klass.NumTypeArguments() > 0) {
      const TypeArguments& type_arguments =
          PeekArgumentsInstantiatedType(klass);
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      instructions += PushArgument();
      instructions += AllocateObject(position, klass, 1);
    } else {
      instructions += AllocateObject(position, klass, 0);
    }

    instance_variable = MakeTemporary();

    instructions += LoadLocal(instance_variable);
    instructions += PushArgument();
  } else if (target.IsFactory()) {
    // The VM requires currently a TypeArguments object as first parameter for
    // every factory constructor :-/ !
    //
    // TODO(27590): Get rid of this after we're using core libraries compiled
    // into Kernel.
    const TypeArguments& type_arguments = PeekArgumentsInstantiatedType(klass);
    instructions += TranslateInstantiatedTypeArguments(type_arguments);
    instructions += PushArgument();
  } else if (!special_case_identical && I->reify_generic_functions()) {
    AlternativeReadingScope alt(reader_);
    ReadUInt();                               // read argument count.
    intptr_t list_length = ReadListLength();  // read types list length.
    if (list_length > 0) {
      const TypeArguments& type_arguments =
          T.BuildTypeArguments(list_length);  // read types.
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      instructions += PushArgument();
    }
    type_args_len = list_length;
  }

  Array& argument_names = Array::ZoneHandle(Z);
  instructions += BuildArguments(&argument_names, NULL,
                                 special_case_identical);  // read arguments.
  ASSERT(target.AreValidArguments(type_args_len, argument_count, argument_names,
                                  NULL));

  // Special case identical(x, y) call.
  // TODO(27590) consider moving this into the inliner and force inline it
  // there.
  if (special_case_identical) {
    ASSERT(argument_count == 2);
    instructions += StrictCompare(Token::kEQ_STRICT, /*number_check=*/true);
  } else {
    instructions += StaticCall(position, target, argument_count, argument_names,
                               ICData::kStatic, type_args_len);
    if (target.IsGenerativeConstructor()) {
      // Drop the result of the constructor call and leave [instance_variable]
      // on top-of-stack.
      instructions += Drop();
    }
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildConstructorInvocation(
    bool is_const,
    TokenPosition* p) {
  if (is_const) {
    intptr_t offset = ReaderOffset() - 1;                 // Include the tag.
    (p != NULL) ? * p = ReadPosition() : ReadPosition();  // read position.

    SetOffset(offset);
    SkipExpression();  // read past this ConstructorInvocation.
    return Constant(constant_evaluator_.EvaluateConstructorInvocation(offset));
  }

  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  NameIndex kernel_name =
      ReadCanonicalNameReference();  // read target_reference.

  Class& klass = Class::ZoneHandle(
      Z, H.LookupClassByKernelClass(H.EnclosingName(kernel_name)));

  Fragment instructions;

  // Check for malbounded-ness of type.
  if (I->type_checks()) {
    intptr_t offset = ReaderOffset();

    const TypeArguments& type_arguments = BuildTypeArguments();

    AbstractType& type = AbstractType::Handle(
        Z, Type::New(klass, type_arguments, TokenPosition::kNoSource));
    type = ClassFinalizer::FinalizeType(klass, type);

    if (type.IsMalbounded()) {
      // Evaluate expressions for correctness.
      instructions +=
          BuildArgumentsFromActualArguments(NULL, false, /*do_drop*/ true);

      // Throw an error & keep the [Value] on the stack.
      instructions += ThrowTypeError();

      // Bail out early.
      return instructions;
    }

    SetOffset(offset);
  }

  if (klass.NumTypeArguments() > 0) {
    if (!klass.IsGeneric()) {
      Type& type = Type::ZoneHandle(Z, T.ReceiverType(klass).raw());

      // TODO(27590): Can we move this code into [ReceiverType]?
      type ^= ClassFinalizer::FinalizeType(*active_class()->klass, type,
                                           ClassFinalizer::kFinalize);
      ASSERT(!type.IsMalformedOrMalbounded());

      TypeArguments& canonicalized_type_arguments =
          TypeArguments::ZoneHandle(Z, type.arguments());
      canonicalized_type_arguments =
          canonicalized_type_arguments.Canonicalize();
      instructions += Constant(canonicalized_type_arguments);
    } else {
      const TypeArguments& type_arguments =
          PeekArgumentsInstantiatedType(klass);
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
    }

    instructions += PushArgument();
    instructions += AllocateObject(position, klass, 1);
  } else {
    instructions += AllocateObject(position, klass, 0);
  }
  LocalVariable* variable = MakeTemporary();

  instructions += LoadLocal(variable);
  instructions += PushArgument();

  Array& argument_names = Array::ZoneHandle(Z);
  intptr_t argument_count;
  instructions +=
      BuildArguments(&argument_names, &argument_count);  // read arguments.

  const Function& target = Function::ZoneHandle(
      Z, H.LookupConstructorByKernelConstructor(klass, kernel_name));
  ++argument_count;
  instructions += StaticCall(position, target, argument_count, argument_names,
                             ICData::kStatic);
  return instructions + Drop();
}

Fragment StreamingFlowGraphBuilder::BuildNot(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  Fragment instructions = BuildExpression();  // read expression.
  instructions += CheckBooleanInCheckedMode();
  instructions += BooleanNegate();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildLogicalExpression(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  bool negate;
  Fragment instructions = TranslateCondition(&negate);  // read left.

  TargetEntryInstr* right_entry;
  TargetEntryInstr* constant_entry;
  LogicalOperator op = static_cast<LogicalOperator>(ReadByte());

  if (op == kAnd) {
    instructions += BranchIfTrue(&right_entry, &constant_entry, negate);
  } else {
    instructions += BranchIfTrue(&constant_entry, &right_entry, negate);
  }

  Value* top = stack();
  Fragment right_fragment(right_entry);
  right_fragment += TranslateCondition(&negate);  // read right.

  right_fragment += Constant(Bool::True());
  right_fragment +=
      StrictCompare(negate ? Token::kNE_STRICT : Token::kEQ_STRICT);
  right_fragment += StoreLocal(TokenPosition::kNoSource,
                               parsed_function()->expression_temp_var());
  right_fragment += Drop();

  ASSERT(top == stack());
  Fragment constant_fragment(constant_entry);
  constant_fragment += Constant(Bool::Get(op == kOr));
  constant_fragment += StoreLocal(TokenPosition::kNoSource,
                                  parsed_function()->expression_temp_var());
  constant_fragment += Drop();

  JoinEntryInstr* join = BuildJoinEntry();
  right_fragment += Goto(join);
  constant_fragment += Goto(join);

  return Fragment(instructions.entry, join) +
         LoadLocal(parsed_function()->expression_temp_var());
}

Fragment StreamingFlowGraphBuilder::BuildConditionalExpression(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  bool negate;
  Fragment instructions = TranslateCondition(&negate);  // read condition.

  TargetEntryInstr* then_entry;
  TargetEntryInstr* otherwise_entry;
  instructions += BranchIfTrue(&then_entry, &otherwise_entry, negate);

  Value* top = stack();
  Fragment then_fragment(then_entry);
  then_fragment += BuildExpression();  // read then.
  then_fragment += StoreLocal(TokenPosition::kNoSource,
                              parsed_function()->expression_temp_var());
  then_fragment += Drop();
  ASSERT(stack() == top);

  Fragment otherwise_fragment(otherwise_entry);
  otherwise_fragment += BuildExpression();  // read otherwise.
  otherwise_fragment += StoreLocal(TokenPosition::kNoSource,
                                   parsed_function()->expression_temp_var());
  otherwise_fragment += Drop();
  ASSERT(stack() == top);

  JoinEntryInstr* join = BuildJoinEntry();
  then_fragment += Goto(join);
  otherwise_fragment += Goto(join);

  SkipOptionalDartType();  // read unused static type.

  return Fragment(instructions.entry, join) +
         LoadLocal(parsed_function()->expression_temp_var());
}

Fragment StreamingFlowGraphBuilder::BuildStringConcatenation(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  intptr_t length = ReadListLength();  // read list length.
  // Note: there will be "length" expressions.

  Fragment instructions;
  if (length == 1) {
    instructions += BuildExpression();  // read expression.
    instructions += StringInterpolateSingle(position);
  } else {
    // The type arguments for CreateArray.
    instructions += Constant(TypeArguments::ZoneHandle(Z));
    instructions += IntConstant(length);
    instructions += CreateArray();
    LocalVariable* array = MakeTemporary();

    for (intptr_t i = 0; i < length; ++i) {
      instructions += LoadLocal(array);
      instructions += IntConstant(i);
      instructions += BuildExpression();  // read ith expression.
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();
    }

    instructions += StringInterpolate(position);
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildIsExpression(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions = BuildExpression();  // read operand.

  const AbstractType& type = T.BuildType();  // read type.

  // The VM does not like an instanceOf call with a dynamic type. We need to
  // special case this situation.
  const Type& object_type = Type::Handle(Z, Type::ObjectType());

  if (type.IsMalformed()) {
    instructions += Drop();
    instructions += ThrowTypeError();
    return instructions;
  }

  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, NULL, NULL, Heap::kOld)) {
    // Evaluate the expression on the left but ignore it's result.
    instructions += Drop();

    // Let condition be always true.
    instructions += Constant(Bool::True());
  } else {
    instructions += PushArgument();

    // See if simple instanceOf is applicable.
    if (dart::FlowGraphBuilder::SimpleInstanceOfType(type)) {
      instructions += Constant(type);
      instructions += PushArgument();  // Type.
      instructions += InstanceCall(
          position, Library::PrivateCoreLibName(Symbols::_simpleInstanceOf()),
          Token::kIS, 2, 2);  // 2 checked arguments.
      return instructions;
    }

    if (!type.IsInstantiated(kCurrentClass)) {
      instructions += LoadInstantiatorTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Instantiator type arguments.

    if (!type.IsInstantiated(kFunctions)) {
      instructions += LoadFunctionTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Function type arguments.

    instructions += Constant(type);
    instructions += PushArgument();  // Type.

    instructions += InstanceCall(
        position, Library::PrivateCoreLibName(Symbols::_instanceOf()),
        Token::kIS, 4);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildAsExpression(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  uint8_t flags = ReadFlags();  // read flags.
  const bool is_type_error = (flags & (1 << 0)) != 0;

  Fragment instructions = BuildExpression();  // read operand.

  const AbstractType& type = T.BuildType();  // read type.

  // The VM does not like an Object_as call with a dynamic type. We need to
  // special case this situation.
  const Type& object_type = Type::Handle(Z, Type::ObjectType());

  if (type.IsMalformed()) {
    instructions += Drop();
    instructions += ThrowTypeError();
    return instructions;
  }

  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, NULL, NULL, Heap::kOld)) {
    // We already evaluated the operand on the left and just leave it there as
    // the result of the `obj as dynamic` expression.
  } else if (is_type_error) {
    instructions += LoadLocal(MakeTemporary());
    instructions +=
        flow_graph_builder_->AssertAssignable(type, Symbols::Empty());
    instructions += Drop();
  } else {
    instructions += PushArgument();

    if (!type.IsInstantiated(kCurrentClass)) {
      instructions += LoadInstantiatorTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Instantiator type arguments.

    if (!type.IsInstantiated(kFunctions)) {
      instructions += LoadFunctionTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Function type arguments.

    instructions += Constant(type);
    instructions += PushArgument();  // Type.

    instructions += InstanceCall(
        position, Library::PrivateCoreLibName(Symbols::_as()), Token::kAS, 4);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildSymbolLiteral(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  intptr_t offset = ReaderOffset() - 1;  // EvaluateExpression needs the tag.
  SkipStringReference();                 // read index into string table.
  return Constant(constant_evaluator_.EvaluateExpression(offset));
}

Fragment StreamingFlowGraphBuilder::BuildTypeLiteral(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  const AbstractType& type = T.BuildType();  // read type.
  if (type.IsMalformed()) H.ReportError("Malformed type literal");

  Fragment instructions;
  if (type.IsInstantiated()) {
    instructions += Constant(type);
  } else {
    if (!type.IsInstantiated(kCurrentClass)) {
      instructions += LoadInstantiatorTypeArguments();
    } else {
      instructions += NullConstant();
    }
    if (!type.IsInstantiated(kFunctions)) {
      instructions += LoadFunctionTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += InstantiateType(type);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildThisExpression(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  return LoadLocal(scopes()->this_variable);
}

Fragment StreamingFlowGraphBuilder::BuildRethrow(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions = DebugStepCheck(position);
  instructions += LoadLocal(catch_block()->exception_var());
  instructions += PushArgument();
  instructions += LoadLocal(catch_block()->stack_trace_var());
  instructions += PushArgument();
  instructions += RethrowException(position, catch_block()->catch_try_index());

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildThrow(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions;

  instructions += BuildExpression();  // read expression.

  if (NeedsDebugStepCheck(stack(), position)) {
    instructions = DebugStepCheck(position) + instructions;
  }
  instructions += PushArgument();
  instructions += ThrowException(position);
  ASSERT(instructions.is_closed());

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildListLiteral(bool is_const,
                                                     TokenPosition* p) {
  if (is_const) {
    intptr_t offset = ReaderOffset() - 1;                 // Include the tag.
    (p != NULL) ? * p = ReadPosition() : ReadPosition();  // read position.

    SetOffset(offset);
    SkipExpression();  // read past the ListLiteral.
    return Constant(constant_evaluator_.EvaluateListLiteral(offset));
  }

  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const TypeArguments& type_arguments = T.BuildTypeArguments(1);  // read type.
  intptr_t length = ReadListLength();  // read list length.
  // Note: there will be "length" expressions.

  // The type argument for the factory call.
  Fragment instructions = TranslateInstantiatedTypeArguments(type_arguments);
  instructions += PushArgument();
  if (length == 0) {
    instructions += Constant(Object::empty_array());
  } else {
    // The type arguments for CreateArray.
    instructions += Constant(type_arguments);
    instructions += IntConstant(length);
    instructions += CreateArray();
    AbstractType& list_type = AbstractType::ZoneHandle(Z);
    if (I->type_checks()) {
      if (type_arguments.IsNull()) {
        // It was dynamic.
        list_type = Object::dynamic_type().raw();
      } else {
        list_type = type_arguments.TypeAt(0);
      }
    }

    LocalVariable* array = MakeTemporary();
    for (intptr_t i = 0; i < length; ++i) {
      instructions += LoadLocal(array);
      instructions += IntConstant(i);
      instructions += BuildExpression();  // read ith expression.
      instructions += CheckAssignableInCheckedMode(
          list_type, Symbols::ListLiteralElement());
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();
    }
  }
  instructions += PushArgument();  // The array.

  const Class& factory_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::List()));
  const Function& factory_method = Function::ZoneHandle(
      Z, factory_class.LookupFactory(
             Library::PrivateCoreLibName(Symbols::ListLiteralFactory())));

  return instructions +
         StaticCall(position, factory_method, 2, ICData::kStatic);
}

Fragment StreamingFlowGraphBuilder::BuildMapLiteral(bool is_const,
                                                    TokenPosition* p) {
  if (is_const) {
    intptr_t offset = ReaderOffset() - 1;  // Include the tag.
    (p != NULL) ? * p = ReadPosition() : ReadPosition();

    SetOffset(offset);
    SkipExpression();  // Read past the MapLiteral.
    return Constant(constant_evaluator_.EvaluateMapLiteral(offset));
  }

  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  const TypeArguments& type_arguments =
      T.BuildTypeArguments(2);  // read key_type and value_type.

  // The type argument for the factory call `new Map<K, V>._fromLiteral(List)`.
  Fragment instructions = TranslateInstantiatedTypeArguments(type_arguments);
  instructions += PushArgument();

  intptr_t length = ReadListLength();  // read list length.
  // Note: there will be "length" map entries (i.e. key and value expressions).

  if (length == 0) {
    instructions += Constant(Object::empty_array());
  } else {
    // The type arguments for `new List<X>(int len)`.
    instructions += Constant(TypeArguments::ZoneHandle(Z));

    // We generate a list of tuples, i.e. [key1, value1, ..., keyN, valueN].
    instructions += IntConstant(2 * length);
    instructions += CreateArray();

    LocalVariable* array = MakeTemporary();
    for (intptr_t i = 0; i < length; ++i) {
      instructions += LoadLocal(array);
      instructions += IntConstant(2 * i);
      instructions += BuildExpression();  // read ith key.
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();

      instructions += LoadLocal(array);
      instructions += IntConstant(2 * i + 1);
      instructions += BuildExpression();  // read ith value.
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();
    }
  }
  instructions += PushArgument();  // The array.

  const Class& map_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::Map()));
  const Function& factory_method = Function::ZoneHandle(
      Z, map_class.LookupFactory(
             Library::PrivateCoreLibName(Symbols::MapLiteralFactory())));

  return instructions +
         StaticCall(position, factory_method, 2, ICData::kStatic);
}

Fragment StreamingFlowGraphBuilder::BuildFunctionExpression() {
  ReadPosition();  // read position.
  return BuildFunctionNode(TokenPosition::kNoSource, StringIndex());
}

Fragment StreamingFlowGraphBuilder::BuildLet(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  Fragment instructions = BuildVariableDeclaration();  // read variable.
  instructions += BuildExpression();                   // read body.
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildBigIntLiteral(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  const String& value =
      H.DartString(ReadStringReference());  // read index into string table.
  const Integer& integer =
      Integer::ZoneHandle(Z, Integer::New(value, Heap::kOld));
  if (integer.IsNull()) {
    H.ReportError("Integer literal %s is out of range", value.ToCString());
    UNREACHABLE();
  }
  return Constant(integer);
}

Fragment StreamingFlowGraphBuilder::BuildStringLiteral(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  return Constant(
      H.DartSymbol(ReadStringReference()));  // read index into string table.
}

Fragment StreamingFlowGraphBuilder::BuildIntLiteral(uint8_t payload,
                                                    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  int64_t value = static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
  return IntConstant(value);
}

Fragment StreamingFlowGraphBuilder::BuildIntLiteral(bool is_negative,
                                                    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  int64_t value = is_negative ? -static_cast<int64_t>(ReadUInt())
                              : ReadUInt();  // read value.
  return IntConstant(value);
}

Fragment StreamingFlowGraphBuilder::BuildDoubleLiteral(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  intptr_t offset = ReaderOffset() - 1;  // EvaluateExpression needs the tag.
  SkipStringReference();                 // read index into string table.
  return Constant(constant_evaluator_.EvaluateExpression(offset));
}

Fragment StreamingFlowGraphBuilder::BuildBoolLiteral(bool value,
                                                     TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  return Constant(Bool::Get(value));
}

Fragment StreamingFlowGraphBuilder::BuildNullLiteral(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  return Constant(Instance::ZoneHandle(Z, Instance::null()));
}

Fragment StreamingFlowGraphBuilder::BuildVectorCreation(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  intptr_t size = ReadUInt();  // read size.
  return AllocateContext(size);
}

Fragment StreamingFlowGraphBuilder::BuildVectorGet(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  Fragment instructions = BuildExpression();  // read expression.
  intptr_t index = ReadUInt();                // read index.
  instructions += LoadField(Context::variable_offset(index));
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildVectorSet(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  Fragment instructions = NullConstant();
  LocalVariable* result = MakeTemporary();

  instructions += BuildExpression();  // read vector expression.
  intptr_t index = ReadUInt();        // read index.
  instructions += BuildExpression();  // read value expression.
  instructions += StoreLocal(TokenPosition::kNoSource, result);

  instructions += StoreInstanceField(TokenPosition::kNoSource,
                                     Context::variable_offset(index));

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildVectorCopy(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  Fragment instructions = BuildExpression();  // read vector expression.
  Value* context_to_copy = Pop();
  // TODO(dartbug.com/31218) VectorCopy should contain size of the context
  // as a constant.
  CloneContextInstr* clone_instruction =
      new (Z) CloneContextInstr(TokenPosition::kNoSource, context_to_copy,
                                CloneContextInstr::kUnknownContextSize,
                                Thread::Current()->GetNextDeoptId());
  instructions <<= clone_instruction;
  Push(clone_instruction);

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildClosureCreation(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  NameIndex function_reference =
      ReadCanonicalNameReference();  // read function reference.
  Function& function = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(function_reference));
  function = function.ConvertedClosureFunction();
  ASSERT(!function.IsNull());

  const Class& closure_class =
      Class::ZoneHandle(Z, I->object_store()->closure_class());
  Fragment instructions = AllocateObject(closure_class, function);
  LocalVariable* closure = MakeTemporary();

  instructions += BuildExpression();  // read context vector.
  LocalVariable* context = MakeTemporary();

  instructions += LoadLocal(closure);
  instructions += Constant(function);
  instructions +=
      StoreInstanceField(TokenPosition::kNoSource, Closure::function_offset());

  instructions += LoadLocal(closure);
  instructions += LoadLocal(context);
  instructions +=
      StoreInstanceField(TokenPosition::kNoSource, Closure::context_offset());

  SkipDartType();  // skip function type of the closure.

  // TODO(30455): Kernel generic methods undone. When generic methods are
  // fully supported in kernel, we'll need to store a NULL in the type arguments
  // slot when type arguments are absent, so the wrapper for the target function
  // can tell how many type args are captured vs. provided by the caller of the
  // closure.

  intptr_t types_count = ReadListLength();  // read type count.
  if (types_count > 0) {
    const TypeArguments& type_args =
        T.BuildTypeArguments(types_count);  // read list of type arguments.
    instructions += TranslateInstantiatedTypeArguments(type_args);
    LocalVariable* type_args_slot = MakeTemporary();

    instructions += LoadLocal(context);
    instructions += LoadLocal(type_args_slot);
    instructions += StoreInstanceField(TokenPosition::kNoSource,
                                       Context::variable_offset(0));

    instructions += LoadLocal(closure);
    instructions += LoadLocal(type_args_slot);
    instructions += StoreInstanceField(
        TokenPosition::kNoSource, Closure::function_type_arguments_offset());

    instructions += Drop();  // type args
  }

  instructions += Drop();  // context
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildInvalidStatement() {
  H.ReportError("Invalid statements not implemented yet!");
  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildExpressionStatement() {
  Fragment instructions = BuildExpression();  // read expression.
  instructions += Drop();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildBlock() {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  Fragment instructions;

  instructions += EnterScope(offset);
  intptr_t list_length = ReadListLength();  // read number of statements.
  for (intptr_t i = 0; i < list_length; ++i) {
    if (instructions.is_open()) {
      instructions += BuildStatement();  // read ith statement.
    } else {
      SkipStatement();  // read ith statement.
    }
  }
  instructions += ExitScope(offset);

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildEmptyStatement() {
  return Fragment();
}

Fragment StreamingFlowGraphBuilder::BuildAssertStatement() {
  if (!I->asserts()) {
    SetOffset(ReaderOffset() - 1);  // Include the tag.
    SkipStatement();                // read this statement.
    return Fragment();
  }

  TargetEntryInstr* then;
  TargetEntryInstr* otherwise;

  Fragment instructions;
  // Asserts can be of the following two kinds:
  //
  //    * `assert(expr)`
  //    * `assert(() { ... })`
  //
  // The call to `_AssertionError._evaluateAssertion()` will take care of both
  // and returns a boolean.
  instructions += BuildExpression();  // read condition.
  instructions += PushArgument();
  instructions += EvaluateAssertion();
  instructions += CheckBooleanInCheckedMode();
  instructions += Constant(Bool::True());
  instructions += BranchIfEqual(&then, &otherwise, false);

  TokenPosition condition_start_offset =
      ReadPosition();  // read condition start offset.
  TokenPosition condition_end_offset =
      ReadPosition();  // read condition end offset.

  const Class& klass =
      Class::ZoneHandle(Z, Library::LookupCoreClass(Symbols::AssertionError()));
  ASSERT(!klass.IsNull());
  const Function& target = Function::ZoneHandle(
      Z, klass.LookupStaticFunctionAllowPrivate(Symbols::ThrowNew()));
  ASSERT(!target.IsNull());

  // Build equivalent of `throw _AssertionError._throwNew(start, end, message)`
  // expression. We build throw (even through _throwNew already throws) because
  // call is not a valid last instruction for the block. Blocks can only
  // terminate with explicit control flow instructions (Branch, Goto, Return
  // or Throw).
  Fragment otherwise_fragment(otherwise);
  otherwise_fragment += IntConstant(condition_start_offset.Pos());
  otherwise_fragment += PushArgument();  // start
  otherwise_fragment += IntConstant(condition_end_offset.Pos());
  otherwise_fragment += PushArgument();  // end
  Tag tag = ReadTag();                   // read (first part of) message.
  if (tag == kSomething) {
    otherwise_fragment += BuildExpression();  // read (rest of) message.
  } else {
    otherwise_fragment += Constant(Instance::ZoneHandle(Z));  // null.
  }
  otherwise_fragment += PushArgument();  // message

  otherwise_fragment +=
      StaticCall(TokenPosition::kNoSource, target, 3, ICData::kStatic);
  otherwise_fragment += PushArgument();
  otherwise_fragment += ThrowException(TokenPosition::kNoSource);
  otherwise_fragment += Drop();

  return Fragment(instructions.entry, then);
}

Fragment StreamingFlowGraphBuilder::BuildLabeledStatement() {
  // There can be serveral cases:
  //
  //   * the body contains a break
  //   * the body doesn't contain a break
  //
  //   * translating the body results in a closed fragment
  //   * translating the body results in a open fragment
  //
  // => We will only know which case we are in after the body has been
  //    traversed.

  BreakableBlock block(flow_graph_builder_);
  Fragment instructions = BuildStatement();  // read body.
  if (block.HadJumper()) {
    if (instructions.is_open()) {
      instructions += Goto(block.destination());
    }
    return Fragment(instructions.entry, block.destination());
  } else {
    return instructions;
  }
}

Fragment StreamingFlowGraphBuilder::BuildBreakStatement() {
  TokenPosition position = ReadPosition();  // read position.
  intptr_t target_index = ReadUInt();       // read target index.

  TryFinallyBlock* outer_finally = NULL;
  intptr_t target_context_depth = -1;
  JoinEntryInstr* destination = breakable_block()->BreakDestination(
      target_index, &outer_finally, &target_context_depth);

  Fragment instructions;
  instructions +=
      TranslateFinallyFinalizers(outer_finally, target_context_depth);
  if (instructions.is_open()) {
    if (NeedsDebugStepCheck(parsed_function()->function(), position)) {
      instructions += DebugStepCheck(position);
    }
    instructions += Goto(destination);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildWhileStatement() {
  loop_depth_inc();
  ReadPosition();  // read position.

  bool negate;
  Fragment condition = TranslateCondition(&negate);  // read condition.
  TargetEntryInstr* body_entry;
  TargetEntryInstr* loop_exit;
  condition += BranchIfTrue(&body_entry, &loop_exit, negate);

  Fragment body(body_entry);
  body += BuildStatement();  // read body.

  Instruction* entry;
  if (body.is_open()) {
    JoinEntryInstr* join = BuildJoinEntry();
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow();
    loop += condition;
    entry = new (Z) GotoInstr(join, Thread::Current()->GetNextDeoptId());
  } else {
    entry = condition.entry;
  }

  loop_depth_dec();
  return Fragment(entry, loop_exit);
}

Fragment StreamingFlowGraphBuilder::BuildDoStatement() {
  loop_depth_inc();
  ReadPosition();                    // read position.
  Fragment body = BuildStatement();  // read body.

  if (body.is_closed()) {
    SkipExpression();  // read condition.
    loop_depth_dec();
    return body;
  }

  bool negate;
  JoinEntryInstr* join = BuildJoinEntry();
  Fragment loop(join);
  loop += CheckStackOverflow();
  loop += body;
  loop += TranslateCondition(&negate);  // read condition.
  TargetEntryInstr* loop_repeat;
  TargetEntryInstr* loop_exit;
  loop += BranchIfTrue(&loop_repeat, &loop_exit, negate);

  Fragment repeat(loop_repeat);
  repeat += Goto(join);

  loop_depth_dec();
  return Fragment(new (Z) GotoInstr(join, Thread::Current()->GetNextDeoptId()),
                  loop_exit);
}

Fragment StreamingFlowGraphBuilder::BuildForStatement() {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  ReadPosition();  // read position.

  Fragment declarations;

  loop_depth_inc();

  intptr_t num_context_variables = 0;
  declarations += EnterScope(offset, &num_context_variables);

  intptr_t list_length = ReadListLength();  // read number of variables.
  for (intptr_t i = 0; i < list_length; ++i) {
    declarations += BuildVariableDeclaration();  // read ith variable.
  }

  bool negate = false;
  Tag tag = ReadTag();  // Read first part of condition.
  Fragment condition =
      tag == kNothing ? Constant(Bool::True())
                      : TranslateCondition(&negate);  // read rest of condition.
  TargetEntryInstr* body_entry;
  TargetEntryInstr* loop_exit;
  condition += BranchIfTrue(&body_entry, &loop_exit, negate);

  Fragment updates;
  list_length = ReadListLength();  // read number of updates.
  for (intptr_t i = 0; i < list_length; ++i) {
    updates += BuildExpression();  // read ith update.
    updates += Drop();
  }

  Fragment body(body_entry);
  body += BuildStatement();  // read body.

  if (body.is_open()) {
    // We allocated a fresh context before the loop which contains captured
    // [ForStatement] variables.  Before jumping back to the loop entry we clone
    // the context object (at same depth) which ensures the next iteration of
    // the body gets a fresh set of [ForStatement] variables (with the old
    // (possibly updated) values).
    if (num_context_variables > 0) body += CloneContext(num_context_variables);

    body += updates;
    JoinEntryInstr* join = BuildJoinEntry();
    declarations += Goto(join);
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow();
    loop += condition;
  } else {
    declarations += condition;
  }

  Fragment loop(declarations.entry, loop_exit);

  loop += ExitScope(offset);

  loop_depth_dec();

  return loop;
}

Fragment StreamingFlowGraphBuilder::BuildForInStatement(bool async) {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  ReadPosition();                                // read position.
  TokenPosition body_position = ReadPosition();  // read body position.
  intptr_t variable_kernel_position = ReaderOffset() + data_program_offset_;
  SkipVariableDeclaration();  // read variable.

  TokenPosition iterable_position = TokenPosition::kNoSource;
  Fragment instructions =
      BuildExpression(&iterable_position);  // read iterable.
  instructions += PushArgument();

  const String& iterator_getter =
      String::ZoneHandle(Z, Field::GetterSymbol(Symbols::Iterator()));
  instructions +=
      InstanceCall(iterable_position, iterator_getter, Token::kGET, 1);
  LocalVariable* iterator = scopes()->iterator_variables[for_in_depth()];
  instructions += StoreLocal(TokenPosition::kNoSource, iterator);
  instructions += Drop();

  for_in_depth_inc();
  loop_depth_inc();
  Fragment condition = LoadLocal(iterator);
  condition += PushArgument();
  condition +=
      InstanceCall(iterable_position, Symbols::MoveNext(), Token::kILLEGAL, 1);
  TargetEntryInstr* body_entry;
  TargetEntryInstr* loop_exit;
  condition += BranchIfTrue(&body_entry, &loop_exit, false);

  Fragment body(body_entry);
  body += EnterScope(offset);
  body += LoadLocal(iterator);
  body += PushArgument();
  const String& current_getter =
      String::ZoneHandle(Z, Field::GetterSymbol(Symbols::Current()));
  body += InstanceCall(body_position, current_getter, Token::kGET, 1);
  body += StoreLocal(TokenPosition::kNoSource,
                     LookupVariable(variable_kernel_position));
  body += Drop();
  body += BuildStatement();  // read body.
  body += ExitScope(offset);

  if (body.is_open()) {
    JoinEntryInstr* join = BuildJoinEntry();
    instructions += Goto(join);
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow();
    loop += condition;
  } else {
    instructions += condition;
  }

  loop_depth_dec();
  for_in_depth_dec();
  return Fragment(instructions.entry, loop_exit);
}

Fragment StreamingFlowGraphBuilder::BuildSwitchStatement() {
  ReadPosition();  // read position.
  // We need the number of cases. So start by getting that, then go back.
  intptr_t offset = ReaderOffset();
  SkipExpression();                   // temporarily skip condition
  int case_count = ReadListLength();  // read number of cases.
  SetOffset(offset);

  SwitchBlock block(flow_graph_builder_, case_count);

  // Instead of using a variable we should reuse the expression on the stack,
  // since it won't be assigned again, we don't need phi nodes.
  Fragment head_instructions = BuildExpression();  // read condition.
  head_instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes()->switch_variable);
  head_instructions += Drop();

  case_count = ReadListLength();  // read number of cases.

  // Phase 1: Generate bodies and try to find out whether a body will be target
  // of a jump due to:
  //   * `continue case_label`
  //   * `case e1: case e2: body`
  Fragment* body_fragments = new Fragment[case_count];
  intptr_t* case_expression_offsets = new intptr_t[case_count];
  int default_case = -1;

  for (intptr_t i = 0; i < case_count; ++i) {
    case_expression_offsets[i] = ReaderOffset();
    int expression_count = ReadListLength();  // read number of expressions.
    for (intptr_t j = 0; j < expression_count; ++j) {
      ReadPosition();    // read jth position.
      SkipExpression();  // read jth expression.
    }
    bool is_default = ReadBool();  // read is_default.
    if (is_default) default_case = i;
    Fragment& body_fragment = body_fragments[i] =
        BuildStatement();  // read body.

    if (body_fragment.entry == NULL) {
      // Make a NOP in order to ensure linking works properly.
      body_fragment = NullConstant();
      body_fragment += Drop();
    }

    // The Dart language specification mandates fall-throughs in [SwitchCase]es
    // to be runtime errors.
    if (!is_default && body_fragment.is_open() && (i < (case_count - 1))) {
      const Class& klass = Class::ZoneHandle(
          Z, Library::LookupCoreClass(Symbols::FallThroughError()));
      ASSERT(!klass.IsNull());
      const Function& constructor = Function::ZoneHandle(
          Z, klass.LookupConstructorAllowPrivate(
                 H.DartSymbol("FallThroughError._create")));
      ASSERT(!constructor.IsNull());
      const String& url = H.DartString(
          parsed_function()->function().ToLibNamePrefixedQualifiedCString(),
          Heap::kOld);

      // Create instance of _FallThroughError
      body_fragment += AllocateObject(TokenPosition::kNoSource, klass, 0);
      LocalVariable* instance = MakeTemporary();

      // Call _FallThroughError._create constructor.
      body_fragment += LoadLocal(instance);
      body_fragment += PushArgument();  // this

      body_fragment += Constant(url);
      body_fragment += PushArgument();  // url

      body_fragment += NullConstant();
      body_fragment += PushArgument();  // line

      body_fragment +=
          StaticCall(TokenPosition::kNoSource, constructor, 3, ICData::kStatic);
      body_fragment += Drop();

      // Throw the exception
      body_fragment += PushArgument();
      body_fragment += ThrowException(TokenPosition::kNoSource);
      body_fragment += Drop();
    }

    // If there is an implicit fall-through we have one [SwitchCase] and
    // multiple expressions, e.g.
    //
    //    switch(expr) {
    //      case a:
    //      case b:
    //        <stmt-body>
    //    }
    //
    // This means that the <stmt-body> will have more than 1 incoming edge (one
    // from `a == expr` and one from `a != expr && b == expr`). The
    // `block.Destination()` records the additional jump.
    if (expression_count > 1) {
      block.DestinationDirect(i);
    }
  }

  intptr_t end_offset = ReaderOffset();

  // Phase 2: Generate everything except the real bodies:
  //   * jump directly to a body (if there is no jumper)
  //   * jump to a wrapper block which jumps to the body (if there is a jumper)
  Fragment current_instructions = head_instructions;
  for (intptr_t i = 0; i < case_count; ++i) {
    SetOffset(case_expression_offsets[i]);
    int expression_count = ReadListLength();  // read length of expressions.

    if (i == default_case) {
      ASSERT(i == (case_count - 1));

      // Evaluate the conditions for the default [SwitchCase] just for the
      // purpose of potentially triggering a compile-time error.

      for (intptr_t j = 0; j < expression_count; ++j) {
        ReadPosition();  // read jth position.
        // this reads the expression, but doesn't skip past it.
        constant_evaluator_.EvaluateExpression(ReaderOffset());
        SkipExpression();  // read jth expression.
      }

      if (block.HadJumper(i)) {
        // There are several branches to the body, so we will make a goto to
        // the join block (and prepend a join instruction to the real body).
        JoinEntryInstr* join = block.DestinationDirect(i);
        current_instructions += Goto(join);

        current_instructions = Fragment(current_instructions.entry, join);
        current_instructions += body_fragments[i];
      } else {
        current_instructions += body_fragments[i];
      }
    } else {
      JoinEntryInstr* body_join = NULL;
      if (block.HadJumper(i)) {
        body_join = block.DestinationDirect(i);
        body_fragments[i] = Fragment(body_join) + body_fragments[i];
      }

      for (intptr_t j = 0; j < expression_count; ++j) {
        TargetEntryInstr* then;
        TargetEntryInstr* otherwise;

        TokenPosition position = ReadPosition();  // read jth position.
        current_instructions +=
            Constant(constant_evaluator_.EvaluateExpression(ReaderOffset()));
        SkipExpression();  // read jth expression.
        current_instructions += PushArgument();
        current_instructions += LoadLocal(scopes()->switch_variable);
        current_instructions += PushArgument();
        current_instructions +=
            InstanceCall(position, Symbols::EqualOperator(), Token::kEQ,
                         /*argument_count=*/2,
                         /*checked_argument_count=*/2);
        current_instructions += BranchIfTrue(&then, &otherwise, false);

        Fragment then_fragment(then);

        if (body_join != NULL) {
          // There are several branches to the body, so we will make a goto to
          // the join block (the real body has already been prepended with a
          // join instruction).
          then_fragment += Goto(body_join);
        } else {
          // There is only a signle branch to the body, so we will just append
          // the body fragment.
          then_fragment += body_fragments[i];
        }

        current_instructions = Fragment(otherwise);
      }
    }
  }

  if (case_count > 0 && default_case < 0) {
    // There is no default, which means we have an open [current_instructions]
    // (which is a [TargetEntryInstruction] for the last "otherwise" branch).
    //
    // Furthermore the last [SwitchCase] can be open as well.  If so, we need
    // to join these two.
    Fragment& last_body = body_fragments[case_count - 1];
    if (last_body.is_open()) {
      ASSERT(current_instructions.is_open());
      ASSERT(current_instructions.current->IsTargetEntry());

      // Join the last "otherwise" branch and the last [SwitchCase] fragment.
      JoinEntryInstr* join = BuildJoinEntry();
      current_instructions += Goto(join);
      last_body += Goto(join);

      current_instructions = Fragment(join);
    }
  } else {
    // All non-default cases will be closed (i.e. break/continue/throw/return)
    // So it is fine to just let more statements after the switch append to the
    // default case.
  }

  delete[] body_fragments;
  delete[] case_expression_offsets;

  SetOffset(end_offset);
  return Fragment(head_instructions.entry, current_instructions.current);
}

Fragment StreamingFlowGraphBuilder::BuildContinueSwitchStatement() {
  TokenPosition position = ReadPosition();  // read position.
  intptr_t target_index = ReadUInt();       // read target index.

  TryFinallyBlock* outer_finally = NULL;
  intptr_t target_context_depth = -1;
  JoinEntryInstr* entry = switch_block()->Destination(
      target_index, &outer_finally, &target_context_depth);

  Fragment instructions;
  instructions +=
      TranslateFinallyFinalizers(outer_finally, target_context_depth);
  if (instructions.is_open()) {
    if (NeedsDebugStepCheck(parsed_function()->function(), position)) {
      instructions += DebugStepCheck(position);
    }
    instructions += Goto(entry);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildIfStatement() {
  bool negate;
  ReadPosition();                                       // read position.
  Fragment instructions = TranslateCondition(&negate);  // read condition.
  TargetEntryInstr* then_entry;
  TargetEntryInstr* otherwise_entry;
  instructions += BranchIfTrue(&then_entry, &otherwise_entry, negate);

  Fragment then_fragment(then_entry);
  then_fragment += BuildStatement();  // read then.

  Fragment otherwise_fragment(otherwise_entry);
  otherwise_fragment += BuildStatement();  // read otherwise.

  if (then_fragment.is_open()) {
    if (otherwise_fragment.is_open()) {
      JoinEntryInstr* join = BuildJoinEntry();
      then_fragment += Goto(join);
      otherwise_fragment += Goto(join);
      return Fragment(instructions.entry, join);
    } else {
      return Fragment(instructions.entry, then_fragment.current);
    }
  } else if (otherwise_fragment.is_open()) {
    return Fragment(instructions.entry, otherwise_fragment.current);
  } else {
    return instructions.closed();
  }
}

Fragment StreamingFlowGraphBuilder::BuildReturnStatement() {
  TokenPosition position = ReadPosition();  // read position.
  Tag tag = ReadTag();                      // read first part of expression.

  bool inside_try_finally = try_finally_block() != NULL;

  Fragment instructions = tag == kNothing
                              ? NullConstant()
                              : BuildExpression();  // read rest of expression.

  if (instructions.is_open()) {
    if (inside_try_finally) {
      ASSERT(scopes()->finally_return_variable != NULL);
      const Function& function = parsed_function()->function();
      if (NeedsDebugStepCheck(function, position)) {
        instructions += DebugStepCheck(position);
      }
      instructions += StoreLocal(position, scopes()->finally_return_variable);
      instructions += Drop();
      instructions += TranslateFinallyFinalizers(NULL, -1);
      if (instructions.is_open()) {
        instructions += LoadLocal(scopes()->finally_return_variable);
        instructions += Return(TokenPosition::kNoSource);
      }
    } else {
      instructions += Return(position);
    }
  } else {
    Pop();
  }

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildTryCatch() {
  InlineBailout("kernel::FlowgraphBuilder::VisitTryCatch");

  intptr_t try_handler_index = AllocateTryIndex();
  Fragment try_body = TryCatch(try_handler_index);
  JoinEntryInstr* after_try = BuildJoinEntry();

  // Fill in the body of the try.
  try_depth_inc();
  {
    TryCatchBlock block(flow_graph_builder_, try_handler_index);
    try_body += BuildStatement();  // read body.
    try_body += Goto(after_try);
  }
  try_depth_dec();

  bool needs_stacktrace = ReadBool();  // read any_catch_needs_stack_trace

  catch_depth_inc();
  intptr_t catch_count = ReadListLength();  // read number of catches.
  const Array& handler_types =
      Array::ZoneHandle(Z, Array::New(catch_count, Heap::kOld));
  Fragment catch_body =
      CatchBlockEntry(handler_types, try_handler_index, needs_stacktrace);
  // Fill in the body of the catch.
  for (intptr_t i = 0; i < catch_count; ++i) {
    intptr_t catch_offset = ReaderOffset();  // Catch has no tag.
    Tag tag = PeekTag();                     // peek guard type.
    AbstractType* type_guard = NULL;
    if (tag != kDynamicType) {
      type_guard = &T.BuildType();  // read guard.
      handler_types.SetAt(i, *type_guard);
    } else {
      SkipDartType();  // read guard.
      handler_types.SetAt(i, Object::dynamic_type());
    }

    Fragment catch_handler_body = EnterScope(catch_offset);

    tag = ReadTag();  // read first part of exception.
    if (tag == kSomething) {
      catch_handler_body += LoadLocal(CurrentException());
      catch_handler_body +=
          StoreLocal(TokenPosition::kNoSource,
                     LookupVariable(ReaderOffset() + data_program_offset_));
      catch_handler_body += Drop();
      SkipVariableDeclaration();  // read exception.
    }

    tag = ReadTag();  // read first part of stack trace.
    if (tag == kSomething) {
      catch_handler_body += LoadLocal(CurrentStackTrace());
      catch_handler_body +=
          StoreLocal(TokenPosition::kNoSource,
                     LookupVariable(ReaderOffset() + data_program_offset_));
      catch_handler_body += Drop();
      SkipVariableDeclaration();  // read stack trace.
    }

    {
      CatchBlock block(flow_graph_builder_, CurrentException(),
                       CurrentStackTrace(), try_handler_index);

      catch_handler_body += BuildStatement();  // read body.

      // Note: ExitScope adjusts context_depth_ so even if catch_handler_body
      // is closed we still need to execute ExitScope for its side effect.
      catch_handler_body += ExitScope(catch_offset);
      if (catch_handler_body.is_open()) {
        catch_handler_body += Goto(after_try);
      }
    }

    if (type_guard != NULL) {
      if (type_guard->IsMalformed()) {
        catch_body += ThrowTypeError();
        catch_body += Drop();
      } else {
        catch_body += LoadLocal(CurrentException());
        catch_body += PushArgument();  // exception
        if (!type_guard->IsInstantiated(kCurrentClass)) {
          catch_body += LoadInstantiatorTypeArguments();
        } else {
          catch_body += NullConstant();
        }
        catch_body += PushArgument();  // instantiator type arguments
        if (!type_guard->IsInstantiated(kFunctions)) {
          catch_body += LoadFunctionTypeArguments();
        } else {
          catch_body += NullConstant();
        }
        catch_body += PushArgument();  // function type arguments
        catch_body += Constant(*type_guard);
        catch_body += PushArgument();  // guard type
        catch_body += InstanceCall(
            TokenPosition::kNoSource,
            Library::PrivateCoreLibName(Symbols::_instanceOf()), Token::kIS, 4);

        TargetEntryInstr* catch_entry;
        TargetEntryInstr* next_catch_entry;
        catch_body += BranchIfTrue(&catch_entry, &next_catch_entry, false);

        Fragment(catch_entry) + catch_handler_body;
        catch_body = Fragment(next_catch_entry);
      }
    } else {
      catch_body += catch_handler_body;
    }
  }

  // In case the last catch body was not handling the exception and branching to
  // after the try block, we will rethrow the exception (i.e. no default catch
  // handler).
  if (catch_body.is_open()) {
    catch_body += LoadLocal(CurrentException());
    catch_body += PushArgument();
    catch_body += LoadLocal(CurrentStackTrace());
    catch_body += PushArgument();
    catch_body += RethrowException(TokenPosition::kNoSource, try_handler_index);
    Drop();
  }
  catch_depth_dec();

  return Fragment(try_body.entry, after_try);
}

Fragment StreamingFlowGraphBuilder::BuildTryFinally() {
  // Note on streaming:
  // We only stream this TryFinally if we can stream everything inside it,
  // so creating a "TryFinallyBlock" with a kernel binary offset instead of an
  // AST node isn't a problem.

  InlineBailout("kernel::FlowgraphBuilder::VisitTryFinally");

  // There are 5 different cases where we need to execute the finally block:
  //
  //  a) 1/2/3th case: Special control flow going out of `node->body()`:
  //
  //   * [BreakStatement] transfers control to a [LabledStatement]
  //   * [ContinueSwitchStatement] transfers control to a [SwitchCase]
  //   * [ReturnStatement] returns a value
  //
  //   => All three cases will automatically append all finally blocks
  //      between the branching point and the destination (so we don't need to
  //      do anything here).
  //
  //  b) 4th case: Translating the body resulted in an open fragment (i.e. body
  //               executes without any control flow out of it)
  //
  //   => We are responsible for jumping out of the body to a new block (with
  //      different try index) and execute the finalizer.
  //
  //  c) 5th case: An exception occurred inside the body.
  //
  //   => We are responsible for catching it, executing the finally block and
  //      rethrowing the exception.
  intptr_t try_handler_index = AllocateTryIndex();
  Fragment try_body = TryCatch(try_handler_index);
  JoinEntryInstr* after_try = BuildJoinEntry();

  intptr_t offset = ReaderOffset();
  SkipStatement();  // temporarily read body.
  intptr_t finalizer_offset = ReaderOffset();
  SetOffset(offset);

  // Fill in the body of the try.
  try_depth_inc();
  {
    TryFinallyBlock tfb(flow_graph_builder_, finalizer_offset);
    TryCatchBlock tcb(flow_graph_builder_, try_handler_index);
    try_body += BuildStatement();  // read body.
  }
  try_depth_dec();

  if (try_body.is_open()) {
    // Please note: The try index will be on level out of this block,
    // thereby ensuring if there's an exception in the finally block we
    // won't run it twice.
    JoinEntryInstr* finally_entry = BuildJoinEntry();

    try_body += Goto(finally_entry);

    Fragment finally_body(finally_entry);
    finally_body += BuildStatement();  // read finalizer.
    finally_body += Goto(after_try);
  }

  // Fill in the body of the catch.
  catch_depth_inc();
  const Array& handler_types = Array::ZoneHandle(Z, Array::New(1, Heap::kOld));
  handler_types.SetAt(0, Object::dynamic_type());
  // Note: rethrow will actually force mark the handler as needing a stacktrace.
  Fragment finally_body = CatchBlockEntry(handler_types, try_handler_index,
                                          /* needs_stacktrace = */ false);
  SetOffset(finalizer_offset);
  finally_body += BuildStatement();  // read finalizer
  if (finally_body.is_open()) {
    finally_body += LoadLocal(CurrentException());
    finally_body += PushArgument();
    finally_body += LoadLocal(CurrentStackTrace());
    finally_body += PushArgument();
    finally_body +=
        RethrowException(TokenPosition::kNoSource, try_handler_index);
    Drop();
  }
  catch_depth_dec();

  return Fragment(try_body.entry, after_try);
}

Fragment StreamingFlowGraphBuilder::BuildYieldStatement() {
  TokenPosition position = ReadPosition();  // read position.
  uint8_t flags = ReadByte();               // read flags.

  ASSERT(flags == kNativeYieldFlags);  // Must have been desugared.

  // Setup yield/continue point:
  //
  //   ...
  //   :await_jump_var = index;
  //   :await_ctx_var = :current_context_var
  //   return <expr>
  //
  // Continuation<index>:
  //   Drop(1)
  //   ...
  //
  // BuildGraphOfFunction will create a dispatch that jumps to
  // Continuation<:await_jump_var> upon entry to the function.
  //
  Fragment instructions = IntConstant(yield_continuations().length() + 1);
  instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes()->yield_jump_variable);
  instructions += Drop();
  instructions += LoadLocal(parsed_function()->current_context_var());
  instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes()->yield_context_variable);
  instructions += Drop();
  instructions += BuildExpression();  // read expression.
  instructions += Return(TokenPosition::kNoSource);

  // Note: DropTempsInstr serves as an anchor instruction. It will not
  // be linked into the resulting graph.
  DropTempsInstr* anchor = new (Z) DropTempsInstr(0, NULL);
  yield_continuations().Add(YieldContinuation(anchor, CurrentTryIndex()));

  Fragment continuation(instructions.entry, anchor);

  if (parsed_function()->function().IsAsyncClosure() ||
      parsed_function()->function().IsAsyncGenClosure()) {
    // If function is async closure or async gen closure it takes three
    // parameters where the second and the third are exception and stack_trace.
    // Check if exception is non-null and rethrow it.
    //
    //   :async_op([:result, :exception, :stack_trace]) {
    //     ...
    //     Continuation<index>:
    //       if (:exception != null) rethrow(:exception, :stack_trace);
    //     ...
    //   }
    //
    LocalScope* scope = parsed_function()->node_sequence()->scope();
    LocalVariable* exception_var = scope->VariableAt(2);
    LocalVariable* stack_trace_var = scope->VariableAt(3);
    ASSERT(exception_var->name().raw() == Symbols::ExceptionParameter().raw());
    ASSERT(stack_trace_var->name().raw() ==
           Symbols::StackTraceParameter().raw());

    TargetEntryInstr* no_error;
    TargetEntryInstr* error;

    continuation += LoadLocal(exception_var);
    continuation += BranchIfNull(&no_error, &error);

    Fragment rethrow(error);
    rethrow += LoadLocal(exception_var);
    rethrow += PushArgument();
    rethrow += LoadLocal(stack_trace_var);
    rethrow += PushArgument();
    rethrow += RethrowException(position, CatchClauseNode::kInvalidTryIndex);
    Drop();

    continuation = Fragment(continuation.entry, no_error);
  }

  return continuation;
}

Fragment StreamingFlowGraphBuilder::BuildVariableDeclaration() {
  intptr_t kernel_position_no_tag = ReaderOffset() + data_program_offset_;
  LocalVariable* variable = LookupVariable(kernel_position_no_tag);

  VariableDeclarationHelper helper(this);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
  String& name = H.DartSymbol(helper.name_index_);
  AbstractType& type = T.BuildType();  // read type.
  Tag tag = ReadTag();                 // read (first part of) initializer.

  Fragment instructions;
  if (tag == kNothing) {
    instructions += NullConstant();
  } else {
    if (helper.IsConst()) {
      const Instance& constant_value = constant_evaluator_.EvaluateExpression(
          ReaderOffset());  // read initializer form current position.
      variable->SetConstValue(constant_value);
      instructions += Constant(constant_value);
      SkipExpression();  // skip initializer.
    } else {
      // Initializer
      instructions += BuildExpression();  // read (actual) initializer.
      instructions += CheckVariableTypeInCheckedMode(type, name);
    }
  }

  // Use position of equal sign if it exists. If the equal sign does not exist
  // use the position of the identifier.
  TokenPosition debug_position =
      Utils::Maximum(helper.position_, helper.equals_position_);
  if (NeedsDebugStepCheck(stack(), debug_position)) {
    instructions = DebugStepCheck(debug_position) + instructions;
  }
  instructions += StoreLocal(helper.position_, variable);
  instructions += Drop();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildFunctionDeclaration() {
  TokenPosition position = ReadPosition();  // read position.
  intptr_t variable_offset = ReaderOffset() + data_program_offset_;

  // read variable declaration.
  VariableDeclarationHelper helper(this);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kEnd);

  Fragment instructions = DebugStepCheck(position);
  instructions += BuildFunctionNode(position, helper.name_index_);
  instructions += StoreLocal(position, LookupVariable(variable_offset));
  instructions += Drop();
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildFunctionNode(
    TokenPosition parent_position,
    StringIndex name_index) {
  intptr_t offset = ReaderOffset();

  FunctionNodeHelper function_node_helper(this);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);
  TokenPosition position = function_node_helper.position_;

  bool declaration = name_index >= 0;

  if (declaration) {
    position = parent_position;
  }
  if (!position.IsReal()) {
    // Positions has to be unique in regards to the parent.
    // A non-real at this point is probably -1, we cannot blindly use that
    // as others might use it too. Create a new dummy non-real TokenPosition.
    position = TokenPosition(offset).ToSynthetic();
  }

  // The VM has a per-isolate table of functions indexed by the enclosing
  // function and token position.
  Function& function = Function::ZoneHandle(Z);

  // NOTE: This is not TokenPosition in the general sense!
  function = I->LookupClosureFunction(parsed_function()->function(), position);
  if (function.IsNull()) {
    for (intptr_t i = 0; i < scopes()->function_scopes.length(); ++i) {
      if (scopes()->function_scopes[i].kernel_offset != offset) {
        continue;
      }

      const String* name;
      if (declaration) {
        name = &H.DartSymbol(name_index);
      } else {
        name = &Symbols::AnonymousClosure();
      }
      // NOTE: This is not TokenPosition in the general sense!
      function = Function::NewClosureFunction(
          *name, parsed_function()->function(), position);

      function.set_is_debuggable(function_node_helper.dart_async_marker_ ==
                                 FunctionNodeHelper::kSync);
      switch (function_node_helper.dart_async_marker_) {
        case FunctionNodeHelper::kSyncStar:
          function.set_modifier(RawFunction::kSyncGen);
          break;
        case FunctionNodeHelper::kAsync:
          function.set_modifier(RawFunction::kAsync);
          function.set_is_inlinable(!FLAG_causal_async_stacks);
          break;
        case FunctionNodeHelper::kAsyncStar:
          function.set_modifier(RawFunction::kAsyncGen);
          function.set_is_inlinable(!FLAG_causal_async_stacks);
          break;
        default:
          // no special modifier
          break;
      }
      function.set_is_generated_body(function_node_helper.async_marker_ ==
                                     FunctionNodeHelper::kSyncYielding);
      if (function.IsAsyncClosure() || function.IsAsyncGenClosure()) {
        function.set_is_inlinable(!FLAG_causal_async_stacks);
      }

      function.set_end_token_pos(function_node_helper.end_position_);
      LocalScope* scope = scopes()->function_scopes[i].scope;
      const ContextScope& context_scope = ContextScope::Handle(
          Z, scope->PreserveOuterScope(flow_graph_builder_->context_depth_));
      function.set_context_scope(context_scope);
      function.set_kernel_offset(offset);
      SetupFunctionParameters(active_class(), Class::Handle(Z), function,
                              false,  // is_method
                              true,   // is_closure
                              &function_node_helper);
      function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);

      // Finalize function type.
      Type& signature_type = Type::Handle(Z, function.SignatureType());
      signature_type ^=
          ClassFinalizer::FinalizeType(*active_class()->klass, signature_type);
      function.SetSignatureType(signature_type);

      I->AddClosureFunction(function);
      break;
    }
  }

  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);

  const Class& closure_class =
      Class::ZoneHandle(Z, I->object_store()->closure_class());
  ASSERT(!closure_class.IsNull());
  Fragment instructions =
      flow_graph_builder_->AllocateObject(closure_class, function);
  LocalVariable* closure = MakeTemporary();

  // The function signature can have uninstantiated class type parameters.
  if (!function.HasInstantiatedSignature(kCurrentClass)) {
    instructions += LoadLocal(closure);
    instructions += LoadInstantiatorTypeArguments();
    instructions += flow_graph_builder_->StoreInstanceField(
        TokenPosition::kNoSource,
        Closure::instantiator_type_arguments_offset());
  }

  // TODO(30455): We only need to save these if the closure uses any captured
  // type parameters.
  instructions += LoadLocal(closure);
  instructions += LoadFunctionTypeArguments();
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Closure::function_type_arguments_offset());

  // Store the function and the context in the closure.
  instructions += LoadLocal(closure);
  instructions += Constant(function);
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Closure::function_offset());

  instructions += LoadLocal(closure);
  instructions += LoadLocal(parsed_function()->current_context_var());
  instructions += flow_graph_builder_->StoreInstanceField(
      TokenPosition::kNoSource, Closure::context_offset());

  return instructions;
}

RawScript* StreamingFlowGraphBuilder::Script() {
  return script_;
}

void StreamingFlowGraphBuilder::LoadAndSetupTypeParameters(
    ActiveClass* active_class,
    const Object& set_on,
    intptr_t type_parameter_count,
    const Function& parameterized_function) {
  ASSERT(type_parameter_count >= 0);
  if (type_parameter_count == 0) {
    return;
  }
  ASSERT(set_on.IsClass() || set_on.IsFunction());
  bool set_on_class = set_on.IsClass();
  ASSERT(set_on_class == parameterized_function.IsNull());

  // First setup the type parameters, so if any of the following code uses it
  // (in a recursive way) we're fine.
  TypeArguments& type_parameters = TypeArguments::Handle(Z);
  TypeParameter& parameter = TypeParameter::Handle(Z);
  const Type& null_bound = Type::Handle(Z);

  // Step a) Create array of [TypeParameter] objects (without bound).
  type_parameters = TypeArguments::New(type_parameter_count);
  {
    AlternativeReadingScope alt(reader_);
    for (intptr_t i = 0; i < type_parameter_count; i++) {
      SkipFlags();
      SkipListOfExpressions();  // read annotations.
      parameter = TypeParameter::New(
          set_on_class ? *active_class->klass : Class::Handle(Z),
          parameterized_function, i,
          H.DartSymbol(ReadStringReference()),  // read ith name index.
          null_bound, TokenPosition::kNoSource);
      type_parameters.SetTypeAt(i, parameter);
      SkipDartType();  // read guard.
    }
  }

  if (set_on.IsClass()) {
    Class::Cast(set_on).set_type_parameters(type_parameters);
  } else {
    Function::Cast(set_on).set_type_parameters(type_parameters);
  }

  const Function* enclosing = NULL;
  if (!parameterized_function.IsNull()) {
    enclosing = &parameterized_function;
  }
  ActiveTypeParametersScope(active_class, enclosing, type_parameters, Z);

  // Step b) Fill in the bounds of all [TypeParameter]s.
  for (intptr_t i = 0; i < type_parameter_count; i++) {
    SkipFlags();
    SkipListOfExpressions();  // read annotations.
    SkipStringReference();    // read ith name index.

    // TODO(github.com/dart-lang/kernel/issues/42): This should be handled
    // by the frontend.
    parameter ^= type_parameters.TypeAt(i);
    const Tag tag = PeekTag();  // peek ith bound type.
    if (tag == kDynamicType) {
      SkipDartType();  // read ith bound.
      parameter.set_bound(Type::Handle(Z, I->object_store()->object_type()));
    } else {
      AbstractType& bound =
          T.BuildTypeWithoutFinalization();  // read ith bound.
      if (bound.IsMalformedOrMalbounded()) {
        bound = I->object_store()->object_type();
      }
      parameter.set_bound(bound);
    }
  }
}

void StreamingFlowGraphBuilder::SetupFunctionParameters(
    ActiveClass* active_class,
    const Class& klass,
    const Function& function,
    bool is_method,
    bool is_closure,
    FunctionNodeHelper* function_node_helper) {
  ASSERT(!(is_method && is_closure));
  bool is_factory = function.IsFactory();
  intptr_t extra_parameters = (is_method || is_closure || is_factory) ? 1 : 0;

  if (!is_factory) {
    LoadAndSetupTypeParameters(active_class, function, ReadListLength(),
                               function);
    function_node_helper->SetJustRead(FunctionNodeHelper::kTypeParameters);
  }

  ActiveTypeParametersScope scope(
      active_class, &function,
      TypeArguments::Handle(Z, function.type_parameters()), Z);

  function_node_helper->ReadUntilExcluding(
      FunctionNodeHelper::kPositionalParameters);

  intptr_t required_parameter_count =
      function_node_helper->required_parameter_count_;
  intptr_t total_parameter_count = function_node_helper->total_parameter_count_;

  intptr_t positional_parameter_count = ReadListLength();  // read list length.

  intptr_t named_parameter_count =
      total_parameter_count - positional_parameter_count;

  function.set_num_fixed_parameters(extra_parameters +
                                    required_parameter_count);
  if (named_parameter_count > 0) {
    function.SetNumOptionalParameters(named_parameter_count, false);
  } else {
    function.SetNumOptionalParameters(
        positional_parameter_count - required_parameter_count, true);
  }
  intptr_t parameter_count = extra_parameters + total_parameter_count;
  function.set_parameter_types(
      Array::Handle(Z, Array::New(parameter_count, Heap::kOld)));
  function.set_parameter_names(
      Array::Handle(Z, Array::New(parameter_count, Heap::kOld)));
  intptr_t pos = 0;
  if (is_method) {
    ASSERT(!klass.IsNull());
    function.SetParameterTypeAt(pos, H.GetCanonicalType(klass));
    function.SetParameterNameAt(pos, Symbols::This());
    pos++;
  } else if (is_closure) {
    function.SetParameterTypeAt(pos, AbstractType::dynamic_type());
    function.SetParameterNameAt(pos, Symbols::ClosureParameter());
    pos++;
  } else if (is_factory) {
    function.SetParameterTypeAt(pos, AbstractType::dynamic_type());
    function.SetParameterNameAt(pos, Symbols::TypeArgumentsParameter());
    pos++;
  }

  for (intptr_t i = 0; i < positional_parameter_count; ++i, ++pos) {
    // Read ith variable declaration.
    VariableDeclarationHelper helper(this);
    helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
    const AbstractType& type = T.BuildTypeWithoutFinalization();  // read type.
    Tag tag = ReadTag();  // read (first part of) initializer.
    if (tag == kSomething) {
      SkipExpression();  // read (actual) initializer.
    }

    function.SetParameterTypeAt(
        pos, type.IsMalformed() ? Type::dynamic_type() : type);
    function.SetParameterNameAt(pos, H.DartSymbol(helper.name_index_));
  }

  intptr_t named_parameter_count_check = ReadListLength();  // read list length.
  ASSERT(named_parameter_count_check == named_parameter_count);
  for (intptr_t i = 0; i < named_parameter_count; ++i, ++pos) {
    // Read ith variable declaration.
    VariableDeclarationHelper helper(this);
    helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
    const AbstractType& type = T.BuildTypeWithoutFinalization();  // read type.
    Tag tag = ReadTag();  // read (first part of) initializer.
    if (tag == kSomething) {
      SkipExpression();  // read (actual) initializer.
    }

    function.SetParameterTypeAt(
        pos, type.IsMalformed() ? Type::dynamic_type() : type);
    function.SetParameterNameAt(pos, H.DartSymbol(helper.name_index_));
  }

  function_node_helper->SetJustRead(FunctionNodeHelper::kNamedParameters);

  // The result type for generative constructors has already been set.
  if (!function.IsGenerativeConstructor()) {
    const AbstractType& return_type =
        T.BuildTypeWithoutFinalization();  // read return type.
    function.set_result_type(return_type.IsMalformed() ? Type::dynamic_type()
                                                       : return_type);
    function_node_helper->SetJustRead(FunctionNodeHelper::kReturnType);
  }
}

RawObject* StreamingFlowGraphBuilder::BuildParameterDescriptor(
    intptr_t kernel_offset) {
  SetOffset(kernel_offset);
  ReadUntilFunctionNode();  // read until function node.
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
    VariableDeclarationHelper helper(this);
    helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);
    param_descriptor.SetAt(entry_start + Parser::kParameterIsFinalOffset,
                           helper.IsFinal() ? Bool::True() : Bool::False());

    Tag tag = ReadTag();  // read (first part of) initializer.
    if (tag == kSomething) {
      // this will (potentially) read the initializer, but reset the position.
      Instance& constant =
          constant_evaluator_.EvaluateExpression(ReaderOffset());
      SkipExpression();  // read (actual) initializer.
      param_descriptor.SetAt(entry_start + Parser::kParameterDefaultValueOffset,
                             constant);
    } else {
      param_descriptor.SetAt(entry_start + Parser::kParameterDefaultValueOffset,
                             Object::null_instance());
    }

    param_descriptor.SetAt(entry_start + Parser::kParameterMetadataOffset,
                           /* Issue(28434): Missing parameter metadata. */
                           Object::null_instance());
  }
  return param_descriptor.raw();
}

RawObject* StreamingFlowGraphBuilder::EvaluateMetadata(intptr_t kernel_offset) {
  SetOffset(kernel_offset);
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

  intptr_t list_length = ReadListLength();  // read list length.
  const Array& metadata_values = Array::Handle(Z, Array::New(list_length));
  for (intptr_t i = 0; i < list_length; ++i) {
    // this will (potentially) read the expression, but reset the position.
    Instance& value = constant_evaluator_.EvaluateExpression(ReaderOffset());
    SkipExpression();  // read (actual) initializer.
    metadata_values.SetAt(i, value);
  }

  return metadata_values.raw();
}

void StreamingFlowGraphBuilder::CollectTokenPositionsFor(
    intptr_t script_index,
    intptr_t initial_script_index,
    intptr_t kernel_offset,
    GrowableArray<intptr_t>* record_token_positions_in,
    GrowableArray<intptr_t>* record_yield_positions_in) {
  record_token_positions_into_ = record_token_positions_in;
  record_yield_positions_into_ = record_yield_positions_in;
  record_for_script_id_ = script_index;
  current_script_id_ = initial_script_index;

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
  } else {
    H.ReportError("Unsupported tag at this point: %d.", tag);
    UNREACHABLE();
  }

  record_token_positions_into_ = NULL;
  record_yield_positions_into_ = NULL;
  record_for_script_id_ = -1;
}

intptr_t StreamingFlowGraphBuilder::SourceTableSize() {
  AlternativeReadingScope alt(reader_);
  intptr_t library_count = reader_->ReadFromIndexNoReset(
      reader_->size(), LibraryCountFieldCountFromEnd, 1, 0);
  intptr_t source_table_offset = reader_->ReadFromIndexNoReset(
      reader_->size(),
      LibraryCountFieldCountFromEnd + 1 + library_count + 1 +
          SourceTableFieldCountFromFirstLibraryOffset,
      1, 0);
  SetOffset(source_table_offset);  // read source table offset.
  return reader_->ReadUInt32();    // read source table size.
}

intptr_t StreamingFlowGraphBuilder::GetOffsetForSourceInfo(intptr_t index) {
  AlternativeReadingScope alt(reader_);
  intptr_t library_count = reader_->ReadFromIndexNoReset(
      reader_->size(), LibraryCountFieldCountFromEnd, 1, 0);
  intptr_t source_table_offset = reader_->ReadFromIndexNoReset(
      reader_->size(),
      LibraryCountFieldCountFromEnd + 1 + library_count + 1 +
          SourceTableFieldCountFromFirstLibraryOffset,
      1, 0);
  intptr_t next_field_offset = reader_->ReadUInt32();
  SetOffset(source_table_offset);
  intptr_t size = reader_->ReadUInt32();  // read source table size.

  return reader_->ReadFromIndexNoReset(next_field_offset, 0, size, index);
}

String& StreamingFlowGraphBuilder::SourceTableUriFor(intptr_t index) {
  AlternativeReadingScope alt(reader_);
  SetOffset(GetOffsetForSourceInfo(index));
  intptr_t size = ReadUInt();  // read uri List<byte> size.
  return H.DartString(reader_->CopyDataIntoZone(Z, ReaderOffset(), size), size,
                      Heap::kOld);
}

String& StreamingFlowGraphBuilder::GetSourceFor(intptr_t index) {
  AlternativeReadingScope alt(reader_);
  SetOffset(GetOffsetForSourceInfo(index));
  SkipBytes(ReadUInt());       // skip uri.
  intptr_t size = ReadUInt();  // read source List<byte> size.
  return H.DartString(reader_->CopyDataIntoZone(Z, ReaderOffset(), size), size,
                      Heap::kOld);
}

Array& StreamingFlowGraphBuilder::GetLineStartsFor(intptr_t index) {
  AlternativeReadingScope alt(reader_);
  SetOffset(GetOffsetForSourceInfo(index));
  SkipBytes(ReadUInt());       // skip uri.
  SkipBytes(ReadUInt());       // skip source.
  intptr_t size = ReadUInt();  // read line starts length.

  Array& array_object = Array::Handle(Z, Array::New(size, Heap::kOld));
  Smi& value = Smi::Handle(Z);
  intptr_t previous_line_start = 0;
  for (intptr_t j = 0; j < size; ++j) {
    intptr_t line_start = ReadUInt() + previous_line_start;
    value = Smi::New(line_start);
    array_object.SetAt(j, value);
    previous_line_start = line_start;
  }
  return array_object;
}

void StreamingFlowGraphBuilder::EnsureMetadataIsScanned() {
  // Scan metadata mappings only once.
  if (metadata_scanned_) {
    return;
  }
  metadata_scanned_ = true;

  const intptr_t kUInt32Size = 4;
  Reader reader(H.metadata_mappings());

  // Scan through metadata mappings in reverse direction.

  // Read metadataMappings length.
  intptr_t offset = reader.size() - kUInt32Size;
  uint32_t metadata_num = reader.ReadUInt32At(offset);

  if (metadata_num == 0) {
    ASSERT(H.metadata_mappings().LengthInBytes() == kUInt32Size);
    return;
  }

  // Read metadataMappings elements.
  for (uint32_t i = 0; i < metadata_num; ++i) {
    // Read nodeReferences length.
    offset -= kUInt32Size;
    uint32_t node_references_num = reader.ReadUInt32At(offset);

    // Skip nodeReferences and read nodeOffsetToMetadataOffset length.
    offset -= node_references_num * kUInt32Size + kUInt32Size;
    uint32_t mappings_num = reader.ReadUInt32At(offset);

    // Skip nodeOffsetToMetadataOffset and read tag.
    offset -= mappings_num * 2 * kUInt32Size + kUInt32Size;
    StringIndex tag = StringIndex(reader.ReadUInt32At(offset));

    // Check recognized metadata
    if (H.StringEquals(tag, DirectCallMetadataHelper::tag())) {
      ASSERT(node_references_num == 0);

      if (mappings_num > 0) {
        if (!FLAG_precompiled_mode) {
          FATAL("DirectCallMetadata is allowed in precompiled mode only");
        }
        direct_call_metadata_helper_.SetMetadataMappings(offset + kUInt32Size,
                                                         mappings_num);
      }
    }
  }
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
