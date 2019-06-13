// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/bytecode_reader.h"

#include "vm/bit_vector.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/code_descriptors.h"
#include "vm/compiler/assembler/disassembler_kbc.h"
#include "vm/compiler/frontend/bytecode_scope_builder.h"
#include "vm/constants_kbc.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/reusable_handles.h"
#include "vm/stack_frame_kbc.h"
#include "vm/timeline.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

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

  // No parsing is needed if function has bytecode attached.
  // With one exception: implicit functions with artificial are still handled
  // by shared flow graph builder which requires scopes/parsing.
  if (function.HasBytecode() &&
      (function.kind() != RawFunction::kImplicitGetter) &&
      (function.kind() != RawFunction::kImplicitSetter) &&
      (function.kind() != RawFunction::kImplicitStaticGetter) &&
      (function.kind() != RawFunction::kMethodExtractor) &&
      (function.kind() != RawFunction::kInvokeFieldDispatcher) &&
      (function.kind() != RawFunction::kDynamicInvocationForwarder) &&
      (function.kind() != RawFunction::kNoSuchMethodDispatcher)) {
    return;
  }

  BytecodeComponentData bytecode_component(
      Array::Handle(helper_->zone_, GetBytecodeComponent()));
  BytecodeReaderHelper bytecode_reader(&H, active_class_, &bytecode_component);

  bytecode_reader.ParseBytecodeFunction(parsed_function, function);
}

bool BytecodeMetadataHelper::ReadMembers(intptr_t node_offset,
                                         const Class& cls,
                                         bool discard_fields) {
  TIMELINE_DURATION(Thread::Current(), Compiler,
                    "BytecodeMetadataHelper::ReadMembers");

  ASSERT(node_offset > 0);
  const intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return false;
  }

  ASSERT(Thread::Current()->IsMutatorThread());

  BytecodeComponentData bytecode_component(
      Array::Handle(helper_->zone_, GetBytecodeComponent()));
  BytecodeReaderHelper bytecode_reader(&H, active_class_, &bytecode_component);

  AlternativeReadingScope alt(&bytecode_reader.reader(), md_offset);

  intptr_t members_offset = bytecode_reader.reader().ReadUInt();

  bytecode_reader.ReadMembers(cls, members_offset, discard_fields);

  return true;
}

RawLibrary* BytecodeMetadataHelper::GetMainLibrary() {
  const intptr_t md_offset = GetComponentMetadataPayloadOffset();
  if (md_offset < 0) {
    return Library::null();
  }

  BytecodeComponentData bytecode_component(
      Array::Handle(helper_->zone_, GetBytecodeComponent()));
  const intptr_t main_offset = bytecode_component.GetMainOffset();
  if (main_offset == 0) {
    return Library::null();
  }

  BytecodeReaderHelper bytecode_reader(&H, active_class_, &bytecode_component);
  AlternativeReadingScope alt(&bytecode_reader.reader(), main_offset);
  return bytecode_reader.ReadMain();
}

RawArray* BytecodeMetadataHelper::GetBytecodeComponent() {
  RawArray* array = translation_helper_.GetBytecodeComponent();
  if (array == Array::null()) {
    array = ReadBytecodeComponent();
    ASSERT(array != Array::null());
  }
  return array;
}

RawArray* BytecodeMetadataHelper::ReadBytecodeComponent() {
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
  ASSERT(code_offset > 0);

  AlternativeReadingScope alt(&reader_, code_offset);

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
    for (intptr_t i = 0; i < num_params; ++i) {
      reader_.ReadUInt();
    }
  }
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

  {
    // While reading pool entries, deopt_ids are allocated for
    // ICData objects.
    //
    // TODO(alexmarkov): allocate deopt_ids for closures separately
    DeoptIdScope deopt_id_scope(thread_, 0);

    ReadConstantPool(function, pool);
  }

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
    }
  }
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

RawArray* BytecodeReaderHelper::CreateForwarderChecks(
    const Function& function) {
  ASSERT(function.kind() != RawFunction::kDynamicInvocationForwarder);
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
      if (!bound.IsTopType() && !type_param.IsGenericCovariantImpl()) {
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
    if (!type.IsTopType() && !is_generic_covariant_impl.Contains(i) &&
        !is_covariant.Contains(i)) {
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

  const intptr_t flags = reader_.ReadUInt();

  Object& parent = Object::Handle(Z, ReadObject());
  if (!parent.IsFunction()) {
    ASSERT(parent.IsField());
    ASSERT(function.kind() == RawFunction::kStaticFieldInitializer);
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

  closures_->SetAt(closureIndex, closure);

  Type& signature_type = Type::Handle(
      Z, ReadFunctionSignature(closure,
                               (flags & kHasOptionalPositionalParamsFlag) != 0,
                               (flags & kHasOptionalNamedParamsFlag) != 0,
                               (flags & kHasTypeParamsFlag) != 0,
                               /* has_positional_param_names = */ true));

  closure.SetSignatureType(signature_type);
}

RawType* BytecodeReaderHelper::ReadFunctionSignature(
    const Function& func,
    bool has_optional_positional_params,
    bool has_optional_named_params,
    bool has_type_params,
    bool has_positional_param_names) {
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
  const Array& parameter_names =
      Array::Handle(Z, Array::New(num_params, Heap::kOld));
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

  type ^= ReadObject();
  func.set_result_type(type);

  // Finalize function type.
  type = func.SignatureType();
  type = ClassFinalizer::FinalizeType(*(active_class_->klass), type);
  return Type::Cast(type).raw();
}

void BytecodeReaderHelper::ReadTypeParametersDeclaration(
    const Class& parameterized_class,
    const Function& parameterized_function) {
  ASSERT(parameterized_class.IsNull() != parameterized_function.IsNull());

  const intptr_t num_type_params = reader_.ReadUInt();
  ASSERT(num_type_params > 0);

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
    parameter = TypeParameter::New(
        parameterized_class, parameterized_function, i, name, bound,
        /* is_generic_covariant_impl = */ false, TokenPosition::kNoSource);
    type_parameters.SetTypeAt(i, parameter);
  }

  if (!parameterized_class.IsNull()) {
    parameterized_class.set_type_parameters(type_parameters);
  } else if (!parameterized_function.IsFactory()) {
    // Do not set type parameters for factories, as VM uses class type
    // parameters instead.
    parameterized_function.set_type_parameters(type_parameters);
    function_type_type_parameters_ = &type_parameters;
  }

  // Step b) Fill in the bounds of all [TypeParameter]s.
  for (intptr_t i = 0; i < num_type_params; ++i) {
    parameter ^= type_parameters.TypeAt(i);
    bound ^= ReadObject();
    parameter.set_bound(bound);
  }
}

void BytecodeReaderHelper::ReadConstantPool(const Function& function,
                                            const ObjectPool& pool) {
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
    kICData,
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
  };

  enum InvocationKind {
    method,  // x.foo(...) or foo(...)
    getter,  // x.foo
    setter   // x.foo = ...
  };

  const int kInvocationKindMask = 0x3;
  const int kFlagDynamic = 1 << 2;

  Object& obj = Object::Handle(Z);
  Object& elem = Object::Handle(Z);
  Array& array = Array::Handle(Z);
  Field& field = Field::Handle(Z);
  Class& cls = Class::Handle(Z);
  String& name = String::Handle(Z);
  const String* simpleInstanceOf = nullptr;
  const intptr_t obj_count = pool.Length();
  for (intptr_t i = 0; i < obj_count; ++i) {
    const intptr_t tag = reader_.ReadTag();
    switch (tag) {
      case ConstantPoolTag::kInvalid:
        UNREACHABLE();
      case ConstantPoolTag::kICData: {
        intptr_t flags = reader_.ReadByte();
        InvocationKind kind =
            static_cast<InvocationKind>(flags & kInvocationKindMask);
        bool isDynamic = (flags & kFlagDynamic) != 0;
        name ^= ReadObject();
        ASSERT(name.IsSymbol());
        intptr_t arg_desc_index = reader_.ReadUInt();
        ASSERT(arg_desc_index < i);
        array ^= pool.ObjectAt(arg_desc_index);
        if (simpleInstanceOf == nullptr) {
          simpleInstanceOf =
              &Library::PrivateCoreLibName(Symbols::_simpleInstanceOf());
        }
        intptr_t checked_argument_count = 1;
        if ((kind == InvocationKind::method) &&
            ((MethodTokenRecognizer::RecognizeTokenKind(name) !=
              Token::kILLEGAL) ||
             (name.raw() == simpleInstanceOf->raw()))) {
          intptr_t argument_count = ArgumentsDescriptor(array).Count();
          ASSERT(argument_count <= 2);
          checked_argument_count = argument_count;
        }
        // Do not mangle == or call:
        //   * operator == takes an Object so its either not checked or checked
        //     at the entry because the parameter is marked covariant, neither
        //     of those cases require a dynamic invocation forwarder;
        //   * we assume that all closures are entered in a checked way.
        if (isDynamic && (kind != InvocationKind::getter) &&
            !FLAG_precompiled_mode && I->should_emit_strong_mode_checks() &&
            (name.raw() != Symbols::EqualOperator().raw()) &&
            (name.raw() != Symbols::Call().raw())) {
          name = Function::CreateDynamicInvocationForwarderName(name);
        }
        obj =
            ICData::New(function, name,
                        array,  // Arguments descriptor.
                        thread_->compiler_state().GetNextDeoptId(),
                        checked_argument_count, ICData::RebindRule::kInstance);
      } break;
      case ConstantPoolTag::kStaticField:
        obj = ReadObject();
        ASSERT(obj.IsField());
        break;
      case ConstantPoolTag::kInstanceField:
        field ^= ReadObject();
        // InstanceField constant occupies 2 entries.
        // The first entry is used for field offset.
        obj = Smi::New(field.Offset() / kWordSize);
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
        obj = Smi::New(cls.type_arguments_field_offset() / kWordSize);
        break;
      case ConstantPoolTag::kType:
        obj = ReadObject();
        ASSERT(obj.IsAbstractType());
        break;
      case ConstantPoolTag::kClosureFunction: {
        intptr_t closure_index = reader_.ReadUInt();
        obj = closures_->At(closure_index);
        ASSERT(obj.IsFunction());
      } break;
      case ConstantPoolTag::kEndClosureFunctionScope: {
        // Entry is not used and set to null.
        obj = Object::null();
      } break;
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
      default:
        UNREACHABLE();
    }
    pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                   ObjectPool::Patchability::kNotPatchable);
    pool.SetObjectAt(i, obj);
  }
}

RawBytecode* BytecodeReaderHelper::ReadBytecode(const ObjectPool& pool) {
#if defined(SUPPORT_TIMELINE)
  TIMELINE_DURATION(Thread::Current(), CompilerVerbose,
                    "BytecodeReaderHelper::ReadBytecode");
#endif  // defined(SUPPORT_TIMELINE)
  intptr_t size = reader_.ReadUInt();
  intptr_t offset = reader_.offset();

  static_assert(KernelBytecode::kMinSupportedBytecodeFormatVersion < 7,
                "Cleanup support for old bytecode format versions");
  if (bytecode_component_->GetVersion() < 7) {
    const intptr_t kAlignment = 4;
    offset = Utils::RoundUp(offset, kAlignment);
  }

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
    Array& handler_types = Array::ZoneHandle(Z);
    DescriptorList* pc_descriptors_list = new (Z) DescriptorList(64);
    ExceptionHandlerList* exception_handlers_list =
        new (Z) ExceptionHandlerList();

    static_assert(KernelBytecode::kMinSupportedBytecodeFormatVersion < 7,
                  "Cleanup support for old bytecode format versions");
    const int kPCShifter = (bytecode_component_->GetVersion() < 7) ? 2 : 0;

    // Encoding of ExceptionsTable is described in
    // pkg/vm/lib/bytecode/exceptions.dart.
    for (intptr_t try_index = 0; try_index < try_block_count; try_index++) {
      intptr_t outer_try_index_plus1 = reader_.ReadUInt();
      intptr_t outer_try_index = outer_try_index_plus1 - 1;
      // PcDescriptors are expressed in terms of return addresses.
      intptr_t start_pc =
          KernelBytecode::BytecodePcToOffset(reader_.ReadUInt() << kPCShifter,
                                             /* is_return_address = */ true);
      intptr_t end_pc =
          KernelBytecode::BytecodePcToOffset(reader_.ReadUInt() << kPCShifter,
                                             /* is_return_address = */ true);
      intptr_t handler_pc =
          KernelBytecode::BytecodePcToOffset(reader_.ReadUInt() << kPCShifter,
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
      pc_descriptors_list->AddDescriptor(RawPcDescriptors::kOther, start_pc,
                                         DeoptId::kNone,
                                         TokenPosition::kNoSource, try_index);
      pc_descriptors_list->AddDescriptor(RawPcDescriptors::kOther, end_pc,
                                         DeoptId::kNone,
                                         TokenPosition::kNoSource, -1);

      exception_handlers_list->AddHandler(
          try_index, outer_try_index, handler_pc, TokenPosition::kNoSource,
          is_generated, handler_types, needs_stacktrace);
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

  intptr_t offset = reader_.ReadUInt();
  USE(offset);

#if !defined(PRODUCT)
  bytecode.set_local_variables_binary_offset(
      bytecode_component_->GetLocalVariablesOffset() + offset);
#endif
}

RawTypedData* BytecodeReaderHelper::NativeEntry(const Function& function,
                                                const String& external_name) {
  MethodRecognizer::Kind kind = MethodRecognizer::RecognizeKind(function);
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
      break;
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

RawArray* BytecodeReaderHelper::ReadBytecodeComponent(intptr_t md_offset) {
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
  BytecodeReader::UseBytecodeVersion(version);

  reader_.ReadUInt32();  // Skip stringTable.numItems
  const intptr_t string_table_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip objectTable.numItems
  const intptr_t object_table_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip main.numItems
  const intptr_t main_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip members.numItems
  const intptr_t members_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip codes.numItems
  const intptr_t codes_offset = start_offset + reader_.ReadUInt32();

  reader_.ReadUInt32();  // Skip sourcePositions.numItems
  const intptr_t sources_positions_offset = start_offset + reader_.ReadUInt32();

  intptr_t local_variables_offset = 0;
  static_assert(KernelBytecode::kMinSupportedBytecodeFormatVersion < 9,
                "Cleanup condition");
  if (version >= 9) {
    reader_.ReadUInt32();  // Skip localVariables.numItems
    local_variables_offset = start_offset + reader_.ReadUInt32();
  }

  reader_.ReadUInt32();  // Skip annotations.numItems
  const intptr_t annotations_offset = start_offset + reader_.ReadUInt32();

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
  reader_.set_offset(objects_contents_offset + objects_size);

  const Array& bytecode_component_array = Array::Handle(
      Z, BytecodeComponentData::New(
             Z, version, num_objects, string_table_offset,
             strings_contents_offset, objects_contents_offset, main_offset,
             members_offset, codes_offset, sources_positions_offset,
             local_variables_offset, annotations_offset, Heap::kOld));

  BytecodeComponentData bytecode_component(bytecode_component_array);

  // Read object offsets.
  Smi& offs = Smi::Handle(Z);
  for (intptr_t i = 0; i < num_objects; ++i) {
    offs = Smi::New(reader_.ReadUInt());
    bytecode_component.SetObject(i, offs);
  }

  H.SetBytecodeComponent(bytecode_component_array);

  return bytecode_component_array.raw();
}

RawObject* BytecodeReaderHelper::ReadObject() {
  uint32_t header = reader_.ReadUInt();
  if ((header & kReferenceBit) != 0) {
    intptr_t index = header >> kIndexShift;
    if (index == 0) {
      return Object::null();
    }
    RawObject* obj = bytecode_component_->GetObject(index);
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

RawString* BytecodeReaderHelper::ConstructorName(const Class& cls,
                                                 const String& name) {
  GrowableHandlePtrArray<const String> pieces(Z, 3);
  pieces.Add(String::Handle(Z, cls.Name()));
  pieces.Add(Symbols::Dot());
  pieces.Add(name);
  return Symbols::FromConcatAll(thread_, pieces);
}

RawObject* BytecodeReaderHelper::ReadObjectContents(uint32_t header) {
  ASSERT(((header & kReferenceBit) == 0));

  // Must be in sync with enum ObjectKind in
  // pkg/vm/lib/bytecode/object_table.dart.
  enum ObjectKind {
    kInvalid,
    kLibrary,
    kClass,
    kMember,
    kClosure,
    kSimpleType,
    kTypeParameter,
    kGenericType,
    kFunctionType,
    kName,
    kTypeArguments,
    kFinalizedGenericType,
    kConstObject,
    kArgDesc,
  };

  // Member flags, must be in sync with _MemberHandle constants in
  // pkg/vm/lib/bytecode/object_table.dart.
  const intptr_t kFlagIsField = kFlagBit0;
  const intptr_t kFlagIsConstructor = kFlagBit1;

  // SimpleType flags, must be in sync with _SimpleTypeHandle constants in
  // pkg/vm/lib/bytecode/object_table.dart.
  const intptr_t kFlagIsDynamic = kFlagBit0;
  const intptr_t kFlagIsVoid = kFlagBit1;

  // FunctionType flags, must be in sync with _FunctionTypeHandle constants in
  // pkg/vm/lib/bytecode/object_table.dart.
  const int kFlagHasOptionalPositionalParams = kFlagBit0;
  const int kFlagHasOptionalNamedParams = kFlagBit1;
  const int kFlagHasTypeParams = kFlagBit2;

  // ArgDesc flags, must be in sync with _ArgDescHandle constants in
  // pkg/vm/lib/bytecode/object_table.dart.
  const int kFlagHasNamedArgs = kFlagBit0;
  const int kFlagHasTypeArgs = kFlagBit1;

  const intptr_t kind = (header >> kKindShift) & kKindMask;
  const intptr_t flags = header & kFlagsMask;

  switch (kind) {
    case kInvalid:
      UNREACHABLE();
      break;
    case kLibrary: {
      const String& uri = String::Handle(Z, ReadString());
      RawLibrary* library = Library::LookupLibrary(thread_, uri);
      if (library == Library::null()) {
        FATAL1("Unable to find library %s", uri.ToCString());
      }
      return library;
    }
    case kClass: {
      const Library& library = Library::CheckedHandle(Z, ReadObject());
      const String& class_name = String::CheckedHandle(Z, ReadObject());
      if (class_name.raw() == Symbols::Empty().raw()) {
        return library.toplevel_class();
      }
      RawClass* cls = library.LookupClassAllowPrivate(class_name);
      if (cls == Class::null()) {
        FATAL2("Unable to find class %s in %s", class_name.ToCString(),
               library.ToCString());
      }
      return cls;
    }
    case kMember: {
      const Class& cls = Class::CheckedHandle(Z, ReadObject());
      String& name = String::CheckedHandle(Z, ReadObject());
      if ((flags & kFlagIsField) != 0) {
        RawField* field = cls.LookupFieldAllowPrivate(name);
        if (field == Field::null()) {
          FATAL2("Unable to find field %s in %s", name.ToCString(),
                 cls.ToCString());
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
        RawFunction* function = cls.LookupFunctionAllowPrivate(name);
        if (function == Function::null()) {
          // When requesting a getter, also return method extractors.
          if (Field::IsGetterName(name)) {
            String& method_name =
                String::Handle(Z, Field::NameFromGetter(name));
            function = cls.LookupFunctionAllowPrivate(method_name);
            if (function != Function::null()) {
              function = Function::Handle(Z, function).GetMethodExtractor(name);
              if (function != Function::null()) {
                return function;
              }
            }
          }
          FATAL2("Unable to find function %s in %s", name.ToCString(),
                 cls.ToCString());
        }
        return function;
      }
    }
    case kClosure: {
      ReadObject();  // Skip enclosing member.
      const intptr_t closure_index = reader_.ReadUInt();
      return closures_->At(closure_index);
    }
    case kSimpleType: {
      const Class& cls = Class::CheckedHandle(Z, ReadObject());
      if ((flags & kFlagIsDynamic) != 0) {
        ASSERT(cls.IsNull());
        return AbstractType::dynamic_type().raw();
      }
      if ((flags & kFlagIsVoid) != 0) {
        ASSERT(cls.IsNull());
        return AbstractType::void_type().raw();
      }
      return cls.DeclarationType();
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
      AbstractType& type =
          AbstractType::Handle(Z, type_parameters.TypeAt(index_in_parent));
      // TODO(alexmarkov): figure out how to skip this type finalization
      // (consider finalizing type parameters of classes/functions eagerly).
      return ClassFinalizer::FinalizeType(*active_class_->klass, type);
    }
    case kGenericType: {
      const Class& cls = Class::CheckedHandle(Z, ReadObject());
      const TypeArguments& type_arguments =
          TypeArguments::Handle(Z, ReadTypeArguments(Class::Handle(Z)));
      const Type& type = Type::Handle(
          Z, Type::New(cls, type_arguments, TokenPosition::kNoSource));
      return ClassFinalizer::FinalizeType(*active_class_->klass, type);
    }
    case kFunctionType: {
      Function& signature_function = Function::ZoneHandle(
          Z, Function::NewSignatureFunction(*active_class_->klass,
                                            active_class_->enclosing != NULL
                                                ? *active_class_->enclosing
                                                : Function::null_function(),
                                            TokenPosition::kNoSource));

      return ReadFunctionSignature(
          signature_function, (flags & kFlagHasOptionalPositionalParams) != 0,
          (flags & kFlagHasOptionalNamedParams) != 0,
          (flags & kFlagHasTypeParams) != 0,
          /* has_positional_param_names = */ false);
    }
    case kName: {
      const Library& library = Library::CheckedHandle(Z, ReadObject());
      if (library.IsNull()) {
        return ReadString();
      } else {
        const String& name =
            String::Handle(Z, ReadString(/* is_canonical = */ false));
        return library.PrivateName(name);
      }
    }
    case kTypeArguments: {
      return ReadTypeArguments(Class::Handle(Z));
    }
    case kFinalizedGenericType: {
      const Class& cls = Class::CheckedHandle(Z, ReadObject());
      const TypeArguments& type_arguments =
          TypeArguments::CheckedHandle(Z, ReadObject());
      const Type& type = Type::Handle(
          Z, Type::New(cls, type_arguments, TokenPosition::kNoSource));
      type.SetIsFinalized();
      return type.Canonicalize();
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
        return ArgumentsDescriptor::New(num_type_args, num_arguments);
      } else {
        const intptr_t num_arg_names = reader_.ReadListLength();
        const Array& array = Array::Handle(Z, Array::New(num_arg_names));
        String& name = String::Handle(Z);
        for (intptr_t i = 0; i < num_arg_names; ++i) {
          name ^= ReadObject();
          array.SetAt(i, name);
        }
        return ArgumentsDescriptor::New(num_type_args, num_arguments, array);
      }
    }
    default:
      UNREACHABLE();
  }

  return Object::null();
}

RawObject* BytecodeReaderHelper::ReadConstObject(intptr_t tag) {
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
    default:
      UNREACHABLE();
  }
  return Object::null();
}

RawString* BytecodeReaderHelper::ReadString(bool is_canonical) {
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

RawTypeArguments* BytecodeReaderHelper::ReadTypeArguments(
    const Class& instantiator) {
  const intptr_t length = reader_.ReadUInt();
  TypeArguments& type_arguments =
      TypeArguments::ZoneHandle(Z, TypeArguments::New(length));
  AbstractType& type = AbstractType::Handle(Z);
  for (intptr_t i = 0; i < length; ++i) {
    type ^= ReadObject();
    type_arguments.SetTypeAt(i, type);
  }

  type_arguments = type_arguments.Canonicalize();

  if (instantiator.IsNull()) {
    return type_arguments.raw();
  }

  if (type_arguments.IsNull() && instantiator.NumTypeArguments() == length) {
    return type_arguments.raw();
  }

  // We make a temporary [Type] object and use `ClassFinalizer::FinalizeType` to
  // finalize the argument types.
  // (This can for example make the [type_arguments] vector larger)
  type = Type::New(instantiator, type_arguments, TokenPosition::kNoSource);
  type = ClassFinalizer::FinalizeType(*active_class_->klass, type);
  return type.arguments();
}

void BytecodeReaderHelper::ReadMembers(const Class& cls,
                                       intptr_t members_offset,
                                       bool discard_fields) {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(cls.is_type_finalized());
  ASSERT(!cls.is_loaded());

  const intptr_t offset =
      bytecode_component_->GetMembersOffset() + members_offset;
  AlternativeReadingScope alt_md(&reader_, offset);

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
  const int kHasInitializerFlag = 1 << 0;
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
    const bool has_initializer = (flags & kHasInitializerFlag) != 0;
    const bool has_pragma = (flags & kHasPragmaFlag) != 0;

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
                       (flags & kIsReflectableFlag) != 0, script_class, type,
                       position, end_position);

    field.set_is_declared_in_bytecode(true);
    field.set_has_pragma(has_pragma);
    field.set_is_covariant((flags & kIsCovariantFlag) != 0);
    field.set_is_generic_covariant_impl((flags & kIsGenericCovariantImplFlag) !=
                                        0);
    field.set_has_initializer(has_initializer);

    if (!has_initializer) {
      value ^= ReadObject();
      if (is_static) {
        field.SetStaticValue(value, true);
      } else {
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

    if (has_initializer && is_static) {
      const intptr_t code_offset = reader_.ReadUInt();
      field.set_bytecode_offset(code_offset +
                                bytecode_component_->GetCodesOffset());
      field.SetStaticValue(Object::sentinel(), true);
    }

    if ((flags & kHasGetterFlag) != 0) {
      name ^= ReadObject();
      function = Function::New(name,
                               is_static ? RawFunction::kImplicitStaticGetter
                                         : RawFunction::kImplicitGetter,
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
      if (is_const && has_initializer) {
        function.set_bytecode_offset(field.bytecode_offset());
      }
      H.SetupFieldAccessorFunction(cls, function, type);
      functions_->SetAt(function_index_++, function);
    }

    if ((flags & kHasSetterFlag) != 0) {
      ASSERT((!is_static) && (!is_final) && (!is_const));
      name ^= ReadObject();
      function = Function::New(name, RawFunction::kImplicitSetter,
                               false,  // is_static
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

    fields.SetAt(i, field);
  }

  if (cls.is_enum_class()) {
    // Add static field 'const _deleted_enum_sentinel'.
    field =
        Field::New(Symbols::_DeletedEnumSentinel(),
                   /* is_static = */ true,
                   /* is_final = */ true,
                   /* is_const = */ true,
                   /* is_reflectable = */ false, cls, Object::dynamic_type(),
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

RawPatchClass* BytecodeReaderHelper::GetPatchClass(const Class& cls,
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

  for (intptr_t i = 0; i < num_functions; ++i) {
    intptr_t flags = reader_.ReadUInt();

    const bool is_static = (flags & kIsStaticFlag) != 0;
    const bool is_factory = (flags & kIsFactoryFlag) != 0;
    const bool is_native = (flags & kIsNativeFlag) != 0;
    const bool has_pragma = (flags & kHasPragmaFlag) != 0;

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

    RawFunction::Kind kind = RawFunction::kRegularFunction;
    if ((flags & kIsGetterFlag) != 0) {
      kind = RawFunction::kGetterFunction;
    } else if ((flags & kIsSetterFlag) != 0) {
      kind = RawFunction::kSetterFunction;
    } else if ((flags & (kIsConstructorFlag | kIsFactoryFlag)) != 0) {
      kind = RawFunction::kConstructor;
      name = ConstructorName(cls, name);
    }

    // Expression evaluation functions are not supported yet.
    ASSERT(!name.Equals(Symbols::DebugProcedureName()));

    function = Function::New(name, kind, is_static, (flags & kIsConstFlag) != 0,
                             (flags & kIsAbstractFlag) != 0,
                             (flags & kIsExternalFlag) != 0, is_native,
                             script_class, position);

    // Declare function scope as types (type parameters) in function
    // signature may back-reference to the function being declared.
    // At this moment, owner class is not fully loaded yet and it won't be
    // able to serve function lookup requests.
    FunctionScope function_scope(this, function, name, cls);

    function.set_is_declared_in_bytecode(true);
    function.set_has_pragma(has_pragma);
    function.set_end_token_pos(end_position);
    function.set_is_no_such_method_forwarder(
        (flags & kIsNoSuchMethodForwarderFlag) != 0);
    function.set_is_reflectable((flags & kIsReflectableFlag) != 0);
    function.set_is_debuggable((flags & kIsDebuggableFlag) != 0);

    if ((flags & kIsSyncStarFlag) != 0) {
      function.set_modifier(RawFunction::kSyncGen);
    } else if ((flags & kIsAsyncFlag) != 0) {
      function.set_modifier(RawFunction::kAsync);
      function.set_is_inlinable(!FLAG_causal_async_stacks);
    } else if ((flags & kIsAsyncStarFlag) != 0) {
      function.set_modifier(RawFunction::kAsyncGen);
      function.set_is_inlinable(!FLAG_causal_async_stacks);
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

    parameter_names = Array::New(num_params, Heap::kOld);
    function.set_parameter_names(parameter_names);

    intptr_t param_index = 0;
    if (!is_static) {
      function.SetParameterTypeAt(param_index, H.GetDeclarationType(cls));
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

void BytecodeReaderHelper::ParseBytecodeFunction(
    ParsedFunction* parsed_function,
    const Function& function) {
  switch (function.kind()) {
    case RawFunction::kImplicitClosureFunction:
      ParseForwarderFunction(parsed_function, function,
                             Function::Handle(Z, function.parent_function()));
      break;
    case RawFunction::kDynamicInvocationForwarder:
      ParseForwarderFunction(
          parsed_function, function,
          Function::Handle(Z,
                           function.GetTargetOfDynamicInvocationForwarder()));
      break;
    case RawFunction::kImplicitGetter:
    case RawFunction::kImplicitSetter:
      BytecodeScopeBuilder(parsed_function).BuildScopes();
      break;
    case RawFunction::kImplicitStaticGetter: {
      if (IsStaticFieldGetterGeneratedAsInitializer(function, Z)) {
        ReadCode(function, function.bytecode_offset());
      } else {
        BytecodeScopeBuilder(parsed_function).BuildScopes();
      }
      break;
    }
    case RawFunction::kStaticFieldInitializer:
      ReadCode(function, function.bytecode_offset());
      break;
    case RawFunction::kMethodExtractor:
      BytecodeScopeBuilder(parsed_function).BuildScopes();
      break;
    case RawFunction::kRegularFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
    case RawFunction::kClosureFunction:
    case RawFunction::kConstructor:
      ReadCode(function, function.bytecode_offset());
      break;
    case RawFunction::kNoSuchMethodDispatcher:
    case RawFunction::kInvokeFieldDispatcher:
    case RawFunction::kSignatureFunction:
    case RawFunction::kIrregexpFunction:
    case RawFunction::kFfiTrampoline:
      UNREACHABLE();
      break;
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

  if (has_parameters_flags) {
    const intptr_t num_params = reader_.ReadUInt();
    const intptr_t num_implicit_params = function.NumImplicitParameters();
    for (intptr_t i = 0; i < num_params; ++i) {
      const intptr_t flags = reader_.ReadUInt();

      bool is_covariant = (flags & Parameter::kIsCovariantFlag) != 0;
      bool is_generic_covariant_impl =
          (flags & Parameter::kIsGenericCovariantImplFlag) != 0;

      LocalVariable* variable =
          parsed_function->ParameterVariable(num_implicit_params + i);

      if (is_covariant) {
        variable->set_is_explicit_covariant_parameter();
      }

      const bool checked_in_method_body =
          is_covariant || is_generic_covariant_impl;

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

RawLibrary* BytecodeReaderHelper::ReadMain() {
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

intptr_t BytecodeComponentData::GetObjectsContentsOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kObjectsContentsOffset)));
}

intptr_t BytecodeComponentData::GetMainOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kMainOffset)));
}

intptr_t BytecodeComponentData::GetMembersOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kMembersOffset)));
}

intptr_t BytecodeComponentData::GetCodesOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kCodesOffset)));
}

intptr_t BytecodeComponentData::GetSourcePositionsOffset() const {
  return Smi::Value(Smi::RawCast(data_.At(kSourcePositionsOffset)));
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

RawObject* BytecodeComponentData::GetObject(intptr_t index) const {
  return data_.At(kNumFields + index);
}

RawArray* BytecodeComponentData::New(Zone* zone,
                                     intptr_t version,
                                     intptr_t num_objects,
                                     intptr_t strings_header_offset,
                                     intptr_t strings_contents_offset,
                                     intptr_t objects_contents_offset,
                                     intptr_t main_offset,
                                     intptr_t members_offset,
                                     intptr_t codes_offset,
                                     intptr_t source_positions_offset,
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

  smi_handle = Smi::New(objects_contents_offset);
  data.SetAt(kObjectsContentsOffset, smi_handle);

  smi_handle = Smi::New(main_offset);
  data.SetAt(kMainOffset, smi_handle);

  smi_handle = Smi::New(members_offset);
  data.SetAt(kMembersOffset, smi_handle);

  smi_handle = Smi::New(codes_offset);
  data.SetAt(kCodesOffset, smi_handle);

  smi_handle = Smi::New(source_positions_offset);
  data.SetAt(kSourcePositionsOffset, smi_handle);

  smi_handle = Smi::New(local_variables_offset);
  data.SetAt(kLocalVariablesOffset, smi_handle);

  smi_handle = Smi::New(annotations_offset);
  data.SetAt(kAnnotationsOffset, smi_handle);

  return data.raw();
}

RawError* BytecodeReader::ReadFunctionBytecode(Thread* thread,
                                               const Function& function) {
  ASSERT(!FLAG_precompiled_mode);
  ASSERT(!function.HasBytecode());
  ASSERT(thread->sticky_error() == Error::null());
  ASSERT(Thread::Current()->IsMutatorThread());

  VMTagScope tagScope(thread, VMTag::kLoadBytecodeTagId);

#if defined(SUPPORT_TIMELINE)
  TimelineDurationScope tds(thread, Timeline::GetCompilerStream(),
                            "BytecodeReader::ReadFunctionBytecode");
  // This increases bytecode reading time by ~7%, so only keep it around for
  // debugging.
#if defined(DEBUG)
  tds.SetNumArguments(1);
  tds.CopyArgument(0, "Function", function.ToQualifiedCString());
#endif  // defined(DEBUG)
#endif  // !defined(SUPPORT_TIMELINE)

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    StackZone stack_zone(thread);
    Zone* const zone = stack_zone.GetZone();
    HANDLESCOPE(thread);

    auto& bytecode = Bytecode::Handle(zone);

    switch (function.kind()) {
      case RawFunction::kImplicitGetter:
        bytecode = Object::implicit_getter_bytecode().raw();
        break;
      case RawFunction::kImplicitSetter:
        bytecode = Object::implicit_setter_bytecode().raw();
        break;
      case RawFunction::kImplicitStaticGetter:
        if (!IsStaticFieldGetterGeneratedAsInitializer(function, zone)) {
          bytecode = Object::implicit_static_getter_bytecode().raw();
        }
        break;
      case RawFunction::kMethodExtractor:
        bytecode = Object::method_extractor_bytecode().raw();
        break;
      case RawFunction::kInvokeFieldDispatcher:
        if (Class::Handle(zone, function.Owner()).id() == kClosureCid) {
          bytecode = Object::invoke_closure_bytecode().raw();
        } else {
          bytecode = Object::invoke_field_bytecode().raw();
        }
        break;
      case RawFunction::kNoSuchMethodDispatcher:
        bytecode = Object::nsm_dispatcher_bytecode().raw();
        break;
      case RawFunction::kDynamicInvocationForwarder: {
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
              Array::Handle(zone, translation_helper.GetBytecodeComponent()));
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
        CompilerState compiler_state(thread);

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
        ActiveTypeParametersScope active_type_params(&active_class, function,
                                                     zone);

        BytecodeComponentData bytecode_component(
            Array::Handle(zone, translation_helper.GetBytecodeComponent()));
        ASSERT(!bytecode_component.IsNull());
        BytecodeReaderHelper bytecode_reader(&translation_helper, &active_class,
                                             &bytecode_component);

        bytecode_reader.ReadCode(function, code_offset);
      }
    }

#if !defined(PRODUCT)
    if (function.HasBytecode()) {
      thread->isolate()->debugger()->NotifyBytecodeLoaded(function);
    }
#endif

    return Error::null();
  } else {
    return thread->StealStickyError();
  }
}

RawObject* BytecodeReader::ReadAnnotation(const Field& annotation_field) {
  ASSERT(annotation_field.is_declared_in_bytecode());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());

  const Script& script = Script::Handle(zone, annotation_field.Script());
  TranslationHelper translation_helper(thread);
  translation_helper.InitFromScript(script);

  ActiveClass active_class;

  BytecodeComponentData bytecode_component(
      Array::Handle(zone, translation_helper.GetBytecodeComponent()));
  ASSERT(!bytecode_component.IsNull());
  BytecodeReaderHelper bytecode_reader(&translation_helper, &active_class,
                                       &bytecode_component);

  AlternativeReadingScope alt(&bytecode_reader.reader(),
                              annotation_field.bytecode_offset());

  return bytecode_reader.ReadObject();
}

#if !defined(PRODUCT)
RawLocalVarDescriptors* BytecodeReader::ComputeLocalVarDescriptors(
    Zone* zone,
    const Function& function,
    const Bytecode& bytecode) {
  ASSERT(function.is_declared_in_bytecode());
  ASSERT(function.HasBytecode());
  ASSERT(!bytecode.IsNull());
  ASSERT(function.bytecode() == bytecode.raw());

  struct VarDesc {
    const String* name;
    RawLocalVarDescriptors::VarInfo info;
  };
  GrowableArray<VarDesc> vars(8);

  if (function.IsLocalFunction()) {
    const auto& parent = Function::Handle(zone, function.parent_function());
    ASSERT(parent.is_declared_in_bytecode() && parent.HasBytecode());
    const auto& parent_bytecode = Bytecode::Handle(zone, parent.bytecode());
    const auto& parent_vars = LocalVarDescriptors::Handle(
        zone, parent_bytecode.GetLocalVarDescriptors());
    for (intptr_t i = 0; i < parent_vars.Length(); ++i) {
      RawLocalVarDescriptors::VarInfo var_info;
      parent_vars.GetInfo(i, &var_info);
      // Include parent's context variable if variable's scope
      // intersects with the local function range.
      // It is not enough to check if local function is declared within the
      // scope of variable, because in case of async functions closure has
      // the same range as original function.
      if (var_info.kind() == RawLocalVarDescriptors::kContextVar &&
          ((var_info.begin_pos <= function.token_pos() &&
            function.token_pos() <= var_info.end_pos) ||
           (function.token_pos() <= var_info.begin_pos &&
            var_info.begin_pos <= function.end_token_pos()))) {
        vars.Add(
            VarDesc{&String::Handle(zone, parent_vars.GetName(i)), var_info});
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
          VarDesc desc;
          desc.name = &String::Handle(zone, local_vars.Name());
          if (local_vars.IsCaptured()) {
            desc.info.set_kind(RawLocalVarDescriptors::kContextVar);
            desc.info.scope_id = context_level;
            desc.info.set_index(local_vars.Index());
          } else {
            desc.info.set_kind(RawLocalVarDescriptors::kStackVar);
            desc.info.scope_id = scope_id;
            if (local_vars.Index() < 0) {
              // Parameter
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
          VarDesc desc;
          desc.name = &Symbols::CurrentContextVar();
          desc.info.set_kind(RawLocalVarDescriptors::kSavedCurrentContext);
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

  if (vars.is_empty()) {
    return Object::empty_var_descriptors().raw();
  }
  const LocalVarDescriptors& var_desc = LocalVarDescriptors::Handle(
      zone, LocalVarDescriptors::New(vars.length()));
  for (intptr_t i = 0; i < vars.length(); i++) {
    var_desc.SetVar(i, *(vars[i].name), &vars[i].info);
  }
  return var_desc.raw();
}
#endif  // !defined(PRODUCT)

static_assert(KernelBytecode::kMinSupportedBytecodeFormatVersion < 7,
              "Cleanup support for old bytecode format versions");
void BytecodeReader::UseBytecodeVersion(intptr_t version) {
  Isolate* isolate = Isolate::Current();
  bool using_old = isolate->is_using_old_bytecode_instructions();
  bool using_new = isolate->is_using_new_bytecode_instructions();
  if (version < 7) {
    using_old = true;
    isolate->set_is_using_old_bytecode_instructions(true);
  } else {
    using_new = true;
    isolate->set_is_using_new_bytecode_instructions(true);
  }

  if (using_old && using_new) {
    FATAL1(
        "Unable to use both new and old bytecode instructions in the same Dart "
        "isolate (%s)",
        isolate->name());
  }
}

bool IsStaticFieldGetterGeneratedAsInitializer(const Function& function,
                                               Zone* zone) {
  ASSERT(function.kind() == RawFunction::kImplicitStaticGetter);

  const auto& field = Field::Handle(zone, function.accessor_field());
  return field.is_declared_in_bytecode() && field.is_const() &&
         field.has_initializer();
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
