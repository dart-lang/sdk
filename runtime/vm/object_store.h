// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OBJECT_STORE_H_
#define RUNTIME_VM_OBJECT_STORE_H_

#include "vm/object.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;

// A list of the bootstrap libraries including CamelName and name.
//
// These are listed in the order that they are compiled (see vm/bootstrap.cc).
#define FOR_EACH_BOOTSTRAP_LIBRARY(M)                                          \
  M(Core, core)                                                                \
  M(Async, async)                                                              \
  M(Collection, collection)                                                    \
  M(Convert, convert)                                                          \
  M(Developer, developer)                                                      \
  M(Ffi, ffi)                                                                  \
  M(Internal, _internal)                                                       \
  M(Isolate, isolate)                                                          \
  M(Math, math)                                                                \
  M(Mirrors, mirrors)                                                          \
  M(TypedData, typed_data)                                                     \
  M(VMService, _vmservice)

// TODO(liama): Once NNBD is enabled, *_type will be deleted and all uses will
// be replaced with *_type_non_nullable. Later, once we drop support for opted
// out code, *_type_legacy will be deleted.
//
// R_ - needs getter only
// RW - needs getter and setter
// ARW_RELAXED - needs getter and setter with relaxed atomic access
// ARW_AR - needs getter and setter with acq/rel atomic access
// LAZY_CORE - needs lazy init getter for a "dart:core" member
// LAZY_ASYNC - needs lazy init getter for a "dart:async" member
// LAZY_ISOLATE - needs lazy init getter for a "dart:isolate" member
// LAZY_INTERNAL - needs lazy init getter for a "dart:_internal" member
#define OBJECT_STORE_FIELD_LIST(R_, RW, ARW_RELAXED, ARW_AR, LAZY_CORE,        \
                                LAZY_ASYNC, LAZY_ISOLATE, LAZY_INTERNAL,       \
                                LAZY_FFI)                                      \
  LAZY_CORE(Class, list_class)                                                 \
  LAZY_CORE(Class, map_class)                                                  \
  LAZY_CORE(Class, set_class)                                                  \
  LAZY_CORE(Type, non_nullable_list_rare_type)                                 \
  LAZY_CORE(Type, non_nullable_map_rare_type)                                  \
  LAZY_CORE(Field, enum_index_field)                                           \
  LAZY_CORE(Field, enum_name_field)                                            \
  LAZY_CORE(Function, _object_equals_function)                                 \
  LAZY_CORE(Function, _object_hash_code_function)                              \
  LAZY_CORE(Function, _object_to_string_function)                              \
  LAZY_INTERNAL(Class, symbol_class)                                           \
  LAZY_INTERNAL(Field, symbol_name_field)                                      \
  LAZY_FFI(Class, varargs_class)                                               \
  LAZY_FFI(Function, handle_finalizer_message_function)                        \
  LAZY_FFI(Function, handle_native_finalizer_message_function)                 \
  LAZY_ASYNC(Type, non_nullable_future_rare_type)                              \
  LAZY_ASYNC(Type, non_nullable_future_never_type)                             \
  LAZY_ASYNC(Type, nullable_future_null_type)                                  \
  LAZY_ISOLATE(Class, send_port_class)                                         \
  LAZY_ISOLATE(Class, capability_class)                                        \
  LAZY_ISOLATE(Class, transferable_class)                                      \
  LAZY_ISOLATE(Function, lookup_port_handler)                                  \
  LAZY_ISOLATE(Function, lookup_open_ports)                                    \
  LAZY_ISOLATE(Function, handle_message_function)                              \
  RW(Class, object_class)                                                      \
  RW(Type, object_type)                                                        \
  RW(Type, legacy_object_type)                                                 \
  RW(Type, non_nullable_object_type)                                           \
  RW(Type, nullable_object_type)                                               \
  RW(Class, null_class)                                                        \
  RW(Type, null_type)                                                          \
  RW(Class, never_class)                                                       \
  RW(Type, never_type)                                                         \
  RW(Type, function_type)                                                      \
  RW(Type, type_type)                                                          \
  RW(Class, closure_class)                                                     \
  RW(Class, record_class)                                                      \
  RW(Type, number_type)                                                        \
  RW(Type, int_type)                                                           \
  RW(Type, legacy_int_type)                                                    \
  RW(Type, non_nullable_int_type)                                              \
  RW(Type, nullable_int_type)                                                  \
  RW(Class, integer_implementation_class)                                      \
  RW(Type, int64_type)                                                         \
  RW(Class, smi_class)                                                         \
  RW(Type, smi_type)                                                           \
  RW(Class, mint_class)                                                        \
  RW(Type, mint_type)                                                          \
  RW(Class, double_class)                                                      \
  RW(Type, double_type)                                                        \
  RW(Type, nullable_double_type)                                               \
  RW(Type, float32x4_type)                                                     \
  RW(Type, int32x4_type)                                                       \
  RW(Type, float64x2_type)                                                     \
  RW(Type, string_type)                                                        \
  RW(Type, legacy_string_type)                                                 \
  RW(TypeArguments, type_argument_int)                                         \
  RW(TypeArguments, type_argument_legacy_int)                                  \
  RW(TypeArguments, type_argument_double)                                      \
  RW(TypeArguments, type_argument_never)                                       \
  RW(TypeArguments, type_argument_string)                                      \
  RW(TypeArguments, type_argument_legacy_string)                               \
  RW(TypeArguments, type_argument_string_dynamic)                              \
  RW(TypeArguments, type_argument_string_string)                               \
  RW(Class, compiletime_error_class)                                           \
  RW(Class, pragma_class)                                                      \
  RW(Field, pragma_name)                                                       \
  RW(Field, pragma_options)                                                    \
  RW(Class, future_class)                                                      \
  RW(Class, completer_class)                                                   \
  RW(Class, one_byte_string_class)                                             \
  RW(Class, two_byte_string_class)                                             \
  RW(Class, external_one_byte_string_class)                                    \
  RW(Class, external_two_byte_string_class)                                    \
  RW(Type, bool_type)                                                          \
  RW(Class, bool_class)                                                        \
  RW(Class, array_class)                                                       \
  RW(Type, array_type)                                                         \
  RW(Class, immutable_array_class)                                             \
  RW(Class, growable_object_array_class)                                       \
  RW(Class, map_impl_class)                                                    \
  RW(Class, const_map_impl_class)                                              \
  RW(Class, set_impl_class)                                                    \
  RW(Class, const_set_impl_class)                                              \
  RW(Class, float32x4_class)                                                   \
  RW(Class, int32x4_class)                                                     \
  RW(Class, float64x2_class)                                                   \
  RW(Class, error_class)                                                       \
  RW(Class, expando_class)                                                     \
  RW(Class, iterable_class)                                                    \
  RW(Class, weak_property_class)                                               \
  RW(Class, weak_reference_class)                                              \
  RW(Class, finalizer_class)                                                   \
  RW(Class, finalizer_entry_class)                                             \
  RW(Class, native_finalizer_class)                                            \
  ARW_AR(WeakArray, symbol_table)                                              \
  ARW_AR(WeakArray, regexp_table)                                              \
  RW(Array, canonical_types)                                                   \
  RW(Array, canonical_function_types)                                          \
  RW(Array, canonical_record_types)                                            \
  RW(Array, canonical_type_parameters)                                         \
  RW(Array, canonical_type_arguments)                                          \
  RW(Library, async_library)                                                   \
  RW(Library, core_library)                                                    \
  RW(Library, collection_library)                                              \
  RW(Library, convert_library)                                                 \
  RW(Library, developer_library)                                               \
  RW(Library, ffi_library)                                                     \
  RW(Library, _internal_library)                                               \
  RW(Library, isolate_library)                                                 \
  RW(Library, math_library)                                                    \
  RW(Library, mirrors_library)                                                 \
  RW(Library, native_wrappers_library)                                         \
  RW(Library, root_library)                                                    \
  RW(Library, typed_data_library)                                              \
  RW(Library, _vmservice_library)                                              \
  RW(Library, native_assets_library)                                           \
  RW(Array, native_assets_map)                                                 \
  RW(GrowableObjectArray, libraries)                                           \
  RW(Array, libraries_map)                                                     \
  RW(Array, uri_to_resolved_uri_map)                                           \
  RW(Array, resolved_uri_to_uri_map)                                           \
  RW(Smi, last_libraries_count)                                                \
  RW(Array, loading_units)                                                     \
  RW(GrowableObjectArray, closure_functions)                                   \
  RW(GrowableObjectArray, pending_classes)                                     \
  RW(Array, record_field_names_map)                                            \
  ARW_RELAXED(Array, record_field_names)                                       \
  RW(Instance, stack_overflow)                                                 \
  RW(Instance, out_of_memory)                                                  \
  RW(Function, growable_list_factory)                                          \
  RW(Function, simple_instance_of_function)                                    \
  RW(Function, simple_instance_of_true_function)                               \
  RW(Function, simple_instance_of_false_function)                              \
  RW(Function, async_star_stream_controller_add)                               \
  RW(Function, async_star_stream_controller_add_stream)                        \
  RW(Function, suspend_state_init_async)                                       \
  RW(Function, suspend_state_await)                                            \
  RW(Function, suspend_state_await_with_type_check)                            \
  RW(Function, suspend_state_return_async)                                     \
  RW(Function, suspend_state_return_async_not_future)                          \
  RW(Function, suspend_state_init_async_star)                                  \
  RW(Function, suspend_state_yield_async_star)                                 \
  RW(Function, suspend_state_return_async_star)                                \
  RW(Function, suspend_state_init_sync_star)                                   \
  RW(Function, suspend_state_suspend_sync_star_at_start)                       \
  RW(Function, suspend_state_handle_exception)                                 \
  RW(Class, async_star_stream_controller)                                      \
  RW(Class, stream_class)                                                      \
  RW(Class, sync_star_iterator_class)                                          \
  RW(Field, async_star_stream_controller_async_star_body)                      \
  RW(Field, sync_star_iterator_current)                                        \
  RW(Field, sync_star_iterator_state)                                          \
  RW(Field, sync_star_iterator_yield_star_iterable)                            \
  ARW_RELAXED(Smi, future_timeout_future_index)                                \
  ARW_RELAXED(Smi, future_wait_future_index)                                   \
  RW(CompressedStackMaps, canonicalized_stack_map_entries)                     \
  RW(ObjectPool, global_object_pool)                                           \
  RW(Array, unique_dynamic_targets)                                            \
  RW(GrowableObjectArray, megamorphic_cache_table)                             \
  RW(GrowableObjectArray, ffi_callback_code)                                   \
  RW(Code, build_generic_method_extractor_code)                                \
  RW(Code, build_nongeneric_method_extractor_code)                             \
  RW(Code, dispatch_table_null_error_stub)                                     \
  RW(Code, late_initialization_error_stub_with_fpu_regs_stub)                  \
  RW(Code, late_initialization_error_stub_without_fpu_regs_stub)               \
  RW(Code, null_error_stub_with_fpu_regs_stub)                                 \
  RW(Code, null_error_stub_without_fpu_regs_stub)                              \
  RW(Code, null_arg_error_stub_with_fpu_regs_stub)                             \
  RW(Code, null_arg_error_stub_without_fpu_regs_stub)                          \
  RW(Code, null_cast_error_stub_with_fpu_regs_stub)                            \
  RW(Code, null_cast_error_stub_without_fpu_regs_stub)                         \
  RW(Code, range_error_stub_with_fpu_regs_stub)                                \
  RW(Code, range_error_stub_without_fpu_regs_stub)                             \
  RW(Code, write_error_stub_with_fpu_regs_stub)                                \
  RW(Code, write_error_stub_without_fpu_regs_stub)                             \
  RW(Code, allocate_mint_with_fpu_regs_stub)                                   \
  RW(Code, allocate_mint_without_fpu_regs_stub)                                \
  RW(Code, stack_overflow_stub_with_fpu_regs_stub)                             \
  RW(Code, stack_overflow_stub_without_fpu_regs_stub)                          \
  RW(Code, allocate_array_stub)                                                \
  RW(Code, allocate_mint_stub)                                                 \
  RW(Code, allocate_double_stub)                                               \
  RW(Code, allocate_float32x4_stub)                                            \
  RW(Code, allocate_float64x2_stub)                                            \
  RW(Code, allocate_int32x4_stub)                                              \
  RW(Code, allocate_int8_array_stub)                                           \
  RW(Code, allocate_uint8_array_stub)                                          \
  RW(Code, allocate_uint8_clamped_array_stub)                                  \
  RW(Code, allocate_int16_array_stub)                                          \
  RW(Code, allocate_uint16_array_stub)                                         \
  RW(Code, allocate_int32_array_stub)                                          \
  RW(Code, allocate_uint32_array_stub)                                         \
  RW(Code, allocate_int64_array_stub)                                          \
  RW(Code, allocate_uint64_array_stub)                                         \
  RW(Code, allocate_float32_array_stub)                                        \
  RW(Code, allocate_float64_array_stub)                                        \
  RW(Code, allocate_float32x4_array_stub)                                      \
  RW(Code, allocate_int32x4_array_stub)                                        \
  RW(Code, allocate_float64x2_array_stub)                                      \
  RW(Code, allocate_closure_stub)                                              \
  RW(Code, allocate_context_stub)                                              \
  RW(Code, allocate_growable_array_stub)                                       \
  RW(Code, allocate_object_stub)                                               \
  RW(Code, allocate_object_parametrized_stub)                                  \
  RW(Code, allocate_record_stub)                                               \
  RW(Code, allocate_record2_stub)                                              \
  RW(Code, allocate_record2_named_stub)                                        \
  RW(Code, allocate_record3_stub)                                              \
  RW(Code, allocate_record3_named_stub)                                        \
  RW(Code, allocate_unhandled_exception_stub)                                  \
  RW(Code, clone_context_stub)                                                 \
  RW(Code, write_barrier_wrappers_stub)                                        \
  RW(Code, array_write_barrier_stub)                                           \
  RW(Code, throw_stub)                                                         \
  RW(Code, re_throw_stub)                                                      \
  RW(Code, assert_boolean_stub)                                                \
  RW(Code, instance_of_stub)                                                   \
  RW(Code, init_static_field_stub)                                             \
  RW(Code, init_late_static_field_stub)                                        \
  RW(Code, init_late_final_static_field_stub)                                  \
  RW(Code, init_instance_field_stub)                                           \
  RW(Code, init_late_instance_field_stub)                                      \
  RW(Code, init_late_final_instance_field_stub)                                \
  RW(Code, call_closure_no_such_method_stub)                                   \
  RW(Code, default_tts_stub)                                                   \
  RW(Code, default_nullable_tts_stub)                                          \
  RW(Code, top_type_tts_stub)                                                  \
  RW(Code, nullable_type_parameter_tts_stub)                                   \
  RW(Code, type_parameter_tts_stub)                                            \
  RW(Code, unreachable_tts_stub)                                               \
  RW(Array, ffi_callback_functions)                                            \
  RW(Code, slow_tts_stub)                                                      \
  /* Roots for JIT/AOT snapshots are up until here (see to_snapshot() below)*/ \
  RW(Code, await_stub)                                                         \
  RW(Code, await_with_type_check_stub)                                         \
  RW(Code, clone_suspend_state_stub)                                           \
  RW(Code, init_async_stub)                                                    \
  RW(Code, resume_stub)                                                        \
  RW(Code, return_async_stub)                                                  \
  RW(Code, return_async_not_future_stub)                                       \
  RW(Code, init_async_star_stub)                                               \
  RW(Code, yield_async_star_stub)                                              \
  RW(Code, return_async_star_stub)                                             \
  RW(Code, init_sync_star_stub)                                                \
  RW(Code, suspend_sync_star_at_start_stub)                                    \
  RW(Code, suspend_sync_star_at_yield_stub)                                    \
  RW(Array, dispatch_table_code_entries)                                       \
  RW(GrowableObjectArray, instructions_tables)                                 \
  RW(Array, obfuscation_map)                                                   \
  RW(Array, loading_unit_uris)                                                 \
  RW(Class, ffi_pointer_class)                                                 \
  RW(Class, ffi_native_type_class)                                             \
  // Please remember the last entry must be referred in the 'to' function below.

#define OBJECT_STORE_STUB_CODE_LIST(DO)                                        \
  DO(dispatch_table_null_error_stub, DispatchTableNullError)                   \
  DO(late_initialization_error_stub_with_fpu_regs_stub,                        \
     LateInitializationErrorSharedWithFPURegs)                                 \
  DO(late_initialization_error_stub_without_fpu_regs_stub,                     \
     LateInitializationErrorSharedWithoutFPURegs)                              \
  DO(null_error_stub_with_fpu_regs_stub, NullErrorSharedWithFPURegs)           \
  DO(null_error_stub_without_fpu_regs_stub, NullErrorSharedWithoutFPURegs)     \
  DO(null_arg_error_stub_with_fpu_regs_stub, NullArgErrorSharedWithFPURegs)    \
  DO(null_arg_error_stub_without_fpu_regs_stub,                                \
     NullArgErrorSharedWithoutFPURegs)                                         \
  DO(null_cast_error_stub_with_fpu_regs_stub, NullCastErrorSharedWithFPURegs)  \
  DO(null_cast_error_stub_without_fpu_regs_stub,                               \
     NullCastErrorSharedWithoutFPURegs)                                        \
  DO(range_error_stub_with_fpu_regs_stub, RangeErrorSharedWithFPURegs)         \
  DO(range_error_stub_without_fpu_regs_stub, RangeErrorSharedWithoutFPURegs)   \
  DO(write_error_stub_with_fpu_regs_stub, WriteErrorSharedWithFPURegs)         \
  DO(write_error_stub_without_fpu_regs_stub, WriteErrorSharedWithoutFPURegs)   \
  DO(allocate_mint_with_fpu_regs_stub, AllocateMintSharedWithFPURegs)          \
  DO(allocate_mint_without_fpu_regs_stub, AllocateMintSharedWithoutFPURegs)    \
  DO(stack_overflow_stub_with_fpu_regs_stub, StackOverflowSharedWithFPURegs)   \
  DO(stack_overflow_stub_without_fpu_regs_stub,                                \
     StackOverflowSharedWithoutFPURegs)                                        \
  DO(allocate_array_stub, AllocateArray)                                       \
  DO(allocate_mint_stub, AllocateMint)                                         \
  DO(allocate_double_stub, AllocateDouble)                                     \
  DO(allocate_float32x4_stub, AllocateFloat32x4)                               \
  DO(allocate_float64x2_stub, AllocateFloat64x2)                               \
  DO(allocate_int32x4_stub, AllocateInt32x4)                                   \
  DO(allocate_int8_array_stub, AllocateInt8Array)                              \
  DO(allocate_uint8_array_stub, AllocateUint8Array)                            \
  DO(allocate_uint8_clamped_array_stub, AllocateUint8ClampedArray)             \
  DO(allocate_int16_array_stub, AllocateInt16Array)                            \
  DO(allocate_uint16_array_stub, AllocateUint16Array)                          \
  DO(allocate_int32_array_stub, AllocateInt32Array)                            \
  DO(allocate_uint32_array_stub, AllocateUint32Array)                          \
  DO(allocate_int64_array_stub, AllocateInt64Array)                            \
  DO(allocate_uint64_array_stub, AllocateUint64Array)                          \
  DO(allocate_float32_array_stub, AllocateFloat32Array)                        \
  DO(allocate_float64_array_stub, AllocateFloat64Array)                        \
  DO(allocate_float32x4_array_stub, AllocateFloat32x4Array)                    \
  DO(allocate_int32x4_array_stub, AllocateInt32x4Array)                        \
  DO(allocate_float64x2_array_stub, AllocateFloat64x2Array)                    \
  DO(allocate_closure_stub, AllocateClosure)                                   \
  DO(allocate_context_stub, AllocateContext)                                   \
  DO(allocate_growable_array_stub, AllocateGrowableArray)                      \
  DO(allocate_object_stub, AllocateObject)                                     \
  DO(allocate_object_parametrized_stub, AllocateObjectParameterized)           \
  DO(allocate_record_stub, AllocateRecord)                                     \
  DO(allocate_record2_stub, AllocateRecord2)                                   \
  DO(allocate_record2_named_stub, AllocateRecord2Named)                        \
  DO(allocate_record3_stub, AllocateRecord3)                                   \
  DO(allocate_record3_named_stub, AllocateRecord3Named)                        \
  DO(allocate_unhandled_exception_stub, AllocateUnhandledException)            \
  DO(clone_context_stub, CloneContext)                                         \
  DO(call_closure_no_such_method_stub, CallClosureNoSuchMethod)                \
  DO(default_tts_stub, DefaultTypeTest)                                        \
  DO(default_nullable_tts_stub, DefaultNullableTypeTest)                       \
  DO(top_type_tts_stub, TopTypeTypeTest)                                       \
  DO(nullable_type_parameter_tts_stub, NullableTypeParameterTypeTest)          \
  DO(type_parameter_tts_stub, TypeParameterTypeTest)                           \
  DO(unreachable_tts_stub, UnreachableTypeTest)                                \
  DO(slow_tts_stub, SlowTypeTest)                                              \
  DO(write_barrier_wrappers_stub, WriteBarrierWrappers)                        \
  DO(array_write_barrier_stub, ArrayWriteBarrier)                              \
  DO(throw_stub, Throw)                                                        \
  DO(re_throw_stub, ReThrow)                                                   \
  DO(assert_boolean_stub, AssertBoolean)                                       \
  DO(init_static_field_stub, InitStaticField)                                  \
  DO(init_late_static_field_stub, InitLateStaticField)                         \
  DO(init_late_final_static_field_stub, InitLateFinalStaticField)              \
  DO(init_instance_field_stub, InitInstanceField)                              \
  DO(init_late_instance_field_stub, InitLateInstanceField)                     \
  DO(init_late_final_instance_field_stub, InitLateFinalInstanceField)          \
  DO(await_stub, Await)                                                        \
  DO(await_with_type_check_stub, AwaitWithTypeCheck)                           \
  DO(clone_suspend_state_stub, CloneSuspendState)                              \
  DO(init_async_stub, InitAsync)                                               \
  DO(resume_stub, Resume)                                                      \
  DO(return_async_stub, ReturnAsync)                                           \
  DO(return_async_not_future_stub, ReturnAsyncNotFuture)                       \
  DO(init_async_star_stub, InitAsyncStar)                                      \
  DO(yield_async_star_stub, YieldAsyncStar)                                    \
  DO(return_async_star_stub, ReturnAsyncStar)                                  \
  DO(init_sync_star_stub, InitSyncStar)                                        \
  DO(suspend_sync_star_at_start_stub, SuspendSyncStarAtStart)                  \
  DO(suspend_sync_star_at_yield_stub, SuspendSyncStarAtYield)                  \
  DO(instance_of_stub, InstanceOf)

#define ISOLATE_OBJECT_STORE_FIELD_LIST(R_, RW)                                \
  RW(UnhandledException, preallocated_unhandled_exception)                     \
  RW(StackTrace, preallocated_stack_trace)                                     \
  RW(UnwindError, preallocated_unwind_error)                                   \
  R_(Array, dart_args_1)                                                       \
  R_(Array, dart_args_2)                                                       \
  R_(GrowableObjectArray, resume_capabilities)                                 \
  R_(GrowableObjectArray, exit_listeners)                                      \
  R_(GrowableObjectArray, error_listeners)
// Please remember the last entry must be referred in the 'to' function below.

class IsolateObjectStore {
 public:
  IsolateObjectStore() {}
  ~IsolateObjectStore() {}

#define DECLARE_GETTER(Type, name)                                             \
  Type##Ptr name() const { return name##_; }                                   \
  static intptr_t name##_offset() {                                            \
    return OFFSET_OF(IsolateObjectStore, name##_);                             \
  }

#define DECLARE_GETTER_AND_SETTER(Type, name)                                  \
  DECLARE_GETTER(Type, name)                                                   \
  void set_##name(const Type& value) { name##_ = value.ptr(); }
  ISOLATE_OBJECT_STORE_FIELD_LIST(DECLARE_GETTER, DECLARE_GETTER_AND_SETTER)
#undef DECLARE_GETTER
#undef DECLARE_GETTER_AND_SETTER

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Called to initialize objects required by the vm but which invoke
  // dart code.  If an error occurs the error object is returned otherwise
  // a null object is returned.
  ErrorPtr PreallocateObjects(const Object& out_of_memory);

  void Init();
  void PostLoad();

#ifndef PRODUCT
  void PrintToJSONObject(JSONObject* jsobj);
#endif

 private:
  // Finds a core library private method in Object.
  FunctionPtr PrivateObjectLookup(const String& name);

  ObjectPtr* from() {
    return reinterpret_cast<ObjectPtr*>(&preallocated_unhandled_exception_);
  }
#define DECLARE_OBJECT_STORE_FIELD(type, name) type##Ptr name##_;
  ISOLATE_OBJECT_STORE_FIELD_LIST(DECLARE_OBJECT_STORE_FIELD,
                                  DECLARE_OBJECT_STORE_FIELD)
#undef DECLARE_OBJECT_STORE_FIELD
  ObjectPtr* to() { return reinterpret_cast<ObjectPtr*>(&error_listeners_); }

  friend class Serializer;
  friend class Deserializer;

  DISALLOW_COPY_AND_ASSIGN(IsolateObjectStore);
};

// The object store is a per isolate group instance which stores references to
// objects used by the VM shared by all isolates in a group.
class ObjectStore {
 public:
  enum BootstrapLibraryId {
#define MAKE_ID(Name, _) k##Name,

    FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_ID)
#undef MAKE_ID
  };

  ObjectStore();
  ~ObjectStore();

#define DECLARE_OFFSET(name)                                                   \
  static intptr_t name##_offset() { return OFFSET_OF(ObjectStore, name##_); }
#define DECLARE_GETTER(Type, name)                                             \
  Type##Ptr name() const { return name##_; }                                   \
  DECLARE_OFFSET(name)
#define DECLARE_GETTER_AND_SETTER(Type, name)                                  \
  DECLARE_GETTER(Type, name)                                                   \
  void set_##name(const Type& value) { name##_ = value.ptr(); }
#define DECLARE_RELAXED_ATOMIC_GETTER_AND_SETTER(Type, name)                   \
  template <std::memory_order order = std::memory_order_relaxed>               \
  Type##Ptr name() const {                                                     \
    return name##_.load(order);                                                \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##name(const Type& value) {                                         \
    name##_.store(value.ptr(), order);                                         \
  }                                                                            \
  DECLARE_OFFSET(name)
#define DECLARE_ACQREL_ATOMIC_GETTER_AND_SETTER(Type, name)                    \
  Type##Ptr name() const { return name##_.load(); }                            \
  void set_##name(const Type& value) { name##_.store(value.ptr()); }           \
  DECLARE_OFFSET(name)
#define DECLARE_LAZY_INIT_GETTER(Type, name, init)                             \
  Type##Ptr name() {                                                           \
    if (name##_.load() == Type::null()) {                                      \
      init();                                                                  \
    }                                                                          \
    return name##_.load();                                                     \
  }                                                                            \
  DECLARE_OFFSET(name)
#define DECLARE_LAZY_INIT_CORE_GETTER(Type, name)                              \
  DECLARE_LAZY_INIT_GETTER(Type, name, LazyInitCoreMembers)
#define DECLARE_LAZY_INIT_ASYNC_GETTER(Type, name)                             \
  DECLARE_LAZY_INIT_GETTER(Type, name, LazyInitAsyncMembers)
#define DECLARE_LAZY_INIT_ISOLATE_GETTER(Type, name)                           \
  DECLARE_LAZY_INIT_GETTER(Type, name, LazyInitIsolateMembers)
#define DECLARE_LAZY_INIT_INTERNAL_GETTER(Type, name)                          \
  DECLARE_LAZY_INIT_GETTER(Type, name, LazyInitInternalMembers)
#define DECLARE_LAZY_INIT_FFI_GETTER(Type, name)                               \
  DECLARE_LAZY_INIT_GETTER(Type, name, LazyInitFfiMembers)
  OBJECT_STORE_FIELD_LIST(DECLARE_GETTER,
                          DECLARE_GETTER_AND_SETTER,
                          DECLARE_RELAXED_ATOMIC_GETTER_AND_SETTER,
                          DECLARE_ACQREL_ATOMIC_GETTER_AND_SETTER,
                          DECLARE_LAZY_INIT_CORE_GETTER,
                          DECLARE_LAZY_INIT_ASYNC_GETTER,
                          DECLARE_LAZY_INIT_ISOLATE_GETTER,
                          DECLARE_LAZY_INIT_INTERNAL_GETTER,
                          DECLARE_LAZY_INIT_FFI_GETTER)
#undef DECLARE_OFFSET
#undef DECLARE_GETTER
#undef DECLARE_GETTER_AND_SETTER
#undef DECLARE_RELAXED_ATOMIC_GETTER_AND_SETTER
#undef DECLARE_ACQREL_ATOMIC_GETTER_AND_SETTER
#undef DECLARE_LAZY_INIT_GETTER
#undef DECLARE_LAZY_INIT_CORE_GETTER
#undef DECLARE_LAZY_INIT_ASYNC_GETTER
#undef DECLARE_LAZY_INIT_ISOLATE_GETTER
#undef DECLARE_LAZY_INIT_INTERNAL_GETTER

  LibraryPtr bootstrap_library(BootstrapLibraryId index) {
    switch (index) {
#define MAKE_CASE(CamelName, name)                                             \
  case k##CamelName:                                                           \
    return name##_library_;

      FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_CASE)
#undef MAKE_CASE

      default:
        UNREACHABLE();
        return Library::null();
    }
  }

  void set_bootstrap_library(BootstrapLibraryId index, const Library& value) {
    switch (index) {
#define MAKE_CASE(CamelName, name)                                             \
  case k##CamelName:                                                           \
    name##_library_ = value.ptr();                                             \
    break;

      FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_CASE)
#undef MAKE_CASE
      default:
        UNREACHABLE();
    }
  }

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Called to initialize objects required by the vm but which invoke
  // dart code.  If an error occurs the error object is returned otherwise
  // a null object is returned.
  ErrorPtr PreallocateObjects();

  void InitKnownObjects();

  void InitStubs();

#ifndef PRODUCT
  void PrintToJSONObject(JSONObject* jsobj);
#endif

 private:
  void LazyInitCoreMembers();
  void LazyInitAsyncMembers();
  void LazyInitFfiMembers();
  void LazyInitIsolateMembers();
  void LazyInitInternalMembers();

  // Finds a core library private method in Object.
  FunctionPtr PrivateObjectLookup(const String& name);

  ObjectPtr* from() { return reinterpret_cast<ObjectPtr*>(&list_class_); }
#define DECLARE_OBJECT_STORE_FIELD(type, name) type##Ptr name##_;
#define DECLARE_ATOMIC_OBJECT_STORE_FIELD(type, name)                          \
  std::atomic<type##Ptr> name##_;
#define DECLARE_LAZY_OBJECT_STORE_FIELD(type, name)                            \
  AcqRelAtomic<type##Ptr> name##_;
  OBJECT_STORE_FIELD_LIST(DECLARE_OBJECT_STORE_FIELD,
                          DECLARE_OBJECT_STORE_FIELD,
                          DECLARE_ATOMIC_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD)
#undef DECLARE_OBJECT_STORE_FIELD
#undef DECLARE_ATOMIC_OBJECT_STORE_FIELD
#undef DECLARE_LAZY_OBJECT_STORE_FIELD
  ObjectPtr* to() {
    return reinterpret_cast<ObjectPtr*>(&ffi_native_type_class_);
  }
  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFull:
      case Snapshot::kFullCore:
        return reinterpret_cast<ObjectPtr*>(&global_object_pool_);
      case Snapshot::kFullJIT:
      case Snapshot::kFullAOT:
        return reinterpret_cast<ObjectPtr*>(&slow_tts_stub_);
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }
  uword unused_field_;

  friend class ProgramSerializationRoots;
  friend class ProgramDeserializationRoots;
  friend class ProgramVisitor;

  DISALLOW_COPY_AND_ASSIGN(ObjectStore);
};

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_STORE_H_
