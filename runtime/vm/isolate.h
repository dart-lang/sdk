// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ISOLATE_H_
#define VM_ISOLATE_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/class_table.h"
#include "platform/thread.h"
#include "vm/base_isolate.h"
#include "vm/gc_callbacks.h"
#include "vm/store_buffer.h"
#include "vm/timer.h"

namespace dart {

// Forward declarations.
class ApiState;
class CodeIndexTable;
class Debugger;
class HandleScope;
class HandleVisitor;
class Heap;
class ICData;
class LongJump;
class MessageHandler;
class Mutex;
class ObjectPointerVisitor;
class ObjectStore;
class RawArray;
class RawContext;
class RawDouble;
class RawMint;
class RawInteger;
class RawError;
class StackResource;
class StackZone;
class StubCode;


// Used by the deoptimization infrastructure to defer allocation of Double
// objects until frame is fully rewritten and GC is safe.
// See callers of Isolate::DeferDoubleMaterialization.
class DeferredDouble {
 public:
  DeferredDouble(double value, RawDouble** slot, DeferredDouble* next)
      : value_(value), slot_(slot), next_(next) { }

  double value() const { return value_; }
  RawDouble** slot() const { return slot_; }
  DeferredDouble* next() const { return next_; }

 private:
  const double value_;
  RawDouble** const slot_;
  DeferredDouble* const next_;

  DISALLOW_COPY_AND_ASSIGN(DeferredDouble);
};


class DeferredMint {
 public:
  DeferredMint(int64_t value, RawMint** slot, DeferredMint* next)
      : value_(value), slot_(slot), next_(next) { }

  int64_t value() const { return value_; }
  RawMint** slot() const { return slot_; }
  DeferredMint* next() const { return next_; }

 private:
  const int64_t value_;
  RawMint** const slot_;
  DeferredMint* const next_;

  DISALLOW_COPY_AND_ASSIGN(DeferredMint);
};


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

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor,
                           bool visit_prologue_weak_persistent_handles,
                           bool validate_frames);

  // Visits weak object pointers.
  void VisitWeakPersistentHandles(HandleVisitor* visit,
                                  bool visit_prologue_weak_persistent_handles);

  StoreBufferBlock* store_buffer_block() { return &store_buffer_block_; }
  static intptr_t store_buffer_block_offset() {
    return OFFSET_OF(Isolate, store_buffer_block_);
  }

  StoreBuffer* store_buffer() { return &store_buffer_; }

  ClassTable* class_table() { return &class_table_; }
  static intptr_t class_table_offset() {
    return OFFSET_OF(Isolate, class_table_);
  }

  Dart_MessageNotifyCallback message_notify_callback() const {
    return message_notify_callback_;
  }
  void set_message_notify_callback(Dart_MessageNotifyCallback value) {
    message_notify_callback_ = value;
  }

  const char* name() const { return name_; }

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

  enum {
    kApiInterrupt = 0x1,      // An interrupt from Dart_InterruptIsolate.
    kMessageInterrupt = 0x2,  // An interrupt to process an out of band message.
    kStoreBufferInterrupt = 0x4,  // An interrupt to process the store buffer.

    kInterruptsMask =
        kApiInterrupt |
        kMessageInterrupt |
        kStoreBufferInterrupt,
  };

  void ScheduleInterrupts(uword interrupt_bits);
  uword GetAndClearInterrupts();

  MessageHandler* message_handler() const { return message_handler_; }
  void set_message_handler(MessageHandler* value) { message_handler_ = value; }

  uword spawn_data() const { return spawn_data_; }
  void set_spawn_data(uword value) { spawn_data_ = value; }

  static const intptr_t kNoDeoptId = -1;
  intptr_t deopt_id() const { return deopt_id_; }
  void set_deopt_id(int value) {
    ASSERT(value >= 0);
    deopt_id_ = value;
  }
  intptr_t GetNextDeoptId() {
    ASSERT(deopt_id_ != kNoDeoptId);
    return deopt_id_++;
  }

  RawArray* ic_data_array() const { return ic_data_array_; }
  void set_ic_data_array(RawArray* value) { ic_data_array_ = value; }
  ICData* GetICDataForDeoptId(intptr_t deopt_id) const;

  Debugger* debugger() const { return debugger_; }

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

  intptr_t* deopt_cpu_registers_copy() const {
    return deopt_cpu_registers_copy_;
  }
  void set_deopt_cpu_registers_copy(intptr_t* value) {
    ASSERT((value == NULL) || (deopt_cpu_registers_copy_ == NULL));
    deopt_cpu_registers_copy_ = value;
  }
  double* deopt_xmm_registers_copy() const {
    return deopt_xmm_registers_copy_;
  }
  void set_deopt_xmm_registers_copy(double* value) {
    ASSERT((value == NULL) || (deopt_xmm_registers_copy_ == NULL));
    deopt_xmm_registers_copy_ = value;
  }
  intptr_t* deopt_frame_copy() const { return deopt_frame_copy_; }
  void SetDeoptFrameCopy(intptr_t* value, intptr_t size) {
    ASSERT((value == NULL) || (size > 0));
    ASSERT((value == NULL) || (deopt_frame_copy_ == NULL));
    deopt_frame_copy_ = value;
    deopt_frame_copy_size_ = size;
  }
  intptr_t deopt_frame_copy_size() const { return deopt_frame_copy_size_; }

  void DeferDoubleMaterialization(double value, RawDouble** slot) {
    deferred_doubles_ = new DeferredDouble(value, slot, deferred_doubles_);
  }

  void DeferMintMaterialization(int64_t value, RawMint** slot) {
    deferred_mints_ = new DeferredMint(value, slot, deferred_mints_);
  }

  DeferredDouble* DetachDeferredDoubles() {
    DeferredDouble* list = deferred_doubles_;
    deferred_doubles_ = NULL;
    return list;
  }

  DeferredMint* DetachDeferredMints() {
    DeferredMint* list = deferred_mints_;
    deferred_mints_ = NULL;
    return list;
  }

 private:
  Isolate();

  void BuildName(const char* name_prefix);
  void PrintInvokedFunctions();

  static uword GetSpecifiedStackSize();

  static const intptr_t kStackSizeBuffer = (16 * KB);

  static ThreadLocalKey isolate_key;
  StoreBufferBlock store_buffer_block_;
  StoreBuffer store_buffer_;
  ClassTable class_table_;
  Dart_MessageNotifyCallback message_notify_callback_;
  char* name_;
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
  LongJump* long_jump_base_;
  TimerList timer_list_;
  intptr_t deopt_id_;
  RawArray* ic_data_array_;
  Mutex* mutex_;  // protects stack_limit_ and saved_stack_limit_.
  uword stack_limit_;
  uword saved_stack_limit_;
  MessageHandler* message_handler_;
  uword spawn_data_;
  GcPrologueCallbacks gc_prologue_callbacks_;
  GcEpilogueCallbacks gc_epilogue_callbacks_;
  // Deoptimization support.
  intptr_t* deopt_cpu_registers_copy_;
  double* deopt_xmm_registers_copy_;
  intptr_t* deopt_frame_copy_;
  intptr_t deopt_frame_copy_size_;
  DeferredDouble* deferred_doubles_;
  DeferredMint* deferred_mints_;

  static Dart_IsolateCreateCallback create_callback_;
  static Dart_IsolateInterruptCallback interrupt_callback_;
  static Dart_IsolateUnhandledExceptionCallback unhandled_exception_callback_;
  static Dart_IsolateShutdownCallback shutdown_callback_;

  DISALLOW_COPY_AND_ASSIGN(Isolate);
};

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

}  // namespace dart

#endif  // VM_ISOLATE_H_
