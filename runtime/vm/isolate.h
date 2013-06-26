// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ISOLATE_H_
#define VM_ISOLATE_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/thread.h"
#include "vm/base_isolate.h"
#include "vm/class_table.h"
#include "vm/gc_callbacks.h"
#include "vm/handles.h"
#include "vm/megamorphic_cache_table.h"
#include "vm/store_buffer.h"
#include "vm/timer.h"

namespace dart {

// Forward declarations.
class AbstractType;
class ApiState;
class Array;
class Class;
class CodeIndexTable;
class Debugger;
class Field;
class Function;
class HandleScope;
class HandleVisitor;
class Heap;
class ICData;
class Instance;
class LongJump;
class MessageHandler;
class Mutex;
class Object;
class ObjectPointerVisitor;
class ObjectStore;
class RawInstance;
class RawArray;
class RawContext;
class RawDouble;
class RawMint;
class RawObject;
class RawInteger;
class RawError;
class RawFloat32x4;
class RawUint32x4;
class Simulator;
class StackResource;
class StackZone;
class StubCode;
class TypeArguments;
class TypeParameter;
class ObjectHistogram;


// Used by the deoptimization infrastructure to defer allocation of unboxed
// objects until frame is fully rewritten and GC is safe.
// Describes a stack slot that should be populated with a reference to the
// materialized object.
class DeferredSlot {
 public:
  DeferredSlot(RawInstance** slot, DeferredSlot* next)
      : slot_(slot), next_(next) { }
  virtual ~DeferredSlot() { }

  RawInstance** slot() const { return slot_; }
  DeferredSlot* next() const { return next_; }

  virtual void Materialize() = 0;

 private:
  RawInstance** const slot_;
  DeferredSlot* const next_;

  DISALLOW_COPY_AND_ASSIGN(DeferredSlot);
};


class DeferredDouble : public DeferredSlot {
 public:
  DeferredDouble(double value, RawInstance** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), value_(value) { }

  virtual void Materialize();

  double value() const { return value_; }

 private:
  const double value_;

  DISALLOW_COPY_AND_ASSIGN(DeferredDouble);
};


class DeferredMint : public DeferredSlot {
 public:
  DeferredMint(int64_t value, RawInstance** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), value_(value) { }

  virtual void Materialize();

  int64_t value() const { return value_; }

 private:
  const int64_t value_;

  DISALLOW_COPY_AND_ASSIGN(DeferredMint);
};


class DeferredFloat32x4 : public DeferredSlot {
 public:
  DeferredFloat32x4(simd128_value_t value, RawInstance** slot,
                    DeferredSlot* next)
      : DeferredSlot(slot, next), value_(value) { }

  virtual void Materialize();

  simd128_value_t value() const { return value_; }

 private:
  const simd128_value_t value_;

  DISALLOW_COPY_AND_ASSIGN(DeferredFloat32x4);
};


class DeferredUint32x4 : public DeferredSlot {
 public:
  DeferredUint32x4(simd128_value_t value, RawInstance** slot,
                   DeferredSlot* next)
      : DeferredSlot(slot, next), value_(value) { }

  virtual void Materialize();

  simd128_value_t value() const { return value_; }

 private:
  const simd128_value_t value_;

  DISALLOW_COPY_AND_ASSIGN(DeferredUint32x4);
};


// Describes a slot that contains a reference to an object that had its
// allocation removed by AllocationSinking pass.
// Object itself is described and materialized by DeferredObject.
class DeferredObjectRef : public DeferredSlot {
 public:
  DeferredObjectRef(intptr_t index, RawInstance** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), index_(index) { }

  virtual void Materialize();

  intptr_t index() const { return index_; }

 private:
  const intptr_t index_;

  DISALLOW_COPY_AND_ASSIGN(DeferredObjectRef);
};


// Describes an object which allocation was removed by AllocationSinking pass.
// Arguments for materialization are stored as a part of expression stack
// for the bottommost deoptimized frame so that GC could discover them.
// They will be removed from the stack at the very end of deoptimization.
class DeferredObject {
 public:
  DeferredObject(intptr_t field_count, intptr_t* args)
      : field_count_(field_count),
        args_(reinterpret_cast<RawObject**>(args)),
        object_(NULL) { }

  intptr_t ArgumentCount() const {
    return kFieldsStartIndex + kFieldEntrySize * field_count_;
  }

  RawInstance* object();

 private:
  enum {
    kClassIndex = 0,
    kFieldsStartIndex = kClassIndex + 1
  };

  enum {
    kFieldIndex = 0,
    kValueIndex,
    kFieldEntrySize,
  };

  // Materializes the object. Returns amount of values that were consumed
  // and should be removed from the expression stack at the very end of
  // deoptimization.
  void Materialize();

  RawObject* GetClass() const {
    return args_[kClassIndex];
  }

  RawObject* GetField(intptr_t index) const {
    return args_[kFieldsStartIndex + kFieldEntrySize * index + kFieldIndex];
  }

  RawObject* GetValue(intptr_t index) const {
    return args_[kFieldsStartIndex + kFieldEntrySize * index + kValueIndex];
  }

  // Amount of fields that have to be initialized.
  const intptr_t field_count_;

  // Pointer to the first materialization argument on the stack.
  // The first argument is Class of the instance to materialize followed by
  // Field, value pairs.
  RawObject** args_;

  // Object materialized from this description.
  const Instance* object_;

  DISALLOW_COPY_AND_ASSIGN(DeferredObject);
};

#define REUSABLE_HANDLE_LIST(V)                                                \
  V(Object)                                                                    \
  V(Array)                                                                     \
  V(String)                                                                    \
  V(Instance)                                                                  \
  V(Function)                                                                  \
  V(Field)                                                                     \
  V(Class)                                                                     \
  V(AbstractType)                                                              \
  V(TypeParameter)                                                             \
  V(TypeArguments)                                                             \

class Isolate : public BaseIsolate {
 public:
  ~Isolate();

  static inline Isolate* Current() {
    return reinterpret_cast<Isolate*>(Thread::GetThreadLocal(isolate_key));
  }

  static void SetCurrent(Isolate* isolate);

  static void InitOnce();
  static Isolate* Init(const char* name_prefix);
  void Shutdown();

  // Register a newly introduced class.
  void RegisterClass(const Class& cls);

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor,
                           bool visit_prologue_weak_persistent_handles,
                           bool validate_frames);

  // Visits weak object pointers.
  void VisitWeakPersistentHandles(HandleVisitor* visit,
                                  bool visit_prologue_weak_persistent_handles);

  StoreBuffer* store_buffer() { return &store_buffer_; }
  static intptr_t store_buffer_offset() {
    return OFFSET_OF(Isolate, store_buffer_);
  }

  ClassTable* class_table() { return &class_table_; }
  static intptr_t class_table_offset() {
    return OFFSET_OF(Isolate, class_table_);
  }

  ObjectHistogram* object_histogram() { return object_histogram_; }

  MegamorphicCacheTable* megamorphic_cache_table() {
    return &megamorphic_cache_table_;
  }

  Dart_MessageNotifyCallback message_notify_callback() const {
    return message_notify_callback_;
  }
  void set_message_notify_callback(Dart_MessageNotifyCallback value) {
    message_notify_callback_ = value;
  }

  const char* name() const { return name_; }

  int64_t start_time() const { return start_time_; }

  Dart_Port main_port() { return main_port_; }
  void set_main_port(Dart_Port port) {
    ASSERT(main_port_ == 0);  // Only set main port once.
    main_port_ = port;
  }

  Heap* heap() const { return heap_; }
  void set_heap(Heap* value) { heap_ = value; }
  static intptr_t heap_offset() { return OFFSET_OF(Isolate, heap_); }

  ObjectStore* object_store() const { return object_store_; }
  void set_object_store(ObjectStore* value) { object_store_ = value; }
  static intptr_t object_store_offset() {
    return OFFSET_OF(Isolate, object_store_);
  }

  RawContext* top_context() const { return top_context_; }
  void set_top_context(RawContext* value) { top_context_ = value; }
  static intptr_t top_context_offset() {
    return OFFSET_OF(Isolate, top_context_);
  }

  uword top_exit_frame_info() const { return top_exit_frame_info_; }
  void set_top_exit_frame_info(uword value) { top_exit_frame_info_ = value; }
  static intptr_t top_exit_frame_info_offset() {
    return OFFSET_OF(Isolate, top_exit_frame_info_);
  }

  ApiState* api_state() const { return api_state_; }
  void set_api_state(ApiState* value) { api_state_ = value; }

  StubCode* stub_code() const { return stub_code_; }
  void set_stub_code(StubCode* value) { stub_code_ = value; }

  LongJump* long_jump_base() const { return long_jump_base_; }
  void set_long_jump_base(LongJump* value) { long_jump_base_ = value; }

  TimerList& timer_list() { return timer_list_; }

  static intptr_t current_zone_offset() {
    return OFFSET_OF(Isolate, current_zone_);
  }

  void set_init_callback_data(void* value) {
    init_callback_data_ = value;
  }
  void* init_callback_data() const {
    return init_callback_data_;
  }

  Dart_LibraryTagHandler library_tag_handler() const {
    return library_tag_handler_;
  }
  void set_library_tag_handler(Dart_LibraryTagHandler value) {
    library_tag_handler_ = value;
  }

  void SetStackLimit(uword value);
  void SetStackLimitFromCurrentTOS(uword isolate_stack_top);

  uword stack_limit_address() const {
    return reinterpret_cast<uword>(&stack_limit_);
  }

  // The current stack limit.  This may be overwritten with a special
  // value to trigger interrupts.
  uword stack_limit() const { return stack_limit_; }

  // The true stack limit for this isolate.
  uword saved_stack_limit() const { return saved_stack_limit_; }

  static uword GetSpecifiedStackSize();

  static const intptr_t kStackSizeBuffer = (4 * KB * kWordSize);

  enum {
    kApiInterrupt = 0x1,      // An interrupt from Dart_InterruptIsolate.
    kMessageInterrupt = 0x2,  // An interrupt to process an out of band message.
    kStoreBufferInterrupt = 0x4,  // An interrupt to process the store buffer.
    kVmStatusInterrupt = 0x8,     // An interrupt to process a status request.

    kInterruptsMask =
        kApiInterrupt |
        kMessageInterrupt |
        kStoreBufferInterrupt |
        kVmStatusInterrupt,
  };

  enum IsolateRunState {
    kIsolateWaiting = 0,      // The isolate is waiting for code to execute.
    kIsolateRunning,          // The isolate is executing code.
  };

  void ScheduleInterrupts(uword interrupt_bits);
  uword GetAndClearInterrupts();

  bool MakeRunnable();
  void Run();

  MessageHandler* message_handler() const { return message_handler_; }
  void set_message_handler(MessageHandler* value) { message_handler_ = value; }

  bool is_runnable() const { return is_runnable_; }
  void set_is_runnable(bool value) { is_runnable_ = value; }

  IsolateRunState running_state() const { return running_state_; }
  void set_running_state(IsolateRunState value) { running_state_ = value; }

  uword spawn_data() const { return spawn_data_; }
  void set_spawn_data(uword value) { spawn_data_ = value; }

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

  Mutex* mutex() const { return mutex_; }

  Debugger* debugger() const { return debugger_; }

  Simulator* simulator() const { return simulator_; }
  void set_simulator(Simulator* value) { simulator_ = value; }

  GcPrologueCallbacks& gc_prologue_callbacks() {
    return gc_prologue_callbacks_;
  }

  GcEpilogueCallbacks& gc_epilogue_callbacks() {
    return gc_epilogue_callbacks_;
  }

  static void SetCreateCallback(Dart_IsolateCreateCallback cb) {
    create_callback_ = cb;
  }
  static Dart_IsolateCreateCallback CreateCallback() {
    return create_callback_;
  }

  static void SetInterruptCallback(Dart_IsolateInterruptCallback cb) {
    interrupt_callback_ = cb;
  }
  static Dart_IsolateInterruptCallback InterruptCallback() {
    return interrupt_callback_;
  }

  static void SetVmStatsCallback(Dart_IsolateInterruptCallback cb) {
    vmstats_callback_ = cb;
  }
  static Dart_IsolateInterruptCallback VmStatsCallback() {
    return vmstats_callback_;
  }

  static void SetUnhandledExceptionCallback(
      Dart_IsolateUnhandledExceptionCallback cb) {
    unhandled_exception_callback_ = cb;
  }
  static Dart_IsolateUnhandledExceptionCallback UnhandledExceptionCallback() {
    return unhandled_exception_callback_;
  }

  static void SetShutdownCallback(Dart_IsolateShutdownCallback cb) {
    shutdown_callback_ = cb;
  }
  static Dart_IsolateShutdownCallback ShutdownCallback() {
    return shutdown_callback_;
  }

  static void SetFileCallbacks(Dart_FileOpenCallback file_open,
                               Dart_FileReadCallback file_read,
                               Dart_FileWriteCallback file_write,
                               Dart_FileCloseCallback file_close) {
    file_open_callback_ = file_open;
    file_read_callback_ = file_read;
    file_write_callback_ = file_write;
    file_close_callback_ = file_close;
  }

  static Dart_FileOpenCallback file_open_callback() {
    return file_open_callback_;
  }
  static Dart_FileReadCallback file_read_callback() {
    return file_read_callback_;
  }
  static Dart_FileWriteCallback file_write_callback() {
    return file_write_callback_;
  }
  static Dart_FileCloseCallback file_close_callback() {
    return file_close_callback_;
  }

  intptr_t* deopt_cpu_registers_copy() const {
    return deopt_cpu_registers_copy_;
  }
  void set_deopt_cpu_registers_copy(intptr_t* value) {
    ASSERT((value == NULL) || (deopt_cpu_registers_copy_ == NULL));
    deopt_cpu_registers_copy_ = value;
  }
  fpu_register_t* deopt_fpu_registers_copy() const {
    return deopt_fpu_registers_copy_;
  }
  void set_deopt_fpu_registers_copy(fpu_register_t* value) {
    ASSERT((value == NULL) || (deopt_fpu_registers_copy_ == NULL));
    deopt_fpu_registers_copy_ = value;
  }
  intptr_t* deopt_frame_copy() const { return deopt_frame_copy_; }
  void SetDeoptFrameCopy(intptr_t* value, intptr_t size) {
    ASSERT((value == NULL) || (size > 0));
    ASSERT((value == NULL) || (deopt_frame_copy_ == NULL));
    deopt_frame_copy_ = value;
    deopt_frame_copy_size_ = size;
  }
  intptr_t deopt_frame_copy_size() const { return deopt_frame_copy_size_; }

  void PrepareForDeferredMaterialization(intptr_t count) {
    if (count > 0) {
      deferred_objects_ = new DeferredObject*[count];
      deferred_objects_count_ = count;
    }
  }

  void DeleteDeferredObjects() {
    for (intptr_t i = 0; i < deferred_objects_count_; i++) {
      delete deferred_objects_[i];
    }
    delete[] deferred_objects_;
    deferred_objects_ = NULL;
    deferred_objects_count_ = 0;
  }

  DeferredObject* GetDeferredObject(intptr_t idx) const {
    return deferred_objects_[idx];
  }

  void SetDeferredObjectAt(intptr_t idx, DeferredObject* object) {
    deferred_objects_[idx] = object;
  }

  intptr_t DeferredObjectsCount() const {
    return deferred_objects_count_;
  }

  void DeferMaterializedObjectRef(intptr_t idx, intptr_t* slot) {
    deferred_object_refs_ = new DeferredObjectRef(
        idx,
        reinterpret_cast<RawInstance**>(slot),
        deferred_object_refs_);
  }

  void DeferDoubleMaterialization(double value, RawDouble** slot) {
    deferred_boxes_ = new DeferredDouble(
        value,
        reinterpret_cast<RawInstance**>(slot),
        deferred_boxes_);
  }

  void DeferMintMaterialization(int64_t value, RawMint** slot) {
    deferred_boxes_ = new DeferredMint(
        value,
        reinterpret_cast<RawInstance**>(slot),
        deferred_boxes_);
  }

  void DeferFloat32x4Materialization(simd128_value_t value,
                                     RawFloat32x4** slot) {
    deferred_boxes_ = new DeferredFloat32x4(
        value,
        reinterpret_cast<RawInstance**>(slot),
        deferred_boxes_);
  }

  void DeferUint32x4Materialization(simd128_value_t value,
                                    RawUint32x4** slot) {
    deferred_boxes_ = new DeferredUint32x4(
        value,
        reinterpret_cast<RawInstance**>(slot),
        deferred_boxes_);
  }

  // Populate all deferred slots that contain boxes for double, mint, simd
  // values.
  void MaterializeDeferredBoxes();

  // Populate all slots containing references to objects which allocations
  // were eliminated by AllocationSinking pass.
  void MaterializeDeferredObjects();

  static char* GetStatus(const char* request);

  intptr_t BlockClassFinalization() {
    ASSERT(defer_finalization_count_ >= 0);
    return defer_finalization_count_++;
  }

  intptr_t UnblockClassFinalization() {
    ASSERT(defer_finalization_count_ > 0);
    return defer_finalization_count_--;
  }

  bool AllowClassFinalization() {
    ASSERT(defer_finalization_count_ >= 0);
    return defer_finalization_count_ == 0;
  }

 private:
  Isolate();

  void BuildName(const char* name_prefix);
  void PrintInvokedFunctions();

  static bool FetchStacktrace();
  static bool FetchStackFrameDetails();
  char* GetStatusDetails();
  char* GetStatusStacktrace();
  char* GetStatusStackFrame(intptr_t index);
  char* DoStacktraceInterrupt(Dart_IsolateInterruptCallback cb);
  template<class T> T* AllocateReusableHandle();

  static ThreadLocalKey isolate_key;
  StoreBuffer store_buffer_;
  ClassTable class_table_;
  MegamorphicCacheTable megamorphic_cache_table_;
  Dart_MessageNotifyCallback message_notify_callback_;
  char* name_;
  int64_t start_time_;
  Dart_Port main_port_;
  Heap* heap_;
  ObjectStore* object_store_;
  RawContext* top_context_;
  uword top_exit_frame_info_;
  void* init_callback_data_;
  Dart_LibraryTagHandler library_tag_handler_;
  ApiState* api_state_;
  StubCode* stub_code_;
  Debugger* debugger_;
  Simulator* simulator_;
  LongJump* long_jump_base_;
  TimerList timer_list_;
  intptr_t deopt_id_;
  Mutex* mutex_;  // protects stack_limit_ and saved_stack_limit_.
  uword stack_limit_;
  uword saved_stack_limit_;
  MessageHandler* message_handler_;
  uword spawn_data_;
  bool is_runnable_;
  IsolateRunState running_state_;
  GcPrologueCallbacks gc_prologue_callbacks_;
  GcEpilogueCallbacks gc_epilogue_callbacks_;
  intptr_t defer_finalization_count_;

  // Deoptimization support.
  intptr_t* deopt_cpu_registers_copy_;
  fpu_register_t* deopt_fpu_registers_copy_;
  intptr_t* deopt_frame_copy_;
  intptr_t deopt_frame_copy_size_;
  DeferredSlot* deferred_boxes_;
  DeferredSlot* deferred_object_refs_;

  intptr_t deferred_objects_count_;
  DeferredObject** deferred_objects_;

  // Status support.
  char* stacktrace_;
  intptr_t stack_frame_index_;
  ObjectHistogram* object_histogram_;

  // Reusable handles support.
#define REUSABLE_HANDLE_FIELDS(object)                                         \
  object* object##_handle_;                                                    \

  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_FIELDS)
#undef REUSABLE_HANDLE_FIELDS
  VMHandles reusable_handles_;

  static Dart_IsolateCreateCallback create_callback_;
  static Dart_IsolateInterruptCallback interrupt_callback_;
  static Dart_IsolateUnhandledExceptionCallback unhandled_exception_callback_;
  static Dart_IsolateShutdownCallback shutdown_callback_;
  static Dart_FileOpenCallback file_open_callback_;
  static Dart_FileReadCallback file_read_callback_;
  static Dart_FileWriteCallback file_write_callback_;
  static Dart_FileCloseCallback file_close_callback_;
  static Dart_IsolateInterruptCallback vmstats_callback_;

  friend class ReusableHandleScope;
  DISALLOW_COPY_AND_ASSIGN(Isolate);
};

// The class ReusableHandleScope is used in regions of the
// virtual machine where isolate specific reusable handles are used.
// This class asserts that we do not add code that will result in recursive
// uses of reusable handles.
// It is used as follows:
// {
//   ReusableHandleScope reused_handles(isolate);
//   ....
//   .....
//   code that uses isolate specific reusable handles.
//   Array& funcs = reused_handles.ArrayHandle();
//   ....
// }
#if defined(DEBUG)
class ReusableHandleScope : public StackResource {
 public:
  explicit ReusableHandleScope(Isolate* isolate)
      : StackResource(isolate), isolate_(isolate) {
    ASSERT(!isolate->reusable_handle_scope_active());
    isolate->set_reusable_handle_scope_active(true);
  }
  ReusableHandleScope()
      : StackResource(Isolate::Current()), isolate_(Isolate::Current()) {
    ASSERT(!isolate()->reusable_handle_scope_active());
    isolate()->set_reusable_handle_scope_active(true);
  }
  ~ReusableHandleScope() {
    ASSERT(isolate()->reusable_handle_scope_active());
    isolate()->set_reusable_handle_scope_active(false);
    ResetHandles();
  }

#define REUSABLE_HANDLE_ACCESSORS(object)                                      \
  object& object##Handle() {                                                   \
    ASSERT(isolate_->object##_handle_ != NULL);                                \
    return *isolate_->object##_handle_;                                        \
  }                                                                            \

  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_ACCESSORS)
#undef REUSABLE_HANDLE_ACCESSORS

 private:
  void ResetHandles();
  Isolate* isolate_;
  DISALLOW_COPY_AND_ASSIGN(ReusableHandleScope);
};
#else
class ReusableHandleScope : public ValueObject {
 public:
  explicit ReusableHandleScope(Isolate* isolate) : isolate_(isolate) {
  }
  ReusableHandleScope() : isolate_(Isolate::Current()) {
  }
  ~ReusableHandleScope() {
    ResetHandles();
  }

#define REUSABLE_HANDLE_ACCESSORS(object)                                      \
  object& object##Handle() {                                                   \
    ASSERT(isolate_->object##_handle_ != NULL);                                \
    return *isolate_->object##_handle_;                                        \
  }                                                                            \

  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_ACCESSORS)
#undef REUSABLE_HANDLE_ACCESSORS

 private:
  void ResetHandles();
  Isolate* isolate_;
  DISALLOW_COPY_AND_ASSIGN(ReusableHandleScope);
};
#endif  // defined(DEBUG)



// When we need to execute code in an isolate, we use the
// StartIsolateScope.
class StartIsolateScope {
 public:
  explicit StartIsolateScope(Isolate* new_isolate)
      : new_isolate_(new_isolate), saved_isolate_(Isolate::Current()) {
    ASSERT(new_isolate_ != NULL);
    if (saved_isolate_ != new_isolate_) {
      ASSERT(Isolate::Current() == NULL);
      Isolate::SetCurrent(new_isolate_);
      new_isolate_->SetStackLimitFromCurrentTOS(reinterpret_cast<uword>(this));
    }
  }

  ~StartIsolateScope() {
    if (saved_isolate_ != new_isolate_) {
      new_isolate_->SetStackLimit(~static_cast<uword>(0));
      Isolate::SetCurrent(saved_isolate_);
    }
  }

 private:
  Isolate* new_isolate_;
  Isolate* saved_isolate_;

  DISALLOW_COPY_AND_ASSIGN(StartIsolateScope);
};

// When we need to temporarily become another isolate, we use the
// SwitchIsolateScope.  It is not permitted to run dart code while in
// a SwitchIsolateScope.
class SwitchIsolateScope {
 public:
  explicit SwitchIsolateScope(Isolate* new_isolate)
      : new_isolate_(new_isolate),
        saved_isolate_(Isolate::Current()),
        saved_stack_limit_(saved_isolate_
                           ? saved_isolate_->saved_stack_limit() : 0) {
    if (saved_isolate_ != new_isolate_) {
      Isolate::SetCurrent(new_isolate_);
      if (new_isolate_ != NULL) {
        // Don't allow dart code to execute.
        new_isolate_->SetStackLimit(~static_cast<uword>(0));
      }
    }
  }

  ~SwitchIsolateScope() {
    if (saved_isolate_ != new_isolate_) {
      Isolate::SetCurrent(saved_isolate_);
      if (saved_isolate_ != NULL) {
        saved_isolate_->SetStackLimit(saved_stack_limit_);
      }
    }
  }

 private:
  Isolate* new_isolate_;
  Isolate* saved_isolate_;
  uword saved_stack_limit_;

  DISALLOW_COPY_AND_ASSIGN(SwitchIsolateScope);
};


class IsolateSpawnState {
 public:
  IsolateSpawnState(const Function& func, const Function& callback_func);
  explicit IsolateSpawnState(const char* script_url);
  ~IsolateSpawnState();

  Isolate* isolate() const { return isolate_; }
  void set_isolate(Isolate* value) { isolate_ = value; }
  char* script_url() const { return script_url_; }
  char* library_url() const { return library_url_; }
  char* function_name() const { return function_name_; }
  char* exception_callback_name() const { return exception_callback_name_; }

  RawObject* ResolveFunction();
  void Cleanup();

 private:
  Isolate* isolate_;
  char* script_url_;
  char* library_url_;
  char* function_name_;
  char* exception_callback_name_;
};


class IsolateRunStateManager : public StackResource {
 public:
  explicit IsolateRunStateManager()
      : StackResource(Isolate::Current()),
        saved_state_(Isolate::kIsolateWaiting) {
    saved_state_ = reinterpret_cast<Isolate*>(isolate())->running_state();
  }

  virtual ~IsolateRunStateManager() {
    reinterpret_cast<Isolate*>(isolate())->set_running_state(saved_state_);
  }

  void SetRunState(Isolate::IsolateRunState run_state) {
    reinterpret_cast<Isolate*>(isolate())->set_running_state(run_state);
  }

 private:
  Isolate::IsolateRunState saved_state_;

  DISALLOW_COPY_AND_ASSIGN(IsolateRunStateManager);
};

}  // namespace dart

#endif  // VM_ISOLATE_H_
