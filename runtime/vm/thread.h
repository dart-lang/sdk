// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_H_
#define VM_THREAD_H_

#include "include/dart_api.h"
#include "vm/globals.h"
#include "vm/handles.h"
#include "vm/os_thread.h"
#include "vm/store_buffer.h"
#include "vm/runtime_entry_list.h"

namespace dart {

class AbstractType;
class ApiLocalScope;
class Array;
class CHA;
class Class;
class Code;
class Error;
class ExceptionHandlers;
class Field;
class Function;
class GrowableObjectArray;
class HandleScope;
class Heap;
class Instance;
class Isolate;
class Library;
class LongJumpScope;
class Object;
class OSThread;
class PcDescriptors;
class RawBool;
class RawObject;
class RawCode;
class RawGrowableObjectArray;
class RawString;
class RuntimeEntry;
class StackResource;
class String;
class TypeArguments;
class TypeParameter;
class Zone;

#define REUSABLE_HANDLE_LIST(V)                                                \
  V(AbstractType)                                                              \
  V(Array)                                                                     \
  V(Class)                                                                     \
  V(Code)                                                                      \
  V(Error)                                                                     \
  V(ExceptionHandlers)                                                         \
  V(Field)                                                                     \
  V(Function)                                                                  \
  V(GrowableObjectArray)                                                       \
  V(Instance)                                                                  \
  V(Library)                                                                   \
  V(Object)                                                                    \
  V(PcDescriptors)                                                             \
  V(String)                                                                    \
  V(TypeArguments)                                                             \
  V(TypeParameter)                                                             \


// List of VM-global objects/addresses cached in each Thread object.
#define CACHED_VM_OBJECTS_LIST(V)                                              \
  V(RawObject*, object_null_, Object::null(), NULL)                            \
  V(RawBool*, bool_true_, Object::bool_true().raw(), NULL)                     \
  V(RawBool*, bool_false_, Object::bool_false().raw(), NULL)                   \
  V(RawCode*, update_store_buffer_code_,                                       \
    StubCode::UpdateStoreBuffer_entry()->code(), NULL)                         \
  V(RawCode*, fix_callers_target_code_,                                        \
    StubCode::FixCallersTarget_entry()->code(), NULL)                          \
  V(RawCode*, fix_allocation_stub_code_,                                       \
    StubCode::FixAllocationStubTarget_entry()->code(), NULL)                   \
  V(RawCode*, invoke_dart_code_stub_,                                          \
    StubCode::InvokeDartCode_entry()->code(), NULL)                            \

#define CACHED_ADDRESSES_LIST(V)                                               \
  V(uword, update_store_buffer_entry_point_,                                   \
    StubCode::UpdateStoreBuffer_entry()->EntryPoint(), 0)                      \
  V(uword, native_call_wrapper_entry_point_,                                   \
    NativeEntry::NativeCallWrapperEntry(), 0)                                  \
  V(RawString**, predefined_symbols_address_,                                  \
    Symbols::PredefinedAddress(), NULL)                                        \
  V(uword, double_negate_address_,                                             \
    reinterpret_cast<uword>(&double_negate_constant), 0)                       \
  V(uword, double_abs_address_,                                                \
    reinterpret_cast<uword>(&double_abs_constant), 0)                          \
  V(uword, float_not_address_,                                                 \
    reinterpret_cast<uword>(&float_not_constant), 0)                           \
  V(uword, float_negate_address_,                                              \
    reinterpret_cast<uword>(&float_negate_constant), 0)                        \
  V(uword, float_absolute_address_,                                            \
    reinterpret_cast<uword>(&float_absolute_constant), 0)                      \
  V(uword, float_zerow_address_,                                               \
    reinterpret_cast<uword>(&float_zerow_constant), 0)                         \

#define CACHED_CONSTANTS_LIST(V)                                               \
  CACHED_VM_OBJECTS_LIST(V)                                                    \
  CACHED_ADDRESSES_LIST(V)                                                     \

// A VM thread; may be executing Dart code or performing helper tasks like
// garbage collection or compilation. The Thread structure associated with
// a thread is allocated by EnsureInit before entering an isolate, and destroyed
// automatically when the underlying OS thread exits. NOTE: On Windows, CleanUp
// must currently be called manually (issue 23474).
class Thread : public BaseThread {
 public:
  ~Thread();

  // The currently executing thread, or NULL if not yet initialized.
  static Thread* Current() {
    BaseThread* thread = OSThread::GetCurrentTLS();
    if (thread == NULL || thread->is_os_thread()) {
      return NULL;
    }
    return reinterpret_cast<Thread*>(thread);
  }

  // Makes the current thread enter 'isolate'.
  static bool EnterIsolate(Isolate* isolate);
  // Makes the current thread exit its isolate.
  static void ExitIsolate();

  // A VM thread other than the main mutator thread can enter an isolate as a
  // "helper" to gain limited concurrent access to the isolate. One example is
  // SweeperTask (which uses the class table, which is copy-on-write).
  // TODO(koda): Properly synchronize heap access to expand allowed operations.
  static bool EnterIsolateAsHelper(Isolate* isolate,
                                   bool bypass_safepoint = false);
  static void ExitIsolateAsHelper(bool bypass_safepoint = false);

  // Empties the store buffer block into the isolate.
  void PrepareForGC();

  // OSThread corresponding to this thread.
  OSThread* os_thread() const { return os_thread_; }
  void set_os_thread(OSThread* os_thread) {
    os_thread_ = os_thread;
  }

  // The topmost zone used for allocation in this thread.
  Zone* zone() const { return zone_; }

  // The reusable api local scope for this thread.
  ApiLocalScope* api_reusable_scope() const { return api_reusable_scope_; }
  void set_api_reusable_scope(ApiLocalScope* value) {
    ASSERT(value == NULL || api_reusable_scope_ == NULL);
    api_reusable_scope_ = value;
  }

  // The api local scope for this thread, this where all local handles
  // are allocated.
  ApiLocalScope* api_top_scope() const { return api_top_scope_; }
  void set_api_top_scope(ApiLocalScope* value) { api_top_scope_ = value; }

  // The isolate that this thread is operating on, or NULL if none.
  Isolate* isolate() const { return isolate_; }
  static intptr_t isolate_offset() {
    return OFFSET_OF(Thread, isolate_);
  }
  bool IsMutatorThread() const;
  bool CanCollectGarbage() const;

  // Is |this| executing Dart code?
  bool IsExecutingDartCode() const;

  // Has |this| exited Dart code?
  bool HasExitedDartCode() const;

  // The (topmost) CHA for the compilation in this thread.
  CHA* cha() const {
    ASSERT(isolate_ != NULL);
    return cha_;
  }

  void set_cha(CHA* value) {
    ASSERT(isolate_ != NULL);
    cha_ = value;
  }

  int32_t no_callback_scope_depth() const {
    return no_callback_scope_depth_;
  }

  void IncrementNoCallbackScopeDepth() {
    ASSERT(no_callback_scope_depth_ < INT_MAX);
    no_callback_scope_depth_ += 1;
  }

  void DecrementNoCallbackScopeDepth() {
    ASSERT(no_callback_scope_depth_ > 0);
    no_callback_scope_depth_ -= 1;
  }

  void StoreBufferAddObject(RawObject* obj);
  void StoreBufferAddObjectGC(RawObject* obj);
#if defined(TESTING)
  bool StoreBufferContains(RawObject* obj) const {
    return store_buffer_block_->Contains(obj);
  }
#endif
  void StoreBufferBlockProcess(StoreBuffer::ThresholdPolicy policy);
  static intptr_t store_buffer_block_offset() {
    return OFFSET_OF(Thread, store_buffer_block_);
  }

  uword top_exit_frame_info() const { return top_exit_frame_info_; }
  static intptr_t top_exit_frame_info_offset() {
    return OFFSET_OF(Thread, top_exit_frame_info_);
  }

  StackResource* top_resource() const { return top_resource_; }
  void set_top_resource(StackResource* value) {
    top_resource_ = value;
  }
  static intptr_t top_resource_offset() {
    return OFFSET_OF(Thread, top_resource_);
  }

  // Heap of the isolate that this thread is operating on.
  Heap* heap() const { return heap_; }
  static intptr_t heap_offset() {
    return OFFSET_OF(Thread, heap_);
  }

  int32_t no_handle_scope_depth() const {
#if defined(DEBUG)
    return no_handle_scope_depth_;
#else
    return 0;
#endif
  }

  void IncrementNoHandleScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_handle_scope_depth_ < INT_MAX);
    no_handle_scope_depth_ += 1;
#endif
  }

  void DecrementNoHandleScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_handle_scope_depth_ > 0);
    no_handle_scope_depth_ -= 1;
#endif
  }

  HandleScope* top_handle_scope() const {
#if defined(DEBUG)
    return top_handle_scope_;
#else
    return 0;
#endif
  }

  void set_top_handle_scope(HandleScope* handle_scope) {
#if defined(DEBUG)
    top_handle_scope_ = handle_scope;
#endif
  }

  int32_t no_safepoint_scope_depth() const {
#if defined(DEBUG)
    return no_safepoint_scope_depth_;
#else
    return 0;
#endif
  }

  void IncrementNoSafepointScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_safepoint_scope_depth_ < INT_MAX);
    no_safepoint_scope_depth_ += 1;
#endif
  }

  void DecrementNoSafepointScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_safepoint_scope_depth_ > 0);
    no_safepoint_scope_depth_ -= 1;
#endif
  }

#define DEFINE_OFFSET_METHOD(type_name, member_name, expr, default_init_value) \
  static intptr_t member_name##offset() {                                      \
    return OFFSET_OF(Thread, member_name);                                     \
  }
CACHED_CONSTANTS_LIST(DEFINE_OFFSET_METHOD)
#undef DEFINE_OFFSET_METHOD

#define DEFINE_OFFSET_METHOD(name)                                             \
  static intptr_t name##_entry_point_offset() {                                \
    return OFFSET_OF(Thread, name##_entry_point_);                             \
  }
RUNTIME_ENTRY_LIST(DEFINE_OFFSET_METHOD)
#undef DEFINE_OFFSET_METHOD

#define DEFINE_OFFSET_METHOD(returntype, name, ...)                            \
  static intptr_t name##_entry_point_offset() {                                \
    return OFFSET_OF(Thread, name##_entry_point_);                             \
  }
LEAF_RUNTIME_ENTRY_LIST(DEFINE_OFFSET_METHOD)
#undef DEFINE_OFFSET_METHOD

  static bool CanLoadFromThread(const Object& object);
  static intptr_t OffsetFromThread(const Object& object);
  static bool ObjectAtOffset(intptr_t offset, Object* object);
  static intptr_t OffsetFromThread(const RuntimeEntry* runtime_entry);

  static const intptr_t kNoDeoptId = -1;
  static const intptr_t kDeoptIdStep = 2;
  static const intptr_t kDeoptIdBeforeOffset = 0;
  static const intptr_t kDeoptIdAfterOffset = 1;
  intptr_t deopt_id() const { return deopt_id_; }
  void set_deopt_id(int value) {
    ASSERT(value >= 0);
    deopt_id_ = value;
  }
  intptr_t GetNextDeoptId() {
    ASSERT(deopt_id_ != kNoDeoptId);
    const intptr_t id = deopt_id_;
    deopt_id_ += kDeoptIdStep;
    return id;
  }

  static intptr_t ToDeoptAfter(intptr_t deopt_id) {
    ASSERT(IsDeoptBefore(deopt_id));
    return deopt_id + kDeoptIdAfterOffset;
  }

  static bool IsDeoptBefore(intptr_t deopt_id) {
    return (deopt_id % kDeoptIdStep) == kDeoptIdBeforeOffset;
  }

  static bool IsDeoptAfter(intptr_t deopt_id) {
    return (deopt_id % kDeoptIdStep) == kDeoptIdAfterOffset;
  }

  LongJumpScope* long_jump_base() const { return long_jump_base_; }
  void set_long_jump_base(LongJumpScope* value) {
    long_jump_base_ = value;
  }

  uword vm_tag() const {
    return vm_tag_;
  }
  void set_vm_tag(uword tag) {
    vm_tag_ = tag;
  }
  static intptr_t vm_tag_offset() {
    return OFFSET_OF(Thread, vm_tag_);
  }

#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_ACCESSORS(object)                                \
  void set_reusable_##object##_handle_scope_active(bool value) {               \
    reusable_##object##_handle_scope_active_ = value;                          \
  }                                                                            \
  bool reusable_##object##_handle_scope_active() const {                       \
    return reusable_##object##_handle_scope_active_;                           \
  }
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_ACCESSORS)
#undef REUSABLE_HANDLE_SCOPE_ACCESSORS

  bool IsAnyReusableHandleScopeActive() const {
#define IS_REUSABLE_HANDLE_SCOPE_ACTIVE(object)                                \
    if (reusable_##object##_handle_scope_active_) return true;
    REUSABLE_HANDLE_LIST(IS_REUSABLE_HANDLE_SCOPE_ACTIVE)
    return false;
#undef IS_REUSABLE_HANDLE_SCOPE_ACTIVE
  }
#endif  // defined(DEBUG)

  void ClearReusableHandles();

#define REUSABLE_HANDLE(object)                                                \
  object& object##Handle() const {                                             \
    return *object##_handle_;                                                  \
  }
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE)
#undef REUSABLE_HANDLE

  RawGrowableObjectArray* pending_functions();

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  bool IsValidLocalHandle(Dart_Handle object) const;
  int CountLocalHandles() const;
  int ZoneSizeInBytes() const;
  void UnwindScopes(uword stack_marker);

  void InitVMConstants();

 private:
  template<class T> T* AllocateReusableHandle();

  OSThread* os_thread_;
  Isolate* isolate_;
  Heap* heap_;
  Zone* zone_;
  ApiLocalScope* api_reusable_scope_;
  ApiLocalScope* api_top_scope_;
  uword top_exit_frame_info_;
  StackResource* top_resource_;
  LongJumpScope* long_jump_base_;
  StoreBufferBlock* store_buffer_block_;
  int32_t no_callback_scope_depth_;
#if defined(DEBUG)
  HandleScope* top_handle_scope_;
  int32_t no_handle_scope_depth_;
  int32_t no_safepoint_scope_depth_;
#endif
  VMHandles reusable_handles_;

  // Compiler state:
  CHA* cha_;
  intptr_t deopt_id_;  // Compilation specific counter.
  uword vm_tag_;
  RawGrowableObjectArray* pending_functions_;

  // State that is cached in the TLS for fast access in generated code.
#define DECLARE_MEMBERS(type_name, member_name, expr, default_init_value)      \
  type_name member_name;
CACHED_CONSTANTS_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

#define DECLARE_MEMBERS(name)      \
  uword name##_entry_point_;
RUNTIME_ENTRY_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

#define DECLARE_MEMBERS(returntype, name, ...)      \
  uword name##_entry_point_;
LEAF_RUNTIME_ENTRY_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

  // Reusable handles support.
#define REUSABLE_HANDLE_FIELDS(object)                                         \
  object* object##_handle_;
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_FIELDS)
#undef REUSABLE_HANDLE_FIELDS

#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_VARIABLE(object)                                 \
  bool reusable_##object##_handle_scope_active_;
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_VARIABLE);
#undef REUSABLE_HANDLE_SCOPE_VARIABLE
#endif  // defined(DEBUG)

  Thread* next_;  // Used to chain the thread structures in an isolate.

  explicit Thread(Isolate* isolate);

  void StoreBufferRelease(
      StoreBuffer::ThresholdPolicy policy = StoreBuffer::kCheckThreshold);
  void StoreBufferAcquire();

  void set_zone(Zone* zone) {
    zone_ = zone;
  }

  void set_top_exit_frame_info(uword top_exit_frame_info) {
    top_exit_frame_info_ = top_exit_frame_info;
  }

  static void SetCurrent(Thread* current) {
    OSThread::SetCurrentTLS(reinterpret_cast<uword>(current));
  }

#define REUSABLE_FRIEND_DECLARATION(name)                                      \
  friend class Reusable##name##HandleScope;
REUSABLE_HANDLE_LIST(REUSABLE_FRIEND_DECLARATION)
#undef REUSABLE_FRIEND_DECLARATION

  friend class ApiZone;
  friend class Isolate;
  friend class Simulator;
  friend class StackZone;
  friend class ThreadRegistry;

  DISALLOW_COPY_AND_ASSIGN(Thread);
};


#if defined(TARGET_OS_WINDOWS)
// Clears the state of the current thread and frees the allocation.
void WindowsThreadCleanUp();
#endif


// Disable thread interrupts.
class DisableThreadInterruptsScope : public StackResource {
 public:
  explicit DisableThreadInterruptsScope(Thread* thread);
  ~DisableThreadInterruptsScope();
};

}  // namespace dart

#endif  // VM_THREAD_H_
