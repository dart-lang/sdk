// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate.h"

#include "include/dart_api.h"

#include "vm/assert.h"
#include "vm/bigint_store.h"
#include "vm/code_index_table.h"
#include "vm/compiler_stats.h"
#include "vm/dart_api_state.h"
#include "vm/debuginfo.h"
#include "vm/heap.h"
#include "vm/message_queue.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/port.h"
#include "vm/random.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/thread.h"
#include "vm/timer.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, report_invocation_count, false,
    "Count function invocations and report.");
DECLARE_FLAG(bool, generate_gdb_symbols);


Isolate::Isolate()
    : store_buffer_(),
      message_queue_(NULL),
      post_message_callback_(NULL),
      close_port_callback_(NULL),
      active_ports_(0),
      heap_(NULL),
      object_store_(NULL),
      top_resource_(NULL),
      top_context_(Context::null()),
      current_zone_(NULL),
#if defined(DEBUG)
      no_gc_scope_depth_(0),
      no_handle_scope_depth_(0),
      top_handle_scope_(NULL),
#endif
      random_seed_(Random::kDefaultRandomSeed),
      bigint_store_(NULL),
      top_exit_frame_info_(0),
      init_callback_data_(NULL),
      library_tag_handler_(NULL),
      api_state_(NULL),
      stub_code_(NULL),
      code_index_table_(NULL),
      long_jump_base_(NULL),
      timer_list_(),
      stack_limit_(0),
      stack_limit_on_overflow_exception_(0),
      ast_node_id_(AstNode::kNoId) {
}


Isolate::~Isolate() {
  delete message_queue_;
  delete heap_;
  delete object_store_;
  // Do not delete stack resources: top_resource_ and current_zone_.
  delete bigint_store_;
  delete api_state_;
  delete stub_code_;
  delete code_index_table_;
}


static bool StandardPostMessageCallback(Dart_Isolate dart_isolate,
                                        Dart_Port dest_port,
                                        Dart_Port reply_port,
                                        Dart_Message dart_message) {
  Isolate* isolate = reinterpret_cast<Isolate*>(dart_isolate);
  ASSERT(isolate != NULL);
  PortMessage* message = new PortMessage(dest_port, reply_port, dart_message);
  isolate->message_queue()->Enqueue(message);
  return true;
}


static void StandardClosePortCallback(Dart_Isolate dart_isolate,
                                      Dart_Port port) {
  // Remove the pending messages for this port.
  Isolate* isolate = reinterpret_cast<Isolate*>(dart_isolate);
  ASSERT(isolate != NULL);
  if (port == kCloseAllPorts) {
    isolate->message_queue()->FlushAll();
  } else {
    isolate->message_queue()->Flush(port);
  }
}


Isolate* Isolate::Init() {
  Isolate* result = new Isolate();
  ASSERT(result != NULL);

  // TODO(5411455): For now just set the recently created isolate as
  // the current isolate.
  SetCurrent(result);

  // Set up the isolate message queue.
  MessageQueue* queue = new MessageQueue();
  ASSERT(queue != NULL);
  result->set_message_queue(queue);
  result->set_post_message_callback(&StandardPostMessageCallback);
  result->set_close_port_callback(&StandardClosePortCallback);

  // Setup the Dart API state.
  ApiState* state = new ApiState();
  ASSERT(state != NULL);
  result->set_api_state(state);

  // Initialize stack top and limit in case we are running the isolate in the
  // main thread.
  // TODO(5411455): Need to figure out how to set the stack limit for the
  // main thread.
  result->SetStackLimitFromCurrentTOS(reinterpret_cast<uword>(&result));

  return result;
}


// TODO(5411455): Use flag to override default value and Validate the
// stack size by querying OS.
uword Isolate::GetSpecifiedStackSize() {
  uword stack_size = Isolate::kDefaultStackSize - Isolate::kStackSizeBuffer;
  return stack_size;
}


void Isolate::SetStackLimitFromCurrentTOS(uword stack_top_value) {
  SetStackLimit(stack_top_value - GetSpecifiedStackSize());
}


void Isolate::SetStackLimit(uword limit) {
  stack_limit_ = limit;
  stack_limit_on_overflow_exception_ = limit - kStackSizeBuffer;
}


static int MostCalledFunctionFirst(const Function* const* a,
                                   const Function* const* b) {
  if ((*a)->invocation_counter() > (*b)->invocation_counter()) {
    return -1;
  } else if ((*a)->invocation_counter() < (*b)->invocation_counter()) {
    return 1;
  } else {
    return 0;
  }
}


void Isolate::PrintInvokedFunctions() {
  ASSERT(this == Isolate::Current());
  Zone zone(this);
  HandleScope handle_scope(this);
  Library& library = Library::Handle();
  library = object_store()->registered_libraries();
  GrowableArray<const Function*> invoked_functions;
  while (!library.IsNull()) {
    Class& cls = Class::Handle();
    ClassDictionaryIterator iter(library);
    while (iter.HasNext()) {
      cls = iter.GetNextClass();
      const Array& functions = Array::Handle(cls.functions());
      // Class 'Dynamic' is allocated/initialized in a special way, leaving
      // the functions field NULL instead of empty.
      const int func_len = functions.IsNull() ? 0 : functions.Length();
      for (int j = 0; j < func_len; j++) {
        Function& function = Function::Handle();
        function ^= functions.At(j);
        if (function.invocation_counter() > 0) {
          invoked_functions.Add(&function);
        }
      }
    }
    library = library.next_registered();
  }
  invoked_functions.Sort(MostCalledFunctionFirst);
  for (int i = 0; i < invoked_functions.length(); i++) {
    OS::Print("%10d x %s\n",
        invoked_functions[i]->invocation_counter(),
        invoked_functions[i]->ToFullyQualifiedCString());
  }
}


void Isolate::Shutdown() {
  ASSERT(this == Isolate::Current());
  ASSERT(top_resource_ == NULL);
  ASSERT((heap_ == NULL) || heap_->Verify());

  // Close all the ports owned by this isolate.
  PortMap::ClosePorts();

  delete message_queue();
  set_message_queue(NULL);

  // Dump all accumalated timer data for the isolate.
  timer_list_.ReportTimers();
  if (FLAG_report_invocation_count) {
    PrintInvokedFunctions();
  }
  CompilerStats::Print();
  if (FLAG_generate_gdb_symbols) {
    DebugInfo::UnregisterAllSections();
  }

  // TODO(5411455): For now just make sure there are no current isolates
  // as we are shutting down the isolate.
  SetCurrent(NULL);
}


Dart_IsolateInitCallback Isolate::init_callback_ = NULL;


void Isolate::SetInitCallback(Dart_IsolateInitCallback callback) {
  init_callback_ = callback;
}


Dart_IsolateInitCallback Isolate::InitCallback() {
  return init_callback_;
}


void Isolate::StandardRunLoop() {
  ASSERT(long_jump_base() != NULL);
  ASSERT(post_message_callback() == &StandardPostMessageCallback);
  ASSERT(close_port_callback() == &StandardClosePortCallback);

  while (active_ports() > 0) {
    ASSERT(this == Isolate::Current());
    Zone zone(this);
    HandleScope handle_scope(this);

    PortMessage* message = message_queue()->Dequeue(0);
    if (message != NULL) {
      Dart_EnterScope();
      Dart_Handle result = Dart_HandleMessage(
          message->dest_port(), message->reply_port(), message->data());
      if (Dart_IsError(result)) {
        // TODO(turnidge): Consider passing this error out to
        // Dart_RunLoop so that the embedder can choose how to handle
        // it.
        fprintf(stderr, "%s\n", Dart_GetError(result));
        Dart_ExitScope();
        exit(255);
      }
      Dart_ExitScope();
      delete message;
    }
  }
}


void Isolate::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                  bool validate_frames) {
  ASSERT(visitor != NULL);

  // Visit objects in the object store.
  object_store()->VisitObjectPointers(visitor);

  // Visit objects in per isolate stubs.
  StubCode::VisitObjectPointers(visitor);

  // Visit objects in zones.
  current_zone()->VisitObjectPointers(visitor);

  // Iterate over all the stack frames and visit objects on the stack.
  StackFrameIterator frames_iterator(validate_frames);
  StackFrame* frame = frames_iterator.NextFrame();
  while (frame != NULL) {
    frame->VisitObjectPointers(visitor);
    frame = frames_iterator.NextFrame();
  }

  // Visit the dart api state for all local and persistent handles.
  if (api_state() != NULL) {
    api_state()->VisitObjectPointers(visitor);
  }

  // Visit all objects in the code index table.
  if (code_index_table() != NULL) {
    code_index_table()->VisitObjectPointers(visitor);
  }

  // Visit the top context which is stored in the isolate.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&top_context_));
}

}  // namespace dart
