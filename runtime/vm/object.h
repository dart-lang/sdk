// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OBJECT_H_
#define RUNTIME_VM_OBJECT_H_

#if defined(SHOULD_NOT_INCLUDE_RUNTIME)
#error "Should not include runtime"
#endif

#include <limits>
#include <tuple>
#include <utility>

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/atomic.h"
#include "platform/thread_sanitizer.h"
#include "platform/utils.h"
#include "vm/bitmap.h"
#include "vm/code_comments.h"
#include "vm/code_entry_kind.h"
#include "vm/compiler/assembler/object_pool_builder.h"
#include "vm/compiler/method_recognizer.h"
#include "vm/compiler/runtime_api.h"
#include "vm/dart.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/handles.h"
#include "vm/heap/heap.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/os.h"
#include "vm/raw_object.h"
#include "vm/report.h"
#include "vm/static_type_exactness_state.h"
#include "vm/thread.h"
#include "vm/token_position.h"

namespace dart {

// Forward declarations.
namespace compiler {
class Assembler;
}

namespace kernel {
class Program;
class TreeNode;
}  // namespace kernel

#define DEFINE_FORWARD_DECLARATION(clazz) class clazz;
CLASS_LIST(DEFINE_FORWARD_DECLARATION)
#undef DEFINE_FORWARD_DECLARATION
class Api;
class ArgumentsDescriptor;
class Closure;
class Code;
class DeoptInstr;
class DisassemblyFormatter;
class FinalizablePersistentHandle;
class FlowGraphCompiler;
class HierarchyInfo;
class LocalScope;
class CallSiteResetter;
class CodeStatistics;
class IsolateGroupReloadContext;
class ObjectGraphCopier;
class FunctionTypeMapping;
class NativeArguments;

#define REUSABLE_FORWARD_DECLARATION(name) class Reusable##name##HandleScope;
REUSABLE_HANDLE_LIST(REUSABLE_FORWARD_DECLARATION)
#undef REUSABLE_FORWARD_DECLARATION

class Symbols;
class BaseTextBuffer;

#if defined(DEBUG)
#define CHECK_HANDLE() CheckHandle();
#else
#define CHECK_HANDLE()
#endif

// For AllStatic classes like OneByteString. Checks that
// ContainsCompressedPointers() returns the same value for AllStatic class and
// class used for handles.
#define ALLSTATIC_CONTAINS_COMPRESSED_IMPLEMENTATION(object, handle)           \
 public: /* NOLINT */                                                          \
  using UntaggedObjectType = dart::Untagged##object;                           \
  using ObjectPtrType = dart::object##Ptr;                                     \
  static_assert(std::is_base_of<dart::handle##Ptr, ObjectPtrType>::value,      \
                #object "Ptr must be a subtype of " #handle "Ptr");            \
  static_assert(dart::handle::ContainsCompressedPointers() ==                  \
                    UntaggedObjectType::kContainsCompressedPointers,           \
                "Pointer compression in Untagged" #object                      \
                " must match pointer compression in Untagged" #handle);        \
  static constexpr bool ContainsCompressedPointers() {                         \
    return UntaggedObjectType::kContainsCompressedPointers;                    \
  }                                                                            \
                                                                               \
 private: /* NOLINT */

#define BASE_OBJECT_IMPLEMENTATION(object, super)                              \
 public: /* NOLINT */                                                          \
  using UntaggedObjectType = dart::Untagged##object;                           \
  using ObjectPtrType = dart::object##Ptr;                                     \
  static_assert(!dart::super::ContainsCompressedPointers() ||                  \
                    UntaggedObjectType::kContainsCompressedPointers,           \
                "Untagged" #object                                             \
                " must have compressed pointers, as supertype Untagged" #super \
                " has compressed pointers");                                   \
  static constexpr bool ContainsCompressedPointers() {                         \
    return UntaggedObjectType::kContainsCompressedPointers;                    \
  }                                                                            \
  object##Ptr ptr() const {                                                    \
    return static_cast<object##Ptr>(ptr_);                                     \
  }                                                                            \
  bool Is##object() const {                                                    \
    return true;                                                               \
  }                                                                            \
  DART_NOINLINE static object& Handle() {                                      \
    return static_cast<object&>(                                               \
        HandleImpl(Thread::Current()->zone(), object::null(), kClassId));      \
  }                                                                            \
  DART_NOINLINE static object& Handle(Zone* zone) {                            \
    return static_cast<object&>(HandleImpl(zone, object::null(), kClassId));   \
  }                                                                            \
  DART_NOINLINE static object& Handle(object##Ptr ptr) {                       \
    return static_cast<object&>(                                               \
        HandleImpl(Thread::Current()->zone(), ptr, kClassId));                 \
  }                                                                            \
  DART_NOINLINE static object& Handle(Zone* zone, object##Ptr ptr) {           \
    return static_cast<object&>(HandleImpl(zone, ptr, kClassId));              \
  }                                                                            \
  DART_NOINLINE static object& ZoneHandle() {                                  \
    return static_cast<object&>(                                               \
        ZoneHandleImpl(Thread::Current()->zone(), object::null(), kClassId));  \
  }                                                                            \
  DART_NOINLINE static object& ZoneHandle(Zone* zone) {                        \
    return static_cast<object&>(                                               \
        ZoneHandleImpl(zone, object::null(), kClassId));                       \
  }                                                                            \
  DART_NOINLINE static object& ZoneHandle(object##Ptr ptr) {                   \
    return static_cast<object&>(                                               \
        ZoneHandleImpl(Thread::Current()->zone(), ptr, kClassId));             \
  }                                                                            \
  DART_NOINLINE static object& ZoneHandle(Zone* zone, object##Ptr ptr) {       \
    return static_cast<object&>(ZoneHandleImpl(zone, ptr, kClassId));          \
  }                                                                            \
  static object* ReadOnlyHandle() {                                            \
    return static_cast<object*>(ReadOnlyHandleImpl(kClassId));                 \
  }                                                                            \
  DART_NOINLINE static object& CheckedHandle(Zone* zone, ObjectPtr ptr) {      \
    object* obj = reinterpret_cast<object*>(VMHandles::AllocateHandle(zone));  \
    initializeHandle(obj, ptr);                                                \
    if (!obj->Is##object()) {                                                  \
      FATAL("Handle check failed: saw %s expected %s", obj->ToCString(),       \
            #object);                                                          \
    }                                                                          \
    return *obj;                                                               \
  }                                                                            \
  DART_NOINLINE static object& CheckedZoneHandle(Zone* zone, ObjectPtr ptr) {  \
    object* obj =                                                              \
        reinterpret_cast<object*>(VMHandles::AllocateZoneHandle(zone));        \
    initializeHandle(obj, ptr);                                                \
    if (!obj->Is##object()) {                                                  \
      FATAL("Handle check failed: saw %s expected %s", obj->ToCString(),       \
            #object);                                                          \
    }                                                                          \
    return *obj;                                                               \
  }                                                                            \
  DART_NOINLINE static object& CheckedZoneHandle(ObjectPtr ptr) {              \
    return CheckedZoneHandle(Thread::Current()->zone(), ptr);                  \
  }                                                                            \
  /* T::Cast cannot be applied to a null Object, because the object vtable */  \
  /* is not setup for type T, although some methods are supposed to work   */  \
  /* with null, for example Instance::Equals().                            */  \
  static const object& Cast(const Object& obj) {                               \
    ASSERT(obj.Is##object());                                                  \
    return reinterpret_cast<const object&>(obj);                               \
  }                                                                            \
  static object##Ptr RawCast(ObjectPtr raw) {                                  \
    ASSERT(Is##object##NoHandle(raw));                                         \
    return static_cast<object##Ptr>(raw);                                      \
  }                                                                            \
  static object##Ptr null() {                                                  \
    return static_cast<object##Ptr>(Object::null());                           \
  }                                                                            \
  virtual const char* ToCString() const;                                       \
  static const ClassId kClassId = k##object##Cid;                              \
                                                                               \
 private: /* NOLINT */                                                         \
  /* Initialize the handle based on the ptr in the presence of null. */        \
  static void initializeHandle(object* obj, ObjectPtr ptr) {                   \
    obj->setPtr(ptr, kClassId);                                                \
  }                                                                            \
  /* Disallow allocation, copy constructors and override super assignment. */  \
 public: /* NOLINT */                                                          \
  void operator delete(void* pointer) {                                        \
    UNREACHABLE();                                                             \
  }                                                                            \
                                                                               \
 private: /* NOLINT */                                                         \
  void* operator new(size_t size);                                             \
  object(const object& value) = delete;                                        \
  void operator=(super##Ptr value) = delete;                                   \
  void operator=(const object& value) = delete;                                \
  void operator=(const super& value) = delete;

// Conditionally include object_service.cc functionality in the vtable to avoid
// link errors like the following:
//
// object.o:(.rodata._ZTVN4....E[_ZTVN4...E]+0x278):
// undefined reference to
// `dart::Instance::PrintSharedInstanceJSON(dart::JSONObject*, bool) const'.
//
#ifndef PRODUCT
#define OBJECT_SERVICE_SUPPORT(object)                                         \
 protected: /* NOLINT */                                                       \
  /* Object is printed as JSON into stream. If ref is true only a header */    \
  /* with an object id is printed. If ref is false the object is fully   */    \
  /* printed.                                                            */    \
  virtual void PrintJSONImpl(JSONStream* stream, bool ref) const;              \
  /* Prints JSON objects that describe the implementation-level fields of */   \
  /* the current Object to |jsarr_fields|.                                */   \
  virtual void PrintImplementationFieldsImpl(const JSONArray& jsarr_fields)    \
      const;                                                                   \
  virtual const char* JSONType() const {                                       \
    return "" #object;                                                         \
  }
#else
#define OBJECT_SERVICE_SUPPORT(object) protected: /* NOLINT */
#endif                                            // !PRODUCT

#define SNAPSHOT_SUPPORT(object)                                               \
  friend class object##MessageSerializationCluster;                            \
  friend class object##MessageDeserializationCluster;

#define OBJECT_IMPLEMENTATION(object, super)                                   \
 public: /* NOLINT */                                                          \
  DART_NOINLINE void operator=(object##Ptr value) {                            \
    initializeHandle(this, value);                                             \
  }                                                                            \
  DART_NOINLINE void operator^=(ObjectPtr value) {                             \
    initializeHandle(this, value);                                             \
    ASSERT(IsNull() || Is##object());                                          \
  }                                                                            \
                                                                               \
 protected: /* NOLINT */                                                       \
  object() : super() {}                                                        \
  BASE_OBJECT_IMPLEMENTATION(object, super)                                    \
  OBJECT_SERVICE_SUPPORT(object)                                               \
  friend class Object;

extern "C" void DFLRT_ExitSafepoint(NativeArguments __unusable_);

#define HEAP_OBJECT_IMPLEMENTATION(object, super)                              \
  OBJECT_IMPLEMENTATION(object, super);                                        \
  Untagged##object* untag() const {                                            \
    ASSERT(ptr() != null());                                                   \
    return const_cast<Untagged##object*>(ptr()->untag());                      \
  }                                                                            \
  SNAPSHOT_SUPPORT(object)                                                     \
  friend class StackFrame;                                                     \
  friend class Thread;                                                         \
  friend void DFLRT_ExitSafepoint(NativeArguments __unusable_);

// This macro is used to denote types that do not have a sub-type.
#define FINAL_HEAP_OBJECT_IMPLEMENTATION_HELPER(object, rettype, super)        \
 public: /* NOLINT */                                                          \
  void operator=(object##Ptr value) {                                          \
    ptr_ = value;                                                              \
    CHECK_HANDLE();                                                            \
  }                                                                            \
  void operator^=(ObjectPtr value) {                                           \
    ptr_ = value;                                                              \
    CHECK_HANDLE();                                                            \
  }                                                                            \
                                                                               \
 private: /* NOLINT */                                                         \
  object() : super() {}                                                        \
  BASE_OBJECT_IMPLEMENTATION(object, super)                                    \
  OBJECT_SERVICE_SUPPORT(object)                                               \
  Untagged##object* untag() const {                                            \
    ASSERT(ptr() != null());                                                   \
    return const_cast<Untagged##object*>(ptr()->untag());                      \
  }                                                                            \
  static intptr_t NextFieldOffset() { return -kWordSize; }                     \
  SNAPSHOT_SUPPORT(rettype)                                                    \
  friend class Object;                                                         \
  friend class StackFrame;                                                     \
  friend class Thread;                                                         \
  friend void DFLRT_ExitSafepoint(NativeArguments __unusable_);

#define FINAL_HEAP_OBJECT_IMPLEMENTATION(object, super)                        \
  FINAL_HEAP_OBJECT_IMPLEMENTATION_HELPER(object, object, super)

#define MINT_OBJECT_IMPLEMENTATION(object, rettype, super)                     \
  FINAL_HEAP_OBJECT_IMPLEMENTATION_HELPER(object, rettype, super)

// In precompiled runtime, there is no access to runtime_api.cc since host
// and target are the same. In those cases, the namespace dart is used to refer
// to the target namespace
#if defined(DART_PRECOMPILED_RUNTIME)
namespace RTN = dart;
#else
namespace RTN = dart::compiler::target;
#endif  //  defined(DART_PRECOMPILED_RUNTIME)

class Object {
 public:
  using UntaggedObjectType = UntaggedObject;
  using ObjectPtrType = ObjectPtr;

  // We use 30 bits for the hash code so hashes in a snapshot taken on a
  // 64-bit architecture stay in Smi range when loaded on a 32-bit
  // architecture.
  static constexpr intptr_t kHashBits = 30;

  static ObjectPtr RawCast(ObjectPtr obj) { return obj; }

  virtual ~Object() {}

  static constexpr bool ContainsCompressedPointers() {
    return UntaggedObject::kContainsCompressedPointers;
  }
  ObjectPtr ptr() const { return ptr_; }
  void operator=(ObjectPtr value) { initializeHandle(this, value); }

  bool IsCanonical() const { return ptr()->untag()->IsCanonical(); }
  void SetCanonical() const { ptr()->untag()->SetCanonical(); }
  void ClearCanonical() const { ptr()->untag()->ClearCanonical(); }
  bool IsImmutable() const { return ptr()->untag()->IsImmutable(); }
  void SetImmutable() const { ptr()->untag()->SetImmutable(); }
  void ClearImmutable() const { ptr()->untag()->ClearImmutable(); }
  intptr_t GetClassId() const {
    return !ptr()->IsHeapObject() ? static_cast<intptr_t>(kSmiCid)
                                  : ptr()->untag()->GetClassId();
  }
  inline ClassPtr clazz() const;
  static intptr_t tags_offset() { return OFFSET_OF(UntaggedObject, tags_); }

// Class testers.
#define DEFINE_CLASS_TESTER(clazz)                                             \
  virtual bool Is##clazz() const { return false; }                             \
  static bool Is##clazz##NoHandle(ObjectPtr ptr) {                             \
    /* Use a stack handle to make RawCast safe in contexts where handles   */  \
    /* should not be allocated, such as GC or runtime transitions. Not     */  \
    /* using Object's constructor to avoid Is##clazz being de-virtualized. */  \
    char buf[sizeof(Object)];                                                  \
    Object* obj = reinterpret_cast<Object*>(&buf);                             \
    initializeHandle(obj, ptr);                                                \
    return obj->IsNull() || obj->Is##clazz();                                  \
  }
  CLASS_LIST_FOR_HANDLES(DEFINE_CLASS_TESTER);
#undef DEFINE_CLASS_TESTER

  bool IsNull() const { return ptr_ == null_; }

  // Matches Object.toString on instances (except String::ToCString, bug 20583).
  virtual const char* ToCString() const {
    if (IsNull()) {
      return "null";
    } else {
      return "Object";
    }
  }

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream, bool ref = true) const;
  virtual void PrintJSONImpl(JSONStream* stream, bool ref) const;
  void PrintImplementationFields(JSONStream* stream) const;
  virtual void PrintImplementationFieldsImpl(
      const JSONArray& jsarr_fields) const;
  virtual const char* JSONType() const { return IsNull() ? "null" : "Object"; }
#endif

  // Returns the name that is used to identify an object in the
  // namespace dictionary.
  // Object::DictionaryName() returns String::null(). Only subclasses
  // of Object that need to be entered in the library and library prefix
  // namespaces need to provide an implementation.
  virtual StringPtr DictionaryName() const;

  bool IsNew() const { return ptr()->IsNewObject(); }
  bool IsOld() const { return ptr()->IsOldObject(); }
#if defined(DEBUG)
  bool InVMIsolateHeap() const;
#else
  bool InVMIsolateHeap() const { return ptr()->untag()->InVMIsolateHeap(); }
#endif  // DEBUG

  // Print the object on stdout for debugging.
  void Print() const;

#if defined(DEBUG)
  bool IsZoneHandle() const;
  bool IsReadOnlyHandle() const;
  bool IsNotTemporaryScopedHandle() const;
#endif

  static Object& Handle() {
    return HandleImpl(Thread::Current()->zone(), null_, kObjectCid);
  }
  static Object& Handle(Zone* zone) {
    return HandleImpl(zone, null_, kObjectCid);
  }
  static Object& Handle(ObjectPtr ptr) {
    return HandleImpl(Thread::Current()->zone(), ptr, kObjectCid);
  }
  static Object& Handle(Zone* zone, ObjectPtr ptr) {
    return HandleImpl(zone, ptr, kObjectCid);
  }
  static Object& ZoneHandle() {
    return ZoneHandleImpl(Thread::Current()->zone(), null_, kObjectCid);
  }
  static Object& ZoneHandle(Zone* zone) {
    return ZoneHandleImpl(zone, null_, kObjectCid);
  }
  static Object& ZoneHandle(ObjectPtr ptr) {
    return ZoneHandleImpl(Thread::Current()->zone(), ptr, kObjectCid);
  }
  static Object& ZoneHandle(Zone* zone, ObjectPtr ptr) {
    return ZoneHandleImpl(zone, ptr, kObjectCid);
  }
  static Object* ReadOnlyHandle() { return ReadOnlyHandleImpl(kObjectCid); }

  static ObjectPtr null() { return null_; }

#if defined(HASH_IN_OBJECT_HEADER)
  static uint32_t GetCachedHash(const ObjectPtr obj) {
    return obj->untag()->GetHeaderHash();
  }

  static uint32_t SetCachedHashIfNotSet(ObjectPtr obj, uint32_t hash) {
    return obj->untag()->SetHeaderHashIfNotSet(hash);
  }
#endif

  // The list below enumerates read-only handles for singleton
  // objects that are shared between the different isolates.
  //
  // - sentinel is a value that cannot be produced by Dart code. It can be used
  // to mark special values, for example to distinguish "uninitialized" fields.
  // - transition_sentinel is a value marking that we are transitioning from
  // sentinel, e.g., computing a field value. Used to detect circular
  // initialization.
  // - unknown_constant and non_constant are optimizing compiler's constant
  // propagation constants.
  // - optimized_out results from deopt environment pruning or failure to
  // capture variables in a closure's context
#define SHARED_READONLY_HANDLES_LIST(V)                                        \
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
  V(ContextScope, empty_context_scope)                                         \
  V(ObjectPool, empty_object_pool)                                             \
  V(CompressedStackMaps, empty_compressed_stackmaps)                           \
  V(PcDescriptors, empty_descriptors)                                          \
  V(LocalVarDescriptors, empty_var_descriptors)                                \
  V(ExceptionHandlers, empty_exception_handlers)                               \
  V(ExceptionHandlers, empty_async_exception_handlers)                         \
  V(Array, synthetic_getter_parameter_types)                                   \
  V(Array, synthetic_getter_parameter_names)                                   \
  V(Sentinel, sentinel)                                                        \
  V(Sentinel, transition_sentinel)                                             \
  V(Sentinel, unknown_constant)                                                \
  V(Sentinel, non_constant)                                                    \
  V(Sentinel, optimized_out)                                                   \
  V(Bool, bool_true)                                                           \
  V(Bool, bool_false)                                                          \
  V(Smi, smi_illegal_cid)                                                      \
  V(Smi, smi_zero)                                                             \
  V(ApiError, no_callbacks_error)                                              \
  V(UnwindError, unwind_in_progress_error)                                     \
  V(LanguageError, snapshot_writer_error)                                      \
  V(LanguageError, branch_offset_error)                                        \
  V(LanguageError, speculative_inlining_error)                                 \
  V(LanguageError, background_compilation_error)                               \
  V(LanguageError, out_of_memory_error)                                        \
  V(Array, vm_isolate_snapshot_object_table)                                   \
  V(Type, dynamic_type)                                                        \
  V(Type, void_type)                                                           \
  V(AbstractType, null_abstract_type)

#define DEFINE_SHARED_READONLY_HANDLE_GETTER(Type, name)                       \
  static const Type& name() {                                                  \
    ASSERT(name##_ != nullptr);                                                \
    return *name##_;                                                           \
  }
  SHARED_READONLY_HANDLES_LIST(DEFINE_SHARED_READONLY_HANDLE_GETTER)
#undef DEFINE_SHARED_READONLY_HANDLE_GETTER

  static void set_vm_isolate_snapshot_object_table(const Array& table);

  static ClassPtr class_class() { return class_class_; }
  static ClassPtr dynamic_class() { return dynamic_class_; }
  static ClassPtr void_class() { return void_class_; }
  static ClassPtr type_parameters_class() { return type_parameters_class_; }
  static ClassPtr type_arguments_class() { return type_arguments_class_; }
  static ClassPtr patch_class_class() { return patch_class_class_; }
  static ClassPtr function_class() { return function_class_; }
  static ClassPtr closure_data_class() { return closure_data_class_; }
  static ClassPtr ffi_trampoline_data_class() {
    return ffi_trampoline_data_class_;
  }
  static ClassPtr field_class() { return field_class_; }
  static ClassPtr script_class() { return script_class_; }
  static ClassPtr library_class() { return library_class_; }
  static ClassPtr namespace_class() { return namespace_class_; }
  static ClassPtr kernel_program_info_class() {
    return kernel_program_info_class_;
  }
  static ClassPtr code_class() { return code_class_; }
  static ClassPtr instructions_class() { return instructions_class_; }
  static ClassPtr instructions_section_class() {
    return instructions_section_class_;
  }
  static ClassPtr instructions_table_class() {
    return instructions_table_class_;
  }
  static ClassPtr object_pool_class() { return object_pool_class_; }
  static ClassPtr pc_descriptors_class() { return pc_descriptors_class_; }
  static ClassPtr code_source_map_class() { return code_source_map_class_; }
  static ClassPtr compressed_stackmaps_class() {
    return compressed_stackmaps_class_;
  }
  static ClassPtr var_descriptors_class() { return var_descriptors_class_; }
  static ClassPtr exception_handlers_class() {
    return exception_handlers_class_;
  }
  static ClassPtr context_class() { return context_class_; }
  static ClassPtr context_scope_class() { return context_scope_class_; }
  static ClassPtr sentinel_class() { return sentinel_class_; }
  static ClassPtr api_error_class() { return api_error_class_; }
  static ClassPtr language_error_class() { return language_error_class_; }
  static ClassPtr unhandled_exception_class() {
    return unhandled_exception_class_;
  }
  static ClassPtr unwind_error_class() { return unwind_error_class_; }
  static ClassPtr singletargetcache_class() { return singletargetcache_class_; }
  static ClassPtr unlinkedcall_class() { return unlinkedcall_class_; }
  static ClassPtr monomorphicsmiablecall_class() {
    return monomorphicsmiablecall_class_;
  }
  static ClassPtr icdata_class() { return icdata_class_; }
  static ClassPtr megamorphic_cache_class() { return megamorphic_cache_class_; }
  static ClassPtr subtypetestcache_class() { return subtypetestcache_class_; }
  static ClassPtr loadingunit_class() { return loadingunit_class_; }
  static ClassPtr weak_serialization_reference_class() {
    return weak_serialization_reference_class_;
  }
  static ClassPtr weak_array_class() { return weak_array_class_; }

  // Initialize the VM isolate.
  static void InitNullAndBool(IsolateGroup* isolate_group);
  static void Init(IsolateGroup* isolate_group);
  static void InitVtables();
  static void FinishInit(IsolateGroup* isolate_group);
  static void FinalizeVMIsolate(IsolateGroup* isolate_group);
  static void FinalizeReadOnlyObject(ObjectPtr object);

  static void Cleanup();

  // Initialize a new isolate either from a Kernel IR, from source, or from a
  // snapshot.
  static ErrorPtr Init(IsolateGroup* isolate_group,
                       const uint8_t* kernel_buffer,
                       intptr_t kernel_buffer_size);

  static void MakeUnusedSpaceTraversable(const Object& obj,
                                         intptr_t original_size,
                                         intptr_t used_size);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedObject));
  }

  template <class FakeObject>
  static void VerifyBuiltinVtable(intptr_t cid) {
    FakeObject fake;
    if (cid >= kNumPredefinedCids) {
      cid = kInstanceCid;
    }
    ASSERT(builtin_vtables_[cid] == fake.vtable());
  }
  static void VerifyBuiltinVtables();

  static const ClassId kClassId = kObjectCid;

  // Different kinds of name visibility.
  enum NameVisibility {
    // Internal names are the true names of classes, fields,
    // etc. inside the vm.  These names include privacy suffixes,
    // getter prefixes, and trailing dots on unnamed constructors.
    //
    // The names of core implementation classes (like _OneByteString)
    // are preserved as well.
    //
    // e.g.
    //   private getter             -> get:foo@6be832b
    //   private constructor        -> _MyClass@6b3832b.
    //   private named constructor  -> _MyClass@6b3832b.named
    //   core impl class name shown -> _OneByteString
    kInternalName = 0,

    // Scrubbed names drop privacy suffixes, getter prefixes, and
    // trailing dots on unnamed constructors.  These names are used in
    // the vm service.
    //
    // e.g.
    //   get:foo@6be832b        -> foo
    //   _MyClass@6b3832b.      -> _MyClass
    //   _MyClass@6b3832b.named -> _MyClass.named
    //   _OneByteString         -> _OneByteString (not remapped)
    kScrubbedName,

    // User visible names are appropriate for reporting type errors
    // directly to programmers.  The names have been scrubbed and
    // the names of core implementation classes are remapped to their
    // public interface names.
    //
    // e.g.
    //   get:foo@6be832b        -> foo
    //   _MyClass@6b3832b.      -> _MyClass
    //   _MyClass@6b3832b.named -> _MyClass.named
    //   _OneByteString         -> String (remapped)
    kUserVisibleName
  };

  // Sometimes simple formating might produce the same name for two different
  // entities, for example we might inject a synthetic forwarder into the
  // class which has the same name as an already existing function, or
  // two different types can be formatted as X<T> because T has different
  // meaning (refers to a different type parameter) in these two types.
  // Such ambiguity might be acceptable in some contexts but not in others, so
  // some formatting methods have two modes - one which tries to be more
  // user friendly, and another one which tries to avoid name conflicts by
  // emitting longer and less user friendly names.
  enum class NameDisambiguation {
    kYes,
    kNo,
  };

 protected:
  friend ObjectPtr AllocateObject(intptr_t, intptr_t, intptr_t);

  // Used for extracting the C++ vtable during bringup.
  Object() : ptr_(null_) {}

  uword raw_value() const { return static_cast<uword>(ptr()); }

  inline void setPtr(ObjectPtr value, intptr_t default_cid);
  void CheckHandle() const;
  DART_NOINLINE static Object& HandleImpl(Zone* zone,
                                          ObjectPtr ptr,
                                          intptr_t default_cid) {
    Object* obj = reinterpret_cast<Object*>(VMHandles::AllocateHandle(zone));
    obj->setPtr(ptr, default_cid);
    return *obj;
  }
  DART_NOINLINE static Object& ZoneHandleImpl(Zone* zone,
                                              ObjectPtr ptr,
                                              intptr_t default_cid) {
    Object* obj =
        reinterpret_cast<Object*>(VMHandles::AllocateZoneHandle(zone));
    obj->setPtr(ptr, default_cid);
    return *obj;
  }
  DART_NOINLINE static Object* ReadOnlyHandleImpl(intptr_t cid) {
    Object* obj = reinterpret_cast<Object*>(Dart::AllocateReadOnlyHandle());
    obj->setPtr(Object::null(), cid);
    return obj;
  }

  // Memcpy to account for the strict aliasing rule.
  // Explicit cast to silence -Wdynamic-class-memaccess.
  // This is still undefined behavior because we're messing with the internal
  // representation of C++ objects, but works okay in practice with
  // -fno-strict-vtable-pointers.
  cpp_vtable vtable() const {
    cpp_vtable result;
    memcpy(&result, reinterpret_cast<const void*>(this),  // NOLINT
           sizeof(result));
    return result;
  }
  void set_vtable(cpp_vtable value) {
    memcpy(reinterpret_cast<void*>(this), &value,  // NOLINT
           sizeof(cpp_vtable));
  }

  static ObjectPtr Allocate(intptr_t cls_id,
                            intptr_t size,
                            Heap::Space space,
                            bool compressed,
                            uword ptr_field_start_offset,
                            uword ptr_field_end_offset);

  // Templates of Allocate that retrieve the appropriate values to pass from
  // the class.

  template <typename T>
  DART_FORCE_INLINE static typename T::ObjectPtrType Allocate(
      Heap::Space space) {
    return static_cast<typename T::ObjectPtrType>(Allocate(
        T::kClassId, T::InstanceSize(), space, T::ContainsCompressedPointers(),
        Object::from_offset<T>(), Object::to_offset<T>()));
  }
  template <typename T>
  DART_FORCE_INLINE static typename T::ObjectPtrType Allocate(
      Heap::Space space,
      intptr_t elements) {
    return static_cast<typename T::ObjectPtrType>(
        Allocate(T::kClassId, T::InstanceSize(elements), space,
                 T::ContainsCompressedPointers(), Object::from_offset<T>(),
                 Object::to_offset<T>(elements)));
  }

  // Additional versions that also take a class_id for types like Array, Map,
  // and Set that have more than one possible class id.

  template <typename T>
  DART_FORCE_INLINE static typename T::ObjectPtrType AllocateVariant(
      intptr_t class_id,
      Heap::Space space) {
    return static_cast<typename T::ObjectPtrType>(Allocate(
        class_id, T::InstanceSize(), space, T::ContainsCompressedPointers(),
        Object::from_offset<T>(), Object::to_offset<T>()));
  }
  template <typename T>
  DART_FORCE_INLINE static typename T::ObjectPtrType
  AllocateVariant(intptr_t class_id, Heap::Space space, intptr_t elements) {
    return static_cast<typename T::ObjectPtrType>(
        Allocate(class_id, T::InstanceSize(elements), space,
                 T::ContainsCompressedPointers(), Object::from_offset<T>(),
                 Object::to_offset<T>(elements)));
  }

  static constexpr intptr_t RoundedAllocationSize(intptr_t size) {
    return Utils::RoundUp(size, kObjectAlignment);
  }

  bool Contains(uword addr) const { return ptr()->untag()->Contains(addr); }

  // Start of field mutator guards.
  //
  // All writes to heap objects should ultimately pass through one of the
  // methods below or their counterparts in UntaggedObject, to ensure that the
  // write barrier is correctly applied.

  template <typename type, std::memory_order order = std::memory_order_relaxed>
  type LoadPointer(type const* addr) const {
    return ptr()->untag()->LoadPointer<type, order>(addr);
  }

  template <typename type, std::memory_order order = std::memory_order_relaxed>
  void StorePointer(type const* addr, type value) const {
    ptr()->untag()->StorePointer<type, order>(addr, value);
  }
  template <typename type,
            typename compressed_type,
            std::memory_order order = std::memory_order_relaxed>
  void StoreCompressedPointer(compressed_type const* addr, type value) const {
    ptr()->untag()->StoreCompressedPointer<type, compressed_type, order>(addr,
                                                                         value);
  }
  template <typename type>
  void StorePointerUnaligned(type const* addr,
                             type value,
                             Thread* thread) const {
    ptr()->untag()->StorePointerUnaligned<type>(addr, value, thread);
  }

  // Use for storing into an explicitly Smi-typed field of an object
  // (i.e., both the previous and new value are Smis).
  void StoreSmi(SmiPtr const* addr, SmiPtr value) const {
    ptr()->untag()->StoreSmi(addr, value);
  }

  template <typename FieldType>
  void StoreSimd128(const FieldType* addr, simd128_value_t value) const {
    ASSERT(Contains(reinterpret_cast<uword>(addr)));
    value.writeTo(const_cast<FieldType*>(addr));
  }

  template <typename FieldType>
  FieldType LoadNonPointer(const FieldType* addr) const {
    return *const_cast<FieldType*>(addr);
  }

  template <typename FieldType, std::memory_order order>
  FieldType LoadNonPointer(const FieldType* addr) const {
    return reinterpret_cast<std::atomic<FieldType>*>(
               const_cast<FieldType*>(addr))
        ->load(order);
  }

  // Needs two template arguments to allow assigning enums to fixed-size ints.
  template <typename FieldType, typename ValueType>
  void StoreNonPointer(const FieldType* addr, ValueType value) const {
    // Can't use Contains, as it uses tags_, which is set through this method.
    ASSERT(reinterpret_cast<uword>(addr) >= UntaggedObject::ToAddr(ptr()));
    *const_cast<FieldType*>(addr) = value;
  }

  template <typename FieldType, typename ValueType, std::memory_order order>
  void StoreNonPointer(const FieldType* addr, ValueType value) const {
    // Can't use Contains, as it uses tags_, which is set through this method.
    ASSERT(reinterpret_cast<uword>(addr) >= UntaggedObject::ToAddr(ptr()));
    reinterpret_cast<std::atomic<FieldType>*>(const_cast<FieldType*>(addr))
        ->store(value, order);
  }

  // Provides non-const access to non-pointer fields within the object. Such
  // access does not need a write barrier, but it is *not* GC-safe, since the
  // object might move, hence must be fully contained within a NoSafepointScope.
  template <typename FieldType>
  FieldType* UnsafeMutableNonPointer(const FieldType* addr) const {
    // Allow pointers at the end of variable-length data, and disallow pointers
    // within the header word.
    ASSERT(Contains(reinterpret_cast<uword>(addr) - 1) &&
           Contains(reinterpret_cast<uword>(addr) - kWordSize));
    // At least check that there is a NoSafepointScope and hope it's big enough.
    ASSERT(Thread::Current()->no_safepoint_scope_depth() > 0);
    return const_cast<FieldType*>(addr);
  }

// Fail at link time if StoreNonPointer or UnsafeMutableNonPointer is
// instantiated with an object pointer type.
#define STORE_NON_POINTER_ILLEGAL_TYPE(type)                                   \
  template <typename ValueType>                                                \
  void StoreNonPointer(type##Ptr const* addr, ValueType value) const {         \
    UnimplementedMethod();                                                     \
  }                                                                            \
  type##Ptr* UnsafeMutableNonPointer(type##Ptr const* addr) const {            \
    UnimplementedMethod();                                                     \
    return nullptr;                                                            \
  }

  CLASS_LIST(STORE_NON_POINTER_ILLEGAL_TYPE);
  void UnimplementedMethod() const;
#undef STORE_NON_POINTER_ILLEGAL_TYPE

  // Allocate an object and copy the body of 'orig'.
  static ObjectPtr Clone(const Object& orig,
                         Heap::Space space,
                         bool load_with_relaxed_atomics = false);

  // End of field mutator guards.

  ObjectPtr ptr_;  // The raw object reference.

 protected:
  // The first offset in an allocated object of the given type that contains a
  // (possibly compressed) object pointer. Used to initialize object pointer
  // fields to Object::null() instead of 0.
  //
  // Always returns an offset after the object header tags.
  template <typename T>
  DART_FORCE_INLINE static uword from_offset() {
    return UntaggedObject::from_offset<typename T::UntaggedObjectType>();
  }

  // The last offset in an allocated object of the given type that contains a
  // (possibly compressed) object pointer. Used to initialize object pointer
  // fields to Object::null() instead of 0.
  //
  // Takes an optional argument that is the number of elements in the payload,
  // which is ignored if the object never contains a payload.
  //
  // If there are no pointer fields in the object, then
  // to_offset<T>() < from_offset<T>().
  template <typename T>
  DART_FORCE_INLINE static uword to_offset(intptr_t length = 0) {
    return UntaggedObject::to_offset<typename T::UntaggedObjectType>(length);
  }

  void AddCommonObjectProperties(JSONObject* jsobj,
                                 const char* protocol_type,
                                 bool ref) const;

 private:
  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  static void InitializeObject(uword address,
                               intptr_t id,
                               intptr_t size,
                               bool compressed,
                               uword ptr_field_start_offset,
                               uword ptr_field_end_offset);

  // Templates of InitializeObject that retrieve the appropriate values to pass
  // from the class.

  template <typename T>
  DART_FORCE_INLINE static void InitializeObject(uword address) {
    return InitializeObject(address, T::kClassId, T::InstanceSize(),
                            T::ContainsCompressedPointers(),
                            Object::from_offset<T>(), Object::to_offset<T>());
  }
  template <typename T>
  DART_FORCE_INLINE static void InitializeObject(uword address,
                                                 intptr_t elements) {
    return InitializeObject(address, T::kClassId, T::InstanceSize(elements),
                            T::ContainsCompressedPointers(),
                            Object::from_offset<T>(),
                            Object::to_offset<T>(elements));
  }

  // Additional versions that also take a class_id for types like Array, Map,
  // and Set that have more than one possible class id.

  template <typename T>
  DART_FORCE_INLINE static void InitializeObjectVariant(uword address,
                                                        intptr_t class_id) {
    return InitializeObject(address, class_id, T::InstanceSize(),
                            T::ContainsCompressedPointers(),
                            Object::from_offset<T>(), Object::to_offset<T>());
  }
  template <typename T>
  DART_FORCE_INLINE static void InitializeObjectVariant(uword address,
                                                        intptr_t class_id,
                                                        intptr_t elements) {
    return InitializeObject(address, class_id, T::InstanceSize(elements),
                            T::ContainsCompressedPointers(),
                            Object::from_offset<T>(),
                            Object::to_offset<T>(elements));
  }

  static void RegisterClass(const Class& cls,
                            const String& name,
                            const Library& lib);
  static void RegisterPrivateClass(const Class& cls,
                                   const String& name,
                                   const Library& lib);

  /* Initialize the handle based on the ptr in the presence of null. */
  static void initializeHandle(Object* obj, ObjectPtr ptr) {
    obj->setPtr(ptr, kObjectCid);
  }

  static cpp_vtable builtin_vtables_[kNumPredefinedCids];

  // The static values below are singletons shared between the different
  // isolates. They are all allocated in the non-GC'd Dart::vm_isolate_.
  static ObjectPtr null_;
  static BoolPtr true_;
  static BoolPtr false_;

  static ClassPtr class_class_;
  static ClassPtr dynamic_class_;
  static ClassPtr void_class_;
  static ClassPtr type_parameters_class_;
  static ClassPtr type_arguments_class_;
  static ClassPtr patch_class_class_;
  static ClassPtr function_class_;
  static ClassPtr closure_data_class_;
  static ClassPtr ffi_trampoline_data_class_;
  static ClassPtr field_class_;
  static ClassPtr script_class_;
  static ClassPtr library_class_;
  static ClassPtr namespace_class_;
  static ClassPtr kernel_program_info_class_;
  static ClassPtr code_class_;
  static ClassPtr instructions_class_;
  static ClassPtr instructions_section_class_;
  static ClassPtr instructions_table_class_;
  static ClassPtr object_pool_class_;
  static ClassPtr pc_descriptors_class_;
  static ClassPtr code_source_map_class_;
  static ClassPtr compressed_stackmaps_class_;
  static ClassPtr var_descriptors_class_;
  static ClassPtr exception_handlers_class_;
  static ClassPtr context_class_;
  static ClassPtr context_scope_class_;
  static ClassPtr sentinel_class_;
  static ClassPtr singletargetcache_class_;
  static ClassPtr unlinkedcall_class_;
  static ClassPtr monomorphicsmiablecall_class_;
  static ClassPtr icdata_class_;
  static ClassPtr megamorphic_cache_class_;
  static ClassPtr subtypetestcache_class_;
  static ClassPtr loadingunit_class_;
  static ClassPtr api_error_class_;
  static ClassPtr language_error_class_;
  static ClassPtr unhandled_exception_class_;
  static ClassPtr unwind_error_class_;
  static ClassPtr weak_serialization_reference_class_;
  static ClassPtr weak_array_class_;

#define DECLARE_SHARED_READONLY_HANDLE(Type, name) static Type* name##_;
  SHARED_READONLY_HANDLES_LIST(DECLARE_SHARED_READONLY_HANDLE)
#undef DECLARE_SHARED_READONLY_HANDLE

  friend void ClassTable::Register(const Class& cls);
  friend void UntaggedObject::Validate(IsolateGroup* isolate_group) const;
  friend class Closure;
  friend class InstanceDeserializationCluster;
  friend class ObjectGraphCopier;  // For Object::InitializeObject
  friend class Simd128MessageDeserializationCluster;
  friend class OneByteString;
  friend class TwoByteString;
  friend class ExternalOneByteString;
  friend class ExternalTwoByteString;
  friend class Thread;

#define REUSABLE_FRIEND_DECLARATION(name)                                      \
  friend class Reusable##name##HandleScope;
  REUSABLE_HANDLE_LIST(REUSABLE_FRIEND_DECLARATION)
#undef REUSABLE_FRIEND_DECLARATION

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Object);
};

// Used to declare setters and getters for untagged object fields that are
// defined with the WSR_COMPRESSED_POINTER_FIELD macro.
//
// In the precompiler, the getter transparently unwraps the
// WeakSerializationReference, if present, to get the wrapped value of the
// appropriate type, since a WeakSerializationReference object should be
// transparent to the parts of the precompiler that are not the serializer.
// Meanwhile, the setter takes an Object to allow the precompiler to set the
// field to a WeakSerializationReference.
//
// Since WeakSerializationReferences are only used during precompilation,
// this macro creates the normally expected getter and setter otherwise.
#if defined(DART_PRECOMPILER)
#define PRECOMPILER_WSR_FIELD_DECLARATION(Type, Name)                          \
  Type##Ptr Name() const;                                                      \
  void set_##Name(const Object& value) const {                                 \
    untag()->set_##Name(value.ptr());                                          \
  }
#else
#define PRECOMPILER_WSR_FIELD_DECLARATION(Type, Name)                          \
  Type##Ptr Name() const { return untag()->Name(); }                           \
  void set_##Name(const Type& value) const;
#endif

class PassiveObject : public Object {
 public:
  void operator=(ObjectPtr value) { ptr_ = value; }
  void operator^=(ObjectPtr value) { ptr_ = value; }

  static PassiveObject& Handle(Zone* zone, ObjectPtr ptr) {
    PassiveObject* obj =
        reinterpret_cast<PassiveObject*>(VMHandles::AllocateHandle(zone));
    obj->ptr_ = ptr;
    obj->set_vtable(0);
    return *obj;
  }
  static PassiveObject& Handle(ObjectPtr ptr) {
    return Handle(Thread::Current()->zone(), ptr);
  }
  static PassiveObject& Handle() {
    return Handle(Thread::Current()->zone(), Object::null());
  }
  static PassiveObject& Handle(Zone* zone) {
    return Handle(zone, Object::null());
  }
  static PassiveObject& ZoneHandle(Zone* zone, ObjectPtr ptr) {
    PassiveObject* obj =
        reinterpret_cast<PassiveObject*>(VMHandles::AllocateZoneHandle(zone));
    obj->ptr_ = ptr;
    obj->set_vtable(0);
    return *obj;
  }
  static PassiveObject& ZoneHandle(ObjectPtr ptr) {
    return ZoneHandle(Thread::Current()->zone(), ptr);
  }
  static PassiveObject& ZoneHandle() {
    return ZoneHandle(Thread::Current()->zone(), Object::null());
  }
  static PassiveObject& ZoneHandle(Zone* zone) {
    return ZoneHandle(zone, Object::null());
  }

 private:
  PassiveObject() : Object() {}
  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(PassiveObject);
};

// A URIs array contains triplets of strings.
// The first string in the triplet is a type name (usually a class).
// The second string in the triplet is the URI of the type.
// The third string in the triplet is "print" if the triplet should be printed.
typedef ZoneGrowableHandlePtrArray<const String> URIs;

enum class Nullability : uint8_t {
  kNullable = 0,
  kNonNullable = 1,
  kLegacy = 2,
  // Adjust kNullabilityBitSize in app_snapshot.cc if adding new values.
};

// Equality kind between types.
enum class TypeEquality {
  kCanonical = 0,
  kSyntactical = 1,
  kInSubtypeTest = 2,
};

// The NNBDMode reflects the opted-in status of libraries.
// Note that the weak or strong checking mode is not reflected in NNBDMode.
enum class NNBDMode {
  // Status of the library:
  kLegacyLib = 0,   // Library is legacy.
  kOptedInLib = 1,  // Library is opted-in.
};

// The NNBDCompiledMode reflects the mode in which constants of the library were
// compiled by CFE.
enum class NNBDCompiledMode {
  kWeak = 0,
  kStrong = 1,
  kAgnostic = 2,
  kInvalid = 3,
};

class Class : public Object {
 public:
  enum InvocationDispatcherEntry {
    kInvocationDispatcherName,
    kInvocationDispatcherArgsDesc,
    kInvocationDispatcherFunction,
    kInvocationDispatcherEntrySize,
  };

  bool HasCompressedPointers() const;
  intptr_t host_instance_size() const {
    ASSERT(is_finalized() || is_prefinalized());
    return (untag()->host_instance_size_in_words_ * kCompressedWordSize);
  }
  intptr_t target_instance_size() const {
    ASSERT(is_finalized() || is_prefinalized());
#if defined(DART_PRECOMPILER)
    return (untag()->target_instance_size_in_words_ *
            compiler::target::kCompressedWordSize);
#else
    return host_instance_size();
#endif  // defined(DART_PRECOMPILER)
  }
  static intptr_t host_instance_size(ClassPtr clazz) {
    return (clazz->untag()->host_instance_size_in_words_ * kCompressedWordSize);
  }
  static intptr_t target_instance_size(ClassPtr clazz) {
#if defined(DART_PRECOMPILER)
    return (clazz->untag()->target_instance_size_in_words_ *
            compiler::target::kCompressedWordSize);
#else
    return host_instance_size(clazz);
#endif  // defined(DART_PRECOMPILER)
  }
  void set_instance_size(intptr_t host_value_in_bytes,
                         intptr_t target_value_in_bytes) const {
    ASSERT(kCompressedWordSize != 0);
    set_instance_size_in_words(
        host_value_in_bytes / kCompressedWordSize,
        target_value_in_bytes / compiler::target::kCompressedWordSize);
  }
  void set_instance_size_in_words(intptr_t host_value,
                                  intptr_t target_value) const {
    ASSERT(
        Utils::IsAligned((host_value * kCompressedWordSize), kObjectAlignment));
    StoreNonPointer(&untag()->host_instance_size_in_words_, host_value);
#if defined(DART_PRECOMPILER)
    ASSERT(
        Utils::IsAligned((target_value * compiler::target::kCompressedWordSize),
                         compiler::target::kObjectAlignment));
    StoreNonPointer(&untag()->target_instance_size_in_words_, target_value);
#else
    // Could be different only during cross-compilation.
    ASSERT_EQUAL(host_value, target_value);
#endif  // defined(DART_PRECOMPILER)
  }

  intptr_t host_next_field_offset() const {
    return untag()->host_next_field_offset_in_words_ * kCompressedWordSize;
  }
  intptr_t target_next_field_offset() const {
#if defined(DART_PRECOMPILER)
    return untag()->target_next_field_offset_in_words_ *
           compiler::target::kCompressedWordSize;
#else
    return host_next_field_offset();
#endif  // defined(DART_PRECOMPILER)
  }
  void set_next_field_offset(intptr_t host_value_in_bytes,
                             intptr_t target_value_in_bytes) const {
    set_next_field_offset_in_words(
        host_value_in_bytes / kCompressedWordSize,
        target_value_in_bytes / compiler::target::kCompressedWordSize);
  }
  void set_next_field_offset_in_words(intptr_t host_value,
                                      intptr_t target_value) const {
    // Assert that the next field offset is either negative (ie, this object
    // can't be extended by dart code), or rounds up to the kObjectAligned
    // instance size.
    ASSERT((host_value < 0) ||
           ((host_value <= untag()->host_instance_size_in_words_) &&
            (host_value + (kObjectAlignment / kCompressedWordSize) >
             untag()->host_instance_size_in_words_)));
    StoreNonPointer(&untag()->host_next_field_offset_in_words_, host_value);
#if defined(DART_PRECOMPILER)
    ASSERT((target_value < 0) ||
           ((target_value <= untag()->target_instance_size_in_words_) &&
            (target_value + (compiler::target::kObjectAlignment /
                             compiler::target::kCompressedWordSize) >
             untag()->target_instance_size_in_words_)));
    StoreNonPointer(&untag()->target_next_field_offset_in_words_, target_value);
#else
    // Could be different only during cross-compilation.
    ASSERT_EQUAL(host_value, target_value);
#endif  // defined(DART_PRECOMPILER)
  }

  static bool is_valid_id(intptr_t value) {
    return UntaggedObject::ClassIdTag::is_valid(value);
  }
  intptr_t id() const { return untag()->id_; }
  void set_id(intptr_t value) const {
    ASSERT(value >= 0 && value < std::numeric_limits<classid_t>::max());
    StoreNonPointer(&untag()->id_, value);
  }
  static intptr_t id_offset() { return OFFSET_OF(UntaggedClass, id_); }

#if !defined(DART_PRECOMPILED_RUNTIME)
  // If the interface of this class has a single concrete implementation, either
  // via `extends` or by `implements`, returns its CID.
  // If it has no implementation, returns kIllegalCid.
  // If it has more than one implementation, returns kDynamicCid.
  intptr_t implementor_cid() const { return untag()->implementor_cid_; }

  // Returns true if the implementor tracking state changes and so must be
  // propagated to this class's superclass and interfaces.
  bool NoteImplementor(const Class& implementor) const;
#endif

  static intptr_t num_type_arguments_offset() {
    return OFFSET_OF(UntaggedClass, num_type_arguments_);
  }

  StringPtr Name() const;
  StringPtr ScrubbedName() const;
  const char* ScrubbedNameCString() const;
  StringPtr UserVisibleName() const;
  const char* UserVisibleNameCString() const;

  const char* NameCString(NameVisibility name_visibility) const;

  // The mixin for this class if one exists. Otherwise, returns a raw pointer
  // to this class.
  ClassPtr Mixin() const;

  // The NNBD mode of the library declaring this class.
  NNBDMode nnbd_mode() const;

  bool IsInFullSnapshot() const;

  virtual StringPtr DictionaryName() const { return Name(); }

  ScriptPtr script() const { return untag()->script(); }
  void set_script(const Script& value) const;

#if !defined(DART_PRECOMPILED_RUNTIME)
  KernelProgramInfoPtr KernelProgramInfo() const;
#endif

  TokenPosition token_pos() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return TokenPosition::kNoSource;
#else
    return untag()->token_pos_;
#endif  // defined(DART_PRECOMPILED_RUNTIME)
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  void set_token_pos(TokenPosition value) const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  TokenPosition end_token_pos() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return TokenPosition::kNoSource;
#else
    return untag()->end_token_pos_;
#endif  // defined(DART_PRECOMPILED_RUNTIME)
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  void set_end_token_pos(TokenPosition value) const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  uint32_t Hash() const;
  static uint32_t Hash(ClassPtr);

  int32_t SourceFingerprint() const;

  // Return the Type with type arguments instantiated to bounds.
  TypePtr RareType() const;

  // Return the non-nullable Type whose arguments are the type parameters
  // declared by this class.
  TypePtr DeclarationType() const;

  static intptr_t declaration_type_offset() {
    return OFFSET_OF(UntaggedClass, declaration_type_);
  }

  // Returns flattened instance type arguments vector for
  // instance of this class, parameterized with declared
  // type parameters of this class.
  TypeArgumentsPtr GetDeclarationInstanceTypeArguments() const;

  // Returns flattened instance type arguments vector for
  // instance of this type, parameterized with given type arguments.
  //
  // Length of [type_arguments] should match number of type parameters
  // returned by [NumTypeParameters].
  TypeArgumentsPtr GetInstanceTypeArguments(Thread* thread,
                                            const TypeArguments& type_arguments,
                                            bool canonicalize = true) const;

  LibraryPtr library() const { return untag()->library(); }
  void set_library(const Library& value) const;

  // The formal type parameters and their bounds (no defaults), are specified as
  // an object of type TypeParameters.
  TypeParametersPtr type_parameters() const {
    ASSERT(is_declaration_loaded());
    return untag()->type_parameters();
  }
  void set_type_parameters(const TypeParameters& value) const;
  intptr_t NumTypeParameters(Thread* thread) const;
  intptr_t NumTypeParameters() const {
    return NumTypeParameters(Thread::Current());
  }

  // Return the type parameter declared at index.
  TypeParameterPtr TypeParameterAt(
      intptr_t index,
      Nullability nullability = Nullability::kNonNullable) const;

  // Length of the flattened instance type arguments vector.
  // Includes type arguments of the super class.
  intptr_t NumTypeArguments() const;

  // Return true if this class declares type parameters.
  bool IsGeneric() const {
    // If the declaration is not loaded, fall back onto NumTypeParameters.
    if (!is_declaration_loaded()) {
      return NumTypeParameters(Thread::Current()) > 0;
    }
    return type_parameters() != Object::null();
  }

  // Returns a canonicalized vector of the type parameters instantiated
  // to bounds. If non-generic, the empty type arguments vector is returned.
  TypeArgumentsPtr InstantiateToBounds(Thread* thread) const;

  // If this class is parameterized, each instance has a type_arguments field.
  static constexpr intptr_t kNoTypeArguments = -1;
  intptr_t host_type_arguments_field_offset() const {
    ASSERT(is_type_finalized() || is_prefinalized());
    if (untag()->host_type_arguments_field_offset_in_words_ ==
        kNoTypeArguments) {
      return kNoTypeArguments;
    }
    return untag()->host_type_arguments_field_offset_in_words_ *
           kCompressedWordSize;
  }
  intptr_t target_type_arguments_field_offset() const {
#if defined(DART_PRECOMPILER)
    ASSERT(is_type_finalized() || is_prefinalized());
    if (untag()->target_type_arguments_field_offset_in_words_ ==
        compiler::target::Class::kNoTypeArguments) {
      return compiler::target::Class::kNoTypeArguments;
    }
    return untag()->target_type_arguments_field_offset_in_words_ *
           compiler::target::kCompressedWordSize;
#else
    return host_type_arguments_field_offset();
#endif  // defined(DART_PRECOMPILER)
  }
  void set_type_arguments_field_offset(intptr_t host_value_in_bytes,
                                       intptr_t target_value_in_bytes) const {
    intptr_t host_value, target_value;
    if (host_value_in_bytes == kNoTypeArguments ||
        target_value_in_bytes == RTN::Class::kNoTypeArguments) {
      ASSERT(host_value_in_bytes == kNoTypeArguments &&
             target_value_in_bytes == RTN::Class::kNoTypeArguments);
      host_value = kNoTypeArguments;
      target_value = RTN::Class::kNoTypeArguments;
    } else {
      ASSERT(kCompressedWordSize != 0 && compiler::target::kCompressedWordSize);
      host_value = host_value_in_bytes / kCompressedWordSize;
      target_value =
          target_value_in_bytes / compiler::target::kCompressedWordSize;
    }
    set_type_arguments_field_offset_in_words(host_value, target_value);
  }
  void set_type_arguments_field_offset_in_words(intptr_t host_value,
                                                intptr_t target_value) const {
    StoreNonPointer(&untag()->host_type_arguments_field_offset_in_words_,
                    host_value);
#if defined(DART_PRECOMPILER)
    StoreNonPointer(&untag()->target_type_arguments_field_offset_in_words_,
                    target_value);
#else
    // Could be different only during cross-compilation.
    ASSERT_EQUAL(host_value, target_value);
#endif  // defined(DART_PRECOMPILER)
  }
  static intptr_t host_type_arguments_field_offset_in_words_offset() {
    return OFFSET_OF(UntaggedClass, host_type_arguments_field_offset_in_words_);
  }

  // The super type of this class, Object type if not explicitly specified.
  TypePtr super_type() const {
    ASSERT(is_declaration_loaded());
    return untag()->super_type();
  }
  void set_super_type(const Type& value) const;
  static intptr_t super_type_offset() {
    return OFFSET_OF(UntaggedClass, super_type_);
  }

  // Asserts that the class of the super type has been resolved.
  // If |class_table| is provided it will be used to resolve class id to the
  // actual class object, instead of using current class table on the isolate
  // group.
  ClassPtr SuperClass(ClassTable* class_table = nullptr) const;

  // Interfaces is an array of Types.
  ArrayPtr interfaces() const {
    ASSERT(is_declaration_loaded());
    return untag()->interfaces();
  }
  void set_interfaces(const Array& value) const;

  // Returns whether a path from [this] to [cls] can be found, where the first
  // element is a direct supertype of [this], each following element is a direct
  // supertype of the previous element and the final element has [cls] as its
  // type class. If [this] and [cls] are the same class, then the path is empty.
  //
  // If [path] is not nullptr, then the elements of the path are added to it.
  // This path can then be used to compute type arguments of [cls] given type
  // arguments for an instance of [this].
  //
  // Note: There may be multiple paths to [cls], but the result of applying each
  // path must be equal to the other results.
  bool FindInstantiationOf(Zone* zone,
                           const Class& cls,
                           GrowableArray<const Type*>* path,
                           bool consider_only_super_classes = false) const;
  bool FindInstantiationOf(Zone* zone,
                           const Class& cls,
                           bool consider_only_super_classes = false) const {
    return FindInstantiationOf(zone, cls, /*path=*/nullptr,
                               consider_only_super_classes);
  }

  // Returns whether a path from [this] to [type] can be found, where the first
  // element is a direct supertype of [this], each following element is a direct
  // supertype of the previous element and the final element has the same type
  // class as [type]. If [this] is the type class of [type], then the path is
  // empty.
  //
  // If [path] is not nullptr, then the elements of the path are added to it.
  // This path can then be used to compute type arguments of [type]'s type
  // class given type arguments for an instance of [this].
  //
  // Note: There may be multiple paths to [type]'s type class, but the result of
  // applying each path must be equal to the other results.
  bool FindInstantiationOf(Zone* zone,
                           const Type& type,
                           GrowableArray<const Type*>* path,
                           bool consider_only_super_classes = false) const;
  bool FindInstantiationOf(Zone* zone,
                           const Type& type,
                           bool consider_only_super_classes = false) const {
    return FindInstantiationOf(zone, type, /*path=*/nullptr,
                               consider_only_super_classes);
  }

  // If [this] is a subtype of a type with type class [cls], then this
  // returns [cls]<X_0, ..., X_n>, where n is the number of type arguments for
  // [cls] and where each type argument X_k is either instantiated or has free
  // class type parameters corresponding to the type parameters of [this].
  // Thus, given an instance of [this], the result can be instantiated
  // with the instance type arguments to get the type of the instance.
  //
  // If [this] is not a subtype of a type with type class [cls], returns null.
  TypePtr GetInstantiationOf(Zone* zone, const Class& cls) const;

  // If [this] is a subtype of [type], then this returns [cls]<X_0, ..., X_n>,
  // where [cls] is the type class of [type], n is the number of type arguments
  // for [cls], and where each type argument X_k is either instantiated or has
  // free class type parameters corresponding to the type parameters of [this].
  // Thus, given an instance of [this], the result can be instantiated with the
  // instance type arguments to get the type of the instance.
  //
  // If [this] is not a subtype of a type with type class [cls], returns null.
  TypePtr GetInstantiationOf(Zone* zone, const Type& type) const;

#if !defined(PRODUCT) || !defined(DART_PRECOMPILED_RUNTIME)
  // Returns the list of classes directly implementing this class.
  GrowableObjectArrayPtr direct_implementors() const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
    return untag()->direct_implementors();
  }
  GrowableObjectArrayPtr direct_implementors_unsafe() const {
    return untag()->direct_implementors();
  }
#endif  // !defined(PRODUCT) || !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
  void set_direct_implementors(const GrowableObjectArray& implementors) const;
  void AddDirectImplementor(const Class& subclass, bool is_mixin) const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(PRODUCT) || !defined(DART_PRECOMPILED_RUNTIME)
  // Returns the list of classes having this class as direct superclass.
  GrowableObjectArrayPtr direct_subclasses() const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
    return direct_subclasses_unsafe();
  }
  GrowableObjectArrayPtr direct_subclasses_unsafe() const {
    return untag()->direct_subclasses();
  }
#endif  // !defined(PRODUCT) || !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
  void set_direct_subclasses(const GrowableObjectArray& subclasses) const;
  void AddDirectSubclass(const Class& subclass) const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Check if this class represents the class of null.
  bool IsNullClass() const { return id() == kNullCid; }

  // Check if this class represents the 'dynamic' class.
  bool IsDynamicClass() const { return id() == kDynamicCid; }

  // Check if this class represents the 'void' class.
  bool IsVoidClass() const { return id() == kVoidCid; }

  // Check if this class represents the 'Never' class.
  bool IsNeverClass() const { return id() == kNeverCid; }

  // Check if this class represents the 'Object' class.
  bool IsObjectClass() const { return id() == kInstanceCid; }

  // Check if this class represents the 'Function' class.
  bool IsDartFunctionClass() const;

  // Check if this class represents the 'Future' class.
  bool IsFutureClass() const;

  // Check if this class represents the 'FutureOr' class.
  bool IsFutureOrClass() const { return id() == kFutureOrCid; }

  // Check if this class represents the 'Closure' class.
  bool IsClosureClass() const { return id() == kClosureCid; }
  static bool IsClosureClass(ClassPtr cls) {
    return GetClassId(cls) == kClosureCid;
  }

  // Check if this class represents the 'Record' class.
  bool IsRecordClass() const {
    return id() == kRecordCid;
  }

  static bool IsInFullSnapshot(ClassPtr cls) {
    NoSafepointScope no_safepoint;
    return UntaggedLibrary::InFullSnapshotBit::decode(
        cls->untag()->library()->untag()->flags_);
  }

  static intptr_t GetClassId(ClassPtr cls) {
    NoSafepointScope no_safepoint;
    return cls->untag()->id_;
  }

  // Returns true if the type specified by cls, type_arguments, and nullability
  // is a subtype of the other type.
  static bool IsSubtypeOf(
      const Class& cls,
      const TypeArguments& type_arguments,
      Nullability nullability,
      const AbstractType& other,
      Heap::Space space,
      FunctionTypeMapping* function_type_equivalence = nullptr);

  // Check if this is the top level class.
  bool IsTopLevel() const;

  bool IsPrivate() const;

  DART_WARN_UNUSED_RESULT
  ErrorPtr VerifyEntryPoint() const;

  // Returns an array of instance and static fields defined by this class.
  ArrayPtr fields() const {
    // We rely on the fact that any loads from the array are dependent loads
    // and avoid the load-acquire barrier here.
    return untag()->fields();
  }
  void SetFields(const Array& value) const;
  void AddField(const Field& field) const;
  void AddFields(const GrowableArray<const Field*>& fields) const;

  intptr_t FindFieldIndex(const Field& needle) const;
  FieldPtr FieldFromIndex(intptr_t idx) const;

  // If this is a dart:internal.ClassID class, then inject our own const
  // fields. Returns true if synthetic fields are injected and regular
  // field declarations should be ignored.
  bool InjectCIDFields() const;

  // Returns an array of all instance fields of this class and its superclasses
  // indexed by offset in words.
  // If |class_table| is provided it will be used to resolve super classes by
  // class id, instead of the current class_table stored in the isolate.
  ArrayPtr OffsetToFieldMap(ClassTable* class_table = nullptr) const;

  // Returns true if non-static fields are defined.
  bool HasInstanceFields() const;

  ArrayPtr current_functions() const {
    // We rely on the fact that any loads from the array are dependent loads
    // and avoid the load-acquire barrier here.
    return untag()->functions();
  }
  ArrayPtr functions() const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
    return current_functions();
  }
  void SetFunctions(const Array& value) const;
  void AddFunction(const Function& function) const;
  intptr_t FindFunctionIndex(const Function& needle) const;
  FunctionPtr FunctionFromIndex(intptr_t idx) const;
  intptr_t FindImplicitClosureFunctionIndex(const Function& needle) const;
  FunctionPtr ImplicitClosureFunctionFromIndex(intptr_t idx) const;

  FunctionPtr LookupFunctionReadLocked(const String& name) const;
  FunctionPtr LookupDynamicFunctionUnsafe(const String& name) const;

  FunctionPtr LookupDynamicFunctionAllowPrivate(const String& name) const;
  FunctionPtr LookupStaticFunction(const String& name) const;
  FunctionPtr LookupStaticFunctionAllowPrivate(const String& name) const;
  FunctionPtr LookupConstructor(const String& name) const;
  FunctionPtr LookupConstructorAllowPrivate(const String& name) const;
  FunctionPtr LookupFactory(const String& name) const;
  FunctionPtr LookupFactoryAllowPrivate(const String& name) const;
  FunctionPtr LookupFunctionAllowPrivate(const String& name) const;
  FunctionPtr LookupGetterFunction(const String& name) const;
  FunctionPtr LookupSetterFunction(const String& name) const;
  FieldPtr LookupInstanceField(const String& name) const;
  FieldPtr LookupStaticField(const String& name) const;
  FieldPtr LookupField(const String& name) const;
  FieldPtr LookupFieldAllowPrivate(const String& name,
                                   bool instance_only = false) const;
  FieldPtr LookupInstanceFieldAllowPrivate(const String& name) const;
  FieldPtr LookupStaticFieldAllowPrivate(const String& name) const;

  // The methods above are more efficient than this generic one.
  InstancePtr LookupCanonicalInstance(Zone* zone, const Instance& value) const;

  InstancePtr InsertCanonicalConstant(Zone* zone,
                                      const Instance& constant) const;

  bool RequireCanonicalTypeErasureOfConstants(Zone* zone) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedClass));
  }

  // Returns true if any class implements this interface via `implements`.
  // Returns false if all possible implementations of this interface must be
  // instances of this class or its subclasses.
  bool is_implemented() const { return ImplementedBit::decode(state_bits()); }
  void set_is_implemented() const;
  void set_is_implemented_unsafe() const;

  bool is_abstract() const { return AbstractBit::decode(state_bits()); }
  void set_is_abstract() const;

  UntaggedClass::ClassLoadingState class_loading_state() const {
    return ClassLoadingBits::decode(state_bits());
  }

  bool is_declaration_loaded() const {
    return class_loading_state() >= UntaggedClass::kDeclarationLoaded;
  }
  void set_is_declaration_loaded() const;
  void set_is_declaration_loaded_unsafe() const;

  bool is_type_finalized() const {
    return class_loading_state() >= UntaggedClass::kTypeFinalized;
  }
  void set_is_type_finalized() const;

  bool is_synthesized_class() const {
    return SynthesizedClassBit::decode(state_bits());
  }
  void set_is_synthesized_class() const;
  void set_is_synthesized_class_unsafe() const;

  bool is_enum_class() const { return EnumBit::decode(state_bits()); }
  void set_is_enum_class() const;

  bool is_finalized() const {
    return ClassFinalizedBits::decode(state_bits()) ==
               UntaggedClass::kFinalized ||
           ClassFinalizedBits::decode(state_bits()) ==
               UntaggedClass::kAllocateFinalized;
  }
  void set_is_finalized() const;
  void set_is_finalized_unsafe() const;

  bool is_allocate_finalized() const {
    return ClassFinalizedBits::decode(state_bits()) ==
           UntaggedClass::kAllocateFinalized;
  }
  void set_is_allocate_finalized() const;

  bool is_prefinalized() const {
    return ClassFinalizedBits::decode(state_bits()) ==
           UntaggedClass::kPreFinalized;
  }

  void set_is_prefinalized() const;

  bool is_const() const { return ConstBit::decode(state_bits()); }
  void set_is_const() const;

  // Tests if this is a mixin application class which was desugared
  // to a normal class by kernel mixin transformation
  // (pkg/kernel/lib/transformations/mixin_full_resolution.dart).
  //
  // In such case, its mixed-in type was pulled into the end of
  // interfaces list.
  bool is_transformed_mixin_application() const {
    return TransformedMixinApplicationBit::decode(state_bits());
  }
  void set_is_transformed_mixin_application() const;

  bool is_sealed() const { return SealedBit::decode(state_bits()); }
  void set_is_sealed() const;

  bool is_mixin_class() const { return MixinClassBit::decode(state_bits()); }
  void set_is_mixin_class() const;

  bool is_base_class() const { return BaseClassBit::decode(state_bits()); }
  void set_is_base_class() const;

  bool is_interface_class() const {
    return InterfaceClassBit::decode(state_bits());
  }
  void set_is_interface_class() const;

  bool is_final() const { return FinalBit::decode(state_bits()); }
  void set_is_final() const;

  bool is_fields_marked_nullable() const {
    return FieldsMarkedNullableBit::decode(state_bits());
  }
  void set_is_fields_marked_nullable() const;

  bool is_allocated() const { return IsAllocatedBit::decode(state_bits()); }
  void set_is_allocated(bool value) const;
  void set_is_allocated_unsafe(bool value) const;

  bool is_loaded() const { return IsLoadedBit::decode(state_bits()); }
  void set_is_loaded(bool value) const;

  uint16_t num_native_fields() const { return untag()->num_native_fields_; }
  void set_num_native_fields(uint16_t value) const {
    StoreNonPointer(&untag()->num_native_fields_, value);
  }
  static uint16_t NumNativeFieldsOf(ClassPtr clazz) {
    return clazz->untag()->num_native_fields_;
  }
  static bool IsIsolateUnsendable(ClassPtr clazz) {
    return IsIsolateUnsendableBit::decode(clazz->untag()->state_bits_);
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  CodePtr allocation_stub() const { return untag()->allocation_stub(); }
  void set_allocation_stub(const Code& value) const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  intptr_t kernel_offset() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return untag()->kernel_offset_;
#endif
  }

  void set_kernel_offset(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    StoreNonPointer(&untag()->kernel_offset_, value);
#endif
  }

  void DisableAllocationStub() const;

  ArrayPtr constants() const;
  void set_constants(const Array& value) const;

  intptr_t FindInvocationDispatcherFunctionIndex(const Function& needle) const;
  FunctionPtr InvocationDispatcherFunctionFromIndex(intptr_t idx) const;

  FunctionPtr GetInvocationDispatcher(const String& target_name,
                                      const Array& args_desc,
                                      UntaggedFunction::Kind kind,
                                      bool create_if_absent) const;

  FunctionPtr GetRecordFieldGetter(const String& getter_name) const;

  void Finalize() const;

  ObjectPtr Invoke(const String& selector,
                   const Array& arguments,
                   const Array& argument_names,
                   bool respect_reflectable = true,
                   bool check_is_entrypoint = false) const;
  ObjectPtr InvokeGetter(const String& selector,
                         bool throw_nsm_if_absent,
                         bool respect_reflectable = true,
                         bool check_is_entrypoint = false) const;
  ObjectPtr InvokeSetter(const String& selector,
                         const Instance& argument,
                         bool respect_reflectable = true,
                         bool check_is_entrypoint = false) const;

  // Evaluate the given expression as if it appeared in a static method of this
  // class and return the resulting value, or an error object if evaluating the
  // expression fails. The method has the formal (type) parameters given in
  // (type_)param_names, and is invoked with the (type)argument values given in
  // (type_)param_values.
  ObjectPtr EvaluateCompiledExpression(
      const ExternalTypedData& kernel_buffer,
      const Array& type_definitions,
      const Array& param_values,
      const TypeArguments& type_param_values) const;

  // Load class declaration (super type, interfaces, type parameters and
  // number of type arguments) if it is not loaded yet.
  void EnsureDeclarationLoaded() const;

  ErrorPtr EnsureIsFinalized(Thread* thread) const;
  ErrorPtr EnsureIsAllocateFinalized(Thread* thread) const;

  // Allocate a class used for VM internal objects.
  template <class FakeObject, class TargetFakeObject>
  static ClassPtr New(IsolateGroup* isolate_group, bool register_class = true);

  // Allocate instance classes.
  static ClassPtr New(const Library& lib,
                      const String& name,
                      const Script& script,
                      TokenPosition token_pos,
                      bool register_class = true);
  static ClassPtr NewNativeWrapper(const Library& library,
                                   const String& name,
                                   int num_fields);

  // Allocate the raw string classes.
  static ClassPtr NewStringClass(intptr_t class_id,
                                 IsolateGroup* isolate_group);

  // Allocate the raw TypedData classes.
  static ClassPtr NewTypedDataClass(intptr_t class_id,
                                    IsolateGroup* isolate_group);

  // Allocate the raw TypedDataView/ByteDataView classes.
  static ClassPtr NewTypedDataViewClass(intptr_t class_id,
                                        IsolateGroup* isolate_group);
  static ClassPtr NewUnmodifiableTypedDataViewClass(
      intptr_t class_id,
      IsolateGroup* isolate_group);

  // Allocate the raw ExternalTypedData classes.
  static ClassPtr NewExternalTypedDataClass(intptr_t class_id,
                                            IsolateGroup* isolate);

  // Allocate the raw Pointer classes.
  static ClassPtr NewPointerClass(intptr_t class_id,
                                  IsolateGroup* isolate_group);

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Register code that has used CHA for optimization.
  // TODO(srdjan): Also register kind of CHA optimization (e.g.: leaf class,
  // leaf method, ...).
  void RegisterCHACode(const Code& code);

  void DisableCHAOptimizedCode(const Class& subclass);

  void DisableAllCHAOptimizedCode();

  void DisableCHAImplementorUsers() { DisableAllCHAOptimizedCode(); }

  // Return the list of code objects that were compiled using CHA of this class.
  // These code objects will be invalidated if new subclasses of this class
  // are finalized.
  WeakArrayPtr dependent_code() const;
  void set_dependent_code(const WeakArray& array) const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  bool TraceAllocation(IsolateGroup* isolate_group) const;
  void SetTraceAllocation(bool trace_allocation) const;

  void CopyStaticFieldValues(ProgramReloadContext* reload_context,
                             const Class& old_cls) const;
  void PatchFieldsAndFunctions() const;
  void MigrateImplicitStaticClosures(ProgramReloadContext* context,
                                     const Class& new_cls) const;
  void CopyCanonicalConstants(const Class& old_cls) const;
  void CopyDeclarationType(const Class& old_cls) const;
  void CheckReload(const Class& replacement,
                   ProgramReloadContext* context) const;

  void AddInvocationDispatcher(const String& target_name,
                               const Array& args_desc,
                               const Function& dispatcher) const;

  static int32_t host_instance_size_in_words(const ClassPtr cls) {
    return cls->untag()->host_instance_size_in_words_;
  }

  static int32_t target_instance_size_in_words(const ClassPtr cls) {
#if defined(DART_PRECOMPILER)
    return cls->untag()->target_instance_size_in_words_;
#else
    return host_instance_size_in_words(cls);
#endif  // defined(DART_PRECOMPILER)
  }

  static int32_t host_next_field_offset_in_words(const ClassPtr cls) {
    return cls->untag()->host_next_field_offset_in_words_;
  }

  static int32_t target_next_field_offset_in_words(const ClassPtr cls) {
#if defined(DART_PRECOMPILER)
    return cls->untag()->target_next_field_offset_in_words_;
#else
    return host_next_field_offset_in_words(cls);
#endif  // defined(DART_PRECOMPILER)
  }

  static int32_t host_type_arguments_field_offset_in_words(const ClassPtr cls) {
    return cls->untag()->host_type_arguments_field_offset_in_words_;
  }

  static int32_t target_type_arguments_field_offset_in_words(
      const ClassPtr cls) {
#if defined(DART_PRECOMPILER)
    return cls->untag()->target_type_arguments_field_offset_in_words_;
#else
    return host_type_arguments_field_offset_in_words(cls);
#endif  // defined(DART_PRECOMPILER)
  }

  static intptr_t UnboxedFieldSizeInBytesByCid(intptr_t cid);
  void MarkFieldBoxedDuringReload(ClassTable* class_table,
                                  const Field& field) const;

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  void SetUserVisibleNameInClassTable();
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)

 private:
  TypePtr declaration_type() const {
    return untag()->declaration_type<std::memory_order_acquire>();
  }

  // Caches the declaration type of this class.
  void set_declaration_type(const Type& type) const;

  TypeArgumentsPtr declaration_instance_type_arguments() const {
    return untag()
        ->declaration_instance_type_arguments<std::memory_order_acquire>();
  }
  void set_declaration_instance_type_arguments(
      const TypeArguments& value) const;

  bool CanReloadFinalized(const Class& replacement,
                          ProgramReloadContext* context) const;
  bool CanReloadPreFinalized(const Class& replacement,
                             ProgramReloadContext* context) const;

  // Tells whether instances need morphing for reload.
  bool RequiresInstanceMorphing(ClassTable* class_table,
                                const Class& replacement) const;

  template <class FakeInstance, class TargetFakeInstance>
  static ClassPtr NewCommon(intptr_t index);

  enum MemberKind {
    kAny = 0,
    kStatic,
    kInstance,
    kInstanceAllowAbstract,
    kConstructor,
    kFactory,
  };
  enum StateBits {
    kConstBit = 0,
    kImplementedBit = 1,
    kClassFinalizedPos = 2,
    kClassFinalizedSize = 2,
    kClassLoadingPos = kClassFinalizedPos + kClassFinalizedSize,  // = 4
    kClassLoadingSize = 2,
    kAbstractBit = kClassLoadingPos + kClassLoadingSize,  // = 6
    kSynthesizedClassBit,
    kMixinAppAliasBit,
    kMixinTypeAppliedBit,
    kFieldsMarkedNullableBit,
    kEnumBit,
    kTransformedMixinApplicationBit,
    kIsAllocatedBit,
    kIsLoadedBit,
    kHasPragmaBit,
    kSealedBit,
    kMixinClassBit,
    kBaseClassBit,
    kInterfaceClassBit,
    kFinalBit,
    // Whether instances of the class cannot be sent across ports.
    //
    // Will be true iff
    //    - class is marked with `@pragma('vm:isolate-unsendable')
    //    - super class / super interface classes are marked as unsendable.
    //    - class has native fields.
    kIsIsolateUnsendableBit,
    // True if this class has `@pragma('vm:isolate-unsendable') annotation or
    // base class or implemented interfaces has this bit.
    kIsIsolateUnsendableDueToPragmaBit,
    // This class is a subtype of Future.
    kIsFutureSubtypeBit,
    // This class has a non-abstract subtype which is a subtype of Future.
    // It means that variable of static type based on this class may hold
    // a Future instance.
    kCanBeFutureBit,
  };
  class ConstBit : public BitField<uint32_t, bool, kConstBit, 1> {};
  class ImplementedBit : public BitField<uint32_t, bool, kImplementedBit, 1> {};
  class ClassFinalizedBits : public BitField<uint32_t,
                                             UntaggedClass::ClassFinalizedState,
                                             kClassFinalizedPos,
                                             kClassFinalizedSize> {};
  class ClassLoadingBits : public BitField<uint32_t,
                                           UntaggedClass::ClassLoadingState,
                                           kClassLoadingPos,
                                           kClassLoadingSize> {};
  class AbstractBit : public BitField<uint32_t, bool, kAbstractBit, 1> {};
  class SynthesizedClassBit
      : public BitField<uint32_t, bool, kSynthesizedClassBit, 1> {};
  class FieldsMarkedNullableBit
      : public BitField<uint32_t, bool, kFieldsMarkedNullableBit, 1> {};
  class EnumBit : public BitField<uint32_t, bool, kEnumBit, 1> {};
  class TransformedMixinApplicationBit
      : public BitField<uint32_t, bool, kTransformedMixinApplicationBit, 1> {};
  class IsAllocatedBit : public BitField<uint32_t, bool, kIsAllocatedBit, 1> {};
  class IsLoadedBit : public BitField<uint32_t, bool, kIsLoadedBit, 1> {};
  class HasPragmaBit : public BitField<uint32_t, bool, kHasPragmaBit, 1> {};
  class SealedBit : public BitField<uint32_t, bool, kSealedBit, 1> {};
  class MixinClassBit : public BitField<uint32_t, bool, kMixinClassBit, 1> {};
  class BaseClassBit : public BitField<uint32_t, bool, kBaseClassBit, 1> {};
  class InterfaceClassBit
      : public BitField<uint32_t, bool, kInterfaceClassBit, 1> {};
  class FinalBit : public BitField<uint32_t, bool, kFinalBit, 1> {};
  class IsIsolateUnsendableBit
      : public BitField<uint32_t, bool, kIsIsolateUnsendableBit, 1> {};
  class IsIsolateUnsendableDueToPragmaBit
      : public BitField<uint32_t, bool, kIsIsolateUnsendableDueToPragmaBit, 1> {
  };
  class IsFutureSubtypeBit
      : public BitField<uint32_t, bool, kIsFutureSubtypeBit, 1> {};
  class CanBeFutureBit : public BitField<uint32_t, bool, kCanBeFutureBit, 1> {};

  void set_name(const String& value) const;
  void set_user_name(const String& value) const;
  const char* GenerateUserVisibleName() const;
  void set_state_bits(intptr_t bits) const;
  void set_implementor_cid(intptr_t value) const;

  FunctionPtr CreateInvocationDispatcher(const String& target_name,
                                         const Array& args_desc,
                                         UntaggedFunction::Kind kind) const;

  FunctionPtr CreateRecordFieldGetter(const String& getter_name) const;

  // Returns the bitmap of unboxed fields
  UnboxedFieldBitmap CalculateFieldOffsets() const;

  // functions_hash_table is in use iff there are at least this many functions.
  static constexpr intptr_t kFunctionLookupHashThreshold = 16;

  // Initial value for the cached number of type arguments.
  static constexpr intptr_t kUnknownNumTypeArguments = -1;

  int16_t num_type_arguments() const {
    return LoadNonPointer<int16_t, std::memory_order_relaxed>(
        &untag()->num_type_arguments_);
  }

  uint32_t state_bits() const {
    // Ensure any following load instructions do not get performed before this
    // one.
    return LoadNonPointer<uint32_t, std::memory_order_acquire>(
        &untag()->state_bits_);
  }

 public:
  void set_num_type_arguments(intptr_t value) const;
  void set_num_type_arguments_unsafe(intptr_t value) const;

  bool has_pragma() const { return HasPragmaBit::decode(state_bits()); }
  void set_has_pragma(bool value) const;

  void set_is_isolate_unsendable(bool value) const;
  bool is_isolate_unsendable() const {
    ASSERT(is_finalized());  // This bit is initialized in class finalizer.
    return IsIsolateUnsendableBit::decode(state_bits());
  }

  void set_is_isolate_unsendable_due_to_pragma(bool value) const;
  bool is_isolate_unsendable_due_to_pragma() const {
    return IsIsolateUnsendableDueToPragmaBit::decode(state_bits());
  }

  void set_is_future_subtype(bool value) const;
  bool is_future_subtype() const {
    ASSERT(is_type_finalized());
    return IsFutureSubtypeBit::decode(state_bits());
  }

  void set_can_be_future(bool value) const;
  bool can_be_future() const { return CanBeFutureBit::decode(state_bits()); }

 private:
  void set_functions(const Array& value) const;
  void set_fields(const Array& value) const;
  void set_invocation_dispatcher_cache(const Array& cache) const;

  ArrayPtr invocation_dispatcher_cache() const;

  // Calculates number of type arguments of this class.
  // This includes type arguments of a superclass and takes overlapping
  // of type arguments into account.
  intptr_t ComputeNumTypeArguments() const;

  // Assigns empty array to all raw class array fields.
  void InitEmptyFields() const;

  static FunctionPtr CheckFunctionType(const Function& func, MemberKind kind);
  FunctionPtr LookupFunctionReadLocked(const String& name,
                                       MemberKind kind) const;
  FunctionPtr LookupFunctionAllowPrivate(const String& name,
                                         MemberKind kind) const;
  FieldPtr LookupField(const String& name, MemberKind kind) const;

  FunctionPtr LookupAccessorFunction(const char* prefix,
                                     intptr_t prefix_length,
                                     const String& name) const;

  // Allocate an instance class which has a VM implementation.
  template <class FakeInstance, class TargetFakeInstance>
  static ClassPtr New(intptr_t id,
                      IsolateGroup* isolate_group,
                      bool register_class = true,
                      bool is_abstract = false);

  // Helper that calls 'Class::New<Instance>(kIllegalCid)'.
  static ClassPtr NewInstanceClass();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Class, Object);
  friend class AbstractType;
  friend class Instance;
  friend class Object;
  friend class Type;
  friend class Intrinsifier;
  friend class ProgramWalker;
  friend class Precompiler;
  friend class ClassFinalizer;
};

// Classification of type genericity according to type parameter owners.
enum Genericity {
  kAny,           // Consider type params of current class and functions.
  kCurrentClass,  // Consider type params of current class only.
  kFunctions,     // Consider type params of current and parent functions.
};

// Wrapper of a [Class] with different [Script] and kernel binary.
//
// We use this as owner of [Field]/[Function] objects that were from a different
// script/kernel than the actual class object.
//
//  * used for corelib patches that live in different .dart files than the
//    library itself.
//
//  * used for library parts that live in different .dart files than the library
//    itself.
//
//  * used in reload to make old [Function]/[Field] objects have the old script
//    kernel data.
//
class PatchClass : public Object {
 public:
  ClassPtr wrapped_class() const { return untag()->wrapped_class(); }
  ScriptPtr script() const { return untag()->script(); }

  intptr_t kernel_library_index() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return untag()->kernel_library_index_;
#else
    return -1;
#endif
  }
  void set_kernel_library_index(intptr_t index) const {
    NOT_IN_PRECOMPILED(StoreNonPointer(&untag()->kernel_library_index_, index));
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  KernelProgramInfoPtr kernel_program_info() const {
    return untag()->kernel_program_info();
  }
  void set_kernel_program_info(const KernelProgramInfo& info) const;
#endif

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedPatchClass));
  }
  static bool IsInFullSnapshot(PatchClassPtr cls) {
    NoSafepointScope no_safepoint;
    return Class::IsInFullSnapshot(cls->untag()->wrapped_class());
  }

  static PatchClassPtr New(const Class& wrapped_class,
                           const KernelProgramInfo& info,
                           const Script& source);

 private:
  void set_wrapped_class(const Class& value) const;
  void set_script(const Script& value) const;

  static PatchClassPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(PatchClass, Object);
  friend class Class;
};

class SingleTargetCache : public Object {
 public:
  CodePtr target() const { return untag()->target(); }
  void set_target(const Code& target) const;
  static intptr_t target_offset() {
    return OFFSET_OF(UntaggedSingleTargetCache, target_);
  }

#define DEFINE_NON_POINTER_FIELD_ACCESSORS(type, name)                         \
  type name() const { return untag()->name##_; }                               \
  void set_##name(type value) const {                                          \
    StoreNonPointer(&untag()->name##_, value);                                 \
  }                                                                            \
  static intptr_t name##_offset() {                                            \
    return OFFSET_OF(UntaggedSingleTargetCache, name##_);                      \
  }

  DEFINE_NON_POINTER_FIELD_ACCESSORS(uword, entry_point);
  DEFINE_NON_POINTER_FIELD_ACCESSORS(intptr_t, lower_limit);
  DEFINE_NON_POINTER_FIELD_ACCESSORS(intptr_t, upper_limit);
#undef DEFINE_NON_POINTER_FIELD_ACCESSORS

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedSingleTargetCache));
  }

  static SingleTargetCachePtr New();

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(SingleTargetCache, Object);
  friend class Class;
};

class MonomorphicSmiableCall : public Object {
 public:
  classid_t expected_cid() const { return untag()->expected_cid_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedMonomorphicSmiableCall));
  }

  static MonomorphicSmiableCallPtr New(classid_t expected_cid,
                                       const Code& target);

  static intptr_t expected_cid_offset() {
    return OFFSET_OF(UntaggedMonomorphicSmiableCall, expected_cid_);
  }

  static intptr_t entrypoint_offset() {
    return OFFSET_OF(UntaggedMonomorphicSmiableCall, entrypoint_);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(MonomorphicSmiableCall, Object);
  friend class Class;
};

class CallSiteData : public Object {
 public:
  StringPtr target_name() const { return untag()->target_name(); }
  ArrayPtr arguments_descriptor() const { return untag()->args_descriptor(); }

  intptr_t TypeArgsLen() const;

  intptr_t CountWithTypeArgs() const;

  intptr_t CountWithoutTypeArgs() const;

  intptr_t SizeWithoutTypeArgs() const;

  intptr_t SizeWithTypeArgs() const;

  static intptr_t target_name_offset() {
    return OFFSET_OF(UntaggedCallSiteData, target_name_);
  }

  static intptr_t arguments_descriptor_offset() {
    return OFFSET_OF(UntaggedCallSiteData, args_descriptor_);
  }

 private:
  void set_target_name(const String& value) const;
  void set_arguments_descriptor(const Array& value) const;

  HEAP_OBJECT_IMPLEMENTATION(CallSiteData, Object)

  friend class ICData;
  friend class MegamorphicCache;
};

class UnlinkedCall : public CallSiteData {
 public:
  bool can_patch_to_monomorphic() const {
    return untag()->can_patch_to_monomorphic_;
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedUnlinkedCall));
  }

  uword Hash() const;
  bool Equals(const UnlinkedCall& other) const;

  static UnlinkedCallPtr New();

 private:
  friend class ICData;  // For set_*() methods.

  void set_can_patch_to_monomorphic(bool value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(UnlinkedCall, CallSiteData);
  friend class Class;
};

// Object holding information about an IC: test classes and their
// corresponding targets. The owner of the ICData can be either the function
// or the original ICData object. In case of background compilation we
// copy the ICData in a child object, thus freezing it during background
// compilation. Code may contain only original ICData objects.
//
// ICData's backing store is an array that logically contains several valid
// entries followed by a sentinel entry.
//
//   [<entry-0>, <...>, <entry-N>, <sentinel>]
//
// Each entry has the following form:
//
//   [arg0?, arg1?, argN?, count, target-function/code, exactness?]
//
// The <entry-X> need to contain valid type feedback.
// The <sentinel> entry and must have kIllegalCid value for all
// members of the entry except for the last one (`exactness` if
// present, otherwise `target-function/code`) - which we use as a backref:
//
//   * For empty ICData we use a cached/shared backing store. So there is no
//     unique backref, we use kIllegalCid instead.
//   * For non-empty ICData the backref in the backing store array will point to
//     the ICData object.
//
// Updating the ICData happens under a lock to avoid phantom-reads. The backing
// is treated as an immutable Copy-on-Write data structure: Adding to the ICData
// makes a copy with length+1 which will be store-release'd so any reader can
// see it (and doesn't need to hold a lock).
class ICData : public CallSiteData {
 public:
  FunctionPtr Owner() const;

  ICDataPtr Original() const;

  void SetOriginal(const ICData& value) const;

  bool IsOriginal() const { return Original() == this->ptr(); }

  intptr_t NumArgsTested() const;

  intptr_t deopt_id() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return -1;
#else
    return untag()->deopt_id_;
#endif
  }

  bool IsImmutable() const;

#if !defined(DART_PRECOMPILED_RUNTIME)
  AbstractTypePtr receivers_static_type() const {
    return untag()->receivers_static_type();
  }
  bool is_tracking_exactness() const {
    return untag()->state_bits_.Read<TrackingExactnessBit>();
  }
#else
  bool is_tracking_exactness() const { return false; }
#endif

// Note: only deopts with reasons before Unknown in this list are recorded in
// the ICData. All other reasons are used purely for informational messages
// printed during deoptimization itself.
#define DEOPT_REASONS(V)                                                       \
  V(BinarySmiOp)                                                               \
  V(BinaryInt64Op)                                                             \
  V(DoubleToSmi)                                                               \
  V(CheckSmi)                                                                  \
  V(CheckClass)                                                                \
  V(Unknown)                                                                   \
  V(PolymorphicInstanceCallTestFail)                                           \
  V(UnaryInt64Op)                                                              \
  V(BinaryDoubleOp)                                                            \
  V(UnaryOp)                                                                   \
  V(UnboxInteger)                                                              \
  V(Unbox)                                                                     \
  V(CheckArrayBound)                                                           \
  V(AtCall)                                                                    \
  V(GuardField)                                                                \
  V(TestCids)                                                                  \
  V(NumReasons)

  enum DeoptReasonId {
#define DEFINE_ENUM_LIST(name) kDeopt##name,
    DEOPT_REASONS(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
  };

  static constexpr intptr_t kLastRecordedDeoptReason = kDeoptUnknown - 1;

  enum DeoptFlags {
    // Deoptimization is caused by an optimistically hoisted instruction.
    kHoisted = 1 << 0,

    // Deoptimization is caused by an optimistically generalized bounds check.
    kGeneralized = 1 << 1
  };

  bool HasDeoptReasons() const { return DeoptReasons() != 0; }
  uint32_t DeoptReasons() const;
  void SetDeoptReasons(uint32_t reasons) const;

  bool HasDeoptReason(ICData::DeoptReasonId reason) const;
  void AddDeoptReason(ICData::DeoptReasonId reason) const;

  // Call site classification that is helpful for hot-reload. Call sites with
  // different `RebindRule` have to be rebound differently.
#define FOR_EACH_REBIND_RULE(V)                                                \
  V(Instance)                                                                  \
  V(NoRebind)                                                                  \
  V(NSMDispatch)                                                               \
  V(Optimized)                                                                 \
  V(Static)                                                                    \
  V(Super)

  enum RebindRule {
#define REBIND_ENUM_DEF(name) k##name,
    FOR_EACH_REBIND_RULE(REBIND_ENUM_DEF)
#undef REBIND_ENUM_DEF
        kNumRebindRules,
  };
  static const char* RebindRuleToCString(RebindRule r);
  static bool ParseRebindRule(const char* str, RebindRule* out);
  RebindRule rebind_rule() const;

  void set_is_megamorphic(bool value) const {
    untag()->state_bits_.UpdateBool<MegamorphicBit, std::memory_order_release>(
        value);
  }

  // The length of the array. This includes all sentinel entries including
  // the final one.
  intptr_t Length() const;

  intptr_t NumberOfChecks() const;

  // Discounts any checks with usage of zero.
  // Takes O(result)) time!
  intptr_t NumberOfUsedChecks() const;

  bool NumberOfChecksIs(intptr_t n) const;

  bool IsValidEntryIndex(intptr_t index) const {
    return 0 <= index && index < NumberOfChecks();
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedICData));
  }

  static intptr_t state_bits_offset() {
    return OFFSET_OF(UntaggedICData, state_bits_);
  }

  static intptr_t NumArgsTestedShift() { return kNumArgsTestedPos; }

  static intptr_t NumArgsTestedMask() {
    return ((1 << kNumArgsTestedSize) - 1) << kNumArgsTestedPos;
  }

  static intptr_t entries_offset() {
    return OFFSET_OF(UntaggedICData, entries_);
  }

  static intptr_t owner_offset() { return OFFSET_OF(UntaggedICData, owner_); }

#if !defined(DART_PRECOMPILED_RUNTIME)
  static intptr_t receivers_static_type_offset() {
    return OFFSET_OF(UntaggedICData, receivers_static_type_);
  }
#endif

  // NOTE: Can only be called during reload.
  void Clear(const CallSiteResetter& proof_of_reload) const {
    TruncateTo(0, proof_of_reload);
  }

  // NOTE: Can only be called during reload.
  void TruncateTo(intptr_t num_checks,
                  const CallSiteResetter& proof_of_reload) const;

  // Clears the count for entry |index|.
  // NOTE: Can only be called during reload.
  void ClearCountAt(intptr_t index,
                    const CallSiteResetter& proof_of_reload) const;

  // Clear all entries with the sentinel value and reset the first entry
  // with the dummy target entry.
  // NOTE: Can only be called during reload.
  void ClearAndSetStaticTarget(const Function& func,
                               const CallSiteResetter& proof_of_reload) const;

  void DebugDump() const;

  // Adding checks.

  // Ensures there is a check for [class_ids].
  //
  // Calls [AddCheck] iff there is no existing check. Ensures test (and
  // potential update) will be performed under exclusive lock to guard against
  // multiple threads trying to add the same check.
  void EnsureHasCheck(const GrowableArray<intptr_t>& class_ids,
                      const Function& target,
                      intptr_t count = 1) const;

  // Adds one more class test to ICData. Length of 'classes' must be equal to
  // the number of arguments tested. Use only for num_args_tested > 1.
  void AddCheck(const GrowableArray<intptr_t>& class_ids,
                const Function& target,
                intptr_t count = 1) const;

  StaticTypeExactnessState GetExactnessAt(intptr_t count) const;

  // Ensures there is a receiver check for [receiver_class_id].
  //
  // Calls [AddCheckReceiverCheck] iff there is no existing check. Ensures
  // test (and potential update) will be performed under exclusive lock to
  // guard against multiple threads trying to add the same check.
  void EnsureHasReceiverCheck(
      intptr_t receiver_class_id,
      const Function& target,
      intptr_t count = 1,
      StaticTypeExactnessState exactness =
          StaticTypeExactnessState::NotTracking()) const;

  // Adds sorted so that Smi is the first class-id. Use only for
  // num_args_tested == 1.
  void AddReceiverCheck(intptr_t receiver_class_id,
                        const Function& target,
                        intptr_t count = 1,
                        StaticTypeExactnessState exactness =
                            StaticTypeExactnessState::NotTracking()) const;

  // Retrieving checks.

  void GetCheckAt(intptr_t index,
                  GrowableArray<intptr_t>* class_ids,
                  Function* target) const;
  void GetClassIdsAt(intptr_t index, GrowableArray<intptr_t>* class_ids) const;

  // Only for 'num_args_checked == 1'.
  void GetOneClassCheckAt(intptr_t index,
                          intptr_t* class_id,
                          Function* target) const;
  // Only for 'num_args_checked == 1'.
  intptr_t GetCidAt(intptr_t index) const;

  intptr_t GetReceiverClassIdAt(intptr_t index) const;
  intptr_t GetClassIdAt(intptr_t index, intptr_t arg_nr) const;

  FunctionPtr GetTargetAt(intptr_t index) const;

  void IncrementCountAt(intptr_t index, intptr_t value) const;
  void SetCountAt(intptr_t index, intptr_t value) const;
  intptr_t GetCountAt(intptr_t index) const;
  intptr_t AggregateCount() const;

  // Returns this->untag() if num_args_tested == 1 and arg_nr == 1, otherwise
  // returns a new ICData object containing only unique arg_nr checks.
  // Returns only used entries.
  ICDataPtr AsUnaryClassChecksForArgNr(intptr_t arg_nr) const;
  ICDataPtr AsUnaryClassChecks() const { return AsUnaryClassChecksForArgNr(0); }

  // Returns ICData with aggregated receiver count, sorted by highest count.
  // Smi not first!! (the convention for ICData used in code generation is that
  // Smi check is first)
  // Used for printing and optimizations.
  ICDataPtr AsUnaryClassChecksSortedByCount() const;

  UnlinkedCallPtr AsUnlinkedCall() const;

  bool HasReceiverClassId(intptr_t class_id) const;

  // Note: passing non-null receiver_type enables exactness tracking for
  // the receiver type. Receiver type is expected to be a fully
  // instantiated generic (but not a FutureOr).
  // See StaticTypeExactnessState for more information.
  static ICDataPtr New(
      const Function& owner,
      const String& target_name,
      const Array& arguments_descriptor,
      intptr_t deopt_id,
      intptr_t num_args_tested,
      RebindRule rebind_rule,
      const AbstractType& receiver_type = Object::null_abstract_type());

  // Similar to [New] makes the ICData have an initial (cids, target) entry.
  static ICDataPtr NewWithCheck(
      const Function& owner,
      const String& target_name,
      const Array& arguments_descriptor,
      intptr_t deopt_id,
      intptr_t num_args_tested,
      RebindRule rebind_rule,
      GrowableArray<intptr_t>* cids,
      const Function& target,
      const AbstractType& receiver_type = Object::null_abstract_type());

  static ICDataPtr NewForStaticCall(const Function& owner,
                                    const Function& target,
                                    const Array& arguments_descriptor,
                                    intptr_t deopt_id,
                                    intptr_t num_args_tested,
                                    RebindRule rebind_rule);

  static ICDataPtr NewFrom(const ICData& from, intptr_t num_args_tested);

  // Generates a new ICData with descriptor and data array copied (deep clone).
  static ICDataPtr Clone(const ICData& from);

  // Gets the [ICData] from the [ICData::entries_] array (which stores a back
  // ref).
  //
  // May return `null` if the [ICData] is empty.
  static ICDataPtr ICDataOfEntriesArray(const Array& array);

  static intptr_t TestEntryLengthFor(intptr_t num_args,
                                     bool tracking_exactness);

  static intptr_t CountIndexFor(intptr_t num_args) { return num_args; }
  static intptr_t EntryPointIndexFor(intptr_t num_args) { return num_args; }

  static intptr_t TargetIndexFor(intptr_t num_args) { return num_args + 1; }
  static intptr_t CodeIndexFor(intptr_t num_args) { return num_args + 1; }

  static intptr_t ExactnessIndexFor(intptr_t num_args) { return num_args + 2; }

  bool IsUsedAt(intptr_t i) const;

  void PrintToJSONArray(const JSONArray& jsarray,
                        TokenPosition token_pos) const;

  // Initialize the preallocated empty ICData entry arrays.
  static void Init();

  // Clear the preallocated empty ICData entry arrays.
  static void Cleanup();

  // We cache ICData with 0, 1, 2 arguments tested without exactness
  // tracking and with 1 argument tested with exactness tracking.
  enum {
    kCachedICDataZeroArgTestedWithoutExactnessTrackingIdx = 0,
    kCachedICDataMaxArgsTestedWithoutExactnessTracking = 2,
    kCachedICDataOneArgWithExactnessTrackingIdx =
        kCachedICDataZeroArgTestedWithoutExactnessTrackingIdx +
        kCachedICDataMaxArgsTestedWithoutExactnessTracking + 1,
    kCachedICDataArrayCount = kCachedICDataOneArgWithExactnessTrackingIdx + 1,
  };

  bool is_static_call() const;

  intptr_t FindCheck(const GrowableArray<intptr_t>& cids) const;

  ArrayPtr entries() const {
    return untag()->entries<std::memory_order_acquire>();
  }

  bool receiver_cannot_be_smi() const {
    return untag()->state_bits_.Read<ReceiverCannotBeSmiBit>();
  }

  void set_receiver_cannot_be_smi(bool value) const {
    untag()->state_bits_.UpdateBool<ReceiverCannotBeSmiBit>(value);
  }

  uword Hash() const;

 private:
  static ICDataPtr New();

  // Grows the array and also sets the argument to the index that should be used
  // for the new entry.
  ArrayPtr Grow(intptr_t* index) const;

  void set_deopt_id(intptr_t value) const;
  void set_entries(const Array& value) const;
  void set_owner(const Function& value) const;
  void set_rebind_rule(uint32_t rebind_rule) const;
  void clear_state_bits() const;
  void set_tracking_exactness(bool value) const {
    untag()->state_bits_.UpdateBool<TrackingExactnessBit>(value);
  }

  // Does entry |index| contain the sentinel value?
  void SetNumArgsTested(intptr_t value) const;
  void SetReceiversStaticType(const AbstractType& type) const;
  DEBUG_ONLY(void AssertInvariantsAreSatisfied() const;)

  static void SetTargetAtPos(const Array& data,
                             intptr_t data_pos,
                             intptr_t num_args_tested,
                             const Function& target);
  void AddCheckInternal(const GrowableArray<intptr_t>& class_ids,
                        const Function& target,
                        intptr_t count) const;
  void AddReceiverCheckInternal(intptr_t receiver_class_id,
                                const Function& target,
                                intptr_t count,
                                StaticTypeExactnessState exactness) const;

  // This bit is set when a call site becomes megamorphic and starts using a
  // MegamorphicCache instead of ICData. It means that the entries in the
  // ICData are incomplete and the MegamorphicCache needs to also be consulted
  // to list the call site's observed receiver classes and targets.
  // In the compiler, this should only be read once by CallTargets to avoid the
  // compiler seeing an unstable set of feedback.
  bool is_megamorphic() const {
    // Ensure any following load instructions do not get performed before this
    // one.
    return untag()
        ->state_bits_.Read<MegamorphicBit, std::memory_order_acquire>();
  }

  bool ValidateInterceptor(const Function& target) const;

  enum {
    kNumArgsTestedPos = 0,
    kNumArgsTestedSize = 2,
    kTrackingExactnessPos = kNumArgsTestedPos + kNumArgsTestedSize,
    kTrackingExactnessSize = 1,
    kDeoptReasonPos = kTrackingExactnessPos + kTrackingExactnessSize,
    kDeoptReasonSize = kLastRecordedDeoptReason + 1,
    kRebindRulePos = kDeoptReasonPos + kDeoptReasonSize,
    kRebindRuleSize = 3,
    kMegamorphicPos = kRebindRulePos + kRebindRuleSize,
    kMegamorphicSize = 1,
    kReceiverCannotBeSmiPos = kMegamorphicPos + kMegamorphicSize,
    kReceiverCannotBeSmiSize = 1,
  };

  COMPILE_ASSERT(kReceiverCannotBeSmiPos + kReceiverCannotBeSmiSize <=
                 sizeof(UntaggedICData::state_bits_) * kBitsPerWord);
  COMPILE_ASSERT(kNumRebindRules <= (1 << kRebindRuleSize));

  class NumArgsTestedBits : public BitField<uint32_t,
                                            uint32_t,
                                            kNumArgsTestedPos,
                                            kNumArgsTestedSize> {};
  class TrackingExactnessBit : public BitField<uint32_t,
                                               bool,
                                               kTrackingExactnessPos,
                                               kTrackingExactnessSize> {};
  class DeoptReasonBits : public BitField<uint32_t,
                                          uint32_t,
                                          ICData::kDeoptReasonPos,
                                          ICData::kDeoptReasonSize> {};
  class RebindRuleBits : public BitField<uint32_t,
                                         uint32_t,
                                         ICData::kRebindRulePos,
                                         ICData::kRebindRuleSize> {};
  class MegamorphicBit
      : public BitField<uint32_t, bool, kMegamorphicPos, kMegamorphicSize> {};

  class ReceiverCannotBeSmiBit : public BitField<uint32_t,
                                                 bool,
                                                 kReceiverCannotBeSmiPos,
                                                 kReceiverCannotBeSmiSize> {};

#if defined(DEBUG)
  // Used in asserts to verify that a check is not added twice.
  bool HasCheck(const GrowableArray<intptr_t>& cids) const;
#endif  // DEBUG

  intptr_t TestEntryLength() const;
  static ArrayPtr NewNonCachedEmptyICDataArray(intptr_t num_args_tested,
                                               bool tracking_exactness);
  static ArrayPtr CachedEmptyICDataArray(intptr_t num_args_tested,
                                         bool tracking_exactness);
  static bool IsCachedEmptyEntry(const Array& array);
  static ICDataPtr NewDescriptor(Zone* zone,
                                 const Function& owner,
                                 const String& target_name,
                                 const Array& arguments_descriptor,
                                 intptr_t deopt_id,
                                 intptr_t num_args_tested,
                                 RebindRule rebind_rule,
                                 const AbstractType& receiver_type);

  static void WriteSentinel(const Array& data,
                            intptr_t test_entry_length,
                            const Object& back_ref);

  // A cache of VM heap allocated preinitialized empty ic data entry arrays.
  static ArrayPtr cached_icdata_arrays_[kCachedICDataArrayCount];

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ICData, CallSiteData);
  friend class CallSiteResetter;
  friend class CallTargets;
  friend class Class;
  friend class VMDeserializationRoots;
  friend class ICDataTestTask;
  friend class VMSerializationRoots;
};

// Often used constants for number of free function type parameters.
enum {
  kNoneFree = 0,

  // 'kCurrentAndEnclosingFree' is used when partially applying a signature
  // function to a set of type arguments. It indicates that the set of type
  // parameters declared by the current function and enclosing functions should
  // be considered free, and the current function type parameters should be
  // substituted as well.
  //
  // For instance, if the signature "<T>(T, R) => T" is instantiated with
  // function type arguments [int, String] and kCurrentAndEnclosingFree is
  // supplied, the result of the instantiation will be "(String, int) => int".
  kCurrentAndEnclosingFree = kMaxInt32 - 1,

  // Only parameters declared by enclosing functions are free.
  kAllFree = kMaxInt32,
};

// Formatting configuration for Function::PrintName.
struct NameFormattingParams {
  Object::NameVisibility name_visibility;
  bool disambiguate_names;

  // By default function name includes the name of the enclosing class if any.
  // However in some contexts this information is redundant and class name
  // is already known. In this case setting |include_class_name| to false
  // allows you to exclude this information from the formatted name.
  bool include_class_name = true;

  // By default function name includes the name of the enclosing function if
  // any. However in some contexts this information is redundant and
  // the name of the enclosing function is already known. In this case
  // setting |include_parent_name| to false allows to exclude this information
  // from the formatted name.
  bool include_parent_name = true;

  NameFormattingParams(Object::NameVisibility visibility,
                       Object::NameDisambiguation name_disambiguation =
                           Object::NameDisambiguation::kNo)
      : name_visibility(visibility),
        disambiguate_names(name_disambiguation ==
                           Object::NameDisambiguation::kYes) {}

  static NameFormattingParams DisambiguatedWithoutClassName(
      Object::NameVisibility visibility) {
    NameFormattingParams params(visibility, Object::NameDisambiguation::kYes);
    params.include_class_name = false;
    return params;
  }

  static NameFormattingParams DisambiguatedUnqualified(
      Object::NameVisibility visibility) {
    NameFormattingParams params(visibility, Object::NameDisambiguation::kYes);
    params.include_class_name = false;
    params.include_parent_name = false;
    return params;
  }
};

enum class FfiFunctionKind : uint8_t {
  kCall,
  kIsolateLocalStaticCallback,
  kIsolateLocalClosureCallback,
  kAsyncCallback,
};

class Function : public Object {
 public:
  StringPtr name() const { return untag()->name(); }
  StringPtr UserVisibleName() const;  // Same as scrubbed name.
  const char* UserVisibleNameCString() const;

  const char* NameCString(NameVisibility name_visibility) const;

  void PrintName(const NameFormattingParams& params,
                 BaseTextBuffer* printer) const;
  StringPtr QualifiedScrubbedName() const;
  const char* QualifiedScrubbedNameCString() const;
  StringPtr QualifiedUserVisibleName() const;
  const char* QualifiedUserVisibleNameCString() const;

  virtual StringPtr DictionaryName() const { return name(); }

  StringPtr GetSource() const;

  // Set the "C signature" for an FFI trampoline.
  // Can only be used on FFI trampolines.
  void SetFfiCSignature(const FunctionType& sig) const;

  // Retrieves the "C signature" for an FFI trampoline.
  // Can only be used on FFI trampolines.
  FunctionTypePtr FfiCSignature() const;

  bool FfiCSignatureContainsHandles() const;
  bool FfiCSignatureReturnsStruct() const;

  // Can only be called on FFI trampolines.
  // -1 for Dart -> native calls.
  int32_t FfiCallbackId() const;

  // Should be called when ffi trampoline function object is created.
  void AssignFfiCallbackId(int32_t callback_id) const;

  // Can only be called on FFI trampolines.
  bool FfiIsLeaf() const;

  // Can only be called on FFI trampolines.
  void SetFfiIsLeaf(bool is_leaf) const;

  // Can only be called on FFI trampolines.
  // Null for Dart -> native calls.
  FunctionPtr FfiCallbackTarget() const;

  // Can only be called on FFI trampolines.
  void SetFfiCallbackTarget(const Function& target) const;

  // Can only be called on FFI trampolines.
  // Null for Dart -> native calls.
  InstancePtr FfiCallbackExceptionalReturn() const;

  // Can only be called on FFI trampolines.
  void SetFfiCallbackExceptionalReturn(const Instance& value) const;

  // Can only be called on FFI trampolines.
  FfiFunctionKind GetFfiFunctionKind() const;

  // Can only be called on FFI trampolines.
  void SetFfiFunctionKind(FfiFunctionKind value) const;

  // Return the signature of this function.
  PRECOMPILER_WSR_FIELD_DECLARATION(FunctionType, signature);
  void SetSignature(const FunctionType& value) const;
  static intptr_t signature_offset() {
    return OFFSET_OF(UntaggedFunction, signature_);
  }

  // Build a string of the form '<T>(T, {B b, C c}) => R' representing the
  // internal signature of the given function. In this example, T is a type
  // parameter of this function and R is a type parameter of class C, the owner
  // of the function. B and C are not type parameters.
  StringPtr InternalSignature() const;

  // Build a string of the form '<T>(T, {B b, C c}) => R' representing the
  // user visible signature of the given function. In this example, T is a type
  // parameter of this function and R is a type parameter of class C, the owner
  // of the function. B and C are not type parameters.
  // Implicit parameters are hidden.
  StringPtr UserVisibleSignature() const;

  // Returns true if the signature of this function is instantiated, i.e. if it
  // does not involve generic parameter types or generic result type.
  // Note that function type parameters declared by this function do not make
  // its signature uninstantiated, only type parameters declared by parent
  // generic functions or class type parameters.
  bool HasInstantiatedSignature(
      Genericity genericity = kAny,
      intptr_t num_free_fun_type_params = kAllFree) const;

  bool IsPrivate() const;

  ClassPtr Owner() const;
  void set_owner(const Object& value) const;
  ScriptPtr script() const;
#if !defined(DART_PRECOMPILED_RUNTIME)
  KernelProgramInfoPtr KernelProgramInfo() const;
#endif
  ObjectPtr RawOwner() const { return untag()->owner(); }

  // The NNBD mode of the library declaring this function.
  // TODO(alexmarkov): nnbd_mode() doesn't work for mixins.
  // It should be either removed or fixed.
  NNBDMode nnbd_mode() const { return Class::Handle(Owner()).nnbd_mode(); }

  RegExpPtr regexp() const;
  intptr_t string_specialization_cid() const;
  bool is_sticky_specialization() const;
  void SetRegExpData(const RegExp& regexp,
                     intptr_t string_specialization_cid,
                     bool sticky) const;

  StringPtr native_name() const;
  void set_native_name(const String& name) const;

  AbstractTypePtr result_type() const {
    return signature()->untag()->result_type();
  }

  // The parameters, starting with NumImplicitParameters() parameters which are
  // only visible to the VM, but not to Dart users.
  // Note that type checks exclude implicit parameters.
  AbstractTypePtr ParameterTypeAt(intptr_t index) const;
  ArrayPtr parameter_types() const {
    return signature()->untag()->parameter_types();
  }

  // Outside of the AOT runtime, functions store the names for their positional
  // parameters, and delegate storage of the names for named parameters to
  // their signature. These methods handle fetching the name from and
  // setting the name to the correct location.
  StringPtr ParameterNameAt(intptr_t index) const;
  // Only valid for positional parameter indexes, as this should be called
  // explicitly on the signature for named parameters.
  void SetParameterNameAt(intptr_t index, const String& value) const;
  // Creates an appropriately sized array in the function to hold positional
  // parameter names, using the positional parameter count in the signature.
  // Uses same default space as Function::New.
  void CreateNameArray(Heap::Space space = Heap::kOld) const;

  // Delegates to the signature, which stores the named parameter flags.
  bool IsRequiredAt(intptr_t index) const;

  // The formal type parameters, their bounds, and defaults, are specified as an
  // object of type TypeParameters stored in the signature.
  TypeParametersPtr type_parameters() const {
    return signature()->untag()->type_parameters();
  }

  // Returns the number of local type arguments for this function.
  intptr_t NumTypeParameters() const;
  // Return the cumulative number of type arguments in all parent functions.
  intptr_t NumParentTypeArguments() const;
  // Return the cumulative number of type arguments for this function, including
  // type arguments for all parent functions.
  intptr_t NumTypeArguments() const;
  // Return whether this function declares local type arguments.
  bool IsGeneric() const;
  // Returns whether any parent function of this function is generic.
  bool HasGenericParent() const { return NumParentTypeArguments() > 0; }

  // Return the type parameter declared at index.
  TypeParameterPtr TypeParameterAt(
      intptr_t index,
      Nullability nullability = Nullability::kNonNullable) const;

  // Not thread-safe; must be called in the main thread.
  // Sets function's code and code's function.
  void InstallOptimizedCode(const Code& code) const;
  void AttachCode(const Code& value) const;
  void SetInstructions(const Code& value) const;
  void SetInstructionsSafe(const Code& value) const;
  void ClearCode() const;
  void ClearCodeSafe() const;

  // Disables optimized code and switches to unoptimized code.
  void SwitchToUnoptimizedCode() const;

  // Ensures that the function has code. If there is no code it compiles the
  // unoptimized version of the code.  If the code contains errors, it calls
  // Exceptions::PropagateError and does not return.  Normally returns the
  // current code, whether it is optimized or unoptimized.
  CodePtr EnsureHasCode() const;

  // Disables optimized code and switches to unoptimized code (or the lazy
  // compilation stub).
  void SwitchToLazyCompiledUnoptimizedCode() const;

  // Compiles unoptimized code (if necessary) and attaches it to the function.
  void EnsureHasCompiledUnoptimizedCode() const;

  // Return the most recently compiled and installed code for this function.
  // It is not the only Code object that points to this function.
  CodePtr CurrentCode() const { return CurrentCodeOf(ptr()); }

  bool SafeToClosurize() const;

  static CodePtr CurrentCodeOf(const FunctionPtr function) {
    return function->untag()->code();
  }

  CodePtr unoptimized_code() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return static_cast<CodePtr>(Object::null());
#else
    return untag()->unoptimized_code();
#endif
  }
  void set_unoptimized_code(const Code& value) const;
  bool HasCode() const;
  static bool HasCode(FunctionPtr function);

  static intptr_t code_offset() { return OFFSET_OF(UntaggedFunction, code_); }

  uword entry_point() const {
    return EntryPointOf(ptr());
  }
  static uword EntryPointOf(const FunctionPtr function) {
    return function->untag()->entry_point_;
  }

  static intptr_t entry_point_offset(
      CodeEntryKind entry_kind = CodeEntryKind::kNormal) {
    switch (entry_kind) {
      case CodeEntryKind::kNormal:
        return OFFSET_OF(UntaggedFunction, entry_point_);
      case CodeEntryKind::kUnchecked:
        return OFFSET_OF(UntaggedFunction, unchecked_entry_point_);
      default:
        UNREACHABLE();
    }
  }

  static intptr_t unchecked_entry_point_offset() {
    return OFFSET_OF(UntaggedFunction, unchecked_entry_point_);
  }

  virtual uword Hash() const;

  // Returns true if there is at least one debugger breakpoint
  // set in this function.
  bool HasBreakpoint() const;

  ContextScopePtr context_scope() const;
  void set_context_scope(const ContextScope& value) const;

  struct AwaiterLink {
    // Context depth at which the `@pragma('vm:awaiter-link')` variable
    // is located.
    uint8_t depth = UntaggedClosureData::kNoAwaiterLinkDepth;
    // Context index at which the `@pragma('vm:awaiter-link')` variable
    // is located.
    uint8_t index = static_cast<uint8_t>(-1);
  };

  AwaiterLink awaiter_link() const;
  void set_awaiter_link(AwaiterLink link) const;
  bool HasAwaiterLink() const {
    return IsClosureFunction() &&
           (awaiter_link().depth != UntaggedClosureData::kNoAwaiterLinkDepth);
  }

  // Enclosing function of this local function.
  FunctionPtr parent_function() const;

  using DefaultTypeArgumentsKind =
      UntaggedClosureData::DefaultTypeArgumentsKind;

  // Returns a canonicalized vector of the type parameters instantiated
  // to bounds. If non-generic, the empty type arguments vector is returned.
  TypeArgumentsPtr InstantiateToBounds(
      Thread* thread,
      DefaultTypeArgumentsKind* kind_out = nullptr) const;

  // Only usable for closure functions.
  DefaultTypeArgumentsKind default_type_arguments_kind() const;
  void set_default_type_arguments_kind(DefaultTypeArgumentsKind value) const;

  // Enclosing outermost function of this local function.
  FunctionPtr GetOutermostFunction() const;

  void set_extracted_method_closure(const Function& function) const;
  FunctionPtr extracted_method_closure() const;

  void set_saved_args_desc(const Array& array) const;
  ArrayPtr saved_args_desc() const;

  bool HasSavedArgumentsDescriptor() const {
    return IsInvokeFieldDispatcher() || IsNoSuchMethodDispatcher();
  }

  void set_accessor_field(const Field& value) const;
  FieldPtr accessor_field() const;

  bool IsRegularFunction() const {
    return kind() == UntaggedFunction::kRegularFunction;
  }

  bool IsMethodExtractor() const {
    return kind() == UntaggedFunction::kMethodExtractor;
  }

  bool IsNoSuchMethodDispatcher() const {
    return kind() == UntaggedFunction::kNoSuchMethodDispatcher;
  }

  bool IsRecordFieldGetter() const {
    return kind() == UntaggedFunction::kRecordFieldGetter;
  }

  bool IsInvokeFieldDispatcher() const {
    return kind() == UntaggedFunction::kInvokeFieldDispatcher;
  }

  bool IsDynamicInvokeFieldDispatcher() const {
    return IsInvokeFieldDispatcher() &&
           IsDynamicInvocationForwarderName(name());
  }

  // Performs all the checks that don't require the current thread first, to
  // avoid retrieving it unless they all pass. If you have a handle on the
  // current thread, call the version that takes one instead.
  bool IsDynamicClosureCallDispatcher() const {
    if (!IsDynamicInvokeFieldDispatcher()) return false;
    return IsDynamicClosureCallDispatcher(Thread::Current());
  }
  bool IsDynamicClosureCallDispatcher(Thread* thread) const;

  bool IsDynamicInvocationForwarder() const {
    return kind() == UntaggedFunction::kDynamicInvocationForwarder;
  }

  bool IsImplicitGetterOrSetter() const {
    return kind() == UntaggedFunction::kImplicitGetter ||
           kind() == UntaggedFunction::kImplicitSetter ||
           kind() == UntaggedFunction::kImplicitStaticGetter;
  }

  // Returns true iff an implicit closure function has been created
  // for this function.
  bool HasImplicitClosureFunction() const {
    return implicit_closure_function() != null();
  }

  // Returns the closure function implicitly created for this function.  If none
  // exists yet, create one and remember it.  Implicit closure functions are
  // used in VM Closure instances that represent results of tear-off operations.
  FunctionPtr ImplicitClosureFunction() const;
  void DropUncompiledImplicitClosureFunction() const;

  // Return the closure implicitly created for this function.
  // If none exists yet, create one and remember it.
  ClosurePtr ImplicitStaticClosure() const;

  ClosurePtr ImplicitInstanceClosure(const Instance& receiver) const;

  // Returns the target of the implicit closure or null if the target is now
  // invalid (e.g., mismatched argument shapes after a reload).
  FunctionPtr ImplicitClosureTarget(Zone* zone) const;

  FunctionPtr ForwardingTarget() const;
  void SetForwardingTarget(const Function& target) const;

  UntaggedFunction::Kind kind() const {
    return untag()->kind_tag_.Read<KindBits>();
  }

  UntaggedFunction::AsyncModifier modifier() const {
    return untag()->kind_tag_.Read<ModifierBits>();
  }

  static const char* KindToCString(UntaggedFunction::Kind kind);

  bool IsConstructor() const {
    return kind() == UntaggedFunction::kConstructor;
  }
  bool IsGenerativeConstructor() const {
    return IsConstructor() && !is_static();
  }
  bool IsImplicitConstructor() const;
  bool IsFactory() const { return IsConstructor() && is_static(); }

  bool HasThisParameter() const {
    return IsDynamicFunction(/*allow_abstract=*/true) ||
           IsGenerativeConstructor() || (IsFieldInitializer() && !is_static());
  }

  bool IsDynamicFunction(bool allow_abstract = false) const {
    if (is_static() || (!allow_abstract && is_abstract())) {
      return false;
    }
    switch (kind()) {
      case UntaggedFunction::kRegularFunction:
      case UntaggedFunction::kGetterFunction:
      case UntaggedFunction::kSetterFunction:
      case UntaggedFunction::kImplicitGetter:
      case UntaggedFunction::kImplicitSetter:
      case UntaggedFunction::kMethodExtractor:
      case UntaggedFunction::kNoSuchMethodDispatcher:
      case UntaggedFunction::kInvokeFieldDispatcher:
      case UntaggedFunction::kDynamicInvocationForwarder:
      case UntaggedFunction::kRecordFieldGetter:
        return true;
      case UntaggedFunction::kClosureFunction:
      case UntaggedFunction::kImplicitClosureFunction:
      case UntaggedFunction::kConstructor:
      case UntaggedFunction::kImplicitStaticGetter:
      case UntaggedFunction::kFieldInitializer:
      case UntaggedFunction::kIrregexpFunction:
        return false;
      default:
        UNREACHABLE();
        return false;
    }
  }
  bool IsStaticFunction() const {
    if (!is_static()) {
      return false;
    }
    switch (kind()) {
      case UntaggedFunction::kRegularFunction:
      case UntaggedFunction::kGetterFunction:
      case UntaggedFunction::kSetterFunction:
      case UntaggedFunction::kImplicitGetter:
      case UntaggedFunction::kImplicitSetter:
      case UntaggedFunction::kImplicitStaticGetter:
      case UntaggedFunction::kFieldInitializer:
      case UntaggedFunction::kIrregexpFunction:
        return true;
      case UntaggedFunction::kClosureFunction:
      case UntaggedFunction::kImplicitClosureFunction:
      case UntaggedFunction::kConstructor:
      case UntaggedFunction::kMethodExtractor:
      case UntaggedFunction::kNoSuchMethodDispatcher:
      case UntaggedFunction::kInvokeFieldDispatcher:
      case UntaggedFunction::kDynamicInvocationForwarder:
      case UntaggedFunction::kRecordFieldGetter:
        return false;
      default:
        UNREACHABLE();
        return false;
    }
  }

  bool NeedsTypeArgumentTypeChecks() const {
    return !(is_static() || (kind() == UntaggedFunction::kConstructor));
  }

  bool NeedsArgumentTypeChecks() const {
    return !(is_static() || (kind() == UntaggedFunction::kConstructor));
  }

  bool NeedsMonomorphicCheckedEntry(Zone* zone) const;
  bool HasDynamicCallers(Zone* zone) const;
  bool PrologueNeedsArgumentsDescriptor() const;

  bool MayHaveUncheckedEntryPoint() const;

  TokenPosition token_pos() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return TokenPosition::kNoSource;
#else
    return untag()->token_pos_;
#endif
  }
  void set_token_pos(TokenPosition value) const;

  TokenPosition end_token_pos() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return TokenPosition::kNoSource;
#else
    return untag()->end_token_pos_;
#endif
  }
  void set_end_token_pos(TokenPosition value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    StoreNonPointer(&untag()->end_token_pos_, value);
#endif
  }

#if !defined(PRODUCT) &&                                                       \
    (defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME))
  int32_t line() const {
    return untag()->token_pos_.Serialize();
  }

  void set_line(int32_t line) const {
    StoreNonPointer(&untag()->token_pos_, TokenPosition::Deserialize(line));
  }
#endif

  // Returns the size of the source for this function.
  intptr_t SourceSize() const;

  uint32_t packed_fields() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    return untag()->packed_fields_;
#endif
  }
  void set_packed_fields(uint32_t packed_fields) const;

  // Returns the number of required positional parameters.
  intptr_t num_fixed_parameters() const;
  // Returns the number of optional parameters, whether positional or named.
  bool HasOptionalParameters() const;
  // Returns whether the function has optional named parameters.
  bool HasOptionalNamedParameters() const;
  // Returns whether the function has required named parameters.
  bool HasRequiredNamedParameters() const;
  // Returns whether the function has optional positional parameters.
  bool HasOptionalPositionalParameters() const;
  // Returns the number of optional parameters, or 0 if none.
  intptr_t NumOptionalParameters() const;
  // Returns the number of optional positional parameters, or 0 if none.
  intptr_t NumOptionalPositionalParameters() const;
  // Returns the number of optional named parameters, or 0 if none.
  intptr_t NumOptionalNamedParameters() const;
  // Returns the total number of both required and optional parameters.
  intptr_t NumParameters() const;
  // Returns the number of implicit parameters, e.g., this for instance methods.
  intptr_t NumImplicitParameters() const;

  // Returns true if parameters of this function are copied into the frame
  // in the function prologue.
  bool MakesCopyOfParameters() const {
    return HasOptionalParameters() || IsSuspendableFunction();
  }

#if defined(DART_PRECOMPILED_RUNTIME)
#define DEFINE_GETTERS_AND_SETTERS(return_type, type, name)                    \
  static intptr_t name##_offset() {                                            \
    UNREACHABLE();                                                             \
    return 0;                                                                  \
  }                                                                            \
  return_type name() const { return 0; }                                       \
                                                                               \
  void set_##name(type value) const { UNREACHABLE(); }
#else
#define DEFINE_GETTERS_AND_SETTERS(return_type, type, name)                    \
  static intptr_t name##_offset() {                                            \
    return OFFSET_OF(UntaggedFunction, name##_);                               \
  }                                                                            \
  return_type name() const {                                                   \
    return LoadNonPointer<type, std::memory_order_relaxed>(&untag()->name##_); \
  }                                                                            \
                                                                               \
  void set_##name(type value) const {                                          \
    StoreNonPointer<type, type, std::memory_order_relaxed>(&untag()->name##_,  \
                                                           value);             \
  }
#endif

  JIT_FUNCTION_COUNTERS(DEFINE_GETTERS_AND_SETTERS)

#undef DEFINE_GETTERS_AND_SETTERS

  intptr_t kernel_offset() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return untag()->kernel_offset_;
#endif
  }

  void set_kernel_offset(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    StoreNonPointer(&untag()->kernel_offset_, value);
#endif
  }

  void InheritKernelOffsetFrom(const Function& src) const;
  void InheritKernelOffsetFrom(const Field& src) const;

  static constexpr intptr_t kMaxInstructionCount = (1 << 16) - 1;

  void SetOptimizedInstructionCountClamped(uintptr_t value) const {
    if (value > kMaxInstructionCount) value = kMaxInstructionCount;
    set_optimized_instruction_count(value);
  }

  void SetOptimizedCallSiteCountClamped(uintptr_t value) const {
    if (value > kMaxInstructionCount) value = kMaxInstructionCount;
    set_optimized_call_site_count(value);
  }

  void SetKernelLibraryAndEvalScript(
      const Script& script,
      const class KernelProgramInfo& kernel_program_info,
      intptr_t index) const;

  intptr_t KernelLibraryOffset() const;
  intptr_t KernelLibraryIndex() const;

  TypedDataViewPtr KernelLibrary() const;

  bool IsOptimizable() const;
  void SetIsOptimizable(bool value) const;

  // Whether this function must be optimized immediately and cannot be compiled
  // with the unoptimizing compiler. Such a function must be sure to not
  // deoptimize, since we won't generate deoptimization info or register
  // dependencies. It will be compiled into optimized code immediately when it's
  // run.
  bool ForceOptimize() const;

  // Whether this function is idempotent (i.e. calling it twice has the same
  // effect as calling it once - no visible side effects).
  //
  // If a function is idempotent VM may decide to abort halfway through one call
  // and retry it again.
  bool IsIdempotent() const;

  bool IsCachableIdempotent() const;

  // Whether this function's |recognized_kind| requires optimization.
  bool RecognizedKindForceOptimize() const;

  bool CanBeInlined() const;

  MethodRecognizer::Kind recognized_kind() const {
    return untag()->kind_tag_.Read<RecognizedBits>();
  }
  void set_recognized_kind(MethodRecognizer::Kind value) const;

  bool IsRecognized() const {
    return recognized_kind() != MethodRecognizer::kUnknown;
  }

  bool HasOptimizedCode() const;

  // Returns true if the argument counts are valid for calling this function.
  // Otherwise, it returns false and the reason (if error_message is not
  // nullptr).
  bool AreValidArgumentCounts(intptr_t num_type_arguments,
                              intptr_t num_arguments,
                              intptr_t num_named_arguments,
                              String* error_message) const;

  // Returns a TypeError if the provided arguments don't match the function
  // parameter types, null otherwise. Assumes AreValidArguments is called first.
  //
  // If the function has a non-null receiver in the arguments, the instantiator
  // type arguments are retrieved from the receiver, otherwise the null type
  // arguments vector is used.
  //
  // If the function is generic, the appropriate function type arguments are
  // retrieved either from the arguments array or the receiver (if a closure).
  // If no function type arguments are available in either location, the bounds
  // of the function type parameters are instantiated and used as the function
  // type arguments.
  //
  // The local function type arguments (_not_ parent function type arguments)
  // are also checked against the bounds of the corresponding parameters to
  // ensure they are appropriate subtypes if the function is generic.
  ObjectPtr DoArgumentTypesMatch(const Array& args,
                                 const ArgumentsDescriptor& arg_names) const;

  // Returns a TypeError if the provided arguments don't match the function
  // parameter types, null otherwise. Assumes AreValidArguments is called first.
  //
  // If the function is generic, the appropriate function type arguments are
  // retrieved either from the arguments array or the receiver (if a closure).
  // If no function type arguments are available in either location, the bounds
  // of the function type parameters are instantiated and used as the function
  // type arguments.
  //
  // The local function type arguments (_not_ parent function type arguments)
  // are also checked against the bounds of the corresponding parameters to
  // ensure they are appropriate subtypes if the function is generic.
  ObjectPtr DoArgumentTypesMatch(
      const Array& args,
      const ArgumentsDescriptor& arg_names,
      const TypeArguments& instantiator_type_args) const;

  // Returns a TypeError if the provided arguments don't match the function
  // parameter types, null otherwise. Assumes AreValidArguments is called first.
  //
  // The local function type arguments (_not_ parent function type arguments)
  // are also checked against the bounds of the corresponding parameters to
  // ensure they are appropriate subtypes if the function is generic.
  ObjectPtr DoArgumentTypesMatch(const Array& args,
                                 const ArgumentsDescriptor& arg_names,
                                 const TypeArguments& instantiator_type_args,
                                 const TypeArguments& function_type_args) const;

  // Returns true if the type argument count, total argument count and the names
  // of optional arguments are valid for calling this function.
  // Otherwise, it returns false and the reason (if error_message is not
  // nullptr).
  bool AreValidArguments(intptr_t num_type_arguments,
                         intptr_t num_arguments,
                         const Array& argument_names,
                         String* error_message) const;
  bool AreValidArguments(const ArgumentsDescriptor& args_desc,
                         String* error_message) const;

  // Fully qualified name uniquely identifying the function under gdb and during
  // ast printing. The special ':' character, if present, is replaced by '_'.
  const char* ToFullyQualifiedCString() const;

  const char* ToLibNamePrefixedQualifiedCString() const;

  const char* ToQualifiedCString() const;

  static constexpr intptr_t maximum_unboxed_parameter_count() {
    // Subtracts one that represents the return value
    return UntaggedFunction::UnboxedParameterBitmap::kCapacity - 1;
  }

  void reset_unboxed_parameters_and_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    StoreNonPointer(&untag()->unboxed_parameters_info_,
                    UntaggedFunction::UnboxedParameterBitmap());
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  void set_unboxed_integer_parameter_at(intptr_t index) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(index >= 0 && index < maximum_unboxed_parameter_count());
    index++;  // position 0 is reserved for the return value
    const_cast<UntaggedFunction::UnboxedParameterBitmap*>(
        &untag()->unboxed_parameters_info_)
        ->SetUnboxedInteger(index);
#else
    UNREACHABLE();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  void set_unboxed_double_parameter_at(intptr_t index) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(index >= 0 && index < maximum_unboxed_parameter_count());
    index++;  // position 0 is reserved for the return value
    const_cast<UntaggedFunction::UnboxedParameterBitmap*>(
        &untag()->unboxed_parameters_info_)
        ->SetUnboxedDouble(index);

#else
    UNREACHABLE();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  void set_unboxed_integer_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    const_cast<UntaggedFunction::UnboxedParameterBitmap*>(
        &untag()->unboxed_parameters_info_)
        ->SetUnboxedInteger(0);
#else
    UNREACHABLE();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  void set_unboxed_double_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    const_cast<UntaggedFunction::UnboxedParameterBitmap*>(
        &untag()->unboxed_parameters_info_)
        ->SetUnboxedDouble(0);

#else
    UNREACHABLE();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  void set_unboxed_record_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    const_cast<UntaggedFunction::UnboxedParameterBitmap*>(
        &untag()->unboxed_parameters_info_)
        ->SetUnboxedRecord(0);

#else
    UNREACHABLE();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool is_unboxed_parameter_at(intptr_t index) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(index >= 0);
    index++;  // position 0 is reserved for the return value
    return untag()->unboxed_parameters_info_.IsUnboxed(index);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool is_unboxed_integer_parameter_at(intptr_t index) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(index >= 0);
    index++;  // position 0 is reserved for the return value
    return untag()->unboxed_parameters_info_.IsUnboxedInteger(index);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool is_unboxed_double_parameter_at(intptr_t index) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(index >= 0);
    index++;  // position 0 is reserved for the return value
    return untag()->unboxed_parameters_info_.IsUnboxedDouble(index);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool has_unboxed_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return untag()->unboxed_parameters_info_.IsUnboxed(0);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool has_unboxed_integer_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return untag()->unboxed_parameters_info_.IsUnboxedInteger(0);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool has_unboxed_double_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return untag()->unboxed_parameters_info_.IsUnboxedDouble(0);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool has_unboxed_record_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return untag()->unboxed_parameters_info_.IsUnboxedRecord(0);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  bool HasUnboxedParameters() const {
    return untag()->unboxed_parameters_info_.HasUnboxedParameters();
  }
  bool HasUnboxedReturnValue() const { return has_unboxed_return(); }
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)

  bool IsDispatcherOrImplicitAccessor() const {
    switch (kind()) {
      case UntaggedFunction::kImplicitGetter:
      case UntaggedFunction::kImplicitSetter:
      case UntaggedFunction::kImplicitStaticGetter:
      case UntaggedFunction::kNoSuchMethodDispatcher:
      case UntaggedFunction::kInvokeFieldDispatcher:
      case UntaggedFunction::kDynamicInvocationForwarder:
        return true;
      default:
        return false;
    }
  }

  // Returns true if this function represents an explicit getter function.
  bool IsGetterFunction() const {
    return kind() == UntaggedFunction::kGetterFunction;
  }

  // Returns true if this function represents an implicit getter function.
  bool IsImplicitGetterFunction() const {
    return kind() == UntaggedFunction::kImplicitGetter;
  }

  // Returns true if this function represents an implicit static getter
  // function.
  bool IsImplicitStaticGetterFunction() const {
    return kind() == UntaggedFunction::kImplicitStaticGetter;
  }

  // Returns true if this function represents an explicit setter function.
  bool IsSetterFunction() const {
    return kind() == UntaggedFunction::kSetterFunction;
  }

  // Returns true if this function represents an implicit setter function.
  bool IsImplicitSetterFunction() const {
    return kind() == UntaggedFunction::kImplicitSetter;
  }

  // Returns true if this function represents an initializer for a static or
  // instance field. The function returns the initial value and the caller is
  // responsible for setting the field.
  bool IsFieldInitializer() const {
    return kind() == UntaggedFunction::kFieldInitializer;
  }

  // Returns true if this function represents a (possibly implicit) closure
  // function.
  bool IsClosureFunction() const {
    UntaggedFunction::Kind k = kind();
    return (k == UntaggedFunction::kClosureFunction) ||
           (k == UntaggedFunction::kImplicitClosureFunction);
  }

  // Returns true if this function represents a generated irregexp function.
  bool IsIrregexpFunction() const {
    return kind() == UntaggedFunction::kIrregexpFunction;
  }

  // Returns true if this function represents an implicit closure function.
  bool IsImplicitClosureFunction() const {
    return kind() == UntaggedFunction::kImplicitClosureFunction;
  }

  // Returns true if this function represents a non implicit closure function.
  bool IsNonImplicitClosureFunction() const {
    return IsClosureFunction() && !IsImplicitClosureFunction();
  }

  // Returns true if this function represents an implicit static closure
  // function.
  bool IsImplicitStaticClosureFunction() const {
    return IsImplicitClosureFunction() && is_static();
  }
  static bool IsImplicitStaticClosureFunction(FunctionPtr func);

  // Returns true if this function represents an implicit instance closure
  // function.
  bool IsImplicitInstanceClosureFunction() const {
    return IsImplicitClosureFunction() && !is_static();
  }

  // Returns true if this function has a parent function.
  bool HasParent() const { return parent_function() != Function::null(); }

  // Returns true if this function is a local function.
  bool IsLocalFunction() const {
    return !IsImplicitClosureFunction() && HasParent();
  }

  // Returns true if this function represents an ffi trampoline.
  bool IsFfiTrampoline() const {
    return kind() == UntaggedFunction::kFfiTrampoline;
  }
  static bool IsFfiTrampoline(FunctionPtr function) {
    NoSafepointScope no_safepoint;
    return function->untag()->kind_tag_.Read<KindBits>() ==
           UntaggedFunction::kFfiTrampoline;
  }

  // Returns true for functions which execution can be suspended
  // using Suspend/Resume stubs. Such functions have an artificial
  // :suspend_state local variable at the fixed location of the frame.
  bool IsSuspendableFunction() const {
    return modifier() != UntaggedFunction::kNoModifier;
  }

  // Returns true if this function is marked with 'async' modifier.
  bool IsAsyncFunction() const {
    return modifier() == UntaggedFunction::kAsync;
  }

  // Returns true if this function is marked with 'sync*' modifier.
  bool IsSyncGenerator() const {
    return modifier() == UntaggedFunction::kSyncGen;
  }

  // Returns true if this function is marked with 'async*' modifier.
  bool IsAsyncGenerator() const {
    return modifier() == UntaggedFunction::kAsyncGen;
  }

  bool IsTypedDataViewFactory() const;
  bool IsUnmodifiableTypedDataViewFactory() const;

  DART_WARN_UNUSED_RESULT
  ErrorPtr VerifyCallEntryPoint() const;

  DART_WARN_UNUSED_RESULT
  ErrorPtr VerifyClosurizedEntryPoint() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedFunction));
  }

  static FunctionPtr New(const FunctionType& signature,
                         const String& name,
                         UntaggedFunction::Kind kind,
                         bool is_static,
                         bool is_const,
                         bool is_abstract,
                         bool is_external,
                         bool is_native,
                         const Object& owner,
                         TokenPosition token_pos,
                         Heap::Space space = Heap::kOld);

  // Allocates a new Function object representing a closure function
  // with given kind - kClosureFunction or kImplicitClosureFunction.
  static FunctionPtr NewClosureFunctionWithKind(UntaggedFunction::Kind kind,
                                                const String& name,
                                                const Function& parent,
                                                bool is_static,
                                                TokenPosition token_pos,
                                                const Object& owner);

  // Allocates a new Function object representing a closure function.
  static FunctionPtr NewClosureFunction(const String& name,
                                        const Function& parent,
                                        TokenPosition token_pos);

  // Allocates a new Function object representing an implicit closure function.
  static FunctionPtr NewImplicitClosureFunction(const String& name,
                                                const Function& parent,
                                                TokenPosition token_pos);

  FunctionPtr CreateMethodExtractor(const String& getter_name) const;
  FunctionPtr GetMethodExtractor(const String& getter_name) const;

  static bool IsDynamicInvocationForwarderName(const String& name);
  static bool IsDynamicInvocationForwarderName(StringPtr name);

  static StringPtr DemangleDynamicInvocationForwarderName(const String& name);

  static StringPtr CreateDynamicInvocationForwarderName(const String& name);

#if !defined(DART_PRECOMPILED_RUNTIME)
  FunctionPtr CreateDynamicInvocationForwarder(
      const String& mangled_name) const;

  FunctionPtr GetDynamicInvocationForwarder(const String& mangled_name,
                                            bool allow_add = true) const;
#endif

  // Slow function, use in asserts to track changes in important library
  // functions.
  int32_t SourceFingerprint() const;

  // Return false and report an error if the fingerprint does not match.
  bool CheckSourceFingerprint(int32_t fp, const char* kind = nullptr) const;

  // Works with map [deopt-id] -> ICData.
  void SaveICDataMap(
      const ZoneGrowableArray<const ICData*>& deopt_id_to_ic_data,
      const Array& edge_counters_array,
      const Array& coverage_array) const;
  // Uses 'ic_data_array' to populate the table 'deopt_id_to_ic_data'. Clone
  // ic_data (array and descriptor) if 'clone_ic_data' is true.
  void RestoreICDataMap(ZoneGrowableArray<const ICData*>* deopt_id_to_ic_data,
                        bool clone_ic_data) const;

  // ic_data_array attached to the function stores edge counters in the
  // first element, coverage data array in the second element and the rest
  // are ICData objects.
  struct ICDataArrayIndices {
    static constexpr intptr_t kEdgeCounters = 0;
    static constexpr intptr_t kCoverageData = 1;
    static constexpr intptr_t kFirstICData = 2;
  };

  ArrayPtr ic_data_array() const;
  void ClearICDataArray() const;
  ICDataPtr FindICData(intptr_t deopt_id) const;

  // Coverage data array is a list of pairs:
  //   element 2 * i + 0 is token position
  //   element 2 * i + 1 is coverage hit (zero meaning code was not hit)
  ArrayPtr GetCoverageArray() const;

  // Outputs this function's service ID to the provided JSON object.
  void AddFunctionServiceId(const JSONObject& obj) const;

  // Sets deopt reason in all ICData-s with given deopt_id.
  void SetDeoptReasonForAll(intptr_t deopt_id, ICData::DeoptReasonId reason);

  void set_modifier(UntaggedFunction::AsyncModifier value) const;

// 'WasCompiled' is true if the function was compiled once in this
// VM instantiation. It is independent from presence of type feedback
// (ic_data_array) and code, which may be loaded from a snapshot.
// 'WasExecuted' is true if the usage counter has ever been positive.
// 'ProhibitsInstructionHoisting' is true if this function deoptimized before on
// a hoisted instruction.
// 'ProhibitsBoundsCheckGeneralization' is true if this function deoptimized
// before on a generalized bounds check.
#define STATE_BITS_LIST(V)                                                     \
  V(WasCompiled)                                                               \
  V(WasExecutedBit)                                                            \
  V(ProhibitsInstructionHoisting)                                              \
  V(ProhibitsBoundsCheckGeneralization)

  enum StateBits {
#define DECLARE_FLAG_POS(Name) k##Name##Pos,
    STATE_BITS_LIST(DECLARE_FLAG_POS)
#undef DECLARE_FLAG_POS
  };
#define DEFINE_FLAG_BIT(Name)                                                  \
  class Name##Bit : public BitField<uint8_t, bool, k##Name##Pos, 1> {};
  STATE_BITS_LIST(DEFINE_FLAG_BIT)
#undef DEFINE_FLAG_BIT

#define DEFINE_FLAG_ACCESSORS(Name)                                            \
  void Set##Name(bool value) const {                                           \
    set_state_bits(Name##Bit::update(value, state_bits()));                    \
  }                                                                            \
  bool Name() const { return Name##Bit::decode(state_bits()); }
  STATE_BITS_LIST(DEFINE_FLAG_ACCESSORS)
#undef DEFINE_FLAG_ACCESSORS

  void SetUsageCounter(intptr_t value) const {
    if (usage_counter() > 0) {
      SetWasExecuted(true);
    }
    set_usage_counter(value);
  }

  bool WasExecuted() const { return (usage_counter() > 0) || WasExecutedBit(); }

  void SetWasExecuted(bool value) const { SetWasExecutedBit(value); }

  static intptr_t data_offset() { return OFFSET_OF(UntaggedFunction, data_); }

  static intptr_t kind_tag_offset() {
    return OFFSET_OF(UntaggedFunction, kind_tag_);
  }

  // static: Considered during class-side or top-level resolution rather than
  //         instance-side resolution.
  // const: Valid target of a const constructor call.
  // abstract: Skipped during instance-side resolution.
  // reflectable: Enumerated by mirrors, invocable by mirrors. False for private
  //              functions of dart: libraries.
  // debuggable: Valid location of a breakpoint. Synthetic code is not
  //             debuggable.
  // visible: Frame is included in stack traces. Synthetic code such as
  //          dispatchers is not visible. Synthetic code that can trigger
  //          exceptions such as the outer async functions that create Futures
  //          is visible.
  // intrinsic: Has a hand-written assembly prologue.
  // inlinable: Candidate for inlining. False for functions with features we
  //            don't support during inlining (e.g., optional parameters),
  //            functions which are too big, etc.
  // native: Bridge to C/C++ code.
  // external: Just a declaration that expects to be defined in another patch
  //           file.
  // polymorphic_target: A polymorphic method.
  // has_pragma: Has a @pragma decoration.
  // no_such_method_forwarder: A stub method that just calls noSuchMethod.

// Bits that are set when function is created, don't have to worry about
// concurrent updates.
#define FOR_EACH_FUNCTION_KIND_BIT(V)                                          \
  V(Static, is_static)                                                         \
  V(Const, is_const)                                                           \
  V(Abstract, is_abstract)                                                     \
  V(Reflectable, is_reflectable)                                               \
  V(Visible, is_visible)                                                       \
  V(Debuggable, is_debuggable)                                                 \
  V(Intrinsic, is_intrinsic)                                                   \
  V(Native, is_native)                                                         \
  V(External, is_external)                                                     \
  V(PolymorphicTarget, is_polymorphic_target)                                  \
  V(HasPragma, has_pragma)                                                     \
  V(IsSynthetic, is_synthetic)                                                 \
  V(IsExtensionMember, is_extension_member)                                    \
  V(IsRedirectingFactory, is_redirecting_factory)
// Bit that is updated after function is constructed, has to be updated in
// concurrent-safe manner.
#define FOR_EACH_FUNCTION_VOLATILE_KIND_BIT(V) V(Inlinable, is_inlinable)

#define DEFINE_ACCESSORS(name, accessor_name)                                  \
  void set_##accessor_name(bool value) const {                                 \
    untag()->kind_tag_.UpdateUnsynchronized<name##Bit>(value);                 \
  }                                                                            \
  bool accessor_name() const { return untag()->kind_tag_.Read<name##Bit>(); }
  FOR_EACH_FUNCTION_KIND_BIT(DEFINE_ACCESSORS)
#undef DEFINE_ACCESSORS

  static bool is_visible(FunctionPtr f) {
    return f.untag()->kind_tag_.Read<VisibleBit>();
  }

#define DEFINE_ACCESSORS(name, accessor_name)                                  \
  void set_##accessor_name(bool value) const {                                 \
    untag()->kind_tag_.UpdateBool<name##Bit>(value);                           \
  }                                                                            \
  bool accessor_name() const { return untag()->kind_tag_.Read<name##Bit>(); }
  FOR_EACH_FUNCTION_VOLATILE_KIND_BIT(DEFINE_ACCESSORS)
#undef DEFINE_ACCESSORS

  // optimizable: Candidate for going through the optimizing compiler. False for
  //              some functions known to be execute infrequently and functions
  //              which have been de-optimized too many times.
  bool is_optimizable() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return false;
#else
    return untag()->packed_fields_.Read<UntaggedFunction::PackedOptimizable>();
#endif
  }
  void set_is_optimizable(bool value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    untag()->packed_fields_.UpdateBool<UntaggedFunction::PackedOptimizable>(
        value);
#endif
  }

  enum KindTagBits {
    kKindTagPos = 0,
    kKindTagSize = 5,
    kRecognizedTagPos = kKindTagPos + kKindTagSize,
    kRecognizedTagSize = 9,
    kModifierPos = kRecognizedTagPos + kRecognizedTagSize,
    kModifierSize = 2,
    kLastModifierBitPos = kModifierPos + (kModifierSize - 1),
// Single bit sized fields start here.
#define DECLARE_BIT(name, _) k##name##Bit,
    FOR_EACH_FUNCTION_KIND_BIT(DECLARE_BIT)
        FOR_EACH_FUNCTION_VOLATILE_KIND_BIT(DECLARE_BIT)
#undef DECLARE_BIT
            kNumTagBits
  };

  COMPILE_ASSERT(MethodRecognizer::kNumRecognizedMethods <
                 (1 << kRecognizedTagSize));
  COMPILE_ASSERT(kNumTagBits <=
                 (kBitsPerByte *
                  sizeof(decltype(UntaggedFunction::kind_tag_))));

#define ASSERT_FUNCTION_KIND_IN_RANGE(Name)                                    \
  COMPILE_ASSERT(UntaggedFunction::k##Name < (1 << kKindTagSize));
  FOR_EACH_RAW_FUNCTION_KIND(ASSERT_FUNCTION_KIND_IN_RANGE)
#undef ASSERT_FUNCTION_KIND_IN_RANGE

  class KindBits : public BitField<uint32_t,
                                   UntaggedFunction::Kind,
                                   kKindTagPos,
                                   kKindTagSize> {};

  class RecognizedBits : public BitField<uint32_t,
                                         MethodRecognizer::Kind,
                                         kRecognizedTagPos,
                                         kRecognizedTagSize> {};
  class ModifierBits : public BitField<uint32_t,
                                       UntaggedFunction::AsyncModifier,
                                       kModifierPos,
                                       kModifierSize> {};

#define DEFINE_BIT(name, _)                                                    \
  class name##Bit : public BitField<uint32_t, bool, k##name##Bit, 1> {};
  FOR_EACH_FUNCTION_KIND_BIT(DEFINE_BIT)
  FOR_EACH_FUNCTION_VOLATILE_KIND_BIT(DEFINE_BIT)
#undef DEFINE_BIT

 private:
  enum class EvalFunctionData {
    kScript,
    kKernelProgramInfo,
    kKernelLibraryIndex,
    kLength,
  };
  enum NativeFunctionData {
    kNativeName,
    kTearOff,
    kLength,
  };
  // Given the provided defaults type arguments, determines which
  // DefaultTypeArgumentsKind applies.
  DefaultTypeArgumentsKind DefaultTypeArgumentsKindFor(
      const TypeArguments& defaults) const;

  void set_ic_data_array(const Array& value) const;
  void set_name(const String& value) const;
  void set_kind(UntaggedFunction::Kind value) const;
  void set_parent_function(const Function& value) const;
  FunctionPtr implicit_closure_function() const;
  void set_implicit_closure_function(const Function& value) const;
  ClosurePtr implicit_static_closure() const;
  void set_implicit_static_closure(const Closure& closure) const;
  ScriptPtr eval_script() const;
  void set_eval_script(const Script& value) const;
  void set_num_optional_parameters(intptr_t value) const;  // Encoded value.
  void set_kind_tag(uint32_t value) const;
  bool is_eval_function() const;

#if !defined(DART_PRECOMPILED_RUNTIME)
  ArrayPtr positional_parameter_names() const {
    return untag()->positional_parameter_names();
  }
  void set_positional_parameter_names(const Array& value) const;
#endif

  ObjectPtr data() const { return untag()->data<std::memory_order_acquire>(); }
  void set_data(const Object& value) const;

  static FunctionPtr New(Heap::Space space = Heap::kOld);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Function, Object);
  friend class Class;
  friend class Parser;  // For set_eval_script.
  // UntaggedFunction::VisitFunctionPointers accesses the private constructor of
  // Function.
  friend class UntaggedFunction;
  friend class ClassFinalizer;  // To reset parent_function.
  friend class Type;            // To adjust parent_function.
  friend class Precompiler;     // To access closure data.
  friend class ProgramVisitor;  // For set_parameter_types/names.
};

class ClosureData : public Object {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedClosureData));
  }

  static intptr_t packed_fields_offset() {
    return OFFSET_OF(UntaggedClosureData, packed_fields_);
  }

  using DefaultTypeArgumentsKind =
      UntaggedClosureData::DefaultTypeArgumentsKind;
  using PackedDefaultTypeArgumentsKind =
      UntaggedClosureData::PackedDefaultTypeArgumentsKind;

  static constexpr uint8_t kNoAwaiterLinkDepth =
      UntaggedClosureData::kNoAwaiterLinkDepth;

 private:
  ContextScopePtr context_scope() const { return untag()->context_scope(); }
  void set_context_scope(const ContextScope& value) const;

  void set_packed_fields(uint32_t value) const {
    untag()->packed_fields_ = value;
  }

  Function::AwaiterLink awaiter_link() const;
  void set_awaiter_link(Function::AwaiterLink link) const;

  // Enclosing function of this local function.
  PRECOMPILER_WSR_FIELD_DECLARATION(Function, parent_function)

  ClosurePtr implicit_static_closure() const {
    return untag()->closure<std::memory_order_acquire>();
  }
  void set_implicit_static_closure(const Closure& closure) const;

  DefaultTypeArgumentsKind default_type_arguments_kind() const;
  void set_default_type_arguments_kind(DefaultTypeArgumentsKind value) const;

  static ClosureDataPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ClosureData, Object);
  friend class Class;
  friend class Function;
  friend class Precompiler;  // To wrap parent functions in WSRs.
};

enum class EntryPointPragma {
  kAlways,
  kNever,
  kGetterOnly,
  kSetterOnly,
  kCallOnly
};

class FfiTrampolineData : public Object {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedFfiTrampolineData));
  }

 private:
  FunctionTypePtr c_signature() const { return untag()->c_signature(); }
  void set_c_signature(const FunctionType& value) const;

  FunctionPtr callback_target() const { return untag()->callback_target(); }
  void set_callback_target(const Function& value) const;

  InstancePtr callback_exceptional_return() const {
    return untag()->callback_exceptional_return();
  }
  void set_callback_exceptional_return(const Instance& value) const;

  FfiFunctionKind ffi_function_kind() const {
    return static_cast<FfiFunctionKind>(untag()->ffi_function_kind_);
  }
  void set_ffi_function_kind(FfiFunctionKind kind) const;

  int32_t callback_id() const { return untag()->callback_id_; }
  void set_callback_id(int32_t value) const;

  bool is_leaf() const { return untag()->is_leaf_; }
  void set_is_leaf(bool value) const;

  static FfiTrampolineDataPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(FfiTrampolineData, Object);
  friend class Class;
  friend class Function;
};

class Field : public Object {
 public:
  // The field that this field was cloned from, or this field itself if it isn't
  // a clone. The purpose of cloning is that the fields the background compiler
  // sees are consistent.
  FieldPtr Original() const;

  // Set the original field that this field was cloned from.
  void SetOriginal(const Field& value) const;

  // Returns whether this field is an original or a clone.
  bool IsOriginal() const {
    if (IsNull()) {
      return true;
    }
    NoSafepointScope no_safepoint;
    return !untag()->owner()->IsField();
  }

  // Returns a field cloned from 'this'. 'this' is set as the
  // original field of result.
  FieldPtr CloneFromOriginal() const;

  StringPtr name() const { return untag()->name(); }
  StringPtr UserVisibleName() const;  // Same as scrubbed name.
  const char* UserVisibleNameCString() const;
  virtual StringPtr DictionaryName() const { return name(); }

  uint16_t kind_bits() const {
    return LoadNonPointer<uint16_t, std::memory_order_acquire>(
        &untag()->kind_bits_);
  }

  bool is_static() const { return StaticBit::decode(kind_bits()); }
  bool is_instance() const { return !is_static(); }
  bool is_final() const { return FinalBit::decode(kind_bits()); }
  bool is_const() const { return ConstBit::decode(kind_bits()); }
  bool is_late() const { return IsLateBit::decode(kind_bits()); }
  bool is_extension_member() const {
    return IsExtensionMemberBit::decode(kind_bits());
  }
  bool needs_load_guard() const {
    return NeedsLoadGuardBit::decode(kind_bits());
  }
  bool is_reflectable() const { return ReflectableBit::decode(kind_bits()); }
  void set_is_reflectable(bool value) const {
    ASSERT(IsOriginal());
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(ReflectableBit::update(value, untag()->kind_bits_));
  }

  bool initializer_changed_after_initialization() const {
    return InitializerChangedAfterInitializationBit::decode(kind_bits());
  }
  void set_initializer_changed_after_initialization(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(InitializerChangedAfterInitializationBit::update(
        value, untag()->kind_bits_));
  }

  bool has_pragma() const { return HasPragmaBit::decode(kind_bits()); }
  void set_has_pragma(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(HasPragmaBit::update(value, untag()->kind_bits_));
  }

  bool is_covariant() const { return CovariantBit::decode(kind_bits()); }
  void set_is_covariant(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(CovariantBit::update(value, untag()->kind_bits_));
  }

  bool is_generic_covariant_impl() const {
    return GenericCovariantImplBit::decode(kind_bits());
  }
  void set_is_generic_covariant_impl(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(GenericCovariantImplBit::update(value, untag()->kind_bits_));
  }

  intptr_t kernel_offset() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return untag()->kernel_offset_;
#endif
  }

  void set_kernel_offset(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    StoreNonPointer(&untag()->kernel_offset_, value);
#endif
  }

  void InheritKernelOffsetFrom(const Field& src) const;

  TypedDataViewPtr KernelLibrary() const;
  intptr_t KernelLibraryOffset() const;
  intptr_t KernelLibraryIndex() const;

  // Called during class finalization.
  inline void SetOffset(intptr_t host_offset_in_bytes,
                        intptr_t target_offset_in_bytes) const;

  inline intptr_t HostOffset() const;
  static intptr_t host_offset_or_field_id_offset() {
    return OFFSET_OF(UntaggedField, host_offset_or_field_id_);
  }

  inline intptr_t TargetOffset() const;
  static inline intptr_t TargetOffsetOf(FieldPtr field);

  ObjectPtr StaticConstFieldValue() const;
  void SetStaticConstFieldValue(const Instance& value,
                                bool assert_initializing_store = true) const;

  inline ObjectPtr StaticValue() const;
  void SetStaticValue(const Object& value) const;

  inline intptr_t field_id() const;
  inline void set_field_id(intptr_t field_id) const;
  inline void set_field_id_unsafe(intptr_t field_id) const;

  ClassPtr Owner() const;
  ScriptPtr Script() const;
#if !defined(DART_PRECOMPILED_RUNTIME)
  KernelProgramInfoPtr KernelProgramInfo() const;
#endif
  ObjectPtr RawOwner() const;

  uint32_t Hash() const;

  AbstractTypePtr type() const { return untag()->type(); }
  // Used by class finalizer, otherwise initialized in constructor.
  void SetFieldType(const AbstractType& value) const;
  void SetFieldTypeSafe(const AbstractType& value) const;

  DART_WARN_UNUSED_RESULT
  ErrorPtr VerifyEntryPoint(EntryPointPragma kind) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedField));
  }

  static FieldPtr New(const String& name,
                      bool is_static,
                      bool is_final,
                      bool is_const,
                      bool is_reflectable,
                      bool is_late,
                      const Object& owner,
                      const AbstractType& type,
                      TokenPosition token_pos,
                      TokenPosition end_token_pos);

  static FieldPtr NewTopLevel(const String& name,
                              bool is_final,
                              bool is_const,
                              bool is_late,
                              const Object& owner,
                              TokenPosition token_pos,
                              TokenPosition end_token_pos);

  // Allocate new field object, clone values from this field. The
  // original is specified.
  FieldPtr Clone(const Field& original) const;

  static intptr_t kind_bits_offset() {
    return OFFSET_OF(UntaggedField, kind_bits_);
  }

  TokenPosition token_pos() const { return untag()->token_pos_; }
  TokenPosition end_token_pos() const { return untag()->end_token_pos_; }

  int32_t SourceFingerprint() const;

  StringPtr InitializingExpression() const;

  bool has_nontrivial_initializer() const {
    return HasNontrivialInitializerBit::decode(kind_bits());
  }
  // Called by parser after allocating field.
  void set_has_nontrivial_initializer_unsafe(
      bool has_nontrivial_initializer) const {
    ASSERT(IsOriginal());
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(HasNontrivialInitializerBit::update(
        has_nontrivial_initializer, untag()->kind_bits_));
  }
  void set_has_nontrivial_initializer(bool has_nontrivial_initializer) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_has_nontrivial_initializer_unsafe(has_nontrivial_initializer);
  }

  bool has_initializer() const {
    return HasInitializerBit::decode(kind_bits());
  }
  // Called by parser after allocating field.
  void set_has_initializer_unsafe(bool has_initializer) const {
    ASSERT(IsOriginal());
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(
        HasInitializerBit::update(has_initializer, untag()->kind_bits_));
  }
  void set_has_initializer(bool has_initializer) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_has_initializer_unsafe(has_initializer);
  }

  bool has_trivial_initializer() const {
    return has_initializer() && !has_nontrivial_initializer();
  }

  StaticTypeExactnessState static_type_exactness_state() const {
    return StaticTypeExactnessState::Decode(
        LoadNonPointer<int8_t, std::memory_order_relaxed>(
            &untag()->static_type_exactness_state_));
  }

  void set_static_type_exactness_state(StaticTypeExactnessState state) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_static_type_exactness_state_unsafe(state);
  }

  void set_static_type_exactness_state_unsafe(
      StaticTypeExactnessState state) const {
    StoreNonPointer<int8_t, int8_t, std::memory_order_relaxed>(
        &untag()->static_type_exactness_state_, state.Encode());
  }

  static intptr_t static_type_exactness_state_offset() {
    return OFFSET_OF(UntaggedField, static_type_exactness_state_);
  }

  // Return class id that any non-null value read from this field is guaranteed
  // to have or kDynamicCid if such class id is not known.
  // Stores to this field must update this information hence the name.
  intptr_t guarded_cid() const;

  void set_guarded_cid(intptr_t cid) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_guarded_cid_unsafe(cid);
  }
  void set_guarded_cid_unsafe(intptr_t cid) const {
    StoreNonPointer<ClassIdTagType, ClassIdTagType, std::memory_order_relaxed>(
        &untag()->guarded_cid_, cid);
  }
  static intptr_t guarded_cid_offset() {
    return OFFSET_OF(UntaggedField, guarded_cid_);
  }
  // Return the list length that any list stored in this field is guaranteed
  // to have. If length is kUnknownFixedLength the length has not
  // been determined. If length is kNoFixedLength this field has multiple
  // list lengths associated with it and cannot be predicted.
  intptr_t guarded_list_length() const;
  void set_guarded_list_length_unsafe(intptr_t list_length) const;
  void set_guarded_list_length(intptr_t list_length) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_guarded_list_length_unsafe(list_length);
  }
  static intptr_t guarded_list_length_offset() {
    return OFFSET_OF(UntaggedField, guarded_list_length_);
  }
  intptr_t guarded_list_length_in_object_offset() const;
  void set_guarded_list_length_in_object_offset_unsafe(intptr_t offset) const;
  void set_guarded_list_length_in_object_offset(intptr_t offset) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_guarded_list_length_in_object_offset_unsafe(offset);
  }
  static intptr_t guarded_list_length_in_object_offset_offset() {
    return OFFSET_OF(UntaggedField, guarded_list_length_in_object_offset_);
  }

  bool needs_length_check() const {
    const bool r = guarded_list_length() >= Field::kUnknownFixedLength;
    ASSERT(!r || is_final());
    return r;
  }

  bool NeedsSetter() const;
  bool NeedsGetter() const;

  bool NeedsInitializationCheckOnLoad() const {
    return needs_load_guard() || (is_late() && !has_trivial_initializer());
  }

  const char* GuardedPropertiesAsCString() const;

  bool is_unboxed() const {
    return UnboxedBit::decode(kind_bits());
  }

  // Field unboxing decisions are based either on static types (JIT) or
  // inferred types (AOT). See the callers of this function.
  void set_is_unboxed_unsafe(bool b) const {
    set_kind_bits(UnboxedBit::update(b, untag()->kind_bits_));
  }

  void set_is_unboxed(bool b) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_is_unboxed_unsafe(b);
  }

  enum {
    kUnknownLengthOffset = -1,
    kUnknownFixedLength = -1,
    kNoFixedLength = -2,
  };
  void set_is_late(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(IsLateBit::update(value, untag()->kind_bits_));
  }
  void set_is_extension_member(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(IsExtensionMemberBit::update(value, untag()->kind_bits_));
  }
  void set_needs_load_guard(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(NeedsLoadGuardBit::update(value, untag()->kind_bits_));
  }
  // Returns false if any value read from this field is guaranteed to be
  // not null.
  // Internally we is_nullable_ field contains either kNullCid (nullable) or
  // kIllegalCid (non-nullable) instead of boolean. This is done to simplify
  // guarding sequence in the generated code.
  bool is_nullable() const;
  void set_is_nullable(bool val) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_is_nullable_unsafe(val);
  }
  bool is_nullable_unsafe() const {
    return LoadNonPointer<ClassIdTagType, std::memory_order_relaxed>(
               &untag()->is_nullable_) == kNullCid;
  }
  void set_is_nullable_unsafe(bool val) const {
    StoreNonPointer<ClassIdTagType, ClassIdTagType, std::memory_order_relaxed>(
        &untag()->is_nullable_, val ? kNullCid : kIllegalCid);
  }
  static intptr_t is_nullable_offset() {
    return OFFSET_OF(UntaggedField, is_nullable_);
  }

  // Record store of the given value into this field. May trigger
  // deoptimization of dependent optimized code.
  void RecordStore(const Object& value) const;

  void InitializeGuardedListLengthInObjectOffset(bool unsafe = false) const;

  // Return the list of optimized code objects that were optimized under
  // assumptions about guarded class id and nullability of this field.
  // These code objects must be deoptimized when field's properties change.
  // Code objects are held weakly via an indirection through WeakProperty.
  WeakArrayPtr dependent_code() const;
  void set_dependent_code(const WeakArray& array) const;

  // Add the given code object to the list of dependent ones.
  void RegisterDependentCode(const Code& code) const;

  // Deoptimize all dependent code objects.
  void DeoptimizeDependentCode(bool are_mutators_stopped = false) const;

  // Used by background compiler to check consistency of field copy with its
  // original.
  bool IsConsistentWith(const Field& field) const;

  bool IsUninitialized() const;

  // Run initializer and set field value.
  DART_WARN_UNUSED_RESULT ErrorPtr
  InitializeInstance(const Instance& instance) const;
  DART_WARN_UNUSED_RESULT ErrorPtr InitializeStatic() const;

  // Run initializer only.
  DART_WARN_UNUSED_RESULT ObjectPtr EvaluateInitializer() const;

  FunctionPtr EnsureInitializerFunction() const;
  FunctionPtr InitializerFunction() const {
    return untag()->initializer_function<std::memory_order_acquire>();
  }
  void SetInitializerFunction(const Function& initializer) const;
  bool HasInitializerFunction() const;
  static intptr_t initializer_function_offset() {
    return OFFSET_OF(UntaggedField, initializer_function_);
  }

  // For static fields only. Constructs a closure that gets/sets the
  // field value.
  InstancePtr GetterClosure() const;
  InstancePtr SetterClosure() const;
  InstancePtr AccessorClosure(bool make_setter) const;

  // Constructs getter and setter names for fields and vice versa.
  static StringPtr GetterName(const String& field_name);
  static StringPtr GetterSymbol(const String& field_name);
  // Returns String::null() if getter symbol does not exist.
  static StringPtr LookupGetterSymbol(const String& field_name);
  static StringPtr SetterName(const String& field_name);
  static StringPtr SetterSymbol(const String& field_name);
  // Returns String::null() if setter symbol does not exist.
  static StringPtr LookupSetterSymbol(const String& field_name);
  static StringPtr NameFromGetter(const String& getter_name);
  static StringPtr NameFromSetter(const String& setter_name);
  static StringPtr NameFromInit(const String& init_name);
  static bool IsGetterName(const String& function_name);
  static bool IsSetterName(const String& function_name);
  static bool IsInitName(const String& function_name);

 private:
  static void InitializeNew(const Field& result,
                            const String& name,
                            bool is_static,
                            bool is_final,
                            bool is_const,
                            bool is_reflectable,
                            bool is_late,
                            const Object& owner,
                            TokenPosition token_pos,
                            TokenPosition end_token_pos);
  friend class StoreFieldInstr;  // Generated code access to bit field.

  enum {
    kConstBit = 0,
    kStaticBit,
    kFinalBit,
    kHasNontrivialInitializerBit,
    kUnboxedBit,
    kReflectableBit,
    kInitializerChangedAfterInitializationBit,
    kHasPragmaBit,
    kCovariantBit,
    kGenericCovariantImplBit,
    kIsLateBit,
    kIsExtensionMemberBit,
    kNeedsLoadGuardBit,
    kHasInitializerBit,
  };
  class ConstBit : public BitField<uint16_t, bool, kConstBit, 1> {};
  class StaticBit : public BitField<uint16_t, bool, kStaticBit, 1> {};
  class FinalBit : public BitField<uint16_t, bool, kFinalBit, 1> {};
  class HasNontrivialInitializerBit
      : public BitField<uint16_t, bool, kHasNontrivialInitializerBit, 1> {};
  class UnboxedBit : public BitField<uint16_t, bool, kUnboxedBit, 1> {};
  class ReflectableBit : public BitField<uint16_t, bool, kReflectableBit, 1> {};
  class InitializerChangedAfterInitializationBit
      : public BitField<uint16_t,
                        bool,
                        kInitializerChangedAfterInitializationBit,
                        1> {};
  class HasPragmaBit : public BitField<uint16_t, bool, kHasPragmaBit, 1> {};
  class CovariantBit : public BitField<uint16_t, bool, kCovariantBit, 1> {};
  class GenericCovariantImplBit
      : public BitField<uint16_t, bool, kGenericCovariantImplBit, 1> {};
  class IsLateBit : public BitField<uint16_t, bool, kIsLateBit, 1> {};
  class IsExtensionMemberBit
      : public BitField<uint16_t, bool, kIsExtensionMemberBit, 1> {};
  class NeedsLoadGuardBit
      : public BitField<uint16_t, bool, kNeedsLoadGuardBit, 1> {};
  class HasInitializerBit
      : public BitField<uint16_t, bool, kHasInitializerBit, 1> {};

  // Force this field's guard to be dynamic and deoptimize dependent code.
  void ForceDynamicGuardedCidAndLength() const;

  void set_name(const String& value) const;
  void set_is_static(bool is_static) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(StaticBit::update(is_static, untag()->kind_bits_));
  }
  void set_is_final(bool is_final) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(FinalBit::update(is_final, untag()->kind_bits_));
  }
  void set_is_const(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(ConstBit::update(value, untag()->kind_bits_));
  }
  void set_owner(const Object& value) const { untag()->set_owner(value.ptr()); }
  void set_token_pos(TokenPosition token_pos) const {
    StoreNonPointer(&untag()->token_pos_, token_pos);
  }
  void set_end_token_pos(TokenPosition token_pos) const {
    StoreNonPointer(&untag()->end_token_pos_, token_pos);
  }
  void set_kind_bits(uint16_t value) const {
    StoreNonPointer<uint16_t, uint16_t, std::memory_order_release>(
        &untag()->kind_bits_, value);
  }

  static FieldPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Field, Object);
  friend class Class;
  friend class UntaggedField;
  friend class FieldSerializationCluster;
  friend class FieldDeserializationCluster;
};

class Script : public Object {
 public:
  StringPtr url() const { return untag()->url(); }
  void set_url(const String& value) const;

  // The actual url which was loaded from disk, if provided by the embedder.
  StringPtr resolved_url() const;
  bool HasSource() const;
  StringPtr Source() const;
  bool IsPartOfDartColonLibrary() const;

  GrowableObjectArrayPtr GenerateLineNumberArray() const;

  intptr_t line_offset() const { return 0; }
  intptr_t col_offset() const { return 0; }
  // Returns the max real token position for this script, or kNoSource
  // if there is no line starts information.
  TokenPosition MaxPosition() const;

  // The load time in milliseconds since epoch.
  int64_t load_timestamp() const { return untag()->load_timestamp_; }

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Initializes thie script object from a kernel file.
  void InitializeFromKernel(const KernelProgramInfo& info,
                            intptr_t script_index,
                            const TypedData& line_starts,
                            const TypedDataView& constant_coverage) const;
#endif

  // The index of this script into the [KernelProgramInfo] object's source
  // table.
  intptr_t kernel_script_index() const { return untag()->kernel_script_index_; }

  static intptr_t line_starts_offset() {
    return OFFSET_OF(UntaggedScript, line_starts_);
  }

  TypedDataPtr line_starts() const;

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  TypedDataViewPtr constant_coverage() const;
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  LibraryPtr FindLibrary() const;
  StringPtr GetLine(intptr_t line_number, Heap::Space space = Heap::kNew) const;
  StringPtr GetSnippet(intptr_t from_line,
                       intptr_t from_column,
                       intptr_t to_line,
                       intptr_t to_column) const;

  // For real token positions when line starts are available, returns whether or
  // not a GetTokenLocation call would succeed. Returns true for non-real token
  // positions or if there is no line starts information.
  bool IsValidTokenPosition(TokenPosition token_pos) const;

  // Returns whether a line and column could be computed for the given token
  // position and, if so, sets *line and *column (if not nullptr).
  bool GetTokenLocation(const TokenPosition& token_pos,
                        intptr_t* line,
                        intptr_t* column = nullptr) const;

  // Returns the length of the token at the given position. If the length cannot
  // be determined, returns a negative value.
  intptr_t GetTokenLength(const TokenPosition& token_pos) const;

  // Returns whether any tokens were found for the given line. When found,
  // *first_token_index and *last_token_index are set to the first and
  // last token on the line, respectively.
  bool TokenRangeAtLine(intptr_t line_number,
                        TokenPosition* first_token_index,
                        TokenPosition* last_token_index) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedScript));
  }

  static ScriptPtr New(const String& url, const String& source);

  static ScriptPtr New(const String& url,
                       const String& resolved_url,
                       const String& source);

#if !defined(DART_PRECOMPILED_RUNTIME)
  void LoadSourceFromKernel(const uint8_t* kernel_buffer,
                            intptr_t kernel_buffer_len) const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  void CollectTokenPositionsFor() const;
  ArrayPtr CollectConstConstructorCoverageFrom() const;

 private:
  KernelProgramInfoPtr kernel_program_info() const {
    return untag()->kernel_program_info();
  }

  void set_debug_positions(const Array& value) const;

#if !defined(DART_PRECOMPILED_RUNTIME)
  bool HasCachedMaxPosition() const;

  void SetHasCachedMaxPosition(bool value) const;
  void SetCachedMaxPosition(intptr_t value) const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  void set_resolved_url(const String& value) const;
  void set_source(const String& value) const;
  void set_load_timestamp(int64_t value) const;
  ArrayPtr debug_positions() const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Script, Object);
  friend class Class;
  friend class Precompiler;
};

class DictionaryIterator : public ValueObject {
 public:
  explicit DictionaryIterator(const Library& library);

  bool HasNext() const { return next_ix_ < size_; }

  // Returns next non-null raw object.
  ObjectPtr GetNext();

 private:
  void MoveToNextObject();

  const Array& array_;
  const int size_;  // Number of elements to iterate over.
  int next_ix_;     // Index of next element.

  friend class ClassDictionaryIterator;
  DISALLOW_COPY_AND_ASSIGN(DictionaryIterator);
};

class ClassDictionaryIterator : public DictionaryIterator {
 public:
  enum IterationKind {
    // TODO(hausner): fix call sites that use kIteratePrivate. There is only
    // one top-level class per library left, not an array to iterate over.
    kIteratePrivate,
    kNoIteratePrivate
  };

  ClassDictionaryIterator(const Library& library,
                          IterationKind kind = kNoIteratePrivate);

  bool HasNext() const {
    return (next_ix_ < size_) || !toplevel_class_.IsNull();
  }

  // Returns a non-null raw class.
  ClassPtr GetNextClass();

 private:
  void MoveToNextClass();

  Class& toplevel_class_;

  DISALLOW_COPY_AND_ASSIGN(ClassDictionaryIterator);
};

class Library : public Object {
 public:
  StringPtr name() const { return untag()->name(); }
  void SetName(const String& name) const;

  StringPtr url() const { return untag()->url(); }
  static StringPtr UrlOf(LibraryPtr lib) { return lib->untag()->url(); }
  StringPtr private_key() const { return untag()->private_key(); }
  bool LoadNotStarted() const {
    return untag()->load_state_ == UntaggedLibrary::kAllocated;
  }
  bool LoadRequested() const {
    return untag()->load_state_ == UntaggedLibrary::kLoadRequested;
  }
  bool LoadInProgress() const {
    return untag()->load_state_ == UntaggedLibrary::kLoadInProgress;
  }
  void SetLoadRequested() const;
  void SetLoadInProgress() const;
  bool Loaded() const {
    return untag()->load_state_ == UntaggedLibrary::kLoaded;
  }
  void SetLoaded() const;

  LoadingUnitPtr loading_unit() const { return untag()->loading_unit(); }
  void set_loading_unit(const LoadingUnit& value) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedLibrary));
  }

  static LibraryPtr New(const String& url);

  ObjectPtr Invoke(const String& selector,
                   const Array& arguments,
                   const Array& argument_names,
                   bool respect_reflectable = true,
                   bool check_is_entrypoint = false) const;
  ObjectPtr InvokeGetter(const String& selector,
                         bool throw_nsm_if_absent,
                         bool respect_reflectable = true,
                         bool check_is_entrypoint = false) const;
  ObjectPtr InvokeSetter(const String& selector,
                         const Instance& argument,
                         bool respect_reflectable = true,
                         bool check_is_entrypoint = false) const;

  // Evaluate the given expression as if it appeared in an top-level method of
  // this library and return the resulting value, or an error object if
  // evaluating the expression fails. The method has the formal (type)
  // parameters given in (type_)param_names, and is invoked with the (type)
  // argument values given in (type_)param_values.
  ObjectPtr EvaluateCompiledExpression(
      const ExternalTypedData& kernel_buffer,
      const Array& type_definitions,
      const Array& param_values,
      const TypeArguments& type_param_values) const;

  // Library scope name dictionary.
  //
  // TODO(turnidge): The Lookup functions are not consistent in how
  // they deal with private names.  Go through and make them a bit
  // more regular.
  void AddClass(const Class& cls) const;
  void AddObject(const Object& obj, const String& name) const;
  ObjectPtr LookupReExport(
      const String& name,
      ZoneGrowableArray<intptr_t>* visited = nullptr) const;
  ObjectPtr LookupLocalOrReExportObject(const String& name) const;
  LibraryPrefixPtr LookupLocalLibraryPrefix(const String& name) const;

  // These lookups are local within the library.
  ClassPtr LookupClass(const String& name) const;
  ClassPtr LookupClassAllowPrivate(const String& name) const;
  FieldPtr LookupFieldAllowPrivate(const String& name) const;
  FunctionPtr LookupFunctionAllowPrivate(const String& name) const;

  // Look up a Script based on a url. If 'useResolvedUri' is not provided or is
  // false, 'url' should have a 'dart:' scheme for Dart core libraries,
  // a 'package:' scheme for packages, and 'file:' scheme otherwise.
  //
  // If 'useResolvedUri' is true, 'url' should have a 'org-dartlang-sdk:' scheme
  // for Dart core libraries and a 'file:' scheme otherwise.
  ScriptPtr LookupScript(const String& url, bool useResolvedUri = false) const;
  ArrayPtr LoadedScripts() const;

  void AddExport(const Namespace& ns) const;

  void AddMetadata(const Object& declaration, intptr_t kernel_offset) const;
  ObjectPtr GetMetadata(const Object& declaration) const;

  // Tries to finds a @pragma annotation on [object].
  //
  // If successful returns `true`. If an error happens during constant
  // evaluation, returns `false.
  //
  // If [only_core] is true, then the annotations on the object will only
  // be inspected if it is part of a core library.
  //
  // If [multiple] is true, then sets [options] to an GrowableObjectArray
  // containing all results and [options] may not be nullptr.
  //
  // WARNING: If the isolate received an [UnwindError] this function will not
  // return and rather unwinds until the enclosing setjmp() handler.
  static bool FindPragma(Thread* T,
                         bool only_core,
                         const Object& object,
                         const String& pragma_name,
                         bool multiple = false,
                         Object* options = nullptr);

  ClassPtr toplevel_class() const { return untag()->toplevel_class(); }
  void set_toplevel_class(const Class& value) const;

  GrowableObjectArrayPtr used_scripts() const {
    return untag()->used_scripts();
  }

  // Library imports.
  ArrayPtr imports() const { return untag()->imports(); }
  ArrayPtr exports() const { return untag()->exports(); }
  void AddImport(const Namespace& ns) const;
  intptr_t num_imports() const { return untag()->num_imports_; }
  NamespacePtr ImportAt(intptr_t index) const;
  LibraryPtr ImportLibraryAt(intptr_t index) const;

  ArrayPtr dependencies() const { return untag()->dependencies(); }
  void set_dependencies(const Array& deps) const;

  void DropDependenciesAndCaches() const;

  // Resolving native methods for script loaded in the library.
  Dart_NativeEntryResolver native_entry_resolver() const {
    return LoadNonPointer<Dart_NativeEntryResolver, std::memory_order_relaxed>(
        &untag()->native_entry_resolver_);
  }
  void set_native_entry_resolver(Dart_NativeEntryResolver value) const {
    StoreNonPointer<Dart_NativeEntryResolver, Dart_NativeEntryResolver,
                    std::memory_order_relaxed>(&untag()->native_entry_resolver_,
                                               value);
  }
  Dart_NativeEntrySymbol native_entry_symbol_resolver() const {
    return LoadNonPointer<Dart_NativeEntrySymbol, std::memory_order_relaxed>(
        &untag()->native_entry_symbol_resolver_);
  }
  void set_native_entry_symbol_resolver(
      Dart_NativeEntrySymbol native_symbol_resolver) const {
    StoreNonPointer<Dart_NativeEntrySymbol, Dart_NativeEntrySymbol,
                    std::memory_order_relaxed>(
        &untag()->native_entry_symbol_resolver_, native_symbol_resolver);
  }

  // Resolver for FFI native function pointers.
  Dart_FfiNativeResolver ffi_native_resolver() const {
    return LoadNonPointer<Dart_FfiNativeResolver, std::memory_order_relaxed>(
        &untag()->ffi_native_resolver_);
  }
  void set_ffi_native_resolver(Dart_FfiNativeResolver value) const {
    StoreNonPointer<Dart_FfiNativeResolver, Dart_FfiNativeResolver,
                    std::memory_order_relaxed>(&untag()->ffi_native_resolver_,
                                               value);
  }

  bool is_in_fullsnapshot() const {
    return UntaggedLibrary::InFullSnapshotBit::decode(untag()->flags_);
  }
  void set_is_in_fullsnapshot(bool value) const {
    set_flags(
        UntaggedLibrary::InFullSnapshotBit::update(value, untag()->flags_));
  }

  bool is_nnbd() const {
    return UntaggedLibrary::NnbdBit::decode(untag()->flags_);
  }
  void set_is_nnbd(bool value) const {
    set_flags(UntaggedLibrary::NnbdBit::update(value, untag()->flags_));
  }

  NNBDMode nnbd_mode() const {
    return is_nnbd() ? NNBDMode::kOptedInLib : NNBDMode::kLegacyLib;
  }

  NNBDCompiledMode nnbd_compiled_mode() const {
    return static_cast<NNBDCompiledMode>(
        UntaggedLibrary::NnbdCompiledModeBits::decode(untag()->flags_));
  }
  void set_nnbd_compiled_mode(NNBDCompiledMode value) const {
    set_flags(UntaggedLibrary::NnbdCompiledModeBits::update(
        static_cast<uint8_t>(value), untag()->flags_));
  }

  StringPtr PrivateName(const String& name) const;

  intptr_t index() const { return untag()->index_; }
  void set_index(intptr_t value) const {
    ASSERT((value == -1) ||
           ((value >= 0) && (value < std::numeric_limits<classid_t>::max())));
    StoreNonPointer(&untag()->index_, value);
  }

  void Register(Thread* thread) const;
  static void RegisterLibraries(Thread* thread,
                                const GrowableObjectArray& libs);

  bool IsDebuggable() const {
    return UntaggedLibrary::DebuggableBit::decode(untag()->flags_);
  }
  void set_debuggable(bool value) const {
    set_flags(UntaggedLibrary::DebuggableBit::update(value, untag()->flags_));
  }

  bool is_dart_scheme() const {
    return UntaggedLibrary::DartSchemeBit::decode(untag()->flags_);
  }
  void set_is_dart_scheme(bool value) const {
    set_flags(UntaggedLibrary::DartSchemeBit::update(value, untag()->flags_));
  }

  // Includes 'dart:async', 'dart:typed_data', etc.
  bool IsAnyCoreLibrary() const;

  inline intptr_t UrlHash() const;

#if !defined(DART_PRECOMPILED_RUNTIME)
  KernelProgramInfoPtr kernel_program_info() const {
    return untag()->kernel_program_info();
  }
  void set_kernel_program_info(const KernelProgramInfo& info) const;
  TypedDataViewPtr KernelLibrary() const;
  intptr_t KernelLibraryOffset() const;
#endif

  intptr_t kernel_library_index() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return untag()->kernel_library_index_;
#endif
  }

  void set_kernel_library_index(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    StoreNonPointer(&untag()->kernel_library_index_, value);
#endif
  }

  static LibraryPtr LookupLibrary(Thread* thread, const String& url);
  static LibraryPtr GetLibrary(intptr_t index);

  static void InitCoreLibrary(IsolateGroup* isolate_group);
  static void InitNativeWrappersLibrary(IsolateGroup* isolate_group,
                                        bool is_kernel_file);

  static LibraryPtr AsyncLibrary();
  static LibraryPtr ConvertLibrary();
  static LibraryPtr CoreLibrary();
  static LibraryPtr CollectionLibrary();
  static LibraryPtr DeveloperLibrary();
  static LibraryPtr FfiLibrary();
  static LibraryPtr InternalLibrary();
  static LibraryPtr IsolateLibrary();
  static LibraryPtr MathLibrary();
#if !defined(DART_PRECOMPILED_RUNTIME)
  static LibraryPtr MirrorsLibrary();
#endif
  static LibraryPtr NativeWrappersLibrary();
  static LibraryPtr TypedDataLibrary();
  static LibraryPtr VMServiceLibrary();

  // Eagerly compile all classes and functions in the library.
  static ErrorPtr CompileAll(bool ignore_error = false);
#if !defined(DART_PRECOMPILED_RUNTIME)
  // Finalize all classes in all libraries.
  static ErrorPtr FinalizeAllClasses();
#endif

#if defined(DEBUG) && !defined(DART_PRECOMPILED_RUNTIME)
  // Checks function fingerprints. Prints mismatches and aborts if
  // mismatch found.
  static void CheckFunctionFingerprints();
#endif  // defined(DEBUG) && !defined(DART_PRECOMPILED_RUNTIME).

  static bool IsPrivate(const String& name);

  // Construct the full name of a corelib member.
  static const String& PrivateCoreLibName(const String& member);

  // Returns true if [name] matches full name of corelib [member].
  static bool IsPrivateCoreLibName(const String& name, const String& member);

  // Lookup class in the core lib which also contains various VM
  // helper methods and classes. Allow look up of private classes.
  static ClassPtr LookupCoreClass(const String& class_name);

  // Return Function::null() if function does not exist in libs.
  static FunctionPtr GetFunction(const GrowableArray<Library*>& libs,
                                 const char* class_name,
                                 const char* function_name);

  // Character used to indicate a private identifier.
  static const char kPrivateIdentifierStart = '_';

  // Character used to separate private identifiers from
  // the library-specific key.
  static const char kPrivateKeySeparator = '@';

  void CheckReload(const Library& replacement,
                   ProgramReloadContext* context) const;

  // Returns a closure of top level function 'name' in the exported namespace
  // of this library. If a top level function 'name' does not exist we look
  // for a top level getter 'name' that returns a closure.
  ObjectPtr GetFunctionClosure(const String& name) const;

  // Ensures that all top-level functions and variables (fields) are loaded.
  void EnsureTopLevelClassIsFinalized() const;

 private:
  static constexpr int kInitialImportsCapacity = 4;
  static constexpr int kImportsCapacityIncrement = 8;

  static LibraryPtr New();

  // These methods are only used by the Precompiler to obfuscate
  // the name and url.
  void set_name(const String& name) const;
  void set_url(const String& url) const;
  void set_private_key(const String& key) const;

  void set_num_imports(intptr_t value) const;
  void set_flags(uint8_t flags) const;
  bool HasExports() const;
  ArrayPtr loaded_scripts() const { return untag()->loaded_scripts(); }
  ArrayPtr metadata() const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
    return untag()->metadata();
  }
  void set_metadata(const Array& value) const;
  ArrayPtr dictionary() const { return untag()->dictionary(); }
  void InitClassDictionary() const;

  void InitImportList() const;
  void RehashDictionary(const Array& old_dict, intptr_t new_dict_size) const;
  static LibraryPtr NewLibraryHelper(const String& url, bool import_core_lib);
  ObjectPtr LookupEntry(const String& name, intptr_t* index) const;
  ObjectPtr LookupLocalObject(const String& name) const;
  ObjectPtr LookupLocalObjectAllowPrivate(const String& name) const;

  void AllocatePrivateKey() const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Library, Object);

  friend class Bootstrap;
  friend class Class;
  friend class Debugger;
  friend class DictionaryIterator;
  friend class Isolate;
  friend class LibraryDeserializationCluster;
  friend class Namespace;
  friend class Object;
  friend class Precompiler;
};

// A Namespace contains the names in a library dictionary, filtered by
// the show/hide combinators.
class Namespace : public Object {
 public:
  LibraryPtr target() const { return untag()->target(); }
  ArrayPtr show_names() const { return untag()->show_names(); }
  ArrayPtr hide_names() const { return untag()->hide_names(); }
  LibraryPtr owner() const { return untag()->owner(); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedNamespace));
  }

  bool HidesName(const String& name) const;
  ObjectPtr Lookup(const String& name,
                   ZoneGrowableArray<intptr_t>* trail = nullptr) const;

  static NamespacePtr New(const Library& library,
                          const Array& show_names,
                          const Array& hide_names,
                          const Library& owner);

 private:
  static NamespacePtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Namespace, Object);
  friend class Class;
  friend class Precompiler;
};

class KernelProgramInfo : public Object {
 public:
  static KernelProgramInfoPtr New(const TypedDataBase& kernel_component,
                                  const TypedDataView& string_data,
                                  const TypedDataView& metadata_payload,
                                  const TypedDataView& metadata_mappings,
                                  const TypedDataView& constants_table,
                                  const TypedData& string_offsets,
                                  const TypedData& canonical_names,
                                  const Array& scripts,
                                  const Array& libraries_cache,
                                  const Array& classes_cache);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedKernelProgramInfo));
  }

  TypedDataPtr string_offsets() const { return untag()->string_offsets(); }

  TypedDataBasePtr kernel_component() const {
    return untag()->kernel_component();
  }
  TypedDataViewPtr string_data() const { return untag()->string_data(); }

  TypedDataPtr canonical_names() const { return untag()->canonical_names(); }

  TypedDataViewPtr metadata_payloads() const {
    return untag()->metadata_payloads();
  }

  TypedDataViewPtr metadata_mappings() const {
    return untag()->metadata_mappings();
  }

  intptr_t KernelLibraryStartOffset(intptr_t library_index) const;
  intptr_t KernelLibraryEndOffset(intptr_t library_index) const;
  TypedDataViewPtr KernelLibrary(intptr_t library_index) const;

  TypedDataViewPtr constants_table() const {
    return untag()->constants_table();
  }

  void set_constants_table(const TypedDataView& value) const;

  ArrayPtr scripts() const { return untag()->scripts(); }
  void set_scripts(const Array& scripts) const;

  ArrayPtr constants() const { return untag()->constants(); }
  void set_constants(const Array& constants) const;

  ScriptPtr ScriptAt(intptr_t index) const;

  ArrayPtr libraries_cache() const { return untag()->libraries_cache(); }
  void set_libraries_cache(const Array& cache) const;
  LibraryPtr LookupLibrary(Thread* thread, const Smi& name_index) const;
  LibraryPtr InsertLibrary(Thread* thread,
                           const Smi& name_index,
                           const Library& lib) const;

  ArrayPtr classes_cache() const { return untag()->classes_cache(); }
  void set_classes_cache(const Array& cache) const;
  ClassPtr LookupClass(Thread* thread, const Smi& name_index) const;
  ClassPtr InsertClass(Thread* thread,
                       const Smi& name_index,
                       const Class& klass) const;

 private:
  static KernelProgramInfoPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(KernelProgramInfo, Object);
  friend class Class;
};

// ObjectPool contains constants, immediates and addresses referenced by
// generated code and deoptimization infos. Each entry has an type associated
// with it which is stored in-inline after all the entries.
class ObjectPool : public Object {
 public:
  using EntryType = compiler::ObjectPoolBuilderEntry::EntryType;
  using Patchability = compiler::ObjectPoolBuilderEntry::Patchability;
  using SnapshotBehavior = compiler::ObjectPoolBuilderEntry::SnapshotBehavior;
  using TypeBits = compiler::ObjectPoolBuilderEntry::TypeBits;
  using PatchableBit = compiler::ObjectPoolBuilderEntry::PatchableBit;
  using SnapshotBehaviorBits =
      compiler::ObjectPoolBuilderEntry::SnapshotBehaviorBits;

  struct Entry {
    Entry() : raw_value_(), type_() {}
    explicit Entry(const Object* obj)
        : obj_(obj), type_(EntryType::kTaggedObject) {}
    Entry(uword value, EntryType info) : raw_value_(value), type_(info) {}
    union {
      const Object* obj_;
      uword raw_value_;
    };
    EntryType type_;
  };

  intptr_t Length() const { return untag()->length_; }
  void SetLength(intptr_t value) const {
    StoreNonPointer(&untag()->length_, value);
  }

  static intptr_t length_offset() {
    return OFFSET_OF(UntaggedObjectPool, length_);
  }
  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(UntaggedObjectPool, data);
  }
  static intptr_t element_offset(intptr_t index) {
    return OFFSET_OF_RETURNED_VALUE(UntaggedObjectPool, data) +
           sizeof(UntaggedObjectPool::Entry) * index;
  }

  struct ArrayTraits {
    static intptr_t elements_start_offset() {
      return ObjectPool::data_offset();
    }

    static constexpr intptr_t kElementSize = sizeof(UntaggedObjectPool::Entry);
  };

  EntryType TypeAt(intptr_t index) const {
    ASSERT((index >= 0) && (index <= Length()));
    return TypeBits::decode(untag()->entry_bits()[index]);
  }

  Patchability PatchableAt(intptr_t index) const {
    ASSERT((index >= 0) && (index <= Length()));
    return PatchableBit::decode(untag()->entry_bits()[index]);
  }

  SnapshotBehavior SnapshotBehaviorAt(intptr_t index) const {
    ASSERT((index >= 0) && (index <= Length()));
    return SnapshotBehaviorBits::decode(untag()->entry_bits()[index]);
  }

  static uint8_t EncodeBits(EntryType type,
                            Patchability patchable,
                            SnapshotBehavior snapshot_behavior) {
    return PatchableBit::encode(patchable) | TypeBits::encode(type) |
           SnapshotBehaviorBits::encode(snapshot_behavior);
  }

  void SetTypeAt(intptr_t index,
                 EntryType type,
                 Patchability patchable,
                 SnapshotBehavior snapshot_behavior) const {
    ASSERT(index >= 0 && index <= Length());
    const uint8_t bits = EncodeBits(type, patchable, snapshot_behavior);
    StoreNonPointer(&untag()->entry_bits()[index], bits);
  }

  template <std::memory_order order = std::memory_order_relaxed>
  ObjectPtr ObjectAt(intptr_t index) const {
    ASSERT(TypeAt(index) == EntryType::kTaggedObject);
    return LoadPointer<ObjectPtr, order>(&(EntryAddr(index)->raw_obj_));
  }

  template <std::memory_order order = std::memory_order_relaxed>
  void SetObjectAt(intptr_t index, const Object& obj) const {
    ASSERT((TypeAt(index) == EntryType::kTaggedObject) ||
           (TypeAt(index) == EntryType::kImmediate && obj.IsSmi()));
    StorePointer<ObjectPtr, order>(&EntryAddr(index)->raw_obj_, obj.ptr());
  }

  uword RawValueAt(intptr_t index) const {
    ASSERT(TypeAt(index) != EntryType::kTaggedObject);
    return EntryAddr(index)->raw_value_;
  }
  void SetRawValueAt(intptr_t index, uword raw_value) const {
    ASSERT(TypeAt(index) != EntryType::kTaggedObject);
    StoreNonPointer(&EntryAddr(index)->raw_value_, raw_value);
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedObjectPool) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedObjectPool, data));
    return 0;
  }

  static constexpr intptr_t kBytesPerElement =
      sizeof(UntaggedObjectPool::Entry) + sizeof(uint8_t);
  static constexpr intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize(intptr_t len) {
    // Ensure that variable length data is not adding to the object length.
    ASSERT(sizeof(UntaggedObjectPool) ==
           (sizeof(UntaggedObject) + (1 * kWordSize)));
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(UntaggedObjectPool) +
                                 (len * kBytesPerElement));
  }

  static ObjectPoolPtr NewFromBuilder(
      const compiler::ObjectPoolBuilder& builder);
  static ObjectPoolPtr New(intptr_t len);

  void CopyInto(compiler::ObjectPoolBuilder* builder) const;

  // Returns the pool index from the offset relative to a tagged ObjectPoolPtr,
  // adjusting for the tag-bit.
  static intptr_t IndexFromOffset(intptr_t offset) {
    ASSERT(
        Utils::IsAligned(offset + kHeapObjectTag, compiler::target::kWordSize));
#if defined(DART_PRECOMPILER)
    return (offset + kHeapObjectTag -
            compiler::target::ObjectPool::element_offset(0)) /
           compiler::target::kWordSize;
#else
    return (offset + kHeapObjectTag - element_offset(0)) / kWordSize;
#endif
  }

  static intptr_t OffsetFromIndex(intptr_t index) {
    return element_offset(index) - kHeapObjectTag;
  }

  void DebugPrint() const;

 private:
  UntaggedObjectPool::Entry const* EntryAddr(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return &untag()->data()[index];
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ObjectPool, Object);
  friend class Class;
  friend class Object;
  friend class UntaggedObjectPool;
};

class Instructions : public Object {
 public:
  enum {
    kSizePos = 0,
    kSizeSize = 31,
    kFlagsPos = kSizePos + kSizeSize,
    kFlagsSize = 1,  // Currently, only flag is single entry flag.
  };

  class SizeBits : public BitField<uint32_t, uint32_t, kSizePos, kSizeSize> {};
  class FlagsBits : public BitField<uint32_t, bool, kFlagsPos, kFlagsSize> {};

  // Excludes HeaderSize().
  intptr_t Size() const { return SizeBits::decode(untag()->size_and_flags_); }
  static intptr_t Size(const InstructionsPtr instr) {
    return SizeBits::decode(instr->untag()->size_and_flags_);
  }

  bool HasMonomorphicEntry() const {
    return FlagsBits::decode(untag()->size_and_flags_);
  }
  static bool HasMonomorphicEntry(const InstructionsPtr instr) {
    return FlagsBits::decode(instr->untag()->size_and_flags_);
  }

  uword PayloadStart() const { return PayloadStart(ptr()); }
  uword MonomorphicEntryPoint() const { return MonomorphicEntryPoint(ptr()); }
  uword EntryPoint() const { return EntryPoint(ptr()); }
  static uword PayloadStart(const InstructionsPtr instr) {
    return reinterpret_cast<uword>(instr->untag()) + HeaderSize();
  }

// Note: We keep the checked entrypoint offsets even (emitting NOPs if
// necessary) to allow them to be seen as Smis by the GC.
#if defined(TARGET_ARCH_IA32)
  static constexpr intptr_t kMonomorphicEntryOffsetJIT = 6;
  static constexpr intptr_t kPolymorphicEntryOffsetJIT = 36;
  static constexpr intptr_t kMonomorphicEntryOffsetAOT = 0;
  static constexpr intptr_t kPolymorphicEntryOffsetAOT = 0;
#elif defined(TARGET_ARCH_X64)
  static constexpr intptr_t kMonomorphicEntryOffsetJIT = 8;
  static constexpr intptr_t kPolymorphicEntryOffsetJIT = 42;
  static constexpr intptr_t kMonomorphicEntryOffsetAOT = 8;
  static constexpr intptr_t kPolymorphicEntryOffsetAOT = 22;
#elif defined(TARGET_ARCH_ARM)
  static constexpr intptr_t kMonomorphicEntryOffsetJIT = 0;
  static constexpr intptr_t kPolymorphicEntryOffsetJIT = 44;
  static constexpr intptr_t kMonomorphicEntryOffsetAOT = 0;
  static constexpr intptr_t kPolymorphicEntryOffsetAOT = 16;
#elif defined(TARGET_ARCH_ARM64)
  static constexpr intptr_t kMonomorphicEntryOffsetJIT = 8;
  static constexpr intptr_t kPolymorphicEntryOffsetJIT = 52;
  static constexpr intptr_t kMonomorphicEntryOffsetAOT = 8;
  static constexpr intptr_t kPolymorphicEntryOffsetAOT = 24;
#elif defined(TARGET_ARCH_RISCV32)
  static constexpr intptr_t kMonomorphicEntryOffsetJIT = 6;
  static constexpr intptr_t kPolymorphicEntryOffsetJIT = 44;
  static constexpr intptr_t kMonomorphicEntryOffsetAOT = 6;
  static constexpr intptr_t kPolymorphicEntryOffsetAOT = 18;
#elif defined(TARGET_ARCH_RISCV64)
  static constexpr intptr_t kMonomorphicEntryOffsetJIT = 6;
  static constexpr intptr_t kPolymorphicEntryOffsetJIT = 44;
  static constexpr intptr_t kMonomorphicEntryOffsetAOT = 6;
  static constexpr intptr_t kPolymorphicEntryOffsetAOT = 18;
#else
#error Missing entry offsets for current architecture
#endif

  static uword MonomorphicEntryPoint(const InstructionsPtr instr) {
    uword entry = PayloadStart(instr);
    if (HasMonomorphicEntry(instr)) {
      entry += !FLAG_precompiled_mode ? kMonomorphicEntryOffsetJIT
                                      : kMonomorphicEntryOffsetAOT;
    }
    return entry;
  }

  static uword EntryPoint(const InstructionsPtr instr) {
    uword entry = PayloadStart(instr);
    if (HasMonomorphicEntry(instr)) {
      entry += !FLAG_precompiled_mode ? kPolymorphicEntryOffsetJIT
                                      : kPolymorphicEntryOffsetAOT;
    }
    return entry;
  }

  static constexpr intptr_t kMaxElements =
      (kMaxInt32 - (sizeof(UntaggedInstructions) + sizeof(UntaggedObject) +
                    (2 * kObjectStartAlignment)));

  // Currently, we align bare instruction payloads on 4 byte boundaries.
  //
  // If we later decide to align on larger boundaries to put entries at the
  // start of cache lines, make sure to account for entry points that are
  // _not_ at the start of the payload.
  static constexpr intptr_t kBarePayloadAlignment = 4;

  // When instructions reside in the heap we align the payloads on word
  // boundaries.
  static constexpr intptr_t kNonBarePayloadAlignment = kWordSize;

  // In the precompiled runtime when running in bare instructions mode,
  // Instructions objects don't exist, just their bare payloads, so we
  // mark them as unreachable in that case.

  static intptr_t HeaderSize() {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#endif
    return Utils::RoundUp(sizeof(UntaggedInstructions),
                          kNonBarePayloadAlignment);
  }

  static intptr_t InstanceSize() {
    ASSERT_EQUAL(sizeof(UntaggedInstructions),
                 OFFSET_OF_RETURNED_VALUE(UntaggedInstructions, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t size) {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#endif
    return RoundedAllocationSize(HeaderSize() + size);
  }

  static InstructionsPtr FromPayloadStart(uword payload_start) {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#endif
    return static_cast<InstructionsPtr>(payload_start - HeaderSize() +
                                        kHeapObjectTag);
  }

  bool Equals(const Instructions& other) const {
    return Equals(ptr(), other.ptr());
  }

  static bool Equals(InstructionsPtr a, InstructionsPtr b) {
    // This method should only be called on non-null Instructions objects.
    ASSERT_EQUAL(a->GetClassId(), kInstructionsCid);
    ASSERT_EQUAL(b->GetClassId(), kInstructionsCid);
    // Don't include the object header tags wholesale in the comparison,
    // because the GC tags may differ in JIT mode. In fact, we can skip checking
    // the object header entirely, as we're guaranteed that the cids match,
    // because there are no subclasses for the Instructions class, and the sizes
    // should match if the content size encoded in size_and_flags_ matches.
    if (a->untag()->size_and_flags_ != b->untag()->size_and_flags_) {
      return false;
    }
    NoSafepointScope no_safepoint;
    return memcmp(a->untag()->data(), b->untag()->data(), Size(a)) == 0;
  }

  uint32_t Hash() const { return Hash(ptr()); }

  static uint32_t Hash(const InstructionsPtr instr) {
    return HashBytes(reinterpret_cast<const uint8_t*>(PayloadStart(instr)),
                     Size(instr));
  }

  CodeStatistics* stats() const;
  void set_stats(CodeStatistics* stats) const;

 private:
  friend struct RelocatorTestHelper;

  void SetSize(intptr_t value) const {
    ASSERT(value >= 0);
    StoreNonPointer(&untag()->size_and_flags_,
                    SizeBits::update(value, untag()->size_and_flags_));
  }

  void SetHasMonomorphicEntry(bool value) const {
    StoreNonPointer(&untag()->size_and_flags_,
                    FlagsBits::update(value, untag()->size_and_flags_));
  }

  // New is a private method as RawInstruction and RawCode objects should
  // only be created using the Code::FinalizeCode method. This method creates
  // the RawInstruction and RawCode objects, sets up the pointer offsets
  // and links the two in a GC safe manner.
  static InstructionsPtr New(intptr_t size, bool has_monomorphic_entry);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Instructions, Object);
  friend class Class;
  friend class Code;
  friend class AssemblyImageWriter;
  friend class BlobImageWriter;
  friend class ImageWriter;
};

// An InstructionsSection contains extra information about serialized AOT
// snapshots.
//
// To avoid changing the embedder to return more information about an AOT
// snapshot and possibly disturbing existing clients of that interface, we
// serialize a single InstructionsSection object at the start of any text
// segments. In bare instructions mode, it also has the benefit of providing
// memory accounting for the instructions payloads and avoiding special casing
// Images with bare instructions payloads in the GC. Otherwise, it is empty
// and the Instructions objects come after it in the Image.
class InstructionsSection : public Object {
 public:
  // Excludes HeaderSize().
  static intptr_t Size(const InstructionsSectionPtr instr) {
    return instr->untag()->payload_length_;
  }
  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedInstructionsSection) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedInstructionsSection, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t size) {
    return Utils::RoundUp(HeaderSize() + size, kObjectAlignment);
  }

  static intptr_t HeaderSize() {
    return Utils::RoundUp(sizeof(UntaggedInstructionsSection),
                          Instructions::kBarePayloadAlignment);
  }

  // There are no public instance methods for the InstructionsSection class, as
  // all access to the contents is handled by methods on the Image class.

 private:
  // Note there are no New() methods for InstructionsSection. Instead, the
  // serializer writes the UntaggedInstructionsSection object manually at the
  // start of instructions Images in precompiled snapshots.

  FINAL_HEAP_OBJECT_IMPLEMENTATION(InstructionsSection, Object);
  friend class Class;
};

// Table which maps ranges of machine code to [Code] or
// [CompressedStackMaps] objects.
// Used in AOT in bare instructions mode.
class InstructionsTable : public Object {
 public:
  static intptr_t InstanceSize() { return sizeof(UntaggedInstructionsTable); }

  static InstructionsTablePtr New(intptr_t length,
                                  uword start_pc,
                                  uword end_pc,
                                  uword rodata);

  void SetCodeAt(intptr_t index, CodePtr code) const;

  bool ContainsPc(uword pc) const { return ContainsPc(ptr(), pc); }
  static bool ContainsPc(InstructionsTablePtr table, uword pc);

  static CodePtr FindCode(InstructionsTablePtr table, uword pc);

  static const UntaggedCompressedStackMaps::Payload*
  FindStackMap(InstructionsTablePtr table, uword pc, uword* start_pc);

  static const UntaggedCompressedStackMaps::Payload* GetCanonicalStackMap(
      InstructionsTablePtr table);

  const UntaggedInstructionsTable::Data* rodata() const {
    return ptr()->untag()->rodata_;
  }

  // Returns start address of the instructions entry with given index.
  uword PayloadStartAt(intptr_t index) const {
    return InstructionsTable::PayloadStartAt(this->ptr(), index);
  }
  static uword PayloadStartAt(InstructionsTablePtr table, intptr_t index);

  // Returns entry point of the instructions with given index.
  uword EntryPointAt(intptr_t index) const;

 private:
  uword start_pc() const { return InstructionsTable::start_pc(this->ptr()); }
  static uword start_pc(InstructionsTablePtr table) {
    return table->untag()->start_pc_;
  }

  uword end_pc() const { return InstructionsTable::end_pc(this->ptr()); }
  static uword end_pc(InstructionsTablePtr table) {
    return table->untag()->end_pc_;
  }

  ArrayPtr code_objects() const { return untag()->code_objects_; }

  void set_length(intptr_t value) const;
  void set_start_pc(uword value) const;
  void set_end_pc(uword value) const;
  void set_code_objects(const Array& value) const;
  void set_rodata(uword rodata) const;

  uint32_t ConvertPcToOffset(uword pc) const {
    return InstructionsTable::ConvertPcToOffset(this->ptr(), pc);
  }
  static uint32_t ConvertPcToOffset(InstructionsTablePtr table, uword pc);

  static intptr_t FindEntry(InstructionsTablePtr table,
                            uword pc,
                            intptr_t start_index = 0);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(InstructionsTable, Object);
  friend class Class;
  friend class Deserializer;
};

class LocalVarDescriptors : public Object {
 public:
  intptr_t Length() const;

  StringPtr GetName(intptr_t var_index) const;

  void SetVar(intptr_t var_index,
              const String& name,
              UntaggedLocalVarDescriptors::VarInfo* info) const;

  void GetInfo(intptr_t var_index,
               UntaggedLocalVarDescriptors::VarInfo* info) const;

  static constexpr intptr_t kBytesPerElement =
      sizeof(UntaggedLocalVarDescriptors::VarInfo);
  static constexpr intptr_t kMaxElements =
      UntaggedLocalVarDescriptors::kMaxIndex;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedLocalVarDescriptors) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedLocalVarDescriptors, names));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(UntaggedLocalVarDescriptors) +
        (len * kWordSize)  // RawStrings for names.
        + (len * sizeof(UntaggedLocalVarDescriptors::VarInfo)));
  }

  static LocalVarDescriptorsPtr New(intptr_t num_variables);

  static const char* KindToCString(
      UntaggedLocalVarDescriptors::VarInfoKind kind);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(LocalVarDescriptors, Object);
  friend class Class;
  friend class Object;
};

class PcDescriptors : public Object {
 public:
  static constexpr intptr_t kBytesPerElement = 1;
  static constexpr intptr_t kMaxElements = kMaxInt32 / kBytesPerElement;

  static intptr_t HeaderSize() { return sizeof(UntaggedPcDescriptors); }
  static intptr_t UnroundedSize(PcDescriptorsPtr desc) {
    return UnroundedSize(desc->untag()->length_);
  }
  static intptr_t UnroundedSize(intptr_t len) { return HeaderSize() + len; }
  static intptr_t InstanceSize() {
    ASSERT_EQUAL(sizeof(UntaggedPcDescriptors),
                 OFFSET_OF_RETURNED_VALUE(UntaggedPcDescriptors, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(UnroundedSize(len));
  }

  static PcDescriptorsPtr New(const void* delta_encoded_data, intptr_t size);

  // Verify (assert) assumptions about pc descriptors in debug mode.
  void Verify(const Function& function) const;

  static void PrintHeaderString();

  void PrintToJSONObject(JSONObject* jsobj, bool ref) const;

  // We would have a VisitPointers function here to traverse the
  // pc descriptors table to visit objects if any in the table.
  // Note: never return a reference to a UntaggedPcDescriptors::PcDescriptorRec
  // as the object can move.
  class Iterator : public ValueObject {
   public:
    Iterator(const PcDescriptors& descriptors, intptr_t kind_mask)
        : descriptors_(descriptors),
          kind_mask_(kind_mask),
          byte_index_(0),
          cur_pc_offset_(0),
          cur_kind_(0),
          cur_deopt_id_(0),
          cur_token_pos_(0),
          cur_try_index_(0),
          cur_yield_index_(UntaggedPcDescriptors::kInvalidYieldIndex) {}

    bool MoveNext() {
      NoSafepointScope scope;
      ReadStream stream(descriptors_.untag()->data(), descriptors_.Length(),
                        byte_index_);
      // Moves to record that matches kind_mask_.
      while (byte_index_ < descriptors_.Length()) {
        const int32_t kind_and_metadata = stream.ReadSLEB128<int32_t>();
        cur_kind_ = UntaggedPcDescriptors::KindAndMetadata::DecodeKind(
            kind_and_metadata);
        cur_try_index_ = UntaggedPcDescriptors::KindAndMetadata::DecodeTryIndex(
            kind_and_metadata);
        cur_yield_index_ =
            UntaggedPcDescriptors::KindAndMetadata::DecodeYieldIndex(
                kind_and_metadata);

        cur_pc_offset_ += stream.ReadSLEB128();

        if (!FLAG_precompiled_mode) {
          cur_deopt_id_ += stream.ReadSLEB128();
          cur_token_pos_ = Utils::AddWithWrapAround(
              cur_token_pos_, stream.ReadSLEB128<int32_t>());
        }
        byte_index_ = stream.Position();

        if ((cur_kind_ & kind_mask_) != 0) {
          return true;  // Current is valid.
        }
      }
      return false;
    }

    uword PcOffset() const { return cur_pc_offset_; }
    intptr_t DeoptId() const { return cur_deopt_id_; }
    TokenPosition TokenPos() const {
      return TokenPosition::Deserialize(cur_token_pos_);
    }
    intptr_t TryIndex() const { return cur_try_index_; }
    intptr_t YieldIndex() const { return cur_yield_index_; }
    UntaggedPcDescriptors::Kind Kind() const {
      return static_cast<UntaggedPcDescriptors::Kind>(cur_kind_);
    }

   private:
    friend class PcDescriptors;

    // For nested iterations, starting at element after.
    explicit Iterator(const Iterator& iter)
        : ValueObject(),
          descriptors_(iter.descriptors_),
          kind_mask_(iter.kind_mask_),
          byte_index_(iter.byte_index_),
          cur_pc_offset_(iter.cur_pc_offset_),
          cur_kind_(iter.cur_kind_),
          cur_deopt_id_(iter.cur_deopt_id_),
          cur_token_pos_(iter.cur_token_pos_),
          cur_try_index_(iter.cur_try_index_),
          cur_yield_index_(iter.cur_yield_index_) {}

    const PcDescriptors& descriptors_;
    const intptr_t kind_mask_;
    intptr_t byte_index_;

    intptr_t cur_pc_offset_;
    intptr_t cur_kind_;
    intptr_t cur_deopt_id_;
    int32_t cur_token_pos_;
    intptr_t cur_try_index_;
    intptr_t cur_yield_index_;
  };

  intptr_t Length() const;
  bool Equals(const PcDescriptors& other) const {
    if (Length() != other.Length()) {
      return false;
    }
    NoSafepointScope no_safepoint;
    return memcmp(untag(), other.untag(), InstanceSize(Length())) == 0;
  }

 private:
  static const char* KindAsStr(UntaggedPcDescriptors::Kind kind);

  static PcDescriptorsPtr New(intptr_t length);

  void SetLength(intptr_t value) const;
  void CopyData(const void* bytes, intptr_t size);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(PcDescriptors, Object);
  friend class Class;
  friend class Object;
};

class CodeSourceMap : public Object {
 public:
  static constexpr intptr_t kBytesPerElement = 1;
  static constexpr intptr_t kMaxElements = kMaxInt32 / kBytesPerElement;

  static intptr_t HeaderSize() { return sizeof(UntaggedCodeSourceMap); }
  static intptr_t UnroundedSize(CodeSourceMapPtr map) {
    return UnroundedSize(map->untag()->length_);
  }
  static intptr_t UnroundedSize(intptr_t len) { return HeaderSize() + len; }
  static intptr_t InstanceSize() {
    ASSERT_EQUAL(sizeof(UntaggedCodeSourceMap),
                 OFFSET_OF_RETURNED_VALUE(UntaggedCodeSourceMap, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(UnroundedSize(len));
  }

  static CodeSourceMapPtr New(intptr_t length);

  intptr_t Length() const { return untag()->length_; }
  uint8_t* Data() const { return UnsafeMutableNonPointer(&untag()->data()[0]); }

  bool Equals(const CodeSourceMap& other) const {
    if (Length() != other.Length()) {
      return false;
    }
    NoSafepointScope no_safepoint;
    return memcmp(untag(), other.untag(), InstanceSize(Length())) == 0;
  }

  uint32_t Hash() const {
    NoSafepointScope no_safepoint;
    return HashBytes(Data(), Length());
  }

  void PrintToJSONObject(JSONObject* jsobj, bool ref) const;

 private:
  void SetLength(intptr_t value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(CodeSourceMap, Object);
  friend class Class;
  friend class Object;
};

class CompressedStackMaps : public Object {
 public:
  uintptr_t payload_size() const { return PayloadSizeOf(ptr()); }
  static uintptr_t PayloadSizeOf(const CompressedStackMapsPtr raw) {
    return UntaggedCompressedStackMaps::SizeField::decode(
        raw->untag()->payload()->flags_and_size());
  }

  const uint8_t* data() const { return ptr()->untag()->payload()->data(); }

  // Methods to allow use with PointerKeyValueTrait to create sets of CSMs.
  bool Equals(const CompressedStackMaps& other) const {
    // All of the table flags and payload size must match.
    if (untag()->payload()->flags_and_size() !=
        other.untag()->payload()->flags_and_size()) {
      return false;
    }
    NoSafepointScope no_safepoint;
    return memcmp(untag(), other.untag(), InstanceSize(payload_size())) == 0;
  }
  uword Hash() const;

  static intptr_t HeaderSize() {
    return sizeof(UntaggedCompressedStackMaps) +
           sizeof(UntaggedCompressedStackMaps::Payload::FlagsAndSizeHeader);
  }
  static intptr_t UnroundedSize(CompressedStackMapsPtr maps) {
    return UnroundedSize(CompressedStackMaps::PayloadSizeOf(maps));
  }
  static intptr_t UnroundedSize(intptr_t length) {
    return HeaderSize() + length;
  }
  static intptr_t InstanceSize() { return 0; }
  static intptr_t InstanceSize(intptr_t length) {
    return RoundedAllocationSize(UnroundedSize(length));
  }

  bool UsesGlobalTable() const { return UsesGlobalTable(ptr()); }
  static bool UsesGlobalTable(const CompressedStackMapsPtr raw) {
    return UntaggedCompressedStackMaps::UsesTableBit::decode(
        raw->untag()->payload()->flags_and_size());
  }

  bool IsGlobalTable() const { return IsGlobalTable(ptr()); }
  static bool IsGlobalTable(const CompressedStackMapsPtr raw) {
    return UntaggedCompressedStackMaps::GlobalTableBit::decode(
        raw->untag()->payload()->flags_and_size());
  }

  static CompressedStackMapsPtr NewInlined(const void* payload, intptr_t size) {
    return New(payload, size, /*is_global_table=*/false,
               /*uses_global_table=*/false);
  }
  static CompressedStackMapsPtr NewUsingTable(const void* payload,
                                              intptr_t size) {
    return New(payload, size, /*is_global_table=*/false,
               /*uses_global_table=*/true);
  }

  static CompressedStackMapsPtr NewGlobalTable(const void* payload,
                                               intptr_t size) {
    return New(payload, size, /*is_global_table=*/true,
               /*uses_global_table=*/false);
  }

  class RawPayloadHandle {
   public:
    RawPayloadHandle() {}
    RawPayloadHandle(const RawPayloadHandle&) = default;
    RawPayloadHandle& operator=(const RawPayloadHandle&) = default;

    const UntaggedCompressedStackMaps::Payload* payload() const {
      return payload_;
    }
    bool IsNull() const { return payload_ == nullptr; }

    RawPayloadHandle& operator=(
        const UntaggedCompressedStackMaps::Payload* payload) {
      payload_ = payload;
      return *this;
    }

    RawPayloadHandle& operator=(const CompressedStackMaps& maps) {
      ASSERT(!maps.IsNull());
      payload_ = maps.untag()->payload();
      return *this;
    }

    RawPayloadHandle& operator=(CompressedStackMapsPtr maps) {
      ASSERT(maps != CompressedStackMaps::null());
      payload_ = maps.untag()->payload();
      return *this;
    }

    uintptr_t payload_size() const {
      return UntaggedCompressedStackMaps::SizeField::decode(
          payload()->flags_and_size());
    }
    const uint8_t* data() const { return payload()->data(); }

    bool UsesGlobalTable() const {
      return UntaggedCompressedStackMaps::UsesTableBit::decode(
          payload()->flags_and_size());
    }

    bool IsGlobalTable() const {
      return UntaggedCompressedStackMaps::GlobalTableBit::decode(
          payload()->flags_and_size());
    }

   private:
    const UntaggedCompressedStackMaps::Payload* payload_ = nullptr;
  };

  template <typename PayloadHandle>
  class Iterator {
   public:
    Iterator(const PayloadHandle& maps, const PayloadHandle& global_table)
        : maps_(maps),
          bits_container_(maps.UsesGlobalTable() ? global_table : maps) {
      ASSERT(!maps_.IsNull());
      ASSERT(!bits_container_.IsNull());
      ASSERT(!maps_.IsGlobalTable());
      ASSERT(!maps_.UsesGlobalTable() || bits_container_.IsGlobalTable());
    }

    Iterator(const Iterator& it)
        : maps_(it.maps_),
          bits_container_(it.bits_container_),
          next_offset_(it.next_offset_),
          current_pc_offset_(it.current_pc_offset_),
          current_global_table_offset_(it.current_global_table_offset_),
          current_spill_slot_bit_count_(it.current_spill_slot_bit_count_),
          current_non_spill_slot_bit_count_(it.current_spill_slot_bit_count_),
          current_bits_offset_(it.current_bits_offset_) {}

    // Loads the next entry from [maps_], if any. If [maps_] is the null value,
    // this always returns false.
    bool MoveNext() {
      if (next_offset_ >= maps_.payload_size()) {
        return false;
      }

      NoSafepointScope scope;
      ReadStream stream(maps_.data(), maps_.payload_size(), next_offset_);

      auto const pc_delta = stream.ReadLEB128();
      ASSERT(pc_delta <= (kMaxUint32 - current_pc_offset_));
      current_pc_offset_ += pc_delta;

      // Table-using CSMs have a table offset after the PC offset delta, whereas
      // the post-delta part of inlined entries has the same information as
      // global table entries.
      // See comments in UntaggedCompressedStackMaps for description of
      // encoding.
      if (maps_.UsesGlobalTable()) {
        current_global_table_offset_ = stream.ReadLEB128();
        ASSERT(current_global_table_offset_ < bits_container_.payload_size());

        // Since generally we only use entries in the GC and the GC only needs
        // the rest of the entry information if the PC offset matches, we lazily
        // load and cache the information stored in the global object when it is
        // actually requested.
        current_spill_slot_bit_count_ = -1;
        current_non_spill_slot_bit_count_ = -1;
        current_bits_offset_ = -1;

        next_offset_ = stream.Position();
      } else {
        current_spill_slot_bit_count_ = stream.ReadLEB128();
        ASSERT(current_spill_slot_bit_count_ >= 0);

        current_non_spill_slot_bit_count_ = stream.ReadLEB128();
        ASSERT(current_non_spill_slot_bit_count_ >= 0);

        const auto stackmap_bits =
            current_spill_slot_bit_count_ + current_non_spill_slot_bit_count_;
        const uintptr_t stackmap_size =
            Utils::RoundUp(stackmap_bits, kBitsPerByte) >> kBitsPerByteLog2;
        ASSERT(stackmap_size <= (maps_.payload_size() - stream.Position()));

        current_bits_offset_ = stream.Position();
        next_offset_ = current_bits_offset_ + stackmap_size;
      }

      return true;
    }

    // Finds the entry with the given PC offset starting at the current position
    // of the iterator. If [maps_] is the null value, this always returns false.
    bool Find(uint32_t pc_offset) {
      // We should never have an entry with a PC offset of 0 inside an
      // non-empty CSM, so fail.
      if (pc_offset == 0) return false;
      do {
        if (current_pc_offset_ >= pc_offset) break;
      } while (MoveNext());
      return current_pc_offset_ == pc_offset;
    }

    // Methods for accessing parts of an entry should not be called until
    // a successful MoveNext() or Find() call has been made.

    // Returns the PC offset of the loaded entry.
    uint32_t pc_offset() const {
      ASSERT(HasLoadedEntry());
      return current_pc_offset_;
    }

    // Returns the bit length of the loaded entry.
    intptr_t Length() const {
      EnsureFullyLoadedEntry();
      return current_spill_slot_bit_count_ + current_non_spill_slot_bit_count_;
    }
    // Returns the number of spill slot bits of the loaded entry.
    intptr_t SpillSlotBitCount() const {
      EnsureFullyLoadedEntry();
      return current_spill_slot_bit_count_;
    }
    // Returns whether the stack entry represented by the offset contains
    // a tagged object.
    bool IsObject(intptr_t bit_index) const {
      EnsureFullyLoadedEntry();
      ASSERT(bit_index >= 0 && bit_index < Length());
      const intptr_t byte_index = bit_index >> kBitsPerByteLog2;
      const intptr_t bit_remainder = bit_index & (kBitsPerByte - 1);
      uint8_t byte_mask = 1U << bit_remainder;
      const intptr_t byte_offset = current_bits_offset_ + byte_index;
      NoSafepointScope scope;
      return (bits_container_.data()[byte_offset] & byte_mask) != 0;
    }

   private:
    bool HasLoadedEntry() const { return next_offset_ > 0; }

    // Caches the corresponding values from the global table in the mutable
    // fields. We lazily load these as some clients only need the PC offset.
    void LazyLoadGlobalTableEntry() const {
      ASSERT(maps_.UsesGlobalTable());
      ASSERT(HasLoadedEntry());
      ASSERT(current_global_table_offset_ < bits_container_.payload_size());

      NoSafepointScope scope;
      ReadStream stream(bits_container_.data(), bits_container_.payload_size(),
                        current_global_table_offset_);

      current_spill_slot_bit_count_ = stream.ReadLEB128();
      ASSERT(current_spill_slot_bit_count_ >= 0);

      current_non_spill_slot_bit_count_ = stream.ReadLEB128();
      ASSERT(current_non_spill_slot_bit_count_ >= 0);

      const auto stackmap_bits = Length();
      const uintptr_t stackmap_size =
          Utils::RoundUp(stackmap_bits, kBitsPerByte) >> kBitsPerByteLog2;
      ASSERT(stackmap_size <=
             (bits_container_.payload_size() - stream.Position()));

      current_bits_offset_ = stream.Position();
    }

    void EnsureFullyLoadedEntry() const {
      ASSERT(HasLoadedEntry());
      if (current_spill_slot_bit_count_ < 0) {
        LazyLoadGlobalTableEntry();
        ASSERT(current_spill_slot_bit_count_ >= 0);
      }
    }

    const PayloadHandle& maps_;
    const PayloadHandle& bits_container_;

    uintptr_t next_offset_ = 0;
    uint32_t current_pc_offset_ = 0;
    // Only used when looking up non-PC information in the global table.
    uintptr_t current_global_table_offset_ = 0;
    // Marked as mutable as these fields may be updated with lazily loaded
    // values from the global table when their associated accessor is called,
    // but those values will never change for a given entry once loaded..
    mutable intptr_t current_spill_slot_bit_count_ = -1;
    mutable intptr_t current_non_spill_slot_bit_count_ = -1;
    mutable intptr_t current_bits_offset_ = -1;

    friend class StackMapEntry;
  };

  Iterator<CompressedStackMaps> iterator(Thread* thread) const;

  void WriteToBuffer(BaseTextBuffer* buffer, const char* separator) const;

 private:
  static CompressedStackMapsPtr New(const void* payload,
                                    intptr_t size,
                                    bool is_global_table,
                                    bool uses_global_table);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(CompressedStackMaps, Object);
  friend class Class;
};

class ExceptionHandlers : public Object {
 public:
  static constexpr intptr_t kInvalidPcOffset = 0;

  intptr_t num_entries() const;

  bool has_async_handler() const;
  void set_has_async_handler(bool value) const;

  void GetHandlerInfo(intptr_t try_index, ExceptionHandlerInfo* info) const;

  uword HandlerPCOffset(intptr_t try_index) const;
  intptr_t OuterTryIndex(intptr_t try_index) const;
  bool NeedsStackTrace(intptr_t try_index) const;
  bool IsGenerated(intptr_t try_index) const;

  void SetHandlerInfo(intptr_t try_index,
                      intptr_t outer_try_index,
                      uword handler_pc_offset,
                      bool needs_stacktrace,
                      bool has_catch_all,
                      bool is_generated) const;

  ArrayPtr GetHandledTypes(intptr_t try_index) const;
  void SetHandledTypes(intptr_t try_index, const Array& handled_types) const;
  bool HasCatchAll(intptr_t try_index) const;

  struct ArrayTraits {
    static intptr_t elements_start_offset() {
      return sizeof(UntaggedExceptionHandlers);
    }
    static constexpr intptr_t kElementSize = sizeof(ExceptionHandlerInfo);
  };

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedExceptionHandlers) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedExceptionHandlers, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    return RoundedAllocationSize(sizeof(UntaggedExceptionHandlers) +
                                 (len * sizeof(ExceptionHandlerInfo)));
  }

  static ExceptionHandlersPtr New(intptr_t num_handlers);
  static ExceptionHandlersPtr New(const Array& handled_types_data);

  // We would have a VisitPointers function here to traverse the
  // exception handler table to visit objects if any in the table.

 private:
  // Pick somewhat arbitrary maximum number of exception handlers
  // for a function. This value is used to catch potentially
  // malicious code.
  static constexpr intptr_t kMaxHandlers = 1024 * 1024;

  void set_handled_types_data(const Array& value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ExceptionHandlers, Object);
  friend class Class;
  friend class Object;
};

// A WeakSerializationReference (WSR) denotes a type of weak reference to a
// target object. In particular, objects that can only be reached from roots via
// WSR edges during serialization of AOT snapshots should not be serialized, but
// instead references to these objects should be replaced with a reference to
// the provided replacement object.
//
// Of course, the target object may still be serialized if there are paths to
// the object from the roots that do not go through one of these objects. In
// this case, references through WSRs are serialized as direct references to
// the target.
//
// Unfortunately a WSR is not a proxy for the original object, so WSRs may
// only currently be used with ObjectPtr fields. To ease this situation for
// fields that are normally a non-ObjectPtr type outside of the precompiler,
// use the following macros, which avoid the need to adjust other code to
// handle the WSR case:
//
// * WSR_*POINTER_FIELD() in raw_object.h (i.e., just append WSR_ to the
//   original field declaration).
// * PRECOMPILER_WSR_FIELD_DECLARATION() in object.h
// * PRECOMPILER_WSR_FIELD_DEFINITION() in object.cc
class WeakSerializationReference : public Object {
 public:
  ObjectPtr target() const { return TargetOf(ptr()); }
  static ObjectPtr TargetOf(const WeakSerializationReferencePtr obj) {
    return obj->untag()->target();
  }

  static ObjectPtr Unwrap(ObjectPtr obj) {
#if defined(DART_PRECOMPILER)
    if (obj->IsHeapObject() && obj->IsWeakSerializationReference()) {
      return TargetOf(static_cast<WeakSerializationReferencePtr>(obj));
    }
#endif
    return obj;
  }
  static ObjectPtr Unwrap(const Object& obj) { return Unwrap(obj.ptr()); }
  static ObjectPtr UnwrapIfTarget(ObjectPtr obj) { return Unwrap(obj); }
  static ObjectPtr UnwrapIfTarget(const Object& obj) { return Unwrap(obj); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedWeakSerializationReference));
  }

  // Returns an ObjectPtr as the target may not need wrapping (e.g., it
  // is guaranteed to be serialized).
  static ObjectPtr New(const Object& target, const Object& replacement);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(WeakSerializationReference, Object);

  ObjectPtr replacement() const { return untag()->replacement(); }

  friend class Class;
};

class WeakArray : public Object {
 public:
  intptr_t Length() const { return LengthOf(ptr()); }
  static inline intptr_t LengthOf(const WeakArrayPtr array);

  static intptr_t length_offset() {
    return OFFSET_OF(UntaggedWeakArray, length_);
  }
  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(UntaggedWeakArray, data);
  }
  static intptr_t element_offset(intptr_t index) {
    return OFFSET_OF_RETURNED_VALUE(UntaggedWeakArray, data) +
           kBytesPerElement * index;
  }
  static intptr_t index_at_offset(intptr_t offset_in_bytes) {
    intptr_t index = (offset_in_bytes - data_offset()) / kBytesPerElement;
    ASSERT(index >= 0);
    return index;
  }

  struct ArrayTraits {
    static intptr_t elements_start_offset() { return WeakArray::data_offset(); }

    static constexpr intptr_t kElementSize = kCompressedWordSize;
  };

  ObjectPtr At(intptr_t index) const { return untag()->element(index); }
  void SetAt(intptr_t index, const Object& value) const {
    untag()->set_element(index, value.ptr());
  }

  // Access to the array with acquire release semantics.
  ObjectPtr AtAcquire(intptr_t index) const {
    return untag()->element<std::memory_order_acquire>(index);
  }
  void SetAtRelease(intptr_t index, const Object& value) const {
    untag()->set_element<std::memory_order_release>(index, value.ptr());
  }

  static constexpr intptr_t kBytesPerElement = kCompressedWordSize;
  static constexpr intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static constexpr bool IsValidLength(intptr_t length) {
    return 0 <= length && length <= kMaxElements;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedWeakArray) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedWeakArray, data));
    return 0;
  }

  static constexpr intptr_t InstanceSize(intptr_t len) {
    return RoundedAllocationSize(sizeof(UntaggedWeakArray) +
                                 (len * kBytesPerElement));
  }

  static WeakArrayPtr New(intptr_t length, Heap::Space space = Heap::kNew);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(WeakArray, Object);
  friend class Class;
  friend class Object;
};

class Code : public Object {
 public:
  // When dual mapping, this returns the executable view.
  InstructionsPtr active_instructions() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return nullptr;
#else
    return untag()->active_instructions();
#endif
  }

  // When dual mapping, these return the executable view.
  InstructionsPtr instructions() const { return untag()->instructions(); }
  static InstructionsPtr InstructionsOf(const CodePtr code) {
    return code->untag()->instructions();
  }

  static intptr_t instructions_offset() {
    return OFFSET_OF(UntaggedCode, instructions_);
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  static intptr_t active_instructions_offset() {
    return OFFSET_OF(UntaggedCode, active_instructions_);
  }
#endif

  using EntryKind = CodeEntryKind;

  static const char* EntryKindToCString(EntryKind kind);
  static bool ParseEntryKind(const char* str, EntryKind* out);

  static intptr_t entry_point_offset(EntryKind kind = EntryKind::kNormal) {
    switch (kind) {
      case EntryKind::kNormal:
        return OFFSET_OF(UntaggedCode, entry_point_);
      case EntryKind::kUnchecked:
        return OFFSET_OF(UntaggedCode, unchecked_entry_point_);
      case EntryKind::kMonomorphic:
        return OFFSET_OF(UntaggedCode, monomorphic_entry_point_);
      case EntryKind::kMonomorphicUnchecked:
        return OFFSET_OF(UntaggedCode, monomorphic_unchecked_entry_point_);
      default:
        UNREACHABLE();
    }
  }

  ObjectPoolPtr object_pool() const { return untag()->object_pool(); }
  static intptr_t object_pool_offset() {
    return OFFSET_OF(UntaggedCode, object_pool_);
  }

  intptr_t pointer_offsets_length() const {
    return PtrOffBits::decode(untag()->state_bits_);
  }

  bool is_optimized() const {
    return OptimizedBit::decode(untag()->state_bits_);
  }
  void set_is_optimized(bool value) const;
  static bool IsOptimized(CodePtr code) {
    return Code::OptimizedBit::decode(code->untag()->state_bits_);
  }

  bool is_force_optimized() const {
    return ForceOptimizedBit::decode(untag()->state_bits_);
  }
  void set_is_force_optimized(bool value) const;

  bool is_alive() const { return AliveBit::decode(untag()->state_bits_); }
  void set_is_alive(bool value) const;

  bool is_discarded() const { return IsDiscarded(ptr()); }
  static bool IsDiscarded(const CodePtr code) {
    return DiscardedBit::decode(code->untag()->state_bits_);
  }
  void set_is_discarded(bool value) const;

  bool HasMonomorphicEntry() const { return HasMonomorphicEntry(ptr()); }
  static bool HasMonomorphicEntry(const CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    return code->untag()->entry_point_ !=
           code->untag()->monomorphic_entry_point_;
#else
    return Instructions::HasMonomorphicEntry(InstructionsOf(code));
#endif
  }

  // Returns the payload start of [instructions()].
  uword PayloadStart() const { return PayloadStartOf(ptr()); }
  static uword PayloadStartOf(const CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    if (IsUnknownDartCode(code)) return 0;
    const uword entry_offset = HasMonomorphicEntry(code)
                                   ? Instructions::kPolymorphicEntryOffsetAOT
                                   : 0;
    return EntryPointOf(code) - entry_offset;
#else
    return Instructions::PayloadStart(InstructionsOf(code));
#endif
  }

  // Returns the entry point of [instructions()].
  uword EntryPoint() const { return EntryPointOf(ptr()); }
  static uword EntryPointOf(const CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    return code->untag()->entry_point_;
#else
    return Instructions::EntryPoint(InstructionsOf(code));
#endif
  }

  static uword UncheckedEntryPointOf(const CodePtr code) {
    return code->untag()->unchecked_entry_point_;
  }

  // Returns the unchecked entry point of [instructions()].
  uword UncheckedEntryPoint() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return untag()->unchecked_entry_point_;
#else
    return EntryPoint() + untag()->unchecked_offset_;
#endif
  }
  // Returns the monomorphic entry point of [instructions()].
  uword MonomorphicEntryPoint() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return untag()->monomorphic_entry_point_;
#else
    return Instructions::MonomorphicEntryPoint(instructions());
#endif
  }
  // Returns the unchecked monomorphic entry point of [instructions()].
  uword MonomorphicUncheckedEntryPoint() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return untag()->monomorphic_unchecked_entry_point_;
#else
    return MonomorphicEntryPoint() + untag()->unchecked_offset_;
#endif
  }

  // Returns the size of [instructions()].
  uword Size() const { return PayloadSizeOf(ptr()); }
  static uword PayloadSizeOf(const CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    if (IsUnknownDartCode(code)) return kUwordMax;
    return code->untag()->instructions_length_;
#else
    return Instructions::Size(InstructionsOf(code));
#endif
  }

  ObjectPoolPtr GetObjectPool() const;
  // Returns whether the given PC address is in [instructions()].
  bool ContainsInstructionAt(uword addr) const {
    return ContainsInstructionAt(ptr(), addr);
  }

  // Returns whether the given PC address is in [InstructionsOf(code)].
  static bool ContainsInstructionAt(const CodePtr code, uword pc) {
    return UntaggedCode::ContainsPC(code, pc);
  }

  // Returns true if there is a debugger breakpoint set in this code object.
  bool HasBreakpoint() const;

  PcDescriptorsPtr pc_descriptors() const { return untag()->pc_descriptors(); }
  void set_pc_descriptors(const PcDescriptors& descriptors) const {
    ASSERT(descriptors.IsOld());
    untag()->set_pc_descriptors(descriptors.ptr());
  }

  CodeSourceMapPtr code_source_map() const {
    return untag()->code_source_map();
  }

  void set_code_source_map(const CodeSourceMap& code_source_map) const {
    ASSERT(code_source_map.IsOld());
    untag()->set_code_source_map(code_source_map.ptr());
  }

  // Array of DeoptInfo objects.
  ArrayPtr deopt_info_array() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return nullptr;
#else
    return untag()->deopt_info_array();
#endif
  }
  void set_deopt_info_array(const Array& array) const;

#if !defined(DART_PRECOMPILED_RUNTIME)
  intptr_t num_variables() const;
  void set_num_variables(intptr_t num_variables) const;
#endif

#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
  TypedDataPtr catch_entry_moves_maps() const;
  void set_catch_entry_moves_maps(const TypedData& maps) const;
#endif

  CompressedStackMapsPtr compressed_stackmaps() const {
    return untag()->compressed_stackmaps();
  }
  void set_compressed_stackmaps(const CompressedStackMaps& maps) const;

  enum CallKind {
    kPcRelativeCall = 1,
    kPcRelativeTTSCall = 2,
    kPcRelativeTailCall = 3,
    kCallViaCode = 4,
  };

  enum CallEntryPoint {
    kDefaultEntry,
    kUncheckedEntry,
  };

  enum SCallTableEntry {
    kSCallTableKindAndOffset = 0,
    kSCallTableCodeOrTypeTarget = 1,
    kSCallTableFunctionTarget = 2,
    kSCallTableEntryLength = 3,
  };

  enum class PoolAttachment {
    kAttachPool,
    kNotAttachPool,
  };

  class KindField : public BitField<intptr_t, CallKind, 0, 3> {};
  class EntryPointField
      : public BitField<intptr_t, CallEntryPoint, KindField::kNextBit, 1> {};
  class OffsetField
      : public BitField<intptr_t, intptr_t, EntryPointField::kNextBit, 26> {};

  void set_static_calls_target_table(const Array& value) const;
  ArrayPtr static_calls_target_table() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return nullptr;
#else
    return untag()->static_calls_target_table();
#endif
  }

  TypedDataPtr GetDeoptInfoAtPc(uword pc,
                                ICData::DeoptReasonId* deopt_reason,
                                uint32_t* deopt_flags) const;

  // Returns null if there is no static call at 'pc'.
  FunctionPtr GetStaticCallTargetFunctionAt(uword pc) const;
  // Aborts if there is no static call at 'pc'.
  void SetStaticCallTargetCodeAt(uword pc, const Code& code) const;
  void SetStubCallTargetCodeAt(uword pc, const Code& code) const;

  void Disassemble(DisassemblyFormatter* formatter = nullptr) const;

#if defined(INCLUDE_IL_PRINTER)
  class Comments : public ZoneAllocated, public CodeComments {
   public:
    static Comments& New(intptr_t count);

    intptr_t Length() const override;

    void SetPCOffsetAt(intptr_t idx, intptr_t pc_offset);
    void SetCommentAt(intptr_t idx, const String& comment);

    intptr_t PCOffsetAt(intptr_t idx) const override;
    const char* CommentAt(intptr_t idx) const override;

   private:
    explicit Comments(const Array& comments);

    // Layout of entries describing comments.
    enum {kPCOffsetEntry = 0,  // PC offset to a comment as a Smi.
          kCommentEntry,       // Comment text as a String.
          kNumberOfEntries};

    const Array& comments_;
    String& string_;

    friend class Code;

    DISALLOW_COPY_AND_ASSIGN(Comments);
  };

  const CodeComments& comments() const;
  void set_comments(const CodeComments& comments) const;
#endif  // defined(INCLUDE_IL_PRINTER)

  ObjectPtr return_address_metadata() const {
#if defined(PRODUCT)
    UNREACHABLE();
    return nullptr;
#else
    return untag()->return_address_metadata();
#endif
  }
  // Sets |return_address_metadata|.
  void SetPrologueOffset(intptr_t offset) const;
  // Returns -1 if no prologue offset is available.
  intptr_t GetPrologueOffset() const;

  ArrayPtr inlined_id_to_function() const;
  void set_inlined_id_to_function(const Array& value) const;

  // Provides the call stack at the given pc offset, with the top-of-stack in
  // the last element and the root function (this) as the first element, along
  // with the corresponding source positions. Note the token position for each
  // function except the top-of-stack is the position of the call to the next
  // function. The stack will be empty if we lack the metadata to produce it,
  // which happens for stub code.
  // The pc offset is interpreted as an instruction address (as needed by the
  // disassembler or the top frame of a profiler sample).
  void GetInlinedFunctionsAtInstruction(
      intptr_t pc_offset,
      GrowableArray<const Function*>* functions,
      GrowableArray<TokenPosition>* token_positions) const;
  // Same as above, except the pc is interpreted as a return address (as needed
  // for a stack trace or the bottom frames of a profiler sample).
  void GetInlinedFunctionsAtReturnAddress(
      intptr_t pc_offset,
      GrowableArray<const Function*>* functions,
      GrowableArray<TokenPosition>* token_positions) const {
    GetInlinedFunctionsAtInstruction(pc_offset - 1, functions, token_positions);
  }

  NOT_IN_PRODUCT(void PrintJSONInlineIntervals(JSONObject* object) const);
  void DumpInlineIntervals() const;
  void DumpSourcePositions(bool relative_addresses = false) const;

  LocalVarDescriptorsPtr var_descriptors() const {
#if defined(PRODUCT)
    UNREACHABLE();
    return nullptr;
#else
    return untag()->var_descriptors();
#endif
  }
  void set_var_descriptors(const LocalVarDescriptors& value) const {
#if defined(PRODUCT)
    UNREACHABLE();
#else
    ASSERT(value.IsOld());
    untag()->set_var_descriptors(value.ptr());
#endif
  }

  // Will compute local var descriptors if necessary.
  LocalVarDescriptorsPtr GetLocalVarDescriptors() const;

  ExceptionHandlersPtr exception_handlers() const {
    return untag()->exception_handlers();
  }
  void set_exception_handlers(const ExceptionHandlers& handlers) const {
    ASSERT(handlers.IsOld());
    untag()->set_exception_handlers(handlers.ptr());
  }

  // WARNING: function() returns the owner which is not guaranteed to be
  // a Function. It is up to the caller to guarantee it isn't a stub, class,
  // or something else.
  // TODO(turnidge): Consider dropping this function and making
  // everybody use owner().  Currently this function is misused - even
  // while generating the snapshot.
  FunctionPtr function() const {
    ASSERT(IsFunctionCode());
    return Function::RawCast(owner());
  }

  ObjectPtr owner() const {
    return WeakSerializationReference::Unwrap(untag()->owner());
  }
  void set_owner(const Object& owner) const;

  classid_t OwnerClassId() const { return OwnerClassIdOf(ptr()); }
  static classid_t OwnerClassIdOf(CodePtr raw) {
    ObjectPtr owner = WeakSerializationReference::Unwrap(raw->untag()->owner());
    if (!owner->IsHeapObject()) {
      return RawSmiValue(static_cast<SmiPtr>(owner));
    }
    return owner->GetClassId();
  }

  static intptr_t owner_offset() { return OFFSET_OF(UntaggedCode, owner_); }

  // We would have a VisitPointers function here to traverse all the
  // embedded objects in the instructions using pointer_offsets.

  static constexpr intptr_t kBytesPerElement =
      sizeof(reinterpret_cast<UntaggedCode*>(kOffsetOfPtr)->data()[0]);
  static constexpr intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  struct ArrayTraits {
    static intptr_t elements_start_offset() { return sizeof(UntaggedCode); }
    static constexpr intptr_t kElementSize = kBytesPerElement;
  };

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedCode) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedCode, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(UntaggedCode) +
                                 (len * kBytesPerElement));
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  // Finalizes the generated code, by generating various kinds of metadata (e.g.
  // stack maps, pc descriptors, ...) and attach them to a newly generated
  // [Code] object.
  //
  // If Code::PoolAttachment::kAttachPool is specified for [pool_attachment]
  // then a new [ObjectPool] will be attached to the code object as well.
  // Otherwise the caller is responsible for doing this via
  // `Object::set_object_pool()`.
  static CodePtr FinalizeCode(FlowGraphCompiler* compiler,
                              compiler::Assembler* assembler,
                              PoolAttachment pool_attachment,
                              bool optimized,
                              CodeStatistics* stats);

  // Notifies all active [CodeObserver]s.
  static void NotifyCodeObservers(const Code& code, bool optimized);
  static void NotifyCodeObservers(const Function& function,
                                  const Code& code,
                                  bool optimized);
  static void NotifyCodeObservers(const char* name,
                                  const Code& code,
                                  bool optimized);

  // Calls [FinalizeCode] and also notifies [CodeObserver]s.
  static CodePtr FinalizeCodeAndNotify(const Function& function,
                                       FlowGraphCompiler* compiler,
                                       compiler::Assembler* assembler,
                                       PoolAttachment pool_attachment,
                                       bool optimized = false,
                                       CodeStatistics* stats = nullptr);
  static CodePtr FinalizeCodeAndNotify(const char* name,
                                       FlowGraphCompiler* compiler,
                                       compiler::Assembler* assembler,
                                       PoolAttachment pool_attachment,
                                       bool optimized = false,
                                       CodeStatistics* stats = nullptr);

#endif
  static CodePtr FindCode(uword pc, int64_t timestamp);

  int32_t GetPointerOffsetAt(int index) const {
    NoSafepointScope no_safepoint;
    return *PointerOffsetAddrAt(index);
  }
  TokenPosition GetTokenIndexOfPC(uword pc) const;

  // Find pc, return 0 if not found.
  uword GetPcForDeoptId(intptr_t deopt_id,
                        UntaggedPcDescriptors::Kind kind) const;
  intptr_t GetDeoptIdForOsr(uword pc) const;

  uint32_t Hash() const;
  const char* Name() const;
  const char* QualifiedName(const NameFormattingParams& params) const;

  int64_t compile_timestamp() const {
#if defined(PRODUCT)
    return 0;
#else
    return untag()->compile_timestamp_;
#endif
  }

  bool IsStubCode() const;
  bool IsAllocationStubCode() const;
  bool IsTypeTestStubCode() const;
  bool IsFunctionCode() const;

  // Returns true if this Code object represents
  // Dart function code without any additional information.
  bool IsUnknownDartCode() const { return IsUnknownDartCode(ptr()); }
  static bool IsUnknownDartCode(CodePtr code);

  void DisableDartCode() const;

  void DisableStubCode(bool is_cls_parameterized) const;

  void Enable() const {
    if (!IsDisabled()) return;
    ResetActiveInstructions();
  }

  bool IsDisabled() const { return IsDisabled(ptr()); }
  static bool IsDisabled(CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return false;
#else
    return code->untag()->instructions() !=
           code->untag()->active_instructions();
#endif
  }

  void set_object_pool(ObjectPoolPtr object_pool) const {
    untag()->set_object_pool(object_pool);
  }

 private:
  void set_state_bits(intptr_t bits) const;

  friend class UntaggedObject;  // For UntaggedObject::SizeFromClass().
  friend class UntaggedCode;
  friend struct RelocatorTestHelper;

  enum {
    kOptimizedBit = 0,
    kForceOptimizedBit = 1,
    kAliveBit = 2,
    kDiscardedBit = 3,
    kPtrOffBit = 4,
    kPtrOffSize = kBitsPerInt32 - kPtrOffBit,
  };

  class OptimizedBit : public BitField<int32_t, bool, kOptimizedBit, 1> {};

  // Force-optimized is true if the Code was generated for a function with
  // Function::ForceOptimize().
  class ForceOptimizedBit
      : public BitField<int32_t, bool, kForceOptimizedBit, 1> {};

  class AliveBit : public BitField<int32_t, bool, kAliveBit, 1> {};

  // Set by precompiler if this Code object doesn't contain
  // useful information besides instructions and compressed stack map.
  // Such objects are serialized in a shorter form and replaced with
  // StubCode::UnknownDartCode() during snapshot deserialization.
  class DiscardedBit : public BitField<int32_t, bool, kDiscardedBit, 1> {};

  class PtrOffBits
      : public BitField<int32_t, intptr_t, kPtrOffBit, kPtrOffSize> {};

  static constexpr intptr_t kEntrySize = sizeof(int32_t);  // NOLINT

  void set_compile_timestamp(int64_t timestamp) const {
#if defined(PRODUCT)
    UNREACHABLE();
#else
    StoreNonPointer(&untag()->compile_timestamp_, timestamp);
#endif
  }

  // Initializes the cached entrypoint addresses in [code] as calculated
  // from [instructions] and [unchecked_offset].
  static void InitializeCachedEntryPointsFrom(CodePtr code,
                                              InstructionsPtr instructions,
                                              uint32_t unchecked_offset);

  // Sets [active_instructions_] to [instructions] and updates the cached
  // entry point addresses.
  void SetActiveInstructions(const Instructions& instructions,
                             uint32_t unchecked_offset) const;
  void SetActiveInstructionsSafe(const Instructions& instructions,
                                 uint32_t unchecked_offset) const;

  // Resets [active_instructions_] to its original value of [instructions_] and
  // updates the cached entry point addresses to match.
  void ResetActiveInstructions() const;

  void set_instructions(const Instructions& instructions) const {
    ASSERT(Thread::Current()->IsDartMutatorThread() || !is_alive());
    untag()->set_instructions(instructions.ptr());
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  void set_unchecked_offset(uword offset) const {
    StoreNonPointer(&untag()->unchecked_offset_, offset);
  }
#endif

  // Returns the unchecked entry point offset for [instructions_].
  uint32_t UncheckedEntryPointOffset() const {
    return UncheckedEntryPointOffsetOf(ptr());
  }
  static uint32_t UncheckedEntryPointOffsetOf(CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    return code->untag()->unchecked_offset_;
#endif
  }

  void set_pointer_offsets_length(intptr_t value) {
    // The number of fixups is limited to 1-billion.
    ASSERT(Utils::IsUint(30, value));
    set_state_bits(PtrOffBits::update(value, untag()->state_bits_));
  }
  int32_t* PointerOffsetAddrAt(int index) const {
    ASSERT(index >= 0);
    ASSERT(index < pointer_offsets_length());
    // TODO(iposva): Unit test is missing for this functionality.
    return &UnsafeMutableNonPointer(untag()->data())[index];
  }
  void SetPointerOffsetAt(int index, int32_t offset_in_instructions) {
    NoSafepointScope no_safepoint;
    *PointerOffsetAddrAt(index) = offset_in_instructions;
  }

  intptr_t BinarySearchInSCallTable(uword pc) const;
  static CodePtr LookupCodeInIsolateGroup(IsolateGroup* isolate_group,
                                          uword pc);

  // New is a private method as RawInstruction and RawCode objects should
  // only be created using the Code::FinalizeCode method. This method creates
  // the RawInstruction and RawCode objects, sets up the pointer offsets
  // and links the two in a GC safe manner.
  static CodePtr New(intptr_t pointer_offsets_length);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Code, Object);
  friend class Class;
  friend class CodeTestHelper;
  friend class StubCode;     // for set_object_pool
  friend class Precompiler;  // for set_object_pool
  friend class FunctionSerializationCluster;
  friend class CodeSerializationCluster;
  friend class CodeDeserializationCluster;
  friend class Deserializer;           // for InitializeCachedEntryPointsFrom
  friend class StubCode;               // for set_object_pool
  friend class MegamorphicCacheTable;  // for set_object_pool
  friend class CodePatcher;            // for set_instructions
  friend class ProgramVisitor;         // for set_instructions
  // So that the UntaggedFunction pointer visitor can determine whether code the
  // function points to is optimized.
  friend class UntaggedFunction;
  friend class CallSiteResetter;
  friend class CodeKeyValueTrait;  // for UncheckedEntryPointOffset
  friend class InstanceCall;       // for StorePointerUnaligned
  friend class StaticCall;         // for StorePointerUnaligned
};

class Context : public Object {
 public:
  ContextPtr parent() const { return untag()->parent(); }
  void set_parent(const Context& parent) const {
    untag()->set_parent(parent.ptr());
  }
  static intptr_t parent_offset() {
    return OFFSET_OF(UntaggedContext, parent_);
  }

  intptr_t num_variables() const { return untag()->num_variables_; }
  static intptr_t num_variables_offset() {
    return OFFSET_OF(UntaggedContext, num_variables_);
  }
  static intptr_t NumVariables(const ContextPtr context) {
    return context->untag()->num_variables_;
  }

  ObjectPtr At(intptr_t context_index) const {
    return untag()->element(context_index);
  }
  inline void SetAt(intptr_t context_index, const Object& value) const;

  intptr_t GetLevel() const;

  void Dump(int indent = 0) const;

  static constexpr intptr_t kBytesPerElement = kCompressedWordSize;
  static constexpr intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  struct ArrayTraits {
    static intptr_t elements_start_offset() { return sizeof(UntaggedContext); }
    static constexpr intptr_t kElementSize = kBytesPerElement;
  };

  static intptr_t variable_offset(intptr_t context_index) {
    return OFFSET_OF_RETURNED_VALUE(UntaggedContext, data) +
           (kBytesPerElement * context_index);
  }

  static bool IsValidLength(intptr_t len) {
    return 0 <= len && len <= compiler::target::Context::kMaxElements;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedContext) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedContext, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(IsValidLength(len));
    return RoundedAllocationSize(sizeof(UntaggedContext) +
                                 (len * kBytesPerElement));
  }

  static ContextPtr New(intptr_t num_variables, Heap::Space space = Heap::kNew);

 private:
  void set_num_variables(intptr_t num_variables) const {
    StoreNonPointer(&untag()->num_variables_, num_variables);
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Context, Object);
  friend class Class;
  friend class Object;
};

// The ContextScope class makes it possible to delay the compilation of a local
// function until it is invoked. A ContextScope instance collects the local
// variables that are referenced by the local function to be compiled and that
// belong to the outer scopes, that is, to the local scopes of (possibly nested)
// functions enclosing the local function. Each captured variable is represented
// by its token position in the source, its name, its type, its allocation index
// in the context, and its context level. The function nesting level and loop
// nesting level are not preserved, since they are only used until the context
// level is assigned. In addition the ContextScope has a field 'is_implicit'
// which is true if the ContextScope was created for an implicit closure.
class ContextScope : public Object {
 public:
  intptr_t num_variables() const { return untag()->num_variables_; }

  TokenPosition TokenIndexAt(intptr_t scope_index) const;
  void SetTokenIndexAt(intptr_t scope_index, TokenPosition token_pos) const;

  TokenPosition DeclarationTokenIndexAt(intptr_t scope_index) const;
  void SetDeclarationTokenIndexAt(intptr_t scope_index,
                                  TokenPosition declaration_token_pos) const;

  StringPtr NameAt(intptr_t scope_index) const;
  void SetNameAt(intptr_t scope_index, const String& name) const;

  void ClearFlagsAt(intptr_t scope_index) const;

  intptr_t LateInitOffsetAt(intptr_t scope_index) const;
  void SetLateInitOffsetAt(intptr_t scope_index,
                           intptr_t late_init_offset) const;

#define DECLARE_FLAG_ACCESSORS(Name)                                           \
  bool Is##Name##At(intptr_t scope_index) const;                               \
  void SetIs##Name##At(intptr_t scope_index, bool value) const;

  CONTEXT_SCOPE_VARIABLE_DESC_FLAG_LIST(DECLARE_FLAG_ACCESSORS)
#undef DECLARE_FLAG_ACCESSORS

  AbstractTypePtr TypeAt(intptr_t scope_index) const;
  void SetTypeAt(intptr_t scope_index, const AbstractType& type) const;

  intptr_t CidAt(intptr_t scope_index) const;
  void SetCidAt(intptr_t scope_index, intptr_t cid) const;

  intptr_t ContextIndexAt(intptr_t scope_index) const;
  void SetContextIndexAt(intptr_t scope_index, intptr_t context_index) const;

  intptr_t ContextLevelAt(intptr_t scope_index) const;
  void SetContextLevelAt(intptr_t scope_index, intptr_t context_level) const;

  intptr_t KernelOffsetAt(intptr_t scope_index) const;
  void SetKernelOffsetAt(intptr_t scope_index, intptr_t kernel_offset) const;

  static constexpr intptr_t kBytesPerElement =
      sizeof(UntaggedContextScope::VariableDesc);
  static constexpr intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  struct ArrayTraits {
    static intptr_t elements_start_offset() {
      return sizeof(UntaggedContextScope);
    }
    static constexpr intptr_t kElementSize = kBytesPerElement;
  };

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedContextScope) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedContextScope, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(UntaggedContextScope) +
                                 (len * kBytesPerElement));
  }

  static ContextScopePtr New(intptr_t num_variables, bool is_implicit);

 private:
  void set_num_variables(intptr_t num_variables) const {
    StoreNonPointer(&untag()->num_variables_, num_variables);
  }

  void set_is_implicit(bool is_implicit) const {
    StoreNonPointer(&untag()->is_implicit_, is_implicit);
  }

  const UntaggedContextScope::VariableDesc* VariableDescAddr(
      intptr_t index) const {
    ASSERT((index >= 0) && (index < num_variables()));
    return untag()->VariableDescAddr(index);
  }

  bool GetFlagAt(intptr_t scope_index, intptr_t bit_index) const;
  void SetFlagAt(intptr_t scope_index, intptr_t bit_index, bool value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ContextScope, Object);
  friend class Class;
  friend class Object;
};

// Class of special sentinel values:
// - Object::sentinel() is a value that cannot be produced by Dart code.
// It can be used to mark special values, for example to distinguish
// "uninitialized" fields.
// - Object::transition_sentinel() is a value marking that we are transitioning
// from sentinel, e.g., computing a field value. Used to detect circular
// initialization of static fields.
// - Object::unknown_constant() and Object::non_constant() are optimizing
// compiler's constant propagation constants.
// - Object::optimized_out() result from deopt environment pruning or failure
// to capture variables in a closure's context
class Sentinel : public Object {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedSentinel));
  }

  static SentinelPtr New();

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Sentinel, Object);
  friend class Class;
  friend class Object;
};

class MegamorphicCache : public CallSiteData {
 public:
  static constexpr intptr_t kInitialCapacity = 16;
  static constexpr intptr_t kSpreadFactor = 7;
  static constexpr double kLoadFactor = 0.50;

  enum EntryType {
    kClassIdIndex,
    kTargetFunctionIndex,
    kEntryLength,
  };

  ArrayPtr buckets() const;
  void set_buckets(const Array& buckets) const;

  intptr_t mask() const;
  void set_mask(intptr_t mask) const;

  intptr_t filled_entry_count() const;
  void set_filled_entry_count(intptr_t num) const;

  static intptr_t buckets_offset() {
    return OFFSET_OF(UntaggedMegamorphicCache, buckets_);
  }
  static intptr_t mask_offset() {
    return OFFSET_OF(UntaggedMegamorphicCache, mask_);
  }
  static intptr_t arguments_descriptor_offset() {
    return OFFSET_OF(UntaggedMegamorphicCache, args_descriptor_);
  }

  static MegamorphicCachePtr New(const String& target_name,
                                 const Array& arguments_descriptor);

  void EnsureContains(const Smi& class_id, const Object& target) const;
  ObjectPtr Lookup(const Smi& class_id) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedMegamorphicCache));
  }

 private:
  friend class Class;
  friend class MegamorphicCacheTable;
  friend class ProgramVisitor;

  static MegamorphicCachePtr New();

  // The caller must hold IsolateGroup::type_feedback_mutex().
  void InsertLocked(const Smi& class_id, const Object& target) const;
  void EnsureCapacityLocked() const;
  ObjectPtr LookupLocked(const Smi& class_id) const;

  void InsertEntryLocked(const Smi& class_id, const Object& target) const;

  static inline void SetEntry(const Array& array,
                              intptr_t index,
                              const Smi& class_id,
                              const Object& target);

  static inline ObjectPtr GetClassId(const Array& array, intptr_t index);
  static inline ObjectPtr GetTargetFunction(const Array& array, intptr_t index);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(MegamorphicCache, CallSiteData);
};

class SubtypeTestCache : public Object {
 public:
  // The contents of the backing array storage is a number of entry tuples.
  // Any entry that is unoccupied has the null value as its first component.
  //
  // If the cache is linear, the entries can be accessed in a linear fashion:
  // all occupied entries come first, followed by at least one unoccupied
  // entry to mark the end of the cache. Guaranteeing at least one unoccupied
  // entry avoids the need for a length check when iterating over the contents
  // of the linear cache in stubs.
  //
  // If the cache is hash-based, the array is instead treated as a hash table
  // probed by using a hash value derived from the inputs.

  // The tuple of values stored in a given entry.
  //
  // Note that occupied entry contents are never modified. That means reading a
  // non-null instance cid or signature means the rest of the entry can be
  // loaded without worrying about concurrent modification. Thus, we always set
  // the instance cid or signature last when making an occupied entry.
  //
  // Also note that each STC, when created, has a set number of used inputs.
  // The value of any unused input is unspecified, so for example, if the
  // STC only uses 3 inputs, then no assumptions can be made about the value
  // stored in the instantiator type arguments slot.
  enum Entries {
    kInstanceCidOrSignature = 0,
    kInstanceTypeArguments = 1,
    kInstantiatorTypeArguments = 2,
    kFunctionTypeArguments = 3,
    kInstanceParentFunctionTypeArguments = 4,
    kInstanceDelayedFunctionTypeArguments = 5,
    kDestinationType = 6,
    kTestResult = 7,
    kTestEntryLength = 8,
  };

  // Assumes only one non-input entry in the array, kTestResult.
  static_assert(kInstanceCidOrSignature == 0 &&
                    kDestinationType + 1 == kTestResult &&
                    kTestResult + 1 == kTestEntryLength,
                "Need to adjust number of max inputs");
  static constexpr intptr_t kMaxInputs = kTestResult;

  // Returns the number of occupied entries stored in the cache.
  intptr_t NumberOfChecks() const;

  // Retrieves the number of entries (occupied or unoccupied) in the cache.
  intptr_t NumEntries() const;

  // Adds a check, returning the index of the new entry in the cache.
  intptr_t AddCheck(
      const Object& instance_class_id_or_signature,
      const AbstractType& destination_type,
      const TypeArguments& instance_type_arguments,
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      const TypeArguments& instance_parent_function_type_arguments,
      const TypeArguments& instance_delayed_type_arguments,
      const Bool& test_result) const;
  void GetCheck(intptr_t ix,
                Object* instance_class_id_or_signature,
                AbstractType* destination_type,
                TypeArguments* instance_type_arguments,
                TypeArguments* instantiator_type_arguments,
                TypeArguments* function_type_arguments,
                TypeArguments* instance_parent_function_type_arguments,
                TypeArguments* instance_delayed_type_arguments,
                Bool* test_result) const;

  // Like GetCheck(), but does not require the subtype test cache mutex and so
  // may see an outdated view of the cache.
  void GetCurrentCheck(intptr_t ix,
                       Object* instance_class_id_or_signature,
                       AbstractType* destination_type,
                       TypeArguments* instance_type_arguments,
                       TypeArguments* instantiator_type_arguments,
                       TypeArguments* function_type_arguments,
                       TypeArguments* instance_parent_function_type_arguments,
                       TypeArguments* instance_delayed_type_arguments,
                       Bool* test_result) const;

  // Like GetCheck(), but returns the contents of the first occupied entry
  // at or after the initial contents of [ix]. Returns whether an occupied entry
  // was found, and if an occupied entry was found, [ix] is updated to the entry
  // index following the occupied entry.
  bool GetNextCheck(intptr_t* ix,
                    Object* instance_class_id_or_signature,
                    AbstractType* destination_type,
                    TypeArguments* instance_type_arguments,
                    TypeArguments* instantiator_type_arguments,
                    TypeArguments* function_type_arguments,
                    TypeArguments* instance_parent_function_type_arguments,
                    TypeArguments* instance_delayed_type_arguments,
                    Bool* test_result) const;

  // Returns whether all the elements of an existing cache entry, excluding
  // the result, match the non-pointer arguments. The pointer arguments are
  // out parameters as follows:
  //
  // If [index] is not nullptr, then it is set to the matching entry's index.
  // If [result] is not nullptr, then it is set to the matching entry's result.
  //
  // If called without the STC mutex lock, may return outdated information:
  // * May return a false negative if the entry was added concurrently.
  // * The [index] field may be invalid for the STC if the backing array is
  //   grown concurrently and the new backing array is hash-based.
  bool HasCheck(const Object& instance_class_id_or_signature,
                const AbstractType& destination_type,
                const TypeArguments& instance_type_arguments,
                const TypeArguments& instantiator_type_arguments,
                const TypeArguments& function_type_arguments,
                const TypeArguments& instance_parent_function_type_arguments,
                const TypeArguments& instance_delayed_type_arguments,
                intptr_t* index,
                Bool* result) const;

  // Writes the cache entry at index [index] to the given text buffer.
  //
  // The output is comma separated on a single line if [line_prefix] is nullptr,
  // otherwise line breaks followed by [line_prefix] is used as a separator.
  void WriteEntryToBuffer(Zone* zone,
                          BaseTextBuffer* buffer,
                          intptr_t index,
                          const char* line_prefix = nullptr) const;

  // Writes the contents of this SubtypeTestCache to the given text buffer.
  void WriteToBuffer(Zone* zone,
                     BaseTextBuffer* buffer,
                     const char* line_prefix = nullptr) const;

  void Reset() const;

  // Tests that [other] contains the same entries in the same order.
  bool Equals(const SubtypeTestCache& other) const;

  // Returns whether the cache backed by the given storage is hash-based.
  bool IsHash() const;

  // Creates a separate copy of the current STC contents.
  SubtypeTestCachePtr Copy(Thread* thread) const;

  static SubtypeTestCachePtr New(intptr_t num_inputs);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedSubtypeTestCache));
  }

  static intptr_t cache_offset() {
    return OFFSET_OF(UntaggedSubtypeTestCache, cache_);
  }
  ArrayPtr cache() const;

  static intptr_t num_inputs_offset() {
    return OFFSET_OF(UntaggedSubtypeTestCache, num_inputs_);
  }
  intptr_t num_inputs() const { return untag()->num_inputs_; }

  intptr_t num_occupied() const { return untag()->num_occupied_; }

  // The maximum number of occupied entries for a linear subtype test cache
  // before swapping to a hash table-based cache. Exposed publicly for tests.
#if defined(TARGET_ARCH_IA32)
  // We don't generate hash cache probing in the stub on IA32, so larger caches
  // force runtime checks.
  static constexpr intptr_t kMaxLinearCacheEntries = 100;
#else
  static constexpr intptr_t kMaxLinearCacheEntries = 30;
#endif

  // Whether the entry at the given index in the cache is occupied. Exposed
  // publicly for tests.
  bool IsOccupied(intptr_t index) const;

  // Returns the number of inputs needed to cache entries for the given type.
  static intptr_t UsedInputsForType(const AbstractType& type);

  // Given a minimum entry count, calculates an entry count that won't force
  // additional allocation but minimizes the number of unoccupied entries.
  // Used to calculate an appropriate value for FLAG_max_subtype_cache_entries.
  static constexpr intptr_t MaxEntriesForCacheAllocatedFor(intptr_t count) {
    // If the cache would be linear, just return the count unchanged.
    if (count <= kMaxLinearCacheEntries) return count;
    intptr_t allocated_entries = Utils::RoundUpToPowerOfTwo(count);
    if (LoadFactor(count, allocated_entries) >= kMaxLoadFactor) {
      allocated_entries *= 2;
    }
    const intptr_t max_entries =
        static_cast<intptr_t>(kMaxLoadFactor * allocated_entries);
    assert(LoadFactor(max_entries, allocated_entries) < kMaxLoadFactor);
    assert(max_entries >= count);
    return max_entries;
  }

 private:
  static constexpr double LoadFactor(intptr_t occupied, intptr_t capacity) {
    return occupied / static_cast<double>(capacity);
  }

  // Retrieves the number of entries (occupied or unoccupied) in a cache
  // backed by the given array.
  static intptr_t NumEntries(const Array& array);

  // Returns whether the cache backed by the given storage is linear.
  static bool IsLinear(const Array& array) { return !IsHash(array); }

  // Returns whether the cache backed by the given storage is hash-based.
  static bool IsHash(const Array& array);

  struct KeyLocation {
    // The entry index if [present] is true, otherwise where the entry would
    // be located if added afterwards without any intermediate additions.
    intptr_t entry;
    bool present;  // Whether an entry already exists in the cache.
  };

  // If a cache entry in the given array contains the given inputs, returns a
  // KeyLocation with the index of the entry and true. Otherwise, returns a
  // KeyLocation with the index that would be used if the instantiation for the
  // given type arguments is added and false.
  //
  // If called without the STC mutex lock, may return outdated information:
  // * The [present] field may be a false negative if the entry was added
  //   concurrently.
  static KeyLocation FindKeyOrUnused(
      const Array& array,
      intptr_t num_inputs,
      const Object& instance_class_id_or_signature,
      const AbstractType& destination_type,
      const TypeArguments& instance_type_arguments,
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      const TypeArguments& instance_parent_function_type_arguments,
      const TypeArguments& instance_delayed_type_arguments);

  // If the given array can contain the requested number of entries, returns
  // the same array and sets [was_grown] to false.
  //
  // If the given array cannot contain the requested number of entries,
  // returns a new array that can and which contains all the entries of the
  // given array and sets [was_grown] to true.
  ArrayPtr EnsureCapacity(Zone* zone,
                          const Array& array,
                          intptr_t new_capacity,
                          bool* was_grown) const;

 public:  // Used in the StubCodeCompiler.
  // The maximum size of the array backing a linear cache. All hash based
  // caches are guaranteed to have sizes larger than this.
  static constexpr intptr_t kMaxLinearCacheSize =
      (kMaxLinearCacheEntries + 1) * kTestEntryLength;

 private:
  // The initial number of entries used when converting from a linear to
  // a hash-based cache.
  static constexpr intptr_t kNumInitialHashCacheEntries =
      Utils::RoundUpToPowerOfTwo(2 * kMaxLinearCacheEntries);
  static_assert(Utils::IsPowerOfTwo(kNumInitialHashCacheEntries),
                "number of hash-based cache entries must be a power of two");

  // The max load factor allowed in hash-based caches.
  static constexpr double kMaxLoadFactor = 0.71;

  void set_cache(const Array& value) const;
  void set_num_occupied(intptr_t value) const;

  // Like GetCurrentCheck, but takes the backing storage array.
  static void GetCheckFromArray(
      const Array& array,
      intptr_t num_inputs,
      intptr_t ix,
      Object* instance_class_id_or_signature,
      AbstractType* destination_type,
      TypeArguments* instance_type_arguments,
      TypeArguments* instantiator_type_arguments,
      TypeArguments* function_type_arguments,
      TypeArguments* instance_parent_function_type_arguments,
      TypeArguments* instance_delayed_type_arguments,
      Bool* test_result);

  // Like WriteEntryToBuffer(), but does not require the subtype test cache
  // mutex and so may see an incorrect view of the cache if there are concurrent
  // modifications.
  void WriteCurrentEntryToBuffer(Zone* zone,
                                 BaseTextBuffer* buffer,
                                 intptr_t index,
                                 const char* line_prefix = nullptr) const;

  // Like WriteToBuffer(), but does not require the subtype test cache mutex and
  // so may see an incorrect view of the cache if there are concurrent
  // modifications.
  void WriteToBufferUnlocked(Zone* zone,
                             BaseTextBuffer* buffer,
                             const char* line_prefix = nullptr) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(SubtypeTestCache, Object);
  friend class Class;
  friend class FieldInvalidator;
  friend class VMSerializationRoots;
  friend class VMDeserializationRoots;
};

class LoadingUnit : public Object {
 public:
  static constexpr intptr_t kIllegalId = 0;
  COMPILE_ASSERT(kIllegalId == WeakTable::kNoValue);
  static constexpr intptr_t kRootId = 1;

  static LoadingUnitPtr New();

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedLoadingUnit));
  }

  static intptr_t LoadingUnitOf(const Function& function);
  static intptr_t LoadingUnitOf(const Code& code);

  LoadingUnitPtr parent() const;
  void set_parent(const LoadingUnit& value) const;

  ArrayPtr base_objects() const;
  void set_base_objects(const Array& value) const;

  intptr_t id() const { return untag()->id_; }
  void set_id(intptr_t id) const { StoreNonPointer(&untag()->id_, id); }

  // True once the VM deserializes this unit's snapshot.
  bool loaded() const { return untag()->loaded_; }
  void set_loaded(bool value) const {
    StoreNonPointer(&untag()->loaded_, value);
  }

  // True once the VM invokes the embedder's deferred load callback until the
  // embedder calls Dart_DeferredLoadComplete[Error].
  bool load_outstanding() const { return untag()->load_outstanding_; }
  void set_load_outstanding(bool value) const {
    StoreNonPointer(&untag()->load_outstanding_, value);
  }

  ObjectPtr IssueLoad() const;
  ObjectPtr CompleteLoad(const String& error_message,
                         bool transient_error) const;

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(LoadingUnit, Object);
  friend class Class;
};

class Error : public Object {
 public:
  virtual const char* ToErrorCString() const;

 private:
  HEAP_OBJECT_IMPLEMENTATION(Error, Object);
};

class ApiError : public Error {
 public:
  StringPtr message() const { return untag()->message(); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedApiError));
  }

  static ApiErrorPtr New(const String& message, Heap::Space space = Heap::kNew);

  virtual const char* ToErrorCString() const;

 private:
  void set_message(const String& message) const;

  static ApiErrorPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ApiError, Error);
  friend class Class;
};

class LanguageError : public Error {
 public:
  Report::Kind kind() const {
    return static_cast<Report::Kind>(untag()->kind_);
  }

  // Build, cache, and return formatted message.
  StringPtr FormatMessage() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedLanguageError));
  }

  // A null script means no source and a negative token_pos means no position.
  static LanguageErrorPtr NewFormatted(const Error& prev_error,
                                       const Script& script,
                                       TokenPosition token_pos,
                                       bool report_after_token,
                                       Report::Kind kind,
                                       Heap::Space space,
                                       const char* format,
                                       ...) PRINTF_ATTRIBUTE(7, 8);

  static LanguageErrorPtr NewFormattedV(const Error& prev_error,
                                        const Script& script,
                                        TokenPosition token_pos,
                                        bool report_after_token,
                                        Report::Kind kind,
                                        Heap::Space space,
                                        const char* format,
                                        va_list args);

  static LanguageErrorPtr New(const String& formatted_message,
                              Report::Kind kind = Report::kError,
                              Heap::Space space = Heap::kNew);

  virtual const char* ToErrorCString() const;

  TokenPosition token_pos() const { return untag()->token_pos_; }

 private:
  ErrorPtr previous_error() const { return untag()->previous_error(); }
  void set_previous_error(const Error& value) const;

  ScriptPtr script() const { return untag()->script(); }
  void set_script(const Script& value) const;

  void set_token_pos(TokenPosition value) const;

  bool report_after_token() const { return untag()->report_after_token_; }
  void set_report_after_token(bool value) const;

  void set_kind(uint8_t value) const;

  StringPtr message() const { return untag()->message(); }
  void set_message(const String& value) const;

  StringPtr formatted_message() const { return untag()->formatted_message(); }
  void set_formatted_message(const String& value) const;

  static LanguageErrorPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(LanguageError, Error);
  friend class Class;
};

class UnhandledException : public Error {
 public:
  InstancePtr exception() const { return untag()->exception(); }
  static intptr_t exception_offset() {
    return OFFSET_OF(UntaggedUnhandledException, exception_);
  }

  InstancePtr stacktrace() const { return untag()->stacktrace(); }
  static intptr_t stacktrace_offset() {
    return OFFSET_OF(UntaggedUnhandledException, stacktrace_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedUnhandledException));
  }

  static UnhandledExceptionPtr New(const Instance& exception,
                                   const Instance& stacktrace,
                                   Heap::Space space = Heap::kNew);

  virtual const char* ToErrorCString() const;

 private:
  static UnhandledExceptionPtr New(Heap::Space space = Heap::kNew);

  void set_exception(const Instance& exception) const;
  void set_stacktrace(const Instance& stacktrace) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(UnhandledException, Error);
  friend class Class;
  friend class ObjectStore;
};

class UnwindError : public Error {
 public:
  bool is_user_initiated() const { return untag()->is_user_initiated_; }
  void set_is_user_initiated(bool value) const;

  StringPtr message() const { return untag()->message(); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedUnwindError));
  }

  static UnwindErrorPtr New(const String& message,
                            Heap::Space space = Heap::kNew);

  virtual const char* ToErrorCString() const;

 private:
  void set_message(const String& message) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(UnwindError, Error);
  friend class Class;
};

// Instance is the base class for all instance objects (aka the Object class
// in Dart source code.
class Instance : public Object {
 public:
  // Equality and identity testing.
  // 1. OperatorEquals: true iff 'this == other' is true in Dart code.
  // 2. IsIdenticalTo: true iff 'identical(this, other)' is true in Dart code.
  // 3. CanonicalizeEquals: used to canonicalize compile-time constants, e.g.,
  //    using bitwise equality of fields and list elements.
  // Subclasses where 1 and 3 coincide may also define a plain Equals, e.g.,
  // String and Integer.
  virtual bool OperatorEquals(const Instance& other) const;
  bool IsIdenticalTo(const Instance& other) const;
  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const;

  intptr_t SizeFromClass() const {
#if defined(DEBUG)
    const Class& cls = Class::Handle(clazz());
    ASSERT(cls.is_finalized() || cls.is_prefinalized());
#endif
    return (clazz()->untag()->host_instance_size_in_words_ *
            kCompressedWordSize);
  }

  InstancePtr Canonicalize(Thread* thread) const;
  // Caller must hold IsolateGroup::constant_canonicalization_mutex_.
  virtual InstancePtr CanonicalizeLocked(Thread* thread) const;
  virtual void CanonicalizeFieldsLocked(Thread* thread) const;

  InstancePtr CopyShallowToOldSpace(Thread* thread) const;

  ObjectPtr GetField(const Field& field) const;

  void SetField(const Field& field, const Object& value) const;

  AbstractTypePtr GetType(Heap::Space space) const;

  // Access the type arguments vector of this [Instance].
  // This vector includes type arguments corresponding to type parameters of
  // instance's class and all its superclasses.
  virtual TypeArgumentsPtr GetTypeArguments() const;
  virtual void SetTypeArguments(const TypeArguments& value) const;

  // Check if the type of this instance is a subtype of the given other type.
  // The type argument vectors are used to instantiate the other type if needed.
  bool IsInstanceOf(const AbstractType& other,
                    const TypeArguments& other_instantiator_type_arguments,
                    const TypeArguments& other_function_type_arguments) const;

  // Check if this instance is assignable to the given other type.
  // The type argument vectors are used to instantiate the other type if needed.
  bool IsAssignableTo(const AbstractType& other,
                      const TypeArguments& other_instantiator_type_arguments,
                      const TypeArguments& other_function_type_arguments) const;

  // Return true if the null instance can be assigned to a variable of [other]
  // type. Return false if null cannot be assigned or we cannot tell (if
  // [other] is a type parameter in NNBD strong mode). Only used for checks at
  // compile time.
  static bool NullIsAssignableTo(const AbstractType& other);

  // Return true if the null instance can be assigned to a variable of [other]
  // type. Return false if null cannot be assigned. Used for checks at runtime,
  // when the instantiator and function type argument vectors are available.
  static bool NullIsAssignableTo(
      const AbstractType& other,
      const TypeArguments& other_instantiator_type_arguments,
      const TypeArguments& other_function_type_arguments);

  bool IsValidNativeIndex(int index) const {
    return ((index >= 0) && (index < clazz()->untag()->num_native_fields_));
  }

  intptr_t* NativeFieldsDataAddr() const;
  inline intptr_t GetNativeField(int index) const;
  inline void GetNativeFields(uint16_t num_fields,
                              intptr_t* field_values) const;
  void SetNativeFields(uint16_t num_fields, const intptr_t* field_values) const;

  uint16_t NumNativeFields() const {
    return clazz()->untag()->num_native_fields_;
  }

  void SetNativeField(int index, intptr_t value) const;

  // If the instance is a callable object, i.e. a closure or the instance of a
  // class implementing a 'call' method, return true and set the function
  // (if not nullptr) to call.
  bool IsCallable(Function* function) const;

  ObjectPtr Invoke(const String& selector,
                   const Array& arguments,
                   const Array& argument_names,
                   bool respect_reflectable = true,
                   bool check_is_entrypoint = false) const;
  ObjectPtr InvokeGetter(const String& selector,
                         bool respect_reflectable = true,
                         bool check_is_entrypoint = false) const;
  ObjectPtr InvokeSetter(const String& selector,
                         const Instance& argument,
                         bool respect_reflectable = true,
                         bool check_is_entrypoint = false) const;

  ObjectPtr EvaluateCompiledExpression(
      const Class& klass,
      const ExternalTypedData& kernel_buffer,
      const Array& type_definitions,
      const Array& arguments,
      const TypeArguments& type_arguments) const;

  // Evaluate the given expression as if it appeared in an instance method of
  // [receiver] and return the resulting value, or an error object if
  // evaluating the expression fails. The method has the formal (type)
  // parameters given in (type_)param_names, and is invoked with the (type)
  // argument values given in (type_)param_values.
  //
  // We allow [receiver] to be null/<optimized out> if
  //   * the evaluation function doesn't access `this`
  //   * the evaluation function is static
  static ObjectPtr EvaluateCompiledExpression(
      Thread* thread,
      const Object& receiver,
      const Library& library,
      const Class& klass,
      const ExternalTypedData& kernel_buffer,
      const Array& type_definitions,
      const Array& param_values,
      const TypeArguments& type_param_values);

  // Equivalent to invoking hashCode on this instance.
  virtual ObjectPtr HashCode() const;

  // Equivalent to invoking identityHashCode with this instance.
  IntegerPtr IdentityHashCode(Thread* thread) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedInstance));
  }

  static InstancePtr New(const Class& cls, Heap::Space space = Heap::kNew);
  static InstancePtr NewAlreadyFinalized(const Class& cls,
                                         Heap::Space space = Heap::kNew);

  // Array/list element address computations.
  static intptr_t DataOffsetFor(intptr_t cid);
  static intptr_t ElementSizeFor(intptr_t cid);

  // Pointers may be subtyped, but their subtypes may not get extra fields.
  // The subtype runtime representation has exactly the same object layout,
  // only the class_id is different. So, it is safe to use subtype instances in
  // Pointer handles.
  virtual bool IsPointer() const;

  static intptr_t NextFieldOffset() { return sizeof(UntaggedInstance); }

  static intptr_t NativeFieldsOffset() { return sizeof(UntaggedObject); }

 protected:
#ifndef PRODUCT
  virtual void PrintSharedInstanceJSON(JSONObject* jsobj,
                                       bool ref,
                                       bool include_id = true) const;
#endif

 private:
  // Return true if the runtimeType of this instance is a subtype of other type.
  bool RuntimeTypeIsSubtypeOf(
      const AbstractType& other,
      const TypeArguments& other_instantiator_type_arguments,
      const TypeArguments& other_function_type_arguments) const;

  // Returns true if the type of this instance is a subtype of FutureOr<T>
  // specified by instantiated type 'other'.
  // Returns false if other type is not a FutureOr.
  bool RuntimeTypeIsSubtypeOfFutureOr(Zone* zone,
                                      const AbstractType& other) const;

  // Return true if the null instance is an instance of other type.
  static bool NullIsInstanceOf(
      const AbstractType& other,
      const TypeArguments& other_instantiator_type_arguments,
      const TypeArguments& other_function_type_arguments);

  CompressedObjectPtr* FieldAddrAtOffset(intptr_t offset) const {
    ASSERT(IsValidFieldOffset(offset));
    return reinterpret_cast<CompressedObjectPtr*>(raw_value() - kHeapObjectTag +
                                                  offset);
  }
  CompressedObjectPtr* FieldAddr(const Field& field) const {
    return FieldAddrAtOffset(field.HostOffset());
  }
  CompressedObjectPtr* NativeFieldsAddr() const {
    return FieldAddrAtOffset(sizeof(UntaggedObject));
  }
  void SetFieldAtOffset(intptr_t offset, const Object& value) const {
    StoreCompressedPointer(FieldAddrAtOffset(offset), value.ptr());
  }
  bool IsValidFieldOffset(intptr_t offset) const;

  // The following raw methods are used for morphing.
  // They are needed due to the extraction of the class in IsValidFieldOffset.
  CompressedObjectPtr* RawFieldAddrAtOffset(intptr_t offset) const {
    return reinterpret_cast<CompressedObjectPtr*>(raw_value() - kHeapObjectTag +
                                                  offset);
  }
  ObjectPtr RawGetFieldAtOffset(intptr_t offset) const {
    return RawFieldAddrAtOffset(offset)->Decompress(untag()->heap_base());
  }
  void RawSetFieldAtOffset(intptr_t offset, const Object& value) const {
    StoreCompressedPointer(RawFieldAddrAtOffset(offset), value.ptr());
  }
  void RawSetFieldAtOffset(intptr_t offset, ObjectPtr value) const {
    StoreCompressedPointer(RawFieldAddrAtOffset(offset), value);
  }

  template <typename T>
  T* RawUnboxedFieldAddrAtOffset(intptr_t offset) const {
    return reinterpret_cast<T*>(raw_value() - kHeapObjectTag + offset);
  }
  template <typename T>
  T RawGetUnboxedFieldAtOffset(intptr_t offset) const {
    return *RawUnboxedFieldAddrAtOffset<T>(offset);
  }
  template <typename T>
  void RawSetUnboxedFieldAtOffset(intptr_t offset, const T& value) const {
    *RawUnboxedFieldAddrAtOffset<T>(offset) = value;
  }

  // TODO(iposva): Determine if this gets in the way of Smi.
  HEAP_OBJECT_IMPLEMENTATION(Instance, Object);
  friend class ByteBuffer;
  friend class Class;
  friend class Closure;
  friend class Pointer;
  friend class DeferredObject;
  friend class FlowGraphSerializer;
  friend class FlowGraphDeserializer;
  friend class RegExp;
  friend class StubCode;
  friend class TypedDataView;
  friend class InstanceSerializationCluster;
  friend class InstanceDeserializationCluster;
  friend class ClassDeserializationCluster;  // vtable
  friend class InstanceMorpher;
  friend class Obfuscator;  // RawGetFieldAtOffset, RawSetFieldAtOffset
};

class LibraryPrefix : public Instance {
 public:
  StringPtr name() const { return untag()->name(); }
  virtual StringPtr DictionaryName() const { return name(); }

  ArrayPtr imports() const { return untag()->imports(); }
  intptr_t num_imports() const { return untag()->num_imports_; }
  LibraryPtr importer() const { return untag()->importer(); }

  LibraryPtr GetLibrary(int index) const;
  void AddImport(const Namespace& import) const;

  bool is_deferred_load() const { return untag()->is_deferred_load_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedLibraryPrefix));
  }

  static LibraryPrefixPtr New(const String& name,
                              const Namespace& import,
                              bool deferred_load,
                              const Library& importer);

 private:
  static constexpr int kInitialSize = 2;
  static constexpr int kIncrementSize = 2;

  void set_name(const String& value) const;
  void set_imports(const Array& value) const;
  void set_num_imports(intptr_t value) const;
  void set_importer(const Library& value) const;

  static LibraryPrefixPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(LibraryPrefix, Instance);
  friend class Class;
};

// TypeParameters represents a list of formal type parameters with their bounds
// and their default values as calculated by CFE.
class TypeParameters : public Object {
 public:
  intptr_t Length() const;

  static intptr_t names_offset() {
    return OFFSET_OF(UntaggedTypeParameters, names_);
  }
  StringPtr NameAt(intptr_t index) const;
  void SetNameAt(intptr_t index, const String& value) const;

  static intptr_t flags_offset() {
    return OFFSET_OF(UntaggedTypeParameters, flags_);
  }

  static intptr_t bounds_offset() {
    return OFFSET_OF(UntaggedTypeParameters, bounds_);
  }
  AbstractTypePtr BoundAt(intptr_t index) const;
  void SetBoundAt(intptr_t index, const AbstractType& value) const;
  bool AllDynamicBounds() const;

  static intptr_t defaults_offset() {
    return OFFSET_OF(UntaggedTypeParameters, defaults_);
  }
  AbstractTypePtr DefaultAt(intptr_t index) const;
  void SetDefaultAt(intptr_t index, const AbstractType& value) const;
  bool AllDynamicDefaults() const;

  // The isGenericCovariantImpl bits are packed into SMIs in the flags array,
  // but omitted if they're 0.
  bool IsGenericCovariantImplAt(intptr_t index) const;
  void SetIsGenericCovariantImplAt(intptr_t index, bool value) const;

  // The number of flags per Smi should be a power of 2 in order to simplify the
  // generated code accessing the flags array.
#if !defined(DART_COMPRESSED_POINTERS)
  static constexpr intptr_t kFlagsPerSmiShift = kBitsPerWordLog2 - 1;
#else
  static constexpr intptr_t kFlagsPerSmiShift = kBitsPerWordLog2 - 2;
#endif
  static constexpr intptr_t kFlagsPerSmi = 1LL << kFlagsPerSmiShift;
  COMPILE_ASSERT(kFlagsPerSmi < kSmiBits);
  static constexpr intptr_t kFlagsPerSmiMask = kFlagsPerSmi - 1;

  void Print(Thread* thread,
             Zone* zone,
             bool are_class_type_parameters,
             intptr_t base,
             NameVisibility name_visibility,
             BaseTextBuffer* printer) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedTypeParameters));
  }

  static TypeParametersPtr New(Heap::Space space = Heap::kOld);
  static TypeParametersPtr New(intptr_t count, Heap::Space space = Heap::kOld);

 private:
  ArrayPtr names() const { return untag()->names(); }
  void set_names(const Array& value) const;
  ArrayPtr flags() const { return untag()->flags(); }
  void set_flags(const Array& value) const;
  TypeArgumentsPtr bounds() const { return untag()->bounds(); }
  void set_bounds(const TypeArguments& value) const;
  TypeArgumentsPtr defaults() const { return untag()->defaults(); }
  void set_defaults(const TypeArguments& value) const;

  // Allocate and initialize the flags array to zero.
  void AllocateFlags(Heap::Space space) const;
  // Reset the flags array to null if all flags are zero.
  void OptimizeFlags() const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypeParameters, Object);
  friend class Class;
  friend class ClassFinalizer;
  friend class FlowGraphSerializer;
  friend class FlowGraphDeserializer;
  friend class Function;
  friend class FunctionType;
  friend class Object;
  friend class Precompiler;
  friend class Type;  // To determine whether to print type arguments.
};

// A TypeArguments is an array of AbstractType.
class TypeArguments : public Instance {
 public:
  // Hash value for a type argument vector consisting solely of dynamic types.
  static constexpr intptr_t kAllDynamicHash = 1;

  // Returns whether this TypeArguments vector can be used in a context that
  // expects a vector of length [count]. Always true for the null vector.
  bool HasCount(intptr_t count) const;
  static intptr_t length_offset() {
    return OFFSET_OF(UntaggedTypeArguments, length_);
  }
  intptr_t Length() const;
  AbstractTypePtr TypeAt(intptr_t index) const;
  AbstractTypePtr TypeAtNullSafe(intptr_t index) const;
  static intptr_t types_offset() {
    return OFFSET_OF_RETURNED_VALUE(UntaggedTypeArguments, types);
  }
  static intptr_t type_at_offset(intptr_t index) {
    return types_offset() + index * kCompressedWordSize;
  }
  void SetTypeAt(intptr_t index, const AbstractType& value) const;

  struct ArrayTraits {
    static intptr_t elements_start_offset() {
      return TypeArguments::types_offset();
    }

    static constexpr intptr_t kElementSize = kCompressedWordSize;
  };

  // The nullability of a type argument vector represents the nullability of its
  // type elements (up to a maximum number of them, i.e. kNullabilityMaxTypes).
  // It is used at runtime in some cases (predetermined by the compiler) to
  // decide whether the instantiator type arguments (ITA) can be shared instead
  // of performing a more costly instantiation of the uninstantiated type
  // arguments (UTA).
  // The vector nullability is stored as a bit vector (in a Smi field), using
  // 2 bits per type:
  //  - the high bit is set if the type is nullable or legacy.
  //  - the low bit is set if the type is nullable.
  // The nullability is 0 if the vector is longer than kNullabilityMaxTypes.
  // The condition evaluated at runtime to decide whether UTA can share ITA is
  //   (UTA.nullability & ITA.nullability) == UTA.nullability
  // Note that this allows for ITA to be longer than UTA (the bit vector must be
  // stored in the same order as the corresponding type vector, i.e. with the
  // least significant 2 bits representing the nullability of the first type).
  static constexpr intptr_t kNullabilityBitsPerType = 2;
  static constexpr intptr_t kNullabilityMaxTypes =
      kSmiBits / kNullabilityBitsPerType;
  static constexpr intptr_t kNonNullableBits = 0;
  static constexpr intptr_t kNullableBits = 3;
  static constexpr intptr_t kLegacyBits = 2;
  intptr_t nullability() const;
  static intptr_t nullability_offset() {
    return OFFSET_OF(UntaggedTypeArguments, nullability_);
  }

  // The name of this type argument vector, e.g. "<T, dynamic, List<T>, Smi>".
  StringPtr Name() const;

  // The name of this type argument vector, e.g. "<T, dynamic, List<T>, int>".
  // Names of internal classes are mapped to their public interfaces.
  StringPtr UserVisibleName() const;

  // Print the internal or public name of a subvector of this type argument
  // vector, e.g. "<T, dynamic, List<T>, int>".
  void PrintSubvectorName(intptr_t from_index,
                          intptr_t len,
                          NameVisibility name_visibility,
                          BaseTextBuffer* printer) const;
  void PrintTo(BaseTextBuffer* printer) const;

  // Check if the subvector of length 'len' starting at 'from_index' of this
  // type argument vector consists solely of DynamicType.
  bool IsRaw(intptr_t from_index, intptr_t len) const {
    return IsDynamicTypes(false, from_index, len);
  }

  // Check if this type argument vector would consist solely of DynamicType if
  // it was instantiated from both a raw (null) instantiator type arguments and
  // a raw (null) function type arguments, i.e. consider each class type
  // parameter and function type parameters as it would be first instantiated
  // from a vector of dynamic types.
  // Consider only a prefix of length 'len'.
  bool IsRawWhenInstantiatedFromRaw(intptr_t len) const {
    return IsDynamicTypes(true, 0, len);
  }

  // Return true if this vector contains a non-nullable type.
  bool RequireConstCanonicalTypeErasure(Zone* zone,
                                        intptr_t from_index,
                                        intptr_t len) const;

  TypeArgumentsPtr Prepend(Zone* zone,
                           const TypeArguments& other,
                           intptr_t other_length,
                           intptr_t total_length) const;

  // Concatenate [this] and [other] vectors of type parameters.
  TypeArgumentsPtr ConcatenateTypeParameters(Zone* zone,
                                             const TypeArguments& other) const;

  // Check if the vectors are equal (they may be null).
  bool Equals(const TypeArguments& other) const {
    return IsSubvectorEquivalent(other, 0, IsNull() ? 0 : Length(),
                                 TypeEquality::kCanonical);
  }

  bool IsEquivalent(
      const TypeArguments& other,
      TypeEquality kind,
      FunctionTypeMapping* function_type_equivalence = nullptr) const {
    // Make a null vector a vector of dynamic as long as the other vector.
    return IsSubvectorEquivalent(other, 0, IsNull() ? other.Length() : Length(),
                                 kind, function_type_equivalence);
  }
  bool IsSubvectorEquivalent(
      const TypeArguments& other,
      intptr_t from_index,
      intptr_t len,
      TypeEquality kind,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;

  // Check if the vector is instantiated (it must not be null).
  bool IsInstantiated(Genericity genericity = kAny,
                      intptr_t num_free_fun_type_params = kAllFree) const {
    return IsSubvectorInstantiated(0, Length(), genericity,
                                   num_free_fun_type_params);
  }
  bool IsSubvectorInstantiated(
      intptr_t from_index,
      intptr_t len,
      Genericity genericity = kAny,
      intptr_t num_free_fun_type_params = kAllFree) const;
  bool IsUninstantiatedIdentity() const;

  // Determine whether this uninstantiated type argument vector can share its
  // instantiator (resp. function) type argument vector instead of being
  // instantiated at runtime.
  // If null is passed in for 'with_runtime_check', the answer is unconditional
  // (i.e. the answer will be false even if a runtime check may allow sharing),
  // otherwise, in case the function returns true, 'with_runtime_check'
  // indicates if a check is still required at runtime before allowing sharing.
  bool CanShareInstantiatorTypeArguments(
      const Class& instantiator_class,
      bool* with_runtime_check = nullptr) const;
  bool CanShareFunctionTypeArguments(const Function& function,
                                     bool* with_runtime_check = nullptr) const;
  TypeArgumentsPtr TruncatedTo(intptr_t length) const;

  // Return true if all types of this vector are finalized.
  bool IsFinalized() const;

  // Caller must hold IsolateGroup::constant_canonicalization_mutex_.
  virtual InstancePtr CanonicalizeLocked(Thread* thread) const {
    return Canonicalize(thread);
  }

  // Canonicalize only if instantiated, otherwise returns 'this'.
  TypeArgumentsPtr Canonicalize(Thread* thread) const;

  // Shrinks flattened instance type arguments to ordinary type arguments.
  TypeArgumentsPtr FromInstanceTypeArguments(Thread* thread,
                                             const Class& cls) const;

  // Expands type arguments to a vector suitable as instantiator type
  // arguments.
  //
  // Only fills positions corresponding to type parameters of [cls], leave
  // all positions of superclass type parameters blank.
  // Use [GetInstanceTypeArguments] on a class or a type if full vector is
  // needed.
  TypeArgumentsPtr ToInstantiatorTypeArguments(Thread* thread,
                                               const Class& cls) const;

  // Add the class name and URI of each type argument of this vector to the uris
  // list and mark ambiguous triplets to be printed.
  void EnumerateURIs(URIs* uris) const;

  // Return 'this' if this type argument vector is instantiated, i.e. if it does
  // not refer to type parameters. Otherwise, return a new type argument vector
  // where each reference to a type parameter is replaced with the corresponding
  // type from the various type argument vectors (class instantiator, function,
  // or parent functions via the current context).
  TypeArgumentsPtr InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping = nullptr,
      intptr_t num_parent_type_args_adjustment = 0) const;

  // Update number of parent function type arguments for
  // all elements of this vector.
  TypeArgumentsPtr UpdateFunctionTypes(
      intptr_t num_parent_type_args_adjustment,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping) const;

  // Runtime instantiation with canonicalization. Not to be used during type
  // finalization at compile time.
  TypeArgumentsPtr InstantiateAndCanonicalizeFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments) const;

  class Cache : public ValueObject {
   public:
    // The contents of the backing array storage is a header followed by
    // a number of entry tuples. Any entry that is unoccupied has
    // Sentinel() as its first component.
    //
    // If the cache is linear, the entries can be accessed in a linear fashion:
    // all occupied entries come first, followed by at least one unoccupied
    // entry to mark the end of the cache. Guaranteeing at least one unoccupied
    // entry avoids the need for a length check when iterating over the contents
    // of the linear cache in stubs.
    //
    // If the cache is hash-based, the array is instead treated as a hash table
    // probed by using a hash value derived from the instantiator and function
    // type arguments.

    enum Header {
      // A single Smi that is a bitfield containing two values:
      // - The number of occupied entries in the cache for all caches.
      // - For hash-based caches, the upper bits contain log2(N) where N
      //   is the number of total entries in the cache, so this information can
      //   be quickly retrieved by stubs.
      //
      // Note: accesses outside of the type arguments canonicalization mutex
      // must have acquire semantics. In C++ code, use NumOccupied to retrieve
      // the number of occupied entries.
      kMetadataIndex = 0,
      kHeaderSize,
    };

    using NumOccupiedBits = BitField<intptr_t,
                                     intptr_t,
                                     0,
                                     compiler::target::kSmiBits -
                                         compiler::target::kBitsPerWordLog2>;
    using EntryCountLog2Bits = BitField<intptr_t,
                                        intptr_t,
                                        NumOccupiedBits::kNextBit,
                                        compiler::target::kBitsPerWordLog2>;

    // The tuple of values stored in a given entry.
    //
    // Note: accesses of the first component outside of the type arguments
    // canonicalization mutex must have acquire semantics.
    enum Entry {
      kSentinelIndex = 0,  // Used when only checking for sentinel values.
      kInstantiatorTypeArgsIndex = kSentinelIndex,
      kFunctionTypeArgsIndex,
      kInstantiatedTypeArgsIndex,
      kEntrySize,
    };

    // Requires that the type arguments canonicalization mutex is held.
    Cache(Zone* zone, const TypeArguments& source);

    // Requires that the type arguments canonicalization mutex is held.
    Cache(Zone* zone, const Array& array);

    // Used to check that the state of the backing array is valid.
    //
    // Requires that the type arguments canonicalization mutex is held.
    DEBUG_ONLY(static bool IsValidStorageLocked(const Array& array);)

    // Returns the number of entries stored in the cache.
    intptr_t NumOccupied() const { return NumOccupied(data_); }

    struct KeyLocation {
      // The entry index if [present] is true, otherwise where the entry would
      // be located if added afterwards without any intermediate additions.
      intptr_t entry;
      bool present;  // Whether an entry already exists in the cache.
    };

    // If an entry contains the given instantiator and function type arguments,
    // returns a KeyLocation with the index of the entry and true. Otherwise,
    // returns the index an entry with those keys would have if added and false.
    KeyLocation FindKeyOrUnused(const TypeArguments& instantiator_tav,
                                const TypeArguments& function_tav) const {
      return FindKeyOrUnused(data_, instantiator_tav, function_tav);
    }

    // Returns whether the entry at the given index in the cache is occupied.
    bool IsOccupied(intptr_t entry) const;

    // Given an occupied entry index, returns the instantiated TypeArguments.
    TypeArgumentsPtr Retrieve(intptr_t entry) const;

    // Adds a new instantiation mapping to the cache at index [entry]. Assumes
    // that the entry at index [entry] is unoccupied.
    //
    // May replace the underlying storage array, in which case the returned
    // index of the entry may differ from the requested one. If this Cache was
    // constructed using a TypeArguments object, its instantiations field is
    // also updated to point to the new storage.
    KeyLocation AddEntry(intptr_t entry,
                         const TypeArguments& instantiator_tav,
                         const TypeArguments& function_tav,
                         const TypeArguments& instantiated_tav) const;

    // The sentinel value used to mark unoccupied entries.
    static SmiPtr Sentinel();

    static const Array& EmptyStorage() {
      return Object::empty_instantiations_cache_array();
    }

    // Returns whether the cache is linear.
    bool IsLinear() const { return IsLinear(data_); }

    // Returns whether the cache is hash-based.
    bool IsHash() const { return IsHash(data_); }

   private:
    static constexpr double LoadFactor(intptr_t occupied, intptr_t capacity) {
      return occupied / static_cast<double>(capacity);
    }

    // Returns the number of entries stored in the cache backed by the given
    // array.
    static intptr_t NumOccupied(const Array& array);

    // Returns whether the cache backed by the given storage is linear.
    static bool IsLinear(const Array& array) { return !IsHash(array); }

    // Returns whether the cache backed by the given storage is hash-based.
    static bool IsHash(const Array& array);

    // Ensures that the backing store for the cache can hold at least [occupied]
    // occupied entries. If it cannot, replaces the backing store with one that
    // can, copying over entries from the old backing store.
    //
    // Returns whether the backing store changed.
    bool EnsureCapacity(intptr_t occupied) const;

   public:  // For testing purposes only.
    // Retrieves the number of entries (occupied or unoccupied) in the cache.
    intptr_t NumEntries() const { return NumEntries(data_); }

    // The maximum number of occupied entries for a linear cache of
    // instantiations before swapping to a hash table-based cache.
#if defined(TARGET_ARCH_IA32)
    // We don't generate hash cache probing in the stub on IA32.
    static constexpr intptr_t kMaxLinearCacheEntries = 500;
#else
    static constexpr intptr_t kMaxLinearCacheEntries = 10;
#endif

   private:
    // Retrieves the number of entries (occupied or unoccupied) in a cache
    // backed by the given array.
    static intptr_t NumEntries(const Array& array);

    // If an entry in the given array contains the given instantiator and
    // function type arguments, returns a KeyLocation with the index of the
    // entry and true. Otherwise, returns a KeyLocation with the index that
    // would be used if the instantiation for the given type arguments is
    // added and false.
    static KeyLocation FindKeyOrUnused(const Array& array,
                                       const TypeArguments& instantiator_tav,
                                       const TypeArguments& function_tav);

    // The sentinel value in the Smi returned from Sentinel().
    static constexpr intptr_t kSentinelValue = 0;

   public:  // Used in the StubCodeCompiler.
    // The maximum size of the array backing a linear cache. All hash based
    // caches are guaranteed to have sizes larger than this.
    static constexpr intptr_t kMaxLinearCacheSize =
        kHeaderSize + (kMaxLinearCacheEntries + 1) * kEntrySize;

   private:
    // The initial number of entries used when converting from a linear to
    // a hash-based cache.
    static constexpr intptr_t kNumInitialHashCacheEntries =
        Utils::RoundUpToPowerOfTwo(2 * kMaxLinearCacheEntries);
    static_assert(Utils::IsPowerOfTwo(kNumInitialHashCacheEntries),
                  "number of hash-based cache entries must be a power of two");

    // The max load factor allowed in hash-based caches.
    static constexpr double kMaxLoadFactor = 0.71;

    Zone* const zone_;
    const TypeArguments* const cache_container_;
    Array& data_;
    Smi& smi_handle_;

    friend class TypeArguments;  // For asserts against data_.
  };

  // Return true if this type argument vector has cached instantiations.
  bool HasInstantiations() const;

  static intptr_t instantiations_offset() {
    return OFFSET_OF(UntaggedTypeArguments, instantiations_);
  }

  static constexpr intptr_t kBytesPerElement = kCompressedWordSize;
  static constexpr intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedTypeArguments) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedTypeArguments, types));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    // Ensure that the types() is not adding to the object size, which includes
    // 4 fields: instantiations_, length_, hash_, and nullability_.
    ASSERT(sizeof(UntaggedTypeArguments) ==
           (sizeof(UntaggedObject) + (kNumFields * kCompressedWordSize)));
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(UntaggedTypeArguments) +
                                 (len * kBytesPerElement));
  }

  virtual uint32_t CanonicalizeHash() const {
    // Hash() is not stable until finalization is done.
    return 0;
  }
  uword Hash() const;
  uword HashForRange(intptr_t from_index, intptr_t len) const;
  static intptr_t hash_offset() {
    return OFFSET_OF(UntaggedTypeArguments, hash_);
  }

  static TypeArgumentsPtr New(intptr_t len, Heap::Space space = Heap::kOld);

 private:
  intptr_t ComputeNullability() const;
  void set_nullability(intptr_t value) const;

  uword ComputeHash() const;
  void SetHash(intptr_t value) const;

  // Check if the subvector of length 'len' starting at 'from_index' of this
  // type argument vector consists solely of DynamicType.
  // If raw_instantiated is true, consider each class type parameter to be first
  // instantiated from a vector of dynamic types.
  bool IsDynamicTypes(bool raw_instantiated,
                      intptr_t from_index,
                      intptr_t len) const;

  ArrayPtr instantiations() const;
  void set_instantiations(const Array& value) const;
  void SetLength(intptr_t value) const;
  // Number of fields in the raw object is 4:
  // instantiations_, length_, hash_ and nullability_.
  static constexpr int kNumFields = 4;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypeArguments, Instance);
  friend class AbstractType;
  friend class Class;
  friend class ClearTypeHashVisitor;
  friend class Object;
};

// AbstractType is an abstract superclass.
// Subclasses of AbstractType are Type and TypeParameter.
class AbstractType : public Instance {
 public:
  static intptr_t flags_offset() {
    return OFFSET_OF(UntaggedAbstractType, flags_);
  }
  static intptr_t hash_offset() {
    return OFFSET_OF(UntaggedAbstractType, hash_);
  }

  bool IsFinalized() const {
    const auto state = type_state();
    return (state == UntaggedAbstractType::kFinalizedInstantiated) ||
           (state == UntaggedAbstractType::kFinalizedUninstantiated);
  }
  void SetIsFinalized() const;

  Nullability nullability() const {
    return static_cast<Nullability>(
        UntaggedAbstractType::NullabilityBits::decode(untag()->flags()));
  }
  // Returns true if type has '?' nullability suffix, or it is a
  // built-in type which is always nullable (Null, dynamic or void).
  bool IsNullable() const { return nullability() == Nullability::kNullable; }
  // Returns true if type does not have any nullability suffix.
  // This function also returns true for type parameters without
  // nullability suffix ("T") which can be instantiated with
  // nullable or legacy types.
  bool IsNonNullable() const {
    return nullability() == Nullability::kNonNullable;
  }
  // Returns true if type has '*' nullability suffix, i.e.
  // it is from a legacy (opted-out) library.
  bool IsLegacy() const { return nullability() == Nullability::kLegacy; }
  // Returns true if it is guaranteed that null cannot be
  // assigned to this type.
  bool IsStrictlyNonNullable() const;

  virtual AbstractTypePtr SetInstantiatedNullability(
      const TypeParameter& type_param,
      Heap::Space space) const;
  virtual AbstractTypePtr NormalizeFutureOrType(Heap::Space space) const;

  virtual bool HasTypeClass() const { return type_class_id() != kIllegalCid; }
  virtual classid_t type_class_id() const;
  virtual ClassPtr type_class() const;
  virtual TypeArgumentsPtr arguments() const;
  virtual bool IsInstantiated(
      Genericity genericity = kAny,
      intptr_t num_free_fun_type_params = kAllFree) const;
  virtual bool CanonicalizeEquals(const Instance& other) const {
    return Equals(other);
  }
  virtual uint32_t CanonicalizeHash() const { return Hash(); }
  virtual bool Equals(const Instance& other) const {
    return IsEquivalent(other, TypeEquality::kCanonical);
  }
  virtual bool IsEquivalent(
      const Instance& other,
      TypeEquality kind,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;
  virtual bool RequireConstCanonicalTypeErasure(Zone* zone) const;

  // Instantiate this type using the given type argument vectors.
  //
  // Note that some type parameters appearing in this type may not require
  // instantiation. Consider a class C<T> declaring a non-generic method
  // foo(bar<B>(T t, B b)). Although foo is not a generic method, it takes a
  // generic function bar<B> as argument and its function type refers to class
  // type parameter T and function type parameter B. When instantiating the
  // function type of foo for a particular value of T, function type parameter B
  // must remain uninstantiated, because only T is a free variable in this type.
  //
  // Return a new type, or return 'this' if it is already instantiated.
  virtual AbstractTypePtr InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping = nullptr,
      intptr_t num_parent_type_args_adjustment = 0) const;

  // Update number of parent function type arguments for the
  // nested function types and their type parameters.
  //
  // This adjustment is needed when nesting one generic function type
  // inside another. It is also needed when function type is copied
  // and owners of type parameters need to be adjusted.
  //
  // Number of parent function type arguments is adjusted by
  // [num_parent_type_args_adjustment].
  // Type parameters up to [num_free_fun_type_params] are not adjusted.
  virtual AbstractTypePtr UpdateFunctionTypes(
      intptr_t num_parent_type_args_adjustment,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping) const;

  // Caller must hold IsolateGroup::constant_canonicalization_mutex_.
  virtual InstancePtr CanonicalizeLocked(Thread* thread) const {
    return Canonicalize(thread);
  }

  // Return the canonical version of this type.
  virtual AbstractTypePtr Canonicalize(Thread* thread) const;

  // Add the pair <name, uri> to the list, if not already present.
  static void AddURI(URIs* uris, const String& name, const String& uri);

  // Return a formatted string of the uris.
  static StringPtr PrintURIs(URIs* uris);

  // Returns a C-String (possibly "") representing the nullability of this type.
  // Legacy and undetermined suffixes are only displayed with kInternalName.
  virtual const char* NullabilitySuffix(NameVisibility name_visibility) const;

  // The name of this type, including the names of its type arguments, if any.
  virtual StringPtr Name() const;

  // The name of this type, including the names of its type arguments, if any.
  // Names of internal classes are mapped to their public interfaces.
  virtual StringPtr UserVisibleName() const;

  // The name of this type, including the names of its type arguments, if any.
  // Privacy suffixes are dropped.
  virtual StringPtr ScrubbedName() const;

  // Return the internal or public name of this type, including the names of its
  // type arguments, if any.
  virtual void PrintName(NameVisibility visibility,
                         BaseTextBuffer* printer) const;

  // Add the class name and URI of each occurring type to the uris
  // list and mark ambiguous triplets to be printed.
  virtual void EnumerateURIs(URIs* uris) const;

  uword Hash() const;
  virtual uword ComputeHash() const;

  // The name of this type's class, i.e. without the type argument names of this
  // type.
  StringPtr ClassName() const;

  // Check if this type represents the 'dynamic' type.
  bool IsDynamicType() const { return type_class_id() == kDynamicCid; }

  // Check if this type represents the 'void' type.
  bool IsVoidType() const { return type_class_id() == kVoidCid; }

  // Check if this type represents the 'Null' type.
  bool IsNullType() const;

  // Check if this type represents the 'Never' type.
  bool IsNeverType() const;

  // Check if this type represents the 'Sentinel' type.
  bool IsSentinelType() const;

  // Check if this type represents the 'Object' type.
  bool IsObjectType() const { return type_class_id() == kInstanceCid; }

  // Check if this type represents the 'Object?' type.
  bool IsNullableObjectType() const {
    return IsObjectType() && (nullability() == Nullability::kNullable);
  }

  // Check if this type represents a top type for subtyping,
  // assignability and 'as' type tests.
  //
  // Returns true if
  //  - any type is a subtype of this type;
  //  - any value can be assigned to a variable of this type;
  //  - 'as' type test always succeeds for this type.
  bool IsTopTypeForSubtyping() const;

  // Check if this type represents a top type for 'is' type tests.
  // Returns true if 'is' type test always returns true for this type.
  bool IsTopTypeForInstanceOf() const;

  // Check if this type represents the 'bool' type.
  bool IsBoolType() const { return type_class_id() == kBoolCid; }

  // Check if this type represents the 'int' type.
  bool IsIntType() const;

  // Check if this type represents the '_IntegerImplementation' type.
  bool IsIntegerImplementationType() const;

  // Check if this type represents the 'double' type.
  bool IsDoubleType() const;

  // Check if this type represents the 'Float32x4' type.
  bool IsFloat32x4Type() const;

  // Check if this type represents the 'Float64x2' type.
  bool IsFloat64x2Type() const;

  // Check if this type represents the 'Int32x4' type.
  bool IsInt32x4Type() const;

  // Check if this type represents the 'num' type.
  bool IsNumberType() const { return type_class_id() == kNumberCid; }

  // Check if this type represents the '_Smi' type.
  bool IsSmiType() const { return type_class_id() == kSmiCid; }

  // Check if this type represents the '_Mint' type.
  bool IsMintType() const { return type_class_id() == kMintCid; }

  // Check if this type represents the 'String' type.
  bool IsStringType() const;

  // Check if this type represents the Dart 'Function' type.
  bool IsDartFunctionType() const;

  // Check if this type represents the Dart '_Closure' type.
  bool IsDartClosureType() const;

  // Check if this type represents the Dart 'Record' type.
  bool IsDartRecordType() const;

  // Check if this type represents the 'Pointer' type from "dart:ffi".
  bool IsFfiPointerType() const;

  // Check if this type represents the 'FutureOr' type.
  bool IsFutureOrType() const { return type_class_id() == kFutureOrCid; }

  // Returns the type argument of this (possibly nested) 'FutureOr' type.
  // Returns unmodified type if this type is not a 'FutureOr' type.
  AbstractTypePtr UnwrapFutureOr() const;

  // Returns true if parameter of this type might need a
  // null assertion (if null assertions are enabled).
  bool NeedsNullAssertion() const;

  // Returns true if catching this type will catch all exceptions.
  // Exception objects are guaranteed to be non-nullable, so
  // non-nullable Object is also a catch-all type.
  bool IsCatchAllType() const { return IsDynamicType() || IsObjectType(); }

  // Returns true if this type has a type class permitted by SendPort.send for
  // messages between isolates in different groups. Does not recursively visit
  // type arguments.
  bool IsTypeClassAllowedBySpawnUri() const;

  // Check the subtype relationship.
  bool IsSubtypeOf(
      const AbstractType& other,
      Heap::Space space,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;

  // Returns true iff subtype is a subtype of supertype, false otherwise or if
  // an error occurred.
  static bool InstantiateAndTestSubtype(
      AbstractType* subtype,
      AbstractType* supertype,
      const TypeArguments& instantiator_type_args,
      const TypeArguments& function_type_args);

  static intptr_t type_test_stub_entry_point_offset() {
    return OFFSET_OF(UntaggedAbstractType, type_test_stub_entry_point_);
  }

  uword type_test_stub_entry_point() const {
    return untag()->type_test_stub_entry_point_;
  }
  CodePtr type_test_stub() const { return untag()->type_test_stub(); }

  // Sets the TTS to [stub].
  //
  // The update will ensure both fields (code as well as the cached entrypoint)
  // are updated together.
  //
  // Can be used concurrently by multiple threads - the updates will be applied
  // in undetermined order - but always consistently.
  void SetTypeTestingStub(const Code& stub) const;

  // Sets the TTS to the [stub].
  //
  // The caller has to ensure no other thread can concurrently try to update the
  // TTS. This should mainly be used when initializing newly allocated Type
  // objects.
  void InitializeTypeTestingStubNonAtomic(const Code& stub) const;

  void UpdateTypeTestingStubEntryPoint() const {
    StoreNonPointer(&untag()->type_test_stub_entry_point_,
                    Code::EntryPointOf(untag()->type_test_stub()));
  }

  // No instances of type AbstractType are allocated, but InstanceSize() and
  // NextFieldOffset() are required to register class _AbstractType.
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedAbstractType));
  }

  static intptr_t NextFieldOffset() { return -kWordSize; }

 private:
  // Returns true if this type is a subtype of FutureOr<T> specified by 'other'.
  // Returns false if other type is not a FutureOr.
  bool IsSubtypeOfFutureOr(
      Zone* zone,
      const AbstractType& other,
      Heap::Space space,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;

 protected:
  bool IsNullabilityEquivalent(Thread* thread,
                               const AbstractType& other_type,
                               TypeEquality kind) const;

  void SetHash(intptr_t value) const;

  UntaggedAbstractType::TypeState type_state() const {
    return static_cast<UntaggedAbstractType::TypeState>(
        UntaggedAbstractType::TypeStateBits::decode(untag()->flags()));
  }
  void set_flags(uint32_t value) const;
  void set_type_state(UntaggedAbstractType::TypeState value) const;
  void set_nullability(Nullability value) const;

  HEAP_OBJECT_IMPLEMENTATION(AbstractType, Instance);
  friend class Class;
  friend class ClearTypeHashVisitor;
  friend class Function;
  friend class TypeArguments;
};

// A Type consists of a class, possibly parameterized with type
// arguments. Example: C<T1, T2>.
class Type : public AbstractType {
 public:
  static intptr_t arguments_offset() {
    return OFFSET_OF(UntaggedType, arguments_);
  }
  virtual bool HasTypeClass() const {
    ASSERT(type_class_id() != kIllegalCid);
    return true;
  }
  TypePtr ToNullability(Nullability value, Heap::Space space) const;
  virtual classid_t type_class_id() const;
  virtual ClassPtr type_class() const;
  void set_type_class(const Class& value) const;
  virtual TypeArgumentsPtr arguments() const { return untag()->arguments(); }
  void set_arguments(const TypeArguments& value) const;

  // Returns flattened instance type arguments vector for
  // instance of this type.
  TypeArgumentsPtr GetInstanceTypeArguments(Thread* thread,
                                            bool canonicalize = true) const;

  virtual bool IsInstantiated(
      Genericity genericity = kAny,
      intptr_t num_free_fun_type_params = kAllFree) const;
  virtual bool IsEquivalent(
      const Instance& other,
      TypeEquality kind,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;
  virtual bool RequireConstCanonicalTypeErasure(Zone* zone) const;

  // Return true if this type can be used as the declaration type of cls after
  // canonicalization (passed-in cls must match type_class()).
  bool IsDeclarationTypeOf(const Class& cls) const;

  virtual AbstractTypePtr InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping = nullptr,
      intptr_t num_parent_type_args_adjustment = 0) const;

  virtual AbstractTypePtr UpdateFunctionTypes(
      intptr_t num_parent_type_args_adjustment,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping) const;

  virtual AbstractTypePtr Canonicalize(Thread* thread) const;
  virtual void EnumerateURIs(URIs* uris) const;
  virtual void PrintName(NameVisibility visibility,
                         BaseTextBuffer* printer) const;

  virtual uword ComputeHash() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedType));
  }

  // The type of the literal 'null'.
  static TypePtr NullType();

  // The 'dynamic' type.
  static TypePtr DynamicType();

  // The 'void' type.
  static TypePtr VoidType();

  // The 'Never' type.
  static TypePtr NeverType();

  // The 'Object' type.
  static TypePtr ObjectType();

  // The 'bool' type.
  static TypePtr BoolType();

  // The 'int' type.
  static TypePtr IntType();

  // The 'int?' type.
  static TypePtr NullableIntType();

  // The 'Smi' type.
  static TypePtr SmiType();

  // The 'Mint' type.
  static TypePtr MintType();

  // The 'double' type.
  static TypePtr Double();

  // The 'double?' type.
  static TypePtr NullableDouble();

  // The 'Float32x4' type.
  static TypePtr Float32x4();

  // The 'Float64x2' type.
  static TypePtr Float64x2();

  // The 'Int32x4' type.
  static TypePtr Int32x4();

  // The 'num' type.
  static TypePtr Number();

  // The 'num?' type.
  static TypePtr NullableNumber();

  // The 'String' type.
  static TypePtr StringType();

  // The 'Array' type.
  static TypePtr ArrayType();

  // The 'Function' type.
  static TypePtr DartFunctionType();

  // The 'Type' type.
  static TypePtr DartTypeType();

  // The finalized type of the given non-parameterized class.
  static TypePtr NewNonParameterizedType(const Class& type_class);

  static TypePtr New(const Class& clazz,
                     const TypeArguments& arguments,
                     Nullability nullability = Nullability::kLegacy,
                     Heap::Space space = Heap::kOld);

 private:
  // Takes an intptr_t since the cids of some classes are larger than will fit
  // in ClassIdTagType. This allows us to guard against that case, instead of
  // silently truncating the cid.
  void set_type_class_id(intptr_t id) const;

  static TypePtr New(Heap::Space space = Heap::kOld);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Type, AbstractType);
  friend class Class;
  friend class TypeArguments;
};

// A FunctionType represents the type of a function. It describes most of the
// signature of a function, excluding the names of type parameters and names
// of parameters, but includes the names of optional named parameters.
class FunctionType : public AbstractType {
 public:
  // Reexported so they can be used by the flow graph builders.
  using PackedNumParentTypeArguments =
      UntaggedFunctionType::PackedNumParentTypeArguments;
  using PackedNumTypeParameters = UntaggedFunctionType::PackedNumTypeParameters;
  using PackedHasNamedOptionalParameters =
      UntaggedFunctionType::PackedHasNamedOptionalParameters;
  using PackedNumImplicitParameters =
      UntaggedFunctionType::PackedNumImplicitParameters;
  using PackedNumFixedParameters =
      UntaggedFunctionType::PackedNumFixedParameters;
  using PackedNumOptionalParameters =
      UntaggedFunctionType::PackedNumOptionalParameters;

  virtual bool HasTypeClass() const { return false; }
  FunctionTypePtr ToNullability(Nullability value, Heap::Space space) const;
  virtual classid_t type_class_id() const { return kIllegalCid; }
  virtual bool IsInstantiated(
      Genericity genericity = kAny,
      intptr_t num_free_fun_type_params = kAllFree) const;
  virtual bool IsEquivalent(
      const Instance& other,
      TypeEquality kind,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;
  virtual bool RequireConstCanonicalTypeErasure(Zone* zone) const;

  virtual AbstractTypePtr InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping = nullptr,
      intptr_t num_parent_type_args_adjustment = 0) const;

  virtual AbstractTypePtr UpdateFunctionTypes(
      intptr_t num_parent_type_args_adjustment,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping) const;

  virtual AbstractTypePtr Canonicalize(Thread* thread) const;
  virtual void EnumerateURIs(URIs* uris) const;
  virtual void PrintName(NameVisibility visibility,
                         BaseTextBuffer* printer) const;

  virtual uword ComputeHash() const;

  bool IsSubtypeOf(
      const FunctionType& other,
      Heap::Space space,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;

  static intptr_t NumParentTypeArgumentsOf(FunctionTypePtr ptr) {
    return ptr->untag()
        ->packed_type_parameter_counts_.Read<PackedNumParentTypeArguments>();
  }
  // Return the number of type arguments in the enclosing signature.
  intptr_t NumParentTypeArguments() const {
    return NumParentTypeArgumentsOf(ptr());
  }
  void SetNumParentTypeArguments(intptr_t value) const;
  static intptr_t NumTypeParametersOf(FunctionTypePtr ptr) {
    return ptr->untag()
        ->packed_type_parameter_counts_.Read<PackedNumTypeParameters>();
  }
  intptr_t NumTypeParameters() const { return NumTypeParametersOf(ptr()); }

  static intptr_t NumTypeArgumentsOf(FunctionTypePtr ptr) {
    return NumTypeParametersOf(ptr) + NumParentTypeArgumentsOf(ptr);
  }
  intptr_t NumTypeArguments() const { return NumTypeArgumentsOf(ptr()); }

  intptr_t num_implicit_parameters() const {
    return untag()
        ->packed_parameter_counts_.Read<PackedNumImplicitParameters>();
  }
  void set_num_implicit_parameters(intptr_t value) const;

  static intptr_t NumFixedParametersOf(FunctionTypePtr ptr) {
    return ptr->untag()
        ->packed_parameter_counts_.Read<PackedNumFixedParameters>();
  }
  intptr_t num_fixed_parameters() const { return NumFixedParametersOf(ptr()); }
  void set_num_fixed_parameters(intptr_t value) const;

  static bool HasOptionalParameters(FunctionTypePtr ptr) {
    return ptr->untag()
               ->packed_parameter_counts_.Read<PackedNumOptionalParameters>() >
           0;
  }
  bool HasOptionalParameters() const { return HasOptionalParameters(ptr()); }

  static bool HasOptionalNamedParameters(FunctionTypePtr ptr) {
    return ptr->untag()
        ->packed_parameter_counts_.Read<PackedHasNamedOptionalParameters>();
  }
  bool HasOptionalNamedParameters() const {
    return HasOptionalNamedParameters(ptr());
  }
  bool HasRequiredNamedParameters() const;

  static bool HasOptionalPositionalParameters(FunctionTypePtr ptr) {
    return !HasOptionalNamedParameters(ptr) && HasOptionalParameters(ptr);
  }
  bool HasOptionalPositionalParameters() const {
    return HasOptionalPositionalParameters(ptr());
  }

  static intptr_t NumOptionalParametersOf(FunctionTypePtr ptr) {
    return ptr->untag()
        ->packed_parameter_counts_.Read<PackedNumOptionalParameters>();
  }
  intptr_t NumOptionalParameters() const {
    return NumOptionalParametersOf(ptr());
  }
  void SetNumOptionalParameters(intptr_t num_optional_parameters,
                                bool are_optional_positional) const;

  static intptr_t NumOptionalPositionalParametersOf(FunctionTypePtr ptr) {
    return HasOptionalNamedParameters(ptr) ? 0 : NumOptionalParametersOf(ptr);
  }
  intptr_t NumOptionalPositionalParameters() const {
    return NumOptionalPositionalParametersOf(ptr());
  }

  static intptr_t NumOptionalNamedParametersOf(FunctionTypePtr ptr) {
    return HasOptionalNamedParameters(ptr) ? NumOptionalParametersOf(ptr) : 0;
  }
  intptr_t NumOptionalNamedParameters() const {
    return NumOptionalNamedParametersOf(ptr());
  }

  static intptr_t NumParametersOf(FunctionTypePtr ptr) {
    return NumFixedParametersOf(ptr) + NumOptionalParametersOf(ptr);
  }
  intptr_t NumParameters() const { return NumParametersOf(ptr()); }

  uint32_t packed_parameter_counts() const {
    return untag()->packed_parameter_counts_;
  }
  void set_packed_parameter_counts(uint32_t packed_parameter_counts) const;
  static intptr_t packed_parameter_counts_offset() {
    return OFFSET_OF(UntaggedFunctionType, packed_parameter_counts_);
  }
  uint16_t packed_type_parameter_counts() const {
    return untag()->packed_type_parameter_counts_;
  }
  void set_packed_type_parameter_counts(uint16_t packed_parameter_counts) const;
  static intptr_t packed_type_parameter_counts_offset() {
    return OFFSET_OF(UntaggedFunctionType, packed_type_parameter_counts_);
  }

  // Return the type parameter declared at index.
  TypeParameterPtr TypeParameterAt(
      intptr_t index,
      Nullability nullability = Nullability::kNonNullable) const;

  AbstractTypePtr result_type() const { return untag()->result_type(); }
  void set_result_type(const AbstractType& value) const;

  // The parameters, starting with NumImplicitParameters() parameters which are
  // only visible to the VM, but not to Dart users.
  // Note that type checks exclude implicit parameters.
  AbstractTypePtr ParameterTypeAt(intptr_t index) const;
  void SetParameterTypeAt(intptr_t index, const AbstractType& value) const;
  ArrayPtr parameter_types() const { return untag()->parameter_types(); }
  void set_parameter_types(const Array& value) const;
  static intptr_t parameter_types_offset() {
    return OFFSET_OF(UntaggedFunctionType, parameter_types_);
  }
  // Parameter names are only stored for named parameters. If there are no named
  // parameters, named_parameter_names() is null.
  // If there are parameter flags (eg required) they're stored at the end of
  // this array, so the size of this array isn't necessarily
  // NumOptionalNamedParameters(), but the first NumOptionalNamedParameters()
  // elements are the names.
  ArrayPtr named_parameter_names() const {
    return untag()->named_parameter_names();
  }
  void set_named_parameter_names(const Array& value) const;
  static intptr_t named_parameter_names_offset() {
    return OFFSET_OF(UntaggedFunctionType, named_parameter_names_);
  }
  // The index for these operations is the absolute index of the parameter, not
  // the index relative to the start of the named parameters (if any).
  StringPtr ParameterNameAt(intptr_t index) const;
  // Only valid for absolute indexes of named parameters.
  void SetParameterNameAt(intptr_t index, const String& value) const;

  // The required flags are stored at the end of the parameter_names. The flags
  // are packed into SMIs, but omitted if they're 0.
  bool IsRequiredAt(intptr_t index) const;
  void SetIsRequiredAt(intptr_t index) const;

  // Sets up the signature's parameter name array, including appropriate space
  // for any possible parameter flags. This may be an overestimate if some
  // parameters don't have flags, and so FinalizeNameArray() should
  // be called after all parameter flags have been appropriately set.
  //
  // Assumes that the number of fixed and optional parameters for the signature
  // has already been set. Uses same default space as FunctionType::New.
  void CreateNameArrayIncludingFlags(Heap::Space space = Heap::kOld) const;

  // Truncate the parameter names array to remove any unused flag slots. Make
  // sure to only do this after calling SetIsRequiredAt as necessary.
  void FinalizeNameArray() const;

  // Returns the length of the parameter names array that is required to store
  // all the names plus all their flags. This may be an overestimate if some
  // parameters don't have flags.
  static intptr_t NameArrayLengthIncludingFlags(intptr_t num_parameters);

  // The formal type parameters, their bounds, and defaults, are specified as an
  // object of type TypeParameters.
  TypeParametersPtr type_parameters() const {
    return untag()->type_parameters();
  }
  void SetTypeParameters(const TypeParameters& value) const;
  static intptr_t type_parameters_offset() {
    return OFFSET_OF(UntaggedFunctionType, type_parameters_);
  }

  // Returns true if this function type has the same number of type parameters
  // with equal bounds as the other function type. Type parameter names and
  // parameter names (unless optional named) are ignored.
  bool HasSameTypeParametersAndBounds(
      const FunctionType& other,
      TypeEquality kind,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;

  // Return true if this function type declares type parameters.
  static bool IsGeneric(FunctionTypePtr ptr) {
    return ptr->untag()->type_parameters() != TypeParameters::null();
  }
  bool IsGeneric() const { return IsGeneric(ptr()); }

  // Return true if any enclosing signature of this signature is generic.
  bool HasGenericParent() const { return NumParentTypeArguments() > 0; }

  // Returns true if the type of the formal parameter at the given position in
  // this function type is contravariant with the type of the other formal
  // parameter at the given position in the other function type.
  bool IsContravariantParameter(
      intptr_t parameter_position,
      const FunctionType& other,
      intptr_t other_parameter_position,
      Heap::Space space,
      FunctionTypeMapping* function_type_equivalence) const;

  // Returns the index in the parameter names array of the corresponding flag
  // for the given parameter index. Also returns (via flag_mask) the
  // corresponding mask within the flag.
  intptr_t GetRequiredFlagIndex(intptr_t index, intptr_t* flag_mask) const;

  void Print(NameVisibility name_visibility, BaseTextBuffer* printer) const;
  void PrintParameters(Thread* thread,
                       Zone* zone,
                       NameVisibility name_visibility,
                       BaseTextBuffer* printer) const;

  StringPtr ToUserVisibleString() const;
  const char* ToUserVisibleCString() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedFunctionType));
  }

  static FunctionTypePtr New(intptr_t num_parent_type_arguments = 0,
                             Nullability nullability = Nullability::kLegacy,
                             Heap::Space space = Heap::kOld);

  static FunctionTypePtr Clone(const FunctionType& orig, Heap::Space space);

 private:
  static FunctionTypePtr New(Heap::Space space);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(FunctionType, AbstractType);
  friend class Class;
  friend class Function;
};

// A TypeParameter represents a type parameter of a parameterized class.
// It specifies its index (and its name for debugging purposes), as well as its
// upper bound.
// For example, the type parameter 'V' is specified as index 1 in the context of
// the class HashMap<K, V>. At compile time, the TypeParameter is not
// instantiated yet, i.e. it is only a place holder.
// Upon finalization, the TypeParameter index is changed to reflect its position
// as type argument (rather than type parameter) of the parameterized class.
// If the type parameter is declared without an extends clause, its bound is set
// to the ObjectType.
class TypeParameter : public AbstractType {
 public:
  TypeParameterPtr ToNullability(Nullability value, Heap::Space space) const;
  virtual bool HasTypeClass() const { return false; }
  virtual classid_t type_class_id() const { return kIllegalCid; }

  bool IsFunctionTypeParameter() const {
    return UntaggedTypeParameter::IsFunctionTypeParameter::decode(
        untag()->flags());
  }
  bool IsClassTypeParameter() const { return !IsFunctionTypeParameter(); }

  intptr_t base() const { return untag()->base_; }
  void set_base(intptr_t value) const;
  intptr_t index() const { return untag()->index_; }
  void set_index(intptr_t value) const;
  static intptr_t index_offset() {
    return OFFSET_OF(UntaggedTypeParameter, index_);
  }

  classid_t parameterized_class_id() const;
  void set_parameterized_class_id(classid_t value) const;
  ClassPtr parameterized_class() const;
  FunctionTypePtr parameterized_function_type() const;

  AbstractTypePtr bound() const;

  virtual bool IsInstantiated(
      Genericity genericity = kAny,
      intptr_t num_free_fun_type_params = kAllFree) const;
  virtual bool IsEquivalent(
      const Instance& other,
      TypeEquality kind,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;
  virtual bool RequireConstCanonicalTypeErasure(Zone* zone) const {
    return IsNonNullable();
  }
  virtual AbstractTypePtr InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping = nullptr,
      intptr_t num_parent_type_args_adjustment = 0) const;

  virtual AbstractTypePtr UpdateFunctionTypes(
      intptr_t num_parent_type_args_adjustment,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping) const;

  virtual AbstractTypePtr Canonicalize(Thread* thread) const;
  virtual void EnumerateURIs(URIs* uris) const { return; }
  virtual void PrintName(NameVisibility visibility,
                         BaseTextBuffer* printer) const;

  // Returns type corresponding to [this] type parameter from the
  // given [instantiator_type_arguments] and [function_type_arguments].
  // Unlike InstantiateFrom, nullability of type parameter is not applied to
  // the result.
  AbstractTypePtr GetFromTypeArguments(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments) const;

  // Return a constructed name for this nameless type parameter.
  const char* CanonicalNameCString() const {
    return CanonicalNameCString(IsClassTypeParameter(), base(), index());
  }

  static const char* CanonicalNameCString(bool is_class_type_parameter,
                                          intptr_t base,
                                          intptr_t index);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedTypeParameter));
  }

  // 'owner' is a Class or FunctionType.
  static TypeParameterPtr New(const Object& owner,
                              intptr_t base,
                              intptr_t index,
                              Nullability nullability);

 private:
  virtual uword ComputeHash() const;

  void set_owner(const Object& value) const;

  static TypeParameterPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypeParameter, AbstractType);
  friend class Class;
};

class Number : public Instance {
 public:
  // TODO(iposva): Add more useful Number methods.
  StringPtr ToString(Heap::Space space) const;

 private:
  OBJECT_IMPLEMENTATION(Number, Instance);

  friend class Class;
};

class Integer : public Number {
 public:
  static IntegerPtr New(const String& str, Heap::Space space = Heap::kNew);

  // Creates a new Integer by given uint64_t value.
  // Silently casts value to int64_t with wrap-around if it is greater
  // than kMaxInt64.
  static IntegerPtr NewFromUint64(uint64_t value,
                                  Heap::Space space = Heap::kNew);

  // Returns a canonical Integer object allocated in the old gen space.
  // Returns null if integer is out of range.
  static IntegerPtr NewCanonical(const String& str);
  static IntegerPtr NewCanonical(int64_t value);

  static IntegerPtr New(int64_t value, Heap::Space space = Heap::kNew);

  // Returns true iff the given uint64_t value is representable as Dart integer.
  static bool IsValueInRange(uint64_t value);

  virtual bool OperatorEquals(const Instance& other) const {
    return Equals(other);
  }
  virtual bool CanonicalizeEquals(const Instance& other) const {
    return Equals(other);
  }
  virtual uint32_t CanonicalizeHash() const;
  virtual bool Equals(const Instance& other) const;

  virtual ObjectPtr HashCode() const { return ptr(); }

  virtual bool IsZero() const;
  virtual bool IsNegative() const;

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;
  virtual int64_t AsTruncatedInt64Value() const { return AsInt64Value(); }
  virtual uint32_t AsTruncatedUint32Value() const;

  virtual bool FitsIntoSmi() const;

  // Returns 0, -1 or 1.
  virtual int CompareWith(const Integer& other) const;

  // Converts integer to hex string.
  const char* ToHexCString(Zone* zone) const;

  // Return the most compact presentation of an integer.
  IntegerPtr AsValidInteger() const;

  // Returns null to indicate that a bigint operation is required.
  IntegerPtr ArithmeticOp(Token::Kind operation,
                          const Integer& other,
                          Heap::Space space = Heap::kNew) const;
  IntegerPtr BitOp(Token::Kind operation,
                   const Integer& other,
                   Heap::Space space = Heap::kNew) const;
  IntegerPtr ShiftOp(Token::Kind operation,
                     const Integer& other,
                     Heap::Space space = Heap::kNew) const;

  static int64_t GetInt64Value(const IntegerPtr obj) {
    if (obj->IsSmi()) {
      return RawSmiValue(static_cast<const SmiPtr>(obj));
    } else {
      ASSERT(obj->IsMint());
      return static_cast<const MintPtr>(obj)->untag()->value_;
    }
  }

 private:
  OBJECT_IMPLEMENTATION(Integer, Number);
  friend class Class;
};

class Smi : public Integer {
 public:
  static constexpr intptr_t kBits = kSmiBits;
  static constexpr intptr_t kMaxValue = kSmiMax;
  static constexpr intptr_t kMinValue = kSmiMin;

  intptr_t Value() const { return RawSmiValue(ptr()); }

  virtual bool Equals(const Instance& other) const;
  virtual bool IsZero() const { return Value() == 0; }
  virtual bool IsNegative() const { return Value() < 0; }

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;
  virtual uint32_t AsTruncatedUint32Value() const;

  virtual bool FitsIntoSmi() const { return true; }

  virtual int CompareWith(const Integer& other) const;

  static intptr_t InstanceSize() { return 0; }

  static SmiPtr New(intptr_t value) {
    SmiPtr raw_smi = static_cast<SmiPtr>(
        (static_cast<uintptr_t>(value) << kSmiTagShift) | kSmiTag);
    ASSERT(RawSmiValue(raw_smi) == value);
    return raw_smi;
  }

  static ClassPtr Class();

  static intptr_t Value(const SmiPtr raw_smi) { return RawSmiValue(raw_smi); }
#if defined(DART_COMPRESSED_POINTERS)
  static intptr_t Value(const CompressedSmiPtr raw_smi) {
    return Smi::Value(static_cast<SmiPtr>(raw_smi.DecompressSmi()));
  }
#endif

  static intptr_t RawValue(intptr_t value) {
    return static_cast<intptr_t>(New(value));
  }

  static bool IsValid(int64_t value) { return compiler::target::IsSmi(value); }

  void operator=(SmiPtr value) {
    ptr_ = value;
    CHECK_HANDLE();
  }
  void operator^=(ObjectPtr value) {
    ptr_ = value;
    CHECK_HANDLE();
  }

 private:
  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  Smi() : Integer() {}
  BASE_OBJECT_IMPLEMENTATION(Smi, Integer);
  OBJECT_SERVICE_SUPPORT(Smi);
  friend class Api;  // For ValueFromRaw
  friend class Class;
  friend class Object;
  friend class ReusableSmiHandleScope;
  friend class Thread;
};

class SmiTraits : AllStatic {
 public:
  static const char* Name() { return "SmiTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    return Smi::Cast(a).Value() == Smi::Cast(b).Value();
  }

  static uword Hash(const Object& obj) { return Smi::Cast(obj).Value(); }
};

class Mint : public Integer {
 public:
  static constexpr intptr_t kBits = 63;  // 64-th bit is sign.
  static constexpr int64_t kMaxValue =
      static_cast<int64_t>(DART_2PART_UINT64_C(0x7FFFFFFF, FFFFFFFF));
  static constexpr int64_t kMinValue =
      static_cast<int64_t>(DART_2PART_UINT64_C(0x80000000, 00000000));

  int64_t value() const { return untag()->value_; }
  static intptr_t value_offset() { return OFFSET_OF(UntaggedMint, value_); }
  static int64_t Value(MintPtr mint) { return mint->untag()->value_; }

  virtual bool IsZero() const { return value() == 0; }
  virtual bool IsNegative() const { return value() < 0; }

  virtual bool Equals(const Instance& other) const;

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;
  virtual uint32_t AsTruncatedUint32Value() const;

  virtual bool FitsIntoSmi() const;

  virtual int CompareWith(const Integer& other) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedMint));
  }

 protected:
  // Only Integer::NewXXX is allowed to call Mint::NewXXX directly.
  friend class Integer;
  friend class MintMessageDeserializationCluster;

  static MintPtr New(int64_t value, Heap::Space space = Heap::kNew);

  static MintPtr NewCanonical(int64_t value);

 private:
  void set_value(int64_t value) const;

  MINT_OBJECT_IMPLEMENTATION(Mint, Integer, Integer);
  friend class Class;
  friend class Number;
};

// Class Double represents class Double in corelib_impl, which implements
// abstract class double in corelib.
class Double : public Number {
 public:
  double value() const { return untag()->value_; }
  static double Value(DoublePtr dbl) { return dbl->untag()->value_; }

  bool BitwiseEqualsToDouble(double value) const;
  virtual bool OperatorEquals(const Instance& other) const;
  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const;

  static DoublePtr New(double d, Heap::Space space = Heap::kNew);

  static DoublePtr New(const String& str, Heap::Space space = Heap::kNew);

  // Returns a canonical double object allocated in the old gen space.
  static DoublePtr NewCanonical(double d);

  // Returns a canonical double object (allocated in the old gen space) or
  // Double::null() if str points to a string that does not convert to a
  // double value.
  static DoublePtr NewCanonical(const String& str);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedDouble));
  }

  static intptr_t value_offset() { return OFFSET_OF(UntaggedDouble, value_); }

 private:
  void set_value(double value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Double, Number);
  friend class Class;
  friend class Number;
};

// TODO(http://dartbug.com/46716): Recognize Symbol in the VM.
class Symbol : public AllStatic {
 public:
  static bool IsSymbolCid(Thread* thread, classid_t class_id);

  static uint32_t CanonicalizeHash(Thread* thread, const Instance& instance);
};

// String may not be '\0' terminated.
class String : public Instance {
 public:
  static constexpr intptr_t kOneByteChar = 1;
  static constexpr intptr_t kTwoByteChar = 2;

// All strings share the same maximum element count to keep things
// simple.  We choose a value that will prevent integer overflow for
// 2 byte strings, since it is the worst case.
#if defined(HASH_IN_OBJECT_HEADER)
  static constexpr intptr_t kSizeofRawString =
      sizeof(UntaggedInstance) + kWordSize;
#else
  static constexpr intptr_t kSizeofRawString =
      sizeof(UntaggedInstance) + 2 * kWordSize;
#endif
  static constexpr intptr_t kMaxElements = kSmiMax / kTwoByteChar;

  static intptr_t HeaderSize() { return String::kSizeofRawString; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedString));
  }

  class CodePointIterator : public ValueObject {
   public:
    explicit CodePointIterator(const String& str)
        : str_(str), ch_(0), index_(-1), end_(str.Length()) {
      ASSERT(!str_.IsNull());
    }

    CodePointIterator(const String& str, intptr_t start, intptr_t length)
        : str_(str), ch_(0), index_(start - 1), end_(start + length) {
      ASSERT(start >= 0);
      ASSERT(end_ <= str.Length());
    }

    int32_t Current() const {
      ASSERT(index_ >= 0);
      ASSERT(index_ < end_);
      return ch_;
    }

    bool Next();

   private:
    const String& str_;
    int32_t ch_;
    intptr_t index_;
    intptr_t end_;
    DISALLOW_IMPLICIT_CONSTRUCTORS(CodePointIterator);
  };

  intptr_t Length() const { return LengthOf(ptr()); }
  static intptr_t LengthOf(StringPtr obj) {
    return Smi::Value(obj->untag()->length());
  }
  static intptr_t length_offset() { return OFFSET_OF(UntaggedString, length_); }

  uword Hash() const {
    uword result = GetCachedHash(ptr());
    if (result != 0) {
      return result;
    }
    result = String::Hash(*this, 0, this->Length());
    uword set_hash = SetCachedHashIfNotSet(ptr(), result);
    ASSERT(set_hash == result);
    return result;
  }

  static uword Hash(StringPtr raw);

  bool HasHash() const {
    ASSERT(Smi::New(0) == nullptr);
    return GetCachedHash(ptr()) != 0;
  }

  static intptr_t hash_offset() {
#if defined(HASH_IN_OBJECT_HEADER)
    COMPILE_ASSERT(UntaggedObject::kHashTagPos % kBitsPerByte == 0);
    return OFFSET_OF(UntaggedObject, tags_) +
           UntaggedObject::kHashTagPos / kBitsPerByte;
#else
    return OFFSET_OF(UntaggedString, hash_);
#endif
  }
  static uword Hash(const String& str, intptr_t begin_index, intptr_t len);
  static uword Hash(const char* characters, intptr_t len);
  static uword Hash(const uint16_t* characters, intptr_t len);
  static uword Hash(const int32_t* characters, intptr_t len);
  static uword HashRawSymbol(const StringPtr symbol) {
    ASSERT(symbol->untag()->IsCanonical());
    const uword result = GetCachedHash(symbol);
    ASSERT(result != 0);
    return result;
  }

  // Returns the hash of str1 + str2.
  static uword HashConcat(const String& str1, const String& str2);

  virtual ObjectPtr HashCode() const { return Integer::New(Hash()); }

  uint16_t CharAt(intptr_t index) const { return CharAt(ptr(), index); }
  static uint16_t CharAt(StringPtr str, intptr_t index);

  intptr_t CharSize() const;

  inline bool Equals(const String& str) const;

  bool Equals(const String& str,
              intptr_t begin_index,  // begin index on 'str'.
              intptr_t len) const;   // len on 'str'.

  // Compares to a '\0' terminated array of UTF-8 encoded characters.
  bool Equals(const char* cstr) const;

  // Compares to an array of Latin-1 encoded characters.
  bool EqualsLatin1(const uint8_t* characters, intptr_t len) const {
    return Equals(characters, len);
  }

  // Compares to an array of UTF-16 encoded characters.
  bool Equals(const uint16_t* characters, intptr_t len) const;

  // Compares to an array of UTF-32 encoded characters.
  bool Equals(const int32_t* characters, intptr_t len) const;

  // True iff this string equals str1 + str2.
  bool EqualsConcat(const String& str1, const String& str2) const;

  virtual bool OperatorEquals(const Instance& other) const {
    return Equals(other);
  }
  virtual bool CanonicalizeEquals(const Instance& other) const {
    return Equals(other);
  }
  virtual uint32_t CanonicalizeHash() const { return Hash(); }
  virtual bool Equals(const Instance& other) const;

  intptr_t CompareTo(const String& other) const;

  bool StartsWith(const String& other) const {
    NoSafepointScope no_safepoint;
    return StartsWith(ptr(), other.ptr());
  }
  static bool StartsWith(StringPtr str, StringPtr prefix);
  bool EndsWith(const String& other) const;

  // Strings are canonicalized using the symbol table.
  // Caller must hold IsolateGroup::constant_canonicalization_mutex_.
  virtual InstancePtr CanonicalizeLocked(Thread* thread) const;

  bool IsSymbol() const { return ptr()->untag()->IsCanonical(); }

  bool IsOneByteString() const {
    return ptr()->GetClassId() == kOneByteStringCid;
  }

  bool IsTwoByteString() const {
    return ptr()->GetClassId() == kTwoByteStringCid;
  }

  bool IsExternalOneByteString() const {
    return ptr()->GetClassId() == kExternalOneByteStringCid;
  }

  bool IsExternalTwoByteString() const {
    return ptr()->GetClassId() == kExternalTwoByteStringCid;
  }

  bool IsExternal() const {
    return IsExternalStringClassId(ptr()->GetClassId());
  }

  void* GetPeer() const;

  char* ToMallocCString() const;
  void ToUTF8(uint8_t* utf8_array, intptr_t array_len) const;
  static const char* ToCString(Thread* thread, StringPtr ptr);

  // Creates a new String object from a C string that is assumed to contain
  // UTF-8 encoded characters and '\0' is considered a termination character.
  // TODO(7123) - Rename this to FromCString(....).
  static StringPtr New(const char* cstr, Heap::Space space = Heap::kNew);

  // Creates a new String object from an array of UTF-8 encoded characters.
  static StringPtr FromUTF8(const uint8_t* utf8_array,
                            intptr_t array_len,
                            Heap::Space space = Heap::kNew);

  // Creates a new String object from an array of Latin-1 encoded characters.
  static StringPtr FromLatin1(const uint8_t* latin1_array,
                              intptr_t array_len,
                              Heap::Space space = Heap::kNew);

  // Creates a new String object from an array of UTF-16 encoded characters.
  static StringPtr FromUTF16(const uint16_t* utf16_array,
                             intptr_t array_len,
                             Heap::Space space = Heap::kNew);

  // Creates a new String object from an array of UTF-32 encoded characters.
  static StringPtr FromUTF32(const int32_t* utf32_array,
                             intptr_t array_len,
                             Heap::Space space = Heap::kNew);

  // Create a new String object from another Dart String instance.
  static StringPtr New(const String& str, Heap::Space space = Heap::kNew);

  // Creates a new External String object using the specified array of
  // UTF-8 encoded characters as the external reference.
  static StringPtr NewExternal(const uint8_t* utf8_array,
                               intptr_t array_len,
                               void* peer,
                               intptr_t external_allocation_size,
                               Dart_HandleFinalizer callback,
                               Heap::Space = Heap::kNew);

  // Creates a new External String object using the specified array of
  // UTF-16 encoded characters as the external reference.
  static StringPtr NewExternal(const uint16_t* utf16_array,
                               intptr_t array_len,
                               void* peer,
                               intptr_t external_allocation_size,
                               Dart_HandleFinalizer callback,
                               Heap::Space = Heap::kNew);

  static void Copy(const String& dst,
                   intptr_t dst_offset,
                   const uint8_t* characters,
                   intptr_t len);
  static void Copy(const String& dst,
                   intptr_t dst_offset,
                   const uint16_t* characters,
                   intptr_t len);
  static void Copy(const String& dst,
                   intptr_t dst_offset,
                   const String& src,
                   intptr_t src_offset,
                   intptr_t len);

  static StringPtr EscapeSpecialCharacters(const String& str);
  // Encodes 'str' for use in an Internationalized Resource Identifier (IRI),
  // a generalization of URI (percent-encoding). See RFC 3987.
  static const char* EncodeIRI(const String& str);
  // Returns null if 'str' is not a valid encoding.
  static StringPtr DecodeIRI(const String& str);
  static StringPtr Concat(const String& str1,
                          const String& str2,
                          Heap::Space space = Heap::kNew);
  static StringPtr ConcatAll(const Array& strings,
                             Heap::Space space = Heap::kNew);
  // Concat all strings in 'strings' from 'start' to 'end' (excluding).
  static StringPtr ConcatAllRange(const Array& strings,
                                  intptr_t start,
                                  intptr_t end,
                                  Heap::Space space = Heap::kNew);

  static StringPtr SubString(const String& str,
                             intptr_t begin_index,
                             Heap::Space space = Heap::kNew);
  static StringPtr SubString(const String& str,
                             intptr_t begin_index,
                             intptr_t length,
                             Heap::Space space = Heap::kNew) {
    return SubString(Thread::Current(), str, begin_index, length, space);
  }
  static StringPtr SubString(Thread* thread,
                             const String& str,
                             intptr_t begin_index,
                             intptr_t length,
                             Heap::Space space = Heap::kNew);

  static StringPtr Transform(int32_t (*mapping)(int32_t ch),
                             const String& str,
                             Heap::Space space = Heap::kNew);

  static StringPtr ToUpperCase(const String& str,
                               Heap::Space space = Heap::kNew);
  static StringPtr ToLowerCase(const String& str,
                               Heap::Space space = Heap::kNew);

  static StringPtr RemovePrivateKey(const String& name);

  static const char* ScrubName(const String& name, bool is_extension = false);
  static StringPtr ScrubNameRetainPrivate(const String& name,
                                          bool is_extension = false);

  static bool EqualsIgnoringPrivateKey(const String& str1, const String& str2);

  static StringPtr NewFormatted(const char* format, ...) PRINTF_ATTRIBUTE(1, 2);
  static StringPtr NewFormatted(Heap::Space space, const char* format, ...)
      PRINTF_ATTRIBUTE(2, 3);
  static StringPtr NewFormattedV(const char* format,
                                 va_list args,
                                 Heap::Space space = Heap::kNew);

  static bool ParseDouble(const String& str,
                          intptr_t start,
                          intptr_t end,
                          double* result);

#if !defined(HASH_IN_OBJECT_HEADER)
  static uint32_t GetCachedHash(const StringPtr obj) {
    return Smi::Value(obj->untag()->hash_);
  }

  static uint32_t SetCachedHashIfNotSet(StringPtr obj, uint32_t hash) {
    ASSERT(Smi::Value(obj->untag()->hash_) == 0 ||
           Smi::Value(obj->untag()->hash_) == static_cast<intptr_t>(hash));
    return SetCachedHash(obj, hash);
  }
  static uint32_t SetCachedHash(StringPtr obj, uint32_t hash) {
    obj->untag()->hash_ = Smi::New(hash);
    return hash;
  }
#else
  static uint32_t SetCachedHash(StringPtr obj, uint32_t hash) {
    return Object::SetCachedHashIfNotSet(obj, hash);
  }
#endif

 protected:
  // These two operate on an array of Latin-1 encoded characters.
  // They are protected to avoid mistaking Latin-1 for UTF-8, but used
  // by friendly templated code (e.g., Symbols).
  bool Equals(const uint8_t* characters, intptr_t len) const;
  static uword Hash(const uint8_t* characters, intptr_t len);

  void SetLength(intptr_t value) const {
    // This is only safe because we create a new Smi, which does not cause
    // heap allocation.
    untag()->set_length(Smi::New(value));
  }

  void SetHash(intptr_t value) const {
    const intptr_t hash_set = SetCachedHashIfNotSet(ptr(), value);
    ASSERT(hash_set == value);
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(String, Instance);

  friend class Class;
  friend class Symbols;
  friend class StringSlice;  // SetHash
  template <typename CharType>
  friend class CharArray;     // SetHash
  friend class ConcatString;  // SetHash
  friend class OneByteString;
  friend class TwoByteString;
  friend class ExternalOneByteString;
  friend class ExternalTwoByteString;
  friend class UntaggedOneByteString;
  friend class RODataSerializationCluster;  // SetHash
  friend class Pass2Visitor;                // Stack "handle"
};

// Synchronize with implementation in compiler (intrinsifier).
class StringHasher : public ValueObject {
 public:
  StringHasher() : hash_(0) {}
  void Add(uint16_t code_unit) { hash_ = CombineHashes(hash_, code_unit); }
  void Add(const uint8_t* code_units, intptr_t len) {
    while (len > 0) {
      Add(*code_units);
      code_units++;
      len--;
    }
  }
  void Add(const uint16_t* code_units, intptr_t len) {
    while (len > 0) {
      Add(LoadUnaligned(code_units));
      code_units++;
      len--;
    }
  }
  void Add(const String& str, intptr_t begin_index, intptr_t len);
  intptr_t Finalize() { return FinalizeHash(hash_, String::kHashBits); }

 private:
  uint32_t hash_;
};

class OneByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    ASSERT(str.IsOneByteString());
    return OneByteString::CharAt(static_cast<OneByteStringPtr>(str.ptr()),
                                 index);
  }

  static uint16_t CharAt(OneByteStringPtr str, intptr_t index) {
    ASSERT(index >= 0 && index < String::LengthOf(str));
    return str->untag()->data()[index];
  }

  static void SetCharAt(const String& str, intptr_t index, uint8_t code_unit) {
    NoSafepointScope no_safepoint;
    *CharAddr(str, index) = code_unit;
  }
  static OneByteStringPtr EscapeSpecialCharacters(const String& str);
  // We use the same maximum elements for all strings.
  static constexpr intptr_t kBytesPerElement = 1;
  static constexpr intptr_t kMaxElements = String::kMaxElements;
  static constexpr intptr_t kMaxNewSpaceElements =
      (kNewAllocatableSize - sizeof(UntaggedOneByteString)) / kBytesPerElement;

  struct ArrayTraits {
    static intptr_t elements_start_offset() {
      return sizeof(UntaggedOneByteString);
    }
    static constexpr intptr_t kElementSize = kBytesPerElement;
  };

  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(UntaggedOneByteString, data);
  }

  static intptr_t UnroundedSize(OneByteStringPtr str) {
    return UnroundedSize(Smi::Value(str->untag()->length()));
  }
  static intptr_t UnroundedSize(intptr_t len) {
    return sizeof(UntaggedOneByteString) + (len * kBytesPerElement);
  }
  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedOneByteString) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedOneByteString, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(sizeof(UntaggedOneByteString) == String::kSizeofRawString);
    ASSERT(0 <= len && len <= kMaxElements);
    return String::RoundedAllocationSize(UnroundedSize(len));
  }

  static OneByteStringPtr New(intptr_t len, Heap::Space space);
  static OneByteStringPtr New(const char* c_string,
                              Heap::Space space = Heap::kNew) {
    return New(reinterpret_cast<const uint8_t*>(c_string), strlen(c_string),
               space);
  }
  static OneByteStringPtr New(const uint8_t* characters,
                              intptr_t len,
                              Heap::Space space);
  static OneByteStringPtr New(const uint16_t* characters,
                              intptr_t len,
                              Heap::Space space);
  static OneByteStringPtr New(const int32_t* characters,
                              intptr_t len,
                              Heap::Space space);
  static OneByteStringPtr New(const String& str, Heap::Space space);
  // 'other' must be OneByteString.
  static OneByteStringPtr New(const String& other_one_byte_string,
                              intptr_t other_start_index,
                              intptr_t other_len,
                              Heap::Space space);

  static OneByteStringPtr New(const TypedDataBase& other_typed_data,
                              intptr_t other_start_index,
                              intptr_t other_len,
                              Heap::Space space = Heap::kNew);

  static OneByteStringPtr Concat(const String& str1,
                                 const String& str2,
                                 Heap::Space space);
  static OneByteStringPtr ConcatAll(const Array& strings,
                                    intptr_t start,
                                    intptr_t end,
                                    intptr_t len,
                                    Heap::Space space);

  static OneByteStringPtr Transform(int32_t (*mapping)(int32_t ch),
                                    const String& str,
                                    Heap::Space space);

  // High performance version of substring for one-byte strings.
  // "str" must be OneByteString.
  static OneByteStringPtr SubStringUnchecked(const String& str,
                                             intptr_t begin_index,
                                             intptr_t length,
                                             Heap::Space space);

  static const ClassId kClassId = kOneByteStringCid;

  static OneByteStringPtr null() {
    return static_cast<OneByteStringPtr>(Object::null());
  }

 private:
  static OneByteStringPtr raw(const String& str) {
    return static_cast<OneByteStringPtr>(str.ptr());
  }

  static const UntaggedOneByteString* untag(const String& str) {
    return reinterpret_cast<const UntaggedOneByteString*>(str.untag());
  }

  static uint8_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsOneByteString());
    return &str.UnsafeMutableNonPointer(untag(str)->data())[index];
  }

  static uint8_t* DataStart(const String& str) {
    ASSERT(str.IsOneByteString());
    return &str.UnsafeMutableNonPointer(untag(str)->data())[0];
  }

  ALLSTATIC_CONTAINS_COMPRESSED_IMPLEMENTATION(OneByteString, String);

  friend class Class;
  friend class ExternalOneByteString;
  friend class FlowGraphSerializer;
  friend class ImageWriter;
  friend class String;
  friend class StringHasher;
  friend class Symbols;
  friend class Utf8;
  friend class OneByteStringMessageSerializationCluster;
  friend class Deserializer;
  friend class JSONWriter;
};

class TwoByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    ASSERT(str.IsTwoByteString());
    return TwoByteString::CharAt(static_cast<TwoByteStringPtr>(str.ptr()),
                                 index);
  }

  static uint16_t CharAt(TwoByteStringPtr str, intptr_t index) {
    ASSERT(index >= 0 && index < String::LengthOf(str));
    return str->untag()->data()[index];
  }

  static void SetCharAt(const String& str, intptr_t index, uint16_t ch) {
    NoSafepointScope no_safepoint;
    *CharAddr(str, index) = ch;
  }

  static TwoByteStringPtr EscapeSpecialCharacters(const String& str);

  // We use the same maximum elements for all strings.
  static constexpr intptr_t kBytesPerElement = 2;
  static constexpr intptr_t kMaxElements = String::kMaxElements;
  static constexpr intptr_t kMaxNewSpaceElements =
      (kNewAllocatableSize - sizeof(UntaggedTwoByteString)) / kBytesPerElement;

  struct ArrayTraits {
    static intptr_t elements_start_offset() {
      return sizeof(UntaggedTwoByteString);
    }
    static constexpr intptr_t kElementSize = kBytesPerElement;
  };

  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(UntaggedTwoByteString, data);
  }
  static intptr_t UnroundedSize(TwoByteStringPtr str) {
    return UnroundedSize(Smi::Value(str->untag()->length()));
  }
  static intptr_t UnroundedSize(intptr_t len) {
    return sizeof(UntaggedTwoByteString) + (len * kBytesPerElement);
  }
  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedTwoByteString) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedTwoByteString, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(sizeof(UntaggedTwoByteString) == String::kSizeofRawString);
    ASSERT(0 <= len && len <= kMaxElements);
    return String::RoundedAllocationSize(UnroundedSize(len));
  }

  static TwoByteStringPtr New(intptr_t len, Heap::Space space);
  static TwoByteStringPtr New(const uint16_t* characters,
                              intptr_t len,
                              Heap::Space space);
  static TwoByteStringPtr New(intptr_t utf16_len,
                              const int32_t* characters,
                              intptr_t len,
                              Heap::Space space);
  static TwoByteStringPtr New(const String& str, Heap::Space space);

  static TwoByteStringPtr New(const TypedDataBase& other_typed_data,
                              intptr_t other_start_index,
                              intptr_t other_len,
                              Heap::Space space = Heap::kNew);

  static TwoByteStringPtr Concat(const String& str1,
                                 const String& str2,
                                 Heap::Space space);
  static TwoByteStringPtr ConcatAll(const Array& strings,
                                    intptr_t start,
                                    intptr_t end,
                                    intptr_t len,
                                    Heap::Space space);

  static TwoByteStringPtr Transform(int32_t (*mapping)(int32_t ch),
                                    const String& str,
                                    Heap::Space space);

  static TwoByteStringPtr null() {
    return static_cast<TwoByteStringPtr>(Object::null());
  }

  static const ClassId kClassId = kTwoByteStringCid;

 private:
  static TwoByteStringPtr raw(const String& str) {
    return static_cast<TwoByteStringPtr>(str.ptr());
  }

  static const UntaggedTwoByteString* untag(const String& str) {
    return reinterpret_cast<const UntaggedTwoByteString*>(str.untag());
  }

  static uint16_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsTwoByteString());
    return &str.UnsafeMutableNonPointer(untag(str)->data())[index];
  }

  // Use this instead of CharAddr(0).  It will not assert that the index is <
  // length.
  static uint16_t* DataStart(const String& str) {
    ASSERT(str.IsTwoByteString());
    return &str.UnsafeMutableNonPointer(untag(str)->data())[0];
  }

  ALLSTATIC_CONTAINS_COMPRESSED_IMPLEMENTATION(TwoByteString, String);

  friend class Class;
  friend class FlowGraphSerializer;
  friend class ImageWriter;
  friend class String;
  friend class StringHasher;
  friend class Symbols;
  friend class TwoByteStringMessageSerializationCluster;
  friend class JSONWriter;
};

class ExternalOneByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    ASSERT(str.IsExternalOneByteString());
    return ExternalOneByteString::CharAt(
        static_cast<ExternalOneByteStringPtr>(str.ptr()), index);
  }

  static uint16_t CharAt(ExternalOneByteStringPtr str, intptr_t index) {
    ASSERT(index >= 0 && index < String::LengthOf(str));
    return str->untag()->external_data_[index];
  }

  static void* GetPeer(const String& str) { return untag(str)->peer_; }

  static intptr_t external_data_offset() {
    return OFFSET_OF(UntaggedExternalOneByteString, external_data_);
  }

  // We use the same maximum elements for all strings.
  static constexpr intptr_t kBytesPerElement = 1;
  static constexpr intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    return String::RoundedAllocationSize(sizeof(UntaggedExternalOneByteString));
  }

  static ExternalOneByteStringPtr New(const uint8_t* characters,
                                      intptr_t len,
                                      void* peer,
                                      intptr_t external_allocation_size,
                                      Dart_HandleFinalizer callback,
                                      Heap::Space space);

  static ExternalOneByteStringPtr null() {
    return static_cast<ExternalOneByteStringPtr>(Object::null());
  }

  static OneByteStringPtr EscapeSpecialCharacters(const String& str);
  static OneByteStringPtr EncodeIRI(const String& str);
  static OneByteStringPtr DecodeIRI(const String& str);

  static const ClassId kClassId = kExternalOneByteStringCid;

 private:
  static ExternalOneByteStringPtr raw(const String& str) {
    return static_cast<ExternalOneByteStringPtr>(str.ptr());
  }

  static const UntaggedExternalOneByteString* untag(const String& str) {
    return reinterpret_cast<const UntaggedExternalOneByteString*>(str.untag());
  }

  static const uint8_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsExternalOneByteString());
    return &(untag(str)->external_data_[index]);
  }

  static const uint8_t* DataStart(const String& str) {
    ASSERT(str.IsExternalOneByteString());
    return untag(str)->external_data_;
  }

  static void SetExternalData(const String& str,
                              const uint8_t* data,
                              void* peer) {
    ASSERT(str.IsExternalOneByteString());
    ASSERT(!IsolateGroup::Current()->heap()->Contains(
        reinterpret_cast<uword>(data)));
    str.StoreNonPointer(&untag(str)->external_data_, data);
    str.StoreNonPointer(&untag(str)->peer_, peer);
  }

  static void Finalize(void* isolate_callback_data,
                       Dart_WeakPersistentHandle handle,
                       void* peer);

  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  ALLSTATIC_CONTAINS_COMPRESSED_IMPLEMENTATION(ExternalOneByteString, String);

  friend class Class;
  friend class String;
  friend class StringHasher;
  friend class Symbols;
  friend class Utf8;
  friend class JSONWriter;
};

class ExternalTwoByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    ASSERT(str.IsExternalTwoByteString());
    return ExternalTwoByteString::CharAt(
        static_cast<ExternalTwoByteStringPtr>(str.ptr()), index);
  }

  static uint16_t CharAt(ExternalTwoByteStringPtr str, intptr_t index) {
    ASSERT(index >= 0 && index < String::LengthOf(str));
    return str->untag()->external_data_[index];
  }

  static void* GetPeer(const String& str) { return untag(str)->peer_; }

  static intptr_t external_data_offset() {
    return OFFSET_OF(UntaggedExternalTwoByteString, external_data_);
  }

  // We use the same maximum elements for all strings.
  static constexpr intptr_t kBytesPerElement = 2;
  static constexpr intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    return String::RoundedAllocationSize(sizeof(UntaggedExternalTwoByteString));
  }

  static ExternalTwoByteStringPtr New(const uint16_t* characters,
                                      intptr_t len,
                                      void* peer,
                                      intptr_t external_allocation_size,
                                      Dart_HandleFinalizer callback,
                                      Heap::Space space = Heap::kNew);

  static ExternalTwoByteStringPtr null() {
    return static_cast<ExternalTwoByteStringPtr>(Object::null());
  }

  static const ClassId kClassId = kExternalTwoByteStringCid;

 private:
  static ExternalTwoByteStringPtr raw(const String& str) {
    return static_cast<ExternalTwoByteStringPtr>(str.ptr());
  }

  static const UntaggedExternalTwoByteString* untag(const String& str) {
    return reinterpret_cast<const UntaggedExternalTwoByteString*>(str.untag());
  }

  static const uint16_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsExternalTwoByteString());
    return &(untag(str)->external_data_[index]);
  }

  static const uint16_t* DataStart(const String& str) {
    ASSERT(str.IsExternalTwoByteString());
    return untag(str)->external_data_;
  }

  static void SetExternalData(const String& str,
                              const uint16_t* data,
                              void* peer) {
    ASSERT(str.IsExternalTwoByteString());
    ASSERT(!IsolateGroup::Current()->heap()->Contains(
        reinterpret_cast<uword>(data)));
    str.StoreNonPointer(&untag(str)->external_data_, data);
    str.StoreNonPointer(&untag(str)->peer_, peer);
  }

  static void Finalize(void* isolate_callback_data,
                       Dart_WeakPersistentHandle handle,
                       void* peer);

  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  ALLSTATIC_CONTAINS_COMPRESSED_IMPLEMENTATION(ExternalTwoByteString, String);

  friend class Class;
  friend class String;
  friend class StringHasher;
  friend class Symbols;
  friend class JSONWriter;
};

// Matches null_patch.dart / bool_patch.dart.
static constexpr intptr_t kNullIdentityHash = 2011;
static constexpr intptr_t kTrueIdentityHash = 1231;
static constexpr intptr_t kFalseIdentityHash = 1237;

// Class Bool implements Dart core class bool.
class Bool : public Instance {
 public:
  bool value() const { return untag()->value_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedBool));
  }

  static const Bool& True() { return Object::bool_true(); }

  static const Bool& False() { return Object::bool_false(); }

  static const Bool& Get(bool value) {
    return value ? Bool::True() : Bool::False();
  }

  virtual uint32_t CanonicalizeHash() const {
    return ptr() == True().ptr() ? kTrueIdentityHash : kFalseIdentityHash;
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Bool, Instance);
  friend class Class;
  friend class Object;  // To initialize the true and false values.
};

class Array : public Instance {
 public:
  // Returns `true` if we use card marking for arrays of length [array_length].
  static constexpr bool UseCardMarkingForAllocation(
      const intptr_t array_length) {
    return Array::InstanceSize(array_length) > kNewAllocatableSize;
  }

  // WB invariant restoration code only applies to arrives which have at most
  // this many elements. Consequently WB elimination code should not eliminate
  // WB on arrays of larger lengths across instructions that can cause GC.
  // Note: we also can't restore WB invariant for arrays which use card marking.
  static constexpr intptr_t kMaxLengthForWriteBarrierElimination = 8;

  intptr_t Length() const { return LengthOf(ptr()); }
  static intptr_t LengthOf(const ArrayPtr array) {
    return Smi::Value(array->untag()->length());
  }

  static intptr_t length_offset() { return OFFSET_OF(UntaggedArray, length_); }
  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(UntaggedArray, data);
  }
  static intptr_t element_offset(intptr_t index) {
    return OFFSET_OF_RETURNED_VALUE(UntaggedArray, data) +
           kBytesPerElement * index;
  }
  static intptr_t index_at_offset(intptr_t offset_in_bytes) {
    intptr_t index = (offset_in_bytes - data_offset()) / kBytesPerElement;
    ASSERT(index >= 0);
    return index;
  }

  struct ArrayTraits {
    static intptr_t elements_start_offset() { return Array::data_offset(); }

    static constexpr intptr_t kElementSize = kCompressedWordSize;
  };

  static bool Equals(ArrayPtr a, ArrayPtr b) {
    if (a == b) return true;
    if (a->IsRawNull() || b->IsRawNull()) return false;
    if (a->untag()->length() != b->untag()->length()) return false;
    if (a->untag()->type_arguments() != b->untag()->type_arguments()) {
      return false;
    }
    const intptr_t length = LengthOf(a);
    return memcmp(a->untag()->data(), b->untag()->data(),
                  kBytesPerElement * length) == 0;
  }
  bool Equals(const Array& other) const {
    NoSafepointScope scope;
    return Equals(ptr(), other.ptr());
  }

  static CompressedObjectPtr* DataOf(ArrayPtr array) {
    return array->untag()->data();
  }

  template <std::memory_order order = std::memory_order_relaxed>
  ObjectPtr At(intptr_t index) const {
    return untag()->element<order>(index);
  }
  template <std::memory_order order = std::memory_order_relaxed>
  void SetAt(intptr_t index, const Object& value) const {
    untag()->set_element<order>(index, value.ptr());
  }
  template <std::memory_order order = std::memory_order_relaxed>
  void SetAt(intptr_t index, const Object& value, Thread* thread) const {
    untag()->set_element<order>(index, value.ptr(), thread);
  }

  // Access to the array with acquire release semantics.
  ObjectPtr AtAcquire(intptr_t index) const {
    return untag()->element<std::memory_order_acquire>(index);
  }
  void SetAtRelease(intptr_t index, const Object& value) const {
    untag()->set_element<std::memory_order_release>(index, value.ptr());
  }

  bool IsImmutable() const { return ptr()->GetClassId() == kImmutableArrayCid; }

  // Position of element type in type arguments.
  static constexpr intptr_t kElementTypeTypeArgPos = 0;

  virtual TypeArgumentsPtr GetTypeArguments() const {
    return untag()->type_arguments();
  }
  virtual void SetTypeArguments(const TypeArguments& value) const {
    // An Array is raw or takes one type argument. However, its type argument
    // vector may be longer than 1 due to a type optimization reusing the type
    // argument vector of the instantiator.
    ASSERT(value.IsNull() ||
           ((value.Length() >= 1) &&
            value.IsInstantiated() /*&& value.IsCanonical()*/));
    // TODO(asiva): Values read from a message snapshot are not properly marked
    // as canonical. See for example tests/isolate/mandel_isolate_test.dart.
    StoreArrayPointer(&untag()->type_arguments_, value.ptr());
  }

  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const;

  static constexpr intptr_t kBytesPerElement = ArrayTraits::kElementSize;
  static constexpr intptr_t kMaxElements = kSmiMax / kBytesPerElement;
  static constexpr intptr_t kMaxNewSpaceElements =
      (kNewAllocatableSize - sizeof(UntaggedArray)) / kBytesPerElement;

  static intptr_t type_arguments_offset() {
    return OFFSET_OF(UntaggedArray, type_arguments_);
  }

  static constexpr bool IsValidLength(intptr_t len) {
    return 0 <= len && len <= kMaxElements;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedArray) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedArray, data));
    return 0;
  }

  static constexpr intptr_t InstanceSize(intptr_t len) {
    // Ensure that variable length data is not adding to the object length.
    ASSERT(sizeof(UntaggedArray) ==
           (sizeof(UntaggedInstance) + (2 * kBytesPerElement)));
    ASSERT(IsValidLength(len));
    return RoundedAllocationSize(sizeof(UntaggedArray) +
                                 (len * kBytesPerElement));
  }

  virtual void CanonicalizeFieldsLocked(Thread* thread) const;

  // Make the array immutable to Dart code by switching the class pointer
  // to ImmutableArray.
  void MakeImmutable() const;

  static ArrayPtr New(intptr_t len, Heap::Space space = Heap::kNew) {
    return New(kArrayCid, len, space);
  }
  // The result's type arguments and elements are GC-safe but not initialized to
  // null.
  static ArrayPtr NewUninitialized(intptr_t len,
                                   Heap::Space space = Heap::kNew) {
    return NewUninitialized(kArrayCid, len, space);
  }
  static ArrayPtr New(intptr_t len,
                      const AbstractType& element_type,
                      Heap::Space space = Heap::kNew);

  // Creates and returns a new array with 'new_length'. Copies all elements from
  // 'source' to the new array. 'new_length' must be greater than or equal to
  // 'source.Length()'. 'source' can be null.
  static ArrayPtr Grow(const Array& source,
                       intptr_t new_length,
                       Heap::Space space = Heap::kNew);

  // Truncates the array to a given length. 'new_length' must be less than
  // or equal to 'source.Length()'. The remaining unused part of the array is
  // marked as an Array object or a regular Object so that it can be traversed
  // during garbage collection.
  void Truncate(intptr_t new_length) const;

  // Return an Array object that contains all the elements currently present
  // in the specified Growable Object Array. This is done by first truncating
  // the Growable Object Array's backing array to the currently used size and
  // returning the truncated backing array.
  // The backing array of the original Growable Object Array is
  // set to an empty array.
  // If the unique parameter is false, the function is allowed to return
  // a shared Array instance.
  static ArrayPtr MakeFixedLength(const GrowableObjectArray& growable_array,
                                  bool unique = false);

  ArrayPtr Slice(intptr_t start, intptr_t count, bool with_type_argument) const;
  ArrayPtr Copy() const {
    return Slice(0, Length(), /*with_type_argument=*/true);
  }

 protected:
  static ArrayPtr New(intptr_t class_id,
                      intptr_t len,
                      Heap::Space space = Heap::kNew);
  static ArrayPtr NewUninitialized(intptr_t class_id,
                                   intptr_t len,
                                   Heap::Space space = Heap::kNew);

 private:
  CompressedObjectPtr const* ObjectAddr(intptr_t index) const {
    // TODO(iposva): Determine if we should throw an exception here.
    ASSERT((index >= 0) && (index < Length()));
    return &untag()->data()[index];
  }

  void SetLength(intptr_t value) const { untag()->set_length(Smi::New(value)); }
  void SetLengthRelease(intptr_t value) const {
    untag()->set_length<std::memory_order_release>(Smi::New(value));
  }

  template <typename type,
            std::memory_order order = std::memory_order_relaxed,
            typename value_type>
  void StoreArrayPointer(type const* addr, value_type value) const {
    ptr()->untag()->StoreArrayPointer<type, order, value_type>(addr, value);
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Array, Instance);
  friend class Class;
  friend class ImmutableArray;
  friend class Object;
  friend class String;
  friend class MessageDeserializer;
};

class ImmutableArray : public AllStatic {
 public:
  static constexpr bool ContainsCompressedPointers() {
    return Array::ContainsCompressedPointers();
  }

  static ImmutableArrayPtr New(intptr_t len, Heap::Space space = Heap::kNew);

  static const ClassId kClassId = kImmutableArrayCid;

  static intptr_t InstanceSize() { return Array::InstanceSize(); }

  static intptr_t InstanceSize(intptr_t len) {
    return Array::InstanceSize(len);
  }

 private:
  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  static ImmutableArrayPtr raw(const Array& array) {
    return static_cast<ImmutableArrayPtr>(array.ptr());
  }

  friend class Class;
};

class GrowableObjectArray : public Instance {
 public:
  intptr_t Capacity() const {
    NoSafepointScope no_safepoint;
    ASSERT(!IsNull());
    return Smi::Value(DataArray()->length());
  }
  intptr_t Length() const {
    ASSERT(!IsNull());
    return Smi::Value(untag()->length());
  }
  void SetLength(intptr_t value) const {
    // This is only safe because we create a new Smi, which does not cause
    // heap allocation.
    untag()->set_length(Smi::New(value));
  }

  ArrayPtr data() const { return untag()->data(); }
  void SetData(const Array& value) const { untag()->set_data(value.ptr()); }

  ObjectPtr At(intptr_t index) const {
    NoSafepointScope no_safepoint;
    ASSERT(!IsNull());
    ASSERT(index < Length());
    return data()->untag()->element(index);
  }
  void SetAt(intptr_t index, const Object& value) const {
    ASSERT(!IsNull());
    ASSERT(index < Length());

    // TODO(iposva): Add storing NoSafepointScope.
    data()->untag()->set_element(index, value.ptr());
  }

  void Add(const Object& value, Heap::Space space = Heap::kNew) const;

  void Grow(intptr_t new_capacity, Heap::Space space = Heap::kNew) const;
  ObjectPtr RemoveLast() const;

  virtual TypeArgumentsPtr GetTypeArguments() const {
    return untag()->type_arguments();
  }
  virtual void SetTypeArguments(const TypeArguments& value) const {
    // A GrowableObjectArray is raw or takes one type argument. However, its
    // type argument vector may be longer than 1 due to a type optimization
    // reusing the type argument vector of the instantiator.
    ASSERT(value.IsNull() || ((value.Length() >= 1) && value.IsInstantiated() &&
                              value.IsCanonical()));

    untag()->set_type_arguments(value.ptr());
  }

  // We don't expect a growable object array to be canonicalized.
  virtual bool CanonicalizeEquals(const Instance& other) const {
    UNREACHABLE();
    return false;
  }

  // We don't expect a growable object array to be canonicalized.
  virtual InstancePtr CanonicalizeLocked(Thread* thread) const {
    UNREACHABLE();
    return Instance::null();
  }

  static intptr_t type_arguments_offset() {
    return OFFSET_OF(UntaggedGrowableObjectArray, type_arguments_);
  }

  static intptr_t length_offset() {
    return OFFSET_OF(UntaggedGrowableObjectArray, length_);
  }
  static intptr_t data_offset() {
    return OFFSET_OF(UntaggedGrowableObjectArray, data_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedGrowableObjectArray));
  }

  static GrowableObjectArrayPtr New(Heap::Space space = Heap::kNew) {
    return New(kDefaultInitialCapacity, space);
  }
  static GrowableObjectArrayPtr New(intptr_t capacity,
                                    Heap::Space space = Heap::kNew);
  static GrowableObjectArrayPtr New(const Array& array,
                                    Heap::Space space = Heap::kNew);

  static SmiPtr NoSafepointLength(const GrowableObjectArrayPtr array) {
    return array->untag()->length();
  }

  static ArrayPtr NoSafepointData(const GrowableObjectArrayPtr array) {
    return array->untag()->data();
  }

 private:
  UntaggedArray* DataArray() const { return data()->untag(); }

  static constexpr int kDefaultInitialCapacity = 0;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(GrowableObjectArray, Instance);
  friend class Array;
  friend class Class;
};

class Float32x4 : public Instance {
 public:
  static Float32x4Ptr New(float value0,
                          float value1,
                          float value2,
                          float value3,
                          Heap::Space space = Heap::kNew);
  static Float32x4Ptr New(simd128_value_t value,
                          Heap::Space space = Heap::kNew);

  float x() const;
  float y() const;
  float z() const;
  float w() const;

  void set_x(float x) const;
  void set_y(float y) const;
  void set_z(float z) const;
  void set_w(float w) const;

  simd128_value_t value() const;
  void set_value(simd128_value_t value) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedFloat32x4));
  }

  static intptr_t value_offset() {
    return OFFSET_OF(UntaggedFloat32x4, value_);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Float32x4, Instance);
  friend class Class;
};

class Int32x4 : public Instance {
 public:
  static Int32x4Ptr New(int32_t value0,
                        int32_t value1,
                        int32_t value2,
                        int32_t value3,
                        Heap::Space space = Heap::kNew);
  static Int32x4Ptr New(simd128_value_t value, Heap::Space space = Heap::kNew);

  int32_t x() const;
  int32_t y() const;
  int32_t z() const;
  int32_t w() const;

  void set_x(int32_t x) const;
  void set_y(int32_t y) const;
  void set_z(int32_t z) const;
  void set_w(int32_t w) const;

  simd128_value_t value() const;
  void set_value(simd128_value_t value) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedInt32x4));
  }

  static intptr_t value_offset() { return OFFSET_OF(UntaggedInt32x4, value_); }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Int32x4, Instance);
  friend class Class;
};

class Float64x2 : public Instance {
 public:
  static Float64x2Ptr New(double value0,
                          double value1,
                          Heap::Space space = Heap::kNew);
  static Float64x2Ptr New(simd128_value_t value,
                          Heap::Space space = Heap::kNew);

  double x() const;
  double y() const;

  void set_x(double x) const;
  void set_y(double y) const;

  simd128_value_t value() const;
  void set_value(simd128_value_t value) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedFloat64x2));
  }

  static intptr_t value_offset() {
    return OFFSET_OF(UntaggedFloat64x2, value_);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Float64x2, Instance);
  friend class Class;
};

// Packed representation of record shape (number of fields and field names).
class RecordShape {
  enum {
    kNumFieldsBits = 16,
    kFieldNamesIndexBits = kSmiBits - kNumFieldsBits,
  };
  using NumFieldsBitField = BitField<intptr_t, intptr_t, 0, kNumFieldsBits>;
  using FieldNamesIndexBitField = BitField<intptr_t,
                                           intptr_t,
                                           NumFieldsBitField::kNextBit,
                                           kFieldNamesIndexBits>;

 public:
  static constexpr intptr_t kNumFieldsMask = NumFieldsBitField::mask();
  static constexpr intptr_t kMaxNumFields = kNumFieldsMask;
  static constexpr intptr_t kFieldNamesIndexMask =
      FieldNamesIndexBitField::mask();
  static constexpr intptr_t kFieldNamesIndexShift =
      FieldNamesIndexBitField::shift();
  static constexpr intptr_t kMaxFieldNamesIndex = kFieldNamesIndexMask;

  explicit RecordShape(intptr_t value) : value_(value) { ASSERT(value_ >= 0); }
  explicit RecordShape(SmiPtr smi_value) : value_(Smi::Value(smi_value)) {
    ASSERT(value_ >= 0);
  }
  RecordShape(intptr_t num_fields, intptr_t field_names_index)
      : value_(NumFieldsBitField::encode(num_fields) |
               FieldNamesIndexBitField::encode(field_names_index)) {
    ASSERT(value_ >= 0);
  }
  static RecordShape ForUnnamed(intptr_t num_fields) {
    return RecordShape(num_fields, 0);
  }

  bool HasNamedFields() const { return field_names_index() != 0; }

  intptr_t num_fields() const { return NumFieldsBitField::decode(value_); }

  intptr_t field_names_index() const {
    return FieldNamesIndexBitField::decode(value_);
  }

  SmiPtr AsSmi() const { return Smi::New(value_); }

  intptr_t AsInt() const { return value_; }

  bool operator==(const RecordShape& other) const {
    return value_ == other.value_;
  }
  bool operator!=(const RecordShape& other) const {
    return value_ != other.value_;
  }

  // Registers record shape with [num_fields] and [field_names] in the current
  // isolate group.
  static RecordShape Register(Thread* thread,
                              intptr_t num_fields,
                              const Array& field_names);

  // Retrieves an array of field names.
  ArrayPtr GetFieldNames(Thread* thread) const;

 private:
  intptr_t value_;

  DISALLOW_ALLOCATION();
};

// A RecordType represents the type of a record. It describes
// number of named and positional fields, field types and
// names of the named fields.
class RecordType : public AbstractType {
 public:
  virtual bool HasTypeClass() const { return false; }
  RecordTypePtr ToNullability(Nullability value, Heap::Space space) const;
  virtual classid_t type_class_id() const { return kIllegalCid; }
  virtual bool IsInstantiated(
      Genericity genericity = kAny,
      intptr_t num_free_fun_type_params = kAllFree) const;
  virtual bool IsEquivalent(
      const Instance& other,
      TypeEquality kind,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;
  virtual bool RequireConstCanonicalTypeErasure(Zone* zone) const;

  virtual AbstractTypePtr InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping = nullptr,
      intptr_t num_parent_type_args_adjustment = 0) const;

  virtual AbstractTypePtr UpdateFunctionTypes(
      intptr_t num_parent_type_args_adjustment,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      FunctionTypeMapping* function_type_mapping) const;

  virtual AbstractTypePtr Canonicalize(Thread* thread) const;
  virtual void EnumerateURIs(URIs* uris) const;
  virtual void PrintName(NameVisibility visibility,
                         BaseTextBuffer* printer) const;

  virtual uword ComputeHash() const;

  bool IsSubtypeOf(
      const RecordType& other,
      Heap::Space space,
      FunctionTypeMapping* function_type_equivalence = nullptr) const;

  RecordShape shape() const { return RecordShape(untag()->shape()); }

  ArrayPtr field_types() const { return untag()->field_types(); }

  AbstractTypePtr FieldTypeAt(intptr_t index) const;
  void SetFieldTypeAt(intptr_t index, const AbstractType& value) const;

  // Names of the named fields, sorted.
  ArrayPtr GetFieldNames(Thread* thread) const;

  intptr_t NumFields() const;

  void Print(NameVisibility name_visibility, BaseTextBuffer* printer) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedRecordType));
  }

  static RecordTypePtr New(RecordShape shape,
                           const Array& field_types,
                           Nullability nullability = Nullability::kLegacy,
                           Heap::Space space = Heap::kOld);

 private:
  void set_shape(RecordShape shape) const;
  void set_field_types(const Array& value) const;

  static RecordTypePtr New(Heap::Space space);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(RecordType, AbstractType);
  friend class Class;
  friend class ClassFinalizer;
  friend class Record;
};

class Record : public Instance {
 public:
  intptr_t num_fields() const { return NumFields(ptr()); }
  static intptr_t NumFields(RecordPtr ptr) {
    return RecordShape(ptr->untag()->shape()).num_fields();
  }

  RecordShape shape() const { return RecordShape(untag()->shape()); }
  static intptr_t shape_offset() { return OFFSET_OF(UntaggedRecord, shape_); }

  ObjectPtr FieldAt(intptr_t field_index) const {
    return untag()->field(field_index);
  }
  void SetFieldAt(intptr_t field_index, const Object& value) const {
    untag()->set_field(field_index, value.ptr());
  }

  static constexpr intptr_t kBytesPerElement = kCompressedWordSize;
  static constexpr intptr_t kMaxElements = RecordShape::kMaxNumFields;

  struct ArrayTraits {
    static intptr_t elements_start_offset() { return sizeof(UntaggedRecord); }
    static constexpr intptr_t kElementSize = kBytesPerElement;
  };

  static intptr_t field_offset(intptr_t index) {
    return OFFSET_OF_RETURNED_VALUE(UntaggedRecord, data) +
           kBytesPerElement * index;
  }
  static intptr_t field_index_at_offset(intptr_t offset_in_bytes) {
    const intptr_t index =
        (offset_in_bytes - OFFSET_OF_RETURNED_VALUE(UntaggedRecord, data)) /
        kBytesPerElement;
    ASSERT(index >= 0);
    return index;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedRecord) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedRecord, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t num_fields) {
    return RoundedAllocationSize(sizeof(UntaggedRecord) +
                                 (num_fields * kBytesPerElement));
  }

  static RecordPtr New(RecordShape shape, Heap::Space space = Heap::kNew);

  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const;
  virtual void CanonicalizeFieldsLocked(Thread* thread) const;

  // Returns RecordType representing runtime type of this record instance.
  // It is not created eagerly when record instance is allocated because
  // it depends on runtime types of values if its fields, which can be
  // quite expensive to query.
  RecordTypePtr GetRecordType() const;

  // Parses positional field name and return its index,
  // or -1 if [field_name] is not a valid positional field name.
  static intptr_t GetPositionalFieldIndexFromFieldName(
      const String& field_name);

  // Returns index of the field with given name, or -1
  // if such field doesn't exist.
  // Supports positional field names ("$1", "$2", etc).
  intptr_t GetFieldIndexByName(Thread* thread, const String& field_name) const;

  ArrayPtr GetFieldNames(Thread* thread) const {
    return shape().GetFieldNames(thread);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Record, Instance);
  friend class Class;
  friend class Object;
};

class PointerBase : public Instance {
 public:
  static intptr_t data_offset() {
    return OFFSET_OF(UntaggedPointerBase, data_);
  }
};

class TypedDataBase : public PointerBase {
 public:
  static intptr_t length_offset() {
    return OFFSET_OF(UntaggedTypedDataBase, length_);
  }

  SmiPtr length() const { return untag()->length(); }

  intptr_t Length() const {
    ASSERT(!IsNull());
    return Smi::Value(untag()->length());
  }

  intptr_t LengthInBytes() const {
    return ElementSizeInBytes(ptr()->GetClassId()) * Length();
  }

  TypedDataElementType ElementType() const {
    return ElementType(ptr()->GetClassId());
  }

  intptr_t ElementSizeInBytes() const {
    return element_size(ElementType(ptr()->GetClassId()));
  }

  static intptr_t ElementSizeInBytes(classid_t cid) {
    return element_size(ElementType(cid));
  }

  static TypedDataElementType ElementType(classid_t cid) {
    if (cid == kByteDataViewCid || cid == kUnmodifiableByteDataViewCid) {
      return kUint8ArrayElement;
    } else if (IsTypedDataClassId(cid)) {
      const intptr_t index =
          (cid - kTypedDataInt8ArrayCid - kTypedDataCidRemainderInternal) / 4;
      return static_cast<TypedDataElementType>(index);
    } else if (IsTypedDataViewClassId(cid)) {
      const intptr_t index =
          (cid - kTypedDataInt8ArrayCid - kTypedDataCidRemainderView) / 4;
      return static_cast<TypedDataElementType>(index);
    } else if (IsExternalTypedDataClassId(cid)) {
      const intptr_t index =
          (cid - kTypedDataInt8ArrayCid - kTypedDataCidRemainderExternal) / 4;
      return static_cast<TypedDataElementType>(index);
    } else {
      ASSERT(IsUnmodifiableTypedDataViewClassId(cid));
      const intptr_t index =
          (cid - kTypedDataInt8ArrayCid - kTypedDataCidRemainderUnmodifiable) /
          4;
      return static_cast<TypedDataElementType>(index);
    }
  }

  bool IsExternalOrExternalView() const;
  TypedDataViewPtr ViewFromTo(intptr_t start,
                              intptr_t end,
                              Heap::Space space = Heap::kNew) const;

  void* DataAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset == 0) ||
           ((byte_offset > 0) && (byte_offset < LengthInBytes())));
    return reinterpret_cast<void*>(Validate(untag()->data_) + byte_offset);
  }

#define TYPED_GETTER_SETTER(name, type)                                        \
  type Get##name(intptr_t byte_offset) const {                                 \
    ASSERT(static_cast<uintptr_t>(byte_offset) <=                              \
           static_cast<uintptr_t>(LengthInBytes()) - sizeof(type));            \
    return LoadUnaligned(                                                      \
        reinterpret_cast<type*>(untag()->data_ + byte_offset));                \
  }                                                                            \
  void Set##name(intptr_t byte_offset, type value) const {                     \
    ASSERT(static_cast<uintptr_t>(byte_offset) <=                              \
           static_cast<uintptr_t>(LengthInBytes()) - sizeof(type));            \
    StoreUnaligned(reinterpret_cast<type*>(untag()->data_ + byte_offset),      \
                   value);                                                     \
  }

  TYPED_GETTER_SETTER(Int8, int8_t)
  TYPED_GETTER_SETTER(Uint8, uint8_t)
  TYPED_GETTER_SETTER(Int16, int16_t)
  TYPED_GETTER_SETTER(Uint16, uint16_t)
  TYPED_GETTER_SETTER(Int32, int32_t)
  TYPED_GETTER_SETTER(Uint32, uint32_t)
  TYPED_GETTER_SETTER(Int64, int64_t)
  TYPED_GETTER_SETTER(Uint64, uint64_t)
  TYPED_GETTER_SETTER(Float32, float)
  TYPED_GETTER_SETTER(Float64, double)
  TYPED_GETTER_SETTER(Float32x4, simd128_value_t)
  TYPED_GETTER_SETTER(Int32x4, simd128_value_t)
  TYPED_GETTER_SETTER(Float64x2, simd128_value_t)

#undef TYPED_GETTER_SETTER

 protected:
  void SetLength(intptr_t value) const {
    ASSERT(value <= Smi::kMaxValue);
    untag()->set_length(Smi::New(value));
  }

  virtual uint8_t* Validate(uint8_t* data) const {
    return UnsafeMutableNonPointer(data);
  }

 private:
  friend class Class;

  static intptr_t element_size(intptr_t index) {
    ASSERT(0 <= index && index < kNumElementSizes);
    intptr_t size = element_size_table[index];
    ASSERT(size != 0);
    return size;
  }
  static constexpr intptr_t kNumElementSizes =
      (kTypedDataFloat64x2ArrayCid - kTypedDataInt8ArrayCid) / 4 + 1;
  static const intptr_t element_size_table[kNumElementSizes];

  HEAP_OBJECT_IMPLEMENTATION(TypedDataBase, PointerBase);
};

class TypedData : public TypedDataBase {
 public:
  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const;

#define TYPED_GETTER_SETTER(name, type)                                        \
  type Get##name(intptr_t byte_offset) const {                                 \
    ASSERT(static_cast<uintptr_t>(byte_offset) <=                              \
           static_cast<uintptr_t>(LengthInBytes()) - sizeof(type));            \
    return LoadUnaligned(                                                      \
        reinterpret_cast<const type*>(untag()->data() + byte_offset));         \
  }                                                                            \
  void Set##name(intptr_t byte_offset, type value) const {                     \
    ASSERT(static_cast<uintptr_t>(byte_offset) <=                              \
           static_cast<uintptr_t>(LengthInBytes()) - sizeof(type));            \
    return StoreUnaligned(                                                     \
        reinterpret_cast<type*>(untag()->data() + byte_offset), value);        \
  }

  TYPED_GETTER_SETTER(Int8, int8_t)
  TYPED_GETTER_SETTER(Uint8, uint8_t)
  TYPED_GETTER_SETTER(Int16, int16_t)
  TYPED_GETTER_SETTER(Uint16, uint16_t)
  TYPED_GETTER_SETTER(Int32, int32_t)
  TYPED_GETTER_SETTER(Uint32, uint32_t)
  TYPED_GETTER_SETTER(Int64, int64_t)
  TYPED_GETTER_SETTER(Uint64, uint64_t)
  TYPED_GETTER_SETTER(Float32, float)
  TYPED_GETTER_SETTER(Float64, double)
  TYPED_GETTER_SETTER(Float32x4, simd128_value_t)
  TYPED_GETTER_SETTER(Int32x4, simd128_value_t)
  TYPED_GETTER_SETTER(Float64x2, simd128_value_t)

#undef TYPED_GETTER_SETTER

  static intptr_t payload_offset() {
    return UntaggedTypedData::payload_offset();
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(UntaggedTypedData) ==
           OFFSET_OF_RETURNED_VALUE(UntaggedTypedData, internal_data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t lengthInBytes) {
    ASSERT(0 <= lengthInBytes && lengthInBytes <= kSmiMax);
    return RoundedAllocationSize(sizeof(UntaggedTypedData) + lengthInBytes);
  }

  static intptr_t MaxElements(intptr_t class_id) {
    ASSERT(IsTypedDataClassId(class_id));
    return (kSmiMax / ElementSizeInBytes(class_id));
  }

  static intptr_t MaxNewSpaceElements(intptr_t class_id) {
    ASSERT(IsTypedDataClassId(class_id));
    return (kNewAllocatableSize - sizeof(UntaggedTypedData)) /
           ElementSizeInBytes(class_id);
  }

  static TypedDataPtr New(intptr_t class_id,
                          intptr_t len,
                          Heap::Space space = Heap::kNew);

  static TypedDataPtr Grow(const TypedData& current,
                           intptr_t len,
                           Heap::Space space = Heap::kNew);

  static bool IsTypedData(const Instance& obj) {
    ASSERT(!obj.IsNull());
    intptr_t cid = obj.ptr()->GetClassId();
    return IsTypedDataClassId(cid);
  }

 protected:
  void RecomputeDataField() { ptr()->untag()->RecomputeDataField(); }

 private:
  // Provides const access to non-pointer, non-aligned data within the object.
  // Such access does not need a write barrier, but it is *not* GC-safe, since
  // the object might move.
  //
  // Therefore this method is private and the call-sites in this class need to
  // ensure the returned pointer does not escape.
  template <typename FieldType>
  const FieldType* ReadOnlyDataAddr(intptr_t byte_offset) const {
    return reinterpret_cast<const FieldType*>((untag()->data()) + byte_offset);
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypedData, TypedDataBase);
  friend class Class;
  friend class ExternalTypedData;
  friend class TypedDataView;
};

class ExternalTypedData : public TypedDataBase {
 public:
  // Alignment of data when serializing ExternalTypedData in a clustered
  // snapshot. Should be independent of word size.
  static constexpr int kDataSerializationAlignment = 8;

  FinalizablePersistentHandle* AddFinalizer(void* peer,
                                            Dart_HandleFinalizer callback,
                                            intptr_t external_size) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedExternalTypedData));
  }

  static intptr_t MaxElements(intptr_t class_id) {
    ASSERT(IsExternalTypedDataClassId(class_id));
    return (kSmiMax / ElementSizeInBytes(class_id));
  }

  static ExternalTypedDataPtr New(
      intptr_t class_id,
      uint8_t* data,
      intptr_t len,
      Heap::Space space = Heap::kNew,
      bool perform_eager_msan_initialization_check = true);

  static ExternalTypedDataPtr NewFinalizeWithFree(uint8_t* data, intptr_t len);

  static bool IsExternalTypedData(const Instance& obj) {
    ASSERT(!obj.IsNull());
    intptr_t cid = obj.ptr()->GetClassId();
    return IsExternalTypedDataClassId(cid);
  }

 protected:
  virtual uint8_t* Validate(uint8_t* data) const { return data; }

  void SetLength(intptr_t value) const {
    ASSERT(value <= Smi::kMaxValue);
    untag()->set_length(Smi::New(value));
  }

  void SetData(uint8_t* data) const {
    ASSERT(!IsolateGroup::Current()->heap()->Contains(
        reinterpret_cast<uword>(data)));
    StoreNonPointer(&untag()->data_, data);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(ExternalTypedData, TypedDataBase);
  friend class Class;
};

class TypedDataView : public TypedDataBase {
 public:
  static TypedDataViewPtr New(intptr_t class_id,
                              Heap::Space space = Heap::kNew);
  static TypedDataViewPtr New(intptr_t class_id,
                              const TypedDataBase& typed_data,
                              intptr_t offset_in_bytes,
                              intptr_t length,
                              Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedTypedDataView));
  }

  static InstancePtr Data(const TypedDataView& view) {
    return view.typed_data();
  }

  static SmiPtr OffsetInBytes(const TypedDataView& view) {
    return view.offset_in_bytes();
  }

  static bool IsExternalTypedDataView(const TypedDataView& view_obj) {
    const auto& data = Instance::Handle(Data(view_obj));
    intptr_t cid = data.ptr()->GetClassId();
    ASSERT(IsTypedDataClassId(cid) || IsExternalTypedDataClassId(cid));
    return IsExternalTypedDataClassId(cid);
  }

  static intptr_t typed_data_offset() {
    return OFFSET_OF(UntaggedTypedDataView, typed_data_);
  }

  static intptr_t offset_in_bytes_offset() {
    return OFFSET_OF(UntaggedTypedDataView, offset_in_bytes_);
  }

  TypedDataBasePtr typed_data() const { return untag()->typed_data(); }

  void InitializeWith(const TypedDataBase& typed_data,
                      intptr_t offset_in_bytes,
                      intptr_t length) {
    const classid_t cid = typed_data.GetClassId();
    ASSERT(IsTypedDataClassId(cid) || IsExternalTypedDataClassId(cid));
    untag()->set_typed_data(typed_data.ptr());
    untag()->set_length(Smi::New(length));
    untag()->set_offset_in_bytes(Smi::New(offset_in_bytes));

    // Update the inner pointer.
    RecomputeDataField();
  }

  SmiPtr offset_in_bytes() const { return untag()->offset_in_bytes(); }

 protected:
  virtual uint8_t* Validate(uint8_t* data) const { return data; }

 private:
  void RecomputeDataField() { ptr()->untag()->RecomputeDataField(); }

  void Clear() {
    untag()->set_length(Smi::New(0));
    untag()->set_offset_in_bytes(Smi::New(0));
    StoreNonPointer(&untag()->data_, nullptr);
    untag()->set_typed_data(TypedDataBase::RawCast(Object::null()));
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypedDataView, TypedDataBase);
  friend class Class;
  friend class Object;
  friend class TypedDataViewDeserializationCluster;
};

class ByteBuffer : public AllStatic {
 public:
  static constexpr bool ContainsCompressedPointers() {
    return Instance::ContainsCompressedPointers();
  }

  static InstancePtr Data(const Instance& view_obj) {
    ASSERT(!view_obj.IsNull());
    return reinterpret_cast<CompressedInstancePtr*>(
               reinterpret_cast<uword>(view_obj.untag()) + data_offset())
        ->Decompress(view_obj.untag()->heap_base());
  }

  static intptr_t NumberOfFields() { return kNumFields; }

  static intptr_t data_offset() {
    return sizeof(UntaggedObject) + (kCompressedWordSize * kDataIndex);
  }

 private:
  enum {
    kDataIndex = 0,
    kNumFields = 1,
  };
};

class Pointer : public Instance {
 public:
  static PointerPtr New(uword native_address, Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedPointer));
  }

  static bool IsPointer(const Instance& obj);

  size_t NativeAddress() const {
    return reinterpret_cast<size_t>(untag()->data_);
  }

  void SetNativeAddress(size_t address) const {
    uint8_t* value = reinterpret_cast<uint8_t*>(address);
    StoreNonPointer(&untag()->data_, value);
  }

  static intptr_t type_arguments_offset() {
    return OFFSET_OF(UntaggedPointer, type_arguments_);
  }

  static constexpr intptr_t kNativeTypeArgPos = 0;

  // Fetches the NativeType type argument.
  AbstractTypePtr type_argument() const {
    TypeArguments& type_args = TypeArguments::Handle(GetTypeArguments());
    return type_args.TypeAtNullSafe(Pointer::kNativeTypeArgPos);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Pointer, Instance);

  friend class Class;
};

class DynamicLibrary : public Instance {
 public:
  static DynamicLibraryPtr New(void* handle,
                               bool canBeClosed,
                               Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedDynamicLibrary));
  }

  static bool IsDynamicLibrary(const Instance& obj) {
    ASSERT(!obj.IsNull());
    intptr_t cid = obj.ptr()->GetClassId();
    return IsFfiDynamicLibraryClassId(cid);
  }

  void* GetHandle() const {
    ASSERT(!IsNull());
    return untag()->handle_;
  }

  void SetHandle(void* value) const {
    StoreNonPointer(&untag()->handle_, value);
  }

  bool CanBeClosed() const {
    ASSERT(!IsNull());
    return untag()->canBeClosed_;
  }

  void SetCanBeClosed(bool value) const {
    ASSERT(!IsNull());
    StoreNonPointer(&untag()->canBeClosed_, value);
  }

  bool IsClosed() const {
    ASSERT(!IsNull());
    return untag()->isClosed_;
  }

  void SetClosed(bool value) const {
    StoreNonPointer(&untag()->isClosed_, value);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(DynamicLibrary, Instance);

  friend class Class;
};

class LinkedHashBase : public Instance {
 public:
  // Keep consistent with _indexSizeToHashMask in compact_hash.dart.
  static intptr_t IndexSizeToHashMask(intptr_t index_size) {
    ASSERT(index_size >= kInitialIndexSize);
    intptr_t index_bits = Utils::BitLength(index_size) - 2;
#if defined(HAS_SMI_63_BITS)
    return (1 << (32 - index_bits)) - 1;
#else
    return (1 << (Object::kHashBits - index_bits)) - 1;
#endif
  }
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedLinkedHashBase));
  }

  static intptr_t type_arguments_offset() {
    return OFFSET_OF(UntaggedLinkedHashBase, type_arguments_);
  }

  static intptr_t index_offset() {
    return OFFSET_OF(UntaggedLinkedHashBase, index_);
  }

  static intptr_t data_offset() {
    return OFFSET_OF(UntaggedLinkedHashBase, data_);
  }

  static intptr_t hash_mask_offset() {
    return OFFSET_OF(UntaggedLinkedHashBase, hash_mask_);
  }

  static intptr_t used_data_offset() {
    return OFFSET_OF(UntaggedLinkedHashBase, used_data_);
  }

  static intptr_t deleted_keys_offset() {
    return OFFSET_OF(UntaggedLinkedHashBase, deleted_keys_);
  }

  static const LinkedHashBase& Cast(const Object& obj) {
    ASSERT(obj.IsMap() || obj.IsSet());
    return static_cast<const LinkedHashBase&>(obj);
  }

  bool IsImmutable() const {
    return GetClassId() == kConstMapCid || GetClassId() == kConstSetCid;
  }

  virtual TypeArgumentsPtr GetTypeArguments() const {
    return untag()->type_arguments();
  }
  virtual void SetTypeArguments(const TypeArguments& value) const {
    const intptr_t num_type_args = IsMap() ? 2 : 1;
    ASSERT(value.IsNull() ||
           ((value.Length() >= num_type_args) &&
            value.IsInstantiated() /*&& value.IsCanonical()*/));
    // TODO(asiva): Values read from a message snapshot are not properly marked
    // as canonical. See for example tests/isolate/message3_test.dart.
    untag()->set_type_arguments(value.ptr());
  }

  TypedDataPtr index() const { return untag()->index(); }
  void set_index(const TypedData& value) const {
    ASSERT(!value.IsNull());
    untag()->set_index(value.ptr());
  }

  ArrayPtr data() const { return untag()->data(); }
  void set_data(const Array& value) const { untag()->set_data(value.ptr()); }

  SmiPtr hash_mask() const { return untag()->hash_mask(); }
  void set_hash_mask(intptr_t value) const {
    untag()->set_hash_mask(Smi::New(value));
  }

  SmiPtr used_data() const { return untag()->used_data(); }
  void set_used_data(intptr_t value) const {
    untag()->set_used_data(Smi::New(value));
  }

  SmiPtr deleted_keys() const { return untag()->deleted_keys(); }
  void set_deleted_keys(intptr_t value) const {
    untag()->set_deleted_keys(Smi::New(value));
  }

  intptr_t Length() const {
    // The map or set may be uninitialized.
    if (untag()->used_data() == Object::null()) return 0;
    if (untag()->deleted_keys() == Object::null()) return 0;

    intptr_t used = Smi::Value(untag()->used_data());
    if (IsMap()) {
      used >>= 1;
    }
    const intptr_t deleted = Smi::Value(untag()->deleted_keys());
    return used - deleted;
  }

  // We do not compute the indices in the VM, but we do precompute the hash
  // mask to avoid a load acquire barrier on reading the combination of index
  // and hash mask.
  void ComputeAndSetHashMask() const;

  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const;
  virtual void CanonicalizeFieldsLocked(Thread* thread) const;

 protected:
  // Keep this in sync with Dart implementation (lib/compact_hash.dart).
  static constexpr intptr_t kInitialIndexBits = 2;
  static constexpr intptr_t kInitialIndexSize = 1 << (kInitialIndexBits + 1);

 private:
  LinkedHashBasePtr ptr() const { return static_cast<LinkedHashBasePtr>(ptr_); }
  UntaggedLinkedHashBase* untag() const {
    ASSERT(ptr() != null());
    return const_cast<UntaggedLinkedHashBase*>(ptr()->untag());
  }

  friend class Class;
  friend class ImmutableLinkedHashBase;
  friend class LinkedHashBaseDeserializationCluster;
};

class ImmutableLinkedHashBase : public AllStatic {
 public:
  static constexpr bool ContainsCompressedPointers() {
    return LinkedHashBase::ContainsCompressedPointers();
  }

  static intptr_t data_offset() { return LinkedHashBase::data_offset(); }
};

// Corresponds to
// - _Map in dart:collection
// - "new Map()",
// - non-const map literals, and
// - the default constructor of LinkedHashMap in dart:collection.
class Map : public LinkedHashBase {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedMap));
  }

  // Allocates a map with some default capacity, just like "new Map()".
  static MapPtr NewDefault(intptr_t class_id = kMapCid,
                           Heap::Space space = Heap::kNew);
  static MapPtr New(intptr_t class_id,
                    const Array& data,
                    const TypedData& index,
                    intptr_t hash_mask,
                    intptr_t used_data,
                    intptr_t deleted_keys,
                    Heap::Space space = Heap::kNew);

  // This iterator differs somewhat from its Dart counterpart (_CompactIterator
  // in runtime/lib/compact_hash.dart):
  //  - There are no checks for concurrent modifications.
  //  - Accessing a key or value before the first call to MoveNext and after
  //    MoveNext returns false will result in crashes.
  class Iterator : public ValueObject {
   public:
    explicit Iterator(const Map& map)
        : data_(Array::Handle(map.data())),
          scratch_(Object::Handle()),
          offset_(-2),
          length_(Smi::Value(map.used_data())) {}

    bool MoveNext() {
      while (true) {
        offset_ += 2;
        if (offset_ >= length_) {
          return false;
        }
        scratch_ = data_.At(offset_);
        if (scratch_.ptr() != data_.ptr()) {
          // Slot is not deleted (self-reference indicates deletion).
          return true;
        }
      }
    }

    ObjectPtr CurrentKey() const { return data_.At(offset_); }

    ObjectPtr CurrentValue() const { return data_.At(offset_ + 1); }

   private:
    const Array& data_;
    Object& scratch_;
    intptr_t offset_;
    const intptr_t length_;
  };

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Map, LinkedHashBase);

  // Allocate a map, but leave all fields set to null.
  // Used during deserialization (since map might contain itself as key/value).
  static MapPtr NewUninitialized(intptr_t class_id,
                                 Heap::Space space = Heap::kNew);

  friend class Class;
  friend class ConstMap;
  friend class MapDeserializationCluster;
};

// Corresponds to
// - _ConstMap in dart:collection
// - const map literals
class ConstMap : public AllStatic {
 public:
  static constexpr bool ContainsCompressedPointers() {
    return Map::ContainsCompressedPointers();
  }

  static ConstMapPtr NewDefault(Heap::Space space = Heap::kNew);

  static ConstMapPtr NewUninitialized(Heap::Space space = Heap::kNew);

  static const ClassId kClassId = kConstMapCid;

  static intptr_t InstanceSize() { return Map::InstanceSize(); }

 private:
  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  static ConstMapPtr raw(const Map& map) {
    return static_cast<ConstMapPtr>(map.ptr());
  }

  friend class Class;
};

// Corresponds to
// - _Set in dart:collection,
// - "new Set()",
// - non-const set literals, and
// - the default constructor of LinkedHashSet in dart:collection.
class Set : public LinkedHashBase {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedSet));
  }

  // Allocates a set with some default capacity, just like "new Set()".
  static SetPtr NewDefault(intptr_t class_id = kSetCid,
                           Heap::Space space = Heap::kNew);
  static SetPtr New(intptr_t class_id,
                    const Array& data,
                    const TypedData& index,
                    intptr_t hash_mask,
                    intptr_t used_data,
                    intptr_t deleted_keys,
                    Heap::Space space = Heap::kNew);

  // This iterator differs somewhat from its Dart counterpart (_CompactIterator
  // in runtime/lib/compact_hash.dart):
  //  - There are no checks for concurrent modifications.
  //  - Accessing a key or value before the first call to MoveNext and after
  //    MoveNext returns false will result in crashes.
  class Iterator : public ValueObject {
   public:
    explicit Iterator(const Set& set)
        : data_(Array::Handle(set.data())),
          scratch_(Object::Handle()),
          offset_(-1),
          length_(Smi::Value(set.used_data())) {}

    bool MoveNext() {
      while (true) {
        offset_++;
        if (offset_ >= length_) {
          return false;
        }
        scratch_ = data_.At(offset_);
        if (scratch_.ptr() != data_.ptr()) {
          // Slot is not deleted (self-reference indicates deletion).
          return true;
        }
      }
    }

    ObjectPtr CurrentKey() const { return data_.At(offset_); }

   private:
    const Array& data_;
    Object& scratch_;
    intptr_t offset_;
    const intptr_t length_;
  };

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Set, LinkedHashBase);

  // Allocate a set, but leave all fields set to null.
  // Used during deserialization (since set might contain itself as key/value).
  static SetPtr NewUninitialized(intptr_t class_id,
                                 Heap::Space space = Heap::kNew);

  friend class Class;
  friend class ConstSet;
  friend class SetDeserializationCluster;
};

// Corresponds to
// - _ConstSet in dart:collection
// - const set literals
class ConstSet : public AllStatic {
 public:
  static constexpr bool ContainsCompressedPointers() {
    return Set::ContainsCompressedPointers();
  }

  static ConstSetPtr NewDefault(Heap::Space space = Heap::kNew);

  static ConstSetPtr NewUninitialized(Heap::Space space = Heap::kNew);

  static const ClassId kClassId = kConstSetCid;

  static intptr_t InstanceSize() { return Set::InstanceSize(); }

 private:
  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  static ConstSetPtr raw(const Set& map) {
    return static_cast<ConstSetPtr>(map.ptr());
  }

  friend class Class;
};

class Closure : public Instance {
 public:
#if defined(DART_PRECOMPILED_RUNTIME)
  uword entry_point() const { return untag()->entry_point_; }
  void set_entry_point(uword entry_point) const {
    StoreNonPointer(&untag()->entry_point_, entry_point);
  }
  static intptr_t entry_point_offset() {
    return OFFSET_OF(UntaggedClosure, entry_point_);
  }
#endif

  TypeArgumentsPtr instantiator_type_arguments() const {
    return untag()->instantiator_type_arguments();
  }
  void set_instantiator_type_arguments(const TypeArguments& args) const {
    untag()->set_instantiator_type_arguments(args.ptr());
  }
  static intptr_t instantiator_type_arguments_offset() {
    return OFFSET_OF(UntaggedClosure, instantiator_type_arguments_);
  }

  TypeArgumentsPtr function_type_arguments() const {
    return untag()->function_type_arguments();
  }
  void set_function_type_arguments(const TypeArguments& args) const {
    untag()->set_function_type_arguments(args.ptr());
  }
  static intptr_t function_type_arguments_offset() {
    return OFFSET_OF(UntaggedClosure, function_type_arguments_);
  }

  TypeArgumentsPtr delayed_type_arguments() const {
    return untag()->delayed_type_arguments();
  }
  void set_delayed_type_arguments(const TypeArguments& args) const {
    untag()->set_delayed_type_arguments(args.ptr());
  }
  static intptr_t delayed_type_arguments_offset() {
    return OFFSET_OF(UntaggedClosure, delayed_type_arguments_);
  }

  FunctionPtr function() const { return untag()->function(); }
  static intptr_t function_offset() {
    return OFFSET_OF(UntaggedClosure, function_);
  }
  static FunctionPtr FunctionOf(ClosurePtr closure) {
    return closure.untag()->function();
  }

  ContextPtr context() const { return untag()->context(); }
  static intptr_t context_offset() {
    return OFFSET_OF(UntaggedClosure, context_);
  }
  static ContextPtr ContextOf(ClosurePtr closure) {
    return closure.untag()->context();
  }

  // Returns whether the closure is generic, that is, it has a generic closure
  // function and no delayed type arguments.
  bool IsGeneric() const {
    return delayed_type_arguments() == Object::empty_type_arguments().ptr();
  }

  SmiPtr hash() const { return untag()->hash(); }
  static intptr_t hash_offset() { return OFFSET_OF(UntaggedClosure, hash_); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedClosure));
  }

  virtual void CanonicalizeFieldsLocked(Thread* thread) const;
  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const {
    return Function::Handle(function()).Hash();
  }
  uword ComputeHash() const;

  static ClosurePtr New(const TypeArguments& instantiator_type_arguments,
                        const TypeArguments& function_type_arguments,
                        const Function& function,
                        const Context& context,
                        Heap::Space space = Heap::kNew);

  static ClosurePtr New(const TypeArguments& instantiator_type_arguments,
                        const TypeArguments& function_type_arguments,
                        const TypeArguments& delayed_type_arguments,
                        const Function& function,
                        const Context& context,
                        Heap::Space space = Heap::kNew);

  FunctionTypePtr GetInstantiatedSignature(Zone* zone) const;

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Closure, Instance);
  friend class Class;
};

// Corresponds to _Capability in dart:isolate.
class Capability : public Instance {
 public:
  uint64_t Id() const { return untag()->id_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedCapability));
  }
  static CapabilityPtr New(uint64_t id, Heap::Space space = Heap::kNew);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Capability, Instance);
  friend class Class;
};

// Corresponds to _RawReceivePort in dart:isolate.
class ReceivePort : public Instance {
 public:
  SendPortPtr send_port() const { return untag()->send_port(); }
  static intptr_t send_port_offset() {
    return OFFSET_OF(UntaggedReceivePort, send_port_);
  }
  Dart_Port Id() const { return send_port()->untag()->id_; }

  InstancePtr handler() const { return untag()->handler(); }
  void set_handler(const Instance& value) const {
    untag()->set_handler(value.ptr());
  }
  static intptr_t handler_offset() {
    return OFFSET_OF(UntaggedReceivePort, handler_);
  }

  bool is_open() const {
    return IsOpen::decode(Smi::Value(untag()->bitfield()));
  }
  void set_is_open(bool value) const {
    const auto updated = IsOpen::update(value, Smi::Value(untag()->bitfield()));
    untag()->set_bitfield(Smi::New(updated));
  }

  bool keep_isolate_alive() const {
    return IsKeepIsolateAlive::decode(Smi::Value(untag()->bitfield()));
  }
  void set_keep_isolate_alive(bool value) const {
    const auto updated =
        IsKeepIsolateAlive::update(value, Smi::Value(untag()->bitfield()));
    untag()->set_bitfield(Smi::New(updated));
  }

#if !defined(PRODUCT)
  StackTracePtr allocation_location() const {
    return untag()->allocation_location();
  }

  StringPtr debug_name() const { return untag()->debug_name(); }
#endif

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedReceivePort));
  }
  static ReceivePortPtr New(Dart_Port id,
                            const String& debug_name,
                            Heap::Space space = Heap::kNew);

 private:
  class IsOpen : public BitField<intptr_t, bool, 0, 1> {};
  class IsKeepIsolateAlive
      : public BitField<intptr_t, bool, IsOpen::kNextBit, 1> {};

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ReceivePort, Instance);
  friend class Class;
};

// Corresponds to _SendPort in dart:isolate.
class SendPort : public Instance {
 public:
  Dart_Port Id() const { return untag()->id_; }

  Dart_Port origin_id() const { return untag()->origin_id_; }
  void set_origin_id(Dart_Port id) const {
    ASSERT(origin_id() == 0);
    StoreNonPointer(&(untag()->origin_id_), id);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedSendPort));
  }
  static SendPortPtr New(Dart_Port id, Heap::Space space = Heap::kNew);
  static SendPortPtr New(Dart_Port id,
                         Dart_Port origin_id,
                         Heap::Space space = Heap::kNew);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(SendPort, Instance);
  friend class Class;
};

// This is allocated when new instance of TransferableTypedData is created in
// [TransferableTypedData::New].
class TransferableTypedDataPeer {
 public:
  // [data] backing store should be malloc'ed, not new'ed.
  TransferableTypedDataPeer(uint8_t* data, intptr_t length)
      : data_(data), length_(length), handle_(nullptr) {}

  ~TransferableTypedDataPeer() { free(data_); }

  uint8_t* data() const { return data_; }
  intptr_t length() const { return length_; }
  FinalizablePersistentHandle* handle() const { return handle_; }
  void set_handle(FinalizablePersistentHandle* handle) { handle_ = handle; }

  void ClearData() {
    data_ = nullptr;
    length_ = 0;
    handle_ = nullptr;
  }

 private:
  uint8_t* data_;
  intptr_t length_;
  FinalizablePersistentHandle* handle_;

  DISALLOW_COPY_AND_ASSIGN(TransferableTypedDataPeer);
};

class TransferableTypedData : public Instance {
 public:
  static TransferableTypedDataPtr New(uint8_t* data, intptr_t len);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedTransferableTypedData));
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(TransferableTypedData, Instance);
  friend class Class;
};

class DebuggerStackTrace;

// Internal stacktrace object used in exceptions for printing stack traces.
class StackTrace : public Instance {
 public:
  static constexpr int kPreallocatedStackdepth = 90;

  intptr_t Length() const;

  StackTracePtr async_link() const { return untag()->async_link(); }
  void set_async_link(const StackTrace& async_link) const;
  void set_expand_inlined(bool value) const;

  ArrayPtr code_array() const { return untag()->code_array(); }
  ObjectPtr CodeAtFrame(intptr_t frame_index) const;
  void SetCodeAtFrame(intptr_t frame_index, const Object& code) const;

  TypedDataPtr pc_offset_array() const { return untag()->pc_offset_array(); }
  uword PcOffsetAtFrame(intptr_t frame_index) const;
  void SetPcOffsetAtFrame(intptr_t frame_index, uword pc_offset) const;

  bool skip_sync_start_in_parent_stack() const;
  void set_skip_sync_start_in_parent_stack(bool value) const;

  // The number of frames that should be cut off the top of an async stack trace
  // if it's appended to a synchronous stack trace along a sync-async call.
  //
  // Without cropping, the border would look like:
  //
  // <async function>
  // ---------------------------
  // <asynchronous gap marker>
  // <async function>
  //
  // Since it's not actually an async call, we crop off the last two
  // frames when concatenating the sync and async stacktraces.
  static constexpr intptr_t kSyncAsyncCroppedFrames = 2;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedStackTrace));
  }
  static StackTracePtr New(const Array& code_array,
                           const TypedData& pc_offset_array,
                           Heap::Space space = Heap::kNew);

  static StackTracePtr New(const Array& code_array,
                           const TypedData& pc_offset_array,
                           const StackTrace& async_link,
                           bool skip_sync_start_in_parent_stack,
                           Heap::Space space = Heap::kNew);

 private:
  void set_code_array(const Array& code_array) const;
  void set_pc_offset_array(const TypedData& pc_offset_array) const;
  bool expand_inlined() const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(StackTrace, Instance);
  friend class Class;
  friend class DebuggerStackTrace;
};

class SuspendState : public Instance {
 public:
  // :suspend_state local variable index
  static constexpr intptr_t kSuspendStateVarIndex = 0;

  static intptr_t HeaderSize() { return sizeof(UntaggedSuspendState); }
  static intptr_t UnroundedSize(SuspendStatePtr ptr) {
    return UnroundedSize(ptr->untag()->frame_capacity());
  }
  static intptr_t UnroundedSize(intptr_t frame_capacity) {
    return HeaderSize() + frame_capacity;
  }
  static intptr_t InstanceSize() {
    ASSERT_EQUAL(sizeof(UntaggedSuspendState),
                 OFFSET_OF_RETURNED_VALUE(UntaggedSuspendState, payload));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t frame_capacity) {
    return RoundedAllocationSize(UnroundedSize(frame_capacity));
  }

  // Number of extra words reserved for growth of frame size
  // during SuspendState allocation. Frames do not grow in AOT.
  static intptr_t FrameSizeGrowthGap() {
    return ONLY_IN_PRECOMPILED(0) NOT_IN_PRECOMPILED(2);
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  static intptr_t frame_capacity_offset() {
    return OFFSET_OF(UntaggedSuspendState, frame_capacity_);
  }
#endif
  static intptr_t frame_size_offset() {
    return OFFSET_OF(UntaggedSuspendState, frame_size_);
  }
  static intptr_t pc_offset() { return OFFSET_OF(UntaggedSuspendState, pc_); }
  static intptr_t function_data_offset() {
    return OFFSET_OF(UntaggedSuspendState, function_data_);
  }
  static intptr_t then_callback_offset() {
    return OFFSET_OF(UntaggedSuspendState, then_callback_);
  }
  static intptr_t error_callback_offset() {
    return OFFSET_OF(UntaggedSuspendState, error_callback_);
  }
  static intptr_t payload_offset() {
    return UntaggedSuspendState::payload_offset();
  }

  static SuspendStatePtr New(intptr_t frame_size,
                             const Instance& function_data,
                             Heap::Space space = Heap::kNew);

  // Makes a copy of [src] object.
  // The object should be holding a suspended frame.
  static SuspendStatePtr Clone(Thread* thread,
                               const SuspendState& src,
                               Heap::Space space = Heap::kNew);

  uword pc() const { return untag()->pc_; }

  intptr_t frame_size() const { return untag()->frame_size_; }

  InstancePtr function_data() const {
    return untag()->function_data();
  }

  ClosurePtr then_callback() const { return untag()->then_callback(); }

  ClosurePtr error_callback() const {
    return untag()->error_callback();
  }

  // Returns Code object corresponding to the suspended function.
  CodePtr GetCodeObject() const;

 private:
#if !defined(DART_PRECOMPILED_RUNTIME)
  void set_frame_capacity(intptr_t frame_capcity) const;
#endif
  void set_frame_size(intptr_t frame_size) const;
  void set_pc(uword pc) const;
  void set_function_data(const Instance& function_data) const;
  void set_then_callback(const Closure& then_callback) const;
  void set_error_callback(const Closure& error_callback) const;

  uint8_t* payload() const { return untag()->payload(); }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(SuspendState, Instance);
  friend class Class;
};

class RegExpFlags {
 public:
  // Flags are passed to a regex object as follows:
  // 'i': ignore case, 'g': do global matches, 'm': pattern is multi line,
  // 'u': pattern is full Unicode, not just BMP, 's': '.' in pattern matches
  // all characters including line terminators.
  enum Flags {
    kNone = 0,
    kGlobal = 1,
    kIgnoreCase = 2,
    kMultiLine = 4,
    kUnicode = 8,
    kDotAll = 16,
  };

  static constexpr int kDefaultFlags = 0;

  RegExpFlags() : value_(kDefaultFlags) {}
  explicit RegExpFlags(int value) : value_(value) {}

  inline bool IsGlobal() const { return (value_ & kGlobal) != 0; }
  inline bool IgnoreCase() const { return (value_ & kIgnoreCase) != 0; }
  inline bool IsMultiLine() const { return (value_ & kMultiLine) != 0; }
  inline bool IsUnicode() const { return (value_ & kUnicode) != 0; }
  inline bool IsDotAll() const { return (value_ & kDotAll) != 0; }

  inline bool NeedsUnicodeCaseEquivalents() {
    // Both unicode and ignore_case flags are set. We need to use ICU to find
    // the closure over case equivalents.
    return IsUnicode() && IgnoreCase();
  }

  void SetGlobal() { value_ |= kGlobal; }
  void SetIgnoreCase() { value_ |= kIgnoreCase; }
  void SetMultiLine() { value_ |= kMultiLine; }
  void SetUnicode() { value_ |= kUnicode; }
  void SetDotAll() { value_ |= kDotAll; }

  const char* ToCString() const;

  int value() const { return value_; }

  bool operator==(const RegExpFlags& other) const {
    return value_ == other.value_;
  }
  bool operator!=(const RegExpFlags& other) const {
    return value_ != other.value_;
  }

 private:
  int value_;
};

// Internal JavaScript regular expression object.
class RegExp : public Instance {
 public:
  // Meaning of RegExType:
  // kUninitialized: the type of th regexp has not been initialized yet.
  // kSimple: A simple pattern to match against, using string indexOf operation.
  // kComplex: A complex pattern to match.
  enum RegExType {
    kUninitialized = 0,
    kSimple = 1,
    kComplex = 2,
  };

  enum {
    kTypePos = 0,
    kTypeSize = 2,
    kFlagsPos = 2,
    kFlagsSize = 5,
  };

  class TypeBits : public BitField<int8_t, RegExType, kTypePos, kTypeSize> {};
  class GlobalBit : public BitField<int8_t, bool, kFlagsPos, 1> {};
  class IgnoreCaseBit : public BitField<int8_t, bool, GlobalBit::kNextBit, 1> {
  };
  class MultiLineBit
      : public BitField<int8_t, bool, IgnoreCaseBit::kNextBit, 1> {};
  class UnicodeBit : public BitField<int8_t, bool, MultiLineBit::kNextBit, 1> {
  };
  class DotAllBit : public BitField<int8_t, bool, UnicodeBit::kNextBit, 1> {};

  class FlagsBits : public BitField<int8_t, int8_t, kFlagsPos, kFlagsSize> {};

  bool is_initialized() const { return (type() != kUninitialized); }
  bool is_simple() const { return (type() == kSimple); }
  bool is_complex() const { return (type() == kComplex); }

  intptr_t num_registers(bool is_one_byte) const {
    return LoadNonPointer<intptr_t, std::memory_order_relaxed>(
        is_one_byte ? &untag()->num_one_byte_registers_
                    : &untag()->num_two_byte_registers_);
  }

  StringPtr pattern() const { return untag()->pattern(); }
  intptr_t num_bracket_expressions() const {
    return untag()->num_bracket_expressions_;
  }
  ArrayPtr capture_name_map() const { return untag()->capture_name_map(); }

  TypedDataPtr bytecode(bool is_one_byte, bool sticky) const {
    if (sticky) {
      return TypedData::RawCast(
          is_one_byte ? untag()->one_byte_sticky<std::memory_order_acquire>()
                      : untag()->two_byte_sticky<std::memory_order_acquire>());
    } else {
      return TypedData::RawCast(
          is_one_byte ? untag()->one_byte<std::memory_order_acquire>()
                      : untag()->two_byte<std::memory_order_acquire>());
    }
  }

  static intptr_t function_offset(intptr_t cid, bool sticky) {
    if (sticky) {
      switch (cid) {
        case kOneByteStringCid:
          return OFFSET_OF(UntaggedRegExp, one_byte_sticky_);
        case kTwoByteStringCid:
          return OFFSET_OF(UntaggedRegExp, two_byte_sticky_);
        case kExternalOneByteStringCid:
          return OFFSET_OF(UntaggedRegExp, external_one_byte_sticky_);
        case kExternalTwoByteStringCid:
          return OFFSET_OF(UntaggedRegExp, external_two_byte_sticky_);
      }
    } else {
      switch (cid) {
        case kOneByteStringCid:
          return OFFSET_OF(UntaggedRegExp, one_byte_);
        case kTwoByteStringCid:
          return OFFSET_OF(UntaggedRegExp, two_byte_);
        case kExternalOneByteStringCid:
          return OFFSET_OF(UntaggedRegExp, external_one_byte_);
        case kExternalTwoByteStringCid:
          return OFFSET_OF(UntaggedRegExp, external_two_byte_);
      }
    }

    UNREACHABLE();
    return -1;
  }

  FunctionPtr function(intptr_t cid, bool sticky) const {
    if (sticky) {
      switch (cid) {
        case kOneByteStringCid:
          return static_cast<FunctionPtr>(untag()->one_byte_sticky());
        case kTwoByteStringCid:
          return static_cast<FunctionPtr>(untag()->two_byte_sticky());
        case kExternalOneByteStringCid:
          return static_cast<FunctionPtr>(untag()->external_one_byte_sticky());
        case kExternalTwoByteStringCid:
          return static_cast<FunctionPtr>(untag()->external_two_byte_sticky());
      }
    } else {
      switch (cid) {
        case kOneByteStringCid:
          return static_cast<FunctionPtr>(untag()->one_byte());
        case kTwoByteStringCid:
          return static_cast<FunctionPtr>(untag()->two_byte());
        case kExternalOneByteStringCid:
          return static_cast<FunctionPtr>(untag()->external_one_byte());
        case kExternalTwoByteStringCid:
          return static_cast<FunctionPtr>(untag()->external_two_byte());
      }
    }

    UNREACHABLE();
    return Function::null();
  }

  void set_pattern(const String& pattern) const;
  void set_function(intptr_t cid, bool sticky, const Function& value) const;
  void set_bytecode(bool is_one_byte,
                    bool sticky,
                    const TypedData& bytecode) const;

  void set_num_bracket_expressions(SmiPtr value) const;
  void set_num_bracket_expressions(const Smi& value) const;
  void set_num_bracket_expressions(intptr_t value) const;
  void set_capture_name_map(const Array& array) const;
  void set_is_global() const {
    untag()->type_flags_.UpdateBool<GlobalBit>(true);
  }
  void set_is_ignore_case() const {
    untag()->type_flags_.UpdateBool<IgnoreCaseBit>(true);
  }
  void set_is_multi_line() const {
    untag()->type_flags_.UpdateBool<MultiLineBit>(true);
  }
  void set_is_unicode() const {
    untag()->type_flags_.UpdateBool<UnicodeBit>(true);
  }
  void set_is_dot_all() const {
    untag()->type_flags_.UpdateBool<DotAllBit>(true);
  }
  void set_is_simple() const { set_type(kSimple); }
  void set_is_complex() const { set_type(kComplex); }
  void set_num_registers(bool is_one_byte, intptr_t value) const {
    StoreNonPointer<intptr_t, intptr_t, std::memory_order_relaxed>(
        is_one_byte ? &untag()->num_one_byte_registers_
                    : &untag()->num_two_byte_registers_,
        value);
  }

  RegExpFlags flags() const {
    return RegExpFlags(untag()->type_flags_.Read<FlagsBits>());
  }
  void set_flags(RegExpFlags flags) const {
    untag()->type_flags_.Update<FlagsBits>(flags.value());
  }

  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedRegExp));
  }

  static RegExpPtr New(Zone* zone, Heap::Space space = Heap::kNew);

 private:
  void set_type(RegExType type) const {
    untag()->type_flags_.Update<TypeBits>(type);
  }
  RegExType type() const { return untag()->type_flags_.Read<TypeBits>(); }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(RegExp, Instance);
  friend class Class;
};

// Corresponds to _WeakProperty in dart:core.
class WeakProperty : public Instance {
 public:
  ObjectPtr key() const { return untag()->key(); }
  void set_key(const Object& key) const { untag()->set_key(key.ptr()); }
  static intptr_t key_offset() { return OFFSET_OF(UntaggedWeakProperty, key_); }

  ObjectPtr value() const { return untag()->value(); }
  void set_value(const Object& value) const { untag()->set_value(value.ptr()); }
  static intptr_t value_offset() {
    return OFFSET_OF(UntaggedWeakProperty, value_);
  }

  static WeakPropertyPtr New(Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedWeakProperty));
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(WeakProperty, Instance);
  friend class Class;
};

// Corresponds to _WeakReference in dart:core.
class WeakReference : public Instance {
 public:
  ObjectPtr target() const { return untag()->target(); }
  void set_target(const Object& target) const {
    untag()->set_target(target.ptr());
  }
  static intptr_t target_offset() {
    return OFFSET_OF(UntaggedWeakReference, target_);
  }

  static intptr_t type_arguments_offset() {
    return OFFSET_OF(UntaggedWeakReference, type_arguments_);
  }

  static WeakReferencePtr New(Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedWeakReference));
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(WeakReference, Instance);
  friend class Class;
};

class FinalizerBase;
class FinalizerEntry : public Instance {
 public:
  ObjectPtr value() const { return untag()->value(); }
  void set_value(const Object& value) const { untag()->set_value(value.ptr()); }
  static intptr_t value_offset() {
    return OFFSET_OF(UntaggedFinalizerEntry, value_);
  }

  ObjectPtr detach() const { return untag()->detach(); }
  void set_detach(const Object& value) const {
    untag()->set_detach(value.ptr());
  }
  static intptr_t detach_offset() {
    return OFFSET_OF(UntaggedFinalizerEntry, detach_);
  }

  ObjectPtr token() const { return untag()->token(); }
  void set_token(const Object& value) const { untag()->set_token(value.ptr()); }
  static intptr_t token_offset() {
    return OFFSET_OF(UntaggedFinalizerEntry, token_);
  }

  FinalizerBasePtr finalizer() const { return untag()->finalizer(); }
  void set_finalizer(const FinalizerBase& value) const;
  static intptr_t finalizer_offset() {
    return OFFSET_OF(UntaggedFinalizerEntry, finalizer_);
  }

  FinalizerEntryPtr next() const { return untag()->next(); }
  void set_next(const FinalizerEntry& value) const {
    untag()->set_next(value.ptr());
  }
  static intptr_t next_offset() {
    return OFFSET_OF(UntaggedFinalizerEntry, next_);
  }

  intptr_t external_size() const { return untag()->external_size(); }
  void set_external_size(intptr_t value) const {
    untag()->set_external_size(value);
  }
  static intptr_t external_size_offset() {
    return OFFSET_OF(UntaggedFinalizerEntry, external_size_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedFinalizerEntry));
  }

  // Allocates a new FinalizerEntry, initializing the external size (to 0) and
  // finalizer.
  //
  // Should only be used for object tests.
  //
  // Does not initialize `value`, `token`, and `detach` to allow for flexible
  // testing code setting those manually.
  //
  // Does _not_ add the entry to the finalizer. We could add the entry to
  // finalizer.all_entries.data, but we have no way of initializing the hashset
  // index.
  static FinalizerEntryPtr New(const FinalizerBase& finalizer,
                               Heap::Space space = Heap::kNew);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(FinalizerEntry, Instance);
  friend class Class;
};

class FinalizerBase : public Instance {
 public:
  static intptr_t isolate_offset() {
    return OFFSET_OF(UntaggedFinalizerBase, isolate_);
  }
  Isolate* isolate() const { return untag()->isolate_; }
  void set_isolate(Isolate* value) const { untag()->isolate_ = value; }

  static intptr_t detachments_offset() {
    return OFFSET_OF(UntaggedFinalizerBase, detachments_);
  }

  SetPtr all_entries() const { return untag()->all_entries(); }
  void set_all_entries(const Set& value) const {
    untag()->set_all_entries(value.ptr());
  }
  static intptr_t all_entries_offset() {
    return OFFSET_OF(UntaggedFinalizerBase, all_entries_);
  }

  FinalizerEntryPtr entries_collected() const {
    return untag()->entries_collected();
  }
  void set_entries_collected(const FinalizerEntry& value) const {
    untag()->set_entries_collected(value.ptr());
  }
  static intptr_t entries_collected_offset() {
    return OFFSET_OF(UntaggedFinalizer, entries_collected_);
  }

 private:
  HEAP_OBJECT_IMPLEMENTATION(FinalizerBase, Instance);
  friend class Class;
};

class Finalizer : public FinalizerBase {
 public:
  static intptr_t type_arguments_offset() {
    return OFFSET_OF(UntaggedFinalizer, type_arguments_);
  }

  ObjectPtr callback() const { return untag()->callback(); }
  static intptr_t callback_offset() {
    return OFFSET_OF(UntaggedFinalizer, callback_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedFinalizer));
  }

  static FinalizerPtr New(Heap::Space space = Heap::kNew);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Finalizer, FinalizerBase);
  friend class Class;
};

class NativeFinalizer : public FinalizerBase {
 public:
  typedef void (*Callback)(void*);

  PointerPtr callback() const { return untag()->callback(); }
  void set_callback(const Pointer& value) const {
    untag()->set_callback(value.ptr());
  }
  static intptr_t callback_offset() {
    return OFFSET_OF(UntaggedNativeFinalizer, callback_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedNativeFinalizer));
  }

  static NativeFinalizerPtr New(Heap::Space space = Heap::kNew);

  void RunCallback(const FinalizerEntry& entry,
                   const char* trace_context) const;

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(NativeFinalizer, FinalizerBase);
  friend class Class;
};

class MirrorReference : public Instance {
 public:
  ObjectPtr referent() const { return untag()->referent(); }

  void set_referent(const Object& referent) const {
    untag()->set_referent(referent.ptr());
  }

  AbstractTypePtr GetAbstractTypeReferent() const;

  ClassPtr GetClassReferent() const;

  FieldPtr GetFieldReferent() const;

  FunctionPtr GetFunctionReferent() const;

  FunctionTypePtr GetFunctionTypeReferent() const;

  LibraryPtr GetLibraryReferent() const;

  TypeParameterPtr GetTypeParameterReferent() const;

  static MirrorReferencePtr New(const Object& referent,
                                Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedMirrorReference));
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(MirrorReference, Instance);
  friend class Class;
};

class UserTag : public Instance {
 public:
  uword tag() const { return untag()->tag(); }
  void set_tag(uword t) const {
    ASSERT(t >= UserTags::kUserTagIdOffset);
    ASSERT(t < UserTags::kUserTagIdOffset + UserTags::kMaxUserTags);
    StoreNonPointer(&untag()->tag_, t);
  }

  bool streamable() const { return untag()->streamable(); }
  void set_streamable(bool streamable) {
    StoreNonPointer(&untag()->streamable_, streamable);
  }

  static intptr_t tag_offset() { return OFFSET_OF(UntaggedUserTag, tag_); }

  StringPtr label() const { return untag()->label(); }

  UserTagPtr MakeActive() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedUserTag));
  }

  static UserTagPtr New(const String& label, Heap::Space space = Heap::kOld);
  static UserTagPtr DefaultTag();

  static bool TagTableIsFull(Thread* thread);
  static UserTagPtr FindTagById(const Isolate* isolate, uword tag_id);
  static UserTagPtr FindTagInIsolate(Isolate* isolate,
                                     Thread* thread,
                                     const String& label);

 private:
  static UserTagPtr FindTagInIsolate(Thread* thread, const String& label);
  static void AddTagToIsolate(Thread* thread, const UserTag& tag);

  void set_label(const String& tag_label) const {
    untag()->set_label(tag_label.ptr());
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(UserTag, Instance);
  friend class Class;
};

// Represents abstract FutureOr class in dart:async.
class FutureOr : public Instance {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UntaggedFutureOr));
  }

  virtual TypeArgumentsPtr GetTypeArguments() const {
    return untag()->type_arguments();
  }
  static intptr_t type_arguments_offset() {
    return OFFSET_OF(UntaggedFutureOr, type_arguments_);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(FutureOr, Instance);

  friend class Class;
};

// Breaking cycles and loops.
ClassPtr Object::clazz() const {
  uword raw_value = static_cast<uword>(ptr_);
  if ((raw_value & kSmiTagMask) == kSmiTag) {
    return Smi::Class();
  }
  return IsolateGroup::Current()->class_table()->At(ptr()->GetClassId());
}

DART_FORCE_INLINE
void Object::setPtr(ObjectPtr value, intptr_t default_cid) {
  ptr_ = value;
  intptr_t cid = value->GetClassIdMayBeSmi();
  // Free-list elements cannot be wrapped in a handle.
  ASSERT(cid != kFreeListElement);
  ASSERT(cid != kForwardingCorpse);
  if (cid == kNullCid) {
    cid = default_cid;
  } else if (cid >= kNumPredefinedCids) {
    cid = kInstanceCid;
  }
  set_vtable(builtin_vtables_[cid]);
}

intptr_t Field::HostOffset() const {
  ASSERT(is_instance());  // Valid only for dart instance fields.
  return (Smi::Value(untag()->host_offset_or_field_id()) * kCompressedWordSize);
}

intptr_t Field::TargetOffset() const {
  ASSERT(is_instance());  // Valid only for dart instance fields.
#if !defined(DART_PRECOMPILED_RUNTIME)
  return (untag()->target_offset_ * compiler::target::kCompressedWordSize);
#else
  return HostOffset();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
}

inline intptr_t Field::TargetOffsetOf(const FieldPtr field) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  return field->untag()->target_offset_;
#else
  return Smi::Value(field->untag()->host_offset_or_field_id());
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
}

void Field::SetOffset(intptr_t host_offset_in_bytes,
                      intptr_t target_offset_in_bytes) const {
  ASSERT(is_instance());  // Valid only for dart instance fields.
  ASSERT(kCompressedWordSize != 0);
  untag()->set_host_offset_or_field_id(
      Smi::New(host_offset_in_bytes / kCompressedWordSize));
#if !defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(compiler::target::kCompressedWordSize != 0);
  StoreNonPointer(
      &untag()->target_offset_,
      target_offset_in_bytes / compiler::target::kCompressedWordSize);
#else
  ASSERT(host_offset_in_bytes == target_offset_in_bytes);
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
}

ObjectPtr Field::StaticValue() const {
  ASSERT(is_static());  // Valid only for static dart fields.
  return Isolate::Current()->field_table()->At(field_id());
}

inline intptr_t Field::field_id() const {
  return Smi::Value(untag()->host_offset_or_field_id());
}

void Field::set_field_id(intptr_t field_id) const {
  DEBUG_ASSERT(
      IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  set_field_id_unsafe(field_id);
}

void Field::set_field_id_unsafe(intptr_t field_id) const {
  ASSERT(is_static());
  untag()->set_host_offset_or_field_id(Smi::New(field_id));
}

intptr_t WeakArray::LengthOf(const WeakArrayPtr array) {
  return Smi::Value(array->untag()->length());
}

void Context::SetAt(intptr_t index, const Object& value) const {
  untag()->set_element(index, value.ptr());
}

intptr_t Instance::GetNativeField(int index) const {
  ASSERT(IsValidNativeIndex(index));
  NoSafepointScope no_safepoint;
  TypedDataPtr native_fields = static_cast<TypedDataPtr>(
      NativeFieldsAddr()->Decompress(untag()->heap_base()));
  if (native_fields == TypedData::null()) {
    return 0;
  }
  return reinterpret_cast<intptr_t*>(native_fields->untag()->data())[index];
}

void Instance::GetNativeFields(uint16_t num_fields,
                               intptr_t* field_values) const {
  NoSafepointScope no_safepoint;
  ASSERT(num_fields == NumNativeFields());
  ASSERT(field_values != nullptr);
  TypedDataPtr native_fields = static_cast<TypedDataPtr>(
      NativeFieldsAddr()->Decompress(untag()->heap_base()));
  if (native_fields == TypedData::null()) {
    for (intptr_t i = 0; i < num_fields; i++) {
      field_values[i] = 0;
    }
  }
  intptr_t* fields =
      reinterpret_cast<intptr_t*>(native_fields->untag()->data());
  for (intptr_t i = 0; i < num_fields; i++) {
    field_values[i] = fields[i];
  }
}

bool String::Equals(const String& str) const {
  if (ptr() == str.ptr()) {
    return true;  // Both handles point to the same raw instance.
  }
  if (str.IsNull()) {
    return false;
  }
  if (IsCanonical() && str.IsCanonical()) {
    return false;  // Two symbols that aren't identical aren't equal.
  }
  if (HasHash() && str.HasHash() && (Hash() != str.Hash())) {
    return false;  // Both sides have hash codes and they do not match.
  }
  return Equals(str, 0, str.Length());
}

intptr_t Library::UrlHash() const {
  intptr_t result = String::GetCachedHash(url());
  ASSERT(result != 0);
  return result;
}

void MegamorphicCache::SetEntry(const Array& array,
                                intptr_t index,
                                const Smi& class_id,
                                const Object& target) {
  ASSERT(target.IsNull() || target.IsFunction() || target.IsSmi());
  array.SetAt((index * kEntryLength) + kClassIdIndex, class_id);
  array.SetAt((index * kEntryLength) + kTargetFunctionIndex, target);
}

ObjectPtr MegamorphicCache::GetClassId(const Array& array, intptr_t index) {
  return array.At((index * kEntryLength) + kClassIdIndex);
}

ObjectPtr MegamorphicCache::GetTargetFunction(const Array& array,
                                              intptr_t index) {
  return array.At((index * kEntryLength) + kTargetFunctionIndex);
}

inline uword AbstractType::Hash() const {
  ASSERT(IsFinalized());
  intptr_t result = Smi::Value(untag()->hash());
  if (result != 0) {
    return result;
  }
  return ComputeHash();
}

inline void AbstractType::SetHash(intptr_t value) const {
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  untag()->set_hash(Smi::New(value));
}

inline intptr_t RecordType::NumFields() const {
  return Array::LengthOf(field_types());
}

inline uword TypeArguments::Hash() const {
  if (IsNull()) return kAllDynamicHash;
  intptr_t result = Smi::Value(untag()->hash());
  if (result != 0) {
    return result;
  }
  return ComputeHash();
}

inline void TypeArguments::SetHash(intptr_t value) const {
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  untag()->set_hash(Smi::New(value));
}

inline uint16_t String::CharAt(StringPtr str, intptr_t index) {
  switch (str->GetClassId()) {
    case kOneByteStringCid:
      return OneByteString::CharAt(static_cast<OneByteStringPtr>(str), index);
    case kTwoByteStringCid:
      return TwoByteString::CharAt(static_cast<TwoByteStringPtr>(str), index);
    case kExternalOneByteStringCid:
      return ExternalOneByteString::CharAt(
          static_cast<ExternalOneByteStringPtr>(str), index);
    case kExternalTwoByteStringCid:
      return ExternalTwoByteString::CharAt(
          static_cast<ExternalTwoByteStringPtr>(str), index);
  }
  UNREACHABLE();
  return 0;
}

// A view on an [Array] as a list of tuples, optionally starting at an offset.
//
// Example: We store a list of (kind, function, code) tuples into the
// [Code::static_calls_target_table] array of type [Array].
//
// This helper class can then be used via
//
//     using CallTableView = ArrayOfTuplesView<
//         Code::Kind, std::tuple<Smi, Function, Code>>;
//
//     auto& array = Array::Handle(code.static_calls_targets_table());
//     CallTableView static_calls(array);
//
//     // Using convenient for loop.
//     auto& function = Function::Handle();
//     for (auto& call : static_calls) {
//       function = call.Get<Code::kSCallTableFunctionTarget>();
//       call.Set<Code::kSCallTableFunctionTarget>(function);
//     }
//
//     // Using manual loop.
//     auto& function = Function::Handle();
//     for (intptr_t i = 0; i < static_calls.Length(); ++i) {
//       auto call = static_calls[i];
//       function = call.Get<Code::kSCallTableFunctionTarget>();
//       call.Set<Code::kSCallTableFunctionTarget>(function);
//     }
//
//
// Template parameters:
//
//   * [EnumType] must be a normal enum which enumerates the entries of the
//     tuple
//
//   * [kStartOffset] is the offset at which the first tuple in the array
//     starts (can be 0).
//
//   * [TupleT] must be a std::tuple<...> where "..." are the heap object handle
//     classes (e.g. 'Code', 'Smi', 'Object')
template <typename EnumType, typename TupleT, int kStartOffset = 0>
class ArrayOfTuplesView {
 public:
  static constexpr intptr_t EntrySize = std::tuple_size<TupleT>::value;

  class Iterator;

  class TupleView {
   public:
    TupleView(const Array& array, intptr_t index)
        : array_(array), index_(index) {}

    template <EnumType kElement,
              std::memory_order order = std::memory_order_relaxed>
    typename std::tuple_element<kElement, TupleT>::type::ObjectPtrType Get()
        const {
      using object_type = typename std::tuple_element<kElement, TupleT>::type;
      return object_type::RawCast(array_.At<order>(index_ + kElement));
    }

    template <EnumType kElement,
              std::memory_order order = std::memory_order_relaxed>
    void Set(const typename std::tuple_element<kElement, TupleT>::type& value)
        const {
      array_.SetAt<order>(index_ + kElement, value);
    }

    intptr_t index() const { return (index_ - kStartOffset) / EntrySize; }

   private:
    const Array& array_;
    intptr_t index_;

    friend class Iterator;
  };

  class Iterator {
   public:
    Iterator(const Array& array, intptr_t index) : entry_(array, index) {}

    bool operator==(const Iterator& other) {
      return entry_.index_ == other.entry_.index_;
    }
    bool operator!=(const Iterator& other) {
      return entry_.index_ != other.entry_.index_;
    }

    const TupleView& operator*() const { return entry_; }

    Iterator& operator++() {
      entry_.index_ += EntrySize;
      return *this;
    }

   private:
    TupleView entry_;
  };

  explicit ArrayOfTuplesView(const Array& array) : array_(array) {
    ASSERT(!array.IsNull());
    ASSERT(array.Length() >= kStartOffset);
    ASSERT(array.Length() % EntrySize == kStartOffset);
  }

  intptr_t Length() const {
    return (array_.Length() - kStartOffset) / EntrySize;
  }

  TupleView At(intptr_t i) const {
    return TupleView(array_, kStartOffset + i * EntrySize);
  }

  TupleView operator[](intptr_t i) const { return At(i); }

  Iterator begin() const { return Iterator(array_, kStartOffset); }

  Iterator end() const {
    return Iterator(array_, kStartOffset + Length() * EntrySize);
  }

 private:
  const Array& array_;
};

using StaticCallsTable =
    ArrayOfTuplesView<Code::SCallTableEntry, std::tuple<Smi, Object, Function>>;

using StaticCallsTableEntry = StaticCallsTable::TupleView;

using SubtypeTestCacheTable = ArrayOfTuplesView<SubtypeTestCache::Entries,
                                                std::tuple<Object,
                                                           TypeArguments,
                                                           TypeArguments,
                                                           TypeArguments,
                                                           TypeArguments,
                                                           TypeArguments,
                                                           AbstractType,
                                                           Bool>>;

using MegamorphicCacheEntries =
    ArrayOfTuplesView<MegamorphicCache::EntryType, std::tuple<Smi, Object>>;

using InstantiationsCacheTable =
    ArrayOfTuplesView<TypeArguments::Cache::Entry,
                      std::tuple<Object, TypeArguments, TypeArguments>,
                      TypeArguments::Cache::kHeaderSize>;

void DumpTypeTable(Isolate* isolate);
void DumpTypeParameterTable(Isolate* isolate);
void DumpTypeArgumentsTable(Isolate* isolate);

bool FindPragmaInMetadata(Thread* T,
                          const Object& metadata_obj,
                          const String& pragma_name,
                          bool multiple = false,
                          Object* options = nullptr);

EntryPointPragma FindEntryPointPragma(IsolateGroup* isolate_group,
                                      const Array& metadata,
                                      Field* reusable_field_handle,
                                      Object* reusable_object_handle);

DART_WARN_UNUSED_RESULT
ErrorPtr EntryPointFieldInvocationError(const String& getter_name);

DART_WARN_UNUSED_RESULT
ErrorPtr EntryPointMemberInvocationError(const Object& member);

#undef PRECOMPILER_WSR_FIELD_DECLARATION

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_H_
