// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/constant_evaluator.h"

#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/longjump.h"
#include "vm/object_store.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()

ConstantEvaluator::ConstantEvaluator(KernelReaderHelper* helper,
                                     TypeTranslator* type_translator,
                                     ActiveClass* active_class,
                                     FlowGraphBuilder* flow_graph_builder)
    : helper_(helper),
      isolate_(Isolate::Current()),
      zone_(helper->zone_),
      translation_helper_(helper->translation_helper_),
      type_translator_(*type_translator),
      active_class_(active_class),
      flow_graph_builder_(flow_graph_builder),
      script_(helper->script()),
      result_(Instance::Handle(zone_)) {}

bool ConstantEvaluator::IsCached(intptr_t offset) {
  return GetCachedConstant(offset, &result_);
}

RawInstance* ConstantEvaluator::EvaluateExpression(intptr_t offset,
                                                   bool reset_position) {
  ASSERT(Error::Handle(Z, H.thread()->sticky_error()).IsNull());
  if (!GetCachedConstant(offset, &result_)) {
    BailoutIfBackgroundCompilation();

    ASSERT(IsAllowedToEvaluate());
    intptr_t original_offset = helper_->ReaderOffset();
    helper_->SetOffset(offset);
    uint8_t payload = 0;
    Tag tag = helper_->ReadTag(&payload);  // read tag.
    switch (tag) {
      case kVariableGet:
        EvaluateVariableGet(/* is_specialized = */ false);
        break;
      case kSpecializedVariableGet:
        EvaluateVariableGet(/* is_specialized = */ true);
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
      case kListConcatenation:
      case kSetConcatenation:
      case kMapConcatenation:
      case kInstanceCreation:
        // These only occur inside unevaluated constants, so if we decide to
        // remove support for late evaluation of environment constants from
        // dill files in the VM, an implementation here will not be necessary.
        H.ReportError(
            script_, TokenPosition::kNoSource,
            "Unexpected unevaluated constant, All constant expressions"
            " are expected to be evaluated at this point %s (%d)",
            Reader::TagName(tag), tag);
        break;
      case kSymbolLiteral:
        EvaluateSymbolLiteral();
        break;
      case kTypeLiteral:
        EvaluateTypeLiteral();
        break;
      case kAsExpression:
        EvaluateAsExpression();
        break;
      case kConstListLiteral:
        EvaluateListLiteralInternal();
        break;
      case kConstSetLiteral:
        // Set literals are currently desugared in the frontend and will not
        // reach the VM. See http://dartbug.com/35124 for discussion.
        H.ReportError(script_, TokenPosition::kNoSource,
                      "Unexpected set literal constant, this constant"
                      " is expected to be evaluated at this point %s (%d)",
                      Reader::TagName(tag), tag);
        break;
      case kConstMapLiteral:
        EvaluateMapLiteralInternal();
        break;
      case kLet:
        EvaluateLet();
        break;
      case kBlockExpression: {
        UNIMPLEMENTED();
        break;
      }
      case kInstantiation:
        EvaluatePartialTearoffInstantiation();
        break;
      case kBigIntLiteral:
        EvaluateBigIntLiteral();
        break;
      case kStringLiteral:
        EvaluateStringLiteral();
        break;
      case kSpecializedIntLiteral:
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
      case kConstantExpression:
        helper_->ReadPosition();
        helper_->SkipDartType();
        result_ = EvaluateConstantExpression(helper_->ReadUInt());
        break;
      case kDeprecated_ConstantExpression:
        result_ = EvaluateConstantExpression(helper_->ReadUInt());
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
        H.ReportError(
            script_, TokenPosition::kNoSource,
            "Not a constant expression: unexpected kernel tag %s (%d)",
            Reader::TagName(tag), tag);
    }

    CacheConstantValue(offset, result_);
    if (reset_position) helper_->SetOffset(original_offset);
  } else {
    if (!reset_position) {
      helper_->SetOffset(offset);
      helper_->SkipExpression();
    }
  }
  return result_.raw();
}

Instance& ConstantEvaluator::EvaluateListLiteral(intptr_t offset,
                                                 bool reset_position) {
  if (!GetCachedConstant(offset, &result_)) {
    BailoutIfBackgroundCompilation();

    ASSERT(IsAllowedToEvaluate());
    intptr_t original_offset = helper_->ReaderOffset();
    helper_->SetOffset(offset);
    helper_->ReadTag();  // skip tag.
    EvaluateListLiteralInternal();

    CacheConstantValue(offset, result_);
    if (reset_position) helper_->SetOffset(original_offset);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}

Instance& ConstantEvaluator::EvaluateMapLiteral(intptr_t offset,
                                                bool reset_position) {
  if (!GetCachedConstant(offset, &result_)) {
    BailoutIfBackgroundCompilation();

    ASSERT(IsAllowedToEvaluate());
    intptr_t original_offset = helper_->ReaderOffset();
    helper_->SetOffset(offset);
    helper_->ReadTag();  // skip tag.
    EvaluateMapLiteralInternal();

    CacheConstantValue(offset, result_);
    if (reset_position) helper_->SetOffset(original_offset);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}

Instance& ConstantEvaluator::EvaluateConstructorInvocation(
    intptr_t offset,
    bool reset_position) {
  if (!GetCachedConstant(offset, &result_)) {
    BailoutIfBackgroundCompilation();

    ASSERT(IsAllowedToEvaluate());
    intptr_t original_offset = helper_->ReaderOffset();
    helper_->SetOffset(offset);
    helper_->ReadTag();  // skip tag.
    EvaluateConstructorInvocationInternal();

    CacheConstantValue(offset, result_);
    if (reset_position) helper_->SetOffset(original_offset);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}

Instance& ConstantEvaluator::EvaluateStaticInvocation(intptr_t offset,
                                                      bool reset_position) {
  if (!GetCachedConstant(offset, &result_)) {
    BailoutIfBackgroundCompilation();

    ASSERT(IsAllowedToEvaluate());
    intptr_t original_offset = helper_->ReaderOffset();
    helper_->SetOffset(offset);
    helper_->ReadTag();  // skip tag.
    EvaluateStaticInvocation();

    CacheConstantValue(offset, result_);
    if (reset_position) helper_->SetOffset(original_offset);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}

RawObject* ConstantEvaluator::EvaluateExpressionSafe(intptr_t offset) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    return EvaluateExpression(offset);
  } else {
    return H.thread()->StealStickyError();
  }
}

RawObject* ConstantEvaluator::EvaluateAnnotations() {
  intptr_t list_length = helper_->ReadListLength();  // read list length.
  const Array& metadata_values =
      Array::Handle(Z, Array::New(list_length, H.allocation_space()));
  Instance& value = Instance::Handle(Z);
  for (intptr_t i = 0; i < list_length; ++i) {
    // this will (potentially) read the expression, but reset the position.
    value = EvaluateExpression(helper_->ReaderOffset());
    helper_->SkipExpression();  // read (actual) initializer.
    metadata_values.SetAt(i, value);
  }
  return metadata_values.raw();
}

RawInstance* ConstantEvaluator::EvaluateConstantExpression(
    intptr_t constant_offset) {
  ASSERT(!H.constants().IsNull());
  ASSERT(!H.constants_table().IsNull());  // raw bytes

  // For kernel-level cache (in contrast with script-level caching),
  // we need to access the raw constants array inside the shared
  // KernelProgramInfo directly, so that all scripts will see the
  // results after new insertions. These accesses at kernel-level
  // must be locked since mutator and background compiler can
  // access the array at the same time.
  {
    SafepointMutexLocker ml(H.thread()->isolate()->kernel_constants_mutex());
    KernelConstantsMap constant_map(H.info().constants());
    result_ ^= constant_map.GetOrNull(constant_offset);
    ASSERT(constant_map.Release().raw() == H.info().constants());
  }

  // On miss, evaluate, and insert value.
  if (result_.IsNull()) {
    result_ = EvaluateConstant(constant_offset);
    SafepointMutexLocker ml(H.thread()->isolate()->kernel_constants_mutex());
    KernelConstantsMap constant_map(H.info().constants());
    auto insert = constant_map.InsertNewOrGetValue(constant_offset, result_);
    ASSERT(insert == result_.raw());
    H.info().set_constants(constant_map.Release());  // update!
  }
  return result_.raw();
}

bool ConstantEvaluator::IsInstanceConstant(intptr_t constant_offset,
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

RawInstance* ConstantEvaluator::EvaluateConstant(intptr_t constant_offset) {
  // Get reader directly into raw bytes of constant table.
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
      TypeTranslator type_translator(&reader, active_class_, true);
      auto& type_arguments =
          TypeArguments::Handle(Z, TypeArguments::New(1, Heap::kOld));
      AbstractType& type = type_translator.BuildType();
      type_arguments.SetTypeAt(0, type);
      // Instantiate class.
      type = Type::New(list_class, type_arguments, TokenPosition::kNoSource);
      type = ClassFinalizer::FinalizeType(*active_class_->klass, type,
                                          ClassFinalizer::kCanonicalize);
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
        constant = EvaluateConstantExpression(entry_offset);
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
      const auto& obj = Object::Handle(Z, klass.EnsureIsFinalized(H.thread()));
      ASSERT(obj.IsNull());
      instance = Instance::New(klass, Heap::kOld);
      // Build type from the raw bytes (needs temporary translator).
      TypeTranslator type_translator(&reader, active_class_, true);
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
        type = ClassFinalizer::FinalizeType(*active_class_->klass, type,
                                            ClassFinalizer::kCanonicalize);
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
        constant = EvaluateConstantExpression(entry_offset);
        instance.SetField(field, constant);
      }
      break;
    }
    case kPartialInstantiationConstant: {
      // Recurse into lazily evaluating the "sub" constant
      // needed to evaluate the current constant.
      const intptr_t entry_offset = reader.ReadUInt();
      ASSERT(entry_offset < constant_offset);  // DAG!
      const auto& constant =
          Instance::Handle(Z, EvaluateConstantExpression(entry_offset));
      ASSERT(!constant.IsNull());

      // Build type from the raw bytes (needs temporary translator).
      TypeTranslator type_translator(&reader, active_class_, true);
      const intptr_t number_of_type_arguments = reader.ReadUInt();
      ASSERT(number_of_type_arguments > 0);
      auto& type_arguments = TypeArguments::Handle(
          Z, TypeArguments::New(number_of_type_arguments, Heap::kOld));
      for (intptr_t j = 0; j < number_of_type_arguments; ++j) {
        type_arguments.SetTypeAt(j, type_translator.BuildType());
      }
      type_arguments = type_arguments.Canonicalize();
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
      TypeTranslator type_translator(&reader, active_class_, true);
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

void ConstantEvaluator::BailoutIfBackgroundCompilation() {
  if (Compiler::IsBackgroundCompilation()) {
    Compiler::AbortBackgroundCompilation(
        DeoptId::kNone, "Cannot evaluate annotations in background compiler.");
  }
}

bool ConstantEvaluator::IsBuildingFlowGraph() const {
  return flow_graph_builder_ != nullptr;
}

bool ConstantEvaluator::IsAllowedToEvaluate() const {
  return FLAG_precompiled_mode || !IsBuildingFlowGraph() ||
         !flow_graph_builder_->optimizing_;
}

void ConstantEvaluator::EvaluateVariableGet(bool is_specialized) {
  ASSERT(IsBuildingFlowGraph());
  // When we see a [VariableGet] the corresponding [VariableDeclaration] must've
  // been executed already. It therefore must have a constant object associated
  // with it.
  const TokenPosition position = helper_->ReadPosition();  // read position.
  const intptr_t variable_kernel_position =
      helper_->ReadUInt();  // read kernel position.
  if (!is_specialized) {
    helper_->ReadUInt();              // read relative variable index.
    helper_->SkipOptionalDartType();  // read promoted type.
  }
  LocalVariable* variable =
      flow_graph_builder_->LookupVariable(variable_kernel_position);
  if (!variable->IsConst()) {
    H.ReportError(script_, position, "Not a constant expression.");
  }
  result_ = variable->ConstValue()->raw();
}

void ConstantEvaluator::EvaluateGetStringLength(intptr_t expression_offset,
                                                TokenPosition position) {
  EvaluateExpression(expression_offset);
  if (result_.IsString()) {
    const auto& str = String::Handle(Z, String::RawCast(result_.raw()));
    result_ = Integer::New(str.Length(), H.allocation_space());
  } else {
    H.ReportError(
        script_, position,
        "Constant expressions can only call 'length' on string constants.");
  }
}

void ConstantEvaluator::EvaluatePropertyGet() {
  const TokenPosition position = helper_->ReadPosition();  // read position.
  intptr_t expression_offset = helper_->ReaderOffset();
  helper_->SkipExpression();                            // read receiver.
  StringIndex name = helper_->ReadNameAsStringIndex();  // read name.
  helper_->SkipCanonicalNameReference();  // read interface_target_reference.

  if (H.StringEquals(name, "length")) {
    EvaluateGetStringLength(expression_offset, position);
  } else {
    H.ReportError(
        script_, position,
        "Constant expressions can only call 'length' on string constants.");
  }
}

void ConstantEvaluator::EvaluateDirectPropertyGet() {
  TokenPosition position = helper_->ReadPosition();  // read position.
  intptr_t expression_offset = helper_->ReaderOffset();
  helper_->SkipExpression();  // read receiver.
  NameIndex kernel_name =
      helper_->ReadCanonicalNameReference();  // read target_reference.

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

void ConstantEvaluator::EvaluateStaticGet() {
  TokenPosition position = helper_->ReadPosition();  // read position.
  NameIndex target =
      helper_->ReadCanonicalNameReference();  // read target_reference.

  ASSERT(Error::Handle(Z, H.thread()->sticky_error()).IsNull());

  if (H.IsField(target)) {
    const auto& field = Field::Handle(Z, H.LookupFieldByKernelField(target));
    if (!field.is_const()) {
      H.ReportError(script_, position, "Not a constant field.");
    }
    if (field.StaticValue() == Object::transition_sentinel().raw()) {
      if (IsBuildingFlowGraph()) {
        flow_graph_builder_->InlineBailout(
            "kernel::ConstantEvaluator::EvaluateStaticGet::Cyclic");
      }
      H.ReportError(script_, position, "Not a constant expression.");
    } else if (field.StaticValue() == Object::sentinel().raw()) {
      field.SetStaticValue(Object::transition_sentinel());
      const auto& value = Object::Handle(Z, field.EvaluateInitializer());
      if (value.IsError()) {
        field.SetStaticValue(Object::null_instance());
        H.ReportError(Error::Cast(value), script_, position,
                      "Not a constant expression.");
      }
      Thread* thread = H.thread();
      const Error& error =
          Error::Handle(thread->zone(), thread->StealStickyError());
      if (!error.IsNull()) {
        field.SetStaticValue(Object::null_instance());
        H.ReportError(error, script_, position, "Not a constant expression.");
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
    const auto& function =
        Function::Handle(Z, H.LookupStaticMethodByKernelProcedure(target));

    if (H.IsMethod(target)) {
      const auto& closure_function =
          Function::Handle(Z, function.ImplicitClosureFunction());
      result_ = closure_function.ImplicitStaticClosure();
      result_ = H.Canonicalize(result_);
    } else if (H.IsGetter(target)) {
      H.ReportError(script_, position, "Not a constant expression.");
    } else {
      H.ReportError(script_, position, "Not a constant expression.");
    }
  }
}

void ConstantEvaluator::EvaluateMethodInvocation() {
  TokenPosition position = helper_->ReadPosition();  // read position.
  // This method call wasn't cached, so receiver et al. isn't cached either.
  const auto& receiver = Instance::Handle(
      Z, EvaluateExpression(helper_->ReaderOffset(), false));  // read receiver.
  Class& klass =
      Class::Handle(Z, isolate_->class_table()->At(receiver.GetClassId()));
  ASSERT(!klass.IsNull());

  // Search the superclass chain for the selector.
  const String& method_name = helper_->ReadNameAsMethodName();  // read name.
  Function& function =
      Function::Handle(Z, H.LookupDynamicFunction(klass, method_name));

  // The frontend should guarantee that [MethodInvocation]s inside constant
  // expressions are always valid.
  ASSERT(!function.IsNull());

  // Read arguments, run the method and canonicalize the result.
  const Object& result = RunMethodCall(position, function, &receiver);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);

  helper_->SkipCanonicalNameReference();  // read interface_target_reference.
}

void ConstantEvaluator::EvaluateDirectMethodInvocation() {
  TokenPosition position = helper_->ReadPosition();  // read position.

  const auto& receiver = Instance::Handle(
      Z, EvaluateExpression(helper_->ReaderOffset(), false));  // read receiver.

  NameIndex kernel_name =
      helper_->ReadCanonicalNameReference();  // read target_reference.

  const auto& function = Function::Handle(
      Z, H.LookupMethodByMember(kernel_name, H.DartProcedureName(kernel_name)));

  // Read arguments, run the method and canonicalize the result.
  const Object& result = RunMethodCall(position, function, &receiver);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);
}

void ConstantEvaluator::EvaluateSuperMethodInvocation() {
  ASSERT(IsBuildingFlowGraph());
  TokenPosition position = helper_->ReadPosition();  // read position.

  const LocalVariable* receiver_variable =
      flow_graph_builder_->parsed_function_->receiver_var();
  ASSERT(receiver_variable->IsConst());
  const Instance& receiver =
      Instance::Handle(Z, receiver_variable->ConstValue()->raw());
  ASSERT(!receiver.IsNull());

  Class& klass = Class::Handle(Z, active_class_->klass->SuperClass());
  ASSERT(!klass.IsNull());

  const String& method_name = helper_->ReadNameAsMethodName();  // read name.
  const auto& function =
      Function::Handle(Z, H.LookupDynamicFunction(klass, method_name));

  // The frontend should guarantee that [MethodInvocation]s inside constant
  // expressions are always valid.
  ASSERT(!function.IsNull());

  // Read arguments, run the method and canonicalize the result.
  const Object& result = RunMethodCall(position, function, &receiver);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);

  helper_->SkipCanonicalNameReference();  // read interface_target_reference.
}

void ConstantEvaluator::EvaluateStaticInvocation() {
  TokenPosition position = helper_->ReadPosition();  // read position.
  NameIndex procedure_reference =
      helper_->ReadCanonicalNameReference();  // read procedure reference.

  const auto& function = Function::Handle(
      Z, H.LookupStaticMethodByKernelProcedure(procedure_reference));
  Class& klass = Class::Handle(Z, function.Owner());

  intptr_t argument_count =
      helper_->ReadUInt();  // read arguments part #1: arguments count.

  // Build the type arguments vector (if necessary).
  const TypeArguments* type_arguments =
      TranslateTypeArguments(function, &klass);  // read argument types.

  // read positional and named parameters.
  const Object& result =
      RunFunction(position, function, argument_count, NULL, type_arguments);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);
}

void ConstantEvaluator::EvaluateConstructorInvocationInternal() {
  TokenPosition position = helper_->ReadPosition();  // read position.

  NameIndex target = helper_->ReadCanonicalNameReference();  // read target.
  const auto& constructor =
      Function::Handle(Z, H.LookupConstructorByKernelConstructor(target));
  Class& klass = Class::Handle(Z, constructor.Owner());

  intptr_t argument_count =
      helper_->ReadUInt();  // read arguments part #1: arguments count.

  // Build the type arguments vector (if necessary).
  const TypeArguments* type_arguments =
      TranslateTypeArguments(constructor, &klass);  // read argument types.

  if (klass.NumTypeArguments() > 0 && !klass.IsGeneric()) {
    auto& type = Type::Handle(Z, T.ReceiverType(klass).raw());
    // TODO(27590): Can we move this code into [ReceiverType]?
    type ^= ClassFinalizer::FinalizeType(*active_class_->klass, type,
                                         ClassFinalizer::kFinalize);
    auto& canonicalized_type_arguments =
        TypeArguments::Handle(Z, type.arguments());
    canonicalized_type_arguments = canonicalized_type_arguments.Canonicalize();
    type_arguments = &canonicalized_type_arguments;
  }

  // Prepare either the instance or the type argument vector for the constructor
  // call.
  Instance* receiver = NULL;
  const TypeArguments* type_arguments_argument = NULL;
  if (!constructor.IsFactory()) {
    receiver = &Instance::Handle(Z, Instance::New(klass, Heap::kOld));
    if (type_arguments != NULL) {
      receiver->SetTypeArguments(*type_arguments);
    }
  } else {
    type_arguments_argument = type_arguments;
  }

  // read positional and named parameters.
  const Object& result = RunFunction(position, constructor, argument_count,
                                     receiver, type_arguments_argument);

  if (constructor.IsFactory()) {
    // Factories return the new object.
    result_ ^= result.raw();
  } else {
    ASSERT(!receiver->IsNull());
    result_ = (*receiver).raw();
  }
  if (I->obfuscate() &&
      (result_.clazz() == I->object_store()->symbol_class())) {
    Obfuscator::ObfuscateSymbolInstance(H.thread(), result_);
  }
  result_ = H.Canonicalize(result_);
}

void ConstantEvaluator::EvaluateNot() {
  result_ = Bool::Get(!EvaluateBooleanExpressionHere()).raw();
}

void ConstantEvaluator::EvaluateLogicalExpression() {
  bool left = EvaluateBooleanExpressionHere();  // read left.
  LogicalOperator op = static_cast<LogicalOperator>(helper_->ReadByte());
  if (op == kAnd) {
    if (left) {
      EvaluateBooleanExpressionHere();  // read right.
    } else {
      helper_->SkipExpression();  // read right.
    }
  } else {
    ASSERT(op == kOr);
    if (!left) {
      EvaluateBooleanExpressionHere();  // read right.
    } else {
      helper_->SkipExpression();  // read right.
    }
  }
}

void ConstantEvaluator::EvaluateAsExpression() {
  TokenPosition position = helper_->ReadPosition();
  const uint8_t flags = helper_->ReadFlags();
  const bool is_type_error = (flags & (1 << 0)) != 0;

  // Check that this AsExpression was inserted by the front-end.
  if (!is_type_error) {
    H.ReportError(
        script_, position,
        "explicit as operator is not permitted in constant expression");
  }

  EvaluateExpression(helper_->ReaderOffset(), false);

  const AbstractType& type = T.BuildType();
  if (!type.IsInstantiated()) {
    const auto& type_str = String::Handle(type.UserVisibleName());
    H.ReportError(
        script_, position,
        "Not a constant expression: right hand side of an implicit "
        "as-expression is expected to be an instantiated type, got %s",
        type_str.ToCString());
  }

  const auto& instantiator_type_arguments = TypeArguments::Handle();
  const auto& function_type_arguments = TypeArguments::Handle();
  if (!result_.IsInstanceOf(type, instantiator_type_arguments,
                            function_type_arguments)) {
    const AbstractType& rtype =
        AbstractType::Handle(result_.GetType(Heap::kNew));
    const auto& result_str = String::Handle(rtype.UserVisibleName());
    const auto& type_str = String::Handle(type.UserVisibleName());
    H.ReportError(
        script_, position,
        "Not a constant expression: Type '%s' is not a subtype of type '%s'",
        result_str.ToCString(), type_str.ToCString());
  }
}

void ConstantEvaluator::EvaluateConditionalExpression() {
  bool condition = EvaluateBooleanExpressionHere();
  if (condition) {
    EvaluateExpression(helper_->ReaderOffset(), false);  // read then.
    helper_->SkipExpression();                           // read otherwise.
  } else {
    helper_->SkipExpression();                           // read then.
    EvaluateExpression(helper_->ReaderOffset(), false);  // read otherwise.
  }
  helper_->SkipOptionalDartType();  // read unused static type.
}

void ConstantEvaluator::EvaluateStringConcatenation() {
  TokenPosition position = helper_->ReadPosition();  // read position.
  intptr_t length = helper_->ReadListLength();       // read list length.

  bool all_string = true;
  const Array& strings =
      Array::Handle(Z, Array::New(length, H.allocation_space()));
  for (intptr_t i = 0; i < length; ++i) {
    EvaluateExpression(helper_->ReaderOffset(),
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
    const auto& func = Function::Handle(
        Z, cls.LookupStaticFunction(
               Library::PrivateCoreLibName(Symbols::Interpolate())));
    ASSERT(!func.IsNull());

    // Build argument array to pass to the interpolation function.
    const auto& interpolate_arg = Array::Handle(Z, Array::New(1, Heap::kOld));
    interpolate_arg.SetAt(0, strings);

    // Run and canonicalize.
    const Object& result =
        RunFunction(position, func, interpolate_arg, Array::null_array());
    result_ = H.Canonicalize(String::Cast(result));
  }
}

void ConstantEvaluator::EvaluateSymbolLiteral() {
  const Class& owner = *active_class_->klass;
  const Library& lib = Library::Handle(Z, owner.library());
  String& symbol_value = H.DartIdentifier(lib, helper_->ReadStringReference());
  const Class& symbol_class =
      Class::Handle(Z, I->object_store()->symbol_class());
  ASSERT(!symbol_class.IsNull());
  const auto& symbol_constructor = Function::Handle(
      Z, symbol_class.LookupConstructor(Symbols::SymbolCtor()));
  ASSERT(!symbol_constructor.IsNull());
  result_ ^= EvaluateConstConstructorCall(
      symbol_class, TypeArguments::Handle(Z), symbol_constructor, symbol_value);
}

void ConstantEvaluator::EvaluateTypeLiteral() {
  const AbstractType& type = T.BuildType();
  result_ = type.raw();
}

void ConstantEvaluator::EvaluateListLiteralInternal() {
  helper_->ReadPosition();  // read position.
  const TypeArguments& type_arguments = T.BuildTypeArguments(1);  // read type.
  intptr_t length = helper_->ReadListLength();  // read list length.
  const auto& const_list = Array::Handle(Z, Array::New(length, Heap::kOld));
  const_list.SetTypeArguments(type_arguments);
  Instance& expression = Instance::Handle(Z);
  for (intptr_t i = 0; i < length; ++i) {
    expression = EvaluateExpression(helper_->ReaderOffset(),
                                    false);  // read ith expression.
    const_list.SetAt(i, expression);
  }
  const_list.MakeImmutable();
  result_ = H.Canonicalize(const_list);
}

void ConstantEvaluator::EvaluateMapLiteralInternal() {
  helper_->ReadPosition();  // read position.
  const TypeArguments& type_arguments =
      T.BuildTypeArguments(2);  // read key type and value type.

  intptr_t length = helper_->ReadListLength();  // read length of entries.

  // This MapLiteral wasn't cached, so content isn't cached either.
  Array& const_kv_array = Array::Handle(Z, Array::New(2 * length, Heap::kOld));
  Instance& temp = Instance::Handle(Z);
  for (intptr_t i = 0; i < length; ++i) {
    temp = EvaluateExpression(helper_->ReaderOffset(), false);  // read key.
    const_kv_array.SetAt(2 * i + 0, temp);
    temp = EvaluateExpression(helper_->ReaderOffset(), false);  // read value.
    const_kv_array.SetAt(2 * i + 1, temp);
  }

  const_kv_array.MakeImmutable();
  const_kv_array ^= H.Canonicalize(const_kv_array);

  const Class& map_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::ImmutableMap()));
  ASSERT(!map_class.IsNull());
  ASSERT(map_class.NumTypeArguments() == 2);

  const Field& field =
      Field::Handle(Z, map_class.LookupInstanceFieldAllowPrivate(
                           H.DartSymbolObfuscate("_kvPairs")));
  ASSERT(!field.IsNull());

  // NOTE: This needs to be kept in sync with `runtime/lib/immutable_map.dart`!
  result_ = Instance::New(map_class, Heap::kOld);
  ASSERT(!result_.IsNull());
  result_.SetTypeArguments(type_arguments);
  result_.SetField(field, const_kv_array);
  result_ = H.Canonicalize(result_);
}

void ConstantEvaluator::EvaluateLet() {
  ASSERT(IsBuildingFlowGraph());
  intptr_t kernel_position =
      helper_->ReaderOffset() + helper_->data_program_offset_;

  LocalVariable* local = flow_graph_builder_->LookupVariable(kernel_position);

  // read variable declaration.
  VariableDeclarationHelper helper(helper_);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kInitializer);
  Tag tag = helper_->ReadTag();  // read (first part of) initializer.
  if (tag == kNothing) {
    local->SetConstValue(Instance::ZoneHandle(Z, Instance::null()));
  } else {
    local->SetConstValue(Instance::ZoneHandle(
        Z, EvaluateExpression(helper_->ReaderOffset(),
                              false)));  // read rest of initializer.
  }

  EvaluateExpression(helper_->ReaderOffset(), false);  // read body
}

void ConstantEvaluator::EvaluatePartialTearoffInstantiation() {
  // This method call wasn't cached, so receiver et al. isn't cached either.
  const auto& receiver = Instance::Handle(
      Z, EvaluateExpression(helper_->ReaderOffset(), false));  // read receiver.
  if (!receiver.IsClosure()) {
    H.ReportError(script_, TokenPosition::kNoSource, "Expected closure.");
  }
  const Closure& old_closure = Closure::Cast(receiver);

  // read type arguments.
  intptr_t num_type_args = helper_->ReadListLength();
  const TypeArguments* type_args = &T.BuildTypeArguments(num_type_args);
  if (!type_args->IsNull() && !type_args->IsInstantiated()) {
    H.ReportError(
        script_, TokenPosition::kNoSource,
        "Type arguments in partial instantiations must be instantiated and are "
        "therefore not allowed to depend on type parameters.");
  }

  // Create new closure with the type arguments inserted, and other things
  // copied over.
  Closure& new_closure = Closure::Handle(
      Z,
      Closure::New(
          TypeArguments::Handle(Z, old_closure.instantiator_type_arguments()),
          TypeArguments::Handle(old_closure.function_type_arguments()),
          *type_args, Function::Handle(Z, old_closure.function()),
          Context::Handle(Z, old_closure.context()), Heap::kOld));
  result_ = H.Canonicalize(new_closure);
}

void ConstantEvaluator::EvaluateBigIntLiteral() {
  const String& value =
      H.DartString(helper_->ReadStringReference());  // read string reference.
  result_ = Integer::New(value, Heap::kOld);
  if (result_.IsNull()) {
    H.ReportError(script_, TokenPosition::kNoSource,
                  "Integer literal %s is out of range", value.ToCString());
  }
  result_ = H.Canonicalize(result_);
}

void ConstantEvaluator::EvaluateStringLiteral() {
  result_ = H.DartSymbolPlain(helper_->ReadStringReference())
                .raw();  // read string reference.
}

void ConstantEvaluator::EvaluateIntLiteral(uint8_t payload) {
  int64_t value = static_cast<int32_t>(payload) - SpecializedIntLiteralBias;
  result_ = Integer::New(value, Heap::kOld);
  result_ = H.Canonicalize(result_);
}

void ConstantEvaluator::EvaluateIntLiteral(bool is_negative) {
  int64_t value = is_negative ? -static_cast<int64_t>(helper_->ReadUInt())
                              : helper_->ReadUInt();  // read value.
  result_ = Integer::New(value, Heap::kOld);
  result_ = H.Canonicalize(result_);
}

void ConstantEvaluator::EvaluateDoubleLiteral() {
  result_ = Double::New(helper_->ReadDouble(), Heap::kOld);  // read value.
  result_ = H.Canonicalize(result_);
}

void ConstantEvaluator::EvaluateBoolLiteral(bool value) {
  result_ = Bool::Get(value).raw();
}

void ConstantEvaluator::EvaluateNullLiteral() {
  result_ = Instance::null();
}

// This depends on being about to read the list of positionals on arguments.
const Object& ConstantEvaluator::RunFunction(TokenPosition position,
                                             const Function& function,
                                             intptr_t argument_count,
                                             const Instance* receiver,
                                             const TypeArguments* type_args) {
  // We use a kernel2kernel constant evaluator in Dart 2.0 AOT compilation, so
  // we should never end up evaluating constants using the VM's constant
  // evaluator.
  if (FLAG_precompiled_mode) {
    UNREACHABLE();
  }

  // We do not support generic methods yet.
  ASSERT((receiver == NULL) || (type_args == NULL));
  intptr_t extra_arguments =
      (receiver != NULL ? 1 : 0) + (type_args != NULL ? 1 : 0);

  // Build up arguments.
  const auto& arguments = Array::Handle(
      Z, Array::New(extra_arguments + argument_count, H.allocation_space()));
  intptr_t pos = 0;
  if (receiver != NULL) {
    arguments.SetAt(pos++, *receiver);
  }
  if (type_args != NULL) {
    arguments.SetAt(pos++, *type_args);
  }

  // List of positional.
  intptr_t list_length = helper_->ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    EvaluateExpression(helper_->ReaderOffset(),
                       false);  // read ith expression.
    arguments.SetAt(pos++, result_);
  }

  // List of named.
  list_length = helper_->ReadListLength();  // read list length.
  const Array& names =
      Array::Handle(Z, Array::New(list_length, H.allocation_space()));
  for (intptr_t i = 0; i < list_length; ++i) {
    String& name = H.DartSymbolObfuscate(
        helper_->ReadStringReference());  // read ith name index.
    names.SetAt(i, name);
    EvaluateExpression(helper_->ReaderOffset(),
                       false);  // read ith expression.
    arguments.SetAt(pos++, result_);
  }

  return RunFunction(position, function, arguments, names);
}

const Object& ConstantEvaluator::RunFunction(const TokenPosition position,
                                             const Function& function,
                                             const Array& arguments,
                                             const Array& names) {
  // We do not support generic methods yet.
  const int kTypeArgsLen = 0;
  const auto& args_descriptor = Array::Handle(
      Z, ArgumentsDescriptor::New(kTypeArgsLen, arguments.Length(), names));
  const auto& result = Object::Handle(
      Z, DartEntry::InvokeFunction(function, arguments, args_descriptor));
  if (result.IsError()) {
    H.ReportError(Error::Cast(result), script_, position,
                  "error evaluating constant constructor");
  }
  return result;
}

const Object& ConstantEvaluator::RunMethodCall(const TokenPosition position,
                                               const Function& function,
                                               const Instance* receiver) {
  intptr_t argument_count = helper_->ReadUInt();  // read arguments count.

  // TODO(28109) Support generic methods in the VM or reify them away.
  ASSERT(helper_->PeekListLength() == 0);
  helper_->SkipListOfDartTypes();  // read list of types.

  // Run the method.
  return RunFunction(position, function, argument_count, receiver, NULL);
}

RawObject* ConstantEvaluator::EvaluateConstConstructorCall(
    const Class& type_class,
    const TypeArguments& type_arguments,
    const Function& constructor,
    const Object& argument) {
  // We use a kernel2kernel constant evaluator in Dart 2.0 AOT compilation, so
  // we should never end up evaluating constants using the VM's constant
  // evaluator.
  if (FLAG_precompiled_mode) {
    UNREACHABLE();
  }

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
  const auto& result = Object::Handle(
      Z, DartEntry::InvokeFunction(constructor, arg_values, args_descriptor));
  ASSERT(!result.IsError());
  if (constructor.IsFactory()) {
    // The factory method returns the allocated object.
    instance ^= result.raw();
  }
  if (I->obfuscate() &&
      (instance.clazz() == I->object_store()->symbol_class())) {
    Obfuscator::ObfuscateSymbolInstance(H.thread(), instance);
  }
  return H.Canonicalize(instance);
}

const TypeArguments* ConstantEvaluator::TranslateTypeArguments(
    const Function& target,
    Class* target_klass) {
  intptr_t type_count = helper_->ReadListLength();  // read type count.

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

bool ConstantEvaluator::EvaluateBooleanExpressionHere() {
  EvaluateExpression(helper_->ReaderOffset(), false);
  AssertBool();
  return result_.raw() == Bool::True().raw();
}

bool ConstantEvaluator::GetCachedConstant(intptr_t kernel_offset,
                                          Instance* value) {
  if (!IsBuildingFlowGraph()) return false;

  const Function& function = flow_graph_builder_->parsed_function_->function();
  if ((function.kind() == RawFunction::kImplicitStaticGetter ||
       function.kind() == RawFunction::kFieldInitializer) &&
      !I->CanOptimizeImmediately()) {
    // Don't cache constants in initializer expressions. They get
    // evaluated only once.
    return false;
  }

  bool is_present = false;
  ASSERT(!script_.InVMIsolateHeap());
  if (script_.compile_time_constants() == Array::null()) {
    return false;
  }
  {
    // Any access to constants arrays must be locked since mutator and
    // background compiler can access the array at the same time.
    SafepointMutexLocker ml(H.thread()->isolate()->kernel_constants_mutex());

    KernelConstantsMap constants(script_.compile_time_constants());
    *value ^= constants.GetOrNull(kernel_offset + helper_->data_program_offset_,
                                  &is_present);
    constants.Release();
  }
  return is_present;
}

void ConstantEvaluator::CacheConstantValue(intptr_t kernel_offset,
                                           const Instance& value) {
  ASSERT(Thread::Current()->IsMutatorThread());

  if (!IsBuildingFlowGraph()) return;

  const Function& function = flow_graph_builder_->parsed_function_->function();
  if ((function.kind() == RawFunction::kImplicitStaticGetter ||
       function.kind() == RawFunction::kFieldInitializer) &&
      !I->CanOptimizeImmediately()) {
    // Don't cache constants in initializer expressions. They get
    // evaluated only once.
    return;
  }
  const intptr_t kInitialConstMapSize = 16;
  ASSERT(!script_.InVMIsolateHeap());
  if (script_.compile_time_constants() == Array::null()) {
    const auto& array = Array::Handle(
        HashTables::New<KernelConstantsMap>(kInitialConstMapSize, Heap::kNew));
    script_.set_compile_time_constants(array);
  }
  {
    // Any access to constants arrays must be locked since mutator and
    // background compiler can access the array at the same time.
    SafepointMutexLocker ml(H.thread()->isolate()->kernel_constants_mutex());

    KernelConstantsMap constants(script_.compile_time_constants());
    constants.InsertNewOrGetValue(kernel_offset + helper_->data_program_offset_,
                                  value);
    script_.set_compile_time_constants(constants.Release());
  }
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
