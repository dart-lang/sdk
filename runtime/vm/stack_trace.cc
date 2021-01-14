// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stack_trace.h"

#include "vm/dart_api_impl.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

// Keep in sync with
// sdk/lib/async/stream_controller.dart:_StreamController._STATE_SUBSCRIBED.
const intptr_t k_StreamController__STATE_SUBSCRIBED = 1;
// sdk/lib/async/future_impl.dart:_FutureListener.stateWhencomplete.
const intptr_t k_FutureListener_stateWhencomplete = 8;

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

// Instance caches library and field references.
// This way we don't have to do the look-ups for every frame in the stack.
CallerClosureFinder::CallerClosureFinder(Zone* zone)
    : receiver_context_(Context::Handle(zone)),
      receiver_function_(Function::Handle(zone)),
      parent_function_(Function::Handle(zone)),
      context_entry_(Object::Handle(zone)),
      future_(Object::Handle(zone)),
      listener_(Object::Handle(zone)),
      callback_(Object::Handle(zone)),
      controller_(Object::Handle(zone)),
      state_(Object::Handle(zone)),
      var_data_(Object::Handle(zone)),
      callback_instance_(Object::Handle(zone)),
      future_impl_class(Class::Handle(zone)),
      future_listener_class(Class::Handle(zone)),
      async_start_stream_controller_class(Class::Handle(zone)),
      stream_controller_class(Class::Handle(zone)),
      async_stream_controller_class(Class::Handle(zone)),
      controller_subscription_class(Class::Handle(zone)),
      buffering_stream_subscription_class(Class::Handle(zone)),
      stream_iterator_class(Class::Handle(zone)),
      future_result_or_listeners_field(Field::Handle(zone)),
      callback_field(Field::Handle(zone)),
      future_listener_state_field(Field::Handle(zone)),
      future_listener_result_field(Field::Handle(zone)),
      controller_controller_field(Field::Handle(zone)),
      var_data_field(Field::Handle(zone)),
      state_field(Field::Handle(zone)),
      on_data_field(Field::Handle(zone)),
      state_data_field(Field::Handle(zone)) {
  const auto& async_lib = Library::Handle(zone, Library::AsyncLibrary());
  // Look up classes:
  // - async:
  future_impl_class = async_lib.LookupClassAllowPrivate(Symbols::FutureImpl());
  ASSERT(!future_impl_class.IsNull());
  future_listener_class =
      async_lib.LookupClassAllowPrivate(Symbols::_FutureListener());
  ASSERT(!future_listener_class.IsNull());
  // - async*:
  async_start_stream_controller_class =
      async_lib.LookupClassAllowPrivate(Symbols::_AsyncStarStreamController());
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
  future_result_or_listeners_field =
      future_impl_class.LookupFieldAllowPrivate(Symbols::_resultOrListeners());
  ASSERT(!future_result_or_listeners_field.IsNull());
  callback_field =
      future_listener_class.LookupFieldAllowPrivate(Symbols::callback());
  ASSERT(!callback_field.IsNull());
  future_listener_state_field =
      future_listener_class.LookupFieldAllowPrivate(Symbols::state());
  ASSERT(!future_listener_state_field.IsNull());
  future_listener_result_field =
      future_listener_class.LookupFieldAllowPrivate(Symbols::result());
  ASSERT(!future_listener_result_field.IsNull());
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
}

ClosurePtr CallerClosureFinder::GetCallerInFutureImpl(const Object& future) {
  ASSERT(!future.IsNull());
  ASSERT(future.GetClassId() == future_impl_class.id());

  listener_ = Instance::Cast(future).GetField(future_result_or_listeners_field);
  if (listener_.GetClassId() != future_listener_class.id()) {
    return Closure::null();
  }

  // If the _FutureListener is a whenComplete listener, follow the Future being
  // completed, `result`, instead of the dangling whenComplete `callback`.
  state_ = Instance::Cast(listener_).GetField(future_listener_state_field);
  ASSERT(state_.IsSmi());
  if (Smi::Cast(state_).Value() == k_FutureListener_stateWhencomplete) {
    future_ = Instance::Cast(listener_).GetField(future_listener_result_field);
    return GetCallerInFutureImpl(future_);
  }

  callback_ = Instance::Cast(listener_).GetField(callback_field);
  // This happens for e.g.: await f().catchError(..);
  if (callback_.IsNull()) {
    return Closure::null();
  }
  ASSERT(callback_.IsClosure());

  return Closure::Cast(callback_).raw();
}

ClosurePtr CallerClosureFinder::FindCallerInAsyncClosure(
    const Context& receiver_context) {
  future_ = receiver_context.At(Context::kAsyncFutureIndex);
  return GetCallerInFutureImpl(future_);
}

ClosurePtr CallerClosureFinder::FindCallerInAsyncGenClosure(
    const Context& receiver_context) {
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
  if (Smi::Cast(state_).Value() != k_StreamController__STATE_SUBSCRIBED) {
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

ClosurePtr CallerClosureFinder::FindCaller(const Closure& receiver_closure) {
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
      context_entry_ = receiver_context_.At(Context::kFutureTimeoutFutureIndex);
      return GetCallerInFutureImpl(context_entry_);
    } else if (parent_function_.recognized_kind() ==
               MethodRecognizer::kFutureWait) {
      receiver_context_ = receiver_context_.parent();
      ASSERT(!receiver_context_.IsNull());
      context_entry_ = receiver_context_.At(Context::kFutureWaitFutureIndex);
      return GetCallerInFutureImpl(context_entry_);
    }
  }

  return Closure::null();
}

bool CallerClosureFinder::IsRunningAsync(const Closure& receiver_closure) {
  auto zone = Thread::Current()->zone();

  // The async* functions are never started synchronously, they start running
  // after the first `listen()` call to its returned `Stream`.
  const Function& receiver_function_ =
      Function::Handle(zone, receiver_closure.function());
  if (receiver_function_.IsAsyncGenClosure()) {
    return true;
  }
  ASSERT(receiver_function_.IsAsyncClosure());

  const Context& receiver_context_ =
      Context::Handle(zone, receiver_closure.context());
  const Object& is_sync =
      Object::Handle(zone, receiver_context_.At(Context::kIsSyncIndex));
  ASSERT(!is_sync.IsNull());
  ASSERT(is_sync.IsBool());
  // isSync indicates whether the future should be completed async. or sync.,
  // based on whether it has yielded yet.
  // isSync is true when the :async_op has yielded at least once.
  // I.e. isSync will be false even after :async_op has run, if e.g. it threw
  // an exception before yielding.
  return Bool::Cast(is_sync).value();
}

ClosurePtr StackTraceUtils::FindClosureInFrame(ObjectPtr* last_object_in_caller,
                                               const Function& function) {
  NoSafepointScope nsp;

  ASSERT(!function.IsNull());
  ASSERT(function.IsAsyncClosure() || function.IsAsyncGenClosure());

  // The callee has function signature
  //   :async_op([result, exception, stack])
  // So we are guaranteed to
  //   a) have only tagged arguments on the stack until we find the :async_op
  //      closure, and
  //   b) find the async closure.
  const intptr_t kNumClosureAndArgs = 4;
  auto& closure = Closure::Handle();
  for (intptr_t i = 0; i < kNumClosureAndArgs; i++) {
    ObjectPtr arg = last_object_in_caller[i];
    if (arg->IsHeapObject() && arg->GetClassId() == kClosureCid) {
      closure = Closure::RawCast(arg);
      if (closure.function() == function.raw()) {
        return closure.raw();
      }
    }
  }
  UNREACHABLE();
}

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
  auto& offset = Smi::Handle(zone);

  auto& closure = Closure::Handle(zone);
  CallerClosureFinder caller_closure_finder(zone);
  auto& pc_descs = PcDescriptors::Handle();

  // Start by traversing the sync. part of the stack.
  for (; frame != nullptr; frame = frames.NextFrame()) {
    if (skip_frames > 0) {
      skip_frames--;
      continue;
    }

    function = frame->LookupDartFunction();

    // Add the current synchronous frame.
    code = frame->LookupDartCode();
    ASSERT(function.raw() == code.function());
    code_array.Add(code);
    const intptr_t pc_offset = frame->pc() - code.PayloadStart();
    ASSERT(pc_offset > 0 && pc_offset <= code.Size());
    offset = Smi::New(pc_offset);
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

      {
        NoSafepointScope nsp;

        // Next, look up caller's closure on the stack and walk backwards
        // through the yields.
        ObjectPtr* last_caller_obj =
            reinterpret_cast<ObjectPtr*>(frame->GetCallerSp());
        closure = FindClosureInFrame(last_caller_obj, function);

        // If this async function hasn't yielded yet, we're still dealing with a
        // normal stack. Continue to next frame as usual.
        if (!caller_closure_finder.IsRunningAsync(closure)) {
          continue;
        }
      }

      // Inject async suspension marker.
      code_array.Add(StubCode::AsynchronousGapMarker());
      offset = Smi::New(0);
      pc_offset_array.Add(offset);

      // Skip: Already handled this frame's function above.
      closure = caller_closure_finder.FindCaller(closure);

      // Traverse the trail of async futures all the way up.
      for (; !closure.IsNull();
           closure = caller_closure_finder.FindCaller(closure)) {
        function = closure.function();
        // In hot-reload-test-mode we sometimes have to do this:
        if (!function.HasCode()) {
          function.EnsureHasCode();
        }
        if (function.HasCode()) {
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

intptr_t StackTraceUtils::CountFrames(Thread* thread,
                                      int skip_frames,
                                      const Function& async_function,
                                      bool* sync_async_end) {
  Zone* zone = thread->zone();
  intptr_t frame_count = 0;
  DartFrameIterator frames(thread, StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != nullptr);  // We expect to find a dart invocation frame.
  Function& function = Function::Handle(zone);
  Code& code = Code::Handle(zone);
  Closure& closure = Closure::Handle(zone);
  const bool async_function_is_null = async_function.IsNull();

  ASSERT(async_function_is_null || sync_async_end != nullptr);

  for (; frame != nullptr; frame = frames.NextFrame()) {
    if (skip_frames > 0) {
      skip_frames--;
      continue;
    }
    code = frame->LookupDartCode();
    function = code.function();

    frame_count++;

    const bool function_is_null = function.IsNull();

    if (!async_function_is_null && !function_is_null &&
        function.parent_function() != Function::null()) {
      if (async_function.raw() == function.parent_function()) {
        if (function.IsAsyncClosure() || function.IsAsyncGenClosure()) {
          ObjectPtr* last_caller_obj =
              reinterpret_cast<ObjectPtr*>(frame->GetCallerSp());
          closure = FindClosureInFrame(last_caller_obj, function);
          if (CallerClosureFinder::IsRunningAsync(closure)) {
            *sync_async_end = false;
            return frame_count;
          }
        }
        break;
      }
    }
  }

  if (!async_function_is_null) {
    *sync_async_end = true;
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
  DartFrameIterator frames(thread, StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Code& code = Code::Handle(zone);
  Smi& offset = Smi::Handle(zone);
  intptr_t collected_frames_count = 0;
  for (; (frame != NULL) && (collected_frames_count < count);
       frame = frames.NextFrame()) {
    if (skip_frames > 0) {
      skip_frames--;
      continue;
    }
    code = frame->LookupDartCode();
    offset = Smi::New(frame->pc() - code.PayloadStart());
    code_array.SetAt(array_offset, code);
    pc_offset_array.SetAt(array_offset, offset);
    array_offset++;
    collected_frames_count++;
  }
  return collected_frames_count;
}

}  // namespace dart
