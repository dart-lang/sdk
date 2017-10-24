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
  M(Internal, _internal)                                                       \
  M(Isolate, isolate)                                                          \
  M(Math, math)                                                                \
  M(Mirrors, mirrors)                                                          \
  M(Profiler, profiler)                                                        \
  M(TypedData, typed_data)                                                     \
  M(VMService, _vmservice)

#define OBJECT_STORE_FIELD_LIST(R_, RW)                                        \
  RW(Class, object_class)                                                      \
  RW(Type, object_type)                                                        \
  RW(Class, null_class)                                                        \
  RW(Type, null_type)                                                          \
  RW(Type, function_type)                                                      \
  RW(Type, type_type)                                                          \
  RW(Class, closure_class)                                                     \
  RW(Type, number_type)                                                        \
  RW(Type, int_type)                                                           \
  RW(Class, integer_implementation_class)                                      \
  RW(Type, int64_type)                                                         \
  RW(Class, smi_class)                                                         \
  RW(Type, smi_type)                                                           \
  RW(Class, mint_class)                                                        \
  RW(Type, mint_type)                                                          \
  RW(Class, bigint_class)                                                      \
  RW(Class, double_class)                                                      \
  RW(Type, double_type)                                                        \
  RW(Type, float32x4_type)                                                     \
  RW(Type, int32x4_type)                                                       \
  RW(Type, float64x2_type)                                                     \
  RW(Type, string_type)                                                        \
  RW(TypeArguments, type_argument_string)                                      \
  RW(TypeArguments, type_argument_int)                                         \
  RW(Class, compiletime_error_class)                                           \
  RW(Class, future_class)                                                      \
  RW(Class, completer_class)                                                   \
  RW(Class, stream_iterator_class)                                             \
  RW(Class, symbol_class)                                                      \
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
  RW(Class, linked_hash_map_class)                                             \
  RW(Class, float32x4_class)                                                   \
  RW(Class, int32x4_class)                                                     \
  RW(Class, float64x2_class)                                                   \
  RW(Class, error_class)                                                       \
  RW(Class, weak_property_class)                                               \
  RW(Array, symbol_table)                                                      \
  RW(Array, canonical_types)                                                   \
  RW(Array, canonical_type_arguments)                                          \
  RW(Library, async_library)                                                   \
  RW(Library, builtin_library)                                                 \
  RW(Library, core_library)                                                    \
  RW(Library, collection_library)                                              \
  RW(Library, convert_library)                                                 \
  RW(Library, developer_library)                                               \
  RW(Library, _internal_library)                                               \
  RW(Library, isolate_library)                                                 \
  RW(Library, math_library)                                                    \
  RW(Library, mirrors_library)                                                 \
  RW(Library, native_wrappers_library)                                         \
  RW(Library, profiler_library)                                                \
  RW(Library, root_library)                                                    \
  RW(Library, typed_data_library)                                              \
  RW(Library, _vmservice_library)                                              \
  RW(GrowableObjectArray, libraries)                                           \
  RW(Array, libraries_map)                                                     \
  RW(GrowableObjectArray, closure_functions)                                   \
  RW(GrowableObjectArray, pending_classes)                                     \
  R_(GrowableObjectArray, pending_deferred_loads)                              \
  R_(GrowableObjectArray, resume_capabilities)                                 \
  R_(GrowableObjectArray, exit_listeners)                                      \
  R_(GrowableObjectArray, error_listeners)                                     \
  RW(Instance, stack_overflow)                                                 \
  RW(Instance, out_of_memory)                                                  \
  RW(UnhandledException, preallocated_unhandled_exception)                     \
  RW(StackTrace, preallocated_stack_trace)                                     \
  RW(Function, lookup_port_handler)                                            \
  RW(TypedData, empty_uint32_array)                                            \
  RW(Function, handle_message_function)                                        \
  RW(Function, simple_instance_of_function)                                    \
  RW(Function, simple_instance_of_true_function)                               \
  RW(Function, simple_instance_of_false_function)                              \
  RW(Function, async_clear_thread_stack_trace)                                 \
  RW(Function, async_set_thread_stack_trace)                                   \
  RW(Function, async_star_move_next_helper)                                    \
  RW(Function, complete_on_async_return)                                       \
  RW(Class, async_star_stream_controller)                                      \
  RW(Array, library_load_error_table)                                          \
  RW(Array, unique_dynamic_targets)                                            \
  RW(GrowableObjectArray, token_objects)                                       \
  RW(Array, token_objects_map)                                                 \
  RW(GrowableObjectArray, megamorphic_cache_table)                             \
  R_(Code, megamorphic_miss_code)                                              \
  R_(Function, megamorphic_miss_function)                                      \
  RW(Array, obfuscation_map)                                                   \
  RW(GrowableObjectArray, changed_in_last_reload)                              \
// Please remember the last entry must be referred in the 'to' function below.

// The object store is a per isolate instance which stores references to
// objects used by the VM.
// TODO(iposva): Move the actual store into the object heap for quick handling
// by snapshots eventually.
class ObjectStore {
 public:
  enum BootstrapLibraryId {
#define MAKE_ID(Name, _) k##Name,

    FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_ID)
#undef MAKE_ID
  };

  ~ObjectStore();

#define DECLARE_GETTER(Type, name)                                             \
  Raw##Type* name() const { return name##_; }                                  \
  static intptr_t name##_offset() { return OFFSET_OF(ObjectStore, name##_); }
#define DECLARE_GETTER_AND_SETTER(Type, name)                                  \
  DECLARE_GETTER(Type, name)                                                   \
  void set_##name(const Type& value) { name##_ = value.raw(); }
  OBJECT_STORE_FIELD_LIST(DECLARE_GETTER, DECLARE_GETTER_AND_SETTER)
#undef DECLARE_GETTER
#undef DECLARE_GETTER_AND_SETTER

  RawLibrary* bootstrap_library(BootstrapLibraryId index) {
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
    name##_library_ = value.raw();                                             \
    break;

      FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_CASE)
#undef MAKE_CASE
      default:
        UNREACHABLE();
    }
  }

  void clear_pending_deferred_loads() {
    pending_deferred_loads_ = GrowableObjectArray::New();
  }

  void SetMegamorphicMissHandler(const Code& code, const Function& func) {
    // Hold onto the code so it is traced and not detached from the function.
    megamorphic_miss_code_ = code.raw();
    megamorphic_miss_function_ = func.raw();
  }

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Called to initialize objects required by the vm but which invoke
  // dart code.  If an error occurs the error object is returned otherwise
  // a null object is returned.
  RawError* PreallocateObjects();

  void InitKnownObjects();

  static void Init(Isolate* isolate);

#ifndef PRODUCT
  void PrintToJSONObject(JSONObject* jsobj);
#endif

 private:
  ObjectStore();

  // Finds a core library private method in Object.
  RawFunction* PrivateObjectLookup(const String& name);

  RawObject** from() { return reinterpret_cast<RawObject**>(&object_class_); }
#define DECLARE_OBJECT_STORE_FIELD(type, name) Raw##type* name##_;
  OBJECT_STORE_FIELD_LIST(DECLARE_OBJECT_STORE_FIELD,
                          DECLARE_OBJECT_STORE_FIELD)
#undef DECLARE_OBJECT_STORE_FIELD
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&changed_in_last_reload_);
  }
  RawObject** to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFull:
        return reinterpret_cast<RawObject**>(&library_load_error_table_);
      case Snapshot::kFullJIT:
      case Snapshot::kFullAOT:
        return reinterpret_cast<RawObject**>(&megamorphic_miss_function_);
      case Snapshot::kScript:
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }

  friend class Serializer;
  friend class Deserializer;

  DISALLOW_COPY_AND_ASSIGN(ObjectStore);
};

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_STORE_H_
