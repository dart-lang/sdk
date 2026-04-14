// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ROOTS_H_
#define RUNTIME_VM_ROOTS_H_

#include "vm/stub_code_list.h"
#include "vm/symbol_list.h"
#include "vm/tagged_pointer.h"

namespace dart {

#define RAW_ROOTS_LIST(V)                                                      \
  V(ObjectPtr, null_obj)                                                       \
  V(BoolPtr, true_obj)                                                         \
  V(BoolPtr, false_obj)                                                        \
  V(ClassPtr, class_class)                                                     \
  V(ClassPtr, dynamic_class)                                                   \
  V(ClassPtr, void_class)                                                      \
  V(ClassPtr, type_parameters_class)                                           \
  V(ClassPtr, type_arguments_class)                                            \
  V(ClassPtr, patch_class_class)                                               \
  V(ClassPtr, function_class)                                                  \
  V(ClassPtr, closure_data_class)                                              \
  V(ClassPtr, ffi_trampoline_data_class)                                       \
  V(ClassPtr, field_class)                                                     \
  V(ClassPtr, script_class)                                                    \
  V(ClassPtr, library_class)                                                   \
  V(ClassPtr, namespace_class)                                                 \
  V(ClassPtr, kernel_program_info_class)                                       \
  V(ClassPtr, code_class)                                                      \
  V(ClassPtr, instructions_class)                                              \
  V(ClassPtr, instructions_section_class)                                      \
  V(ClassPtr, instructions_table_class)                                        \
  V(ClassPtr, object_pool_class)                                               \
  V(ClassPtr, pc_descriptors_class)                                            \
  V(ClassPtr, code_source_map_class)                                           \
  V(ClassPtr, compressed_stackmaps_class)                                      \
  V(ClassPtr, var_descriptors_class)                                           \
  V(ClassPtr, exception_handlers_class)                                        \
  V(ClassPtr, context_class)                                                   \
  V(ClassPtr, context_scope_class)                                             \
  V(ClassPtr, bytecode_class)                                                  \
  V(ClassPtr, sentinel_class)                                                  \
  V(ClassPtr, singletargetcache_class)                                         \
  V(ClassPtr, unlinkedcall_class)                                              \
  V(ClassPtr, monomorphicsmiablecall_class)                                    \
  V(ClassPtr, icdata_class)                                                    \
  V(ClassPtr, megamorphic_cache_class)                                         \
  V(ClassPtr, subtypetestcache_class)                                          \
  V(ClassPtr, loadingunit_class)                                               \
  V(ClassPtr, api_error_class)                                                 \
  V(ClassPtr, language_error_class)                                            \
  V(ClassPtr, unhandled_exception_class)                                       \
  V(ClassPtr, unwind_error_class)                                              \
  V(ClassPtr, weak_serialization_reference_class)                              \
  V(ClassPtr, weak_array_class)

#define HANDLE_ROOTS_LIST(V)                                                   \
  V(Object, null_object)                                                       \
  V(Class, null_class)                                                         \
  V(Array, null_array)                                                         \
  V(String, null_string)                                                       \
  V(Instance, null_instance)                                                   \
  V(Function, null_function)                                                   \
  V(FunctionType, null_function_type)                                          \
  V(RecordType, null_record_type)                                              \
  V(TypeArguments, null_type_arguments)                                        \
  V(CompressedStackMaps, null_compressed_stackmaps)                            \
  V(Closure, null_closure)                                                     \
  V(TypeArguments, empty_type_arguments)                                       \
  V(Array, empty_array)                                                        \
  V(Array, empty_instantiations_cache_array)                                   \
  V(Array, empty_subtype_test_cache_array)                                     \
  V(Array, mutable_empty_array)                                                \
  V(ContextScope, empty_context_scope)                                         \
  V(ObjectPool, empty_object_pool)                                             \
  V(CompressedStackMaps, empty_compressed_stackmaps)                           \
  V(PcDescriptors, empty_descriptors)                                          \
  V(LocalVarDescriptors, empty_var_descriptors)                                \
  V(ExceptionHandlers, empty_exception_handlers)                               \
  V(ExceptionHandlers, empty_async_exception_handlers)                         \
  V(Array, synthetic_getter_parameter_types)                                   \
  V(Array, synthetic_getter_parameter_names)                                   \
  V(Bytecode, implicit_getter_bytecode)                                        \
  V(Bytecode, implicit_setter_bytecode)                                        \
  V(Bytecode, implicit_static_getter_bytecode)                                 \
  V(Bytecode, implicit_shared_static_getter_bytecode)                          \
  V(Bytecode, implicit_static_setter_bytecode)                                 \
  V(Bytecode, implicit_shared_static_setter_bytecode)                          \
  V(Bytecode, method_extractor_with_ita_bytecode)                              \
  V(Bytecode, method_extractor_without_ita_bytecode)                           \
  V(Bytecode, invoke_closure_bytecode)                                         \
  V(Bytecode, invoke_field_bytecode)                                           \
  V(Bytecode, nsm_dispatcher_bytecode)                                         \
  V(Bytecode, dynamic_invocation_forwarder_bytecode)                           \
  V(Bytecode, implicit_static_closure_bytecode)                                \
  V(Bytecode, implicit_instance_closure_bytecode)                              \
  V(Bytecode, implicit_constructor_closure_bytecode)                           \
  V(Sentinel, sentinel)                                                        \
  V(Sentinel, unknown_constant)                                                \
  V(Sentinel, non_constant)                                                    \
  V(Sentinel, optimized_out)                                                   \
  V(Bool, bool_true)                                                           \
  V(Bool, bool_false)                                                          \
  V(Smi, smi_illegal_cid)                                                      \
  V(Smi, smi_zero)                                                             \
  V(ApiError, no_callbacks_error)                                              \
  V(UnwindError, unwind_error)                                                 \
  V(UnwindError, unwind_in_progress_error)                                     \
  V(LanguageError, snapshot_writer_error)                                      \
  V(LanguageError, branch_offset_error)                                        \
  V(LanguageError, background_compilation_error)                               \
  V(LanguageError, no_debuggable_code_error)                                   \
  V(LanguageError, out_of_memory_error)                                        \
  V(UnhandledException, unhandled_oom_exception)                               \
  V(Array, vm_isolate_snapshot_object_table)                                   \
  V(Type, dynamic_type)                                                        \
  V(Type, void_type)                                                           \
  V(AbstractType, null_abstract_type)                                          \
  V(TypedData, uninitialized_index)                                            \
  V(Array, uninitialized_data)

#define API_HANDLE_ROOTS_LIST(V)                                               \
  V(true_api_handle)                                                           \
  V(false_api_handle)                                                          \
  V(null_api_handle)                                                           \
  V(empty_string_api_handle)                                                   \
  V(no_callbacks_error_api_handle)                                             \
  V(unwind_in_progress_error_api_handle)

class AbstractType;
class ApiError;
class Array;
class Bool;
class Bytecode;
class Class;
class Closure;
class Code;
class CompressedStackMaps;
class ContextScope;
class ExceptionHandlers;
class Function;
class FunctionType;
class Instance;
class LanguageError;
class LocalVarDescriptors;
class Object;
class ObjectPool;
class PcDescriptors;
class RecordType;
class Sentinel;
class Smi;
class String;
class Type;
class TypeArguments;
class TypedData;
class UnhandledException;
class UnwindError;

class LocalHandle;
class ObjectPointerVisitor;

class Roots {
 public:
  Roots() {}
  ~Roots() {}

#define DECL(type, name)                                                       \
  static type name() { return current_->raw_.name##_; }                        \
  static void set_##name(type v) { current_->raw_.name##_ = v; }
  RAW_ROOTS_LIST(DECL)
#undef DECL

  static ArrayPtr cached_args_descriptor(intptr_t i) {
    return current_->raw_.cached_args_descriptors_[i];
  }
  static void set_cached_args_descriptor(intptr_t i, ArrayPtr v) {
    current_->raw_.cached_args_descriptors_[i] = v;
  }
  static ArrayPtr cached_icdata_array(intptr_t i) {
    return current_->raw_.cached_icdata_arrays_[i];
  }
  static void set_cached_icdata_array(intptr_t i, ArrayPtr v) {
    current_->raw_.cached_icdata_arrays_[i] = v;
  }
  static StringPtr one_char_symbol(intptr_t i) {
    return current_->raw_.one_char_symbols_[i];
  }
  static void set_one_char_symbol(intptr_t i, StringPtr v) {
    current_->raw_.one_char_symbols_[i] = v;
  }
  static StringPtr* one_char_symbols() {
    return &current_->raw_.one_char_symbols_[0];
  }

#define DECL(type, name)                                                       \
  static const type& name() {                                                  \
    return *reinterpret_cast<type*>(&current_->internal_.name##_);             \
  }
  HANDLE_ROOTS_LIST(DECL)
#undef DECL
  static const String& symbol_handle(intptr_t i) {
    return *reinterpret_cast<const String*>(
        &current_->internal_.symbol_handles_[i]);
  }
  static const Code& stub_handle(intptr_t i) {
    return *reinterpret_cast<const Code*>(
        &current_->internal_.stub_handles_[i]);
  }
  const Code& x_stub_handle(intptr_t i) {
    return *reinterpret_cast<const Code*>(&internal_.stub_handles_[i]);
  }

#define DECL(name)                                                             \
  static LocalHandle* name() {                                                 \
    return reinterpret_cast<LocalHandle*>(&current_->api_.name##_);            \
  }
  API_HANDLE_ROOTS_LIST(DECL)
#undef DECL

  static bool IsReadOnlyHandle(uword handle) {
    return handle - reinterpret_cast<uword>(&current_->internal_) <
           sizeof(Internal);
  }
  static bool IsReadOnlyApiHandle(uword handle) {
    return handle - reinterpret_cast<uword>(&current_->api_) < sizeof(Api);
  }

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  static Roots* Current() { return current_; }
  static void SetCurrent(Roots* roots) { current_ = roots; }
  static void ClearCurrent() { current_ = nullptr; }

 private:
  enum {
#define DEFINE_SYMBOL_INDEX(symbol, literal) k##symbol##Id,
    PREDEFINED_SYMBOLS_LIST(DEFINE_SYMBOL_INDEX)
#undef DEFINE_SYMBOL_INDEX
        kNumPredefinedSymbols,
  };
  enum {
#define STUB_CODE_ENTRY(name) k##name##Index,
    VM_STUB_CODE_LIST(STUB_CODE_ENTRY)
#undef STUB_CODE_ENTRY
        kNumStubEntries,
  };

  struct Raw {
#define DECL(type, name)                                                       \
  type name##_ = type{static_cast<uword>(kHeapObjectTag)};
    RAW_ROOTS_LIST(DECL)
#undef DECL
    ArrayPtr cached_args_descriptors_[35];
    ArrayPtr cached_icdata_arrays_[4];
    StringPtr one_char_symbols_[256];
  };
  Raw raw_;

  struct ApiHandle {
    uword ptr;
  };
  struct Api {
#define DECL(name) ApiHandle name##_ = {};
    API_HANDLE_ROOTS_LIST(DECL)
#undef DECL
  };
  Api api_;

  struct VMHandle {
    cpp_vtable vtable;
    ObjectPtr ptr = {nullptr};
#if defined(DEBUG)
    uword is_zone_handle = 0;
#endif
  };
  struct Internal {
#define DECL(type, name) VMHandle name##_ = {};
    HANDLE_ROOTS_LIST(DECL)
#undef DECL
    VMHandle symbol_handles_[kNumPredefinedSymbols + 256] = {};
    VMHandle stub_handles_[kNumStubEntries] = {};
  };
  Internal internal_ = {};

  static inline thread_local Roots* current_ = nullptr;

  // TODO(rmacnak): Re-enable after groups initialize separately.
  // DISALLOW_COPY_AND_ASSIGN(Roots);
};

}  // namespace dart

#endif  // RUNTIME_VM_ROOTS_H_
