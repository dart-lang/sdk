// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_binary_flowgraph.h"

#include "vm/object_store.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define I Isolate::Current()

StreamingConstantEvaluator::StreamingConstantEvaluator(
    StreamingFlowGraphBuilder* builder,
    Zone* zone,
    TranslationHelper* h,
    DartTypeTranslator* type_translator)
    : builder_(builder),
      isolate_(Isolate::Current()),
      zone_(zone),
      translation_helper_(*h),
      // type_translator_(*type_translator),
      script_(Script::Handle(
          zone,
          builder == NULL ? Script::null()
                          : builder_->parsed_function()->function().script())),
      result_(Instance::Handle(zone)) {}


Instance& StreamingConstantEvaluator::EvaluateExpression() {
  intptr_t offset = builder_->ReaderOffset();
  if (!GetCachedConstant(offset, &result_)) {
    uint8_t payload = 0;
    Tag tag = builder_->ReadTag(&payload);
    switch (tag) {
      case kStaticGet:
        EvaluateStaticGet();
        break;
      case kSymbolLiteral:
        EvaluateSymbolLiteral();
        break;
      case kDoubleLiteral:
        EvaluateDoubleLiteral();
        break;
      default:
        UNREACHABLE();
    }

    CacheConstantValue(offset, result_);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return dart::Instance::ZoneHandle(Z, result_.raw());
}

void StreamingConstantEvaluator::EvaluateStaticGet() {
  builder_->ReadPosition();
  intptr_t target = builder_->ReadUInt() - 1;

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


void StreamingConstantEvaluator::EvaluateSymbolLiteral() {
  int str_index = builder_->ReadUInt();
  const dart::String& symbol_value = H.DartSymbol(str_index);

  const dart::Class& symbol_class =
      dart::Class::ZoneHandle(Z, I->object_store()->symbol_class());
  ASSERT(!symbol_class.IsNull());
  const dart::Function& symbol_constructor = Function::ZoneHandle(
      Z, symbol_class.LookupConstructor(Symbols::SymbolCtor()));
  ASSERT(!symbol_constructor.IsNull());
  result_ ^= EvaluateConstConstructorCall(
      symbol_class, TypeArguments::Handle(Z), symbol_constructor, symbol_value);
}


void StreamingConstantEvaluator::EvaluateDoubleLiteral() {
  int str_index = builder_->ReadUInt();
  result_ = dart::Double::New(H.DartString(str_index), Heap::kOld);
  result_ = H.Canonicalize(result_);
}


RawObject* StreamingConstantEvaluator::EvaluateConstConstructorCall(
    const dart::Class& type_class,
    const TypeArguments& type_arguments,
    const Function& constructor,
    const Object& argument) {
  // Factories have one extra argument: the type arguments.
  // Constructors have 1 extra arguments: receiver.
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
  const Array& args_descriptor = Array::Handle(
      Z, ArgumentsDescriptor::New(num_arguments, Object::empty_array()));
  const Object& result = Object::Handle(
      Z, DartEntry::InvokeFunction(constructor, arg_values, args_descriptor));
  ASSERT(!result.IsError());
  if (constructor.IsFactory()) {
    // The factory method returns the allocated object.
    instance ^= result.raw();
  }
  return H.Canonicalize(instance);
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
    H.thread()->compiler_stats()->num_const_cache_hits++;
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


Fragment StreamingFlowGraphBuilder::BuildAt(intptr_t kernel_offset) {
  SetOffset(kernel_offset);

  uint8_t payload = 0;
  Tag tag = ReadTag(&payload);
  switch (tag) {
    case kInvalidExpression:
      return BuildInvalidExpression();
    //    case kVariableGet:
    //      return VariableGet::ReadFrom(reader_);
    //    case kSpecializedVariableGet:
    //      return VariableGet::ReadFrom(reader_, payload);
    //    case kVariableSet:
    //      return VariableSet::ReadFrom(reader_);
    //    case kSpecializedVariableSet:
    //      return VariableSet::ReadFrom(reader_, payload);
    //    case kPropertyGet:
    //      return PropertyGet::ReadFrom(reader_);
    //    case kPropertySet:
    //      return PropertySet::ReadFrom(reader_);
    //    case kDirectPropertyGet:
    //      return DirectPropertyGet::ReadFrom(reader_);
    //    case kDirectPropertySet:
    //      return DirectPropertySet::ReadFrom(reader_);
    case kStaticGet:
      return BuildStaticGet();
    //    case kStaticSet:
    //      return StaticSet::ReadFrom(reader_);
    //    case kMethodInvocation:
    //      return MethodInvocation::ReadFrom(reader_);
    //    case kDirectMethodInvocation:
    //      return DirectMethodInvocation::ReadFrom(reader_);
    //    case kStaticInvocation:
    //      return StaticInvocation::ReadFrom(reader_, false);
    //    case kConstStaticInvocation:
    //      return StaticInvocation::ReadFrom(reader_, true);
    //    case kConstructorInvocation:
    //      return ConstructorInvocation::ReadFrom(reader_, false);
    //    case kConstConstructorInvocation:
    //      return ConstructorInvocation::ReadFrom(reader_, true);
    //    case kNot:
    //      return Not::ReadFrom(reader_);
    //    case kLogicalExpression:
    //      return LogicalExpression::ReadFrom(reader_);
    //    case kConditionalExpression:
    //      return ConditionalExpression::ReadFrom(reader_);
    //    case kStringConcatenation:
    //      return StringConcatenation::ReadFrom(reader_);
    //    case kIsExpression:
    //      return IsExpression::ReadFrom(reader_);
    //    case kAsExpression:
    //      return AsExpression::ReadFrom(reader_);
    case kSymbolLiteral:
      return BuildSymbolLiteral();
    //    case kTypeLiteral:
    //      return TypeLiteral::ReadFrom(reader_);
    case kThisExpression:
      return BuildThisExpression();
    case kRethrow:
      return BuildRethrow();
    //    case kThrow:
    //      return Throw::ReadFrom(reader_);
    //    case kListLiteral:
    //      return ListLiteral::ReadFrom(reader_, false);
    //    case kConstListLiteral:
    //      return ListLiteral::ReadFrom(reader_, true);
    //    case kMapLiteral:
    //      return MapLiteral::ReadFrom(reader_, false);
    //    case kConstMapLiteral:
    //      return MapLiteral::ReadFrom(reader_, true);
    //    case kAwaitExpression:
    //      return AwaitExpression::ReadFrom(reader_);
    //    case kFunctionExpression:
    //      return FunctionExpression::ReadFrom(reader_);
    //    case kLet:
    //      return Let::ReadFrom(reader_);
    case kBigIntLiteral:
      return BuildBigIntLiteral();
    case kStringLiteral:
      return BuildStringLiteral();
    case kSpecialIntLiteral:
      return BuildIntLiteral(payload);
    case kNegativeIntLiteral:
      return BuildIntLiteral(true);
    case kPositiveIntLiteral:
      return BuildIntLiteral(false);
    case kDoubleLiteral:
      return BuildDoubleLiteral();
    case kTrueLiteral:
      return BuildBoolLiteral(true);
    case kFalseLiteral:
      return BuildBoolLiteral(false);
    case kNullLiteral:
      return BuildNullLiteral();
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


uint32_t StreamingFlowGraphBuilder::ReadUInt() {
  return reader_->ReadUInt();
}


intptr_t StreamingFlowGraphBuilder::ReadListLength() {
  return reader_->ReadListLength();
}


TokenPosition StreamingFlowGraphBuilder::ReadPosition(bool record) {
  return reader_->ReadPosition(record);
}


Tag StreamingFlowGraphBuilder::ReadTag(uint8_t* payload) {
  return reader_->ReadTag(payload);
}


CatchBlock* StreamingFlowGraphBuilder::catch_block() {
  return flow_graph_builder_->catch_block_;
}


ScopeBuildingResult* StreamingFlowGraphBuilder::scopes() {
  return flow_graph_builder_->scopes_;
}


ParsedFunction* StreamingFlowGraphBuilder::parsed_function() {
  return flow_graph_builder_->parsed_function_;
}


Fragment StreamingFlowGraphBuilder::DebugStepCheck(TokenPosition position) {
  return flow_graph_builder_->DebugStepCheck(position);
}


Fragment StreamingFlowGraphBuilder::LoadLocal(LocalVariable* variable) {
  return flow_graph_builder_->LoadLocal(variable);
}


Fragment StreamingFlowGraphBuilder::PushArgument() {
  return flow_graph_builder_->PushArgument();
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


Fragment StreamingFlowGraphBuilder::BuildInvalidExpression() {
  // The frontend will take care of emitting normal errors (like
  // [NoSuchMethodError]s) and only emit [InvalidExpression]s in very special
  // situations (e.g. an invalid annotation).
  return ThrowNoSuchMethodError();
}


Fragment StreamingFlowGraphBuilder::BuildStaticGet() {
  intptr_t saved_offset = ReaderOffset() - 1;  // Include the tag.
  TokenPosition position = ReadPosition();
  intptr_t target = ReadUInt() - 1;

  if (H.IsField(target)) {
    const dart::Field& field =
        dart::Field::ZoneHandle(Z, H.LookupFieldByKernelField(target));
    if (field.is_const()) {
      SetOffset(saved_offset);  // EvaluateExpression needs the tag.
      return Constant(constant_evaluator_.EvaluateExpression());
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
      SetOffset(saved_offset);  // EvaluateExpression needs the tag.
      return Constant(constant_evaluator_.EvaluateExpression());
    } else {
      UNIMPLEMENTED();
    }
  }

  return Fragment();
}


Fragment StreamingFlowGraphBuilder::BuildSymbolLiteral() {
  SkipBytes(-1);  // EvaluateExpression needs the tag.
  return Constant(constant_evaluator_.EvaluateExpression());
}


Fragment StreamingFlowGraphBuilder::BuildThisExpression() {
  return LoadLocal(scopes()->this_variable);
}


Fragment StreamingFlowGraphBuilder::BuildRethrow() {
  TokenPosition position = ReadPosition();
  Fragment instructions = DebugStepCheck(position);
  instructions += LoadLocal(catch_block()->exception_var());
  instructions += PushArgument();
  instructions += LoadLocal(catch_block()->stack_trace_var());
  instructions += PushArgument();
  instructions += RethrowException(position, catch_block()->catch_try_index());

  return instructions;
}


Fragment StreamingFlowGraphBuilder::BuildBigIntLiteral() {
  const dart::String& value = H.DartString(ReadUInt());
  return Constant(Integer::ZoneHandle(Z, Integer::New(value, Heap::kOld)));
}


Fragment StreamingFlowGraphBuilder::BuildStringLiteral() {
  intptr_t str_index = ReadUInt();
  return Constant(H.DartSymbol(str_index));
}


Fragment StreamingFlowGraphBuilder::BuildIntLiteral(uint8_t payload) {
  int64_t value = static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
  return IntConstant(value);
}


Fragment StreamingFlowGraphBuilder::BuildIntLiteral(bool is_negative) {
  int64_t value = is_negative ? -static_cast<int64_t>(ReadUInt()) : ReadUInt();
  return IntConstant(value);
}


Fragment StreamingFlowGraphBuilder::BuildDoubleLiteral() {
  SkipBytes(-1);  // EvaluateExpression needs the tag.
  return Constant(constant_evaluator_.EvaluateExpression());
}


Fragment StreamingFlowGraphBuilder::BuildBoolLiteral(bool value) {
  return Constant(Bool::Get(value));
}


Fragment StreamingFlowGraphBuilder::BuildNullLiteral() {
  return Constant(Instance::ZoneHandle(Z, Instance::null()));
}


}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
