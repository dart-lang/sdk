// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stack_trace.h"

#include "vm/dart_api_impl.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/frontend/bytecode_reader.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

// Keep in sync with
// sdk/lib/async/stream_controller.dart:_StreamController._STATE_SUBSCRIBED.
const intptr_t kStreamController_StateSubscribed = 1;

ClosurePtr FindClosureInFrame(ObjectPtr* last_object_in_caller,
                              const Function& function,
                              bool is_interpreted) {
  NoSafepointScope nsp;

  // The callee has function signature
  //   :async_op([result, exception, stack])
  // So we are guaranteed to
  //   a) have only tagged arguments on the stack until we find the :async_op
  //      closure, and
  //   b) find the async closure.
  auto& closure = Closure::Handle();
  for (intptr_t i = 0; i < 4; i++) {
    // KBC builds the stack upwards instead of the usual downwards stack.
    ObjectPtr arg = last_object_in_caller[(is_interpreted ? -i : i)];
    if (arg->IsHeapObject() && arg->GetClassId() == kClosureCid) {
      closure = Closure::RawCast(arg);
      if (closure.function() == function.raw()) {
        return closure.raw();
      }
    }
  }
  UNREACHABLE();
}

// Find current yield index from async closure.
// Async closures contains a variable, :await_jump_var that holds the index into
// async wrapper.
intptr_t GetYieldIndex(const Closure& receiver_closure) {
  const auto& function = Function::Handle(receiver_closure.function());
  if (!function.IsAsyncClosure() && !function.IsAsyncGenClosure()) {
    return PcDescriptorsLayout::kInvalidYieldIndex;
  }
  const auto& await_jump_var =
      Object::Handle(Context::Handle(receiver_closure.context())
                         .At(Context::kAwaitJumpVarIndex));
  ASSERT(await_jump_var.IsSmi());
  return Smi::Cast(await_jump_var).Value();
}

intptr_t FindPcOffset(const PcDescriptors& pc_descs, intptr_t yield_index) {
  if (yield_index == PcDescriptorsLayout::kInvalidYieldIndex) {
    return 0;
  }
  PcDescriptors::Iterator iter(pc_descs, PcDescriptorsLayout::kAnyKind);
  while (iter.MoveNext()) {
    if (iter.YieldIndex() == yield_index) {
      return iter.PcOffset();
    }
  }
  UNREACHABLE();  // If we cannot find it we have a bug.
}

#if !defined(DART_PRECOMPILED_RUNTIME)
intptr_t FindPcOffset(const Bytecode& bytecode, intptr_t yield_index) {
  if (yield_index == PcDescriptorsLayout::kInvalidYieldIndex) {
    return 0;
  }
  if (!bytecode.HasSourcePositions()) {
    return 0;
  }
  intptr_t last_yield_point = 0;
  kernel::BytecodeSourcePositionsIterator iter(Thread::Current()->zone(),
                                               bytecode);
  while (iter.MoveNext()) {
    if (iter.IsYieldPoint()) {
      last_yield_point++;
    }
    if (last_yield_point == yield_index) {
      return iter.PcOffset();
    }
  }
  UNREACHABLE();  // If we cannot find it we have a bug.
}
#endif

// Helper class for finding the closure of the caller.
// This is done via the _AsyncAwaitCompleter which holds a
// FutureResultOrListeners which in turn holds a callback.
class CallerClosureFinder {
 public:
  // Instance caches library and field references.
  // This way we don't have to do the look-ups for every frame in the stack.
  explicit CallerClosureFinder(Zone* zone)
      : receiver_context_(Context::Handle(zone)),
        receiver_function_(Function::Handle(zone)),
        parent_function_(Function::Handle(zone)),
        context_entry_(Object::Handle(zone)),
        is_sync(Object::Handle(zone)),
        future_(Object::Handle(zone)),
        listener_(Object::Handle(zone)),
        callback_(Object::Handle(zone)),
        controller_(Object::Handle(zone)),
        state_(Object::Handle(zone)),
        var_data_(Object::Handle(zone)),
        callback_instance_(Object::Handle(zone)),
        future_impl_class(Class::Handle(zone)),
        async_await_completer_class(Class::Handle(zone)),
        future_listener_class(Class::Handle(zone)),
        async_start_stream_controller_class(Class::Handle(zone)),
        stream_controller_class(Class::Handle(zone)),
        async_stream_controller_class(Class::Handle(zone)),
        controller_subscription_class(Class::Handle(zone)),
        buffering_stream_subscription_class(Class::Handle(zone)),
        stream_iterator_class(Class::Handle(zone)),
        completer_is_sync_field(Field::Handle(zone)),
        completer_future_field(Field::Handle(zone)),
        future_result_or_listeners_field(Field::Handle(zone)),
        callback_field(Field::Handle(zone)),
        controller_controller_field(Field::Handle(zone)),
        var_data_field(Field::Handle(zone)),
        state_field(Field::Handle(zone)),
        on_data_field(Field::Handle(zone)),
        state_data_field(Field::Handle(zone)),
        future_timeout_method_(Function::Handle(zone)) {
    const auto& async_lib = Library::Handle(zone, Library::AsyncLibrary());
    // Look up classes:
    // - async:
    future_impl_class =
        async_lib.LookupClassAllowPrivate(Symbols::FutureImpl());
    ASSERT(!future_impl_class.IsNull());
    async_await_completer_class =
        async_lib.LookupClassAllowPrivate(Symbols::_AsyncAwaitCompleter());
    ASSERT(!async_await_completer_class.IsNull());
    future_listener_class =
        async_lib.LookupClassAllowPrivate(Symbols::_FutureListener());
    ASSERT(!future_listener_class.IsNull());
    // - async*:
    async_start_stream_controller_class = async_lib.LookupClassAllowPrivate(
        Symbols::_AsyncStarStreamController());
    ASSERT(!async_start_stream_controller_class.IsNull());
    stream_controller_class =
        async_lib.LookupClassAllowPrivate(Symbols::_StreamController());
    ASSERT(!stream_controller_class.IsNull());
    async_stream_controller_class =
        async_lib.LookupClassAllowPrivate(Symbols::_AsyncStreamController());
    ASSERT(!async_stream_controller_class.IsNull());
    controller_subscription_class =
        async_lib.LookupClassAllowPrivate(Symbols::_ControllerSubscription());
    ASSERT(!controller_subscription_class.IsNull());
    buffering_stream_subscription_class = async_lib.LookupClassAllowPrivate(
        Symbols::_BufferingStreamSubscription());
    ASSERT(!buffering_stream_subscription_class.IsNull());
    stream_iterator_class =
        async_lib.LookupClassAllowPrivate(Symbols::_StreamIterator());
    ASSERT(!stream_iterator_class.IsNull());

    // Look up fields:
    // - async:
    completer_is_sync_field =
        async_await_completer_class.LookupFieldAllowPrivate(Symbols::isSync());
    ASSERT(!completer_is_sync_field.IsNull());
    completer_future_field =
        async_await_completer_class.LookupFieldAllowPrivate(Symbols::_future());
    ASSERT(!completer_future_field.IsNull());
    future_result_or_listeners_field =
        future_impl_class.LookupFieldAllowPrivate(
            Symbols::_resultOrListeners());
    ASSERT(!future_result_or_listeners_field.IsNull());
    callback_field =
        future_listener_class.LookupFieldAllowPrivate(Symbols::callback());
    ASSERT(!callback_field.IsNull());
    // - async*:
    controller_controller_field =
        async_start_stream_controller_class.LookupFieldAllowPrivate(
            Symbols::controller());
    ASSERT(!controller_controller_field.IsNull());
    state_field =
        stream_controller_class.LookupFieldAllowPrivate(Symbols::_state());
    ASSERT(!state_field.IsNull());
    var_data_field =
        stream_controller_class.LookupFieldAllowPrivate(Symbols::_varData());
    ASSERT(!var_data_field.IsNull());
    on_data_field = buffering_stream_subscription_class.LookupFieldAllowPrivate(
        Symbols::_onData());
    ASSERT(!on_data_field.IsNull());
    state_data_field =
        stream_iterator_class.LookupFieldAllowPrivate(Symbols::_stateData());
    ASSERT(!state_data_field.IsNull());

    // Functions:
    future_timeout_method_ =
        future_impl_class.LookupFunction(Symbols::timeout());
    ASSERT(!future_timeout_method_.IsNull());
  }

  ClosurePtr GetCallerInFutureImpl(const Object& future_) {
    ASSERT(!future_.IsNull());
    ASSERT(future_.GetClassId() == future_impl_class.id());

    listener_ =
        Instance::Cast(future_).GetField(future_result_or_listeners_field);
    if (listener_.GetClassId() != future_listener_class.id()) {
      return Closure::null();
    }

    callback_ = Instance::Cast(listener_).GetField(callback_field);
    // This happens for e.g.: await f().catchError(..);
    if (callback_.IsNull()) {
      return Closure::null();
    }
    ASSERT(callback_.IsClosure());

    return Closure::Cast(callback_).raw();
  }

  ClosurePtr FindCallerInAsyncClosure(const Context& receiver_context) {
    context_entry_ = receiver_context.At(Context::kAsyncCompleterIndex);
    ASSERT(context_entry_.IsInstance());
    ASSERT(context_entry_.GetClassId() == async_await_completer_class.id());

    const Instance& completer = Instance::Cast(context_entry_);
    future_ = completer.GetField(completer_future_field);
    return GetCallerInFutureImpl(future_);
  }

  ClosurePtr FindCallerInAsyncGenClosure(const Context& receiver_context) {
    context_entry_ = receiver_context.At(Context::kControllerIndex);
    ASSERT(context_entry_.IsInstance());
    ASSERT(context_entry_.GetClassId() ==
           async_start_stream_controller_class.id());

    const Instance& controller = Instance::Cast(context_entry_);
    controller_ = controller.GetField(controller_controller_field);
    ASSERT(!controller_.IsNull());
    ASSERT(controller_.GetClassId() == async_stream_controller_class.id());

    state_ = Instance::Cast(controller_).GetField(state_field);
    ASSERT(state_.IsSmi());
    if (Smi::Cast(state_).Value() != kStreamController_StateSubscribed) {
      return Closure::null();
    }

    // _StreamController._varData
    var_data_ = Instance::Cast(controller_).GetField(var_data_field);
    ASSERT(var_data_.GetClassId() == controller_subscription_class.id());

    // _ControllerSubscription<T>/_BufferingStreamSubscription.<T>_onData
    callback_ = Instance::Cast(var_data_).GetField(on_data_field);
    ASSERT(callback_.IsClosure());

    // If this is not the "_StreamIterator._onData" tear-off, we return the
    // callback we found.
    receiver_function_ = Closure::Cast(callback_).function();
    if (!receiver_function_.IsImplicitInstanceClosureFunction() ||
        receiver_function_.Owner() != stream_iterator_class.raw()) {
      return Closure::Cast(callback_).raw();
    }

    // All implicit closure functions (tear-offs) have the "this" receiver
    // captured.
    receiver_context_ = Closure::Cast(callback_).context();
    ASSERT(receiver_context_.num_variables() == 1);
    callback_instance_ = receiver_context_.At(0);
    ASSERT(callback_instance_.IsInstance());

    // If the async* stream is await-for'd:
    if (callback_instance_.GetClassId() == stream_iterator_class.id()) {
      // _StreamIterator._stateData
      future_ = Instance::Cast(callback_instance_).GetField(state_data_field);
      return GetCallerInFutureImpl(future_);
    }

    UNREACHABLE();  // If no onData is found we have a bug.
  }

  ClosurePtr FindCaller(const Closure& receiver_closure) {
    receiver_function_ = receiver_closure.function();
    receiver_context_ = receiver_closure.context();

    if (receiver_function_.IsAsyncClosure()) {
      return FindCallerInAsyncClosure(receiver_context_);
    } else if (receiver_function_.IsAsyncGenClosure()) {
      return FindCallerInAsyncGenClosure(receiver_context_);
    } else if (receiver_function_.IsLocalFunction()) {
      parent_function_ = receiver_function_.parent_function();
      if (parent_function_.recognized_kind() ==
          MethodRecognizer::kFutureTimeout) {
        context_entry_ = receiver_context_.At(Context::kChainedFutureIndex);
        return GetCallerInFutureImpl(context_entry_);
      }
    }

    return Closure::null();
  }

  bool IsRunningAsync(const Closure& receiver_closure) {
    receiver_function_ = receiver_closure.function();
    receiver_context_ = receiver_closure.context();

    // The async* functions are never started synchronously, they start running
    // after the first `listen()` call to its returned `Stream`.
    if (receiver_function_.IsAsyncGenClosure()) {
      return true;
    }
    ASSERT(receiver_function_.IsAsyncClosure());

    context_entry_ = receiver_context_.At(Context::kAsyncCompleterIndex);
    ASSERT(context_entry_.IsInstance());
    ASSERT(context_entry_.GetClassId() == async_await_completer_class.id());

    const Instance& completer = Instance::Cast(context_entry_);
    is_sync = completer.GetField(completer_is_sync_field);
    ASSERT(!is_sync.IsNull());
    ASSERT(is_sync.IsBool());
    // _AsyncAwaitCompleter.isSync indicates whether the future should be
    // completed async. or sync., based on whether it has yielded yet.
    // isSync is true when the :async_op is running async.
    return Bool::Cast(is_sync).value();
  }

 private:
  Context& receiver_context_;
  Function& receiver_function_;
  Function& parent_function_;

  Object& context_entry_;
  Object& is_sync;
  Object& future_;
  Object& listener_;
  Object& callback_;
  Object& controller_;
  Object& state_;
  Object& var_data_;
  Object& callback_instance_;

  Class& future_impl_class;
  Class& async_await_completer_class;
  Class& future_listener_class;
  Class& async_start_stream_controller_class;
  Class& stream_controller_class;
  Class& async_stream_controller_class;
  Class& controller_subscription_class;
  Class& buffering_stream_subscription_class;
  Class& stream_iterator_class;

  Field& completer_is_sync_field;
  Field& completer_future_field;
  Field& future_result_or_listeners_field;
  Field& callback_field;
  Field& controller_controller_field;
  Field& var_data_field;
  Field& state_field;
  Field& on_data_field;
  Field& state_data_field;

  Function& future_timeout_method_;
};

void StackTraceUtils::CollectFramesLazy(
    Thread* thread,
    const GrowableObjectArray& code_array,
    const GrowableObjectArray& pc_offset_array,
    int skip_frames,
    std::function<void(StackFrame*)>* on_sync_frames,
    bool* has_async) {
  if (has_async != nullptr) {
    *has_async = false;
  }
  Zone* zone = thread->zone();
  DartFrameIterator frames(thread, StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();

  // If e.g. the isolate is paused before executing anything, we might not get
  // any frames at all. Bail:
  if (frame == nullptr) {
    return;
  }

  auto& function = Function::Handle(zone);
  auto& code = Code::Handle(zone);
  auto& bytecode = Bytecode::Handle(zone);
  auto& offset = Smi::Handle(zone);

  auto& closure = Closure::Handle(zone);
  CallerClosureFinder caller_closure_finder(zone);
  auto& pc_descs = PcDescriptors::Handle();

  for (; frame != nullptr; frame = frames.NextFrame()) {
    if (skip_frames > 0) {
      skip_frames--;
      continue;
    }

    if (frame->is_interpreted()) {
      bytecode = frame->LookupDartBytecode();
      ASSERT(!bytecode.IsNull());
      function = bytecode.function();
      if (function.IsNull()) {
        continue;
      }
      RELEASE_ASSERT(function.raw() == frame->LookupDartFunction());
    } else {
      function = frame->LookupDartFunction();
    }

    // Add the current synchronous frame.
    if (frame->is_interpreted()) {
      code_array.Add(bytecode);
      const intptr_t pc_offset = frame->pc() - bytecode.PayloadStart();
      ASSERT(pc_offset > 0 && pc_offset <= bytecode.Size());
      offset = Smi::New(pc_offset);
    } else {
      code = frame->LookupDartCode();
      ASSERT(function.raw() == code.function());
      code_array.Add(code);
      const intptr_t pc_offset = frame->pc() - code.PayloadStart();
      ASSERT(pc_offset > 0 && pc_offset <= code.Size());
      offset = Smi::New(pc_offset);
    }
    pc_offset_array.Add(offset);
    if (on_sync_frames != nullptr) {
      (*on_sync_frames)(frame);
    }

    // Either continue the loop (sync-async case) or find all await'ers and
    // return.
    if (!function.IsNull() &&
        (function.IsAsyncClosure() || function.IsAsyncGenClosure())) {
      if (has_async != nullptr) {
        *has_async = true;
      }

      // Next, look up caller's closure on the stack and walk backwards through
      // the yields.
      ObjectPtr* last_caller_obj =
          reinterpret_cast<ObjectPtr*>(frame->GetCallerSp());
      closure = FindClosureInFrame(last_caller_obj, function,
                                   frame->is_interpreted());

      // If this async function hasn't yielded yet, we're still dealing with a
      // normal stack. Continue to next frame as usual.
      if (!caller_closure_finder.IsRunningAsync(closure)) {
        continue;
      }

      // Inject async suspension marker.
      code_array.Add(StubCode::AsynchronousGapMarker());
      offset = Smi::New(0);
      pc_offset_array.Add(offset);

      // Skip: Already handled this frame's function above.
      closure = caller_closure_finder.FindCaller(closure);

      for (; !closure.IsNull();
           closure = caller_closure_finder.FindCaller(closure)) {
        function = closure.function();
        // In hot-reload-test-mode we sometimes have to do this:
        if (!function.HasCode() && !function.HasBytecode()) {
          function.EnsureHasCode();
        }
        if (function.HasBytecode()) {
#if !defined(DART_PRECOMPILED_RUNTIME)
          bytecode = function.bytecode();
          code_array.Add(bytecode);
          offset = Smi::New(FindPcOffset(bytecode, GetYieldIndex(closure)));
#else
          UNREACHABLE();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
        } else if (function.HasCode()) {
          code = function.CurrentCode();
          code_array.Add(code);
          pc_descs = code.pc_descriptors();
          offset = Smi::New(FindPcOffset(pc_descs, GetYieldIndex(closure)));
        } else {
          UNREACHABLE();
        }
        // Unlike other sources of PC offsets, the offset may be 0 here if we
        // reach a non-async closure receiving the yielded value.
        ASSERT(offset.Value() >= 0);
        pc_offset_array.Add(offset);

        // Inject async suspension marker.
        code_array.Add(StubCode::AsynchronousGapMarker());
        offset = Smi::New(0);
        pc_offset_array.Add(offset);
      }

      // Ignore the rest of the stack; already unwound all async calls.
      return;
    }
  }

  return;
}

// Count the number of frames that are on the stack.
intptr_t StackTraceUtils::CountFrames(Thread* thread,
                                      int skip_frames,
                                      const Function& async_function,
                                      bool* sync_async_end) {
  Zone* zone = thread->zone();
  intptr_t frame_count = 0;
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames, thread,
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Function& function = Function::Handle(zone);
  Code& code = Code::Handle(zone);
  Bytecode& bytecode = Bytecode::Handle(zone);
  String& function_name = String::Handle(zone);
  const bool async_function_is_null = async_function.IsNull();
  int sync_async_gap_frames = -1;
  ASSERT(async_function_is_null || sync_async_end != NULL);
  for (; frame != NULL && sync_async_gap_frames != 0;
       frame = frames.NextFrame()) {
    if (!frame->IsDartFrame()) {
      continue;
    }
    if (skip_frames > 0) {
      skip_frames--;
      continue;
    }
    if (frame->is_interpreted()) {
      bytecode = frame->LookupDartBytecode();
      function = bytecode.function();
      if (function.IsNull()) continue;
    } else {
      code = frame->LookupDartCode();
      function = code.function();
    }
    const bool function_is_null = function.IsNull();
    if (!function_is_null && sync_async_gap_frames > 0) {
      function_name = function.QualifiedScrubbedName();
      if (!CheckAndSkipAsync(&sync_async_gap_frames, function_name)) {
        *sync_async_end = false;
        return frame_count;
      }
    } else {
      frame_count++;
    }
    if (!async_function_is_null && !function_is_null &&
        (async_function.raw() == function.parent_function())) {
      sync_async_gap_frames = kSyncAsyncFrameGap;
    }
  }
  if (!async_function_is_null) {
    *sync_async_end = sync_async_gap_frames == 0;
  }
  return frame_count;
}

intptr_t StackTraceUtils::CollectFrames(Thread* thread,
                                        const Array& code_array,
                                        const Array& pc_offset_array,
                                        intptr_t array_offset,
                                        intptr_t count,
                                        int skip_frames) {
  Zone* zone = thread->zone();
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames, thread,
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Function& function = Function::Handle(zone);
  Code& code = Code::Handle(zone);
  Bytecode& bytecode = Bytecode::Handle(zone);
  Smi& offset = Smi::Handle(zone);
  intptr_t collected_frames_count = 0;
  for (; (frame != NULL) && (collected_frames_count < count);
       frame = frames.NextFrame()) {
    if (!frame->IsDartFrame()) {
      continue;
    }
    if (skip_frames > 0) {
      skip_frames--;
      continue;
    }
    if (frame->is_interpreted()) {
      bytecode = frame->LookupDartBytecode();
      function = bytecode.function();
      if (function.IsNull()) {
        continue;
      }
      offset = Smi::New(frame->pc() - bytecode.PayloadStart());
      code_array.SetAt(array_offset, bytecode);
    } else {
      code = frame->LookupDartCode();
      offset = Smi::New(frame->pc() - code.PayloadStart());
      code_array.SetAt(array_offset, code);
    }
    pc_offset_array.SetAt(array_offset, offset);
    array_offset++;
    collected_frames_count++;
  }
  return collected_frames_count;
}

intptr_t StackTraceUtils::ExtractAsyncStackTraceInfo(
    Thread* thread,
    Function* async_function,
    StackTrace* async_stack_trace_out,
    Array* async_code_array,
    Array* async_pc_offset_array) {
  if (thread->async_stack_trace() == StackTrace::null()) {
    return 0;
  }
  *async_stack_trace_out = thread->async_stack_trace();
  ASSERT(!async_stack_trace_out->IsNull());
  const StackTrace& async_stack_trace =
      StackTrace::Handle(thread->async_stack_trace());
  const intptr_t async_stack_trace_length = async_stack_trace.Length();
  // At least two entries (0: gap marker, 1: async function).
  ASSERT(async_stack_trace_length >= 2);
  // Validate the structure of this stack trace.
  *async_code_array = async_stack_trace.code_array();
  ASSERT(!async_code_array->IsNull());
  *async_pc_offset_array = async_stack_trace.pc_offset_array();
  ASSERT(!async_pc_offset_array->IsNull());
  // We start with the asynchronous gap marker.
  ASSERT(async_code_array->At(0) != Code::null());
  ASSERT(async_code_array->At(0) == StubCode::AsynchronousGapMarker().raw());
  const Object& code_object = Object::Handle(async_code_array->At(1));
  if (code_object.IsCode()) {
    *async_function = Code::Cast(code_object).function();
  } else {
    ASSERT(code_object.IsBytecode());
    *async_function = Bytecode::Cast(code_object).function();
  }
  ASSERT(!async_function->IsNull());
  ASSERT(async_function->IsAsyncFunction() ||
         async_function->IsAsyncGenerator());
  return async_stack_trace_length;
}

}  // namespace dart
