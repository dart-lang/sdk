// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ISOLATE_H_
#define VM_ISOLATE_H_

#include <limits.h>

#include "include/dart_api.h"
#include "vm/assert.h"
#include "vm/store_buffer.h"
#include "vm/timer.h"

namespace dart {

// Forward declarations.
class ApiState;
class BigintStore;
class CodeIndexTable;
class Debugger;
class HandleScope;
class Heap;
class LongJump;
class MessageQueue;
class Monitor;
class ObjectPointerVisitor;
class ObjectStore;
class RawContext;
class StackResource;
class StubCode;
class Zone;

class Isolate {
 public:
  ~Isolate();

  static inline Isolate* Current();
  static void SetCurrent(Isolate* isolate);

  static void InitOnce();
  static Isolate* Init();
  void Shutdown();

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor, bool validate_frames);

  StoreBufferBlock* store_buffer() { return &store_buffer_; }

  Dart_PostMessageCallback post_message_callback() const {
    return post_message_callback_;
  }
  void set_post_message_callback(Dart_PostMessageCallback value) {
    post_message_callback_ = value;
  }

  Dart_ClosePortCallback close_port_callback() const {
    return close_port_callback_;
  }
  void set_close_port_callback(Dart_ClosePortCallback value) {
    close_port_callback_ = value;
  }

  MessageQueue* message_queue() const { return message_queue_; }
  void set_message_queue(MessageQueue* value) { message_queue_ = value; }

  // The number of ports is only correct when read from the current
  // isolate. This value is not protected from being updated
  // concurrently.
  intptr_t num_ports() const { return num_ports_; }
  void increment_num_ports() {
    ASSERT(this == Isolate::Current());
    num_ports_++;
  }
  void decrement_num_ports() {
    ASSERT(this == Isolate::Current());
    num_ports_--;
  }

  intptr_t live_ports() const { return live_ports_; }
  void increment_live_ports() {
    ASSERT(this == Isolate::Current());
    live_ports_++;
  }
  void decrement_live_ports() {
    ASSERT(this == Isolate::Current());
    live_ports_--;
  }

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

  StackResource* top_resource() const { return top_resource_; }
  void set_top_resource(StackResource* value) { top_resource_ = value; }

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

  CodeIndexTable* code_index_table() const { return code_index_table_; }
  void set_code_index_table(CodeIndexTable* value) {
    code_index_table_ = value;
  }

  LongJump* long_jump_base() const { return long_jump_base_; }
  void set_long_jump_base(LongJump* value) { long_jump_base_ = value; }

  TimerList& timer_list() { return timer_list_; }

  Zone* current_zone() const { return current_zone_; }
  void set_current_zone(Zone* zone) { current_zone_ = zone; }
  static intptr_t current_zone_offset() {
    return OFFSET_OF(Isolate, current_zone_);
  }

  BigintStore* bigint_store() const { return bigint_store_; }
  void set_bigint_store(BigintStore* store) { bigint_store_ = store; }

  int32_t no_gc_scope_depth() const {
#if defined(DEBUG)
    return no_gc_scope_depth_;
#else
    return 0;
#endif
  }

  void IncrementNoGCScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_gc_scope_depth_ < INT_MAX);
    no_gc_scope_depth_ += 1;
#endif
  }

  void DecrementNoGCScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_gc_scope_depth_ > 0);
    no_gc_scope_depth_ -= 1;
#endif
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

  static void SetInitCallback(Dart_IsolateInitCallback callback);
  static Dart_IsolateInitCallback InitCallback();

  uword stack_limit_address() const {
    return reinterpret_cast<uword>(&stack_limit_);
  }

  void SetStackLimit(uword value);
  uword stack_limit() const { return stack_limit_; }

  void SetStackLimitFromCurrentTOS(uword isolate_stack_top);

  void ResetStackLimitAfterException() {
    stack_limit_ = stack_limit_on_overflow_exception_ + kStackSizeBuffer;
  }

  void AdjustStackLimitForException() {
    stack_limit_ = stack_limit_on_overflow_exception_;
  }

  void StandardRunLoop();

  intptr_t ast_node_id() const { return ast_node_id_; }
  void set_ast_node_id(int value) { ast_node_id_ = value; }

  Debugger* debugger() const { return debugger_; }

 private:
  Isolate();

  void PrintInvokedFunctions();

  static uword GetSpecifiedStackSize();

  static const uword kStackSizeBuffer = (128 * KB);
  static const uword kDefaultStackSize = (1 * MB);

  StoreBufferBlock store_buffer_;
  Monitor* monitor_;
  MessageQueue* message_queue_;
  Dart_PostMessageCallback post_message_callback_;
  Dart_ClosePortCallback close_port_callback_;
  intptr_t num_ports_;
  intptr_t live_ports_;
  Dart_Port main_port_;
  Heap* heap_;
  ObjectStore* object_store_;
  StackResource* top_resource_;
  RawContext* top_context_;
  Zone* current_zone_;
#if defined(DEBUG)
  int32_t no_gc_scope_depth_;
  int32_t no_handle_scope_depth_;
  HandleScope* top_handle_scope_;
#endif
  int32_t random_seed_;
  BigintStore* bigint_store_;
  uword top_exit_frame_info_;
  void* init_callback_data_;
  Dart_LibraryTagHandler library_tag_handler_;
  ApiState* api_state_;
  StubCode* stub_code_;
  CodeIndexTable* code_index_table_;
  Debugger* debugger_;
  LongJump* long_jump_base_;
  TimerList timer_list_;
  uword stack_limit_;
  uword stack_limit_on_overflow_exception_;
  intptr_t ast_node_id_;

  static Dart_IsolateInitCallback init_callback_;

  DISALLOW_COPY_AND_ASSIGN(Isolate);
};

}  // namespace dart

#if defined(TARGET_OS_LINUX)
#include "vm/isolate_linux.h"
#elif defined(TARGET_OS_MACOS)
#include "vm/isolate_macos.h"
#elif defined(TARGET_OS_WINDOWS)
#include "vm/isolate_win.h"
#else
#error Unknown target os.
#endif

#endif  // VM_ISOLATE_H_
