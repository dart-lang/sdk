// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bytecode_reader.h"

#include "vm/globals.h"
#if defined(DART_DYNAMIC_MODULES)

#include "vm/bit_vector.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/class_id.h"
#include "vm/closure_functions_cache.h"
#include "vm/code_descriptors.h"
#include "vm/compiler/api/deopt_id.h"
#include "vm/compiler/assembler/disassembler_kbc.h"
#include "vm/constants_kbc.h"
#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/hash.h"
#include "vm/hash_table.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/reusable_handles.h"
#include "vm/stack_frame_kbc.h"
#include "vm/symbols.h"
#include "vm/timeline.h"

#define Z (zone_)
#define IG (thread_->isolate_group())

namespace dart {

DEFINE_FLAG(bool, dump_kernel_bytecode, false, "Dump kernel bytecode");

namespace bytecode {

class BytecodeOffsetsMapTraits {
 public:
  static const char* Name() { return "BytecodeOffsetsMapTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    return (a.ptr() == b.ptr());
  }

  static uword Hash(const Object& key) {
    if (key.IsClass()) {
      return Class::Cast(key).id();
    } else if (key.IsFunction()) {
      return Function::Cast(key).Hash();
    } else if (key.IsField()) {
      return Field::Cast(key).Hash();
    } else {
      UNREACHABLE();
    }
  }
};
using BytecodeOffsetsMap = UnorderedHashMap<BytecodeOffsetsMapTraits>;

BytecodeLoader::BytecodeLoader(Thread* thread, const TypedDataBase& binary)
    : thread_(thread),
      binary_(binary),
      bytecode_component_array_(Array::Handle(thread->zone())),
      bytecode_offsets_map_(
          Array::Handle(thread->zone(),
                        HashTables::New<BytecodeOffsetsMap>(16))) {
  ASSERT(thread_ == Thread::Current());
  ASSERT(thread_->bytecode_loader() == nullptr);
  thread_->set_bytecode_loader(this);

  ASSERT(!binary_.IsNull());
  ASSERT(binary_.IsExternalOrExternalView());
}

BytecodeLoader::~BytecodeLoader() {
  ASSERT(thread_->bytecode_loader() == this);
  thread_->set_bytecode_loader(nullptr);
}

FunctionPtr BytecodeLoader::LoadBytecode() {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());

  BytecodeReaderHelper component_reader(thread_, binary_);
  bytecode_component_array_ = component_reader.ReadBytecodeComponent();

  BytecodeComponentData bytecode_component(bytecode_component_array_);
  BytecodeReaderHelper bytecode_reader(thread_, &bytecode_component);
  AlternativeReadingScope alt(&bytecode_reader.reader(),
                              bytecode_component.GetLibraryIndexOffset());
  bytecode_reader.ReadLibraryDeclarations(bytecode_component.GetNumLibraries());

  if (bytecode_component.GetMainOffset() == 0) {
    return Function::null();
  }

  AlternativeReadingScope alt2(&bytecode_reader.reader(),
                               bytecode_component.GetMainOffset());
  return Function::RawCast(bytecode_reader.ReadObject());
}

void BytecodeLoader::SetOffset(const Object& obj, intptr_t offset) {
  BytecodeOffsetsMap map(bytecode_offsets_map_.ptr());
  map.UpdateOrInsert(obj, Smi::Handle(thread_->zone(), Smi::New(offset)));
  bytecode_offsets_map_ = map.Release().ptr();
}

intptr_t BytecodeLoader::GetOffset(const Object& obj) {
  BytecodeOffsetsMap map(bytecode_offsets_map_.ptr());
  const auto value = map.GetOrNull(obj);
  ASSERT(value != Object::null());
  const intptr_t offset = Smi::Value(Smi::RawCast(value));
  ASSERT(map.Release().ptr() == bytecode_offsets_map_.ptr());
  return offset;
}

BytecodeReaderHelper::BytecodeReaderHelper(Thread* thread,
                                           const TypedDataBase& typed_data)
    : reader_(typed_data),
      thread_(thread),
      zone_(thread->zone()),
      bytecode_component_(nullptr),
      scoped_function_(Function::Handle(thread->zone())),
      scoped_function_name_(String::Handle(thread->zone())),
      scoped_function_class_(Class::Handle(thread->zone())) {}

BytecodeReaderHelper::BytecodeReaderHelper(
    Thread* thread,
    BytecodeComponentData* bytecode_component)
    : reader_(TypedDataBase::Handle(thread->zone(),
                                    bytecode_component->GetTypedData())),
      thread_(thread),
      zone_(thread->zone()),
      bytecode_component_(bytecode_component),
      scoped_function_(Function::Handle(thread->zone())),
      scoped_function_name_(String::Handle(thread->zone())),
      scoped_function_class_(Class::Handle(thread->zone())) {}

void BytecodeReaderHelper::ReadCode(const Function& function,
                                    intptr_t code_offset) {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  ASSERT(!function.IsImplicitGetterFunction() &&
         !function.IsImplicitSetterFunction());
  if (code_offset == 0) {
    FATAL("Function %s (kind %s) doesn't have bytecode",
          function.ToFullyQualifiedCString(),
          Function::KindToCString(function.kind()));
  }

  AlternativeReadingScope alt(&reader_, code_offset);
  const auto& signature = FunctionType::Handle(Z, function.signature());
  FunctionTypeScope function_type_scope(this, signature);

  const intptr_t flags = reader_.ReadUInt();
  const bool has_exceptions_table =
      (flags & Code::kHasExceptionsTableFlag) != 0;
  const bool has_source_positions =
      (flags & Code::kHasSourcePositionsFlag) != 0;
  const bool has_local_variables = (flags & Code::kHasLocalVariablesFlag) != 0;
  const bool has_nullable_fields = (flags & Code::kHasNullableFieldsFlag) != 0;
  const bool has_closures = (flags & Code::kHasClosuresFlag) != 0;
  const bool has_parameter_flags = (flags & Code::kHasParameterFlagsFlag) != 0;
  const bool has_forwarding_stub_target =
      (flags & Code::kHasForwardingStubTargetFlag) != 0;
  const bool has_default_function_type_args =
      (flags & Code::kHasDefaultFunctionTypeArgsFlag) != 0;

  if (has_parameter_flags) {
    intptr_t num_flags = reader_.ReadUInt();
    for (intptr_t i = 0; i < num_flags; ++i) {
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
  ReadConstantPool(function, pool, 0);

  // Read bytecode and attach to function.
  const Bytecode& bytecode = Bytecode::Handle(Z, ReadBytecode(pool));
  bytecode.set_code_offset(code_offset);
  function.AttachBytecode(bytecode);

  ReadExceptionsTable(function, bytecode, has_exceptions_table);

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
    if (IG->use_field_guards()) {
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

      ReadExceptionsTable(closure, closure_bytecode, has_exceptions_table);

      ReadSourcePositions(closure_bytecode, has_source_positions);

      ReadLocalVariables(closure_bytecode, has_local_variables);

      if (FLAG_dump_kernel_bytecode) {
        KernelBytecodeDisassembler::Disassemble(closure);
      }
    }
  }
}

void BytecodeReaderHelper::ReadClosureDeclaration(const Function& function,
                                                  intptr_t closureIndex) {
  // Closure flags, must be in sync with ClosureDeclaration constants in
  // pkg/dart2bytecode/lib/declarations.dart.
  const int kHasOptionalPositionalParamsFlag = 1 << 0;
  const int kHasOptionalNamedParamsFlag = 1 << 1;
  const int kHasTypeParamsFlag = 1 << 2;
  const int kHasSourcePositionsFlag = 1 << 3;
  const int kIsAsyncFlag = 1 << 4;
  const int kIsAsyncStarFlag = 1 << 5;
  const int kIsSyncStarFlag = 1 << 6;
  const int kIsDebuggableFlag = 1 << 7;
  const int kHasParameterFlagsFlag = 1 << 8;

  const intptr_t flags = reader_.ReadUInt();

  Object& parent = Object::Handle(Z, ReadObject());
  if (!parent.IsFunction()) {
    ASSERT(parent.IsField());
    ASSERT(function.kind() == UntaggedFunction::kFieldInitializer);
    // Closure in a static field initializer, so use current function as parent.
    parent = function.ptr();
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

  NOT_IN_PRECOMPILED(closure.set_end_token_pos(end_position));

  if ((flags & kIsSyncStarFlag) != 0) {
    closure.set_modifier(UntaggedFunction::kSyncGen);
    closure.set_is_inlinable(false);
  } else if ((flags & kIsAsyncFlag) != 0) {
    closure.set_modifier(UntaggedFunction::kAsync);
    closure.set_is_inlinable(false);
  } else if ((flags & kIsAsyncStarFlag) != 0) {
    closure.set_modifier(UntaggedFunction::kAsyncGen);
    closure.set_is_inlinable(false);
  }
  closure.set_is_debuggable((flags & kIsDebuggableFlag) != 0);

  closures_->SetAt(closureIndex, closure);

  auto& signature = FunctionType::Handle(Z, closure.signature());
  signature = ReadFunctionSignature(
      signature, (flags & kHasOptionalPositionalParamsFlag) != 0,
      (flags & kHasOptionalNamedParamsFlag) != 0,
      (flags & kHasTypeParamsFlag) != 0,
      /* has_positional_param_names = */ true,
      (flags & kHasParameterFlagsFlag) != 0);

  closure.SetSignature(signature);
}

FunctionTypePtr BytecodeReaderHelper::ReadFunctionSignature(
    const FunctionType& signature,
    bool has_optional_positional_params,
    bool has_optional_named_params,
    bool has_type_params,
    bool has_positional_param_names,
    bool has_parameter_flags) {
  FunctionTypeScope function_type_scope(this, signature);

  if (has_type_params) {
    ReadTypeParametersDeclaration(Class::Handle(Z), signature);
  }

  const intptr_t kImplicitClosureParam = 1;
  const intptr_t num_params = kImplicitClosureParam + reader_.ReadUInt();

  intptr_t num_required_params = num_params;
  if (has_optional_positional_params || has_optional_named_params) {
    num_required_params = kImplicitClosureParam + reader_.ReadUInt();
  }

  signature.set_num_implicit_parameters(kImplicitClosureParam);
  signature.set_num_fixed_parameters(num_required_params);
  signature.SetNumOptionalParameters(num_params - num_required_params,
                                     !has_optional_named_params);
  signature.set_parameter_types(
      Array::Handle(Z, Array::New(num_params, Heap::kOld)));
  signature.CreateNameArrayIncludingFlags(Heap::kOld);

  intptr_t i = 0;
  signature.SetParameterTypeAt(i, AbstractType::dynamic_type());
  ++i;

  AbstractType& type = AbstractType::Handle(Z);
  String& name = String::Handle(Z);
  for (; i < num_params; ++i) {
    if (has_positional_param_names ||
        (has_optional_named_params && (i >= num_required_params))) {
      name ^= ReadObject();
      if (has_optional_named_params && (i >= num_required_params)) {
        signature.SetParameterNameAt(i, name);
      }
    }
    type ^= ReadObject();
    signature.SetParameterTypeAt(i, type);
  }
  if (has_parameter_flags) {
    intptr_t num_flags = reader_.ReadUInt();
    for (intptr_t i = 0; i < num_flags; ++i) {
      intptr_t flag = reader_.ReadUInt();
      if ((flag & Parameter::kIsRequiredFlag) != 0) {
        RELEASE_ASSERT(kImplicitClosureParam + i >= num_required_params);
        signature.SetIsRequiredAt(kImplicitClosureParam + i);
      }
    }
  }

  type ^= ReadObject();
  signature.set_result_type(type);

  // Finalize function type.
  return FunctionType::RawCast(
      ClassFinalizer::FinalizeType(signature, ClassFinalizer::kCanonicalize));
}

void BytecodeReaderHelper::ReadTypeParametersDeclaration(
    const Class& parameterized_class,
    const FunctionType& parameterized_signature) {
  ASSERT(parameterized_class.IsNull() != parameterized_signature.IsNull());

  const intptr_t num_type_params = reader_.ReadUInt();
  ASSERT(num_type_params > 0);

  // First setup the type parameters, so if any of the following code uses it
  // (in a recursive way) we're fine.
  //
  // Step a) Create TypeParameters object (without bounds and defaults).
  const TypeParameters& type_parameters =
      TypeParameters::Handle(Z, TypeParameters::New(num_type_params));

  if (!parameterized_class.IsNull()) {
    ASSERT(parameterized_class.type_parameters() == TypeParameters::null());
    parameterized_class.set_type_parameters(type_parameters);
  } else {
    ASSERT(parameterized_signature.type_parameters() == TypeParameters::null());
    parameterized_signature.SetTypeParameters(type_parameters);
  }

  String& name = String::Handle(Z);
  AbstractType& type = AbstractType::Handle(Z);
  for (intptr_t i = 0; i < num_type_params; ++i) {
    name ^= ReadObject();
    ASSERT(name.IsSymbol());
    type_parameters.SetNameAt(i, name);
    // Set bound temporarily to dynamic in order to
    // allow type finalization of type parameter types.
    type_parameters.SetBoundAt(i, Object::dynamic_type());
  }

  // Step b) Fill in the bounds and defaults of all [TypeParameter]s.
  for (intptr_t i = 0; i < num_type_params; ++i) {
    type ^= ReadObject();
    type_parameters.SetBoundAt(i, type);
    type ^= ReadObject();
    type_parameters.SetDefaultAt(i, type);
  }
}

intptr_t BytecodeReaderHelper::ReadConstantPool(const Function& function,
                                                const ObjectPool& pool,
                                                intptr_t start_index) {
  // These enums and the code below reading the constant pool from kernel must
  // be kept in sync with pkg/dart2bytecode/lib/constant_pool.dart.
  enum ConstantPoolTag {
    kInvalid,
    kStaticField,
    kInstanceField,
    kClass,
    kTypeArgumentsField,
    kType,
    kClosureFunction,
    kEndClosureFunctionScope,
    kSubtypeTestCache,
    kEmptyTypeArguments,
    kObjectRef,
    kDirectCall,
    kInterfaceCall,
    kInstantiatedInterfaceCall,
    kDynamicCall,
  };

  Object& obj = Object::Handle(Z);
  Object& elem = Object::Handle(Z);
  Field& field = Field::Handle(Z);
  Class& cls = Class::Handle(Z);
  String& name = String::Handle(Z);
  const intptr_t obj_count = pool.Length();
  for (intptr_t i = start_index; i < obj_count; ++i) {
    const intptr_t tag = reader_.ReadByte();
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
        obj = Smi::New(field.HostOffset() / kCompressedWordSize);
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable,
                       ObjectPool::SnapshotBehavior::kNotSnapshotable);
        pool.SetObjectAt(i, obj);
        ++i;
        ASSERT(i < obj_count);
        // The second entry is used for field object.
        obj = field.ptr();
        break;
      case ConstantPoolTag::kClass:
        obj = ReadObject();
        ASSERT(obj.IsClass());
        break;
      case ConstantPoolTag::kTypeArgumentsField:
        cls ^= ReadObject();
        obj = Smi::New(cls.host_type_arguments_field_offset() /
                       kCompressedWordSize);
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
                       ObjectPool::Patchability::kNotPatchable,
                       ObjectPool::SnapshotBehavior::kNotSnapshotable);
        pool.SetObjectAt(i, obj);

        const auto& signature =
            FunctionType::Handle(Z, Function::Cast(obj).signature());
        FunctionTypeScope function_type_scope(this, signature);

        // Read constant pool until corresponding EndClosureFunctionScope.
        i = ReadConstantPool(function, pool, i + 1);

        // Proceed with the rest of entries.
        continue;
      }
      case ConstantPoolTag::kEndClosureFunctionScope: {
        // EndClosureFunctionScope entry is not used and set to null.
        obj = Object::null();
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable,
                       ObjectPool::SnapshotBehavior::kNotSnapshotable);
        pool.SetObjectAt(i, obj);
        return i;
      }
      case ConstantPoolTag::kSubtypeTestCache: {
        obj = SubtypeTestCache::New(SubtypeTestCache::kMaxInputs);
      } break;
      case ConstantPoolTag::kEmptyTypeArguments:
        obj = Object::empty_type_arguments().ptr();
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
                       ObjectPool::Patchability::kNotPatchable,
                       ObjectPool::SnapshotBehavior::kNotSnapshotable);
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
                       ObjectPool::Patchability::kNotPatchable,
                       ObjectPool::SnapshotBehavior::kNotSnapshotable);
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
                       ObjectPool::Patchability::kNotPatchable,
                       ObjectPool::SnapshotBehavior::kNotSnapshotable);
        pool.SetObjectAt(i, elem);
        ++i;
        ASSERT(i < obj_count);
        // 2) Arguments descriptor.
        obj = ReadObject();
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable,
                       ObjectPool::SnapshotBehavior::kNotSnapshotable);
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
            (name.ptr() != Symbols::EqualOperator().ptr())) {
          name = Function::CreateDynamicInvocationForwarderName(name);
        }
        // DynamicCall constant occupies 2 entries: selector and arguments
        // descriptor.
        pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                       ObjectPool::Patchability::kNotPatchable,
                       ObjectPool::SnapshotBehavior::kNotSnapshotable);
        pool.SetObjectAt(i, name);
        ++i;
        ASSERT(i < obj_count);
        // The second entry is used for arguments descriptor.
        obj = ReadObject();
      } break;
      default:
        UNREACHABLE();
    }
    pool.SetTypeAt(i, ObjectPool::EntryType::kTaggedObject,
                   ObjectPool::Patchability::kNotPatchable,
                   ObjectPool::SnapshotBehavior::kNotSnapshotable);
    pool.SetObjectAt(i, obj);
  }

  return obj_count - 1;
}

BytecodePtr BytecodeReaderHelper::ReadBytecode(const ObjectPool& pool) {
  const intptr_t size = reader_.ReadUInt();
  const intptr_t offset = reader_.offset();

  const uint8_t* data = reader_.BufferAt(offset);
  reader_.set_offset(offset + size);

  // Create and return bytecode object.
  return Bytecode::New(reinterpret_cast<uword>(data), size, offset,
                       *(reader_.typed_data()), pool);
}

void BytecodeReaderHelper::ReadExceptionsTable(const Function& function,
                                               const Bytecode& bytecode,
                                               bool has_exceptions_table) {
  const intptr_t try_block_count =
      has_exceptions_table ? reader_.ReadListLength() : 0;
  if (try_block_count > 0) {
    const ObjectPool& pool = ObjectPool::Handle(Z, bytecode.object_pool());
    AbstractType& handler_type = AbstractType::Handle(Z);
    Array& handler_types = Array::Handle(Z);
    DescriptorList* pc_descriptors_list = new (Z) DescriptorList(Z);
    ExceptionHandlerList* exception_handlers_list =
        new (Z) ExceptionHandlerList(function);

    // Encoding of ExceptionsTable is described in
    // pkg/dart2bytecode/lib/exceptions.dart.
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
          UntaggedPcDescriptors::kOther, start_pc, DeoptId::kNone,
          TokenPosition::kNoSource, try_index,
          UntaggedPcDescriptors::kInvalidYieldIndex);
      pc_descriptors_list->AddDescriptor(
          UntaggedPcDescriptors::kOther, end_pc, DeoptId::kNone,
          TokenPosition::kNoSource, try_index,
          UntaggedPcDescriptors::kInvalidYieldIndex);

      // The exception handler keeps a zone handle of the types array, rather
      // than a raw pointer. Do not share the handle across iterations to avoid
      // clobbering the array.
      exception_handlers_list->AddHandler(
          try_index, outer_try_index, handler_pc, is_generated,
          Array::ZoneHandle(Z, handler_types.ptr()), needs_stacktrace);
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

  reader_.ReadUInt();  // Skip local variables offset.
}

ArrayPtr BytecodeReaderHelper::ReadBytecodeComponent() {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());

  AlternativeReadingScope alt(&reader_, 0);

  const intptr_t start_offset = reader_.offset();

  intptr_t magic = reader_.ReadUInt32();
  if (magic != KernelBytecode::kMagicValue) {
    FATAL("Unexpected Dart bytecode magic %" Px, magic);
  }

  const intptr_t version = reader_.ReadUInt32();
  if (version != KernelBytecode::kBytecodeFormatVersion) {
    FATAL("Unsupported Dart bytecode format version %" Pd
          ". "
          "This version of Dart VM supports bytecode format version %" Pd ".",
          version, KernelBytecode::kBytecodeFormatVersion);
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
      Z, BytecodeComponentData::New(
             Z, *(reader_.typed_data()), version, num_objects,
             string_table_offset, strings_contents_offset,
             object_offsets_offset, objects_contents_offset, main_offset,
             num_libraries, library_index_offset, libraries_offset, num_classes,
             classes_offset, members_offset, num_codes, codes_offset,
             source_positions_offset, source_files_offset, line_starts_offset,
             local_variables_offset, annotations_offset, Heap::kOld));

  BytecodeComponentData bytecode_component(bytecode_component_array);

  // Read object offsets.
  Smi& offs = Smi::Handle(Z);
  for (intptr_t i = 0; i < num_objects; ++i) {
    offs = Smi::New(reader_.ReadUInt());
    bytecode_component.SetObject(i, offs);
  }

  return bytecode_component_array.ptr();
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
  // pkg/dart2bytecode/lib/object_table.dart.
  enum ObjectKind {
    kInvalid,
    kLibrary,
    kClass,
    kMember,
    kClosure,
    kName,
    kTypeArguments,
    kConstObject,
    kArgDesc,
    kScript,
    kType,
  };

  // Member flags, must be in sync with _MemberHandle constants in
  // pkg/dart2bytecode/lib/object_table.dart.
  const intptr_t kFlagIsField = kFlagBit0;
  const intptr_t kFlagIsConstructor = kFlagBit1;

  // ArgDesc flags, must be in sync with _ArgDescHandle constants in
  // pkg/dart2bytecode/lib/object_table.dart.
  const int kFlagHasNamedArgs = kFlagBit0;
  const int kFlagHasTypeArgs = kFlagBit1;

  // Script flags, must be in sync with _ScriptHandle constants in
  // pkg/dart2bytecode/lib/object_table.dart.
  const int kFlagHasSourceFile = kFlagBit0;

  // Name flags, must be in sync with _NameHandle constants in
  // pkg/dart2bytecode/lib/object_table.dart.
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
        FATAL("Unable to find library %s", uri.ToCString());
      }
      return library;
    }
    case kClass: {
      const Library& library = Library::CheckedHandle(Z, ReadObject());
      const String& class_name = String::CheckedHandle(Z, ReadObject());
      if (class_name.ptr() == Symbols::Empty().ptr()) {
        NoSafepointScope no_safepoint_scope(thread_);
        ClassPtr cls = library.toplevel_class();
        if (cls == Class::null()) {
          FATAL("Unable to find toplevel class %s", library.ToCString());
        }
        return cls;
      }
      ClassPtr cls = library.LookupClassAllowPrivate(class_name);
      if (cls == Class::null()) {
        FATAL("Unable to find class %s in %s", class_name.ToCString(),
              library.ToCString());
      }
      return cls;
    }
    case kMember: {
      const Class& cls = Class::CheckedHandle(Z, ReadObject());
      String& name = String::CheckedHandle(Z, ReadObject());
      if ((flags & kFlagIsField) != 0) {
        FieldPtr field = cls.LookupField(name);
        if (field == Field::null()) {
          FATAL("Unable to find field %s in %s", name.ToCString(),
                cls.ToCString());
        }
        return field;
      } else {
        if ((flags & kFlagIsConstructor) != 0) {
          name = ConstructorName(cls, name);
        }
        ASSERT(!name.IsNull() && name.IsSymbol());
        if (name.ptr() == scoped_function_name_.ptr() &&
            cls.ptr() == scoped_function_class_.ptr()) {
          return scoped_function_.ptr();
        }
        FunctionPtr function = Function::null();
        if ((flags & kFlagIsConstructor) != 0) {
          if (cls.EnsureIsAllocateFinalized(thread_) == Error::null()) {
            function = Resolver::ResolveFunction(Z, cls, name);
          }
        } else {
          if (cls.EnsureIsFinalized(thread_) == Error::null()) {
            function = Resolver::ResolveFunction(Z, cls, name);
          }
        }
        if (function == Function::null()) {
          // When requesting a getter, also return method extractors.
          if (Field::IsGetterName(name)) {
            String& method_name =
                String::Handle(Z, Field::NameFromGetter(name));
            function = Resolver::ResolveFunction(Z, cls, method_name);
            if (function != Function::null()) {
              function = Function::Handle(Z, function).GetMethodExtractor(name);
              if (function != Function::null()) {
                return function;
              }
            }
          }
          FATAL("Unable to find function %s in %s", name.ToCString(),
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
    case kName: {
      if ((flags & kFlagIsPublic) == 0) {
        const Library& library = Library::CheckedHandle(Z, ReadObject());
        ASSERT(!library.IsNull());
        auto& name = String::Handle(Z, ReadString(/* is_canonical = */ false));
        name = library.PrivateName(name);
        return name.ptr();
      }
      return ReadString();
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
      RELEASE_ASSERT((flags & kFlagHasSourceFile) == 0);
      return Script::New(uri, Object::null_string());
    }
    case kType: {
      const intptr_t tag = (flags & kTagMask) / kFlagBit0;
      const Nullability nullability = ((flags & kFlagIsNullable) != 0)
                                          ? Nullability::kNullable
                                          : Nullability::kNonNullable;
      return ReadType(tag, nullability);
    }
    default:
      UNREACHABLE();
  }

  return Object::null();
}

ObjectPtr BytecodeReaderHelper::ReadConstObject(intptr_t tag) {
  // Must be in sync with enum ConstTag in
  // pkg/dart2bytecode/lib/object_table.dart.
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
    kMap,
    kSet,
    kRecord,
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
      return Canonicalize(obj);
    }
    case kInt: {
      const int64_t value = reader_.ReadSLEB128AsInt64();
      if (Smi::IsValid(value)) {
        return Smi::New(static_cast<intptr_t>(value));
      }
      const Integer& obj = Integer::Handle(Z, Integer::New(value, Heap::kOld));
      return Canonicalize(obj);
    }
    case kDouble: {
      const int64_t bits = reader_.ReadSLEB128AsInt64();
      double value = bit_cast<double, int64_t>(bits);
      const Double& obj = Double::Handle(Z, Double::New(value, Heap::kOld));
      return Canonicalize(obj);
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
      return Canonicalize(array);
    }
    case kTearOff: {
      Object& obj = Object::Handle(Z, ReadObject());
      ASSERT(obj.IsFunction());
      obj = Function::Cast(obj).ImplicitClosureFunction();
      ASSERT(obj.IsFunction());
      obj = Function::Cast(obj).ImplicitStaticClosure();
      ASSERT(obj.IsInstance());
      return Canonicalize(Instance::Cast(obj));
    }
    case kBool: {
      bool is_true = reader_.ReadByte() != 0;
      return is_true ? Bool::True().ptr() : Bool::False().ptr();
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
      return Canonicalize(obj);
    }
    case kTearOffInstantiation: {
      Closure& closure = Closure::CheckedHandle(Z, ReadObject());
      const TypeArguments& type_args =
          TypeArguments::CheckedHandle(Z, ReadObject());
      closure = Closure::New(
          TypeArguments::Handle(Z, closure.instantiator_type_arguments()),
          TypeArguments::Handle(Z, closure.function_type_arguments()),
          type_args, Function::Handle(Z, closure.function()),
          Object::Handle(Z, closure.RawContext()), Heap::kOld);
      return Canonicalize(closure);
    }
    case kString:
      return ReadString();
    case kMap: {
      const auto& map_type = Type::CheckedHandle(Z, ReadObject());
      const intptr_t used_data = reader_.ReadUInt();

      const auto& map_class =
          Class::Handle(Z, IG->object_store()->const_map_impl_class());
      ASSERT(!map_class.IsNull());
      ASSERT(map_class.is_finalized());

      auto& type_arguments = TypeArguments::Handle(Z, map_type.arguments());
      type_arguments =
          map_class.GetInstanceTypeArguments(thread_, type_arguments);

      const auto& map = Map::Handle(Z, ConstMap::NewUninitialized(Heap::kOld));
      ASSERT_EQUAL(map.GetClassId(), kConstMapCid);
      map.SetTypeArguments(type_arguments);
      map.set_used_data(used_data);

      const auto& data = Array::Handle(Z, Array::New(used_data));
      map.set_data(data);
      map.set_deleted_keys(0);
      map.ComputeAndSetHashMask();

      Object& value = Object::Handle(Z);
      for (intptr_t i = 0; i < used_data; ++i) {
        value = ReadObject();
        data.SetAt(i, value);
      }
      return Canonicalize(map);
    }
    case kSet: {
      const AbstractType& elem_type =
          AbstractType::CheckedHandle(Z, ReadObject());

      const auto& set_class =
          Class::Handle(Z, IG->object_store()->const_set_impl_class());
      ASSERT(!set_class.IsNull());
      ASSERT(set_class.is_finalized());

      auto& type_arguments =
          TypeArguments::Handle(Z, TypeArguments::New(1, Heap::kOld));
      type_arguments.SetTypeAt(0, elem_type);
      type_arguments =
          set_class.GetInstanceTypeArguments(thread_, type_arguments);

      const auto& set = Set::Handle(Z, ConstSet::NewUninitialized(Heap::kOld));
      ASSERT_EQUAL(set.GetClassId(), kConstSetCid);
      set.SetTypeArguments(type_arguments);

      const intptr_t length = reader_.ReadUInt();
      set.set_used_data(length);

      const auto& data = Array::Handle(Z, Array::New(length));
      set.set_data(data);
      set.set_deleted_keys(0);
      set.ComputeAndSetHashMask();

      Object& value = Object::Handle(Z);
      for (intptr_t i = 0; i < length; ++i) {
        value = ReadObject();
        data.SetAt(i, value);
      }
      return Canonicalize(set);
    }
    case kRecord: {
      const RecordType& record_type =
          RecordType::CheckedHandle(Z, ReadObject());
      const intptr_t num_fields = reader_.ReadUInt();
      ASSERT(num_fields == record_type.NumFields());
      const RecordShape shape = record_type.shape();
      const auto& record = Record::Handle(Z, Record::New(shape));
      Object& value = Object::Handle(Z);
      for (intptr_t i = 0; i < num_fields; ++i) {
        value = ReadObject();
        record.SetFieldAt(i, value);
      }
      return Canonicalize(record);
    }
    default:
      UNREACHABLE();
  }
  return Object::null();
}

ObjectPtr BytecodeReaderHelper::ReadType(intptr_t tag,
                                         Nullability nullability) {
  // Must be in sync with enum TypeTag in
  // pkg/dart2bytecode/lib/object_table.dart.
  enum TypeTag {
    kInvalid,
    kDynamic,
    kVoid,
    kSimpleType,
    kTypeParameter,
    kGenericType,
    kFunctionType,
    kRecordType,
    kNull,
    kNever,
  };

  // FunctionType flags, must be in sync with _FunctionTypeHandle constants in
  // pkg/dart2bytecode/lib/object_table.dart.
  const int kFlagHasOptionalPositionalParams = 1 << 0;
  const int kFlagHasOptionalNamedParams = 1 << 1;
  const int kFlagHasTypeParams = 1 << 2;

  switch (tag) {
    case kInvalid:
      UNREACHABLE();
      break;
    case kDynamic:
      return Type::DynamicType();
    case kVoid:
      return Type::VoidType();
    case kNull:
      return Type::NullType();
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
      auto& type = TypeParameter::Handle(Z);
      if (parent.IsClass()) {
        type =
            Class::Cast(parent).TypeParameterAt(index_in_parent, nullability);
      } else if (parent.IsFunction()) {
        if (Function::Cast(parent).IsFactory()) {
          // For factory constructors VM uses type parameters of a class
          // instead of constructor's type parameters.
          parent = Function::Cast(parent).Owner();
          type =
              Class::Cast(parent).TypeParameterAt(index_in_parent, nullability);
        } else {
          type = Function::Cast(parent).TypeParameterAt(index_in_parent,
                                                        nullability);
        }
      } else if (parent.IsNull()) {
        ASSERT(!enclosing_function_types_.is_empty());
        for (intptr_t i = enclosing_function_types_.length() - 1; i >= 0; --i) {
          parent = enclosing_function_types_[i]->ptr();
          ASSERT(index_in_parent <
                 FunctionType::Cast(parent).NumTypeArguments());
          if (index_in_parent >=
              FunctionType::Cast(parent).NumParentTypeArguments()) {
            break;
          }
        }
        type = FunctionType::Cast(parent).TypeParameterAt(
            index_in_parent -
                FunctionType::Cast(parent).NumParentTypeArguments(),
            nullability);
      } else {
        UNREACHABLE();
      }
      return ClassFinalizer::FinalizeType(type, ClassFinalizer::kCanonicalize);
    }
    case kGenericType: {
      const Class& cls = Class::CheckedHandle(Z, ReadObject());
      if (!cls.is_declaration_loaded()) {
        LoadReferencedClass(cls);
      }
      const TypeArguments& type_arguments =
          TypeArguments::CheckedHandle(Z, ReadObject());
      const Type& type =
          Type::Handle(Z, Type::New(cls, type_arguments, nullability));
      type.SetIsFinalized();
      return type.Canonicalize(thread_);
    }
    case kFunctionType: {
      const intptr_t flags = reader_.ReadUInt();
      const intptr_t num_parent_type_args =
          enclosing_function_types_.is_empty()
              ? 0
              : enclosing_function_types_.Last()->NumTypeArguments();
      auto& signature_type = FunctionType::Handle(
          Z, FunctionType::New(num_parent_type_args, nullability));
      // TODO(alexmarkov): skip type finalization
      return ReadFunctionSignature(
          signature_type, (flags & kFlagHasOptionalPositionalParams) != 0,
          (flags & kFlagHasOptionalNamedParams) != 0,
          (flags & kFlagHasTypeParams) != 0,
          /* has_positional_param_names = */ false,
          /* has_parameter_flags */ false);
    }
    case kRecordType: {
      const intptr_t num_positional = reader_.ReadUInt();
      const intptr_t num_named = reader_.ReadUInt();

      const intptr_t num_fields = num_positional + num_named;
      const Array& field_types =
          Array::Handle(Z, Array::New(num_fields, Heap::kOld));
      const Array& field_names =
          (num_named == 0)
              ? Object::empty_array()
              : Array::Handle(Z, Array::New(num_named, Heap::kOld));
      AbstractType& type = AbstractType::Handle(Z);

      intptr_t pos = 0;
      for (intptr_t i = 0; i < num_positional; ++i) {
        type ^= ReadObject();
        field_types.SetAt(pos++, type);
      }

      if (num_named > 0) {
        String& name = String::Handle(Z);
        for (intptr_t i = 0; i < num_named; ++i) {
          name ^= ReadObject();
          field_names.SetAt(i, name);
          type ^= ReadObject();
          field_types.SetAt(pos++, type);
        }
        field_names.MakeImmutable();
      }

      const RecordShape shape =
          RecordShape::Register(thread_, num_fields, field_names);

      type = RecordType::New(shape, field_types, nullability);
      type.SetIsFinalized();
      return type.Canonicalize(thread_);
    }

      UNIMPLEMENTED();
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

TypeArgumentsPtr BytecodeReaderHelper::ReadTypeArguments() {
  const intptr_t length = reader_.ReadUInt();
  TypeArguments& type_arguments =
      TypeArguments::ZoneHandle(Z, TypeArguments::New(length));
  AbstractType& type = AbstractType::Handle(Z);
  for (intptr_t i = 0; i < length; ++i) {
    type ^= ReadObject();
    type_arguments.SetTypeAt(i, type);
  }
  return type_arguments.Canonicalize(thread_);
}

void BytecodeReaderHelper::ReadMembers(const Class& cls, bool discard_fields) {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  ASSERT(cls.is_type_finalized());
  ASSERT(!cls.is_loaded());

  const intptr_t num_functions = reader_.ReadUInt();
  functions_ = &Array::Handle(Z, Array::New(num_functions, Heap::kOld));
  function_index_ = 0;

  ReadFieldDeclarations(cls, discard_fields);
  ReadFunctionDeclarations(cls);

  ASSERT(!cls.is_loaded());
  cls.set_is_loaded(true);
}

void BytecodeReaderHelper::ReadFieldDeclarations(const Class& cls,
                                                 bool discard_fields) {
  // Field flags, must be in sync with FieldDeclaration constants in
  // pkg/dart2bytecode/lib/declarations.dart.
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
  const int kIsLateFlag = 1 << 14;
  const int kIsExtensionMemberFlag = 1 << 15;
  const int kHasInitializerFlag = 1 << 16;

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
  Object& value = Object::Handle(Z);
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
      script_class = cls.ptr();
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

    field.set_has_pragma(has_pragma);
    field.set_is_covariant((flags & kIsCovariantFlag) != 0);
    field.set_is_generic_covariant_impl((flags & kIsGenericCovariantImplFlag) !=
                                        0);
    field.set_has_nontrivial_initializer(has_nontrivial_initializer);
    field.set_is_extension_member(is_extension_member);
    field.set_has_initializer(has_initializer);

    if (!has_nontrivial_initializer) {
      value = ReadObject();
      if (is_static) {
        if (field.is_late() && !has_initializer) {
          value = Object::sentinel().ptr();
        }
      } else {
        // Null-initialized instance fields are tracked separately for each
        // constructor (see handling of kHasNullableFieldsFlag).
        if (!value.IsNull()) {
          field.RecordStore(value);
        }
      }
    }

    if ((flags & kHasInitializerCodeFlag) != 0) {
      const intptr_t code_offset = reader_.ReadUInt();
      BytecodeLoader* loader = thread_->bytecode_loader();
      ASSERT(loader != nullptr);
      loader->SetOffset(field,
                        code_offset + bytecode_component_->GetCodesOffset());
      if (is_static) {
        value = Object::sentinel().ptr();
      }
    }

    if ((flags & kHasGetterFlag) != 0) {
      name ^= ReadObject();
      const auto& signature = FunctionType::Handle(Z, FunctionType::New());
      function =
          Function::New(signature, name,
                        is_static ? UntaggedFunction::kImplicitStaticGetter
                                  : UntaggedFunction::kImplicitGetter,
                        is_static, is_const,
                        false,  // is_abstract
                        false,  // is_external
                        false,  // is_native
                        script_class, position);
      NOT_IN_PRECOMPILED(function.set_end_token_pos(end_position));
      signature.set_result_type(type);
      function.set_is_debuggable(false);
      function.set_accessor_field(field);
      function.set_is_extension_member(is_extension_member);
      SetupFieldAccessorFunction(cls, function, type);
      if (is_const && has_nontrivial_initializer) {
        BytecodeLoader* loader = thread_->bytecode_loader();
        ASSERT(loader != nullptr);
        loader->SetOffset(function, loader->GetOffset(field));
      } else {
        if (is_static) {
          function.AttachBytecode(Object::implicit_static_getter_bytecode());
        } else {
          function.AttachBytecode(Object::implicit_getter_bytecode());
        }
      }
      functions_->SetAt(function_index_++, function);
    }

    if ((flags & kHasSetterFlag) != 0) {
      ASSERT(is_late || ((!is_static) && (!is_final)));
      ASSERT(!is_const);
      name ^= ReadObject();
      const auto& signature = FunctionType::Handle(Z, FunctionType::New());
      function = Function::New(signature, name,
                               UntaggedFunction::kImplicitSetter, is_static,
                               false,  // is_const
                               false,  // is_abstract
                               false,  // is_external
                               false,  // is_native
                               script_class, position);
      NOT_IN_PRECOMPILED(function.set_end_token_pos(end_position));
      signature.set_result_type(Object::void_type());
      function.set_is_debuggable(false);
      function.set_accessor_field(field);
      function.set_is_extension_member(is_extension_member);
      SetupFieldAccessorFunction(cls, function, type);
      if (is_static) {
        function.AttachBytecode(Object::implicit_static_setter_bytecode());
      } else {
        function.AttachBytecode(Object::implicit_setter_bytecode());
      }
      functions_->SetAt(function_index_++, function);
    }

    if ((flags & kHasAnnotationsFlag) != 0) {
      reader_.ReadUInt();  // Skip annotations offset.
    }

    if (field.is_static()) {
      IG->RegisterStaticField(field, value);
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

// TODO(alexmarkov): unify with
// TranslationHelper::SetupFieldAccessorFunction.
void BytecodeReaderHelper::SetupFieldAccessorFunction(
    const Class& klass,
    const Function& function,
    const AbstractType& field_type) {
  bool is_setter = function.IsImplicitSetterFunction();
  bool is_method = !function.IsStaticFunction();
  intptr_t parameter_count = (is_method ? 1 : 0) + (is_setter ? 1 : 0);

  const FunctionType& signature = FunctionType::Handle(Z, function.signature());
  signature.SetNumOptionalParameters(0, false);
  signature.set_num_fixed_parameters(parameter_count);
  if (parameter_count > 0) {
    signature.set_parameter_types(
        Array::Handle(Z, Array::New(parameter_count, Heap::kOld)));
  }
  NOT_IN_PRECOMPILED(function.CreateNameArray());

  intptr_t pos = 0;
  if (is_method) {
    signature.SetParameterTypeAt(
        pos, AbstractType::Handle(Z, klass.DeclarationType()));
    NOT_IN_PRECOMPILED(function.SetParameterNameAt(pos, Symbols::This()));
    pos++;
  }
  if (is_setter) {
    signature.SetParameterTypeAt(pos, field_type);
    NOT_IN_PRECOMPILED(function.SetParameterNameAt(pos, Symbols::Value()));
    pos++;
  }
}

PatchClassPtr BytecodeReaderHelper::GetPatchClass(const Class& cls,
                                                  const Script& script) {
  if (patch_class_ != nullptr && patch_class_->wrapped_class() == cls.ptr() &&
      patch_class_->script() == script.ptr()) {
    return patch_class_->ptr();
  }
  if (patch_class_ == nullptr) {
    patch_class_ = &PatchClass::Handle(Z);
  }
  *patch_class_ = PatchClass::New(cls, KernelProgramInfo::Handle(Z), script);
  return patch_class_->ptr();
}

InstancePtr BytecodeReaderHelper::Canonicalize(const Instance& instance) {
  if (instance.IsNull()) return instance.ptr();
  return instance.Canonicalize(thread_);
}

void BytecodeReaderHelper::ReadFunctionDeclarations(const Class& cls) {
  // Function flags, must be in sync with FunctionDeclaration constants in
  // pkg/dart2bytecode/lib/declarations.dart.
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
  const int kIsExtensionMemberFlag = 1 << 23;
  const int kHasParameterFlagsFlag = 1 << 24;

  const intptr_t num_functions = reader_.ReadListLength();
  ASSERT(function_index_ + num_functions == functions_->Length());

  if (function_index_ + num_functions == 0) {
    return;
  }

  String& name = String::Handle(Z);
  Object& script_class = Object::Handle(Z);
  FunctionType& signature = FunctionType::Handle(Z);
  Function& function = Function::Handle(Z);
  Array& parameter_types = Array::Handle(Z);
  AbstractType& type = AbstractType::Handle(Z);

  name = cls.ScrubbedName();

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
      script_class = cls.ptr();
    }

    TokenPosition position = TokenPosition::kNoSource;
    TokenPosition end_position = TokenPosition::kNoSource;
    if ((flags & kHasSourcePositionsFlag) != 0) {
      position = reader_.ReadPosition();
      end_position = reader_.ReadPosition();
    }

    UntaggedFunction::Kind kind = UntaggedFunction::kRegularFunction;
    if ((flags & kIsGetterFlag) != 0) {
      kind = UntaggedFunction::kGetterFunction;
    } else if ((flags & kIsSetterFlag) != 0) {
      kind = UntaggedFunction::kSetterFunction;
    } else if ((flags & (kIsConstructorFlag | kIsFactoryFlag)) != 0) {
      kind = UntaggedFunction::kConstructor;
      name = ConstructorName(cls, name);
    }

    signature = FunctionType::New();
    function = Function::New(
        signature, name, kind, is_static, (flags & kIsConstFlag) != 0,
        (flags & kIsAbstractFlag) != 0, (flags & kIsExternalFlag) != 0,
        is_native, script_class, position);

    // Declare function scope as types (type parameters) in function
    // signature may back-reference to the function being declared.
    // At this moment, owner class is not fully loaded yet and it won't be
    // able to serve function lookup requests.
    FunctionScope function_scope(this, function, name, cls);
    FunctionTypeScope function_type_scope(this, signature);

    function.set_has_pragma(has_pragma);
    NOT_IN_PRECOMPILED(function.set_end_token_pos(end_position));
    function.set_is_synthetic((flags & kIsNoSuchMethodForwarderFlag) != 0);
    function.set_is_reflectable((flags & kIsReflectableFlag) != 0);
    function.set_is_debuggable((flags & kIsDebuggableFlag) != 0);
    function.set_is_extension_member(is_extension_member);

    if ((flags & kIsSyncStarFlag) != 0) {
      function.set_modifier(UntaggedFunction::kSyncGen);
      function.set_is_inlinable(false);
    } else if ((flags & kIsAsyncFlag) != 0) {
      function.set_modifier(UntaggedFunction::kAsync);
      function.set_is_inlinable(false);
    } else if ((flags & kIsAsyncStarFlag) != 0) {
      function.set_modifier(UntaggedFunction::kAsyncGen);
      function.set_is_inlinable(false);
    }

    if ((flags & kHasTypeParamsFlag) != 0) {
      ReadTypeParametersDeclaration(Class::Handle(Z), signature);
    }

    const intptr_t num_implicit_params = (!is_static || is_factory) ? 1 : 0;
    const intptr_t num_params = num_implicit_params + reader_.ReadUInt();
    const bool has_optional_named_params =
        ((flags & kHasOptionalNamedParamsFlag) != 0);

    intptr_t num_required_params = num_params;
    if ((flags & (kHasOptionalPositionalParamsFlag |
                  kHasOptionalNamedParamsFlag)) != 0) {
      num_required_params = num_implicit_params + reader_.ReadUInt();
    }

    signature.set_num_fixed_parameters(num_required_params);
    signature.SetNumOptionalParameters(num_params - num_required_params,
                                       !has_optional_named_params);

    if (num_params > 0) {
      parameter_types = Array::New(num_params, Heap::kOld);
      signature.set_parameter_types(parameter_types);
      signature.CreateNameArrayIncludingFlags(Heap::kOld);
      NOT_IN_PRECOMPILED(function.CreateNameArray());
    }

    intptr_t param_index = 0;
    if (!is_static) {
      type = cls.DeclarationType();
      signature.SetParameterTypeAt(param_index, type);
      NOT_IN_PRECOMPILED(
          function.SetParameterNameAt(param_index, Symbols::This()));
      ++param_index;
    } else if (is_factory) {
      signature.SetParameterTypeAt(param_index, AbstractType::dynamic_type());
      NOT_IN_PRECOMPILED(function.SetParameterNameAt(
          param_index, Symbols::TypeArgumentsParameter()));
      ++param_index;
    }

    for (; param_index < num_params; ++param_index) {
      name ^= ReadObject();
      if (has_optional_named_params && (param_index >= num_required_params)) {
        signature.SetParameterNameAt(param_index, name);
      } else {
        NOT_IN_PRECOMPILED(function.SetParameterNameAt(param_index, name));
      }
      type ^= ReadObject();
      signature.SetParameterTypeAt(param_index, type);
    }

    if ((flags & kHasParameterFlagsFlag) != 0) {
      const intptr_t length = reader_.ReadUInt();
      const intptr_t offset = function.NumImplicitParameters();
      for (intptr_t i = 0; i < length; i++) {
        const intptr_t param_flags = reader_.ReadUInt();
        if ((param_flags & Parameter::kIsRequiredFlag) != 0) {
          RELEASE_ASSERT(function.HasOptionalNamedParameters());
          RELEASE_ASSERT(i + offset >= function.num_fixed_parameters());
          signature.SetIsRequiredAt(i + offset);
        }
      }
    }

    type ^= ReadObject();
    signature.set_result_type(type);

    if (is_native) {
      name ^= ReadObject();
      function.set_native_name(name);
    }

    if ((flags & kIsAbstractFlag) == 0) {
      const intptr_t code_offset = reader_.ReadUInt();
      BytecodeLoader* loader = thread_->bytecode_loader();
      ASSERT(loader != nullptr);
      loader->SetOffset(function,
                        code_offset + bytecode_component_->GetCodesOffset());
    }

    if ((flags & kHasAnnotationsFlag) != 0) {
      reader_.ReadUInt();  // Skip annotations offset.
    }

    functions_->SetAt(function_index_++, function);
  }

  {
    Thread* thread = Thread::Current();
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    cls.SetFunctions(*functions_);
  }

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

  BytecodeLoader* loader = thread_->bytecode_loader();
  ASSERT(loader != nullptr);

  AlternativeReadingScope alt(&reader_, loader->GetOffset(cls));
  ReadClassDeclaration(cls);
}

void BytecodeReaderHelper::ReadClassDeclaration(const Class& cls) {
  // Class flags, must be in sync with ClassDeclaration constants in
  // pkg/dart2bytecode/lib/declarations.dart.
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
  // Its cid is set in Class::New / IsolateGroup::RegisterClass /
  // ClassTable::Register, unless it was loaded for expression evaluation.
  ASSERT(cls.is_declared_in_bytecode());
  ASSERT(!cls.is_declaration_loaded());

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
    NOT_IN_PRECOMPILED(cls.set_token_pos(position));
    NOT_IN_PRECOMPILED(cls.set_end_token_pos(end_position));
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
    ReadTypeParametersDeclaration(cls, Object::null_function_type());
  }

  auto& type = AbstractType::CheckedHandle(Z, ReadObject());
  if (!type.IsNull()) {
    cls.set_super_type(Type::Cast(type));
  }

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
    reader_.ReadUInt();  // Skip annotations offset.
  }

  const intptr_t members_offset = reader_.ReadUInt();
  BytecodeLoader* loader = thread_->bytecode_loader();
  ASSERT(loader != nullptr);
  loader->SetOffset(cls,
                    members_offset + bytecode_component_->GetMembersOffset());

  if (!cls.is_type_finalized()) {
    ClassFinalizer::FinalizeTypesInClass(cls);
  }
}

void BytecodeReaderHelper::ReadLibraryDeclaration(
    const Library& library,
    bool lookup_classes,
    const GrowableObjectArray& pending_classes) {
  // Library flags, must be in sync with LibraryDeclaration constants in
  // pkg/dart2bytecode/lib/declarations.dart.
  // const int kUsesDartMirrorsFlag = 1 << 0;
  // const int kUsesDartFfiFlag = 1 << 1;

  ASSERT(!library.Loaded());
  ASSERT(library.toplevel_class() == Object::null());

  // TODO(alexmarkov): fill in library.used_scripts.

  reader_.ReadUInt();  // Flags.

  auto& name = String::CheckedHandle(Z, ReadObject());
  ASSERT(name.ptr() !=
         Symbols::Symbol(Symbols::kDartNativeWrappersLibNameId).ptr());
  library.SetName(name);

  const auto& script = Script::CheckedHandle(Z, ReadObject());

  library.SetLoadInProgress();

  const intptr_t num_classes = reader_.ReadUInt();
  ASSERT(num_classes > 0);
  auto& cls = Class::Handle(Z);

  for (intptr_t i = 0; i < num_classes; ++i) {
    name ^= ReadObject();
    const intptr_t class_offset =
        bytecode_component_->GetClassesOffset() + reader_.ReadUInt();

    if (i == 0) {
      ASSERT(name.ptr() == Symbols::Empty().ptr());
      cls = Class::New(library, Symbols::TopLevel(), script,
                       TokenPosition::kNoSource, /*register_class=*/true);
      cls.set_is_declared_in_bytecode(true);
      library.set_toplevel_class(cls);
    } else {
      if (lookup_classes) {
        cls = library.LookupClassAllowPrivate(name);
      }
      if (lookup_classes && !cls.IsNull()) {
        ASSERT(!cls.is_declaration_loaded());
        cls.set_script(script);
      } else {
        cls = Class::New(library, name, script, TokenPosition::kNoSource,
                         /*register_class=*/true);
        cls.set_is_declared_in_bytecode(true);
        library.AddClass(cls);
      }
    }

    BytecodeLoader* loader = thread_->bytecode_loader();
    ASSERT(loader != nullptr);
    loader->SetOffset(cls, class_offset);
    pending_classes.Add(cls);
  }

  ASSERT(!library.Loaded());
  library.SetLoaded();
}

void BytecodeReaderHelper::ReadLibraryDeclarations(intptr_t num_libraries) {
  auto& library = Library::Handle(Z);
  auto& uri = String::Handle(Z);
  auto& pending_classes =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());

  for (intptr_t i = 0; i < num_libraries; ++i) {
    uri ^= ReadObject();
    const intptr_t library_offset =
        bytecode_component_->GetLibrariesOffset() + reader_.ReadUInt();

    bool lookup_classes = true;
    library = Library::LookupLibrary(thread_, uri);
    if (library.IsNull()) {
      lookup_classes = false;
      library = Library::New(uri);
      library.Register(thread_);
    }

    if (library.Loaded()) {
      continue;
    }

    AlternativeReadingScope alt(&reader_, library_offset);
    ReadLibraryDeclaration(library, lookup_classes, pending_classes);
  }

  auto& cls = Class::Handle(Z);
  auto& error = Error::Handle(Z);
  auto& members = Array::Handle(Z);
  auto& function = Function::Handle(Z);
  auto& field = Field::Handle(Z);
  for (intptr_t i = 0, n = pending_classes.Length(); i < n; ++i) {
    cls ^= pending_classes.At(i);
    error = cls.EnsureIsFinalized(thread_);
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
      UNREACHABLE();
    }
    members = cls.functions();
    for (intptr_t j = 0, m = members.Length(); j < m; ++j) {
      function ^= members.At(j);
      if (!function.is_abstract() && !function.HasBytecode()) {
        ReadCode(function, thread_->bytecode_loader()->GetOffset(function));
      }
    }
    members = cls.fields();
    for (intptr_t j = 0, m = members.Length(); j < m; ++j) {
      field ^= members.At(j);
      if ((field.is_static() || field.is_late()) &&
          field.has_nontrivial_initializer()) {
        function = field.EnsureInitializerFunction();
        if (!function.HasBytecode()) {
          ReadCode(function, thread_->bytecode_loader()->GetOffset(field));
        }
      }
    }
  }
}

void BytecodeReaderHelper::ReadParameterCovariance(
    const Function& function,
    intptr_t code_offset,
    BitVector* is_covariant,
    BitVector* is_generic_covariant_impl) {
  ASSERT(function.is_declared_in_bytecode());

  const intptr_t num_params = function.NumParameters();
  ASSERT(is_covariant->length() == num_params);
  ASSERT(is_generic_covariant_impl->length() == num_params);

  AlternativeReadingScope alt(&reader_, code_offset);

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

LibraryPtr BytecodeReaderHelper::ReadMain() {
  return Library::RawCast(ReadObject());
}

TypedDataBasePtr BytecodeComponentData::GetTypedData() const {
  return TypedDataBase::RawCast(data_.At(kTypedData));
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
                                    const TypedDataBase& typed_data,
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

  data.SetAt(kTypedData, typed_data);

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

  return data.ptr();
}

void BytecodeReader::LoadClassDeclaration(const Class& cls) {
  ASSERT(cls.is_declared_in_bytecode());
  ASSERT(!cls.is_declaration_loaded());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());

  BytecodeLoader* loader = thread->bytecode_loader();
  ASSERT(loader != nullptr);

  BytecodeComponentData bytecode_component(
      Array::Handle(zone, loader->bytecode_component_array()));
  ASSERT(!bytecode_component.IsNull());
  BytecodeReaderHelper bytecode_reader(thread, &bytecode_component);

  AlternativeReadingScope alt(&bytecode_reader.reader(),
                              loader->GetOffset(cls));
  bytecode_reader.ReadClassDeclaration(cls);
}

void BytecodeReader::FinishClassLoading(const Class& cls) {
  ASSERT(cls.is_declared_in_bytecode());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());

  BytecodeLoader* loader = thread->bytecode_loader();
  ASSERT(loader != nullptr);

  BytecodeComponentData bytecode_component(
      Array::Handle(zone, loader->bytecode_component_array()));
  ASSERT(!bytecode_component.IsNull());
  BytecodeReaderHelper bytecode_reader(thread, &bytecode_component);

  AlternativeReadingScope alt(&bytecode_reader.reader(),
                              loader->GetOffset(cls));

  // If this is a dart:internal.ClassID class ignore field declarations
  // contained in the Kernel file and instead inject our own const
  // fields.
  const bool discard_fields = cls.InjectCIDFields();

  bytecode_reader.ReadMembers(cls, discard_fields);
}

void BytecodeReader::ReadParameterCovariance(
    const Function& function,
    BitVector* is_covariant,
    BitVector* is_generic_covariant_impl) {
  ASSERT(function.is_declared_in_bytecode());
  ASSERT(!function.IsClosureFunction());

  // Method extractors of abstract methods are only used as
  // targets of interface calls, so covariance of parameters is irrelevant.
  if (function.is_abstract()) {
    return;
  }

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  auto& binary = TypedDataBase::Handle(zone);
  intptr_t offset = 0;

  const auto& bytecode = Bytecode::Handle(zone, function.GetBytecode());
  if (bytecode.IsNull()) {
    BytecodeLoader* loader = thread->bytecode_loader();
    ASSERT(loader != nullptr);
    binary = loader->binary();
    offset = loader->GetOffset(function);
  } else {
    binary = bytecode.binary();
    ASSERT(!binary.IsNull());
    offset = bytecode.code_offset();
    ASSERT(offset > 0);
  }
  BytecodeReaderHelper bytecode_reader(thread, binary);
  bytecode_reader.ReadParameterCovariance(function, offset, is_covariant,
                                          is_generic_covariant_impl);
}

}  // namespace bytecode
}  // namespace dart

#endif  // defined(DART_DYNAMIC_MODULES)
