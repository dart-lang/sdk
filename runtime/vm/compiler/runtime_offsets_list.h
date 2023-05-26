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
// ARRAY_SIZEOF(Class, Name, ElementOffset) Instance size for an array object.
//     Defines Class::Name(intptr_t length) and uses
//     Class::ElementOffset(length) to calculate size of the instance. Also
//     defines Class::Name() (with no length argument) to be 0.
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
// AOT_OFFSETS_LIST is for declarations that are only valid in AOT mode.
// A declaration that is not valid in product mode can be wrapped with
// NOT_IN_PRODUCT().
//
// TODO(dartbug.com/43646): Add DART_PRECOMPILER as another axis.

#if defined(DART_COMPRESSED_POINTERS)
#define COMPRESSED_ONLY(x) x
#else
#define COMPRESSED_ONLY(x)
#endif

#define COMMON_OFFSETS_LIST(FIELD, ARRAY, SIZEOF, ARRAY_SIZEOF,                \
                            PAYLOAD_SIZEOF, RANGE, CONSTANT)                   \
  ARRAY(Array, element_offset)                                                 \
  NOT_IN_PRODUCT(ARRAY(ClassTable, AllocationTracingStateSlotOffsetFor))       \
  ARRAY(Code, element_offset)                                                  \
  ARRAY(Context, variable_offset)                                              \
  ARRAY(ContextScope, element_offset)                                          \
  ARRAY(ExceptionHandlers, element_offset)                                     \
  ARRAY(ObjectPool, element_offset)                                            \
  ARRAY(OneByteString, element_offset)                                         \
  ARRAY(Record, field_offset)                                                  \
  ARRAY(TypeArguments, type_at_offset)                                         \
  ARRAY(TwoByteString, element_offset)                                         \
  ARRAY(WeakArray, element_offset)                                             \
  ARRAY_SIZEOF(Array, InstanceSize, element_offset)                            \
  ARRAY_SIZEOF(Code, InstanceSize, element_offset)                             \
  ARRAY_SIZEOF(Context, InstanceSize, variable_offset)                         \
  ARRAY_SIZEOF(ContextScope, InstanceSize, element_offset)                     \
  ARRAY_SIZEOF(ExceptionHandlers, InstanceSize, element_offset)                \
  ARRAY_SIZEOF(ObjectPool, InstanceSize, element_offset)                       \
  ARRAY_SIZEOF(OneByteString, InstanceSize, element_offset)                    \
  ARRAY_SIZEOF(Record, InstanceSize, field_offset)                             \
  ARRAY_SIZEOF(TypeArguments, InstanceSize, type_at_offset)                    \
  ARRAY_SIZEOF(TwoByteString, InstanceSize, element_offset)                    \
  ARRAY_SIZEOF(WeakArray, InstanceSize, element_offset)                        \
  CONSTANT(Array, kMaxElements)                                                \
  CONSTANT(Array, kMaxNewSpaceElements)                                        \
  CONSTANT(Context, kMaxElements)                                              \
  CONSTANT(Instructions, kMonomorphicEntryOffsetJIT)                           \
  CONSTANT(Instructions, kPolymorphicEntryOffsetJIT)                           \
  CONSTANT(Instructions, kMonomorphicEntryOffsetAOT)                           \
  CONSTANT(Instructions, kPolymorphicEntryOffsetAOT)                           \
  CONSTANT(Instructions, kBarePayloadAlignment)                                \
  CONSTANT(Instructions, kNonBarePayloadAlignment)                             \
  CONSTANT(NativeEntry, kNumCallWrapperArguments)                              \
  CONSTANT(Page, kBytesPerCardLog2)                                            \
  CONSTANT(Record, kMaxElements)                                               \
  CONSTANT(RecordShape, kFieldNamesIndexMask)                                  \
  CONSTANT(RecordShape, kFieldNamesIndexShift)                                 \
  CONSTANT(RecordShape, kMaxFieldNamesIndex)                                   \
  CONSTANT(RecordShape, kMaxNumFields)                                         \
  CONSTANT(RecordShape, kNumFieldsMask)                                        \
  CONSTANT(String, kMaxElements)                                               \
  CONSTANT(SubtypeTestCache, kFunctionTypeArguments)                           \
  CONSTANT(SubtypeTestCache, kInstanceCidOrSignature)                          \
  CONSTANT(SubtypeTestCache, kDestinationType)                                 \
  CONSTANT(SubtypeTestCache, kInstanceDelayedFunctionTypeArguments)            \
  CONSTANT(SubtypeTestCache, kInstanceParentFunctionTypeArguments)             \
  CONSTANT(SubtypeTestCache, kInstanceTypeArguments)                           \
  CONSTANT(SubtypeTestCache, kInstantiatorTypeArguments)                       \
  CONSTANT(SubtypeTestCache, kTestEntryLength)                                 \
  CONSTANT(SubtypeTestCache, kTestResult)                                      \
  CONSTANT(TypeArguments, kMaxElements)                                        \
  FIELD(AbstractType, flags_offset)                                            \
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
  NOT_IN_PRODUCT(FIELD(ClassTable, allocation_tracing_state_table_offset))     \
  FIELD(Closure, context_offset)                                               \
  FIELD(Closure, delayed_type_arguments_offset)                                \
  FIELD(Closure, function_offset)                                              \
  FIELD(Closure, function_type_arguments_offset)                               \
  FIELD(Closure, hash_offset)                                                  \
  FIELD(Closure, instantiator_type_arguments_offset)                           \
  FIELD(ClosureData, default_type_arguments_kind_offset)                       \
  FIELD(Code, instructions_offset)                                             \
  FIELD(Code, object_pool_offset)                                              \
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
  FIELD(Function, signature_offset)                                            \
  FIELD(FutureOr, type_arguments_offset)                                       \
  FIELD(GrowableObjectArray, data_offset)                                      \
  FIELD(GrowableObjectArray, length_offset)                                    \
  FIELD(GrowableObjectArray, type_arguments_offset)                            \
  FIELD(Page, card_table_offset)                                               \
  FIELD(CallSiteData, arguments_descriptor_offset)                             \
  FIELD(ICData, NumArgsTestedMask)                                             \
  FIELD(ICData, NumArgsTestedShift)                                            \
  FIELD(ICData, entries_offset)                                                \
  FIELD(ICData, owner_offset)                                                  \
  FIELD(ICData, state_bits_offset)                                             \
  FIELD(Int32x4, value_offset)                                                 \
  FIELD(Isolate, current_tag_offset)                                           \
  FIELD(Isolate, default_tag_offset)                                           \
  FIELD(Isolate, finalizers_offset)                                            \
  NOT_IN_PRODUCT(FIELD(Isolate, has_resumption_breakpoints_offset))            \
  FIELD(Isolate, ic_miss_code_offset)                                          \
  FIELD(IsolateGroup, object_store_offset)                                     \
  FIELD(IsolateGroup, class_table_offset)                                      \
  FIELD(IsolateGroup, cached_class_table_table_offset)                         \
  NOT_IN_PRODUCT(FIELD(Isolate, single_step_offset))                           \
  FIELD(Isolate, user_tag_offset)                                              \
  FIELD(LinkedHashBase, data_offset)                                           \
  FIELD(ImmutableLinkedHashBase, data_offset)                                  \
  FIELD(LinkedHashBase, deleted_keys_offset)                                   \
  FIELD(LinkedHashBase, hash_mask_offset)                                      \
  FIELD(LinkedHashBase, index_offset)                                          \
  FIELD(LinkedHashBase, type_arguments_offset)                                 \
  FIELD(LinkedHashBase, used_data_offset)                                      \
  FIELD(LocalHandle, ptr_offset)                                               \
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
  FIELD(ObjectStore, record_field_names_offset)                                \
  FIELD(ObjectStore, string_type_offset)                                       \
  FIELD(ObjectStore, type_type_offset)                                         \
  FIELD(ObjectStore, ffi_callback_code_offset)                                 \
  FIELD(ObjectStore, suspend_state_await_offset)                               \
  FIELD(ObjectStore, suspend_state_await_with_type_check_offset)               \
  FIELD(ObjectStore, suspend_state_handle_exception_offset)                    \
  FIELD(ObjectStore, suspend_state_init_async_offset)                          \
  FIELD(ObjectStore, suspend_state_init_async_star_offset)                     \
  FIELD(ObjectStore, suspend_state_init_sync_star_offset)                      \
  FIELD(ObjectStore, suspend_state_return_async_offset)                        \
  FIELD(ObjectStore, suspend_state_return_async_not_future_offset)             \
  FIELD(ObjectStore, suspend_state_return_async_star_offset)                   \
  FIELD(ObjectStore, suspend_state_suspend_sync_star_at_start_offset)          \
  FIELD(ObjectStore, suspend_state_yield_async_star_offset)                    \
  FIELD(OneByteString, data_offset)                                            \
  FIELD(PointerBase, data_offset)                                              \
  FIELD(Pointer, type_arguments_offset)                                        \
  FIELD(ReceivePort, send_port_offset)                                         \
  FIELD(ReceivePort, handler_offset)                                           \
  FIELD(Record, shape_offset)                                                  \
  FIELD(SingleTargetCache, entry_point_offset)                                 \
  FIELD(SingleTargetCache, lower_limit_offset)                                 \
  FIELD(SingleTargetCache, target_offset)                                      \
  FIELD(SingleTargetCache, upper_limit_offset)                                 \
  FIELD(StoreBufferBlock, pointers_offset)                                     \
  FIELD(StoreBufferBlock, top_offset)                                          \
  FIELD(StreamInfo, enabled_offset)                                            \
  FIELD(String, hash_offset)                                                   \
  FIELD(String, length_offset)                                                 \
  FIELD(SubtypeTestCache, cache_offset)                                        \
  FIELD(SuspendState, FrameSizeGrowthGap)                                      \
  FIELD(SuspendState, error_callback_offset)                                   \
  FIELD(SuspendState, frame_size_offset)                                       \
  FIELD(SuspendState, function_data_offset)                                    \
  FIELD(SuspendState, payload_offset)                                          \
  FIELD(SuspendState, pc_offset)                                               \
  FIELD(SuspendState, then_callback_offset)                                    \
  FIELD(Thread, AllocateArray_entry_point_offset)                              \
  FIELD(Thread, active_exception_offset)                                       \
  FIELD(Thread, active_stacktrace_offset)                                      \
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
  FIELD(Thread, async_exception_handler_stub_offset)                           \
  FIELD(Thread, auto_scope_native_wrapper_entry_point_offset)                  \
  FIELD(Thread, bool_false_offset)                                             \
  FIELD(Thread, bool_true_offset)                                              \
  FIELD(Thread, bootstrap_native_wrapper_entry_point_offset)                   \
  FIELD(Thread, call_to_runtime_entry_point_offset)                            \
  FIELD(Thread, call_to_runtime_stub_offset)                                   \
  FIELD(Thread, dart_stream_offset)                                            \
  FIELD(Thread, dispatch_table_array_offset)                                   \
  FIELD(Thread, double_truncate_round_supported_offset)                        \
  FIELD(Thread, service_extension_stream_offset)                               \
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
  FIELD(Thread, exit_safepoint_ignore_unwind_in_progress_stub_offset)          \
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
  FIELD(Thread, isolate_group_offset)                                          \
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
  FIELD(Thread, write_error_shared_with_fpu_regs_stub_offset)                  \
  FIELD(Thread, write_error_shared_without_fpu_regs_stub_offset)               \
  FIELD(Thread, resume_stub_offset)                                            \
  FIELD(Thread, return_async_not_future_stub_offset)                           \
  FIELD(Thread, return_async_star_stub_offset)                                 \
  FIELD(Thread, return_async_stub_offset)                                      \
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
  FIELD(Thread, suspend_state_await_entry_point_offset)                        \
  FIELD(Thread, suspend_state_await_with_type_check_entry_point_offset)        \
  FIELD(Thread, suspend_state_init_async_entry_point_offset)                   \
  FIELD(Thread, suspend_state_return_async_entry_point_offset)                 \
  FIELD(Thread, suspend_state_return_async_not_future_entry_point_offset)      \
  FIELD(Thread, suspend_state_init_async_star_entry_point_offset)              \
  FIELD(Thread, suspend_state_yield_async_star_entry_point_offset)             \
  FIELD(Thread, suspend_state_return_async_star_entry_point_offset)            \
  FIELD(Thread, suspend_state_init_sync_star_entry_point_offset)               \
  FIELD(Thread, suspend_state_suspend_sync_star_at_start_entry_point_offset)   \
  FIELD(Thread, suspend_state_handle_exception_entry_point_offset)             \
  FIELD(Thread, top_exit_frame_info_offset)                                    \
  FIELD(Thread, top_offset)                                                    \
  FIELD(Thread, top_resource_offset)                                           \
  FIELD(Thread, unboxed_runtime_arg_offset)                                    \
  FIELD(Thread, vm_tag_offset)                                                 \
  FIELD(Thread, write_barrier_entry_point_offset)                              \
  FIELD(Thread, write_barrier_mask_offset)                                     \
  COMPRESSED_ONLY(FIELD(Thread, heap_base_offset))                             \
  FIELD(Thread, next_task_id_offset)                                           \
  FIELD(Thread, random_offset)                                                 \
  FIELD(Thread, jump_to_frame_entry_point_offset)                              \
  FIELD(Thread, tsan_utils_offset)                                             \
  FIELD(TsanUtils, setjmp_function_offset)                                     \
  FIELD(TsanUtils, setjmp_buffer_offset)                                       \
  FIELD(TsanUtils, exception_pc_offset)                                        \
  FIELD(TsanUtils, exception_sp_offset)                                        \
  FIELD(TsanUtils, exception_fp_offset)                                        \
  FIELD(TimelineStream, enabled_offset)                                        \
  FIELD(TwoByteString, data_offset)                                            \
  FIELD(Type, arguments_offset)                                                \
  FIELD(Type, hash_offset)                                                     \
  FIELD(Finalizer, type_arguments_offset)                                      \
  FIELD(Finalizer, callback_offset)                                            \
  FIELD(FinalizerBase, all_entries_offset)                                     \
  FIELD(FinalizerBase, detachments_offset)                                     \
  FIELD(FinalizerBase, entries_collected_offset)                               \
  FIELD(FinalizerBase, isolate_offset)                                         \
  FIELD(FinalizerEntry, detach_offset)                                         \
  FIELD(FinalizerEntry, external_size_offset)                                  \
  FIELD(FinalizerEntry, finalizer_offset)                                      \
  FIELD(FinalizerEntry, next_offset)                                           \
  FIELD(FinalizerEntry, token_offset)                                          \
  FIELD(FinalizerEntry, value_offset)                                          \
  FIELD(NativeFinalizer, callback_offset)                                      \
  FIELD(FunctionType, hash_offset)                                             \
  FIELD(FunctionType, named_parameter_names_offset)                            \
  FIELD(FunctionType, packed_parameter_counts_offset)                          \
  FIELD(FunctionType, packed_type_parameter_counts_offset)                     \
  FIELD(FunctionType, parameter_types_offset)                                  \
  FIELD(FunctionType, type_parameters_offset)                                  \
  FIELD(TypeParameter, index_offset)                                           \
  FIELD(TypeArguments, hash_offset)                                            \
  FIELD(TypeArguments, instantiations_offset)                                  \
  FIELD(TypeArguments, length_offset)                                          \
  FIELD(TypeArguments, nullability_offset)                                     \
  FIELD(TypeArguments, types_offset)                                           \
  FIELD(TypeParameters, names_offset)                                          \
  FIELD(TypeParameters, flags_offset)                                          \
  FIELD(TypeParameters, bounds_offset)                                         \
  FIELD(TypeParameters, defaults_offset)                                       \
  FIELD(TypedDataBase, length_offset)                                          \
  FIELD(TypedDataView, typed_data_offset)                                      \
  FIELD(TypedDataView, offset_in_bytes_offset)                                 \
  FIELD(TypedData, payload_offset)                                             \
  FIELD(UnhandledException, exception_offset)                                  \
  FIELD(UnhandledException, stacktrace_offset)                                 \
  FIELD(UserTag, tag_offset)                                                   \
  FIELD(MonomorphicSmiableCall, expected_cid_offset)                           \
  FIELD(MonomorphicSmiableCall, entrypoint_offset)                             \
  FIELD(WeakProperty, key_offset)                                              \
  FIELD(WeakProperty, value_offset)                                            \
  FIELD(WeakReference, target_offset)                                          \
  FIELD(WeakReference, type_arguments_offset)                                  \
  RANGE(Code, entry_point_offset, CodeEntryKind, CodeEntryKind::kNormal,       \
        CodeEntryKind::kMonomorphicUnchecked,                                  \
        [](CodeEntryKind value) { return true; })                              \
  RANGE(Thread, write_barrier_wrappers_thread_offset, Register, 0,             \
        kNumberOfCpuRegisters - 1, [](Register reg) {                          \
          return (kDartAvailableCpuRegs & (1 << reg)) != 0;                    \
        })                                                                     \
                                                                               \
  SIZEOF(AbstractType, InstanceSize, UntaggedAbstractType)                     \
  SIZEOF(ApiError, InstanceSize, UntaggedApiError)                             \
  SIZEOF(Array, header_size, UntaggedArray)                                    \
  SIZEOF(Bool, InstanceSize, UntaggedBool)                                     \
  SIZEOF(Capability, InstanceSize, UntaggedCapability)                         \
  SIZEOF(Class, InstanceSize, UntaggedClass)                                   \
  SIZEOF(Closure, InstanceSize, UntaggedClosure)                               \
  SIZEOF(ClosureData, InstanceSize, UntaggedClosureData)                       \
  SIZEOF(CodeSourceMap, HeaderSize, UntaggedCodeSourceMap)                     \
  SIZEOF(CompressedStackMaps, ObjectHeaderSize, UntaggedCompressedStackMaps)   \
  SIZEOF(CompressedStackMaps, PayloadHeaderSize,                               \
         UntaggedCompressedStackMaps::Payload::FlagsAndSizeHeader)             \
  SIZEOF(Context, header_size, UntaggedContext)                                \
  SIZEOF(Double, InstanceSize, UntaggedDouble)                                 \
  SIZEOF(DynamicLibrary, InstanceSize, UntaggedDynamicLibrary)                 \
  SIZEOF(ExternalOneByteString, InstanceSize, UntaggedExternalOneByteString)   \
  SIZEOF(ExternalTwoByteString, InstanceSize, UntaggedExternalTwoByteString)   \
  SIZEOF(ExternalTypedData, InstanceSize, UntaggedExternalTypedData)           \
  SIZEOF(FfiTrampolineData, InstanceSize, UntaggedFfiTrampolineData)           \
  SIZEOF(Field, InstanceSize, UntaggedField)                                   \
  SIZEOF(Finalizer, InstanceSize, UntaggedFinalizer)                           \
  SIZEOF(FinalizerEntry, InstanceSize, UntaggedFinalizerEntry)                 \
  SIZEOF(NativeFinalizer, InstanceSize, UntaggedNativeFinalizer)               \
  SIZEOF(Float32x4, InstanceSize, UntaggedFloat32x4)                           \
  SIZEOF(Float64x2, InstanceSize, UntaggedFloat64x2)                           \
  SIZEOF(Function, InstanceSize, UntaggedFunction)                             \
  SIZEOF(FunctionType, InstanceSize, UntaggedFunctionType)                     \
  SIZEOF(FutureOr, InstanceSize, UntaggedFutureOr)                             \
  SIZEOF(GrowableObjectArray, InstanceSize, UntaggedGrowableObjectArray)       \
  SIZEOF(ICData, InstanceSize, UntaggedICData)                                 \
  SIZEOF(Instance, InstanceSize, UntaggedInstance)                             \
  SIZEOF(Instructions, UnalignedHeaderSize, UntaggedInstructions)              \
  SIZEOF(InstructionsSection, UnalignedHeaderSize,                             \
         UntaggedInstructionsSection)                                          \
  SIZEOF(InstructionsTable, InstanceSize, UntaggedInstructionsTable)           \
  SIZEOF(Int32x4, InstanceSize, UntaggedInt32x4)                               \
  SIZEOF(Integer, InstanceSize, UntaggedInteger)                               \
  SIZEOF(KernelProgramInfo, InstanceSize, UntaggedKernelProgramInfo)           \
  SIZEOF(LanguageError, InstanceSize, UntaggedLanguageError)                   \
  SIZEOF(Library, InstanceSize, UntaggedLibrary)                               \
  SIZEOF(LibraryPrefix, InstanceSize, UntaggedLibraryPrefix)                   \
  SIZEOF(LinkedHashBase, InstanceSize, UntaggedLinkedHashBase)                 \
  SIZEOF(LocalHandle, InstanceSize, LocalHandle)                               \
  SIZEOF(MegamorphicCache, InstanceSize, UntaggedMegamorphicCache)             \
  SIZEOF(Mint, InstanceSize, UntaggedMint)                                     \
  SIZEOF(MirrorReference, InstanceSize, UntaggedMirrorReference)               \
  SIZEOF(MonomorphicSmiableCall, InstanceSize, UntaggedMonomorphicSmiableCall) \
  SIZEOF(Namespace, InstanceSize, UntaggedNamespace)                           \
  SIZEOF(NativeArguments, StructSize, NativeArguments)                         \
  SIZEOF(Number, InstanceSize, UntaggedNumber)                                 \
  SIZEOF(Object, InstanceSize, UntaggedObject)                                 \
  SIZEOF(PatchClass, InstanceSize, UntaggedPatchClass)                         \
  SIZEOF(PcDescriptors, HeaderSize, UntaggedPcDescriptors)                     \
  SIZEOF(Pointer, InstanceSize, UntaggedPointer)                               \
  SIZEOF(ReceivePort, InstanceSize, UntaggedReceivePort)                       \
  SIZEOF(RecordType, InstanceSize, UntaggedRecordType)                         \
  SIZEOF(RegExp, InstanceSize, UntaggedRegExp)                                 \
  SIZEOF(Script, InstanceSize, UntaggedScript)                                 \
  SIZEOF(SendPort, InstanceSize, UntaggedSendPort)                             \
  SIZEOF(Sentinel, InstanceSize, UntaggedSentinel)                             \
  SIZEOF(SingleTargetCache, InstanceSize, UntaggedSingleTargetCache)           \
  SIZEOF(StackTrace, InstanceSize, UntaggedStackTrace)                         \
  SIZEOF(SuspendState, HeaderSize, UntaggedSuspendState)                       \
  SIZEOF(String, InstanceSize, UntaggedString)                                 \
  SIZEOF(SubtypeTestCache, InstanceSize, UntaggedSubtypeTestCache)             \
  SIZEOF(LoadingUnit, InstanceSize, UntaggedLoadingUnit)                       \
  SIZEOF(TransferableTypedData, InstanceSize, UntaggedTransferableTypedData)   \
  SIZEOF(Type, InstanceSize, UntaggedType)                                     \
  SIZEOF(TypeParameter, InstanceSize, UntaggedTypeParameter)                   \
  SIZEOF(TypeParameters, InstanceSize, UntaggedTypeParameters)                 \
  SIZEOF(TypedData, HeaderSize, UntaggedTypedData)                             \
  SIZEOF(TypedDataBase, InstanceSize, UntaggedTypedDataBase)                   \
  SIZEOF(TypedDataView, InstanceSize, UntaggedTypedDataView)                   \
  SIZEOF(UnhandledException, InstanceSize, UntaggedUnhandledException)         \
  SIZEOF(UnlinkedCall, InstanceSize, UntaggedUnlinkedCall)                     \
  SIZEOF(UnwindError, InstanceSize, UntaggedUnwindError)                       \
  SIZEOF(UserTag, InstanceSize, UntaggedUserTag)                               \
  SIZEOF(WeakProperty, InstanceSize, UntaggedWeakProperty)                     \
  SIZEOF(WeakReference, InstanceSize, UntaggedWeakReference)                   \
  SIZEOF(WeakSerializationReference, InstanceSize,                             \
         UntaggedWeakSerializationReference)                                   \
  PAYLOAD_SIZEOF(CodeSourceMap, InstanceSize, HeaderSize)                      \
  PAYLOAD_SIZEOF(CompressedStackMaps, InstanceSize, HeaderSize)                \
  PAYLOAD_SIZEOF(InstructionsSection, InstanceSize, HeaderSize)                \
  PAYLOAD_SIZEOF(PcDescriptors, InstanceSize, HeaderSize)                      \
  PAYLOAD_SIZEOF(SuspendState, InstanceSize, HeaderSize)                       \
  PAYLOAD_SIZEOF(TypedData, InstanceSize, HeaderSize)

#define JIT_OFFSETS_LIST(FIELD, ARRAY, SIZEOF, ARRAY_SIZEOF, PAYLOAD_SIZEOF,   \
                         RANGE, CONSTANT)                                      \
  FIELD(Code, active_instructions_offset)                                      \
  FIELD(Function, usage_counter_offset)                                        \
  FIELD(ICData, receivers_static_type_offset)                                  \
  FIELD(SuspendState, frame_capacity_offset)

#define AOT_OFFSETS_LIST(FIELD, ARRAY, SIZEOF, ARRAY_SIZEOF, PAYLOAD_SIZEOF,   \
                         RANGE, CONSTANT)                                      \
  FIELD(Closure, entry_point_offset)

#endif  // RUNTIME_VM_COMPILER_RUNTIME_OFFSETS_LIST_H_
