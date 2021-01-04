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

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/atomic.h"
#include "platform/thread_sanitizer.h"
#include "platform/utils.h"
#include "vm/bitmap.h"
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
#include "vm/tags.h"
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

#define BASE_OBJECT_IMPLEMENTATION(object, super)                              \
 public: /* NOLINT */                                                          \
  using ObjectLayoutType = dart::object##Layout;                               \
  using ObjectPtrType = dart::object##Ptr;                                     \
  object##Ptr raw() const { return static_cast<object##Ptr>(raw_); }           \
  bool Is##object() const { return true; }                                     \
  DART_NOINLINE static object& Handle() {                                      \
    return HandleImpl(Thread::Current()->zone(), object::null());              \
  }                                                                            \
  DART_NOINLINE static object& Handle(Zone* zone) {                            \
    return HandleImpl(zone, object::null());                                   \
  }                                                                            \
  DART_NOINLINE static object& Handle(object##Ptr raw_ptr) {                   \
    return HandleImpl(Thread::Current()->zone(), raw_ptr);                     \
  }                                                                            \
  DART_NOINLINE static object& Handle(Zone* zone, object##Ptr raw_ptr) {       \
    return HandleImpl(zone, raw_ptr);                                          \
  }                                                                            \
  DART_NOINLINE static object& ZoneHandle() {                                  \
    return ZoneHandleImpl(Thread::Current()->zone(), object::null());          \
  }                                                                            \
  DART_NOINLINE static object& ZoneHandle(Zone* zone) {                        \
    return ZoneHandleImpl(zone, object::null());                               \
  }                                                                            \
  DART_NOINLINE static object& ZoneHandle(object##Ptr raw_ptr) {               \
    return ZoneHandleImpl(Thread::Current()->zone(), raw_ptr);                 \
  }                                                                            \
  DART_NOINLINE static object& ZoneHandle(Zone* zone, object##Ptr raw_ptr) {   \
    return ZoneHandleImpl(zone, raw_ptr);                                      \
  }                                                                            \
  DART_NOINLINE static object* ReadOnlyHandle() {                              \
    object* obj = reinterpret_cast<object*>(Dart::AllocateReadOnlyHandle());   \
    initializeHandle(obj, object::null());                                     \
    return obj;                                                                \
  }                                                                            \
  DART_NOINLINE static object& CheckedHandle(Zone* zone, ObjectPtr raw_ptr) {  \
    object* obj = reinterpret_cast<object*>(VMHandles::AllocateHandle(zone));  \
    initializeHandle(obj, raw_ptr);                                            \
    if (!obj->Is##object()) {                                                  \
      FATAL2("Handle check failed: saw %s expected %s", obj->ToCString(),      \
             #object);                                                         \
    }                                                                          \
    return *obj;                                                               \
  }                                                                            \
  DART_NOINLINE static object& CheckedZoneHandle(Zone* zone,                   \
                                                 ObjectPtr raw_ptr) {          \
    object* obj =                                                              \
        reinterpret_cast<object*>(VMHandles::AllocateZoneHandle(zone));        \
    initializeHandle(obj, raw_ptr);                                            \
    if (!obj->Is##object()) {                                                  \
      FATAL2("Handle check failed: saw %s expected %s", obj->ToCString(),      \
             #object);                                                         \
    }                                                                          \
    return *obj;                                                               \
  }                                                                            \
  DART_NOINLINE static object& CheckedZoneHandle(ObjectPtr raw_ptr) {          \
    return CheckedZoneHandle(Thread::Current()->zone(), raw_ptr);              \
  }                                                                            \
  /* T::Cast cannot be applied to a null Object, because the object vtable */  \
  /* is not setup for type T, although some methods are supposed to work   */  \
  /* with null, for example Instance::Equals().                            */  \
  static const object& Cast(const Object& obj) {                               \
    ASSERT(obj.Is##object());                                                  \
    return reinterpret_cast<const object&>(obj);                               \
  }                                                                            \
  static object##Ptr RawCast(ObjectPtr raw) {                                  \
    ASSERT(Object::Handle(raw).IsNull() || Object::Handle(raw).Is##object());  \
    return static_cast<object##Ptr>(raw);                                      \
  }                                                                            \
  static object##Ptr null() {                                                  \
    return static_cast<object##Ptr>(Object::null());                           \
  }                                                                            \
  virtual const char* ToCString() const;                                       \
  static const ClassId kClassId = k##object##Cid;                              \
                                                                               \
 private: /* NOLINT */                                                         \
  static object& HandleImpl(Zone* zone, object##Ptr raw_ptr) {                 \
    object* obj = reinterpret_cast<object*>(VMHandles::AllocateHandle(zone));  \
    initializeHandle(obj, raw_ptr);                                            \
    return *obj;                                                               \
  }                                                                            \
  static object& ZoneHandleImpl(Zone* zone, object##Ptr raw_ptr) {             \
    object* obj =                                                              \
        reinterpret_cast<object*>(VMHandles::AllocateZoneHandle(zone));        \
    initializeHandle(obj, raw_ptr);                                            \
    return *obj;                                                               \
  }                                                                            \
  /* Initialize the handle based on the raw_ptr in the presence of null. */    \
  static void initializeHandle(object* obj, ObjectPtr raw_ptr) {               \
    if (raw_ptr != Object::null()) {                                           \
      obj->SetRaw(raw_ptr);                                                    \
    } else {                                                                   \
      obj->raw_ = Object::null();                                              \
      object fake_object;                                                      \
      obj->set_vtable(fake_object.vtable());                                   \
    }                                                                          \
  }                                                                            \
  /* Disallow allocation, copy constructors and override super assignment. */  \
 public: /* NOLINT */                                                          \
  void operator delete(void* pointer) { UNREACHABLE(); }                       \
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
  virtual const char* JSONType() const { return "" #object; }
#else
#define OBJECT_SERVICE_SUPPORT(object) protected: /* NOLINT */
#endif                                            // !PRODUCT

#define SNAPSHOT_READER_SUPPORT(object)                                        \
  static object##Ptr ReadFrom(SnapshotReader* reader, intptr_t object_id,      \
                              intptr_t tags, Snapshot::Kind,                   \
                              bool as_reference);                              \
  friend class SnapshotReader;

#define OBJECT_IMPLEMENTATION(object, super)                                   \
 public: /* NOLINT */                                                          \
  void operator=(object##Ptr value) { initializeHandle(this, value); }         \
  void operator^=(ObjectPtr value) {                                           \
    initializeHandle(this, value);                                             \
    ASSERT(IsNull() || Is##object());                                          \
  }                                                                            \
                                                                               \
 protected: /* NOLINT */                                                       \
  object() : super() {}                                                        \
  BASE_OBJECT_IMPLEMENTATION(object, super)                                    \
  OBJECT_SERVICE_SUPPORT(object)                                               \
  friend class Object;

#define HEAP_OBJECT_IMPLEMENTATION(object, super)                              \
  OBJECT_IMPLEMENTATION(object, super);                                        \
  object##Layout* raw_ptr() const {                                            \
    ASSERT(raw() != null());                                                   \
    return const_cast<object##Layout*>(raw()->ptr());                          \
  }                                                                            \
  SNAPSHOT_READER_SUPPORT(object)                                              \
  friend class StackFrame;                                                     \
  friend class Thread;

// This macro is used to denote types that do not have a sub-type.
#define FINAL_HEAP_OBJECT_IMPLEMENTATION_HELPER(object, rettype, super)        \
 public: /* NOLINT */                                                          \
  void operator=(object##Ptr value) {                                          \
    raw_ = value;                                                              \
    CHECK_HANDLE();                                                            \
  }                                                                            \
  void operator^=(ObjectPtr value) {                                           \
    raw_ = value;                                                              \
    CHECK_HANDLE();                                                            \
  }                                                                            \
                                                                               \
 private: /* NOLINT */                                                         \
  object() : super() {}                                                        \
  BASE_OBJECT_IMPLEMENTATION(object, super)                                    \
  OBJECT_SERVICE_SUPPORT(object)                                               \
  object##Layout* raw_ptr() const {                                            \
    ASSERT(raw() != null());                                                   \
    return const_cast<object##Layout*>(raw()->ptr());                          \
  }                                                                            \
  static intptr_t NextFieldOffset() { return -kWordSize; }                     \
  SNAPSHOT_READER_SUPPORT(rettype)                                             \
  friend class Object;                                                         \
  friend class StackFrame;                                                     \
  friend class Thread;

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
  using ObjectLayoutType = ObjectLayout;
  using ObjectPtrType = ObjectPtr;

  static ObjectPtr RawCast(ObjectPtr obj) { return obj; }

  virtual ~Object() {}

  ObjectPtr raw() const { return raw_; }
  void operator=(ObjectPtr value) { initializeHandle(this, value); }

  bool IsCanonical() const { return raw()->ptr()->IsCanonical(); }
  void SetCanonical() const { raw()->ptr()->SetCanonical(); }
  void ClearCanonical() const { raw()->ptr()->ClearCanonical(); }
  intptr_t GetClassId() const {
    return !raw()->IsHeapObject() ? static_cast<intptr_t>(kSmiCid)
                                  : raw()->ptr()->GetClassId();
  }
  inline ClassPtr clazz() const;
  static intptr_t tags_offset() { return OFFSET_OF(ObjectLayout, tags_); }

// Class testers.
#define DEFINE_CLASS_TESTER(clazz)                                             \
  virtual bool Is##clazz() const { return false; }
  CLASS_LIST_FOR_HANDLES(DEFINE_CLASS_TESTER);
#undef DEFINE_CLASS_TESTER

  bool IsNull() const { return raw_ == null_; }

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
  virtual const char* JSONType() const { return IsNull() ? "null" : "Object"; }
#endif

  // Returns the name that is used to identify an object in the
  // namespace dictionary.
  // Object::DictionaryName() returns String::null(). Only subclasses
  // of Object that need to be entered in the library and library prefix
  // namespaces need to provide an implementation.
  virtual StringPtr DictionaryName() const;

  bool IsNew() const { return raw()->IsNewObject(); }
  bool IsOld() const { return raw()->IsOldObject(); }
#if defined(DEBUG)
  bool InVMIsolateHeap() const;
#else
  bool InVMIsolateHeap() const { return raw()->ptr()->InVMIsolateHeap(); }
#endif  // DEBUG

  // Print the object on stdout for debugging.
  void Print() const;

  bool IsZoneHandle() const {
    return VMHandles::IsZoneHandle(reinterpret_cast<uword>(this));
  }

  bool IsReadOnlyHandle() const;

  bool IsNotTemporaryScopedHandle() const;

  static Object& Handle(Zone* zone, ObjectPtr raw_ptr) {
    Object* obj = reinterpret_cast<Object*>(VMHandles::AllocateHandle(zone));
    initializeHandle(obj, raw_ptr);
    return *obj;
  }
  static Object* ReadOnlyHandle() {
    Object* obj = reinterpret_cast<Object*>(Dart::AllocateReadOnlyHandle());
    initializeHandle(obj, Object::null());
    return obj;
  }

  static Object& Handle() { return Handle(Thread::Current()->zone(), null_); }

  static Object& Handle(Zone* zone) { return Handle(zone, null_); }

  static Object& Handle(ObjectPtr raw_ptr) {
    return Handle(Thread::Current()->zone(), raw_ptr);
  }

  static Object& ZoneHandle(Zone* zone, ObjectPtr raw_ptr) {
    Object* obj =
        reinterpret_cast<Object*>(VMHandles::AllocateZoneHandle(zone));
    initializeHandle(obj, raw_ptr);
    return *obj;
  }

  static Object& ZoneHandle(Zone* zone) { return ZoneHandle(zone, null_); }

  static Object& ZoneHandle() {
    return ZoneHandle(Thread::Current()->zone(), null_);
  }

  static Object& ZoneHandle(ObjectPtr raw_ptr) {
    return ZoneHandle(Thread::Current()->zone(), raw_ptr);
  }

  static ObjectPtr null() { return null_; }

#if defined(HASH_IN_OBJECT_HEADER)
  static uint32_t GetCachedHash(const ObjectPtr obj) {
    return obj->ptr()->GetHeaderHash();
  }

  static void SetCachedHash(ObjectPtr obj, uint32_t hash) {
    obj->ptr()->SetHeaderHash(hash);
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
#define SHARED_READONLY_HANDLES_LIST(V)                                        \
  V(Object, null_object)                                                       \
  V(Array, null_array)                                                         \
  V(String, null_string)                                                       \
  V(Instance, null_instance)                                                   \
  V(Function, null_function)                                                   \
  V(TypeArguments, null_type_arguments)                                        \
  V(CompressedStackMaps, null_compressed_stackmaps)                            \
  V(TypeArguments, empty_type_arguments)                                       \
  V(Array, empty_array)                                                        \
  V(Array, zero_array)                                                         \
  V(ContextScope, empty_context_scope)                                         \
  V(ObjectPool, empty_object_pool)                                             \
  V(CompressedStackMaps, empty_compressed_stackmaps)                           \
  V(PcDescriptors, empty_descriptors)                                          \
  V(LocalVarDescriptors, empty_var_descriptors)                                \
  V(ExceptionHandlers, empty_exception_handlers)                               \
  V(Array, extractor_parameter_types)                                          \
  V(Array, extractor_parameter_names)                                          \
  V(Instance, sentinel)                                                        \
  V(Instance, transition_sentinel)                                             \
  V(Instance, unknown_constant)                                                \
  V(Instance, non_constant)                                                    \
  V(Bool, bool_true)                                                           \
  V(Bool, bool_false)                                                          \
  V(Smi, smi_illegal_cid)                                                      \
  V(Smi, smi_zero)                                                             \
  V(ApiError, typed_data_acquire_error)                                        \
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
  static ClassPtr type_arguments_class() { return type_arguments_class_; }
  static ClassPtr patch_class_class() { return patch_class_class_; }
  static ClassPtr function_class() { return function_class_; }
  static ClassPtr closure_data_class() { return closure_data_class_; }
  static ClassPtr signature_data_class() { return signature_data_class_; }
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
  static ClassPtr deopt_info_class() { return deopt_info_class_; }
  static ClassPtr context_class() { return context_class_; }
  static ClassPtr context_scope_class() { return context_scope_class_; }
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

  // Initialize the VM isolate.
  static void InitNullAndBool(Isolate* isolate);
  static void Init(Isolate* isolate);
  static void InitVtables();
  static void FinishInit(Isolate* isolate);
  static void FinalizeVMIsolate(Isolate* isolate);
  static void FinalizeReadOnlyObject(ObjectPtr object);

  static void Cleanup();

  // Initialize a new isolate either from a Kernel IR, from source, or from a
  // snapshot.
  static ErrorPtr Init(Isolate* isolate,
                       const uint8_t* kernel_buffer,
                       intptr_t kernel_buffer_size);

  static void MakeUnusedSpaceTraversable(const Object& obj,
                                         intptr_t original_size,
                                         intptr_t used_size);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(ObjectLayout));
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
  // Used for extracting the C++ vtable during bringup.
  Object() : raw_(null_) {}

  uword raw_value() const { return static_cast<uword>(raw()); }

  inline void SetRaw(ObjectPtr value);
  void CheckHandle() const;

  cpp_vtable vtable() const { return bit_copy<cpp_vtable>(*this); }
  void set_vtable(cpp_vtable value) { *vtable_address() = value; }

  static ObjectPtr Allocate(intptr_t cls_id, intptr_t size, Heap::Space space);

  static intptr_t RoundedAllocationSize(intptr_t size) {
    return Utils::RoundUp(size, kObjectAlignment);
  }

  bool Contains(uword addr) const { return raw()->ptr()->Contains(addr); }

  // Start of field mutator guards.
  //
  // All writes to heap objects should ultimately pass through one of the
  // methods below or their counterparts in RawObject, to ensure that the
  // write barrier is correctly applied.

  template <typename type, std::memory_order order = std::memory_order_relaxed>
  type LoadPointer(type const* addr) const {
    return raw()->ptr()->LoadPointer<type, order>(addr);
  }

  template <typename type, std::memory_order order = std::memory_order_relaxed>
  void StorePointer(type const* addr, type value) const {
    raw()->ptr()->StorePointer<type, order>(addr, value);
  }

  // Use for storing into an explicitly Smi-typed field of an object
  // (i.e., both the previous and new value are Smis).
  void StoreSmi(SmiPtr const* addr, SmiPtr value) const {
    raw()->ptr()->StoreSmi(addr, value);
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
    ASSERT(reinterpret_cast<uword>(addr) >= ObjectLayout::ToAddr(raw()));
    *const_cast<FieldType*>(addr) = value;
  }

  template <typename FieldType, typename ValueType, std::memory_order order>
  void StoreNonPointer(const FieldType* addr, ValueType value) const {
    // Can't use Contains, as it uses tags_, which is set through this method.
    ASSERT(reinterpret_cast<uword>(addr) >= ObjectLayout::ToAddr(raw()));
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
    return NULL;                                                               \
  }

  CLASS_LIST(STORE_NON_POINTER_ILLEGAL_TYPE);
  void UnimplementedMethod() const;
#undef STORE_NON_POINTER_ILLEGAL_TYPE

  // Allocate an object and copy the body of 'orig'.
  static ObjectPtr Clone(const Object& orig, Heap::Space space);

  // End of field mutator guards.

  ObjectPtr raw_;  // The raw object reference.

 protected:
  void AddCommonObjectProperties(JSONObject* jsobj,
                                 const char* protocol_type,
                                 bool ref) const;

 private:
  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  static void InitializeObject(uword address, intptr_t id, intptr_t size);

  static void RegisterClass(const Class& cls,
                            const String& name,
                            const Library& lib);
  static void RegisterPrivateClass(const Class& cls,
                                   const String& name,
                                   const Library& lib);

  /* Initialize the handle based on the raw_ptr in the presence of null. */
  static void initializeHandle(Object* obj, ObjectPtr raw_ptr) {
    if (raw_ptr != Object::null()) {
      obj->SetRaw(raw_ptr);
    } else {
      obj->raw_ = Object::null();
      Object fake_object;
      obj->set_vtable(fake_object.vtable());
    }
  }

  cpp_vtable* vtable_address() const {
    uword vtable_addr = reinterpret_cast<uword>(this);
    return reinterpret_cast<cpp_vtable*>(vtable_addr);
  }

  static cpp_vtable builtin_vtables_[kNumPredefinedCids];

  // The static values below are singletons shared between the different
  // isolates. They are all allocated in the non-GC'd Dart::vm_isolate_.
  static ObjectPtr null_;
  static BoolPtr true_;
  static BoolPtr false_;

  static ClassPtr class_class_;           // Class of the Class vm object.
  static ClassPtr dynamic_class_;         // Class of the 'dynamic' type.
  static ClassPtr void_class_;            // Class of the 'void' type.
  static ClassPtr type_arguments_class_;  // Class of TypeArguments vm object.
  static ClassPtr patch_class_class_;     // Class of the PatchClass vm object.
  static ClassPtr function_class_;        // Class of the Function vm object.
  static ClassPtr closure_data_class_;    // Class of ClosureData vm obj.
  static ClassPtr signature_data_class_;  // Class of SignatureData vm obj.
  static ClassPtr ffi_trampoline_data_class_;  // Class of FfiTrampolineData
                                               // vm obj.
  static ClassPtr field_class_;                // Class of the Field vm object.
  static ClassPtr script_class_;               // Class of the Script vm object.
  static ClassPtr library_class_;    // Class of the Library vm object.
  static ClassPtr namespace_class_;  // Class of Namespace vm object.
  static ClassPtr kernel_program_info_class_;  // Class of KernelProgramInfo vm
                                               // object.
  static ClassPtr code_class_;                 // Class of the Code vm object.

  static ClassPtr instructions_class_;  // Class of the Instructions vm object.
  static ClassPtr instructions_section_class_;  // Class of InstructionsSection.
  static ClassPtr object_pool_class_;      // Class of the ObjectPool vm object.
  static ClassPtr pc_descriptors_class_;   // Class of PcDescriptors vm object.
  static ClassPtr code_source_map_class_;  // Class of CodeSourceMap vm object.
  static ClassPtr compressed_stackmaps_class_;  // Class of CompressedStackMaps.
  static ClassPtr var_descriptors_class_;       // Class of LocalVarDescriptors.
  static ClassPtr exception_handlers_class_;    // Class of ExceptionHandlers.
  static ClassPtr deopt_info_class_;            // Class of DeoptInfo.
  static ClassPtr context_class_;            // Class of the Context vm object.
  static ClassPtr context_scope_class_;      // Class of ContextScope vm object.
  static ClassPtr singletargetcache_class_;  // Class of SingleTargetCache.
  static ClassPtr unlinkedcall_class_;       // Class of UnlinkedCall.
  static ClassPtr
      monomorphicsmiablecall_class_;         // Class of MonomorphicSmiableCall.
  static ClassPtr icdata_class_;             // Class of ICData.
  static ClassPtr megamorphic_cache_class_;  // Class of MegamorphiCache.
  static ClassPtr subtypetestcache_class_;   // Class of SubtypeTestCache.
  static ClassPtr loadingunit_class_;        // Class of LoadingUnit.
  static ClassPtr api_error_class_;          // Class of ApiError.
  static ClassPtr language_error_class_;     // Class of LanguageError.
  static ClassPtr unhandled_exception_class_;  // Class of UnhandledException.
  static ClassPtr unwind_error_class_;         // Class of UnwindError.
  // Class of WeakSerializationReference.
  static ClassPtr weak_serialization_reference_class_;

#define DECLARE_SHARED_READONLY_HANDLE(Type, name) static Type* name##_;
  SHARED_READONLY_HANDLES_LIST(DECLARE_SHARED_READONLY_HANDLE)
#undef DECLARE_SHARED_READONLY_HANDLE

  friend void ClassTable::Register(const Class& cls);
  friend void ObjectLayout::Validate(IsolateGroup* isolate_group) const;
  friend class Closure;
  friend class SnapshotReader;
  friend class InstanceDeserializationCluster;
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

class PassiveObject : public Object {
 public:
  void operator=(ObjectPtr value) { raw_ = value; }
  void operator^=(ObjectPtr value) { raw_ = value; }

  static PassiveObject& Handle(Zone* zone, ObjectPtr raw_ptr) {
    PassiveObject* obj =
        reinterpret_cast<PassiveObject*>(VMHandles::AllocateHandle(zone));
    obj->raw_ = raw_ptr;
    obj->set_vtable(0);
    return *obj;
  }
  static PassiveObject& Handle(ObjectPtr raw_ptr) {
    return Handle(Thread::Current()->zone(), raw_ptr);
  }
  static PassiveObject& Handle() {
    return Handle(Thread::Current()->zone(), Object::null());
  }
  static PassiveObject& Handle(Zone* zone) {
    return Handle(zone, Object::null());
  }
  static PassiveObject& ZoneHandle(Zone* zone, ObjectPtr raw_ptr) {
    PassiveObject* obj =
        reinterpret_cast<PassiveObject*>(VMHandles::AllocateZoneHandle(zone));
    obj->raw_ = raw_ptr;
    obj->set_vtable(0);
    return *obj;
  }
  static PassiveObject& ZoneHandle(ObjectPtr raw_ptr) {
    return ZoneHandle(Thread::Current()->zone(), raw_ptr);
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

typedef ZoneGrowableHandlePtrArray<const AbstractType> Trail;
typedef ZoneGrowableHandlePtrArray<const AbstractType>* TrailPtr;

// A URIs array contains triplets of strings.
// The first string in the triplet is a type name (usually a class).
// The second string in the triplet is the URI of the type.
// The third string in the triplet is "print" if the triplet should be printed.
typedef ZoneGrowableHandlePtrArray<const String> URIs;

enum class Nullability : int8_t {
  kNullable = 0,
  kNonNullable = 1,
  kLegacy = 2,
  // Adjust kNullabilityBitSize in clustered_snapshot.cc if adding new values.
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

  intptr_t host_instance_size() const {
    ASSERT(is_finalized() || is_prefinalized());
    return (raw_ptr()->host_instance_size_in_words_ * kWordSize);
  }
  intptr_t target_instance_size() const {
    ASSERT(is_finalized() || is_prefinalized());
#if !defined(DART_PRECOMPILED_RUNTIME)
    return (raw_ptr()->target_instance_size_in_words_ *
            compiler::target::kWordSize);
#else
    return host_instance_size();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  }
  static intptr_t host_instance_size(ClassPtr clazz) {
    return (clazz->ptr()->host_instance_size_in_words_ * kWordSize);
  }
  static intptr_t target_instance_size(ClassPtr clazz) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return (clazz->ptr()->target_instance_size_in_words_ *
            compiler::target::kWordSize);
#else
    return host_instance_size(clazz);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  }
  void set_instance_size(intptr_t host_value_in_bytes,
                         intptr_t target_value_in_bytes) const {
    ASSERT(kWordSize != 0);
    set_instance_size_in_words(
        host_value_in_bytes / kWordSize,
        target_value_in_bytes / compiler::target::kWordSize);
  }
  void set_instance_size_in_words(intptr_t host_value,
                                  intptr_t target_value) const {
    ASSERT(Utils::IsAligned((host_value * kWordSize), kObjectAlignment));
    StoreNonPointer(&raw_ptr()->host_instance_size_in_words_, host_value);
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(Utils::IsAligned((target_value * compiler::target::kWordSize),
                            compiler::target::kObjectAlignment));
    StoreNonPointer(&raw_ptr()->target_instance_size_in_words_, target_value);
#else
    ASSERT(host_value == target_value);
#endif  // #!defined(DART_PRECOMPILED_RUNTIME)
  }

  intptr_t host_next_field_offset() const {
    return raw_ptr()->host_next_field_offset_in_words_ * kWordSize;
  }
  intptr_t target_next_field_offset() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return raw_ptr()->target_next_field_offset_in_words_ *
           compiler::target::kWordSize;
#else
    return host_next_field_offset();
#endif  // #!defined(DART_PRECOMPILED_RUNTIME)
  }
  void set_next_field_offset(intptr_t host_value_in_bytes,
                             intptr_t target_value_in_bytes) const {
    set_next_field_offset_in_words(
        host_value_in_bytes / kWordSize,
        target_value_in_bytes / compiler::target::kWordSize);
  }
  void set_next_field_offset_in_words(intptr_t host_value,
                                      intptr_t target_value) const {
    ASSERT((host_value == -1) ||
           (Utils::IsAligned((host_value * kWordSize), kObjectAlignment) &&
            (host_value == raw_ptr()->host_instance_size_in_words_)) ||
           (!Utils::IsAligned((host_value * kWordSize), kObjectAlignment) &&
            ((host_value + 1) == raw_ptr()->host_instance_size_in_words_)));
    StoreNonPointer(&raw_ptr()->host_next_field_offset_in_words_, host_value);
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT((target_value == -1) ||
           (Utils::IsAligned((target_value * compiler::target::kWordSize),
                             compiler::target::kObjectAlignment) &&
            (target_value == raw_ptr()->target_instance_size_in_words_)) ||
           (!Utils::IsAligned((target_value * compiler::target::kWordSize),
                              compiler::target::kObjectAlignment) &&
            ((target_value + 1) == raw_ptr()->target_instance_size_in_words_)));
    StoreNonPointer(&raw_ptr()->target_next_field_offset_in_words_,
                    target_value);
#else
    ASSERT(host_value == target_value);
#endif  // #!defined(DART_PRECOMPILED_RUNTIME)
  }

  static bool is_valid_id(intptr_t value) {
    return ObjectLayout::ClassIdTag::is_valid(value);
  }
  intptr_t id() const { return raw_ptr()->id_; }
  void set_id(intptr_t value) const {
    ASSERT(value >= 0 && value < std::numeric_limits<classid_t>::max());
    StoreNonPointer(&raw_ptr()->id_, value);
  }
  static intptr_t id_offset() { return OFFSET_OF(ClassLayout, id_); }
  static intptr_t num_type_arguments_offset() {
    return OFFSET_OF(ClassLayout, num_type_arguments_);
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

  ScriptPtr script() const { return raw_ptr()->script(); }
  void set_script(const Script& value) const;

  TokenPosition token_pos() const { return raw_ptr()->token_pos_; }
  void set_token_pos(TokenPosition value) const;
  TokenPosition end_token_pos() const { return raw_ptr()->end_token_pos_; }
  void set_end_token_pos(TokenPosition value) const;

  int32_t SourceFingerprint() const;

  // This class represents a typedef if the signature function is not null.
  FunctionPtr signature_function() const {
    return raw_ptr()->signature_function();
  }
  void set_signature_function(const Function& value) const;

  // Return the Type with type parameters declared by this class filled in with
  // dynamic and type parameters declared in superclasses filled in as declared
  // in superclass clauses.
  AbstractTypePtr RareType() const;

  // Return the Type whose arguments are the type parameters declared by this
  // class preceded by the type arguments declared for superclasses, etc.
  // e.g. given
  // class B<T, S>
  // class C<R> extends B<R, int>
  // C.DeclarationType() --> C [R, int, R]
  // The declaration type's nullability is either legacy or non-nullable when
  // the non-nullable experiment is enabled.
  TypePtr DeclarationType() const;

  static intptr_t declaration_type_offset() {
    return OFFSET_OF(ClassLayout, declaration_type_);
  }

  LibraryPtr library() const { return raw_ptr()->library(); }
  void set_library(const Library& value) const;

  // The type parameters (and their bounds) are specified as an array of
  // TypeParameter.
  TypeArgumentsPtr type_parameters() const {
    ASSERT(is_declaration_loaded());
    return raw_ptr()->type_parameters();
  }
  void set_type_parameters(const TypeArguments& value) const;
  intptr_t NumTypeParameters(Thread* thread) const;
  intptr_t NumTypeParameters() const {
    return NumTypeParameters(Thread::Current());
  }

  // Return a TypeParameter if the type_name is a type parameter of this class.
  // Return null otherwise.
  TypeParameterPtr LookupTypeParameter(const String& type_name) const;

  // The type argument vector is flattened and includes the type arguments of
  // the super class.
  intptr_t NumTypeArguments() const;

  // Return true if this class declares type parameters.
  bool IsGeneric() const { return NumTypeParameters(Thread::Current()) > 0; }

  // Returns a canonicalized vector of the type parameters instantiated
  // to bounds. If non-generic, the empty type arguments vector is returned.
  TypeArgumentsPtr InstantiateToBounds(Thread* thread) const;

  // If this class is parameterized, each instance has a type_arguments field.
  static const intptr_t kNoTypeArguments = -1;
  intptr_t host_type_arguments_field_offset() const {
    ASSERT(is_type_finalized() || is_prefinalized());
    if (raw_ptr()->host_type_arguments_field_offset_in_words_ ==
        kNoTypeArguments) {
      return kNoTypeArguments;
    }
    return raw_ptr()->host_type_arguments_field_offset_in_words_ * kWordSize;
  }
  intptr_t target_type_arguments_field_offset() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(is_type_finalized() || is_prefinalized());
    if (raw_ptr()->target_type_arguments_field_offset_in_words_ ==
        compiler::target::Class::kNoTypeArguments) {
      return compiler::target::Class::kNoTypeArguments;
    }
    return raw_ptr()->target_type_arguments_field_offset_in_words_ *
           compiler::target::kWordSize;
#else
    return host_type_arguments_field_offset();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
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
      ASSERT(kWordSize != 0 && compiler::target::kWordSize);
      host_value = host_value_in_bytes / kWordSize;
      target_value = target_value_in_bytes / compiler::target::kWordSize;
    }
    set_type_arguments_field_offset_in_words(host_value, target_value);
  }
  void set_type_arguments_field_offset_in_words(intptr_t host_value,
                                                intptr_t target_value) const {
    StoreNonPointer(&raw_ptr()->host_type_arguments_field_offset_in_words_,
                    host_value);
#if !defined(DART_PRECOMPILED_RUNTIME)
    StoreNonPointer(&raw_ptr()->target_type_arguments_field_offset_in_words_,
                    target_value);
#else
    ASSERT(host_value == target_value);
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }
  static intptr_t host_type_arguments_field_offset_in_words_offset() {
    return OFFSET_OF(ClassLayout, host_type_arguments_field_offset_in_words_);
  }

  static intptr_t target_type_arguments_field_offset_in_words_offset() {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return OFFSET_OF(ClassLayout, target_type_arguments_field_offset_in_words_);
#else
    return host_type_arguments_field_offset_in_words_offset();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  // The super type of this class, Object type if not explicitly specified.
  AbstractTypePtr super_type() const {
    ASSERT(is_declaration_loaded());
    return raw_ptr()->super_type();
  }
  void set_super_type(const AbstractType& value) const;
  static intptr_t super_type_offset() {
    return OFFSET_OF(ClassLayout, super_type_);
  }

  // Asserts that the class of the super type has been resolved.
  // |original_classes| only has an effect when reloading. If true and we
  // are reloading, it will prefer the original classes to the replacement
  // classes.
  ClassPtr SuperClass(bool original_classes = false) const;

  // Interfaces is an array of Types.
  ArrayPtr interfaces() const {
    ASSERT(is_declaration_loaded());
    return raw_ptr()->interfaces();
  }
  void set_interfaces(const Array& value) const;

  // Returns the list of classes directly implementing this class.
  GrowableObjectArrayPtr direct_implementors() const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
    return raw_ptr()->direct_implementors();
  }
  void AddDirectImplementor(const Class& subclass, bool is_mixin) const;
  void ClearDirectImplementors() const;

  // Returns the list of classes having this class as direct superclass.
  GrowableObjectArrayPtr direct_subclasses() const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
    return direct_subclasses_unsafe();
  }
  GrowableObjectArrayPtr direct_subclasses_unsafe() const {
    return raw_ptr()->direct_subclasses();
  }
  void AddDirectSubclass(const Class& subclass) const;
  void ClearDirectSubclasses() const;

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
    NoSafepointScope no_safepoint;
    return cls->ptr()->id_ == kClosureCid;
  }

  // Check if this class represents a typedef class.
  bool IsTypedefClass() const { return signature_function() != Object::null(); }

  static bool IsInFullSnapshot(ClassPtr cls) {
    NoSafepointScope no_safepoint;
    return LibraryLayout::InFullSnapshotBit::decode(
        cls->ptr()->library()->ptr()->flags_);
  }

  // Returns true if the type specified by cls, type_arguments, and nullability
  // is a subtype of the other type.
  static bool IsSubtypeOf(const Class& cls,
                          const TypeArguments& type_arguments,
                          Nullability nullability,
                          const AbstractType& other,
                          Heap::Space space,
                          TrailPtr trail = nullptr);

  // Check if this is the top level class.
  bool IsTopLevel() const;

  bool IsPrivate() const;

  DART_WARN_UNUSED_RESULT
  ErrorPtr VerifyEntryPoint() const;

  // Returns an array of instance and static fields defined by this class.
  ArrayPtr fields() const {
    // We rely on the fact that any loads from the array are dependent loads
    // and avoid the load-acquire barrier here.
    return raw_ptr()->fields();
  }
  void SetFields(const Array& value) const;
  void AddField(const Field& field) const;
  void AddFields(const GrowableArray<const Field*>& fields) const;

  // If this is a dart:internal.ClassID class, then inject our own const
  // fields. Returns true if synthetic fields are injected and regular
  // field declarations should be ignored.
  bool InjectCIDFields() const;

  // Returns an array of all instance fields of this class and its superclasses
  // indexed by offset in words.
  // |original_classes| only has an effect when reloading. If true and we
  // are reloading, it will prefer the original classes to the replacement
  // classes.
  ArrayPtr OffsetToFieldMap(bool original_classes = false) const;

  // Returns true if non-static fields are defined.
  bool HasInstanceFields() const;

  ArrayPtr current_functions() const {
    // We rely on the fact that any loads from the array are dependent loads
    // and avoid the load-acquire barrier here.
    return raw_ptr()->functions();
  }
  ArrayPtr functions() const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
    return current_functions();
  }
  void SetFunctions(const Array& value) const;
  void AddFunction(const Function& function) const;
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

  DoublePtr LookupCanonicalDouble(Zone* zone, double value) const;
  MintPtr LookupCanonicalMint(Zone* zone, int64_t value) const;

  // The methods above are more efficient than this generic one.
  InstancePtr LookupCanonicalInstance(Zone* zone, const Instance& value) const;

  InstancePtr InsertCanonicalConstant(Zone* zone,
                                      const Instance& constant) const;
  void InsertCanonicalDouble(Zone* zone, const Double& constant) const;
  void InsertCanonicalMint(Zone* zone, const Mint& constant) const;

  void RehashConstants(Zone* zone) const;

  bool RequireLegacyErasureOfConstants(Zone* zone) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(ClassLayout));
  }

  bool is_implemented() const { return ImplementedBit::decode(state_bits()); }
  void set_is_implemented() const;

  bool is_abstract() const { return AbstractBit::decode(state_bits()); }
  void set_is_abstract() const;

  ClassLayout::ClassLoadingState class_loading_state() const {
    return ClassLoadingBits::decode(state_bits());
  }

  bool is_declaration_loaded() const {
    return class_loading_state() >= ClassLayout::kDeclarationLoaded;
  }
  void set_is_declaration_loaded() const;

  bool is_type_finalized() const {
    return class_loading_state() >= ClassLayout::kTypeFinalized;
  }
  void set_is_type_finalized() const;

  bool is_synthesized_class() const {
    return SynthesizedClassBit::decode(state_bits());
  }
  void set_is_synthesized_class() const;

  bool is_enum_class() const { return EnumBit::decode(state_bits()); }
  void set_is_enum_class() const;

  bool is_finalized() const {
    return ClassFinalizedBits::decode(state_bits()) ==
               ClassLayout::kFinalized ||
           ClassFinalizedBits::decode(state_bits()) ==
               ClassLayout::kAllocateFinalized;
  }
  void set_is_finalized() const;

  bool is_allocate_finalized() const {
    return ClassFinalizedBits::decode(state_bits()) ==
           ClassLayout::kAllocateFinalized;
  }
  void set_is_allocate_finalized() const;

  bool is_prefinalized() const {
    return ClassFinalizedBits::decode(state_bits()) ==
           ClassLayout::kPreFinalized;
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

  bool is_fields_marked_nullable() const {
    return FieldsMarkedNullableBit::decode(state_bits());
  }
  void set_is_fields_marked_nullable() const;

  bool is_allocated() const { return IsAllocatedBit::decode(state_bits()); }
  void set_is_allocated(bool value) const;

  bool is_loaded() const { return IsLoadedBit::decode(state_bits()); }
  void set_is_loaded(bool value) const;

  uint16_t num_native_fields() const { return raw_ptr()->num_native_fields_; }
  void set_num_native_fields(uint16_t value) const {
    StoreNonPointer(&raw_ptr()->num_native_fields_, value);
  }

  CodePtr allocation_stub() const { return raw_ptr()->allocation_stub(); }
  void set_allocation_stub(const Code& value) const;

  intptr_t kernel_offset() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return raw_ptr()->kernel_offset_;
#endif
  }

  void set_kernel_offset(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    StoreNonPointer(&raw_ptr()->kernel_offset_, value);
#endif
  }

  void DisableAllocationStub() const;

  ArrayPtr constants() const;
  void set_constants(const Array& value) const;

  intptr_t FindInvocationDispatcherFunctionIndex(const Function& needle) const;
  FunctionPtr InvocationDispatcherFunctionFromIndex(intptr_t idx) const;

  FunctionPtr GetInvocationDispatcher(const String& target_name,
                                      const Array& args_desc,
                                      FunctionLayout::Kind kind,
                                      bool create_if_absent) const;

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
  static ClassPtr New(Isolate* isolate, bool register_class = true);

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
  static ClassPtr NewStringClass(intptr_t class_id, Isolate* isolate);

  // Allocate the raw TypedData classes.
  static ClassPtr NewTypedDataClass(intptr_t class_id, Isolate* isolate);

  // Allocate the raw TypedDataView/ByteDataView classes.
  static ClassPtr NewTypedDataViewClass(intptr_t class_id, Isolate* isolate);

  // Allocate the raw ExternalTypedData classes.
  static ClassPtr NewExternalTypedDataClass(intptr_t class_id,
                                            Isolate* isolate);

  // Allocate the raw Pointer classes.
  static ClassPtr NewPointerClass(intptr_t class_id, Isolate* isolate);

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
  ArrayPtr dependent_code() const;
  void set_dependent_code(const Array& array) const;

  bool TraceAllocation(Isolate* isolate) const;
  void SetTraceAllocation(bool trace_allocation) const;

  void ReplaceEnum(IsolateReloadContext* reload_context,
                   const Class& old_enum) const;
  void CopyStaticFieldValues(IsolateReloadContext* reload_context,
                             const Class& old_cls) const;
  void PatchFieldsAndFunctions() const;
  void MigrateImplicitStaticClosures(IsolateReloadContext* context,
                                     const Class& new_cls) const;
  void CopyCanonicalConstants(const Class& old_cls) const;
  void CopyDeclarationType(const Class& old_cls) const;
  void CheckReload(const Class& replacement,
                   IsolateReloadContext* context) const;

  void AddInvocationDispatcher(const String& target_name,
                               const Array& args_desc,
                               const Function& dispatcher) const;

  static int32_t host_instance_size_in_words(const ClassPtr cls) {
    return cls->ptr()->host_instance_size_in_words_;
  }

  static int32_t target_instance_size_in_words(const ClassPtr cls) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return cls->ptr()->target_instance_size_in_words_;
#else
    return host_instance_size_in_words(cls);
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  static int32_t host_next_field_offset_in_words(const ClassPtr cls) {
    return cls->ptr()->host_next_field_offset_in_words_;
  }

  static int32_t target_next_field_offset_in_words(const ClassPtr cls) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return cls->ptr()->target_next_field_offset_in_words_;
#else
    return host_next_field_offset_in_words(cls);
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  static int32_t host_type_arguments_field_offset_in_words(const ClassPtr cls) {
    return cls->ptr()->host_type_arguments_field_offset_in_words_;
  }

  static int32_t target_type_arguments_field_offset_in_words(
      const ClassPtr cls) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return cls->ptr()->target_type_arguments_field_offset_in_words_;
#else
    return host_type_arguments_field_offset_in_words(cls);
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

 private:
  TypePtr declaration_type() const { return raw_ptr()->declaration_type(); }

  // Caches the declaration type of this class.
  void set_declaration_type(const Type& type) const;

  bool CanReloadFinalized(const Class& replacement,
                          IsolateReloadContext* context) const;
  bool CanReloadPreFinalized(const Class& replacement,
                             IsolateReloadContext* context) const;

  // Tells whether instances need morphing for reload.
  bool RequiresInstanceMorphing(const Class& replacement) const;

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
  };
  class ConstBit : public BitField<uint32_t, bool, kConstBit, 1> {};
  class ImplementedBit : public BitField<uint32_t, bool, kImplementedBit, 1> {};
  class ClassFinalizedBits : public BitField<uint32_t,
                                             ClassLayout::ClassFinalizedState,
                                             kClassFinalizedPos,
                                             kClassFinalizedSize> {};
  class ClassLoadingBits : public BitField<uint32_t,
                                           ClassLayout::ClassLoadingState,
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

  void set_name(const String& value) const;
  void set_user_name(const String& value) const;
  const char* GenerateUserVisibleName() const;
  void set_state_bits(intptr_t bits) const;

  FunctionPtr CreateInvocationDispatcher(const String& target_name,
                                         const Array& args_desc,
                                         FunctionLayout::Kind kind) const;

  // Returns the bitmap of unboxed fields
  UnboxedFieldBitmap CalculateFieldOffsets() const;

  // functions_hash_table is in use iff there are at least this many functions.
  static const intptr_t kFunctionLookupHashTreshold = 16;

  // Initial value for the cached number of type arguments.
  static const intptr_t kUnknownNumTypeArguments = -1;

  int16_t num_type_arguments() const { return raw_ptr()->num_type_arguments_; }

  uint32_t state_bits() const {
    // Ensure any following load instructions do not get performed before this
    // one.
    return LoadNonPointer<uint32_t, std::memory_order_acquire>(
        &raw_ptr()->state_bits_);
  }

 public:
  void set_num_type_arguments(intptr_t value) const;

  bool has_pragma() const { return HasPragmaBit::decode(state_bits()); }
  void set_has_pragma(bool has_pragma) const;

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
  void InitEmptyFields();

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
                      Isolate* isolate,
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
};

// Classification of type genericity according to type parameter owners.
enum Genericity {
  kAny,           // Consider type params of current class and functions.
  kCurrentClass,  // Consider type params of current class only.
  kFunctions,     // Consider type params of current and parent functions.
};

class PatchClass : public Object {
 public:
  ClassPtr patched_class() const { return raw_ptr()->patched_class(); }
  ClassPtr origin_class() const { return raw_ptr()->origin_class(); }
  ScriptPtr script() const { return raw_ptr()->script(); }
  ExternalTypedDataPtr library_kernel_data() const {
    return raw_ptr()->library_kernel_data();
  }
  void set_library_kernel_data(const ExternalTypedData& data) const;

  intptr_t library_kernel_offset() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return raw_ptr()->library_kernel_offset_;
#else
    return -1;
#endif
  }
  void set_library_kernel_offset(intptr_t offset) const {
    NOT_IN_PRECOMPILED(
        StoreNonPointer(&raw_ptr()->library_kernel_offset_, offset));
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(PatchClassLayout));
  }
  static bool IsInFullSnapshot(PatchClassPtr cls) {
    NoSafepointScope no_safepoint;
    return Class::IsInFullSnapshot(cls->ptr()->patched_class());
  }

  static PatchClassPtr New(const Class& patched_class,
                           const Class& origin_class);

  static PatchClassPtr New(const Class& patched_class, const Script& source);

 private:
  void set_patched_class(const Class& value) const;
  void set_origin_class(const Class& value) const;
  void set_script(const Script& value) const;

  static PatchClassPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(PatchClass, Object);
  friend class Class;
};

class SingleTargetCache : public Object {
 public:
  CodePtr target() const { return raw_ptr()->target(); }
  void set_target(const Code& target) const;
  static intptr_t target_offset() {
    return OFFSET_OF(SingleTargetCacheLayout, target_);
  }

#define DEFINE_NON_POINTER_FIELD_ACCESSORS(type, name)                         \
  type name() const { return raw_ptr()->name##_; }                             \
  void set_##name(type value) const {                                          \
    StoreNonPointer(&raw_ptr()->name##_, value);                               \
  }                                                                            \
  static intptr_t name##_offset() {                                            \
    return OFFSET_OF(SingleTargetCacheLayout, name##_);                        \
  }

  DEFINE_NON_POINTER_FIELD_ACCESSORS(uword, entry_point);
  DEFINE_NON_POINTER_FIELD_ACCESSORS(intptr_t, lower_limit);
  DEFINE_NON_POINTER_FIELD_ACCESSORS(intptr_t, upper_limit);
#undef DEFINE_NON_POINTER_FIELD_ACCESSORS

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(SingleTargetCacheLayout));
  }

  static SingleTargetCachePtr New();

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(SingleTargetCache, Object);
  friend class Class;
};

class MonomorphicSmiableCall : public Object {
 public:
  CodePtr target() const { return raw_ptr()->target(); }
  classid_t expected_cid() const { return raw_ptr()->expected_cid_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(MonomorphicSmiableCallLayout));
  }

  static MonomorphicSmiableCallPtr New(classid_t expected_cid,
                                       const Code& target);

  static intptr_t expected_cid_offset() {
    return OFFSET_OF(MonomorphicSmiableCallLayout, expected_cid_);
  }

  static intptr_t target_offset() {
    return OFFSET_OF(MonomorphicSmiableCallLayout, target_);
  }

  static intptr_t entrypoint_offset() {
    return OFFSET_OF(MonomorphicSmiableCallLayout, entrypoint_);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(MonomorphicSmiableCall, Object);
  friend class Class;
};

class CallSiteData : public Object {
 public:
  StringPtr target_name() const { return raw_ptr()->target_name(); }
  ArrayPtr arguments_descriptor() const { return raw_ptr()->args_descriptor(); }

  intptr_t TypeArgsLen() const;

  intptr_t CountWithTypeArgs() const;

  intptr_t CountWithoutTypeArgs() const;

  intptr_t SizeWithoutTypeArgs() const;

  intptr_t SizeWithTypeArgs() const;

  static intptr_t target_name_offset() {
    return OFFSET_OF(CallSiteDataLayout, target_name_);
  }

  static intptr_t arguments_descriptor_offset() {
    return OFFSET_OF(CallSiteDataLayout, args_descriptor_);
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
    return raw_ptr()->can_patch_to_monomorphic_;
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UnlinkedCallLayout));
  }

  intptr_t Hashcode() const;
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
class ICData : public CallSiteData {
 public:
  FunctionPtr Owner() const;

  ICDataPtr Original() const;

  void SetOriginal(const ICData& value) const;

  bool IsOriginal() const { return Original() == this->raw(); }

  intptr_t NumArgsTested() const;

  intptr_t deopt_id() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return -1;
#else
    return raw_ptr()->deopt_id_;
#endif
  }

  bool IsImmutable() const;

#if !defined(DART_PRECOMPILED_RUNTIME)
  AbstractTypePtr receivers_static_type() const {
    return raw_ptr()->receivers_static_type();
  }
  bool is_tracking_exactness() const {
    return TrackingExactnessBit::decode(raw_ptr()->state_bits_);
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

  static const intptr_t kLastRecordedDeoptReason = kDeoptUnknown - 1;

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
    // We don't have concurrent RW access to [state_bits_].
    const uint32_t updated_bits =
        MegamorphicBit::update(value, raw_ptr()->state_bits_);

    // Though we ensure that once the state bits are updated, all other previous
    // writes to the IC are visible as well.
    StoreNonPointer<uint32_t, uint32_t, std::memory_order_release>(
        &raw_ptr()->state_bits_, updated_bits);
  }

  // The length of the array. This includes all sentinel entries including
  // the final one.
  intptr_t Length() const;

  // Takes O(result) time!
  intptr_t NumberOfChecks() const;

  // Discounts any checks with usage of zero.
  // Takes O(result)) time!
  intptr_t NumberOfUsedChecks() const;

  // Takes O(n) time!
  bool NumberOfChecksIs(intptr_t n) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(ICDataLayout));
  }

  static intptr_t state_bits_offset() {
    return OFFSET_OF(ICDataLayout, state_bits_);
  }

  static intptr_t NumArgsTestedShift() { return kNumArgsTestedPos; }

  static intptr_t NumArgsTestedMask() {
    return ((1 << kNumArgsTestedSize) - 1) << kNumArgsTestedPos;
  }

  static intptr_t entries_offset() { return OFFSET_OF(ICDataLayout, entries_); }

  static intptr_t owner_offset() { return OFFSET_OF(ICDataLayout, owner_); }

#if !defined(DART_PRECOMPILED_RUNTIME)
  static intptr_t receivers_static_type_offset() {
    return OFFSET_OF(ICDataLayout, receivers_static_type_);
  }
#endif

  // Replaces entry |index| with the sentinel.
  // NOTE: Can only be called during reload.
  void WriteSentinelAt(intptr_t index,
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

  // Returns this->raw() if num_args_tested == 1 and arg_nr == 1, otherwise
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
    return raw_ptr()->entries<std::memory_order_acquire>();
  }

  bool receiver_cannot_be_smi() const {
    return ReceiverCannotBeSmiBit::decode(
        LoadNonPointer(&raw_ptr()->state_bits_));
  }

  void set_receiver_cannot_be_smi(bool value) const {
    set_state_bits(ReceiverCannotBeSmiBit::encode(value) |
                   LoadNonPointer(&raw_ptr()->state_bits_));
  }

 private:
  friend class FlowGraphSerializer;  // For is_megamorphic()

  static ICDataPtr New();

  // Grows the array and also sets the argument to the index that should be used
  // for the new entry.
  ArrayPtr Grow(intptr_t* index) const;

  void set_deopt_id(intptr_t value) const;
  void set_entries(const Array& value) const;
  void set_owner(const Function& value) const;
  void set_rebind_rule(uint32_t rebind_rule) const;
  void set_state_bits(uint32_t bits) const;
  void set_tracking_exactness(bool value) const {
    StoreNonPointer(
        &raw_ptr()->state_bits_,
        TrackingExactnessBit::update(value, raw_ptr()->state_bits_));
  }

  // Does entry |index| contain the sentinel value?
  bool IsSentinelAt(intptr_t index) const;
  void SetNumArgsTested(intptr_t value) const;
  void SetReceiversStaticType(const AbstractType& type) const;

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
    const uint32_t bits = LoadNonPointer<uint32_t, std::memory_order_acquire>(
        &raw_ptr()->state_bits_);
    return MegamorphicBit::decode(bits);
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
                 sizeof(ICDataLayout::state_bits_) * kBitsPerWord);
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
  static ICDataPtr NewDescriptor(Zone* zone,
                                 const Function& owner,
                                 const String& target_name,
                                 const Array& arguments_descriptor,
                                 intptr_t deopt_id,
                                 intptr_t num_args_tested,
                                 RebindRule rebind_rule,
                                 const AbstractType& receiver_type);

  static void WriteSentinel(const Array& data, intptr_t test_entry_length);

  // A cache of VM heap allocated preinitialized empty ic data entry arrays.
  static ArrayPtr cached_icdata_arrays_[kCachedICDataArrayCount];

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ICData, CallSiteData);
  friend class CallSiteResetter;
  friend class CallTargets;
  friend class Class;
  friend class VMDeserializationRoots;
  friend class ICDataTestTask;
  friend class VMSerializationRoots;
  friend class SnapshotWriter;
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

class Function : public Object {
 public:
  StringPtr name() const { return raw_ptr()->name(); }
  StringPtr UserVisibleName() const;  // Same as scrubbed name.
  const char* UserVisibleNameCString() const;

  const char* NameCString(NameVisibility name_visibility) const;

  void PrintName(const NameFormattingParams& params,
                 BaseTextBuffer* printer) const;
  StringPtr QualifiedScrubbedName() const;
  StringPtr QualifiedUserVisibleName() const;
  const char* QualifiedUserVisibleNameCString() const;

  virtual StringPtr DictionaryName() const { return name(); }

  StringPtr GetSource() const;

  // Return the type of this function's signature. It may not be canonical yet.
  // For example, if this function has a signature of the form
  // '(T, [B, C]) => R', where 'T' and 'R' are type parameters of the
  // owner class of this function, then its signature type is a parameterized
  // function type with uninstantiated type arguments 'T' and 'R' as elements of
  // its type argument vector.
  // A function type is non-nullable by default.
  TypePtr SignatureType(
      Nullability nullability = Nullability::kNonNullable) const;
  TypePtr ExistingSignatureType() const;

  // Update the signature type (with a canonical version).
  void SetSignatureType(const Type& value) const;

  // Set the "C signature" function for an FFI trampoline.
  // Can only be used on FFI trampolines.
  void SetFfiCSignature(const Function& sig) const;

  // Retrieves the "C signature" function for an FFI trampoline.
  // Can only be used on FFI trampolines.
  FunctionPtr FfiCSignature() const;

  bool FfiCSignatureContainsHandles() const;
  bool FfiCSignatureReturnsStruct() const;

  // Can only be called on FFI trampolines.
  // -1 for Dart -> native calls.
  int32_t FfiCallbackId() const;

  // Can only be called on FFI trampolines.
  void SetFfiCallbackId(int32_t value) const;

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

  // Return a new function with instantiated result and parameter types.
  FunctionPtr InstantiateSignatureFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space) const;

  // Build a string of the form '<T>(T, {B b, C c}) => R' representing the
  // internal signature of the given function. In this example, T is a type
  // parameter of this function and R is a type parameter of class C, the owner
  // of the function. B and C are not type parameters.
  StringPtr Signature() const;

  // Build a string of the form '<T>(T, {B b, C c}) => R' representing the
  // user visible signature of the given function. In this example, T is a type
  // parameter of this function and R is a type parameter of class C, the owner
  // of the function. B and C are not type parameters.
  // Implicit parameters are hidden.
  StringPtr UserVisibleSignature() const;

  void PrintSignature(NameVisibility name_visibility,
                      BaseTextBuffer* printer) const;

  // Returns true if the signature of this function is instantiated, i.e. if it
  // does not involve generic parameter types or generic result type.
  // Note that function type parameters declared by this function do not make
  // its signature uninstantiated, only type parameters declared by parent
  // generic functions or class type parameters.
  bool HasInstantiatedSignature(Genericity genericity = kAny,
                                intptr_t num_free_fun_type_params = kAllFree,
                                TrailPtr trail = nullptr) const;

  ClassPtr Owner() const;
  void set_owner(const Object& value) const;
  ClassPtr origin() const;
  ScriptPtr script() const;
  ObjectPtr RawOwner() const { return raw_ptr()->owner(); }

  // The NNBD mode of the library declaring this function.
  // TODO(alexmarkov): nnbd_mode() doesn't work for mixins.
  // It should be either removed or fixed.
  NNBDMode nnbd_mode() const { return Class::Handle(origin()).nnbd_mode(); }

  RegExpPtr regexp() const;
  intptr_t string_specialization_cid() const;
  bool is_sticky_specialization() const;
  void SetRegExpData(const RegExp& regexp,
                     intptr_t string_specialization_cid,
                     bool sticky) const;

  StringPtr native_name() const;
  void set_native_name(const String& name) const;

  AbstractTypePtr result_type() const { return raw_ptr()->result_type(); }
  void set_result_type(const AbstractType& value) const;

  // The parameters, starting with NumImplicitParameters() parameters which are
  // only visible to the VM, but not to Dart users.
  // Note that type checks exclude implicit parameters.
  AbstractTypePtr ParameterTypeAt(intptr_t index) const;
  void SetParameterTypeAt(intptr_t index, const AbstractType& value) const;
  ArrayPtr parameter_types() const { return raw_ptr()->parameter_types(); }
  void set_parameter_types(const Array& value) const;
  static intptr_t parameter_types_offset() {
    return OFFSET_OF(FunctionLayout, parameter_types_);
  }

  // Parameter names are valid for all valid parameter indices, and are not
  // limited to named optional parameters. If there are parameter flags (eg
  // required) they're stored at the end of this array, so the size of this
  // array isn't necessarily NumParameters(), but the first NumParameters()
  // elements are the names.
  StringPtr ParameterNameAt(intptr_t index) const;
  void SetParameterNameAt(intptr_t index, const String& value) const;
  ArrayPtr parameter_names() const { return raw_ptr()->parameter_names(); }
  static intptr_t parameter_names_offset() {
    return OFFSET_OF(FunctionLayout, parameter_names_);
  }

  // Sets up the function's parameter name array, including appropriate space
  // for any possible parameter flags. This may be an overestimate if some
  // parameters don't have flags, and so TruncateUnusedParameterFlags() should
  // be called after all parameter flags have been appropriately set.
  //
  // Assumes that the number of fixed and optional parameters for the function
  // has already been set.
  void CreateNameArrayIncludingFlags(Heap::Space space) const;

  // Truncate the parameter names array to remove any unused flag slots. Make
  // sure to only do this after calling SetIsRequiredAt as necessary.
  void TruncateUnusedParameterFlags() const;

  // The required flags are stored at the end of the parameter_names. The flags
  // are packed into Smis.
  bool IsRequiredAt(intptr_t index) const;
  void SetIsRequiredAt(intptr_t index) const;

  // The type parameters (and their bounds) are specified as an array of
  // TypeParameter.
  TypeArgumentsPtr type_parameters() const {
    return raw_ptr()->type_parameters();
  }
  void set_type_parameters(const TypeArguments& value) const;
  static intptr_t type_parameters_offset() {
    return OFFSET_OF(FunctionLayout, type_parameters_);
  }
  intptr_t NumTypeParameters(Thread* thread) const;
  intptr_t NumTypeParameters() const {
    return NumTypeParameters(Thread::Current());
  }

  // Returns true if this function has the same number of type parameters with
  // equal bounds as the other function. Type parameter names are ignored.
  bool HasSameTypeParametersAndBounds(const Function& other,
                                      TypeEquality kind) const;

  // Return the number of type parameters declared in parent generic functions.
  intptr_t NumParentTypeParameters() const;

  // Print the signature type of this function and of all of its parents.
  void PrintSignatureTypes() const;

  // Return a TypeParameter if the type_name is a type parameter of this
  // function or of one of its parent functions.
  // Unless NULL, adjust function_level accordingly (in and out parameter).
  // Return null otherwise.
  TypeParameterPtr LookupTypeParameter(const String& type_name,
                                       intptr_t* function_level) const;

  // Return true if this function declares type parameters.
  bool IsGeneric() const { return NumTypeParameters(Thread::Current()) > 0; }

  // Return true if any parent function of this function is generic.
  bool HasGenericParent() const;

  // Not thread-safe; must be called in the main thread.
  // Sets function's code and code's function.
  void InstallOptimizedCode(const Code& code) const;
  void AttachCode(const Code& value) const;
  void SetInstructions(const Code& value) const;
  void ClearCode() const;

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
  CodePtr CurrentCode() const { return CurrentCodeOf(raw()); }

  bool SafeToClosurize() const;

  static CodePtr CurrentCodeOf(const FunctionPtr function) {
    return function->ptr()->code();
  }

  CodePtr unoptimized_code() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return static_cast<CodePtr>(Object::null());
#else
    return raw_ptr()->unoptimized_code();
#endif
  }
  void set_unoptimized_code(const Code& value) const;
  bool HasCode() const;
  static bool HasCode(FunctionPtr function);

  static intptr_t code_offset() { return OFFSET_OF(FunctionLayout, code_); }

  static intptr_t result_type_offset() {
    return OFFSET_OF(FunctionLayout, result_type_);
  }

  static intptr_t entry_point_offset(
      CodeEntryKind entry_kind = CodeEntryKind::kNormal) {
    switch (entry_kind) {
      case CodeEntryKind::kNormal:
        return OFFSET_OF(FunctionLayout, entry_point_);
      case CodeEntryKind::kUnchecked:
        return OFFSET_OF(FunctionLayout, unchecked_entry_point_);
      default:
        UNREACHABLE();
    }
  }

  static intptr_t unchecked_entry_point_offset() {
    return OFFSET_OF(FunctionLayout, unchecked_entry_point_);
  }

  virtual intptr_t Hash() const;

  // Returns true if there is at least one debugger breakpoint
  // set in this function.
  bool HasBreakpoint() const;

  ContextScopePtr context_scope() const;
  void set_context_scope(const ContextScope& value) const;

  // Enclosing function of this local function.
  FunctionPtr parent_function() const;

  enum class DefaultTypeArgumentsKind : uint8_t {
    // Only here to make sure it's explicitly set appropriately.
    kInvalid = 0,
    // Must instantiate the default type arguments before use.
    kNeedsInstantiation,
    // The default type arguments are already instantiated.
    kIsInstantiated,
    // Use the instantiator type arguments that would be used to instantiate
    // the default type arguments, as instantiating produces the same result.
    kSharesInstantiatorTypeArguments,
    // Use the function type arguments that would be used to instantiate
    // the default type arguments, as instantiating produces the same result.
    kSharesFunctionTypeArguments,
  };
  static constexpr intptr_t kDefaultTypeArgumentsKindFieldSize = 3;
  static_assert(static_cast<uint8_t>(
                    DefaultTypeArgumentsKind::kSharesFunctionTypeArguments) <
                    (1 << kDefaultTypeArgumentsKindFieldSize),
                "Wrong bit size chosen for default TAV kind field");

  // Fields encoded in an integer stored alongside a default TAV. The size of
  // the integer should be <= the size of a target Smi.
  using DefaultTypeArgumentsKindField =
      BitField<intptr_t,
               DefaultTypeArgumentsKind,
               0,
               kDefaultTypeArgumentsKindFieldSize>;
  // Just use the rest of the space for the number of parent type parameters.
  using NumParentTypeParametersField =
      BitField<intptr_t,
               intptr_t,
               DefaultTypeArgumentsKindField::kNextBit,
               compiler::target::kSmiBits -
                   DefaultTypeArgumentsKindField::kNextBit>;

  // Returns a canonicalized vector of the type parameters instantiated
  // to bounds. If non-generic, the empty type arguments vector is returned.
  TypeArgumentsPtr InstantiateToBounds(
      Thread* thread,
      DefaultTypeArgumentsKind* kind_out = nullptr) const;

  // Whether this function should have a cached type arguments vector for the
  // instantiated-to-bounds version of the type parameters.
  bool CachesDefaultTypeArguments() const { return IsClosureFunction(); }

  // Updates the cached default type arguments vector for this function if it
  // caches and for its implicit closure function if it has one. If the
  // default arguments are all canonical, the cached default type arguments
  // vector is canonicalized. Should be run any time the type parameters vector
  // is changed or if the default arguments of any type parameters are updated.
  void UpdateCachedDefaultTypeArguments(Thread* thread) const;

  // These are only usable for functions that cache the default type arguments.
  TypeArgumentsPtr default_type_arguments(
      DefaultTypeArgumentsKind* kind_out = nullptr) const;
  void set_default_type_arguments(const TypeArguments& value) const;

  // Enclosed generated closure function of this local function.
  // This will only work after the closure function has been allocated in the
  // isolate's object_store.
  FunctionPtr GetGeneratedClosure() const;

  // Enclosing outermost function of this local function.
  FunctionPtr GetOutermostFunction() const;

  void set_extracted_method_closure(const Function& function) const;
  FunctionPtr extracted_method_closure() const;

  void set_saved_args_desc(const Array& array) const;
  ArrayPtr saved_args_desc() const;

  void set_accessor_field(const Field& value) const;
  FieldPtr accessor_field() const;

  bool IsRegularFunction() const {
    return kind() == FunctionLayout::kRegularFunction;
  }

  bool IsMethodExtractor() const {
    return kind() == FunctionLayout::kMethodExtractor;
  }

  bool IsNoSuchMethodDispatcher() const {
    return kind() == FunctionLayout::kNoSuchMethodDispatcher;
  }

  bool IsInvokeFieldDispatcher() const {
    return kind() == FunctionLayout::kInvokeFieldDispatcher;
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
    return kind() == FunctionLayout::kDynamicInvocationForwarder;
  }

  bool IsImplicitGetterOrSetter() const {
    return kind() == FunctionLayout::kImplicitGetter ||
           kind() == FunctionLayout::kImplicitSetter ||
           kind() == FunctionLayout::kImplicitStaticGetter;
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
  InstancePtr ImplicitStaticClosure() const;

  InstancePtr ImplicitInstanceClosure(const Instance& receiver) const;

  // Returns the target of the implicit closure or null if the target is now
  // invalid (e.g., mismatched argument shapes after a reload).
  FunctionPtr ImplicitClosureTarget(Zone* zone) const;

  intptr_t ComputeClosureHash() const;

  FunctionPtr ForwardingTarget() const;
  void SetForwardingChecks(const Array& checks) const;

  FunctionLayout::Kind kind() const {
    return KindBits::decode(raw_ptr()->kind_tag_);
  }
  static FunctionLayout::Kind kind(FunctionPtr function) {
    return KindBits::decode(function->ptr()->kind_tag_);
  }

  FunctionLayout::AsyncModifier modifier() const {
    return ModifierBits::decode(raw_ptr()->kind_tag_);
  }

  static const char* KindToCString(FunctionLayout::Kind kind);

  bool IsGenerativeConstructor() const {
    return (kind() == FunctionLayout::kConstructor) && !is_static();
  }
  bool IsImplicitConstructor() const;
  bool IsFactory() const {
    return (kind() == FunctionLayout::kConstructor) && is_static();
  }

  bool HasThisParameter() const {
    return IsDynamicFunction(/*allow_abstract=*/true) ||
           IsGenerativeConstructor() || (IsFieldInitializer() && !is_static());
  }

  bool IsDynamicFunction(bool allow_abstract = false) const {
    if (is_static() || (!allow_abstract && is_abstract())) {
      return false;
    }
    switch (kind()) {
      case FunctionLayout::kRegularFunction:
      case FunctionLayout::kGetterFunction:
      case FunctionLayout::kSetterFunction:
      case FunctionLayout::kImplicitGetter:
      case FunctionLayout::kImplicitSetter:
      case FunctionLayout::kMethodExtractor:
      case FunctionLayout::kNoSuchMethodDispatcher:
      case FunctionLayout::kInvokeFieldDispatcher:
      case FunctionLayout::kDynamicInvocationForwarder:
        return true;
      case FunctionLayout::kClosureFunction:
      case FunctionLayout::kImplicitClosureFunction:
      case FunctionLayout::kSignatureFunction:
      case FunctionLayout::kConstructor:
      case FunctionLayout::kImplicitStaticGetter:
      case FunctionLayout::kFieldInitializer:
      case FunctionLayout::kIrregexpFunction:
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
      case FunctionLayout::kRegularFunction:
      case FunctionLayout::kGetterFunction:
      case FunctionLayout::kSetterFunction:
      case FunctionLayout::kImplicitGetter:
      case FunctionLayout::kImplicitSetter:
      case FunctionLayout::kImplicitStaticGetter:
      case FunctionLayout::kFieldInitializer:
      case FunctionLayout::kIrregexpFunction:
        return true;
      case FunctionLayout::kClosureFunction:
      case FunctionLayout::kImplicitClosureFunction:
      case FunctionLayout::kSignatureFunction:
      case FunctionLayout::kConstructor:
      case FunctionLayout::kMethodExtractor:
      case FunctionLayout::kNoSuchMethodDispatcher:
      case FunctionLayout::kInvokeFieldDispatcher:
      case FunctionLayout::kDynamicInvocationForwarder:
        return false;
      default:
        UNREACHABLE();
        return false;
    }
  }
  bool IsInFactoryScope() const;

  bool NeedsTypeArgumentTypeChecks() const {
    return !(is_static() || (kind() == FunctionLayout::kConstructor));
  }

  bool NeedsArgumentTypeChecks() const {
    return !(is_static() || (kind() == FunctionLayout::kConstructor));
  }

  bool NeedsMonomorphicCheckedEntry(Zone* zone) const;
  bool HasDynamicCallers(Zone* zone) const;
  bool PrologueNeedsArgumentsDescriptor() const;

  bool MayHaveUncheckedEntryPoint() const;

  TokenPosition token_pos() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return TokenPosition::kNoSource;
#else
    return raw_ptr()->token_pos_;
#endif
  }
  void set_token_pos(TokenPosition value) const;

  TokenPosition end_token_pos() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return TokenPosition::kNoSource;
#else
    return raw_ptr()->end_token_pos_;
#endif
  }
  void set_end_token_pos(TokenPosition value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    StoreNonPointer(&raw_ptr()->end_token_pos_, value);
#endif
  }

  // Returns the size of the source for this function.
  intptr_t SourceSize() const;

  intptr_t num_fixed_parameters() const {
    return FunctionLayout::PackedNumFixedParameters::decode(
        raw_ptr()->packed_fields_);
  }
  void set_num_fixed_parameters(intptr_t value) const;

  uint32_t packed_fields() const { return raw_ptr()->packed_fields_; }
  void set_packed_fields(uint32_t packed_fields) const;
  static intptr_t packed_fields_offset() {
    return OFFSET_OF(FunctionLayout, packed_fields_);
  }
  // Reexported so they can be used by the flow graph builders.
  using PackedHasNamedOptionalParameters =
      FunctionLayout::PackedHasNamedOptionalParameters;
  using PackedNumFixedParameters = FunctionLayout::PackedNumFixedParameters;
  using PackedNumOptionalParameters =
      FunctionLayout::PackedNumOptionalParameters;

  bool HasOptionalParameters() const {
    return PackedNumOptionalParameters::decode(raw_ptr()->packed_fields_) > 0;
  }
  bool HasOptionalNamedParameters() const {
    return HasOptionalParameters() &&
           PackedHasNamedOptionalParameters::decode(raw_ptr()->packed_fields_);
  }
  bool HasOptionalPositionalParameters() const {
    return HasOptionalParameters() && !HasOptionalNamedParameters();
  }
  intptr_t NumOptionalParameters() const {
    return PackedNumOptionalParameters::decode(raw_ptr()->packed_fields_);
  }
  void SetNumOptionalParameters(intptr_t num_optional_parameters,
                                bool are_optional_positional) const;

  intptr_t NumOptionalPositionalParameters() const {
    return HasOptionalPositionalParameters() ? NumOptionalParameters() : 0;
  }

  intptr_t NumOptionalNamedParameters() const {
    return HasOptionalNamedParameters() ? NumOptionalParameters() : 0;
  }

  intptr_t NumParameters() const;

  intptr_t NumImplicitParameters() const;

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
    return OFFSET_OF(FunctionLayout, name##_);                                 \
  }                                                                            \
  return_type name() const { return raw_ptr()->name##_; }                      \
                                                                               \
  void set_##name(type value) const {                                          \
    StoreNonPointer(&raw_ptr()->name##_, value);                               \
  }
#endif

  JIT_FUNCTION_COUNTERS(DEFINE_GETTERS_AND_SETTERS)

#undef DEFINE_GETTERS_AND_SETTERS

  intptr_t kernel_offset() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return raw_ptr()->kernel_offset_;
#endif
  }

  void set_kernel_offset(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    StoreNonPointer(&raw_ptr()->kernel_offset_, value);
#endif
  }

  void InheritKernelOffsetFrom(const Function& src) const;
  void InheritKernelOffsetFrom(const Field& src) const;

  static const intptr_t kMaxInstructionCount = (1 << 16) - 1;

  void SetOptimizedInstructionCountClamped(uintptr_t value) const {
    if (value > kMaxInstructionCount) value = kMaxInstructionCount;
    set_optimized_instruction_count(value);
  }

  void SetOptimizedCallSiteCountClamped(uintptr_t value) const {
    if (value > kMaxInstructionCount) value = kMaxInstructionCount;
    set_optimized_call_site_count(value);
  }

  void SetKernelDataAndScript(const Script& script,
                              const ExternalTypedData& data,
                              intptr_t offset) const;

  intptr_t KernelDataProgramOffset() const;

  ExternalTypedDataPtr KernelData() const;

  bool IsOptimizable() const;
  void SetIsOptimizable(bool value) const;

  // Whether this function must be optimized immediately and cannot be compiled
  // with the unoptimizing compiler. Such a function must be sure to not
  // deoptimize, since we won't generate deoptimization info or register
  // dependencies. It will be compiled into optimized code immediately when it's
  // run.
  bool ForceOptimize() const {
    return IsFfiFromAddress() || IsFfiGetAddress() || IsFfiLoad() ||
           IsFfiStore() || IsFfiTrampoline() || IsTypedDataViewFactory() ||
           IsUtf8Scan();
  }

  bool CanBeInlined() const;

  MethodRecognizer::Kind recognized_kind() const {
    return RecognizedBits::decode(raw_ptr()->kind_tag_);
  }
  void set_recognized_kind(MethodRecognizer::Kind value) const;

  bool IsRecognized() const {
    return recognized_kind() != MethodRecognizer::kUnknown;
  }

  bool HasOptimizedCode() const;

  // Returns true if the argument counts are valid for calling this function.
  // Otherwise, it returns false and the reason (if error_message is not NULL).
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
  // Otherwise, it returns false and the reason (if error_message is not NULL).
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
    return FunctionLayout::UnboxedParameterBitmap::kCapacity - 1;
  }

  void reset_unboxed_parameters_and_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    StoreNonPointer(&raw_ptr()->unboxed_parameters_info_,
                    FunctionLayout::UnboxedParameterBitmap());
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  void set_unboxed_integer_parameter_at(intptr_t index) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(index >= 0 && index < maximum_unboxed_parameter_count());
    index++;  // position 0 is reserved for the return value
    const_cast<FunctionLayout::UnboxedParameterBitmap*>(
        &raw_ptr()->unboxed_parameters_info_)
        ->SetUnboxedInteger(index);
#else
    UNREACHABLE();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  void set_unboxed_double_parameter_at(intptr_t index) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(index >= 0 && index < maximum_unboxed_parameter_count());
    index++;  // position 0 is reserved for the return value
    const_cast<FunctionLayout::UnboxedParameterBitmap*>(
        &raw_ptr()->unboxed_parameters_info_)
        ->SetUnboxedDouble(index);

#else
    UNREACHABLE();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  void set_unboxed_integer_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    const_cast<FunctionLayout::UnboxedParameterBitmap*>(
        &raw_ptr()->unboxed_parameters_info_)
        ->SetUnboxedInteger(0);
#else
    UNREACHABLE();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  void set_unboxed_double_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    const_cast<FunctionLayout::UnboxedParameterBitmap*>(
        &raw_ptr()->unboxed_parameters_info_)
        ->SetUnboxedDouble(0);

#else
    UNREACHABLE();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool is_unboxed_parameter_at(intptr_t index) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(index >= 0);
    index++;  // position 0 is reserved for the return value
    return raw_ptr()->unboxed_parameters_info_.IsUnboxed(index);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool is_unboxed_integer_parameter_at(intptr_t index) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(index >= 0);
    index++;  // position 0 is reserved for the return value
    return raw_ptr()->unboxed_parameters_info_.IsUnboxedInteger(index);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool is_unboxed_double_parameter_at(intptr_t index) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    ASSERT(index >= 0);
    index++;  // position 0 is reserved for the return value
    return raw_ptr()->unboxed_parameters_info_.IsUnboxedDouble(index);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool has_unboxed_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return raw_ptr()->unboxed_parameters_info_.IsUnboxed(0);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool has_unboxed_integer_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return raw_ptr()->unboxed_parameters_info_.IsUnboxedInteger(0);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

  bool has_unboxed_double_return() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return raw_ptr()->unboxed_parameters_info_.IsUnboxedDouble(0);
#else
    return false;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  bool HasUnboxedParameters() const {
    return raw_ptr()->unboxed_parameters_info_.HasUnboxedParameters();
  }
  bool HasUnboxedReturnValue() const {
    return raw_ptr()->unboxed_parameters_info_.HasUnboxedReturnValue();
  }
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)

  // Returns true if the type of this function is a subtype of the type of
  // the other function.
  bool IsSubtypeOf(const Function& other, Heap::Space space) const;

  bool IsDispatcherOrImplicitAccessor() const {
    switch (kind()) {
      case FunctionLayout::kImplicitGetter:
      case FunctionLayout::kImplicitSetter:
      case FunctionLayout::kImplicitStaticGetter:
      case FunctionLayout::kNoSuchMethodDispatcher:
      case FunctionLayout::kInvokeFieldDispatcher:
      case FunctionLayout::kDynamicInvocationForwarder:
        return true;
      default:
        return false;
    }
  }

  // Returns true if this function represents an explicit getter function.
  bool IsGetterFunction() const {
    return kind() == FunctionLayout::kGetterFunction;
  }

  // Returns true if this function represents an implicit getter function.
  bool IsImplicitGetterFunction() const {
    return kind() == FunctionLayout::kImplicitGetter;
  }

  // Returns true if this function represents an implicit static getter
  // function.
  bool IsImplicitStaticGetterFunction() const {
    return kind() == FunctionLayout::kImplicitStaticGetter;
  }

  // Returns true if this function represents an explicit setter function.
  bool IsSetterFunction() const {
    return kind() == FunctionLayout::kSetterFunction;
  }

  // Returns true if this function represents an implicit setter function.
  bool IsImplicitSetterFunction() const {
    return kind() == FunctionLayout::kImplicitSetter;
  }

  // Returns true if this function represents an initializer for a static or
  // instance field. The function returns the initial value and the caller is
  // responsible for setting the field.
  bool IsFieldInitializer() const {
    return kind() == FunctionLayout::kFieldInitializer;
  }

  // Returns true if this function represents a (possibly implicit) closure
  // function.
  bool IsClosureFunction() const {
    FunctionLayout::Kind k = kind();
    return (k == FunctionLayout::kClosureFunction) ||
           (k == FunctionLayout::kImplicitClosureFunction);
  }

  // Returns true if this function represents a generated irregexp function.
  bool IsIrregexpFunction() const {
    return kind() == FunctionLayout::kIrregexpFunction;
  }

  // Returns true if this function represents an implicit closure function.
  bool IsImplicitClosureFunction() const {
    return kind() == FunctionLayout::kImplicitClosureFunction;
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

  // Returns true if this function represents a local function.
  bool IsLocalFunction() const { return parent_function() != Function::null(); }

  // Returns true if this function represents a signature function without code.
  bool IsSignatureFunction() const {
    return kind() == FunctionLayout::kSignatureFunction;
  }
  static bool IsSignatureFunction(FunctionPtr function) {
    NoSafepointScope no_safepoint;
    return KindBits::decode(function->ptr()->kind_tag_) ==
           FunctionLayout::kSignatureFunction;
  }

  // Returns true if this function represents an ffi trampoline.
  bool IsFfiTrampoline() const {
    return kind() == FunctionLayout::kFfiTrampoline;
  }
  static bool IsFfiTrampoline(FunctionPtr function) {
    NoSafepointScope no_safepoint;
    return KindBits::decode(function->ptr()->kind_tag_) ==
           FunctionLayout::kFfiTrampoline;
  }

  bool IsFfiLoad() const {
    const auto kind = recognized_kind();
    return MethodRecognizer::kFfiLoadInt8 <= kind &&
           kind <= MethodRecognizer::kFfiLoadPointer;
  }

  bool IsFfiStore() const {
    const auto kind = recognized_kind();
    return MethodRecognizer::kFfiStoreInt8 <= kind &&
           kind <= MethodRecognizer::kFfiStorePointer;
  }

  bool IsFfiFromAddress() const {
    const auto kind = recognized_kind();
    return kind == MethodRecognizer::kFfiFromAddress;
  }

  bool IsFfiGetAddress() const {
    const auto kind = recognized_kind();
    return kind == MethodRecognizer::kFfiGetAddress;
  }

  bool IsUtf8Scan() const {
    const auto kind = recognized_kind();
    return kind == MethodRecognizer::kUtf8DecoderScan;
  }

  // Recognise async functions like:
  //   user_func async {
  //     // ...
  //   }
  bool IsAsyncFunction() const { return modifier() == FunctionLayout::kAsync; }

  // Recognise synthetic sync-yielding functions like the inner-most:
  //   user_func /* was async */ {
  //      :async_op(..) yielding {
  //        // ...
  //      }
  //   }
  bool IsAsyncClosure() const {
    return is_generated_body() &&
           Function::Handle(parent_function()).IsAsyncFunction();
  }

  // Recognise sync* functions like:
  //   user_func sync* {
  //     // ...
  //   }
  bool IsSyncGenerator() const {
    return modifier() == FunctionLayout::kSyncGen;
  }

  // Recognise synthetic :sync_op_gen()s like:
  //   user_func /* was sync* */ {
  //     :sync_op_gen() {
  //        // ...
  //      }
  //   }
  bool IsSyncGenClosureMaker() const {
    return is_generated_body() &&
           Function::Handle(parent_function()).IsSyncGenerator();
  }

  // Recognise async* functions like:
  //   user_func async* {
  //     // ...
  //   }
  bool IsAsyncGenerator() const {
    return modifier() == FunctionLayout::kAsyncGen;
  }

  // Recognise synthetic sync-yielding functions like the inner-most:
  //   user_func /* originally async* */ {
  //      :async_op(..) yielding {
  //        // ...
  //      }
  //   }
  bool IsAsyncGenClosure() const {
    return is_generated_body() &&
           Function::Handle(parent_function()).IsAsyncGenerator();
  }

  bool IsAsyncOrGenerator() const {
    return modifier() != FunctionLayout::kNoModifier;
  }

  // Recognise synthetic sync-yielding functions like the inner-most:
  //   user_func /* was sync* */ {
  //     :sync_op_gen() {
  //        :sync_op(..) yielding {
  //          // ...
  //        }
  //      }
  //   }
  bool IsSyncGenClosure() const {
    return (parent_function() != Function::null()) &&
           Function::Handle(parent_function()).IsSyncGenClosureMaker();
  }

  bool IsTypedDataViewFactory() const {
    if (is_native() && kind() == FunctionLayout::kConstructor) {
      // This is a native factory constructor.
      const Class& klass = Class::Handle(Owner());
      return IsTypedDataViewClassId(klass.id());
    }
    return false;
  }

  DART_WARN_UNUSED_RESULT
  ErrorPtr VerifyCallEntryPoint() const;

  DART_WARN_UNUSED_RESULT
  ErrorPtr VerifyClosurizedEntryPoint() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(FunctionLayout));
  }

  static FunctionPtr New(const String& name,
                         FunctionLayout::Kind kind,
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
  static FunctionPtr NewClosureFunctionWithKind(FunctionLayout::Kind kind,
                                                const String& name,
                                                const Function& parent,
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

  // Allocates a new Function object representing a signature function.
  // The owner is the scope class of the function type.
  // The parent is the enclosing function or null if none.
  static FunctionPtr NewSignatureFunction(const Object& owner,
                                          const Function& parent,
                                          TokenPosition token_pos,
                                          Heap::Space space = Heap::kOld);

  static FunctionPtr NewEvalFunction(const Class& owner,
                                     const Script& script,
                                     bool is_static);

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
      const Array& edge_counters_array) const;
  // Uses 'ic_data_array' to populate the table 'deopt_id_to_ic_data'. Clone
  // ic_data (array and descriptor) if 'clone_ic_data' is true.
  void RestoreICDataMap(ZoneGrowableArray<const ICData*>* deopt_id_to_ic_data,
                        bool clone_ic_data) const;

  ArrayPtr ic_data_array() const;
  void ClearICDataArray() const;
  ICDataPtr FindICData(intptr_t deopt_id) const;

  // Sets deopt reason in all ICData-s with given deopt_id.
  void SetDeoptReasonForAll(intptr_t deopt_id, ICData::DeoptReasonId reason);

  void set_modifier(FunctionLayout::AsyncModifier value) const;

// 'WasCompiled' is true if the function was compiled once in this
// VM instantiation. It is independent from presence of type feedback
// (ic_data_array) and code, which may be loaded from a snapshot.
// 'WasExecuted' is true if the usage counter has ever been positive.
// 'ProhibitsHoistingCheckClass' is true if this function deoptimized before on
// a hoisted check class instruction.
// 'ProhibitsBoundsCheckGeneralization' is true if this function deoptimized
// before on a generalized bounds check.
#define STATE_BITS_LIST(V)                                                     \
  V(WasCompiled)                                                               \
  V(WasExecutedBit)                                                            \
  V(ProhibitsHoistingCheckClass)                                               \
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

  static intptr_t data_offset() { return OFFSET_OF(FunctionLayout, data_); }

  static intptr_t kind_tag_offset() {
    return OFFSET_OF(FunctionLayout, kind_tag_);
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
  // instrinsic: Has a hand-written assembly prologue.
  // inlinable: Candidate for inlining. False for functions with features we
  //            don't support during inlining (e.g., optional parameters),
  //            functions which are too big, etc.
  // native: Bridge to C/C++ code.
  // external: Just a declaration that expects to be defined in another patch
  //           file.
  // generated_body: Has a generated body.
  // polymorphic_target: A polymorphic method.
  // has_pragma: Has a @pragma decoration.
  // no_such_method_forwarder: A stub method that just calls noSuchMethod.

#define FOR_EACH_FUNCTION_KIND_BIT(V)                                          \
  V(Static, is_static)                                                         \
  V(Const, is_const)                                                           \
  V(Abstract, is_abstract)                                                     \
  V(Reflectable, is_reflectable)                                               \
  V(Visible, is_visible)                                                       \
  V(Debuggable, is_debuggable)                                                 \
  V(Inlinable, is_inlinable)                                                   \
  V(Intrinsic, is_intrinsic)                                                   \
  V(Native, is_native)                                                         \
  V(External, is_external)                                                     \
  V(GeneratedBody, is_generated_body)                                          \
  V(PolymorphicTarget, is_polymorphic_target)                                  \
  V(HasPragma, has_pragma)                                                     \
  V(IsSynthetic, is_synthetic)                                                 \
  V(IsExtensionMember, is_extension_member)

#define DEFINE_ACCESSORS(name, accessor_name)                                  \
  void set_##accessor_name(bool value) const {                                 \
    set_kind_tag(name##Bit::update(value, raw_ptr()->kind_tag_));              \
  }                                                                            \
  bool accessor_name() const { return name##Bit::decode(raw_ptr()->kind_tag_); }
  FOR_EACH_FUNCTION_KIND_BIT(DEFINE_ACCESSORS)
#undef DEFINE_ACCESSORS

  // optimizable: Candidate for going through the optimizing compiler. False for
  //              some functions known to be execute infrequently and functions
  //              which have been de-optimized too many times.
  bool is_optimizable() const {
    return FunctionLayout::OptimizableBit::decode(raw_ptr()->packed_fields_);
  }
  void set_is_optimizable(bool value) const {
    set_packed_fields(FunctionLayout::OptimizableBit::update(
        value, raw_ptr()->packed_fields_));
  }

  // Indicates whether this function can be optimized on the background compiler
  // thread.
  bool is_background_optimizable() const {
    return FunctionLayout::BackgroundOptimizableBit::decode(
        raw_ptr()->packed_fields_);
  }

  void set_is_background_optimizable(bool value) const {
    set_packed_fields(FunctionLayout::BackgroundOptimizableBit::update(
        value, raw_ptr()->packed_fields_));
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
#undef DECLARE_BIT
        kNumTagBits
  };

  COMPILE_ASSERT(MethodRecognizer::kNumRecognizedMethods <
                 (1 << kRecognizedTagSize));
  COMPILE_ASSERT(kNumTagBits <=
                 (kBitsPerByte * sizeof(decltype(FunctionLayout::kind_tag_))));

  class KindBits : public BitField<uint32_t,
                                   FunctionLayout::Kind,
                                   kKindTagPos,
                                   kKindTagSize> {};

  class RecognizedBits : public BitField<uint32_t,
                                         MethodRecognizer::Kind,
                                         kRecognizedTagPos,
                                         kRecognizedTagSize> {};
  class ModifierBits : public BitField<uint32_t,
                                       FunctionLayout::AsyncModifier,
                                       kModifierPos,
                                       kModifierSize> {};

#define DEFINE_BIT(name, _)                                                    \
  class name##Bit : public BitField<uint32_t, bool, k##name##Bit, 1> {};
  FOR_EACH_FUNCTION_KIND_BIT(DEFINE_BIT)
#undef DEFINE_BIT

 private:
  // Given the provided defaults type arguments, determines which
  // DefaultTypeArgumentsKind applies.
  DefaultTypeArgumentsKind DefaultTypeArgumentsKindFor(
      const TypeArguments& defaults) const;

  void set_parameter_names(const Array& value) const;
  void set_ic_data_array(const Array& value) const;
  void SetInstructionsSafe(const Code& value) const;
  void set_name(const String& value) const;
  void set_kind(FunctionLayout::Kind value) const;
  void set_parent_function(const Function& value) const;
  FunctionPtr implicit_closure_function() const;
  void set_implicit_closure_function(const Function& value) const;
  InstancePtr implicit_static_closure() const;
  void set_implicit_static_closure(const Instance& closure) const;
  ScriptPtr eval_script() const;
  void set_eval_script(const Script& value) const;
  void set_num_optional_parameters(intptr_t value) const;  // Encoded value.
  void set_kind_tag(uint32_t value) const;
  void set_data(const Object& value) const;
  static FunctionPtr New(Heap::Space space = Heap::kOld);

  void PrintSignatureParameters(Thread* thread,
                                Zone* zone,
                                NameVisibility name_visibility,
                                BaseTextBuffer* printer) const;

  // Returns true if the type of the formal parameter at the given position in
  // this function is contravariant with the type of the other formal parameter
  // at the given position in the other function.
  bool IsContravariantParameter(intptr_t parameter_position,
                                const Function& other,
                                intptr_t other_parameter_position,
                                Heap::Space space) const;

  // Returns the index in the parameter names array of the corresponding flag
  // for the given parametere index. Also returns (via flag_mask) the
  // corresponding mask within the flag.
  intptr_t GetRequiredFlagIndex(intptr_t index, intptr_t* flag_mask) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Function, Object);
  friend class Class;
  friend class SnapshotWriter;
  friend class Parser;  // For set_eval_script.
  friend class ProgramVisitor;  // For set_parameter_names.
  // FunctionLayout::VisitFunctionPointers accesses the private constructor of
  // Function.
  friend class FunctionLayout;
  friend class ClassFinalizer;  // To reset parent_function.
  friend class Type;            // To adjust parent_function.
};

class ClosureData : public Object {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(ClosureDataLayout));
  }

  static intptr_t default_type_arguments_offset() {
    return OFFSET_OF(ClosureDataLayout, default_type_arguments_);
  }
  static intptr_t default_type_arguments_info_offset() {
    return OFFSET_OF(ClosureDataLayout, default_type_arguments_info_);
  }

 private:
  ContextScopePtr context_scope() const { return raw_ptr()->context_scope_; }
  void set_context_scope(const ContextScope& value) const;

  // Enclosing function of this local function.
  FunctionPtr parent_function() const { return raw_ptr()->parent_function_; }
  void set_parent_function(const Function& value) const;

  // Signature type of this closure function.
  TypePtr signature_type() const { return raw_ptr()->signature_type_; }
  void set_signature_type(const Type& value) const;

  InstancePtr implicit_static_closure() const { return raw_ptr()->closure_; }
  void set_implicit_static_closure(const Instance& closure) const;

  TypeArgumentsPtr default_type_arguments() const {
    return raw_ptr()->default_type_arguments_;
  }
  void set_default_type_arguments(const TypeArguments& value) const;

  intptr_t default_type_arguments_info() const;
  void set_default_type_arguments_info(intptr_t value) const;

  static ClosureDataPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ClosureData, Object);
  friend class Class;
  friend class Function;
  friend class HeapProfiler;
};

class SignatureData : public Object {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(SignatureDataLayout));
  }

 private:
  // Enclosing function of this signature function.
  FunctionPtr parent_function() const { return raw_ptr()->parent_function(); }
  void set_parent_function(const Function& value) const;

  // Signature type of this signature function.
  TypePtr signature_type() const { return raw_ptr()->signature_type(); }
  void set_signature_type(const Type& value) const;

  static SignatureDataPtr New(Heap::Space space = Heap::kOld);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(SignatureData, Object);
  friend class Class;
  friend class Function;
  friend class HeapProfiler;
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
    return RoundedAllocationSize(sizeof(FfiTrampolineDataLayout));
  }

 private:
  // Signature type of this closure function.
  TypePtr signature_type() const { return raw_ptr()->signature_type(); }
  void set_signature_type(const Type& value) const;

  FunctionPtr c_signature() const { return raw_ptr()->c_signature(); }
  void set_c_signature(const Function& value) const;

  FunctionPtr callback_target() const { return raw_ptr()->callback_target(); }
  void set_callback_target(const Function& value) const;

  InstancePtr callback_exceptional_return() const {
    return raw_ptr()->callback_exceptional_return();
  }
  void set_callback_exceptional_return(const Instance& value) const;

  int32_t callback_id() const { return raw_ptr()->callback_id_; }
  void set_callback_id(int32_t value) const;

  static FfiTrampolineDataPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(FfiTrampolineData, Object);
  friend class Class;
  friend class Function;
  friend class HeapProfiler;
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
    return !raw_ptr()->owner()->IsField();
  }

  // Mark previously unboxed field boxed. Only operates on clones, updates
  // original as well as this clone.
  void DisableFieldUnboxing() const;
  // Returns a field cloned from 'this'. 'this' is set as the
  // original field of result.
  FieldPtr CloneFromOriginal() const;

  StringPtr name() const { return raw_ptr()->name(); }
  StringPtr UserVisibleName() const;  // Same as scrubbed name.
  const char* UserVisibleNameCString() const;
  virtual StringPtr DictionaryName() const { return name(); }

  uint16_t kind_bits() const {
    return LoadNonPointer<uint16_t, std::memory_order_acquire>(
        &raw_ptr()->kind_bits_);
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
    set_kind_bits(ReflectableBit::update(value, raw_ptr()->kind_bits_));
  }
  bool is_double_initialized() const {
    return DoubleInitializedBit::decode(kind_bits());
  }
  // Called in parser after allocating field, immutable property otherwise.
  // Marks fields that are initialized with a simple double constant.
  void set_is_double_initialized(bool value) const {
    ASSERT(Thread::Current()->IsMutatorThread());
    ASSERT(IsOriginal());
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(DoubleInitializedBit::update(value, raw_ptr()->kind_bits_));
  }

  bool initializer_changed_after_initialization() const {
    return InitializerChangedAfterInitializatonBit::decode(kind_bits());
  }
  void set_initializer_changed_after_initialization(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(InitializerChangedAfterInitializatonBit::update(
        value, raw_ptr()->kind_bits_));
  }

  bool has_pragma() const { return HasPragmaBit::decode(kind_bits()); }
  void set_has_pragma(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(HasPragmaBit::update(value, raw_ptr()->kind_bits_));
  }

  bool is_covariant() const { return CovariantBit::decode(kind_bits()); }
  void set_is_covariant(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(CovariantBit::update(value, raw_ptr()->kind_bits_));
  }

  bool is_generic_covariant_impl() const {
    return GenericCovariantImplBit::decode(kind_bits());
  }
  void set_is_generic_covariant_impl(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(
        GenericCovariantImplBit::update(value, raw_ptr()->kind_bits_));
  }

  intptr_t kernel_offset() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return raw_ptr()->kernel_offset_;
#endif
  }

  void set_kernel_offset(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    StoreNonPointer(&raw_ptr()->kernel_offset_, value);
#endif
  }

  void InheritKernelOffsetFrom(const Field& src) const;

  ExternalTypedDataPtr KernelData() const;

  intptr_t KernelDataProgramOffset() const;

  // Called during class finalization.
  inline void SetOffset(intptr_t host_offset_in_bytes,
                        intptr_t target_offset_in_bytes) const;

  inline intptr_t HostOffset() const;
  static intptr_t host_offset_or_field_id_offset() {
    return OFFSET_OF(FieldLayout, host_offset_or_field_id_);
  }

  inline intptr_t TargetOffset() const;
  static inline intptr_t TargetOffsetOf(FieldPtr field);

  inline InstancePtr StaticValue() const;
  void SetStaticValue(const Instance& value,
                      bool save_initial_value = false) const;

  inline intptr_t field_id() const;
  inline void set_field_id(intptr_t field_id) const;

  ClassPtr Owner() const;
  ClassPtr Origin() const;  // Either mixin class, or same as owner().
  ScriptPtr Script() const;
  ObjectPtr RawOwner() const;

  AbstractTypePtr type() const { return raw_ptr()->type(); }
  // Used by class finalizer, otherwise initialized in constructor.
  void SetFieldType(const AbstractType& value) const;

  DART_WARN_UNUSED_RESULT
  ErrorPtr VerifyEntryPoint(EntryPointPragma kind) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(FieldLayout));
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
    return OFFSET_OF(FieldLayout, kind_bits_);
  }

  TokenPosition token_pos() const { return raw_ptr()->token_pos_; }
  TokenPosition end_token_pos() const { return raw_ptr()->end_token_pos_; }

  int32_t SourceFingerprint() const;

  StringPtr InitializingExpression() const;

  bool has_nontrivial_initializer() const {
    return HasNontrivialInitializerBit::decode(kind_bits());
  }
  // Called by parser after allocating field.
  void set_has_nontrivial_initializer(bool has_nontrivial_initializer) const {
    ASSERT(IsOriginal());
    ASSERT(Thread::Current()->IsMutatorThread());
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(HasNontrivialInitializerBit::update(
        has_nontrivial_initializer, raw_ptr()->kind_bits_));
  }

  bool has_initializer() const {
    return HasInitializerBit::decode(kind_bits());
  }
  // Called by parser after allocating field.
  void set_has_initializer(bool has_initializer) const {
    ASSERT(IsOriginal());
    ASSERT(Thread::Current()->IsMutatorThread());
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(
        HasInitializerBit::update(has_initializer, raw_ptr()->kind_bits_));
  }

  bool has_trivial_initializer() const {
    return has_initializer() && !has_nontrivial_initializer();
  }

  bool is_non_nullable_integer() const {
    return IsNonNullableIntBit::decode(kind_bits());
  }

  void set_is_non_nullable_integer(bool is_non_nullable_integer) const {
    ASSERT(Thread::Current()->IsMutatorThread());
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(IsNonNullableIntBit::update(is_non_nullable_integer,
                                              raw_ptr()->kind_bits_));
  }

  StaticTypeExactnessState static_type_exactness_state() const {
    return StaticTypeExactnessState::Decode(
        raw_ptr()->static_type_exactness_state_);
  }

  void set_static_type_exactness_state(StaticTypeExactnessState state) const {
    StoreNonPointer(&raw_ptr()->static_type_exactness_state_, state.Encode());
  }

  static intptr_t static_type_exactness_state_offset() {
    return OFFSET_OF(FieldLayout, static_type_exactness_state_);
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
    StoreNonPointer(&raw_ptr()->guarded_cid_, cid);
  }
  static intptr_t guarded_cid_offset() {
    return OFFSET_OF(FieldLayout, guarded_cid_);
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
    return OFFSET_OF(FieldLayout, guarded_list_length_);
  }
  intptr_t guarded_list_length_in_object_offset() const;
  void set_guarded_list_length_in_object_offset_unsafe(intptr_t offset) const;
  void set_guarded_list_length_in_object_offset(intptr_t offset) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_guarded_list_length_in_object_offset_unsafe(offset);
  }
  static intptr_t guarded_list_length_in_object_offset_offset() {
    return OFFSET_OF(FieldLayout, guarded_list_length_in_object_offset_);
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

  intptr_t UnboxedFieldCid() const { return guarded_cid(); }

  bool is_unboxing_candidate() const {
    return UnboxingCandidateBit::decode(kind_bits());
  }

  // Default 'true', set to false once optimizing compiler determines it should
  // be boxed.
  void set_is_unboxing_candidate_unsafe(bool b) const {
    set_kind_bits(UnboxingCandidateBit::update(b, raw_ptr()->kind_bits_));
  }

  void set_is_unboxing_candidate(bool b) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_is_unboxing_candidate_unsafe(b);
  }

  enum {
    kUnknownLengthOffset = -1,
    kUnknownFixedLength = -1,
    kNoFixedLength = -2,
  };
  void set_is_late(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(IsLateBit::update(value, raw_ptr()->kind_bits_));
  }
  void set_is_extension_member(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(IsExtensionMemberBit::update(value, raw_ptr()->kind_bits_));
  }
  void set_needs_load_guard(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(NeedsLoadGuardBit::update(value, raw_ptr()->kind_bits_));
  }
  // Returns false if any value read from this field is guaranteed to be
  // not null.
  // Internally we is_nullable_ field contains either kNullCid (nullable) or
  // kInvalidCid (non-nullable) instead of boolean. This is done to simplify
  // guarding sequence in the generated code.
  bool is_nullable(bool silence_assert = false) const {
#if defined(DEBUG)
    if (!silence_assert) {
      // Same assert as guarded_cid(), because is_nullable() also needs to be
      // consistent for the background compiler.
      Thread* thread = Thread::Current();
      ASSERT(!IsOriginal() || is_static() || thread->IsMutatorThread() ||
             thread->IsAtSafepoint());
    }
#endif
    return raw_ptr()->is_nullable_ == kNullCid;
  }
  void set_is_nullable(bool val) const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    set_is_nullable_unsafe(val);
  }
  void set_is_nullable_unsafe(bool val) const {
    ASSERT(Thread::Current()->IsMutatorThread());
    StoreNonPointer(&raw_ptr()->is_nullable_, val ? kNullCid : kIllegalCid);
  }
  static intptr_t is_nullable_offset() {
    return OFFSET_OF(FieldLayout, is_nullable_);
  }

  // Record store of the given value into this field. May trigger
  // deoptimization of dependent optimized code.
  void RecordStore(const Object& value) const;

  void InitializeGuardedListLengthInObjectOffset(bool unsafe = false) const;

  // Return the list of optimized code objects that were optimized under
  // assumptions about guarded class id and nullability of this field.
  // These code objects must be deoptimized when field's properties change.
  // Code objects are held weakly via an indirection through WeakProperty.
  ArrayPtr dependent_code() const;
  void set_dependent_code(const Array& array) const;

  // Add the given code object to the list of dependent ones.
  void RegisterDependentCode(const Code& code) const;

  // Deoptimize all dependent code objects.
  void DeoptimizeDependentCode() const;

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
    return raw_ptr()->initializer_function<std::memory_order_acquire>();
  }
  void SetInitializerFunction(const Function& initializer) const;
  bool HasInitializerFunction() const;
  static intptr_t initializer_function_offset() {
    return OFFSET_OF(FieldLayout, initializer_function_);
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

#if !defined(DART_PRECOMPILED_RUNTIME)
  SubtypeTestCachePtr type_test_cache() const {
    return raw_ptr()->type_test_cache();
  }
  void set_type_test_cache(const SubtypeTestCache& cache) const;
#endif

  // Unboxed fields require exclusive ownership of the box.
  // Ensure this by cloning the box if necessary.
  const Object* CloneForUnboxed(const Object& value) const;

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
  friend class StoreInstanceFieldInstr;  // Generated code access to bit field.

  enum {
    kConstBit = 0,
    kStaticBit,
    kFinalBit,
    kHasNontrivialInitializerBit,
    kUnboxingCandidateBit,
    kReflectableBit,
    kDoubleInitializedBit,
    kInitializerChangedAfterInitializatonBit,
    kHasPragmaBit,
    kCovariantBit,
    kGenericCovariantImplBit,
    kIsLateBit,
    kIsExtensionMemberBit,
    kNeedsLoadGuardBit,
    kHasInitializerBit,
    kIsNonNullableIntBit,
  };
  class ConstBit : public BitField<uint16_t, bool, kConstBit, 1> {};
  class StaticBit : public BitField<uint16_t, bool, kStaticBit, 1> {};
  class FinalBit : public BitField<uint16_t, bool, kFinalBit, 1> {};
  class HasNontrivialInitializerBit
      : public BitField<uint16_t, bool, kHasNontrivialInitializerBit, 1> {};
  class UnboxingCandidateBit
      : public BitField<uint16_t, bool, kUnboxingCandidateBit, 1> {};
  class ReflectableBit : public BitField<uint16_t, bool, kReflectableBit, 1> {};
  class DoubleInitializedBit
      : public BitField<uint16_t, bool, kDoubleInitializedBit, 1> {};
  class InitializerChangedAfterInitializatonBit
      : public BitField<uint16_t,
                        bool,
                        kInitializerChangedAfterInitializatonBit,
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
  class IsNonNullableIntBit
      : public BitField<uint16_t, bool, kIsNonNullableIntBit, 1> {};

  // Update guarded cid and guarded length for this field. Returns true, if
  // deoptimization of dependent code is required.
  bool UpdateGuardedCidAndLength(const Object& value) const;

  // Update guarded exactness state for this field. Returns true, if
  // deoptimization of dependent code is required.
  // Assumes that guarded cid was already updated.
  bool UpdateGuardedExactnessState(const Object& value) const;

  // Force this field's guard to be dynamic and deoptimize dependent code.
  void ForceDynamicGuardedCidAndLength() const;

  void set_name(const String& value) const;
  void set_is_static(bool is_static) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(StaticBit::update(is_static, raw_ptr()->kind_bits_));
  }
  void set_is_final(bool is_final) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(FinalBit::update(is_final, raw_ptr()->kind_bits_));
  }
  void set_is_const(bool value) const {
    // TODO(36097): Once concurrent access is possible ensure updates are safe.
    set_kind_bits(ConstBit::update(value, raw_ptr()->kind_bits_));
  }
  void set_owner(const Object& value) const {
    raw_ptr()->set_owner(value.raw());
  }
  void set_token_pos(TokenPosition token_pos) const {
    StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
  }
  void set_end_token_pos(TokenPosition token_pos) const {
    StoreNonPointer(&raw_ptr()->end_token_pos_, token_pos);
  }
  void set_kind_bits(uint16_t value) const {
    StoreNonPointer<uint16_t, uint16_t, std::memory_order_release>(
        &raw_ptr()->kind_bits_, value);
  }

  static FieldPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Field, Object);
  friend class Class;
  friend class HeapProfiler;
  friend class FieldLayout;
  friend class FieldSerializationCluster;
  friend class FieldDeserializationCluster;
};

class Script : public Object {
 public:
  StringPtr url() const { return raw_ptr()->url(); }
  void set_url(const String& value) const;

  // The actual url which was loaded from disk, if provided by the embedder.
  StringPtr resolved_url() const { return raw_ptr()->resolved_url(); }
  bool HasSource() const;
  StringPtr Source() const;
  bool IsPartOfDartColonLibrary() const;

  void LookupSourceAndLineStarts(Zone* zone) const;
  GrowableObjectArrayPtr GenerateLineNumberArray() const;

  intptr_t line_offset() const { return raw_ptr()->line_offset_; }
  intptr_t col_offset() const { return raw_ptr()->col_offset_; }
  // Returns the max real token position for this script, or kNoSource
  // if there is no line starts information.
  TokenPosition MaxPosition() const;

  // The load time in milliseconds since epoch.
  int64_t load_timestamp() const { return raw_ptr()->load_timestamp_; }

  ArrayPtr compile_time_constants() const {
    return raw_ptr()->compile_time_constants();
  }
  void set_compile_time_constants(const Array& value) const;

  KernelProgramInfoPtr kernel_program_info() const {
    return raw_ptr()->kernel_program_info();
  }
  void set_kernel_program_info(const KernelProgramInfo& info) const;

  intptr_t kernel_script_index() const {
    return raw_ptr()->kernel_script_index_;
  }
  void set_kernel_script_index(const intptr_t kernel_script_index) const;

  TypedDataPtr kernel_string_offsets() const;

  TypedDataPtr line_starts() const;

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  ExternalTypedDataPtr constant_coverage() const;

  void set_constant_coverage(const ExternalTypedData& value) const;
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  void set_line_starts(const TypedData& value) const;

  void set_debug_positions(const Array& value) const;

  LibraryPtr FindLibrary() const;
  StringPtr GetLine(intptr_t line_number, Heap::Space space = Heap::kNew) const;
  StringPtr GetSnippet(intptr_t from_line,
                       intptr_t from_column,
                       intptr_t to_line,
                       intptr_t to_column) const;

  void SetLocationOffset(intptr_t line_offset, intptr_t col_offset) const;

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
    return RoundedAllocationSize(sizeof(ScriptLayout));
  }

  static ScriptPtr New(const String& url, const String& source);

  static ScriptPtr New(const String& url,
                       const String& resolved_url,
                       const String& source);

#if !defined(DART_PRECOMPILED_RUNTIME)
  void LoadSourceFromKernel(const uint8_t* kernel_buffer,
                            intptr_t kernel_buffer_len) const;
  bool IsLazyLookupSourceAndLineStarts() const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

 private:
#if !defined(DART_PRECOMPILED_RUNTIME)
  bool HasCachedMaxPosition() const;

  void SetLazyLookupSourceAndLineStarts(bool value) const;
  void SetHasCachedMaxPosition(bool value) const;
  void SetCachedMaxPosition(intptr_t value) const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  void set_resolved_url(const String& value) const;
  void set_source(const String& value) const;
  void set_load_timestamp(int64_t value) const;
  ArrayPtr debug_positions() const;

  static ScriptPtr New();

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
  StringPtr name() const { return raw_ptr()->name(); }
  void SetName(const String& name) const;

  StringPtr url() const { return raw_ptr()->url(); }
  StringPtr private_key() const { return raw_ptr()->private_key(); }
  bool LoadNotStarted() const {
    return raw_ptr()->load_state_ == LibraryLayout::kAllocated;
  }
  bool LoadRequested() const {
    return raw_ptr()->load_state_ == LibraryLayout::kLoadRequested;
  }
  bool LoadInProgress() const {
    return raw_ptr()->load_state_ == LibraryLayout::kLoadInProgress;
  }
  void SetLoadRequested() const;
  void SetLoadInProgress() const;
  bool Loaded() const {
    return raw_ptr()->load_state_ == LibraryLayout::kLoaded;
  }
  void SetLoaded() const;

  LoadingUnitPtr loading_unit() const { return raw_ptr()->loading_unit(); }
  void set_loading_unit(const LoadingUnit& value) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(LibraryLayout));
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
  ObjectPtr LookupReExport(const String& name,
                           ZoneGrowableArray<intptr_t>* visited = NULL) const;
  ObjectPtr LookupObjectAllowPrivate(const String& name) const;
  ObjectPtr LookupLocalOrReExportObject(const String& name) const;
  ObjectPtr LookupImportedObject(const String& name) const;
  ClassPtr LookupClass(const String& name) const;
  ClassPtr LookupClassAllowPrivate(const String& name) const;
  ClassPtr SlowLookupClassAllowMultiPartPrivate(const String& name) const;
  ClassPtr LookupLocalClass(const String& name) const;
  FieldPtr LookupFieldAllowPrivate(const String& name) const;
  FieldPtr LookupLocalField(const String& name) const;
  FunctionPtr LookupFunctionAllowPrivate(const String& name) const;
  FunctionPtr LookupLocalFunction(const String& name) const;
  LibraryPrefixPtr LookupLocalLibraryPrefix(const String& name) const;

  // Look up a Script based on a url. If 'useResolvedUri' is not provided or is
  // false, 'url' should have a 'dart:' scheme for Dart core libraries,
  // a 'package:' scheme for packages, and 'file:' scheme otherwise.
  //
  // If 'useResolvedUri' is true, 'url' should have a 'org-dartlang-sdk:' scheme
  // for Dart core libraries and a 'file:' scheme otherwise.
  ScriptPtr LookupScript(const String& url, bool useResolvedUri = false) const;
  ArrayPtr LoadedScripts() const;

  // Resolve name in the scope of this library. First check the cache
  // of already resolved names for this library. Then look in the
  // local dictionary for the unmangled name N, the getter name get:N
  // and setter name set:N.
  // If the local dictionary contains no entry for these names,
  // look in the scopes of all libraries that are imported
  // without a library prefix.
  ObjectPtr ResolveName(const String& name) const;

  void AddAnonymousClass(const Class& cls) const;

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
  // WARNING: If the isolate received an [UnwindError] this function will not
  // return and rather unwinds until the enclosing setjmp() handler.
  static bool FindPragma(Thread* T,
                         bool only_core,
                         const Object& object,
                         const String& pragma_name,
                         Object* options);

  ClassPtr toplevel_class() const { return raw_ptr()->toplevel_class(); }
  void set_toplevel_class(const Class& value) const;

  GrowableObjectArrayPtr used_scripts() const {
    return raw_ptr()->used_scripts();
  }

  // Library imports.
  ArrayPtr imports() const { return raw_ptr()->imports(); }
  ArrayPtr exports() const { return raw_ptr()->exports(); }
  void AddImport(const Namespace& ns) const;
  intptr_t num_imports() const { return raw_ptr()->num_imports_; }
  NamespacePtr ImportAt(intptr_t index) const;
  LibraryPtr ImportLibraryAt(intptr_t index) const;

  ArrayPtr dependencies() const { return raw_ptr()->dependencies(); }
  void set_dependencies(const Array& deps) const;

  void DropDependenciesAndCaches() const;

  // Resolving native methods for script loaded in the library.
  Dart_NativeEntryResolver native_entry_resolver() const {
    return LoadNonPointer<Dart_NativeEntryResolver, std::memory_order_relaxed>(
        &raw_ptr()->native_entry_resolver_);
  }
  void set_native_entry_resolver(Dart_NativeEntryResolver value) const {
    StoreNonPointer<Dart_NativeEntryResolver, Dart_NativeEntryResolver,
                    std::memory_order_relaxed>(
        &raw_ptr()->native_entry_resolver_, value);
  }
  Dart_NativeEntrySymbol native_entry_symbol_resolver() const {
    return LoadNonPointer<Dart_NativeEntrySymbol, std::memory_order_relaxed>(
        &raw_ptr()->native_entry_symbol_resolver_);
  }
  void set_native_entry_symbol_resolver(
      Dart_NativeEntrySymbol native_symbol_resolver) const {
    StoreNonPointer<Dart_NativeEntrySymbol, Dart_NativeEntrySymbol,
                    std::memory_order_relaxed>(
        &raw_ptr()->native_entry_symbol_resolver_, native_symbol_resolver);
  }

  bool is_in_fullsnapshot() const {
    return LibraryLayout::InFullSnapshotBit::decode(raw_ptr()->flags_);
  }
  void set_is_in_fullsnapshot(bool value) const {
    set_flags(
        LibraryLayout::InFullSnapshotBit::update(value, raw_ptr()->flags_));
  }

  bool is_nnbd() const {
    return LibraryLayout::NnbdBit::decode(raw_ptr()->flags_);
  }
  void set_is_nnbd(bool value) const {
    set_flags(LibraryLayout::NnbdBit::update(value, raw_ptr()->flags_));
  }

  NNBDMode nnbd_mode() const {
    return is_nnbd() ? NNBDMode::kOptedInLib : NNBDMode::kLegacyLib;
  }

  NNBDCompiledMode nnbd_compiled_mode() const {
    return static_cast<NNBDCompiledMode>(
        LibraryLayout::NnbdCompiledModeBits::decode(raw_ptr()->flags_));
  }
  void set_nnbd_compiled_mode(NNBDCompiledMode value) const {
    set_flags(LibraryLayout::NnbdCompiledModeBits::update(
        static_cast<uint8_t>(value), raw_ptr()->flags_));
  }

  StringPtr PrivateName(const String& name) const;

  intptr_t index() const { return raw_ptr()->index_; }
  void set_index(intptr_t value) const {
    ASSERT((value == -1) ||
           ((value >= 0) && (value < std::numeric_limits<classid_t>::max())));
    StoreNonPointer(&raw_ptr()->index_, value);
  }

  void Register(Thread* thread) const;
  static void RegisterLibraries(Thread* thread,
                                const GrowableObjectArray& libs);

  bool IsDebuggable() const {
    return LibraryLayout::DebuggableBit::decode(raw_ptr()->flags_);
  }
  void set_debuggable(bool value) const {
    set_flags(LibraryLayout::DebuggableBit::update(value, raw_ptr()->flags_));
  }

  bool is_dart_scheme() const {
    return LibraryLayout::DartSchemeBit::decode(raw_ptr()->flags_);
  }
  void set_is_dart_scheme(bool value) const {
    set_flags(LibraryLayout::DartSchemeBit::update(value, raw_ptr()->flags_));
  }

  // Includes 'dart:async', 'dart:typed_data', etc.
  bool IsAnyCoreLibrary() const;

  inline intptr_t UrlHash() const;

  ExternalTypedDataPtr kernel_data() const { return raw_ptr()->kernel_data(); }
  void set_kernel_data(const ExternalTypedData& data) const;

  intptr_t kernel_offset() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return raw_ptr()->kernel_offset_;
#endif
  }

  void set_kernel_offset(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    StoreNonPointer(&raw_ptr()->kernel_offset_, value);
#endif
  }

  static LibraryPtr LookupLibrary(Thread* thread, const String& url);
  static LibraryPtr GetLibrary(intptr_t index);

  static void InitCoreLibrary(Isolate* isolate);
  static void InitNativeWrappersLibrary(Isolate* isolate, bool is_kernel_file);

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
  static LibraryPtr ProfilerLibrary();
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
                   IsolateReloadContext* context) const;

  // Returns a closure of top level function 'name' in the exported namespace
  // of this library. If a top level function 'name' does not exist we look
  // for a top level getter 'name' that returns a closure.
  ObjectPtr GetFunctionClosure(const String& name) const;

  // Ensures that all top-level functions and variables (fields) are loaded.
  void EnsureTopLevelClassIsFinalized() const;

 private:
  static const int kInitialImportsCapacity = 4;
  static const int kImportsCapacityIncrement = 8;

  static LibraryPtr New();

  // These methods are only used by the Precompiler to obfuscate
  // the name and url.
  void set_name(const String& name) const;
  void set_url(const String& url) const;

  void set_num_imports(intptr_t value) const;
  void set_flags(uint8_t flags) const;
  bool HasExports() const;
  ArrayPtr loaded_scripts() const { return raw_ptr()->loaded_scripts(); }
  ArrayPtr metadata() const {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
    return raw_ptr()->metadata();
  }
  void set_metadata(const Array& value) const;
  ArrayPtr dictionary() const { return raw_ptr()->dictionary(); }
  void InitClassDictionary() const;

  ArrayPtr resolved_names() const { return raw_ptr()->resolved_names(); }
  bool LookupResolvedNamesCache(const String& name, Object* obj) const;
  void AddToResolvedNamesCache(const String& name, const Object& obj) const;
  void InitResolvedNamesCache() const;
  void ClearResolvedNamesCache() const;
  void InvalidateResolvedName(const String& name) const;
  void InvalidateResolvedNamesCache() const;

  ArrayPtr exported_names() const { return raw_ptr()->exported_names(); }
  bool LookupExportedNamesCache(const String& name, Object* obj) const;
  void AddToExportedNamesCache(const String& name, const Object& obj) const;
  void InitExportedNamesCache() const;
  void ClearExportedNamesCache() const;
  static void InvalidateExportedNamesCaches();

  void InitImportList() const;
  void RehashDictionary(const Array& old_dict, intptr_t new_dict_size) const;
  static LibraryPtr NewLibraryHelper(const String& url, bool import_core_lib);
  ObjectPtr LookupEntry(const String& name, intptr_t* index) const;
  ObjectPtr LookupLocalObjectAllowPrivate(const String& name) const;
  ObjectPtr LookupLocalObject(const String& name) const;

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
  LibraryPtr target() const { return raw_ptr()->target(); }
  ArrayPtr show_names() const { return raw_ptr()->show_names(); }
  ArrayPtr hide_names() const { return raw_ptr()->hide_names(); }
  LibraryPtr owner() const { return raw_ptr()->owner(); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(NamespaceLayout));
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
  static KernelProgramInfoPtr New(const TypedData& string_offsets,
                                  const ExternalTypedData& string_data,
                                  const TypedData& canonical_names,
                                  const ExternalTypedData& metadata_payload,
                                  const ExternalTypedData& metadata_mappings,
                                  const ExternalTypedData& constants_table,
                                  const Array& scripts,
                                  const Array& libraries_cache,
                                  const Array& classes_cache,
                                  const Object& retained_kernel_blob,
                                  const uint32_t binary_version);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(KernelProgramInfoLayout));
  }

  TypedDataPtr string_offsets() const { return raw_ptr()->string_offsets(); }

  ExternalTypedDataPtr string_data() const { return raw_ptr()->string_data(); }

  TypedDataPtr canonical_names() const { return raw_ptr()->canonical_names(); }

  ExternalTypedDataPtr metadata_payloads() const {
    return raw_ptr()->metadata_payloads();
  }

  ExternalTypedDataPtr metadata_mappings() const {
    return raw_ptr()->metadata_mappings();
  }

  ExternalTypedDataPtr constants_table() const {
    return raw_ptr()->constants_table();
  }

  void set_constants_table(const ExternalTypedData& value) const;

  ArrayPtr scripts() const { return raw_ptr()->scripts(); }
  void set_scripts(const Array& scripts) const;

  ArrayPtr constants() const { return raw_ptr()->constants(); }
  void set_constants(const Array& constants) const;

  uint32_t kernel_binary_version() const {
    return raw_ptr()->kernel_binary_version_;
  }
  void set_kernel_binary_version(uint32_t version) const;

  // If we load a kernel blob with evaluated constants, then we delay setting
  // the native names of [Function] objects until we've read the constant table
  // (since native names are encoded as constants).
  //
  // This array will hold the functions which might need their native name set.
  GrowableObjectArrayPtr potential_natives() const {
    return raw_ptr()->potential_natives();
  }
  void set_potential_natives(const GrowableObjectArray& candidates) const;

  GrowableObjectArrayPtr potential_pragma_functions() const {
    return raw_ptr()->potential_pragma_functions();
  }
  void set_potential_pragma_functions(
      const GrowableObjectArray& candidates) const;

  ScriptPtr ScriptAt(intptr_t index) const;

  ArrayPtr libraries_cache() const { return raw_ptr()->libraries_cache(); }
  void set_libraries_cache(const Array& cache) const;
  LibraryPtr LookupLibrary(Thread* thread, const Smi& name_index) const;
  LibraryPtr InsertLibrary(Thread* thread,
                           const Smi& name_index,
                           const Library& lib) const;

  ArrayPtr classes_cache() const { return raw_ptr()->classes_cache(); }
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
  using TypeBits = compiler::ObjectPoolBuilderEntry::TypeBits;
  using PatchableBit = compiler::ObjectPoolBuilderEntry::PatchableBit;

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

  intptr_t Length() const { return raw_ptr()->length_; }
  void SetLength(intptr_t value) const {
    StoreNonPointer(&raw_ptr()->length_, value);
  }

  static intptr_t length_offset() {
    return OFFSET_OF(ObjectPoolLayout, length_);
  }
  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(ObjectPoolLayout, data);
  }
  static intptr_t element_offset(intptr_t index) {
    return OFFSET_OF_RETURNED_VALUE(ObjectPoolLayout, data) +
           sizeof(ObjectPoolLayout::Entry) * index;
  }

  struct ArrayTraits {
    static intptr_t elements_start_offset() {
      return ObjectPool::data_offset();
    }

    static constexpr intptr_t kElementSize = sizeof(ObjectPoolLayout::Entry);
  };

  EntryType TypeAt(intptr_t index) const {
    ASSERT((index >= 0) && (index <= Length()));
    return TypeBits::decode(raw_ptr()->entry_bits()[index]);
  }

  Patchability PatchableAt(intptr_t index) const {
    ASSERT((index >= 0) && (index <= Length()));
    return PatchableBit::decode(raw_ptr()->entry_bits()[index]);
  }

  void SetTypeAt(intptr_t index, EntryType type, Patchability patchable) const {
    ASSERT(index >= 0 && index <= Length());
    const uint8_t bits =
        PatchableBit::encode(patchable) | TypeBits::encode(type);
    StoreNonPointer(&raw_ptr()->entry_bits()[index], bits);
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
    StorePointer<ObjectPtr, order>(&EntryAddr(index)->raw_obj_, obj.raw());
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
    ASSERT(sizeof(ObjectPoolLayout) ==
           OFFSET_OF_RETURNED_VALUE(ObjectPoolLayout, data));
    return 0;
  }

  static const intptr_t kBytesPerElement =
      sizeof(ObjectPoolLayout::Entry) + sizeof(uint8_t);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize(intptr_t len) {
    // Ensure that variable length data is not adding to the object length.
    ASSERT(sizeof(ObjectPoolLayout) ==
           (sizeof(ObjectLayout) + (1 * kWordSize)));
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(ObjectPoolLayout) +
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
  ObjectPoolLayout::Entry const* EntryAddr(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return &raw_ptr()->data()[index];
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ObjectPool, Object);
  friend class Class;
  friend class Object;
  friend class ObjectPoolLayout;
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
  intptr_t Size() const { return SizeBits::decode(raw_ptr()->size_and_flags_); }
  static intptr_t Size(const InstructionsPtr instr) {
    return SizeBits::decode(instr->ptr()->size_and_flags_);
  }

  bool HasMonomorphicEntry() const {
    return FlagsBits::decode(raw_ptr()->size_and_flags_);
  }
  static bool HasMonomorphicEntry(const InstructionsPtr instr) {
    return FlagsBits::decode(instr->ptr()->size_and_flags_);
  }

  uword PayloadStart() const { return PayloadStart(raw()); }
  uword MonomorphicEntryPoint() const { return MonomorphicEntryPoint(raw()); }
  uword EntryPoint() const { return EntryPoint(raw()); }
  static uword PayloadStart(const InstructionsPtr instr) {
    return reinterpret_cast<uword>(instr->ptr()) + HeaderSize();
  }

// Note: We keep the checked entrypoint offsets even (emitting NOPs if
// necessary) to allow them to be seen as Smis by the GC.
#if defined(TARGET_ARCH_IA32)
  static const intptr_t kMonomorphicEntryOffsetJIT = 6;
  static const intptr_t kPolymorphicEntryOffsetJIT = 34;
  static const intptr_t kMonomorphicEntryOffsetAOT = 0;
  static const intptr_t kPolymorphicEntryOffsetAOT = 0;
#elif defined(TARGET_ARCH_X64)
  static const intptr_t kMonomorphicEntryOffsetJIT = 8;
  static const intptr_t kPolymorphicEntryOffsetJIT = 40;
  static const intptr_t kMonomorphicEntryOffsetAOT = 8;
  static const intptr_t kPolymorphicEntryOffsetAOT = 22;
#elif defined(TARGET_ARCH_ARM)
  static const intptr_t kMonomorphicEntryOffsetJIT = 0;
  static const intptr_t kPolymorphicEntryOffsetJIT = 40;
  static const intptr_t kMonomorphicEntryOffsetAOT = 0;
  static const intptr_t kPolymorphicEntryOffsetAOT = 12;
#elif defined(TARGET_ARCH_ARM64)
  static const intptr_t kMonomorphicEntryOffsetJIT = 8;
  static const intptr_t kPolymorphicEntryOffsetJIT = 48;
  static const intptr_t kMonomorphicEntryOffsetAOT = 8;
  static const intptr_t kPolymorphicEntryOffsetAOT = 20;
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

  static const intptr_t kMaxElements =
      (kMaxInt32 - (sizeof(InstructionsLayout) + sizeof(ObjectLayout) +
                    (2 * kMaxObjectAlignment)));

  // Currently, we align bare instruction payloads on 4 byte boundaries.
  //
  // If we later decide to align on larger boundaries to put entries at the
  // start of cache lines, make sure to account for entry points that are
  // _not_ at the start of the payload.
  static const intptr_t kBarePayloadAlignment = 4;

  // In non-bare mode, we align the payloads on word boundaries.
  static const intptr_t kNonBarePayloadAlignment = kWordSize;

  // In the precompiled runtime when running in bare instructions mode,
  // Instructions objects don't exist, just their bare payloads, so we
  // mark them as unreachable in that case.

  static intptr_t HeaderSize() {
#if defined(DART_PRECOMPILED_RUNTIME)
    if (FLAG_use_bare_instructions) {
      UNREACHABLE();
    }
#endif
    return Utils::RoundUp(sizeof(InstructionsLayout), kNonBarePayloadAlignment);
  }

  static intptr_t InstanceSize() {
    ASSERT_EQUAL(sizeof(InstructionsLayout),
                 OFFSET_OF_RETURNED_VALUE(InstructionsLayout, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t size) {
#if defined(DART_PRECOMPILED_RUNTIME)
    if (FLAG_use_bare_instructions) {
      UNREACHABLE();
    }
#endif
    return RoundedAllocationSize(HeaderSize() + size);
  }

  static InstructionsPtr FromPayloadStart(uword payload_start) {
#if defined(DART_PRECOMPILED_RUNTIME)
    if (FLAG_use_bare_instructions) {
      UNREACHABLE();
    }
#endif
    return static_cast<InstructionsPtr>(payload_start - HeaderSize() +
                                        kHeapObjectTag);
  }

  bool Equals(const Instructions& other) const {
    return Equals(raw(), other.raw());
  }

  static bool Equals(InstructionsPtr a, InstructionsPtr b) {
    if (Size(a) != Size(b)) return false;
    NoSafepointScope no_safepoint;
    return memcmp(a->ptr(), b->ptr(), InstanceSize(Size(a))) == 0;
  }

  uint32_t Hash() const {
    return HashBytes(reinterpret_cast<const uint8_t*>(PayloadStart()), Size());
  }

  CodeStatistics* stats() const;
  void set_stats(CodeStatistics* stats) const;

 private:
  void SetSize(intptr_t value) const {
    ASSERT(value >= 0);
    StoreNonPointer(&raw_ptr()->size_and_flags_,
                    SizeBits::update(value, raw_ptr()->size_and_flags_));
  }

  void SetHasMonomorphicEntry(bool value) const {
    StoreNonPointer(&raw_ptr()->size_and_flags_,
                    FlagsBits::update(value, raw_ptr()->size_and_flags_));
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
    return instr->ptr()->payload_length_;
  }
  static intptr_t InstanceSize() {
    ASSERT(sizeof(InstructionsSectionLayout) ==
           OFFSET_OF_RETURNED_VALUE(InstructionsSectionLayout, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t size) {
    return Utils::RoundUp(HeaderSize() + size, kObjectAlignment);
  }

  static intptr_t HeaderSize() {
    return Utils::RoundUp(sizeof(InstructionsSectionLayout),
                          Instructions::kBarePayloadAlignment);
  }

  // There are no public instance methods for the InstructionsSection class, as
  // all access to the contents is handled by methods on the Image class.

 private:
  // Note there are no New() methods for InstructionsSection. Instead, the
  // serializer writes the InstructionsSectionLayout object manually at the
  // start of instructions Images in precompiled snapshots.

  FINAL_HEAP_OBJECT_IMPLEMENTATION(InstructionsSection, Object);
  friend class Class;
};

class LocalVarDescriptors : public Object {
 public:
  intptr_t Length() const;

  StringPtr GetName(intptr_t var_index) const;

  void SetVar(intptr_t var_index,
              const String& name,
              LocalVarDescriptorsLayout::VarInfo* info) const;

  void GetInfo(intptr_t var_index,
               LocalVarDescriptorsLayout::VarInfo* info) const;

  static const intptr_t kBytesPerElement =
      sizeof(LocalVarDescriptorsLayout::VarInfo);
  static const intptr_t kMaxElements = LocalVarDescriptorsLayout::kMaxIndex;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(LocalVarDescriptorsLayout) ==
           OFFSET_OF_RETURNED_VALUE(LocalVarDescriptorsLayout, names));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(LocalVarDescriptorsLayout) +
        (len * kWordSize)  // RawStrings for names.
        + (len * sizeof(LocalVarDescriptorsLayout::VarInfo)));
  }

  static LocalVarDescriptorsPtr New(intptr_t num_variables);

  static const char* KindToCString(LocalVarDescriptorsLayout::VarInfoKind kind);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(LocalVarDescriptors, Object);
  friend class Class;
  friend class Object;
};

class PcDescriptors : public Object {
 public:
  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = kMaxInt32 / kBytesPerElement;

  static intptr_t HeaderSize() { return sizeof(PcDescriptorsLayout); }
  static intptr_t UnroundedSize(PcDescriptorsPtr desc) {
    return UnroundedSize(desc->ptr()->length_);
  }
  static intptr_t UnroundedSize(intptr_t len) { return HeaderSize() + len; }
  static intptr_t InstanceSize() {
    ASSERT_EQUAL(sizeof(PcDescriptorsLayout),
                 OFFSET_OF_RETURNED_VALUE(PcDescriptorsLayout, data));
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
  // Note: never return a reference to a PcDescriptorsLayout::PcDescriptorRec
  // as the object can move.
  class Iterator : ValueObject {
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
          cur_yield_index_(PcDescriptorsLayout::kInvalidYieldIndex) {}

    bool MoveNext() {
      NoSafepointScope scope;
      ReadStream stream(descriptors_.raw_ptr()->data(), descriptors_.Length(),
                        byte_index_);
      // Moves to record that matches kind_mask_.
      while (byte_index_ < descriptors_.Length()) {
        const int32_t kind_and_metadata = stream.ReadSLEB128<int32_t>();
        cur_kind_ =
            PcDescriptorsLayout::KindAndMetadata::DecodeKind(kind_and_metadata);
        cur_try_index_ = PcDescriptorsLayout::KindAndMetadata::DecodeTryIndex(
            kind_and_metadata);
        cur_yield_index_ =
            PcDescriptorsLayout::KindAndMetadata::DecodeYieldIndex(
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
    PcDescriptorsLayout::Kind Kind() const {
      return static_cast<PcDescriptorsLayout::Kind>(cur_kind_);
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
    return memcmp(raw_ptr(), other.raw_ptr(), InstanceSize(Length())) == 0;
  }

 private:
  static const char* KindAsStr(PcDescriptorsLayout::Kind kind);

  static PcDescriptorsPtr New(intptr_t length);

  void SetLength(intptr_t value) const;
  void CopyData(const void* bytes, intptr_t size);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(PcDescriptors, Object);
  friend class Class;
  friend class Object;
};

class CodeSourceMap : public Object {
 public:
  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = kMaxInt32 / kBytesPerElement;

  static intptr_t HeaderSize() { return sizeof(CodeSourceMapLayout); }
  static intptr_t UnroundedSize(CodeSourceMapPtr map) {
    return UnroundedSize(map->ptr()->length_);
  }
  static intptr_t UnroundedSize(intptr_t len) { return HeaderSize() + len; }
  static intptr_t InstanceSize() {
    ASSERT_EQUAL(sizeof(CodeSourceMapLayout),
                 OFFSET_OF_RETURNED_VALUE(CodeSourceMapLayout, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(UnroundedSize(len));
  }

  static CodeSourceMapPtr New(intptr_t length);

  intptr_t Length() const { return raw_ptr()->length_; }
  uint8_t* Data() const {
    return UnsafeMutableNonPointer(&raw_ptr()->data()[0]);
  }

  bool Equals(const CodeSourceMap& other) const {
    if (Length() != other.Length()) {
      return false;
    }
    NoSafepointScope no_safepoint;
    return memcmp(raw_ptr(), other.raw_ptr(), InstanceSize(Length())) == 0;
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
  static const intptr_t kHashBits = 30;

  uintptr_t payload_size() const { return PayloadSizeOf(raw()); }
  static uintptr_t PayloadSizeOf(const CompressedStackMapsPtr raw) {
    return CompressedStackMapsLayout::SizeField::decode(
        raw->ptr()->flags_and_size_);
  }

  bool Equals(const CompressedStackMaps& other) const {
    // All of the table flags and payload size must match.
    if (raw_ptr()->flags_and_size_ != other.raw_ptr()->flags_and_size_) {
      return false;
    }
    NoSafepointScope no_safepoint;
    return memcmp(raw_ptr(), other.raw_ptr(), InstanceSize(payload_size())) ==
           0;
  }

  // Methods to allow use with PointerKeyValueTrait to create sets of CSMs.
  bool Equals(const CompressedStackMaps* other) const { return Equals(*other); }
  intptr_t Hashcode() const;

  static intptr_t HeaderSize() { return sizeof(CompressedStackMapsLayout); }
  static intptr_t UnroundedSize(CompressedStackMapsPtr maps) {
    return UnroundedSize(CompressedStackMaps::PayloadSizeOf(maps));
  }
  static intptr_t UnroundedSize(intptr_t length) {
    return HeaderSize() + length;
  }
  static intptr_t InstanceSize() {
    ASSERT_EQUAL(sizeof(CompressedStackMapsLayout),
                 OFFSET_OF_RETURNED_VALUE(CompressedStackMapsLayout, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t length) {
    return RoundedAllocationSize(UnroundedSize(length));
  }

  bool UsesGlobalTable() const { return UsesGlobalTable(raw()); }
  static bool UsesGlobalTable(const CompressedStackMapsPtr raw) {
    return CompressedStackMapsLayout::UsesTableBit::decode(
        raw->ptr()->flags_and_size_);
  }

  bool IsGlobalTable() const { return IsGlobalTable(raw()); }
  static bool IsGlobalTable(const CompressedStackMapsPtr raw) {
    return CompressedStackMapsLayout::GlobalTableBit::decode(
        raw->ptr()->flags_and_size_);
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

  class Iterator : public ValueObject {
   public:
    Iterator(const CompressedStackMaps& maps,
             const CompressedStackMaps& global_table);
    Iterator(Thread* thread, const CompressedStackMaps& maps);

    explicit Iterator(const CompressedStackMaps::Iterator& it);

    // Loads the next entry from [maps_], if any. If [maps_] is the null value,
    // this always returns false.
    bool MoveNext();

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
    intptr_t Length() const;
    // Returns the number of spill slot bits of the loaded entry.
    intptr_t SpillSlotBitCount() const;
    // Returns whether the stack entry represented by the offset contains
    // a tagged objecet.
    bool IsObject(intptr_t bit_offset) const;

    void WriteToBuffer(BaseTextBuffer* buffer, const char* separator) const;

   private:
    bool HasLoadedEntry() const { return next_offset_ > 0; }

    // Caches the corresponding values from the global table in the mutable
    // fields. We lazily load these as some clients only need the PC offset.
    void LazyLoadGlobalTableEntry() const;

    void EnsureFullyLoadedEntry() const {
      ASSERT(HasLoadedEntry());
      if (current_spill_slot_bit_count_ < 0) {
        LazyLoadGlobalTableEntry();
        ASSERT(current_spill_slot_bit_count_ >= 0);
      }
    }

    const CompressedStackMaps& maps_;
    const CompressedStackMaps& bits_container_;

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
  static const intptr_t kInvalidPcOffset = 0;

  intptr_t num_entries() const;

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

  static intptr_t InstanceSize() {
    ASSERT(sizeof(ExceptionHandlersLayout) ==
           OFFSET_OF_RETURNED_VALUE(ExceptionHandlersLayout, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    return RoundedAllocationSize(sizeof(ExceptionHandlersLayout) +
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
  static const intptr_t kMaxHandlers = 1024 * 1024;

  void set_handled_types_data(const Array& value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ExceptionHandlers, Object);
  friend class Class;
  friend class Object;
};

// A WeakSerializationReference (WSR) denotes a type of weak reference to a
// target object. In particular, objects that can only be reached from roots via
// WSR edges during serialization of AOT snapshots should not be serialized. Of
// course, the target object may still be serialized if there are paths to the
// object from the roots that do not go through one of these objects, in which
// case the WSR is discarded in favor of a direct reference during serialization
// to avoid runtime overhead.
//
// Note: Some objects cannot be dropped during AOT serialization, and thus
//       Wrap() may return the original object in some cases. The CanWrap()
//       function returns false if Wrap() will return the original object.
//       In particular, the null object will never be wrapped, so receiving
//       Object::null() from target() means the WSR represents a dropped target.
//
// Unfortunately a WSR is not a proxy for the original object, so if WSRs may
// appear as field contents (currently only possible for ObjectPtr fields),
// then code that accesses that field must handle the case where an WSR has
// been introduced. Before serialization, Unwrap can be used to take a
// Object reference or RawObject pointer and remove any WSR wrapping before use.
// After deserialization, any WSRs no longer contain a pointer to the target,
// but instead contain only the class ID of the original target.
//
// Current uses of WSRs:
//  * Code::owner_
class WeakSerializationReference : public Object {
 public:
  ObjectPtr target() const { return TargetOf(raw()); }
  static ObjectPtr TargetOf(const WeakSerializationReferencePtr raw) {
#if defined(DART_PRECOMPILED_RUNTIME)
    // WSRs in the precompiled runtime only contain some remaining info about
    // their old target, not a reference to the target itself..
    return Object::null();
#else
    // Outside the precompiled runtime, they should always have a target.
    ASSERT(raw->ptr()->target() != Object::null());
    return raw->ptr()->target();
#endif
  }

  classid_t TargetClassId() const { return TargetClassIdOf(raw()); }
  static classid_t TargetClassIdOf(const WeakSerializationReferencePtr raw) {
#if defined(DART_PRECOMPILED_RUNTIME)
    // No new instances of WSRs are created in the precompiled runtime, so
    // this instance came from deserialization and thus must be the empty WSR.
    return raw->ptr()->cid_;
#else
    return TargetOf(raw)->GetClassId();
#endif
  }

  static ObjectPtr Unwrap(const Object& obj) { return Unwrap(obj.raw()); }
  // Gets the underlying object from a WSR, or the original object if it is
  // not one. Notably, Unwrap(Wrap(r)) == r for all raw objects r, whether
  // CanWrap(r) or not. However, this will not hold if a serialization and
  // deserialization step is put between the two calls.
  static ObjectPtr Unwrap(ObjectPtr obj) {
    if (!obj->IsWeakSerializationReference()) return obj;
    return TargetOf(static_cast<WeakSerializationReferencePtr>(obj));
  }

  // An Unwrap that only unwraps if there's a valid target, otherwise the
  // WSR is returned. Useful for cases where we want to call Object methods
  // like ToCString() on whatever non-null object we can get.
  static ObjectPtr UnwrapIfTarget(const Object& obj) {
    return UnwrapIfTarget(obj.raw());
  }
  static ObjectPtr UnwrapIfTarget(ObjectPtr raw) {
#if defined(DART_PRECOMPILED_RUNTIME)
    // In the precompiled runtime, WSRs never have a target so we always return
    // the argument.
    return raw;
#else
    if (!raw->IsWeakSerializationReference()) return raw;
    // Otherwise, they always do.
    return TargetOf(WeakSerializationReference::RawCast(raw));
#endif
  }

  static classid_t UnwrappedClassIdOf(const Object& obj) {
    return UnwrappedClassIdOf(obj.raw());
  }
  // Gets the class ID of the underlying object from a WSR, or the class ID of
  // the object if it is not one.
  //
  // UnwrappedClassOf(Wrap(r)) == UnwrappedClassOf(r) for all raw objects r,
  // whether CanWrap(r) or not. Unlike Unwrap, this is still true even if
  // there is a serialization and deserialization step between the two calls,
  // since that information is saved in the serialized WSR.
  static classid_t UnwrappedClassIdOf(ObjectPtr obj) {
    if (!obj->IsWeakSerializationReference()) return obj->GetClassId();
    return TargetClassIdOf(WeakSerializationReference::RawCast(obj));
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(WeakSerializationReferenceLayout));
  }

#if defined(DART_PRECOMPILER)
  // Returns true if a new WSR would be created when calling Wrap.
  static bool CanWrap(const Object& object);

  // This returns ObjectPtr, not WeakSerializationReferencePtr, because
  // target.raw() is returned when CanWrap(target) is false.
  static ObjectPtr Wrap(Zone* zone, const Object& target);
#endif

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(WeakSerializationReference, Object);
  friend class Class;
};

class Code : public Object {
 public:
  // When dual mapping, this returns the executable view.
  InstructionsPtr active_instructions() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return NULL;
#else
    return raw_ptr()->active_instructions();
#endif
  }

  // When dual mapping, these return the executable view.
  InstructionsPtr instructions() const { return raw_ptr()->instructions(); }
  static InstructionsPtr InstructionsOf(const CodePtr code) {
    return code->ptr()->instructions();
  }

  static intptr_t saved_instructions_offset() {
    return OFFSET_OF(CodeLayout, instructions_);
  }

  using EntryKind = CodeEntryKind;

  static const char* EntryKindToCString(EntryKind kind);
  static bool ParseEntryKind(const char* str, EntryKind* out);

  static intptr_t entry_point_offset(EntryKind kind = EntryKind::kNormal) {
    switch (kind) {
      case EntryKind::kNormal:
        return OFFSET_OF(CodeLayout, entry_point_);
      case EntryKind::kUnchecked:
        return OFFSET_OF(CodeLayout, unchecked_entry_point_);
      case EntryKind::kMonomorphic:
        return OFFSET_OF(CodeLayout, monomorphic_entry_point_);
      case EntryKind::kMonomorphicUnchecked:
        return OFFSET_OF(CodeLayout, monomorphic_unchecked_entry_point_);
      default:
        UNREACHABLE();
    }
  }

  ObjectPoolPtr object_pool() const { return raw_ptr()->object_pool(); }
  static intptr_t object_pool_offset() {
    return OFFSET_OF(CodeLayout, object_pool_);
  }

  intptr_t pointer_offsets_length() const {
    return PtrOffBits::decode(raw_ptr()->state_bits_);
  }

  bool is_optimized() const {
    return OptimizedBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_optimized(bool value) const;
  static bool IsOptimized(CodePtr code) {
    return Code::OptimizedBit::decode(code->ptr()->state_bits_);
  }

  bool is_force_optimized() const {
    return ForceOptimizedBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_force_optimized(bool value) const;

  bool is_alive() const { return AliveBit::decode(raw_ptr()->state_bits_); }
  void set_is_alive(bool value) const;

  bool HasMonomorphicEntry() const { return HasMonomorphicEntry(raw()); }
  static bool HasMonomorphicEntry(const CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    return code->ptr()->entry_point_ != code->ptr()->monomorphic_entry_point_;
#else
    return Instructions::HasMonomorphicEntry(InstructionsOf(code));
#endif
  }

  // Returns the payload start of [instructions()].
  uword PayloadStart() const { return PayloadStartOf(raw()); }
  static uword PayloadStartOf(const CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    const uword entry_offset = HasMonomorphicEntry(code)
                                   ? Instructions::kPolymorphicEntryOffsetAOT
                                   : 0;
    return EntryPointOf(code) - entry_offset;
#else
    return Instructions::PayloadStart(InstructionsOf(code));
#endif
  }

  // Returns the entry point of [instructions()].
  uword EntryPoint() const { return EntryPointOf(raw()); }
  static uword EntryPointOf(const CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    return code->ptr()->entry_point_;
#else
    return Instructions::EntryPoint(InstructionsOf(code));
#endif
  }

  // Returns the unchecked entry point of [instructions()].
  uword UncheckedEntryPoint() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return raw_ptr()->unchecked_entry_point_;
#else
    return EntryPoint() + raw_ptr()->unchecked_offset_;
#endif
  }
  // Returns the monomorphic entry point of [instructions()].
  uword MonomorphicEntryPoint() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return raw_ptr()->monomorphic_entry_point_;
#else
    return Instructions::MonomorphicEntryPoint(instructions());
#endif
  }
  // Returns the unchecked monomorphic entry point of [instructions()].
  uword MonomorphicUncheckedEntryPoint() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return raw_ptr()->monomorphic_unchecked_entry_point_;
#else
    return MonomorphicEntryPoint() + raw_ptr()->unchecked_offset_;
#endif
  }

  // Returns the size of [instructions()].
  intptr_t Size() const { return PayloadSizeOf(raw()); }
  static intptr_t PayloadSizeOf(const CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    return code->ptr()->instructions_length_;
#else
    return Instructions::Size(InstructionsOf(code));
#endif
  }

  ObjectPoolPtr GetObjectPool() const;
  // Returns whether the given PC address is in [instructions()].
  bool ContainsInstructionAt(uword addr) const {
    return ContainsInstructionAt(raw(), addr);
  }

  // Returns whether the given PC address is in [InstructionsOf(code)].
  static bool ContainsInstructionAt(const CodePtr code, uword pc) {
    return CodeLayout::ContainsPC(code, pc);
  }

  // Returns true if there is a debugger breakpoint set in this code object.
  bool HasBreakpoint() const;

  PcDescriptorsPtr pc_descriptors() const {
    return raw_ptr()->pc_descriptors();
  }
  void set_pc_descriptors(const PcDescriptors& descriptors) const {
    ASSERT(descriptors.IsOld());
    raw_ptr()->set_pc_descriptors(descriptors.raw());
  }

  CodeSourceMapPtr code_source_map() const {
    return raw_ptr()->code_source_map();
  }

  void set_code_source_map(const CodeSourceMap& code_source_map) const {
    ASSERT(code_source_map.IsOld());
    raw_ptr()->set_code_source_map(code_source_map.raw());
  }

  // Array of DeoptInfo objects.
  ArrayPtr deopt_info_array() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return NULL;
#else
    return raw_ptr()->deopt_info_array();
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
    return raw_ptr()->compressed_stackmaps();
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
    return NULL;
#else
    return raw_ptr()->static_calls_target_table();
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

  void Disassemble(DisassemblyFormatter* formatter = NULL) const;

  class Comments : public ZoneAllocated {
   public:
    static Comments& New(intptr_t count);

    intptr_t Length() const;

    void SetPCOffsetAt(intptr_t idx, intptr_t pc_offset);
    void SetCommentAt(intptr_t idx, const String& comment);

    intptr_t PCOffsetAt(intptr_t idx) const;
    StringPtr CommentAt(intptr_t idx) const;

   private:
    explicit Comments(const Array& comments);

    // Layout of entries describing comments.
    enum {
      kPCOffsetEntry = 0,  // PC offset to a comment as a Smi.
      kCommentEntry,       // Comment text as a String.
      kNumberOfEntries
    };

    const Array& comments_;

    friend class Code;

    DISALLOW_COPY_AND_ASSIGN(Comments);
  };

  const Comments& comments() const;
  void set_comments(const Comments& comments) const;

  ObjectPtr return_address_metadata() const {
#if defined(PRODUCT)
    UNREACHABLE();
    return NULL;
#else
    return raw_ptr()->return_address_metadata();
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
    return NULL;
#else
    return raw_ptr()->var_descriptors();
#endif
  }
  void set_var_descriptors(const LocalVarDescriptors& value) const {
#if defined(PRODUCT)
    UNREACHABLE();
#else
    ASSERT(value.IsOld());
    raw_ptr()->set_var_descriptors(value.raw());
#endif
  }

  // Will compute local var descriptors if necessary.
  LocalVarDescriptorsPtr GetLocalVarDescriptors() const;

  ExceptionHandlersPtr exception_handlers() const {
    return raw_ptr()->exception_handlers();
  }
  void set_exception_handlers(const ExceptionHandlers& handlers) const {
    ASSERT(handlers.IsOld());
    raw_ptr()->set_exception_handlers(handlers.raw());
  }

  // WARNING: function() returns the owner which is not guaranteed to be
  // a Function. It is up to the caller to guarantee it isn't a stub, class,
  // or something else.
  // TODO(turnidge): Consider dropping this function and making
  // everybody use owner().  Currently this function is misused - even
  // while generating the snapshot.
  FunctionPtr function() const {
    ASSERT(IsFunctionCode());
    return Function::RawCast(
        WeakSerializationReference::Unwrap(raw_ptr()->owner()));
  }

  ObjectPtr owner() const { return raw_ptr()->owner(); }
  void set_owner(const Object& owner) const;

  classid_t OwnerClassId() const { return OwnerClassIdOf(raw()); }
  static classid_t OwnerClassIdOf(CodePtr raw) {
    return WeakSerializationReference::UnwrappedClassIdOf(raw->ptr()->owner());
  }

  static intptr_t owner_offset() { return OFFSET_OF(CodeLayout, owner_); }

  // We would have a VisitPointers function here to traverse all the
  // embedded objects in the instructions using pointer_offsets.

  static const intptr_t kBytesPerElement =
      sizeof(reinterpret_cast<CodeLayout*>(0)->data()[0]);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(CodeLayout) == OFFSET_OF_RETURNED_VALUE(CodeLayout, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(CodeLayout) + (len * kBytesPerElement));
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
  static CodePtr LookupCode(uword pc);
  static CodePtr LookupCodeInVmIsolate(uword pc);
  static CodePtr FindCode(uword pc, int64_t timestamp);

  int32_t GetPointerOffsetAt(int index) const {
    NoSafepointScope no_safepoint;
    return *PointerOffsetAddrAt(index);
  }
  TokenPosition GetTokenIndexOfPC(uword pc) const;

  // Find pc, return 0 if not found.
  uword GetPcForDeoptId(intptr_t deopt_id,
                        PcDescriptorsLayout::Kind kind) const;
  intptr_t GetDeoptIdForOsr(uword pc) const;

  const char* Name() const;
  const char* QualifiedName(const NameFormattingParams& params) const;

  int64_t compile_timestamp() const {
#if defined(PRODUCT)
    return 0;
#else
    return raw_ptr()->compile_timestamp_;
#endif
  }

  bool IsStubCode() const;
  bool IsAllocationStubCode() const;
  bool IsTypeTestStubCode() const;
  bool IsFunctionCode() const;

  void DisableDartCode() const;

  void DisableStubCode() const;

  void Enable() const {
    if (!IsDisabled()) return;
    ASSERT(Thread::Current()->IsMutatorThread());
    ResetActiveInstructions();
  }

  bool IsDisabled() const { return IsDisabled(raw()); }
  static bool IsDisabled(CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return false;
#else
    return code->ptr()->instructions() != code->ptr()->active_instructions();
#endif
  }

  void set_object_pool(ObjectPoolPtr object_pool) const {
    raw_ptr()->set_object_pool(object_pool);
  }

 private:
  void set_state_bits(intptr_t bits) const;

  friend class ObjectLayout;  // For ObjectLayout::SizeFromClass().
  friend class CodeLayout;
  enum {
    kOptimizedBit = 0,
    kForceOptimizedBit = 1,
    kAliveBit = 2,
    kPtrOffBit = 3,
    kPtrOffSize = 29,
  };

  class OptimizedBit : public BitField<int32_t, bool, kOptimizedBit, 1> {};

  // Force-optimized is true if the Code was generated for a function with
  // Function::ForceOptimize().
  class ForceOptimizedBit
      : public BitField<int32_t, bool, kForceOptimizedBit, 1> {};

  class AliveBit : public BitField<int32_t, bool, kAliveBit, 1> {};
  class PtrOffBits
      : public BitField<int32_t, intptr_t, kPtrOffBit, kPtrOffSize> {};

  class SlowFindRawCodeVisitor : public FindObjectVisitor {
   public:
    explicit SlowFindRawCodeVisitor(uword pc) : pc_(pc) {}
    virtual ~SlowFindRawCodeVisitor() {}

    // Check if object matches find condition.
    virtual bool FindObject(ObjectPtr obj) const;

   private:
    const uword pc_;

    DISALLOW_COPY_AND_ASSIGN(SlowFindRawCodeVisitor);
  };

  static const intptr_t kEntrySize = sizeof(int32_t);  // NOLINT

  void set_compile_timestamp(int64_t timestamp) const {
#if defined(PRODUCT)
    UNREACHABLE();
#else
    StoreNonPointer(&raw_ptr()->compile_timestamp_, timestamp);
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

  // Resets [active_instructions_] to its original value of [instructions_] and
  // updates the cached entry point addresses to match.
  void ResetActiveInstructions() const;

  void set_instructions(const Instructions& instructions) const {
    ASSERT(Thread::Current()->IsMutatorThread() || !is_alive());
    raw_ptr()->set_instructions(instructions.raw());
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  void set_unchecked_offset(uword offset) const {
    StoreNonPointer(&raw_ptr()->unchecked_offset_, offset);
  }
#endif

  // Returns the unchecked entry point offset for [instructions_].
  uint32_t UncheckedEntryPointOffset() const {
    return UncheckedEntryPointOffsetOf(raw());
  }
  static uint32_t UncheckedEntryPointOffsetOf(CodePtr code) {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    return code->ptr()->unchecked_offset_;
#endif
  }

  void set_pointer_offsets_length(intptr_t value) {
    // The number of fixups is limited to 1-billion.
    ASSERT(Utils::IsUint(30, value));
    set_state_bits(PtrOffBits::update(value, raw_ptr()->state_bits_));
  }
  int32_t* PointerOffsetAddrAt(int index) const {
    ASSERT(index >= 0);
    ASSERT(index < pointer_offsets_length());
    // TODO(iposva): Unit test is missing for this functionality.
    return &UnsafeMutableNonPointer(raw_ptr()->data())[index];
  }
  void SetPointerOffsetAt(int index, int32_t offset_in_instructions) {
    NoSafepointScope no_safepoint;
    *PointerOffsetAddrAt(index) = offset_in_instructions;
  }

  intptr_t BinarySearchInSCallTable(uword pc) const;
  static CodePtr LookupCodeInIsolate(Isolate* isolate, uword pc);

  // New is a private method as RawInstruction and RawCode objects should
  // only be created using the Code::FinalizeCode method. This method creates
  // the RawInstruction and RawCode objects, sets up the pointer offsets
  // and links the two in a GC safe manner.
  static CodePtr New(intptr_t pointer_offsets_length);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Code, Object);
  friend class Class;
  friend class CodeTestHelper;
  friend class SnapshotWriter;
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
  // So that the FunctionLayout pointer visitor can determine whether code the
  // function points to is optimized.
  friend class FunctionLayout;
  friend class CallSiteResetter;
  friend class CodeKeyValueTrait;  // for UncheckedEntryPointOffset
};

class Context : public Object {
 public:
  ContextPtr parent() const { return raw_ptr()->parent(); }
  void set_parent(const Context& parent) const {
    raw_ptr()->set_parent(parent.raw());
  }
  static intptr_t parent_offset() { return OFFSET_OF(ContextLayout, parent_); }

  intptr_t num_variables() const { return raw_ptr()->num_variables_; }
  static intptr_t num_variables_offset() {
    return OFFSET_OF(ContextLayout, num_variables_);
  }
  static intptr_t NumVariables(const ContextPtr context) {
    return context->ptr()->num_variables_;
  }

  ObjectPtr At(intptr_t context_index) const {
    return raw_ptr()->element(context_index);
  }
  inline void SetAt(intptr_t context_index, const Object& value) const;

  intptr_t GetLevel() const;

  void Dump(int indent = 0) const;

  static const intptr_t kBytesPerElement = kWordSize;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static const intptr_t kAwaitJumpVarIndex = 0;
  static const intptr_t kAsyncFutureIndex = 1;
  static const intptr_t kControllerIndex = 1;
  // Expected context index of chained futures in recognized async functions.
  // These are used to unwind async stacks.
  static const intptr_t kFutureTimeoutFutureIndex = 2;
  static const intptr_t kFutureWaitFutureIndex = 2;
  static const intptr_t kIsSyncIndex = 2;

  static intptr_t variable_offset(intptr_t context_index) {
    return OFFSET_OF_RETURNED_VALUE(ContextLayout, data) +
           (kWordSize * context_index);
  }

  static bool IsValidLength(intptr_t len) {
    return 0 <= len && len <= compiler::target::Array::kMaxElements;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(ContextLayout) ==
           OFFSET_OF_RETURNED_VALUE(ContextLayout, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(IsValidLength(len));
    return RoundedAllocationSize(sizeof(ContextLayout) +
                                 (len * kBytesPerElement));
  }

  static ContextPtr New(intptr_t num_variables, Heap::Space space = Heap::kNew);

 private:
  void set_num_variables(intptr_t num_variables) const {
    StoreNonPointer(&raw_ptr()->num_variables_, num_variables);
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
  intptr_t num_variables() const { return raw_ptr()->num_variables_; }

  TokenPosition TokenIndexAt(intptr_t scope_index) const;
  void SetTokenIndexAt(intptr_t scope_index, TokenPosition token_pos) const;

  TokenPosition DeclarationTokenIndexAt(intptr_t scope_index) const;
  void SetDeclarationTokenIndexAt(intptr_t scope_index,
                                  TokenPosition declaration_token_pos) const;

  StringPtr NameAt(intptr_t scope_index) const;
  void SetNameAt(intptr_t scope_index, const String& name) const;

  void ClearFlagsAt(intptr_t scope_index) const;

  bool IsFinalAt(intptr_t scope_index) const;
  void SetIsFinalAt(intptr_t scope_index, bool is_final) const;

  bool IsLateAt(intptr_t scope_index) const;
  void SetIsLateAt(intptr_t scope_index, bool is_late) const;

  intptr_t LateInitOffsetAt(intptr_t scope_index) const;
  void SetLateInitOffsetAt(intptr_t scope_index,
                           intptr_t late_init_offset) const;

  bool IsConstAt(intptr_t scope_index) const;
  void SetIsConstAt(intptr_t scope_index, bool is_const) const;

  AbstractTypePtr TypeAt(intptr_t scope_index) const;
  void SetTypeAt(intptr_t scope_index, const AbstractType& type) const;

  InstancePtr ConstValueAt(intptr_t scope_index) const;
  void SetConstValueAt(intptr_t scope_index, const Instance& value) const;

  intptr_t ContextIndexAt(intptr_t scope_index) const;
  void SetContextIndexAt(intptr_t scope_index, intptr_t context_index) const;

  intptr_t ContextLevelAt(intptr_t scope_index) const;
  void SetContextLevelAt(intptr_t scope_index, intptr_t context_level) const;

  static const intptr_t kBytesPerElement =
      sizeof(ContextScopeLayout::VariableDesc);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(ContextScopeLayout) ==
           OFFSET_OF_RETURNED_VALUE(ContextScopeLayout, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(ContextScopeLayout) +
                                 (len * kBytesPerElement));
  }

  static ContextScopePtr New(intptr_t num_variables, bool is_implicit);

 private:
  void set_num_variables(intptr_t num_variables) const {
    StoreNonPointer(&raw_ptr()->num_variables_, num_variables);
  }

  void set_is_implicit(bool is_implicit) const {
    StoreNonPointer(&raw_ptr()->is_implicit_, is_implicit);
  }

  const ContextScopeLayout::VariableDesc* VariableDescAddr(
      intptr_t index) const {
    ASSERT((index >= 0) && (index < num_variables()));
    return raw_ptr()->VariableDescAddr(index);
  }

  bool GetFlagAt(intptr_t scope_index, intptr_t mask) const;
  void SetFlagAt(intptr_t scope_index, intptr_t mask, bool value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ContextScope, Object);
  friend class Class;
  friend class Object;
};

class MegamorphicCache : public CallSiteData {
 public:
  static const intptr_t kInitialCapacity = 16;
  static const intptr_t kSpreadFactor = 7;
  static const double kLoadFactor;

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
    return OFFSET_OF(MegamorphicCacheLayout, buckets_);
  }
  static intptr_t mask_offset() {
    return OFFSET_OF(MegamorphicCacheLayout, mask_);
  }
  static intptr_t arguments_descriptor_offset() {
    return OFFSET_OF(MegamorphicCacheLayout, args_descriptor_);
  }

  static MegamorphicCachePtr New(const String& target_name,
                                 const Array& arguments_descriptor);

  void EnsureContains(const Smi& class_id, const Object& target) const;
  ObjectPtr Lookup(const Smi& class_id) const;

  void SwitchToBareInstructions();

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(MegamorphicCacheLayout));
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
  enum Entries {
    kTestResult = 0,
    kInstanceClassIdOrFunction = 1,
    kDestinationType = 2,
    kInstanceTypeArguments = 3,
    kInstantiatorTypeArguments = 4,
    kFunctionTypeArguments = 5,
    kInstanceParentFunctionTypeArguments = 6,
    kInstanceDelayedFunctionTypeArguments = 7,
    kTestEntryLength = 8,
  };

  virtual intptr_t NumberOfChecks() const;
  void AddCheck(const Object& instance_class_id_or_function,
                const AbstractType& destination_type,
                const TypeArguments& instance_type_arguments,
                const TypeArguments& instantiator_type_arguments,
                const TypeArguments& function_type_arguments,
                const TypeArguments& instance_parent_function_type_arguments,
                const TypeArguments& instance_delayed_type_arguments,
                const Bool& test_result) const;
  void GetCheck(intptr_t ix,
                Object* instance_class_id_or_function,
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
                       Object* instance_class_id_or_function,
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
  bool HasCheck(const Object& instance_class_id_or_function,
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

  // Like WriteEntryToBuffer(), but does not require the subtype test cache
  // mutex and so may see an outdated view of the cache.
  void WriteCurrentEntryToBuffer(Zone* zone,
                                 BaseTextBuffer* buffer,
                                 intptr_t index,
                                 const char* line_prefix = nullptr) const;
  void Reset() const;

  static SubtypeTestCachePtr New();

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(SubtypeTestCacheLayout));
  }

  static intptr_t cache_offset() {
    return OFFSET_OF(SubtypeTestCacheLayout, cache_);
  }

  static void Init();
  static void Cleanup();

  ArrayPtr cache() const;

 private:
  void set_cache(const Array& value) const;

  // A VM heap allocated preinitialized empty subtype entry array.
  static ArrayPtr cached_array_;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(SubtypeTestCache, Object);
  friend class Class;
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
    return RoundedAllocationSize(sizeof(LoadingUnitLayout));
  }

  LoadingUnitPtr parent() const;
  void set_parent(const LoadingUnit& value) const;

  ArrayPtr base_objects() const;
  void set_base_objects(const Array& value) const;

  intptr_t id() const { return raw_ptr()->id_; }
  void set_id(intptr_t id) const { StoreNonPointer(&raw_ptr()->id_, id); }

  // True once the VM deserializes this unit's snapshot.
  bool loaded() const { return raw_ptr()->loaded_; }
  void set_loaded(bool value) const {
    StoreNonPointer(&raw_ptr()->loaded_, value);
  }

  // True once the VM invokes the embedder's deferred load callback until the
  // embedder calls Dart_DeferredLoadComplete[Error].
  bool load_outstanding() const { return raw_ptr()->load_outstanding_; }
  void set_load_outstanding(bool value) const {
    StoreNonPointer(&raw_ptr()->load_outstanding_, value);
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
  StringPtr message() const { return raw_ptr()->message(); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(ApiErrorLayout));
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
    return static_cast<Report::Kind>(raw_ptr()->kind_);
  }

  // Build, cache, and return formatted message.
  StringPtr FormatMessage() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(LanguageErrorLayout));
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

  TokenPosition token_pos() const { return raw_ptr()->token_pos_; }

 private:
  ErrorPtr previous_error() const { return raw_ptr()->previous_error(); }
  void set_previous_error(const Error& value) const;

  ScriptPtr script() const { return raw_ptr()->script(); }
  void set_script(const Script& value) const;

  void set_token_pos(TokenPosition value) const;

  bool report_after_token() const { return raw_ptr()->report_after_token_; }
  void set_report_after_token(bool value);

  void set_kind(uint8_t value) const;

  StringPtr message() const { return raw_ptr()->message(); }
  void set_message(const String& value) const;

  StringPtr formatted_message() const { return raw_ptr()->formatted_message(); }
  void set_formatted_message(const String& value) const;

  static LanguageErrorPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(LanguageError, Error);
  friend class Class;
};

class UnhandledException : public Error {
 public:
  InstancePtr exception() const { return raw_ptr()->exception(); }
  static intptr_t exception_offset() {
    return OFFSET_OF(UnhandledExceptionLayout, exception_);
  }

  InstancePtr stacktrace() const { return raw_ptr()->stacktrace(); }
  static intptr_t stacktrace_offset() {
    return OFFSET_OF(UnhandledExceptionLayout, stacktrace_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UnhandledExceptionLayout));
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
  bool is_user_initiated() const { return raw_ptr()->is_user_initiated_; }
  void set_is_user_initiated(bool value) const;

  StringPtr message() const { return raw_ptr()->message(); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UnwindErrorLayout));
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
    return (clazz()->ptr()->host_instance_size_in_words_ * kWordSize);
  }

  InstancePtr Canonicalize(Thread* thread) const;
  // Caller must hold Isolate::constant_canonicalization_mutex_.
  virtual InstancePtr CanonicalizeLocked(Thread* thread) const;
  virtual void CanonicalizeFieldsLocked(Thread* thread) const;

  InstancePtr CopyShallowToOldSpace(Thread* thread) const;

#if defined(DEBUG)
  // Check if instance is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const;
#endif  // DEBUG

  ObjectPtr GetField(const Field& field) const;

  void SetField(const Field& field, const Object& value) const;

  AbstractTypePtr GetType(Heap::Space space) const;

  // Access the arguments of the [Type] of this [Instance].
  // Note: for [Type]s instead of [Instance]s with a [Type] attached, use
  // [arguments()] and [set_arguments()]
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
  // [other] is a type parameter in NNBD strong mode).
  static bool NullIsAssignableTo(const AbstractType& other);

  bool IsValidNativeIndex(int index) const {
    return ((index >= 0) && (index < clazz()->ptr()->num_native_fields_));
  }

  intptr_t* NativeFieldsDataAddr() const;
  inline intptr_t GetNativeField(int index) const;
  inline void GetNativeFields(uint16_t num_fields,
                              intptr_t* field_values) const;
  void SetNativeFields(uint16_t num_fields, const intptr_t* field_values) const;

  uint16_t NumNativeFields() const {
    return clazz()->ptr()->num_native_fields_;
  }

  void SetNativeField(int index, intptr_t value) const;

  // If the instance is a callable object, i.e. a closure or the instance of a
  // class implementing a 'call' method, return true and set the function
  // (if not NULL) to call.
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

  // Evaluate the given expression as if it appeared in an instance method of
  // this instance and return the resulting value, or an error object if
  // evaluating the expression fails. The method has the formal (type)
  // parameters given in (type_)param_names, and is invoked with the (type)
  // argument values given in (type_)param_values.
  ObjectPtr EvaluateCompiledExpression(
      const Class& method_cls,
      const ExternalTypedData& kernel_buffer,
      const Array& type_definitions,
      const Array& param_values,
      const TypeArguments& type_param_values) const;

  // Equivalent to invoking hashCode on this instance.
  virtual ObjectPtr HashCode() const;

  // Equivalent to invoking identityHashCode with this instance.
  ObjectPtr IdentityHashCode() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(InstanceLayout));
  }

  static InstancePtr New(const Class& cls, Heap::Space space = Heap::kNew);

  // Array/list element address computations.
  static intptr_t DataOffsetFor(intptr_t cid);
  static intptr_t ElementSizeFor(intptr_t cid);

  // Pointers may be subtyped, but their subtypes may not get extra fields.
  // The subtype runtime representation has exactly the same object layout,
  // only the class_id is different. So, it is safe to use subtype instances in
  // Pointer handles.
  virtual bool IsPointer() const;

  static intptr_t NextFieldOffset() { return sizeof(InstanceLayout); }

 protected:
#ifndef PRODUCT
  virtual void PrintSharedInstanceJSON(JSONObject* jsobj, bool ref) const;
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

  ObjectPtr* FieldAddrAtOffset(intptr_t offset) const {
    ASSERT(IsValidFieldOffset(offset));
    return reinterpret_cast<ObjectPtr*>(raw_value() - kHeapObjectTag + offset);
  }
  ObjectPtr* FieldAddr(const Field& field) const {
    return FieldAddrAtOffset(field.HostOffset());
  }
  ObjectPtr* NativeFieldsAddr() const {
    return FieldAddrAtOffset(sizeof(ObjectLayout));
  }
  void SetFieldAtOffset(intptr_t offset, const Object& value) const {
    StorePointer(FieldAddrAtOffset(offset), value.raw());
  }
  bool IsValidFieldOffset(intptr_t offset) const;

  // The following raw methods are used for morphing.
  // They are needed due to the extraction of the class in IsValidFieldOffset.
  ObjectPtr* RawFieldAddrAtOffset(intptr_t offset) const {
    return reinterpret_cast<ObjectPtr*>(raw_value() - kHeapObjectTag + offset);
  }
  ObjectPtr RawGetFieldAtOffset(intptr_t offset) const {
    return *RawFieldAddrAtOffset(offset);
  }
  void RawSetFieldAtOffset(intptr_t offset, const Object& value) const {
    StorePointer(RawFieldAddrAtOffset(offset), value.raw());
  }

  static InstancePtr NewFromCidAndSize(SharedClassTable* shared_class_table,
                                       classid_t cid,
                                       Heap::Space heap = Heap::kNew);

  // TODO(iposva): Determine if this gets in the way of Smi.
  HEAP_OBJECT_IMPLEMENTATION(Instance, Object);
  friend class ByteBuffer;
  friend class Class;
  friend class Closure;
  friend class Pointer;
  friend class DeferredObject;
  friend class RegExp;
  friend class SnapshotWriter;
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
  StringPtr name() const { return raw_ptr()->name(); }
  virtual StringPtr DictionaryName() const { return name(); }

  ArrayPtr imports() const { return raw_ptr()->imports(); }
  intptr_t num_imports() const { return raw_ptr()->num_imports_; }
  LibraryPtr importer() const { return raw_ptr()->importer(); }

  LibraryPtr GetLibrary(int index) const;
  void AddImport(const Namespace& import) const;

  bool is_deferred_load() const { return raw_ptr()->is_deferred_load_; }
  bool is_loaded() const { return raw_ptr()->is_loaded_; }
  void set_is_loaded(bool value) const {
    return StoreNonPointer(&raw_ptr()->is_loaded_, value);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(LibraryPrefixLayout));
  }

  static LibraryPrefixPtr New(const String& name,
                              const Namespace& import,
                              bool deferred_load,
                              const Library& importer);

 private:
  static const int kInitialSize = 2;
  static const int kIncrementSize = 2;

  void set_name(const String& value) const;
  void set_imports(const Array& value) const;
  void set_num_imports(intptr_t value) const;
  void set_importer(const Library& value) const;

  static LibraryPrefixPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(LibraryPrefix, Instance);
  friend class Class;
};

// A TypeArguments is an array of AbstractType.
class TypeArguments : public Instance {
 public:
  // We use 30 bits for the hash code so hashes in a snapshot taken on a
  // 64-bit architecture stay in Smi range when loaded on a 32-bit
  // architecture.
  static const intptr_t kHashBits = 30;

  // Hash value for a type argument vector consisting solely of dynamic types.
  static const intptr_t kAllDynamicHash = 1;

  // Returns whether this TypeArguments vector can be used in a context that
  // expects a vector of length [count]. Always true for the null vector.
  bool HasCount(intptr_t count) const;
  static intptr_t length_offset() {
    return OFFSET_OF(TypeArgumentsLayout, length_);
  }
  intptr_t Length() const;
  AbstractTypePtr TypeAt(intptr_t index) const;
  AbstractTypePtr TypeAtNullSafe(intptr_t index) const;
  static intptr_t types_offset() {
    return OFFSET_OF_RETURNED_VALUE(TypeArgumentsLayout, types);
  }
  static intptr_t type_at_offset(intptr_t index) {
    return types_offset() + index * kWordSize;
  }
  void SetTypeAt(intptr_t index, const AbstractType& value) const;

  struct ArrayTraits {
    static intptr_t elements_start_offset() {
      return TypeArguments::types_offset();
    }

    static constexpr intptr_t kElementSize = kWordSize;
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
  // The nullabilty is 0 if the vector is longer than kNullabilityMaxTypes.
  // The condition evaluated at runtime to decide whether UTA can share ITA is
  //   (UTA.nullability & ITA.nullability) == UTA.nullability
  // Note that this allows for ITA to be longer than UTA.
  static const intptr_t kNullabilityBitsPerType = 2;
  static const intptr_t kNullabilityMaxTypes =
      kSmiBits / kNullabilityBitsPerType;
  static const intptr_t kNonNullableBits = 0;
  static const intptr_t kNullableBits = 3;
  static const intptr_t kLegacyBits = 2;
  intptr_t nullability() const;
  static intptr_t nullability_offset() {
    return OFFSET_OF(TypeArgumentsLayout, nullability_);
  }

  // The name of this type argument vector, e.g. "<T, dynamic, List<T>, Smi>".
  StringPtr Name() const;

  // The name of this type argument vector, e.g. "<T, dynamic, List<T>, int>".
  // Names of internal classes are mapped to their public interfaces.
  StringPtr UserVisibleName() const;

  // Print the internal or public name of a subvector of this type argument
  // vector, e.g. "<T, dynamic, List<T>, int>".
  void PrintSubvectorName(
      intptr_t from_index,
      intptr_t len,
      NameVisibility name_visibility,
      BaseTextBuffer* printer,
      NameDisambiguation name_disambiguation = NameDisambiguation::kNo) const;
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

  bool IsEquivalent(const TypeArguments& other,
                    TypeEquality kind,
                    TrailPtr trail = nullptr) const {
    return IsSubvectorEquivalent(other, 0, IsNull() ? 0 : Length(), kind,
                                 trail);
  }
  bool IsSubvectorEquivalent(const TypeArguments& other,
                             intptr_t from_index,
                             intptr_t len,
                             TypeEquality kind,
                             TrailPtr trail = nullptr) const;

  // Check if the vector is instantiated (it must not be null).
  bool IsInstantiated(Genericity genericity = kAny,
                      intptr_t num_free_fun_type_params = kAllFree,
                      TrailPtr trail = nullptr) const {
    return IsSubvectorInstantiated(0, Length(), genericity,
                                   num_free_fun_type_params, trail);
  }
  bool IsSubvectorInstantiated(intptr_t from_index,
                               intptr_t len,
                               Genericity genericity = kAny,
                               intptr_t num_free_fun_type_params = kAllFree,
                               TrailPtr trail = nullptr) const;
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

  // Return true if all types of this vector are finalized.
  bool IsFinalized() const;

  // Return true if this vector contains a recursive type argument.
  bool IsRecursive() const;

  // Caller must hold Isolate::constant_canonicalization_mutex_.
  virtual InstancePtr CanonicalizeLocked(Thread* thread) const {
    return Canonicalize(thread, nullptr);
  }

  // Canonicalize only if instantiated, otherwise returns 'this'.
  TypeArgumentsPtr Canonicalize(Thread* thread, TrailPtr trail = nullptr) const;

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
      TrailPtr trail = nullptr) const;

  // Runtime instantiation with canonicalization. Not to be used during type
  // finalization at compile time.
  TypeArgumentsPtr InstantiateAndCanonicalizeFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments) const;

  // Each cached instantiation consists of a 3-tuple in the instantiations_
  // array stored in each canonical uninstantiated type argument vector.
  enum Instantiation {
    kInstantiatorTypeArgsIndex = 0,
    kFunctionTypeArgsIndex,
    kInstantiatedTypeArgsIndex,
    kSizeInWords,
  };

  // The array is terminated by the value kNoInstantiator occuring in place of
  // the instantiator type args of the 4-tuple that would otherwise follow.
  // Therefore, kNoInstantiator must be distinct from any type arguments vector,
  // even a null one. Since arrays are initialized with 0, the instantiations_
  // array is properly terminated upon initialization.
  static const intptr_t kNoInstantiator = 0;

  // Return true if this type argument vector has cached instantiations.
  bool HasInstantiations() const;

  // Return the number of cached instantiations for this type argument vector.
  intptr_t NumInstantiations() const;

  static intptr_t instantiations_offset() {
    return OFFSET_OF(TypeArgumentsLayout, instantiations_);
  }

  static const intptr_t kBytesPerElement = kWordSize;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(TypeArgumentsLayout) ==
           OFFSET_OF_RETURNED_VALUE(TypeArgumentsLayout, types));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    // Ensure that the types() is not adding to the object size, which includes
    // 4 fields: instantiations_, length_, hash_, and nullability_.
    ASSERT(sizeof(TypeArgumentsLayout) ==
           (sizeof(ObjectLayout) + (kNumFields * kWordSize)));
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(TypeArgumentsLayout) +
                                 (len * kBytesPerElement));
  }

  virtual uint32_t CanonicalizeHash() const {
    // Hash() is not stable until finalization is done.
    return 0;
  }
  intptr_t Hash() const;
  intptr_t HashForRange(intptr_t from_index, intptr_t len) const;

  static TypeArgumentsPtr New(intptr_t len, Heap::Space space = Heap::kOld);

 private:
  intptr_t ComputeNullability() const;
  void set_nullability(intptr_t value) const;

  intptr_t ComputeHash() const;
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
  static const int kNumFields = 4;

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
  // We use 30 bits for the hash code so hashes in a snapshot taken on a
  // 64-bit architecture stay in Smi range when loaded on a 32-bit
  // architecture.
  static const intptr_t kHashBits = 30;

  virtual bool IsFinalized() const;
  virtual void SetIsFinalized() const;
  virtual bool IsBeingFinalized() const;
  virtual void SetIsBeingFinalized() const;

  virtual Nullability nullability() const;
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
  virtual void set_arguments(const TypeArguments& value) const;
  virtual TokenPosition token_pos() const;
  virtual bool IsInstantiated(Genericity genericity = kAny,
                              intptr_t num_free_fun_type_params = kAllFree,
                              TrailPtr trail = nullptr) const;
  virtual bool CanonicalizeEquals(const Instance& other) const {
    return Equals(other);
  }
  virtual uint32_t CanonicalizeHash() const { return Hash(); }
  virtual bool Equals(const Instance& other) const {
    return IsEquivalent(other, TypeEquality::kCanonical);
  }
  virtual bool IsEquivalent(const Instance& other,
                            TypeEquality kind,
                            TrailPtr trail = nullptr) const;
  virtual bool IsRecursive() const;

  // Check if this type represents a function type.
  virtual bool IsFunctionType() const { return false; }

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
      TrailPtr trail = nullptr) const;

  // Caller must hold Isolate::constant_canonicalization_mutex_.
  virtual InstancePtr CanonicalizeLocked(Thread* thread) const {
    return Canonicalize(thread, nullptr);
  }

  // Return the canonical version of this type.
  virtual AbstractTypePtr Canonicalize(Thread* thread, TrailPtr trail) const;

#if defined(DEBUG)
  // Check if abstract type is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const {
    UNREACHABLE();
    return false;
  }
#endif  // DEBUG

  // Return the object associated with the receiver in the trail or
  // AbstractType::null() if the receiver is not contained in the trail.
  AbstractTypePtr OnlyBuddyInTrail(TrailPtr trail) const;

  // If the trail is null, allocate a trail, add the pair <receiver, buddy> to
  // the trail. The receiver may only be added once with its only buddy.
  void AddOnlyBuddyToTrail(TrailPtr* trail, const AbstractType& buddy) const;

  // Return true if the receiver is contained in the trail.
  // Otherwise, if the trail is null, allocate a trail, then add the receiver to
  // the trail and return false.
  bool TestAndAddToTrail(TrailPtr* trail) const;

  // Return true if the pair <receiver, buddy> is contained in the trail.
  // Otherwise, if the trail is null, allocate a trail, add the pair <receiver,
  // buddy> to the trail and return false.
  // The receiver may be added several times, each time with a different buddy.
  bool TestAndAddBuddyToTrail(TrailPtr* trail, const AbstractType& buddy) const;

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

  // Return the internal or public name of this type, including the names of its
  // type arguments, if any.
  void PrintName(
      NameVisibility visibility,
      BaseTextBuffer* printer,
      NameDisambiguation name_disambiguation = NameDisambiguation::kNo) const;

  // Add the class name and URI of each occuring type to the uris
  // list and mark ambiguous triplets to be printed.
  virtual void EnumerateURIs(URIs* uris) const;

  virtual intptr_t Hash() const;

  // The name of this type's class, i.e. without the type argument names of this
  // type.
  StringPtr ClassName() const;

  // Check if this type is a still uninitialized TypeRef.
  bool IsNullTypeRef() const;

  // Check if this type represents the 'dynamic' type.
  bool IsDynamicType() const { return type_class_id() == kDynamicCid; }

  // Check if this type represents the 'void' type.
  bool IsVoidType() const { return type_class_id() == kVoidCid; }

  // Check if this type represents the 'Null' type.
  bool IsNullType() const;

  // Check if this type represents the 'Never' type.
  bool IsNeverType() const;

  // Check if this type represents the 'Object' type.
  bool IsObjectType() const { return type_class_id() == kInstanceCid; }

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

  // Check if this type represents the 'String' type.
  bool IsStringType() const;

  // Check if this type represents the Dart 'Function' type.
  bool IsDartFunctionType() const;

  // Check if this type represents the Dart '_Closure' type.
  bool IsDartClosureType() const;

  // Check if this type represents the 'Pointer' type from "dart:ffi".
  bool IsFfiPointerType() const;

  // Check if this type represents the 'FutureOr' type.
  bool IsFutureOrType() const { return type_class_id() == kFutureOrCid; }

  // Returns the type argument of this (possibly nested) 'FutureOr' type.
  // Returns unmodified type if this type is not a 'FutureOr' type.
  AbstractTypePtr UnwrapFutureOr() const;

  // Returns true if catching this type will catch all exceptions.
  // Exception objects are guaranteed to be non-nullable, so
  // non-nullable Object is also a catch-all type.
  bool IsCatchAllType() const { return IsDynamicType() || IsObjectType(); }

  // Check the subtype relationship.
  bool IsSubtypeOf(const AbstractType& other,
                   Heap::Space space,
                   TrailPtr trail = nullptr) const;

  // Returns true iff subtype is a subtype of supertype, false otherwise or if
  // an error occurred.
  static bool InstantiateAndTestSubtype(
      AbstractType* subtype,
      AbstractType* supertype,
      const TypeArguments& instantiator_type_args,
      const TypeArguments& function_type_args);

  static intptr_t type_test_stub_entry_point_offset() {
    return OFFSET_OF(AbstractTypeLayout, type_test_stub_entry_point_);
  }

  uword type_test_stub_entry_point() const {
    return raw_ptr()->type_test_stub_entry_point_;
  }
  CodePtr type_test_stub() const { return raw_ptr()->type_test_stub(); }

  void SetTypeTestingStub(const Code& stub) const;

 private:
  // Returns true if this type is a subtype of FutureOr<T> specified by 'other'.
  // Returns false if other type is not a FutureOr.
  bool IsSubtypeOfFutureOr(Zone* zone,
                           const AbstractType& other,
                           Heap::Space space,
                           TrailPtr trail = nullptr) const;

 protected:
  HEAP_OBJECT_IMPLEMENTATION(AbstractType, Instance);
  friend class Class;
  friend class Function;
  friend class TypeArguments;
};

// A Type consists of a class, possibly parameterized with type
// arguments. Example: C<T1, T2>.
//
// Caution: 'TypePtr' denotes a 'raw' pointer to a VM object of class Type, as
// opposed to 'Type' denoting a 'handle' to the same object. 'RawType' does not
// relate to a 'raw type', as opposed to a 'cooked type' or 'rare type'.
class Type : public AbstractType {
 public:
  static intptr_t type_class_id_offset() {
    return OFFSET_OF(TypeLayout, type_class_id_);
  }
  static intptr_t arguments_offset() {
    return OFFSET_OF(TypeLayout, arguments_);
  }
  static intptr_t type_state_offset() {
    return OFFSET_OF(TypeLayout, type_state_);
  }
  static intptr_t hash_offset() { return OFFSET_OF(TypeLayout, hash_); }
  static intptr_t nullability_offset() {
    return OFFSET_OF(TypeLayout, nullability_);
  }
  virtual bool IsFinalized() const {
    return (raw_ptr()->type_state_ == TypeLayout::kFinalizedInstantiated) ||
           (raw_ptr()->type_state_ == TypeLayout::kFinalizedUninstantiated);
  }
  virtual void SetIsFinalized() const;
  void ResetIsFinalized() const;  // Ignore current state and set again.
  virtual bool IsBeingFinalized() const {
    return raw_ptr()->type_state_ == TypeLayout::kBeingFinalized;
  }
  virtual void SetIsBeingFinalized() const;
  virtual bool HasTypeClass() const {
    ASSERT(type_class_id() != kIllegalCid);
    return true;
  }
  virtual Nullability nullability() const {
    return static_cast<Nullability>(raw_ptr()->nullability_);
  }
  TypePtr ToNullability(Nullability value, Heap::Space space) const;
  virtual classid_t type_class_id() const;
  virtual ClassPtr type_class() const;
  void set_type_class(const Class& value) const;
  virtual TypeArgumentsPtr arguments() const { return raw_ptr()->arguments(); }
  virtual void set_arguments(const TypeArguments& value) const;
  virtual TokenPosition token_pos() const { return raw_ptr()->token_pos_; }
  virtual bool IsInstantiated(Genericity genericity = kAny,
                              intptr_t num_free_fun_type_params = kAllFree,
                              TrailPtr trail = nullptr) const;
  virtual bool IsEquivalent(const Instance& other,
                            TypeEquality kind,
                            TrailPtr trail = nullptr) const;
  virtual bool IsRecursive() const;

  // Return true if this type can be used as the declaration type of cls after
  // canonicalization (passed-in cls must match type_class()).
  bool IsDeclarationTypeOf(const Class& cls) const;

  // If signature is not null, this type represents a function type. Note that
  // the signature fully represents the type and type arguments can be ignored.
  // However, in case of a generic typedef, they document how the typedef class
  // was parameterized to obtain the actual signature.
  FunctionPtr signature() const;
  void set_signature(const Function& value) const;
  static intptr_t signature_offset() {
    return OFFSET_OF(TypeLayout, signature_);
  }

  virtual bool IsFunctionType() const {
    return signature() != Function::null();
  }
  virtual AbstractTypePtr InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      TrailPtr trail = nullptr) const;
  virtual AbstractTypePtr Canonicalize(Thread* thread, TrailPtr trail) const;
#if defined(DEBUG)
  // Check if type is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const;
#endif  // DEBUG
  virtual void EnumerateURIs(URIs* uris) const;

  virtual intptr_t Hash() const;
  intptr_t ComputeHash() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(TypeLayout));
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
                     TokenPosition token_pos,
                     Nullability nullability = Nullability::kLegacy,
                     Heap::Space space = Heap::kOld);

 private:
  void SetHash(intptr_t value) const;

  void set_token_pos(TokenPosition token_pos) const;
  void set_type_state(int8_t state) const;
  void set_nullability(Nullability value) const {
    ASSERT(!IsCanonical());
    StoreNonPointer(&raw_ptr()->nullability_, static_cast<int8_t>(value));
  }

  static TypePtr New(Heap::Space space = Heap::kOld);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Type, AbstractType);
  friend class Class;
  friend class TypeArguments;
  friend class ClearTypeHashVisitor;
};

// A TypeRef is used to break cycles in the representation of recursive types.
// Its only field is the recursive AbstractType it refers to, which can
// temporarily be null during finalization.
// Note that the cycle always involves type arguments.
class TypeRef : public AbstractType {
 public:
  static intptr_t type_offset() { return OFFSET_OF(TypeRefLayout, type_); }

  virtual bool IsFinalized() const {
    const AbstractType& ref_type = AbstractType::Handle(type());
    return !ref_type.IsNull() && ref_type.IsFinalized();
  }
  virtual bool IsBeingFinalized() const {
    const AbstractType& ref_type = AbstractType::Handle(type());
    return ref_type.IsNull() || ref_type.IsBeingFinalized();
  }
  virtual Nullability nullability() const {
    const AbstractType& ref_type = AbstractType::Handle(type());
    ASSERT(!ref_type.IsNull());
    return ref_type.nullability();
  }
  virtual bool HasTypeClass() const {
    return (type() != AbstractType::null()) &&
           AbstractType::Handle(type()).HasTypeClass();
  }
  AbstractTypePtr type() const { return raw_ptr()->type(); }
  void set_type(const AbstractType& value) const;
  virtual classid_t type_class_id() const {
    return AbstractType::Handle(type()).type_class_id();
  }
  virtual ClassPtr type_class() const {
    return AbstractType::Handle(type()).type_class();
  }
  virtual TypeArgumentsPtr arguments() const {
    return AbstractType::Handle(type()).arguments();
  }
  virtual TokenPosition token_pos() const {
    return AbstractType::Handle(type()).token_pos();
  }
  virtual bool IsInstantiated(Genericity genericity = kAny,
                              intptr_t num_free_fun_type_params = kAllFree,
                              TrailPtr trail = nullptr) const;
  virtual bool IsEquivalent(const Instance& other,
                            TypeEquality kind,
                            TrailPtr trail = nullptr) const;
  virtual bool IsRecursive() const { return true; }
  virtual bool IsFunctionType() const {
    const AbstractType& ref_type = AbstractType::Handle(type());
    return !ref_type.IsNull() && ref_type.IsFunctionType();
  }
  virtual AbstractTypePtr InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      TrailPtr trail = nullptr) const;
  virtual AbstractTypePtr Canonicalize(Thread* thread, TrailPtr trail) const;
#if defined(DEBUG)
  // Check if typeref is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const;
#endif  // DEBUG
  virtual void EnumerateURIs(URIs* uris) const;

  virtual intptr_t Hash() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(TypeRefLayout));
  }

  static TypeRefPtr New(const AbstractType& type);

 private:
  static TypeRefPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypeRef, AbstractType);
  friend class Class;
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
  virtual bool IsFinalized() const {
    return TypeParameterLayout::FinalizedBit::decode(raw_ptr()->flags_);
  }
  virtual void SetIsFinalized() const;
  virtual bool IsBeingFinalized() const { return false; }
  static intptr_t flags_offset() {
    return OFFSET_OF(TypeParameterLayout, flags_);
  }
  bool IsGenericCovariantImpl() const {
    return TypeParameterLayout::GenericCovariantImplBit::decode(
        raw_ptr()->flags_);
  }
  void SetGenericCovariantImpl(bool value) const;
  bool IsDeclaration() const {
    return TypeParameterLayout::DeclarationBit::decode(raw_ptr()->flags_);
  }
  void SetDeclaration(bool value) const;
  static intptr_t nullability_offset() {
    return OFFSET_OF(TypeParameterLayout, nullability_);
  }
  virtual Nullability nullability() const {
    return static_cast<Nullability>(raw_ptr()->nullability_);
  }
  TypeParameterPtr ToNullability(Nullability value, Heap::Space space) const;
  virtual bool HasTypeClass() const { return false; }
  virtual classid_t type_class_id() const { return kIllegalCid; }
  classid_t parameterized_class_id() const;
  ClassPtr parameterized_class() const;
  FunctionPtr parameterized_function() const {
    return raw_ptr()->parameterized_function();
  }
  bool IsClassTypeParameter() const {
    return parameterized_class_id() != kFunctionCid;
  }
  bool IsFunctionTypeParameter() const {
    return parameterized_function() != Function::null();
  }
  ObjectPtr Owner() const {
    if (IsClassTypeParameter()) {
      return parameterized_class();
    } else {
      return parameterized_function();
    }
  }

  static intptr_t parameterized_class_id_offset() {
    return OFFSET_OF(TypeParameterLayout, parameterized_class_id_);
  }
  static intptr_t index_offset() {
    return OFFSET_OF(TypeParameterLayout, index_);
  }

  StringPtr name() const { return raw_ptr()->name(); }
  static intptr_t name_offset() {
    return OFFSET_OF(TypeParameterLayout, name_);
  }
  intptr_t index() const { return raw_ptr()->index_; }
  void set_index(intptr_t value) const;
  AbstractTypePtr bound() const { return raw_ptr()->bound(); }
  void set_bound(const AbstractType& value) const;
  AbstractTypePtr default_argument() const {
    return raw_ptr()->default_argument();
  }
  void set_default_argument(const AbstractType& value) const;
  static intptr_t bound_offset() {
    return OFFSET_OF(TypeParameterLayout, bound_);
  }
  virtual TokenPosition token_pos() const { return raw_ptr()->token_pos_; }
  virtual bool IsInstantiated(Genericity genericity = kAny,
                              intptr_t num_free_fun_type_params = kAllFree,
                              TrailPtr trail = nullptr) const;
  virtual bool IsEquivalent(const Instance& other,
                            TypeEquality kind,
                            TrailPtr trail = nullptr) const;
  virtual bool IsRecursive() const { return false; }
  virtual AbstractTypePtr InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      TrailPtr trail = nullptr) const;
  virtual AbstractTypePtr Canonicalize(Thread* thread, TrailPtr trail) const;
#if defined(DEBUG)
  // Check if type parameter is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const;
#endif  // DEBUG
  virtual void EnumerateURIs(URIs* uris) const;

  virtual intptr_t Hash() const;

  // Returns type corresponding to [this] type parameter from the
  // given [instantiator_type_arguments] and [function_type_arguments].
  // Unlike InstantiateFrom, nullability of type parameter is not applied to
  // the result.
  AbstractTypePtr GetFromTypeArguments(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(TypeParameterLayout));
  }

  // Only one of parameterized_class and parameterized_function is non-null.
  static TypeParameterPtr New(const Class& parameterized_class,
                              const Function& parameterized_function,
                              intptr_t index,
                              const String& name,
                              const AbstractType& bound,
                              bool is_generic_covariant_impl,
                              Nullability nullability,
                              TokenPosition token_pos);

 private:
  intptr_t ComputeHash() const;
  void SetHash(intptr_t value) const;

  void set_parameterized_class(const Class& value) const;
  void set_parameterized_function(const Function& value) const;
  void set_name(const String& value) const;
  void set_token_pos(TokenPosition token_pos) const;
  void set_flags(uint8_t flags) const;
  void set_nullability(Nullability value) const;

  static TypeParameterPtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypeParameter, AbstractType);
  friend class Class;
  friend class ClearTypeHashVisitor;
};

class Number : public Instance {
 public:
  // TODO(iposva): Add more useful Number methods.
  StringPtr ToString(Heap::Space space) const;

  // Numbers are canonicalized differently from other instances/strings.
  // Caller must hold Isolate::constant_canonicalization_mutex_.
  virtual InstancePtr CanonicalizeLocked(Thread* thread) const;

#if defined(DEBUG)
  // Check if number is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const;
#endif  // DEBUG

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
  virtual uint32_t CanonicalizeHash() const { return AsTruncatedUint32Value(); }
  virtual bool Equals(const Instance& other) const;

  virtual ObjectPtr HashCode() const { return raw(); }

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
    intptr_t raw_value = static_cast<intptr_t>(obj);
    if ((raw_value & kSmiTagMask) == kSmiTag) {
      return (raw_value >> kSmiTagShift);
    } else {
      ASSERT(obj->IsMint());
      return static_cast<const MintPtr>(obj)->ptr()->value_;
    }
  }

 private:
  OBJECT_IMPLEMENTATION(Integer, Number);
  friend class Class;
};

class Smi : public Integer {
 public:
  static const intptr_t kBits = kSmiBits;
  static const intptr_t kMaxValue = kSmiMax;
  static const intptr_t kMinValue = kSmiMin;

  intptr_t Value() const { return RawSmiValue(raw()); }

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

  static SmiPtr FromAlignedAddress(uword address) {
    ASSERT((address & kSmiTagMask) == kSmiTag);
    return static_cast<SmiPtr>(address);
  }

  static ClassPtr Class();

  static intptr_t Value(const SmiPtr raw_smi) { return RawSmiValue(raw_smi); }

  static intptr_t RawValue(intptr_t value) {
    return static_cast<intptr_t>(New(value));
  }

  static bool IsValid(int64_t value) { return compiler::target::IsSmi(value); }

  void operator=(SmiPtr value) {
    raw_ = value;
    CHECK_HANDLE();
  }
  void operator^=(ObjectPtr value) {
    raw_ = value;
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
  static const intptr_t kBits = 63;  // 64-th bit is sign.
  static const int64_t kMaxValue =
      static_cast<int64_t>(DART_2PART_UINT64_C(0x7FFFFFFF, FFFFFFFF));
  static const int64_t kMinValue =
      static_cast<int64_t>(DART_2PART_UINT64_C(0x80000000, 00000000));

  int64_t value() const { return raw_ptr()->value_; }
  static intptr_t value_offset() { return OFFSET_OF(MintLayout, value_); }

  virtual bool IsZero() const { return value() == 0; }
  virtual bool IsNegative() const { return value() < 0; }

  virtual bool Equals(const Instance& other) const;

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;
  virtual uint32_t AsTruncatedUint32Value() const;

  virtual bool FitsIntoSmi() const;

  virtual int CompareWith(const Integer& other) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(MintLayout));
  }

 protected:
  // Only Integer::NewXXX is allowed to call Mint::NewXXX directly.
  friend class Integer;

  static MintPtr New(int64_t value, Heap::Space space = Heap::kNew);

  static MintPtr NewCanonical(int64_t value);
  static MintPtr NewCanonicalLocked(Thread* thread, int64_t value);

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
  double value() const { return raw_ptr()->value_; }

  bool BitwiseEqualsToDouble(double value) const;
  virtual bool OperatorEquals(const Instance& other) const;
  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const;

  static DoublePtr New(double d, Heap::Space space = Heap::kNew);

  static DoublePtr New(const String& str, Heap::Space space = Heap::kNew);

  // Returns a canonical double object allocated in the old gen space.
  static DoublePtr NewCanonical(double d);
  static DoublePtr NewCanonicalLocked(Thread* thread, double d);

  // Returns a canonical double object (allocated in the old gen space) or
  // Double::null() if str points to a string that does not convert to a
  // double value.
  static DoublePtr NewCanonical(const String& str);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(DoubleLayout));
  }

  static intptr_t value_offset() { return OFFSET_OF(DoubleLayout, value_); }

 private:
  void set_value(double value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Double, Number);
  friend class Class;
  friend class Number;
};

// String may not be '\0' terminated.
class String : public Instance {
 public:
  // We use 30 bits for the hash code so hashes in a snapshot taken on a
  // 64-bit architecture stay in Smi range when loaded on a 32-bit
  // architecture.
  static const intptr_t kHashBits = 30;

  static const intptr_t kOneByteChar = 1;
  static const intptr_t kTwoByteChar = 2;

// All strings share the same maximum element count to keep things
// simple.  We choose a value that will prevent integer overflow for
// 2 byte strings, since it is the worst case.
#if defined(HASH_IN_OBJECT_HEADER)
  static const intptr_t kSizeofRawString = sizeof(InstanceLayout) + kWordSize;
#else
  static const intptr_t kSizeofRawString =
      sizeof(InstanceLayout) + 2 * kWordSize;
#endif
  static const intptr_t kMaxElements = kSmiMax / kTwoByteChar;

  static intptr_t HeaderSize() { return String::kSizeofRawString; }

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

  intptr_t Length() const { return LengthOf(raw()); }
  static intptr_t LengthOf(StringPtr obj) {
    return Smi::Value(obj->ptr()->length());
  }
  static intptr_t length_offset() { return OFFSET_OF(StringLayout, length_); }

  intptr_t Hash() const {
    intptr_t result = GetCachedHash(raw());
    if (result != 0) {
      return result;
    }
    result = String::Hash(*this, 0, this->Length());
    SetCachedHash(raw(), result);
    return result;
  }

  static intptr_t Hash(StringPtr raw);

  bool HasHash() const {
    ASSERT(Smi::New(0) == nullptr);
    return GetCachedHash(raw()) != 0;
  }

  static intptr_t hash_offset() {
#if defined(HASH_IN_OBJECT_HEADER)
    COMPILE_ASSERT(ObjectLayout::kHashTagPos % kBitsPerByte == 0);
    return OFFSET_OF(ObjectLayout, tags_) +
           ObjectLayout::kHashTagPos / kBitsPerByte;
#else
    return OFFSET_OF(StringLayout, hash_);
#endif
  }
  static intptr_t Hash(const String& str, intptr_t begin_index, intptr_t len);
  static intptr_t Hash(const char* characters, intptr_t len);
  static intptr_t Hash(const uint16_t* characters, intptr_t len);
  static intptr_t Hash(const int32_t* characters, intptr_t len);
  static intptr_t HashRawSymbol(const StringPtr symbol) {
    ASSERT(symbol->ptr()->IsCanonical());
    intptr_t result = GetCachedHash(symbol);
    ASSERT(result != 0);
    return result;
  }

  // Returns the hash of str1 + str2.
  static intptr_t HashConcat(const String& str1, const String& str2);

  virtual ObjectPtr HashCode() const { return Integer::New(Hash()); }

  uint16_t CharAt(intptr_t index) const { return CharAt(raw(), index); }
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
    return StartsWith(raw(), other.raw());
  }
  static bool StartsWith(StringPtr str, StringPtr prefix);
  bool EndsWith(const String& other) const;

  // Strings are canonicalized using the symbol table.
  // Caller must hold Isolate::constant_canonicalization_mutex_.
  virtual InstancePtr CanonicalizeLocked(Thread* thread) const;

#if defined(DEBUG)
  // Check if string is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const;
#endif  // DEBUG

  bool IsSymbol() const { return raw()->ptr()->IsCanonical(); }

  bool IsOneByteString() const {
    return raw()->GetClassId() == kOneByteStringCid;
  }

  bool IsTwoByteString() const {
    return raw()->GetClassId() == kTwoByteStringCid;
  }

  bool IsExternalOneByteString() const {
    return raw()->GetClassId() == kExternalOneByteStringCid;
  }

  bool IsExternalTwoByteString() const {
    return raw()->GetClassId() == kExternalTwoByteStringCid;
  }

  bool IsExternal() const {
    return IsExternalStringClassId(raw()->GetClassId());
  }

  void* GetPeer() const;

  char* ToMallocCString() const;
  void ToUTF8(uint8_t* utf8_array, intptr_t array_len) const;

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
    return Smi::Value(obj->ptr()->hash_);
  }

  static void SetCachedHash(StringPtr obj, uint32_t hash) {
    obj->ptr()->hash_ = Smi::New(hash);
  }
#endif

 protected:
  // These two operate on an array of Latin-1 encoded characters.
  // They are protected to avoid mistaking Latin-1 for UTF-8, but used
  // by friendly templated code (e.g., Symbols).
  bool Equals(const uint8_t* characters, intptr_t len) const;
  static intptr_t Hash(const uint8_t* characters, intptr_t len);

  void SetLength(intptr_t value) const {
    // This is only safe because we create a new Smi, which does not cause
    // heap allocation.
    raw_ptr()->set_length(Smi::New(value));
  }

  void SetHash(intptr_t value) const { SetCachedHash(raw(), value); }

  template <typename HandleType, typename ElementType, typename CallbackType>
  static void ReadFromImpl(SnapshotReader* reader,
                           String* str_obj,
                           intptr_t len,
                           intptr_t tags,
                           CallbackType new_symbol,
                           Snapshot::Kind kind);

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
  friend class OneByteStringLayout;
  friend class RODataSerializationCluster;  // SetHash
  friend class Pass2Visitor;                // Stack "handle"
};

// Synchronize with implementation in compiler (intrinsifier).
class StringHasher : ValueObject {
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
    NoSafepointScope no_safepoint;
    return OneByteString::CharAt(static_cast<OneByteStringPtr>(str.raw()),
                                 index);
  }

  static uint16_t CharAt(OneByteStringPtr str, intptr_t index) {
    ASSERT(index >= 0 && index < String::LengthOf(str));
    return str->ptr()->data()[index];
  }

  static void SetCharAt(const String& str, intptr_t index, uint8_t code_unit) {
    NoSafepointScope no_safepoint;
    *CharAddr(str, index) = code_unit;
  }
  static OneByteStringPtr EscapeSpecialCharacters(const String& str);
  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(OneByteStringLayout, data);
  }

  static intptr_t UnroundedSize(OneByteStringPtr str) {
    return UnroundedSize(Smi::Value(str->ptr()->length()));
  }
  static intptr_t UnroundedSize(intptr_t len) {
    return sizeof(OneByteStringLayout) + (len * kBytesPerElement);
  }
  static intptr_t InstanceSize() {
    ASSERT(sizeof(OneByteStringLayout) ==
           OFFSET_OF_RETURNED_VALUE(OneByteStringLayout, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(sizeof(OneByteStringLayout) == String::kSizeofRawString);
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

  static OneByteStringPtr New(const TypedData& other_typed_data,
                              intptr_t other_start_index,
                              intptr_t other_len,
                              Heap::Space space = Heap::kNew);

  static OneByteStringPtr New(const ExternalTypedData& other_typed_data,
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
    return static_cast<OneByteStringPtr>(str.raw());
  }

  static const OneByteStringLayout* raw_ptr(const String& str) {
    return reinterpret_cast<const OneByteStringLayout*>(str.raw_ptr());
  }

  static uint8_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsOneByteString());
    return &str.UnsafeMutableNonPointer(raw_ptr(str)->data())[index];
  }

  static uint8_t* DataStart(const String& str) {
    ASSERT(str.IsOneByteString());
    return &str.UnsafeMutableNonPointer(raw_ptr(str)->data())[0];
  }

  static OneByteStringPtr ReadFrom(SnapshotReader* reader,
                                   intptr_t object_id,
                                   intptr_t tags,
                                   Snapshot::Kind kind,
                                   bool as_reference);

  friend class Class;
  friend class ExternalOneByteString;
  friend class ImageWriter;
  friend class SnapshotReader;
  friend class String;
  friend class StringHasher;
  friend class Symbols;
  friend class Utf8;
};

class TwoByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    ASSERT(str.IsTwoByteString());
    NoSafepointScope no_safepoint;
    return TwoByteString::CharAt(static_cast<TwoByteStringPtr>(str.raw()),
                                 index);
  }

  static uint16_t CharAt(TwoByteStringPtr str, intptr_t index) {
    ASSERT(index >= 0 && index < String::LengthOf(str));
    return str->ptr()->data()[index];
  }

  static void SetCharAt(const String& str, intptr_t index, uint16_t ch) {
    NoSafepointScope no_safepoint;
    *CharAddr(str, index) = ch;
  }

  static TwoByteStringPtr EscapeSpecialCharacters(const String& str);

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 2;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(TwoByteStringLayout, data);
  }
  static intptr_t UnroundedSize(TwoByteStringPtr str) {
    return UnroundedSize(Smi::Value(str->ptr()->length()));
  }
  static intptr_t UnroundedSize(intptr_t len) {
    return sizeof(TwoByteStringLayout) + (len * kBytesPerElement);
  }
  static intptr_t InstanceSize() {
    ASSERT(sizeof(TwoByteStringLayout) ==
           OFFSET_OF_RETURNED_VALUE(TwoByteStringLayout, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(sizeof(TwoByteStringLayout) == String::kSizeofRawString);
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

  static TwoByteStringPtr New(const TypedData& other_typed_data,
                              intptr_t other_start_index,
                              intptr_t other_len,
                              Heap::Space space = Heap::kNew);

  static TwoByteStringPtr New(const ExternalTypedData& other_typed_data,
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
    return static_cast<TwoByteStringPtr>(str.raw());
  }

  static const TwoByteStringLayout* raw_ptr(const String& str) {
    return reinterpret_cast<const TwoByteStringLayout*>(str.raw_ptr());
  }

  static uint16_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsTwoByteString());
    return &str.UnsafeMutableNonPointer(raw_ptr(str)->data())[index];
  }

  // Use this instead of CharAddr(0).  It will not assert that the index is <
  // length.
  static uint16_t* DataStart(const String& str) {
    ASSERT(str.IsTwoByteString());
    return &str.UnsafeMutableNonPointer(raw_ptr(str)->data())[0];
  }

  static TwoByteStringPtr ReadFrom(SnapshotReader* reader,
                                   intptr_t object_id,
                                   intptr_t tags,
                                   Snapshot::Kind kind,
                                   bool as_reference);

  friend class Class;
  friend class ImageWriter;
  friend class SnapshotReader;
  friend class String;
  friend class StringHasher;
  friend class Symbols;
};

class ExternalOneByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    ASSERT(str.IsExternalOneByteString());
    NoSafepointScope no_safepoint;
    return ExternalOneByteString::CharAt(
        static_cast<ExternalOneByteStringPtr>(str.raw()), index);
  }

  static uint16_t CharAt(ExternalOneByteStringPtr str, intptr_t index) {
    ASSERT(index >= 0 && index < String::LengthOf(str));
    return str->ptr()->external_data_[index];
  }

  static void* GetPeer(const String& str) { return raw_ptr(str)->peer_; }

  static intptr_t external_data_offset() {
    return OFFSET_OF(ExternalOneByteStringLayout, external_data_);
  }

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    return String::RoundedAllocationSize(sizeof(ExternalOneByteStringLayout));
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
    return static_cast<ExternalOneByteStringPtr>(str.raw());
  }

  static const ExternalOneByteStringLayout* raw_ptr(const String& str) {
    return reinterpret_cast<const ExternalOneByteStringLayout*>(str.raw_ptr());
  }

  static const uint8_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsExternalOneByteString());
    return &(raw_ptr(str)->external_data_[index]);
  }

  static const uint8_t* DataStart(const String& str) {
    ASSERT(str.IsExternalOneByteString());
    return raw_ptr(str)->external_data_;
  }

  static void SetExternalData(const String& str,
                              const uint8_t* data,
                              void* peer) {
    ASSERT(str.IsExternalOneByteString());
    ASSERT(
        !Isolate::Current()->heap()->Contains(reinterpret_cast<uword>(data)));
    str.StoreNonPointer(&raw_ptr(str)->external_data_, data);
    str.StoreNonPointer(&raw_ptr(str)->peer_, peer);
  }

  static void Finalize(void* isolate_callback_data,
                       Dart_WeakPersistentHandle handle,
                       void* peer);

  static ExternalOneByteStringPtr ReadFrom(SnapshotReader* reader,
                                           intptr_t object_id,
                                           intptr_t tags,
                                           Snapshot::Kind kind,
                                           bool as_reference);

  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  friend class Class;
  friend class String;
  friend class StringHasher;
  friend class SnapshotReader;
  friend class Symbols;
  friend class Utf8;
};

class ExternalTwoByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    ASSERT(str.IsExternalTwoByteString());
    NoSafepointScope no_safepoint;
    return ExternalTwoByteString::CharAt(
        static_cast<ExternalTwoByteStringPtr>(str.raw()), index);
  }

  static uint16_t CharAt(ExternalTwoByteStringPtr str, intptr_t index) {
    ASSERT(index >= 0 && index < String::LengthOf(str));
    return str->ptr()->external_data_[index];
  }

  static void* GetPeer(const String& str) { return raw_ptr(str)->peer_; }

  static intptr_t external_data_offset() {
    return OFFSET_OF(ExternalTwoByteStringLayout, external_data_);
  }

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 2;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    return String::RoundedAllocationSize(sizeof(ExternalTwoByteStringLayout));
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
    return static_cast<ExternalTwoByteStringPtr>(str.raw());
  }

  static const ExternalTwoByteStringLayout* raw_ptr(const String& str) {
    return reinterpret_cast<const ExternalTwoByteStringLayout*>(str.raw_ptr());
  }

  static const uint16_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsExternalTwoByteString());
    return &(raw_ptr(str)->external_data_[index]);
  }

  static const uint16_t* DataStart(const String& str) {
    ASSERT(str.IsExternalTwoByteString());
    return raw_ptr(str)->external_data_;
  }

  static void SetExternalData(const String& str,
                              const uint16_t* data,
                              void* peer) {
    ASSERT(str.IsExternalTwoByteString());
    ASSERT(
        !Isolate::Current()->heap()->Contains(reinterpret_cast<uword>(data)));
    str.StoreNonPointer(&raw_ptr(str)->external_data_, data);
    str.StoreNonPointer(&raw_ptr(str)->peer_, peer);
  }

  static void Finalize(void* isolate_callback_data,
                       Dart_WeakPersistentHandle handle,
                       void* peer);

  static ExternalTwoByteStringPtr ReadFrom(SnapshotReader* reader,
                                           intptr_t object_id,
                                           intptr_t tags,
                                           Snapshot::Kind kind,
                                           bool as_reference);

  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  friend class Class;
  friend class String;
  friend class StringHasher;
  friend class SnapshotReader;
  friend class Symbols;
};

// Class Bool implements Dart core class bool.
class Bool : public Instance {
 public:
  bool value() const { return raw_ptr()->value_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(BoolLayout));
  }

  static const Bool& True() { return Object::bool_true(); }

  static const Bool& False() { return Object::bool_false(); }

  static const Bool& Get(bool value) {
    return value ? Bool::True() : Bool::False();
  }

  virtual uint32_t CanonicalizeHash() const {
    return raw() == True().raw() ? 1231 : 1237;
  }

 private:
  void set_value(bool value) const {
    StoreNonPointer(&raw_ptr()->value_, value);
  }

  // New should only be called to initialize the two legal bool values.
  static BoolPtr New(bool value);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Bool, Instance);
  friend class Class;
  friend class Object;  // To initialize the true and false values.
};

class Array : public Instance {
 public:
  // We use 30 bits for the hash code so hashes in a snapshot taken on a
  // 64-bit architecture stay in Smi range when loaded on a 32-bit
  // architecture.
  static const intptr_t kHashBits = 30;

  // Returns `true` if we use card marking for arrays of length [array_length].
  static bool UseCardMarkingForAllocation(const intptr_t array_length) {
    return Array::InstanceSize(array_length) > Heap::kNewAllocatableSize;
  }

  intptr_t Length() const { return LengthOf(raw()); }
  static intptr_t LengthOf(const ArrayPtr array) {
    return Smi::Value(array->ptr()->length());
  }

  static intptr_t length_offset() { return OFFSET_OF(ArrayLayout, length_); }
  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(ArrayLayout, data);
  }
  static intptr_t element_offset(intptr_t index) {
    return OFFSET_OF_RETURNED_VALUE(ArrayLayout, data) + kWordSize * index;
  }
  static intptr_t index_at_offset(intptr_t offset_in_bytes) {
    intptr_t index = (offset_in_bytes - data_offset()) / kWordSize;
    ASSERT(index >= 0);
    return index;
  }

  struct ArrayTraits {
    static intptr_t elements_start_offset() { return Array::data_offset(); }

    static constexpr intptr_t kElementSize = kWordSize;
  };

  static bool Equals(ArrayPtr a, ArrayPtr b) {
    if (a == b) return true;
    if (a->IsRawNull() || b->IsRawNull()) return false;
    if (a->ptr()->length() != b->ptr()->length()) return false;
    if (a->ptr()->type_arguments() != b->ptr()->type_arguments()) return false;
    const intptr_t length = LengthOf(a);
    return memcmp(a->ptr()->data(), b->ptr()->data(), kWordSize * length) == 0;
  }

  static ObjectPtr* DataOf(ArrayPtr array) { return array->ptr()->data(); }

  template <std::memory_order order = std::memory_order_relaxed>
  ObjectPtr At(intptr_t index) const {
    return raw_ptr()->element(index);
  }
  template <std::memory_order order = std::memory_order_relaxed>
  void SetAt(intptr_t index, const Object& value) const {
    // TODO(iposva): Add storing NoSafepointScope.
    raw_ptr()->set_element(index, value.raw());
  }

  // Access to the array with acquire release semantics.
  ObjectPtr AtAcquire(intptr_t index) const {
    return raw_ptr()->element<std::memory_order_acquire>(index);
  }
  void SetAtRelease(intptr_t index, const Object& value) const {
    raw_ptr()->set_element<std::memory_order_release>(index, value.raw());
  }

  bool IsImmutable() const { return raw()->GetClassId() == kImmutableArrayCid; }

  // Position of element type in type arguments.
  static const intptr_t kElementTypeTypeArgPos = 0;

  virtual TypeArgumentsPtr GetTypeArguments() const {
    return raw_ptr()->type_arguments();
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
    StoreArrayPointer(&raw_ptr()->type_arguments_, value.raw());
  }

  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const;

  static const intptr_t kBytesPerElement = kWordSize;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;
  static const intptr_t kMaxNewSpaceElements =
      (Heap::kNewAllocatableSize - sizeof(ArrayLayout)) / kBytesPerElement;

  static intptr_t type_arguments_offset() {
    return OFFSET_OF(ArrayLayout, type_arguments_);
  }

  static bool IsValidLength(intptr_t len) {
    return 0 <= len && len <= kMaxElements;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(ArrayLayout) == OFFSET_OF_RETURNED_VALUE(ArrayLayout, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    // Ensure that variable length data is not adding to the object length.
    ASSERT(sizeof(ArrayLayout) == (sizeof(InstanceLayout) + (2 * kWordSize)));
    ASSERT(IsValidLength(len));
    return RoundedAllocationSize(sizeof(ArrayLayout) +
                                 (len * kBytesPerElement));
  }

  virtual void CanonicalizeFieldsLocked(Thread* thread) const;

  // Make the array immutable to Dart code by switching the class pointer
  // to ImmutableArray.
  void MakeImmutable() const;

  static ArrayPtr New(intptr_t len, Heap::Space space = Heap::kNew);
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

 protected:
  static ArrayPtr New(intptr_t class_id,
                      intptr_t len,
                      Heap::Space space = Heap::kNew);

 private:
  ObjectPtr const* ObjectAddr(intptr_t index) const {
    // TODO(iposva): Determine if we should throw an exception here.
    ASSERT((index >= 0) && (index < Length()));
    return &raw_ptr()->data()[index];
  }

  void SetLength(intptr_t value) const {
    raw_ptr()->set_length(Smi::New(value));
  }
  void SetLengthRelease(intptr_t value) const {
    raw_ptr()->set_length<std::memory_order_release>(Smi::New(value));
  }

  template <typename type, std::memory_order order = std::memory_order_relaxed>
  void StoreArrayPointer(type const* addr, type value) const {
    raw()->ptr()->StoreArrayPointer<type, order>(addr, value);
  }

  // Store a range of pointers [from, from + count) into [to, to + count).
  // TODO(koda): Use this to fix Object::Clone's broken store buffer logic.
  void StoreArrayPointers(ObjectPtr const* to,
                          ObjectPtr const* from,
                          intptr_t count) {
    ASSERT(Contains(reinterpret_cast<uword>(to)));
    if (raw()->IsNewObject()) {
      memmove(const_cast<ObjectPtr*>(to), from, count * kWordSize);
    } else {
      for (intptr_t i = 0; i < count; ++i) {
        StoreArrayPointer(&to[i], from[i]);
      }
    }
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Array, Instance);
  friend class Class;
  friend class ImmutableArray;
  friend class Object;
  friend class String;
};

class ImmutableArray : public AllStatic {
 public:
  static ImmutableArrayPtr New(intptr_t len, Heap::Space space = Heap::kNew);

  static ImmutableArrayPtr ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    intptr_t tags,
                                    Snapshot::Kind kind,
                                    bool as_reference);

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
    return static_cast<ImmutableArrayPtr>(array.raw());
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
    return Smi::Value(raw_ptr()->length());
  }
  void SetLength(intptr_t value) const {
    // This is only safe because we create a new Smi, which does not cause
    // heap allocation.
    raw_ptr()->set_length(Smi::New(value));
  }

  ArrayPtr data() const { return raw_ptr()->data(); }
  void SetData(const Array& value) const { raw_ptr()->set_data(value.raw()); }

  ObjectPtr At(intptr_t index) const {
    NoSafepointScope no_safepoint;
    ASSERT(!IsNull());
    ASSERT(index < Length());
    return data()->ptr()->element(index);
  }
  void SetAt(intptr_t index, const Object& value) const {
    ASSERT(!IsNull());
    ASSERT(index < Length());

    // TODO(iposva): Add storing NoSafepointScope.
    data()->ptr()->set_element(index, value.raw());
  }

  void Add(const Object& value, Heap::Space space = Heap::kNew) const;

  void Grow(intptr_t new_capacity, Heap::Space space = Heap::kNew) const;
  ObjectPtr RemoveLast() const;

  virtual TypeArgumentsPtr GetTypeArguments() const {
    return raw_ptr()->type_arguments();
  }
  virtual void SetTypeArguments(const TypeArguments& value) const {
    // A GrowableObjectArray is raw or takes one type argument. However, its
    // type argument vector may be longer than 1 due to a type optimization
    // reusing the type argument vector of the instantiator.
    ASSERT(value.IsNull() || ((value.Length() >= 1) && value.IsInstantiated() &&
                              value.IsCanonical()));
    raw_ptr()->set_type_arguments(value.raw());
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
    return OFFSET_OF(GrowableObjectArrayLayout, type_arguments_);
  }

  static intptr_t length_offset() {
    return OFFSET_OF(GrowableObjectArrayLayout, length_);
  }
  static intptr_t data_offset() {
    return OFFSET_OF(GrowableObjectArrayLayout, data_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(GrowableObjectArrayLayout));
  }

  static GrowableObjectArrayPtr New(Heap::Space space = Heap::kNew) {
    return New(kDefaultInitialCapacity, space);
  }
  static GrowableObjectArrayPtr New(intptr_t capacity,
                                    Heap::Space space = Heap::kNew);
  static GrowableObjectArrayPtr New(const Array& array,
                                    Heap::Space space = Heap::kNew);

  static SmiPtr NoSafepointLength(const GrowableObjectArrayPtr array) {
    return array->ptr()->length();
  }

  static ArrayPtr NoSafepointData(const GrowableObjectArrayPtr array) {
    return array->ptr()->data();
  }

 private:
  ArrayLayout* DataArray() const { return data()->ptr(); }

  static const int kDefaultInitialCapacity = 0;

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
    return RoundedAllocationSize(sizeof(Float32x4Layout));
  }

  static intptr_t value_offset() { return OFFSET_OF(Float32x4Layout, value_); }

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
    return RoundedAllocationSize(sizeof(Int32x4Layout));
  }

  static intptr_t value_offset() { return OFFSET_OF(Int32x4Layout, value_); }

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
    return RoundedAllocationSize(sizeof(Float64x2Layout));
  }

  static intptr_t value_offset() { return OFFSET_OF(Float64x2Layout, value_); }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Float64x2, Instance);
  friend class Class;
};

class PointerBase : public Instance {
 public:
  static intptr_t data_field_offset() {
    return OFFSET_OF(PointerBaseLayout, data_);
  }
};

class TypedDataBase : public PointerBase {
 public:
  static intptr_t length_offset() {
    return OFFSET_OF(TypedDataBaseLayout, length_);
  }

  SmiPtr length() const { return raw_ptr()->length(); }

  intptr_t Length() const {
    ASSERT(!IsNull());
    return Smi::Value(raw_ptr()->length());
  }

  intptr_t LengthInBytes() const {
    return ElementSizeInBytes(raw()->GetClassId()) * Length();
  }

  TypedDataElementType ElementType() const {
    return ElementType(raw()->GetClassId());
  }

  intptr_t ElementSizeInBytes() const {
    return element_size(ElementType(raw()->GetClassId()));
  }

  static intptr_t ElementSizeInBytes(classid_t cid) {
    return element_size(ElementType(cid));
  }

  static TypedDataElementType ElementType(classid_t cid) {
    if (cid == kByteDataViewCid) {
      return kUint8ArrayElement;
    } else if (IsTypedDataClassId(cid)) {
      const intptr_t index =
          (cid - kTypedDataInt8ArrayCid - kTypedDataCidRemainderInternal) / 3;
      return static_cast<TypedDataElementType>(index);
    } else if (IsTypedDataViewClassId(cid)) {
      const intptr_t index =
          (cid - kTypedDataInt8ArrayCid - kTypedDataCidRemainderView) / 3;
      return static_cast<TypedDataElementType>(index);
    } else {
      ASSERT(IsExternalTypedDataClassId(cid));
      const intptr_t index =
          (cid - kTypedDataInt8ArrayCid - kTypedDataCidRemainderExternal) / 3;
      return static_cast<TypedDataElementType>(index);
    }
  }

  void* DataAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset == 0) ||
           ((byte_offset > 0) && (byte_offset < LengthInBytes())));
    return reinterpret_cast<void*>(Validate(raw_ptr()->data_) + byte_offset);
  }

 protected:
  void SetLength(intptr_t value) const {
    ASSERT(value <= Smi::kMaxValue);
    raw_ptr()->set_length(Smi::New(value));
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
  static const intptr_t kNumElementSizes =
      (kTypedDataFloat64x2ArrayCid - kTypedDataInt8ArrayCid) / 3 + 1;
  static const intptr_t element_size_table[kNumElementSizes];

  HEAP_OBJECT_IMPLEMENTATION(TypedDataBase, PointerBase);
};

class TypedData : public TypedDataBase {
 public:
  // We use 30 bits for the hash code so hashes in a snapshot taken on a
  // 64-bit architecture stay in Smi range when loaded on a 32-bit
  // architecture.
  static const intptr_t kHashBits = 30;

  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const;

#define TYPED_GETTER_SETTER(name, type)                                        \
  type Get##name(intptr_t byte_offset) const {                                 \
    ASSERT((byte_offset >= 0) &&                                               \
           (byte_offset + static_cast<intptr_t>(sizeof(type)) - 1) <           \
               LengthInBytes());                                               \
    return LoadUnaligned(ReadOnlyDataAddr<type>(byte_offset));                 \
  }                                                                            \
  void Set##name(intptr_t byte_offset, type value) const {                     \
    NoSafepointScope no_safepoint;                                             \
    StoreUnaligned(reinterpret_cast<type*>(DataAddr(byte_offset)), value);     \
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

  static intptr_t data_offset() { return TypedDataLayout::payload_offset(); }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(TypedDataLayout) ==
           OFFSET_OF_RETURNED_VALUE(TypedDataLayout, internal_data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t lengthInBytes) {
    ASSERT(0 <= lengthInBytes && lengthInBytes <= kSmiMax);
    return RoundedAllocationSize(sizeof(TypedDataLayout) + lengthInBytes);
  }

  static intptr_t MaxElements(intptr_t class_id) {
    ASSERT(IsTypedDataClassId(class_id));
    return (kSmiMax / ElementSizeInBytes(class_id));
  }

  static intptr_t MaxNewSpaceElements(intptr_t class_id) {
    ASSERT(IsTypedDataClassId(class_id));
    return (Heap::kNewAllocatableSize - sizeof(TypedDataLayout)) /
           ElementSizeInBytes(class_id);
  }

  static TypedDataPtr New(intptr_t class_id,
                          intptr_t len,
                          Heap::Space space = Heap::kNew);

  template <typename DstType, typename SrcType>
  static void Copy(const DstType& dst,
                   intptr_t dst_offset_in_bytes,
                   const SrcType& src,
                   intptr_t src_offset_in_bytes,
                   intptr_t length_in_bytes) {
    ASSERT(Utils::RangeCheck(src_offset_in_bytes, length_in_bytes,
                             src.LengthInBytes()));
    ASSERT(Utils::RangeCheck(dst_offset_in_bytes, length_in_bytes,
                             dst.LengthInBytes()));
    {
      NoSafepointScope no_safepoint;
      if (length_in_bytes > 0) {
        memmove(dst.DataAddr(dst_offset_in_bytes),
                src.DataAddr(src_offset_in_bytes), length_in_bytes);
      }
    }
  }

  template <typename DstType, typename SrcType>
  static void ClampedCopy(const DstType& dst,
                          intptr_t dst_offset_in_bytes,
                          const SrcType& src,
                          intptr_t src_offset_in_bytes,
                          intptr_t length_in_bytes) {
    ASSERT(Utils::RangeCheck(src_offset_in_bytes, length_in_bytes,
                             src.LengthInBytes()));
    ASSERT(Utils::RangeCheck(dst_offset_in_bytes, length_in_bytes,
                             dst.LengthInBytes()));
    {
      NoSafepointScope no_safepoint;
      if (length_in_bytes > 0) {
        uint8_t* dst_data =
            reinterpret_cast<uint8_t*>(dst.DataAddr(dst_offset_in_bytes));
        int8_t* src_data =
            reinterpret_cast<int8_t*>(src.DataAddr(src_offset_in_bytes));
        for (intptr_t ix = 0; ix < length_in_bytes; ix++) {
          int8_t v = *src_data;
          if (v < 0) v = 0;
          *dst_data = v;
          src_data++;
          dst_data++;
        }
      }
    }
  }

  static bool IsTypedData(const Instance& obj) {
    ASSERT(!obj.IsNull());
    intptr_t cid = obj.raw()->GetClassId();
    return IsTypedDataClassId(cid);
  }

 protected:
  void RecomputeDataField() { raw()->ptr()->RecomputeDataField(); }

 private:
  // Provides const access to non-pointer, non-aligned data within the object.
  // Such access does not need a write barrier, but it is *not* GC-safe, since
  // the object might move.
  //
  // Therefore this method is private and the call-sites in this class need to
  // ensure the returned pointer does not escape.
  template <typename FieldType>
  const FieldType* ReadOnlyDataAddr(intptr_t byte_offset) const {
    return reinterpret_cast<const FieldType*>((raw_ptr()->data()) +
                                              byte_offset);
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
  static const int kDataSerializationAlignment = 8;

#define TYPED_GETTER_SETTER(name, type)                                        \
  type Get##name(intptr_t byte_offset) const {                                 \
    return LoadUnaligned(reinterpret_cast<type*>(DataAddr(byte_offset)));      \
  }                                                                            \
  void Set##name(intptr_t byte_offset, type value) const {                     \
    StoreUnaligned(reinterpret_cast<type*>(DataAddr(byte_offset)), value);     \
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

  FinalizablePersistentHandle* AddFinalizer(void* peer,
                                            Dart_HandleFinalizer callback,
                                            intptr_t external_size) const;

  static intptr_t data_offset() {
    return OFFSET_OF(ExternalTypedDataLayout, data_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(ExternalTypedDataLayout));
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
    intptr_t cid = obj.raw()->GetClassId();
    return IsExternalTypedDataClassId(cid);
  }

 protected:
  virtual uint8_t* Validate(uint8_t* data) const { return data; }

  void SetLength(intptr_t value) const {
    ASSERT(value <= Smi::kMaxValue);
    raw_ptr()->set_length(Smi::New(value));
  }

  void SetData(uint8_t* data) const {
    ASSERT(
        !Isolate::Current()->heap()->Contains(reinterpret_cast<uword>(data)));
    StoreNonPointer(&raw_ptr()->data_, data);
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
    return RoundedAllocationSize(sizeof(TypedDataViewLayout));
  }

  static InstancePtr Data(const TypedDataView& view) {
    return view.typed_data();
  }

  static SmiPtr OffsetInBytes(const TypedDataView& view) {
    return view.offset_in_bytes();
  }

  static bool IsExternalTypedDataView(const TypedDataView& view_obj) {
    const auto& data = Instance::Handle(Data(view_obj));
    intptr_t cid = data.raw()->GetClassId();
    ASSERT(IsTypedDataClassId(cid) || IsExternalTypedDataClassId(cid));
    return IsExternalTypedDataClassId(cid);
  }

  static intptr_t data_offset() {
    return OFFSET_OF(TypedDataViewLayout, typed_data_);
  }

  static intptr_t offset_in_bytes_offset() {
    return OFFSET_OF(TypedDataViewLayout, offset_in_bytes_);
  }

  InstancePtr typed_data() const { return raw_ptr()->typed_data(); }

  void InitializeWith(const TypedDataBase& typed_data,
                      intptr_t offset_in_bytes,
                      intptr_t length) {
    const classid_t cid = typed_data.GetClassId();
    ASSERT(IsTypedDataClassId(cid) || IsExternalTypedDataClassId(cid));
    raw_ptr()->set_typed_data(typed_data.raw());
    raw_ptr()->set_length(Smi::New(length));
    raw_ptr()->set_offset_in_bytes(Smi::New(offset_in_bytes));

    // Update the inner pointer.
    RecomputeDataField();
  }

  SmiPtr offset_in_bytes() const { return raw_ptr()->offset_in_bytes(); }

 protected:
  virtual uint8_t* Validate(uint8_t* data) const { return data; }

 private:
  void RecomputeDataField() { raw()->ptr()->RecomputeDataField(); }

  void Clear() {
    raw_ptr()->set_length(Smi::New(0));
    raw_ptr()->set_offset_in_bytes(Smi::New(0));
    StoreNonPointer(&raw_ptr()->data_, nullptr);
    raw_ptr()->set_typed_data(TypedDataBase::RawCast(Object::null()));
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypedDataView, TypedDataBase);
  friend class Class;
  friend class Object;
  friend class TypedDataViewDeserializationCluster;
};

class ByteBuffer : public AllStatic {
 public:
  static InstancePtr Data(const Instance& view_obj) {
    ASSERT(!view_obj.IsNull());
    return *reinterpret_cast<InstancePtr const*>(view_obj.raw_ptr() +
                                                 kDataOffset);
  }

  static intptr_t NumberOfFields() { return kDataOffset; }

  static intptr_t data_offset() { return kWordSize * kDataOffset; }

 private:
  enum {
    kDataOffset = 1,
  };
};

class Pointer : public Instance {
 public:
  static PointerPtr New(const AbstractType& type_arg,
                        uword native_address,
                        Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(PointerLayout));
  }

  static bool IsPointer(const Instance& obj);

  size_t NativeAddress() const {
    return reinterpret_cast<size_t>(raw_ptr()->data_);
  }

  void SetNativeAddress(size_t address) const {
    uint8_t* value = reinterpret_cast<uint8_t*>(address);
    StoreNonPointer(&raw_ptr()->data_, value);
  }

  static intptr_t type_arguments_offset() {
    return OFFSET_OF(PointerLayout, type_arguments_);
  }

  static intptr_t NextFieldOffset() { return sizeof(PointerLayout); }

  static const intptr_t kNativeTypeArgPos = 0;

  // Fetches the NativeType type argument.
  AbstractTypePtr type_argument() const {
    TypeArguments& type_args = TypeArguments::Handle(GetTypeArguments());
    return type_args.TypeAtNullSafe(Pointer::kNativeTypeArgPos);
  }

 private:
  HEAP_OBJECT_IMPLEMENTATION(Pointer, Instance);

  friend class Class;
};

class DynamicLibrary : public Instance {
 public:
  static DynamicLibraryPtr New(void* handle, Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(DynamicLibraryLayout));
  }

  static bool IsDynamicLibrary(const Instance& obj) {
    ASSERT(!obj.IsNull());
    intptr_t cid = obj.raw()->GetClassId();
    return IsFfiDynamicLibraryClassId(cid);
  }

  void* GetHandle() const {
    ASSERT(!IsNull());
    return raw_ptr()->handle_;
  }

  void SetHandle(void* value) const {
    StoreNonPointer(&raw_ptr()->handle_, value);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(DynamicLibrary, Instance);

  friend class Class;
};

// Corresponds to
// - "new Map()",
// - non-const map literals, and
// - the default constructor of LinkedHashMap in dart:collection.
class LinkedHashMap : public Instance {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(LinkedHashMapLayout));
  }

  // Allocates a map with some default capacity, just like "new Map()".
  static LinkedHashMapPtr NewDefault(Heap::Space space = Heap::kNew);
  static LinkedHashMapPtr New(const Array& data,
                              const TypedData& index,
                              intptr_t hash_mask,
                              intptr_t used_data,
                              intptr_t deleted_keys,
                              Heap::Space space = Heap::kNew);

  virtual TypeArgumentsPtr GetTypeArguments() const {
    return raw_ptr()->type_arguments();
  }
  virtual void SetTypeArguments(const TypeArguments& value) const {
    ASSERT(value.IsNull() ||
           ((value.Length() >= 2) &&
            value.IsInstantiated() /*&& value.IsCanonical()*/));
    // TODO(asiva): Values read from a message snapshot are not properly marked
    // as canonical. See for example tests/isolate/message3_test.dart.
    raw_ptr()->set_type_arguments(value.raw());
  }
  static intptr_t type_arguments_offset() {
    return OFFSET_OF(LinkedHashMapLayout, type_arguments_);
  }

  TypedDataPtr index() const { return raw_ptr()->index(); }
  void SetIndex(const TypedData& value) const {
    ASSERT(!value.IsNull());
    raw_ptr()->set_index(value.raw());
  }
  static intptr_t index_offset() {
    return OFFSET_OF(LinkedHashMapLayout, index_);
  }

  ArrayPtr data() const { return raw_ptr()->data(); }
  void SetData(const Array& value) const { raw_ptr()->set_data(value.raw()); }
  static intptr_t data_offset() {
    return OFFSET_OF(LinkedHashMapLayout, data_);
  }

  SmiPtr hash_mask() const { return raw_ptr()->hash_mask(); }
  void SetHashMask(intptr_t value) const {
    raw_ptr()->set_hash_mask(Smi::New(value));
  }
  static intptr_t hash_mask_offset() {
    return OFFSET_OF(LinkedHashMapLayout, hash_mask_);
  }

  SmiPtr used_data() const { return raw_ptr()->used_data(); }
  void SetUsedData(intptr_t value) const {
    raw_ptr()->set_used_data(Smi::New(value));
  }
  static intptr_t used_data_offset() {
    return OFFSET_OF(LinkedHashMapLayout, used_data_);
  }

  SmiPtr deleted_keys() const { return raw_ptr()->deleted_keys(); }
  void SetDeletedKeys(intptr_t value) const {
    raw_ptr()->set_deleted_keys(Smi::New(value));
  }
  static intptr_t deleted_keys_offset() {
    return OFFSET_OF(LinkedHashMapLayout, deleted_keys_);
  }

  intptr_t Length() const {
    // The map may be uninitialized.
    if (raw_ptr()->used_data() == Object::null()) return 0;
    if (raw_ptr()->deleted_keys() == Object::null()) return 0;

    intptr_t used = Smi::Value(raw_ptr()->used_data());
    intptr_t deleted = Smi::Value(raw_ptr()->deleted_keys());
    return (used >> 1) - deleted;
  }

  // This iterator differs somewhat from its Dart counterpart (_CompactIterator
  // in runtime/lib/compact_hash.dart):
  //  - There are no checks for concurrent modifications.
  //  - Accessing a key or value before the first call to MoveNext and after
  //    MoveNext returns false will result in crashes.
  class Iterator : ValueObject {
   public:
    explicit Iterator(const LinkedHashMap& map)
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
        if (scratch_.raw() != data_.raw()) {
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
  FINAL_HEAP_OBJECT_IMPLEMENTATION(LinkedHashMap, Instance);

  // Keep this in sync with Dart implementation (lib/compact_hash.dart).
  static const intptr_t kInitialIndexBits = 3;
  static const intptr_t kInitialIndexSize = 1 << (kInitialIndexBits + 1);

  // Allocate a map, but leave all fields set to null.
  // Used during deserialization (since map might contain itself as key/value).
  static LinkedHashMapPtr NewUninitialized(Heap::Space space = Heap::kNew);

  friend class Class;
  friend class LinkedHashMapDeserializationCluster;
};

class Closure : public Instance {
 public:
  TypeArgumentsPtr instantiator_type_arguments() const {
    return raw_ptr()->instantiator_type_arguments();
  }
  void set_instantiator_type_arguments(const TypeArguments& args) const {
    raw_ptr()->set_instantiator_type_arguments(args.raw());
  }
  static intptr_t instantiator_type_arguments_offset() {
    return OFFSET_OF(ClosureLayout, instantiator_type_arguments_);
  }

  TypeArgumentsPtr function_type_arguments() const {
    return raw_ptr()->function_type_arguments();
  }
  void set_function_type_arguments(const TypeArguments& args) const {
    raw_ptr()->set_function_type_arguments(args.raw());
  }
  static intptr_t function_type_arguments_offset() {
    return OFFSET_OF(ClosureLayout, function_type_arguments_);
  }

  TypeArgumentsPtr delayed_type_arguments() const {
    return raw_ptr()->delayed_type_arguments();
  }
  void set_delayed_type_arguments(const TypeArguments& args) const {
    raw_ptr()->set_delayed_type_arguments(args.raw());
  }
  static intptr_t delayed_type_arguments_offset() {
    return OFFSET_OF(ClosureLayout, delayed_type_arguments_);
  }

  FunctionPtr function() const { return raw_ptr()->function(); }
  static intptr_t function_offset() {
    return OFFSET_OF(ClosureLayout, function_);
  }

  ContextPtr context() const { return raw_ptr()->context(); }
  static intptr_t context_offset() {
    return OFFSET_OF(ClosureLayout, context_);
  }

  bool IsGeneric(Thread* thread) const { return NumTypeParameters(thread) > 0; }
  intptr_t NumTypeParameters(Thread* thread) const;
  // No need for NumParentTypeParameters, as a closure is always closed over
  // its parents type parameters (i.e., function_type_parameters() above).

  SmiPtr hash() const { return raw_ptr()->hash(); }
  static intptr_t hash_offset() { return OFFSET_OF(ClosureLayout, hash_); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(ClosureLayout));
  }

  virtual void CanonicalizeFieldsLocked(Thread* thread) const;
  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uint32_t CanonicalizeHash() const {
    return Function::Handle(function()).Hash();
  }
  int64_t ComputeHash() const;

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

  FunctionPtr GetInstantiatedSignature(Zone* zone) const;

 private:
  static ClosurePtr New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Closure, Instance);
  friend class Class;
};

class Capability : public Instance {
 public:
  uint64_t Id() const { return raw_ptr()->id_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(CapabilityLayout));
  }
  static CapabilityPtr New(uint64_t id, Heap::Space space = Heap::kNew);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Capability, Instance);
  friend class Class;
};

class ReceivePort : public Instance {
 public:
  SendPortPtr send_port() const { return raw_ptr()->send_port(); }
  Dart_Port Id() const { return send_port()->ptr()->id_; }

  InstancePtr handler() const { return raw_ptr()->handler(); }
  void set_handler(const Instance& value) const;

#if !defined(PRODUCT)
  StackTracePtr allocation_location() const {
    return raw_ptr()->allocation_location();
  }

  StringPtr debug_name() const { return raw_ptr()->debug_name(); }
#endif

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(ReceivePortLayout));
  }
  static ReceivePortPtr New(Dart_Port id,
                            const String& debug_name,
                            bool is_control_port,
                            Heap::Space space = Heap::kNew);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(ReceivePort, Instance);
  friend class Class;
};

class SendPort : public Instance {
 public:
  Dart_Port Id() const { return raw_ptr()->id_; }

  Dart_Port origin_id() const { return raw_ptr()->origin_id_; }
  void set_origin_id(Dart_Port id) const {
    ASSERT(origin_id() == 0);
    StoreNonPointer(&(raw_ptr()->origin_id_), id);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(SendPortLayout));
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
  static TransferableTypedDataPtr New(uint8_t* data,
                                      intptr_t len,
                                      Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(TransferableTypedDataLayout));
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(TransferableTypedData, Instance);
  friend class Class;
};

// Internal stacktrace object used in exceptions for printing stack traces.
class StackTrace : public Instance {
 public:
  static const int kPreallocatedStackdepth = 90;

  intptr_t Length() const;

  StackTracePtr async_link() const { return raw_ptr()->async_link(); }
  void set_async_link(const StackTrace& async_link) const;
  void set_expand_inlined(bool value) const;

  ArrayPtr code_array() const { return raw_ptr()->code_array(); }
  ObjectPtr CodeAtFrame(intptr_t frame_index) const;
  void SetCodeAtFrame(intptr_t frame_index, const Object& code) const;

  ArrayPtr pc_offset_array() const { return raw_ptr()->pc_offset_array(); }
  SmiPtr PcOffsetAtFrame(intptr_t frame_index) const;
  void SetPcOffsetAtFrame(intptr_t frame_index, const Smi& pc_offset) const;

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
    return RoundedAllocationSize(sizeof(StackTraceLayout));
  }
  static StackTracePtr New(const Array& code_array,
                           const Array& pc_offset_array,
                           Heap::Space space = Heap::kNew);

  static StackTracePtr New(const Array& code_array,
                           const Array& pc_offset_array,
                           const StackTrace& async_link,
                           bool skip_sync_start_in_parent_stack,
                           Heap::Space space = Heap::kNew);

 private:
  void set_code_array(const Array& code_array) const;
  void set_pc_offset_array(const Array& pc_offset_array) const;
  bool expand_inlined() const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(StackTrace, Instance);
  friend class Class;
  friend class Debugger;
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

  static const int kDefaultFlags = 0;

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

  bool operator==(const RegExpFlags& other) { return value_ == other.value_; }
  bool operator!=(const RegExpFlags& other) { return value_ != other.value_; }

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
  class FlagsBits : public BitField<int8_t, intptr_t, kFlagsPos, kFlagsSize> {};

  bool is_initialized() const { return (type() != kUninitialized); }
  bool is_simple() const { return (type() == kSimple); }
  bool is_complex() const { return (type() == kComplex); }

  intptr_t num_registers(bool is_one_byte) const {
    return is_one_byte ? raw_ptr()->num_one_byte_registers_
                       : raw_ptr()->num_two_byte_registers_;
  }

  StringPtr pattern() const { return raw_ptr()->pattern(); }
  SmiPtr num_bracket_expressions() const {
    return raw_ptr()->num_bracket_expressions();
  }
  ArrayPtr capture_name_map() const { return raw_ptr()->capture_name_map(); }

  TypedDataPtr bytecode(bool is_one_byte, bool sticky) const {
    if (sticky) {
      return TypedData::RawCast(is_one_byte ? raw_ptr()->one_byte_sticky_
                                            : raw_ptr()->two_byte_sticky_);
    } else {
      return TypedData::RawCast(is_one_byte ? raw_ptr()->one_byte_
                                            : raw_ptr()->two_byte_);
    }
  }

  static intptr_t function_offset(intptr_t cid, bool sticky) {
    if (sticky) {
      switch (cid) {
        case kOneByteStringCid:
          return OFFSET_OF(RegExpLayout, one_byte_sticky_);
        case kTwoByteStringCid:
          return OFFSET_OF(RegExpLayout, two_byte_sticky_);
        case kExternalOneByteStringCid:
          return OFFSET_OF(RegExpLayout, external_one_byte_sticky_);
        case kExternalTwoByteStringCid:
          return OFFSET_OF(RegExpLayout, external_two_byte_sticky_);
      }
    } else {
      switch (cid) {
        case kOneByteStringCid:
          return OFFSET_OF(RegExpLayout, one_byte_);
        case kTwoByteStringCid:
          return OFFSET_OF(RegExpLayout, two_byte_);
        case kExternalOneByteStringCid:
          return OFFSET_OF(RegExpLayout, external_one_byte_);
        case kExternalTwoByteStringCid:
          return OFFSET_OF(RegExpLayout, external_two_byte_);
      }
    }

    UNREACHABLE();
    return -1;
  }

  FunctionPtr* FunctionAddr(intptr_t cid, bool sticky) const {
    return reinterpret_cast<FunctionPtr*>(
        FieldAddrAtOffset(function_offset(cid, sticky)));
  }

  FunctionPtr function(intptr_t cid, bool sticky) const {
    return *FunctionAddr(cid, sticky);
  }

  void set_pattern(const String& pattern) const;
  void set_function(intptr_t cid, bool sticky, const Function& value) const;
  void set_bytecode(bool is_one_byte,
                    bool sticky,
                    const TypedData& bytecode) const;

  void set_num_bracket_expressions(intptr_t value) const;
  void set_capture_name_map(const Array& array) const;
  void set_is_global() const {
    RegExpFlags f = flags();
    f.SetGlobal();
    set_flags(f);
  }
  void set_is_ignore_case() const {
    RegExpFlags f = flags();
    f.SetIgnoreCase();
    set_flags(f);
  }
  void set_is_multi_line() const {
    RegExpFlags f = flags();
    f.SetMultiLine();
    set_flags(f);
  }
  void set_is_unicode() const {
    RegExpFlags f = flags();
    f.SetUnicode();
    set_flags(f);
  }
  void set_is_dot_all() const {
    RegExpFlags f = flags();
    f.SetDotAll();
    set_flags(f);
  }
  void set_is_simple() const { set_type(kSimple); }
  void set_is_complex() const { set_type(kComplex); }
  void set_num_registers(bool is_one_byte, intptr_t value) const {
    if (is_one_byte) {
      StoreNonPointer(&raw_ptr()->num_one_byte_registers_, value);
    } else {
      StoreNonPointer(&raw_ptr()->num_two_byte_registers_, value);
    }
  }

  RegExpFlags flags() const {
    return RegExpFlags(FlagsBits::decode(raw_ptr()->type_flags_));
  }
  void set_flags(RegExpFlags flags) const {
    StoreNonPointer(&raw_ptr()->type_flags_,
                    FlagsBits::update(flags.value(), raw_ptr()->type_flags_));
  }
  const char* Flags() const;

  virtual bool CanonicalizeEquals(const Instance& other) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RegExpLayout));
  }

  static RegExpPtr New(Heap::Space space = Heap::kNew);

 private:
  void set_type(RegExType type) const {
    StoreNonPointer(&raw_ptr()->type_flags_,
                    TypeBits::update(type, raw_ptr()->type_flags_));
  }

  RegExType type() const { return TypeBits::decode(raw_ptr()->type_flags_); }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(RegExp, Instance);
  friend class Class;
};

class WeakProperty : public Instance {
 public:
  ObjectPtr key() const { return raw_ptr()->key(); }
  void set_key(const Object& key) const { raw_ptr()->set_key(key.raw()); }
  static intptr_t key_offset() { return OFFSET_OF(WeakPropertyLayout, key_); }

  ObjectPtr value() const { return raw_ptr()->value(); }
  void set_value(const Object& value) const {
    raw_ptr()->set_value(value.raw());
  }
  static intptr_t value_offset() {
    return OFFSET_OF(WeakPropertyLayout, value_);
  }

  static WeakPropertyPtr New(Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(WeakPropertyLayout));
  }

  static void Clear(WeakPropertyPtr raw_weak) {
    ASSERT(raw_weak->ptr()->next_ == WeakProperty::null());
    // This action is performed by the GC. No barrier.
    raw_weak->ptr()->key_ = Object::null();
    raw_weak->ptr()->value_ = Object::null();
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(WeakProperty, Instance);
  friend class Class;
};

class MirrorReference : public Instance {
 public:
  ObjectPtr referent() const { return raw_ptr()->referent(); }

  void set_referent(const Object& referent) const {
    raw_ptr()->set_referent(referent.raw());
  }

  AbstractTypePtr GetAbstractTypeReferent() const;

  ClassPtr GetClassReferent() const;

  FieldPtr GetFieldReferent() const;

  FunctionPtr GetFunctionReferent() const;

  LibraryPtr GetLibraryReferent() const;

  TypeParameterPtr GetTypeParameterReferent() const;

  static MirrorReferencePtr New(const Object& referent,
                                Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(MirrorReferenceLayout));
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(MirrorReference, Instance);
  friend class Class;
};

class UserTag : public Instance {
 public:
  uword tag() const { return raw_ptr()->tag(); }
  void set_tag(uword t) const {
    ASSERT(t >= UserTags::kUserTagIdOffset);
    ASSERT(t < UserTags::kUserTagIdOffset + UserTags::kMaxUserTags);
    StoreNonPointer(&raw_ptr()->tag_, t);
  }
  static intptr_t tag_offset() { return OFFSET_OF(UserTagLayout, tag_); }

  StringPtr label() const { return raw_ptr()->label(); }

  void MakeActive() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(UserTagLayout));
  }

  static UserTagPtr New(const String& label, Heap::Space space = Heap::kOld);
  static UserTagPtr DefaultTag();

  static bool TagTableIsFull(Thread* thread);
  static UserTagPtr FindTagById(uword tag_id);

 private:
  static UserTagPtr FindTagInIsolate(Thread* thread, const String& label);
  static void AddTagToIsolate(Thread* thread, const UserTag& tag);

  void set_label(const String& tag_label) const {
    raw_ptr()->set_label(tag_label.raw());
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(UserTag, Instance);
  friend class Class;
};

// Represents abstract FutureOr class in dart:async.
class FutureOr : public Instance {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(FutureOrLayout));
  }

  virtual TypeArgumentsPtr GetTypeArguments() const {
    return raw_ptr()->type_arguments();
  }
  static intptr_t type_arguments_offset() {
    return OFFSET_OF(FutureOrLayout, type_arguments_);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(FutureOr, Instance);

  friend class Class;
};

// Breaking cycles and loops.
ClassPtr Object::clazz() const {
  uword raw_value = static_cast<uword>(raw_);
  if ((raw_value & kSmiTagMask) == kSmiTag) {
    return Smi::Class();
  }
  ASSERT(!IsolateGroup::Current()->compaction_in_progress());
  return Isolate::Current()->class_table()->At(raw()->GetClassId());
}

DART_FORCE_INLINE
void Object::SetRaw(ObjectPtr value) {
  NoSafepointScope no_safepoint_scope;
  raw_ = value;
  intptr_t cid = value->GetClassIdMayBeSmi();
  // Free-list elements cannot be wrapped in a handle.
  ASSERT(cid != kFreeListElement);
  ASSERT(cid != kForwardingCorpse);
  if (cid >= kNumPredefinedCids) {
    cid = kInstanceCid;
  }
  set_vtable(builtin_vtables_[cid]);
#if defined(DEBUG)
  if (FLAG_verify_handles && raw_->IsHeapObject()) {
    Isolate* isolate = Isolate::Current();
    Heap* isolate_heap = isolate->heap();
    // TODO(rmacnak): Remove after rewriting StackFrame::VisitObjectPointers
    // to not use handles.
    if (!isolate_heap->new_space()->scavenging()) {
      Heap* vm_isolate_heap = Dart::vm_isolate()->heap();
      uword addr = ObjectLayout::ToAddr(raw_);
      if (!isolate_heap->Contains(addr) && !vm_isolate_heap->Contains(addr)) {
        ASSERT(FLAG_write_protect_code);
        addr = ObjectLayout::ToAddr(OldPage::ToWritable(raw_));
        ASSERT(isolate_heap->Contains(addr) || vm_isolate_heap->Contains(addr));
      }
    }
  }
#endif
}

intptr_t Field::HostOffset() const {
  ASSERT(is_instance());  // Valid only for dart instance fields.
  return (Smi::Value(raw_ptr()->host_offset_or_field_id()) * kWordSize);
}

intptr_t Field::TargetOffset() const {
  ASSERT(is_instance());  // Valid only for dart instance fields.
#if !defined(DART_PRECOMPILED_RUNTIME)
  return (raw_ptr()->target_offset_ * compiler::target::kWordSize);
#else
  return HostOffset();
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
}

inline intptr_t Field::TargetOffsetOf(const FieldPtr field) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  return field->ptr()->target_offset_;
#else
  return Smi::Value(field->ptr()->host_offset_or_field_id_);
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
}

void Field::SetOffset(intptr_t host_offset_in_bytes,
                      intptr_t target_offset_in_bytes) const {
  ASSERT(is_instance());  // Valid only for dart instance fields.
  ASSERT(kWordSize != 0);
  raw_ptr()->set_host_offset_or_field_id(
      Smi::New(host_offset_in_bytes / kWordSize));
#if !defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(compiler::target::kWordSize != 0);
  StoreNonPointer(&raw_ptr()->target_offset_,
                  target_offset_in_bytes / compiler::target::kWordSize);
#else
  ASSERT(host_offset_in_bytes == target_offset_in_bytes);
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
}

InstancePtr Field::StaticValue() const {
  ASSERT(is_static());  // Valid only for static dart fields.
  return Isolate::Current()->field_table()->At(
      Smi::Value(raw_ptr()->host_offset_or_field_id()));
}

inline intptr_t Field::field_id() const {
  return Smi::Value(raw_ptr()->host_offset_or_field_id());
}

void Field::set_field_id(intptr_t field_id) const {
  ASSERT(is_static());
  ASSERT(Thread::Current()->IsMutatorThread());
  raw_ptr()->set_host_offset_or_field_id(Smi::New(field_id));
}

void Context::SetAt(intptr_t index, const Object& value) const {
  raw_ptr()->set_element(index, value.raw());
}

intptr_t Instance::GetNativeField(int index) const {
  ASSERT(IsValidNativeIndex(index));
  NoSafepointScope no_safepoint;
  TypedDataPtr native_fields = static_cast<TypedDataPtr>(*NativeFieldsAddr());
  if (native_fields == TypedData::null()) {
    return 0;
  }
  return reinterpret_cast<intptr_t*>(native_fields->ptr()->data())[index];
}

void Instance::GetNativeFields(uint16_t num_fields,
                               intptr_t* field_values) const {
  NoSafepointScope no_safepoint;
  ASSERT(num_fields == NumNativeFields());
  ASSERT(field_values != NULL);
  TypedDataPtr native_fields = static_cast<TypedDataPtr>(*NativeFieldsAddr());
  if (native_fields == TypedData::null()) {
    for (intptr_t i = 0; i < num_fields; i++) {
      field_values[i] = 0;
    }
  }
  intptr_t* fields = reinterpret_cast<intptr_t*>(native_fields->ptr()->data());
  for (intptr_t i = 0; i < num_fields; i++) {
    field_values[i] = fields[i];
  }
}

bool String::Equals(const String& str) const {
  if (raw() == str.raw()) {
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
#if defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    if (target.IsFunction()) {
      const auto& function = Function::Cast(target);
      const auto& entry_point = Smi::Handle(
          Smi::FromAlignedAddress(Code::EntryPointOf(function.CurrentCode())));
      array.SetAt((index * kEntryLength) + kTargetFunctionIndex, entry_point);
      return;
    }
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
  array.SetAt((index * kEntryLength) + kTargetFunctionIndex, target);
}

ObjectPtr MegamorphicCache::GetClassId(const Array& array, intptr_t index) {
  return array.At((index * kEntryLength) + kClassIdIndex);
}

ObjectPtr MegamorphicCache::GetTargetFunction(const Array& array,
                                              intptr_t index) {
  return array.At((index * kEntryLength) + kTargetFunctionIndex);
}

inline intptr_t Type::Hash() const {
  intptr_t result = Smi::Value(raw_ptr()->hash());
  if (result != 0) {
    return result;
  }
  return ComputeHash();
}

inline void Type::SetHash(intptr_t value) const {
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  raw_ptr()->set_hash(Smi::New(value));
}

inline intptr_t TypeParameter::Hash() const {
  ASSERT(IsFinalized());
  intptr_t result = Smi::Value(raw_ptr()->hash());
  if (result != 0) {
    return result;
  }
  return ComputeHash();
}

inline void TypeParameter::SetHash(intptr_t value) const {
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  raw_ptr()->set_hash(Smi::New(value));
}

inline intptr_t TypeArguments::Hash() const {
  if (IsNull()) return kAllDynamicHash;
  intptr_t result = Smi::Value(raw_ptr()->hash());
  if (result != 0) {
    return result;
  }
  return ComputeHash();
}

inline void TypeArguments::SetHash(intptr_t value) const {
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  raw_ptr()->set_hash(Smi::New(value));
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
//     using CallTableView = ArrayOfTuplesVied<
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

  explicit ArrayOfTuplesView(const Array& array) : array_(array), index_(-1) {
    ASSERT(!array.IsNull());
    ASSERT(array.Length() >= kStartOffset);
    ASSERT((array.Length() - kStartOffset) % EntrySize == kStartOffset);
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
  intptr_t index_;
};

using InvocationDispatcherTable =
    ArrayOfTuplesView<Class::InvocationDispatcherEntry,
                      std::tuple<String, Array, Function>>;

using StaticCallsTable =
    ArrayOfTuplesView<Code::SCallTableEntry, std::tuple<Smi, Object, Function>>;

using StaticCallsTableEntry = StaticCallsTable::TupleView;

using SubtypeTestCacheTable = ArrayOfTuplesView<SubtypeTestCache::Entries,
                                                std::tuple<Object,
                                                           Object,
                                                           AbstractType,
                                                           TypeArguments,
                                                           TypeArguments,
                                                           TypeArguments,
                                                           TypeArguments,
                                                           TypeArguments>>;

using MegamorphicCacheEntries =
    ArrayOfTuplesView<MegamorphicCache::EntryType, std::tuple<Smi, Object>>;

void DumpTypeTable(Isolate* isolate);
void DumpTypeParameterTable(Isolate* isolate);
void DumpTypeArgumentsTable(Isolate* isolate);

EntryPointPragma FindEntryPointPragma(Isolate* I,
                                      const Array& metadata,
                                      Field* reusable_field_handle,
                                      Object* reusable_object_handle);

DART_WARN_UNUSED_RESULT
ErrorPtr EntryPointFieldInvocationError(const String& getter_name);

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_H_
