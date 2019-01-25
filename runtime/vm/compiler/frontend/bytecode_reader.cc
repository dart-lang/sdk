// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/bytecode_reader.h"

#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/code_descriptors.h"
#include "vm/compiler/assembler/disassembler_kbc.h"
#include "vm/constants_kbc.h"
#include "vm/dart_entry.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/reusable_handles.h"
#include "vm/timeline.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

#define Z (helper_->zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()

namespace dart {

DEFINE_FLAG(bool, dump_kernel_bytecode, false, "Dump kernel bytecode");

namespace kernel {

BytecodeMetadataHelper::BytecodeMetadataHelper(KernelReaderHelper* helper,
                                               TypeTranslator* type_translator,
                                               ActiveClass* active_class)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ false),
      type_translator_(*type_translator),
      active_class_(active_class),
      bytecode_component_(nullptr),
      closures_(nullptr),
      function_type_type_parameters_(nullptr) {}

bool BytecodeMetadataHelper::HasBytecode(intptr_t node_offset) {
  const intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  return (md_offset >= 0);
}

void BytecodeMetadataHelper::ReadMetadata(const Function& function) {
#if defined(SUPPORT_TIMELINE)
  TimelineDurationScope tds(Thread::Current(), Timeline::GetCompilerStream(),
                            "BytecodeMetadataHelper::ReadMetadata");
  // This increases bytecode reading time by ~7%, so only keep it around for
  // debugging.
#if defined(DEBUG)
  tds.SetNumArguments(1);
  tds.CopyArgument(0, "Function", function.ToQualifiedCString());
#endif  // defined(DEBUG)
#endif  // !defined(PRODUCT)

  const intptr_t node_offset = function.kernel_offset();
  const intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return;
  }

  ASSERT(Thread::Current()->IsMutatorThread());

  Array& bytecode_component_array =
      Array::Handle(Z, translation_helper_.GetBytecodeComponent());
  if (bytecode_component_array.IsNull()) {
    bytecode_component_array = ReadBytecodeComponent();
    ASSERT(!bytecode_component_array.IsNull());
  }
  BytecodeComponentData bytecode_component(bytecode_component_array);
  bytecode_component_ = &bytecode_component;

  AlternativeReadingScope alt(&helper_->reader_, &H.metadata_payloads(),
                              md_offset);

  const int kHasExceptionsTableFlag = 1 << 0;
  const int kHasSourcePositionsFlag = 1 << 1;
  const int kHasNullableFieldsFlag = 1 << 2;
  const int kHasClosuresFlag = 1 << 3;

  const intptr_t flags = helper_->reader_.ReadUInt();
  const bool has_exceptions_table = (flags & kHasExceptionsTableFlag) != 0;
  const bool has_source_positions = (flags & kHasSourcePositionsFlag) != 0;
  const bool has_nullable_fields = (flags & kHasNullableFieldsFlag) != 0;
  const bool has_closures = (flags & kHasClosuresFlag) != 0;

  intptr_t num_closures = 0;
  if (has_closures) {
    num_closures = helper_->ReadListLength();
    closures_ = &Array::Handle(Z, Array::New(num_closures));
    for (intptr_t i = 0; i < num_closures; i++) {
      ReadClosureDeclaration(function, i);
    }
  }

  // Create object pool and read pool entries.
  const intptr_t obj_count = helper_->reader_.ReadListLength();
  const ObjectPool& pool =
      ObjectPool::Handle(helper_->zone_, ObjectPool::New(obj_count));

  {
    // While reading pool entries, deopt_ids are allocated for
    // ICData objects.
    //
    // TODO(alexmarkov): allocate deopt_ids for closures separately
    DeoptIdScope deopt_id_scope(H.thread(), 0);

    ReadConstantPool(function, pool);
  }

  // Read bytecode and attach to function.
  const Bytecode& bytecode =
      Bytecode::Handle(helper_->zone_, ReadBytecode(pool));
  function.AttachBytecode(bytecode);
  ASSERT(bytecode.GetBinary(helper_->zone_) ==
         helper_->reader_.typed_data()->raw());

  ReadExceptionsTable(bytecode, has_exceptions_table);

  ReadSourcePositions(bytecode, has_source_positions);

  if (FLAG_dump_kernel_bytecode) {
    KernelBytecodeDisassembler::Disassemble(function);
  }

  // Initialization of fields with null literal is elided from bytecode.
  // Record the corresponding stores if field guards are enabled.
  if (has_nullable_fields) {
    ASSERT(function.IsGenerativeConstructor());
    const intptr_t num_fields = helper_->ReadListLength();
    if (I->use_field_guards()) {
      Field& field = Field::Handle(helper_->zone_);
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
    Function& closure = Function::Handle(helper_->zone_);
    Bytecode& closure_bytecode = Bytecode::Handle(helper_->zone_);
    for (intptr_t i = 0; i < num_closures; i++) {
      closure ^= closures_->At(i);

      const intptr_t flags = helper_->reader_.ReadUInt();
      const bool has_exceptions_table = (flags & kHasExceptionsTableFlag) != 0;
      const bool has_source_positions = (flags & kHasSourcePositionsFlag) != 0;

      // Read closure bytecode and attach to closure function.
      closure_bytecode = ReadBytecode(pool);
      closure.AttachBytecode(closure_bytecode);
      ASSERT(bytecode.GetBinary(helper_->zone_) ==
             helper_->reader_.typed_data()->raw());

      ReadExceptionsTable(closure_bytecode, has_exceptions_table);

      ReadSourcePositions(closure_bytecode, has_source_positions);

      if (FLAG_dump_kernel_bytecode) {
        KernelBytecodeDisassembler::Disassemble(closure);
      }
    }
  }

  bytecode_component_ = nullptr;
}

void BytecodeMetadataHelper::ReadClosureDeclaration(const Function& function,
                                                    intptr_t closureIndex) {
  const int kHasOptionalPositionalParams = 1 << 0;
  const int kHasOptionalNamedParams = 1 << 1;
  const int kHasTypeParams = 1 << 2;

  const intptr_t flags = helper_->reader_.ReadUInt();

  Object& parent = Object::Handle(Z, ReadObject());
  if (!parent.IsFunction()) {
    ASSERT(parent.IsField());
    ASSERT(function.kind() == RawFunction::kImplicitStaticFinalGetter);
    // Closure in a static field initializer, so use current function as parent.
    parent = function.raw();
  }

  String& name = String::CheckedHandle(Z, ReadObject());
  ASSERT(name.IsSymbol());

  const Function& closure = Function::Handle(
      Z, Function::NewClosureFunction(name, Function::Cast(parent),
                                      TokenPosition::kNoSource));

  closures_->SetAt(closureIndex, closure);

  Type& signature_type =
      Type::Handle(Z, ReadFunctionSignature(
                          closure, (flags & kHasOptionalPositionalParams) != 0,
                          (flags & kHasOptionalNamedParams) != 0,
                          (flags & kHasTypeParams) != 0,
                          /* has_positional_param_names = */ true));

  closure.SetSignatureType(signature_type);
}

RawType* BytecodeMetadataHelper::ReadFunctionSignature(
    const Function& func,
    bool has_optional_positional_params,
    bool has_optional_named_params,
    bool has_type_params,
    bool has_positional_param_names) {
  FunctionTypeScope function_type_scope(this);

  if (has_type_params) {
    const intptr_t num_type_params = helper_->reader_.ReadUInt();
    ReadTypeParametersDeclaration(Class::Handle(Z), func, num_type_params);
    function_type_type_parameters_ =
        &TypeArguments::Handle(Z, func.type_parameters());
  }

  const intptr_t kImplicitClosureParam = 1;
  const intptr_t num_params =
      kImplicitClosureParam + helper_->reader_.ReadUInt();

  intptr_t num_required_params = num_params;
  if (has_optional_positional_params || has_optional_named_params) {
    num_required_params = kImplicitClosureParam + helper_->reader_.ReadUInt();
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
  type ^= ClassFinalizer::FinalizeType(*(active_class_->klass), type);
  return Type::Cast(type).raw();
}

void BytecodeMetadataHelper::ReadTypeParametersDeclaration(
    const Class& parameterized_class,
    const Function& parameterized_function,
    intptr_t num_type_params) {
  ASSERT(parameterized_class.IsNull() != parameterized_function.IsNull());
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
    parameter = TypeParameter::New(parameterized_class, parameterized_function,
                                   i, name, bound, TokenPosition::kNoSource);
    type_parameters.SetTypeAt(i, parameter);
  }

  if (!parameterized_class.IsNull()) {
    parameterized_class.set_type_parameters(type_parameters);
  } else {
    parameterized_function.set_type_parameters(type_parameters);
  }

  // Step b) Fill in the bounds of all [TypeParameter]s.
  for (intptr_t i = 0; i < num_type_params; ++i) {
    parameter ^= type_parameters.TypeAt(i);
    bound ^= ReadObject();
    parameter.set_bound(bound);
  }
}

void BytecodeMetadataHelper::ReadConstantPool(const Function& function,
                                              const ObjectPool& pool) {
  TIMELINE_DURATION(Thread::Current(), Compiler,
                    "BytecodeMetadataHelper::ReadConstantPool");

  // These enums and the code below reading the constant pool from kernel must
  // be kept in sync with pkg/vm/lib/bytecode/constant_pool.dart.
  enum ConstantPoolTag {
    kInvalid,
    kNull,
    kString,
    kInt,
    kDouble,
    kBool,
    kArgDesc,
    kICData,
    kStaticICData,
    kStaticField,
    kInstanceField,
    kClass,
    kTypeArgumentsField,
    kTearOff,
    kType,
    kTypeArguments,
    kList,
    kInstance,
    kTypeArgumentsForInstanceAllocation,
    kClosureFunction,
    kEndClosureFunctionScope,
    kNativeEntry,
    kSubtypeTestCache,
    kPartialTearOffInstantiation,
    kEmptyTypeArguments,
    kSymbol,
    kInterfaceCall,
  };

  enum InvocationKind {
    method,  // x.foo(...) or foo(...)
    getter,  // x.foo
    setter   // x.foo = ...
  };

  const int kInvocationKindMask = 0x3;
  const int kFlagDynamic = 1 << 2;

  Object& obj = Object::Handle(helper_->zone_);
  Object& elem = Object::Handle(helper_->zone_);
  Array& array = Array::Handle(helper_->zone_);
  Field& field = Field::Handle(helper_->zone_);
  Class& cls = Class::Handle(helper_->zone_);
  String& name = String::Handle(helper_->zone_);
  TypeArguments& type_args = TypeArguments::Handle(helper_->zone_);
  Class* symbol_class = nullptr;
  Field* symbol_name_field = nullptr;
  const String* simpleInstanceOf = nullptr;
  const intptr_t obj_count = pool.Length();
  for (intptr_t i = 0; i < obj_count; ++i) {
    const intptr_t tag = helper_->ReadTag();
    switch (tag) {
      case ConstantPoolTag::kInvalid:
        UNREACHABLE();
      case ConstantPoolTag::kNull:
        obj = Object::null();
        break;
      case ConstantPoolTag::kString:
        obj = ReadString();
        ASSERT(obj.IsString() && obj.IsCanonical());
        break;
      case ConstantPoolTag::kInt: {
        uint32_t low_bits = helper_->ReadUInt32();
        int64_t value = helper_->ReadUInt32();
        value = (value << 32) | low_bits;
        obj = Integer::New(value, Heap::kOld);
        obj = H.Canonicalize(Integer::Cast(obj));
      } break;
      case ConstantPoolTag::kDouble: {
        uint32_t low_bits = helper_->ReadUInt32();
        uint64_t bits = helper_->ReadUInt32();
        bits = (bits << 32) | low_bits;
        double value = bit_cast<double, uint64_t>(bits);
        obj = Double::New(value, Heap::kOld);
        obj = H.Canonicalize(Double::Cast(obj));
      } break;
      case ConstantPoolTag::kBool:
        if (helper_->ReadByte() == 1) {
          obj = Bool::True().raw();
        } else {
          obj = Bool::False().raw();
        }
        break;
      case ConstantPoolTag::kArgDesc: {
        intptr_t num_arguments = helper_->ReadUInt();
        intptr_t num_type_args = helper_->ReadUInt();
        intptr_t num_arg_names = helper_->ReadListLength();
        if (num_arg_names == 0) {
          obj = ArgumentsDescriptor::New(num_type_args, num_arguments);
        } else {
          array = Array::New(num_arg_names);
          for (intptr_t j = 0; j < num_arg_names; j++) {
            name = ReadString();
            array.SetAt(j, name);
          }
          obj = ArgumentsDescriptor::New(num_type_args, num_arguments, array);
        }
      } break;
      case ConstantPoolTag::kICData: {
        intptr_t flags = helper_->ReadByte();
        InvocationKind kind =
            static_cast<InvocationKind>(flags & kInvocationKindMask);
        bool isDynamic = (flags & kFlagDynamic) != 0;
        name ^= ReadObject();
        ASSERT(name.IsSymbol());
        intptr_t arg_desc_index = helper_->ReadUInt();
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
                        H.thread()->compiler_state().GetNextDeoptId(),
                        checked_argument_count, ICData::RebindRule::kInstance);
      } break;
      case ConstantPoolTag::kStaticICData: {
        elem = ReadObject();
        ASSERT(elem.IsFunction());
        name = Function::Cast(elem).name();
        const int num_args_checked =
            MethodRecognizer::NumArgsCheckedForStaticCall(Function::Cast(elem));
        intptr_t arg_desc_index = helper_->ReadUInt();
        ASSERT(arg_desc_index < i);
        array ^= pool.ObjectAt(arg_desc_index);
        obj = ICData::New(function, name,
                          array,  // Arguments descriptor.
                          H.thread()->compiler_state().GetNextDeoptId(),
                          num_args_checked, ICData::RebindRule::kStatic);
        ICData::Cast(obj).AddTarget(Function::Cast(elem));
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
      case ConstantPoolTag::kTearOff:
        obj = ReadObject();
        ASSERT(obj.IsFunction());
        obj = Function::Cast(obj).ImplicitClosureFunction();
        ASSERT(obj.IsFunction());
        obj = Function::Cast(obj).ImplicitStaticClosure();
        ASSERT(obj.IsInstance());
        obj = H.Canonicalize(Instance::Cast(obj));
        break;
      case ConstantPoolTag::kType:
        obj = ReadObject();
        ASSERT(obj.IsAbstractType());
        break;
      case ConstantPoolTag::kTypeArguments:
        cls = Class::null();
        obj = ReadTypeArguments(cls);
        ASSERT(obj.IsNull() || obj.IsTypeArguments());
        break;
      case ConstantPoolTag::kList: {
        obj = ReadObject();
        ASSERT(obj.IsAbstractType());
        const intptr_t length = helper_->ReadListLength();
        array = Array::New(length, AbstractType::Cast(obj));
        for (intptr_t j = 0; j < length; j++) {
          intptr_t elem_index = helper_->ReadUInt();
          ASSERT(elem_index < i);
          elem = pool.ObjectAt(elem_index);
          array.SetAt(j, elem);
        }
        array.MakeImmutable();
        obj = H.Canonicalize(Array::Cast(array));
        ASSERT(!obj.IsNull());
      } break;
      case ConstantPoolTag::kInstance: {
        cls ^= ReadObject();
        obj = Instance::New(cls, Heap::kOld);
        intptr_t type_args_index = helper_->ReadUInt();
        ASSERT(type_args_index < i);
        type_args ^= pool.ObjectAt(type_args_index);
        if (!type_args.IsNull()) {
          Instance::Cast(obj).SetTypeArguments(type_args);
        }
        intptr_t num_fields = helper_->ReadUInt();
        for (intptr_t j = 0; j < num_fields; j++) {
          field ^= ReadObject();
          intptr_t elem_index = helper_->ReadUInt();
          ASSERT(elem_index < i);
          elem = pool.ObjectAt(elem_index);
          Instance::Cast(obj).SetField(field, elem);
        }
        obj = H.Canonicalize(Instance::Cast(obj));
      } break;
      case ConstantPoolTag::kTypeArgumentsForInstanceAllocation: {
        cls ^= ReadObject();
        obj = ReadTypeArguments(cls);
        ASSERT(obj.IsNull() || obj.IsTypeArguments());
      } break;
      case ConstantPoolTag::kClosureFunction: {
        intptr_t closure_index = helper_->ReadUInt();
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
      case ConstantPoolTag::kPartialTearOffInstantiation: {
        intptr_t tearoff_index = helper_->ReadUInt();
        ASSERT(tearoff_index < i);
        const Closure& old_closure = Closure::CheckedHandle(
            helper_->zone_, pool.ObjectAt(tearoff_index));

        intptr_t type_args_index = helper_->ReadUInt();
        ASSERT(type_args_index < i);
        type_args ^= pool.ObjectAt(type_args_index);

        obj = Closure::New(
            TypeArguments::Handle(helper_->zone_,
                                  old_closure.instantiator_type_arguments()),
            TypeArguments::Handle(helper_->zone_,
                                  old_closure.function_type_arguments()),
            type_args, Function::Handle(helper_->zone_, old_closure.function()),
            Context::Handle(helper_->zone_, old_closure.context()), Heap::kOld);
        obj = H.Canonicalize(Instance::Cast(obj));
      } break;
      case ConstantPoolTag::kEmptyTypeArguments:
        obj = Object::empty_type_arguments().raw();
        break;
      case ConstantPoolTag::kSymbol: {
        name ^= ReadObject();
        ASSERT(name.IsSymbol());
        if (symbol_class == nullptr) {
          elem = Library::InternalLibrary();
          ASSERT(!elem.IsNull());
          symbol_class = &Class::Handle(
              helper_->zone_,
              Library::Cast(elem).LookupClass(Symbols::Symbol()));
          ASSERT(!symbol_class->IsNull());
          symbol_name_field = &Field::Handle(
              helper_->zone_,
              symbol_class->LookupInstanceFieldAllowPrivate(Symbols::_name()));
          ASSERT(!symbol_name_field->IsNull());
        }
        obj = Instance::New(*symbol_class, Heap::kOld);
        Instance::Cast(obj).SetField(*symbol_name_field, name);
        obj = H.Canonicalize(Instance::Cast(obj));
      } break;
      case ConstantPoolTag::kInterfaceCall: {
        helper_->ReadByte();  // TODO(regis): Remove, unneeded.
        name ^= ReadObject();
        ASSERT(name.IsSymbol());
        intptr_t arg_desc_index = helper_->ReadUInt();
        ASSERT(arg_desc_index < i);
        array ^= pool.ObjectAt(arg_desc_index);
        // InterfaceCall constant occupies 2 entries.
        // The first entry is used for selector name.
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable);
        pool.SetObjectAt(i, name);
        ++i;
        ASSERT(i < obj_count);
        // The second entry is used for arguments descriptor.
        obj = array.raw();
      } break;
      default:
        UNREACHABLE();
    }
    pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                   ObjectPool::Patchability::kNotPatchable);
    pool.SetObjectAt(i, obj);
  }
}

RawBytecode* BytecodeMetadataHelper::ReadBytecode(const ObjectPool& pool) {
  TIMELINE_DURATION(Thread::Current(), Compiler,
                    "BytecodeMetadataHelper::ReadBytecode");
  intptr_t size = helper_->ReadUInt();
  intptr_t offset = Utils::RoundUp(helper_->reader_.offset(), sizeof(KBCInstr));
  const uint8_t* data = helper_->reader_.BufferAt(offset);
  ASSERT(Utils::IsAligned(data, sizeof(KBCInstr)));
  helper_->reader_.set_offset(offset + size);

  const ExternalTypedData& instructions = ExternalTypedData::Handle(
      helper_->zone_,
      ExternalTypedData::New(kExternalTypedDataInt8ArrayCid,
                             const_cast<uint8_t*>(data), size, Heap::kOld));

  // Create and return bytecode object.
  return Bytecode::New(instructions, pool);
}

void BytecodeMetadataHelper::ReadExceptionsTable(const Bytecode& bytecode,
                                                 bool has_exceptions_table) {
  TIMELINE_DURATION(Thread::Current(), Compiler,
                    "BytecodeMetadataHelper::ReadExceptionsTable");

  const intptr_t try_block_count =
      has_exceptions_table ? helper_->reader_.ReadListLength() : 0;
  if (try_block_count > 0) {
    const ObjectPool& pool =
        ObjectPool::Handle(helper_->zone_, bytecode.object_pool());
    AbstractType& handler_type = AbstractType::Handle(helper_->zone_);
    Array& handler_types = Array::ZoneHandle(helper_->zone_);
    DescriptorList* pc_descriptors_list =
        new (helper_->zone_) DescriptorList(64);
    ExceptionHandlerList* exception_handlers_list =
        new (helper_->zone_) ExceptionHandlerList();

    // Encoding of ExceptionsTable is described in
    // pkg/vm/lib/bytecode/exceptions.dart.
    for (intptr_t try_index = 0; try_index < try_block_count; try_index++) {
      intptr_t outer_try_index_plus1 = helper_->reader_.ReadUInt();
      intptr_t outer_try_index = outer_try_index_plus1 - 1;
      // PcDescriptors are expressed in terms of return addresses.
      intptr_t start_pc = KernelBytecode::BytecodePcToOffset(
          helper_->reader_.ReadUInt(), /* is_return_address = */ true);
      intptr_t end_pc = KernelBytecode::BytecodePcToOffset(
          helper_->reader_.ReadUInt(), /* is_return_address = */ true);
      intptr_t handler_pc = KernelBytecode::BytecodePcToOffset(
          helper_->reader_.ReadUInt(), /* is_return_address = */ false);
      uint8_t flags = helper_->reader_.ReadByte();
      const uint8_t kFlagNeedsStackTrace = 1 << 0;
      const uint8_t kFlagIsSynthetic = 1 << 1;
      const bool needs_stacktrace = (flags & kFlagNeedsStackTrace) != 0;
      const bool is_generated = (flags & kFlagIsSynthetic) != 0;
      intptr_t type_count = helper_->reader_.ReadListLength();
      ASSERT(type_count > 0);
      handler_types = Array::New(type_count, Heap::kOld);
      for (intptr_t i = 0; i < type_count; i++) {
        intptr_t type_index = helper_->reader_.ReadUInt();
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
        helper_->zone_,
        pc_descriptors_list->FinalizePcDescriptors(bytecode.PayloadStart()));
    bytecode.set_pc_descriptors(descriptors);
    const ExceptionHandlers& handlers = ExceptionHandlers::Handle(
        helper_->zone_, exception_handlers_list->FinalizeExceptionHandlers(
                            bytecode.PayloadStart()));
    bytecode.set_exception_handlers(handlers);
  } else {
    bytecode.set_pc_descriptors(Object::empty_descriptors());
    bytecode.set_exception_handlers(Object::empty_exception_handlers());
  }
}

void BytecodeMetadataHelper::ReadSourcePositions(const Bytecode& bytecode,
                                                 bool has_source_positions) {
  if (!has_source_positions) {
    return;
  }

  intptr_t length = helper_->reader_.ReadUInt();
  bytecode.set_source_positions_binary_offset(helper_->reader_.offset());
  helper_->SkipBytes(length);
}

RawTypedData* BytecodeMetadataHelper::NativeEntry(const Function& function,
                                                  const String& external_name) {
  Zone* zone = helper_->zone_;
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
    case MethodRecognizer::kTypedDataLength:
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
      const Class& cls = Class::Handle(zone, function.Owner());
      const Library& library = Library::Handle(zone, cls.library());
      Dart_NativeEntryResolver resolver = library.native_entry_resolver();
      const bool is_bootstrap_native = Bootstrap::IsBootstrapResolver(resolver);
      const int num_params =
          NativeArguments::ParameterCountForResolution(function);
      bool is_auto_scope = true;
      native_function = NativeEntry::ResolveNative(library, external_name,
                                                   num_params, &is_auto_scope);
      ASSERT(native_function != NULL);  // TODO(regis): Should we throw instead?
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

RawArray* BytecodeMetadataHelper::ReadBytecodeComponent() {
  const intptr_t md_offset = GetComponentMetadataPayloadOffset();
  if (md_offset < 0) {
    return Array::null();
  }

  ASSERT(Thread::Current()->IsMutatorThread());

  AlternativeReadingScope alt(&helper_->reader_, &H.metadata_payloads(),
                              md_offset);

  const intptr_t version = helper_->reader_.ReadUInt();
  if ((version < KernelBytecode::kMinSupportedBytecodeFormatVersion) ||
      (version > KernelBytecode::kMaxSupportedBytecodeFormatVersion)) {
    FATAL3("Unsupported Dart bytecode format version %" Pd
           ". "
           "This version of Dart VM supports bytecode format versions from %" Pd
           " to %" Pd ".",
           version, KernelBytecode::kMinSupportedBytecodeFormatVersion,
           KernelBytecode::kMaxSupportedBytecodeFormatVersion);
  }

  const intptr_t strings_size = helper_->reader_.ReadUInt();
  helper_->reader_.ReadUInt();  // Objects table size.

  // Read header of strings table.
  const intptr_t strings_header_offset = helper_->reader_.offset();
  const intptr_t num_one_byte_strings = helper_->reader_.ReadUInt32();
  const intptr_t num_two_byte_strings = helper_->reader_.ReadUInt32();
  const intptr_t strings_contents_offset =
      helper_->reader_.offset() +
      (num_one_byte_strings + num_two_byte_strings) * 4;

  // Read header of objects table.
  helper_->reader_.set_offset(strings_header_offset + strings_size);
  const intptr_t num_objects = helper_->reader_.ReadUInt();
  const intptr_t objects_size = helper_->reader_.ReadUInt();

  // Skip over contents of objects.
  const intptr_t objects_contents_offset = helper_->reader_.offset();
  helper_->reader_.set_offset(objects_contents_offset + objects_size);

  const Array& bytecode_component_array = Array::Handle(
      Z, BytecodeComponentData::New(
             Z, version, num_objects, strings_header_offset,
             strings_contents_offset, objects_contents_offset, Heap::kOld));
  BytecodeComponentData bytecode_component(bytecode_component_array);

  // Read object offsets.
  Smi& offs = Smi::Handle(helper_->zone_);
  for (intptr_t i = 0; i < num_objects; ++i) {
    offs = Smi::New(helper_->reader_.ReadUInt());
    bytecode_component.SetObject(i, offs);
  }

  H.SetBytecodeComponent(bytecode_component_array);

  return bytecode_component_array.raw();
}

// TODO(alexmarkov): create a helper class with cached handles to avoid handle
// allocations.
RawObject* BytecodeMetadataHelper::ReadObject() {
  uint32_t header = helper_->reader_.ReadUInt();
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
    AlternativeReadingScope alt(&helper_->reader_, &H.metadata_payloads(),
                                offset);
    header = helper_->reader_.ReadUInt();

    obj = ReadObjectContents(header);
    ASSERT(obj->IsHeapObject());
    {
      Thread* thread = H.thread();
      REUSABLE_OBJECT_HANDLESCOPE(thread);
      Object& obj_handle = thread->ObjectHandle();
      obj_handle = obj;
      bytecode_component_->SetObject(index, obj_handle);
    }
    return obj;
  }

  return ReadObjectContents(header);
}

RawObject* BytecodeMetadataHelper::ReadObjectContents(uint32_t header) {
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

  const intptr_t kind = (header >> kKindShift) & kKindMask;
  const intptr_t flags = header & kFlagsMask;

  switch (kind) {
    case kInvalid:
      UNREACHABLE();
      break;
    case kLibrary: {
      const String& uri = String::Handle(Z, ReadString());
      RawLibrary* library = Library::LookupLibrary(H.thread(), uri);
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
          GrowableHandlePtrArray<const String> pieces(Z, 3);
          pieces.Add(String::Handle(Z, cls.Name()));
          pieces.Add(Symbols::Dot());
          pieces.Add(name);
          name = Symbols::FromConcatAll(H.thread(), pieces);
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
      const intptr_t closure_index = helper_->reader_.ReadUInt();
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
      const intptr_t index_in_parent = helper_->reader_.ReadUInt();
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
                                                : Function::Handle(Z),
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
  }

  return Object::null();
}

RawString* BytecodeMetadataHelper::ReadString(bool is_canonical) {
  const int kFlagTwoByteString = 1;
  const int kHeaderFields = 2;
  const int kUInt32Size = 4;

  uint32_t ref = helper_->reader_.ReadUInt();
  const bool isOneByteString = (ref & kFlagTwoByteString) == 0;
  intptr_t index = ref >> 1;

  if (!isOneByteString) {
    const uint32_t num_one_byte_strings = helper_->reader_.ReadUInt32At(
        bytecode_component_->GetStringsHeaderOffset());
    index += num_one_byte_strings;
  }

  AlternativeReadingScope alt(&helper_->reader_, &H.metadata_payloads(),
                              bytecode_component_->GetStringsHeaderOffset() +
                                  (kHeaderFields + index - 1) * kUInt32Size);
  intptr_t start_offs = helper_->ReadUInt32();
  intptr_t end_offs = helper_->ReadUInt32();
  if (index == 0) {
    // For the 0-th string we read a header field instead of end offset of
    // the previous string.
    start_offs = 0;
  }

  // Bytecode strings reside in ExternalTypedData which is not movable by GC,
  // so it is OK to take a direct pointer to string characters even if
  // symbol allocation triggers GC.
  const uint8_t* data = helper_->reader_.BufferAt(
      bytecode_component_->GetStringsContentsOffset() + start_offs);

  if (is_canonical) {
    if (isOneByteString) {
      return Symbols::FromLatin1(H.thread(), data, end_offs - start_offs);
    } else {
      return Symbols::FromUTF16(H.thread(),
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

RawTypeArguments* BytecodeMetadataHelper::ReadTypeArguments(
    const Class& instantiator) {
  const intptr_t length = helper_->reader_.ReadUInt();
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
  type ^= ClassFinalizer::FinalizeType(*active_class_->klass, type);
  return type.arguments();
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

  return data.raw();
}

RawError* BytecodeReader::ReadFunctionBytecode(Thread* thread,
                                               const Function& function) {
  ASSERT(!FLAG_precompiled_mode);
  ASSERT(!function.HasBytecode());
  ASSERT(thread->sticky_error() == Error::null());
  ASSERT(Thread::Current()->IsMutatorThread());

  VMTagScope tagScope(thread, VMTag::kLoadBytecodeTagId);

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    StackZone stack_zone(thread);
    Zone* const zone = stack_zone.GetZone();
    HANDLESCOPE(thread);
    CompilerState compiler_state(thread);

    const Script& script = Script::Handle(zone, function.script());
    TranslationHelper translation_helper(thread);
    translation_helper.InitFromScript(script);

    KernelReaderHelper reader_helper(
        zone, &translation_helper, script,
        ExternalTypedData::Handle(zone, function.KernelData()),
        function.KernelDataProgramOffset());
    ActiveClass active_class;
    TypeTranslator type_translator(&reader_helper, &active_class,
                                   /* finalize= */ true);

    BytecodeMetadataHelper bytecode_metadata_helper(
        &reader_helper, &type_translator, &active_class);

    // Setup a [ActiveClassScope] and a [ActiveMemberScope] which will be used
    // e.g. for type translation.
    const Class& klass = Class::Handle(zone, function.Owner());
    Function& outermost_function =
        Function::Handle(zone, function.GetOutermostFunction());

    ActiveClassScope active_class_scope(&active_class, &klass);
    ActiveMemberScope active_member(&active_class, &outermost_function);
    ActiveTypeParametersScope active_type_params(&active_class, function, zone);

    bytecode_metadata_helper.ReadMetadata(function);

    return Error::null();
  } else {
    return thread->StealStickyError();
  }
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
