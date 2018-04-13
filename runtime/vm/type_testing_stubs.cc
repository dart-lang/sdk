// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/type_testing_stubs.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/object_store.h"

#define __ assembler->

namespace dart {

DECLARE_FLAG(bool, disassemble_stubs);

TypeTestingStubNamer::TypeTestingStubNamer()
    : lib_(Library::Handle()),
      klass_(Class::Handle()),
      type_(AbstractType::Handle()),
      type_arguments_(TypeArguments::Handle()),
      string_(String::Handle()) {}

const char* TypeTestingStubNamer::StubNameForType(
    const AbstractType& type) const {
  const uintptr_t address =
      reinterpret_cast<uintptr_t>(type.raw()) & 0x7fffffff;
  Zone* Z = Thread::Current()->zone();
  return OS::SCreate(Z, "TypeTestingStub_%s__%" Pd "", StringifyType(type),
                     address);
}

const char* TypeTestingStubNamer::StringifyType(
    const AbstractType& type) const {
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

    string_ = klass_.ScrubbedName();
    ASSERT(!string_.IsNull());
    const char* concatenated =
        AssemblerSafeName(OS::SCreate(Z, "%s_%s", curl, string_.ToCString()));

    const intptr_t type_parameters = klass_.NumTypeParameters();
    if (type.arguments() != TypeArguments::null() && type_parameters > 0) {
      type_arguments_ = type.arguments();
      ASSERT(type_arguments_.Length() >= type_parameters);
      const intptr_t length = type_arguments_.Length();
      for (intptr_t i = 0; i < type_parameters; ++i) {
        type_ = type_arguments_.TypeAt(length - type_parameters + i);
        concatenated =
            OS::SCreate(Z, "%s__%s", concatenated, StringifyType(type_));
      }
    }
    return concatenated;
  } else if (type.IsTypeParameter()) {
    string_ = TypeParameter::Cast(type).name();
    return AssemblerSafeName(OS::SCreate(Z, "%s", string_.ToCString()));
  } else if (type.IsTypeRef()) {
    const Type& dereferenced_type =
        Type::Handle(Type::RawCast(TypeRef::Cast(type).type()));
    return OS::SCreate(Z, "TypeRef_%s", StringifyType(dereferenced_type));
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

RawInstructions* TypeTestingStubGenerator::DefaultCodeForType(
    const AbstractType& type) {
  // During bootstrapping we have no access to stubs yet, so we'll just return
  // `null` and patch these later in `Object::FinishInitOnce()`.
  if (!StubCode::HasBeenInitialized()) {
    ASSERT(type.IsType());
    const intptr_t cid = Type::Cast(type).type_class_id();
    ASSERT(cid == kDynamicCid || cid == kVoidCid || cid == kVectorCid);
    return Instructions::null();
  }

  if (type.raw() == Type::ObjectType() || type.raw() == Type::DynamicType() ||
      type.raw() == Type::VoidType()) {
    return Code::InstructionsOf(StubCode::TopTypeTypeTest_entry()->code());
  }

  if (type.IsTypeRef()) {
    return Code::InstructionsOf(StubCode::TypeRefTypeTest_entry()->code());
  }

  if (type.IsType() || type.IsTypeParameter()) {
    return Code::InstructionsOf(StubCode::DefaultTypeTest_entry()->code());
  } else {
    ASSERT(type.IsBoundedType() || type.IsMixinAppType());
    return Code::InstructionsOf(StubCode::UnreachableTypeTest_entry()->code());
  }
}

TypeTestingStubGenerator::TypeTestingStubGenerator()
    : object_store_(Isolate::Current()->object_store()),
      array_(GrowableObjectArray::Handle()),
      instr_(Instructions::Handle()) {}

RawInstructions* TypeTestingStubGenerator::OptimizedCodeForType(
    const AbstractType& type) {
#if !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)
  ASSERT(StubCode::HasBeenInitialized());

  if (type.IsTypeRef()) {
    return Code::InstructionsOf(StubCode::TypeRefTypeTest_entry()->code());
  }

  if (type.raw() == Type::ObjectType() || type.raw() == Type::DynamicType()) {
    return Code::InstructionsOf(StubCode::TopTypeTypeTest_entry()->code());
  }

  if (type.IsCanonical()) {
    ASSERT(type.IsResolved());
    if (type.IsType()) {
#if !defined(DART_PRECOMPILED_RUNTIME)
      // Lazily create the type testing stubs array.
      array_ = object_store_->type_testing_stubs();
      if (array_.IsNull()) {
        array_ = GrowableObjectArray::New(Heap::kOld);
        object_store_->set_type_testing_stubs(array_);
      }

      instr_ = TypeTestingStubGenerator::BuildCodeForType(Type::Cast(type));
      if (!instr_.IsNull()) {
        array_.Add(type);
        array_.Add(instr_);
      } else {
        // Fall back to default.
        instr_ =
            Code::InstructionsOf(StubCode::DefaultTypeTest_entry()->code());
      }
#else
      // In the precompiled runtime we cannot lazily create new optimized type
      // testing stubs, so if we cannot find one, we'll just return the default
      // one.
      instr_ = Code::InstructionsOf(StubCode::DefaultTypeTest_entry()->code());
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
      return instr_.raw();
    }
  }
#endif  // !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)
  return TypeTestingStubGenerator::DefaultCodeForType(type);
}

TypeTestingStubFinder::TypeTestingStubFinder()
    : array_(GrowableObjectArray::Handle()),
      type_(Type::Handle()),
      code_(Code::Handle()),
      instr_(Instructions::Handle()) {
  array_ = Isolate::Current()->object_store()->type_testing_stubs();
  if (!array_.IsNull()) {
    SortTableForFastLookup();
  }
}

// TODO(kustermann): Use sorting/hashtables to speed this up.
RawInstructions* TypeTestingStubFinder::LookupByAddresss(
    uword entry_point) const {
  // First test the 2 common ones:
  code_ = StubCode::DefaultTypeTest_entry()->code();
  if (entry_point == code_.UncheckedEntryPoint()) {
    return code_.instructions();
  }
  code_ = StubCode::TopTypeTypeTest_entry()->code();
  if (entry_point == code_.UncheckedEntryPoint()) {
    return code_.instructions();
  }
  code_ = StubCode::TypeRefTypeTest_entry()->code();
  if (entry_point == code_.UncheckedEntryPoint()) {
    return code_.instructions();
  }
  code_ = StubCode::UnreachableTypeTest_entry()->code();
  if (entry_point == code_.UncheckedEntryPoint()) {
    return code_.instructions();
  }

  const intptr_t tuple_idx = LookupInSortedArray(entry_point);
  return Instructions::RawCast(array_.At(2 * tuple_idx + 1));
}

const char* TypeTestingStubFinder::StubNameFromAddresss(
    uword entry_point) const {
  // First test the 2 common ones:
  code_ = StubCode::DefaultTypeTest_entry()->code();
  if (entry_point == code_.UncheckedEntryPoint()) {
    return "TypeTestingStub_Default";
  }
  code_ = StubCode::UnreachableTypeTest_entry()->code();
  if (entry_point == code_.UncheckedEntryPoint()) {
    return "TypeTestingStub_Unreachable";
  }

  const intptr_t tuple_idx = LookupInSortedArray(entry_point);
  type_ = AbstractType::RawCast(array_.At(2 * tuple_idx));
  return namer_.StubNameForType(type_);
}

void TypeTestingStubFinder::SortTableForFastLookup() {
  struct Sorter {
    explicit Sorter(const GrowableObjectArray& array)
        : array_(array),
          object_(AbstractType::Handle()),
          object2_(AbstractType::Handle()) {}

    void Sort() {
      const intptr_t tuples = array_.Length() / 2;
      InsertionSort(0, tuples - 1);
    }

    void InsertionSort(intptr_t start, intptr_t end) {
      for (intptr_t i = start + 1; i <= end; ++i) {
        intptr_t j = i;
        while (j > start && Value(j - 1) > Value(j)) {
          Swap(j - 1, j);
          j--;
        }
      }
    }

    void Swap(intptr_t i, intptr_t j) {
      // Swap type.
      object_ = array_.At(2 * i);
      object2_ = array_.At(2 * j);
      array_.SetAt(2 * i, object2_);
      array_.SetAt(2 * j, object_);

      // Swap instructions.
      object_ = array_.At(2 * i + 1);
      object2_ = array_.At(2 * j + 1);
      array_.SetAt(2 * i + 1, object2_);
      array_.SetAt(2 * j + 1, object_);
    }

    uword Value(intptr_t i) {
      return Instructions::UncheckedEntryPoint(
          Instructions::RawCast(array_.At(2 * i + 1)));
    }

    const GrowableObjectArray& array_;
    Object& object_;
    Object& object2_;
  };

  Sorter sorter(array_);
  sorter.Sort();
}

intptr_t TypeTestingStubFinder::LookupInSortedArray(uword entry_point) const {
  intptr_t left = 0;
  intptr_t right = array_.Length() / 2 - 1;

  while (left <= right) {
    const intptr_t mid = left + (right - left) / 2;
    RawInstructions* instr = Instructions::RawCast(array_.At(2 * mid + 1));
    const uword mid_value = Instructions::UncheckedEntryPoint(instr);

    if (entry_point < mid_value) {
      right = mid - 1;
    } else if (mid_value == entry_point) {
      return mid;
    } else {
      left = mid + 1;
    }
  }

  // The caller should only call this function if [entry_point] is a real type
  // testing entrypoint, in which case it must be guaranteed to find it.
  UNREACHABLE();
  return NULL;
}

#if !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)
#if !defined(DART_PRECOMPILED_RUNTIME)

RawInstructions* TypeTestingStubGenerator::BuildCodeForType(const Type& type) {
  HierarchyInfo* hi = Thread::Current()->hierarchy_info();
  ASSERT(hi != NULL);

  if (!hi->CanUseSubtypeRangeCheckFor(type)) {
    if (!hi->CanUseGenericSubtypeRangeCheckFor(type)) {
      return Instructions::null();
    }
  }

  const Class& type_class = Class::Handle(type.type_class());
  ASSERT(!type_class.IsNull());

  // To use the already-defined __ Macro !
  Assembler assembler;
  BuildOptimizedTypeTestStub(&assembler, hi, type, type_class);

  const char* name = namer_.StubNameForType(type);
  const Code& code =
      Code::Handle(Code::FinalizeCode(name, &assembler, false /* optimized */));
#ifndef PRODUCT
  if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
    LogBlock lb;
    THR_Print("Code for stub '%s': {\n", name);
    DisassembleToStdout formatter;
    code.Disassemble(&formatter);
    THR_Print("}\n");
    const ObjectPool& object_pool = ObjectPool::Handle(code.object_pool());
    object_pool.DebugPrint();
  }
#endif  // !PRODUCT

  return code.instructions();
}

void TypeTestingStubGenerator::BuildOptimizedTypeTestStubFastCases(
    Assembler* assembler,
    HierarchyInfo* hi,
    const Type& type,
    const Class& type_class,
    Register instance_reg,
    Register class_id_reg) {
  // These are handled via the TopTypeTypeTestStub!
  ASSERT(
      !(type.raw() == Type::ObjectType() || type.raw() == Type::DynamicType()));

  // Fast case for 'int'.
  if (type.raw() == Type::IntType()) {
    Label non_smi_value;
    __ BranchIfNotSmi(instance_reg, &non_smi_value);
    __ Ret();
    __ Bind(&non_smi_value);
  } else if (type.IsDartFunctionType()) {
    Label continue_checking;
    __ CompareImmediate(class_id_reg, kClosureCid);
    __ BranchIf(NOT_EQUAL, &continue_checking);
    __ Ret();
    __ Bind(&continue_checking);

  } else {
    // TODO(kustermann): Make more fast cases, e.g. Type::Number()
    // is implemented by Smi.
  }

  // Check the cid ranges which are a subtype of [type].
  if (hi->CanUseSubtypeRangeCheckFor(type)) {
    const CidRangeVector& ranges = hi->SubtypeRangesForClass(type_class);

    const Type& int_type = Type::Handle(Type::IntType());
    const bool smi_is_ok = int_type.IsSubtypeOf(type, NULL, NULL, Heap::kNew);

    BuildOptimizedSubtypeRangeCheck(assembler, ranges, class_id_reg,
                                    instance_reg, smi_is_ok);
  } else {
    ASSERT(hi->CanUseGenericSubtypeRangeCheckFor(type));

    const intptr_t num_type_parameters = type_class.NumTypeParameters();
    const intptr_t num_type_arguments = type_class.NumTypeArguments();

    const TypeArguments& tp =
        TypeArguments::Handle(type_class.type_parameters());
    ASSERT(tp.Length() == num_type_parameters);

    const TypeArguments& ta = TypeArguments::Handle(type.arguments());
    ASSERT(ta.Length() == num_type_arguments);

    BuildOptimizedSubclassRangeCheckWithTypeArguments(assembler, hi, type_class,
                                                      tp, ta);
  }

  // Fast case for 'null'.
  Label non_null;
  __ CompareObject(instance_reg, Object::null_object());
  __ BranchIf(NOT_EQUAL, &non_null);
  __ Ret();
  __ Bind(&non_null);
}

void TypeTestingStubGenerator::BuildOptimizedSubtypeRangeCheck(
    Assembler* assembler,
    const CidRangeVector& ranges,
    Register class_id_reg,
    Register instance_reg,
    bool smi_is_ok) {
  Label cid_range_failed, is_subtype;

  if (smi_is_ok) {
    __ LoadClassIdMayBeSmi(class_id_reg, instance_reg);
  } else {
    __ BranchIfSmi(instance_reg, &cid_range_failed);
    __ LoadClassId(class_id_reg, instance_reg);
  }

  FlowGraphCompiler::GenerateCidRangesCheck(
      assembler, class_id_reg, ranges, &is_subtype, &cid_range_failed, true);
  __ Bind(&is_subtype);
  __ Ret();
  __ Bind(&cid_range_failed);
}

void TypeTestingStubGenerator::
    BuildOptimizedSubclassRangeCheckWithTypeArguments(
        Assembler* assembler,
        HierarchyInfo* hi,
        const Class& type_class,
        const TypeArguments& tp,
        const TypeArguments& ta,
        const Register class_id_reg,
        const Register instance_reg,
        const Register instance_type_args_reg) {
  // a) First we make a quick sub*class* cid-range check.
  Label check_failed;
  ASSERT(!type_class.is_implemented());
  const CidRangeVector& ranges = hi->SubclassRangesForClass(type_class);
  BuildOptimizedSubclassRangeCheck(assembler, ranges, class_id_reg,
                                   instance_reg, &check_failed);
  // fall through to continue

  // b) Then we'll load the values for the type parameters.
  __ LoadField(
      instance_type_args_reg,
      FieldAddress(instance_reg, type_class.type_arguments_field_offset()));

  // The kernel frontend should fill in any non-assigned type parameters on
  // construction with dynamic/Object, so we should never get the null type
  // argument vector in created instances.
  //
  // TODO(kustermann): We could consider not using "null" as type argument
  // vector representing all-dynamic to avoid this extra check (which will be
  // uncommon because most Dart code in 2.0 will be strongly typed)!
  Label process_done;
  __ CompareObject(instance_type_args_reg, Object::null_object());
  __ BranchIf(NOT_EQUAL, &process_done);
  __ Ret();
  __ Bind(&process_done);

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
    Assembler* assembler,
    const CidRangeVector& ranges,
    Register class_id_reg,
    Register instance_reg,
    Label* check_failed) {
  __ LoadClassIdMayBeSmi(class_id_reg, instance_reg);

  Label is_subtype;
  FlowGraphCompiler::GenerateCidRangesCheck(assembler, class_id_reg, ranges,
                                            &is_subtype, check_failed, true);
  __ Bind(&is_subtype);
}

void TypeTestingStubGenerator::BuildOptimizedTypeArgumentValueCheck(
    Assembler* assembler,
    HierarchyInfo* hi,
    const AbstractType& type_arg,
    intptr_t type_param_value_offset_i,
    const Register class_id_reg,
    const Register instance_type_args_reg,
    const Register instantiator_type_args_reg,
    const Register function_type_args_reg,
    const Register own_type_arg_reg,
    Label* check_failed) {
  if (type_arg.raw() != Type::ObjectType() &&
      type_arg.raw() != Type::DynamicType()) {
    // TODO(kustermann): Even though it should be safe to use TMP here, we
    // should avoid using TMP outside the assembler.  Try to find a free
    // register to use here!
    __ LoadField(
        TMP,
        FieldAddress(instance_type_args_reg,
                     TypeArguments::type_at_offset(type_param_value_offset_i)));
    __ LoadField(class_id_reg, FieldAddress(TMP, Type::type_class_id_offset()));

    if (type_arg.IsTypeParameter()) {
      const TypeParameter& type_param = TypeParameter::Cast(type_arg);
      const Register kTypeArgumentsReg = type_param.IsClassTypeParameter()
                                             ? instantiator_type_args_reg
                                             : function_type_args_reg;
      __ LoadField(
          own_type_arg_reg,
          FieldAddress(kTypeArgumentsReg,
                       TypeArguments::type_at_offset(type_param.index())));
      __ CompareWithFieldValue(
          class_id_reg,
          FieldAddress(own_type_arg_reg, Type::type_class_id_offset()));
      __ BranchIf(NOT_EQUAL, check_failed);
    } else {
      const Class& type_class = Class::Handle(type_arg.type_class());
      const CidRangeVector& ranges =
          hi->SubtypeRangesForClass(type_class, /*include_abstract=*/true);

      Label is_subtype;
      __ SmiUntag(class_id_reg);
      FlowGraphCompiler::GenerateCidRangesCheck(
          assembler, class_id_reg, ranges, &is_subtype, check_failed, true);
      __ Bind(&is_subtype);
    }
  }
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
  //      type_arguments <- InstantiateTypeArguments(
  //          <type-expr-with-parameters>, ita, fta)
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
    const TypeArguments& ta = instantiate->type_arguments();
    ASSERT(!ta.IsNull());
    type_usage_info->UseTypeArgumentsInInstanceCreation(klass, ta);
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
      if (instance_klass.IsGeneric() &&
          instance_klass.type_arguments_field_offset() ==
              load_field->offset_in_bytes()) {
        // This is a subset of Case c) above, namely forwarding the type
        // argument vector.
        //
        // We use the declaration type arguments for the instance creation,
        // which is a non-instantiated, expanded, type arguments vector.
        const AbstractType& declaration_type =
            AbstractType::Handle(instance_klass.DeclarationType());
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
    // practically it's guranteed that this is a forward of a type argument
    // vector passed in by the caller.
    if (function.IsFactory()) {
      const Class& enclosing_class = Class::Handle(function.Owner());
      const AbstractType& declaration_type =
          AbstractType::Handle(enclosing_class.DeclarationType());
      TypeArguments& declaration_type_args =
          TypeArguments::Handle(declaration_type.arguments());
      type_usage_info->UseTypeArgumentsInInstanceCreation(
          klass, declaration_type_args);
    }
  } else {
    // It can also be a phi node where the inputs are any of the above.
    ASSERT(type_arguments->IsPhi());
  }
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#else  // !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)

void RegisterTypeArgumentsUse(const Function& function,
                              TypeUsageInfo* type_usage_info,
                              const Class& klass,
                              Definition* type_arguments) {
  // We only have a [TypeUsageInfo] object available durin AOT compilation.
  UNREACHABLE();
}

#endif  // !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)

#undef __

const TypeArguments& TypeArgumentInstantiator::InstantiateTypeArguments(
    const Class& klass,
    const TypeArguments& type_arguments) {
  const intptr_t len = klass.NumTypeArguments();
  TypeArguments* instantiated_type_arguments = type_arguments_handles_.Obtain();
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
      instantiated_type_arguments->Canonicalize(NULL);
  type_arguments_handles_.Release(instantiated_type_arguments);
  return *instantiated_type_arguments;
}

RawAbstractType* TypeArgumentInstantiator::InstantiateType(
    const AbstractType& type) {
  if (type.IsTypeParameter()) {
    const TypeParameter& parameter = TypeParameter::Cast(type);
    ASSERT(parameter.IsClassTypeParameter());
    ASSERT(parameter.IsFinalized());
    if (instantiator_type_arguments_.IsNull()) {
      return Type::DynamicType();
    }
    return instantiator_type_arguments_.TypeAt(parameter.index());
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

    Type* to = type_handles_.Obtain();
    TypeArguments* to_type_arguments = type_arguments_handles_.Obtain();

    *to_type_arguments = TypeArguments::null();
    *to = Type::New(klass_, *to_type_arguments, type.token_pos());

    *to_type_arguments = from.arguments();
    to->set_arguments(InstantiateTypeArguments(klass_, *to_type_arguments));
    *to ^= to->Canonicalize(NULL);

    type_arguments_handles_.Release(to_type_arguments);
    type_handles_.Release(to);

    return to->raw();
  }
  UNREACHABLE();
  return NULL;
}

TypeUsageInfo::TypeUsageInfo(Thread* thread)
    : StackResource(thread),
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
  type = Type::ObjectType();
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
            type ^= (*ta)->TypeAt(i);
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
  if (dereferenced_type->IsResolved() && dereferenced_type->IsFinalized()) {
    return assert_assignable_types_.HasKey(dereferenced_type);
  }
  return false;
}

}  // namespace dart
