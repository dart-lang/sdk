// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/type_testing_stubs.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
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

  if (type.IsType() || type.IsTypeParameter() || type.IsTypeRef()) {
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

  const AbstractType* dereferenced_type = &type;
  if (type.IsTypeRef()) {
    dereferenced_type = &AbstractType::Handle(TypeRef::Cast(type).type());
  }

  if (dereferenced_type->IsCanonical()) {
    ASSERT(dereferenced_type->IsResolved());
    if (dereferenced_type->IsType()) {
#if !defined(DART_PRECOMPILED_RUNTIME)
      // Lazily create the type testing stubs array.
      array_ = object_store_->type_testing_stubs();
      if (array_.IsNull()) {
        array_ = GrowableObjectArray::New(Heap::kOld);
        object_store_->set_type_testing_stubs(array_);
      }

      instr_ = TypeTestingStubGenerator::BuildCodeForType(
          Type::Cast(*dereferenced_type));
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
      const intptr_t tuples = array_.Length() / 2 - 1;
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

  const Type* dereferenced_type = NULL;
  if (type.IsTypeRef()) {
    dereferenced_type =
        &Type::Handle(Type::RawCast(TypeRef::Cast(type).type()));
  } else {
    dereferenced_type = &Type::Cast(type);
  }
  if (!hi->CanUseSubtypeRangeCheckFor(*dereferenced_type)) {
    if (!hi->CanUseGenericSubtypeRangeCheckFor(*dereferenced_type)) {
      return Instructions::null();
    }
  }

  const Class& type_class = Class::Handle(dereferenced_type->type_class());
  ASSERT(!type_class.IsNull());

  // To use the already-defined __ Macro !
  Assembler assembler;
  BuildOptimizedTypeTestStub(&assembler, hi, *dereferenced_type, type_class);

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
  // Every object is a subtype of 'Object' and 'dynamic'.
  if (type.raw() == Type::ObjectType() || type.raw() == Type::DynamicType()) {
    __ Ret();
    return;
  }

  // Fast case for 'int'.
  if (type.raw() == Type::IntType()) {
    Label non_smi_value;
    __ BranchIfNotSmi(instance_reg, &non_smi_value);
    __ Ret();
    __ Bind(&non_smi_value);
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
      const CidRangeVector& ranges = hi->SubtypeRangesForClass(type_class);

      Label is_subtype;
      FlowGraphCompiler::GenerateCidRangesCheck(
          assembler, class_id_reg, ranges, &is_subtype, check_failed, true);
      __ Bind(&is_subtype);
    }
  }
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)

#undef __

}  // namespace dart
