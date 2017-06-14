// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/kernel_binary.h"
#include "platform/globals.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/kernel.h"
#include "vm/kernel_to_il.h"
#include "vm/os.h"

#if defined(DEBUG)
#define TRACE_READ_OFFSET()                                                    \
  do {                                                                         \
    if (FLAG_trace_kernel_binary) reader->DumpOffset(DART_PRETTY_FUNCTION);    \
  } while (0)
#else
#define TRACE_READ_OFFSET()
#endif

namespace dart {


namespace kernel {


Reader::~Reader() {
  delete[] string_offsets_;
  delete[] canonical_name_parents_;
  delete[] canonical_name_strings_;
}


template <typename T>
template <typename IT>
void List<T>::ReadFrom(Reader* reader, TreeNode* parent) {
  TRACE_READ_OFFSET();
  ASSERT(parent != NULL);
  int length = reader->ReadListLength();
  EnsureInitialized(length);

  for (intptr_t i = 0; i < length_; i++) {
    IT* object = GetOrCreate<IT>(i, parent);
    object->ReadFrom(reader);
  }
}


template <typename T>
template <typename IT>
void List<T>::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  int length = reader->ReadListLength();
  EnsureInitialized(length);

  for (intptr_t i = 0; i < length_; i++) {
    GetOrCreate<IT>(i)->ReadFrom(reader);
  }
}


template <typename T>
template <typename IT>
void List<T>::ReadFromStatic(Reader* reader) {
  TRACE_READ_OFFSET();
  int length = reader->ReadListLength();
  EnsureInitialized(length);

  for (intptr_t i = 0; i < length_; i++) {
    ASSERT(array_[i] == NULL);
    array_[i] = IT::ReadFrom(reader);
  }
}


void TypeParameterList::ReadFrom(Reader* reader) {
  // It is possible for the bound of the first type parameter to refer to
  // the second type parameter. This means we need to create [TypeParameter]
  // objects before reading the bounds.
  int length = reader->ReadListLength();
  EnsureInitialized(length);

  // Make all [TypeParameter]s available in scope.
  for (intptr_t i = 0; i < length; i++) {
    TypeParameter* parameter = (*this)[i] = new TypeParameter();
    reader->helper()->type_parameters().Push(parameter);
  }

  if (length > 0) {
    // Read all [TypeParameter]s and their bounds.
    for (intptr_t i = 0; i < length; i++) {
      (*this)[i]->ReadFrom(reader);
    }
    first_offset = (*this)[0]->kernel_offset_;
  }
}


NamedParameter* NamedParameter::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  StringIndex name_index(reader->ReadUInt());
  DartType* type = DartType::ReadFrom(reader);
  return new NamedParameter(name_index, type);
}


template <typename B, typename S>
class DowncastReader {
 public:
  static S* ReadFrom(Reader* reader) {
    TRACE_READ_OFFSET();
    return S::Cast(B::ReadFrom(reader));
  }
};


class VariableDeclarationImpl {
 public:
  static VariableDeclaration* ReadFrom(Reader* reader) {
    TRACE_READ_OFFSET();
    return VariableDeclaration::ReadFromImpl(reader, false);
  }
};


void SourceTable::ReadFrom(Reader* reader) {
  size_ = reader->ReadUInt();
  sources_ = new Source[size_];

  // Build a table of the URI offsets.
  intptr_t* end_offsets = new intptr_t[size_];
  for (intptr_t i = 0; i < size_; ++i) {
    end_offsets[i] = reader->ReadUInt();
  }

  // Read the URI strings.
  intptr_t start_offset = 0;
  for (intptr_t i = 0; i < size_; ++i) {
    intptr_t length = end_offsets[i] - start_offset;
    uint8_t* buffer = new uint8_t[length];
    memmove(buffer, reader->buffer() + reader->offset(), length);
    reader->Consume(length);

    sources_[i].uri_ = buffer;
    sources_[i].uri_size_ = length;

    start_offset = end_offsets[i];
  }

  // Read the source code strings and line starts.
  for (intptr_t i = 0; i < size_; ++i) {
    intptr_t length = reader->ReadUInt();
    uint8_t* string_buffer = new uint8_t[length];
    memmove(string_buffer, reader->buffer() + reader->offset(), length);
    reader->Consume(length);
    intptr_t line_count = reader->ReadUInt();
    intptr_t* line_starts = new intptr_t[line_count];
    intptr_t previous_line_start = 0;
    for (intptr_t j = 0; j < line_count; ++j) {
      intptr_t line_start = reader->ReadUInt() + previous_line_start;
      line_starts[j] = line_start;
      previous_line_start = line_start;
    }

    sources_[i].source_code_ = string_buffer;
    sources_[i].source_code_size_ = length;
    sources_[i].line_starts_ = line_starts;
    sources_[i].line_count_ = line_count;
  }
}


Library* Library::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  int flags = reader->ReadFlags();
  ASSERT(flags == 0);  // external libraries not supported
  kernel_data_ = reader->buffer();
  kernel_data_size_ = reader->size();

  canonical_name_ = reader->ReadCanonicalNameReference();
  name_index_ = StringIndex(reader->ReadUInt());
  import_uri_index_ = reader->CanonicalNameString(canonical_name_);
  source_uri_index_ = reader->ReadUInt();
  reader->set_current_script_id(source_uri_index_);

  annotations_.ReadFromStatic<Expression>(reader);
  dependencies().ReadFromStatic<LibraryDependency>(reader);
  int num_typedefs = reader->ReadUInt();
  typedefs().EnsureInitialized(num_typedefs);
  for (intptr_t i = 0; i < num_typedefs; i++) {
    typedefs().GetOrCreate<Typedef>(i, this)->ReadFrom(reader);
  }
  int num_classes = reader->ReadUInt();
  classes().EnsureInitialized(num_classes);
  for (intptr_t i = 0; i < num_classes; i++) {
    Tag tag = reader->ReadTag();
    ASSERT(tag == kClass);
    NormalClass* klass = classes().GetOrCreate<NormalClass>(i, this);
    klass->ReadFrom(reader);
  }

  fields().ReadFrom<Field>(reader, this);
  procedures().ReadFrom<Procedure>(reader, this);

  can_stream_ =
      classes().CanStream() && fields().CanStream() && procedures().CanStream();

  return this;
}


LibraryDependency* LibraryDependency::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();

  LibraryDependency* node = new LibraryDependency();
  node->flags_ = reader->ReadFlags();
  node->annotations_.ReadFromStatic<Expression>(reader);
  node->target_reference_ = Reference::ReadLibraryFrom(reader);
  node->name_index_ = StringIndex(reader->ReadUInt());
  node->combinators_.ReadFromStatic<Combinator>(reader);

  return node;
}


Combinator* Combinator::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();

  Combinator* node = new Combinator();
  node->is_show_ = (reader->ReadByte() == 1);
  int num_names = reader->ReadUInt();
  node->name_indices_.Initialize(num_names);
  for (intptr_t i = 0; i < num_names; ++i) {
    node->name_indices_[i] = reader->ReadUInt();
  }

  return node;
}


Typedef* Typedef::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();

  canonical_name_ = reader->ReadCanonicalNameReference();
  position_ = reader->ReadPosition(false);
  name_index_ = StringIndex(reader->ReadUInt());
  source_uri_index_ = reader->ReadUInt();
  type_parameters_.ReadFrom(reader);
  type_ = DartType::ReadFrom(reader);

  return this;
}


Class* Class::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();

  kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  canonical_name_ = reader->ReadCanonicalNameReference();
  position_ = reader->ReadPosition(false);
  is_abstract_ = reader->ReadBool();
  name_index_ = StringIndex(reader->ReadUInt());
  source_uri_index_ = reader->ReadUInt();
  reader->set_current_script_id(source_uri_index_);
  reader->record_token_position(position_);
  annotations_.ReadFromStatic<Expression>(reader);

  can_stream_ = annotations_.CanStream();

  return this;
}


NormalClass* NormalClass::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Class::ReadFrom(reader);
  TypeParameterScope<ReaderHelper> scope(reader->helper());

  type_parameters_.ReadFrom(reader);
  DartType* type = reader->ReadOptional<DartType>();

  super_class_ = InterfaceType::Cast(type);
  reader->ReadOptional<DartType>();  // Mixed-in type is unused.
  implemented_classes_.ReadFromStatic<DowncastReader<DartType, InterfaceType> >(
      reader);
  fields_.ReadFrom<Field>(reader, this);
  constructors_.ReadFrom<Constructor>(reader, this);
  procedures_.ReadFrom<Procedure>(reader, this);

  can_stream_ = can_stream_ && fields_.CanStream() &&
                constructors_.CanStream() && procedures_.CanStream();

  return this;
}


MixinClass* MixinClass::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TypeParameterScope<ReaderHelper> scope(reader->helper());

  Class::ReadFrom(reader);
  type_parameters_.ReadFrom(reader);
  first_ = InterfaceType::Cast(DartType::ReadFrom(reader));
  second_ = InterfaceType::Cast(DartType::ReadFrom(reader));
  implemented_classes_.ReadFromStatic<DowncastReader<DartType, InterfaceType> >(
      reader);
  constructors_.ReadFrom<Constructor>(reader, this);

  can_stream_ = constructors_.CanStream();

  return this;
}


NameIndex Reference::ReadMemberFrom(Reader* reader, bool allow_null) {
  TRACE_READ_OFFSET();
  NameIndex canonical_name = reader->ReadCanonicalNameReference();
  if ((canonical_name == -1) && !allow_null) {
    FATAL("Expected a valid member reference, but got `null`");
  }
  return canonical_name;
}


NameIndex Reference::ReadClassFrom(Reader* reader, bool allow_null) {
  TRACE_READ_OFFSET();
  NameIndex canonical_name = reader->ReadCanonicalNameReference();
  if ((canonical_name == -1) && !allow_null) {
    FATAL("Expected a valid class reference, but got `null`");
  }
  return canonical_name;
}


NameIndex Reference::ReadTypedefFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  NameIndex canonical_name = reader->ReadCanonicalNameReference();
  if (canonical_name == -1) {
    FATAL("Expected a valid typedef reference, but got `null`");
  }
  return canonical_name;
}


NameIndex Reference::ReadLibraryFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  NameIndex canonical_name = reader->ReadCanonicalNameReference();
  if (canonical_name == -1) {
    FATAL("Expected a valid typedef reference, but got `null`");
  }
  return canonical_name;
}


Field* Field::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  kernel_offset_ = reader->offset();  // Notice the ReadTag() below.
  Tag tag = reader->ReadTag();
  ASSERT(tag == kField);

  canonical_name_ = reader->ReadCanonicalNameReference();
  position_ = reader->ReadPosition(false);
  end_position_ = reader->ReadPosition(false);
  flags_ = reader->ReadFlags();
  reader->ReadUInt();  // parent class binary offset (or 0).
  name_ = Name::ReadFrom(reader);
  source_uri_index_ = reader->ReadUInt();
  reader->set_current_script_id(source_uri_index_);
  reader->record_token_position(position_);
  reader->record_token_position(end_position_);
  annotations_.ReadFromStatic<Expression>(reader);
  type_ = DartType::ReadFrom(reader);
  initializer_ = reader->ReadOptional<Expression>();

  can_stream_ = (initializer_ == NULL || initializer_->can_stream()) &&
                annotations_.CanStream();

  return this;
}


Constructor* Constructor::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  kernel_offset_ = reader->offset();  // Notice the ReadTag() below.
  Tag tag = reader->ReadTag();
  ASSERT(tag == kConstructor);

  canonical_name_ = reader->ReadCanonicalNameReference();
  VariableScope<ReaderHelper> parameters(reader->helper());
  position_ = reader->ReadPosition();
  end_position_ = reader->ReadPosition();
  flags_ = reader->ReadFlags();
  reader->ReadUInt();  // parent class binary offset.
  name_ = Name::ReadFrom(reader);
  annotations_.ReadFromStatic<Expression>(reader);
  function_ = FunctionNode::ReadFrom(reader);
  initializers_.ReadFromStatic<Initializer>(reader);

  can_stream_ = annotations_.CanStream() && function_->can_stream() &&
                initializers_.CanStream();

  return this;
}


Procedure* Procedure::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  kernel_offset_ = reader->offset();  // Notice the ReadTag() below.
  Tag tag = reader->ReadTag();
  ASSERT(tag == kProcedure);

  canonical_name_ = reader->ReadCanonicalNameReference();
  VariableScope<ReaderHelper> parameters(reader->helper());
  position_ = reader->ReadPosition(false);
  end_position_ = reader->ReadPosition(false);
  kind_ = static_cast<ProcedureKind>(reader->ReadByte());
  flags_ = reader->ReadFlags();
  reader->ReadUInt();  // parent class binary offset (or 0).
  name_ = Name::ReadFrom(reader);
  source_uri_index_ = reader->ReadUInt();
  reader->set_current_script_id(source_uri_index_);
  reader->record_token_position(position_);
  reader->record_token_position(end_position_);
  annotations_.ReadFromStatic<Expression>(reader);
  function_ = reader->ReadOptional<FunctionNode>();

  can_stream_ = annotations_.CanStream() &&
                (function_ == NULL || function_->can_stream());

  return this;
}


Initializer* Initializer::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  switch (tag) {
    case kInvalidInitializer:
      return InvalidInitializer::ReadFromImpl(reader);
    case kFieldInitializer:
      return FieldInitializer::ReadFromImpl(reader);
    case kSuperInitializer:
      return SuperInitializer::ReadFromImpl(reader);
    case kRedirectingInitializer:
      return RedirectingInitializer::ReadFromImpl(reader);
    case kLocalInitializer:
      return LocalInitializer::ReadFromImpl(reader);
    default:
      UNREACHABLE();
  }
  return NULL;
}


InvalidInitializer* InvalidInitializer::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  return new InvalidInitializer();
}


FieldInitializer* FieldInitializer::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  FieldInitializer* initializer = new FieldInitializer();
  initializer->field_reference_ = Reference::ReadMemberFrom(reader);
  initializer->value_ = Expression::ReadFrom(reader);

  initializer->can_stream_ = initializer->value_->can_stream();

  return initializer;
}


SuperInitializer* SuperInitializer::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  SuperInitializer* init = new SuperInitializer();
  init->target_reference_ = Reference::ReadMemberFrom(reader);
  init->arguments_ = Arguments::ReadFrom(reader);

  init->can_stream_ = init->arguments_->can_stream();

  return init;
}


RedirectingInitializer* RedirectingInitializer::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  RedirectingInitializer* init = new RedirectingInitializer();
  init->target_reference_ = Reference::ReadMemberFrom(reader);
  init->arguments_ = Arguments::ReadFrom(reader);

  init->can_stream_ = init->arguments_->can_stream();

  return init;
}


LocalInitializer* LocalInitializer::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  LocalInitializer* init = new LocalInitializer();
  init->variable_ = VariableDeclaration::ReadFromImpl(reader, false);

  init->can_stream_ = init->variable_->can_stream();

  return init;
}


Expression* Expression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  uint8_t payload = 0;
  Tag tag = reader->ReadTag(&payload);
  switch (tag) {
    case kInvalidExpression:
      return InvalidExpression::ReadFrom(reader);
    case kVariableGet:
      return VariableGet::ReadFrom(reader);
    case kSpecializedVariableGet:
      return VariableGet::ReadFrom(reader, payload);
    case kVariableSet:
      return VariableSet::ReadFrom(reader);
    case kSpecializedVariableSet:
      return VariableSet::ReadFrom(reader, payload);
    case kPropertyGet:
      return PropertyGet::ReadFrom(reader);
    case kPropertySet:
      return PropertySet::ReadFrom(reader);
    case kDirectPropertyGet:
      return DirectPropertyGet::ReadFrom(reader);
    case kDirectPropertySet:
      return DirectPropertySet::ReadFrom(reader);
    case kStaticGet:
      return StaticGet::ReadFrom(reader);
    case kStaticSet:
      return StaticSet::ReadFrom(reader);
    case kMethodInvocation:
      return MethodInvocation::ReadFrom(reader);
    case kDirectMethodInvocation:
      return DirectMethodInvocation::ReadFrom(reader);
    case kStaticInvocation:
      return StaticInvocation::ReadFrom(reader, false);
    case kConstStaticInvocation:
      return StaticInvocation::ReadFrom(reader, true);
    case kConstructorInvocation:
      return ConstructorInvocation::ReadFrom(reader, false);
    case kConstConstructorInvocation:
      return ConstructorInvocation::ReadFrom(reader, true);
    case kNot:
      return Not::ReadFrom(reader);
    case kLogicalExpression:
      return LogicalExpression::ReadFrom(reader);
    case kConditionalExpression:
      return ConditionalExpression::ReadFrom(reader);
    case kStringConcatenation:
      return StringConcatenation::ReadFrom(reader);
    case kIsExpression:
      return IsExpression::ReadFrom(reader);
    case kAsExpression:
      return AsExpression::ReadFrom(reader);
    case kSymbolLiteral:
      return SymbolLiteral::ReadFrom(reader);
    case kTypeLiteral:
      return TypeLiteral::ReadFrom(reader);
    case kThisExpression:
      return ThisExpression::ReadFrom(reader);
    case kRethrow:
      return Rethrow::ReadFrom(reader);
    case kThrow:
      return Throw::ReadFrom(reader);
    case kListLiteral:
      return ListLiteral::ReadFrom(reader, false);
    case kConstListLiteral:
      return ListLiteral::ReadFrom(reader, true);
    case kMapLiteral:
      return MapLiteral::ReadFrom(reader, false);
    case kConstMapLiteral:
      return MapLiteral::ReadFrom(reader, true);
    case kAwaitExpression:
      return AwaitExpression::ReadFrom(reader);
    case kFunctionExpression:
      return FunctionExpression::ReadFrom(reader);
    case kLet:
      return Let::ReadFrom(reader);
    case kVectorCreation:
      return VectorCreation::ReadFrom(reader);
    case kVectorGet:
      return VectorGet::ReadFrom(reader);
    case kVectorSet:
      return VectorSet::ReadFrom(reader);
    case kVectorCopy:
      return VectorCopy::ReadFrom(reader);
    case kClosureCreation:
      return ClosureCreation::ReadFrom(reader);
    case kBigIntLiteral:
      return BigintLiteral::ReadFrom(reader);
    case kStringLiteral:
      return StringLiteral::ReadFrom(reader);
    case kSpecialIntLiteral:
      return IntLiteral::ReadFrom(reader, payload);
    case kNegativeIntLiteral:
      return IntLiteral::ReadFrom(reader, true);
    case kPositiveIntLiteral:
      return IntLiteral::ReadFrom(reader, false);
    case kDoubleLiteral:
      return DoubleLiteral::ReadFrom(reader);
    case kTrueLiteral:
      return BoolLiteral::ReadFrom(reader, true);
    case kFalseLiteral:
      return BoolLiteral::ReadFrom(reader, false);
    case kNullLiteral:
      return NullLiteral::ReadFrom(reader);
    default:
      UNREACHABLE();
  }
  return NULL;
}


InvalidExpression* InvalidExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  InvalidExpression* invalid_expression = new InvalidExpression();
  invalid_expression->kernel_offset_ =
      reader->offset() - 1;  // -1 to include tag byte.
  return invalid_expression;
}


VariableGet* VariableGet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableGet* get = new VariableGet();
  get->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  get->position_ = reader->ReadPosition();
  get->variable_kernel_offset_ = reader->ReadUInt();
  get->variable_ = reader->helper()->variables().Lookup(reader->ReadUInt());
  ASSERT(get->variable_->kernel_offset_no_tag() ==
         get->variable_kernel_offset_);
  reader->ReadOptional<DartType>();  // Unused promoted type.
  return get;
}


VariableGet* VariableGet::ReadFrom(Reader* reader, uint8_t payload) {
  TRACE_READ_OFFSET();
  VariableGet* get = new VariableGet();
  get->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  get->position_ = reader->ReadPosition();
  get->variable_kernel_offset_ = reader->ReadUInt();
  get->variable_ = reader->helper()->variables().Lookup(payload);
  ASSERT(get->variable_->kernel_offset_no_tag() ==
         get->variable_kernel_offset_);
  return get;
}


VariableSet* VariableSet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableSet* set = new VariableSet();
  set->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  set->position_ = reader->ReadPosition();
  set->variable_kernel_offset_ = reader->ReadUInt();
  set->variable_ = reader->helper()->variables().Lookup(reader->ReadUInt());
  ASSERT(set->variable_->kernel_offset_no_tag() ==
         set->variable_kernel_offset_);
  set->expression_ = Expression::ReadFrom(reader);

  set->can_stream_ = set->expression_->can_stream();

  return set;
}


VariableSet* VariableSet::ReadFrom(Reader* reader, uint8_t payload) {
  TRACE_READ_OFFSET();
  VariableSet* set = new VariableSet();
  set->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  set->variable_ = reader->helper()->variables().Lookup(payload);
  set->position_ = reader->ReadPosition();
  set->variable_kernel_offset_ = reader->ReadUInt();
  ASSERT(set->variable_->kernel_offset_no_tag() ==
         set->variable_kernel_offset_);
  set->expression_ = Expression::ReadFrom(reader);

  set->can_stream_ = set->expression_->can_stream();

  return set;
}


PropertyGet* PropertyGet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  PropertyGet* get = new PropertyGet();
  get->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  get->position_ = reader->ReadPosition();
  get->receiver_ = Expression::ReadFrom(reader);
  get->name_ = Name::ReadFrom(reader);
  get->interface_target_reference_ = Reference::ReadMemberFrom(reader, true);

  get->can_stream_ = get->receiver_->can_stream();

  return get;
}


PropertySet* PropertySet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  PropertySet* set = new PropertySet();
  set->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  set->position_ = reader->ReadPosition();
  set->receiver_ = Expression::ReadFrom(reader);
  set->name_ = Name::ReadFrom(reader);
  set->value_ = Expression::ReadFrom(reader);
  set->interface_target_reference_ = Reference::ReadMemberFrom(reader, true);

  set->can_stream_ = set->receiver_->can_stream() && set->value_->can_stream();

  return set;
}


DirectPropertyGet* DirectPropertyGet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  DirectPropertyGet* get = new DirectPropertyGet();
  get->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  get->position_ = reader->ReadPosition();
  get->receiver_ = Expression::ReadFrom(reader);
  get->target_reference_ = Reference::ReadMemberFrom(reader);

  get->can_stream_ = get->receiver_->can_stream();

  return get;
}


DirectPropertySet* DirectPropertySet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  DirectPropertySet* set = new DirectPropertySet();
  set->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  set->position_ = reader->ReadPosition();
  set->receiver_ = Expression::ReadFrom(reader);
  set->target_reference_ = Reference::ReadMemberFrom(reader);
  set->value_ = Expression::ReadFrom(reader);

  set->can_stream_ = set->receiver_->can_stream() && set->value_->can_stream();

  return set;
}


StaticGet* StaticGet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  StaticGet* get = new StaticGet();
  get->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  get->position_ = reader->ReadPosition();
  get->target_reference_ = Reference::ReadMemberFrom(reader);
  return get;
}


StaticSet* StaticSet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  StaticSet* set = new StaticSet();
  set->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  set->position_ = reader->ReadPosition();
  set->target_reference_ = Reference::ReadMemberFrom(reader);
  set->expression_ = Expression::ReadFrom(reader);

  set->can_stream_ = set->expression_->can_stream();

  return set;
}


Arguments* Arguments::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Arguments* arguments = new Arguments();
  intptr_t num_arguments = reader->ReadUInt();
  arguments->types().ReadFromStatic<DartType>(reader);
  arguments->positional().ReadFromStatic<Expression>(reader);
  arguments->named().ReadFromStatic<NamedExpression>(reader);
  ASSERT(arguments->count() == num_arguments);

  arguments->can_stream_ =
      arguments->positional().CanStream() && arguments->named().CanStream();

  return arguments;
}


NamedExpression* NamedExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  StringIndex name_index(reader->ReadUInt());
  Expression* expression = Expression::ReadFrom(reader);
  NamedExpression* named = new NamedExpression(name_index, expression);

  named->can_stream_ = expression->can_stream();

  return named;
}


MethodInvocation* MethodInvocation::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  MethodInvocation* invocation = new MethodInvocation();
  invocation->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  invocation->position_ = reader->ReadPosition();
  invocation->receiver_ = Expression::ReadFrom(reader);
  invocation->name_ = Name::ReadFrom(reader);
  invocation->arguments_ = Arguments::ReadFrom(reader);
  invocation->interface_target_reference_ =
      Reference::ReadMemberFrom(reader, true);

  invocation->can_stream_ = invocation->receiver_->can_stream() &&
                            invocation->arguments_->can_stream();

  return invocation;
}


DirectMethodInvocation* DirectMethodInvocation::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  DirectMethodInvocation* invocation = new DirectMethodInvocation();
  invocation->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  invocation->receiver_ = Expression::ReadFrom(reader);
  invocation->target_reference_ = Reference::ReadMemberFrom(reader);
  invocation->arguments_ = Arguments::ReadFrom(reader);

  invocation->can_stream_ = invocation->receiver_->can_stream() &&
                            invocation->arguments_->can_stream();

  return invocation;
}


StaticInvocation* StaticInvocation::ReadFrom(Reader* reader, bool is_const) {
  TRACE_READ_OFFSET();
  StaticInvocation* invocation = new StaticInvocation();
  invocation->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  invocation->is_const_ = is_const;
  invocation->position_ = reader->ReadPosition();
  invocation->procedure_reference_ = Reference::ReadMemberFrom(reader);
  invocation->arguments_ = Arguments::ReadFrom(reader);

  invocation->can_stream_ = invocation->arguments_->can_stream();

  return invocation;
}


ConstructorInvocation* ConstructorInvocation::ReadFrom(Reader* reader,
                                                       bool is_const) {
  TRACE_READ_OFFSET();
  ConstructorInvocation* invocation = new ConstructorInvocation();
  invocation->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  invocation->is_const_ = is_const;
  invocation->position_ = reader->ReadPosition();
  invocation->target_reference_ = Reference::ReadMemberFrom(reader);
  invocation->arguments_ = Arguments::ReadFrom(reader);

  invocation->can_stream_ = invocation->arguments_->can_stream();

  return invocation;
}


Not* Not::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Not* n = new Not();
  n->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  n->expression_ = Expression::ReadFrom(reader);

  n->can_stream_ = n->expression_->can_stream();

  return n;
}


LogicalExpression* LogicalExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  LogicalExpression* expr = new LogicalExpression();
  expr->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  expr->left_ = Expression::ReadFrom(reader);
  expr->operator_ = static_cast<Operator>(reader->ReadByte());
  expr->right_ = Expression::ReadFrom(reader);

  expr->can_stream_ = expr->left_->can_stream() && expr->right_->can_stream();

  return expr;
}


ConditionalExpression* ConditionalExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  ConditionalExpression* expr = new ConditionalExpression();
  expr->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  expr->condition_ = Expression::ReadFrom(reader);
  expr->then_ = Expression::ReadFrom(reader);
  expr->otherwise_ = Expression::ReadFrom(reader);
  reader->ReadOptional<DartType>();  // Unused static type.

  expr->can_stream_ = expr->condition_->can_stream() &&
                      expr->then_->can_stream() &&
                      expr->otherwise_->can_stream();

  return expr;
}


StringConcatenation* StringConcatenation::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  StringConcatenation* concat = new StringConcatenation();
  concat->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  concat->position_ = reader->ReadPosition();
  concat->expressions_.ReadFromStatic<Expression>(reader);

  concat->can_stream_ = concat->expressions_.CanStream();

  return concat;
}


IsExpression* IsExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  IsExpression* expr = new IsExpression();
  expr->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  expr->position_ = reader->ReadPosition();
  expr->operand_ = Expression::ReadFrom(reader);
  expr->type_ = DartType::ReadFrom(reader);

  expr->can_stream_ = expr->operand_->can_stream();

  return expr;
}


AsExpression* AsExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  AsExpression* expr = new AsExpression();
  expr->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  expr->position_ = reader->ReadPosition();
  expr->operand_ = Expression::ReadFrom(reader);
  expr->type_ = DartType::ReadFrom(reader);

  expr->can_stream_ = expr->operand_->can_stream();

  return expr;
}


StringLiteral* StringLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  intptr_t offset = reader->offset() - 1;  // -1 to include tag byte.
  StringLiteral* lit = new StringLiteral(StringIndex(reader->ReadUInt()));
  lit->kernel_offset_ = offset;
  return lit;
}


BigintLiteral* BigintLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  intptr_t offset = reader->offset() - 1;  // -1 to include tag byte.
  BigintLiteral* lit = new BigintLiteral(StringIndex(reader->ReadUInt()));
  lit->kernel_offset_ = offset;
  return lit;
}


IntLiteral* IntLiteral::ReadFrom(Reader* reader, bool is_negative) {
  TRACE_READ_OFFSET();
  IntLiteral* literal = new IntLiteral();
  literal->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  literal->value_ = is_negative ? -static_cast<int64_t>(reader->ReadUInt())
                                : reader->ReadUInt();
  return literal;
}


IntLiteral* IntLiteral::ReadFrom(Reader* reader, uint8_t payload) {
  TRACE_READ_OFFSET();
  IntLiteral* literal = new IntLiteral();
  literal->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  literal->value_ = static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
  return literal;
}


DoubleLiteral* DoubleLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  DoubleLiteral* literal = new DoubleLiteral();
  literal->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  literal->value_index_ = StringIndex(reader->ReadUInt());
  return literal;
}


BoolLiteral* BoolLiteral::ReadFrom(Reader* reader, bool value) {
  TRACE_READ_OFFSET();
  BoolLiteral* lit = new BoolLiteral();
  lit->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  lit->value_ = value;
  return lit;
}


NullLiteral* NullLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  NullLiteral* lit = new NullLiteral();
  lit->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  return lit;
}


SymbolLiteral* SymbolLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  SymbolLiteral* lit = new SymbolLiteral();
  lit->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  lit->value_index_ = StringIndex(reader->ReadUInt());
  return lit;
}


TypeLiteral* TypeLiteral::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TypeLiteral* literal = new TypeLiteral();
  literal->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  literal->type_ = DartType::ReadFrom(reader);
  return literal;
}


ThisExpression* ThisExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  ThisExpression* this_expr = new ThisExpression();
  this_expr->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  return this_expr;
}


Rethrow* Rethrow::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Rethrow* rethrow = new Rethrow();
  rethrow->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  rethrow->position_ = reader->ReadPosition();
  return rethrow;
}


Throw* Throw::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Throw* t = new Throw();
  t->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  t->position_ = reader->ReadPosition();
  t->expression_ = Expression::ReadFrom(reader);

  t->can_stream_ = t->expression_->can_stream();

  return t;
}


ListLiteral* ListLiteral::ReadFrom(Reader* reader, bool is_const) {
  TRACE_READ_OFFSET();
  ListLiteral* literal = new ListLiteral();
  literal->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  literal->is_const_ = is_const;
  literal->position_ = reader->ReadPosition();
  literal->type_ = DartType::ReadFrom(reader);
  literal->expressions_.ReadFromStatic<Expression>(reader);

  literal->can_stream_ = literal->expressions_.CanStream();

  return literal;
}


MapLiteral* MapLiteral::ReadFrom(Reader* reader, bool is_const) {
  TRACE_READ_OFFSET();
  MapLiteral* literal = new MapLiteral();
  literal->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  literal->is_const_ = is_const;
  literal->position_ = reader->ReadPosition();
  literal->key_type_ = DartType::ReadFrom(reader);
  literal->value_type_ = DartType::ReadFrom(reader);
  literal->entries_.ReadFromStatic<MapEntry>(reader);

  literal->can_stream_ = literal->entries_.CanStream();

  return literal;
}


MapEntry* MapEntry::ReadFrom(Reader* reader) {
  MapEntry* entry = new MapEntry();
  entry->key_ = Expression::ReadFrom(reader);
  entry->value_ = Expression::ReadFrom(reader);

  entry->can_stream_ = entry->key_->can_stream() && entry->value_->can_stream();

  return entry;
}


AwaitExpression* AwaitExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  AwaitExpression* await = new AwaitExpression();
  await->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  await->operand_ = Expression::ReadFrom(reader);

  await->can_stream_ = await->operand_->can_stream();

  return await;
}


FunctionExpression* FunctionExpression::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> parameters(reader->helper());
  FunctionExpression* expr = new FunctionExpression();
  expr->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  expr->function_ = FunctionNode::ReadFrom(reader);

  expr->can_stream_ = false;

  return expr;
}


Let* Let::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> vars(reader->helper());
  PositionScope scope(reader);

  Let* let = new Let();
  let->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  let->variable_ = VariableDeclaration::ReadFromImpl(reader, false);
  let->body_ = Expression::ReadFrom(reader);
  let->position_ = reader->min_position();
  let->end_position_ = reader->max_position();

  let->can_stream_ = let->variable_->can_stream() && let->body_->can_stream();

  return let;
}


VectorCreation* VectorCreation::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();

  VectorCreation* vector_creation = new VectorCreation();
  vector_creation->kernel_offset_ =
      reader->offset() - 1;  // -1 to include tag byte.
  vector_creation->value_ = reader->ReadUInt();

  return vector_creation;
}


VectorGet* VectorGet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();

  VectorGet* vector_get = new VectorGet();
  vector_get->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  vector_get->vector_expression_ = Expression::ReadFrom(reader);
  vector_get->index_ = reader->ReadUInt();

  vector_get->can_stream_ = false;

  return vector_get;
}


VectorSet* VectorSet::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();

  VectorSet* vector_set = new VectorSet();
  vector_set->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  vector_set->vector_expression_ = Expression::ReadFrom(reader);
  vector_set->index_ = reader->ReadUInt();
  vector_set->value_ = Expression::ReadFrom(reader);

  vector_set->can_stream_ = false;

  return vector_set;
}


VectorCopy* VectorCopy::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();

  VectorCopy* vector_copy = new VectorCopy();
  vector_copy->kernel_offset_ =
      reader->offset() - 1;  // -1 to include tag byte.
  vector_copy->vector_expression_ = Expression::ReadFrom(reader);

  vector_copy->can_stream_ = false;

  return vector_copy;
}


ClosureCreation* ClosureCreation::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();

  ClosureCreation* closure_creation = new ClosureCreation();
  closure_creation->kernel_offset_ =
      reader->offset() - 1;  // to include tag byte.
  closure_creation->top_level_function_reference_ =
      Reference::ReadMemberFrom(reader);
  closure_creation->context_vector_ = Expression::ReadFrom(reader);
  closure_creation->function_type_ =
      FunctionType::Cast(DartType::ReadFrom(reader));

  closure_creation->can_stream_ = false;

  return closure_creation;
}


Statement* Statement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  switch (tag) {
    case kInvalidStatement:
      return InvalidStatement::ReadFrom(reader);
    case kExpressionStatement:
      return ExpressionStatement::ReadFrom(reader);
    case kBlock:
      return Block::ReadFromImpl(reader);
    case kEmptyStatement:
      return EmptyStatement::ReadFrom(reader);
    case kAssertStatement:
      return AssertStatement::ReadFrom(reader);
    case kLabeledStatement:
      return LabeledStatement::ReadFrom(reader);
    case kBreakStatement:
      return BreakStatement::ReadFrom(reader);
    case kWhileStatement:
      return WhileStatement::ReadFrom(reader);
    case kDoStatement:
      return DoStatement::ReadFrom(reader);
    case kForStatement:
      return ForStatement::ReadFrom(reader);
    case kForInStatement:
      return ForInStatement::ReadFrom(reader, false);
    case kAsyncForInStatement:
      return ForInStatement::ReadFrom(reader, true);
    case kSwitchStatement:
      return SwitchStatement::ReadFrom(reader);
    case kContinueSwitchStatement:
      return ContinueSwitchStatement::ReadFrom(reader);
    case kIfStatement:
      return IfStatement::ReadFrom(reader);
    case kReturnStatement:
      return ReturnStatement::ReadFrom(reader);
    case kTryCatch:
      return TryCatch::ReadFrom(reader);
    case kTryFinally:
      return TryFinally::ReadFrom(reader);
    case kYieldStatement:
      return YieldStatement::ReadFrom(reader);
    case kVariableDeclaration:
      return VariableDeclaration::ReadFromImpl(reader, true);
    case kFunctionDeclaration:
      return FunctionDeclaration::ReadFrom(reader);
    default:
      UNREACHABLE();
  }
  return NULL;
}


InvalidStatement* InvalidStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  InvalidStatement* stmt = new InvalidStatement();
  stmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  return stmt;
}


ExpressionStatement* ExpressionStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  intptr_t offset = reader->offset() - 1;  // -1 to include tag byte.
  ExpressionStatement* stmt =
      new ExpressionStatement(Expression::ReadFrom(reader));
  stmt->kernel_offset_ = offset;

  stmt->can_stream_ = stmt->expression_->can_stream();

  return stmt;
}


Block* Block::ReadFromImpl(Reader* reader) {
  TRACE_READ_OFFSET();
  PositionScope scope(reader);

  VariableScope<ReaderHelper> vars(reader->helper());
  Block* block = new Block();
  block->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  block->statements().ReadFromStatic<Statement>(reader);
  block->position_ = reader->min_position();
  block->end_position_ = reader->max_position();

  block->can_stream_ = block->statements().CanStream();

  return block;
}


EmptyStatement* EmptyStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  EmptyStatement* stmt = new EmptyStatement();
  stmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  return stmt;
}


AssertStatement* AssertStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  AssertStatement* stmt = new AssertStatement();
  stmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  stmt->condition_ = Expression::ReadFrom(reader);
  stmt->message_ = reader->ReadOptional<Expression>();

  stmt->can_stream_ = stmt->condition_->can_stream() &&
                      (stmt->message_ == NULL || stmt->message_->can_stream());

  return stmt;
}


LabeledStatement* LabeledStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  LabeledStatement* stmt = new LabeledStatement();
  stmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.

  reader->helper()->labels()->Push(stmt);
  stmt->body_ = Statement::ReadFrom(reader);
  reader->helper()->labels()->Pop(stmt);

  stmt->can_stream_ = stmt->body_->can_stream();

  return stmt;
}


BreakStatement* BreakStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  BreakStatement* stmt = new BreakStatement();
  stmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  stmt->position_ = reader->ReadPosition();
  stmt->target_index_ = reader->ReadUInt();
  return stmt;
}


WhileStatement* WhileStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  WhileStatement* stmt = new WhileStatement();
  stmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  stmt->condition_ = Expression::ReadFrom(reader);
  stmt->body_ = Statement::ReadFrom(reader);

  stmt->can_stream_ =
      stmt->condition_->can_stream() && stmt->body_->can_stream();

  return stmt;
}


DoStatement* DoStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  DoStatement* dostmt = new DoStatement();
  dostmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  dostmt->body_ = Statement::ReadFrom(reader);
  dostmt->condition_ = Expression::ReadFrom(reader);

  dostmt->can_stream_ =
      dostmt->body_->can_stream() && dostmt->condition_->can_stream();

  return dostmt;
}


ForStatement* ForStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> vars(reader->helper());
  PositionScope scope(reader);

  ForStatement* forstmt = new ForStatement();
  forstmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  forstmt->variables_.ReadFromStatic<VariableDeclarationImpl>(reader);
  forstmt->condition_ = reader->ReadOptional<Expression>();
  forstmt->updates_.ReadFromStatic<Expression>(reader);
  forstmt->body_ = Statement::ReadFrom(reader);
  forstmt->end_position_ = reader->max_position();
  forstmt->position_ = reader->min_position();

  forstmt->can_stream_ =
      forstmt->body_->can_stream() &&
      (forstmt->condition_ == NULL || forstmt->condition_->can_stream()) &&
      forstmt->variables_.CanStream() && forstmt->updates_.CanStream();

  return forstmt;
}


ForInStatement* ForInStatement::ReadFrom(Reader* reader, bool is_async) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> vars(reader->helper());
  PositionScope scope(reader);

  ForInStatement* forinstmt = new ForInStatement();
  forinstmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  forinstmt->is_async_ = is_async;
  forinstmt->position_ = reader->ReadPosition();
  forinstmt->variable_ = VariableDeclaration::ReadFromImpl(reader, false);
  forinstmt->iterable_ = Expression::ReadFrom(reader);
  forinstmt->body_ = Statement::ReadFrom(reader);
  forinstmt->end_position_ = reader->max_position();
  if (!forinstmt->position_.IsReal()) {
    forinstmt->position_ = reader->min_position();
  }
  forinstmt->variable_->set_end_position(forinstmt->position_);

  forinstmt->can_stream_ = forinstmt->variable_->can_stream() &&
                           forinstmt->iterable_->can_stream() &&
                           forinstmt->body_->can_stream();

  return forinstmt;
}


SwitchStatement* SwitchStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  SwitchStatement* stmt = new SwitchStatement();
  stmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  stmt->condition_ = Expression::ReadFrom(reader);
  int count = reader->ReadUInt();
  stmt->cases_.EnsureInitialized(count);
  for (intptr_t i = 0; i < count; i++) {
    SwitchCase* sc = stmt->cases_.GetOrCreate<SwitchCase>(i);
    sc->ReadFrom(reader);
  }

  stmt->can_stream_ =
      stmt->condition_->can_stream() && stmt->cases_.CanStream();

  return stmt;
}


SwitchCase* SwitchCase::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  int length = reader->ReadListLength();
  expressions_.EnsureInitialized(length);

  for (intptr_t i = 0; i < length; i++) {
    ASSERT(expressions_[i] == NULL);
    TokenPosition position = reader->ReadPosition();
    expressions_[i] = Expression::ReadFrom(reader);
    expressions_[i]->set_position(position);
  }
  is_default_ = reader->ReadBool();
  body_ = Statement::ReadFrom(reader);

  can_stream_ = expressions_.CanStream() && body_->can_stream();

  return this;
}


ContinueSwitchStatement* ContinueSwitchStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  ContinueSwitchStatement* stmt = new ContinueSwitchStatement();
  stmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  stmt->target_index_ = reader->ReadUInt();

  return stmt;
}


IfStatement* IfStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  IfStatement* ifstmt = new IfStatement();
  ifstmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  ifstmt->condition_ = Expression::ReadFrom(reader);
  ifstmt->then_ = Statement::ReadFrom(reader);
  ifstmt->otherwise_ = Statement::ReadFrom(reader);

  ifstmt->can_stream_ = ifstmt->condition_->can_stream() &&
                        ifstmt->then_->can_stream() &&
                        ifstmt->otherwise_->can_stream();

  return ifstmt;
}


ReturnStatement* ReturnStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  ReturnStatement* ret = new ReturnStatement();
  ret->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  ret->position_ = reader->ReadPosition();
  ret->expression_ = reader->ReadOptional<Expression>();

  ret->can_stream_ =
      (ret->expression_ == NULL || ret->expression_->can_stream());

  return ret;
}


TryCatch* TryCatch::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  PositionScope scope(reader);

  TryCatch* tc = new TryCatch();
  tc->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  tc->body_ = Statement::ReadFrom(reader);
  reader->ReadBool();  // whether any catch needs a stacktrace.
  tc->catches_.ReadFromStatic<Catch>(reader);
  tc->position_ = reader->min_position();

  tc->can_stream_ = tc->body_->can_stream() && tc->catches_.CanStream();

  return tc;
}


Catch* Catch::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VariableScope<ReaderHelper> vars(reader->helper());
  PositionScope scope(reader);

  Catch* c = new Catch();
  c->kernel_offset_ = reader->offset();  // Catch has no tag.
  c->guard_ = DartType::ReadFrom(reader);
  c->exception_ =
      reader->ReadOptional<VariableDeclaration, VariableDeclarationImpl>();
  c->stack_trace_ =
      reader->ReadOptional<VariableDeclaration, VariableDeclarationImpl>();
  c->body_ = Statement::ReadFrom(reader);
  c->end_position_ = reader->max_position();
  c->position_ = reader->min_position();

  c->can_stream_ = c->body_->can_stream();

  return c;
}


TryFinally* TryFinally::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TryFinally* tf = new TryFinally();
  tf->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  tf->body_ = Statement::ReadFrom(reader);
  tf->finalizer_ = Statement::ReadFrom(reader);

  tf->can_stream_ = tf->body_->can_stream() && tf->finalizer_->can_stream();

  return tf;
}


YieldStatement* YieldStatement::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  YieldStatement* stmt = new YieldStatement();
  stmt->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  stmt->position_ = reader->ReadPosition();
  reader->record_yield_token_position(stmt->position_);
  stmt->flags_ = reader->ReadByte();
  stmt->expression_ = Expression::ReadFrom(reader);

  stmt->can_stream_ = stmt->expression_->can_stream();

  return stmt;
}


VariableDeclaration* VariableDeclaration::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  ASSERT(tag == kVariableDeclaration);
  return VariableDeclaration::ReadFromImpl(reader, true);
}


VariableDeclaration* VariableDeclaration::ReadFromImpl(Reader* reader,
                                                       bool read_tag) {
  TRACE_READ_OFFSET();
  PositionScope scope(reader);

  VariableDeclaration* decl = new VariableDeclaration();
  // -1 or -0 depending on whether there's a tag or not.
  decl->kernel_offset_ = reader->offset() - (read_tag ? 1 : 0);
  decl->kernel_offset_no_tag_ = reader->offset();
  decl->position_ = reader->ReadPosition();
  decl->equals_position_ = reader->ReadPosition();
  decl->flags_ = reader->ReadFlags();
  decl->name_index_ = StringIndex(reader->ReadUInt());
  decl->type_ = DartType::ReadFrom(reader);
  decl->initializer_ = reader->ReadOptional<Expression>();

  // Go to next token position so it ends *after* the last potentially
  // debuggable position in the initializer.
  TokenPosition position = reader->max_position();
  if (position.IsReal()) position.Next();
  decl->end_position_ = position;
  reader->helper()->variables().Push(decl);

  decl->can_stream_ =
      (decl->initializer_ == NULL || decl->initializer_->can_stream());

  return decl;
}


FunctionDeclaration* FunctionDeclaration::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  FunctionDeclaration* decl = new FunctionDeclaration();
  decl->kernel_offset_ = reader->offset() - 1;  // -1 to include tag byte.
  decl->position_ = reader->ReadPosition();
  decl->variable_ = VariableDeclaration::ReadFromImpl(reader, false);
  VariableScope<ReaderHelper> parameters(reader->helper());
  decl->function_ = FunctionNode::ReadFrom(reader);

  decl->can_stream_ = false;

  return decl;
}


Name* Name::ReadFrom(Reader* reader) {
  StringIndex name_index(reader->ReadUInt());
  if ((reader->StringLength(name_index) >= 1) &&
      (reader->CharacterAt(name_index, 0) == '_')) {
    intptr_t library_reference = reader->ReadCanonicalNameReference();
    return new Name(name_index, library_reference);
  } else {
    return new Name(name_index, NULL);
  }
}


DartType* DartType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  Tag tag = reader->ReadTag();
  switch (tag) {
    case kInvalidType:
      return InvalidType::ReadFrom(reader);
    case kDynamicType:
      return DynamicType::ReadFrom(reader);
    case kVoidType:
      return VoidType::ReadFrom(reader);
    case kBottomType:
      return BottomType::ReadFrom(reader);
    case kInterfaceType:
      return InterfaceType::ReadFrom(reader);
    case kSimpleInterfaceType:
      return InterfaceType::ReadFrom(reader, true);
    case kFunctionType:
      return FunctionType::ReadFrom(reader);
    case kSimpleFunctionType:
      return FunctionType::ReadFrom(reader, true);
    case kTypeParameterType:
      return TypeParameterType::ReadFrom(reader);
    case kVectorType:
      return VectorType::ReadFrom(reader);
    case kTypedefType:
      return TypedefType::ReadFrom(reader);
    default:
      UNREACHABLE();
  }
  UNREACHABLE();
  return NULL;
}


InvalidType* InvalidType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new InvalidType();
}


DynamicType* DynamicType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new DynamicType();
}


VoidType* VoidType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new VoidType();
}


BottomType* BottomType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  return new BottomType();
}


InterfaceType* InterfaceType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  NameIndex klass_name = Reference::ReadClassFrom(reader);
  InterfaceType* type = new InterfaceType(klass_name);
  type->type_arguments().ReadFromStatic<DartType>(reader);
  return type;
}


InterfaceType* InterfaceType::ReadFrom(Reader* reader,
                                       bool _without_type_arguments_) {
  TRACE_READ_OFFSET();
  NameIndex klass_name = Reference::ReadClassFrom(reader);
  InterfaceType* type = new InterfaceType(klass_name);
  ASSERT(_without_type_arguments_);
  return type;
}


TypedefType* TypedefType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  NameIndex typedef_name = Reference::ReadTypedefFrom(reader);
  TypedefType* type = new TypedefType(typedef_name);
  type->type_arguments().ReadFromStatic<DartType>(reader);
  return type;
}


FunctionType* FunctionType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  FunctionType* type = new FunctionType();
  TypeParameterScope<ReaderHelper> scope(reader->helper());
  type->type_parameters().ReadFrom(reader);
  type->required_parameter_count_ = reader->ReadUInt();
  intptr_t total_parameter_count = reader->ReadUInt();
  type->positional_parameters().ReadFromStatic<DartType>(reader);
  type->named_parameters().ReadFromStatic<NamedParameter>(reader);
  ASSERT(type->positional_parameters().length() +
             type->named_parameters().length() ==
         total_parameter_count);
  type->return_type_ = DartType::ReadFrom(reader);
  return type;
}


FunctionType* FunctionType::ReadFrom(Reader* reader, bool _is_simple_) {
  TRACE_READ_OFFSET();
  FunctionType* type = new FunctionType();
  ASSERT(_is_simple_);
  type->positional_parameters().ReadFromStatic<DartType>(reader);
  type->required_parameter_count_ = type->positional_parameters().length();
  type->return_type_ = DartType::ReadFrom(reader);
  return type;
}


TypeParameterType* TypeParameterType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TypeParameterType* type = new TypeParameterType();
  type->parameter_ =
      reader->helper()->type_parameters().Lookup(reader->ReadUInt());
  reader->ReadUInt();  // binary offset of parameter
  // There is an optional promoted bound, currently ignored.
  delete reader->ReadOptional<DartType>();
  return type;
}


VectorType* VectorType::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  VectorType* type = new VectorType();
  return type;
}


Program* Program::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  uint32_t magic = reader->ReadUInt32();
  if (magic != kMagicProgramFile) FATAL("Invalid magic identifier");

  Program* program = new Program();
  reader->helper()->set_program(program);

  // Deserialize the string offset table to give fast access to the string data
  // during deserialization.
  program->string_table_offset_ = reader->offset();
  intptr_t string_count = reader->ReadUInt();
  reader->string_offsets_ = new intptr_t[string_count + 1];
  intptr_t offset = 0;
  for (intptr_t i = 0; i < string_count; ++i) {
    reader->string_offsets_[i] = offset;
    offset = reader->ReadUInt();
  }
  reader->string_offsets_[string_count] = offset;
  // Skip the UTF-8 encoded strings.
  reader->MarkStringDataOffset();
  reader->Consume(offset);

  program->source_table_.ReadFrom(reader);

  // Deserialize the canonical name table to give fast access to canonical names
  // during deserialization.
  program->name_table_offset_ = reader->offset();
  intptr_t name_count = reader->ReadUInt();
  reader->canonical_name_parents_ = new NameIndex[name_count];
  reader->canonical_name_strings_ = new StringIndex[name_count];
  for (int i = 0; i < name_count; ++i) {
    // The parent name index is biased: 0 is the root name and otherwise N+1 is
    // the Nth name.
    reader->canonical_name_parents_[i] = reader->ReadCanonicalNameReference();
    reader->canonical_name_strings_[i] = StringIndex(reader->ReadUInt());
  }

  int libraries = reader->ReadUInt();
  program->libraries().EnsureInitialized(libraries);
  for (intptr_t i = 0; i < libraries; i++) {
    program->libraries().GetOrCreate<Library>(i)->ReadFrom(reader);
  }

  program->main_method_reference_ =
      Reference::ReadMemberFrom(reader, /*allow_null=*/true);

  program->can_stream_ = false;

  return program;
}


FunctionNode* FunctionNode::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  TypeParameterScope<ReaderHelper> scope(reader->helper());

  FunctionNode* function = new FunctionNode();
  // FunctionNode tag not read yet.
  function->kernel_offset_ = reader->offset();
  Tag tag = reader->ReadTag();
  ASSERT(tag == kFunctionNode);
  function->position_ = reader->ReadPosition();
  function->end_position_ = reader->ReadPosition();
  function->async_marker_ =
      static_cast<FunctionNode::AsyncMarker>(reader->ReadByte());
  function->dart_async_marker_ =
      static_cast<FunctionNode::AsyncMarker>(reader->ReadByte());
  function->type_parameters().ReadFrom(reader);
  reader->ReadUInt();  // total parameter count.
  function->required_parameter_count_ = reader->ReadUInt();
  function->positional_parameters().ReadFromStatic<VariableDeclarationImpl>(
      reader);
  function->named_parameters().ReadFromStatic<VariableDeclarationImpl>(reader);
  function->return_type_ = DartType::ReadFrom(reader);

  LabelScope<ReaderHelper, BlockStack<LabeledStatement> > labels(
      reader->helper());
  VariableScope<ReaderHelper> vars(reader->helper());
  function->body_ = reader->ReadOptional<Statement>();

  function->can_stream_ =
      function->positional_parameters_.CanStream() &&
      function->named_parameters_.CanStream() &&
      (function->body_ == NULL || function->body_->can_stream());

  return function;
}


TypeParameter* TypeParameter::ReadFrom(Reader* reader) {
  TRACE_READ_OFFSET();
  kernel_offset_ = reader->offset();
  name_index_ = StringIndex(reader->ReadUInt());
  bound_ = DartType::ReadFrom(reader);
  return this;
}


}  // namespace kernel


kernel::Program* ReadPrecompiledKernelFromBuffer(const uint8_t* buffer,
                                                 intptr_t buffer_length) {
  kernel::Reader reader(buffer, buffer_length);
  return kernel::Program::ReadFrom(&reader);
}


}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
