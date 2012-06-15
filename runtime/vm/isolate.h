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
class LongJump;
class MessageHandler;
class Mutex;
class ObjectPointerVisitor;
class ObjectStore;
class RawArray;
class RawContext;
class RawError;
class StackResource;
class StubCode;
class Zone;

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

  StoreBufferBlock* store_buffer() { return &store_buffer_; }

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

  int32_t random_seed() const { return random_seed_; }
  void set_random_seed(int32_t value) { random_seed_ = value; }

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

    kInterruptsMask = kApiInterrupt | kMessageInterrupt,
  };

  void ScheduleInterrupts(uword interrupt_bits);
  uword GetAndClearInterrupts();

  MessageHandler* message_handler() const { return message_handler_; }
  void set_message_handler(MessageHandler* value) { message_handler_ = value; }

  uword spawn_data() const { return spawn_data_; }
  void set_spawn_data(uword value) { spawn_data_ = value; }

  // Deprecate.
  intptr_t ast_node_id() const { return ast_node_id_; }
  void set_ast_node_id(int value) { ast_node_id_ = value; }

  intptr_t computation_id() const { return computation_id_; }
  void set_computation_id(int value) { computation_id_ = value; }

  RawArray* ic_data_array() const { return ic_data_array_; }
  void set_ic_data_array(RawArray* value) { ic_data_array_ = value; }

  Debugger* debugger() const { return debugger_; }

  static void SetCreateCallback(Dart_IsolateCreateCallback cback);
  static Dart_IsolateCreateCallback CreateCallback();

  static void SetInterruptCallback(Dart_IsolateInterruptCallback cback);
  static Dart_IsolateInterruptCallback InterruptCallback();

  GcPrologueCallbacks& gc_prologue_callbacks() {
    return gc_prologue_callbacks_;
  }

  GcEpilogueCallbacks& gc_epilogue_callbacks() {
    return gc_epilogue_callbacks_;
  }

 private:
  Isolate();

  void BuildName(const char* name_prefix);
  void PrintInvokedFunctions();

  static uword GetSpecifiedStackSize();

  static const intptr_t kStackSizeBuffer = (16 * KB);

  static ThreadLocalKey isolate_key;
  StoreBufferBlock store_buffer_;
  ClassTable class_table_;
  Dart_MessageNotifyCallback message_notify_callback_;
  char* name_;
  Dart_Port main_port_;
  Heap* heap_;
  ObjectStore* object_store_;
  RawContext* top_context_;
  int32_t random_seed_;
  uword top_exit_frame_info_;
  void* init_callback_data_;
  Dart_LibraryTagHandler library_tag_handler_;
  ApiState* api_state_;
  StubCode* stub_code_;
  Debugger* debugger_;
  LongJump* long_jump_base_;
  TimerList timer_list_;
  intptr_t ast_node_id_;  // Deprecate.
  intptr_t computation_id_;
  RawArray* ic_data_array_;
  Mutex* mutex_;  // protects stack_limit_ and saved_stack_limit_.
  uword stack_limit_;
  uword saved_stack_limit_;
  MessageHandler* message_handler_;
  uword spawn_data_;
  GcPrologueCallbacks gc_prologue_callbacks_;
  GcEpilogueCallbacks gc_epilogue_callbacks_;

  static Dart_IsolateCreateCallback create_callback_;
  static Dart_IsolateInterruptCallback interrupt_callback_;

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
