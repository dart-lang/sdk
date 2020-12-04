// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/type_testing_stubs.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"
#include "vm/timeline.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#define __ assembler->

namespace dart {

DECLARE_FLAG(bool, disassemble_stubs);

TypeTestingStubNamer::TypeTestingStubNamer()
    : lib_(Library::Handle()),
      klass_(Class::Handle()),
      type_(AbstractType::Handle()),
      string_(String::Handle()) {}

const char* TypeTestingStubNamer::StubNameForType(
    const AbstractType& type) const {
  Zone* Z = Thread::Current()->zone();
  return OS::SCreate(Z, "TypeTestingStub_%s", StringifyType(type));
}

const char* TypeTestingStubNamer::StringifyType(
    const AbstractType& type) const {
  NoSafepointScope no_safepoint;
  Zone* Z = Thread::Current()->zone();
  if (type.IsType() && !type.IsFunctionType()) {
    const intptr_t cid = Type::Cast(type).type_class_id();
    ClassTable* class_table = Isolate::Current()->class_table();
    klass_ = class_table->At(cid);
    ASSERT(!klass_.IsNull());

    const char* curl = "";
    lib_ = klass_.library();
    if (!lib_.IsNull()) {
      string_ = lib_.url();
      curl = OS::SCreate(Z, "%s_", string_.ToCString());
    } else {
      static intptr_t counter = 0;
      curl = OS::SCreate(Z, "nolib%" Pd "_", counter++);
    }

    const char* concatenated = AssemblerSafeName(
        OS::SCreate(Z, "%s_%s", curl, klass_.ScrubbedNameCString()));

    const intptr_t type_parameters = klass_.NumTypeParameters();
    auto& type_arguments = TypeArguments::Handle();
    if (type.arguments() != TypeArguments::null() && type_parameters > 0) {
      type_arguments = type.arguments();
      ASSERT(type_arguments.Length() >= type_parameters);
      const intptr_t length = type_arguments.Length();
      for (intptr_t i = 0; i < type_parameters; ++i) {
        type_ = type_arguments.TypeAt(length - type_parameters + i);
        concatenated =
            OS::SCreate(Z, "%s__%s", concatenated, StringifyType(type_));
      }
    }

    return concatenated;
  } else if (type.IsTypeParameter()) {
    string_ = TypeParameter::Cast(type).name();
    return AssemblerSafeName(OS::SCreate(Z, "%s", string_.ToCString()));
  } else {
    return AssemblerSafeName(OS::SCreate(Z, "%s", type.ToCString()));
  }
}

const char* TypeTestingStubNamer::AssemblerSafeName(char* cname) {
  char* cursor = cname;
  while (*cursor != '\0') {
    char c = *cursor;
    if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
          (c >= '0' && c <= '9') || (c == '_'))) {
      *cursor = '_';
    }
    cursor++;
  }
  return cname;
}

CodePtr TypeTestingStubGenerator::DefaultCodeForType(
    const AbstractType& type,
    bool lazy_specialize /* = true */) {
  auto isolate = Isolate::Current();

  if (type.IsTypeRef()) {
    return isolate->use_strict_null_safety_checks()
               ? StubCode::DefaultTypeTest().raw()
               : StubCode::DefaultNullableTypeTest().raw();
  }

  // During bootstrapping we have no access to stubs yet, so we'll just return
  // `null` and patch these later in `Object::FinishInit()`.
  if (!StubCode::HasBeenInitialized()) {
    ASSERT(type.IsType());
    const classid_t cid = type.type_class_id();
    ASSERT(cid == kDynamicCid || cid == kVoidCid);
    return Code::null();
  }

  if (type.IsTopTypeForSubtyping()) {
    return StubCode::TopTypeTypeTest().raw();
  }
  if (type.IsTypeParameter()) {
    const bool nullable = Instance::NullIsAssignableTo(type);
    if (nullable) {
      return StubCode::NullableTypeParameterTypeTest().raw();
    } else {
      return StubCode::TypeParameterTypeTest().raw();
    }
  }

  if (type.IsType()) {
    const bool should_specialize = !FLAG_precompiled_mode && lazy_specialize;
    const bool nullable = Instance::NullIsAssignableTo(type);
    if (should_specialize) {
      return nullable ? StubCode::LazySpecializeNullableTypeTest().raw()
                      : StubCode::LazySpecializeTypeTest().raw();
    } else {
      return nullable ? StubCode::DefaultNullableTypeTest().raw()
                      : StubCode::DefaultTypeTest().raw();
    }
  }

  return StubCode::UnreachableTypeTest().raw();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void TypeTestingStubGenerator::SpecializeStubFor(Thread* thread,
                                                 const AbstractType& type) {
  HierarchyInfo hi(thread);
  TypeTestingStubGenerator generator;
  const Code& code =
      Code::Handle(thread->zone(), generator.OptimizedCodeForType(type));
  type.SetTypeTestingStub(code);
}
#endif

TypeTestingStubGenerator::TypeTestingStubGenerator()
    : object_store_(Isolate::Current()->object_store()) {}

CodePtr TypeTestingStubGenerator::OptimizedCodeForType(
    const AbstractType& type) {
#if !defined(TARGET_ARCH_IA32)
  ASSERT(StubCode::HasBeenInitialized());

  if (type.IsTypeRef() || type.IsTypeParameter()) {
    return TypeTestingStubGenerator::DefaultCodeForType(
        type, /*lazy_specialize=*/false);
  }

  if (type.IsTopTypeForSubtyping()) {
    return StubCode::TopTypeTypeTest().raw();
  }

  if (type.IsCanonical()) {
    if (type.IsType()) {
#if !defined(DART_PRECOMPILED_RUNTIME)
      const Code& code = Code::Handle(
          TypeTestingStubGenerator::BuildCodeForType(Type::Cast(type)));
      if (!code.IsNull()) {
        return code.raw();
      }

      // Fall back to default.
#else
      // In the precompiled runtime we cannot lazily create new optimized type
      // testing stubs, so if we cannot find one, we'll just return the default
      // one.
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
    }
  }
#endif  // !defined(TARGET_ARCH_IA32)
  return TypeTestingStubGenerator::DefaultCodeForType(
      type, /*lazy_specialize=*/false);
}

#if !defined(TARGET_ARCH_IA32)
#if !defined(DART_PRECOMPILED_RUNTIME)

CodePtr TypeTestingStubGenerator::BuildCodeForType(const Type& type) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  HierarchyInfo* hi = thread->hierarchy_info();
  ASSERT(hi != NULL);

  if (!hi->CanUseSubtypeRangeCheckFor(type) &&
      !hi->CanUseGenericSubtypeRangeCheckFor(type)) {
    return Code::null();
  }

  const Class& type_class = Class::Handle(type.type_class());
  ASSERT(!type_class.IsNull());

  auto& slow_tts_stub = Code::ZoneHandle(zone);
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    slow_tts_stub = thread->isolate()->object_store()->slow_tts_stub();
  }

  // To use the already-defined __ Macro !
  compiler::Assembler assembler(nullptr);
  compiler::UnresolvedPcRelativeCalls unresolved_calls;
  BuildOptimizedTypeTestStub(&assembler, &unresolved_calls, slow_tts_stub, hi,
                             type, type_class);

  const auto& static_calls_table =
      Array::Handle(zone, compiler::StubCodeCompiler::BuildStaticCallsTable(
                              zone, &unresolved_calls));

  const char* name = namer_.StubNameForType(type);
  const auto pool_attachment = FLAG_use_bare_instructions
                                   ? Code::PoolAttachment::kNotAttachPool
                                   : Code::PoolAttachment::kAttachPool;

  Code& code = Code::Handle(thread->zone());
  auto install_code_fun = [&]() {
    code = Code::FinalizeCode(nullptr, &assembler, pool_attachment,
                              /*optimized=*/false, /*stats=*/nullptr);
    if (!static_calls_table.IsNull()) {
      code.set_static_calls_target_table(static_calls_table);
    }
  };

  // We have to ensure no mutators are running, because:
  //
  //   a) We allocate an instructions object, which might cause us to
  //      temporarily flip page protections from (RX -> RW -> RX).
  //
  thread->isolate_group()->RunWithStoppedMutators(install_code_fun,
                                                  /*use_force_growth=*/true);

  Code::NotifyCodeObservers(name, code, /*optimized=*/false);

  code.set_owner(type);
#ifndef PRODUCT
  if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
    LogBlock lb;
    THR_Print("Code for stub '%s' (type = %s): {\n", name, type.ToCString());
    DisassembleToStdout formatter;
    code.Disassemble(&formatter);
    THR_Print("}\n");
    const ObjectPool& object_pool = ObjectPool::Handle(code.object_pool());
    if (!object_pool.IsNull()) {
      object_pool.DebugPrint();
    }
  }
#endif  // !PRODUCT

  return code.raw();
}

void TypeTestingStubGenerator::BuildOptimizedTypeTestStubFastCases(
    compiler::Assembler* assembler,
    HierarchyInfo* hi,
    const Type& type,
    const Class& type_class) {
  // These are handled via the TopTypeTypeTestStub!
  ASSERT(!type.IsTopTypeForSubtyping());

  // Fast case for 'int'.
  if (type.IsIntType()) {
    compiler::Label non_smi_value;
    __ BranchIfNotSmi(TypeTestABI::kInstanceReg, &non_smi_value);
    __ Ret();
    __ Bind(&non_smi_value);
  } else if (type.IsDartFunctionType()) {
    compiler::Label continue_checking;
    __ CompareImmediate(TTSInternalRegs::kScratchReg, kClosureCid);
    __ BranchIf(NOT_EQUAL, &continue_checking);
    __ Ret();
    __ Bind(&continue_checking);

  } else if (type.IsObjectType()) {
    ASSERT(type.IsNonNullable() &&
           Isolate::Current()->use_strict_null_safety_checks());
    compiler::Label continue_checking;
    __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
    __ BranchIf(EQUAL, &continue_checking);
    __ Ret();
    __ Bind(&continue_checking);

  } else {
    // TODO(kustermann): Make more fast cases, e.g. Type::Number()
    // is implemented by Smi.
  }

  // Check the cid ranges which are a subtype of [type].
  if (hi->CanUseSubtypeRangeCheckFor(type)) {
    const CidRangeVector& ranges = hi->SubtypeRangesForClass(
        type_class,
        /*include_abstract=*/false,
        /*exclude_null=*/!Instance::NullIsAssignableTo(type));

    const Type& int_type = Type::Handle(Type::IntType());
    const bool smi_is_ok = int_type.IsSubtypeOf(type, Heap::kNew);

    BuildOptimizedSubtypeRangeCheck(assembler, ranges, smi_is_ok);
  } else {
    ASSERT(hi->CanUseGenericSubtypeRangeCheckFor(type));

    const intptr_t num_type_parameters = type_class.NumTypeParameters();
    const intptr_t num_type_arguments = type_class.NumTypeArguments();

    const TypeArguments& tp =
        TypeArguments::Handle(type_class.type_parameters());
    ASSERT(tp.Length() == num_type_parameters);

    const TypeArguments& ta = TypeArguments::Handle(type.arguments());
    ASSERT(ta.Length() == num_type_arguments);

    BuildOptimizedSubclassRangeCheckWithTypeArguments(assembler, hi, type,
                                                      type_class, tp, ta);
  }

  if (Instance::NullIsAssignableTo(type)) {
    // Fast case for 'null'.
    compiler::Label non_null;
    __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
    __ BranchIf(NOT_EQUAL, &non_null);
    __ Ret();
    __ Bind(&non_null);
  }
}

void TypeTestingStubGenerator::BuildOptimizedSubtypeRangeCheck(
    compiler::Assembler* assembler,
    const CidRangeVector& ranges,
    bool smi_is_ok) {
  compiler::Label cid_range_failed, is_subtype;

  if (smi_is_ok) {
    __ LoadClassIdMayBeSmi(TTSInternalRegs::kScratchReg,
                           TypeTestABI::kInstanceReg);
  } else {
    __ BranchIfSmi(TypeTestABI::kInstanceReg, &cid_range_failed);
    __ LoadClassId(TTSInternalRegs::kScratchReg, TypeTestABI::kInstanceReg);
  }

  FlowGraphCompiler::GenerateCidRangesCheck(
      assembler, TTSInternalRegs::kScratchReg, ranges, &is_subtype,
      &cid_range_failed, true);
  __ Bind(&is_subtype);
  __ Ret();
  __ Bind(&cid_range_failed);
}

void TypeTestingStubGenerator::
    BuildOptimizedSubclassRangeCheckWithTypeArguments(
        compiler::Assembler* assembler,
        HierarchyInfo* hi,
        const Type& type,
        const Class& type_class,
        const TypeArguments& tp,
        const TypeArguments& ta) {
  // a) First we make a quick sub*class* cid-range check.
  compiler::Label check_failed;
  ASSERT(!type_class.is_implemented());
  const CidRangeVector& ranges = hi->SubclassRangesForClass(type_class);
  BuildOptimizedSubclassRangeCheck(assembler, ranges, &check_failed);
  // fall through to continue

  // b) Then we'll load the values for the type parameters.
  __ LoadField(
      TTSInternalRegs::kInstanceTypeArgumentsReg,
      compiler::FieldAddress(
          TypeTestABI::kInstanceReg,
          compiler::target::Class::TypeArgumentsFieldOffset(type_class)));

  // The kernel frontend should fill in any non-assigned type parameters on
  // construction with dynamic/Object, so we should never get the null type
  // argument vector in created instances.
  //
  // TODO(kustermann): We could consider not using "null" as type argument
  // vector representing all-dynamic to avoid this extra check (which will be
  // uncommon because most Dart code in 2.0 will be strongly typed)!
  __ CompareObject(TTSInternalRegs::kInstanceTypeArgumentsReg,
                   Object::null_object());
  const Type& rare_type = Type::Handle(Type::RawCast(type_class.RareType()));
  if (rare_type.IsSubtypeOf(type, Heap::kNew)) {
    compiler::Label process_done;
    __ BranchIf(NOT_EQUAL, &process_done);
    __ Ret();
    __ Bind(&process_done);
  } else {
    __ BranchIf(EQUAL, &check_failed);
  }

  // c) Then we'll check each value of the type argument.
  AbstractType& type_arg = AbstractType::Handle();

  const intptr_t num_type_parameters = type_class.NumTypeParameters();
  const intptr_t num_type_arguments = type_class.NumTypeArguments();
  for (intptr_t i = 0; i < num_type_parameters; ++i) {
    const intptr_t type_param_value_offset_i =
        num_type_arguments - num_type_parameters + i;

    type_arg = ta.TypeAt(type_param_value_offset_i);
    ASSERT(type_arg.IsTypeParameter() ||
           hi->CanUseSubtypeRangeCheckFor(type_arg));

    BuildOptimizedTypeArgumentValueCheck(
        assembler, hi, type_arg, type_param_value_offset_i, &check_failed);
  }
  __ Ret();

  // If anything fails.
  __ Bind(&check_failed);
}

void TypeTestingStubGenerator::BuildOptimizedSubclassRangeCheck(
    compiler::Assembler* assembler,
    const CidRangeVector& ranges,
    compiler::Label* check_failed) {
  __ LoadClassIdMayBeSmi(TTSInternalRegs::kScratchReg,
                         TypeTestABI::kInstanceReg);

  compiler::Label is_subtype;
  FlowGraphCompiler::GenerateCidRangesCheck(
      assembler, TTSInternalRegs::kScratchReg, ranges, &is_subtype,
      check_failed, true);
  __ Bind(&is_subtype);
}

// Generate code to verify that instance's type argument is a subtype of
// 'type_arg'.
void TypeTestingStubGenerator::BuildOptimizedTypeArgumentValueCheck(
    compiler::Assembler* assembler,
    HierarchyInfo* hi,
    const AbstractType& type_arg,
    intptr_t type_param_value_offset_i,
    compiler::Label* check_failed) {
  if (type_arg.IsTopTypeForSubtyping()) {
    return;
  }

  // If the upper bound is a type parameter and its value is "dynamic"
  // we always succeed.
  compiler::Label is_dynamic;
  if (type_arg.IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(type_arg);
    const Register kTypeArgumentsReg =
        type_param.IsClassTypeParameter()
            ? TypeTestABI::kInstantiatorTypeArgumentsReg
            : TypeTestABI::kFunctionTypeArgumentsReg;

    __ CompareObject(kTypeArgumentsReg, Object::null_object());
    __ BranchIf(EQUAL, &is_dynamic);

    __ LoadField(
        TTSInternalRegs::kScratchReg,
        compiler::FieldAddress(kTypeArgumentsReg,
                               compiler::target::TypeArguments::type_at_offset(
                                   type_param.index())));
    __ CompareWithFieldValue(
        TTSInternalRegs::kScratchReg,
        compiler::FieldAddress(TTSInternalRegs::kInstanceTypeArgumentsReg,
                               compiler::target::TypeArguments::type_at_offset(
                                   type_param_value_offset_i)));
    __ BranchIf(NOT_EQUAL, check_failed);
  } else {
    const Class& type_class = Class::Handle(type_arg.type_class());
    const CidRangeVector& ranges = hi->SubtypeRangesForClass(
        type_class,
        /*include_abstract=*/true,
        /*exclude_null=*/!Instance::NullIsAssignableTo(type_arg));

    __ LoadField(
        TTSInternalRegs::kScratchReg,
        compiler::FieldAddress(TTSInternalRegs::kInstanceTypeArgumentsReg,
                               compiler::target::TypeArguments::type_at_offset(
                                   type_param_value_offset_i)));
    __ LoadField(
        TTSInternalRegs::kScratchReg,
        compiler::FieldAddress(TTSInternalRegs::kScratchReg,
                               compiler::target::Type::type_class_id_offset()));

    compiler::Label is_subtype;
    __ SmiUntag(TTSInternalRegs::kScratchReg);
    FlowGraphCompiler::GenerateCidRangesCheck(
        assembler, TTSInternalRegs::kScratchReg, ranges, &is_subtype,
        check_failed, true);
    __ Bind(&is_subtype);

    // Weak NNBD mode uses LEGACY_SUBTYPE which ignores nullability.
    // We don't need to check nullability of LHS for nullable and legacy RHS
    // ("Right Legacy", "Right Nullable" rules).
    if (Isolate::Current()->use_strict_null_safety_checks() &&
        !type_arg.IsNullable() && !type_arg.IsLegacy()) {
      // Nullable type is not a subtype of non-nullable type.
      // TODO(dartbug.com/40736): Allocate a register for instance type argument
      // and avoid reloading it.
      __ LoadField(TTSInternalRegs::kScratchReg,
                   compiler::FieldAddress(
                       TTSInternalRegs::kInstanceTypeArgumentsReg,
                       compiler::target::TypeArguments::type_at_offset(
                           type_param_value_offset_i)));
      __ CompareTypeNullabilityWith(TTSInternalRegs::kScratchReg,
                                    compiler::target::Nullability::kNullable);
      __ BranchIf(EQUAL, check_failed);
    }
  }

  __ Bind(&is_dynamic);
}

void RegisterTypeArgumentsUse(const Function& function,
                              TypeUsageInfo* type_usage_info,
                              const Class& klass,
                              Definition* type_arguments) {
  // The [type_arguments] can, in the general case, be any kind of [Definition]
  // but generally (in order of expected frequency)
  //
  //   Case a)
  //      type_arguments <- Constant(#null)
  //      type_arguments <- Constant(#TypeArguments: [ ... ])
  //
  //   Case b)
  //      type_arguments <- InstantiateTypeArguments(ita, fta, uta)
  //      (where uta may not be a constant non-null TypeArguments object)
  //
  //   Case c)
  //      type_arguments <- LoadField(vx)
  //      type_arguments <- LoadField(vx T{_ABC})
  //      type_arguments <- LoadField(vx T{Type: class: '_ABC'})
  //
  //   Case d, e)
  //      type_arguments <- LoadIndexedUnsafe(rbp[vx + 16]))
  //      type_arguments <- Parameter(0)

  if (ConstantInstr* constant = type_arguments->AsConstant()) {
    const Object& object = constant->value();
    ASSERT(object.IsNull() || object.IsTypeArguments());
    const TypeArguments& type_arguments =
        TypeArguments::Handle(TypeArguments::RawCast(object.raw()));
    type_usage_info->UseTypeArgumentsInInstanceCreation(klass, type_arguments);
  } else if (InstantiateTypeArgumentsInstr* instantiate =
                 type_arguments->AsInstantiateTypeArguments()) {
    if (instantiate->type_arguments()->BindsToConstant() &&
        !instantiate->type_arguments()->BoundConstant().IsNull()) {
      const auto& ta =
          TypeArguments::Cast(instantiate->type_arguments()->BoundConstant());
      type_usage_info->UseTypeArgumentsInInstanceCreation(klass, ta);
    }
  } else if (LoadFieldInstr* load_field = type_arguments->AsLoadField()) {
    Definition* instance = load_field->instance()->definition();
    intptr_t cid = instance->Type()->ToNullableCid();
    if (cid == kDynamicCid) {
      // This is an approximation: If we only know the type, but not the cid, we
      // might have a this-dispatch where we know it's either this class or any
      // subclass.
      // We try to strengthen this assumption furher down by checking the offset
      // of the type argument vector, but generally speaking this could be a
      // false-postive, which is still ok!
      const AbstractType& type = *instance->Type()->ToAbstractType();
      if (type.IsType()) {
        const Class& type_class = Class::Handle(type.type_class());
        if (type_class.NumTypeArguments() >= klass.NumTypeArguments()) {
          cid = type_class.id();
        }
      }
    }
    if (cid != kDynamicCid) {
      const Class& instance_klass =
          Class::Handle(Isolate::Current()->class_table()->At(cid));
      if (load_field->slot().IsTypeArguments() && instance_klass.IsGeneric() &&
          compiler::target::Class::TypeArgumentsFieldOffset(instance_klass) ==
              load_field->slot().offset_in_bytes()) {
        // This is a subset of Case c) above, namely forwarding the type
        // argument vector.
        //
        // We use the declaration type arguments for the instance creation,
        // which is a non-instantiated, expanded, type arguments vector.
        const Type& declaration_type =
            Type::Handle(instance_klass.DeclarationType());
        TypeArguments& declaration_type_args =
            TypeArguments::Handle(declaration_type.arguments());
        type_usage_info->UseTypeArgumentsInInstanceCreation(
            klass, declaration_type_args);
      }
    }
  } else if (type_arguments->IsParameter() ||
             type_arguments->IsLoadIndexedUnsafe()) {
    // This happens in constructors with non-optional/optional parameters
    // where we forward the type argument vector to object allocation.
    //
    // Theoretically this could be a false-positive, which is still ok, but
    // practically it's guaranteed that this is a forward of a type argument
    // vector passed in by the caller.
    if (function.IsFactory()) {
      const Class& enclosing_class = Class::Handle(function.Owner());
      const Type& declaration_type =
          Type::Handle(enclosing_class.DeclarationType());
      TypeArguments& declaration_type_args =
          TypeArguments::Handle(declaration_type.arguments());
      type_usage_info->UseTypeArgumentsInInstanceCreation(
          klass, declaration_type_args);
    }
  } else {
    // It can also be a phi node where the inputs are any of the above,
    // or it could be the result of _prependTypeArguments call.
    ASSERT(type_arguments->IsPhi() || type_arguments->IsStaticCall());
  }
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#else  // !defined(TARGET_ARCH_IA32)

#if !defined(DART_PRECOMPILED_RUNTIME)
void RegisterTypeArgumentsUse(const Function& function,
                              TypeUsageInfo* type_usage_info,
                              const Class& klass,
                              Definition* type_arguments) {
  // We only have a [TypeUsageInfo] object available durin AOT compilation.
  UNREACHABLE();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#endif  // !defined(TARGET_ARCH_IA32)

#undef __

const TypeArguments& TypeArgumentInstantiator::InstantiateTypeArguments(
    const Class& klass,
    const TypeArguments& type_arguments) {
  const intptr_t len = klass.NumTypeArguments();
  ScopedHandle<TypeArguments> instantiated_type_arguments(
      &type_arguments_handles_);
  *instantiated_type_arguments = TypeArguments::New(len);
  for (intptr_t i = 0; i < len; ++i) {
    type_ = type_arguments.TypeAt(i);
    type_ = InstantiateType(type_);
    instantiated_type_arguments->SetTypeAt(i, type_);
    ASSERT(type_.IsCanonical() ||
           (type_.IsTypeRef() &&
            AbstractType::Handle(TypeRef::Cast(type_).type()).IsCanonical()));
  }
  *instantiated_type_arguments =
      instantiated_type_arguments->Canonicalize(Thread::Current(), nullptr);
  return *instantiated_type_arguments;
}

AbstractTypePtr TypeArgumentInstantiator::InstantiateType(
    const AbstractType& type) {
  if (type.IsTypeParameter()) {
    const TypeParameter& parameter = TypeParameter::Cast(type);
    ASSERT(parameter.IsClassTypeParameter());
    ASSERT(parameter.IsFinalized());
    if (instantiator_type_arguments_.IsNull()) {
      return Type::DynamicType();
    }
    AbstractType& result = AbstractType::Handle(
        instantiator_type_arguments_.TypeAt(parameter.index()));
    result = result.SetInstantiatedNullability(TypeParameter::Cast(type),
                                               Heap::kOld);
    return result.NormalizeFutureOrType(Heap::kOld);
  } else if (type.IsFunctionType()) {
    // No support for function types yet.
    UNREACHABLE();
    return nullptr;
  } else if (type.IsTypeRef()) {
    // No support for recursive types.
    UNREACHABLE();
    return nullptr;
  } else if (type.IsType()) {
    if (type.IsInstantiated() || type.arguments() == TypeArguments::null()) {
      return type.raw();
    }

    const Type& from = Type::Cast(type);
    klass_ = from.type_class();

    ScopedHandle<Type> to(&type_handles_);
    ScopedHandle<TypeArguments> to_type_arguments(&type_arguments_handles_);

    *to_type_arguments = TypeArguments::null();
    *to = Type::New(klass_, *to_type_arguments, type.token_pos());

    *to_type_arguments = from.arguments();
    to->set_arguments(InstantiateTypeArguments(klass_, *to_type_arguments));
    to->SetIsFinalized();
    *to ^= to->Canonicalize(Thread::Current(), nullptr);

    return to->raw();
  }
  UNREACHABLE();
  return NULL;
}

TypeUsageInfo::TypeUsageInfo(Thread* thread)
    : ThreadStackResource(thread),
      zone_(thread->zone()),
      finder_(zone_),
      assert_assignable_types_(),
      instance_creation_arguments_(
          new TypeArgumentsSet[thread->isolate()->class_table()->NumCids()]),
      klass_(Class::Handle(zone_)) {
  thread->set_type_usage_info(this);
}

TypeUsageInfo::~TypeUsageInfo() {
  thread()->set_type_usage_info(NULL);
  delete[] instance_creation_arguments_;
}

void TypeUsageInfo::UseTypeInAssertAssignable(const AbstractType& type) {
  if (!assert_assignable_types_.HasKey(&type)) {
    AddTypeToSet(&assert_assignable_types_, &type);
  }
}

void TypeUsageInfo::UseTypeArgumentsInInstanceCreation(
    const Class& klass,
    const TypeArguments& ta) {
  if (ta.IsNull() || ta.IsCanonical()) {
    // The Dart VM performs an optimization where it re-uses type argument
    // vectors if the use-site needs a prefix of an already-existent type
    // arguments vector.
    //
    // For example:
    //
    //    class Foo<K, V> {
    //      foo() => new Bar<K>();
    //    }
    //
    // So the length of the type arguments vector can be longer than the number
    // of type arguments the class expects.
    ASSERT(ta.IsNull() || klass.NumTypeArguments() <= ta.Length());

    // If this is a non-instantiated [TypeArguments] object, then it referes to
    // type parameters.  We need to ensure the type parameters in [ta] only
    // refer to type parameters in the class.
    if (!ta.IsNull() && !ta.IsInstantiated() &&
        finder_.FindClass(ta).IsNull()) {
      return;
    }

    klass_ = klass.raw();
    while (klass_.NumTypeArguments() > 0) {
      const intptr_t cid = klass_.id();
      TypeArgumentsSet& set = instance_creation_arguments_[cid];
      if (!set.HasKey(&ta)) {
        set.Insert(&TypeArguments::ZoneHandle(zone_, ta.raw()));
      }
      klass_ = klass_.SuperClass();
    }
  }
}

void TypeUsageInfo::BuildTypeUsageInformation() {
  ClassTable* class_table = thread()->isolate()->class_table();
  const intptr_t cid_count = class_table->NumCids();

  // Step 1) Propagate instantiated type argument vectors.
  PropagateTypeArguments(class_table, cid_count);

  // Step 2) Collect the type parameters we're interested in.
  TypeParameterSet parameters_tested_against;
  CollectTypeParametersUsedInAssertAssignable(&parameters_tested_against);

  // Step 2) Add all types which flow into a type parameter we test against to
  // the set of types tested against.
  UpdateAssertAssignableTypes(class_table, cid_count,
                              &parameters_tested_against);
}

void TypeUsageInfo::PropagateTypeArguments(ClassTable* class_table,
                                           intptr_t cid_count) {
  // See comment in .h file for what this method does.

  Class& klass = Class::Handle(zone_);
  TypeArguments& temp_type_arguments = TypeArguments::Handle(zone_);

  // We cannot modify a set while we are iterating over it, so we delay the
  // addition to the set to the point when iteration has finished and use this
  // list as temporary storage.
  GrowableObjectArray& delayed_type_argument_set =
      GrowableObjectArray::Handle(zone_, GrowableObjectArray::New());

  TypeArgumentInstantiator instantiator(zone_);

  const intptr_t kPropgationRounds = 2;
  for (intptr_t round = 0; round < kPropgationRounds; ++round) {
    for (intptr_t cid = 0; cid < cid_count; ++cid) {
      if (!class_table->IsValidIndex(cid) ||
          !class_table->HasValidClassAt(cid)) {
        continue;
      }

      klass = class_table->At(cid);
      bool null_in_delayed_type_argument_set = false;
      delayed_type_argument_set.SetLength(0);

      auto it = instance_creation_arguments_[cid].GetIterator();
      for (const TypeArguments** type_arguments = it.Next();
           type_arguments != nullptr; type_arguments = it.Next()) {
        // We have a "type allocation" with "klass<type_arguments[0:N]>".
        if (!(*type_arguments)->IsNull() &&
            !(*type_arguments)->IsInstantiated()) {
          const Class& enclosing_class = finder_.FindClass(**type_arguments);
          if (!klass.IsNull()) {
            // We know that "klass<type_arguments[0:N]>" happens inside
            // [enclosing_class].
            if (enclosing_class.raw() != klass.raw()) {
              // Now we try to instantiate [type_arguments] with all the known
              // instantiator type argument vectors of the [enclosing_class].
              const intptr_t enclosing_class_cid = enclosing_class.id();
              TypeArgumentsSet& instantiator_set =
                  instance_creation_arguments_[enclosing_class_cid];
              auto it2 = instantiator_set.GetIterator();
              for (const TypeArguments** instantiator_type_arguments =
                       it2.Next();
                   instantiator_type_arguments != nullptr;
                   instantiator_type_arguments = it2.Next()) {
                // We have also a "type allocation" with
                // "enclosing_class<instantiator_type_arguments[0:M]>".
                if ((*instantiator_type_arguments)->IsNull() ||
                    (*instantiator_type_arguments)->IsInstantiated()) {
                  temp_type_arguments = instantiator.Instantiate(
                      klass, **type_arguments, **instantiator_type_arguments);
                  if (temp_type_arguments.IsNull() &&
                      !null_in_delayed_type_argument_set) {
                    null_in_delayed_type_argument_set = true;
                    delayed_type_argument_set.Add(temp_type_arguments);
                  } else {
                    delayed_type_argument_set.Add(temp_type_arguments);
                  }
                }
              }
            }
          }
        }
      }

      // Now we add the [delayed_type_argument_set] elements to the set of
      // instantiator type arguments of [klass] (and its superclasses).
      if (delayed_type_argument_set.Length() > 0) {
        while (klass.NumTypeArguments() > 0) {
          TypeArgumentsSet& type_argument_set =
              instance_creation_arguments_[klass.id()];
          const intptr_t len = delayed_type_argument_set.Length();
          for (intptr_t i = 0; i < len; ++i) {
            temp_type_arguments =
                TypeArguments::RawCast(delayed_type_argument_set.At(i));
            if (!type_argument_set.HasKey(&temp_type_arguments)) {
              type_argument_set.Insert(
                  &TypeArguments::ZoneHandle(zone_, temp_type_arguments.raw()));
            }
          }
          klass = klass.SuperClass();
        }
      }
    }
  }
}

void TypeUsageInfo::CollectTypeParametersUsedInAssertAssignable(
    TypeParameterSet* set) {
  TypeParameter& param = TypeParameter::Handle(zone_);
  auto it = assert_assignable_types_.GetIterator();
  for (const AbstractType** type = it.Next(); type != nullptr;
       type = it.Next()) {
    AddToSetIfParameter(set, *type, &param);
  }
}

void TypeUsageInfo::UpdateAssertAssignableTypes(
    ClassTable* class_table,
    intptr_t cid_count,
    TypeParameterSet* parameters_tested_against) {
  Class& klass = Class::Handle(zone_);
  TypeParameter& param = TypeParameter::Handle(zone_);
  TypeArguments& params = TypeArguments::Handle(zone_);
  AbstractType& type = AbstractType::Handle(zone_);

  // Because Object/dynamic are common values for type parameters, we add them
  // eagerly and avoid doing it down inside the loop.
  type = Type::DynamicType();
  UseTypeInAssertAssignable(type);
  type = Type::ObjectType();  // TODO(regis): Add nullable Object?
  UseTypeInAssertAssignable(type);

  for (intptr_t cid = 0; cid < cid_count; ++cid) {
    if (!class_table->IsValidIndex(cid) || !class_table->HasValidClassAt(cid)) {
      continue;
    }
    klass = class_table->At(cid);
    if (klass.NumTypeArguments() <= 0) {
      continue;
    }

    const intptr_t num_parameters = klass.NumTypeParameters();
    params = klass.type_parameters();
    for (intptr_t i = 0; i < num_parameters; ++i) {
      param ^= params.TypeAt(i);
      if (parameters_tested_against->HasKey(&param)) {
        TypeArgumentsSet& ta_set = instance_creation_arguments_[cid];
        auto it = ta_set.GetIterator();
        for (const TypeArguments** ta = it.Next(); ta != nullptr;
             ta = it.Next()) {
          // We only add instantiated types to the set (and dynamic/Object were
          // already handled above).
          if (!(*ta)->IsNull()) {
            type = (*ta)->TypeAt(i);
            if (type.IsInstantiated()) {
              UseTypeInAssertAssignable(type);
            }
          }
        }
      }
    }
  }
}

void TypeUsageInfo::AddToSetIfParameter(TypeParameterSet* set,
                                        const AbstractType* type,
                                        TypeParameter* param) {
  if (type->IsTypeParameter()) {
    *param ^= type->raw();
    if (!param->IsNull() && !set->HasKey(param)) {
      set->Insert(&TypeParameter::Handle(zone_, param->raw()));
    }
  }
}

void TypeUsageInfo::AddTypeToSet(TypeSet* set, const AbstractType* type) {
  if (!set->HasKey(type)) {
    set->Insert(&AbstractType::ZoneHandle(zone_, type->raw()));
  }
}

bool TypeUsageInfo::IsUsedInTypeTest(const AbstractType& type) {
  const AbstractType* dereferenced_type = &type;
  if (type.IsTypeRef()) {
    dereferenced_type = &AbstractType::Handle(TypeRef::Cast(type).type());
  }
  if (dereferenced_type->IsFinalized()) {
    return assert_assignable_types_.HasKey(dereferenced_type);
  }
  return false;
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

void DeoptimizeTypeTestingStubs() {
  class CollectTypes : public ObjectVisitor {
   public:
    CollectTypes(GrowableArray<AbstractType*>* types, Zone* zone)
        : types_(types), object_(Object::Handle(zone)), zone_(zone) {}

    void VisitObject(ObjectPtr object) {
      if (object->IsPseudoObject()) {
        // Cannot even be wrapped in handles.
        return;
      }
      object_ = object;
      if (object_.IsAbstractType()) {
        types_->Add(
            &AbstractType::Handle(zone_, AbstractType::RawCast(object)));
      }
    }

   private:
    GrowableArray<AbstractType*>* types_;
    Object& object_;
    Zone* zone_;
  };

  Thread* thread = Thread::Current();
  TIMELINE_DURATION(thread, Isolate, "DeoptimizeTypeTestingStubs");
  HANDLESCOPE(thread);
  Zone* zone = thread->zone();
  GrowableArray<AbstractType*> types;
  {
    HeapIterationScope iter(thread);
    CollectTypes visitor(&types, zone);
    iter.IterateObjects(&visitor);
  }

  TypeTestingStubGenerator generator;
  Code& code = Code::Handle(zone);
  for (intptr_t i = 0; i < types.length(); i++) {
    code = generator.DefaultCodeForType(*types[i]);
    types[i]->SetTypeTestingStub(code);
  }
}

#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
