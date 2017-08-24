// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OBJECT_H_
#define RUNTIME_VM_OBJECT_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/bitmap.h"
#include "vm/dart.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/handles.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/method_recognizer.h"
#include "vm/os.h"
#include "vm/raw_object.h"
#include "vm/report.h"
#include "vm/scanner.h"
#include "vm/tags.h"
#include "vm/thread.h"
#include "vm/token_position.h"

namespace dart {

// Forward declarations.
namespace kernel {
class Program;
class TreeNode;
}  // namespace kernel

#define DEFINE_FORWARD_DECLARATION(clazz) class clazz;
CLASS_LIST(DEFINE_FORWARD_DECLARATION)
#undef DEFINE_FORWARD_DECLARATION
class Api;
class ArgumentsDescriptor;
class Assembler;
class Closure;
class Code;
class DisassemblyFormatter;
class DeoptInstr;
class FinalizablePersistentHandle;
class LocalScope;

#define REUSABLE_FORWARD_DECLARATION(name) class Reusable##name##HandleScope;
REUSABLE_HANDLE_LIST(REUSABLE_FORWARD_DECLARATION)
#undef REUSABLE_FORWARD_DECLARATION

class Symbols;

#if defined(DEBUG)
#define CHECK_HANDLE() CheckHandle();
#else
#define CHECK_HANDLE()
#endif

#define BASE_OBJECT_IMPLEMENTATION(object, super)                              \
 public: /* NOLINT */                                                          \
  Raw##object* raw() const { return reinterpret_cast<Raw##object*>(raw_); }    \
  bool Is##object() const { return true; }                                     \
  static object& Handle(Zone* zone, Raw##object* raw_ptr) {                    \
    object* obj = reinterpret_cast<object*>(VMHandles::AllocateHandle(zone));  \
    initializeHandle(obj, raw_ptr);                                            \
    return *obj;                                                               \
  }                                                                            \
  static object& Handle() {                                                    \
    return Handle(Thread::Current()->zone(), object::null());                  \
  }                                                                            \
  static object& Handle(Zone* zone) { return Handle(zone, object::null()); }   \
  static object& Handle(Raw##object* raw_ptr) {                                \
    return Handle(Thread::Current()->zone(), raw_ptr);                         \
  }                                                                            \
  static object& CheckedHandle(Zone* zone, RawObject* raw_ptr) {               \
    object* obj = reinterpret_cast<object*>(VMHandles::AllocateHandle(zone));  \
    initializeHandle(obj, raw_ptr);                                            \
    if (!obj->Is##object()) {                                                  \
      FATAL2("Handle check failed: saw %s expected %s", obj->ToCString(),      \
             #object);                                                         \
    }                                                                          \
    return *obj;                                                               \
  }                                                                            \
  static object& CheckedHandle(RawObject* raw_ptr) {                           \
    return CheckedHandle(Thread::Current()->zone(), raw_ptr);                  \
  }                                                                            \
  static object& ZoneHandle(Zone* zone, Raw##object* raw_ptr) {                \
    object* obj =                                                              \
        reinterpret_cast<object*>(VMHandles::AllocateZoneHandle(zone));        \
    initializeHandle(obj, raw_ptr);                                            \
    return *obj;                                                               \
  }                                                                            \
  static object* ReadOnlyHandle() {                                            \
    object* obj = reinterpret_cast<object*>(Dart::AllocateReadOnlyHandle());   \
    initializeHandle(obj, object::null());                                     \
    return obj;                                                                \
  }                                                                            \
  static object& ZoneHandle(Zone* zone) {                                      \
    return ZoneHandle(zone, object::null());                                   \
  }                                                                            \
  static object& ZoneHandle() {                                                \
    return ZoneHandle(Thread::Current()->zone(), object::null());              \
  }                                                                            \
  static object& ZoneHandle(Raw##object* raw_ptr) {                            \
    return ZoneHandle(Thread::Current()->zone(), raw_ptr);                     \
  }                                                                            \
  static object& CheckedZoneHandle(Zone* zone, RawObject* raw_ptr) {           \
    object* obj =                                                              \
        reinterpret_cast<object*>(VMHandles::AllocateZoneHandle(zone));        \
    initializeHandle(obj, raw_ptr);                                            \
    if (!obj->Is##object()) {                                                  \
      FATAL2("Handle check failed: saw %s expected %s", obj->ToCString(),      \
             #object);                                                         \
    }                                                                          \
    return *obj;                                                               \
  }                                                                            \
  static object& CheckedZoneHandle(RawObject* raw_ptr) {                       \
    return CheckedZoneHandle(Thread::Current()->zone(), raw_ptr);              \
  }                                                                            \
  /* T::Cast cannot be applied to a null Object, because the object vtable */  \
  /* is not setup for type T, although some methods are supposed to work   */  \
  /* with null, for example Instance::Equals().                            */  \
  static const object& Cast(const Object& obj) {                               \
    ASSERT(obj.Is##object());                                                  \
    return reinterpret_cast<const object&>(obj);                               \
  }                                                                            \
  static Raw##object* RawCast(RawObject* raw) {                                \
    ASSERT(Object::Handle(raw).Is##object());                                  \
    return reinterpret_cast<Raw##object*>(raw);                                \
  }                                                                            \
  static Raw##object* null() {                                                 \
    return reinterpret_cast<Raw##object*>(Object::null());                     \
  }                                                                            \
  virtual const char* ToCString() const;                                       \
  static const ClassId kClassId = k##object##Cid;                              \
                                                                               \
 private: /* NOLINT */                                                         \
  /* Initialize the handle based on the raw_ptr in the presence of null. */    \
  static void initializeHandle(object* obj, RawObject* raw_ptr) {              \
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
  object(const object& value);                                                 \
  void operator=(Raw##super* value);                                           \
  void operator=(const object& value);                                         \
  void operator=(const super& value);

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
  static Raw##object* ReadFrom(SnapshotReader* reader, intptr_t object_id,     \
                               intptr_t tags, Snapshot::Kind,                  \
                               bool as_reference);                             \
  friend class SnapshotReader;

#define OBJECT_IMPLEMENTATION(object, super)                                   \
 public: /* NOLINT */                                                          \
  void operator=(Raw##object* value) { initializeHandle(this, value); }        \
  void operator^=(RawObject* value) {                                          \
    initializeHandle(this, value);                                             \
    ASSERT(IsNull() || Is##object());                                          \
  }                                                                            \
                                                                               \
 protected: /* NOLINT */                                                       \
  object() : super() {}                                                        \
  BASE_OBJECT_IMPLEMENTATION(object, super)                                    \
  OBJECT_SERVICE_SUPPORT(object)

#define HEAP_OBJECT_IMPLEMENTATION(object, super)                              \
  OBJECT_IMPLEMENTATION(object, super);                                        \
  const Raw##object* raw_ptr() const {                                         \
    ASSERT(raw() != null());                                                   \
    return raw()->ptr();                                                       \
  }                                                                            \
  SNAPSHOT_READER_SUPPORT(object)                                              \
  friend class StackFrame;                                                     \
  friend class Thread;

// This macro is used to denote types that do not have a sub-type.
#define FINAL_HEAP_OBJECT_IMPLEMENTATION_HELPER(object, rettype, super)        \
 public: /* NOLINT */                                                          \
  void operator=(Raw##object* value) {                                         \
    raw_ = value;                                                              \
    CHECK_HANDLE();                                                            \
  }                                                                            \
  void operator^=(RawObject* value) {                                          \
    raw_ = value;                                                              \
    CHECK_HANDLE();                                                            \
  }                                                                            \
                                                                               \
 private: /* NOLINT */                                                         \
  object() : super() {}                                                        \
  BASE_OBJECT_IMPLEMENTATION(object, super)                                    \
  OBJECT_SERVICE_SUPPORT(object)                                               \
  const Raw##object* raw_ptr() const {                                         \
    ASSERT(raw() != null());                                                   \
    return raw()->ptr();                                                       \
  }                                                                            \
  static intptr_t NextFieldOffset() { return -kWordSize; }                     \
  SNAPSHOT_READER_SUPPORT(rettype)                                             \
  friend class StackFrame;                                                     \
  friend class Thread;

#define FINAL_HEAP_OBJECT_IMPLEMENTATION(object, super)                        \
  FINAL_HEAP_OBJECT_IMPLEMENTATION_HELPER(object, object, super)

#define MINT_OBJECT_IMPLEMENTATION(object, rettype, super)                     \
  FINAL_HEAP_OBJECT_IMPLEMENTATION_HELPER(object, rettype, super)

class Object {
 public:
  virtual ~Object() {}

  RawObject* raw() const { return raw_; }
  void operator=(RawObject* value) { initializeHandle(this, value); }

  uint32_t CompareAndSwapTags(uint32_t old_tags, uint32_t new_tags) const {
    return AtomicOperations::CompareAndSwapUint32(&raw()->ptr()->tags_,
                                                  old_tags, new_tags);
  }
  bool IsCanonical() const { return raw()->IsCanonical(); }
  void SetCanonical() const { raw()->SetCanonical(); }
  void ClearCanonical() const { raw()->ClearCanonical(); }
  intptr_t GetClassId() const {
    return !raw()->IsHeapObject() ? static_cast<intptr_t>(kSmiCid)
                                  : raw()->GetClassId();
  }
  inline RawClass* clazz() const;
  static intptr_t tags_offset() { return OFFSET_OF(RawObject, tags_); }

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
  virtual RawString* DictionaryName() const;

  bool IsNew() const { return raw()->IsNewObject(); }
  bool IsOld() const { return raw()->IsOldObject(); }
#if defined(DEBUG)
  bool InVMHeap() const;
#else
  bool InVMHeap() const { return raw()->IsVMHeapObject(); }
#endif  // DEBUG

  // Print the object on stdout for debugging.
  void Print() const;

  bool IsZoneHandle() const {
    return VMHandles::IsZoneHandle(reinterpret_cast<uword>(this));
  }

  bool IsReadOnlyHandle() const;

  bool IsNotTemporaryScopedHandle() const;

  static Object& Handle(Zone* zone, RawObject* raw_ptr) {
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

  static Object& Handle(RawObject* raw_ptr) {
    return Handle(Thread::Current()->zone(), raw_ptr);
  }

  static Object& ZoneHandle(Zone* zone, RawObject* raw_ptr) {
    Object* obj =
        reinterpret_cast<Object*>(VMHandles::AllocateZoneHandle(zone));
    initializeHandle(obj, raw_ptr);
    return *obj;
  }

  static Object& ZoneHandle() {
    return ZoneHandle(Thread::Current()->zone(), null_);
  }

  static Object& ZoneHandle(RawObject* raw_ptr) {
    return ZoneHandle(Thread::Current()->zone(), raw_ptr);
  }

  static RawObject* null() { return null_; }

  static const Object& null_object() {
    ASSERT(null_object_ != NULL);
    return *null_object_;
  }
  static const Array& null_array() {
    ASSERT(null_array_ != NULL);
    return *null_array_;
  }
  static const String& null_string() {
    ASSERT(null_string_ != NULL);
    return *null_string_;
  }
  static const Instance& null_instance() {
    ASSERT(null_instance_ != NULL);
    return *null_instance_;
  }
  static const Function& null_function() {
    ASSERT(null_function_ != NULL);
    return *null_function_;
  }
  static const TypeArguments& null_type_arguments() {
    ASSERT(null_type_arguments_ != NULL);
    return *null_type_arguments_;
  }
  static const TypeArguments& empty_type_arguments() {
    ASSERT(empty_type_arguments_ != NULL);
    return *empty_type_arguments_;
  }

  static const Array& empty_array() {
    ASSERT(empty_array_ != NULL);
    return *empty_array_;
  }
  static const Array& zero_array() {
    ASSERT(zero_array_ != NULL);
    return *zero_array_;
  }

  static const Context& empty_context() {
    ASSERT(empty_context_ != NULL);
    return *empty_context_;
  }

  static const ContextScope& empty_context_scope() {
    ASSERT(empty_context_scope_ != NULL);
    return *empty_context_scope_;
  }

  static const ObjectPool& empty_object_pool() {
    ASSERT(empty_object_pool_ != NULL);
    return *empty_object_pool_;
  }

  static const PcDescriptors& empty_descriptors() {
    ASSERT(empty_descriptors_ != NULL);
    return *empty_descriptors_;
  }

  static const LocalVarDescriptors& empty_var_descriptors() {
    ASSERT(empty_var_descriptors_ != NULL);
    return *empty_var_descriptors_;
  }

  static const ExceptionHandlers& empty_exception_handlers() {
    ASSERT(empty_exception_handlers_ != NULL);
    return *empty_exception_handlers_;
  }

  static const Array& extractor_parameter_types() {
    ASSERT(extractor_parameter_types_ != NULL);
    return *extractor_parameter_types_;
  }

  static const Array& extractor_parameter_names() {
    ASSERT(extractor_parameter_names_ != NULL);
    return *extractor_parameter_names_;
  }

  // The sentinel is a value that cannot be produced by Dart code.
  // It can be used to mark special values, for example to distinguish
  // "uninitialized" fields.
  static const Instance& sentinel() {
    ASSERT(sentinel_ != NULL);
    return *sentinel_;
  }
  // Value marking that we are transitioning from sentinel, e.g., computing
  // a field value. Used to detect circular initialization.
  static const Instance& transition_sentinel() {
    ASSERT(transition_sentinel_ != NULL);
    return *transition_sentinel_;
  }

#if defined(HASH_IN_OBJECT_HEADER)
  static uint32_t GetCachedHash(const RawObject* obj) {
    return obj->ptr()->hash_;
  }

  static void SetCachedHash(RawObject* obj, uint32_t hash) {
    obj->ptr()->hash_ = hash;
  }
#endif

  // Compiler's constant propagation constants.
  static const Instance& unknown_constant() {
    ASSERT(unknown_constant_ != NULL);
    return *unknown_constant_;
  }
  static const Instance& non_constant() {
    ASSERT(non_constant_ != NULL);
    return *non_constant_;
  }

  static const Bool& bool_true() {
    ASSERT(bool_true_ != NULL);
    return *bool_true_;
  }
  static const Bool& bool_false() {
    ASSERT(bool_false_ != NULL);
    return *bool_false_;
  }

  static const Smi& smi_illegal_cid() {
    ASSERT(smi_illegal_cid_ != NULL);
    return *smi_illegal_cid_;
  }
  static const LanguageError& snapshot_writer_error() {
    ASSERT(snapshot_writer_error_ != NULL);
    return *snapshot_writer_error_;
  }

  static const LanguageError& branch_offset_error() {
    ASSERT(branch_offset_error_ != NULL);
    return *branch_offset_error_;
  }

  static const LanguageError& speculative_inlining_error() {
    ASSERT(speculative_inlining_error_ != NULL);
    return *speculative_inlining_error_;
  }

  static const LanguageError& background_compilation_error() {
    ASSERT(background_compilation_error_ != NULL);
    return *background_compilation_error_;
  }

  static const Array& vm_isolate_snapshot_object_table() {
    ASSERT(vm_isolate_snapshot_object_table_ != NULL);
    return *vm_isolate_snapshot_object_table_;
  }
  static const Type& dynamic_type() {
    ASSERT(dynamic_type_ != NULL);
    return *dynamic_type_;
  }
  static const Type& void_type() {
    ASSERT(void_type_ != NULL);
    return *void_type_;
  }
  static const Type& vector_type() {
    ASSERT(vector_type_ != NULL);
    return *vector_type_;
  }

  static void set_vm_isolate_snapshot_object_table(const Array& table);

  static RawClass* class_class() { return class_class_; }
  static RawClass* dynamic_class() { return dynamic_class_; }
  static RawClass* void_class() { return void_class_; }
  static RawClass* unresolved_class_class() { return unresolved_class_class_; }
  static RawClass* type_arguments_class() { return type_arguments_class_; }
  static RawClass* patch_class_class() { return patch_class_class_; }
  static RawClass* function_class() { return function_class_; }
  static RawClass* closure_data_class() { return closure_data_class_; }
  static RawClass* signature_data_class() { return signature_data_class_; }
  static RawClass* redirection_data_class() { return redirection_data_class_; }
  static RawClass* field_class() { return field_class_; }
  static RawClass* literal_token_class() { return literal_token_class_; }
  static RawClass* token_stream_class() { return token_stream_class_; }
  static RawClass* script_class() { return script_class_; }
  static RawClass* library_class() { return library_class_; }
  static RawClass* namespace_class() { return namespace_class_; }
  static RawClass* code_class() { return code_class_; }
  static RawClass* instructions_class() { return instructions_class_; }
  static RawClass* object_pool_class() { return object_pool_class_; }
  static RawClass* pc_descriptors_class() { return pc_descriptors_class_; }
  static RawClass* code_source_map_class() { return code_source_map_class_; }
  static RawClass* stackmap_class() { return stackmap_class_; }
  static RawClass* var_descriptors_class() { return var_descriptors_class_; }
  static RawClass* exception_handlers_class() {
    return exception_handlers_class_;
  }
  static RawClass* deopt_info_class() { return deopt_info_class_; }
  static RawClass* context_class() { return context_class_; }
  static RawClass* context_scope_class() { return context_scope_class_; }
  static RawClass* api_error_class() { return api_error_class_; }
  static RawClass* language_error_class() { return language_error_class_; }
  static RawClass* unhandled_exception_class() {
    return unhandled_exception_class_;
  }
  static RawClass* unwind_error_class() { return unwind_error_class_; }
  static RawClass* singletargetcache_class() {
    return singletargetcache_class_;
  }
  static RawClass* unlinkedcall_class() { return unlinkedcall_class_; }
  static RawClass* icdata_class() { return icdata_class_; }
  static RawClass* megamorphic_cache_class() {
    return megamorphic_cache_class_;
  }
  static RawClass* subtypetestcache_class() { return subtypetestcache_class_; }

  // Initialize the VM isolate.
  static void InitNull(Isolate* isolate);
  static void InitOnce(Isolate* isolate);
  static void FinalizeVMIsolate(Isolate* isolate);

  // Initialize a new isolate either from a Kernel IR, from source, or from a
  // snapshot.
  static RawError* Init(Isolate* isolate, kernel::Program* program);

  static void MakeUnusedSpaceTraversable(const Object& obj,
                                         intptr_t original_size,
                                         intptr_t used_size);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawObject));
  }

  static void VerifyBuiltinVtables();

  static const ClassId kClassId = kObjectCid;

  // Different kinds of type tests.
  enum TypeTestKind { kIsSubtypeOf = 0, kIsMoreSpecificThan };

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

 protected:
  // Used for extracting the C++ vtable during bringup.
  Object() : raw_(null_) {}

  uword raw_value() const { return reinterpret_cast<uword>(raw()); }

  inline void SetRaw(RawObject* value);
  void CheckHandle() const;

  cpp_vtable vtable() const { return bit_copy<cpp_vtable>(*this); }
  void set_vtable(cpp_vtable value) { *vtable_address() = value; }

  static RawObject* Allocate(intptr_t cls_id, intptr_t size, Heap::Space space);

  static intptr_t RoundedAllocationSize(intptr_t size) {
    return Utils::RoundUp(size, kObjectAlignment);
  }

  bool Contains(uword addr) const { return raw()->Contains(addr); }

  // Start of field mutator guards.
  //
  // All writes to heap objects should ultimately pass through one of the
  // methods below or their counterparts in RawObject, to ensure that the
  // write barrier is correctly applied.

  template <typename type>
  void StorePointer(type const* addr, type value) const {
    raw()->StorePointer(addr, value);
  }

  // Store a range of pointers [from, from + count) into [to, to + count).
  // TODO(koda): Use this to fix Object::Clone's broken store buffer logic.
  void StorePointers(RawObject* const* to,
                     RawObject* const* from,
                     intptr_t count) {
    ASSERT(Contains(reinterpret_cast<uword>(to)));
    if (raw()->IsNewObject()) {
      memmove(const_cast<RawObject**>(to), from, count * kWordSize);
    } else {
      for (intptr_t i = 0; i < count; ++i) {
        StorePointer(&to[i], from[i]);
      }
    }
  }

  // Use for storing into an explicitly Smi-typed field of an object
  // (i.e., both the previous and new value are Smis).
  void StoreSmi(RawSmi* const* addr, RawSmi* value) const {
    raw()->StoreSmi(addr, value);
  }

  template <typename FieldType>
  void StoreSimd128(const FieldType* addr, simd128_value_t value) const {
    ASSERT(Contains(reinterpret_cast<uword>(addr)));
    value.writeTo(const_cast<FieldType*>(addr));
  }

  // Needs two template arguments to allow assigning enums to fixed-size ints.
  template <typename FieldType, typename ValueType>
  void StoreNonPointer(const FieldType* addr, ValueType value) const {
    // Can't use Contains, as it uses tags_, which is set through this method.
    ASSERT(reinterpret_cast<uword>(addr) >= RawObject::ToAddr(raw()));
    *const_cast<FieldType*>(addr) = value;
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
  void StoreNonPointer(Raw##type* const* addr, ValueType value) const {        \
    UnimplementedMethod();                                                     \
  }                                                                            \
  Raw##type** UnsafeMutableNonPointer(Raw##type* const* addr) const {          \
    UnimplementedMethod();                                                     \
    return NULL;                                                               \
  }

  CLASS_LIST(STORE_NON_POINTER_ILLEGAL_TYPE);
  void UnimplementedMethod() const;
#undef STORE_NON_POINTER_ILLEGAL_TYPE

  // Allocate an object and copy the body of 'orig'.
  static RawObject* Clone(const Object& orig, Heap::Space space);

  // End of field mutator guards.

  RawObject* raw_;  // The raw object reference.

 protected:
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
                               bool is_vm_object);

  static void RegisterClass(const Class& cls,
                            const String& name,
                            const Library& lib);
  static void RegisterPrivateClass(const Class& cls,
                                   const String& name,
                                   const Library& lib);

  /* Initialize the handle based on the raw_ptr in the presence of null. */
  static void initializeHandle(Object* obj, RawObject* raw_ptr) {
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

  static cpp_vtable handle_vtable_;
  static cpp_vtable builtin_vtables_[kNumPredefinedCids];

  // The static values below are singletons shared between the different
  // isolates. They are all allocated in the non-GC'd Dart::vm_isolate_.
  static RawObject* null_;

  static RawClass* class_class_;             // Class of the Class vm object.
  static RawClass* dynamic_class_;           // Class of the 'dynamic' type.
  static RawClass* void_class_;              // Class of the 'void' type.
  static RawClass* vector_class_;            // Class of the 'vector' type.
  static RawClass* unresolved_class_class_;  // Class of UnresolvedClass.
  static RawClass* type_arguments_class_;  // Class of TypeArguments vm object.
  static RawClass* patch_class_class_;     // Class of the PatchClass vm object.
  static RawClass* function_class_;        // Class of the Function vm object.
  static RawClass* closure_data_class_;    // Class of ClosureData vm obj.
  static RawClass* signature_data_class_;  // Class of SignatureData vm obj.
  static RawClass* redirection_data_class_;  // Class of RedirectionData vm obj.
  static RawClass* field_class_;             // Class of the Field vm object.
  static RawClass* literal_token_class_;     // Class of LiteralToken vm object.
  static RawClass* token_stream_class_;  // Class of the TokenStream vm object.
  static RawClass* script_class_;        // Class of the Script vm object.
  static RawClass* library_class_;       // Class of the Library vm object.
  static RawClass* namespace_class_;     // Class of Namespace vm object.
  static RawClass* code_class_;          // Class of the Code vm object.
  static RawClass* instructions_class_;  // Class of the Instructions vm object.
  static RawClass* object_pool_class_;   // Class of the ObjectPool vm object.
  static RawClass* pc_descriptors_class_;   // Class of PcDescriptors vm object.
  static RawClass* code_source_map_class_;  // Class of CodeSourceMap vm object.
  static RawClass* stackmap_class_;         // Class of StackMap vm object.
  static RawClass* var_descriptors_class_;  // Class of LocalVarDescriptors.
  static RawClass* exception_handlers_class_;  // Class of ExceptionHandlers.
  static RawClass* deopt_info_class_;          // Class of DeoptInfo.
  static RawClass* context_class_;        // Class of the Context vm object.
  static RawClass* context_scope_class_;  // Class of ContextScope vm object.
  static RawClass* singletargetcache_class_;    // Class of SingleTargetCache.
  static RawClass* unlinkedcall_class_;         // Class of UnlinkedCall.
  static RawClass* icdata_class_;               // Class of ICData.
  static RawClass* megamorphic_cache_class_;    // Class of MegamorphiCache.
  static RawClass* subtypetestcache_class_;     // Class of SubtypeTestCache.
  static RawClass* api_error_class_;            // Class of ApiError.
  static RawClass* language_error_class_;       // Class of LanguageError.
  static RawClass* unhandled_exception_class_;  // Class of UnhandledException.
  static RawClass* unwind_error_class_;         // Class of UnwindError.

  // The static values below are read-only handle pointers for singleton
  // objects that are shared between the different isolates.
  static Object* null_object_;
  static Array* null_array_;
  static String* null_string_;
  static Instance* null_instance_;
  static Function* null_function_;
  static TypeArguments* null_type_arguments_;
  static TypeArguments* empty_type_arguments_;
  static Array* empty_array_;
  static Array* zero_array_;
  static Context* empty_context_;
  static ContextScope* empty_context_scope_;
  static ObjectPool* empty_object_pool_;
  static PcDescriptors* empty_descriptors_;
  static LocalVarDescriptors* empty_var_descriptors_;
  static ExceptionHandlers* empty_exception_handlers_;
  static Array* extractor_parameter_types_;
  static Array* extractor_parameter_names_;
  static Instance* sentinel_;
  static Instance* transition_sentinel_;
  static Instance* unknown_constant_;
  static Instance* non_constant_;
  static Bool* bool_true_;
  static Bool* bool_false_;
  static Smi* smi_illegal_cid_;
  static LanguageError* snapshot_writer_error_;
  static LanguageError* branch_offset_error_;
  static LanguageError* speculative_inlining_error_;
  static LanguageError* background_compilation_error_;
  static Array* vm_isolate_snapshot_object_table_;
  static Type* dynamic_type_;
  static Type* void_type_;
  static Type* vector_type_;

  friend void ClassTable::Register(const Class& cls);
  friend void RawObject::Validate(Isolate* isolate) const;
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
  void operator=(RawObject* value) { raw_ = value; }
  void operator^=(RawObject* value) { raw_ = value; }

  static PassiveObject& Handle(Zone* zone, RawObject* raw_ptr) {
    PassiveObject* obj =
        reinterpret_cast<PassiveObject*>(VMHandles::AllocateHandle(zone));
    obj->raw_ = raw_ptr;
    obj->set_vtable(0);
    return *obj;
  }
  static PassiveObject& Handle(RawObject* raw_ptr) {
    return Handle(Thread::Current()->zone(), raw_ptr);
  }
  static PassiveObject& Handle() {
    return Handle(Thread::Current()->zone(), Object::null());
  }
  static PassiveObject& Handle(Zone* zone) {
    return Handle(zone, Object::null());
  }
  static PassiveObject& ZoneHandle(Zone* zone, RawObject* raw_ptr) {
    PassiveObject* obj =
        reinterpret_cast<PassiveObject*>(VMHandles::AllocateZoneHandle(zone));
    obj->raw_ = raw_ptr;
    obj->set_vtable(0);
    return *obj;
  }
  static PassiveObject& ZoneHandle(RawObject* raw_ptr) {
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

class Class : public Object {
 public:
  intptr_t instance_size() const {
    ASSERT(is_finalized() || is_prefinalized());
    return (raw_ptr()->instance_size_in_words_ * kWordSize);
  }
  void set_instance_size(intptr_t value_in_bytes) const {
    ASSERT(kWordSize != 0);
    set_instance_size_in_words(value_in_bytes / kWordSize);
  }
  void set_instance_size_in_words(intptr_t value) const {
    ASSERT(Utils::IsAligned((value * kWordSize), kObjectAlignment));
    StoreNonPointer(&raw_ptr()->instance_size_in_words_, value);
  }

  intptr_t next_field_offset() const {
    return raw_ptr()->next_field_offset_in_words_ * kWordSize;
  }
  void set_next_field_offset(intptr_t value_in_bytes) const {
    ASSERT(kWordSize != 0);
    set_next_field_offset_in_words(value_in_bytes / kWordSize);
  }
  void set_next_field_offset_in_words(intptr_t value) const {
    ASSERT((value == -1) ||
           (Utils::IsAligned((value * kWordSize), kObjectAlignment) &&
            (value == raw_ptr()->instance_size_in_words_)) ||
           (!Utils::IsAligned((value * kWordSize), kObjectAlignment) &&
            ((value + 1) == raw_ptr()->instance_size_in_words_)));
    StoreNonPointer(&raw_ptr()->next_field_offset_in_words_, value);
  }

  cpp_vtable handle_vtable() const { return raw_ptr()->handle_vtable_; }
  void set_handle_vtable(cpp_vtable value) const {
    StoreNonPointer(&raw_ptr()->handle_vtable_, value);
  }

  static bool is_valid_id(intptr_t value) {
    return RawObject::ClassIdTag::is_valid(value);
  }
  intptr_t id() const { return raw_ptr()->id_; }
  void set_id(intptr_t value) const {
    ASSERT(is_valid_id(value));
    StoreNonPointer(&raw_ptr()->id_, value);
  }

  RawString* Name() const;
  RawString* ScrubbedName() const;
  RawString* UserVisibleName() const;
  bool IsInFullSnapshot() const;

  virtual RawString* DictionaryName() const { return Name(); }

  RawScript* script() const { return raw_ptr()->script_; }
  void set_script(const Script& value) const;

  TokenPosition token_pos() const { return raw_ptr()->token_pos_; }
  void set_token_pos(TokenPosition value) const;

  TokenPosition ComputeEndTokenPos() const;

  // This class represents a typedef if the signature function is not null.
  RawFunction* signature_function() const {
    return raw_ptr()->signature_function_;
  }
  void set_signature_function(const Function& value) const;

  // Return the Type with type parameters declared by this class filled in with
  // dynamic and type parameters declared in superclasses filled in as declared
  // in superclass clauses.
  RawAbstractType* RareType() const;

  // Return the Type whose arguments are the type parameters declared by this
  // class preceded by the type arguments declared for superclasses, etc.
  // e.g. given
  // class B<T, S>
  // class C<R> extends B<R, int>
  // C.DeclarationType() --> C [R, int, R]
  RawAbstractType* DeclarationType() const;

  RawLibrary* library() const { return raw_ptr()->library_; }
  void set_library(const Library& value) const;

  // The type parameters (and their bounds) are specified as an array of
  // TypeParameter.
  RawTypeArguments* type_parameters() const {
    return raw_ptr()->type_parameters_;
  }
  void set_type_parameters(const TypeArguments& value) const;
  intptr_t NumTypeParameters(Thread* thread) const;
  intptr_t NumTypeParameters() const {
    return NumTypeParameters(Thread::Current());
  }
  static intptr_t type_parameters_offset() {
    return OFFSET_OF(RawClass, type_parameters_);
  }

  // Return a TypeParameter if the type_name is a type parameter of this class.
  // Return null otherwise.
  RawTypeParameter* LookupTypeParameter(const String& type_name) const;

  // The type argument vector is flattened and includes the type arguments of
  // the super class.
  intptr_t NumTypeArguments() const;

  // Return the number of type arguments that are specific to this class, i.e.
  // not overlapping with the type arguments of the super class of this class.
  intptr_t NumOwnTypeArguments() const;

  // Return true if this class declares type parameters.
  bool IsGeneric() const { return NumTypeParameters(Thread::Current()) > 0; }

  // If this class is parameterized, each instance has a type_arguments field.
  static const intptr_t kNoTypeArguments = -1;
  intptr_t type_arguments_field_offset() const {
    ASSERT(is_type_finalized() || is_prefinalized());
    if (raw_ptr()->type_arguments_field_offset_in_words_ == kNoTypeArguments) {
      return kNoTypeArguments;
    }
    return raw_ptr()->type_arguments_field_offset_in_words_ * kWordSize;
  }
  void set_type_arguments_field_offset(intptr_t value_in_bytes) const {
    intptr_t value;
    if (value_in_bytes == kNoTypeArguments) {
      value = kNoTypeArguments;
    } else {
      ASSERT(kWordSize != 0);
      value = value_in_bytes / kWordSize;
    }
    set_type_arguments_field_offset_in_words(value);
  }
  void set_type_arguments_field_offset_in_words(intptr_t value) const {
    StoreNonPointer(&raw_ptr()->type_arguments_field_offset_in_words_, value);
  }
  static intptr_t type_arguments_field_offset_in_words_offset() {
    return OFFSET_OF(RawClass, type_arguments_field_offset_in_words_);
  }

  // Returns the cached canonical type of this class, i.e. the canonical type
  // whose type class is this class and whose type arguments are the
  // uninstantiated type parameters declared by this class if it is generic,
  // e.g. Map<K, V>.
  // Returns Type::null() if the canonical type is not cached yet.
  RawType* CanonicalType() const;

  // Caches the canonical type of this class.
  void SetCanonicalType(const Type& type) const;

  static intptr_t canonical_type_offset() {
    return OFFSET_OF(RawClass, canonical_type_);
  }

  // The super type of this class, Object type if not explicitly specified.
  // Note that the super type may be bounded, as in this example:
  // class C<T> extends S<T> { }; class S<T extends num> { };
  RawAbstractType* super_type() const { return raw_ptr()->super_type_; }
  void set_super_type(const AbstractType& value) const;
  static intptr_t super_type_offset() {
    return OFFSET_OF(RawClass, super_type_);
  }

  // Asserts that the class of the super type has been resolved.
  // |original_classes| only has an effect when reloading. If true and we
  // are reloading, it will prefer the original classes to the replacement
  // classes.
  RawClass* SuperClass(bool original_classes = false) const;

  RawType* mixin() const { return raw_ptr()->mixin_; }
  void set_mixin(const Type& value) const;

  // Note this returns false for mixin application aliases.
  bool IsMixinApplication() const;

  RawClass* GetPatchClass() const;

  // Interfaces is an array of Types.
  RawArray* interfaces() const { return raw_ptr()->interfaces_; }
  void set_interfaces(const Array& value) const;
  static intptr_t interfaces_offset() {
    return OFFSET_OF(RawClass, interfaces_);
  }

  // Returns the list of classes having this class as direct superclass.
  RawGrowableObjectArray* direct_subclasses() const {
    return raw_ptr()->direct_subclasses_;
  }
  void AddDirectSubclass(const Class& subclass) const;
  void ClearDirectSubclasses() const;

  // Check if this class represents the class of null.
  bool IsNullClass() const { return id() == kNullCid; }

  // Check if this class represents the 'dynamic' class.
  bool IsDynamicClass() const { return id() == kDynamicCid; }

  // Check if this class represents the 'void' class.
  bool IsVoidClass() const { return id() == kVoidCid; }

  // Check if this class represents the 'Object' class.
  bool IsObjectClass() const { return id() == kInstanceCid; }

  // Check if this class represents the 'Function' class.
  bool IsDartFunctionClass() const;

  // Check if this class represents the 'Closure' class.
  bool IsClosureClass() const { return id() == kClosureCid; }
  static bool IsClosureClass(RawClass* cls) {
    NoSafepointScope no_safepoint;
    return cls->ptr()->id_ == kClosureCid;
  }

  // Check if this class represents a typedef class.
  bool IsTypedefClass() const { return signature_function() != Object::null(); }

  static bool IsInFullSnapshot(RawClass* cls) {
    NoSafepointScope no_safepoint;
    return cls->ptr()->library_->ptr()->is_in_fullsnapshot_;
  }

  // Check the subtype relationship.
  bool IsSubtypeOf(const TypeArguments& type_arguments,
                   const Class& other,
                   const TypeArguments& other_type_arguments,
                   Error* bound_error,
                   TrailPtr bound_trail,
                   Heap::Space space) const {
    return TypeTest(kIsSubtypeOf, type_arguments, other, other_type_arguments,
                    bound_error, bound_trail, space);
  }

  // Check the 'more specific' relationship.
  bool IsMoreSpecificThan(const TypeArguments& type_arguments,
                          const Class& other,
                          const TypeArguments& other_type_arguments,
                          Error* bound_error,
                          TrailPtr bound_trail,
                          Heap::Space space) const {
    return TypeTest(kIsMoreSpecificThan, type_arguments, other,
                    other_type_arguments, bound_error, bound_trail, space);
  }

  // Check if this is the top level class.
  bool IsTopLevel() const;

  bool IsPrivate() const;

  // Returns an array of instance and static fields defined by this class.
  RawArray* fields() const { return raw_ptr()->fields_; }
  void SetFields(const Array& value) const;
  void AddField(const Field& field) const;
  void AddFields(const GrowableArray<const Field*>& fields) const;

  void InjectCIDFields() const;

  // Returns an array of all instance fields of this class and its superclasses
  // indexed by offset in words.
  // |original_classes| only has an effect when reloading. If true and we
  // are reloading, it will prefer the original classes to the replacement
  // classes.
  RawArray* OffsetToFieldMap(bool original_classes = false) const;

  // Returns true if non-static fields are defined.
  bool HasInstanceFields() const;

  // TODO(koda): Unite w/ hash table.
  RawArray* functions() const { return raw_ptr()->functions_; }
  void SetFunctions(const Array& value) const;
  void AddFunction(const Function& function) const;
  void RemoveFunction(const Function& function) const;
  RawFunction* FunctionFromIndex(intptr_t idx) const;
  intptr_t FindImplicitClosureFunctionIndex(const Function& needle) const;
  RawFunction* ImplicitClosureFunctionFromIndex(intptr_t idx) const;

  RawFunction* LookupDynamicFunction(const String& name) const;
  RawFunction* LookupDynamicFunctionAllowAbstract(const String& name) const;
  RawFunction* LookupDynamicFunctionAllowPrivate(const String& name) const;
  RawFunction* LookupStaticFunction(const String& name) const;
  RawFunction* LookupStaticFunctionAllowPrivate(const String& name) const;
  RawFunction* LookupConstructor(const String& name) const;
  RawFunction* LookupConstructorAllowPrivate(const String& name) const;
  RawFunction* LookupFactory(const String& name) const;
  RawFunction* LookupFactoryAllowPrivate(const String& name) const;
  RawFunction* LookupFunction(const String& name) const;
  RawFunction* LookupFunctionAllowPrivate(const String& name) const;
  RawFunction* LookupGetterFunction(const String& name) const;
  RawFunction* LookupSetterFunction(const String& name) const;
  RawFunction* LookupCallFunctionForTypeTest() const;
  RawField* LookupInstanceField(const String& name) const;
  RawField* LookupStaticField(const String& name) const;
  RawField* LookupField(const String& name) const;
  RawField* LookupFieldAllowPrivate(const String& name,
                                    bool instance_only = false) const;
  RawField* LookupInstanceFieldAllowPrivate(const String& name) const;
  RawField* LookupStaticFieldAllowPrivate(const String& name) const;

  RawLibraryPrefix* LookupLibraryPrefix(const String& name) const;

  // Returns an instance of Double or Double::null().
  // 'index' points to either:
  // - constants_list_ position of found element, or
  // - constants_list_ position where new canonical can be inserted.
  RawDouble* LookupCanonicalDouble(Zone* zone,
                                   double value,
                                   intptr_t* index) const;
  RawMint* LookupCanonicalMint(Zone* zone,
                               int64_t value,
                               intptr_t* index) const;
  RawBigint* LookupCanonicalBigint(Zone* zone,
                                   const Bigint& value,
                                   intptr_t* index) const;
  // The methods above are more efficient than this generic one.
  RawInstance* LookupCanonicalInstance(Zone* zone, const Instance& value) const;

  RawInstance* InsertCanonicalConstant(Zone* zone,
                                       const Instance& constant) const;
  void InsertCanonicalNumber(Zone* zone,
                             intptr_t index,
                             const Number& constant) const;

  void RehashConstants(Zone* zone) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawClass));
  }

  bool is_implemented() const {
    return ImplementedBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_implemented() const;

  bool is_abstract() const {
    return AbstractBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_abstract() const;

  bool is_type_finalized() const {
    return TypeFinalizedBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_type_finalized() const;

  bool is_patch() const { return PatchBit::decode(raw_ptr()->state_bits_); }
  void set_is_patch() const;

  bool is_synthesized_class() const {
    return SynthesizedClassBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_synthesized_class() const;

  bool is_enum_class() const { return EnumBit::decode(raw_ptr()->state_bits_); }
  void set_is_enum_class() const;

  bool is_finalized() const {
    return ClassFinalizedBits::decode(raw_ptr()->state_bits_) ==
           RawClass::kFinalized;
  }
  void set_is_finalized() const;

  bool is_prefinalized() const {
    return ClassFinalizedBits::decode(raw_ptr()->state_bits_) ==
           RawClass::kPreFinalized;
  }

  void set_is_prefinalized() const;

  bool is_refinalize_after_patch() const {
    return ClassFinalizedBits::decode(raw_ptr()->state_bits_) ==
           RawClass::kRefinalizeAfterPatch;
  }

  void SetRefinalizeAfterPatch() const;
  void ResetFinalization() const;

  bool is_marked_for_parsing() const {
    return MarkedForParsingBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_marked_for_parsing() const;
  void reset_is_marked_for_parsing() const;

  bool is_const() const { return ConstBit::decode(raw_ptr()->state_bits_); }
  void set_is_const() const;

  bool is_mixin_app_alias() const {
    return MixinAppAliasBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_mixin_app_alias() const;

  bool is_mixin_type_applied() const {
    return MixinTypeAppliedBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_mixin_type_applied() const;

  bool is_fields_marked_nullable() const {
    return FieldsMarkedNullableBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_fields_marked_nullable() const;

  bool is_cycle_free() const {
    return CycleFreeBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_cycle_free() const;

  bool is_allocated() const {
    return IsAllocatedBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_allocated(bool value) const;

  uint16_t num_native_fields() const { return raw_ptr()->num_native_fields_; }
  void set_num_native_fields(uint16_t value) const {
    StoreNonPointer(&raw_ptr()->num_native_fields_, value);
  }

  RawCode* allocation_stub() const { return raw_ptr()->allocation_stub_; }
  void set_allocation_stub(const Code& value) const;

  void DisableAllocationStub() const;

  RawArray* constants() const;
  void set_constants(const Array& value) const;

  intptr_t FindInvocationDispatcherFunctionIndex(const Function& needle) const;
  RawFunction* InvocationDispatcherFunctionFromIndex(intptr_t idx) const;

  RawFunction* GetInvocationDispatcher(const String& target_name,
                                       const Array& args_desc,
                                       RawFunction::Kind kind,
                                       bool create_if_absent) const;

  void Finalize() const;

  // Apply given patch class to this class.
  // Return true on success, or false and error otherwise.
  bool ApplyPatch(const Class& patch, Error* error) const;

  // Evaluate the given expression as if it appeared in a static
  // method of this class and return the resulting value, or an
  // error object if evaluating the expression fails. The method has
  // the formal parameters given in param_names, and is invoked with
  // the argument values given in param_values.
  RawObject* Evaluate(const String& expr,
                      const Array& param_names,
                      const Array& param_values) const;

  RawError* EnsureIsFinalized(Thread* thread) const;

  // Allocate a class used for VM internal objects.
  template <class FakeObject>
  static RawClass* New();

  // Allocate instance classes.
  static RawClass* New(const Library& lib,
                       const String& name,
                       const Script& script,
                       TokenPosition token_pos);
  static RawClass* NewNativeWrapper(const Library& library,
                                    const String& name,
                                    int num_fields);

  // Allocate the raw string classes.
  static RawClass* NewStringClass(intptr_t class_id);

  // Allocate the raw TypedData classes.
  static RawClass* NewTypedDataClass(intptr_t class_id);

  // Allocate the raw TypedDataView classes.
  static RawClass* NewTypedDataViewClass(intptr_t class_id);

  // Allocate the raw ExternalTypedData classes.
  static RawClass* NewExternalTypedDataClass(intptr_t class_id);

  // Register code that has used CHA for optimization.
  // TODO(srdjan): Also register kind of CHA optimization (e.g.: leaf class,
  // leaf method, ...).
  void RegisterCHACode(const Code& code);

  void DisableCHAOptimizedCode(const Class& subclass);

  void DisableAllCHAOptimizedCode();

  // Return the list of code objects that were compiled using CHA of this class.
  // These code objects will be invalidated if new subclasses of this class
  // are finalized.
  RawArray* dependent_code() const { return raw_ptr()->dependent_code_; }
  void set_dependent_code(const Array& array) const;

  bool TraceAllocation(Isolate* isolate) const;
  void SetTraceAllocation(bool trace_allocation) const;

  bool ValidatePostFinalizePatch(const Class& orig_class, Error* error) const;
  void ReplaceEnum(const Class& old_enum) const;
  void CopyStaticFieldValues(const Class& old_cls) const;
  void PatchFieldsAndFunctions() const;
  void MigrateImplicitStaticClosures(IsolateReloadContext* context,
                                     const Class& new_cls) const;
  void CopyCanonicalConstants(const Class& old_cls) const;
  void CopyCanonicalType(const Class& old_cls) const;
  void CheckReload(const Class& replacement,
                   IsolateReloadContext* context) const;

 private:
  bool CanReloadFinalized(const Class& replacement,
                          IsolateReloadContext* context) const;
  bool CanReloadPreFinalized(const Class& replacement,
                             IsolateReloadContext* context) const;

  // Tells whether instances need morphing for reload.
  bool RequiresInstanceMorphing(const Class& replacement) const;

  template <class FakeObject>
  static RawClass* NewCommon(intptr_t index);

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
    kTypeFinalizedBit = 2,
    kClassFinalizedPos = 3,
    kClassFinalizedSize = 2,
    kAbstractBit = kClassFinalizedPos + kClassFinalizedSize,  // = 5
    kPatchBit = 6,
    kSynthesizedClassBit = 7,
    kMarkedForParsingBit = 8,
    kMixinAppAliasBit = 9,
    kMixinTypeAppliedBit = 10,
    kFieldsMarkedNullableBit = 11,
    kCycleFreeBit = 12,
    kEnumBit = 13,
    kIsAllocatedBit = 15,
  };
  class ConstBit : public BitField<uint16_t, bool, kConstBit, 1> {};
  class ImplementedBit : public BitField<uint16_t, bool, kImplementedBit, 1> {};
  class TypeFinalizedBit
      : public BitField<uint16_t, bool, kTypeFinalizedBit, 1> {};
  class ClassFinalizedBits : public BitField<uint16_t,
                                             RawClass::ClassFinalizedState,
                                             kClassFinalizedPos,
                                             kClassFinalizedSize> {};
  class AbstractBit : public BitField<uint16_t, bool, kAbstractBit, 1> {};
  class PatchBit : public BitField<uint16_t, bool, kPatchBit, 1> {};
  class SynthesizedClassBit
      : public BitField<uint16_t, bool, kSynthesizedClassBit, 1> {};
  class MarkedForParsingBit
      : public BitField<uint16_t, bool, kMarkedForParsingBit, 1> {};
  class MixinAppAliasBit
      : public BitField<uint16_t, bool, kMixinAppAliasBit, 1> {};
  class MixinTypeAppliedBit
      : public BitField<uint16_t, bool, kMixinTypeAppliedBit, 1> {};
  class FieldsMarkedNullableBit
      : public BitField<uint16_t, bool, kFieldsMarkedNullableBit, 1> {};
  class CycleFreeBit : public BitField<uint16_t, bool, kCycleFreeBit, 1> {};
  class EnumBit : public BitField<uint16_t, bool, kEnumBit, 1> {};
  class IsAllocatedBit : public BitField<uint16_t, bool, kIsAllocatedBit, 1> {};

  void set_name(const String& value) const;
  void set_user_name(const String& value) const;
  RawString* GenerateUserVisibleName() const;
  void set_state_bits(intptr_t bits) const;

  void set_canonical_type(const Type& value) const;
  RawType* canonical_type() const;

  RawArray* invocation_dispatcher_cache() const;
  void set_invocation_dispatcher_cache(const Array& cache) const;
  RawFunction* CreateInvocationDispatcher(const String& target_name,
                                          const Array& args_desc,
                                          RawFunction::Kind kind) const;

  void CalculateFieldOffsets() const;

  // functions_hash_table is in use iff there are at least this many functions.
  static const intptr_t kFunctionLookupHashTreshold = 16;

  // Initial value for the cached number of type arguments.
  static const intptr_t kUnknownNumTypeArguments = -1;

  int16_t num_type_arguments() const { return raw_ptr()->num_type_arguments_; }
  void set_num_type_arguments(intptr_t value) const;
  static intptr_t num_type_arguments_offset() {
    return OFFSET_OF(RawClass, num_type_arguments_);
  }

  int16_t num_own_type_arguments() const {
    return raw_ptr()->num_own_type_arguments_;
  }
  void set_num_own_type_arguments(intptr_t value) const;

  // Assigns empty array to all raw class array fields.
  void InitEmptyFields();

  static RawFunction* CheckFunctionType(const Function& func, MemberKind kind);
  RawFunction* LookupFunction(const String& name, MemberKind kind) const;
  RawFunction* LookupFunctionAllowPrivate(const String& name,
                                          MemberKind kind) const;
  RawField* LookupField(const String& name, MemberKind kind) const;

  RawFunction* LookupAccessorFunction(const char* prefix,
                                      intptr_t prefix_length,
                                      const String& name) const;

  // Allocate an instance class which has a VM implementation.
  template <class FakeInstance>
  static RawClass* New(intptr_t id);

  // Helper that calls 'Class::New<Instance>(kIllegalCid)'.
  static RawClass* NewInstanceClass();

  // Check the subtype or 'more specific' relationship.
  bool TypeTest(TypeTestKind test_kind,
                const TypeArguments& type_arguments,
                const Class& other,
                const TypeArguments& other_type_arguments,
                Error* bound_error,
                TrailPtr bound_trail,
                Heap::Space space) const;

  static bool TypeTestNonRecursive(const Class& cls,
                                   TypeTestKind test_kind,
                                   const TypeArguments& type_arguments,
                                   const Class& other,
                                   const TypeArguments& other_type_arguments,
                                   Error* bound_error,
                                   TrailPtr bound_trail,
                                   Heap::Space space);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Class, Object);
  friend class AbstractType;
  friend class Instance;
  friend class Object;
  friend class Type;
  friend class Intrinsifier;
  friend class ProgramVisitor;
};

// Unresolved class is used for storing unresolved names which will be resolved
// to a class after all classes have been loaded and finalized.
class UnresolvedClass : public Object {
 public:
  RawObject* library_or_library_prefix() const {
    return raw_ptr()->library_or_library_prefix_;
  }
  RawString* ident() const { return raw_ptr()->ident_; }
  TokenPosition token_pos() const { return raw_ptr()->token_pos_; }

  RawString* Name() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawUnresolvedClass));
  }

  static RawUnresolvedClass* New(const Object& library_prefix,
                                 const String& ident,
                                 TokenPosition token_pos);

 private:
  void set_library_or_library_prefix(const Object& library_prefix) const;
  void set_ident(const String& ident) const;
  void set_token_pos(TokenPosition token_pos) const;

  static RawUnresolvedClass* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(UnresolvedClass, Object);
  friend class Class;
};

// Classification of type genericity according to type parameter owners.
enum Genericity {
  kAny,           // Consider type params of current class and functions.
  kCurrentClass,  // Consider type params of current class only.
  kFunctions,     // Consider type params of current and parent functions.
};

// A TypeArguments is an array of AbstractType.
class TypeArguments : public Object {
 public:
  // We use 30 bits for the hash code so hashes in a snapshot taken on a
  // 64-bit architecture stay in Smi range when loaded on a 32-bit
  // architecture.
  static const intptr_t kHashBits = 30;

  intptr_t Length() const;
  RawAbstractType* TypeAt(intptr_t index) const;
  static intptr_t type_at_offset(intptr_t index) {
    return OFFSET_OF_RETURNED_VALUE(RawTypeArguments, types) +
           index * kWordSize;
  }
  void SetTypeAt(intptr_t index, const AbstractType& value) const;

  // The name of this type argument vector, e.g. "<T, dynamic, List<T>, Smi>".
  RawString* Name() const { return SubvectorName(0, Length(), kInternalName); }

  // The name of this type argument vector, e.g. "<T, dynamic, List<T>, int>".
  // Names of internal classes are mapped to their public interfaces.
  RawString* UserVisibleName() const {
    return SubvectorName(0, Length(), kUserVisibleName);
  }

  // Check if the subvector of length 'len' starting at 'from_index' of this
  // type argument vector consists solely of DynamicType.
  bool IsRaw(intptr_t from_index, intptr_t len) const {
    return IsDynamicTypes(false, from_index, len);
  }

  // Check if this type argument vector would consist solely of DynamicType if
  // it was instantiated from both a raw (null) instantiator typearguments and
  // a raw (null) function type arguments, i.e. consider each class type
  // parameter and function type parameters as it would be first instantiated
  // from a vector of dynamic types.
  // Consider only a prefix of length 'len'.
  bool IsRawWhenInstantiatedFromRaw(intptr_t len) const {
    return IsDynamicTypes(true, 0, len);
  }

  // Check the subtype relationship, considering only a subvector of length
  // 'len' starting at 'from_index'.
  bool IsSubtypeOf(const TypeArguments& other,
                   intptr_t from_index,
                   intptr_t len,
                   Error* bound_error,
                   TrailPtr bound_trail,
                   Heap::Space space) const {
    return TypeTest(kIsSubtypeOf, other, from_index, len, bound_error,
                    bound_trail, space);
  }

  // Check the 'more specific' relationship, considering only a subvector of
  // length 'len' starting at 'from_index'.
  bool IsMoreSpecificThan(const TypeArguments& other,
                          intptr_t from_index,
                          intptr_t len,
                          Error* bound_error,
                          TrailPtr bound_trail,
                          Heap::Space space) const {
    return TypeTest(kIsMoreSpecificThan, other, from_index, len, bound_error,
                    bound_trail, space);
  }

  // Check if the vectors are equal (they may be null).
  bool Equals(const TypeArguments& other) const {
    return IsSubvectorEquivalent(other, 0, IsNull() ? 0 : Length());
  }

  bool IsEquivalent(const TypeArguments& other, TrailPtr trail = NULL) const {
    return IsSubvectorEquivalent(other, 0, IsNull() ? 0 : Length(), trail);
  }
  bool IsSubvectorEquivalent(const TypeArguments& other,
                             intptr_t from_index,
                             intptr_t len,
                             TrailPtr trail = NULL) const;

  // Check if the vector is instantiated (it must not be null).
  bool IsInstantiated(Genericity genericity = kAny,
                      intptr_t num_free_fun_type_params = kMaxInt32,
                      TrailPtr trail = NULL) const {
    return IsSubvectorInstantiated(0, Length(), genericity,
                                   num_free_fun_type_params, trail);
  }
  bool IsSubvectorInstantiated(intptr_t from_index,
                               intptr_t len,
                               Genericity genericity = kAny,
                               intptr_t num_free_fun_type_params = kMaxInt32,
                               TrailPtr trail = NULL) const;
  bool IsUninstantiatedIdentity() const;
  bool CanShareInstantiatorTypeArguments(const Class& instantiator_class) const;

  // Return true if all types of this vector are respectively, resolved,
  // finalized, or bounded.
  bool IsResolved() const;
  bool IsFinalized() const;
  bool IsBounded() const;

  // Return true if this vector contains a recursive type argument.
  bool IsRecursive() const;

  // Set the scope of this type argument vector to the given function.
  void SetScopeFunction(const Function& function) const;

  // Clone this type argument vector and clone all unfinalized type arguments.
  // Finalized type arguments are shared.
  RawTypeArguments* CloneUnfinalized() const;

  // Clone this type argument vector and clone all uninstantiated type
  // arguments, changing the class owner of type parameters.
  // Instantiated type arguments are shared.
  RawTypeArguments* CloneUninstantiated(const Class& new_owner,
                                        TrailPtr trail = NULL) const;

  // Canonicalize only if instantiated, otherwise returns 'this'.
  RawTypeArguments* Canonicalize(TrailPtr trail = NULL) const;

  // Returns a formatted list of occurring type arguments with their URI.
  RawString* EnumerateURIs() const;

  // Return 'this' if this type argument vector is instantiated, i.e. if it does
  // not refer to type parameters. Otherwise, return a new type argument vector
  // where each reference to a type parameter is replaced with the corresponding
  // type from the various type argument vectors (class instantiator, function,
  // or parent functions via the current context).
  // If bound_error is not NULL, it may be set to reflect a bound error.
  RawTypeArguments* InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      Error* bound_error,
      TrailPtr instantiation_trail,
      TrailPtr bound_trail,
      Heap::Space space) const;

  // Runtime instantiation with canonicalization. Not to be used during type
  // finalization at compile time.
  RawTypeArguments* InstantiateAndCanonicalizeFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      Error* bound_error) const;

  // Return true if this type argument vector has cached instantiations.
  bool HasInstantiations() const;

  // Return the number of cached instantiations for this type argument vector.
  intptr_t NumInstantiations() const;

  static intptr_t instantiations_offset() {
    return OFFSET_OF(RawTypeArguments, instantiations_);
  }

  static const intptr_t kBytesPerElement = kWordSize;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawTypeArguments) ==
           OFFSET_OF_RETURNED_VALUE(RawTypeArguments, types));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    // Ensure that the types() is not adding to the object size, which includes
    // 3 fields: instantiations_, length_ and hash_.
    ASSERT(sizeof(RawTypeArguments) ==
           (sizeof(RawObject) + (kNumFields * kWordSize)));
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawTypeArguments) +
                                 (len * kBytesPerElement));
  }

  intptr_t Hash() const;

  static RawTypeArguments* New(intptr_t len, Heap::Space space = Heap::kOld);

 private:
  intptr_t ComputeHash() const;
  void SetHash(intptr_t value) const;

  // Check if the subvector of length 'len' starting at 'from_index' of this
  // type argument vector consists solely of DynamicType.
  // If raw_instantiated is true, consider each class type parameter to be first
  // instantiated from a vector of dynamic types.
  bool IsDynamicTypes(bool raw_instantiated,
                      intptr_t from_index,
                      intptr_t len) const;

  // Check the subtype or 'more specific' relationship, considering only a
  // subvector of length 'len' starting at 'from_index'.
  bool TypeTest(TypeTestKind test_kind,
                const TypeArguments& other,
                intptr_t from_index,
                intptr_t len,
                Error* bound_error,
                TrailPtr bound_trail,
                Heap::Space space) const;

  // Return the internal or public name of a subvector of this type argument
  // vector, e.g. "<T, dynamic, List<T>, int>".
  RawString* SubvectorName(intptr_t from_index,
                           intptr_t len,
                           NameVisibility name_visibility) const;

  RawArray* instantiations() const;
  void set_instantiations(const Array& value) const;
  RawAbstractType* const* TypeAddr(intptr_t index) const;
  void SetLength(intptr_t value) const;
  // Number of fields in the raw object=3 (instantiations_, length_ and hash_).
  static const int kNumFields = 3;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypeArguments, Object);
  friend class AbstractType;
  friend class Class;
  friend class ClearTypeHashVisitor;
  friend class Object;
};

class PatchClass : public Object {
 public:
  RawClass* patched_class() const { return raw_ptr()->patched_class_; }
  RawClass* origin_class() const { return raw_ptr()->origin_class_; }
  RawScript* script() const { return raw_ptr()->script_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawPatchClass));
  }
  static bool IsInFullSnapshot(RawPatchClass* cls) {
    NoSafepointScope no_safepoint;
    return Class::IsInFullSnapshot(cls->ptr()->patched_class_);
  }

  static RawPatchClass* New(const Class& patched_class,
                            const Class& origin_class);

  static RawPatchClass* New(const Class& patched_class, const Script& source);

 private:
  void set_patched_class(const Class& value) const;
  void set_origin_class(const Class& value) const;
  void set_script(const Script& value) const;

  static RawPatchClass* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(PatchClass, Object);
  friend class Class;
};

class SingleTargetCache : public Object {
 public:
  RawCode* target() const { return raw_ptr()->target_; }
  void set_target(const Code& target) const;
  static intptr_t target_offset() {
    return OFFSET_OF(RawSingleTargetCache, target_);
  }

#define DEFINE_NON_POINTER_FIELD_ACCESSORS(type, name)                         \
  type name() const { return raw_ptr()->name##_; }                             \
  void set_##name(type value) const {                                          \
    StoreNonPointer(&raw_ptr()->name##_, value);                               \
  }                                                                            \
  static intptr_t name##_offset() {                                            \
    return OFFSET_OF(RawSingleTargetCache, name##_);                           \
  }

  DEFINE_NON_POINTER_FIELD_ACCESSORS(uword, entry_point);
  DEFINE_NON_POINTER_FIELD_ACCESSORS(intptr_t, lower_limit);
  DEFINE_NON_POINTER_FIELD_ACCESSORS(intptr_t, upper_limit);
#undef DEFINE_NON_POINTER_FIELD_ACCESSORS

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawSingleTargetCache));
  }

  static RawSingleTargetCache* New();

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(SingleTargetCache, Object);
  friend class Class;
};

class UnlinkedCall : public Object {
 public:
  RawString* target_name() const { return raw_ptr()->target_name_; }
  void set_target_name(const String& target_name) const;
  RawArray* args_descriptor() const { return raw_ptr()->args_descriptor_; }
  void set_args_descriptor(const Array& args_descriptor) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawUnlinkedCall));
  }

  static RawUnlinkedCall* New();

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(UnlinkedCall, Object);
  friend class Class;
};

// Object holding information about an IC: test classes and their
// corresponding targets. The owner of the ICData can be either the function
// or the original ICData object. In case of background compilation we
// copy the ICData in a child object, thus freezing it during background
// compilation. Code may contain only original ICData objects.
class ICData : public Object {
 public:
  RawFunction* Owner() const;

  RawICData* Original() const;

  void SetOriginal(const ICData& value) const;

  bool IsOriginal() const { return Original() == this->raw(); }

  RawString* target_name() const { return raw_ptr()->target_name_; }

  RawArray* arguments_descriptor() const { return raw_ptr()->args_descriptor_; }

  intptr_t NumArgsTested() const;

  intptr_t TypeArgsLen() const;

  intptr_t deopt_id() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return -1;
#else
    return raw_ptr()->deopt_id_;
#endif
  }

  bool IsImmutable() const;

  void Reset(Zone* zone) const;
  void ResetSwitchable(Zone* zone) const;

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
    return RoundedAllocationSize(sizeof(RawICData));
  }

  static intptr_t target_name_offset() {
    return OFFSET_OF(RawICData, target_name_);
  }

  static intptr_t state_bits_offset() {
    return OFFSET_OF(RawICData, state_bits_);
  }

  static intptr_t NumArgsTestedShift() { return kNumArgsTestedPos; }

  static intptr_t NumArgsTestedMask() {
    return ((1 << kNumArgsTestedSize) - 1) << kNumArgsTestedPos;
  }

  static intptr_t arguments_descriptor_offset() {
    return OFFSET_OF(RawICData, args_descriptor_);
  }

  static intptr_t ic_data_offset() { return OFFSET_OF(RawICData, ic_data_); }

  static intptr_t owner_offset() { return OFFSET_OF(RawICData, owner_); }

  // Replaces entry |index| with the sentinel.
  void WriteSentinelAt(intptr_t index) const;

  // Clears the count for entry |index|.
  void ClearCountAt(intptr_t index) const;

  // Clear all entries with the sentinel value (but will preserve initial
  // smi smi checks).
  void ClearWithSentinel() const;

  // Clear all entries with the sentinel value and reset the first entry
  // with the dummy target entry.
  void ClearAndSetStaticTarget(const Function& func) const;

  // Returns the first index that should be used to for a new entry. Will
  // grow the array if necessary.
  RawArray* FindFreeIndex(intptr_t* index) const;

  void DebugDump() const;

  // Returns true if this is a two arg smi operation.
  bool AddSmiSmiCheckForFastSmiStubs() const;

  // Used for unoptimized static calls when no class-ids are checked.
  void AddTarget(const Function& target) const;

  // Adding checks.

  // Adds one more class test to ICData. Length of 'classes' must be equal to
  // the number of arguments tested. Use only for num_args_tested > 1.
  void AddCheck(const GrowableArray<intptr_t>& class_ids,
                const Function& target,
                intptr_t count = 1) const;
  // Adds sorted so that Smi is the first class-id. Use only for
  // num_args_tested == 1.
  void AddReceiverCheck(intptr_t receiver_class_id,
                        const Function& target,
                        intptr_t count = 1) const;

  // Does entry |index| contain the sentinel value?
  bool IsSentinelAt(intptr_t index) const;

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

  RawFunction* GetTargetAt(intptr_t index) const;
  RawFunction* GetTargetForReceiverClassId(intptr_t class_id,
                                           intptr_t* count_return) const;

  RawObject* GetTargetOrCodeAt(intptr_t index) const;
  void SetCodeAt(intptr_t index, const Code& value) const;
  void SetEntryPointAt(intptr_t index, const Smi& value) const;

  void IncrementCountAt(intptr_t index, intptr_t value) const;
  void SetCountAt(intptr_t index, intptr_t value) const;
  intptr_t GetCountAt(intptr_t index) const;
  intptr_t AggregateCount() const;

  // Returns this->raw() if num_args_tested == 1 and arg_nr == 1, otherwise
  // returns a new ICData object containing only unique arg_nr checks.
  // Returns only used entries.
  RawICData* AsUnaryClassChecksForArgNr(intptr_t arg_nr) const;
  RawICData* AsUnaryClassChecks() const {
    return AsUnaryClassChecksForArgNr(0);
  }
  RawICData* AsUnaryClassChecksForCid(intptr_t cid,
                                      const Function& target) const;

  // Returns ICData with aggregated receiver count, sorted by highest count.
  // Smi not first!! (the convention for ICData used in code generation is that
  // Smi check is first)
  // Used for printing and optimizations.
  RawICData* AsUnaryClassChecksSortedByCount() const;

  // Consider only used entries.
  bool AllTargetsHaveSameOwner(intptr_t owner_cid) const;
  bool AllReceiversAreNumbers() const;
  bool HasOneTarget() const;
  bool HasReceiverClassId(intptr_t class_id) const;

  static RawICData* New(const Function& owner,
                        const String& target_name,
                        const Array& arguments_descriptor,
                        intptr_t deopt_id,
                        intptr_t num_args_tested,
                        bool is_static_call);
  static RawICData* NewFrom(const ICData& from, intptr_t num_args_tested);

  // Generates a new ICData with descriptor and data array copied (deep clone).
  static RawICData* Clone(const ICData& from);

  static intptr_t TestEntryLengthFor(intptr_t num_args);

  static intptr_t TargetIndexFor(intptr_t num_args) { return num_args; }
  static intptr_t CodeIndexFor(intptr_t num_args) { return num_args; }

  static intptr_t CountIndexFor(intptr_t num_args) { return (num_args + 1); }
  static intptr_t EntryPointIndexFor(intptr_t num_args) {
    return (num_args + 1);
  }

  bool IsUsedAt(intptr_t i) const;

  void GetUsedCidsForTwoArgs(GrowableArray<intptr_t>* first,
                             GrowableArray<intptr_t>* second) const;

  void PrintToJSONArray(const JSONArray& jsarray,
                        TokenPosition token_pos) const;

  // Initialize the preallocated empty ICData entry arrays.
  static void InitOnce();

  enum { kCachedICDataArrayCount = 4 };

#if defined(TAG_IC_DATA)
  void set_tag(intptr_t value) const;
  intptr_t tag() const { return raw_ptr()->tag_; }
#endif

  void SetIsStaticCall(bool static_call) const;
  bool is_static_call() const;

 private:
  static RawICData* New();

  RawArray* ic_data() const { return raw_ptr()->ic_data_; }

  void set_owner(const Function& value) const;
  void set_target_name(const String& value) const;
  void set_arguments_descriptor(const Array& value) const;
  void set_deopt_id(intptr_t value) const;
  void SetNumArgsTested(intptr_t value) const;
  void set_ic_data_array(const Array& value) const;
  void set_state_bits(uint32_t bits) const;

  bool ValidateInterceptor(const Function& target) const;

  enum {
    kNumArgsTestedPos = 0,
    kNumArgsTestedSize = 2,
    kDeoptReasonPos = kNumArgsTestedPos + kNumArgsTestedSize,
    kDeoptReasonSize = kLastRecordedDeoptReason + 1,
    kStaticCallPos = kDeoptReasonPos + kDeoptReasonSize,
    kStaticCallSize = 1,
  };

  class NumArgsTestedBits : public BitField<uint32_t,
                                            uint32_t,
                                            kNumArgsTestedPos,
                                            kNumArgsTestedSize> {};
  class DeoptReasonBits : public BitField<uint32_t,
                                          uint32_t,
                                          ICData::kDeoptReasonPos,
                                          ICData::kDeoptReasonSize> {};
  class StaticCallBit : public BitField<uint32_t,
                                        bool,
                                        ICData::kStaticCallPos,
                                        ICData::kStaticCallSize> {};
#if defined(DEBUG)
  // Used in asserts to verify that a check is not added twice.
  bool HasCheck(const GrowableArray<intptr_t>& cids) const;
#endif  // DEBUG

  intptr_t TestEntryLength() const;
  static RawArray* NewNonCachedEmptyICDataArray(intptr_t num_args_tested);
  static RawArray* CachedEmptyICDataArray(intptr_t num_args_tested);
  static RawICData* NewDescriptor(Zone* zone,
                                  const Function& owner,
                                  const String& target_name,
                                  const Array& arguments_descriptor,
                                  intptr_t deopt_id,
                                  intptr_t num_args_tested,
                                  bool is_static_call);

  static void WriteSentinel(const Array& data, intptr_t test_entry_length);

  // A cache of VM heap allocated preinitialized empty ic data entry arrays.
  static RawArray* cached_icdata_arrays_[kCachedICDataArrayCount];

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ICData, Object);
  friend class Class;
  friend class SnapshotWriter;
  friend class Serializer;
  friend class Deserializer;
};

class Function : public Object {
 public:
  RawString* name() const { return raw_ptr()->name_; }
  RawString* UserVisibleName() const;  // Same as scrubbed name.
  RawString* QualifiedScrubbedName() const {
    return QualifiedName(kScrubbedName);
  }
  RawString* QualifiedUserVisibleName() const {
    return QualifiedName(kUserVisibleName);
  }
  virtual RawString* DictionaryName() const { return name(); }

  RawString* GetSource() const;

  // Return the type of this function's signature. It may not be canonical yet.
  // For example, if this function has a signature of the form
  // '(T, [B, C]) => R', where 'T' and 'R' are type parameters of the
  // owner class of this function, then its signature type is a parameterized
  // function type with uninstantiated type arguments 'T' and 'R' as elements of
  // its type argument vector.
  RawType* SignatureType() const;
  RawType* ExistingSignatureType() const;

  // Update the signature type (with a canonical version).
  void SetSignatureType(const Type& value) const;

  // Return a new function with instantiated result and parameter types.
  RawFunction* InstantiateSignatureFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      Heap::Space space) const;

  // Build a string of the form '<T>(T, {B b, C c}) => R' representing the
  // internal signature of the given function. In this example, T is a type
  // parameter of this function and R is a type parameter of class C, the owner
  // of the function. B and C are not type parameters.
  RawString* Signature() const { return BuildSignature(kInternalName); }

  // Build a string of the form '<T>(T, {B b, C c}) => R' representing the
  // user visible signature of the given function. In this example, T is a type
  // parameter of this function and R is a type parameter of class C, the owner
  // of the function. B and C are not type parameters.
  // Implicit parameters are hidden.
  RawString* UserVisibleSignature() const {
    return BuildSignature(kUserVisibleName);
  }

  // Returns true if the signature of this function is instantiated, i.e. if it
  // does not involve generic parameter types or generic result type.
  // Note that function type parameters declared by this function do not make
  // its signature uninstantiated, only type parameters declared by parent
  // generic functions or class type parameters.
  bool HasInstantiatedSignature(Genericity genericity = kAny,
                                intptr_t num_free_fun_type_params = kMaxInt32,
                                TrailPtr trail = NULL) const;

  // Build a string of the form 'T, {B b, C c}' representing the user
  // visible formal parameters of the function.
  RawString* UserVisibleFormalParameters() const;

  // Reloading support:
  void Reparent(const Class& new_cls) const;
  void ZeroEdgeCounters() const;

  RawClass* Owner() const;
  RawClass* origin() const;
  RawScript* script() const;
  RawObject* RawOwner() const { return raw_ptr()->owner_; }

  RawRegExp* regexp() const;
  intptr_t string_specialization_cid() const;
  bool is_sticky_specialization() const;
  void SetRegExpData(const RegExp& regexp,
                     intptr_t string_specialization_cid,
                     bool sticky) const;

  RawString* native_name() const;
  void set_native_name(const String& name) const;

  RawAbstractType* result_type() const { return raw_ptr()->result_type_; }
  void set_result_type(const AbstractType& value) const;

  RawAbstractType* ParameterTypeAt(intptr_t index) const;
  void SetParameterTypeAt(intptr_t index, const AbstractType& value) const;
  RawArray* parameter_types() const { return raw_ptr()->parameter_types_; }
  void set_parameter_types(const Array& value) const;

  // Parameter names are valid for all valid parameter indices, and are not
  // limited to named optional parameters.
  RawString* ParameterNameAt(intptr_t index) const;
  void SetParameterNameAt(intptr_t index, const String& value) const;
  RawArray* parameter_names() const { return raw_ptr()->parameter_names_; }
  void set_parameter_names(const Array& value) const;

  // The type parameters (and their bounds) are specified as an array of
  // TypeParameter.
  RawTypeArguments* type_parameters() const {
    return raw_ptr()->type_parameters_;
  }
  void set_type_parameters(const TypeArguments& value) const;
  intptr_t NumTypeParameters(Thread* thread) const;
  intptr_t NumTypeParameters() const {
    return NumTypeParameters(Thread::Current());
  }

  // Returns true if this function has the same number of type parameters with
  // equal bounds as the other function. Type parameter names are ignored.
  bool HasSameTypeParametersAndBounds(const Function& other) const;

  // Return the number of type parameters declared in parent generic functions.
  intptr_t NumParentTypeParameters() const;

  // Print the signature type of this function and of all of its parents.
  void PrintSignatureTypes() const;

  // Return a TypeParameter if the type_name is a type parameter of this
  // function or of one of its parent functions.
  // Unless NULL, adjust function_level accordingly (in and out parameter).
  // Return null otherwise.
  RawTypeParameter* LookupTypeParameter(const String& type_name,
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
  RawCode* EnsureHasCode() const;

  // Disables optimized code and switches to unoptimized code (or the lazy
  // compilation stub).
  void SwitchToLazyCompiledUnoptimizedCode() const;

  // Compiles unoptimized code (if necessary) and attaches it to the function.
  void EnsureHasCompiledUnoptimizedCode() const;

  // Return the most recently compiled and installed code for this function.
  // It is not the only Code object that points to this function.
  RawCode* CurrentCode() const { return raw_ptr()->code_; }

  RawCode* unoptimized_code() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return static_cast<RawCode*>(Object::null());
#else
    return raw_ptr()->unoptimized_code_;
#endif
  }
  void set_unoptimized_code(const Code& value) const;
  bool HasCode() const;

  static intptr_t code_offset() { return OFFSET_OF(RawFunction, code_); }

  static intptr_t entry_point_offset() {
    return OFFSET_OF(RawFunction, entry_point_);
  }

  virtual intptr_t Hash() const;

  // Returns true if there is at least one debugger breakpoint
  // set in this function.
  bool HasBreakpoint() const;

  RawContextScope* context_scope() const;
  void set_context_scope(const ContextScope& value) const;

  RawField* LookupImplicitGetterSetterField() const;

  // Enclosing function of this local function.
  RawFunction* parent_function() const;

  void set_extracted_method_closure(const Function& function) const;
  RawFunction* extracted_method_closure() const;

  void set_saved_args_desc(const Array& array) const;
  RawArray* saved_args_desc() const;

  bool IsMethodExtractor() const {
    return kind() == RawFunction::kMethodExtractor;
  }

  bool IsNoSuchMethodDispatcher() const {
    return kind() == RawFunction::kNoSuchMethodDispatcher;
  }

  bool IsInvokeFieldDispatcher() const {
    return kind() == RawFunction::kInvokeFieldDispatcher;
  }

  // Returns true iff an implicit closure function has been created
  // for this function.
  bool HasImplicitClosureFunction() const {
    return implicit_closure_function() != null();
  }

  // Returns true iff a converted closure function has been created
  // for this function.
  bool HasConvertedClosureFunction() const {
    return converted_closure_function() != null();
  }

  // Returns the closure function implicitly created for this function.  If none
  // exists yet, create one and remember it.  Implicit closure functions are
  // used in VM Closure instances that represent results of tear-off operations.
  RawFunction* ImplicitClosureFunction() const;
  void DropUncompiledImplicitClosureFunction() const;

  // Returns the converted closure function created for this function.
  // If none exists yet, create one and remember it.  See the comment on
  // ConvertedClosureFunction definition in runtime/vm/object.cc for elaborate
  // explanation.
  RawFunction* ConvertedClosureFunction() const;
  void DropUncompiledConvertedClosureFunction() const;

  // Return the closure implicitly created for this function.
  // If none exists yet, create one and remember it.
  RawInstance* ImplicitStaticClosure() const;

  RawInstance* ImplicitInstanceClosure(const Instance& receiver) const;

  intptr_t ComputeClosureHash() const;

  // Redirection information for a redirecting factory.
  bool IsRedirectingFactory() const;
  RawType* RedirectionType() const;
  void SetRedirectionType(const Type& type) const;
  RawString* RedirectionIdentifier() const;
  void SetRedirectionIdentifier(const String& identifier) const;
  RawFunction* RedirectionTarget() const;
  void SetRedirectionTarget(const Function& target) const;

  RawFunction::Kind kind() const {
    return KindBits::decode(raw_ptr()->kind_tag_);
  }

  RawFunction::AsyncModifier modifier() const {
    return ModifierBits::decode(raw_ptr()->kind_tag_);
  }

  static const char* KindToCString(RawFunction::Kind kind);

  bool IsGenerativeConstructor() const {
    return (kind() == RawFunction::kConstructor) && !is_static();
  }
  bool IsImplicitConstructor() const;
  bool IsFactory() const {
    return (kind() == RawFunction::kConstructor) && is_static();
  }
  bool IsDynamicFunction(bool allow_abstract = false) const {
    if (is_static() || (!allow_abstract && is_abstract())) {
      return false;
    }
    switch (kind()) {
      case RawFunction::kRegularFunction:
      case RawFunction::kGetterFunction:
      case RawFunction::kSetterFunction:
      case RawFunction::kImplicitGetter:
      case RawFunction::kImplicitSetter:
      case RawFunction::kMethodExtractor:
      case RawFunction::kNoSuchMethodDispatcher:
      case RawFunction::kInvokeFieldDispatcher:
        return true;
      case RawFunction::kClosureFunction:
      case RawFunction::kImplicitClosureFunction:
      case RawFunction::kSignatureFunction:
      case RawFunction::kConstructor:
      case RawFunction::kImplicitStaticFinalGetter:
      case RawFunction::kIrregexpFunction:
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
      case RawFunction::kRegularFunction:
      case RawFunction::kGetterFunction:
      case RawFunction::kSetterFunction:
      case RawFunction::kImplicitGetter:
      case RawFunction::kImplicitSetter:
      case RawFunction::kImplicitStaticFinalGetter:
      case RawFunction::kIrregexpFunction:
        return true;
      case RawFunction::kClosureFunction:
      case RawFunction::kImplicitClosureFunction:
      case RawFunction::kSignatureFunction:
      case RawFunction::kConstructor:
      case RawFunction::kMethodExtractor:
      case RawFunction::kNoSuchMethodDispatcher:
      case RawFunction::kInvokeFieldDispatcher:
        return false;
      default:
        UNREACHABLE();
        return false;
    }
  }
  bool IsInFactoryScope() const;

  TokenPosition token_pos() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return TokenPosition();
#else
    return raw_ptr()->token_pos_;
#endif
  }
  void set_token_pos(TokenPosition value) const;

  TokenPosition end_token_pos() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return TokenPosition();
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

  intptr_t num_fixed_parameters() const {
    return raw_ptr()->num_fixed_parameters_;
  }
  void set_num_fixed_parameters(intptr_t value) const;

  bool HasOptionalParameters() const {
    return raw_ptr()->num_optional_parameters_ != 0;
  }
  bool HasOptionalPositionalParameters() const {
    return raw_ptr()->num_optional_parameters_ > 0;
  }
  bool HasOptionalNamedParameters() const {
    return raw_ptr()->num_optional_parameters_ < 0;
  }
  intptr_t NumOptionalParameters() const {
    const intptr_t num_opt_params = raw_ptr()->num_optional_parameters_;
    return (num_opt_params >= 0) ? num_opt_params : -num_opt_params;
  }
  void SetNumOptionalParameters(intptr_t num_optional_parameters,
                                bool are_optional_positional) const;

  intptr_t NumOptionalPositionalParameters() const {
    const intptr_t num_opt_params = raw_ptr()->num_optional_parameters_;
    return (num_opt_params > 0) ? num_opt_params : 0;
  }
  intptr_t NumOptionalNamedParameters() const {
    const intptr_t num_opt_params = raw_ptr()->num_optional_parameters_;
    return (num_opt_params < 0) ? -num_opt_params : 0;
  }

  intptr_t NumParameters() const;

  intptr_t NumImplicitParameters() const;

  static intptr_t usage_counter_offset() {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return 0;
#else
    return OFFSET_OF(RawFunction, usage_counter_);
#endif
  }
  intptr_t usage_counter() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return raw_ptr()->usage_counter_;
#endif
  }
  void set_usage_counter(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    // TODO(Srdjan): Assert that this is thread-safe, i.e., only
    // set from mutator-thread or while at a safepoint (e.g., during marking).
    StoreNonPointer(&raw_ptr()->usage_counter_, value);
#endif
  }

  int8_t deoptimization_counter() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return raw_ptr()->deoptimization_counter_;
#endif
  }
  void set_deoptimization_counter(int8_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    StoreNonPointer(&raw_ptr()->deoptimization_counter_, value);
#endif
  }

  static const intptr_t kMaxInstructionCount = (1 << 16) - 1;
  intptr_t optimized_instruction_count() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return 0;
#else
    return raw_ptr()->optimized_instruction_count_;
#endif
  }
  void set_optimized_instruction_count(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    if (value > kMaxInstructionCount) {
      value = kMaxInstructionCount;
    }
    StoreNonPointer(&raw_ptr()->optimized_instruction_count_,
                    static_cast<uint16_t>(value));
#endif
  }

  intptr_t optimized_call_site_count() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return raw_ptr()->optimized_call_site_count_;
#endif
  }
  void set_optimized_call_site_count(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value >= 0);
    if (value > kMaxInstructionCount) {
      value = kMaxInstructionCount;
    }
    StoreNonPointer(&raw_ptr()->optimized_call_site_count_,
                    static_cast<uint16_t>(value));
#endif
  }

  intptr_t kernel_offset() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return raw_ptr()->kernel_offset_;
#endif
  }

  void set_kernel_offset(intptr_t kernel_offset) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    StoreNonPointer(&raw_ptr()->kernel_offset_, kernel_offset);
#endif
  }

  RawTypedData* kernel_data() const { return raw_ptr()->kernel_data_; }
  void set_kernel_data(const TypedData& data) const;

  bool IsOptimizable() const;
  void SetIsOptimizable(bool value) const;

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

  // Returns true if this function has parameters that are compatible with the
  // parameters of the other function in order for this function to override the
  // other function.
  bool HasCompatibleParametersWith(const Function& other,
                                   Error* bound_error) const;

  // Returns true if the type of this function is a subtype of the type of
  // the other function.
  bool IsSubtypeOf(const Function& other,
                   Error* bound_error,
                   TrailPtr bound_trail,
                   Heap::Space space) const {
    return TypeTest(kIsSubtypeOf, other, bound_error, bound_trail, space);
  }

  // Returns true if the type of this function is more specific than the type of
  // the other function.
  bool IsMoreSpecificThan(const Function& other,
                          Error* bound_error,
                          TrailPtr bound_trail,
                          Heap::Space space) const {
    return TypeTest(kIsMoreSpecificThan, other, bound_error, bound_trail,
                    space);
  }

  // Check the subtype or 'more specific' relationship.
  bool TypeTest(TypeTestKind test_kind,
                const Function& other,
                Error* bound_error,
                TrailPtr bound_trail,
                Heap::Space space) const;

  bool IsDispatcherOrImplicitAccessor() const {
    switch (kind()) {
      case RawFunction::kImplicitGetter:
      case RawFunction::kImplicitSetter:
      case RawFunction::kNoSuchMethodDispatcher:
      case RawFunction::kInvokeFieldDispatcher:
        return true;
      default:
        return false;
    }
  }

  // Returns true if this function represents an explicit getter function.
  bool IsGetterFunction() const {
    return kind() == RawFunction::kGetterFunction;
  }

  // Returns true if this function represents an implicit getter function.
  bool IsImplicitGetterFunction() const {
    return kind() == RawFunction::kImplicitGetter;
  }

  // Returns true if this function represents an explicit setter function.
  bool IsSetterFunction() const {
    return kind() == RawFunction::kSetterFunction;
  }

  // Returns true if this function represents an implicit setter function.
  bool IsImplicitSetterFunction() const {
    return kind() == RawFunction::kImplicitSetter;
  }

  // Returns true if this function represents a (possibly implicit) closure
  // function.
  bool IsClosureFunction() const {
    RawFunction::Kind k = kind();
    return (k == RawFunction::kClosureFunction) ||
           (k == RawFunction::kImplicitClosureFunction);
  }

  // Returns true if this function represents a generated irregexp function.
  bool IsIrregexpFunction() const {
    return kind() == RawFunction::kIrregexpFunction;
  }

  // Returns true if this function represents an implicit closure function.
  bool IsImplicitClosureFunction() const {
    return kind() == RawFunction::kImplicitClosureFunction;
  }

  // Returns true if this function represents a converted closure function.
  bool IsConvertedClosureFunction() const {
    return kind() == RawFunction::kConvertedClosureFunction;
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
  static bool IsImplicitStaticClosureFunction(RawFunction* func);

  // Returns true if this function represents an implicit instance closure
  // function.
  bool IsImplicitInstanceClosureFunction() const {
    return IsImplicitClosureFunction() && !is_static();
  }

  bool IsConstructorClosureFunction() const;

  // Returns true if this function represents a local function.
  bool IsLocalFunction() const { return parent_function() != Function::null(); }

  // Returns true if this function represents a signature function without code.
  bool IsSignatureFunction() const {
    return kind() == RawFunction::kSignatureFunction;
  }
  static bool IsSignatureFunction(RawFunction* function) {
    NoSafepointScope no_safepoint;
    return KindBits::decode(function->ptr()->kind_tag_) ==
           RawFunction::kSignatureFunction;
  }

  bool IsAsyncFunction() const { return modifier() == RawFunction::kAsync; }

  bool IsAsyncClosure() const {
    return is_generated_body() &&
           Function::Handle(parent_function()).IsAsyncFunction();
  }

  bool IsGenerator() const {
    return (modifier() & RawFunction::kGeneratorBit) != 0;
  }

  bool IsSyncGenerator() const { return modifier() == RawFunction::kSyncGen; }

  bool IsSyncGenClosure() const {
    return is_generated_body() &&
           Function::Handle(parent_function()).IsSyncGenerator();
  }

  bool IsGeneratorClosure() const {
    return is_generated_body() &&
           Function::Handle(parent_function()).IsGenerator();
  }

  bool IsAsyncGenerator() const { return modifier() == RawFunction::kAsyncGen; }

  bool IsAsyncGenClosure() const {
    return is_generated_body() &&
           Function::Handle(parent_function()).IsAsyncGenerator();
  }

  bool IsAsyncOrGenerator() const {
    return modifier() != RawFunction::kNoModifier;
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawFunction));
  }

  static RawFunction* EvaluateHelper(const Class& cls,
                                     const String& expr,
                                     const Array& param_names,
                                     bool is_static);

  static RawFunction* New(const String& name,
                          RawFunction::Kind kind,
                          bool is_static,
                          bool is_const,
                          bool is_abstract,
                          bool is_external,
                          bool is_native,
                          const Object& owner,
                          TokenPosition token_pos,
                          Heap::Space space = Heap::kOld);

  // Allocates a new Function object representing a closure function
  // with given kind - kClosureFunction, kImplicitClosureFunction or
  // kConvertedClosureFunction.
  static RawFunction* NewClosureFunctionWithKind(RawFunction::Kind kind,
                                                 const String& name,
                                                 const Function& parent,
                                                 TokenPosition token_pos);

  // Allocates a new Function object representing a closure function.
  static RawFunction* NewClosureFunction(const String& name,
                                         const Function& parent,
                                         TokenPosition token_pos);

  // Allocates a new Function object representing an implicit closure function.
  static RawFunction* NewImplicitClosureFunction(const String& name,
                                                 const Function& parent,
                                                 TokenPosition token_pos);

  // Allocates a new Function object representing a converted closure function.
  static RawFunction* NewConvertedClosureFunction(const String& name,
                                                  const Function& parent,
                                                  TokenPosition token_pos);

  // Allocates a new Function object representing a signature function.
  // The owner is the scope class of the function type.
  // The parent is the enclosing function or null if none.
  static RawFunction* NewSignatureFunction(const Object& owner,
                                           const Function& parent,
                                           TokenPosition token_pos,
                                           Heap::Space space = Heap::kOld);

  static RawFunction* NewEvalFunction(const Class& owner,
                                      const Script& script,
                                      bool is_static);

  RawFunction* CreateMethodExtractor(const String& getter_name) const;
  RawFunction* GetMethodExtractor(const String& getter_name) const;

  // Allocate new function object, clone values from this function. The
  // owner of the clone is new_owner.
  RawFunction* Clone(const Class& new_owner) const;

  // Slow function, use in asserts to track changes in important library
  // functions.
  int32_t SourceFingerprint() const;

  // Return false and report an error if the fingerprint does not match.
  bool CheckSourceFingerprint(const char* prefix, int32_t fp) const;

  // Works with map [deopt-id] -> ICData.
  void SaveICDataMap(
      const ZoneGrowableArray<const ICData*>& deopt_id_to_ic_data,
      const Array& edge_counters_array) const;
  // Uses 'ic_data_array' to populate the table 'deopt_id_to_ic_data'. Clone
  // ic_data (array and descriptor) if 'clone_ic_data' is true.
  void RestoreICDataMap(ZoneGrowableArray<const ICData*>* deopt_id_to_ic_data,
                        bool clone_ic_data) const;

  RawArray* ic_data_array() const;
  void ClearICDataArray() const;

  // Sets deopt reason in all ICData-s with given deopt_id.
  void SetDeoptReasonForAll(intptr_t deopt_id, ICData::DeoptReasonId reason);

  void set_modifier(RawFunction::AsyncModifier value) const;

  // 'was_compiled' is true if the function was compiled once in this
  // VM instantiation. It is independent from presence of type feedback
  // (ic_data_array) and code, which may be loaded from a snapshot.
  void set_was_compiled(bool value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    StoreNonPointer(&raw_ptr()->was_compiled_, value ? 1 : 0);
#endif
  }
  bool was_compiled() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return true;
#else
    return raw_ptr()->was_compiled_ == 1;
#endif
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
// optimizable: Candidate for going through the optimizing compiler. False for
//              some functions known to be execute infrequently and functions
//              which have been de-optimized too many times.
// instrinsic: Has a hand-written assembly prologue.
// inlinable: Candidate for inlining. False for functions with features we
//            don't support during inlining (e.g., optional parameters),
//            functions which are too big, etc.
// native: Bridge to C/C++ code.
// redirecting: Redirecting generative or factory constructor.
// external: Just a declaration that expects to be defined in another patch
//           file.

#define FOR_EACH_FUNCTION_KIND_BIT(V)                                          \
  V(Static, is_static)                                                         \
  V(Const, is_const)                                                           \
  V(Abstract, is_abstract)                                                     \
  V(Reflectable, is_reflectable)                                               \
  V(Visible, is_visible)                                                       \
  V(Debuggable, is_debuggable)                                                 \
  V(Optimizable, is_optimizable)                                               \
  V(Inlinable, is_inlinable)                                                   \
  V(Intrinsic, is_intrinsic)                                                   \
  V(Native, is_native)                                                         \
  V(Redirecting, is_redirecting)                                               \
  V(External, is_external)                                                     \
  V(AllowsHoistingCheckClass, allows_hoisting_check_class)                     \
  V(AllowsBoundsCheckGeneralization, allows_bounds_check_generalization)       \
  V(GeneratedBody, is_generated_body)                                          \
  V(AlwaysInline, always_inline)                                               \
  V(PolymorphicTarget, is_polymorphic_target)

#define DEFINE_ACCESSORS(name, accessor_name)                                  \
  void set_##accessor_name(bool value) const {                                 \
    set_kind_tag(name##Bit::update(value, raw_ptr()->kind_tag_));              \
  }                                                                            \
  bool accessor_name() const { return name##Bit::decode(raw_ptr()->kind_tag_); }
  FOR_EACH_FUNCTION_KIND_BIT(DEFINE_ACCESSORS)
#undef DEFINE_ACCESSORS

 private:
  void set_ic_data_array(const Array& value) const;
  void SetInstructionsSafe(const Code& value) const;

  enum KindTagBits {
    kKindTagPos = 0,
    kKindTagSize = 4,
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
                 (kBitsPerByte *
                  sizeof(static_cast<RawFunction*>(0)->kind_tag_)));

  class KindBits : public BitField<uint32_t,
                                   RawFunction::Kind,
                                   kKindTagPos,
                                   kKindTagSize> {};

  class RecognizedBits : public BitField<uint32_t,
                                         MethodRecognizer::Kind,
                                         kRecognizedTagPos,
                                         kRecognizedTagSize> {};
  class ModifierBits : public BitField<uint32_t,
                                       RawFunction::AsyncModifier,
                                       kModifierPos,
                                       kModifierSize> {};

#define DEFINE_BIT(name, _)                                                    \
  class name##Bit : public BitField<uint32_t, bool, k##name##Bit, 1> {};
  FOR_EACH_FUNCTION_KIND_BIT(DEFINE_BIT)
#undef DEFINE_BIT

  void set_name(const String& value) const;
  void set_kind(RawFunction::Kind value) const;
  void set_parent_function(const Function& value) const;
  void set_owner(const Object& value) const;
  RawFunction* implicit_closure_function() const;
  void set_implicit_closure_function(const Function& value) const;
  RawFunction* converted_closure_function() const;
  void set_converted_closure_function(const Function& value) const;
  RawInstance* implicit_static_closure() const;
  void set_implicit_static_closure(const Instance& closure) const;
  RawScript* eval_script() const;
  void set_eval_script(const Script& value) const;
  void set_num_optional_parameters(intptr_t value) const;  // Encoded value.
  void set_kind_tag(uint32_t value) const;
  void set_data(const Object& value) const;

  static RawFunction* New(Heap::Space space = Heap::kOld);

  RawString* QualifiedName(NameVisibility name_visibility) const;

  void BuildSignatureParameters(
      Thread* thread,
      Zone* zone,
      NameVisibility name_visibility,
      GrowableHandlePtrArray<const String>* pieces) const;
  RawString* BuildSignature(NameVisibility name_visibility) const;

  // Checks the type of the formal parameter at the given position for
  // subtyping or 'more specific' relationship between the type of this function
  // and the type of the other function.
  bool TestParameterType(TypeTestKind test_kind,
                         intptr_t parameter_position,
                         intptr_t other_parameter_position,
                         const Function& other,
                         Error* bound_error,
                         TrailPtr bound_trail,
                         Heap::Space space) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Function, Object);
  friend class Class;
  friend class SnapshotWriter;
  friend class Parser;  // For set_eval_script.
  // RawFunction::VisitFunctionPointers accesses the private constructor of
  // Function.
  friend class RawFunction;
  friend class ClassFinalizer;  // To reset parent_function.
  friend class Type;            // To adjust parent_function.
};

class ClosureData : public Object {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawClosureData));
  }

 private:
  RawContextScope* context_scope() const { return raw_ptr()->context_scope_; }
  void set_context_scope(const ContextScope& value) const;

  // Enclosing function of this local function.
  RawFunction* parent_function() const { return raw_ptr()->parent_function_; }
  void set_parent_function(const Function& value) const;

  // Signature type of this closure function.
  RawType* signature_type() const { return raw_ptr()->signature_type_; }
  void set_signature_type(const Type& value) const;

  RawInstance* implicit_static_closure() const { return raw_ptr()->closure_; }
  void set_implicit_static_closure(const Instance& closure) const;

  static RawClosureData* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ClosureData, Object);
  friend class Class;
  friend class Function;
  friend class HeapProfiler;
};

class SignatureData : public Object {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawSignatureData));
  }

 private:
  // Enclosing function of this signature function.
  RawFunction* parent_function() const { return raw_ptr()->parent_function_; }
  void set_parent_function(const Function& value) const;

  // Signature type of this signature function.
  RawType* signature_type() const { return raw_ptr()->signature_type_; }
  void set_signature_type(const Type& value) const;

  static RawSignatureData* New(Heap::Space space = Heap::kOld);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(SignatureData, Object);
  friend class Class;
  friend class Function;
  friend class HeapProfiler;
};

class RedirectionData : public Object {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawRedirectionData));
  }

 private:
  // The type specifies the class and type arguments of the target constructor.
  RawType* type() const { return raw_ptr()->type_; }
  void set_type(const Type& value) const;

  // The optional identifier specifies a named constructor.
  RawString* identifier() const { return raw_ptr()->identifier_; }
  void set_identifier(const String& value) const;

  // The resolved constructor or factory target of the redirection.
  RawFunction* target() const { return raw_ptr()->target_; }
  void set_target(const Function& value) const;

  static RawRedirectionData* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(RedirectionData, Object);
  friend class Class;
  friend class Function;
  friend class HeapProfiler;
};

class Field : public Object {
 public:
  RawField* Original() const;
  void SetOriginal(const Field& value) const;
  bool IsOriginal() const {
    if (IsNull()) {
      return true;
    }
    NoSafepointScope no_safepoint;
    return !raw_ptr()->owner_->IsField();
  }

  // Returns a field cloned from 'this'. 'this' is set as the
  // original field of result.
  RawField* CloneFromOriginal() const;

  RawString* name() const { return raw_ptr()->name_; }
  RawString* UserVisibleName() const;  // Same as scrubbed name.
  virtual RawString* DictionaryName() const { return name(); }

  bool is_static() const { return StaticBit::decode(raw_ptr()->kind_bits_); }
  bool is_instance() const { return !is_static(); }
  bool is_final() const { return FinalBit::decode(raw_ptr()->kind_bits_); }
  bool is_const() const { return ConstBit::decode(raw_ptr()->kind_bits_); }
  bool is_reflectable() const {
    return ReflectableBit::decode(raw_ptr()->kind_bits_);
  }
  void set_is_reflectable(bool value) const {
    ASSERT(IsOriginal());
    set_kind_bits(ReflectableBit::update(value, raw_ptr()->kind_bits_));
  }
  bool is_double_initialized() const {
    return DoubleInitializedBit::decode(raw_ptr()->kind_bits_);
  }
  // Called in parser after allocating field, immutable property otherwise.
  // Marks fields that are initialized with a simple double constant.
  void set_is_double_initialized(bool value) const {
    ASSERT(Thread::Current()->IsMutatorThread());
    ASSERT(IsOriginal());
    set_kind_bits(DoubleInitializedBit::update(value, raw_ptr()->kind_bits_));
  }

  intptr_t kernel_offset() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return NULL;
#else
    return raw_ptr()->kernel_offset_;
#endif
  }

  void set_kernel_offset(intptr_t kernel_offset) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
    StoreNonPointer(&raw_ptr()->kernel_offset_, kernel_offset);
#endif
  }

  RawTypedData* kernel_data() const { return raw_ptr()->kernel_data_; }
  void set_kernel_data(const TypedData& data) const;

  inline intptr_t Offset() const;
  // Called during class finalization.
  inline void SetOffset(intptr_t offset_in_bytes) const;

  inline RawInstance* StaticValue() const;
  inline void SetStaticValue(const Instance& value,
                             bool save_initial_value = false) const;

  RawClass* Owner() const;
  RawClass* Origin() const;  // Either mixin class, or same as owner().
  RawScript* Script() const;
  RawObject* RawOwner() const;

  RawAbstractType* type() const { return raw_ptr()->type_; }
  // Used by class finalizer, otherwise initialized in constructor.
  void SetFieldType(const AbstractType& value) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawField));
  }

  static RawField* New(const String& name,
                       bool is_static,
                       bool is_final,
                       bool is_const,
                       bool is_reflectable,
                       const Object& owner,
                       const AbstractType& type,
                       TokenPosition token_pos);

  static RawField* NewTopLevel(const String& name,
                               bool is_final,
                               bool is_const,
                               const Object& owner,
                               TokenPosition token_pos);

  // Allocate new field object, clone values from this field. The
  // owner of the clone is new_owner.
  RawField* Clone(const Class& new_owner) const;
  // Allocate new field object, clone values from this field. The
  // original is specified.
  RawField* Clone(const Field& original) const;

  static intptr_t instance_field_offset() {
    return OFFSET_OF(RawField, value_.offset_);
  }
  static intptr_t static_value_offset() {
    return OFFSET_OF(RawField, value_.static_value_);
  }

  static intptr_t kind_bits_offset() { return OFFSET_OF(RawField, kind_bits_); }

  TokenPosition token_pos() const { return raw_ptr()->token_pos_; }

  RawString* InitializingExpression() const;

  bool has_initializer() const {
    return HasInitializerBit::decode(raw_ptr()->kind_bits_);
  }
  // Called by parser after allocating field.
  void set_has_initializer(bool has_initializer) const {
    ASSERT(IsOriginal());
    ASSERT(Thread::Current()->IsMutatorThread());
    set_kind_bits(
        HasInitializerBit::update(has_initializer, raw_ptr()->kind_bits_));
  }

  // Return class id that any non-null value read from this field is guaranteed
  // to have or kDynamicCid if such class id is not known.
  // Stores to this field must update this information hence the name.
  intptr_t guarded_cid() const {
#if defined(DEGUG)
    Thread* thread = Thread::Current();
    ASSERT(!IsOriginal() || thread->IsMutator() || thread->IsAtSafepoint());
#endif
    return raw_ptr()->guarded_cid_;
  }

  void set_guarded_cid(intptr_t cid) const {
#if defined(DEGUG)
    Thread* thread = Thread::Current();
    ASSERT(!IsOriginal() || thread->IsMutator() || thread->IsAtSafepoint());
#endif
    StoreNonPointer(&raw_ptr()->guarded_cid_, cid);
  }
  static intptr_t guarded_cid_offset() {
    return OFFSET_OF(RawField, guarded_cid_);
  }
  // Return the list length that any list stored in this field is guaranteed
  // to have. If length is kUnknownFixedLength the length has not
  // been determined. If length is kNoFixedLength this field has multiple
  // list lengths associated with it and cannot be predicted.
  intptr_t guarded_list_length() const;
  void set_guarded_list_length(intptr_t list_length) const;
  static intptr_t guarded_list_length_offset() {
    return OFFSET_OF(RawField, guarded_list_length_);
  }
  intptr_t guarded_list_length_in_object_offset() const;
  void set_guarded_list_length_in_object_offset(intptr_t offset) const;
  static intptr_t guarded_list_length_in_object_offset_offset() {
    return OFFSET_OF(RawField, guarded_list_length_in_object_offset_);
  }

  bool needs_length_check() const {
    const bool r = guarded_list_length() >= Field::kUnknownFixedLength;
    ASSERT(!r || is_final());
    return r;
  }

  const char* GuardedPropertiesAsCString() const;

  intptr_t UnboxedFieldCid() const { return guarded_cid(); }

  bool is_unboxing_candidate() const {
    return UnboxingCandidateBit::decode(raw_ptr()->kind_bits_);
  }
  // Default 'true', set to false once optimizing compiler determines it should
  // be boxed.
  void set_is_unboxing_candidate(bool b) const {
    ASSERT(IsOriginal());
    set_kind_bits(UnboxingCandidateBit::update(b, raw_ptr()->kind_bits_));
  }

  enum {
    kUnknownLengthOffset = -1,
    kUnknownFixedLength = -1,
    kNoFixedLength = -2,
  };
  // Returns false if any value read from this field is guaranteed to be
  // not null.
  // Internally we is_nullable_ field contains either kNullCid (nullable) or
  // any other value (non-nullable) instead of boolean. This is done to simplify
  // guarding sequence in the generated code.
  bool is_nullable() const { return raw_ptr()->is_nullable_ == kNullCid; }
  void set_is_nullable(bool val) const {
    ASSERT(Thread::Current()->IsMutatorThread());
    StoreNonPointer(&raw_ptr()->is_nullable_, val ? kNullCid : kIllegalCid);
  }
  static intptr_t is_nullable_offset() {
    return OFFSET_OF(RawField, is_nullable_);
  }

  // Record store of the given value into this field. May trigger
  // deoptimization of dependent optimized code.
  void RecordStore(const Object& value) const;

  void InitializeGuardedListLengthInObjectOffset() const;

  // Return the list of optimized code objects that were optimized under
  // assumptions about guarded class id and nullability of this field.
  // These code objects must be deoptimized when field's properties change.
  // Code objects are held weakly via an indirection through WeakProperty.
  RawArray* dependent_code() const;
  void set_dependent_code(const Array& array) const;

  // Add the given code object to the list of dependent ones.
  void RegisterDependentCode(const Code& code) const;

  // Deoptimize all dependent code objects.
  void DeoptimizeDependentCode() const;

  // Used by background compiler to check consistency of field copy with its
  // original.
  bool IsConsistentWith(const Field& field) const;

  bool IsUninitialized() const;

  void EvaluateInitializer() const;

  RawFunction* PrecompiledInitializer() const {
    return raw_ptr()->initializer_.precompiled_;
  }
  void SetPrecompiledInitializer(const Function& initializer) const;
  bool HasPrecompiledInitializer() const;

  RawInstance* SavedInitialStaticValue() const {
    return raw_ptr()->initializer_.saved_value_;
  }
  void SetSavedInitialStaticValue(const Instance& value) const;

  // For static fields only. Constructs a closure that gets/sets the
  // field value.
  RawInstance* GetterClosure() const;
  RawInstance* SetterClosure() const;
  RawInstance* AccessorClosure(bool make_setter) const;

  // Constructs getter and setter names for fields and vice versa.
  static RawString* GetterName(const String& field_name);
  static RawString* GetterSymbol(const String& field_name);
  // Returns String::null() if getter symbol does not exist.
  static RawString* LookupGetterSymbol(const String& field_name);
  static RawString* SetterName(const String& field_name);
  static RawString* SetterSymbol(const String& field_name);
  // Returns String::null() if setter symbol does not exist.
  static RawString* LookupSetterSymbol(const String& field_name);
  static RawString* NameFromGetter(const String& getter_name);
  static RawString* NameFromSetter(const String& setter_name);
  static bool IsGetterName(const String& function_name);
  static bool IsSetterName(const String& function_name);

 private:
  static void InitializeNew(const Field& result,
                            const String& name,
                            bool is_static,
                            bool is_final,
                            bool is_const,
                            bool is_reflectable,
                            const Object& owner,
                            TokenPosition token_pos);
  friend class StoreInstanceFieldInstr;  // Generated code access to bit field.

  enum {
    kConstBit = 0,
    kStaticBit,
    kFinalBit,
    kHasInitializerBit,
    kUnboxingCandidateBit,
    kReflectableBit,
    kDoubleInitializedBit,
  };
  class ConstBit : public BitField<uint8_t, bool, kConstBit, 1> {};
  class StaticBit : public BitField<uint8_t, bool, kStaticBit, 1> {};
  class FinalBit : public BitField<uint8_t, bool, kFinalBit, 1> {};
  class HasInitializerBit
      : public BitField<uint8_t, bool, kHasInitializerBit, 1> {};
  class UnboxingCandidateBit
      : public BitField<uint8_t, bool, kUnboxingCandidateBit, 1> {};
  class ReflectableBit : public BitField<uint8_t, bool, kReflectableBit, 1> {};
  class DoubleInitializedBit
      : public BitField<uint8_t, bool, kDoubleInitializedBit, 1> {};

  // Update guarded cid and guarded length for this field. Returns true, if
  // deoptimization of dependent code is required.
  bool UpdateGuardedCidAndLength(const Object& value) const;

  // Force this field's guard to be dynamic and deoptimize dependent code.
  void ForceDynamicGuardedCidAndLength() const;

  void set_name(const String& value) const;
  void set_is_static(bool is_static) const {
    set_kind_bits(StaticBit::update(is_static, raw_ptr()->kind_bits_));
  }
  void set_is_final(bool is_final) const {
    set_kind_bits(FinalBit::update(is_final, raw_ptr()->kind_bits_));
  }
  void set_is_const(bool value) const {
    set_kind_bits(ConstBit::update(value, raw_ptr()->kind_bits_));
  }
  void set_owner(const Object& value) const {
    StorePointer(&raw_ptr()->owner_, value.raw());
  }
  void set_token_pos(TokenPosition token_pos) const {
    StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
  }
  void set_kind_bits(uint8_t value) const {
    StoreNonPointer(&raw_ptr()->kind_bits_, value);
  }

  static RawField* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Field, Object);
  friend class Class;
  friend class HeapProfiler;
  friend class RawField;
  friend class FieldSerializationCluster;
};

class LiteralToken : public Object {
 public:
  Token::Kind kind() const { return raw_ptr()->kind_; }
  RawString* literal() const { return raw_ptr()->literal_; }
  RawObject* value() const { return raw_ptr()->value_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawLiteralToken));
  }

  static RawLiteralToken* New();
  static RawLiteralToken* New(Token::Kind kind, const String& literal);

 private:
  void set_kind(Token::Kind kind) const {
    StoreNonPointer(&raw_ptr()->kind_, kind);
  }
  void set_literal(const String& literal) const;
  void set_value(const Object& value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(LiteralToken, Object);
  friend class Class;
};

class TokenStream : public Object {
 public:
  RawGrowableObjectArray* TokenObjects() const;
  void SetTokenObjects(const GrowableObjectArray& value) const;

  RawExternalTypedData* GetStream() const;
  void SetStream(const ExternalTypedData& stream) const;

  RawString* GenerateSource() const;
  RawString* GenerateSource(TokenPosition start, TokenPosition end) const;
  intptr_t ComputeSourcePosition(TokenPosition tok_pos) const;

  RawString* PrivateKey() const;

  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawTokenStream));
  }

  static RawTokenStream* New(intptr_t length);
  static RawTokenStream* New(const String& source,
                             const String& private_key,
                             bool use_shared_tokens);

  static void OpenSharedTokenList(Isolate* isolate);
  static void CloseSharedTokenList(Isolate* isolate);

  // The class Iterator encapsulates iteration over the tokens
  // in a TokenStream object.
  class Iterator : ValueObject {
   public:
    enum StreamType { kNoNewlines, kAllTokens };

    Iterator(Zone* zone,
             const TokenStream& tokens,
             TokenPosition token_pos,
             Iterator::StreamType stream_type = kNoNewlines);

    void SetStream(const TokenStream& tokens, TokenPosition token_pos);
    bool IsValid() const;

    inline Token::Kind CurrentTokenKind() const { return cur_token_kind_; }

    Token::Kind LookaheadTokenKind(intptr_t num_tokens);

    TokenPosition CurrentPosition() const;
    void SetCurrentPosition(TokenPosition token_pos);

    void Advance();

    RawObject* CurrentToken() const;
    RawString* CurrentLiteral() const;
    RawString* MakeLiteralToken(const Object& obj) const;

   private:
    // Read token from the token stream (could be a simple token or an index
    // into the token objects array for IDENT or literal tokens).
    intptr_t ReadToken() {
      int64_t value = stream_.ReadUnsigned();
      ASSERT((value >= 0) && (value <= kIntptrMax));
      return static_cast<intptr_t>(value);
    }

    TokenStream& tokens_;
    ExternalTypedData& data_;
    ReadStream stream_;
    Array& token_objects_;
    Object& obj_;
    intptr_t cur_token_pos_;
    Token::Kind cur_token_kind_;
    intptr_t cur_token_obj_index_;
    Iterator::StreamType stream_type_;
  };

 private:
  void SetPrivateKey(const String& value) const;

  static RawTokenStream* New();
  static void DataFinalizer(void* isolate_callback_data,
                            Dart_WeakPersistentHandle handle,
                            void* peer);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TokenStream, Object);
  friend class Class;
};

class Script : public Object {
 public:
  RawString* url() const { return raw_ptr()->url_; }

  // The actual url which was loaded from disk, if provided by the embedder.
  RawString* resolved_url() const { return raw_ptr()->resolved_url_; }
  bool HasSource() const;
  RawString* Source() const;
  RawString* GenerateSource() const;  // Generates source code from Tokenstream.
  RawGrowableObjectArray* GenerateLineNumberArray() const;
  RawScript::Kind kind() const {
    return static_cast<RawScript::Kind>(raw_ptr()->kind_);
  }
  const char* GetKindAsCString() const;
  intptr_t line_offset() const { return raw_ptr()->line_offset_; }
  intptr_t col_offset() const { return raw_ptr()->col_offset_; }

  // The load time in milliseconds since epoch.
  int64_t load_timestamp() const { return raw_ptr()->load_timestamp_; }

  RawArray* compile_time_constants() const {
    return raw_ptr()->compile_time_constants_;
  }
  void set_compile_time_constants(const Array& value) const;

  intptr_t kernel_script_index() const {
    return raw_ptr()->kernel_script_index_;
  }
  void set_kernel_script_index(const intptr_t kernel_script_index) const;

  RawTypedData* kernel_string_offsets() const {
    return raw_ptr()->kernel_string_offsets_;
  }
  void set_kernel_string_offsets(const TypedData& offsets) const;

  RawTypedData* kernel_string_data() const {
    return raw_ptr()->kernel_string_data_;
  }
  void set_kernel_string_data(const TypedData& data) const;

  RawTypedData* kernel_canonical_names() const {
    return raw_ptr()->kernel_canonical_names_;
  }
  void set_kernel_canonical_names(const TypedData& names) const;

  RawTokenStream* tokens() const {
    ASSERT(kind() != RawScript::kKernelTag);
    return raw_ptr()->tokens_;
  }

  void set_line_starts(const Array& value) const;

  void set_debug_positions(const Array& value) const;

  void set_yield_positions(const Array& value) const;

  RawArray* yield_positions() const;

  void Tokenize(const String& private_key, bool use_shared_tokens = true) const;

  RawLibrary* FindLibrary() const;
  RawString* GetLine(intptr_t line_number,
                     Heap::Space space = Heap::kNew) const;
  RawString* GetSnippet(TokenPosition from, TokenPosition to) const;
  RawString* GetSnippet(intptr_t from_line,
                        intptr_t from_column,
                        intptr_t to_line,
                        intptr_t to_column) const;

  void SetLocationOffset(intptr_t line_offset, intptr_t col_offset) const;

  intptr_t GetTokenLineUsingLineStarts(TokenPosition token_pos) const;
  void GetTokenLocation(TokenPosition token_pos,
                        intptr_t* line,
                        intptr_t* column,
                        intptr_t* token_len = NULL) const;

  // Returns index of first and last token on the given line. Returns both
  // indices < 0 if no token exists on or after the line. If a token exists
  // after, but not on given line, returns in *first_token_index the index of
  // the first token after the line, and a negative value in *last_token_index.
  void TokenRangeAtLine(intptr_t line_number,
                        TokenPosition* first_token_index,
                        TokenPosition* last_token_index) const;

  int32_t SourceFingerprint() const;
  int32_t SourceFingerprint(TokenPosition start, TokenPosition end) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawScript));
  }

  static RawScript* New(const String& url,
                        const String& source,
                        RawScript::Kind kind);

  static RawScript* New(const String& url,
                        const String& resolved_url,
                        const String& source,
                        RawScript::Kind kind);

 private:
  void set_url(const String& value) const;
  void set_resolved_url(const String& value) const;
  void set_source(const String& value) const;
  void set_kind(RawScript::Kind value) const;
  void set_load_timestamp(int64_t value) const;
  void set_tokens(const TokenStream& value) const;
  RawArray* line_starts() const;
  RawArray* debug_positions() const;

  static RawScript* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Script, Object);
  friend class Class;
  friend class Precompiler;
};

class DictionaryIterator : public ValueObject {
 public:
  explicit DictionaryIterator(const Library& library);

  bool HasNext() const { return next_ix_ < size_; }

  // Returns next non-null raw object.
  RawObject* GetNext();

 private:
  void MoveToNextObject();

  const Array& array_;
  const int size_;  // Number of elements to iterate over.
  int next_ix_;     // Index of next element.

  friend class ClassDictionaryIterator;
  friend class LibraryPrefixIterator;
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
  RawClass* GetNextClass();

 private:
  void MoveToNextClass();

  Class& toplevel_class_;

  DISALLOW_COPY_AND_ASSIGN(ClassDictionaryIterator);
};

class LibraryPrefixIterator : public DictionaryIterator {
 public:
  explicit LibraryPrefixIterator(const Library& library);
  RawLibraryPrefix* GetNext();

 private:
  void Advance();
  DISALLOW_COPY_AND_ASSIGN(LibraryPrefixIterator);
};

class Library : public Object {
 public:
  RawString* name() const { return raw_ptr()->name_; }
  void SetName(const String& name) const;

  RawString* url() const { return raw_ptr()->url_; }
  RawString* private_key() const { return raw_ptr()->private_key_; }
  bool LoadNotStarted() const {
    return raw_ptr()->load_state_ == RawLibrary::kAllocated;
  }
  bool LoadRequested() const {
    return raw_ptr()->load_state_ == RawLibrary::kLoadRequested;
  }
  bool LoadInProgress() const {
    return raw_ptr()->load_state_ == RawLibrary::kLoadInProgress;
  }
  void SetLoadRequested() const;
  void SetLoadInProgress() const;
  bool Loaded() const { return raw_ptr()->load_state_ == RawLibrary::kLoaded; }
  void SetLoaded() const;
  bool LoadFailed() const {
    return raw_ptr()->load_state_ == RawLibrary::kLoadError;
  }
  RawInstance* LoadError() const { return raw_ptr()->load_error_; }
  void SetLoadError(const Instance& error) const;
  RawInstance* TransitiveLoadError() const;

  void AddPatchClass(const Class& cls) const;
  RawClass* GetPatchClass(const String& name) const;
  void RemovePatchClass(const Class& cls) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawLibrary));
  }

  static RawLibrary* New(const String& url);

  // Evaluate the given expression as if it appeared in an top-level
  // method of this library and return the resulting value, or an
  // error object if evaluating the expression fails. The method has
  // the formal parameters given in param_names, and is invoked with
  // the argument values given in param_values.
  RawObject* Evaluate(const String& expr,
                      const Array& param_names,
                      const Array& param_values) const;

  // Library scope name dictionary.
  //
  // TODO(turnidge): The Lookup functions are not consistent in how
  // they deal with private names.  Go through and make them a bit
  // more regular.
  void AddClass(const Class& cls) const;
  void AddObject(const Object& obj, const String& name) const;
  void ReplaceObject(const Object& obj, const String& name) const;
  RawObject* LookupReExport(const String& name,
                            ZoneGrowableArray<intptr_t>* visited = NULL) const;
  RawObject* LookupObjectAllowPrivate(const String& name) const;
  RawObject* LookupLocalObjectAllowPrivate(const String& name) const;
  RawObject* LookupLocalObject(const String& name) const;
  RawObject* LookupImportedObject(const String& name) const;
  RawClass* LookupClass(const String& name) const;
  RawClass* LookupClassAllowPrivate(const String& name) const;
  RawClass* SlowLookupClassAllowMultiPartPrivate(const String& name) const;
  RawClass* LookupLocalClass(const String& name) const;
  RawField* LookupFieldAllowPrivate(const String& name) const;
  RawField* LookupLocalField(const String& name) const;
  RawFunction* LookupFunctionAllowPrivate(const String& name) const;
  RawFunction* LookupLocalFunction(const String& name) const;
  RawLibraryPrefix* LookupLocalLibraryPrefix(const String& name) const;
  RawScript* LookupScript(const String& url) const;
  RawArray* LoadedScripts() const;

  // Resolve name in the scope of this library. First check the cache
  // of already resolved names for this library. Then look in the
  // local dictionary for the unmangled name N, the getter name get:N
  // and setter name set:N.
  // If the local dictionary contains no entry for these names,
  // look in the scopes of all libraries that are imported
  // without a library prefix.
  RawObject* ResolveName(const String& name) const;

  void AddAnonymousClass(const Class& cls) const;

  void AddExport(const Namespace& ns) const;

  void AddClassMetadata(const Class& cls,
                        const Object& tl_owner,
                        TokenPosition token_pos,
                        intptr_t kernel_offset = 0,
                        const TypedData* kernel_data = NULL) const;
  void AddFieldMetadata(const Field& field,
                        TokenPosition token_pos,
                        intptr_t kernel_offset = 0,
                        const TypedData* kernel_data = NULL) const;
  void AddFunctionMetadata(const Function& func,
                           TokenPosition token_pos,
                           intptr_t kernel_offset = 0,
                           const TypedData* kernel_data = NULL) const;
  void AddLibraryMetadata(const Object& tl_owner,
                          TokenPosition token_pos) const;
  void AddTypeParameterMetadata(const TypeParameter& param,
                                TokenPosition token_pos) const;
  RawObject* GetMetadata(const Object& obj) const;

  RawClass* toplevel_class() const { return raw_ptr()->toplevel_class_; }
  void set_toplevel_class(const Class& value) const;

  RawGrowableObjectArray* patch_classes() const {
    return raw_ptr()->patch_classes_;
  }

  // Library imports.
  RawArray* imports() const { return raw_ptr()->imports_; }
  RawArray* exports() const { return raw_ptr()->exports_; }
  void AddImport(const Namespace& ns) const;
  intptr_t num_imports() const { return raw_ptr()->num_imports_; }
  RawNamespace* ImportAt(intptr_t index) const;
  RawLibrary* ImportLibraryAt(intptr_t index) const;
  bool ImportsCorelib() const;

  void DropDependenciesAndCaches() const;

  // Resolving native methods for script loaded in the library.
  Dart_NativeEntryResolver native_entry_resolver() const {
    return raw_ptr()->native_entry_resolver_;
  }
  void set_native_entry_resolver(Dart_NativeEntryResolver value) const {
    StoreNonPointer(&raw_ptr()->native_entry_resolver_, value);
  }
  Dart_NativeEntrySymbol native_entry_symbol_resolver() const {
    return raw_ptr()->native_entry_symbol_resolver_;
  }
  void set_native_entry_symbol_resolver(
      Dart_NativeEntrySymbol native_symbol_resolver) const {
    StoreNonPointer(&raw_ptr()->native_entry_symbol_resolver_,
                    native_symbol_resolver);
  }

  bool is_in_fullsnapshot() const { return raw_ptr()->is_in_fullsnapshot_; }
  void set_is_in_fullsnapshot(bool value) const {
    StoreNonPointer(&raw_ptr()->is_in_fullsnapshot_, value);
  }

  RawError* Patch(const Script& script) const;

  RawString* PrivateName(const String& name) const;

  intptr_t index() const { return raw_ptr()->index_; }
  void set_index(intptr_t value) const {
    StoreNonPointer(&raw_ptr()->index_, value);
  }

  void Register(Thread* thread) const;
  static void RegisterLibraries(Thread* thread,
                                const GrowableObjectArray& libs);

  bool IsDebuggable() const { return raw_ptr()->debuggable_; }
  void set_debuggable(bool value) const {
    StoreNonPointer(&raw_ptr()->debuggable_, value);
  }

  bool is_dart_scheme() const { return raw_ptr()->is_dart_scheme_; }
  void set_is_dart_scheme(bool value) const {
    StoreNonPointer(&raw_ptr()->is_dart_scheme_, value);
  }

  bool IsCoreLibrary() const { return raw() == CoreLibrary(); }

  inline intptr_t UrlHash() const;

  static RawLibrary* LookupLibrary(Thread* thread, const String& url);
  static RawLibrary* GetLibrary(intptr_t index);

  static void InitCoreLibrary(Isolate* isolate);
  static void InitNativeWrappersLibrary(Isolate* isolate, bool is_kernel_file);

  static RawLibrary* AsyncLibrary();
  static RawLibrary* ConvertLibrary();
  static RawLibrary* CoreLibrary();
  static RawLibrary* CollectionLibrary();
  static RawLibrary* DeveloperLibrary();
  static RawLibrary* InternalLibrary();
  static RawLibrary* IsolateLibrary();
  static RawLibrary* MathLibrary();
#if !defined(DART_PRECOMPILED_RUNTIME)
  static RawLibrary* MirrorsLibrary();
#endif
  static RawLibrary* NativeWrappersLibrary();
  static RawLibrary* ProfilerLibrary();
  static RawLibrary* TypedDataLibrary();
  static RawLibrary* VMServiceLibrary();

  // Eagerly compile all classes and functions in the library.
  static RawError* CompileAll();
  static RawError* ParseAll(Thread* thread);

#if defined(DART_NO_SNAPSHOT)
  // Checks function fingerprints. Prints mismatches and aborts if
  // mismatch found.
  static void CheckFunctionFingerprints();
#endif  // defined(DART_NO_SNAPSHOT).

  static bool IsPrivate(const String& name);
  // Construct the full name of a corelib member.
  static const String& PrivateCoreLibName(const String& member);
  // Lookup class in the core lib which also contains various VM
  // helper methods and classes. Allow look up of private classes.
  static RawClass* LookupCoreClass(const String& class_name);

  // Return Function::null() if function does not exist in libs.
  static RawFunction* GetFunction(const GrowableArray<Library*>& libs,
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
  RawObject* GetFunctionClosure(const String& name) const;

 private:
  static const int kInitialImportsCapacity = 4;
  static const int kImportsCapacityIncrement = 8;

  static RawLibrary* New();

  void set_num_imports(intptr_t value) const;
  bool HasExports() const;
  RawArray* loaded_scripts() const { return raw_ptr()->loaded_scripts_; }
  RawGrowableObjectArray* metadata() const { return raw_ptr()->metadata_; }
  void set_metadata(const GrowableObjectArray& value) const;
  RawArray* dictionary() const { return raw_ptr()->dictionary_; }
  void InitClassDictionary() const;

  RawArray* resolved_names() const { return raw_ptr()->resolved_names_; }
  bool LookupResolvedNamesCache(const String& name, Object* obj) const;
  void AddToResolvedNamesCache(const String& name, const Object& obj) const;
  void InitResolvedNamesCache() const;
  void ClearResolvedNamesCache() const;
  void InvalidateResolvedName(const String& name) const;
  void InvalidateResolvedNamesCache() const;

  RawArray* exported_names() const { return raw_ptr()->exported_names_; }
  bool LookupExportedNamesCache(const String& name, Object* obj) const;
  void AddToExportedNamesCache(const String& name, const Object& obj) const;
  void InitExportedNamesCache() const;
  void ClearExportedNamesCache() const;
  static void InvalidateExportedNamesCaches();

  void InitImportList() const;
  void RehashDictionary(const Array& old_dict, intptr_t new_dict_size) const;
  static RawLibrary* NewLibraryHelper(const String& url, bool import_core_lib);
  RawObject* LookupEntry(const String& name, intptr_t* index) const;

  void AllocatePrivateKey() const;

  RawString* MakeMetadataName(const Object& obj) const;
  RawField* GetMetadataField(const String& metaname) const;
  void AddMetadata(const Object& owner,
                   const String& name,
                   TokenPosition token_pos,
                   intptr_t kernel_offset = 0,
                   const TypedData* kernel_data = NULL) const;

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
  RawLibrary* library() const { return raw_ptr()->library_; }
  RawArray* show_names() const { return raw_ptr()->show_names_; }
  RawArray* hide_names() const { return raw_ptr()->hide_names_; }

  void AddMetadata(const Object& owner, TokenPosition token_pos);
  RawObject* GetMetadata() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawNamespace));
  }

  bool HidesName(const String& name) const;
  RawObject* Lookup(const String& name,
                    ZoneGrowableArray<intptr_t>* trail = NULL) const;

  static RawNamespace* New(const Library& library,
                           const Array& show_names,
                           const Array& hide_names);

 private:
  static RawNamespace* New();

  RawField* metadata_field() const { return raw_ptr()->metadata_field_; }
  void set_metadata_field(const Field& value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Namespace, Object);
  friend class Class;
  friend class Precompiler;
};

// ObjectPool contains constants, immediates and addresses embedded in code
// and deoptimization infos. Each entry has an type-info associated with it
// which is stored in a typed data array (info_array).
class ObjectPool : public Object {
 public:
  enum EntryType {
    kTaggedObject,
    kImmediate,
    kNativeEntry,
  };

  struct Entry {
    Entry() : raw_value_(), type_() {}
    explicit Entry(const Object* obj) : obj_(obj), type_(kTaggedObject) {}
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

  RawTypedData* info_array() const { return raw_ptr()->info_array_; }

  void set_info_array(const TypedData& info_array) const;

  static intptr_t length_offset() { return OFFSET_OF(RawObjectPool, length_); }
  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(RawObjectPool, data);
  }
  static intptr_t element_offset(intptr_t index) {
    return OFFSET_OF_RETURNED_VALUE(RawObjectPool, data) +
           kBytesPerElement * index;
  }

  EntryType InfoAt(intptr_t index) const;

  RawObject* ObjectAt(intptr_t index) const {
    ASSERT(InfoAt(index) == kTaggedObject);
    return EntryAddr(index)->raw_obj_;
  }
  void SetObjectAt(intptr_t index, const Object& obj) const {
    ASSERT(InfoAt(index) == kTaggedObject);
    StorePointer(&EntryAddr(index)->raw_obj_, obj.raw());
  }

  uword RawValueAt(intptr_t index) const {
    ASSERT(InfoAt(index) != kTaggedObject);
    return EntryAddr(index)->raw_value_;
  }
  void SetRawValueAt(intptr_t index, uword raw_value) const {
    ASSERT(InfoAt(index) != kTaggedObject);
    StoreNonPointer(&EntryAddr(index)->raw_value_, raw_value);
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawObjectPool) ==
           OFFSET_OF_RETURNED_VALUE(RawObjectPool, data));
    return 0;
  }

  static const intptr_t kBytesPerElement = sizeof(RawObjectPool::Entry);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize(intptr_t len) {
    // Ensure that variable length data is not adding to the object length.
    ASSERT(sizeof(RawObjectPool) == (sizeof(RawObject) + (2 * kWordSize)));
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawObjectPool) +
                                 (len * kBytesPerElement));
  }

  static RawObjectPool* New(intptr_t len);

  // Returns the pool index from the offset relative to a tagged RawObjectPool*,
  // adjusting for the tag-bit.
  static intptr_t IndexFromOffset(intptr_t offset) {
    ASSERT(Utils::IsAligned(offset + kHeapObjectTag, kWordSize));
    return (offset + kHeapObjectTag - data_offset()) / kBytesPerElement;
  }

  static intptr_t OffsetFromIndex(intptr_t index) {
    return element_offset(index) - kHeapObjectTag;
  }

  void DebugPrint() const;

 private:
  RawObjectPool::Entry const* EntryAddr(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return &raw_ptr()->data()[index];
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ObjectPool, Object);
  friend class Class;
  friend class Object;
  friend class RawObjectPool;
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
  static intptr_t Size(const RawInstructions* instr) {
    return SizeBits::decode(instr->ptr()->size_and_flags_);
  }

  bool HasSingleEntryPoint() const {
    return FlagsBits::decode(raw_ptr()->size_and_flags_);
  }
  static bool HasSingleEntryPoint(const RawInstructions* instr) {
    return FlagsBits::decode(instr->ptr()->size_and_flags_);
  }

  uword PayloadStart() const { return PayloadStart(raw()); }
  uword CheckedEntryPoint() const { return CheckedEntryPoint(raw()); }
  uword UncheckedEntryPoint() const { return UncheckedEntryPoint(raw()); }
  static uword PayloadStart(const RawInstructions* instr) {
    return reinterpret_cast<uword>(instr->ptr()) + HeaderSize();
  }

#if defined(TARGET_ARCH_IA32)
  static const intptr_t kCheckedEntryOffset = 0;
  static const intptr_t kUncheckedEntryOffset = 0;
#elif defined(TARGET_ARCH_X64)
  static const intptr_t kCheckedEntryOffset = 16;
  static const intptr_t kUncheckedEntryOffset = 38;
#elif defined(TARGET_ARCH_ARM)
  static const intptr_t kCheckedEntryOffset = 8;
  static const intptr_t kUncheckedEntryOffset = 32;
#elif defined(TARGET_ARCH_ARM64)
  static const intptr_t kCheckedEntryOffset = 16;
  static const intptr_t kUncheckedEntryOffset = 40;
#elif defined(TARGET_ARCH_DBC)
  static const intptr_t kCheckedEntryOffset = 0;
  static const intptr_t kUncheckedEntryOffset = 0;
#else
#error Missing entry offsets for current architecture
#endif

  static uword CheckedEntryPoint(const RawInstructions* instr) {
    uword entry = PayloadStart(instr);
    if (!HasSingleEntryPoint(instr)) {
      entry += kCheckedEntryOffset;
    }
    return entry;
  }
  static uword UncheckedEntryPoint(const RawInstructions* instr) {
    uword entry = PayloadStart(instr);
    if (!HasSingleEntryPoint(instr)) {
      entry += kUncheckedEntryOffset;
    }
    return entry;
  }

  static const intptr_t kMaxElements =
      (kMaxInt32 - (sizeof(RawInstructions) + sizeof(RawObject) +
                    (2 * OS::kMaxPreferredCodeAlignment)));

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawInstructions) ==
           OFFSET_OF_RETURNED_VALUE(RawInstructions, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t size) {
    intptr_t instructions_size =
        Utils::RoundUp(size, OS::PreferredCodeAlignment());
    intptr_t result = instructions_size + HeaderSize();
    ASSERT(result % OS::PreferredCodeAlignment() == 0);
    return result;
  }

  static intptr_t HeaderSize() {
    intptr_t alignment = OS::PreferredCodeAlignment();
    return Utils::RoundUp(sizeof(RawInstructions), alignment);
  }

  static RawInstructions* FromPayloadStart(uword payload_start) {
    return reinterpret_cast<RawInstructions*>(payload_start - HeaderSize() +
                                              kHeapObjectTag);
  }

  bool Equals(const Instructions& other) const {
    if (Size() != other.Size()) {
      return false;
    }
    NoSafepointScope no_safepoint;
    return memcmp(raw_ptr(), other.raw_ptr(), InstanceSize(Size())) == 0;
  }

 private:
  void SetSize(intptr_t value) const {
    ASSERT(value >= 0);
    StoreNonPointer(&raw_ptr()->size_and_flags_,
                    SizeBits::update(value, raw_ptr()->size_and_flags_));
  }

  void SetHasSingleEntryPoint(bool value) const {
    StoreNonPointer(&raw_ptr()->size_and_flags_,
                    FlagsBits::update(value, raw_ptr()->size_and_flags_));
  }

  // New is a private method as RawInstruction and RawCode objects should
  // only be created using the Code::FinalizeCode method. This method creates
  // the RawInstruction and RawCode objects, sets up the pointer offsets
  // and links the two in a GC safe manner.
  static RawInstructions* New(intptr_t size, bool has_single_entry_point);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Instructions, Object);
  friend class Class;
  friend class Code;
  friend class AssemblyImageWriter;
  friend class BlobImageWriter;
};

class LocalVarDescriptors : public Object {
 public:
  intptr_t Length() const;

  RawString* GetName(intptr_t var_index) const;

  void SetVar(intptr_t var_index,
              const String& name,
              RawLocalVarDescriptors::VarInfo* info) const;

  void GetInfo(intptr_t var_index, RawLocalVarDescriptors::VarInfo* info) const;

  static const intptr_t kBytesPerElement =
      sizeof(RawLocalVarDescriptors::VarInfo);
  static const intptr_t kMaxElements = RawLocalVarDescriptors::kMaxIndex;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawLocalVarDescriptors) ==
           OFFSET_OF_RETURNED_VALUE(RawLocalVarDescriptors, names));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawLocalVarDescriptors) +
        (len * kWordSize)  // RawStrings for names.
        + (len * sizeof(RawLocalVarDescriptors::VarInfo)));
  }

  static RawLocalVarDescriptors* New(intptr_t num_variables);

  static const char* KindToCString(RawLocalVarDescriptors::VarInfoKind kind);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(LocalVarDescriptors, Object);
  friend class Class;
  friend class Object;
};

class PcDescriptors : public Object {
 public:
  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = kMaxInt32 / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawPcDescriptors) ==
           OFFSET_OF_RETURNED_VALUE(RawPcDescriptors, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawPcDescriptors) + len);
  }

  static RawPcDescriptors* New(GrowableArray<uint8_t>* delta_encoded_data);

  // Verify (assert) assumptions about pc descriptors in debug mode.
  void Verify(const Function& function) const;

  static void PrintHeaderString();

  void PrintToJSONObject(JSONObject* jsobj, bool ref) const;

  // Encode integer in SLEB128 format.
  static void EncodeInteger(GrowableArray<uint8_t>* data, intptr_t value);

  // Decode SLEB128 encoded integer. Update byte_index to the next integer.
  intptr_t DecodeInteger(intptr_t* byte_index) const;

  // We would have a VisitPointers function here to traverse the
  // pc descriptors table to visit objects if any in the table.
  // Note: never return a reference to a RawPcDescriptors::PcDescriptorRec
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
          cur_try_index_(0) {}

    bool MoveNext() {
      // Moves to record that matches kind_mask_.
      while (byte_index_ < descriptors_.Length()) {
        int32_t merged_kind_try = descriptors_.DecodeInteger(&byte_index_);
        cur_kind_ =
            RawPcDescriptors::MergedKindTry::DecodeKind(merged_kind_try);
        cur_try_index_ =
            RawPcDescriptors::MergedKindTry::DecodeTryIndex(merged_kind_try);

        cur_pc_offset_ += descriptors_.DecodeInteger(&byte_index_);
        cur_deopt_id_ += descriptors_.DecodeInteger(&byte_index_);
        cur_token_pos_ += descriptors_.DecodeInteger(&byte_index_);

        if ((cur_kind_ & kind_mask_) != 0) {
          return true;  // Current is valid.
        }
      }
      return false;
    }

    uword PcOffset() const { return cur_pc_offset_; }
    intptr_t DeoptId() const { return cur_deopt_id_; }
    TokenPosition TokenPos() const { return TokenPosition(cur_token_pos_); }
    intptr_t TryIndex() const { return cur_try_index_; }
    RawPcDescriptors::Kind Kind() const {
      return static_cast<RawPcDescriptors::Kind>(cur_kind_);
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
          cur_try_index_(iter.cur_try_index_) {}

    const PcDescriptors& descriptors_;
    const intptr_t kind_mask_;
    intptr_t byte_index_;

    intptr_t cur_pc_offset_;
    intptr_t cur_kind_;
    intptr_t cur_deopt_id_;
    intptr_t cur_token_pos_;
    intptr_t cur_try_index_;
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
  static const char* KindAsStr(RawPcDescriptors::Kind kind);

  static RawPcDescriptors* New(intptr_t length);

  void SetLength(intptr_t value) const;
  void CopyData(GrowableArray<uint8_t>* data);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(PcDescriptors, Object);
  friend class Class;
  friend class Object;
};

class CodeSourceMap : public Object {
 public:
  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = kMaxInt32 / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawCodeSourceMap) ==
           OFFSET_OF_RETURNED_VALUE(RawCodeSourceMap, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawCodeSourceMap) + len);
  }

  static RawCodeSourceMap* New(intptr_t length);

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

class StackMap : public Object {
 public:
  static const intptr_t kNoMaximum = -1;
  static const intptr_t kNoMinimum = -1;

  bool IsObject(intptr_t index) const {
    ASSERT(InRange(index));
    return GetBit(index);
  }

  intptr_t Length() const { return raw_ptr()->length_; }

  uint32_t PcOffset() const { return raw_ptr()->pc_offset_; }
  void SetPcOffset(uint32_t value) const {
    ASSERT(value <= kMaxUint32);
    StoreNonPointer(&raw_ptr()->pc_offset_, value);
  }

  intptr_t SlowPathBitCount() const { return raw_ptr()->slow_path_bit_count_; }
  void SetSlowPathBitCount(intptr_t bit_count) const {
    ASSERT(bit_count < kMaxInt32);
    StoreNonPointer(&raw_ptr()->slow_path_bit_count_, bit_count);
  }

  bool Equals(const StackMap& other) const {
    if (Length() != other.Length()) {
      return false;
    }
    NoSafepointScope no_safepoint;
    return memcmp(raw_ptr(), other.raw_ptr(), InstanceSize(Length())) == 0;
  }

  static const intptr_t kMaxLengthInBytes = kSmiMax;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawStackMap) == OFFSET_OF_RETURNED_VALUE(RawStackMap, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t length) {
    ASSERT(length >= 0);
    // The stackmap payload is in an array of bytes.
    intptr_t payload_size = Utils::RoundUp(length, kBitsPerByte) / kBitsPerByte;
    return RoundedAllocationSize(sizeof(RawStackMap) + payload_size);
  }
  static RawStackMap* New(intptr_t pc_offset,
                          BitmapBuilder* bmap,
                          intptr_t register_bit_count);

  static RawStackMap* New(intptr_t length,
                          intptr_t register_bit_count,
                          intptr_t pc_offset);

 private:
  void SetLength(intptr_t length) const {
    StoreNonPointer(&raw_ptr()->length_, length);
  }

  bool InRange(intptr_t index) const { return index < Length(); }

  bool GetBit(intptr_t bit_index) const;
  void SetBit(intptr_t bit_index, bool value) const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(StackMap, Object);
  friend class BitmapBuilder;
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
                      TokenPosition token_pos,
                      bool is_generated) const;

  RawArray* GetHandledTypes(intptr_t try_index) const;
  void SetHandledTypes(intptr_t try_index, const Array& handled_types) const;
  bool HasCatchAll(intptr_t try_index) const;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawExceptionHandlers) ==
           OFFSET_OF_RETURNED_VALUE(RawExceptionHandlers, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    return RoundedAllocationSize(sizeof(RawExceptionHandlers) +
                                 (len * sizeof(ExceptionHandlerInfo)));
  }

  static RawExceptionHandlers* New(intptr_t num_handlers);
  static RawExceptionHandlers* New(const Array& handled_types_data);

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

class Code : public Object {
 public:
  RawInstructions* active_instructions() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return NULL;
#else
    return raw_ptr()->active_instructions_;
#endif
  }

  RawInstructions* instructions() const { return raw_ptr()->instructions_; }

  static intptr_t saved_instructions_offset() {
    return OFFSET_OF(RawCode, instructions_);
  }

  static intptr_t entry_point_offset() {
    return OFFSET_OF(RawCode, entry_point_);
  }
  static intptr_t checked_entry_point_offset() {
    return OFFSET_OF(RawCode, checked_entry_point_);
  }

  RawObjectPool* object_pool() const { return raw_ptr()->object_pool_; }
  static intptr_t object_pool_offset() {
    return OFFSET_OF(RawCode, object_pool_);
  }

  intptr_t pointer_offsets_length() const {
    return PtrOffBits::decode(raw_ptr()->state_bits_);
  }

  bool is_optimized() const {
    return OptimizedBit::decode(raw_ptr()->state_bits_);
  }
  void set_is_optimized(bool value) const;
  bool is_alive() const { return AliveBit::decode(raw_ptr()->state_bits_); }
  void set_is_alive(bool value) const;

  uword PayloadStart() const {
    return Instructions::PayloadStart(instructions());
  }
  uword UncheckedEntryPoint() const {
    const Instructions& instr = Instructions::Handle(instructions());
    return instr.UncheckedEntryPoint();
  }
  uword CheckedEntryPoint() const {
    const Instructions& instr = Instructions::Handle(instructions());
    return instr.CheckedEntryPoint();
  }
  intptr_t Size() const { return Instructions::Size(instructions()); }
  RawObjectPool* GetObjectPool() const { return object_pool(); }
  bool ContainsInstructionAt(uword addr) const {
    const Instructions& instr = Instructions::Handle(instructions());
    const uword offset = addr - instr.PayloadStart();
    return offset < static_cast<uword>(instr.Size());
  }

  // Returns true if there is a debugger breakpoint set in this code object.
  bool HasBreakpoint() const;

  RawPcDescriptors* pc_descriptors() const {
    return raw_ptr()->pc_descriptors_;
  }
  void set_pc_descriptors(const PcDescriptors& descriptors) const {
    ASSERT(descriptors.IsOld());
    StorePointer(&raw_ptr()->pc_descriptors_, descriptors.raw());
  }

  RawCodeSourceMap* code_source_map() const {
    return raw_ptr()->code_source_map_;
  }

  void set_code_source_map(const CodeSourceMap& code_source_map) const {
    ASSERT(code_source_map.IsOld());
    StorePointer(&raw_ptr()->code_source_map_, code_source_map.raw());
  }

  RawArray* await_token_positions() const;
  void set_await_token_positions(const Array& await_token_positions) const;

  // Used during reloading (see object_reload.cc). Calls Reset on all ICDatas
  // that are embedded inside the Code object.
  void ResetICDatas(Zone* zone) const;

  // Array of DeoptInfo objects.
  RawArray* deopt_info_array() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return NULL;
#else
    return raw_ptr()->deopt_info_array_;
#endif
  }
  void set_deopt_info_array(const Array& array) const;

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(DART_PRECOMPILER)
  RawSmi* variables() const { return raw_ptr()->catch_entry_.variables_; }
  void set_variables(const Smi& smi) const;
#else
  RawTypedData* catch_entry_state_maps() const {
    return raw_ptr()->catch_entry_.catch_entry_state_maps_;
  }
  void set_catch_entry_state_maps(const TypedData& maps) const;
#endif

  RawArray* stackmaps() const { return raw_ptr()->stackmaps_; }
  void set_stackmaps(const Array& maps) const;
  RawStackMap* GetStackMap(uint32_t pc_offset,
                           Array* stackmaps,
                           StackMap* map) const;

  enum {
    kSCallTableOffsetEntry = 0,
    kSCallTableFunctionEntry = 1,
    kSCallTableCodeEntry = 2,
    kSCallTableEntryLength = 3,
  };

  void set_static_calls_target_table(const Array& value) const;
  RawArray* static_calls_target_table() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return NULL;
#else
    return raw_ptr()->static_calls_target_table_;
#endif
  }

  RawTypedData* GetDeoptInfoAtPc(uword pc,
                                 ICData::DeoptReasonId* deopt_reason,
                                 uint32_t* deopt_flags) const;

  // Returns null if there is no static call at 'pc'.
  RawFunction* GetStaticCallTargetFunctionAt(uword pc) const;
  // Returns null if there is no static call at 'pc'.
  RawCode* GetStaticCallTargetCodeAt(uword pc) const;
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
    RawString* CommentAt(intptr_t idx) const;

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

  RawObject* return_address_metadata() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return NULL;
#else
    return raw_ptr()->return_address_metadata_;
#endif
  }
  // Sets |return_address_metadata|.
  void SetPrologueOffset(intptr_t offset) const;
  // Returns -1 if no prologue offset is available.
  intptr_t GetPrologueOffset() const;

  RawArray* inlined_id_to_function() const;
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
  // Same as above, expect the pc is interpreted as a return address (as needed
  // for a stack trace or the bottom frames of a profiler sample).
  void GetInlinedFunctionsAtReturnAddress(
      intptr_t pc_offset,
      GrowableArray<const Function*>* functions,
      GrowableArray<TokenPosition>* token_positions) const {
    GetInlinedFunctionsAtInstruction(pc_offset - 1, functions, token_positions);
  }

  NOT_IN_PRODUCT(void PrintJSONInlineIntervals(JSONObject* object) const);
  void DumpInlineIntervals() const;
  void DumpSourcePositions() const;

  RawLocalVarDescriptors* var_descriptors() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
    return NULL;
#else
    return raw_ptr()->var_descriptors_;
#endif
  }
  void set_var_descriptors(const LocalVarDescriptors& value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    ASSERT(value.IsOld());
    StorePointer(&raw_ptr()->var_descriptors_, value.raw());
#endif
  }

  // Will compute local var descriptors is necessary.
  RawLocalVarDescriptors* GetLocalVarDescriptors() const;

  RawExceptionHandlers* exception_handlers() const {
    return raw_ptr()->exception_handlers_;
  }
  void set_exception_handlers(const ExceptionHandlers& handlers) const {
    ASSERT(handlers.IsOld());
    StorePointer(&raw_ptr()->exception_handlers_, handlers.raw());
  }

  // TODO(turnidge): Consider dropping this function and making
  // everybody use owner().  Currently this function is misused - even
  // while generating the snapshot.
  RawFunction* function() const {
    return reinterpret_cast<RawFunction*>(raw_ptr()->owner_);
  }

  RawObject* owner() const { return raw_ptr()->owner_; }

  void set_owner(const Function& function) const {
    ASSERT(function.IsOld());
    StorePointer(&raw_ptr()->owner_,
                 reinterpret_cast<RawObject*>(function.raw()));
  }

  void set_owner(const Class& cls) {
    ASSERT(cls.IsOld());
    StorePointer(&raw_ptr()->owner_, reinterpret_cast<RawObject*>(cls.raw()));
  }

  // We would have a VisitPointers function here to traverse all the
  // embedded objects in the instructions using pointer_offsets.

  static const intptr_t kBytesPerElement =
      sizeof(reinterpret_cast<RawCode*>(0)->data()[0]);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawCode) == OFFSET_OF_RETURNED_VALUE(RawCode, data));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawCode) + (len * kBytesPerElement));
  }
  static RawCode* FinalizeCode(const Function& function,
                               Assembler* assembler,
                               bool optimized = false);
  static RawCode* FinalizeCode(const char* name,
                               Assembler* assembler,
                               bool optimized);
  static RawCode* LookupCode(uword pc);
  static RawCode* LookupCodeInVmIsolate(uword pc);
  static RawCode* FindCode(uword pc, int64_t timestamp);

  int32_t GetPointerOffsetAt(int index) const {
    NoSafepointScope no_safepoint;
    return *PointerOffsetAddrAt(index);
  }
  TokenPosition GetTokenIndexOfPC(uword pc) const;

  // Find pc, return 0 if not found.
  uword GetPcForDeoptId(intptr_t deopt_id, RawPcDescriptors::Kind kind) const;
  intptr_t GetDeoptIdForOsr(uword pc) const;

  const char* Name() const;
  const char* QualifiedName() const;

  int64_t compile_timestamp() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return 0;
#else
    return raw_ptr()->compile_timestamp_;
#endif
  }

  bool IsAllocationStubCode() const;
  bool IsStubCode() const;
  bool IsFunctionCode() const;

  void DisableDartCode() const;

  void DisableStubCode() const;

  void Enable() const {
    if (!IsDisabled()) return;
    ASSERT(Thread::Current()->IsMutatorThread());
    ASSERT(instructions() != active_instructions());
    SetActiveInstructions(Instructions::Handle(instructions()));
  }

  bool IsDisabled() const { return instructions() != active_instructions(); }

 private:
  void set_state_bits(intptr_t bits) const;

  void set_object_pool(RawObjectPool* object_pool) const {
    StorePointer(&raw_ptr()->object_pool_, object_pool);
  }

  friend class RawObject;  // For RawObject::SizeFromClass().
  friend class RawCode;
  enum {
    kOptimizedBit = 0,
    kAliveBit = 1,
    kPtrOffBit = 2,
    kPtrOffSize = 30,
  };

  class OptimizedBit : public BitField<int32_t, bool, kOptimizedBit, 1> {};
  class AliveBit : public BitField<int32_t, bool, kAliveBit, 1> {};
  class PtrOffBits
      : public BitField<int32_t, intptr_t, kPtrOffBit, kPtrOffSize> {};

  class SlowFindRawCodeVisitor : public FindObjectVisitor {
   public:
    explicit SlowFindRawCodeVisitor(uword pc) : pc_(pc) {}
    virtual ~SlowFindRawCodeVisitor() {}

    // Check if object matches find condition.
    virtual bool FindObject(RawObject* obj) const;

   private:
    const uword pc_;

    DISALLOW_COPY_AND_ASSIGN(SlowFindRawCodeVisitor);
  };

  static bool IsOptimized(RawCode* code) {
    return Code::OptimizedBit::decode(code->ptr()->state_bits_);
  }

  static const intptr_t kEntrySize = sizeof(int32_t);  // NOLINT

  void set_compile_timestamp(int64_t timestamp) const {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    StoreNonPointer(&raw_ptr()->compile_timestamp_, timestamp);
#endif
  }

  void SetActiveInstructions(const Instructions& instructions) const;

  void set_instructions(const Instructions& instructions) const {
    ASSERT(Thread::Current()->IsMutatorThread() || !is_alive());
    StorePointer(&raw_ptr()->instructions_, instructions.raw());
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
  static RawCode* LookupCodeInIsolate(Isolate* isolate, uword pc);

  // New is a private method as RawInstruction and RawCode objects should
  // only be created using the Code::FinalizeCode method. This method creates
  // the RawInstruction and RawCode objects, sets up the pointer offsets
  // and links the two in a GC safe manner.
  static RawCode* New(intptr_t pointer_offsets_length);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Code, Object);
  friend class Class;
  friend class SnapshotWriter;
  friend class FunctionSerializationCluster;
  friend class CodeSerializationCluster;
  friend class CodePatcher;     // for set_instructions
  friend class ProgramVisitor;  // for set_instructions
  // So that the RawFunction pointer visitor can determine whether code the
  // function points to is optimized.
  friend class RawFunction;
};

class Context : public Object {
 public:
  RawContext* parent() const { return raw_ptr()->parent_; }
  void set_parent(const Context& parent) const {
    StorePointer(&raw_ptr()->parent_, parent.raw());
  }
  static intptr_t parent_offset() { return OFFSET_OF(RawContext, parent_); }

  intptr_t num_variables() const { return raw_ptr()->num_variables_; }
  static intptr_t num_variables_offset() {
    return OFFSET_OF(RawContext, num_variables_);
  }

  RawObject* At(intptr_t context_index) const {
    return *ObjectAddr(context_index);
  }
  inline void SetAt(intptr_t context_index, const Object& value) const;

  void Dump(int indent = 0) const;

  static const intptr_t kBytesPerElement = kWordSize;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t variable_offset(intptr_t context_index) {
    return OFFSET_OF_RETURNED_VALUE(RawContext, data) +
           (kWordSize * context_index);
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawContext) == OFFSET_OF_RETURNED_VALUE(RawContext, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawContext) + (len * kBytesPerElement));
  }

  static RawContext* New(intptr_t num_variables,
                         Heap::Space space = Heap::kNew);

 private:
  RawObject* const* ObjectAddr(intptr_t context_index) const {
    ASSERT((context_index >= 0) && (context_index < num_variables()));
    return &raw_ptr()->data()[context_index];
  }

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

  RawString* NameAt(intptr_t scope_index) const;
  void SetNameAt(intptr_t scope_index, const String& name) const;

  bool IsFinalAt(intptr_t scope_index) const;
  void SetIsFinalAt(intptr_t scope_index, bool is_final) const;

  bool IsConstAt(intptr_t scope_index) const;
  void SetIsConstAt(intptr_t scope_index, bool is_const) const;

  RawAbstractType* TypeAt(intptr_t scope_index) const;
  void SetTypeAt(intptr_t scope_index, const AbstractType& type) const;

  RawInstance* ConstValueAt(intptr_t scope_index) const;
  void SetConstValueAt(intptr_t scope_index, const Instance& value) const;

  intptr_t ContextIndexAt(intptr_t scope_index) const;
  void SetContextIndexAt(intptr_t scope_index, intptr_t context_index) const;

  intptr_t ContextLevelAt(intptr_t scope_index) const;
  void SetContextLevelAt(intptr_t scope_index, intptr_t context_level) const;

  static const intptr_t kBytesPerElement =
      sizeof(RawContextScope::VariableDesc);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawContextScope) ==
           OFFSET_OF_RETURNED_VALUE(RawContextScope, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawContextScope) +
                                 (len * kBytesPerElement));
  }

  static RawContextScope* New(intptr_t num_variables, bool is_implicit);

 private:
  void set_num_variables(intptr_t num_variables) const {
    StoreNonPointer(&raw_ptr()->num_variables_, num_variables);
  }

  void set_is_implicit(bool is_implicit) const {
    StoreNonPointer(&raw_ptr()->is_implicit_, is_implicit);
  }

  const RawContextScope::VariableDesc* VariableDescAddr(intptr_t index) const {
    ASSERT((index >= 0) && (index < num_variables()));
    return raw_ptr()->VariableDescAddr(index);
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ContextScope, Object);
  friend class Class;
  friend class Object;
};

class MegamorphicCache : public Object {
 public:
  static const intptr_t kInitialCapacity = 16;
  static const intptr_t kSpreadFactor = 7;
  static const double kLoadFactor;

  RawArray* buckets() const;
  void set_buckets(const Array& buckets) const;

  intptr_t mask() const;
  void set_mask(intptr_t mask) const;

  RawString* target_name() const { return raw_ptr()->target_name_; }

  RawArray* arguments_descriptor() const { return raw_ptr()->args_descriptor_; }

  intptr_t filled_entry_count() const;
  void set_filled_entry_count(intptr_t num) const;

  static intptr_t buckets_offset() {
    return OFFSET_OF(RawMegamorphicCache, buckets_);
  }
  static intptr_t mask_offset() {
    return OFFSET_OF(RawMegamorphicCache, mask_);
  }
  static intptr_t arguments_descriptor_offset() {
    return OFFSET_OF(RawMegamorphicCache, args_descriptor_);
  }

  static RawMegamorphicCache* New(const String& target_name,
                                  const Array& arguments_descriptor);

  void EnsureCapacity() const;

  void Insert(const Smi& class_id, const Function& target) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawMegamorphicCache));
  }

 private:
  friend class Class;
  friend class MegamorphicCacheTable;
  friend class ProgramVisitor;

  static RawMegamorphicCache* New();

  void set_target_name(const String& value) const;
  void set_arguments_descriptor(const Array& value) const;

  enum {
    kClassIdIndex,
    kTargetFunctionIndex,
    kEntryLength,
  };

  static inline void SetEntry(const Array& array,
                              intptr_t index,
                              const Smi& class_id,
                              const Function& target);

  static inline RawObject* GetClassId(const Array& array, intptr_t index);
  static inline RawObject* GetTargetFunction(const Array& array,
                                             intptr_t index);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(MegamorphicCache, Object);
};

class SubtypeTestCache : public Object {
 public:
  enum Entries {
    kInstanceClassIdOrFunction = 0,
    kInstanceTypeArguments = 1,
    kInstantiatorTypeArguments = 2,
    kFunctionTypeArguments = 3,
    kTestResult = 4,
    kTestEntryLength = 5,
  };

  intptr_t NumberOfChecks() const;
  void AddCheck(const Object& instance_class_id_or_function,
                const TypeArguments& instance_type_arguments,
                const TypeArguments& instantiator_type_arguments,
                const TypeArguments& function_type_arguments,
                const Bool& test_result) const;
  void GetCheck(intptr_t ix,
                Object* instance_class_id_or_function,
                TypeArguments* instance_type_arguments,
                TypeArguments* instantiator_type_arguments,
                TypeArguments* function_type_arguments,
                Bool* test_result) const;

  static RawSubtypeTestCache* New();

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawSubtypeTestCache));
  }

  static intptr_t cache_offset() {
    return OFFSET_OF(RawSubtypeTestCache, cache_);
  }

 private:
  RawArray* cache() const { return raw_ptr()->cache_; }

  void set_cache(const Array& value) const;

  intptr_t TestEntryLength() const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(SubtypeTestCache, Object);
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
  RawString* message() const { return raw_ptr()->message_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawApiError));
  }

  static RawApiError* New(const String& message,
                          Heap::Space space = Heap::kNew);

  virtual const char* ToErrorCString() const;

 private:
  void set_message(const String& message) const;

  static RawApiError* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(ApiError, Error);
  friend class Class;
};

class LanguageError : public Error {
 public:
  Report::Kind kind() const {
    return static_cast<Report::Kind>(raw_ptr()->kind_);
  }

  // Build, cache, and return formatted message.
  RawString* FormatMessage() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawLanguageError));
  }

  // A null script means no source and a negative token_pos means no position.
  static RawLanguageError* NewFormatted(const Error& prev_error,
                                        const Script& script,
                                        TokenPosition token_pos,
                                        bool report_after_token,
                                        Report::Kind kind,
                                        Heap::Space space,
                                        const char* format,
                                        ...) PRINTF_ATTRIBUTE(7, 8);

  static RawLanguageError* NewFormattedV(const Error& prev_error,
                                         const Script& script,
                                         TokenPosition token_pos,
                                         bool report_after_token,
                                         Report::Kind kind,
                                         Heap::Space space,
                                         const char* format,
                                         va_list args);

  static RawLanguageError* New(const String& formatted_message,
                               Report::Kind kind = Report::kError,
                               Heap::Space space = Heap::kNew);

  virtual const char* ToErrorCString() const;

  TokenPosition token_pos() const { return raw_ptr()->token_pos_; }

 private:
  RawError* previous_error() const { return raw_ptr()->previous_error_; }
  void set_previous_error(const Error& value) const;

  RawScript* script() const { return raw_ptr()->script_; }
  void set_script(const Script& value) const;

  void set_token_pos(TokenPosition value) const;

  bool report_after_token() const { return raw_ptr()->report_after_token_; }
  void set_report_after_token(bool value);

  void set_kind(uint8_t value) const;

  RawString* message() const { return raw_ptr()->message_; }
  void set_message(const String& value) const;

  RawString* formatted_message() const { return raw_ptr()->formatted_message_; }
  void set_formatted_message(const String& value) const;

  static RawLanguageError* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(LanguageError, Error);
  friend class Class;
};

class UnhandledException : public Error {
 public:
  RawInstance* exception() const { return raw_ptr()->exception_; }
  static intptr_t exception_offset() {
    return OFFSET_OF(RawUnhandledException, exception_);
  }

  RawInstance* stacktrace() const { return raw_ptr()->stacktrace_; }
  static intptr_t stacktrace_offset() {
    return OFFSET_OF(RawUnhandledException, stacktrace_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawUnhandledException));
  }

  static RawUnhandledException* New(const Instance& exception,
                                    const Instance& stacktrace,
                                    Heap::Space space = Heap::kNew);

  virtual const char* ToErrorCString() const;

 private:
  static RawUnhandledException* New(Heap::Space space = Heap::kNew);

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

  RawString* message() const { return raw_ptr()->message_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawUnwindError));
  }

  static RawUnwindError* New(const String& message,
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
  virtual uword ComputeCanonicalTableHash() const;

  intptr_t SizeFromClass() const {
#if defined(DEBUG)
    const Class& cls = Class::Handle(clazz());
    ASSERT(cls.is_finalized() || cls.is_prefinalized());
#endif
    return (clazz()->ptr()->instance_size_in_words_ * kWordSize);
  }

  // Returns Instance::null() if instance cannot be canonicalized.
  // Any non-canonical number of string will be canonicalized here.
  // An instance cannot be canonicalized if it still contains non-canonical
  // instances in its fields.
  // Returns error in error_str, pass NULL if an error cannot occur.
  virtual RawInstance* CheckAndCanonicalize(Thread* thread,
                                            const char** error_str) const;

  // Returns true if all fields are OK for canonicalization.
  virtual bool CheckAndCanonicalizeFields(Thread* thread,
                                          const char** error_str) const;

#if defined(DEBUG)
  // Check if instance is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const;
#endif  // DEBUG

  RawObject* GetField(const Field& field) const { return *FieldAddr(field); }

  void SetField(const Field& field, const Object& value) const {
    field.RecordStore(value);
    StorePointer(FieldAddr(field), value.raw());
  }

  RawAbstractType* GetType(Heap::Space space) const;

  virtual RawTypeArguments* GetTypeArguments() const;
  virtual void SetTypeArguments(const TypeArguments& value) const;

  // Check if the type of this instance is a subtype of the given other type.
  // The type argument vectors are used to instantiate the other type if needed.
  bool IsInstanceOf(const AbstractType& other,
                    const TypeArguments& other_instantiator_type_arguments,
                    const TypeArguments& other_function_type_arguments,
                    Error* bound_error) const;

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

  // Evaluate the given expression as if it appeared in an instance
  // method of this instance and return the resulting value, or an
  // error object if evaluating the expression fails. The method has
  // the formal parameters given in param_names, and is invoked with
  // the argument values given in param_values.
  RawObject* Evaluate(const Class& method_cls,
                      const String& expr,
                      const Array& param_names,
                      const Array& param_values) const;

  // Equivalent to invoking hashCode on this instance.
  virtual RawObject* HashCode() const;

  // Equivalent to invoking identityHashCode with this instance.
  RawObject* IdentityHashCode() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawInstance));
  }

  static RawInstance* New(const Class& cls, Heap::Space space = Heap::kNew);

  // Array/list element address computations.
  static intptr_t DataOffsetFor(intptr_t cid);
  static intptr_t ElementSizeFor(intptr_t cid);

 protected:
#ifndef PRODUCT
  virtual void PrintSharedInstanceJSON(JSONObject* jsobj, bool ref) const;
#endif

 private:
  RawObject** FieldAddrAtOffset(intptr_t offset) const {
    ASSERT(IsValidFieldOffset(offset));
    return reinterpret_cast<RawObject**>(raw_value() - kHeapObjectTag + offset);
  }
  RawObject** FieldAddr(const Field& field) const {
    return FieldAddrAtOffset(field.Offset());
  }
  RawObject** NativeFieldsAddr() const {
    return FieldAddrAtOffset(sizeof(RawObject));
  }
  void SetFieldAtOffset(intptr_t offset, const Object& value) const {
    StorePointer(FieldAddrAtOffset(offset), value.raw());
  }
  bool IsValidFieldOffset(intptr_t offset) const;

  static intptr_t NextFieldOffset() { return sizeof(RawInstance); }

  // The following raw methods are used for morphing.
  // They are needed due to the extraction of the class in IsValidFieldOffset.
  RawObject** RawFieldAddrAtOffset(intptr_t offset) const {
    return reinterpret_cast<RawObject**>(raw_value() - kHeapObjectTag + offset);
  }
  RawObject* RawGetFieldAtOffset(intptr_t offset) const {
    return *RawFieldAddrAtOffset(offset);
  }
  void RawSetFieldAtOffset(intptr_t offset, const Object& value) const {
    StorePointer(RawFieldAddrAtOffset(offset), value.raw());
  }

  // TODO(iposva): Determine if this gets in the way of Smi.
  HEAP_OBJECT_IMPLEMENTATION(Instance, Object);
  friend class ByteBuffer;
  friend class Class;
  friend class Closure;
  friend class DeferredObject;
  friend class RegExp;
  friend class SnapshotWriter;
  friend class StubCode;
  friend class TypedDataView;
  friend class InstanceSerializationCluster;
  friend class InstanceDeserializationCluster;
  friend class ClassDeserializationCluster;  // vtable
  friend class InstanceMorpher;
};

class LibraryPrefix : public Instance {
 public:
  RawString* name() const { return raw_ptr()->name_; }
  virtual RawString* DictionaryName() const { return name(); }

  RawArray* imports() const { return raw_ptr()->imports_; }
  intptr_t num_imports() const { return raw_ptr()->num_imports_; }
  RawLibrary* importer() const { return raw_ptr()->importer_; }

  RawInstance* LoadError() const;

  bool ContainsLibrary(const Library& library) const;
  RawLibrary* GetLibrary(int index) const;
  void AddImport(const Namespace& import) const;
  RawObject* LookupObject(const String& name) const;
  RawClass* LookupClass(const String& class_name) const;

  bool is_deferred_load() const { return raw_ptr()->is_deferred_load_; }
  bool is_loaded() const { return raw_ptr()->is_loaded_; }
  bool LoadLibrary() const;

  // Return the list of code objects that were compiled when this
  // prefix was not yet loaded. These code objects will be invalidated
  // when the prefix is loaded.
  RawArray* dependent_code() const;
  void set_dependent_code(const Array& array) const;

  // Add the given code object to the list of dependent ones.
  void RegisterDependentCode(const Code& code) const;
  void InvalidateDependentCode() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawLibraryPrefix));
  }

  static RawLibraryPrefix* New(const String& name,
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
  void set_is_loaded() const;

  static RawLibraryPrefix* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(LibraryPrefix, Instance);
  friend class Class;
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
  virtual bool IsMalformed() const;
  virtual bool IsMalbounded() const;
  virtual bool IsMalformedOrMalbounded() const;
  virtual RawLanguageError* error() const;
  virtual void set_error(const LanguageError& value) const;
  virtual bool IsResolved() const;
  virtual void SetIsResolved() const;
  virtual bool HasResolvedTypeClass() const;
  virtual classid_t type_class_id() const;
  virtual RawClass* type_class() const;
  virtual RawUnresolvedClass* unresolved_class() const;
  virtual RawTypeArguments* arguments() const;
  virtual void set_arguments(const TypeArguments& value) const;
  virtual TokenPosition token_pos() const;
  virtual bool IsInstantiated(Genericity genericity = kAny,
                              intptr_t num_free_fun_type_params = kMaxInt32,
                              TrailPtr trail = NULL) const;
  virtual bool CanonicalizeEquals(const Instance& other) const {
    return Equals(other);
  }
  virtual bool Equals(const Instance& other) const {
    return IsEquivalent(other);
  }
  virtual bool IsEquivalent(const Instance& other, TrailPtr trail = NULL) const;
  virtual bool IsRecursive() const;

  // Set the scope of this type to the given function.
  virtual void SetScopeFunction(const Function& function) const;

  // Check if this type represents a function type.
  virtual bool IsFunctionType() const { return false; }

  // Instantiate this type using the given type argument vectors and possibly
  // the current context.
  // Return a new type, or return 'this' if it is already instantiated.
  // If bound_error is not NULL, it may be set to reflect a bound error.
  virtual RawAbstractType* InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      Error* bound_error,
      TrailPtr instantiation_trail,
      TrailPtr bound_trail,
      Heap::Space space) const;

  // Return a clone of this unfinalized type or the type itself if it is
  // already finalized. Apply recursively to type arguments, i.e. finalized
  // type arguments of an unfinalized type are not cloned, but shared.
  virtual RawAbstractType* CloneUnfinalized() const;

  // Return a clone of this uninstantiated type where all references to type
  // parameters are replaced with references to type parameters of the same name
  // but belonging to the new owner class.
  // Apply recursively to type arguments, i.e. instantiated type arguments of
  // an uninstantiated type are not cloned, but shared.
  virtual RawAbstractType* CloneUninstantiated(const Class& new_owner,
                                               TrailPtr trail = NULL) const;

  virtual RawInstance* CheckAndCanonicalize(Thread* thread,
                                            const char** error_str) const {
    return Canonicalize();
  }

  // Return the canonical version of this type.
  virtual RawAbstractType* Canonicalize(TrailPtr trail = NULL) const;

#if defined(DEBUG)
  // Check if abstract type is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const {
    UNREACHABLE();
    return false;
  }
#endif  // DEBUG

  // Return the object associated with the receiver in the trail or
  // AbstractType::null() if the receiver is not contained in the trail.
  RawAbstractType* OnlyBuddyInTrail(TrailPtr trail) const;

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

  // The name of this type, including the names of its type arguments, if any.
  virtual RawString* Name() const { return BuildName(kInternalName); }

  // The name of this type, including the names of its type arguments, if any.
  // Names of internal classes are mapped to their public interfaces.
  virtual RawString* UserVisibleName() const {
    return BuildName(kUserVisibleName);
  }

  // Returns a formatted list of occurring types with their URI.
  virtual RawString* EnumerateURIs() const;

  virtual intptr_t Hash() const;

  // The name of this type's class, i.e. without the type argument names of this
  // type.
  RawString* ClassName() const;

  // Check if this type represents the 'dynamic' type or if it is malformed,
  // since a malformed type is mapped to 'dynamic'.
  // Call IsMalformed() first, if distinction is required.
  bool IsDynamicType() const;

  // Check if this type represents the 'void' type.
  bool IsVoidType() const;

  // Check if this type represents the 'Null' type.
  bool IsNullType() const;

  bool IsObjectType() const {
    return !IsFunctionType() && HasResolvedTypeClass() &&
           Class::Handle(type_class()).IsObjectClass();
  }

  // Check if this type represents the 'bool' type.
  bool IsBoolType() const;

  // Check if this type represents the 'int' type.
  bool IsIntType() const;

  // Check if this type represents the '_int64' type.
  bool IsInt64Type() const;

  // Check if this type represents the 'double' type.
  bool IsDoubleType() const;

  // Check if this type represents the 'Float32x4' type.
  bool IsFloat32x4Type() const;

  // Check if this type represents the 'Float64x2' type.
  bool IsFloat64x2Type() const;

  // Check if this type represents the 'Int32x4' type.
  bool IsInt32x4Type() const;

  // Check if this type represents the 'num' type.
  bool IsNumberType() const;

  // Check if this type represents the '_Smi' type.
  bool IsSmiType() const;

  // Check if this type represents the 'String' type.
  bool IsStringType() const;

  // Check if this type represents the Dart 'Function' type.
  bool IsDartFunctionType() const;

  // Check if this type represents the Dart '_Closure' type.
  bool IsDartClosureType() const;

  // Check the subtype relationship.
  bool IsSubtypeOf(const AbstractType& other,
                   Error* bound_error,
                   TrailPtr bound_trail,
                   Heap::Space space) const {
    return TypeTest(kIsSubtypeOf, other, bound_error, bound_trail, space);
  }

  // Check the 'more specific' relationship.
  bool IsMoreSpecificThan(const AbstractType& other,
                          Error* bound_error,
                          TrailPtr bound_trail,
                          Heap::Space space) const {
    return TypeTest(kIsMoreSpecificThan, other, bound_error, bound_trail,
                    space);
  }

 private:
  // Check the subtype or 'more specific' relationship.
  bool TypeTest(TypeTestKind test_kind,
                const AbstractType& other,
                Error* bound_error,
                TrailPtr bound_trail,
                Heap::Space space) const;

  // Return the internal or public name of this type, including the names of its
  // type arguments, if any.
  RawString* BuildName(NameVisibility visibility) const;

 protected:
  HEAP_OBJECT_IMPLEMENTATION(AbstractType, Instance);
  friend class Class;
  friend class Function;
  friend class TypeArguments;
};

// A Type consists of a class, possibly parameterized with type
// arguments. Example: C<T1, T2>.
// An unresolved class is a String specifying the class name.
//
// Caution: 'RawType*' denotes a 'raw' pointer to a VM object of class Type, as
// opposed to 'Type' denoting a 'handle' to the same object. 'RawType' does not
// relate to a 'raw type', as opposed to a 'cooked type' or 'rare type'.
class Type : public AbstractType {
 public:
  static intptr_t type_class_id_offset() {
    return OFFSET_OF(RawType, type_class_id_);
  }
  virtual bool IsFinalized() const {
    return (raw_ptr()->type_state_ == RawType::kFinalizedInstantiated) ||
           (raw_ptr()->type_state_ == RawType::kFinalizedUninstantiated);
  }
  virtual void SetIsFinalized() const;
  void ResetIsFinalized() const;  // Ignore current state and set again.
  virtual bool IsBeingFinalized() const {
    return raw_ptr()->type_state_ == RawType::kBeingFinalized;
  }
  virtual void SetIsBeingFinalized() const;
  virtual bool IsMalformed() const;
  virtual bool IsMalbounded() const;
  virtual bool IsMalformedOrMalbounded() const;
  virtual RawLanguageError* error() const;
  virtual void set_error(const LanguageError& value) const;
  virtual bool IsResolved() const {
    return raw_ptr()->type_state_ >= RawType::kResolved;
  }
  virtual void SetIsResolved() const;
  virtual bool HasResolvedTypeClass() const;  // Own type class resolved.
  virtual classid_t type_class_id() const;
  virtual RawClass* type_class() const;
  void set_type_class(const Class& value) const;
  void set_unresolved_class(const Object& value) const;
  virtual RawUnresolvedClass* unresolved_class() const;
  virtual RawTypeArguments* arguments() const { return raw_ptr()->arguments_; }
  virtual void set_arguments(const TypeArguments& value) const;
  virtual TokenPosition token_pos() const { return raw_ptr()->token_pos_; }
  virtual bool IsInstantiated(Genericity genericity = kAny,
                              intptr_t num_free_fun_type_params = kMaxInt32,
                              TrailPtr trail = NULL) const;
  virtual bool IsEquivalent(const Instance& other, TrailPtr trail = NULL) const;
  virtual bool IsRecursive() const;
  virtual void SetScopeFunction(const Function& function) const;
  // If signature is not null, this type represents a function type. Note that
  // the signature fully represents the type and type arguments can be ignored.
  // However, in case of a generic typedef, they document how the typedef class
  // was parameterized to obtain the actual signature.
  RawFunction* signature() const;
  void set_signature(const Function& value) const;
  virtual bool IsFunctionType() const {
    return signature() != Function::null();
  }
  virtual RawAbstractType* InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      Error* bound_error,
      TrailPtr instantiation_trail,
      TrailPtr bound_trail,
      Heap::Space space) const;
  virtual RawAbstractType* CloneUnfinalized() const;
  virtual RawAbstractType* CloneUninstantiated(const Class& new_owner,
                                               TrailPtr trail = NULL) const;
  virtual RawAbstractType* Canonicalize(TrailPtr trail = NULL) const;
#if defined(DEBUG)
  // Check if type is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const;
#endif  // DEBUG
  virtual RawString* EnumerateURIs() const;

  virtual intptr_t Hash() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawType));
  }

  // The type of the literal 'null'.
  static RawType* NullType();

  // The 'dynamic' type.
  static RawType* DynamicType();

  // The 'void' type.
  static RawType* VoidType();

  // The 'Object' type.
  static RawType* ObjectType();

  // The 'bool' type.
  static RawType* BoolType();

  // The 'int' type.
  static RawType* IntType();

  // The '_int64' type.
  static RawType* Int64Type();

  // The 'Smi' type.
  static RawType* SmiType();

  // The 'Mint' type.
  static RawType* MintType();

  // The 'double' type.
  static RawType* Double();

  // The 'Float32x4' type.
  static RawType* Float32x4();

  // The 'Float64x2' type.
  static RawType* Float64x2();

  // The 'Int32x4' type.
  static RawType* Int32x4();

  // The 'num' type.
  static RawType* Number();

  // The 'String' type.
  static RawType* StringType();

  // The 'Array' type.
  static RawType* ArrayType();

  // The 'Function' type.
  static RawType* DartFunctionType();

  // The finalized type of the given non-parameterized class.
  static RawType* NewNonParameterizedType(const Class& type_class);

  static RawType* New(const Object& clazz,
                      const TypeArguments& arguments,
                      TokenPosition token_pos,
                      Heap::Space space = Heap::kOld);

 private:
  intptr_t ComputeHash() const;
  void SetHash(intptr_t value) const;

  void set_token_pos(TokenPosition token_pos) const;
  void set_type_state(int8_t state) const;

  static RawType* New(Heap::Space space = Heap::kOld);

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
  virtual bool IsFinalized() const {
    const AbstractType& ref_type = AbstractType::Handle(type());
    return !ref_type.IsNull() && ref_type.IsFinalized();
  }
  virtual bool IsBeingFinalized() const {
    const AbstractType& ref_type = AbstractType::Handle(type());
    return ref_type.IsNull() || ref_type.IsBeingFinalized();
  }
  virtual bool IsMalformed() const {
    return AbstractType::Handle(type()).IsMalformed();
  }
  virtual bool IsMalbounded() const {
    return AbstractType::Handle(type()).IsMalbounded();
  }
  virtual bool IsMalformedOrMalbounded() const {
    return AbstractType::Handle(type()).IsMalformedOrMalbounded();
  }
  virtual bool IsResolved() const { return true; }
  virtual bool HasResolvedTypeClass() const {
    return AbstractType::Handle(type()).HasResolvedTypeClass();
  }
  RawAbstractType* type() const { return raw_ptr()->type_; }
  void set_type(const AbstractType& value) const;
  virtual RawClass* type_class() const {
    return AbstractType::Handle(type()).type_class();
  }
  virtual RawTypeArguments* arguments() const {
    return AbstractType::Handle(type()).arguments();
  }
  virtual TokenPosition token_pos() const {
    return AbstractType::Handle(type()).token_pos();
  }
  virtual bool IsInstantiated(Genericity genericity = kAny,
                              intptr_t num_free_fun_type_params = kMaxInt32,
                              TrailPtr trail = NULL) const;
  virtual bool IsEquivalent(const Instance& other, TrailPtr trail = NULL) const;
  virtual bool IsRecursive() const { return true; }
  virtual void SetScopeFunction(const Function& function) const;
  virtual RawTypeRef* InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      Error* bound_error,
      TrailPtr instantiation_trail,
      TrailPtr bound_trail,
      Heap::Space space) const;
  virtual RawTypeRef* CloneUninstantiated(const Class& new_owner,
                                          TrailPtr trail = NULL) const;
  virtual RawAbstractType* Canonicalize(TrailPtr trail = NULL) const;
#if defined(DEBUG)
  // Check if typeref is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const;
#endif  // DEBUG
  virtual RawString* EnumerateURIs() const;

  virtual intptr_t Hash() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawTypeRef));
  }

  static RawTypeRef* New(const AbstractType& type);

 private:
  static RawTypeRef* New();

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
    ASSERT(raw_ptr()->type_state_ != RawTypeParameter::kFinalizedInstantiated);
    return raw_ptr()->type_state_ == RawTypeParameter::kFinalizedUninstantiated;
  }
  virtual void SetIsFinalized() const;
  virtual bool IsBeingFinalized() const { return false; }
  virtual bool IsMalformed() const { return false; }
  virtual bool IsMalbounded() const { return false; }
  virtual bool IsMalformedOrMalbounded() const { return false; }
  virtual bool IsResolved() const { return true; }
  virtual bool HasResolvedTypeClass() const { return false; }
  classid_t parameterized_class_id() const;
  RawClass* parameterized_class() const;
  RawFunction* parameterized_function() const {
    return raw_ptr()->parameterized_function_;
  }
  bool IsClassTypeParameter() const {
    return parameterized_class_id() != kFunctionCid;
  }
  bool IsFunctionTypeParameter() const {
    return parameterized_function() != Function::null();
  }
  RawString* name() const { return raw_ptr()->name_; }
  intptr_t index() const { return raw_ptr()->index_; }
  void set_index(intptr_t value) const;
  RawAbstractType* bound() const { return raw_ptr()->bound_; }
  void set_bound(const AbstractType& value) const;
  // Returns true if bounded_type is below upper_bound, otherwise return false
  // and set bound_error if both bounded_type and upper_bound are instantiated.
  // If one or both are not instantiated, returning false only means that the
  // bound cannot be checked yet and this is not an error.
  bool CheckBound(const AbstractType& bounded_type,
                  const AbstractType& upper_bound,
                  Error* bound_error,
                  TrailPtr bound_trail,
                  Heap::Space space) const;
  virtual TokenPosition token_pos() const { return raw_ptr()->token_pos_; }
  virtual bool IsInstantiated(Genericity genericity = kAny,
                              intptr_t num_free_fun_type_params = kMaxInt32,
                              TrailPtr trail = NULL) const;
  virtual bool IsEquivalent(const Instance& other, TrailPtr trail = NULL) const;
  virtual bool IsRecursive() const { return false; }
  virtual void SetScopeFunction(const Function& function) const {}
  virtual RawAbstractType* InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      Error* bound_error,
      TrailPtr instantiation_trail,
      TrailPtr bound_trail,
      Heap::Space space) const;
  virtual RawAbstractType* CloneUnfinalized() const;
  virtual RawAbstractType* CloneUninstantiated(const Class& new_owner,
                                               TrailPtr trail = NULL) const;
  virtual RawAbstractType* Canonicalize(TrailPtr trail = NULL) const {
    return raw();
  }
#if defined(DEBUG)
  // Check if type parameter is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const { return true; }
#endif  // DEBUG
  virtual RawString* EnumerateURIs() const;

  virtual intptr_t Hash() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawTypeParameter));
  }

  // Only one of parameterized_class and parameterized_function is non-null.
  static RawTypeParameter* New(const Class& parameterized_class,
                               const Function& parameterized_function,
                               intptr_t index,
                               const String& name,
                               const AbstractType& bound,
                               TokenPosition token_pos);

 private:
  intptr_t ComputeHash() const;
  void SetHash(intptr_t value) const;

  void set_parameterized_class(const Class& value) const;
  void set_parameterized_function(const Function& value) const;
  void set_name(const String& value) const;
  void set_token_pos(TokenPosition token_pos) const;
  void set_type_state(int8_t state) const;

  static RawTypeParameter* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypeParameter, AbstractType);
  friend class Class;
  friend class ClearTypeHashVisitor;
};

// A BoundedType represents a type instantiated at compile time from a type
// parameter specifying a bound that either cannot be checked at compile time
// because the type or the bound are still uninstantiated or can be checked and
// would trigger a bound error in checked mode. The bound must be checked at
// runtime once the type and its bound are instantiated and when the execution
// mode is known to be checked mode.
class BoundedType : public AbstractType {
 public:
  virtual bool IsFinalized() const {
    return AbstractType::Handle(type()).IsFinalized();
  }
  virtual bool IsBeingFinalized() const {
    return AbstractType::Handle(type()).IsBeingFinalized();
  }
  virtual bool IsMalformed() const;
  virtual bool IsMalbounded() const;
  virtual bool IsMalformedOrMalbounded() const;
  virtual RawLanguageError* error() const;
  virtual bool IsResolved() const { return true; }
  virtual bool HasResolvedTypeClass() const {
    return AbstractType::Handle(type()).HasResolvedTypeClass();
  }
  virtual RawClass* type_class() const {
    return AbstractType::Handle(type()).type_class();
  }
  virtual RawUnresolvedClass* unresolved_class() const {
    return AbstractType::Handle(type()).unresolved_class();
  }
  virtual RawTypeArguments* arguments() const {
    return AbstractType::Handle(type()).arguments();
  }
  RawAbstractType* type() const { return raw_ptr()->type_; }
  RawAbstractType* bound() const { return raw_ptr()->bound_; }
  RawTypeParameter* type_parameter() const {
    return raw_ptr()->type_parameter_;
  }
  virtual TokenPosition token_pos() const {
    return AbstractType::Handle(type()).token_pos();
  }
  virtual bool IsInstantiated(Genericity genericity = kAny,
                              intptr_t num_free_fun_type_params = kMaxInt32,
                              TrailPtr trail = NULL) const {
    // It is not possible to encounter an instantiated bounded type with an
    // uninstantiated upper bound. Therefore, we do not need to check if the
    // bound is instantiated. Moreover, doing so could lead into cycles, as in
    // class C<T extends C<C>> { }.
    return AbstractType::Handle(type()).IsInstantiated(
        genericity, num_free_fun_type_params, trail);
  }
  virtual bool IsEquivalent(const Instance& other, TrailPtr trail = NULL) const;
  virtual bool IsRecursive() const;
  virtual void SetScopeFunction(const Function& function) const;
  virtual RawAbstractType* InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      Error* bound_error,
      TrailPtr instantiation_trail,
      TrailPtr bound_trail,
      Heap::Space space) const;
  virtual RawAbstractType* CloneUnfinalized() const;
  virtual RawAbstractType* CloneUninstantiated(const Class& new_owner,
                                               TrailPtr trail = NULL) const;
  virtual RawAbstractType* Canonicalize(TrailPtr trail = NULL) const {
    return raw();
  }
#if defined(DEBUG)
  // Check if bounded type is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const { return true; }
#endif  // DEBUG
  virtual RawString* EnumerateURIs() const;

  virtual intptr_t Hash() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawBoundedType));
  }

  static RawBoundedType* New(const AbstractType& type,
                             const AbstractType& bound,
                             const TypeParameter& type_parameter);

 private:
  intptr_t ComputeHash() const;
  void SetHash(intptr_t value) const;

  void set_type(const AbstractType& value) const;
  void set_bound(const AbstractType& value) const;
  void set_type_parameter(const TypeParameter& value) const;

  static RawBoundedType* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(BoundedType, AbstractType);
  friend class Class;
  friend class ClearTypeHashVisitor;
};

// A MixinAppType represents a parsed mixin application clause, e.g.
// "S<T> with M<U>, N<V>".
// MixinAppType objects do not survive finalization, so they do not
// need to be written to and read from snapshots.
// The class finalizer creates synthesized classes S&M and S&M&N if they do not
// yet exist in the library declaring the mixin application clause.
class MixinAppType : public AbstractType {
 public:
  // A MixinAppType object is unfinalized by definition, since it is replaced at
  // class finalization time with a finalized (and possibly malformed or
  // malbounded) Type object.
  virtual bool IsFinalized() const { return false; }
  virtual bool IsMalformed() const { return false; }
  virtual bool IsMalbounded() const { return false; }
  virtual bool IsMalformedOrMalbounded() const { return false; }
  virtual bool IsResolved() const { return false; }
  virtual bool HasResolvedTypeClass() const { return false; }
  virtual RawString* Name() const;
  virtual TokenPosition token_pos() const;

  // Returns the mixin composition depth of this mixin application type.
  intptr_t Depth() const;

  // Returns the declared super type of the mixin application, which will also
  // be the super type of the first synthesized class, e.g. class "S&M" will
  // refer to super type "S<T>".
  RawAbstractType* super_type() const { return raw_ptr()->super_type_; }

  // Returns the mixin type at the given mixin composition depth, e.g. N<V> at
  // depth 0 and M<U> at depth 1.
  RawAbstractType* MixinTypeAt(intptr_t depth) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawMixinAppType));
  }

  static RawMixinAppType* New(const AbstractType& super_type,
                              const Array& mixin_types);

 private:
  void set_super_type(const AbstractType& value) const;

  RawArray* mixin_types() const { return raw_ptr()->mixin_types_; }
  void set_mixin_types(const Array& value) const;

  static RawMixinAppType* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(MixinAppType, AbstractType);
  friend class Class;
};

class Number : public Instance {
 public:
  // TODO(iposva): Add more useful Number methods.
  RawString* ToString(Heap::Space space) const;

  // Numbers are canonicalized differently from other instances/strings.
  virtual RawInstance* CheckAndCanonicalize(Thread* thread,
                                            const char** error_str) const;

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
  static RawInteger* New(const String& str, Heap::Space space = Heap::kNew);

  // Creates a new Integer by given uint64_t value.
  // In the --limit-ints-to-64-bits mode silently casts value to int64_t
  // (with wrap-around if it is greater than kMaxInt64).
  static RawInteger* NewFromUint64(uint64_t value,
                                   Heap::Space space = Heap::kNew);

  // Returns a canonical Integer object allocated in the old gen space.
  // Returns null if integer is out of range (in --limit-ints-to-64-bits mode).
  static RawInteger* NewCanonical(const String& str);

  static RawInteger* New(int64_t value, Heap::Space space = Heap::kNew);

  // Returns true iff the given uint64_t value is representable as Dart integer.
  static bool IsValueInRange(uint64_t value);

  virtual bool OperatorEquals(const Instance& other) const {
    return Equals(other);
  }
  virtual bool CanonicalizeEquals(const Instance& other) const {
    return Equals(other);
  }
  virtual uword ComputeCanonicalTableHash() const {
    UNREACHABLE();
    return 0;
  }
  virtual bool Equals(const Instance& other) const;

  virtual RawObject* HashCode() const { return raw(); }

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
  // TODO(alexmarkov): this method can become non-virtual once Bigint class is
  // decoupled from Integer hierarchy.
  virtual const char* ToHexCString(Zone* zone) const;

  // Return the most compact presentation of an integer.
  RawInteger* AsValidInteger() const;

  // Returns null to indicate that a bigint operation is required.
  RawInteger* ArithmeticOp(Token::Kind operation,
                           const Integer& other,
                           Heap::Space space = Heap::kNew) const;
  RawInteger* BitOp(Token::Kind operation,
                    const Integer& other,
                    Heap::Space space = Heap::kNew) const;

 private:
  OBJECT_IMPLEMENTATION(Integer, Number);
  friend class Class;
};

class Smi : public Integer {
 public:
  static const intptr_t kBits = kSmiBits;
  static const intptr_t kMaxValue = kSmiMax;
  static const intptr_t kMinValue = kSmiMin;

  intptr_t Value() const { return ValueFromRaw(raw_value()); }

  virtual bool Equals(const Instance& other) const;
  virtual bool IsZero() const { return Value() == 0; }
  virtual bool IsNegative() const { return Value() < 0; }

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;
  virtual uint32_t AsTruncatedUint32Value() const;

  virtual bool FitsIntoSmi() const { return true; }

  virtual int CompareWith(const Integer& other) const;

  static intptr_t InstanceSize() { return 0; }

  static RawSmi* New(intptr_t value) {
    intptr_t raw_smi = (value << kSmiTagShift) | kSmiTag;
    ASSERT(ValueFromRaw(raw_smi) == value);
    return reinterpret_cast<RawSmi*>(raw_smi);
  }

  static RawSmi* FromAlignedAddress(uword address) {
    ASSERT((address & kSmiTagMask) == kSmiTag);
    return reinterpret_cast<RawSmi*>(address);
  }

  static RawClass* Class();

  static intptr_t Value(const RawSmi* raw_smi) {
    return ValueFromRaw(reinterpret_cast<uword>(raw_smi));
  }

  static intptr_t RawValue(intptr_t value) {
    return reinterpret_cast<intptr_t>(New(value));
  }

  static bool IsValid(int64_t value) {
    return (value >= kMinValue) && (value <= kMaxValue);
  }

  RawInteger* ShiftOp(Token::Kind kind,
                      const Smi& other,
                      Heap::Space space = Heap::kNew) const;

  void operator=(RawSmi* value) {
    raw_ = value;
    CHECK_HANDLE();
  }
  void operator^=(RawObject* value) {
    raw_ = value;
    CHECK_HANDLE();
  }

 private:
  static intptr_t NextFieldOffset() {
    // Indicates this class cannot be extended by dart code.
    return -kWordSize;
  }

  static intptr_t ValueFromRaw(uword raw_value) {
    intptr_t value = raw_value;
    ASSERT((value & kSmiTagMask) == kSmiTag);
    return (value >> kSmiTagShift);
  }

  static cpp_vtable handle_vtable_;

  Smi() : Integer() {}
  BASE_OBJECT_IMPLEMENTATION(Smi, Integer);
  OBJECT_SERVICE_SUPPORT(Smi);
  friend class Api;  // For ValueFromRaw
  friend class Class;
  friend class Object;
  friend class ReusableSmiHandleScope;
  friend class Thread;
};

class Mint : public Integer {
 public:
  static const intptr_t kBits = 63;  // 64-th bit is sign.
  static const int64_t kMaxValue =
      static_cast<int64_t>(DART_2PART_UINT64_C(0x7FFFFFFF, FFFFFFFF));
  static const int64_t kMinValue =
      static_cast<int64_t>(DART_2PART_UINT64_C(0x80000000, 00000000));

  int64_t value() const { return raw_ptr()->value_; }
  static intptr_t value_offset() { return OFFSET_OF(RawMint, value_); }

  virtual bool IsZero() const { return value() == 0; }
  virtual bool IsNegative() const { return value() < 0; }

  virtual bool Equals(const Instance& other) const;

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;
  virtual uint32_t AsTruncatedUint32Value() const;

  virtual bool FitsIntoSmi() const;

  virtual int CompareWith(const Integer& other) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawMint));
  }

 protected:
  // Only Integer::NewXXX is allowed to call Mint::NewXXX directly.
  friend class Integer;

  static RawMint* New(int64_t value, Heap::Space space = Heap::kNew);

  static RawMint* NewCanonical(int64_t value);

 private:
  void set_value(int64_t value) const;

  MINT_OBJECT_IMPLEMENTATION(Mint, Integer, Integer);
  friend class Class;
  friend class Number;
};

class Bigint : public Integer {
 public:
  virtual bool IsZero() const { return Used() == 0; }
  virtual bool IsNegative() const { return Neg(); }
  virtual bool Equals(const Instance& other) const;

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;
  virtual int64_t AsTruncatedInt64Value() const;
  virtual uint32_t AsTruncatedUint32Value() const;

  virtual int CompareWith(const Integer& other) const;

  virtual const char* ToHexCString(Zone* zone) const;

  virtual bool CheckAndCanonicalizeFields(Thread* thread,
                                          const char** error_str) const;

  virtual bool FitsIntoSmi() const;
  bool FitsIntoInt64() const;
  bool FitsIntoUint64() const;
  uint64_t AsUint64Value() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawBigint));
  }

  // Offsets of fields accessed directly by optimized code.
  static intptr_t neg_offset() { return OFFSET_OF(RawBigint, neg_); }
  static intptr_t used_offset() { return OFFSET_OF(RawBigint, used_); }
  static intptr_t digits_offset() { return OFFSET_OF(RawBigint, digits_); }

  // Accessors used by native calls from Dart.
  RawBool* neg() const { return raw_ptr()->neg_; }
  RawSmi* used() const { return raw_ptr()->used_; }
  RawTypedData* digits() const { return raw_ptr()->digits_; }

  // Accessors used by runtime calls from C++.
  bool Neg() const;
  intptr_t Used() const;
  uint32_t DigitAt(intptr_t index) const;

  const char* ToDecCString(Zone* zone) const;

  static const intptr_t kBitsPerDigit = 32;  // Same as _Bigint._DIGIT_BITS
  static const intptr_t kBytesPerDigit = 4;
  static const int64_t kDigitBase = 1LL << kBitsPerDigit;
  static const int64_t kDigitMask = kDigitBase - 1;

  static RawBigint* New(Heap::Space space = Heap::kNew);  // For snapshots.

  static RawBigint* New(bool neg,
                        intptr_t used,
                        const TypedData& digits,
                        Heap::Space space = Heap::kNew);

  static RawBigint* NewFromInt64(int64_t value, Heap::Space space = Heap::kNew);

  static RawBigint* NewFromUint64(uint64_t value,
                                  Heap::Space space = Heap::kNew);

  static RawBigint* NewFromShiftedInt64(int64_t value,
                                        intptr_t shift,
                                        Heap::Space space = Heap::kNew);

  static RawBigint* NewFromCString(const char* str,
                                   Heap::Space space = Heap::kNew);

  // Returns a canonical Bigint object allocated in the old gen space.
  static RawBigint* NewCanonical(const String& str);

  // Returns true if Bigint can't be instantiated.
  static bool IsDisabled() { return FLAG_limit_ints_to_64_bits; }

 private:
  void SetNeg(bool value) const;
  void SetUsed(intptr_t value) const;
  void set_digits(const TypedData& value) const;

  // Convenience helpers.
  static RawTypedData* NewDigits(intptr_t length,
                                 Heap::Space space = Heap::kNew);
  static uint32_t DigitAt(const TypedData& digits, intptr_t index);
  static void SetDigitAt(const TypedData& digits,
                         intptr_t index,
                         uint32_t value);

  static RawTypedData* NewDigitsFromHexCString(const char* str,
                                               intptr_t* used,
                                               Heap::Space space = Heap::kNew);

  static RawTypedData* NewDigitsFromDecCString(const char* str,
                                               intptr_t* used,
                                               Heap::Space space = Heap::kNew);

  static RawBigint* Allocate(intptr_t length, Heap::Space space = Heap::kNew);

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Bigint, Integer);
  friend class Class;
};

// Class Double represents class Double in corelib_impl, which implements
// abstract class double in corelib.
class Double : public Number {
 public:
  double value() const { return raw_ptr()->value_; }

  bool BitwiseEqualsToDouble(double value) const;
  virtual bool OperatorEquals(const Instance& other) const;
  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uword ComputeCanonicalTableHash() const {
    UNREACHABLE();
    return 0;
  }

  static RawDouble* New(double d, Heap::Space space = Heap::kNew);

  static RawDouble* New(const String& str, Heap::Space space = Heap::kNew);

  // Returns a canonical double object allocated in the old gen space.
  static RawDouble* NewCanonical(double d);

  // Returns a canonical double object (allocated in the old gen space) or
  // Double::null() if str points to a string that does not convert to a
  // double value.
  static RawDouble* NewCanonical(const String& str);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawDouble));
  }

  static intptr_t value_offset() { return OFFSET_OF(RawDouble, value_); }

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
  static const intptr_t kSizeofRawString = sizeof(RawInstance) + kWordSize;
#else
  static const intptr_t kSizeofRawString = sizeof(RawInstance) + 2 * kWordSize;
#endif
  static const intptr_t kMaxElements = kSmiMax / kTwoByteChar;

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

  intptr_t Length() const { return Smi::Value(raw_ptr()->length_); }
  static intptr_t length_offset() { return OFFSET_OF(RawString, length_); }

  intptr_t Hash() const {
    intptr_t result = GetCachedHash(raw());
    if (result != 0) {
      return result;
    }
    result = String::Hash(*this, 0, this->Length());
    SetCachedHash(raw(), result);
    return result;
  }

  static intptr_t Hash(RawString* raw);

  bool HasHash() const {
    ASSERT(Smi::New(0) == NULL);
    return GetCachedHash(raw()) != 0;
  }

  static intptr_t hash_offset() { return OFFSET_OF(RawString, hash_); }
  static intptr_t Hash(const String& str, intptr_t begin_index, intptr_t len);
  static intptr_t Hash(const char* characters, intptr_t len);
  static intptr_t Hash(const uint16_t* characters, intptr_t len);
  static intptr_t Hash(const int32_t* characters, intptr_t len);
  static intptr_t HashRawSymbol(const RawString* symbol) {
    ASSERT(symbol->IsCanonical());
    intptr_t result = GetCachedHash(symbol);
    ASSERT(result != 0);
    return result;
  }

  // Returns the hash of str1 + str2.
  static intptr_t HashConcat(const String& str1, const String& str2);

  virtual RawObject* HashCode() const { return Integer::New(Hash()); }

  uint16_t CharAt(intptr_t index) const;

  Scanner::CharAtFunc CharAtFunc() const;

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
  virtual uword ComputeCanonicalTableHash() const {
    UNREACHABLE();
    return 0;
  }
  virtual bool Equals(const Instance& other) const;

  intptr_t CompareTo(const String& other) const;

  bool StartsWith(const String& other) const;

  // Strings are canonicalized using the symbol table.
  virtual RawInstance* CheckAndCanonicalize(Thread* thread,
                                            const char** error_str) const;

#if defined(DEBUG)
  // Check if string is canonical.
  virtual bool CheckIsCanonical(Thread* thread) const;
#endif  // DEBUG

  bool IsSymbol() const { return raw()->IsCanonical(); }

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
    return RawObject::IsExternalStringClassId(raw()->GetClassId());
  }

  void* GetPeer() const;

  void ToUTF8(uint8_t* utf8_array, intptr_t array_len) const;

  // Creates a new String object from a C string that is assumed to contain
  // UTF-8 encoded characters and '\0' is considered a termination character.
  // TODO(7123) - Rename this to FromCString(....).
  static RawString* New(const char* cstr, Heap::Space space = Heap::kNew);

  // Creates a new String object from an array of UTF-8 encoded characters.
  static RawString* FromUTF8(const uint8_t* utf8_array,
                             intptr_t array_len,
                             Heap::Space space = Heap::kNew);

  // Creates a new String object from an array of Latin-1 encoded characters.
  static RawString* FromLatin1(const uint8_t* latin1_array,
                               intptr_t array_len,
                               Heap::Space space = Heap::kNew);

  // Creates a new String object from an array of UTF-16 encoded characters.
  static RawString* FromUTF16(const uint16_t* utf16_array,
                              intptr_t array_len,
                              Heap::Space space = Heap::kNew);

  // Creates a new String object from an array of UTF-32 encoded characters.
  static RawString* FromUTF32(const int32_t* utf32_array,
                              intptr_t array_len,
                              Heap::Space space = Heap::kNew);

  // Create a new String object from another Dart String instance.
  static RawString* New(const String& str, Heap::Space space = Heap::kNew);

  // Creates a new External String object using the specified array of
  // UTF-8 encoded characters as the external reference.
  static RawString* NewExternal(const uint8_t* utf8_array,
                                intptr_t array_len,
                                void* peer,
                                Dart_PeerFinalizer callback,
                                Heap::Space = Heap::kNew);

  // Creates a new External String object using the specified array of
  // UTF-16 encoded characters as the external reference.
  static RawString* NewExternal(const uint16_t* utf16_array,
                                intptr_t array_len,
                                void* peer,
                                Dart_PeerFinalizer callback,
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

  static RawString* EscapeSpecialCharacters(const String& str);
  // Encodes 'str' for use in an Internationalized Resource Identifier (IRI),
  // a generalization of URI (percent-encoding). See RFC 3987.
  static const char* EncodeIRI(const String& str);
  // Returns null if 'str' is not a valid encoding.
  static RawString* DecodeIRI(const String& str);
  static RawString* Concat(const String& str1,
                           const String& str2,
                           Heap::Space space = Heap::kNew);
  static RawString* ConcatAll(const Array& strings,
                              Heap::Space space = Heap::kNew);
  // Concat all strings in 'strings' from 'start' to 'end' (excluding).
  static RawString* ConcatAllRange(const Array& strings,
                                   intptr_t start,
                                   intptr_t end,
                                   Heap::Space space = Heap::kNew);

  static RawString* SubString(const String& str,
                              intptr_t begin_index,
                              Heap::Space space = Heap::kNew);
  static RawString* SubString(const String& str,
                              intptr_t begin_index,
                              intptr_t length,
                              Heap::Space space = Heap::kNew) {
    return SubString(Thread::Current(), str, begin_index, length, space);
  }
  static RawString* SubString(Thread* thread,
                              const String& str,
                              intptr_t begin_index,
                              intptr_t length,
                              Heap::Space space = Heap::kNew);

  static RawString* Transform(int32_t (*mapping)(int32_t ch),
                              const String& str,
                              Heap::Space space = Heap::kNew);

  static RawString* ToUpperCase(const String& str,
                                Heap::Space space = Heap::kNew);
  static RawString* ToLowerCase(const String& str,
                                Heap::Space space = Heap::kNew);

  static RawString* RemovePrivateKey(const String& name);

  static RawString* ScrubName(const String& name);
  static RawString* ScrubNameRetainPrivate(const String& name);

  static bool EqualsIgnoringPrivateKey(const String& str1, const String& str2);

  static RawString* NewFormatted(const char* format, ...)
      PRINTF_ATTRIBUTE(1, 2);
  static RawString* NewFormatted(Heap::Space space, const char* format, ...)
      PRINTF_ATTRIBUTE(2, 3);
  static RawString* NewFormattedV(const char* format,
                                  va_list args,
                                  Heap::Space space = Heap::kNew);

  static bool ParseDouble(const String& str,
                          intptr_t start,
                          intptr_t end,
                          double* result);

#if !defined(HASH_IN_OBJECT_HEADER)
  static uint32_t GetCachedHash(const RawString* obj) {
    return Smi::Value(obj->ptr()->hash_);
  }

  static void SetCachedHash(RawString* obj, uintptr_t hash) {
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
    StoreSmi(&raw_ptr()->length_, Smi::New(value));
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
  // So that SkippedCodeFunctions can print a debug string from a NoHandleScope.
  friend class SkippedCodeFunctions;
  friend class RawOneByteString;
  friend class RODataSerializationCluster;  // SetHash
};

class OneByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsOneByteString());
    return raw_ptr(str)->data()[index];
  }

  static void SetCharAt(const String& str, intptr_t index, uint8_t code_unit) {
    NoSafepointScope no_safepoint;
    *CharAddr(str, index) = code_unit;
  }
  static RawOneByteString* EscapeSpecialCharacters(const String& str);
  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(RawOneByteString, data);
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawOneByteString) ==
           OFFSET_OF_RETURNED_VALUE(RawOneByteString, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(sizeof(RawOneByteString) == String::kSizeofRawString);
    ASSERT(0 <= len && len <= kMaxElements);
#if defined(HASH_IN_OBJECT_HEADER)
    // We have to pad zero-length raw strings so that they can be externalized.
    // If we don't pad, then the external string object does not fit in the
    // memory allocated for the raw string.
    if (len == 0) return InstanceSize(1);
#endif
    return String::RoundedAllocationSize(sizeof(RawOneByteString) +
                                         (len * kBytesPerElement));
  }

  static RawOneByteString* New(intptr_t len, Heap::Space space);
  static RawOneByteString* New(const char* c_string,
                               Heap::Space space = Heap::kNew) {
    return New(reinterpret_cast<const uint8_t*>(c_string), strlen(c_string),
               space);
  }
  static RawOneByteString* New(const uint8_t* characters,
                               intptr_t len,
                               Heap::Space space);
  static RawOneByteString* New(const uint16_t* characters,
                               intptr_t len,
                               Heap::Space space);
  static RawOneByteString* New(const int32_t* characters,
                               intptr_t len,
                               Heap::Space space);
  static RawOneByteString* New(const String& str, Heap::Space space);
  // 'other' must be OneByteString.
  static RawOneByteString* New(const String& other_one_byte_string,
                               intptr_t other_start_index,
                               intptr_t other_len,
                               Heap::Space space);

  static RawOneByteString* New(const TypedData& other_typed_data,
                               intptr_t other_start_index,
                               intptr_t other_len,
                               Heap::Space space = Heap::kNew);

  static RawOneByteString* New(const ExternalTypedData& other_typed_data,
                               intptr_t other_start_index,
                               intptr_t other_len,
                               Heap::Space space = Heap::kNew);

  static RawOneByteString* Concat(const String& str1,
                                  const String& str2,
                                  Heap::Space space);
  static RawOneByteString* ConcatAll(const Array& strings,
                                     intptr_t start,
                                     intptr_t end,
                                     intptr_t len,
                                     Heap::Space space);

  static RawOneByteString* Transform(int32_t (*mapping)(int32_t ch),
                                     const String& str,
                                     Heap::Space space);

  // High performance version of substring for one-byte strings.
  // "str" must be OneByteString.
  static RawOneByteString* SubStringUnchecked(const String& str,
                                              intptr_t begin_index,
                                              intptr_t length,
                                              Heap::Space space);

  static void SetPeer(const String& str,
                      intptr_t external_size,
                      void* peer,
                      Dart_PeerFinalizer cback);

  static void Finalize(void* isolate_callback_data,
                       Dart_WeakPersistentHandle handle,
                       void* peer);

  static const ClassId kClassId = kOneByteStringCid;

  static RawOneByteString* null() {
    return reinterpret_cast<RawOneByteString*>(Object::null());
  }

 private:
  static RawOneByteString* raw(const String& str) {
    return reinterpret_cast<RawOneByteString*>(str.raw());
  }

  static const RawOneByteString* raw_ptr(const String& str) {
    return reinterpret_cast<const RawOneByteString*>(str.raw_ptr());
  }

  static uint8_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsOneByteString());
    return &str.UnsafeMutableNonPointer(raw_ptr(str)->data())[index];
  }

  static RawOneByteString* ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    intptr_t tags,
                                    Snapshot::Kind kind,
                                    bool as_reference);

  friend class Class;
  friend class String;
  friend class Symbols;
  friend class ExternalOneByteString;
  friend class SnapshotReader;
  friend class StringHasher;
};

class TwoByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsTwoByteString());
    return raw_ptr(str)->data()[index];
  }

  static void SetCharAt(const String& str, intptr_t index, uint16_t ch) {
    NoSafepointScope no_safepoint;
    *CharAddr(str, index) = ch;
  }

  static RawTwoByteString* EscapeSpecialCharacters(const String& str);

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 2;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(RawTwoByteString, data);
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawTwoByteString) ==
           OFFSET_OF_RETURNED_VALUE(RawTwoByteString, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(sizeof(RawTwoByteString) == String::kSizeofRawString);
    ASSERT(0 <= len && len <= kMaxElements);
    // We have to pad zero-length raw strings so that they can be externalized.
    // If we don't pad, then the external string object does not fit in the
    // memory allocated for the raw string.
    if (len == 0) return InstanceSize(1);
    return String::RoundedAllocationSize(sizeof(RawTwoByteString) +
                                         (len * kBytesPerElement));
  }

  static RawTwoByteString* New(intptr_t len, Heap::Space space);
  static RawTwoByteString* New(const uint16_t* characters,
                               intptr_t len,
                               Heap::Space space);
  static RawTwoByteString* New(intptr_t utf16_len,
                               const int32_t* characters,
                               intptr_t len,
                               Heap::Space space);
  static RawTwoByteString* New(const String& str, Heap::Space space);

  static RawTwoByteString* New(const TypedData& other_typed_data,
                               intptr_t other_start_index,
                               intptr_t other_len,
                               Heap::Space space = Heap::kNew);

  static RawTwoByteString* New(const ExternalTypedData& other_typed_data,
                               intptr_t other_start_index,
                               intptr_t other_len,
                               Heap::Space space = Heap::kNew);

  static RawTwoByteString* Concat(const String& str1,
                                  const String& str2,
                                  Heap::Space space);
  static RawTwoByteString* ConcatAll(const Array& strings,
                                     intptr_t start,
                                     intptr_t end,
                                     intptr_t len,
                                     Heap::Space space);

  static RawTwoByteString* Transform(int32_t (*mapping)(int32_t ch),
                                     const String& str,
                                     Heap::Space space);

  static void SetPeer(const String& str,
                      intptr_t external_size,
                      void* peer,
                      Dart_PeerFinalizer cback);

  static void Finalize(void* isolate_callback_data,
                       Dart_WeakPersistentHandle handle,
                       void* peer);

  static RawTwoByteString* null() {
    return reinterpret_cast<RawTwoByteString*>(Object::null());
  }

  static const ClassId kClassId = kTwoByteStringCid;

 private:
  static RawTwoByteString* raw(const String& str) {
    return reinterpret_cast<RawTwoByteString*>(str.raw());
  }

  static const RawTwoByteString* raw_ptr(const String& str) {
    return reinterpret_cast<const RawTwoByteString*>(str.raw_ptr());
  }

  static uint16_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsTwoByteString());
    return &str.UnsafeMutableNonPointer(raw_ptr(str)->data())[index];
  }

  static RawTwoByteString* ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    intptr_t tags,
                                    Snapshot::Kind kind,
                                    bool as_reference);

  friend class Class;
  friend class String;
  friend class SnapshotReader;
  friend class Symbols;
};

class ExternalOneByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    NoSafepointScope no_safepoint;
    return *CharAddr(str, index);
  }

  static void* GetPeer(const String& str) {
    return raw_ptr(str)->external_data_->peer();
  }

  static intptr_t external_data_offset() {
    return OFFSET_OF(RawExternalOneByteString, external_data_);
  }

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    return String::RoundedAllocationSize(sizeof(RawExternalOneByteString));
  }

  static RawExternalOneByteString* New(const uint8_t* characters,
                                       intptr_t len,
                                       void* peer,
                                       Dart_PeerFinalizer callback,
                                       Heap::Space space);

  static RawExternalOneByteString* null() {
    return reinterpret_cast<RawExternalOneByteString*>(Object::null());
  }

  static RawOneByteString* EscapeSpecialCharacters(const String& str);
  static RawOneByteString* EncodeIRI(const String& str);
  static RawOneByteString* DecodeIRI(const String& str);

  static const ClassId kClassId = kExternalOneByteStringCid;

 private:
  static RawExternalOneByteString* raw(const String& str) {
    return reinterpret_cast<RawExternalOneByteString*>(str.raw());
  }

  static const RawExternalOneByteString* raw_ptr(const String& str) {
    return reinterpret_cast<const RawExternalOneByteString*>(str.raw_ptr());
  }

  static const uint8_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsExternalOneByteString());
    return &(raw_ptr(str)->external_data_->data()[index]);
  }

  static void SetExternalData(const String& str,
                              ExternalStringData<uint8_t>* data) {
    ASSERT(str.IsExternalOneByteString());
    ASSERT(!Isolate::Current()->heap()->Contains(
        reinterpret_cast<uword>(data->data())));
    str.StoreNonPointer(&raw_ptr(str)->external_data_, data);
  }

  static void Finalize(void* isolate_callback_data,
                       Dart_WeakPersistentHandle handle,
                       void* peer);

  static RawExternalOneByteString* ReadFrom(SnapshotReader* reader,
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
  friend class SnapshotReader;
  friend class Symbols;
};

class ExternalTwoByteString : public AllStatic {
 public:
  static uint16_t CharAt(const String& str, intptr_t index) {
    NoSafepointScope no_safepoint;
    return *CharAddr(str, index);
  }

  static void* GetPeer(const String& str) {
    return raw_ptr(str)->external_data_->peer();
  }

  static intptr_t external_data_offset() {
    return OFFSET_OF(RawExternalTwoByteString, external_data_);
  }

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 2;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    return String::RoundedAllocationSize(sizeof(RawExternalTwoByteString));
  }

  static RawExternalTwoByteString* New(const uint16_t* characters,
                                       intptr_t len,
                                       void* peer,
                                       Dart_PeerFinalizer callback,
                                       Heap::Space space = Heap::kNew);

  static RawExternalTwoByteString* null() {
    return reinterpret_cast<RawExternalTwoByteString*>(Object::null());
  }

  static const ClassId kClassId = kExternalTwoByteStringCid;

 private:
  static RawExternalTwoByteString* raw(const String& str) {
    return reinterpret_cast<RawExternalTwoByteString*>(str.raw());
  }

  static const RawExternalTwoByteString* raw_ptr(const String& str) {
    return reinterpret_cast<const RawExternalTwoByteString*>(str.raw_ptr());
  }

  static const uint16_t* CharAddr(const String& str, intptr_t index) {
    ASSERT((index >= 0) && (index < str.Length()));
    ASSERT(str.IsExternalTwoByteString());
    return &(raw_ptr(str)->external_data_->data()[index]);
  }

  static void SetExternalData(const String& str,
                              ExternalStringData<uint16_t>* data) {
    ASSERT(str.IsExternalTwoByteString());
    ASSERT(!Isolate::Current()->heap()->Contains(
        reinterpret_cast<uword>(data->data())));
    str.StoreNonPointer(&raw_ptr(str)->external_data_, data);
  }

  static void Finalize(void* isolate_callback_data,
                       Dart_WeakPersistentHandle handle,
                       void* peer);

  static RawExternalTwoByteString* ReadFrom(SnapshotReader* reader,
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
  friend class SnapshotReader;
  friend class Symbols;
};

// Class Bool implements Dart core class bool.
class Bool : public Instance {
 public:
  bool value() const { return raw_ptr()->value_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawBool));
  }

  static const Bool& True() { return Object::bool_true(); }

  static const Bool& False() { return Object::bool_false(); }

  static const Bool& Get(bool value) {
    return value ? Bool::True() : Bool::False();
  }

 private:
  void set_value(bool value) const {
    StoreNonPointer(&raw_ptr()->value_, value);
  }

  // New should only be called to initialize the two legal bool values.
  static RawBool* New(bool value);

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

  intptr_t Length() const {
    ASSERT(!IsNull());
    return Smi::Value(raw_ptr()->length_);
  }
  static intptr_t length_offset() { return OFFSET_OF(RawArray, length_); }
  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(RawArray, data);
  }
  static intptr_t element_offset(intptr_t index) {
    return OFFSET_OF_RETURNED_VALUE(RawArray, data) + kWordSize * index;
  }

  RawObject* At(intptr_t index) const { return *ObjectAddr(index); }
  void SetAt(intptr_t index, const Object& value) const {
    // TODO(iposva): Add storing NoSafepointScope.
    StorePointer(ObjectAddr(index), value.raw());
  }

  bool IsImmutable() const { return raw()->GetClassId() == kImmutableArrayCid; }

  virtual RawTypeArguments* GetTypeArguments() const {
    return raw_ptr()->type_arguments_;
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
    StorePointer(&raw_ptr()->type_arguments_, value.raw());
  }

  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uword ComputeCanonicalTableHash() const;

  static const intptr_t kBytesPerElement = kWordSize;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t type_arguments_offset() {
    return OFFSET_OF(RawArray, type_arguments_);
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawArray) == OFFSET_OF_RETURNED_VALUE(RawArray, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    // Ensure that variable length data is not adding to the object length.
    ASSERT(sizeof(RawArray) == (sizeof(RawInstance) + (2 * kWordSize)));
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawArray) + (len * kBytesPerElement));
  }

  // Returns true if all elements are OK for canonicalization.
  virtual bool CheckAndCanonicalizeFields(Thread* thread,
                                          const char** error_str) const;

  // Make the array immutable to Dart code by switching the class pointer
  // to ImmutableArray.
  void MakeImmutable() const;

  static RawArray* New(intptr_t len, Heap::Space space = Heap::kNew);

  // Creates and returns a new array with 'new_length'. Copies all elements from
  // 'source' to the new array. 'new_length' must be greater than or equal to
  // 'source.Length()'. 'source' can be null.
  static RawArray* Grow(const Array& source,
                        intptr_t new_length,
                        Heap::Space space = Heap::kNew);

  // Return an Array object that contains all the elements currently present
  // in the specified Growable Object Array. This is done by first truncating
  // the Growable Object Array's backing array to the currently used size and
  // returning the truncated backing array.
  // The remaining unused part of the backing array is marked as an Array
  // object or a regular Object so that it can be traversed during garbage
  // collection. The backing array of the original Growable Object Array is
  // set to an empty array.
  // If the unique parameter is false, the function is allowed to return
  // a shared Array instance.
  static RawArray* MakeFixedLength(const GrowableObjectArray& growable_array,
                                   bool unique = false);

  RawArray* Slice(intptr_t start,
                  intptr_t count,
                  bool with_type_argument) const;

 protected:
  static RawArray* New(intptr_t class_id,
                       intptr_t len,
                       Heap::Space space = Heap::kNew);

 private:
  RawObject* const* ObjectAddr(intptr_t index) const {
    // TODO(iposva): Determine if we should throw an exception here.
    ASSERT((index >= 0) && (index < Length()));
    return &raw_ptr()->data()[index];
  }

  void SetLength(intptr_t value) const {
    // This is only safe because we create a new Smi, which does not cause
    // heap allocation.
    StoreSmi(&raw_ptr()->length_, Smi::New(value));
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Array, Instance);
  friend class Class;
  friend class ImmutableArray;
  friend class Object;
  friend class String;
};

class ImmutableArray : public AllStatic {
 public:
  static RawImmutableArray* New(intptr_t len, Heap::Space space = Heap::kNew);

  static RawImmutableArray* ReadFrom(SnapshotReader* reader,
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

  static RawImmutableArray* raw(const Array& array) {
    return reinterpret_cast<RawImmutableArray*>(array.raw());
  }

  friend class Class;
};

class GrowableObjectArray : public Instance {
 public:
  intptr_t Capacity() const {
    NoSafepointScope no_safepoint;
    ASSERT(!IsNull());
    return Smi::Value(DataArray()->length_);
  }
  intptr_t Length() const {
    ASSERT(!IsNull());
    return Smi::Value(raw_ptr()->length_);
  }
  void SetLength(intptr_t value) const {
    // This is only safe because we create a new Smi, which does not cause
    // heap allocation.
    StoreSmi(&raw_ptr()->length_, Smi::New(value));
  }

  RawArray* data() const { return raw_ptr()->data_; }
  void SetData(const Array& value) const {
    StorePointer(&raw_ptr()->data_, value.raw());
  }

  RawObject* At(intptr_t index) const {
    NoSafepointScope no_safepoint;
    ASSERT(!IsNull());
    ASSERT(index < Length());
    return *ObjectAddr(index);
  }
  void SetAt(intptr_t index, const Object& value) const {
    ASSERT(!IsNull());
    ASSERT(index < Length());

    // TODO(iposva): Add storing NoSafepointScope.
    data()->StorePointer(ObjectAddr(index), value.raw());
  }

  void Add(const Object& value, Heap::Space space = Heap::kNew) const;

  void Grow(intptr_t new_capacity, Heap::Space space = Heap::kNew) const;
  RawObject* RemoveLast() const;

  virtual RawTypeArguments* GetTypeArguments() const {
    return raw_ptr()->type_arguments_;
  }
  virtual void SetTypeArguments(const TypeArguments& value) const {
    // A GrowableObjectArray is raw or takes one type argument. However, its
    // type argument vector may be longer than 1 due to a type optimization
    // reusing the type argument vector of the instantiator.
    ASSERT(value.IsNull() || ((value.Length() >= 1) && value.IsInstantiated() &&
                              value.IsCanonical()));
    StorePointer(&raw_ptr()->type_arguments_, value.raw());
  }

  // We don't expect a growable object array to be canonicalized.
  virtual bool CanonicalizeEquals(const Instance& other) const {
    UNREACHABLE();
    return false;
  }
  virtual uword ComputeCanonicalTableHash() const {
    UNREACHABLE();
    return 0;
  }

  // We don't expect a growable object array to be canonicalized.
  virtual RawInstance* CheckAndCanonicalize(Thread* thread,
                                            const char** error_str) const {
    UNREACHABLE();
    return Instance::null();
  }

  static intptr_t type_arguments_offset() {
    return OFFSET_OF(RawGrowableObjectArray, type_arguments_);
  }

  static intptr_t length_offset() {
    return OFFSET_OF(RawGrowableObjectArray, length_);
  }
  static intptr_t data_offset() {
    return OFFSET_OF(RawGrowableObjectArray, data_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawGrowableObjectArray));
  }

  static RawGrowableObjectArray* New(Heap::Space space = Heap::kNew) {
    return New(kDefaultInitialCapacity, space);
  }
  static RawGrowableObjectArray* New(intptr_t capacity,
                                     Heap::Space space = Heap::kNew);
  static RawGrowableObjectArray* New(const Array& array,
                                     Heap::Space space = Heap::kNew);

 private:
  RawArray* DataArray() const { return data()->ptr(); }
  RawObject** ObjectAddr(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return &(DataArray()->data()[index]);
  }

  static const int kDefaultInitialCapacity = 0;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(GrowableObjectArray, Instance);
  friend class Array;
  friend class Class;
};

class Float32x4 : public Instance {
 public:
  static RawFloat32x4* New(float value0,
                           float value1,
                           float value2,
                           float value3,
                           Heap::Space space = Heap::kNew);
  static RawFloat32x4* New(simd128_value_t value,
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
    return RoundedAllocationSize(sizeof(RawFloat32x4));
  }

  static intptr_t value_offset() { return OFFSET_OF(RawFloat32x4, value_); }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Float32x4, Instance);
  friend class Class;
};

class Int32x4 : public Instance {
 public:
  static RawInt32x4* New(int32_t value0,
                         int32_t value1,
                         int32_t value2,
                         int32_t value3,
                         Heap::Space space = Heap::kNew);
  static RawInt32x4* New(simd128_value_t value, Heap::Space space = Heap::kNew);

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
    return RoundedAllocationSize(sizeof(RawInt32x4));
  }

  static intptr_t value_offset() { return OFFSET_OF(RawInt32x4, value_); }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Int32x4, Instance);
  friend class Class;
};

class Float64x2 : public Instance {
 public:
  static RawFloat64x2* New(double value0,
                           double value1,
                           Heap::Space space = Heap::kNew);
  static RawFloat64x2* New(simd128_value_t value,
                           Heap::Space space = Heap::kNew);

  double x() const;
  double y() const;

  void set_x(double x) const;
  void set_y(double y) const;

  simd128_value_t value() const;
  void set_value(simd128_value_t value) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawFloat64x2));
  }

  static intptr_t value_offset() { return OFFSET_OF(RawFloat64x2, value_); }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Float64x2, Instance);
  friend class Class;
};

class TypedData : public Instance {
 public:
  // We use 30 bits for the hash code so hashes in a snapshot taken on a
  // 64-bit architecture stay in Smi range when loaded on a 32-bit
  // architecture.
  static const intptr_t kHashBits = 30;

  intptr_t Length() const {
    ASSERT(!IsNull());
    return Smi::Value(raw_ptr()->length_);
  }

  intptr_t ElementSizeInBytes() const {
    intptr_t cid = raw()->GetClassId();
    return ElementSizeInBytes(cid);
  }

  TypedDataElementType ElementType() const {
    intptr_t cid = raw()->GetClassId();
    return ElementType(cid);
  }

  intptr_t LengthInBytes() const {
    intptr_t cid = raw()->GetClassId();
    return (ElementSizeInBytes(cid) * Length());
  }

  void* DataAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset == 0) ||
           ((byte_offset > 0) && (byte_offset < LengthInBytes())));
    return reinterpret_cast<void*>(UnsafeMutableNonPointer(raw_ptr()->data()) +
                                   byte_offset);
  }

  virtual bool CanonicalizeEquals(const Instance& other) const;
  virtual uword ComputeCanonicalTableHash() const;

#define TYPED_GETTER_SETTER(name, type)                                        \
  type Get##name(intptr_t byte_offset) const {                                 \
    NoSafepointScope no_safepoint;                                             \
    return ReadUnaligned(reinterpret_cast<type*>(DataAddr(byte_offset)));      \
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

  static intptr_t length_offset() { return OFFSET_OF(RawTypedData, length_); }

  static intptr_t data_offset() {
    return OFFSET_OF_RETURNED_VALUE(RawTypedData, data);
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawTypedData) ==
           OFFSET_OF_RETURNED_VALUE(RawTypedData, data));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t lengthInBytes) {
    ASSERT(0 <= lengthInBytes && lengthInBytes <= kSmiMax);
    return RoundedAllocationSize(sizeof(RawTypedData) + lengthInBytes);
  }

  static intptr_t ElementSizeInBytes(intptr_t class_id) {
    ASSERT(RawObject::IsTypedDataClassId(class_id));
    return element_size(ElementType(class_id));
  }

  static TypedDataElementType ElementType(intptr_t class_id) {
    ASSERT(RawObject::IsTypedDataClassId(class_id));
    return static_cast<TypedDataElementType>(class_id - kTypedDataInt8ArrayCid);
  }

  static intptr_t MaxElements(intptr_t class_id) {
    ASSERT(RawObject::IsTypedDataClassId(class_id));
    return (kSmiMax / ElementSizeInBytes(class_id));
  }

  static RawTypedData* New(intptr_t class_id,
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
    return RawObject::IsTypedDataClassId(cid);
  }

  static RawTypedData* EmptyUint32Array(Thread* thread);

 protected:
  void SetLength(intptr_t value) const {
    StoreSmi(&raw_ptr()->length_, Smi::New(value));
  }

 private:
  static intptr_t element_size(intptr_t index) {
    ASSERT(0 <= index && index < kNumElementSizes);
    intptr_t size = element_size_table[index];
    ASSERT(size != 0);
    return size;
  }
  static const intptr_t kNumElementSizes =
      kTypedDataFloat64x2ArrayCid - kTypedDataInt8ArrayCid + 1;
  static const intptr_t element_size_table[kNumElementSizes];

  FINAL_HEAP_OBJECT_IMPLEMENTATION(TypedData, Instance);
  friend class Class;
  friend class ExternalTypedData;
  friend class TypedDataView;
};

class ExternalTypedData : public Instance {
 public:
  intptr_t Length() const {
    ASSERT(!IsNull());
    return Smi::Value(raw_ptr()->length_);
  }

  intptr_t ElementSizeInBytes() const {
    intptr_t cid = raw()->GetClassId();
    return ElementSizeInBytes(cid);
  }

  TypedDataElementType ElementType() const {
    intptr_t cid = raw()->GetClassId();
    return ElementType(cid);
  }

  intptr_t LengthInBytes() const {
    intptr_t cid = raw()->GetClassId();
    return (ElementSizeInBytes(cid) * Length());
  }

  void* DataAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset == 0) ||
           ((byte_offset > 0) && (byte_offset < LengthInBytes())));
    return reinterpret_cast<void*>(raw_ptr()->data_ + byte_offset);
  }

#define TYPED_GETTER_SETTER(name, type)                                        \
  type Get##name(intptr_t byte_offset) const {                                 \
    return *reinterpret_cast<type*>(DataAddr(byte_offset));                    \
  }                                                                            \
  void Set##name(intptr_t byte_offset, type value) const {                     \
    *reinterpret_cast<type*>(DataAddr(byte_offset)) = value;                   \
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

  FinalizablePersistentHandle* AddFinalizer(
      void* peer,
      Dart_WeakPersistentHandleFinalizer callback,
      intptr_t external_size) const;

  static intptr_t length_offset() {
    return OFFSET_OF(RawExternalTypedData, length_);
  }

  static intptr_t data_offset() {
    return OFFSET_OF(RawExternalTypedData, data_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalTypedData));
  }

  static intptr_t ElementSizeInBytes(intptr_t class_id) {
    ASSERT(RawObject::IsExternalTypedDataClassId(class_id));
    return TypedData::element_size(ElementType(class_id));
  }

  static TypedDataElementType ElementType(intptr_t class_id) {
    ASSERT(RawObject::IsExternalTypedDataClassId(class_id));
    return static_cast<TypedDataElementType>(class_id -
                                             kExternalTypedDataInt8ArrayCid);
  }

  static intptr_t MaxElements(intptr_t class_id) {
    ASSERT(RawObject::IsExternalTypedDataClassId(class_id));
    return (kSmiMax / ElementSizeInBytes(class_id));
  }

  static RawExternalTypedData* New(intptr_t class_id,
                                   uint8_t* data,
                                   intptr_t len,
                                   Heap::Space space = Heap::kNew);

  static bool IsExternalTypedData(const Instance& obj) {
    ASSERT(!obj.IsNull());
    intptr_t cid = obj.raw()->GetClassId();
    return RawObject::IsExternalTypedDataClassId(cid);
  }

 protected:
  void SetLength(intptr_t value) const {
    StoreSmi(&raw_ptr()->length_, Smi::New(value));
  }

  void SetData(uint8_t* data) const {
    ASSERT(
        !Isolate::Current()->heap()->Contains(reinterpret_cast<uword>(data)));
    StoreNonPointer(&raw_ptr()->data_, data);
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(ExternalTypedData, Instance);
  friend class Class;
};

class TypedDataView : public AllStatic {
 public:
  static intptr_t ElementSizeInBytes(const Instance& view_obj) {
    ASSERT(!view_obj.IsNull());
    intptr_t cid = view_obj.raw()->GetClassId();
    return ElementSizeInBytes(cid);
  }

  static RawInstance* Data(const Instance& view_obj) {
    ASSERT(!view_obj.IsNull());
    return *reinterpret_cast<RawInstance* const*>(view_obj.raw_ptr() +
                                                  kDataOffset);
  }

  static RawSmi* OffsetInBytes(const Instance& view_obj) {
    ASSERT(!view_obj.IsNull());
    return *reinterpret_cast<RawSmi* const*>(view_obj.raw_ptr() +
                                             kOffsetInBytesOffset);
  }

  static RawSmi* Length(const Instance& view_obj) {
    ASSERT(!view_obj.IsNull());
    return *reinterpret_cast<RawSmi* const*>(view_obj.raw_ptr() +
                                             kLengthOffset);
  }

  static bool IsExternalTypedDataView(const Instance& view_obj) {
    const Instance& data = Instance::Handle(Data(view_obj));
    intptr_t cid = data.raw()->GetClassId();
    ASSERT(RawObject::IsTypedDataClassId(cid) ||
           RawObject::IsExternalTypedDataClassId(cid));
    return RawObject::IsExternalTypedDataClassId(cid);
  }

  static intptr_t NumberOfFields() { return kLengthOffset; }

  static intptr_t data_offset() { return kWordSize * kDataOffset; }

  static intptr_t offset_in_bytes_offset() {
    return kWordSize * kOffsetInBytesOffset;
  }

  static intptr_t length_offset() { return kWordSize * kLengthOffset; }

  static intptr_t ElementSizeInBytes(intptr_t class_id) {
    ASSERT(RawObject::IsTypedDataViewClassId(class_id));
    return (class_id == kByteDataViewCid)
               ? 1
               : TypedData::element_size(class_id - kTypedDataInt8ArrayViewCid);
  }

 private:
  enum {
    kDataOffset = 1,
    kOffsetInBytesOffset = 2,
    kLengthOffset = 3,
  };
};

class ByteBuffer : public AllStatic {
 public:
  static RawInstance* Data(const Instance& view_obj) {
    ASSERT(!view_obj.IsNull());
    return *reinterpret_cast<RawInstance* const*>(view_obj.raw_ptr() +
                                                  kDataOffset);
  }

  static intptr_t NumberOfFields() { return kDataOffset; }

  static intptr_t data_offset() { return kWordSize * kDataOffset; }

 private:
  enum {
    kDataOffset = 1,
  };
};

// Corresponds to
// - "new Map()",
// - non-const map literals, and
// - the default constructor of LinkedHashMap in dart:collection.
class LinkedHashMap : public Instance {
 public:
  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawLinkedHashMap));
  }

  // Allocates a map with some default capacity, just like "new Map()".
  static RawLinkedHashMap* NewDefault(Heap::Space space = Heap::kNew);
  static RawLinkedHashMap* New(const Array& data,
                               const TypedData& index,
                               intptr_t hash_mask,
                               intptr_t used_data,
                               intptr_t deleted_keys,
                               Heap::Space space = Heap::kNew);

  virtual RawTypeArguments* GetTypeArguments() const {
    return raw_ptr()->type_arguments_;
  }
  virtual void SetTypeArguments(const TypeArguments& value) const {
    ASSERT(value.IsNull() ||
           ((value.Length() >= 2) &&
            value.IsInstantiated() /*&& value.IsCanonical()*/));
    // TODO(asiva): Values read from a message snapshot are not properly marked
    // as canonical. See for example tests/isolate/message3_test.dart.
    StorePointer(&raw_ptr()->type_arguments_, value.raw());
  }
  static intptr_t type_arguments_offset() {
    return OFFSET_OF(RawLinkedHashMap, type_arguments_);
  }

  RawTypedData* index() const { return raw_ptr()->index_; }
  void SetIndex(const TypedData& value) const {
    StorePointer(&raw_ptr()->index_, value.raw());
  }
  static intptr_t index_offset() { return OFFSET_OF(RawLinkedHashMap, index_); }

  RawArray* data() const { return raw_ptr()->data_; }
  void SetData(const Array& value) const {
    StorePointer(&raw_ptr()->data_, value.raw());
  }
  static intptr_t data_offset() { return OFFSET_OF(RawLinkedHashMap, data_); }

  RawSmi* hash_mask() const { return raw_ptr()->hash_mask_; }
  void SetHashMask(intptr_t value) const {
    StoreSmi(&raw_ptr()->hash_mask_, Smi::New(value));
  }
  static intptr_t hash_mask_offset() {
    return OFFSET_OF(RawLinkedHashMap, hash_mask_);
  }

  RawSmi* used_data() const { return raw_ptr()->used_data_; }
  void SetUsedData(intptr_t value) const {
    StoreSmi(&raw_ptr()->used_data_, Smi::New(value));
  }
  static intptr_t used_data_offset() {
    return OFFSET_OF(RawLinkedHashMap, used_data_);
  }

  RawSmi* deleted_keys() const { return raw_ptr()->deleted_keys_; }
  void SetDeletedKeys(intptr_t value) const {
    StoreSmi(&raw_ptr()->deleted_keys_, Smi::New(value));
  }
  static intptr_t deleted_keys_offset() {
    return OFFSET_OF(RawLinkedHashMap, deleted_keys_);
  }

  intptr_t Length() const {
    // The map may be uninitialized.
    if (raw_ptr()->used_data_ == Object::null()) return 0;
    if (raw_ptr()->deleted_keys_ == Object::null()) return 0;

    intptr_t used = Smi::Value(raw_ptr()->used_data_);
    intptr_t deleted = Smi::Value(raw_ptr()->deleted_keys_);
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

    RawObject* CurrentKey() const { return data_.At(offset_); }

    RawObject* CurrentValue() const { return data_.At(offset_ + 1); }

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
  static RawLinkedHashMap* NewUninitialized(Heap::Space space = Heap::kNew);

  friend class Class;
  friend class LinkedHashMapDeserializationCluster;
};

class Closure : public Instance {
 public:
  RawTypeArguments* instantiator_type_arguments() const {
    return raw_ptr()->instantiator_type_arguments_;
  }
  static intptr_t instantiator_type_arguments_offset() {
    return OFFSET_OF(RawClosure, instantiator_type_arguments_);
  }

  RawTypeArguments* function_type_arguments() const {
    return raw_ptr()->function_type_arguments_;
  }
  static intptr_t function_type_arguments_offset() {
    return OFFSET_OF(RawClosure, function_type_arguments_);
  }

  RawFunction* function() const { return raw_ptr()->function_; }
  static intptr_t function_offset() { return OFFSET_OF(RawClosure, function_); }

  RawContext* context() const { return raw_ptr()->context_; }
  static intptr_t context_offset() { return OFFSET_OF(RawClosure, context_); }

  RawSmi* hash() const { return raw_ptr()->hash_; }
  static intptr_t hash_offset() { return OFFSET_OF(RawClosure, hash_); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawClosure));
  }

  // Returns true if all elements are OK for canonicalization.
  virtual bool CheckAndCanonicalizeFields(Thread* thread,
                                          const char** error_str) const {
    // None of the fields of a closure are instances.
    return true;
  }

  int64_t ComputeHash() const;

  static RawClosure* New(const TypeArguments& instantiator_type_arguments,
                         const TypeArguments& function_type_arguments,
                         const Function& function,
                         const Context& context,
                         Heap::Space space = Heap::kNew);

 private:
  static RawClosure* New();

  FINAL_HEAP_OBJECT_IMPLEMENTATION(Closure, Instance);
  friend class Class;
};

class Capability : public Instance {
 public:
  uint64_t Id() const { return raw_ptr()->id_; }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawCapability));
  }
  static RawCapability* New(uint64_t id, Heap::Space space = Heap::kNew);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(Capability, Instance);
  friend class Class;
};

class ReceivePort : public Instance {
 public:
  RawSendPort* send_port() const { return raw_ptr()->send_port_; }
  Dart_Port Id() const { return send_port()->ptr()->id_; }

  RawInstance* handler() const { return raw_ptr()->handler_; }
  void set_handler(const Instance& value) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawReceivePort));
  }
  static RawReceivePort* New(Dart_Port id,
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
    return RoundedAllocationSize(sizeof(RawSendPort));
  }
  static RawSendPort* New(Dart_Port id, Heap::Space space = Heap::kNew);
  static RawSendPort* New(Dart_Port id,
                          Dart_Port origin_id,
                          Heap::Space space = Heap::kNew);

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(SendPort, Instance);
  friend class Class;
};

// Internal stacktrace object used in exceptions for printing stack traces.
class StackTrace : public Instance {
 public:
  static const int kPreallocatedStackdepth = 30;

  intptr_t Length() const;

  RawStackTrace* async_link() const { return raw_ptr()->async_link_; }
  void set_async_link(const StackTrace& async_link) const;
  void set_expand_inlined(bool value) const;

  RawArray* code_array() const { return raw_ptr()->code_array_; }
  RawCode* CodeAtFrame(intptr_t frame_index) const;
  void SetCodeAtFrame(intptr_t frame_index, const Code& code) const;

  RawArray* pc_offset_array() const { return raw_ptr()->pc_offset_array_; }
  RawSmi* PcOffsetAtFrame(intptr_t frame_index) const;
  void SetPcOffsetAtFrame(intptr_t frame_index, const Smi& pc_offset) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawStackTrace));
  }
  static RawStackTrace* New(const Array& code_array,
                            const Array& pc_offset_array,
                            Heap::Space space = Heap::kNew);

  static RawStackTrace* New(const Array& code_array,
                            const Array& pc_offset_array,
                            const StackTrace& async_link,
                            Heap::Space space = Heap::kNew);

 private:
  static const char* ToDartCString(const StackTrace& stack_trace_in);
  static const char* ToDwarfCString(const StackTrace& stack_trace_in);

  void set_code_array(const Array& code_array) const;
  void set_pc_offset_array(const Array& pc_offset_array) const;
  bool expand_inlined() const;

  FINAL_HEAP_OBJECT_IMPLEMENTATION(StackTrace, Instance);
  friend class Class;
  friend class Debugger;
};

// Internal JavaScript regular expression object.
class RegExp : public Instance {
 public:
  // Meaning of RegExType:
  // kUninitialized: the type of th regexp has not been initialized yet.
  // kSimple: A simple pattern to match against, using string indexOf operation.
  // kComplex: A complex pattern to match.
  enum RegExType {
    kUnitialized = 0,
    kSimple = 1,
    kComplex = 2,
  };

  // Flags are passed to a regex object as follows:
  // 'i': ignore case, 'g': do global matches, 'm': pattern is multi line.
  enum Flags {
    kNone = 0,
    kGlobal = 1,
    kIgnoreCase = 2,
    kMultiLine = 4,
  };

  enum {
    kTypePos = 0,
    kTypeSize = 2,
    kFlagsPos = 2,
    kFlagsSize = 4,
  };

  class TypeBits : public BitField<int8_t, RegExType, kTypePos, kTypeSize> {};
  class FlagsBits : public BitField<int8_t, intptr_t, kFlagsPos, kFlagsSize> {};

  bool is_initialized() const { return (type() != kUnitialized); }
  bool is_simple() const { return (type() == kSimple); }
  bool is_complex() const { return (type() == kComplex); }

  bool is_global() const { return (flags() & kGlobal); }
  bool is_ignore_case() const { return (flags() & kIgnoreCase); }
  bool is_multi_line() const { return (flags() & kMultiLine); }

  intptr_t num_registers() const { return raw_ptr()->num_registers_; }

  RawString* pattern() const { return raw_ptr()->pattern_; }
  RawSmi* num_bracket_expressions() const {
    return raw_ptr()->num_bracket_expressions_;
  }

  RawTypedData* bytecode(bool is_one_byte, bool sticky) const {
    if (sticky) {
      return is_one_byte ? raw_ptr()->one_byte_sticky_.bytecode_
                         : raw_ptr()->two_byte_sticky_.bytecode_;
    } else {
      return is_one_byte ? raw_ptr()->one_byte_.bytecode_
                         : raw_ptr()->two_byte_.bytecode_;
    }
  }

  static intptr_t function_offset(intptr_t cid, bool sticky) {
    if (sticky) {
      switch (cid) {
        case kOneByteStringCid:
          return OFFSET_OF(RawRegExp, one_byte_sticky_.function_);
        case kTwoByteStringCid:
          return OFFSET_OF(RawRegExp, two_byte_sticky_.function_);
        case kExternalOneByteStringCid:
          return OFFSET_OF(RawRegExp, external_one_byte_sticky_function_);
        case kExternalTwoByteStringCid:
          return OFFSET_OF(RawRegExp, external_two_byte_sticky_function_);
      }
    } else {
      switch (cid) {
        case kOneByteStringCid:
          return OFFSET_OF(RawRegExp, one_byte_.function_);
        case kTwoByteStringCid:
          return OFFSET_OF(RawRegExp, two_byte_.function_);
        case kExternalOneByteStringCid:
          return OFFSET_OF(RawRegExp, external_one_byte_function_);
        case kExternalTwoByteStringCid:
          return OFFSET_OF(RawRegExp, external_two_byte_function_);
      }
    }

    UNREACHABLE();
    return -1;
  }

  RawFunction** FunctionAddr(intptr_t cid, bool sticky) const {
    return reinterpret_cast<RawFunction**>(
        FieldAddrAtOffset(function_offset(cid, sticky)));
  }

  RawFunction* function(intptr_t cid, bool sticky) const {
    return *FunctionAddr(cid, sticky);
  }

  void set_pattern(const String& pattern) const;
  void set_function(intptr_t cid, bool sticky, const Function& value) const;
  void set_bytecode(bool is_one_byte,
                    bool sticky,
                    const TypedData& bytecode) const;

  void set_num_bracket_expressions(intptr_t value) const;
  void set_is_global() const { set_flags(flags() | kGlobal); }
  void set_is_ignore_case() const { set_flags(flags() | kIgnoreCase); }
  void set_is_multi_line() const { set_flags(flags() | kMultiLine); }
  void set_is_simple() const { set_type(kSimple); }
  void set_is_complex() const { set_type(kComplex); }
  void set_num_registers(intptr_t value) const {
    StoreNonPointer(&raw_ptr()->num_registers_, value);
  }

  void* GetDataStartAddress() const;
  static RawRegExp* FromDataStartAddress(void* data);
  const char* Flags() const;

  virtual bool CanonicalizeEquals(const Instance& other) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawRegExp));
  }

  static RawRegExp* New(Heap::Space space = Heap::kNew);

 private:
  void set_type(RegExType type) const {
    StoreNonPointer(&raw_ptr()->type_flags_,
                    TypeBits::update(type, raw_ptr()->type_flags_));
  }
  void set_flags(intptr_t value) const {
    StoreNonPointer(&raw_ptr()->type_flags_,
                    FlagsBits::update(value, raw_ptr()->type_flags_));
  }

  RegExType type() const { return TypeBits::decode(raw_ptr()->type_flags_); }
  intptr_t flags() const { return FlagsBits::decode(raw_ptr()->type_flags_); }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(RegExp, Instance);
  friend class Class;
};

class WeakProperty : public Instance {
 public:
  RawObject* key() const { return raw_ptr()->key_; }

  void set_key(const Object& key) const {
    StorePointer(&raw_ptr()->key_, key.raw());
  }

  RawObject* value() const { return raw_ptr()->value_; }

  void set_value(const Object& value) const {
    StorePointer(&raw_ptr()->value_, value.raw());
  }

  static RawWeakProperty* New(Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawWeakProperty));
  }

  static void Clear(RawWeakProperty* raw_weak) {
    ASSERT(raw_weak->ptr()->next_ == 0);
    raw_weak->StorePointer(&(raw_weak->ptr()->key_), Object::null());
    raw_weak->StorePointer(&(raw_weak->ptr()->value_), Object::null());
  }

 private:
  FINAL_HEAP_OBJECT_IMPLEMENTATION(WeakProperty, Instance);
  friend class Class;
};

class MirrorReference : public Instance {
 public:
  RawObject* referent() const { return raw_ptr()->referent_; }

  void set_referent(const Object& referent) const {
    StorePointer(&raw_ptr()->referent_, referent.raw());
  }

  RawAbstractType* GetAbstractTypeReferent() const;

  RawClass* GetClassReferent() const;

  RawField* GetFieldReferent() const;

  RawFunction* GetFunctionReferent() const;

  RawLibrary* GetLibraryReferent() const;

  RawTypeParameter* GetTypeParameterReferent() const;

  static RawMirrorReference* New(const Object& referent,
                                 Heap::Space space = Heap::kNew);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawMirrorReference));
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
  static intptr_t tag_offset() { return OFFSET_OF(RawUserTag, tag_); }

  RawString* label() const { return raw_ptr()->label_; }

  void MakeActive() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawUserTag));
  }

  static RawUserTag* New(const String& label, Heap::Space space = Heap::kOld);
  static RawUserTag* DefaultTag();

  static bool TagTableIsFull(Thread* thread);
  static RawUserTag* FindTagById(uword tag_id);

 private:
  static RawUserTag* FindTagInIsolate(Thread* thread, const String& label);
  static void AddTagToIsolate(Thread* thread, const UserTag& tag);

  void set_label(const String& tag_label) const {
    StorePointer(&raw_ptr()->label_, tag_label.raw());
  }

  FINAL_HEAP_OBJECT_IMPLEMENTATION(UserTag, Instance);
  friend class Class;
};

class ObjectPoolInfo : public ValueObject {
 public:
  explicit ObjectPoolInfo(const ObjectPool& pool)
      : array_(TypedData::Handle(pool.info_array())) {}

  explicit ObjectPoolInfo(const TypedData& info_array) : array_(info_array) {}

  ObjectPool::EntryType InfoAt(intptr_t i) {
    return static_cast<ObjectPool::EntryType>(array_.GetInt8(i));
  }

  void SetInfoAt(intptr_t i, ObjectPool::EntryType info) {
    array_.SetInt8(i, static_cast<int8_t>(info));
  }

 private:
  const TypedData& array_;
};

// Breaking cycles and loops.
RawClass* Object::clazz() const {
  uword raw_value = reinterpret_cast<uword>(raw_);
  if ((raw_value & kSmiTagMask) == kSmiTag) {
    return Smi::Class();
  }
  return Isolate::Current()->class_table()->At(raw()->GetClassId());
}

DART_FORCE_INLINE void Object::SetRaw(RawObject* value) {
  NoSafepointScope no_safepoint_scope;
  raw_ = value;
  if ((reinterpret_cast<uword>(value) & kSmiTagMask) == kSmiTag) {
    set_vtable(Smi::handle_vtable_);
    return;
  }
  intptr_t cid = value->GetClassId();
  // Free-list elements cannot be wrapped in a handle.
  ASSERT(cid != kFreeListElement);
  ASSERT(cid != kForwardingCorpse);
  if (cid >= kNumPredefinedCids) {
    cid = kInstanceCid;
  }
  set_vtable(builtin_vtables_[cid]);
#if defined(DEBUG)
  if (FLAG_verify_handles) {
    Isolate* isolate = Isolate::Current();
    Heap* isolate_heap = isolate->heap();
    Heap* vm_isolate_heap = Dart::vm_isolate()->heap();
    ASSERT(isolate_heap->Contains(RawObject::ToAddr(raw_)) ||
           vm_isolate_heap->Contains(RawObject::ToAddr(raw_)));
  }
#endif
}

intptr_t Field::Offset() const {
  ASSERT(is_instance());  // Valid only for dart instance fields.
  intptr_t value = Smi::Value(raw_ptr()->value_.offset_);
  return (value * kWordSize);
}

void Field::SetOffset(intptr_t offset_in_bytes) const {
  ASSERT(is_instance());  // Valid only for dart instance fields.
  ASSERT(kWordSize != 0);
  StorePointer(&raw_ptr()->value_.offset_,
               Smi::New(offset_in_bytes / kWordSize));
}

RawInstance* Field::StaticValue() const {
  ASSERT(is_static());  // Valid only for static dart fields.
  return raw_ptr()->value_.static_value_;
}

void Field::SetStaticValue(const Instance& value,
                           bool save_initial_value) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(is_static());  // Valid only for static dart fields.
  StorePointer(&raw_ptr()->value_.static_value_, value.raw());
  if (save_initial_value) {
    ASSERT(!HasPrecompiledInitializer());
    StorePointer(&raw_ptr()->initializer_.saved_value_, value.raw());
  }
}

void Context::SetAt(intptr_t index, const Object& value) const {
  StorePointer(ObjectAddr(index), value.raw());
}

intptr_t Instance::GetNativeField(int index) const {
  ASSERT(IsValidNativeIndex(index));
  NoSafepointScope no_safepoint;
  RawTypedData* native_fields =
      reinterpret_cast<RawTypedData*>(*NativeFieldsAddr());
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
  RawTypedData* native_fields =
      reinterpret_cast<RawTypedData*>(*NativeFieldsAddr());
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
                                const Function& target) {
  array.SetAt((index * kEntryLength) + kClassIdIndex, class_id);
  array.SetAt((index * kEntryLength) + kTargetFunctionIndex, target);
}

RawObject* MegamorphicCache::GetClassId(const Array& array, intptr_t index) {
  return array.At((index * kEntryLength) + kClassIdIndex);
}

RawObject* MegamorphicCache::GetTargetFunction(const Array& array,
                                               intptr_t index) {
  return array.At((index * kEntryLength) + kTargetFunctionIndex);
}

inline intptr_t Type::Hash() const {
  intptr_t result = Smi::Value(raw_ptr()->hash_);
  if (result != 0) {
    return result;
  }
  return ComputeHash();
}

inline void Type::SetHash(intptr_t value) const {
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  StoreSmi(&raw_ptr()->hash_, Smi::New(value));
}

inline intptr_t TypeParameter::Hash() const {
  ASSERT(IsFinalized());
  intptr_t result = Smi::Value(raw_ptr()->hash_);
  if (result != 0) {
    return result;
  }
  return ComputeHash();
}

inline void TypeParameter::SetHash(intptr_t value) const {
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  StoreSmi(&raw_ptr()->hash_, Smi::New(value));
}

inline intptr_t BoundedType::Hash() const {
  intptr_t result = Smi::Value(raw_ptr()->hash_);
  if (result != 0) {
    return result;
  }
  return ComputeHash();
}

inline void BoundedType::SetHash(intptr_t value) const {
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  StoreSmi(&raw_ptr()->hash_, Smi::New(value));
}

inline intptr_t TypeArguments::Hash() const {
  if (IsNull()) return 0;
  intptr_t result = Smi::Value(raw_ptr()->hash_);
  if (result != 0) {
    return result;
  }
  return ComputeHash();
}

inline void TypeArguments::SetHash(intptr_t value) const {
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  StoreSmi(&raw_ptr()->hash_, Smi::New(value));
}

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_H_
