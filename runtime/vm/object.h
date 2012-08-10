// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_OBJECT_H_
#define VM_OBJECT_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/bitmap.h"
#include "vm/dart.h"
#include "vm/globals.h"
#include "vm/handles.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/os.h"
#include "vm/raw_object.h"
#include "vm/scanner.h"

namespace dart {

// Forward declarations.
#define DEFINE_FORWARD_DECLARATION(clazz)                                      \
  class clazz;
CLASS_LIST(DEFINE_FORWARD_DECLARATION)
#undef DEFINE_FORWARD_DECLARATION
class Api;
class Assembler;
class Code;
class LocalScope;
class Symbols;

#define OBJECT_IMPLEMENTATION(object, super)                                   \
 public:  /* NOLINT */                                                         \
  Raw##object* raw() const { return reinterpret_cast<Raw##object*>(raw_); }    \
  void operator=(Raw##object* value) {                                         \
    initializeHandle(this, value);                                             \
  }                                                                            \
  bool Is##object() const { return true; }                                     \
  void operator^=(RawObject* value) {                                          \
    initializeHandle(this, value);                                             \
    ASSERT(IsNull() || Is##object());                                          \
  }                                                                            \
  static object& Handle(Isolate* isolate, Raw##object* raw_ptr) {              \
    object* obj =                                                              \
        reinterpret_cast<object*>(VMHandles::AllocateHandle(isolate));         \
    initializeHandle(obj, raw_ptr);                                            \
    return *obj;                                                               \
  }                                                                            \
  static object& Handle() {                                                    \
    return Handle(Isolate::Current(), object::null());                         \
  }                                                                            \
  static object& Handle(Isolate* isolate) {                                    \
    return Handle(isolate, object::null());                                    \
  }                                                                            \
  static object& Handle(Raw##object* raw_ptr) {                                \
    return Handle(Isolate::Current(), raw_ptr);                                \
  }                                                                            \
  static object& CheckedHandle(Isolate* isolate, RawObject* raw_ptr) {         \
    object* obj =                                                              \
        reinterpret_cast<object*>(VMHandles::AllocateHandle(isolate));         \
    initializeHandle(obj, raw_ptr);                                            \
    if (!obj->Is##object()) {                                                  \
      FATAL2("Handle check failed: saw %s expected %s",                        \
             obj->ToCString(), #object);                                       \
    }                                                                          \
    return *obj;                                                               \
  }                                                                            \
  static object& CheckedHandle(RawObject* raw_ptr) {                           \
    return CheckedHandle(Isolate::Current(), raw_ptr);                         \
  }                                                                            \
  static object& ZoneHandle(Isolate* isolate, Raw##object* raw_ptr) {          \
    object* obj = reinterpret_cast<object*>(                                   \
        VMHandles::AllocateZoneHandle(isolate));                               \
    initializeHandle(obj, raw_ptr);                                            \
    return *obj;                                                               \
  }                                                                            \
  static object& ZoneHandle() {                                                \
    return ZoneHandle(Isolate::Current(), object::null());                     \
  }                                                                            \
  static object& ZoneHandle(Raw##object* raw_ptr) {                            \
    return ZoneHandle(Isolate::Current(), raw_ptr);                            \
  }                                                                            \
  static object& CheckedZoneHandle(Isolate* isolate, RawObject* raw_ptr) {     \
    object* obj = reinterpret_cast<object*>(                                   \
        VMHandles::AllocateZoneHandle(isolate));                               \
    initializeHandle(obj, raw_ptr);                                            \
    if (!obj->Is##object()) {                                                  \
      FATAL2("Handle check failed: saw %s expected %s",                        \
             obj->ToCString(), #object);                                       \
    }                                                                          \
    return *obj;                                                               \
  }                                                                            \
  static object& CheckedZoneHandle(RawObject* raw_ptr) {                       \
    return CheckedZoneHandle(Isolate::Current(), raw_ptr);                     \
  }                                                                            \
  /* T::Cast cannot be applied to a null Object, because the object vtable */  \
  /* is not setup for type T, although some methods are supposed to work   */  \
  /* with null, for example Instance::Equals().                            */  \
  static const object& Cast(const Object& obj) {                               \
    ASSERT(obj.Is##object());                                                  \
    return reinterpret_cast<const object&>(obj);                               \
  }                                                                            \
  static Raw##object* null() {                                                 \
    return reinterpret_cast<Raw##object*>(Object::null());                     \
  }                                                                            \
  virtual const char* ToCString() const;                                       \
  static const ClassId kClassId = k##object##Cid;                              \
 protected:  /* NOLINT */                                                      \
  object() : super() {}                                                        \
 private:  /* NOLINT */                                                        \
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
  void* operator new(size_t size);                                             \
  object(const object& value);                                                 \
  void operator=(Raw##super* value);                                           \
  void operator=(const object& value);                                         \
  void operator=(const super& value);                                          \

#define SNAPSHOT_READER_SUPPORT(object)                                        \
  static Raw##object* ReadFrom(SnapshotReader* reader,                         \
                               intptr_t object_id,                             \
                               intptr_t tags,                                  \
                               Snapshot::Kind);                                \
  friend class SnapshotReader;                                                 \

#define HEAP_OBJECT_IMPLEMENTATION(object, super)                              \
  OBJECT_IMPLEMENTATION(object, super);                                        \
  Raw##object* raw_ptr() const {                                               \
    ASSERT(raw() != null());                                                   \
    return raw()->ptr();                                                       \
  }                                                                            \
  SNAPSHOT_READER_SUPPORT(object)                                              \
  friend class StackFrame;                                                     \

class Object {
 public:
  virtual ~Object() { }

  RawObject* raw() const { return raw_; }
  void operator=(RawObject* value) { SetRaw(value); }

  void set_tags(intptr_t value) const {
    // TODO(asiva): Remove the capability of setting tags in general. The mask
    // here only allows for canonical and from_snapshot flags to be set.
    ASSERT(!IsNull());
    uword tags = raw()->ptr()->tags_ & ~0x0000000c;
    raw()->ptr()->tags_ = tags | (value & 0x0000000c);
  }
  void SetCreatedFromSnapshot() const {
    ASSERT(!IsNull());
    raw()->SetCreatedFromSnapshot();
  }
  bool IsCanonical() const {
    ASSERT(!IsNull());
    return raw()->IsCanonical();
  }
  void SetCanonical() const {
    ASSERT(!IsNull());
    raw()->SetCanonical();
  }

  inline RawClass* clazz() const;
  static intptr_t tags_offset() { return OFFSET_OF(RawObject, tags_); }

  // Class testers.
#define DEFINE_CLASS_TESTER(clazz)                                             \
  virtual bool Is##clazz() const { return false; }
CLASS_LIST_NO_OBJECT(DEFINE_CLASS_TESTER);
#undef DEFINE_CLASS_TESTER

  bool IsNull() const { return raw_ == null_; }

  virtual const char* ToCString() const {
    if (IsNull()) {
      return "null";
    } else {
      return "Object";
    }
  }

  bool IsNew() const { return raw()->IsNewObject(); }
  bool IsOld() const { return raw()->IsOldObject(); }

  // Print the object on stdout for debugging.
  void Print() const;

  bool IsZoneHandle() const {
    return VMHandles::IsZoneHandle(reinterpret_cast<uword>(this));
  }

  static RawObject* Clone(const Object& src, Heap::Space space = Heap::kNew);

  static Object& Handle(Isolate* isolate, RawObject* raw_ptr) {
    Object* obj = reinterpret_cast<Object*>(VMHandles::AllocateHandle(isolate));
    obj->SetRaw(raw_ptr);
    return *obj;
  }

  static Object& Handle() {
    return Handle(Isolate::Current(), null_);
  }

  static Object& Handle(Isolate* isolate) {
    return Handle(isolate, null_);
  }

  static Object& Handle(RawObject* raw_ptr) {
    return Handle(Isolate::Current(), raw_ptr);
  }

  static Object& ZoneHandle(Isolate* isolate, RawObject* raw_ptr) {
    Object* obj = reinterpret_cast<Object*>(
        VMHandles::AllocateZoneHandle(isolate));
    obj->SetRaw(raw_ptr);
    return *obj;
  }

  static Object& ZoneHandle() {
    return ZoneHandle(Isolate::Current(), null_);
  }

  static Object& ZoneHandle(RawObject* raw_ptr) {
    return ZoneHandle(Isolate::Current(), raw_ptr);
  }

  static RawObject* null() { return null_; }

  // The sentinel is a value that cannot be produced by Dart code.
  // It can be used to mark special values, for example to distinguish
  // "uninitialized" fields.
  static RawInstance* sentinel() { return sentinel_; }
  // Value marking that we are transitioning from sentinel, e.g., computing
  // a field value. Used to detect circular initialization.
  static RawInstance* transition_sentinel() { return transition_sentinel_; }

  static RawClass* class_class() { return class_class_; }
  static RawClass* null_class() { return null_class_; }
  static RawClass* dynamic_class() { return dynamic_class_; }
  static RawClass* void_class() { return void_class_; }
  static RawClass* unresolved_class_class() { return unresolved_class_class_; }
  static RawClass* type_class() {
      return type_class_;
  }
  static RawClass* type_parameter_class() { return type_parameter_class_; }
  static RawClass* type_arguments_class() { return type_arguments_class_; }
  static RawClass* instantiated_type_arguments_class() {
      return instantiated_type_arguments_class_;
  }
  static RawClass* function_class() { return function_class_; }
  static RawClass* field_class() { return field_class_; }
  static RawClass* literal_token_class() { return literal_token_class_; }
  static RawClass* token_stream_class() { return token_stream_class_; }
  static RawClass* script_class() { return script_class_; }
  static RawClass* library_class() { return library_class_; }
  static RawClass* library_prefix_class() { return library_prefix_class_; }
  static RawClass* code_class() { return code_class_; }
  static RawClass* instructions_class() { return instructions_class_; }
  static RawClass* pc_descriptors_class() { return pc_descriptors_class_; }
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
  static RawClass* icdata_class() { return icdata_class_; }
  static RawClass* subtypetestcache_class() { return subtypetestcache_class_; }

  static const char* GetSingletonClassName(intptr_t class_id);

  static RawClass* CreateAndRegisterInterface(const char* cname,
                                              const Script& script,
                                              const Library& lib);
  static void RegisterClass(const Class& cls,
                            const char* cname,
                            const Script& script,
                            const Library& lib);

  static void RegisterPrivateClass(const Class& cls,
                                   const char* cname,
                                   const Script& script,
                                   const Library& lib);

  static RawError* Init(Isolate* isolate);
  static void InitFromSnapshot(Isolate* isolate);
  static void InitOnce();

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawObject));
  }

  static const ClassId kClassId = kObjectCid;

  // Different kinds of type tests.
  enum TypeTestKind {
    kIsSubtypeOf = 0,
    kIsMoreSpecificThan
  };

  // Different kinds of name visibility.
  enum NameVisibility {
    kInternalName = 0,
    kUserVisibleName
  };

 protected:
  // Used for extracting the C++ vtable during bringup.
  Object() : raw_(null_) {}

  uword raw_value() const {
    return reinterpret_cast<uword>(raw());
  }

  inline void SetRaw(RawObject* value);

  cpp_vtable vtable() const { return bit_copy<cpp_vtable>(*this); }
  void set_vtable(cpp_vtable value) { *vtable_address() = value; }

  static RawObject* Allocate(intptr_t cls_id,
                             intptr_t size,
                             Heap::Space space);

  static intptr_t RoundedAllocationSize(intptr_t size) {
    return Utils::RoundUp(size, kObjectAlignment);
  }

  bool Contains(uword addr) const {
    intptr_t this_size = raw()->Size();
    uword this_addr = RawObject::ToAddr(raw());
    return (addr >= this_addr) && (addr < (this_addr + this_size));
  }

  template<typename type> void StorePointer(type* addr, type value) const {
    // Ensure that this object contains the addr.
    ASSERT(Contains(reinterpret_cast<uword>(addr)));
    *addr = value;
    // Filter stores based on source and target.
    if (!value->IsHeapObject()) return;
    if (value->IsNewObject() && raw()->IsOldObject()) {
      uword ptr = reinterpret_cast<uword>(addr);
      Isolate::Current()->store_buffer()->AddPointer(ptr);
    }
  }

  RawObject* raw_;  // The raw object reference.

 private:
  static void InitializeObject(uword address, intptr_t id, intptr_t size);

  cpp_vtable* vtable_address() const {
    uword vtable_addr = reinterpret_cast<uword>(this);
    return reinterpret_cast<cpp_vtable*>(vtable_addr);
  }

  static cpp_vtable handle_vtable_;
  static cpp_vtable builtin_vtables_[kNumPredefinedCids];

  // The static values below are singletons shared between the different
  // isolates. They are all allocated in the non-GC'd Dart::vm_isolate_.
  static RawObject* null_;
  static RawInstance* sentinel_;
  static RawInstance* transition_sentinel_;

  static RawClass* class_class_;  // Class of the Class vm object.
  static RawClass* null_class_;  // Class of the null object.
  static RawClass* dynamic_class_;  // Class of the 'Dynamic' type.
  static RawClass* void_class_;  // Class of the 'void' type.
  static RawClass* unresolved_class_class_;  // Class of UnresolvedClass.
  static RawClass* type_class_;  // Class of Type.
  static RawClass* type_parameter_class_;  // Class of TypeParameter vm object.
  // Class of the TypeArguments vm object.
  static RawClass* type_arguments_class_;
  static RawClass* instantiated_type_arguments_class_;  // Class of Inst..ments.
  static RawClass* function_class_;  // Class of the Function vm object.
  static RawClass* field_class_;  // Class of the Field vm object.
  static RawClass* literal_token_class_;  // Class of LiteralToken vm object.
  static RawClass* token_stream_class_;  // Class of the TokenStream vm object.
  static RawClass* script_class_;  // Class of the Script vm object.
  static RawClass* library_class_;  // Class of the Library vm object.
  static RawClass* library_prefix_class_;  // Class of Library prefix vm object.
  static RawClass* code_class_;  // Class of the Code vm object.
  static RawClass* instructions_class_;  // Class of the Instructions vm object.
  static RawClass* pc_descriptors_class_;  // Class of PcDescriptors vm object.
  static RawClass* stackmap_class_;  // Class of Stackmap vm object.
  static RawClass* var_descriptors_class_;  // Class of LocalVarDescriptors.
  static RawClass* exception_handlers_class_;  // Class of ExceptionHandlers.
  static RawClass* deopt_info_class_;  // Class of DeoptInfo.
  static RawClass* context_class_;  // Class of the Context vm object.
  static RawClass* context_scope_class_;  // Class of ContextScope vm object.
  static RawClass* icdata_class_;  // Class of ICData.
  static RawClass* subtypetestcache_class_;  // Class of SubtypeTestCache.
  static RawClass* api_error_class_;  // Class of ApiError.
  static RawClass* language_error_class_;  // Class of LanguageError.
  static RawClass* unhandled_exception_class_;  // Class of UnhandledException.
  static RawClass* unwind_error_class_;  // Class of UnwindError.

  friend void ClassTable::Register(const Class& cls);
  friend void RawObject::Validate(Isolate* isolate) const;
  friend class SnapshotReader;

  // Disallow allocation.
  void* operator new(size_t size);
  // Disallow copy constructor.
  DISALLOW_COPY_AND_ASSIGN(Object);
};


class Class : public Object {
 public:
  intptr_t instance_size() const {
    ASSERT(is_finalized() || is_prefinalized());
    return raw_ptr()->instance_size_;
  }
  void set_instance_size(intptr_t value) const {
    ASSERT(Utils::IsAligned(value, kObjectAlignment));
    raw_ptr()->instance_size_ = value;
  }
  static intptr_t instance_size_offset() {
    return OFFSET_OF(RawClass, instance_size_);
  }

  intptr_t next_field_offset() const {
    return raw_ptr()->next_field_offset_;
  }
  void set_next_field_offset(intptr_t value) const {
    ASSERT((Utils::IsAligned(value, kObjectAlignment) &&
            (value == raw_ptr()->instance_size_)) ||
           (!Utils::IsAligned(value, kObjectAlignment) &&
            (value + kWordSize == raw_ptr()->instance_size_)));
    raw_ptr()->next_field_offset_ = value;
  }

  cpp_vtable handle_vtable() const { return raw_ptr()->handle_vtable_; }
  void set_handle_vtable(cpp_vtable value) const {
    raw_ptr()->handle_vtable_ = value;
  }

  intptr_t id() const { return raw_ptr()->id_; }
  void set_id(intptr_t value) const {
    raw_ptr()->id_ = value;
  }

  RawString* Name() const;

  RawString* UserVisibleName() const;

  RawScript* script() const { return raw_ptr()->script_; }

  intptr_t token_pos() const { return raw_ptr()->token_pos_; }

  // This class represents the signature class of a closure function if
  // signature_function() is not null.
  // The associated function may be a closure function (with code) or a
  // signature function (without code) solely describing the result type and
  // parameter types of the signature.
  RawFunction* signature_function() const {
    return raw_ptr()->signature_function_;
  }
  static intptr_t signature_function_offset() {
    return OFFSET_OF(RawClass, signature_function_);
  }

  // Return the signature type of this signature class.
  // For example, if this class represents a signature of the form
  // '<T, R>(T, [b: B, c: C]) => R', then its signature type is a parameterized
  // type with this class as the type class and type parameters 'T' and 'R'
  // as its type argument vector.
  RawType* SignatureType() const;

  RawLibrary* library() const { return raw_ptr()->library_; }
  void set_library(const Library& value) const;

  // The type parameters (and their bounds) are specified as an array of
  // TypeParameter.
  RawTypeArguments* type_parameters() const {
      return raw_ptr()->type_parameters_;
  }
  void set_type_parameters(const TypeArguments& value) const;
  intptr_t NumTypeParameters() const;
  static intptr_t type_parameters_offset() {
    return OFFSET_OF(RawClass, type_parameters_);
  }

  // Return a TypeParameter if the type_name is a type parameter of this class.
  // Return null otherwise.
  RawTypeParameter* LookupTypeParameter(const String& type_name,
                                        intptr_t token_pos) const;

  // The type argument vector is flattened and includes the type arguments of
  // the super class.
  bool HasTypeArguments() const;
  intptr_t NumTypeArguments() const;

  // If this class is parameterized, each instance has a type_arguments field.
  static const intptr_t kNoTypeArguments = -1;
  intptr_t type_arguments_instance_field_offset() const {
    ASSERT(is_finalized() || is_prefinalized());
    return raw_ptr()->type_arguments_instance_field_offset_;
  }
  void set_type_arguments_instance_field_offset(intptr_t value) const {
    raw_ptr()->type_arguments_instance_field_offset_ = value;
  }
  static intptr_t type_arguments_instance_field_offset_offset() {
    return OFFSET_OF(RawClass, type_arguments_instance_field_offset_);
  }

  // The super type of this class, Object type if not explicitly specified.
  RawType* super_type() const { return raw_ptr()->super_type_; }
  void set_super_type(const Type& value) const;
  static intptr_t super_type_offset() {
    return OFFSET_OF(RawClass, super_type_);
  }

  // Asserts that the class of the super type has been resolved.
  RawClass* SuperClass() const;

  // Return true if this interface has a factory class.
  bool HasFactoryClass() const;

  // Return true if the factory class of this interface is resolved.
  bool HasResolvedFactoryClass() const;

  // Return the resolved factory class of this interface.
  RawClass* FactoryClass() const;

  // Return the unresolved factory class of this interface.
  RawUnresolvedClass* UnresolvedFactoryClass() const;

  // Set the resolved or unresolved factory class of this interface.
  void set_factory_class(const Object& value) const;

  // Interfaces is an array of Types.
  RawArray* interfaces() const { return raw_ptr()->interfaces_; }
  void set_interfaces(const Array& value) const;
  static intptr_t interfaces_offset() {
    return OFFSET_OF(RawClass, interfaces_);
  }

  RawArray* functions_cache() const { return raw_ptr()->functions_cache_; }
  void set_functions_cache(const Array& value) const;

  static intptr_t functions_cache_offset() {
    return OFFSET_OF(RawClass, functions_cache_);
  }

  // Check if this class represents the class of null.
  bool IsNullClass() const { return raw() == Object::null_class(); }

  // Check if this class represents the 'Dynamic' class.
  bool IsDynamicClass() const { return raw() == Object::dynamic_class(); }

  // Check if this class represents the 'void' class.
  bool IsVoidClass() const { return raw() == Object::void_class(); }

  // Check if this class represents the 'Object' class.
  bool IsObjectClass() const;

  // Check if this class represents a signature class.
  bool IsSignatureClass() const {
    return signature_function() != Object::null();
  }
  static bool IsSignatureClass(RawClass* cls) {
    return cls->ptr()->signature_function_ != Object::null();
  }

  // Check if this class represents a canonical signature class, i.e. not an
  // alias as defined in a typedef.
  bool IsCanonicalSignatureClass() const;

  // Check the subtype relationship.
  bool IsSubtypeOf(const AbstractTypeArguments& type_arguments,
                   const Class& other,
                   const AbstractTypeArguments& other_type_arguments,
                   Error* malformed_error) const {
    return TypeTest(kIsSubtypeOf,
                    type_arguments,
                    other,
                    other_type_arguments,
                    malformed_error);
  }

  // Check the 'more specific' relationship.
  bool IsMoreSpecificThan(const AbstractTypeArguments& type_arguments,
                          const Class& other,
                          const AbstractTypeArguments& other_type_arguments,
                          Error* malformed_error) const {
    return TypeTest(kIsMoreSpecificThan,
                    type_arguments,
                    other,
                    other_type_arguments,
                    malformed_error);
  }

  // Check if this is the top level class.
  bool IsTopLevel() const;

  RawArray* fields() const { return raw_ptr()->fields_; }
  void SetFields(const Array& value) const;

  // Returns true if non-static fields are defined.
  bool HasInstanceFields() const;

  RawArray* functions() const { return raw_ptr()->functions_; }
  void SetFunctions(const Array& value) const;

  void AddClosureFunction(const Function& function) const;
  RawFunction* LookupClosureFunction(intptr_t token_pos) const;

  RawFunction* LookupDynamicFunction(const String& name) const;
  RawFunction* LookupStaticFunction(const String& name) const;
  RawFunction* LookupConstructor(const String& name) const;
  RawFunction* LookupFactory(const String& name) const;
  RawFunction* LookupFunction(const String& name) const;
  RawFunction* LookupGetterFunction(const String& name) const;
  RawFunction* LookupSetterFunction(const String& name) const;
  RawFunction* LookupFunctionAtToken(intptr_t token_pos) const;
  RawField* LookupInstanceField(const String& name) const;
  RawField* LookupStaticField(const String& name) const;
  RawField* LookupField(const String& name) const;

  RawLibraryPrefix* LookupLibraryPrefix(const String& name) const;

  void InsertCanonicalConstant(intptr_t index, const Instance& constant) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawClass));
  }

  bool is_interface() const {
    return raw_ptr()->is_interface_;
  }
  void set_is_interface() const;
  static intptr_t is_interface_offset() {
    return OFFSET_OF(RawClass, is_interface_);
  }

  bool is_finalized() const {
    return raw_ptr()->class_state_ == RawClass::kFinalized;
  }
  void set_is_finalized() const;

  bool is_prefinalized() const {
    return raw_ptr()->class_state_ == RawClass::kPreFinalized;
  }

  void set_is_prefinalized() const;

  bool is_const() const {
    return raw_ptr()->is_const_;
  }
  void set_is_const() const;

  int num_native_fields() const {
    return raw_ptr()->num_native_fields_;
  }
  void set_num_native_fields(int value) const {
    raw_ptr()->num_native_fields_ = value;
  }
  static intptr_t num_native_fields_offset() {
    return OFFSET_OF(RawClass, num_native_fields_);
  }

  RawCode* allocation_stub() const {
    return raw_ptr()->allocation_stub_;
  }
  void set_allocation_stub(const Code& value) const;

  RawArray* constants() const;

  void Finalize() const;

  // Allocate a class used for VM internal objects.
  template <class FakeObject> static RawClass* New();

  // Allocate instance classes and interfaces.
  static RawClass* New(const String& name,
                       const Script& script,
                       intptr_t token_pos);
  static RawClass* NewInterface(const String& name,
                                const Script& script,
                                intptr_t token_pos);
  static RawClass* NewNativeWrapper(Library* library,
                                    const String& name,
                                    int num_fields);

  // Allocate a class representing a function signature described by
  // signature_function, which must be a closure function or a signature
  // function.
  // The class may be type parameterized unless the signature_function is in a
  // static scope. In that case, the type parameters are copied from the owner
  // class of signature_function.
  static RawClass* NewSignatureClass(const String& name,
                                     const Function& signature_function,
                                     const Script& script);

  // Return a class object corresponding to the specified kind. If
  // a canonicalized version of it exists then that object is returned
  // otherwise a new object is allocated and returned.
  static RawClass* GetClass(intptr_t class_id, bool is_signature_class);

 private:
  void set_name(const String& value) const;
  void set_script(const Script& value) const;
  void set_token_pos(intptr_t value) const;
  void set_signature_function(const Function& value) const;
  void set_signature_type(const AbstractType& value) const;
  void set_class_state(int8_t state) const;

  void set_constants(const Array& value) const;

  void set_canonical_types(const Array& value) const;
  RawArray* canonical_types() const;

  void CalculateFieldOffsets() const;

  // Assigns empty array to all raw class array fields.
  void InitEmptyFields();

  RawFunction* LookupAccessorFunction(const char* prefix,
                                      intptr_t prefix_length,
                                      const String& name) const;

  // Allocate an instance class which has a VM implementation.
  template <class FakeInstance> static RawClass* New(intptr_t id);
  template <class FakeInstance> static RawClass* New(const String& name,
                                                     const Script& script,
                                                     intptr_t token_pos);

  // Check the subtype or 'more specific' relationship.
  bool TypeTest(TypeTestKind test_kind,
                const AbstractTypeArguments& type_arguments,
                const Class& other,
                const AbstractTypeArguments& other_type_arguments,
                Error* malformed_error) const;

  HEAP_OBJECT_IMPLEMENTATION(Class, Object);
  friend class AbstractType;
  friend class Instance;
  friend class Object;
  friend class Type;
};


// Unresolved class is used for storing unresolved names which will be resolved
// to a class after all classes have been loaded and finalized.
class UnresolvedClass : public Object {
 public:
  RawLibraryPrefix* library_prefix() const {
    return raw_ptr()->library_prefix_;
  }
  RawString* ident() const { return raw_ptr()->ident_; }
  intptr_t token_pos() const { return raw_ptr()->token_pos_; }

  RawClass* factory_signature_class() const {
    return raw_ptr()->factory_signature_class_;
  }
  void set_factory_signature_class(const Class& value) const;

  RawString* Name() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawUnresolvedClass));
  }
  static RawUnresolvedClass* New(const LibraryPrefix& library_prefix,
                                 const String& ident,
                                 intptr_t token_pos);

 private:
  void set_library_prefix(const LibraryPrefix& library_prefix) const;
  void set_ident(const String& ident) const;
  void set_token_pos(intptr_t token_pos) const;

  static RawUnresolvedClass* New();

  HEAP_OBJECT_IMPLEMENTATION(UnresolvedClass, Object);
  friend class Class;
};


// AbstractType is an abstract superclass.
// Subclasses of AbstractType are Type and TypeParameter.
class AbstractType : public Object {
 public:
  virtual bool IsFinalized() const;
  virtual bool IsBeingFinalized() const;
  virtual bool IsMalformed() const;
  virtual RawError* malformed_error() const;
  virtual void set_malformed_error(const Error& value) const;
  virtual bool IsResolved() const;
  virtual bool HasResolvedTypeClass() const;
  virtual RawClass* type_class() const;
  virtual RawUnresolvedClass* unresolved_class() const;
  virtual RawAbstractTypeArguments* arguments() const;
  virtual intptr_t token_pos() const;
  virtual bool IsInstantiated() const;
  virtual bool Equals(const AbstractType& other) const;
  virtual bool IsIdentical(const AbstractType& other,
                           bool check_type_parameter_bound) const;

  // Instantiate this type using the given type argument vector.
  // Return a new type, or return 'this' if it is already instantiated.
  virtual RawAbstractType* InstantiateFrom(
      const AbstractTypeArguments& instantiator_type_arguments) const;

  // Return the canonical version of this type.
  virtual RawAbstractType* Canonicalize() const;

  // The name of this type, including the names of its type arguments, if any.
  virtual RawString* Name() const {
    return BuildName(kInternalName);
  }

  // The name of this type, including the names of its type arguments, if any.
  // Names of internal classes are mapped to their public interfaces.
  virtual RawString* UserVisibleName() const {
    return BuildName(kUserVisibleName);
  }

  // The name of this type's class, i.e. without the type argument names of this
  // type.
  RawString* ClassName() const;

  // Check if this type represents the 'Dynamic' type.
  bool IsDynamicType() const {
    return HasResolvedTypeClass() && (type_class() == Object::dynamic_class());
  }

  // Check if this type represents the 'Null' type.
  bool IsNullType() const {
    return HasResolvedTypeClass() && (type_class() == Object::null_class());
  }

  // Check if this type represents the 'void' type.
  bool IsVoidType() const {
    return HasResolvedTypeClass() && (type_class() == Object::void_class());
  }

  bool IsObjectType() const {
    return HasResolvedTypeClass() &&
        Class::Handle(type_class()).IsObjectClass();
  }

  // Check if this type represents the 'bool' interface.
  bool IsBoolInterface() const;

  // Check if this type represents the 'int' interface.
  bool IsIntInterface() const;

  // Check if this type represents the 'double' interface.
  bool IsDoubleInterface() const;

  // Check if this type represents the 'num' interface.
  bool IsNumberInterface() const;

  // Check if this type represents the 'String' interface.
  bool IsStringInterface() const;

  // Check if this type represents the 'Function' interface.
  bool IsFunctionInterface() const;

  // Check if this type represents the 'List' interface.
  bool IsListInterface() const;

  // Check if this type is an interface type.
  bool IsInterfaceType() const {
    if (!HasResolvedTypeClass()) {
      return false;
    }
    const Class& cls = Class::Handle(type_class());
    return !cls.IsNull() && cls.is_interface();
  }

  // Check the subtype relationship.
  bool IsSubtypeOf(const AbstractType& other, Error* malformed_error) const {
    return TypeTest(kIsSubtypeOf, other, malformed_error);
  }

  // Check the 'more specific' relationship.
  bool IsMoreSpecificThan(const AbstractType& other,
                          Error* malformed_error) const {
    return TypeTest(kIsMoreSpecificThan, other, malformed_error);
  }

 private:
  // Check the subtype or 'more specific' relationship.
  bool TypeTest(TypeTestKind test_kind,
                const AbstractType& other,
                Error* malformed_error) const;

  // Return the internal or public name of this type, including the names of its
  // type arguments, if any.
  RawString* BuildName(NameVisibility visibility) const;

 protected:
  HEAP_OBJECT_IMPLEMENTATION(AbstractType, Object);
  friend class AbstractTypeArguments;
  friend class Class;
  friend class Function;
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
  static intptr_t type_class_offset() {
    return OFFSET_OF(RawType, type_class_);
  }
  virtual bool IsFinalized() const {
    return
        (raw_ptr()->type_state_ == RawType::kFinalizedInstantiated) ||
        (raw_ptr()->type_state_ == RawType::kFinalizedUninstantiated);
  }
  void set_is_finalized_instantiated() const;
  void set_is_finalized_uninstantiated() const;
  virtual bool IsBeingFinalized() const {
    return raw_ptr()->type_state_ == RawType::kBeingFinalized;
  }
  void set_is_being_finalized() const;
  virtual bool IsMalformed() const;
  virtual RawError* malformed_error() const;
  virtual void set_malformed_error(const Error& value) const;
  virtual bool IsResolved() const;  // Class and all arguments classes resolved.
  virtual bool HasResolvedTypeClass() const;  // Own type class resolved.
  virtual RawClass* type_class() const;
  void set_type_class(const Object& value) const;
  virtual RawUnresolvedClass* unresolved_class() const;
  RawString* TypeClassName() const;
  virtual RawAbstractTypeArguments* arguments() const;
  void set_arguments(const AbstractTypeArguments& value) const;
  virtual intptr_t token_pos() const { return raw_ptr()->token_pos_; }
  virtual bool IsInstantiated() const;
  virtual bool Equals(const AbstractType& other) const;
  virtual bool IsIdentical(const AbstractType& other,
                           bool check_type_parameter_bound) const;
  virtual RawAbstractType* InstantiateFrom(
      const AbstractTypeArguments& instantiator_type_arguments) const;
  virtual RawAbstractType* Canonicalize() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawType));
  }

  // The type of the literal 'null'.
  static RawType* NullType();

  // The 'Dynamic' type.
  static RawType* DynamicType();

  // The 'void' type.
  static RawType* VoidType();

  // The 'Object' type.
  static RawType* ObjectType();

  // The 'bool' interface type.
  static RawType* BoolInterface();

  // The 'int' interface type.
  static RawType* IntInterface();

  // The 'double' interface type.
  static RawType* DoubleInterface();

  // The 'num' interface type.
  static RawType* NumberInterface();

  // The 'String' interface type.
  static RawType* StringInterface();

  // The 'Function' interface type.
  static RawType* FunctionInterface();

  // The 'List' interface type.
  static RawType* ListInterface();

  // The finalized type of the given non-parameterized class.
  static RawType* NewNonParameterizedType(const Class& type_class);

  static RawType* New(const Object& clazz,
                      const AbstractTypeArguments& arguments,
                      intptr_t token_pos,
                      Heap::Space space = Heap::kOld);

 private:
  void set_token_pos(intptr_t token_pos) const;
  void set_type_state(int8_t state) const;

  static RawType* New(Heap::Space space = Heap::kOld);

  HEAP_OBJECT_IMPLEMENTATION(Type, AbstractType);
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
// to the DynamicType.
class TypeParameter : public AbstractType {
 public:
  virtual bool IsFinalized() const {
    ASSERT(raw_ptr()->type_state_ != RawTypeParameter::kFinalizedInstantiated);
    return raw_ptr()->type_state_ == RawTypeParameter::kFinalizedUninstantiated;
  }
  void set_is_finalized() const;
  virtual bool IsBeingFinalized() const { return false; }
  virtual bool IsMalformed() const { return false; }
  virtual bool IsResolved() const { return true; }
  virtual bool HasResolvedTypeClass() const { return false; }
  RawClass* parameterized_class() const {
      return raw_ptr()->parameterized_class_;
  }
  RawString* name() const { return raw_ptr()->name_; }
  intptr_t index() const { return raw_ptr()->index_; }
  void set_index(intptr_t value) const;
  RawAbstractType* bound() const { return raw_ptr()->bound_; }
  void set_bound(const AbstractType& value) const;
  virtual intptr_t token_pos() const { return raw_ptr()->token_pos_; }
  virtual bool IsInstantiated() const { return false; }
  virtual bool Equals(const AbstractType& other) const;
  virtual bool IsIdentical(const AbstractType& other,
                           bool check_type_parameter_bound) const;
  virtual RawAbstractType* InstantiateFrom(
      const AbstractTypeArguments& instantiator_type_arguments) const;
  virtual RawAbstractType* Canonicalize() const { return raw(); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawTypeParameter));
  }

  static RawTypeParameter* New(const Class& parameterized_class,
                               intptr_t index,
                               const String& name,
                               const AbstractType& bound,
                               intptr_t token_pos);

 private:
  void set_parameterized_class(const Class& value) const;
  void set_name(const String& value) const;
  void set_token_pos(intptr_t token_pos) const;
  void set_type_state(int8_t state) const;
  static RawTypeParameter* New();

  HEAP_OBJECT_IMPLEMENTATION(TypeParameter, AbstractType);
  friend class Class;
};


// AbstractTypeArguments is an abstract superclass.
// Subclasses of AbstractTypeArguments are TypeArguments and
// InstantiatedTypeArguments.
class AbstractTypeArguments : public Object {
 public:
  // Returns true if both arguments represent vectors of equal types.
  static bool AreEqual(const AbstractTypeArguments& arguments,
                       const AbstractTypeArguments& other_arguments);

  // Returns true if both arguments represent vectors of possibly still
  // unresolved identical types.
  static bool AreIdentical(const AbstractTypeArguments& arguments,
                           const AbstractTypeArguments& other_arguments,
                           bool check_type_parameter_bounds);

  // Return 'this' if this type argument vector is instantiated, i.e. if it does
  // not refer to type parameters. Otherwise, return a new type argument vector
  // where each reference to a type parameter is replaced with the corresponding
  // type of the instantiator type argument vector.
  virtual RawAbstractTypeArguments* InstantiateFrom(
      const AbstractTypeArguments& instantiator_type_arguments) const;

  // Do not canonicalize InstantiatedTypeArguments or NULL objects
  virtual RawAbstractTypeArguments* Canonicalize() const { return this->raw(); }

  // The name of this type argument vector, e.g. "<T, Dynamic, List<T>, Smi>".
  virtual RawString* Name() const {
    return SubvectorName(0, Length(), kInternalName);
  }

  // The name of this type argument vector, e.g. "<T, Dynamic, List<T>, int>".
  // Names of internal classes are mapped to their public interfaces.
  virtual RawString* UserVisibleName() const {
    return SubvectorName(0, Length(), kUserVisibleName);
  }

  // Check if this type argument vector consists solely of DynamicType,
  // considering only a prefix of length 'len'.
  bool IsRaw(intptr_t len) const {
    return IsDynamicTypes(false, len);
  }

  // Check if this type argument vector would consist solely of DynamicType if
  // it was instantiated from a raw (null) instantiator, i.e. consider each type
  // parameter as it would be first instantiated from a vector of dynamic types.
  // Consider only a prefix of length 'len'.
  bool IsRawInstantiatedRaw(intptr_t len) const {
    return IsDynamicTypes(true, len);
  }

  // Check that this type argument vector is within the declared bounds of the
  // given class or interface. If not, set malformed_error (if not yet set).
  bool IsWithinBoundsOf(const Class& cls,
                        const AbstractTypeArguments& bounds_instantiator,
                        Error* malformed_error) const;

  // Check the subtype relationship, considering only a prefix of length 'len'.
  bool IsSubtypeOf(const AbstractTypeArguments& other,
                   intptr_t len,
                   Error* malformed_error) const {
    return TypeTest(kIsSubtypeOf, other, len, malformed_error);
  }

  // Check the 'more specific' relationship, considering only a prefix of
  // length 'len'.
  bool IsMoreSpecificThan(const AbstractTypeArguments& other,
                          intptr_t len,
                          Error* malformed_error) const {
    return TypeTest(kIsMoreSpecificThan, other, len, malformed_error);
  }

  bool Equals(const AbstractTypeArguments& other) const;

  // UNREACHABLEs as AbstractTypeArguments is an abstract class.
  virtual intptr_t Length() const;
  virtual RawAbstractType* TypeAt(intptr_t index) const;
  virtual void SetTypeAt(intptr_t index, const AbstractType& value) const;
  virtual bool IsResolved() const;
  virtual bool IsInstantiated() const;
  virtual bool IsUninstantiatedIdentity() const;

 private:
  // Check if this type argument vector consists solely of DynamicType,
  // considering only a prefix of length 'len'.
  // If raw_instantiated is true, consider each type parameter to be first
  // instantiated from a vector of dynamic types.
  bool IsDynamicTypes(bool raw_instantiated, intptr_t len) const;

  // Check the subtype or 'more specific' relationship, considering only a
  // prefix of length 'len'.
  bool TypeTest(TypeTestKind test_kind,
                const AbstractTypeArguments& other,
                intptr_t len,
                Error* malformed_error) const;

  // Return the internal or public name of a subvector of this type argument
  // vector, e.g. "<T, Dynamic, List<T>, int>".
  RawString* SubvectorName(intptr_t from_index,
                           intptr_t len,
                           NameVisibility name_visibility) const;

 protected:
  HEAP_OBJECT_IMPLEMENTATION(AbstractTypeArguments, Object);
  friend class AbstractType;
  friend class Class;
};


// A TypeArguments is an array of AbstractType.
class TypeArguments : public AbstractTypeArguments {
 public:
  virtual intptr_t Length() const;
  virtual RawAbstractType* TypeAt(intptr_t index) const;
  static intptr_t type_at_offset(intptr_t index) {
    return OFFSET_OF(RawTypeArguments, types_) + index * kWordSize;
  }
  virtual void SetTypeAt(intptr_t index, const AbstractType& value) const;
  virtual bool IsResolved() const;
  virtual bool IsInstantiated() const;
  virtual bool IsUninstantiatedIdentity() const;
  // Canonicalize only if instantiated, otherwise returns 'this'.
  virtual RawAbstractTypeArguments* Canonicalize() const;

  virtual RawAbstractTypeArguments* InstantiateFrom(
      const AbstractTypeArguments& instantiator_type_arguments) const;

  static const intptr_t kBytesPerElement = kWordSize;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t length_offset() {
    return OFFSET_OF(RawTypeArguments, length_);
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawTypeArguments) == OFFSET_OF(RawTypeArguments, types_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    // Ensure that the types_ is not adding to the object length.
    ASSERT(sizeof(RawTypeArguments) == (sizeof(RawObject) + (1 * kWordSize)));
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawTypeArguments) + (len * kBytesPerElement));
  }

  static RawTypeArguments* New(intptr_t len, Heap::Space space = Heap::kOld);

 private:
  RawAbstractType** TypeAddr(intptr_t index) const;
  void SetLength(intptr_t value) const;

  HEAP_OBJECT_IMPLEMENTATION(TypeArguments, AbstractTypeArguments);
  friend class Class;
};


// An instance of InstantiatedTypeArguments is never encountered at compile
// time, but only at run time, when type parameters can be matched to actual
// types.
// An instance of InstantiatedTypeArguments consists of a pair of
// AbstractTypeArguments objects. The first type argument vector is
// uninstantiated, because it contains type expressions referring to at least
// one TypeParameter object, i.e. to a type that is not known at compile time.
// The second type argument vector is the instantiator, because each type
// parameter with index i in the first vector can be substituted (or
// "instantiated") with the type at index i in the second type argument vector.
class InstantiatedTypeArguments : public AbstractTypeArguments {
 public:
  virtual intptr_t Length() const;
  virtual RawAbstractType* TypeAt(intptr_t index) const;
  virtual void SetTypeAt(intptr_t index, const AbstractType& value) const;
  virtual bool IsResolved() const { return true; }
  virtual bool IsInstantiated() const { return true; }
  virtual bool IsUninstantiatedIdentity() const  { return false; }

  RawAbstractTypeArguments* uninstantiated_type_arguments() const {
    return raw_ptr()->uninstantiated_type_arguments_;
  }
  static intptr_t uninstantiated_type_arguments_offset() {
    return OFFSET_OF(RawInstantiatedTypeArguments,
                     uninstantiated_type_arguments_);
  }

  RawAbstractTypeArguments* instantiator_type_arguments() const {
    return raw_ptr()->instantiator_type_arguments_;
  }
  static intptr_t instantiator_type_arguments_offset() {
    return OFFSET_OF(RawInstantiatedTypeArguments,
                     instantiator_type_arguments_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawInstantiatedTypeArguments));
  }

  static RawInstantiatedTypeArguments* New(
      const AbstractTypeArguments& uninstantiated_type_arguments,
      const AbstractTypeArguments& instantiator_type_arguments);

 private:
  void set_uninstantiated_type_arguments(
      const AbstractTypeArguments& value) const;
  void set_instantiator_type_arguments(
      const AbstractTypeArguments& value) const;
  static RawInstantiatedTypeArguments* New();

  HEAP_OBJECT_IMPLEMENTATION(InstantiatedTypeArguments, AbstractTypeArguments);
  friend class Class;
};


class Function : public Object {
 public:
  RawString* name() const { return raw_ptr()->name_; }
  RawString* UserVisibleName() const;
  RawString* QualifiedUserVisibleName() const;

  // Build a string of the form '<T, R>(T, [b: B, c: C]) => R' representing the
  // internal signature of the given function.
  RawString* Signature() const {
    const bool instantiate = false;
    return BuildSignature(instantiate, kInternalName, TypeArguments::Handle());
  }

  // Build a string of the form '(A, [b: B, c: C]) => D' representing the
  // signature of the given function, where all generic types (e.g. '<T, R>' in
  // '<T, R>(T, [b: B, c: C]) => R') are instantiated using the given
  // instantiator type argument vector (e.g. '<A, D>').
  RawString* InstantiatedSignatureFrom(
      const AbstractTypeArguments& instantiator,
      NameVisibility name_visibility) const {
    const bool instantiate = true;
    return BuildSignature(instantiate, name_visibility, instantiator);
  }

  // Returns true if the signature of this function is instantiated, i.e. if it
  // does not involve generic parameter types or generic result type.
  bool HasInstantiatedSignature() const;

  RawClass* owner() const { return raw_ptr()->owner_; }

  RawAbstractType* result_type() const { return raw_ptr()->result_type_; }
  void set_result_type(const AbstractType& value) const;

  RawAbstractType* ParameterTypeAt(intptr_t index) const;
  void SetParameterTypeAt(intptr_t index, const AbstractType& value) const;
  void set_parameter_types(const Array& value) const;

  // Parameter names are valid for all valid parameter indices, and are not
  // limited to named optional parameters.
  RawString* ParameterNameAt(intptr_t index) const;
  void SetParameterNameAt(intptr_t index, const String& value) const;
  void set_parameter_names(const Array& value) const;

  // Sets function's code and code's function.
  void SetCode(const Code& value) const;

  // Disables optimized code and switches to unoptimized code.
  void SwitchToUnoptimizedCode() const;

  // Return the most recently compiled and installed code for this function.
  // It is not the only Code object that points to this function.
  RawCode* CurrentCode() const { return raw_ptr()->code_; }

  RawCode* unoptimized_code() const { return raw_ptr()->unoptimized_code_; }
  void set_unoptimized_code(const Code& value) const;
  static intptr_t code_offset() { return OFFSET_OF(RawFunction, code_); }
  inline bool HasCode() const;

  RawContextScope* context_scope() const { return raw_ptr()->context_scope_; }
  void set_context_scope(const ContextScope& value) const;

  // Enclosing function of this local function.
  RawFunction* parent_function() const { return raw_ptr()->parent_function_; }

  // Signature class of this closure function or signature function.
  RawClass* signature_class() const { return raw_ptr()->signature_class_; }
  void set_signature_class(const Class& value) const;

  RawCode* closure_allocation_stub() const {
    return raw_ptr()->closure_allocation_stub_;
  }
  void set_closure_allocation_stub(const Code& value) const;

  // Return the closure function implicitly created for this function.
  // If none exists yet, create one and remember it.
  RawFunction* ImplicitClosureFunction() const;

  RawFunction::Kind kind() const { return raw()->GetKind(); }

  bool is_static() const { return raw()->IsStatic(); }
  bool is_const() const { return raw()->IsConst(); }
  bool is_external() const { return raw()->IsExternal(); }
  bool IsConstructor() const {
    return (kind() == RawFunction::kConstructor) && !is_static();
  }
  bool IsFactory() const {
    return (kind() == RawFunction::kConstructor) && is_static();
  }
  bool IsDynamicFunction() const {
    if (is_static() || is_abstract()) {
      return false;
    }
    switch (kind()) {
      case RawFunction::kRegularFunction:
      case RawFunction::kGetterFunction:
      case RawFunction::kSetterFunction:
      case RawFunction::kImplicitGetter:
      case RawFunction::kImplicitSetter:
        return true;
      case RawFunction::kClosureFunction:
      case RawFunction::kConstructor:
      case RawFunction::kConstImplicitGetter:
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
      case RawFunction::kConstImplicitGetter:
        return true;
      case RawFunction::kClosureFunction:
      case RawFunction::kConstructor:
        return false;
      default:
        UNREACHABLE();
        return false;
    }
  }
  bool IsInFactoryScope() const;

  intptr_t token_pos() const { return raw_ptr()->token_pos_; }

  intptr_t end_token_pos() const { return raw_ptr()->end_token_pos_; }
  void set_end_token_pos(intptr_t value) const {
    raw_ptr()->end_token_pos_ = value;
  }

  static intptr_t num_fixed_parameters_offset() {
    return OFFSET_OF(RawFunction, num_fixed_parameters_);
  }
  intptr_t num_fixed_parameters() const {
    return raw_ptr()->num_fixed_parameters_;
  }
  void set_num_fixed_parameters(intptr_t value) const;

  static intptr_t num_optional_parameters_offset() {
    return OFFSET_OF(RawFunction, num_optional_parameters_);
  }
  intptr_t num_optional_parameters() const {
    return raw_ptr()->num_optional_parameters_;
  }
  void set_num_optional_parameters(intptr_t value) const;

  static intptr_t usage_counter_offset() {
    return OFFSET_OF(RawFunction, usage_counter_);
  }
  intptr_t usage_counter() const {
    return raw_ptr()->usage_counter_;
  }
  void set_usage_counter(intptr_t value) const {
    raw_ptr()->usage_counter_ = value;
  }

  intptr_t deoptimization_counter() const {
    return raw_ptr()->deoptimization_counter_;
  }
  void set_deoptimization_counter(intptr_t value) const {
    raw_ptr()->deoptimization_counter_ = value;
  }

  bool is_optimizable() const { return raw()->IsOptimizable(); }
  void set_is_optimizable(bool value) const;

  bool has_finally() const { return raw()->HasFinally(); }
  void set_has_finally(bool value) const;

  bool is_native() const { return raw()->IsNative(); }
  void set_is_native(bool value) const;

  bool is_abstract() const { return raw()->IsAbstract(); }
  void set_is_abstract(bool value) const;

  bool HasOptimizedCode() const;

  intptr_t NumberOfParameters() const;
  intptr_t NumberOfImplicitParameters() const;

  // Returns true if the argument counts are valid for calling this function.
  // Otherwise, it returns false and the reason (if error_message is not NULL).
  bool AreValidArgumentCounts(int num_arguments,
                              int num_named_arguments,
                              String* error_message) const;

  // Returns true if the total argument count and the names of optional
  // arguments are valid for calling this function.
  // Otherwise, it returns false and the reason (if error_message is not NULL).
  bool AreValidArguments(int num_arguments,
                         const Array& argument_names,
                         String* error_message) const;

  // Fully qualified name uniquely identifying the function under gdb and during
  // ast printing. The special ':' character, if present, is replaced by '_'.
  const char* ToFullyQualifiedCString() const;

  // Returns true if this function has parameters that are compatible with the
  // parameters of the other function in order for this function to override the
  // other function. Parameter types are ignored.
  bool HasCompatibleParametersWith(const Function& other) const;

  // Returns true if the type of this function is a subtype of the type of
  // the other function.
  bool IsSubtypeOf(const AbstractTypeArguments& type_arguments,
                   const Function& other,
                   const AbstractTypeArguments& other_type_arguments,
                   Error* malformed_error) const {
    return TypeTest(kIsSubtypeOf,
                    type_arguments,
                    other,
                    other_type_arguments,
                    malformed_error);
  }

  // Returns true if the type of this function is more specific than the type of
  // the other function.
  bool IsMoreSpecificThan(const AbstractTypeArguments& type_arguments,
                          const Function& other,
                          const AbstractTypeArguments& other_type_arguments,
                          Error* malformed_error) const {
    return TypeTest(kIsMoreSpecificThan,
                    type_arguments,
                    other,
                    other_type_arguments,
                    malformed_error);
  }

  // Returns true if this function represents a (possibly implicit) closure
  // function.
  bool IsClosureFunction() const {
    return kind() == RawFunction::kClosureFunction;
  }

  // Returns true if this function represents an implicit closure function.
  bool IsImplicitClosureFunction() const;

  // Returns true if this function represents a non implicit closure function.
  bool IsNonImplicitClosureFunction() const {
    return IsClosureFunction() && !IsImplicitClosureFunction();
  }

  // Returns true if this function represents an implicit static closure
  // function.
  bool IsImplicitStaticClosureFunction() const {
    return is_static() && IsImplicitClosureFunction();
  }

  // Returns true if this function represents an implicit instance closure
  // function.
  bool IsImplicitInstanceClosureFunction() const {
    return !is_static() && IsImplicitClosureFunction();
  }

  // Returns true if this function represents a local function.
  bool IsLocalFunction() const {
    return parent_function() != Function::null();
  }

  // Returns true if this function represents a signature function without code.
  bool IsSignatureFunction() const {
    return kind() == RawFunction::kSignatureFunction;
  }


  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawFunction));
  }

  static RawFunction* New(const String& name,
                          RawFunction::Kind kind,
                          bool is_static,
                          bool is_const,
                          bool is_abstract,
                          bool is_external,
                          const Class& owner,
                          intptr_t token_pos);

  // Allocates a new Function object representing a closure function, as well as
  // a new associated Class object representing the signature class of the
  // function.
  // The function and the class share the same given name.
  static RawFunction* NewClosureFunction(const String& name,
                                         const Function& parent,
                                         intptr_t token_pos);

  static const int kCtorPhaseInit = 1 << 0;
  static const int kCtorPhaseBody = 1 << 1;
  static const int kCtorPhaseAll = (kCtorPhaseInit | kCtorPhaseBody);

 private:
  void set_name(const String& value) const;
  void set_kind(RawFunction::Kind value) const;
  void set_is_static(bool is_static) const;
  void set_is_const(bool is_const) const;
  void set_is_external(bool value) const;
  void set_parent_function(const Function& value) const;
  void set_owner(const Class& value) const;
  void set_token_pos(intptr_t value) const;
  void set_implicit_closure_function(const Function& value) const;
  static RawFunction* New();

  RawString* BuildSignature(bool instantiate,
                            NameVisibility name_visibility,
                            const AbstractTypeArguments& instantiator) const;

  // Check the subtype or 'more specific' relationship.
  bool TypeTest(TypeTestKind test_kind,
                const AbstractTypeArguments& type_arguments,
                const Function& other,
                const AbstractTypeArguments& other_type_arguments,
                Error* malformed_error) const;

  // Checks the type of the formal parameter at the given position for
  // subtyping or 'more specific' relationship between the type of this function
  // and the type of the other function.
  bool TestParameterType(TypeTestKind test_kind,
                         intptr_t parameter_position,
                         const AbstractTypeArguments& type_arguments,
                         const Function& other,
                         const AbstractTypeArguments& other_type_arguments,
                         Error* malformed_error) const;

  HEAP_OBJECT_IMPLEMENTATION(Function, Object);
  friend class Class;
};


class Field : public Object {
 public:
  RawString* name() const { return raw_ptr()->name_; }
  RawString* UserVisibleName() const;

  bool is_static() const { return raw_ptr()->is_static_; }
  bool is_final() const { return raw_ptr()->is_final_; }
  bool is_const() const { return raw_ptr()->is_const_; }

  inline intptr_t Offset() const;
  inline void SetOffset(intptr_t value) const;

  RawInstance* value() const;
  void set_value(const Instance& value) const;

  RawClass* owner() const { return raw_ptr()->owner_; }

  RawAbstractType* type() const  { return raw_ptr()->type_; }
  void set_type(const AbstractType& value) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawField));
  }

  static RawField* New(const String& name,
                       bool is_static,
                       bool is_final,
                       bool is_const,
                       const Class& owner,
                       intptr_t token_pos);

  static intptr_t value_offset() { return OFFSET_OF(RawField, value_); }

  intptr_t token_pos() const { return raw_ptr()->token_pos_; }

  bool has_initializer() const { return raw_ptr()->has_initializer_; }
  void set_has_initializer(bool has_initializer) const {
    raw_ptr()->has_initializer_ = has_initializer;
  }

  // Constructs getter and setter names for fields and vice versa.
  static RawString* GetterName(const String& field_name);
  static RawString* GetterSymbol(const String& field_name);
  static RawString* SetterName(const String& field_name);
  static RawString* SetterSymbol(const String& field_name);
  static RawString* NameFromGetter(const String& getter_name);
  static RawString* NameFromSetter(const String& setter_name);
  static bool IsGetterName(const String& function_name);
  static bool IsSetterName(const String& function_name);

 private:
  void set_name(const String& value) const;
  void set_is_static(bool is_static) const {
    raw_ptr()->is_static_ = is_static;
  }
  void set_is_final(bool is_final) const {
    raw_ptr()->is_final_ = is_final;
  }
  void set_is_const(bool value) const {
    raw_ptr()->is_const_ = value;
  }
  void set_owner(const Class& value) const {
    StorePointer(&raw_ptr()->owner_, value.raw());
  }
  void set_token_pos(intptr_t token_pos) const {
    raw_ptr()->token_pos_ = token_pos;
  }
  static RawField* New();

  HEAP_OBJECT_IMPLEMENTATION(Field, Object);
  friend class Class;
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
  void set_kind(Token::Kind kind) const { raw_ptr()->kind_ = kind; }
  void set_literal(const String& literal) const;
  void set_value(const Object& value) const;

  HEAP_OBJECT_IMPLEMENTATION(LiteralToken, Object);
  friend class Class;
};


class TokenStream : public Object {
 public:
  inline intptr_t Length() const;

  RawArray* TokenObjects() const;
  void SetTokenObjects(const Array& value) const;

  RawString* GenerateSource() const;
  intptr_t ComputeSourcePosition(intptr_t tok_pos) const;
  intptr_t ComputeTokenPosition(intptr_t src_pos) const;

  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawTokenStream) == OFFSET_OF(RawTokenStream, data_));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawTokenStream) + (len * kBytesPerElement));
  }

  static RawTokenStream* New(intptr_t length);
  static RawTokenStream* New(const Scanner::GrowableTokenStream& tokens,
                             const String& private_key);

  // The class Iterator encapsulates iteration over the tokens
  // in a TokenStream object.
  class Iterator : ValueObject {
   public:
    Iterator(const TokenStream& tokens, intptr_t token_pos);

    bool IsValid() const;

    inline Token::Kind CurrentTokenKind() const {
      return cur_token_kind_;
    }

    Token::Kind LookaheadTokenKind(intptr_t num_tokens);

    intptr_t CurrentPosition() const;
    void SetCurrentPosition(intptr_t value);

    void Advance();

    RawObject* CurrentToken() const;
    RawString* CurrentLiteral() const;
    RawString* MakeLiteralToken(const Object& obj) const;

   private:
    // Read token from the token stream (could be a simple token or an index
    // into the token objects array for IDENT or literal tokens).
    intptr_t ReadToken();
    uint8_t ReadByte();

    const TokenStream& tokens_;
    Array& token_objects_;
    Object& obj_;
    intptr_t cur_token_pos_;
    intptr_t stream_token_pos_;
    Token::Kind cur_token_kind_;
    intptr_t cur_token_obj_index_;
  };

 private:
  void SetLength(intptr_t value) const;

  RawString* PrivateKey() const;
  void SetPrivateKey(const String& value) const;

  uint8_t* EntryAddr(intptr_t token_pos) const {
    ASSERT((token_pos >=0) && (token_pos < Length()));
    return &raw_ptr()->data_[token_pos];
  }

  HEAP_OBJECT_IMPLEMENTATION(TokenStream, Object);
  friend class Class;
};


class Script : public Object {
 public:
  RawString* url() const { return raw_ptr()->url_; }
  bool HasSource() const;
  RawString* Source() const;
  RawScript::Kind kind() const { return raw_ptr()->kind_; }

  RawTokenStream* tokens() const { return raw_ptr()->tokens_; }

  void Tokenize(const String& private_key) const;

  RawString* GetLine(intptr_t line_number) const;

  RawString* GetSnippet(intptr_t from_line,
                        intptr_t from_column,
                        intptr_t to_line,
                        intptr_t to_column) const;

  void GetTokenLocation(intptr_t token_pos,
                        intptr_t* line, intptr_t* column) const;

  void TokenRangeAtLine(intptr_t line_number,
                        intptr_t* first_token_index,
                        intptr_t* last_token_index) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawScript));
  }

  static RawScript* New(const String& url,
                        const String& source,
                        RawScript::Kind kind);

 private:
  void set_url(const String& value) const;
  void set_source(const String& value) const;
  void set_kind(RawScript::Kind value) const;
  void set_tokens(const TokenStream& value) const;
  static RawScript* New();

  HEAP_OBJECT_IMPLEMENTATION(Script, Object);
  friend class Class;
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
  int next_ix_;  // Index of next element.

  friend class ClassDictionaryIterator;
  friend class LibraryPrefixIterator;
  DISALLOW_COPY_AND_ASSIGN(DictionaryIterator);
};


class ClassDictionaryIterator : public DictionaryIterator {
 public:
  explicit ClassDictionaryIterator(const Library& library);

  // Returns a non-null raw class.
  RawClass* GetNextClass();

 private:
  void MoveToNextClass();

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
  bool LoadInProgress() const {
    return raw_ptr()->load_state_ == RawLibrary::kLoadInProgress;
  }
  void SetLoadInProgress() const;
  bool Loaded() const { return raw_ptr()->load_state_ == RawLibrary::kLoaded; }
  void SetLoaded() const;
  bool LoadError() const {
    return raw_ptr()->load_state_ == RawLibrary::kLoadError;
  }
  void SetLoadError() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawLibrary));
  }

  static RawLibrary* New(const String& url);

  // Library scope name dictionary.
  //
  // TODO(turnidge): The Lookup functions are not consistent in how
  // they deal with private names.  Go through and make them a bit
  // more regular.
  void AddClass(const Class& cls) const;
  void AddObject(const Object& obj, const String& name) const;
  void ReplaceObject(const Object& obj, const String& name) const;
  RawObject* LookupObject(const String& name) const;
  RawClass* LookupClass(const String& name) const;
  RawClass* LookupClassAllowPrivate(const String& name) const;
  RawObject* LookupLocalObject(const String& name) const;
  RawClass* LookupLocalClass(const String& name) const;
  RawField* LookupFieldAllowPrivate(const String& name) const;
  RawField* LookupLocalField(const String& name) const;
  RawFunction* LookupFunctionAllowPrivate(const String& name) const;
  RawFunction* LookupLocalFunction(const String& name) const;
  RawLibraryPrefix* LookupLocalLibraryPrefix(const String& name) const;
  RawScript* LookupScript(const String& url) const;
  RawArray* LoadedScripts() const;

  void AddAnonymousClass(const Class& cls) const;

  // Library imports.
  void AddImport(const Library& library) const;
  RawLibrary* LookupImport(const String& url) const;
  intptr_t num_imports() const { return raw_ptr()->num_imports_; }
  RawLibrary* ImportAt(intptr_t index) const;
  RawLibraryPrefix* ImportPrefixAt(intptr_t index) const;

  RawFunction* LookupFunctionInSource(const String& script_url,
                                      intptr_t line_number) const;
  RawFunction* LookupFunctionInScript(const Script& script,
                                      intptr_t token_pos) const;

  // Resolving native methods for script loaded in the library.
  Dart_NativeEntryResolver native_entry_resolver() const {
    return raw_ptr()->native_entry_resolver_;
  }
  void set_native_entry_resolver(Dart_NativeEntryResolver value) const {
    raw_ptr()->native_entry_resolver_ = value;
  }

  RawError* Patch(const String& url, const String& source) const;

  RawString* PrivateName(const String& name) const;

  intptr_t index() const { return raw_ptr()->index_; }
  void set_index(intptr_t value) const {
    raw_ptr()->index_ = value;
  }

  void Register() const;

  bool IsDebuggable() const {
    return raw_ptr()->debuggable_;
  }
  void set_debuggable(bool value) const {
    raw_ptr()->debuggable_ = value;
  }

  RawString* DuplicateDefineErrorString(const String& entry_name,
                                        const Library& conflicting_lib) const;
  static RawLibrary* LookupLibrary(const String& url);
  static RawLibrary* GetLibrary(intptr_t index);
  static RawString* CheckForDuplicateDefinition();
  static bool IsKeyUsed(intptr_t key);

  static void InitCoreLibrary(Isolate* isolate);
  static void InitMathLibrary(Isolate* isolate);
  static void InitIsolateLibrary(Isolate* isolate);
  static void InitMirrorsLibrary(Isolate* isolate);
  static RawLibrary* CoreLibrary();
  static RawLibrary* CoreImplLibrary();
  static RawLibrary* MathLibrary();
  static RawLibrary* IsolateLibrary();
  static RawLibrary* MirrorsLibrary();
  static void InitNativeWrappersLibrary(Isolate* isolate);
  static RawLibrary* NativeWrappersLibrary();

  // Eagerly compile all classes and functions in the library.
  static RawError* CompileAll();

 private:
  static const int kInitialImportsCapacity = 4;
  static const int kImportsCapacityIncrement = 8;
  static const int kInitialImportedIntoCapacity = 1;
  static const int kImportedIntoCapacityIncrement = 2;
  static RawLibrary* New();

  void set_num_imports(intptr_t value) const {
    raw_ptr()->num_imports_ = value;
  }
  intptr_t num_imported_into() const { return raw_ptr()->num_imported_into_; }
  void set_num_imported_into(intptr_t value) const {
    raw_ptr()->num_imported_into_ = value;
  }
  RawArray* imports() const { return raw_ptr()->imports_; }
  RawArray* imported_into() const { return raw_ptr()->imported_into_; }
  RawArray* loaded_scripts() const { return raw_ptr()->loaded_scripts_; }
  RawArray* dictionary() const { return raw_ptr()->dictionary_; }
  void InitClassDictionary() const;
  void InitImportList() const;
  void InitImportedIntoList() const;
  void GrowDictionary(const Array& dict, intptr_t dict_size) const;
  static RawLibrary* NewLibraryHelper(const String& url,
                                      bool import_core_lib);
  void AddImportedInto(const Library& library) const;
  RawObject* LookupEntry(const String& name, intptr_t *index) const;
  RawObject* LookupObjectFiltered(const String& name,
                                  const Library& filter_lib) const;
  RawLibrary* LookupObjectInImporter(const String& name) const;
  RawString* FindDuplicateDefinition() const;

  HEAP_OBJECT_IMPLEMENTATION(Library, Object);
  friend class Class;
  friend class Debugger;
  friend class DictionaryIterator;
  friend class Isolate;
};


class LibraryPrefix : public Object {
 public:
  RawString* name() const { return raw_ptr()->name_; }
  RawArray* libraries() const { return raw_ptr()->libraries_; }
  intptr_t num_libs() const { return raw_ptr()->num_libs_; }

  bool ContainsLibrary(const Library& library) const;
  RawLibrary* GetLibrary(int index) const;
  void AddLibrary(const Library& library) const;
  RawClass* LookupLocalClass(const String& class_name) const;
  RawString* CheckForDuplicateDefinition() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawLibraryPrefix));
  }

  static RawLibraryPrefix* New(const String& name, const Library& lib);

 private:
  static const int kInitialSize = 2;
  static const int kIncrementSize = 2;

  void set_name(const String& value) const;
  void set_libraries(const Array& value) const;
  void set_num_libs(intptr_t value) const;
  static RawLibraryPrefix* New();

  HEAP_OBJECT_IMPLEMENTATION(LibraryPrefix, Object);
  friend class Class;
  friend class Isolate;
};


class Instructions : public Object {
 public:
  intptr_t size() const { return raw_ptr()->size_; }
  RawCode* code() const { return raw_ptr()->code_; }

  uword EntryPoint() const {
    return reinterpret_cast<uword>(raw_ptr()) + HeaderSize();
  }

  static const intptr_t kMaxElements = (kIntptrMax -
                                        (sizeof(RawInstructions) +
                                         sizeof(RawObject) +
                                         (2 * OS::kMaxPreferredCodeAlignment)));

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawInstructions) == OFFSET_OF(RawInstructions, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t size) {
    intptr_t instructions_size = Utils::RoundUp(size,
                                                OS::PreferredCodeAlignment());
    intptr_t result = instructions_size + HeaderSize();
    ASSERT(result % OS::PreferredCodeAlignment() == 0);
    return result;
  }

  static intptr_t HeaderSize() {
    intptr_t alignment = OS::PreferredCodeAlignment();
    return Utils::RoundUp(sizeof(RawInstructions), alignment);
  }

  static RawInstructions* FromEntryPoint(uword entry_point) {
    return reinterpret_cast<RawInstructions*>(
        entry_point - HeaderSize() + kHeapObjectTag);
  }

 private:
  void set_size(intptr_t size) const {
    raw_ptr()->size_ = size;
  }
  void set_code(RawCode* code) {
    raw_ptr()->code_ = code;
  }

  // New is a private method as RawInstruction and RawCode objects should
  // only be created using the Code::FinalizeCode method. This method creates
  // the RawInstruction and RawCode objects, sets up the pointer offsets
  // and links the two in a GC safe manner.
  static RawInstructions* New(intptr_t size);

  HEAP_OBJECT_IMPLEMENTATION(Instructions, Object);
  friend class Class;
  friend class Code;
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
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawLocalVarDescriptors) ==
        OFFSET_OF(RawLocalVarDescriptors, data_));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawLocalVarDescriptors) + (len * kBytesPerElement));
  }

  static RawLocalVarDescriptors* New(intptr_t num_variables);

 private:
  HEAP_OBJECT_IMPLEMENTATION(LocalVarDescriptors, Object);
  friend class Class;
};


class PcDescriptors : public Object {
 private:
  // Describes the layout of PC descriptor data.
  enum {
    kPcEntry = 0,      // PC value of the descriptor, unique.
    kKindEntry = 1,
    kDeoptIdEntry = 2,      // Deopt id.
    kTokenPosEntry = 3,     // Token position in source.
    kDeoptReasonEntry = 3,  // DeoptReasonId.
    kTryIndexEntry = 4,     // Try block index.
    kDeoptIndexEntry = 4,   // Deoptimization array index.
    // We would potentially be adding other objects here like
    // pointer maps for optimized functions, local variables information  etc.
    kNumberOfEntries = 5,
  };

 public:
  enum Kind {
    kDeopt = 0,   // Deoptimization continuation point.
    kDeoptIndex,  // Index into deopt info array.
    kPatchCode,   // Buffer for patching code entry.
    kIcCall,      // IC call.
    kFuncCall,    // Call to known target, e.g. static call, closure call.
    kReturn,      // Return from function.
    kOther
  };

  intptr_t Length() const;

  uword PC(intptr_t index) const;
  PcDescriptors::Kind DescriptorKind(intptr_t index) const;
  const char* KindAsStr(intptr_t index) const;
  intptr_t DeoptId(intptr_t index) const;
  intptr_t TokenPos(intptr_t index) const;
  intptr_t TryIndex(intptr_t index) const;
  // Different encoding for kDeoptIndex.
  // Index into the deopt-info array of Code object.
  intptr_t DeoptIndex(intptr_t index) const;
  intptr_t DeoptReason(intptr_t index) const;

  void AddDescriptor(intptr_t index,
                     uword pc,
                     PcDescriptors::Kind kind,
                     intptr_t deopt_id,
                     intptr_t token_pos,  // Or deopt reason.
                     intptr_t try_index) const {  // Or deopt index.
    SetPC(index, pc);
    SetKind(index, kind);
    SetDeoptId(index, deopt_id);
    SetTokenPos(index, token_pos);
    SetTryIndex(index, try_index);
  }

  static const intptr_t kBytesPerElement = (kNumberOfEntries * kWordSize);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawPcDescriptors) == OFFSET_OF(RawPcDescriptors, data_));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawPcDescriptors) + (len * kBytesPerElement));
  }

  static RawPcDescriptors* New(intptr_t num_descriptors);

  // Verify (assert) assumptions about pc descriptors in debug mode.
  void Verify(bool check_ids) const;

  // We would have a VisitPointers function here to traverse the
  // pc descriptors table to visit objects if any in the table.

 private:
  void SetPC(intptr_t index, uword value) const;
  void SetKind(intptr_t index, PcDescriptors::Kind kind) const;
  void SetDeoptId(intptr_t index, intptr_t value) const;
  void SetTokenPos(intptr_t index, intptr_t value) const;
  void SetTryIndex(intptr_t index, intptr_t value) const;

  void SetLength(intptr_t value) const;

  intptr_t* EntryAddr(intptr_t index, intptr_t entry_offset) const {
    ASSERT((index >=0) && (index < Length()));
    intptr_t data_index = (index * kNumberOfEntries) + entry_offset;
    return &raw_ptr()->data_[data_index];
  }
  RawSmi** SmiAddr(intptr_t index, intptr_t entry_offset) const {
    return reinterpret_cast<RawSmi**>(EntryAddr(index, entry_offset));
  }

  HEAP_OBJECT_IMPLEMENTATION(PcDescriptors, Object);
  friend class Class;
};


class Stackmap : public Object {
 public:
  static const intptr_t kNoMaximum = -1;
  static const intptr_t kNoMinimum = -1;

  bool IsObject(intptr_t index) const {
    return InRange(index) && GetBit(index);
  }
  uword PC() const { return raw_ptr()->pc_; }
  void SetPC(uword value) const { raw_ptr()->pc_ = value; }

  RawCode* GetCode() const { return raw_ptr()->code_; }
  void SetCode(const Code& code) const;

  // Return the index of the highest stack slot that has an object.
  intptr_t MaximumBitIndex() const { return raw_ptr()->max_set_bit_index_; }

  // Return the index of the lowest stack slot that has an object.
  intptr_t MinimumBitIndex() const { return raw_ptr()->min_set_bit_index_; }

  static const intptr_t kBytesPerElement = kWordSize;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawStackmap) == OFFSET_OF(RawStackmap, data_));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawStackmap) + (len * kBytesPerElement));
  }
  static RawStackmap* New(uword pc, BitmapBuilder* bmap);

 private:
  inline intptr_t SizeInBits() const;

  void SetMinBitIndex(intptr_t value) const {
    raw_ptr()->min_set_bit_index_ = value;
  }
  void SetMaxBitIndex(intptr_t value) const {
    raw_ptr()->max_set_bit_index_ = value;
  }

  bool InRange(intptr_t index) const { return index < SizeInBits(); }

  bool GetBit(intptr_t bit_index) const;
  void SetBit(intptr_t bit_index, bool value) const;

  void set_bitmap_size_in_bytes(intptr_t value) const;

  HEAP_OBJECT_IMPLEMENTATION(Stackmap, Object);
  friend class BitmapBuilder;
  friend class Class;
};


class ExceptionHandlers : public Object {
 private:
  // Describes the layout of exception handler data.
  enum {
    kTryIndexEntry = 0,  // Try block index associated with handler.
    kHandlerPcEntry,  // PC value of handler.
    kNumberOfEntries
  };

 public:
  intptr_t Length() const;

  intptr_t TryIndex(intptr_t index) const;
  intptr_t HandlerPC(intptr_t index) const;

  void SetHandlerEntry(intptr_t index,
                       intptr_t try_index,
                       intptr_t handler_pc) const {
    SetTryIndex(index, try_index);
    SetHandlerPC(index, handler_pc);
  }

  static const intptr_t kBytesPerElement = (kNumberOfEntries * kWordSize);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawExceptionHandlers) == OFFSET_OF(RawExceptionHandlers,
                                                     data_));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawExceptionHandlers) + (len * kBytesPerElement));
  }

  static RawExceptionHandlers* New(intptr_t num_handlers);

  // We would have a VisitPointers function here to traverse the
  // exception handler table to visit objects if any in the table.

 private:
  void SetTryIndex(intptr_t index, intptr_t value) const;
  void SetHandlerPC(intptr_t index, intptr_t value) const;

  void SetLength(intptr_t value) const;

  intptr_t* EntryAddr(intptr_t index, intptr_t entry_offset) const {
    ASSERT((index >=0) && (index < Length()));
    intptr_t data_index = (index * kNumberOfEntries) + entry_offset;
    return &raw_ptr()->data_[data_index];
  }

  HEAP_OBJECT_IMPLEMENTATION(ExceptionHandlers, Object);
  friend class Class;
};


// Holds deopt information at one deoptimization point. The information
// is a list of DeoptInstr objects, specifying transformation information
// for each slot in unoptimized frame(s).
class DeoptInfo : public Object {
 private:
  // Describes the layout of deopt info data. The index of a deopt-info entry
  // is implicitly the target slot in which the value is written into.
  enum {
    kInstruction = 0,
    kFromIndex,
    kNumberOfEntries,
  };

 public:
  intptr_t Length() const;

  static RawDeoptInfo* New(intptr_t num_commands);

  static const intptr_t kBytesPerElement = (kNumberOfEntries * kWordSize);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawDeoptInfo) == OFFSET_OF(RawDeoptInfo, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawDeoptInfo) +
                                 (len * kBytesPerElement));
  }

  // 'index' corresponds to target, to-index.
  void SetAt(intptr_t index,
             intptr_t instr_kind,
             intptr_t from_index) const;

  intptr_t Instruction(intptr_t index) const;
  intptr_t FromIndex(intptr_t index) const;
  intptr_t ToIndex(intptr_t index) const {
    return index;
  }

 private:
  intptr_t* EntryAddr(intptr_t index, intptr_t entry_offset) const {
    ASSERT((index >=0) && (index < Length()));
    intptr_t data_index = (index * kNumberOfEntries) + entry_offset;
    return &raw_ptr()->data_[data_index];
  }

  void SetLength(intptr_t value) const;

  HEAP_OBJECT_IMPLEMENTATION(DeoptInfo, Object);
  friend class Class;
};


class Code : public Object {
 public:
  RawInstructions* instructions() const { return raw_ptr()->instructions_; }
  static intptr_t instructions_offset() {
    return OFFSET_OF(RawCode, instructions_);
  }
  intptr_t pointer_offsets_length() const {
    return raw_ptr()->pointer_offsets_length_;
  }
  bool is_optimized() const {
    return (raw_ptr()->is_optimized_ == 1);
  }
  void set_is_optimized(bool value) const {
    raw_ptr()->is_optimized_ = value ? 1 : 0;
  }
  uword EntryPoint() const {
    const Instructions& instr = Instructions::Handle(instructions());
    return instr.EntryPoint();
  }
  intptr_t Size() const {
    const Instructions& instr = Instructions::Handle(instructions());
    return instr.size();
  }

  RawPcDescriptors* pc_descriptors() const {
    return raw_ptr()->pc_descriptors_;
  }
  void set_pc_descriptors(const PcDescriptors& descriptors) const {
    StorePointer(&raw_ptr()->pc_descriptors_, descriptors.raw());
  }

  // Array of DeoptInfo objects.
  RawArray* deopt_info_array() const {
    return raw_ptr()->deopt_info_array_;
  }
  void set_deopt_info_array(const Array& array) const;

  RawArray* object_table() const {
    return raw_ptr()->object_table_;
  }
  void set_object_table(const Array& array) const;

  RawArray* stackmaps() const {
    return raw_ptr()->stackmaps_;
  }
  void set_stackmaps(const Array& maps) const;
  RawStackmap* GetStackmap(uword pc, Array* stackmaps, Stackmap* map) const;

  class Comments : public ZoneAllocated {
   public:
    static Comments& New(intptr_t count);

    intptr_t Length() const;

    void SetPCOffsetAt(intptr_t idx, intptr_t pc_offset);
    void SetCommentAt(intptr_t idx, const String& comment);

    intptr_t PCOffsetAt(intptr_t idx) const;
    const String& CommentAt(intptr_t idx) const;

   private:
    explicit Comments(RawArray* comments);

    // Layout of entries describing comments.
    enum {
      kPCOffsetEntry = 0,  // PC offset to a comment as a Smi.
      kCommentEntry,  // Comment text as a String.
      kNumberOfEntries
    };

    const Array& comments_;

    friend class Code;

    DISALLOW_COPY_AND_ASSIGN(Comments);
  };


  const Comments& comments() const;
  void set_comments(const Comments& comments) const;

  RawLocalVarDescriptors* var_descriptors() const {
    return raw_ptr()->var_descriptors_;
  }
  void set_var_descriptors(const LocalVarDescriptors& value) const {
    StorePointer(&raw_ptr()->var_descriptors_, value.raw());
  }

  RawExceptionHandlers* exception_handlers() const {
    return raw_ptr()->exception_handlers_;
  }
  void set_exception_handlers(const ExceptionHandlers& handlers) const {
    StorePointer(&raw_ptr()->exception_handlers_, handlers.raw());
  }

  RawFunction* function() const {
    return raw_ptr()->function_;
  }
  void set_function(const Function& function) const {
    StorePointer(&raw_ptr()->function_, function.raw());
  }

  // We would have a VisitPointers function here to traverse all the
  // embedded objects in the instructions using pointer_offsets.

  static const intptr_t kBytesPerElement =
      sizeof(reinterpret_cast<RawCode*>(0)->data_[0]);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawCode) == OFFSET_OF(RawCode, data_));
    return 0;
  }
  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawCode) + (len * kBytesPerElement));
  }
  static RawCode* FinalizeCode(const Function& function, Assembler* assembler);
  static RawCode* FinalizeCode(const char* name, Assembler* assembler);
  static RawCode* LookupCode(uword pc);

  int32_t GetPointerOffsetAt(int index) const {
    return *PointerOffsetAddrAt(index);
  }
  intptr_t GetTokenIndexOfPC(uword pc) const;

  // Find pc of patch code buffer. Return 0 if not found.
  uword GetPatchCodePc() const;

  uword GetDeoptPcAtDeoptId(intptr_t deopt_id) const;

  // Returns true if there is an object in the code between 'start_offset'
  // (inclusive) and 'end_offset' (exclusive).
  bool ObjectExistsInArea(intptr_t start_offest, intptr_t end_offset) const;

  // Each (*node_ids)[n] has a an extracted ic data array (*arrays)[n].
  // Returns the maximum id found.
  intptr_t ExtractIcDataArraysAtCalls(
      GrowableArray<intptr_t>* node_ids,
      const GrowableObjectArray& ic_data_objs) const;

 private:
  // An object finder visitor interface.
  class FindRawCodeVisitor : public FindObjectVisitor {
   public:
    explicit FindRawCodeVisitor(uword pc)
        : FindObjectVisitor(Isolate::Current()), pc_(pc) { }
    virtual ~FindRawCodeVisitor() { }

    // Check if object matches find condition.
    virtual bool FindObject(RawObject* obj);

   private:
    const uword pc_;

    DISALLOW_COPY_AND_ASSIGN(FindRawCodeVisitor);
  };

  static const intptr_t kEntrySize = sizeof(int32_t);  // NOLINT

  void set_instructions(RawInstructions* instructions) {
    raw_ptr()->instructions_ = instructions;
  }
  void set_pointer_offsets_length(intptr_t value) {
    ASSERT(value >= 0);
    raw_ptr()->pointer_offsets_length_ = value;
  }
  int32_t* PointerOffsetAddrAt(int index) const {
    ASSERT(index >= 0);
    ASSERT(index < pointer_offsets_length());
    // TODO(iposva): Unit test is missing for this functionality.
    return &raw_ptr()->data_[index];
  }
  void SetPointerOffsetAt(int index, int32_t offset_in_instructions) {
    *PointerOffsetAddrAt(index) = offset_in_instructions;
  }

  // New is a private method as RawInstruction and RawCode objects should
  // only be created using the Code::FinalizeCode method. This method creates
  // the RawInstruction and RawCode objects, sets up the pointer offsets
  // and links the two in a GC safe manner.
  static RawCode* New(intptr_t pointer_offsets_length);

  HEAP_OBJECT_IMPLEMENTATION(Code, Object);
  friend class Class;
};


class Context : public Object {
 public:
  RawContext* parent() const { return raw_ptr()->parent_; }
  void set_parent(const Context& parent) const {
    ASSERT(parent.IsNull() || parent.isolate() == Isolate::Current());
    StorePointer(&raw_ptr()->parent_, parent.raw());
  }
  static intptr_t parent_offset() { return OFFSET_OF(RawContext, parent_); }

  Isolate* isolate() const { return raw_ptr()->isolate_; }
  static intptr_t isolate_offset() { return OFFSET_OF(RawContext, isolate_); }

  intptr_t num_variables() const { return raw_ptr()->num_variables_; }
  static intptr_t num_variables_offset() {
    return OFFSET_OF(RawContext, num_variables_);
  }

  RawInstance* At(intptr_t context_index) const {
    return *InstanceAddr(context_index);
  }
  inline void SetAt(intptr_t context_index, const Instance& value) const;

  static const intptr_t kBytesPerElement = kWordSize;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t variable_offset(intptr_t context_index) {
    return OFFSET_OF(RawContext, data_[context_index]);
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawContext) == OFFSET_OF(RawContext, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawContext) + (len * kBytesPerElement));
  }

  static RawContext* New(intptr_t num_variables,
                         Heap::Space space = Heap::kNew);

 private:
  RawInstance** InstanceAddr(intptr_t context_index) const {
    ASSERT((context_index >= 0) && (context_index < num_variables()));
    return &raw_ptr()->data_[context_index];
  }

  void set_isolate(Isolate* isolate) const {
    raw_ptr()->isolate_ = isolate;
  }

  void set_num_variables(intptr_t num_variables) const {
    raw_ptr()->num_variables_ = num_variables;
  }

  HEAP_OBJECT_IMPLEMENTATION(Context, Object);
  friend class Class;
};


// The ContextScope class makes it possible to delay the compilation of a local
// function until it is invoked. A ContextScope instance collects the local
// variables that are referenced by the local function to be compiled and that
// belong to the outer scopes, that is, to the local scopes of (possibly nested)
// functions enclosing the local function. Each captured variable is represented
// by its token position in the source, its name, its type, its allocation index
// in the context, and its context level. The function nesting level and loop
// nesting level are not preserved, since they are only used until the context
// level is assigned.
class ContextScope : public Object {
 public:
  intptr_t num_variables() const { return raw_ptr()->num_variables_; }

  intptr_t TokenIndexAt(intptr_t scope_index) const;
  void SetTokenIndexAt(intptr_t scope_index, intptr_t token_pos) const;

  RawString* NameAt(intptr_t scope_index) const;
  void SetNameAt(intptr_t scope_index, const String& name) const;

  bool IsFinalAt(intptr_t scope_index) const;
  void SetIsFinalAt(intptr_t scope_index, bool is_const) const;

  RawAbstractType* TypeAt(intptr_t scope_index) const;
  void SetTypeAt(intptr_t scope_index, const AbstractType& type) const;

  intptr_t ContextIndexAt(intptr_t scope_index) const;
  void SetContextIndexAt(intptr_t scope_index, intptr_t context_index) const;

  intptr_t ContextLevelAt(intptr_t scope_index) const;
  void SetContextLevelAt(intptr_t scope_index, intptr_t context_level) const;

  static const intptr_t kBytesPerElement =
      sizeof(RawContextScope::VariableDesc);
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawContextScope) == OFFSET_OF(RawContextScope, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawContextScope) + (len * kBytesPerElement));
  }

  static RawContextScope* New(intptr_t num_variables);

 private:
  void set_num_variables(intptr_t num_variables) const {
    raw_ptr()->num_variables_ = num_variables;
  }

  RawContextScope::VariableDesc* VariableDescAddr(intptr_t index) const {
    ASSERT((index >= 0) && (index < num_variables()));
    uword raw_addr = reinterpret_cast<uword>(raw_ptr());
    raw_addr += sizeof(RawContextScope) +
        (index * sizeof(RawContextScope::VariableDesc));
    return reinterpret_cast<RawContextScope::VariableDesc*>(raw_addr);
  }

  HEAP_OBJECT_IMPLEMENTATION(ContextScope, Object);
  friend class Class;
};


// Object holding information about an IC: test classes and their
// corresponding targets.
class ICData : public Object {
 public:
  RawFunction* function() const {
    return raw_ptr()->function_;
  }

  RawString* target_name() const {
    return raw_ptr()->target_name_;
  }

  intptr_t num_args_tested() const {
    return raw_ptr()->num_args_tested_;
  }

  intptr_t deopt_id() const {
    return raw_ptr()->deopt_id_;
  }

  intptr_t NumberOfChecks() const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawICData));
  }

  static intptr_t target_name_offset() {
    return OFFSET_OF(RawICData, target_name_);
  }

  static intptr_t num_args_tested_offset() {
    return OFFSET_OF(RawICData, num_args_tested_);
  }

  static intptr_t ic_data_offset() {
    return OFFSET_OF(RawICData, ic_data_);
  }

  static intptr_t function_offset() {
    return OFFSET_OF(RawICData, function_);
  }

  // Adds one more class test to ICData. Length of 'classes' must be equal to
  // the number of arguments tested. Use only for num_args_tested > 1.
  void AddCheck(const GrowableArray<intptr_t>& class_ids,
                const Function& target) const;
  // Adds sorted so that Smi is the first class-id. Use only for
  // num_args_tested == 1.
  void AddReceiverCheck(intptr_t receiver_class_id,
                        const Function& target) const;
  void GetCheckAt(intptr_t index,
                  GrowableArray<intptr_t>* class_ids,
                  Function* target) const;
  void GetOneClassCheckAt(
      int index, intptr_t* class_id, Function* target) const;

  intptr_t GetReceiverClassIdAt(intptr_t index) const;
  RawFunction* GetTargetAt(intptr_t index) const;
  RawFunction* GetTargetForReceiverClassId(intptr_t class_id) const;

  // Returns this->raw() if num_args_tested == 1, otherwise returns a new
  // ICData object containing only unique arg0 checks.
  RawICData* AsUnaryClassChecks() const;

  static RawICData* New(const Function& caller_function,
                        const String& target_name,
                        intptr_t deopt_id,
                        intptr_t num_args_tested);

 private:
  RawArray* ic_data() const {
    return raw_ptr()->ic_data_;
  }

  void set_function(const Function& value) const;
  void set_target_name(const String& value) const;
  void set_deopt_id(intptr_t value) const;
  void set_num_args_tested(intptr_t value) const;
  void set_ic_data(const Array& value) const;

  intptr_t TestEntryLength() const;
  void WriteSentinel() const;

  HEAP_OBJECT_IMPLEMENTATION(ICData, Object);
  friend class Class;
};


class SubtypeTestCache : public Object {
 public:
  enum Entries {
    kInstanceClassId = 0,
    kInstanceTypeArguments = 1,
    kInstantiatorTypeArguments = 2,
    kTestResult = 3,
    kTestEntryLength  = 4,
  };

  intptr_t NumberOfChecks() const;
  void AddCheck(intptr_t class_id,
                const AbstractTypeArguments& instance_type_arguments,
                const AbstractTypeArguments& instantiator_type_arguments,
                const Bool& test_result) const;
  void GetCheck(intptr_t ix,
                intptr_t* class_id,
                AbstractTypeArguments* instance_type_arguments,
                AbstractTypeArguments* instantiator_type_arguments,
                Bool* test_result) const;

  static RawSubtypeTestCache* New();

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawSubtypeTestCache));
  }

  static intptr_t cache_offset() {
    return OFFSET_OF(RawSubtypeTestCache, cache_);
  }

 private:
  RawArray* cache() const {
    return raw_ptr()->cache_;
  }

  void set_cache(const Array& value) const;

  intptr_t TestEntryLength() const;

  HEAP_OBJECT_IMPLEMENTATION(SubtypeTestCache, Object);
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
  static intptr_t message_offset() {
    return OFFSET_OF(RawApiError, message_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawApiError));
  }

  static RawApiError* New(const String& message,
                          Heap::Space space = Heap::kNew);

  virtual const char* ToErrorCString() const;

 private:
  void set_message(const String& message) const;

  HEAP_OBJECT_IMPLEMENTATION(ApiError, Error);
  friend class Class;
};


class LanguageError : public Error {
 public:
  RawString* message() const { return raw_ptr()->message_; }
  static intptr_t message_offset() {
    return OFFSET_OF(RawLanguageError, message_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawLanguageError));
  }

  static RawLanguageError* New(const String& message,
                               Heap::Space space = Heap::kNew);

  virtual const char* ToErrorCString() const;

 private:
  void set_message(const String& message) const;

  HEAP_OBJECT_IMPLEMENTATION(LanguageError, Error);
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
  void set_exception(const Instance& exception) const;
  void set_stacktrace(const Instance& stacktrace) const;

  HEAP_OBJECT_IMPLEMENTATION(UnhandledException, Error);
  friend class Class;
};


class UnwindError : public Error {
 public:
  RawString* message() const { return raw_ptr()->message_; }
  static intptr_t message_offset() {
    return OFFSET_OF(RawUnwindError, message_);
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawUnwindError));
  }

  static RawUnwindError* New(const String& message,
                             Heap::Space space = Heap::kNew);

  virtual const char* ToErrorCString() const;

 private:
  void set_message(const String& message) const;

  HEAP_OBJECT_IMPLEMENTATION(UnwindError, Error);
  friend class Class;
};


// Instance is the base class for all instance objects (aka the Object class
// in Dart source code.
class Instance : public Object {
 public:
  virtual bool Equals(const Instance& other) const;
  virtual RawInstance* Canonicalize() const;

  RawObject* GetField(const Field& field) const {
    return *FieldAddr(field);
  }

  void SetField(const Field& field, const Object& value) const {
    StorePointer(FieldAddr(field), value.raw());
  }

  RawType* GetType() const;

  virtual RawAbstractTypeArguments* GetTypeArguments() const;
  virtual void SetTypeArguments(const AbstractTypeArguments& value) const;

  // Check if the type of this instance is a subtype of the given type.
  bool IsInstanceOf(const AbstractType& type,
                    const AbstractTypeArguments& type_instantiator,
                    Error* malformed_error) const;

  bool IsValidNativeIndex(int index) const;

  intptr_t GetNativeField(int index) const {
    return *NativeFieldAddr(index);
  }

  void SetNativeField(int index, intptr_t value) const {
    *NativeFieldAddr(index) = value;
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawInstance));
  }

  static RawInstance* New(const Class& cls, Heap::Space space = Heap::kNew);

 private:
  RawObject** FieldAddrAtOffset(intptr_t offset) const {
    ASSERT(IsValidFieldOffset(offset));
    return reinterpret_cast<RawObject**>(raw_value() - kHeapObjectTag + offset);
  }
  RawObject** FieldAddr(const Field& field) const {
    return FieldAddrAtOffset(field.Offset());
  }
  intptr_t* NativeFieldAddr(int index) const {
    ASSERT(IsValidNativeIndex(index));
    return reinterpret_cast<intptr_t*>((raw_value() - kHeapObjectTag)
                                       + (index * kWordSize)
                                       + sizeof(RawObject));
  }
  void SetFieldAtOffset(intptr_t offset, const Object& value) const {
    StorePointer(FieldAddrAtOffset(offset), value.raw());
  }
  bool IsValidFieldOffset(int offset) const;

  // TODO(iposva): Determine if this gets in the way of Smi.
  HEAP_OBJECT_IMPLEMENTATION(Instance, Object);
  friend class Class;
};


class Number : public Instance {
 public:
  // TODO(iposva): Fill in a useful Number interface.
  virtual bool IsZero() const {
    // Number is an abstract class.
    UNREACHABLE();
    return false;
  }
  virtual bool IsNegative() const {
    // Number is an abstract class.
    UNREACHABLE();
    return false;
  }
  OBJECT_IMPLEMENTATION(Number, Instance);
};


class Integer : public Number {
 public:
  static RawInteger* New(const String& str, Heap::Space space = Heap::kNew);
  static RawInteger* New(int64_t value, Heap::Space space = Heap::kNew);

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;

  // Returns 0, -1 or 1.
  virtual int CompareWith(const Integer& other) const;

  OBJECT_IMPLEMENTATION(Integer, Number);
  friend class Class;
};


class Smi : public Integer {
 public:
  static const intptr_t kBits = kSmiBits;
  static const intptr_t kMaxValue = kSmiMax;
  static const intptr_t kMinValue =  kSmiMin;

  intptr_t Value() const {
    return ValueFromRaw(raw_value());
  }

  virtual bool Equals(const Instance& other) const;
  virtual bool IsZero() const { return Value() == 0; }
  virtual bool IsNegative() const { return Value() < 0; }
  // Smi values are implicitly canonicalized.
  virtual RawInstance* Canonicalize() const {
    return reinterpret_cast<RawSmi*>(raw_value());
  }

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;

  virtual int CompareWith(const Integer& other) const;

  static intptr_t InstanceSize() { return 0; }

  static RawSmi* New(intptr_t value) {
    word raw_smi = (value << kSmiTagShift) | kSmiTag;
    ASSERT(ValueFromRaw(raw_smi) == value);
    return reinterpret_cast<RawSmi*>(raw_smi);
  }

  static RawClass* Class();

  static intptr_t Value(const RawSmi* raw_smi) {
    return ValueFromRaw(reinterpret_cast<uword>(raw_smi));
  }

  static intptr_t RawValue(intptr_t value) {
    return reinterpret_cast<intptr_t>(New(value));
  }

  static bool IsValid(intptr_t value) {
    return (value >= kMinValue) && (value <= kMaxValue);
  }

  static bool IsValid64(int64_t value) {
    return (value >= kMinValue) && (value <= kMaxValue);
  }

 private:
  static intptr_t ValueFromRaw(uword raw_value) {
    intptr_t value = raw_value;
    ASSERT((value & kSmiTagMask) == kSmiTag);
    return (value >> kSmiTagShift);
  }
  static cpp_vtable handle_vtable_;

  OBJECT_IMPLEMENTATION(Smi, Integer);
  friend class Api;  // For ValueFromRaw
  friend class Class;
  friend class Object;
};


class Mint : public Integer {
 public:
  static const intptr_t kBits = 63;  // 64-th bit is sign.
  static const int64_t kMaxValue =
      static_cast<int64_t>(DART_2PART_UINT64_C(0x7FFFFFFF, FFFFFFFF));
  static const int64_t kMinValue =
      static_cast<int64_t>(DART_2PART_UINT64_C(0x80000000, 00000000));

  int64_t value() const {
    return raw_ptr()->value_;
  }
  static intptr_t value_offset() { return OFFSET_OF(RawMint, value_); }

  virtual bool IsZero() const {
    return value() == 0;
  }
  virtual bool IsNegative() const {
    return value() < 0;
  }

  virtual bool Equals(const Instance& other) const;

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;

  virtual int CompareWith(const Integer& other) const;

  static RawMint* New(int64_t value, Heap::Space space = Heap::kNew);
  static RawMint* NewCanonical(int64_t value);

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawMint));
  }

 private:
  void set_value(int64_t value) const;

  HEAP_OBJECT_IMPLEMENTATION(Mint, Integer);
  friend class Class;
};


class Bigint : public Integer {
 private:
  typedef uint32_t Chunk;
  typedef uint64_t DoubleChunk;
  static const int kChunkSize = sizeof(Chunk);

 public:
  virtual bool IsZero() const { return raw_ptr()->signed_length_ == 0; }
  virtual bool IsNegative() const { return raw_ptr()->signed_length_ < 0; }

  virtual bool Equals(const Instance& other) const;

  virtual double AsDoubleValue() const;
  virtual int64_t AsInt64Value() const;

  virtual int CompareWith(const Integer& other) const;

  static const intptr_t kBytesPerElement = kChunkSize;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() { return 0; }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawBigint) + (len * kBytesPerElement));
  }

  static RawBigint* New(const String& str, Heap::Space space = Heap::kNew);
  static RawBigint* New(int64_t value, Heap::Space space = Heap::kNew);

 private:
  Chunk GetChunkAt(intptr_t i) const {
    return *ChunkAddr(i);
  }

  void SetChunkAt(intptr_t i, Chunk newValue) const {
    *ChunkAddr(i) = newValue;
  }

  // Returns the number of chunks in use.
  intptr_t Length() const {
    intptr_t signed_length = raw_ptr()->signed_length_;
    return Utils::Abs(signed_length);
  }

  // SetLength does not change the sign.
  void SetLength(intptr_t length) const {
    ASSERT(length >= 0);
    bool is_negative = IsNegative();
    raw_ptr()->signed_length_ = length;
    if (is_negative) ToggleSign();
  }

  void SetSign(bool is_negative) const {
    if (is_negative != IsNegative()) {
      ToggleSign();
    }
  }

  void ToggleSign() const {
    raw_ptr()->signed_length_ = -raw_ptr()->signed_length_;
  }

  Chunk* ChunkAddr(intptr_t index) const {
    ASSERT(0 <= index);
    ASSERT(index < Length());
    uword digits_start = reinterpret_cast<uword>(raw_ptr()) + sizeof(RawBigint);
    return &(reinterpret_cast<Chunk*>(digits_start)[index]);
  }

  static RawBigint* Allocate(intptr_t length, Heap::Space space = Heap::kNew);

  HEAP_OBJECT_IMPLEMENTATION(Bigint, Integer);
  friend class BigintOperations;
  friend class Class;
};


class Double : public Number {
 public:
  double value() const {
    return raw_ptr()->value_;
  }

  bool EqualsToDouble(double value) const;
  virtual bool Equals(const Instance& other) const;

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

  HEAP_OBJECT_IMPLEMENTATION(Double, Number);
  friend class Class;
};


// String may not be '\0' terminated.
class String : public Instance {
 public:
  // We use 30 bits for the hash code so that we consistently use a
  // 32bit Smi representation for the hash code on all architectures.
  static const intptr_t kHashBits = 30;

  static const intptr_t kOneByteChar = 1;
  static const intptr_t kTwoByteChar = 2;
  static const intptr_t kFourByteChar = 4;

  // All strings share the same maximum element count to keep things
  // simple.  We choose a value that will prevent integer overflow for
  // 4 byte strings, since it is the worst case.
  static const intptr_t kSizeofRawString = sizeof(RawObject) + (2 * kWordSize);
  static const intptr_t kMaxElements = kSmiMax / kFourByteChar;

  intptr_t Length() const { return Smi::Value(raw_ptr()->length_); }
  static intptr_t length_offset() { return OFFSET_OF(RawString, length_); }

  virtual intptr_t Hash() const;
  static intptr_t hash_offset() { return OFFSET_OF(RawString, hash_); }
  static intptr_t Hash(const String& str, intptr_t begin_index, intptr_t len);
  static intptr_t Hash(const uint8_t* characters, intptr_t len);
  static intptr_t Hash(const uint16_t* characters, intptr_t len);
  static intptr_t Hash(const uint32_t* characters, intptr_t len);

  virtual int32_t CharAt(intptr_t index) const;

  virtual intptr_t CharSize() const;

  inline bool Equals(const String& str) const;
  inline bool Equals(const String& str,
                     intptr_t begin_index,  // begin index on 'str'.
                     intptr_t len) const;  // len on 'str'.
  bool Equals(const char* str) const;
  bool Equals(const uint8_t* characters, intptr_t len) const;
  bool Equals(const uint16_t* characters, intptr_t len) const;
  bool Equals(const uint32_t* characters, intptr_t len) const;

  virtual bool Equals(const Instance& other) const;

  intptr_t CompareTo(const String& other) const;

  bool StartsWith(const String& other) const;

  virtual RawInstance* Canonicalize() const;

  bool IsSymbol() const { return raw()->IsCanonical(); }

  virtual bool IsExternal() const { return false; }
  virtual void* GetPeer() const {
    UNREACHABLE();
    return NULL;
  }

  static RawString* New(const char* str, Heap::Space space = Heap::kNew);
  static RawString* New(const uint8_t* characters,
                        intptr_t len,
                        Heap::Space space = Heap::kNew);
  static RawString* New(const uint16_t* characters,
                        intptr_t len,
                        Heap::Space space = Heap::kNew);
  static RawString* New(const uint32_t* characters,
                        intptr_t len,
                        Heap::Space space = Heap::kNew);
  static RawString* New(const String& str, Heap::Space space = Heap::kNew);

  static RawString* NewExternal(const uint8_t* characters,
                                intptr_t len,
                                void* peer,
                                Dart_PeerFinalizer callback,
                                Heap::Space = Heap::kNew);
  static RawString* NewExternal(const uint16_t* characters,
                                intptr_t len,
                                void* peer,
                                Dart_PeerFinalizer callback,
                                Heap::Space = Heap::kNew);
  static RawString* NewExternal(const uint32_t* characters,
                                intptr_t len,
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
                   const uint32_t* characters,
                   intptr_t len);
  static void Copy(const String& dst,
                   intptr_t dst_offset,
                   const String& src,
                   intptr_t src_offset,
                   intptr_t len);

  static RawString* EscapeDoubleQuotes(const String& str);

  static RawString* Concat(const String& str1,
                           const String& str2,
                           Heap::Space space = Heap::kNew);
  static RawString* ConcatAll(const Array& strings,
                              Heap::Space space = Heap::kNew);

  static RawString* SubString(const String& str,
                              intptr_t begin_index,
                              Heap::Space space = Heap::kNew);
  static RawString* SubString(const String& str,
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

  static RawString* NewFormatted(const char* format, ...);

 protected:
  bool HasHash() const {
    ASSERT(Smi::New(0) == NULL);
    return (raw_ptr()->hash_ != NULL);
  }

  void SetLength(intptr_t value) const {
    // This is only safe because we create a new Smi, which does not cause
    // heap allocation.
    raw_ptr()->length_ = Smi::New(value);
  }

  void SetHash(intptr_t value) const {
    // This is only safe because we create a new Smi, which does not cause
    // heap allocation.
    raw_ptr()->hash_ = Smi::New(value);
  }

  template<typename HandleType, typename ElementType>
  static void ReadFromImpl(SnapshotReader* reader,
                           HandleType* str_obj,
                           intptr_t len,
                           intptr_t tags);

  HEAP_OBJECT_IMPLEMENTATION(String, Instance);

  friend class Symbols;
};


class OneByteString : public String {
 public:
  virtual int32_t CharAt(intptr_t index) const {
    return *CharAddr(index);
  }

  virtual intptr_t CharSize() const {
    return kOneByteChar;
  }

  RawOneByteString* EscapeDoubleQuotes() const;

  bool EqualsIgnoringPrivateKey(const OneByteString& str) const;

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t data_offset() { return OFFSET_OF(RawOneByteString, data_); }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawOneByteString) == OFFSET_OF(RawOneByteString, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(sizeof(RawOneByteString) == kSizeofRawString);
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawOneByteString) + (len * kBytesPerElement));
  }

  static RawOneByteString* New(intptr_t len,
                               Heap::Space space);
  static RawOneByteString* New(const char* c_string,
                               Heap::Space space = Heap::kNew) {
    return New(reinterpret_cast<const uint8_t*>(c_string),
               strlen(c_string),
               space);
  }
  static RawOneByteString* New(const uint8_t* characters,
                               intptr_t len,
                               Heap::Space space);
  static RawOneByteString* New(const uint16_t* characters,
                               intptr_t len,
                               Heap::Space space);
  static RawOneByteString* New(const uint32_t* characters,
                               intptr_t len,
                               Heap::Space space);
  static RawOneByteString* New(const OneByteString& str,
                               Heap::Space space);

  static RawOneByteString* Concat(const String& str1,
                                  const String& str2,
                                  Heap::Space space);
  static RawOneByteString* ConcatAll(const Array& strings,
                                     intptr_t len,
                                     Heap::Space space);

  static RawOneByteString* Transform(int32_t (*mapping)(int32_t ch),
                                     const String& str,
                                     Heap::Space space);

 private:
  uint8_t* CharAddr(intptr_t index) const {
    // TODO(iposva): Determine if we should throw an exception here.
    ASSERT((index >= 0) && (index < Length()));
    return &raw_ptr()->data_[index];
  }

  HEAP_OBJECT_IMPLEMENTATION(OneByteString, String);
  friend class Class;
  friend class String;
};


class TwoByteString : public String {
 public:
  virtual int32_t CharAt(intptr_t index) const {
    return *CharAddr(index);
  }

  virtual intptr_t CharSize() const {
    return kTwoByteChar;
  }

  RawTwoByteString* EscapeDoubleQuotes() const;

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 2;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawTwoByteString) == OFFSET_OF(RawTwoByteString, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(sizeof(RawTwoByteString) == kSizeofRawString);
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawTwoByteString) + (len * kBytesPerElement));
  }

  static RawTwoByteString* New(intptr_t len,
                               Heap::Space space);
  static RawTwoByteString* New(const uint16_t* characters,
                               intptr_t len,
                               Heap::Space space);
  static RawTwoByteString* New(const uint32_t* characters,
                               intptr_t len,
                               Heap::Space space);
  static RawTwoByteString* New(const TwoByteString& str,
                               Heap::Space space);

  static RawTwoByteString* Concat(const String& str1,
                                  const String& str2,
                                  Heap::Space space);
  static RawTwoByteString* ConcatAll(const Array& strings,
                                     intptr_t len,
                                     Heap::Space space);

  static RawTwoByteString* Transform(int32_t (*mapping)(int32_t ch),
                                     const String& str,
                                     Heap::Space space);

 private:
  uint16_t* CharAddr(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return &raw_ptr()->data_[index];
  }

  HEAP_OBJECT_IMPLEMENTATION(TwoByteString, String);
  friend class Class;
  friend class String;
};


class FourByteString : public String {
 public:
  virtual int32_t CharAt(intptr_t index) const {
    return *CharAddr(index);
  }

  virtual intptr_t CharSize() const {
    return kFourByteChar;
  }

  RawFourByteString* EscapeDoubleQuotes() const;

  static const intptr_t kBytesPerElement = 4;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawFourByteString) == OFFSET_OF(RawFourByteString, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(sizeof(RawTwoByteString) == kSizeofRawString);
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawFourByteString) + (len * kBytesPerElement));
  }

  static RawFourByteString* New(intptr_t len,
                                Heap::Space space);
  static RawFourByteString* New(const uint32_t* characters,
                                intptr_t len,
                                Heap::Space space);
  static RawFourByteString* New(const FourByteString& str,
                                Heap::Space space);

  static RawFourByteString* Concat(const String& str1,
                                   const String& str2,
                                   Heap::Space space);
  static RawFourByteString* ConcatAll(const Array& strings,
                                      intptr_t len,
                                      Heap::Space space);

  static RawFourByteString* Transform(int32_t (*mapping)(int32_t ch),
                                      const String& str,
                                      Heap::Space space);

 private:
  uint32_t* CharAddr(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return &raw_ptr()->data_[index];
  }

  HEAP_OBJECT_IMPLEMENTATION(FourByteString, String);
  friend class Class;
  friend class String;
};


class ExternalOneByteString : public String {
 public:
  virtual int32_t CharAt(intptr_t index) const {
    return *CharAddr(index);
  }

  virtual intptr_t CharSize() const {
    return kOneByteChar;
  }

  virtual bool IsExternal() const { return true; }
  virtual void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalOneByteString));
  }

  static RawExternalOneByteString* New(const uint8_t* characters,
                                       intptr_t len,
                                       void* peer,
                                       Dart_PeerFinalizer callback,
                                       Heap::Space space);

 private:
  const uint8_t* CharAddr(intptr_t index) const {
    // TODO(iposva): Determine if we should throw an exception here.
    ASSERT((index >= 0) && (index < Length()));
    return &(raw_ptr()->external_data_->data()[index]);
  }

  void SetExternalData(ExternalStringData<uint8_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  static void Finalize(Dart_Handle handle, void* peer);

  HEAP_OBJECT_IMPLEMENTATION(ExternalOneByteString, String);
  friend class Class;
  friend class String;
};


class ExternalTwoByteString : public String {
 public:
  virtual int32_t CharAt(intptr_t index) const {
    return *CharAddr(index);
  }

  virtual intptr_t CharSize() const {
    return kTwoByteChar;
  }

  virtual bool IsExternal() const { return true; }
  virtual void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 2;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalTwoByteString));
  }

  static RawExternalTwoByteString* New(const uint16_t* characters,
                                       intptr_t len,
                                       void* peer,
                                       Dart_PeerFinalizer callback,
                                       Heap::Space space = Heap::kNew);

 private:
  const uint16_t* CharAddr(intptr_t index) const {
    // TODO(iposva): Determine if we should throw an exception here.
    ASSERT((index >= 0) && (index < Length()));
    return &(raw_ptr()->external_data_->data()[index]);
  }

  void SetExternalData(ExternalStringData<uint16_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  static void Finalize(Dart_Handle handle, void* peer);

  HEAP_OBJECT_IMPLEMENTATION(ExternalTwoByteString, String);
  friend class Class;
  friend class String;
};


class ExternalFourByteString : public String {
 public:
  virtual int32_t CharAt(intptr_t index) const {
    return *CharAddr(index);
  }

  virtual intptr_t CharSize() const {
    return kFourByteChar;
  }

  virtual bool IsExternal() const { return true; }
  virtual void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  // We use the same maximum elements for all strings.
  static const intptr_t kBytesPerElement = 4;
  static const intptr_t kMaxElements = String::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalFourByteString));
  }

  static RawExternalFourByteString* New(const uint32_t* characters,
                                        intptr_t len,
                                        void* peer,
                                        Dart_PeerFinalizer callback,
                                        Heap::Space space = Heap::kNew);

 private:
  const uint32_t* CharAddr(intptr_t index) const {
    // TODO(iposva): Determine if we should throw an exception here.
    ASSERT((index >= 0) && (index < Length()));
    return &(raw_ptr()->external_data_->data()[index]);
  }

  void SetExternalData(ExternalStringData<uint32_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  static void Finalize(Dart_Handle handle, void* peer);

  HEAP_OBJECT_IMPLEMENTATION(ExternalFourByteString, String);
  friend class Class;
  friend class String;
};


class Bool : public Instance {
 public:
  bool value() const {
    return raw_ptr()->value_;
  }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawBool));
  }

  static RawBool* True();
  static RawBool* False();

  static RawBool* Get(bool value) {
    return value ? Bool::True() : Bool::False();
  }

 private:
  void set_value(bool value) const { raw_ptr()->value_ = value; }

  // New should only be called to initialize the two legal bool values.
  static RawBool* New(bool value);

  HEAP_OBJECT_IMPLEMENTATION(Bool, Instance);
  friend class Class;
  friend class Object;  // To initialize the true and false values.
};


class Array : public Instance {
 public:
  intptr_t Length() const {
    ASSERT(!IsNull());
    return Smi::Value(raw_ptr()->length_);
  }
  static intptr_t length_offset() { return OFFSET_OF(RawArray, length_); }
  static intptr_t data_offset() { return length_offset() + kWordSize; }

  RawObject* At(intptr_t index) const {
    return *ObjectAddr(index);
  }
  void SetAt(intptr_t index, const Object& value) const {
    // TODO(iposva): Add storing NoGCScope.
    StorePointer(ObjectAddr(index), value.raw());
  }

  virtual RawAbstractTypeArguments* GetTypeArguments() const {
    return raw_ptr()->type_arguments_;
  }
  virtual void SetTypeArguments(const AbstractTypeArguments& value) const {
    StorePointer(&raw_ptr()->type_arguments_, value.raw());
  }

  virtual bool Equals(const Instance& other) const;

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
    ASSERT(sizeof(RawArray) == (sizeof(RawObject) + (2 * kWordSize)));
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(sizeof(RawArray) + (len * kBytesPerElement));
  }

  // Make the array immutable to Dart code by switching the class pointer
  // to ImmutableArray.
  void MakeImmutable() const;

  static RawArray* New(intptr_t len, Heap::Space space = Heap::kNew);

  // Creates and returns a new array with 'new_length'. Copies all elements from
  // 'source' to the new array. 'new_length' must be greater than or equal to
  // 'source.Length()'. 'source' can be null.
  static RawArray* Grow(const Array& source,
                        int new_length,
                        Heap::Space space = Heap::kNew);

  // Returns the preallocated empty array, used to initialize array fields.
  static RawArray* Empty();

  // Return an Array object that contains all the elements currently present
  // in the specified Growable Object Array. This is done by first truncating
  // the Growable Object Array's backing array to the currently used size and
  // returning the truncated backing array.
  // The remaining unused part of the backing array is marked as an Array
  // object or a regular Object so that it can be traversed during garbage
  // collection. The backing array of the original Growable Object Array is
  // set to an empty array.
  static RawArray* MakeArray(const GrowableObjectArray& growable_array);

 protected:
  static RawArray* New(const Class& cls,
                       intptr_t len,
                       Heap::Space space = Heap::kNew);

 private:
  RawObject** ObjectAddr(intptr_t index) const {
    // TODO(iposva): Determine if we should throw an exception here.
    ASSERT((index >= 0) && (index < Length()));
    return &raw_ptr()->data()[index];
  }

  void SetLength(intptr_t value) const {
    // This is only safe because we create a new Smi, which does not cause
    // heap allocation.
    raw_ptr()->length_ = Smi::New(value);
  }

  HEAP_OBJECT_IMPLEMENTATION(Array, Instance);
  friend class Class;
};


class ImmutableArray : public Array {
 public:
  static RawImmutableArray* New(intptr_t len, Heap::Space space = Heap::kNew);

 private:
  HEAP_OBJECT_IMPLEMENTATION(ImmutableArray, Array);
  friend class Class;
};


class GrowableObjectArray : public Instance {
 public:
  intptr_t Capacity() const {
    NoGCScope no_gc;
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
    raw_ptr()->length_ = Smi::New(value);
  }

  RawArray* data() const { return raw_ptr()->data_; }
  void SetData(const Array& value) const {
    StorePointer(&raw_ptr()->data_, value.raw());
  }

  RawObject* At(intptr_t index) const {
    NoGCScope no_gc;
    ASSERT(!IsNull());
    ASSERT(index < Length());
    return *ObjectAddr(index);
  }
  void SetAt(intptr_t index, const Object& value) const {
    ASSERT(!IsNull());
    ASSERT(index < Length());
    const Array& arr = Array::Handle(data());
    arr.SetAt(index, value);
  }

  void Add(const Object& value, Heap::Space space = Heap::kNew) const;
  void Grow(intptr_t new_capacity, Heap::Space space = Heap::kNew) const;
  RawObject* RemoveLast() const;

  virtual RawAbstractTypeArguments* GetTypeArguments() const {
    ASSERT(AbstractTypeArguments::AreEqual(
        AbstractTypeArguments::Handle(Array::Handle(data()).GetTypeArguments()),
        AbstractTypeArguments::Handle(raw_ptr()->type_arguments_)));
    return raw_ptr()->type_arguments_;
  }
  virtual void SetTypeArguments(const AbstractTypeArguments& value) const {
    const Array& contents = Array::Handle(data());
    contents.SetTypeArguments(value);
    StorePointer(&raw_ptr()->type_arguments_, value.raw());
  }

  virtual bool Equals(const Instance& other) const;

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

  static const int kDefaultInitialCapacity = 4;

  HEAP_OBJECT_IMPLEMENTATION(GrowableObjectArray, Instance);
  friend class Array;
  friend class Class;
};


class ByteArray : public Instance {
 public:
  intptr_t Length() const {
    ASSERT(!IsNull());
    return Smi::Value(raw_ptr()->length_);
  }

  static intptr_t length_offset() {
    return OFFSET_OF(RawByteArray, length_);
  }

  virtual intptr_t ByteLength() const;

  static void Copy(void* dst,
                   const ByteArray& src,
                   intptr_t src_offset,
                   intptr_t length);

  static void Copy(const ByteArray& dst,
                   intptr_t dst_offset,
                   const void* src,
                   intptr_t length);

  static void Copy(const ByteArray& dst,
                   intptr_t dst_offset,
                   const ByteArray& src,
                   intptr_t src_offset,
                   intptr_t length);

 protected:
  virtual uint8_t* ByteAddr(intptr_t byte_offset) const;

  template<typename HandleT, typename RawT>
  static RawT* NewImpl(const Class& cls,
                       intptr_t len,
                       Heap::Space space);

  template<typename HandleT, typename RawT, typename ElementT>
  static RawT* NewImpl(const Class& cls,
                       const ElementT* data,
                       intptr_t len,
                       Heap::Space space);

  template<typename HandleT, typename RawT, typename ElementT>
  static RawT* NewExternalImpl(const Class& cls,
                               ElementT* data,
                               intptr_t len,
                               void* peer,
                               Dart_PeerFinalizer callback,
                               Heap::Space space);

  template<typename HandleT, typename RawT, typename ElementT>
  static RawT* ReadFromImpl(SnapshotReader* reader,
                            intptr_t object_id,
                            intptr_t tags,
                            Snapshot::Kind kind);

  void SetLength(intptr_t value) const {
    raw_ptr()->length_ = Smi::New(value);
  }

 private:
  HEAP_OBJECT_IMPLEMENTATION(ByteArray, Instance);
  friend class Class;
};


class Int8Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length();
  }

  int8_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->data_[index];
  }

  void SetAt(intptr_t index, int8_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->data_[index] = value;
  }

  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t data_offset() {
    return length_offset() + kWordSize;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawInt8Array) == OFFSET_OF(RawInt8Array, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawInt8Array) + (len * kBytesPerElement));
  }

  static RawInt8Array* New(intptr_t len,
                           Heap::Space space = Heap::kNew);
  static RawInt8Array* New(const int8_t* data,
                           intptr_t len,
                           Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    return reinterpret_cast<uint8_t*>(&raw_ptr()->data_) + byte_offset;
  }

  HEAP_OBJECT_IMPLEMENTATION(Int8Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class Uint8Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length();
  }

  uint8_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->data_[index];
  }

  void SetAt(intptr_t index, uint8_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->data_[index] = value;
  }

  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t data_offset() {
    return length_offset() + kWordSize;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawUint8Array) == OFFSET_OF(RawUint8Array, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawUint8Array) + (len * kBytesPerElement));
  }

  static RawUint8Array* New(intptr_t len,
                            Heap::Space space = Heap::kNew);
  static RawUint8Array* New(const uint8_t* data,
                            intptr_t len,
                            Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    return reinterpret_cast<uint8_t*>(&raw_ptr()->data_) + byte_offset;
  }

  HEAP_OBJECT_IMPLEMENTATION(Uint8Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class Int16Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  int16_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->data_[index];
  }

  void SetAt(intptr_t index, int16_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->data_[index] = value;
  }

  static const intptr_t kBytesPerElement = 2;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t data_offset() {
    return length_offset() + kWordSize;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawInt16Array) == OFFSET_OF(RawInt16Array, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawInt16Array) + (len * kBytesPerElement));
  }

  static RawInt16Array* New(intptr_t len,
                            Heap::Space space = Heap::kNew);
  static RawInt16Array* New(const int16_t* data,
                            intptr_t len,
                            Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    return reinterpret_cast<uint8_t*>(&raw_ptr()->data_) + byte_offset;
  }

  HEAP_OBJECT_IMPLEMENTATION(Int16Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class Uint16Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  uint16_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->data_[index];
  }

  void SetAt(intptr_t index, uint16_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->data_[index] = value;
  }

  static const intptr_t kBytesPerElement = 2;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t data_offset() {
    return length_offset() + kWordSize;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawUint16Array) == OFFSET_OF(RawUint16Array, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawUint16Array) + (len * kBytesPerElement));
  }

  static RawUint16Array* New(intptr_t len,
                             Heap::Space space = Heap::kNew);
  static RawUint16Array* New(const uint16_t* data,
                             intptr_t len,
                             Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    return reinterpret_cast<uint8_t*>(&raw_ptr()->data_) + byte_offset;
  }

  HEAP_OBJECT_IMPLEMENTATION(Uint16Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class Int32Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  int32_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->data_[index];
  }

  void SetAt(intptr_t index, int32_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->data_[index] = value;
  }

  static const intptr_t kBytesPerElement = 4;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t data_offset() {
    return length_offset() + kWordSize;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawInt32Array) == OFFSET_OF(RawInt32Array, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawInt32Array) + (len * kBytesPerElement));
  }

  static RawInt32Array* New(intptr_t len,
                            Heap::Space space = Heap::kNew);
  static RawInt32Array* New(const int32_t* data,
                            intptr_t len,
                            Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    return reinterpret_cast<uint8_t*>(&raw_ptr()->data_) + byte_offset;
  }

  HEAP_OBJECT_IMPLEMENTATION(Int32Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class Uint32Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  uint32_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->data_[index];
  }

  void SetAt(intptr_t index, uint32_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->data_[index] = value;
  }

  static const intptr_t kBytesPerElement = 4;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t data_offset() {
    return length_offset() + kWordSize;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawUint32Array) == OFFSET_OF(RawUint32Array, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawUint32Array) + (len * kBytesPerElement));
  }

  static RawUint32Array* New(intptr_t len,
                             Heap::Space space = Heap::kNew);
  static RawUint32Array* New(const uint32_t* data,
                             intptr_t len,
                             Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    return reinterpret_cast<uint8_t*>(&raw_ptr()->data_) + byte_offset;
  }

  HEAP_OBJECT_IMPLEMENTATION(Uint32Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class Int64Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  int64_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->data_[index];
  }

  void SetAt(intptr_t index, int64_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->data_[index] = value;
  }

  static const intptr_t kBytesPerElement = 8;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t data_offset() {
    return length_offset() + kWordSize;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawInt64Array) == OFFSET_OF(RawInt64Array, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawInt64Array) + (len * kBytesPerElement));
  }

  static RawInt64Array* New(intptr_t len,
                            Heap::Space space = Heap::kNew);
  static RawInt64Array* New(const int64_t* data,
                            intptr_t len,
                            Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    return reinterpret_cast<uint8_t*>(&raw_ptr()->data_) + byte_offset;
  }

  HEAP_OBJECT_IMPLEMENTATION(Int64Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class Uint64Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * sizeof(uint64_t);
  }

  uint64_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->data_[index];
  }

  void SetAt(intptr_t index, uint64_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->data_[index] = value;
  }

  static const intptr_t kBytesPerElement = 8;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t data_offset() {
    return length_offset() + kWordSize;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawUint64Array) == OFFSET_OF(RawUint64Array, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawUint64Array) + (len * kBytesPerElement));
  }

  static RawUint64Array* New(intptr_t len,
                             Heap::Space space = Heap::kNew);
  static RawUint64Array* New(const uint64_t* data,
                             intptr_t len,
                             Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    return reinterpret_cast<uint8_t*>(&raw_ptr()->data_) + byte_offset;
  }

  HEAP_OBJECT_IMPLEMENTATION(Uint64Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class Float32Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  float At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->data_[index];
  }

  void SetAt(intptr_t index, float value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->data_[index] = value;
  }

  static const intptr_t kBytesPerElement = 4;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t data_offset() {
    return length_offset() + kWordSize;
  }

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawFloat32Array) == OFFSET_OF(RawFloat32Array, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawFloat32Array) + (len * kBytesPerElement));
  }

  static RawFloat32Array* New(intptr_t len,
                              Heap::Space space = Heap::kNew);
  static RawFloat32Array* New(const float* data,
                              intptr_t len,
                              Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    return reinterpret_cast<uint8_t*>(&raw_ptr()->data_) + byte_offset;
  }

  HEAP_OBJECT_IMPLEMENTATION(Float32Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class Float64Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  double At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->data_[index];
  }

  void SetAt(intptr_t index, double value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->data_[index] = value;
  }

  static const intptr_t kBytesPerElement = 8;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawFloat64Array) == OFFSET_OF(RawFloat64Array, data_));
    return 0;
  }

  static intptr_t data_offset() {
    return length_offset() + kWordSize;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawFloat64Array) + (len * kBytesPerElement));
  }

  static RawFloat64Array* New(intptr_t len,
                              Heap::Space space = Heap::kNew);
  static RawFloat64Array* New(const double* data,
                              intptr_t len,
                              Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    return reinterpret_cast<uint8_t*>(&raw_ptr()->data_) + byte_offset;
  }

  HEAP_OBJECT_IMPLEMENTATION(Float64Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class ExternalInt8Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  int8_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->external_data_->data()[index];
  }

  void SetAt(intptr_t index, int8_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->external_data_->data()[index] = value;
  }

  void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  static const intptr_t kBytesPerElement = 1;

  // Since external arrays may be serialized to non-external ones,
  // enforce the same maximum element count.
  static const intptr_t kMaxElements = Int8Array::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalInt8Array));
  }

  static RawExternalInt8Array* New(int8_t* data,
                                   intptr_t len,
                                   void* peer,
                                   Dart_PeerFinalizer callback,
                                   Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    uint8_t* data =
        reinterpret_cast<uint8_t*>(raw_ptr()->external_data_->data());
    return data + byte_offset;
  }

  void SetExternalData(ExternalByteArrayData<int8_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  HEAP_OBJECT_IMPLEMENTATION(ExternalInt8Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class ExternalUint8Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  uint8_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->external_data_->data()[index];
  }

  void SetAt(intptr_t index, uint8_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->external_data_->data()[index] = value;
  }

  void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  static const intptr_t kBytesPerElement = 1;

  // Since external arrays may be serialized to non-external ones,
  // enforce the same maximum element count.
  static const intptr_t kMaxElements = Uint8Array::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalUint8Array));
  }

  static RawExternalUint8Array* New(uint8_t* data,
                                    intptr_t len,
                                    void* peer,
                                    Dart_PeerFinalizer callback,
                                    Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    uint8_t* data =
        reinterpret_cast<uint8_t*>(raw_ptr()->external_data_->data());
    return data + byte_offset;
  }

  void SetExternalData(ExternalByteArrayData<uint8_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  HEAP_OBJECT_IMPLEMENTATION(ExternalUint8Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class ExternalInt16Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  int16_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->external_data_->data()[index];
  }

  void SetAt(intptr_t index, int16_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->external_data_->data()[index] = value;
  }

  void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  static const intptr_t kBytesPerElement = 2;

  // Since external arrays may be serialized to non-external ones,
  // enforce the same maximum element count.
  static const intptr_t kMaxElements = Int16Array::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalInt16Array));
  }

  static RawExternalInt16Array* New(int16_t* data,
                                    intptr_t len,
                                    void* peer,
                                    Dart_PeerFinalizer callback,
                                    Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    uint8_t* data =
        reinterpret_cast<uint8_t*>(raw_ptr()->external_data_->data());
    return data + byte_offset;
  }

  void SetExternalData(ExternalByteArrayData<int16_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  HEAP_OBJECT_IMPLEMENTATION(ExternalInt16Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class ExternalUint16Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  int16_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->external_data_->data()[index];
  }

  void SetAt(intptr_t index, int16_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->external_data_->data()[index] = value;
  }

  void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  static const intptr_t kBytesPerElement = 2;

  // Since external arrays may be serialized to non-external ones,
  // enforce the same maximum element count.
  static const intptr_t kMaxElements = Uint16Array::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalUint16Array));
  }

  static RawExternalUint16Array* New(uint16_t* data,
                                     intptr_t len,
                                     void* peer,
                                     Dart_PeerFinalizer callback,
                                     Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    uint8_t* data =
        reinterpret_cast<uint8_t*>(raw_ptr()->external_data_->data());
    return data + byte_offset;
  }

  void SetExternalData(ExternalByteArrayData<uint16_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  HEAP_OBJECT_IMPLEMENTATION(ExternalUint16Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class ExternalInt32Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  int32_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->external_data_->data()[index];
  }

  void SetAt(intptr_t index, int32_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->external_data_->data()[index] = value;
  }

  void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  static const intptr_t kBytesPerElement = 4;

  // Since external arrays may be serialized to non-external ones,
  // enforce the same maximum element count.
  static const intptr_t kMaxElements = Int32Array::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalInt32Array));
  }

  static RawExternalInt32Array* New(int32_t* data,
                                    intptr_t len,
                                    void* peer,
                                    Dart_PeerFinalizer callback,
                                    Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    uint8_t* data =
        reinterpret_cast<uint8_t*>(raw_ptr()->external_data_->data());
    return data + byte_offset;
  }

  void SetExternalData(ExternalByteArrayData<int32_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  HEAP_OBJECT_IMPLEMENTATION(ExternalInt32Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class ExternalUint32Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  int32_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->external_data_->data()[index];
  }

  void SetAt(intptr_t index, int32_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->external_data_->data()[index] = value;
  }

  void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  static const intptr_t kBytesPerElement = 4;

  // Since external arrays may be serialized to non-external ones,
  // enforce the same maximum element count.
  static const intptr_t kMaxElements = Uint32Array::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalUint32Array));
  }

  static RawExternalUint32Array* New(uint32_t* data,
                                     intptr_t len,
                                     void* peer,
                                     Dart_PeerFinalizer callback,
                                     Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    uint8_t* data =
        reinterpret_cast<uint8_t*>(raw_ptr()->external_data_->data());
    return data + byte_offset;
  }

  void SetExternalData(ExternalByteArrayData<uint32_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  HEAP_OBJECT_IMPLEMENTATION(ExternalUint32Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class ExternalInt64Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  int64_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->external_data_->data()[index];
  }

  void SetAt(intptr_t index, int64_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->external_data_->data()[index] = value;
  }

  void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  static const intptr_t kBytesPerElement = 8;

  // Since external arrays may be serialized to non-external ones,
  // enforce the same maximum element count.
  static const intptr_t kMaxElements = Int64Array::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalInt64Array));
  }

  static RawExternalInt64Array* New(int64_t* data,
                                    intptr_t len,
                                    void* peer,
                                    Dart_PeerFinalizer callback,
                                    Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    uint8_t* data =
        reinterpret_cast<uint8_t*>(raw_ptr()->external_data_->data());
    return data + byte_offset;
  }

  void SetExternalData(ExternalByteArrayData<int64_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  HEAP_OBJECT_IMPLEMENTATION(ExternalInt64Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class ExternalUint64Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  int64_t At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->external_data_->data()[index];
  }

  void SetAt(intptr_t index, int64_t value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->external_data_->data()[index] = value;
  }

  void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  static const intptr_t kBytesPerElement = 8;

  // Since external arrays may be serialized to non-external ones,
  // enforce the same maximum element count.
  static const intptr_t kMaxElements = Uint64Array::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalUint64Array));
  }

  static RawExternalUint64Array* New(uint64_t* data,
                                     intptr_t len,
                                     void* peer,
                                     Dart_PeerFinalizer callback,
                                     Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    uint8_t* data =
        reinterpret_cast<uint8_t*>(raw_ptr()->external_data_->data());
    return data + byte_offset;
  }

  void SetExternalData(ExternalByteArrayData<uint64_t>* data) {
    raw_ptr()->external_data_ = data;
  }

  HEAP_OBJECT_IMPLEMENTATION(ExternalUint64Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class ExternalFloat32Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  float At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->external_data_->data()[index];
  }

  void SetAt(intptr_t index, float value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->external_data_->data()[index] = value;
  }

  void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  static const intptr_t kBytesPerElement = 4;

  // Since external arrays may be serialized to non-external ones,
  // enforce the same maximum element count.
  static const intptr_t kMaxElements = Float32Array::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalFloat32Array));
  }

  static RawExternalFloat32Array* New(float* data,
                                      intptr_t len,
                                      void* peer,
                                      Dart_PeerFinalizer callback,
                                      Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    uint8_t* data =
        reinterpret_cast<uint8_t*>(raw_ptr()->external_data_->data());
    return data + byte_offset;
  }

  void SetExternalData(ExternalByteArrayData<float>* data) {
    raw_ptr()->external_data_ = data;
  }

  HEAP_OBJECT_IMPLEMENTATION(ExternalFloat32Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class ExternalFloat64Array : public ByteArray {
 public:
  intptr_t ByteLength() const {
    return Length() * kBytesPerElement;
  }

  double At(intptr_t index) const {
    ASSERT((index >= 0) && (index < Length()));
    return raw_ptr()->external_data_->data()[index];
  }

  void SetAt(intptr_t index, double value) const {
    ASSERT((index >= 0) && (index < Length()));
    raw_ptr()->external_data_->data()[index] = value;
  }

  void* GetPeer() const {
    return raw_ptr()->external_data_->peer();
  }

  static const intptr_t kBytesPerElement = 8;

  // Since external arrays may be serialized to non-external ones,
  // enforce the same maximum element count.
  static const intptr_t kMaxElements = Float64Array::kMaxElements;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawExternalFloat64Array));
  }

  static RawExternalFloat64Array* New(double* data,
                                      intptr_t len,
                                      void* peer,
                                      Dart_PeerFinalizer callback,
                                      Heap::Space space = Heap::kNew);

 private:
  uint8_t* ByteAddr(intptr_t byte_offset) const {
    ASSERT((byte_offset >= 0) && (byte_offset < ByteLength()));
    uint8_t* data =
        reinterpret_cast<uint8_t*>(raw_ptr()->external_data_->data());
    return data + byte_offset;
  }

  void SetExternalData(ExternalByteArrayData<double>* data) {
    raw_ptr()->external_data_ = data;
  }

  HEAP_OBJECT_IMPLEMENTATION(ExternalFloat64Array, ByteArray);
  friend class ByteArray;
  friend class Class;
};


class Closure : public Instance {
 public:
  RawFunction* function() const { return raw_ptr()->function_; }
  static intptr_t function_offset() {
    return OFFSET_OF(RawClosure, function_);
  }

  RawContext* context() const { return raw_ptr()->context_; }
  static intptr_t context_offset() { return OFFSET_OF(RawClosure, context_); }

  virtual RawAbstractTypeArguments* GetTypeArguments() const {
    return raw_ptr()->type_arguments_;
  }
  virtual void SetTypeArguments(const AbstractTypeArguments& value) const {
    StorePointer(&raw_ptr()->type_arguments_, value.raw());
  }
  static intptr_t type_arguments_offset() {
    return OFFSET_OF(RawClosure, type_arguments_);
  }

  // TODO(iposva): Remove smrck support once mapping to arbitrary is available.
  RawInteger* smrck() const { return raw_ptr()->smrck_; }
  void set_smrck(const Integer& smrck) const {
    StorePointer(&raw_ptr()->smrck_, smrck.raw());
  }
  static intptr_t smrck_offset() { return OFFSET_OF(RawClosure, smrck_); }

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawClosure));
  }

  static RawClosure* New(const Function& function,
                         const Context& context,
                         Heap::Space space = Heap::kNew);

 private:
  void set_function(const Function& value) const;
  void set_context(const Context& value) const;

  HEAP_OBJECT_IMPLEMENTATION(Closure, Instance);
  friend class Class;
};


// Internal stacktrace object used in exceptions for printing stack traces.
class Stacktrace : public Instance {
 public:
  intptr_t Length() const;
  RawFunction* FunctionAtFrame(intptr_t frame_index) const;
  RawCode* CodeAtFrame(intptr_t frame_index) const;
  RawSmi* PcOffsetAtFrame(intptr_t frame_index) const;
  void Append(const GrowableObjectArray& func_list,
              const GrowableObjectArray& code_list,
              const GrowableObjectArray& pc_offset_list) const;

  static intptr_t InstanceSize() {
    return RoundedAllocationSize(sizeof(RawStacktrace));
  }
  static RawStacktrace* New(const GrowableObjectArray& func_list,
                            const GrowableObjectArray& code_list,
                            const GrowableObjectArray& pc_offset_list,
                            Heap::Space space = Heap::kNew);

  const char* ToCStringInternal(bool verbose) const;

 private:
  void set_function_array(const Array& function_array) const;
  void set_code_array(const Array& code_array) const;
  void set_pc_offset_array(const Array& pc_offset_array) const;

  HEAP_OBJECT_IMPLEMENTATION(Stacktrace, Instance);
  friend class Class;
};


// Internal JavaScript regular expression object.
class JSRegExp : public Instance {
 public:
  // Meaning of RegExType:
  // kUninitialized: the type of th regexp has not been initialized yet.
  // kSimple: A simple pattern to match against, using string indexOf operation.
  // kComplex: A complex pattern to match.
  enum RegExType {
    kUnitialized = 0,
    kSimple,
    kComplex,
  };

  // Flags are passed to a regex object as follows:
  // 'i': ignore case, 'g': do global matches, 'm': pattern is multi line.
  enum Flags {
    kNone = 0,
    kGlobal = 1,
    kIgnoreCase = 2,
    kMultiLine = 4,
  };

  bool is_initialized() const { return (raw_ptr()->type_ != kUnitialized); }
  bool is_simple() const { return (raw_ptr()->type_ == kSimple); }
  bool is_complex() const { return (raw_ptr()->type_ == kComplex); }

  bool is_global() const { return (raw_ptr()->flags_ & kGlobal); }
  bool is_ignore_case() const { return (raw_ptr()->flags_ & kIgnoreCase); }
  bool is_multi_line() const { return (raw_ptr()->flags_ & kMultiLine); }

  RawString* pattern() const { return raw_ptr()->pattern_; }
  RawSmi* num_bracket_expressions() const {
    return raw_ptr()->num_bracket_expressions_;
  }

  void set_pattern(const String& pattern) const;
  void set_num_bracket_expressions(intptr_t value) const;
  void set_is_global() const { raw_ptr()->flags_ |= kGlobal; }
  void set_is_ignore_case() const { raw_ptr()->flags_ |= kIgnoreCase; }
  void set_is_multi_line() const { raw_ptr()->flags_ |= kMultiLine; }
  void set_is_simple() const { raw_ptr()->type_ = kSimple; }
  void set_is_complex() const { raw_ptr()->type_ = kComplex; }

  void* GetDataStartAddress() const;
  static RawJSRegExp* FromDataStartAddress(void* data);
  const char* Flags() const;

  virtual bool Equals(const Instance& other) const;

  static const intptr_t kBytesPerElement = 1;
  static const intptr_t kMaxElements = kSmiMax / kBytesPerElement;

  static intptr_t InstanceSize() {
    ASSERT(sizeof(RawJSRegExp) == OFFSET_OF(RawJSRegExp, data_));
    return 0;
  }

  static intptr_t InstanceSize(intptr_t len) {
    ASSERT(0 <= len && len <= kMaxElements);
    return RoundedAllocationSize(
        sizeof(RawJSRegExp) + (len * kBytesPerElement));
  }

  static RawJSRegExp* New(intptr_t length, Heap::Space space = Heap::kNew);

 private:
  void set_type(RegExType type) const { raw_ptr()->type_ = type; }
  void set_flags(intptr_t value) const { raw_ptr()->flags_ = value; }

  void SetLength(intptr_t value) const {
    // This is only safe because we create a new Smi, which does not cause
    // heap allocation.
    raw_ptr()->data_length_ = Smi::New(value);
  }

  HEAP_OBJECT_IMPLEMENTATION(JSRegExp, Instance);
  friend class Class;
};


// Breaking cycles and loops.
RawClass* Object::clazz() const {
  uword raw_value = reinterpret_cast<uword>(raw_);
  if ((raw_value & kSmiTagMask) == kSmiTag) {
    return Smi::Class();
  }
  return Isolate::Current()->class_table()->At(raw()->GetClassId());
}


void Object::SetRaw(RawObject* value) {
  // NOTE: The assignment "raw_ = value" should be the first statement in
  // this function. Also do not use 'value' in this function after the
  // assignment (use 'raw_' instead).
  raw_ = value;
  if ((reinterpret_cast<uword>(raw_) & kSmiTagMask) == kSmiTag) {
    set_vtable(Smi::handle_vtable_);
    return;
  } else if (raw_ == null_) {
    set_vtable(handle_vtable_);
    return;
  }

#if defined(DEBUG)
  Isolate* isolate = Isolate::Current();
  Heap* isolate_heap = isolate->heap();
  Heap* vm_isolate_heap = Dart::vm_isolate()->heap();
  ASSERT(isolate_heap->Contains(reinterpret_cast<uword>(raw_->ptr())) ||
         vm_isolate_heap->Contains(reinterpret_cast<uword>(raw_->ptr())));
#endif
  intptr_t cid = raw_->GetClassId();
  if (cid < kNumPredefinedCids) {
#if defined(DEBUG)
    ASSERT(builtin_vtables_[cid] ==
           isolate->class_table()->At(cid)->ptr()->handle_vtable_);
#endif
    set_vtable(builtin_vtables_[cid]);
  } else {
#if !defined(DEBUG)
    Isolate* isolate = Isolate::Current();
#endif
    RawClass* raw_class = isolate->class_table()->At(cid);
    set_vtable(raw_class->ptr()->handle_vtable_);
  }
}


bool Function::HasCode() const {
  return raw_ptr()->code_ != Code::null();
}


intptr_t Field::Offset() const {
  ASSERT(!is_static());  // Offset is valid only for instance fields.
  return Smi::Value(reinterpret_cast<RawSmi*>(raw_ptr()->value_));
}


void Field::SetOffset(intptr_t value) const {
  ASSERT(!is_static());  // SetOffset is valid only for instance fields.
  raw_ptr()->value_ = Smi::New(value);
}


intptr_t TokenStream::Length() const {
  return Smi::Value(raw_ptr()->length_);
}


void Context::SetAt(intptr_t index, const Instance& value) const {
  StorePointer(InstanceAddr(index), value.raw());
}


intptr_t Stackmap::SizeInBits() const {
  return (Smi::Value(raw_ptr()->bitmap_size_in_bytes_) * kBitsPerByte);
}


bool String::Equals(const String& str) const {
  if (raw() == str.raw()) {
    return true;  // Both handles point to the same raw instance.
  }
  if (str.IsNull()) {
    return false;
  }
  return Equals(str, 0, str.Length());
}


bool String::Equals(const String& str,
                    intptr_t begin_index,
                    intptr_t len) const {
  ASSERT(begin_index >= 0);
  ASSERT((begin_index == 0) || (begin_index < str.Length()));
  ASSERT(len >= 0);
  ASSERT(len <= str.Length());
  if (len != this->Length()) {
    return false;  // Lengths don't match.
  }
  for (intptr_t i = 0; i < len; i++) {
    if (this->CharAt(i) != str.CharAt(begin_index + i)) {
      return false;
    }
  }
  return true;
}

}  // namespace dart

#endif  // VM_OBJECT_H_
