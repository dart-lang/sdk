// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_RUNTIME_OFFSETS_LIST_H_
#define RUNTIME_VM_COMPILER_RUNTIME_OFFSETS_LIST_H_

// Macro list of all constants that differ based on whether the architecture is
// 32-bit or 64-bit. They are used to allow the target architecture to differ
// from the host, like this:
// 1) The macros correspond to constants defined throughout the VM that are
//    sized based on the *host* architecture.
// 2) offsets_extractor.cc prints these values to runtime_offsets_extracted.h,
//    for both 32 and 64 bit architectures.
// 3) runtime_api.h presents the runtime_offsets_extracted.h constants in a way
//    designed to look like the original constants from 1), but now namespaced
//    to dart::compiler::target, and sized based on the *target* architecture.
// 4) Users of the constants from 1) can now just add the namespace from 3) to
//    get all their constants sized based on the target rather than the host.

// FIELD(Class, Name) Offset of a field within a class.
// ARRAY(Class, Name) Offset of the first element and the size of the elements
//     in an array of this class.
// SIZEOF(Class, Name, What) Class::Name() is defined as sizeof(What).
// PAYLOAD_SIZEOF(Class, Name, HeaderSize) Instance size for a payload object.
//     Defines Class::Name(word payload_size) and uses Class::HeaderSize(),
//     which should give the size of the header before the payload. Also
//     defines Class::Name() (with no payload size argument) to be 0.
// RANGE(Class, Name, Type, First, Last, Filter) An array of offsets generated
//     by passing a value of the given Type in the range from First to Last to
//     Class::Name() if Filter returns true for that value.
// CONSTANT(Class, Name) Miscellaneous constant.
//
// COMMON_OFFSETS_LIST is for declarations that are valid in all contexts.
// JIT_OFFSETS_LIST is for declarations that are only valid in JIT mode.
// A declaration that is not valid in product mode can be wrapped with
// NOT_IN_PRODUCT().
//
// TODO(dartbug.com/43646): Add DART_PRECOMPILER as another axis.

#define COMMON_OFFSETS_LIST(FIELD, ARRAY, SIZEOF, PAYLOAD_SIZEOF, RANGE,       \
                            CONSTANT)                                          \
  ARRAY(ObjectPool, element_offset)                                            \
  CONSTANT(Array, kMaxElements)                                                \
  CONSTANT(Array, kMaxNewSpaceElements)                                        \
  CONSTANT(Instructions, kMonomorphicEntryOffsetJIT)                           \
  CONSTANT(Instructions, kPolymorphicEntryOffsetJIT)                           \
  CONSTANT(Instructions, kMonomorphicEntryOffsetAOT)                           \
  CONSTANT(Instructions, kPolymorphicEntryOffsetAOT)                           \
  CONSTANT(Instructions, kBarePayloadAlignment)                                \
  CONSTANT(Instructions, kNonBarePayloadAlignment)                             \
  CONSTANT(OldPage, kBytesPerCardLog2)                                         \
  CONSTANT(NativeEntry, kNumCallWrapperArguments)                              \
  CONSTANT(String, kMaxElements)                                               \
  CONSTANT(SubtypeTestCache, kFunctionTypeArguments)                           \
  CONSTANT(SubtypeTestCache, kInstanceClassIdOrFunction)                       \
  CONSTANT(SubtypeTestCache, kDestinationType)                                 \
  CONSTANT(SubtypeTestCache, kInstanceDelayedFunctionTypeArguments)            \
  CONSTANT(SubtypeTestCache, kInstanceParentFunctionTypeArguments)             \
  CONSTANT(SubtypeTestCache, kInstanceTypeArguments)                           \
  CONSTANT(SubtypeTestCache, kInstantiatorTypeArguments)                       \
  CONSTANT(SubtypeTestCache, kTestEntryLength)                                 \
  CONSTANT(SubtypeTestCache, kTestResult)                                      \
  CONSTANT(TypeArguments, kMaxElements)                                        \
  FIELD(AbstractType, type_test_stub_entry_point_offset)                       \
  FIELD(ArgumentsDescriptor, count_offset)                                     \
  FIELD(ArgumentsDescriptor, size_offset)                                      \
  FIELD(ArgumentsDescriptor, first_named_entry_offset)                         \
  FIELD(ArgumentsDescriptor, named_entry_size)                                 \
  FIELD(ArgumentsDescriptor, name_offset)                                      \
  FIELD(ArgumentsDescriptor, position_offset)                                  \
  FIELD(ArgumentsDescriptor, positional_count_offset)                          \
  FIELD(ArgumentsDescriptor, type_args_len_offset)                             \
  FIELD(Array, data_offset)                                                    \
  FIELD(Array, length_offset)                                                  \
  FIELD(Array, tags_offset)                                                    \
  FIELD(Array, type_arguments_offset)                                          \
  FIELD(Class, declaration_type_offset)                                        \
  FIELD(Class, num_type_arguments_offset)                                      \
  FIELD(Class, super_type_offset)                                              \
  FIELD(Class, host_type_arguments_field_offset_in_words_offset)               \
  NOT_IN_PRODUCT(FIELD(SharedClassTable, class_heap_stats_table_offset))       \
  FIELD(Closure, context_offset)                                               \
  FIELD(Closure, delayed_type_arguments_offset)                                \
  FIELD(Closure, function_offset)                                              \
  FIELD(Closure, function_type_arguments_offset)                               \
  FIELD(Closure, hash_offset)                                                  \
  FIELD(Closure, instantiator_type_arguments_offset)                           \
  FIELD(ClosureData, default_type_arguments_offset)                            \
  FIELD(ClosureData, default_type_arguments_info_offset)                       \
  FIELD(Code, object_pool_offset)                                              \
  FIELD(Code, saved_instructions_offset)                                       \
  FIELD(Code, owner_offset)                                                    \
  FIELD(Context, num_variables_offset)                                         \
  FIELD(Context, parent_offset)                                                \
  FIELD(Double, value_offset)                                                  \
  FIELD(ExternalOneByteString, external_data_offset)                           \
  FIELD(ExternalTwoByteString, external_data_offset)                           \
  FIELD(Float32x4, value_offset)                                               \
  FIELD(Float64x2, value_offset)                                               \
  FIELD(Field, initializer_function_offset)                                    \
  FIELD(Field, host_offset_or_field_id_offset)                                 \
  FIELD(Field, guarded_cid_offset)                                             \
  FIELD(Field, guarded_list_length_in_object_offset_offset)                    \
  FIELD(Field, guarded_list_length_offset)                                     \
  FIELD(Field, is_nullable_offset)                                             \
  FIELD(Field, kind_bits_offset)                                               \
  FIELD(Function, code_offset)                                                 \
  FIELD(Function, data_offset)                                                 \
  RANGE(Function, entry_point_offset, CodeEntryKind, CodeEntryKind::kNormal,   \
        CodeEntryKind::kUnchecked, [](CodeEntryKind value) { return true; })   \
  FIELD(Function, kind_tag_offset)                                             \
  FIELD(Function, packed_fields_offset)                                        \
  FIELD(Function, parameter_names_offset)                                      \
  FIELD(Function, parameter_types_offset)                                      \
  FIELD(Function, type_parameters_offset)                                      \
  FIELD(FutureOr, type_arguments_offset)                                       \
  FIELD(GrowableObjectArray, data_offset)                                      \
  FIELD(GrowableObjectArray, length_offset)                                    \
  FIELD(GrowableObjectArray, type_arguments_offset)                            \
  FIELD(OldPage, card_table_offset)                                            \
  FIELD(CallSiteData, arguments_descriptor_offset)                             \
  FIELD(ICData, NumArgsTestedMask)                                             \
  FIELD(ICData, NumArgsTestedShift)                                            \
  FIELD(ICData, entries_offset)                                                \
  FIELD(ICData, owner_offset)                                                  \
  FIELD(ICData, state_bits_offset)                                             \
  FIELD(Int32x4, value_offset)                                                 \
  FIELD(Isolate, shared_class_table_offset)                                    \
  FIELD(Isolate, cached_class_table_table_offset)                              \
  FIELD(Isolate, current_tag_offset)                                           \
  FIELD(Isolate, default_tag_offset)                                           \
  FIELD(Isolate, ic_miss_code_offset)                                          \
  FIELD(Isolate, cached_object_store_offset)                                   \
  NOT_IN_PRODUCT(FIELD(Isolate, single_step_offset))                           \
  FIELD(Isolate, user_tag_offset)                                              \
  FIELD(LinkedHashMap, data_offset)                                            \
  FIELD(LinkedHashMap, deleted_keys_offset)                                    \
  FIELD(LinkedHashMap, hash_mask_offset)                                       \
  FIELD(LinkedHashMap, index_offset)                                           \
  FIELD(LinkedHashMap, type_arguments_offset)                                  \
  FIELD(LinkedHashMap, used_data_offset)                                       \
  FIELD(LocalHandle, raw_offset)                                               \
  FIELD(MarkingStackBlock, pointers_offset)                                    \
  FIELD(MarkingStackBlock, top_offset)                                         \
  FIELD(MegamorphicCache, buckets_offset)                                      \
  FIELD(MegamorphicCache, mask_offset)                                         \
  FIELD(Mint, value_offset)                                                    \
  FIELD(NativeArguments, argc_tag_offset)                                      \
  FIELD(NativeArguments, argv_offset)                                          \
  FIELD(NativeArguments, retval_offset)                                        \
  FIELD(NativeArguments, thread_offset)                                        \
  FIELD(ObjectStore, double_type_offset)                                       \
  FIELD(ObjectStore, int_type_offset)                                          \
  FIELD(ObjectStore, string_type_offset)                                       \
  FIELD(OneByteString, data_offset)                                            \
  FIELD(PointerBase, data_field_offset)                                        \
  FIELD(Pointer, type_arguments_offset)                                        \
  FIELD(SingleTargetCache, entry_point_offset)                                 \
  FIELD(SingleTargetCache, lower_limit_offset)                                 \
  FIELD(SingleTargetCache, target_offset)                                      \
  FIELD(SingleTargetCache, upper_limit_offset)                                 \
  FIELD(StoreBufferBlock, pointers_offset)                                     \
  FIELD(StoreBufferBlock, top_offset)                                          \
  FIELD(String, hash_offset)                                                   \
  FIELD(String, length_offset)                                                 \
  FIELD(SubtypeTestCache, cache_offset)                                        \
  FIELD(Thread, AllocateArray_entry_point_offset)                              \
  FIELD(Thread, active_exception_offset)                                       \
  FIELD(Thread, active_stacktrace_offset)                                      \
  FIELD(Thread, array_write_barrier_code_offset)                               \
  FIELD(Thread, array_write_barrier_entry_point_offset)                        \
  FIELD(Thread, allocate_mint_with_fpu_regs_entry_point_offset)                \
  FIELD(Thread, allocate_mint_with_fpu_regs_stub_offset)                       \
  FIELD(Thread, allocate_mint_without_fpu_regs_entry_point_offset)             \
  FIELD(Thread, allocate_mint_without_fpu_regs_stub_offset)                    \
  FIELD(Thread, allocate_object_entry_point_offset)                            \
  FIELD(Thread, allocate_object_stub_offset)                                   \
  FIELD(Thread, allocate_object_parameterized_entry_point_offset)              \
  FIELD(Thread, allocate_object_parameterized_stub_offset)                     \
  FIELD(Thread, allocate_object_slow_entry_point_offset)                       \
  FIELD(Thread, allocate_object_slow_stub_offset)                              \
  FIELD(Thread, api_top_scope_offset)                                          \
  FIELD(Thread, auto_scope_native_wrapper_entry_point_offset)                  \
  FIELD(Thread, bool_false_offset)                                             \
  FIELD(Thread, bool_true_offset)                                              \
  FIELD(Thread, bootstrap_native_wrapper_entry_point_offset)                   \
  FIELD(Thread, call_to_runtime_entry_point_offset)                            \
  FIELD(Thread, call_to_runtime_stub_offset)                                   \
  FIELD(Thread, dart_stream_offset)                                            \
  FIELD(Thread, dispatch_table_array_offset)                                   \
  FIELD(Thread, optimize_entry_offset)                                         \
  FIELD(Thread, optimize_stub_offset)                                          \
  FIELD(Thread, deoptimize_entry_offset)                                       \
  FIELD(Thread, deoptimize_stub_offset)                                        \
  FIELD(Thread, double_abs_address_offset)                                     \
  FIELD(Thread, double_negate_address_offset)                                  \
  FIELD(Thread, end_offset)                                                    \
  FIELD(Thread, enter_safepoint_stub_offset)                                   \
  FIELD(Thread, execution_state_offset)                                        \
  FIELD(Thread, exit_safepoint_stub_offset)                                    \
  FIELD(Thread, call_native_through_safepoint_stub_offset)                     \
  FIELD(Thread, call_native_through_safepoint_entry_point_offset)              \
  FIELD(Thread, fix_allocation_stub_code_offset)                               \
  FIELD(Thread, fix_callers_target_code_offset)                                \
  FIELD(Thread, float_absolute_address_offset)                                 \
  FIELD(Thread, float_negate_address_offset)                                   \
  FIELD(Thread, float_not_address_offset)                                      \
  FIELD(Thread, float_zerow_address_offset)                                    \
  FIELD(Thread, global_object_pool_offset)                                     \
  FIELD(Thread, invoke_dart_code_stub_offset)                                  \
  FIELD(Thread, exit_through_ffi_offset)                                       \
  FIELD(Thread, isolate_offset)                                                \
  FIELD(Thread, field_table_values_offset)                                     \
  FIELD(Thread, lazy_deopt_from_return_stub_offset)                            \
  FIELD(Thread, lazy_deopt_from_throw_stub_offset)                             \
  FIELD(Thread, lazy_specialize_type_test_stub_offset)                         \
  FIELD(Thread, marking_stack_block_offset)                                    \
  FIELD(Thread, megamorphic_call_checked_entry_offset)                         \
  FIELD(Thread, switchable_call_miss_entry_offset)                             \
  FIELD(Thread, switchable_call_miss_stub_offset)                              \
  FIELD(Thread, no_scope_native_wrapper_entry_point_offset)                    \
  FIELD(Thread, late_initialization_error_shared_with_fpu_regs_stub_offset)    \
  FIELD(Thread, late_initialization_error_shared_without_fpu_regs_stub_offset) \
  FIELD(Thread, null_error_shared_with_fpu_regs_stub_offset)                   \
  FIELD(Thread, null_error_shared_without_fpu_regs_stub_offset)                \
  FIELD(Thread, null_arg_error_shared_with_fpu_regs_stub_offset)               \
  FIELD(Thread, null_arg_error_shared_without_fpu_regs_stub_offset)            \
  FIELD(Thread, null_cast_error_shared_with_fpu_regs_stub_offset)              \
  FIELD(Thread, null_cast_error_shared_without_fpu_regs_stub_offset)           \
  FIELD(Thread, range_error_shared_with_fpu_regs_stub_offset)                  \
  FIELD(Thread, range_error_shared_without_fpu_regs_stub_offset)               \
                                                                               \
  FIELD(Thread, object_null_offset)                                            \
  FIELD(Thread, predefined_symbols_address_offset)                             \
  FIELD(Thread, resume_pc_offset)                                              \
  FIELD(Thread, saved_shadow_call_stack_offset)                                \
  FIELD(Thread, safepoint_state_offset)                                        \
  FIELD(Thread, slow_type_test_stub_offset)                                    \
  FIELD(Thread, slow_type_test_entry_point_offset)                             \
  FIELD(Thread, stack_limit_offset)                                            \
  FIELD(Thread, saved_stack_limit_offset)                                      \
  FIELD(Thread, stack_overflow_flags_offset)                                   \
  FIELD(Thread, stack_overflow_shared_with_fpu_regs_entry_point_offset)        \
  FIELD(Thread, stack_overflow_shared_with_fpu_regs_stub_offset)               \
  FIELD(Thread, stack_overflow_shared_without_fpu_regs_entry_point_offset)     \
                                                                               \
  FIELD(Thread, stack_overflow_shared_without_fpu_regs_stub_offset)            \
  FIELD(Thread, store_buffer_block_offset)                                     \
  FIELD(Thread, top_exit_frame_info_offset)                                    \
  FIELD(Thread, top_offset)                                                    \
  FIELD(Thread, top_resource_offset)                                           \
  FIELD(Thread, unboxed_int64_runtime_arg_offset)                              \
  FIELD(Thread, vm_tag_offset)                                                 \
  FIELD(Thread, write_barrier_code_offset)                                     \
  FIELD(Thread, write_barrier_entry_point_offset)                              \
  FIELD(Thread, write_barrier_mask_offset)                                     \
  FIELD(Thread, callback_code_offset)                                          \
  FIELD(Thread, callback_stack_return_offset)                                  \
  FIELD(TimelineStream, enabled_offset)                                        \
  FIELD(TwoByteString, data_offset)                                            \
  FIELD(Type, arguments_offset)                                                \
  FIELD(Type, hash_offset)                                                     \
  FIELD(Type, signature_offset)                                                \
  FIELD(Type, type_class_id_offset)                                            \
  FIELD(Type, type_state_offset)                                               \
  FIELD(Type, nullability_offset)                                              \
  FIELD(TypeParameter, parameterized_class_id_offset)                          \
  FIELD(TypeParameter, index_offset)                                           \
  FIELD(TypeParameter, nullability_offset)                                     \
  FIELD(TypeArguments, instantiations_offset)                                  \
  FIELD(TypeArguments, length_offset)                                          \
  FIELD(TypeArguments, nullability_offset)                                     \
  FIELD(TypeArguments, types_offset)                                           \
  FIELD(TypeParameter, bound_offset)                                           \
  FIELD(TypeParameter, flags_offset)                                           \
  FIELD(TypeParameter, name_offset)                                            \
  FIELD(TypeRef, type_offset)                                                  \
  FIELD(TypedDataBase, length_offset)                                          \
  FIELD(TypedDataView, data_offset)                                            \
  FIELD(TypedDataView, offset_in_bytes_offset)                                 \
  FIELD(TypedData, data_offset)                                                \
  FIELD(UnhandledException, exception_offset)                                  \
  FIELD(UnhandledException, stacktrace_offset)                                 \
  FIELD(UserTag, tag_offset)                                                   \
  FIELD(MonomorphicSmiableCall, expected_cid_offset)                           \
  FIELD(MonomorphicSmiableCall, entrypoint_offset)                             \
  FIELD(MonomorphicSmiableCall, target_offset)                                 \
  FIELD(WeakProperty, key_offset)                                              \
  FIELD(WeakProperty, value_offset)                                            \
  ARRAY(Array, element_offset)                                                 \
  ARRAY(TypeArguments, type_at_offset)                                         \
  NOT_IN_PRODUCT(ARRAY(ClassTable, ClassOffsetFor))                            \
  RANGE(Code, entry_point_offset, CodeEntryKind, CodeEntryKind::kNormal,       \
        CodeEntryKind::kMonomorphicUnchecked,                                  \
        [](CodeEntryKind value) { return true; })                              \
  ONLY_IN_ARM_ARM64_X64(RANGE(                                                 \
      Thread, write_barrier_wrappers_thread_offset, Register, 0,               \
      kNumberOfCpuRegisters - 1,                                               \
      [](Register reg) { return (kDartAvailableCpuRegs & (1 << reg)) != 0; })) \
                                                                               \
  SIZEOF(ApiError, InstanceSize, ApiErrorLayout)                               \
  SIZEOF(Array, InstanceSize, ArrayLayout)                                     \
  SIZEOF(Array, header_size, ArrayLayout)                                      \
  SIZEOF(Bool, InstanceSize, BoolLayout)                                       \
  SIZEOF(Capability, InstanceSize, CapabilityLayout)                           \
  SIZEOF(Class, InstanceSize, ClassLayout)                                     \
  SIZEOF(Closure, InstanceSize, ClosureLayout)                                 \
  SIZEOF(ClosureData, InstanceSize, ClosureDataLayout)                         \
  SIZEOF(Code, InstanceSize, CodeLayout)                                       \
  SIZEOF(CodeSourceMap, HeaderSize, CodeSourceMapLayout)                       \
  SIZEOF(CompressedStackMaps, HeaderSize, CompressedStackMapsLayout)           \
  SIZEOF(Context, InstanceSize, ContextLayout)                                 \
  SIZEOF(Context, header_size, ContextLayout)                                  \
  SIZEOF(ContextScope, InstanceSize, ContextScopeLayout)                       \
  SIZEOF(Double, InstanceSize, DoubleLayout)                                   \
  SIZEOF(DynamicLibrary, InstanceSize, DynamicLibraryLayout)                   \
  SIZEOF(ExceptionHandlers, InstanceSize, ExceptionHandlersLayout)             \
  SIZEOF(ExternalOneByteString, InstanceSize, ExternalOneByteStringLayout)     \
  SIZEOF(ExternalTwoByteString, InstanceSize, ExternalTwoByteStringLayout)     \
  SIZEOF(ExternalTypedData, InstanceSize, ExternalTypedDataLayout)             \
  SIZEOF(FfiTrampolineData, InstanceSize, FfiTrampolineDataLayout)             \
  SIZEOF(Field, InstanceSize, FieldLayout)                                     \
  SIZEOF(Float32x4, InstanceSize, Float32x4Layout)                             \
  SIZEOF(Float64x2, InstanceSize, Float64x2Layout)                             \
  SIZEOF(Function, InstanceSize, FunctionLayout)                               \
  SIZEOF(FutureOr, InstanceSize, FutureOrLayout)                               \
  SIZEOF(GrowableObjectArray, InstanceSize, GrowableObjectArrayLayout)         \
  SIZEOF(ICData, InstanceSize, ICDataLayout)                                   \
  SIZEOF(Instance, InstanceSize, InstanceLayout)                               \
  SIZEOF(Instructions, UnalignedHeaderSize, InstructionsLayout)                \
  SIZEOF(InstructionsSection, UnalignedHeaderSize, InstructionsSectionLayout)  \
  SIZEOF(Int32x4, InstanceSize, Int32x4Layout)                                 \
  SIZEOF(Integer, InstanceSize, IntegerLayout)                                 \
  SIZEOF(KernelProgramInfo, InstanceSize, KernelProgramInfoLayout)             \
  SIZEOF(LanguageError, InstanceSize, LanguageErrorLayout)                     \
  SIZEOF(Library, InstanceSize, LibraryLayout)                                 \
  SIZEOF(LibraryPrefix, InstanceSize, LibraryPrefixLayout)                     \
  SIZEOF(LinkedHashMap, InstanceSize, LinkedHashMapLayout)                     \
  SIZEOF(LocalVarDescriptors, InstanceSize, LocalVarDescriptorsLayout)         \
  SIZEOF(MegamorphicCache, InstanceSize, MegamorphicCacheLayout)               \
  SIZEOF(Mint, InstanceSize, MintLayout)                                       \
  SIZEOF(MirrorReference, InstanceSize, MirrorReferenceLayout)                 \
  SIZEOF(MonomorphicSmiableCall, InstanceSize, MonomorphicSmiableCallLayout)   \
  SIZEOF(Namespace, InstanceSize, NamespaceLayout)                             \
  SIZEOF(NativeArguments, StructSize, NativeArguments)                         \
  SIZEOF(Number, InstanceSize, NumberLayout)                                   \
  SIZEOF(Object, InstanceSize, ObjectLayout)                                   \
  SIZEOF(ObjectPool, InstanceSize, ObjectPoolLayout)                           \
  SIZEOF(OneByteString, InstanceSize, OneByteStringLayout)                     \
  SIZEOF(PatchClass, InstanceSize, PatchClassLayout)                           \
  SIZEOF(PcDescriptors, HeaderSize, PcDescriptorsLayout)                       \
  SIZEOF(Pointer, InstanceSize, PointerLayout)                                 \
  SIZEOF(ReceivePort, InstanceSize, ReceivePortLayout)                         \
  SIZEOF(RegExp, InstanceSize, RegExpLayout)                                   \
  SIZEOF(Script, InstanceSize, ScriptLayout)                                   \
  SIZEOF(SendPort, InstanceSize, SendPortLayout)                               \
  SIZEOF(SignatureData, InstanceSize, SignatureDataLayout)                     \
  SIZEOF(SingleTargetCache, InstanceSize, SingleTargetCacheLayout)             \
  SIZEOF(Smi, InstanceSize, SmiLayout)                                         \
  SIZEOF(StackTrace, InstanceSize, StackTraceLayout)                           \
  SIZEOF(String, InstanceSize, StringLayout)                                   \
  SIZEOF(SubtypeTestCache, InstanceSize, SubtypeTestCacheLayout)               \
  SIZEOF(LoadingUnit, InstanceSize, LoadingUnitLayout)                         \
  SIZEOF(TransferableTypedData, InstanceSize, TransferableTypedDataLayout)     \
  SIZEOF(TwoByteString, InstanceSize, TwoByteStringLayout)                     \
  SIZEOF(Type, InstanceSize, TypeLayout)                                       \
  SIZEOF(TypeArguments, InstanceSize, TypeArgumentsLayout)                     \
  SIZEOF(TypeParameter, InstanceSize, TypeParameterLayout)                     \
  SIZEOF(TypeRef, InstanceSize, TypeRefLayout)                                 \
  SIZEOF(TypedData, InstanceSize, TypedDataLayout)                             \
  SIZEOF(TypedDataBase, InstanceSize, TypedDataBaseLayout)                     \
  SIZEOF(TypedDataView, InstanceSize, TypedDataViewLayout)                     \
  SIZEOF(UnhandledException, InstanceSize, UnhandledExceptionLayout)           \
  SIZEOF(UnlinkedCall, InstanceSize, UnlinkedCallLayout)                       \
  SIZEOF(UnwindError, InstanceSize, UnwindErrorLayout)                         \
  SIZEOF(UserTag, InstanceSize, UserTagLayout)                                 \
  SIZEOF(WeakProperty, InstanceSize, WeakPropertyLayout)                       \
  SIZEOF(WeakSerializationReference, InstanceSize,                             \
         WeakSerializationReferenceLayout)                                     \
  PAYLOAD_SIZEOF(CodeSourceMap, InstanceSize, HeaderSize)                      \
  PAYLOAD_SIZEOF(CompressedStackMaps, InstanceSize, HeaderSize)                \
  PAYLOAD_SIZEOF(InstructionsSection, InstanceSize, HeaderSize)                \
  PAYLOAD_SIZEOF(PcDescriptors, InstanceSize, HeaderSize)

#define JIT_OFFSETS_LIST(FIELD, ARRAY, SIZEOF, PAYLOAD_SIZEOF, RANGE,          \
                         CONSTANT)                                             \
  FIELD(Function, usage_counter_offset)                                        \
  FIELD(ICData, receivers_static_type_offset)

#endif  // RUNTIME_VM_COMPILER_RUNTIME_OFFSETS_LIST_H_
