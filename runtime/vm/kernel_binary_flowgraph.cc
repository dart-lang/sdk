// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_binary_flowgraph.h"

#include "vm/longjump.h"
#include "vm/object_store.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()


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
  return dart::AbstractType::ZoneHandle(Z, result_.raw());
}

void StreamingDartTypeTranslator::BuildTypeInternal() {
  Tag tag = builder_->ReadTag();
  switch (tag) {
    case kInvalidType:
      result_ = ClassFinalizer::NewFinalizedMalformedType(
          Error::Handle(Z),  // No previous error.
          dart::Script::Handle(Z, dart::Script::null()),
          TokenPosition::kNoSource, "[InvalidType] in Kernel IR.");
      break;
    case kDynamicType:
      result_ = Object::dynamic_type().raw();
      break;
    case kVoidType:
      result_ = Object::void_type().raw();
      break;
    case kBottomType:
      result_ = dart::Class::Handle(Z, I->object_store()->null_class())
                    .CanonicalType();
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

  dart::Object& klass =
      dart::Object::Handle(Z, H.LookupClassByKernelClass(klass_name));
  result_ = Type::New(klass, type_arguments, TokenPosition::kNoSource);
  if (finalize_) {
    ASSERT(active_class_->klass != NULL);
    result_ = ClassFinalizer::FinalizeType(*active_class_->klass, result_);
  }
}

void StreamingDartTypeTranslator::BuildFunctionType(bool simple) {
  intptr_t list_length = 0;
  intptr_t* type_parameters = NULL;
  if (!simple) {
    list_length =
        builder_->ReadListLength();  // read type_parameters list length
    type_parameters = new intptr_t[list_length];
    for (int i = 0; i < list_length; ++i) {
      type_parameters[i] = builder_->ReaderOffset();
      builder_->SkipStringReference();  // read string index (name).
      builder_->SkipDartType();         // read dart type.
    }
  }

  // The spec describes in section "19.1 Static Types":
  //
  //     Any use of a malformed type gives rise to a static warning. A
  //     malformed type is then interpreted as dynamic by the static type
  //     checker and the runtime unless explicitly specified otherwise.
  //
  // So we convert malformed return/parameter types to `dynamic`.
  TypeParameterScope scope(this, type_parameters, list_length);

  Function& signature_function = Function::ZoneHandle(
      Z, Function::NewSignatureFunction(*active_class_->klass,
                                        TokenPosition::kNoSource));

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
      dart::String& name = H.DartSymbol(builder_->ReadStringReference());
      BuildTypeInternal();  // read named_parameters[i].type.
      if (result_.IsMalformed()) {
        result_ = AbstractType::dynamic_type().raw();
      }
      parameter_types.SetAt(pos, result_);
      parameter_names.SetAt(pos, name);
    }
  }

  BuildTypeInternal();  // read return type.
  if (result_.IsMalformed()) {
    result_ = AbstractType::dynamic_type().raw();
  }
  signature_function.set_result_type(result_);

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

static intptr_t FindTypeParameterIndex(intptr_t* parameters,
                                       intptr_t parameters_count,
                                       intptr_t look_for) {
  for (intptr_t i = 0; i < parameters_count; ++i) {
    if (look_for == parameters[i]) {
      return i;
    }
  }
  return -1;
}

static intptr_t FindTypeParameterIndex(List<TypeParameter>* parameters,
                                       intptr_t look_for) {
  for (intptr_t i = 0; i < parameters->length(); ++i) {
    if (look_for == (*parameters)[i]->kernel_offset()) {
      return i;
    }
  }
  return -1;
}

void StreamingDartTypeTranslator::BuildTypeParameterType() {
  builder_->ReadUInt();                           // read parameter index.
  intptr_t binary_offset = builder_->ReadUInt();  // read binary offset.
  builder_->SkipOptionalDartType();               // read bound.

  if (binary_offset == 0) {
    // TODO(jensj): This doesn't appear to actually happen.
    UNIMPLEMENTED();
    return;
  }

  for (TypeParameterScope* scope = type_parameter_scope_; scope != NULL;
       scope = scope->outer()) {
    const intptr_t index = FindTypeParameterIndex(
        scope->parameters(), scope->parameters_count(), binary_offset);
    if (index >= 0) {
      result_ ^= dart::Type::DynamicType();
      return;
    }
  }

  if ((active_class_->member != NULL) && active_class_->member->IsProcedure()) {
    Procedure* procedure = Procedure::Cast(active_class_->member);
    if ((procedure->function() != NULL) &&
        (procedure->function()->type_parameters().length() > 0)) {
      //
      // WARNING: This is a little hackish:
      //
      // We have a static factory constructor. The kernel IR gives the factory
      // constructor function it's own type parameters (which are equal in name
      // and number to the ones of the enclosing class).
      // I.e.,
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
      const intptr_t index = FindTypeParameterIndex(
          &procedure->function()->type_parameters(), binary_offset);
      if (index >= 0) {
        if (procedure->kind() == Procedure::kFactory) {
          // The index of the type parameter in [parameters] is
          // the same index into the `klass->type_parameters()` array.
          result_ ^= dart::TypeArguments::Handle(
                         Z, active_class_->klass->type_parameters())
                         .TypeAt(index);
        } else {
          result_ ^= dart::Type::DynamicType();
        }
        return;
      }
    }
  }

  ASSERT(active_class_->kernel_class != NULL);
  List<TypeParameter>* parameters =
      &active_class_->kernel_class->type_parameters();
  const intptr_t index = FindTypeParameterIndex(parameters, binary_offset);
  if (index >= 0) {
    // The index of the type parameter in [parameters] is
    // the same index into the `klass->type_parameters()` array.
    result_ ^=
        dart::TypeArguments::Handle(Z, active_class_->klass->type_parameters())
            .TypeAt(index);
    return;
  }

  UNREACHABLE();
}

const TypeArguments& StreamingDartTypeTranslator::BuildTypeArguments(
    intptr_t length) {
  bool only_dynamic = true;
  intptr_t offset = builder_->ReaderOffset();
  for (intptr_t i = 0; i < length; ++i) {
    if (builder_->ReadTag() != kDynamicType) {  // read ith type's tag.
      only_dynamic = false;
      builder_->SetOffset(offset);
      break;
    }
  }
  TypeArguments& type_arguments = TypeArguments::ZoneHandle(Z);
  if (!only_dynamic) {
    type_arguments = TypeArguments::New(length);
    for (intptr_t i = 0; i < length; ++i) {
      BuildTypeInternal();  // read ith type.
      if (!result_.IsDynamicType()) {
        only_dynamic = false;
      }
      if (result_.IsMalformed()) {
        type_arguments = TypeArguments::null();
        return type_arguments;
      }
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
    const dart::Class& receiver_class,
    intptr_t length) {
  const TypeArguments& type_arguments = BuildTypeArguments(length);
  if (type_arguments.IsNull()) return type_arguments;

  // We make a temporary [Type] object and use `ClassFinalizer::FinalizeType` to
  // finalize the argument types.
  // (This can for example make the [type_arguments] vector larger)
  Type& type = Type::Handle(
      Z, Type::New(receiver_class, type_arguments, TokenPosition::kNoSource));
  if (finalize_) {
    type ^=
        ClassFinalizer::FinalizeType(*builder_->active_class()->klass, type);
  }

  const TypeArguments& instantiated_type_arguments =
      TypeArguments::ZoneHandle(Z, type.arguments());
  return instantiated_type_arguments;
}


const Type& StreamingDartTypeTranslator::ReceiverType(
    const dart::Class& klass) {
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
      script_(Script::Handle(
          zone_,
          builder == NULL ? Script::null()
                          : builder_->parsed_function()->function().script())),
      result_(Instance::Handle(zone_)) {}


Instance& StreamingConstantEvaluator::EvaluateExpression(intptr_t offset,
                                                         bool reset_position) {
  if (!GetCachedConstant(offset, &result_)) {
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
      case kStaticGet:
        EvaluateStaticGet();
        break;
      case kMethodInvocation:
        EvaluateMethodInvocation();
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
        UNREACHABLE();
    }

    CacheConstantValue(offset, result_);
    if (reset_position) builder_->SetOffset(original_offset);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}

Instance& StreamingConstantEvaluator::EvaluateListLiteral(intptr_t offset,
                                                          bool reset_position) {
  if (!GetCachedConstant(offset, &result_)) {
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

void StreamingConstantEvaluator::EvaluatePropertyGet() {
  builder_->ReadPosition();  // read position.
  intptr_t expression_offset = builder_->ReaderOffset();
  builder_->SkipExpression();                            // read receiver.
  StringIndex name = builder_->ReadNameAsStringIndex();  // read name.
  // Read unused "interface_target_reference".
  builder_->SkipCanonicalNameReference();

  if (H.StringEquals(name, "length")) {
    EvaluateExpression(expression_offset);
    if (result_.IsString()) {
      const dart::String& str =
          dart::String::Handle(Z, dart::String::RawCast(result_.raw()));
      result_ = Integer::New(str.Length());
    } else {
      H.ReportError(
          "Constant expressions can only call "
          "'length' on string constants.");
    }
  } else {
    UNREACHABLE();
  }
}

void StreamingConstantEvaluator::EvaluateStaticGet() {
  builder_->ReadPosition();  // read position.
  NameIndex target =
      builder_->ReadCanonicalNameReference();  // read target_reference.

  if (H.IsField(target)) {
    const dart::Field& field =
        dart::Field::Handle(Z, H.LookupFieldByKernelField(target));
    if (field.StaticValue() == Object::sentinel().raw() ||
        field.StaticValue() == Object::transition_sentinel().raw()) {
      field.EvaluateInitializer();
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
      closure_function.set_kernel_function(function.kernel_function());
      result_ = closure_function.ImplicitStaticClosure();
      result_ = H.Canonicalize(result_);
    } else if (H.IsGetter(target)) {
      UNIMPLEMENTED();
    } else {
      UNIMPLEMENTED();
    }
  }
}

void StreamingConstantEvaluator::EvaluateMethodInvocation() {
  builder_->ReadPosition();  // read position.
  // This method call wasn't cached, so receiver et al. isn't cached either.
  const dart::Instance& receiver =
      EvaluateExpression(builder_->ReaderOffset(), false);  // read receiver.
  dart::Class& klass = dart::Class::Handle(
      Z, isolate_->class_table()->At(receiver.GetClassId()));
  ASSERT(!klass.IsNull());

  // Search the superclass chain for the selector.
  dart::Function& function = dart::Function::Handle(Z);
  const dart::String& method_name =
      builder_->ReadNameAsMethodName();  // read name.
  while (!klass.IsNull()) {
    function = klass.LookupDynamicFunctionAllowPrivate(method_name);
    if (!function.IsNull()) break;
    klass = klass.SuperClass();
  }

  // The frontend should guarantee that [MethodInvocation]s inside constant
  // expressions are always valid.
  ASSERT(!function.IsNull());

  // Read first parts of arguments: count and list of types.
  intptr_t argument_count = builder_->PeekArgumentsCount();
  // Dart does not support generic methods yet.
  ASSERT(builder_->PeekArgumentsTypeCount() == 0);
  builder_->SkipArgumentsBeforeActualArguments();

  // Run the method and canonicalize the result.
  const Object& result = RunFunction(function, argument_count, &receiver, NULL);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);

  builder_->SkipCanonicalNameReference();  // read "interface_target_reference"
}

void StreamingConstantEvaluator::EvaluateStaticInvocation() {
  builder_->ReadPosition();  // read position.
  NameIndex procedue_reference =
      builder_->ReadCanonicalNameReference();  // read procedure reference.

  const Function& function = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(procedue_reference));
  dart::Class& klass = dart::Class::Handle(Z, function.Owner());

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
  dart::Class& klass = dart::Class::Handle(Z, constructor.Owner());

  intptr_t argument_count =
      builder_->ReadUInt();  // read arguments part #1: arguments count.

  // Build the type arguments vector (if necessary).
  const TypeArguments* type_arguments =
      TranslateTypeArguments(constructor, &klass);  // read argument types.

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
  LogicalExpression::Operator op = static_cast<LogicalExpression::Operator>(
      builder_->ReadByte());  // read operator.
  if (op == LogicalExpression::kAnd) {
    if (left) {
      EvaluateBooleanExpressionHere();  // read right.
    } else {
      builder_->SkipExpression();  // read right.
    }
  } else {
    ASSERT(op == LogicalExpression::kOr);
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
    result_ = dart::String::ConcatAll(strings, Heap::kOld);
    result_ = H.Canonicalize(result_);
  } else {
    // Get string interpolation function.
    const dart::Class& cls = dart::Class::Handle(
        Z, dart::Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    const Function& func = Function::Handle(
        Z, cls.LookupStaticFunction(
               dart::Library::PrivateCoreLibName(Symbols::Interpolate())));
    ASSERT(!func.IsNull());

    // Build argument array to pass to the interpolation function.
    const Array& interpolate_arg = Array::Handle(Z, Array::New(1, Heap::kOld));
    interpolate_arg.SetAt(0, strings);

    // Run and canonicalize.
    const Object& result =
        RunFunction(func, interpolate_arg, Array::null_array());
    result_ = H.Canonicalize(dart::String::Cast(result));
  }
}

void StreamingConstantEvaluator::EvaluateSymbolLiteral() {
  const dart::String& symbol_value = H.DartSymbol(
      builder_->ReadStringReference());  // read index into string table.

  const dart::Class& symbol_class =
      dart::Class::ZoneHandle(Z, I->object_store()->symbol_class());
  ASSERT(!symbol_class.IsNull());
  const dart::Function& symbol_constructor = Function::ZoneHandle(
      Z, symbol_class.LookupConstructor(Symbols::SymbolCtor()));
  ASSERT(!symbol_constructor.IsNull());
  result_ ^= EvaluateConstConstructorCall(
      symbol_class, TypeArguments::Handle(Z), symbol_constructor, symbol_value);
}

void StreamingConstantEvaluator::EvaluateTypeLiteral() {
  const AbstractType& type = T.BuildType();
  if (type.IsMalformed()) {
    H.ReportError("Malformed type literal in constant expression.");
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

  const dart::Class& map_class = dart::Class::Handle(
      Z, dart::Library::LookupCoreClass(Symbols::ImmutableMap()));
  ASSERT(!map_class.IsNull());
  ASSERT(map_class.NumTypeArguments() == 2);

  const dart::Field& field = dart::Field::Handle(
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
  intptr_t kernel_position = builder_->ReaderOffset();
  LocalVariable* local = builder_->LookupVariable(kernel_position);

  // read variable declaration.
  builder_->ReadPosition();         // read position.
  builder_->ReadPosition();         // read equals position.
  builder_->ReadFlags();            // read flags.
  builder_->SkipStringReference();  // read name index.
  builder_->SkipDartType();         // read type.
  Tag tag = builder_->ReadTag();    // read (first part of) initializer.
  if (tag == kNothing) {
    local->SetConstValue(Instance::ZoneHandle(Z, dart::Instance::null()));
  } else {
    local->SetConstValue(EvaluateExpression(
        builder_->ReaderOffset(), false));  // read rest of initializer.
  }

  EvaluateExpression(builder_->ReaderOffset(), false);  // read body
}

void StreamingConstantEvaluator::EvaluateBigIntLiteral() {
  const dart::String& value =
      H.DartString(builder_->ReadStringReference());  // read string reference.
  result_ = Integer::New(value, Heap::kOld);
  result_ = H.Canonicalize(result_);
}

void StreamingConstantEvaluator::EvaluateStringLiteral() {
  result_ = H.DartSymbol(builder_->ReadStringReference())
                .raw();  // read string reference.
}

void StreamingConstantEvaluator::EvaluateIntLiteral(uint8_t payload) {
  int64_t value = static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
  result_ = dart::Integer::New(value, Heap::kOld);
  result_ = H.Canonicalize(result_);
}

void StreamingConstantEvaluator::EvaluateIntLiteral(bool is_negative) {
  int64_t value = is_negative ? -static_cast<int64_t>(builder_->ReadUInt())
                              : builder_->ReadUInt();  // read value.
  result_ = dart::Integer::New(value, Heap::kOld);
  result_ = H.Canonicalize(result_);
}

void StreamingConstantEvaluator::EvaluateDoubleLiteral() {
  result_ = Double::New(H.DartString(builder_->ReadStringReference()),
                        Heap::kOld);  // read string reference.
  result_ = H.Canonicalize(result_);
}

void StreamingConstantEvaluator::EvaluateBoolLiteral(bool value) {
  result_ = dart::Bool::Get(value).raw();
}

void StreamingConstantEvaluator::EvaluateNullLiteral() {
  result_ = dart::Instance::null();
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
    dart::String& name =
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

RawObject* StreamingConstantEvaluator::EvaluateConstConstructorCall(
    const dart::Class& type_class,
    const TypeArguments& type_arguments,
    const Function& constructor,
    const Object& argument) {
  // Factories have one extra argument: the type arguments.
  // Constructors have 1 extra arguments: receiver.
  const int kTypeArgsLen = 0;
  const int kNumArgs = 1;
  const int kNumExtraArgs = 1;
  const int num_arguments = kNumArgs + kNumExtraArgs;
  const Array& arg_values =
      Array::Handle(Z, Array::New(num_arguments, Heap::kOld));
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
      Array::Handle(Z, ArgumentsDescriptor::New(kTypeArgsLen, num_arguments,
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
    dart::Class* target_klass) {
  intptr_t types_count = builder_->ReadListLength();  // read types count.

  const TypeArguments* type_arguments = NULL;
  if (types_count > 0) {
    type_arguments = &T.BuildInstantiatedTypeArguments(
        *target_klass, types_count);  // read types.

    if (!(type_arguments->IsNull() || type_arguments->IsInstantiated())) {
      H.ReportError("Type must be constant in const constructor.");
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
  AssertBoolInCheckedMode();
  return result_.raw() == Bool::True().raw();
}

bool StreamingConstantEvaluator::GetCachedConstant(intptr_t kernel_offset,
                                                   Instance* value) {
  if (builder_ == NULL) return false;

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
  *value ^= constants.GetOrNull(kernel_offset, &is_present);
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

  if (builder_ == NULL) return;

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
  constants.InsertNewOrGetValue(kernel_offset, value);
  script_.set_compile_time_constants(constants.Release());
}


Fragment StreamingFlowGraphBuilder::BuildExpressionAt(intptr_t kernel_offset) {
  SetOffset(kernel_offset);
  return BuildExpression();  // read expression.
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
    case kStaticGet:
      return BuildStaticGet(position);
    case kStaticSet:
      return BuildStaticSet(position);
    case kMethodInvocation:
      return BuildMethodInvocation(position);
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
      // TODO(jensj)
      UNIMPLEMENTED();
      return Fragment();
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
    default:
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
      return BuildVariableDeclaration(true);
    case kFunctionDeclaration:
      // TODO(jensj)
      UNIMPLEMENTED();
      return Fragment();
    default:
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

uint32_t StreamingFlowGraphBuilder::PeekUInt() {
  intptr_t offset = ReaderOffset();
  uint32_t result = reader_->ReadUInt();
  SetOffset(offset);
  return result;
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

const dart::String& StreamingFlowGraphBuilder::ReadNameAsMethodName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartMethodName(library_reference, name_index);
  } else {
    return H.DartMethodName(NameIndex(), name_index);
  }
}

const dart::String& StreamingFlowGraphBuilder::ReadNameAsSetterName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartSetterName(library_reference, name_index);
  } else {
    return H.DartSetterName(NameIndex(), name_index);
  }
}

const dart::String& StreamingFlowGraphBuilder::ReadNameAsGetterName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartGetterName(library_reference, name_index);
  } else {
    return H.DartGetterName(NameIndex(), name_index);
  }
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
      ReadUInt();              // read binary offset.
      SkipOptionalDartType();  // read bound bound.
      return;
    default:
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
    intptr_t length = ReadListLength();  // read number of types.
    for (intptr_t i = 0; i < length; ++i) {
      SkipDartType();  // skip the ith type.
    }
  }
}

void StreamingFlowGraphBuilder::SkipFunctionType(bool simple) {
  if (!simple) {
    intptr_t list_length =
        ReadListLength();  // read type_parameters list length.
    for (int i = 0; i < list_length; ++i) {
      SkipStringReference();  // read string index (name).
      SkipDartType();         // read dart type.
    }
    ReadUInt();  // read required parameter count.
    ReadUInt();  // read total parameter count.
  }

  const intptr_t positional_count =
      ReadListLength();  // read positional_parameters list length.
  for (intptr_t i = 0; i < positional_count; ++i) {
    SkipDartType();  // read ith positional parameter.
  }

  if (!simple) {
    const intptr_t named_count =
        ReadListLength();  // read named_parameters list length.
    for (intptr_t i = 0; i < named_count; ++i) {
      // read string reference (i.e. named_parameters[i].name).
      SkipStringReference();
      SkipDartType();  // read named_parameters[i].type.
    }
  }

  SkipDartType();  // read return type.
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
      ReadPosition();    // read position.
      SkipExpression();  // read receiver.
      SkipName();        // read name.
      // Read unused "interface_target_reference".
      SkipCanonicalNameReference();
      return;
    case kPropertySet:
      ReadPosition();    // read position.
      SkipExpression();  // read receiver.
      SkipName();        // read name.
      SkipExpression();  // read value.
      // read unused "interface_target_reference".
      SkipCanonicalNameReference();
      return;
    case kDirectPropertyGet:
      ReadPosition();                // read position.
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
      ReadPosition();    // read position.
      SkipExpression();  // read receiver.
      SkipName();        // read name.
      SkipArguments();   // read arguments.
      // read unused "interface_target_reference".
      SkipCanonicalNameReference();
      return;
    case kDirectMethodInvocation:
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
    case kStringConcatenation: {
      ReadPosition();                           // read position.
      intptr_t list_length = ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        SkipExpression();  // read ith expression.
      }
      return;
    }
    case kIsExpression:
      ReadPosition();    // read position.
      SkipExpression();  // read operand.
      SkipDartType();    // read type.
      return;
    case kAsExpression:
      ReadPosition();    // read position.
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
    case kConstListLiteral: {
      ReadPosition();                           // read position.
      SkipDartType();                           // read type.
      intptr_t list_length = ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        SkipExpression();  // read ith expression.
      }
      return;
    }
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
      // TODO(jensj)
      UNIMPLEMENTED();
      return;
    case kLet:
      SkipVariableDeclaration();  // read variable declaration.
      SkipExpression();           // read expression.
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
      SkipExpression();  // read condition.
      SkipStatement();   // read body.
      return;
    case kDoStatement:
      SkipStatement();   // read body.
      SkipExpression();  // read condition.
      return;
    case kForStatement: {
      intptr_t list_length = ReadListLength();  // read number of variables.
      for (intptr_t i = 0; i < list_length; ++i) {
        SkipVariableDeclaration();  // read ith variable.
      }
      Tag tag = ReadTag();  // Read first part of condition.
      if (tag == kSomething) {
        SkipExpression();  // read rest of condition.
      }
      list_length = ReadListLength();  // read number of updates.
      for (intptr_t i = 0; i < list_length; ++i) {
        SkipExpression();  // read ith update.
      }
      SkipStatement();  // read body.
      return;
    }
    case kForInStatement:
    case kAsyncForInStatement:
      ReadPosition();             // read position.
      SkipVariableDeclaration();  // read variable.
      SkipExpression();           // read iterable.
      SkipStatement();            // read body.
      return;
    case kSwitchStatement: {
      SkipExpression();                  // read condition.
      int num_cases = ReadListLength();  // read number of cases.
      for (intptr_t i = 0; i < num_cases; ++i) {
        int num_expressions = ReadListLength();  // read number of expressions.
        for (intptr_t j = 0; j < num_expressions; ++j) {
          ReadPosition();    // read jth position.
          SkipExpression();  // read jth expression.
        }
        ReadBool();       // read is_default.
        SkipStatement();  // read body.
      }
      return;
    }
    case kContinueSwitchStatement:
      ReadUInt();  // read target_index.
      return;
    case kIfStatement:
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
      intptr_t num_matches = ReadListLength();  // read number of catches.
      for (intptr_t i = 0; i < num_matches; ++i) {
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
    case kYieldStatement:
      ReadPosition();    // read position.
      ReadByte();        // read flags.
      SkipExpression();  // read expression.
      return;
    case kVariableDeclaration:
      SkipVariableDeclaration();
      return;
    case kFunctionDeclaration:
      // TODO(jensj)
      UNIMPLEMENTED();
      return;
    default:
      UNREACHABLE();
  }
}

void StreamingFlowGraphBuilder::SkipName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    SkipCanonicalNameReference();  // read library index.
  }
}

void StreamingFlowGraphBuilder::SkipArguments() {
  ReadUInt();  // read argument count.

  // List of types.
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipDartType();  // read ith type.
  }

  // List of positional.
  list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipExpression();  // read ith expression.
  }

  // List of named.
  list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipStringReference();  // read ith name index.
    SkipExpression();       // read ith expression.
  }
}

void StreamingFlowGraphBuilder::SkipVariableDeclaration() {
  ReadPosition();         // read position.
  ReadPosition();         // read equals position.
  ReadFlags();            // read flags.
  SkipStringReference();  // read name index.
  SkipDartType();         // read type.
  Tag tag = ReadTag();    // read (first part of) initializer.
  if (tag == kSomething) {
    SkipExpression();  // read (actual) initializer.
  }
}

TokenPosition StreamingFlowGraphBuilder::ReadPosition(bool record) {
  return reader_->ReadPosition(record);
}

Tag StreamingFlowGraphBuilder::ReadTag(uint8_t* payload) {
  return reader_->ReadTag(payload);
}

Tag StreamingFlowGraphBuilder::PeekTag(uint8_t* payload) {
  return reader_->PeekTag(payload);
}

word StreamingFlowGraphBuilder::ReadFlags() {
  return reader_->ReadFlags();
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

Value* StreamingFlowGraphBuilder::Pop() {
  return flow_graph_builder_->Pop();
}

Tag StreamingFlowGraphBuilder::PeekArgumentsFirstPositionalTag() {
  // read parts of arguments, then go back to before doing so.
  intptr_t offset = ReaderOffset();
  ReadUInt();  // read number of arguments.

  // List of types.
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipDartType();  // read ith type.
  }

  // List of positional.
  list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    Tag tag = ReadTag();  // read first tag.
    SetOffset(offset);    // reset offset.
    return tag;
  }

  UNREACHABLE();
  return kNothing;
}

const TypeArguments& StreamingFlowGraphBuilder::PeekArgumentsInstantiatedType(
    const dart::Class& klass) {
  // read parts of arguments, then go back to before doing so.
  intptr_t offset = ReaderOffset();
  ReadUInt();                               // read argument count.
  intptr_t list_length = ReadListLength();  // read types list length.
  const TypeArguments& type_arguments =
      T.BuildInstantiatedTypeArguments(klass, list_length);  // read types.
  SetOffset(offset);
  return type_arguments;
}

intptr_t StreamingFlowGraphBuilder::PeekArgumentsCount() {
  return PeekUInt();
}

intptr_t StreamingFlowGraphBuilder::PeekArgumentsTypeCount() {
  intptr_t offset = ReaderOffset();
  ReadUInt();                               // read arguments count.
  intptr_t types_count = ReadListLength();  // read length of types list.
  SetOffset(offset);
  return types_count;
}

void StreamingFlowGraphBuilder::SkipArgumentsBeforeActualArguments() {
  ReadUInt();  // read arguments count.
  intptr_t types_count = ReadListLength();
  for (intptr_t i = 0; i < types_count; ++i) {
    SkipDartType();  // read ith type.
  }
}

LocalVariable* StreamingFlowGraphBuilder::LookupVariable(
    intptr_t kernel_offset) {
  return flow_graph_builder_->LookupVariable(kernel_offset);
}

LocalVariable* StreamingFlowGraphBuilder::MakeTemporary() {
  return flow_graph_builder_->MakeTemporary();
}

Token::Kind StreamingFlowGraphBuilder::MethodKind(const dart::String& name) {
  return flow_graph_builder_->MethodKind(name);
}

dart::RawFunction* StreamingFlowGraphBuilder::LookupMethodByMember(
    NameIndex target,
    const dart::String& method_name) {
  return flow_graph_builder_->LookupMethodByMember(target, method_name);
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

Fragment StreamingFlowGraphBuilder::StaticCall(TokenPosition position,
                                               const Function& target,
                                               intptr_t argument_count) {
  return flow_graph_builder_->StaticCall(position, target, argument_count);
}

Fragment StreamingFlowGraphBuilder::StaticCall(TokenPosition position,
                                               const Function& target,
                                               intptr_t argument_count,
                                               const Array& argument_names) {
  return flow_graph_builder_->StaticCall(position, target, argument_count,
                                         argument_names);
}

Fragment StreamingFlowGraphBuilder::InstanceCall(TokenPosition position,
                                                 const dart::String& name,
                                                 Token::Kind kind,
                                                 intptr_t argument_count,
                                                 intptr_t num_args_checked) {
  return flow_graph_builder_->InstanceCall(position, name, kind, argument_count,
                                           num_args_checked);
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

Fragment StreamingFlowGraphBuilder::AllocateObject(const dart::Class& klass,
                                                   intptr_t argument_count) {
  return flow_graph_builder_->AllocateObject(klass, argument_count);
}

Fragment StreamingFlowGraphBuilder::InstanceCall(TokenPosition position,
                                                 const dart::String& name,
                                                 Token::Kind kind,
                                                 intptr_t argument_count,
                                                 const Array& argument_names,
                                                 intptr_t num_args_checked) {
  return flow_graph_builder_->InstanceCall(position, name, kind, argument_count,
                                           argument_names, num_args_checked);
}

Fragment StreamingFlowGraphBuilder::StoreLocal(TokenPosition position,
                                               LocalVariable* variable) {
  return flow_graph_builder_->StoreLocal(position, variable);
}

Fragment StreamingFlowGraphBuilder::StoreStaticField(TokenPosition position,
                                                     const dart::Field& field) {
  return flow_graph_builder_->StoreStaticField(position, field);
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

Fragment StreamingFlowGraphBuilder::CloneContext() {
  return flow_graph_builder_->CloneContext();
}

Fragment StreamingFlowGraphBuilder::TranslateFinallyFinalizers(
    TryFinallyBlock* outer_finally,
    intptr_t target_context_depth) {
  // TranslateFinallyFinalizers can move the readers offset.
  // Save the current position and restore it afterwards.
  intptr_t offset = ReaderOffset();
  Fragment result = flow_graph_builder_->TranslateFinallyFinalizers(
      outer_finally, target_context_depth);
  SetOffset(offset);
  return result;
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
    const dart::AbstractType& dst_type,
    const dart::String& dst_name) {
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
    const dart::String& name_symbol) {
  return flow_graph_builder_->CheckVariableTypeInCheckedMode(dst_type,
                                                             name_symbol);
}

Fragment StreamingFlowGraphBuilder::EnterScope(intptr_t kernel_offset,
                                               bool* new_context) {
  return flow_graph_builder_->EnterScope(kernel_offset, new_context);
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
  ReadUInt();                                // read arguments count.
  intptr_t types_count = ReadListLength();   // read type count.
  return T.BuildTypeArguments(types_count);  // read types.
}

Fragment StreamingFlowGraphBuilder::BuildArguments(Array* argument_names,
                                                   intptr_t* argument_count,
                                                   bool skip_push_arguments,
                                                   bool do_drop) {
  intptr_t dummy;
  if (argument_count == NULL) argument_count = &dummy;
  *argument_count = ReadUInt();  // read arguments count.

  // List of types.
  intptr_t list_length = ReadListLength();  // read type count.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipDartType();  // read ith type.
  }

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
    dart::String& name =
        H.DartSymbol(ReadStringReference());  // read ith name index.
    instructions += BuildExpression();        // read ith expression.
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
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions = BuildExpression();  // read receiver.
  instructions += PushArgument();

  const dart::String& getter_name = ReadNameAsGetterName();  // read name.
  SkipCanonicalNameReference();  // Read unused "interface_target_reference".

  return instructions + InstanceCall(position, getter_name, Token::kGET, 1);
}

Fragment StreamingFlowGraphBuilder::BuildPropertySet(TokenPosition* p) {
  Fragment instructions(NullConstant());
  LocalVariable* variable = MakeTemporary();

  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  instructions += BuildExpression();  // read receiver.
  instructions += PushArgument();

  const dart::String& setter_name = ReadNameAsSetterName();  // read name.

  instructions += BuildExpression();  // read value.
  instructions += StoreLocal(TokenPosition::kNoSource, variable);
  instructions += PushArgument();

  SkipCanonicalNameReference();  // read unused "interface_target_reference".

  instructions += InstanceCall(position, setter_name, Token::kSET, 2);
  return instructions + Drop();
}

Fragment StreamingFlowGraphBuilder::BuildDirectPropertyGet(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions = BuildExpression();  // read receiver.
  NameIndex kernel_name =
      ReadCanonicalNameReference();  // read target_reference.

  Function& target = Function::ZoneHandle(Z);
  if (H.IsProcedure(kernel_name)) {
    if (H.IsGetter(kernel_name)) {
      target = LookupMethodByMember(kernel_name, H.DartGetterName(kernel_name));
    } else {
      // Undo stack change for the BuildExpression.
      Pop();

      target = LookupMethodByMember(kernel_name, H.DartMethodName(kernel_name));
      target = target.ImplicitClosureFunction();
      ASSERT(!target.IsNull());
      return BuildImplicitClosureCreation(target);
    }
  } else {
    ASSERT(H.IsField(kernel_name));
    const dart::String& getter_name = H.DartGetterName(kernel_name);
    target = LookupMethodByMember(kernel_name, getter_name);
    ASSERT(target.IsGetterFunction() || target.IsImplicitGetterFunction());
  }

  instructions += PushArgument();
  return instructions + StaticCall(position, target, 1);
}

Fragment StreamingFlowGraphBuilder::BuildDirectPropertySet(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Fragment instructions(NullConstant());
  LocalVariable* value = MakeTemporary();

  instructions += BuildExpression();  // read receiver.
  instructions += PushArgument();

  NameIndex target_reference =
      ReadCanonicalNameReference();  // read target_reference.
  const dart::String& method_name = H.DartSetterName(target_reference);
  const Function& target = Function::ZoneHandle(
      Z, LookupMethodByMember(target_reference, method_name));
  ASSERT(target.IsSetterFunction() || target.IsImplicitSetterFunction());

  instructions += BuildExpression();  // read value.
  instructions += StoreLocal(TokenPosition::kNoSource, value);
  instructions += PushArgument();

  instructions += StaticCall(position, target, 2);

  return instructions + Drop();
}

Fragment StreamingFlowGraphBuilder::BuildStaticGet(TokenPosition* p) {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  NameIndex target = ReadCanonicalNameReference();  // read target_reference.

  if (H.IsField(target)) {
    const dart::Field& field =
        dart::Field::ZoneHandle(Z, H.LookupFieldByKernelField(target));
    if (field.is_const()) {
      return Constant(constant_evaluator_.EvaluateExpression(offset));
    } else {
      const dart::Class& owner = dart::Class::Handle(Z, field.Owner());
      const dart::String& getter_name = H.DartGetterName(target);
      const Function& getter =
          Function::ZoneHandle(Z, owner.LookupStaticFunction(getter_name));
      if (getter.IsNull() || !field.has_initializer()) {
        Fragment instructions = Constant(field);
        return instructions + LoadStaticField();
      } else {
        return StaticCall(position, getter, 0);
      }
    }
  } else {
    const Function& function =
        Function::ZoneHandle(Z, H.LookupStaticMethodByKernelProcedure(target));

    if (H.IsGetter(target)) {
      return StaticCall(position, function, 0);
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
    const dart::Field& field =
        dart::Field::ZoneHandle(Z, H.LookupFieldByKernelField(target));
    const AbstractType& dst_type = AbstractType::ZoneHandle(Z, field.type());
    Fragment instructions = BuildExpression();  // read expression.
    if (NeedsDebugStepCheck(stack(), position)) {
      instructions = DebugStepCheck(position) + instructions;
    }
    instructions += CheckAssignableInCheckedMode(
        dst_type, dart::String::ZoneHandle(Z, field.name()));
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
    instructions += StaticCall(position, function, 1);

    // Drop the unused result & leave the stored value on the stack.
    return instructions + Drop();
  }
}

static bool IsNumberLiteral(Tag tag) {
  return tag == kNegativeIntLiteral || tag == kPositiveIntLiteral ||
         tag == kSpecialIntLiteral || tag == kDoubleLiteral;
}

Fragment StreamingFlowGraphBuilder::BuildMethodInvocation(TokenPosition* p) {
  intptr_t offset = ReaderOffset() - 1;     // Include the tag.
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  Tag receiver_tag = PeekTag();  // peek tag for receiver.
  if (IsNumberLiteral(receiver_tag)) {
    intptr_t before_branch_offset = ReaderOffset();

    SkipExpression();  // read receiver (it's just a number literal).

    const dart::String& name = ReadNameAsMethodName();  // read name.
    const Token::Kind token_kind = MethodKind(name);
    intptr_t argument_count = PeekArgumentsCount() + 1;

    if ((argument_count == 1) && (token_kind == Token::kNEGATE)) {
      const Object& result = constant_evaluator_.EvaluateExpressionSafe(offset);
      if (!result.IsError()) {
        SkipArguments();  // read arguments,
        // read unused "interface_target_reference".
        SkipCanonicalNameReference();
        return Constant(result);
      }
    } else if ((argument_count == 2) &&
               Token::IsBinaryArithmeticOperator(token_kind) &&
               IsNumberLiteral(PeekArgumentsFirstPositionalTag())) {
      const Object& result = constant_evaluator_.EvaluateExpressionSafe(offset);
      if (!result.IsError()) {
        SkipArguments();
        // read unused "interface_target_reference".
        SkipCanonicalNameReference();
        return Constant(result);
      }
    }

    SetOffset(before_branch_offset);
  }

  Fragment instructions = BuildExpression();  // read receiver.

  const dart::String& name = ReadNameAsMethodName();  // read name.
  const Token::Kind token_kind = MethodKind(name);

  // Detect comparison with null.
  if ((token_kind == Token::kEQ || token_kind == Token::kNE) &&
      PeekArgumentsCount() == 1 &&
      (receiver_tag == kNullLiteral ||
       PeekArgumentsFirstPositionalTag() == kNullLiteral)) {
    // "==" or "!=" with null on either side.
    instructions += BuildArguments(NULL, NULL, true);  // read arguments.
    SkipCanonicalNameReference();  // read unused "interface_target_reference".
    Token::Kind strict_cmp_kind =
        token_kind == Token::kEQ ? Token::kEQ_STRICT : Token::kNE_STRICT;
    return instructions +
           StrictCompare(strict_cmp_kind, /*number_check = */ true);
  }

  instructions += PushArgument();  // push receiver as argument.

  // TODO(28109) Support generic methods in the VM or reify them away.
  Array& argument_names = Array::ZoneHandle(Z);
  intptr_t argument_count;
  instructions +=
      BuildArguments(&argument_names, &argument_count);  // read arguments.
  ++argument_count;

  intptr_t num_args_checked = 1;
  // If we have a special operation (e.g. +/-/==) we mark both arguments as
  // to be checked.
  if (token_kind != Token::kILLEGAL) {
    ASSERT(argument_count <= 2);
    num_args_checked = argument_count;
  }

  instructions += InstanceCall(position, name, token_kind, argument_count,
                               argument_names, num_args_checked);
  // Later optimization passes assume that result of a x.[]=(...) call is not
  // used. We must guarantee this invariant because violation will lead to an
  // illegal IL once we replace x.[]=(...) with a sequence that does not
  // actually produce any value. See http://dartbug.com/29135 for more details.
  if (name.raw() == Symbols::AssignIndexToken().raw()) {
    instructions += Drop();
    instructions += NullConstant();
  }

  SkipCanonicalNameReference();  // read unused "interface_target_reference".

  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildDirectMethodInvocation(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  // TODO(28109) Support generic methods in the VM or reify them away.
  Tag receiver_tag = PeekTag();               // peek tag for receiver.
  Fragment instructions = BuildExpression();  // read receiver.

  NameIndex kernel_name =
      ReadCanonicalNameReference();  // read target_reference.
  const dart::String& method_name = H.DartProcedureName(kernel_name);
  const Token::Kind token_kind = MethodKind(method_name);

  // Detect comparison with null.
  if ((token_kind == Token::kEQ || token_kind == Token::kNE) &&
      PeekArgumentsCount() == 1 &&
      (receiver_tag == kNullLiteral ||
       PeekArgumentsFirstPositionalTag() == kNullLiteral)) {
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
  return instructions + StaticCall(TokenPosition::kNoSource, target,
                                   argument_count, argument_names);
}

Fragment StreamingFlowGraphBuilder::BuildStaticInvocation(bool is_const,
                                                          TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

  NameIndex procedue_reference =
      ReadCanonicalNameReference();  // read procedure reference.
  intptr_t argument_count = PeekArgumentsCount();
  const Function& target = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(procedue_reference));
  const dart::Class& klass = dart::Class::ZoneHandle(Z, target.Owner());
  if (target.IsGenerativeConstructor() || target.IsFactory()) {
    // The VM requires a TypeArguments object as first parameter for
    // every factory constructor.
    ++argument_count;
  }

  Fragment instructions;
  LocalVariable* instance_variable = NULL;

  // If we cross the Kernel -> VM core library boundary, a [StaticInvocation]
  // can appear, but the thing we're calling is not a static method, but a
  // factory constructor.
  // The `H.LookupStaticmethodByKernelProcedure` will potentially resolve to the
  // forwarded constructor.
  // In that case we'll make an instance and pass it as first argument.
  //
  // TODO(27590): Get rid of this after we're using core libraries compiled
  // into Kernel.
  if (target.IsGenerativeConstructor()) {
    if (klass.NumTypeArguments() > 0) {
      const TypeArguments& type_arguments =
          PeekArgumentsInstantiatedType(klass);
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      instructions += PushArgument();
      instructions += AllocateObject(klass, 1);
    } else {
      instructions += AllocateObject(klass, 0);
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
  } else {
    // TODO(28109) Support generic methods in the VM or reify them away.
  }

  bool special_case_identical =
      klass.IsTopLevel() && (klass.library() == dart::Library::CoreLibrary()) &&
      (target.name() == Symbols::Identical().raw());

  Array& argument_names = Array::ZoneHandle(Z);
  instructions += BuildArguments(&argument_names, NULL,
                                 special_case_identical);  // read arguments.
  const int kTypeArgsLen = 0;
  ASSERT(target.AreValidArguments(kTypeArgsLen, argument_count, argument_names,
                                  NULL));

  // Special case identical(x, y) call.
  // TODO(27590) consider moving this into the inliner and force inline it
  // there.
  if (special_case_identical) {
    ASSERT(argument_count == 2);
    instructions += StrictCompare(Token::kEQ_STRICT, /*number_check=*/true);
  } else {
    instructions +=
        StaticCall(position, target, argument_count, argument_names);
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

  dart::Class& klass = dart::Class::ZoneHandle(
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
    const TypeArguments& type_arguments = PeekArgumentsInstantiatedType(klass);
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
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
    }

    instructions += PushArgument();
    instructions += AllocateObject(klass, 1);
  } else {
    instructions += AllocateObject(klass, 0);
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
  instructions += StaticCall(position, target, argument_count, argument_names);
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
  LogicalExpression::Operator op =
      static_cast<LogicalExpression::Operator>(ReadByte());

  if (op == LogicalExpression::kAnd) {
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
  constant_fragment += Constant(Bool::Get(op == LogicalExpression::kOr));
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
      instructions += InstanceCall(position, dart::Library::PrivateCoreLibName(
                                                 Symbols::_simpleInstanceOf()),
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
        position, dart::Library::PrivateCoreLibName(Symbols::_instanceOf()),
        Token::kIS, 4);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildAsExpression(TokenPosition* p) {
  TokenPosition position = ReadPosition();  // read position.
  if (p != NULL) *p = position;

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
        position, dart::Library::PrivateCoreLibName(Symbols::_as()), Token::kAS,
        4);
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
  }
  instructions += PushArgument();  // The array.

  const dart::Class& factory_class =
      dart::Class::Handle(Z, dart::Library::LookupCoreClass(Symbols::List()));
  const Function& factory_method = Function::ZoneHandle(
      Z, factory_class.LookupFactory(
             dart::Library::PrivateCoreLibName(Symbols::ListLiteralFactory())));

  return instructions + StaticCall(position, factory_method, 2);
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


  const dart::Class& map_class =
      dart::Class::Handle(Z, dart::Library::LookupCoreClass(Symbols::Map()));
  const Function& factory_method = Function::ZoneHandle(
      Z, map_class.LookupFactory(
             dart::Library::PrivateCoreLibName(Symbols::MapLiteralFactory())));

  return instructions + StaticCall(position, factory_method, 2);
}

Fragment StreamingFlowGraphBuilder::BuildLet(TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  Fragment instructions = BuildVariableDeclaration(false);  // read variable.
  instructions += BuildExpression();                        // read body.
  return instructions;
}


Fragment StreamingFlowGraphBuilder::BuildBigIntLiteral(
    TokenPosition* position) {
  if (position != NULL) *position = TokenPosition::kNoSource;

  const dart::String& value =
      H.DartString(ReadStringReference());  // read index into string table.
  return Constant(Integer::ZoneHandle(Z, Integer::New(value, Heap::kOld)));
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
    intptr_t offset = ReaderOffset() - 1;  // Include the tag.
    SetOffset(offset);
    SkipStatement();  // read this statement.
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

  const dart::Class& klass = dart::Class::ZoneHandle(
      Z, dart::Library::LookupCoreClass(Symbols::AssertionError()));
  ASSERT(!klass.IsNull());
  const dart::Function& constructor = dart::Function::ZoneHandle(
      Z, klass.LookupConstructorAllowPrivate(
             H.DartSymbol("_AssertionError._create")));
  ASSERT(!constructor.IsNull());

  const dart::String& url = H.DartString(
      parsed_function()->function().ToLibNamePrefixedQualifiedCString(),
      Heap::kOld);

  // Create instance of _AssertionError
  Fragment otherwise_fragment(otherwise);
  otherwise_fragment += AllocateObject(klass, 0);
  LocalVariable* instance = MakeTemporary();

  // Call _AssertionError._create constructor.
  otherwise_fragment += LoadLocal(instance);
  otherwise_fragment += PushArgument();  // this

  otherwise_fragment += Constant(H.DartString("<no message>", Heap::kOld));
  otherwise_fragment += PushArgument();  // failedAssertion

  otherwise_fragment += Constant(url);
  otherwise_fragment += PushArgument();  // url

  otherwise_fragment += IntConstant(0);
  otherwise_fragment += PushArgument();  // line

  otherwise_fragment += IntConstant(0);
  otherwise_fragment += PushArgument();  // column

  Tag tag = ReadTag();  // read (first part of) message.
  if (tag == kSomething) {
    otherwise_fragment += BuildExpression();  // read (rest of) message.
  } else {
    otherwise_fragment += Constant(H.DartString("<no message>", Heap::kOld));
  }
  otherwise_fragment += PushArgument();  // message

  otherwise_fragment += StaticCall(TokenPosition::kNoSource, constructor, 6);
  otherwise_fragment += Drop();

  // Throw _AssertionError exception.
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
    entry = new (Z) GotoInstr(join);
  } else {
    entry = condition.entry;
  }


  loop_depth_dec();
  return Fragment(entry, loop_exit);
}

Fragment StreamingFlowGraphBuilder::BuildDoStatement() {
  loop_depth_inc();
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
  return Fragment(new (Z) GotoInstr(join), loop_exit);
}

Fragment StreamingFlowGraphBuilder::BuildForStatement() {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  Fragment declarations;

  bool new_context = false;
  declarations += EnterScope(offset, &new_context);

  intptr_t list_length = ReadListLength();  // read number of variables.
  for (intptr_t i = 0; i < list_length; ++i) {
    declarations += BuildVariableDeclaration(false);  // read ith variable.
  }

  loop_depth_inc();
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
    if (new_context) body += CloneContext();

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
  loop_depth_dec();

  loop += ExitScope(offset);

  return loop;
}

Fragment StreamingFlowGraphBuilder::BuildForInStatement(bool async) {
  intptr_t offset = ReaderOffset() - 1;  // Include the tag.

  TokenPosition position = ReadPosition();  // read position.
  intptr_t variable_kernel_position = ReaderOffset();
  SkipVariableDeclaration();  // read variable.

  TokenPosition iterable_position = TokenPosition::kNoSource;
  Fragment instructions =
      BuildExpression(&iterable_position);  // read iterable.
  instructions += PushArgument();

  const dart::String& iterator_getter = dart::String::ZoneHandle(
      Z, dart::Field::GetterSymbol(Symbols::Iterator()));
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
  const dart::String& current_getter = dart::String::ZoneHandle(
      Z, dart::Field::GetterSymbol(Symbols::Current()));
  body += InstanceCall(position, current_getter, Token::kGET, 1);
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
  // We need the number of cases. So start by getting that, then go back.
  intptr_t offset = ReaderOffset();
  SkipExpression();                  // temporarily skip condition
  int num_cases = ReadListLength();  // read number of cases.
  SetOffset(offset);

  SwitchBlock block(flow_graph_builder_, num_cases);

  // Instead of using a variable we should reuse the expression on the stack,
  // since it won't be assigned again, we don't need phi nodes.
  Fragment head_instructions = BuildExpression();  // read condition.
  head_instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes()->switch_variable);
  head_instructions += Drop();

  num_cases = ReadListLength();  // read number of cases.

  // Phase 1: Generate bodies and try to find out whether a body will be target
  // of a jump due to:
  //   * `continue case_label`
  //   * `case e1: case e2: body`
  Fragment* body_fragments = new Fragment[num_cases];
  intptr_t* case_expression_offsets = new intptr_t[num_cases];
  bool* case_is_default = new bool[num_cases];

  for (intptr_t i = 0; i < num_cases; ++i) {
    case_expression_offsets[i] = ReaderOffset();
    int num_expressions = ReadListLength();  // read number of expressions.
    for (intptr_t j = 0; j < num_expressions; ++j) {
      ReadPosition();    // read jth position.
      SkipExpression();  // read jth expression.
    }
    bool is_default = ReadBool();  // read is_default.
    case_is_default[i] = is_default;
    Fragment& body_fragment = body_fragments[i] =
        BuildStatement();  // read body.

    if (body_fragment.entry == NULL) {
      // Make a NOP in order to ensure linking works properly.
      body_fragment = NullConstant();
      body_fragment += Drop();
    }

    // The Dart language specification mandates fall-throughs in [SwitchCase]es
    // to be runtime errors.
    if (!is_default && body_fragment.is_open() && (i < (num_cases - 1))) {
      const dart::Class& klass = dart::Class::ZoneHandle(
          Z, dart::Library::LookupCoreClass(Symbols::FallThroughError()));
      ASSERT(!klass.IsNull());
      const dart::Function& constructor = dart::Function::ZoneHandle(
          Z, klass.LookupConstructorAllowPrivate(
                 H.DartSymbol("FallThroughError._create")));
      ASSERT(!constructor.IsNull());
      const dart::String& url = H.DartString(
          parsed_function()->function().ToLibNamePrefixedQualifiedCString(),
          Heap::kOld);

      // Create instance of _FallThroughError
      body_fragment += AllocateObject(klass, 0);
      LocalVariable* instance = MakeTemporary();

      // Call _FallThroughError._create constructor.
      body_fragment += LoadLocal(instance);
      body_fragment += PushArgument();  // this

      body_fragment += Constant(url);
      body_fragment += PushArgument();  // url

      body_fragment += NullConstant();
      body_fragment += PushArgument();  // line

      body_fragment += StaticCall(TokenPosition::kNoSource, constructor, 3);
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
    if (num_expressions > 1) {
      block.DestinationDirect(i);
    }
  }

  intptr_t end_offset = ReaderOffset();

  // Phase 2: Generate everything except the real bodies:
  //   * jump directly to a body (if there is no jumper)
  //   * jump to a wrapper block which jumps to the body (if there is a jumper)
  Fragment current_instructions = head_instructions;
  for (intptr_t i = 0; i < num_cases; ++i) {
    SetOffset(case_expression_offsets[i]);
    int num_expressions = ReadListLength();  // read length of expressions.

    if (case_is_default[i]) {
      ASSERT(i == (num_cases - 1));

      // Evaluate the conditions for the default [SwitchCase] just for the
      // purpose of potentially triggering a compile-time error.

      for (intptr_t j = 0; j < num_expressions; ++j) {
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

      for (intptr_t j = 0; j < num_expressions; ++j) {
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
                         /*num_args_checked=*/2);
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

  bool has_no_default = num_cases > 0 && !case_is_default[num_cases - 1];
  if (has_no_default) {
    // There is no default, which means we have an open [current_instructions]
    // (which is a [TargetEntryInstruction] for the last "otherwise" branch).
    //
    // Furthermore the last [SwitchCase] can be open as well.  If so, we need
    // to join these two.
    Fragment& last_body = body_fragments[num_cases - 1];
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

  SetOffset(end_offset);
  return Fragment(head_instructions.entry, current_instructions.current);
}

Fragment StreamingFlowGraphBuilder::BuildContinueSwitchStatement() {
  intptr_t target_index = ReadUInt();  // read target index.

  TryFinallyBlock* outer_finally = NULL;
  intptr_t target_context_depth = -1;
  JoinEntryInstr* entry = switch_block()->Destination(
      target_index, &outer_finally, &target_context_depth);

  Fragment instructions;
  instructions +=
      TranslateFinallyFinalizers(outer_finally, target_context_depth);
  if (instructions.is_open()) {
    instructions += Goto(entry);
  }
  return instructions;
}

Fragment StreamingFlowGraphBuilder::BuildIfStatement() {
  bool negate;
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
  intptr_t num_matches = ReadListLength();  // read number of catches.
  const Array& handler_types =
      Array::ZoneHandle(Z, Array::New(num_matches, Heap::kOld));
  Fragment catch_body =
      CatchBlockEntry(handler_types, try_handler_index, needs_stacktrace);
  // Fill in the body of the catch.
  for (intptr_t i = 0; i < num_matches; ++i) {
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
          StoreLocal(TokenPosition::kNoSource, LookupVariable(ReaderOffset()));
      catch_handler_body += Drop();
      SkipVariableDeclaration();  // read exception.
    }

    tag = ReadTag();  // read first part of stack trace.
    if (tag == kSomething) {
      catch_handler_body += LoadLocal(CurrentStackTrace());
      catch_handler_body +=
          StoreLocal(TokenPosition::kNoSource, LookupVariable(ReaderOffset()));
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
        catch_body += NullConstant();
        catch_body += PushArgument();  // instantiator type arguments
        catch_body += NullConstant();
        catch_body += PushArgument();  // function type arguments
        catch_body += Constant(*type_guard);
        catch_body += PushArgument();  // guard type
        catch_body += InstanceCall(
            TokenPosition::kNoSource,
            dart::Library::PrivateCoreLibName(Symbols::_instanceOf()),
            Token::kIS, 4);

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
    TryFinallyBlock tfb(flow_graph_builder_, NULL, finalizer_offset);
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

  ASSERT((flags & YieldStatement::kFlagNative) ==
         YieldStatement::kFlagNative);  // Must have been desugared.

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

Fragment StreamingFlowGraphBuilder::BuildVariableDeclaration(bool has_tag) {
  intptr_t kernel_position = ReaderOffset() - (has_tag ? 1 : 0);
  LocalVariable* variable = LookupVariable(kernel_position);

  TokenPosition position = ReadPosition();         // read position.
  TokenPosition equals_position = ReadPosition();  // read equals position.
  word flags = ReadFlags();                        // read flags.
  dart::String& name = H.DartSymbol(ReadStringReference());  // read name index.
  AbstractType& type = T.BuildType();                        // read type.
  Tag tag = ReadTag();  // read (first part of) initializer.

  Fragment instructions;
  if (tag == kNothing) {
    instructions += NullConstant();
  } else {
    if ((flags & VariableDeclaration::kFlagConst) ==
        VariableDeclaration::kFlagConst) {
      // Const!
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
  TokenPosition debug_position = Utils::Maximum(position, equals_position);
  if (NeedsDebugStepCheck(stack(), debug_position)) {
    instructions = DebugStepCheck(debug_position) + instructions;
  }
  instructions += StoreLocal(position, variable);
  instructions += Drop();
  return instructions;
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
