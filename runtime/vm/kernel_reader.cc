// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_reader.h"

#include <string.h>

#include "vm/dart_api_impl.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/symbols.h"

namespace dart {
namespace kernel {

#define Z (zone_)
#define I (isolate_)
#define T (type_translator_)
#define H (translation_helper_)

class SimpleExpressionConverter : public ExpressionVisitor {
 public:
  SimpleExpressionConverter(Thread* thread, Zone* zone)
      : translation_helper_(thread, zone, NULL),
        zone_(zone),
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
  TranslationHelper translation_helper_;
  dart::Zone* zone_;
  bool is_simple_;
  dart::Instance* simple_value_;
};

void BuildingTranslationHelper::SetFinalize(bool finalize) {
  reader_->finalize_ = finalize;
}

RawLibrary* BuildingTranslationHelper::LookupLibraryByKernelLibrary(
    Library* library) {
  return reader_->LookupLibrary(library).raw();
}

RawClass* BuildingTranslationHelper::LookupClassByKernelClass(Class* klass) {
  return reader_->LookupClass(klass).raw();
}

Object& KernelReader::ReadProgram() {
  ASSERT(!bootstrapping_);
  Program* program = ReadPrecompiledKernelFromBuffer(buffer_, buffer_length_);
  if (program == NULL) {
    const dart::String& error = H.DartString("Failed to read .kernell file");
    return Object::Handle(Z, ApiError::New(error));
  }

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Procedure* main = program->main_method();
    Library* kernel_main_library = Library::Cast(main->parent());

    intptr_t length = program->libraries().length();
    for (intptr_t i = 0; i < length; i++) {
      Library* kernel_library = program->libraries()[i];
      ReadLibrary(kernel_library);
    }

    // We finalize classes after we've constructed all classes since we
    // currently don't construct them in pre-order of the class hierarchy (and
    // finalization of a class needs all of its superclasses to be finalized).
    dart::String& name = dart::String::Handle(Z);
    for (intptr_t i = 0; i < length; i++) {
      Library* kernel_library = program->libraries()[i];
      dart::Library& library = LookupLibrary(kernel_library);
      name = library.url();

      // TODO(27590) unskip this library when we fix underlying issue.
      if (name.Equals("dart:vmservice_io")) {
        continue;
      }

      if (!library.Loaded()) {
        dart::Class& klass = dart::Class::Handle(Z);
        for (intptr_t i = 0; i < kernel_library->classes().length(); i++) {
          klass = LookupClass(kernel_library->classes()[i]).raw();
          ClassFinalizer::FinalizeTypesInClass(klass);
          ClassFinalizer::FinalizeClass(klass);
        }
        library.SetLoaded();
      }
    }

    dart::Library& library = LookupLibrary(kernel_main_library);

    // Sanity check that we can find the main entrypoint.
    Object& main_obj = Object::Handle(
        Z, library.LookupObjectAllowPrivate(H.DartSymbol("main")));
    ASSERT(!main_obj.IsNull());
    return library;
  } else {
    // Everything else is a compile-time error. We don't use the [error] since
    // it sometimes causes the higher-level error handling to try to read the
    // script and token position (which we don't have) to produce a nice error
    // message.
    Error& error = Error::Handle(Z);
    error = thread_->sticky_error();
    thread_->clear_sticky_error();

    // Instead we simply make a non-informative error message.
    const dart::String& error_message =
        H.DartString("Failed to read .kernell file => CompileTimeError.");
    return Object::Handle(Z, LanguageError::New(error_message));
  }
}

void KernelReader::ReadLibrary(Library* kernel_library) {
  dart::Library& library = LookupLibrary(kernel_library);
  if (library.Loaded()) return;

  // The bootstrapper will take care of creating the native wrapper classes, but
  // we will add the synthetic constructors to them here.
  if (library.name() ==
      Symbols::Symbol(Symbols::kDartNativeWrappersLibNameId).raw()) {
    ASSERT(library.LoadInProgress());
  } else {
    library.SetLoadInProgress();
  }
  // Setup toplevel class (which contains library fields/procedures).

  // TODO(27590): Figure out why we need this script stuff here.
  Script& script = Script::Handle(
      Z,
      Script::New(H.DartString(""), H.DartString(""), RawScript::kScriptTag));
  script.SetLocationOffset(0, 0);
  script.Tokenize(H.DartString("nop() {}"));
  dart::Class& toplevel_class = dart::Class::Handle(Z, dart::Class::New(
      library, Symbols::TopLevel(), script, TokenPosition::kNoSource));
  toplevel_class.set_is_cycle_free();
  library.set_toplevel_class(toplevel_class);
  if (bootstrapping_) {
    GrowableObjectArray::Handle(Z, I->object_store()->pending_classes())
        .Add(toplevel_class, Heap::kOld);
  }

  ActiveClassScope active_class_scope(&active_class_, NULL, &toplevel_class);
  // Load toplevel fields.
  for (intptr_t i = 0; i < kernel_library->fields().length(); i++) {
    Field* kernel_field = kernel_library->fields()[i];

    ActiveMemberScope active_member_scope(&active_class_, kernel_field);
    const dart::String& name = H.DartFieldName(kernel_field->name());
    dart::Field& field = dart::Field::Handle(
        Z, dart::Field::NewTopLevel(name, kernel_field->IsFinal(),
                                    kernel_field->IsConst(), toplevel_class,
                                    TokenPosition::kNoSource));
    field.set_kernel_field(kernel_field);
    const AbstractType& type = T.TranslateType(kernel_field->type());
    field.SetFieldType(type);
    field.set_has_initializer(kernel_field->initializer() != NULL);
    GenerateFieldAccessors(toplevel_class, field, kernel_field);
    toplevel_class.AddField(field);
    library.AddObject(field, name);
  }

  // Load toplevel procedures.
  for (intptr_t i = 0; i < kernel_library->procedures().length(); i++) {
    Procedure* kernel_procedure = kernel_library->procedures()[i];
    ReadProcedure(library, toplevel_class, kernel_procedure);
  }

  // Load all classes.
  for (intptr_t i = 0; i < kernel_library->classes().length(); i++) {
    Class* kernel_klass = kernel_library->classes()[i];
    ReadClass(library, kernel_klass);
  }
}

void KernelReader::ReadPreliminaryClass(dart::Class* klass,
                                        Class* kernel_klass) {
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
      // There is no dynamic bound, only Object.
      // TODO(27590): Should we fix this in the kernel IR generator?
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

  if (kernel_klass->IsNormalClass()) {
    NormalClass* kernel_normal_class = NormalClass::Cast(kernel_klass);

    // Set super type.  Some classes (e.g., Object) do not have one.
    if (kernel_normal_class->super_class() != NULL) {
      AbstractType& super_type = T.TranslateTypeWithoutFinalization(
          kernel_normal_class->super_class());
      if (super_type.IsMalformed()) H.ReportError("Malformed super type");
      klass->set_super_type(super_type);
    }
  } else {
    MixinClass* kernel_mixin = MixinClass::Cast(kernel_klass);

    // Set super type.
    AbstractType& super_type =
        T.TranslateTypeWithoutFinalization(kernel_mixin->first());
    if (super_type.IsMalformed()) H.ReportError("Malformed super type.");
    klass->set_super_type(super_type);

    // Tell the rest of the system there is nothing to resolve.
    super_type.SetIsResolved();

    // Set mixin type.
    AbstractType& mixin_type =
        T.TranslateTypeWithoutFinalization(kernel_mixin->second());
    if (mixin_type.IsMalformed()) H.ReportError("Malformed mixin type.");
    klass->set_mixin(Type::Cast(mixin_type));
  }

  // Build implemented interface types
  intptr_t interface_count = kernel_klass->implemented_classes().length();
  const dart::Array& interfaces =
      dart::Array::Handle(Z, dart::Array::New(interface_count));
  dart::Class& interface_class = dart::Class::Handle(Z);
  for (intptr_t i = 0; i < interface_count; i++) {
    InterfaceType* kernel_interface_type =
        kernel_klass->implemented_classes()[i];
    const AbstractType& type =
        T.TranslateTypeWithoutFinalization(kernel_interface_type);
    if (type.IsMalformed()) H.ReportError("Malformed interface type.");
    interfaces.SetAt(i, type);

    // NOTE: Normally the DartVM keeps a list of pending classes and iterates
    // through them later on using `ClassFinalizer::ProcessPendingClasses()`.
    // This involes calling `ClassFinalizer::ResolveSuperTypeAndInterfaces()`
    // which does a lot of error validation (e.g. cycle checks) which we don't
    // need here.  But we do need to do one thing which this resolving phase
    // normally does for us: set the `is_implemented` boolean.

    // TODO(27590): Maybe we can do this differently once we have
    // "bootstrapping from kernel"-support.
    interface_class = type.type_class();
    interface_class.set_is_implemented();
  }
  klass->set_interfaces(interfaces);
  if (kernel_klass->is_abstract()) klass->set_is_abstract();
  klass->set_is_cycle_free();

  // When bootstrapping we should not finalize types yet because they will be
  // finalized when the object store's pending_classes list is drained by
  // ClassFinalizer::ProcessPendingClasses.  Even when not bootstrapping we are
  // careful not to eagerly finalize types that may introduce a circularity
  // (such as type arguments, interface types, field types, etc.).
  if (finalize_) ClassFinalizer::FinalizeTypesInClass(*klass);
}

void KernelReader::ReadClass(const dart::Library& library,
                             Class* kernel_klass) {
  // This will trigger a call to [ReadPreliminaryClass] if not already done.
  dart::Class& klass = LookupClass(kernel_klass);

  ActiveClassScope active_class_scope(&active_class_, kernel_klass, &klass);

  TokenPosition pos(0);

  for (intptr_t i = 0; i < kernel_klass->fields().length(); i++) {
    Field* kernel_field = kernel_klass->fields()[i];
    ActiveMemberScope active_member_scope(&active_class_, kernel_field);

    const dart::String& name = H.DartFieldName(kernel_field->name());
    const AbstractType& type =
        T.TranslateTypeWithoutFinalization(kernel_field->type());
    dart::Field& field = dart::Field::Handle(
        Z, dart::Field::New(name, kernel_field->IsStatic(),
                            // In the VM all const fields are implicitly final
                            // whereas in Kernel they are not final because they
                            // are not explicitly declared that way.
                            kernel_field->IsFinal() || kernel_field->IsConst(),
                            kernel_field->IsConst(),
                            false,  // is_reflectable
                            klass, type, pos));
    field.set_kernel_field(kernel_field);
    field.set_has_initializer(kernel_field->initializer() != NULL);
    GenerateFieldAccessors(klass, field, kernel_field);
    klass.AddField(field);
  }

  for (intptr_t i = 0; i < kernel_klass->constructors().length(); i++) {
    Constructor* kernel_constructor = kernel_klass->constructors()[i];
    ActiveMemberScope active_member_scope(&active_class_, kernel_constructor);
    ActiveFunctionScope active_function_scope(&active_class_,
                                              kernel_constructor->function());

    const dart::String& name = H.DartConstructorName(kernel_constructor);
    Function& function = dart::Function::ZoneHandle(
        Z, dart::Function::New(name, RawFunction::kConstructor,
                               false,  // is_static
                               kernel_constructor->IsConst(),
                               false,  // is_abstract
                               kernel_constructor->IsExternal(),
                               false,  // is_native
                               klass, pos));
    klass.AddFunction(function);
    function.set_kernel_function(kernel_constructor);
    function.set_result_type(T.ReceiverType(klass));
    SetupFunctionParameters(H, T, klass, function,
                            kernel_constructor->function(),
                            true,    // is_method
                            false);  // is_closure
  }

  for (intptr_t i = 0; i < kernel_klass->procedures().length(); i++) {
    Procedure* kernel_procedure = kernel_klass->procedures()[i];
    ActiveMemberScope active_member_scope(&active_class_, kernel_procedure);
    ReadProcedure(library, klass, kernel_procedure, kernel_klass);
  }

  if (bootstrapping_ && !klass.is_marked_for_parsing()) {
    klass.set_is_marked_for_parsing();
    GrowableObjectArray::Handle(Z, I->object_store()->pending_classes())
        .Add(klass, Heap::kOld);
  }
}

void KernelReader::ReadProcedure(const dart::Library& library,
                                 const dart::Class& owner,
                                 Procedure* kernel_procedure,
                                 Class* kernel_klass) {
  ActiveClassScope active_class_scope(&active_class_, kernel_klass, &owner);
  ActiveMemberScope active_member_scope(&active_class_, kernel_procedure);
  ActiveFunctionScope active_function_scope(&active_class_,
                                            kernel_procedure->function());

  const dart::String& name = H.DartProcedureName(kernel_procedure);
  TokenPosition pos(0);
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
      Class* annotation_class = Class::Cast(invocation->target()->parent());
      String* class_name = annotation_class->name();
      // Just compare by name, do not generate the annotation class.
      int length = sizeof("ExternalName") - 1;
      if (class_name->size() != length) continue;
      if (memcmp(class_name->buffer(), "ExternalName", length) != 0) continue;
      String* library_name = annotation_class->parent()->name();
      length = sizeof("dart._internal") - 1;
      if (library_name->size() != length) continue;
      if (memcmp(library_name->buffer(), "dart._internal", length) != 0) {
        continue;
      }

      is_external = false;
      ASSERT(invocation->arguments()->positional().length() == 1 &&
             invocation->arguments()->named().length() == 0);
      StringLiteral* literal =
          StringLiteral::Cast(invocation->arguments()->positional()[0]);
      native_name = &H.DartSymbol(literal->value());
      break;
    }
  }
  dart::Function& function = dart::Function::ZoneHandle(
      Z, Function::New(name, GetFunctionType(kernel_procedure),
                       !is_method,  // is_static
                       false,       // is_const
                       is_abstract, is_external,
                       native_name != NULL,  // is_native
                       owner, pos));
  owner.AddFunction(function);
  function.set_kernel_function(kernel_procedure);
  function.set_is_debuggable(false);
  if (native_name != NULL) {
    function.set_native_name(*native_name);
  }

  SetupFunctionParameters(H, T, owner, function, kernel_procedure->function(),
                          is_method,
                          false);  // is_closure

  if (kernel_klass == NULL) {
    library.AddObject(function, name);
    ASSERT(!Object::Handle(Z, library.LookupObjectAllowPrivate(
                                  H.DartProcedureName(kernel_procedure)))
                .IsNull());
  }
}

void KernelReader::GenerateFieldAccessors(const dart::Class& klass,
                                          const dart::Field& field,
                                          Field* kernel_field) {
  TokenPosition pos(0);

  if (kernel_field->IsStatic() && kernel_field->initializer() != NULL) {
    // Static fields with initializers either have the static value set to the
    // initializer value if it is simple enough or else set to an uninitialized
    // sentinel.
    SimpleExpressionConverter converter(H.thread(), Z);
    if (converter.IsSimple(kernel_field->initializer())) {
      // We do not need a getter.
      field.SetStaticValue(converter.SimpleValue(), true);
      return;
    }
    // We do need a getter that evaluates the initializer if necessary.
    field.SetStaticValue(Object::sentinel(), true);
  }

  const dart::String& getter_name = H.DartGetterName(kernel_field->name());
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
          klass, pos));
  klass.AddFunction(getter);
  if (klass.IsTopLevel()) {
    dart::Library& library = dart::Library::Handle(Z, klass.library());
    library.AddObject(getter, getter_name);
  }
  getter.set_kernel_function(kernel_field);
  getter.set_result_type(AbstractType::Handle(Z, field.type()));
  getter.set_is_debuggable(false);
  SetupFieldAccessorFunction(klass, getter);

  if (!kernel_field->IsStatic() && !kernel_field->IsFinal()) {
    // Only static fields can be const.
    ASSERT(!kernel_field->IsConst());
    const dart::String& setter_name = H.DartSetterName(kernel_field->name());
    Function& setter = Function::ZoneHandle(
        Z, Function::New(setter_name, RawFunction::kImplicitSetter,
                         false,  // is_static
                         false,  // is_const
                         false,  // is_abstract
                         false,  // is_external
                         false,  // is_native
                         klass, pos));
    klass.AddFunction(setter);
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
                                           FunctionNode* node, bool is_method,
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
    const AbstractType& type =
        type_translator.TranslateType(kernel_variable->type());
    function.SetParameterTypeAt(
        pos, type.IsMalformed() ? Type::dynamic_type() : type);
    function.SetParameterNameAt(
        pos, translation_helper.DartSymbol(kernel_variable->name()));
  }
  for (intptr_t i = 0; i < node->named_parameters().length(); i++, pos++) {
    VariableDeclaration* named_expression = node->named_parameters()[i];
    const AbstractType& type =
        type_translator.TranslateType(named_expression->type());
    function.SetParameterTypeAt(
        pos, type.IsMalformed() ? Type::dynamic_type() : type);
    function.SetParameterNameAt(
        pos, translation_helper.DartSymbol(named_expression->name()));
  }

  const AbstractType& return_type =
      type_translator.TranslateType(node->return_type());
  function.set_result_type(return_type.IsMalformed() ? Type::dynamic_type()
                                                     : return_type);
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

dart::Library& KernelReader::LookupLibrary(Library* library) {
  dart::Library* handle = NULL;
  if (!libraries_.Lookup(library, &handle)) {
    const dart::String& url = H.DartSymbol(library->import_uri());
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

dart::Class& KernelReader::LookupClass(Class* klass) {
  dart::Class* handle = NULL;
  if (!classes_.Lookup(klass, &handle)) {
    dart::Library& library = LookupLibrary(klass->parent());
    const dart::String& name = H.DartClassName(klass);
    handle = &dart::Class::Handle(Z, library.LookupClass(name));
    if (handle->IsNull()) {
      // The class needs to have a script because all the functions in the class
      // will inherit it.  The predicate Function::IsOptimizable uses the
      // absence of a script to detect test functions that should not be
      // optimized.  Use a dummy script.
      //
      // TODO(27590): We shouldn't need a dummy script per class.  At the
      // least we could have a singleton.  At best, we'd change IsOptimizable to
      // detect test functions some other way (like simply not setting the
      // optimizable bit on those functions in the first place).
      TokenPosition pos(0);
      Script& script =
          Script::Handle(Z, Script::New(H.DartString(""), H.DartString(""),
                                        RawScript::kScriptTag));
      handle =
          &dart::Class::Handle(Z, dart::Class::New(library, name, script, pos));
      library.AddClass(*handle);
    } else if (handle->script() == Script::null()) {
      // When bootstrapping we can encounter classes that do not yet have a
      // dummy script.
      TokenPosition pos(0);
      Script& script =
          Script::Handle(Z, Script::New(H.DartString(""), H.DartString(""),
                                        RawScript::kScriptTag));
      handle->set_script(script);
    }
    // Insert the class in the cache before calling ReadPreliminaryClass so
    // we do not risk allocating the class again by calling LookupClass
    // recursively from ReadPreliminaryClass for the same class.
    classes_.Insert(klass, handle);
    if (!handle->is_type_finalized()) {
      ReadPreliminaryClass(handle, klass);
    }
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

}  // namespace kernel
}  // namespace dart
