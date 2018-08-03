// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/bytecode_reader.h"

#include "vm/bootstrap.h"
#include "vm/code_descriptors.h"
#include "vm/compiler/assembler/disassembler_kbc.h"
#include "vm/dart_entry.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#if defined(DART_USE_INTERPRETER)

#define Z (zone_)
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
      active_class_(active_class) {}

void BytecodeMetadataHelper::ReadMetadata(const Function& function) {
  const intptr_t node_offset = function.kernel_offset();
  const intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return;
  }

  AlternativeReadingScope alt(&helper_->reader_, &H.metadata_payloads(),
                              md_offset);

  // Create object pool and read pool entries.
  const intptr_t obj_count = helper_->reader_.ReadListLength();
  const ObjectPool& pool =
      ObjectPool::Handle(helper_->zone_, ObjectPool::New(obj_count));
  ReadPoolEntries(function, function, pool, 0);

  // Read bytecode and attach to function.
  const Code& bytecode = Code::Handle(helper_->zone_, ReadBytecode(pool));
  function.AttachBytecode(bytecode);

  // Read exceptions table.
  ReadExceptionsTable(bytecode);

  if (FLAG_dump_kernel_bytecode) {
    KernelBytecodeDisassembler::Disassemble(function);
  }

  // Read closures.
  Function& closure = Function::Handle(helper_->zone_);
  Code& closure_bytecode = Code::Handle(helper_->zone_);
  intptr_t num_closures = helper_->ReadListLength();
  for (intptr_t i = 0; i < num_closures; i++) {
    intptr_t closure_index = helper_->ReadUInt();
    ASSERT(closure_index < obj_count);
    closure ^= pool.ObjectAt(closure_index);

    // Read closure bytecode and attach to closure function.
    closure_bytecode = ReadBytecode(pool);
    closure.AttachBytecode(closure_bytecode);

    // Read closure exceptions table.
    ReadExceptionsTable(closure_bytecode);

    if (FLAG_dump_kernel_bytecode) {
      KernelBytecodeDisassembler::Disassemble(closure);
    }
  }
}

intptr_t BytecodeMetadataHelper::ReadPoolEntries(const Function& function,
                                                 const Function& inner_function,
                                                 const ObjectPool& pool,
                                                 intptr_t from_index) {
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
    kField,
    kFieldOffset,
    kClass,
    kTypeArgumentsFieldOffset,
    kTearOff,
    kType,
    kTypeArguments,
    kList,
    kInstance,
    kSymbol,
    kTypeArgumentsForInstanceAllocation,
    kContextOffset,
    kClosureFunction,
    kEndClosureFunctionScope,
    kNativeEntry,
    kSubtypeTestCache,
  };

  enum InvocationKind {
    method,  // x.foo(...) or foo(...)
    getter,  // x.foo
    setter   // x.foo = ...
  };

  Object& obj = Object::Handle(helper_->zone_);
  Object& elem = Object::Handle(helper_->zone_);
  Array& array = Array::Handle(helper_->zone_);
  Field& field = Field::Handle(helper_->zone_);
  Class& cls = Class::Handle(helper_->zone_);
  String& name = String::Handle(helper_->zone_);
  TypeArguments& type_args = TypeArguments::Handle(helper_->zone_);
  const intptr_t obj_count = pool.Length();
  for (intptr_t i = from_index; i < obj_count; ++i) {
    const intptr_t tag = helper_->ReadTag();
    switch (tag) {
      case ConstantPoolTag::kInvalid:
        UNREACHABLE();
      case ConstantPoolTag::kNull:
        obj = Object::null();
        break;
      case ConstantPoolTag::kString:
        obj = H.DartString(helper_->ReadStringReference()).raw();
        ASSERT(obj.IsString());
        obj = H.Canonicalize(String::Cast(obj));
        break;
      case ConstantPoolTag::kInt: {
        uint32_t low_bits = helper_->ReadUInt32();
        int64_t value = helper_->ReadUInt32();
        value = (value << 32) | low_bits;
        obj = Integer::New(value);
      } break;
      case ConstantPoolTag::kDouble: {
        uint32_t low_bits = helper_->ReadUInt32();
        uint64_t bits = helper_->ReadUInt32();
        bits = (bits << 32) | low_bits;
        double value = bit_cast<double, uint64_t>(bits);
        obj = Double::New(value);
      } break;
      case ConstantPoolTag::kBool:
        if (helper_->ReadUInt() == 1) {
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
            array.SetAt(j, H.DartSymbolPlain(helper_->ReadStringReference()));
          }
          obj = ArgumentsDescriptor::New(num_type_args, num_arguments, array);
        }
      } break;
      case ConstantPoolTag::kICData: {
        InvocationKind kind = static_cast<InvocationKind>(helper_->ReadByte());
        if (kind == InvocationKind::getter) {
          name = helper_->ReadNameAsGetterName().raw();
        } else if (kind == InvocationKind::setter) {
          name = helper_->ReadNameAsSetterName().raw();
        } else {
          ASSERT(kind == InvocationKind::method);
          name = helper_->ReadNameAsMethodName().raw();
        }
        intptr_t arg_desc_index = helper_->ReadUInt();
        ASSERT(arg_desc_index < i);
        array ^= pool.ObjectAt(arg_desc_index);
        // TODO(regis): Should num_args_tested be explicitly provided?
        obj = ICData::New(function, name,
                          array,  // Arguments descriptor.
                          Thread::kNoDeoptId, 1 /* num_args_tested */,
                          ICData::RebindRule::kInstance);
#if defined(TAG_IC_DATA)
        ICData::Cast(obj).set_tag(ICData::Tag::kInstanceCall);
#endif
      } break;
      case ConstantPoolTag::kStaticICData: {
        InvocationKind kind = static_cast<InvocationKind>(helper_->ReadByte());
        NameIndex target = helper_->ReadCanonicalNameReference();
        if (H.IsConstructor(target)) {
          name = H.DartConstructorName(target).raw();
          elem = H.LookupConstructorByKernelConstructor(target);
        } else if (H.IsField(target)) {
          if (kind == InvocationKind::getter) {
            name = H.DartGetterName(target).raw();
          } else if (kind == InvocationKind::setter) {
            name = H.DartSetterName(target).raw();
          } else {
            ASSERT(kind == InvocationKind::method);
            UNIMPLEMENTED();  // TODO(regis): Revisit.
          }
          field = H.LookupFieldByKernelField(target);
          cls = field.Owner();
          elem = cls.LookupFunctionAllowPrivate(name);
        } else {
          if ((kind == InvocationKind::method) && H.IsGetter(target)) {
            UNIMPLEMENTED();  // TODO(regis): Revisit.
          }
          name = H.DartProcedureName(target).raw();
          elem = H.LookupStaticMethodByKernelProcedure(target);
        }
        ASSERT(elem.IsFunction());
        intptr_t arg_desc_index = helper_->ReadUInt();
        ASSERT(arg_desc_index < i);
        array ^= pool.ObjectAt(arg_desc_index);
        obj = ICData::New(function, name,
                          array,  // Arguments descriptor.
                          Thread::kNoDeoptId, 0 /* num_args_tested */,
                          ICData::RebindRule::kStatic);
        ICData::Cast(obj).AddTarget(Function::Cast(elem));
#if defined(TAG_IC_DATA)
        ICData::Cast(obj).set_tag(ICData::Tag::kStaticCall);
#endif
      } break;
      case ConstantPoolTag::kField:
        obj = H.LookupFieldByKernelField(helper_->ReadCanonicalNameReference());
        ASSERT(obj.IsField());
        break;
      case ConstantPoolTag::kFieldOffset:
        obj = H.LookupFieldByKernelField(helper_->ReadCanonicalNameReference());
        ASSERT(obj.IsField());
        obj = Smi::New(Field::Cast(obj).Offset() / kWordSize);
        break;
      case ConstantPoolTag::kClass:
        obj = H.LookupClassByKernelClass(helper_->ReadCanonicalNameReference());
        ASSERT(obj.IsClass());
        break;
      case ConstantPoolTag::kTypeArgumentsFieldOffset:
        cls = H.LookupClassByKernelClass(helper_->ReadCanonicalNameReference());
        obj = Smi::New(cls.type_arguments_field_offset() / kWordSize);
        break;
      case ConstantPoolTag::kTearOff:
        obj = H.LookupStaticMethodByKernelProcedure(
            helper_->ReadCanonicalNameReference());
        ASSERT(obj.IsFunction());
        obj = Function::Cast(obj).ImplicitClosureFunction();
        ASSERT(obj.IsFunction());
        obj = Function::Cast(obj).ImplicitStaticClosure();
        ASSERT(obj.IsInstance());
        obj = H.Canonicalize(Instance::Cast(obj));
        break;
      case ConstantPoolTag::kType:
        obj = type_translator_.BuildType().raw();
        ASSERT(obj.IsAbstractType());
        break;
      case ConstantPoolTag::kTypeArguments:
        obj = type_translator_.BuildTypeArguments(helper_->ReadListLength())
                  .raw();
        ASSERT(obj.IsNull() || obj.IsTypeArguments());
        break;
      case ConstantPoolTag::kList: {
        obj = type_translator_.BuildType().raw();
        ASSERT(obj.IsAbstractType());
        const intptr_t length = helper_->ReadListLength();
        array = Array::New(length, AbstractType::Cast(obj));
        for (intptr_t j = 0; j < length; j++) {
          intptr_t elem_index = helper_->ReadUInt();
          ASSERT(elem_index < i);
          elem = pool.ObjectAt(elem_index);
          array.SetAt(j, elem);
        }
        obj = H.Canonicalize(Array::Cast(array));
        ASSERT(!obj.IsNull());
      } break;
      case ConstantPoolTag::kInstance: {
        cls = H.LookupClassByKernelClass(helper_->ReadCanonicalNameReference());
        obj = Instance::New(cls, Heap::kOld);
        intptr_t type_args_index = helper_->ReadUInt();
        ASSERT(type_args_index < i);
        type_args ^= pool.ObjectAt(type_args_index);
        if (!type_args.IsNull()) {
          Instance::Cast(obj).SetTypeArguments(type_args);
        }
        intptr_t num_fields = helper_->ReadUInt();
        for (intptr_t j = 0; j < num_fields; j++) {
          NameIndex field_name = helper_->ReadCanonicalNameReference();
          ASSERT(H.IsField(field_name));
          field = H.LookupFieldByKernelField(field_name);
          intptr_t elem_index = helper_->ReadUInt();
          ASSERT(elem_index < i);
          elem = pool.ObjectAt(elem_index);
          Instance::Cast(obj).SetField(field, elem);
        }
        obj = H.Canonicalize(Instance::Cast(obj));
      } break;
      case ConstantPoolTag::kSymbol:
        obj = H.DartSymbolPlain(helper_->ReadStringReference()).raw();
        ASSERT(String::Cast(obj).IsSymbol());
        break;
      case ConstantPoolTag::kTypeArgumentsForInstanceAllocation: {
        cls = H.LookupClassByKernelClass(helper_->ReadCanonicalNameReference());
        obj =
            type_translator_
                .BuildInstantiatedTypeArguments(cls, helper_->ReadListLength())
                .raw();
        ASSERT(obj.IsNull() || obj.IsTypeArguments());
      } break;
      case ConstantPoolTag::kContextOffset: {
        intptr_t index = helper_->ReadUInt();
        if (index == 0) {
          obj = Smi::New(Context::parent_offset() / kWordSize);
        } else {
          obj = Smi::New(Context::variable_offset(index - 1) / kWordSize);
        }
      } break;
      case ConstantPoolTag::kClosureFunction: {
        name = H.DartSymbolPlain(helper_->ReadStringReference()).raw();
        const Function& closure = Function::Handle(
            helper_->zone_,
            Function::NewClosureFunction(name, inner_function,
                                         TokenPosition::kNoSource));

        FunctionNodeHelper function_node_helper(helper_);
        function_node_helper.ReadUntilExcluding(
            FunctionNodeHelper::kTypeParameters);
        type_translator_.LoadAndSetupTypeParameters(
            active_class_, closure, helper_->ReadListLength(), closure);
        function_node_helper.SetJustRead(FunctionNodeHelper::kTypeParameters);

        // Scope remains opened until ConstantPoolTag::kEndClosureFunctionScope.
        ActiveTypeParametersScope scope(
            active_class_, &closure,
            TypeArguments::Handle(helper_->zone_, closure.type_parameters()),
            helper_->zone_);

        function_node_helper.ReadUntilExcluding(
            FunctionNodeHelper::kPositionalParameters);

        intptr_t required_parameter_count =
            function_node_helper.required_parameter_count_;
        intptr_t total_parameter_count =
            function_node_helper.total_parameter_count_;

        intptr_t positional_parameter_count = helper_->ReadListLength();

        intptr_t named_parameter_count =
            total_parameter_count - positional_parameter_count;

        const intptr_t extra_parameters = 1;
        closure.set_num_fixed_parameters(extra_parameters +
                                         required_parameter_count);
        if (named_parameter_count > 0) {
          closure.SetNumOptionalParameters(named_parameter_count, false);
        } else {
          closure.SetNumOptionalParameters(
              positional_parameter_count - required_parameter_count, true);
        }
        intptr_t parameter_count = extra_parameters + total_parameter_count;
        closure.set_parameter_types(Array::Handle(
            helper_->zone_, Array::New(parameter_count, Heap::kOld)));
        closure.set_parameter_names(Array::Handle(
            helper_->zone_, Array::New(parameter_count, Heap::kOld)));

        intptr_t pos = 0;
        closure.SetParameterTypeAt(pos, AbstractType::dynamic_type());
        closure.SetParameterNameAt(pos, Symbols::ClosureParameter());
        pos++;

        const Library& lib =
            Library::Handle(helper_->zone_, active_class_->klass->library());
        for (intptr_t j = 0; j < positional_parameter_count; ++j, ++pos) {
          VariableDeclarationHelper helper(helper_);
          helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
          const AbstractType& type = type_translator_.BuildVariableType();
          Tag tag = helper_->ReadTag();  // read (first part of) initializer.
          if (tag == kSomething) {
            helper_->SkipExpression();  // read (actual) initializer.
          }

          closure.SetParameterTypeAt(pos, type);
          closure.SetParameterNameAt(pos,
                                     H.DartIdentifier(lib, helper.name_index_));
        }

        intptr_t named_parameter_count_check = helper_->ReadListLength();
        ASSERT(named_parameter_count_check == named_parameter_count);
        for (intptr_t j = 0; j < named_parameter_count; ++j, ++pos) {
          VariableDeclarationHelper helper(helper_);
          helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
          const AbstractType& type = type_translator_.BuildVariableType();
          Tag tag = helper_->ReadTag();  // read (first part of) initializer.
          if (tag == kSomething) {
            helper_->SkipExpression();  // read (actual) initializer.
          }

          closure.SetParameterTypeAt(pos, type);
          closure.SetParameterNameAt(pos,
                                     H.DartIdentifier(lib, helper.name_index_));
        }

        function_node_helper.SetJustRead(FunctionNodeHelper::kNamedParameters);

        const AbstractType& return_type = type_translator_.BuildVariableType();
        closure.set_result_type(return_type);
        function_node_helper.SetJustRead(FunctionNodeHelper::kReturnType);
        // The closure has no body.
        function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);

        pool.SetTypeAt(i, ObjectPool::kTaggedObject);
        pool.SetObjectAt(i, closure);

        // Continue reading the constant pool entries inside the opened
        // ActiveTypeParametersScope until the scope gets closed by a
        // kEndClosureFunctionScope tag, in which case control returns here.
        i = ReadPoolEntries(function, closure, pool, i + 1);
        // Pool entry at index i has been set to null, because it was a
        // kEndClosureFunctionScope.
        ASSERT(pool.ObjectAt(i) == Object::null());
        continue;
      }
      case ConstantPoolTag::kEndClosureFunctionScope: {
        // Entry is not used and set to null.
        obj = Object::null();
        pool.SetTypeAt(i, ObjectPool::kTaggedObject);
        pool.SetObjectAt(i, obj);
        return i;  // The caller will close the scope.
      } break;
      case ConstantPoolTag::kNativeEntry: {
        name = H.DartString(helper_->ReadStringReference()).raw();
        obj = NativeEntry(function, name);
      } break;
      case ConstantPoolTag::kSubtypeTestCache: {
        obj = SubtypeTestCache::New();
      } break;
      default:
        UNREACHABLE();
    }
    pool.SetTypeAt(i, ObjectPool::kTaggedObject);
    pool.SetObjectAt(i, obj);
  }
  // Return the index of the last read pool entry.
  return obj_count - 1;
}

RawCode* BytecodeMetadataHelper::ReadBytecode(const ObjectPool& pool) {
  intptr_t size = helper_->reader_.ReadUInt();
  intptr_t offset = helper_->reader_.offset();
  const uint8_t* data = helper_->reader_.BufferAt(offset);
  helper_->reader_.set_offset(offset + size);

  // Create and return code object.
  return Code::FinalizeBytecode(reinterpret_cast<const void*>(data), size,
                                pool);
}

void BytecodeMetadataHelper::ReadExceptionsTable(const Code& bytecode) {
  const intptr_t try_block_count = helper_->reader_.ReadListLength();
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
      intptr_t start_pc = helper_->reader_.ReadUInt();
      intptr_t end_pc = helper_->reader_.ReadUInt();
      intptr_t handler_pc = helper_->reader_.ReadUInt();
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
                                         Thread::kNoDeoptId,
                                         TokenPosition::kNoSource, try_index);
      pc_descriptors_list->AddDescriptor(RawPcDescriptors::kOther, end_pc,
                                         Thread::kNoDeoptId,
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
    if (FLAG_link_natives_lazily) {
      trampoline = &NativeEntry::BootstrapNativeCallWrapper;
      native_function =
          reinterpret_cast<NativeFunction>(&NativeEntry::LinkNativeCall);
    } else {
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
  // TODO(regis): Introduce a new VM class subclassing Object and containing
  // these four untagged values.
#ifdef ARCH_IS_32_BIT
  const TypedData& native_entry = TypedData::Handle(
      zone, TypedData::New(kTypedDataUint32ArrayCid, 4, Heap::kOld));
  native_entry.SetUint32(0 << 2, static_cast<uint32_t>(kind));
  native_entry.SetUint32(1 << 2, reinterpret_cast<uint32_t>(trampoline));
  native_entry.SetUint32(2 << 2, reinterpret_cast<uint32_t>(native_function));
  native_entry.SetUint32(3 << 2, static_cast<uint32_t>(argc_tag));
#else
  const TypedData& native_entry = TypedData::Handle(
      zone, TypedData::New(kTypedDataUint64ArrayCid, 4, Heap::kOld));
  native_entry.SetUint64(0 << 3, static_cast<uint64_t>(kind));
  native_entry.SetUint64(1 << 3, reinterpret_cast<uint64_t>(trampoline));
  native_entry.SetUint64(2 << 3, reinterpret_cast<uint64_t>(native_function));
  native_entry.SetUint64(3 << 3, static_cast<uint64_t>(argc_tag));
#endif
  return native_entry.raw();
}

}  // namespace kernel
}  // namespace dart

#endif  // defined(DART_USE_INTERPRETER)
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
