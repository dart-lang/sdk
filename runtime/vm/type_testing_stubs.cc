// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <functional>

#include "platform/globals.h"
#include "vm/class_id.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/runtime_api.h"
#include "vm/hash_map.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"
#include "vm/timeline.h"
#include "vm/type_testing_stubs.h"
#include "vm/zone_text_buffer.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#define __ assembler->

namespace dart {

TypeTestingStubNamer::TypeTestingStubNamer()
    : lib_(Library::Handle()),
      klass_(Class::Handle()),
      type_(AbstractType::Handle()),
      string_(String::Handle()) {}

const char* TypeTestingStubNamer::StubNameForType(
    const AbstractType& type) const {
  ZoneTextBuffer buffer(Thread::Current()->zone());
  WriteStubNameForTypeTo(&buffer, type);
  return buffer.buffer();
}

void TypeTestingStubNamer::WriteStubNameForTypeTo(
    BaseTextBuffer* buffer,
    const AbstractType& type) const {
  buffer->AddString("TypeTestingStub_");
  StringifyTypeTo(buffer, type);
}

void TypeTestingStubNamer::StringifyTypeTo(BaseTextBuffer* buffer,
                                           const AbstractType& type) const {
  NoSafepointScope no_safepoint;
  if (type.IsType()) {
    const intptr_t cid = Type::Cast(type).type_class_id();
    ClassTable* class_table = IsolateGroup::Current()->class_table();
    klass_ = class_table->At(cid);
    ASSERT(!klass_.IsNull());

    lib_ = klass_.library();
    if (!lib_.IsNull()) {
      string_ = lib_.url();
      buffer->AddString(string_.ToCString());
    } else {
      buffer->Printf("nolib%" Pd "_", nonce_++);
    }

    buffer->AddString("_");
    buffer->AddString(klass_.ScrubbedNameCString());

    auto& type_arguments = TypeArguments::Handle(Type::Cast(type).arguments());
    if (!type_arguments.IsNull()) {
      for (intptr_t i = 0, n = type_arguments.Length(); i < n; ++i) {
        type_ = type_arguments.TypeAt(i);
        buffer->AddString("__");
        StringifyTypeTo(buffer, type_);
      }
    }
  } else if (type.IsTypeParameter()) {
    buffer->AddString(TypeParameter::Cast(type).CanonicalNameCString());
  } else if (type.IsRecordType()) {
    const RecordType& rec = RecordType::Cast(type);
    buffer->AddString("Record");
    const intptr_t num_fields = rec.NumFields();
    const auto& field_names =
        Array::Handle(rec.GetFieldNames(Thread::Current()));
    const intptr_t num_positional_fields = num_fields - field_names.Length();
    const auto& field_types = Array::Handle(rec.field_types());
    for (intptr_t i = 0; i < num_fields; ++i) {
      buffer->AddString("__");
      type_ ^= field_types.At(i);
      StringifyTypeTo(buffer, type_);
      if (i >= num_positional_fields) {
        buffer->AddString("_");
        string_ ^= field_names.At(i - num_positional_fields);
        buffer->AddString(string_.ToCString());
      }
    }
  } else {
    buffer->AddString(type.ToCString());
  }
  MakeNameAssemblerSafe(buffer);
}

void TypeTestingStubNamer::MakeNameAssemblerSafe(BaseTextBuffer* buffer) {
  char* cursor = buffer->buffer();
  while (*cursor != '\0') {
    char c = *cursor;
    if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
          (c >= '0' && c <= '9') || (c == '_'))) {
      *cursor = '_';
    }
    cursor++;
  }
}

CodePtr TypeTestingStubGenerator::DefaultCodeForType(
    const AbstractType& type,
    bool lazy_specialize /* = true */) {
  // During bootstrapping we have no access to stubs yet, so we'll just return
  // `null` and patch these later in `Object::FinishInit()`.
  if (!StubCode::HasBeenInitialized()) {
    ASSERT(type.IsType());
    const classid_t cid = type.type_class_id();
    ASSERT(cid == kDynamicCid || cid == kVoidCid);
    return Code::null();
  }

  if (type.IsTopTypeForSubtyping()) {
    return StubCode::TopTypeTypeTest().ptr();
  }
  if (type.IsTypeParameter()) {
    const bool nullable = Instance::NullIsAssignableTo(type);
    if (nullable) {
      return StubCode::NullableTypeParameterTypeTest().ptr();
    } else {
      return StubCode::TypeParameterTypeTest().ptr();
    }
  }

  if (type.IsFunctionType()) {
    const bool nullable = Instance::NullIsAssignableTo(type);
    return nullable ? StubCode::DefaultNullableTypeTest().ptr()
                    : StubCode::DefaultTypeTest().ptr();
  }

  if (type.IsType() || type.IsRecordType()) {
    const bool should_specialize = !FLAG_precompiled_mode && lazy_specialize;
    const bool nullable = Instance::NullIsAssignableTo(type);
    if (should_specialize) {
      return nullable ? StubCode::LazySpecializeNullableTypeTest().ptr()
                      : StubCode::LazySpecializeTypeTest().ptr();
    } else {
      return nullable ? StubCode::DefaultNullableTypeTest().ptr()
                      : StubCode::DefaultTypeTest().ptr();
    }
  }

  return StubCode::UnreachableTypeTest().ptr();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
CodePtr TypeTestingStubGenerator::SpecializeStubFor(Thread* thread,
                                                    const AbstractType& type) {
  HierarchyInfo hi(thread);
  TypeTestingStubGenerator generator;
  return generator.OptimizedCodeForType(type);
}
#endif

TypeTestingStubGenerator::TypeTestingStubGenerator()
    : object_store_(IsolateGroup::Current()->object_store()) {}

CodePtr TypeTestingStubGenerator::OptimizedCodeForType(
    const AbstractType& type) {
#if !defined(TARGET_ARCH_IA32)
  ASSERT(StubCode::HasBeenInitialized());

  if (type.IsTypeParameter()) {
    return TypeTestingStubGenerator::DefaultCodeForType(
        type, /*lazy_specialize=*/false);
  }

  if (type.IsTopTypeForSubtyping()) {
    return StubCode::TopTypeTypeTest().ptr();
  }

  if (type.IsCanonical()) {
    // When adding any new types that can have specialized TTSes, also update
    // CollectTypes::VisitObject appropriately.
    if (type.IsType() || type.IsRecordType()) {
#if !defined(DART_PRECOMPILED_RUNTIME)
      const Code& code =
          Code::Handle(TypeTestingStubGenerator::BuildCodeForType(type));
      if (!code.IsNull()) {
        return code.ptr();
      }
      const Error& error = Error::Handle(Thread::Current()->StealStickyError());
      if (!error.IsNull()) {
        if (error.ptr() == Object::out_of_memory_error().ptr()) {
          Exceptions::ThrowOOM();
        } else {
          UNREACHABLE();
        }
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

static CodePtr RetryCompilationWithFarBranches(
    Thread* thread,
    std::function<CodePtr(compiler::Assembler&)> fun) {
  volatile intptr_t far_branch_level = 0;
  while (true) {
    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      // To use the already-defined __ Macro !
      compiler::Assembler assembler(nullptr, far_branch_level);
      return fun(assembler);
    } else {
      // We bailed out or we encountered an error.
      const Error& error = Error::Handle(thread->StealStickyError());
      if (error.ptr() == Object::branch_offset_error().ptr()) {
        ASSERT(far_branch_level < 2);
        far_branch_level++;
      } else if (error.ptr() == Object::out_of_memory_error().ptr()) {
        thread->set_sticky_error(error);
        return Code::null();
      } else {
        UNREACHABLE();
      }
    }
  }
}

CodePtr TypeTestingStubGenerator::BuildCodeForType(const AbstractType& type) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  HierarchyInfo* hi = thread->hierarchy_info();
  ASSERT(hi != nullptr);

  if (!hi->CanUseSubtypeRangeCheckFor(type) &&
      !hi->CanUseGenericSubtypeRangeCheckFor(type) &&
      !hi->CanUseRecordSubtypeRangeCheckFor(type)) {
    return Code::null();
  }

  auto& slow_tts_stub = Code::ZoneHandle(zone);
  if (FLAG_precompiled_mode) {
    slow_tts_stub = thread->isolate_group()->object_store()->slow_tts_stub();
  }

  const Code& code = Code::Handle(
      thread->zone(),
      RetryCompilationWithFarBranches(
          thread, [&](compiler::Assembler& assembler) {
            compiler::UnresolvedPcRelativeCalls unresolved_calls;
            BuildOptimizedTypeTestStub(&assembler, &unresolved_calls,
                                       slow_tts_stub, hi, type);

            const auto& static_calls_table = Array::Handle(
                zone, compiler::StubCodeCompiler::BuildStaticCallsTable(
                          zone, &unresolved_calls));

            const char* name = namer_.StubNameForType(type);
            const auto pool_attachment =
                FLAG_precompiled_mode ? Code::PoolAttachment::kNotAttachPool
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
            SafepointWriteRwLocker ml(thread,
                                      thread->isolate_group()->program_lock());
            thread->isolate_group()->RunWithStoppedMutators(
                install_code_fun,
                /*use_force_growth=*/true);

            Code::NotifyCodeObservers(name, code, /*optimized=*/false);

            code.set_owner(type);
#ifndef PRODUCT
            if (FLAG_support_disassembler && FLAG_disassemble_stubs) {
              LogBlock lb;
              THR_Print("Code for stub '%s' (type = %s): {\n", name,
                        type.ToCString());
              DisassembleToStdout formatter;
              code.Disassemble(&formatter);
              THR_Print("}\n");
              const ObjectPool& object_pool =
                  ObjectPool::Handle(code.object_pool());
              if (!object_pool.IsNull()) {
                object_pool.DebugPrint();
              }
            }
#endif  // !PRODUCT
            return code.ptr();
          }));

  return code.ptr();
}

void TypeTestingStubGenerator::BuildOptimizedTypeTestStub(
    compiler::Assembler* assembler,
    compiler::UnresolvedPcRelativeCalls* unresolved_calls,
    const Code& slow_type_test_stub,
    HierarchyInfo* hi,
    const AbstractType& type) {
  BuildOptimizedTypeTestStubFastCases(assembler, hi, type);
  __ Jump(compiler::Address(
      THR, compiler::target::Thread::slow_type_test_entry_point_offset()));
}

void TypeTestingStubGenerator::BuildOptimizedTypeTestStubFastCases(
    compiler::Assembler* assembler,
    HierarchyInfo* hi,
    const AbstractType& type) {
  // These are handled via the TopTypeTypeTestStub!
  ASSERT(!type.IsTopTypeForSubtyping());

  if (type.IsObjectType()) {
    ASSERT(type.IsNonNullable() &&
           hi->thread()->isolate_group()->use_strict_null_safety_checks());
    compiler::Label is_null;
    __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
    __ BranchIf(EQUAL, &is_null, compiler::Assembler::kNearJump);
    __ Ret();
    __ Bind(&is_null);
    return;  // No further checks needed.
  }

  // Fast case for 'int' and '_Smi' (which can appear in core libraries).
  if (type.IsIntType() || type.IsSmiType()) {
    compiler::Label non_smi_value;
    __ BranchIfNotSmi(TypeTestABI::kInstanceReg, &non_smi_value,
                      compiler::Assembler::kNearJump);
    __ Ret();
    __ Bind(&non_smi_value);
  } else {
    // TODO(kustermann): Make more fast cases, e.g. Type::Number()
    // is implemented by Smi.
  }

  // Check the cid ranges which are a subtype of [type].
  if (hi->CanUseSubtypeRangeCheckFor(type)) {
    const Class& type_class = Class::Handle(type.type_class());
    ASSERT(!type_class.IsNull());
    const CidRangeVector& ranges = hi->SubtypeRangesForClass(
        type_class,
        /*include_abstract=*/false,
        /*exclude_null=*/!Instance::NullIsAssignableTo(type));

    compiler::Label is_subtype, is_not_subtype;
    const bool smi_is_ok =
        Type::Handle(Type::SmiType()).IsSubtypeOf(type, Heap::kNew);
    if (smi_is_ok) {
      __ LoadClassIdMayBeSmi(TTSInternalRegs::kScratchReg,
                             TypeTestABI::kInstanceReg);
    } else {
      __ BranchIfSmi(TypeTestABI::kInstanceReg, &is_not_subtype);
      __ LoadClassId(TTSInternalRegs::kScratchReg, TypeTestABI::kInstanceReg);
    }
    BuildOptimizedSubtypeRangeCheck(assembler, ranges,
                                    TTSInternalRegs::kScratchReg, &is_subtype,
                                    &is_not_subtype);
    __ Bind(&is_subtype);
    __ Ret();
    __ Bind(&is_not_subtype);
  } else if (hi->CanUseGenericSubtypeRangeCheckFor(type)) {
    const Class& type_class = Class::Handle(type.type_class());
    ASSERT(!type_class.IsNull());
    BuildOptimizedSubclassRangeCheckWithTypeArguments(
        assembler, hi, Type::Cast(type), type_class);
  } else if (hi->CanUseRecordSubtypeRangeCheckFor(type)) {
    BuildOptimizedRecordSubtypeRangeCheck(assembler, hi,
                                          RecordType::Cast(type));
  } else {
    UNREACHABLE();
  }

  if (Instance::NullIsAssignableTo(type)) {
    // Fast case for 'null'.
    compiler::Label non_null;
    __ CompareObject(TypeTestABI::kInstanceReg, Object::null_object());
    __ BranchIf(NOT_EQUAL, &non_null, compiler::Assembler::kNearJump);
    __ Ret();
    __ Bind(&non_null);
  }
}

static void CommentCheckedClasses(compiler::Assembler* assembler,
                                  const CidRangeVector& ranges) {
  if (!assembler->EmittingComments()) return;
  Thread* const thread = Thread::Current();
  ClassTable* const class_table = thread->isolate_group()->class_table();
  Zone* const zone = thread->zone();
  if (ranges.is_empty()) {
    __ Comment("No valid cids to check");
    return;
  }
  if ((ranges.length() == 1) && ranges[0].IsSingleCid()) {
    const auto& cls = Class::Handle(zone, class_table->At(ranges[0].cid_start));
    __ Comment("Checking for cid %" Pd " (%s)", cls.id(),
               cls.ScrubbedNameCString());
    return;
  }
  __ Comment("Checking for concrete finalized classes:");
  auto& cls = Class::Handle(zone);
  for (const auto& range : ranges) {
    ASSERT(!range.IsIllegalRange());
    for (classid_t cid = range.cid_start; cid <= range.cid_end; cid++) {
      // Invalid entries can be included to keep range count low.
      if (!class_table->HasValidClassAt(cid)) continue;
      cls = class_table->At(cid);
      if (cls.is_abstract()) continue;  // Only output concrete classes.
      __ Comment(" * %" Pd32 " (%s)", cid, cls.ScrubbedNameCString());
    }
  }
}

// Represents the following needs for runtime checks to see if an instance of
// [cls] is a subtype of [type] that has type class [type_class]:
//
// * kCannotBeChecked: Instances of [cls] cannot be checked with any of the
//   currently implemented runtime checks, so must fall back on the runtime.
//
// * kNotSubtype: A [cls] instance is guaranteed to not be a subtype of [type]
//   regardless of any instance type arguments.
//
// * kCidCheckOnly: A [cls] instance is guaranteed to be a subtype of [type]
//   regardless of any instance type arguments.
//
// * kNeedsFinalization: Checking that an instance of [cls] is a subtype of
//   [type] requires instance type arguments, but [cls] is not finalized, and
//   so the appropriate type arguments field offset cannot be determined.
//
// * kInstanceTypeArgumentsAreSubtypes: [cls] implements a fully uninstantiated
//   type with type class [type_class] which can be directly instantiated with
//   the instance type arguments. Thus, each type argument of [type] should be
//   compared with the corresponding (index-wise) instance type argument.
enum class CheckType {
  kCannotBeChecked,
  kNotSubtype,
  kCidCheckOnly,
  kNeedsFinalization,
  kInstanceTypeArgumentsAreSubtypes,
};

// Returns a CheckType describing how to check instances of [to_check] as
// subtypes of [type].
static CheckType SubtypeChecksForClass(Zone* zone,
                                       const Type& type,
                                       const Class& type_class,
                                       const Class& to_check) {
  ASSERT_EQUAL(type.type_class_id(), type_class.id());
  ASSERT(type_class.is_type_finalized());
  ASSERT(!to_check.is_abstract());
  ASSERT(to_check.is_type_finalized());
  ASSERT(AbstractType::Handle(zone, to_check.RareType())
             .IsSubtypeOf(AbstractType::Handle(zone, type_class.RareType()),
                          Heap::kNew));
  if (!type_class.IsGeneric()) {
    // All instances of [to_check] are subtypes of [type].
    return CheckType::kCidCheckOnly;
  }
  if (to_check.FindInstantiationOf(zone, type_class,
                                   /*only_super_classes=*/true)) {
    // No need to check for type argument consistency, as [to_check] is the same
    // as or a subclass of [type_class].
    return to_check.is_finalized()
               ? CheckType::kInstanceTypeArgumentsAreSubtypes
               : CheckType::kCannotBeChecked;
  }
  auto& calculated_type =
      Type::Handle(zone, to_check.GetInstantiationOf(zone, type_class));
  if (calculated_type.IsInstantiated()) {
    if (type.IsInstantiated()) {
      return calculated_type.IsSubtypeOf(type, Heap::kNew)
                 ? CheckType::kCidCheckOnly
                 : CheckType::kNotSubtype;
    }
    // TODO(dartbug.com/46920): Requires walking both types, checking
    // corresponding instantiated parts at compile time (assuming uninstantiated
    // parts check successfully) and then creating appropriate runtime checks
    // for uninstantiated parts of [type].
    return CheckType::kCannotBeChecked;
  }
  if (!to_check.is_finalized()) {
    return CheckType::kNeedsFinalization;
  }
  ASSERT(to_check.NumTypeArguments() > 0);
  ASSERT(compiler::target::Class::TypeArgumentsFieldOffset(to_check) !=
         compiler::target::Class::kNoTypeArguments);
  // If the calculated type arguments are a prefix of the declaration type
  // arguments, then we can just treat the instance type arguments as if they
  // were used to instantiate the type class during checking.
  const auto& decl_type_args = TypeArguments::Handle(
      zone, to_check.GetDeclarationInstanceTypeArguments());
  const auto& calculated_type_args = TypeArguments::Handle(
      zone, calculated_type.GetInstanceTypeArguments(Thread::Current(),
                                                     /*canonicalize=*/false));
  const bool type_args_consistent = calculated_type_args.IsSubvectorEquivalent(
      decl_type_args, 0, type_class.NumTypeArguments(),
      TypeEquality::kCanonical);
  // TODO(dartbug.com/46920): Currently we require subtyping to be checkable
  // by comparing the instance type arguments against the type arguments of
  // [type] piecewise, but we could check other cases as well.
  return type_args_consistent ? CheckType::kInstanceTypeArgumentsAreSubtypes
                              : CheckType::kCannotBeChecked;
}

static void CommentSkippedClasses(compiler::Assembler* assembler,
                                  const Type& type,
                                  const Class& type_class,
                                  const CidRangeVector& ranges) {
  if (!assembler->EmittingComments() || ranges.is_empty()) return;
  if (ranges.is_empty()) return;
  ASSERT(type_class.is_implemented());
  __ Comment("Not checking the following concrete implementors of %s:",
             type_class.ScrubbedNameCString());
  Thread* const thread = Thread::Current();
  auto* const class_table = thread->isolate_group()->class_table();
  Zone* const zone = thread->zone();
  auto& cls = Class::Handle(zone);
  auto& calculated_type = Type::Handle(zone);
  for (const auto& range : ranges) {
    ASSERT(!range.IsIllegalRange());
    for (classid_t cid = range.cid_start; cid <= range.cid_end; cid++) {
      // Invalid entries can be included to keep range count low.
      if (!class_table->HasValidClassAt(cid)) continue;
      cls = class_table->At(cid);
      if (cls.is_abstract()) continue;  // Only output concrete classes.
      ASSERT(cls.is_type_finalized());
      TextBuffer buffer(128);
      buffer.Printf(" * %" Pd32 "(%s): ", cid, cls.ScrubbedNameCString());
      switch (SubtypeChecksForClass(zone, type, type_class, cls)) {
        case CheckType::kCannotBeChecked:
          calculated_type = cls.GetInstantiationOf(zone, type_class);
          buffer.AddString("cannot check that ");
          calculated_type.PrintName(Object::kScrubbedName, &buffer);
          buffer.AddString(" is a subtype of ");
          type.PrintName(Object::kScrubbedName, &buffer);
          break;
        case CheckType::kNotSubtype:
          calculated_type = cls.GetInstantiationOf(zone, type_class);
          calculated_type.PrintName(Object::kScrubbedName, &buffer);
          buffer.AddString(" is not a subtype of ");
          type.PrintName(Object::kScrubbedName, &buffer);
          break;
        case CheckType::kNeedsFinalization:
          buffer.AddString("is not finalized");
          break;
        case CheckType::kInstanceTypeArgumentsAreSubtypes:
          buffer.AddString("was not finalized during class splitting");
          break;
        default:
          // Either the CheckType was kCidCheckOnly, which should never happen
          // since it only requires type finalization, or a new CheckType has
          // been added.
          UNREACHABLE();
          break;
      }
      __ Comment("%s", buffer.buffer());
    }
  }
}

// Builds a cid range check for the concrete subclasses and implementors of
// type. Falls through or jumps to check_succeeded if the range contains the
// cid, else jumps to check_failed.
//
// Returns whether class_id_reg is clobbered.
bool TypeTestingStubGenerator::BuildOptimizedSubtypeRangeCheck(
    compiler::Assembler* assembler,
    const CidRangeVector& ranges,
    Register class_id_reg,
    compiler::Label* check_succeeded,
    compiler::Label* check_failed) {
  CommentCheckedClasses(assembler, ranges);
  return FlowGraphCompiler::GenerateCidRangesCheck(
      assembler, class_id_reg, ranges, check_succeeded, check_failed, true);
}

void TypeTestingStubGenerator::
    BuildOptimizedSubclassRangeCheckWithTypeArguments(
        compiler::Assembler* assembler,
        HierarchyInfo* hi,
        const Type& type,
        const Class& type_class) {
  ASSERT(hi->CanUseGenericSubtypeRangeCheckFor(type));
  compiler::Label check_failed, load_succeeded;
  // a) First we perform subtype cid-range checks and load the instance type
  // arguments based on which check succeeded.
  if (BuildLoadInstanceTypeArguments(assembler, hi, type, type_class,
                                     TTSInternalRegs::kScratchReg,
                                     TTSInternalRegs::kInstanceTypeArgumentsReg,
                                     &load_succeeded, &check_failed)) {
    // Only build type argument checking if any checked cid ranges require it.
    __ Bind(&load_succeeded);

    // The rare type of the class is guaranteed to be a supertype of the
    // runtime type of any instance..
    const Type& rare_type = Type::Handle(type_class.RareType());
    // If the rare type is a subtype of the type being checked, then the runtime
    // type of the instance is also a subtype and we shouldn't need to perform
    // checks for the instance type arguments.
    ASSERT(!rare_type.IsSubtypeOf(type, Heap::kNew));
    // b) We check if the type arguments of the rare type are all dynamic
    // (that is, the type arguments vector is null).
    if (rare_type.arguments() == TypeArguments::null()) {
      // If it is, then the instance could have a null instance TAV. However,
      // if the instance TAV is null, then the runtime type of the instance is
      // the rare type, which means it cannot be a subtype of the checked type.
      __ CompareObject(TTSInternalRegs::kInstanceTypeArgumentsReg,
                       Object::null_object());
      __ BranchIf(EQUAL, &check_failed);
    } else {
      // If the TAV of the rare type is not null, at least one type argument
      // of the rare type is a non-top type. This means no instance can have
      // a null instance TAV, as the dynamic type cannot be a subtype of
      // a non-top type and each type argument of an instance must be
      // a subtype of the corresponding type argument for the rare type.
#if defined(DEBUG)
      // Add the check for null in DEBUG mode, but instead of failing, create a
      // breakpoint to make it obvious that the assumption above has failed.
      __ CompareObject(TTSInternalRegs::kInstanceTypeArgumentsReg,
                       Object::null_object());
      compiler::Label check_instance_tav;
      __ BranchIf(NOT_EQUAL, &check_instance_tav,
                  compiler::Assembler::kNearJump);
      __ Breakpoint();
      __ Bind(&check_instance_tav);
#endif
    }

    // c) Then we'll check each value of the type argument.
    compiler::Label pop_saved_registers_on_failure;
    const RegisterSet saved_registers(
        TTSInternalRegs::kSavedTypeArgumentRegisters, /*fpu_registers=*/0);
    __ PushRegisters(saved_registers);

    AbstractType& type_arg = AbstractType::Handle();
    const TypeArguments& ta = TypeArguments::Handle(type.arguments());
    const intptr_t num_type_parameters = type_class.NumTypeParameters();
    const intptr_t num_type_arguments = type_class.NumTypeArguments();
    ASSERT(ta.Length() == num_type_parameters);
    for (intptr_t i = 0; i < num_type_parameters; ++i) {
      const intptr_t type_param_value_offset_i =
          num_type_arguments - num_type_parameters + i;

      type_arg = ta.TypeAt(i);
      ASSERT(type_arg.IsTypeParameter() ||
             hi->CanUseSubtypeRangeCheckFor(type_arg));

      if (type_arg.IsTypeParameter()) {
        BuildOptimizedTypeParameterArgumentValueCheck(
            assembler, hi, TypeParameter::Cast(type_arg),
            type_param_value_offset_i, &pop_saved_registers_on_failure);
      } else {
        BuildOptimizedTypeArgumentValueCheck(
            assembler, hi, Type::Cast(type_arg), type_param_value_offset_i,
            &pop_saved_registers_on_failure);
      }
    }
    __ PopRegisters(saved_registers);
    __ Ret();
    __ Bind(&pop_saved_registers_on_failure);
    __ PopRegisters(saved_registers);
  }

  // If anything fails.
  __ Bind(&check_failed);
}

void TypeTestingStubGenerator::BuildOptimizedRecordSubtypeRangeCheck(
    compiler::Assembler* assembler,
    HierarchyInfo* hi,
    const RecordType& type) {
  compiler::Label is_subtype, is_not_subtype;
  Zone* zone = Thread::Current()->zone();

  __ BranchIfSmi(TypeTestABI::kInstanceReg, &is_not_subtype);
  __ LoadClassId(TTSInternalRegs::kScratchReg, TypeTestABI::kInstanceReg);

  if (Instance::NullIsAssignableTo(type)) {
    __ CompareImmediate(TTSInternalRegs::kScratchReg, kNullCid);
    __ BranchIf(EQUAL, &is_subtype);
  }
  __ CompareImmediate(TTSInternalRegs::kScratchReg, kRecordCid);
  __ BranchIf(NOT_EQUAL, &is_not_subtype);

  __ LoadCompressedSmi(
      TTSInternalRegs::kScratchReg,
      compiler::FieldAddress(TypeTestABI::kInstanceReg,
                             compiler::target::Record::shape_offset()));
  __ CompareImmediate(TTSInternalRegs::kScratchReg,
                      Smi::RawValue(type.shape().AsInt()));
  __ BranchIf(NOT_EQUAL, &is_not_subtype);

  auto& field_type = AbstractType::Handle(zone);
  auto& field_type_class = Class::Handle(zone);
  const auto& smi_type = Type::Handle(zone, Type::SmiType());
  for (intptr_t i = 0, n = type.NumFields(); i < n; ++i) {
    compiler::Label next;

    field_type = type.FieldTypeAt(i);
    ASSERT(hi->CanUseSubtypeRangeCheckFor(field_type));

    __ LoadCompressedFieldFromOffset(TTSInternalRegs::kScratchReg,
                                     TypeTestABI::kInstanceReg,
                                     compiler::target::Record::field_offset(i));

    field_type_class = field_type.type_class();
    ASSERT(!field_type_class.IsNull());

    const CidRangeVector& ranges = hi->SubtypeRangesForClass(
        field_type_class,
        /*include_abstract=*/false,
        /*exclude_null=*/!Instance::NullIsAssignableTo(field_type));

    const bool smi_is_ok = smi_type.IsSubtypeOf(field_type, Heap::kNew);
    __ BranchIfSmi(TTSInternalRegs::kScratchReg,
                   smi_is_ok ? &next : &is_not_subtype);
    __ LoadClassId(TTSInternalRegs::kScratchReg, TTSInternalRegs::kScratchReg);

    BuildOptimizedSubtypeRangeCheck(assembler, ranges,
                                    TTSInternalRegs::kScratchReg, &next,
                                    &is_not_subtype);
    __ Bind(&next);
  }

  __ Bind(&is_subtype);
  __ Ret();
  __ Bind(&is_not_subtype);
}

// Splits [ranges] into multiple ranges in [output], where the concrete,
// finalized classes in each range share the same type arguments field offset.
//
// The first range in [output] contains [type_class], if any do, and otherwise
// prioritizes ranges that include predefined cids before ranges that only
// contain user-defined classes.
//
// Any cids that do not have valid class table entries, correspond to abstract
// or unfinalized classes, or have no TAV field offset are treated as don't
// cares, in that the cid may appear in any of the CidRangeVectors as needed to
// reduce the number of ranges.
//
// Note that CidRangeVectors are MallocGrowableArrays, so the elements in
// output must be freed after use!
static void SplitByTypeArgumentsFieldOffset(
    Thread* T,
    const Class& type_class,
    const CidRangeVector& ranges,
    GrowableArray<CidRangeVector*>* output) {
  ASSERT(output != nullptr);
  ASSERT(!ranges.is_empty());

  Zone* const Z = T->zone();
  ClassTable* const class_table = T->isolate_group()->class_table();
  IntMap<CidRangeVector*> offset_map(Z);
  IntMap<intptr_t> predefined_offsets(Z);
  IntMap<intptr_t> user_defined_offsets(Z);

  auto add_to_vector = [&](intptr_t tav_offset, const CidRange& range) {
    if (range.cid_start == -1) return;
    ASSERT(tav_offset != compiler::target::Class::kNoTypeArguments);
    if (CidRangeVector* vector = offset_map.Lookup(tav_offset)) {
      vector->Add(range);
    } else {
      vector = new CidRangeVector(1);
      vector->Add(range);
      offset_map.Insert(tav_offset, vector);
    }
  };

  auto increment_count = [&](intptr_t cid, intptr_t tav_offset) {
    if (cid <= kNumPredefinedCids) {
      predefined_offsets.Update(
          {tav_offset, predefined_offsets.Lookup(tav_offset) + 1});
    } else if (auto* const kv = predefined_offsets.LookupPair(tav_offset)) {
      predefined_offsets.Update({kv->key, kv->value + 1});
    } else {
      user_defined_offsets.Update(
          {tav_offset, user_defined_offsets.Lookup(tav_offset) + 1});
    }
  };

  // First populate offset_map.
  auto& cls = Class::Handle(Z);
  for (const auto& range : ranges) {
    intptr_t last_offset = compiler::target::Class::kNoTypeArguments;
    intptr_t cid_start = -1;
    intptr_t cid_end = -1;
    for (intptr_t cid = range.cid_start; cid <= range.cid_end; cid++) {
      if (!class_table->HasValidClassAt(cid)) continue;
      cls = class_table->At(cid);
      if (cls.is_abstract()) continue;
      // Only finalized concrete classes are present due to the conditions on
      // returning kInstanceTypeArgumentsAreSubtypes in SubtypeChecksForClass.
      ASSERT(cls.is_finalized());
      const intptr_t tav_offset =
          compiler::target::Class::TypeArgumentsFieldOffset(cls);
      if (tav_offset == compiler::target::Class::kNoTypeArguments) continue;
      if (tav_offset == last_offset && cid_start >= 0) {
        cid_end = cid;
        increment_count(cid, tav_offset);
        continue;
      }
      add_to_vector(last_offset, {cid_start, cid_end});
      last_offset = tav_offset;
      cid_start = cid_end = cid;
      increment_count(cid, tav_offset);
    }
    add_to_vector(last_offset, {cid_start, cid_end});
  }

  ASSERT(!offset_map.IsEmpty());

  // Add the CidRangeVector for the type_class's offset, if it has one.
  if (!type_class.is_abstract() && type_class.is_finalized()) {
    const intptr_t type_class_offset =
        compiler::target::Class::TypeArgumentsFieldOffset(type_class);
    ASSERT(predefined_offsets.LookupPair(type_class_offset) != nullptr ||
           user_defined_offsets.LookupPair(type_class_offset) != nullptr);
    CidRangeVector* const vector = offset_map.Lookup(type_class_offset);
    ASSERT(vector != nullptr);
    output->Add(vector);
    // Remove this CidRangeVector from consideration in the following loops.
    predefined_offsets.Remove(type_class_offset);
    user_defined_offsets.Remove(type_class_offset);
  }
  // Now add CidRangeVectors that include predefined cids.
  // For now, we do this in an arbitrary order, but we could use the counts
  // to prioritize offsets that are more shared if desired.
  auto predefined_it = predefined_offsets.GetIterator();
  while (auto* const kv = predefined_it.Next()) {
    CidRangeVector* const vector = offset_map.Lookup(kv->key);
    ASSERT(vector != nullptr);
    output->Add(vector);
  }
  // Finally, add CidRangeVectors that only include user-defined cids.
  // For now, we do this in an arbitrary order, but we could use the counts
  // to prioritize offsets that are more shared if desired.
  auto user_defined_it = user_defined_offsets.GetIterator();
  while (auto* const kv = user_defined_it.Next()) {
    CidRangeVector* const vector = offset_map.Lookup(kv->key);
    ASSERT(vector != nullptr);
    output->Add(vector);
  }
  ASSERT(output->length() > 0);
}

// Given [type], its type class [type_class], and a CidRangeVector [ranges],
// populates the output CidRangeVectors from cids in [ranges], based on what
// runtime checks are needed to determine whether the runtime type of
// an instance is a subtype of [type].
//
// Concrete, type finalized classes whose cids are added to [cid_check_only]
// implement a particular instantiation of [type_class] that is guaranteed to
// be a subtype of [type]. Thus, these instances do not require any checking
// of type arguments.
//
// Concrete, finalized classes whose cids are added to [type_argument_checks]
// implement a fully uninstantiated version of [type_class] that can be directly
// instantiated with the type arguments of the class's instance. Thus, each
// type argument of [type] should be checked against the corresponding
// instance type argument.
//
// Classes whose cids are in [not_checked]:
// * Instances of the class are guaranteed to not be a subtype of [type].
// * The class is not finalized.
// * The subtype relation cannot be checked with our current approach and
//   thus the stub must fall back to the STC/VM runtime.
//
// Any cids that do not have valid class table entries or correspond to
// abstract classes are treated as don't cares, in that the cid may or may not
// appear as needed to reduce the number of ranges.
static void SplitOnTypeArgumentTests(HierarchyInfo* hi,
                                     const Type& type,
                                     const Class& type_class,
                                     const CidRangeVector& ranges,
                                     CidRangeVector* cid_check_only,
                                     CidRangeVector* type_argument_checks,
                                     CidRangeVector* not_checked) {
  ASSERT(type_class.is_implemented());  // No need to split if not implemented.
  ASSERT(cid_check_only->is_empty());
  ASSERT(type_argument_checks->is_empty());
  ASSERT(not_checked->is_empty());
  ClassTable* const class_table = hi->thread()->isolate_group()->class_table();
  Zone* const zone = hi->thread()->zone();
  auto& to_check = Class::Handle(zone);
  auto add_cid_range = [&](CheckType check, const CidRange& range) {
    if (range.cid_start == -1) return;
    switch (check) {
      case CheckType::kCidCheckOnly:
        cid_check_only->Add(range);
        break;
      case CheckType::kInstanceTypeArgumentsAreSubtypes:
        type_argument_checks->Add(range);
        break;
      default:
        not_checked->Add(range);
    }
  };
  for (const auto& range : ranges) {
    CheckType last_check = CheckType::kCannotBeChecked;
    classid_t cid_start = -1, cid_end = -1;
    for (classid_t cid = range.cid_start; cid <= range.cid_end; cid++) {
      // Invalid entries can be included to keep range count low.
      if (!class_table->HasValidClassAt(cid)) continue;
      to_check = class_table->At(cid);
      if (to_check.is_abstract()) continue;
      const CheckType current_check =
          SubtypeChecksForClass(zone, type, type_class, to_check);
      ASSERT(current_check != CheckType::kInstanceTypeArgumentsAreSubtypes ||
             to_check.is_finalized());
      if (last_check == current_check && cid_start >= 0) {
        cid_end = cid;
        continue;
      }
      add_cid_range(last_check, {cid_start, cid_end});
      last_check = current_check;
      cid_start = cid_end = cid;
    }
    add_cid_range(last_check, {cid_start, cid_end});
  }
}

bool TypeTestingStubGenerator::BuildLoadInstanceTypeArguments(
    compiler::Assembler* assembler,
    HierarchyInfo* hi,
    const Type& type,
    const Class& type_class,
    const Register class_id_reg,
    const Register instance_type_args_reg,
    compiler::Label* load_succeeded,
    compiler::Label* load_failed) {
  const CidRangeVector& ranges =
      hi->SubtypeRangesForClass(type_class, /*include_abstract=*/false,
                                !Instance::NullIsAssignableTo(type));
  if (ranges.is_empty()) {
    // Fall through and signal type argument checks should not be generated.
    CommentCheckedClasses(assembler, ranges);
    return false;
  }
  if (!type_class.is_implemented()) {
    ASSERT(type_class.is_finalized());
    const intptr_t tav_offset =
        compiler::target::Class::TypeArgumentsFieldOffset(type_class);
    compiler::Label is_subtype;
    __ LoadClassIdMayBeSmi(class_id_reg, TypeTestABI::kInstanceReg);
    BuildOptimizedSubtypeRangeCheck(assembler, ranges, class_id_reg,
                                    &is_subtype, load_failed);
    __ Bind(&is_subtype);
    if (tav_offset != compiler::target::Class::kNoTypeArguments) {
      // The class and its subclasses have trivially consistent type arguments.
      __ LoadCompressedFieldFromOffset(instance_type_args_reg,
                                       TypeTestABI::kInstanceReg, tav_offset);
      return true;
    } else {
      // Not a generic type, so cid checks are sufficient.
      __ Ret();
      return false;
    }
  }
  Thread* const T = hi->thread();
  Zone* const Z = T->zone();
  CidRangeVector cid_checks_only, type_argument_checks, not_checked;
  SplitOnTypeArgumentTests(hi, type, type_class, ranges, &cid_checks_only,
                           &type_argument_checks, &not_checked);
  ASSERT(!CidRangeVectorUtils::ContainsCid(type_argument_checks, kSmiCid));
  const bool smi_valid =
      CidRangeVectorUtils::ContainsCid(cid_checks_only, kSmiCid);
  // If we'll generate any cid checks and Smi isn't a valid subtype, then
  // do a single Smi check here, since each generated check requires a fresh
  // load of the class id. Otherwise, we'll generate the Smi check as part of
  // the cid checks only block.
  if (!smi_valid &&
      (!cid_checks_only.is_empty() || !type_argument_checks.is_empty())) {
    __ BranchIfSmi(TypeTestABI::kInstanceReg, load_failed);
  }
  // Ensure that if the cid checks only block is skipped, the first iteration
  // of the type arguments check will generate a cid load.
  bool cid_needs_reload = true;
  if (!cid_checks_only.is_empty()) {
    compiler::Label is_subtype, keep_looking;
    compiler::Label* check_failed =
        type_argument_checks.is_empty() ? load_failed : &keep_looking;
    if (smi_valid) {
      __ LoadClassIdMayBeSmi(class_id_reg, TypeTestABI::kInstanceReg);
    } else {
      __ LoadClassId(class_id_reg, TypeTestABI::kInstanceReg);
    }
    cid_needs_reload = BuildOptimizedSubtypeRangeCheck(
        assembler, cid_checks_only, class_id_reg, &is_subtype, check_failed);
    __ Bind(&is_subtype);
    __ Ret();
    __ Bind(&keep_looking);
  }
  if (!type_argument_checks.is_empty()) {
    GrowableArray<CidRangeVector*> vectors;
    SplitByTypeArgumentsFieldOffset(T, type_class, type_argument_checks,
                                    &vectors);
    ASSERT(vectors.length() > 0);
    ClassTable* const class_table = T->isolate_group()->class_table();
    auto& cls = Class::Handle(Z);
    for (intptr_t i = 0; i < vectors.length(); i++) {
      CidRangeVector* const vector = vectors[i];
      ASSERT(!vector->is_empty());
      const intptr_t first_cid = vector->At(0).cid_start;
      ASSERT(class_table->HasValidClassAt(first_cid));
      cls = class_table->At(first_cid);
      ASSERT(cls.is_finalized());
      const intptr_t tav_offset =
          compiler::target::Class::TypeArgumentsFieldOffset(cls);
      compiler::Label load_tav, keep_looking;
      // For the last vector, just jump to load_failed if the check fails
      // and avoid emitting a jump to load_succeeded.
      compiler::Label* check_failed =
          i < vectors.length() - 1 ? &keep_looking : load_failed;
      if (cid_needs_reload) {
        __ LoadClassId(class_id_reg, TypeTestABI::kInstanceReg);
      }
      cid_needs_reload = BuildOptimizedSubtypeRangeCheck(
          assembler, *vector, class_id_reg, &load_tav, check_failed);
      __ Bind(&load_tav);
      __ LoadCompressedFieldFromOffset(instance_type_args_reg,
                                       TypeTestABI::kInstanceReg, tav_offset);
      if (i < vectors.length() - 1) {
        __ Jump(load_succeeded);
        __ Bind(&keep_looking);
      }
      // Free the CidRangeVector allocated by SplitByTypeArgumentsFieldOffset.
      delete vector;
    }
  }
  if (!not_checked.is_empty()) {
    CommentSkippedClasses(assembler, type, type_class, not_checked);
  }
  return !type_argument_checks.is_empty();
}

void TypeTestingStubGenerator::BuildOptimizedTypeParameterArgumentValueCheck(
    compiler::Assembler* assembler,
    HierarchyInfo* hi,
    const TypeParameter& type_param,
    intptr_t type_param_value_offset_i,
    compiler::Label* check_failed) {
  if (assembler->EmittingComments()) {
    TextBuffer buffer(128);
    buffer.Printf("Generating check for type argument %" Pd ": ",
                  type_param_value_offset_i);
    type_param.PrintName(Object::kScrubbedName, &buffer);
    __ Comment("%s", buffer.buffer());
  }

  const Register kTypeArgumentsReg =
      type_param.IsClassTypeParameter()
          ? TypeTestABI::kInstantiatorTypeArgumentsReg
          : TypeTestABI::kFunctionTypeArgumentsReg;

  const bool strict_null_safety =
      hi->thread()->isolate_group()->use_strict_null_safety_checks();
  compiler::Label is_subtype;
  // TODO(dartbug.com/46920): Currently only canonical equality (identity)
  // and some top and bottom types are checked.
  __ CompareObject(kTypeArgumentsReg, Object::null_object());
  __ BranchIf(EQUAL, &is_subtype);

  __ LoadCompressedFieldFromOffset(
      TTSInternalRegs::kSuperTypeArgumentReg, kTypeArgumentsReg,
      compiler::target::TypeArguments::type_at_offset(type_param.index()));
  __ LoadCompressedFieldFromOffset(
      TTSInternalRegs::kSubTypeArgumentReg,
      TTSInternalRegs::kInstanceTypeArgumentsReg,
      compiler::target::TypeArguments::type_at_offset(
          type_param_value_offset_i));
  __ CompareRegisters(TTSInternalRegs::kSuperTypeArgumentReg,
                      TTSInternalRegs::kSubTypeArgumentReg);
  __ BranchIf(EQUAL, &is_subtype);

  __ Comment("Checking instantiated type parameter for possible top types");
  compiler::Label check_subtype_type_class_ids;
  __ LoadClassId(TTSInternalRegs::kScratchReg,
                 TTSInternalRegs::kSuperTypeArgumentReg);
  __ CompareImmediate(TTSInternalRegs::kScratchReg, kTypeCid);
  __ BranchIf(NOT_EQUAL, &check_subtype_type_class_ids);
  __ LoadTypeClassId(TTSInternalRegs::kScratchReg,
                     TTSInternalRegs::kSuperTypeArgumentReg);
  __ CompareImmediate(TTSInternalRegs::kScratchReg, kDynamicCid);
  __ BranchIf(EQUAL, &is_subtype);
  __ CompareImmediate(TTSInternalRegs::kScratchReg, kVoidCid);
  __ BranchIf(EQUAL, &is_subtype);
  __ CompareImmediate(TTSInternalRegs::kScratchReg, kInstanceCid);
  if (strict_null_safety) {
    __ BranchIf(NOT_EQUAL, &check_subtype_type_class_ids);
    // If non-nullable Object, then the subtype must be legacy or non-nullable.
    __ CompareAbstractTypeNullabilityWith(
        TTSInternalRegs::kSuperTypeArgumentReg,
        static_cast<int8_t>(Nullability::kNonNullable),
        TTSInternalRegs::kScratchReg);
    __ BranchIf(NOT_EQUAL, &is_subtype);
    __ Comment("Checking for legacy or non-nullable instance type argument");
    __ CompareAbstractTypeNullabilityWith(
        TTSInternalRegs::kSubTypeArgumentReg,
        static_cast<int8_t>(Nullability::kNullable),
        TTSInternalRegs::kScratchReg);
    __ BranchIf(EQUAL, check_failed);
    __ Jump(&is_subtype);
  } else {
    __ BranchIf(EQUAL, &is_subtype, compiler::Assembler::kNearJump);
  }

  __ Bind(&check_subtype_type_class_ids);
  __ Comment("Checking instance type argument for possible bottom types");
  // Nothing else to check for non-Types, so fall back to the slow stub.
  __ LoadClassId(TTSInternalRegs::kScratchReg,
                 TTSInternalRegs::kSubTypeArgumentReg);
  __ CompareImmediate(TTSInternalRegs::kScratchReg, kTypeCid);
  __ BranchIf(NOT_EQUAL, check_failed);
  __ LoadTypeClassId(TTSInternalRegs::kScratchReg,
                     TTSInternalRegs::kSubTypeArgumentReg);
  __ CompareImmediate(TTSInternalRegs::kScratchReg, kNeverCid);
  __ BranchIf(EQUAL, &is_subtype);
  __ CompareImmediate(TTSInternalRegs::kScratchReg, kNullCid);
  // Last possible check, so fall back to slow stub on failure.
  __ BranchIf(NOT_EQUAL, check_failed);
  if (strict_null_safety) {
    // Only nullable or legacy types can be a supertype of Null.
    __ Comment("Checking for legacy or nullable instantiated type parameter");
    __ CompareAbstractTypeNullabilityWith(
        TTSInternalRegs::kSuperTypeArgumentReg,
        static_cast<int8_t>(Nullability::kNonNullable),
        TTSInternalRegs::kScratchReg);
    __ BranchIf(EQUAL, check_failed);
  }

  __ Bind(&is_subtype);
}

// Generate code to verify that instance's type argument is a subtype of
// 'type_arg'.
void TypeTestingStubGenerator::BuildOptimizedTypeArgumentValueCheck(
    compiler::Assembler* assembler,
    HierarchyInfo* hi,
    const Type& type,
    intptr_t type_param_value_offset_i,
    compiler::Label* check_failed) {
  ASSERT(type.IsInstantiated());
  if (type.IsTopTypeForSubtyping()) {
    return;
  }

  const bool strict_null_safety =
      hi->thread()->isolate_group()->use_strict_null_safety_checks();
  ASSERT(!type.IsObjectType() || (strict_null_safety && type.IsNonNullable()));

  if (assembler->EmittingComments()) {
    TextBuffer buffer(128);
    buffer.Printf("Generating check for type argument %" Pd ": ",
                  type_param_value_offset_i);
    type.PrintName(Object::kScrubbedName, &buffer);
    __ Comment("%s", buffer.buffer());
  }

  compiler::Label is_subtype, sub_is_type;
  __ LoadCompressedFieldFromOffset(
      TTSInternalRegs::kSubTypeArgumentReg,
      TTSInternalRegs::kInstanceTypeArgumentsReg,
      compiler::target::TypeArguments::type_at_offset(
          type_param_value_offset_i));
  __ LoadClassId(TTSInternalRegs::kScratchReg,
                 TTSInternalRegs::kSubTypeArgumentReg);
  if (type.IsObjectType() || type.IsDartFunctionType() ||
      type.IsDartRecordType()) {
    __ CompareImmediate(TTSInternalRegs::kScratchReg, kTypeCid);
    __ BranchIf(EQUAL, &sub_is_type);
    if (type.IsDartFunctionType()) {
      __ Comment("Checks for Function type");
      __ CompareImmediate(TTSInternalRegs::kScratchReg, kFunctionTypeCid);
      __ BranchIf(NOT_EQUAL, check_failed);
    } else if (type.IsDartRecordType()) {
      __ Comment("Checks for Record type");
      __ CompareImmediate(TTSInternalRegs::kScratchReg, kRecordTypeCid);
      __ BranchIf(NOT_EQUAL, check_failed);
    } else {
      __ Comment("Checks for Object type");
    }
    if (strict_null_safety && type.IsNonNullable()) {
      // Nullable types cannot be a subtype of a non-nullable type.
      __ CompareAbstractTypeNullabilityWith(
          TTSInternalRegs::kSubTypeArgumentReg,
          static_cast<int8_t>(Nullability::kNullable),
          TTSInternalRegs::kScratchReg);
      __ BranchIf(EQUAL, check_failed);
    }
    // No further checks needed for non-nullable Object, Function or Record.
    __ Jump(&is_subtype, compiler::Assembler::kNearJump);
  } else {
    // Don't fall back to cid tests for record and function types. Instead,
    // just let the STC/runtime handle any possible false negatives here.
    __ CompareImmediate(TTSInternalRegs::kScratchReg, kTypeCid);
    __ BranchIf(NOT_EQUAL, check_failed);
  }

  __ Comment("Checks for Type");
  __ Bind(&sub_is_type);
  if (strict_null_safety && type.IsNonNullable()) {
    // Nullable types cannot be a subtype of a non-nullable type in strict mode.
    __ CompareAbstractTypeNullabilityWith(
        TTSInternalRegs::kSubTypeArgumentReg,
        static_cast<int8_t>(Nullability::kNullable),
        TTSInternalRegs::kScratchReg);
    __ BranchIf(EQUAL, check_failed);
    // Fall through to bottom type checks.
  }

  // No further checks needed for non-nullable object.
  if (!type.IsObjectType()) {
    __ LoadTypeClassId(TTSInternalRegs::kScratchReg,
                       TTSInternalRegs::kSubTypeArgumentReg);

    const bool null_is_assignable = Instance::NullIsAssignableTo(type);
    // Check bottom types.
    __ CompareImmediate(TTSInternalRegs::kScratchReg, kNeverCid);
    __ BranchIf(EQUAL, &is_subtype);
    if (null_is_assignable) {
      __ CompareImmediate(TTSInternalRegs::kScratchReg, kNullCid);
      __ BranchIf(EQUAL, &is_subtype);
    }

    // Not a bottom type, so check cid ranges.
    const Class& type_class = Class::Handle(type.type_class());
    const CidRangeVector& ranges =
        hi->SubtypeRangesForClass(type_class,
                                  /*include_abstract=*/true,
                                  /*exclude_null=*/!null_is_assignable);
    BuildOptimizedSubtypeRangeCheck(assembler, ranges,
                                    TTSInternalRegs::kScratchReg, &is_subtype,
                                    check_failed);
  }

  __ Bind(&is_subtype);
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
        TypeArguments::Handle(TypeArguments::RawCast(object.ptr()));
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
      // We try to strengthen this assumption further down by checking the
      // offset of the type argument vector, but generally speaking this could
      // be a false-positive, which is still ok!
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
          Class::Handle(IsolateGroup::Current()->class_table()->At(cid));
      if (load_field->slot().IsTypeArguments() && instance_klass.IsGeneric() &&
          compiler::target::Class::TypeArgumentsFieldOffset(instance_klass) ==
              load_field->slot().offset_in_bytes()) {
        // This is a subset of Case c) above, namely forwarding the type
        // argument vector.
        //
        // We use the declaration type arguments for the instance creation,
        // which is a non-instantiated, expanded, type arguments vector.
        TypeArguments& declaration_type_args = TypeArguments::Handle(
            instance_klass.GetDeclarationInstanceTypeArguments());
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
      TypeArguments& declaration_type_args = TypeArguments::Handle(
          enclosing_class.GetDeclarationInstanceTypeArguments());
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

TypeUsageInfo::TypeUsageInfo(Thread* thread)
    : ThreadStackResource(thread),
      zone_(thread->zone()),
      assert_assignable_types_(),
      instance_creation_arguments_(
          new TypeArgumentsSet
              [thread->isolate_group()->class_table()->NumCids()]),
      klass_(Class::Handle(zone_)) {
  thread->set_type_usage_info(this);
}

TypeUsageInfo::~TypeUsageInfo() {
  thread()->set_type_usage_info(nullptr);
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

    // If this is a non-instantiated [TypeArguments] object, then it refers to
    // type parameters.  We need to ensure the type parameters in [ta] only
    // refer to type parameters in the class.
    if (!ta.IsNull() && !ta.IsInstantiated()) {
      return;
    }

    klass_ = klass.ptr();
    while (klass_.NumTypeArguments() > 0) {
      const intptr_t cid = klass_.id();
      TypeArgumentsSet& set = instance_creation_arguments_[cid];
      if (!set.HasKey(&ta)) {
        set.Insert(&TypeArguments::ZoneHandle(zone_, ta.ptr()));
      }
      klass_ = klass_.SuperClass();
    }
  }
}

void TypeUsageInfo::BuildTypeUsageInformation() {
  ClassTable* class_table = thread()->isolate_group()->class_table();
  const intptr_t cid_count = class_table->NumCids();

  // Step 1) Collect the type parameters we're interested in.
  TypeParameterSet parameters_tested_against;
  CollectTypeParametersUsedInAssertAssignable(&parameters_tested_against);

  // Step 2) Add all types which flow into a type parameter we test against to
  // the set of types tested against.
  UpdateAssertAssignableTypes(class_table, cid_count,
                              &parameters_tested_against);
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
    for (intptr_t i = 0; i < num_parameters; ++i) {
      param = klass.TypeParameterAt(i);
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
    *param ^= type->ptr();
    if (!param->IsNull() && !set->HasKey(param)) {
      set->Insert(&TypeParameter::Handle(zone_, param->ptr()));
    }
  }
}

void TypeUsageInfo::AddTypeToSet(TypeSet* set, const AbstractType* type) {
  if (!set->HasKey(type)) {
    set->Insert(&AbstractType::ZoneHandle(zone_, type->ptr()));
  }
}

bool TypeUsageInfo::IsUsedInTypeTest(const AbstractType& type) {
  if (type.IsFinalized()) {
    return assert_assignable_types_.HasKey(&type);
  }
  return false;
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

void DeoptimizeTypeTestingStubs() {
  class CollectTypes : public ObjectVisitor {
   public:
    CollectTypes(Zone* zone, GrowableArray<AbstractType*>* types)
        : zone_(zone), types_(types), cache_(SubtypeTestCache::Handle(zone)) {}

    void VisitObject(ObjectPtr object) {
      // Only types and record types may have optimized TTSes,
      // see TypeTestingStubGenerator::OptimizedCodeForType.
      if (object->IsType() || object->IsRecordType()) {
        types_->Add(&AbstractType::CheckedHandle(zone_, object));
      } else if (object->IsSubtypeTestCache()) {
        cache_ ^= object;
        cache_.Reset();
      }
    }

   private:
    Zone* const zone_;
    GrowableArray<AbstractType*>* const types_;
    TypeTestingStubGenerator generator_;
    SubtypeTestCache& cache_;
  };

  Thread* thread = Thread::Current();
  TIMELINE_DURATION(thread, Isolate, "DeoptimizeTypeTestingStubs");
  HANDLESCOPE(thread);
  Zone* zone = thread->zone();
  GrowableArray<AbstractType*> types(zone, 0);
  {
    HeapIterationScope iter(thread);
    CollectTypes visitor(zone, &types);
    iter.IterateObjects(&visitor);
  }
  auto& stub = Code::Handle(zone);
  for (auto* const type : types) {
    stub = TypeTestingStubGenerator::DefaultCodeForType(*type);
    type->SetTypeTestingStub(stub);
  }
}

#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
