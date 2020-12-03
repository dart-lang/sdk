// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/raw_object_fields.h"

namespace dart {

#if defined(DART_PRECOMPILER) || !defined(DART_PRODUCT)

#define COMMON_CLASSES_AND_FIELDS(F)                                           \
  F(Class, name_)                                                              \
  F(Class, user_name_)                                                         \
  F(Class, functions_)                                                         \
  F(Class, functions_hash_table_)                                              \
  F(Class, fields_)                                                            \
  F(Class, offset_in_words_to_field_)                                          \
  F(Class, interfaces_)                                                        \
  F(Class, script_)                                                            \
  F(Class, library_)                                                           \
  F(Class, type_parameters_)                                                   \
  F(Class, super_type_)                                                        \
  F(Class, signature_function_)                                                \
  F(Class, constants_)                                                         \
  F(Class, declaration_type_)                                                  \
  F(Class, invocation_dispatcher_cache_)                                       \
  F(Class, allocation_stub_)                                                   \
  F(Class, direct_implementors_)                                               \
  F(Class, direct_subclasses_)                                                 \
  F(Class, dependent_code_)                                                    \
  F(PatchClass, patched_class_)                                                \
  F(PatchClass, origin_class_)                                                 \
  F(PatchClass, script_)                                                       \
  F(PatchClass, library_kernel_data_)                                          \
  F(Function, name_)                                                           \
  F(Function, owner_)                                                          \
  F(Function, result_type_)                                                    \
  F(Function, parameter_types_)                                                \
  F(Function, parameter_names_)                                                \
  F(Function, type_parameters_)                                                \
  F(Function, data_)                                                           \
  F(Function, ic_data_array_)                                                  \
  F(Function, code_)                                                           \
  F(ClosureData, context_scope_)                                               \
  F(ClosureData, parent_function_)                                             \
  F(ClosureData, signature_type_)                                              \
  F(ClosureData, closure_)                                                     \
  F(SignatureData, parent_function_)                                           \
  F(SignatureData, signature_type_)                                            \
  F(Field, name_)                                                              \
  F(Field, owner_)                                                             \
  F(Field, type_)                                                              \
  F(Field, guarded_list_length_)                                               \
  F(Field, dependent_code_)                                                    \
  F(Field, initializer_function_)                                              \
  F(Field, host_offset_or_field_id_)                                           \
  F(Script, url_)                                                              \
  F(Script, resolved_url_)                                                     \
  F(Script, compile_time_constants_)                                           \
  F(Script, line_starts_)                                                      \
  F(Script, debug_positions_)                                                  \
  F(Script, kernel_program_info_)                                              \
  F(Script, source_)                                                           \
  F(Library, name_)                                                            \
  F(Library, url_)                                                             \
  F(Library, private_key_)                                                     \
  F(Library, dictionary_)                                                      \
  F(Library, metadata_)                                                        \
  F(Library, toplevel_class_)                                                  \
  F(Library, used_scripts_)                                                    \
  F(Library, loading_unit_)                                                    \
  F(Library, imports_)                                                         \
  F(Library, exports_)                                                         \
  F(Library, kernel_data_)                                                     \
  F(Library, resolved_names_)                                                  \
  F(Library, exported_names_)                                                  \
  F(Library, loaded_scripts_)                                                  \
  F(Namespace, target_)                                                        \
  F(Namespace, show_names_)                                                    \
  F(Namespace, hide_names_)                                                    \
  F(Namespace, owner_)                                                         \
  F(KernelProgramInfo, string_offsets_)                                        \
  F(KernelProgramInfo, string_data_)                                           \
  F(KernelProgramInfo, canonical_names_)                                       \
  F(KernelProgramInfo, metadata_payloads_)                                     \
  F(KernelProgramInfo, metadata_mappings_)                                     \
  F(KernelProgramInfo, scripts_)                                               \
  F(KernelProgramInfo, constants_)                                             \
  F(KernelProgramInfo, potential_natives_)                                     \
  F(KernelProgramInfo, potential_pragma_functions_)                            \
  F(KernelProgramInfo, constants_table_)                                       \
  F(KernelProgramInfo, libraries_cache_)                                       \
  F(KernelProgramInfo, classes_cache_)                                         \
  F(KernelProgramInfo, retained_kernel_blob_)                                  \
  F(Code, object_pool_)                                                        \
  F(Code, instructions_)                                                       \
  F(Code, owner_)                                                              \
  F(Code, exception_handlers_)                                                 \
  F(Code, pc_descriptors_)                                                     \
  F(Code, catch_entry_)                                                        \
  F(Code, compressed_stackmaps_)                                               \
  F(Code, inlined_id_to_function_)                                             \
  F(Code, code_source_map_)                                                    \
  F(ExceptionHandlers, handled_types_data_)                                    \
  F(Context, parent_)                                                          \
  F(SingleTargetCache, target_)                                                \
  F(UnlinkedCall, target_name_)                                                \
  F(UnlinkedCall, args_descriptor_)                                            \
  F(MonomorphicSmiableCall, expected_cid_)                                     \
  F(MonomorphicSmiableCall, target_)                                           \
  F(CallSiteData, target_name_)                                                \
  F(CallSiteData, args_descriptor_)                                            \
  F(ICData, entries_)                                                          \
  F(ICData, owner_)                                                            \
  F(MegamorphicCache, buckets_)                                                \
  F(MegamorphicCache, mask_)                                                   \
  F(SubtypeTestCache, cache_)                                                  \
  F(LoadingUnit, parent_)                                                      \
  F(LoadingUnit, base_objects_)                                                \
  F(ApiError, message_)                                                        \
  F(LanguageError, previous_error_)                                            \
  F(LanguageError, script_)                                                    \
  F(LanguageError, message_)                                                   \
  F(LanguageError, formatted_message_)                                         \
  F(UnhandledException, exception_)                                            \
  F(UnhandledException, stacktrace_)                                           \
  F(UnwindError, message_)                                                     \
  F(LibraryPrefix, name_)                                                      \
  F(LibraryPrefix, importer_)                                                  \
  F(LibraryPrefix, imports_)                                                   \
  F(TypeArguments, instantiations_)                                            \
  F(TypeArguments, length_)                                                    \
  F(TypeArguments, hash_)                                                      \
  F(TypeArguments, nullability_)                                               \
  F(AbstractType, type_test_stub_)                                             \
  F(Type, type_test_stub_)                                                     \
  F(Type, type_class_id_)                                                      \
  F(Type, arguments_)                                                          \
  F(Type, hash_)                                                               \
  F(Type, signature_)                                                          \
  F(TypeRef, type_test_stub_)                                                  \
  F(TypeRef, type_)                                                            \
  F(TypeParameter, type_test_stub_)                                            \
  F(TypeParameter, name_)                                                      \
  F(TypeParameter, hash_)                                                      \
  F(TypeParameter, bound_)                                                     \
  F(TypeParameter, parameterized_function_)                                    \
  F(Closure, instantiator_type_arguments_)                                     \
  F(Closure, function_type_arguments_)                                         \
  F(Closure, delayed_type_arguments_)                                          \
  F(Closure, function_)                                                        \
  F(Closure, context_)                                                         \
  F(Closure, hash_)                                                            \
  F(String, length_)                                                           \
  F(Array, type_arguments_)                                                    \
  F(Array, length_)                                                            \
  F(GrowableObjectArray, type_arguments_)                                      \
  F(GrowableObjectArray, length_)                                              \
  F(GrowableObjectArray, data_)                                                \
  F(LinkedHashMap, type_arguments_)                                            \
  F(LinkedHashMap, index_)                                                     \
  F(LinkedHashMap, hash_mask_)                                                 \
  F(LinkedHashMap, data_)                                                      \
  F(LinkedHashMap, used_data_)                                                 \
  F(LinkedHashMap, deleted_keys_)                                              \
  F(TypedData, length_)                                                        \
  F(ExternalTypedData, length_)                                                \
  F(ReceivePort, send_port_)                                                   \
  F(ReceivePort, handler_)                                                     \
  F(StackTrace, async_link_)                                                   \
  F(StackTrace, code_array_)                                                   \
  F(StackTrace, pc_offset_array_)                                              \
  F(RegExp, num_bracket_expressions_)                                          \
  F(RegExp, capture_name_map_)                                                 \
  F(RegExp, pattern_)                                                          \
  F(RegExp, one_byte_)                                                         \
  F(RegExp, two_byte_)                                                         \
  F(RegExp, external_one_byte_)                                                \
  F(RegExp, external_two_byte_)                                                \
  F(RegExp, one_byte_sticky_)                                                  \
  F(RegExp, two_byte_sticky_)                                                  \
  F(RegExp, external_one_byte_sticky_)                                         \
  F(RegExp, external_two_byte_sticky_)                                         \
  F(WeakProperty, key_)                                                        \
  F(WeakProperty, value_)                                                      \
  F(MirrorReference, referent_)                                                \
  F(UserTag, label_)                                                           \
  F(PointerBase, data_)                                                        \
  F(Pointer, type_arguments_)                                                  \
  F(DynamicLibrary, handle_)                                                   \
  F(FfiTrampolineData, signature_type_)                                        \
  F(FfiTrampolineData, c_signature_)                                           \
  F(FfiTrampolineData, callback_target_)                                       \
  F(FfiTrampolineData, callback_exceptional_return_)                           \
  F(TypedDataBase, length_)                                                    \
  F(TypedDataView, typed_data_)                                                \
  F(TypedDataView, offset_in_bytes_)                                           \
  F(FutureOr, type_arguments_)

#define AOT_CLASSES_AND_FIELDS(F) F(WeakSerializationReference, cid_)

#define JIT_CLASSES_AND_FIELDS(F)                                              \
  F(Code, active_instructions_)                                                \
  F(Code, deopt_info_array_)                                                   \
  F(Code, static_calls_target_table_)                                          \
  F(ICData, receivers_static_type_)                                            \
  F(Function, unoptimized_code_)                                               \
  F(Field, type_test_cache_)                                                   \
  F(WeakSerializationReference, target_)

#define NON_PRODUCT_CLASSES_AND_FIELDS(F)                                      \
  F(ReceivePort, debug_name_)                                                  \
  F(ReceivePort, allocation_location_)

#define NON_HEADER_HASH_CLASSES_AND_FIELDS(F) F(String, hash_)

OffsetsTable::OffsetsTable(Zone* zone) : cached_offsets_(zone) {
  for (intptr_t i = 0; offsets_table[i].class_id != -1; ++i) {
    OffsetsTableEntry entry = offsets_table[i];
    cached_offsets_.Insert({{entry.class_id, entry.offset}, entry.field_name});
  }
}

const char* OffsetsTable::FieldNameForOffset(intptr_t class_id,
                                             intptr_t offset) {
  return cached_offsets_.LookupValue({class_id, offset});
}

#define DEFINE_OFFSETS_TABLE_ENTRY(class_name, field_name)                     \
  {class_name::kClassId, #field_name,                                          \
   OFFSET_OF(class_name##Layout, field_name)},

// clang-format off
OffsetsTable::OffsetsTableEntry OffsetsTable::offsets_table[] = {
    COMMON_CLASSES_AND_FIELDS(DEFINE_OFFSETS_TABLE_ENTRY)
#if !defined(PRODUCT)
    NON_PRODUCT_CLASSES_AND_FIELDS(DEFINE_OFFSETS_TABLE_ENTRY)
#endif

#if !defined(HASH_IN_OBJECT_HEADER)
    NON_HEADER_HASH_CLASSES_AND_FIELDS(DEFINE_OFFSETS_TABLE_ENTRY)
#endif

#if defined(DART_PRECOMPILED_RUNTIME)
    AOT_CLASSES_AND_FIELDS(DEFINE_OFFSETS_TABLE_ENTRY)
#else
    JIT_CLASSES_AND_FIELDS(DEFINE_OFFSETS_TABLE_ENTRY)
#endif
    {-1, nullptr, -1}
};
// clang-format on

#undef DEFINE_OFFSETS_TABLE_ENTRY

#endif

}  // namespace dart
