// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/bytecode_reader.h"

#include "vm/bit_vector.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/code_descriptors.h"
#include "vm/compiler/aot/precompiler.h"  // For Obfuscator
#include "vm/compiler/assembler/disassembler_kbc.h"
#include "vm/compiler/frontend/bytecode_scope_builder.h"
#include "vm/constants_kbc.h"
#include "vm/dart_api_impl.h"  // For Api::IsFfiEnabled().
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/flags.h"
#include "vm/hash.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/reusable_handles.h"
#include "vm/scopes.h"
#include "vm/stack_frame_kbc.h"
#include "vm/timeline.h"

#define Z (zone_)
#define H (translation_helper_)
#define I (translation_helper_.isolate())

namespace dart {

DEFINE_FLAG(bool, dump_kernel_bytecode, false, "Dump kernel bytecode");

namespace kernel {

BytecodeMetadataHelper::BytecodeMetadataHelper(KernelReaderHelper* helper,
                                               ActiveClass* active_class)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ false),
      active_class_(active_class) {}

void BytecodeMetadataHelper::ParseBytecodeFunction(
    ParsedFunction* parsed_function) {
  TIMELINE_DURATION(Thread::Current(), CompilerVerbose,
                    "BytecodeMetadataHelper::ParseBytecodeFunction");

  const Function& function = parsed_function->function();
  ASSERT(function.is_declared_in_bytecode());

  BytecodeComponentData bytecode_component(
      &Array::Handle(helper_->zone_, GetBytecodeComponent()));
  BytecodeReaderHelper bytecode_reader(&H, active_class_, &bytecode_component);

  bytecode_reader.ParseBytecodeFunction(parsed_function, function);
}

bool BytecodeMetadataHelper::ReadLibraries() {
  TIMELINE_DURATION(Thread::Current(), Compiler,
                    "BytecodeMetadataHelper::ReadLibraries");
  ASSERT(Thread::Current()->IsMutatorThread());

  if (translation_helper_.GetBytecodeComponent() == Array::null()) {
    return false;
  }

  BytecodeComponentData bytecode_component(
      &Array::Handle(helper_->zone_, GetBytecodeComponent()));

  BytecodeReaderHelper bytecode_reader(&H, active_class_, &bytecode_component);
  AlternativeReadingScope alt(&bytecode_reader.reader(),
                              bytecode_component.GetLibraryIndexOffset());
  bytecode_reader.ReadLibraryDeclarations(bytecode_component.GetNumLibraries());
  return true;
}

void BytecodeMetadataHelper::ReadLibrary(const Library& library) {
  TIMELINE_DURATION(Thread::Current(), Compiler,
                    "BytecodeMetadataHelper::ReadLibrary");
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(!library.Loaded());

  if (translation_helper_.GetBytecodeComponent() == Array::null()) {
    return;
  }

  BytecodeComponentData bytecode_component(
      &Array::Handle(helper_->zone_, GetBytecodeComponent()));
  BytecodeReaderHelper bytecode_reader(&H, active_class_, &bytecode_component);
  AlternativeReadingScope alt(&bytecode_reader.reader(),
                              bytecode_component.GetLibraryIndexOffset());
  bytecode_reader.FindAndReadSpecificLibrary(
      library, bytecode_component.GetNumLibraries());
}

bool BytecodeMetadataHelper::FindModifiedLibrariesForHotReload(
    BitVector* modified_libs,
    bool* is_empty_program,
    intptr_t* p_num_classes,
    intptr_t* p_num_procedures) {
  ASSERT(Thread::Current()->IsMutatorThread());

  if (translation_helper_.GetBytecodeComponent() == Array::null()) {
    return false;
  }

  BytecodeComponentData bytecode_component(
      &Array::Handle(helper_->zone_, GetBytecodeComponent()));
  BytecodeReaderHelper bytecode_reader(&H, active_class_, &bytecode_component);
  AlternativeReadingScope alt(&bytecode_reader.reader(),
                              bytecode_component.GetLibraryIndexOffset());
  bytecode_reader.FindModifiedLibrariesForHotReload(
      modified_libs, bytecode_component.GetNumLibraries());

  if (is_empty_program != nullptr) {
    *is_empty_program = (bytecode_component.GetNumLibraries() == 0);
  }
  if (p_num_classes != nullptr) {
    *p_num_classes = bytecode_component.GetNumClasses();
  }
  if (p_num_procedures != nullptr) {
    *p_num_procedures = bytecode_component.GetNumCodes();
  }
  return true;
}

LibraryPtr BytecodeMetadataHelper::GetMainLibrary() {
  const intptr_t md_offset = GetComponentMetadataPayloadOffset();
  if (md_offset < 0) {
    return Library::null();
  }

  BytecodeComponentData bytecode_component(
      &Array::Handle(helper_->zone_, GetBytecodeComponent()));
  const intptr_t main_offset = bytecode_component.GetMainOffset();
  if (main_offset == 0) {
    return Library::null();
  }

  BytecodeReaderHelper bytecode_reader(&H, active_class_, &bytecode_component);
  AlternativeReadingScope alt(&bytecode_reader.reader(), main_offset);
  return bytecode_reader.ReadMain();
}

ArrayPtr BytecodeMetadataHelper::GetBytecodeComponent() {
  ArrayPtr array = translation_helper_.GetBytecodeComponent();
  if (array == Array::null()) {
    array = ReadBytecodeComponent();
    ASSERT(array != Array::null());
  }
  return array;
}

ArrayPtr BytecodeMetadataHelper::ReadBytecodeComponent() {
  const intptr_t md_offset = GetComponentMetadataPayloadOffset();
  if (md_offset < 0) {
    return Array::null();
  }

  BytecodeReaderHelper component_reader(&H, nullptr, nullptr);
  return component_reader.ReadBytecodeComponent(md_offset);
}

BytecodeReaderHelper::BytecodeReaderHelper(
    TranslationHelper* translation_helper,
    ActiveClass* active_class,
    BytecodeComponentData* bytecode_component)
    : reader_(translation_helper->metadata_payloads()),
      translation_helper_(*translation_helper),
      active_class_(active_class),
      thread_(translation_helper->thread()),
      zone_(translation_helper->zone()),
      bytecode_component_(bytecode_component),
      scoped_function_(Function::Handle(translation_helper->zone())),
      scoped_function_name_(String::Handle(translation_helper->zone())),
      scoped_function_class_(Class::Handle(translation_helper->zone())) {}

void BytecodeReaderHelper::ReadCode(const Function& function,
                                    intptr_t code_offset) {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(!function.IsImplicitGetterFunction() &&
         !function.IsImplicitSetterFunction());
  if (code_offset == 0) {
    FATAL2("Function %s (kind %s) doesn't have bytecode",
           function.ToFullyQualifiedCString(),
           Function::KindToCString(function.kind()));
  }

  AlternativeReadingScope alt(&reader_, code_offset);
  // This scope is needed to set active_class_->enclosing_ which is used to
  // assign parent function for function types.
  ActiveEnclosingFunctionScope active_enclosing_function(active_class_,
                                                         &function);

  const intptr_t flags = reader_.ReadUInt();
  const bool has_exceptions_table =
      (flags & Code::kHasExceptionsTableFlag) != 0;
  const bool has_source_positions =
      (flags & Code::kHasSourcePositionsFlag) != 0;
  const bool has_local_variables = (flags & Code::kHasLocalVariablesFlag) != 0;
  const bool has_nullable_fields = (flags & Code::kHasNullableFieldsFlag) != 0;
  const bool has_closures = (flags & Code::kHasClosuresFlag) != 0;
  const bool has_parameters_flags = (flags & Code::kHasParameterFlagsFlag) != 0;
  const bool has_forwarding_stub_target =
      (flags & Code::kHasForwardingStubTargetFlag) != 0;
  const bool has_default_function_type_args =
      (flags & Code::kHasDefaultFunctionTypeArgsFlag) != 0;

  if (has_parameters_flags) {
    intptr_t num_params = reader_.ReadUInt();
    ASSERT(num_params ==
           function.NumParameters() - function.NumImplicitParameters());
    for (intptr_t i = function.NumImplicitParameters();
         i < function.NumParameters(); ++i) {
      const intptr_t flags = reader_.ReadUInt();
      if ((flags & Parameter::kIsRequiredFlag) != 0) {
        function.SetIsRequiredAt(i);
      }
    }
  }
  function.TruncateUnusedParameterFlags();
  if (has_forwarding_stub_target) {
    reader_.ReadUInt();
  }
  if (has_default_function_type_args) {
    reader_.ReadUInt();
  }

  intptr_t num_closures = 0;
  if (has_closures) {
    num_closures = reader_.ReadListLength();
    closures_ = &Array::Handle(Z, Array::New(num_closures));
    for (intptr_t i = 0; i < num_closures; i++) {
      ReadClosureDeclaration(function, i);
    }
  }

  // Create object pool and read pool entries.
  const intptr_t obj_count = reader_.ReadListLength();
  const ObjectPool& pool = ObjectPool::Handle(Z, ObjectPool::New(obj_count));
  ReadConstantPool(function, pool, 0);

  // Read bytecode and attach to function.
  const Bytecode& bytecode = Bytecode::Handle(Z, ReadBytecode(pool));
  function.AttachBytecode(bytecode);
  ASSERT(bytecode.GetBinary(Z) == reader_.typed_data()->raw());

  ReadExceptionsTable(bytecode, has_exceptions_table);

  ReadSourcePositions(bytecode, has_source_positions);

  ReadLocalVariables(bytecode, has_local_variables);

  if (FLAG_dump_kernel_bytecode) {
    KernelBytecodeDisassembler::Disassemble(function);
  }

  // Initialization of fields with null literal is elided from bytecode.
  // Record the corresponding stores if field guards are enabled.
  if (has_nullable_fields) {
    ASSERT(function.IsGenerativeConstructor());
    const intptr_t num_fields = reader_.ReadListLength();
    if (I->use_field_guards()) {
      Field& field = Field::Handle(Z);
      for (intptr_t i = 0; i < num_fields; i++) {
        field ^= ReadObject();
        field.RecordStore(Object::null_object());
      }
    } else {
      for (intptr_t i = 0; i < num_fields; i++) {
        ReadObject();
      }
    }
  }

  // Read closures.
  if (has_closures) {
    Function& closure = Function::Handle(Z);
    Bytecode& closure_bytecode = Bytecode::Handle(Z);
    for (intptr_t i = 0; i < num_closures; i++) {
      closure ^= closures_->At(i);

      const intptr_t flags = reader_.ReadUInt();
      const bool has_exceptions_table =
          (flags & ClosureCode::kHasExceptionsTableFlag) != 0;
      const bool has_source_positions =
          (flags & ClosureCode::kHasSourcePositionsFlag) != 0;
      const bool has_local_variables =
          (flags & ClosureCode::kHasLocalVariablesFlag) != 0;

      // Read closure bytecode and attach to closure function.
      closure_bytecode = ReadBytecode(pool);
      closure.AttachBytecode(closure_bytecode);
      ASSERT(bytecode.GetBinary(Z) == reader_.typed_data()->raw());

      ReadExceptionsTable(closure_bytecode, has_exceptions_table);

      ReadSourcePositions(closure_bytecode, has_source_positions);

      ReadLocalVariables(closure_bytecode, has_local_variables);

      if (FLAG_dump_kernel_bytecode) {
        KernelBytecodeDisassembler::Disassemble(closure);
      }

#if !defined(PRODUCT)
      thread_->isolate()->debugger()->NotifyBytecodeLoaded(closure);
#endif
    }
  }

#if !defined(PRODUCT)
  thread_->isolate()->debugger()->NotifyBytecodeLoaded(function);
#endif
}

static intptr_t IndexFor(Zone* zone,
                         const Function& function,
                         const String& name) {
  const Bytecode& bc = Bytecode::Handle(zone, function.bytecode());
  const ObjectPool& pool = ObjectPool::Handle(zone, bc.object_pool());
  const KBCInstr* pc = reinterpret_cast<const KBCInstr*>(bc.PayloadStart());

  ASSERT(KernelBytecode::IsEntryOptionalOpcode(pc));
  ASSERT(KernelBytecode::DecodeB(pc) ==
         function.NumOptionalPositionalParameters());
  ASSERT(KernelBytecode::DecodeC(pc) == function.NumOptionalNamedParameters());
  pc = KernelBytecode::Next(pc);

  const intptr_t num_opt_params = function.NumOptionalParameters();
  const intptr_t num_fixed_params = function.num_fixed_parameters();
  for (intptr_t i = 0; i < num_opt_params; i++) {
    const KBCInstr* load_name = pc;
    const KBCInstr* load_value = KernelBytecode::Next(load_name);
    pc = KernelBytecode::Next(load_value);
    ASSERT(KernelBytecode::IsLoadConstantOpcode(load_name));
    ASSERT(KernelBytecode::IsLoadConstantOpcode(load_value));
    if (pool.ObjectAt(KernelBytecode::DecodeE(load_name)) == name.raw()) {
      return num_fixed_params + i;
    }
  }

  UNREACHABLE();
  return -1;
}

ArrayPtr BytecodeReaderHelper::CreateForwarderChecks(const Function& function) {
  ASSERT(function.kind() != FunctionLayout::kDynamicInvocationForwarder);
  ASSERT(function.is_declared_in_bytecode());

  TypeArguments& default_args = TypeArguments::Handle(Z);
  if (function.bytecode_offset() != 0) {
    AlternativeReadingScope alt(&reader_, function.bytecode_offset());

    const intptr_t flags = reader_.ReadUInt();
    const bool has_parameters_flags =
        (flags & Code::kHasParameterFlagsFlag) != 0;
    const bool has_forwarding_stub_target =
        (flags & Code::kHasForwardingStubTargetFlag) != 0;
    const bool has_default_function_type_args =
        (flags & Code::kHasDefaultFunctionTypeArgsFlag) != 0;

    if (has_parameters_flags) {
      intptr_t num_params = reader_.ReadUInt();
      ASSERT(num_params ==
             function.NumParameters() - function.NumImplicitParameters());
      for (intptr_t i = 0; i < num_params; ++i) {
        reader_.ReadUInt();
      }
    }

    if (has_forwarding_stub_target) {
      reader_.ReadUInt();
    }

    if (has_default_function_type_args) {
      const intptr_t index = reader_.ReadUInt();
      const Bytecode& code = Bytecode::Handle(Z, function.bytecode());
      const ObjectPool& pool = ObjectPool::Handle(Z, code.object_pool());
      default_args ^= pool.ObjectAt(index);
    }
  }

  auto& name = String::Handle(Z);
  auto& check = ParameterTypeCheck::Handle(Z);
  auto& checks = GrowableObjectArray::Handle(Z, GrowableObjectArray::New());

  checks.Add(function);
  checks.Add(default_args);

  const auto& type_params =
      TypeArguments::Handle(Z, function.type_parameters());
  if (!type_params.IsNull()) {
    auto& type_param = TypeParameter::Handle(Z);
    auto& bound = AbstractType::Handle(Z);
    for (intptr_t i = 0, n = type_params.Length(); i < n; ++i) {
      type_param ^= type_params.TypeAt(i);
      bound = type_param.bound();
      if (!bound.IsTopTypeForSubtyping() &&
          !type_param.IsGenericCovariantImpl()) {
        name = type_param.name();
        ASSERT(type_param.IsFinalized());
        check = ParameterTypeCheck::New();
        check.set_param(type_param);
        check.set_type_or_bound(bound);
        check.set_name(name);
        checks.Add(check);
      }
    }
  }

  const intptr_t num_params = function.NumParameters();
  const intptr_t num_pos_params = function.HasOptionalNamedParameters()
                                      ? function.num_fixed_parameters()
                                      : num_params;

  BitVector is_covariant(Z, num_params);
  BitVector is_generic_covariant_impl(Z, num_params);
  ReadParameterCovariance(function, &is_covariant, &is_generic_covariant_impl);

  auto& type = AbstractType::Handle(Z);
  auto& cache = SubtypeTestCache::Handle(Z);
  const bool has_optional_parameters = function.HasOptionalParameters();
  for (intptr_t i = function.NumImplicitParameters(); i < num_params; ++i) {
    type = function.ParameterTypeAt(i);
    if (!type.IsTopTypeForSubtyping() &&
        !is_generic_covariant_impl.Contains(i) && !is_covariant.Contains(i)) {
      name = function.ParameterNameAt(i);
      intptr_t index;
      if (i >= num_pos_params) {
        // Named parameter.
        index = IndexFor(Z, function, name);
      } else if (has_optional_parameters) {
        // Fixed or optional parameter.
        index = i;
      } else {
        // Fixed parameter.
        index = -kKBCParamEndSlotFromFp - num_params + i;
      }
      check = ParameterTypeCheck::New();
      check.set_index(index);
      check.set_type_or_bound(type);
      check.set_name(name);
      cache = SubtypeTestCache::New();
      check.set_cache(cache);
      checks.Add(check);
    }
  }

  return Array::MakeFixedLength(checks);
}

void BytecodeReaderHelper::ReadClosureDeclaration(const Function& function,
                                                  intptr_t closureIndex) {
  // Closure flags, must be in sync with ClosureDeclaration constants in
  // pkg/vm/lib/bytecode/declarations.dart.
  const int kHasOptionalPositionalParamsFlag = 1 << 0;
  const int kHasOptionalNamedParamsFlag = 1 << 1;
  const int kHasTypeParamsFlag = 1 << 2;
  const int kHasSourcePositionsFlag = 1 << 3;
  const int kIsAsyncFlag = 1 << 4;
  const int kIsAsyncStarFlag = 1 << 5;
  const int kIsSyncStarFlag = 1 << 6;
  const int kIsDebuggableFlag = 1 << 7;
  const int kHasAttributesFlag = 1 << 8;
  const int kHasParameterFlagsFlag = 1 << 9;

  const intptr_t flags = reader_.ReadUInt();

  Object& parent = Object::Handle(Z, ReadObject());
  if (!parent.IsFunction()) {
    ASSERT(parent.IsField());
    ASSERT(function.kind() == FunctionLayout::kFieldInitializer);
    // Closure in a static field initializer, so use current function as parent.
    parent = function.raw();
  }

  String& name = String::CheckedHandle(Z, ReadObject());
  ASSERT(name.IsSymbol());

  TokenPosition position = TokenPosition::kNoSource;
  TokenPosition end_position = TokenPosition::kNoSource;
  if ((flags & kHasSourcePositionsFlag) != 0) {
    position = reader_.ReadPosition();
    end_position = reader_.ReadPosition();
  }

  const Function& closure = Function::Handle(
      Z, Function::NewClosureFunction(name, Function::Cast(parent), position));

  closure.set_is_declared_in_bytecode(true);
  closure.set_end_token_pos(end_position);

  if ((flags & kIsSyncStarFlag) != 0) {
    closure.set_modifier(FunctionLayout::kSyncGen);
  } else if ((flags & kIsAsyncFlag) != 0) {
    closure.set_modifier(FunctionLayout::kAsync);
    closure.set_is_inlinable(!FLAG_causal_async_stacks &&
                             !FLAG_lazy_async_stacks);
  } else if ((flags & kIsAsyncStarFlag) != 0) {
    closure.set_modifier(FunctionLayout::kAsyncGen);
    closure.set_is_inlinable(!FLAG_causal_async_stacks &&
                             !FLAG_lazy_async_stacks);
  }
  if (Function::Cast(parent).IsAsyncOrGenerator()) {
    closure.set_is_generated_body(true);
  }
  closure.set_is_debuggable((flags & kIsDebuggableFlag) != 0);

  closures_->SetAt(closureIndex, closure);

  Type& signature_type = Type::Handle(
      Z, ReadFunctionSignature(
             closure, (flags & kHasOptionalPositionalParamsFlag) != 0,
             (flags & kHasOptionalNamedParamsFlag) != 0,
             (flags & kHasTypeParamsFlag) != 0,
             /* has_positional_param_names = */ true,
             (flags & kHasParameterFlagsFlag) != 0, Nullability::kNonNullable));

  closure.SetSignatureType(signature_type);

  if ((flags & kHasAttributesFlag) != 0) {
    ReadAttributes(closure);
  }

  I->AddClosureFunction(closure);
}

static bool IsNonCanonical(const AbstractType& type) {
  return type.IsTypeRef() || (type.IsType() && !type.IsCanonical());
}

static bool HasNonCanonicalTypes(Zone* zone, const Function& func) {
  auto& type = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < func.NumParameters(); ++i) {
    type = func.ParameterTypeAt(i);
    if (IsNonCanonical(type)) {
      return true;
    }
  }
  type = func.result_type();
  if (IsNonCanonical(type)) {
    return true;
  }
  const auto& type_params = TypeArguments::Handle(zone, func.type_parameters());
  if (!type_params.IsNull()) {
    for (intptr_t i = 0; i < type_params.Length(); ++i) {
      type = type_params.TypeAt(i);
      type = TypeParameter::Cast(type).bound();
      if (IsNonCanonical(type)) {
        return true;
      }
    }
  }
  return false;
}

TypePtr BytecodeReaderHelper::ReadFunctionSignature(
    const Function& func,
    bool has_optional_positional_params,
    bool has_optional_named_params,
    bool has_type_params,
    bool has_positional_param_names,
    bool has_parameter_flags,
    Nullability nullability) {
  FunctionTypeScope function_type_scope(this);

  if (has_type_params) {
    ReadTypeParametersDeclaration(Class::Handle(Z), func);
  }

  const intptr_t kImplicitClosureParam = 1;
  const intptr_t num_params = kImplicitClosureParam + reader_.ReadUInt();

  intptr_t num_required_params = num_params;
  if (has_optional_positional_params || has_optional_named_params) {
    num_required_params = kImplicitClosureParam + reader_.ReadUInt();
  }

  func.set_num_fixed_parameters(num_required_params);
  func.SetNumOptionalParameters(num_params - num_required_params,
                                !has_optional_named_params);
  const Array& parameter_types =
      Array::Handle(Z, Array::New(num_params, Heap::kOld));
  func.set_parameter_types(parameter_types);
  const Array& parameter_names = Array::Handle(
      Z, Array::New(Function::NameArrayLengthIncludingFlags(num_params),
                    Heap::kOld));
  func.set_parameter_names(parameter_names);

  intptr_t i = 0;
  parameter_types.SetAt(i, AbstractType::dynamic_type());
  parameter_names.SetAt(i, Symbols::ClosureParameter());
  ++i;

  AbstractType& type = AbstractType::Handle(Z);
  String& name = String::Handle(Z);
  for (; i < num_params; ++i) {
    if (has_positional_param_names ||
        (has_optional_named_params && (i >= num_required_params))) {
      name ^= ReadObject();
    } else {
      name = Symbols::NotNamed().raw();
    }
    parameter_names.SetAt(i, name);
    type ^= ReadObject();
    parameter_types.SetAt(i, type);
  }
  if (has_parameter_flags) {
    intptr_t num_flags = reader_.ReadUInt();
    for (intptr_t i = 0; i < num_flags; ++i) {
      intptr_t flag = reader_.ReadUInt();
      if ((flag & Parameter::kIsRequiredFlag) != 0) {
        func.SetIsRequiredAt(kImplicitClosureParam + i);
      }
    }
  }
  func.TruncateUnusedParameterFlags();

  type ^= ReadObject();
  func.set_result_type(type);

  // Finalize function type.
  type = func.SignatureType(nullability);
  ClassFinalizer::FinalizationKind finalization = ClassFinalizer::kCanonicalize;
  if (pending_recursive_types_ != nullptr && HasNonCanonicalTypes(Z, func)) {
    // This function type is a part of recursive type. Avoid canonicalization
    // as not all TypeRef objects are filled up at this point.
    finalization = ClassFinalizer::kFinalize;
  }
  type =
      ClassFinalizer::FinalizeType(*(active_class_->klass), type, finalization);
  return Type::Cast(type).raw();
}

void BytecodeReaderHelper::ReadTypeParametersDeclaration(
    const Class& parameterized_class,
    const Function& parameterized_function) {
  ASSERT(parameterized_class.IsNull() != parameterized_function.IsNull());

  const intptr_t num_type_params = reader_.ReadUInt();
  ASSERT(num_type_params > 0);

  intptr_t offset;
  NNBDMode nnbd_mode;
  if (!parameterized_class.IsNull()) {
    offset = parameterized_class.NumTypeArguments() - num_type_params;
    nnbd_mode = parameterized_class.nnbd_mode();
  } else {
    offset = parameterized_function.NumParentTypeParameters();
    nnbd_mode = parameterized_function.nnbd_mode();
  }
  const Nullability nullability = (nnbd_mode == NNBDMode::kOptedInLib)
                                      ? Nullability::kNonNullable
                                      : Nullability::kLegacy;

  // First setup the type parameters, so if any of the following code uses it
  // (in a recursive way) we're fine.
  //
  // Step a) Create array of [TypeParameter] objects (without bound).
  const TypeArguments& type_parameters =
      TypeArguments::Handle(Z, TypeArguments::New(num_type_params));
  String& name = String::Handle(Z);
  TypeParameter& parameter = TypeParameter::Handle(Z);
  AbstractType& bound = AbstractType::Handle(Z);
  for (intptr_t i = 0; i < num_type_params; ++i) {
    name ^= ReadObject();
    ASSERT(name.IsSymbol());
    parameter = TypeParameter::New(parameterized_class, parameterized_function,
                                   i, name, bound,
                                   /* is_generic_covariant_impl = */ false,
                                   nullability, TokenPosition::kNoSource);
    parameter.set_index(offset + i);
    parameter.SetIsFinalized();
    parameter.SetCanonical();
    parameter.SetDeclaration(true);
    type_parameters.SetTypeAt(i, parameter);
  }

  if (!parameterized_class.IsNull()) {
    parameterized_class.set_type_parameters(type_parameters);
  } else if (!parameterized_function.IsFactory()) {
    // Do not set type parameters for factories, as VM uses class type
    // parameters instead.
    parameterized_function.set_type_parameters(type_parameters);
    if (parameterized_function.IsSignatureFunction()) {
      if (function_type_type_parameters_ == nullptr) {
        function_type_type_parameters_ = &type_parameters;
      } else {
        function_type_type_parameters_ = &TypeArguments::Handle(
            Z, function_type_type_parameters_->ConcatenateTypeParameters(
                   Z, type_parameters));
      }
    } else {
      ASSERT(function_type_type_parameters_ == nullptr);
    }
  }

  // Step b) Fill in the bounds of all [TypeParameter]s.
  for (intptr_t i = 0; i < num_type_params; ++i) {
    parameter ^= type_parameters.TypeAt(i);
    bound ^= ReadObject();
    // Convert dynamic to Object? or Object* in bounds of type parameters so
    // they are equivalent when doing subtype checks for function types.
    // TODO(https://github.com/dart-lang/language/issues/495): revise this
    // when function subtyping is fixed.
    if (bound.IsDynamicType()) {
      bound = nnbd_mode == NNBDMode::kOptedInLib
                  ? I->object_store()->nullable_object_type()
                  : I->object_store()->legacy_object_type();
    }
    parameter.set_bound(bound);
  }

  // Fix bounds in all derived type parameters (with different nullabilities).
  if (active_class_->derived_type_parameters != nullptr) {
    auto& derived = TypeParameter::Handle(Z);
    auto& bound = AbstractType::Handle(Z);
    for (intptr_t i = 0, n = active_class_->derived_type_parameters->Length();
         i < n; ++i) {
      derived ^= active_class_->derived_type_parameters->At(i);
      if (derived.bound() == AbstractType::null() &&
          ((!parameterized_class.IsNull() &&
            derived.parameterized_class() == parameterized_class.raw()) ||
           (!parameterized_function.IsNull() &&
            derived.parameterized_function() ==
                parameterized_function.raw()))) {
        ASSERT(derived.IsFinalized());
        parameter ^= type_parameters.TypeAt(derived.index() - offset);
        bound = parameter.bound();
        derived.set_bound(bound);
      }
    }
  }
}

intptr_t BytecodeReaderHelper::ReadConstantPool(const Function& function,
                                                const ObjectPool& pool,
                                                intptr_t start_index) {
  TIMELINE_DURATION(Thread::Current(), CompilerVerbose,
                    "BytecodeReaderHelper::ReadConstantPool");

  // These enums and the code below reading the constant pool from kernel must
  // be kept in sync with pkg/vm/lib/bytecode/constant_pool.dart.
  enum ConstantPoolTag {
    kInvalid,
    kUnused1,
    kUnused2,
    kUnused3,
    kUnused4,
    kUnused5,
    kUnused6,
    kUnused6a,
    kUnused7,
    kStaticField,
    kInstanceField,
    kClass,
    kTypeArgumentsField,
    kUnused8,
    kType,
    kUnused9,
    kUnused10,
    kUnused11,
    kUnused12,
    kClosureFunction,
    kEndClosureFunctionScope,
    kNativeEntry,
    kSubtypeTestCache,
    kUnused13,
    kEmptyTypeArguments,
    kUnused14,
    kUnused15,
    kObjectRef,
    kDirectCall,
    kInterfaceCall,
    kInstantiatedInterfaceCall,
    kDynamicCall,
    kDirectCallViaDynamicForwarder,
  };

  Object& obj = Object::Handle(Z);
  Object& elem = Object::Handle(Z);
  Field& field = Field::Handle(Z);
  Class& cls = Class::Handle(Z);
  String& name = String::Handle(Z);
  const intptr_t obj_count = pool.Length();
  for (intptr_t i = start_index; i < obj_count; ++i) {
    const intptr_t tag = reader_.ReadTag();
    switch (tag) {
      case ConstantPoolTag::kInvalid:
        UNREACHABLE();
      case ConstantPoolTag::kStaticField:
        obj = ReadObject();
        ASSERT(obj.IsField());
        break;
      case ConstantPoolTag::kInstanceField:
        field ^= ReadObject();
        // InstanceField constant occupies 2 entries.
        // The first entry is used for field offset.
        obj = Smi::New(field.HostOffset() / kWordSize);
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, obj);
        ++i;
        ASSERT(i < obj_count);
        // The second entry is used for field object.
        obj = field.raw();
        break;
      case ConstantPoolTag::kClass:
        obj = ReadObject();
        ASSERT(obj.IsClass());
        break;
      case ConstantPoolTag::kTypeArgumentsField:
        cls ^= ReadObject();
        obj = Smi::New(cls.host_type_arguments_field_offset() / kWordSize);
        break;
      case ConstantPoolTag::kType:
        obj = ReadObject();
        ASSERT(obj.IsAbstractType());
        break;
      case ConstantPoolTag::kClosureFunction: {
        intptr_t closure_index = reader_.ReadUInt();
        obj = closures_->At(closure_index);
        ASSERT(obj.IsFunction());
        // Set current entry.
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, obj);

        // This scope is needed to set active_class_->enclosing_ which is used
        // to assign parent function for function types.
        ActiveEnclosingFunctionScope active_enclosing_function(
            active_class_, &Function::Cast(obj));

        // Read constant pool until corresponding EndClosureFunctionScope.
        i = ReadConstantPool(function, pool, i + 1);

        // Proceed with the rest of entries.
        continue;
      }
      case ConstantPoolTag::kEndClosureFunctionScope: {
        // EndClosureFunctionScope entry is not used and set to null.
        obj = Object::null();
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, obj);
        return i;
      }
      case ConstantPoolTag::kNativeEntry: {
        name = ReadString();
        obj = NativeEntry(function, name);
        pool.SetTypeAt(i, ObjectPool::EntryType::kNativeEntryData,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, obj);
        continue;
      }
      case ConstantPoolTag::kSubtypeTestCache: {
        obj = SubtypeTestCache::New();
      } break;
      case ConstantPoolTag::kEmptyTypeArguments:
        obj = Object::empty_type_arguments().raw();
        break;
      case ConstantPoolTag::kObjectRef:
        obj = ReadObject();
        break;
      case ConstantPoolTag::kDirectCall: {
        // DirectCall constant occupies 2 entries.
        // The first entry is used for target function.
        obj = ReadObject();
        ASSERT(obj.IsFunction());
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, obj);
        ++i;
        ASSERT(i < obj_count);
        // The second entry is used for arguments descriptor.
        obj = ReadObject();
      } break;
      case ConstantPoolTag::kInterfaceCall: {
        elem = ReadObject();
        ASSERT(elem.IsFunction());
        // InterfaceCall constant occupies 2 entries.
        // The first entry is used for interface target.
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, elem);
        ++i;
        ASSERT(i < obj_count);
        // The second entry is used for arguments descriptor.
        obj = ReadObject();
      } break;
      case ConstantPoolTag::kInstantiatedInterfaceCall: {
        elem = ReadObject();
        ASSERT(elem.IsFunction());
        // InstantiatedInterfaceCall constant occupies 3 entries:
        // 1) Interface target.
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, elem);
        ++i;
        ASSERT(i < obj_count);
        // 2) Arguments descriptor.
        obj = ReadObject();
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, obj);
        ++i;
        ASSERT(i < obj_count);
        // 3) Static receiver type.
        obj = ReadObject();
      } break;
      case ConstantPoolTag::kDynamicCall: {
        name ^= ReadObject();
        ASSERT(name.IsSymbol());
        // Do not mangle ==:
        //   * operator == takes an Object so it is either not checked or
        //     checked at the entry because the parameter is marked covariant,
        //     neither of those cases require a dynamic invocation forwarder
        if (!Field::IsGetterName(name) &&
            (name.raw() != Symbols::EqualOperator().raw())) {
          name = Function::CreateDynamicInvocationForwarderName(name);
        }
        // DynamicCall constant occupies 2 entries: selector and arguments
        // descriptor.
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, name);
        ++i;
        ASSERT(i < obj_count);
        // The second entry is used for arguments descriptor.
        obj = ReadObject();
      } break;
      case ConstantPoolTag::kDirectCallViaDynamicForwarder: {
        // DirectCallViaDynamicForwarder constant occupies 2 entries.
        // The first entry is used for target function.
        obj = ReadObject();
        ASSERT(obj.IsFunction());
        name = Function::Cast(obj).name();
        name = Function::CreateDynamicInvocationForwarderName(name);
        obj = Function::Cast(obj).GetDynamicInvocationForwarder(name);

        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, obj);
        ++i;
        ASSERT(i < obj_count);
        // The second entry is used for arguments descriptor.
        obj = ReadObject();
      } break;
      default:
        UNREACHABLE();
    }
    pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                   ObjectPool::Patchability::kNotPatchable);
    pool.SetObjectAt(i, obj);
  }

  return obj_count - 1;
}

BytecodePtr BytecodeReaderHelper::ReadBytecode(const ObjectPool& pool) {
#if defined(SUPPORT_TIMELINE)
  TIMELINE_DURATION(Thread::Current(), CompilerVerbose,
                    "BytecodeReaderHelper::ReadBytecode");
#endif  // defined(SUPPORT_TIMELINE)
  const intptr_t size = reader_.ReadUInt();
  const intptr_t offset = reader_.offset();

  const uint8_t* data = reader_.BufferAt(offset);
  reader_.set_offset(offset + size);

  // Create and return bytecode object.
  return Bytecode::New(reinterpret_cast<uword>(data), size, offset, pool);
}

void BytecodeReaderHelper::ReadExceptionsTable(const Bytecode& bytecode,
                                               bool has_exceptions_table) {
#if defined(SUPPORT_TIMELINE)
  TIMELINE_DURATION(Thread::Current(), CompilerVerbose,
                    "BytecodeReaderHelper::ReadExceptionsTable");
#endif

  const intptr_t try_block_count =
      has_exceptions_table ? reader_.ReadListLength() : 0;
  if (try_block_count > 0) {
    const ObjectPool& pool = ObjectPool::Handle(Z, bytecode.object_pool());
    AbstractType& handler_type = AbstractType::Handle(Z);
    Array& handler_types = Array::Handle(Z);
    DescriptorList* pc_descriptors_list = new (Z) DescriptorList(64);
    ExceptionHandlerList* exception_handlers_list =
        new (Z) ExceptionHandlerList();

    // Encoding of ExceptionsTable is described in
    // pkg/vm/lib/bytecode/exceptions.dart.
    for (intptr_t try_index = 0; try_index < try_block_count; try_index++) {
      intptr_t outer_try_index_plus1 = reader_.ReadUInt();
      intptr_t outer_try_index = outer_try_index_plus1 - 1;
      // PcDescriptors are expressed in terms of return addresses.
      intptr_t start_pc =
          KernelBytecode::BytecodePcToOffset(reader_.ReadUInt(),
                                             /* is_return_address = */ true);
      intptr_t end_pc =
          KernelBytecode::BytecodePcToOffset(reader_.ReadUInt(),
                                             /* is_return_address = */ true);
      intptr_t handler_pc =
          KernelBytecode::BytecodePcToOffset(reader_.ReadUInt(),
                                             /* is_return_address = */ false);
      uint8_t flags = reader_.ReadByte();
      const uint8_t kFlagNeedsStackTrace = 1 << 0;
      const uint8_t kFlagIsSynthetic = 1 << 1;
      const bool needs_stacktrace = (flags & kFlagNeedsStackTrace) != 0;
      const bool is_generated = (flags & kFlagIsSynthetic) != 0;
      intptr_t type_count = reader_.ReadListLength();
      ASSERT(type_count > 0);
      handler_types = Array::New(type_count, Heap::kOld);
      for (intptr_t i = 0; i < type_count; i++) {
        intptr_t type_index = reader_.ReadUInt();
        ASSERT(type_index < pool.Length());
        handler_type ^= pool.ObjectAt(type_index);
        handler_types.SetAt(i, handler_type);
      }
      pc_descriptors_list->AddDescriptor(
          PcDescriptorsLayout::kOther, start_pc, DeoptId::kNone,
          TokenPosition::kNoSource, try_index,
          PcDescriptorsLayout::kInvalidYieldIndex);
      pc_descriptors_list->AddDescriptor(
          PcDescriptorsLayout::kOther, end_pc, DeoptId::kNone,
          TokenPosition::kNoSource, try_index,
          PcDescriptorsLayout::kInvalidYieldIndex);

      // The exception handler keeps a zone handle of the types array, rather
      // than a raw pointer. Do not share the handle across iterations to avoid
      // clobbering the array.
      exception_handlers_list->AddHandler(
          try_index, outer_try_index, handler_pc, is_generated,
          Array::ZoneHandle(Z, handler_types.raw()), needs_stacktrace);
    }
    const PcDescriptors& descriptors = PcDescriptors::Handle(
        Z, pc_descriptors_list->FinalizePcDescriptors(bytecode.PayloadStart()));
    bytecode.set_pc_descriptors(descriptors);
    const ExceptionHandlers& handlers = ExceptionHandlers::Handle(
        Z, exception_handlers_list->FinalizeExceptionHandlers(
               bytecode.PayloadStart()));
    bytecode.set_exception_handlers(handlers);
  } else {
    bytecode.set_pc_descriptors(Object::empty_descriptors());
    bytecode.set_exception_handlers(Object::empty_exception_handlers());
  }
}

void BytecodeReaderHelper::ReadSourcePositions(const Bytecode& bytecode,
                                               bool has_source_positions) {
  if (!has_source_positions) {
    return;
  }

  intptr_t offset = reader_.ReadUInt();
  bytecode.set_source_positions_binary_offset(
      bytecode_component_->GetSourcePositionsOffset() + offset);
}

void BytecodeReaderHelper::ReadLocalVariables(const Bytecode& bytecode,
                                              bool has_local_variables) {
  if (!has_local_variables) {
    return;
  }

  const intptr_t offset = reader_.ReadUInt();
  bytecode.set_local_variables_binary_offset(
      bytecode_component_->GetLocalVariablesOffset() + offset);
}

TypedDataPtr BytecodeReaderHelper::NativeEntry(const Function& function,
                                               const String& external_name) {
  MethodRecognizer::Kind kind = function.recognized_kind();
  // This list of recognized methods must be kept in sync with the list of
  // methods handled specially by the NativeCall bytecode in the interpreter.
  switch (kind) {
    case MethodRecognizer::kObjectEquals:
    case MethodRecognizer::kStringBaseLength:
    case MethodRecognizer::kStringBaseIsEmpty:
    case MethodRecognizer::kGrowableArrayLength:
    case MethodRecognizer::kObjectArrayLength:
    case MethodRecognizer::kImmutableArrayLength:
    case MethodRecognizer::kTypedListLength:
    case MethodRecognizer::kTypedListViewLength:
    case MethodRecognizer::kByteDataViewLength:
    case MethodRecognizer::kByteDataViewOffsetInBytes:
    case MethodRecognizer::kTypedDataViewOffsetInBytes:
    case MethodRecognizer::kByteDataViewTypedData:
    case MethodRecognizer::kTypedDataViewTypedData:
    case MethodRecognizer::kClassIDgetID:
    case MethodRecognizer::kGrowableArrayCapacity:
    case MethodRecognizer::kListFactory:
    case MethodRecognizer::kObjectArrayAllocate:
    case MethodRecognizer::kLinkedHashMap_getIndex:
    case MethodRecognizer::kLinkedHashMap_setIndex:
    case MethodRecognizer::kLinkedHashMap_getData:
    case MethodRecognizer::kLinkedHashMap_setData:
    case MethodRecognizer::kLinkedHashMap_getHashMask:
    case MethodRecognizer::kLinkedHashMap_setHashMask:
    case MethodRecognizer::kLinkedHashMap_getUsedData:
    case MethodRecognizer::kLinkedHashMap_setUsedData:
    case MethodRecognizer::kLinkedHashMap_getDeletedKeys:
    case MethodRecognizer::kLinkedHashMap_setDeletedKeys:
    case MethodRecognizer::kFfiAbi:
      break;
    case MethodRecognizer::kAsyncStackTraceHelper:
      // If causal async stacks are disabled the interpreter.cc will handle this
      // native call specially.
      if (!FLAG_causal_async_stacks) {
        break;
      }
      FALL_THROUGH;
    default:
      kind = MethodRecognizer::kUnknown;
  }
  NativeFunctionWrapper trampoline = NULL;
  NativeFunction native_function = NULL;
  intptr_t argc_tag = 0;
  if (kind == MethodRecognizer::kUnknown) {
    if (!FLAG_link_natives_lazily) {
      const Class& cls = Class::Handle(Z, function.Owner());
      const Library& library = Library::Handle(Z, cls.library());
      Dart_NativeEntryResolver resolver = library.native_entry_resolver();
      const bool is_bootstrap_native = Bootstrap::IsBootstrapResolver(resolver);
      const int num_params =
          NativeArguments::ParameterCountForResolution(function);
      bool is_auto_scope = true;
      native_function = NativeEntry::ResolveNative(library, external_name,
                                                   num_params, &is_auto_scope);
      if (native_function == nullptr) {
        Report::MessageF(Report::kError, Script::Handle(function.script()),
                         function.token_pos(), Report::AtLocation,
                         "native function '%s' (%" Pd
                         " arguments) cannot be found",
                         external_name.ToCString(), function.NumParameters());
      }
      if (is_bootstrap_native) {
        trampoline = &NativeEntry::BootstrapNativeCallWrapper;
      } else if (is_auto_scope) {
        trampoline = &NativeEntry::AutoScopeNativeCallWrapper;
      } else {
        trampoline = &NativeEntry::NoScopeNativeCallWrapper;
      }
    }
    argc_tag = NativeArguments::ComputeArgcTag(function);
  }
  return NativeEntryData::New(kind, trampoline, native_function, argc_tag);
}

ArrayPtr BytecodeReaderHelper::ReadBytecodeComponent(intptr_t md_offset) {
  ASSERT(Thread::Current()->IsMutatorThread());

  AlternativeReadingScope alt(&reader_, md_offset);

  const intptr_t start_offset = reader_.offset();

  intptr_t magic = reader_.ReadUInt32();
  if (magic != KernelBytecode::kMagicValue) {
    FATAL1("Unexpected Dart bytecode magic %" Px, magic);
  }

  const intptr_t version = reader_.ReadUInt32();
  if ((version < KernelBytecode::kMinSupportedBytecodeFormatVersion) ||
      (version > KernelBytecode::kMaxSupportedBytecodeFormatVersion)) {
    FATAL3("Unsupported Dart bytecode format version %" Pd
           ". "
           "This version of Dart VM supports bytecode format versions from %" Pd
           " to %" Pd ".",
           version, KernelBytecode::kMinSupportedBytecodeFormatVersion,
           KernelBytecode::kMaxSupportedBytecodeFormatVersion);
  }

  reader_.ReadUInt32();  // Skip stringTable.numItems
  const intptr_t string_table_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip objectTable.numItems
  const intptr_t object_table_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip main.numItems
  const intptr_t main_offset = start_offset + reader_.ReadUInt32();

  const intptr_t num_libraries = reader_.ReadUInt32();
  const intptr_t library_index_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip libraries.numItems
  const intptr_t libraries_offset = start_offset + reader_.ReadUInt32();

  const intptr_t num_classes = reader_.ReadUInt32();
  const intptr_t classes_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip members.numItems
  const intptr_t members_offset = start_offset + reader_.ReadUInt32();

  const intptr_t num_codes = reader_.ReadUInt32();
  const intptr_t codes_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip sourcePositions.numItems
  const intptr_t source_positions_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip sourceFiles.numItems
  const intptr_t source_files_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip lineStarts.numItems
  const intptr_t line_starts_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip localVariables.numItems
  const intptr_t local_variables_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip annotations.numItems
  const intptr_t annotations_offset = start_offset + reader_.ReadUInt32();

  const intptr_t num_protected_names = reader_.ReadUInt32();
  const intptr_t protected_names_offset = start_offset + reader_.ReadUInt32();

  // Read header of string table.
  reader_.set_offset(string_table_offset);
  const intptr_t num_one_byte_strings = reader_.ReadUInt32();
  const intptr_t num_two_byte_strings = reader_.ReadUInt32();
  const intptr_t strings_contents_offset =
      reader_.offset() + (num_one_byte_strings + num_two_byte_strings) * 4;

  // Read header of object table.
  reader_.set_offset(object_table_offset);
  const intptr_t num_objects = reader_.ReadUInt();
  const intptr_t objects_size = reader_.ReadUInt();

  // Skip over contents of objects.
  const intptr_t objects_contents_offset = reader_.offset();
  const intptr_t object_offsets_offset = objects_contents_offset + objects_size;
  reader_.set_offset(object_offsets_offset);

  auto& bytecode_component_array = Array::Handle(
      Z,
      BytecodeComponentData::New(
          Z, version, num_objects, string_table_offset, strings_contents_offset,
          object_offsets_offset, objects_contents_offset, main_offset,
          num_libraries, library_index_offset, libraries_offset, num_classes,
          classes_offset, members_offset, num_codes, codes_offset,
          source_positions_offset, source_files_offset, line_starts_offset,
          local_variables_offset, annotations_offset, Heap::kOld));

  BytecodeComponentData bytecode_component(&bytecode_component_array);

  // Read object offsets.
  Smi& offs = Smi::Handle(Z);
  for (intptr_t i = 0; i < num_objects; ++i) {
    offs = Smi::New(reader_.ReadUInt());
    bytecode_component.SetObject(i, offs);
  }

  // Read protected names.
  if (I->obfuscate() && (num_protected_names > 0)) {
    bytecode_component_ = &bytecode_component;

    reader_.set_offset(protected_names_offset);
    Obfuscator obfuscator(thread_, Object::null_string());
    auto& name = String::Handle(Z);
    for (intptr_t i = 0; i < num_protected_names; ++i) {
      name = ReadString();
      obfuscator.PreventRenaming(name);
    }

    bytecode_component_ = nullptr;
  }

  H.SetBytecodeComponent(bytecode_component_array);

  return bytecode_component_array.raw();
}

void BytecodeReaderHelper::ResetObjects() {
  reader_.set_offset(bytecode_component_->GetObjectOffsetsOffset());
  const intptr_t num_objects = bytecode_component_->GetNumObjects();

  // Read object offsets.
  Smi& offs = Smi::Handle(Z);
  for (intptr_t i = 0; i < num_objects; ++i) {
    offs = Smi::New(reader_.ReadUInt());
    bytecode_component_->SetObject(i, offs);
  }
}

ObjectPtr BytecodeReaderHelper::ReadObject() {
  uint32_t header = reader_.ReadUInt();
  if ((header & kReferenceBit) != 0) {
    intptr_t index = header >> kIndexShift;
    if (index == 0) {
      return Object::null();
    }
    ObjectPtr obj = bytecode_component_->GetObject(index);
    if (obj->IsHeapObject()) {
      return obj;
    }
    // Object is not loaded yet.
    intptr_t offset = bytecode_component_->GetObjectsContentsOffset() +
                      Smi::Value(Smi::RawCast(obj));
    AlternativeReadingScope alt(&reader_, offset);
    header = reader_.ReadUInt();

    obj = ReadObjectContents(header);
    ASSERT(obj->IsHeapObject());
    {
      REUSABLE_OBJECT_HANDLESCOPE(thread_);
      Object& obj_handle = thread_->ObjectHandle();
      obj_handle = obj;
      bytecode_component_->SetObject(index, obj_handle);
    }
    return obj;
  }

  return ReadObjectContents(header);
}

StringPtr BytecodeReaderHelper::ConstructorName(const Class& cls,
                                                const String& name) {
  GrowableHandlePtrArray<const String> pieces(Z, 3);
  pieces.Add(String::Handle(Z, cls.Name()));
  pieces.Add(Symbols::Dot());
  pieces.Add(name);
  return Symbols::FromConcatAll(thread_, pieces);
}

ObjectPtr BytecodeReaderHelper::ReadObjectContents(uint32_t header) {
  ASSERT(((header & kReferenceBit) == 0));

  // Must be in sync with enum ObjectKind in
  // pkg/vm/lib/bytecode/object_table.dart.
  enum ObjectKind {
    kInvalid,
    kLibrary,
    kClass,
    kMember,
    kClosure,
    kUnused1,
    kUnused2,
    kUnused3,
    kUnused4,
    kName,
    kTypeArguments,
    kUnused5,
    kConstObject,
    kArgDesc,
    kScript,
    kType,
  };

  // Member flags, must be in sync with _MemberHandle constants in
  // pkg/vm/lib/bytecode/object_table.dart.
  const intptr_t kFlagIsField = kFlagBit0;
  const intptr_t kFlagIsConstructor = kFlagBit1;

  // ArgDesc flags, must be in sync with _ArgDescHandle constants in
  // pkg/vm/lib/bytecode/object_table.dart.
  const int kFlagHasNamedArgs = kFlagBit0;
  const int kFlagHasTypeArgs = kFlagBit1;

  // Script flags, must be in sync with _ScriptHandle constants in
  // pkg/vm/lib/bytecode/object_table.dart.
  const int kFlagHasSourceFile = kFlagBit0;

  // Name flags, must be in sync with _NameHandle constants in
  // pkg/vm/lib/bytecode/object_table.dart.
  const intptr_t kFlagIsPublic = kFlagBit0;

  const intptr_t kind = (header >> kKindShift) & kKindMask;
  const intptr_t flags = header & kFlagsMask;

  switch (kind) {
    case kInvalid:
      UNREACHABLE();
      break;
    case kLibrary: {
      String& uri = String::CheckedHandle(Z, ReadObject());
      LibraryPtr library = Library::LookupLibrary(thread_, uri);
      if (library == Library::null()) {
        // We do not register expression evaluation libraries with the VM:
        // The expression evaluation functions should be GC-able as soon as
        // they are not reachable anymore and we never look them up by name.
        if (uri.raw() == Symbols::EvalSourceUri().raw()) {
          ASSERT(expression_evaluation_library_ != nullptr);
          return expression_evaluation_library_->raw();
        }
#if !defined(PRODUCT)
        ASSERT(Isolate::Current()->HasAttemptedReload());
        const String& msg = String::Handle(
            Z,
            String::NewFormatted("Unable to find library %s", uri.ToCString()));
        Report::LongJump(LanguageError::Handle(Z, LanguageError::New(msg)));
#else
        FATAL1("Unable to find library %s", uri.ToCString());
#endif
      }
      return library;
    }
    case kClass: {
      const Library& library = Library::CheckedHandle(Z, ReadObject());
      const String& class_name = String::CheckedHandle(Z, ReadObject());
      if (class_name.raw() == Symbols::Empty().raw()) {
        NoSafepointScope no_safepoint_scope(thread_);
        ClassPtr cls = library.toplevel_class();
        if (cls == Class::null()) {
          FATAL1("Unable to find toplevel class %s", library.ToCString());
        }
        return cls;
      }
      ClassPtr cls = library.LookupLocalClass(class_name);
      if (cls == Class::null()) {
        if (IsExpressionEvaluationLibrary(library)) {
          return H.GetExpressionEvaluationRealClass();
        }
#if !defined(PRODUCT)
        ASSERT(Isolate::Current()->HasAttemptedReload());
        const String& msg = String::Handle(
            Z,
            String::NewFormatted("Unable to find class %s in %s",
                                 class_name.ToCString(), library.ToCString()));
        Report::LongJump(LanguageError::Handle(Z, LanguageError::New(msg)));
#else
        FATAL2("Unable to find class %s in %s", class_name.ToCString(),
               library.ToCString());
#endif
      }
      return cls;
    }
    case kMember: {
      const Class& cls = Class::CheckedHandle(Z, ReadObject());
      String& name = String::CheckedHandle(Z, ReadObject());
      if ((flags & kFlagIsField) != 0) {
        FieldPtr field = cls.LookupField(name);
        if (field == Field::null()) {
#if !defined(PRODUCT)
          ASSERT(Isolate::Current()->HasAttemptedReload());
          const String& msg = String::Handle(
              Z, String::NewFormatted("Unable to find field %s in %s",
                                      name.ToCString(), cls.ToCString()));
          Report::LongJump(LanguageError::Handle(Z, LanguageError::New(msg)));
#else
          FATAL2("Unable to find field %s in %s", name.ToCString(),
                 cls.ToCString());
#endif
        }
        return field;
      } else {
        if ((flags & kFlagIsConstructor) != 0) {
          name = ConstructorName(cls, name);
        }
        ASSERT(!name.IsNull() && name.IsSymbol());
        if (name.raw() == scoped_function_name_.raw() &&
            cls.raw() == scoped_function_class_.raw()) {
          return scoped_function_.raw();
        }
        FunctionPtr function = cls.LookupFunction(name);
        if (function == Function::null()) {
          // When requesting a getter, also return method extractors.
          if (Field::IsGetterName(name)) {
            String& method_name =
                String::Handle(Z, Field::NameFromGetter(name));
            function = cls.LookupFunction(method_name);
            if (function != Function::null()) {
              function =
                  Function::Handle(Z, function).CreateMethodExtractor(name);
              if (function != Function::null()) {
                return function;
              }
            }
          }
#if !defined(PRODUCT)
          ASSERT(Isolate::Current()->HasAttemptedReload());
          const String& msg = String::Handle(
              Z, String::NewFormatted("Unable to find function %s in %s",
                                      name.ToCString(), cls.ToCString()));
          Report::LongJump(LanguageError::Handle(Z, LanguageError::New(msg)));
#else
          FATAL2("Unable to find function %s in %s", name.ToCString(),
                 cls.ToCString());
#endif
        }
        return function;
      }
    }
    case kClosure: {
      ReadObject();  // Skip enclosing member.
      const intptr_t closure_index = reader_.ReadUInt();
      return closures_->At(closure_index);
    }
    case kName: {
      if ((flags & kFlagIsPublic) == 0) {
        const Library& library = Library::CheckedHandle(Z, ReadObject());
        ASSERT(!library.IsNull());
        auto& name = String::Handle(Z, ReadString(/* is_canonical = */ false));
        name = library.PrivateName(name);
        if (I->obfuscate()) {
          const auto& library_key = String::Handle(Z, library.private_key());
          Obfuscator obfuscator(thread_, library_key);
          return obfuscator.Rename(name);
        }
        return name.raw();
      }
      if (I->obfuscate()) {
        Obfuscator obfuscator(thread_, Object::null_string());
        const auto& name = String::Handle(Z, ReadString());
        return obfuscator.Rename(name);
      } else {
        return ReadString();
      }
    }
    case kTypeArguments: {
      return ReadTypeArguments();
    }
    case kConstObject: {
      const intptr_t tag = flags / kFlagBit0;
      return ReadConstObject(tag);
    }
    case kArgDesc: {
      const intptr_t num_arguments = reader_.ReadUInt();
      const intptr_t num_type_args =
          ((flags & kFlagHasTypeArgs) != 0) ? reader_.ReadUInt() : 0;
      if ((flags & kFlagHasNamedArgs) == 0) {
        return ArgumentsDescriptor::NewBoxed(num_type_args, num_arguments);
      } else {
        const intptr_t num_arg_names = reader_.ReadListLength();
        const Array& array = Array::Handle(Z, Array::New(num_arg_names));
        String& name = String::Handle(Z);
        for (intptr_t i = 0; i < num_arg_names; ++i) {
          name ^= ReadObject();
          array.SetAt(i, name);
        }
        return ArgumentsDescriptor::NewBoxed(num_type_args, num_arguments,
                                             array);
      }
    }
    case kScript: {
      const String& uri = String::CheckedHandle(Z, ReadObject());
      Script& script = Script::Handle(Z);
      if ((flags & kFlagHasSourceFile) != 0) {
        // TODO(alexmarkov): read source and line starts only when needed.
        script =
            ReadSourceFile(uri, bytecode_component_->GetSourceFilesOffset() +
                                    reader_.ReadUInt());
      } else {
        script = Script::New(uri, Object::null_string());
      }
      script.set_kernel_program_info(H.GetKernelProgramInfo());
      return script.raw();
    }
    case kType: {
      const intptr_t tag = (flags & kTagMask) / kFlagBit0;
      const Nullability nullability =
          Reader::ConvertNullability(static_cast<KernelNullability>(
              (flags & kNullabilityMask) / kFlagBit4));
      return ReadType(tag, nullability);
    }
    default:
      UNREACHABLE();
  }

  return Object::null();
}

ObjectPtr BytecodeReaderHelper::ReadConstObject(intptr_t tag) {
  // Must be in sync with enum ConstTag in
  // pkg/vm/lib/bytecode/object_table.dart.
  enum ConstTag {
    kInvalid,
    kInstance,
    kInt,
    kDouble,
    kList,
    kTearOff,
    kBool,
    kSymbol,
    kTearOffInstantiation,
    kString,
  };

  switch (tag) {
    case kInvalid:
      UNREACHABLE();
      break;
    case kInstance: {
      const Type& type = Type::CheckedHandle(Z, ReadObject());
      const Class& cls = Class::Handle(Z, type.type_class());
      const Instance& obj = Instance::Handle(Z, Instance::New(cls, Heap::kOld));
      if (type.arguments() != TypeArguments::null()) {
        const TypeArguments& type_args =
            TypeArguments::Handle(Z, type.arguments());
        obj.SetTypeArguments(type_args);
      }
      const intptr_t num_fields = reader_.ReadUInt();
      Field& field = Field::Handle(Z);
      Object& value = Object::Handle(Z);
      for (intptr_t i = 0; i < num_fields; ++i) {
        field ^= ReadObject();
        value = ReadObject();
        obj.SetField(field, value);
      }
      return H.Canonicalize(obj);
    }
    case kInt: {
      const int64_t value = reader_.ReadSLEB128AsInt64();
      if (Smi::IsValid(value)) {
        return Smi::New(static_cast<intptr_t>(value));
      }
      const Integer& obj = Integer::Handle(Z, Integer::New(value, Heap::kOld));
      return H.Canonicalize(obj);
    }
    case kDouble: {
      const int64_t bits = reader_.ReadSLEB128AsInt64();
      double value = bit_cast<double, int64_t>(bits);
      const Double& obj = Double::Handle(Z, Double::New(value, Heap::kOld));
      return H.Canonicalize(obj);
    }
    case kList: {
      const AbstractType& elem_type =
          AbstractType::CheckedHandle(Z, ReadObject());
      const intptr_t length = reader_.ReadUInt();
      const Array& array = Array::Handle(Z, Array::New(length, elem_type));
      Object& value = Object::Handle(Z);
      for (intptr_t i = 0; i < length; ++i) {
        value = ReadObject();
        array.SetAt(i, value);
      }
      array.MakeImmutable();
      return H.Canonicalize(array);
    }
    case kTearOff: {
      Object& obj = Object::Handle(Z, ReadObject());
      ASSERT(obj.IsFunction());
      obj = Function::Cast(obj).ImplicitClosureFunction();
      ASSERT(obj.IsFunction());
      obj = Function::Cast(obj).ImplicitStaticClosure();
      ASSERT(obj.IsInstance());
      return H.Canonicalize(Instance::Cast(obj));
    }
    case kBool: {
      bool is_true = reader_.ReadByte() != 0;
      return is_true ? Bool::True().raw() : Bool::False().raw();
    }
    case kSymbol: {
      const String& name = String::CheckedHandle(Z, ReadObject());
      ASSERT(name.IsSymbol());
      const Library& library = Library::Handle(Z, Library::InternalLibrary());
      ASSERT(!library.IsNull());
      const Class& cls =
          Class::Handle(Z, library.LookupClass(Symbols::Symbol()));
      ASSERT(!cls.IsNull());
      const Field& field = Field::Handle(
          Z, cls.LookupInstanceFieldAllowPrivate(Symbols::_name()));
      ASSERT(!field.IsNull());
      const Instance& obj = Instance::Handle(Z, Instance::New(cls, Heap::kOld));
      obj.SetField(field, name);
      return H.Canonicalize(obj);
    }
    case kTearOffInstantiation: {
      Closure& closure = Closure::CheckedHandle(Z, ReadObject());
      const TypeArguments& type_args =
          TypeArguments::CheckedHandle(Z, ReadObject());
      closure = Closure::New(
          TypeArguments::Handle(Z, closure.instantiator_type_arguments()),
          TypeArguments::Handle(Z, closure.function_type_arguments()),
          type_args, Function::Handle(Z, closure.function()),
          Context::Handle(Z, closure.context()), Heap::kOld);
      return H.Canonicalize(closure);
    }
    case kString:
      return ReadString();
    default:
      UNREACHABLE();
  }
  return Object::null();
}

ObjectPtr BytecodeReaderHelper::ReadType(intptr_t tag,
                                         Nullability nullability) {
  // Must be in sync with enum TypeTag in
  // pkg/vm/lib/bytecode/object_table.dart.
  enum TypeTag {
    kInvalid,
    kDynamic,
    kVoid,
    kSimpleType,
    kTypeParameter,
    kGenericType,
    kRecursiveGenericType,
    kRecursiveTypeRef,
    kFunctionType,
    kNever,
  };

  // FunctionType flags, must be in sync with _FunctionTypeHandle constants in
  // pkg/vm/lib/bytecode/object_table.dart.
  const int kFlagHasOptionalPositionalParams = 1 << 0;
  const int kFlagHasOptionalNamedParams = 1 << 1;
  const int kFlagHasTypeParams = 1 << 2;

  switch (tag) {
    case kInvalid:
      UNREACHABLE();
      break;
    case kDynamic:
      return AbstractType::dynamic_type().raw();
    case kVoid:
      return AbstractType::void_type().raw();
    case kNever:
      return Type::Handle(Z, Type::NeverType())
          .ToNullability(nullability, Heap::kOld);
    case kSimpleType: {
      const Class& cls = Class::CheckedHandle(Z, ReadObject());
      if (!cls.is_declaration_loaded()) {
        LoadReferencedClass(cls);
      }
      const Type& type = Type::Handle(Z, cls.DeclarationType());
      return type.ToNullability(nullability, Heap::kOld);
    }
    case kTypeParameter: {
      Object& parent = Object::Handle(Z, ReadObject());
      const intptr_t index_in_parent = reader_.ReadUInt();
      TypeArguments& type_parameters = TypeArguments::Handle(Z);
      if (parent.IsClass()) {
        type_parameters = Class::Cast(parent).type_parameters();
      } else if (parent.IsFunction()) {
        if (Function::Cast(parent).IsFactory()) {
          // For factory constructors VM uses type parameters of a class
          // instead of constructor's type parameters.
          parent = Function::Cast(parent).Owner();
          type_parameters = Class::Cast(parent).type_parameters();
        } else {
          type_parameters = Function::Cast(parent).type_parameters();
        }
      } else if (parent.IsNull()) {
        ASSERT(function_type_type_parameters_ != nullptr);
        type_parameters = function_type_type_parameters_->raw();
      } else {
        UNREACHABLE();
      }
      TypeParameter& type_parameter = TypeParameter::Handle(Z);
      type_parameter ^= type_parameters.TypeAt(index_in_parent);
      if (type_parameter.bound() == AbstractType::null()) {
        AbstractType& derived = AbstractType::Handle(
            Z, type_parameter.ToNullability(nullability, Heap::kOld));
        active_class_->RecordDerivedTypeParameter(Z, type_parameter,
                                                  TypeParameter::Cast(derived));
        return derived.raw();
      }
      return type_parameter.ToNullability(nullability, Heap::kOld);
    }
    case kGenericType: {
      const Class& cls = Class::CheckedHandle(Z, ReadObject());
      if (!cls.is_declaration_loaded()) {
        LoadReferencedClass(cls);
      }
      const TypeArguments& type_arguments =
          TypeArguments::CheckedHandle(Z, ReadObject());
      const Type& type =
          Type::Handle(Z, Type::New(cls, type_arguments,
                                    TokenPosition::kNoSource, nullability));
      type.SetIsFinalized();
      return type.Canonicalize();
    }
    case kRecursiveGenericType: {
      const intptr_t id = reader_.ReadUInt();
      const Class& cls = Class::CheckedHandle(Z, ReadObject());
      if (!cls.is_declaration_loaded()) {
        LoadReferencedClass(cls);
      }
      const auto saved_pending_recursive_types = pending_recursive_types_;
      if (id == 0) {
        pending_recursive_types_ = &GrowableObjectArray::Handle(
            Z, GrowableObjectArray::New(Heap::kOld));
      }
      ASSERT(id == pending_recursive_types_->Length());
      const auto& type_ref =
          TypeRef::Handle(Z, TypeRef::New(AbstractType::null_abstract_type()));
      pending_recursive_types_->Add(type_ref);

      reading_type_arguments_of_recursive_type_ = true;
      const TypeArguments& type_arguments =
          TypeArguments::CheckedHandle(Z, ReadObject());
      reading_type_arguments_of_recursive_type_ = false;

      ASSERT(id == pending_recursive_types_->Length() - 1);
      ASSERT(pending_recursive_types_->At(id) == type_ref.raw());
      pending_recursive_types_->SetLength(id);
      pending_recursive_types_ = saved_pending_recursive_types;

      Type& type =
          Type::Handle(Z, Type::New(cls, type_arguments,
                                    TokenPosition::kNoSource, nullability));
      type_ref.set_type(type);
      type.SetIsFinalized();
      if (id != 0) {
        // Do not canonicalize non-root recursive types
        // as not all TypeRef objects are filled up at this point.
        return type.raw();
      }
      return type.Canonicalize();
    }
    case kRecursiveTypeRef: {
      const intptr_t id = reader_.ReadUInt();
      ASSERT(pending_recursive_types_ != nullptr);
      ASSERT(pending_recursive_types_->Length() >= id);
      return pending_recursive_types_->At(id);
    }
    case kFunctionType: {
      const intptr_t flags = reader_.ReadUInt();
      Function& signature_function = Function::ZoneHandle(
          Z, Function::NewSignatureFunction(*active_class_->klass,
                                            active_class_->enclosing != NULL
                                                ? *active_class_->enclosing
                                                : Function::null_function(),
                                            TokenPosition::kNoSource));

      // This scope is needed to set active_class_->enclosing_ which is used to
      // assign parent function for function types.
      ActiveEnclosingFunctionScope active_enclosing_function(
          active_class_, &signature_function);

      // TODO(alexmarkov): skip type finalization
      return ReadFunctionSignature(
          signature_function, (flags & kFlagHasOptionalPositionalParams) != 0,
          (flags & kFlagHasOptionalNamedParams) != 0,
          (flags & kFlagHasTypeParams) != 0,
          /* has_positional_param_names = */ false,
          /* has_parameter_flags */ false, nullability);
    }
    default:
      UNREACHABLE();
  }
  return Object::null();
}

StringPtr BytecodeReaderHelper::ReadString(bool is_canonical) {
  const int kFlagTwoByteString = 1;
  const int kHeaderFields = 2;
  const int kUInt32Size = 4;

  uint32_t ref = reader_.ReadUInt();
  const bool isOneByteString = (ref & kFlagTwoByteString) == 0;
  intptr_t index = ref >> 1;

  if (!isOneByteString) {
    const uint32_t num_one_byte_strings =
        reader_.ReadUInt32At(bytecode_component_->GetStringsHeaderOffset());
    index += num_one_byte_strings;
  }

  AlternativeReadingScope alt(&reader_,
                              bytecode_component_->GetStringsHeaderOffset() +
                                  (kHeaderFields + index - 1) * kUInt32Size);
  intptr_t start_offs = reader_.ReadUInt32();
  intptr_t end_offs = reader_.ReadUInt32();
  if (index == 0) {
    // For the 0-th string we read a header field instead of end offset of
    // the previous string.
    start_offs = 0;
  }

  // Bytecode strings reside in ExternalTypedData which is not movable by GC,
  // so it is OK to take a direct pointer to string characters even if
  // symbol allocation triggers GC.
  const uint8_t* data = reader_.BufferAt(
      bytecode_component_->GetStringsContentsOffset() + start_offs);

  if (is_canonical) {
    if (isOneByteString) {
      return Symbols::FromLatin1(thread_, data, end_offs - start_offs);
    } else {
      return Symbols::FromUTF16(thread_,
                                reinterpret_cast<const uint16_t*>(data),
                                (end_offs - start_offs) >> 1);
    }
  } else {
    if (isOneByteString) {
      return String::FromLatin1(data, end_offs - start_offs, Heap::kOld);
    } else {
      return String::FromUTF16(reinterpret_cast<const uint16_t*>(data),
                               (end_offs - start_offs) >> 1, Heap::kOld);
    }
  }
}

ScriptPtr BytecodeReaderHelper::ReadSourceFile(const String& uri,
                                               intptr_t offset) {
  // SourceFile flags, must be in sync with SourceFile constants in
  // pkg/vm/lib/bytecode/declarations.dart.
  const int kHasLineStartsFlag = 1 << 0;
  const int kHasSourceFlag = 1 << 1;

  AlternativeReadingScope alt(&reader_, offset);

  const intptr_t flags = reader_.ReadUInt();
  const String& import_uri = String::CheckedHandle(Z, ReadObject());

  TypedData& line_starts = TypedData::Handle(Z);
  if ((flags & kHasLineStartsFlag) != 0) {
    // TODO(alexmarkov): read line starts only when needed.
    const intptr_t line_starts_offset =
        bytecode_component_->GetLineStartsOffset() + reader_.ReadUInt();

    AlternativeReadingScope alt(&reader_, line_starts_offset);

    const intptr_t num_line_starts = reader_.ReadUInt();
    line_starts = reader_.ReadLineStartsData(num_line_starts);
  }

  String& source = String::Handle(Z);
  if ((flags & kHasSourceFlag) != 0) {
    source = ReadString(/* is_canonical = */ false);
  }

  const Script& script =
      Script::Handle(Z, Script::New(import_uri, uri, source));
  script.set_line_starts(line_starts);

  if (source.IsNull() && line_starts.IsNull()) {
    // This script provides a uri only, but no source or line_starts array.
    // This could be a reference to a Script in another kernel binary.
    // Make an attempt to find source and line starts when needed.
    script.SetLazyLookupSourceAndLineStarts(true);
  }

  return script.raw();
}

TypeArgumentsPtr BytecodeReaderHelper::ReadTypeArguments() {
  const bool is_recursive = reading_type_arguments_of_recursive_type_;
  reading_type_arguments_of_recursive_type_ = false;
  const intptr_t length = reader_.ReadUInt();
  TypeArguments& type_arguments =
      TypeArguments::ZoneHandle(Z, TypeArguments::New(length));
  AbstractType& type = AbstractType::Handle(Z);
  for (intptr_t i = 0; i < length; ++i) {
    type ^= ReadObject();
    type_arguments.SetTypeAt(i, type);
  }
  if (is_recursive) {
    // Avoid canonicalization of type arguments of recursive type
    // as not all TypeRef objects are filled up at this point.
    // Type arguments will be canoncialized when the root recursive
    // type is canonicalized.
    ASSERT(pending_recursive_types_ != nullptr);
    return type_arguments.raw();
  }
  return type_arguments.Canonicalize();
}

void BytecodeReaderHelper::ReadAttributes(const Object& key) {
  ASSERT(key.IsFunction() || key.IsField());
  const auto& value = Object::Handle(Z, ReadObject());

  Array& attributes =
      Array::Handle(Z, I->object_store()->bytecode_attributes());
  if (attributes.IsNull()) {
    attributes = HashTables::New<BytecodeAttributesMap>(16, Heap::kOld);
  }
  BytecodeAttributesMap map(attributes.raw());
  bool present = map.UpdateOrInsert(key, value);
  ASSERT(!present);
  I->object_store()->set_bytecode_attributes(map.Release());

  if (key.IsField()) {
    const Field& field = Field::Cast(key);
    const auto& inferred_type_attr =
        Array::CheckedHandle(Z, BytecodeReader::GetBytecodeAttribute(
                                    key, Symbols::vm_inferred_type_metadata()));

    if (!inferred_type_attr.IsNull() &&
        (InferredTypeBytecodeAttribute::GetPCAt(inferred_type_attr, 0) ==
         InferredTypeBytecodeAttribute::kFieldTypePC)) {
      const InferredTypeMetadata type =
          InferredTypeBytecodeAttribute::GetInferredTypeAt(
              Z, inferred_type_attr, 0);
      if (!type.IsTrivial()) {
        field.set_guarded_cid(type.cid);
        field.set_is_nullable(type.IsNullable());
        field.set_guarded_list_length(Field::kNoFixedLength);
      }
    }
  }
}

void BytecodeReaderHelper::ReadMembers(const Class& cls, bool discard_fields) {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(cls.is_type_finalized());
  ASSERT(!cls.is_loaded());

  const intptr_t num_functions = reader_.ReadUInt();
  functions_ = &Array::Handle(Z, Array::New(num_functions, Heap::kOld));
  function_index_ = 0;

  ReadFieldDeclarations(cls, discard_fields);
  ReadFunctionDeclarations(cls);

  cls.set_is_loaded(true);
}

void BytecodeReaderHelper::ReadFieldDeclarations(const Class& cls,
                                                 bool discard_fields) {
  // Field flags, must be in sync with FieldDeclaration constants in
  // pkg/vm/lib/bytecode/declarations.dart.
  const int kHasNontrivialInitializerFlag = 1 << 0;
  const int kHasGetterFlag = 1 << 1;
  const int kHasSetterFlag = 1 << 2;
  const int kIsReflectableFlag = 1 << 3;
  const int kIsStaticFlag = 1 << 4;
  const int kIsConstFlag = 1 << 5;
  const int kIsFinalFlag = 1 << 6;
  const int kIsCovariantFlag = 1 << 7;
  const int kIsGenericCovariantImplFlag = 1 << 8;
  const int kHasSourcePositionsFlag = 1 << 9;
  const int kHasAnnotationsFlag = 1 << 10;
  const int kHasPragmaFlag = 1 << 11;
  const int kHasCustomScriptFlag = 1 << 12;
  const int kHasInitializerCodeFlag = 1 << 13;
  const int kHasAttributesFlag = 1 << 14;
  const int kIsLateFlag = 1 << 15;
  const int kIsExtensionMemberFlag = 1 << 16;
  const int kHasInitializerFlag = 1 << 17;

  const int num_fields = reader_.ReadListLength();
  if ((num_fields == 0) && !cls.is_enum_class()) {
    return;
  }
  const Array& fields = Array::Handle(
      Z, Array::New(num_fields + (cls.is_enum_class() ? 1 : 0), Heap::kOld));
  String& name = String::Handle(Z);
  Object& script_class = Object::Handle(Z);
  AbstractType& type = AbstractType::Handle(Z);
  Field& field = Field::Handle(Z);
  Instance& value = Instance::Handle(Z);
  Function& function = Function::Handle(Z);

  for (intptr_t i = 0; i < num_fields; ++i) {
    intptr_t flags = reader_.ReadUInt();

    const bool is_static = (flags & kIsStaticFlag) != 0;
    const bool is_final = (flags & kIsFinalFlag) != 0;
    const bool is_const = (flags & kIsConstFlag) != 0;
    const bool is_late = (flags & kIsLateFlag) != 0;
    const bool has_nontrivial_initializer =
        (flags & kHasNontrivialInitializerFlag) != 0;
    const bool has_pragma = (flags & kHasPragmaFlag) != 0;
    const bool is_extension_member = (flags & kIsExtensionMemberFlag) != 0;
    const bool has_initializer = (flags & kHasInitializerFlag) != 0;

    name ^= ReadObject();
    type ^= ReadObject();

    if ((flags & kHasCustomScriptFlag) != 0) {
      Script& script = Script::CheckedHandle(Z, ReadObject());
      script_class = GetPatchClass(cls, script);
    } else {
      script_class = cls.raw();
    }

    TokenPosition position = TokenPosition::kNoSource;
    TokenPosition end_position = TokenPosition::kNoSource;
    if ((flags & kHasSourcePositionsFlag) != 0) {
      position = reader_.ReadPosition();
      end_position = reader_.ReadPosition();
    }

    field = Field::New(name, is_static, is_final, is_const,
                       (flags & kIsReflectableFlag) != 0, is_late, script_class,
                       type, position, end_position);

    field.set_is_declared_in_bytecode(true);
    field.set_has_pragma(has_pragma);
    field.set_is_covariant((flags & kIsCovariantFlag) != 0);
    field.set_is_generic_covariant_impl((flags & kIsGenericCovariantImplFlag) !=
                                        0);
    field.set_has_nontrivial_initializer(has_nontrivial_initializer);
    field.set_is_extension_member(is_extension_member);
    field.set_has_initializer(has_initializer);

    if (!has_nontrivial_initializer) {
      value ^= ReadObject();
      if (is_static) {
        if (field.is_late() && !has_initializer) {
          field.SetStaticValue(Object::sentinel(), true);
        } else {
          field.SetStaticValue(value, true);
        }
      } else {
        field.set_saved_initial_value(value);
        // Null-initialized instance fields are tracked separately for each
        // constructor (see handling of kHasNullableFieldsFlag).
        if (!value.IsNull()) {
          // Note: optimizer relies on DoubleInitialized bit in its
          // field-unboxing heuristics.
          // See JitCallSpecializer::VisitStoreInstanceField for more details.
          field.RecordStore(value);
          if (value.IsDouble()) {
            field.set_is_double_initialized(true);
          }
        }
      }
    }

    if ((flags & kHasInitializerCodeFlag) != 0) {
      const intptr_t code_offset = reader_.ReadUInt();
      field.set_bytecode_offset(code_offset +
                                bytecode_component_->GetCodesOffset());
      if (is_static) {
        field.SetStaticValue(Object::sentinel(), true);
      }
    }

    if ((flags & kHasGetterFlag) != 0) {
      name ^= ReadObject();
      function = Function::New(name,
                               is_static ? FunctionLayout::kImplicitStaticGetter
                                         : FunctionLayout::kImplicitGetter,
                               is_static, is_const,
                               false,  // is_abstract
                               false,  // is_external
                               false,  // is_native
                               script_class, position);
      function.set_end_token_pos(end_position);
      function.set_result_type(type);
      function.set_is_debuggable(false);
      function.set_accessor_field(field);
      function.set_is_declared_in_bytecode(true);
      function.set_is_extension_member(is_extension_member);
      if (is_const && has_nontrivial_initializer) {
        function.set_bytecode_offset(field.bytecode_offset());
      }
      H.SetupFieldAccessorFunction(cls, function, type);
      functions_->SetAt(function_index_++, function);
    }

    if ((flags & kHasSetterFlag) != 0) {
      ASSERT(is_late || ((!is_static) && (!is_final)));
      ASSERT(!is_const);
      name ^= ReadObject();
      function = Function::New(name, FunctionLayout::kImplicitSetter, is_static,
                               false,  // is_const
                               false,  // is_abstract
                               false,  // is_external
                               false,  // is_native
                               script_class, position);
      function.set_end_token_pos(end_position);
      function.set_result_type(Object::void_type());
      function.set_is_debuggable(false);
      function.set_accessor_field(field);
      function.set_is_declared_in_bytecode(true);
      function.set_is_extension_member(is_extension_member);
      H.SetupFieldAccessorFunction(cls, function, type);
      functions_->SetAt(function_index_++, function);
    }

    if ((flags & kHasAnnotationsFlag) != 0) {
      intptr_t annotations_offset =
          reader_.ReadUInt() + bytecode_component_->GetAnnotationsOffset();
      ASSERT(annotations_offset > 0);

      if (FLAG_enable_mirrors || has_pragma) {
        Library& library = Library::Handle(Z, cls.library());
        library.AddFieldMetadata(field, TokenPosition::kNoSource, 0,
                                 annotations_offset);
        if (has_pragma) {
          // TODO(alexmarkov): read annotations right away using
          //  annotations_offset.
          NoOOBMessageScope no_msg_scope(thread_);
          NoReloadScope no_reload_scope(thread_->isolate(), thread_);
          library.GetMetadata(field);
        }
      }
    }

    if ((flags & kHasAttributesFlag) != 0) {
      ReadAttributes(field);
    }

    fields.SetAt(i, field);
  }

  if (cls.is_enum_class()) {
    // Add static field 'const _deleted_enum_sentinel'.
    field = Field::New(Symbols::_DeletedEnumSentinel(),
                       /* is_static = */ true,
                       /* is_final = */ true,
                       /* is_const = */ true,
                       /* is_reflectable = */ false,
                       /* is_late = */ false, cls, Object::dynamic_type(),
                       TokenPosition::kNoSource, TokenPosition::kNoSource);

    fields.SetAt(num_fields, field);
  }

  if (!discard_fields) {
    cls.SetFields(fields);
  }

  if (cls.IsTopLevel()) {
    const Library& library = Library::Handle(Z, cls.library());
    for (intptr_t i = 0, n = fields.Length(); i < n; ++i) {
      field ^= fields.At(i);
      name = field.name();
      library.AddObject(field, name);
    }
  }
}

PatchClassPtr BytecodeReaderHelper::GetPatchClass(const Class& cls,
                                                  const Script& script) {
  if (patch_class_ != nullptr && patch_class_->patched_class() == cls.raw() &&
      patch_class_->script() == script.raw()) {
    return patch_class_->raw();
  }
  if (patch_class_ == nullptr) {
    patch_class_ = &PatchClass::Handle(Z);
  }
  *patch_class_ = PatchClass::New(cls, script);
  return patch_class_->raw();
}

void BytecodeReaderHelper::ReadFunctionDeclarations(const Class& cls) {
  // Function flags, must be in sync with FunctionDeclaration constants in
  // pkg/vm/lib/bytecode/declarations.dart.
  const int kIsConstructorFlag = 1 << 0;
  const int kIsGetterFlag = 1 << 1;
  const int kIsSetterFlag = 1 << 2;
  const int kIsFactoryFlag = 1 << 3;
  const int kIsStaticFlag = 1 << 4;
  const int kIsAbstractFlag = 1 << 5;
  const int kIsConstFlag = 1 << 6;
  const int kHasOptionalPositionalParamsFlag = 1 << 7;
  const int kHasOptionalNamedParamsFlag = 1 << 8;
  const int kHasTypeParamsFlag = 1 << 9;
  const int kIsReflectableFlag = 1 << 10;
  const int kIsDebuggableFlag = 1 << 11;
  const int kIsAsyncFlag = 1 << 12;
  const int kIsAsyncStarFlag = 1 << 13;
  const int kIsSyncStarFlag = 1 << 14;
  // const int kIsForwardingStubFlag = 1 << 15;
  const int kIsNoSuchMethodForwarderFlag = 1 << 16;
  const int kIsNativeFlag = 1 << 17;
  const int kIsExternalFlag = 1 << 18;
  const int kHasSourcePositionsFlag = 1 << 19;
  const int kHasAnnotationsFlag = 1 << 20;
  const int kHasPragmaFlag = 1 << 21;
  const int kHasCustomScriptFlag = 1 << 22;
  const int kHasAttributesFlag = 1 << 23;
  const int kIsExtensionMemberFlag = 1 << 24;

  const intptr_t num_functions = reader_.ReadListLength();
  ASSERT(function_index_ + num_functions == functions_->Length());

  if (function_index_ + num_functions == 0) {
    return;
  }

  String& name = String::Handle(Z);
  Object& script_class = Object::Handle(Z);
  Function& function = Function::Handle(Z);
  Array& parameter_types = Array::Handle(Z);
  Array& parameter_names = Array::Handle(Z);
  AbstractType& type = AbstractType::Handle(Z);

  name = cls.ScrubbedName();
  const bool is_async_await_completer_owner =
      Symbols::_AsyncAwaitCompleter().Equals(name);

  for (intptr_t i = 0; i < num_functions; ++i) {
    intptr_t flags = reader_.ReadUInt();

    const bool is_static = (flags & kIsStaticFlag) != 0;
    const bool is_factory = (flags & kIsFactoryFlag) != 0;
    const bool is_native = (flags & kIsNativeFlag) != 0;
    const bool has_pragma = (flags & kHasPragmaFlag) != 0;
    const bool is_extension_member = (flags & kIsExtensionMemberFlag) != 0;

    name ^= ReadObject();

    if ((flags & kHasCustomScriptFlag) != 0) {
      Script& script = Script::CheckedHandle(Z, ReadObject());
      script_class = GetPatchClass(cls, script);
    } else {
      script_class = cls.raw();
    }

    TokenPosition position = TokenPosition::kNoSource;
    TokenPosition end_position = TokenPosition::kNoSource;
    if ((flags & kHasSourcePositionsFlag) != 0) {
      position = reader_.ReadPosition();
      end_position = reader_.ReadPosition();
    }

    FunctionLayout::Kind kind = FunctionLayout::kRegularFunction;
    if ((flags & kIsGetterFlag) != 0) {
      kind = FunctionLayout::kGetterFunction;
    } else if ((flags & kIsSetterFlag) != 0) {
      kind = FunctionLayout::kSetterFunction;
    } else if ((flags & (kIsConstructorFlag | kIsFactoryFlag)) != 0) {
      kind = FunctionLayout::kConstructor;
      name = ConstructorName(cls, name);
    }

    function = Function::New(name, kind, is_static, (flags & kIsConstFlag) != 0,
                             (flags & kIsAbstractFlag) != 0,
                             (flags & kIsExternalFlag) != 0, is_native,
                             script_class, position);

    const bool is_expression_evaluation =
        (name.raw() == Symbols::DebugProcedureName().raw());

    // Declare function scope as types (type parameters) in function
    // signature may back-reference to the function being declared.
    // At this moment, owner class is not fully loaded yet and it won't be
    // able to serve function lookup requests.
    FunctionScope function_scope(this, function, name, cls);

    function.set_is_declared_in_bytecode(true);
    function.set_has_pragma(has_pragma);
    function.set_end_token_pos(end_position);
    function.set_is_synthetic((flags & kIsNoSuchMethodForwarderFlag) != 0);
    function.set_is_reflectable((flags & kIsReflectableFlag) != 0);
    function.set_is_debuggable((flags & kIsDebuggableFlag) != 0);
    function.set_is_extension_member(is_extension_member);

    // _AsyncAwaitCompleter.start should be made non-visible in stack traces,
    // since it is an implementation detail of our await/async desugaring.
    if (is_async_await_completer_owner &&
        Symbols::_AsyncAwaitStart().Equals(name)) {
      function.set_is_visible(!FLAG_causal_async_stacks &&
                              !FLAG_lazy_async_stacks);
    }

    if ((flags & kIsSyncStarFlag) != 0) {
      function.set_modifier(FunctionLayout::kSyncGen);
      function.set_is_visible(!FLAG_causal_async_stacks &&
                              !FLAG_lazy_async_stacks);
    } else if ((flags & kIsAsyncFlag) != 0) {
      function.set_modifier(FunctionLayout::kAsync);
      function.set_is_inlinable(!FLAG_causal_async_stacks &&
                                !FLAG_lazy_async_stacks);
      function.set_is_visible(!FLAG_causal_async_stacks &&
                              !FLAG_lazy_async_stacks);
    } else if ((flags & kIsAsyncStarFlag) != 0) {
      function.set_modifier(FunctionLayout::kAsyncGen);
      function.set_is_inlinable(!FLAG_causal_async_stacks &&
                                !FLAG_lazy_async_stacks);
      function.set_is_visible(!FLAG_causal_async_stacks &&
                              !FLAG_lazy_async_stacks);
    }

    if ((flags & kHasTypeParamsFlag) != 0) {
      ReadTypeParametersDeclaration(Class::Handle(Z), function);
    }

    const intptr_t num_implicit_params = (!is_static || is_factory) ? 1 : 0;
    const intptr_t num_params = num_implicit_params + reader_.ReadUInt();

    intptr_t num_required_params = num_params;
    if ((flags & (kHasOptionalPositionalParamsFlag |
                  kHasOptionalNamedParamsFlag)) != 0) {
      num_required_params = num_implicit_params + reader_.ReadUInt();
    }

    function.set_num_fixed_parameters(num_required_params);
    function.SetNumOptionalParameters(
        num_params - num_required_params,
        (flags & kHasOptionalNamedParamsFlag) == 0);

    parameter_types = Array::New(num_params, Heap::kOld);
    function.set_parameter_types(parameter_types);

    parameter_names = Array::New(
        Function::NameArrayLengthIncludingFlags(num_params), Heap::kOld);
    function.set_parameter_names(parameter_names);

    intptr_t param_index = 0;
    if (!is_static) {
      if (is_expression_evaluation) {
        // Do not reference enclosing class as expression evaluation
        // method logically belongs to another (real) class.
        // Enclosing class is not registered and doesn't have
        // a valid cid, so it can't be used in a type.
        function.SetParameterTypeAt(param_index, AbstractType::dynamic_type());
      } else {
        function.SetParameterTypeAt(param_index, H.GetDeclarationType(cls));
      }
      function.SetParameterNameAt(param_index, Symbols::This());
      ++param_index;
    } else if (is_factory) {
      function.SetParameterTypeAt(param_index, AbstractType::dynamic_type());
      function.SetParameterNameAt(param_index,
                                  Symbols::TypeArgumentsParameter());
      ++param_index;
    }

    for (; param_index < num_params; ++param_index) {
      name ^= ReadObject();
      parameter_names.SetAt(param_index, name);
      type ^= ReadObject();
      parameter_types.SetAt(param_index, type);
    }

    type ^= ReadObject();
    function.set_result_type(type);

    if (is_native) {
      name ^= ReadObject();
      function.set_native_name(name);
    }

    if ((flags & kIsAbstractFlag) == 0) {
      const intptr_t code_offset = reader_.ReadUInt();
      function.set_bytecode_offset(code_offset +
                                   bytecode_component_->GetCodesOffset());
    }

    if ((flags & kHasAnnotationsFlag) != 0) {
      const intptr_t annotations_offset =
          reader_.ReadUInt() + bytecode_component_->GetAnnotationsOffset();
      ASSERT(annotations_offset > 0);

      if (FLAG_enable_mirrors || has_pragma) {
        Library& library = Library::Handle(Z, cls.library());
        library.AddFunctionMetadata(function, TokenPosition::kNoSource, 0,
                                    annotations_offset);

        if (has_pragma) {
          if (H.constants().IsNull() &&
              library.raw() == Library::CoreLibrary()) {
            // Bootstrapping, need to postpone evaluation of pragma annotations
            // as classes are not fully loaded/finalized yet.
            const auto& pragma_funcs = GrowableObjectArray::Handle(
                Z, H.EnsurePotentialPragmaFunctions());
            pragma_funcs.Add(function);
          } else {
            // TODO(alexmarkov): read annotations right away using
            //  annotations_offset.
            Thread* thread = H.thread();
            NoOOBMessageScope no_msg_scope(thread);
            NoReloadScope no_reload_scope(thread->isolate(), thread);
            library.GetMetadata(function);
          }
        }
      }
    }

    if ((flags & kHasAttributesFlag) != 0) {
      ASSERT(!is_expression_evaluation);
      ReadAttributes(function);
    }

    if (is_expression_evaluation) {
      H.SetExpressionEvaluationFunction(function);
      // Read bytecode of expression evaluation function eagerly,
      // while expression_evaluation_library_ and FunctionScope
      // are still set, as its constant pool may reference back to a library
      // or a function which are not registered and cannot be looked up.
      ASSERT(!function.is_abstract());
      ASSERT(function.bytecode_offset() != 0);
      // Replace class of the function in scope as we're going to look for
      // expression evaluation function in a real class.
      if (!cls.IsTopLevel()) {
        scoped_function_class_ = H.GetExpressionEvaluationRealClass();
      }
      CompilerState compiler_state(thread_, FLAG_precompiled_mode);
      ReadCode(function, function.bytecode_offset());
    }

    functions_->SetAt(function_index_++, function);
  }

  cls.SetFunctions(*functions_);

  if (cls.IsTopLevel()) {
    const Library& library = Library::Handle(Z, cls.library());
    for (intptr_t i = 0, n = functions_->Length(); i < n; ++i) {
      function ^= functions_->At(i);
      name = function.name();
      library.AddObject(function, name);
    }
  }

  functions_ = nullptr;
}

void BytecodeReaderHelper::LoadReferencedClass(const Class& cls) {
  ASSERT(!cls.is_declaration_loaded());

  if (!cls.is_declared_in_bytecode()) {
    cls.EnsureDeclarationLoaded();
    return;
  }

  const auto& script = Script::Handle(Z, cls.script());
  if (H.GetKernelProgramInfo().raw() != script.kernel_program_info()) {
    // Class comes from a different binary.
    cls.EnsureDeclarationLoaded();
    return;
  }

  // We can reuse current BytecodeReaderHelper.
  ActiveClassScope active_class_scope(active_class_, &cls);
  AlternativeReadingScope alt(&reader_, cls.bytecode_offset());
  ReadClassDeclaration(cls);
}

void BytecodeReaderHelper::ReadClassDeclaration(const Class& cls) {
  // Class flags, must be in sync with ClassDeclaration constants in
  // pkg/vm/lib/bytecode/declarations.dart.
  const int kIsAbstractFlag = 1 << 0;
  const int kIsEnumFlag = 1 << 1;
  const int kHasTypeParamsFlag = 1 << 2;
  const int kHasTypeArgumentsFlag = 1 << 3;
  const int kIsTransformedMixinApplicationFlag = 1 << 4;
  const int kHasSourcePositionsFlag = 1 << 5;
  const int kHasAnnotationsFlag = 1 << 6;
  const int kHasPragmaFlag = 1 << 7;

  // Class is allocated when reading library declaration in
  // BytecodeReaderHelper::ReadLibraryDeclaration.
  // Its cid is set in Class::New / Isolate::RegisterClass /
  // ClassTable::Register, unless it was loaded for expression evaluation.
  ASSERT(cls.is_declared_in_bytecode());
  ASSERT(!cls.is_declaration_loaded() || loading_native_wrappers_library_);

  const intptr_t flags = reader_.ReadUInt();
  const bool has_pragma = (flags & kHasPragmaFlag) != 0;

  // Set early to enable access to type_parameters().
  // TODO(alexmarkov): revise early stamping of native wrapper classes
  //  as loaded.
  if (!cls.is_declaration_loaded()) {
    cls.set_is_declaration_loaded();
  }

  const auto& script = Script::CheckedHandle(Z, ReadObject());
  cls.set_script(script);

  TokenPosition position = TokenPosition::kNoSource;
  TokenPosition end_position = TokenPosition::kNoSource;
  if ((flags & kHasSourcePositionsFlag) != 0) {
    position = reader_.ReadPosition();
    end_position = reader_.ReadPosition();
    cls.set_token_pos(position);
    cls.set_end_token_pos(end_position);
  }

  cls.set_has_pragma(has_pragma);

  if ((flags & kIsAbstractFlag) != 0) {
    cls.set_is_abstract();
  }
  if ((flags & kIsEnumFlag) != 0) {
    cls.set_is_enum_class();
  }
  if ((flags & kIsTransformedMixinApplicationFlag) != 0) {
    cls.set_is_transformed_mixin_application();
  }

  intptr_t num_type_arguments = 0;
  if ((flags & kHasTypeArgumentsFlag) != 0) {
    num_type_arguments = reader_.ReadUInt();
  }
  cls.set_num_type_arguments(num_type_arguments);

  if ((flags & kHasTypeParamsFlag) != 0) {
    ReadTypeParametersDeclaration(cls, Function::null_function());
  }

  auto& type = AbstractType::CheckedHandle(Z, ReadObject());
  cls.set_super_type(type);

  const intptr_t num_interfaces = reader_.ReadUInt();
  if (num_interfaces > 0) {
    const auto& interfaces =
        Array::Handle(Z, Array::New(num_interfaces, Heap::kOld));
    for (intptr_t i = 0; i < num_interfaces; ++i) {
      type ^= ReadObject();
      interfaces.SetAt(i, type);
    }
    cls.set_interfaces(interfaces);
  }

  if ((flags & kHasAnnotationsFlag) != 0) {
    intptr_t annotations_offset =
        reader_.ReadUInt() + bytecode_component_->GetAnnotationsOffset();
    ASSERT(annotations_offset > 0);

    if (FLAG_enable_mirrors || has_pragma) {
      const auto& library = Library::Handle(Z, cls.library());
      if (cls.IsTopLevel()) {
        ASSERT(!has_pragma);
        library.AddLibraryMetadata(cls, TokenPosition::kNoSource, 0,
                                   annotations_offset);
      } else {
        const auto& top_level_class =
            Class::Handle(Z, library.toplevel_class());

        library.AddClassMetadata(cls, top_level_class, TokenPosition::kNoSource,
                                 0, annotations_offset);
      }
    }
  }

  const intptr_t members_offset = reader_.ReadUInt();
  cls.set_bytecode_offset(members_offset +
                          bytecode_component_->GetMembersOffset());

  // All types are finalized if loading from bytecode.
  // TODO(alexmarkov): revise early stamping of native wrapper classes
  //  as type-finalized.
  if (!cls.is_type_finalized()) {
    cls.set_is_type_finalized();
  }

  // Avoid registering expression evaluation class in a hierarchy, as
  // it doesn't have cid and shouldn't be found when enumerating subclasses.
  if (expression_evaluation_library_ == nullptr) {
    // TODO(alexmarkov): move this to class finalization.
    ClassFinalizer::RegisterClassInHierarchy(Z, cls);
  }
}

void BytecodeReaderHelper::ReadLibraryDeclaration(const Library& library,
                                                  bool lookup_classes) {
  // Library flags, must be in sync with LibraryDeclaration constants in
  // pkg/vm/lib/bytecode/declarations.dart.
  const int kUsesDartMirrorsFlag = 1 << 0;
  const int kUsesDartFfiFlag = 1 << 1;
  const int kHasExtensionsFlag = 1 << 2;
  const int kIsNonNullableByDefaultFlag = 1 << 3;

  ASSERT(library.is_declared_in_bytecode());
  ASSERT(!library.Loaded());
  ASSERT(library.toplevel_class() == Object::null());

  // TODO(alexmarkov): fill in library.used_scripts.

  const intptr_t flags = reader_.ReadUInt();
  if (((flags & kUsesDartMirrorsFlag) != 0) && !FLAG_enable_mirrors) {
    H.ReportError(
        "import of dart:mirrors is not supported in the current Dart runtime");
  }
  if (((flags & kUsesDartFfiFlag) != 0) && !Api::IsFfiEnabled()) {
    H.ReportError(
        "import of dart:ffi is not supported in the current Dart runtime");
  }

  auto& name = String::CheckedHandle(Z, ReadObject());
  library.SetName(name);

  const auto& script = Script::CheckedHandle(Z, ReadObject());

  if ((flags & kHasExtensionsFlag) != 0) {
    const intptr_t num_extensions = reader_.ReadUInt();
    auto& import_namespace = Namespace::Handle(Z);
    auto& native_library = Library::Handle(Z);
    for (intptr_t i = 0; i < num_extensions; ++i) {
      name ^= ReadObject();
      ASSERT(name.StartsWith(Symbols::DartExtensionScheme()));

      // Create a dummy library and add it as an import to the current library.
      // Actual loading occurs in KernelLoader::LoadNativeExtensionLibraries().
      // This also allows later to discover and reload this native extension,
      // e.g. when running from an app-jit snapshot.
      // See Loader::ReloadNativeExtensions(...) which relies on
      // Dart_GetImportsOfScheme('dart-ext').
      native_library = Library::New(name);
      import_namespace = Namespace::New(native_library, Array::null_array(),
                                        Array::null_array());
      library.AddImport(import_namespace);
    }
    H.AddPotentialExtensionLibrary(library);
  }

  if ((flags & kIsNonNullableByDefaultFlag) != 0) {
    library.set_is_nnbd(true);
  }

  // The bootstrapper will take care of creating the native wrapper classes,
  // but we will add the synthetic constructors to them here.
  if (name.raw() ==
      Symbols::Symbol(Symbols::kDartNativeWrappersLibNameId).raw()) {
    ASSERT(library.LoadInProgress());
    loading_native_wrappers_library_ = true;
  } else {
    loading_native_wrappers_library_ = false;
    library.SetLoadInProgress();
  }

  const bool register_class = !IsExpressionEvaluationLibrary(library);

  const intptr_t num_classes = reader_.ReadUInt();
  ASSERT(num_classes > 0);
  auto& cls = Class::Handle(Z);

  for (intptr_t i = 0; i < num_classes; ++i) {
    name ^= ReadObject();
    const intptr_t class_offset =
        bytecode_component_->GetClassesOffset() + reader_.ReadUInt();

    if (i == 0) {
      ASSERT(name.raw() == Symbols::Empty().raw());
      cls = Class::New(library, Symbols::TopLevel(), script,
                       TokenPosition::kNoSource, register_class);
      library.set_toplevel_class(cls);
    } else {
      if (lookup_classes) {
        cls = library.LookupLocalClass(name);
      }
      if (lookup_classes && !cls.IsNull()) {
        ASSERT(!cls.is_declaration_loaded() ||
               loading_native_wrappers_library_);
        cls.set_script(script);
      } else {
        cls = Class::New(library, name, script, TokenPosition::kNoSource,
                         register_class);
        if (register_class) {
          library.AddClass(cls);
        }
      }
    }

    cls.set_is_declared_in_bytecode(true);
    cls.set_bytecode_offset(class_offset);

    if (loading_native_wrappers_library_ || !register_class) {
      AlternativeReadingScope alt(&reader_, class_offset);
      ReadClassDeclaration(cls);
      ActiveClassScope active_class_scope(active_class_, &cls);
      AlternativeReadingScope alt2(&reader_, cls.bytecode_offset());
      ReadMembers(cls, /* discard_fields = */ false);
    }
  }

  ASSERT(!library.Loaded());
  library.SetLoaded();

  loading_native_wrappers_library_ = false;
}

void BytecodeReaderHelper::ReadLibraryDeclarations(intptr_t num_libraries) {
  auto& library = Library::Handle(Z);
  auto& uri = String::Handle(Z);

  for (intptr_t i = 0; i < num_libraries; ++i) {
    uri ^= ReadObject();
    const intptr_t library_offset =
        bytecode_component_->GetLibrariesOffset() + reader_.ReadUInt();

    if (!FLAG_precompiled_mode && !I->should_load_vmservice()) {
      if (uri.raw() == Symbols::DartVMServiceIO().raw()) {
        continue;
      }
    }

    bool lookup_classes = true;
    library = Library::LookupLibrary(thread_, uri);
    if (library.IsNull()) {
      lookup_classes = false;
      library = Library::New(uri);

      if (uri.raw() == Symbols::EvalSourceUri().raw()) {
        ASSERT(expression_evaluation_library_ == nullptr);
        expression_evaluation_library_ = &Library::Handle(Z, library.raw());
      } else {
        library.Register(thread_);
      }
    }

    if (library.Loaded()) {
      continue;
    }

    library.set_is_declared_in_bytecode(true);
    library.set_bytecode_offset(library_offset);

    AlternativeReadingScope alt(&reader_, library_offset);
    ReadLibraryDeclaration(library, lookup_classes);
  }
}

void BytecodeReaderHelper::FindAndReadSpecificLibrary(const Library& library,
                                                      intptr_t num_libraries) {
  auto& uri = String::Handle(Z);
  for (intptr_t i = 0; i < num_libraries; ++i) {
    uri ^= ReadObject();
    const intptr_t library_offset =
        bytecode_component_->GetLibrariesOffset() + reader_.ReadUInt();

    if (uri.raw() == library.url()) {
      library.set_is_declared_in_bytecode(true);
      library.set_bytecode_offset(library_offset);

      AlternativeReadingScope alt(&reader_, library_offset);
      ReadLibraryDeclaration(library, /* lookup_classes = */ true);
      return;
    }
  }
}

void BytecodeReaderHelper::FindModifiedLibrariesForHotReload(
    BitVector* modified_libs,
    intptr_t num_libraries) {
  auto& uri = String::Handle(Z);
  auto& lib = Library::Handle(Z);
  for (intptr_t i = 0; i < num_libraries; ++i) {
    uri ^= ReadObject();
    reader_.ReadUInt();  // Skip offset.

    lib = Library::LookupLibrary(thread_, uri);
    if (!lib.IsNull() && !lib.is_dart_scheme()) {
      // This is a library that already exists so mark it as being modified.
      modified_libs->Add(lib.index());
    }
  }
}

void BytecodeReaderHelper::ReadParameterCovariance(
    const Function& function,
    BitVector* is_covariant,
    BitVector* is_generic_covariant_impl) {
  ASSERT(function.is_declared_in_bytecode());

  const intptr_t num_params = function.NumParameters();
  ASSERT(is_covariant->length() == num_params);
  ASSERT(is_generic_covariant_impl->length() == num_params);

  AlternativeReadingScope alt(&reader_, function.bytecode_offset());

  const intptr_t code_flags = reader_.ReadUInt();
  if ((code_flags & Code::kHasParameterFlagsFlag) != 0) {
    const intptr_t num_explicit_params = reader_.ReadUInt();
    ASSERT(num_params ==
           function.NumImplicitParameters() + num_explicit_params);

    for (intptr_t i = function.NumImplicitParameters(); i < num_params; ++i) {
      const intptr_t flags = reader_.ReadUInt();

      if ((flags & Parameter::kIsCovariantFlag) != 0) {
        is_covariant->Add(i);
      }
      if ((flags & Parameter::kIsGenericCovariantImplFlag) != 0) {
        is_generic_covariant_impl->Add(i);
      }
    }
  }
}

ObjectPtr BytecodeReaderHelper::BuildParameterDescriptor(
    const Function& function) {
  ASSERT(function.is_declared_in_bytecode());

  Object& result = Object::Handle(Z);
  if (!function.HasBytecode()) {
    result = BytecodeReader::ReadFunctionBytecode(Thread::Current(), function);
    if (result.IsError()) {
      return result.raw();
    }
  }

  const intptr_t num_params = function.NumParameters();
  const intptr_t num_implicit_params = function.NumImplicitParameters();
  const intptr_t num_explicit_params = num_params - num_implicit_params;
  const Array& descriptor = Array::Handle(
      Z, Array::New(num_explicit_params * Parser::kParameterEntrySize));

  // 1. Find isFinal in the Code declaration.
  bool found_final = false;
  if (!function.is_abstract()) {
    AlternativeReadingScope alt(&reader_, function.bytecode_offset());
    const intptr_t code_flags = reader_.ReadUInt();

    if ((code_flags & Code::kHasParameterFlagsFlag) != 0) {
      const intptr_t num_explicit_params_written = reader_.ReadUInt();
      ASSERT(num_explicit_params == num_explicit_params_written);
      for (intptr_t i = 0; i < num_explicit_params; ++i) {
        const intptr_t flags = reader_.ReadUInt();
        descriptor.SetAt(
            i * Parser::kParameterEntrySize + Parser::kParameterIsFinalOffset,
            Bool::Get((flags & Parameter::kIsFinalFlag) != 0));
      }
      found_final = true;
    }
  }
  if (!found_final) {
    for (intptr_t i = 0; i < num_explicit_params; ++i) {
      descriptor.SetAt(
          i * Parser::kParameterEntrySize + Parser::kParameterIsFinalOffset,
          Bool::Get(false));
    }
  }

  // 2. Find metadata implicitly after the function declaration's metadata.
  const Class& klass = Class::Handle(Z, function.Owner());
  const Library& library = Library::Handle(Z, klass.library());
  const Object& metadata = Object::Handle(
      Z, library.GetExtendedMetadata(function, num_explicit_params));
  if (metadata.IsError()) {
    return metadata.raw();
  }
  if (Array::Cast(metadata).Length() != 0) {
    for (intptr_t i = 0; i < num_explicit_params; i++) {
      result = Array::Cast(metadata).At(i);
      descriptor.SetAt(
          i * Parser::kParameterEntrySize + Parser::kParameterMetadataOffset,
          result);
    }
  }

  // 3. Find the defaultValues in the EntryOptional sequence.
  if (!function.is_abstract()) {
    const Bytecode& bytecode = Bytecode::Handle(Z, function.bytecode());
    ASSERT(!bytecode.IsNull());
    const ObjectPool& constants = ObjectPool::Handle(Z, bytecode.object_pool());
    ASSERT(!constants.IsNull());
    const KBCInstr* instr =
        reinterpret_cast<const KBCInstr*>(bytecode.PayloadStart());
    if (KernelBytecode::IsEntryOptionalOpcode(instr)) {
      // Note that number of fixed parameters may not match 'A' operand of
      // EntryOptional bytecode as [function] could be an implicit closure
      // function with an extra implicit argument, while bytecode corresponds
      // to a static function without any implicit arguments.
      const intptr_t num_fixed_params = function.num_fixed_parameters();
      const intptr_t num_opt_pos_params = KernelBytecode::DecodeB(instr);
      const intptr_t num_opt_named_params = KernelBytecode::DecodeC(instr);
      instr = KernelBytecode::Next(instr);
      ASSERT(num_opt_pos_params == function.NumOptionalPositionalParameters());
      ASSERT(num_opt_named_params == function.NumOptionalNamedParameters());
      ASSERT((num_opt_pos_params == 0) || (num_opt_named_params == 0));

      for (intptr_t i = 0; i < num_opt_pos_params; i++) {
        const KBCInstr* load_value_instr = instr;
        instr = KernelBytecode::Next(instr);
        ASSERT(KernelBytecode::IsLoadConstantOpcode(load_value_instr));
        result = constants.ObjectAt(KernelBytecode::DecodeE(load_value_instr));
        descriptor.SetAt((num_fixed_params - num_implicit_params + i) *
                                 Parser::kParameterEntrySize +
                             Parser::kParameterDefaultValueOffset,
                         result);
      }
      for (intptr_t i = 0; i < num_opt_named_params; i++) {
        const KBCInstr* load_name_instr = instr;
        const KBCInstr* load_value_instr =
            KernelBytecode::Next(load_name_instr);
        instr = KernelBytecode::Next(load_value_instr);
        ASSERT(KernelBytecode::IsLoadConstantOpcode(load_name_instr));
        result = constants.ObjectAt(KernelBytecode::DecodeE(load_name_instr));
        intptr_t param_index;
        for (param_index = num_fixed_params; param_index < num_params;
             param_index++) {
          if (function.ParameterNameAt(param_index) == result.raw()) {
            break;
          }
        }
        ASSERT(param_index < num_params);
        ASSERT(KernelBytecode::IsLoadConstantOpcode(load_value_instr));
        result = constants.ObjectAt(KernelBytecode::DecodeE(load_value_instr));
        descriptor.SetAt(
            (param_index - num_implicit_params) * Parser::kParameterEntrySize +
                Parser::kParameterDefaultValueOffset,
            result);
      }
    }
  }

  return descriptor.raw();
}

void BytecodeReaderHelper::ParseBytecodeFunction(
    ParsedFunction* parsed_function,
    const Function& function) {
  // Handle function kinds which don't have a user-defined body first.
  switch (function.kind()) {
    case FunctionLayout::kImplicitClosureFunction:
      ParseForwarderFunction(parsed_function, function,
                             Function::Handle(Z, function.parent_function()));
      return;
    case FunctionLayout::kDynamicInvocationForwarder:
      ParseForwarderFunction(parsed_function, function,
                             Function::Handle(Z, function.ForwardingTarget()));
      return;
    case FunctionLayout::kImplicitGetter:
    case FunctionLayout::kImplicitSetter:
    case FunctionLayout::kMethodExtractor:
      BytecodeScopeBuilder(parsed_function).BuildScopes();
      return;
    case FunctionLayout::kImplicitStaticGetter: {
      if (IsStaticFieldGetterGeneratedAsInitializer(function, Z)) {
        break;
      } else {
        BytecodeScopeBuilder(parsed_function).BuildScopes();
        return;
      }
    }
    case FunctionLayout::kRegularFunction:
    case FunctionLayout::kGetterFunction:
    case FunctionLayout::kSetterFunction:
    case FunctionLayout::kClosureFunction:
    case FunctionLayout::kConstructor:
    case FunctionLayout::kFieldInitializer:
      break;
    case FunctionLayout::kNoSuchMethodDispatcher:
    case FunctionLayout::kInvokeFieldDispatcher:
    case FunctionLayout::kSignatureFunction:
    case FunctionLayout::kIrregexpFunction:
    case FunctionLayout::kFfiTrampoline:
      UNREACHABLE();
      break;
  }

  // We only reach here if function has a bytecode body. Make sure it is
  // loaded and collect information about covariant parameters.

  if (!function.HasBytecode()) {
    ReadCode(function, function.bytecode_offset());
    ASSERT(function.HasBytecode());
  }

  // TODO(alexmarkov): simplify access to covariant / generic_covariant_impl
  //  flags of parameters so we won't need to read them separately.
  if (!parsed_function->HasCovariantParametersInfo()) {
    const intptr_t num_params = function.NumParameters();
    BitVector* covariant_parameters = new (Z) BitVector(Z, num_params);
    BitVector* generic_covariant_impl_parameters =
        new (Z) BitVector(Z, num_params);
    ReadParameterCovariance(function, covariant_parameters,
                            generic_covariant_impl_parameters);
    parsed_function->SetCovariantParameters(covariant_parameters);
    parsed_function->SetGenericCovariantImplParameters(
        generic_covariant_impl_parameters);
  }
}

void BytecodeReaderHelper::ParseForwarderFunction(
    ParsedFunction* parsed_function,
    const Function& function,
    const Function& target) {
  ASSERT(function.IsImplicitClosureFunction() ||
         function.IsDynamicInvocationForwarder());

  ASSERT(target.is_declared_in_bytecode());

  if (function.IsDynamicInvocationForwarder() &&
      target.IsImplicitSetterFunction()) {
    BytecodeScopeBuilder(parsed_function).BuildScopes();
    return;
  }

  if (!target.HasBytecode()) {
    ReadCode(target, target.bytecode_offset());
  }

  BytecodeScopeBuilder(parsed_function).BuildScopes();

  const auto& target_bytecode = Bytecode::Handle(Z, target.bytecode());
  const auto& obj_pool = ObjectPool::Handle(Z, target_bytecode.object_pool());

  AlternativeReadingScope alt(&reader_, target.bytecode_offset());

  const intptr_t flags = reader_.ReadUInt();
  const bool has_parameters_flags = (flags & Code::kHasParameterFlagsFlag) != 0;
  const bool has_forwarding_stub_target =
      (flags & Code::kHasForwardingStubTargetFlag) != 0;
  const bool has_default_function_type_args =
      (flags & Code::kHasDefaultFunctionTypeArgsFlag) != 0;
  const auto proc_attrs = kernel::ProcedureAttributesOf(target, Z);
  // TODO(alexmarkov): fix building of flow graph for implicit closures so
  // it would include missing checks and remove 'proc_attrs.has_tearoff_uses'
  // from this condition.
  const bool body_has_generic_covariant_impl_type_checks =
      proc_attrs.has_non_this_uses || proc_attrs.has_tearoff_uses;

  if (has_parameters_flags) {
    const intptr_t num_params = reader_.ReadUInt();
    const intptr_t num_implicit_params = function.NumImplicitParameters();
    for (intptr_t i = 0; i < num_params; ++i) {
      const intptr_t flags = reader_.ReadUInt();

      bool is_covariant = (flags & Parameter::kIsCovariantFlag) != 0;
      bool is_generic_covariant_impl =
          (flags & Parameter::kIsGenericCovariantImplFlag) != 0;
      bool is_required = (flags & Parameter::kIsRequiredFlag) != 0;

      if (is_required) {
        function.SetIsRequiredAt(num_implicit_params + i);
      }

      LocalVariable* variable =
          parsed_function->ParameterVariable(num_implicit_params + i);

      if (is_covariant) {
        variable->set_is_explicit_covariant_parameter();
      }

      const bool checked_in_method_body =
          is_covariant || (is_generic_covariant_impl &&
                           body_has_generic_covariant_impl_type_checks);

      if (checked_in_method_body) {
        variable->set_type_check_mode(LocalVariable::kSkipTypeCheck);
      } else {
        ASSERT(variable->type_check_mode() == LocalVariable::kDoTypeCheck);
      }
    }
  }

  if (has_forwarding_stub_target) {
    const intptr_t cp_index = reader_.ReadUInt();
    const auto& forwarding_stub_target =
        Function::CheckedZoneHandle(Z, obj_pool.ObjectAt(cp_index));
    parsed_function->MarkForwardingStub(&forwarding_stub_target);
  }

  if (has_default_function_type_args) {
    ASSERT(function.IsGeneric());
    const intptr_t cp_index = reader_.ReadUInt();
    const auto& type_args =
        TypeArguments::CheckedHandle(Z, obj_pool.ObjectAt(cp_index));
    parsed_function->SetDefaultFunctionTypeArguments(type_args);
  }

  if (function.HasOptionalParameters()) {
    const KBCInstr* raw_bytecode =
        reinterpret_cast<const KBCInstr*>(target_bytecode.PayloadStart());
    const KBCInstr* entry = raw_bytecode;
    raw_bytecode = KernelBytecode::Next(raw_bytecode);
    ASSERT(KernelBytecode::IsEntryOptionalOpcode(entry));
    ASSERT(KernelBytecode::DecodeB(entry) ==
           function.NumOptionalPositionalParameters());
    ASSERT(KernelBytecode::DecodeC(entry) ==
           function.NumOptionalNamedParameters());

    const intptr_t num_opt_params = function.NumOptionalParameters();
    ZoneGrowableArray<const Instance*>* default_values =
        new (Z) ZoneGrowableArray<const Instance*>(Z, num_opt_params);

    if (function.HasOptionalPositionalParameters()) {
      for (intptr_t i = 0, n = function.NumOptionalPositionalParameters();
           i < n; ++i) {
        const KBCInstr* load = raw_bytecode;
        raw_bytecode = KernelBytecode::Next(raw_bytecode);
        ASSERT(KernelBytecode::IsLoadConstantOpcode(load));
        const auto& value = Instance::CheckedZoneHandle(
            Z, obj_pool.ObjectAt(KernelBytecode::DecodeE(load)));
        default_values->Add(&value);
      }
    } else {
      const intptr_t num_fixed_params = function.num_fixed_parameters();
      auto& param_name = String::Handle(Z);
      default_values->EnsureLength(num_opt_params, nullptr);
      for (intptr_t i = 0; i < num_opt_params; ++i) {
        const KBCInstr* load_name = raw_bytecode;
        const KBCInstr* load_value = KernelBytecode::Next(load_name);
        raw_bytecode = KernelBytecode::Next(load_value);
        ASSERT(KernelBytecode::IsLoadConstantOpcode(load_name));
        ASSERT(KernelBytecode::IsLoadConstantOpcode(load_value));
        param_name ^= obj_pool.ObjectAt(KernelBytecode::DecodeE(load_name));
        const auto& value = Instance::CheckedZoneHandle(
            Z, obj_pool.ObjectAt(KernelBytecode::DecodeE(load_value)));

        const intptr_t num_params = function.NumParameters();
        intptr_t param_index = num_fixed_params;
        for (; param_index < num_params; ++param_index) {
          if (function.ParameterNameAt(param_index) == param_name.raw()) {
            break;
          }
        }
        ASSERT(param_index < num_params);
        ASSERT(default_values->At(param_index - num_fixed_params) == nullptr);
        (*default_values)[param_index - num_fixed_params] = &value;
      }
    }

    parsed_function->set_default_parameter_values(default_values);
  }
}

LibraryPtr BytecodeReaderHelper::ReadMain() {
  return Library::RawCast(ReadObject());
}

intptr_t BytecodeComponentData::GetVersion() const {
  return Smi::Value(Smi::RawCast(data_.At(kVersion)));
}

intptr_t BytecodeComponentData::GetStringsHeaderOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kStringsHeaderOffset)));
}

intptr_t BytecodeComponentData::GetStringsContentsOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kStringsContentsOffset)));
}

intptr_t BytecodeComponentData::GetObjectOffsetsOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kObjectOffsetsOffset)));
}

intptr_t BytecodeComponentData::GetNumObjects() const {
  return Smi::Value(Smi::RawCast(data_.At(kNumObjects)));
}

intptr_t BytecodeComponentData::GetObjectsContentsOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kObjectsContentsOffset)));
}

intptr_t BytecodeComponentData::GetMainOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kMainOffset)));
}

intptr_t BytecodeComponentData::GetNumLibraries() const {
  return Smi::Value(Smi::RawCast(data_.At(kNumLibraries)));
}

intptr_t BytecodeComponentData::GetLibraryIndexOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kLibraryIndexOffset)));
}

intptr_t BytecodeComponentData::GetLibrariesOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kLibrariesOffset)));
}

intptr_t BytecodeComponentData::GetNumClasses() const {
  return Smi::Value(Smi::RawCast(data_.At(kNumClasses)));
}

intptr_t BytecodeComponentData::GetClassesOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kClassesOffset)));
}

intptr_t BytecodeComponentData::GetMembersOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kMembersOffset)));
}

intptr_t BytecodeComponentData::GetNumCodes() const {
  return Smi::Value(Smi::RawCast(data_.At(kNumCodes)));
}

intptr_t BytecodeComponentData::GetCodesOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kCodesOffset)));
}

intptr_t BytecodeComponentData::GetSourcePositionsOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kSourcePositionsOffset)));
}

intptr_t BytecodeComponentData::GetSourceFilesOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kSourceFilesOffset)));
}

intptr_t BytecodeComponentData::GetLineStartsOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kLineStartsOffset)));
}

intptr_t BytecodeComponentData::GetLocalVariablesOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kLocalVariablesOffset)));
}

intptr_t BytecodeComponentData::GetAnnotationsOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kAnnotationsOffset)));
}

void BytecodeComponentData::SetObject(intptr_t index, const Object& obj) const {
  data_.SetAt(kNumFields + index, obj);
}

ObjectPtr BytecodeComponentData::GetObject(intptr_t index) const {
  return data_.At(kNumFields + index);
}

ArrayPtr BytecodeComponentData::New(Zone* zone,
                                    intptr_t version,
                                    intptr_t num_objects,
                                    intptr_t strings_header_offset,
                                    intptr_t strings_contents_offset,
                                    intptr_t object_offsets_offset,
                                    intptr_t objects_contents_offset,
                                    intptr_t main_offset,
                                    intptr_t num_libraries,
                                    intptr_t library_index_offset,
                                    intptr_t libraries_offset,
                                    intptr_t num_classes,
                                    intptr_t classes_offset,
                                    intptr_t members_offset,
                                    intptr_t num_codes,
                                    intptr_t codes_offset,
                                    intptr_t source_positions_offset,
                                    intptr_t source_files_offset,
                                    intptr_t line_starts_offset,
                                    intptr_t local_variables_offset,
                                    intptr_t annotations_offset,
                                    Heap::Space space) {
  const Array& data =
      Array::Handle(zone, Array::New(kNumFields + num_objects, space));
  Smi& smi_handle = Smi::Handle(zone);

  smi_handle = Smi::New(version);
  data.SetAt(kVersion, smi_handle);

  smi_handle = Smi::New(strings_header_offset);
  data.SetAt(kStringsHeaderOffset, smi_handle);

  smi_handle = Smi::New(strings_contents_offset);
  data.SetAt(kStringsContentsOffset, smi_handle);

  smi_handle = Smi::New(object_offsets_offset);
  data.SetAt(kObjectOffsetsOffset, smi_handle);

  smi_handle = Smi::New(num_objects);
  data.SetAt(kNumObjects, smi_handle);

  smi_handle = Smi::New(objects_contents_offset);
  data.SetAt(kObjectsContentsOffset, smi_handle);

  smi_handle = Smi::New(main_offset);
  data.SetAt(kMainOffset, smi_handle);

  smi_handle = Smi::New(num_libraries);
  data.SetAt(kNumLibraries, smi_handle);

  smi_handle = Smi::New(library_index_offset);
  data.SetAt(kLibraryIndexOffset, smi_handle);

  smi_handle = Smi::New(libraries_offset);
  data.SetAt(kLibrariesOffset, smi_handle);

  smi_handle = Smi::New(num_classes);
  data.SetAt(kNumClasses, smi_handle);

  smi_handle = Smi::New(classes_offset);
  data.SetAt(kClassesOffset, smi_handle);

  smi_handle = Smi::New(members_offset);
  data.SetAt(kMembersOffset, smi_handle);

  smi_handle = Smi::New(num_codes);
  data.SetAt(kNumCodes, smi_handle);

  smi_handle = Smi::New(codes_offset);
  data.SetAt(kCodesOffset, smi_handle);

  smi_handle = Smi::New(source_positions_offset);
  data.SetAt(kSourcePositionsOffset, smi_handle);

  smi_handle = Smi::New(source_files_offset);
  data.SetAt(kSourceFilesOffset, smi_handle);

  smi_handle = Smi::New(line_starts_offset);
  data.SetAt(kLineStartsOffset, smi_handle);

  smi_handle = Smi::New(local_variables_offset);
  data.SetAt(kLocalVariablesOffset, smi_handle);

  smi_handle = Smi::New(annotations_offset);
  data.SetAt(kAnnotationsOffset, smi_handle);

  return data.raw();
}

ErrorPtr BytecodeReader::ReadFunctionBytecode(Thread* thread,
                                              const Function& function) {
  ASSERT(!FLAG_precompiled_mode);
  ASSERT(!function.HasBytecode());
  ASSERT(thread->sticky_error() == Error::null());
  ASSERT(Thread::Current()->IsMutatorThread());

  VMTagScope tagScope(thread, VMTag::kLoadBytecodeTagId);

#if defined(SUPPORT_TIMELINE)
  TimelineBeginEndScope tbes(thread, Timeline::GetCompilerStream(),
                             "BytecodeReader::ReadFunctionBytecode");
  // This increases bytecode reading time by ~7%, so only keep it around for
  // debugging.
#if defined(DEBUG)
  tbes.SetNumArguments(1);
  tbes.CopyArgument(0, "Function", function.ToQualifiedCString());
#endif  // defined(DEBUG)
#endif  // !defined(SUPPORT_TIMELINE)

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    StackZone stack_zone(thread);
    Zone* const zone = stack_zone.GetZone();
    HANDLESCOPE(thread);

    auto& bytecode = Bytecode::Handle(zone);

    switch (function.kind()) {
      case FunctionLayout::kImplicitGetter:
        bytecode = Object::implicit_getter_bytecode().raw();
        break;
      case FunctionLayout::kImplicitSetter:
        bytecode = Object::implicit_setter_bytecode().raw();
        break;
      case FunctionLayout::kImplicitStaticGetter:
        if (!IsStaticFieldGetterGeneratedAsInitializer(function, zone)) {
          bytecode = Object::implicit_static_getter_bytecode().raw();
        }
        break;
      case FunctionLayout::kMethodExtractor:
        bytecode = Object::method_extractor_bytecode().raw();
        break;
      case FunctionLayout::kInvokeFieldDispatcher:
        if (Class::Handle(zone, function.Owner()).id() == kClosureCid) {
          bytecode = Object::invoke_closure_bytecode().raw();
        } else {
          bytecode = Object::invoke_field_bytecode().raw();
        }
        break;
      case FunctionLayout::kNoSuchMethodDispatcher:
        bytecode = Object::nsm_dispatcher_bytecode().raw();
        break;
      case FunctionLayout::kDynamicInvocationForwarder: {
        const Function& target =
            Function::Handle(zone, function.ForwardingTarget());
        if (!target.HasBytecode()) {
          // The forwarder will use the target's bytecode to handle optional
          // parameters.
          const Error& error =
              Error::Handle(zone, ReadFunctionBytecode(thread, target));
          if (!error.IsNull()) {
            return error.raw();
          }
        }
        {
          const Script& script = Script::Handle(zone, target.script());
          TranslationHelper translation_helper(thread);
          translation_helper.InitFromScript(script);

          ActiveClass active_class;
          BytecodeComponentData bytecode_component(
              &Array::Handle(zone, translation_helper.GetBytecodeComponent()));
          ASSERT(!bytecode_component.IsNull());
          BytecodeReaderHelper bytecode_reader(
              &translation_helper, &active_class, &bytecode_component);

          const Array& checks = Array::Handle(
              zone, bytecode_reader.CreateForwarderChecks(target));
          function.SetForwardingChecks(checks);
        }
        bytecode = Object::dynamic_invocation_forwarder_bytecode().raw();
      } break;
      default:
        break;
    }

    if (!bytecode.IsNull()) {
      function.AttachBytecode(bytecode);
    } else if (function.is_declared_in_bytecode()) {
      const intptr_t code_offset = function.bytecode_offset();
      if (code_offset != 0) {
        CompilerState compiler_state(thread, FLAG_precompiled_mode);

        const Script& script = Script::Handle(zone, function.script());
        TranslationHelper translation_helper(thread);
        translation_helper.InitFromScript(script);

        ActiveClass active_class;

        // Setup a [ActiveClassScope] and a [ActiveMemberScope] which will be
        // used e.g. for type translation.
        const Class& klass = Class::Handle(zone, function.Owner());
        Function& outermost_function =
            Function::Handle(zone, function.GetOutermostFunction());

        ActiveClassScope active_class_scope(&active_class, &klass);
        ActiveMemberScope active_member(&active_class, &outermost_function);

        BytecodeComponentData bytecode_component(
            &Array::Handle(zone, translation_helper.GetBytecodeComponent()));
        ASSERT(!bytecode_component.IsNull());
        BytecodeReaderHelper bytecode_reader(&translation_helper, &active_class,
                                             &bytecode_component);

        bytecode_reader.ReadCode(function, code_offset);
      }
    }
    return Error::null();
  } else {
    return thread->StealStickyError();
  }
}

ObjectPtr BytecodeReader::ReadAnnotation(const Field& annotation_field) {
  ASSERT(annotation_field.is_declared_in_bytecode());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());

  const Script& script = Script::Handle(zone, annotation_field.Script());
  TranslationHelper translation_helper(thread);
  translation_helper.InitFromScript(script);

  ActiveClass active_class;

  BytecodeComponentData bytecode_component(
      &Array::Handle(zone, translation_helper.GetBytecodeComponent()));
  ASSERT(!bytecode_component.IsNull());
  BytecodeReaderHelper bytecode_reader(&translation_helper, &active_class,
                                       &bytecode_component);

  AlternativeReadingScope alt(&bytecode_reader.reader(),
                              annotation_field.bytecode_offset());

  return bytecode_reader.ReadObject();
}

ArrayPtr BytecodeReader::ReadExtendedAnnotations(const Field& annotation_field,
                                                 intptr_t count) {
  ASSERT(annotation_field.is_declared_in_bytecode());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());

  const Script& script = Script::Handle(zone, annotation_field.Script());
  TranslationHelper translation_helper(thread);
  translation_helper.InitFromScript(script);

  ActiveClass active_class;

  BytecodeComponentData bytecode_component(
      &Array::Handle(zone, translation_helper.GetBytecodeComponent()));
  ASSERT(!bytecode_component.IsNull());
  BytecodeReaderHelper bytecode_reader(&translation_helper, &active_class,
                                       &bytecode_component);

  AlternativeReadingScope alt(&bytecode_reader.reader(),
                              annotation_field.bytecode_offset());

  bytecode_reader.ReadObject();  // Discard main annotation.

  Array& result = Array::Handle(zone, Array::New(count));
  Object& element = Object::Handle(zone);
  for (intptr_t i = 0; i < count; i++) {
    element = bytecode_reader.ReadObject();
    result.SetAt(i, element);
  }
  return result.raw();
}

void BytecodeReader::ResetObjectTable(const KernelProgramInfo& info) {
  Thread* thread = Thread::Current();
  TranslationHelper translation_helper(thread);
  translation_helper.InitFromKernelProgramInfo(info);
  ActiveClass active_class;
  BytecodeComponentData bytecode_component(&Array::Handle(
      thread->zone(), translation_helper.GetBytecodeComponent()));
  ASSERT(!bytecode_component.IsNull());
  BytecodeReaderHelper bytecode_reader(&translation_helper, &active_class,
                                       &bytecode_component);
  bytecode_reader.ResetObjects();
}

void BytecodeReader::LoadClassDeclaration(const Class& cls) {
  TIMELINE_DURATION(Thread::Current(), Compiler,
                    "BytecodeReader::LoadClassDeclaration");

  ASSERT(cls.is_declared_in_bytecode());
  ASSERT(!cls.is_declaration_loaded());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());

  const Script& script = Script::Handle(zone, cls.script());
  TranslationHelper translation_helper(thread);
  translation_helper.InitFromScript(script);

  ActiveClass active_class;
  ActiveClassScope active_class_scope(&active_class, &cls);

  BytecodeComponentData bytecode_component(
      &Array::Handle(zone, translation_helper.GetBytecodeComponent()));
  ASSERT(!bytecode_component.IsNull());
  BytecodeReaderHelper bytecode_reader(&translation_helper, &active_class,
                                       &bytecode_component);

  AlternativeReadingScope alt(&bytecode_reader.reader(), cls.bytecode_offset());

  bytecode_reader.ReadClassDeclaration(cls);
}

void BytecodeReader::FinishClassLoading(const Class& cls) {
  ASSERT(cls.is_declared_in_bytecode());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());

  const Script& script = Script::Handle(zone, cls.script());
  TranslationHelper translation_helper(thread);
  translation_helper.InitFromScript(script);

  ActiveClass active_class;
  ActiveClassScope active_class_scope(&active_class, &cls);

  BytecodeComponentData bytecode_component(
      &Array::Handle(zone, translation_helper.GetBytecodeComponent()));
  ASSERT(!bytecode_component.IsNull());
  BytecodeReaderHelper bytecode_reader(&translation_helper, &active_class,
                                       &bytecode_component);

  AlternativeReadingScope alt(&bytecode_reader.reader(), cls.bytecode_offset());

  // If this is a dart:internal.ClassID class ignore field declarations
  // contained in the Kernel file and instead inject our own const
  // fields.
  const bool discard_fields = cls.InjectCIDFields();

  bytecode_reader.ReadMembers(cls, discard_fields);
}

ObjectPtr BytecodeReader::GetBytecodeAttribute(const Object& key,
                                               const String& name) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const auto* object_store = thread->isolate()->object_store();
  if (object_store->bytecode_attributes() == Object::null()) {
    return Object::null();
  }
  BytecodeAttributesMap map(object_store->bytecode_attributes());
  const auto& attrs = Array::CheckedHandle(zone, map.GetOrNull(key));
  ASSERT(map.Release().raw() == object_store->bytecode_attributes());
  if (attrs.IsNull()) {
    return Object::null();
  }
  auto& obj = Object::Handle(zone);
  for (intptr_t i = 0, n = attrs.Length(); i + 1 < n; i += 2) {
    obj = attrs.At(i);
    if (obj.raw() == name.raw()) {
      return attrs.At(i + 1);
    }
  }
  return Object::null();
}

InferredTypeMetadata InferredTypeBytecodeAttribute::GetInferredTypeAt(
    Zone* zone,
    const Array& attr,
    intptr_t index) {
  ASSERT(index + kNumElements <= attr.Length());
  const auto& type = AbstractType::CheckedHandle(zone, attr.At(index + 1));
  const intptr_t flags = Smi::Value(Smi::RawCast(attr.At(index + 2)));
  if (!type.IsNull()) {
    intptr_t cid = Type::Cast(type).type_class_id();
    return InferredTypeMetadata(cid, flags);
  } else {
    return InferredTypeMetadata(kDynamicCid, flags);
  }
}

#if !defined(PRODUCT)
LocalVarDescriptorsPtr BytecodeReader::ComputeLocalVarDescriptors(
    Zone* zone,
    const Function& function,
    const Bytecode& bytecode) {
  ASSERT(function.is_declared_in_bytecode());
  ASSERT(function.HasBytecode());
  ASSERT(!bytecode.IsNull());
  ASSERT(function.bytecode() == bytecode.raw());

  LocalVarDescriptorsBuilder vars;

  if (function.IsLocalFunction()) {
    const auto& parent = Function::Handle(zone, function.parent_function());
    ASSERT(parent.is_declared_in_bytecode() && parent.HasBytecode());
    const auto& parent_bytecode = Bytecode::Handle(zone, parent.bytecode());
    const auto& parent_vars = LocalVarDescriptors::Handle(
        zone, parent_bytecode.GetLocalVarDescriptors());
    for (intptr_t i = 0; i < parent_vars.Length(); ++i) {
      LocalVarDescriptorsLayout::VarInfo var_info;
      parent_vars.GetInfo(i, &var_info);
      // Include parent's context variable if variable's scope
      // intersects with the local function range.
      // It is not enough to check if local function is declared within the
      // scope of variable, because in case of async functions closure has
      // the same range as original function.
      if (var_info.kind() == LocalVarDescriptorsLayout::kContextVar &&
          ((var_info.begin_pos <= function.token_pos() &&
            function.token_pos() <= var_info.end_pos) ||
           (function.token_pos() <= var_info.begin_pos &&
            var_info.begin_pos <= function.end_token_pos()))) {
        vars.Add(LocalVarDescriptorsBuilder::VarDesc{
            &String::Handle(zone, parent_vars.GetName(i)), var_info});
      }
    }
  }

  if (bytecode.HasLocalVariablesInfo()) {
    intptr_t scope_id = 0;
    intptr_t context_level = -1;
    BytecodeLocalVariablesIterator local_vars(zone, bytecode);
    while (local_vars.MoveNext()) {
      switch (local_vars.Kind()) {
        case BytecodeLocalVariablesIterator::kScope: {
          ++scope_id;
          context_level = local_vars.ContextLevel();
        } break;
        case BytecodeLocalVariablesIterator::kVariableDeclaration: {
          LocalVarDescriptorsBuilder::VarDesc desc;
          desc.name = &String::Handle(zone, local_vars.Name());
          if (local_vars.IsCaptured()) {
            desc.info.set_kind(LocalVarDescriptorsLayout::kContextVar);
            desc.info.scope_id = context_level;
            desc.info.set_index(local_vars.Index());
          } else {
            desc.info.set_kind(LocalVarDescriptorsLayout::kStackVar);
            desc.info.scope_id = scope_id;
            if (local_vars.Index() < 0) {
              // Parameter
              ASSERT(local_vars.Index() < -kKBCParamEndSlotFromFp);
              desc.info.set_index(-local_vars.Index() - kKBCParamEndSlotFromFp);
            } else {
              desc.info.set_index(-local_vars.Index());
            }
          }
          desc.info.declaration_pos = local_vars.DeclarationTokenPos();
          desc.info.begin_pos = local_vars.StartTokenPos();
          desc.info.end_pos = local_vars.EndTokenPos();
          vars.Add(desc);
        } break;
        case BytecodeLocalVariablesIterator::kContextVariable: {
          ASSERT(local_vars.Index() >= 0);
          const intptr_t context_variable_index = -local_vars.Index();
          LocalVarDescriptorsBuilder::VarDesc desc;
          desc.name = &Symbols::CurrentContextVar();
          desc.info.set_kind(LocalVarDescriptorsLayout::kSavedCurrentContext);
          desc.info.scope_id = 0;
          desc.info.declaration_pos = TokenPosition::kMinSource;
          desc.info.begin_pos = TokenPosition::kMinSource;
          desc.info.end_pos = TokenPosition::kMinSource;
          desc.info.set_index(context_variable_index);
          vars.Add(desc);
        } break;
      }
    }
  }

  return vars.Done();
}
#endif  // !defined(PRODUCT)

bool IsStaticFieldGetterGeneratedAsInitializer(const Function& function,
                                               Zone* zone) {
  ASSERT(function.kind() == FunctionLayout::kImplicitStaticGetter);

  const auto& field = Field::Handle(zone, function.accessor_field());
  return field.is_declared_in_bytecode() && field.is_const() &&
         field.has_nontrivial_initializer();
}

}  // namespace kernel
}  // namespace dart
