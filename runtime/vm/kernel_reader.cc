// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_reader.h"

#include <string.h>

#include "vm/dart_api_impl.h"
#include "vm/kernel_binary.h"
#include "vm/kernel_binary_flowgraph.h"
#include "vm/kernel_to_il.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/symbols.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
namespace dart {
namespace kernel {

#define Z (zone_)
#define I (isolate_)
#define T (builder_.type_translator_)
#define H (translation_helper_)

class SimpleExpressionConverter {
 public:
  SimpleExpressionConverter(TranslationHelper* helper,
                            StreamingFlowGraphBuilder* builder)
      : translation_helper_(*helper),
        zone_(translation_helper_.zone()),
        simple_value_(NULL),
        builder_(builder) {}

  bool IsSimple(intptr_t kernel_offset) {
    AlternativeReadingScope alt(builder_->reader_, kernel_offset);
    uint8_t payload = 0;
    Tag tag = builder_->ReadTag(&payload);  // read tag.
    switch (tag) {
      case kBigIntLiteral: {
        const dart::String& literal_str =
            H.DartString(builder_->ReadStringReference(),
                         Heap::kOld);  // read index into string table.
        simple_value_ = &Integer::ZoneHandle(Z, Integer::New(literal_str));
        if (simple_value_->IsNull()) {
          H.ReportError("Integer literal %s is out of range",
                        literal_str.ToCString());
          UNREACHABLE();
        }
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      }
      case kStringLiteral:
        simple_value_ = &H.DartSymbol(
            builder_->ReadStringReference());  // read index into string table.
        return true;
      case kSpecialIntLiteral:
        simple_value_ =
            &Integer::ZoneHandle(Z, Integer::New(static_cast<int32_t>(payload) -
                                                     SpecializedIntLiteralBias,
                                                 Heap::kOld));
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kNegativeIntLiteral:
        simple_value_ = &Integer::ZoneHandle(
            Z, Integer::New(-static_cast<int64_t>(builder_->ReadUInt()),
                            Heap::kOld));  // read value.
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kPositiveIntLiteral:
        simple_value_ = &Integer::ZoneHandle(
            Z, Integer::New(static_cast<int64_t>(builder_->ReadUInt()),
                            Heap::kOld));  // read value.
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kDoubleLiteral:
        simple_value_ = &Double::ZoneHandle(
            Z, Double::New(H.DartString(builder_->ReadStringReference()),
                           Heap::kOld));  // read string reference.
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kTrueLiteral:
        simple_value_ = &Bool::Handle(Z, Bool::Get(true).raw());
        return true;
      case kFalseLiteral:
        simple_value_ = &Bool::Handle(Z, Bool::Get(false).raw());
        return true;
      case kNullLiteral:
        simple_value_ = &dart::Instance::ZoneHandle(Z, dart::Instance::null());
        return true;
      default:
        return false;
    }
  }

  const dart::Instance& SimpleValue() { return *simple_value_; }
  dart::Zone* zone() const { return zone_; }

 private:
  TranslationHelper& translation_helper_;
  dart::Zone* zone_;
  dart::Instance* simple_value_;
  StreamingFlowGraphBuilder* builder_;
};

RawArray* KernelReader::MakeFunctionsArray() {
  const intptr_t len = functions_.length();
  const Array& res = Array::Handle(zone_, Array::New(len, Heap::kOld));
  for (intptr_t i = 0; i < len; i++) {
    res.SetAt(i, *functions_[i]);
  }
  return res.raw();
}

RawLibrary* BuildingTranslationHelper::LookupLibraryByKernelLibrary(
    NameIndex library) {
  return reader_->LookupLibrary(library).raw();
}

RawClass* BuildingTranslationHelper::LookupClassByKernelClass(NameIndex klass) {
  return reader_->LookupClass(klass).raw();
}

KernelReader::KernelReader(Program* program)
    : program_(program),
      thread_(dart::Thread::Current()),
      zone_(thread_->zone()),
      isolate_(thread_->isolate()),
      scripts_(Array::ZoneHandle(zone_)),
      patch_classes_(Array::ZoneHandle(zone_)),
      translation_helper_(this, thread_),
      builder_(&translation_helper_,
               zone_,
               program_->kernel_data(),
               program_->kernel_data_size()) {
  T.active_class_ = &active_class_;
  T.finalize_ = false;

  scripts_ = Array::New(builder_.SourceTableSize(), Heap::kOld);
  patch_classes_ = Array::New(builder_.SourceTableSize(), Heap::kOld);

  // Copy the Kernel string offsets out of the binary and into the VM's heap.
  ASSERT(program->string_table_offset() >= 0);
  Reader reader(program->kernel_data(), program->kernel_data_size());
  reader.set_offset(program->string_table_offset());
  intptr_t count = reader.ReadUInt() + 1;
  TypedData& offsets = TypedData::Handle(
      Z, TypedData::New(kTypedDataUint32ArrayCid, count, Heap::kOld));
  offsets.SetUint32(0, 0);
  intptr_t end_offset = 0;
  for (intptr_t i = 1; i < count; ++i) {
    end_offset = reader.ReadUInt();
    offsets.SetUint32(i << 2, end_offset);
  }

  // Copy the string data out of the binary and into the VM's heap.
  TypedData& data = TypedData::Handle(
      Z, TypedData::New(kTypedDataUint8ArrayCid, end_offset, Heap::kOld));
  {
    NoSafepointScope no_safepoint;
    memmove(data.DataAddr(0), reader.buffer() + reader.offset(), end_offset);
  }

  // Copy the canonical names into the VM's heap.  Encode them as unsigned, so
  // the parent indexes are adjusted when extracted.
  reader.set_offset(program->name_table_offset());
  count = reader.ReadUInt() * 2;
  TypedData& names = TypedData::Handle(
      Z, TypedData::New(kTypedDataUint32ArrayCid, count, Heap::kOld));
  for (intptr_t i = 0; i < count; ++i) {
    names.SetUint32(i << 2, reader.ReadUInt());
  }

  H.SetStringOffsets(offsets);
  H.SetStringData(data);
  H.SetCanonicalNames(names);
}

Object& KernelReader::ReadProgram() {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    intptr_t length = program_->library_count();
    for (intptr_t i = 0; i < length; i++) {
      ReadLibrary(library_offset(i));
    }

    for (intptr_t i = 0; i < length; i++) {
      dart::Library& library = LookupLibrary(library_canonical_name(i));
      if (!library.Loaded()) library.SetLoaded();
    }

    if (ClassFinalizer::ProcessPendingClasses(/*from_kernel=*/true)) {
      // If 'main' is not found return a null library, this is the case
      // when bootstrapping is in progress.
      NameIndex main = program_->main_method();
      if (main == -1) {
        return dart::Library::Handle(Z);
      }

      NameIndex main_library = H.EnclosingName(main);
      dart::Library& library = LookupLibrary(main_library);
      // Sanity check that we can find the main entrypoint.
      ASSERT(library.LookupObjectAllowPrivate(H.DartSymbol("main")) !=
             Object::null());
      return library;
    }
  }

  // Either class finalization failed or we caught a compile error.
  // In both cases sticky error would be set.
  Error& error = Error::Handle(Z);
  error = thread_->sticky_error();
  thread_->clear_sticky_error();
  return error;
}

void KernelReader::ReadLibrary(intptr_t kernel_offset) {
  builder_.SetOffset(kernel_offset);
  LibraryHelper library_helper(&builder_);
  library_helper.ReadUntilIncluding(LibraryHelper::kCanonicalName);
  dart::Library& library = LookupLibrary(library_helper.canonical_name_);
  if (library.Loaded()) return;

  library_helper.ReadUntilIncluding(LibraryHelper::kName);
  library.SetName(H.DartSymbol(library_helper.name_index_));

  // The bootstrapper will take care of creating the native wrapper classes, but
  // we will add the synthetic constructors to them here.
  if (library.name() ==
      Symbols::Symbol(Symbols::kDartNativeWrappersLibNameId).raw()) {
    ASSERT(library.LoadInProgress());
  } else {
    library.SetLoadInProgress();
  }
  // Setup toplevel class (which contains library fields/procedures).

  StringIndex import_uri_index =
      H.CanonicalNameString(library_helper.canonical_name_);
  library_helper.ReadUntilIncluding(LibraryHelper::kSourceUriIndex);
  Script& script = ScriptAt(library_helper.source_uri_index_, import_uri_index);

  dart::Class& toplevel_class = dart::Class::Handle(
      Z, dart::Class::New(library, Symbols::TopLevel(), script,
                          TokenPosition::kNoSource));
  toplevel_class.set_is_cycle_free();
  library.set_toplevel_class(toplevel_class);

  const GrowableObjectArray& classes =
      GrowableObjectArray::Handle(Z, I->object_store()->pending_classes());

  library_helper.ReadUntilExcluding(LibraryHelper::kClasses);

  // Load all classes.
  int class_count = builder_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < class_count; ++i) {
    classes.Add(ReadClass(library, toplevel_class), Heap::kOld);
  }

  fields_.Clear();
  functions_.Clear();
  ActiveClassScope active_class_scope(&active_class_, 0, -1, &toplevel_class);
  // Load toplevel fields.
  intptr_t field_count = builder_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < field_count; ++i) {
    intptr_t field_offset = builder_.ReaderOffset();
    ActiveMemberScope active_member_scope(&active_class_, false, false, 0, -1);
    FieldHelper field_helper(&builder_);
    field_helper.ReadUntilExcluding(FieldHelper::kName);

    const dart::String& name = builder_.ReadNameAsFieldName();
    field_helper.SetJustRead(FieldHelper::kName);
    field_helper.ReadUntilExcluding(FieldHelper::kType);
    const Object& script_class =
        ClassForScriptAt(toplevel_class, field_helper.source_uri_index_);
    dart::Field& field = dart::Field::Handle(
        Z, dart::Field::NewTopLevel(name, field_helper.IsFinal(),
                                    field_helper.IsConst(), script_class,
                                    field_helper.position_));
    field.set_kernel_offset(field_offset);
    const AbstractType& type = T.BuildType();  // read type.
    field.SetFieldType(type);
    field_helper.SetJustRead(FieldHelper::kType);
    field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
    field.set_has_initializer(builder_.PeekTag() == kSomething);
    GenerateFieldAccessors(toplevel_class, field, &field_helper, field_offset);
    field_helper.ReadUntilExcluding(FieldHelper::kEnd);
    if (FLAG_enable_mirrors && field_helper.annotation_count_ > 0) {
      library.AddFieldMetadata(field, TokenPosition::kNoSource, field_offset);
    }
    fields_.Add(&field);
    library.AddObject(field, name);
  }
  toplevel_class.AddFields(fields_);

  // Load toplevel procedures.
  intptr_t procedure_count = builder_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < procedure_count; ++i) {
    ReadProcedure(library, toplevel_class, false);
  }

  toplevel_class.SetFunctions(Array::Handle(MakeFunctionsArray()));

  classes.Add(toplevel_class, Heap::kOld);
}

void KernelReader::ReadPreliminaryClass(dart::Class* klass,
                                        ClassHelper* class_helper,
                                        intptr_t type_parameter_count) {
  // Note: This assumes that ClassHelper is exactly at the position where
  // the length of the type parameters have been read, and that the order in
  // the binary is as follows: [...], kTypeParameters, kSuperClass, kMixinType,
  // kImplementedClasses, [...].

  // First setup the type parameters, so if any of the following code uses it
  // (in a recursive way) we're fine.
  TypeArguments& type_parameters =
      TypeArguments::Handle(Z, TypeArguments::null());
  if (type_parameter_count > 0) {
    dart::TypeParameter& parameter = dart::TypeParameter::Handle(Z);
    Type& null_bound = Type::Handle(Z, Type::null());

    // Step a) Create array of [TypeParameter] objects (without bound).
    type_parameters = TypeArguments::New(type_parameter_count);
    {
      AlternativeReadingScope alt(builder_.reader_);
      for (intptr_t i = 0; i < type_parameter_count; i++) {
        parameter = dart::TypeParameter::New(
            *klass, Function::Handle(Z), i,
            H.DartSymbol(
                builder_.ReadStringReference()),  // read ith name index.
            null_bound, TokenPosition::kNoSource);
        type_parameters.SetTypeAt(i, parameter);
        builder_.SkipDartType();  // read guard.
      }
    }
    klass->set_type_parameters(type_parameters);

    // Step b) Fill in the bounds of all [TypeParameter]s.
    for (intptr_t i = 0; i < type_parameter_count; i++) {
      builder_.SkipStringReference();  // read ith name index.

      // TODO(github.com/dart-lang/kernel/issues/42): This should be handled
      // by the frontend.
      parameter ^= type_parameters.TypeAt(i);
      Tag tag = builder_.PeekTag();  // peek ith bound type.
      if (tag == kDynamicType) {
        builder_.SkipDartType();  // read ith bound.
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

  // Set super type.  Some classes (e.g., Object) do not have one.
  Tag type_tag = builder_.ReadTag();  // read super class type (part 1).
  if (type_tag == kSomething) {
    AbstractType& super_type =
        T.BuildTypeWithoutFinalization();  // read super class type (part 2).
    if (super_type.IsMalformed()) H.ReportError("Malformed super type");
    klass->set_super_type(super_type);
  }

  class_helper->SetJustRead(ClassHelper::kSuperClass);
  class_helper->ReadUntilIncluding(ClassHelper::kMixinType);

  // Build implemented interface types
  intptr_t interface_count = builder_.ReadListLength();
  const dart::Array& interfaces =
      dart::Array::Handle(Z, dart::Array::New(interface_count, Heap::kOld));
  for (intptr_t i = 0; i < interface_count; i++) {
    const AbstractType& type =
        T.BuildTypeWithoutFinalization();  // read ith type.
    if (type.IsMalformed()) H.ReportError("Malformed interface type.");
    interfaces.SetAt(i, type);
  }
  class_helper->SetJustRead(ClassHelper::kImplementedClasses);
  klass->set_interfaces(interfaces);

  if (class_helper->is_abstract_) klass->set_is_abstract();
}

dart::Class& KernelReader::ReadClass(const dart::Library& library,
                                     const dart::Class& toplevel_class) {
  ClassHelper class_helper(&builder_);
  intptr_t class_offset = builder_.ReaderOffset();
  class_helper.ReadUntilIncluding(ClassHelper::kCanonicalName);
  dart::Class& klass = LookupClass(class_helper.canonical_name_);

  // The class needs to have a script because all the functions in the class
  // will inherit it.  The predicate Function::IsOptimizable uses the absence of
  // a script to detect test functions that should not be optimized.
  if (klass.script() == Script::null()) {
    class_helper.ReadUntilIncluding(ClassHelper::kSourceUriIndex);
    klass.set_script(ScriptAt(class_helper.source_uri_index_));
  }
  if (klass.token_pos() == TokenPosition::kNoSource) {
    class_helper.ReadUntilIncluding(ClassHelper::kPosition);
    klass.set_token_pos(class_helper.position_);
  }

  class_helper.ReadUntilExcluding(ClassHelper::kTypeParameters);
  intptr_t type_paremeter_counts =
      builder_.ReadListLength();  // read type_parameters list length.
  intptr_t type_paremeter_offset = builder_.ReaderOffset();

  ActiveClassScope active_class_scope(&active_class_, type_paremeter_counts,
                                      type_paremeter_offset, &klass);
  if (!klass.is_cycle_free()) {
    ReadPreliminaryClass(&klass, &class_helper, type_paremeter_counts);
  } else {
    for (intptr_t i = 0; i < type_paremeter_counts; ++i) {
      builder_.SkipStringReference();  // read ith name index.
      builder_.SkipDartType();         // read ith bound.
    }
    class_helper.SetJustRead(ClassHelper::kTypeParameters);
  }

  fields_.Clear();
  functions_.Clear();

  if (library.raw() == dart::Library::InternalLibrary() &&
      klass.Name() == Symbols::ClassID().raw()) {
    // If this is a dart:internal.ClassID class ignore field declarations
    // contained in the Kernel file and instead inject our own const
    // fields.
    klass.InjectCIDFields();
  } else {
    class_helper.ReadUntilExcluding(ClassHelper::kFields);
    int field_count = builder_.ReadListLength();  // read list length.
    for (intptr_t i = 0; i < field_count; ++i) {
      intptr_t field_offset = builder_.ReaderOffset();
      ActiveMemberScope active_member(&active_class_, false, false, 0, -1);
      FieldHelper field_helper(&builder_);
      field_helper.ReadUntilExcluding(FieldHelper::kName);

      const dart::String& name = builder_.ReadNameAsFieldName();
      field_helper.SetJustRead(FieldHelper::kName);
      field_helper.ReadUntilExcluding(FieldHelper::kType);
      const AbstractType& type =
          T.BuildTypeWithoutFinalization();  // read type.
      field_helper.SetJustRead(FieldHelper::kType);
      const Object& script_class =
          ClassForScriptAt(klass, field_helper.source_uri_index_);

      const bool is_reflectable =
          field_helper.position_.IsReal() &&
          !(library.is_dart_scheme() && library.IsPrivate(name));
      dart::Field& field = dart::Field::Handle(
          Z,
          dart::Field::New(name, field_helper.IsStatic(),
                           // In the VM all const fields are implicitly final
                           // whereas in Kernel they are not final because they
                           // are not explicitly declared that way.
                           field_helper.IsFinal() || field_helper.IsConst(),
                           field_helper.IsConst(), is_reflectable, script_class,
                           type, field_helper.position_));
      field.set_kernel_offset(field_offset);
      field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
      field.set_has_initializer(builder_.PeekTag() == kSomething);
      GenerateFieldAccessors(klass, field, &field_helper, field_offset);
      field_helper.ReadUntilExcluding(FieldHelper::kEnd);
      if (FLAG_enable_mirrors && field_helper.annotation_count_ > 0) {
        library.AddFieldMetadata(field, TokenPosition::kNoSource, field_offset);
      }
      fields_.Add(&field);
    }
    klass.AddFields(fields_);
    class_helper.SetJustRead(ClassHelper::kFields);
  }

  class_helper.ReadUntilExcluding(ClassHelper::kConstructors);
  int constructor_count = builder_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < constructor_count; ++i) {
    intptr_t constructor_offset = builder_.ReaderOffset();
    ActiveMemberScope active_member_scope(&active_class_, false, false, 0, -1);
    ConstructorHelper constructor_helper(&builder_);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kFunction);

    const dart::String& name =
        H.DartConstructorName(constructor_helper.canonical_name_);
    Function& function = dart::Function::ZoneHandle(
        Z, dart::Function::New(name, RawFunction::kConstructor,
                               false,  // is_static
                               constructor_helper.IsConst(),
                               false,  // is_abstract
                               constructor_helper.IsExternal(),
                               false,  // is_native
                               klass, constructor_helper.position_));
    function.set_end_token_pos(constructor_helper.end_position_);
    functions_.Add(&function);
    function.set_kernel_offset(constructor_offset);
    function.set_result_type(T.ReceiverType(klass));

    FunctionNodeHelper function_node_helper(&builder_);
    function_node_helper.ReadUntilExcluding(
        FunctionNodeHelper::kRequiredParameterCount);
    builder_.SetupFunctionParameters(klass, function,
                                     true,   // is_method
                                     false,  // is_closure
                                     &function_node_helper);
    function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);
    constructor_helper.SetJustRead(ConstructorHelper::kFunction);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kEnd);

    if (FLAG_enable_mirrors && constructor_helper.annotation_count_ > 0) {
      library.AddFunctionMetadata(function, TokenPosition::kNoSource,
                                  constructor_offset);
    }
  }
  class_helper.SetJustRead(ClassHelper::kConstructors);

  class_helper.ReadUntilExcluding(ClassHelper::kProcedures);
  int procedure_count = builder_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < procedure_count; ++i) {
    ReadProcedure(library, klass, true);
  }
  class_helper.SetJustRead(ClassHelper::kProcedures);

  klass.SetFunctions(Array::Handle(MakeFunctionsArray()));

  if (!klass.is_marked_for_parsing()) {
    klass.set_is_marked_for_parsing();
  }

  if (FLAG_enable_mirrors && class_helper.annotation_count_ > 0) {
    library.AddClassMetadata(klass, toplevel_class, TokenPosition::kNoSource,
                             class_offset);
  }

  class_helper.ReadUntilExcluding(ClassHelper::kEnd);

  return klass;
}

void KernelReader::ReadProcedure(const dart::Library& library,
                                 const dart::Class& owner,
                                 bool in_class) {
  intptr_t procedure_offset = builder_.ReaderOffset();
  ProcedureHelper procedure_helper(&builder_);

  bool member_is_procedure = false;
  bool is_factory_procedure = false;
  intptr_t member_type_parameters = 0;
  intptr_t member_type_parameters_offset_start = -1;
  builder_.GetTypeParameterInfoForPossibleProcedure(
      builder_.ReaderOffset(), &member_is_procedure, &is_factory_procedure,
      &member_type_parameters, &member_type_parameters_offset_start);

  ActiveMemberScope active_member(&active_class_, member_is_procedure,
                                  is_factory_procedure, member_type_parameters,
                                  member_type_parameters_offset_start);

  procedure_helper.ReadUntilExcluding(ProcedureHelper::kAnnotations);
  const dart::String& name =
      H.DartProcedureName(procedure_helper.canonical_name_);
  bool is_method = in_class && !procedure_helper.IsStatic();
  bool is_abstract = procedure_helper.IsAbstract();
  bool is_external = procedure_helper.IsExternal();
  dart::String* native_name = NULL;
  intptr_t annotation_count;
  if (is_external) {
    // Maybe it has a native implementation, which is not external as far as
    // the VM is concerned because it does have an implementation.  Check for
    // an ExternalName annotation and extract the string from it.
    annotation_count = builder_.ReadListLength();  // read list length.
    for (int i = 0; i < annotation_count; ++i) {
      if (builder_.PeekTag() != kConstructorInvocation &&
          builder_.PeekTag() != kConstConstructorInvocation) {
        builder_.SkipExpression();
        continue;
      }
      builder_.ReadTag();
      builder_.ReadPosition();
      NameIndex annotation_class = H.EnclosingName(
          builder_.ReadCanonicalNameReference());  // read target reference,
      ASSERT(H.IsClass(annotation_class));
      StringIndex class_name_index = H.CanonicalNameString(annotation_class);
      // Just compare by name, do not generate the annotation class.
      if (!H.StringEquals(class_name_index, "ExternalName")) {
        builder_.SkipArguments();
        continue;
      }
      ASSERT(H.IsLibrary(H.CanonicalNameParent(annotation_class)));
      StringIndex library_name_index =
          H.CanonicalNameString(H.CanonicalNameParent(annotation_class));
      if (!H.StringEquals(library_name_index, "dart:_internal")) {
        builder_.SkipArguments();
        continue;
      }

      is_external = false;
      // Read arguments:
      intptr_t total_arguments = builder_.ReadUInt();  // read argument count.
      builder_.SkipListOfDartTypes();                  // read list of types.
      intptr_t positional_arguments = builder_.ReadListLength();
      ASSERT(total_arguments == 1 && positional_arguments == 1);

      Tag tag = builder_.ReadTag();
      ASSERT(tag == kStringLiteral);
      native_name = &H.DartSymbol(
          builder_.ReadStringReference());  // read index into string table.

      // List of named.
      intptr_t list_length = builder_.ReadListLength();  // read list length.
      ASSERT(list_length == 0);

      // Skip remaining annotations
      for (++i; i < annotation_count; ++i) {
        builder_.SkipExpression();  // read ith annotation.
      }

      break;
    }
    procedure_helper.SetJustRead(ProcedureHelper::kAnnotations);
  } else {
    procedure_helper.ReadUntilIncluding(ProcedureHelper::kAnnotations);
    annotation_count = procedure_helper.annotation_count_;
  }
  const Object& script_class =
      ClassForScriptAt(owner, procedure_helper.source_uri_index_);
  dart::Function& function = dart::Function::ZoneHandle(
      Z, Function::New(name, GetFunctionType(procedure_helper.kind_),
                       !is_method,  // is_static
                       false,       // is_const
                       is_abstract, is_external,
                       native_name != NULL,  // is_native
                       script_class, procedure_helper.position_));
  function.set_end_token_pos(procedure_helper.end_position_);
  functions_.Add(&function);
  function.set_kernel_offset(procedure_offset);

  procedure_helper.ReadUntilExcluding(ProcedureHelper::kFunction);
  Tag function_node_tag = builder_.ReadTag();
  ASSERT(function_node_tag == kSomething);
  FunctionNodeHelper function_node_helper(&builder_);
  function_node_helper.ReadUntilIncluding(FunctionNodeHelper::kDartAsyncMarker);
  function.set_is_debuggable(function_node_helper.dart_async_marker_ ==
                             FunctionNode::kSync);
  switch (function_node_helper.dart_async_marker_) {
    case FunctionNode::kSyncStar:
      function.set_modifier(RawFunction::kSyncGen);
      break;
    case FunctionNode::kAsync:
      function.set_modifier(RawFunction::kAsync);
      function.set_is_inlinable(!FLAG_causal_async_stacks);
      break;
    case FunctionNode::kAsyncStar:
      function.set_modifier(RawFunction::kAsyncGen);
      function.set_is_inlinable(!FLAG_causal_async_stacks);
      break;
    default:
      // no special modifier
      break;
  }
  ASSERT(function_node_helper.async_marker_ == FunctionNode::kSync);

  if (native_name != NULL) {
    function.set_native_name(*native_name);
  }

  function_node_helper.ReadUntilExcluding(
      FunctionNodeHelper::kRequiredParameterCount);
  builder_.SetupFunctionParameters(owner, function, is_method,
                                   false,  // is_closure
                                   &function_node_helper);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);
  procedure_helper.SetJustRead(ProcedureHelper::kFunction);

  if (!in_class) {
    library.AddObject(function, name);
    ASSERT(!Object::Handle(
                Z, library.LookupObjectAllowPrivate(
                       H.DartProcedureName(procedure_helper.canonical_name_)))
                .IsNull());
  }
  if (FLAG_enable_mirrors && annotation_count > 0) {
    library.AddFunctionMetadata(function, TokenPosition::kNoSource,
                                procedure_offset);
  }

  procedure_helper.ReadUntilExcluding(ProcedureHelper::kEnd);
}

const Object& KernelReader::ClassForScriptAt(const dart::Class& klass,
                                             intptr_t source_uri_index) {
  Script& correct_script = ScriptAt(source_uri_index);
  if (klass.script() != correct_script.raw()) {
    // Use cache for patch classes. This works best for in-order usages.
    PatchClass& patch_class = PatchClass::ZoneHandle(Z);
    patch_class ^= patch_classes_.At(source_uri_index);
    if (patch_class.IsNull() || patch_class.origin_class() != klass.raw()) {
      patch_class = PatchClass::New(klass, correct_script);
      patch_classes_.SetAt(source_uri_index, patch_class);
    }
    return patch_class;
  }
  return klass;
}

Script& KernelReader::ScriptAt(intptr_t index, StringIndex import_uri) {
  Script& script = Script::ZoneHandle(Z);
  script ^= scripts_.At(index);
  if (script.IsNull()) {
    // Create script with correct uri(s).
    dart::String& uri_string = builder_.SourceTableUriFor(index);
    dart::String& import_uri_string =
        import_uri == -1 ? uri_string : H.DartString(import_uri, Heap::kOld);
    script = Script::New(import_uri_string, uri_string,
                         String::Handle(String::null()), RawScript::kKernelTag);
    script.set_kernel_data(program_->kernel_data());
    script.set_kernel_data_size(program_->kernel_data_size());
    script.set_kernel_script_index(index);
    script.set_kernel_string_offsets(H.string_offsets());
    script.set_kernel_string_data(H.string_data());
    script.set_kernel_canonical_names(H.canonical_names());
    scripts_.SetAt(index, script);

    script.set_line_starts(Array::Handle(Array::null()));
    script.set_debug_positions(Array::Handle(Array::null()));
    script.set_yield_positions(Array::Handle(Array::null()));
  }
  return script;
}

void KernelReader::GenerateFieldAccessors(const dart::Class& klass,
                                          const dart::Field& field,
                                          FieldHelper* field_helper,
                                          intptr_t field_offset) {
  Tag tag = builder_.PeekTag();
  if (field_helper->IsStatic() && tag == kNothing) {
    // Static fields without an initializer are implicitly initialized to null.
    // We do not need a getter.
    field.SetStaticValue(Instance::Handle(Z), true);
    return;
  }
  if (tag == kSomething) {
    SimpleExpressionConverter converter(&H, &builder_);
    const bool has_simple_initializer =
        converter.IsSimple(builder_.ReaderOffset() + 1);  // ignore the tag.
    if (field_helper->IsStatic()) {
      // Static fields with initializers either have the static value set to the
      // initializer value if it is simple enough or else set to an
      // uninitialized sentinel.
      if (has_simple_initializer) {
        // We do not need a getter.
        field.SetStaticValue(converter.SimpleValue(), true);
        return;
      }
      // We do need a getter that evaluates the initializer if necessary.
      field.SetStaticValue(Object::sentinel(), true);
    } else if (has_simple_initializer) {
      // Note: optimizer relies on DoubleInitialized bit in its field-unboxing
      // heuristics. See JitOptimizer::VisitStoreInstanceField for more details.
      field.RecordStore(converter.SimpleValue());
      if (!converter.SimpleValue().IsNull() &&
          converter.SimpleValue().IsDouble()) {
        field.set_is_double_initialized(true);
      }
    }
  }

  const dart::String& getter_name =
      H.DartGetterName(field_helper->canonical_name_);
  const Object& script_class =
      ClassForScriptAt(klass, field_helper->source_uri_index_);
  Function& getter = Function::ZoneHandle(
      Z,
      Function::New(
          getter_name,
          field_helper->IsStatic() ? RawFunction::kImplicitStaticFinalGetter
                                   : RawFunction::kImplicitGetter,
          field_helper->IsStatic(),
          // The functions created by the parser have is_const for static fields
          // that are const (not just final) and they have is_const for
          // non-static
          // fields that are final.
          field_helper->IsStatic() ? field_helper->IsConst()
                                   : field_helper->IsFinal(),
          false,  // is_abstract
          false,  // is_external
          false,  // is_native
          script_class, field_helper->position_));
  functions_.Add(&getter);
  getter.set_end_token_pos(field_helper->end_position_);
  getter.set_kernel_offset(field_offset);
  getter.set_result_type(AbstractType::Handle(Z, field.type()));
  getter.set_is_debuggable(false);
  SetupFieldAccessorFunction(klass, getter);

  if (!field_helper->IsStatic() && !field_helper->IsFinal()) {
    // Only static fields can be const.
    ASSERT(!field_helper->IsConst());
    const dart::String& setter_name =
        H.DartSetterName(field_helper->canonical_name_);
    Function& setter = Function::ZoneHandle(
        Z, Function::New(setter_name, RawFunction::kImplicitSetter,
                         false,  // is_static
                         false,  // is_const
                         false,  // is_abstract
                         false,  // is_external
                         false,  // is_native
                         script_class, field_helper->position_));
    functions_.Add(&setter);
    setter.set_end_token_pos(field_helper->end_position_);
    setter.set_kernel_offset(field_offset);
    setter.set_result_type(Object::void_type());
    setter.set_is_debuggable(false);
    SetupFieldAccessorFunction(klass, setter);
  }
}

void KernelReader::SetupFieldAccessorFunction(const dart::Class& klass,
                                              const dart::Function& function) {
  bool is_setter = function.IsImplicitSetterFunction();
  bool is_method = !function.IsStaticFunction();
  intptr_t parameter_count = (is_method ? 1 : 0) + (is_setter ? 1 : 0);

  function.SetNumOptionalParameters(0, false);
  function.set_num_fixed_parameters(parameter_count);
  function.set_parameter_types(
      Array::Handle(Z, Array::New(parameter_count, Heap::kOld)));
  function.set_parameter_names(
      Array::Handle(Z, Array::New(parameter_count, Heap::kOld)));

  intptr_t pos = 0;
  if (is_method) {
    function.SetParameterTypeAt(pos, T.ReceiverType(klass));
    function.SetParameterNameAt(pos, Symbols::This());
    pos++;
  }
  if (is_setter) {
    function.SetParameterTypeAt(pos, AbstractType::dynamic_type());
    function.SetParameterNameAt(pos, Symbols::Value());
    pos++;
  }
}

dart::Library& KernelReader::LookupLibrary(NameIndex library) {
  dart::Library* handle = NULL;
  if (!libraries_.Lookup(library, &handle)) {
    const dart::String& url = H.DartSymbol(H.CanonicalNameString(library));
    handle =
        &dart::Library::Handle(Z, dart::Library::LookupLibrary(thread_, url));
    if (handle->IsNull()) {
      *handle = dart::Library::New(url);
      handle->Register(thread_);
    }
    ASSERT(!handle->IsNull());
    libraries_.Insert(library, handle);
  }
  return *handle;
}

dart::Class& KernelReader::LookupClass(NameIndex klass) {
  dart::Class* handle = NULL;
  if (!classes_.Lookup(klass, &handle)) {
    dart::Library& library = LookupLibrary(H.CanonicalNameParent(klass));
    const dart::String& name = H.DartClassName(klass);
    handle = &dart::Class::Handle(Z, library.LookupClass(name));
    if (handle->IsNull()) {
      *handle = dart::Class::New(library, name, Script::Handle(Z),
                                 TokenPosition::kNoSource);
      library.AddClass(*handle);
    }
    // Insert the class in the cache before calling ReadPreliminaryClass so
    // we do not risk allocating the class again by calling LookupClass
    // recursively from ReadPreliminaryClass for the same class.
    classes_.Insert(klass, handle);
  }
  return *handle;
}

RawFunction::Kind KernelReader::GetFunctionType(
    Procedure::ProcedureKind procedure_kind) {
  intptr_t lookuptable[] = {
      RawFunction::kRegularFunction,  // Procedure::kMethod
      RawFunction::kGetterFunction,   // Procedure::kGetter
      RawFunction::kSetterFunction,   // Procedure::kSetter
      RawFunction::kRegularFunction,  // Procedure::kOperator
      RawFunction::kConstructor,      // Procedure::kFactory
  };
  intptr_t kind = static_cast<int>(procedure_kind);
  if (kind == Procedure::kIncompleteProcedure) {
    return RawFunction::kSignatureFunction;
  } else {
    ASSERT(0 <= kind && kind <= Procedure::kFactory);
    return static_cast<RawFunction::Kind>(lookuptable[kind]);
  }
}

bool KernelReader::FieldHasFunctionLiteralInitializer(const dart::Field& field,
                                                      TokenPosition* start,
                                                      TokenPosition* end) {
  dart::Zone* zone = Thread::Current()->zone();
  const Script& script = Script::Handle(zone, field.Script());

  TranslationHelper translation_helper(
      Thread::Current(), script.kernel_string_offsets(),
      script.kernel_string_data(), script.kernel_canonical_names());

  kernel::StreamingFlowGraphBuilder* builder =
      new kernel::StreamingFlowGraphBuilder(&translation_helper, zone,
                                            script.kernel_data(),
                                            script.kernel_data_size());

  kernel::FieldHelper field_helper(builder, field.kernel_offset());
  field_helper.ReadUntilExcluding(kernel::FieldHelper::kEnd, true);
  bool result = field_helper.FieldHasFunctionLiteralInitializer(start, end);

  delete builder;
  return result;
}

ParsedFunction* ParseStaticFieldInitializer(Zone* zone,
                                            const dart::Field& field) {
  Thread* thread = Thread::Current();

  dart::String& init_name = dart::String::Handle(zone, field.name());
  init_name = Symbols::FromConcat(thread, Symbols::InitPrefix(), init_name);

  // Create a static initializer.
  const Object& owner = Object::Handle(field.RawOwner());
  const Function& initializer_fun = Function::ZoneHandle(
      zone,
      dart::Function::New(init_name, RawFunction::kImplicitStaticFinalGetter,
                          true,   // is_static
                          false,  // is_const
                          false,  // is_abstract
                          false,  // is_external
                          false,  // is_native
                          owner, TokenPosition::kNoSource));
  initializer_fun.set_kernel_offset(field.kernel_offset());
  initializer_fun.set_result_type(AbstractType::Handle(zone, field.type()));
  initializer_fun.set_is_debuggable(false);
  initializer_fun.set_is_reflectable(false);
  initializer_fun.set_is_inlinable(false);
  return new (zone) ParsedFunction(thread, initializer_fun);
}

}  // namespace kernel
}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
