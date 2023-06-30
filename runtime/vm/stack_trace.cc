// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stack_trace.h"

#include "vm/dart_api_impl.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

namespace {

// Keep in sync with:
// - sdk/lib/async/stream_controller.dart:_StreamController._STATE_SUBSCRIBED.
const intptr_t k_StreamController__STATE_SUBSCRIBED = 1;
// - sdk/lib/async/future_impl.dart:_FutureListener.stateThen.
const intptr_t k_FutureListener_stateThen = 1;
// - sdk/lib/async/future_impl.dart:_FutureListener.stateCatchError.
const intptr_t k_FutureListener_stateCatchError = 2;
// - sdk/lib/async/future_impl.dart:_FutureListener.stateWhenComplete.
const intptr_t k_FutureListener_stateWhenComplete = 8;

bool WasPreviouslySuspended(const Function& function,
                            const Object& suspend_state_var) {
  if (!suspend_state_var.IsSuspendState()) {
    return false;
  }
  if (function.IsAsyncFunction()) {
    // Error callback is set after both 'then' and 'error' callbacks are
    // registered with the Zone. Callback registration may query
    // stack trace and should still collect the synchronous stack trace.
    return SuspendState::Cast(suspend_state_var).error_callback() !=
           Object::null();
  } else if (function.IsAsyncGenerator()) {
    return true;
  } else {
    UNREACHABLE();
  }
}

// Unwinder which starts by unwinding the synchronous portion of the stack
// until it reaches a frame which has an asynchronous awaiter (e.g. an
// activation of the async function which has a listener attached to the
// corresponding Future object) and then unwinds through the chain
// of awaiters.
class AsyncAwareStackUnwinder : public ValueObject {
 public:
  explicit AsyncAwareStackUnwinder(Thread* thread)
      : zone_(thread->zone()),
        sync_frames_(thread, StackFrameIterator::kNoCrossThreadIteration),
        sync_frame_(nullptr),
        awaiter_frame_{Closure::Handle(zone_), Object::Handle(zone_)},
        closure_(Closure::Handle(zone_)),
        code_(Code::Handle(zone_)),
        context_(Context::Handle(zone_)),
        function_(Function::Handle(zone_)),
        parent_function_(Function::Handle(zone_)),
        object_(Object::Handle(zone_)),
        suspend_state_(SuspendState::Handle(zone_)),
        controller_(Object::Handle(zone_)),
        subscription_(Object::Handle(zone_)),
        stream_iterator_(Object::Handle(zone_)),
        async_lib_(Library::Handle(zone_, Library::AsyncLibrary())),
        null_closure_(Closure::Handle(zone_)) {}

  bool Unwind(intptr_t skip_frames,
              std::function<void(const StackTraceUtils::Frame&)> handle_frame);

 private:
  bool HandleSynchronousFrame();

  void UnwindAwaiterFrame();

  // Returns either the `onData` or the Future awaiter.
  ObjectPtr FindCallerInAsyncStarStreamController(
      const Object& async_star_stream_controller);

  void InitializeAwaiterFrameFromSuspendState();

  void InitializeAwaiterFrameFromFutureListener(const Object& listener);

  void UnwindToAwaiter();

  // |frame.next| is a |_Future| instance. Unwind to the next frame.
  void UnwindFrameToFutureListener();

  // |frame.next| is an |_AsyncStarStreamController| instance corresponding to
  // an async* function. Unwind to the next frame.
  void UnwindFrameToStreamListener();

  ObjectPtr GetReceiver() const;

#define USED_CLASS_LIST(V)                                                     \
  V(_AsyncStarStreamController)                                                \
  V(_BufferingStreamSubscription)                                              \
  V(_Completer)                                                                \
  V(_AsyncCompleter)                                                           \
  V(_SyncCompleter)                                                            \
  V(_ControllerSubscription)                                                   \
  V(_Future)                                                                   \
  V(_FutureListener)                                                           \
  V(_StreamController)                                                         \
  V(_StreamIterator)                                                           \
  V(_SyncStreamController)

  enum ClassId {
#define DECLARE_CONSTANT(symbol) k##symbol,
    USED_CLASS_LIST(DECLARE_CONSTANT)
#undef DECLARE_CONSTANT
  };

#define USED_FIELD_LIST(V)                                                     \
  V(_AsyncStarStreamController, controller)                                    \
  V(_BufferingStreamSubscription, _onData)                                     \
  V(_Completer, future)                                                        \
  V(_Future, _resultOrListeners)                                               \
  V(_FutureListener, callback)                                                 \
  V(_FutureListener, result)                                                   \
  V(_FutureListener, state)                                                    \
  V(_StreamController, _state)                                                 \
  V(_StreamController, _varData)                                               \
  V(_StreamIterator, _hasValue)                                                \
  V(_StreamIterator, _stateData)

  enum FieldId {
#define DECLARE_CONSTANT(class_symbol, field_symbol)                           \
  k##class_symbol##_##field_symbol,
    USED_FIELD_LIST(DECLARE_CONSTANT)
#undef DECLARE_CONSTANT
  };

#define PLUS_ONE(...) +1
  static constexpr intptr_t kUsedClassCount = 0 USED_CLASS_LIST(PLUS_ONE);
  static constexpr intptr_t kUsedFieldCount = 0 USED_FIELD_LIST(PLUS_ONE);
#undef PLUS_ONE

#define DECLARE_GETTER(symbol)                                                 \
  const Class& symbol() {                                                      \
    auto& cls = classes_[k##symbol];                                           \
    if (cls == nullptr) {                                                      \
      cls = &Class::Handle(                                                    \
          zone_, async_lib_.LookupClassAllowPrivate(Symbols::symbol()));       \
      ASSERT(!cls->IsNull());                                                  \
    }                                                                          \
    return *cls;                                                               \
  }
  USED_CLASS_LIST(DECLARE_GETTER)
#undef DECLARE_GETTER

#define DECLARE_GETTER(class_symbol, field_symbol)                             \
  ObjectPtr Get##class_symbol##_##field_symbol(const Object& obj) {            \
    auto& field = fields_[k##class_symbol##_##field_symbol];                   \
    if (field == nullptr) {                                                    \
      field = &Field::Handle(zone_, class_symbol().LookupFieldAllowPrivate(    \
                                        Symbols::field_symbol()));             \
      ASSERT(!field->IsNull());                                                \
    }                                                                          \
    return Instance::Cast(obj).GetField(*field);                               \
  }
  USED_FIELD_LIST(DECLARE_GETTER)
#undef DECLARE_GETTER

  struct AwaiterFrame {
    Closure& closure;
    Object& next;
    bool has_catch_error;
  };

  Zone* zone_;
  DartFrameIterator sync_frames_;

  StackFrame* sync_frame_;
  AwaiterFrame awaiter_frame_;

  Closure& closure_;
  Code& code_;
  Context& context_;
  Function& function_;
  Function& parent_function_;
  Object& object_;
  SuspendState& suspend_state_;

  Object& controller_;
  Object& subscription_;
  Object& stream_iterator_;

  const Library& async_lib_;
  Class* classes_[kUsedClassCount] = {};
  Field* fields_[kUsedFieldCount] = {};

  const Closure& null_closure_;

  DISALLOW_COPY_AND_ASSIGN(AsyncAwareStackUnwinder);
};

bool AsyncAwareStackUnwinder::Unwind(
    intptr_t skip_frames,
    std::function<void(const StackTraceUtils::Frame&)> handle_frame) {
  // First skip the given number of synchronous frames.
  sync_frame_ = sync_frames_.NextFrame();
  while (skip_frames > 0 && sync_frame_ != nullptr) {
    sync_frame_ = sync_frames_.NextFrame();
    skip_frames--;
  }

  // Continue unwinding synchronous portion of the stack looking for
  // a synchronous frame which has an awaiter.
  while (sync_frame_ != nullptr && awaiter_frame_.closure.IsNull()) {
    const bool was_handled = HandleSynchronousFrame();
    if (!was_handled) {
      code_ = sync_frame_->LookupDartCode();
      const uword pc_offset = sync_frame_->pc() - code_.PayloadStart();
      handle_frame({sync_frame_, code_, pc_offset, null_closure_, false});
    }
    sync_frame_ = sync_frames_.NextFrame();
  }

  // Traverse awaiter frames.
  bool any_async = false;
  for (; !awaiter_frame_.closure.IsNull(); UnwindToAwaiter()) {
    function_ = awaiter_frame_.closure.function();
    if (function_.IsNull()) {
      continue;
    }

    any_async = true;
    if (awaiter_frame_.next.IsSuspendState()) {
      const uword pc = SuspendState::Cast(awaiter_frame_.next).pc();
      if (pc == 0) {
        // Async function is already resumed.
        continue;
      }

      code_ = SuspendState::Cast(awaiter_frame_.next).GetCodeObject();
      const uword pc_offset = pc - code_.PayloadStart();
      handle_frame({nullptr, code_, pc_offset, awaiter_frame_.closure,
                    awaiter_frame_.has_catch_error});
    } else {
      // This is an asynchronous continuation represented by a closure which
      // will handle successful completion. This function is not yet executing
      // so we have to use artificial marker offset (1).
      code_ = function_.EnsureHasCode();
      RELEASE_ASSERT(!code_.IsNull());
      const uword pc_offset =
          (function_.entry_point() + StackTraceUtils::kFutureListenerPcOffset) -
          code_.PayloadStart();
      handle_frame({nullptr, code_, pc_offset, awaiter_frame_.closure,
                    awaiter_frame_.has_catch_error});
    }
  }
  return any_async;
}

ObjectPtr AsyncAwareStackUnwinder::GetReceiver() const {
  return *(reinterpret_cast<ObjectPtr*>(sync_frame_->GetCallerSp()) +
           function_.num_fixed_parameters() - 1);
}

bool AsyncAwareStackUnwinder::HandleSynchronousFrame() {
  function_ = sync_frame_->LookupDartFunction();
  if (function_.IsNull()) {
    return false;
  }

  // This is an invocation of an `async` or `async*` function.
  if (function_.IsAsyncFunction() || function_.IsAsyncGenerator()) {
    InitializeAwaiterFrameFromSuspendState();
    return false;
  }

  // This is an invocation of a closure which has a variable marked
  // with `@pragma('vm:awaiter-link')` which points to the awaiter.
  if (function_.HasAwaiterLink()) {
    object_ = GetReceiver();
    if (object_.IsClosure() &&
        StackTraceUtils::GetSuspendState(Closure::Cast(object_),
                                         &awaiter_frame_.next)) {
      awaiter_frame_.closure ^= object_.ptr();
      return true;  // Hide this frame from the stack trace.
    }
  }

  // This is `_FutureListener.handleValue(...)` invocation.
  if (function_.recognized_kind() ==
      MethodRecognizer::kFutureListenerHandleValue) {
    object_ = GetReceiver();
    InitializeAwaiterFrameFromFutureListener(object_);
    UnwindToAwaiter();
    return true;  // Hide this frame from the stack trace.
  }

  return false;
}

void AsyncAwareStackUnwinder::InitializeAwaiterFrameFromSuspendState() {
  if (function_.IsAsyncFunction() || function_.IsAsyncGenerator()) {
    // Check if we reached a resumed asynchronous function. In this case we
    // are going to start following async frames after we emit this frame.
    object_ = *reinterpret_cast<ObjectPtr*>(LocalVarAddress(
        sync_frame_->fp(), runtime_frame_layout.FrameSlotForVariableIndex(
                               SuspendState::kSuspendStateVarIndex)));

    awaiter_frame_.closure = Closure::null();
    if (WasPreviouslySuspended(function_, object_)) {
      awaiter_frame_.next = object_.ptr();
      UnwindToAwaiter();
    }
  }
}

void AsyncAwareStackUnwinder::UnwindToAwaiter() {
  awaiter_frame_.has_catch_error = false;
  do {
    UnwindAwaiterFrame();
  } while (awaiter_frame_.closure.IsNull() && !awaiter_frame_.next.IsNull());
}

void AsyncAwareStackUnwinder::UnwindAwaiterFrame() {
  if (awaiter_frame_.next.IsSuspendState()) {
    awaiter_frame_.next =
        SuspendState::Cast(awaiter_frame_.next).function_data();
  } else if (awaiter_frame_.next.GetClassId() == _SyncCompleter().id() ||
             awaiter_frame_.next.GetClassId() == _AsyncCompleter().id()) {
    awaiter_frame_.next = Get_Completer_future(awaiter_frame_.next);
  }

  if (awaiter_frame_.next.GetClassId() == _Future().id()) {
    UnwindFrameToFutureListener();
  } else if (awaiter_frame_.next.GetClassId() ==
             _AsyncStarStreamController().id()) {
    UnwindFrameToStreamListener();
  } else {
    awaiter_frame_.closure = Closure::null();
    awaiter_frame_.next = Object::null();
    return;
  }

  while (!awaiter_frame_.closure.IsNull()) {
    function_ = awaiter_frame_.closure.function();
    context_ = awaiter_frame_.closure.context();

    const auto awaiter_link = function_.awaiter_link();
    if (awaiter_link.depth != ClosureData::kNoAwaiterLinkDepth) {
      intptr_t depth = awaiter_link.depth;
      while (depth-- > 0) {
        context_ = context_.parent();
      }

      const Object& object = Object::Handle(context_.At(awaiter_link.index));
      if (object.IsClosure()) {
        awaiter_frame_.closure ^= object.ptr();
        continue;
      } else {
        awaiter_frame_.next = object.ptr();
        return;
      }
    }
    break;
  }
}

void AsyncAwareStackUnwinder::UnwindFrameToFutureListener() {
  object_ = Get_Future__resultOrListeners(awaiter_frame_.next);
  if (object_.GetClassId() == _FutureListener().id()) {
    InitializeAwaiterFrameFromFutureListener(object_);
  } else {
    awaiter_frame_.closure = Closure::null();
    awaiter_frame_.next = Object::null();
  }
}

void AsyncAwareStackUnwinder::InitializeAwaiterFrameFromFutureListener(
    const Object& listener) {
  if (listener.GetClassId() != _FutureListener().id()) {
    awaiter_frame_.closure = Closure::null();
    awaiter_frame_.next = Object::null();
    return;
  }

  const auto state =
      Smi::Value(Smi::RawCast(Get_FutureListener_state(listener)));
  if (state == k_FutureListener_stateThen ||
      state == k_FutureListener_stateCatchError ||
      state == k_FutureListener_stateWhenComplete ||
      state ==
          (k_FutureListener_stateThen | k_FutureListener_stateCatchError)) {
    awaiter_frame_.next = Get_FutureListener_result(listener);
  } else {
    awaiter_frame_.next = Object::null();
  }
  awaiter_frame_.closure =
      Closure::RawCast(Get_FutureListener_callback(listener));
  if (state == k_FutureListener_stateCatchError) {
    awaiter_frame_.has_catch_error = true;
  }
}

void AsyncAwareStackUnwinder::UnwindFrameToStreamListener() {
  controller_ = Get_AsyncStarStreamController_controller(awaiter_frame_.next);

  // Clear the frame.
  awaiter_frame_.closure = Closure::null();
  awaiter_frame_.next = Object::null();

  const auto state =
      Smi::Value(Smi::RawCast(Get_StreamController__state(controller_)));
  if (state != k_StreamController__STATE_SUBSCRIBED) {
    return;
  }

  subscription_ = Get_StreamController__varData(controller_);
  closure_ ^= Get_BufferingStreamSubscription__onData(subscription_);

  // If this is not the "_StreamIterator._onData" tear-off, we return the
  // callback we found.
  function_ = closure_.function();
  if (!function_.IsImplicitInstanceClosureFunction() ||
      function_.Owner() != _StreamIterator().ptr()) {
    awaiter_frame_.closure = closure_.ptr();
    return;
  }

  // All implicit closure functions (tear-offs) have the "this" receiver
  // captured.
  context_ = closure_.context();
  ASSERT(context_.num_variables() == 1);
  stream_iterator_ = context_.At(0);
  ASSERT(stream_iterator_.IsInstance());

  if (stream_iterator_.GetClassId() != _StreamIterator().id()) {
    UNREACHABLE();
  }

  // If `_hasValue` is true then the `StreamIterator._stateData` field
  // contains the iterator's value. In that case we cannot unwind anymore.
  //
  // Notice: With correct async* semantics this may never be true: The async*
  // generator should only be invoked to produce a value if there's an
  // in-progress `await streamIterator.moveNext()` call. Once such call has
  // finished the async* generator should be paused/yielded until the next
  // such call - and being paused/yielded means it should not appear in stack
  // traces.
  //
  // See dartbug.com/48695.
  if (Get_StreamIterator__hasValue(stream_iterator_) ==
      Object::bool_true().ptr()) {
    return;
  }

  // If we have an await'er for `await streamIterator.moveNext()` we continue
  // unwinding there.
  //
  // Notice: With correct async* semantics this may always contain a Future
  // See also comment above as well as dartbug.com/48695.
  object_ = Get_StreamIterator__stateData(stream_iterator_);
  if (object_.GetClassId() == _Future().id()) {
    awaiter_frame_.next = object_.ptr();
  }
}

}  // namespace

bool StackTraceUtils::IsNeededForAsyncAwareUnwinding(const Function& function) {
  // If this is a closure function which specifies an awaiter-link then
  // we need to retain both function and the corresponding code.
  if (function.HasAwaiterLink()) {
    return true;
  }

  if (function.recognized_kind() ==
      MethodRecognizer::kFutureListenerHandleValue) {
    return true;
  }

  return false;
}

void StackTraceUtils::CollectFrames(
    Thread* thread,
    int skip_frames,
    const std::function<void(const StackTraceUtils::Frame&)>& handle_frame) {
  const Closure& null_closure = Closure::Handle(thread->zone());

  const Frame gap_frame = {nullptr, StubCode::AsynchronousGapMarker(),
                           /*pc_offset=*/0, null_closure, false};

  const Frame gap_frame_with_catch = {nullptr,
                                      StubCode::AsynchronousGapMarker(),
                                      /*pc_offset=*/0, null_closure, true};

  AsyncAwareStackUnwinder it(thread);
  const bool any_async = it.Unwind(skip_frames, [&](const Frame& frame) {
    if (frame.frame == nullptr) {
      handle_frame(frame.has_async_catch_error ? gap_frame_with_catch
                                               : gap_frame);
    }

    handle_frame(frame);
  });

  if (any_async) {
    handle_frame(gap_frame);
  }
}

bool StackTraceUtils::GetSuspendState(const Closure& closure,
                                      Object* suspend_state) {
  const Function& function = Function::Handle(closure.function());
  const auto awaiter_link = function.awaiter_link();
  if (awaiter_link.depth != ClosureData::kNoAwaiterLinkDepth) {
    Context& context = Context::Handle(closure.context());
    intptr_t depth = awaiter_link.depth;
    while (depth-- > 0) {
      context = context.parent();
    }

    const Object& link = Object::Handle(context.At(awaiter_link.index));
    if (link.IsSuspendState()) {
      *suspend_state = link.ptr();
      return true;
    }
  }
  return false;
}

}  // namespace dart
