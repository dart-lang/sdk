// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_reader.h"

#include <string.h>

#include "vm/dart_api_impl.h"
#include "vm/kernel_binary.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/symbols.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
namespace dart {
namespace kernel {

#define Z (zone_)
#define I (isolate_)
#define T (type_translator_)
#define H (translation_helper_)

class SimpleExpressionConverter : public ExpressionVisitor {
 public:
  explicit SimpleExpressionConverter(TranslationHelper* helper)
      : translation_helper_(*helper),
        zone_(translation_helper_.zone()),
        is_simple_(false),
        simple_value_(NULL) {}

  virtual void VisitDefaultExpression(Expression* node) { is_simple_ = false; }

  virtual void VisitIntLiteral(IntLiteral* node) {
    is_simple_ = true;
    simple_value_ =
        &Integer::ZoneHandle(Z, Integer::New(node->value(), Heap::kOld));
    *simple_value_ = H.Canonicalize(*simple_value_);
  }

  virtual void VisitBigintLiteral(BigintLiteral* node) {
    is_simple_ = true;
    simple_value_ = &Integer::ZoneHandle(
        Z, Integer::New(H.DartString(node->value(), Heap::kOld)));
    *simple_value_ = H.Canonicalize(*simple_value_);
  }

  virtual void VisitDoubleLiteral(DoubleLiteral* node) {
    is_simple_ = true;
    simple_value_ = &Double::ZoneHandle(
        Z, Double::New(H.DartString(node->value()), Heap::kOld));
    *simple_value_ = H.Canonicalize(*simple_value_);
  }

  virtual void VisitBoolLiteral(BoolLiteral* node) {
    is_simple_ = true;
    simple_value_ = &Bool::Handle(Z, Bool::Get(node->value()).raw());
  }

  virtual void VisitNullLiteral(NullLiteral* node) {
    is_simple_ = true;
    simple_value_ = &dart::Instance::ZoneHandle(Z, dart::Instance::null());
  }

  virtual void VisitStringLiteral(StringLiteral* node) {
    is_simple_ = true;
    simple_value_ = &H.DartSymbol(node->value());
  }

  bool IsSimple(Expression* expression) {
    expression->AcceptExpressionVisitor(this);
    return is_simple_;
  }

  const dart::Instance& SimpleValue() { return *simple_value_; }
  dart::Zone* zone() const { return zone_; }

 private:
  TranslationHelper& translation_helper_;
  dart::Zone* zone_;
  bool is_simple_;
  dart::Instance* simple_value_;
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
      translation_helper_(this, thread_),
      type_translator_(&translation_helper_,
                       &active_class_,
                       /*finalize=*/false) {
  intptr_t source_file_count = program->source_table().size();
  scripts_ = Array::New(source_file_count, Heap::kOld);

  // We need at least one library to get access to the binary.
  ASSERT(program->libraries().length() > 0);
  Library* library = program->libraries()[0];
  Reader reader(library->kernel_data(), library->kernel_data_size());

  // Copy the Kernel string offsets out of the binary and into the VM's heap.
  ASSERT(program->string_table_offset() >= 0);
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
    intptr_t length = program_->libraries().length();
    for (intptr_t i = 0; i < length; i++) {
      Library* kernel_library = program_->libraries()[i];
      ReadLibrary(kernel_library);
    }

    for (intptr_t i = 0; i < length; i++) {
      dart::Library& library =
          LookupLibrary(program_->libraries()[i]->canonical_name());
      if (!library.Loaded()) library.SetLoaded();
    }

    if (ClassFinalizer::ProcessPendingClasses(/*from_kernel=*/true)) {
      // There is a function _getMainClosure in dart:_builtin that returns the
      // main procedure.  Since the platform libraries are compiled before the
      // program script, this function might need to be patched here.

      // If there is no main method then we have compiled a partial Kernel file
      // and do not need to patch here.
      NameIndex main = program_->main_method();
      if (main == -1) {
        return dart::Library::Handle(Z);
      }

      // If the builtin library is not set in the object store, then we are
      // bootstrapping and do not need to patch here.
      dart::Library& builtin_library =
          dart::Library::Handle(Z, I->object_store()->builtin_library());
      if (builtin_library.IsNull()) {
        return dart::Library::Handle(Z);
      }

      NameIndex main_library = H.EnclosingName(main);
      dart::Library& library = LookupLibrary(main_library);
      // Sanity check that we can find the main entrypoint.
      Object& main_obj = Object::Handle(
          Z, library.LookupObjectAllowPrivate(H.DartSymbol("main")));
      ASSERT(!main_obj.IsNull());

      Function& to_patch = Function::Handle(
          Z, builtin_library.LookupFunctionAllowPrivate(
                 dart::String::Handle(dart::String::New("_getMainClosure"))));

      Procedure* procedure =
          reinterpret_cast<Procedure*>(to_patch.kernel_function());
      // If dart:_builtin was not compiled from Kernel at all it does not need
      // to be patched.
      if (procedure != NULL) {
        // We will handle the StaticGet specially and will not use the name.
        // Note that we pass "true" in cannot_stream to avoid trying to stream
        // a non-existing part of the binary.
        //
        // TODO(kmillikin): we are leaking the new function body.  Find a way to
        // deallocate it.
        procedure->function()->ReplaceBody(
            new ReturnStatement(new StaticGet(NameIndex(), false), false));
      }
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


void KernelReader::ReadLibrary(Library* kernel_library) {
  dart::Library& library = LookupLibrary(kernel_library->canonical_name());
  if (library.Loaded()) return;
  library.SetName(H.DartSymbol(kernel_library->name()));

  // The bootstrapper will take care of creating the native wrapper classes, but
  // we will add the synthetic constructors to them here.
  if (library.name() ==
      Symbols::Symbol(Symbols::kDartNativeWrappersLibNameId).raw()) {
    ASSERT(library.LoadInProgress());
  } else {
    library.SetLoadInProgress();
  }
  // Setup toplevel class (which contains library fields/procedures).

  Script& script = ScriptAt(kernel_library->source_uri_index(),
                            kernel_library->import_uri());
  dart::Class& toplevel_class = dart::Class::Handle(
      Z, dart::Class::New(library, Symbols::TopLevel(), script,
                          TokenPosition::kNoSource));
  toplevel_class.set_is_cycle_free();
  library.set_toplevel_class(toplevel_class);

  fields_.Clear();
  functions_.Clear();
  ActiveClassScope active_class_scope(&active_class_, NULL, &toplevel_class);
  // Load toplevel fields.
  for (intptr_t i = 0; i < kernel_library->fields().length(); i++) {
    Field* kernel_field = kernel_library->fields()[i];

    ActiveMemberScope active_member_scope(&active_class_, kernel_field);
    const dart::String& name = H.DartFieldName(kernel_field->name());
    const Object& script_class =
        ClassForScriptAt(toplevel_class, kernel_field->source_uri_index());
    dart::Field& field = dart::Field::Handle(
        Z, dart::Field::NewTopLevel(name, kernel_field->IsFinal(),
                                    kernel_field->IsConst(), script_class,
                                    kernel_field->position()));
    field.set_kernel_field(kernel_field);
    const AbstractType& type = T.TranslateType(kernel_field->type());
    field.SetFieldType(type);
    field.set_has_initializer(kernel_field->initializer() != NULL);
    GenerateFieldAccessors(toplevel_class, field, kernel_field);
    fields_.Add(&field);
    library.AddObject(field, name);
  }
  toplevel_class.AddFields(fields_);

  // Load toplevel procedures.
  for (intptr_t i = 0; i < kernel_library->procedures().length(); i++) {
    Procedure* kernel_procedure = kernel_library->procedures()[i];
    ReadProcedure(library, toplevel_class, kernel_procedure);
  }

  toplevel_class.SetFunctions(Array::Handle(MakeFunctionsArray()));

  const GrowableObjectArray& classes =
      GrowableObjectArray::Handle(Z, I->object_store()->pending_classes());

  // Load all classes.
  for (intptr_t i = 0; i < kernel_library->classes().length(); i++) {
    Class* kernel_klass = kernel_library->classes()[i];
    classes.Add(ReadClass(library, toplevel_class, kernel_klass), Heap::kOld);
  }

  classes.Add(toplevel_class, Heap::kOld);
}


void KernelReader::ReadPreliminaryClass(dart::Class* klass,
                                        Class* kernel_klass) {
  ASSERT(kernel_klass->IsNormalClass());
  NormalClass* kernel_normal_class = NormalClass::Cast(kernel_klass);

  ActiveClassScope active_class_scope(&active_class_, kernel_klass, klass);

  // First setup the type parameters, so if any of the following code uses it
  // (in a recursive way) we're fine.
  TypeArguments& type_parameters =
      TypeArguments::Handle(Z, TypeArguments::null());
  intptr_t num_type_parameters = kernel_klass->type_parameters().length();
  if (num_type_parameters > 0) {
    dart::TypeParameter& parameter = dart::TypeParameter::Handle(Z);
    Type& null_bound = Type::Handle(Z, Type::null());

    // Step a) Create array of [TypeParameter] objects (without bound).
    type_parameters = TypeArguments::New(num_type_parameters);
    for (intptr_t i = 0; i < num_type_parameters; i++) {
      parameter = dart::TypeParameter::New(
          *klass, Function::Handle(Z), i,
          H.DartSymbol(kernel_klass->type_parameters()[i]->name()), null_bound,
          TokenPosition::kNoSource);
      type_parameters.SetTypeAt(i, parameter);
    }
    klass->set_type_parameters(type_parameters);

    // Step b) Fill in the bounds of all [TypeParameter]s.
    for (intptr_t i = 0; i < num_type_parameters; i++) {
      TypeParameter* kernel_parameter = kernel_klass->type_parameters()[i];
      // TODO(github.com/dart-lang/kernel/issues/42): This should be handled
      // by the frontend.
      if (kernel_parameter->bound()->IsDynamicType()) {
        parameter ^= type_parameters.TypeAt(i);
        parameter.set_bound(Type::Handle(Z, I->object_store()->object_type()));
      } else {
        AbstractType& bound =
            T.TranslateTypeWithoutFinalization(kernel_parameter->bound());
        if (bound.IsMalformedOrMalbounded()) {
          bound = I->object_store()->object_type();
        }

        parameter ^= type_parameters.TypeAt(i);
        parameter.set_bound(bound);
      }
    }
  }

  // Set super type.  Some classes (e.g., Object) do not have one.
  if (kernel_normal_class->super_class() != NULL) {
    AbstractType& super_type =
        T.TranslateTypeWithoutFinalization(kernel_normal_class->super_class());
    if (super_type.IsMalformed()) H.ReportError("Malformed super type");
    klass->set_super_type(super_type);
  }

  // Build implemented interface types
  intptr_t interface_count = kernel_klass->implemented_classes().length();
  const dart::Array& interfaces =
      dart::Array::Handle(Z, dart::Array::New(interface_count, Heap::kOld));
  for (intptr_t i = 0; i < interface_count; i++) {
    InterfaceType* kernel_interface_type =
        kernel_klass->implemented_classes()[i];
    const AbstractType& type =
        T.TranslateTypeWithoutFinalization(kernel_interface_type);
    if (type.IsMalformed()) H.ReportError("Malformed interface type.");
    interfaces.SetAt(i, type);
  }
  klass->set_interfaces(interfaces);
  if (kernel_klass->is_abstract()) klass->set_is_abstract();
}


dart::Class& KernelReader::ReadClass(const dart::Library& library,
                                     const dart::Class& toplevel_class,
                                     Class* kernel_klass) {
  dart::Class& klass = LookupClass(kernel_klass->canonical_name());

  // The class needs to have a script because all the functions in the class
  // will inherit it.  The predicate Function::IsOptimizable uses the absence of
  // a script to detect test functions that should not be optimized.
  if (klass.script() == Script::null()) {
    klass.set_script(ScriptAt(kernel_klass->source_uri_index()));
  }
  if (klass.token_pos() == TokenPosition::kNoSource) {
    klass.set_token_pos(kernel_klass->position());
  }
  if (!klass.is_cycle_free()) {
    ReadPreliminaryClass(&klass, kernel_klass);
  }

  ActiveClassScope active_class_scope(&active_class_, kernel_klass, &klass);
  fields_.Clear();
  functions_.Clear();

  if (library.raw() == dart::Library::InternalLibrary() &&
      klass.Name() == Symbols::ClassID().raw()) {
    // If this is a dart:internal.ClassID class ignore field declarations
    // contained in the Kernel file and instead inject our own const
    // fields.
    klass.InjectCIDFields();
  } else {
    for (intptr_t i = 0; i < kernel_klass->fields().length(); i++) {
      Field* kernel_field = kernel_klass->fields()[i];
      ActiveMemberScope active_member_scope(&active_class_, kernel_field);

      const dart::String& name = H.DartFieldName(kernel_field->name());
      const AbstractType& type =
          T.TranslateTypeWithoutFinalization(kernel_field->type());
      const Object& script_class =
          ClassForScriptAt(klass, kernel_field->source_uri_index());
      dart::Field& field = dart::Field::Handle(
          Z,
          dart::Field::New(name, kernel_field->IsStatic(),
                           // In the VM all const fields are implicitly final
                           // whereas in Kernel they are not final because they
                           // are not explicitly declared that way.
                           kernel_field->IsFinal() || kernel_field->IsConst(),
                           kernel_field->IsConst(),
                           false,  // is_reflectable
                           script_class, type, kernel_field->position()));
      field.set_kernel_field(kernel_field);
      field.set_has_initializer(kernel_field->initializer() != NULL);
      GenerateFieldAccessors(klass, field, kernel_field);
      fields_.Add(&field);
    }
    klass.AddFields(fields_);
  }

  for (intptr_t i = 0; i < kernel_klass->constructors().length(); i++) {
    Constructor* kernel_constructor = kernel_klass->constructors()[i];
    ActiveMemberScope active_member_scope(&active_class_, kernel_constructor);

    const dart::String& name =
        H.DartConstructorName(kernel_constructor->canonical_name());
    Function& function = dart::Function::ZoneHandle(
        Z, dart::Function::New(name, RawFunction::kConstructor,
                               false,  // is_static
                               kernel_constructor->IsConst(),
                               false,  // is_abstract
                               kernel_constructor->IsExternal(),
                               false,  // is_native
                               klass, kernel_constructor->position()));
    function.set_end_token_pos(kernel_constructor->end_position());
    functions_.Add(&function);
    function.set_kernel_function(kernel_constructor);
    function.set_result_type(T.ReceiverType(klass));
    SetupFunctionParameters(H, T, klass, function,
                            kernel_constructor->function(),
                            true,    // is_method
                            false);  // is_closure

    if (FLAG_enable_mirrors) {
      library.AddFunctionMetadata(function, TokenPosition::kNoSource,
                                  kernel_constructor);
    }
  }

  for (intptr_t i = 0; i < kernel_klass->procedures().length(); i++) {
    Procedure* kernel_procedure = kernel_klass->procedures()[i];
    ActiveMemberScope active_member_scope(&active_class_, kernel_procedure);
    ReadProcedure(library, klass, kernel_procedure, kernel_klass);
  }

  klass.SetFunctions(Array::Handle(MakeFunctionsArray()));

  if (!klass.is_marked_for_parsing()) {
    klass.set_is_marked_for_parsing();
  }

  if (FLAG_enable_mirrors) {
    library.AddClassMetadata(klass, toplevel_class, TokenPosition::kNoSource,
                             kernel_klass);
  }

  return klass;
}


void KernelReader::ReadProcedure(const dart::Library& library,
                                 const dart::Class& owner,
                                 Procedure* kernel_procedure,
                                 Class* kernel_klass) {
  ActiveClassScope active_class_scope(&active_class_, kernel_klass, &owner);
  ActiveMemberScope active_member_scope(&active_class_, kernel_procedure);

  const dart::String& name =
      H.DartProcedureName(kernel_procedure->canonical_name());
  bool is_method = kernel_klass != NULL && !kernel_procedure->IsStatic();
  bool is_abstract = kernel_procedure->IsAbstract();
  bool is_external = kernel_procedure->IsExternal();
  dart::String* native_name = NULL;
  if (is_external) {
    // Maybe it has a native implementation, which is not external as far as
    // the VM is concerned because it does have an implementation.  Check for
    // an ExternalName annotation and extract the string from it.
    for (int i = 0; i < kernel_procedure->annotations().length(); ++i) {
      Expression* annotation = kernel_procedure->annotations()[i];
      if (!annotation->IsConstructorInvocation()) continue;
      ConstructorInvocation* invocation =
          ConstructorInvocation::Cast(annotation);
      NameIndex annotation_class = H.EnclosingName(invocation->target());
      ASSERT(H.IsClass(annotation_class));
      StringIndex class_name_index = H.CanonicalNameString(annotation_class);
      // Just compare by name, do not generate the annotation class.
      if (!H.StringEquals(class_name_index, "ExternalName")) continue;
      ASSERT(H.IsLibrary(H.CanonicalNameParent(annotation_class)));
      StringIndex library_name_index =
          H.CanonicalNameString(H.CanonicalNameParent(annotation_class));
      if (!H.StringEquals(library_name_index, "dart:_internal")) continue;

      is_external = false;
      ASSERT(invocation->arguments()->positional().length() == 1 &&
             invocation->arguments()->named().length() == 0);
      StringLiteral* literal =
          StringLiteral::Cast(invocation->arguments()->positional()[0]);
      native_name = &H.DartSymbol(literal->value());
      break;
    }
  }
  const Object& script_class =
      ClassForScriptAt(owner, kernel_procedure->source_uri_index());
  dart::Function& function = dart::Function::ZoneHandle(
      Z, Function::New(name, GetFunctionType(kernel_procedure),
                       !is_method,  // is_static
                       false,       // is_const
                       is_abstract, is_external,
                       native_name != NULL,  // is_native
                       script_class, kernel_procedure->position()));
  function.set_end_token_pos(kernel_procedure->end_position());
  functions_.Add(&function);
  function.set_kernel_function(kernel_procedure);

  function.set_is_debuggable(
      kernel_procedure->function()->dart_async_marker() == FunctionNode::kSync);
  switch (kernel_procedure->function()->dart_async_marker()) {
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
  ASSERT(kernel_procedure->function()->async_marker() == FunctionNode::kSync);

  if (native_name != NULL) {
    function.set_native_name(*native_name);
  }

  SetupFunctionParameters(H, T, owner, function, kernel_procedure->function(),
                          is_method,
                          false);  // is_closure

  if (kernel_klass == NULL) {
    library.AddObject(function, name);
    ASSERT(!Object::Handle(
                Z, library.LookupObjectAllowPrivate(
                       H.DartProcedureName(kernel_procedure->canonical_name())))
                .IsNull());
  }
  if (FLAG_enable_mirrors) {
    library.AddFunctionMetadata(function, TokenPosition::kNoSource,
                                kernel_procedure);
  }
}

const Object& KernelReader::ClassForScriptAt(const dart::Class& klass,
                                             intptr_t source_uri_index) {
  Script& correct_script = ScriptAt(source_uri_index);
  if (klass.script() != correct_script.raw()) {
    // TODO(jensj): We could probably cache this so we don't create
    // new PatchClasses all the time
    return PatchClass::ZoneHandle(Z, PatchClass::New(klass, correct_script));
  }
  return klass;
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
static RawArray* AsSortedDuplicateFreeArray(
    intptr_t index,
    MallocGrowableArray<MallocGrowableArray<intptr_t>*>* list) {
  if ((index < list->length()) && (list->At(index)->length() > 0)) {
    MallocGrowableArray<intptr_t>* source = list->At(index);
    source->Sort(LowestFirst);

    intptr_t size = source->length();
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
  } else {
    return Array::New(0);
  }
}

Script& KernelReader::ScriptAt(intptr_t index, StringIndex import_uri) {
  Script& script = Script::ZoneHandle(Z);
  script ^= scripts_.At(index);
  if (script.IsNull()) {
    // Create script with correct uri(s).
    uint8_t* uri_buffer = program_->source_table().UriFor(index);
    intptr_t uri_size = program_->source_table().UriSizeFor(index);
    dart::String& uri_string = H.DartString(uri_buffer, uri_size, Heap::kOld);
    dart::String& import_uri_string =
        import_uri == -1 ? uri_string : H.DartString(import_uri, Heap::kOld);
    uint8_t* source_buffer = program_->source_table().SourceCodeFor(index);
    intptr_t source_size = program_->source_table().SourceCodeSizeFor(index);
    dart::String& source_code =
        H.DartString(source_buffer, source_size, Heap::kOld);
    script = Script::New(import_uri_string, uri_string, source_code,
                         RawScript::kKernelTag);
    script.set_kernel_string_offsets(H.string_offsets());
    script.set_kernel_string_data(H.string_data());
    script.set_kernel_canonical_names(H.canonical_names());
    scripts_.SetAt(index, script);

    // Create line_starts array for the script.
    intptr_t* line_starts = program_->source_table().LineStartsFor(index);
    intptr_t line_count = program_->source_table().LineCountFor(index);
    Array& array_object = Array::Handle(Z, Array::New(line_count, Heap::kOld));
    Smi& value = Smi::Handle(Z);
    for (intptr_t i = 0; i < line_count; ++i) {
      value = Smi::New(line_starts[i]);
      array_object.SetAt(i, value);
    }
    script.set_line_starts(array_object);

    // Create tokens_seen array for the script.
    array_object =
        AsSortedDuplicateFreeArray(index, &program_->valid_token_positions);
    script.set_debug_positions(array_object);

    // Create yield_positions array for the script.
    array_object =
        AsSortedDuplicateFreeArray(index, &program_->yield_token_positions);
    script.set_yield_positions(array_object);
  }
  return script;
}

void KernelReader::GenerateFieldAccessors(const dart::Class& klass,
                                          const dart::Field& field,
                                          Field* kernel_field) {
  if (kernel_field->IsStatic() && kernel_field->initializer() == NULL) {
    // Static fields without an initializer are implicitly initialized to null.
    // We do not need a getter.
    field.SetStaticValue(Instance::Handle(Z), true);
    return;
  }
  if (kernel_field->initializer() != NULL) {
    SimpleExpressionConverter converter(&H);
    const bool has_simple_initializer =
        converter.IsSimple(kernel_field->initializer());
    if (kernel_field->IsStatic()) {
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
      H.DartGetterName(kernel_field->canonical_name());
  const Object& script_class =
      ClassForScriptAt(klass, kernel_field->source_uri_index());
  Function& getter = Function::ZoneHandle(
      Z,
      Function::New(
          getter_name,
          kernel_field->IsStatic() ? RawFunction::kImplicitStaticFinalGetter
                                   : RawFunction::kImplicitGetter,
          kernel_field->IsStatic(),
          // The functions created by the parser have is_const for static fields
          // that are const (not just final) and they have is_const for
          // non-static
          // fields that are final.
          kernel_field->IsStatic() ? kernel_field->IsConst()
                                   : kernel_field->IsFinal(),
          false,  // is_abstract
          false,  // is_external
          false,  // is_native
          script_class, kernel_field->position()));
  functions_.Add(&getter);
  getter.set_end_token_pos(kernel_field->end_position());
  getter.set_kernel_function(kernel_field);
  getter.set_result_type(AbstractType::Handle(Z, field.type()));
  getter.set_is_debuggable(false);
  SetupFieldAccessorFunction(klass, getter);

  if (!kernel_field->IsStatic() && !kernel_field->IsFinal()) {
    // Only static fields can be const.
    ASSERT(!kernel_field->IsConst());
    const dart::String& setter_name =
        H.DartSetterName(kernel_field->canonical_name());
    Function& setter = Function::ZoneHandle(
        Z, Function::New(setter_name, RawFunction::kImplicitSetter,
                         false,  // is_static
                         false,  // is_const
                         false,  // is_abstract
                         false,  // is_external
                         false,  // is_native
                         script_class, kernel_field->position()));
    functions_.Add(&setter);
    setter.set_end_token_pos(kernel_field->end_position());
    setter.set_kernel_function(kernel_field);
    setter.set_result_type(Object::void_type());
    setter.set_is_debuggable(false);
    SetupFieldAccessorFunction(klass, setter);
  }
}


void KernelReader::SetupFunctionParameters(TranslationHelper translation_helper,
                                           DartTypeTranslator type_translator,
                                           const dart::Class& klass,
                                           const dart::Function& function,
                                           FunctionNode* node,
                                           bool is_method,
                                           bool is_closure) {
  dart::Zone* zone = translation_helper.zone();

  ASSERT(!(is_method && is_closure));
  bool is_factory = function.IsFactory();
  intptr_t extra_parameters = (is_method || is_closure || is_factory) ? 1 : 0;

  function.set_num_fixed_parameters(extra_parameters +
                                    node->required_parameter_count());
  if (node->named_parameters().length() > 0) {
    function.SetNumOptionalParameters(node->named_parameters().length(), false);
  } else {
    function.SetNumOptionalParameters(node->positional_parameters().length() -
                                          node->required_parameter_count(),
                                      true);
  }
  intptr_t num_parameters = extra_parameters +
                            node->positional_parameters().length() +
                            node->named_parameters().length();
  function.set_parameter_types(
      Array::Handle(zone, Array::New(num_parameters, Heap::kOld)));
  function.set_parameter_names(
      Array::Handle(zone, Array::New(num_parameters, Heap::kOld)));
  intptr_t pos = 0;
  if (is_method) {
    ASSERT(!klass.IsNull());
    function.SetParameterTypeAt(pos,
                                translation_helper.GetCanonicalType(klass));
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
  for (intptr_t i = 0; i < node->positional_parameters().length(); i++, pos++) {
    VariableDeclaration* kernel_variable = node->positional_parameters()[i];
    const AbstractType& type = type_translator.TranslateTypeWithoutFinalization(
        kernel_variable->type());
    function.SetParameterTypeAt(
        pos, type.IsMalformed() ? Type::dynamic_type() : type);
    function.SetParameterNameAt(
        pos, translation_helper.DartSymbol(kernel_variable->name()));
  }
  for (intptr_t i = 0; i < node->named_parameters().length(); i++, pos++) {
    VariableDeclaration* named_expression = node->named_parameters()[i];
    const AbstractType& type = type_translator.TranslateTypeWithoutFinalization(
        named_expression->type());
    function.SetParameterTypeAt(
        pos, type.IsMalformed() ? Type::dynamic_type() : type);
    function.SetParameterNameAt(
        pos, translation_helper.DartSymbol(named_expression->name()));
  }

  // The result type for generative constructors has already been set.
  if (!function.IsGenerativeConstructor()) {
    const AbstractType& return_type =
        type_translator.TranslateTypeWithoutFinalization(node->return_type());
    function.set_result_type(return_type.IsMalformed() ? Type::dynamic_type()
                                                       : return_type);
  }
}


void KernelReader::SetupFieldAccessorFunction(const dart::Class& klass,
                                              const dart::Function& function) {
  bool is_setter = function.IsImplicitSetterFunction();
  bool is_method = !function.IsStaticFunction();
  intptr_t num_parameters = (is_method ? 1 : 0) + (is_setter ? 1 : 0);

  function.SetNumOptionalParameters(0, false);
  function.set_num_fixed_parameters(num_parameters);
  function.set_parameter_types(
      Array::Handle(Z, Array::New(num_parameters, Heap::kOld)));
  function.set_parameter_names(
      Array::Handle(Z, Array::New(num_parameters, Heap::kOld)));

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


RawFunction::Kind KernelReader::GetFunctionType(Procedure* kernel_procedure) {
  intptr_t lookuptable[] = {
      RawFunction::kRegularFunction,  // Procedure::kMethod
      RawFunction::kGetterFunction,   // Procedure::kGetter
      RawFunction::kSetterFunction,   // Procedure::kSetter
      RawFunction::kRegularFunction,  // Procedure::kOperator
      RawFunction::kConstructor,      // Procedure::kFactory
  };
  intptr_t kind = static_cast<int>(kernel_procedure->kind());
  if (kind == Procedure::kIncompleteProcedure) {
    return RawFunction::kSignatureFunction;
  } else {
    ASSERT(0 <= kind && kind <= Procedure::kFactory);
    return static_cast<RawFunction::Kind>(lookuptable[kind]);
  }
}


ParsedFunction* ParseStaticFieldInitializer(Zone* zone,
                                            const dart::Field& field) {
  Thread* thread = Thread::Current();
  kernel::Field* kernel_field = kernel::Field::Cast(
      reinterpret_cast<kernel::Node*>(field.kernel_field()));

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
  initializer_fun.set_kernel_function(kernel_field);
  initializer_fun.set_result_type(AbstractType::Handle(zone, field.type()));
  initializer_fun.set_is_debuggable(false);
  initializer_fun.set_is_reflectable(false);
  initializer_fun.set_is_inlinable(false);
  return new (zone) ParsedFunction(thread, initializer_fun);
}


}  // namespace kernel
}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
